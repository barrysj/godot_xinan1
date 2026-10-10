# 教室投影仪 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/projector.yaml)为准。

现存参数／处理入口：[build-config.json](build-config.json)、[rig_manifest.json](rig_manifest.json)、[battle_animation.frames.json](battle_animation.frames.json)、[action-cards.json](action-cards.json)、[action-input.json](action-input.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 生成工具：内置 imagegen；透明背景；source/projectile.png。
- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。

## 原始生成提示词

### 1 · tmp_002 定向修改（2026-10-07）

```text
Use case: stylized-concept. Asset type: one isolated transparent 2D optical energy projectile head for cream/cyan hovering projector enemy. A single very short horizontal CYAN LIGHT PULSE aimed directly SCREEN RIGHT: rounded bright white-cyan leading tip on RIGHT, narrow light cyan body, tapering soft cyan tail extending LEFT. Clean precise 2D cel-shaded game effect with restrained soft outer edge, compact 3:1 horizontal silhouette, no huge glowing halo. Center the pulse with generous empty transparent margins, actual alpha background. NO projector, no eye, no scene, no arrows, no text, no particles, no multiple bolts, no circular rings, no ground or shadow. White core #F6F8FA, cyan #22E0F0 and teal #22B8D6; readable at 24 by 8 logical pixels.
```

### 2 · 完整提示词

```text
Use case: identity-preserve. Asset type: transparent 2D production game enemy pose atlas. The supplied approved PROJECTOR concept is the strict identity, mechanical structure, palette and cel-shading reference. Create a square transparent RGBA atlas with NINE full isolated poses in a regular THREE COLUMN by THREE ROW grid. Each cell has generous transparent margins, no overlap, same body size, fixed 3/4 viewpoint facing SCREEN RIGHT. True alpha, no checkerboard, no ground shadow, no target, no words, no labels, no frames. Cream rectangular projector casing with charcoal underside, ONE cyan circular lens at right/front, FOUR cream mechanical shutter flaps around it, ONE articulated folded ceiling bracket and rectangular top mounting plate, cable with magenta ring. No legs, feet, arms or face beyond lens. Faithful clean navy outlines, restrained cel shading, cream/navy/cyan/magenta colors. Every cell uses exactly same component count. Nine cells row-major: 1 idle level hovering, flaps partially open, cyan iris; 2 move glide forward with bracket leaning rearward and body pitched slightly toward screen-right; 3 anticipation four flaps CLOSE inward around lens to a small aperture, bracket compresses; 4 attack release four flaps WIDE open, cyan lens bright white center, slight body rear recoil, NO long beam painted in atlas; 5 recovery flaps returning to idle and body stable; 6 cast flaps wide open in a distinct radial orientation, top bracket fully extended upward, bright focused cyan iris, no surrounding detached effects; 7 critical body lists downward, bracket slumps, lens dim and cracked small but components remain attached; 8 death-start projector descending and tilted 25 degrees, lens dark, top bracket folding onto body; 9 death-end whole projector lying on its side on an imaginary floor, top mounting bracket folded down, dead dark lens, four attached shutter flaps, no explosion or separated debris. Same rigid casing proportions in all poses. All silhouettes entirely inside each cell with large margin, visual atlas built for cutting into clean sprites, not a labeled concept board.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
