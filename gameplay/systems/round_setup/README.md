# 内容分配与生成 · 四房原生 Demo 已编写

PRG-SPAWN，程序负责。职责0.3.0、代码/接口0.2.0。controller.lua 已实现当前四房Demo初始化，离线组装/对象逻辑已检查；原生节点绑定、正常开局与死亡怪物后新局复位已通过。

## 当前实现

模块gameplay.systems.round_setup.controller。start(map)读取同一map_demo的玩家出生点、怪物出生点/巡逻路线、宝箱和出口位置，通过Characters:spawn与Assets:instantiate绑定实例，再ctx:new_entity调用策划controller并start。

当前固定生成player_local、monster_cube_1、chest_demo与exit_demo；宝箱初始化藏品1份和药品2份，玩家获得一把铲并通过统一Inventory:try_equip持用。药品handler/武器controller注入公共context，不由本系统补专属AI、攻击或使用时间线。

Inventory:_create_container/_add_item属于程序初始化辅助，不开放给对象/界面随意复制道具。dispose调用已生成对象的清理入口；原生节点的停用/缓存/重开恢复由Adapter管理，不代表正式模型销毁或资源权限验收。

## 尚待完整需求

多人内容名单与出生分配、按规则随机怪物种类/数量/时机、完整地图/宝藏布点、资源加载失败回退、比赛音效调度和正式资产导入仍待实现。本Demo仅固定场景与一只原生方块怪物。

## 验收

原生玩家、方块、宝箱和出口实例挂接已经运行。两轮自动QA及手动开箱/撤离通过；手动单次重开恢复玩家100HP、死亡方块60HP、背包0/12、出生位置和计时，见[Demo证据索引](../../../README.md)。

四房声明几何的出生点/路线可达性、初始化和请求隔离已有离线集成检查；全地图自然遍历、真实墙体与声明几何全域一致、缺节点/资源失败及多玩家内容分配仍待专项验收。自动QA的原生Teleport用于定位测试点，不替代自然探索。
