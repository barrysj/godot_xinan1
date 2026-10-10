# 美术任务：M1 敌人家族

2026-10-10 精简：保留整体目标、现用版本与最终状态；删除逐次生成、小修改意见和阶段流水账。资产与接入状态分别维护，技术检查不代替负责人决定。

## 目标与范围

敌人围绕校园设备、教材、运动与餐具的身份设计，采用同一战斗播放与角色契约。概念批准与当前主线遭遇、正式动画接入分别维护。

## 当前对象与有效版本

| 对象 | 现用／选定版本 | 状态来源 |
| --- | --- | --- |
| 信息安全数学 | `concept_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/textbook_security_math.yaml) |
| 图书管理员 | `concept_003`（approved）、`asset_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/cyber_librarian.yaml) |
| 广播中继 | `concept_003`（approved）、`integration_001`（review） | [Manifest](../../../assets/art/manifests/enemy/radio.yaml) |
| 弹跳篮球 | `concept_002`（approved） | [Manifest](../../../assets/art/manifests/enemy/basketball_bouncer.yaml) |
| 归还印章怪 | `concept_002`（approved）、`asset_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/return_stamp.yaml) |
| 教室投影仪 | `concept_003`（approved）、`asset_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/projector.yaml) |
| 机房终端 | `concept_003`（approved） | [Manifest](../../../assets/art/manifests/enemy/computer_terminal.yaml) |
| 监考钟灵 | `concept_002`（approved） | [Manifest](../../../assets/art/manifests/enemy/exam_clock_boss.yaml) |
| 线性代数 | `concept_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/textbook_linear_algebra.yaml) |
| 编译原理 | `concept_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/textbook_compilers.yaml) |
| 羽球突刺 | `concept_002`（approved） | [Manifest](../../../assets/art/manifests/enemy/shuttlecock_diver.yaml) |
| 计算机组成原理 | `concept_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/textbook_architecture.yaml) |
| 错题试卷 | `concept_002`（approved）、`integration_001`（review） | [Manifest](../../../assets/art/manifests/enemy/exam_paper.yaml) |
| 键帽拳灵 | `concept_002`（approved）、`asset_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/keycap_brawler.yaml) |
| 餐盘格挡怪 | `concept_003`（approved）、`integration_001`（review） | [Manifest](../../../assets/art/manifests/enemy/meal_tray_guard.yaml) |
| 馆藏巨典 | `concept_004`（approved）、`asset_001`（approved） | [Manifest](../../../assets/art/manifests/enemy/great_volume_boss.yaml) |

版本明细、原始来源和实际接入路径由 Manifest 与保留源包维护，不在此复制逐文件清单。当前选定版本可能仍为 review；目录移动与文档清理不改变批准状态。验证入口见[美术验证](../verification.md)。

## 五套图书馆敌人动作方向

已批准概念作为身份参考，单视角朝右制作，朝左由原表现层处理；未制作八方向。七动作复用原模拟时钟与混合播放，不另建战斗状态机。攻击／施法由模拟锁定，受击不抢占；死亡末帧冻结，恢复生命按原流程重置。设计F1／4／8／12／16是姿势约束，远程释放不等于弹道已命中。

| 对象 | 动作签名 | 最终机器参数 |
| --- | --- | --- |
| 键帽拳灵 | 蓄力收拳，蹬地向前，双键拳面撞击后迅速回防 | [动作卡](../../../design/concepts/enemy/keycap-brawler/asset_001/action-cards.json) |
| 投影独眼灵 | 轻悬浮、挡片收拢聚焦，镜头释放时机身小幅后坐 | [动作卡](../../../design/concepts/enemy/projector/asset_001/action-cards.json) |
| 归还印章怪 | 木柄沿伸缩套直上直下，印底平行落地，回弹利落 | [动作卡](../../../design/concepts/enemy/return-stamp/asset_001/action-cards.json) |
| 馆藏巨典 | 沉重抬升后下砸，书签延迟回摆，开页释放纸飞机 | [动作卡](../../../design/concepts/enemy/great-volume-boss/asset_001/action-cards.json) |
| 图书管理员 | 平稳值守，两翼按秩序展开，归架书群集中指向目标 | [动作卡](../../../design/concepts/enemy/cyber-librarian/asset_001/action-cards.json) |

源图、裁切与部件参数分别在原包source／build-config.json；当前资产与接入状态见上表Manifest。动作卡JSON是机器参数，不再复制成每对象数百行Markdown。
