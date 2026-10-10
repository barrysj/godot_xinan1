# 操场环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_sports_field.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 地点身份：操场
- 实景参考：`design/concepts/environments/campus-locations/references/sports-field.png`
- 风格参考：`design/concepts/environments/campus-locations/m1_campus_locations/asset_003/concept.png`
- 工作区副本：`design/concepts/environments/campus-locations/m1_sports_field/asset_001/concept.png`
- 生成工具：Codex `image_gen` 参考图概念生成
- 生成日期：2026-09-20

## 原始生成提示词

### 1 · 生成提示词

```text
Create a polished 16:9 daytime 2D illustrated environment concept of 操场 at UESTC. Use the real photo as the exact location identity reference and the approved South Gate concept_003 as the rendering-style reference. Preserve the expansive green football field, white center-circle marking, running track edge, simple white goals, enclosing tree rows, and distinctive large arched stadium canopy centered in the distance. Use clean semi-realistic anime campus background painting, crisp architecture and perspective, natural daylight, fresh blue sky, leafy greens, restrained digital polish, and gentle atmospheric depth. Remove panorama navigation arrows, browser or tour UI, university logos, watermarks, readable lettering and signs, crowds, vehicles, and visual clutter. Keep at most a few tiny people or bicycles only for scale. No game UI, hotspot icons, neon cyberpunk, fantasy, or text. Keep lower corners and the bottom area calm for future native interface.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
