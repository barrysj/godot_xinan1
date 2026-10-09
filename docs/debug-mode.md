# Debug 模式

## 启动与入口

在项目目录使用 PowerShell 7：

```powershell
pwsh.exe -File .\run-battle-demo.ps1
# 启动菜单选 Debug，或直接：
pwsh.exe -File .\run-battle-demo.ps1 -Mode Debug
# 原直接入口仍保留：
pwsh.exe -File .\run-debug.ps1
```

统一启动菜单只选择 Debug / Release，回车默认 Debug。Debug 直接进入新的序章战斗，四人自动部署并立即开战；复用原校园战斗与战报，无需先完成基地教学。默认本地当前三人动画，可加 `-Animations Formal` 使用正式资源；缺少候选的工作区使用该参数。Release 进入原校园基地，使用正常存档和正式角色资源，关闭校园调试能力。两种模式是本地运行选项，不替代发行包导出。

`run-debug.ps1` 仍用于调试完整校园进度，从基地进入原序章／探索流程；需要直接试战斗时使用 `run-battle-demo.ps1 -Mode Debug`。后者在 `--campus-debug` 外加 `--debug-battle`；仅传战斗参数而未启用 Debug，不会开启战斗预览。

可通过 `-EnginePath '完整 Godot 路径'` 指定引擎。脚本直接进入校园主流程；**右上角“调试”**打开面板，F8 也可开关，Esc／P 关闭面板。入口随画面角落锚定，不覆盖战斗菜单。打开时暂停战斗，返回时保留此前暂停状态；执行调试操作后回到游戏。退出确认和队伍／地点／图鉴窗口打开时，先关闭原窗口再进入调试。

普通 `run-campus-demo.ps1`／F5 不启用这些能力。显式启动参数是 `-- --campus-debug`，不根据编辑器或引擎的 debug build 自动开启。

调试界面使用居中弹窗：当前场景保留在半透明遮罩下，弹窗随窗口尺寸居中，内容溢出时可滚动。点击弹窗外的遮罩也可关闭，点击不会穿透到下方游戏按钮。

## 存档隔离

