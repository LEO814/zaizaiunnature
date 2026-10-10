-- Planner-owned chest interaction. Round setup owns the one-time container seed.
local Definition = require("gameplay.packages.interactables.chest_basic.definition")
local Controller = {}
Controller.__index=Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
function Controller.new(context,instance)
  assert(type(context)=="table"and type(instance)=="table"and instance.id,"context/instance required")
  return setmetatable({context=context,instance=instance,definition=Definition,
    container_id=instance.container_id or "chest_demo",opened=false,started=false,disposed=false},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED"end
  if self.context.is_ready==false then return false,"ADAPTER_NOT_READY"end
  for _,name in ipairs({"Interaction","Inventory","Assets"})do
    if not self.context.services[name]then return false,"MISSING_SERVICE:"..name end
  end
  self.opened=false;self.started=true;return true
end
function Controller:permit(owner)
  return self.context.services.Interaction:try_begin(self:request("chest_permission",{
    user_instance_id=owner,target_instance_id=self.instance.id,mode="chest",
    max_distance_m=Definition.interactionDistanceM
  }))
end
function Controller:read_contents()
  return self.context.services.Inventory:read_snapshot(self:request("chest_snapshot",{container_id=self.container_id}))
end
function Controller:open(player_id)
  local id=self.context:next_request_id("chest_open")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  local owner=player_id or "player_local"
  local permission=self:permit(owner)
  if not permission.ok then self.last_result=permission;return permission end
  local snapshot=self:read_contents()
  if not snapshot.ok then self.last_result=snapshot;return snapshot end
  local was_open=self.opened
  self.opened=true;self.owner_id=owner
  if not was_open then
    self.context.services.Assets:play_clip(self:request("chest_animation",{
      instance_id=self.instance.id,clip_id="clip_chest_basic_open",native_action="chest_open"
    }))
  end
  snapshot.data.container_id=self.container_id
  self.last_result=snapshot
  return snapshot
end
function Controller:pickup(item_id,count)
  local id=self.context:next_request_id("chest_pickup")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.opened then return result(false,"CHEST_NOT_OPEN",id)end
  if self.context.state.phase~="EXPLORE"then self:close();return result(false,"INVALID_PHASE",id)end
  local permission=self:permit(self.owner_id)
  if not permission.ok then self:close();self.last_result=permission;return permission end
  local source=self:read_contents()
  if not source.ok then self.last_result=source;return source end
  local destination=self.context.services.Inventory:read_snapshot(self:request("chest_bag",{owner_instance_id=self.owner_id}))
  if not destination.ok then self.last_result=destination;return destination end
  self.last_result=self.context.services.Inventory:try_transfer({
    request_id=id,run_id=self.context.state.run_id,from_id=self.container_id,
    to_id="bag_"..self.owner_id,item_instance_id=item_id,count=count or 1,
    expected_versions={from=source.data.bag.version,to=destination.data.bag.version}
  })
  return self.last_result
end
function Controller:close()
  if self.opened and not self.disposed then
    self.context.services.Assets:play_clip(self:request("chest_close",{
      instance_id=self.instance.id,clip_id="clip_chest_basic_close",native_action="chest_close"
    }))
  end
  self.opened=false;self.owner_id=nil
end
function Controller:update(dt)
  if self.disposed or not self.started or not self.opened then return end
  if self.context.state.phase~="EXPLORE"then self:close();return end
  local query=self.context.services.Interaction:query_target(self:request("chest_range",{
    user_instance_id=self.owner_id,target_instance_id=self.instance.id,mode="chest",
    max_distance_m=Definition.interactionDistanceM
  }))
  local e=query.data or {}
  if not query.ok or not e.in_range or not e.line_of_sight then self:close()end
end
function Controller:dispose()
  if self.disposed then return end
  self:close();self.started=false;self.disposed=true
end
return Controller
