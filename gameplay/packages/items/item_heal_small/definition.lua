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
