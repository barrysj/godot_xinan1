# 009 异变事件热点资产

用户反馈008图标过于中规中矩、像PPT；本版按“图标不是按钮，而是正在发生的事件”重做。使用内置 imagegen，一项资产一次生成。四图均为独立RGBA，不带文字、不带统一方形底座；运行时仍使用规则透明点击区。

最终交付：memory 使用首轮后定向简化结果；character 使用首轮结果；terminal 使用首轮后语义纠正结果；guardian 使用首轮后缩短电击结果。未接入游戏，待人工资产评审。

## 首轮提示词

### memory

Use case: stylized-concept
Asset type: production game exploration hotspot marker
Style/medium: polished flat 2D anime game UI glyph with subtle translucent holographic layers; Cyber Pop Campus anomaly layer
Color palette: blue-black translucent fragments, ivory symbol, cyan #00F0FF edge light; only combat may use magenta #FF2DAA and warning yellow #F7EA39
Composition: one asymmetrical free-floating marker centered on a square transparent canvas, strong readable silhouette at 56 pixels, visual mass occupies about 62 percent of canvas
Materials: thin luminous glass shards and clean graphic shapes, restrained narrow glow, smooth antialiased edges
Constraints: genuinely transparent RGBA outside the marker; no uniform badge, no square or circular backing plate, no enclosing border, no app-icon container, no label, no text, no letters, no numbers, no presentation card, no scene, no mockup, no watermark; the irregular art silhouette must remain inside a larger invisible rectangular click area at runtime
Avoid: PPT icon, mobile app icon, centered symbol inside a box, thick glass tile, heavy 3D bevel, realistic object, excessive details, broad glow, circuit clutter
Primary request: CAMPUS MEMORY event marker. Two overlapping instant-photo fragments at slightly different angles, one cropped and offset behind the other. The front fragment contains only an extremely simple abstract campus roofline and one small memory shimmer. One corner dissolves into three tiny horizontal cyan scan fragments, suggesting an unstable recovered memory. The photo pieces themselves form the free silhouette; no background badge. Elegant and slightly broken, not cute, not an image-gallery app icon.

### character

Use case: stylized-concept
Asset type: production game exploration hotspot marker
Style/medium: polished flat 2D anime game UI glyph with subtle translucent holographic layers; Cyber Pop Campus anomaly layer
Color palette: blue-black translucent fragments, ivory symbol, cyan #00F0FF edge light; only combat may use magenta #FF2DAA and warning yellow #F7EA39
Composition: one asymmetrical free-floating marker centered on a square transparent canvas, strong readable silhouette at 56 pixels, visual mass occupies about 62 percent of canvas
Materials: thin luminous glass shards and clean graphic shapes, restrained narrow glow, smooth antialiased edges
Constraints: genuinely transparent RGBA outside the marker; no uniform badge, no square or circular backing plate, no enclosing border, no app-icon container, no label, no text, no letters, no numbers, no presentation card, no scene, no mockup, no watermark; the irregular art silhouette must remain inside a larger invisible rectangular click area at runtime
Avoid: PPT icon, mobile app icon, centered symbol inside a box, thick glass tile, heavy 3D bevel, realistic object, excessive details, broad glow, circuit clutter
Primary request: CHARACTER INTERACTION event marker. A very simple featureless person bust made from one round head and one shoulder shape, offset lower-left, intersecting a large speech bubble offset upper-right. The speech bubble tail clearly points toward the person and contains exactly two short bold horizontal signal strokes. Add two tiny detached cyan signal fragments along one edge. The overlapping person and bubble form a dynamic diagonal free silhouette; no background badge. Communicates an active conversation, not a profile, contact card, portrait or character selection.

### terminal

Use case: stylized-concept
Asset type: production game exploration hotspot marker
Style/medium: polished flat 2D anime game UI glyph with subtle translucent holographic layers; Cyber Pop Campus anomaly layer
Color palette: blue-black translucent fragments, ivory symbol, cyan #00F0FF edge light; only combat may use magenta #FF2DAA and warning yellow #F7EA39
Composition: one asymmetrical free-floating marker centered on a square transparent canvas, strong readable silhouette at 56 pixels, visual mass occupies about 62 percent of canvas
Materials: thin luminous glass shards and clean graphic shapes, restrained narrow glow, smooth antialiased edges
Constraints: genuinely transparent RGBA outside the marker; no uniform badge, no square or circular backing plate, no enclosing border, no app-icon container, no label, no text, no letters, no numbers, no presentation card, no scene, no mockup, no watermark; the irregular art silhouette must remain inside a larger invisible rectangular click area at runtime
Avoid: PPT icon, mobile app icon, centered symbol inside a box, thick glass tile, heavy 3D bevel, realistic object, excessive details, broad glow, circuit clutter
Primary request: LIBRARY TERMINAL event marker. A thin floating terminal screen light-slab tilted only a few degrees, with one offset lower support shard and two short broken scanning lines crossing the screen. A small data pulse exits one side as two detached cyan fragments. The monitor and scan pieces form a free asymmetrical silhouette; no background badge. Feels like an accessible corrupted terminal in the environment, not a desktop-computer app icon.

