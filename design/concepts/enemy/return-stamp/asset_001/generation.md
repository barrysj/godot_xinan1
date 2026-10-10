# 资产生成记录

## 资产阶段收尾（2026-10-07）

负责人决定：“已生成资产”用选择框筛选、而不是标签。只保留最新一版，并提升为正式资产。本文件保存 tmp_002 制作时的完整提示词与来源；该整套现为已批准的 asset_001。历史过程用语不表示当前审批状态。正式运行子集由白名单提升，源稿、动作卡、GIF 与预览单位留在生产资料中。



### 退场两姿势定向修正及复核

整表第一次修正的七个非死亡姿势保持四轮；失稳和退场分别选用后续局部修正，源稿均保留。归一化只作裁取和等比缩放，没有手绘轮子或修改源像素。末帧尺度按原末帧完整外轮廓宽度和地面锚点匹配。三次输入／输出如下：

#### 两张退场帧整表修改

- 工具：内置 imagegen；透明背景。
- 输入：source/poses-four-wheels.png；输出：source/poses-death-wheel-attempt.png；原文件：exec-e4b79615-daaf-4b90-820f-4c48ddbf8537.png。
- 复核：仅提取 fall；末帧轮轴方向仍错，不作为 death 输入。

完整提示词：

Local edit ONLY the TWO LAST sprites (bottom-middle death-start and bottom-right death-end) in this transparent 3x3 RETURN STAMP nine-pose atlas. Preserve the other SEVEN sprites exactly as they are, with their already correct FOUR date wheels. The two lying/tipping death sprites must each show EXACTLY FOUR, not five and not three, separate metal date-wheel bands inside the EXISTING brass frame. The bottom-middle currently shows FIVE curved silver bands: reduce to FOUR evenly spaced equal-width silver curved wheel bands, each decorated with simple engraved square marks. The bottom-right currently shows THREE broad wheel bands: subdivide the same axle width into FOUR equally spaced thin silver curved wheel bands. Keep both dead eyes completely dark. Keep the SAME existing rotated brass frame, wood head, collar, two paper arms, rubber base, colors, shading, pose and position; edit only the wheel pixels inside each of these TWO brass frames. Do not add, enlarge or redraw anything else. If the paper arm overlaps the uppermost wheel in the right sprite, retain that natural overlap but make four band divisions evident along the opposite visible edge. The four bands must occupy the SAME total axle width as before. No digits, words, labels, halos, effects, shadows, duplicated objects or background. True RGBA transparency, identical whole canvas and composition. Local surgical correction; the top six poses and bottom-left critical sprite already have EXACTLY FOUR and must remain unchanged.

#### 末帧单独修正

- 工具：内置 imagegen；透明背景。
- 输入：source/death-edit-input.png；输出：source/death-four-wheel-attempt.png；原文件：exec-4a153eea-4082-4f59-a077-4653ec0d8e0e.png。
- 复核：产生第五条窄银轮，仍未通过。

完整提示词：

Surgical local edit of this ONE transparent dead RETURN STAMP sprite. Preserve the entire drawing, current lying-on-side pose, body, wood head, dark eyes, brass frame and collar, red rubber base at LEFT, wood head at RIGHT, both attached ivory paper arms and their shapes. Only edit the SILVER DATE WHEELS inside the brass middle housing: currently THREE gray horizontal bands are visible stacked from top to bottom. Replace those with EXACTLY FOUR distinct equal-width curved silver horizontal wheel bands stacked top to bottom, occupying the SAME total housing height. Draw four wheels like four separate narrow curved metal sleeves around the same central shaft, with THREE clear dark separation gaps between them. Add simple small engraved rectangles, no digits. Do NOT turn them into vertically striped wheels: in this lying pose their band seams are horizontal, as in the input. Keep the paper-arm overlap at the top, but leave each of the four bands visible at the left edge of the silver housing so all FOUR can be counted. Exactly one dead stamp, no additional objects, no limbs, no glow, no shadows, no background, no labels, no checkerboard. Keep true RGBA transparency and generous safe margins. Identical proportions and outlines; only correct THREE to FOUR date-wheel bands.

#### 末帧多余银环材质修正

- 工具：内置 imagegen；透明背景。
- 输入：source/death-four-wheel-attempt.png；输出：source/death-four-wheels.png；原文件：exec-f6aad199-a0f0-48f3-8e70-e27a02340660.png。
- 复核：最下窄银带改为光滑黄铜支框，最终四只银轮可数；当前 death 输入。

完整提示词：

Extremely small LOCAL material edit. Preserve this entire transparent dead stamp sprite unchanged. In the center silver cylinder, the BOTTOMMOST very thin silver band touching the lower gold frame lip is an erroneous extra fifth wheel. Convert ONLY this lowest thin silver engraved strip into SOLID GOLD BRASS continuous frame lip with NO silver and NO engraved rectangles. The four wider silver wheel bands ABOVE it must remain unchanged. Thus the cylinder contains exactly FOUR silver wheels total, and the lowest thin strip becomes brass frame, not a wheel. Do not add any new silver bands. Do not redraw any wheels, head, eyes, base, frame, receipts, shape, perspective, pose or proportions. Only recolor the lowest narrow silver strip to smooth brass and remove its engraving. Perfect RGBA alpha background, no other changes.


