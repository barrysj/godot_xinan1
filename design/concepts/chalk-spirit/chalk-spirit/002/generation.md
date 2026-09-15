# 粉笔精灵战斗图集候选 002 生成记录

- 阶段：正式资产候选，待人工评审；未批准、未接入
- 身份参考：已批准的 `../001/chalk_spirit_concept_001.png`
- 生成工具：内置 `image_gen`；原始输出再进行确定性透明背景提取，未重绘角色
- 日期：2026-09-14
- 原始保留：`battle_sheet_source_rgb.png`，SHA-256 `c6c0936bbf2918d9bff5a8258f3b8ffc18e512536def4faec7ee2411b5836395`
- 评审候选：`battle_sheet.png`，SHA-256 `9fcaf9abffb5a5f4b3bf685e365aa259183154083f1c077a5c92a09aff90d41a`

## 生成与修正

首次动作图集输出 `exec-77ef74b3-7335-4dc5-bc09-0a4b3968d2af.png`（SHA-256 `12815a4036601c7ffcd4f13f8a9d8855d3bf66419aa390af395bd5cfa4a80a5d`）保留 16 姿势，但为 RGB 烘焙棋盘格，技术拒收。随后背景提取输出 `exec-c93f05d3-979b-4798-8e6b-ba0afee61b65.png`（SHA-256 `681f043ac7fb1087067f2b65ccca88d14da53cf879b406f8c8c129a8ce246a6a`）具备 RGBA，却残留彩色噪边，同样拒收。

第二次定向清理输出 `exec-0f50cdd1-4fe1-4a45-a33e-c2510d43ff26.png`，角色和 16 姿势干净，但工具再次输出 RGB 棋盘格；该文件作为原始来源保留。随后按规则格纹执行确定性提取：当像素 `max(R,G,B)-min(R,G,B) <= 7` 且加权亮度 `(54R+183G+19B)>>8 >= 190` 时设为透明，其余设为不透明；最后移除面积不超过 3 像素的八连通孤立噪点。处理保留主体、身体裂纹、漂浮粉笔块和粉尘尾，未缩放、重排或重绘。

## 主生成提示词

> Use case: identity-preserve
> Asset type: production-oriented 2D game battle animation sprite sheet candidate, asset review only
> Input images: Image 1 is the approved Chalk Sprite concept 001 and is the identity, silhouette, material, and color reference
> Primary request: Convert the exact approved Chalk Sprite into a 4 columns by 4 rows sprite sheet with EXACTLY 16 separate full-body poses. Preserve the same non-human floating creature in every cell: sharp split lightning-shaped off-white chalk crown/head, dark triangular face opening with exactly two vivid magenta error-light eyes, dark chalkboard-green rectangular felt eraser core, segmented chipped off-white chalk arms and shoulder pieces, restrained cyan and magenta cracks, small orbiting chalk pieces, and a tapering chalk-dust hover tail. It is a hostile ranged classroom-anomaly enemy, not a humanoid student and not a generic robot.
> Scene/backdrop: genuine transparent alpha background in every cell; transparent gutters; no floor, no shadows, no scenery
> Style/medium: match Image 1 closely; clean refined 2D anime game art, crisp deep-navy linework, cel-shaded chalk and felt materials, clear color blocks, animation-friendly silhouette
> Composition/framing: square PNG canvas; perfectly regular 4x4 layout; all 16 cells equal; each full creature entirely inside its own cell with generous transparent margins; stable body-core pivot at horizontal center; hover-tail contact baseline at 88% down each cell; consistent scale and identity. All poses use the same three-quarter side view and ALWAYS face screen RIGHT. Do not draw grid lines.
> Pose order left-to-right, top-to-bottom:
> ROW 1: (1) neutral hover ready pose, elongated firing forearm lowered; (2) subtle idle hover with chalk pieces raised slightly and tail curled differently; (3) forward glide with body leaning right and dust tail streaming left; (4) second forward glide pose with body slightly higher and orbiting pieces shifted.
> ROW 2: (5) ranged attack anticipation, long firing forearm drawn back and crown tilted toward target; (6) actual basic firing pose, long forearm snapped fully toward screen RIGHT, one small chalk projectile just separating but still contained inside the cell; (7) recoil pose with forearm kicked back and orbiting pieces spread; (8) recovery pose returning the long forearm to ready.
> ROW 3: (9) skill charge crouched/contracted hover, three chalk shards gathering tightly around the core; (10) powerful charged cast toward screen RIGHT, long forearm extended and three shards aligned behind it, no large external VFX; (11) clear hurt recoil, core twisted back and two outer chalk pieces displaced but still attached/readable; (12) hurt recovery, pieces pulling back around core.
> ROW 4: (13) critical weakened hover, crown lowered, dust tail thin, a few fragments sagging; (14) death begins, eraser core tilting down and chalk armor separating; (15) death continues, core close to baseline with large pieces falling around it; (16) defeated remains: eraser core and recognizable crown/chalk pieces settled low in a compact non-graphic pile. Keep every death pose entirely inside its own cell.
> Color palette: chalk white and warm off-white dominate; dark chalkboard green and deep navy core; only small high-saturation cyan #00F0FF and magenta #FF2DAA fissures; no blanket neon
> Constraints: true RGBA transparency, at least 30 percent fully transparent pixels overall; no baked checkerboard; exactly 16 non-empty poses; no pose crosses a cell boundary; no labels, text, numbers, borders, guide marks, logos, or watermark; same character identity and proportions in every cell; each pose independently drawn rather than one static image shifted
> Avoid: background color, concept-board layout, duplicate or missing cells, extra creatures, human student, baby chibi, fantasy ghost robe, skeleton, knight armor, generic mechanical robot, gun, bow, magic wand, ornate debris, photorealism, pixel art, painterly rendering

## 定向修正提示词

> Remove only the checkerboard background and preserve all 16 drawings, positions, sizes, poses, colors, linework, chalk dust, fragments and identity. Output true RGBA with transparent gutters and no checkerboard pixels.

> Clean only extraction artifacts outside the 16 poses. Preserve the exact canvas, grid positions, silhouettes, body cracks, nearby chalk pieces and neutral chalk-dust tails. Remove stray colored or gray halos; output genuine RGBA with clean gutters.