### guardian

Use case: stylized-concept
Asset type: production game exploration hotspot marker
Style/medium: polished flat 2D anime game UI glyph with subtle translucent holographic layers; Cyber Pop Campus anomaly layer
Color palette: blue-black translucent fragments, ivory symbol, cyan #00F0FF edge light; only combat may use magenta #FF2DAA and warning yellow #F7EA39
Composition: one asymmetrical free-floating marker centered on a square transparent canvas, strong readable silhouette at 56 pixels, visual mass occupies about 62 percent of canvas
Materials: thin luminous glass shards and clean graphic shapes, restrained narrow glow, smooth antialiased edges
Constraints: genuinely transparent RGBA outside the marker; no uniform badge, no square or circular backing plate, no enclosing border, no app-icon container, no label, no text, no letters, no numbers, no presentation card, no scene, no mockup, no watermark; the irregular art silhouette must remain inside a larger invisible rectangular click area at runtime
Avoid: PPT icon, mobile app icon, centered symbol inside a box, thick glass tile, heavy 3D bevel, realistic object, excessive details, broad glow, circuit clutter
Primary request: HOSTILE GUARDIAN combat marker. A bold fierce shadow-creature head made from no more than five major graphic shapes: angular broken outer head contour, two sharply downward hostile yellow eyes, one jagged mouth with two fangs. Three short magenta lightning slashes point inward from uneven distances, leaving open gaps around the head. Free aggressive silhouette with no shield, exclamation mark or background badge. Communicates enemy and combat immediately, not security, warning, quest, mission or event.

## 定向修订提示词

### memory

Use case: precise-object-edit. Image 1 is the edit target.
Keep the two overlapping tilted broken instant-photo fragments, asymmetrical free silhouette, transparent exterior, cyan/ivory palette and dissolution fragments.
Change only the detailed campus picture inside the front photo: replace it with an extremely simple bold abstract campus memory pictogram made of one roofline, one short tower rectangle and one luminous circular clock dot, using no more than six large shapes. Remove trees, clouds, window details, cracks crossing the picture, photographic depth and scenery detail. Reduce glass cracks overall. Preserve the small memory shimmer and the broken right corner.
The marker must remain readable at 56px. No square background badge, no text, no watermark. Keep actual transparent alpha outside.

### terminal

Use case: precise-object-edit. Image 1 is the edit target.
Keep the free asymmetrical floating glass screen silhouette, tilted a few degrees, detached support shard, transparent exterior, cyan/blue-black palette, scan fragments and polished smooth edges.
Remove the book symbol, star, circular reticle and all tiny dashboard decoration completely. Replace them with one unmistakable LIBRARY TERMINAL display glyph: a bold ivory horizontal data waveform, a small cyan cursor block at its end, and two short interrupted scan lines. Use only large simple shapes, readable at 56px.
Reduce frame detail and glow slightly. It must communicate corrupted computer terminal, not book, reading, education or app icon. No backing badge, text, letters, numbers or watermark. Keep actual transparent alpha outside.

### guardian

Use case: precise-object-edit. Image 1 is the edit target.
Keep the fierce angular shadow-creature head, hostile yellow eyes, jagged fanged mouth, free asymmetrical silhouette, transparent exterior and cyan/magenta/yellow palette.
Change only the magenta electricity: replace the three huge blade-like bolts with three very short thin lightning slashes, each less than one quarter of the head width, positioned around different sides and pointing inward toward the face. Leave wide transparent gaps. The enemy head must clearly dominate.
Simplify the outer head silhouette slightly so it stays readable at 56px. No shield, exclamation mark, badge, text, letters, numbers, watermark or background. Keep actual transparent alpha outside.

## 检查与边界

四张文件均为1254×1254 RGBA，Alpha最小值0、最大值255。已看图检查语义：记忆为破碎照片，人物为人物与对话框叠合，终端为扫描波形屏幕，守卫为敌人脸与三根短电击。当前只检查资产大图与透明通道；56px实际运行清晰度、视觉重量、焦点／完成状态和多分辨率布局须在人工认可资产方向后另行接入验证。

