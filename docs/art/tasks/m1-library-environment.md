# 美术任务：M1 图书馆静态环境

状态：concept_005 日常三视角概念已获人工批准并选用；005 夜间与异变三视角候选待评审；未制作正式资产、未接入 Godot。下方历轮待审状态为当时记录，以本节最新决定为准。

## 异变状态候选：concept_005_anomaly（2026-09-17）

依据用户“然后生成异变的”的授权，以当前 005 夜间三视角为母版生成同机位异变状态。三图统一采用图书馆记忆索引与数字书目侵入现实的视觉语言：青／品红数据流、网络节点、局部书目碎块、展陈内容失真与受控空间错位；仍保持图书馆建筑、主通道和家具关系可辨。异变是 005 的状态变体，不增加数字版本。

| 文件（005 目录） | SHA-256 | 当前决定 |
| --- | --- | --- |
| `atrium-down-anomaly.png` | `21d59930522a25f57e996ec411b1564655b4724bcc3a30b72aa018ff4ff12b7d` | 异变概念待评审 |
| `window-corridor-anomaly.png` | `c7844a373f17f0f817e2dbec3f059d71247df1ef01e739daf507b9d024529faa` | 异变概念待评审 |
| `shelf-to-atrium-anomaly.png` | `cafa366e37f61857cbd20203b994bd5d39e35e66ae900973a7e3ae2c339855e2` | 异变概念待评审 |

Manifest 以 `concept_005_anomaly` 独立登记 `unselected + pending`，不扩张日常状态批准。三图均为 1672 × 941、RGB、不透明；生成映射、提示词和自检边界见 005 目录 `generation-anomaly.md`。当前只完成概念候选，未制作正式资产或接入 Godot。

## 夜间状态候选：concept_005_night（2026-09-17）

用户补充图书馆还需夜间与异变状态，并授权继续生成。本轮先基于已批准的 005 日常三视角生成同机位夜景，未生成异变状态。三个夜间文件仍属于空间方案 005，以状态后缀区分，不增加 006 等数字版本。

| 文件（005 目录） | SHA-256 | 当前决定 |
| --- | --- | --- |
| `atrium-down-night.png` | `970a9a5a334c59cec8550239266fa8aeaf1a7a9c32517cf9c1c67b0b2daea9ac` | 夜间概念待评审 |
| `window-corridor-night.png` | `a13d0849d2e360d7af0bcfd53dcf0b63902daeaa1cf36f4ba8c5f97e34a6e062` | 夜间概念待评审 |
| `shelf-to-atrium-night.png` | `229aa3b1597c0f1d7519190c51b7a081144ba359d5e7dacbba53033c14f29f74` | 按反馈提亮远处楼层；夜间概念待评审 |

Manifest 以 `concept_005_night` 单独承载 `unselected + pending`，避免把日常状态的既有批准扩张到夜间新图。三图均为 1672 × 941、RGB、不透明；内建 imagegen 的精确提示词与输出映射见 005 目录 `generation-night.md`。夜间仍是现实校园，只改变时间、照明、反射和数字导视强度；异变需在本轮夜景审核后另行生成。

2026-09-17 反馈修订：负责人指出 `shelf-to-atrium-night.png` 的远处楼层偏暗。本轮仅提高中央远处多层环廊的暖色顶灯与局部反射补光，保持夜空、前景书架／短桌曝光及空间结构；修订图继续待评审。

## 概念批准：concept_005（2026-09-17）

负责人在本任务聊天中明确回复“接受这一版”，对应刚展示的 005 三视角及提交 66f4dbc 的实际文件。批准范围为本版日常环境概念，不扩展为正式资产或接入效果批准，也不代表真实建筑测绘精度确认。

