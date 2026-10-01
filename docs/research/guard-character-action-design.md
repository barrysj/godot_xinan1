# Guard 动画：Character Action Design 与文章提示词核查

核查日期：2026-09-27。范围仅为外部方法和提示词证据，不代表已安装、运行或批准新资产。项目现有 H3/Godot 样片和抽帧效果见 [Guard 动画方法对照](../art/tasks/guard-animation-study.md)。

## 证据边界

- GitHub 仓库的 [README](https://github.com/guiguiyan930-source/Character_Action_Design)、[SKILL.md](https://github.com/guiguiyan930-source/Character_Action_Design/blob/main/SKILL.md)、[动作卡规范](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/references/action-card-schema-v2.md)、[反模式](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/references/anti-patterns.md)、[输入校验脚本](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/scripts/validate_input.py) 可直接读取；下文关于仓库的事实仅据这些原文件。
- 用户给出的 [微信文章](https://mp.weixin.qq.com/s/vn0qUmBqrkmbONcS7HncKA?click_id=2047251715) 原页与去除追踪参数的同一页面，在本次网络环境中均无法读取；站点精确 ID 搜索没有全文结果，浏览器访问超时。**因此，文章末尾提示词是否与用户贴出的文字逐字一致、参考视频实际效果、作者和发布时间，均未独立核实。** 本文只将对话中用户提供的图像、死亡、待机、移动提示词作为“用户提供的文章摘录”，不声称已从网页直接摘录。没有拿到的攻击、施法等提示词也不补写为文章原文。

## 仓库实际提供什么

[README](https://github.com/guiguiyan930-source/Character_Action_Design) 和 [SKILL.md 的定位与流程](https://github.com/guiguiyan930-source/Character_Action_Design/blob/main/SKILL.md) 显示，这是**角色设定到动作卡的设计中间层**：输入锁定的三视图、身份、性格、体型、武器、游戏类型和不对称特征；按游戏类型选动作包和预算；为每个动作写关键姿势、AI 出图 prompt 与动作衔接；把产物交给另一个 8 方向/16 帧生成环节。仓库列出的 `game-character-8dir-frame-animation` 是下游依赖名称，并非当前仓库已经提供的一键生成器。仓库自身没有展示视频生成、绿幕抠像、自动抽帧或 Godot 导入的可执行流水线。

值得吸收的设计约束：

1. [动作卡规范](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/references/action-card-schema-v2.md)要求身份锚、左右不对称锁、武器数量及持手锁、配色锁写入每条 prompt。Guard 的剑、盾应分别描述数量、角色自身左右手、握点、外形和在动作全过程的位置关系；“武器完整入框”与“不可遮掉剑尖”属于需要为 H3 视频额外补充的镜头/裁切约束，原四锁并未保证这些。
2. [SKILL.md 动作卡](https://github.com/guiguiyan930-source/Character_Action_Design/blob/main/SKILL.md)给五个关键姿势和帧号映射，例如起势、蓄力、命中、收势、回位；战斗动作另有命中帧、是否可打断和可衔接状态。这些是设计节奏与 Godot 动作事件的有用输入，但其默认 12 fps、16 帧是示例/下游约定，不能直接套到 H3 视频时长和抽帧间隔。
3. [反模式清单](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/references/anti-patterns.md)明确指出“手持武器攻击”一类模糊写法会让武器数量或持手漂移；省略身份锚、不对称特征以及足够的关键姿势也易让帧间不连贯。其正确写法强调数量、持手和贯穿全程的一致性。
4. [输入校验脚本](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/scripts/validate_input.py)使用 Python 和 PyYAML，主要校验 YAML 必填字段、游戏类型/视角枚举、方向、正整数帧数/帧率和不对称声明；**不会**检验参考图像实际存在、武器或盾牌是否完整出画、视频时序、Godot 播放效果。它的通过结果不能替代逐帧目视 QA。

## 仓库边界和可用性

- 仓库提供的“重剑女骑士”等属于文字示例；在已读文件中没有可独立重现的模型视频对照、Guard 样本或抽帧验收记录。[仓库文件概览](https://github.com/guiguiyan930-source/Character_Action_Design)
- 这是可参考的方法，不是已证明可解决 H3 剑尖出画/盾面变形的算法。四锁和五关键姿势能减少提示词歧义，但视频模型是否遵守，仍需同一 Guard 参考图的 A/B 生成与逐帧检查。
- 仓库根目录可见文件列表中未见 `LICENSE`；本次没有查到明确的再分发许可，故不将其源码或完整技能文件复制到本仓库。仅转化设计思想并引用原始 URL。[仓库文件概览](https://github.com/guiguiyan930-source/Character_Action_Design)
- 原文存在少量内部不一致：README 说不对称特征为必填，[SKILL.md 输入表](https://github.com/guiguiyan930-source/Character_Action_Design/blob/main/SKILL.md)称“有则必填”，而[校验脚本](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/scripts/validate_input.py)始终要求 `character.asymmetry` 键（无特征写 `none`）；[反模式文档](https://raw.githubusercontent.com/guiguiyan930-source/Character_Action_Design/main/references/anti-patterns.md)实际列到第 9 条，README 概览写 8 条。采用前以具体 schema 和脚本行为为准。

## 用户提供的文章提示词摘录：可提炼但未核实原页

用户在本对话中贴出的图像、死亡、待机、移动提示词反复使用以下可操作模式：固定约三分之二到四分之三、朝右的角色视角；固定机位；全身和道具（例中的法杖）全程完整入框；纯色绿幕以便抠像；每段只做一个动作；道具外形及相对手部关系稳定；结尾回到稳定姿态或静止；用负面约束排除镜头运动、裁切、额外人物和道具变化。**这些仅可归于用户提供的摘录，无法据此判断原文用词、视频生成参数或参考视频效果。** [文章原链接](https://mp.weixin.qq.com/s/vn0qUmBqrkmbONcS7HncKA?click_id=2047251715)

将这种提示词结构迁移到 Guard 时，要从“法杖”改成明确的**一把剑、一面盾**：指定角色自身哪只手分别持有；剑柄、剑身、剑尖和盾面、盾缘各段在最宽挥击时仍处于画面安全区；固定俯视/侧视角与角色朝向；剑盾不交换、不复制、不融化变形；不靠近镜头且不改变镜头焦距。以带安全边距的首帧/参考图约束构图，并检查出手最快的区间，而不是只看首尾帧。以上是本项目的**推导和建议**，并非文章原 prompt。

## 对 Guard 的方法结论

优先试验“锁定的 Guard 参考图 → 单动作图生视频 → 逐帧/关键时间检查剑盾 → 抽帧和统一画布 → Godot 战斗预览”，把本仓库的动作卡用作**提示词规划器和验收表**。先做近战一条 A/B：固定同一首帧、模型/时长/画布/抽帧方法，只改动作卡、构图安全区和武器锁。若剑尖与盾缘在全段都保持可见、身份和手持关系稳定，才推广到待机、移动、受击、施法。该流程的实测结论仍以生成样片为准；文字约束本身不等于通过验收。项目既有 H3 资源与 Godot 预览事实见[ART-03](../implementation/art-03.md)。
