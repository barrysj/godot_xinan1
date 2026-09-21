# 学生活动中心 · 日常4K候选与配对异常

日期：2026-09-22。阶段：资产候选，未获人工批准、未提升、未接入。

## 日常 asset_daily_002

- 文件：daily.png
- 参考用途：现有 asset_daily_001 用于保持同一地点的构图、身份和日常表现。
- 参考：C:/Users/SongJun/.codex/worktrees/6e21/godot_xinan1/assets/art/backgrounds/m1_campus_locations/student_activity_center/daily.png
- 生成工具：Codex 内置 imagegen；未回报可核实模型版本，不推定为 image 2.5。
- 原始输出：C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-e0b5e4bd-be39-4fc7-b2b1-f425fd369851.png
- 原始尺寸：1672×941；交付：3840×2160 RGB、不透明 PNG。
- 处理：System.Drawing HighQualityBicubic，中心等比裁切至16:9，源上下各裁 0.25 像素再放大；不是原生4K，也不是AI超分。
- 最终 SHA-256：29E723AD9E07E5C3A3A192660EB2810FD9EC0B0A8B1EFB309FC4C0468D67204F
- 原文件保留在上述路径；重编码可能不保留内嵌元数据，来源在本记录及批次索引保留。
- 公开或商业再分发权限尚未单独核验。

### 完整提示词

```text
Use case: precise-object-edit. Produce ONE standalone finished 16:9 campus game background, requested output resolution 3840x2160 pixels, highest available detail, not a collage. Image 1 is the approved daily background and the strict composition/identity edit target. Restore and refine it into a detailed clean daily master. Location: 学生活动中心. Preserve exactly its camera, vanishing point, building silhouettes, floor count, window spacing, trees, paths, ramps, landscape placement and the apparent distance of far buildings. low red brick rounded facade on the left, central glazed entrance, generous paved plaza, road receding on right. Keep the same polished 2D illustrated campus environment style and existing sunny daytime color palette: blue sky, natural green foliage, pale cream masonry, delicate clean architectural lines, soft ambient shadows. Refine fine material and edge detail without inventing structural features. Far windows remain small. No new people, cars, signs, readable text, school logo, flags, flagpoles, UI, watermark, neon, glowing seams or supernatural effects. Keep the lower foreground open. Match the existing wide framing, no zoom or recompose. Save one full-frame PNG, 3840x2160 requested.
```

## 异常 asset_anomaly_003 · 墨蓝灰天空校准样图

- 文件：anomaly.png；本批唯一已修正天空的异常样图，待负责人确认后扩展到其余11处。
- 参考：C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-479985b8-1ebd-49f2-af69-840e149a537f.png；定向编辑天空并微调天光溢色，锁定建筑、道路和双光弧位置。
- 前一中间稿：因用户反馈“天空过于紫色了”不再作为整批目标；对照保存在 review/codex-workflow/sky-calibration-before.png。
- 原始输出：C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-ad6294a1-65a4-4d5c-8a87-ab2e5bb940d0.png；原始尺寸：1672×941。
- 最终：3840×2160 RGB PNG，高质量双三次重采样而非原生4K；SHA-256：7C3A42F03E423D5EEF72D502581422E4D940CBF540745481E32F657B72DF0C37。
- 使用限制：仅为天空颜色校准，既不是资产批准，也不是24张已完成。

### 完整天空修订提示词

```text
Use case: precise-object-edit / color correction. Edit this ONE existing campus student activity center anomaly background. The user's correction is specifically "the sky is too purple." Produce one standalone 16:9 image, requested native 3840x2160 or maximum available resolution.

CHANGE: The entire SKY ONLY must become a quiet, low-saturation near-black navy night sky, midnight ink-blue #0B1423 to charcoal steel-blue #243144, with subdued neutral slate-gray clouds. Reduce sky saturation greatly and make the cloud/horizon glow much dimmer. No lavender, purple, violet, magenta or pink colored cloud banks, no purple horizon gradient, no bright Milky Way, no aurora, no sky rift or celestial fantasy display. A few very faint neutral stars are fine. The sky should recede into the background rather than be the biggest colorful feature.

PRESERVE: the exact rounded brick facade on the left, all architecture, windows, entrances, plaza paving perspective, trees, receding road on the right, camera angle, framing and illustration rendering. Retain a restrained black-plum atmosphere in building shadows and foreground, warm ordinary window lights, and the same TWO small violet transmission arcs just above the central entrance. These localized arcs are the brightest violet accents. Keep their size and location; do not add any effects. The building and plaza should remain clearly visible with muted cool-neutral moonlight; only minimally reduce purple skylight spill so the new sky physically fits. Do NOT turn the whole scene uniformly blue or remove the anomaly state. Do NOT redesign buildings, foliage or pavement. No new people, text, UI, logos, flags, watermarks. No side-by-side or collage. Requested final resolution 3840x2160.
```
