# 目录、命名与引用规范

> 历史规划基线：本文保留初始空白项目的目录、职责与接口约定。文中的“全部待实现”“NOT_IMPLEMENTED”“未开始”等状态描述属于当时基线，不是当前 Demo 实现状态。仔仔搜打撤1.0 的实际代码能力及限制见[根 README](../README.md)与[公共主框架](../gameplay/core/README.md)，最新验收见[Demo 状态](demo_scope.json)。原生自动QA两轮各17项、手动A/D移动/UI拾取/撤离/重开（含死亡怪物复活）、默认速度/胶囊组件回读及Inspector读入70/90抽样已通过；其余参数/组合以离线校验为准。自然手动战斗、四房完整遍历及胶囊物理尺寸独立测量仍待专项验收。这不代表正式美术、多人或完整项目完成。

职责与需求修订：`0.3.0`；现有 Lua/manifest 引用格式：`0.2.0`。项目：仔仔超现实。先固定命名，再按目录填 README、资源和 Lua。

## 1. 设定、对象实现与总体系统目录

```text
README.md
art/                              美术：完整设定包，三个专题
  characters/README.md             角色形象与动作设定
  monsters/README.md               怪物形象与动作设定
  visual_ui/README.md              武器道具外观/UIUE/图标等设定
docs/
  directory_contract.md
  package_contract.md
  service_api.md                  拟议 0.2.0 公共约定
  change_requests/
gameplay/
  bootstrap.lua
  registry.lua                    自动派生运行注册表
  registry_entries.json           自动派生离线注册表
  package_factories.lua           自动派生模块入口
  core/                           程序：公共参数/权威状态
  adapters/zaizai/                 程序：真实编辑器能力映射
  systems/                        程序：总体规划与未来实现
    match/README.md
    round_setup/README.md
    inventory_meta/README.md
    settlement/README.md
  packages/
    player/<entity_id>/           策划：角色整包
    monsters/<entity_id>/          策划：怪物整包
    weapons/<entity_id>/           与 items 同属武器道具需求
    items/<entity_id>/
    interactables/<entity_id>/     与 environment 同属场景交互需求
    environment/<entity_id>/
    ui/ui_main/                   程序：共享界面，不独立发包
tools/
tests/
dist/                             派生脚本，不人工编辑
```

根目录显示名可中文，Lua 相关路径/脚本统一小写 ASCII snake_case；文档入口为 README.md，仓库相对路径用正斜杠。art 保存设定图/标注，不做正式 GLB/动画/Lua、不进对象 registry。systems 先定目录与 README，不能因目录存在就称系统实现；后续源码遵守同一模块与公共契约。

## 2. 策划对象包结构

```text
gameplay/packages/<group>/<entity_id>/
  README.md           主责、依据设定、挂接、参数、缺口与验收
  manifest.json       ID、格式版本、模块、资源、动作与依赖
  definition.lua      只读静态定义
  controller.lua      完整专属行为与生命周期
  model/main.glb      待制作运行模型，不造空文件
  model/source.blend  可选源模型
  animations/         独立动作或主 GLB 内嵌动作说明
  materials/          材质、贴图/图标
  tests/              行为测试与预览证据
```

模型、骨骼、动作、属性挂接和专属逻辑由策划在同一对象包完成，程序合入公共能力与流程。weapons/items 两物理分类仍是一个策划需求；没有独立装备/护甲对象类型。environment/interactables 同为场景交互整包。UI 运行资源与 Lua 在 ui_main，由程序据美术设定制作/整合。

main.glb/source.blend 是未来约定，不是已有资源；planned 不能写成 delivered，源模型可选且不能列为必需运行资源。静态物件/界面不适用骨骼动画时说明，不伪造 clip。环境组件显式列 manifest，不靠目录遍历顺序。

## 3. 稳定 ID

ID 为 `^[a-z][a-z0-9_]{2,63}$`，全项目唯一。

