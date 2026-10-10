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
