# 音频生产 Skill 调研

调研日期：2026-10-11；核对基线 `0e117af`。状态：方案调研，未安装 Skill／MCP、执行远程脚本、下载模型或生成音频。实施状态见 [AUDIO-01](../audio-01.md)，声音清单和正式工作流见[制作方案](../production.md)。

Skill 是指引与脚本，不是音频模型；开源 Skill 不会免除它调用的 API 费用或素材许可。推荐复用现有 audio-design＋godot-audio 做设计／接入，评估 ffmpeg-skill 做后期；ACE-Step 与 Stable Audio 3 优先使用官方 API／CLI。以下结论来自原仓库静态阅读，尚未本机试跑或完整安全审计。

## 已有技能

- [audio-design](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/audio-design/SKILL.md)：总线、dB 增益、ducking、音效变化、音乐分层／分段和实际试听；负责设计与混音，不生成文件。
- [godot-audio](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-audio/SKILL.md)：播放节点、总线路由、静音、交叉淡化、循环与重复触发；原文面向 Godot 4.7，与本项目配置版本一致，具体实现仍核对原玩家流程。

公开原仓库为 [Apache-2.0](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/LICENSE)，没有外部付费音频 API；当前环境已有对应技能。不要把示例总线名覆盖本项目的 `BGM`／`SFX`。

## 新候选

| Skill | 覆盖与依赖 | 许可与 Windows 边界 | 判断 |
| --- | --- | --- | --- |
| [ACE-Step 官方 acestep](https://github.com/ace-step/ace-step-skills/blob/main/skills/acestep/SKILL.md) | 已启动的 ACE-Step 1.5 API；生成、续写、重绘；记录 prompt／seed／模型／BPM／调性 | Bash＋curl＋jq；skill 仓库未确认许可证；需原生 pwsh／Python 适配。本地服务与收费 API 各自区分 | 参考官方接口，暂不直接复制安装 |
| [kajisho5 ffmpeg-skill](https://github.com/kajisho5/ffmpeg-skill/blob/main/SKILL.md) | 裁切、淡化、声道、格式、响度、true peak 和元数据检查；Python 3.9+、FFmpeg 5+ | [MIT](https://github.com/kajisho5/ffmpeg-skill/blob/main/LICENSE)；Python 脚本可由 pwsh.exe 调用，无云端密钥；运行时需核实 | 优先试用的新增后期技能 |
| [Stable Audio 3 prompt-writing](https://github.com/UgurInanc12/stable-audio-3-prompt-writing/blob/main/SKILL.md) | 音效提示词为主，没有独立生成后端 | frontmatter 声明 MIT，未见独立 LICENSE；混入作者本机 ComfyUI Medium Base 路径和偏好 | 不直接安装，先用官方指南 |
| [AIEGOBOT audio-production](https://github.com/AIEGOBOT/agent-audio/blob/main/skills/audio-production/SKILL.md) | Agent Audio MCP＋Stable Audio 3 Medium；文本到 WAV | [MIT](https://github.com/AIEGOBOT/agent-audio/blob/main/LICENSE)，权重另受 Community／Gemma 条款；Windows 默认 CPU，CUDA 未验证，不能选 Small-SFX | 当前机器暂不优先 |
| [ElevenLabs sound-effects](https://github.com/elevenlabs/skills/blob/main/sound-effects/SKILL.md) | 官方 Python／JS SDK 或 CLI；时长、影响度、循环；互联网和 API key | [MIT](https://github.com/elevenlabs/skills/blob/main/LICENSE)；仍消耗 API 额度并受商业使用条款限制 | 有预算时备选，非免费主路线 |

## 核验细节

ACE 官方 skill 会保存制作依据，LM 增强后实际 prompt 可能不同于输入，应同时保留。但 [SKILL.md](https://github.com/ace-step/ace-step-skills/blob/main/skills/acestep/SKILL.md)和[脚本](https://github.com/ace-step/ace-step-skills/blob/main/skills/acestep/scripts/acestep.sh)的 api_mode 默认值有差异；文档说缺 jq 会自动安装，脚本实际报错退出。config --set 会输出所写值，不应使用可见命令写入密钥。[skill 仓库](https://github.com/ace-step/ace-step-skills)根未见 LICENSE，不能把[模型主项目 MIT](https://github.com/ace-step/ACE-Step-1.5/blob/main/LICENSE)自动套到独立 skill；依公开 API 自行编写项目适配器更合适。

FFmpeg 已查看 [audio.py](https://github.com/kajisho5/ffmpeg-skill/blob/main/scripts/audio.py)、[loudness.py](https://github.com/kajisho5/ffmpeg-skill/blob/main/scripts/loudness.py)、[probe.py](https://github.com/kajisho5/ffmpeg-skill/blob/main/scripts/probe.py)。本地后期无需付费 API，具有输出复测；[README](https://github.com/kajisho5/ffmpeg-skill#ffmpeg-compatibility)列 Windows CI，但实际素材与本机环境仍需验证。不要把视频平台默认响度套到短音效／底声，也不把元数据通过当作已经试听。首次只评估音频脚本子集，不为本任务安装视频工作流或 MCP。

Stable Audio 3 已有[官方 CLI](https://github.com/Stability-AI/stable-audio-3#cli)与[提示词指南](https://github.com/Stability-AI/stable-audio-3/blob/main/docs/guides/prompting.md)，可选 small-music／small-sfx；音效提示词写声源、动作与录音特征，短效果匹配短时长。CLI 是工具，不是 skill，不必为它额外安装第三方 MCP。

Agent Audio 的 [README](https://github.com/AIEGOBOT/agent-audio#before-you-install)指出 Windows CPU、CUDA 未验证及较高磁盘／内存开销；[skill](https://github.com/AIEGOBOT/agent-audio/blob/main/skills/audio-production/SKILL.md)明确 Small-SFX 仅在独立 benchmark，不能从 MCP 选用，编辑／续写／循环／混音也未暴露。查看了 [bootstrap.py](https://github.com/AIEGOBOT/agent-audio/blob/main/install/bootstrap.py)与 [SECURITY.md](https://github.com/AIEGOBOT/agent-audio/blob/main/SECURITY.md)：安装会下载模型并登记配置，有备份和 revision 固定，但当前仍不值得为此引入额外复杂度。

## 推荐组合

需求卡与制作依据 → 官方生成工具 → 本地后期与客观检查 → 实际试听／重复循环 → 原 Godot 流程接入。

现有设计和引擎 skill 可直接复用；新增后期优先评估 ffmpeg-skill。生成侧用 ACE-Step 本地 API 与 Stable Audio Small-SFX 官方 CLI，必要时写薄的 pwsh／Python 包装，而非为了 skill 更换音频模型。范围、资产清单和批次见[制作方案](../production.md)，这里不复制。
