# CORE-05 · 原主线羁绊、破解与战后强化

- 状态：已接入校园主线；桌面工程验证通过；数值和真人趣味性待验。
- 当前玩家入口：原主菜单 → 校园流程 → 胜利战报 → 战利品。
- 规则事实源：[战斗文档](../battle-demo.md#原主线战斗接入)。内容录入：[内容录入](../content-authoring.md#主线羁绊与代码资源接入)。

## 实现入口

- 模拟规则：`game/combat/synergy_simulation.gd`、`code_battle_simulation.gd`；沿用原 BattleSimulation 的结算、伤害和事件时序。
- 原战斗操作：`scenes/battle_demo/code_panel.tscn` 与 `code_panel.gd`；代码掉落与收集：`code_fx.gd`、`code_sockets.gd`。
- 战后奖励进入校园既有 `RewardCatalog`、`ShortRun`、`campaign_hub` 与 `campaign_panel`。六种强化保存在当前构筑，角色选择类奖励有独立选择页。
- 定义仍使用 `resources/trial/` 下已校验的人物、羁绊、奖励、破解和代码 Resource；主菜单独立试炼入口已移除，但独立试炼代码尚待清理与依赖核验。

## 验证与交付

2026-09-24，基线 `b4b091e` 加奖励接入工作树；PowerShell 7 / Godot 4.7.2 Windows。

- `pwsh.exe -File ./run-battle-demo.ps1 -EnginePath <Godot 4.7.2 console> -CodeCheck`：`MAIN_CODE_CHECK checks=35 failures=0`，覆盖六种强化候选、应用和去重，程序／道具、绑定效果、构筑 schema 7 与 schema 5 迁移、对象选择检查点、真实战斗胜利及库存提交。
- 同命令 `-CodeCapture`：`MAIN_CODE_CHECK checks=37 failures=0`，截图实际原校园战后混合奖励卡、强化对象选择页、终端与战斗。截图位于 `.godot/main-code-rewards.png`、`main-code-reward-owner.png`、`main-code-terminal-1920x1080.png` 和 `main-code-battle.png`。
- `expedition.tscn -- --campaign-flow-check`：`CAMPAIGN_FLOW checks=124 failures=0`；`expedition.tscn -- --run-smoke`：原短局三路线、奖励、恢复及暂停流程 PASS。
- `game/combat/synergy_check.tscn`：羁绊和通用效果回归；`game/trial/trial_content_check.tscn`：共享 Resource 定义校验。旧独立试炼其余实现尚未清理，见当前边界。
- `game/combat/code_rules_check.tscn`：`CODE_CHECK checks=48 failures=0`；`synergy_check.tscn`：`SYNERGY_CHECK checks=70 failures=0`；共享内容 `game/trial/trial_content_check.tscn`：`TRIAL_CONTENT_CHECK PASS checks=95 failures=0`。
- 原 M1 区域流程、随机路线、暂停、部署、内容和图鉴入口沿用 E32 回归，不代表本次重新证明手机、手柄或导出。

## 当前边界

六项试炼强化已接入校园原战利品候选池，与原奖励共同抽取；每项强化每局限领一次。角色专属奖励仅在对应人物已进入本局队伍或候补名单时出现，角色培养类奖励进入对象选择页，装备受原有单件装备规则限制。奖励数量、出现率和强度尚待真人试玩调整；历史活动存档保留原队伍，分析员仅加入新局候补。移动设备、手柄和导出未验。

独立试炼主菜单入口已经移除，重复模拟和规则回归入口已迁至 `game/combat/`。其余独立试炼场景、短局存档模型及启动脚本仍在工作树中；批量删除尚未完成，须先核验并移除文档、UID、内容校验和回归入口对旧路径的引用，再按明确范围清理。共享的 `resources/trial/` 定义、`trial_catalog.gd` 与内容校验流程继续由主线使用，不属于冗余删除目标。
