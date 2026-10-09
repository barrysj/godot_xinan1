# DEV-01 · Debug 模式与独立启动入口

- 功能 ID：DEV-01
- 所属系统：开发工具
- 当前状态：已验证
- 验证日期：2026-10-09
- 基线：从 main `10dfbcd` 创建 `codex/debug-tools`，正式重开基线 `77afbd3`，其后为本功能提交。

## 玩家／开发者能力与接入范围

显式启动 Debug，右上角按钮／F8 打开面板；跳过战斗、保留构筑重开战斗、重抽未消费事件／记录或待选奖励。主线与旧活动局使用各自既有结算入口。独立调试存档，普通启动关闭能力；正式重开由 SAVE-02 维护。

战斗或未领取结果的战报中，四人已部署时可选择简单、普通、困难并“应用重开”：保留当前遭遇和构筑，满血清空统计后立即开战。选择仅在当前 Debug 进程保留，不加入存档或正式玩家难度设置。

`run-battle-demo.ps1` 无参数启动只选择 Debug / Release，回车默认 Debug。Debug 通过原校园序章入口新建战斗，四人自动部署并立即开战，使用最新正式动画和临时预览档；Release 进入校园基地，使用正式资源和正常档。难度选择在游戏内 Debug 面板；固定难度参数仅保留给显式战斗试验。`run-debug.ps1` 保留完整校园 Debug 进度入口。

## 实现与规则入口

