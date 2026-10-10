# INKWAVE 怪物专属音效

这些资产只服务 `monster_inkwave`，不引入原项目的音乐、比赛提示或全局音频引擎。

| ID | 源合成器 | 建议触发 |
|---|---|---|
| `shoot_a/b/c` | `shoot_shooter` | 真正发射一枚弹体时轮换播放；前摇不播放 |
| `hit` | `ink_hit_body` | 本怪物弹体被公共 Combat 确认命中时 |
| `hurt` | `hurt` | 怪物被公共 Combat 确认扣血时；限频 |
| `death` | `splat_enemy` | 怪物进入死亡状态时一次 |
| `step` | `step_dry` | 巡逻/追逐有实际位移时，由脚步相位触发 |
| `step_ink` | `step_ink` | 有明确墨地标记时可切换；默认不用凭空判定地面 |

`*.wav` 是 22,050 Hz、单声道 PCM16 试听和可转换源文件。`pcm_bank.lua` 是紧凑 G.711 μ-law 8bit + base64 bank；量化质量见 `manifest.json`、`validation.json`。`audition_bank.wav` 按 manifest 顺序串联的是 bank 解码后的声音，片段间隔 0.14 秒，可核对编辑器实际将播放的 PCM。8 条 bank 总采样 32,482，Lua 文件约 46 KB。

这里直接运行源项目 `SFX.build` 和 `music.V` 的 Web Audio 合成图，在 Chrome `OfflineAudioContext` 中离线烘焙。保留原 SFX gain，固定 pitch=1 和随机 seed；源噪声缓冲仍使用源固定 seed。怪物版采用 22.05k 单声道、25Hz 高通、必要时峰值上限 0.82、结尾 5ms 淡出。原实时随机 pitch、HRTF、共享广场混响、master 压缩/限制、音乐总线不烘焙，所以不是原游戏最终混音的逐样本副本。编辑器在运行时做 3D 距离衰减和小幅 pitch 变化。

## Lua 接口

```lua
local Bank = require('gameplay.packages.monsters.monster_inkwave.audio.pcm_bank')
local decoder, reason = Bank.new_decoder('shoot_a')
-- decoder.total_frames / decoder.sample_rate，用于创建 AudioClip 和 typed Single[]。
-- 在 Update 的有限初始化预算内逐帧推进；sink 的 index 从 0 开始。
local done, written = decoder:step(4096, function(index, value)
    typed_float_array[index] = value
end)
-- done==true 后，才做完整 clip:SetData(typed_float_array, 0)，随后可以播放。
```

`Bank.clips[id].frames/source_name/data` 可读；`Bank.decode(id)` 返回 Lua 1 起始 float 表和采样率，便于离线验证。未知 ID 返回 `nil, 'UNKNOWN_CLIP'`。解码不依赖 Lua bit 库、文件读取或网络。

原生桥接建议：`CS.System.Array.CreateInstance(typeof(CS.System.Single), frames)`，`UnityEngine.AudioClip.Create(name, frames, 1, 22050, false)`；不使用分块 `SetData`。固定 4～8 个 `AudioSource`，`playOnAwake=false`、`loop=false`、`spatialBlend=1`、`dopplerLevel=0`、限制最大距离和事件限频，播放时定位到本怪物或本次命中点。停止预览/销毁时 Stop 并销毁本怪物音源/clip；不修改全局 AudioListener/BGM。

## 重建与来源

运行 `tools/inkwave_asset_pipeline/audio_bake.mjs` 可重新烘焙；使用已安装 Node、Chrome、Playwright，或设置 `PLAYWRIGHT_MODULE` / `CHROME_BINARY`。运行 `audio_validate.py`（项目 QA 依赖 `lupa==2.6`）独立验证 WAV 和 Lua 解码。原生播放还需集成验收，离线 PASS 不代表扬声器已经验证。

来源：[ENTROVIA/inkwave-main](https://github.com/ENTROVIA/inkwave-main)，固定提交 `dee4273a49f8839d757a3593a14bf33508f02c15`；作者 Jayden Davis，MIT。原文件快照在 `tools/inkwave_asset_pipeline/audio_source/`，文件 SHA256 见 manifest；完整上游许可保存在本目录 `LICENSE` 和源快照 `LICENSE`。
