# 公共 Lua 挂接约定 · 0.2.0

> 历史规划基线：本文保留初始空白项目的目录、职责与接口约定。文中的“全部待实现”“NOT_IMPLEMENTED”“未开始”等状态描述属于当时基线，不是当前 Demo 实现状态。仔仔搜打撤1.0 的实际代码能力及限制见[根 README](../README.md)与[公共主框架](../gameplay/core/README.md)，最新验收见[Demo 状态](demo_scope.json)。原生自动QA两轮各17项、手动A/D移动/UI拾取/撤离/重开（含死亡怪物复活）、默认速度/胶囊组件回读及Inspector读入70/90抽样已通过；其余参数/组合以离线校验为准。自然手动战斗、四房完整遍历及胶囊物理尺寸独立测量仍待专项验收。这不代表正式美术、多人或完整项目完成。

以下为初始规划时的服务外观，基线状态为全部待实现；当前 supported/partial/unsupported 以公共主框架清单为准。它不是仔仔编辑器现成API。`gameplay/core/service_api.lua`固定方法名，Adapter把经实测的编辑器能力映射到这些方法。业务包通过`context.services`调用，不跨包读取另一个controller。

统一使用Lua冒号调用，例如`context.services.Navigation:find_path(request)`。所有方法接收一个request表，返回一个Result表：`{ok, reason, request_id, data}`。读请求也遵循同一结构。异步结果由Adapter包装成可订阅的任务句柄，`data.task_id`用于取消，最终结果仍携带request_id；回调绑定run_id，旧局结果失效。

| 服务 / 方法 | 请求中的关键字段 | 返回data / 责任 |
|---|---|---|
| Characters:read_snapshot | run_id、instance_id | 当前HP、防御、存活、属性版本，只读 |
| Characters:spawn | request_id、run_id、instance_id、entity_id、position_m | 初始化实例；基值来自core/config或对象definition |
| Characters:apply_modifier / remove_modifier | request_id、run_id、instance_id、source_instance_id、modifier_id | 武器或道具临时效果按来源去重，结束恢复，不把临时值写回定义 |
| Combat:try_begin_attack / cancel_attack | request_id、run_id、source_instance_id、attack_id / attack_instance_id | 程序校验公共请求并分配攻击实例ID；策划controller管理攻击时序与取消表现 |
| Combat:try_apply_damage | request_id、run_id、attack_instance_id、target_instance_id、tick_index、hit_evidence | 从定义取伤害、统一减免/免疫/去重；调用方不任意传HP数值 |
| Combat:try_heal | request_id、run_id、user_instance_id、item_instance_id | 治疗与药品消耗一起提交；满血/失效不扣药 |
| Inventory:read_snapshot | run_id、owner_instance_id | bag/equipment、数量、电量、耐久、版本 |
| Inventory:try_transfer | request_id、run_id、from_id、to_id、item_instance_id、count、expected_versions | 原子转移；容量/权限/距离失败原样保留 |
| Inventory:try_equip | request_id、run_id、owner_instance_id、item_instance_id、slot_id | 装卸原子变更；槽位读取core/config |
| Inventory:try_consume | request_id、run_id、item_instance_id、effect_request_id | 仅合法效果提交过程调用；不允许UI先扣数量 |
| Movement:move_to / stop | request_id、run_id、instance_id、goal_m、speed_mps / task_id | 程序提供逻辑根位移与碰撞底层；策划controller决定巡逻、追逐、攻击与回退 |
| Movement:read_position | run_id、instance_id | 位置与朝向；不能借此绕过失视记忆规则 |
| Navigation:find_path / cancel_query | request_id、run_id、instance_id、from_m、to_m、route_id / task_id | 路点或NO_PATH；无导航能力返回UNSUPPORTED，不假装直线可通行 |
| Interaction:query_target / try_begin / cancel | run_id、user_instance_id、target_instance_id；操作另带request_id | 距离/LOS/状态、交互任务与取消结果 |
| Session:read_snapshot / try_start | run_id；开局另带request_id、map_entity_id | 局内状态、总时间、唯一局次 |
| Session:try_extract / try_finish | request_id、run_id、user_instance_id、exit_instance_id / terminal_reason | 撤离或终局请求；死亡/超时/撤离统一仲裁一次 |
| Assets:resolve / instantiate | resource_id；实例化另带request_id、run_id、entity_id、instance_id | registry相对路径→平台资源句柄；无文件/权限返回明确失败 |
| Assets:play_clip / resolve_socket / destroy | run_id、instance_id、clip_id / socket_semantic / request_id | 本包动作与语义插槽；销毁释放模型实例 |
| UI:open_view / close_view / publish_snapshot | run_id、view_id、owner_instance_id、snapshot_version | 显示/关闭/刷新权威快照，不自建库存 |
| UI:subscribe / unsubscribe | run_id、view_id、event_name、callback / subscription_id | 订阅句柄；关闭/死亡/离局必须取消 |

命名分工：目录、脚本文件、模块路径、操作方法及请求字段使用snake_case；内容数值字段沿用已有约定如`maxHp`、`windupSec`，不能自行重命名。entity_id对应目录里的定义ID，instance_id对应每局实例，request_id对应一次操作；三者不得混用。

血量、库存、攻击消耗与结局只由程序的共享服务提交。模型、骨骼动作、巡逻/索敌/寻路决策、攻击时间窗和受击效果，由策划在同一个对象包的controller中实现；程序只提供底层能力并合入，不接管专属AI。必要的新方法先在`docs/change_requests/`提案，更新此契约、service_api、Adapter、所有受影响包及验收，再发布新版本。职责修订0.3.0，现有代码接口格式保持0.2.0。

历史基线记录：当时骨架只有方法名检查，Adapter未映射SDK、对象start拒绝NOT_IMPLEMENTED；当前已编写的Demo对象不再沿用这一状态。即使注入带齐方法的测试替身，也只证明挂接外观，不能据此验收游戏。
