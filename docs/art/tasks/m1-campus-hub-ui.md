# 美术任务：M1 校园修复站与日常 UI 视觉样板

状态：草案，未批准。首轮只提交一个基地首页 hero 概念候选；概念、正式资产、Godot 接入效果均需分别人工评审。

## 目标与范围

- 用途、数量与本次要求：为局外“校园修复站”建立一套可反复使用的日常 UI 视觉语言；已有 1 张非地点绑定的首页 hero 概念样板，本轮补齐 10 枚有明确界面位置的功能图标。
- 对应规范、已有身份参考：[WORKFLOW](../WORKFLOW.md)、[ART_CONTRACT](../ART_CONTRACT.md)、[STYLE_BIBLE](../STYLE_BIBLE.md)、[UI_SPEC](../specs/UI_SPEC.md)、`data/visual/{colors,typography,spacing,animation}.json`；参考已批准的 M1 探索 UI 与 M1 记忆载体，仅继承其信息层级和局部强调，不复制异常层强度。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/meta_hub.gd` 的基地页、`campaign_panel.gd` 的首页／记录入口，以及现有 `campus_map.gd`、`location_dispatch_panel.gd`、`visual_team_panel.gd`。本轮不修改 Godot。
- 不在本次范围内：真实校园地点背景、现实人物或学生身份、面板／按钮重制、队伍头像家族、派遣地图重绘、共享 Theme／Token 重构、运行时代码与接入截图。

## 当前版本与方案

- 当前使用版：无；Manifest 对象 `m1_campus_hub_ui` 尚未接入。
- 本轮概念基础：`concept_003`，`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/003/`，概念阶段，hero 文件为 `campus_hub_hero_concept_003.png`；`concept_001`、`concept_002` 保留为历史对照。负责人已明确要求开始生成资产，因此保留正式资产候选 `asset_004`，并根据新的徽章参考方向新增 `asset_005`；两者都不等同于概念批准或正式资产批准。
- 当前选定资产种子：`asset_007`，`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/asset_007/`，文件为 `campus_hub_memory_terminal_orb_asset_007.png`；用途为首页核心终端、终端进度状态和结算状态复用。负责人于 2026-09-20 同意继续生成其他素材，007 作为家族视觉种子；仍未授权 Godot 接入。`asset_005` 保留为徽章方向对照，`asset_004` 保留为更早的回退候选。
- 本轮改动、需保留的部分与当前待决事项：新增 `asset_011` 功能图标候选包，包括学习、队伍、成长、派遣、图鉴、资源、回忆、设置、消息、通知。图标均为无背景 SVG，卡片、悬停、禁用、选中和数字角标留给 Godot 原生控件；008–010 保留为历史待评审候选，但不属于当前首页最小接入集，不作为本轮图标包内容。
- 复用的批准方向／资产及原评审记录：M1 探索 UI 的“图标／悬停简要信息／点击详情”渐进展示原则，以及 M1 记忆载体 011 的局部青品红数字强调；不把它们的异常背景、图标或终端位图直接拼进本概念。
- 技术依据：日常 Token 使用 `colors.json` 的 `daily`，版式以 4px 间距倍数和 `typography.json` 的标题／正文／等宽角色为后续原生实现依据；动画只沿用 `animation.json` 的 `120–220ms` 稳定交互范围。概念图本身不建立新的 Token，也不建立 selected-to-effective binding。
- 接入要求：概念通过后，先以原生 Container／Anchor、现有 Theme 和可拆分矢量／NinePatch 组件实现；文字、数值、按钮、焦点和设置入口必须由 Godot 原生组件承担。运行评审覆盖 1920×1080、2560×1440、1920×1200，至少检查首页、队伍、成长、派遣、回忆／资源状态与设置入口的安全区和可读性。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001` · `campus_hub_hero_concept_001.png` · `E5998CA4474B3F34CE88731A9B1B951A280781EC6CE7902ED89902A45DB59569` | 待评审 | | 首次展示，2026-09-19 |
| 概念 | `concept_002` · `campus_hub_hero_concept_002.png` · `3AFD7622A5B8B43241022EDAE0C28CA1E379B714E00D28B8D5F69D5FFA0D1694` | 待评审 | 适配已批准探索 UI 的深蓝内芯、切角、青色细边与品红断点；保留浅色日常底 | 根据负责人反馈调整，2026-09-19 |
| 概念 | `concept_003` · `campus_hub_hero_concept_003.png` · `00AB3EECBDB8781059B58CADB1DC0A34B63229B176DC8AFB60F1D3157872142E` | 待评审 | 按质检意见只替换底部前景生活方式道具 | 根据负责人反馈调整，2026-09-19 |
| 资产 | `asset_004` · `campus_hub_repair_nexus_asset_004.png` · `04C62EE793E203D1DC3FB9464810DA555A377B681448AF9DC5BFCB6756447BC3` | 待评审 | 透明 RGBA 核心终端图标；中央高光与 48px 识别度待确认 | 负责人明确要求开始生成资产，2026-09-19 |
| 资产 | `asset_005` · `campus_hub_science_badge_asset_005.png` · `9BDACD2946D7B1B5541752B43A46654703F70C98577C265D8BF2E7D994174668` | 待评审 | 吸收用户参考图的圆环、蓝金轨道和科学徽章结构；不含原图文字、年份或水印 | 根据负责人新主题反馈生成，2026-09-20 |
| 资产 | `asset_007` · `campus_hub_memory_terminal_orb_asset_007.png` · `E8B68895A0B1D1E6A93792B076C82C634D88B195D202B3CDFB7E1F952AE40B45` | 通过，作为家族种子 | 移除水晶与尖角节点，换为记忆终端圆球及玻璃／陶瓷立体材质；允许继续生成同家族素材，尚未授权接入 | 负责人明确回复“可以。继续生成其他素材”，2026-09-20 |
| 资产 | `asset_008` · `campus_hub_calibration_node_asset_008.png` · `5896B8AC4DA86D8DE355D25FF30489BEBF05B7AEBCBD93600917DB697E9D7E62` | 待评审 | 单一圆形校准节点；用于地图、进度环路和状态卡角标 | 基于 007 家族种子生成，2026-09-20 |
| 资产 | `asset_009` · `campus_hub_repair_beacon_asset_009.png` · `081C53A27332695B28578AE836A16C5040710200BB495CB74F2D40B4B335FD21` | 待评审 | 纵向维修信标；用于地图热点、派遣目的地和维修状态 | 基于 007 家族种子生成，2026-09-20 |
| 资产 | `asset_010` · `campus_hub_memory_bay_asset_010.png` · `F1233CBA3C272A6479033A27FE1325DEEC32E2321A4FDC3B49DC16166087F1C8` | 待评审 | 横向记忆舱托架；用于结算卡和修复完成展示 | 基于 007 家族种子生成，2026-09-20 |
| 资产 | `asset_011` · 10 枚功能图标 SVG · 预览 SHA-256 `C80EA9ACE6E61E46EAE305F3776DC9F30EC2EA1446B8A6B8992A27A5A0D6DB85` | 待评审 | 首页与侧栏的学习、队伍、成长、派遣、图鉴、资源、回忆、设置、消息、通知；无背景、无可见文字 | 负责人明确要求“生成一些图标”，2026-09-20 |
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 本任务验收条件：实际概念与资产候选均可解码；10 枚 SVG 均为 `64×64` 透明画布、无可见文字并可组成评审板；资源 Manifest 能发现该对象与所有版本；没有 Godot 引用或运行画面变更；候选预览在对话中展示给负责人审核。
- 技术检查结果及必要复现命令：既有位图候选检查结果保持不变；本轮使用 PowerShell 7 XML 解析检查 `asset_011`，10 枚生产图标与 2 份预览 SVG 全部可解析，生产图标均为 `64×64`、`viewBox="0 0 64 64"` 且不含 `<text>`；Chrome headless 实际渲染 64px 与 32／24px PNG 评审板，缩小后仍可区分主要语义。`py -3 -B -m unittest discover -s tools/art/asset_manager/tests` 共 33 项通过；`git diff --check` 通过。
- Manifest 回写：`assets/art/manifests/m1_campus_hub_ui.yaml` 新增 `asset_011`，登记 10 枚 SVG、PNG 评审板、SVG 评审板源文件和生产记录；状态为 `unselected + pending`，未写 Godot integration binding。
- 一致性检查：候选图是独立不透明概念板，不作为运行时纹理；正式实现必须拆成原生布局、矢量／NinePatch 和可替换图标。当前无 Godot 引用，integration 为 `not_integrated`。
- 适用的布局／动画验证结果：概念阶段不启动游戏；无运行画面变化。后续接入阶段按三种目标分辨率和现有 UI 规范复核。
- 实际截图／动作预览证据：`asset_011/icon_pack_preview.png` 为本轮 64px 静态评审板，`asset_011/icon_pack_small_preview.png` 为 32px／24px 缩放评审板，均已在对话中展示；无 Godot 运行截图。
- 未解决问题：`asset_011` 仍需人工决定是否作为正式图标方向；24–32px 的运行时清晰度、各入口是否需要同色或按语义保留黄／品红强调，需在试接入阶段复核。008–010 不属于当前首页最小接入集。尚未获准生产面板、终端进度条或队伍头像。
- 本地提交：待资产候选与文档验证后提交到 `art/m1-campus-hub-ui`；远程不推送。
