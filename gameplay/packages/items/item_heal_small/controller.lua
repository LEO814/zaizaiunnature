-- Planner-owned medicine cast/cancel logic. Healing and consumption commit together.
local Definition = require("gameplay.packages.items.item_heal_small.definition")
local Controller = {}
Controller.__index = Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
local function distance(a,b)
  local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
  return math.sqrt(x*x+y*y+z*z)
end
function Controller.new(context,instance)
  assert(type(context)=="table" and type(instance)=="table" and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    started=false,disposed=false,stage="IDLE",next_use_at=0},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED" end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY" end
  for _,name in ipairs({"Characters","Combat","Inventory","Assets"})do
    if not self.context.services[name]then return false,"MISSING_SERVICE:"..name end
  end
  self.started=true;return true
end
function Controller:use(request)
  request=request or {}
  local id=request.request_id or self.context:next_request_id("heal_use")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  if self.cast then return result(false,"USE_IN_PROGRESS",id)end
  if self.context.state.clock<self.next_use_at then return result(false,"COOLDOWN",id)end
  local owner=request.user_instance_id or self.instance.owner_instance_id or "player_local"
  local character=self.context.services.Characters:read_snapshot(self:request("heal_owner",{instance_id=owner}))
  if not character.ok then return character end
  local player=character.data
  if not player.alive then return result(false,"OWNER_DEAD",id)end
  if player.hp>=player.max_hp then return result(false,"FULL_HEALTH",id)end
  if not player.position_m then return result(false,"POSITION_UNAVAILABLE",id)end
  local inventory=self.context.services.Inventory:read_snapshot(self:request("heal_inventory",{owner_instance_id=owner}))
  if not inventory.ok then return inventory end
  local bag=inventory.data.bag
  local item_id=request.item_instance_id
  local found
  for _,item in ipairs(bag.items or {})do
    if item.id==item_id and item.entity_id==Definition.id and item.count>0 then found=true;break end
  end
  if not found then return result(false,"ITEM_NOT_OWNED",id)end
  local p=player.position_m
  self.cast={id=id,item_id=item_id,owner_id=owner,started_at=self.context.state.clock,
    origin={x=p.x,y=p.y,z=p.z},last_hp=player.hp}
  self.stage="USING"
  self.context.services.Assets:play_clip(self:request("heal_animation",{
    instance_id=owner,clip_id="native_use",native_action="use",definition_clip_id=Definition.useClipId
  }))
  self.last_result=result(true,"CAST_STARTED",id,{cast_sec=Definition.castSec})
  return self.last_result
end
function Controller:cancel(reason)
  if not self.cast then return false end
  self.last_result=result(false,reason or "CANCELLED",self.cast.id)
  self.cast=nil;self.stage="IDLE";return true
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.cast then return end
  local cast=self.cast
  if self.context.state.phase~="EXPLORE" then self:cancel("PHASE_CHANGED");return end
  local character=self.context.services.Characters:read_snapshot(self:request("heal_progress",{instance_id=cast.owner_id}))
  if not character.ok or not character.data.alive then self:cancel("OWNER_DEAD");return end
  local player=character.data
  if not player.position_m then self:cancel("POSITION_UNAVAILABLE");return end
  if Definition.cancelOnDamage and player.hp<cast.last_hp then self:cancel("DAMAGED");return end
  cast.last_hp=player.hp
  if distance(player.position_m,cast.origin)>Definition.cancelOnMoveBeyondM then self:cancel("MOVED");return end
  if self.context.state.clock-cast.started_at<Definition.castSec then return end
  -- Clear the cast before submitting; repeated update cannot consume another medicine.
  self.cast=nil;self.stage="IDLE"
  self.last_result=self.context.services.Combat:try_heal({
    request_id=cast.id,run_id=self.context.state.run_id,user_instance_id=cast.owner_id,item_instance_id=cast.item_id
  })
  if self.last_result.ok then self.next_use_at=self.context.state.clock+Definition.cooldownSec end
end
function Controller:get_status()
  local elapsed=self.cast and math.max(0,self.context.state.clock-self.cast.started_at)or 0
  return {stage=self.stage,progress_sec=elapsed,cast_sec=Definition.castSec,
    progress_ratio=math.min(1,elapsed/Definition.castSec),
    cooldown_remaining=math.max(0,self.next_use_at-self.context.state.clock),last_result=self.last_result}
end
function Controller:dispose()
  if self.disposed then return end
  self:cancel("DISPOSED");self.started=false;self.disposed=true
end
return Controller
