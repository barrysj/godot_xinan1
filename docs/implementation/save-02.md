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
