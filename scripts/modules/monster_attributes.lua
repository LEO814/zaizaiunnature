---@id 63480fdf-d72b-48cc-9a5a-583a92702ea9
---@referenceName monster_attributes.lua
---@start
---@var monsterMaxHp:number=60
---@name 怪物最大血量（HP）
---@desc 公共Characters初始化HP，策划controller不直接扣血
---@range 1,10000,1
---@group 怪物／属性
---@var monsterPatrolSpeedMps:number=1
---@name 巡逻速度（米/秒）
---@desc 控制器沿导航返回的路点巡逻
---@range 0.1,15,0.1
---@group 怪物／移动与寻路
---@var monsterChaseSpeedMps:number=3
---@name 追逐速度（米/秒）
---@desc 仅索敌成功或最后可见记忆有效时用于追逐
---@range 0.1,20,0.1
---@group 怪物／移动与寻路
---@var monsterPatrolWaitSec:number=0.6
---@name 巡逻点停留（秒）
---@desc 到达巡逻点后的停留时间
---@range 0,10,0.1
---@group 怪物／移动与寻路
---@var monsterArriveDistanceM:number=0.25
---@name 路点到达距离（米）
---@desc 平面距离小于此值时判定到达
---@range 0.05,2,0.05
---@group 怪物／移动与寻路
---@var monsterPathRefreshSec:number=0.4
---@name 路径刷新间隔（秒）
---@desc 相同目标的路径刷新间隔；不是每帧请求新路径
---@range 0.05,5,0.05
---@group 怪物／移动与寻路
---@var monsterPathFailureRetrySec:number=0.6
---@name 无路径重试间隔（秒）
---@desc 寻路失败先停止，等待后重试
---@range 0.05,10,0.05
---@group 怪物／移动与寻路
---@var monsterPatrolUnreachableSkipSec:number=2
---@name 不可达巡逻点跳过时间（秒）
---@desc 持续不可达后换下一巡逻点，不能穿墙
---@range 0.1,30,0.1
---@group 怪物／移动与寻路
---@var monsterLeashRadiusM:number=15
---@name 出生点活动半径（米）
---@desc 超过活动半径返回出生点
---@range 1,100,1
---@group 怪物／移动与寻路
---@var monsterHurtPauseSec:number=0.25
---@name 受击暂停（秒）
---@desc 有效HP下降后取消当前攻击并暂时停移动
---@range 0,5,0.05
---@group 怪物／受击
---@var monsterSenseRangeM:number=7
---@name 视野距离（米）
---@desc 首次索敌同时要求范围、完整视野角和无遮挡
---@range 0.1,50,0.1
---@group 怪物／视野与索敌
---@var monsterFullAngleDeg:number=100
---@name 完整视野角（度）
---@desc 完整锥角；左右各占一半，不是单边角
---@range 1,360,1
---@group 怪物／视野与索敌
---@var monsterLoseSightGraceSec:number=1.2
---@name 失视宽限（秒）
---@desc 丢失视线仅移动到最后可见点，不能继续实时隔墙追踪
---@range 0,10,0.1
---@group 怪物／视野与索敌
---@var monsterSearchSec:number=4
---@name 失视搜索时间（秒）
---@desc 搜索最后可见点，超时返回出生点
---@range 0,30,0.1
---@group 怪物／视野与索敌
---@var monsterDamageHp:number=25
---@name 单次攻击伤害（HP）
---@desc primary攻击，由公共Combat验证窗口与命中后结算
---@range 0,1000,1
---@group 怪物／攻击
---@var monsterWindupSec:number=0.55
---@name 攻击前摇（秒）
---@desc 原生方块前摇反馈；并非骨骼动画资源
---@range 0,10,0.05
---@group 怪物／攻击
---@var monsterActiveSec:number=0.25
---@name 攻击有效窗口（秒）
---@desc 有效窗口实时复核距离、LOS和角度；单次tick0
---@range 0.05,5,0.05
---@group 怪物／攻击
---@var monsterRecoverySec:number=0.7
---@name 攻击恢复（秒）
---@desc 有效窗口结束后的恢复，期间停止移动
---@range 0,10,0.05
---@group 怪物／攻击
---@var monsterCooldownSec:number=2
---@name 攻击开始间隔（秒）
---@desc 不得短于前摇+有效+恢复总时长；运行入口统一校验
---@range 0.05,30,0.05
---@group 怪物／攻击
---@var monsterAttackRangeM:number=3.5
---@name 攻击距离（米）
---@desc 进入范围且可见才前摇，有效窗口再次检查
---@range 0.1,15,0.1
---@group 怪物／攻击
---@var monsterAttackArcDeg:number=100
---@name 攻击完整角度（度）
---@desc 公共Combat按同一攻击定义复核角度
---@range 1,360,1
---@group 怪物／攻击
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
    maxHp = number(monsterMaxHp, 60, 1, 10000, true),
    patrolSpeedMps = number(monsterPatrolSpeedMps, 1, 0.1, 15, false),
    chaseSpeedMps = number(monsterChaseSpeedMps, 3, 0.1, 20, false),
    patrolWaitSec = number(monsterPatrolWaitSec, 0.6, 0, 10, false),
    arriveDistanceM = number(monsterArriveDistanceM, 0.25, 0.05, 2, false),
    pathRefreshSec = number(monsterPathRefreshSec, 0.4, 0.05, 5, false),
    pathFailureRetrySec = number(monsterPathFailureRetrySec, 0.6, 0.05, 10, false),
    patrolUnreachableSkipSec = number(monsterPatrolUnreachableSkipSec, 2, 0.1, 30, false),
    leashRadiusM = number(monsterLeashRadiusM, 15, 1, 100, false),
    hurtPauseSec = number(monsterHurtPauseSec, 0.25, 0, 5, false),
    sense = {
      rangeM = number(monsterSenseRangeM, 7, 0.1, 50, false),
      fullAngleDeg = number(monsterFullAngleDeg, 100, 1, 360, false),
      loseSightGraceSec = number(monsterLoseSightGraceSec, 1.2, 0, 10, false),
      searchSec = number(monsterSearchSec, 4, 0, 30, false),
    },
    attacks = {{
      id = "primary",
      damageHp = number(monsterDamageHp, 25, 0, 1000, true),
      windupSec = number(monsterWindupSec, 0.55, 0, 10, false),
      activeSec = number(monsterActiveSec, 0.25, 0.05, 5, false),
      recoverySec = number(monsterRecoverySec, 0.7, 0, 10, false),
      cooldownSec = number(monsterCooldownSec, 2, 0.05, 30, false),
      rangeM = number(monsterAttackRangeM, 3.5, 0.1, 15, false),
      arcDeg = number(monsterAttackArcDeg, 100, 1, 360, false),
    }},
  }
end

return {GetProfile = GetProfile}