- 使用与行为事实源：[Debug 模式](../debug-mode.md)。
- `run-battle-demo.ps1`、`run-debug.ps1`、`game/debug/campus_debug.gd`、`scenes/expedition/debug_panel.gd`、`campaign_hub.gd`。
- 检查入口：`scenes/expedition/debug_check.gd`、`debug_battle_check.gd`；共享命令见[验证 E23](verification.md#debug-与重开存档-e23)。

## 验证与证据

- 2026-10-10 美术收尾：五人 asset_002 已批准并正式提升，Debug／Release 同用正式包，Current 兼容稳定路径；原 Debug 自动开战、难度重开、三尺寸与存档隔离保留。验证结果见 ART-02／ART-03 与人物任务，旧本地候选证据已按仅最终稿授权清理。待统筹。

- 2026-10-09，战斗启动修复基线 `d269b50` 加本功能改动，PowerShell 7 / Godot 4.7.2。上一版将启动映射到基地，旧检查自行建立遭遇，未覆盖用户实际启动后能否直接开战；此前截图不能证明默认启动可进入战斗。现启动使用 `--campus-debug --debug-battle`，沿用原序章、部署、开战、战报和保存接口；不读旧预览缓存，不覆盖正式或完整校园调试档。
- 入口修复当时的真实启动检查 `run-battle-demo.ps1 -Mode Debug -Smoke`：37／0；正式动画配置 `-Animations Formal -Smoke`：34／0；`-Mode Debug -Capture`：42／0。覆盖启动即战斗、四人部署、实际模拟推进、F8 打开面板、三档与重复困难、鼠标点击应用、满血及构筑保留、战报再次重开、三尺寸截图及两个玩家档字节不变；先写入损坏预览缓存仍正常启动。截图 `.godot/debug-battle-launch-{1920x1080,2560x1440,1920x1200}.png` 与 `debug-battle-launch-menu.png` 已目视并在对话展示。回归 `run-debug.ps1 -Check`：169／0，Release `-Smoke`：6／0，原 `-CodeCheck`：39／0。

- 2026-10-09，启动菜单基线 `63ab01a` 加本功能改动，PowerShell 7 / Godot 4.7.2。`run-battle-demo.ps1 -Mode Debug -Smoke`：169 checks / 0 failures；同模式 `-Capture`：193 checks / 0 failures，包含实际鼠标应用重开与三种尺寸。`-Mode Release -Smoke`：6 checks / 0 failures，调试面板与命令关闭；同模式 `-Capture`：主线集成 41 checks / 0 failures。`-Mode Debug -Animations Formal -Smoke`：169 checks / 0 failures。菜单非法输入 `99` 后重新询问，输入 `0` 正常退出；模式与固定难度混用、Release 加当前候选均明确拒绝。
- 启动兼容检查：无模式 `-Smoke` 保留手动正式夹具，`DEMO_SPEED` 两倍速结果一致；`-Difficulty Hard -Smoke` 为 `DEMO_DIFFICULTY_CHECK result=PASS`，三名候选均覆盖七种状态；`-CodeCheck` 为 39 checks / 0 failures。实际截图 `.godot/launcher-debug-menu.png`、`main-code-hud-1920x1080.png` 已目视并在对话展示；Debug 图形日志留存 `.godot/launcher-debug-capture.log`，其余脚本日志见主题文档。截图和日志为可重建缓存，不作为正式资产。

- 2026-10-09，基线 `6173ad7` 加本功能改动，PowerShell 7 / Godot 4.7.2。`run-debug.ps1 -Check`：169 checks / 0 failures；`-Capture`：193 checks / 0 failures。主线与旧活动局均覆盖三档、连续两次困难、选择不立即应用、实际按钮点击后自动开战、恢复生命与本场统计、阵容／装备／成长／敌阵保留、存档仅正常记录游玩时间而无难度字段、缺员和已领取结果拒绝、保存失败不应用。普通模式 `--debug-check`：6 checks / 0 failures；`--campaign-flow-check`：148 checks / 0 failures；原 `run-battle-demo.ps1 -CodeCheck`：39 checks / 0 failures。
- 本轮图形证据：`.godot/debug-difficulty-menu-{1920x1080,2560x1440,1920x1200}.png`、`debug-difficulty-restarted.png`。三种尺寸均检查菜单构图、控件位置与实际像素尺寸；图形重开操作用真实 Viewport 鼠标点击应用按钮。日志 `.godot/debug-difficulty-{headless,graphical,disabled,campaign}.log`，缓存可由上述入口重建。旧遍历夹具补齐人物奖励归属步骤，保留原奖励与终局断言；失败时及时终止并报告阻断原因。

- 2026-09-17，基线 `7160568` 后改为居中弹窗与半透明遮罩，背景保留当前场景；沿用暂停、快捷键与角落入口。`run-debug.ps1 -Capture`：71 checks / 0 failures，新增弹窗四周可见背景、实际点击遮罩关闭且不触发下层菜单检查；实际截图 `.godot/debug-battle-panel.png`、`debug-reward-panel.png`。待统筹：仅调整调试界面呈现，无存档或玩法规则变化。

- `pwsh.exe -File .\run-debug.ps1 -Check`：59 checks / 0 failures。
- `pwsh.exe -File .\run-debug.ps1 -Capture`：69 checks / 0 failures，含真实角落按钮鼠标点击、三尺寸像素与菜单不相交断言。截图 `.godot/debug-corner-1920x1080.png`、其余两尺寸、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`。
- 关闭模式 `-- --debug-check`：5 checks / 0 failures；主线回归 `-- --campaign-flow-check`：124 checks / 0 failures。
- 覆盖真实战斗推进后暂停／重开，HP／统计／构筑保留，主线三地区及终局正常结算，重复跳过禁止，重抽确实改变候选与磁盘续玩一致，保存失败回滚，旧随机事件／奖励快照可恢复，正式存档字节不变。故障注入使用不可写入的目录，未模拟断电／磁盘满。

## 已知边界与待统筹

- Windows Godot 4.7.2 Compatibility 图形与 headless 已验证；本功能尚未做 Web／Android 导出与交互验收，启动脚本为 Windows PowerShell 7。
- 启动菜单的 Release 是本地正常试玩模式，不执行发行包导出。Debug 默认候选依赖当前工作区，缺少候选时可显式使用 `-Animations Formal`。
- 不增加事件内容、不重抽固定地图；已消费结果不回退；不提供正式档导入调试档按钮。独立战斗实验室不接入此主流程 Debug 面板。
- 待统筹：新增开发启动方式和独立档案路径；正式基地重开能力见 SAVE-02。未改高层总览／Roadmap。
- 待统筹：本次新增战斗中 Debug 难度调整与即时重开，仅在显式启用模式下给现有遭遇临时应用属性倍率；共用原重开、保存与战斗入口，不改变正式难度、存档 schema 或主线节点。
- 待统筹：战斗启动菜单统一为 Debug / Release；Debug 直接启动原序章战斗，临时工作区预览档沿用现有存档编解码，完整校园 Debug 入口仍保留。显式固定难度和原检查参数继续使用已有夹具，无新增存档 schema、战斗系统或发行平台。


清理后最终复验：资源台39项单测／0失败，五对象 warnings=[]、正式内容全部 matched、缺失／不一致 0；五人各七态与守护者旧 asset_001 检查通过，35 动作 GIF＋5 巡演已重录；7 个原配／派生源模型重开，28 动作原始曲线指纹通过。Debug 正式启动捕获39／0、Release6／0，Current兼容38／0；正式实录22.6秒／339帧／678步／344事件与批准候选一致，MP4完整解码通过。65个已核验目标清理约5.56GiB，最终资源、许可证、旧守护者62帧保留；历史有效工具归档。验证日期2026-10-10，基线667e60e＋收尾工作树。
