# 资产生成记录

## 资产阶段收尾（2026-10-07）

负责人决定：“已生成资产”用选择框筛选、而不是标签。只保留最新一版，并提升为正式资产。本文件保存 tmp_002 制作时的完整提示词与来源；该整套现为已批准的 asset_001。历史过程用语不表示当前审批状态。正式运行子集由白名单提升，源稿、动作卡、GIF 与预览单位留在生产资料中。



## tmp_002 定向修改（2026-10-07）

- 负责人反馈：图书管理员攻击与施法不明显；每个敌人施法必须有光效。
- 本版保留 tmp_001 九姿势源图和弹体作为基底，批准概念版本未改变。
- 光效使用 Godot 原生双色 Line2D 光环、径向短光线与 AnimationLibrary；未绘制额外位图，释放峰值与现有动作时钟同步，其他状态复位为透明。试渲染中发现大面积柔光在 GIF 中发灰，最终版移除柔光面，只保留清晰亮边与脉冲。
- 修订制作时为未批准候选；2026-10-07 负责人批准只保留本版，正式留存为 asset_001，旧 tmp_001 已按授权清理。

- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。
- 生成原图：exec-411f6205-4c39-40dc-94b6-4931ce60b981.png
- 资产阶段临时候选，未批准、未正式接入。
- 三视图替代／单视角制作依据：负责人当前对话确认。

## 完整提示词

Use case: identity-preserve. Asset type: production transparent 2D game enemy pose atlas. Use the attached approved KEYCAP BRAWLER concept solely as identity, mechanical component, palette, and rendering reference. Produce a square 1536x1536 RGBA atlas with EXACTLY NINE isolated complete poses arranged in a perfectly regular THREE COLUMN by THREE ROW grid, each invisible square cell 512x512. All poses centered with at least 35px clear space around each full silhouette, consistently same body/head scale, feet baseline at cell y=455 for standing poses. No labels, no dividers, no shadows, no ground, no target cubes, no text except the unchanged small Esc on head cap. Transparent background, actual alpha, no checkerboard. Crisp navy outlines and clean cel shading, cream keycaps, charcoal mechanical joints, cyan chest core and magenta eyes/wiring, no gradients beyond subtle material highlights. Identity locked: one Esc head, two arms, two legs, exactly TWO cream keys on EACH rectangular fist, never extra keys, same magenta cables and cyan core. Approx four-head tall sturdy robot. Camera fixed 3/4 facing SCREEN RIGHT in all living poses, full body, no perspective or identity redesign. Nine cells in row-major order: 1 idle guarded stance; 2 moving stride with visibly bent knees; 3 anticipation draw screen-right punching arm BACK with elbow bent while opposite fist guards chest; 4 IMPACT fully extend punching arm toward screen-right at chest height with rigid two-key fist, torso twists and bent knees, no beam; 5 recovery elbow retracting toward guarded idle; 6 CAST both fists close to chest, keys visibly pressed inward with brighter cyan chest core, controlled focused pose, no floating effects; 7 CRITICAL crouch low with one fist supporting weakened body, dim core, intact limbs; 8 DEATH START knees collapse, head drops, fists low, core dark; 9 DEATH END robot lying on side with head still attached, both legs and two intact two-key fists visible, same body proportions. Every cell is one complete same robot; clear separated cutout sprites, no silhouettes touching grid boundaries. Clean usable game sprite art, faithful to supplied concept, not a concept board.
