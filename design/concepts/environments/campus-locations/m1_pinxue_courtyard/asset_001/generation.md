# 品学楼单区内部庭院环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_pinxue_courtyard.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 地点身份：品学楼（教学楼）单区内部庭院
- 参考图 1：`design/concepts/environments/campus-locations/references/pinxue-building-courtyard.png`，主要身份与建筑几何参考。
- 参考图 2：`design/concepts/environments/campus-locations/references/campus-map.png`，用于品学楼组团的大关系。
- 工作区副本：`design/concepts/environments/campus-locations/m1_pinxue_courtyard/asset_001/concept.png`
- 生成工具：Codex `image_gen` 新概念生成
- 生成日期：2026-09-20

## 原始生成提示词

### 1 · 生成提示词

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

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
