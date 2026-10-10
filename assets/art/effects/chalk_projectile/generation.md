# 美术素材 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前状态与使用范围见[美术入口](../../../../docs/art/README.md)和[主Manifest](../../asset_manifest.yaml)。

现存参数／处理入口：[projectile.metadata.json](projectile.metadata.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 日期：2026-09-15。
- 工具：Codex 内置 ImageGen。
- 身份参考：`design/concepts/enemy/chalk-spirit/concept_001/chalk_spirit_concept_001.png`；战斗比例与朝向参考：`design/concepts/enemy/chalk-spirit/asset_005/combat_sheet.png`。
- 设计：单枚朝右的断裂白粉笔弹体，左端为炭黑断面，中部仅保留少量青／品红异常裂纹；源图不烘焙尾迹、环境、命中特效或角色。
- 运行目标：约 32×16 逻辑像素；由程序按飞行方向旋转，并在弹体后方绘制三颗递减尾迹点。
- 原始图：1254×1254 RGBA；有效包围盒 `[370, 518, 898, 724]`。
- 运行资源：`resources/content/animations/chalk_projectile.tres`，锚点 `[0.5, 0.5]`，尾迹间距 2 逻辑像素。

## 原始生成提示词

### 1 · 设计与生成

```text
Use case: stylized-concept
Asset type: single lightweight 2D Godot projectile sprite for the Chalk Spirit
Input images: Image 1 is the authoritative character identity, material, palette, and rendering-style reference; Image 2 is the authoritative in-game combat sprite style and right-facing orientation reference.
Scene/backdrop: genuine transparent alpha background
Subject: exactly one short broken white classroom chalk projectile, flying horizontally to the right. It should look like a compact chalk slug cut from the same white chalk material as the character, with one dark charcoal broken end and only tiny cyan and magenta anomaly cracks near the middle.
Style/medium: clean hand-painted 2D game sprite matching the references, strong readable silhouette, crisp dark outline, restrained texture, suitable for downscaling to approximately 30 by 18 logical pixels.
Composition/framing: one object only, centered, horizontal side view, nose pointing right, generous transparent padding on all sides. No rotation in the source; runtime will rotate it along the trajectory.
Lighting/mood: same soft top-left lighting as the reference character.
Color palette: chalk white and warm pale gray, charcoal broken end, very small cyan and magenta accents.
Constraints: a single isolated projectile; no character; no hands; no muzzle; no environment; no separate debris; no motion trail; no glow cloud; no impact burst; no text; no symbols; no border; no watermark; no checkerboard pixels. Preserve a simple silhouette that remains recognizable at very small size. Output one square PNG with real transparency.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../docs/art/WORKFLOW.md#源资料与版本)。
