# CORE-05 · 原主线羁绊、破解与战后强化

- 状态：已接入校园主线；桌面工程验证通过；数值和真人趣味性待验。
- 当前玩家入口：原主菜单 → 校园流程 → 胜利战报 → 战利品。
- 规则事实源：[战斗文档](../battle-demo.md#原主线战斗接入)。内容录入：[内容录入](../content-authoring.md#主线羁绊与代码资源接入)。

## 实现入口

- 模拟规则：`game/combat/synergy_simulation.gd`、`code_battle_simulation.gd`；沿用原 BattleSimulation 的结算、伤害和事件时序。
- 原战斗操作：`scenes/battle_demo/code_panel.tscn` 与 `code_panel.gd`；代码掉落与收集：`code_fx.gd`、`code_sockets.gd`。
- 战后奖励进入校园既有 `RewardCatalog`、`ShortRun`、`campaign_hub` 与 `campaign_panel`。六种强化保存在当前构筑，角色选择类奖励有独立选择页。
- 定义使用 `resources/combat/` 下已校验的人物标签、羁绊、奖励和代码 Resource；共享目录在 `game/combat/combat_content_catalog.gd`，校验在 `game/content/combat_content_check.tscn`。旧独立试炼入口和专属代码已移除。

## 验证与交付

2026-09-24，基线 `b4b091e` 加奖励接入工作树；PowerShell 7 / Godot 4.7.2 Windows。

2026-09-24，共享资源改名基线 `b8ff16d`，清理基线 `f44cdf4` 加当前工作树；PowerShell 7 / Godot 4.7.2 Windows。改名后 `-CodeCheck` 35/0、`-CodeCapture` 37/0；校园流程 124/0、短局 smoke PASS；代码规则 47/0、羁绊 69/0、共享内容 40/0。截图重新生成于 `.godot/main-code-rewards.png`。旧独立试炼专属文件已清理，清理后复测结果见下。

清理后 Godot 编辑器无脚本解析错误；`-CodeCapture` 37/0、校园流程 124/0、短局 smoke PASS、代码规则 47/0、羁绊 69/0、共享内容 40/0。主线之外的旧三战回归入口随专属场景删除，不再作为当前验收。

- `pwsh.exe -File ./run-battle-demo.ps1 -EnginePath <Godot 4.7.2 console> -CodeCheck`：`MAIN_CODE_CHECK checks=35 failures=0`，覆盖六种强化候选、应用和去重，程序／道具、绑定效果、构筑 schema 7 与 schema 5 迁移、对象选择检查点、真实战斗胜利及库存提交。
- 同命令 `-CodeCapture`：`MAIN_CODE_CHECK checks=37 failures=0`，截图实际原校园战后混合奖励卡、强化对象选择页、终端与战斗。截图位于 `.godot/main-code-rewards.png`、`main-code-reward-owner.png`、`main-code-terminal-1920x1080.png` 和 `main-code-battle.png`。
- `expedition.tscn -- --campaign-flow-check`：`CAMPAIGN_FLOW checks=124 failures=0`；`expedition.tscn -- --run-smoke`：原短局三路线、奖励、恢复及暂停流程 PASS。
- `game/combat/code_rules_check.tscn`：`CODE_CHECK checks=47 failures=0`；`synergy_check.tscn`：`SYNERGY_CHECK checks=69 failures=0`；`game/content/combat_content_check.tscn`：`COMBAT_CONTENT_CHECK checks=40 failures=0`。共享校验只覆盖当前主线定义；旧三战校验用例已移除。
- 原 M1 区域流程、随机路线、暂停、部署、内容和图鉴入口沿用 E32 回归，不代表本次重新证明手机、手柄或导出。
- 2026-09-24，基线 `d8efeb2` 加当前工作树：战役模式恢复粉笔精灵混合动画，主线原场景直接创建并驱动表现场景；`campaign_animation_check.tscn` 7/0、图形截图 8/0，校园流程 124/0、短局 smoke 和代码检查 35/0。动画资源未修改，视觉接入评审仍见 ART-02。

## 当前边界

六项试炼强化已接入校园原战利品候选池，与原奖励共同抽取；每项强化每局限领一次。角色专属奖励仅在对应人物已进入本局队伍或候补名单时出现，角色培养类奖励进入对象选择页，装备受原有单件装备规则限制。奖励数量、出现率和强度尚待真人试玩调整；历史活动存档保留原队伍，分析员仅加入新局候补。移动设备、手柄和导出未验。

独立试炼主菜单入口、专属场景、短局存档模型和启动脚本已移除，规则与回归入口统一在 `game/combat/`。共享的 `resources/combat/` 定义、`combat_content_catalog.gd` 与内容校验流程继续由主线使用。
