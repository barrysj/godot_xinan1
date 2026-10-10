# COMBAT-02 · 普攻、自动技能、弹道结算

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：COMBAT-02
- 所属系统：战斗
- 当前状态：已验证
- 最近验证：2026-10-08；自然产码队列基线 `f602b36`，分支 `art/enemy-animation-assets`。独立施法与意图的既有验证保留于下方。

## 玩家能力与接入范围

普攻、独立蓄力自动技能、弹道结算。普通技能在触发普攻完成后进入互斥施法；定时敌人也通过同一个动作状态执行预警与释放。人物与敌人暴露统一行动计时和意图，界面不再自行猜测技能释放时间。

## 实现与规则入口

- 实现入口：[battle_simulation.gd](../../game/combat/battle_simulation.gd)、[code_battle_simulation.gd](../../game/combat/code_battle_simulation.gd)
- 规则事实源：[战斗](../battle-demo.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

2026-10-07，Godot 4.7.2 / PowerShell 7；下列场景命令前缀为 `Godot --headless --path .`，GUI 捕获去掉 `--headless`，增加 `--rendering-method gl_compatibility`。所有日志均使用本次唯一 `--log-file .godot/cast-*.log`，不依赖旧缓存结论。

- `res://game/combat/cast_check.tscn`：72 checks / 0 failures；N 次普攻后单次施法、计数归零、暂停/无效 delta、冻结普攻时钟、普通受击不中断、阵亡取消、攻击速度不缩短蓄力、延后敌人预警、真实释放时点、产码无重复，现有动画准备/释放/收招映射，以及普通/定时技能与收招时的真实目标语义。
- `res://game/combat/action_check.tscn` PASS；旧“触发普攻同批附带技能”断言按独立蓄力规则改为先普攻、后技能，并保留单次群体技能验证。
- `res://game/combat/accuracy_check.tscn` 51/0；`auto_battle_check.tscn` PASS；`chain_check.tscn` 36/0；`pierce_check.tscn` 34/0。命中批次、盾来源、投射物、阵亡和真实连锁保持有效。
- `res://scenes/battle_demo/presentation_check.tscn` PASS；包含 30/60/144 FPS、0.25/1/2 倍速事件一致性与完整暂停。
- `res://scenes/battle_demo/battle_feedback_check.tscn -- --capture` GUI 68/0，原 expedition 场景三种敌阵与三种尺寸，截图 `.godot/feedback-final-warning-1920x1200.png` 等实际显示蓄力与释放。
- `res://scenes/battle_demo/starting_strategy_check.tscn` 133/0；两条原起始队伍共 10 场完成序章与图书馆。首个正式区域战斗的自然首次追踪 11.2 秒、反冲 12.4 秒；尚无发明家的护盾序章为 16.25 秒。奖励样本有随机差异，不能据此宣称全部数值平衡。
- 扩展旧检查 `code_rules_check.tscn` 47 checks / 11 failures；`synergy_check.tscn` 65 checks / 32 failures 且旧标记字典访问报错。另从开发基线提取原模拟器到 `.godot/cast-baseline/` 重跑，同样失败集合与数量，涉及旧断链/接管/羁绊定义；本次未修改这些检查、未将它们记为通过。
- 程序通过不等于真人体验、目标设备或美术审批通过。旧证据 E01/E09/E14 留在[共享验证目录](verification.md)。

### 自然产码队列验证（2026-10-08）

- `res://game/combat/code_cycle_check.tscn`：33 checks / 0 failures。覆盖第 3 次有效普攻排队、0.30 模拟秒准确到账、暂停与无效 delta、生成期间新命中计下一轮、多周期独立、满库溢出、等待期间腾出容量、紫码共享阈值及余量、作者阵亡、胜负结算等待已完成产出、reset/configure 清队列、道具立即入库。日志 `.godot/code-cycle-check.log`。
- `res://game/combat/cast_check.tscn`：72/0；`res://game/combat/chain_check.tscn`：37/0（紫码的旧即时入库断言改为阈值排队＋六个固定步后到账，护盾余量与实际链路断言保留）。
- `res://scenes/battle_demo/starting_strategy_check.tscn`：133/0，两条实际起始流程共 10 场完成；日志 `.godot/code-cycle-starting_strategy_check.log`。原无成长链路样本自然首次核心由 11.2/12.0 秒变为 11.5/12.3 秒，符合短暂生成等待；不将此视为全部流派平衡验收。
- 逻辑改动不生成新美术；三格填满到收拢的实际 GUI 截图与尺寸验证由对应 HUD 功能记录，此处只声明上述模拟及原流程证据。

## 本轮行为与扩展入口

统一先推进全员位置，再判断释放与碰撞；同批支援先于伤害，伤害按命中权重分摊实际扣血与吸收统计。普通技能排队时保留触发普攻目标；开始施法时若该目标已阵亡则选择存活目标，释放时各效果仍按自己的射程与目标规则检查。低血量用浮点比例，平手按距离与稳定 ID；结果不依赖 roster 遍历顺序。

护盾用 `grant_shield` / `remove_shields` 按来源管理，优先消耗即将到期的层；兼容旧 `shield` 直接赋值。派生玩法在 `_after_impact_batch` 读取实际结果与自定义效果元数据，不能重复执行基础伤害。具体结算规则维护在 battle-demo.md。

### 表现读取契约

- `unit.action.kind` 为 `attack` 或 `cast`；`casts` 仅在真正独立施法时为 true。仍保留 `age/windup/duration/released/phase`，现有动画 `sync_motion` 据此映射准备、释放与短收招；不新增动作资产。
- `action_timing(id)` 返回 `kind/phase/progress/remaining/duration/waiting_target/skill_id/target_id`。满条代表释放，不代表远程命中；收招保持满条，已就绪但在接敌时也为满条并标 `waiting_target`。死亡单位返回空字典。
- `intent_for(id)` 返回 `kind/icon/label/description/target_id/locked/remaining`；施法另有 `target_description`，界面优先展示它。自身技能保留自己的 ID；真实锁定单体保留目标 ID；群体、范围或释放时动态选人的技能返回 `target_id=-1`，不能沿用触发技能的普攻目标。广播为其他存活敌人，横排/重击为锁定区域；守护、发明、应援等按当前主线实际受益范围描述，收招阶段也不泄漏旧普攻目标。定时敌人的预警还带锁定地面 `center`。`warnings.fire_at` 来自实际施法开始，正在执行的普攻不会被强制取消或在预警中继续开始下一次普攻。
- 普攻与独立技能具有不同 action ID，技能效果仍为 special，产码只统计真实普攻命中。敌方预警效果从同一 action 释放，范围伤害当场结算，不变成追踪弹道。

### 自然产码的表现事件

第三次有效普攻及全队护盾吸收满阈值后，立即消耗本轮计数并排入 `pending_code_cycles`；后续命中继续累计下一轮。等待使用原模拟时钟，暂停不会推进；只有这两种阈值产出延迟，道具和既有漏洞验证/特殊触发的直接产出仍沿原即时规则。

- `code_cycle_started`：继承标准 `actor_id/time/from/to`，另有 `cycle_id/code_type/amount/reason/duration/ready_at/shared`。`duration` 为 0.30 模拟秒；紫码 `shared=true`，是全队吸收计数而非某个人的专属计数。
- 到期沿 `_gain` 结算；`code_generated` 带相同 `cycle_id`，即时来源该字段为 -1。容量在实际到账时检查，等待期间花费缓存可腾出空间；`generated/overflow` 统计也在到账时更新。
- `code_cycle_completed`：无论是否满库，都带 `cycle_id/code_type/actual/overflow/reason`，让界面正确结束收拢。先移除队列再发布事件，嵌套结算不能重复入库。
- 已完成的产出不因作者阵亡取消。战斗已决胜负时先进入 `closing` 禁止新行动/破解，等已赚取的队列到账再 `finished`，不在结算末尾丢码；等待不额外制造普攻。`reset` 和 `configure_combat` 均清除队列与编号，新战斗不会继承上一场待产出。

## 已知边界与未完成项

统一公开 `request_action` 仍只接受 attack；自动技能由内部队列驱动。现有手动破解和道具继续走原 CodeBattleSimulation 接口，不使用这个普攻请求入口。

互斥施法会放慢供盾与普攻产码。最小护盾起始队的首个核心偏晚，完整供盾队的无成长巡逻样本时长达 53.6 秒且一人阵亡，需真人试玩和成对数值样本继续评估；本次未擅自提高角色属性抵消变化。旧规则检查仍有上列已复现的基线失败。

## 交接给统筹

待统筹：本次改动作用于共享模拟器，影响原 Demo、旧随机局及 M1，首次产码、供盾与战斗时长需要按新节奏重新采样；界面消费统一计时/意图契约。没有新增战斗入口、存档系统或人物/敌人动作，未改变美术资源批准状态。
