# Windows 游戏启动器

日常双击项目根目录的 `CampusDebugLauncher.exe` 或 `CampusReleaseLauncher.exe`。它们是独立 Windows 窗口，不加入美术／地图工具集，不显示命令行菜单。原有根目录启动脚本已收进 `tools/`，仅供启动器后端、自动化和已有高级夹具使用。

## 入口与存档

| 启动器 | 操作 | 实际入口 |
| --- | --- | --- |
| Debug · 启动 | 战斗试玩 | 原序章四人自动部署后停在整备；拖动换位／点击角色编辑，F8 改背景，手动开战；每次新建 `.godot/debug-battle-preview.json` |
| Debug · 启动 | 校园调试 | 原校园流程，F8 调试；`user://campus_debug_progress.json` |
| Debug · 启动 | 正常游戏 | 与 Release 同样的正式进度和资源 |
| Release | 开始游戏 | 原校园流程；`user://campus_progress.json`，调试能力关闭 |

两种启动器默认正式五人资源，画面可选择三种已有分辨率及全屏。设置按模式保存在当前工作区 `.godot/game-launcher/`，首次可沿用另一模式的引擎配置。Debug 可以输入或选择引擎；Release 的“引擎设置”选择本机 Godot。它们运行本地源码工程，需要 Godot 和 PowerShell 7；Release 不是自带引擎的发行包，正式导出仍走[发布流程](../release/README.md)。

## Debug 检查页

- **一键检查**：自动准备导入并运行真实主入口预检，按需修复缓存。
- **修复工程**：强制重新导入后预检，保留玩家存档。

细分的功能／内容校验和 hooks 设置仅保留为内部自动化入口。切到“检查”页时，Enter 默认执行“一键检查”。

启动前均执行[工程预检](project-health.md)。窗口通过后台进程事件显示准备、运行、成功和失败；同一工作区整个准备／游戏期间持有锁，另一个启动器不能重复启动。检查期间关闭窗口会提示等待，游戏运行时可以关闭启动器，游戏继续运行。检查和游戏退出都核对实际日志；退出码 0 仍可能失败。点击“查看日志”打开最新日志，缺少引擎等早期失败打开启动器记录。

## 实现与维护

`tools/game_launcher/GameLauncher.cs` 使用 Windows Forms，以不同编译定义生成两个 GUI 可执行文件；Release 没有 Debug 按钮，后端也拒绝 Release 调试操作。颜色读取 `data/visual/colors.json`，使用系统中文字体、容器布局和原生键盘焦点。

`launch-action.ps1` 是唯一日常启动后端，使用 PowerShell 7，不通过 shell 拼接游戏参数；引擎选项位于 `--` 之前。后台自动检查不弹命令窗口，不重建战斗或存档系统。根目录两个小型 `.exe` 与源码和 `build-info.json` 一起版本管理，检出即可双击；C# 编译器仅维护时使用。修改窗口源码、manifest 或构建脚本后必须重新构建并验证，以免交付旧二进制。

内部自动化入口（维护／CI 使用）：

```powershell
pwsh.exe -NoProfile -File tools/game_launcher/build-launchers.ps1
pwsh.exe -NoProfile -File tools/game_launcher/test-launchers.ps1 -EnginePath '<Godot console.exe>'
```

原校园、Debug、战斗的高级 Smoke／Capture／固定难度夹具保存在 `tools/game_launcher/legacy/`；内容命令在 `tools/content/`；工程检查和 hooks 在 `tools/development/`；美术预览和工具集构建脚本在 `tools/art/`。这些不是日常用户入口。美术／地图原窗口仍是 `tools/art/asset_manager/control/ArtManagerControl.exe`，本次只修正内部脚本引用。

验证结果和已知边界统一见 [DEV-01](dev-01.md)。仅覆盖 Windows 桌面，不宣布发行包、Web／手机或真人体验验收。

战斗修改器使用见[调试说明](battle-tuning.md)，继续使用原战斗流程和临时预览档。
