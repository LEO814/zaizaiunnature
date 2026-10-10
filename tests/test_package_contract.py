"""Regression tests for meaningful package-contract failure cases; no editor simulation."""
from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1] / "tools"
sys.path.insert(0, str(TOOLS))
from project_layout import lua_encode, write_registry  # noqa: E402
from validate_packages import SERVICE_NAMES, TYPE_DIRECTORIES, static_requires, validate_root  # noqa: E402


class PackageContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="zaizai-package-contract-")
        self.root = Path(self.temp.name) / "project"
        for directory in set(TYPE_DIRECTORIES.values()):
            (self.root / "gameplay" / "packages" / directory).mkdir(parents=True)
        core = self.root / "gameplay" / "core"
        core.mkdir(parents=True)
        (core / "config.lua").write_text("return {}\n", encoding="utf-8")
        self.write_json(core / "service_contracts.json", {"schemaVersion": "0.2.0", "services": sorted(SERVICE_NAMES)})
        (core / "service_contracts.lua").write_text("return " + lua_encode(sorted(SERVICE_NAMES)) + "\n", encoding="utf-8")
        self.package = self.make_package("item_heal", "item")
        self.rebuild()

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def write_json(path: Path, data: object) -> None:
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def make_package(self, entity_id: str, type_name: str) -> Path:
        package = self.root / "gameplay" / "packages" / TYPE_DIRECTORIES[type_name] / entity_id
        package.mkdir()
        for directory in ("model", "animations", "materials", "tests"):
            (package / directory).mkdir()
            (package / directory / ".gitkeep").write_text("", encoding="utf-8")
        (package / "README.md").write_text("# Planned example\n", encoding="utf-8")
        module_prefix = ".".join(package.relative_to(self.root).parts)
        (package / "definition.lua").write_text('return { id = "' + entity_id + '" }\n', encoding="utf-8")
        (package / "controller.lua").write_text(
            'local definition = require("' + module_prefix + '.definition")\n'
            'local config = require("gameplay.core.config")\nreturn {}\n', encoding="utf-8"
        )
        prefix = package.relative_to(self.root).as_posix()
        self.write_json(package / "manifest.json", {
            "id": entity_id, "type": type_name, "status": "planned", "packageId": "PKG-ITEM",
            "schemaVersion": "0.2.0", "definitionModule": module_prefix + ".definition",
            "controllerModule": module_prefix + ".controller",
            "resources": [
                {"id": "asset_" + entity_id, "path": prefix + "/model/main.glb", "kind": "model", "status": "planned"},
                {"id": "source_" + entity_id, "path": prefix + "/model/source.blend", "kind": "source", "status": "planned"},
            ],
            "clips": [{"id": "clip_" + entity_id + "_use", "name": "Use", "role": "use", "resourceId": "asset_" + entity_id}],
            "requiredServices": ["Characters", "Inventory"], "dependencies": [],
        })
        return package

    def mutate(self, action, package: Path | None = None) -> None:
        path = (package or self.package) / "manifest.json"
        manifest = json.loads(path.read_text(encoding="utf-8"))
        action(manifest)
        self.write_json(path, manifest)
        self.rebuild()

    def rebuild(self) -> None:
        write_registry(self.root)

    def assert_code(self, expected: str, mode: str = "contract") -> None:
        result = validate_root(self.root, mode)
        self.assertFalse(result["ok"], result)
        self.assertIn(expected, {error["code"] for error in result["errors"]}, result)

    def test_planned_contract_passes_without_models(self) -> None:
        result = validate_root(self.root)
        self.assertTrue(result["ok"], result)
        self.assertEqual(result["counts"]["packages"], 1)
        self.assertIn("does not parse GLB", result["scope"])

    def test_delivery_rejects_planned_content(self) -> None:
        self.assert_code("planned-package", "delivery")

    def test_declared_delivered_resource_requires_file(self) -> None:
        self.mutate(lambda m: m["resources"][0].update(status="delivered"))
        self.assert_code("resource-missing")

    def test_missing_module(self) -> None:
        (self.package / "definition.lua").unlink()
        self.assert_code("module-missing")

    def test_missing_package_readme_and_directory(self) -> None:
        (self.package / "README.md").unlink()
        (self.package / "animations" / ".gitkeep").unlink()
        (self.package / "animations").rmdir()
        self.assert_code("readme")
        self.assert_code("package-directory")

    def test_schema_id_and_type_mismatch(self) -> None:
        self.mutate(lambda m: m.update(schemaVersion="0.1.0", id="ItemHeal", type="weapon"))
        self.assert_code("schema-version")
        self.assert_code("id-format")
        self.assert_code("type-directory")

    def test_duplicate_resource_and_clip_id(self) -> None:
        self.mutate(lambda m: m["clips"][0].update(id=m["resources"][0]["id"]))
        self.assert_code("duplicate-id")

    def test_additional_resource_locations_and_clip_binding(self) -> None:
        prefix = self.package.relative_to(self.root).as_posix()
        def add_resources(manifest):
            manifest["resources"].extend([
                {"id": "asset_heal_actions", "path": prefix + "/animations/player_actions.glb", "kind": "animation", "status": "planned"},
                {"id": "texture_heal_base", "path": prefix + "/materials/base_color.png", "kind": "texture", "status": "planned"},
                {"id": "asset_heal_chunk", "path": prefix + "/model/chunks/room_a.glb", "kind": "scene_chunk", "status": "planned"},
            ])
            manifest["clips"][0]["resourceId"] = "asset_heal_actions"
        self.mutate(add_resources)
        self.assertTrue(validate_root(self.root)["ok"])
        self.mutate(lambda m: m["resources"][2].update(path=prefix + "/model/player_actions.glb"))
        self.assert_code("resource-location")

    def test_clip_requires_owned_runtime_resource(self) -> None:
        self.mutate(lambda m: m["clips"][0].update(resourceId="asset_missing"))
        self.assert_code("clip-resource")
        self.mutate(lambda m: m["clips"][0].update(resourceId="source_item_heal"))
        self.assert_code("clip-resource")

    def test_resource_traversal_and_wrong_module(self) -> None:
        self.mutate(lambda m: (m["resources"][0].update(path="../outside.glb"), m.update(controllerModule="gameplay.core.config")))
        self.assert_code("path-safety")
        self.assert_code("module-path")

    def test_dangling_and_self_dependencies(self) -> None:
        self.mutate(lambda m: m.update(dependencies=["monster_missing", "item_heal"]))
        self.assert_code("dependency-missing")
        self.assert_code("self-dependency")

    def test_unknown_service_is_rejected(self) -> None:
        self.mutate(lambda m: m.update(requiredServices=["Inventroy"]))
        self.assert_code("services")

    def test_service_lua_must_match_json(self) -> None:
        (self.root / "gameplay" / "core" / "service_contracts.lua").write_text('return { "Combat", }\n', encoding="utf-8")
        self.assert_code("service-lua-mismatch")

    def test_dynamic_require_rejected_comments_and_strings_ignored(self) -> None:
        (self.package / "controller.lua").write_text(
            '-- require("missing.comment")\nlocal text = "require(something)"\n'
            'local x = require("gameplay.core." .. name)\nreturn {}\n', encoding="utf-8"
        )
        self.assert_code("dynamic-require")
        imports, errors = static_requires('--[=[require(name)]=]\nlocal text = [[require(name)]]\nrequire "gameplay.core.config"')
        self.assertEqual(imports, [("gameplay.core.config", 3)])
        self.assertEqual(errors, [])

    def test_missing_static_require(self) -> None:
        (self.package / "controller.lua").write_text('return require("gameplay.core.missing")\n', encoding="utf-8")
        self.assert_code("require-missing")

    def test_cross_package_import_requires_dependency(self) -> None:
        self.make_package("monster_sample", "monster")
        self.rebuild()
        (self.package / "controller.lua").write_text('return require("gameplay.packages.monsters.monster_sample.definition")\n', encoding="utf-8")
        self.assert_code("undeclared-import")
        self.mutate(lambda m: m.update(dependencies=["monster_sample"]))
        self.assertTrue(validate_root(self.root)["ok"])

    def test_other_package_controller_forbidden_despite_dependency(self) -> None:
        self.make_package("monster_sample", "monster")
        self.mutate(lambda m: m.update(dependencies=["monster_sample"]))
        (self.package / "controller.lua").write_text('return require("gameplay.packages.monsters.monster_sample.controller")\n', encoding="utf-8")
        self.assert_code("cross-package-controller")

    def test_business_package_cannot_import_editor_adapter(self) -> None:
        adapter = self.root / "gameplay" / "adapters" / "zaizai" / "adapter.lua"
        adapter.parent.mkdir(parents=True)
        adapter.write_text("return {}\n", encoding="utf-8")
        (self.package / "controller.lua").write_text('return require("gameplay.adapters.zaizai.adapter")\n', encoding="utf-8")
        self.assert_code("package-adapter-import")

    def test_core_cannot_import_business_package(self) -> None:
        (self.root / "gameplay" / "core" / "config.lua").write_text('return require("gameplay.packages.items.item_heal.definition")\n', encoding="utf-8")
        self.assert_code("core-package-import")

    def test_registry_json_and_lua_drift(self) -> None:
        path = self.root / "gameplay" / "registry_entries.json"
        self.write_json(path, {"schemaVersion": "0.2.0", "entries": []})
        self.assert_code("registry-mismatch")
        self.rebuild()
        (self.root / "gameplay" / "registry.lua").write_text("return {}\n", encoding="utf-8")
        self.assert_code("registry-lua-mismatch")

    def test_factories_drift(self) -> None:
        (self.root / "gameplay" / "package_factories.lua").write_text("return {}\n", encoding="utf-8")
        self.assert_code("factories-mismatch")

    def test_symlink_escape_is_rejected(self) -> None:
        outside = Path(self.temp.name) / "outside.glb"
        outside.write_bytes(b"fixture")
        (self.package / "model" / "main.glb").symlink_to(outside)
        self.assert_code("path-safety")


if __name__ == "__main__":
    unittest.main()
