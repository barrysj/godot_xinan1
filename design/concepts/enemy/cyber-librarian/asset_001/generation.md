# 图书管理员 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/cyber_librarian.yaml)为准。

现存参数／处理入口：[build-config.json](build-config.json)、[rig_manifest.json](rig_manifest.json)、[battle_animation.frames.json](battle_animation.frames.json)、[action-cards.json](action-cards.json)、[action-input.json](action-input.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 生成工具：内置 imagegen；透明背景；source/projectile.png。
- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。

## 原始生成提示词

### 1 · 两张出手姿势重生成

```text
Use case: identity-preserve. Create a TRANSPARENT game sprite two-pose sheet for the exact CYBER LIBRARIAN BOSS shown in the references. Approved board is identity reference; transparent idle sprite is exact runtime proportions and linework reference. Exactly TWO complete isolated full-body poses, two equally sized cells SIDE BY SIDE, same body/head scale, plenty 12 percent transparent margins, no labels, grid, ground, targets, flying books or baked external light FX. Requested canvas 1536x1024 RGBA. Fixed slight three-quarter facing screen RIGHT, no camera variation. NONHUMANOID hovering cream/navy/brass tall smooth rounded capsule, one black face screen with exactly TWO flat cyan horizontal eye bars, small gold open-book emblem, one lower black book return slot, exactly TWO rigid NAVY BOOKEND CONTROLLER WINGS, ONE visibly connected at EACH side, with brown stored books remaining attached behind them. No arms, hands, legs, feet, mouth or pupils. No typography/barcodes except small book emblem. Preserve cream #F6F8FA, navy #25344B, brass #B58A40, cyan #22E0F0 with crisp navy outline and cel shading. LEFT pose: ATTACK RELEASE, whole body leans forward toward RIGHT by 14 degrees, both navy wings visibly flared out at 30 degrees while remaining attached, lower book return slot visibly open with thin bright cyan rim, calm focused eyes. RIGHT pose: CAST RELEASE, body perfectly upright authoritative, both navy wings raised and spread symmetrically around 35 degrees, showing their broad navy faces and bright cyan emitter rails, flat calm eye bars, dark return slot to distinguish spell from attack. Main torso identical in the two poses. Wings should be clearly displaced from idle silhouette, never disappear into books or turn completely edge-on. Both complete rigid shapes, same proportions, visually clear at 200px. Do not add detached props or effects; light halos and silence field will be authored separately in Godot.
```

### 2 · 透明边缘检查及清理候选

```text
Background-removal / alpha-cleanup edit ONLY. Preserve EXACTLY both existing robot drawings, their poses, dimensions, body proportions, colors, outlines, eye bars, two attached navy wings, books, and composition. Remove ALL surrounding gray haze, glow halos, shadows, gray clouds, and backdrop outside both cutout silhouettes. The sprites must be truly clean opaque interior RGBA cutouts on a perfectly transparent background with only a 1-2 pixel antialiased outline edge. No light effects outside the silhouettes; the game will render light separately. Do not redraw, redesign, shrink, relight, rotate, recolor, crop or move either robot. Keep both full-body robots in the same side-by-side layout. Remove external haze while retaining the cyan rails and cyan slot border INSIDE the actual robot shapes.
## 弹体画稿
```

### 3 · 透明边缘检查及清理候选

```text
Use case: stylized-concept. Asset type: single isolated transparent 2D game projectile for CYBER LIBRARIAN boss, matching the attached approved reference ONLY as palette and book design reference. ONE small CLOSED conventional navy hardcover library book with cream thick page edges, fine brass cover border and tiny simple gold open-book emblem, no title or lettering. In a three-quarter side view, horizontal long axis pointing screen-right, leading top-right corner to right, closed rigid covers, cream page block clearly visible on lower edge. Clean crisp navy outlines and cel-shading, navy/brass/cream materials, not 3D render. Full book centered with large transparent margins, true alpha background. No boss, no character, no hands, no extra books, no glow, trails, shadow, text, captions, watermarks or page wings. Professional readable game sprite.
```

### 4 · 完整提示词

```text
Use case: identity-preserve. Asset type: transparent production nine-pose 2D CYBER LIBRARIAN BOSS game sprite atlas. Follow attached approved concept EXACTLY as identity: nonhumanoid floating smooth rounded tall cream robot capsule, navy front panel with fine brass trim and small gold open-book emblem, BLACK rounded rectangular face screen with TWO flat cyan horizontal eye bars, ONE black book return slot at lower front, TWO navy/brass vertical bookend controller wings beside body, brown neatly stacked books visible behind wings. NO human head, hands, arms, legs, feet, mouth or pupil eyes. Preserve authoritative calm/old-fashioned mood, clean navy outlines and cel-shading, cream/navy/brass palette, restrained cyan light. Remove ALL tiny typography and barcodes for runtime sprite readability, retaining book emblem and return slot. Square true-alpha RGBA atlas, EXACTLY NINE isolated full-body sprites in THREE COLUMNS by THREE ROWS, same body scale and camera fixed slight 3/4 toward screen-right. Big 12% safe margin around every silhouette, no shadows, ground, grid, labels, text, cubes, targets, long beams or flying books detached from main silhouette. Row-major: 1 idle hovering with two side wings resting vertical, flat calm eyes; 2 move gliding forward body pitched 8 degrees, wings trail; 3 attack anticipation wings swing BACK slightly and eyes focus to narrower bars, return slot light powers up; 4 attack release wings spread outward 25 degrees, return slot OPEN with cyan glow, visible ordered books still held beside body, no launched books in atlas; 5 recovery wings fold back to idle, slot darkens; 6 CAST two wings raise outward evenly in strict orderly formation, front scanner glowing cyan, eye bars level, upright body like reference silence-field pose, no large outside effects; 7 CRITICAL low tilted hovering, one wing droops, eyes dim and front screen has a tiny glitch line, no extra features; 8 DEATH START boss dropping with wings folding inward and eye bars off, body tilted 20 degrees; 9 DEATH END capsule lies on side with wings folded flat alongside, dark face screen and return slot, cream/navy body whole, no detached books, no gore/explosion. All parts rigid and same number across poses. Professional crisp readable game sprites faithful to reference, not a labeled design board.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
