# 公共主框架 · 本地 Demo 已编写

职责版本 0.3.0；固定方法/代码/manifest 仍为 0.2.0。Characters、Combat、Inventory、Session 的本地权威 Lua 已实现并完成离线行为检查。原生自动 QA 已连续两轮各通过17项，手动移动/拾取/撤离/重开通过；下方分别说明代码支持范围与验收边界，初始化 READY 不等于全部能力验收通过。

## 职责与状态归属

程序维护共享参数、HP/生命、容器/持用槽、事务和比赛结果；策划对象controller维护巡逻/索敌/搜索/寻路决策、攻击窗口、受击效果及宝箱专属状态。core不require特定对象controller。比赛生成系统按稳定ID调用构造器，不在公共层实现怪物AI。

config.lua 为默认值；原生入口在Update等待三份Inspector GetProfile全部就绪，缺失累计120次尝试明确报错；读取后白名单/组合校验，注入运行 config 与 definitions。方块怪物、公共 Characters/Combat 与 Adapter 共用 context.definitions.monster_cube；运行状态不写回静态定义。每局run_id隔离请求，变更事务带request_id并缓存结果，命中按攻击/目标/tick去重。

## 九服务、三十四固定方法：当前实际支持范围

supported表示源码已实现对应Demo范围；当前已使用的原生路径有截图证据，未逐一证明每个API的全部边界。partial明确能力限制；unsupported会返回错误，不伪装成功。当前公共签名没有升级。

| 方法 | Demo代码状态 | 能力边界 |
|---|---|---|
| `Characters:read_snapshot` | supported / Lua | 读取权威角色快照与公共空间位置 |
| `Characters:spawn` | supported / Lua | 实例、HP、生命/出生保护与玩家背包初始化 |
| `Characters:apply_modifier` | unsupported | 返回 UNSUPPORTED_DEMO_MODIFIER，临时属性加成未实现 |
| `Characters:remove_modifier` | unsupported | 返回 UNSUPPORTED_DEMO_MODIFIER |
| `Combat:try_begin_attack` | supported / Lua | 合法性、攻击实例ID、冷却、武器耐久；时序由策划controller组织 |
| `Combat:try_apply_damage` | supported / Lua | 当前有效窗、范围/LOS/角度证据、减免、去重、死亡及撤离中断 |
| `Combat:try_heal` | supported / Lua | 治疗与一份药品消耗同事务；满血不消耗 |
| `Combat:cancel_attack` | supported / Lua | 取消权威攻击实例，后续命中拒绝 |
| `Inventory:read_snapshot` | supported / Lua | 局内容器、持用槽与版本快照 |
| `Inventory:try_transfer` | supported / Lua | 容器版本、归属、距离/LOS、容量、堆叠与原子数量转移 |
| `Inventory:try_equip` | supported / Lua | 局内 weapon/tool 持用槽；无独立装备/护甲对象 |
| `Inventory:try_consume` | supported / Lua，限治疗回执 | 确认已成功治疗的消耗回执，不再次扣物；未提交效果拒绝 |
| `Movement:move_to` | supported / 原生代理 | 只驱动已绑定非玩家逻辑节点，按同一地图墙体数学阻挡；玩家返回 UNSUPPORTED |
| `Movement:stop` | partial / 同步确认 | 离散移动无持续任务；controller下一步停止请求即可停，非原生导航任务取消 |
| `Movement:read_position` | supported / 原生 | 读取本地Actor或绑定节点的位置/朝向 |
| `Navigation:find_path` | supported / 数学BFS | 同一白盒墙体与网格返回路点；不是原生NavMesh、垂直或动态场景导航 |
| `Navigation:cancel_query` | partial / 同步确认 | 当前查询同步完成，没有异步任务可中断 |
| `Interaction:query_target` | supported / 数学几何 | 范围、完整FOV角和静态墙体LOS；不是平台Physics射线 |
| `Interaction:try_begin` | supported / Demo许可 | EXPLORE与感知许可；专属宝箱/机关状态由策划controller维护 |
| `Interaction:cancel` | partial / 同步确认 | 不持有统一异步读条；对象controller自行取消专属任务 |
| `Session:read_snapshot` | supported / Lua | 局次、phase、时间、撤离与结果快照 |
| `Session:try_start` | supported / 本地Lua | 新run_id、清空上一局公共状态；不实现联网房间匹配 |
| `Session:try_extract` | supported / Lua | 出口距离/LOS、存活、可选目标额度与撤离读条 |
| `Session:try_finish` | supported / Lua | 死亡/超时/撤离/退出条件裁定，唯一结果；未达到终局条件拒绝 |
| `Assets:resolve` | unsupported / 正式资源 | 已登记未来资源返回 PLANNED_MODEL_NOT_IMPORTED；未声明返回 UNKNOWN_RESOURCE |
| `Assets:instantiate` | supported / 原生代理 | 绑定本地Actor或已有GameObject，原生节点缓存供重开；未导入GLB |
| `Assets:play_clip` | supported / 原生反馈 | native_*颜色/缩放与宝箱开合；正式clip返回 PLANNED_ANIMATION，不是骨骼播放 |
| `Assets:destroy` | supported / 原生代理 | 停用非玩家节点、解除实例反馈；原生节点缓存不等于永久删除模型 |
| `Assets:resolve_socket` | unsupported | 原生玩家骨骼/语义插槽尚未验证，返回 UNSUPPORTED |
| `UI:open_view` | supported / 原生UI | 打开程序占位面板并记录公共ui_view |
| `UI:close_view` | supported / 原生UI | 关闭面板/公共ui_view，输入恢复由Adapter驱动 |
| `UI:publish_snapshot` | supported / 当前UI直连 | 刷新当前ui_main；尚未向所有订阅callback派发事件 |
| `UI:subscribe` | partial / 登记句柄 | 缓存订阅请求并返回ID，通用事件派发未实现 |
| `UI:unsubscribe` | supported / 登记注销 | 删除已登记订阅，不代表曾有事件派发 |

