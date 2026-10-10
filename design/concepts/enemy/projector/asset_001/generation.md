# 资产生成记录

## 资产阶段收尾（2026-10-07）

负责人决定：“已生成资产”用选择框筛选、而不是标签。只保留最新一版，并提升为正式资产。本文件保存 tmp_002 制作时的完整提示词与来源；该整套现为已批准的 asset_001。历史过程用语不表示当前审批状态。正式运行子集由白名单提升，源稿、动作卡、GIF 与预览单位留在生产资料中。



## tmp_002 定向修改（2026-10-07）

- 负责人反馈：图书管理员攻击与施法不明显；每个敌人施法必须有光效。
- 本版保留 tmp_001 九姿势源图和弹体作为基底，批准概念版本未改变。
- 光效使用 Godot 原生双色 Line2D 光环、径向短光线与 AnimationLibrary；未绘制额外位图，释放峰值与现有动作时钟同步，其他状态复位为透明。试渲染中发现大面积柔光在 GIF 中发灰，最终版移除柔光面，只保留清晰亮边与脉冲。
- 修订制作时为未批准候选；2026-10-07 负责人批准只保留本版，正式留存为 asset_001，旧 tmp_001 已按授权清理。
## 弹体画稿

- 生成工具：内置 imagegen；透明背景；source/projectile.png。
- 原始生成文件：exec-a630e5d1-90d7-4ac9-be75-cd48c17732b4.png；仅作独立弹体形态，未作为概念批准证据。

Use case: stylized-concept. Asset type: one isolated transparent 2D optical energy projectile head for cream/cyan hovering projector enemy. A single very short horizontal CYAN LIGHT PULSE aimed directly SCREEN RIGHT: rounded bright white-cyan leading tip on RIGHT, narrow light cyan body, tapering soft cyan tail extending LEFT. Clean precise 2D cel-shaded game effect with restrained soft outer edge, compact 3:1 horizontal silhouette, no huge glowing halo. Center the pulse with generous empty transparent margins, actual alpha background. NO projector, no eye, no scene, no arrows, no text, no particles, no multiple bolts, no circular rings, no ground or shadow. White core #F6F8FA, cyan #22E0F0 and teal #22B8D6; readable at 24 by 8 logical pixels.

## 处理与预览

裁取主体并保持原 Alpha／比例，源图留存；以实际 Godot 捕获 GIF 和 rig_manifest.json 的运行文件清单为准。

- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。
- 生成原图：exec-34fdfd14-6387-4567-80ea-3bf48bd1546a.png
- 资产阶段临时候选，未批准、未正式接入。
- 三视图替代／单视角制作依据：负责人当前对话确认。

## 完整提示词

Use case: identity-preserve. Asset type: transparent 2D production game enemy pose atlas. The supplied approved PROJECTOR concept is the strict identity, mechanical structure, palette and cel-shading reference. Create a square transparent RGBA atlas with NINE full isolated poses in a regular THREE COLUMN by THREE ROW grid. Each cell has generous transparent margins, no overlap, same body size, fixed 3/4 viewpoint facing SCREEN RIGHT. True alpha, no checkerboard, no ground shadow, no target, no words, no labels, no frames. Cream rectangular projector casing with charcoal underside, ONE cyan circular lens at right/front, FOUR cream mechanical shutter flaps around it, ONE articulated folded ceiling bracket and rectangular top mounting plate, cable with magenta ring. No legs, feet, arms or face beyond lens. Faithful clean navy outlines, restrained cel shading, cream/navy/cyan/magenta colors. Every cell uses exactly same component count. Nine cells row-major: 1 idle level hovering, flaps partially open, cyan iris; 2 move glide forward with bracket leaning rearward and body pitched slightly toward screen-right; 3 anticipation four flaps CLOSE inward around lens to a small aperture, bracket compresses; 4 attack release four flaps WIDE open, cyan lens bright white center, slight body rear recoil, NO long beam painted in atlas; 5 recovery flaps returning to idle and body stable; 6 cast flaps wide open in a distinct radial orientation, top bracket fully extended upward, bright focused cyan iris, no surrounding detached effects; 7 critical body lists downward, bracket slumps, lens dim and cracked small but components remain attached; 8 death-start projector descending and tilted 25 degrees, lens dark, top bracket folding onto body; 9 death-end whole projector lying on its side on an imaginary floor, top mounting bracket folded down, dead dark lens, four attached shutter flaps, no explosion or separated debris. Same rigid casing proportions in all poses. All silhouettes entirely inside each cell with large margin, visual atlas built for cutting into clean sprites, not a labeled concept board.
