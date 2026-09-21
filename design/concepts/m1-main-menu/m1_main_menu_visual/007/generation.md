# M1 图书馆异常倒影定向修订 · concept_007

## 修订目标

在 `concept_006` 图书馆异常图的基础上，只加强湖面倒影的异常程度与颜色变化。建筑、湖岸、天空、地平线、镜头构图和左侧菜单安全区保持连续，不重做地点身份。

## 修订内容

- 下半部水面加入深蓝、青色、电光蓝、紫色、品红和少量酸黄的分区式记忆颜色。
- 建筑倒影出现轻微横向错帧、重复窗列、局部倒置和不规则波纹接缝。
- 加入少量彩色环形波纹与半透明几何倒影碎片，重点集中在下方中部与右侧。
- 保留水面透视、岸线接触和真实水波逻辑；不改变真实建筑本体。
- 不加入菜单文字、Logo、水印、人物、动物、道路、旗帜或全屏扫描线。

## 输入与输出

- 输入参考：`../006/library-anomaly.png`
- 输出：`library-anomaly.png`
- 文件：PNG、1672×941、`Format24bppRgb`、非透明
- SHA-256：`f0100e195b71f4cf84cb1226b4bb97215b3b92675432246c7e11b5678c3a7b3f`

## image-quality-check 结果

```yaml
quality_result:
  schema_version: 1
  task_id: m1-main-menu-library-anomaly-reflection-007
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
    - "异常主要集中在水面，图书馆建筑仍可快速识别。"
    - "颜色变化比 concept_006 明显，左侧天空与湖面仍可承载菜单。"
    - "几何碎片与倒影错帧属于有意异常语言，未形成伪文字或水印。"
  repair_directives: []
  next_step: accept
```

## 接入说明

主菜单 `menu.gd` 已改为读取本版本；品学楼和银杏主楼仍使用 `concept_006`。本版本保持概念 review 状态，未升级为正式发布资产。
