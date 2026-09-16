# 007 两个热点图标语义修订

使用 game-ui-ux 的小尺寸可读性与形状独立辨识原则评审；使用内置 imagegen 编辑 006 两图，不改其他资产。人物改通用人形＋对话框，守卫改凶恶简笔敌人脸，去除盾牌与感叹号。待人工评审，未接入游戏。人物框相对旧版略放大，边框辉光仍偏强；实际56px辨识度、与其余图标的视觉重量统一及焦点状态尚待运行检查。透明原图完整复制，无程序重绘。

## character

输入：../006/character.png（编辑目标）。

完整提示词：

Use case: precise-object-edit. Edit supplied game UI badge. Preserve its square canvas, transparent exterior, dark blue glass backing and clipped upper-right corner, cyan/ice-white palette and premium smooth antialiased finish. Replace ALL central portrait, hair, clothing, orbit rings with ONE extremely simple pictogram communicating TALK TO A PERSON: a featureless round head and single rounded shoulder shape in lower-left, plus a large clear speech bubble in upper-right with a tail pointing toward the person. Bubble contains only two short bold horizontal strokes. No face, hair, clothes, gender, portrait detail, orbital lines or stars. Readable at 56px. Flatten central symbol to solid ivory with restrained cyan rim, reduce backing reflections and rim glow so the central silhouette dominates. Generous spacing between head and speech bubble, balanced unified symbol. No text, letters, numbers. Actual alpha transparency outside badge, no background. One icon only.

## guardian

输入：../006/guardian.png（编辑目标）。

完整提示词：

Use case: precise-object-edit. Edit supplied game UI badge. Preserve square canvas, actual transparent exterior, dark blue-purple glass backing and clipped upper-right corner, magenta rim and pale yellow symbol palette. REMOVE shield and exclamation mark completely. Replace with ONE very simple fierce enemy head pictogram: compact angular shadow creature face silhouette with two sharply downward-slanted hostile eyes and a simple jagged mouth with two triangular fangs. Bold iconic flat graphic, 5 or fewer major shapes, no body, no clothes, no armor, no detailed character portrait. Must read ENEMY / COMBAT at 56px, not quest, warning notice or security protection. Keep only three tiny short magenta electrical strokes pointing toward the head, secondary to face. Reduce rim brightness and glass reflections so face dominates. Smooth antialiased premium anime-campus anomaly game UI. No skull, shield, punctuation, letters, text, numbers, full scene or drawn checkerboard. Actual transparent alpha outside badge. One icon only.

