# M1 图书馆环境 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../../assets/art/manifests/m1_library_environment.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始生成提示词

### 1 · 共同提示词

```text
Use case: style-transfer
Asset type: Cyber Pop Campus game environment concept, library anomaly-state variant
Primary request: Transform this exact nighttime university library into its high-intensity anomaly state: the library's memory index and digital catalog are visibly corrupting physical space.
Style/medium: preserve the source's polished 2D anime-inspired architectural concept art, line quality, materials, and cinematic rendering.
Anomaly language: luminous cyan and magenta data streams travel along selected architectural edges; small network nodes and waveform fragments appear around catalog areas; book spines and exhibition displays locally fragment into ordered digital blocks; a few controlled spatial echoes or misregistered repetitions suggest broken indexing. Use sharp localized glitch and transparent data geometry, not full-screen noise.
Lighting/mood: retain the deep navy night foundation and warm practical lamps, now invaded by high-saturation cyan, magenta, and violet anomaly light. Highest visual intensity of the three states, eerie and beautiful, but still readable as the same library.
Constraints: preserve the exact camera, crop, perspective, floor count, octagonal atrium identity, columns, primary stairs, wooden railings, radial bookshelves, desks, chairs, exhibition, cafe, sofas, plants, doors, and main walkways. Keep all routes readable. No people. No legible text. No logo. No watermark.
Avoid: simple purple filter; full-screen blur or glitch; generic server room; total destruction; darkness that hides the space; changing the camera; replacing the library; moving or removing major furniture; adding characters; covering the whole image with HUD.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../../docs/art/WORKFLOW.md#源资料与版本)。
