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
