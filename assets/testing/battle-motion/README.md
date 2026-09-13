# 战斗动画测试素材：未通过样本

状态：**rejected / test only**。使用内置 `image_gen` 生成与编辑；不作为正式角色，不被任何游戏场景引用。`.gdignore` 将本目录排除在 Godot 资源导入之外。保留两个典型未通过样本，供网页端试产时对照。

- `student-proportion-rejected.png`：初次生成，1254×1254，具有真实透明 Alpha，但明显接近立绘比例，不符合战斗 4 头身。
- `student-alpha-rejected.png`：比例修正版，1254×1254，画入棋盘格，角落 Alpha=255，不是真透明，不能接入。
- 对修正版再次要求去除棋盘格后仍未通过，因此停止扩张美术试产，框架和预览继续复用现有占位素材。第三次未通过输出保留在工具原始生成目录，不作为项目交付物。

战斗素材试产提示词和交付步骤见 `docs/prompts/battle-animation-assets.md`。不修改已批准美术，不把这些图登记为 approved。

## 本轮内置工具原始提示词

初次生成：

> Use case: stylized-concept. Asset type: TEST ONLY transparent 2D game character cutout for a Godot animation-framework preview, not final production art. Create ONE full-body young adult campus student, approximately exactly four heads tall, refined simple cel-shaded cartoon with natural readable limbs, not baby chibi. Short dark navy hair, white and navy modern athletic campus jacket with tiny cyan seam accents, dark straight trousers, white sneakers, a small student-card holder and smartwatch. No armor, no fantasy costume or weapon. Neutral alert ready-to-act pose, feet comfortably apart and both fully visible, hands slightly apart from torso, face and body in a mild three-quarter view toward screen right. Clean bold silhouette, restrained highlights, crisp outlines, flat colors and two-tone shading readable at 100 pixels tall. Genuine transparent background and alpha channel, no floor, no cast shadow, no checkerboard drawn into the image, no effects, no text, no labels, no watermark. Square canvas, character centered horizontally; entire head-to-foot silhouette approximately from y=12% to y=88%, with foot-contact baseline at y=88%, generous transparent margin for programmatic movement. Cyber Pop Campus: clean contemporary science-and-engineering campus, white/navy/gray clothing and restrained cyan technology accents, no neon glow or glitch. Deliver just this single sprite.

比例修正（以上图为编辑输入）：

> Edit this single transparent game character cutout. CRITICAL single correction: change the body proportions from the current tall approximately seven-head adult illustration to a FOUR-HEAD-TALL battle sprite. Total head-to-sole height must equal FOUR times the crown-to-chin head height. Keep the same young adult identity, navy hairstyle, expression, white/navy jacket, cyan accents, ID card, trousers, white shoes, smartwatch, three-quarter right facing and crisp cel shading. Enlarge head relative to body and shorten torso/limbs substantially while keeping natural joints and a youthful adult face, not baby chibi. This is a compact stylized game-world character, not a tall fashion illustration. Full body, both feet visible, same simple ready stance. Maintain genuinely transparent background, no text/shadow/effects. Square canvas: crown at y=12%, bottom of sole y=88%, head crown to chin occupies about 19% of entire canvas height so there are exactly four such lengths in the full body. Center horizontally. Do not change clothing design.

透明修正尝试：

> Edit the attached compact campus character test sprite. Remove the ENTIRE gray checkerboard background and replace it with actual transparent alpha (RGBA PNG); the checkerboard is currently baked into pixels and is NOT transparency. Preserve the existing character silhouette, hairstyle, face, compact game-sprite proportions, clothing, pose, colors and both shoes exactly. Only background extraction. Keep the whole square canvas and character position. No shadow, no checkerboard, no solid-colored backdrop. All pixels outside the character must have alpha zero.
