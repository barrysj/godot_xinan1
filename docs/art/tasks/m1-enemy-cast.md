# 美术任务：M1 敌人家族

## 合并交付范围（2026-09-30）

- 负责人确认：“只保留这些批准的概念的最新版本”。本次交付限 16 个已批准对象，每个对象一张最终概念图及对应 `generation.md`；均为概念阶段，`integration: not_integrated`。
- 已淘汰、未筛选和各对象较早的候选图不进入本次合并。下面各历史段落保留当时的文字结论；其旧图链接已取消。需要追溯原图、提示词和原编号时，从原美术分支 `art/m1-enemy-cast` 的提交 `fd548a3` 恢复。
- 旧版目录原为纯数字，本次留存目录按新流程命名为 `concept_###`；保留原编号，不重排、不复用历史已分配编号。此阶段没有 `tmp_###` 候选。
- 阶段收尾依赖：每版 PNG 与同目录生成提示词；主 Manifest、16 份对象清单及本任务记录。没有游戏运行时引用，正式资产、动画与接入效果另行制作和评审。

| 已批准概念 | 留存版本 | 概念图 |
| --- | --- | --- |
| 机械弹跳篮球 | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/basketball-bouncer/concept_002/basketball_bouncer_action_concept_002.png) |
| 羽片发射器 | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/shuttlecock-diver/concept_002/shuttlecock_diver_action_concept_002.png) |
| 餐具协同怪 | concept_003 | [查看图](../../../design/concepts/m1-enemy-cast/meal-tray-guard/concept_003/meal_tray_guard_action_concept_003.png) |
| 《计算机组成原理》 | concept_001 | [查看图](../../../design/concepts/m1-enemy-cast/textbook-architecture/concept_001/textbook_architecture_action_concept_001.png) |
| 《线性代数》 | concept_001 | [查看图](../../../design/concepts/m1-enemy-cast/textbook-linear-algebra/concept_001/textbook_linear_algebra_action_concept_001.png) |
| 《信息安全数学》 | concept_001 | [查看图](../../../design/concepts/m1-enemy-cast/textbook-security-math/concept_001/textbook_security_math_action_concept_001.png) |
| 《编译原理》 | concept_001 | [查看图](../../../design/concepts/m1-enemy-cast/textbook-compilers/concept_001/textbook_compilers_action_concept_001.png) |
| 图书管理员（Boss） | concept_003 | [查看图](../../../design/concepts/m1-enemy-cast/cyber-librarian/concept_003/cyber_librarian_action_concept_003.png) |
| 馆藏巨典 | concept_004 | [查看图](../../../design/concepts/m1-enemy-cast/great-volume-boss/concept_004/great_volume_boss_action_concept_004.png) |
| 键帽拳灵 | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/keycap-brawler/concept_002/keycap_brawler_action_concept_002.png) |
| 投影独眼灵 | concept_003 | [查看图](../../../design/concepts/m1-enemy-cast/projector/concept_003/projector_action_concept_003.png) |
| 归还印章怪 | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/return-stamp/concept_002/return_stamp_action_concept_002.png) |
| 监考钟灵（Boss） | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/exam-clock-boss/concept_002/exam_clock_boss_action_concept_002.png) |
| 广播中继 | concept_003 | [查看图](../../../design/concepts/m1-enemy-cast/radio/concept_003/radio_action_concept_003.png) |
| 试卷怨灵 | concept_002 | [查看图](../../../design/concepts/m1-enemy-cast/exam-paper/concept_002/exam_paper_action_concept_002.png) |
| 光标术士 | concept_003 | [查看图](../../../design/concepts/m1-enemy-cast/computer-terminal/concept_003/computer_terminal_action_concept_003.png) |

### 历史评审记录

以下内容记录当时的生成与筛选情况；其中“保留”“待评审”等历史措辞不表示当前状态。当前生效版本以本节和对象 Manifest 为准。

## 四本教材概念批准（2026-09-30，最新决定）

- 负责人原话：“4本书的概念也通过”。批准分别绑定 textbook_architecture/concept_001《计算机组成原理》、textbook_linear_algebra/concept_001《线性代数》、textbook_security_math/concept_001《信息安全数学》、textbook_compilers/concept_001《编译原理》，均登记 selected + approved。
- 保留既定技能方向：数字脉冲、矩阵移位、运算封锁环、编译指令弹。真实课程书名与原创游戏封面不变，不指认具体出版社或教材版本。
- 仅概念阶段批准；内页微小文字、二进制串和公式仍须在正式制作时校正或简化，动画与 Godot 接入未制作，四项保持 not_integrated。下方保留历史评审状态。
- 本次仅更新批准记录，验证 AssetCatalog.scan() 与 git diff --check，不重画或启动游戏。

## 餐具协同怪概念批准（2026-09-30，最新决定）

