# M1 主菜单视觉样板 · 概念 004

## 修订来源与边界

- 生成工具：Codex 内置 `image_gen`，使用编辑模式完成定向构图修订。
- 生成日期：2026-09-20。
- 编辑目标：`design/concepts/m1-main-menu/m1_main_menu_visual/003/ginkgo-main-building.png`。
- 项目副本：`ginkgo-main-building.png`。
- 用户意见：中轴线是歪的，需要将主楼向左一些。
- 修订范围：将主楼整体向左微移，并让主入口、台阶与现有道路黄线重新对齐；道路、银杏林、路径灯和镜头不随之移动。
- 继承范围：保留 `concept_003` 已完成的去旗帜、去旗杆、去左侧岔路结果，以及主楼比例、秋季金黄色调和局部赛博光效。
- 审批边界：本文件是新的概念修订候选，不覆盖 `concept_003`，不代表概念批准、正式资产批准或 Godot 接入授权。

## 编辑提示词

```text
Use case: precise-object-edit. Asset type: 16:9 horizontal main-menu background concept for Cyber Pop Campus. Input image: Image 1 is the clean current ginkgo-main-building concept and is the edit target. The user's red hand-drawn markup is guidance only and must not appear in the result. Correct the composition by shifting the entire main-building group slightly left as one coherent unit: the central facade, both wings, entrance, front steps, and the visible landing must move left by a small controlled amount, about 3 percent of the image width. Align the exact architectural center of the main entrance and steps with the existing straight yellow centerline of the road in the foreground, so the campus axis reads as one clean vertical line from road to building. Reconstruct any exposed background naturally after the move. Keep the road, yellow centerline, curb edges, ginkgo trees, path lights, sky, sun, autumn leaves, building scale, perspective, warm golden palette, cyan lights, and small magenta accent unchanged. Do not move or bend the road. Do not make the building wider, taller, mirrored, or newly designed. Do not add flags, poles, people, cars, signs, text, logos, watermarks, UI, or HUD. Preserve the clean 2D painted game-concept look and the exact 16:9 framing. This is a non-destructive revision candidate, not a finished production asset.
```

## 输出与质量闸门

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu
  variant: concept_004
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
    - "主楼整体向左微移，主入口、台阶和前景道路黄线的轴向关系得到校正。"
    - "道路、银杏林和路径灯保持连续，未把用户的红色手绘标记带入画面。"
    - "未发现菜单文字、水印或签名；正式标题、按钮和状态信息仍必须由 Godot 原生组件或独立可编辑资源承担。"
    - "生成式构图修订仍可能带来建筑细节和透视的局部漂移；若进入正式资产阶段，需要按选定版本重新做安全区和多分辨率检查。"
  repair_directives: []
  next_step: accept
```

## 文件核验

| 文件 | 尺寸 | 像素格式 | 大小 | SHA-256 |
| --- | --- | --- | ---: | --- |
| `ginkgo-main-building.png` | 1672×941 | `Format24bppRgb` | 2,558,667 bytes | `8615e1cfb198b8e6acbbd25ffe96698bb10582cb1d3ae51321f3bfbcf96ca342` |

结论：该修订允许进入人工概念评审，不代表概念批准、正式资产批准或 Godot 接入授权。当前 Manifest 选择状态为 `unselected`，审批状态为 `pending`，集成状态为 `not_integrated`。
