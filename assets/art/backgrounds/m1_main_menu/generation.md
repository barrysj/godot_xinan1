# M1 主菜单背景正式资产 · asset_001

## 提升范围

2026-09-21，负责人明确回复“好，将这6张都提升为资产”。本包包含三个地点的正常主题与三个地点的异常主题；原概念目录保留为生成来源、质量闸门和版本追溯记录。

| 状态 | 地点 | 正式文件 | 来源概念 | SHA-256 |
| --- | --- | --- | --- | --- |
| normal | 图书馆 | `normal/library.png` | `concept_002.library` | `9c5084963c20c93fea30edc9fbda1b3c4a591b83ec4b7a9cb3bb39254bb01842` |
| normal | 品学楼 | `normal/pinxue-building.png` | `concept_002.pinxue_building` | `8d71c520dd505ab3722504db03213444fc00be7f89ba6f894012bee220e0e3a4` |
| normal | 银杏主楼 | `normal/ginkgo-main-building.png` | `concept_005.ginkgo_main_building` | `01587c6106e9b6ab7b5667fb9cc891e01481e460095037ee1377558e8212378c` |
| anomaly | 图书馆 | `anomaly/library-two-digital-swans.png` | `concept_011.library_anomaly_two_digital_swans_clear_directions` | `26c91dd40488fae87396b59f69bb9cbb9f094d714091c0c238ed636e6a3cf96b` |
| anomaly | 品学楼 | `anomaly/pinxue-building.png` | `concept_006.pinxue_building_anomaly` | `95fd5e2380002f022b728cbfbb6d2c40797beb625b5ae0a9ac4f653428bb9b86` |
| anomaly | 银杏主楼 | `anomaly/ginkgo-main-building.png` | `concept_006.ginkgo_main_building_anomaly` | `49912bda0715fbeb212c8079c1f26e72d3ccc0cc76959b117dbad6a1607f5292` |

## 技术与使用边界

- 六张均为 1672×941、`Format24bppRgb`、非透明 PNG；不包含菜单文字、按钮、标题字标或水印。
- 正常状态由 `CampusProgress.campaign.restored` 解锁；未通关时使用异常状态，完整通关后使用正常状态。
- 图书馆异常图中的两只数字黑天鹅仍是一体化背景内容，不作为独立透明角色资产登记。
- 用户提供的校园照片仅作为地点身份与构图参考；本记录不推断其公开发布或商业再分发许可。
- 主菜单的实际裁切、安全区和多分辨率效果仍需 Godot 图形运行截图进行接入评审。
