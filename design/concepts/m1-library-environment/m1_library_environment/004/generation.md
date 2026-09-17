# concept_004 · 细节修订，三个视角

2026-09-17；基线 23e0c25。内建 imagegen 编辑同名 003 图片，不覆盖旧图。004 是整套修订版本，文件名区分视角。

用户认可 003 的颜色、光比和大结构，要求修改细节；不是整套概念或正式资产批准。用户说的图 3 是上轮有楼板断接的临时失败输出（exec-599b6570-40f6-42e3-8a8e-1cf08caef48a.png），明确舍弃，未加入资源台；图 4 是修复后的 003/shelf-to-atrium.png。

## atrium-down.png

输入：../003/atrium-down.png。

Edit the provided library concept image keeping its EXACT camera, color palette, exposure/lighting contrast, polygonal atrium, central ground-floor art exhibit, perimeter cafe/water bar and sofa areas. User likes large structure and color. Correct architectural details only. Redraw LEFT SIDE staircase flights coherently: each flight starts at a real landing and ends at the next level landing, consistent step rise and straight wooden handrails, no broken flights, no doubled random steps. Align all corresponding balcony floor slabs, columns and landings across sides into orderly repeated floor levels with consistent floor-to-floor height in perspective. At EACH upper-floor atrium railing bay place a SHORT study table with its SHORT END tight against railing, long axis extending RADIALLY outward from atrium, never tangentially following railing. Long bookcases further out aligned radially too, separated from short desk by walkway. Do not clutter staircase landings. Tables warm wood half-depth partitions with top horizontal board and inset fluorescent light. Do not change ground-floor arrangement, do not add people, UI, text, logos. Same clean 2D cel shading. One image.

实际自检：楼层线更齐，左侧梯段已重绘，重复短桌增加；远景短桌长轴及每个栏杆湾的对应关系不够清楚，不能视为细节验收通过。底层画展、水吧、沙发和主要颜色保留。

## window-corridor.png

输入：../003/window-corridor.png。

Edit provided library image ONLY rotating all tall BOOKSHELF RUNS 90 degrees on the FLOOR. Current tall shelves run wrongly along the ring. Correct shelf long axes to run left-to-right INTO the scene from outer WINDOW WALL at LEFT toward ATRIUM at RIGHT, in the SAME direction as short foreground desk long axes, like radial spokes from atrium center to exterior windows. Literally rotate shelf footprints a quarter turn relative to their current orientation. Tall long shelves must cross the band from window side to atrium side, not march away into image parallel to window wall. Make this change obvious. Keep a cross aisle between short window desks and middle long shelves, and another cross aisle before inner short desks next to railing. Shelf length about SIX desk modules. Preserve camera angle, windows, all building structure, warm palette, lighting contrast, desk construction with half-depth dividers and top inset tube lighting, ground floor exhibition/cafe/sofas, original 2D cel shading. No new people or UI/text. Do NOT simply reproduce input. No other redesign.

实际自检：书架已改变方向，长轴更接近前景桌列，是否满足真实径向布置仍需人工看图；新增书架顶灯并非用户要求，保留为待修偏差。

## shelf-to-atrium.png

输入：../003/shelf-to-atrium.png（上轮图 4）。

Edit this same library image. User likes camera, architecture, warm colors, light/shadow contrast; keep them unchanged. Move the TWO SHORT STUDY DESK RUNS at left and right farther away from camera so their FAR SHORT ENDS TOUCH the timber atrium safety railing, maintaining their radial orientation (long axes recede toward atrium). Then shorten/pull the near end of each short desk back enough to create a clearly visible CROSS WALKWAY separating the far ends of both foreground bookshelf runs from the near ends of the two desk runs. Desired sequence along view: foreground long bookshelf rows -> UNOBSTRUCTED TRANSVERSE WALKWAY 1.2 to 1.5m across -> short desk rows -> railing with desk short ends flush against it -> atrium. Show two obvious pale floor gaps, one between left bookshelf and left desk, other between right bookshelf and right desk, joined through center aisle. No desk remains connected to bookshelf. Keep center aisle unobstructed, continuous solid floor supports railing, no holes. Desk half-depth partitions, top board and inset fluorescent tubes unchanged. Do NOT rotate desks to follow railing; only their SHORT ends touch railing. No people, text, UI. One edited image, same cel-shaded style.

实际自检：短桌移近栏杆，书架与桌位明显分离，横向过道可见；透视下无法精确证明贴合距离，过道宽度是提示词构图目标，不是现场测量。

## 状态与校验

三张原图均已在聊天展示，004 整体 unselected + pending，未接入。只生成修订概念，未制作正式资产。PNG 尺寸与 SHA-256 实测、AssetCatalog.scan 校验路径及状态、git diff --check；不改变游戏画面，不启动运行截图。