完整请求/Result约定见[服务文档](../../docs/service_api.md)，固定名字见service_api.lua。Inventory:_create_container/_add_item、Session:tick 是程序Demo内部初始化/推进辅助，不计入34个公共方法，策划与UI不使用它们绕过权威事务。

## 本地规则与缺口

Characters初始化玩家100HP、方块60HP；Combat仅提交合法窗口内伤害/治疗，策划负责窗口时序。药品治疗与消耗原子提交；try_consume只确认已提交回执。Inventory支持局内容器版本/容量/堆叠/持用，未实现局前背包、仓库、商店和持久化。Session支持本地开局、时钟、撤离/取消和唯一终局，未实现线上房间/多人权限同步。

Settlement在对象战斗update之后推进公共时钟并仲裁死亡→超时→撤离。LOBBY/EXPLORE/EXTRACTING/FINISHED是当前状态；重开创建新公共状态，策划对象收到停用需清理自身任务。

## 验收与维护

[离线测试记录](../../docs/test_results.json)为13个集成场景/301个断言、10项bundle smoke、22项契约检查，覆盖真实权威状态、对象控制器和地图数学几何；SDK空间/视觉部分使用替身。原生自动QA两轮各17项通过，巡逻/FOV、战斗用药、库存、撤离与幂等结算有证据。手动A/D移动、UI拾取/背包、满血拒绝、3秒撤离及重开已通过，重开可把死亡方块0恢复60HP、玩家恢复100HP并清空背包。

默认行走速度写入/回读3.2000000476837，胶囊组件映射/回读成功；物理尺寸未独立测量。Inspector实机抽样怪物70HP、玩家出生90/100HP已生效；其他字段/组合以离线校验为准。自然手动怪物战斗、四房完整遍历、死亡/超时人工分支、全快捷键和焦点边界未完成验收。范围与截图索引见[Demo状态](../../docs/demo_scope.json)。bootstrap只检查接口外观；未支持能力保留明确错误，未来对象仍可为NOT_IMPLEMENTED样板。

公共能力/字段更改在docs/change_requests记录，并核对所有受影响对象。新增Demo实体与平台派生层见[原生代理变更记录](../../docs/change_requests/demo_native_proxy.md)。
