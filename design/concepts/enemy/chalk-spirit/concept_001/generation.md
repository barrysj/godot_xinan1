# 粉笔精灵 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/chalk_spirit.yaml)为准。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 生成工具：内置 `image_gen`

## 原始生成提示词

### 1 · 完整提示词

```text
> Use case: stylized-concept
> Asset type: 2D game enemy concept art for Cyber Pop Campus, concept review only
> Primary request: Design one recurring ranged enemy named “Chalk Sprite” (粉笔精灵), born from an anomalous university classroom. It appears twice in both an elite encounter and the final boss encounter, so it needs an instantly readable silhouette at small battle scale and must clearly look hostile rather than like a student ally.
> Scene/backdrop: clean restrained dark blue-gray concept presentation backdrop with a subtle chalkboard tone; no environment scene
> Subject: one compact non-human floating chalk creature, roughly the visual mass of a four-head-tall student but shorter and lighter. Its body is assembled from several broken off-white chalk sticks around a dark chalkboard-green eraser-like core. A sharp triangular chalk crown/head and two small vivid magenta error-light eyes create a mischievous hostile face. One elongated chalk forearm forms a clear aiming/launching gesture toward screen LEFT, with three small chalk shards orbiting behind it like queued projectiles. A tapering chalk-dust tail makes it hover; no human clothing, no armor, no fantasy staff, no legs. Include one large three-quarter side-view hero design facing screen LEFT and two small supporting thumbnails of neutral hover and ranged attack, all showing exactly the same identity and proportions.
> Style/medium: clean refined 2D anime game concept art, crisp navy linework, cel-shaded, clear color blocks, lightly graphic digital accents, production-oriented silhouette study rather than painterly illustration
> Composition/framing: square concept board, large hero design centered-left with generous breathing room; two small pose thumbnails aligned on the right; full bodies completely visible; no grid lines
> Lighting/mood: cool classroom-night light, restrained eerie playfulness, readable rather than horror
> Color palette: chalk white and warm off-white as the main mass, dark chalkboard green and deep navy structure, small high-saturation cyan #00F0FF and magenta #FF2DAA glitch cracks, very little violet, no blanket neon
> Materials/textures: matte dusty chalk with chipped ends, felt eraser texture at the core, only a few clean digital fissures
> Constraints: preserve a simple animation-friendly silhouette; enemy must remain recognizable at 128x128 display size; readable against a dark blue-gray classroom floor; obvious ranged-attacker gesture; contemporary campus-object origin first, cyber anomaly second; no text, no labels, no logos, no watermark
> Avoid: human student, cute mascot proportions, baby chibi, fantasy ghost robe, skeleton, knight armor, mechanical robot, gun, bow, magic wand, ornate accessories, realistic horror, pixel art, photorealism, painterly thick rendering, overly complex floating debris, full-screen glitch, checkerboard transparency
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
