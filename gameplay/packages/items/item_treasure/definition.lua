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
