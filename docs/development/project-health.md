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

## 启动入口接入

run-campus-demo.ps1、run-battle-demo.ps1和run-debug.ps1在启动可见游戏前调用同一预检；运行结束也检查实际日志，不以退出0代替成功。已有Debug／Release／战斗参数和存档规则不变。Debug检查还有时间上限与完成标记要求，避免失败后静默挂起或被当成通过。

## main更新后的自动触发

工具分支合入后，在仓库运行一次：

```powershell
pwsh.exe -NoProfile -File .\install-project-hooks.ps1
```

本地Git配置指向版本化.githooks。post-merge、post-checkout、post-commit通过小型分发入口调用PowerShell7，仅在当前分支是main时检查实际checkout。覆盖快进／普通合并、切回main、squash暂存工作树及后续提交。EnginePath保存在本地配置；同库worktrees共享配置，但检查各自的源码／缓存。安装时保留已有不同hooksPath和默认hooks目录内的自定义文件，遇到它们会拒绝覆盖，应手动整合。

后置hook检查失败会明确报错，但Git操作可能已完成，不能自动回滚或阻止提交。最终验收／CI应显式调用check-project.ps1并要求返回0；启动入口也继续拦截不健康工程。冲突解决后再检查。已打开的Godot编辑器仍保留旧内存状态时需要重新打开项目，本工具验证新进程。

卸载：`pwsh.exe -NoProfile -File .\install-project-hooks.ps1 -Remove`，保留版本化工具和启动预检。本地Git设置不随克隆传播。本轮在隔离仓库验证安装／卸载，尚未修改真实仓库hooksPath。

## 验证

2026-10-13，基线main 82a04c9＋本功能：隔离真实Godot工程回归14／0，实际项目启动预检9／0；Release启动集成先通过9项预检，再通过原DEBUG_CHECK 6／0；Debug入口174／0，原生Git hook回归14／0。回归命令：

```powershell
pwsh.exe -NoProfile -File tools/development/tests/project-health.test.ps1 -EnginePath 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
```

覆盖未导入SVG／缺少类型缓存、自动导入、缓存复用、导入元数据丢失修复、未提交与同状态多次改动、真实坏代码、退出0报错、缺失成功标记和并发锁。隔离夹具与证据在.godot/art-workflow/project-health-tests；夹具Git元数据在结束时移除。

Hook回归入口为tools/development/tests/project-hooks.test.ps1，使用同样的-EnginePath参数。覆盖有空格路径、现有设置保护、main／非main筛选、原生快进／squash／提交／切换触发、失败报告与Git已完成行为边界、卸载。证据在.godot/art-workflow/project-hook-tests。

官方契约：[命令行导入](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)、[版本控制与缓存](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)、[Git hooks](https://git-scm.com/docs/githooks)。
