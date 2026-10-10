# ART-01 · 同步动作、受击与退场回退

- 功能 ID：ART-01
- 所属系统：美术
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

同步动作、受击与退场回退。玩家价值：看懂行动结果。

## 实现与规则入口

- 实现入口：[unit_presentation.gd](../../scenes/battle_demo/unit_presentation.gd)、[battle_animation.gd](../../scenes/battle_demo/battle_animation.gd)
- 规则事实源：[动画](../combat/animation.md)
- 跨系统边界参见[集成约束](../development/integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E09–E11。编号和重跑入口见[共享验证目录](../development/verification.md)。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

未配动画仍回退旧图；无骨骼后端

## 统筹状态

2026-10-10已汇总到总览；后续在本档案就地维护当前能力、证据与边界。

## 既有计时施法的释放反馈（2026-10-07）

基线8e983ea加工作树。pixel_battle.gd监听原enemy_release事件，短暂同步既有cast片段的释放段，0.4模拟秒后恢复普通动作；死亡优先，重建战斗清空状态。code_fx.gd只绘制蓄力弧及0.22秒缓出释放提示，简化特效减少运动。没有新增动作资源，不改变模拟或使用Engine.time_scale。

battle_feedback_check.tscn -- --capture：68/0，原广播／投影／巨典均实际到达9秒预警、12秒释放，已有cast可见且提示正常收尾；三桌面尺寸实机截图已查看。presentation_check.tscn PASS / 0；原starting_strategy_check.tscn无头132/0。日志 .godot/battle-feedback-verified.log、feedback-presentation.log、feedback-starting-flow.log。旧强化接入检查的现行失败和输入边界见UI-02。已汇总（2026-10-10）：无新动作生产，只补原事件到现有表现资源的连接。
