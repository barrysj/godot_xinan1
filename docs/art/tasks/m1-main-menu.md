# 美术任务：M1 主菜单视觉样板

状态：`asset_001` 的六张主菜单背景已获用户批准并提升为正式资产；异常与正常主题已切换到稳定 `assets/art/backgrounds/m1_main_menu/` 路径，Godot 图形接入与三种桌面窗口尺寸检查已通过。生成成功、技术检查和本地提交不替代接入效果或发布授权批准。

## 目标与范围

- 用途、数量与本次要求：建立并提升一组由真实校园参考图引导的主菜单 hero 背景资产，包含图书馆、品学楼、秋天银杏主楼三种身份主题的正常／异常各一张；标题家族和按钮资产不在本任务范围内。
- 对应规范、已有身份参考：`docs/art/STYLE_BIBLE.md`、`docs/art/ART_CONTRACT.md`、`docs/art/WORKFLOW.md`、`docs/art/specs/UI_SPEC.md`、`docs/art/specs/ENVIRONMENT_SPEC.md`、`data/visual/colors.json`、`data/visual/typography.json`、`data/visual/spacing.json`。
- 已批准连续性参考：M1 图书馆日常／异常环境（`m1_library_environment`）与三色记忆终端家族（`m1_memory_artifact`）仅用于配色、光影和数字层级协调，不修改它们、不把它们烘焙进本候选。
- 目标 Godot 场景与现状：`scenes/menu/menu.tscn`；本轮将其从模板背景接到三地点异常／正常主题轮播，标题与短动作按钮继续由 Godot 原生组件承担。
- 不在本次范围内的内容：不制作可发布标题字标、不替换共享 Theme、不加入新玩法交互、不虚构真实校园建筑、不生成动画资产；当前 Godot 接入仍需独立做视觉 QA。

## 当前版本与方案

- 当前正式版：Manifest 对象 `m1_main_menu_visual` 的 `asset_001`，正式文件位于 `assets/art/backgrounds/m1_main_menu/`；异常图使用最终双黑天鹅图书馆与 `concept_006` 的品学楼／银杏主楼，正常图使用 `concept_002` 的图书馆／品学楼与已确认中轴线的 `concept_005` 银杏主楼。
- 当前接入：`menu.gd` 读取正式资产路径；未完成完整终局通关时显示异常轮播，读取现有 `CampusProgress.campaign.restored` 为真后切换到正常轮播。
- 接入验证：`tools/menu_runtime_check.tscn` 以图形模式覆盖异常／正常两种状态、三地点六张背景、8 秒轮播索引及 1920×1080、1920×1200、2560×1440 窗口；六张图均实际渲染成功。
- 历史候选：版本 `concept_001` 保留为抽象校园网络中庭方向；版本 `concept_002` 保留三张小批候选；版本 `concept_003`、`concept_004` 保留此前的去旗帜、去岔路和中轴修订，均为 `unselected + pending`，不因本轮修订自动升级或淘汰。
- 方案名称：**抽象校园网络中庭 / Abstract Campus Node Plaza**。
- 主视觉：以中央圆形网络节点、放射式校园路径和少量通用理工建筑块面表达“校园系统正在被记忆重新连接”；画面明确是虚构抽象构图，不冒充真实校园地图或建筑。
- 标题标识方向：右上区域的青／品红双波形与节点组合，先作为不可读徽记占位；如果概念获批，正式标题需拆成独立可编辑标识或由原生／矢量方案实现，不能把菜单文字烘焙进背景。
- 导航关系：左侧三分之一保持低信息、低亮度，供原生 `开始`、`设置`、`退出` 等短动作按钮垂直排列；按钮文字只在 Godot 中实现，概念图不承诺最终文案。右侧中部保留中央节点焦点，避免导航遮挡核心世界观图形。
- 复用的批准方向／资产及原评审记录：`docs/art/tasks/m1-library-environment.md`、`docs/art/tasks/m1-memory-artifact.md` 及其 Manifest；本候选没有复制或修改其中任何文件。
- 技术依据：主视觉候选为 1672×941、非透明整屏 PNG；色彩沿用 `colors.json` 的 night／evening 角色，标题使用 `typography.json` 的 display 角色，按钮与正文继续使用原生 Theme 和 `spacing.json` 的 4px 倍数。精确接入裁切、字体字重和多分辨率适配待概念批准后另行制定。
- 提前试接入授权：无。

