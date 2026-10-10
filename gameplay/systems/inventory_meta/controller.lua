-- Program-owned inventory use dispatch; object behavior arrives by dependency injection.
local Controller={}
Controller.__index=Controller
local function result(ok,reason,id,data)return {ok=ok,reason=reason,request_id=id,data=data or {}}end
function Controller.new(context,objects)
  assert(type(context)=="table","context required")
  return setmetatable({context=context,objects=objects or {},started=false,disposed=false},Controller)
end
function Controller:request(prefix,fields)
  fields=fields or {};fields.run_id=self.context.state.run_id
  fields.request_id=self.context:next_request_id(prefix);return fields
end
function Controller:start()
  if self.disposed then return false,"DISPOSED"end
  if not self.context.services.Inventory then return false,"MISSING_SERVICE:Inventory"end
  self.started=true;return true
end
function Controller:read_bag(owner_id)
  return self.context.services.Inventory:read_snapshot(self:request("bag_read",{owner_instance_id=owner_id or "player_local"}))
end
function Controller:read_container(container_id)
  return self.context.services.Inventory:read_snapshot(self:request("container_read",{container_id=container_id}))
end
function Controller:use_item(item_id)
  local id=self.context:next_request_id("inventory_use")
  if self.disposed then return result(false,"DISPOSED",id)end
  if not self.started then return result(false,"NOT_STARTED",id)end
  if self.context.state.phase~="EXPLORE"then return result(false,"INVALID_PHASE",id)end
  local snapshot=self:read_bag()
  if not snapshot.ok then return snapshot end
  local item
  for _,entry in ipairs(snapshot.data.bag.items or {})do
    if entry.id==item_id and entry.count>0 then item=entry;break end
  end
  if not item then return result(false,"ITEM_NOT_OWNED",id)end
  if item.entity_id=="item_heal_small"and self.objects.heal then
    return self.objects.heal:use({request_id=id,user_instance_id="player_local",item_instance_id=item_id})
  end
  return result(false,"NO_USE_HANDLER",id,{entity_id=item.entity_id})
end
function Controller:update(dt)
  -- Injected object controllers are updated by the round driver, not twice here.
end
function Controller:dispose()
  if self.disposed then return end
  self.started=false;self.disposed=true;self.objects={}
end
return Controller
