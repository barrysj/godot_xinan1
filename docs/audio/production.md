# 音频制作与接入方案

2026-10-11；核对基线 `0e117af`。状态：当前实施建议，未冻结音色，未生成／试听／接入资产。功能状态见 [AUDIO-01](audio-01.md)，工具许可见[免费方案调研](research/free-audio-generation.md)，skill 评估见[生产技能调研](research/audio-production-skills.md)。

## 当前依据与范围

原玩家流程包含菜单／基地、序章、三区域地点探索与热点、自动战斗、代码破解、记忆终端、三阶段终局和校园恢复；具体规则仍以[战役设计](../campaign/design.md)和[战斗规则](../combat/rules.md)为准。

当前尚无主流程音频消费者与正式音频文件；已有 `BGM`／`SFX` 总线是模板基础。战斗入口为 [presentation_cue](../../scenes/battle_demo/pixel_battle.gd)，模拟事件来自[行动与命中](../../game/combat/battle_simulation.gd)、[代码与敌方预警](../../game/combat/code_battle_simulation.gd)、[羁绊](../../game/combat/synergy_simulation.gd)。战役节点和收尾复用 [campaign_hub.gd](../../scenes/expedition/campaign_hub.gd)。本方案不增加平行战斗、地图或存档。

完整计划为 **6 段循环 BGM、27 类一次性音效、3 类环境底声**。这是按作用计数，不是最终文件数；高频音效需 2～3 个变体，其他操作尽量复用。无需为每位角色、地点、强化或按钮各做专属声音。首批为 **3 段 BGM＋14 类短音效＋1 类室外环境底声**，先验证原流程内的听感，再补其余内容。

## BGM 清单

音乐建议共同使用柔和电钢琴／拨弦合成器、克制的电子鼓与数字纹理；校园温度和虚拟系统感并存。不是纯 8-bit 全曲，也不覆盖真实校园纪念气氛。下面的速度和长度是制作起点，不是已批准参数；模型写了 BPM／loop 也必须实际核对。

| ID | 场景与作用 | 首批 | 建议长度与方向 | 复用边界 |
| --- | --- | --- | --- | --- |
| bgm_campus | 菜单、基地、出发准备、序章安全段 | 是 | 60～90 秒；约 88～96 BPM，温暖、轻电子 | 首批也覆盖路线探索，不因开关详情重播 |
| bgm_explore | 地点调查、系统线索和未恢复校园 | 后补 | 60～90 秒；约 96 BPM，轻微悬疑、稀疏节奏 | 三区域共享，地点差异用底声体现 |
| bgm_battle | 普通守卫与序章战斗 | 是 | 60～90 秒；约 120 BPM，清楚脉冲、少量旋律 | 不为每个阵容或敌群生成一首 |
| bgm_boss | 区域 Boss 与终局核心战斗 | 后补 | 60～90 秒；约 128～136 BPM，更紧张但避免堆满 | 先共享一首；以后有需要再增加三阶段强度版本 |
| bgm_memory | 照片、人物交谈、重要对白 | 是 | 60～90 秒；约 76～88 BPM，少鼓、亲切克制 | 首批用于结尾；短详情不反复切音乐 |
| bgm_restored | 限制写入成功、校园恢复、结束后基地 | 后补 | 60～90 秒；校园主题的温暖舒展变奏 | 与开场有共同动机，表现恢复而非陌生新主题 |

胜利／失败／恢复的短提示列入音效，不另外生成完整 BGM。先用同一段原创动机制作校园、回忆和恢复变奏；保留同一组音色和自有参考输入。第一阶段采用状态切曲与短交叉淡化，有实际需要再做 stems 和整小节切换，不先建设复杂自适应音乐系统。

## 一次性音效清单

“首批”合计 14 类。时长为剪辑目标，不要求模型直接精确生成到毫秒。

