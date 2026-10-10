# ui_main · 程序共享原生 Demo 界面

归属PRG-INVENTORY及比赛/结算总体系统，代码类别PKG-INVENTORY；代码/manifest0.2.0，职责0.3.0。本目录不是独立UI整包需求。原生布局/按钮/快照读取已编写并完成离线加载/关联检查；真实宝箱/背包/结果显示、UI拾取/满血拒绝/重开按钮已通过手动预览。正式UI设定/图标/atlas尚未交付，manifest保持planned。

## 实际入口与内容

模块gameplay.packages.ui.ui_main.controller。当前UI.new(context,dispatch)接收程序动作调度函数，不是Base的instance对象样板；start创建原生Canvas/缩放器/面板/按钮，update读取公共state，dispose销毁本次运行UI根。

包含HP/时间/怪物状态、E交互/F铲击/B背包/H用药按钮、属性面板、宝箱逐项/全部拾取、背包药品使用、用药/撤离读条、结果与重新开始，以及“验证Demo”按钮。按钮只向Demo dispatch发请求；宝箱/武器/药品专属行为来自策划controller，HP/库存/终局由公共服务提交。

UI服务open_view/close_view映射本界面；publish_snapshot刷新当前面板。subscribe只登记句柄，通用订阅callback事件派发尚未实现，不能写成完整消息总线。

## 资源与接入边界

当前是程序直接创建Unity UI/Text/按钮的占位界面，不需要GLB、骨骼或动作clip；不要把武器动画/模型导入清单复制成UI验收要求。未来正式图标与界面素材留同包materials/ui_atlas.png并按manifest登记；planned路径不是真实资源文件。

程序原生UI接入与Adapter一起属于程序层。策划对象不得引用UI内部GameObject或直接改公共快照。面板打开记录ui_view，由Adapter阻断世界移动；已手动关闭面板后移动并撤离；所有键盘/鼠标焦点边界及无穿透仍需专项预览。

## 验收

原生HUD、属性、宝箱、背包和结果面板已显示。手动打开宝箱/全部拾取/查看背包通过，满血用药拒绝且数量保持×2；回绿区3秒撤离后显示310价值和run_1:result，单次点击“重新开始”恢复新局，包含已死亡方块复活。见[Demo证据索引](../../../../README.md)。

尚需独立验收全部E/F/B/H/Esc快捷键、逐项拾取按钮、模态输入无穿透、异常反馈、设备字体/尺寸适配及自然人工战斗操作。QA按钮通过原生Teleport定位功能测试，不直接修改HP/库存；自动两轮各17项通过与手动路线分别记录，不以两者宣称全分支或全设备UI完成。