### 概念 002：真实校园主题小批候选

- 图书馆：以用户提供的湖畔白色建筑、树线和倒影为身份锚点；低对比湖面与左侧天空为导航留白，使用日落暖光、青／品红局部反射表达轻量数字层。
- 品学楼：以用户提供的正面中轴、喷泉、广场和两侧大树为身份锚点；蓝调时刻与暖窗光形成迎宾感，喷泉与路径灯承担局部赛博提示，避免把菜单压在建筑中心。
- 秋天银杏主楼：以用户提供的秋季银杏大道、中央道路和主楼正立面为身份锚点；金黄季节色是主导，青色仅落在窗面和路灯，形成最强的季节记忆点。
- 共同约束：三张均为 16:9、无菜单文字／按钮／标题字标／水印的概念底图；真实建筑用于身份参考，不把照片中的偶然人物、天鹅、可读标语或其他非必要细节固化为玩法资产。
- 图像生成与来源记录：见 `design/concepts/m1-main-menu/m1_main_menu_visual/002/generation.md`；用户提供的本地参考图只作为本任务的视觉输入，未据此推断外部授权或可发布许可。

### 概念 003：秋天银杏主楼定向修订

- 修改范围：只去除主楼前中央旗帜、旗杆及相关硬件；只去除左侧前景岔路，将其补为连续的银杏林、绿化带、落叶与路缘。
- 保留范围：主楼几何与位置、正中单一道路轴线、秋季金黄色调、青色路径灯、少量品红提示、天空、光照和 16:9 构图均保持为 `concept_002` 的连续方向。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png`。
- 生成与质量记录：见同目录 `generation.md`。这是新的概念修订候选，不覆盖 `concept_002`，也不代表已批准或已接入。

### 概念 004：秋天银杏主楼中轴线定向修订

- 修改范围：将主楼整体向左微移，使主入口、台阶和现有道路黄线重新落在同一条垂直中轴上；道路、银杏林、路径灯和镜头不随之移动。
- 保留范围：概念 003 已完成的去旗帜、去旗杆、去左侧岔路结果，以及主楼建筑比例、秋季金黄色调和局部赛博光效。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png`。
- 生成与质量记录：见同目录 `generation.md`。这是新的概念修订候选，不覆盖 `concept_003`，也不代表已批准或已接入。

### 概念 005：大门中列与道路中轴对齐修订

