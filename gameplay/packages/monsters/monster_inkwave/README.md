# 墨潮巡猎者 · monster_inkwave

主责：策划怪物对象整包；程序负责公共服务、真实编辑器资源绑定与生成。代码/manifest 格式沿用 `0.2.0`，职责沿用 `0.3.0`。当前状态：模型、动画与 Lua 文件已交付并完成资源/公共服务离线检查，manifest 的 delivered 表示文件交付；原生模型导入、动作、声音及特效的视觉验收以项目集成记录为准，不用纯 Lua 测试替代原生预览。

本对象取自 INKWAVE 的程序化角色与 shooter 武器，并借鉴 BotBrain 的反应延迟、按武器距离攻击、低血退避策略。其涂地、墨水补充/回血、阵营争夺、机器人比赛、复活跳跃、投弹与特殊技能没有进入本对象。`controller.lua` 是本项目公共契约下的 Lua 改造；原作 JavaScript 不会作为第二套运行 AI。

## 文件与来源

`definition.lua` 是只读静态数值；`controller.lua` 只管理本怪物实例的 AI、路线、攻击时间线及表现请求；`manifest.json` 声明实体/模型/动作 ID。唯一运行主模型路径为 `model/main.glb`：最终 Blender 简化导出版本为 7,382,108 bytes，27,952 三角、87 骨骼、1 skin、110 nodes，SHA256 `8fe3a3194c04ff9f8dff56e5a5008e972b8d709720b4e92c0293b704b6d029e0`。同一最终 GLB 的二进制 channel/time/value 与 runtime bank 逐项验证通过。原始骨骼及动画由独立导出流程生成，主 GLB 内嵌以下固定动作：

| 稳定动作 ID | GLB 动作名 | 用途 |
|---|---|---|
| `clip_monster_inkwave_idle` | `idle` | 站立、警觉、巡逻停留 |
| `clip_monster_inkwave_patrol` | `patrol` | 巡逻、搜索、返回 |
| `clip_monster_inkwave_chase` | `chase` | 追逐、短退避 |
| `clip_monster_inkwave_attack` | `attack` | 举枪前摇、枪口反馈与后坐力、收枪 |
| `clip_monster_inkwave_hit` | `hit` | 受击反应 |
| `clip_monster_inkwave_death` | `death` | 倒地、死亡收束 |

