# 仔仔搜打撤1.0 · 原生四房 Demo 与墨潮怪物

本项目实现“出生 → 探索 → 开箱入包 → 战斗/用药 → 撤离或失败 → 结算 → 重开”的本地单玩家四房闭环。本次将原方块测试对象接为 INKWAVE 独立怪物“墨潮巡猎者”，包含真实骨架、shooter 武器、六组烘焙动作及本项目规则下的 Lua AI。接入和验收记录见 [INKWAVE 接入说明](docs/inkwave_integration.md)。

下方既有17项原生验收及280/310带出价值是**此前方块 Demo 的历史基线**，不能当作新模型验收。新增模型的 Blender 简化、真实导入和预览结果单独记录；其他规划模型仍为 planned，多人、仓库、商店和持久化仍未交付。

## 墨潮怪物：当前交付与验收

Blender 实际简化由 38,710 降至 27,952 三角面（减少 27.8%），最终 GLB 为 7.04 MiB，保留 87 根骨骼、武器、材质及 idle/patrol/chase/attack/hit/death 六动作。资产库“墨潮巡猎者_定稿”已真实上传并挂入当前场景，其他节点与比赛配置保留。

[最终编辑器验收](docs/inkwave_native_acceptance.json)：22 项全部通过，含 4 个真实蒙皮网格、87 根共用骨骼的 348 次 renderer 引用、直立巡逻、视野背后不索敌、25HP 攻击、用药、两次铲击击杀和3秒撤离带出280。死亡后单次重开恢复100/60HP、空背包；另行自然 WASD 进入怪物房，观察直立追逐及玩家死亡结算。声音加载与播放事件通过，未独立听测每条音效。

- [Blender 源文件](gameplay/packages/monsters/monster_inkwave/model/source.blend) / [导入 GLB](gameplay/packages/monsters/monster_inkwave/model/main.glb)
- [原生22项结果](docs/evidence/inkwave_native_22_pass.png) / [蒙皮及朝向实测](docs/evidence/inkwave_imported_skin_diagnostics.png) / [最终场景模型](docs/evidence/inkwave_final_editor_model.png)
- 离线 AI/表现/真实生成入口共44场景、515断言通过；原核心13场景301断言、22项交付契约、新14项bundle smoke通过。离线检查与实际编辑器验收分别记录。

## Git 仓库与项目恢复

