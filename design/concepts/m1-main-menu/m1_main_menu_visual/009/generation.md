# M1 图书馆异常远景双黑天鹅修订 · concept_009

## 修订目标

针对 `concept_008` 中黑天鹅过大的问题进行单变量修订：移除前景大黑天鹅，改为两只更小、位于中远距离湖面的数字化黑天鹅。保留图书馆建筑、彩色异常倒影、湖岸、天空、镜头构图和左侧菜单安全区。

## 视觉系统

- 数量：严格为两只，不增加第三只。
- 位置与尺度：两只位于湖面中远景、靠近远岸但仍在水面上；每只约为上一版黑天鹅可见主体的 20%～25%。
- 形体：保留黑天鹅的黑色小体块、长弯颈、自然贴水姿态和小型尾波，远景仍能快速辨认。
- 数字化：使用低强度青／品红边缘分裂、少量几何羽片闪烁和对应的细小错位倒影；不让黑天鹅压过水面主异常。
- 构图：远景双鸟避开左侧菜单安全区，图书馆仍是第一识别主体，水面色彩变化仍是第二异常焦点。

## 输入与输出

- 输入参考：`../008/library-anomaly-digital-swan.png`
- 输出：`library-anomaly-two-digital-swans.png`
- 文件：PNG、1672×941、`Format24bppRgb`、非透明
- SHA-256：`3e76911600f46b58b60041d52f9cfacf070734edcb6b285768fb8018ce2713b1`

## image-quality-check 结果

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu-library-two-digital-swans-009
  status: PASS_WITH_NOTES
  eligible_for_style_validation: true
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: PASS
    prompt_and_content: PASS
    composition_and_readability: PASS
    generation_artifacts: PASS_WITH_NOTES
  failures: []
  notes:
    - "画面中为两只远景黑天鹅，已移除上一版前景大鸟。"
    - "两只黑天鹅的水面接触、尾波和小型错位倒影可读。"
    - "图书馆地标与水面彩色异常仍是主视觉，左侧菜单安全区保持低信息。"
    - "当前仍是背景概念内的一体化双鸟，不是可独立复用的透明角色资产。"
  repair_directives: []
  next_step: accept
```

## 接入说明

主菜单 `menu.gd` 已改为读取本版本；品学楼和银杏主楼仍使用 `concept_006`。本版本保持概念 review 状态，后续若需要独立复用黑天鹅，应另行制作透明背景双鸟／单鸟资产并进行锚点、尺寸和引擎导入验证。
