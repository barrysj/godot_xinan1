# RELEASE-01 · Web 构建与 Pages 自动发布配置

- 功能 ID：RELEASE-01
- 所属系统：发布
- 当前状态：已验证
- 最近验证：2026-09-30；`art/campus-map-web-merge`在本地`main e611d5b`的squash合并树完成三态全图平台映射、正式Web导出和桌面预览复测，结果见E59；浏览器全图与线上Pages仍待验。

## 玩家能力与接入范围

Web 构建与 Pages 自动发布配置。玩家价值：可分发入口。

## 实现与规则入口

- 实现入口：[build-web.ps1](../../build-web.ps1)、[export_presets.cfg](../../export_presets.cfg)、[push-export.yml](../../.github/workflows/push-export.yml)、[平台素材适配层](../../game/visual/platform_asset_paths.gd)、[映射检查](../../tools/release/platform_asset_check.tscn)、[Web 背景生成器](../../tools/art/build_web_backgrounds.gd)、[主菜单映射](../../scenes/menu/menu.gd)、[校园地点映射](../../scenes/expedition/campus_location_skin.gd)、[三态全图映射](../../scenes/expedition/expanded_campus_map.gd)、[基地](../../scenes/expedition/campaign_panel.gd)、[图书馆](../../scenes/expedition/exploration_skin.gd)、[记忆终端纹理加载](../../scenes/expedition/memory_terminal_view.gd)
- 规则事实源：[发布](web-publishing.md)
- 跨系统边界参见[集成约束](../development/integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E18；Web 缩包与实际浏览器检查见 [E56](../development/verification.md)，背景衍生图检查见 [E57](../development/verification.md)；平台路径适配见 [E58](../development/verification.md)。
- E18、E56、E57 为继承记录；E58 记录合并树复测。整站 255.8 MiB；平台映射 30/0、浏览器背景 30/0、战役 148/0、资源台单测 33 项通过，实际浏览器和桌面主菜单截图已保存。
- E59记录全图Web三态接入：整站199.3 MiB，平台映射33/0、桌面地图202/0，PCK含3张Web全图且排除3张高清全图；资源台单测33项通过。尚无Web浏览器三态实际画面证据。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

本地 HTTP 入口通过；线上 Actions／Pages 未触发。Web 自动全战役检查为 124/0，但日志出现两条延迟焦点调用错误；原生终端专项 12 项有 3 项节点数量断言失败，均未作为本轮通过项。

2026-09-30 已汇总（2026-10-10）：校园全图`asset_001`同时保留5400×4500原图和1800×1500 Web图。合并分支已按`main`平台路径适配层增加三态全图映射及双向导出排除规则；正式Web导出包体和三态画质仍须以本分支验证记录为准，不能把资源留存或路径检查直接等同于线上发布验收。

## 统筹状态

已汇总（2026-10-10）：合并后的 Web 包体积和平台素材适配影响发布能力与平台范围；统筹核验后更新高层总览。线上 Pages 发布及 Web 素材视觉效果仍待验收。

## Web 导出资源范围（已汇总（2026-10-10））

Web 预设保留 `all_resources`，排除 `design/*` 及校园地点、主菜单原始 4K PNG，改由 30 张 1920×1080 WebP 衍生图供 Web 使用；非 Web 预设继续使用原始 4K，并排除这些仅供 Web 使用的衍生图。正式 `assets/art/holo_cards` 仍完整导出，保持图鉴闪卡按目录自动发现。基地、图书馆和记忆终端使用 Godot 导入纹理，避免导出包中原 PNG 不存在时出现空画面。本地脚本及 Pages CI 在上传前检查整站体积，达到 900 MB 即失败。功能分支背景优化后整站约 182.4 MiB；合入现有主线校园地图后为 255.8 MiB。线上发布边界和自动检查的已知错误已汇总（2026-10-10）汇总。1080p 背景在 1440p 显示器上会放大，视觉效果待负责人评审。

## 平台规格适配（已汇总（2026-10-10））

2026-09-30：运行时平台路径统一由 [platform_asset_paths.gd](../../game/visual/platform_asset_paths.gd) 选择，主菜单、校园地点和全图只传原始路径；当前登记 Web 两组 1080p WebP 及全图一组 1800×1500 PNG，其余平台保持原图。Web 背景生成器只生产前两组；全图使用已留存的三态低清图。各平台导出预设负责排除不需要的版本。此层只解决按平台选文件，不处理屏幕尺寸动态分档。Android 与 iOS 新规格须另备资产、配置导出预设并做设备验收。

## 单字体与 Web 纹理瘦身（2026-10-16，待统筹）

基线 `31b672f`；保持正式主线入口与平台映射。事件页／过场统一思源，排除 Web 内 Noto 与 Open Sans；33 张 Web 专用背景／地图导入使用高质量有损压缩。实现与后续资源接入契约见 [发布规则](web-publishing.md#单字体与纹理压缩2026-10-16)。

本地优化前现有 PCK 为 247,684,692 字节；优化后 167,165,192 字节（约 167.2 MB），减少约 80.5 MB（32.5%）；整站约 197.4 MiB。统计包含全部运行资源，不是压缩下载体积。检查命令：`pwsh.exe -File build-web.ps1`、`py -3 tools/release/web_package_check.py builds/web/index.pck`、Godot `--headless --path . res://tools/release/platform_asset_check.tscn`。纹理 33/0；PCK 审计仅一个思源字体。

正式 release 包在本地 HTTP、1280×720 桌面浏览器实际点击完成：菜单→热点读取→编队→暂停／恢复／调速→代码补给→积码／破解→胜利领奖→基地→首个免费派遣解锁→校园地图→图书馆路线出发。中文、角色、背景、地图均显示，控制台无 error/warn。截图 `.godot/web-tutorial-dispatch.jpg`、`.godot/web-tutorial-route.jpg`。未触发线上 Pages，也不以桌面浏览器替代手机真机验收。该变更影响发布包和共用字体，待统筹汇总。

最终包刷新后正确恢复图书馆路线第 1/4 站，已完成教学不再重复出现。最终构建基线 `49b0f47` 加本节单字体／纹理改动。
