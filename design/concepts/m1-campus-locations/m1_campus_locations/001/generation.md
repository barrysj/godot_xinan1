# M1 校园探索地点环境 · concept_001

## Provenance

- Task: `m1-campus-locations`
- Asset object: `m1_campus_locations`
- Candidate: `concept_001`
- Location: `gate` / 南门
- Stage: concept
- Generated: 2026-09-19
- Tool: built-in `image_gen` via the project imagegen skill; no CLI/API fallback
- Output copied to: `design/concepts/m1-campus-locations/m1_campus_locations/001/concept.png`
- Default generated output: `C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-85b69453-044b-417f-b0f4-fce36f8e14ff.png`
- Actual output: 1672 × 941, RGB, opaque PNG, aspect 1.776833
- Local SHA-256: `586D7711B6BF19FEFF5C53149152D76F366F35F54B7482B205CD62DE0FFEDA11`

## Input references

The following files were supplied by the user in the current conversation and copied into the
reference-only directory. They are not shipped assets and are not treated as licensed public
source files. Public redistribution or commercial-use terms have not been independently verified.

| Reference | Role | Local SHA-256 |
| --- | --- | --- |
| `references/campus-map.png` | 校园平面与地点关系身份参考 | `C44BBEF026A2E6DACA8F852110D67AE9DC646B2355F25C7E63BFA97525B57738` |
| `references/south-gate.png` | 南门主要建筑与入口构图参考 | `737BAD5A2C08F229CCC6194B2B5DB92B392B2F47008EAC06889167427FFA8BEE` |
| `references/pinxue-building-courtyard.png` | 品学楼材料、庭院尺度与建筑家族辅助参考 | `91A17502FD517A52EFC008E9D29FFC4D212D829A7F3B20ACC795E60B58F33789` |
| `references/pinxue-building-atrium.png` | 品学楼组团中庭的构图与回廊辅助参考 | `895E46C8AA77D778455486F0CDFFDECC4C08EE35C6CECD17377EB8FA960ABC65` |

The map and building photos establish real-campus identity. The concept does not copy map
controls, browser chrome, watermarks, readable signage, school logos, people, or vehicles.

## Generation history

1. First pass used the four user references to establish the South Gate and reserve the four
   corner/bottom UI-safe areas. It was not retained because it remained too photographic and
   introduced an unsupported saturated pink canopy on the right.
2. Final pass was a targeted style-transfer revision using the first pass as the edit target and
   the supplied South Gate photo as the identity anchor. It preserved the gate towers, booths,
   tree wall, central road, and inner campus axis, while removing unsupported props and shifting
   the rendering toward crisp 2D cel-shaded concept art.

## Final prompt

```text
Use case: style-transfer
Asset type: concept-stage game environment background candidate.
Input images: the most recent generated South Gate concept is the edit target; the supplied campus map and South Gate photo are identity references; the supplied Pinxue Building photos are supporting architecture references.
Primary request: Convert the current South Gate concept into a refined 2D daily exploration environment concept in the established Cyber Pop Campus visual language while preserving the recognizable South Gate architecture and the overall composition. Keep the pale gate towers, separate security booth structures, tree-lined wall on the left, central roadway, inner campus axis, and four potential hotspot anchors.
Style/medium: clean detailed 2D game environment concept art; crisp geometric planes, restrained cel shading, controlled soft texture, clear stylized silhouettes, subtle digital-art finish; visibly illustrated rather than photorealistic, with calm, light, readable rendering.
Composition/framing: keep the wide 16:9 entrance perspective; keep gate towers in the upper-middle and the road readable through the center; lower-middle remains a low-detail playable field; all four corners and the lower action area remain low contrast and uncluttered for code-native HUD, details, status, and buttons.
Color palette: mostly pale neutral stone, muted gray, soft sky blue, and restrained green; limited cyan-blue fixtures; charcoal as line/value anchor; no large magenta or neon accents in the daily state.
Lighting/mood: soft natural daytime light, gentle shadows, airy and trustworthy.
Change only: rendering treatment, clutter reduction, and removal of unsupported props. Remove the large pink canopy, any random signage, any browser/map-like overlay, watermarks, logos, readable text, labels, icons, and UI chrome. Keep the real-place geometry and identity from the supplied South Gate photo. Do not add characters, vehicles, sci-fi structures, route lines, or interaction markers.
Avoid: photorealistic camera rendering, fisheye distortion, excessive micro-detail, neon cyberpunk styling, saturated pink, impossible architecture, duplicated windows, cropped gate towers, signatures.
Output intent: one concept candidate for human concept review, not a final production asset.
```

## Technical quality gate

```yaml
quality_result:
  schema_version: 1
  task_id: m1-campus-locations
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
    - "概念保留了南门的门体、门卫房、左侧树墙与内向道路；不是测绘图或正式背景。"
    - "16:9 画面四角和底部操作区保持低对比；四个热点锚点由真实结构提供，不含烘焙标记。"
    - "风格相似度与正式资产可用性仍需负责人概念评审，未执行 Godot 接入。"
  repair_directives: []
  next_step: accept
```

## Review state

- Selection: `unselected`
- Approval: `pending`
- Integration: `not_integrated`
- Human concept decision: pending