| 被评文件（005 目录） | SHA-256 | 人工决定 |
| --- | --- | --- |
| atrium-down.png | 899cf22547c661346acef848640f3a8b7f0cdde54f72bfed398fe8df7d320bca | 概念批准 |
| window-corridor.png | 66acb9fc0eafcc5ea0611d7b0b050afc6d67053d466473c4ddfdab714d74215e | 概念批准 |
| shelf-to-atrium.png | 2ca0eb9bc4c4a1f6f9ad7504cfe1267fbc82773352a58cf56bc4b5384ae35b0c | 概念批准 |

Manifest 回写 selected + approved，approval_evidence 引用本任务；integration 保持 not_integrated。001—004 状态不变。验证日期 2026-09-17、基线 66f4dbc：资源台扫描与三图 SHA-256 核对、git diff --check；本次仅记录批准，不修改图片或运行画面。待统筹：图书馆日常三视角概念已通过，正式资产与 Godot 接入仍未完成。

## 当前修订：concept_005（2026-09-17）

用户要求：图 1 左侧二、三层不直接以楼梯相连，应开敞；图 2 书架右端与栏杆留过道；图 3 每层八角形，远处白色楼板排列规整。

基于 004 同名三图逐项编辑，005 保存 atrium-down.png、window-corridor.png、shelf-to-atrium.png；精确提示词与偏差见 design/concepts/m1-library-environment/m1_library_environment/005/generation.md。实际新图已展示；图 1 连续梯段移除、图 2 过道明显、图 3 楼板转角与柱列对齐。额外高处左梯删减、远景楼梯变化及规则八角形假设仍需审核。

验证日期 2026-09-17、基线 131a38c：AssetCatalog.scan 核对五版本图数 1/4/3/3/3、PNG 可读、零缺失、状态不变；git diff --check。005 未选用、待评审、未接入。颜色与大结构认可沿用前轮反馈，不扩展为细节或正式资产批准。本次不改游戏或其他任务。

## 当前修订：concept_004（2026-09-17）

用户对 003 的反馈原意：“作为概念图还可以，颜色、光比、大结构都不错，但细节把握不佳”。此反馈记录为方向认可及细节修改要求，未推定整套概念批准。

按上轮聊天展示顺序逐图记录：

| 被评对象 | 用户意见 | 本轮处理与状态 |
| --- | --- | --- |
| 图 1：003/atrium-down.png | 左侧楼梯重绘；每个栏杆边短桌；楼层排列整齐 | 编辑为 004/atrium-down.png；楼层与梯段重绘、补桌，远景桌位对应仍待审 |
| 图 2：003/window-corridor.png | 书架旋转 90°，从中庭径向向外 | 编辑为 004/window-corridor.png；方向变化可见，额外书架顶灯待修 |
| 图 3：临时失败输出 exec-599b6570-40f6-42e3-8a8e-1cf08caef48a.png | 舍弃 | 未进入候选或 Manifest，不继续使用 |
| 图 4：003/shelf-to-atrium.png | 保留，短桌紧贴栏杆，与书架间留过道 | 编辑为 004/shelf-to-atrium.png；桌架分离、过道可见，贴合程度待审 |

四个版本是方案修订序列；004 含三个视角，不按视角另起版本。原图、输入与精确提示词见 design/concepts/m1-library-environment/m1_library_environment/004/generation.md。003 保留原文件供比较；所有新图待评审、未选用、未接入。

验证基线 23e0c25，日期 2026-09-17：AssetCatalog.scan 核验 001/002/003/004 图片数 1/4/3/3、文件可读且无缺失，PNG 尺寸和 SHA-256 实测、git diff --check。未改游戏。待统筹：方向获正面反馈但细节审核尚未完成。

## 当前修订：concept_003（2026-09-17）

用户反馈桌架应径向排布；底层中央画展，周边水吧与沙发。已按此生成三个修订视角，统一为 003：atrium-down.png、window-corridor.png、shelf-to-atrium.png，位于 design/concepts/m1-library-environment/m1_library_environment/003/，生成依据及偏差见同目录 generation.md。

