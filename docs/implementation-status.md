# 项目实现总览

> **这是整个项目的当前状态，不是某一轮施工记录。** 由统筹 session 维护；具体功能的实现、验证和限制见[功能实施目录](implementation/README.md)，未来安排见 [Roadmap](roadmap.md)。

最近统筹：2026-09-15；文档整理基线：`467784e`；已有功能验收基线：`7fe7529`。本次仅重组文档，未重跑游戏检查。功能 session 更新档案后，总览可能暂时滞后；最新可验证的功能证据优先。

## 当前阶段

**M0 短局试玩版已完成工程验收，当前进入 M1 校园短篇制作。** 探索、构筑、战斗、结算、成长和续玩已有闭环；完整纪念剧情、真实人物内容与校园恢复表达尚未落地。M0 完成不代表手机、陌生玩家或最终美术验收通过。

## 玩家现在可以怎么玩

```text
基地 → 新探索 → 选路 → 战斗／事件 → 奖励 → 下一层
                         ↓
            首战部署，后续沿用并可调整 → 自动战斗
            胜利全恢复；失败保留构筑、无限重试
最终 Boss → 资源结算 → 基地升级 → 再次探索

中途离开 → 保存检查点 → 继续探索
（半场战斗从战前重开，战报和待选奖励可恢复）

基地 → 地图选地点与后勤队伍 → 派遣 → 离线计时 → 领取与归队
```

目前是五层短局，已有上下文提示、队伍与装备详情、图鉴、暂停和倍速。通关主要得到资源，尚无完整故事收尾；派遣收益尚未对应可见的校园恢复。

## 整体能力概况

这是统筹摘要；精确功能状态、实现路径和验证边界只在对应档案维护。

| 能力 | 当前整体判断 | 具体实施入口 |
| --- | --- | --- |
| 探索闭环 | 短局到结算、再出发已贯通 | [核心流程](implementation/core-01.md) |
| 自动战斗 | 移动、射程、技能、弹道及重试可用 | [移动](implementation/combat-01.md)、[结算](implementation/combat-02.md)、[难度样本](implementation/combat-04.md) |
| 部署构筑 | 首战部署、后续沿用、候补与换装可用 | [部署](implementation/deploy-01.md)、[队伍](implementation/deploy-02.md)、[装备](implementation/reward-02.md) |
| 路线事件 | 随机地点、奖励快照与条件事件可用，内容量有限 | [路线](implementation/run-01.md)、[事件](implementation/run-02.md)、[奖励](implementation/reward-01.md) |
| 局外成长 | 升级、多人派遣和资源回流可用，标签要求尚未启用 | [成长](implementation/meta-01.md)、[派遣](implementation/meta-02.md)、[标签](implementation/meta-04.md) |
| 存档退出 | 节点续玩、迁移与桌面 Web 刷新恢复已有证据 | [续玩](implementation/save-01.md)、[异常边界](implementation/save-02.md)、[暂停](implementation/ui-01.md) |
| 内容生产 | Resource 录入与校验已有基础，仍以虚构样本为主 | [录入](implementation/content-01.md)、[内容样本](implementation/content-02.md) |
| 纪念主线 | 剧情、人物与校园恢复仍需制作 | [主线](implementation/core-02.md)、[纪念内容](implementation/content-03.md) |
| 美术音频 | 两角色、一个特效、三背景试接入；声音未接通 | [资产接入](implementation/art-02.md)、[工具](implementation/art-03.md)、[声音](implementation/audio-01.md) |
| 平台交付 | Windows 和本地桌面 Web 有证据，手机未通过 | [构建](implementation/release-01.md)、[平台](implementation/release-02.md) |

全部 36 项稳定功能 ID 见[功能目录](implementation/README.md)，不在总览重复宽表。

## 最重要的缺口

1. **纪念体验**：出发理由、关键人物与事件、通关后的校园变化和可重看结尾。
2. **目标设备**：小屏探针已暴露文字与操作目标偏小；Android／iOS 真机、其他浏览器与线上部署尚未验收。
3. **真人试玩**：自动样本通关不代表新玩家会调整阵容；实际局长和主线公平性仍缺证据。
4. **视听完成度**：六项资产仍为 review，其余角色／敌人有占位内容；正式批准与声音需随内容制作推进。
5. **集成维护**：存档、两类地图和多个装备入口有共享边界，详见[集成约束](implementation/integration.md)。

## 证据与维护职责

- M0 已有随机路径重配通关、真实战斗图鉴恢复、阵位沿用和 Web 写后同步记录，详见[验证目录](implementation/verification.md)。这是既有验收记录，不是本次整理的新测试。
- 平台、真人和美术审批不能用程序检查代替；缓存日志不能作为跨 checkout 的唯一证据。
- 原[临时摘要](tmp/README.md)保留，不再用它们维护当前状态；此次没有删除或提交原始摘要。
- 功能 session 更新 `docs/implementation/<功能ID>.md` 及必要的规则主题文档；统筹 session 消费“待统筹”项，更新本总览及 Roadmap。具体操作见[目录说明](implementation/README.md)。

状态统一为：**已验证**（明确验证通过，仅限覆盖范围）、**已实装**（实现存在但完整证据不足）、**部分实装**（只覆盖部分目标流程）、**原型**（验证方向）、**仅设计**（方案存在未实现）、**待核验**（材料不足）、**已替代**（不再扩展的旧路径）。代码与可重复验证优先于文档、提交说明和历史摘要。