- 负责人对抛食修改稿回复“概念通过”，批准绑定 meal_tray_guard/concept_003，登记 selected + approved。
- 确认餐盘主体及悬浮餐具：筷子远程抛食（米饭、骨头）、汤勺泼汤、叉子突刺；不再采用筷子夹击目标。
- 仅概念阶段通过，正式资产、连续动作与 Godot 接入未制作，保持 not_integrated。旧稿不继承批准；下方保留历史生成时状态。
- 本次仅更新批准记录，验证 AssetCatalog.scan() 与 git diff --check，不改变图片或游戏运行画面。

## 运动概念批准与筷子抛食修订（2026-09-30，当前状态）

- 负责人原话：“筷子的攻击方式是远程扔食物（例如米饭、骨头），其他两个概念通过”。批准绑定 basketball_bouncer/concept_002 与 shuttlecock_diver/concept_002，登记 selected + approved；仅概念阶段通过，仍 not_integrated。
- 餐具协同怪新增 meal_tray_guard/concept_003，筷子取消夹击，改为夹取餐盘食物后远程甩投，图中展示米饭团和骨头沿弧线飞向目标；保留悬浮武器、汤勺泼汤与叉子突刺。
- 003 为 pending / unselected / not_integrated；002 保留历史，不视为通过。抛食格省略停放叉子，尚未提供夹取／甩投连续帧。完整提示词见对应 003/generation.md。
- 验证：PNG 解码与实测 1774×887、AssetCatalog.scan()、git diff --check；未改游戏运行画面，无需运行截图。

## 机械运动与餐具组合重画（2026-09-29，当前候选）

- 用户要求舍弃跳绳：jump_rope_snare/concept_001 登记 rejected，保留历史图。
- 篮球与羽毛球旧稿仅作身份参考；新增 basketball_bouncer/concept_002（机械分瓣、弹簧蓄力与弹撞）、shuttlecock_diver/concept_002（独立金属羽片发射、射后空槽）。
- 餐盘与汤勺合为一个对象，新增 meal_tray_guard/concept_002：餐盘本体与悬浮汤勺、一双筷子、一把叉子，展示泼汤、夹击、叉刺。独立 soup_ladle/concept_001 停用，rejected 仅表示不再作为独立敌人，造型参考保留。精英定位仍只是建议，尚未锁定。
- 三张 002 均为 unselected / pending / not_integrated，不继承任何批准；其他对象状态不变。
- 图片及完整内置 image_gen 提示词保存在对应对象 002 目录的 generation.md。餐具经过两次定向修正，去除连接臂和重复筷子。
- 质检 PASS_WITH_NOTES：篮球蓄力格偏结构展开，正式动作需更明确的压缩行程；羽片回装和固定数量待细化；餐具夹击格省略停放叉子、未展示补汤来源，仅供概念筛选，不用作连续动画帧。
- 三张 PNG 解码尺寸依次为 1536×1024、1774×887、1774×887。验证：PNG 解码、AssetCatalog.scan()、git diff --check。未改运行画面，不启动游戏。

## 新一轮筛选与运动／食堂／教材候选（2026-09-25，当前状态）

- 负责人明确回复“03 05 也通过”：03 试卷怨灵 concept_002、05 光标术士 concept_003 登记 selected + approved。连同此前批准的七项，本任务共九项概念通过；不代表正式资产或接入批准。
- “其他概念都不太行”绑定上一轮未批准的 17 项 concept_001：订书钳兽、圆规刺客及对应 Manifest 对象 stapler_beast、compass_assassin、cable_snare、bookmark_serpent、book_cart_raider、compact_stacks_boss、index_keeper_boss、laptop、desktop_tower、peripheral_cluster、grading_machine、copier、bicycle、e_bike、cleaning_vehicle、library_sorter、cold_aisle_core。登记 rejected，历史图片保留；已批准对象及友军班车不受影响。
- 新增下列十项 concept_001，均为普通敌人，pending / unselected / not_integrated。编号 A/B/C 仅用于本轮预览，避免与旧编号混淆。

| 编号 | 候选与概念图 | 攻击／技能动作 |
|---|---|---|
| A1 | 弹跳篮球 | 压缩蓄力后弹跳撞击 |
| A2 | 羽球突刺 | 收拢羽毛，以球头向前俯冲 |
| A3 | 跳绳缠灵 | 单根绳索甩动并缠住目标 |
| B1 | 餐盘格挡怪 | 竖起格挡后用盘面冲撞 |
| B2 | 汤勺泼手 | 倾转勺体泼洒热汤 |
| B3 | 蒸笼喷喷 | 抬盖蓄压后喷出蒸汽 |
| C1 | [计算机组成原理](../../../design/concepts/m1-enemy-cast/textbook-architecture/concept_001/textbook_architecture_action_concept_001.png) | 通过 CPU 运算发射数字脉冲 |
| C2 | [线性代数](../../../design/concepts/m1-enemy-cast/textbook-linear-algebra/concept_001/textbook_linear_algebra_action_concept_001.png) | 生成矩阵区域，改变目标站位 |
| C3 | [信息安全数学](../../../design/concepts/m1-enemy-cast/textbook-security-math/concept_001/textbook_security_math_action_concept_001.png) | 生成模运算封锁环限制目标 |
| C4 | [编译原理](../../../design/concepts/m1-enemy-cast/textbook-compilers/concept_001/textbook_compilers_action_concept_001.png) | 词法单元进入语法树，输出指令弹 |

