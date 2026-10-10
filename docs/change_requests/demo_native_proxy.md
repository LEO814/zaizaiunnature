# Demo 原生代理与平台运行层 · 变更记录

项目：仔仔搜打撤1.0。职责0.3.0；现有Lua/manifest/固定服务签名仍0.2.0。状态：本地Demo源码已实现、离线检查已执行；原生自动QA两轮各17项通过，手动移动/拾取/撤离/重开和默认组件回读已有证据，完整范围见Demo状态。本记录不声明正式模型/动画或完整线上玩法交付。

## 目的与新增实体

用最小四房闭环验证公共属性、怪物AI、武器/药品、宝箱库存和撤离结算。新增monster_cube（monster）与map_demo（environment）实体，按既有manifest字段与稳定ID注册，registry/factories由manifest派生。

monster_cube使用已放场景原生方块作为运行代理，未来model/main.glb仍planned、clips=[]；native_*反馈为颜色/缩放，非骨骼clip。map_demo提供四房、入口/出口、出生/宝箱/巡逻和墙体几何，导航与LOS读取同一声明，非原生NavMesh或物理射线证明。

## 目录与平台派生层

规范来源：gameplay/demo.lua、core、adapters/zaizai、systems与对象packages。新增平台运行层scripts/modules/，由tools/build_editor_bundle.py从规范源码生成demo_entry.lua及三个Inspector脚本副本，固定UUID绑定demo_root/player_default/monster_cube。

平台入口封装Start/Update/OnDestroy与GetStatus/GetSnapshot/GetQAResults。ProjectRequire打包模块；table.unpack or unpack与atan2兼容处理支持Lua5.1/5.4代码路径，实机已确认父Start先于子属性脚本的初始化风险；Start只创建待启动实例，Update等待三份GetProfile全部就绪后启动，累计120次属性读取尝试仍失败明确报错。gameplay/demo.lua不再静默fallback到默认配置；入口专项离线回归待结果补入。源码调整后重新构建/安装，禁止直接维护第二份派生业务。

## 不改变固定签名的Demo字段

- context.state：公共run_id、clock、phase只读；ctx:next_request_id(prefix)统一请求ID。
- context.definitions.monster_cube：Inspector GetProfile经白名单和组合校验生成的运行定义，controller/Core/Adapter共用。
- Interaction.query_target请求mode=perception/weapon/chest，可附range_m/full_angle_deg/require_line_of_sight；Result.data返回visible/in_range/distance_m/angular_valid/line_of_sight/range_m/full_angle_deg。
- Navigation.find_path Result.data.waypoints为{x,y,z}路点数组，可附task_id；当前同步BFS，cancel_query是同步确认。
- Movement.move_to请求goal_m/speed_mps与dt_sec，实际使用公共步长离散移动；read_position返回position_m/forward_m。
- Assets.play_clip接受native_*或宝箱native_action，Result明确rigged_animation=false/skeletal_animation=false；正式资源与socket继续unsupported。
- Session.try_finish使用既有terminal_reason=quit供退出/QA重置，未新增服务方法。

这36个Inspector字段是配置片段，不修改静态定义或正在运行HP。动态跳高尚需场景同步；默认行走速度实际回读3.2000000476837、胶囊组件映射/回读已成功，物理尺寸未独立测量。Inspector实际读入已抽样验证怪物HP70与玩家出生HP90/100，其他字段/组合以离线校验为准；抽样后已恢复100/60并保存。

## 状态与责任

Characters/Combat/Inventory/Session本地Lua已实现；Movement/Navigation/Interaction/Assets/UI限原生白盒范围，34方法的逐项限制见[core说明](../../gameplay/core/README.md)。属性修改/删除、GLB解析、正式clip/socket未实现；多人匹配/仓库商店/存档/正式美术仍pending。

策划controller拥有巡逻/索敌/搜索/寻路决策/攻击窗口/受击和专属交互状态。程序生成/比赛/库存/结算和Adapter不承接怪物AI；纯Lua权威层只提交合法事务。美术仍提供角色/怪物动作及视觉/UIUE设定包，不以原生代理完成美术交付。

## 验证与兼容

保持0.2.0的9服务34固定方法、manifest字段、ID/路径推导与registry生成。当前[离线测试记录](../test_results.json)为13场景/301断言、10项bundle smoke、22项契约检查。原生自动QA两轮各17项、带出280；手动A/D移动、UI拾取/背包、满血拒绝、3秒撤离带出310与结果按钮重开均通过。死亡方块0→60HP、玩家75→100HP及包/计时/出生复位已确认，默认速度及胶囊组件回读成功，证据见[根README](../../README.md)。

自然手动怪物战斗、完整四房遍历、死亡/超时人工分支、全快捷键/焦点边界及胶囊物理尺寸独立测量仍待专项验收。Inspector70/90抽样证据见[怪物](../evidence/inspector_override_monster_70.png)和[玩家](../evidence/inspector_override_player_90.png)，不泛称其他字段已逐项原生验收。自动QA使用原生Teleport定位测试点，不绕过HP/库存权威服务；不以该结果宣称全地图操作、性能、正式资源、多人或持久化完成。

未支持方法返回明确错误，禁止假成功。后续真正新增API、正式模型/clip、多人或持久化必须单独变更与回归，不以此Demo记录自动宣称兼容。
