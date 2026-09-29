# RELEASE-01 · Web 构建与 Pages 自动发布配置

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：RELEASE-01
- 所属系统：发布
- 当前状态：已验证
- 最近验证：2026-09-29；以 `main` 的 `06ad4e6` 为起点，在 `codex/web-export-size` 实施 Web 缩包与背景衍生图；本轮背景优化基线为 `75a1011`。

## 玩家能力与接入范围

Web 构建与 Pages 自动发布配置。玩家价值：可分发入口。

## 实现与规则入口

- 实现入口：[build-web.ps1](../../build-web.ps1)、[export_presets.cfg](../../export_presets.cfg)、[push-export.yml](../../.github/workflows/push-export.yml)、[Web 背景生成器](../../tools/art/build_web_backgrounds.gd)、[主菜单映射](../../scenes/menu/menu.gd)、[校园地点映射](../../scenes/expedition/campus_location_skin.gd)、[基地](../../scenes/expedition/campaign_panel.gd)、[图书馆](../../scenes/expedition/exploration_skin.gd)、[记忆终端纹理加载](../../scenes/expedition/memory_terminal_view.gd)
- 规则事实源：[发布](../web-publishing.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E18；Web 缩包与实际浏览器检查见 [E33](verification.md#web-缩包与资源完整性验证-e33)，背景衍生图检查见 [E34](verification.md#web-背景衍生图验证-e34)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

本地 HTTP 入口通过；线上 Actions／Pages 未触发。Web 自动全战役检查为 124/0，但日志出现两条延迟焦点调用错误；原生终端专项 12 项有 3 项节点数量断言失败，均未作为本轮通过项。

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。

## Web 导出资源范围（待统筹）

Web 预设保留 `all_resources`，排除 `design/*` 及校园地点、主菜单原始 4K PNG，改由 30 张 1920×1080 WebP 衍生图供 Web 使用；非 Web 预设继续使用原始 4K，并排除这些仅供 Web 使用的衍生图。正式 `assets/art/holo_cards` 仍完整导出，保持图鉴闪卡按目录自动发现。基地、图书馆和记忆终端使用 Godot 导入纹理，避免导出包中原 PNG 不存在时出现空画面。本地脚本及 Pages CI 在上传前检查整站体积，达到 900 MB 即失败。背景优化后本地整站约 182.4 MiB；此次只本地验证，待统筹汇总新体积、线上发布边界和自动检查的已知错误。1080p 背景在 1440p 显示器上会放大，视觉效果待负责人评审。
