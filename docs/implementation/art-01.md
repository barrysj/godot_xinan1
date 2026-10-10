# ART-01 · 同步动作、受击与退场回退

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：ART-01
- 所属系统：美术
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

同步动作、受击与退场回退。玩家价值：看懂行动结果。

## 实现与规则入口

- 实现入口：[unit_presentation.gd](../../scenes/battle_demo/unit_presentation.gd)、[battle_animation.gd](../../scenes/battle_demo/battle_animation.gd)
- 规则事实源：[动画](../battle-animation.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E09–E11。编号和重跑入口见[共享验证目录](verification.md)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

未配动画仍回退旧图；无骨骼后端

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。

## 既有计时施法的释放反馈（2026-10-07）

基线8e983ea加工作树。pixel_battle.gd监听原enemy_release事件，短暂同步既有cast片段的释放段，0.4模拟秒后恢复普通动作；死亡优先，重建战斗清空状态。code_fx.gd只绘制蓄力弧及0.22秒缓出释放提示，简化特效减少运动。没有新增动作资源，不改变模拟或使用Engine.time_scale。

battle_feedback_check.tscn -- --capture：68/0，原广播／投影／巨典均实际到达9秒预警、12秒释放，已有cast可见且提示正常收尾；三桌面尺寸实机截图已查看。presentation_check.tscn PASS / 0；原starting_strategy_check.tscn无头132/0。日志 .godot/battle-feedback-verified.log、feedback-presentation.log、feedback-starting-flow.log。旧强化接入检查的现行失败和输入边界见UI-02。待统筹：无新动作生产，只补原事件到现有表现资源的连接。