## tmp_002 定向修改（2026-10-07）

- 负责人反馈：图书管理员攻击与施法不明显；每个敌人施法必须有光效。
- 本版保留 tmp_001 九姿势源图和弹体作为基底，批准概念版本未改变。
- 光效使用 Godot 原生双色 Line2D 光环、径向短光线与 AnimationLibrary；未绘制额外位图，释放峰值与现有动作时钟同步，其他状态复位为透明。试渲染中发现大面积柔光在 GIF 中发灰，最终版移除柔光面，只保留清晰亮边与脉冲。
- 修订制作时为未批准候选；2026-10-07 负责人批准只保留本版，正式留存为 asset_001，旧 tmp_001 已按授权清理。

### 日期轮数量修正

通用质量闸门发现原九姿势中部分姿势只有三只日期轮，违反动作卡的四轮身份锁。原输入保留为 source/poses.png；imagegen 定向编辑为 source/poses-four-wheels.png，原输出 exec-69cfb82a-022c-4f54-8aee-d27a4d275b0e.png。当前构建明确读取修正稿，不覆盖原始稿。参考用途为原图身份、比例、线稿与全部姿势；只要求统一轮数，不引入新设计。

完整修正提示词：

Use case: local-edit, identity-preserve. Correct ONLY the date wheel count in this existing transparent nine-pose RETURN STAMP game sprite atlas. The supplied atlas is the edit target and exact identity, composition, pose, outline and palette reference. Keep the SAME nine poses, same three-column three-row arrangement, sprite positions, cell margins, camera, wood handle shapes, angry magenta eyes in living poses, rigid telescoping collars, brass housings, dark red flat rubber bases, and exactly two attached ivory paper arms for each sprite. Each stamp must have EXACTLY FOUR distinct side-by-side metallic date wheels inside its brass housing, with FOUR visibly separated curved gray bands running from left to right. Some sprites currently have only three: insert the missing fourth band by spacing four narrow equal-width wheels within the SAME housing width. Never resize the brass housing or stamp body to accommodate them. All four wheels share the same rigid axle and remain physically attached and equally visible in the front three-quarter living poses. In side-lying death poses show the four bands across the horizontal axle after rotation; do not merge into three bands. Use only simple engraved bars or square marks, NO real digits or letters on the wheels. Do not change the body, poses, expressions, paper arm shapes, mechanical structure, lighting, palette or style; no new cracks, props, eyes, arms, shadows, glow effects, scene, labels, grid lines or checkerboard. Preserve true RGBA transparency and complete uncropped silhouettes. Nine individual complete stamps, 3 by 3, exactly as original except consistently FOUR date wheels. Keep the sprites safely separated in the same layout.

- 日期：2026-10-07；工具：内置 imagegen。
- 概念依据：docs/art/tasks/m1-enemy-animation.md 与原对象 concept 版本。
- 生成原图：exec-76318028-e127-4e36-b747-5a4beba27de4.png
- 资产阶段临时候选，未批准、未正式接入。
- 三视图替代／单视角制作依据：负责人当前对话确认。

## 完整提示词

Use case: identity-preserve. Asset type: clean transparent RGBA nine-pose atlas for 2D game RETURN STAMP monster, faithful to the attached approved reference. Square atlas, perfectly regular THREE COLUMNS by THREE ROWS, nine isolated full sprites centered inside cells with VERY generous margins, at least 12% cell margin, no cell overlap. True alpha background, no shadows, no grid lines, labels, captions, cubes, enemies, watermarks or detached effects. ONE rigid pear-shaped tall warm brown wood handle with two magenta angry eyes, brass telescoping collar and brass date-wheel housing, EXACTLY FOUR date wheels, ONE dark red rectangular rubber base, exactly TWO ivory receipt-paper arms attached at opposite sides of date housing. No legs, feet, hands, face on base. Fixed 3/4 view turned slightly screen-right, same rigid wood shape and same base proportions all cells. Navy outlines, crisp cel-shaded cream/brass/wood/red materials like reference. Wood never squashes: movement is exclusively TELESCOPING collar translation, same rigid handle height. Row-major poses: 1 idle upright with long collar and paper arms resting; 2 moving small hopping posture base level and paper arms trailing; 3 anticipation handle pushed DOWN into clearly shortened collar, body mechanically compressed, base unmodified; 4 attack stamp base touching imaginary floor FLAT and horizontal, collar fully compressed, rigid handle unchanged, paper arms jolted upward, NO red seal baked into image; 5 recovery base lifts slightly, collar re-extends; 6 cast rigid handle raised up to full collar extension, four date wheels readable as simple bars without real numbers, both paper arms raised outward, magenta eyes brightest; 7 critical slight tilt with one paper arm drooping, dim eyes, small casing crack, still recognizable four wheels; 8 death-start stamp tipping onto side, handle and four wheels attached, eyes extinguished; 9 death-end lying on side, wood handle intact and rigid, red base still attached, paper arms limp. Nine poses same character proportions, each whole silhouette safely inside its cell. Professional clean game sprites, not a concept board.
