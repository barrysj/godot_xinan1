# M1 主菜单视觉样板 · 概念 003

## 修订来源与边界

- 生成工具：Codex 内置 `image_gen`，使用编辑模式完成定向对象移除。
- 生成日期：2026-09-20。
- 编辑目标：`design/concepts/m1-main-menu/m1_main_menu_visual/002/ginkgo-main-building.png`。
- 项目副本：`ginkgo-main-building.png`。
- 用户意见：去除旗帜，去除左侧的岔路。
- 修订范围：移除主楼前中央红旗、旗杆及硬件；移除左前景岔路，并补成连续的银杏林、绿化带、落叶和路缘。
- 保留范围：主楼身份和几何、正中单一道路轴线、秋季金黄色调、青色路径灯、少量品红提示、天空、光照、镜头和 16:9 画幅。
- 审批边界：本文件是新的概念修订候选，不覆盖 `concept_002`，不代表概念批准、正式资产批准或 Godot 接入授权。

## 编辑提示词

```text
Use case: precise-object-edit. Asset type: 16:9 horizontal main-menu background concept for Cyber Pop Campus. Input image: Image 1 is the current ginkgo-main-building concept and is the edit target. Edit only the two requested issues while preserving the rest of the image as closely as possible. First, remove the central red flag, the flag fabric, and the entire flagpole and hardware; reconstruct the building facade, steps, trees, and sky naturally so there is no remaining flag or pole. Second, remove the broad side road / fork entering from the lower-left foreground; replace that area with a continuous ginkgo-lined planting strip, grass, curb, fallen leaves, and a natural dark paved edge, so the scene has one clear straight central road leading to the main building and no left-side branch road. Keep the same main building geometry and position, central axial road, golden autumn ginkgo canopy, cyan path lights, small magenta accent, warm late-afternoon palette, sky, sun, leaves, and restrained cyber-campus treatment. Do not add any new roads, flags, poles, signs, people, cars, text, logos, watermarks, UI, or HUD. Do not redesign the campus or change the camera framing. Preserve the clean 2D painted game-concept look. This is a non-destructive revision candidate, not a finished production asset.
```

## 输出与质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu
  variant: concept_003
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: NOT_APPLICABLE
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS_WITH_NOTES
  failures: []
  notes:
    - "中央红旗、旗杆和硬件已移除；左侧岔路已替换为连续的银杏林、绿化带、落叶和路缘。"
    - "主楼、正中单一道路、秋季金黄色调和赛博路径灯保持连续，适合作为概念修订候选。"
    - "未发现菜单文字、水印或签名；正式标题、按钮和状态信息仍必须由 Godot 原生组件或独立可编辑资源承担。"
    - "生成式编辑仍可能带来建筑细节和树叶边缘的局部漂移；若进入正式资产阶段，需要按选定版本重新做安全区和多分辨率检查。"
  repair_directives: []
  next_step: accept
```

## 文件核验

| 文件 | 尺寸 | 像素格式 | 大小 | SHA-256 |
| --- | --- | --- | ---: | --- |
| `ginkgo-main-building.png` | 1672×941 | `Format24bppRgb` | 2,612,220 bytes | `fefa7bcfaa5fbb59a4981469b953924cad29d0704bb208aaf1229b6ae5335dce` |

结论：该修订允许进入人工概念评审，不代表概念批准、正式资产批准或 Godot 接入授权。当前 Manifest 选择状态为 `unselected`，审批状态为 `pending`，集成状态为 `not_integrated`。
