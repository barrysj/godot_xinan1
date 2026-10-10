# 归还印章怪 · 来源与当前制作入口

图像来源含Codex内置imagegen；负责人提供的参考、上游模型及许可继续随原资料保留。
当前选用、最终批准状态和接入边界以[Manifest](../../../../../assets/art/manifests/enemy/return_stamp.yaml)为准。

现存参数／处理入口：[build-config.json](build-config.json)、[rig_manifest.json](rig_manifest.json)、[battle_animation.frames.json](battle_animation.frames.json)、[action-cards.json](action-cards.json)、[action-input.json](action-input.json)。源图和输出均随本包保留；重新生成云端图片不保证逐像素复现。

设计与实现说明在相应领域文档就地维护，验证命令见[美术验证](../../../../../docs/art/verification.md)。运行素材使用稳定assets/art路径。

## 原始输入与处理依据

- 工具：内置 imagegen；透明背景。

## 原始生成提示词

### 1 · 两张退场帧整表修改

```text
Local edit ONLY the TWO LAST sprites (bottom-middle death-start and bottom-right death-end) in this transparent 3x3 RETURN STAMP nine-pose atlas. Preserve the other SEVEN sprites exactly as they are, with their already correct FOUR date wheels. The two lying/tipping death sprites must each show EXACTLY FOUR, not five and not three, separate metal date-wheel bands inside the EXISTING brass frame. The bottom-middle currently shows FIVE curved silver bands: reduce to FOUR evenly spaced equal-width silver curved wheel bands, each decorated with simple engraved square marks. The bottom-right currently shows THREE broad wheel bands: subdivide the same axle width into FOUR equally spaced thin silver curved wheel bands. Keep both dead eyes completely dark. Keep the SAME existing rotated brass frame, wood head, collar, two paper arms, rubber base, colors, shading, pose and position; edit only the wheel pixels inside each of these TWO brass frames. Do not add, enlarge or redraw anything else. If the paper arm overlaps the uppermost wheel in the right sprite, retain that natural overlap but make four band divisions evident along the opposite visible edge. The four bands must occupy the SAME total axle width as before. No digits, words, labels, halos, effects, shadows, duplicated objects or background. True RGBA transparency, identical whole canvas and composition. Local surgical correction; the top six poses and bottom-left critical sprite already have EXACTLY FOUR and must remain unchanged.
```

### 2 · 末帧单独修正

```text
Surgical local edit of this ONE transparent dead RETURN STAMP sprite. Preserve the entire drawing, current lying-on-side pose, body, wood head, dark eyes, brass frame and collar, red rubber base at LEFT, wood head at RIGHT, both attached ivory paper arms and their shapes. Only edit the SILVER DATE WHEELS inside the brass middle housing: currently THREE gray horizontal bands are visible stacked from top to bottom. Replace those with EXACTLY FOUR distinct equal-width curved silver horizontal wheel bands stacked top to bottom, occupying the SAME total housing height. Draw four wheels like four separate narrow curved metal sleeves around the same central shaft, with THREE clear dark separation gaps between them. Add simple small engraved rectangles, no digits. Do NOT turn them into vertically striped wheels: in this lying pose their band seams are horizontal, as in the input. Keep the paper-arm overlap at the top, but leave each of the four bands visible at the left edge of the silver housing so all FOUR can be counted. Exactly one dead stamp, no additional objects, no limbs, no glow, no shadows, no background, no labels, no checkerboard. Keep true RGBA transparency and generous safe margins. Identical proportions and outlines; only correct THREE to FOUR date-wheel bands.
```

### 3 · 末帧多余银环材质修正

```text
Extremely small LOCAL material edit. Preserve this entire transparent dead stamp sprite unchanged. In the center silver cylinder, the BOTTOMMOST very thin silver band touching the lower gold frame lip is an erroneous extra fifth wheel. Convert ONLY this lowest thin silver engraved strip into SOLID GOLD BRASS continuous frame lip with NO silver and NO engraved rectangles. The four wider silver wheel bands ABOVE it must remain unchanged. Thus the cylinder contains exactly FOUR silver wheels total, and the lowest thin strip becomes brass frame, not a wheel. Do not add any new silver bands. Do not redraw any wheels, head, eyes, base, frame, receipts, shape, perspective, pose or proportions. Only recolor the lowest narrow silver strip to smooth brass and remove its engraving. Perfect RGBA alpha background, no other changes.
```

