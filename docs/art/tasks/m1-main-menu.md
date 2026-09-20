# 美术任务：M1 主菜单视觉样板

状态：`concept_009` 已生成并获用户要求缩小黑天鹅、改为两只远景湖面黑天鹅；异常图仍为 `unselected + pending`，`concept_005` 的银杏主楼正常概念已获用户确认可用，正式资产与最终视觉 QA 未批准。生成成功、技术检查和本地提交均不代表标题方向、正式资产或发布授权已批准。

## 目标与范围

- 用途、数量与本次要求：建立一组由真实校园参考图引导的主菜单 hero 概念候选，分别验证图书馆、品学楼、秋天银杏主楼三种身份主题与原生导航区之间的关系；在用户最新要求下，补充三张对应的异常状态概念，并试接入主菜单状态切换，不批量生产标题家族或按钮资产。
- 对应规范、已有身份参考：`docs/art/STYLE_BIBLE.md`、`docs/art/ART_CONTRACT.md`、`docs/art/WORKFLOW.md`、`docs/art/specs/UI_SPEC.md`、`docs/art/specs/ENVIRONMENT_SPEC.md`、`data/visual/colors.json`、`data/visual/typography.json`、`data/visual/spacing.json`。
- 已批准连续性参考：M1 图书馆日常／异常环境（`m1_library_environment`）与三色记忆终端家族（`m1_memory_artifact`）仅用于配色、光影和数字层级协调，不修改它们、不把它们烘焙进本候选。
- 目标 Godot 场景与现状：`scenes/menu/menu.tscn`；本轮将其从模板背景接到三地点异常／正常主题轮播，标题与短动作按钮继续由 Godot 原生组件承担。
- 不在本次范围内的内容：不制作正式发布背景、不制作可发布标题字标、不替换共享 Theme、不加入新玩法交互、不虚构真实校园建筑、不生成动画资产；当前接入仅为用户授权的 review 试接入。

## 当前版本与方案

- 当前使用版：`concept_006` 异常三联图加 `concept_009` 图书馆远景双黑天鹅修订作为 review 试接入；未完成完整终局通关时显示异常轮播，读取现有 `CampusProgress.campaign.restored` 为真后切换到 `concept_002`／`concept_005` 的正常轮播。
- 当前候选：Manifest 对象 `m1_main_menu_visual`，版本 `concept_009` 为图书馆异常双黑天鹅定向修订，文件位于 `design/concepts/m1-main-menu/m1_main_menu_visual/009/`；品学楼与秋天银杏主楼继续使用 `concept_006`，三处分别保持地点身份并使用不同记忆失真语言。
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
| 资产 | 尚未制作 | 待评审 | 需先通过概念阶段 | |
| 接入效果 | `scenes/menu/menu.tscn` + `scenes/menu/menu.gd` review 试接入 | 待评审 | 已按用户请求接入异常／正常状态轮播；需 Godot 运行截图与多分辨率检查 | 2026-09-20 用户请求 |

## 验证与结果

- 本任务验收条件：每张概念需在几秒内读出对应的校园地标主题；至少一侧或下方能容纳原生导航，标题区能保持低干扰；不能出现可读伪文字、烘焙菜单或不可编辑的正式标题；未确认的异常概念保持 `unselected + pending`，review 试接入保持独立授权，不等同于正式资产批准。
- 技术检查结果：`PASS_WITH_NOTES`。`concept_002` 至 `concept_009` 的实际文件均可读取，PNG，1672×941，`Format24bppRgb`，非透明；异常图没有发现水印、签名或菜单文字，`concept_007` 的倒影异常、`concept_008` 的数字黑天鹅和 `concept_009` 的远景双黑天鹅均通过 `image-quality-check`，完整提示词、来源和质量闸门记录见各版本目录的 `generation.md`。
- 复现检查命令：
  - `Add-Type -AssemblyName System.Drawing; Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | ForEach-Object { $img = [System.Drawing.Image]::FromFile($_.FullName); try { \"$($_.Name) $($img.Width)x$($img.Height) $($img.PixelFormat)\" } finally { $img.Dispose() } }`
  - `Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | Get-FileHash -Algorithm SHA256`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png'`
- Manifest 回写：`assets/art/manifests/m1_main_menu_visual.yaml` 已登记 `concept_006`；`concept_005` 记录为用户确认的 `selected + approved` 正常概念，`concept_006` 保持 `unselected + pending` 并以 `authorized_active` 进行 review 试接入。
- 一致性检查：Manifest 的 root 与文件均指向实际存在的概念副本；异常概念保留在 `design/concepts/` 并以用户授权的 review 方式试接入，`concept_009` 替换菜单中的图书馆异常图，未升级为正式资产；未修改共享 Token、Theme、实现总览或 Roadmap。
- 实际截图／展示证据：本轮已在对话展示三张 `concept_006` 异常图；它们是概念候选，不等同于正式资产批准。主菜单运行截图仍待可用 Godot 编辑器／运行时重新验证。
- 资源台验证：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`，33 项测试全部通过；覆盖主 Manifest schema、对象发现、注册文件存在性及候选不自动提升规则。当前环境未发现可调用的 Godot 4 可执行文件，因此主菜单运行截图、存档真假状态切换和三种桌面分辨率检查待补；本轮未修改工具链或共享 Theme。
- 专业边界与已知问题：真实建筑参考提升了校园识别度，但也带来构图裁切、建筑连续性和照片来源授权的后续风险；本轮异常概念仍需负责人确认，正式资产阶段应再简化细节、单独制作标题标识，并以实际菜单安全区和三种桌面分辨率重新验证。完整终局通关开关使用现有 `campaign.restored`，未新增存档字段。
- 本地提交：概念候选、来源记录、任务档案与 Manifest 将在本分支完成验证后提交；不推送远程。
