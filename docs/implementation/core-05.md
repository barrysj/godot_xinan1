# CORE-05 · 六人羁绊与三战破解试炼

- 状态：已实现并通过桌面工程验证；真人趣味性与平衡待验。
- 日期：2026-09-22；初版基线 `f6b79df`，共享战斗基线 `599ea0d` 加本次资源／流程／表现工作树；分支 `codex/synergy-hacking-trial`。
- 玩家入口：主菜单「三战试炼」；或 `pwsh.exe -File ./run-synergy-trial.ps1`。
- 规则事实源：[战斗文档](../battle-demo.md#三战试炼羁绊与系统破解)。

## 实现入口

- `resources/trial/manifest.tres` 及引用资源：人物、标签、三敌阵、奖励与破解数据；新Resource类型位于 `game/content/`。新增同类羁绊不再修改角色编号分支，录入契约见 [内容录入](../content-authoring.md#三战试炼内容)。
- `game/trial/trial_catalog.gd`、`trial_content_validator.gd`：校验、只读注册与运行实例工厂，非法配置阻止进入／读写存档。
- `game/trial/trial_simulation.gd`：消费实际结算与动作事件，通用效果绑定、次数作用域、合作破解、维护来源、临时倍率及半血事件。
- `game/trial/trial_run.gd`：合法操作、奖励来源、装备归属、v2原子存档／备份／v1只读迁移、通关出发解锁。
- `scenes/trial/trial.gd`、`trial_board.gd`、`trial_actor.gd`：原生界面、事件驱动的只读人物／弹道／效果、暂停与战报保存重试；主菜单提供入口。

## 验证

PowerShell 7，Godot 4.7.2 Windows，命令从仓库根目录运行：

```powershell
pwsh.exe -File ./run-synergy-trial.ps1 -Check
pwsh.exe -File ./run-synergy-trial.ps1 -Capture
pwsh.exe -File ./run-battle-demo.ps1 -Smoke
```

- `-Check` 顺序运行以下场景，全部退出0：

| 场景 | 结果与覆盖 |
| --- | --- |
| `game/trial/trial_content_check.tscn` | 95 / 0；真实Resource、坏配置、扩展人物／羁绊、阶段奖励死路、固定出发装备与单训练边界 |
| `game/trial/trial_proc_check.tscn` | 70 / 0；六羁绊、效果作用域、动态资源组合、落空／死靶、盾吸收验证、临时倍率与永久间隔组合、贯穿几何 |
| `game/trial/trial_run_check.tscn` | 76 / 0；真实文件故障、事务回滚／重试、坏主档恢复、未来版本保护、v1各阶段迁移、奖励记录与换装 |
| `scenes/trial/trial_check.tscn` | 104 / 0；18组阵容／敌阵／破解选择，三条空构筑至逐场领奖完整流程、暂停、重复选择、倍速、重试与解锁 |
| `scenes/trial/trial_presentation_check.tscn` | 34 / 0；只读投影、事件无重复伤害、暂停、混合动画与死亡回退、帧率30/60/144与三种速度组合、特效回收 |
| `game/combat/accuracy_check.tscn` | 51 / 0；共享移动／索敌／命中／来源护盾，详见COMBAT-02 |
| 原 `action_check.tscn`、`auto_battle_check.tscn` | 均PASS，无失败 |

- 图形专项增加截图断言后35 / 0。完整 `-Capture` 在1600×900实际完成三战、两次领奖与通关；实际暂停断言验证模拟与视觉时间冻结、Board实例保留，未直接改胜负或跳过结算。
- 偏输出样本可在未满破解前通关；合作/解析样本可满条，后两场断开/接管产生不同战斗时长。当前样本通关不说明难度或两种选择已平衡。
- 图形实跑输出 `.godot/trial-prepare.png`、`trial-combat.png`、`trial-paused.png`、`trial-hack.png`、`trial-reward.png`、`trial-complete.png`，以及按场编号的过程图；已看图并在对话展示。截图入口必须实际抵达破解暂停并通关，未达成返回失败。所有试炼检查使用独立 `.godot` 测试档，不写玩家试炼存档。
- 原战斗Demo两敌阵、四装备分配与倍速一致性通过；探索场景 `-- --campaign-flow-check --order=012` 为124 / 0，`-- --run-smoke` 三条路线及输入／奖励／恢复／重试／暂停均PASS。
- 环境仍报告已有根证书读取错误；旧Demo仍有Kenney直接图片加载警告，新切片未据此声明Web导出通过。

## 边界与待统筹

- 这是固定三战的可玩切片，不是将羁绊/破解接入所有M1主线；主线profile和随机池未改。
- 数值仍为样本，真人试玩、手机/手柄、Web导出、所有阵容的胜率均待验；三战不强行等待以凑目标时长。
- 复用既有帧动画／混合表现，其他角色为程序全身占位；人物身份仍为虚构，既有资源批准状态不变。
- 当前支持已有事件／效果的声明组合；全新效果类型仍须实现处理器与检查。单训练、单种出发补给和人物数组追加约束见内容录入，不能宣称任意玩法只填数据即可。
- 存档故障注入故意制造一次 `.bak.tmp` 不可写错误，断言原档与回滚状态；须与真实脚本失败区分。
- 待统筹：主菜单入口、独立v2存档／迁移、局外试炼解锁与共享战斗修正。总览与Roadmap未修改。
