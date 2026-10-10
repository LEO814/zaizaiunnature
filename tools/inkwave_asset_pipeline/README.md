# INKWAVE 单怪物资产导出管线

来源：Jayden Davis 的 INKWAVE；当前可读副本 https://github.com/ENTROVIA/inkwave-main ，固定提交 `dee4273a49f8839d757a3593a14bf33508f02c15`。保留原 MIT 许可证于 `source/LICENSE`。Three.js r186 导出运行库许可证于 `vendor/three/LICENSE`。

本管线只实例化 `Character` 和 shooter 武器，省略比赛、地图、队伍、涂地系统、菜单以及未使用的鱿鱼形态/手雷/远景武器副本。角色和骨骼并非重新画的简化占位物：原始头部、耳朵、头发触手、手指、鞋带、服装、墨罐以及枪身零件几何均保留。

## 构建

使用 Node 24、Playwright 和本机独立 headless Chrome（导出进程使用新建浏览器配置，不连接或操作用户现有浏览器）。

```bash
PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs node tools/inkwave_asset_pipeline/run_export.mjs
/Applications/Blender.app/Contents/MacOS/Blender -b --python tools/inkwave_asset_pipeline/simplify_blender.py
python3 tools/inkwave_asset_pipeline/normalize_clip_times.py
python3 tools/inkwave_asset_pipeline/extract_runtime_bank.py
python3 tools/inkwave_asset_pipeline/verify_export.py
/Applications/Blender.app/Contents/MacOS/Blender -b --python tools/inkwave_asset_pipeline/validate_final_blender.py
```

`run_export.mjs` 内置本机默认 Playwright 路径，可由环境变量覆盖；Chrome 路径适用于 macOS。产物位于 `gameplay/packages/monsters/monster_inkwave/`。

## 模型与材质

- `model/main.glb`：米单位，Y 上，+Z 前，脚底为根；87 骨骼，4 蒙皮分片共用 1 个 skin，12 可见网格；源版 38,710 三角面，经真实 Blender Decimate 简化为约 27,952 面。皮肤/眼部不减面，优先简化衣服、头发和武器小装饰。
- 用原始 shader 在 GPU 上烘焙三角形材质图集，保留护目镜面罩、虹膜、嘴部、衣服标志、鞋子和触手吸盘等细节。三角 UV 图集逐 cell 扩展边缘颜色，防止降采样黑/亮接缝。每个网格有 base / roughness-metalness / clearcoat 三种贴图并内嵌 GLB；`materials/` 另保留 2K PNG 源件；编辑器版 base ≤1024、粗糙金属/清漆 ≤512 或256，以满足编辑器10MB单文件限制。
- 静态面部贴图固定为中性表情；眨眼、眉毛、下颌、手指、头发、衣摆和背罐动作仍由骨骼动画驱动。原版动态 shader 嘴形/瞳孔注视、微表面法线、视角相关玻璃效果是跨引擎限制，未假称完全迁移。
- `model/source.blend` 是 Blender 简化的可编辑验收工程，保留未应用的 Decimate modifiers、隐藏的高清参考 collection、灯光、相机和六个动作 NLA 轨。预览物不会导出进 GLB。

## 动作

`idle / patrol / chase / attack / hit / death`，30 Hz 采样源程序动画。移动为原地动作，位移由项目 Monster/Navigation 服务控制。巡逻/追击循环末段收束到首帧以适配独立动画片段。

`attack` 1.5 秒：0.55 秒开枪，与本项目公共战斗窗口一致；`hit` 0.7 秒，控制器可按项目受击暂停规则打断；`death` 1.4 秒，为原受击动作加倒地收束（原版没有独立死亡片段）。

Blender NLA 导出的一帧时间偏移已归零，动作实际时长与游戏契约一致。`animations/runtime_bank.json` 与 `.lua` 从最终 Blender GLB 重新提取，使用主项目的节点 TRS 格式；`verify_export.py` 对每个默认 TRS、动画节点、关键帧时间和值逐项比对 GLB，精度误差 < 1e-6。编辑器若没有自动生成 Animator，可用同一动作 bank 驱动导入模型骨骼，不影响怪物 AI 公共接口。

`normalize_clip_times.py` 同时固定 GLB 动画数组顺序为 `idle / patrol / chase / attack / hit / death`；部分编辑器导入后会自动播放第一段动画，因此默认片段必须为 `idle`。提取器与验证器共同检查该顺序，防止把倒地姿态作为初始状态。

枪口 socket：`muzzle`；武器根：`weapon_shooter`；不把任何比赛逻辑装进 GLB。声音和运行时 FX 是本怪物包的配套资源，不能作为 glTF 格式中原生脚本执行。
