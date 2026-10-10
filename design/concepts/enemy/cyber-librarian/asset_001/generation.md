# 资产生成记录

## 资产阶段收尾（2026-10-07）

负责人决定：“已生成资产”用选择框筛选、而不是标签。只保留最新一版，并提升为正式资产。本文件保存 tmp_002 制作时的完整提示词与来源；该整套现为已批准的 asset_001。历史过程用语不表示当前审批状态。正式运行子集由白名单提升，源稿、动作卡、GIF 与预览单位留在生产资料中。



## tmp_002 定向修改（2026-10-07）

- 负责人反馈：图书管理员攻击与施法不明显；每个敌人施法必须有光效。
- 本版保留 tmp_001 九姿势源图和弹体作为基底，批准概念版本未改变。
- 光效使用 Godot 原生双色 Line2D 光环、径向短光线与 AnimationLibrary；未绘制额外位图，释放峰值与现有动作时钟同步，其他状态复位为透明。试渲染中发现大面积柔光在 GIF 中发灰，最终版移除柔光面，只保留清晰亮边与脉冲。
- 修订制作时为未批准候选；2026-10-07 负责人批准只保留本版，正式留存为 asset_001，旧 tmp_001 已按授权清理。

### 两张出手姿势重生成

身份参考：concept_003/cyber_librarian_action_concept_003.png；比例和线稿参考：asset_001/frames/idle.png（与原 tmp_001 身份参考相同的留存副本）。
原始输出 exec-baf20d54-5e33-4b78-974d-6b327649b5a0.png，候选 source/action-poses.png；画幅 1536×1024，RGBA。

完整提示词：

Use case: identity-preserve. Create a TRANSPARENT game sprite two-pose sheet for the exact CYBER LIBRARIAN BOSS shown in the references. Approved board is identity reference; transparent idle sprite is exact runtime proportions and linework reference. Exactly TWO complete isolated full-body poses, two equally sized cells SIDE BY SIDE, same body/head scale, plenty 12 percent transparent margins, no labels, grid, ground, targets, flying books or baked external light FX. Requested canvas 1536x1024 RGBA. Fixed slight three-quarter facing screen RIGHT, no camera variation. NONHUMANOID hovering cream/navy/brass tall smooth rounded capsule, one black face screen with exactly TWO flat cyan horizontal eye bars, small gold open-book emblem, one lower black book return slot, exactly TWO rigid NAVY BOOKEND CONTROLLER WINGS, ONE visibly connected at EACH side, with brown stored books remaining attached behind them. No arms, hands, legs, feet, mouth or pupils. No typography/barcodes except small book emblem. Preserve cream #F6F8FA, navy #25344B, brass #B58A40, cyan #22E0F0 with crisp navy outline and cel shading. LEFT pose: ATTACK RELEASE, whole body leans forward toward RIGHT by 14 degrees, both navy wings visibly flared out at 30 degrees while remaining attached, lower book return slot visibly open with thin bright cyan rim, calm focused eyes. RIGHT pose: CAST RELEASE, body perfectly upright authoritative, both navy wings raised and spread symmetrically around 35 degrees, showing their broad navy faces and bright cyan emitter rails, flat calm eye bars, dark return slot to distinguish spell from attack. Main torso identical in the two poses. Wings should be clearly displaced from idle silhouette, never disappear into books or turn completely edge-on. Both complete rigid shapes, same proportions, visually clear at 200px. Do not add detached props or effects; light halos and silence field will be authored separately in Godot.

### 透明边缘检查及清理候选

输入：上述两姿势输出；使用内置 imagegen 编辑。输出 exec-f47e5865-fdc3-4dc7-b91e-85ede7d99694.png，当前裁取输入 source/action-poses-clean.png。
两份均有有效 Alpha；灰色外围像素为 Alpha=0 的隐藏 RGB，实际合成无灰雾。保留原始和清理稿供阶段留存选择。清理稿仅以实际结构及 Alpha 检查判定，没有假定生成器完全逐像素保持原图。

完整编辑提示词：

