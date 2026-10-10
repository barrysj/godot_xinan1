# SAVE-01 · 节点续玩、战报奖励恢复、成长任务共存

- 功能 ID：SAVE-01
- 所属系统：存档
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

节点续玩、战报奖励恢复、成长任务共存。玩家价值：可安全中断。

## 实现与规则入口

- 实现入口：[run_checkpoint.gd](../../game/run/run_checkpoint.gd)、[meta_hub.gd](../../scenes/expedition/meta_hub.gd)
- 规则事实源：[校园](../campaign/play-guide.md)、[录入](../content/authoring.md)
- 跨系统边界参见[集成约束](../development/integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E03–E05、E14、E18。编号和重跑入口见[共享验证目录](../development/verification.md)。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

profile v4／旧checkpoint schema 1／旧run schema 5／M1独立checkpoint schema 1；Web 写后显式同步；半场不恢复 HP

2026-09-16 合并闪卡分支：保留 main 的 v4 读取／写入及 campus_progress.json 路径，不引入旧短局分支的 v3 专用路径，避免向该文件写入 v4。保存失败时可显式选择不保存退出；详见 campus-demo.md 与 SAVE-02。已有 v3 分支档不自动合并，也不覆盖玩家档。

## 统筹状态

2026-10-10已汇总到总览；后续在本档案就地维护当前能力、证据与边界。


## M1当前接入与验证（已汇总（2026-10-10））

2026-09-16；基线 `7f95448` 后本功能提交。固定区域、地点访问与当前M1主流程已接入，入口和状态见[CORE-02](../campaign/core-02.md)，精确命令和本次结果见[验证E20](../development/verification.md)。旧随机活动局保留原快照恢复；M1保存访问、等级、构筑、临时人物、战报和待选奖励；中断战斗从战前恢复。普通派遣在M1按终端数量开放，保持原计时与费用；旧解锁购买仅适用于旧流程。地图、照片与真实人物仍占位，设备与真人边界不变。

## 主线代码库存保存

2026-09-24，基线 `b4b091e` 加 CORE-05 集成工作树：ShortRun schema 7 保存两程序、两种道具库存及本局已领取强化，旧 schema 补默认值，非法库存拒绝。沿用原检查点事务，半场中断恢复战前库存，胜利战报保存扣费，续玩战报不补充库存。代码块、冷却、维护接管不跨场保存。真实主线集成验证入口 `scenes/battle_demo/code_integration_check.tscn`，结果见本功能档案验证记录；profile 外层版本不变；schema 1～6 原档迁移为默认破解装配、库存和空强化列表。强化选择页也作为可恢复检查点保存。构筑序列化版本已升级并需随 CORE-05 维护。

## 热点节点与跨地图事实保存（已汇总（2026-10-10））

2026-10-08，51c4118＋选择子页工作树：沿原profile v4和CampaignCheckpoint schema1，Campaign.story_flags与LocationVisit.event_states为可选字段，旧档默认空；当前事件节点保存在原Journey，退出地点详情不重置节点。事件选择将新状态和新线索作为同一次CampusProgress.save_campaign_checkpoint事务提交，写失败恢复原checkpoint与线索。非法flag、节点／历史、活动热点引用和已结束event屏幕拒绝恢复；进入下一地点自然清除当地节点，全局事实继续保留。每节点选项携带当前热点和节点ID，过期按钮不能重复推进。

choice_pages_check无头107／0、GUI197／0覆盖真实JSON与磁盘重读、原子写失败、坏存档与旧字段缺省；完整原战役149／0／GUI150／0。精确入口归verification，叙事规则归RUN-02／game-design。半场战斗仍从战前恢复；没有新存档文件体系。Web导出未实测，事件数据include_filter已补齐。

最终边界补验：choice_pages_check无头107／0包含合法空奖励继续后进入事件的真实JSON恢复；run-debug.ps1 -Check -EnginePath <Godot console> 为75／0。旧短局／测试入口未创建campaign_panel时的输入仍安全转交原控制器。GUI197项与终端54项为本任务布局验证，空池后事件补验不涉及新的画面变化。
