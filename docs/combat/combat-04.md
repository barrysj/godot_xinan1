# COMBAT-04 · 主线无需刷成长、路线与阵容有策略差异

- 功能 ID：COMBAT-04
- 所属系统：战斗
- 当前状态：原M0样本已验证；双流派校准部分验证，完整主线/真人平衡待验
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

主线无需刷成长、路线与阵容有策略差异。玩家价值：可理解且公平的难度。

## 实现与规则入口

- 实现入口：[random_checks.gd](../../scenes/expedition/random_checks.gd)
- 开发战斗样本入口：[run-battle-demo.ps1](../../run-battle-demo.ps1)、[demo_battle_presets.gd](../../game/combat/demo_battle_presets.gd)、[demo_options.gd](../../scenes/battle_demo/demo_options.gd)；使用原 `battle_demo.tscn` 和共享战斗模拟。操作见[战斗 Demo](rules.md)。
- 规则事实源：[设计](../campaign/design.md)
- 跨系统边界参见[集成约束](../development/integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E04、E13。编号和重跑入口见[共享验证目录](../development/verification.md)。
- 程序通过不等于真人体验、目标设备或美术审批通过。

### 开发战斗样本入口

验证日期：2026-10-09；代码基线：`2eaa397` 加本功能改动；Windows PowerShell 7、Godot 4.7.2。本次只补充开发演示工具验证，不重写原主线平衡结论。

| 命令 / 入口 | 结果与覆盖 |
| --- | --- |
| `pwsh.exe -NoProfile -File .\run-battle-demo.ps1 -Difficulty Easy -Smoke` | PASS，当前三人动画、真实战斗完成、暂停、重试不叠加属性、难度循环与遭遇对应背景 |
| 同命令 `-Difficulty Normal -Smoke` | PASS，常规属性样本完成 |
| 同命令 `-Difficulty Hard -Smoke` | PASS，三名角色各自覆盖待机、移动、攻击、施法、受击、濒危和退场；濒危 / 退场对应真实生命条件，正常进入失败结果 |
| 同命令 `-Difficulty Hard -Animations Formal -Smoke` | PASS，正式资源选择与完整战斗 |
| `pwsh.exe -NoProfile -File .\run-battle-demo.ps1 -Smoke` | PASS，保留旧手动夹具及 1× / 2×结果一致性 |
| 同脚本 `-CodeCheck` | `MAIN_CODE_CHECK checks=39 failures=0`，原主线集成检查 |
| `presentation_check.tscn`、`animation_check.tscn`（headless） | 均 PASS，共享表现与动画回归 |
| 同脚本 `-Difficulty Hard -Capture -CaptureAt 10.6 -Size <尺寸>` | 1920×1080、2560×1440、1920×1200 三种图形实机截图完成，断言实际像素尺寸一致；已查看构图、难度标题与当前三人动画 |
| 当时的无参数菜单，输入 `0` | 四个难度／手动选项正常退出；当前启动菜单已由 [DEV-01](../development/dev-01.md) 改为 Debug / Release，固定难度使用显式参数 |

难度检查逻辑位于 `scenes/battle_demo/demo_options_check.gd`，不另建场景或战斗时钟。独立日志为 `.godot/demo-{Easy,Normal,Hard}-{Current,Formal}-check.log`、`demo-manual-check.log`、`main-code-integration.log`；图形证据为 `.godot/demo-hard-live-<尺寸>.png`。缓存不属于永久交付；重新生成时按命令复制截图到对应尺寸文件。既有根证书存储错误和占位 PNG 原图加载警告不影响本轮完成标记。

## 已知边界与未完成项

40 条随机样本无永久成长可通关，四条需重配；无真人平衡数据

开发难度档是本地演示预设，不是正式校园的难度设置。2026-10-10人物收尾后，`Current`兼容路径和默认`Formal`均使用已批准的正式动画，不依赖已清理的中间候选。启动及难度切换不写入存档、不改共享资源定义，也不改变正式资产的审批状态。手机、Web、导出与陌生玩家体验未在本次入口验证。

## 统筹状态

2026-10-10已汇总到总览；后续在本档案就地维护当前能力、证据与边界。

已汇总（2026-10-10）：新增 Windows 开发战斗样本启动选项；原主线战斗、存档及平衡范围不变。全局总览与 Roadmap 本次未改。

## 双流派平衡基线补充（2026-10-07）

- b55139d、Godot4.7.2、PowerShell7；调用原战斗模拟器完成81固定配置及布阵/HP/装备/修复等成对诊断，参数与记录见docs/combat/research/combat-balance-evidence.json，具体设计只维护于docs/combat/rules.md的v0.3。
- 证据证明三队均存在不依赖装备/局外成长的三个敌阵可行布阵；站位与热修复能改变输出位存活和时长。不能扩大为完整校园随机路线、任何布阵、任意成长或真人趣味性已通过；原M0四十路线证据属于旧规则。
- 已知边界：当前训练执行/说明不一致、完整奖励池与最高既有成长未复核、晨读替换未纳入本轮、粗等待策略不是最优操作。等待策略与敌人周期变化未证明真人选择更有趣。
- 已汇总（2026-10-10）：新战斗链改变COMBAT-04所依据的规则，需以后重跑真实新档、原M1路线与最高旧成长；本次不更新整体快照。

## 原路线三敌阵实战（已汇总（2026-10-10））

2026-10-07，基线30389ff加工作树：新战役将既有教室Resource接第3站，原缩放及其余敌阵不改。两个真实新档各完成序章＋图书馆四战，教室实际预警／释放和自然核心生效可达；无头132／0、GUI154／0，完整战役固定基础队伍150／0。原始样本见docs/combat/research/combat-route-pressure-evidence.json，规则及兼容见CORE-05／battle-demo.md。此证据只覆盖两条自动策略与当次随机奖励，不能扩为任意布阵或真人趣味性已验证。
