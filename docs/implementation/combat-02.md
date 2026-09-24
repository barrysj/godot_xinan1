# COMBAT-02 · 普攻、自动技能、弹道结算

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：COMBAT-02
- 所属系统：战斗
- 当前状态：已验证
- 最近验证：2026-09-22；开发基线 `f6b79df`，分支 `codex/synergy-hacking-trial`。

## 玩家能力与接入范围

普攻、自动技能、弹道结算。玩家价值：可重复的战斗规则。

## 实现与规则入口

- 实现入口：[battle_simulation.gd](../../game/combat/battle_simulation.gd)
- 规则事实源：[战斗](../battle-demo.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E01、E09、E14。编号和重跑入口见[共享验证目录](verification.md)。
- Godot 4.7.2 / PowerShell 7：`--headless --path . res://game/combat/accuracy_check.tscn`，51 checks / 0 failures；反转单位数组后完整状态与事件一致、同一步移动后统一射程、主目标技能、低血量比例、同批过量伤害归属、盾层来源与过期、移动目标追踪、阵亡取消。
- `res://game/combat/action_check.tscn`、`res://game/combat/auto_battle_check.tscn` 均 PASS；`pwsh.exe -File ./run-battle-demo.ps1 -Smoke` 两敌阵、四装备归属与1×/2×一致通过。
- 图形验证复用三战实际流程；`.godot/trial-combat.png`、`trial-hack.png` 为真实动作／弹道／护盾画面，已在对话展示。试炼表现专项与完整流程见 [CORE-05](core-05.md)。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 本轮行为与扩展入口

统一先推进全员位置，再判断释放与碰撞；同批支援先于伤害，伤害按命中权重分摊实际扣血与吸收统计。自动普通技能沿用动作锁定主目标，低血量用浮点比例，平手按距离与稳定 ID；结果不依赖 roster 遍历顺序。

护盾用 `grant_shield` / `remove_shields` 按来源管理，优先消耗即将到期的层；兼容旧 `shield` 直接赋值。派生玩法在 `_after_impact_batch` 读取实际结果与自定义效果元数据，不能重复执行基础伤害。具体结算规则维护在 battle-demo.md。

## 已知边界与未完成项

统一请求仅 attack；无手动技能／道具

## 交接给统筹

待统筹：本次改动作用于共享模拟器，影响原 Demo、旧随机局、M1 与试炼；旧的总览快照尚未汇总。没有增加手动技能入口，也未改变美术资源批准状态。
