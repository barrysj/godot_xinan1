# Guard 角色动画生产方式调研

## 已采纳结论（2026-10-10）

首选人形（友方＋敌方）采用职业原配开源 3D 模型／动作 → 模型内派生与道具变化 → 水平正交导向 → 已批准身份约束下的整身日系 2D 转绘 → 固定画布 SpriteFrames → 原战斗运行与程序特效。正式规则已回写[美术工作流](../art/WORKFLOW.md#人形动画生成友方敌方首选)，获批交付与混合来源例外见[M1 任务](../art/tasks/m1-player-cast-animation.md)。本文件其余内容为历史研究和当时上游核验，不代表当前价格／版本或已实现的运行时换装能力。中间实物按负责人最新一版授权清理，只保留最终源与最少证据。

调研日期：2026-09-25。目标是用同一个 Guard 概念制作可公平比较的短动作组；本文件记录官方能力、路线判断及本次 H3 验证，具体成片评价见[Guard 动画方法对照](../art/tasks/guard-animation-study.md)。这不是资产批准或正式运行接入。

## 项目输入和比较基线

- 身份依据：`design/concepts/characters/guard/concept_001/m1_guard_identity_reference_002.png` 与同目录的剑、盾、组合概念。002 人物身份和霓虹单手剑、防火墙盾方向已获批准；没有获批的动态 Guard 原画。具体批准边界见[我方角色样板](../art/tasks/m1-player-cast.md)。
- 游戏中的 4 头身战斗角色与 7 头身资料立绘应保持发型、服装和核心配饰一致，见[角色规范](../art/specs/CHARACTER_SPEC.md)。比较样本统一采用 4 头身战斗视角；若 002 参考偏向概念立绘，先派生同一 Guard 的战斗静帧并保留身份对照，不把模型自行重设计的人物视为同一角色。
- 最小动作组建议为 `idle`、`move`、`melee`、`cast`、`hurt` 五项；若时间允许再补 `critical`、`death`。每项展示入场静止、动作与返回静止（死亡停末帧），同一画布、脚底、朝向、尺度、动作时长与出手点；详见[战斗动画契约](../battle-animation.md)。剑、盾的前后遮挡和武器握持是主要观察点。所有方法用相同展示大小、播放速度和 Godot 预览器，而不是只比源视频的观感。
- 2026-09-25 的项目记录已明确：此前人物动态实验的 022 过于抽象、023 出现衣袖／前臂与裤腿交叠处网格翻折，均未通过；这条失败证据不能被粉笔精灵的成功直接抵消，见[ART-03](../implementation/art-03.md)与[角色任务](../art/tasks/m1-player-cast.md)。

## 可行方法

| 路线 | 制作与 Godot 接入 | 适合 Guard 的位置 | 成本与主要风险 | 当前证据 |
| --- | --- | --- | --- | --- |
| A. Godot 刚性分层＋必要手绘关键姿势／序列帧 | 从同一静态设计划出头发、躯干、上／前臂、手、腿、剑盾；为关节补被遮住的像素，明确绘制顺序和枢轴。用 `Skeleton2D`／`Bone2D`／`AnimationPlayer` 做低变形动作，攻击极端姿势和死亡可用独立帧；接现有混合表现控制器。 | 最值得作为生产基准。角色和配件不随帧重生，可反复调时间与出手点。前臂遮挡、侧身与衣袖仍需专门重画／切层。 | 美术拆件与关节修复工时高；若硬把二维扁平剪片当可任意旋转的人体，会重现翻折和纸片感。应限制关节旋转范围，极端角度切换替代画片，不继续靠复杂网格蒙皮挽救。 | 项目粉笔精灵分层样本已验证运行包；人物本身仍需独立验证。[Godot cutout 官方教程](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html)说明剪片、骨骼与逐帧混用；[Godot 2D 骨骼教程](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html)说明 Polygon2D 蒙皮与 Bone2D。 |
| B. Guard 专属逐帧绘制／图生图关键姿势＋人工修帧 | 为每项动作先画极端姿势、出手和收招，补中间帧；输出统一透明 PNG 帧，沿现有 `SpriteFrames`／图集工具入 Godot。可用生成图作姿势草稿，但逐帧锁身份和细节。 | 剑击、盾展开、受击和死亡等遮挡变化大的动作；也可作为 A 的补充。 | 每帧工时、帧间一致性与修图成本高；模型逐张生成的发型、脸、衣纹、手指、剑盾形状容易漂移。 | [Godot 2D 精灵动画](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)支持独立图或图集；[Krita 官方动画导出](https://docs.krita.org/en/reference_manual/render_animation.html)支持 PNG 序列。项目已有 Guard 的旧 16 姿势运行样本，但与此次 002 概念不同，不可当作当前身份验证。 |
| C. MiniMax H3 首帧／首尾帧／多参考图视频，再切帧 | 用已确认的 Guard 4 头身静帧作 `first_frame`；可再给匹配待机姿势的 `last_frame`，便于动作回环。或以多个 Guard 视角／配件图作为 `reference_image`。各动作独立生成，输出视频经过选帧、抠像／去背景、稳定尺度与脚底、重绘坏帧后入 `SpriteFrames`。 | 快速探索动作节奏、武器姿势、视觉效果；可能挑出少量可修成序列帧的动作。 | 视频不直接给可编辑骨骼、真实 Alpha 或游戏动作标记；身份漂移、手与盾互穿、起止帧跳变都必须实测。生成费按输出秒计，返工次数增加费用。仅推荐作为比较候选与动态参考，不能凭视频可看就宣布可接入。 | [MiniMax V2 创建 API](https://platform.minimax.io/docs/api-reference/video-generation-v2-create)确认模式、长度、格式和限制；[官方价格](https://platform.minimax.io/subscribe/token-plan?tab=api-enterprise)提供计费。 |
| D. Spine 专业 2D 骨骼 | 从完整分层 Guard 原画绑定一套共用骨架，换装／相近体型角色用 skins 复用动作；Godot 可用官方 `spine-godot` GDExtension 播放，或从 Spine 导出透明 PNG 序列接现有 `SpriteFrames`。 | 多名相近体型角色共用待机、移动、受击等动作时更有价值；剑击、盾展开仍可能要单独画片和关键姿势。 | 现有整张 PNG 需要补画分层与隐藏面，跨不同骨架并非自动重定向；编辑器许可证、扩展版本与目标平台也需验证。只做 Guard 时可先用现有 Godot 骨骼验证美术成本。 | [Spine skins](https://esotericsoftware.com/spine-skins)、[跨项目动画导入条件](https://esotericsoftware.com/spine-import)、[spine-godot](https://esotericsoftware.com/spine-godot)、[PNG 序列导出](https://esotericsoftware.com/spine-export)。项目可行性分析见下节。 |
| E. Blender Grease Pencil／Krita 手工逐帧 | 在绘画时间轴制作动作，渲染透明 PNG 序列，再走 B 的 Godot 接入。Grease Pencil 可用 2D 逐帧、点变形或父级／骨架驱动；Krita 适合传统逐帧修形。 | 需要真正变化的服装、手和盾轮廓时，作为 B 的制作工具；可做高质量 `melee`／`death` 对照。 | 工时明显高于短循环骨骼；需要明确像素密度和导出命名，工具不会自动给游戏状态机。 | [Blender Grease Pencil 官方动画说明](https://docs.blender.org/manual/en/3.0/grease_pencil/animation/introduction.html)列出逐帧、变形与骨架继承；[Krita 官方导出](https://docs.krita.org/en/reference_manual/render_animation.html)支持图像序列。Blender 链接是 3.0 手册，正式投入前应以安装版本复核界面。 |

### H3 的精确边界与成本

[MiniMax 国际站 V2 API](https://platform.minimax.io/docs/api-reference/video-generation-v2-create)使用 `POST https://api.minimax.io/v2/video_generation`；[中国站 V2 API](https://platform.minimax.cn/docs/api-reference/video-generation-v2-create)对应 `POST https://api.minimax.cn/v2/video_generation`。本次中国站凭据在国际站返回 401，切换中国站后五项任务成功。`model=MiniMax-H3`，请求必须有非空文本。H3 支持 `768P`／`2K`、整数 4–15 秒；首帧／尾帧图生视频与参考图／视频／音频模式**互斥**，不能在同一请求把 `first_frame` 和 `reference_image` 混用。图像输入支持 PNG 等格式，单图不超过 30 MB，边长 256–5760 像素，宽高比 0.4–2.5；参考图最多 9 张。官方说明输出 24 FPS。[官方模型说明](https://www.minimax.io/news/minimax-h3-open-source)可查帧率与模型结构。

国际站[官方定价页面](https://platform.minimax.io/subscribe/token-plan?tab=api-enterprise)列出 H3 768P 每输出秒 US$0.08、2K 每输出秒 US$0.13；这只是国际站公开价，**不能据此推算本次中国站账户的实际扣费**。五项动作均为独立收费请求，本次各成功提交一次；实际人民币账单以中国站账户记录为准。API 凭据不可写入项目文件或日志，本地 `api.txt` 已被 Git 忽略。

MiniMax [官方模型仓库](https://huggingface.co/MiniMaxAI/MiniMax-H3)列出本地权重，但官方同时说明 H3-Context-IR 托管预处理、2K 重生成部分未包含在开源发布中；本地部署不等于完整托管流程，也没有验证当前机器算力与许可证是否合适。[官方 `h3-prompt-writing` skill](https://github.com/MiniMax-AI/MiniMax-H3/tree/main/skills)是提示词结构化工具，能帮助首帧／参考图描述，不提供角色绑定、透明分帧或 Godot 接入能力；官方目录中的其他风格 skill 主要面向短片，不应称作已验证的游戏人物动作管线。

2026-09-25 补查：[官方 H3 CLI 的当前实现](https://github.com/MiniMax-AI/cli/blob/main/src/video/v2.ts)仍将生成分辨率固定为 2K，而 V2 API 已支持 768P。项目直接调用中国站 V2 API 完成 768P 五动作首帧视频。五段视频均为 768×768、24 FPS；实际 MP4 容器报告约 4.46 秒，比较处理仅取 0～4 秒。自动切帧使运动参考进入 Godot，但视频中剑盾几何与出画、绿幕边缘，以及短动作节奏都需要人工处理。此结论来自[本次样片](../art/tasks/guard-animation-study.md)，不代表模型所有模式或版本的上限。

### Spine 动画复用可行性（2026-09-26）

**结论：有条件可行，价值取决于同构角色的数量。** Spine 的 [skins](https://esotericsoftware.com/spine-skins)可在**同一骨架**上替换头发、衣服、武器等 attachment，让现有动画服务多个外观；皮肤约束还能为不同身材调整骨骼，但需逐皮肤设置，并非自动适配。[Linked meshes](https://esotericsoftware.com/spine-meshes)可跨 skin 共享网格结构、权重，按设置继承变形键。跨两个 Spine 工程也可[导入动画](https://esotericsoftware.com/spine-import)，前提是动画实际打键的骨骼、插槽、附件、事件、约束等名称匹配；网格变形键还要求顶点数一致，缺少目标项的键会被丢弃并报警。故可规划“学生型 4 头身共用骨架”，不能把旧 Guard PNG 或任何比例的人物直接套上现成动作。后两句是结合官方条件与本项目素材的推论。

| 复用层级 | 对 Guard 的实际含义 | 判断 |
| --- | --- | --- |
| 同一人物多套装备／服装 | 统一骨架、插槽与握持点，换发型／制服／剑盾 attachment；共用轻动作，特殊盾牌展开单独设附件切换和动画。 | 最稳妥的复用目标；须重新提供分层原画。[官方 skins](https://esotericsoftware.com/spine-skins)。 |
| 相近比例的第二名人物 | 尽量共用骨架与 `idle`／`move`／`hurt`，用 skins 换身体部件；较大比例差异可试 skin constraints。 | 技术可行但每套皮肤仍需验关节、脚底和握持。[官方身材约束示例](https://esotericsoftware.com/blog/Skin-constraints-for-different-proportions)。 |
| 不同骨架／武器动作 | 依赖打键对象同名导入，再修各角色；剑击、盾展开等高遮挡动作可能重画。 | 不应计为“一套骨骼动作自动通用”。[官方导入规则](https://esotericsoftware.com/spine-import)。 |

**美术前置成本。** 当前 001 的独立画片约 5～6 头身，正式战斗规范要求 4 头身；003 只从待机图安全拆出头、盾和主体，前臂／衣袖与裤腿的隐藏面不足。Spine 提供 slot、mesh、skin、draw order 编辑能力，却不会凭单张 PNG 补全这些不可见区域。Guard 真正的第一步是确认一张 4 头身正面／战斗朝向基准，重画头、躯干、上／前臂、手、两段腿、鞋、剑、盾及必要的遮挡替代画片；先在近战和施法极端姿势验证交叉顺序。此项是依据[角色规范](../art/specs/CHARACTER_SPEC.md)及[既有样片失败记录](../art/tasks/guard-animation-study.md)作出的项目推论。

**Godot 两条接法。** [官方 spine-godot 文档](https://esotericsoftware.com/spine-godot)提供 GDExtension，可把 `.skel`／`.spine-json`、`.atlas` 与 PNG 图集导入现有 Godot 项目，通过 `SpineSprite` 播放；它还提供 `AnimationPlayer` 集成与手动更新时间模式，但 GDExtension 没有专用 C# 绑定。项目当前的 `BattleAnimationSet.presentation_scene` 和 `apply_presentation(context)` 可作为适配层：先让 GDScript 包装节点接收 `state`、`age`、`duration`、`motion_time`、朝向及显示尺寸，再让 Spine 播放器跟随战斗模拟的时间，而非自行决定出手时刻。这个接法**尚未在项目中实现或验证**，要检查暂停、单步、变速、受击插入和 0.45 出手比。另一条是按[官方 PNG 序列导出](https://esotericsoftware.com/spine-export)烘焙五动作，复用现有 `SpriteFrames` 和预览／资源台；制作时仍能在 Spine 共用骨架，但游戏里失去运行时换装与连续骨骼调节，并增加逐角色逐动作图片量。PNG 导出提供透明通道与 FPS 设定，需固定画布和脚底后入包。

**版本与平台闸门。** 官方要求[为使用的 Godot 版本下载相应 GDExtension](https://esotericsoftware.com/spine-godot)，且[Spine 编辑器导出与 runtime 要锁定相同主、次版本](https://uk.esotericsoftware.com/spine-versioning)。这是两个不同的兼容维度。2026-09 的[官方论坛维护者回复](https://esotericsoftware.com/forum/d/30639-472-godot-spine-release)称 4.7.1 扩展可在 Godot 4.7.2 使用，同时正在制作 4.7.2 构建；这是上游反馈，**不是本仓库的运行验证**。本仓库当前没有 Spine 扩展或 Spine 原生导出文件；若选择运行时接法，应先在隔离样本验证 Windows 编辑器，再验证 Web／移动导出与 C# Mono 项目共存，不能从官方“支持平台”文字推断已通过。Spine 官方还允许在目标版本缺预编译包时[自行编译扩展](https://esotericsoftware.com/spine-godot)，但这会增加维护成本。

**许可证与先试范围。** [官方购买页](https://esotericsoftware.com/spine-purchase)在本次查阅时列 Essential 标价 US$69、Professional US$379（页面显示促销价，后续以结账为准）。Essential 支持基础骨骼和 skins，但不含 mesh、IK、skin bones／constraints；跨比例调骨骼或用网格修衣袖时需 Professional，且更复杂不等于能自动修好错误的遮挡。[免费试用版](https://esotericsoftware.com/spine-download)可检查编辑体验和附带样本，但不能保存项目或导出自己的 Guard，不能用它完成生产试验。购买和集成前的低成本顺序：先用现有 Godot `Skeleton2D`＋补画的右臂／盾短样本证实原画能变形；若拟做第二名同构人物，再用 Spine 试用版及其官方样本评估编辑器和运行时；只有确认多角色共用收益与目标平台后，才决定购买与采用原生 runtime，或只将 Spine 作为烘焙工具。这是基于项目规模与已知失败作出的建议，不是已完成的 Spine 样片。

### 暂不优先的外部运行时

[Rive 官方文档](https://rive.app/docs/auth)列出的游戏运行时为 Unity、Unreal、Defold，未列 Godot；[Live2D 官方平台表](https://docs.live2d.com/en/cubism-sdk-manual/platform/)列出 Native、Web、Unity 等，未列 Godot。这不足以断言社区没有插件，但意味着当前项目须自行承担桥接或烘焙维护。两者也没有消除 Guard 全身战斗姿势与遮挡原画的制作工作，因此目前不列为优先对比样片。

## 建议的对比与决策

1. 先冻结一张供**比较使用**的 Guard 战斗静帧、相同的剑盾外形、画布和脚底。这是实验输入，不改变 002 的批准范围。每法至少制作 `idle`、`move`、`melee`、`cast`、`hurt`，并保留失败输出与生成参数；若无法完成整组，明确标为局部能力，不以单条炫目视频与完整游戏动作组对比。
2. A 采用刚性分层、显式前后遮挡和攻击极端姿势替换；B/E 采用同一角色画片逐帧；C 先试首尾帧与参考图两种互斥模式各一个 `melee`，看身份与盾遮挡，再决定是否投入整组。D 先核实可用许可证与目标 Godot 版本的官方扩展，若缺则只做导出帧路线，不把不能运行的 Spine 工程算作完成。
3. 统一检查：发型和脸是否仍是 Guard；盾牌在手前／后是否正确；前臂、衣袖、腿部交叠处是否有翻折、断边或额外肢体；武器抓握与长度是否连续；脚底、主体宽高及朝向是否跳变；动作能否对齐模拟出手时刻，暂停、慢速、切换动作、受击插入、死亡末帧是否正确。以 Godot 预览 GIF／截图及逐帧放大图评分，并记录每项制作时间、人工修帧数、收费调用数和运行包大小。
4. 默认选择 A＋必要 B 的混合路线作为生产候选，原因是它复用项目已验证的控制器且可在引擎内精确调时；人物遮挡失败是当前最高风险，样本必须先证明这一点。若 A 仍出现拓扑问题，优先增加替代姿势和手绘帧；H3 结果可作动作参考或少量修帧素材，达到同一技术与美术闸门后才能提升正式资产。上述排序是结合官方能力和项目既有证据的**推论**，不是本轮动画实测结论。

## 2026-09-27：基于 004 样片和用户评审的推荐更新

负责人看过 Godot 中的四组真实预览后，明确认为 **H3 视频抽帧的动作效果明显更好**。这一观察优先于上节基于制作工具可控性的默认排序；但它尚未批准 004 作为正式资产。004 在挥剑峰值有剑尖出画、剑盾轮廓变化，现有首帧约 5～6 头身，也未达到现行正式 4 头身要求，详见[任务实测](../art/tasks/guard-animation-study.md)。

新的**单角色生产试验首选**是：锁定 Guard 首帧 → 每动作单独用 H3 图生视频 → 全段检查身份、右剑左盾和构图 → 选择可用时刻并按战斗出手点重定时 → 修坏帧／重绘道具 → Godot 实际尺寸预览。先只生成一条近战，以相同首帧和时长对比[优化试验词](../art/prompts/guard-h3-melee-frame-test.md)与原词；重点看出手时剑柄到剑尖是否完整、盾是否变窄或与剑合并。004 固定每 0.5 秒采样九帧仅是比较基线，正式择帧应查看源片全帧和出手区间，不能机械沿用。文字约束无法保证武器正确，失败时应先扩大首帧安全边距或调整挥剑路径，再评估逐帧修复成本。

[Character Action Design 调研](guard-character-action-design.md)显示该 Skill 适合规划武器持手锁、五个关键姿势和动作衔接，不负责视频生成、抽帧或视觉验收。用户提供的[微信文章](https://mp.weixin.qq.com/s/vn0qUmBqrkmbONcS7HncKA?click_id=2047251715)提示词摘录提供了固定朝向、纯绿幕、完整入框和单动作的写法；原页和参考视频未能独立读取。因此推荐将两者作为**提示词与质检方法**，不替代已产生较好观感的 H3 动态来源。

目前不优先投入全身 Spine／Godot 骨骼生产：它们仍适合低幅度待机、可复用的同构角色和最终帧修补，但 003 尚未解决 Guard 的袖口、前臂、腿与盾的隐藏面。若新 H3 样片的剑盾连续性、可用帧数量与 128×128 战斗读性都通过，再把视频抽帧提升为这一角色的正式资产候选；若修帧量过高，转向骨骼轻动作＋人工攻击关键帧。不同角色是否复用 Spine，仍以角色数量和分层原画成本单独决定。

2026-09-27 补充比例判断：Guard 当前 5～6 头身的观感得到负责人肯定，因此**后续 H3 抽帧试验暂不把 4 头身作为硬门槛**。更细长的体型可能利于展示挥剑和自然步态；在 128×128 显示下，头脸、学生证和持剑手也可能更小，这是需要实际同屏检验的风险。此为 Guard 试验范围内的临时选择，正式角色是否采用 6 头身、其他角色是否跟随及现行[角色规范](../art/specs/CHARACTER_SPEC.md)是否修改，均待游戏内比较后决定。

2026-09-27 实测补充：负责人提供的 **即梦／Dreamina** 近战片已作为 005 接入独立 Godot 候选预览，不能将其记为 H3 结果。按源片真实时间戳择取 12 帧并使用横向安全画布后，004 旧版出手帧剑尖出画的问题在 005 中得到明显改善；游戏出手帧右剑完整，盾牌仍被身体遮挡较多。当前推荐从“固定使用 H3”调整为**先比较视频生成模型的逐动作有效帧率与修帧成本，再决定供应模型**；已验证的生产核心是固定角色首帧、单动作生成、逐时间戳选帧、等比画布和实际战斗时序预览。005 只有近战，不能推断即梦已具备整组动作的稳定性。样片与验证见[任务档案](../art/tasks/guard-animation-study.md#005--即梦近战视频抽帧试验2026-09-27)。

## 免费 3D 动作资源核验（2026-10-07）

本轮只核对原作者网站、商店和官方许可说明，未下载、导入、重定向或制作对比动画；以下是候选清单，不代表资产批准或接入验证。资源的“可免费用于商业游戏”“CC0”“免费提供 Blender 源文件”是不同条件，不能相互替代。针对本次 3～4 头身守护者需求，优先寻找已有完整人形骨骼及近战、格挡、移动动作的组合。

### 优先试验：KayKit 模型与动作库

| 资源 | 已核实免费范围 | 格式与许可 | 对守护者的意义及边界 |
| --- | --- | --- | --- |
| [KayKit Character Animations](https://kaylousberg.itch.io/kaykit-character-animations) | 当前 Features 列 161 项人形动画；Free 1.1 为 14 MB。全部动画免费，类别含待机、受击、死亡、走跑跳、单手／双手／双持攻击、格挡、弓枪和施法。 | FBX／GLTF；CC0，可商用且无署名要求。带控制 rig 的 `.blend` 源文件为 US$14.99 付费档，不属于免费交付。 | 最直接的动作候选。作者说明 Large rig 动作少于 Medium；重定向至非 KayKit 角色仍需调整，效果可能不理想。不能把动作库总数当成每个体型的动作数。 |
| [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | 当前 Free 2.0 为 12 MB，含 5 个带骨骼人物、25+ 武器／盾等道具和基础移动动作，可配合上述免费动作库。 | FBX／GLTF；CC0。Extra 的 3 个角色需 US$7.95，`.blend` Source 需 US$11.95。 | 可先用原包人物和剑盾观察现成动作，减少首次试验的绑定变量。旧 GitHub 1.0 的 4 角色／75 动作说明不应用来描述当前 2.0。 |

项目推论：先在 KayKit 原骨架上展示待机、移动、单手攻击与格挡，再评估把动作转给守护者，比立刻改造现有试样更容易分辨“动作本身”“绑定”“角色比例”的问题。现成低多边形人物只作为动作验证载体，尚无证据证明它们已经符合校园守护者身份或精确达到本项目的 3～4 头身比例。短手臂、大头、剑盾握持仍要调整，不能只缩放骨架后直接认定合格。

### Quaternius：动作候补，免费范围和许可须分开核对

| 资源 | 已核实范围与费用边界 | 文件与动作证据 | 尚未确认 |
| --- | --- | --- | --- |
| [Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | 整个产品宣传 120+ 动作；免费 Standard 15 MB，Pro US$9.99，Source US$14.99。**120+ 不是已确认的免费动作数。** | [作者官网](https://quaternius.com/packs/universalanimationlibrary.html)列 FBX／GLB／Blend；`.blend` 属 Source。产品说明有八方向移动、战斗、持枪、死亡，以及 Root Motion 开／关两种导出。 | 网页正文未给出可核验的当前 Standard 精确动作数及完整逐项名单；不能断言全部近战、盾牌动作或八方向组合都免费。官网版本区的 60～70% 描述不可换算成精确动画数。 |
| [Universal Animation Library 2](https://quaternius.itch.io/universal-animation-library-2) | 整个产品宣传 130+ 动作；免费 Standard 17 MB，Source US$14.99。**130+ 不是已确认的免费动作数。** | [作者官网](https://quaternius.com/packs/universalanimationlibrary2.html)列 FBX／GLB／Blend；`.blend` 属 Source。产品说明含徒手／持械连击、独立攻击及收招、跑酷等；2026-09-28 更新修复 Sword_Light 与收招末帧衔接。 | 当前免费版具体数量、近战连击与盾动作的免费归属未确认。将它作为近战动作候补，不宣称免费档已有完整守护者动作组。 |
| [Ultimate Animated Character Pack](https://quaternius.com/packs/ultimatedanimatedcharacter.html) | 官网列 52 个模型，正文称 50+ 动画人物，免费个人／商业使用；该老包页面没有 Standard／Pro／Source 下载分档说明。 | FBX／OBJ／Blend；作者 [2019 年发布说明](https://www.patreon.com/quaternius/posts/ultimate-pack-31403272?l=en-GB)也写免费并提供 Blend。OBJ 是网格格式，不能据此推断携带骨骼动画。 | 当前网页未列精确动作总数或逐角色的剑盾动作清单；没有验证旧骨架与 Universal Animation Library 新骨架的兼容性。 |

**许可声明存在差异，暂不把 Quaternius 无条件归为严格 CC0 清单。** 上述包页仍标 CC0，Universal Animation Library 的 itch 元数据也标 CC0；但作者当前[总许可证页](https://quaternius.com/license.html)是 2026-08-28 更新的 Quaternius Asset License（QAL v1.0），允许免费修改并用于商业游戏、视频和渲染作品，无须署名，同时禁止将原版或改版素材作为独立素材再分发。其条款还说明后续许可变化不追溯已经取得的旧版素材。两处声明不能由本轮网页浏览消除：实际采用前应核对所下载版本附带许可证并保存来源，必要时向作者确认；不能凭旧宣传图将新下载包认定为 CC0，也不能将 QAL 与开源许可混同。

### 其他候补及不列入严格开放清单的资源

- Kenney [Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists) 和 [Animated Characters Survivors](https://kenney.nl/assets/animated-characters-survivors)：两页均有免费入口和 CC0 标识，可作为带动画人物候补。页面的 `Files 8` 是文件数量，不能解释为 8 项动作；本轮未确认剑盾覆盖和具体动画格式。
- [Mixamo 官方 FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)：Adobe ID 可免费使用，不要求订阅，允许在游戏等商业项目中使用；它不是 CC0 开源资源，不能和上述 CC0 候选混写。官方还说明中国 country code 的用户不可使用 Mixamo，因此只列为补充信息。

本轮建议排序：**KayKit 免费人物＋免费动作库先做动作质量对照；Quaternius 待版本许可与免费动作名单核清后作为补充；Kenney 作为基础人形候补。** 本次尚未进行任何效果实测，不根据资源数量推断动作一定自然。若进入下一次试验，先限制为一条单手近战加一条移动，与当前 008 使用相同站立高度、时长和出手点比较，观察重心、腰胯发力、脚滑及剑盾穿插，再决定扩展范围。
