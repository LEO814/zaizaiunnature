---@id ed22f5e1-e7bd-4bfe-9d47-f535a7ad2bee
---@referenceName player_attributes.lua
---@start
---@var playerMaxHp:number=100
---@name 玩家最大血量（HP）
---@desc 公共角色最大血量；不直接修改当前局HP
---@range 1,10000,1
---@group 角色／血量
---@var playerStartHp:number=100
---@name 玩家出生血量（HP）
---@desc 出生血量；GetProfile限制为不超过最大血量
---@range 1,10000,1
---@group 角色／血量
---@var playerWalkSpeedMps:number=3.2
---@name 行走速度（米/秒）
---@desc 映射公共角色行走速度
---@range 0.1,20,0.1
---@group 角色／移动
---@var playerSprintSpeedMps:number=5
---@name 奔跑速度（米/秒）
---@desc 映射公共角色奔跑速度
---@range 0.1,30,0.1
---@group 角色／移动
---@var playerCrouchSpeedMps:number=1.6
---@name 蹲行速度（米/秒）
---@desc 映射公共角色蹲行速度
---@range 0.1,15,0.1
---@group 角色／移动
---@var playerJumpHeightM:number=0.8
---@name 跳跃高度（米）
---@desc 跳跃高度；不是初速度，实际控制器由Adapter映射
---@range 0,5,0.05
---@group 角色／移动
---@var playerColliderRadiusM:number=0.35
---@name 碰撞半径（米）
---@desc 胶囊逻辑碰撞体半径，修改后需验证门洞和阻挡
---@range 0.05,2,0.01
---@group 角色／碰撞
---@var playerColliderHeightM:number=1.8
---@name 碰撞高度（米）
---@desc 胶囊逻辑碰撞体总高度，入口校验高度与半径关系
---@range 0.2,5,0.05
---@group 角色／碰撞
---@var playerColliderCenterY_M:number=0.9
---@name 碰撞中心Y（米）
---@desc 相对角色逻辑根的胶囊中心Y
---@range 0,3,0.05
---@group 角色／碰撞
---@var playerSpawnProtectionSec:number=3
---@name 出生保护时间（秒）
---@desc 出生后伤害保护，由公共战斗层执行
---@range 0,30,0.1
---@group 角色／战斗保护
---@var playerHitInvulnerabilitySec:number=0.2
---@name 受击保护间隔（秒）
---@desc 有效受击后短暂保护，公共层统一裁决
---@range 0,5,0.05
---@group 角色／战斗保护
---@var playerInteractionDistanceM:number=2.2
---@name 最大交互距离（米）
---@desc 宝箱/道具交互最大距离，仍需LOS验证
---@range 0.1,10,0.1
---@group 角色／背包与交互
---@var playerBagSlots:number=12
---@name 局内背包格数
---@desc 整数容量；只改变公共库存容量，不创建另一份背包
---@range 1,64,1
---@group 角色／背包与交互
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
  local max_hp = number(playerMaxHp, 100, 1, 10000, true)
  local start_hp = number(playerStartHp, 100, 1, 10000, true)
  if start_hp > max_hp then start_hp = max_hp end
  return {
    player = {
      maxHp = max_hp,
      startHp = start_hp,
      walkSpeedMps = number(playerWalkSpeedMps, 3.2, 0.1, 20, false),
      sprintSpeedMps = number(playerSprintSpeedMps, 5, 0.1, 30, false),
      crouchSpeedMps = number(playerCrouchSpeedMps, 1.6, 0.1, 15, false),
      jumpHeightM = number(playerJumpHeightM, 0.8, 0, 5, false),
      colliderRadiusM = number(playerColliderRadiusM, 0.35, 0.05, 2, false),
      colliderHeightM = number(playerColliderHeightM, 1.8, 0.2, 5, false),
      colliderCenterY_M = number(playerColliderCenterY_M, 0.9, 0, 3, false),
      spawnProtectionSec = number(playerSpawnProtectionSec, 3, 0, 30, false),
      hitInvulnerabilitySec = number(playerHitInvulnerabilitySec, 0.2, 0, 5, false),
    },
    interaction = {maxDistanceM = number(playerInteractionDistanceM, 2.2, 0.1, 10, false)},
    inventory = {bagSlots = number(playerBagSlots, 12, 1, 64, true)},
  }
end

return {GetProfile = GetProfile}
