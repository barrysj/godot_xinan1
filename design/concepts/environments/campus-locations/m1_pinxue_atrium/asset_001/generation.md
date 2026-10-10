# 品学楼组团中庭环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_pinxue_atrium.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 地点身份：品学楼组团的中庭
- 参考图 1：`design/concepts/environments/campus-locations/references/pinxue-building-atrium.png`，主要身份与建筑几何参考。
- 参考图 2：`design/concepts/environments/campus-locations/references/campus-map.png`，用于品学楼组团的大关系。
- 工作区副本：`design/concepts/environments/campus-locations/m1_pinxue_atrium/asset_001/concept.png`
- 生成工具：Codex `image_gen` 新概念生成
- 生成日期：2026-09-20

## 原始生成提示词

### 1 · 生成提示词

```text
Use case: stylized-concept
Asset type: daily exploration location background concept for a campus game.
Input images: Image 1 is the user-provided real photo of the Pinxue Building group central atrium and is the primary identity and geometry reference. Image 2 is the user-provided campus plan used only for broad Pinxue Building group context. Image 3 is the approved South Gate concept_003 used only for the project's clean daytime 2D illustrated rendering direction.
Primary request: Create a new 16:9 daily daytime concept background for the specific location "Pinxue Building group central atrium". Preserve the recognizable spatial identity of the reference: a broad stepped stone approach in the foreground, a large open paved courtyard below, white tiled multi-story teaching wings on the left and right, a central elevated skybridge or enclosed passage supported by a rhythm of columns, planted beds with cycads and trimmed shrubs, and a view through the passage toward trees and the campus beyond.
Scene/backdrop: real-feeling Chinese university teaching-building group atrium, formal but welcoming civic campus space.
Style/medium: refined 2D illustrated campus concept art consistent with the approved South Gate concept; natural daylight, clear architectural depth, restrained digital polish.
Composition/framing: wide elevated eye-level view from the top of the steps, preserving the strong central axis through the columned passage; keep the steps and open courtyard readable, with low-detail corners for future UI and interaction overlays, no baked gameplay markers.
Lighting/mood: bright soft daylight, gentle shadows under the skybridge, calm daily campus atmosphere.
Constraints: translate the photo into concept art; do not copy the photo's browser controls, university logo, readable signs, watermark, people or interface elements. Preserve the distinctive left/right building wings, central skybridge, columns, stairs, planters and axial opening. No neon, glitch, fantasy structures, vehicles, UI, icons or text. Keep 16:9 framing and do not crop or recompose.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
