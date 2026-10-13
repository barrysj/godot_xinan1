# DEV-01 · Debug 模式与独立启动入口

- 功能 ID：DEV-01
- 所属系统：开发工具
- 当前状态：已验证
- 验证日期：2026-10-13
- 基线：从 main `10dfbcd` 创建 `codex/debug-tools`，正式重开基线 `77afbd3`，其后为本功能提交。

## 玩家／开发者能力与接入范围

显式启动 Debug，右上角按钮／F8 打开面板；跳过战斗、保留构筑重开战斗、重抽未消费事件／记录或待选奖励。主线与旧活动局使用各自既有结算入口。独立调试存档，普通启动关闭能力；正式重开由 SAVE-02 维护。

战斗或未领取结果的战报中，四人已部署时可选择简单、普通、困难并“应用重开”：保留当前遭遇和构筑，满血清空统计后立即开战。选择仅在当前 Debug 进程保留，不加入存档或正式玩家难度设置。

日常双击项目根目录的 `CampusDebugLauncher.exe`／`CampusReleaseLauncher.exe`。Debug 包含直接战斗、完整校园调试、正常游戏和检查页；Release 仅正常游戏。使用原主流程、正式资源和现有独立档，详细契约见[Windows 启动器](launcher.md)。原命令行启动脚本已收进 `tools/` 作为内部后端和自动化夹具。

## 实现与规则入口

- 使用与行为事实源：[Debug 模式](debug.md)。
- `tools/game_launcher/GameLauncher.cs`、`tools/game_launcher/launch-action.ps1`、`game/debug/campus_debug.gd`、`game/debug/battle_tuning.gd`、`scenes/expedition/debug_panel.gd`、`battle_tuning_panel.gd`、`campaign_hub.gd`。
- 检查入口：`scenes/expedition/debug_check.gd`、`debug_battle_check.gd`；共享命令见[验证 E23](verification.md)。

## 验证与证据

- 2026-10-10 美术收尾：五人 asset_002 已批准并正式提升，Debug／Release 同用正式包，Current 兼容稳定路径；原 Debug 自动开战、难度重开、三尺寸与存档隔离保留。验证结果见 ART-02／ART-03 与人物任务，旧本地候选证据已按仅最终稿授权清理。已汇总（2026-10-10）。

- 2026-10-09，战斗启动修复基线 `d269b50` 加本功能改动，PowerShell 7 / Godot 4.7.2。上一版将启动映射到基地，旧检查自行建立遭遇，未覆盖用户实际启动后能否直接开战；此前截图不能证明默认启动可进入战斗。现启动使用 `--campus-debug --debug-battle`，沿用原序章、部署、开战、战报和保存接口；不读旧预览缓存，不覆盖正式或完整校园调试档。
- 入口修复当时的真实启动检查 `tools/game_launcher/legacy/run-battle-demo.ps1 -Mode Debug -Smoke`：37／0；正式动画配置 `-Animations Formal -Smoke`：34／0；`-Mode Debug -Capture`：42／0。覆盖启动即战斗、四人部署、实际模拟推进、F8 打开面板、三档与重复困难、鼠标点击应用、满血及构筑保留、战报再次重开、三尺寸截图及两个玩家档字节不变；先写入损坏预览缓存仍正常启动。截图 `.godot/debug-battle-launch-{1920x1080,2560x1440,1920x1200}.png` 与 `debug-battle-launch-menu.png` 已目视并在对话展示。回归 `tools/game_launcher/legacy/run-debug.ps1 -Check`：169／0，Release `-Smoke`：6／0，原 `-CodeCheck`：39／0。

- 2026-10-09，启动菜单基线 `63ab01a` 加本功能改动，PowerShell 7 / Godot 4.7.2。`tools/game_launcher/legacy/run-battle-demo.ps1 -Mode Debug -Smoke`：169 checks / 0 failures；同模式 `-Capture`：193 checks / 0 failures，包含实际鼠标应用重开与三种尺寸。`-Mode Release -Smoke`：6 checks / 0 failures，调试面板与命令关闭；同模式 `-Capture`：主线集成 41 checks / 0 failures。`-Mode Debug -Animations Formal -Smoke`：169 checks / 0 failures。菜单非法输入 `99` 后重新询问，输入 `0` 正常退出；模式与固定难度混用、Release 加当前候选均明确拒绝。
- 启动兼容检查：无模式 `-Smoke` 保留手动正式夹具，`DEMO_SPEED` 两倍速结果一致；`-Difficulty Hard -Smoke` 为 `DEMO_DIFFICULTY_CHECK result=PASS`，三名候选均覆盖七种状态；`-CodeCheck` 为 39 checks / 0 failures。实际截图 `.godot/launcher-debug-menu.png`、`main-code-hud-1920x1080.png` 已目视并在对话展示；Debug 图形日志留存 `.godot/launcher-debug-capture.log`，其余脚本日志见主题文档。截图和日志为可重建缓存，不作为正式资产。

