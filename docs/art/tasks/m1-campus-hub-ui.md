# 美术任务：M1 校园修复站与日常 UI 视觉样板

状态：草案，未批准。首轮只提交一个基地首页 hero 概念候选；概念、正式资产、Godot 接入效果均需分别人工评审。

## 目标与范围

- 用途、数量与本次要求：为局外“校园修复站”建立一套可反复使用的日常 UI 视觉语言；首轮只做 1 张非地点绑定的首页 hero 概念样板。
- 对应规范、已有身份参考：[WORKFLOW](../WORKFLOW.md)、[ART_CONTRACT](../ART_CONTRACT.md)、[STYLE_BIBLE](../STYLE_BIBLE.md)、[UI_SPEC](../specs/UI_SPEC.md)、`data/visual/{colors,typography,spacing,animation}.json`；参考已批准的 M1 探索 UI 与 M1 记忆载体，仅继承其信息层级和局部强调，不复制异常层强度。
- 目标 Godot 场景、入口与依赖：未来对应 `scenes/expedition/meta_hub.gd` 的基地页、`campaign_panel.gd` 的首页／记录入口，以及现有 `campus_map.gd`、`location_dispatch_panel.gd`、`visual_team_panel.gd`。本轮不修改 Godot。
- 不在本次范围内：真实校园地点背景、现实人物或学生身份、整套组件生产、正式资产提升、队伍头像家族、派遣地图重绘、共享 Theme／Token 重构、运行时代码与接入截图。

## 当前版本与方案

- 当前使用版：无；Manifest 对象 `m1_campus_hub_ui` 尚未接入。
- 本轮概念基础：`concept_003`，`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/003/`，概念阶段，hero 文件为 `campus_hub_hero_concept_003.png`；`concept_001`、`concept_002` 保留为历史对照。负责人已明确要求开始生成资产，因此新增正式资产候选 `asset_004`，不等同于概念批准或正式资产批准。
- 当前正式资产候选：`asset_004`，`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/asset_004/`，文件为 `campus_hub_repair_nexus_asset_004.png`；用途为首页核心终端、终端进度状态和结算状态复用。状态保持 `unselected + pending + not_integrated`。
- 本轮改动、需保留的部分与当前待决事项：保留 002 已确认的探索 UI 同源表面语言与全部模块关系；依据 image-quality-check 意见移除绿植、猫杯、纸笔和黑色笔记本，换为低对比几何校园图纸、透明校准片和局部开发板。待负责人确认前景是否更符合“校园修复站”，以及是否需要继续降低前景存在感。
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
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 本任务验收条件：实际概念与资产候选均可解码；资源 Manifest 能发现该对象与所有版本；资产状态保持 `unselected + pending + not_integrated`；没有 Godot 引用或运行画面变更；候选原图在对话中展示给负责人审核。
- 技术检查结果及必要复现命令：PowerShell 7 `System.Drawing.Bitmap` 实测 `asset_004` 为 `1254×1254`、`Format32bppArgb`，四角 alpha 为 `0,0,0,0`，中心 alpha 为 `253`，SHA-256 为 `04C62EE793E203D1DC3FB9464810DA555A377B681448AF9DC5BFCB6756447BC3`；`git diff --check` 待提交前执行。通用 `asset_report.py` 因环境未安装 Pillow，未冒充通过，已在对应 generation.md 记录边界。
- Manifest 回写：`assets/art/manifests/m1_campus_hub_ui.yaml` 新增 `asset_004`，主索引不变；未写批准依据、Godot 预览或 integration binding。
- 一致性检查：候选图是独立不透明概念板，不作为运行时纹理；正式实现必须拆成原生布局、矢量／NinePatch 和可替换图标。当前无 Godot 引用，integration 为 `not_integrated`。
- 适用的布局／动画验证结果：概念阶段不启动游戏；无运行画面变化。后续接入阶段按三种目标分辨率和现有 UI 规范复核。
- 实际截图／动作预览证据：概念原图为 `design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/003/campus_hub_hero_concept_003.png`，正式资产候选为 `design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/asset_004/campus_hub_repair_nexus_asset_004.png`，均已在对话中展示；无 Godot 运行截图。
- 未解决问题：`asset_004` 的中央高光是否需要压低、48px 下是否保留外圈细节，需负责人评审后决定；尚未获准批量生产面板、终端进度条或队伍头像。若后续方案要求真实校园场景或现实人物，必须先取得对应素材，不能用虚构图替代。
- 本地提交：待资产候选与文档验证后提交到 `art/m1-campus-hub-ui`；远程不推送。
