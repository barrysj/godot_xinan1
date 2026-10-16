# 工具入口

双击 **ToolLauncher.exe** 打开共享工具启动器，可启动资源台和校园地图编辑器。游戏试玩仍用仓库根目录的 CampusReleaseLauncher.exe／CampusDebugLauncher.exe。

| 目录 | 职责 |
| --- | --- |
| launcher | 工具启动器源码、构建与自检 |
| game_launcher | 游戏启动器与其后端 |
| development | 工程准备、修复和开发检查；tests 是回归入口 |
| art | 美术处理、缩略图生成和资源台 |
| campus-map-editor | 地图编辑器服务与页面 |
| content | 内容录入工具 |
| release | Web 资源、字体及发布包检查 |
| docs | 文档链接检查 |

修改工具启动器源码后运行 `pwsh.exe -File tools/launcher/run-tool-suite-control.ps1`，会按需重建。仅构建使用同目录 `build-control.ps1`，原生入口与源码一起提交。
