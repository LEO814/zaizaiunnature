#!/usr/bin/env python3
"""Validate package contracts without pretending to run the editor or parse models."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path, PurePosixPath
from typing import Any

SCHEMA_VERSION = "0.2.0"
TYPE_DIRECTORIES = {
    "player": "player", "monster": "monsters", "weapon": "weapons",
    "item": "items", "interactable": "interactables",
    "environment": "environment", "ui": "ui",
}
REQUIRED_DIRS = ("model", "animations", "materials", "tests")
MANIFEST_KEYS = {
    "id", "type", "status", "packageId", "schemaVersion", "definitionModule",
    "controllerModule", "resources", "clips", "requiredServices", "dependencies",
}
SERVICE_NAMES = {
    "Characters", "Combat", "Inventory", "Movement", "Navigation",
    "Interaction", "Session", "Assets", "UI",
}
ID_RE = re.compile(r"^[a-z][a-z0-9_]{2,63}$")
MODULE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$")
SCOPE = (
    "Only directory, manifest, static Lua imports and generated registry contracts are checked. "
    "This does not parse GLB/Blender files, prove SDK compatibility, or verify gameplay in the editor."
)


def _object_no_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_object_no_duplicates)


def expected_module(path: Path, root: Path) -> str:
    return ".".join(path.relative_to(root).with_suffix("").parts)


def safe_path(root: Path, value: Any) -> Path:
    if not isinstance(value, str) or not value or "\\" in value or "\x00" in value:
        raise ValueError("path must be a nonempty forward-slash relative path")
    parts = value.split("/")
    if any(part in ("", ".", "..") for part in parts) or ":" in value:
        raise ValueError("path must not contain traversal, empty segments, drives or URLs")
    pure = PurePosixPath(value)
    if pure.is_absolute():
        raise ValueError("absolute paths are forbidden")
    target = root.joinpath(*pure.parts)
    try:
        target.resolve().relative_to(root.resolve())
    except (ValueError, OSError, RuntimeError) as exc:
        raise ValueError("path escapes project root, including through symlinks") from exc
    return target


def lua_tokens(source: str) -> list[tuple[str, str, int]]:
    """A small lexer for import checking; this is explicitly not a Lua parser."""
    tokens: list[tuple[str, str, int]] = []
    i = 0
    line = 1
    n = len(source)
    while i < n:
        char = source[i]
        if char.isspace():
            line += char == "\n"
            i += 1
            continue
        if source.startswith("--", i):
            start = i
            long_open = re.match(r"\[(=*)\[", source[i + 2:])
            if long_open:
                close = "]" + long_open.group(1) + "]"
                end = source.find(close, i + 2 + len(long_open.group(0)))
                i = n if end < 0 else end + len(close)
            else:
                end = source.find("\n", i + 2)
                i = n if end < 0 else end
            line += source[start:i].count("\n")
            continue
        long_open = re.match(r"\[(=*)\[", source[i:])
        if long_open:
            token_line = line
            start = i + len(long_open.group(0))
            close = "]" + long_open.group(1) + "]"
            end = source.find(close, start)
            if end < 0:
                raise ValueError("unterminated Lua long string at line " + str(line))
            value = source[start:end]
            i = end + len(close)
            line += value.count("\n")
            tokens.append(("string", value, token_line))
            continue
        if char in ("'", '"'):
            quote = char
            token_line = line
            i += 1
            value = ""
            while i < n and source[i] != quote:
                if source[i] == "\\":
                    if i + 1 >= n:
                        raise ValueError("unterminated Lua string at line " + str(token_line))
                    escaped = source[i + 1]
                    value += {"n": "\n", "r": "\r", "t": "\t"}.get(escaped, escaped)
                    line += escaped == "\n"
                    i += 2
                else:
                    line += source[i] == "\n"
                    value += source[i]
                    i += 1
            if i >= n:
                raise ValueError("unterminated Lua string at line " + str(token_line))
            i += 1
            tokens.append(("string", value, token_line))
            continue
        match = re.match(r"[A-Za-z_][A-Za-z0-9_]*", source[i:])
        if match:
            value = match.group(0)
            tokens.append(("name", value, line))
            i += len(value)
            continue
        tokens.append(("symbol", char, line))
        i += 1
    return tokens


def static_requires(source: str) -> tuple[list[tuple[str, int]], list[tuple[int, str]]]:
    tokens = lua_tokens(source)
    imports: list[tuple[str, int]] = []
    failures: list[tuple[int, str]] = []
    for i, token in enumerate(tokens):
        if token[0] != "name" or token[1] != "require":
            continue
        if i > 0 and tokens[i - 1][1] in (".", ":"):
            continue
        rest = tokens[i + 1:]
        if rest and rest[0][1] == "(":
            if len(rest) < 3 or rest[1][0] != "string" or rest[2][1] != ")":
                failures.append((token[2], "dynamic require is forbidden; use one literal module name"))
                continue
            module = rest[1][1]
        elif rest and rest[0][0] == "string":
            module = rest[0][1]
        else:
            failures.append((token[2], "dynamic require or aliasing require is forbidden"))
            continue
        if not MODULE_RE.fullmatch(module):
            failures.append((token[2], "require module must use dot-separated identifiers"))
        else:
            imports.append((module, token[2]))
    return imports, failures


def validate_root(root: Path, mode: str = "contract") -> dict[str, Any]:
    root = root.resolve()
    errors: list[dict[str, Any]] = []
    counts = {"packages": 0, "resources": 0, "clips": 0, "luaFiles": 0, "staticImports": 0}

    def fail(code: str, path: Path | str, message: str) -> None:
        if isinstance(path, Path):
            try:
                label = path.relative_to(root).as_posix()
            except ValueError:
                label = str(path)
        else:
            label = path
        errors.append({"code": code, "path": label, "message": message})

    if mode not in ("contract", "delivery"):
        fail("mode", "", "mode must be contract or delivery")
        return {"ok": False, "mode": mode, "counts": counts, "errors": errors, "scope": SCOPE}
    base = root / "gameplay" / "packages"
    if not base.is_dir():
        fail("package-root", base, "required package root is missing")
    service_file = root / "gameplay" / "core" / "service_contracts.json"
    service_names = set(SERVICE_NAMES)
    try:
        contracts = read_json(service_file)
        if not isinstance(contracts, dict) or contracts.get("schemaVersion") != SCHEMA_VERSION:
            fail("service-contract", service_file, "service contract schemaVersion must be " + SCHEMA_VERSION)
        services = contracts.get("services") if isinstance(contracts, dict) else None
        if not isinstance(services, list) or any(not isinstance(entry, str) for entry in services):
            raise ValueError("services must be a string list")
        service_names = set(services)
        if service_names != SERVICE_NAMES or len(service_names) != len(services):
            fail("service-contract", service_file, "services must declare the nine agreed service names")
        service_lua = service_file.with_suffix(".lua")
        safe_path(root, service_lua.relative_to(root).as_posix())
        actual_tokens = [(kind, value) for kind, value, _ in lua_tokens(service_lua.read_text(encoding="utf-8"))]
        expected_source = "return {" + ",".join(json.dumps(name) for name in services) + ",}"
        expected_tokens = [(kind, value) for kind, value, _ in lua_tokens(expected_source)]
        if actual_tokens != expected_tokens:
            fail("service-lua-mismatch", service_lua, "Lua service array must exactly match JSON service order and values")
    except (OSError, ValueError, TypeError, AttributeError) as exc:
        fail("service-contract", service_file, str(exc))

    manifests: dict[str, tuple[Path, dict[str, Any]]] = {}
    all_ids: dict[str, Path] = {}
    resource_paths: dict[str, Path] = {}

    def register_id(value: Any, path: Path, kind: str) -> None:
        if not isinstance(value, str) or not ID_RE.fullmatch(value):
            fail("id-format", path, kind + " ID must be lowercase ASCII with underscores, 3–64 characters")
            return
        if value in all_ids:
            fail("duplicate-id", path, value + " already declared in " + all_ids[value].relative_to(root).as_posix())
        else:
            all_ids[value] = path

    for group in sorted(set(TYPE_DIRECTORIES.values())):
        group_path = base / group
        if not group_path.is_dir():
            fail("group-directory", group_path, "required package category directory is missing")
    if base.is_dir():
        for child in sorted(base.iterdir()):
            if child.is_dir() and child.name not in TYPE_DIRECTORIES.values():
                fail("group-name", child, "unknown package category")
        paths = sorted(base.glob("*/*/manifest.json"))
        for entity_dir in sorted(base.glob("*/*")):
            if entity_dir.is_dir() and not (entity_dir / "manifest.json").is_file():
                fail("manifest-missing", entity_dir, "entity directory needs manifest.json")
    else:
        paths = []
    for manifest_path in paths:
        package_dir = manifest_path.parent
        counts["packages"] += 1
        try:
            safe_path(root, manifest_path.relative_to(root).as_posix())
            manifest = read_json(manifest_path)
            if not isinstance(manifest, dict):
                raise ValueError("manifest must be an object")
        except (OSError, ValueError) as exc:
            fail("manifest-json", manifest_path, str(exc))
            continue
        missing = MANIFEST_KEYS - set(manifest)
        unknown = set(manifest) - MANIFEST_KEYS
        if missing:
            fail("manifest-fields", manifest_path, "missing fields: " + ", ".join(sorted(missing)))
        if unknown:
            fail("manifest-fields", manifest_path, "unknown fields: " + ", ".join(sorted(unknown)))
        entity_id = manifest.get("id")
        register_id(entity_id, manifest_path, "entity")
        if isinstance(entity_id, str):
            if entity_id != package_dir.name:
                fail("entity-directory", manifest_path, "id must equal entity directory name")
            manifests[entity_id] = (manifest_path, manifest)
        type_name = manifest.get("type")
        if not isinstance(type_name, str) or TYPE_DIRECTORIES.get(type_name) != package_dir.parent.name:
            fail("type-directory", manifest_path, "manifest type must match its package category")
        if manifest.get("schemaVersion") != SCHEMA_VERSION:
            fail("schema-version", manifest_path, "schemaVersion must be " + SCHEMA_VERSION)
        if not isinstance(manifest.get("packageId"), str) or not re.fullmatch(r"PKG-[A-Z0-9_-]+", manifest["packageId"]):
            fail("package-id", manifest_path, "packageId must use PKG- followed by uppercase identifiers")
        if manifest.get("status") not in ("planned", "delivered"):
            fail("status", manifest_path, "status must be planned or delivered")
        elif mode == "delivery" and manifest["status"] != "delivered":
            fail("planned-package", manifest_path, "delivery mode rejects planned packages")
        for directory in REQUIRED_DIRS:
            required = package_dir / directory
            if not required.is_dir():
                fail("package-directory", required, "required package directory is missing")
            else:
                try:
                    safe_path(root, required.relative_to(root).as_posix())
                except ValueError as exc:
                    fail("path-safety", required, str(exc))
        readme = package_dir / "README.md"
        if not readme.is_file():
            fail("readme", readme, "package README is required")
        else:
            try:
                safe_path(root, readme.relative_to(root).as_posix())
            except ValueError as exc:
                fail("path-safety", readme, str(exc))
        for field, filename in (("definitionModule", "definition.lua"), ("controllerModule", "controller.lua")):
            target = package_dir / filename
            if manifest.get(field) != expected_module(target, root):
                fail("module-path", manifest_path, field + " must equal " + expected_module(target, root))
            if not target.is_file():
                fail("module-missing", target, "declared Lua module is missing")
            else:
                try:
                    safe_path(root, target.relative_to(root).as_posix())
                except ValueError as exc:
                    fail("path-safety", target, str(exc))
        required_services = manifest.get("requiredServices")
        if not isinstance(required_services, list) or any(not isinstance(x, str) for x in required_services):
            fail("services", manifest_path, "requiredServices must be a string list")
        elif len(set(required_services)) != len(required_services) or not set(required_services) <= service_names:
            fail("services", manifest_path, "requiredServices must be unique names from service_contracts.json")
        dependencies = manifest.get("dependencies")
        if not isinstance(dependencies, list) or any(not isinstance(x, str) for x in dependencies):
            fail("dependencies", manifest_path, "dependencies must be a string list")
        elif len(set(dependencies)) != len(dependencies):
            fail("dependencies", manifest_path, "dependencies must not repeat")
        resources = manifest.get("resources")
        if not isinstance(resources, list) or not resources:
            fail("resources", manifest_path, "resources must be a nonempty list")
            resources = []
        local_resource_kinds: dict[str, str] = {}
        for resource in resources:
            counts["resources"] += 1
            if not isinstance(resource, dict) or set(resource) != {"id", "path", "kind", "status"}:
                fail("resource-fields", manifest_path, "resource fields must be id, path, kind, status")
                continue
            register_id(resource["id"], manifest_path, "resource")
            if isinstance(resource["id"], str) and isinstance(resource["kind"], str):
                local_resource_kinds.setdefault(resource["id"], resource["kind"])
            if resource["status"] not in ("planned", "delivered"):
                fail("resource-status", manifest_path, "resource status must be planned or delivered")
            try:
                target = safe_path(root, resource["path"])
                target.resolve().relative_to(package_dir.resolve())
                kind = resource["kind"]
                fixed_expected = {
                    "model": package_dir / "model" / "main.glb",
                    "source": package_dir / "model" / "source.blend",
                    "ui_texture": package_dir / "materials" / "ui_atlas.png",
                }.get(kind) if isinstance(kind, str) else None
                extra_location = {
                    "animation": (package_dir / "animations", "glb"),
                    "texture": (package_dir / "materials", "png"),
                    "scene_chunk": (package_dir / "model" / "chunks", "glb"),
                }.get(kind) if isinstance(kind, str) else None
                valid_location = fixed_expected is not None and target == fixed_expected
                if extra_location is not None:
                    directory, extension = extra_location
                    valid_location = target.parent == directory and bool(re.fullmatch(r"[a-z][a-z0-9_]*\." + extension, target.name))
                if not valid_location:
                    fail("resource-location", manifest_path, "resource kind must use its agreed filename within this package")
                relative = target.relative_to(root).as_posix()
                if relative in resource_paths:
                    fail("duplicate-resource-path", manifest_path, "resource path already declared: " + relative)
                else:
                    resource_paths[relative] = manifest_path
                if resource["status"] == "delivered" and not target.is_file():
                    fail("resource-missing", target, "delivered resource file is missing")
                if mode == "delivery" and resource["status"] != "delivered":
                    fail("planned-resource", manifest_path, "delivery mode rejects planned resources")
            except (ValueError, TypeError) as exc:
                fail("path-safety", manifest_path, str(exc))
        clips = manifest.get("clips")
        if not isinstance(clips, list):
            fail("clips", manifest_path, "clips must be a list")
            clips = []
        names: set[str] = set()
        for clip in clips:
            counts["clips"] += 1
            if not isinstance(clip, dict) or set(clip) != {"id", "name", "role", "resourceId"}:
                fail("clip-fields", manifest_path, "clip fields must be id, name, role, resourceId")
                continue
            register_id(clip["id"], manifest_path, "clip")
            resource_id = clip["resourceId"]
            if not isinstance(resource_id, str) or local_resource_kinds.get(resource_id) not in ("model", "animation", "scene_chunk"):
                fail("clip-resource", manifest_path, "clip resourceId must refer to this manifest's runtime model, animation or scene_chunk")
            for key in ("name", "role"):
                if not isinstance(clip[key], str) or not clip[key].strip():
                    fail("clip-value", manifest_path, "clip " + key + " must be a nonempty string")
            if isinstance(clip["name"], str):
                if clip["name"] in names:
                    fail("clip-name", manifest_path, "exported animation names must not repeat within a package")
                names.add(clip["name"])

    for entity_id, (path, manifest) in manifests.items():
        for dependency in manifest.get("dependencies", []) if isinstance(manifest.get("dependencies"), list) else []:
            if dependency == entity_id:
                fail("self-dependency", path, "package must not depend on itself")
            elif isinstance(dependency, str) and dependency not in manifests:
                fail("dependency-missing", path, "unknown entity dependency: " + dependency)

    gameplay = root / "gameplay"
    for lua_path in sorted(gameplay.rglob("*.lua")) if gameplay.is_dir() else []:
        counts["luaFiles"] += 1
        try:
            safe_path(root, lua_path.relative_to(root).as_posix())
            imports, import_errors = static_requires(lua_path.read_text(encoding="utf-8"))
        except (OSError, ValueError, UnicodeError) as exc:
            fail("lua-read", lua_path, str(exc))
            continue
        for line, message in import_errors:
            fail("dynamic-require", lua_path, "line " + str(line) + ": " + message)
        for module, line in imports:
            counts["staticImports"] += 1
            target = root.joinpath(*module.split(".")).with_suffix(".lua")
            try:
                safe_path(root, target.relative_to(root).as_posix())
                if not target.is_file():
                    fail("require-missing", lua_path, "line " + str(line) + ": missing module " + module)
            except ValueError as exc:
                fail("path-safety", lua_path, "line " + str(line) + ": " + str(exc))
            parts = lua_path.relative_to(root).parts
            target_parts = target.relative_to(root).parts
            source_is_package = len(parts) > 4 and parts[:2] == ("gameplay", "packages")
            target_is_package = len(target_parts) > 4 and target_parts[:2] == ("gameplay", "packages")
            if source_is_package and module.startswith("gameplay.adapters."):
                fail("package-adapter-import", lua_path, "business packages must use context services rather than import an editor adapter")
            if parts[:2] == ("gameplay", "core") and target_is_package:
                fail("core-package-import", lua_path, "shared core must not import business packages; assemble them in bootstrap/factories")
            if source_is_package and target_is_package:
                source_id = parts[3]
                target_id = target_parts[3]
                if source_id != target_id and target_parts[-1] == "controller.lua":
                    fail("cross-package-controller", lua_path, "business packages must not import another package controller, even with a declared dependency")
                if source_id != target_id and source_id in manifests:
                    dependencies = manifests[source_id][1].get("dependencies", [])
                    if not isinstance(dependencies, list) or target_id not in dependencies:
                        fail("undeclared-import", lua_path, "cross-package import requires dependency on " + target_id)

    _validate_registry(root, manifests, fail)
    return {"ok": not errors, "mode": mode, "counts": counts, "errors": errors, "scope": SCOPE}


def _validate_registry(root: Path, manifests: dict[str, tuple[Path, dict[str, Any]]], fail: Any) -> None:
    """Verify both generated files against the canonical package manifests."""
    entries_path = root / "gameplay" / "registry_entries.json"
    lua_path = root / "gameplay" / "registry.lua"
    factories_path = root / "gameplay" / "package_factories.lua"
    if not entries_path.is_file():
        fail("registry-missing", entries_path, "generated registry entries are required")
    if not lua_path.is_file():
        fail("registry-missing", lua_path, "generated Lua registry is required")
    if not factories_path.is_file():
        fail("factories-missing", factories_path, "generated static package factories are required")
    if not entries_path.is_file() or not lua_path.is_file() or not factories_path.is_file():
        return
    try:
        from project_layout import factories_lua, lua_encode, registry_from_manifests
        for path in (entries_path, lua_path, factories_path):
            safe_path(root, path.relative_to(root).as_posix())
        expected = registry_from_manifests(root)
        entries = read_json(entries_path)
        if entries != expected:
            fail("registry-mismatch", entries_path, "registry entries must exactly match manifest-derived entries sorted by ID")
        expected_lua = "-- Generated from package manifests. Do not edit.\nreturn " + lua_encode(expected) + "\n"
        if lua_path.read_text(encoding="utf-8") != expected_lua:
            fail("registry-lua-mismatch", lua_path, "registry.lua must exactly match the generated Lua serialization")
        if factories_path.read_text(encoding="utf-8") != factories_lua(expected):
            fail("factories-mismatch", factories_path, "package factories must match generated static definition/controller imports")
    except (ImportError, OSError, ValueError, TypeError, KeyError) as exc:
        fail("registry-read", entries_path, str(exc))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--mode", choices=("contract", "delivery"), default="contract")
    parser.add_argument("--json", action="store_true", help="emit machine-readable result")
    args = parser.parse_args(argv)
    result = validate_root(args.root, args.mode)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if result["ok"] else "FAIL") + " — " + args.mode + " package contract")
        print(json.dumps(result["counts"], ensure_ascii=False))
        for error in result["errors"]:
            print("[" + error["code"] + "] " + error["path"] + ": " + error["message"])
        print(result["scope"])
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