- 2026-10-09，基线 `6173ad7` 加本功能改动，PowerShell 7 / Godot 4.7.2。`tools/game_launcher/legacy/run-debug.ps1 -Check`：169 checks / 0 failures；`-Capture`：193 checks / 0 failures。主线与旧活动局均覆盖三档、连续两次困难、选择不立即应用、实际按钮点击后自动开战、恢复生命与本场统计、阵容／装备／成长／敌阵保留、存档仅正常记录游玩时间而无难度字段、缺员和已领取结果拒绝、保存失败不应用。普通模式 `--debug-check`：6 checks / 0 failures；`--campaign-flow-check`：148 checks / 0 failures；原 `tools/game_launcher/legacy/run-battle-demo.ps1 -CodeCheck`：39 checks / 0 failures。
- 本轮图形证据：`.godot/debug-difficulty-menu-{1920x1080,2560x1440,1920x1200}.png`、`debug-difficulty-restarted.png`。三种尺寸均检查菜单构图、控件位置与实际像素尺寸；图形重开操作用真实 Viewport 鼠标点击应用按钮。日志 `.godot/debug-difficulty-{headless,graphical,disabled,campaign}.log`，缓存可由上述入口重建。旧遍历夹具补齐人物奖励归属步骤，保留原奖励与终局断言；失败时及时终止并报告阻断原因。

- 2026-09-17，基线 `7160568` 后改为居中弹窗与半透明遮罩，背景保留当前场景；沿用暂停、快捷键与角落入口。`tools/game_launcher/legacy/run-debug.ps1 -Capture`：71 checks / 0 failures，新增弹窗四周可见背景、实际点击遮罩关闭且不触发下层菜单检查；实际截图 `.godot/debug-battle-panel.png`、`debug-reward-panel.png`。已汇总（2026-10-10）：仅调整调试界面呈现，无存档或玩法规则变化。

