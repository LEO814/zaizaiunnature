---@id b6a67278-5cf1-4f71-89c4-925ebcdd41a4
---@referenceName match_attributes.lua
---@start
---@var matchRoundDurationSec:number=600
---@name 比赛总时长（秒）
---@desc 公共时钟继续运行；超时与死亡/撤离统一仲裁
---@range 10,7200,1
---@group 比赛／规则
---@var matchExtractionHoldSec:number=3
---@name 撤离持续时间（秒）
---@desc 离开区域或受击中断；只提交一次终局结果
---@range 0.1,60,0.1
---@group 比赛／规则
---@end
-- Inspector profile only: no model, skeleton, animation or gameplay side effects.
-- Direct named globals are injected by the editor's logic-property environment.
local function number(value, fallback, minimum, maximum, integer)
  local n = tonumber(value)
  if not n or n ~= n or n == math.huge or n == -math.huge then n = fallback end
  if n < minimum then n = minimum end
  if n > maximum then n = maximum end
  if integer then n = math.floor(n + 0.5) end
  return n
end

function GetProfile()
  return {
    roundDurationSec = number(matchRoundDurationSec, 600, 10, 7200, true),
    extractionHoldSec = number(matchExtractionHoldSec, 3, 0.1, 60, false),
  }
end

return {GetProfile = GetProfile}
