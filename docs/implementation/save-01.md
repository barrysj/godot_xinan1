# SAVE-01 · 节点续玩、战报奖励恢复、成长任务共存

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：SAVE-01
- 所属系统：存档
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

节点续玩、战报奖励恢复、成长任务共存。玩家价值：可安全中断。

## 实现与规则入口

- 实现入口：[run_checkpoint.gd](../../game/run/run_checkpoint.gd)、[meta_hub.gd](../../scenes/expedition/meta_hub.gd)
- 规则事实源：[校园](../campus-demo.md)、[录入](../content-authoring.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E03–E05、E14、E18。编号和重跑入口见[共享验证目录](verification.md)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

profile v3／checkpoint schema 1／run schema 5；Web 写后显式同步；半场不恢复 HP

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。

## M1 战役状态基础（待统筹）

2026-09-16；实现基线为 `7f92ba8` 后的本功能提交。当前为部分实装：`game/meta/campaign_state.gd` 定义永久事实与合法性；`campus_progress.gd` profile v4 原子保存序章、路线资料、终端、回忆、人物及终局阶段，基地显示当前目标。流程入口尚待后续模块接入。

验证：Godot `--headless --path . --log-file .godot/campaign-check.log res://game/meta/campaign_check.tscn`，101 checks、0 failures；既有 `expedition.tscn -- --meta-smoke`，67 checks、0 failures。覆盖六种区域顺序、重复结算、阶段磁盘恢复和保存失败回滚。图形 `--meta-capture` 截图 `.godot/meta_continue.png` 已在聊天展示。无真机、Web 或真人新证据；引擎既有证书和原图加载警告保留。