- 修改范围：以主楼正中拱门／大门列和前景双黄线为硬基准；保持道路不动，调整主楼整体横向位置，使大门中列精确落在道路中轴线上。
- 纠偏说明：`concept_004` 的主楼左移过多，导致大门中列仍偏离道路；本版改为向右回调，不再以楼顶或整栋建筑外轮廓的视觉中心判断。
- 保留范围：去旗帜、去旗杆、去左侧岔路的结果，以及道路、银杏林、路径灯、天空、季节色和 16:9 镜头。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png`。
- 生成与质量记录：见同目录 `generation.md`。这是新的概念修订候选，不覆盖 `concept_004`，也不代表已批准或已接入。

### 概念 006：三地点异常状态概念与主菜单试接入

- 图书馆：保留湖畔建筑和左侧湖面安全区；异常集中在倒影，加入断裂的记忆镜面、重复窗带、青／品红反射和少量几何碎片。
- 品学楼：保留正面中轴、喷泉、广场和树线；喷泉转为分段数据水弧，广场地砖出现汇向入口的电路线，窗面与路径灯保留少量错误脉冲。
- 秋天银杏主楼：保留金色银杏大道，继续去除旗帜、旗杆和左侧岔路；主楼正中大门列与道路双黄线对齐，异常集中在几何化落叶、重复枝形、青色道路脉冲和品红路径灯。
- 共同约束：三张均为 16:9、无菜单文字／按钮／标题字标／水印；先读出地标，再读出异常；左侧或下方保留原生导航可用区域。
- 试接入规则：`menu.gd` 只读取既有存档，不写入新字段；`campaign.restored == false` 显示异常图，`campaign.restored == true` 显示较正常图；三地点每 8 秒交叉淡入轮播。
- 生成与质量记录：见 `design/concepts/m1-main-menu/m1_main_menu_visual/006/generation.md`。当前属于 `review` 试接入，异常图等待人工概念评审。

### 概念 007：图书馆水面倒影定向修订

- 修改范围：只加强水面倒影的异常程度与颜色变化；加入深蓝、青色、电光蓝、紫色、品红和少量酸黄的分区式记忆颜色，以及错帧、重复窗列、局部倒置、彩色环形波纹和几何倒影碎片。
- 保留范围：图书馆建筑、湖岸、天空、地平线、镜头构图、真实建筑本体和左侧菜单安全区；不改变品学楼与银杏主楼异常图。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/007/library-anomaly.png`。
- 生成与质量记录：见同目录 `generation.md`。`image-quality-check` 结果为 `PASS_WITH_NOTES`，可继续作为主菜单 review 图使用。

### 概念 008：图书馆异常数字黑天鹅修订

- 修改范围：在 `concept_007` 的异常湖面上加入一只自然贴水、可识别的数字化黑天鹅；保留黑色羽体、细长弯颈和羽片层次，加入青／品红边缘分裂、几何化羽片与对应错位倒影。
- 保留范围：图书馆建筑、湖岸、彩色异常倒影、天空、镜头构图和左侧菜单安全区；不增加第二只天鹅，不改变品学楼与银杏主楼异常图。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/008/library-anomaly-digital-swan.png`。
- 生成与质量记录：见同目录 `generation.md`。`image-quality-check` 结果为 `PASS_WITH_NOTES`；当前是背景概念内的一体化黑天鹅，不是独立透明角色资产。

### 概念 009：图书馆异常远景双黑天鹅修订

- 修改范围：移除 `concept_008` 的前景大黑天鹅，改为两只约为上一版 20%～25% 大小的远景湖面黑天鹅，分别位于中远景水面左右两侧；保留小型尾波和细小错位倒影。
- 保留范围：图书馆建筑、湖岸、彩色异常倒影、天空、镜头构图和左侧菜单安全区；严格不增加第三只黑天鹅，不改变品学楼与银杏主楼异常图。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/009/library-anomaly-two-digital-swans.png`。
- 生成与质量记录：见同目录 `generation.md`。`image-quality-check` 结果为 `PASS_WITH_NOTES`；当前仍是一体化背景概念，不是独立透明角色资产。

### 概念 010：双黑天鹅动作差异初版候选

