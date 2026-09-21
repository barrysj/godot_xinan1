# M1 主菜单视觉样板 · 概念 005

## 修订来源与边界

- 生成工具：Codex 内置 `image_gen`，使用编辑模式完成定向构图修订。
- 生成日期：2026-09-20。
- 编辑目标：`design/concepts/m1-main-menu/m1_main_menu_visual/004/ginkgo-main-building.png`。
- 项目副本：`ginkgo-main-building.png`。
- 用户意见：主楼的大门那一列必须对齐道路中轴线。
- 修订范围：以主楼正中拱门／大门列和前景双黄线为硬基准；保持道路不动，将主楼及入口台阶整体横向回调到精确对齐。
- 纠偏说明：`concept_004` 的主楼左移过多，本版明确向右回调，不以楼顶或整栋建筑外轮廓的视觉中心代替大门中列。
- 继承范围：保留去旗帜、去旗杆、去左侧岔路的结果，以及主楼比例、秋季金黄色调、道路、银杏林和局部赛博光效。
- 审批边界：本文件是新的概念修订候选，不覆盖 `concept_004`，不代表概念批准、正式资产批准或 Godot 接入授权。

## 编辑提示词

```text
Use case: precise-object-edit. Asset type: 16:9 horizontal main-menu background concept for Cyber Pop Campus. Input image: Image 1 is the clean current ginkgo-main-building concept and is the edit target. This is a correction of the previous alignment attempt. In the current image, the center of the main entrance doorway / central arched gate column is visibly left of the road's double-yellow centerline. Shift the entire main-building group slightly to the RIGHT as one coherent unit: both wings, the central facade, the entrance, the front steps, and the landing. Move it only enough that the exact center of the main entrance column is precisely superimposed on the existing straight yellow road centerline. Use the entrance column and the road line as the hard alignment guides, not the visual center of the roof or the overall building width. Keep the road, yellow line, curbs, ginkgo trees, path lights, sky, sun, autumn leaves, camera framing, building scale, perspective, warm golden palette, cyan lights, and small magenta accent unchanged. Do not move or bend the road. Do not shift the trees independently. Do not add flags, poles, people, cars, signs, text, logos, watermarks, UI, HUD, or red markup. Do not redesign or mirror the building. Preserve the clean 2D painted game-concept look and exact 16:9 framing. This is a non-destructive revision candidate, not a finished production asset.
```

## 输出与质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu
  variant: concept_005
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: NOT_APPLICABLE
    prompt_and_content: PASS
    composition_and_readability: PASS_WITH_NOTES
    generation_artifacts: PASS_WITH_NOTES
  failures: []
  notes:
    - "以正中拱门／大门列和道路双黄线为硬基准，主楼横向位置完成回调，二者在画面中基本重合。"
    - "道路、银杏林、路径灯和镜头保持连续，未把用户的红色手绘标记带入画面。"
    - "未发现菜单文字、水印或签名；正式标题、按钮和状态信息仍必须由 Godot 原生组件或独立可编辑资源承担。"
    - "生成式构图修订仍可能带来建筑细节和透视的局部漂移；若进入正式资产阶段，需要按选定版本重新做安全区和多分辨率检查。"
  repair_directives: []
  next_step: accept
```

## 文件核验

| 文件 | 尺寸 | 像素格式 | 大小 | SHA-256 |
| --- | --- | --- | ---: | --- |
| `ginkgo-main-building.png` | 1672×941 | `Format24bppRgb` | 2,553,433 bytes | `01587c6106e9b6ab7b5667fb9cc891e01481e460095037ee1377558e8212378c` |

结论：该修订允许进入人工概念评审，不代表概念批准、正式资产批准或 Godot 接入授权。当前 Manifest 选择状态为 `unselected`，审批状态为 `pending`，集成状态为 `not_integrated`。
