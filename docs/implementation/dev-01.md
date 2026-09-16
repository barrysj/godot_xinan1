# DEV-01 · Debug 模式与独立启动入口

- 功能 ID：DEV-01
- 所属系统：开发工具
- 当前状态：已验证
- 验证日期：2026-09-17
- 基线：从 main `10dfbcd` 创建 `codex/debug-tools`，正式重开基线 `77afbd3`，其后为本功能提交。

## 玩家／开发者能力与接入范围

显式启动 Debug，右上角按钮／F8 打开面板；跳过战斗、保留构筑重开战斗、重抽未消费事件／记录或待选奖励。主线与旧活动局使用各自既有结算入口。独立调试存档，普通启动关闭能力；正式重开由 SAVE-02 维护。

## 实现与规则入口

- 使用与行为事实源：[Debug 模式](../debug-mode.md)。
- `run-debug.ps1`、`game/debug/campus_debug.gd`、`scenes/expedition/debug_panel.gd`、`campaign_hub.gd`。
- 检查入口：`scenes/expedition/debug_check.gd`；共享命令见[验证 E23](verification.md#debug-与重开存档-e23)。

## 验证与证据

- 2026-09-17，基线 `7160568` 后改为居中弹窗与半透明遮罩，背景保留当前场景；沿用暂停、快捷键与角落入口。`run-debug.ps1 -Capture`：71 checks / 0 failures，新增弹窗四周可见背景、实际点击遮罩关闭且不触发下层菜单检查；实际截图 `.godot/debug-battle-panel.png`、`debug-reward-panel.png`。待统筹：仅调整调试界面呈现，无存档或玩法规则变化。

- `pwsh.exe -File .\run-debug.ps1 -Check`：59 checks / 0 failures。
- `pwsh.exe -File .\run-debug.ps1 -Capture`：69 checks / 0 failures，含真实角落按钮鼠标点击、三尺寸像素与菜单不相交断言。截图 `.godot/debug-corner-1920x1080.png`、其余两尺寸、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`。
- 关闭模式 `-- --debug-check`：5 checks / 0 failures；主线回归 `-- --campaign-flow-check`：124 checks / 0 failures。
- 覆盖真实战斗推进后暂停／重开，HP／统计／构筑保留，主线三地区及终局正常结算，重复跳过禁止，重抽确实改变候选与磁盘续玩一致，保存失败回滚，旧随机事件／奖励快照可恢复，正式存档字节不变。故障注入使用不可写入的目录，未模拟断电／磁盘满。

## 已知边界与待统筹

- Windows Godot 4.7.2 Compatibility 图形与 headless 已验证；本功能尚未做 Web／Android 导出与交互验收，启动脚本为 Windows PowerShell 7。
- 不增加事件内容、不重抽固定地图；已消费结果不回退；不提供正式档导入调试档按钮。独立战斗实验室不接入此主流程 Debug 面板。
- 待统筹：新增开发启动方式和独立档案路径；正式基地重开能力见 SAVE-02。未改高层总览／Roadmap。
