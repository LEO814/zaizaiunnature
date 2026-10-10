#!/usr/bin/env python3
"""Build the real editor whitebox from its seed; default is a read-only dry run.

Close the project in the editor before passing --install. This tool never drives
the editor, changes project.json/world-config.json, or claims preview acceptance.
Canonical art/gameplay/docs/tools/tests/dist, README.md and root repository/QA
metadata are copied without changing their relative paths. scripts/ contains the
generated native Lua wrappers; dist/ remains the offline bootstrap build.
"""

from __future__ import annotations

import argparse
import ast
import copy
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import time
import zipfile
import zlib


PROJECT_NAME = "仔仔搜打撤1.0"
DEFAULT_EDITOR_PROJECT = Path.home() / "Library/Application Support/AI World Creator/projects/project_wv4fb1w4"
MANAGED = ("art", "gameplay", "docs", "tools", "tests", "dist", "scripts", "README.md", ".gitignore", "requirements_qa.txt")
IGNORE_NAMES = {".git", ".DS_Store", "__pycache__", ".venv", "node_modules"}
SCRIPTS = {
    "demo_entry": "b680ca44-9e0d-4880-9820-65899787da8d",
    "player_attributes": "ed22f5e1-e7bd-4bfe-9d47-f535a7ad2bee",
    "monster_attributes": "63480fdf-d72b-48cc-9a5a-583a92702ea9",
    "match_attributes": "b6a67278-5cf1-4f71-89c4-925ebcdd41a4",
}
NATIVE_JSON = "SerializePcgData.json"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class LiteralLuaTable:
    """Read only return {literal tables}; no Lua evaluation or guessed SDK API."""

    token_re = re.compile(
        r"\s+|--[^\n]*(?:\n|$)|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\""
        r"|-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[A-Za-z_]\w*|[{}\[\]=,;]"
    )

    def __init__(self, source: str):
        self.tokens = []
        offset = 0
        while offset < len(source):
            match = self.token_re.match(source, offset)
            if not match:
                raise ValueError("map definition must contain only literal Lua tables at offset %d" % offset)
            token = match.group()
            if not token.isspace() and not token.startswith("--"):
                self.tokens.append(token)
            offset = match.end()
        self.index = 0

    def pop(self, expected=None):
        if self.index >= len(self.tokens):
            raise ValueError("unexpected end of literal map definition")
        token = self.tokens[self.index]
        self.index += 1
        if expected is not None and token != expected:
            raise ValueError("expected %r, found %r" % (expected, token))
        return token

    def value(self):
        token = self.pop()
        if token == "{":
            keyed, array = {}, []
            while self.tokens[self.index] != "}":
                head = self.tokens[self.index]
                if self.index + 1 < len(self.tokens) and self.tokens[self.index + 1] == "=":
                    key = self.pop()
                    self.pop("=")
                    if not re.fullmatch(r"[A-Za-z_]\w*", key) or key in keyed:
                        raise ValueError("invalid or duplicate Lua table key %r" % key)
                    keyed[key] = self.value()
                else:
                    array.append(self.value())
                if self.tokens[self.index] in (",", ";"):
                    self.pop()
                elif self.tokens[self.index] != "}":
                    raise ValueError("Lua table fields require a separator")
            self.pop("}")
            if keyed and array:
                raise ValueError("mixed Lua tables are not supported for map definitions")
            return keyed if keyed or not array else array
        if token.startswith(("'", '"')):
            return ast.literal_eval(token)
        if token == "true":
            return True
        if token == "false":
            return False
        if token == "nil":
            return None
        if re.fullmatch(r"-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", token):
            return float(token) if any(c in token for c in ".eE") else int(token)
        raise ValueError("non-literal value in map definition: %r" % token)

    def parse(self):
        self.pop("return")
        result = self.value()
        if self.index != len(self.tokens):
            raise ValueError("unexpected content after map return table")
        if not isinstance(result, dict):
            raise ValueError("map definition must return a keyed table")
        return result


def source_inventory(root: Path):
    files, directories = {}, set()
    for top in MANAGED:
        path = root / top
        if not path.exists():
            raise ValueError("missing canonical source path: " + str(path))
        paths = [path] if path.is_file() else [path, *sorted(path.rglob("*"))]
        for current in paths:
            relative = current.relative_to(root)
            if any(part in IGNORE_NAMES for part in relative.parts) or current.suffix in (".pyc", ".pyo"):
                continue
            if current.is_symlink():
                raise ValueError("canonical sync does not follow symlinks: " + str(current))
            if current.is_dir():
                directories.add(relative.as_posix())
            elif current.is_file():
                files[relative.as_posix()] = current.read_bytes()
    return files, sorted(directories)


def native_binding(name):
    return {"scriptId": SCRIPTS[name], "scriptType": 1, "paramsJson": "{}"}


