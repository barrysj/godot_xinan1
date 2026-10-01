# 美术任务：Guard 动画方法对照

状态：负责人于 2026-10-01 指定 **Guard 只留 008**，随后明确批准现存人物概念和动画登记正式资源。`guard/asset_008` 已 `selected + approved` 并提升到 `assets/art/characters/guard/`，单位动画和头像已切换，旧占位图集及动画入口已移除。游戏接入效果待人工评审。概念与动画统一归属 `assets/art/manifests/characters/guard.yaml`。本轮批准范围和验证见 [人物正式登记](m1-player-cast-animation.md#正式登记与接入2026-10-01)。方法事实与来源见[调研](../../research/guard-animation-methods.md)。

## 当前留存：008

- [动画资源](../../../design/concepts/characters/guard/asset_008/battle_animation.tres)、[动作卡](../../../design/concepts/characters/guard/asset_008/action-card.yaml)、[七动作 GIF](../../../design/concepts/characters/guard/asset_008/review/all-actions.gif)与[实机近战截图](../../../design/concepts/characters/guard/asset_008/review/godot-melee-1920x1080.png)保留在同一版本。24 张近战帧、36 张待机／移动／施法／受击帧、濒危与退场静帧均由 008 自身引用。
- 008 保存即梦原片 `source/melee.mp4`、24 张调色前源帧 `source/pre-neutral-frames/`、濒危／退场源图、切帧元数据与确定性调色脚本。调色前帧源自历史 007，其他四动作源自历史 005；这些输入已复制进 008，旧候选不再是活动依赖。
- 预览：`pwsh.exe -File ./run-motion-preview.ps1 -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/characters/guard/asset_008/battle_animation.tres -Action Melee -Speed 0.5`。网页资源台仍按本对象 Manifest 展示逐动作 GIF。
- 历史 001～007、四法并排对照图已从工作树清除，恢复依据为清理前提交 `7c6c62d`（`git show 7c6c62d:<项目相对路径>`）。已分配版本上限为 008，不复用编号。下文保留研究结论与当时的验证记录；旧资源路径仅供历史追溯，不能作为当前预览命令。

## 历史研究记录

## 目标与输入

- 同一 Guard 身份：棕色短发、圆框眼镜、深灰校园外套、浅蓝衬衫、青色学生证、斜挎包、白鞋、右手霓虹单手剑、左前臂防火墙盾。原参考为[组合概念 002](../../../design/concepts/characters/guard/concept_002/m1_guard_loadout_concept_002.png)。
- 共同比较动作：`idle`、`move`、`melee`、`cast`、`hurt`；001～004 使用 512×512 画布，005～007 的即梦近战使用 1024×512 安全画布、256×128 展示尺寸，保留 0.45 出手比。各版画布与脚底数值以自身资源和元数据为准。
- 当前正式角色仍使用原有造型与动画。候选只通过 `run-motion-preview.ps1 -Animation` 临时覆盖预览，不写入 `resources/content/characters/guard.tres`。

## 候选与发现

| 候选 | 方法与可看文件 | 本次观察 | 判断 |
| --- | --- | --- | --- |
| 001（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/001/review/contact-150.png`） | 内置 `image_gen` 根据 002 概念先出透明待机图，再定向生成 6 张独立关键姿势；统一缩放脚底后由 SpriteFrames 播放。Godot 并排近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-melee.gif`） 左列为本候选。 | 剑击、盾展开和受击剪影清楚；跑步两姿势明显变形，切换时脸部、盾宽和服装细节漂移。真实预览待机完全静止，近战与施法关键姿势仅短暂显示。生成图看起来约 5～6 头身，未达到 4 头身生产规范。 | 适合作动作探索和关键姿势草案；需人工统一比例、身份、补中间帧与停留时间，才可评审正式资产。 |
| 002（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/002/review/godot-melee-1920x1080.png`） | 只用 001 待机图做平移、轻旋转和缩放，烘焙为同样五动作的 SpriteFrames。Godot 并排近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-melee.gif`） 中列为本候选。 | 角色像素身份稳定、制作快；身体与剑盾作为一块运动，移动没有腿步，近战出手缺清楚剑击。 | 仅适合待机呼吸／轻受击补偿，不能独自承担 Guard 战斗动作。**这不是完整的粉笔精灵式分层骨骼**，不能据此否定完整混合路线。 |
| 003（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/godot-idle-1920x1080.png`） | 最小混合后端：从同一待机图确定性切出主体、头、盾；`Skeleton2D`／`Bone2D`／`AnimationLibrary` 驱动待机与受击，移动、近战、施法回退 001 序列帧。Godot 并排受击（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-hurt.gif`） 第三列为本候选；施法骨骼失败对照（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/cast-bone-vs-fallback.png`）保留试验。 | 受击后撤能读出且身份稳定；施法只旋转现有盾牌无法表达防火墙展开，因此改用替换姿势。只做了头、盾与根节点，衣袖、前臂、腿和剑仍没有可任意旋转的隐藏面。 | 证明混合控制器对 Guard 可运行，也证明此静帧缺少的盾牌形态不能靠骨骼转角补出；**没有**证明全身人物骨骼动画可量产。正式路线需补画分层原画与遮挡。 |
| 004 MiniMax H3（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/review/melee-contact.png`） | 由[固定绿幕首帧](../../../design/concepts/characters/guard/asset_008/source/identity-first-frame.png)向中国站 V2 API 分别请求五段 768P／4 秒视频；每段采样九帧、抠绿、对齐脚底后进入同一 Godot 预览器。并排近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-melee.gif`）第四列为本候选。 | 连续步态、近战冲刺、盾牌展开与受击闪光有明显运动信息；剑长与盾宽在转身时漂移，部分剑尖／特效出画，抠像边缘残留彩色噪点。压至 0.45 秒战斗行动后，关键细节易被跳过。 | 最适合动作构思与效果参考；原片和自动抠像帧均不能直接升级正式游戏资产，需人工修形、择帧、重定时。 |
| 完整粉笔精灵式混合 | 在 003 基础上重建上／前臂、手、腿、剑、盾的遮挡和隐藏面；轻动作走骨骼，剑击与强遮挡走替换姿势／序列帧。 | [粉笔精灵 006](chalk-spirit.md)已验证共享控制器，但 Guard 多个关节遮挡需要新分层图。旧 M1 人物动态实验的翻折失败见[M1 任务](m1-player-cast.md)；003 只证实一个保守局部。 | 生产候选优先级最高，但应先做经人工校对的右臂／盾遮挡短样本，再扩大五动作。 |

同规格真实运行对照：0.55 秒（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-contact-550ms.png`）、0.75 秒（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-contact-750ms.png`）静帧总览，以及待机（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-idle.gif`）、移动（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-move.gif`）、近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-melee.gif`）、施法（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-cast.gif`）、受击（历史文件 `7c6c62d:design/concepts/guard-animation-study/review/runtime-hurt.gif`）。从左到右是 001／002／003／004；并排 GIF 从四组各自的 Godot 30 FPS／352×352 原始录制按同一时间轴采样至 15 FPS，方便同步对照，原录制保留在各候选的 `review/*-preview.gif`，制作脚本为 `compare_runtime.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/compare_runtime.py`）。这仍是 128×128 人物的独立预览，不等于复杂战场中的辨识度验收。

完整 Godot 截图：001 近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/001/review/godot-melee-1920x1080.png`）、002 近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/002/review/godot-melee-1920x1080.png`）、003 待机（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/godot-idle-1920x1080.png`）、003 施法（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/godot-cast-1920x1080.png`）、003 受击（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/godot-hurt-1920x1080.png`）、004 施法（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/review/godot-cast-1920x1080.png`）、004 受击（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/review/godot-hurt-1920x1080.png`）。001～003 的 PNG 源具有透明通道；H3 首帧为不透明 RGB，经抠像生成 004 透明采样帧。四组 `*-preview.gif` 都来自 Godot 逐帧录制。输入、归一化、烘焙规则由关键姿势构建脚本（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_previews.py`）、混合样例构建脚本（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_hybrid.py`）、H3 切帧脚本（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_h3_candidate.py`）与归一化实测（历史脚本 `7c6c62d:design/concepts/guard-animation-study/normalization.json`）保存，可复跑。资产登记见[Guard 动画研究 Manifest](../../../assets/art/manifests/characters/guard.yaml)；均为 `unselected + pending + not_integrated`。

## H3 原片与处理

使用 001 的 `normalized/idle.png` 派生出的 [512×512 不透明绿幕首帧](../../../design/concepts/characters/guard/asset_008/source/identity-first-frame.png)，其制备脚本为 `prepare_h3_input.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/prepare_h3_input.py`）。绿色背景 RGB 为 `(24, 255, 102)`；它让后续抠像有明确目标，但模型是否保持均匀背景仍须实测。首帧使用现有 001 的约 5～6 头身，因此 H3 结果也不能据此宣称满足正式 4 头身要求。

选 `MiniMax-H3`、768P、4 秒，单动作单请求；先生成 `melee`、`move`，观察后完成 `idle`、`cast`、`hurt`。首帧模式未混入 `reference_image`。`h3_generate.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/h3_generate.py`）默认只验证请求，显式 `--submit` 才读取进程环境变量 `MINIMAX_API_KEY` 并提交；任务 ID 与原提示词留在本地各动作 JSON 中，支持续查。中国站密钥使用 `https://api.minimax.cn/v2` 成功；国际站 `api.minimax.io` 返回 401，两站凭据不能混用。根目录 `api.txt` 仅本机使用且被 Git 忽略，密钥没有写入任务、资源或代码。

```powershell
& 'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' design/concepts/guard-animation-study/h3_generate.py --action melee
# 使用中国站密钥时，从忽略的本地 api.txt 读入进程环境变量，再按动作执行 --submit。
```

原视频：待机（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/source/idle.mp4`）、移动（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/source/move.mp4`）、近战（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/source/melee.mp4`）、施法（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/source/cast.mp4`）、受击（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/source/hurt.mp4`）；五动作源片抽样（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/004/review/melee-contact.png`）中的单动作接触表见 `guard/004/review/*-contact.png`。原片为 768×768、24 FPS；每动作 0～4 秒按 0.5 秒采九帧，角点颜色估计绿幕、去色溢、归一至 512×512 并对齐脚底 y=485，生成 45 张 RGBA 帧和 `battle_animation.tres`。004 的 `critical` 借待机帧、`death` 借既有回退，均非 H3 新动作。自动处理保留了源片剑尖出画、武器变形和彩色边缘，不能把技术入引擎当作质量批准。[中国站 API](https://platform.minimax.cn/docs/api-reference/video-generation-v2-create)与[官方请求样例](https://github.com/MiniMax-AI/MiniMax-H3/blob/main/scripts/readme/full-2k-i2va-reference-768p-result-by-directly-calling-open-platform-api.sh)说明请求格式。

## 验证与边界

- 2026-09-25，当前工作树，使用随 Codex 工作区提供的 Python/Pillow 12.3 运行 `design/concepts/guard-animation-study/build_previews.py` 与 `build_hybrid.py` 成功；7 张源图归一后，001／002 各生成五动作 GIF 与资源文件，003 生成三部件骨骼场景与待机 GIF。003 重新组合图对原待机图的逐通道平均绝对差为 0.0082（0～255 量纲）；这是静止复原度，不代表动态遮挡无瑕疵。
- Godot 4.7.2 增量导入后，三候选均使用 `pwsh.exe -File ./run-motion-preview.ps1 -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/guard-animation-study/guard/00X/battle_animation.tres -Check`；待机、移动、近战、施法、受击、濒危、退场通过，远程按角色能力跳过。003 的待机、受击走骨骼，移动／近战／施法回退序列帧。濒危仅借待机帧通过接口检查，退场来自旧 Guard 回退，不是本轮制作的新动作。
- 三候选 `-Action Melee -Capture` 均取得 1920×1080、2560×1440、1920×1200 真实预览截图；003 另用 `-Action Idle -Capture`。已人工查看三版 1920×1080 截图和 003 的离线待机运动抽样。初版五动作 GIF 为离线烘焙；后续三版均补录 Godot 实际画面，仍需慢速、暂停与更多游戏状态视觉复核。
- 003 的独立骨骼与回退检查（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/hybrid_check.tscn`）在 Godot 4.7.2 headless 运行得到 `GUARD_HYBRID_CHECK PASS`，直接验证 `idle` 两根骨骼转角变化及 `melee` 序列帧回退；只有既有系统根证书报错，没有新脚本或骨骼矩阵错误。
- 2026-09-25，003 增加真实受击骨骼轨道，独立检查确认受击时头和盾转角、近战与施法回退；`-ExportPreviews` 以 Godot 实际画面生成五动作 30 FPS／352×352 GIF，捕获记录显示 `idle`／`hurt` 由骨骼承担，`move`／`melee`／`cast` 有序列帧回退。资源总表有内嵌对象条目，曾使导出器把字典误当路径；已让导出器跳过非路径条目。施法骨骼试验最大盾转角 0.22 rad，实际对照帧（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/003/review/cast-bone-vs-fallback.png`）显示只是现有盾牌旋转，无法出现展开轮廓，因此不保留为最终后端。游戏施法动画在 0.45 秒行动中仅短暂显示替换姿势，仍需专门安排出手帧与停留时间；这不是完整施法动作验收。
- 2026-09-25，001／002 同样用 `-ExportPreviews` 各导出五动作真实 Godot GIF。三版共 15 个原录制均为 352×352、3 秒动作预览，按 0.55 秒取静帧及 15 FPS 同步 GIF 比较。001 待机录制合并为单张静帧，移动有步态但轮廓跳变；002 有小幅整体运动却没有独立剑击或腿步；003 待机／受击连续活动，其他动作回退 001。001 施法关键姿势在录制的约 0.47～0.67 秒出现，确实存在但停留过短；0.55 秒近战是蓄力姿态，不能单凭一帧评判完整攻击。`compare_runtime.py` 可从原录制重建对照，原 GIF 保持 30 FPS；并排 GIF 仅按 15 FPS 抽样，不作为流畅度评分依据。
- 2026-09-25，H3 首帧为 512×512 RGB PNG、203250 字节。中国站 API 五动作各提交一次，五个视频均下载成功。运行 `build_h3_candidate.py` 得 45 张透明帧、五张源片接触表和 004 资源；`run-motion-preview.ps1 -Unit Guard -Animation design/concepts/guard-animation-study/guard/004/battle_animation.tres -Check` 通过，`-ExportPreviews` 得五动作 Godot 原录制，`-Action Cast -Capture`／`-Action Hurt -Capture` 得实际 1920×1080 截图并已人工查看。`compare_runtime.py` 重建四组同步 GIF 与 0.55／0.75 秒静帧总览。视频源片 4 秒、约 24 FPS；Godot 录制为 352×352、30 FPS、3 秒对照。录制检验的是候选的可运行性，不是游戏战场通过。
- 已知质量缺口：比例未达 4 头身，001 逐姿势细节漂移；002 无独立肢体运动；003 的刚性分层只覆盖头盾待机与受击，未验证上／前臂和腿；004 武器与盾牌在连续视频中变形，局部出画，透明化后有色边，且压缩至短行动时效果难读。四者都不是可提升的正式角色资产。原 M1 人物 023 的网格翻折问题未因本轮得到解决。**待统筹**：若后续选择新人物动画管线，需评估角色生产成本和 Web／移动表现；本轮不改 Roadmap 或总览。

## 评审

002 角色概念及剑盾方向的原批准沿用 [M1 任务](m1-player-cast.md)；本轮 001／002／003／004 动态候选和接入效果均待负责人评审，不填造批准决定。生产建议优先补画可分层的 4 头身 Guard 静帧，用骨骼做轻动作、关键姿势做剑击与盾展开；H3 更适合作运动与特效参考。正式生产须先确认静帧与分层／关键姿势版本，再进入资产批准和接入流程。

2026-09-27 负责人看过游戏内预览后反馈：“明显这个动画抽帧的效果好得多”，指向 004 H3 视频抽帧相对 001～003 的动作观感。故将下一轮**方法试验**优先级调为视频图生视频＋择帧修形；原骨骼优先建议保留为当时的技术推论，不再作为 Guard 当前首选。沿用同一首帧只做一条[武器完整性近战提示词试验](../prompts/guard-h3-melee-frame-test.md)，逐帧比对剑尖、握持、盾缘和实际战斗尺寸的出手读性。不把负责人对相对观感的肯定记为 004 的资产或接入批准。[Skill 与文章提示词核查](../../research/guard-character-action-design.md)及[更新后的方法判断](../../research/guard-animation-methods.md)记录依据。

2026-09-27 比例试验边界：负责人提出当前约 5～6 头身的动画观感不错，询问能否先不以 4 头身规范限制抽帧路线。本任务据此继续使用相同比例的首帧验证 H3 动作，比例不作为本轮淘汰项。正式采用 6 头身尚未决定；届时需在实际战斗尺寸、多人同屏及目标小屏上比较动作与武器读性、角色占格和与其他单位的视觉统一性。若效果成立，再按负责人决定修订角色规范和同系列人物方案；本轮不改全局 4 头身条款。

### 005 · 即梦近战视频抽帧试验（2026-09-27）

负责人提供一条即梦／Dreamina 图生视频；MP4 元数据确认来源，并非 MiniMax H3 输出。源片为 1280×720、约 4.1 秒、可变帧率，固定绿幕和完整角色。用 `build_jimeng_melee_candidate.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_jimeng_melee_candidate.py`）按**实际视频时间戳**择取 12 帧，抠绿并保持横纵比，放在 1024×512 安全画布内；显示尺寸 256×128、统一脚底。最初按帧号／平均帧率取样会把动作时间取错，已改为逐时间戳 seek。005 仅新增 `melee`；待机、移动、施法、受击采用 004 原帧横向补边作预览衔接，濒危借待机，退场仍用既有回退。不能把 005 称作即梦生成的完整五动作组。

原片（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/005/source/melee.mp4`）、12 帧接触表（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/005/review/melee-contact.png`）、Godot 实际近战 GIF（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/005/review/melee-preview.gif`）、004／005 同时间对照（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/005/review/compare-runtime-004-005.png`）及1920×1080 游戏截图（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/005/review/godot-melee-1920x1080.png`）均保留。原片抽样的起手、横挥、突刺和收势中，剑柄、剑身、剑尖连续；12 张透明帧的四边无 alpha>30 的触边像素。004 在出手姿势丢剑尖；005 的该问题明显改善。005 攻击峰值的盾牌被身体挡住较多，蓝色刀光一度贴近源画面右缘，局部发丝和绿幕仍可能在低分辨率闪烁，需要负责人逐帧判断。起手与借用的 004 待机也有轻微姿态差异。

Godot 4.7.2：`run-motion-preview.ps1 -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/guard-animation-study/guard/005/battle_animation.tres -EnsureImport -Check` 通过；`-Action Melee -Capture` 得 1920×1080、2560×1440、1920×1200 实际截图，均已生成，1920×1080 已人工查看；`-Action Melee -ExportPreviews` 得 30 FPS、608×352 真正游戏时序 GIF。为宽画布修正放大预览的等比缩放和导出视口宽度，其他方形候选尺寸保持原样。此版依旧 `unselected + pending + not_integrated`，不修改正式 Guard。下一步先请负责人看 005 的攻击读性；若选用此路线，还需补齐同源 `idle`、`move`、`cast`、`hurt` 并处理盾遮挡，再作多人同屏和小屏验证。

负责人补充反馈：005 人物肤色比输入参考偏红、更接近真人肤色。复核起手帧发现偏色已在即梦原片中出现，抽帧抠绿没有造成主要偏差；脸部近似肤色区域中位 RGB 为参考约 `(249,222,196)`、原片约 `(230,194,172)`、透明帧约 `(229,193,171)`，取样只作方向判断。角色同时偏暗、偏暖。建议保留运动和剑盾成果，先对脸、颈、手做相同目标色的跨帧局部校色样片并与原版并排评审；避免全画面调色改变盾牌蓝光、剑光和衣服，也避免逐帧生成导致五官闪烁。若局部校色无法稳定，再用更明确的肤色／阴影约束重生近战。005 原片与候选保持不变，修色结果需单独版本评审。

### 006 · 重新择帧与肤色校正（2026-09-28）

按负责人要求，在原 005 MP4 上重新按视频呈现时间抽取 24 张近战姿势；0.60～1.48 秒挥剑／突刺区间加密，采样时间记录在帧元数据（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/battle_animation.frames.json`）。24 帧均匀映射至预览动作的 4 秒，并把第 10 帧的突刺放在游戏出手比例 0.45 附近。这是动作重定时，**并非**原视频连续 24 FPS 回放。其他动作沿用 005，正式 Guard 不受影响。可用`build_jimeng_melee_refined.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_jimeng_melee_refined.py`）复建。

肤色以输入[首帧](../../../design/concepts/characters/guard/asset_008/source/identity-first-frame.png)的脸部中位色为方向，视频起手脸部取样为 `(231,194,173)`，参考约 `(249,222,197)`，全段统一使用 `(18,28,24)` 的 RGB 增量；肤色种子先筛色、去噪，再在相近暖色范围内轻微扩张和羽化。脸、颈、可见手部调整，alpha、剑盾和蓝色刀光不改。修色前（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/melee-contact-before.png`）、修色后（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/melee-contact-after.png`）及遮罩（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/skin-mask-contact.png`）可逐帧核对。内置 imagegen 也按“只将皮肤调至首帧、完全保持轮廓与装备”做过目标样帧（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/imagegen-skin-direction-rejected.png`），但重画了局部造型，故仅作颜色方向参考，**未**用作序列帧。

Godot 实际近战 GIF（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/melee-preview.gif`）与1920×1080 截图（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/006/review/godot-melee-1920x1080.png`）已生成。Godot 4.7.2 用 `./run-motion-preview.ps1 -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/guard-animation-study/guard/006/battle_animation.tres -EnsureImport -Check` 通过；同入口 `-Action Melee -Capture` 生成三分辨率截图，`-Action Melee -ExportPreviews -PythonPath <Pillow Python>` 录制 30 FPS／608×352 运行 GIF。清理编辑器生成的无关导入描述后，不加 `-EnsureImport` 再次 `-Check` 通过；006 的 24 个近战 PNG 导入描述保留。24 帧均为 1024×512 RGBA，邻帧不同，四边 alpha≤30。资产目录扫描 errors=[]、Guard warnings=[]、缺失文件 0，资源台 33 项单测通过。006 仍是 `unselected + pending + not_integrated`；峰值盾牌遮挡、起手和借用待机的衔接、真实多人同屏读性仍待人工评审。

2026-09-28 预览入口纠错：此前给负责人的相对 `-File ./run-motion-preview.ps1` 命令可能在另一份主仓库运行；主仓库没有 006，且预览器原本对缺失的 `-Animation` 只记录警告并回退占位资源。现脚本先核对动画路径属于本 checkout 且文件存在，缺失时直接失败。实际查看 006 请运行 `pwsh.exe -File 'C:/Users/SongJun/.codex/worktrees/2425/godot_xinan1/run-motion-preview.ps1' -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/guard-animation-study/guard/006/battle_animation.tres -Action Melee -EnsureImport`。预览左侧是 006 守护者，右侧“纸甲守卫”仍是用于展示命中的测试目标。

### 007 · 对齐待机色板（2026-09-28）

负责人反馈 006 整体偏红，要求对比待机和动作。对照 005 沿用的 `idle_00` 与 006 `melee_00` 后发现：起手脸部亮色已接近待机，但视频里的浅蓝衬衫、剑盾和白鞋偏暗，后半段脸部绿色通道进一步降低。由此制作007 比较图（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/007/review/idle-palette-comparison.png`）与24 帧接触表（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/007/review/melee-contact.png`），保留 006 供并排判断。所列 RGB 是固定区域内近似材质像素的中位数，用于判断方向，不是角色色板规范。

| 区域 | 待机参考 | 006 起手 | 007 起手 |
| --- | --- | --- | --- |
| 脸部 | `(246,219,194)` | `(248,221,195)` | `(246,219,193)` |
| 棕发 | `(89,68,59)` | `(88,65,61)` | `(89,68,60)` |
| 浅蓝衬衫 | `(195,210,241)` | `(170,188,221)` | `(194,212,242)` |
| 蓝色盾面 | `(80,170,226)` | `(84,165,216)` | `(81,173,226)` |
| 白鞋 | `(229,222,216)` | `(210,202,200)` | `(227,219,214)` |

`build_guard_palette_match.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_guard_palette_match.py`）对 006 的 24 张原帧施加同一平滑材质色彩映射：浅色衣物与鞋提亮，蓝青装备恢复冷色；肤色遮罩以待机脸部中位色为目标，按帧计算小幅修正并平滑相邻帧。所有原帧 alpha 逐像素相同，最大可见 RGB 单通道改动 28；不重画任何轮廓。内置 imagegen 的“动作帧只匹配待机色彩、不改变形状”样本仍重画了部分人物与剑盾，只用于确认调色方向，未放入 007。007 沿用 006 的 24 帧动作时间与 005 的其他四动作。

Godot 近战 GIF（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/007/review/melee-preview.gif`）与1920×1080 实际截图（历史文件 `7c6c62d:design/concepts/guard-animation-study/guard/007/review/godot-melee-1920x1080.png`）用于看游戏尺寸的连续效果。Godot 4.7.2 以绝对脚本路径执行 `-Animation res://design/concepts/guard-animation-study/guard/007/battle_animation.tres -Action Melee -EnsureImport -Check` 和 `-Capture` 通过；`-ExportPreviews` 输出 30 FPS／608×352 GIF。清理无关导入描述后，不加 `-EnsureImport` 的重复 `-Check` 通过；资产登记扫描 errors=[]、缺失文件 0、Guard warnings=[]，资源台 33 项单测通过。007 仍为 `unselected + pending + not_integrated`；当前改动仅作用于近战帧，正式 Guard 和既有待机图未修改。

### 008 · 压低近战帧整体暖红偏色（2026-09-29）

负责人继续指出 007 整体略偏红，要求再次对比待机与动画。逐帧检查表明，脸部亮色经过 007 已基本接近待机，但近战第 12 帧的浅色区域失去蓝调：在相同的高亮、低饱和、非背景近似取样下，`B−R` 中位数从 007 的 `-5` 变为 008 的 `+13`；待机参考为冷调。该取样混有衣物、鞋和少量其他亮色，只用于偏色方向，不能充当正式色板。

[008 待机／近战并排](../../../design/concepts/characters/guard/asset_008/review/idle-melee-palette-comparison.png)同时展示起手、出手和收势；[24 帧总览](../../../design/concepts/characters/guard/asset_008/review/melee-contact.png)、[Godot 近战 GIF](../../../design/concepts/characters/guard/asset_008/review/melee-preview.gif)与[1920×1080 实际游戏截图](../../../design/concepts/characters/guard/asset_008/review/godot-melee-1920x1080.png)供连续与实际尺寸评审。[`build_guard_neutral_palette.py`](../../../tools/art/animation/guard/build_guard_neutral_palette.py)从 008 本地保存的历史 007 源帧读取动作和 Alpha，只对浅色中性材质、暗部和部分偏灰蓝装备施加同一组连续颜色规则；肤色仅轻微冷却。24 帧的 Alpha 逐像素完全相同，最大单通道 RGB 变化为 16；武器轮廓、采样时间、出手比、待机／其他动作均不变。

按负责人要求，已把 [`Character_Action_Design` Skill](https://github.com/guiguiyan930-source/Character_Action_Design) 安装到本机 Codex skills，并将其“四锁”规则用于[本次近战动作卡](../../../design/concepts/characters/guard/asset_008/action-card.yaml)：身份、左盾右剑、持手数量和待机色板。此 Skill 是动作设计与提示词契约，不直接修色；008 的像素修正由确定性脚本完成。现有 002 参考是负载概念与肖像，并非三视图，因此动作卡只覆盖当前右向片段，不宣称已验证八方向或 16 帧工作流。

Godot 4.7.2 使用本工作树的绝对 `run-motion-preview.ps1`，008 `-EnsureImport -Check` 以及随后不带 `-EnsureImport` 的重复 `-Check` 均完成，后者日志为 `MOTION_PREVIEW_CHECK failures=0`；`-Action Melee -Capture` 生成 1920×1080、2560×1440、1920×1200 三种实际截图，1920×1080 已人工查看；`-ExportPreviews -Action Melee` 得 30 FPS／608×352 的完整进入／出手／返回待机 GIF。资源台扫描为 `errors=[]`、Guard `warnings=[]`、缺失 0、不一致 0。008 为 `unselected + pending + not_integrated`。它改善了后段浅色衣物的暖调，仍有源视频固有的脸型／发型细节和剑盾造型漂移，起手与沿用 005 待机的姿态衔接未由修色解决；是否比 007 更合眼需负责人看连续 GIF 决定。

2026-09-30 网页预览补录：003 与 008 分别运行 `run-motion-preview.ps1 -EnsureImport -ExportPreviews`，补齐七动作 GIF 和 `review/all-actions.gif`；同步真实 `SpriteFrames` 的六个动作到 `battle_animation.frames.json` 的 `clips`，让美术资源浏览器显示逐动作按钮。在 `http://127.0.0.1:8765/` 选“人物”→“Guard 动画方法对照”→003 或 008→“动画”即可预览，[008 网页近战截图](../../../design/concepts/characters/guard/asset_008/review/art-browser-melee-2026-09-30.png)展示实际页面。退场 GIF 是运行时旧 Guard 回退，未列为这两版的新动作；003 的濒危也沿用旧帧。资源台两版校验通过，GIF 可在网页加载，批准状态仍为待评审。

### 003／008 · 濒危与退场独立静帧（2026-09-30）

负责人接受精度较低的过渡，要求濒危和退场至少拥有不同于待机的静态帧。以 005 待机为身份参考生成一张透明双姿势源图，左侧为弯膝低头、剑盾下垂的濒危姿势，右侧为剑盾留在身旁的侧卧倒地姿势；两版分别保存可追溯源图与裁切结果。003 采用 512×512，008 采用 1024×512；[`add_defeat_poses.py`](../../../tools/art/animation/guard/add_defeat_poses.py)固定脚底、增补 `SpriteFrames` 的 `critical`／`death` 片段及网页动作索引。生成提示词见[濒危与退场静帧](../prompts/guard-critical-death-stills.md)。

[008 双姿势对照](../../../design/concepts/characters/guard/asset_008/review/critical-death-stills.png)、[Godot 濒危截图](../../../design/concepts/characters/guard/asset_008/review/godot-critical-1920x1080.png)、[Godot 退场截图](../../../design/concepts/characters/guard/asset_008/review/godot-death-1920x1080.png)确认轮廓与剑盾完整；003 也保留对应的实际截图。两版 `-EnsureImport -Check` 均得到 `MOTION_PREVIEW_CHECK failures=0`，濒危与退场各 `-Capture` 得到三种分辨率截图，`-ExportPreviews` 重录七动作 GIF 和全动作巡演。退场立即切换侧卧姿势，随后仍按既有表现层渐隐；姿势间没有过渡帧。两版仍为 `unselected + pending + not_integrated`，不代表资产批准。

### 008 留存收尾（2026-10-01）

负责人明确“guard 只要 008”。合入 `main` 的规则提交 `c39f08a` 后，Guard 008 保留原编号与路径，历史 001～007 和四法并排候选从当前工作树移除；删除前的完整恢复基线为 `7c6c62d`。008 的动画资源不再引用 005：62 张运行帧均在 `guard/008/frames/`，其中 24 张近战、36 张其他四动作、2 张濒危／退场静帧。即梦原片、原始身份首帧、24 张调色前帧和双姿势源图也在 008；`build_guard_neutral_palette.py` 与 `guard_008_palette_helpers.py` 可从这些源帧重建近战色彩，`add_defeat_poses.py` 可重建两张退场姿势。重建后 24 张近战 PNG、两张静帧与清理前 SHA-256 完全相同，动画资源只发生路径自持化调整。

Godot 4.7.2 在 `design/.gdignore` 生效且 008 无 `.import` 描述时，以 `run-motion-preview.ps1 -EnsureImport -Unit res://resources/content/characters/guard.tres -Animation res://design/concepts/characters/guard/asset_008/battle_animation.tres -Check` 验证，待机、移动、近战、施法、受击、濒危、退场七态 PASS，远程按能力 SKIP，`failures=0`。近战、濒危、退场均重新运行三分辨率截图捕获；上述 1920×1080 图已人工查看。资源台 Manifest 扫描 51 对象、缺失 0、不一致 0、错误 0、Guard 警告 0；Guard 仅登记 008，状态为 `selected + pending + not_integrated`。这表示留存选择，不构成正式资产或游戏接入批准。
