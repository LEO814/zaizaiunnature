# 背包、仓库与商店 · 当前局内背包 Demo

PRG-INVENTORY，程序负责。职责0.3.0、代码/接口0.2.0。controller.lua与公共Inventory已实现本地局内背包读取和道具使用调度，离线事务/取消逻辑已有检查；自动库存转移、手动UI全部拾取/背包查看/满血拒绝及新局清空已通过。局前背包、仓库、商店和持久化尚未实现。

## 当前实现

模块gameplay.systems.inventory_meta.controller。new(context,objects)依赖注入策划药品handler；start校验Inventory，read_bag/read_container读取权威快照，use_item确认持有后调用药品对象use，不复制药品效果或直接改HP/库存。无handler的藏品/武器返回NO_USE_HANDLER。

公共Inventory负责12格默认容量、堆叠、版本冲突、距离/LOS/归属、宝箱到背包原子转移与weapon/tool持用槽。药品controller组织读条/中断，Combat:try_heal同时提交回血与消耗；Inventory:try_consume只确认已成功效果回执，禁止界面提前扣物。没有独立装备/护甲对象。

ui_main显示HUD、宝箱/背包/使用读条及结果，界面程序属于总体系统共享部件，不新增“UI整包需求”。objects在Demo驱动器统一update，本系统update不二次推进道具controller；dispose释放调度引用。

## 尚待完整需求

局前装载/带入、仓库、商品价格/购买/货币、退款/异常恢复、保存/版本迁移、结算写回长期库存均待实现。局内结果中的items/value是本次结果，不是已入仓或余额变化。

## 验收

离线集成已覆盖原子数量转移、容量/版本/持有检查、重复开箱、药品治疗提交与取消不消耗。原生自动QA覆盖库存转移及受伤回血/一次消耗；手动UI开箱并全部拾取、背包查看通过，满血用药被拒绝且药品仍为×2，见[宝箱](../../../docs/evidence/manual_chest.png)和[背包](../../../docs/evidence/manual_inventory.png)。手动重开后背包恢复0/12。

逐项按钮、满包/并发冲突原生提示、全快捷键/焦点边界及中断用药的自然人工操作需补专项验收。买卖/仓库/多人保存尚未实现，不能以本地面板代替长期数据提交。
