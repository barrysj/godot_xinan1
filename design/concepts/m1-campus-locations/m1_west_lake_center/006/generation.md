# m1_west_lake_center 异常候选 006

- 日期：2026-09-24；状态：unselected + pending，仅候选，不代表资产批准或 Godot 接入。
- 负责人反馈：去除重复圆弧形发光光环；增加霓虹裂缝、局部数据雨，并把碎片与投影分布到地面；图书馆作为 Boss 区提高异常强度。
- 来源工具：Codex 内置 imagegen 两步局部编辑。第一步以上一版异常图为严格身份与构图目标，去掉悬浮圆环并加角状裂缝／数据雨；第二步以第一步结果为严格目标，增加透视正确的地面碎片与投影。两步中间稿未登记成独立资产版本。
- 上一版输入：C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-1f3bf464-e317-498a-a3c5-ae01d544b12a.png
- 去圆环中间稿：C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-fdbb9130-b4ff-4bf7-9108-6aea7fd62703.png
- 最终生成源：C:/Users/SongJun/.codex/generated_images/01a0b584-23fa-7182-a86e-e1a6a75e0d64/exec-df72ad9d-65d8-43fe-8cae-93e011a030c2.png
- 水面风格参考：E:/Documents/works/godot_xinan1/assets/art/backgrounds/m1_main_menu/anomaly/library-two-digital-swans.png；仅借用断续青蓝／品红水纹、碎光与倒影，不借用建筑、天鹅与天空。
- 输出：design/concepts/m1-campus-locations/m1_west_lake_center/006/anomaly.png；源 1672×941；交付 3840×2160 RGB 不透明 PNG。按 16:9 中心微裁并以高质量双三次重采样；非原生 4K、非 AI 超分。
- SHA-256：E5804E927E1C49632006EDD0FA4C94B77722837670A8B722047B5B0AB282C757
- QA：两步生成源已目检，未见悬浮发光圆环；建筑与深蓝灰天空保持可辨，地面有断续碎光／投影。文件解码／尺寸／不透明度及资产目录一致性另见批次验证。最终审美与资产批准仍待负责人。
- 来源权利：沿用用户提供实景的参考链，未额外核验公开／商业再分发权利。

## 第一步完整提示词

```text
Use case: precise-object-edit. Image 1 is the STRICT edit target: the current West Lake wooden boardwalk and pergola campus anomaly background. Image 2 is a WATER-EFFECT STYLE REFERENCE ONLY: digital two-swans image. Use ONLY the segmented cyan / magenta / occasional warm-white reflections, broken pixel-like ripples and luminous refracted shards ON THE WATER from Image 2. Do not copy the library building, sunsets, flags, characters, swans or sky from Image 2. Keep Image 1's exact camera, original landforms, buildings, trees, boardwalk/rock sculpture and low-saturation charcoal ink-blue cloudy sky. Completely remove the existing FLOATING PURPLE CIRCULAR ARC / SEMICIRCLE halo near the lake beside the wooden boardwalk and long pergola, filling behind it with natural architecture, vegetation or sky. There must be zero luminous circular arcs or ring-shaped portals anywhere. Replace the repeated ring motif with a connected but broken patch of cyan, deep blue and restrained magenta pixel-like wave facets on 20-30% of the visible water near the far shore and boardwalk edge; its blue-violet glints should stretch in perspective across the water; a few short vertical data streaks under the pergola and one jagged neon fissure at the shore. The data rain is sparse: a few short thin vertical cyan/violet falling symbols, localized below roofline or immediately above water, not across the whole sky. Water effect is clearly visible even in a 960-pixel-wide preview, but much of lake stays dark and realistic; reflections follow the water plane, not straight glossy floor stripes. Preserve all existing 4-6 cyan fragments that are already there if they fit; remove only any conflicting ring pieces. Keep a restrained black-purple night atmosphere, legible campus identity, and quiet near foreground. No giant portal, data rain filling sky, blanket neon water, extra buildings, text, UI, logos or watermark. One complete standalone 16:9 game background. Request 3840x2160 PNG, highest available detail.
```

## 第二步完整提示词

```text
Edit the attached campus anomaly scene, preserving the exact buildings, landscape, dark neutral ink-blue sky, and existing angular neon fissures. The anomaly is too confined to vertical surfaces. Spread additional scattered anomaly on wooden boardwalk and immediate lakeshore, while retaining segmented cyan-magenta digital ripple reflections ON lake water from the prior image: 8-15 separated small irregular cyan-blue and muted magenta luminous shards actually touching the ground at different distances, 2-3 faint broken geometric projections obeying the ground-plane perspective, gentle disconnected shadows and glints beneath fragments. Keep broad empty dark areas and recognizable paths; don't make uniform confetti, continuous circuits, large mirror fields or big glowing puddles. On the lake scene, preserve real shoreline and digital broken ripple reflections; no swans. Sparse short data rain only near architecture or vegetation. Absolutely no floating luminous circular arcs, halos, semicircles or rings. No all-purple sky, no giant portal, no text or UI. 16:9 finished game background.
```
