-- Lifecycle shell only. No movement, AI, damage or inventory is implemented.
local Base = {}
Base.__index = Base
function Base.new(context, instance, definition, required_services)
  assert(type(context) == "table", "context required")
  assert(type(instance) == "table" and type(instance.id) == "string", "instance.id required")
  return setmetatable({context=context, instance=instance, definition=definition,
    required_services=required_services, disposed=false}, Base)
end
function Base:start()
  if self.disposed then return false, "DISPOSED" end
  if not self.context.is_ready then return false, "ADAPTER_NOT_READY" end
  for _, name in ipairs(self.required_services) do
    if not self.context.services[name] then return false, "MISSING_SERVICE:" .. name end
  end
  return false, "NOT_IMPLEMENTED"
end
function Base:dispose()
  self.disposed = true
  self.context = nil
end
return Base
