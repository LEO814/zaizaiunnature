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
