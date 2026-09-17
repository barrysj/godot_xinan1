# 011 Godot 运行预览装配

这是 010 校园记忆正式资产的独立 Godot 运行评审装配，不是正式玩法接入。

- 校园记忆：从 `assets/art/ui/m1_exploration_ui/memory.png` 读取，状态为 selected / approved。
- 人物事件、借阅终端、敌对守卫：从 009 候选读取，仅用于保持四热点场景完整，仍为 unselected / pending。
- 交互与浮窗：继承 005／008 已验证的原生 UI；热点绘制改为 118×118 透明命中区内的 106×106 自由轮廓，不加统一方形底座。
- 运行验证：附加 `-- --ui-capture`，自动执行三种分辨率的默认、详情、完成状态和键鼠焦点／取消／奖励门槛断言。
- 截图输出：`design/concepts/m1-exploration-ui/review/codex-workflow/preview-011/`。

本装配用于审核缩放可读性、视觉重量与整体协调；用户看到运行截图后仍需单独决定接入效果是否通过。
