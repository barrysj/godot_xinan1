# META-01 · 教学解锁与出发准备

- 当前状态：已验证当前准备功能；2026-10-14；实现基线 f32e2b7 后。
- 入口：game/meta/dispatch_catalog.gd、campus_progress.gd、scenes/expedition/campaign_hub.gd、game/combat/code_battle_simulation.gd、scenes/battle_demo/code_panel.gd。

出发准备是教学派遣的永久功能解锁。各物品池通过委托开放；每次新探索选择携带物品，点数和格子共同限制。不会收取另一轮永久资源，不是购买一次性准备资格。全局生命成长已从新战役构筑移除。规则与首轮数值只维护在 docs/combat/rules.md 的出发准备章节。

原库存／战斗规则／战役检查点接入完成；AI图标统一准备页和局内道具栏。旧两项库存补0迁移。原供给与转码、护盾和战中复苏均走同一原模拟。两人选择和途中招募已接入，当前规则与专项证据统一见CORE-02。

## 验证

2026-10-14：preparation_check.tscn headless 与 GUI --capture 均 failures=0，覆盖预算、界面选择、库存准确创建／续玩不补、真实护盾吸收产码、复苏目标／冷却／全灭禁止和原HUD实操。实际截图 .godot/preparation-pool.png、preparation-revive.png 已展示；这属于功能证据，不替代真人平衡。

回归：item_reward_check 69/0，accuracy_check 51/0，code_cycle_check 33/0。命令统一 Godot 4.7.2 --headless --path . --quit-after 1000 res://对应检查场景；GUI 使用 --rendering-method gl_compatibility 并追加 -- --capture。

## 待统筹

成长经济与出发流程改变，永久原始数值升级不再属于新主线；高层总览未修改。两人出发与途中会合专项验证见CORE-02；全流程结果见META-02。
