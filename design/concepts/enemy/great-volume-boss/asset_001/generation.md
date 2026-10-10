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
- 原始生成文件：exec-c5a4c32b-5ed3-486d-975e-ad7db982a766.png；仅作独立弹体形态，未作为概念批准证据。

Use case: stylized-concept. Asset type: single transparent 2D game projectile sprite for the approved hovering book enemy. One familiar sharply folded white/cream paper airplane, side three-quarter view, NO scene. SHARP single nose is the RIGHTMOST point pointing SCREEN RIGHT and very slightly downward, the two broad wing trailing edges and open folded tail are at LEFT. One central fold ridge connects left rear to the right sharp nose. Long horizontal dart shape, crisp dark navy 2px outlines, three simple cream/gray cel shading planes, restrained matching campus illustration style. Airplane occupies 70% width, entire silhouette uncropped with generous transparent margin. True transparent background, no shadow, no speed lines, no glow, no letters, no labels, no duplicated planes. Clean isolated readable raster game asset.

## 处理与预览

裁取主体并保持原 Alpha／比例，源图留存；以实际 Godot 捕获 GIF 和 rig_manifest.json 的运行文件清单为准。

- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。
- 生成原图：exec-03cb257b-fe39-44e1-9fb8-074bb19fdafd.png
- 资产阶段临时候选，未批准、未正式接入。
- 三视图替代／单视角制作依据：负责人当前对话确认。

## 完整提示词

Use case: identity-preserve. Asset type: transparent nine-pose 2D game sprite atlas of GREAT VOLUME enemy. The attached approved thick hovering hardcover book concept is strict identity and action reference. ONE thick dark navy hardcover book, brass four corner protectors, cream page block, two small magenta eyes on visible page edges or open pages, EXACTLY TWO dark red long ribbon bookmarks emerging from binding. No legs, feet, arms, teeth or humanoid features. Faithful clean navy outlines and precise cel-shading in navy/brass/cream/red, not 3D. Produce square true-alpha RGBA atlas with NINE isolated sprites in regular THREE COLUMN by THREE ROW grid, generous 12% margin around complete silhouettes, same physical scale, fixed 3/4 camera toward screen-right. No text, borders, labels, target cubes, shadow or ground. Nine cells row-major: 1 idle book CLOSED upright floating with two ribbons trailing rear/left; 2 moving closed book tilted 12 degrees forward toward screen-right, two ribbons behind; 3 anticipation closed book upright lifted and tilted slightly backward; 4 melee IMPACT closed book rotated 30 degrees forward/down with lower-front corner reaching imaginary floor, page block clear, no debris; 5 recovery closed book settling upright; 6 CAST clearly OPENED LEFT-RIGHT like a conventional book being read, TWO broad flat rectangular cream page surfaces, ONE central recessed binding gutter, same navy covers and brass corners underneath, two magenta eyes one on each page, exactly two red ribbon bookmarks behind, only two subtle lifted page corners; NO feather fan, no wings, no accordion; NO planes baked into this cell; 7 critical closed book sagging with slightly separated covers, two eyes dim, ribbons hanging weakly; 8 death-start book tipping flat, eyes dark, page block loosening but same book; 9 death-end book lying flat HALF OPEN, navy cover and brass corners present, two red bookmarks limp, eyes extinguished. Preserve same book dimensions and page thickness through rotation/opening. All nine cutout silhouettes fully inside cells with safe margins. Production sprite sheet, no labels.
