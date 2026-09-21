# M1 主菜单背景正式资产 · asset_002（4K）

## 提升范围

2026-09-21，负责人在已批准六张背景的基础上要求“提升背景分辨率到3840×2160”。本包包含三个地点的正常主题与三个地点的异常主题；4K 候选保存在 `design/concepts/m1-main-menu/m1_main_menu_visual/012/`，旧概念与 Git 历史保留用于追溯。

| 状态 | 地点 | 正式文件 | 来源概念 | SHA-256 |
| --- | --- | --- | --- | --- |
| normal | 图书馆 | `normal/library.png` | `concept_012.normal_library` | `1f8fa82635487665d47024faeea97ebded38e2d8c6f2f84e3e4593458540faa7` |
| normal | 品学楼 | `normal/pinxue-building.png` | `concept_012.normal_pinxue_building` | `8645710ac62035d070ffe92b0d38179d37680c4928093168e8b7353cce19259b` |
| normal | 银杏主楼 | `normal/ginkgo-main-building.png` | `concept_012.normal_ginkgo_main_building` | `2bb190f22ca036575027bce0fc8c13a9429d7f92227f92d8021799b85cdcfd47` |
| anomaly | 图书馆 | `anomaly/library-two-digital-swans.png` | `concept_012.anomaly_library` | `5e229c2750632f5e3995205323c372e79c05aa36a2614f3c51b833f698d20822` |
| anomaly | 品学楼 | `anomaly/pinxue-building.png` | `concept_012.anomaly_pinxue_building` | `11cf3f5280154e2f901a1218d29f8ab0f679bc2b79f9d2ef8699282a941da9bb` |
| anomaly | 银杏主楼 | `anomaly/ginkgo-main-building.png` | `concept_012.anomaly_ginkgo_main_building` | `a54963550efcfccee84ce270be715a6ae4c9351185ff754577cb039b708791fd` |

## 技术与使用边界

- 六张均为 3840×2160、`Format24bppRgb`、非透明 PNG；不包含菜单文字、按钮、标题字标或水印。
- 生成方式：以 `asset_001` 六张背景逐张进入 AI 图像编辑，提示保持原构图、建筑身份、道路／入口中轴、菜单安全区与异常叙事，只增强远景建筑、树叶、水面和纹理细节；输出随后以高质量双三次插值做精确 16:9 中心裁切和 3840×2160 规范化。此版本是“细节增强后的 4K 像素资产”，不宣称新增真实摄影细节。
- 图书馆异常图提示额外要求：严格保留两只远景数字黑天鹅，左鸟低颈向左、右鸟抬颈向右并轻微展翼，不新增第三只；银杏主楼提示额外要求正中大门列继续与道路双黄线重合。
- 正常状态由 `CampusProgress.campaign.restored` 解锁；未通关时使用异常状态，完整通关后使用正常状态。
- 图书馆异常图中的两只数字黑天鹅仍是一体化背景内容，不作为独立透明角色资产登记。
- 用户提供的校园照片仅作为地点身份与构图参考；本记录不推断其公开发布或商业再分发许可。
- 主菜单使用线性纹理过滤；实际裁切、安全区和 1920×1080、1920×1200、2560×1440、3840×2160 效果由 Godot 图形运行截图复验。
