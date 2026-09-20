# M1 Campus Hub UI · 圆形校准节点资产 008 生成记录

- 任务：`m1-campus-hub-ui`
- 对象：`m1_campus_hub_ui`
- 生成日期：2026-09-20
- 工具：Codex 内置 `imagegen`。
- 阶段：正式资产候选；`unselected + pending + not_integrated`。
- 家族种子：已批准的 `asset_007`。
- 用途：校园地图节点、终端进度环路、状态卡角标。
- 生成输出：`C:\Users\SongJun\.codex\generated_images\01a0b584-0319-7642-a1a4-4f761dc88d88\exec-ef68b7e9-12cf-40f1-a6e8-1debb3e0aabf.png`
- 仓库副本：`design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/asset_008/campus_hub_calibration_node_asset_008.png`
- 参考：`asset_007` 与已批准的 `assets/art/icons/m1_memory_artifact/cyan_magenta.png`；只继承材质、配色和边缘语言。
- 外部来源：无；未使用文字、Logo、学校标记或水印。

## 完整生成提示词

```text
Generate one compact supporting UI component, not a badge and not a miniature of the reference.

Asset: “Calibration Node”, a small sensor used as a single dot on a map or progress line. The output must contain exactly ONE small object, centered, occupying about 30–40% of the square canvas. It must be much smaller and simpler than the referenced assets.

Design only a manufactured circular sensor puck: a dark navy round bezel, one small rounded blue glass lens in the center, a thin cyan rim, one tiny muted amber indicator notch, and two short rounded cyan contact bars on opposite sides. The housing may have a subtle 3D bevel and metal/ceramic thickness. It should read as a technical campus calibration sensor at 48–64 px.

Use the approved family seed only for palette and edge language: deep cobalt/navy, pale cyan, restrained amber, clean manufactured geometry. Use the memory terminal only for the small blue glass material and reflection.

Do NOT reproduce the large circular badge, outer segmented ring, orbit tracks, central large orb, cross-shaped supports, radial architecture, large decorative ring, or any full-size composition from either reference. The final image must not contain any other object.

Strict exclusions: crystal, diamond, gemstone, shard, spike, magic aura, starfield, text, letters, numbers, labels, logos, school marks, readable glyphs, panels, buttons, scenery, characters, cables, ground shadow, watermark, signature, sprite sheet, collage. True transparent RGBA background, square canvas, generous padding, all parts inside canvas.
```

## image-quality-check

```yaml
quality_result:
  schema_version: 1
  task_id: m1-campus-hub-ui-calibration-node-asset-008
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: NOT_APPLICABLE
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS
  failures: []
  notes:
    - 最终输出为单一圆形技术节点，未登记首轮跑偏的缩小徽章版本。
    - 深蓝金属环、蓝色玻璃镜面、青色接触条和暖金校准灯与 007 家族一致。
    - 轮廓适合 48–64px，但小尺寸下应优先保留外环和中心镜面，不依赖细小灯带传达状态。
  repair_directives: []
  next_step: accept
```

## 实测属性

- 尺寸：1254×1254。
- 像素格式：`Format32bppArgb`。
- 透明度：四角 alpha `0,0,0,0`；中心主体 alpha `253`。
- 文件大小：688,743 bytes。
- SHA-256：`5896B8AC4DA86D8DE355D25FF30489BEBF05B7AEBCBD93600917DB697E9D7E62`。
- 当前结论：可进入人工资产评审；未获得选择、批准或 Godot 接入授权。
