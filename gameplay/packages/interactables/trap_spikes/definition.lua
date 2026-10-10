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
