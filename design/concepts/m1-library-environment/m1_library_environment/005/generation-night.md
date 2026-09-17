# concept_005 · 夜间三视角生成记录

日期：2026-09-17。工具：Codex 内建 imagegen；模式：对已批准 005 日常图执行 `lighting-weather` 编辑。三个调用并行执行，每张仅使用对应日常图作为 edit target。

## 共同提示词

```text
Use case: lighting-weather
Asset type: Cyber Pop Campus game environment concept, library state variant
Primary request: Edit the supplied approved daytime library image into a believable nighttime version of the exact same place.
Style/medium: preserve the source's polished 2D anime-inspired architectural concept art and material rendering exactly.
Lighting/mood: night outside every window and skylight; deep navy ambient light; warm practical desk lamps and ceiling lights; restrained cyan and magenta accents only from realistic digital signage or architectural light strips; quiet late-night university library. Night should feel more digitally heightened than daytime but remain a real campus interior.
Constraints: change only time of day, illumination, reflections, and night atmosphere. Preserve the exact camera, crop, perspective, octagonal floor geometry, number and alignment of floors, columns, stairs, wooden railings, radial bookshelves, desks, chairs, exhibition, cafe counter, sofas, plants, doors, and all walkways. Keep every approved spatial relationship unchanged. No people. No text. No logo. No watermark.
Avoid: anomaly effects, glitch, data streams, floating HUD, structural warping, purple color wash, cyberpunk nightclub, added furniture, removed furniture, changed stairs, changed shelf orientation, changed railing spacing, changed floor count.
```

## 逐图补充与输出

### atrium-down-night.png

补充：保留栏杆俯视中庭机位、中央画展、水吧、休闲沙发、左侧开敞楼梯区、规整八角楼层和前景木栏杆；采光顶为清朗夜空与轻微月光。

- 内建输出：`exec-6198e020-b943-4f7b-bc94-1b7a7f7449cc.png`
- SHA-256：`970a9a5a334c59cec8550239266fa8aeaf1a7a9c32517cf9c1c67b0b2daea9ac`

### window-corridor-night.png

补充：保留外窗书桌走廊机位、窗边连续长桌、半深隔断与灯板、径向长书架、书架至栏杆过道及中庭楼层；窗外为少量建筑灯光的校园夜景。

- 内建输出：`exec-d30cf582-4237-4c45-af55-a2992a062124.png`
- SHA-256：`a13d0849d2e360d7af0bcfd53dcf0b63902daeaa1cf36f4ba8c5f97e34a6e062`

### shelf-to-atrium-night.png

补充：保留书架间居中通道、栏杆边两张短桌、书架至栏杆过道、对称八角楼层、书籍和采光顶；暖色桌灯与书架灯对比冷蓝环境光。

- 内建输出：`exec-6e11311c-990c-4abf-8f18-b36d48906ce8.png`
- SHA-256：`45208c298bce73adc486c32cd6597a77195689a4b09b2d70d936f5b6c77b748f`

## 自检边界

- 三张图未加入 glitch、数据流、悬浮 HUD 或结构错位，不冒充异变状态。
- 图像生成不能证明逐像素几何一致；人工评审仍需关注楼梯连接、楼层数量、栏杆节奏、桌架方向和过道宽度是否发生细微漂移。
- `concept_005_night` 当前待评审；日常 `concept_005` 的既有批准不自动覆盖本组夜景。
