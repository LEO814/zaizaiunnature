# Demo Inspector 属性脚本

这三个 Lua 是逻辑属性声明与配置读取层，不是模型、骨骼、动画或玩法交付。默认值来自当前 core/config.lua 与 monster_cube/definition.lua。脚本不依赖 CS/编辑器全局 API，不在加载时修改角色、怪物或比赛状态。

| 脚本 | 固定 UUID | 建议挂接节点 | GetProfile 输出 |
|---|---|---|---|
| player_attributes.lua | ed22f5e1-e7bd-4bfe-9d47-f535a7ad2bee | player_default | player、interaction、inventory 配置片段 |
| monster_attributes.lua | 63480fdf-d72b-48cc-9a5a-583a92702ea9 | monster_cube | 怪物 maxHp/移动/sense/attacks 片段 |
| match_attributes.lua | b6a67278-5cf1-4f71-89c4-925ebcdd41a4 | demo_root | roundDurationSec、extractionHoldSec |

每份头部使用本地已存在脚本的 @id/@referenceName/@start/@var/@name/@desc/@range/@group/@end 格式。Inspector 注入 player/monster/match 前缀全局；GetProfile 读取这些命名变量，未注入时用默认。返回一个新表，不直接写公共 config 或静态 Definition。返回给程序入口进行白名单/组合关系校验，再合并到实际运行参数；怪物控制器和公共战斗/属性/Adapter 必须共用同一 context.definitions.monster_cube。

单字段数值会拒绝 NaN/无穷并夹在注解范围内，HP/背包格数等整数项取整，出生 HP 不超过最大 HP。碰撞高度≥2×半径、攻击开始间隔≥前摇+有效+恢复总时长等组合规则由程序入口统一校验；属性脚本不默默替代总体规则。Inspector变更后重新启动预览时读取；局内“重新开始”沿用本次预览配置，不直接改变正在运行的权威HP。

父入口Start只创建待启动实例，Update等待player/monster/match三份GetProfile全部就绪后才启动；累计120次属性读取尝试仍失败会明确报错。数值字段未注入可使用本脚本默认值，整个脚本未就绪不能静默fallback。

安装器可用 paramsJson={} 读取注解默认，也可写入准确 @var 键名的默认映射（键名表见下面）。UUID 稳定，不因模型名称或目录显示名变化重新生成。

## 默认 Inspector 键值

### player_attributes.lua

```json
{
  "playerMaxHp": 100,
  "playerStartHp": 100,
  "playerWalkSpeedMps": 3.2,
  "playerSprintSpeedMps": 5,
  "playerCrouchSpeedMps": 1.6,
  "playerJumpHeightM": 0.8,
  "playerColliderRadiusM": 0.35,
  "playerColliderHeightM": 1.8,
  "playerColliderCenterY_M": 0.9,
  "playerSpawnProtectionSec": 3,
  "playerHitInvulnerabilitySec": 0.2,
  "playerInteractionDistanceM": 2.2,
  "playerBagSlots": 12
}
```

### monster_attributes.lua

```json
{
  "monsterMaxHp": 60,
  "monsterPatrolSpeedMps": 1,
  "monsterChaseSpeedMps": 3,
  "monsterPatrolWaitSec": 0.6,
  "monsterArriveDistanceM": 0.25,
  "monsterPathRefreshSec": 0.4,
  "monsterPathFailureRetrySec": 0.6,
  "monsterPatrolUnreachableSkipSec": 2,
  "monsterLeashRadiusM": 15,
  "monsterHurtPauseSec": 0.25,
  "monsterSenseRangeM": 7,
  "monsterFullAngleDeg": 100,
  "monsterLoseSightGraceSec": 1.2,
  "monsterSearchSec": 4,
  "monsterDamageHp": 25,
  "monsterWindupSec": 0.55,
  "monsterActiveSec": 0.25,
  "monsterRecoverySec": 0.7,
  "monsterCooldownSec": 2,
  "monsterAttackRangeM": 3.5,
  "monsterAttackArcDeg": 100
}
```

### match_attributes.lua

```json
{
  "matchRoundDurationSec": 600,
  "matchExtractionHoldSec": 3
}
```

## 离线验证

Lupa 2.6 / Lua 5.1 已检查注解格式/唯一稳定 UUID、36个默认值与config/Definition一致、三个配置片段注入、非法数值回退及不改静态数据。项目当前完整离线统计见[测试记录](../../../docs/test_results.json)。

实际原生预览已确认默认参数面板、行走速度回读3.2000000476837，以及胶囊组件映射/回读，见[运行属性证据](../../../docs/evidence/runtime_attributes.png)。物理尺寸未独立测量。Inspector实机抽样已验证[怪物HP70](../../../docs/evidence/inspector_override_monster_70.png)与[玩家出生HP90/100](../../../docs/evidence/inspector_override_player_90.png)随面板改值后生效，随后恢复玩家100/怪物60并保存。其他参数与组合目前以离线校验为准，未逐项完成原生效果验收。动态跳高需同步场景配置。
