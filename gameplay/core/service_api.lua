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
