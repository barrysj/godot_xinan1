# 本地工程导入与启动预检

## 根因与适用范围

Git更新源码，不更新每个checkout自己的Godot缓存。新全局脚本类型、类型依赖、导入资源以及引擎版本变化，都可能使源码与`.godot`缓存不同步。直接运行游戏不会代替编辑器导入；编辑器内存中的旧类型状态也可能持续到重新打开项目。

本项目已在main主工程复现：新增CampusPlaceScene未注册，使scenes字段连锁解析失败；SVG未导入，使preload报告无资源加载器。相同源码经目标checkout重新导入后启动正常。这类外层报错也可能由真实语法错误、错误路径或资源损坏引起，不能一律当作缓存问题。Godot还可能报SCRIPT ERROR却退出0，必须检查日志和明确完成标记。

## 自动检查命令

在目标checkout使用PowerShell7：

```powershell
pwsh.exe -NoProfile -File .\check-project.ps1
pwsh.exe -NoProfile -File .\check-project.ps1 -NoRepair
pwsh.exe -NoProfile -File .\check-project.ps1 -Repair
```

默认自动准备并检测；`-NoRepair`只检测，不刷新导入／就绪记录；`-Repair`强制重新导入并检测。`-EnginePath`选择实际引擎，`-ProjectPath`选择已有项目，`-TimeoutSeconds`调整每阶段时限。目标项目须包含本工具与原主入口。

共享实现为`tools/development/project-health.ps1`。就绪记录绑定绝对checkout、引擎路径／文件版本状态、Git HEAD和已修改／新文件内容；同一Git状态下再次修改文件也能被发现。不在Git仓库内时每次准备。源码变化或缓存缺失时调用Godot的headless编辑器`--import`，等待完成；未变化时仍执行真实主入口预检，避免就绪记录掩盖缓存丢失。

预检`project_startup_check.tscn`加载原Campaign、三区域Resource、菜单、SVG与地图节点，用`.godot/project-health`中的独立临时profile。只有退出0、没有致命日志、且PROJECT_HEALTH_CHECK明确完成才通过。缓存复用时预检失败，会自动重导入、再预检一次；新导入后仍失败或真正代码错误立即阻止启动。日志使用唯一名称，不能误读旧成功日志；同一checkout并发准备会拒绝重入，超时只终止本工具创建的引擎进程。

就绪记录、日志和缓存不进Git；不自动清空整个.godot。强制导入仍不能修好的错误需按保留日志诊断源码／资源，不反复重试。此预检覆盖启动依赖和已加载资源，不代替完整战役、所有延迟加载内容或发布平台验收。

## 验证

2026-10-13，基线main 82a04c9＋本功能：隔离真实Godot工程回归14／0，实际项目启动预检9／0。回归命令：

```powershell
pwsh.exe -NoProfile -File tools/development/tests/project-health.test.ps1 -EnginePath 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
```

覆盖未导入SVG／缺少类型缓存、自动导入、缓存复用、导入元数据丢失修复、未提交与同状态多次改动、真实坏代码、退出0报错、缺失成功标记和并发锁。隔离夹具与证据在.godot/art-workflow/project-health-tests；夹具Git元数据在结束时移除。

官方契约：[命令行导入](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)、[版本控制与缓存](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)。
