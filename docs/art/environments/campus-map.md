# 美术任务：M1 校园地图共用底图

2026-10-10 精简：保留整体目标、现用版本与最终状态；删除逐次生成、小修改意见和阶段流水账。资产与接入状态分别维护，技术检查不代替负责人决定。

## 目标与范围

校园图采用可编辑3D母版离线输出2D三态图；空间位置依据负责人提供的DXF、GLB及地标参考，游玩路径由原战役资源定义，显示落点不构成测绘保证。

## 当前对象与有效版本

| 对象 | 现用／选定版本 | 状态来源 |
| --- | --- | --- |
| M1 校园地图共用底图 | `concept_007`（approved）、`concept_015`（approved）、`legacy_day_028`（review）、`legacy_anomaly_030`（approved）、`integration_030`（review）、`route_preview_035`（approved）、`asset_001`（review）、`expanded_preview_001`（review）、`web_expanded_preview_001`（review） | [Manifest](../../../assets/art/manifests/m1_campus_map.yaml) |

版本明细、原始来源和实际接入路径由 Manifest 与保留源包维护，不在此复制逐文件清单。当前选定版本可能仍为 review；目录移动与文档清理不改变批准状态。验证入口见[美术验证](../verification.md)。

## 关键方向与现用边界

运行时使用 2D 交互图，制作端保存可编辑 3D 母版。当前 asset_001 含日／夜／异常三态，桌面5400×4500、Web1800×1500，逻辑坐标仍为1800×1500。当前仍为 review＋既有试接入授权；未把参考校界当测绘或导航保证。连续地面概念已撤回，继续原版，不能将已撤回概念恢复为当前生产方案。既有编号上限 concept_054、tmp_004 不复用，下一套资产用 asset_002。