本版编号对应布局修订，不对应视角。此前误编号 003—005 已先归回 002（提交 a5e9786）；当前 003 是新的修订包。001 为虚构方案，002 为原实景方案四视角，003 为本次三视角修订；全部未选用、待人工审核、未接入。

当前待决：径向桌架是否准确；画展、水吧与沙发位置是否符合记忆。水吧款式和展览画面为概念推演；window-corridor 的桌架轴向仍不够明确，shelf-to-atrium 残留书架顶灯等额外细节。旧 002 的环向排布被本次用户反馈指出有误，不作为正式资产依据。

验证日期 2026-09-17、基线 a5e9786：资源台登记三个版本、八张图，零缺失与不一致；PNG 读取、哈希和 git diff --check。仅资产候选与任务记录变更。待统筹：尚无任何概念人工批准，不能报图书馆精制完成。

## 多机位补充：concept_002（2026-09-16）

2026-09-17 用户更正：版本代表方案修订，视角不占版本号。原误编号 003/004/005 已合入 002，以 atrium-down/window-corridor/shelf-to-atrium 文件名区分；002/concept.png 为入口正视中庭。归档不改变图片或人工审批。

用户要求更多视角，并提供上层环廊草图：侧楼梯靠内圈；书架在中部，长约六张书桌；走廊两侧为连续长桌，最外层为窗户。相邻座位的隔断占桌面半深，上方有横板并内嵌日光灯管。仅适用于除中庭底层外的楼层。这里记录用户描述，不将概念推测升级为测绘事实。

| 002 内视角 | 机位 | 人工决定 | 自检需关注 |
| --- | --- | --- | --- |
| atrium-down.png | 栏杆俯视中庭 | 待评审 | 底层仍出现部分桌架；层数与下层地面为模型推演 |
| window-corridor.png | 外窗书桌走廊望书架 | 待评审 | 横板与隔断脱开偏高；书架与内外环廊方向待核对 |
| shelf-to-atrium.png | 书架通道望内侧环廊 | 待评审 | 更清楚展示半深隔断与灯板；灯管较外露，长书架比例不能由该机位精确确认 |

三张已分别展示原图，统一保存于 002，各视角附 generation-<视角>.md。版本 unselected + pending，未接入。三机位用于比较空间，不是新增三个游戏场景或获批的连续空间模型。归档校验基线 93aec81；AssetCatalog.scan 核对只有 001/002、002 含四图、零缺失；移动前后 PNG 哈希不变，git diff --check。

## 前轮推荐：concept_002（2026-09-16）

用户已提供正门航拍与入口内固定点四向环视，现实参考阻塞解除。参考原件保存于 `design/concepts/m1-library-environment/references/`；均为用户提供的设计参考，未用于照片卡。下方 001 内容仅保留历史，不再作为当前方案。

- 推荐版本：`m1_library_environment/concept_002`；文件 `design/concepts/m1-library-environment/m1_library_environment/002/concept.png`；生成过程见同目录 `generation.md`。
- 以第二张参考的入口内侧望中庭为机位，保留多层环廊、木栏杆、玻璃采光顶、侧楼梯与挑空。第四张的入口闸机在机位背后，不擅自移入画面；不沿用虚构阅读桌布置。
- 001 保留 `unselected + pending` 作为未批准历史；002 同为 `unselected + pending`，对象保持 `not_integrated`。推荐不代表流程选用或人工批准。
- 待人工审核：建筑辨识度、楼层与楼梯关系、日常配色与赛璐璐程度。002 SHA-256：`81BE939055B23A1B16C6BA0A4189051C270B5438FD9D20AF2A12CB10FC77EA0B`。
- 未解决边界：热点和侧栏需按中庭画面重新排布，现有归一化坐标不能直接视为验收通过；阅读区和借阅设备细部无清晰参考，不补造。异常／恢复仍等日常批准后制作。
- 验证基线：`10dfbcd`；日期 2026-09-16。前轮资源台 33 测试通过；本轮运行 AssetCatalog.scan 核验两版实际文件与 pending/unselected/not_integrated 状态，PNG 头与 SHA-256 核验，`git diff --check`。结果见本次提交与聊天回报。
- 未改运行画面，按工作流仅展示概念原图；本地提交涵盖本任务候选、参考和登记，不包含统筹临时 AGENTS.md 更改。待统筹：概念已具真实参考，尚未取得人工批准，不代表图书馆精制完成。

