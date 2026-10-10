# 仔仔编辑器 Adapter · 原生 Demo 接入

职责0.3.0，代码与固定方法格式0.2.0。原生 GameObject、DouyinActor、本地位置/朝向、原生UI和占位反馈接入代码已编写；离线加载/状态与对象逻辑检查已完成。原生自动QA两轮各17项、手动移动/拾取/撤离/重开已通过；这只覆盖当前Demo路径，不代表所有SDK或正式模型完成验收。

## 已编写的实际路径

- Actor：GetLocalActor、Teleport、Immobilize；tick写actor.speed并输出speed_write_ok/speed_readback；默认行走速度实际回读3.2000000476837。
- 碰撞：首次尝试取得原生CharacterController或CapsuleCollider，写radius/height/center；实际预览已确认组件映射与回读成功；物理尺寸未独立测量。
- GameObject：查找/绑定原生方块、宝箱和出口；native_nodes缓存使停用/死亡后的节点可重开，native_baselines恢复缩放/颜色。
- 世界位移：绑定非玩家节点按地图声明墙体进行离散Transform移动；玩家仍由原生控制器移动。
- 感知：同一map_demo墙体几何的数学距离/FOV/LOS检测，未调用平台Physics射线。未登记几何不会自动变成遮挡。
- 路径：同一墙体与网格的同步BFS返回世界坐标路点，非原生NavMesh；无垂直楼层或动态物体自动导航。
- Assets：原生native_*颜色/缩放反馈与宝箱开合；GLB resolve、正式骨骼clip、语义socket未支持。
- UI：服务映射到程序ui_main的原生Canvas/面板与焦点状态；订阅只登记句柄，通用事件派发尚未完成。

九服务34方法的逐项 supported/partial/unsupported 清单见[主框架](../../core/README.md)，不可把ack方法写成完整异步任务服务。

## Inspector与平台派生层

player_attributes/monster_attributes/match_attributes分别提供13/21/2个数值。原生Start先创建待启动实例，Update等待三份GetProfile全部就绪后经入口白名单和组合校验注入config/definitions；属性读取累计120次尝试仍缺失明确报错，不静默fallback。怪物AI、公共伤害和空间感知使用同一运行定义。默认jumpHeightM=.8来自场景原生基线，动态Inspector跳高仍需场景同步；不能只凭字段显示声称跳跃已改变。

规范源码为gameplay；tools/build_editor_bundle.py生成scripts/modules/demo_entry.lua与三个属性脚本副本。入口使用table.unpack or unpack及atan2兼容处理，兼容Lua5.1/5.4的已修代码路径，实际平台版本/加载结果以预览为准。派生入口的Start/Update/OnDestroy组织Demo生命周期；修改行为回到规范源，不在平台副本补第二套实现。

## 策划与程序边界

策划controller只调用context.services，负责移动目标/路径失败回退、索敌/搜索、攻击时序、受击和交互物状态。程序Adapter负责引擎及数学基础能力、权威状态接入，不搬入怪物专属决策。ui_main是程序共享界面，可在自己的程序层创建原生UI；美术设定和正式资源仍待制作。

## 当前验收状态

原生自动QA连续两轮各通过17项；A/D自然移动、手动UI开箱/全部拾取/查看背包、满血拒绝不耗药、回绿区3秒撤离、结果按钮单次重开已通过。死亡后重开也确认方块0→60HP、玩家75→100HP、背包2→0、时间及出生点复位。见[Demo证据索引](../../../README.md)。

[运行属性截图](../../../docs/evidence/runtime_attributes.png)确认速度3.2000000476837、胶囊已映射及组件回读；未独立测量胶囊物理尺寸。Inspector实际读入已通过怪物70HP/玩家出生90HP两例抽样，其余字段/组合仍以离线校验为准。全快捷键/焦点边界、自然手动战斗、四房完整遍历、静态几何与实际墙体全域一致仍待专项验收。自动QA使用原生Teleport定位测试点，不直接写HP/库存；READY只表示初始化。

尚未支持：正式GLB/rig/clip/socket、原生NavMesh、线上匹配/多人/存档、完整比赛音效。失败必须保留明确错误，不用本地模拟冒充线上或SDK验收。新增Demo实体和运行层记录见[变更说明](../../../docs/change_requests/demo_native_proxy.md)。
