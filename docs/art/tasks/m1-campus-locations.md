# 美术任务：M1 校园探索地点环境

状态：南门概念已批准，其他地点概念制作中。任务草案与版本记录遵循[美术工作流](../WORKFLOW.md)；本任务不修改校园大地图、路线、地点 Resource 或运行时代码。

## 目标与范围

- 用途、数量与本次要求：补齐图书馆之外六处探索地点背景家族：校门、步道、球场、走廊、第二终点、第三终点。南门 `gate` 概念已批准为日常视觉基准；后续按现实资料充分度逐项制作其他地点候选。
- 对应规范、已有身份参考：[场景视觉规范](../specs/ENVIRONMENT_SPEC.md)、[视觉方向](../STYLE_BIBLE.md)、[M1 静态资源清单](../m1-static-assets.md)、用户提供的校园平面图与南门／品学楼照片。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/exploration_board.gd` 的地点环境层；本轮不接入。现有 `game/run/campus_region.gd` 只作为地点 ID 与区域逻辑依据。
- 不在本次范围内的内容：区域地图底图、路线与建筑定位、两个终点命名、其他五处背景、照片卡、UI 贴图、人物、战斗代码和运行时代码。

### 现实身份资料审计

| 地点 ID | 当前运行时占位身份 | 当前参考状态 | 后续最低补充 |
| --- | --- | --- | --- |
| `gate` | 校门／旧校门 | 南门照片与校园平面图已提供 | 概念评审；正式制作前确认可使用范围 |
| `walk` | 步道 | 已生成湖畔步道概念候选；平面图有水系、绿地和道路关系，尚无指定步道照片 | 1 张能看出具体路径形态的照片，并在平面图上标注位置；当前候选不代表已确认现实路径 |
| `court` | 球场／当前 Resource 显示“篮球场” | 已生成篮球场概念候选；平面图可见运动场组团，尚无指定球场照片 | 1 张确定场地身份的宽景照片，并标注具体场地；当前候选不代表已确认现实球场 |
| `hall` | 走廊／教学走廊 | 品学楼庭院与中庭照片可作建筑家族参考，尚非走廊身份证明 | 1 张走廊实景照片，并标注所属楼栋／区段 |
| `end_b` | 第二终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |
| `end_c` | 第三终端 | 尚未绑定现实地点；不以品学楼照片擅自命名 | 1 张候选地点照片与身份确认；系统名继续保留 |

用户本轮提供的品学楼单区内部庭院与品学楼组团中庭，先登记为建筑家族辅助参考，不推断其对应 `hall`、`end_b` 或 `end_c`。

## 当前版本与方案

- 当前使用版：无；`m1_campus_locations` 未接入，`integration.status` 为 `not_integrated`。
- 当前概念基准：`concept_003`；[南门远景修订概念](../../design/concepts/m1-campus-locations/m1_campus_locations/003/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_locations/003/generation.md)。原始 `concept_001`、`concept_002` 保留用于回溯与对比。
- 当前已确认部分与后续待决事项：负责人确认南门概念可以，`concept_003` 作为已选概念基准；其远景主楼通过缩小门窗、降低细节和空气透视表达距离，南门近景结构、右上补全及四个热点锚点保持不变。后续地点仍需逐一确认现实身份；概念批准不等同于正式资产批准或 Godot 接入授权。
- 新增地点候选：`m1_campus_walk/concept_001`；[校园湖畔步道概念](../../design/concepts/m1-campus-locations/m1_campus_walk/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_walk/001/generation.md)。该候选使用校园平面图的大关系，不宣称具体现实步道身份，状态为 `unselected + pending`。
- 新增地点候选：`m1_campus_court/concept_001`；[校园篮球场概念](../../design/concepts/m1-campus-locations/m1_campus_court/001/concept.png)，生成记录见同目录 [generation.md](../../design/concepts/m1-campus-locations/m1_campus_court/001/generation.md)。该候选使用校园平面图的运动场组团大关系，不宣称具体现实球场身份，状态为 `unselected + pending`。
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
| 资产 | 未制作 | 不适用 | 概念批准后才制作正式背景。 | 待负责人决定 |
| 接入效果 | 未接入 | 不适用 | 正式资产批准并提升后才接入 Godot。 | 待负责人决定 |

## 验证与结果

- 本任务验收条件：用户参考副本与概念候选均可追溯；对象 Manifest 能发现实际文件；南门 `concept_003` 为 `selected + approved`，后续地点候选默认 `unselected + pending`；集成状态为 `not_integrated`；未获得身份资料的地点不被虚构为已确认现实地点。
- 技术检查结果：PowerShell 7 使用 `System.Drawing.Image` 核对南门 `concept_003`、步道 `m1_campus_walk/concept_001` 与球场 `m1_campus_court/concept_001` 均为 1672 × 941、RGB、不透明；`view_image` 实际查看通过；概念无可见地图控件、浏览器 chrome、按钮、热点图标、水印或学校 logo；步道与球场质量闸门均为 `PASS_WITH_NOTES`，分别提示需人工确认现实路径／球场身份；本轮 `git diff --check` 通过，资源台 33 项测试通过。
- Manifest 回写：主 Manifest 登记 `m1_campus_locations`、`m1_campus_walk` 与 `m1_campus_court`；南门对象保留三版概念且仅 `concept_003` 为 `selected + approved`，步道与球场对象各追加 `concept_001` 为 `unselected + pending`；不填写正式生效文件，三个对象集成均为 `not_integrated`。
- 一致性检查：当前没有正式资产、Godot 引用或生效文件；概念文件与 generation.md 位于同一候选根目录，参考原图位于任务 references 目录，不进入正式资产路径。
- 资源目录扫描：`AssetCatalog.scan()` 通过；全局 15 个对象、241 个文件，缺失 0、哈希不一致 0；步道与球场候选均为 `matched + unselected + pending`，南门 `concept_003` 保持 `matched + selected + approved`，三个对象集成均为 `not_integrated`。
- 适用的布局／动画验证结果：本轮为静态概念，不执行 Godot 接入、动画或运行截图；概念原图已在对话展示。
- 实际截图／动作预览证据：南门远景修订概念 `003/concept.png`、步道候选 `m1_campus_walk/001/concept.png` 与球场候选 `m1_campus_court/001/concept.png` 已展示；历史南门 `001/002` 保留；无运行时截图。
- 未解决问题：步道候选仍缺具体路径照片和地图标记；球场候选仍缺指定场地照片和地图标记；走廊仍缺足够的现实取景证据；两个终点尚未获得身份确认；用户提供原图的公开／商业再分发许可未单独核验；南门仅完成概念批准，尚未制作正式资产或接入 Godot。
- 本地提交：待资源台与差异检查通过后提交；不自动推送远程。
