# M1 图书馆环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_library_environment.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 共同提示词

```text
Use case: lighting-weather
Asset type: Cyber Pop Campus game environment concept, library state variant
Primary request: Edit the supplied approved daytime library image into a believable nighttime version of the exact same place.
Style/medium: preserve the source's polished 2D anime-inspired architectural concept art and material rendering exactly.
Lighting/mood: night outside every window and skylight; deep navy ambient light; warm practical desk lamps and ceiling lights; restrained cyan and magenta accents only from realistic digital signage or architectural light strips; quiet late-night university library. Night should feel more digitally heightened than daytime but remain a real campus interior.
Constraints: change only time of day, illumination, reflections, and night atmosphere. Preserve the exact camera, crop, perspective, octagonal floor geometry, number and alignment of floors, columns, stairs, wooden railings, radial bookshelves, desks, chairs, exhibition, cafe counter, sofas, plants, doors, and all walkways. Keep every approved spatial relationship unchanged. No people. No text. No logo. No watermark.
Avoid: anomaly effects, glitch, data streams, floating HUD, structural warping, purple color wash, cyberpunk nightclub, added furniture, removed furniture, changed stairs, changed shelf orientation, changed railing spacing, changed floor count.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
