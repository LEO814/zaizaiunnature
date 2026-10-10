# 方块巡逻怪 · monster_cube

主责：策划对象整包；程序提供公共服务并在编辑器绑定/生成。状态：原生代理 AI 已编写，Lua 5.1 行为与集成检查通过；真实原生自动QA已验证巡逻/FOV、伤害和击杀，手动重开已确认死亡怪物复活；正式 GLB、骨骼、蒙皮和动画未制作。manifest 与未来模型保持 planned，clips 为空，不能据原生颜色/位移反馈声明已交付正式怪物模型。

## 功能与数值

最大 HP 60；巡逻 1 m/s，追逐 3 m/s；感知 7 m / 完整 100°，首次锁定必须同时满足距离、视野角与 LOS。失视 1.2 秒后搜索最后可见点 4 秒，再返回出生点。失视后不读取实时玩家位置供追踪；墙后或背后不能发起新追逐。

primary 攻击造成 25 HP，前摇 0.55 秒、有效窗口 0.25 秒、恢复 0.7 秒、攻击开始间隔 2 秒、范围 3.5 m。前摇/有效窗口/恢复期间停止移动；有效窗口再次检查当前距离/角度/LOS，只发一次 tick_index=0 请求，公共 Combat 再验证并去重。当前 Demo 严格按公共时钟的有效窗口提交；建议公共模拟步长不超过 0.1 秒，跨过整个有效窗口不补发过期伤害。

受击读取权威 HP 差值触发原生 hit 并取消攻击，暂停 0.25 秒；HP 到零触发一次原生 death，停止路线和攻击。不会直接写 HP、phase、clock、库存或实际对象位置。

## 挂接

controller.new(context, instance) 优先使用 context.definitions.monster_cube 的已校验运行定义（程序从 GetProfile/Inspector 读取），缺该条目才使用本包静态 definition.lua 原型。HP、巡逻/追逐速度、视野和攻击参数均引用同一实例 definition；公共 Core 与 Adapter 使用同一运行定义。用户在逻辑属性面板修改数值后，重新启动预览读取对应值，不需修改静态模块。运行定义按只读配置使用，不写回 Inspector 或静态表。

instance.id 为唯一实例 ID；可提供 instance.route 为世界坐标 `{x,y,z}` 数组。不提供路线时围绕首次出生位置左右各 2 m 巡逻。目标为 player_local。start/update(dt)/stop/dispose 提供完整生命周期。

context.state 提供只读 run_id、clock（秒）和 phase；仅 EXPLORE / EXTRACTING 运行，LOBBY / FINISHED 暂停取消攻击。绑定 run_id 改变会停止旧控制器。context:next_request_id(prefix) 优先生成请求 ID，缺此 helper 用局次+实例+本地序号；所有服务请求包含 run_id/request_id。

服务为项目契约，不是臆造编辑器 SDK：

- Characters:read_snapshot 返回 data.hp/max_hp/alive；缺权威属性不启动。
- Movement:read_position 返回 data.position_m/forward_m；move_to 请求 goal_m/speed_mps/dt_sec，仅公共层执行位移。
- Navigation:find_path 返回 data.waypoints 坐标数组，可返回 task_id；失败时停住重试，巡逻目标持续不可达后跳下个点。绝不直接穿墙移动。
- Interaction:query_target 的 mode=perception，请求 range_m/full_angle_deg/require_line_of_sight，返回 visible/distance_m/angular_valid/line_of_sight。
- Combat:try_begin_attack 返回 attack_instance_id；伤害请求使用 attack_id=primary、tick_index=0 和当前几何证据；cancel_attack 取消实例。
- Assets:play_clip 使用 native_patrol/native_windup/native_attack/native_hit/native_death，由 Adapter 以颜色/位移反馈。不是 GLB 骨骼 clip。
- Session 必须存在并提供 read_snapshot；局次读取以注入 context.state 为准。

公共字段扩展由程序在变更提案登记。控制器只 require 本包 definition，不 require Adapter 或其他对象 controller。

## 资源与责任

model/native_proxy.json 记录已创建编辑器原生方块样件与语义绑定，实际挂接已通过Demo预览；稳定 binding_key 是语义 ID，不猜测平台句柄。model/main.glb 是未来模型路径，目前没有文件。程序负责数量/位置/时间和实例绑定、清场；本控制器负责 AI，dispose 取消任务，不销毁程序预放场景实体。

## 验收

对象与Lua5.1集成已覆盖巡逻、背后/遮挡不锁定、攻击窗口/冷却/单次伤害、有效窗重检、跨过期窗口不补伤害、失视搜索返回、受击取消、死亡一次、phase与run隔离、路径失败/清理、Inspector运行定义/fallback与静态原型不变。完整离线总计13场景/301断言、10项bundle smoke和22项契约检查，见[测试记录](../../../../docs/test_results.json)；SDK空间/视觉以替身注入。

真实原生自动QA两轮各17项，覆盖方块实际巡逻、视野前后区分、25伤害、两次铲击击杀、用药和撤离；[死亡后重开](../../../../docs/evidence/restart_after_monster_death.png)确认方块0→60HP且重新运行。自然手动追逐/搜索/战斗、撤离受击取消、视野表现细节、全地图路径与碰撞仍需专项预览。Inspector实际读入已抽样验证[怪物HP改70](../../../../docs/evidence/inspector_override_monster_70.png)，其余参数/组合以离线校验为准。正式GLB/rig/clip未交付。
