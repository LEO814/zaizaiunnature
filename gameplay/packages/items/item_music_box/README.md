# 音乐盒 · 整包需求

- 对象ID：`item_music_box`；归属需求：`DES-TOOL`；代码类别：`PKG-TOOL`；代码格式：`0.2.0`，职责修订：`0.3.0`。
- 负责方：策划（完整模型、动作与Lua专属行为）。美术提供设定；程序将策划成果合入总体系统。
- 当前状态：空白样板，模型/资源未交付，Lua行为未实现，编辑器验收未执行。
- 本对象目录：`gameplay/packages/items/item_music_box/`。只修改本包，读取共享框架。

## 同包交付

1. 模型（model/main.glb，可包含骨骼与动作；可选源文件保留在model/source.blend），材质放materials/；动作优先同一GLB，分文件导出时在manifest逐项登记。
2. `definition.lua`与`controller.lua`，分别保存只读定义和实例行为。使用/读条/取消/冷却、效果与消耗、实例电量/数量、使用动作与提示均在本对象包。

`manifest.json`负责声明路径、动作和服务依赖；本README说明挂接与实际检查结果，两者随模型/Lua一起交付，不再分别立项。

每个动作的resourceId必须指向本包声明的模型或动画资源；武器的角色动作保存在animations/player_actions.glb并按角色骨骼契约挂接。额外贴图可放materials/<snake_case>.png，场景分块可放model/chunks/<snake_case>.glb，均登记本包资源ID。

## 文件与引用

| 文件 | 作用 |
|---|---|
| definition.lua | 属性、机制、动作引用；当前值是调参起点 |
| controller.lua | `new(context, instance)`入口；当前start拒绝NOT_IMPLEMENTED |
| manifest.json | 对象/模块/资源/clip ID登记；当前planned |
| model/、animations/、materials/ | 同对象模型、动作与材质/界面资源 |
| tests/ | 本对象未来逻辑/接入验收证据 |

Lua模块名：`gameplay.packages.items.item_music_box.controller` 与 `gameplay.packages.items.item_music_box.definition`。公共引用通过 `gameplay.core.*` 与 context.services，不使用另一套目录或拼接路径。

## 公共挂接

所需服务：Characters, Combat, Inventory, Interaction, Assets, Session。服务是拟议接口，实际SDK需Adapter验证；不能直接改其他对象HP、库存和终局。程序提供位移、路径查询和伤害提交；策划决定巡逻/追逐/索敌/路径失败回退、攻击窗口与受击表现，程序负责合入。

先读根README、docs/directory_contract.md、docs/package_contract.md和本包manifest。仅完成这个对象的模型与Lua，不新增独立“骨骼需求/移动需求/攻击需求”。需要公共能力扩展时提交docs/change_requests/；注册变化执行tools/sync_registry.py再检查。

## 验收（全部待执行）

- 模型尺寸/轴向/材质/碰撞、声明动作与真实导入一致。
- 定义与实例隔离；行为正确连接共享属性和服务。
- 使用/读条/取消/冷却、效果与消耗、实例电量/数量、使用动作与提示均在本对象包。
- 停止/死亡/取消/局结束/重开清理本包动作、订阅和任务。
- 包内模型/代码引用可解析，registry一致；有真实预览日志才能标验收通过。
