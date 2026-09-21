# 美术任务：M1 校园探索地点环境

状态：十二处明确现实地点概念已批准；旧步道与篮球场两个未确认现实身份候选仍待评审。任务草案与版本记录遵循[美术工作流](../WORKFLOW.md)；本任务不修改校园大地图、路线、地点 Resource 或运行时代码。

## 目标与范围

- 用途、数量与本次要求：建立 M1 校园地点背景家族。南门 `gate` 概念已批准为日常视觉基准；后续按现实资料充分度逐项制作地点候选。用户本轮新增九处明确实景：学子食堂、学生活动中心、西湖中心、成电会堂+商业街、银桦食堂+清真食堂、基础实验大楼、西湖入口、操场、图书馆正面。
- 对应规范、已有身份参考：[场景视觉规范](../specs/ENVIRONMENT_SPEC.md)、[视觉方向](../STYLE_BIBLE.md)、[M1 静态资源清单](../m1-static-assets.md)、用户提供的校园平面图与南门／品学楼照片。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/exploration_board.gd` 的地点环境层；本轮不接入。现有 `game/run/campus_region.gd` 只作为地点 ID 与区域逻辑依据。
- 不在本次范围内的内容：区域地图底图、路线与建筑定位、运行时地点绑定、两个终点命名、照片卡、UI 贴图、人物、战斗代码和运行时代码。

### 现实身份资料审计

| 地点 ID | 当前运行时占位身份 | 当前参考状态 | 后续最低补充 |
| --- | --- | --- | --- |
| `gate` | 校门／旧校门 | 南门照片与校园平面图已提供 | 概念评审；正式制作前确认可使用范围 |
| `walk` | 步道 | 已生成湖畔步道概念候选；平面图有水系、绿地和道路关系，尚无指定步道照片 | 1 张能看出具体路径形态的照片，并在平面图上标注位置；当前候选不代表已确认现实路径 |
| `court` | 球场／当前 Resource 显示“篮球场” | 已生成篮球场概念候选；平面图可见运动场组团，尚无指定球场照片 | 1 张确定场地身份的宽景照片，并标注具体场地；当前候选不代表已确认现实球场 |
| `hall` | 走廊／教学走廊 | 仍缺走廊实景；品学楼两个明确地点另行登记为独立视觉身份，不冒充走廊 | 1 张走廊实景照片，并标注所属楼栋／区段 |
| `end_b` | 第二终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |
| `end_c` | 第三终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |

用户本轮明确提供并确认了两处独立现实地点：品学楼（教学楼）单区内部庭院、品学楼组团的中庭。它们现在分别登记为 `m1_pinxue_courtyard` 与 `m1_pinxue_atrium`；由于用户尚未指定它们对应 `hall`、`end_b` 或 `end_c` 哪个运行时占位，暂不强行绑定。

用户随后又明确提供并确认九处实景，分别登记为 `m1_xuezi_cafeteria`、`m1_student_activity_center`、`m1_west_lake_center`、`m1_chengdian_auditorium_commercial_street`、`m1_yinhua_halal_cafeterias`、`m1_basic_laboratory_building`、`m1_west_lake_entrance`、`m1_sports_field` 与 `m1_library_front`。这些对象保留现实地点身份，但同样不擅自绑定现有运行时占位；图书馆正面候选按用户要求移除了旗帜与旗杆。

## 当前版本与方案

- 当前正式资产：十二处日常背景已按批准概念逐字节提升到 `assets/art/backgrounds/m1_campus_locations/<地点>/daily.png`；尚未接入，所有对象 `integration.status` 仍为 `not_integrated`。
- 当前概念基准：`concept_003`；[南门远景修订概念](../../design/concepts/m1-campus-locations/m1_campus_locations/003/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_locations/003/generation.md)。原始 `concept_001`、`concept_002` 保留用于回溯与对比。
- 当前已确认部分与后续待决事项：负责人确认南门概念可以，`concept_003` 作为已选概念基准；其远景主楼通过缩小门窗、降低细节和空气透视表达距离，南门近景结构、右上补全及四个热点锚点保持不变。后续地点仍需逐一确认现实身份；概念批准不等同于正式资产批准或 Godot 接入授权。
- 新增地点候选：`m1_campus_walk/concept_001`；[校园湖畔步道概念](../../design/concepts/m1-campus-locations/m1_campus_walk/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_walk/001/generation.md)。该候选使用校园平面图的大关系，不宣称具体现实步道身份，状态为 `unselected + pending`。
- 新增地点候选：`m1_campus_court/concept_001`；[校园篮球场概念](../../design/concepts/m1-campus-locations/m1_campus_court/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_court/001/generation.md)。该候选使用校园平面图的运动场组团大关系，不宣称具体现实球场身份，状态为 `unselected + pending`。
- 已批准明确地点概念：`m1_pinxue_courtyard/concept_001`；[品学楼单区内部庭院概念](../../design/concepts/m1-campus-locations/m1_pinxue_courtyard/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_pinxue_courtyard/001/generation.md)。该版本基于用户提供的庭院实景、校园平面图和已批准日常方向，状态为 `selected + approved`，运行时地点绑定待确认。
- 已批准明确地点概念：`m1_pinxue_atrium/concept_001`；[品学楼组团中庭概念](../../design/concepts/m1-campus-locations/m1_pinxue_atrium/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_pinxue_atrium/001/generation.md)。该版本基于用户提供的中庭实景、校园平面图和已批准日常方向，状态为 `selected + approved`，运行时地点绑定待确认。
- 已批准九处明确实景概念：`m1_xuezi_cafeteria`、`m1_student_activity_center`、`m1_west_lake_center`、`m1_chengdian_auditorium_commercial_street`、`m1_yinhua_halal_cafeterias`、`m1_basic_laboratory_building`、`m1_west_lake_entrance`、`m1_sports_field`、`m1_library_front` 的 `concept_001`。每处均使用对应用户实景作为身份参考、南门 `concept_003` 作为画风参考；全部为 `selected + approved`，运行时地点绑定待确认，图书馆版本额外记录 `remove_flags_and_flagpoles`。
- 复用的批准方向／资产及原评审记录：沿用 v0.3 清爽理工校园 × 轻数字美术 × 局部赛博强化方向，以及已批准图书馆环境的日常层渲染纪律；不复制图书馆几何，不修改图书馆任务。
- 技术依据：1672 × 941、不透明 RGB PNG；日常状态使用 `data/visual/colors.json` 的日常层；间距与安全区按 `data/visual/spacing.json` 的 4px 倍数原则在后续原生 UI 接入中处理。本轮不生成 Godot 资源、不改运行时代码。
- 接入要求：未来背景不烘焙文字、按钮、侧栏、热点图标或路线线条；需在 1920×1080、2560×1440、1920×1200 三种桌面视口验证四角与底部操作区不压关键建筑。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001/concept.png` · `586D7711B6BF19FEFF5C53149152D76F366F35F54B7482B205CD62DE0FFEDA11` | 待评审 | 请确认南门身份、2D 表现方向、构图安全区与四个热点锚点。 | 待负责人决定 |
| 概念 | `concept_002/concept.png` · `AEFC64205550A9C384A2967623AF4F2826A186A36C48E15419ECFB5313F3B367` | 待评审 | 用户要求移除右上选定区域；请确认修补边界、连续天空／树冠效果，以及其余南门构图是否保持。 | 2026-09-20，用户修订请求；待负责人决定 |
| 概念 | `concept_003/concept.png` · `5CB280638B9B29A1CCF7DDCC8334E2E0E12A4826ABD5C746D03BC2033454386A` | 已批准，选为概念基准 | 用户确认可以；保留远景主楼的门窗缩小、细节降低与空气透视，作为其他地点概念的日常层参考。 | 2026-09-20，负责人确认“可以了，继续生成其他的地点” |
| 概念 | `m1_campus_walk/concept_001/concept.png` · `5F63B9DB3A36FC67A93F1DE3855E7796B9FCCA52639938A1221B680EE1FB652A` | 待评审 | 湖畔步道候选；请确认步道的场景价值与湖岸构图，并注意现实路径身份仍待照片和地图标记确认。 | 2026-09-20，基于负责人继续制作授权；待负责人决定 |
| 概念 | `m1_campus_court/concept_001/concept.png` · `01B872F85D9FE3B18C925A8D712533A53EC8CF8DDF46FD1DF8F2B1FACE45AB50` | 待评审 | 篮球场候选；请确认球场的场景价值与运动场组团构图，并注意现实场地身份仍待照片和地图标记确认。 | 2026-09-20，基于负责人继续制作授权；待负责人决定 |
| 概念 | `m1_pinxue_courtyard/concept_001/concept.png` · `865D67C5B82D3225165F179845CA976C33340F51D83CBCC91E9497051AA9AA5B` | 已批准 | 品学楼单区内部庭院；中央窄塔、连廊、坡道与庭院尺度通过概念验收。运行时 ID 暂不绑定。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_pinxue_atrium/concept_001/concept.png` · `A854A0FD6FA39026356E4384139A35B8661D615EFEA2A0456C1A89DB70EAB25F` | 已批准 | 品学楼组团中庭；台阶、左右翼楼、中央廊桥、柱列与轴线开口通过概念验收。运行时 ID 暂不绑定。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_xuezi_cafeteria/concept_001/concept.png` · `1520A31F7E4CD5DB2EDCB1201C9C82D097CD1097350B0AAF6E6AA3193AB8DC39` | 已批准 | 学子食堂；红米色体块、玻璃中轴、道路与宿舍背景通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_student_activity_center/concept_001/concept.png` · `A146B8A8CF1C279F19CA8B2B7B7AD3111C1613CBFF7F417FAED26C73F67D3D64` | 已批准 | 学生活动中心；弧形立面、广场与右侧道路通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_west_lake_center/concept_001/concept.png` · `81B7847073EC16833EF4FFDD418A2613031738CD115924396A8FC254C2AA9540` | 已批准 | 西湖中心；木栈道、亭廊、树列与湖岸关系通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_chengdian_auditorium_commercial_street/concept_001/concept.png` · `E9A348D0F759C7057DAF717ABA7495D635C51DB67E8EE7E3CCC5C85977A9A646` | 已批准 | 成电会堂+商业街；会堂主量体与右后商业街双主体关系通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_yinhua_halal_cafeterias/concept_001/concept.png` · `1C0ED5D24E680B93D623EA29B6F3F03488C1D19DA524C3788D3B6681B45EA671` | 已批准 | 银桦食堂+清真食堂；左侧直线体块与右侧弧形门厅通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_basic_laboratory_building/concept_001/concept.png` · `4D006B4E732211A1BBE5E4C42ED6EFF9EE69E0ED2CE4F6DF12A34F4565033C91` | 已批准 | 基础实验大楼；右侧实验楼、玻璃中轴及左侧草地小桥通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_west_lake_entrance/concept_001/concept.png` · `A7B3AF56903EA047EEDCF7C4A271FD4EADCE32A4FB684D72707514DF1410BC7B` | 已批准 | 西湖入口；前广场、湖面与右侧假山喷泉通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_sports_field/concept_001/concept.png` · `7C09249556773ED8DDA0C390E14B3CDDABE274BCE3958CDE18AC4D0E67688A2E` | 已批准 | 操场；球场尺度、球门、树列与远处拱形看台通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 概念 | `m1_library_front/concept_001/concept.png` · `9A1149B2E7071D13AC43F0BC6452085AA23F9C97E76EBF04DB5908C2D09D2C1C` | 已批准 | 图书馆正面；旗帜与旗杆移除、正立面对称、玻璃中轴与前广场通过概念验收。 | 2026-09-21，负责人确认本批地点概念验收通过 |
| 资产 | 十二处 `asset_daily_001`；对应 `assets/art/backgrounds/m1_campus_locations/*/daily.png` | 已批准并提升 | 完全复用已批准概念像素，不重绘；候选与正式文件 SHA-256 逐项一致。仅为日常态正式资产，尚未接入。 | 2026-09-21，负责人要求“将这12张都提升为资产” |
| 资产 | 十二处异常态 `asset_anomaly_001` | 制作中，待评审 | 以对应日常图保持构图与地点身份，加入差异化数字空间异常；图书馆正面使用更高异常强度。 | 2026-09-21，负责人要求制作对应异常图资产 |
| 接入效果 | 未接入 | 不适用 | 正式资产批准并提升后才接入 Godot。 | 待负责人决定 |

## 验证与结果

- 本任务验收条件：用户参考副本与概念候选均可追溯；对象 Manifest 能发现实际文件；南门 `concept_003`、两个品学楼 `concept_001` 与本轮九处实景 `concept_001` 均为 `selected + approved`；旧步道与篮球场仍为 `unselected + pending`；所有对象集成状态保持 `not_integrated`；未获得身份资料的地点不被虚构为已确认现实地点。
- 技术检查结果：PowerShell 7 使用 `System.Drawing.Image` 核对南门 `concept_003`、步道、球场、两个品学楼地点及本轮九处实景候选均为 1672 × 941、24bpp RGB、不透明；九张新增候选均经 `view_image` 实际查看与通用图片质量闸门检查通过。概念无可见全景控件、浏览器 chrome、按钮、热点图标、水印、学校 logo 或可读招牌；图书馆正面的旗帜、旗杆、底座和阴影均已移除，玻璃中轴、天空与前广场连续。本轮 `git diff --check` 通过，资源台 33 项测试通过。
- Manifest 回写：南门 `concept_003`、两个品学楼 `concept_001` 与本轮九处实景 `concept_001` 共十二个具体版本均登记为 `selected + approved`，批准证据指向本任务与 2026-09-21 负责人确认；旧步道与篮球场不在本次批准范围，继续保持 `unselected + pending`。不填写正式生效文件，全部对象集成均为 `not_integrated`。
- 一致性检查：十二张日常正式资产与批准概念逐项 SHA-256 一致；正式目录只保存运行 PNG，概念、参考图与 generation.md 继续留在 `design/concepts/`。当前没有 Godot 引用或生效文件。
- 资源目录扫描：`AssetCatalog.scan()` 通过；全局 26 个对象、263 个文件，缺失 0、哈希不一致 0；南门、两个品学楼地点与本轮九处实景共十二个具体版本均为 `matched + selected + approved`，运行时地点绑定仍为 `pending_runtime_location_binding`，集成均为 `not_integrated`；旧步道与篮球场仍为 `matched + unselected + pending`。
- 适用的布局／动画验证结果：本轮为静态概念，不执行 Godot 接入、动画或运行截图；概念原图已在对话展示。
- 实际截图／动作预览证据：南门、步道、球场、两个品学楼候选及本轮学子食堂、学生活动中心、西湖中心、成电会堂+商业街、银桦食堂+清真食堂、基础实验大楼、西湖入口、操场、图书馆正面九张候选原图均已在对话展示；无运行时截图。
- 未解决问题：十二处异常态资产尚待制作与人工评审；旧步道候选仍缺具体路径照片和地图标记；旧篮球场候选仍缺指定场地照片和地图标记；教学走廊仍缺走廊实景；十二处正式日常资产的运行时 ID 映射尚未确认；两个终点仍未获得独立身份资料；用户提供原图的公开／商业再分发许可未单独核验；全部尚未接入 Godot。
- 本地提交：资源台、差异检查与图像检查通过后按项目规则提交；不自动推送远程。
