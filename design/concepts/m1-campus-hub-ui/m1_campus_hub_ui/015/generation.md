# 015 基地控件概念

2026-09-21，Codex built-in image_gen。原始输出exec-0da6a6b4-16b6-4161-b188-d10fc6a18f38.png；输入当前1920×1080基地截图。阶段concept，pending，未接入。

生成简报：保留014教室构图、白桌面、木框墨绿田字黑板、日光、设备与AI，仅重设计覆盖UI。16:9整屏。海军蓝半透明哑光材质、细蓝灰边与轻切角，禁止装甲双边、金属反光、霓虹与品红。顶部精简地点和资源／菜单，左下当前目标、选择区域、三终端进度及唯一突出青色探索按钮；右下成长、派遣、回忆、图鉴四枚横排独立小卡，图标在上文字在下。统一底部安全边距，无外套大框，无重开存档和调试文字，不新增功能或道具。中心黑板保持可见。

自检：图片可读、构图和主体符合；回忆／图鉴图标对调、主按钮反光偏强。概念重新采样背景，正式实现必须继续使用原014，不从本图截取背景。

```yaml
quality_result:
  schema_version: 1
  task_id: m1-campus-hub-ui-015
  status: REGENERATE_MINOR
  eligible_for_style_validation: false
  checks:
    technical_integrity: PASS
    subject_and_identity: PASS
    anatomy_and_physics: PASS
    prompt_and_content: FAIL
    composition_and_readability: PASS
    generation_artifacts: PASS
  failures: [图标映射对调, 主按钮高光偏强]
  notes: [只供布局评审，不是正式切图资产]
  repair_directives: [正式控件沿用正确图标映射, 主按钮降低反光]
  next_step: regenerate
```

批准布局方向后，以原生Control／共享Theme制作正式控件，保留012图标映射与014背景；文字不烘焙，重开存档进入菜单且保留确认。运行版当前不变。
