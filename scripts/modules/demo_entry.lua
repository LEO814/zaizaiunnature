---@id b680ca44-9e0d-4880-9820-65899787da8d
---@referenceName demo_entry.lua
---@start
---@end
local Demo = (function()
-- Generated canonical Demo bundle. Native SDK mapping is isolated in zaizai adapter.
local module_loaders = {}
local module_cache = {}
local loading = {}
local ProjectRequire
ProjectRequire = function(name)
  if module_cache[name] ~= nil then return module_cache[name] end
  if loading[name] then error("CIRCULAR_MODULE:" .. name) end
  local loader = module_loaders[name]
  if not loader then error("UNKNOWN_MODULE:" .. name) end
  loading[name] = true
  local result = loader()
  loading[name] = nil
  if result == nil then error("MODULE_RETURN_REQUIRED:" .. name) end
  module_cache[name] = result
  return result
end
module_loaders["gameplay.core.config"] = function()
  local require = ProjectRequire
-- Canonical default values; proposed and not play-tested.
return {
  ["schemaVersion"] = "0.2.0",
  ["projectName"] = "仔仔搜打撤1.0",
  ["state"] = "proposed_blank_project",
  ["units"] = {
    ["length"] = "m",
    ["time"] = "s",
    ["angle"] = "deg",
    ["mass"] = "kg",
    ["health"] = "HP",
    ["ratio"] = "0..1",
  },
  ["axes"] = {
    ["right"] = "+X",
    ["up"] = "+Y",
    ["forward"] = "+Z",
    ["adapterVerification"] = "G0_required",
  },
  ["player"] = {
    ["maxHp"] = 100,
    ["startHp"] = 100,
    ["armorFlatHp"] = 0,
    ["damageReductionRatio"] = 0,
    ["walkSpeedMps"] = 3.2,
    ["sprintSpeedMps"] = 5.0,
    ["crouchSpeedMps"] = 1.6,
    ["jumpHeightM"] = 0.8,
    ["colliderRadiusM"] = 0.35,
    ["colliderHeightM"] = 1.8,
    ["colliderCenterY_M"] = 0.9,
    ["spawnProtectionSec"] = 3,
    ["hitInvulnerabilitySec"] = 0.2,
    ["stamina"] = {
      ["enabled"] = false,
      ["max"] = 100,
      ["sprintCostPerSec"] = 20,
      ["regenPerSec"] = 15,
      ["regenDelaySec"] = 1.5,
    },
  },
  ["inventory"] = {
    ["bagSlots"] = 12,
    ["maxWeightKg"] = 30,
    ["enforceWeight"] = false,
    ["equipmentSlots"] = {
      "weapon",
      "tool",
    },
    ["equipmentUsesBagSlot"] = false,
    ["quickSlotCount"] = 4,
    ["quickSlotsEnabled"] = false,
    ["quickSlotsAreReferences"] = true,
    ["batDropPolicy"] = "all_unprotected_bag_once_per_attachment",
    ["dropEquipmentOnBatAttach"] = false,
  },
  ["interaction"] = {
    ["maxDistanceM"] = 2.2,
    ["requireLineOfSight"] = true,
    ["modalBlocksWorldInput"] = true,
    ["containerRollPolicy"] = "first_open_only",
  },
  ["combat"] = {
    ["friendlyFire"] = false,
    ["allowDeadTarget"] = false,
    ["damageRounding"] = "nearest_half_up",
    ["damageDedupeKey"] = "attackInstanceId+targetInstanceId+tickIndex",
    ["minPeriodicTickSec"] = 0.2,
    ["hitWindow"] = "half_open_time_interval_with_sweep",
    ["rootMotion"] = "in_place_logic_root",
  },
  ["session"] = {
    ["roundDurationSec"] = 600,
    ["extractionHoldSec"] = 3,
    ["sampleQuotaValue"] = 1000,
    ["quotaEnforced"] = false,
    ["extractionCancelOnDamage"] = true,
    ["extractionCancelOnLeave"] = true,
    ["globalClockContinuesDuringExtraction"] = true,
    ["sameFrameTerminalPriority"] = {
      "death",
      "timeout",
      "extraction",
    },
    ["terminalResultExactlyOnce"] = true,
  },
}

end
module_loaders["gameplay.registry"] = function()
  local require = ProjectRequire
-- Generated from package manifests. Do not edit.
return {
  ["schemaVersion"] = "0.2.0",
  ["entries"] = {
    {
      ["id"] = "chest_basic",
      ["packageId"] = "PKG-SCENE",
      ["type"] = "interactable",
      ["definitionModule"] = "gameplay.packages.interactables.chest_basic.definition",
      ["controllerModule"] = "gameplay.packages.interactables.chest_basic.controller",
      ["resources"] = {
        {
          ["id"] = "asset_chest_basic",
          ["path"] = "gameplay/packages/interactables/chest_basic/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_chest_basic_open",
          ["name"] = "chest_basic_open",
          ["role"] = "open",
          ["resourceId"] = "asset_chest_basic",
        },
        {
          ["id"] = "clip_chest_basic_close",
          ["name"] = "chest_basic_close",
          ["role"] = "close",
          ["resourceId"] = "asset_chest_basic",
        },
      },
      ["manifestPath"] = "gameplay/packages/interactables/chest_basic/manifest.json",
    },
    {
      ["id"] = "gate_exit",
      ["packageId"] = "PKG-SCENE",
      ["type"] = "interactable",
      ["definitionModule"] = "gameplay.packages.interactables.gate_exit.definition",
      ["controllerModule"] = "gameplay.packages.interactables.gate_exit.controller",
      ["resources"] = {
        {
          ["id"] = "asset_gate_exit",
          ["path"] = "gameplay/packages/interactables/gate_exit/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_gate_exit_activate",
          ["name"] = "gate_exit_activate",
          ["role"] = "activate",
          ["resourceId"] = "asset_gate_exit",
        },
      },
      ["manifestPath"] = "gameplay/packages/interactables/gate_exit/manifest.json",
    },
    {
      ["id"] = "item_capture",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "item",
      ["definitionModule"] = "gameplay.packages.items.item_capture.definition",
      ["controllerModule"] = "gameplay.packages.items.item_capture.controller",
      ["resources"] = {
        {
          ["id"] = "asset_item_capture",
          ["path"] = "gameplay/packages/items/item_capture/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_item_capture_use",
          ["name"] = "item_capture_use",
          ["role"] = "use",
          ["resourceId"] = "asset_item_capture",
        },
      },
      ["manifestPath"] = "gameplay/packages/items/item_capture/manifest.json",
    },
    {
      ["id"] = "item_flashlight",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "item",
      ["definitionModule"] = "gameplay.packages.items.item_flashlight.definition",
      ["controllerModule"] = "gameplay.packages.items.item_flashlight.controller",
      ["resources"] = {
        {
          ["id"] = "asset_item_flashlight",
          ["path"] = "gameplay/packages/items/item_flashlight/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_item_flashlight_use",
          ["name"] = "item_flashlight_use",
          ["role"] = "use",
          ["resourceId"] = "asset_item_flashlight",
        },
      },
      ["manifestPath"] = "gameplay/packages/items/item_flashlight/manifest.json",
    },
    {
      ["id"] = "item_heal_small",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "item",
      ["definitionModule"] = "gameplay.packages.items.item_heal_small.definition",
      ["controllerModule"] = "gameplay.packages.items.item_heal_small.controller",
      ["resources"] = {
        {
          ["id"] = "asset_item_heal_small",
          ["path"] = "gameplay/packages/items/item_heal_small/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_item_heal_small_use",
          ["name"] = "item_heal_small_use",
          ["role"] = "use",
          ["resourceId"] = "asset_item_heal_small",
        },
      },
      ["manifestPath"] = "gameplay/packages/items/item_heal_small/manifest.json",
    },
    {
      ["id"] = "item_music_box",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "item",
      ["definitionModule"] = "gameplay.packages.items.item_music_box.definition",
      ["controllerModule"] = "gameplay.packages.items.item_music_box.controller",
      ["resources"] = {
        {
          ["id"] = "asset_item_music_box",
          ["path"] = "gameplay/packages/items/item_music_box/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_item_music_box_use",
          ["name"] = "item_music_box_use",
          ["role"] = "use",
          ["resourceId"] = "asset_item_music_box",
        },
      },
      ["manifestPath"] = "gameplay/packages/items/item_music_box/manifest.json",
    },
    {
      ["id"] = "item_treasure",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "item",
      ["definitionModule"] = "gameplay.packages.items.item_treasure.definition",
      ["controllerModule"] = "gameplay.packages.items.item_treasure.controller",
      ["resources"] = {
        {
          ["id"] = "asset_item_treasure",
          ["path"] = "gameplay/packages/items/item_treasure/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
      },
      ["manifestPath"] = "gameplay/packages/items/item_treasure/manifest.json",
    },
    {
      ["id"] = "map_demo",
      ["packageId"] = "PKG-SCENE",
      ["type"] = "environment",
      ["definitionModule"] = "gameplay.packages.environment.map_demo.definition",
      ["controllerModule"] = "gameplay.packages.environment.map_demo.controller",
      ["resources"] = {
        {
          ["id"] = "asset_map_demo",
          ["path"] = "gameplay/packages/environment/map_demo/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
      },
      ["manifestPath"] = "gameplay/packages/environment/map_demo/manifest.json",
    },
    {
      ["id"] = "map_tomb",
      ["packageId"] = "PKG-SCENE",
      ["type"] = "environment",
      ["definitionModule"] = "gameplay.packages.environment.map_tomb.definition",
      ["controllerModule"] = "gameplay.packages.environment.map_tomb.controller",
      ["resources"] = {
        {
          ["id"] = "asset_map_tomb",
          ["path"] = "gameplay/packages/environment/map_tomb/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
      },
      ["manifestPath"] = "gameplay/packages/environment/map_tomb/manifest.json",
    },
    {
      ["id"] = "monster_bat",
      ["packageId"] = "PKG-MONSTER",
      ["type"] = "monster",
      ["definitionModule"] = "gameplay.packages.monsters.monster_bat.definition",
      ["controllerModule"] = "gameplay.packages.monsters.monster_bat.controller",
      ["resources"] = {
        {
          ["id"] = "asset_monster_bat",
          ["path"] = "gameplay/packages/monsters/monster_bat/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_monster_bat_idle",
          ["name"] = "monster_bat_idle",
          ["role"] = "idle",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_patrol",
          ["name"] = "monster_bat_patrol",
          ["role"] = "patrol",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_chase",
          ["name"] = "monster_bat_chase",
          ["role"] = "chase",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_attack",
          ["name"] = "monster_bat_attack",
          ["role"] = "attack",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_hurt",
          ["name"] = "monster_bat_hurt",
          ["role"] = "hurt",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_death",
          ["name"] = "monster_bat_death",
          ["role"] = "death",
          ["resourceId"] = "asset_monster_bat",
        },
        {
          ["id"] = "clip_monster_bat_special",
          ["name"] = "monster_bat_special",
          ["role"] = "special",
          ["resourceId"] = "asset_monster_bat",
        },
      },
      ["manifestPath"] = "gameplay/packages/monsters/monster_bat/manifest.json",
    },
    {
      ["id"] = "monster_cube",
      ["packageId"] = "PKG-MONSTER",
      ["type"] = "monster",
      ["definitionModule"] = "gameplay.packages.monsters.monster_cube.definition",
      ["controllerModule"] = "gameplay.packages.monsters.monster_cube.controller",
      ["resources"] = {
        {
          ["id"] = "asset_monster_cube",
          ["path"] = "gameplay/packages/monsters/monster_cube/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
      },
      ["manifestPath"] = "gameplay/packages/monsters/monster_cube/manifest.json",
    },
    {
      ["id"] = "monster_marmot",
      ["packageId"] = "PKG-MONSTER",
      ["type"] = "monster",
      ["definitionModule"] = "gameplay.packages.monsters.monster_marmot.definition",
      ["controllerModule"] = "gameplay.packages.monsters.monster_marmot.controller",
      ["resources"] = {
        {
          ["id"] = "asset_monster_marmot",
          ["path"] = "gameplay/packages/monsters/monster_marmot/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_monster_marmot_idle",
          ["name"] = "monster_marmot_idle",
          ["role"] = "idle",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_patrol",
          ["name"] = "monster_marmot_patrol",
          ["role"] = "patrol",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_chase",
          ["name"] = "monster_marmot_chase",
          ["role"] = "chase",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_attack",
          ["name"] = "monster_marmot_attack",
          ["role"] = "attack",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_hurt",
          ["name"] = "monster_marmot_hurt",
          ["role"] = "hurt",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_death",
          ["name"] = "monster_marmot_death",
          ["role"] = "death",
          ["resourceId"] = "asset_monster_marmot",
        },
        {
          ["id"] = "clip_monster_marmot_special",
          ["name"] = "monster_marmot_special",
          ["role"] = "special",
          ["resourceId"] = "asset_monster_marmot",
        },
      },
      ["manifestPath"] = "gameplay/packages/monsters/monster_marmot/manifest.json",
    },
    {
      ["id"] = "monster_slime",
      ["packageId"] = "PKG-MONSTER",
      ["type"] = "monster",
      ["definitionModule"] = "gameplay.packages.monsters.monster_slime.definition",
      ["controllerModule"] = "gameplay.packages.monsters.monster_slime.controller",
      ["resources"] = {
        {
          ["id"] = "asset_monster_slime",
          ["path"] = "gameplay/packages/monsters/monster_slime/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_monster_slime_idle",
          ["name"] = "monster_slime_idle",
          ["role"] = "idle",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_patrol",
          ["name"] = "monster_slime_patrol",
          ["role"] = "patrol",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_chase",
          ["name"] = "monster_slime_chase",
          ["role"] = "chase",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_attack",
          ["name"] = "monster_slime_attack",
          ["role"] = "attack",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_hurt",
          ["name"] = "monster_slime_hurt",
          ["role"] = "hurt",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_death",
          ["name"] = "monster_slime_death",
          ["role"] = "death",
          ["resourceId"] = "asset_monster_slime",
        },
        {
          ["id"] = "clip_monster_slime_special",
          ["name"] = "monster_slime_special",
          ["role"] = "special",
          ["resourceId"] = "asset_monster_slime",
        },
      },
      ["manifestPath"] = "gameplay/packages/monsters/monster_slime/manifest.json",
    },
    {
      ["id"] = "player_default",
      ["packageId"] = "PKG-PLAYER",
      ["type"] = "player",
      ["definitionModule"] = "gameplay.packages.player.player_default.definition",
      ["controllerModule"] = "gameplay.packages.player.player_default.controller",
      ["resources"] = {
        {
          ["id"] = "asset_player_default",
          ["path"] = "gameplay/packages/player/player_default/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_player_default_idle",
          ["name"] = "player_default_idle",
          ["role"] = "idle",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_walk",
          ["name"] = "player_default_walk",
          ["role"] = "walk",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_run",
          ["name"] = "player_default_run",
          ["role"] = "run",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_attack",
          ["name"] = "player_default_attack",
          ["role"] = "attack",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_use",
          ["name"] = "player_default_use",
          ["role"] = "use",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_hurt",
          ["name"] = "player_default_hurt",
          ["role"] = "hurt",
          ["resourceId"] = "asset_player_default",
        },
        {
          ["id"] = "clip_player_default_death",
          ["name"] = "player_default_death",
          ["role"] = "death",
          ["resourceId"] = "asset_player_default",
        },
      },
      ["manifestPath"] = "gameplay/packages/player/player_default/manifest.json",
    },
    {
      ["id"] = "trap_spikes",
      ["packageId"] = "PKG-SCENE",
      ["type"] = "interactable",
      ["definitionModule"] = "gameplay.packages.interactables.trap_spikes.definition",
      ["controllerModule"] = "gameplay.packages.interactables.trap_spikes.controller",
      ["resources"] = {
        {
          ["id"] = "asset_trap_spikes",
          ["path"] = "gameplay/packages/interactables/trap_spikes/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_trap_spikes_warning",
          ["name"] = "trap_spikes_warning",
          ["role"] = "warning",
          ["resourceId"] = "asset_trap_spikes",
        },
        {
          ["id"] = "clip_trap_spikes_activate",
          ["name"] = "trap_spikes_activate",
          ["role"] = "activate",
          ["resourceId"] = "asset_trap_spikes",
        },
        {
          ["id"] = "clip_trap_spikes_reset",
          ["name"] = "trap_spikes_reset",
          ["role"] = "reset",
          ["resourceId"] = "asset_trap_spikes",
        },
      },
      ["manifestPath"] = "gameplay/packages/interactables/trap_spikes/manifest.json",
    },
    {
      ["id"] = "ui_main",
      ["packageId"] = "PKG-INVENTORY",
      ["type"] = "ui",
      ["definitionModule"] = "gameplay.packages.ui.ui_main.definition",
      ["controllerModule"] = "gameplay.packages.ui.ui_main.controller",
      ["resources"] = {
        {
          ["id"] = "asset_ui_main_atlas",
          ["path"] = "gameplay/packages/ui/ui_main/materials/ui_atlas.png",
          ["kind"] = "ui_texture",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
      },
      ["manifestPath"] = "gameplay/packages/ui/ui_main/manifest.json",
    },
    {
      ["id"] = "weapon_ranged_sample",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "weapon",
      ["definitionModule"] = "gameplay.packages.weapons.weapon_ranged_sample.definition",
      ["controllerModule"] = "gameplay.packages.weapons.weapon_ranged_sample.controller",
      ["resources"] = {
        {
          ["id"] = "asset_weapon_ranged_sample",
          ["path"] = "gameplay/packages/weapons/weapon_ranged_sample/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
        {
          ["id"] = "anim_weapon_ranged_sample_player",
          ["path"] = "gameplay/packages/weapons/weapon_ranged_sample/animations/player_actions.glb",
          ["kind"] = "animation",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_weapon_ranged_sample_idle",
          ["name"] = "weapon_ranged_sample_idle",
          ["role"] = "idle",
          ["resourceId"] = "anim_weapon_ranged_sample_player",
        },
        {
          ["id"] = "clip_weapon_ranged_sample_attack",
          ["name"] = "weapon_ranged_sample_attack",
          ["role"] = "attack",
          ["resourceId"] = "anim_weapon_ranged_sample_player",
        },
      },
      ["manifestPath"] = "gameplay/packages/weapons/weapon_ranged_sample/manifest.json",
    },
    {
      ["id"] = "weapon_shovel",
      ["packageId"] = "PKG-TOOL",
      ["type"] = "weapon",
      ["definitionModule"] = "gameplay.packages.weapons.weapon_shovel.definition",
      ["controllerModule"] = "gameplay.packages.weapons.weapon_shovel.controller",
      ["resources"] = {
        {
          ["id"] = "asset_weapon_shovel",
          ["path"] = "gameplay/packages/weapons/weapon_shovel/model/main.glb",
          ["kind"] = "model",
          ["status"] = "planned",
        },
        {
          ["id"] = "anim_weapon_shovel_player",
          ["path"] = "gameplay/packages/weapons/weapon_shovel/animations/player_actions.glb",
          ["kind"] = "animation",
          ["status"] = "planned",
        },
      },
      ["clips"] = {
        {
          ["id"] = "clip_weapon_shovel_idle",
          ["name"] = "weapon_shovel_idle",
          ["role"] = "idle",
          ["resourceId"] = "anim_weapon_shovel_player",
        },
        {
          ["id"] = "clip_weapon_shovel_attack",
          ["name"] = "weapon_shovel_attack",
          ["role"] = "attack",
          ["resourceId"] = "anim_weapon_shovel_player",
        },
      },
      ["manifestPath"] = "gameplay/packages/weapons/weapon_shovel/manifest.json",
    },
  },
}

end
module_loaders["gameplay.packages.interactables.chest_basic.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "chest_basic",
  ["displayName"] = "基础宝箱",
  ["gate"] = "G1",
  ["interactionDistanceM"] = 2.2,
  ["rollPolicy"] = "first_open_only",
  ["lootTableId"] = "loot_room_basic",
  ["containerSlots"] = 6,
  ["type"] = "interactable",
  ["assetId"] = "asset_chest_basic",
  ["lootTable"] = {
    ["id"] = "loot_room_basic",
    ["rolls"] = 2,
    ["entries"] = {
      {
        ["entityId"] = "item_treasure",
        ["weight"] = 3,
        ["minCount"] = 1,
        ["maxCount"] = 1,
      },
      {
        ["entityId"] = "item_heal_small",
        ["weight"] = 1,
        ["minCount"] = 1,
        ["maxCount"] = 1,
      },
    },
  },
}

end
module_loaders["gameplay.packages.interactables.chest_basic.controller"] = function()
  local require = ProjectRequire
-- Planner-owned chest interaction. Round setup owns the one-time container seed.
local Definition = require("gameplay.packages.interactables.chest_basic.definition")
local Controller = {}
Controller.__index=Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
function Controller.new(context,instance)
  assert(type(context)=="table"and type(instance)=="table"and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    container_id=instance.container_id or "chest_demo",opened=false,started=false,disposed=false},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED"end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY"end
  for _,name in ipairs({"Interaction","Inventory","Assets"})do
    if not self.context.services[name]then return false,"MISSING_SERVICE:"..name end
  end
  self.opened=false;self.started=true;return true
end
function Controller:permit(owner)
  return self.context.services.Interaction:try_begin(self:request("chest_permission",{
    user_instance_id=owner,target_instance_id=self.instance.id,mode="chest",
    max_distance_m=Definition.interactionDistanceM
  }))
end
function Controller:read_contents()
  return self.context.services.Inventory:read_snapshot(self:request("chest_snapshot",{container_id=self.container_id}))
end
function Controller:open(player_id)
  local id=self.context:next_request_id("chest_open")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  local owner=player_id or "player_local"
  local permission=self:permit(owner)
  if not permission.ok then self.last_result=permission;return permission end
  local snapshot=self:read_contents()
  if not snapshot.ok then self.last_result=snapshot;return snapshot end
  local was_open=self.opened
  self.opened=true;self.owner_id=owner
  if not was_open then
    self.context.services.Assets:play_clip(self:request("chest_animation",{
      instance_id=self.instance.id,clip_id="clip_chest_basic_open",native_action="chest_open"
    }))
  end
  snapshot.data.container_id=self.container_id
  self.last_result=snapshot
  return snapshot
end
function Controller:pickup(item_id,count)
  local id=self.context:next_request_id("chest_pickup")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.opened then return result(false,"CHEST_NOT_OPEN",id)end
  if self.context.state.phase~="EXPLORE"then self:close();return result(false,"INVALID_PHASE",id)end
  local permission=self:permit(self.owner_id)
  if not permission.ok then self:close();self.last_result=permission;return permission end
  local source=self:read_contents()
  if not source.ok then self.last_result=source;return source end
  local destination=self.context.services.Inventory:read_snapshot(self:request("chest_bag",{owner_instance_id=self.owner_id}))
  if not destination.ok then self.last_result=destination;return destination end
  self.last_result=self.context.services.Inventory:try_transfer({
    request_id=id,run_id=self.context.state.run_id,from_id=self.container_id,
    to_id="bag_"..self.owner_id,item_instance_id=item_id,count=count or 1,
    expected_versions={from=source.data.bag.version,to=destination.data.bag.version}
  })
  return self.last_result
end
function Controller:close()
  if self.opened and not self.disposed then
    self.context.services.Assets:play_clip(self:request("chest_close",{
      instance_id=self.instance.id,clip_id="clip_chest_basic_close",native_action="chest_close"
    }))
  end
  self.opened=false;self.owner_id=nil
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.opened then return end
  if self.context.state.phase~="EXPLORE"then self:close();return end
  local query=self.context.services.Interaction:query_target(self:request("chest_range",{
    user_instance_id=self.owner_id,target_instance_id=self.instance.id,mode="chest",
    max_distance_m=Definition.interactionDistanceM
  }))
  local e=query.data or {}
  if not query.ok or not e.in_range or not e.line_of_sight then self:close()end
end
function Controller:dispose()
  if self.disposed then return end
  self:close();self.started=false;self.disposed=true
end
return Controller

end
module_loaders["gameplay.packages.interactables.gate_exit.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "gate_exit",
  ["displayName"] = "撤离出口",
  ["gate"] = "G1",
  ["holdSecRef"] = "session.extractionHoldSec",
  ["quotaRef"] = "session.sampleQuotaValue",
  ["finishVia"] = "Session",
  ["type"] = "interactable",
  ["assetId"] = "asset_gate_exit",
}

end
module_loaders["gameplay.core.base_controller"] = function()
  local require = ProjectRequire
-- Lifecycle shell only. No movement, AI, damage or inventory is implemented.
local Base = {}
Base.__index = Base
function Base.new(context, instance, definition, required_services)
  assert(type(context) == "table", "context required")
  assert(type(instance) == "table" and type(instance.id) == "string", "instance.id required")
  return setmetatable({context=context, instance=instance, definition=definition,
    required_services=required_services, disposed=false}, Base)
end
function Base:start()
  if self.disposed then return false, "DISPOSED" end
  if not self.context.is_ready then return false, "ADAPTER_NOT_READY" end
  for _, name in ipairs(self.required_services) do
    if not self.context.services[name] then return false, "MISSING_SERVICE:" .. name end
  end
  return false, "NOT_IMPLEMENTED"
end
function Base:dispose()
  self.disposed = true
  self.context = nil
end
return Base

end
module_loaders["gameplay.packages.interactables.gate_exit.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.interactables.gate_exit.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Interaction",
  "Inventory",
  "Combat",
  "Session",
  "Assets",
})
end
return Controller

end
module_loaders["gameplay.packages.items.item_capture.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "item_capture",
  ["displayName"] = "封印器",
  ["gate"] = "G2",
  ["assetId"] = "asset_item_capture",
  ["weightKg"] = 0.4,
  ["maxStack"] = 3,
  ["sellValue"] = 100,
  ["equipmentSlot"] = "none",
  ["castSec"] = 2.5,
  ["cooldownSec"] = 3,
  ["consumePolicy"] = "on_effect_commit",
  ["cancelOnDamage"] = true,
  ["cancelOnMoveBeyondM"] = 0.4,
  ["useClipId"] = "clip_item_capture_use",
  ["effect"] = {
    ["kind"] = "capture",
    ["rangeM"] = 3,
    ["requireLineOfSight"] = true,
    ["requiresCanCapture"] = true,
  },
  ["type"] = "item",
}

end
module_loaders["gameplay.packages.items.item_capture.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.items.item_capture.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Interaction",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.items.item_flashlight.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "item_flashlight",
  ["displayName"] = "手电筒",
  ["gate"] = "G1",
  ["assetId"] = "asset_item_flashlight",
  ["weightKg"] = 0.5,
  ["maxStack"] = 1,
  ["sellValue"] = 60,
  ["equipmentSlot"] = "tool",
  ["castSec"] = 0,
  ["cooldownSec"] = 0.2,
  ["consumePolicy"] = "not_consumed",
  ["cancelOnDamage"] = true,
  ["cancelOnMoveBeyondM"] = 0.4,
  ["useClipId"] = "clip_item_flashlight_use",
  ["effect"] = {
    ["kind"] = "illumination",
    ["rangeM"] = 8,
    ["fullAngleDeg"] = 55,
    ["batteryMaxSec"] = 120,
    ["drainPerSec"] = 1,
  },
  ["type"] = "item",
}

end
module_loaders["gameplay.packages.items.item_flashlight.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.items.item_flashlight.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Interaction",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.items.item_heal_small.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "item_heal_small",
  ["displayName"] = "小型药品",
  ["gate"] = "G1",
  ["assetId"] = "asset_item_heal_small",
  ["weightKg"] = 0.2,
  ["maxStack"] = 5,
  ["sellValue"] = 30,
  ["equipmentSlot"] = "none",
  ["castSec"] = 1.2,
  ["cooldownSec"] = 2,
  ["consumePolicy"] = "on_effect_commit",
  ["cancelOnDamage"] = true,
  ["cancelOnMoveBeyondM"] = 0.4,
  ["useClipId"] = "clip_item_heal_small_use",
  ["effect"] = {
    ["kind"] = "heal",
    ["amountHp"] = 30,
  },
  ["type"] = "item",
}

end
module_loaders["gameplay.packages.items.item_heal_small.controller"] = function()
  local require = ProjectRequire
-- Planner-owned medicine cast/cancel logic. Healing and consumption commit together.
local Definition = require("gameplay.packages.items.item_heal_small.definition")
local Controller = {}
Controller.__index = Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
local function distance(a,b)
  local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
  return math.sqrt(x*x+y*y+z*z)
end
function Controller.new(context,instance)
  assert(type(context)=="table" and type(instance)=="table" and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    started=false,disposed=false,stage="IDLE",next_use_at=0},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED" end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY" end
  for _,name in ipairs({"Characters","Combat","Inventory","Assets"})do
    if not self.context.services[name]then return false,"MISSING_SERVICE:"..name end
  end
  self.started=true;return true
end
function Controller:use(request)
  request=request or {}
  local id=request.request_id or self.context:next_request_id("heal_use")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  if self.cast then return result(false,"USE_IN_PROGRESS",id)end
  if self.context.state.clock<self.next_use_at then return result(false,"COOLDOWN",id)end
  local owner=request.user_instance_id or self.instance.owner_instance_id or "player_local"
  local character=self.context.services.Characters:read_snapshot(self:request("heal_owner",{instance_id=owner}))
  if not character.ok then return character end
  local player=character.data
  if not player.alive then return result(false,"OWNER_DEAD",id)end
  if player.hp>=player.max_hp then return result(false,"FULL_HEALTH",id)end
  if not player.position_m then return result(false,"POSITION_UNAVAILABLE",id)end
  local inventory=self.context.services.Inventory:read_snapshot(self:request("heal_inventory",{owner_instance_id=owner}))
  if not inventory.ok then return inventory end
  local bag=inventory.data.bag
  local item_id=request.item_instance_id
  local found
  for _,item in ipairs(bag.items or {})do
    if item.id==item_id and item.entity_id==Definition.id and item.count>0 then found=true;break end
  end
  if not found then return result(false,"ITEM_NOT_OWNED",id)end
  local p=player.position_m
  self.cast={id=id,item_id=item_id,owner_id=owner,started_at=self.context.state.clock,
    origin={x=p.x,y=p.y,z=p.z},last_hp=player.hp}
  self.stage="USING"
  self.context.services.Assets:play_clip(self:request("heal_animation",{
    instance_id=owner,clip_id="native_use",native_action="use",definition_clip_id=Definition.useClipId
  }))
  self.last_result=result(true,"CAST_STARTED",id,{cast_sec=Definition.castSec})
  return self.last_result
end
function Controller:cancel(reason)
  if not self.cast then return false end
  self.last_result=result(false,reason or "CANCELLED",self.cast.id)
  self.cast=nil;self.stage="IDLE";return true
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.cast then return end
  local cast=self.cast
  if self.context.state.phase~="EXPLORE" then self:cancel("PHASE_CHANGED");return end
  local character=self.context.services.Characters:read_snapshot(self:request("heal_progress",{instance_id=cast.owner_id}))
  if not character.ok or not character.data.alive then self:cancel("OWNER_DEAD");return end
  local player=character.data
  if not player.position_m then self:cancel("POSITION_UNAVAILABLE");return end
  if Definition.cancelOnDamage and player.hp<cast.last_hp then self:cancel("DAMAGED");return end
  cast.last_hp=player.hp
  if distance(player.position_m,cast.origin)>Definition.cancelOnMoveBeyondM then self:cancel("MOVED");return end
  if self.context.state.clock-cast.started_at<Definition.castSec then return end
  -- Clear the cast before submitting; repeated update cannot consume another medicine.
  self.cast=nil;self.stage="IDLE"
  self.last_result=self.context.services.Combat:try_heal({
    request_id=cast.id,run_id=self.context.state.run_id,user_instance_id=cast.owner_id,item_instance_id=cast.item_id
  })
  if self.last_result.ok then self.next_use_at=self.context.state.clock+Definition.cooldownSec end
end
function Controller:get_status()
  local elapsed=self.cast and math.max(0,self.context.state.clock-self.cast.started_at)or 0
  return {stage=self.stage,progress_sec=elapsed,cast_sec=Definition.castSec,
    progress_ratio=math.min(1,elapsed/Definition.castSec),
    cooldown_remaining=math.max(0,self.next_use_at-self.context.state.clock),last_result=self.last_result}
end
function Controller:dispose()
  if self.disposed then return end
  self:cancel("DISPOSED");self.started=false;self.disposed=true
end
return Controller

end
module_loaders["gameplay.packages.items.item_music_box.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "item_music_box",
  ["displayName"] = "音乐盒",
  ["gate"] = "G2",
  ["assetId"] = "asset_item_music_box",
  ["weightKg"] = 0.6,
  ["maxStack"] = 2,
  ["sellValue"] = 80,
  ["equipmentSlot"] = "none",
  ["castSec"] = 0.6,
  ["cooldownSec"] = 5,
  ["consumePolicy"] = "on_effect_commit",
  ["cancelOnDamage"] = true,
  ["cancelOnMoveBeyondM"] = 0.4,
  ["useClipId"] = "clip_item_music_box_use",
  ["effect"] = {
    ["kind"] = "area_control",
    ["rangeM"] = 5,
    ["durationSec"] = 8,
    ["requireLineOfSight"] = true,
    ["targetBehaviorRuleId"] = "slime_contact_enrage",
  },
  ["type"] = "item",
}

end
module_loaders["gameplay.packages.items.item_music_box.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.items.item_music_box.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Interaction",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.items.item_treasure.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "item_treasure",
  ["displayName"] = "宝藏拾取物",
  ["gate"] = "G1",
  ["weightKg"] = 1,
  ["maxStack"] = 1,
  ["sellValue"] = 250,
  ["equipmentSlot"] = "none",
  ["effect"] = {
    ["kind"] = "collectible",
  },
  ["countsForQuota"] = true,
  ["type"] = "item",
  ["assetId"] = "asset_item_treasure",
}

end
module_loaders["gameplay.packages.items.item_treasure.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.items.item_treasure.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Interaction",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.environment.map_demo.definition"] = function()
  local require = ProjectRequire
-- Native whitebox layout. Geometry and navigation read this same definition.
return {
 schemaVersion='0.2.0',id='map_demo',type='environment',displayName='四房连通Demo',
 spawn={x=-2,y=0.1,z=-2},exit={x=-2,y=0.05,z=-1},chest={x=1,y=0.5,z=-1},
 monsterSpawn={x=8,y=0.6,z=8},
 patrolRoute={{x=8,y=0.6,z=8},{x=12,y=0.6,z=8},{x=12,y=0.6,z=12},{x=8,y=0.6,z=12}},
 rooms={{id='entry',label='入口 / 撤离',x=0,z=0},{id='supply',label='补给房',x=10,z=0},{id='hall',label='连接前厅',x=0,z=10},{id='monster',label='方块巡逻室',x=10,z=10}},
 bounds={min_x=-4.6,max_x=14.6,min_z=-4.6,max_z=14.6},
 walls={
  {name='wall_west',x=-5,z=5,sx=0.35,sz=20},{name='wall_east',x=15,z=5,sx=0.35,sz=20},
  {name='wall_south',x=5,z=-5,sx=20,sz=0.35},{name='wall_north',x=5,z=15,sx=20,sz=0.35},
  {name='divider_x_south',x=5,z=-2.5,sx=0.35,sz=5},{name='divider_x_mid',x=5,z=5,sx=0.35,sz=5},{name='divider_x_north',x=5,z=12.5,sx=0.35,sz=5},
  {name='divider_z_west',x=-2.5,z=5,sx=5,sz=0.35},{name='divider_z_mid',x=5,z=5,sx=5,sz=0.35},{name='divider_z_east',x=12.5,z=5,sx=5,sz=0.35},
  {name='sight_cover',x=10,z=10,sx=1.2,sz=1.2},
 },
}

end
module_loaders["gameplay.packages.environment.map_demo.controller"] = function()
  local require = ProjectRequire
local Definition=require('gameplay.packages.environment.map_demo.definition')
local Controller={};Controller.__index=Controller
function Controller.new(context,instance)return setmetatable({context=context,instance=instance,definition=Definition},Controller)end
function Controller:start()self.started=true;return true end
function Controller:dispose()self.started=false end
return Controller

end
module_loaders["gameplay.packages.environment.map_tomb.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "map_tomb",
  ["displayName"] = "墓穴完整地图",
  ["gate"] = "G1",
  ["firstGateRooms"] = 4,
  ["completeMapRooms"] = 10,
  ["routeNamespace"] = "map_tomb",
  ["roomTypes"] = {
    "entry",
    "ordinary",
    "treasure",
    "encounter",
    "exit",
  },
  ["interactiveEntities"] = {
    "chest_basic",
    "trap_spikes",
    "gate_exit",
  },
  ["type"] = "environment",
  ["assetId"] = "asset_map_tomb",
  ["spawnPoints"] = {
    {
      ["id"] = "spawn_player",
      ["roomId"] = "room_entry",
      ["positionM"] = {
        ["x"] = 0,
        ["y"] = 0,
        ["z"] = 0,
      },
    },
  },
  ["patrolRoutes"] = {
    {
      ["id"] = "route_room_02",
      ["roomId"] = "room_ordinary",
      ["pointsM"] = {
        {
          ["x"] = 5,
          ["y"] = 0,
          ["z"] = 5,
        },
        {
          ["x"] = 10,
          ["y"] = 0,
          ["z"] = 5,
        },
      },
    },
  },
}

end
module_loaders["gameplay.packages.environment.map_tomb.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.environment.map_tomb.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Navigation",
  "Movement",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.monsters.monster_bat.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "monster_bat",
  ["displayName"] = "墓穴蝙蝠",
  ["gate"] = "G2",
  ["assetId"] = "asset_monster_bat",
  ["maxHp"] = 90,
  ["canDie"] = true,
  ["armorFlatHp"] = 0,
  ["damageReductionRatio"] = 0,
  ["patrolSpeedMps"] = 1.2,
  ["chaseSpeedMps"] = 4.0,
  ["patrolWaitSec"] = 1.0,
  ["sense"] = {
    ["rangeM"] = 9,
    ["fullAngleDeg"] = 120,
    ["requireLineOfSight"] = true,
    ["loseSightGraceSec"] = 1.2,
    ["searchSec"] = 4,
    ["showDebugCone"] = true,
  },
  ["leashRadiusM"] = 15,
  ["canCapture"] = true,
  ["captureHpRatioMax"] = 0.25,
  ["physicalDamageImmune"] = false,
  ["behaviorRuleId"] = "bat_dive_attach",
  ["behaviorParams"] = {
    ["kind"] = "bat",
    ["attachmentDurationSec"] = 4,
    ["maxAttachmentsPerPlayer"] = 1,
    ["dropPolicy"] = "all_unprotected_bag_once",
    ["dropEquipment"] = false,
  },
  ["attacks"] = {
    {
      ["id"] = "attack_monster_bat_dive",
      ["delivery"] = "lunge",
      ["damageHp"] = 0,
      ["damageType"] = "physical",
      ["damageMode"] = "single",
      ["tickIntervalSec"] = 0,
      ["firstTickDelaySec"] = 0,
      ["windupSec"] = 0.45,
      ["activeSec"] = 0.2,
      ["recoverySec"] = 0.35,
      ["cooldownSec"] = 1.8,
      ["rangeM"] = 5.0,
      ["arcDeg"] = 100,
      ["hitRadiusM"] = 0.25,
      ["maxTargets"] = 1,
      ["requireLineOfSight"] = true,
      ["clipId"] = "clip_monster_bat_attack",
      ["hitTimeSec"] = 0.55,
    },
    {
      ["id"] = "attack_monster_bat_attach",
      ["delivery"] = "attachment",
      ["damageHp"] = 10,
      ["damageType"] = "hazard",
      ["damageMode"] = "periodic",
      ["tickIntervalSec"] = 1.2,
      ["firstTickDelaySec"] = 1.2,
      ["windupSec"] = 0,
      ["activeSec"] = 4,
      ["recoverySec"] = 0.4,
      ["cooldownSec"] = 4.4,
      ["rangeM"] = 0.6,
      ["arcDeg"] = 360,
      ["hitRadiusM"] = 0.25,
      ["maxTargets"] = 1,
      ["requireLineOfSight"] = false,
      ["clipId"] = "clip_monster_bat_special",
      ["hitTimeSec"] = 0,
    },
  },
  ["animationClips"] = {
    ["idle"] = "clip_monster_bat_idle",
    ["patrol"] = "clip_monster_bat_patrol",
    ["chase"] = "clip_monster_bat_chase",
    ["attack"] = "clip_monster_bat_attack",
    ["hurt"] = "clip_monster_bat_hurt",
    ["death"] = "clip_monster_bat_death",
    ["special"] = "clip_monster_bat_special",
  },
  ["collider"] = {
    ["shape"] = "capsule",
    ["radiusM"] = 0.25,
    ["heightM"] = 0.6,
    ["centerY_M"] = 0.3,
  },
  ["type"] = "monster",
}

end
module_loaders["gameplay.packages.monsters.monster_bat.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.monsters.monster_bat.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Movement",
  "Navigation",
  "Inventory",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.monsters.monster_cube.definition"] = function()
  local require = ProjectRequire
-- Static definition. Native feedback is not a delivered skeletal model.
return {
  schemaVersion = "0.2.0",
  id = "monster_cube",
  type = "monster",
  displayName = "方块巡逻怪",
  gate = "G1",
  assetId = "asset_monster_cube",
  maxHp = 60,
  canDie = true,
  armorFlatHp = 0,
  damageReductionRatio = 0,
  patrolSpeedMps = 1,
  chaseSpeedMps = 3,
  patrolWaitSec = 0.6,
  arriveDistanceM = 0.25,
  pathRefreshSec = 0.4,
  pathFailureRetrySec = 0.6,
  patrolUnreachableSkipSec = 2,
  leashRadiusM = 15,
  hurtPauseSec = 0.25,
  sense = {
    rangeM = 7,
    fullAngleDeg = 100,
    requireLineOfSight = true,
    loseSightGraceSec = 1.2,
    searchSec = 4,
    showDebugCone = true,
  },
  -- These are world coordinates only when supplied by scene setup.
  -- An empty default creates a small route relative to the native spawn position.
  patrolRoute = {},
  attacks = {
    {
      id = "primary",
      delivery = "melee_sector",
      damageHp = 25,
      damageType = "physical",
      damageMode = "single",
      tickIntervalSec = 0,
      windupSec = 0.55,
      activeSec = 0.25,
      recoverySec = 0.7,
      cooldownSec = 2,
      rangeM = 3.5,
      arcDeg = 100,
      maxTargets = 1,
      requireLineOfSight = true,
    },
  },
  -- These are Adapter-native feedback IDs, deliberately absent from manifest.clips.
  nativeFeedback = {
    patrol = "native_patrol",
    windup = "native_windup",
    attack = "native_attack",
    hit = "native_hit",
    death = "native_death",
  },
  collider = {shape = "box", widthM = 1.2, heightM = 1.2, depthM = 1.2},
}

end
module_loaders["gameplay.packages.monsters.monster_cube.controller"] = function()
  local require = ProjectRequire
-- Complete native-demo AI; uses only injected project services, never editor globals.
-- Public HP, clock, phase and world transforms are owned by the core/Adapter.
local Definition = require("gameplay.packages.monsters.monster_cube.definition")
local Controller = {}
Controller.__index = Controller

local required = {"Characters", "Combat", "Movement", "Navigation", "Interaction", "Assets", "Session"}
local methods = {
  Characters = {"read_snapshot"},
  Combat = {"try_begin_attack", "try_apply_damage", "cancel_attack"},
  Movement = {"read_position", "move_to", "stop"},
  Navigation = {"find_path", "cancel_query"},
  Interaction = {"query_target"},
  Assets = {"play_clip"},
  Session = {"read_snapshot"},
}

local function point(value)
  if type(value) ~= "table" then return nil end
  local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
  if not x or not y or not z then return nil end
  return {x = x, y = y, z = z}
end

local function distance(a, b)
  local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
  return math.sqrt(x*x + y*y + z*z)
end

local function ground_distance(a, b)
  local x, z = a.x - b.x, a.z - b.z
  return math.sqrt(x*x + z*z)
end

local function result_data(result)
  if type(result) == "table" and result.ok == true and type(result.data) == "table" then
    return result.data
  end
  return nil
end

function Controller.new(context, instance)
  assert(type(context) == "table", "context required")
  assert(type(instance) == "table" and type(instance.id) == "string", "instance.id required")
  return setmetatable({
    context = context, instance = instance,
    definition = (context.definitions and context.definitions.monster_cube) or Definition,
    required_services = required, disposed = false, started = false,
    ai_state = "idle", state = "idle", target_id = "player_local",
    request_sequence = 0, route_index = 1, patrol_wait_until = 0,
    next_attack_at = 0, next_path_at = 0, path_index = 1,
    last_seen_position = nil, last_seen_at = nil, attack_instance_id = nil,
    attack_hit_committed = false, attack_hit_attempted = false,
  }, Controller)
end

function Controller:_now()
  return tonumber(self.context.state.clock) or 0
end

function Controller:_request(operation, fields)
  fields = fields or {}
  self.request_sequence = self.request_sequence + 1
  local prefix = "monster_cube:" .. self.instance.id .. ":" .. operation
  if type(self.context.next_request_id) == "function" then
    fields.request_id = self.context:next_request_id(prefix)
  else
    fields.request_id = tostring(self.bound_run_id or self.context.state.run_id) .. ":" .. prefix .. ":" .. self.request_sequence
  end
  fields.run_id = self.bound_run_id or self.context.state.run_id
  return fields
end

function Controller:_play(clip, force)
  if self.current_feedback == clip and not force then return end
  self.current_feedback = clip
  self.context.services.Assets:play_clip(self:_request("feedback", {
    instance_id = self.instance.id, clip_id = clip,
  }))
end

function Controller:_set_state(name)
  self.ai_state, self.state = name, name
end

function Controller:_position(instance_id)
  local data = result_data(self.context.services.Movement:read_position(self:_request("position", {
    instance_id = instance_id,
  })))
  return data and point(data.position_m) or nil, data
end

function Controller:_snapshot(instance_id)
  return result_data(self.context.services.Characters:read_snapshot(self:_request("snapshot", {
    instance_id = instance_id,
  })))
end

function Controller:_stop_moving()
  self.context.services.Movement:stop(self:_request("stop", {instance_id = self.instance.id}))
end

function Controller:_clear_path()
  if self.path_task_id then
    self.context.services.Navigation:cancel_query(self:_request("cancel_path", {
      instance_id = self.instance.id, task_id = self.path_task_id,
    }))
  end
  self.path, self.path_goal, self.path_task_id = nil, nil, nil
  self.path_index, self.next_path_at = 1, 0
end

function Controller:_cancel_attack(reason)
  if self.attack_instance_id then
    self.context.services.Combat:cancel_attack(self:_request("cancel_attack", {
      source_instance_id = self.instance.id,
      attack_instance_id = self.attack_instance_id, reason = reason,
    }))
  end
  self.attack_instance_id, self.attack_started_at = nil, nil
  self.attack_hit_committed, self.attack_hit_attempted = false, false
end

function Controller:_perception()
  local data = result_data(self.context.services.Interaction:query_target(self:_request("perception", {
    user_instance_id = self.instance.id, target_instance_id = self.target_id,
    mode = "perception", range_m = self.definition.sense.rangeM,
    full_angle_deg = self.definition.sense.fullAngleDeg,
    require_line_of_sight = self.definition.sense.requireLineOfSight,
  })))
  if not data then return {visible = false} end
  local sensed_distance = tonumber(data.distance_m)
  local visible = data.visible == true and data.line_of_sight == true
    and data.angular_valid == true and sensed_distance ~= nil
    and sensed_distance <= self.definition.sense.rangeM
  return {visible = visible, distance_m = sensed_distance,
    line_of_sight = data.line_of_sight == true, angular_valid = data.angular_valid == true}
end

function Controller:_remember_target(now, perception)
  if not perception.visible then return end
  local position = self:_position(self.target_id)
  if position then
    self.last_seen_position, self.last_seen_at = position, now
  end
end

function Controller:_follow(goal, speed, dt, now)
  local own_position = self:_position(self.instance.id)
  if not own_position or not goal then
    self:_stop_moving()
    return false, "POSITION_UNAVAILABLE"
  end
  if ground_distance(own_position, goal) <= self.definition.arriveDistanceM then
    self:_stop_moving()
    return true, "ARRIVED"
  end
  local changed_goal = not self.path_goal or ground_distance(self.path_goal, goal) > 0.5
  if changed_goal or now >= self.next_path_at then
    local data = result_data(self.context.services.Navigation:find_path(self:_request("path", {
      instance_id = self.instance.id, from_m = own_position, to_m = goal,
    })))
    self.path_goal, self.path, self.path_index = point(goal), nil, 1
    self.path_task_id = data and data.task_id or nil
    if data and type(data.waypoints) == "table" then
      local path = {}
      for _, candidate in ipairs(data.waypoints) do
        local waypoint = point(candidate)
        if waypoint then path[#path + 1] = waypoint end
      end
      if #path > 0 then self.path = path end
    end
    self.next_path_at = now + (self.path and self.definition.pathRefreshSec or self.definition.pathFailureRetrySec)
  end
  if not self.path then
    self:_stop_moving()
    return false, "NO_PATH"
  end
  while self.path[self.path_index]
    and ground_distance(own_position, self.path[self.path_index]) <= self.definition.arriveDistanceM do
    self.path_index = self.path_index + 1
  end
  local waypoint = self.path[self.path_index]
  if not waypoint then
    self:_stop_moving()
    self.next_path_at = 0
    return false, "PATH_EXHAUSTED"
  end
  local result = self.context.services.Movement:move_to(self:_request("move", {
    instance_id = self.instance.id, goal_m = waypoint, speed_mps = speed, dt_sec = dt,
  }))
  if type(result) ~= "table" or result.ok ~= true then
    self:_stop_moving()
    self:_clear_path()
    return false, "MOVE_BLOCKED"
  end
  return false, "MOVING"
end

function Controller:start()
  if self.disposed then return false, "DISPOSED" end
  if self.started then return true, "ALREADY_STARTED" end
  if not self.context.is_ready then return false, "ADAPTER_NOT_READY" end
  if type(self.context.state) ~= "table" or self.context.state.run_id == nil then
    return false, "MISSING_SESSION_STATE"
  end
  for _, name in ipairs(required) do
    local service = self.context.services and self.context.services[name]
    if type(service) ~= "table" then return false, "MISSING_SERVICE:" .. name end
    for _, method in ipairs(methods[name]) do
      if type(service[method]) ~= "function" then return false, "MISSING_METHOD:" .. name .. "." .. method end
    end
  end
  self.bound_run_id = self.context.state.run_id
  local own_position = self:_position(self.instance.id)
  local snapshot = self:_snapshot(self.instance.id)
  if not own_position then return false, "POSITION_UNAVAILABLE" end
  if not snapshot or snapshot.hp == nil then return false, "CHARACTER_UNAVAILABLE" end
  self.home_position, self.last_hp = own_position, tonumber(snapshot.hp)
  self.route = {}
  local route = self.instance.route or self.definition.patrolRoute
  if type(route) == "table" then
    for _, candidate in ipairs(route) do
      local waypoint = point(candidate)
      if waypoint then self.route[#self.route + 1] = waypoint end
    end
  end
  if #self.route == 0 then
    self.route = {
      {x = own_position.x - 2, y = own_position.y, z = own_position.z},
      {x = own_position.x + 2, y = own_position.y, z = own_position.z},
    }
  end
  self.started = true
  self:_set_state("patrol")
  self:_play(self.definition.nativeFeedback.patrol)
  return true, "STARTED"
end

function Controller:_begin_attack(now)
  if now < self.next_attack_at then return false end
  local data = result_data(self.context.services.Combat:try_begin_attack(self:_request("attack", {
    source_instance_id = self.instance.id, target_instance_id = self.target_id,
    attack_id = self.definition.attacks[1].id,
  })))
  if not data or not data.attack_instance_id then
    self.next_attack_at = now + 0.2
    return false
  end
  self.attack_instance_id, self.attack_started_at = data.attack_instance_id, now
  self.attack_hit_committed, self.attack_hit_attempted = false, false
  self.next_attack_at = now + self.definition.attacks[1].cooldownSec
  self:_clear_path()
  self:_stop_moving()
  self:_set_state("windup")
  self:_play(self.definition.nativeFeedback.windup, true)
  return true
end

function Controller:_update_attack(now, perception)
  local attack = self.definition.attacks[1]
  local age = now - self.attack_started_at
  local active_end = attack.windupSec + attack.activeSec
  local finish = active_end + attack.recoverySec
  self:_stop_moving()
  if age < attack.windupSec then
    self:_set_state("windup")
    return
  end
  if age < active_end then
    self:_set_state("attack")
    self:_play(self.definition.nativeFeedback.attack)
    if not self.attack_hit_attempted and perception.visible
      and perception.distance_m <= attack.rangeM then
      -- Only the current authoritative active window can submit damage.
      -- The core validates distance, LOS, arc, window and deduplication again.
      self.attack_hit_attempted = true
      local result = self.context.services.Combat:try_apply_damage(self:_request("hit", {
        source_instance_id = self.instance.id, attack_id = attack.id,
        attack_instance_id = self.attack_instance_id, target_instance_id = self.target_id,
        tick_index = 0,
        hit_evidence = {distance_m = perception.distance_m,
          angular_valid = perception.angular_valid, line_of_sight = perception.line_of_sight},
      }))
      self.attack_hit_committed = type(result) == "table" and result.ok == true
    end
    return
  end
  if age < finish then
    self:_set_state("recovery")
    self:_play(self.definition.nativeFeedback.patrol)
    return
  end
  self:_cancel_attack("ATTACK_FINISHED")
  self:_set_state(perception.visible and "chase" or "search")
  if not perception.visible then self.search_started_at = now end
end

function Controller:_patrol(now, dt)
  self:_play(self.definition.nativeFeedback.patrol)
  if now < self.patrol_wait_until then self:_stop_moving(); return end
  local arrived, reason = self:_follow(self.route[self.route_index], self.definition.patrolSpeedMps, dt, now)
  if arrived then
    self.route_index = self.route_index % #self.route + 1
    self.patrol_wait_until, self.patrol_failure_at = now + self.definition.patrolWaitSec, nil
    self:_clear_path()
  elseif reason == "NO_PATH" or reason == "MOVE_BLOCKED" then
    self.patrol_failure_at = self.patrol_failure_at or now
    if now - self.patrol_failure_at >= self.definition.patrolUnreachableSkipSec then
      self.route_index = self.route_index % #self.route + 1
      self.patrol_failure_at = nil
      self:_clear_path()
    end
  else self.patrol_failure_at = nil end
end

function Controller:update(dt)
  if self.disposed then return false, "DISPOSED" end
  if not self.started then return false, "NOT_STARTED" end
  if type(dt) ~= "number" or dt < 0 then return false, "INVALID_DT" end
  local public = self.context.state
  if public.run_id ~= self.bound_run_id then self:stop("RUN_CHANGED"); return false, "RUN_CHANGED" end
  if public.phase ~= "EXPLORE" and public.phase ~= "EXTRACTING" then
    self:_cancel_attack("SESSION_INACTIVE")
    self:_clear_path()
    self:_stop_moving()
    self.last_seen_position, self.last_seen_at = nil, nil
    self:_set_state("patrol")
    return true, "SESSION_INACTIVE"
  end
  local now = self:_now()
  local snapshot = self:_snapshot(self.instance.id)
  if not snapshot or snapshot.hp == nil then self:_stop_moving(); return false, "CHARACTER_UNAVAILABLE" end
  local hp = tonumber(snapshot.hp) or 0
  if snapshot.alive == false or hp <= 0 then
    if self.ai_state ~= "dead" then
      self:_cancel_attack("DEAD")
      self:_clear_path()
      self:_stop_moving()
      self:_set_state("dead")
      self:_play(self.definition.nativeFeedback.death, true)
    end
    self.last_hp = hp
    return true, "DEAD"
  end
  if self.ai_state == "dead" then return true, "DEAD" end
  if self.last_hp and hp < self.last_hp then
    self:_cancel_attack("HURT")
    self:_clear_path()
    self:_stop_moving()
    self:_set_state("hurt")
    self.hurt_until = now + self.definition.hurtPauseSec
    self:_play(self.definition.nativeFeedback.hit, true)
  end
  self.last_hp = hp
  if self.ai_state == "hurt" and now < self.hurt_until then return true, "HURT" end
  local target_snapshot = self:_snapshot(self.target_id)
  local perception = (target_snapshot and target_snapshot.alive ~= false and (tonumber(target_snapshot.hp) or 0) > 0)
    and self:_perception() or {visible = false}
  self:_remember_target(now, perception)
  if self.ai_state == "hurt" then self:_set_state(perception.visible and "chase" or "patrol") end
  if self.attack_instance_id then self:_update_attack(now, perception); return true, self.ai_state end
  local own_position = self:_position(self.instance.id)
  if own_position and ground_distance(own_position, self.home_position) > self.definition.leashRadiusM then
    self:_set_state("return")
    self.last_seen_position, self.last_seen_at = nil, nil
  elseif perception.visible then
    self:_set_state("chase")
  elseif self.ai_state == "chase" and self.last_seen_at
    and now - self.last_seen_at >= self.definition.sense.loseSightGraceSec then
    self:_set_state("search")
    self.search_started_at = now
    self:_clear_path()
  end
  if self.ai_state == "chase" then
    if perception.visible and perception.distance_m <= self.definition.attacks[1].rangeM and self:_begin_attack(now) then
      return true, "WINDUP"
    end
    self:_play(self.definition.nativeFeedback.patrol)
    if self.last_seen_position then self:_follow(self.last_seen_position, self.definition.chaseSpeedMps, dt, now)
    else self:_set_state("patrol") end
  elseif self.ai_state == "search" then
    self.search_started_at = self.search_started_at or now
    if now - self.search_started_at >= self.definition.sense.searchSec or not self.last_seen_position then
      self:_set_state("return")
      self:_clear_path()
    else
      self:_play(self.definition.nativeFeedback.patrol)
      self:_follow(self.last_seen_position, self.definition.patrolSpeedMps, dt, now)
    end
  elseif self.ai_state == "return" then
    self:_play(self.definition.nativeFeedback.patrol)
    local arrived = self:_follow(self.home_position, self.definition.patrolSpeedMps, dt, now)
    if arrived then
      self:_set_state("patrol")
      self.search_started_at, self.last_seen_position, self.last_seen_at = nil, nil, nil
      self:_clear_path()
    end
  elseif self.ai_state == "patrol" then self:_patrol(now, dt) end
  return true, self.ai_state
end

function Controller:stop(reason)
  if self.disposed then return false, "DISPOSED" end
  if self.started then
    self:_cancel_attack(reason or "STOPPED")
    self:_clear_path()
    self:_stop_moving()
  end
  self.started = false
  self:_set_state("stopped")
  return true, "STOPPED"
end

function Controller:dispose()
  if self.disposed then return true, "ALREADY_DISPOSED" end
  self:stop("DISPOSED")
  self.disposed, self.context = true, nil
  return true, "DISPOSED"
end

return Controller

end
module_loaders["gameplay.packages.monsters.monster_marmot.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "monster_marmot",
  ["displayName"] = "圆润土拨鼠",
  ["gate"] = "G1",
  ["assetId"] = "asset_monster_marmot",
  ["maxHp"] = 60,
  ["canDie"] = true,
  ["armorFlatHp"] = 0,
  ["damageReductionRatio"] = 0,
  ["patrolSpeedMps"] = 1.0,
  ["chaseSpeedMps"] = 3.0,
  ["patrolWaitSec"] = 1.0,
  ["sense"] = {
    ["rangeM"] = 7,
    ["fullAngleDeg"] = 100,
    ["requireLineOfSight"] = true,
    ["loseSightGraceSec"] = 1.2,
    ["searchSec"] = 4,
    ["showDebugCone"] = true,
  },
  ["leashRadiusM"] = 15,
  ["canCapture"] = true,
  ["captureHpRatioMax"] = 0.25,
  ["physicalDamageImmune"] = false,
  ["behaviorRuleId"] = "marmot_observe_pounce",
  ["behaviorParams"] = {
    ["kind"] = "marmot",
    ["observeDelaySec"] = 1.2,
    ["pounceSpeedMps"] = 6,
    ["lockTargetAtWindupStart"] = true,
  },
  ["attacks"] = {
    {
      ["id"] = "attack_monster_marmot",
      ["delivery"] = "lunge",
      ["damageHp"] = 25,
      ["damageType"] = "physical",
      ["damageMode"] = "single",
      ["tickIntervalSec"] = 0,
      ["firstTickDelaySec"] = 0,
      ["windupSec"] = 0.55,
      ["activeSec"] = 0.25,
      ["recoverySec"] = 0.7,
      ["cooldownSec"] = 2.0,
      ["rangeM"] = 3.5,
      ["arcDeg"] = 100,
      ["hitRadiusM"] = 0.25,
      ["maxTargets"] = 1,
      ["requireLineOfSight"] = true,
      ["clipId"] = "clip_monster_marmot_attack",
      ["hitTimeSec"] = 0.65,
    },
  },
  ["animationClips"] = {
    ["idle"] = "clip_monster_marmot_idle",
    ["patrol"] = "clip_monster_marmot_patrol",
    ["chase"] = "clip_monster_marmot_chase",
    ["attack"] = "clip_monster_marmot_attack",
    ["hurt"] = "clip_monster_marmot_hurt",
    ["death"] = "clip_monster_marmot_death",
    ["special"] = "clip_monster_marmot_special",
  },
  ["collider"] = {
    ["shape"] = "capsule",
    ["radiusM"] = 0.35,
    ["heightM"] = 0.8,
    ["centerY_M"] = 0.4,
  },
  ["type"] = "monster",
}

end
module_loaders["gameplay.packages.monsters.monster_marmot.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.monsters.monster_marmot.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Movement",
  "Navigation",
  "Inventory",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.monsters.monster_slime.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "monster_slime",
  ["displayName"] = "黏液史莱姆",
  ["gate"] = "G2",
  ["assetId"] = "asset_monster_slime",
  ["maxHp"] = 100,
  ["canDie"] = false,
  ["armorFlatHp"] = 0,
  ["damageReductionRatio"] = 0,
  ["patrolSpeedMps"] = 0.8,
  ["chaseSpeedMps"] = 1.2,
  ["patrolWaitSec"] = 1.0,
  ["sense"] = {
    ["rangeM"] = 7,
    ["fullAngleDeg"] = 100,
    ["requireLineOfSight"] = true,
    ["loseSightGraceSec"] = 1.2,
    ["searchSec"] = 4,
    ["showDebugCone"] = true,
  },
  ["leashRadiusM"] = 15,
  ["canCapture"] = false,
  ["captureHpRatioMax"] = 0.25,
  ["physicalDamageImmune"] = true,
  ["behaviorRuleId"] = "slime_contact_enrage",
  ["behaviorParams"] = {
    ["kind"] = "slime",
    ["enrageSpeedMultiplier"] = 1.5,
    ["enrageDurationSec"] = 6,
    ["musicControlSec"] = 8,
    ["enrageStacks"] = false,
  },
  ["attacks"] = {
    {
      ["id"] = "attack_monster_slime",
      ["delivery"] = "contact",
      ["damageHp"] = 30,
      ["damageType"] = "hazard",
      ["damageMode"] = "periodic",
      ["tickIntervalSec"] = 2.0,
      ["firstTickDelaySec"] = 0,
      ["windupSec"] = 0,
      ["activeSec"] = 6.0,
      ["recoverySec"] = 0,
      ["cooldownSec"] = 6.0,
      ["rangeM"] = 1.1,
      ["arcDeg"] = 100,
      ["hitRadiusM"] = 0.25,
      ["maxTargets"] = 1,
      ["requireLineOfSight"] = false,
      ["clipId"] = "clip_monster_slime_attack",
      ["hitTimeSec"] = 0.1,
    },
  },
  ["animationClips"] = {
    ["idle"] = "clip_monster_slime_idle",
    ["patrol"] = "clip_monster_slime_patrol",
    ["chase"] = "clip_monster_slime_chase",
    ["attack"] = "clip_monster_slime_attack",
    ["hurt"] = "clip_monster_slime_hurt",
    ["death"] = "clip_monster_slime_death",
    ["special"] = "clip_monster_slime_special",
  },
  ["collider"] = {
    ["shape"] = "capsule",
    ["radiusM"] = 0.4,
    ["heightM"] = 0.85,
    ["centerY_M"] = 0.425,
  },
  ["type"] = "monster",
}

end
module_loaders["gameplay.packages.monsters.monster_slime.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.monsters.monster_slime.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Movement",
  "Navigation",
  "Inventory",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.player.player_default.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "player_default",
  ["displayName"] = "玩家角色与动作",
  ["gate"] = "G1",
  ["maxHpRef"] = "player.maxHp",
  ["walkSpeedRef"] = "player.walkSpeedMps",
  ["colliderRef"] = "player",
  ["holdSockets"] = {
    "weapon_right",
    "tool_left",
  },
  ["type"] = "player",
  ["assetId"] = "asset_player_default",
}

end
module_loaders["gameplay.packages.player.player_default.controller"] = function()
  local require = ProjectRequire
-- Planner-owned player action driver; authoritative HP stays in Characters.
local Definition = require("gameplay.packages.player.player_default.definition")
local Controller = {}
Controller.__index = Controller

function Controller.new(context, instance)
  assert(type(context) == "table" and type(instance) == "table" and instance.id, "context/instance required")
  return setmetatable({context=context, instance=instance, definition=Definition,
    started=false, disposed=false, action="idle", input_allowed=false, move_allowed=false}, Controller)
end

function Controller:request(prefix, fields)
  fields = fields or {}
  fields.run_id = self.context.state.run_id
  fields.request_id = self.context:next_request_id(prefix)
  return fields
end

function Controller:play_action(action)
  if self.disposed or not self.started then return false end
  self.action = action
  self.context.services.Assets:play_clip(self:request("player_action", {
    instance_id=self.instance.id, clip_id="native_" .. action, native_action=action
  }))
  return true
end

function Controller:start()
  if self.disposed then return false, "DISPOSED" end
  if self.context.is_ready == false then return false, "ADAPTER_NOT_READY" end
  for _, name in ipairs({"Characters", "Assets"}) do
    if not self.context.services[name] then return false, "MISSING_SERVICE:" .. name end
  end
  self.started = true
  self:play_action("idle")
  return true
end

function Controller:update(dt)
  if self.disposed or not self.started then return end
  local result = self.context.services.Characters:read_snapshot(self:request("player_snapshot", {instance_id=self.instance.id}))
  if not result.ok then self.input_allowed=false;self.move_allowed=false;return end
  local snapshot = result.data
  local phase = self.context.state.phase
  self.input_allowed = snapshot.alive and phase == "EXPLORE"
  self.move_allowed = snapshot.alive and (phase == "EXPLORE" or phase == "EXTRACTING")
  local action
  if not snapshot.alive then
    action = "death"
  elseif self.last_hp and snapshot.hp < self.last_hp then
    action = "hurt"
    self.hurt_until = self.context.state.clock + .3
  elseif self.hurt_until and self.context.state.clock < self.hurt_until then
    action = "hurt"
  else
    local p, previous = snapshot.position_m, self.last_position
    local distance = 0
    if p and previous then
      local x,z=p.x-previous.x,p.z-previous.z
      distance=math.sqrt(x*x+z*z)
    end
    action = self.move_allowed and distance > .002 and "walk" or "idle"
  end
  if action ~= self.action then self:play_action(action) end
  self.last_hp = snapshot.hp
  if snapshot.position_m then
    local p=snapshot.position_m
    self.last_position={x=p.x,y=p.y,z=p.z}
  end
end

function Controller:dispose()
  if self.disposed then return end
  self.input_allowed=false;self.move_allowed=false;self.started=false;self.disposed=true
end
return Controller

end
module_loaders["gameplay.packages.interactables.trap_spikes.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "trap_spikes",
  ["displayName"] = "尖刺机关",
  ["gate"] = "G1",
  ["triggerMode"] = "overlap",
  ["damageHp"] = 20,
  ["warningSec"] = 0.6,
  ["activeSec"] = 0.3,
  ["resetSec"] = 3,
  ["damageDedupe"] = "activationInstanceId+targetId",
  ["type"] = "interactable",
  ["assetId"] = "asset_trap_spikes",
}

end
module_loaders["gameplay.packages.interactables.trap_spikes.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.interactables.trap_spikes.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Interaction",
  "Inventory",
  "Combat",
  "Session",
  "Assets",
})
end
return Controller

end
module_loaders["gameplay.packages.ui.ui_main.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "ui_main",
  ["displayName"] = "HUD与背包交互",
  ["gate"] = "G1",
  ["screens"] = {
    "hud",
    "inventory",
    "container",
    "item_use",
    "extraction",
    "result",
  },
  ["dataSource"] = "read_only_core_snapshots",
  ["modalBlocksWorldInput"] = true,
  ["type"] = "ui",
}

end
module_loaders["gameplay.packages.ui.ui_main.controller"] = function()
  local require = ProjectRequire
-- Program-owned native Demo HUD. Visuals are deliberately whitebox references.
local UI={};UI.__index=UI
function UI.new(context,dispatch)
 return setmetatable({context=context,dispatch=dispatch,view=nil,last_refresh=0,rows={}},UI)
end
function UI:start()
 local U=CS.UnityEngine;self.U=U;local V,C=U.Vector2,U.Color
 local fonts=U.Resources.FindObjectsOfTypeAll(typeof(U.Font));for i=0,fonts.Length-1 do if fonts[i].name=='NotoSansSC-Medium'then self.font=fonts[i];break end end
 self.font=self.font or U.Font.CreateDynamicFontFromOSFont('PingFang SC',20)
 self.root=U.GameObject('demo_ui');self.root.transform:SetParent(self.context.adapter.runtime_root.transform,false)
 local canvas=self.root:AddComponent(typeof(U.Canvas));canvas.renderMode=U.RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=160
 local scaler=self.root:AddComponent(typeof(U.UI.CanvasScaler));scaler.uiScaleMode=U.UI.CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=V(1280,720);scaler.matchWidthOrHeight=.5
 self.root:AddComponent(typeof(U.UI.GraphicRaycaster))
 local top=self:panel(self.root,'hud',0,-58,900,94,C(.035,.065,.1,.94),V(.5,1))
 self.title=self:text(top,'title','仔仔搜打撤1.0',0,24,860,32,22)
 self.status=self:text(top,'status','初始化中',0,-3,860,25,17)
 self.hint=self:text(top,'objective','探索四房 → 开宝箱 → 收集 / 用药 → 绿色区域撤离',0,-30,860,25,15)
 self.notice=self:text(self.root,'notice','',0,102,950,36,18,V(.5,0))
 self.help=self:text(self.root,'help','WASD 移动  Shift 冲刺  Ctrl 蹲行  E 交互  F 铲击  B 背包  H 用药',0,34,1050,26,15,V(.5,0))
 self:button(self.root,'interact','交互 / E',-100,175,170,44,function()self.dispatch('interact')end,V(1,0))
 self:button(self.root,'attack','铲击 / F',-100,226,170,44,function()self.dispatch('attack')end,V(1,0))
 self:button(self.root,'heal','用药 / H',-100,277,170,44,function()self.dispatch('heal')end,V(1,0))
 self:button(self.root,'bag','背包 / B',-100,-141,170,38,function()self.dispatch('bag')end,V(1,1))
 self:button(self.root,'attributes','角色 / 怪物属性',-100,-186,170,38,function()self.dispatch('attributes')end,V(1,1))
 self:button(self.root,'qa','验证 Demo',-100,-231,170,38,function()self.dispatch('qa')end,V(1,1))
 self.modal=self:panel(self.root,'modal',0,0,660,440,C(.04,.075,.115,.99));self.modal:GetComponent(typeof(U.UI.Image)).raycastTarget=true
 self.modal_title=self:text(self.modal,'modal_title','背包',0,182,600,36,24)
 self.modal_hint=self:text(self.modal,'modal_hint','',0,-112,580,45,16)
 self:button(self.modal,'close','关闭',263,182,98,35,function()self.dispatch('close')end)
 self.take=self:button(self.modal,'take_all','全部拾取',0,-182,170,42,function()self.dispatch('take_all')end)
 self.modal:SetActive(false)
 self.result_panel=self:panel(self.root,'result',0,0,660,340,C(.03,.07,.105,.99));self.result_panel:GetComponent(typeof(U.UI.Image)).raycastTarget=true
 self.result_text=self:text(self.result_panel,'result_text','',0,25,610,210,22)
 self:button(self.result_panel,'restart','重新开始',0,-120,190,44,function()self.dispatch('restart')end)
 self.result_panel:SetActive(false)
 self.started=true;return true
end
function UI:panel(parent,name,x,y,w,h,color,anchor)
 local U=self.U;local go=U.GameObject('demo_ui_'..name);go.transform:SetParent(parent.transform,false)
 local rect=go:AddComponent(typeof(U.RectTransform));rect.anchorMin=anchor or U.Vector2(.5,.5);rect.anchorMax=rect.anchorMin;rect.sizeDelta=U.Vector2(w,h);rect.anchoredPosition=U.Vector2(x,y)
 local image=go:AddComponent(typeof(U.UI.Image));image.color=color;image.raycastTarget=false;return go
end
function UI:text(parent,name,value,x,y,w,h,size,anchor)
 local U=self.U;local go=U.GameObject('demo_ui_'..name);go.transform:SetParent(parent.transform,false)
 local rect=go:AddComponent(typeof(U.RectTransform));rect.anchorMin=anchor or U.Vector2(.5,.5);rect.anchorMax=rect.anchorMin;rect.sizeDelta=U.Vector2(w,h);rect.anchoredPosition=U.Vector2(x,y)
 local label=go:AddComponent(typeof(U.UI.Text));label.font=self.font;label.fontSize=size;label.text=value;label.color=U.Color(.91,.96,1,1);label.alignment=U.TextAnchor.MiddleCenter;label.raycastTarget=false;return label
end
function UI:button(parent,name,value,x,y,w,h,fn,anchor)
 local U=self.U;local go=self:panel(parent,name,x,y,w,h,U.Color(.14,.3,.39,1),anchor)
 local image=go:GetComponent(typeof(U.UI.Image));image.raycastTarget=true
 local button=go:AddComponent(typeof(U.UI.Button));button.targetGraphic=image;button.onClick:AddListener(fn)
 self:text(go,name..'_label',value,0,0,w-6,h-4,16);return go
end
function UI:open(view,request)
 self.view=view;self.view_request=request or{};self.modal:SetActive(true);self:refresh_modal()
end
function UI:close()self.view=nil;self.modal:SetActive(false)end
function UI:refresh_modal()
 local ctx=self.context;local s=ctx.state
 for _,go in ipairs(self.rows)do self.U.Object.Destroy(go)end;self.rows={}
 self.take:SetActive(self.view=='chest')
 if self.view=='attributes'then
  local p=ctx.services.Characters:read_snapshot({run_id=s.run_id,instance_id='player_local'}).data
  local m=ctx.services.Characters:read_snapshot({run_id=s.run_id,instance_id='monster_cube_1'}).data
  local d=ctx.definitions.monster_cube
  self.modal_title.text='Demo · 公共属性与对象挂钩'
  local content='角色 HP '..tostring(p.hp)..' / '..tostring(p.max_hp)..'\n步行 '..ctx.config.player.walkSpeedMps..'  冲刺 '..ctx.config.player.sprintSpeedMps..'  蹲行 '..ctx.config.player.crouchSpeedMps..' m/s\n出生保护 '..ctx.config.player.spawnProtectionSec..' s  受击保护 '..ctx.config.player.hitInvulnerabilitySec..' s\n方块怪物 HP '..tostring(m.hp)..' / '..tostring(m.max_hp)..'\n视距 '..d.sense.rangeM..' m  视角 '..d.sense.fullAngleDeg..'°\n怪物伤害 '..d.attacks[1].damageHp..'  铲伤害 '..ctx.definitions.weapon_shovel.attack.damageHp
  local label=self:text(self.modal,'attributes_body',content,0,20,610,255,19);self.rows[1]=label.gameObject
  self.modal_hint.text='逻辑属性调整后重启预览 · 实际速度 '..tostring(ctx.adapter.speed_readback or'未映射')..' · 胶囊 '..(ctx.adapter.collider_apply_ok and'已映射'or'待 SDK 映射')
  return
 end
 local chest=self.view=='chest'
 local snap=ctx.services.Inventory:read_snapshot({run_id=s.run_id,container_id=chest and'chest_demo'or'bag_player_local'})
 local bag=snap.data.bag or{items={},slots=12}
 self.modal_title.text=(chest and'补给宝箱'or'随身背包')..'  '..#bag.items..' / '..bag.slots..' 格'
 for i,item in ipairs(bag.items)do
  local item_id=item.id;local def=ctx.definitions[item.entity_id]or{}
  local value=(def.displayName or item.entity_id)..' ×'..item.count..(chest and' · 拾取'or(item.entity_id=='item_heal_small'and' · 使用'or' · 藏品'))
  self.rows[#self.rows+1]=self:button(self.modal,'item_'..i,value,0,118-(i-1)*54,550,43,function()self.dispatch(chest and'pickup'or'use_item',item_id)end)
 end
 self.modal_hint.text=chest and'拾取走统一库存事务；再次打开不会重抽物品。'or'药品恢复 30 HP，读条 1.2 秒；满血或中断不消耗。'
end
function UI:update_snapshot(r)if self.view then self:refresh_modal()end end
function UI:update(dt)
 if not self.started then return end
 local ctx=self.context;local s=ctx.state;local p=s.entities.player_local;local m=s.entities.monster_cube_1
 local remaining=math.max(0,ctx.config.session.roundDurationSec-s.clock)
 self.status.text='HP '..tostring(p and p.hp or'-')..' / '..ctx.config.player.maxHp..'    时间 '..math.floor(remaining/60)..':'..string.format('%02d',math.floor(remaining%60))..'    方块 HP '..tostring(m and m.hp or'-')..'    '..tostring(s.phase)
 local bag=s.containers.bag_player_local;local count=bag and#bag.items or 0
 self.hint.text='背包 '..count..' / '..ctx.config.inventory.bagSlots..'    怪物：'..tostring(ctx.demo and ctx.demo.objects.monster.ai_state or'等待')..'    搜集后回绿色区域撤离'
 if s.extract then self.hint.text='撤离中 '..string.format('%.1f',math.max(0,ctx.config.session.extractionHoldSec-(s.clock-s.extract.started_at)))..' 秒 · 离区或受击取消'end
 self.notice.text=s.toast or''
 if ctx.demo and ctx.demo.qa_summary then self.notice.text=ctx.demo.qa_summary end
 local heal=ctx.demo and ctx.demo.objects.heal
 if heal and heal.cast then self.notice.text='用药读条 '..string.format('%.1f',heal:get_status().progress_sec)..' / 1.2 秒'end
 self.result_panel:SetActive(s.result~=nil)
 if s.result then
  self.result_text.text=(s.result.success and'撤离成功'or'探索失败')..'\n带出价值：'..s.result.loot_value..'\n结果原因：'..s.result.reason..'\n结算 ID：'..s.result.result_id..'\n本地 Demo：仓库 / 商店 / 多人另行接入'
 end
 if self.view and ((self.view=='attributes'and s.clock-self.last_refresh>=.5)or self.last_inventory_version~=s.inventory_version)then self.last_refresh=s.clock;self.last_inventory_version=s.inventory_version;self:refresh_modal()end
end
function UI:dispose()self.started=false;if self.root then self.U.Object.Destroy(self.root)end end
return UI

end
module_loaders["gameplay.packages.weapons.weapon_ranged_sample.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "weapon_ranged_sample",
  ["displayName"] = "远程样例",
  ["gate"] = "G2",
  ["assetId"] = "asset_weapon_ranged_sample",
  ["equipmentSlot"] = "weapon",
  ["weightKg"] = 2.5,
  ["durabilityMax"] = 0,
  ["durabilityCostPerAttack"] = 0,
  ["ammoCapacity"] = 8,
  ["reloadSec"] = 1.6,
  ["ammoCostPerAttack"] = 1,
  ["attack"] = {
    ["id"] = "attack_weapon_ranged_sample",
    ["delivery"] = "hitscan",
    ["damageHp"] = 20,
    ["damageType"] = "physical",
    ["damageMode"] = "single",
    ["tickIntervalSec"] = 0,
    ["firstTickDelaySec"] = 0,
    ["windupSec"] = 0.05,
    ["activeSec"] = 0.05,
    ["recoverySec"] = 0.2,
    ["cooldownSec"] = 0.35,
    ["rangeM"] = 15,
    ["arcDeg"] = 8,
    ["hitRadiusM"] = 0.25,
    ["maxTargets"] = 1,
    ["requireLineOfSight"] = true,
    ["clipId"] = "clip_weapon_ranged_sample_attack",
    ["hitTimeSec"] = 0.075,
  },
  ["gripSocket"] = "weapon_right",
  ["type"] = "weapon",
  ["playerAnimationResourceId"] = "anim_weapon_ranged_sample_player",
}

end
module_loaders["gameplay.packages.weapons.weapon_ranged_sample.controller"] = function()
  local require = ProjectRequire
-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.weapons.weapon_ranged_sample.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Assets",
  "Session",
})
end
return Controller

end
module_loaders["gameplay.packages.weapons.weapon_shovel.definition"] = function()
  local require = ProjectRequire
-- Read-only object definition. Runtime HP/ammo/AI state belongs to instances.
return {
  ["schemaVersion"] = "0.2.0",
  ["id"] = "weapon_shovel",
  ["displayName"] = "默认铲",
  ["gate"] = "G1",
  ["assetId"] = "asset_weapon_shovel",
  ["equipmentSlot"] = "weapon",
  ["weightKg"] = 1.8,
  ["durabilityMax"] = 100,
  ["durabilityCostPerAttack"] = 1,
  ["ammoCapacity"] = 0,
  ["reloadSec"] = 0,
  ["ammoCostPerAttack"] = 0,
  ["attack"] = {
    ["id"] = "attack_weapon_shovel",
    ["delivery"] = "melee_sector",
    ["damageHp"] = 30,
    ["damageType"] = "physical",
    ["damageMode"] = "single",
    ["tickIntervalSec"] = 0,
    ["firstTickDelaySec"] = 0,
    ["windupSec"] = 0.3,
    ["activeSec"] = 0.2,
    ["recoverySec"] = 0.5,
    ["cooldownSec"] = 1.3,
    ["rangeM"] = 2.5,
    ["arcDeg"] = 110,
    ["hitRadiusM"] = 0.25,
    ["maxTargets"] = 1,
    ["requireLineOfSight"] = true,
    ["clipId"] = "clip_weapon_shovel_attack",
    ["hitTimeSec"] = 0.4,
  },
  ["gripSocket"] = "weapon_right",
  ["type"] = "weapon",
  ["playerAnimationResourceId"] = "anim_weapon_shovel_player",
}

end
module_loaders["gameplay.packages.weapons.weapon_shovel.controller"] = function()
  local require = ProjectRequire
-- Planner-owned shovel timing. The public Combat service alone commits damage.
local Definition = require("gameplay.packages.weapons.weapon_shovel.definition")
local Controller = {}
Controller.__index = Controller
local function result(ok, reason, id, data)
  return {ok=ok,reason=reason,request_id=id,data=data or {}}
end
function Controller.new(context, instance)
  assert(type(context)=="table" and type(instance)=="table" and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    started=false,disposed=false,stage="IDLE",next_use_at=0},Controller)
end
function Controller:request(prefix, fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED" end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY" end
  for _,name in ipairs({"Characters","Combat","Interaction","Assets"}) do
    if not self.context.services[name] then return false,"MISSING_SERVICE:"..name end
  end
  self.started=true;return true
end
function Controller:can_hit(target)
  local owner=self.instance.owner_instance_id or "player_local"
  local query=self.context.services.Interaction:query_target(self:request("shovel_target",{
    user_instance_id=owner,source_instance_id=owner,target_instance_id=target,mode="weapon",
    max_distance_m=Definition.attack.rangeM,full_angle_deg=Definition.attack.arcDeg
  }))
  if not query.ok then return false,query.reason,query.data end
  local evidence=query.data or {}
  local valid=evidence.visible==true and evidence.in_range==true and
    evidence.angular_valid==true and evidence.line_of_sight==true
  return valid,valid and nil or "TARGET_NOT_HITTABLE",evidence
end
function Controller:use(request)
  request=request or {}
  local id=request.request_id or self.context:next_request_id("shovel_use")
  if self.disposed then return result(false,"DISPOSED",id) end
  if not self.started then return result(false,"NOT_STARTED",id) end
  if self.context.state.phase~="EXPLORE" then return result(false,"INVALID_PHASE",id) end
  if self.attack then return result(false,"ATTACK_IN_PROGRESS",id) end
  local now=self.context.state.clock
  if now<self.next_use_at then return result(false,"COOLDOWN",id) end
  local target=request.target_instance_id
  if not target then return result(false,"TARGET_REQUIRED",id) end
  local can_hit,reason=self:can_hit(target)
  if not can_hit then return result(false,reason,id) end
  local owner=self.instance.owner_instance_id or "player_local"
  local begin=self.context.services.Combat:try_begin_attack(self:request("shovel_begin",{
    source_instance_id=owner,attack_id=Definition.attack.id,item_instance_id=self.instance.item_instance_id
  }))
  if not begin.ok then self.last_result=begin;return begin end
  self.attack={id=begin.data.attack_instance_id,target_id=target,started_at=now,owner_id=owner,attempted=false}
  self.stage="WINDUP";self.next_use_at=now+Definition.attack.cooldownSec
  self.context.services.Assets:play_clip(self:request("shovel_animation",{
    instance_id=owner,clip_id="native_attack",native_action="attack",definition_clip_id=Definition.attack.clipId
  }))
  self.last_result=begin
  return begin
end
function Controller:cancel(reason)
  local attack=self.attack
  if attack then
    self.context.services.Combat:cancel_attack(self:request("shovel_cancel",{attack_instance_id=attack.id}))
  end
  self.attack=nil;self.stage="IDLE"
  self.cancel_reason=reason
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.attack then return end
  if self.context.state.phase~="EXPLORE" then self:cancel("PHASE_CHANGED");return end
  local attack=self.attack
  local player=self.context.services.Characters:read_snapshot(self:request("shovel_owner",{instance_id=attack.owner_id}))
  if not player.ok or not player.data.alive then self:cancel("OWNER_DEAD");return end
  local elapsed=self.context.state.clock-attack.started_at
  local active_start=Definition.attack.windupSec
  local active_end=active_start+Definition.attack.activeSec
  local total=active_end+Definition.attack.recoverySec
  if elapsed<active_start then self.stage="WINDUP"
  elseif elapsed<active_end then
    self.stage="ACTIVE"
    if not attack.attempted then
      attack.attempted=true
      local valid,reason,evidence=self:can_hit(attack.target_id)
      if valid then
        self.last_result=self.context.services.Combat:try_apply_damage(self:request("shovel_hit",{
          attack_instance_id=attack.id,target_instance_id=attack.target_id,tick_index=0,
          hit_evidence={distance_m=evidence.distance_m,angular_valid=true,line_of_sight=true}
        }))
      else self.last_result=result(false,reason,self.context:next_request_id("shovel_miss")) end
    end
  elseif elapsed<total then self.stage="RECOVERY"
  else self:cancel("COMPLETED") end
end
function Controller:get_status()
  local elapsed=self.attack and self.context.state.clock-self.attack.started_at or 0
  return {stage=self.stage,elapsed_sec=elapsed,cooldown_remaining=math.max(0,self.next_use_at-self.context.state.clock),last_result=self.last_result}
end
function Controller:dispose()
  if self.disposed then return end
  self:cancel("DISPOSED");self.started=false;self.disposed=true
end
return Controller

end
module_loaders["gameplay.package_factories"] = function()
  local require = ProjectRequire
-- Generated from package manifests. Do not edit.
return {
  ["chest_basic"] = {
    definition = require("gameplay.packages.interactables.chest_basic.definition"),
    controller = require("gameplay.packages.interactables.chest_basic.controller"),
  },
  ["gate_exit"] = {
    definition = require("gameplay.packages.interactables.gate_exit.definition"),
    controller = require("gameplay.packages.interactables.gate_exit.controller"),
  },
  ["item_capture"] = {
    definition = require("gameplay.packages.items.item_capture.definition"),
    controller = require("gameplay.packages.items.item_capture.controller"),
  },
  ["item_flashlight"] = {
    definition = require("gameplay.packages.items.item_flashlight.definition"),
    controller = require("gameplay.packages.items.item_flashlight.controller"),
  },
  ["item_heal_small"] = {
    definition = require("gameplay.packages.items.item_heal_small.definition"),
    controller = require("gameplay.packages.items.item_heal_small.controller"),
  },
  ["item_music_box"] = {
    definition = require("gameplay.packages.items.item_music_box.definition"),
    controller = require("gameplay.packages.items.item_music_box.controller"),
  },
  ["item_treasure"] = {
    definition = require("gameplay.packages.items.item_treasure.definition"),
    controller = require("gameplay.packages.items.item_treasure.controller"),
  },
  ["map_demo"] = {
    definition = require("gameplay.packages.environment.map_demo.definition"),
    controller = require("gameplay.packages.environment.map_demo.controller"),
  },
  ["map_tomb"] = {
    definition = require("gameplay.packages.environment.map_tomb.definition"),
    controller = require("gameplay.packages.environment.map_tomb.controller"),
  },
  ["monster_bat"] = {
    definition = require("gameplay.packages.monsters.monster_bat.definition"),
    controller = require("gameplay.packages.monsters.monster_bat.controller"),
  },
  ["monster_cube"] = {
    definition = require("gameplay.packages.monsters.monster_cube.definition"),
    controller = require("gameplay.packages.monsters.monster_cube.controller"),
  },
  ["monster_marmot"] = {
    definition = require("gameplay.packages.monsters.monster_marmot.definition"),
    controller = require("gameplay.packages.monsters.monster_marmot.controller"),
  },
  ["monster_slime"] = {
    definition = require("gameplay.packages.monsters.monster_slime.definition"),
    controller = require("gameplay.packages.monsters.monster_slime.controller"),
  },
  ["player_default"] = {
    definition = require("gameplay.packages.player.player_default.definition"),
    controller = require("gameplay.packages.player.player_default.controller"),
  },
  ["trap_spikes"] = {
    definition = require("gameplay.packages.interactables.trap_spikes.definition"),
    controller = require("gameplay.packages.interactables.trap_spikes.controller"),
  },
  ["ui_main"] = {
    definition = require("gameplay.packages.ui.ui_main.definition"),
    controller = require("gameplay.packages.ui.ui_main.controller"),
  },
  ["weapon_ranged_sample"] = {
    definition = require("gameplay.packages.weapons.weapon_ranged_sample.definition"),
    controller = require("gameplay.packages.weapons.weapon_ranged_sample.controller"),
  },
  ["weapon_shovel"] = {
    definition = require("gameplay.packages.weapons.weapon_shovel.definition"),
    controller = require("gameplay.packages.weapons.weapon_shovel.controller"),
  },
}

end
module_loaders["gameplay.core.state"] = function()
  local require = ProjectRequire
-- Pure Lua authoritative Demo state. No SDK calls and no mutable definitions.
local State = {}
State.__index = State

function State.new(config)
  return setmetatable({
    config=config, clock=0, run_id="", phase="LOBBY", entities={},
    containers={}, attacks={}, requests={}, damage_keys={}, inventory_version=0,
    result=nil, extract=nil, toast="", run_sequence=0, attack_sequence=0,
    item_sequence=0, player_id=nil, pending_terminal=nil, cooldowns={},
  }, State)
end

function State:reset_run(run_id)
  self.clock=0
  self.run_id=run_id
  self.phase="EXPLORE"
  self.entities={}
  self.containers={}
  self.attacks={}
  self.requests={}
  self.damage_keys={}
  self.inventory_version=0
  self.result=nil
  self.extract=nil
  self.toast=""
  self.attack_sequence=0
  self.item_sequence=0
  self.player_id=nil
  self.pending_terminal=nil
  self.cooldowns={}
end

return State

end
module_loaders["gameplay.core.services"] = function()
  local require = ProjectRequire
-- Authority for HP, inventory transactions and round results. Lua 5.1.
-- spatial.position(id) -> position; distance(position,position) -> metres;
-- spatial.los(position,position) -> boolean. No native engine APIs are assumed.
local Services = {}
local function copy(value)
  if type(value)~="table" then return value end
  local result={}
  for key,item in pairs(value) do result[key]=copy(item) end
  return result
end
local function finite(value)
  return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
local function positive_integer(value)
  return finite(value) and value>0 and value==math.floor(value)
end
local function text(value) return type(value)=="string" and value~="" end

function Services.new(state, config, definitions, spatial)
  definitions=definitions or {}
  spatial=spatial or {}
  local Characters, Combat, Inventory, Session={},{},{},{}
  local player_config=config.player or {}
  local inventory_config=config.inventory or {}
  local interaction_config=config.interaction or {}
  local combat_config=config.combat or {}
  local session_config=config.session or {}

  local function result(request,ok,reason,data)
    return {ok=ok,reason=reason or (ok and "OK" or "FAILED"),
      request_id=type(request)=="table" and request.request_id or nil,data=copy(data or {})}
  end
  local function fail(request,reason) return result(request,false,reason) end
  local function active() return state.phase=="EXPLORE" or state.phase=="EXTRACTING" end
  local function validate(request,playing)
    if type(request)~="table" then return "INVALID_REQUEST" end
    if request.run_id~=state.run_id then return "STALE_RUN" end
    if playing and not active() then return "ROUND_NOT_ACTIVE" end
  end
  local function mutate(name,request,operation)
    if type(request)~="table" or not text(request.request_id) then return fail(request,"REQUEST_ID_REQUIRED") end
    local key=name..":"..request.request_id
    local cached=state.requests[key]
    if cached then
      if request.run_id~=nil and request.run_id~=state.run_id then return fail(request,"STALE_RUN") end
      return copy(cached)
    end
    local value=operation()
    state.requests[key]=copy(value)
    return value
  end
  local function position(id)
    if type(spatial.position)=="function" then
      local ok,value=pcall(spatial.position,id)
      if ok and type(value)=="table" then return value end
    end
    local entity=state.entities[id]
    return entity and entity.position_m or nil
  end
  local function distance(a,b)
    if not a or not b then return nil end
    if type(spatial.distance)=="function" then
      local ok,value=pcall(spatial.distance,a,b)
      if ok and finite(value) and value>=0 then return value end
    end
    if not (finite(a.x) and finite(a.y) and finite(a.z) and finite(b.x) and finite(b.y) and finite(b.z)) then return nil end
    local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
    return math.sqrt(x*x+y*y+z*z)
  end
  local function los(a,b)
    if type(spatial.los)~="function" then return nil end
    local ok,value=pcall(spatial.los,a,b)
    if not ok or type(value)~="boolean" then return nil end
    return value
  end
  local function is_player(entity)
    local definition=definitions[entity.entity_id] or {}
    return definition.type=="player" or string.sub(entity.entity_id,1,7)=="player_"
  end
  local function bag_for(owner_id)
    local entity=state.entities[owner_id]
    return entity and state.containers[entity.bag_id] or state.containers["bag_"..tostring(owner_id)]
  end
  local function find_item(item_id)
    for _,container in pairs(state.containers) do
      for index,item in ipairs(container.items) do
        if item.id==item_id then return item,container,index,nil end
      end
    end
    for _,entity in pairs(state.entities) do
      for slot,item in pairs(entity.equipment or {}) do
        if item and item.id==item_id then return item,nil,nil,{entity=entity,slot=slot} end
      end
    end
  end
  local function changed(container)
    if container then container.version=container.version+1 end
    state.inventory_version=state.inventory_version+1
  end
  local function consume_item(item,container,index,count)
    item.count=item.count-count
    if item.count==0 then table.remove(container.items,index) end
    changed(container)
  end
  local function snapshot(container,owner_id)
    local entity=state.entities[owner_id or container.owner_id]
    return {bag=copy(container),items=copy(container.items),container_id=container.id,
      owner_id=container.owner_id,slots=container.slots,version=container.version,
      equipment=copy(entity and entity.equipment or {}),inventory_version=state.inventory_version}
  end

  function Characters:spawn(request)
    return mutate("Characters.spawn",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      if not text(request.instance_id) or not text(request.entity_id) then return fail(request,"INVALID_ENTITY_ID") end
      if state.entities[request.instance_id] then return fail(request,"INSTANCE_EXISTS") end
      local definition=definitions[request.entity_id]
      if not definition then return fail(request,"UNKNOWN_ENTITY") end
      local maximum=(definition.basic or {}).maxHp or definition.maxHp or player_config.maxHp or 100
      if not positive_integer(maximum) then return fail(request,"INVALID_MAX_HP") end
      local entity={id=request.instance_id,entity_id=request.entity_id,hp=maximum,max_hp=maximum,
        alive=true,position_m=copy(request.position_m or {x=0,y=0,z=0}),
        forward_m=copy(request.forward_m or {x=0,y=0,z=1}),last_hit_at=-math.huge,
        spawn_protect_until=state.clock,armor_flat_hp=definition.armorFlatHp or 0,
        damage_reduction_ratio=definition.damageReductionRatio or 0,equipment={},modifiers={}}
      if is_player(entity) then
        entity.hp=math.min(maximum,player_config.startHp or maximum)
        entity.armor_flat_hp=player_config.armorFlatHp or 0
        entity.damage_reduction_ratio=player_config.damageReductionRatio or 0
        entity.spawn_protect_until=state.clock+(player_config.spawnProtectionSec or 0)
        entity.bag_id="bag_"..entity.id
        state.containers[entity.bag_id]={id=entity.bag_id,owner_id=entity.id,
          slots=inventory_config.bagSlots or 12,items={},version=0}
        state.player_id=entity.id
      end
      state.entities[entity.id]=entity
      return result(request,true,nil,{instance=entity,instance_id=entity.id,bag_id=entity.bag_id})
    end)
  end
  function Characters:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    local entity=state.entities[request.instance_id]
    if not entity then return fail(request,"UNKNOWN_INSTANCE") end
    local value=copy(entity)
    value.position_m=copy(position(entity.id) or entity.position_m)
    return result(request,true,nil,value)
  end
  function Characters:apply_modifier(request) return fail(request,"UNSUPPORTED_DEMO_MODIFIER") end
  function Characters:remove_modifier(request) return fail(request,"UNSUPPORTED_DEMO_MODIFIER") end

  local function get_attack(source,attack_id)
    local definition=definitions[source.entity_id] or {}
    if definition.attack and (definition.attack.id==attack_id or attack_id=="primary") then return definition.attack end
    for _,attack in ipairs(definition.attacks or {}) do
      if attack.id==attack_id then return attack end
    end
    if is_player(source) then
      local weapon=source.equipment.weapon
      local weapon_definition=weapon and definitions[weapon.entity_id] or definitions.weapon_shovel
      if weapon_definition and weapon_definition.attack and weapon_definition.attack.id==attack_id then
        return weapon_definition.attack
      end
    end
  end
  function Combat:try_begin_attack(request)
    return mutate("Combat.begin",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local source=state.entities[request.source_instance_id]
      if not source or not source.alive then return fail(request,"SOURCE_NOT_ALIVE") end
      local attack=get_attack(source,request.attack_id)
      if not attack then return fail(request,"UNKNOWN_ATTACK") end
      local key=source.id..":"..request.attack_id
      if state.clock<(state.cooldowns[key] or -math.huge) then return fail(request,"ATTACK_COOLDOWN") end
      local weapon=is_player(source) and source.equipment.weapon or nil
      if weapon and weapon.durability~=nil and weapon.durability<=0 then return fail(request,"WEAPON_BROKEN") end
      state.attack_sequence=state.attack_sequence+1
      local id=state.run_id..":attack_"..state.attack_sequence
      state.attacks[id]={id=id,source_instance_id=source.id,attack_id=request.attack_id,
        definition=attack,started_at=state.clock,cancelled=false,hit_count=0}
      state.cooldowns[key]=state.clock+(attack.cooldownSec or 0)
      if weapon and weapon.durability~=nil then
        local weapon_definition=definitions[weapon.entity_id] or {}
        weapon.durability=math.max(0,weapon.durability-(weapon_definition.durabilityCostPerAttack or 0))
        changed(bag_for(source.id))
      end
      return result(request,true,nil,{attack_instance_id=id,attack_id=request.attack_id,source_instance_id=source.id})
    end)
  end
  function Combat:cancel_attack(request)
    return mutate("Combat.cancel",request,function()
      local error=validate(request,false)
      if error then return fail(request,error) end
      local attack=state.attacks[request.attack_instance_id]
      if not attack then return fail(request,"UNKNOWN_ATTACK_INSTANCE") end
      attack.cancelled=true
      return result(request,true,nil,{attack_instance_id=attack.id})
    end)
  end
  function Combat:try_apply_damage(request)
    return mutate("Combat.damage",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local attack=state.attacks[request.attack_instance_id]
      if not attack or attack.cancelled then return fail(request,"INVALID_ATTACK_INSTANCE") end
      local source,target=state.entities[attack.source_instance_id],state.entities[request.target_instance_id]
      if not source or not source.alive or not target or not target.alive then return fail(request,"TARGET_OR_SOURCE_NOT_ALIVE") end
      if source.id==target.id or (not combat_config.friendlyFire and is_player(source) and is_player(target)) then return fail(request,"INVALID_FACTION") end
      local definition=attack.definition
      local elapsed=state.clock-attack.started_at
      local window_start=definition.windupSec or 0
      local window_end=window_start+(definition.activeSec or 0.2)
      if elapsed<window_start or elapsed>=window_end then return fail(request,"OUTSIDE_HIT_WINDOW") end
      local tick=request.tick_index or 0
      if not finite(tick) or tick<0 or tick~=math.floor(tick) then return fail(request,"INVALID_TICK_INDEX") end
      if definition.damageMode~="periodic" and tick~=0 then return fail(request,"INVALID_SINGLE_TICK") end
      if definition.damageMode=="periodic" then
        local interval=definition.tickIntervalSec or 0
        if interval<(combat_config.minPeriodicTickSec or 0.2) then return fail(request,"INVALID_TICK_INTERVAL") end
        local due=(definition.firstTickDelaySec or interval)+tick*interval
        if elapsed<due then return fail(request,"TICK_NOT_DUE") end
      end
      local dedupe=attack.id..":"..target.id..":"..tick
      if state.damage_keys[dedupe] then return fail(request,"DUPLICATE_HIT") end
      if attack.hit_count>=(definition.maxTargets or 1) and definition.damageMode~="periodic" then return fail(request,"TARGET_LIMIT") end
      local evidence=request.hit_evidence
      if type(evidence)~="table" or not finite(evidence.distance_m) or evidence.distance_m<0 or evidence.angular_valid~=true then return fail(request,"INVALID_HIT_EVIDENCE") end
      local actual_distance=distance(position(source.id),position(target.id))
      if actual_distance==nil then return fail(request,"POSITION_UNAVAILABLE") end
      local range=definition.rangeM or 0
      if actual_distance>range or evidence.distance_m>range then return fail(request,"OUT_OF_RANGE") end
      if definition.requireLineOfSight~=false then
        if evidence.line_of_sight~=true then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
        local visible=los(position(source.id),position(target.id))
        if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
        if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
      end
      if state.clock<target.spawn_protect_until then return fail(request,"SPAWN_PROTECTED") end
      if state.clock-target.last_hit_at<(player_config.hitInvulnerabilitySec or 0.2) then return fail(request,"HIT_INVULNERABLE") end
      local target_definition=definitions[target.entity_id] or {}
      if target_definition.physicalDamageImmune and definition.damageType=="physical" then return fail(request,"IMMUNE") end
      local base=definition.damageHp or 0
      if not finite(base) or base<0 then return fail(request,"INVALID_DAMAGE_DEFINITION") end
      local damage=math.floor(math.max(0,base-target.armor_flat_hp)*(1-target.damage_reduction_ratio)+0.5)
      state.damage_keys[dedupe]=true
      attack.hit_count=attack.hit_count+1
      target.hp=math.max(0,target.hp-damage)
      if damage>0 then target.last_hit_at=state.clock end
      target.alive=target.hp>0
      if not target.alive and is_player(target) then state.pending_terminal="death" end
      if state.extract and state.extract.user_instance_id==target.id and damage>0 and session_config.extractionCancelOnDamage~=false then
        state.extract=nil
        state.phase="EXPLORE"
        state.toast="撤离因受击取消"
      end
      return result(request,true,nil,{damage_hp=damage,hp=target.hp,max_hp=target.max_hp,alive=target.alive,target_instance_id=target.id})
    end)
  end
  function Combat:try_heal(request)
    return mutate("Combat.heal",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local user=state.entities[request.user_instance_id]
      if not user or not user.alive then return fail(request,"USER_NOT_ALIVE") end
      if user.hp>=user.max_hp then return fail(request,"FULL_HEALTH") end
      local item,container,index=find_item(request.item_instance_id)
      if not item or not container or container.owner_id~=user.id then return fail(request,"ITEM_NOT_OWNED") end
      local definition=definitions[item.entity_id] or {}
      local effect=definition.effect or {}
      if effect.kind~="heal" or not finite(effect.amountHp) or effect.amountHp<=0 then return fail(request,"NOT_HEAL_ITEM") end
      local cooldown_key="heal:"..user.id..":"..item.entity_id
      if state.clock<(state.cooldowns[cooldown_key] or -math.huge) then return fail(request,"ITEM_COOLDOWN") end
      local healed=math.min(effect.amountHp,user.max_hp-user.hp)
      user.hp=user.hp+healed
      consume_item(item,container,index,1)
      state.cooldowns[cooldown_key]=state.clock+(definition.cooldownSec or 0)
      return result(request,true,nil,{healed_hp=healed,hp=user.hp,max_hp=user.max_hp,
        item_instance_id=item.id,item_remaining=item.count})
    end)
  end

  function Inventory:_create_container(request)
    if type(request)~="table" or not text(request.id) then return fail(request,"INVALID_CONTAINER") end
    if state.containers[request.id] then return fail(request,"CONTAINER_EXISTS") end
    local slots=request.slots or inventory_config.bagSlots or 12
    if not positive_integer(slots) then return fail(request,"INVALID_CAPACITY") end
    state.containers[request.id]={id=request.id,owner_id=request.owner_id,slots=slots,items={},version=0,position_m=copy(request.position_m)}
    return result(request,true,nil,copy(state.containers[request.id]))
  end
  function Inventory:_add_item(request)
    if type(request)~="table" then return fail(request,"INVALID_REQUEST") end
    local container=state.containers[request.container_id]
    local definition=definitions[request.entity_id]
    if not container or not definition or not text(request.id) or not positive_integer(request.count or 1) then return fail(request,"INVALID_ITEM") end
    if find_item(request.id) then return fail(request,"ITEM_EXISTS") end
    local count=request.count or 1
    if count>(definition.maxStack or 1) then return fail(request,"STACK_OVERFLOW") end
    local item={id=request.id,entity_id=request.entity_id,count=count}
    if definition.durabilityMax and definition.durabilityMax>0 then item.durability=definition.durabilityMax end
    if request.equip_slot then
      local owner=state.entities[container.owner_id]
      if not owner or (request.equip_slot~="weapon" and request.equip_slot~="tool") or owner.equipment[request.equip_slot] then return fail(request,"INVALID_SLOT") end
      owner.equipment[request.equip_slot]=item
    else
      if #container.items>=container.slots then return fail(request,"BAG_FULL") end
      table.insert(container.items,item)
    end
    changed(container)
    return result(request,true,nil,{item=item,version=container.version})
  end
  function Inventory:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    local container=request.container_id and state.containers[request.container_id] or bag_for(request.owner_instance_id)
    if not container then return fail(request,"UNKNOWN_CONTAINER") end
    return result(request,true,nil,snapshot(container,request.owner_instance_id))
  end
  function Inventory:try_transfer(request)
    return mutate("Inventory.transfer",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local from,to=state.containers[request.from_id],state.containers[request.to_id]
      if not from or not to or from==to then return fail(request,"INVALID_CONTAINERS") end
      local versions=request.expected_versions
      if type(versions)~="table" then return fail(request,"VERSION_REQUIRED") end
      if (versions.from or versions[from.id])~=from.version or (versions.to or versions[to.id])~=to.version then return fail(request,"VERSION_CONFLICT") end
      local actor_id=request.user_instance_id or request.owner_instance_id
      if not actor_id then
        if state.entities[to.owner_id] and is_player(state.entities[to.owner_id]) then actor_id=to.owner_id
        elseif state.entities[from.owner_id] and is_player(state.entities[from.owner_id]) then actor_id=from.owner_id end
      end
      local actor=state.entities[actor_id]
      if not actor or not actor.alive or (from.owner_id~=actor.id and to.owner_id~=actor.id) then return fail(request,"NOT_OWNER") end
      local external=from.owner_id~=actor.id and from or (to.owner_id~=actor.id and to or nil)
      if external then
        local external_position=external.position_m or position(external.owner_id)
        local d=distance(position(actor.id),external_position)
        if d==nil or d>(interaction_config.maxDistanceM or 2.2) then return fail(request,"INTERACTION_OUT_OF_RANGE") end
        if interaction_config.requireLineOfSight~=false then
          local visible=los(position(actor.id),external_position)
          if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
          if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
        end
      end
      local item,container,index=find_item(request.item_instance_id)
      local count=request.count
      if not item or container~=from or not positive_integer(count) or count>item.count then return fail(request,"INVALID_ITEM_COUNT") end
      local definition=definitions[item.entity_id] or {}
      local max_stack=definition.maxStack or 1
      local available=0
      for _,existing in ipairs(to.items) do
        if existing.entity_id==item.entity_id and max_stack>1 then available=available+math.max(0,max_stack-existing.count) end
      end
      local new_slots=math.ceil(math.max(0,count-available)/max_stack)
      if #to.items+new_slots>to.slots then return fail(request,"BAG_FULL") end
      local remaining=count
      for _,existing in ipairs(to.items) do
        if existing.entity_id==item.entity_id and max_stack>1 then
          local moved=math.min(remaining,max_stack-existing.count)
          existing.count=existing.count+moved
          remaining=remaining-moved
        end
      end
      while remaining>0 do
        local moved=math.min(remaining,max_stack)
        local new_item=copy(item)
        if count==item.count and moved==count then new_item.id=item.id
        else state.item_sequence=state.item_sequence+1;new_item.id=state.run_id..":item_"..state.item_sequence end
        new_item.count=moved
        table.insert(to.items,new_item)
        remaining=remaining-moved
      end
      item.count=item.count-count
      if item.count==0 then table.remove(from.items,index) end
      changed(from)
      changed(to)
      return result(request,true,nil,{count=count,from=snapshot(from),to=snapshot(to),inventory_version=state.inventory_version})
    end)
  end
  function Inventory:try_equip(request)
    return mutate("Inventory.equip",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local owner=state.entities[request.owner_instance_id]
      local slot=request.slot_id
      if not owner or not owner.alive or (slot~="weapon" and slot~="tool") then return fail(request,"INVALID_SLOT") end
      local bag=bag_for(owner.id)
      local item,container,index=find_item(request.item_instance_id)
      if not item or container~=bag then return fail(request,"ITEM_NOT_OWNED") end
      local definition=definitions[item.entity_id] or {}
      if definition.equipmentSlot~=slot then return fail(request,"SLOT_MISMATCH") end
      if item.count~=1 then return fail(request,"INVALID_EQUIP_STACK") end
      local previous=owner.equipment[slot]
      table.remove(bag.items,index)
      if previous then table.insert(bag.items,previous) end
      owner.equipment[slot]=item
      changed(bag)
      return result(request,true,nil,snapshot(bag,owner.id))
    end)
  end
  function Inventory:try_consume(request)
    -- Healing already consumed atomically. An authorised receipt acknowledges
    -- that commit; it never spends a second item. UI cannot pre-spend.
    return mutate("Inventory.consume",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local receipt=state.requests["Combat.heal:"..tostring(request.effect_request_id)]
      if not receipt or not receipt.ok or receipt.data.item_instance_id~=request.item_instance_id then
        return fail(request,"EFFECT_COMMIT_REQUIRED")
      end
      return result(request,true,"ALREADY_COMMITTED",{item_instance_id=request.item_instance_id,
        item_remaining=receipt.data.item_remaining,effect_request_id=request.effect_request_id})
    end)
  end

  local function terminal_reason(requested)
    local player=state.player_id and state.entities[state.player_id]
    if state.pending_terminal=="death" or (player and not player.alive) then return "death" end
    if state.clock>=(session_config.roundDurationSec or 600) then return "timeout" end
    local extract=state.extract
    if requested=="extraction" and extract and state.clock-extract.started_at>=(session_config.extractionHoldSec or 3) then
      local d=distance(position(extract.user_instance_id),position(extract.exit_instance_id))
      local user=state.entities[extract.user_instance_id]
      if user and user.alive and d and d<=(interaction_config.maxDistanceM or 2.2)
        and not (session_config.extractionCancelOnDamage~=false and user.last_hit_at>extract.last_hit_at) then
        return "extraction"
      end
    end
    if requested=="quit" then return "quit" end
  end
  local function finish(reason,request)
    if state.result then return result(request,true,"ALREADY_FINISHED",state.result) end
    local items,value={},0
    local bag=state.player_id and bag_for(state.player_id)
    if reason=="extraction" and bag then
      for _,item in ipairs(bag.items) do
        table.insert(items,copy(item))
        value=value+((definitions[item.entity_id] or {}).sellValue or 0)*item.count
      end
    end
    state.result={result_id=state.run_id..":result",run_id=state.run_id,reason=reason,
      success=reason=="extraction",loot_value=value,items=items,clock=state.clock}
    state.phase="FINISHED"
    state.extract=nil
    state.pending_terminal=nil
    return result(request,true,nil,state.result)
  end
  function Session:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    return result(request,true,nil,{run_id=state.run_id,phase=state.phase,clock=state.clock,
      remaining_sec=math.max(0,(session_config.roundDurationSec or 600)-state.clock),
      extract=state.extract,result=state.result,toast=state.toast})
  end
  function Session:try_start(request)
    return mutate("Session.start",request,function()
      if state.phase~="LOBBY" and state.phase~="FINISHED" then return fail(request,"ROUND_ALREADY_ACTIVE") end
      if request.run_id~=nil and request.run_id~=state.run_id then return fail(request,"STALE_RUN") end
      state.run_sequence=state.run_sequence+1
      local id="run_"..state.run_sequence
      state:reset_run(id)
      return result(request,true,nil,{run_id=id,phase=state.phase,clock=0,map_entity_id=request.map_entity_id})
    end)
  end
  function Session:try_extract(request)
    return mutate("Session.extract",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local user=state.entities[request.user_instance_id]
      if not user or not user.alive then return fail(request,"USER_NOT_ALIVE") end
      local d=distance(position(user.id),position(request.exit_instance_id))
      if d==nil or d>(interaction_config.maxDistanceM or 2.2) then return fail(request,"EXIT_OUT_OF_RANGE") end
      if interaction_config.requireLineOfSight~=false then
        local visible=los(position(user.id),position(request.exit_instance_id))
        if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
        if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
      end
      if state.extract then return fail(request,"ALREADY_EXTRACTING") end
      if session_config.quotaEnforced then
        local total=0
        local bag=bag_for(user.id)
        for _,item in ipairs(bag and bag.items or {}) do
          local definition=definitions[item.entity_id] or {}
          if definition.countsForQuota then total=total+(definition.sellValue or 0)*item.count end
        end
        if total<(session_config.sampleQuotaValue or 1000) then return fail(request,"QUOTA_NOT_MET") end
      end
      state.extract={user_instance_id=user.id,exit_instance_id=request.exit_instance_id,
        started_at=state.clock,last_hit_at=user.last_hit_at}
      state.phase="EXTRACTING"
      return result(request,true,nil,{phase=state.phase,extract=state.extract,hold_sec=session_config.extractionHoldSec or 3})
    end)
  end
  function Session:try_finish(request)
    return mutate("Session.finish",request,function()
      local error=validate(request,false)
      if error then return fail(request,error) end
      if state.result then return result(request,true,"ALREADY_FINISHED",state.result) end
      if not active() then return fail(request,"ROUND_NOT_ACTIVE") end
      local reason=terminal_reason(request.terminal_reason)
      if not reason then return fail(request,"TERMINAL_CONDITION_NOT_MET") end
      return finish(reason,request)
    end)
  end
  function Session:tick(dt)
    if not finite(dt) or dt<0 then return fail(nil,"INVALID_DT") end
    if not active() then return result(nil,true,nil,{phase=state.phase,result=state.result}) end
    state.clock=state.clock+dt
    local forced=terminal_reason(nil)
    if forced then return finish(forced,nil) end
    local extract=state.extract
    if extract then
      local user=state.entities[extract.user_instance_id]
      local d=distance(position(extract.user_instance_id),position(extract.exit_instance_id))
      local left=d==nil or d>(interaction_config.maxDistanceM or 2.2)
      local hit=user and user.last_hit_at>extract.last_hit_at
      if (left and session_config.extractionCancelOnLeave~=false) or (hit and session_config.extractionCancelOnDamage~=false) then
        state.extract=nil
        state.phase="EXPLORE"
        state.toast=left and "离开出口，撤离取消" or "撤离因受击取消"
      elseif state.clock-extract.started_at>=(session_config.extractionHoldSec or 3) then
        return finish("extraction",nil)
      end
    end
    return result(nil,true,nil,{phase=state.phase,clock=state.clock,extract=state.extract})
  end

  return {Characters=Characters,Combat=Combat,Inventory=Inventory,Session=Session}
end

return Services

end
module_loaders["gameplay.core.spatial"] = function()
  local require = ProjectRequire
-- Geometry for the authored whitebox. No SDK globals and no object AI.
local Spatial={}
function Spatial.distance(a,b)local x,z=a.x-b.x,a.z-b.z;return math.sqrt(x*x+z*z)end
function Spatial.blocked(a,b,walls,padding)
 padding=padding or 0
 for _,w in ipairs(walls)do
  local lo,hi=0,1
  local valid=true
  for _,axis in ipairs({'x','z'})do
   local av,bv=a[axis],b[axis];local d=bv-av
   local size=axis=='x'and w.sx or w.sz
   local mn,mx=w[axis]-size/2-padding,w[axis]+size/2+padding
   if math.abs(d)<0.00001 then if av<mn or av>mx then valid=false end
   else local t1,t2=(mn-av)/d,(mx-av)/d;if t1>t2 then t1,t2=t2,t1 end;lo=math.max(lo,t1);hi=math.min(hi,t2);if lo>hi then valid=false end end
  end
  if valid and lo<=hi and hi>=0 and lo<=1 then return true end
 end
 return false
end
function Spatial.path(a,b,map,radius)
 radius=radius or 0.35
 if not Spatial.blocked(a,b,map.walls,radius)then return {{x=b.x,y=a.y,z=b.z}}end
 local function key(x,z)return x..':'..z end
 local function walkable(x,z)
  local bounds=map.bounds
  if x<bounds.min_x+radius or x>bounds.max_x-radius or z<bounds.min_z+radius or z>bounds.max_z-radius then return false end
  return not Spatial.blocked({x=x,y=0,z=z},{x=x,y=0,z=z},map.walls,radius)
 end
 local sx,sz=math.floor(a.x+0.5),math.floor(a.z+0.5)
 local tx,tz=math.floor(b.x+0.5),math.floor(b.z+0.5)
 if not walkable(tx,tz)then return nil,'NO_PATH'end
 local q,head,parent,seen={{x=sx,z=sz}},1,{},{};seen[key(sx,sz)]=true
 local endkey
 while head<=#q and head<1700 do
  local p=q[head];head=head+1;local k=key(p.x,p.z)
  if p.x==tx and p.z==tz then endkey=k;break end
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do
   local x,z=p.x+d[1],p.z+d[2];local nk=key(x,z)
   if not seen[nk]then
    seen[nk]=true
    if walkable(x,z)and not Spatial.blocked({x=p.x,z=p.z},{x=x,z=z},map.walls,radius)then parent[nk]=k;q[#q+1]={x=x,z=z}end
   end
  end
 end
 if not endkey then return nil,'NO_PATH'end
 local reverse,k={},endkey
 while k~=key(sx,sz)do
  local x,z=k:match('([^:]+):([^:]+)');reverse[#reverse+1]={x=tonumber(x),y=a.y,z=tonumber(z)};k=parent[k];if not k then return nil,'NO_PATH'end
 end
 local out={};for i=#reverse,1,-1 do out[#out+1]=reverse[i]end
 if not Spatial.blocked(out[#out]or a,b,map.walls,radius)then out[#out+1]={x=b.x,y=a.y,z=b.z}end
 return out
end
return Spatial

end
module_loaders["gameplay.core.service_api"] = function()
  local require = ProjectRequire
-- Project facade method names. All methods require implementation in the Adapter.
return {
  ["schemaVersion"] = "0.2.0",
  ["operations"] = {
    ["Characters"] = {
      "read_snapshot",
      "spawn",
      "apply_modifier",
      "remove_modifier",
    },
    ["Combat"] = {
      "try_begin_attack",
      "try_apply_damage",
      "try_heal",
      "cancel_attack",
    },
    ["Inventory"] = {
      "read_snapshot",
      "try_transfer",
      "try_equip",
      "try_consume",
    },
    ["Movement"] = {
      "move_to",
      "stop",
      "read_position",
    },
    ["Navigation"] = {
      "find_path",
      "cancel_query",
    },
    ["Interaction"] = {
      "query_target",
      "try_begin",
      "cancel",
    },
    ["Session"] = {
      "read_snapshot",
      "try_start",
      "try_extract",
      "try_finish",
    },
    ["Assets"] = {
      "resolve",
      "instantiate",
      "play_clip",
      "destroy",
      "resolve_socket",
    },
    ["UI"] = {
      "open_view",
      "close_view",
      "publish_snapshot",
      "subscribe",
      "unsubscribe",
    },
  },
}

end
module_loaders["gameplay.adapters.zaizai.adapter"] = function()
  local require = ProjectRequire
-- Verified Unity / Douyin bridge. SDK code stays out of object controllers.
local State=require('gameplay.core.state')
local Services=require('gameplay.core.services')
local Spatial=require('gameplay.core.spatial')
local Api=require('gameplay.core.service_api')
local Adapter={};Adapter.__index=Adapter
local function result(ok,reason,request,data)return {ok=ok,reason=reason or(ok and 'OK'or 'UNSUPPORTED'),request_id=request and request.request_id,data=data or{}}end
local function plain(v)return {x=v.x,y=v.y,z=v.z}end
local function copy(v)local t={};for k,x in pairs(v or{})do t[k]=type(x)=='table'and copy(x)or x end;return t end
function Adapter.new(options)
 options=options or{}
 local self=setmetatable({is_ready=false,services={},nodes={},native_nodes={},native_baselines={},feedback={},subscriptions={},dt=0.02,options=options},Adapter)
 self.config=options.config;self.definitions=options.definitions or{};self.map=options.map;self.registry=options.registry
 if not self.config or not self.map or not CS or not CS.UnityEngine then return self end
 self.U=CS.UnityEngine;local U=self.U
 self.state=State.new(self.config)
 self.runtime_root=U.GameObject('demo_runtime');if options.host then self.runtime_root.transform:SetParent(options.host.transform,false)end
 local spatial={distance=Spatial.distance,los=function(a,b)return not Spatial.blocked(a,b,self.map.walls,0)end,position=function(id)return self:position(id)end}
 local shared=Services.new(self.state,self.config,self.definitions,spatial)
 for name,methods in pairs(Api.operations)do
  self.services[name]=shared[name]or{}
  for _,method in ipairs(methods)do if not self.services[name][method]then self.services[name][method]=function(_,request)return result(false,'UNSUPPORTED',request)end end end
 end
 self:_install_engine_services()
 self.is_ready=true
 return self
end
function Adapter:actor()return CS.DouyinActorService.GetLocalActor()end
function Adapter:vector(p)return self.U.Vector3(p.x,p.y,p.z)end
function Adapter:position(id)
 local go=self.nodes[id]
 if id=='player_local'then local a=self:actor();if a then return plain(a.position)end end
 if go then return plain(go.transform.position)end
 local e=self.state.entities[id];return e and e.position_m or nil
end
function Adapter:forward(id)
 local go=self.nodes[id]
 if id=='player_local'then local a=self:actor();if a then go=a.gameObject end end
 if go then local f=go.transform.forward;return {x=f.x,y=0,z=f.z}end
 local e=self.state.entities[id];return e and e.forward_m or{x=0,y=0,z=1}
end
function Adapter:sense(request)
 local a,b=self:position(request.user_instance_id),self:position(request.target_instance_id)
 if not a or not b then return result(false,'MISSING_ENTITY',request)end
 local source=self.state.entities[request.user_instance_id]
 local def=source and self.definitions[source.entity_id]or{}
 local mode=request.mode or'interaction';local range,angle
 if mode=='perception'then
  local p=def.sense or def.perception or def.senses or{}
  range=p.rangeM or p.viewDistanceM or def.viewDistanceM or def.visionRangeM or 7
  angle=p.fullAngleDeg or p.fovDeg or def.fovDeg or def.visionAngleDeg or 100
 elseif mode=='weapon'then range=self.definitions.weapon_shovel.attack.rangeM;angle=self.definitions.weapon_shovel.attack.arcDeg
 else range=self.config.interaction.maxDistanceM;angle=360 end
 local dist=Spatial.distance(a,b);local f=self:forward(request.user_instance_id)
 local angular=dist<0.001 or((f.x*(b.x-a.x)+f.z*(b.z-a.z))/dist>=math.cos(angle*0.5*math.pi/180))
 if angle>=359 then angular=true end
 local los=not Spatial.blocked(a,b,self.map.walls,0)
 return result(true,'OK',request,{visible=dist<=range and angular and los,in_range=dist<=range,angular_valid=angular,line_of_sight=los,distance_m=dist,range_m=range,full_angle_deg=angle})
end
function Adapter:_install_engine_services()
 local self=self;local U=self.U
 local movement=self.services.Movement
 function movement:read_position(r)
  local p=self._adapter:position(r.instance_id);if not p then return result(false,'MISSING_ENTITY',r)end
  return result(true,'OK',r,{position_m=p,forward_m=self._adapter:forward(r.instance_id)})
 end
 function movement:move_to(r)
  local a=self._adapter;local go=a.nodes[r.instance_id];if not go or r.instance_id=='player_local'then return result(false,'UNSUPPORTED',r)end
  local p=a:position(r.instance_id);local target=r.goal_m;if not target then return result(false,'INVALID_GOAL',r)end
  local distance=Spatial.distance(p,target);if distance<0.01 then return result(true,'ARRIVED',r,{position_m=p})end
  local amount=math.min(distance,math.max(0,r.speed_mps or 0)*a.dt)
  local q={x=p.x+(target.x-p.x)*amount/distance,y=p.y,z=p.z+(target.z-p.z)*amount/distance}
  if Spatial.blocked(p,q,a.map.walls,0.35)then return result(false,'BLOCKED',r)end
  go.transform.position=a:vector(q);go.transform.rotation=U.Quaternion.LookRotation(U.Vector3(target.x-p.x,0,target.z-p.z))
  local e=a.state.entities[r.instance_id];if e then e.position_m=q;e.forward_m=a:forward(r.instance_id)end
  return result(true,'OK',r,{position_m=q})
 end
 function movement:stop(r)return result(true,'OK',r)end
 movement._adapter=self
 local navigation=self.services.Navigation
 function navigation:find_path(r)
  local a=self._adapter;local from=r.from_m or a:position(r.instance_id)
  if not from or not r.to_m then return result(false,'INVALID_GOAL',r)end
  local path,reason=Spatial.path(from,r.to_m,a.map,0.35)
  return result(path~=nil,reason or'OK',r,{waypoints=path or{},task_id=r.request_id})
 end
 function navigation:cancel_query(r)return result(true,'OK',r)end
 navigation._adapter=self
 local interaction=self.services.Interaction
 function interaction:query_target(r)return self._adapter:sense(r)end
 function interaction:try_begin(r)
  local a=self._adapter
  if a.state.phase~='EXPLORE'then return result(false,'WRONG_PHASE',r)end
  local sensed=a:sense(r)
  if not sensed.ok or not sensed.data.visible then return result(false,'OUT_OF_RANGE_OR_BLOCKED',r,sensed.data)end
  return result(true,'OK',r,{target_instance_id=r.target_instance_id,container_id=r.target_instance_id=='chest_demo'and 'chest_demo'or nil})
 end
 function interaction:cancel(r)return result(true,'OK',r)end
 interaction._adapter=self
 local assets=self.services.Assets
 function assets:resolve(r)
  local a=self._adapter
  for _,e in ipairs(a.registry.entries)do for _,resource in ipairs(e.resources)do if resource.id==r.resource_id then return result(false,'PLANNED_MODEL_NOT_IMPORTED',r,{path=resource.path})end end end
  return result(false,'UNKNOWN_RESOURCE',r)
 end
 function assets:instantiate(r)
  local a=self._adapter;local go
  if r.entity_id=='player_default'then local actor=a:actor();go=actor and actor.gameObject
  else local name=r.node_name or r.entity_id;go=a.native_nodes[name]or U.GameObject.Find(name);if go then a.native_nodes[name]=go end end
  if not go then return result(false,'NATIVE_PROXY_MISSING',r,{entity_id=r.entity_id})end
  a.nodes[r.instance_id]=go
  local renderer=go:GetComponent(typeof(U.Renderer));local mat=renderer and renderer.material;local color=mat and mat.color or U.Color(0.95,0.48,0.16,1)
  local key=r.node_name or r.entity_id;local base=a.native_baselines[key]
  if not base then base={scale=plain(go.transform.localScale),color={r=color.r,g=color.g,b=color.b,a=color.a}};a.native_baselines[key]=base end
  go.transform.localScale=a:vector(base.scale);if mat then mat.color=U.Color(base.color.r,base.color.g,base.color.b,base.color.a)end
  a.feedback[r.instance_id]={base_scale=copy(base.scale),base_color=copy(base.color),clip='native_idle',at=a.state.clock,material=mat}
  if r.position_m then
   if r.entity_id=='player_default'then local actor=a:actor();actor:Teleport(a:vector(r.position_m),U.Quaternion.identity)
   else go.transform.position=a:vector(r.position_m);go.transform.rotation=U.Quaternion.identity end
  end
  go:SetActive(true)
  return result(true,'NATIVE_PROXY',r,{native_name=go.name,instance_id=r.instance_id})
 end
 function assets:play_clip(r)
  local a=self._adapter;local f=a.feedback[r.instance_id]
  if not f then return result(false,'MISSING_ENTITY',r)end
  if r.native_action=='chest_open'or r.native_action=='chest_close'then
   local lid=U.GameObject.Find('chest_basic_lid')
   if lid then lid.transform.rotation=U.Quaternion.Euler(r.native_action=='chest_open'and -80 or 0,0,0)end
   f.clip='native_idle';return result(true,'NATIVE_DEMO_FEEDBACK',r,{skeletal_animation=false,native_action=r.native_action})
  end
  if not tostring(r.clip_id):match('^native_')then return result(false,'PLANNED_ANIMATION',r)end
  f.clip=r.clip_id;f.at=a.state.clock
  return result(true,'NATIVE_DEMO_FEEDBACK',r,{clip_id=r.clip_id,rigged_animation=false})
 end
 function assets:resolve_socket(r)return result(false,'UNSUPPORTED',r,{reason='Native character bone contract remains unverified'})end
 function assets:destroy(r)
  local a=self._adapter;local go=a.nodes[r.instance_id]
  if go and r.instance_id~='player_local'then go:SetActive(false)end
  a.nodes[r.instance_id]=nil;a.feedback[r.instance_id]=nil
  return result(true,'OK',r)
 end
 assets._adapter=self
 local ui=self.services.UI
 function ui:open_view(r)
  local a=self._adapter;a.state.ui_view=r.view_id
  if a.ui then a.ui:open(r.view_id,r)end
  return result(true,'OK',r)
 end
 function ui:close_view(r)
  local a=self._adapter;a.state.ui_view=nil;if a.ui then a.ui:close()end
  return result(true,'OK',r)
 end
 function ui:publish_snapshot(r)if self._adapter.ui then self._adapter.ui:update_snapshot(r)end;return result(true,'OK',r)end
 function ui:subscribe(r)local a=self._adapter;local id=r.request_id or tostring(r.callback);a.subscriptions[id]=r;return result(true,'OK',r,{subscription_id=id})end
 function ui:unsubscribe(r)self._adapter.subscriptions[r.subscription_id]=nil;return result(true,'OK',r)end
 ui._adapter=self
end
function Adapter:tick(dt)
 local U=self.U
 self.dt=math.min(dt,0.08)
 local a=self:actor()
 if a then
  if not self.collider_checked then
   self.collider_checked=true
   local ok,value=pcall(function()local go=a.gameObject;local co=go:GetComponent(typeof(U.CharacterController))or go:GetComponent(typeof(U.CapsuleCollider));if not co then return nil end;co.radius=self.config.player.colliderRadiusM;co.height=self.config.player.colliderHeightM;co.center=U.Vector3(0,self.config.player.colliderCenterY_M,0);return {radius=co.radius,height=co.height,center_y=co.center.y}end)
   self.collider_apply_ok=ok and value~=nil;self.collider_readback=ok and value or nil
  end
  local e=self.state.entities.player_local
  if e then e.position_m=plain(a.position);e.forward_m=self:forward('player_local')end
  if self.original_speed==nil then pcall(function()self.original_speed=tonumber(a.speed)end)end
  local desired=self.config.player.walkSpeedMps
  if self.U.Input.GetKey(self.U.KeyCode.LeftShift)then desired=self.config.player.sprintSpeedMps end
  if self.U.Input.GetKey(self.U.KeyCode.LeftControl)then desired=self.config.player.crouchSpeedMps end
  local ok=pcall(function()a.speed=desired end)
  self.speed_write_ok=ok
  if ok then pcall(function()self.speed_readback=tonumber(a.speed)end)end
  a:Immobilize(self.state.phase=='FINISHED'or self.state.ui_view~=nil)
 end
 for id,f in pairs(self.feedback)do
  local go=self.nodes[id]
  if go and id~='player_local'then
   local age=self.state.clock-f.at;local clip=f.clip
   local scale=copy(f.base_scale);local bc=f.base_color;local color=U.Color(bc.r,bc.g,bc.b,bc.a)
   if clip=='native_death'then go:SetActive(false)
   else
    go:SetActive(true)
    if clip=='native_windup'then local k=1+0.12*math.sin(age*17);scale.x=scale.x*k;scale.z=scale.z*k;color=U.Color(1,0.25,0.12,1)
    elseif clip=='native_attack'then color=U.Color(1,0.12,0.06,1)
    elseif clip=='native_hit'or clip=='native_hurt'then if age<0.25 then color=U.Color(1,0.95,0.72,1)end end
    go.transform.localScale=self:vector(scale)
    if f.material then f.material.color=color end
   end
  end
 end
end
function Adapter:dispose()
 local actor=self:actor();if actor then actor:Immobilize(false);if self.original_speed then pcall(function()actor.speed=self.original_speed end)end end
 for id,f in pairs(self.feedback)do local go=self.nodes[id];if go and id~='player_local'then go:SetActive(true);go.transform.localScale=self:vector(f.base_scale)end end
 self.subscriptions={};if self.runtime_root then self.U.Object.Destroy(self.runtime_root)end
 self.is_ready=false
end
return Adapter

end
module_loaders["gameplay.core.service_contracts"] = function()
  local require = ProjectRequire
-- Proposed service names; SDK mappings are not implemented.
return {
  "Characters",
  "Combat",
  "Inventory",
  "Movement",
  "Navigation",
  "Interaction",
  "Session",
  "Assets",
  "UI",
}

end
module_loaders["gameplay.bootstrap"] = function()
  local require = ProjectRequire
local Config = require("gameplay.core.config")
local Registry = require("gameplay.registry")
local Factories = require("gameplay.package_factories")
local Services = require("gameplay.core.service_contracts")
local ServiceApi = require("gameplay.core.service_api")
local DefaultAdapter = require("gameplay.adapters.zaizai.adapter")
local Bootstrap = {}
function Bootstrap.create(adapter)
  adapter = adapter or DefaultAdapter.new()
  local context = {config=Config, registry=Registry, services=adapter.services or {},
    is_ready=adapter.is_ready == true, adapter=adapter}
  for _, name in ipairs(Services) do
    local service = context.services[name]
    if type(service) ~= "table" then context.is_ready=false end
    for _, operation in ipairs(ServiceApi.operations[name]) do
      if type(service) ~= "table" or type(service[operation]) ~= "function" then context.is_ready=false end
    end
  end
  function context:new_entity(entity_id, instance)
    if not self.is_ready then return nil, "ADAPTER_NOT_READY" end
    local factory = Factories[entity_id]
    if not factory then return nil, "UNKNOWN_ENTITY" end
    return factory.controller.new(self, instance)
  end
  return context
end
return Bootstrap

end
module_loaders["gameplay.systems.match.controller"] = function()
  local require = ProjectRequire
-- Local single-player start flow. This does not implement online matchmaking.
local Match={}
Match.__index=Match
function Match.new(context)
  assert(context and context.services and context.services.Session,"Session required")
  return setmetatable({context=context,closed=false,sequence=0},Match)
end
function Match:start()
  if self.closed then return {ok=false,reason="CLOSED",data={}} end
  self.sequence=self.sequence+1
  local state=self.context.state
  local request_id
  if type(self.context.next_request_id)=="function" then
    request_id=self.context:next_request_id("match_start")
  else
    request_id="match_start_"..tostring(state and state.run_sequence+1 or 0).."_"..self.sequence
  end
  return self.context.services.Session:try_start({
    request_id=request_id,run_id=state and state.run_id or nil,
    map_entity_id=self.context.map_entity_id or "map_demo"})
end
function Match:close() self.closed=true end
return Match

end
module_loaders["gameplay.systems.round_setup.controller"] = function()
  local require = ProjectRequire
-- Program-owned spawn orchestration. No object-specific AI.
local Controller={};Controller.__index=Controller
function Controller.new(context)return setmetatable({context=context,objects={}},Controller)end
function Controller:request(prefix,fields)fields=fields or{};fields.run_id=self.context.state.run_id;fields.request_id=self.context:next_request_id(prefix);return fields end
function Controller:spawn(entity_id,instance_id,position,node_name,extra)
 local ctx=self.context
 local spawned=ctx.services.Characters:spawn(self:request('spawn_'..instance_id,{entity_id=entity_id,instance_id=instance_id,position_m=position}))
 if not spawned.ok then error('Spawn '..instance_id..': '..tostring(spawned.reason))end
 local asset=ctx.services.Assets:instantiate(self:request('asset_'..instance_id,{entity_id=entity_id,instance_id=instance_id,node_name=node_name,position_m=position}))
 if not asset.ok then error('Asset '..instance_id..': '..tostring(asset.reason))end
 local instance=extra or{};instance.id=instance_id;instance.position_m=position
 local obj,reason=ctx:new_entity(entity_id,instance);if not obj then error(reason)end
 local started,why=obj:start();if not started then error('Start '..instance_id..': '..tostring(why))end
 self.objects[instance_id]=obj
 return obj
end
function Controller:start(map)
 local ctx=self.context;local inv=ctx.services.Inventory
 self.objects={}
 local player=self:spawn('player_default','player_local',map.spawn,'player_default')
 local monster=self:spawn('monster_cube','monster_cube_1',map.monsterSpawn,'monster_cube',{route=map.patrolRoute})
 local chest=self:spawn('chest_basic','chest_demo',map.chest,'chest_basic',{container_id='chest_demo'})
 -- Exit is a scene marker. Global extraction rules live in Session.
 ctx.services.Characters:spawn(self:request('spawn_exit',{entity_id='gate_exit',instance_id='exit_demo',position_m=map.exit}))
 ctx.services.Assets:instantiate(self:request('asset_exit',{entity_id='gate_exit',instance_id='exit_demo',node_name='gate_exit',position_m=map.exit}))
 inv:_create_container({id='chest_demo',owner_id='chest_demo',slots=8,position_m=map.chest})
 inv:_add_item({container_id='chest_demo',id='treasure_demo',entity_id='item_treasure',count=1})
 inv:_add_item({container_id='chest_demo',id='heal_demo',entity_id='item_heal_small',count=2})
 inv:_add_item({container_id='bag_player_local',id='shovel_local',entity_id='weapon_shovel',count=1})
 local equip=inv:try_equip(self:request('equip_shovel',{owner_instance_id='player_local',item_instance_id='shovel_local',slot_id='weapon'}));if not equip.ok then error(equip.reason)end
 local shovel=ctx:new_entity('weapon_shovel',{id='shovel_local',owner_instance_id='player_local'});assert(shovel:start())
 local heal=ctx:new_entity('item_heal_small',{id='heal_handler',owner_instance_id='player_local'});assert(heal:start())
 self.objects.shovel=shovel;self.objects.heal=heal
 return {player=player,monster=monster,chest=chest,shovel=shovel,heal=heal}
end
function Controller:dispose()
 for _,obj in pairs(self.objects)do if obj.dispose then obj:dispose()end end
 self.objects={}
end
return Controller

end
module_loaders["gameplay.systems.settlement.controller"] = function()
  local require = ProjectRequire
-- Tick after object combat updates so death > timeout > extraction arbitration.
local Settlement={}
Settlement.__index=Settlement
function Settlement.new(context)
  assert(context and context.services and context.services.Session,"Session required")
  return setmetatable({context=context,closed=false},Settlement)
end
function Settlement:update(dt)
  if self.closed then return {ok=false,reason="CLOSED",data={}} end
  return self.context.services.Session:tick(dt)
end
function Settlement:close() self.closed=true end
return Settlement

end
module_loaders["gameplay.systems.inventory_meta.controller"] = function()
  local require = ProjectRequire
-- Program-owned inventory use dispatch; object behavior arrives by dependency injection.
local Controller={}
Controller.__index=Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
function Controller.new(context,objects)
  assert(type(context)=="table","context required")
  return setmetatable({context=context,objects=objects or {},started=false,disposed=false},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED"end
  if not self.context.services.Inventory then return false,"MISSING_SERVICE:Inventory"end
  self.started=true;return true
end
function Controller:read_bag(owner_id)
  return self.context.services.Inventory:read_snapshot(self:request("bag_read",{owner_instance_id=owner_id or "player_local"}))
end
function Controller:read_container(container_id)
  return self.context.services.Inventory:read_snapshot(self:request("container_read",{container_id=container_id}))
end
function Controller:use_item(item_id)
  local id=self.context:next_request_id("inventory_use")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  local snapshot=self:read_bag()
  if not snapshot.ok then return snapshot end
  local item
  for _,entry in ipairs(snapshot.data.bag.items or {})do
    if entry.id==item_id and entry.count>0 then item=entry;break end
  end
  if not item then return result(false,"ITEM_NOT_OWNED",id)end
  if item.entity_id=="item_heal_small"and self.objects.heal then
    return self.objects.heal:use({request_id=id,user_instance_id="player_local",item_instance_id=item_id})
  end
  return result(false,"NO_USE_HANDLER",id,{entity_id=item.entity_id})
end
function Controller:update(dt)
  -- Injected object controllers are updated by the round driver, not twice here.
end
function Controller:dispose()
  if self.disposed then return end
  self.started=false;self.disposed=true;self.objects={}
end
return Controller

end
module_loaders["gameplay.demo"] = function()
  local require = ProjectRequire
-- Native whitebox acceptance Demo. Assembly belongs to program; object logic stays in packages.
local Config=require('gameplay.core.config')
local Registry=require('gameplay.registry')
local Factories=require('gameplay.package_factories')
local Adapter=require('gameplay.adapters.zaizai.adapter')
local Bootstrap=require('gameplay.bootstrap')
local Map=require('gameplay.packages.environment.map_demo.definition')
local Match=require('gameplay.systems.match.controller')
local Setup=require('gameplay.systems.round_setup.controller')
local Settlement=require('gameplay.systems.settlement.controller')
local Bag=require('gameplay.systems.inventory_meta.controller')
local UI=require('gameplay.packages.ui.ui_main.controller')
local Spatial=require('gameplay.core.spatial')
local Demo={};Demo.__index=Demo
local function copy(t)local out={};for k,v in pairs(t or{})do out[k]=type(v)=='table'and copy(v)or v end;return out end
local function profile(go,name)
 local ok,value=pcall(function()
  if not go then error('model not loaded: '..name)end
  local s=go:GetDouyinScript(name)
  if not s or not s.script or not s.script.GetProfile then error('profile script not ready: '..name)end
  return s.script.GetProfile()
 end)
 if ok and type(value)=='table'then return value end
 return nil,ok and('profile returned '..type(value))or tostring(value)
end
local function atan2(y,x)
 if x>0 then return math.atan(y/x)elseif x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi)elseif y>0 then return math.pi/2 elseif y<0 then return -math.pi/2 else return 0 end
end
local function number(value,default,min,max)
 local n=tonumber(value);if not n or n~=n or n<min or n>max then return default end;return n
end
local function merge_numbers(target,source,limits)
 for key,limit in pairs(limits)do if source and source[key]~=nil then target[key]=number(source[key],target[key],limit[1],limit[2])end end
end
function Demo.new(host)return setmetatable({host=host,started=false,sequence=0,objects={},qa_results={}},Demo)end
function Demo:log(message)CS.UnityEngine.Debug.Log('[ZZ_DEMO] '..message)end
function Demo:start()
 if self.started then return true end
 local U=CS.UnityEngine
 if not CS.DouyinActorService.GetLocalActor()then self.pending=true;return false end
 local p,pe=profile(U.GameObject.Find('player_default'),'player_attributes.lua')
 local m,me=profile(U.GameObject.Find('monster_cube'),'monster_attributes.lua')
 local session,se=profile(self.host,'match_attributes.lua')
 if not p or not m or not session then
  self.pending=true;self.profile_attempts=(self.profile_attempts or 0)+1
  if self.profile_attempts>=120 then error('Inspector profile loading failed: '..tostring(pe)..' / '..tostring(me)..' / '..tostring(se))end
  return false
 end
 self.inspector_profiles_ready=true
 local config=copy(Config);config.projectName='仔仔搜打撤1.0';config.state='native_whitebox_demo'
 local definitions={};for id,factory in pairs(Factories)do definitions[id]=copy(factory.definition)end
 merge_numbers(config.player,p.player,{maxHp={1,500},startHp={1,500},walkSpeedMps={.1,12},sprintSpeedMps={.1,15},crouchSpeedMps={.1,8},jumpHeightM={0,3},colliderRadiusM={.1,1},colliderHeightM={.5,3},colliderCenterY_M={0,2},spawnProtectionSec={0,15},hitInvulnerabilitySec={0,3}})
 config.player.startHp=math.min(config.player.maxHp,config.player.startHp)
 config.player.colliderHeightM=math.max(config.player.colliderHeightM,2*config.player.colliderRadiusM)
 merge_numbers(config.inventory,p.inventory,{bagSlots={1,48}});config.inventory.bagSlots=math.floor(config.inventory.bagSlots)
 merge_numbers(config.interaction,p.interaction,{maxDistanceM={.5,5}})
 local d=definitions.monster_cube
 merge_numbers(d,m,{maxHp={1,10000},patrolSpeedMps={.1,15},chaseSpeedMps={.1,20},patrolWaitSec={0,10},arriveDistanceM={.05,2},pathRefreshSec={.05,5},pathFailureRetrySec={.05,10},patrolUnreachableSkipSec={.1,30},leashRadiusM={1,100},hurtPauseSec={0,5}})
 merge_numbers(d.sense,m.sense,{rangeM={.1,50},fullAngleDeg={1,360},loseSightGraceSec={0,10},searchSec={0,30}})
 merge_numbers(d.attacks[1],m.attacks and m.attacks[1],{damageHp={0,1000},windupSec={0,10},activeSec={.05,5},recoverySec={0,10},cooldownSec={.05,30},rangeM={.1,15},arcDeg={1,360}})
 local attack=d.attacks[1];attack.cooldownSec=math.max(attack.cooldownSec,attack.windupSec+attack.activeSec+attack.recoverySec)
 merge_numbers(config.session,session,{roundDurationSec={30,3600},extractionHoldSec={.5,15}})
 self.config=config;self.definitions=definitions
 self.adapter=Adapter.new({host=self.host,config=config,definitions=definitions,map=Map,registry=Registry})
 local ctx=Bootstrap.create(self.adapter);ctx.config=config;ctx.definitions=definitions;ctx.state=self.adapter.state;ctx.demo=self;ctx.map_entity_id='map_demo'
 function ctx:next_request_id(prefix)self.request_sequence=(self.request_sequence or 0)+1;return self.state.run_id..':'..prefix..':'..self.request_sequence end
 self.context=ctx;self.match=Match.new(ctx);self.settlement=Settlement.new(ctx)
 local proxy=U.GameObject.Find('player_default');if proxy then
  local renderer=proxy:GetComponent(typeof(U.Renderer));if renderer then renderer.enabled=false end
  local collider=proxy:GetComponent(typeof(U.Collider));if collider then collider.enabled=false end
 end
 self.started=true;self.pending=false;self:begin_round();self:make_vision();self:log('READY config=0.2.0 roles=0.3.0 map=4rooms local_single_player');return true
end
function Demo:begin_round()
 if self.setup then self.setup:dispose()end
 if self.bag then self.bag:dispose()end
 if self.ui then self.ui:dispose()end
 self.adapter.state.ui_view=nil;self.next_vision_at=0
 local result=self.match:start();if not result.ok then error('match_start:'..tostring(result.reason))end
 self.setup=Setup.new(self.context);self.objects=self.setup:start(Map)
 self.bag=Bag.new(self.context,{heal=self.objects.heal});assert(self.bag:start())
 self.ui=UI.new(self.context,function(action,item)return self:dispatch(action,item)end);self.adapter.ui=self.ui;self.ui:start()
 self.adapter.services.Assets:play_clip(self:request('reset_chest',{instance_id='chest_demo',native_action='chest_close',clip_id='native_idle'}))
 self.context.state.toast='Demo 已就绪 · 前往黄色宝箱，绿色区域为撤离点'
end
function Demo:request(prefix,fields)fields=fields or{};fields.run_id=self.context.state.run_id;fields.request_id=self.context:next_request_id(prefix);return fields end
function Demo:message(result)
 local messages={FULL_HEALTH='当前满血，无需用药',CAST_STARTED='开始用药，请保持静止',OUT_OF_RANGE_OR_BLOCKED='距离过远或有墙体遮挡',COOLDOWN='动作冷却中',ITEM_NOT_OWNED='背包中没有这个道具',NO_USE_HANDLER='该物品是藏品 / 武器',EXTRACTION_STARTED='开始撤离读条',INVALID_PHASE='当前阶段不能执行',USE_IN_PROGRESS='正在使用道具'}
 self.context.state.toast=messages[result and result.reason]or(result and result.ok and'操作成功'or'操作失败：'..tostring(result and result.reason));return result
end
function Demo:close_view()
 self.objects.chest:close();self.adapter.services.UI:close_view(self:request('ui_close'))
end
function Demo:dispatch(action,item)
 if not self.started then return end
 local s=self.context.state;local svc=self.context.services
 if action=='qa'then return self:start_qa()end
 if action=='restart'then self.qa=nil;self.qa_summary=nil;self:begin_round();return end
 if action=='close'then self:close_view();return end
 if action=='attributes'then svc.UI:open_view(self:request('attributes',{view_id='attributes'}));return end
 if action=='bag'then if s.ui_view then self:close_view()else svc.UI:open_view(self:request('bag',{view_id='bag'}))end;return end
 if s.phase=='FINISHED'then return end
 if action=='pickup'then local result=self.objects.chest:pickup(item,1);self:message(result);self.ui:refresh_modal();return result end
 if action=='take_all'then
  local contents=self.objects.chest:read_contents();for _,entry in ipairs(contents.data.bag.items or{})do self:message(self.objects.chest:pickup(entry.id,entry.count))end
  self.ui:refresh_modal();return
 end
 if action=='use_item'then local result=self.bag:use_item(item);self:message(result);if result.ok then self:close_view()end;return result end
 if s.ui_view then s.toast='请先关闭面板';return end
 if action=='attack'then return self:message(self.objects.shovel:use({target_instance_id='monster_cube_1'}))end
 if action=='heal'then
  local bag=self.bag:read_bag().data.bag
  for _,entry in ipairs(bag.items)do if entry.entity_id=='item_heal_small'then return self:message(self.bag:use_item(entry.id))end end
  s.toast='先从宝箱取得药品';return
 end
 if action=='interact'then
  local pos=self.adapter:position('player_local');local chestdist=Spatial.distance(pos,Map.chest);local exitdist=Spatial.distance(pos,Map.exit)
  if exitdist<=self.config.interaction.maxDistanceM and exitdist<chestdist then return self:message(svc.Session:try_extract(self:request('extract',{user_instance_id='player_local',exit_instance_id='exit_demo'})))end
  local r=self.objects.chest:open('player_local');if r.ok then svc.UI:open_view(self:request('chest_view',{view_id='chest',container_id='chest_demo'}))end;return self:message(r)
 end
end
function Demo:make_vision()
 local U=self.adapter.U;local go=U.GameObject('demo_monster_vision');go.transform:SetParent(self.adapter.runtime_root.transform,false)
 self.vision=go:AddComponent(typeof(U.LineRenderer));self.vision.material=U.Material(U.Shader.Find('Sprites/Default'));self.vision.startWidth=.045;self.vision.endWidth=.045;self.vision.useWorldSpace=true
 self.vision.positionCount=39;self.next_vision_at=0
end
function Demo:update_vision()
 local s=self.context.state;if s.clock<(self.next_vision_at or 0)then return end;self.next_vision_at=s.clock+.12;local monster=s.entities.monster_cube_1
 self.vision.enabled=monster and monster.alive and self.definitions.monster_cube.sense.showDebugCone
 if not self.vision.enabled then return end
 local p=self.adapter:position('monster_cube_1');local f=self.adapter:forward('monster_cube_1');local sense=self.definitions.monster_cube.sense
 local yaw=atan2(f.x,f.z);local half=sense.fullAngleDeg*.5*math.pi/180
 local U=self.adapter.U;local detected=self.adapter:sense({user_instance_id='monster_cube_1',target_instance_id='player_local',mode='perception'}).data.visible
 local color=detected and U.Color(1,.17,.08,1)or U.Color(1,.69,.12,1);self.vision.startColor=color;self.vision.endColor=color
 self.vision:SetPosition(0,U.Vector3(p.x,.06,p.z))
 for i=0,36 do
  local angle=yaw-half+2*half*i/36;local dist=sense.rangeM
  local target={x=p.x+math.sin(angle)*dist,y=.06,z=p.z+math.cos(angle)*dist}
  if Spatial.blocked(p,target,Map.walls,0)then local lo,hi=0,dist;for j=1,10 do local mid=(lo+hi)/2;local q={x=p.x+math.sin(angle)*mid,z=p.z+math.cos(angle)*mid};if Spatial.blocked(p,q,Map.walls,0)then hi=mid else lo=mid end end;dist=lo end
  self.vision:SetPosition(i+1,U.Vector3(p.x+math.sin(angle)*dist,.06,p.z+math.cos(angle)*dist))
 end
 self.vision:SetPosition(38,U.Vector3(p.x,.06,p.z))
end
function Demo:update(elapsed)
 if not self.started then if self.pending then self:start()end;return end
 local U=self.adapter.U;self.frame=(self.frame or 0)+1
 if not self.qa then
  local keys={{U.KeyCode.E,'interact'},{U.KeyCode.F,'attack'},{U.KeyCode.B,'bag'},{U.KeyCode.H,'heal'},{U.KeyCode.Escape,'close'}}
  for _,pair in ipairs(keys)do if U.Input.GetKeyDown(pair[1])then self:dispatch(pair[2])end end
 end
 local remaining=math.max(0,elapsed or 0)
 while remaining>0 do
  local dt=math.min(.05,remaining);remaining=remaining-dt
  self.adapter:tick(dt)
  self.objects.player:update(dt);self.objects.shovel:update(dt);self.objects.heal:update(dt);self.objects.chest:update(dt);self.objects.monster:update(dt)
  self.settlement:update(dt)
  if self.qa then self:update_qa(dt)end
 end
 self:update_vision();self.ui:update(elapsed)
end
function Demo:teleport(p,face)
 local U=self.adapter.U;local rotation=face and U.Quaternion.LookRotation(U.Vector3(face.x,0,face.z))or U.Quaternion.identity
 local actor=self.adapter:actor();actor:Teleport(self.adapter:vector(p),rotation)
 if face then actor.gameObject.transform.rotation=rotation end
 self.teleport_expected=copy(p)
end
function Demo:qa_check(name,condition,detail)
 local entry={name=name,ok=condition==true,detail=tostring(detail or'')};self.qa_results[#self.qa_results+1]=entry
 self:log('QA '..(entry.ok and'PASS'or'FAIL')..' '..name..' '..entry.detail)
 if not entry.ok then self.qa_summary='验收失败：'..name..' '..entry.detail;self.qa=nil;return false end
 self.qa_summary='自动验收：'..#self.qa_results..' 项通过 · '..name;return true
end
function Demo:start_qa()
 if self.qa then return end
 if self.context.state.phase~='FINISHED'then self.context.services.Session:try_finish(self:request('qa_reset',{terminal_reason='quit'}))end
 -- Start only through the normal match flow; no HP/inventory mutation in the test driver.
 self:begin_round();self.qa_results={};self.qa_summary='自动验收：重开局，检查实际运行服务';self.qa={stage=1,t=0,elapsed=0,last=self.adapter:position('monster_cube_1')}
 self:log('QA START native actor teleports are test navigation only')
end
function Demo:qa_stage(stage)self.qa.stage=stage;self.qa.t=0;self.qa.frame=self.frame end
function Demo:qa_combat_position(attempt)
 local pos=self.adapter:position('monster_cube_1');local f=self.adapter:forward('monster_cube_1');local base=atan2(f.x,f.z)+(attempt or 0)*math.pi/6
 for i=0,11 do
  local a=base+i*math.pi/6;local p={x=pos.x+math.sin(a)*1.6,y=.1,z=pos.z+math.cos(a)*1.6}
  if p.x>Map.bounds.min_x+.65 and p.x<Map.bounds.max_x-.65 and p.z>Map.bounds.min_z+.65 and p.z<Map.bounds.max_z-.65 and not Spatial.blocked(p,p,Map.walls,.65)and not Spatial.blocked(p,pos,Map.walls,0)then
   self:teleport(p,{x=pos.x-p.x,z=pos.z-p.z});return true
  end
 end
 return false
end
function Demo:qa_face_monster()
 local pos=self.adapter:position('player_local');local target=self.adapter:position('monster_cube_1');local U=self.adapter.U
 self.adapter:actor().gameObject.transform.rotation=U.Quaternion.LookRotation(U.Vector3(target.x-pos.x,0,target.z-pos.z))
end
function Demo:update_qa(dt)
 local q=self.qa;if not q then return end;q.t=q.t+dt;q.elapsed=q.elapsed+dt
 local s=self.context.state;local p=s.entities.player_local;local m=s.entities.monster_cube_1
 if (self.frame or 0)-(q.frame or 0)<2 then return end
 if q.elapsed>65 then self:qa_check('全过程限时',false,'stage '..q.stage);return end
 if q.stage==1 and q.t>1.2 then
  if not self:qa_check('初始角色100HP与怪物60HP',p.hp==100 and m.hp==60)then return end
  if not self:qa_check('方块怪物巡逻位移',Spatial.distance(q.last,self.adapter:position('monster_cube_1'))>.1)then return end
  self:teleport({x=1,y=.1,z=-2});self:qa_stage(2)
 elseif q.stage==2 and q.t>.4 then
  local r=self:dispatch('interact');if not self:qa_check('打开宝箱',r and r.ok,r and r.reason)then return end
  self:dispatch('take_all');self:close_view()
  local bag=self.bag:read_bag().data.bag;local medicine,treasure=0,0
  for _,entry in ipairs(bag.items)do if entry.entity_id=='item_heal_small'then medicine=medicine+entry.count elseif entry.entity_id=='item_treasure'then treasure=treasure+entry.count end end
  if not self:qa_check('宝物1份与药品2份进入背包',medicine==2 and treasure==1)then return end
  local r2=self:dispatch('heal');if not self:qa_check('满血用药拒绝',r2 and not r2.ok and r2.reason=='FULL_HEALTH')then return end
  self:qa_stage(3)
 elseif q.stage==3 and s.clock>3.4 then
  local pos=self.adapter:position('monster_cube_1');local f=self.adapter:forward('monster_cube_1')
  self:teleport({x=pos.x-f.x*1.8,y=.1,z=pos.z-f.z*1.8});self:qa_stage(4)
 elseif q.stage==4 and q.t>.1 then
  local sense=self.adapter:sense({user_instance_id='monster_cube_1',target_instance_id='player_local',mode='perception'})
  if not self:qa_check('视野背后不索敌',sense.data.angular_valid==false and sense.data.visible==false)then return end
  local pos=self.adapter:position('monster_cube_1');local f=self.adapter:forward('monster_cube_1')
  self:teleport({x=pos.x+f.x*1.8,y=.1,z=pos.z+f.z*1.8},{x=-f.x,z=-f.z});self:qa_stage(5)
 elseif q.stage==5 and p.hp<100 then
  if not self:qa_check('怪物前摇后攻击造成25伤害',p.hp==75,p.hp)then return end
  self:teleport({x=1,y=.1,z=-2});self:qa_stage(6)
 elseif q.stage==6 and q.t>.5 then
  local result=self:dispatch('heal');if not self:qa_check('受伤可开始药品读条',result and result.ok,result and result.reason)then return end
  self:qa_stage(7)
 elseif q.stage==7 and not self.objects.heal.cast then
  local r=self.objects.heal.last_result;if not self:qa_check('读条完成回血100HP',r and r.ok and p.hp==100,r and r.reason)then return end
  local n=0;for _,entry in ipairs(self.bag:read_bag().data.bag.items)do if entry.entity_id=='item_heal_small'then n=n+entry.count end end
  if not self:qa_check('只消耗一份药品',n==1,n)then return end
  self:qa_combat_position(0);self:qa_stage(8)
 elseif q.stage==8 and q.t>.25 then
  self:qa_face_monster()
  local r=self:dispatch('attack');if not self:qa_check('铲击进入前摇',r and r.ok,r and r.reason)then return end;self:qa_stage(9)
 elseif q.stage==9 and m.hp==30 then
  if not self:qa_check('首个有效窗口扣30HP',true)then return end;self:qa_stage(10)
 elseif q.stage==10 and q.t>1.4 then
  self:qa_combat_position(0);self:qa_stage(11)
 elseif q.stage==11 and q.t>.3 then
  self:qa_face_monster()
  local sense=self.adapter:sense({user_instance_id='player_local',target_instance_id='monster_cube_1',mode='weapon'}).data
  if not sense.visible and q.t<5 then q.attempt=(q.attempt or 0)+1;self:qa_combat_position(q.attempt);q.frame=self.frame;return end
  local r=self:dispatch('attack');local pp=self.adapter:position('player_local');local mp=self.adapter:position('monster_cube_1')
  local detail=tostring(r and r.reason)..' d='..tostring(sense.distance_m)..' arc='..tostring(sense.angular_valid)..' los='..tostring(sense.line_of_sight)..' p='..pp.x..','..pp.z..' m='..mp.x..','..mp.z
  if not self:qa_check('第二次铲击',r and r.ok,detail)then return end;self:qa_stage(12)
 elseif q.stage==12 and m.hp==0 then
  if not self:qa_check('怪物死亡停止行为',m.alive==false)then return end
  self:teleport(Map.exit);self:qa_stage(13)
 elseif q.stage==13 and q.t>.4 then
  local r=self:dispatch('interact');if not self:qa_check('撤离区域读条开始',r and r.ok,r and r.reason)then return end;self:qa_stage(14)
 elseif q.stage==14 and s.result then
  if not self:qa_check('3秒后结算成功带出宝物',s.result.success and s.result.loot_value>=250,s.result.reason..' value='..s.result.loot_value)then return end
  local id=s.result.result_id;self.context.services.Session:try_finish(self:request('qa_duplicate',{terminal_reason='extraction'}))
  if not self:qa_check('重复结束不二次结算',s.result.result_id==id)then return end
  self.qa=nil;self.qa_summary='编辑器实际验收通过 '..#self.qa_results..' 项 · 拾取 → 战斗 → 用药 → 撤离';self:log('QA COMPLETE passed='..#self.qa_results)
 end
end
function Demo:GetSnapshot()
 if not self.context then return {ready=false,pending=self.pending}end
 local s=self.context.state
 return {ready=self.started,project=self.config.projectName,run_id=s.run_id,phase=s.phase,clock=s.clock,player=copy(s.entities.player_local),monster=copy(s.entities.monster_cube_1),monster_state=self.objects.monster.ai_state,bag=copy(s.containers.bag_player_local),result=copy(s.result),speed_write_ok=self.adapter.speed_write_ok,speed_readback=self.adapter.speed_readback,collider_apply_ok=self.adapter.collider_apply_ok,collider_readback=copy(self.adapter.collider_readback),qa=copy(self.qa_results),qa_summary=self.qa_summary}
end
function Demo:dispose()
 self.qa=nil;if self.setup then self.setup:dispose()end;if self.bag then self.bag:dispose()end;if self.ui then self.ui:dispose()end;if self.adapter then self.adapter:dispose()end
 self.started=false
end
return Demo

end
return ProjectRequire("gameplay.demo")

end)()
local instance
local failed=false
local unpack_args=table.unpack or unpack
local function invoke(method,...)
 if failed or not instance then return end
 local args={...}
 local ok,err=pcall(function()return instance[method](instance,unpack_args(args))end)
 if not ok then
  failed=true
  CS.UnityEngine.Debug.LogError('[ZZ_DEMO_ERROR] '..tostring(err))
  if instance.ui and instance.ui.notice then instance.ui.notice.text='Demo错误：'..tostring(err)end
 end
end
function Start()
 instance=Demo.new(self.gameObject)
 -- Child property scripts must finish loading before their profiles are read.
 instance.pending=true
end
function Update() invoke('update',CS.UnityEngine.Time.unscaledDeltaTime)end
function OnDestroy()if instance then pcall(function()instance:dispose()end)end end
function GetStatus()return failed and 'FAILED'or(instance and instance.started and 'READY'or'WAIT_ACTOR')end
function GetSnapshot()return instance and instance:GetSnapshot()or{ready=false}end
function GetQAResults()return instance and instance.qa_results or{}end
return {GetStatus=GetStatus,GetSnapshot=GetSnapshot,GetQAResults=GetQAResults}