def wrapper_sources(root: Path):
    wrappers = {}
    for name, script_id in SCRIPTS.items():
        path = root / "scripts/modules" / (name + ".lua")
        source = path.read_text(encoding="utf-8")
        header = re.search(r"^---@id\s+(\S+)\s*$", source, re.M)
        if not header or header.group(1) != script_id:
            raise ValueError("native wrapper UUID mismatch: " + str(path))
        if "---@referenceName " + name + ".lua" not in source:
            raise ValueError("native wrapper referenceName mismatch: " + str(path))
        wrappers[name] = source
    entry = wrappers["demo_entry"]
    modules = re.findall(r'^module_loaders\["([A-Za-z_][\w.]*)"\] = function\(\)$', entry, re.M)
    if not modules or "function Start()" not in entry:
        raise ValueError("demo_entry.lua is not the generated functional native bundle")
    for module in modules:
        canonical = root / (module.replace(".", "/") + ".lua")
        prefix = 'module_loaders["' + module + '"] = function()\n  local require = ProjectRequire\n'
        if prefix + canonical.read_text(encoding="utf-8") + "\nend" not in entry:
            raise ValueError("stale generated wrapper; rerun tools/build_editor_bundle.py: " + module)
    for name in ("player_attributes", "monster_attributes", "match_attributes"):
        if wrappers[name] != (root / "gameplay/adapters/zaizai" / (name + ".lua")).read_text(encoding="utf-8"):
            raise ValueError("stale attribute wrapper: " + name)
    return wrappers


def build_scene(root: Path, wrappers: dict):
    seed = json.loads((root / "docs/editor_seed_scene.json").read_text(encoding="utf-8"))
    backup_zip = root / "docs/editor_seed_backup/scene.data"
    with zipfile.ZipFile(backup_zip) as archive:
        if json.loads(archive.read(NATIVE_JSON)) != seed:
            raise ValueError("editor_seed_scene.json differs from the preserved native seed ZIP")
    scene = copy.deepcopy(seed)
    old_nodes = seed["nodeTransformDatas"]
    by_name = {node["nodeName"]: node for node in old_nodes}
    cube, capsule, born, map_seed = (by_name[n] for n in ("monster_cube", "player_default", "出生点", "地图"))
    for template in (cube, capsule):
        prefab = template["localPrefabData"]["refPrefabId"]
        if prefab not in {ref["id"] for ref in seed["resourceRefs"]}:
            raise ValueError("native primitive prefab reference is absent from seed resourceRefs")
    definition = LiteralLuaTable((root / "gameplay/packages/environment/map_demo/definition.lua").read_text(encoding="utf-8")).parse()
    if len(definition["rooms"]) != 4:
        raise ValueError("this native Demo requires exactly four connected rooms")
    if definition["monsterSpawn"] != {"x": 8, "y": 0.6, "z": 8}:
        raise ValueError("monster spawn must be 8,0.6,8 outside sight_cover")
    taken = {node["id"] for node in old_nodes}

    def new_id(name):
        raw = zlib.crc32(("zaizai-search-extract-v1/" + name).encode("utf-8"))
        value = raw if raw < 2**31 else raw - 2**32
        if value == 0 or value in taken:
            raise ValueError("stable native node ID collision: " + name)
        taken.add(value)
        return value

    root_node = copy.deepcopy(map_seed)
    root_node.update(id=new_id("demo_root"), nodeName="demo_root", parentId=0,
                     pos={"x": 0, "y": 0, "z": 0}, scale={"x": 1, "y": 1, "z": 1},
                     isStatic=True, isActive=True)
    root_node["appearanceData"] = copy.deepcopy(cube["appearanceData"])
    root_node["appearanceData"].update(visible=False, castShadows=False, isModified=True)
    root_node["physicsColliderData"] = copy.deepcopy(cube["physicsColliderData"])
    root_node["physicsColliderData"].update(enableCollision=False, enableRigidBody=False, useGravity=False)
    root_node["runtimeScriptBindings"] = [native_binding("demo_entry"), native_binding("match_attributes")]
    nodes = [root_node]

    def primitive(name, position, scale, color, *, template=cube, existing_id=None, static=True, collision=True, bindings=None):
        node = copy.deepcopy(template)
        node.update(id=existing_id if existing_id is not None else new_id(name), nodeName=name,
                    parentId=root_node["id"], pos=position, scale={"x": scale[0], "y": scale[1], "z": scale[2]},
                    rot={"x": 0, "y": 0, "z": 0, "w": 1}, isStatic=static, isActive=True)
        node["appearanceData"].update(color={"r": color[0], "g": color[1], "b": color[2], "a": 1},
                                      visible=True, castShadows=True, isModified=True)
        node["physicsColliderData"].update(enableCollision=collision, enableRigidBody=False, useGravity=False)
        node["runtimeScriptBindings"] = bindings or []
        nodes.append(node)
        return node

    floor_colors = [(0.25, 0.30, 0.34), (0.32, 0.29, 0.23), (0.29, 0.29, 0.34), (0.34, 0.23, 0.23)]
    for room, color in zip(definition["rooms"], floor_colors):
        primitive("floor_" + room["id"], {"x": room["x"], "y": -0.15, "z": room["z"]}, (10, 0.3, 10), color)
    for wall in definition["walls"]:
        primitive(wall["name"], {"x": wall["x"], "y": 1.2, "z": wall["z"]},
                  (wall["sx"], 2.4, wall["sz"]), (0.43, 0.46, 0.49))
    primitive("monster_cube", definition["monsterSpawn"], (1.2, 1.2, 1.2), (0.8, 0.22, 0.15),
              existing_id=cube["id"], static=False, bindings=[native_binding("monster_attributes")])
    primitive("player_default", {"x": -3, "y": 0.9, "z": -3}, (0.65, 0.9, 0.65), (0.17, 0.55, 0.88),
              template=capsule, existing_id=capsule["id"], collision=False, bindings=[native_binding("player_attributes")])
    primitive("chest_basic", definition["chest"], (1.2, 0.8, 0.8), (0.48, 0.25, 0.09))
    primitive("chest_basic_lid", {"x": definition["chest"]["x"], "y": 0.94, "z": definition["chest"]["z"]},
              (1.2, 0.08, 0.8), (0.72, 0.48, 0.14), static=False, collision=False)
    primitive("gate_exit", definition["exit"], (2, 0.1, 2), (0.10, 0.82, 0.28), collision=False)
    born_node = copy.deepcopy(born)
    born_node.update(parentId=root_node["id"], pos=definition["spawn"], scale={"x": 1, "y": 1, "z": 1})
    born_node.pop("runtimeScriptBindings", None)
    nodes.append(born_node)
    scene.update(nodeTransformDatas=nodes, spawnPointData=[{"id": born_node["id"]}], moveMaxSpeed=3.2, jumpMaxHeight=0.8)
    for name, script_id in SCRIPTS.items():
        scene["runtimeScripts"][script_id] = {"content": wrappers[name], "referenceName": name + ".lua",
                                              "referencePath": "modules/" + name + ".lua", "isModuleScript": False}
    if scene["resourceRefs"] != seed["resourceRefs"]:
        raise ValueError("seed resourceRefs were modified")
    for script_id, script in seed["runtimeScripts"].items():
        if script_id not in SCRIPTS.values() and scene["runtimeScripts"][script_id] != script:
            raise ValueError("official or built-in runtime script was modified: " + script_id)
    names = [node["nodeName"] for node in nodes]
    if len(names) != len(set(names)) or len({node["id"] for node in nodes}) != len(nodes):
        raise ValueError("duplicate native node names or IDs")
    return scene, definition, seed


