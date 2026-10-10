# SAVE-02 · 旧档迁移、拒绝坏档、交易回滚与幂等结算

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：SAVE-02
- 所属系统：存档
- 当前状态：已验证
- 最近整理：2026-09-15；继承功能基线 `7fe7529` 的状态记录，文档拆分基线 `467784e`；本次未重跑游戏检查。

## 玩家能力与接入范围

旧档迁移、拒绝坏档、交易回滚与幂等结算。玩家价值：防重复领取和存档损坏。

## 实现与规则入口

- 实现入口：[campus_progress.gd](../../game/meta/campus_progress.gd)、[short_run.gd](../../game/run/short_run.gd)
- 规则事实源：[录入](../content-authoring.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 2026-09-17，基线 `10dfbcd` 后本功能提交：新增正式“重开存档”，入口 `campaign_hub.gd::_profile_action`、原子重置 `campus_progress.gd::restart_profile`。确认后备份原始字节，支持坏档恢复，写入失败恢复内存与禁止覆盖状态；按钮与范围说明见 campus-demo.md。Godot expedition.tscn `-- --profile-reset-check` 图形运行：14 checks / 0 failures，覆盖取消、未确认调用、全字段清空、磁盘重读、唯一备份、坏档与故障回滚。实际截图 `.godot/profile-reset-confirm.png`。仅用 `.godot` 隔离档；未模拟断电与磁盘满，Web 未实测。待统筹：基地新增正式重开入口，备份保留策略由玩家管理。

- 2026-09-16 main 合并（`48acc51` / `f32fa4f`）：存档实现与合并前 main 完全一致，保留 v4 与 campus_progress.json，不把 v4 写入旧分支的 v3 专用档；下述 v3 隔离记录仅适用于历史闪卡分支。退出失败显式放弃功能保留。测试改为 `.godot` 隔离档，覆盖 v1～v4 可读、v5 拒绝且不可覆盖，以及取消/显式退出；SAVE_COMPAT_CHECK PASS。CAMPAIGN_CHECK 103/0、完整 CAMPAIGN_FLOW 124/0 通过，未写入玩家存档。待统筹：默认路径说明已同步 campus-demo.md。

- 2026-09-16，基线 996cee4：只读实际档复现 loaded=false/blocked=true，确认是共享 user:// 中 v4 战役档被仅支持 v1～v3 的读取器拒绝，并非文件不可读或 JSON 损坏。v3 默认改用 campus_progress_v3.json，旧兼容档只读沿用，新版档保留并提示独立进度；不降级、不覆盖玩家档。scenes/expedition/save_compat_check.tscn 图形运行加 `-- --codex-check` PASS，覆盖实际只读复现、隔离版本1～4、未来档禁止写入、退出失败取消及实际显式不保存退出；截图 .godot/save-compat-exit.png。meta-smoke 67 checks / 0 failures，原玩家档 SHA256 前后一致。项目原像素图警告仍存在。待统筹：按schema隔离写入，非按工作树隔离；未新增进程锁，禁止并发写同档。

- 已有证据：E05、E07、E14。编号和重跑入口见[共享验证目录](verification.md)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

有限夹具；非断电故障注入；普通局内操作失败仅提示，不全量回滚内存

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。

## M1当前事务边界（待统筹）

2026-09-16；profile v4兼容v1～v3，不把旧通关次数换为终端。教学、终端、人物、回忆与终局由CampusProgress提交，失败回滚；探索快照失败恢复已保存的M1模型。不可读取的战役/访问形状会拒绝覆盖；普通旧Run仍保留此前失败提示边界。验证见[E20](verification.md#m1-战役验证-e20)，含103项永久状态检查与六顺序实际流程；非断电故障注入。

## 局内成长规则版本（待统筹）

2026-10-07，基线6126c11加工作树；原ShortRun构筑schema8记录growth_rules，不变更profile或战役外层schema，不新增存档路径。旧schema1～7采用旧成长版本；写回schema8仍保留该版本。新局采用新预算，非法／未来版本、超份数与同人装备重叠拒绝恢复且不改变接收对象。growth_budget_check.tscn无头38／0、GUI47／0，包含JSON／原checkpoint往返、旧高成长保留和第二次恢复；详细实现与数值只见CORE-05／battle-demo.md。未模拟断电、并发进程或最高旧成长整场；图形详情层级问题另行处理。

## 奖励轮次与真实JSON恢复（待统筹）

2026-10-07，基线42d479c加工作树：原ShortRun schema8保存reward_offer_count与candidate_recruit_shown，可兼容早先同schema缺字段快照；计数须有限整数、标记须布尔。原冻结奖励包含可选offer_slot，旧无该字段仍可恢复。新候选生成推进，页面重开／原checkpoint恢复不推进。

真实JSON往返发现schema数值被解析为浮点后，数组成员判断跳过6／7／8的配置迁移分支；现改为数值相等判断，不改变未知版本拒绝。reward_slots_check无头22／0、GUI29／0，含计数／标记恢复、坏字段原子拒绝、原校园冻结候选与领取；growth_budget_check无头41／0加入JSON stringify／parse的成长版本与属性保留。此前直接Dictionary往返不能代替真实JSON验证。无新存档模型／路径，零奖励池的合法持久化继续入口仍待接入；未测断电或并发。

## 合法空奖励页与道具库存（待统筹）

2026-10-07，基线83437f6加工作树：原ShortRun schema8／校园Journey schema1使用可选rewards_exhausted区分合法耗尽与损坏空页；缺字段的旧正常页仍可读，未标记空页仍拒绝。校园空页要求已赢守卫和原奖励／访问状态；短局空页不允许混入候选或待选对象。继续动作受原页面和领取标记约束，重复调用无额外奖励。

道具奖励写回原code_supplies；读取时校验完整两槽及共用上限，再把合法JSON数量归一为整数。item_reward_check无头69／0、GUI78／0，含种子／无种子原短局、原校园checkpoint、真实JSON、坏形状与重复动作；完整原战役GUI149／0。详细边界见REWARD-01。未模拟断电或并发，未新增profile／路径／存档系统。

## 临时伙伴与出发阵位事务（待统筹）

2026-10-07，基线aa61309加工作树：CampaignState.formation_valid集中校验六格／四名／去重及基础、永久人物身份；分析员为原新局基础候补。活动探索仍记录临时发明家阵位，不提前写入永久偏好；CampusProgress.settle_region新增可选最终阵位，先按即将兑现的名单验证，再与资源／终端／永久人物共用原_commit。旧调用可不传阵位，原profile／Journey／ShortRun格式及路径未增加。起始检查109／0、GUI125／0覆盖真实JSON／读盘、基础分析员偏好、临时伙伴恢复、坏阵位原子拒绝及成功永久结算；完整战役150／0。不是断电或并发故障注入；详细事实见CORE-05。

## 旧活动局敌阵安排兼容（历史，已由schema2替代）

2026-10-07，基线30389ff加工作树：原CampaignJourney.restore的可选encounter_rules只接受1或2并归一为整数，缺字段默认1；不变更外层profile／Journey schema或存档路径。新局2使用新节点安排，旧局再次保存仍为1。原战役按当前地点与规则版本重建敌阵，并非保存完整run.node；不得把派生节点误记为冻结快照。starting_strategy_check132／0、GUI154／0，实际JSON检查旧缺字段恢复／重新保存与失败重试仍巡逻、新局仍教室，未来／小数版本拒绝。原完整战役150／0；未作断电或并发注入，详细边界见CORE-05。


## 资源流程的当前探索快照（2026-10-09，待统筹）

按负责人开发阶段要求，CampaignJourney只接受schema2，删除旧Journey／encounter_rules的兼容恢复分支；旧活动探索需通过已有重开入口重新开始，不自动删除永久档案，不新建保存路径。原profile和ShortRun未扩展迁移逻辑。新格式在开局保存JSON安全的区域站次、地点显示／地标偏移、敌阵ID和强度，正常续玩冻结该定义，但不冻结人物／敌人资源或地图地标本身。

验证基线10fb33b加工作树：区域专项无头120／0、GUI154／0含真实JSON往返、坏定义和旧schema拒绝、新格式快照不因资源编辑缩短；原完整战役149／0；双队伍真实GUI151／0覆盖临时人物、编队、战斗阶段JSON、奖励及原结算。共享命令见[验证记录](verification.md#区域流程资源与编辑器分工)。未作断电或并发注入；此项不声称保留旧活动局兼容。
