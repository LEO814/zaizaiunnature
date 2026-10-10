# INKWAVE 独立怪物接入

本次新增对象 `monster_inkwave`（墨潮巡猎者），只复用 INKWAVE 角色、shooter 外观、角色动作烘焙、专属声音与 AI 决策思路。原作比赛、涂地计分、联网、阵营、墨水回血及投弹没有接入。四房搜打撤的 HP、库存、局次和结算仍由既有公共服务负责。

## 目录与引用

主路径为 `gameplay/packages/monsters/monster_inkwave/`：

- `definition.lua` / `controller.lua` / `manifest.json`：对象数值、AI、稳定资源 ID。
- `model/main.glb`：编辑器用模型，含武器、蒙皮骨架、材质及六组动作。
- `model/source.blend`：可编辑 Blender 源文件。模型简化与大小以 `model/asset_audit.json` / `model/blender_audit.json` 为准。
- `animations/runtime_bank.lua`：从**最终 GLB**提取的相同骨骼曲线；编辑器无原生动画 controller 时由 Adapter 采样，无第二套动作制作。
- `materials/`：原 PBR 烘焙素材。
- `audio/`：原 WebAudio 合成器离线烘焙的八条 WAV、PCM bank、许可及验证记录。运行时使用固定四音源。
- `tests/`：对象与表现验证结果。

现有 manifest `0.2.0` 未增加 audio/fx kind；这些是同包表现资源。可执行 Lua 与声音并非 glTF 标准的动画内容；AI、音源创建和特效通过 `scripts/modules/demo_entry.lua` 中的规范模块加载。

`gameplay/adapters/zaizai/inkwave_presentation.lua` 负责本怪物的骨骼曲线、枪口射线、墨滴、受击闪色和三维音效。骨骼绑定依据导入的真实 Transform 名称，自动比较 x/z/无反射与单位缩放。初始化先停止原生自动动画，再从最终 GLB bank 恢复绑定姿态，不将编辑器已经播放的死亡末帧当作绑定姿态；逻辑根不参与恢复，避免动画覆盖导航位置。每次切动作对未含关键帧的通道恢复 rest pose。GLB 首段固定为 idle；死亡后重开也恢复规范绑定姿态。

攻击动作源前摇 0.55 s、有效 0.25 s、恢复 0.7 s。Inspector 修改攻击时间时，表现按三个阶段映射到原曲线，枪口开火仍由公共攻击实例进入有效窗口的事件触发。特效只表现，不自行扣血。

## 编辑器安装

先用编辑器“项目 → 导入资产”真实上传 `model/main.glb`，名称“墨潮巡猎者_定稿”。首次接入时放到当前场景；已有怪物时使用其资源“替换”，保持一个逻辑实例并恢复名称 `monster_inkwave_actor`。保存并退出本项目，再构建并执行增量安装：

```bash
python3 tools/sync_registry.py
python3 tools/build_editor_bundle.py
python3 tools/install_inkwave_monster.py --native-project '<原生项目目录>' --dry-run
python3 tools/install_inkwave_monster.py --native-project '<原生项目目录>' --apply --editor-closed
```

安装器读取**真实导入的 URI/assetID**，迁移原方块的 Inspector 参数到唯一场景逻辑根 `monster_inkwave_actor`（内部GLB根仍为 `monster_inkwave`，避免同名查找歧义），原方块保留停用。所有其他节点、资源引用、比赛参数及 ZIP 内容保留。不会用 seed 重建当前场景；失败回滚，成功报告 `docs/inkwave_editor_install.json`。编辑器导入限制为 10MB；必须在 Blender 简化并优化贴图后重新通过真实导入校验。

## 原作来源

作者 Jayden Davis，MIT。采用公开保存版本 [ENTROVIA/inkwave-main](https://github.com/ENTROVIA/inkwave-main)，固定提交 `dee4273a49f8839d757a3593a14bf33508f02c15`；原作者仓库当前不可访问，不能称此版本为其最新版本。复制/改造的实质源文件和许可分别位于 `tools/inkwave_asset_pipeline/source/` 与 `audio_source/`，Three.js 许可位于同工具的 `vendor/three/LICENSE`。

原 AI 的距离/LOS 判断增加本项目强制 FOV；新 Lua 控制器保留反应延迟、导航巡逻、失视最后可见点搜索及低血短退避，不使用原作的360°索敌。默认仍为 60HP、1/3 m/s、7m/100°视野、25HP伤害、3.5m攻击范围。角色数值、攻击合法性和重复命中去重只走 `context.services`。

## 验证边界

最终 GLB 的独立 Blender 重导入通过：87 骨骼、12 网格、4 蒙皮网格、6 动作。Lua AI 12 场景 / 230 断言，表现桥接 12 场景 / 177 断言，真实生成入口在 Lua 5.1/5.4 下 20 场景 / 108 断言，共 44 场景 / 515 断言通过；入口回归包含“属性等待期间导入器提前播放 GLB 死亡动作”的故障注入。这些 SDK 替身测试不代替编辑器预览。

纯 Lua AI、骨骼采样/声音解码 SDK 替身测试、Blender 导回检查、编辑器实际预览分别记录；一个层级通过不代表其他层级通过。新增原生 QA 包括真实骨骼更新、八条 AudioClip 上传、声音/墨枪特效事件，继续验证开箱、战斗、用药、撤离及重开。原生验收最终记录放 `docs/inkwave_native_acceptance.json`；未完成项目的多人、局前背包、仓库、商店和持久化不属于本次范围。
