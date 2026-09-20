# 美术任务：M1 主菜单视觉样板

状态：`concept_005` 已生成，当前为 `unselected + pending + not_integrated`，等待负责人进行**概念阶段**人工评审。生成成功、技术检查和本地提交均不代表标题方向、正式资产或接入效果已批准。

## 目标与范围

- 用途、数量与本次要求：建立一组由真实校园参考图引导的主菜单 hero 概念候选，分别验证图书馆、品学楼、秋天银杏主楼三种身份主题与原生导航区之间的关系；本轮只制作三个小批候选，不批量生产标题家族、正式背景家族或按钮资产。
- 对应规范、已有身份参考：`docs/art/STYLE_BIBLE.md`、`docs/art/ART_CONTRACT.md`、`docs/art/WORKFLOW.md`、`docs/art/specs/UI_SPEC.md`、`docs/art/specs/ENVIRONMENT_SPEC.md`、`data/visual/colors.json`、`data/visual/typography.json`、`data/visual/spacing.json`。
- 已批准连续性参考：M1 图书馆日常／异常环境（`m1_library_environment`）与三色记忆终端家族（`m1_memory_artifact`）仅用于配色、光影和数字层级协调，不修改它们、不把它们烘焙进本候选。
- 目标 Godot 场景与现状：`scenes/menu/menu.tscn`；当前仍是 Godot 模板观感，标题为 `Godot Game Template`，使用 Open Sans Bold；本轮不改场景、不改 Theme、不改运行时代码。
- 不在本次范围内的内容：不实现主菜单、不制作正式可接入背景、不制作可发布标题字标、不修改 `scenes/menu/menu.tscn`、不替换字体、不加入新按钮或交互、不虚构真实校园建筑、不生成动画资产。

## 当前版本与方案

- 当前使用版：无；项目主菜单仍使用模板实现。本任务没有获得接入授权，保持 `not_integrated`。
- 当前候选：Manifest 对象 `m1_main_menu_visual`，版本 `concept_005`，阶段 `concept`，文件 `design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png`；这是针对 `concept_004` 的大门中列与道路中轴定向修订。
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

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `design/concepts/m1-main-menu/m1_main_menu_visual/001/hero.png`；`78356ed97ea3f0568d0bb452bb18067285fb98cb88a4b7fcc0f9656680fe5090` | 待评审 | | 待负责人决定 |
| 概念 | `concept_002`：`library.png`（`9c5084963c20c93fea30edc9fbda1b3c4a591b83ec4b7a9cb3bb39254bb01842`）、`pinxue-building.png`（`8d71c520dd505ab3722504db03213444fc00be7f89ba6f894012bee220e0e3a4`）、`ginkgo-main-building.png`（`42608ccf87bd9cfc17323d37186fab55b7b6998fbf507912c98774b5e14bd444`） | 待评审 | 先选择主题方向，再进入正式资产阶段 | 待负责人决定 |
| 概念 | `concept_003`：`ginkgo-main-building.png`；`fefa7bcfaa5fbb59a4981469b953924cad29d0704bb208aaf1229b6ae5335dce` | 待评审 | 已按意见去除旗帜与左侧岔路，等待确认修订结果 | 待负责人决定 |
| 概念 | `concept_004`：`ginkgo-main-building.png`；`8615e1cfb198b8e6acbbd25ffe96698bb10582cb1d3ae51321f3bfbcf96ca342` | 待评审 | 已按意见将主楼向左微移并校正道路中轴，等待确认修订结果 | 待负责人决定 |
| 概念 | `concept_005`：`ginkgo-main-building.png`；`01587c6106e9b6ab7b5667fb9cc891e01481e460095037ee1377558e8212378c` | 待评审 | 已按意见以大门中列为硬基准重新对齐道路中轴，等待确认修订结果 | 待负责人决定 |
| 资产 | 尚未制作 | 待评审 | 需先通过概念阶段 | |
| 接入效果 | 尚未制作 | 待评审 | 需先获得明确接入授权 | |

## 验证与结果

- 本任务验收条件：每张概念需在几秒内读出对应的校园地标主题；至少一侧或下方能容纳原生导航，标题区能保持低干扰；不能出现可读伪文字、烘焙菜单或不可编辑的正式标题；概念状态必须保持 `unselected + pending + not_integrated`。
- 技术检查结果：`PASS_WITH_NOTES`。`concept_002` 至 `concept_005` 的实际文件均可读取，PNG，1672×941，`Format24bppRgb`，非透明；最新银杏主楼修订为 `2,553,433` bytes，SHA-256 为 `01587c6106e9b6ab7b5667fb9cc891e01481e460095037ee1377558e8212378c`。没有发现水印、签名或菜单文字。完整提示词、来源和质量闸门记录见各版本目录的 `generation.md`。
- 复现检查命令：
  - `Add-Type -AssemblyName System.Drawing; Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | ForEach-Object { $img = [System.Drawing.Image]::FromFile($_.FullName); try { \"$($_.Name) $($img.Width)x$($img.Height) $($img.PixelFormat)\" } finally { $img.Dispose() } }`
  - `Get-ChildItem -LiteralPath 'design/concepts/m1-main-menu/m1_main_menu_visual/002' -Filter '*.png' | Get-FileHash -Algorithm SHA256`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png'`
  - `Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Resolve-Path 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png')); try { $img.Width; $img.Height; $img.PixelFormat } finally { $img.Dispose() }`
  - `Get-FileHash -Algorithm SHA256 'design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png'`
- Manifest 回写：`assets/art/manifests/m1_main_menu_visual.yaml` 新增 `concept_005`；`concept_001` 至 `concept_005` 均保持 `selection: unselected`、`approval: pending`；`integration.status: not_integrated`。
- 一致性检查：Manifest 的 root 与文件均指向实际存在的概念副本；未复制到 `assets/art/`，未增加 Godot 引用，未修改共享 Token、Theme、实现总览或 Roadmap。
- 实际截图／展示证据：本轮在对话展示了 `concept_005/ginkgo-main-building.png` 修订图；它是概念阶段候选，不是 Godot 运行截图，也不作为接入验收证据。由于本轮没有修改 Godot 场景、Theme 或运行时代码，未执行新的运行时接入截图。
- 资源台验证：`py -3 -m unittest discover -s tools/art/asset_manager/tests -v`，33 项测试全部通过；覆盖主 Manifest schema、对象发现、注册文件存在性及 `unselected + not_integrated` 不提升规则。直接首次运行 `run-server.ps1 -Port 8876 -NoOpen` 在仓库既有 Godot 导入阶段失败，日志显示缺失 Open Sans 导入缓存、编辑器设置写入限制及既有 `settings_menu.gd` 解析报错；本轮未修改工具链、Theme 或运行时代码。
- 专业边界与已知问题：真实建筑参考提升了校园识别度，但也带来构图裁切、建筑连续性和照片来源授权的后续风险；正式资产阶段应由负责人先选定主题，再简化细节、单独制作标题标识，并以实际菜单安全区和三种桌面分辨率重新验证。概念批准前不做这些下游工作。
- 本地提交：概念候选、来源记录、任务档案与 Manifest 将在本分支完成验证后提交；不推送远程。
