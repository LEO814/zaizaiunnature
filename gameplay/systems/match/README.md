# 比赛与房间匹配 · 本地开局已编写

PRG-MATCH，程序负责。职责0.3.0；固定代码/接口0.2.0。controller.lua 已可加载，当前实现本地单玩家开局与关停；纯Lua流程已有离线检查；原生开局、单次点击重开及击杀后重开已通过。联网房间/匹配未实现。

## 当前实现

Match.new(context)注入Session，start生成唯一请求并调用Session:try_start，close禁止后续开局。唯一run_id和公共状态重置归Session；Demo入口将地图交给round_setup，不在匹配系统实现怪物AI、角色动作或物品效果。

模块为gameplay.systems.match.controller。正常新局只能从LOBBY或FINISHED开始；进行中返回ROUND_ALREADY_ACTIVE。QA重置先走已有try_finish(terminal_reason=quit)，再从正常开局流程重建；不增加固定API签名。

## 尚待完整需求

创建/加入/离开线上房间、成员/准备/取消、权限、多人名单分配、匹配UI、断线/重连和多玩家同步均未实现。本地start不代表房间匹配完成，也不以模拟成员证明线上能力。

## 验收

本地开局与局次初始化已通过离线检查和真实原生预览。单次点击结果页“重新开始”后，玩家恢复100HP、方块恢复60HP、背包清空、计时和出生点复位；死亡方块0→60HP也经重跑确认，见[重开证据](../../../docs/evidence/restart_after_monster_death.png)。

旧局请求隔离有离线集成覆盖；主动退出/异常UI错误及多人场景尚需独立原生验收。本模块不引用其他对象controller，新增能力按docs/change_requests发布。