| ID | 用途／可靠触发 | 首批 | 目标长度与制作方式 |
| --- | --- | --- | --- |
| ui_confirm | 确认有效选择；装备、派遣等普通确认复用 | 是 | 0.08～0.2 秒；jsfxr／参数合成，柔和 click |
| ui_back | 返回、关闭 | 后补 | 0.08～0.2 秒；确认声的低向变化 |
| ui_error | 明确拒绝、资源不足或不可执行操作 | 是 | 0.15～0.35 秒；低频双音，避免尖锐蜂鸣 |
| ui_open | 开详情、热点、照片卡 | 后补 | 0.15～0.35 秒；轻翻页＋电子层；不做每字音 |
| reward_gain | 有效领取奖励、永久伙伴兑现、派遣完成 | 后补 | 0.4～0.8 秒；短上行提示，普通成功共用 |
| unit_place | 合法部署或换位成功 | 是 | 0.12～0.3 秒；轻落位／磁吸，不在拖动每帧播放 |
| melee_swing | 近战 `action_released`；区分普通出手与取消 | 是 | 0.15～0.4 秒；Stable Audio Small-SFX 出 swoosh 后剪辑 |
| ranged_shot | 远程成功出手 | 是 | 0.1～0.35 秒；电子发射与短机械层，2～3 变体 |
| hit_light | `impact` 的真实扣血 | 是 | 0.1～0.3 秒；短干声，2～3 变体；避免写实血肉 |
| hit_heavy | 重击／强伤害的听感加强 | 后补 | 0.25～0.55 秒；命中层＋低频冲击；不另造暴击规则 |
| shield_gain | `impact.effect=shield` 且实际增加量为正 | 是 | 0.3～0.7 秒；柔和充能，不因护盾条刷新重播 |
| shield_block | 实际吸收伤害 | 是 | 0.08～0.25 秒；干净弹性碰撞，2～3 变体 |
| shield_break | `impact.shield_break`，按目标和动作去重 | 是 | 0.25～0.55 秒；玻璃质电子裂解，优先级高于普通格挡 |
| heal_gain | `impact.effect=heal` 且实际治疗量为正 | 是 | 0.3～0.7 秒；温暖上行短音；满血转盾用实际效果选择 |
| cast_charge | 施法前摇；取消时停止长尾 | 后补 | 0.3～0.8 秒；可裁的蓄力纹理，不为每人做长台词 |
| enemy_warning | `enemy_warning` 预警成立 | 是 | 0.3～0.7 秒；可辨识警示，首次提示后不每帧鸣叫 |
| enemy_release | `enemy_release`；攻击／广播等结果区分复用 | 后补 | 0.3～0.8 秒；重击／广播层，和命中层控制叠加 |
| unit_disappear | 存活→死亡／退场状态；每次退场仅一次 | 后补 | 0.25～0.6 秒；数字消散；不是现有独立模拟事件 |
| code_gain | `code_generated.actual>0`；多角色合并提示 | 是 | 0.08～0.2 秒；很轻的数字颗粒；满额溢出不作获得声 |
| scan_mark | `mark_applied` | 后补 | 0.15～0.35 秒；扫描短音，和预警可区分 |
| mark_verified | `mark_verified` | 后补 | 0.2～0.45 秒；清晰确认音，扫描家族变奏 |
| hack_complete | `hack_completed`；程序真正执行成功 | 是 | 0.3～0.7 秒；编译／执行短音，不在点击后无条件播放 |
| terminal_acquire | 区域首次成功、记忆终端确实获得 | 后补 | 1～2 秒；重要解锁提示；重玩不误报首获 |
| core_submit | 修正目标／撤销越权／限制写入实际提交成功 | 后补 | 0.5～1 秒；同一家族，三步微调音高／质地 |
| campus_restore | 首次永久恢复校园 | 后补 | 2～4 秒；短恢复提示，与结尾 BGM 衔接 |
| battle_victory | 原战斗胜利结算 | 是 | 1～2 秒；短明亮 stinger，与校园主题关联 |
| battle_defeat | 原战斗失败结算 | 后补 | 0.7～1.5 秒；温和下降，不惩罚式刺耳音 |

**复用规则**：技能优先按实际效果选择攻击／盾／治疗素材家族；羁绊、装备、道具与奖励不自动新增一套声音。自动战斗中同帧群体技能、连锁命中、护盾破裂和产码均需去重、限流与优先级；不能逐条日志朗读或播放每个事件。语音、角色喊招、逐字滴答、全员脚步和持续濒死警报不列首批。

