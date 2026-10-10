# RUN-02 · 条件事件、支付与一次性结果

- 功能 ID：RUN-02
- 所属系统：探索
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

条件事件、支付与一次性结果。玩家价值：战外选择。

## 实现与规则入口

- 实现入口：[short_run.gd](../../game/run/short_run.gd)、[event_def.gd](../../game/content/event_def.gd)
- 规则事实源：[录入](../content/authoring.md)
- 跨系统边界参见[集成约束](../development/integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E14。编号和重跑入口见[共享验证目录](../development/verification.md)。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

内容数量少，非记忆收集系统

## 统筹状态

2026-10-10已汇总到总览；后续在本档案就地维护当前能力、证据与边界。


## M1当前接入与验证（已汇总（2026-10-10））

2026-09-16；基线 `7f95448` 后本功能提交。固定区域、地点访问与当前M1主流程已接入，入口和状态见[CORE-02](core-02.md)，精确命令和本次结果见[验证E20](../development/verification.md)。旧随机活动局保留原快照恢复；M1保存访问、等级、构筑、临时人物、战报和待选奖励；中断战斗从战前恢复。普通派遣在M1按终端数量开放，保持原计时与费用；旧解锁购买仅适用于旧流程。地图、照片与真实人物仍占位，设备与真人边界不变。

## 多轮热点与跨地图线索（已汇总（2026-10-10））

- 状态：已验证并接入原M1战役。热点可在同一调查中选择多个节点；允许返回的轮次保留当前节点，继续探索恢复未结束子页。全局线索随原profile保存，可供后续地点、区域读取；地点身份采用region:place，避免不同地图的同名逻辑地点混淆。剧情和条件事实源为resources/content/events/hotspot_dialogues.json，执行入口game/run/hotspot_event.gd、LocationVisit／CampaignJourney及campaign_hub事件适配器；呈现复用choice_page。
- 已有系统热点扩为回滚记录→记录线索→跨地点对照；人物热点继续原虚拟发明家入队和护盾编队建议，记忆热点继续原查看即收集。可选线索不会成为通关必需条件；未增加人物／敌人动作。叙事模型只支持显式节点、flag／program条件和允许的编队命令，不执行任意脚本。
- 2026-10-08，基线51c4118＋工作树：choice_pages_check无头107／0、三尺寸GUI197／0；原campus_playthrough_check61／0，完整战役无头149／0／GUI150／0。命令及证据见verification的“选择子页与热点关联”；覆盖退出与继续、实际鼠标多轮选择、跨地图引用、一次性标记、固定对象条件、失败回滚与旧存档。图谱检查验证line引用、选项ID唯一、目标节点存在和每节点可达结束；未做任意外部Mod图谱或所有未来内容验收。
- 已汇总（2026-10-10）：Journey schema1增加可选event屏幕、event_states与event_spot；Campaign schema1增加可选story_flags，旧profile v4兼容；规则和维护方法集中在game-design现行M1章节。美术版本与授权仅归event-choice-ui任务。

### 热点返回权限（2026-10-08，已汇总（2026-10-10））

已接入并验证；基线dbe4aa1＋工作树。事件默认allow_return与节点覆盖值共用原JSON定义，具体维护规则归content-authoring／game-design。移除纯导航leave选项；无选项结束页通过允许的页头返回完成，不留下无出口页。控制器检查权限并拒绝事件期间的旧地点操作；中途返回、菜单保存与继续保留原节点和访问快照，不引入随机抽样、存档字段或人物／敌人动作。

入口hotspot_event.gd、campaign_hub.gd与campaign_panel.gd；event_return_check新增配置、真实点击／Esc、旧动作、原磁盘恢复、基地续玩、失败确认／返回保存回滚及终页结束检查。PowerShell7／Godot4.7.2：三尺寸GUI111／0，原choice_pages GUI197／0／最终无头96／0，原全战役无头149／0，页面清理64／0；紧凑三候选复验235／0。日志、必要截图及命令归verification与event-choice-ui/review/codex-workflow/return-policy。

已汇总（2026-10-10）：原M1热点可按轮次限制离场；不改变旧存档schema。当前对话结果固定，防重抽仍依赖原已保存访问／奖励快照；未来随机分支需先冻结结果再展示。未验所有未来条件组合、移动端、实体手柄、Web包或真人阅读，不把开关当作任意随机事件的防重抽实现。