AI 概念来源：[INKWAVE BotBrain](https://github.com/ENTROVIA/inkwave-main/blob/main/src/game/bots.js)，武器反馈来源：[weapons.js](https://github.com/ENTROVIA/inkwave-main/blob/main/src/game/weapons.js)，角色模型来源：[character.js](https://github.com/ENTROVIA/inkwave-main/blob/main/src/game/character.js)。原作作者 Jayden Davis，MIT License，原作版权与完整许可须随复制/转换后的模型、声音和实质代码分发；项目集成的第三方记录保留上游来源与版本。特定动画的补制/烘焙属于本次适配，不称原作现成动画文件。

## 与本项目规则衔接

默认 HP 60；巡逻 1 m/s，追逐 3 m/s。首次发现玩家必须同时满足 **7 m 距离、完整 100° 视野及 LOS**，连续可见 0.18 秒后才追逐/攻击；短暂露出后消失不创建持续追踪锁。角色/模型逻辑根采用米单位、+Y 上、+Z 前、脚底根，导航碰撞半径 0.35 m，胶囊高度 1.8 m。

攻击 `primary` 沿用本项目怪物规则：25 HP、3.5 m、100° 攻击范围，前摇 0.55 秒、有效窗 0.25 秒、恢复 0.7 秒，开始间隔至少 2 秒。枪是本对象武器表现；伤害为距离/角度/LOS 验证后的单次命中请求，没有涂地或另起原作弹丸战斗。枪口/墨滴轨迹只提供表现，不能自己扣血。攻击期间停止移动；有效窗口再次检查可见性，每次攻击只提交一个 `tick_index=0`。公共 Combat 再校验窗口、实例、距离、LOS、免疫和去重。跨帧跳过整个有效窗口不补发过期伤害，建议模拟步长不超过 0.1 秒。

只有实际可见时调用 Movement 读取目标点并保存 `last_seen_position`；失视后只跟随该点。失视 1.2 秒后搜索 4 秒，之后返回出生点。目标死亡不再攻击。超过 15 m 追逐边界返回。Navigation 找不到路时停止、重试；巡逻点持续不可达 2 秒后跳过该点，不直线穿墙。

受击通过 Characters 的权威 HP 差值检测，取消攻击/路线并暂停 0.25 秒，发送 hit 表现；之后可被下一状态的动画打断。HP≤34% 且见到威胁时，可沿最后可见威胁的反方向寻路退开 2 m，最多持续 1.5 秒，6 秒内不再触发。退避不会回血，找不到路径则停住。死亡只发送一次 death，清空攻击/路线，不更新其他角色数值。

本怪物仅在 `EXPLORE` / `EXTRACTING` 更新；比赛停止时取消攻击/导航并清目标，已死亡模型保留死亡状态。绑定 `run_id` 改变会停止旧控制器；新局由程序生成新权威角色和新控制器，恢复 HP。`dispose` 取消本对象任务，不负责销毁共享场景或修改比赛规则。

## 接入与表现请求

构造器：`controller.new(context, instance)`。`instance.id` 唯一；Demo 约定 `monster_inkwave_1`，默认目标 `player_local`，可显式给 `instance.target_id`。可给世界坐标数组 `instance.route`，否则围绕出生点左右各 2 m 巡逻。生命周期为 `start` / `update(dt)` / `stop` / `dispose`。

优先读取 `context.definitions.monster_inkwave` 的已验证运行定义，缺该定义才使用静态原型。程序提供的 Inspector 覆盖必须同时用于本控制器和公共 Core，避免 AI 与权威伤害各自采用不同数值。该包不直接读取编辑器全局、不写 HP/clock/phase/玩家位置，不 require 其他包或 Adapter。

依赖七个既有公共服务：Characters、Combat、Movement、Navigation、Interaction、Assets、Session。所有请求都携带 `request_id` 和绑定 `run_id`。模型与骨骼动画播放通过 `Assets:play_clip`；额外表现字段是 Adapter 的可选提示，不新增公共服务签名：

```lua
{
  instance_id = "monster_inkwave_1", -- 只作用于这一实例
  clip_id = "clip_monster_inkwave_attack",
  clip_name = "attack",
  restart = false,
  loop = false,
  monster_feedback = {
    event = "monster_inkwave_attack",
    sound_id = "shoot_shooter",
    fx_id = "muzzle_shooter",
    attack_instance_id = "run_1:attack_1",
    target_position_m = {x = 0, y = 0, z = 0}, -- 最后可见点
  },
}
```

windup 时启动 attack clip 并 `restart=true`；0.55 秒有效窗发送射击声音/枪口反馈但 `restart=false`，避免后坐力触发时重新播放前摇。hit/death 的强制反馈会重启动作。循环仅用于 idle/patrol/chase。FX/声音由 Adapter 绑定本实例的视觉根/枪口；缺声音或骨骼播放能力时必须如实返回限制，不能用颜色方块当成骨骼动画已验收。

恢复段使用 `feedback.recovery`，继续同一 attack clip 的 0.8–1.5 秒尾段，不重新播放射击音/枪口反馈。攻击开始前，仅在当前视野与 LOS 合法时，用已验证 Adapter 的零速 `Movement:move_to` 朝向当前可见点；`speed_mps=0` / `dt_sec=0` 不产生位移，背后或墙后的目标不能据此转向或被重新索敌。

若 Inspector 修改攻击前摇/有效窗/恢复时长，表现层从同一公共 `attack_instance_id` 读取权威时序，再分段映射到烘焙动画的 0–0.55 / 0.55–0.8 / 0.8–1.5 秒；这不会修改伤害时钟。输入覆盖后的 1 秒前摇不能在 0.55 秒提前造成伤害或发送射击效果。

反馈标识：`shoot_shooter` / `muzzle_shooter`、`hurt` / `hit_spark`、`splat` / `ink_burst`；windup 可用 `charge_shooter`。实际启用枪声、怪物自身受伤、死亡与干地脚步；`hit` 命中音效和 `step_ink` 墨地脚步只保留为可选资产，目前未触发，未引入墨地/弹体机制。本版 manifest 不新增未经契约约定的 audio/fx kind。声音及 FX 的物理存放、SDK播放与清理由集成记录说明。

`audio/` 已生成来自原作合成器的单声道 22050 Hz 音效：三种 `shoot_a/b/c.wav`，以及 `hit.wav`、`hurt.wav`、`death.wav`、`step.wav`、`step_ink.wav`。`audio/manifest.json` 保存源提交、许可证、WAV/编码 hash 与实际音量指标；`audio/pcm_bank.lua` 以 G.711 μ-law 编码并在 Lua 解码，通过 `System.Single[]` / `AudioClip:SetData` 上传完整缓冲。原始 WAV 是 PCM16，运行 bank 是有损量化版本。表现层仅播放该怪物一击/脚步音效，使用固定 4 个三维声源，不启动原作音乐或比赛。`audio/audition_bank.wav` 用于听音检查，听音和编辑器实际播放须各自验收。

`gameplay/adapters/zaizai/inkwave_presentation.lua` 播放来自主 GLB 的真实变换曲线：先停止原生 Animator/Animation，再从静态绑定偏移推断坐标反射/单位，使用同一 GLB bank 的原始 rest TRS 建立基准。导入器提前播放动作形成的当前姿态不能充当 rest；切换时未出现的通道和重开均恢复这一明确基准。权威逻辑根不参与曲线复位。GLB 动作顺序以 idle 开头，避免导入器默认播放死亡；即使导入器已经播放死亡，表现层也能恢复直立。FX 使用两条短时枪口/瞄准线和固定 16 个墨滴池，受击短时颜色反馈只修改该模型材质；重开/销毁清理本对象声源、曲线与特效。

表现状态额外报告真实 SkinnedMeshRenderer 数、各 renderer 引用骨骼数之和、头与双脚的世界 Y 高度差，以及枪口方向与逻辑前向的水平 dot。它们提供蒙皮绑定、侧躺和朝向的验收证据；骨骼引用数不是去重骨骼数，诊断本身不会旋转模型或代替实际视觉验收。

编辑器外层逻辑/属性节点名为 `monster_inkwave_actor`；内部 GLB 的原始骨骼/节点名保留，实体 ID 仍为 `monster_inkwave`，实例仍为 `monster_inkwave_1`。属性脚本挂外层，避免内部同名模型根导致 Find 歧义。瞬时 FX 使用独立表现时钟，终局冻结公共比赛 clock 不会留下永久墨滴或瞄准线；真正伤害和攻击姿态分段仍以权威比赛时钟为准。

## 验收

`tests/test_inkwave_monster.py`（仓库根 tests）使用 `lupa.lua51` 与真实公共 state/Characters/Combat/Session、真实空间寻路几何；仅原生变换/动画 SDK 是替身。安装 `requirements_qa.txt` 后运行：

```bash
python tests/test_inkwave_monster.py --save-report gameplay/packages/monsters/monster_inkwave/tests/lua_test_results.json
```

已通过 12 场景 / 230 断言：巡逻导航；背面/遮挡无锁定；短暂可见与反应延迟；25 HP 单次伤害和本怪物反馈；合法可见点零速朝向而无位移；失视只跟最后可见点；跳过攻击窗无补伤害；恢复继续动画尾段而不二次射击；受击取消/死亡一次；低血导航退避无回血；不可达巡逻点；搜索返回；终局、dispose、重开/旧局隔离。详见本包 `tests/lua_test_results.json`。这些结果不证明 GLB 导入、动作视觉、声音或特效真实播放，必须另外在编辑器预览验收。

`tests/test_inkwave_presentation.py` 直接执行真实表现层和真实 bank/解码器，独立从二进制 GLB accessor 抽取期望值验证非关键帧采样；同时验证反射/导入比例、权威攻击时序映射、逻辑根保留、死亡复位、受击闪色、必需骨骼缺失失败、typed PCM 完整上传/失败、固定声源/粒子预算、重开与销毁。仅 Unity 对象作为严格 SDK 替身，不代替真实原生预览。最新结果见 `tests/presentation_test_results.json`；资产/bank/entry 必须在最后一次导出后一起重建并重测。

当前表现层通过 12 场景 / 177 断言，包含真实最终 GLB 的非关键帧采样、1 秒 Inspector 前摇与烘焙姿态分段对应、完整 typed 数字索引 PCM 上传、音效上传失败注入、固定对象预算、终局时钟冻结与受击/重开/销毁清理。新增故障注入从二进制 GLB 读取死亡动作末帧全部通道，覆盖 x/z/无反射与 1/100 平移单位：提前死亡姿态不能污染 idle、巡逻、追逐、攻击、重开的 rest；蒙皮数量、世界高度和枪口朝向诊断不会自行改动观察到的模型。原生音频/粒子/骨骼视觉另列预览证据。

现有 `tests/test_editor_entry.py` 已更新为外层 `monster_inkwave_actor` 与最终 GLB 动态节点的严格 SDK 替身，实际执行真实 57 模块生成入口，不替换本怪物的 Presentation。Lua 5.1 / 5.4 共 20 场景 / 108 断言通过：当前 canonical bundle 一致、三类属性加载/缺失/超时、Inspector 70/90 数值至权威实例及 HUD、实际曲线桥接运行与销毁，以及属性等待期间导入器提前播放死亡后的直立恢复。SDK 蒙皮引用由实际 GLB 的 skin joint 列表生成。结果见本包 `tests/editor_entry_test_results.json`，仍不代表原生序列化/渲染验收。