### 本轮检查与边界

- 十张 PNG 已实际解码，尺寸为 1536×1024 或 1774×887；完整生成提示词在各目录 generation.md。
- 跳绳初稿甩圈出现分叉，定向修正为两个握柄之间的一根连续绳索后再归档。羽毛球以球头前冲，汤液从勺口流出，餐盘的格挡与冲撞动作可读。
- 教材采用四个真实课程名称，但封面为游戏内原创设计，不对应某位作者、出版社或具体版本。与馆藏巨典区分为薄型教科书和不同技能，不沿用纸飞机攻击。
- 教材的微小字符、二进制串和公式仅为生成示意，尚未通过教学正确性检验，正式制作应校正或简化；线性代数的移位属于玩法意象，不作严格线性变换教学图。信息安全数学末格为封锁技能特写，不是完整本体姿势。蒸笼导杆数量仍需正式资产统一。
- 当前只做概念筛选，未生成可直接使用的动画帧、正式战斗资产或 Godot 接入。以下为历史评审快照，以本节及 Manifest 最新记录为准。
- 验证入口：PNG 解码、AssetCatalog.scan()、git diff --check；本轮未改变运行画面，无需游戏截图。

## 五项重做概念批准（2026-09-25，最新评审）

- 负责人对上一轮展示的五张重做稿回复：“这几个都概念通过”。批准范围绑定：04 键帽拳灵 concept_002、07 投影独眼灵 concept_003、09 归还印章怪 concept_002、11 监考钟灵 concept_002、19 广播中继 concept_003。五个 Manifest 版本均登记 selected + approved，旧版状态及否决记录保留。
- 03 试卷怨灵 concept_002、05 光标术士 concept_003 仍按上一轮“保留”意见维持 selected + review；本次原话不扩张为这两张的概念批准。
- 04 拳面接触透视、09 伸缩蓄力行程与盖印接触帧属于后续动作设计细化事项，不影响本次概念批准。07、11 采用无脚悬浮造型，19 为非类人广播支援设备。
- 此批准仅完成概念阶段；五项的正式战斗资产、动画、技能效果与 Godot 接入尚未制作，integration 仍为 not_integrated。后续资产与接入效果各自评审。

## 候选筛选与五项重做（2026-09-25，最新入口）

- 按上一轮预览编号：03 试卷怨灵 concept_002、05 光标术士 concept_003 保留，登记 selected + review；“保留”不扩张为正式概念批准。机房终端旧 concept_001 取消当前选中，但保留历史方向评审证据。
- 04 键帽拳灵 concept_002、07 投影独眼灵 concept_003、09 归还印章怪 concept_002、11 监考钟灵 concept_002、19 广播中继 concept_003 为本轮新候选，均 pending / unselected / not_integrated。其他候选状态不变。
- 07、11 去脚并悬浮；19 保留广播中继身份，重设计为调频、展开挡板、向机械友军增幅；受益者仅示意，不是新增敌人。
- 04、09 先按 image-quality-check 检查，再由 imagegen 执行修复：04 原稿拳面排列漂移，蓄力／出拳对应不清，修成双键固定拳面；09 原稿目标在印外，修为印内目标，二次迭代纠正木柄压扁。
- 全部原图与完整提示词见各对象新版本 generation.md。首轮中间稿未替换旧资产。投影首轮异常透明背景已通过第二轮改为灰底。
- 本轮只概念设计，未生产正式资产、动画或接入游戏；沿用用户继续概念筛选的决定，不执行下方先做正式资产的旧建议。

### 04、09 最终质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-enemy-cast
  results:
    - target: keycap_brawler/concept_002
      status: PASS_WITH_NOTES
      eligible_for_style_validation: true
      checks:
        technical_integrity: PASS
        subject_and_identity: PASS
        anatomy_and_physics: PASS
        prompt_and_content: PASS
        composition_and_readability: PASS
        generation_artifacts: PASS
      failures: []
      notes: ["双键拳面统一；击打面透视与按键下压深度仍需正式动作稿细化"]
      repair_directives: ["后续明确拳面接触平面，不将当前图直接用作动画帧"]
      next_step: accept
    - target: return_stamp/concept_002
      status: PASS_WITH_NOTES
      eligible_for_style_validation: true
      checks:
        technical_integrity: PASS
        subject_and_identity: PASS
        anatomy_and_physics: PASS
        prompt_and_content: PASS
        composition_and_readability: PASS
        generation_artifacts: PASS
      failures: []
      notes: ["目标在印内、木柄不再压扁；蓄力行程仍小，盖印接触帧尚未展示"]
      repair_directives: ["后续放大伸缩蓄力行程并补盖印接触帧"]
      next_step: accept
