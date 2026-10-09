# COMBAT-04 · 主线无需刷成长、路线与阵容有策略差异

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：COMBAT-04
- 所属系统：战斗
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

主线无需刷成长、路线与阵容有策略差异。玩家价值：可理解且公平的难度。

## 实现与规则入口

- 实现入口：[random_checks.gd](../../scenes/expedition/random_checks.gd)
- 开发战斗样本入口：[run-battle-demo.ps1](../../run-battle-demo.ps1)、[demo_battle_presets.gd](../../game/combat/demo_battle_presets.gd)、[demo_options.gd](../../scenes/battle_demo/demo_options.gd)；使用原 `battle_demo.tscn` 和共享战斗模拟。操作见[战斗 Demo](../battle-demo.md)。
- 规则事实源：[设计](../game-design.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E04、E13。编号和重跑入口见[共享验证目录](verification.md)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
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
| 当时的无参数菜单，输入 `0` | 四个难度／手动选项正常退出；当前启动菜单已由 [DEV-01](dev-01.md) 改为 Debug / Release，固定难度使用显式参数 |

难度检查逻辑位于 `scenes/battle_demo/demo_options_check.gd`，不另建场景或战斗时钟。独立日志为 `.godot/demo-{Easy,Normal,Hard}-{Current,Formal}-check.log`、`demo-manual-check.log`、`main-code-integration.log`；图形证据为 `.godot/demo-hard-live-<尺寸>.png`。缓存不属于永久交付；重新生成时按命令复制截图到对应尺寸文件。既有根证书存储错误和占位 PNG 原图加载警告不影响本轮完成标记。

## 已知边界与未完成项

40 条随机样本无永久成长可通关，四条需重配；无真人平衡数据

开发难度档是本地演示预设，不是正式校园的难度设置。`Current` 依赖本工作区的美术候选（守护者 `tmp_001`、远射手 `tmp_004`、冲刺手 `tmp_005`），资源未随本功能提交；其他工作区可显式选择 `Formal`。启动及难度切换不写入存档、不改共享资源定义，也不改变正式资产的审批状态。手机、Web、导出与陌生玩家体验未在本次入口验证。

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。

待统筹：新增 Windows 开发战斗样本启动选项；原主线战斗、存档及平衡范围不变。全局总览与 Roadmap 本次未改。
