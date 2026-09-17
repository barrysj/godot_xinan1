# concept_005 · 异变三视角生成记录

日期：2026-09-17。工具：Codex 内建 imagegen；模式：分别对 005 最终夜间三视角执行状态编辑。三次调用并行运行，每张仅使用同机位夜景作为 edit target。

## 共同提示词

```text
Use case: style-transfer
Asset type: Cyber Pop Campus game environment concept, library anomaly-state variant
Primary request: Transform this exact nighttime university library into its high-intensity anomaly state: the library's memory index and digital catalog are visibly corrupting physical space.
Style/medium: preserve the source's polished 2D anime-inspired architectural concept art, line quality, materials, and cinematic rendering.
Anomaly language: luminous cyan and magenta data streams travel along selected architectural edges; small network nodes and waveform fragments appear around catalog areas; book spines and exhibition displays locally fragment into ordered digital blocks; a few controlled spatial echoes or misregistered repetitions suggest broken indexing. Use sharp localized glitch and transparent data geometry, not full-screen noise.
Lighting/mood: retain the deep navy night foundation and warm practical lamps, now invaded by high-saturation cyan, magenta, and violet anomaly light. Highest visual intensity of the three states, eerie and beautiful, but still readable as the same library.
Constraints: preserve the exact camera, crop, perspective, floor count, octagonal atrium identity, columns, primary stairs, wooden railings, radial bookshelves, desks, chairs, exhibition, cafe, sofas, plants, doors, and main walkways. Keep all routes readable. No people. No legible text. No logo. No watermark.
Avoid: simple purple filter; full-screen blur or glitch; generic server room; total destruction; darkness that hides the space; changing the camera; replacing the library; moving or removing major furniture; adding characters; covering the whole image with HUD.
```

## 逐图补充与输出

### atrium-down-anomaly.png

保留栏杆俯视、中央画展、水吧、沙发、左侧开敞楼梯和规整楼层；异常集中于展陈画面、部分环廊边缘、穿过中庭的局部数据瀑布与索引弧，不遮挡水吧和动线。

- 内建输出：`exec-3edf356d-d919-44cf-a128-c27932e3dd54.png`
- SHA-256：`21d59930522a25f57e996ec411b1564655b4724bcc3a30b72aa018ff4ff12b7d`

### window-corridor-anomaly.png

保留窗边连续长桌、半深隔断与灯板、径向长书架、书架至栏杆过道和中庭；数据沿书架行列与桌面隔断传播，加入局部书架边缘重复和网络节点，但不阻断过道。

- 内建输出：`exec-be3bcf2a-2516-4a13-b14f-9c361696e8e0.png`
- SHA-256：`c7844a373f17f0f817e2dbec3f059d71247df1ef01e739daf507b9d024529faa`

### shelf-to-atrium-anomaly.png

保留居中书架通道、栏杆边两张短桌、开敞过道、八角楼层和已提亮远处环廊；局部书列转化为发光索引块，细数据流进入中庭，少量远处栏杆发生空间错位，不改变楼层数量。

- 内建输出：`exec-9e25334b-395e-4b76-9ee0-e96929deeeb6.png`
- SHA-256：`cafa366e37f61857cbd20203b994bd5d39e35e66ae900973a7e3ae2c339855e2`

## 自检边界

- 三图均能辨认夜间母版的固定机位、主要家具与动线；异常不依赖单一紫色滤镜。
- imagegen 会对局部小物和栏杆细节作生成式重绘，不能证明逐像素结构一致；人工评审需关注异常密度是否过强、栏杆／楼梯是否漂移以及热点安全区是否仍足够。
- `concept_005_anomaly` 当前待评审；日常批准及夜间候选状态均不自动覆盖本组异变图。