GitHub 公开仓库：[LEO814/zaizaiunnature](https://github.com/LEO814/zaizaiunnature)。

仓库根同时保存规范源码与当前编辑器项目：`scene.data`、`project.json`、`world-config.json`、`settings/` 和三个 AI 生成配置来自已保存的原生项目。`art/`、`gameplay/`、`docs/`、`tools/`、`tests/`、`dist/`、`scripts/` 保留原目录约定；生成的 Lua 包一并提交，空的规划目录通过 `.gitkeep` 保留。Python 缓存、编辑器运行缓存和旧安装备份不进入 Git，安装器依赖的 `docs/editor_seed_backup/` 保留。

克隆后优先使用仓库中的当前 `scene.data`，不要默认执行安装器重建场景。项目恢复步骤、AI agent 入口和多人 Git 协作规则见[Git 协作与编辑器恢复说明](docs/git_restore.md)。下方17项记录保留此前方块 Demo 基线；墨潮模型以本页当前22项记录为准。跨机器恢复尚未实测。

## 四房 Demo 历史基线与默认参数

| 功能 | 当前代码与默认设定 | 实际验收 |
|---|---|---|
| 角色 | 最大/出生 HP 100；行走 3.2、冲刺 5、蹲行 1.6 m/s；出生保护 3 s，受击保护 0.2 s | 初始100HP与重开复位通过；实际速度回读3.2000000476837、胶囊组件映射通过，物理尺寸未独立测量 |
| 四房地图 | 入口与撤离区、补给区、前厅、怪物区，通过门洞连通；白盒墙体用于遮挡与路径检查 | 原生场景已加载；A/D移动至宝箱并返回撤离通过，四房完整自然遍历与碰撞手感仍待验 |
| 方块怪物 | HP 60，巡逻 1、追逐 3 m/s；视距 7 m、完整视角 100°；失视 1.2 s 后搜索最后可见点 4 s，再返回 | 巡逻位移、FOV前后区分、铲击死亡通过原生自动QA；重开从0恢复60HP已验证，自然手动战斗/搜索另验 |
| 怪物攻击 | 25 HP；前摇 0.55、有效 0.25、恢复 0.7、开始间隔 2 s；距离 3.5 m，有效窗复核距离/角度/LOS | 前摇后25伤害已通过原生QA；撤离受击取消等分支另验 |
| 武器与道具 | 默认铲 30 HP；药品回血 30 HP、读条 1.2 s；满血/失败/取消不消耗；藏品用于带出价值 | 用药、回血与单次消耗、两次铲击击杀已通过原生QA；正式动作待制作 |
| 宝箱与背包 | 宝箱预放藏品 1 份与药品 2 份；局内背包 12 格；首次内容与数量转移统一提交 | 自动转移与手动全部拾取/背包刷新通过；满血用药拒绝后仍保留药品×2，满包等分支已离线检查 |
| 比赛与结算 | 默认 600 s，撤离读条 3 s；离区/受击取消；死亡/超时/撤离统一裁决并只结算一次 | 自动QA：3秒撤离/280价值/结算幂等；手动：310价值与重开复位通过，死亡/超时人工流程仍待验 |
| HUD/面板 | HP/时间/怪物状态、宝箱/背包、公共属性、结果和重新开始；程序占位界面 | 手动宝箱/背包/结果按钮和重开通过；全部快捷键、焦点边界与设备布局适配仍待验 |

这些是 Demo 调参起点。房间匹配、局前背包、仓库、商店、持久化、真实多人、比赛音效系统及完整正式美术仍待实现，本地开局/局内背包不能替代它们。

## 操作与人工验收路线

| 按键/按钮 | 动作 |
|---|---|
| WASD | 使用原生角色移动 |
| Shift / Ctrl | 请求冲刺 / 蹲行速度；行走默认速度已实际回读，冲刺/蹲行手感另验 |
| E / 交互 | 靠近宝箱打开；靠近绿色撤离区域发起撤离 |
| F / 铲击 | 面向可命中的怪物，按铲攻击时间线提交命中 |
| B / 背包 | 打开/关闭局内背包 |
| H / 用药 | 尝试使用背包中的药品 |
| Esc / 关闭 | 关闭面板并恢复世界输入 |
| 角色 / 怪物属性 | 查看本局公共参数与 HP 挂接 |
| 验证 Demo | 启动原生服务自动验收，定位跳转仅用于测试导航，不直接改 HP/库存 |
| 重新开始 | 结束后通过正常开局流程建立下一局 |

已完成的手动路线为出生后使用 A/D 移动至宝箱，通过 UI 打开并全部拾取，查看背包，满血尝试用药而不消耗，关闭面板、返回绿色区域并撤离，再单次点击重开。怪物战斗和受伤用药目前由原生自动 QA 覆盖。后续人工验收需补四房完整探索、自然索敌/追逐/战斗、死亡或超时、全快捷键及焦点边界。自动 QA 使用原生 Teleport 定位测试点，不直接改 HP/库存，不替代这些自然操作与设备性能检查。

## Inspector 属性：同一配置进入公共层和对象

共 36 个 Inspector 数值字段：角色 13、怪物 21、比赛 2。它们是逻辑属性读取层，不是模型或动画交付。

| 挂接节点 | 规范源码 | 固定 UUID | 配置输出 |
|---|---|---|---|
| player_default | gameplay/adapters/zaizai/player_attributes.lua | ed22f5e1-e7bd-4bfe-9d47-f535a7ad2bee | player、interaction、inventory 片段 |
| monster_inkwave_actor | gameplay/adapters/zaizai/monster_attributes.lua | 63480fdf-d72b-48cc-9a5a-583a92702ea9 | 怪物属性、移动、sense、attacks 片段 |
| demo_root | gameplay/adapters/zaizai/match_attributes.lua | b6a67278-5cf1-4f71-89c4-925ebcdd41a4 | roundDurationSec、extractionHoldSec |

选中节点的逻辑属性面板调整数值，重新启动预览时入口读取 GetProfile，做白名单和组合规则校验，再形成运行 config / definitions。怪物 controller、公共 Characters/Combat 和 Adapter 共用 context.definitions.monster_inkwave；运行 HP/目标/冷却不写回静态定义，局内“重新开始”沿用本次预览已读取的配置。

原生父入口 Start 可能先于三个属性子脚本初始化。现已改为 Start 只创建待启动实例，首次及后续 Update 等待 player / monster / match 三份 GetProfile 全部就绪后才初始化赛局；属性读取累计120次尝试仍失败时明确报错，不静默用默认值掩盖缺失脚本。

属性脚本的数值字段未注入时使用当前默认值；整个属性脚本缺失或尚未就绪则等待/报错。角色出生 HP 不高于最大 HP；胶囊高度不小于直径；怪物开始间隔不短于前摇+有效+恢复总时长。完整字段/默认值见[Inspector 使用说明](gameplay/adapters/zaizai/attributes_README.md)。

原生预览已确认默认行走速度写入/回读为 3.2000000476837，胶囊组件映射及回读成功，见[运行属性证据](docs/evidence/runtime_attributes.png)。这证明组件接入，胶囊尺寸对应的实际物理量尚未独立测量。Inspector 实机抽样已通过：[怪物最大HP改为70](docs/evidence/inspector_override_monster_70.png)后HUD显示70；[玩家出生HP改为90](docs/evidence/inspector_override_player_90.png)后HUD显示90/100。其他字段及组合目前以离线校验为准，未逐项完成原生效果验收。抽样结束已恢复玩家100/怪物60并保存。跳跃高度 0.8 m 是当前场景原生控制参数基线；动态 Inspector 跳高调整仍需同步场景配置，不能只凭面板字段宣称已生效。

## 源码与原生挂接双路径

```text
gameplay/demo.lua                      程序：Demo 组装/输入/验收调度
gameplay/core/                         程序：权威HP/库存/局次与公共服务
gameplay/adapters/zaizai/               程序：SDK映射与Inspector属性
gameplay/systems/                      程序：开局/生成/背包/结算
gameplay/packages/                     策划：角色/怪物/武器道具/宝箱完整Lua
  monsters/monster_cube/               保留的旧方块回归测试包
  monsters/monster_inkwave/             独立模型、动作、Lua与专属音效
  environment/map_demo/                同一地图定义供几何与导航读取
  ui/ui_main/                          程序：共享占位界面
art/                                  美术：三个专题设定，正式设定仍待交付
tools/build_editor_bundle.py           从规范源码生成原生运行脚本
scripts/modules/demo_entry.lua         派生入口，固定UUID挂demo_root
scripts/modules/*_attributes.lua       规范Inspector脚本的派生副本
docs/demo_scope.json                   Demo范围与预览状态
```

**规范源码在 gameplay；原生运行入口在 scripts/modules。**修改行为或属性先改规范源码，再执行构建工具；不要在派生 demo_entry.lua 中直接补另一份玩法。入口内 ProjectRequire 只解决模块加载，世界/角色 SDK 调用集中在 Adapter，ui_main 承担程序原生 UI 接入；策划对象 controller 不引用编辑器全局。脚本安装/节点绑定和真实资源权限仍必须在编辑器核对。

原目录/代码/manifest 契约保留 0.2.0；职责文档修订为 0.3.0。公共接口仍为 9 个服务、34 个固定方法；Demo 新字段/原生占位行为按变更记录说明，不因“Demo 已编写”虚构 API 升级或平台能力。

- [目录与引用规范](docs/directory_contract.md)：统一 entity_id、模块路径与资源引用。
- [职责与交付契约](docs/package_contract.md)：美术提供完整设定包；策划实现对象模型/动作/Lua；程序合入并实现总体比赛、库存和结算。
- [公共 Lua 接口](docs/service_api.md)：对象通过 context.services 调用公共层，不自建 HP/库存。

程序公共 Combat 负责合法性、攻击实例、伤害/治疗提交及去重；策划 controller 负责巡逻、索敌、搜索、路线决策、攻击窗口、受击和对象专属状态。程序 Spawn 决定数量/位置/时间，不能把怪物 AI 搬入总体生成系统。

## 构建与验证

在有 Python 3 的项目根目录执行：

```bash
python3 tools/sync_registry.py
python3 tools/validate_packages.py
python3 tools/build_editor_bundle.py
```

有 Lupa 2.6 / Lua 5.1 的独立 QA 环境时可运行：

```bash
python3 -B tests/test_demo_runtime.py --json
python3 -B tests/smoke_lua_bundle.py --json
python3 -B -m unittest discover -s tests -p test_package_contract.py -v
python3 -B tests/test_editor_entry.py --json
```

现有离线基线记录为 **13 个集成场景 / 301 个断言、10 项 bundle smoke、22 项目录/交付契约检查**，详见[测试结果](docs/test_results.json)。集成测试使用真实公共状态、对象控制器及地图数学几何，SDK空间/视觉操作注入替身；这组结果不等于原生渲染或物理验收。启动次序修复后的[独立入口专项结果](docs/editor_entry_test_results.json)另行记录：52个打包模块在Lua5.1/5.4下共18项测试、92个断言全部通过，覆盖Start延迟、三份属性就绪、120次缺失/读取失败报错、Inspector值传播及销毁清理；Unity/Douyin SDK对象使用替身。随后恢复默认值、保存、重新打开，最新入口的最终原生QA仍17项通过，见下方单独记录。

| 真实编辑器证据 | 已通过范围 |
|---|---|
| [最新入口最终QA](docs/evidence/editor_qa_final.png) | 属性启动次序修复、默认100/60恢复、保存并重新打开后，17项全部通过、带出280、run_2:result；独立于下方历史两轮 |
| [历史首轮QA](docs/evidence/editor_qa_success.png)、[历史重复QA](docs/evidence/editor_qa_repeat.png) | 修复启动次序前的两轮各17项：初始属性、巡逻、FOV前后区分、宝箱库存、满血拒绝用药、受伤回血/一次消耗、铲击伤害/击杀、3秒撤离、重复结算幂等；各带出280，结果为run_2:result / run_3:result |
| [手动开箱](docs/evidence/manual_chest.png)、[背包](docs/evidence/manual_inventory.png)、[撤离](docs/evidence/manual_extraction.png) | A/D移动、UI打开/全部拾取、背包药品×2、满血拒绝且不消耗、手动回绿区后3秒撤离；带出310，run_1:result |
| [最新入口重开](docs/evidence/editor_restart_final.png)、[普通重开](docs/evidence/manual_restart.png)、[击杀后重开](docs/evidence/restart_after_monster_death.png) | 单次点击重开，玩家恢复100HP、死亡方块0→60HP、背包清空0/12、比赛时间与出生位置复位；最新入口最终QA后再次通过 |
| [运行属性](docs/evidence/runtime_attributes.png) | 实际行走速度3.2000000476837、胶囊组件映射/回读；未独立测量胶囊物理尺寸 |
| [怪物Inspector抽样](docs/evidence/inspector_override_monster_70.png)、[玩家Inspector抽样](docs/evidence/inspector_override_player_90.png) | 重新启动预览后怪物HP70、玩家出生HP90/100实际生效；只覆盖这两个抽样值，其余组合以离线检查为准 |

自动 QA 用原生 Teleport 定位测试点，手动记录只覆盖上述路线；自然手动怪物战斗、四房完整遍历、死亡/超时人工分支、全快捷键与焦点边界仍待专项验收。Inspector读入已通过70/90抽样，其余字段效果不据此泛称已完成原生验收。正式美术、多人和持久化未完成。最新分项范围见[Demo状态](docs/demo_scope.json)。

预览入口 GetStatus / GetSnapshot / GetQAResults 提供运行状态和自动验收记录；READY 只代表初始化。结论以测试记录及真实截图的已执行范围为准。
