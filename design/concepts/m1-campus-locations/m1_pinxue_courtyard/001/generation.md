# 品学楼单区内部庭院：concept_001 生成记录

## 版本与来源

- 候选版本：`concept_001`
- 地点身份：品学楼（教学楼）单区内部庭院
- 身份状态：用户明确提供并确认的现实地点参考
- 参考图 1：`design/concepts/m1-campus-locations/references/pinxue-building-courtyard.png`，主要身份与建筑几何参考。
- 参考图 2：`design/concepts/m1-campus-locations/references/campus-map.png`，用于品学楼组团的大关系。
- 参考图 3：`design/concepts/m1-campus-locations/m1_campus_locations/003/concept.png`，用于已批准的日常 2D 表现方向。
- 生成输出：`C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-6c5ffac6-dbac-431e-b337-169d28f3e211.png`
- 工作区副本：`design/concepts/m1-campus-locations/m1_pinxue_courtyard/001/concept.png`
- 生成工具：Codex `image_gen` 新概念生成
- 生成日期：2026-09-20

## 生成提示词

```text
Use case: stylized-concept
Asset type: daily exploration location background concept for a campus game.
Input images: Image 1 is the user-provided real photo of the Pinxue Building single-zone internal courtyard and is the primary identity and geometry reference. Image 2 is the user-provided campus plan used only for broad Pinxue Building group context. Image 3 is the approved South Gate concept_003 used only for the project's clean daytime 2D illustrated rendering direction.
Primary request: Create a new 16:9 daily daytime concept background for the specific location "Pinxue Building single-zone internal courtyard". Preserve the recognizable spatial identity of the reference: a compact four-story white tiled teaching-building courtyard, continuous open corridors and balcony rails, a tall narrow vertical stair or service tower near the center, ground-floor classroom doors and windows, a broad brick-paved courtyard, a ramp and handrails on one side, and mature trees along the edge.
Scene/backdrop: real-feeling Chinese university teaching building internal courtyard, orderly and quiet daytime campus space.
Style/medium: refined 2D illustrated campus concept art consistent with the approved South Gate concept; natural daylight, crisp architectural planes, restrained digital polish.
Composition/framing: wide eye-level courtyard view with the building enclosure clearly readable, a low-detail open foreground for future UI and interaction overlays, no baked gameplay markers.
Lighting/mood: bright natural daylight with soft tree shade, clean and calm study-day atmosphere.
Constraints: translate the photo into concept art; do not copy the photo's browser controls, university logo, readable signs, watermark, people or interface elements. Do not invent extra wings or redesign the building's distinctive central tower, corridor rhythm, doors, ramps or courtyard proportions. No neon, glitch, fantasy structures, vehicles, UI, icons or text. Keep 16:9 framing and do not crop or recompose.
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
    - "中央窄塔、四层连廊、门窗节奏、坡道、铺装庭院和树木边界均保持可识别。"
    - "照片中的网页控件、校徽、水印和可读界面元素未进入概念图。"
    - "候选为概念阶段，未批准为正式资产，尚未绑定运行时地点 ID，未接入 Godot。"
  repair_directives: []
  next_step: accept
```

## 技术属性

- 像素尺寸：`1672 × 941`
- 像素格式：`Format24bppRgb`
- 宽高比：`1.776833`
- 文件大小：`2504000` bytes
- SHA-256：`865D67C5B82D3225165F179845CA976C33340F51D83CBCC91E9497051AA9AA5B`
- 透明度：无
- 画面检查：`view_image` 实际查看通过；未见新增 UI、logo、水印、可读文字或明显生成异常。

## 状态

- `selection: selected`
- `approval: approved`
- 批准证据：2026-09-21，负责人确认本批地点概念验收通过；详见 `docs/art/tasks/m1-campus-locations.md`。
- `integration: not_integrated`
- 运行时地点绑定：`pending_runtime_location_binding`