def packed_scene(root: Path, scene: dict) -> bytes:
    output = io.BytesIO()
    with zipfile.ZipFile(root / "docs/editor_seed_backup/scene.data") as seed_zip, zipfile.ZipFile(output, "w") as target:
        target.comment = seed_zip.comment
        for info in seed_zip.infolist():
            data = json.dumps(scene, ensure_ascii=False, separators=(",", ":")).encode("utf-8") if info.filename == NATIVE_JSON else seed_zip.read(info.filename)
            target.writestr(copy.copy(info), data)
    return output.getvalue()


def verify_archive(root: Path, content: bytes, scene: dict):
    with zipfile.ZipFile(root / "docs/editor_seed_backup/scene.data") as seed_zip, zipfile.ZipFile(io.BytesIO(content)) as installed:
        if installed.namelist() != seed_zip.namelist():
            raise ValueError("native scene ZIP member list changed")
        if json.loads(installed.read(NATIVE_JSON)) != scene:
            raise ValueError("native scene JSON readback does not match build")
        kept = []
        for name in seed_zip.namelist():
            if name != NATIVE_JSON:
                if installed.read(name) != seed_zip.read(name):
                    raise ValueError("native ZIP asset changed: " + name)
                kept.append(name)
    return kept


def install(root: Path, target: Path, files: dict, directories: list, scene_bytes: bytes):
    """Stage a complete canonical copy, back up managed paths, atomically replace."""
    protected = {name: (target / name).read_bytes() for name in ("project.json", "world-config.json")}
    before_hashes = {path: sha256(data) for path, data in files.items()}
    stamp = time.strftime("%Y%m%d-%H%M%S") + "-" + str(time.time_ns())
    backup = target / ".demo_install_backups" / stamp
    replaced = []
    with tempfile.TemporaryDirectory(prefix=".demo_stage_", dir=target) as staging:
        stage = Path(staging)
        for relative in directories:
            (stage / relative).mkdir(parents=True, exist_ok=True)
        for relative, data in files.items():
            path = stage / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        (stage / "scene.data").write_bytes(scene_bytes)
        now_files, now_dirs = source_inventory(root)
        if {path: sha256(data) for path, data in now_files.items()} != before_hashes or now_dirs != directories:
            raise ValueError("canonical source changed while staging; rebuild then retry")
        backup.mkdir(parents=True)
        try:
            for relative in (*MANAGED, "scene.data"):
                current = target / relative
                saved = backup / relative
                existed = current.exists()
                if existed:
                    os.replace(current, saved)
                replaced.append((current, saved, existed))
                os.replace(stage / relative, current)
            native_files, native_dirs = source_inventory(target)
            if {path: sha256(data) for path, data in native_files.items()} != before_hashes or native_dirs != directories:
                raise ValueError("installed canonical tree differs from its source")
            for name, original in protected.items():
                if (target / name).read_bytes() != original:
                    raise ValueError("protected editor configuration changed: " + name)
            if (target / "scene.data").read_bytes() != scene_bytes:
                raise ValueError("installed scene.data differs from its staged bytes")
        except BaseException:
            for current, saved, existed in reversed(replaced):
                if current.is_dir():
                    shutil.rmtree(current)
                elif current.exists():
                    current.unlink()
                if existed and saved.exists():
                    os.replace(saved, current)
            raise
    return {"backup": str(backup), "sourceNativeFilesIdentical": True,
            "sourceNativeDirectoriesIdentical": True, "protectedConfigurationUnchanged": True,
            "canonicalFileHashes": before_hashes}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--editor-project", type=Path, default=DEFAULT_EDITOR_PROJECT)
    parser.add_argument("--install", action="store_true", help="write only after this project is closed in the editor")
    args = parser.parse_args()
    root, target = args.source_root.resolve(), args.editor_project.resolve()
    try:
        if root == target or root in target.parents or target in root.parents:
            raise ValueError("canonical source and native editor project must be separate trees")
        native_project = json.loads((target / "project.json").read_text(encoding="utf-8"))
        if native_project.get("name") != PROJECT_NAME:
            raise ValueError("target project.json name is not " + PROJECT_NAME)
        wrappers = wrapper_sources(root)
        scene, definition, seed = build_scene(root, wrappers)
        content = packed_scene(root, scene)
        archive_assets = verify_archive(root, content, scene)
        files, directories = source_inventory(root)
        registry = json.loads(files["gameplay/registry_entries.json"])["entries"]
        if len(registry) != 18 or len({entry["id"] for entry in registry}) != 18:
            raise ValueError("Demo registry must contain exactly 18 unique canonical entities")
        report = {
            "ok": True, "mode": "installed" if args.install else "dry-run", "projectName": PROJECT_NAME,
            "sourceRoot": str(root), "editorProject": str(target), "roomCount": len(definition["rooms"]),
            "wallCount": len(definition["walls"]), "nativeNodeCount": len(scene["nodeTransformDatas"]),
            "registryEntityCount": len(registry), "registryEntityIds": [entry["id"] for entry in registry],
            "topLevelPaths": list(MANAGED), "canonicalFileCount": len(files), "canonicalDirectoryCount": len(directories),
            "spawn": definition["spawn"], "monsterSpawn": definition["monsterSpawn"],
            "sceneMoveSpeed": scene["moveMaxSpeed"], "sceneJumpHeight": scene["jumpMaxHeight"],
            "removedDefaultNodes": [node["nodeName"] for node in seed["nodeTransformDatas"][:6]],
            "officialRuntimeScriptsPreserved": True, "resourceRefsPreserved": True,
            "zipAssetMembersPreserved": archive_assets, "nativeScriptBindings": {
                node["nodeName"]: node["runtimeScriptBindings"] for node in scene["nodeTransformDatas"] if node.get("runtimeScriptBindings")
            }, "previewAcceptance": "not performed by this filesystem installer",
        }
        if args.install:
            report.update(install(root, target, files, directories, content))
            readback = json.loads((target / "gameplay/registry_entries.json").read_text(encoding="utf-8"))
            if readback["entries"] != registry:
                raise ValueError("native registry entity readback differs")
            report["registryReadbackMatches"] = True
            report["topLevelReadback"] = {name: (target / name).is_dir() if (root / name).is_dir() else (target / name).is_file() for name in MANAGED}
        else:
            report["nativeProjectWritten"] = False
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, IndexError, zipfile.BadZipFile) as exc:
        print(json.dumps({"ok": False, "mode": "installed" if args.install else "dry-run", "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