## 目标与范围

- 用途、数量与本次要求：为 M1 图书馆地点制作一张日常静态环境的推荐概念候选。它服务于现有原生地点示意的未来替换，但本次不修改游戏。
- 对应规范、已有身份参考：[场景规范](../specs/ENVIRONMENT_SPEC.md#8-图书馆)、[视觉方向](../STYLE_BIBLE.md#3-核心视觉支柱)、[M1 静态清单](../m1-static-assets.md)。当前没有真实图书馆原照或环境参考；候选是明确虚构的风格概念，不能冒充真实地点或照片。
- 目标 Godot 场景、入口与依赖：`scenes/expedition/campaign_board.gd` 的图书馆地点示意。当前四热点按位置为左下守卫、左上回忆档案、中右下发明家、右上借阅终端；中央阅读桌与侧边详情覆盖区须保持可读。
- 不在本次范围内的内容：正式背景、Godot 接入、运行截图、人物／守卫、照片内容、异常／恢复衍生状态、动画、其他六地点、两个尚未确定身份的终点。

## 当前版本与方案

- 当前使用版：无；`m1_library_environment` 未接入。
- 本轮候选：`concept_001`，概念阶段；[原图](../../../design/concepts/m1-library-environment/m1_library_environment/001/concept.png)，生成记录见同目录 [generation.md](../../../design/concepts/m1-library-environment/m1_library_environment/001/generation.md)。
- 本轮取舍：白天自然光、学习区、书架和电子借阅共同确立图书馆身份；以低饱和浅色为主，少量青蓝作为数字提示。画面没有 UI 或交互标记，保留热点覆盖空间。
- 复用的批准方向／资产及原评审记录：仅沿用 v0.3 日常校园方向与 `colors.json` 日常层；没有复用可视化环境资产，也没有可继承的图书馆批准记录。
- 技术依据：实际输出 1672 × 941 PNG、非透明；主 Manifest 与对象 Manifest 已登记。`campaign_board.gd` 仍使用原生几何绘制，故没有 selected-to-effective binding。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001/concept.png` · `A9D75DCCB6AD4DD7AA0C522FF08403DA12494CF648A483B17236A3ACB715646A` | 待评审 | 需确认日常机位、空间布局与偏细腻的 2D 表现是否可作为正式资产方向。 | 待负责人决定 |
| 资产 | 未制作 | 不适用 | 概念批准后才制作。 | 待负责人决定 |
| 接入效果 | 未接入 | 不适用 | 正式资产批准后才接入并三尺寸截图。 | 待负责人决定 |

## 验证与结果

- 本任务验收条件：真实候选文件存在、主／对象 Manifest 能发现该对象、概念保持 `unselected + pending`，`integration.status` 为 `not_integrated`。
- 技术检查：`[System.Drawing.Image]::FromFile(...)` 核对 1672 × 941；`Get-FileHash -Algorithm SHA256` 核对表内哈希。资源台目录契约见 `tools/art/asset_manager/README.md`。
- Manifest 回写：`m1_library_environment/concept_001` 已登记实际文件；无 `approval_evidence`、无 Godot 预览、无生效文件或对象关系，避免暗示批准或接入。
- 一致性检查：不适用；没有 active variant 或运行时引用。
- 实际截图／动作预览证据：概念原图已在本次对话展示。未改变运行画面，依工作流不启动游戏或伪造运行截图。
- 未解决问题：缺真实图书馆原照、来源与短回忆；概念尚待人工决定。批准日常样板后，异常／恢复衍生必须同机位再单独审核。
- 本地提交：待 Manifest 校验与 Git 复核通过后填写。
