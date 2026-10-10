-- Tick after object combat updates so death > timeout > extraction arbitration.
local Settlement={}
Settlement.__index=Settlement
function Settlement.new(context)
  assert(context and context.services and context.services.Session,"Session required")
  return setmetatable({context=context,closed=false},Settlement)
end
function Settlement:update(dt)
  if self.closed then return {ok=false,reason="CLOSED",data={}} end
  return self.context.services.Session:tick(dt)
end
function Settlement:close() self.closed=true end
return Settlement
