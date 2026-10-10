-- Planner-owned player action driver; authoritative HP stays in Characters.
local Definition = require("gameplay.packages.player.player_default.definition")
local Controller = {}
Controller.__index = Controller

function Controller.new(context, instance)
  assert(type(context) == "table" and type(instance) == "table" and instance.id, "context/instance required")
  return setmetatable({context=context, instance=instance, definition=Definition,
    started=false, disposed=false, action="idle", input_allowed=false, move_allowed=false}, Controller)
end

function Controller:request(prefix, fields)
  fields = fields or {}
  fields.run_id = self.context.state.run_id
  fields.request_id = self.context:next_request_id(prefix)
  return fields
end

function Controller:play_action(action)
  if self.disposed or not self.started then return false end
  self.action = action
  self.context.services.Assets:play_clip(self:request("player_action", {
    instance_id=self.instance.id, clip_id="native_" .. action, native_action=action
  }))
  return true
end

function Controller:start()
  if self.disposed then return false, "DISPOSED" end
  if self.context.is_ready == false then return false, "ADAPTER_NOT_READY" end
  for _, name in ipairs({"Characters", "Assets"}) do
    if not self.context.services[name] then return false, "MISSING_SERVICE:" .. name end
  end
  self.started = true
  self:play_action("idle")
  return true
end

function Controller:update(dt)
  if self.disposed or not self.started then return end
  local result = self.context.services.Characters:read_snapshot(self:request("player_snapshot", {instance_id=self.instance.id}))
  if not result.ok then self.input_allowed=false;self.move_allowed=false;return end
  local snapshot = result.data
  local phase = self.context.state.phase
  self.input_allowed = snapshot.alive and phase == "EXPLORE"
  self.move_allowed = snapshot.alive and (phase == "EXPLORE" or phase == "EXTRACTING")
  local action
  if not snapshot.alive then
    action = "death"
  elseif self.last_hp and snapshot.hp < self.last_hp then
    action = "hurt"
    self.hurt_until = self.context.state.clock + .3
  elseif self.hurt_until and self.context.state.clock < self.hurt_until then
    action = "hurt"
  else
    local p, previous = snapshot.position_m, self.last_position
    local distance = 0
    if p and previous then
      local x,z=p.x-previous.x,p.z-previous.z
      distance=math.sqrt(x*x+z*z)
    end
    action = self.move_allowed and distance > .002 and "walk" or "idle"
  end
  if action ~= self.action then self:play_action(action) end
  self.last_hp = snapshot.hp
  if snapshot.position_m then
    local p=snapshot.position_m
    self.last_position={x=p.x,y=p.y,z=p.z}
  end
end

function Controller:dispose()
  if self.disposed then return end
  self.input_allowed=false;self.move_allowed=false;self.started=false;self.disposed=true
end
return Controller