Background-removal / alpha-cleanup edit ONLY. Preserve EXACTLY both existing robot drawings, their poses, dimensions, body proportions, colors, outlines, eye bars, two attached navy wings, books, and composition. Remove ALL surrounding gray haze, glow halos, shadows, gray clouds, and backdrop outside both cutout silhouettes. The sprites must be truly clean opaque interior RGBA cutouts on a perfectly transparent background with only a 1-2 pixel antialiased outline edge. No light effects outside the silhouettes; the game will render light separately. Do not redraw, redesign, shrink, relight, rotate, recolor, crop or move either robot. Keep both full-body robots in the same side-by-side layout. Remove external haze while retaining the cyan rails and cyan slot border INSIDE the actual robot shapes.
## 弹体画稿

- 生成工具：内置 imagegen；透明背景；source/projectile.png。
- 原始生成文件：exec-fe80d534-e61a-4840-a71d-d7dfdcbf437f.png；仅作独立弹体形态，未作为概念批准证据。

Use case: stylized-concept. Asset type: single isolated transparent 2D game projectile for CYBER LIBRARIAN boss, matching the attached approved reference ONLY as palette and book design reference. ONE small CLOSED conventional navy hardcover library book with cream thick page edges, fine brass cover border and tiny simple gold open-book emblem, no title or lettering. In a three-quarter side view, horizontal long axis pointing screen-right, leading top-right corner to right, closed rigid covers, cream page block clearly visible on lower edge. Clean crisp navy outlines and cel-shading, navy/brass/cream materials, not 3D render. Full book centered with large transparent margins, true alpha background. No boss, no character, no hands, no extra books, no glow, trails, shadow, text, captions, watermarks or page wings. Professional readable game sprite.

## 处理与预览

裁取主体并保持原 Alpha／比例，源图留存；以实际 Godot 捕获 GIF 和 rig_manifest.json 的运行文件清单为准。

- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。
- 生成原图：exec-c7a2d238-6018-4e67-bae3-874b7f0ed380.png
- 资产阶段临时候选，未批准、未正式接入。
- 三视图替代／单视角制作依据：负责人当前对话确认。

## 完整提示词

Use case: identity-preserve. Asset type: transparent production nine-pose 2D CYBER LIBRARIAN BOSS game sprite atlas. Follow attached approved concept EXACTLY as identity: nonhumanoid floating smooth rounded tall cream robot capsule, navy front panel with fine brass trim and small gold open-book emblem, BLACK rounded rectangular face screen with TWO flat cyan horizontal eye bars, ONE black book return slot at lower front, TWO navy/brass vertical bookend controller wings beside body, brown neatly stacked books visible behind wings. NO human head, hands, arms, legs, feet, mouth or pupil eyes. Preserve authoritative calm/old-fashioned mood, clean navy outlines and cel-shading, cream/navy/brass palette, restrained cyan light. Remove ALL tiny typography and barcodes for runtime sprite readability, retaining book emblem and return slot. Square true-alpha RGBA atlas, EXACTLY NINE isolated full-body sprites in THREE COLUMNS by THREE ROWS, same body scale and camera fixed slight 3/4 toward screen-right. Big 12% safe margin around every silhouette, no shadows, ground, grid, labels, text, cubes, targets, long beams or flying books detached from main silhouette. Row-major: 1 idle hovering with two side wings resting vertical, flat calm eyes; 2 move gliding forward body pitched 8 degrees, wings trail; 3 attack anticipation wings swing BACK slightly and eyes focus to narrower bars, return slot light powers up; 4 attack release wings spread outward 25 degrees, return slot OPEN with cyan glow, visible ordered books still held beside body, no launched books in atlas; 5 recovery wings fold back to idle, slot darkens; 6 CAST two wings raise outward evenly in strict orderly formation, front scanner glowing cyan, eye bars level, upright body like reference silence-field pose, no large outside effects; 7 CRITICAL low tilted hovering, one wing droops, eyes dim and front screen has a tiny glitch line, no extra features; 8 DEATH START boss dropping with wings folding inward and eye bars off, body tilted 20 degrees; 9 DEATH END capsule lies on side with wings folded flat alongside, dark face screen and return slot, cream/navy body whole, no detached books, no gore/explosion. All parts rigid and same number across poses. Professional crisp readable game sprites faithful to reference, not a labeled design board.