- 完整校园调试使用 `user://campus_debug_progress.json`，首次进入从序章开始，后续启动可继续该调试进度。
- 战斗启动预览使用工作区 `.godot/debug-battle-preview.json`，沿用现有 Progress 与 CampaignCheckpoint 编解码，每次启动新战斗，不读取旧预览进度。正式档与完整校园调试档均不改写，旧预览缓存损坏也不阻止启动。
- 正式进度仍使用 `user://campus_progress.json`。不自动复制、迁移或合并两个文件。
- 从主菜单再次进入游戏仍遵循本次进程的启动参数；退出整个进程并正常启动即可回到正式档。
- 不同工作树仍可能共享同一调试档；不要并行运行多个实例写同一文件。
- 基地的**重开存档**在两种模式都可用，仅重开当前模式的档案；确认、备份、失败回滚和恢复方式见[校园演示](campus-demo.md#存档位置与版本隔离)。

## 操作语义

| 按钮 | 可用位置 | 结果 |
| --- | --- | --- |
| 跳过战斗 | 主线未击破地点、战前、战斗中、待处理战报；旧活动局战前／战中／战报 | 当前战斗按胜利处理，进入正常奖励；终局仍需手动提交系统操作。区域仍按正常离开与结算流程完成。可用于空阵容快速跳过教学战斗。 |
| 重开战斗 | 尚未领取结果的战斗／战报 | 保留阵型、装备、角色与局内成长；清空本场伤害、治疗、计时，恢复单位状态，返回部署。不会重新发放已领取奖励。 |
| 应用重开 | 四人已部署、尚未领取结果的战斗／战报 | 应用面板选择的难度，保留当前敌阵、阵容、装备及局内成长，恢复满血、清空本场统计与计时，然后立即开战。 |
| 重抽事件 | 主线地点、旧活动局未选择事件、待选奖励 | 主线更换本地点尚未查看的随机系统记录；旧局更换事件快照；奖励页保证包含其他候选。有其他候选时才启用。重抽立即保存，续玩保留本次结果。 |

战斗中按 F8 或点击右上角“调试”，在“战斗难度”下拉框选择**简单 / 普通 / 困难**，再点击**应用重开**。仅选择下拉框不会改变正在进行的战斗，关闭面板也不会应用候选值；点击应用后菜单关闭并恢复战斗。四人未部署齐、已领取战斗结果或不在战斗／战报时，该操作禁用并显示原因。

普通使用当前遭遇的原始属性（含地点与终局阶段的强度）；简单降低敌方生命和攻击，困难增加敌方生命以延长承压。只复用 `game/combat/demo_battle_presets.gd` 中的属性倍率，不切换敌阵或地点。重开从原资源重新建立单位，连续应用不会叠加倍率，也不会修改角色／敌人 Resource。难度只保留在本次 Debug 进程内，后续调试战斗沿用该选择；退出进程再启动恢复普通，调试和正式存档都不新增难度字段。

已查看记录、已选择事件和已领取奖励不会被重置。主线固定地图、人物加入、真实照片资源与终端进度不随重抽改变。主线每地点目前只有两条随机系统记录，候选耗尽时显示原因；这不是新增事件内容生成器。

保存失败显示提示，重抽／跳过不提交到存档，可返回游戏重试。调试命令仍复用正式胜利与保存接口，不另建一套资源结算规则。

## 实现入口

- `game/debug/campus_debug.gd`：命令前置条件、难度应用、重抽快照、执行与失败回滚。
- `scenes/expedition/debug_panel.gd`：角落入口、难度下拉框、原生按钮、暂停和快捷键。
- `scenes/expedition/campaign_hub.gd`：读取存档前选择路径、接入主线、正式重开入口；战斗预览沿用序章遭遇、默认阵型和 `_start()`，仅启用 Debug 时给本场敌人应用临时难度倍率。
- `run-battle-demo.ps1`：Debug 直接启动战斗，Release 启动正常校园。
- `run-debug.ps1`：等待 Godot 进程退出并返回引擎退出码。

## 验证

实际战斗启动检查：`pwsh.exe -File .\run-battle-demo.ps1 -Mode Debug -Smoke`；将 `-Smoke` 换成 `-Capture` 检查三种尺寸与实际点击“应用重开”，截图 `.godot/debug-battle-launch-<尺寸>.png`、`debug-battle-launch-menu.png`。检查读取真实启动后的状态，不自行创建战斗来代替启动流程，完成标记为 `DEBUG_BATTLE_CHECK`。完整校园调试继续使用下列入口：

```powershell
pwsh.exe -File .\run-debug.ps1 -Check
pwsh.exe -File .\run-debug.ps1 -Capture
```

`-Check` 无窗口执行；`-Capture` 图形运行并截图，二者互斥。两者使用 `.godot/debug-check-profile.json`，不使用玩家调试档或正式档。图形检查还验证右上角按钮的真实鼠标输入、菜单避让、1920×1080／2560×1440／1920×1200 实际像素尺寸。日志 `.godot/debug-mode.log`，截图 `.godot/debug-corner-*.png`、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`。

难度检查覆盖主线与旧活动局的真实战斗推进、选择不立即应用、鼠标点击“应用重开”、满血与统计清空、当前敌阵及完整构筑保留、三档属性和重复应用、缺员拒绝、保存失败不应用、存档不保存难度。截图 `.godot/debug-difficulty-menu-<尺寸>.png` 与 `debug-difficulty-restarted.png` 由同一检查生成。回归遍历奖励时也走真实归属选择，避免把待选人物奖励误当成已领取。

正式关闭模式检查：Godot `--headless --path . res://scenes/expedition/expedition.tscn -- --debug-check`，故意不传 `--campus-debug`，核验无调试面板且命令拒绝执行。正式重开检查同场景 `-- --profile-reset-check`。当前结果与边界见 [DEV-01](implementation/dev-01.md)、[SAVE-02](implementation/save-02.md)。
