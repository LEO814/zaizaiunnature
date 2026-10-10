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
