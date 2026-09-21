# CORE-05 · 六人羁绊与三战破解试炼

- 状态：原型（桌面流程与规则检查通过，真人趣味性待验）。
- 日期：2026-09-21；开发基线 `97f534e`；分支 `codex/synergy-hacking-trial`。
- 玩家入口：主菜单「三战试炼」；或 `pwsh.exe -File ./run-synergy-trial.ps1`。
- 规则事实源：[战斗文档](../battle-demo.md#三战试炼羁绊与系统破解)。

## 实现入口

- `game/trial/trial_catalog.gd`：六人、标签、三敌阵、奖励与运行实例工厂。
- `game/trial/trial_simulation.gd`：继承现有模拟器，处理合作破解、维护、护盾来源和羁绊。
- `game/trial/trial_run.gd`：合法操作、奖励幂等、装备归属、独立原子存档、通关出发解锁。
- `scenes/trial/trial.gd`、`trial_board.gd`：原生界面、战场只读投影、暂停选择与事件反馈；主菜单提供入口。

## 验证

PowerShell 7，Godot 4.7.2 Windows，命令从仓库根目录运行：

```powershell
pwsh.exe -File ./run-synergy-trial.ps1 -Check
pwsh.exe -File ./run-synergy-trial.ps1 -Capture
pwsh.exe -File ./run-battle-demo.ps1 -Smoke
```

- 规则检查：104 checks / 0 failures。包括18组阵容/敌阵/破解选择组合、三条从空构筑逐场领奖到通关的完整流程、暂停冻结、重复选择、技能命中贡献、不同队友验证、1×/2×确定性、护盾来源隔离、换装冲突、JSON恢复、实际重复写档、非法/失败写入。
- 偏输出样本可在未满破解前通关；合作/解析样本可满条，后两场断开/接管产生不同战斗时长。当前样本通关不说明难度或两种选择已平衡。
- 图形实跑输出 `.godot/trial-prepare.png`、`trial-hack.png`、`trial-reward.png`；截图入口必须实际抵达破解暂停，未抵达返回失败。图形检查用独立 `.godot/trial-capture.json`，规则检查用 `.godot/trial-check.json`，不写玩家试炼存档。
- 原有 `game/combat/action_check.tscn`：ACTION_CHECK PASS failures=0；原战斗Demo两敌阵、四装备分配与倍速一致性通过。
- 环境仍报告已有根证书读取错误；旧Demo仍有Kenney直接图片加载警告，新切片未据此声明Web导出通过。

## 边界与待统筹

- 这是固定三战的可玩切片，不是将羁绊/破解接入所有M1主线；主线profile和随机池未改。
- 数值为首次样本调整，真人试玩、手机/手柄、Web导出、所有阵容的胜率均待验；三战不强行等待以凑目标时长。
- 界面与头像为现有资源和原生控件，无新美术生产。人物身份仍为虚构占位。
- 待统筹：主菜单新增可玩入口、独立存档与局外试炼解锁。总览与Roadmap未修改。