| 对象 | 前缀 | 示例 |
|---|---|---|
| 玩家 | player_ | player_default |
| 怪物 | monster_ | monster_marmot |
| 武器 | weapon_ | weapon_shovel |
| 道具 | item_ | item_heal_small |
| 宝箱/机关/门 | chest_ / trap_ / gate_ | chest_basic / trap_spikes / gate_exit |
| 地图 | map_ | map_tomb |
| 共享 UI | ui_ | ui_main |
| 资源/动作 | asset_ / clip_ | asset_monster_marmot / clip_monster_marmot_attack |

entity_id、包目录、manifest.id、definition.id 相同；显示名可中文，修改文案不改稳定 ID。运行对象另有 instance.id，攻击/使用/交互另有操作 ID；不能混用。

## 4. Lua 引用与公共能力

根相对路径删 .lua、将 / 改为 .，如 `require("gameplay.packages.monsters.monster_marmot.definition")`。require 只用静态字符串；禁止计算路径、绝对路径、..、扩展名、大小写混用及依赖工作目录。模块返回表，不在 require 时调用未注入全局、生成对象、攻击或改库存。

公共方法/request 用 snake_case；既有 definition 数值沿用 maxHp、windupSec。方法见 core/service_api.lua，语义见[公共约定](service_api.md)。职责改动不新增服务或改签名；匹配/仓库/商店等新 API 需后续变更流程定义，不能猜已有平台调用。

策划 controller 组织攻击时间窗、巡逻/索敌/搜索、路径失败回退和专属交互状态。程序 Combat 仅提交/去重，Movement/Navigation 仅底层位移/路径/LOS映射，Interaction 仅权限/焦点等公共能力。

## 5. 资源与动作引用

manifest 写仓库根相对路径，例如 gameplay/packages/monsters/monster_marmot/model/main.glb。禁止绝对路径、file URI、../ 和个人路径。

| kind | 包内路径 | 用途 |
|---|---|---|
| model | model/main.glb | 主模型，可含骨骼/动作 |
| animation | animations/<snake_case>.glb | 独立动作 |
| texture | materials/<snake_case>.png | 模型/场景/图标贴图 |
| scene_chunk | model/chunks/<snake_case>.glb | 房间/组件 |
| ui_texture | materials/ui_atlas.png | UI 运行素材 |
| source（可选） | model/source.blend | 非最低运行交付 |

clip 格式仍为 `{id, name, role, resourceId}`，resourceId 指向同包 model/animation/scene_chunk，不指贴图、源文件或别包资源。时长/循环等说明留 README/tests，不私增格式字段。武器对应角色动作在 animations/player_actions.glb，clip 引用该动作资源，不能记成武器网格动作；仍同一武器道具需求。

Assets/Adapter 将资源 ID 映射到平台句柄；Git 有文件不代表其他账号有 URI 权限。语义挂点、坐标/导出轴、逻辑根/视觉根在 G0 验证。

## 6. 维护与提交

| 路径 | 维护方 | 其他组边界 |
|---|---|---|
| art 三专题 | 美术 | 引用设定、反馈缺口 |
| 六类对象包（UI 除外） | 策划 | 跨包用 ID/公共服务，不改他包 |
| systems、ui_main | 程序 | 按定义/资源与契约合入 |
| core/Adapter/bootstrap/注册工具 | 程序主框架 | 能力缺口提案，禁止私有 HP/库存替代 |
| docs/change_requests | 提案/审核人 | 写理由/兼容/验收 |

manifest 唯一手写，registry.lua、registry_entries.json、package_factories.lua 由集成人执行 tools/sync_registry.py 派生，禁止手改。core 不 require 特定对象 controller。新字段/API/目录/格式需理由、受影响包、状态归属、取消/失败、迁移及验证。职责 0.3.0 不自动升级代码/manifest 的 0.2.0。

对象模型/动作/Lua/清单/证据同 PR 交付；同一武器道具需求可含多个对象目录。美术各专题可分提交但最终统一设定版本。系统不收特定怪物行为脚本。重命名同步路径、模块、manifest、registry、测试和引用；稳定 ID 非必要不改。大型二进制沿用 Git LFS，同一源模型/主场景由一人编辑。dist 由工具生成，业务修改回源 Lua。
