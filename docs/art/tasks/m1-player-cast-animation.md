# 美术任务：M1 我方角色动画

状态：2026-10-01，负责人批准除应援者旧007／008种子外的现存人物概念和动画正式登记。Guard仅保留008；其他四名角色及远射手替换外观保留001。五名默认角色已接入，替换外观已入库但未替换默认远射手。游戏接入效果待人工评审。

## 正式登记与接入（2026-10-01）

人工依据：“除了注释1的应援者动画，其他的概念、动画都登记为正式资源”，并明确要求按角色归档、删除旧Guard及远射手占位、使用新资源。这同时确认本阶段留存范围。排除项仅指旧应援者动画原图与头部拆件 healer/asset_007、healer/asset_008；新应援者混合动画 healer/asset_001 在本次范围内。

| 对象 | 设计资料与动画源包 | 正式运行包 | 游戏状态 |
| --- | --- | --- | --- |
| guard | characters/guard/concept_002、asset_008 | assets/art/characters/guard/ | 已替换旧图集、动画入口及头像 |
| archer | characters/archer/concept_006、asset_001 | assets/art/characters/archer/ | 已替换旧图集、动画入口及头像 |
| striker | characters/striker/concept_006、asset_001 | assets/art/characters/striker/ | 已绑定动画与新头像 |
| inventor | characters/inventor/concept_006、asset_001 | assets/art/characters/inventor/ | 已绑定动画与新头像 |
| healer | characters/healer/concept_006、asset_001 | assets/art/characters/healer/ | 已绑定动画与新头像；007／008只留原型资料 |
| archer_alt | characters/archer-alt/asset_001 | assets/art/characters/archer_alt/ | 已批准备选外观，未绑定默认单位 |

表内 characters/ 均位于 design/concepts/ 下。概念仍是 stage: concept + approved 的正式设计参考，不将带标注的概念板当作战斗图集。每角色一个对象 Manifest；旧 m1_player_cast、guard_animation_study、player_cast_hybrid_animation 聚合对象已撤销，主表改索引六个人物／外观对象。独立 YAML 本身符合工作流，本轮调整的是所有权归属。

正式包由 tools/art/promotion/promote_animation.py 提升：Guard65文件，其余每包13文件。源图、视频、生成记录、动作卡和GIF留在角色源包；运行包不依赖 design/。各混合包携带同一动画库的确定性副本，远射手两外观库及规范化场景／动作一致，保持可独立交付。头像使用新待机帧的Atlas裁切，不另生成身份图。

验证基线：0a3f939 加本次工作树；Godot4.7.2。六包确定性提升检查、六版动作预览检查（每版七动作，含暂停／单步／慢速）、行动模拟、帧动画与表现专项通过。authored_assets_check.tscn 验证五名实际角色正式路径、头像、帧尺寸、濒危／退场与待机像素不同及低血量／死亡状态选择；5角色、0失败。图形模式 -- --capture 用两组合法四人阵容覆盖全部五角色，在1920×1080、2560×1440、1920×1200捕获六张真实战斗截图，0失败。

证据位于[正式接入截图](../../../design/concepts/characters/review/codex-workflow/release/)、[迁移审计](../../../design/concepts/characters/review/codex-workflow/release/migration-audit.json)。资源台扫描52对象、1105文件、0缺失、0不一致、0错误；PNG原图与批准前内容哈希保持一致。目录迁移撤去 design/.gdignore 内无用的旧 .import 描述，正式帧使用常规Godot导入。

边界：008继承的绿幕细边、武器形变，以及刚性骨骼移动缺腿步仍保留；应援者头身比与其他四人不同。本轮批准既有画稿，没有重绘或改变动作节奏。实际战斗存在纵向相邻人物与上排名牌局部交叠，留待接入效果评审，不宣称布局已最终验收。运行日志的既有根证书／旧像素源图警告不影响本轮加载；编辑器无法写AppData设置的环境告警未改。待统筹：默认五名角色的运行资产、头像和目录所有权已变化。

## 当前预览

默认角色直接使用正式包，无需临时覆盖：
pwsh.exe -File ./run-motion-preview.ps1 -Unit res://resources/content/characters/guard.tres -Action Melee -Speed 0.5
远射手替换外观仍显式指定 -Animation res://assets/art/characters/archer_alt/battle_animation.tres。
网页资源台从六个人物 Manifest 展示同角色的概念、动作及GIF。

## 历史试制记录

## 方法与约束

