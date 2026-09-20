# M1 球场环境：concept_001 生成记录

## 版本与来源

- 候选版本：`concept_001`
- 地点身份：`court`／校园篮球场（具体场地待确认）
- 版本关系：独立于南门与步道对象；使用已批准的南门 `concept_003` 作为日常视觉方向参考。
- 参考图 1：`design/concepts/m1-campus-locations/references/campus-map.png`，仅用于运动场组团、球场和跑道的大关系。
- 参考图 2：`design/concepts/m1-campus-locations/m1_campus_locations/003/concept.png`，用于已批准的日常 2D 表现方向。
- 生成输出：`C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-8b43f85a-f755-4c57-9b21-20208726acfd.png`
- 工作区副本：`design/concepts/m1-campus-locations/m1_campus_court/001/concept.png`
- 生成工具：Codex `image_gen` 新概念生成
- 生成日期：2026-09-20

## 身份边界

当前校园平面图能够确认运动场组团及篮球场关系，但没有指定球场的实景照片或地图标记。本版登记为校园篮球场概念候选，不宣称对应某一块已确认的现实场地；正式制作前仍需补充宽景照片并标注具体位置。

## 生成提示词

```text
Use case: stylized-concept
Asset type: daily exploration location background concept for a campus game.
Input images: Image 1 is a user-provided campus plan used only for broad sports-complex relationships: an athletics zone with courts and a running track. Image 2 is the approved South Gate concept_003 used only as the visual direction reference for clean daytime 2D illustrated campus rendering, palette discipline, lighting and safe composition.
Primary request: Create a new 16:9 daily daytime exploration background for a generic university sports court location. Show a clean outdoor basketball court as the readable focal point, with two hoops, painted court lines, low fencing, a few trees and campus athletic facilities receding behind it. The space should feel like a real student sports area, open and navigable, with a calm campus atmosphere.
Scene/backdrop: maintained university athletic zone, outdoor hard court, subtle track or sports-field context in the distance, mature greenery and practical campus lighting.
Subject: one empty outdoor basketball court; no characters required.
Style/medium: refined 2D illustrated concept art consistent with the approved South Gate concept; natural daylight, fresh engineering-campus atmosphere, restrained technology presence.
Composition/framing: wide eye-level view with a clear court plane in the foreground and a strong depth axis toward the athletic complex, open low-contrast corners and bottom edge for future native UI and hotspot overlays, no baked gameplay markers.
Lighting/mood: bright soft daytime light, gentle tree shadows, clear readable court markings, modest atmospheric perspective.
Color palette: pale warm concrete, muted blue-green fencing, fresh greens, soft blue sky, restrained cyan accents only where naturally appropriate.
Constraints: use the map only as broad sports-zone inspiration; do not reproduce map graphics, pins, labels, roads as diagram lines or any readable text. Do not invent a named or confirmed real-world landmark. Do not add logos, signs, UI, icons, watermark, neon, glitch, people, vehicles or fantasy structures. Keep the scene grounded in a plausible campus. No gate architecture or lakefront promenade; this is a distinct court location. Preserve 16:9 framing and do not crop or recompose.
```

## 质量检查

```yaml
quality_result:
  schema_version: 1
  task_id: m1_campus_locations
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
    - "输出可解码，尺寸为 1672 × 941，24bpp RGB，不透明，保持 16:9 画幅。"
    - "篮球场、篮架、场线、围网、跑道和后方运动设施层次清楚，底部与四角保留低对比操作空间。"
    - "校园平面图仅提供运动场组团大关系，具体现实球场身份仍需照片与地图标记确认。"
    - "候选为概念阶段，未批准为正式资产，未接入 Godot。"
  repair_directives: []
  next_step: accept
```

## 技术属性

- 像素尺寸：`1672 × 941`
- 像素格式：`Format24bppRgb`
- 宽高比：`1.776833`
- 文件大小：`2545599` bytes
- SHA-256：`01B872F85D9FE3B18C925A8D712533A53EC8CF8DDF46FD1DF8F2B1FACE45AB50`
- 透明度：无
- 画面检查：`view_image` 实际查看通过；未见地图控件、可读文字、UI、logo、水印或明显生成异常。

## 状态

- `selection: unselected`
- `approval: pending`
- `integration: not_integrated`
- 现实地点身份：`pending_photo_and_map_mark`
