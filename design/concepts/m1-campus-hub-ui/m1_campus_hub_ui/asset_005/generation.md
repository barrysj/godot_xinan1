# M1 Campus Hub UI · 校园科学徽章核心终端资产 005 生成记录

- 任务：`m1-campus-hub-ui`
- 对象：`m1_campus_hub_ui`
- 生成日期：2026-09-20
- 工具：Codex 内置 `imagegen`，受控参考图编辑。
- 阶段：正式资产候选；`unselected + pending + not_integrated`。
- 资产类型：透明 2D 游戏 UI 图标。
- 编辑基础：`asset_004`；保留校园修复站核心终端用途、中央修复晶核和透明单体交付方式。
- 风格参考：用户提供的 `E:\Pictures\素材\c9fcc3cec3fdfc03924583898a639094a4c27d1e88f4.webp`；仅抽取深蓝圆环、白色留白、蓝／暖金轨道和科学徽章构图。
- 生成输出：`C:\Users\SongJun\.codex\generated_images\01a0b584-0319-7642-a1a4-4f761dc88d88\exec-456817ca-bca4-4acd-8e96-ded9beb9a64a.png`
- 仓库副本：`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/asset_005/campus_hub_science_badge_asset_005.png`
- 外部来源：用户提供的参考图仅用于抽象视觉研究；未将其像素、校名、字母、年份、具体符号或水印带入仓库资产。
- 许可证／归属：参考图的原始权利状态未用于本资产交付；正式发布前仍需按平台当时的生成媒体披露要求复核，并进行人工权利审查。

## 使用范围

- 首页校园修复站核心终端。
- 终端修复进度与状态卡。
- 结算页恢复／修复完成状态。
- 文字、数值、进度条、焦点和按钮由 Godot 原生组件叠加；本图不烘焙任何可读文字或交互状态。

## 风格提取与项目适配

- 深钴蓝分段圆环：承担校园机构身份与稳定的日常底色。
- 白／浅色内圈留白：保留项目“清爽理工校园”的呼吸感，不让徽章变成异常层满屏发光。
- 蓝／暖金双轨：抽象科学轨道与修复路径；暖金只作为稀缺状态强调。
- 中央青色晶核：沿用 `asset_004` 的修复身份，保证与探索 UI 的青色边缘语言相连。
- 少量品红断点：只保留一个诊断提示，不复制参考图的文字或具体校徽符号。

## 完整生成提示词

```text
Create version 005 as a controlled visual redesign of Image 1, a production-ready 2D game UI icon for an original cyber-pop campus exploration game.

Image 1 is the current Campus Repair Nexus asset. Preserve its role, centered transparent single-object delivery, faceted cyan repair crystal, crisp game-icon readability, deep navy structural parts, and restrained digital edge treatment.

Image 2 is only a visual-language reference. Borrow only these abstract properties: a large deep cobalt-blue circular ring, a white or very pale inner breathing space, a central scientific orbital motif, and a restrained navy-plus-warm-amber dual accent. Do not reproduce the reference logo, lettering, school name, year, exact glyphs, watermark, or any identifiable emblem.

Redesign the outer structure of Image 1 into a clean circular campus-science seal silhouette: one deep cobalt segmented ring behind the central repair crystal, with 2 or 3 smooth orbital arcs in navy and muted warm amber crossing around the crystal. Keep the existing cyan crystal as the repair core, but reduce the explosive cyan glow so the daily UI layer feels calm and institutional. Use a few abstract node ticks or small geometric study markers on the ring instead of text. Add one small magenta diagnostic notch only if needed to preserve the project's exploration-UI connection.

Production asset requirements: single centered object, transparent RGBA background, square canvas, generous padding, all geometry inside the canvas, readable as a silhouette at 48–96 px, clean anti-aliased edges, no ground shadow, no scene, no panel, no buttons, no labels, no numbers, no letters, no readable glyphs, no graduation cap, no logo, no watermark, no signature, no collage, no extra objects, no cables leaving the canvas. Do not make it a literal copy of Image 2. The result should feel like a fictional campus restoration badge and repair core, not an institutional logo.
```

## image-quality-check

依据 `image-quality-check` 对实际仓库副本检查；本闸门只判断技术完整性、任务符合度、构图可读性和生成伪影，不替代负责人对风格匹配、正式资产批准或 Godot 接入效果的评审。

```yaml
quality_result:
  schema_version: 1
  task_id: m1-campus-hub-ui-science-badge-asset-005
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: NOT_APPLICABLE
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS
  failures: []
  notes:
    - 文件可解码，透明 RGBA 画布完整，主体没有被裁切。
    - 没有复现参考图中的字母、校名、年份、具体外圈字形或水印；只保留抽象圆环、轨道和蓝金配色关系。
    - 中央修复晶核、深蓝分段徽章环、蓝／暖金轨道和少量品红诊断点符合新的校园科学主题。
    - 四角 alpha 为 `0,0,1,0`；左下角的单个 alpha=1 像素属于抗锯齿边缘，接入前如出现黑边可做阈值清理。
    - 圆环、轨道和晶核细节较密，48 像素下应优先保证外轮廓与中央晶核，不应依赖小节点传达状态。
  repair_directives: []
  next_step: accept
```

## 实测属性

- 尺寸：1254×1254。
- 像素格式：`Format32bppArgb`。
- 透明度：四角 alpha `0,0,1,0`；中心主体 alpha `253`。
- 文件大小：1,654,063 bytes。
- SHA-256：`9BDACD2946D7B1B5541752B43A46654703F70C98577C265D8BF2E7D994174668`。
- 资源检查脚本：使用 PowerShell 7 + `System.Drawing.Bitmap` 实测文件可解码、尺寸、像素格式和角点透明度；未使用 Pillow 版 `asset_report.py`。

## 当前结论

`asset_005` 是基于负责人新参考方向生成的正式资产候选，仍保持 `unselected + pending + not_integrated`。它比 004 更明确地表达“校园科学徽章”，但圆环层级和暖金轨道是否足够清爽、是否需要降低中央高光，仍需负责人评审后决定。没有获得 Godot 接入授权。
