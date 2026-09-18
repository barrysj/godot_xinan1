# 美术任务：M1 校园修复站与日常 UI 视觉样板

状态：草案，未批准。首轮只提交一个基地首页 hero 概念候选；概念、正式资产、Godot 接入效果均需分别人工评审。

## 目标与范围

- 用途、数量与本次要求：为局外“校园修复站”建立一套可反复使用的日常 UI 视觉语言；首轮只做 1 张非地点绑定的首页 hero 概念样板。
- 对应规范、已有身份参考：[WORKFLOW](../WORKFLOW.md)、[ART_CONTRACT](../ART_CONTRACT.md)、[STYLE_BIBLE](../STYLE_BIBLE.md)、[UI_SPEC](../specs/UI_SPEC.md)、`data/visual/{colors,typography,spacing,animation}.json`；参考已批准的 M1 探索 UI 与 M1 记忆载体，仅继承其信息层级和局部强调，不复制异常层强度。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/meta_hub.gd` 的基地页、`campaign_panel.gd` 的首页／记录入口，以及现有 `campus_map.gd`、`location_dispatch_panel.gd`、`visual_team_panel.gd`。本轮不修改 Godot。
- 不在本次范围内：真实校园地点背景、现实人物或学生身份、整套组件生产、正式资产提升、队伍头像家族、派遣地图重绘、共享 Theme／Token 重构、运行时代码与接入截图。

## 当前版本与方案

- 当前使用版：无；Manifest 对象 `m1_campus_hub_ui` 尚未接入。
- 本轮候选：`concept_001`，`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/001/`，概念阶段，hero 文件为 `campus_hub_hero_concept_001.png`。
- 本轮改动、需保留的部分与当前待决事项：保留明亮日常层、中央修复核、左侧队伍／探索模块、右侧成长／派遣／回忆／资源模块、顶部设置入口和细青色连接线；待负责人确认整体构图、日常与异常的同源关系、中央焦点重量及模块拆分方向。
- 复用的批准方向／资产及原评审记录：M1 探索 UI 的“图标／悬停简要信息／点击详情”渐进展示原则，以及 M1 记忆载体 011 的局部青品红数字强调；不把它们的异常背景、图标或终端位图直接拼进本概念。
- 技术依据：日常 Token 使用 `colors.json` 的 `daily`，版式以 4px 间距倍数和 `typography.json` 的标题／正文／等宽角色为后续原生实现依据；动画只沿用 `animation.json` 的 `120–220ms` 稳定交互范围。概念图本身不建立新的 Token，也不建立 selected-to-effective binding。
- 接入要求：概念通过后，先以原生 Container／Anchor、现有 Theme 和可拆分矢量／NinePatch 组件实现；文字、数值、按钮、焦点和设置入口必须由 Godot 原生组件承担。运行评审覆盖 1920×1080、2560×1440、1920×1200，至少检查首页、队伍、成长、派遣、回忆／资源状态与设置入口的安全区和可读性。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001` · `campus_hub_hero_concept_001.png` · `E5998CA4474B3F34CE88731A9B1B951A280781EC6CE7902ED89902A45DB59569` | 待评审 | | 首次展示，2026-09-19 |
| 资产 | 未开始 | 待评审 | | |
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 本任务验收条件：实际概念文件可解码；资源 Manifest 能发现该对象与概念版本；状态保持 `unselected + pending + not_integrated`；没有 Godot 引用或运行画面变更；概念原图在对话中展示给负责人审核。
- 技术检查结果及必要复现命令：PowerShell 7 `System.Drawing.Image` 实测 `1672×941`、`Format24bppRgb`、文件可解码；`Get-FileHash -Algorithm SHA256` 得到上方哈希；`git diff --check` 待提交前执行。通用 `asset_report.py` 因环境未安装 Pillow，未冒充通过，已在 generation.md 记录边界。
- Manifest 回写：`assets/art/manifests/m1_campus_hub_ui.yaml` 的 `concept_001`；主索引只新增 `m1_campus_hub_ui`。未写批准依据、正式文件、Godot 预览或 integration binding。
- 一致性检查：候选图是独立不透明概念板，不作为运行时纹理；正式实现必须拆成原生布局、矢量／NinePatch 和可替换图标。当前无 Godot 引用，integration 为 `not_integrated`。
- 适用的布局／动画验证结果：概念阶段不启动游戏；无运行画面变化。后续接入阶段按三种目标分辨率和现有 UI 规范复核。
- 实际截图／动作预览证据：概念原图即 `design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/001/campus_hub_hero_concept_001.png`，已在对话中展示；无 Godot 运行截图。
- 未解决问题：需要负责人先决定概念方向；还没有获准生产任何单独面板、图标、终端进度条或队伍头像。若后续方案要求真实校园场景或现实人物，必须先取得对应素材，不能用虚构图替代。
- 本地提交：待概念候选与文档验证后提交到 `art/m1-campus-hub-ui`；远程不推送。

