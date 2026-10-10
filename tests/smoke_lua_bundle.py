#!/usr/bin/env python3
"""Optional scaffold smoke test, using Lupa 2.6 / Lua 5.1, not the editor SDK.

Install the optional QA dependency in a temporary virtual environment:
    python3 -m pip install lupa==2.6
Build first with tools/bundle_lua.py, then run this file with --json.
Lupa is a test runtime only; it is not a production dependency or an SDK adapter.
Official runtime/version documentation: https://pypi.org/project/lupa/2.6/
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from bundle_lua import bundle  # noqa: E402

SCOPE = (
    "Lua syntax, static module closure, bootstrap service checks and future-template "
    "NOT_IMPLEMENTED lifecycle responses. Implemented Demo constructors are classified "
    "separately and exercised by tests/test_demo_runtime.py; native UI/SDK start is not "
    "called by inert doubles. No model import, SDK compatibility or preview acceptance."
)

DEMO_CONTROLLERS = {
    "player_default", "monster_cube", "weapon_shovel", "item_heal_small",
    "chest_basic", "map_demo", "ui_main",
}

HARNESS = r'''
local Bootstrap = SmokeBootstrap
local Api = SmokeServiceApi
local results = {}
local function record(name, detail)
  table.insert(results, {name=name, passed=true, detail=detail})
end
assert(type(Bootstrap) == "table" and type(Bootstrap.create) == "function")
record("bundle_loads_bootstrap", "Bootstrap.create is a Lua function")

local default_context = Bootstrap.create()
assert(default_context.is_ready == false)
local default_entity, default_error = default_context:new_entity("monster_marmot", {id="smoke_default"})
assert(default_entity == nil and default_error == "ADAPTER_NOT_READY")
record("default_adapter_rejected", default_error)

local empty_services = {}
for name, _ in pairs(Api.operations) do empty_services[name] = {} end
local empty_context = Bootstrap.create({is_ready=true, services=empty_services})
assert(empty_context.is_ready == false)
local empty_entity, empty_error = empty_context:new_entity("monster_marmot", {id="smoke_empty"})
assert(empty_entity == nil and empty_error == "ADAPTER_NOT_READY")
record("empty_service_tables_rejected", empty_error)

-- These methods are deliberately inert test doubles, not gameplay services.
local service_doubles = {}
local operation_count = 0
for name, operations in pairs(Api.operations) do
  service_doubles[name] = {}
  for _, operation in ipairs(operations) do
    service_doubles[name][operation] = function() return false, "TEST_DOUBLE_ONLY" end
    operation_count = operation_count + 1
  end
end
local ready_context = Bootstrap.create({is_ready=true, services=service_doubles})
assert(ready_context.is_ready == true)
record("declared_methods_allow_scaffold_binding", tostring(operation_count) .. " inert method doubles")

local entities = {}
local demo_count, planned_count = 0, 0
for _, entry in ipairs(ready_context.registry.entries) do
  local resources = {}
  for _, resource in ipairs(entry.resources) do resources[resource.id] = resource.kind end
  for _, clip in ipairs(entry.clips) do
    local kind = resources[clip.resourceId]
    assert(kind == "model" or kind == "animation" or kind == "scene_chunk")
  end
  local entity, error_code = ready_context:new_entity(entry.id, {id="smoke_" .. entry.id})
  assert(entity ~= nil and error_code == nil)
  local definition=SmokeDefinitions[entry.id]
  assert(definition.id == entry.id and definition.type == entry.type)
  if SmokeDemoControllers[entry.id] then
    assert(type(entity.start)=="function" and type(entity.dispose)=="function")
    if entry.id ~= "ui_main" then assert(entity.definition.id==entry.id) end
    -- These constructors are no longer future shells. An inert SDK context
    -- must not call their gameplay/native UI start or pretend to accept them.
    demo_count=demo_count+1
    table.insert(entities,{id=entry.id,start="DEMO_IMPLEMENTED",after_dispose="NOT_EXERCISED_HERE",kind="demo"})
  else
    assert(entity.definition.id == entry.id and entity.definition.type == entry.type)
    local started, start_code = entity:start()
    assert(started == false and start_code == "NOT_IMPLEMENTED")
    entity:dispose()
    local restarted, disposed_code = entity:start()
    assert(restarted == false and disposed_code == "DISPOSED")
    planned_count=planned_count+1
    table.insert(entities, {id=entry.id, start=start_code, after_dispose=disposed_code,kind="future_template"})
  end
end
assert(#entities > 0)
record("definition_identity_matches_manifest", tostring(#entities) .. " definition IDs and types match registry entries")
record("clip_sources_match_owned_runtime_resources", "Every clip identifies its package's runtime model/animation/scene chunk")
record("future_templates_refuse_gameplay_start", tostring(planned_count) .. " future controllers return NOT_IMPLEMENTED")
record("disposed_future_templates_refuse_restart", tostring(planned_count) .. " future controllers return DISPOSED")
record("implemented_demo_controllers_classified_separately",tostring(demo_count).." implemented constructors; use real Demo integration tests")

local unknown, unknown_code = ready_context:new_entity("unknown_entity", {id="smoke_unknown"})
assert(unknown == nil and unknown_code == "UNKNOWN_ENTITY")
record("unknown_entity_rejected", unknown_code)
return {checks=results, entities=entities, declared_method_count=operation_count,demo_count=demo_count,planned_count=planned_count}
'''


def _array(table) -> list:
    return [table[index] for index in range(1, len(table) + 1)]


def smoke(root: Path, bundle_path: Path | None = None) -> dict:
    from lupa import lua51
    root = root.resolve()
    bundle_path = bundle_path or root / "dist" / "zaizai_surreal.lua"
    source = bundle_path.read_text(encoding="utf-8")
    expected, count = bundle(root)
    if source != expected:
        raise ValueError("bundle is stale; regenerate with tools/bundle_lua.py")
    runtime = lua51.LuaRuntime(unpack_returned_tuples=True)
    bootstrap = runtime.execute(source)
    service_api = runtime.execute((root / "gameplay" / "core" / "service_api.lua").read_text(encoding="utf-8"))
    runtime.globals().SmokeBootstrap = bootstrap
    runtime.globals().SmokeServiceApi = service_api
    runtime.globals().SmokeDemoControllers = runtime.table_from({name: True for name in DEMO_CONTROLLERS})
    definitions = runtime.table()
    registry = json.loads((root / "gameplay" / "registry_entries.json").read_text(encoding="utf-8"))
    for entry in registry["entries"]:
        path = root / (entry["definitionModule"].replace(".", "/") + ".lua")
        definitions[entry["id"]] = runtime.execute(path.read_text(encoding="utf-8"))
    runtime.globals().SmokeDefinitions = definitions
    result = runtime.execute(HARNESS)
    checks = [{"name": row["name"], "passed": row["passed"], "detail": row["detail"]} for row in _array(result["checks"])]
    entities = [{"id": row["id"], "start": row["start"], "afterDispose": row["after_dispose"], "kind": row["kind"]} for row in _array(result["entities"])]
    return {
        "ok": True,
        "runtime": {"package": "lupa", "version": importlib.metadata.version("lupa"), "module": "lupa.lua51", "implementation": runtime.lua_implementation, "luaVersion": list(lua51.LUA_VERSION)},
        "bundle": {"path": bundle_path.relative_to(root).as_posix(), "moduleCount": count, "sha256": hashlib.sha256(source.encode("utf-8")).hexdigest()},
        "declaredMethodCount": result["declared_method_count"],
        "implementedDemoConstructors": result["demo_count"],
        "futureTemplateControllers": result["planned_count"],
        "checks": checks,
        "entities": entities,
        "scope": SCOPE,
        "documentation": "https://pypi.org/project/lupa/2.6/",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--bundle", type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)
    try:
        result = smoke(args.root, args.bundle)
    except ImportError as exc:
        result = {"ok": False, "error": "OPTIONAL_QA_DEPENDENCY_MISSING", "detail": str(exc), "scope": SCOPE}
    except Exception as exc:
        result = {"ok": False, "error": "LUA_SMOKE_FAILED", "detail": str(exc), "scope": SCOPE}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(("PASS" if result["ok"] else "FAIL") + " — optional Lua scaffold smoke")
        print(result.get("runtime", result.get("detail")))
        for check in result.get("checks", []):
            print(check["name"] + ": " + check["detail"])
        print(SCOPE)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