- 修改范围：尝试让左鸟低颈向左游、右鸟抬颈展翼；保持两只远景尺度、位置和水面异常不变。
- 复核结论：左鸟朝向清楚，右鸟的抬翼轮廓仍可能被误读为第二个颈部，因此保留为中间候选，不作为主菜单 active 版本。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/010/library-anomaly-two-digital-swans-asymmetric.png`。

### 概念 011：双黑天鹅明确动作与朝向修订

- 修改范围：左鸟明确向左低颈滑行；右鸟明确向右抬颈，头部和喙朝画面右侧，并用清晰羽扇表达轻微展翼；两只水面倒影和尾波保持不同方向。
- 保留范围：两只远景尺度、原位置、图书馆建筑、湖岸、彩色异常倒影、天空、镜头构图和左侧菜单安全区。
- 当前文件：`design/concepts/m1-main-menu/m1_main_menu_visual/011/library-anomaly-two-digital-swans-clear-directions.png`。
- 生成与质量记录：见同目录 `generation.md`。`image-quality-check` 结果为 `PASS_WITH_NOTES`，当前仍是一体化背景概念，不是独立透明角色资产。

### 正式资产 `asset_001`：六张主菜单背景

- 正常主题：图书馆、品学楼、已确认大门中列与道路中轴对齐的秋天银杏主楼。
- 异常主题：水面色彩异常与远景双数字黑天鹅图书馆、数据化喷泉品学楼、几何化银杏大道主楼。
- 正式路径：`assets/art/backgrounds/m1_main_menu/normal/` 与 `assets/art/backgrounds/m1_main_menu/anomaly/`。
- 提升记录：见 `assets/art/backgrounds/m1_main_menu/generation.md`；六张源文件均为 1672×941、24bpp RGB、非透明 PNG，正式包与来源概念逐文件哈希一致。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png`；`78356ed97ea3f0568d0bb452bb18067285fb98cb88a4b7fcc0f9656680fe5090` | 待评审 | | 待负责人决定 |
| 概念 | `concept_002`：`library.png`（`9c5084963c20c93fea30edc9fbda1b3c4a591b83ec4b7a9cb3bb39254bb01842`）、`pinxue-building.png`（`8d71c520dd505ab3722504db03213444fc00be7f89ba6f894012bee220e0e3a4`）、`ginkgo-main-building.png`（`42608ccf87bd9cfc17323d37186fab55b7b6998fbf507912c98774b5e14bd444`） | 待评审 | 先选择主题方向，再进入正式资产阶段 | 待负责人决定 |
| 概念 | `concept_003`：`ginkgo-main-building.png`；`fefa7bcfaa5fbb59a4981469b953924cad29d0704bb208aaf1229b6ae5335dce` | 待评审 | 已按意见去除旗帜与左侧岔路，等待确认修订结果 | 待负责人决定 |
| 概念 | `concept_004`：`ginkgo-main-building.png`；`8615e1cfb198b8e6acbbd25ffe96698bb10582cb1d3ae51321f3bfbcf96ca342` | 待评审 | 已按意见将主楼向左微移并校正道路中轴，等待确认修订结果 | 待负责人决定 |
| 概念 | `concept_005`：`ginkgo-main-building.png`；`01587c6106e9b6ab7b5667fb9cc891e01481e460095037ee1377558e8212378c` | 已确认 | 用户确认本版大门中列与道路中轴对齐结果可用；仅确认正常状态概念，不等同于正式发布资产批准 | 2026-09-20 用户确认 |
| 概念 | `concept_006`：`library-anomaly.png`（`4abfad9fe4b21f3ff71ee3c1545cd08330b8c106390bd533a5eb701665e19697`）、`pinxue-building-anomaly.png`（`95fd5e2380002f022b728cbfbb6d2c40797beb625b5ae0a9ac4f653428bb9b86`）、`ginkgo-main-building-anomaly.png`（`49912bda0715fbeb212c8079c1f26e72d3ccc0cc76959b117dbad6a1607f5292`） | 待评审 | 三地点异常状态概念；用户已授权主菜单 review 试接入，等待异常视觉确认 | 2026-09-20 用户请求 |
| 概念 | `concept_007`：`library-anomaly.png`；`f0100e195b71f4cf84cb1226b4bb97215b3b92675432246c7e11b5678c3a7b3f` | 待评审 | 按用户意见加强水面倒影异常与颜色变化；建筑和左侧菜单安全区保持不变 | 2026-09-20 用户请求 |
| 概念 | `concept_008`：`library-anomaly-digital-swan.png`；`f264272cf974e4f970d595e6d63cab7c87ef2fb82ee9431573f1830d9142eb49` | 待评审 | 按用户意见加入一只数字化黑天鹅及对应异常倒影；保持自然贴水关系与左侧安全区 | 2026-09-20 用户请求 |
| 概念 | `concept_009`：`library-anomaly-two-digital-swans.png`；`3e76911600f46b58b60041d52f9cfacf070734edcb6b285768fb8018ce2713b1` | 待评审 | 按用户意见缩小黑天鹅并改为两只远景湖面黑天鹅；移除前景大鸟 | 2026-09-20 用户请求 |
| 概念 | `concept_010`：`library-anomaly-two-digital-swans-asymmetric.png`；`cf97bece99d789b6ab0413fb1476bd332ceb3e6a8380cc2a4beeb8af72627250` | 待评审 | 两只动作差异初版；右鸟抬翼轮廓仍需复核，保留为中间候选 | 2026-09-21 用户请求 |
| 概念 | `concept_011`：`library-anomaly-two-digital-swans-clear-directions.png`；`26c91dd40488fae87396b59f69bb9cbb9f094d714091c0c238ed636e6a3cf96b` | 待评审 | 左鸟向左低颈游，右鸟向右抬颈并展翼；动作与朝向已明确 | 2026-09-21 用户请求 |
| 资产 | `asset_001`：`assets/art/backgrounds/m1_main_menu/` 六张背景；来源哈希见 `generation.md` | 已批准 | 用户批准六张提升为资产；正式包已登记并替换菜单引用 | 2026-09-21 用户请求 |
| 接入效果 | `scenes/menu/menu.tscn` + `scenes/menu/menu.gd` 正式资产接入 | 待评审 | 已切换到 `assets/art/` 稳定路径；需 Godot 运行截图与多分辨率检查 | 2026-09-21 |

