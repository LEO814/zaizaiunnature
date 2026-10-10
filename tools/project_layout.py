"""Canonical module names and registry generation for the blank scaffold."""
import json
from pathlib import Path

VERSION = "0.2.0"
REGISTRY_HEADER = "-- Generated from package manifests. Do not edit.\nreturn "

def lua_encode(value, level=0):
    pad = "  " * level
    inner = "  " * (level + 1)
    if value is None: return "nil"
    if value is True: return "true"
    if value is False: return "false"
    if isinstance(value, (int, float)): return str(value)
    if isinstance(value, str): return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{\n" + "".join(inner + lua_encode(x, level + 1) + ",\n" for x in value) + pad + "}"
    return "{\n" + "".join(inner + "[" + lua_encode(str(k)) + "] = " + lua_encode(v, level + 1) + ",\n" for k, v in value.items()) + pad + "}"

def registry_from_manifests(root):
    fields = ["id", "packageId", "type", "definitionModule", "controllerModule", "resources", "clips"]
    entries = []
    for path in sorted((Path(root) / "gameplay/packages").glob("*/*/manifest.json")):
        manifest = json.loads(path.read_text(encoding="utf-8"))
        entry = {key: manifest[key] for key in fields}
        entry["manifestPath"] = path.relative_to(root).as_posix()
        entries.append(entry)
    return {"schemaVersion": VERSION, "entries": sorted(entries, key=lambda e: e["id"])}

def factories_lua(registry):
    rows = ["-- Generated from package manifests. Do not edit.", "return {"]
    for entry in registry["entries"]:
        rows += ["  [" + lua_encode(entry["id"]) + "] = {",
                 "    definition = require(" + lua_encode(entry["definitionModule"]) + "),",
                 "    controller = require(" + lua_encode(entry["controllerModule"]) + "),", "  },"]
    return "\n".join(rows + ["}", ""])

def write_registry(root):
    root = Path(root)
    registry = registry_from_manifests(root)
    (root / "gameplay/registry_entries.json").write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (root / "gameplay/registry.lua").write_text(REGISTRY_HEADER + lua_encode(registry) + "\n", encoding="utf-8")
    (root / "gameplay/package_factories.lua").write_text(factories_lua(registry), encoding="utf-8")
    return registry
