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
