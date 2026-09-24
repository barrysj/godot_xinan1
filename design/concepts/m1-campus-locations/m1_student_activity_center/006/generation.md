# 活动中心异常006：可见碎光与青蓝光块

- 日期：2026-09-23；状态：unselected + pending，等待人工确认异常密度，未正式提升或接入。
- 来源：内置 imagegen 局部编辑；模型具体版本未由工具提供。参考005原图作为构图、建筑与天空锁定参考，不作为新版本批准。
- 输入：C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-855e83a1-1a86-48b6-8fc8-0959bb928537.png
- 原始输出：C:\Users\SongJun\.codex\generated_images\01a0b584-23fa-7182-a86e-e1a6a75e0d64\exec-03bec7d2-97b6-4677-ad7f-a8ae04a4f086.png
- 源尺寸1672×941；上下各裁0.25源像素匹配16:9，再用高质量双三次重采样交付3840×2160 RGB不透明PNG。非原生4K，非AI超分。
- SHA256：25F4099E465AB9DDC95C7E06877FCE3E903EFCBEB7F54DDE13DAD3DF677DEA24
- 调整：用户认为005差异不可辨，要求增加碎光、青蓝光块和微弱倒影；新增集中入口中景，不提高天空紫色比例。
- QA：asset_report通过尺寸、格式和不透明检查；实际查看源图及005/006各960px宽对照，新增入口青蓝块与倒影可辨，建筑仍为主体。光块偏透明轮廓感，最终密度及形态待人工评审。没有将提示词数量视为逐一准确执行的保证。
- 来源权利：沿用项目用户提供实景的参考链；不额外声称版权或商用权已核验。
- 对照：../../review/codex-workflow/activity-anomaly-visible-comparison.jpg

## 完整提示词

```text
Use case: precise-object-edit. Image 1 is the strict edit target, a campus student activity center with an already-approved dark ink-blue gray sky. The previous revision was too imperceptible. This revision must add CLEARLY VISIBLE but still localized supernatural fragments, cyan-blue light blocks and faint matching ground reflections. They must read at a 960-pixel-wide preview, not only when zoomed in.

Preserve the sky exactly: low-saturation navy/charcoal with gray clouds, no purple clouds, no new sky effects. Preserve camera framing, entire building geometry, windows, trees, paths, brick pavement and all warm ordinary lights. Preserve the two existing violet arcs and don't enlarge them.

Add THREE modest spatial clusters concentrated around the central glazed entrance and its nearby forecourt:
- Main cluster: 5 distinct translucent cyan/electric-blue rectangular light fragments hovering just in front of the central glazing and doorway. Each fragment is roughly one-quarter to one-half of a visible window pane in size, with solid luminous translucent faces, irregular broken edges and soft cyan glow; no text, icons or HUD borders. They must be unmistakably visible instead of tiny pixel specks.
- Second smaller cluster: 3 cyan-blue shards and 6 short violet/cyan broken light streaks just to the entrance's right at waist to head height, below the roofline.
- Third sparse cluster: 3 small cyan-blue blocks and about 6 tiny broken spark fragments floating low above the paving immediately outside the entrance, with soft elongated blue-violet reflections directly underneath, following the paving perspective. Reflections should be dimmer and softer than the shards, not mirror-floor flooding.
Keep empty gaps between the three clusters. Confine new effects to the middle ground near the entrance; keep most of the plaza, bottom foreground and the entire sky untouched. All clusters together are visually subordinate to the campus architecture; no portal, huge vortex, full-building neon outlines, sky rain or blanket ground circuitry. Give the added shapes enough contrast and size to be obvious relative to Image 1 without increasing overall scene saturation or brightening the sky.
No people, signs, text, UI, logos, flags or watermarks. One standalone complete 16:9 illustrated scene, no collage. Requested actual output 3840x2160 PNG, highest available detail.
```
