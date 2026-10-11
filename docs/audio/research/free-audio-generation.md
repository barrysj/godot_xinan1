# 免费 BGM 与音效生成方案

核验日期：2026-10-11（Asia/Shanghai）；项目基线：`c820167`。状态：方案调研，未安装、试听或生成音频。音频接入状态仍以 [AUDIO-01](../audio-01.md) 为准。

## 选型结论

先用 **ElevenMusic.io 制作云端 BGM 候选、jsfxr 制作短电子音效**；需要批量生产和本地自动化时，再试 **ACE-Step 1.5 制作 BGM、Stable Audio 3 Small-SFX 制作环境与拟音素材**。Stable Audio 网页是可商用的无安装备选，但本轮未核准其精确免费额度。这是根据许可、功能与部署成本作出的适配判断，不是实际试听后的音质排名。

免费生成、免费下载、允许用于商业游戏是三个条件。本地模型没有云端次数收费，仍消耗下载流量、磁盘、算力与维护时间；第三方托管同一模型不自动免费。

| 方案 | 免费范围与正式使用条件 | 建议用途 | 成本与边界 |
| --- | --- | --- | --- |
| [ElevenMusic.io](https://elevenmusic.io/) | 每日 5 次无损下载；Free 原创 New Song 可商用，须显著署名 `Made with ElevenMusic`；Adaptation 不可下载进游戏 | 探索、战斗、校园主题 BGM | 网页即可；下载限额不是生成限额或 API 配额 |
| [ACE-Step 1.5](https://github.com/ace-step/ACE-Step-1.5) | 本地无次数收费；官方代码和模型卡标 MIT，模型卡明确生成音乐可商用 | 无歌词 BGM、主题变奏、局部重做 | 有 Windows 便携包、网页 UI 和 REST API；本机待试跑 |
| [Stable Audio 3 Small-SFX](https://huggingface.co/stabilityai/stable-audio-3-small-sfx) | 满足 Community License 的收入门槛、注册和其他条款时可免费商用 | 环境、机械、技能音效素材 | 需下载权重及接受协议；Windows 与当前显卡待验证 |
| [jsfxr](https://sfxr.me/) | 免费无限生成、导出 WAV，允许商业使用 | 确认、拾取、破解、护盾等短电子音效 | 浏览器即可，无需 GPU；属于参数合成器 |
| [Stable Audio 网页](https://stableaudio.com/) | 官方当前明确 Free 音频可用于商用游戏内 BGM/SFX；免费导出 | 云端器乐 BGM 与音效备选 | 精确免费额度及免费档曲长未核准；API 按量收费 |

额度与许可的原始依据见下文。这些是工具候选，尚无已验收音频资产。

## ElevenLabs：区分产品入口

### 普通 ElevenLabs／ElevenCreative 音效免费档

[价格页](https://elevenlabs.io/pricing)列 Free 每月 10,000 共享 credits，包含 Sound Effects。[音效费用说明](https://help.elevenlabs.io/hc/en-us/articles/25735337678481-How-much-does-it-cost-to-generate-sound-effects)列网页默认一次 4 个结果、200 credits；API 默认一个结果、100 credits。指定时长时，网页与 API 分别为每秒 40 与 20 credits。全部共享额度用于网页默认音效，可推算约 50 次调用；不是独立音效额度。

[发布帮助页](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform)明确普通 Free 不包含商业许可，非商业发布须署名。普通 ElevenLabs 免费 SFX 可试听，不作为本项目零成本商业素材主路线。

### 独立 ElevenMusic.io 免费 BGM

[Music v2.5 官方公告](https://elevenlabs.io/blog/music-v2-5-model)于 2026-09-11 发布、09-20 更新，明确 ElevenMusic Free 每日 5 次无损下载，署名后可商用。不能把普通 ElevenLabs 的非商用结论套到此独立产品。

[ElevenMusic 正式条款](https://elevenmusic.io/terms-of-use)最后更新于 2026-09-11，Section 1 区分：

- **New Song**：输入不使用、纳入或引用平台 Uploaded Music 或其他用户的身份材料；可下载、平台外使用及商用。Free 商用须 reasonably prominent `Made with ElevenMusic` 署名。
- **Adaptation**：基于上传音乐的翻唱、混音或再诠释等；只能在服务内使用，不得下载和平台外使用。
- **数字流媒体发行**：只有在 Pro 期间创建的 New Song 才可发行到数字流媒体／DSP。游戏使用权限不能直接套用到原声专辑发行。

项目可用原创文字描述生成无歌词 New Song，保存生成日期与许可依据，在游戏鸣谢或音频信息处显著署名。未账户内验证生成次数、曲长、循环功能或实际下载。

### ElevenLabs 平台／API Music

[ElevenLabs Music Terms](https://elevenlabs.io/music-terms) Exhibit A 的 Free 列每月 11 分钟生成、禁止下载、无 API；Media Rights 行与通用免费帮助页的表述并不完全相同。按具体产品与适用条款区分，本项目免费音乐优先使用独立 ElevenMusic.io，不将其下载额度套到 ElevenLabs API。

## 本地候选

### ACE-Step 1.5：BGM

[官方仓库](https://github.com/ace-step/ACE-Step-1.5)提供音乐生成、BPM／调性／拍号控制、cover、局部重绘、vocal-to-BGM，以及 Gradio UI、Python 和 REST API；不同 checkpoint 功能不完全相同。[代码 LICENSE](https://github.com/ace-step/ACE-Step-1.5/blob/main/LICENSE)为 MIT，[官方模型卡](https://huggingface.co/ACE-Step/Ace-Step1.5)也标 MIT，并明确生成音乐可用于商业用途。参考曲、第三方 LoRA 与微调输入须分别有权使用。

[安装指南](https://github.com/ace-step/ACE-Step-1.5/blob/main/docs/en/INSTALL.md)要求 Python 3.11～3.12，并提供 Windows 便携环境。[GPU 指南](https://github.com/ace-step/ACE-Step-1.5/blob/main/docs/en/GPU_COMPATIBILITY.md)给出 6～8 GB 的低显存配置：0.6B LM、PyTorch backend、offload 与 INT8。当前机器优先尝试 2B turbo 配合 0.6B LM；官方 A100／RTX 3090 的速度不能作为本机性能承诺。

本轮只读检查得到 RTX 2080 SUPER、8192 MiB 显存，现有 Python 为 3.7。硬件可作为试验对象，尚无跑通证据；应使用隔离的新环境或便携环境，所有 Windows 命令仍通过 `pwsh.exe` 执行。

### Stable Audio 3 Small：音效

[官方模型表](https://github.com/Stability-AI/stable-audio-3)列 Small-Music 与 Small-SFX 为 433M、最长 120 秒，并支持 CPU。[Small-SFX 模型卡](https://huggingface.co/stabilityai/stable-audio-3-small-sfx)和 [Small-Music 模型卡](https://huggingface.co/stabilityai/stable-audio-3-small-music)提供权重；可分别作为环境／拟音与短 BGM 候选，质量待试听。[推理文档](https://github.com/Stability-AI/stable-audio-3/blob/main/docs/workflows/inference.md)支持时长、seed、batch、audio-to-audio、局部重绘与续接；续接不保证尾首无缝，仍需后期处理循环。

[代码 LICENSE](https://github.com/Stability-AI/stable-audio-3/blob/main/LICENSE)为 MIT，权重另适用 Community License。[许可入口](https://stability.ai/license)与[官方音频许可说明](https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing)说明：个人／组织及关联方须满足低于 USD 1,000,000 的年收入门槛，计算所有来源收入；商业使用须注册并遵守其他协议，超限需单独许可。正式生产应保存所用权重版本的完整协议。

下载需 HF 登录、接受协议并分享联系方式；模型卡还提示部分组件适用 Gemma Terms。[依赖文件](https://github.com/Stability-AI/stable-audio-3/blob/main/pyproject.toml)要求 Python ≥3.10。Windows 与当前显卡推理未验证。

本机先选 Small：Medium 需要 Flash Attention 2，而 [FA2 标准 CUDA 支持表](https://github.com/Dao-AILab/flash-attention#nvidia-cuda-support)列 Ampere／Ada／Hopper，Turing 另有部分功能实现。不能依据 H200 显存测试就判断 RTX 2080 SUPER 可直接跑 Medium。

### jsfxr：短电子音效

[jsfxr 官网](https://sfxr.me/)的 Free／Pro 表明确免费版可无限生成、导出 WAV，并允许商业使用。[库代码](https://github.com/chr15m/jsfxr)采用 Unlicense，支持预设、JSON 参数与 WAV 渲染。可为确认、破解、拾取等建立一致的音色家族，无需把 JavaScript 运行时接入 Godot。

## 其他方案与淘汰原因

- **Stable Audio 网页**：[当前许可 KB](https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing)明确 Free 可商用，包括游戏内 BGM/SFX；[使用指南](https://stableaudio.com/guide)支持免费导出。当前产品首页列 1 秒～6 分钟，但不能推断全部适用于 Free。本轮未核准免费配额，不沿用旧“10 次／45 秒／非商用”的说明。网页、本地权重与付费 API 各自独立。
- **Suno Free**：[价格页](https://suno.com/pricing)列每日 50 credits；[下载 FAQ](https://help.suno.com/en/articles/13614785)说明自 2026-09-03 起免费账户最多 7 首终身试用下载，非商用。适合探索旋律方向，不作为免费正式商业游戏素材来源。
- **Flow Music**：[价格页](https://www.flowmusic.app/pricing)列免费每日补充额度但未公开准确数；官方[下载说明](https://support.google.com/flow/answer/17084348)与[准入说明](https://support.google.com/flow/answer/17083868)列下载、地区、Google 账号与年龄条件。未找到明确免费商业游戏许可依据，不列入主推荐。
- **MusicGen／AudioCraft**：[官方模型卡](https://github.com/facebookresearch/audiocraft/blob/main/model_cards/MUSICGEN_MODEL_CARD.md)列代码 MIT、权重 CC BY-NC 4.0；不作为本项目正式商业素材路线。
- **AudioLDM2**：[代码 LICENSE](https://github.com/haoheliu/AudioLDM2/blob/main/LICENSE)与[官方 Diffusers 权重](https://huggingface.co/cvssp/audioldm2)列 CC BY-NC-SA 4.0；同样不作为免费商业生产主路线。

## 最小制作与验证建议

先制作一段校园主题 BGM、一个战斗变奏，以及确认／产码／破解／护盾生成／护盾破裂／终端回收六个短音效。比较实际游戏画面中的辨识度、重复听疲劳和音色一致性，再扩大资产量。

确认可导出 WAV、音乐无意外人声、循环无跳拍与爆音、短音效起音及时且含义可分，保存素材来源与许可依据。声音按原战斗和探索事件接入；这只是制作建议，尚未实施。

本轮已完成官方资料与本机硬件的只读核对；未完成账户内额度、地区可用性、实际下载、试听、Windows 模型安装、显卡推理及 Godot 接入。云端规则可能变动，生产时重新核对具体入口和所用版本。
