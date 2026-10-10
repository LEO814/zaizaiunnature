-- Planner-owned shovel timing. The public Combat service alone commits damage.
local Definition = require("gameplay.packages.weapons.weapon_shovel.definition")
local Controller = {}
Controller.__index = Controller
local function result(ok, reason, id, data)
  return {ok=ok,reason=reason,request_id=id,data=data or {}}
end
function Controller.new(context, instance)
  assert(type(context)=="table" and type(instance)=="table" and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    started=false,disposed=false,stage="IDLE",next_use_at=0},Controller)
end
function Controller:request(prefix, fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED" end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY" end
  for _,name in ipairs({"Characters","Combat","Interaction","Assets"}) do
    if not self.context.services[name] then return false,"MISSING_SERVICE:"..name end
  end
  self.started=true;return true
end
function Controller:can_hit(target)
  local owner=self.instance.owner_instance_id or "player_local"
  local query=self.context.services.Interaction:query_target(self:request("shovel_target",{
    user_instance_id=owner,source_instance_id=owner,target_instance_id=target,mode="weapon",
    max_distance_m=Definition.attack.rangeM,full_angle_deg=Definition.attack.arcDeg
  }))
  if not query.ok then return false,query.reason,query.data end
  local evidence=query.data or {}
  local valid=evidence.visible==true and evidence.in_range==true and
    evidence.angular_valid==true and evidence.line_of_sight==true
  return valid,valid and nil or "TARGET_NOT_HITTABLE",evidence
end
function Controller:use(request)
  request=request or {}
  local id=request.request_id or self.context:next_request_id("shovel_use")
  if self.disposed then return result(false,"DISPOSED",id) end
  if not self.started then return result(false,"NOT_STARTED",id) end
  if self.context.state.phase~="EXPLORE" then return result(false,"INVALID_PHASE",id) end
  if self.attack then return result(false,"ATTACK_IN_PROGRESS",id) end
  local now=self.context.state.clock
  if now<self.next_use_at then return result(false,"COOLDOWN",id) end
  local target=request.target_instance_id
  if not target then return result(false,"TARGET_REQUIRED",id) end
  local can_hit,reason=self:can_hit(target)
  if not can_hit then return result(false,reason,id) end
  local owner=self.instance.owner_instance_id or "player_local"
  local begin=self.context.services.Combat:try_begin_attack(self:request("shovel_begin",{
    source_instance_id=owner,attack_id=Definition.attack.id,item_instance_id=self.instance.item_instance_id
  }))
  if not begin.ok then self.last_result=begin;return begin end
  self.attack={id=begin.data.attack_instance_id,target_id=target,started_at=now,owner_id=owner,attempted=false}
  self.stage="WINDUP";self.next_use_at=now+Definition.attack.cooldownSec
  self.context.services.Assets:play_clip(self:request("shovel_animation",{
    instance_id=owner,clip_id="native_attack",native_action="attack",definition_clip_id=Definition.attack.clipId
  }))
  self.last_result=begin
  return begin
end
function Controller:cancel(reason)
  local attack=self.attack
  if attack then
    self.context.services.Combat:cancel_attack(self:request("shovel_cancel",{attack_instance_id=attack.id}))
  end
  self.attack=nil;self.stage="IDLE"
  self.cancel_reason=reason
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.attack then return end
  if self.context.state.phase~="EXPLORE" then self:cancel("PHASE_CHANGED");return end
  local attack=self.attack
  local player=self.context.services.Characters:read_snapshot(self:request("shovel_owner",{instance_id=attack.owner_id}))
  if not player.ok or not player.data.alive then self:cancel("OWNER_DEAD");return end
  local elapsed=self.context.state.clock-attack.started_at
  local active_start=Definition.attack.windupSec
  local active_end=active_start+Definition.attack.activeSec
  local total=active_end+Definition.attack.recoverySec
  if elapsed<active_start then self.stage="WINDUP"
  elseif elapsed<active_end then
    self.stage="ACTIVE"
    if not attack.attempted then
      attack.attempted=true
      local valid,reason,evidence=self:can_hit(attack.target_id)
      if valid then
        self.last_result=self.context.services.Combat:try_apply_damage(self:request("shovel_hit",{
          attack_instance_id=attack.id,target_instance_id=attack.target_id,tick_index=0,
          hit_evidence={distance_m=evidence.distance_m,angular_valid=true,line_of_sight=true}
        }))
      else self.last_result=result(false,reason,self.context:next_request_id("shovel_miss")) end
    end
  elseif elapsed<total then self.stage="RECOVERY"
  else self:cancel("COMPLETED") end
end
function Controller:get_status()
  local elapsed=self.attack and self.context.state.clock-self.attack.started_at or 0
  return {stage=self.stage,elapsed_sec=elapsed,cooldown_remaining=math.max(0,self.next_use_at-self.context.state.clock),last_result=self.last_result}
end
function Controller:dispose()
  if self.disposed then return end
  self:cancel("DISPOSED");self.started=false;self.disposed=true
end
return Controller