- `pwsh.exe -File .\tools/game_launcher/legacy/run-debug.ps1 -Check`：59 checks / 0 failures。
- `pwsh.exe -File .\tools/game_launcher/legacy/run-debug.ps1 -Capture`：69 checks / 0 failures，含真实角落按钮鼠标点击、三尺寸像素与菜单不相交断言。截图 `.godot/debug-corner-1920x1080.png`、其余两尺寸、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`。
- 关闭模式 `-- --debug-check`：5 checks / 0 failures；主线回归 `-- --campaign-flow-check`：124 checks / 0 failures。
- 覆盖真实战斗推进后暂停／重开，HP／统计／构筑保留，主线三地区及终局正常结算，重复跳过禁止，重抽确实改变候选与磁盘续玩一致，保存失败回滚，旧随机事件／奖励快照可恢复，正式存档字节不变。故障注入使用不可写入的目录，未模拟断电／磁盘满。

## 已知边界与已汇总（2026-10-10）

- Windows Godot 4.7.2 Compatibility 图形与 headless 已验证；本功能尚未做 Web／Android 导出与交互验收，启动脚本为 Windows PowerShell 7。
- 启动菜单的 Release 是本地正常试玩模式，不执行发行包导出。Debug／Release 默认使用正式动画；Current 兼容正式路径，不依赖已经清理的中间候选。
- 不增加事件内容、不重抽固定地图；已消费结果不回退；不提供正式档导入调试档按钮。独立战斗实验室不接入此主流程 Debug 面板。
- 已汇总（2026-10-10）：新增开发启动方式和独立档案路径；正式基地重开能力见 SAVE-02。未改高层总览／Roadmap。
- 已汇总（2026-10-10）：本次新增战斗中 Debug 难度调整与即时重开，仅在显式启用模式下给现有遭遇临时应用属性倍率；共用原重开、保存与战斗入口，不改变正式难度、存档 schema 或主线节点。
- 已汇总（2026-10-10）：战斗启动菜单统一为 Debug / Release；Debug 直接启动原序章战斗，临时工作区预览档沿用现有存档编解码，完整校园 Debug 入口仍保留。显式固定难度和原检查参数继续使用已有夹具，无新增存档 schema、战斗系统或发行平台。


正式人物包与源工具的检查统一见[ART-03](../art/art-03.md)和[美术验证](../art/verification.md)。

## 调试自检适配强化归属（2026-10-07）

基线9a52d06合并敌人资产后的工作树。run-debug -Check首次复验暴露debug_check.gd旧流程只点reward:0、未处理reward_owner，导致无法离站却无限重复skip region guard。仅更新自检：完成合法强化归属、核验奖励领取，遍历设有上限，skip失败立即退出；玩家调试命令与存档格式不变。

PowerShell7执行 ./tools/game_launcher/legacy/run-debug.ps1 -Check，通过72检查／0失败，正常档字节未变。日志.godot/debug-mode.log。本次初次失败不计作通过；旧原图直接读取提示仍在。已汇总（2026-10-10）：自检覆盖当前对象型强化步骤。


## 独立暂停兼容（2026-10-08，已汇总（2026-10-10））

基线45a6513＋当前HUD试用工作树。调试面板不再通过打开再隐藏菜单来暂停，而是保存paused和菜单可见性，直接冻结；关闭后恢复原状态，不让手动暂停变成菜单，也不污染pause_before_menu。跳过／重开等调试命令清掉暂停后进入既有主线操作。入口debug_panel.gd，回归debug_check.gd，隔离调试档与玩家原档不变。

PowerShell7 / Godot4.7.2 Compatibility：`./tools/game_launcher/legacy/run-debug.ps1 -Check -EnginePath <Godot console>`为74／0；`-Capture`为86／0，包含真实调试按钮点击、三桌面尺寸、手动暂停退出调试、从菜单进入再关闭菜单恢复运行。此前失败为Escape关闭调试后残留暂停，已修复。实际截图debug-panel-pause.png保存在design/concepts/ui/battle-status/review/codex-workflow，已查看。未验证Web／移动端。已汇总（2026-10-10）：兼容UI-01独立暂停；不增加存档字段。

## 正式动画与独立暂停合并验证（2026-10-10，已汇总（2026-10-10））

基线ed4d275＋main c3dc5c2。debug_panel保留独立暂停和原菜单可见性恢复，同时将所选难度传给main新增命令；debug_check沿用完整奖励归属筛选，并按真实事件选项结束多轮记忆后再离站，保留重抽拒绝、遍历上限和失败诊断。没有修改玩家事件或存档规则。PowerShell7执行tools/game_launcher/legacy/run-debug.ps1 -Check为174／0，tools/game_launcher/legacy/run-battle-demo.ps1 -Mode Debug -Smoke34／0、-Capture39／0；三规定尺寸实机图debug-battle-launch-*已核验，原玩家档保持不变。完整战役149／0、独立暂停与慢速51／0、多轮事件GUI197／0。日志.godot/campus-main-merge-*及debug-mode.log；Web／移动端未验证。

## 启动导入与依赖预检（待统筹）

2026-10-13，main 82a04c9＋codex/godot-startup-guard：run-campus-demo／run-battle-demo／run-debug已共用启动预检；Release启动集成6／0、Debug入口174／0；可安装仅main触发的Git hooks，原生Git回归14／0，真实仓库尚未启用。tools/development/check-project.ps1与共享project-health.ps1自动准备当前checkout导入，加载原主入口并对日志／成功标记判错。检测失败只修复复验一次，真正代码错误阻止启动；独立profile不接入另一套存档。真实引擎回归14／0，原项目预检9／0；实现契约、命令及覆盖见[工程预检](project-health.md)。待统筹：开发启动／合并验收增加本地预检，平台与玩法范围不变。

## Windows 独立启动器与入口收归（待统筹）

2026-10-13，基线 codex/godot-startup-guard 6c3053c 加本功能，分支 codex/windows-game-launcher。原 10 个根目录启动／检查脚本移到 tools/ 对应目录，更新资源台信任路径、hooks 分发和文档引用；内部高级夹具保留，日常使用两个已构建的 GUI EXE。Debug 日常入口保留校园调试、直接原序章战斗和正常游戏；检查页只提供一键检查／修复工程，细分校验与 hooks 转为内部自动化。Release 仅正常游戏。窗口读取共用颜色 Token，状态由后台事件更新，锁保护同工作区重入，失败可查看日志。

原生窗口最小／扩大尺寸、动作名、默认 Enter 入口／TabStop 和源码／二进制一致性：Debug 36／0、Release 9／0；实际按钮调用工程预检9／0、原战斗34／0、完整校园调试174／0、Release调试关闭6／0、内容校验errors=0。工程预检捕获命令行分隔符后的日志参数错误并修复；两个已复现的 Android EditorSettings 退出提示只作 Windows 无关项过滤，其他脚本／资源／编辑器错误保持阻断。

最终使用默认 GUI Godot 引擎串行执行 `tools/game_launcher/test-launchers.ps1 -EnginePath <Godot GUI.exe>`：30／0，包含上述按钮、实际缓存修复、缺引擎／并发占用错误提示、两档字节不变，以及“战斗试玩”进入真实渲染场景。图形战斗39／0，实际截图覆盖1920×1080、2560×1440、1920×1200和F8面板；已目视。共享工程预检回归新增三项错误分类后17／0。PowerShell解析25文件错误0，197份文档／41功能ID／895链接错误0，差异空白检查通过。

资源台 Python45／0、原生 Git hooks14／0；原工具集在有空格的独立工程目录完成首次构建、缓存复用、过期重建三种真实窗口验证；迁移后闪卡 GUI HOLO_LAUNCH_CHECK PASS。正式及完整校园调试档字节不变；高级夹具与主流程仍使用原存档接口。命令与入口见[启动器](launcher.md)；截图、日志和回归夹具在 .godot/art-workflow/game-launcher，已在对话展示两态原生窗口。

已知边界：只验证 Windows 本地源码入口，需要 Godot／PowerShell7，不执行发行导出。既有默认动作预览夹具在旧基线与迁移后均报告施法姿势取样未命中；保留的 CodeCheck 旧夹具仍存在主线奖励卡／旧技能数组断言失败，本轮未修改其 GDScript 或游戏规则，不能用历史39／0宣布当前夹具通过。新启动器使用已通过的原校园与直接战斗专项。真实仓库尚未启用 hooks。

待统筹：日常开发／用户启动入口改为独立原生窗口，根目录旧脚本不再是操作入口；本轮不改高层总览／Roadmap。

当前检查页精简核验（2026-10-13，基线9d0a8ae）：只显示一键检查／修复工程，检查页Enter默认一键检查。两个原生窗口实际运行并截图，最小／扩大尺寸和入口／二进制一致性回归Debug21／0、Release9／0，文档链接895／0。启动后端与存档规则不变；截图.godot/art-workflow/game-launcher/Debug-compact.png已在对话展示。内部回归入口test-launchers.ps1随可见操作更新。
## 当前战斗修改器与直接整备（待统筹）

2026-10-13，基线76b9540加本功能，codex/windows-game-launcher。战斗试玩沿用原序章四人阵容，停在整备；战场拖动双方角色移动／交换原阵位，单击角色弹出换人及六属性菜单。快捷菜单应用后满血返回整备，取消恢复此前暂停，F8切换无残留暂停；完整场景修改器保留10种敌人／空位、背景预览、六属性与己方倍率，整备中应用不自动开战。角色替换、绝对属性只绑定本次战斗，不改共享Resource、原人物解锁和存档schema；原手牌与预览跟随替换，友方重复部署禁止。行为与入口见[战斗修改器](battle-tuning.md)。

敌方显示统一朝左，首次创建即初始化，不受移动或攻击目标反向影响；原模拟寻路与弹道方向保持。全部已注册敌人覆盖四种逻辑方向、帧镜像标记、混合节点上下文；`presentation_check.tscn`完成原30／60／144fps与速度、暂停、重开的模拟／事件一致性回归，PASS／0失败。原部署使用`deployment_check.tscn -- --deployment-check`的隔离入口，PASS／0失败；省略该标志会进入普通校园界面，不能作为此夹具的验收命令。

PowerShell7／Godot4.7.2：`tools/development/tests/battle-tuning.test.ps1`无头完整修改器50／0、直接整备61／0；GUI -Capture完整修改器70／0、直接整备68／0；两项关闭模式各2／0。覆盖实际鼠标拖动／交换／非法落点／Esc、双方单击菜单、实际键盘输入与点击应用、技能和身份替换、六属性、草稿隔离、原模拟、保存失败后保留配置／菜单并重试、暂停恢复、F8切换、默认恢复和地点清除、存档字节与原资源不变。

三尺寸1920×1080、2560×1440、1920×1200实际运行，快捷菜单及按钮完整位于可视区，截图`.godot/battle-preparation-ally-<尺寸>.png`、`battle-preparation-enemy-menu.png`、`battle-preparation-drag.png`及原完整修改器截图已目视并在对话展示。复用现有资源／Theme／颜色，不生产新素材。启动器更新整备操作说明并重建两态二进制。

待统筹：Debug新增战场直接编辑体验，敌方共用显示朝向调整；原流程、模拟规则、存档及平台范围不变。仅Windows桌面验收，不代表自由网格外布置、永久资源编辑、预设导入导出、真人平衡或其他平台通过。

启动器回归：`tools/game_launcher/test-launchers.ps1 -EnginePath <Godot GUI.exe>`为28／0，原生Debug21／0、Release9／0；原战斗入口无头36／0、GUI41／0，完整校园Debug174／0、Release6／0，检查／修复及并发与缺引擎提示通过，两玩家档字节不变。功能文档链接103份／41功能ID／610链接错误0；PowerShell解析与差异空白检查通过。
