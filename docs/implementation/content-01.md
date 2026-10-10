# CONTENT-01 · Resource 录入、校验、预览并进入探索

> 本文件是该功能的持续实施档案，不是某次 session 日志。功能 session 更新此处；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：CONTENT-01
- 所属系统：内容
- 当前状态：已验证
- 最近验证：2026-10-09，区域流程资源专项基线 `10fb33b` 加工作树；旧内容预览证据仍为 E14，本次不代替其全量复验。

## 玩家能力与接入范围

Resource 录入、校验、预览并进入探索。玩家价值：低代码扩充内容。

## 实现与规则入口

- 实现入口：[content_db.gd](../../game/content/content_db.gd)、[content_preview.tscn](../../scenes/content/content_preview.tscn)
- 规则事实源：[录入](../content-authoring.md)
- 跨系统边界参见[集成约束](integration.md)；本文件不另存规则数值或美术审批记录。

## 验证与证据

- 已有证据：E14。编号和重跑入口见[共享验证目录](verification.md)。
- 以上是继承的验收记录，不表示本次文档整理重新验证。新增验证在此更新日期、代码基线、命令、结果与覆盖边界；共享检查变化同步目录。
- 程序通过不等于真人体验、目标设备或美术审批通过。

## 已知边界与未完成项

扩展已有机制无需分支，新机制仍需代码；未手动逐模式复验预览 UI

## 交接给统筹

当前状态已纳入 2026-09-15 总览。后续 session 在此注明影响其他功能、平台支持、里程碑或整体可玩流程的变化，由统筹汇总；不要追加逐日施工过程。


## 校园区域流程录入（待统筹）

2026-10-09：新增 CampusRegionFlow → CampusRouteStage → CampusRouteStop → CampusRoutePlace 资源链，统一于 `resources/campaign/`。Stages 决定顺序，Choices 决定同站岔路；站点只引用已有共享地点、Manifest已登记敌阵和原热点模板。地图地标仍由浏览器工具维护。原 CampusLocation／Route Pool 保留用于短局与原内容预览，不把两套定义混为主线事实。

`addons/campus-flow/` 给区域资源的原生检查器增加概览、校验和预览；`scenes/content/campus_flow_preview.tscn` 复用校园全图，支持未保存的检查器快照和已保存资源刷新，不读写玩家档案。预览清单可选择重复空间地点的不同访问，长列表有滚动。操作与字段事实源见[区域流程配置](../campus-flow-authoring.md)。

基线10fb33b加工作树，专项无头120／0、GUI154／0；覆盖三区域、五站原控制器、12站小窗口清单、无效引用／坐标、真实JSON和检查器组件。原完整战役149／0、双队伍真实GUI151／0。共享入口与已知边界见[验证记录](verification.md#区域流程资源与编辑器分工)。未逐项鼠标录入原生Inspector、未验Web导出或触控；无新事件内容与任意图编辑器。待统筹：主线地区内容由硬编码变为Resource，旧Journey需重开。
