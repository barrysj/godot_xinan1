# META-04 · 派遣人员选择

- 状态：旧标签门槛已替代；新主线为无数值差异的后勤人选，2026-10-14，待统筹。

当前三名后勤可自由选择一名执行委托，与战斗人物名单独立。无技能差别、收益加成、标签门槛、人数门槛或队伍名额；姓名与美术只用于身份和演出。选择器由dispatch_board读取meta_catalog.STAFF，交易统一由campus_progress.execute_commission验证已知身份。旧tag和crew_size字段仅供遗留随机短局兼容，不据此扩展新机制。

验证：dispatch_framework_check覆盖不同人员执行相同类型委托、未知人员拒绝、一次扣费与失败回滚；人物图像接入结果随META-03更新。规则只维护在[派遣地图](dispatch-map.md)，不另列重复参数。