```

上述为概念用途通用检查，不代表人工批准或画风匹配通过。验证入口：PNG 解码与尺寸检查、catalog scan、git diff --check。

## 当前批准与进度（2026-09-24）

- 负责人原话：“这两张概念通过”。批准绑定馆藏巨典 concept_004 与图书管理员 concept_003，Manifest 已登记 selected + approved；旧版本不继承批准。
- 馆藏巨典为普通敌人：无脚悬浮、本体重砸、左右展开书页发射纸飞机。
- 图书管理员为图书馆 Boss：非类人悬浮电子设备，沉稳古板；肃静区域与归架书群动作意图已确认。
- 当前完成概念阶段；这两个对象尚无正式战斗资产、动画／弹体运行包、技能实装或 Godot 接入，均保持 not_integrated。
- 下一阶段建议先制作巨典的正式静态战斗资产与独立纸飞机弹体，再制作管理员及技能表现；正式资产和接入效果仍分别评审。本次批准不自动启动生产或合并 main。
- 其他敌人继续按各自 Manifest 与历史评审记录处理，不视为整套敌人阵容通过。以下章节保留生成时状态，以本节最新批准为准。
- 验证：资源台 catalog scan 与 git diff --check；仅审批记录变更，无运行画面变化。

## 书本结构与技能方向修复（2026-09-24，最新评审入口）

- 负责人认可前轮概念方向并要求修复；特别指出巨典展开不像书、纸飞机头朝向相反。此意见不自动批准新版本或正式资产。
- [馆藏巨典 concept_004](../../../design/concepts/m1-enemy-cast/great-volume-boss/concept_004/great_volume_boss_action_concept_004.png)：展开改为明确的左右矩形页、中央装订缝、页块和封面；纸飞机尖头朝右，宽尾及尾迹在左；统一两条书签，保留悬浮与重砸。实际有三处卷页角，不影响概念用途。
- [图书管理员 concept_003](../../../design/concepts/m1-enemy-cast/cyber-librarian/concept_003/cyber_librarian_action_concept_003.png)：保留非类人机身；肃静区域包住目标，扫描与归架书群汇向右下同一目标；运动时序留待动画验证。
- 两张均 pending / unselected / not_integrated；旧版保留，新版完整提示词、来源与初检见 generation.md。本轮仅概念修复，无运行画面变动，不代表正式资产通过。

## 纸飞机巨典与非类人管理员（2026-09-24，最新评审入口）

- 负责人修改意见：巨典不丢实体书，向左右展开后投出纸飞机；管理员不要类人形，避免恐怖谷，参考《瓦力》伊娃的方向。
- 馆藏巨典 concept_003：保留无脚悬浮普通敌人和重砸，右侧姿势改为左右展开、纸飞机齐射。展开页层偏复杂，正式资产需简化。
- 图书管理员 concept_002：完全去掉人脸、头颈与四肢，采用圆润悬浮机身、平直电子眼、对称书挡控制翼、归还口和扫描器；通过秩序感表现沉稳古板。伊娃为设计语言参考，不直接复刻角色。
- 概念动作保留值守、肃静、归架；当前归架图的书群飞行方向与锁定目标不一致，动作尚需修正，本轮先评审非类人造型。
- 两版均 unselected + pending + not_integrated；不继承旧版批准。旧图和旧记录保留，下文丢书和类人方向已被本节覆盖。内置 image_gen 提示词与来源见各版本 generation.md。
- 验证：实际图片解码与尺寸检查、资源台 catalog scan、git diff --check；仅概念图更新，没有修改运行画面或战斗逻辑。

## 悬浮巨典与图书管理员（2026-09-24，最新评审入口）

- 负责人决定：咬页书怪与馆藏巨典重复，只保留馆藏巨典作为普通敌人；无需脚，悬浮，动作是砸人与丢书。咬页书怪 concept_001 已登记 rejected，旧图保留。
- 馆藏巨典对象 subtype 改为 enemy；历史 ID great_volume_boss 为保持引用暂留，名称后缀不再代表当前战斗职责。concept_001 为旧Boss探索，当前候选为 concept_002：无脚悬浮、自体重砸、打开书页丢出实体书。旧版批准不自动转移。
- 新增 图书管理员 concept_001：沉稳、古板的赛博仿生管理者，电子眼镜与机械手，整齐深色制服，借阅账册与有序悬浮书阵。
- 管理员概念动作：值守（收手抱册）、肃静（竖指、发出抑制场）、归架（展开账册并抬手发射书阵）。技能效果尚未实装。
- 管理员当前生成比例偏约七头身，作为身份／动作意图概念展示，未达到战斗约四头身要求；正式战斗制作前需压缩比例、放大手势与电子识别点。
- 两张均为 unselected + pending + not_integrated；已展示、解码并记录尺寸、哈希与完整提示词。仅概念与登记修改，无运行画面变化。
- 下方为历轮记录；本节覆盖其中关于巨典作为Boss、咬页书怪继续候选的旧建议。

## 图书馆敌人拓展（2026-09-22，最新评审入口）

用户否决电容跳豆 concept_001、广播号令灵 radio/concept_002、答辩投影巨像 concept_001，指出机房编译核心 concept_001 原型难辨，要求更多敌人概念及图书馆 Boss。本批将这四个具体版本标为 rejected；广播历史 concept_001 的保留意见不被扩大撤销。旧图不删除。

本批提供四个普通敌人与三个图书馆 Boss 方向，均已生成静止／蓄力／出手概念板，状态 unselected + pending + not_integrated。优先使用明确可辨的书本、书签、借阅章、书车、密集书架和目录柜，不继承旧概念批准。

| 编号 | 角色 | 图片 | 初检与待改 |
| --- | --- | --- | --- |
| 1 | 咬页书怪 | 概念 001 | 书封咬合与纸齿清楚，近战行为成立；需与订书钳兽区分攻击节奏，避免同职责重复。 |
| 2 | 书签游蛇 | 概念 001 | 连续带身与缠绕行为可读；头部偏金属蛇头，需强化书签夹身份；书脊连接点需要在正式拆件时明确。 |
| 3 | 归还印章怪 | 概念 001 | 印章原型与压缩、盖印动作明确；图中目标在印外，表现更像击退，禁锢效果的目标位置需重画。 |
| 4 | 书车冲锋手 | 概念 001 | 图书车原型明确，车身前倾与书本发射可读；图中更偏移动投射，若选择冲撞主攻需追加接触姿势。 |
| 5 | 闭架书库（Boss） | 概念 001 | 图书馆身份最强，开架蓄力可读；夹击末姿势合拢不足，轨道与转轴运动仍需细化，不视为动作通过。 |
| 6 | 馆藏巨典（Boss） | 概念 001 | 巨典原型与翻页蓄力、合书重砸明确，作为首个Boss优先推荐；脚部纸层与封面细纹正式资产前需简化。 |
| 7 | 索引管理员（Boss） | 概念 001 | 目录卡柜与抽屉齐射清楚；采用复古目录柜需与图书馆年代设定相容。生成抽屉布局与原提示词不完全一致，但三个姿势基本保持一致；卡片数量需控制。 |

### 推荐与边界

- 当前优先推荐馆藏巨典：原型识别与重砸动作最直接。闭架书库适合封路、夹击和开闭阶段，但需另做真正合拢的关键姿势，不能以当前图判定攻击动作完成。索引管理员适合抽屉齐射和卡片减益。
- 四个普通敌人分别探索扑咬、缠绕、盖印、车轮冲击／抛书；这些是行为设计建议，未扩展运行时战斗机制。
- 馆藏巨典首稿背景与评审板不一致，已用内置 imagegen 定向修正背景和留白；未通过的首稿没有覆盖任何历史评审资产。
- 七张 PNG 已检查解码、实测尺寸与哈希，记录在各图 generation.md；完整生成提示词与最终来源同文件保存。
- 本次只涉及概念图、人工意见与 Manifest，没有运行画面变化，不做 Godot 接入截图。新图等待负责人选定，技术检查不代表人工通过。

## 动作概念重设计（2026-09-22，上一轮评审）

负责人指出旧图难以看出敌人的攻击或技能，要求参照粉笔精灵重新设计；本批按随后“给出他们的概念图”生产上轮讨论的全部十二个候选，每张展示静止、蓄力、出手。使用内置 imagegen，完整提示词、实际来源及逐张视觉边界在同目录 generation.md。

本节为当前工作方向；下文旧设备概念、旧候选清单与验证结果保留为历史，不代表本批批准。所有本批版本均为 unselected + pending + not_integrated。浅灰底与姿势标题是概念评审板的组成，不是正式战斗资产；不从三姿势图片推定动画或技能已经实现。

### 负责人方向决定

- 班车退出敌人用途，转为友军可用的交通设施，用于解锁局外派遣范围；决定来源：2026-09-21 当前对话。Manifest 的对象 subtype 已改为 allied_transport。旧敌对造型保留追溯，不表示获准作为友军正式资产；派遣机制尚未接入，具体解锁条件待后续设计。
- 机房终端 concept_003 为光标术士重设计，身份和结构都发生改变，不沿用 concept_001 的方向批准。
- 新敌人以“来源物件 → 能行动的身体 → 明确蓄力与释放”作为首要评审标准，移除上一轮一概禁止肢体的限制。

### 本批图目

| 编号 | 角色 | 当前概念图 | 状态 |
| --- | --- | --- | --- |
| 1 | 订书钳兽 | concept_001 | 待评审 |
| 2 | 圆规刺客 | concept_001 | 待评审 |
| 3 | 试卷怨灵 | [concept_002](../../../design/concepts/m1-enemy-cast/exam-paper/concept_002/exam_paper_action_concept_002.png) | 待评审 |
| 4 | 键帽拳灵 | concept_001 | 待评审 |
| 5 | 机房终端·光标术士 | [concept_003](../../../design/concepts/m1-enemy-cast/computer-terminal/concept_003/computer_terminal_action_concept_003.png) | 待评审 |
| 6 | 网线缠绕怪 | concept_001 | 待评审 |
| 7 | 电容跳豆 | concept_001 | 待评审 |
| 8 | 广播号令灵 | concept_002 | 待评审 |
| 9 | 投影独眼灵 | concept_002 | 待评审 |
| 10 | 监考钟灵（Boss） | concept_001 | 待评审 |
| 11 | 答辩投影巨像（Boss） | concept_001 | 待评审 |
| 12 | 机房编译核心（Boss） | concept_001 | 待评审 |

### 初检结论与后续约束

- 十二张均已实际展示并检查，可辨认三阶段动作；全部保存为原始 PNG，完整提示词随图保存。
- 订书钳兽、圆规刺客、试卷怨灵的攻击来源与姿势变化较直观，建议优先评审。
- 键帽拳灵、广播与钟灵偏人形机器人；须由负责人判断是否需要进一步强化非人精灵感。
- 网线缠绕怪第三格的缠绕线圈与主体连接不清晰，进入正式动作设计前必须修正；广播受益者被画成学生，敌军支援版需替换为怪物轮廓。
- 自动生成的校名、品牌样式字和宣传语不属于批准的世界观内容；正式资产须删除，并简化键帽小字、纸面和服务器细节。
- 仅概念图片和登记修改，无运行画面变化；检查图片解码、路径、Manifest 和 Git 差异即可，不制作 Godot 接入截图。

状态：草案，部分方向已通过。负责人已否决折纸、移动工位和三版门禁方向；广播中继保留；机房终端 `concept_001` 方向通过但鼠标需纠正，`concept_002` 已按意见重画待确认。本轮另补齐五个普通敌人与三个 Boss 候选。这不代表整套敌人家族或终局节点方案已冻结。

## 目标与范围

- 用途、数量与本次要求：统一 M1 普通敌人、区域守卫和终局节点的战斗视觉语言；在上一轮电脑／考试四张概念基础上，修正 `computer_terminal`，并新增普通敌人 `desktop_tower`、`peripheral_cluster`、`cleaning_vehicle`、`copier`、`projector`，以及 Boss `shuttle_bus/concept_002`（零号班车）、`library_sorter`、`cold_aisle_core`，合计九张本轮评审图。
- 对应规范、已有身份参考：`docs/art/WORKFLOW.md`、`docs/art/ART_CONTRACT.md`、`docs/art/STYLE_BIBLE.md`、`docs/art/specs/CHARACTER_SPEC.md`；chalk_spirit `asset_006` 为已批准方向与战斗表现参考。
- 目标 Godot 场景、入口与依赖：后续接入将使用 M1 实际战斗入口 `scenes/expedition/expedition.gd` / `scenes/battle_demo/pixel_battle.gd`；本阶段不接入。
- 不在本次范围内的内容：继续生产折纸、移动工位、门禁或配送机器人概念；旧讨论中的监控摄像头、无人机、售货机等储备方向；动画、图集、特效、战斗机制、运行时代码、共享 Token、现实校园或真人内容。

## 真实使用清单与首轮选择

M1 `campaign_hub.gd::_guard()` 的非终点区域战斗统一载入 `encounter_patrol`；该遭遇的四个单位依次为 `paper_guard`、`desk`、`radio`、`pages`。终局载入 `encounter_final`，为 `colossus + chalk + chalk`。`chalk` 已使用批准的 `assets/art/characters/chalk_spirit` 正式运行包，不属于本轮占位替换；其余敌人仍引用 `assets/pixel/kenney/tiny-dungeon.png` 的 16×16 像素头像。

`paper_guard` 的折纸与门禁方向、`desk` 移动工位均已退出当前候选；配送机器人只出现在讨论候选中，没有生成或登记。`radio` 广播中继保留为支援型参考。敌人池现分为“校园交通、计算机机房、教学考试、校园设施”四个现实子族：机房终端、笔记本、台式主机和外设群提供电脑主体；错题试卷、自动阅卷机、复印机和投影仪提供教学身份；清扫车取代配送机器人，明确使用校园保洁设备；零号班车、借还分拣总机、冷通道主机柜提供三种不同 Boss 轮廓。`exam_paper` 与现有 `pages` 语义接近；候选在概念批准前不修改运行时 ID 或遭遇配置。

## 当前版本与方案

- 当前使用版：`paper_guard`、`desk`、`radio` 当前仍为 `resources/content/enemies/*.tres` 的 Kenney 像素头像，占位；没有正式绘制战斗资产，运行时未修改。
- 当前候选：机房终端 `concept_001` 为 `selected + review`，记录“方向通过但鼠标需修正”；修正版 `computer_terminal/concept_002` 与本轮五个普通敌人、三个 Boss 均为 `unselected + pending + not_integrated`。此前的笔记本、试卷、阅卷机、广播、交通组仍待评审；`paper_guard` 三版与 `desk/concept_001` 为已否决历史候选。
- 本轮改动、需保留的部分与当前待决事项：机房终端只修改鼠标前后朝向和出线方向，保留已通过的主体。新增候选刻意覆盖低宽、竖重、车辆、办公设备、教学设备及三种 Boss 占框；待决定哪些进入正式资产阶段。外设群、投影仪、零号班车与分拣总机存在概念阶段暗色半透明晕染，正式资产前需清边；台式主机、零号班车和冷通道主机柜需在小尺寸减少面板细节。
- 复用的批准方向／资产及原评审记录：只复用 `chalk_spirit asset_006` 的战斗线条、透明轮廓和显示纪律，以及 `guard battle_current` 的四头身占框参考；不复制主体身份。参考图用途和来源记在候选 `generation.md`。
- 技术依据：颜色读取 `data/visual/colors.json` 的品牌青／品红／深色角色；比例读取 `CHARACTER_SPEC.md`；实际敌人引用来自 `resources/content/encounters/patrol.tres`、`final.tres` 与 `resources/content/manifest.tres`。
- 接入要求：后续正式资产须从同一概念源制作静态战斗图和共享头像裁切，沿用 M1 战斗背景与原生 UI；本阶段无接入要求。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `paper_guard_concept_001.png` / `concept_001` / `184D9F0181F06B94BF016D7334C3569583F09F2548835E764E27A7BB4CCC9847` | 已否决 | 折纸守卫不符合大学、科幻、计算机、电子机械、电路方向 | 负责人决定；2026-09-20 |
| 概念 | `paper_guard_concept_002.png` / `concept_002` / `691D2E3F339FAD72C98C978F7F69F11ACB3ED57699AA8FCFB04294CD0709FC9E` | 已否决 | 门禁需要换成更像移动机械敌人的风格 | 负责人决定；2026-09-20 |
| 概念 | `paper_guard_concept_003.png` / `concept_003` / `CBEE3FFAD21C97A0ACEB0C2FEAA6B29D594949579FFE62917CEDE67F975ED0E3` | 已否决 | 门禁怪物过于抽象；停止继续生产，门禁可另作场景机关 | 负责人决定；2026-09-20 |
| 概念 | `desk_concept_001.png` / `concept_001` / `ABEDC5F977D523C525D4FFDDD66D20D754DA83A7EB7A152AE7BD930B3A2736EB` | 已否决 | 移动工位不符合当前敌人家族，不再继续生产 | 负责人决定；2026-09-20 |
| 概念 | `radio_concept_001.png` / `concept_001` / `3B79FBE517F3297C80C691A7474B38A917CB24DCA8ADDA190BCF9FCE2354827E` | 保留待评审 | 广播中继保留，作为通信支援型敌人 | 负责人决定；2026-09-20 |
| 概念 | `bicycle_concept_001.png` / `concept_001` / `1D7A2F15749D339733F13896EE6B72D3FA00242CAC64490E3007D73F848F3757` | 待评审 | 判断自行车的低窄轮廓、校园身份与机动敌人潜力 | 待负责人决定 |
| 概念 | `e_bike_concept_001.png` / `concept_001` / `ED4E6479A26CD59D733A2D29F6A18845D84A3AF27861FBE1160ABE769134B956` | 待评审 | 判断电池盒、电机环、充电线缆与故障冲撞身份 | 待负责人决定 |
| 概念 | `shuttle_bus_concept_001.png` / `concept_001` / `49B20955BBC0C391EF711C15AFD59E490F36D150A52A038B8225283C49DC425A` | 待评审 | 判断班车的宽重轮廓与校园重型单位潜力 | 待负责人决定 |
| 概念 | `computer_terminal_concept_001.png` / `concept_001` / `6988AFE00138CADBD9317A6F2D55FC433FDEE43D90592FD98BEAA660CA428118` | 方向通过，修正中 | 主体概念通过；鼠标画反，修正后再确认 | 负责人决定；2026-09-21；“机房终端的鼠标画反了，概念通过” |
| 概念 | `computer_terminal_concept_002.png` / `concept_002` / `95DA1F9F25A51E9843E7F1E9858EDF24257C5A3F0911889F05D53A1FADCD064F` | 待评审 | 已把鼠标按钮朝向键盘并从前端出线；其余主体保持 | 待负责人决定 |
| 概念 | `laptop_concept_001.png` / `concept_001` / `EF2FF42819BBB9D94EEE9D381F82A700D967E5CDCD9C92C4C34FBFCEB0BE910F` | 待评审 | 判断屏幕／键盘双平面与合页夹击轮廓 | 待负责人决定 |
| 概念 | `exam_paper_concept_001.png` / `concept_001` / `104CBE1FE34484EC817D5B58B01F8DEA4DB046875143DE71228978057A5A9D6B` | 待评审 | 判断试卷、批改痕迹与轻型减益敌人身份 | 待负责人决定 |
| 概念 | `grading_machine_concept_001.png` / `concept_001` / `D8987796BD214263EAA16836FB31EDA6C2A66920B3A48E4FC75842BCF5040A01` | 待评审 | 判断进纸、扫描、出纸结构与精英支援身份 | 待负责人决定 |
| 概念 | `desktop_tower_concept_001.png` / `concept_001` / `BDC7E2283A76AE78DCB5CB6EF6B46A8ABBEC74F9070519E4FF258218C7532054` | 待评审 | 判断台式机箱的重装防御轮廓与过热身份 | 待负责人决定 |
| 概念 | `peripheral_cluster_concept_001.png` / `concept_001` / `AC1004B49B33A73F86A41E0C7F9BACBD0008E3DA88D7C9A24B07C26B840A161A` | 待评审 | 判断键盘、鼠标、耳机组成的低矮干扰型是否成立 | 待负责人决定 |
| 概念 | `cleaning_vehicle_concept_001.png` / `concept_001` / `008D6DB50290325D7CA4319ADF78B85BF589E05F1C5392A68B3321885A6909EB` | 待评审 | 判断校园洗地车与配送机器人是否已充分区分 | 待负责人决定 |
| 概念 | `copier_concept_001.png` / `concept_001` / `41233F10DAFEE3C9DFB0C117BD213853E2455896068B3FD3A63C8FA2AD18FFC4` | 待评审 | 判断复印机纸路与远程攻击身份 | 待负责人决定 |
| 概念 | `projector_concept_001.png` / `concept_001` / `8AB2DEB1329CA2D1BE4A771422600CD5641B829E72137DD986230F8E2B69664A` | 待评审 | 判断大镜头与聚焦干扰身份，正式资产前清暗部晕染 | 待负责人决定 |
| 概念 Boss | `shuttle_bus_concept_002.png` / `concept_002` / `99B56A8F68D9FE1B5F451E0626D5B794654EA8D9BD1612CFADCF955CDCF680AE` | 待评审 | 判断零号班车是否兼具校园班车辨识与冲撞 Boss 压迫感 | 待负责人决定 |
| 概念 Boss | `library_sorter_concept_001.png` / `concept_001` / `8E21873113E8E7EE2B6F07FE9DA21E27317F4E7D47A1ABFACA5196924E4CB1C4` | 待评审 | 判断借还分拣物流与改道型 Boss 身份 | 待负责人决定 |
| 概念 Boss | `cold_aisle_core_concept_001.png` / `concept_001` / `0CF5F9F23DE012FE0D6E9462FDDA6F5C0517B2DD73B63D997B8EE5ECBEB4A004` | 待评审 | 判断三联主机柜与防御型终局轮廓 | 待负责人决定 |
| 资产 | 待提交 | 待评审 | | |
| 接入效果 | 待提交 | 待评审 | | |

## 验证与结果

- 本任务验收条件：真实使用清单可追溯；概念图单一虚构主体、无文字／UI／水印；轮廓在缩略图可读；真实 Alpha 与尺寸已检查；Manifest 已登记候选；未误接入运行时。
- 技术检查结果及必要复现命令：本轮九张 PNG 均可解码为 `Format32bppArgb`，四角 Alpha 为 `0`，采样到真实透明通道；尺寸与 SHA-256 已逐项记录在评审表和 `generation.md`。机房终端鼠标方向已修正；生成中出现的重复外设小图、外设机械足版本与辨识度较弱版本均未入库。
- Manifest 回写：`computer_terminal/concept_001` 记录为 `selected + review` 并绑定负责人原话，新增修正版 `concept_002`；主 Manifest 新增五个普通敌人与两个新 Boss 对象，`shuttle_bus` 新增 Boss 版 `concept_002`；所有新图均保持 `not_integrated`。
- 一致性检查：概念只位于 `design/concepts/`，没有 Godot Resource、正式 `assets/art/characters/` 文件或运行时引用；同源头像只作为后续正式裁切约束，当前未新增头像。
- 适用的布局／动画验证结果：不适用；本阶段没有运行时画面、图集、动画或 Godot 接入。
- 实际截图／动作预览证据：概念原图已在对话中展示；没有伪造 Godot 接入截图。
- 未解决问题：负责人尚未确认机房终端修正版及本轮八个新角色；还需决定外设群是否过于复杂、清扫车是否适合战斗、复印机与阅卷机是否功能重叠，以及三个 Boss 的优先级。概念阶段暗部晕染与高频机械细节不直接进入正式小尺寸资产。
- 本地提交：本轮九张概念记录在资源台扫描与 33 项美术工具测试通过后随本提交落库；不推送远程。
