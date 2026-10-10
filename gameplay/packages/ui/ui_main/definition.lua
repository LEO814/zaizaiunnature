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