## 验证与结果

- 本任务验收条件：每张背景需在几秒内读出对应的校园地标主题；至少一侧或下方能容纳原生导航，标题区能保持低干扰；不能出现可读伪文字、烘焙菜单或不可编辑的正式标题；正式包的六张文件、Manifest 路径和菜单引用必须一致。
- 技术检查结果：`PASS_WITH_NOTES`。`concept_002` 至 `concept_011` 的实际文件均可读取，PNG，1672×941，`Format24bppRgb`，非透明；异常图没有发现水印、签名或菜单文字，`concept_007` 的倒影异常、`concept_008` 的数字黑天鹅、`concept_009` 的远景双黑天鹅和 `concept_011` 的动作朝向修订均通过 `image-quality-check`，完整提示词、来源和质量闸门记录见各版本目录的 `generation.md`。
- 复现检查命令：
  - `Add-Type -AssemblyName System.Drawing; Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | ForEach-Object { $img = [System.Drawing.Image]::FromFile($_.FullName); try { \"$($_.Name) $($img.Width)x$($img.Height) $($img.PixelFormat)\" } finally { $img.Dispose() } }`
  - `Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | Get-FileHash -Algorithm SHA256`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png'`
- Manifest 回写：`assets/art/manifests/m1_main_menu_visual.yaml` 已登记并选用 `asset_001`；六张正式文件位于 `assets/art/backgrounds/m1_main_menu/`，`integration.active_variant` 与菜单脚本一致。
- 一致性检查：正式包与六个来源概念文件逐文件哈希一致；原概念目录保留，未覆盖或删除历史版本；未修改共享 Token、Theme、实现总览或 Roadmap。
- 实际截图／展示证据：六张概念图已完成质量闸门；正式包接入后仍待可用 Godot 环境完成异常／恢复状态和三种桌面分辨率截图。
- 资源台验证：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`，33 项测试全部通过；覆盖主 Manifest schema、对象发现、注册文件存在性及候选不自动提升规则。当前环境未发现可调用的 Godot 4 可执行文件，因此主菜单运行截图、存档真假状态切换和三种桌面分辨率检查待补；本轮未修改工具链或共享 Theme。
- 专业边界与已知问题：真实建筑参考提升了校园识别度，但也带来构图裁切、建筑连续性和照片来源授权的后续风险；正式资产已批准，但最终菜单安全区、三种桌面分辨率和照片发布边界仍需单独确认。完整终局通关开关使用现有 `campaign.restored`，未新增存档字段。
- 本地提交：概念候选、来源记录、任务档案与 Manifest 将在本分支完成验证后提交；不推送远程。
