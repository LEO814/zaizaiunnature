-- Local single-player start flow. This does not implement online matchmaking.
local Match={}
Match.__index=Match
function Match.new(context)
  assert(context and context.services and context.services.Session,"Session required")
  return setmetatable({context=context,closed=false,sequence=0},Match)
end
function Match:start()
  if self.closed then return {ok=false,reason="CLOSED",data={}} end
  self.sequence=self.sequence+1
  local state=self.context.state
  local request_id
  if type(self.context.next_request_id)=="function" then
    request_id=self.context:next_request_id("match_start")
  else
    request_id="match_start_"..tostring(state and state.run_sequence+1 or 0).."_"..self.sequence
  end
  return self.context.services.Session:try_start({
    request_id=request_id,run_id=state and state.run_id or nil,
    map_entity_id=self.context.map_entity_id or "map_demo"})
end
function Match:close() self.closed=true end
return Match
