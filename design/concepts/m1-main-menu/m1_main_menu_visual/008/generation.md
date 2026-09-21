# M1 图书馆异常数字黑天鹅修订 · concept_008

## 修订目标

在 `concept_007` 的彩色异常倒影基础上加入一只数字化黑天鹅，让原始湖畔照片中的黑天鹅记忆成为图书馆异常场景的身份锚点。保持建筑、湖岸、水面色彩异常、镜头构图和左侧菜单安全区连续。

## 视觉系统

- 主体：一只自然贴水的黑天鹅，黑色羽体、细长弯颈、可读的羽片层次和小幅红色喙部点缀。
- 数字化：青／品红边缘分裂、几何化羽片、细小像素裂纹和轻微全息色偏；不做怪物化、不增加多余肢体或生物。
- 水面关系：黑天鹅位于下方中右湖面，身体与水面接触自然，保留尾波；倒影连接水面并出现垂直错帧、色彩分裂和碎片化。
- 构图：黑天鹅足够大，能在主菜单画面中被识别；不侵入左侧导航安全区，不遮挡图书馆主体。

## 输入与输出

- 输入参考：`../007/library-anomaly.png`
- 输出：`library-anomaly-digital-swan.png`
- 文件：PNG、1672×941、`Format24bppRgb`、非透明
- SHA-256：`f264272cf974e4f970d595e6d63cab7c87ef2fb82ee9431573f1830d9142eb49`

## image-quality-check 结果

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu-library-digital-swan-008
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
    - "黑天鹅轮廓、长颈、羽片与贴水关系清楚，未出现怪物化解剖错误。"
    - "数字化效果集中在羽缘、羽片和倒影，湖畔图书馆身份仍可快速识别。"
    - "黑天鹅位于下方中右侧，未占用左侧菜单安全区。"
    - "当前仍是背景概念中的一体化主体，不是可独立复用的透明角色资产。"
  repair_directives: []
  next_step: accept
```

## 接入说明

主菜单 `menu.gd` 已改为读取本版本；品学楼和银杏主楼仍使用 `concept_006`。本版本保持概念 review 状态，后续若需要角色独立复用，应另行制作透明背景黑天鹅资产并进行独立的锚点、尺寸和引擎导入验证。
