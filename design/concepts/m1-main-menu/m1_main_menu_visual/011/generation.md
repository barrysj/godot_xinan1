# M1 图书馆异常双黑天鹅明确动作修订 · concept_011

## 修订目标

对 `concept_010` 做单变量动作修订，保留两只黑天鹅的远景尺度与位置，只明确左右朝向和动作：左鸟向左低颈滑行，右鸟向右抬颈并进行一次轻微展翼。

## 视觉系统

- 左鸟：明确面向画面左侧，颈部较低、身体水平、双翼收拢，尾波向右拖尾。
- 右鸟：明确面向画面右侧，头部与喙朝右，颈部呈 S 形抬高；一侧羽翼形成宽的分层羽扇，不能读成第二个颈部或第二个头，尾波向左拖尾。
- 两只都保持远景、小尺度和自然贴水关系；青／品红数字边缘分裂与错位倒影保持低强度，不抢过图书馆和水面主异常。
- 其他内容不变：图书馆建筑、湖岸、天空、彩色倒影、几何碎片、镜头构图和左侧菜单安全区。

## 输入与输出

- 输入参考：`../010/library-anomaly-two-digital-swans-asymmetric.png`
- 输出：`library-anomaly-two-digital-swans-clear-directions.png`
- 文件：PNG、1672×941、`Format24bppRgb`、非透明
- SHA-256：`26c91dd40488fae87396b59f69bb9cbb9f094d714091c0c238ed636e6a3cf96b`

## image-quality-check 结果

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu-library-two-digital-swans-clear-directions-011
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
    - "左鸟低颈向左滑行，右鸟抬颈向右滑行并有清晰羽翼动作，朝向不再相同。"
    - "严格保留两只远景黑天鹅，未增加第三只或前景大鸟。"
    - "右鸟抬翼已读作羽扇而非第二个颈部；图书馆与水面异常仍是主焦点。"
    - "当前仍是一体化背景概念，不是独立透明角色资产。"
  repair_directives: []
  next_step: accept
```

## 接入说明

主菜单 `menu.gd` 已改为读取本版本；品学楼和银杏主楼仍使用 `concept_006`。本版本保持概念 review 状态，后续若需要黑天鹅独立复用，应另行制作透明背景角色并验证锚点、尺寸和引擎导入。
