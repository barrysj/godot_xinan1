# RELEASE-01 · Web 构建与 Pages 自动发布配置

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：RELEASE-01
- 所属系统：发布
- 当前状态：已验证
- 最近验证：2026-09-30；在本地 `main` 的 `5939c80` 与 `codex/web-export-size` 的 `5526aab` 合并树上完成正式 Web 导出、浏览器、平台映射、桌面主菜单和战役回归，结果见 E58。

## 玩家能力与接入范围

Web 构建与 Pages 自动发布配置。玩家价值：可分发入口。

## 实现与规则入口

- 实现入口：[build-web.ps1](../../build-web.ps1)、[export_presets.cfg](../../export_presets.cfg)、[push-export.yml](../../.github/workflows/push-export.yml)、[平台素材适配层](../../game/visual/platform_asset_paths.gd)、[映射检查](../../tools/platform_asset_check.tscn)、[Web 背景生成器](../../tools/art/build_web_backgrounds.gd)、[主菜单映射](../../scenes/menu/menu.gd)、[校园地点映射](../../scenes/expedition/campus_location_skin.gd)、[基地](../../scenes/expedition/campaign_panel.gd)、[图书馆](../../scenes/expedition/exploration_skin.gd)、[记忆终端纹理加载](../../scenes/expedition/memory_terminal_view.gd)
- 规则事实源：[发布](../web-publishing.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E18；Web 缩包与实际浏览器检查见 [E56](verification.md#web-缩包与资源完整性验证-e56)，背景衍生图检查见 [E57](verification.md#web-背景衍生图验证-e57)；平台路径适配见 [E58](verification.md#平台素材路径适配验证-e58)。
- E18、E56、E57 为继承记录；E58 记录合并树复测。整站 255.8 MiB；平台映射 30/0、浏览器背景 30/0、战役 148/0、资源台单测 33 项通过，实际浏览器和桌面主菜单截图已保存。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

本地 HTTP 入口通过；线上 Actions／Pages 未触发。Web 自动全战役检查为 124/0，但日志出现两条延迟焦点调用错误；原生终端专项 12 项有 3 项节点数量断言失败，均未作为本轮通过项。

## 交接给统筹

待统筹：合并后的 Web 包体积和平台素材适配影响发布能力与平台范围；统筹核验后更新高层总览。线上 Pages 发布及 Web 素材视觉效果仍待验收。

## Web 导出资源范围（待统筹）

Web 预设保留 `all_resources`，排除 `design/*` 及校园地点、主菜单原始 4K PNG，改由 30 张 1920×1080 WebP 衍生图供 Web 使用；非 Web 预设继续使用原始 4K，并排除这些仅供 Web 使用的衍生图。正式 `assets/art/holo_cards` 仍完整导出，保持图鉴闪卡按目录自动发现。基地、图书馆和记忆终端使用 Godot 导入纹理，避免导出包中原 PNG 不存在时出现空画面。本地脚本及 Pages CI 在上传前检查整站体积，达到 900 MB 即失败。功能分支背景优化后整站约 182.4 MiB；合入现有主线校园地图后为 255.8 MiB。线上发布边界和自动检查的已知错误待统筹汇总。1080p 背景在 1440p 显示器上会放大，视觉效果待负责人评审。

## 平台规格适配（待统筹）

2026-09-30：运行时平台路径统一由 [platform_asset_paths.gd](../../game/visual/platform_asset_paths.gd) 选择，主菜单与校园地点只传原始路径；当前登记 Web 两组 1080p WebP，其余平台保持 4K PNG。Web 背景生成器也调用同一映射；各平台导出预设仍负责排除不需要的版本。此层只解决按平台选文件，不处理屏幕尺寸动态分档。同组新图现由生成器自动发现，并可用 `--check` 只读核验；全新图片组仍需扩展生成器、映射检查和导出筛选。Android 与 iOS 新规格须另备资产、配置导出预设并做设备验收。