## 环境底声

| ID | 用途 | 首批 | 工具和边界 |
| --- | --- | --- | --- |
| amb_campus | 室外校园／湖边／路线底声 | 是 | Stable Audio Small-SFX；20～40 秒素材；风、树叶、少量远鸟，无可辨识人声 |
| amb_indoor | 图书馆、楼内等安静空间 | 后补 | Small-SFX；20～40 秒；极轻通风／室内底噪，不能喧宾夺主 |
| amb_core | 核心存储和终局系统操作 | 后补 | 参数合成／Small-SFX；低强度数据与机器底声，避免耳疲劳 |

这些是风格化空间声音，不能冒充真实校园录音。地点若已播放合适 BGM，可以先不用底声；底声与音乐需一起试听，避免把所有空隙都填满。

## 工具选择与下载额度

先前优先推荐 ElevenMusic 的依据是入口省事、下载额度与署名商业使用规则清楚，只适合少量 BGM 试样；没有充分比较编辑返工与批量制作成本，也没有证明其音质优于 Stable Audio。

[ElevenMusic 公告](https://elevenlabs.io/blog/music-v2-5-model)明确免费每天 5 次无损下载，具体权利见[独立平台条款](https://elevenmusic.io/terms-of-use)。它保留为对照试听和少量补充，不作为持续批量生产的唯一工具。

[Stable Audio 使用指南](https://stableaudio.com/guide)说明生成新音频才消耗 credits，已有音频的剪辑、混音、效果和导出免费；[当前许可 KB](https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing)明确 Free 可用于商用游戏内音乐与音效。因此优先试其云端工作台做候选和局部修改。但本轮未核准精确免费生成配额与免费档全部功能，**不能宣称 Stable Audio 网页无限免费或额度优于 ElevenMusic**；账号内确认配额后才决定云端批量计划，API 计费另算。

持续低成本路线建议：

1. **BGM：ACE-Step 1.5 本地优先候选，Stable Audio 网页作免安装试样／备选**。[ACE 官方模型卡](https://huggingface.co/ACE-Step/Ace-Step1.5)标 MIT 并明确生成音乐可商用；本机 8 GB 显卡先按[低显存指南](https://github.com/ace-step/ACE-Step-1.5/blob/main/docs/en/GPU_COMPATIBILITY.md)验证，不承诺现成跑通。
2. **环境与复杂拟音：Stable Audio 3 Small-SFX 本地候选**。具体收入门槛、注册与权重条款见[许可](https://stability.ai/license)，Small 与 Medium 不能混为同一个硬件条件。
3. **UI／代码／短数字声：jsfxr 或轻量参数合成**。[jsfxr](https://sfxr.me/)免费导出 WAV、商业使用，参数比反复整段生成更易控制；只作为素材层，不把整部游戏都做成刺耳复古音色。
4. **裁切／格式／测量：FFmpeg／ffprobe，必要时 Audacity 手工选循环点**。[FFmpeg 官方滤镜](https://ffmpeg.org/ffmpeg-filters.html)提供裁切、淡化、交叉淡化、响度与静音测量；不依赖云端下载额度。本轮未在 PATH 找到 ffmpeg／ffprobe，正式部署需先定位或配置工具。

## 制作工作流

### 1. 先做音色样本

从首批取 `bgm_campus`、`bgm_battle`、`hit_light`、`shield_break`、`hack_complete` 做小样。每种先做 2～3 个候选，比较校园气氛、战斗清晰度和重复听疲劳，再定首批其他素材。云端先在线试听，下载选中的候选；本地保留原始输出，不把候选全部作为运行资源。

每个简报最少包含 ID、触发、作用、目标时长、音色、BPM／调性（音乐）、人声限制、循环要求和可用输入。校园／回忆／恢复共用原创主题动机；战斗和 Boss 共用节奏音色。参考输入只使用有权使用的素材。

### 2. 分工生成

- BGM：先出 60～90 秒无歌词主题，挑连续整小节段落；模型的 loop／BPM 指令只是意图，不能当循环与拍速验收。需要调整时优先局部重做和自有主题变奏，不只靠重新生成整首。
- 高频短音效：用 jsfxr／参数合成建立一套基础数字音，先生成必要变体；随机细调幅度要克制。
- 拟音／环境：一次请求只包含一个声源或一个短动作；例如一击／一次裂解，不生成已混满音乐和连续战斗的长片段。环境单独生成，不把人声与 BGM 混入。

提示词起点（需根据模型调整，不是已批准稿）：

```text
BGM: Instrumental game background music for a warm virtual campus, soft electric piano, rounded pluck synth, restrained electronic drums, nostalgic and hopeful, 92 BPM, sparse arrangement, stable pulse, no vocals, no spoken words, no dramatic ending, 75 seconds.

Shield break: A single short digital energy shield cracking and dissolving, clean dry transient, soft crystalline fragments, concise tail, no music, no speech, no repeated hits, isolated sound effect.

Campus ambience: Quiet stylized campus outdoors, soft breeze through leaves, occasional distant birds, calm and spacious, no intelligible speech, no music, no abrupt foreground events.
```

### 3. 本地后期与输出

保存原始 WAV，再做去无意义首尾静音、必要短淡化、噪声与爆音检查。避免把护盾／命中短音效做成长片段，使操作延迟。先检查单声道折叠，避免立体声相位抵消。

BGM 与底声按音乐／空间连续性选循环点，保留混响尾巴，至少连续试听三次循环；不能给完整音乐首尾淡出淡入就称无缝循环。循环交叉淡化应避开鼓点瞬态和短周期相消。

母版保留 WAV，短音效输出 WAV，音乐与长底声可输出 Ogg Vorbis；Godot 格式、压缩和 Loop 设置按[官方导入说明](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html)核对。不要把 MP3 作为短音效唯一母版，也不凭扩展名假定已开启 Loop。

用 ffprobe 检查可解码性、时长、采样率和声道；用 FFmpeg 测量峰值／静音／音乐整体响度。短 click 不强行统一到与音乐相同的 integrated LUFS；最终响度根据游戏混音决定，保留主输出余量，不靠峰值归一化让所有音效同样响。

### 4. 保存制作依据

正式制作时，将选择保留的音频源包放 `design/audio/<id>/`，包含原始输出、提示词、模型／checkpoint／seed／参数（服务未提供则明确记录）、输入及权利依据、处理方式和预览；运行版放 `assets/audio/`。这两个目录目前是建议的音频职责分工，尚未创建资产。

Codex 临时处理文件放 Git 忽略的 `.godot/art-workflow/audio/`，遵守项目统一中间目录；长期源包和预览不能当作临时文件清理。只保存现用候选及必要制作依据，不另建逐轮审批流水。

### 5. 接入原流程并验收

复用 `BGM`／`SFX` 总线与原表现事件。伤害在真实 impact 播放，释放与命中分开；按动作／目标／效果去重，同帧多目标不得叠出一片爆音。失败按钮只播放错误提示，不能先播放成功声。

角色退场、战役终端与永久恢复没有一概通用音频事件，需要接到原状态转换／提交成功边界；重新绘制页面、继续存档、重复查看或重玩不误报一次性获得。重看故事可有音乐，但不重发解锁声。

战斗声和长预警音服从暂停；暂停菜单 UI 可响，BGM 可降低音量继续。慢速／倍速改变战斗事件密度，不能无条件改变音乐音高；高频声音限流，恢复时不集中补播暂停期间的音效。

先跑原序章、一次普通战、追踪／护盾各一组、敌方预警与失败重试，再检查区域首获／重玩、终局三步／恢复和保存续玩。耳机、普通扬声器及目标 Web／手机分别试听，确认预警不被音乐盖住、循环不跳拍、暂停与倍速不漏／重复播放。后续每个接入功能运行并截图展示；截图证明触发与运行，音频试听才证明听感。

## 当前验证与边界

本轮完成原流程和事件的静态核对、官方工具与 skill 调研、文档链接／差异检查；没有安装模型、生成素材、执行后期或音频运行验收。声音仍为仅设计。准确云端账号额度、实际 GPU 推理、曲目质量与素材许可版本均在正式生产时确认。
