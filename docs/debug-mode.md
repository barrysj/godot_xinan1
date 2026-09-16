# Debug 模式

## 启动与入口

在项目目录使用 PowerShell 7：

```powershell
pwsh.exe -File .\run-debug.ps1
```

可通过 `-EnginePath '完整 Godot 路径'` 指定引擎。脚本直接进入校园主流程；**右上角“调试”**打开面板，F8 也可开关，Esc／P 关闭面板。入口随画面角落锚定，不覆盖战斗菜单。打开时暂停战斗，返回时保留此前暂停状态；执行调试操作后回到游戏。退出确认和队伍／地点／图鉴窗口打开时，先关闭原窗口再进入调试。

普通 `run-campus-demo.ps1`／F5 不启用这些能力。显式启动参数是 `-- --campus-debug`，不根据编辑器或引擎的 debug build 自动开启。

调试界面使用居中弹窗：当前场景保留在半透明遮罩下，弹窗随窗口尺寸居中，内容溢出时可滚动。点击弹窗外的遮罩也可关闭，点击不会穿透到下方游戏按钮。

## 存档隔离

- 调试使用 `user://campus_debug_progress.json`，首次进入从序章开始，后续启动可继续该调试进度。
- 正式进度仍使用 `user://campus_progress.json`。不自动复制、迁移或合并两个文件。
- 从主菜单再次进入游戏仍遵循本次进程的启动参数；退出整个进程并正常启动即可回到正式档。
- 不同工作树仍可能共享同一调试档；不要并行运行多个实例写同一文件。
- 基地的**重开存档**在两种模式都可用，仅重开当前模式的档案；确认、备份、失败回滚和恢复方式见[校园演示](campus-demo.md#存档位置与版本隔离)。

## 操作语义

| 按钮 | 可用位置 | 结果 |
| --- | --- | --- |
| 跳过战斗 | 主线未击破地点、战前、战斗中、待处理战报；旧活动局战前／战中／战报 | 当前战斗按胜利处理，进入正常奖励；终局仍需手动提交系统操作。区域仍按正常离开与结算流程完成。可用于空阵容快速跳过教学战斗。 |
| 重开战斗 | 尚未领取结果的战斗／战报 | 保留阵型、装备、角色与局内成长；清空本场伤害、治疗、计时，恢复单位状态，返回部署。不会重新发放已领取奖励。 |
| 重抽事件 | 主线地点、旧活动局未选择事件、待选奖励 | 主线更换本地点尚未查看的随机系统记录；旧局更换事件快照；奖励页保证包含其他候选。有其他候选时才启用。重抽立即保存，续玩保留本次结果。 |

已查看记录、已选择事件和已领取奖励不会被重置。主线固定地图、人物加入、真实照片资源与终端进度不随重抽改变。主线每地点目前只有两条随机系统记录，候选耗尽时显示原因；这不是新增事件内容生成器。

保存失败显示提示，重抽／跳过不提交到存档，可返回游戏重试。调试命令仍复用正式胜利与保存接口，不另建一套资源结算规则。

## 实现入口

- `game/debug/campus_debug.gd`：命令前置条件、重抽快照、执行与失败回滚。
- `scenes/expedition/debug_panel.gd`：角落入口、原生按钮、暂停和快捷键。
- `scenes/expedition/campaign_hub.gd`：读取存档前选择路径、接入主线、正式重开入口。
- `run-debug.ps1`：等待 Godot 进程退出并返回引擎退出码。

## 验证

```powershell
pwsh.exe -File .\run-debug.ps1 -Check
pwsh.exe -File .\run-debug.ps1 -Capture
```

`-Check` 无窗口执行；`-Capture` 图形运行并截图，二者互斥。两者使用 `.godot/debug-check-profile.json`，不使用玩家调试档或正式档。图形检查还验证右上角按钮的真实鼠标输入、菜单避让、1920×1080／2560×1440／1920×1200 实际像素尺寸。日志 `.godot/debug-mode.log`，截图 `.godot/debug-corner-*.png`、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`。

正式关闭模式检查：Godot `--headless --path . res://scenes/expedition/expedition.tscn -- --debug-check`，故意不传 `--campus-debug`，核验无调试面板且命令拒绝执行。正式重开检查同场景 `-- --profile-reset-check`。当前结果与边界见 [DEV-01](implementation/dev-01.md)、[SAVE-02](implementation/save-02.md)。