- 先做低成本占位：根骨骼＋头骨骼承担待机、移动、受击；濒危、幅度大的攻击、技能和退场用完整关键姿势帧。避免旧人体网格试验已发现的衣袖、前臂和裤腿翻折；根骨骼移动不是完整腿部步态。
- 根据已安装的 [`Character_Action_Design` Skill v2](https://github.com/guiguiyan930-source/Character_Action_Design)，为每个角色记录身份、不可交换的左右特征、武器数量／持手及色板，并在动作卡标明关键姿势和出手帧。已批准的概念是身份和武器方向参考，尚无完整三视图，本轮仅验证右向片段，不宣称八方向可用。
- 运行预览通过 `-Animation` 临时覆盖，`resources/content/characters/*.tres` 不引用候选。批准与提升仍按 [WORKFLOW](../WORKFLOW.md) 分阶段进行。

## 进度

| 角色 | 状态 | 素材与实现 | 已知边界 |
| --- | --- | --- | --- |
| 守护者 | 已有混合样本 003；视频抽帧 008 保留 | 头／盾骨骼＋序列帧；008 为独立近战修色候选 | 003 不含四肢骨骼，008 仍待人工评审 |
| 远射手 | 001 已技术验证，待人工评审 | 按已批准 006 概念生成透明待机与举枪姿势；共享根／头骨骼动画库，远程／施法关键帧 | 腿部移动只是占位上下运动；静态首尾姿势衔接未精修 |
| 应援者 | 001 已技术验证，待人工评审 | 已批准 007 静态合成种子；共用根／头骨骼库，键盘绿光关键帧 | 手指无独立打字动作 |
| 冲刺手 | 001 已技术验证，待人工评审 | 透明待机母图与双刀前斩姿势；共用根／头骨骼库，近战／施法关键帧 | 移动非腿部步态，出手首尾未精修 |
| 发明家 | 001 已技术验证，待人工评审 | 透明待机母图；共用根／头骨骼库，枪口青光关键帧 | 举枪和后坐力尚未细化 |
| 远射手换貌验证 | 001 已技术验证，待人工评审 | 银蓝短发、圆眼镜、橙白短袖；与原远射手共用完全相同骨骼场景结构、动作资源时序和动画库 | 仅证明当前根／头刚性骨骼可复用，不证明未来四肢蒙皮可直接复用 |

### 远射手 001

- 源图、关键姿势、帧、分层和 Godot 资源见 [`archer/001`](../../../design/concepts/characters/archer/asset_001/)；共享动画库为 [`shared/animations.tres`](../../../tools/art/animation/player_cast/animations.tres)。[动作卡](../../../design/concepts/characters/archer/asset_001/action-card.yaml)锁定右手单枪、马尾发夹、服装色板和关键出手帧。
- 用内置 imagegen 依 006 概念生成单张透明右向待机，再参考该图生成举枪关键姿势；完整提示词与来源见同版本的 `generation.md`。脚本 [`build_placeholder_hybrid.py`](../../../tools/art/animation/player_cast/build_placeholder_hybrid.py)确定性归一画布、脚底、裁出头部、制作枪口短光及淡出退场帧。
- 2026-09-29 技术验证基线：`art/player-cast-hybrid-animation`，Godot 4.7.2。`pwsh.exe -File run-motion-preview.ps1 -Unit res://resources/content/characters/archer.tres -Animation res://design/concepts/characters/archer/asset_001/battle_animation.tres -EnsureImport -Check` 及缓存已齐时不带 `-EnsureImport` 的 `-Check` 均通过，七动作通过、近战略过。`-Action Idle`／`-Action Ranged -Capture` 各得 1920×1080、1920×1200、2560×1440 实机截图并人工查看；`-ExportPreviews` 产出七动作 30 FPS、352×352 GIF 与巡演。资源台扫描 `errors=[]`、本对象 `warnings=[]`、全局缺失和不一致均为 0；Python 编译、Git 差异检查通过。
- [待机截图](../../../design/concepts/characters/archer/asset_001/review/godot-idle-1920x1080.png)、[远程截图](../../../design/concepts/characters/archer/asset_001/review/godot-ranged-1920x1080.png)、[七动作巡演](../../../design/concepts/characters/archer/asset_001/review/all-actions.gif) 是实际 Godot 输出。地面青色方块是预览标记，源图与标准化帧中没有它。
- 状态：只用于低成本可运行占位，不把这套小幅刚性骨骼解释为完整四肢蒙皮；不覆盖正式角色配置。独立动作完成后需继续制作其余职业。

### 冲刺手 001

- [动作卡](../../../design/concepts/characters/striker/asset_001/action-card.yaml)锁定双刀数量、左右持手、发夹和服装色板。按已批准 006 概念生成透明待机母图，再用 imagegen 编辑右向双刀前斩姿势；提示词和来源见同版本的 `generation.md`。整帧关键姿势保住手与两把刀，待机／移动／受击／濒危共用 Archer 的同一根／头骨骼动画库。
- 2026-09-29 验证基线：`art/player-cast-hybrid-animation`。Godot 4.7.2 `run-motion-preview.ps1 -Unit res://resources/content/characters/striker.tres -Animation res://design/concepts/characters/striker/asset_001/battle_animation.tres -EnsureImport -Check` 通过；`-Action Melee -Capture` 得三分辨率截图并人工查看 1920×1080；`-Action Melee -ExportPreviews` 得 30 FPS、352×352 实际时序 GIF。Manifest 扫描 `errors=[]`、本对象 `warnings=[]`、缺失与不一致为 0。首次预览发现刀尖光弧与刀身分离，已改锚点后重建、重新导入、截图复核。
- [近战实机截图](../../../design/concepts/characters/striker/asset_001/review/godot-melee-1920x1080.png)、[近战 GIF](../../../design/concepts/characters/striker/asset_001/review/melee-preview.gif)。状态为评审候选，不覆盖正式角色。

### 发明家 001／应援者 001

- 发明家按已批准 006 服装概念用 imagegen 生成透明持枪母图，双手与同一支完整大枪稳定可见；现阶段用同一姿势加短枪口光表达出手。[动作卡](../../../design/concepts/characters/inventor/asset_001/action-card.yaml)、[远程实机截图](../../../design/concepts/characters/inventor/asset_001/review/godot-ranged-1920x1080.png)、[远程 GIF](../../../design/concepts/characters/inventor/asset_001/review/ranged-preview.gif)。枪口光首次位置偏离，已移回枪口后复建。
- 应援者复制已批准 007 透明合成图，保留两块全息键盘与人物外观；同一静态姿势加键盘处绿光脉冲表达技能。[动作卡](../../../design/concepts/characters/healer/asset_001/action-card.yaml)、[施法实机截图](../../../design/concepts/characters/healer/asset_001/review/godot-cast-1920x1080.png)、[施法 GIF](../../../design/concepts/characters/healer/asset_001/review/cast-preview.gif)。静态素材的批准不等于动画获批。
- 2026-09-29～30 技术验证基线：`art/player-cast-hybrid-animation`，Godot 4.7.2。对 `resources/content/characters/inventor.tres` 和 `healer.tres` 分别用对应 `battle_animation.tres` 运行 `run-motion-preview.ps1 -EnsureImport -Check`，均通过；`-Action Ranged`／`-Action Cast -Capture` 各得三分辨率截图并人工查看 1920×1080；各动作 `-ExportPreviews` 得 30 FPS、352×352 Godot 实际时序 GIF。Manifest 扫描 `errors=[]`、本对象 `warnings=[]`、缺失与不一致均为 0；Python 编译、Git 差异检查通过。两套均引用同一个 `shared/animations.tres`。新动画仍待人工评审，不替换正式角色。

### 远射手换外貌复用验证 001

- 银蓝短发、圆框眼镜和橙白上衣的透明待机母图与举枪关键姿势由内置 imagegen 生成；原远射手举枪图只提供姿势参考，身份以新母图为准。新形象持同一支完整青白手枪，动作卡见 [`archer-alt/001`](../../../design/concepts/characters/archer-alt/asset_001/)；新图尚待人工视觉评审。
- 2026-09-30 验证基线：`art/player-cast-hybrid-animation`。`verify_archer_reuse.py` 检查两套 `presentation.tscn` 和 `battle_animation.tres` 去掉角色资源路径后逐字相同，并都直接引用同一个 `shared/animations.tres`；512×512 待机图重叠可见像素中，RGB 单通道差值大于 30 的比例为 0.391，确认并非只替换文件名。Godot 4.7.2 对换貌候选 `-EnsureImport -Check` 和缓存齐备后普通 `-Check` 均通过；`-Action Idle`／`-Action Ranged -Capture` 各得三分辨率截图并人工查看 1920×1080；待机、远程各用 `-ExportPreviews` 得 30 FPS、352×352 GIF。Manifest 扫描 `errors=[]`、本对象 `warnings=[]`、缺失／不一致为 0；Python 编译和 Git 差异检查通过。
- 对照：[原远射手待机](../../../design/concepts/characters/archer/asset_001/review/godot-idle-1920x1080.png)、[换貌待机](../../../design/concepts/characters/archer-alt/asset_001/review/godot-idle-1920x1080.png)；[原远程](../../../design/concepts/characters/archer/asset_001/review/godot-ranged-1920x1080.png)、[换貌远程](../../../design/concepts/characters/archer-alt/asset_001/review/godot-ranged-1920x1080.png)。证明的范围是当前根／头两根刚性骨骼和整帧攻击的复用；服装、头发的高自由度变形及全身骨骼尚未验证。

### 网页动作预览（2026-09-30）

五个候选均已用 Godot `run-motion-preview.ps1 -EnsureImport -ExportPreviews` 导出七个动作 GIF 和 `review/all-actions.gif`。Manifest 登记逐动作预览，帧元数据同步 `clips` 索引后，美术资源浏览器可直接选择动作观看。启动 `pwsh.exe -NoProfile -File ./tools/art/asset_manager/run-server.ps1`，打开 `http://127.0.0.1:8765/`，依次选择“人物”→“M1 我方角色骨骼与关键帧占位动画”→版本→“动画”→动作。五个版本同为 001，以路径末段 `archer`、`striker`、`inventor`、`healer`、`archer-alt` 区分；分别对应远射手、冲刺手、发明家、应援者和远射手换貌。网页校验显示五版各七动作，GIF 图片均可加载，缺失／不一致为 0。它们仍是待评审候选，不因完成预览而提升为正式资产。

### 濒危／退场关键姿势修订（2026-09-30）

负责人明确要求两态至少有与待机不同的静态帧。旧版濒危仍显示待机图，退场仅给待机图降饱和并淡出，未满足此要求。以各角色原待机图为编辑参考，内置 imagegen 生成[双姿势源图及提示词](../prompts/m1-player-cast-defeat-poses.md)：濒危弯腰或踉跄，退场侧卧倒地；枪、双刀、巨枪与两套全息键盘均保留。每版 `source/critical-death-sheet.png` 是原始输出，脚本确定性裁切成 `frames/death_1.png`（濒危）和 `frames/death_2.png`（倒地）；退场直接显示倒地帧，再由已有战斗表现层淡出。共享骨骼库不再覆盖濒危，五版的动作资源与网页 GIF 已重建。

[五位角色三态并排](../../../design/concepts/characters/review/critical-death-comparison.png)用于核对静态轮廓；[Godot GIF 抽样](../../../design/concepts/characters/review/critical-death-godot-gifs.png)、[远射手濒危实际截图](../../../design/concepts/characters/archer/asset_001/review/godot-critical-1920x1080.png)与[退场实际截图](../../../design/concepts/characters/archer/asset_001/review/godot-death-1920x1080.png)验证运行效果。五版 `-EnsureImport -Check` 均通过、七动作 GIF 与巡演重新导出；源帧对待机的可见 Alpha 轮廓交并比，濒危为 0.335～0.434、退场为 0.115～0.194。动作仍是静态关键姿势之间的切换，没有补中间过渡；候选继续待负责人评审。


## 适配 main 分类索引并合并（2026-10-01）

整合基线：main 1e94537、人物分支967ec0d；合并分支art/characters-main-integration。保留main新增的enemy分类，根assets/art/asset_manifest.yaml通过manifests/characters.yaml加载六个manifests/characters/<角色>.yaml。人物源包位于design/concepts/characters/<角色>/，运行包位于assets/art/characters/<角色>/。撤去本次新增的98个.import描述并忽略后续生成的.import／.uid，不改无关历史导入配置。

动画提升与GIF任务准备复用资源台递归索引解析，补充二级清单回归检查；人物的播放元数据精简改为源包显式选择，保留粉笔精灵既有完整帧元数据契约。验证：39项资源台／制作工具测试通过；六个人物包及粉笔精灵确定性提升检查通过；资源台52对象、1105文件、0缺失、0不一致、0错误。正式角色Godot检查5角色／0失败；保留既有接入视觉评审状态。本轮仅目录、索引与工具兼容调整，沿用前次三分辨率截图。待统筹：人物采用与main敌人相同的分类子索引，制作工具支持递归查找。

本地main合并核验：接收基线902342c，合并来源art/characters-main-integration的a673acf，使用squash。保留main敌人分类及后续战斗设计文档。main实际资源台52对象／1105文件、0缺失／不一致；首次导入后Guard七动作预览0失败，正式角色检查5角色／0失败。新增提交无.import／.uid／缓存，未推送远程。游戏接入效果仍沿用待人工评审状态。
