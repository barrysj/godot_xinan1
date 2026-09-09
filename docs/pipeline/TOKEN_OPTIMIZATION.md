# Codex Token 节省规则

## 1. 最大原则
> 让 Codex 做确定性执行，不做开放式审美探索。

## 2. 普通视觉任务只读
- `ART_CONTRACT.md`
- 当前 Task Spec
- `asset_manifest.yaml`

除非必要，不读完整 STYLE_BIBLE、历史讨论、大量概念图、无关 Spec。

## 3. 不重复描述
错误：在 Prompt 中重新讲一遍“科技青、品红、亮黄、校园赛博波普……”  
正确：`按 ART_CONTRACT.md 和当前 Task Spec 实现。`

## 4. 不让 Codex 反复看图
Manifest 能表达的信息不要再做图片分析。只有裁切、对齐、层级、颜色落地偏差、动效错位、响应式等实际问题才看截图。

## 5. 一个 Thread 一个 Feature
例如：`[UI]课程表`、`[UI]关系网`、`[Scene]教室`、`[System]SaveManager`。不要把全项目塞进一个长 Thread。

## 6. Prompt 固定结构
`目标 → 读取 → 使用资产 → 实现要求 → 禁止事项 → 验证`

## 7. 视觉 QA 必须可执行
错误：更酷、更高级、更赛博。  
正确：标题上边距从约 12 调到 24；品红面积减少约 30%；头像层级置于连接线之上；日常页禁用 glitch shader。