### 4 · 日期轮数量修正

```text
Use case: local-edit, identity-preserve. Correct ONLY the date wheel count in this existing transparent nine-pose RETURN STAMP game sprite atlas. The supplied atlas is the edit target and exact identity, composition, pose, outline and palette reference. Keep the SAME nine poses, same three-column three-row arrangement, sprite positions, cell margins, camera, wood handle shapes, angry magenta eyes in living poses, rigid telescoping collars, brass housings, dark red flat rubber bases, and exactly two attached ivory paper arms for each sprite. Each stamp must have EXACTLY FOUR distinct side-by-side metallic date wheels inside its brass housing, with FOUR visibly separated curved gray bands running from left to right. Some sprites currently have only three: insert the missing fourth band by spacing four narrow equal-width wheels within the SAME housing width. Never resize the brass housing or stamp body to accommodate them. All four wheels share the same rigid axle and remain physically attached and equally visible in the front three-quarter living poses. In side-lying death poses show the four bands across the horizontal axle after rotation; do not merge into three bands. Use only simple engraved bars or square marks, NO real digits or letters on the wheels. Do not change the body, poses, expressions, paper arm shapes, mechanical structure, lighting, palette or style; no new cracks, props, eyes, arms, shadows, glow effects, scene, labels, grid lines or checkerboard. Preserve true RGBA transparency and complete uncropped silhouettes. Nine individual complete stamps, 3 by 3, exactly as original except consistently FOUR date wheels. Keep the sprites safely separated in the same layout.
```

### 5 · 完整提示词

```text
Use case: identity-preserve. Asset type: clean transparent RGBA nine-pose atlas for 2D game RETURN STAMP monster, faithful to the attached approved reference. Square atlas, perfectly regular THREE COLUMNS by THREE ROWS, nine isolated full sprites centered inside cells with VERY generous margins, at least 12% cell margin, no cell overlap. True alpha background, no shadows, no grid lines, labels, captions, cubes, enemies, watermarks or detached effects. ONE rigid pear-shaped tall warm brown wood handle with two magenta angry eyes, brass telescoping collar and brass date-wheel housing, EXACTLY FOUR date wheels, ONE dark red rectangular rubber base, exactly TWO ivory receipt-paper arms attached at opposite sides of date housing. No legs, feet, hands, face on base. Fixed 3/4 view turned slightly screen-right, same rigid wood shape and same base proportions all cells. Navy outlines, crisp cel-shaded cream/brass/wood/red materials like reference. Wood never squashes: movement is exclusively TELESCOPING collar translation, same rigid handle height. Row-major poses: 1 idle upright with long collar and paper arms resting; 2 moving small hopping posture base level and paper arms trailing; 3 anticipation handle pushed DOWN into clearly shortened collar, body mechanically compressed, base unmodified; 4 attack stamp base touching imaginary floor FLAT and horizontal, collar fully compressed, rigid handle unchanged, paper arms jolted upward, NO red seal baked into image; 5 recovery base lifts slightly, collar re-extends; 6 cast rigid handle raised up to full collar extension, four date wheels readable as simple bars without real numbers, both paper arms raised outward, magenta eyes brightest; 7 critical slight tilt with one paper arm drooping, dim eyes, small casing crack, still recognizable four wheels; 8 death-start stamp tipping onto side, handle and four wheels attached, eyes extinguished; 9 death-end lying on side, wood handle intact and rigid, red base still attached, paper arms limp. Nine poses same character proportions, each whole silhouette safely inside its cell. Professional clean game sprites, not a concept board.
```

生成配方是制作资料；稳定修订、缺失参数与历史输入的处理见[源资料与版本](../../../../../docs/art/WORKFLOW.md#源资料与版本)。
