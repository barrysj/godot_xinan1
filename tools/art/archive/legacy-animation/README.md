# 旧代码动画迁移归档

仅用于复现历史资源转换，不作为新角色制作流程。新角色直接编辑 `presentation.tscn`、AnimationLibrary 和 SpriteFrames；运行、预览、GIF 导出及正式提升均不依赖此目录。

- `bake_presentation.tscn`：旧脚本的原始采样桥接，仅写 `.godot` 中间产物，最多 8 秒；不能把输出直接当作最终资产。
- `compact_cycles.tscn`：本次旧密集库的独立周期与稀疏曲线转换；继承归档采样器，参数由 JSON 提供。必须同时验证姿态与资源预算。
- 通用对比已独立到 `tools/art/verification/`；依赖方向只允许归档工具使用通用辅助函数，日常工具不反向依赖归档。

粉笔精灵的历史输入版本、制作配置和重建说明保留在候选 006 的 `generation.md`、`compact_authoring.json`；旧脚本与密集库从 Git 提取，不把它们复制到正式资产或长期缓存。两种入口均以唯一命令行参数接收 JSON 配置。恢复输入及输出父目录后，通过 Godot 场景入口运行；结果先写 `.godot`，验证后才通过现有批准候选与提升流程处理。
