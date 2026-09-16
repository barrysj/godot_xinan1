# concept_005 · 开敞梯间、栏杆过道与八角楼层

2026-09-17，基线 131a38c。内建 imagegen 编辑 004 同名三图，保留颜色、光比、机位；一套修订版包含三个视角。输出原样保存，未批准、未选用、未接入。

## atrium-down.png

输入 ../004/atrium-down.png。

Edit this image locally. On the LEFT SIDE ONLY, REMOVE the diagonal stair flight directly linking the second and third balcony levels (the middle-left stacked stair run between those two floors). That bay should be OPEN AIRY EMPTY atrium-side space with orderly horizontal balcony slab edges and railings at each separate level, not continuous zigzag stairs. Do not replace removed stairs with a wall, bookshelves, ramps or tables; open void must be visible. Retain lower left stair where appropriate and right-side stairs. Preserve all other scene details, exact camera, octagonal floor shape, art exhibition, cafe and sofas, warm palette, light contrast and cel-shaded style. No text or people.

自检：左侧中间连续梯段已删除，最低可见梯段仍保留，恢复水平开敞区。输出也删减了更高处部分左梯，准确范围仍需负责人核对；没有宣称对应楼层已测绘。

## window-corridor.png

输入 ../004/window-corridor.png。

Edit this same library image. Keep bookshelf RADIAL orientation, camera, palette and architecture EXACTLY as input. Change only the RIGHT ENDS of the middle tall bookshelf runs: retract/shorten those ends away from the atrium railing to create a CONTINUOUS CLEAR WALKWAY between all bookshelf ends and railing. It must be visibly about a person's comfortable walking width, a continuous pale stone floor ribbon running along the inner polygonal railing from foreground into distance, no shelf touches railing or sticks into walkway. Do not rotate shelves or remove the railing. Do not move foreground desks. Retain art exhibit below, warm lighting, same 2D cel shading, no people/text/UI.

自检：书架右端回缩，沿栏杆连续浅色地面过道明显可见；径向书架朝向保持。过道实际尺寸未测量，旧版额外书架顶灯仍在，不扩大本轮修图范围。

## shelf-to-atrium.png

输入 ../004/shelf-to-atrium.png。

Edit ONLY the distant atrium architecture in provided image. Every floor in PLAN is the SAME REGULAR OCTAGON, centered on SAME vertical axis. Stack identical octagonal balcony slabs vertically, same footprint on all levels, same floor-to-floor height, white slab edges have exactly corresponding straight sides and 45-degree plan corners. Corresponding corners and columns line up vertically through all floors in perspective. Far central straight face, symmetrical chamfered diagonal faces left/right, then side faces continuing toward camera; no irregular extra kinks, no curved rounded perimeter, no level has different polygon or shifted corners, no cascading setback. Clean precise orderly repeated white slab edges. Keep same number of floors and overall atrium size. Preserve foreground bookshelf/table geometry, floor, cross aisle, desks tight to railing, warm colors and contrast, exact camera, skylight and clean 2D cel shaded drawing. Only correct octagonal geometric alignment, no extra furnishings or text.

自检：远处白色楼板和柱列更整齐，八角转折上下对齐；前景桌架及横向过道保留。用户只指定八角形，并未提供精确边长；提示词采用规则八角形作对齐假设，不能当作真实等边测量结果。远景楼梯局部随规整重绘发生变化，仍待看图审核。

## 验证

实际原图逐张聊天展示；PNG 读取尺寸与 SHA-256，资源台检查五个版本及图数 1/4/3/3/3、零缺失，状态 pending/unselected/not_integrated；git diff --check。无游戏画面修改，不启动游戏截图。技术检查不代替人工概念决定。
