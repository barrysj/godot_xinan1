# 美术任务：M1 探索 UI 视觉样板

状态：概念草案，未批准。负责人只需审核所示布局并以自然语言给出决定；技术检查不构成批准。

## 目标与范围

- 用途：为 M1 图书馆地点探索建立一张 UI 信息层级样板，保持现有四站路线、四个热点、单个展开详情和终端反馈的语义。
- 对应规范：[工作流](../WORKFLOW.md)、[执行契约](../ART_CONTRACT.md)、[UI 规范](../specs/UI_SPEC.md)、[M1 静态资源清单](../m1-static-assets.md)。
- 已核对实现入口：`scenes/expedition/campaign_board.gd`、`campaign_panel.gd`、`campaign_hub.gd`；复用 `resources/theme/theme-main.tres` 与 `data/visual/{colors,typography,spacing}.json` 的日常层方向。
- 目标 Godot 入口：地点探索页；本轮不修改 Godot 场景或运行逻辑。
- 不在本次范围内：真实图书馆环境、建筑背景、照片、人物身份、地图重绘、终端图标家族、三终端状态组件、动画、代码接入。

## 当前版本与方案

- 当前使用版：无；对象 `m1_exploration_ui` 尚未接入。
- 本轮候选：`concept_001`，路径 `design/concepts/m1-exploration-ui/m1_exploration_ui/001/library-exploration-layout.svg`，阶段为概念。
- 推荐方案：左侧保留真实场景安全槽，叠加校园记忆／人物事件／借阅终端／守卫战四个图标热点；右侧只展开选中的借阅终端，按钮为短动作名“查看”。顶部紧凑显示现有四站路线进度。
- 已保留：日常页以浅色、青蓝强调、留白、克制边框为主；热点与按钮分工明确。守卫战使用品红提示主线，黄只用于终端的轻优先级标志。
- 明确限制：候选是手工矢量布局研究，场景框只写“场景资料待补”；不以虚构建筑、校史、地理、人物或照片代替真实资料。正式按钮、文字、边框使用 Godot 原生组件或矢量，不使用整屏烘焙图。
- 技术依据：日常色值 `#EEF4F7`／`#F8FAFB`／`#4AAFD0`，4px 间距基数，Theme 默认 20px；这些是概念方向，不改共享 Token 或 Theme。
- 接入要求：概念获批后，先用现有 `Container`、Theme、锚点与热点交互构建；再按 1920×1080、2560×1440、1920×1200 的实际运行截图单独评审接入效果。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001` · `library-exploration-layout.svg` · `1437759b8ffcdd76a73a03107e4d34abac2c35183d7ebe0024aadcdf5f2ff9b1` | 待评审 | | |
| 资产 | 未开始 | 待评审 | | |
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 本任务验收条件：实际文件可解析；资源台能发现该对象与概念版本；状态为 `unselected + pending + not_integrated`；无 Godot 引用或运行画面变更。
- 验证日期／基线：2026-09-16；本地 `main` 基线 `10dfbcd`。
- 技术检查结果及复现命令：PowerShell 的 XML 解析确认 SVG 根节点、1600 × 900 与 viewBox；`Get-FileHash -Algorithm SHA256` 得到表中哈希；`AssetCatalog('.').scan('assets/art/asset_manifest.yaml')` 返回 `errors=[]`、UI 分类、候选文件 `matched`、`warnings=[]`、`integration=not_integrated`；`py -3 -m unittest discover -s tools/art/asset_manager/tests -v` 为 33 项通过；`py -3 -m py_compile tools/art/asset_manager/catalog.py tools/art/asset_manager/server.py` 与 `git diff --check` 通过。
- Manifest 回写：`m1_exploration_ui/concept_001`；不写批准依据、正式文件、预览 GIF、Godot 预览或 bindings。
- 一致性检查：概念阶段没有 selected-to-effective binding，故只校验候选文件存在与格式；不得由校验动作生成接入状态。
- 实际截图／动作预览证据：矢量原图路径见当前版本；没有运行截图，因为本轮未改 Godot 画面。内置浏览器安全策略拒绝本地 SVG 导航，未绕过该限制生成伪截图。
- 未解决问题：需要负责人审核此布局；图书馆原照、来源／许可、地点身份和短回忆仍缺，故不得开始场景概念、正式资产或接入。
- 本地提交：本档案、候选与 Manifest 已在同一独立本地提交中完成；远程未推送。
