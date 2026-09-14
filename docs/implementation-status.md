# 实现状态索引

## 1. 基线与阅读方式

- 盘点日期：2026-09-14；分支：main；代码基线：`1ad601f0e2b59706b88a6f8d6c680b9fb5626ef1`。本轮只修改统筹文档，基线不含本轮文档提交。
- 已读取 [临时摘要清单](tmp/README.md) 中全部三份摘要、AGENTS.md、游戏设计、战斗、动画、校园、地图、内容录入、美术工作流与发布文档；抽查实际场景继承、数据资源、存档、交易、检查脚本及相关提交。摘要是施工声明，不作为独立验收证明。
- 证据优先级：当前代码与可重复结果 → 正式主题文档 → 当前分支已合入提交 → 临时摘要 → 未落地计划。发现冲突不取较乐观结论。
- 本轮实跑 Windows Godot 4.7.2 Mono 的无头检查及需要渲染的集成检查，见第 3 节。没有人工逐屏视觉验收，没有重导出当前版本，没有验证浏览器持久化、线上部署、手机触控、其他操作系统、实际玩家局长与长期平衡。测试截图不是本轮新增画面成果，不替代人工美术批准。
- `.godot/audit-20260914-*.log` 为本机忽略缓存，不随提交流转；以下记录关键结果与可重跑入口，不把历史截图当作当前画面证据。
- 开始时已有用户修改 `AGENTS.md` 和未跟踪的 `docs/tmp/` 摘要，均保留；原始摘要不纳入本轮提交。

状态统一定义：**已验证**＝实现存在且明确检查通过（仅限所列范围）；**已实装**＝存在实现但完整行为证据不足；**部分实装**＝只能完成部分目标流程；**原型**＝主要验证方向；**仅设计**＝正式方案存在但未落地；**待核验**＝材料不足；**已替代**＝旧路径不应继续扩展。通过程序检查不代表平衡、视觉审批或发布验收通过。

本表记录事实和边界；未来优先级见 [Roadmap](roadmap.md)，玩法规则继续维护于对应主题文档。

## 2. 当前玩家流程

```text
主菜单 Play → 基地 → 新探索（可选已解锁出发装备）
  → 五层路线：选择地点 → 查看敌人／事件
  → 战斗：首战空场部署四人，后续沿用阵位，可换装／候补 → 自动移动战斗
      → 胜利全恢复 → 战报 → 随机奖励 → 下一层
      → 失败 → 战报 → 保留构筑重新部署／调整 → 无限重试
  → 事件：条件选择与结果 → 奖励或下一层
  → Boss → 结算修复资源 → 基地升级 → 再次出发

探索中暂停 → 保存返回基地／主菜单／退出
  → 继续探索：地图、事件、待选奖励、战报恢复；半场战斗从战前重开

基地 → 成长解锁 → 大地图 → 地点详情与多人选队 → 扣费派遣
  → 出发动画 → 现实时间进度（可离线） → 领取一次 → 资源到账、人员归队
```

**已闭合的是短局系统循环，不是完整纪念主线。** 固定回归三条路线可完成；随机回归的 40 条样本路径也可完成，其中四条需要失败后重配站位再胜利。该结果证明当前样本无需永久成长即可通关，不等于所有随机种子或所有构筑都平衡。五类图鉴可从主菜单与实战暂停中浏览，关闭后保持暂停，继续后恢复战斗。

临时／断点：已有首战部署与奖励的上下文短提示，但没有完整新手教学、校园恢复叙事与纪念结局；当前内容量和实际局长没有达到目标的证据。首战确认的阵位会在后续遭遇沿用，失败重试也保留，玩家仍可战前调整。派遣提供资源回流，但没有恢复校园场景或新故事的后续反馈。商店、消耗品和挑战模式未接入。

## 3. 本轮验证证据

引擎：`F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`。在仓库根目录通过 PowerShell 7 运行：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --log-file .godot/audit-20260914-action.log res://game/combat/action_check.tscn
# 按下表替换场景和参数；用户参数放在 -- 后。
# 图形检查移除 --headless，加 --rendering-method gl_compatibility。
```

探索简称指 [expedition.tscn](../scenes/expedition/expedition.tscn)；测试进入独立 `.godot/` 档案，未操作玩家 `user://` 存档。图形检查中断或断言失败时不能只看进程退出码，应核对完成标记。

| 证据 | 场景／用户参数 | 本轮结果与范围 | 日志后缀 |
| --- | --- | --- | --- |
| E01 | [action_check.tscn](../game/combat/action_check.tscn) | PASS，failures=0；前后摇、死亡取消、弹道、同时结算、高攻速 | action |
| E02 | [auto_battle_check.tscn](../game/combat/auto_battle_check.tscn) | PASS，failures=0；寻路占位、射程、换目标、暂停倍速 | auto |
| E03 | [deployment_check.tscn](../scenes/battle_demo/deployment_check.tscn)，`--deployment-check` | PASS，failures=0；真实 Viewport 输入、点击立即部署／换人／换位、交换来源发光与自身格／右键取消、拖拽、部署菜单、撤回、部分部署恢复与下场沿用 | deploy |
| E04 | 探索，`--run-smoke` | PASS；三条固定兼容路线完成，资源 7/9/7；首战部署、后续沿用、奖励、恢复、续玩、候补、重试、结算 | run |
| E05 | 探索，`--meta-smoke` | 67 checks，failures=0；成长生效时机、迁移、检查点、离线派遣、回滚 | meta |
| E06 | 探索，`--map-check` | PASS；地点浏览、缩放拖动、详情空白关闭、锁定交互 | map |
| E07 | 探索，`--dispatch-check` | 36 checks，failures=0；多人校验、交易、旧任务迁移和 UI | dispatch |
| E08 | 探索，`--journey-check` | 17 checks，failures=0；出发到达、进度、领取、返程与失败回滚 | journey |
| E09 | [presentation_check.tscn](../scenes/battle_demo/presentation_check.tscn) | PASS，failures=0；插值、动作同步、不同帧率／倍速统计一致 | presentation |
| E10 | [authored_assets_check.tscn](../scenes/battle_demo/authored_assets_check.tscn)，`--require-two-models` | models=2，failures=0；真实图集与七动作元数据，不是美术审批 | assets |
| E11 | [skill_vfx_check.tscn](../scenes/battle_demo/skill_vfx_check.tscn) | failures=0；护盾出手一次、暂停倍速、回收与收尾 | vfx |
| E12 | [battle_ui_check.tscn](../scenes/battle_demo/battle_ui_check.tscn)，`--deployment-check` | failures=0；侧视投影、角色详情、背包装卸转移、存档、战中只读 | ui |
| E13 | 探索，`--random-check`，图形 | PASS：200 种子生成 197 种地图、146 种奖励序列；40 路径、156 场战斗，四次失败均经战报→重配→重试获胜；待选奖励磁盘恢复通过 | random |
| E14 | 探索，`--content-check`，图形 | `CONTENT_CHECK_COMPLETE`；装备、共享技能隔离、字符串身份、事件交易、冻结快照、旧档及非法资源拒绝 | content |
| E15 | 探索，`--team-check`，图形 | PASS；地图／战斗面板、换装卸装、详情空白关闭、候补、阵容保存、只读和 Esc 恢复 | team |
| E16 | 探索，`--pause-flow-smoke`，图形 | PASS；关闭窗口确认取消、主菜单返回、Play 再入及退出动作 | pause-flow |
| E17 | [menu.tscn](../scenes/menu/menu.tscn)，`--codex-check`，图形 | PASS：35 条图鉴逐项浏览；真实部署四人并开战后，从暂停进入图鉴时状态冻结，Esc 返回暂停，继续后战斗时间恢复推进 | codex |
| E18 | `build-web.ps1` release 包，Codex 应用内浏览器 | PASS（桌面范围）：完整五层路线、暂停恢复、结算与离开；Boss 前刷新恢复；修复后奖励／开战后立刻刷新分别恢复最新地图／同场战前 4/4 阵容。844×390 可进入和点选但文字与确认控件过小 | web |

E13 原失败均位于 stage=4：seed/path 为 `1/1`、`4/0`、`4/1`、`4/2`。定向枚举证明四条路径无需改变奖励或敌人数值，只需把默认站位中的应援者与冲刺手前后互换即可获胜；根因是旧检查把单一固定站位必胜误当作路线可完成。现检查保留默认站位首战，失败时必须走真实战报、重新部署和重试，再以替代站位获胜；胜利与路线完成断言未删除，且补跑了此前被提前退出遮断的磁盘恢复。该结果不替代真人难度与公平性数据。

E17 原夹具在 `_enter_node()` 清空部署后直接 `_start()`，被四人开战门槛拒绝。现通过实际部署组件依次部署四人，并在打开暂停前断言已进入战斗且时间推进；随后对图鉴冻结、关闭回到暂停及继续恢复逐项断言。原失败属于夹具前置过期，产品暂停／图鉴恢复行为在当前检查范围内正常。

所有引擎运行有根证书存储错误，部分有编辑器原图加载警告；通过项指专项断言通过，不是“引擎零报错”。`pixel_battle.gd::_load_atlas()` 已区分 editor 原图与导出 `load(Texture2D)` 路径，摘要所称“必须修复否则导出不可用”证据不足。应以当前导出包实际验证裁决。

## 4. 功能状态总表

验证列 E 编号对应上节；“静态”只表示本轮代码／资源检查，不是玩家行为通过。

| ID | 系统 | 玩家能力 | 状态 | 玩家价值 | 实现入口 | 正式文档 | 验证入口 | 已知边界 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CORE-01 | 核心流程 | 基地到 Boss 结算再出发 | 已验证 | 短局闭环 | [meta_hub.gd](../scenes/expedition/meta_hub.gd)、[expedition.gd](../scenes/expedition/expedition.gd) | [校园](campus-demo.md) | E04、E05 | 仅指定固定路线；非完整纪念主线 |
| CORE-02 | 核心流程 | 教学、校园恢复与纪念结局 | 仅设计 | 首次理解与情感回报 | 无；[设计](game-design.md) | [设计](game-design.md) | 无 | 结算资源不等于校园恢复或结局 |
| CORE-03 | 核心流程 | 独立战斗实验室 | 原型 | 快速比较战斗 | [battle_demo.tscn](../scenes/battle_demo/battle_demo.tscn) | [战斗](battle-demo.md) | E01–E03（共享层） | 主菜单已进入探索；实验室不接正式存档 |
| COMBAT-01 | 战斗 | 自动移动、索敌、射程与绕路 | 已验证 | 站位产生空间决策 | [auto_battle.gd](../game/combat/auto_battle.gd) | [战斗](battle-demo.md) | E02、E04 | 无购买合成经济；并非固定站桩 |
| COMBAT-02 | 战斗 | 普攻、自动技能、弹道结算 | 已验证 | 可重复的战斗规则 | [battle_simulation.gd](../game/combat/battle_simulation.gd) | [战斗](battle-demo.md) | E01、E09、E14 | 统一请求仅 attack；无手动技能／道具 |
| COMBAT-03 | 战斗 | 胜利全恢复、失败保留构筑重试、战报 | 已验证 | 降低失败成本、比较贡献 | [expedition.gd](../scenes/expedition/expedition.gd) | [校园](campus-demo.md) | E04、E05 | 无限制次数挑战；统计不等于失败原因分析 |
| COMBAT-04 | 战斗 | 主线无需刷成长、路线与阵容有策略差异 | 已验证 | 可理解且公平的难度 | [random_checks.gd](../scenes/expedition/random_checks.gd) | [设计](game-design.md) | E04、E13 | 40 条随机样本无永久成长可通关，四条需重配；无真人平衡数据 |
| DEPLOY-01 | 部署 | 手牌点选／拖拽直接部署、换人、换位及撤回 | 已验证 | 快速调整阵容 | [deployment_panel.gd](../scenes/battle_demo/deployment_panel.gd) | [战斗](battle-demo.md) | E03、E04、E12 | 交换来源亮边；自身格、右键或 Esc 可取消；有效目标立即生效；首战空场、后续沿用；触控待验 |
| DEPLOY-02 | 部署 | 地图／战前队伍面板和候补轮换 | 已验证 | 角色与装备构筑 | [visual_team_panel.gd](../scenes/team/visual_team_panel.gd) | [校园](campus-demo.md) | E15、E04 | 战中只读；已确认地图／战前阵位进入后续战斗沿用 |
| RUN-01 | 探索 | 随机地点组合与固定奖励快照 | 已验证 | 重玩变化与公平续玩 | [short_run.gd](../game/run/short_run.gd) | [录入](content-authoring.md) | E13 生成部分、E14 | 层数连线固定；路线通关归 COMBAT-04；非所有战斗数值冻结 |
| RUN-02 | 探索 | 条件事件、支付与一次性结果 | 已验证 | 战外选择 | [short_run.gd](../game/run/short_run.gd)、[event_def.gd](../game/content/event_def.gd) | [录入](content-authoring.md) | E14 | 内容数量少，非记忆收集系统 |
| RUN-03 | 探索 | 多区域、商店与消耗道具 | 仅设计 | 更长程资源取舍 | 无；[设计](game-design.md) | [设计](game-design.md) | 无 | 不把原提案数量当首发承诺 |
| RUN-04 | 探索 | 限次挑战模式 | 仅设计 | 可选高难度 | 无；[设计](game-design.md) | [设计](game-design.md) | 无 | 目前只实现主线无限重试 |
| REWARD-01 | 奖励 | 装备／训练／招募随机选择 | 已验证 | 局内成长与取舍 | [reward_catalog.gd](../game/run/reward_catalog.gd)、[short_run.gd](../game/run/short_run.gd) | [录入](content-authoring.md) | E04、E14 | 持有过滤、一次领取；不代表构筑流派已成熟 |
| REWARD-02 | 奖励 | 背包、穿戴、卸下、转移、属性生效 | 已验证 | 装备归属清楚 | [battle_inspector.gd](../scenes/battle_demo/battle_inspector.gd)、[team_panel.gd](../scenes/team/team_panel.gd) | [战斗](battle-demo.md) | E12、E14、E15 | 一人一件、一种一份；无多槽强化词条 |
| META-01 | 成长 | 修复资源购买升级与出发装备 | 已验证 | 探索回流下一局 | [campus_progress.gd](../game/meta/campus_progress.gd) | [校园](campus-demo.md) | E05 | 能力快照从新局生效；不是永久人物收集 |
| META-02 | 成长 | 地图选地点、多人成队、离线派遣与领取 | 已验证 | 基地可操作循环 | [location_dispatch_panel.gd](../scenes/expedition/location_dispatch_panel.gd)、[campus_progress.gd](../game/meta/campus_progress.gd) | [校园地图](campus-map.md) | E05–E08 | 两地点；独立后勤角色；现实时间本地计时 |
| META-03 | 成长 | 看到出发、驻留进度、返程 | 已验证 | 派遣反馈可见 | [campus_map.gd](../scenes/expedition/campus_map.gd) | [校园地图](campus-map.md) | E08 | 占位头像、折线动画；领取立即释放人员；动画不保存 |
| META-04 | 成长 | 标签影响派遣选择 | 部分实装 | 队伍身份差异 | [meta_catalog.gd](../game/meta/meta_catalog.gd) | [校园地图](campus-map.md) | 静态、E07 | 校验框架存在，但当前 required_tags 均空；无收益加成 |
| SAVE-01 | 存档 | 节点续玩、战报奖励恢复、成长任务共存 | 已验证 | 可安全中断 | [run_checkpoint.gd](../game/run/run_checkpoint.gd)、[meta_hub.gd](../scenes/expedition/meta_hub.gd) | [校园](campus-demo.md)、[录入](content-authoring.md) | E03–E05、E14、E18 | profile v3／checkpoint schema 1／run schema 5；Web 写后显式同步；半场不恢复 HP |
| SAVE-02 | 存档 | 旧档迁移、拒绝坏档、交易回滚与幂等结算 | 已验证 | 防重复领取和存档损坏 | [campus_progress.gd](../game/meta/campus_progress.gd)、[short_run.gd](../game/run/short_run.gd) | [录入](content-authoring.md) | E05、E07、E14 | 有限夹具；非断电故障注入；普通局内操作失败仅提示，不全量回滚内存 |
| UI-01 | 界面 | 暂停、倍速、菜单往返、确认退出 | 已验证 | 控制节奏与离开 | [battle_demo.gd](../scenes/battle_demo/battle_demo.gd)、[meta_hub.gd](../scenes/expedition/meta_hub.gd) | [战斗](battle-demo.md) | E02、E09、E16、E18 | Windows 与本地桌面 Web 已测；浏览器关闭标签行为未单列测试 |
| UI-02 | 界面 | 侧视战场、悬停摘要、点击详情、空白关闭与共享图标 | 已验证 | 减少遮挡与信息查找 | [battle_board.gd](../scenes/battle_demo/battle_board.gd)、[battle_inspector.gd](../scenes/battle_demo/battle_inspector.gd)、[object_icon.gd](../scenes/team/object_icon.gd) | [战斗](battle-demo.md) | E06、E12、E15 | 覆盖式详情统一关闭规则已记录；本轮无人工多尺寸视觉复核 |
| UI-03 | 界面 | 五类校园图鉴与菜单／暂停入口 | 已验证 | 规则查询 | [codex_panel.gd](../scenes/codex/codex_panel.gd)、[codex_catalog.gd](../game/codex/codex_catalog.gd) | [校园](campus-demo.md) | E17 | 35 条当前内容；程序检查不替代小屏可读性验收 |
| UI-04 | 界面 | 模板设置、音量与显示设置 | 已实装 | 基础偏好控制 | [menu.gd](../scenes/menu/menu.gd)、[ggt-core](../addons/ggt-core/) | [设计](game-design.md) | 静态 | 未逐项运行；存在音量设置不代表已接游戏音频 |
| CONTENT-01 | 内容 | Resource 录入、校验、预览并进入探索 | 已验证 | 低代码扩充内容 | [content_db.gd](../game/content/content_db.gd)、[content_preview.tscn](../scenes/content/content_preview.tscn) | [录入](content-authoring.md) | E14 | 扩展已有机制无需分支，新机制仍需代码；未手动逐模式复验预览 UI |
| CONTENT-02 | 内容 | 当前虚构角色、敌人、地点和事件样本 | 原型 | 足够验证短局 | [manifest.tres](../resources/content/manifest.tres) | [录入](content-authoring.md) | 静态、E14 | 注册 6 人物、7 敌人、5 技能、3 敌群、3 装备、9 奖励、1 池、3 事件、9 地点；注册数非每局出现数 |
| CONTENT-03 | 内容 | 真实同学、回忆、校园恢复与结局内容 | 仅设计 | 纪念主题落地 | 无；[设计](game-design.md) | [设计](game-design.md) | 无 | 尚以虚构内容验证；具体身份素材未确定 |
| ART-01 | 美术 | 同步动作、受击与退场回退 | 已验证 | 看懂行动结果 | [unit_presentation.gd](../scenes/battle_demo/unit_presentation.gd)、[battle_animation.gd](../scenes/battle_demo/battle_animation.gd) | [动画](battle-animation.md) | E09–E11 | 未配动画仍回退旧图；无骨骼后端 |
| ART-02 | 美术 | 两名绘制角色、护盾特效、三张战斗背景 | 部分实装 | 主要战斗视觉样本 | [资产登记](../assets/art/asset_manifest.yaml)、[locations](../resources/content/locations/) | [动画](battle-animation.md)、[工作流](art/WORKFLOW.md) | E10–E12 | 六项均 review、获试接入授权；未最终视觉批准，其余角色／敌人仍占位 |
| ART-03 | 美术 | 动作预览与切帧生产工具 | 已实装 | 降低后续动画试错 | [motion_preview.tscn](../scenes/battle_demo/motion_preview.tscn)、[build_battle_frames.py](../tools/art/build_battle_frames.py) | [动画](battle-animation.md) | 历史摘要；本轮静态 | 本轮未重跑七模式工具检查；不当作玩家内容 |
| ART-04 | 美术 | 分阶段人工评审、版本与登记工作流 | 仅设计 | 资产可追溯 | [工作流](art/WORKFLOW.md)、[资产登记](../assets/art/asset_manifest.yaml) | [工作流](art/WORKFLOW.md) | 静态 | 规范已存在；新版完整三阶段生产流程尚未以新任务走通 |
| AUDIO-01 | 音频 | 战斗命中、技能与环境声音 | 仅设计 | 战斗反馈与气氛 | [pixel_battle.gd](../scenes/battle_demo/pixel_battle.gd) 仅发事件 | [动画](battle-animation.md)、[设计](game-design.md) | 静态检索 | 未发现游戏音频消费者；模板音量不是声音内容 |
| RELEASE-01 | 发布 | Web 构建与 Pages 自动发布配置 | 已验证 | 可分发入口 | [build-web.ps1](../build-web.ps1)、[push-export.yml](../.github/workflows/push-export.yml) | [发布](web-publishing.md) | E18；当前 release 包 | 本地 HTTP 入口通过；线上 Actions／Pages 未触发 |
| RELEASE-02 | 发布 | 当前版本桌面／浏览器／手机可用性 | 部分实装 | 真实设备可玩 | [export_presets.cfg](../export_presets.cfg) | [发布](web-publishing.md) | 当前原生专项＋E18 | Windows 与本地桌面 Web 通过；844×390 可操作但不可读，真机触控未通过验收 |
| CORE-04 | 兼容 | 旧固定站桩与固定内容主路径 | 已替代 | 保留旧档兼容价值 | [short_run.gd](../game/run/short_run.gd)、[gameplay.gd](../scenes/gameplay/gameplay.gd) | [录入](content-authoring.md) | 静态、E04、E14 | 旧 STAGES／算法保留兼容；新内容进入 Resource；不要删除迁移依赖 |

## 5. 已形成的能力组合

1. **构筑—战斗—回报**：部署、装备、自动移动和技能、有效贡献统计、恢复与重试、奖励接在同一条短局中；不需要另造战斗或奖励框架。
2. **可中断的探索**：随机内容与检查点、统一档案、基地往返和幂等结算组合；恢复的是节点状态，不是逐帧战斗。
3. **基地资源循环**：通关收入、升级、新局能力快照、多人离线派遣形成回流；现阶段回报主要是数值与功能解锁。
4. **内容生产到实战**：资源注册和校验、事件与奖励快照、角色技能实例隔离、战斗与队伍共用显示；工具和存档边界已有基础。
5. **动画集成样本**：两名真实图集角色、动作时序、技能特效、地点背景和详情交互已组合；全队美术一致性与审批尚不完整。

## 6. 系统断点、依赖与冲突

### 核心流程阻塞与验收缺口

- E13 随机通关样本与 E17 图鉴战斗恢复均已通过；前者仍不能从自动样本推导真人公平性，后者也不替代小屏阅读和触控验收。
- 纪念主线的“为什么出发—发生了什么—恢复了什么”未闭合，通关目前主要得到资源。
- 首战完整部署需四次拖动或八次点选；原先逐场重复没有新增决策价值，现改为后续遭遇沿用已确认阵位，并保留战前调整与失败重配。是否进一步简化首战仍需陌生玩家与真机触控判断。

### 体验质量与内容不足

- 缺陌生玩家教学、可核对的失败解释和实际局长数据。现有贡献统计不能证明玩家理解目标选择；无限重试也不能替代合理难度。
- 随机地点、奖励已有，但敌群和装备组合有限；重复刷相同内容可能只改变数值。没有商店不构成当前短局硬缺陷。
- 派遣有完整操作反馈，但标签未产生实质要求，收益未映射为校园恢复展示；不宜仅按脚本可配置性宣称玩法深度。
- 六项美术为待评版本；角色完成度混合。背景只显式覆盖部分地点，不能把三张图说成全校园完成。

### 技术债与重复边界

- 实际入口继承链为 `meta_hub → expedition → pixel_battle → battle_demo`；存档钩子、战斗和画面复用有效，但场景职责较集中。增量拆分应围绕变更痛点，不重建一套平行框架。
- 两套地图：局内地点 Resource 与局外 `MetaCatalog.LOCATIONS` 职责不同，同名 library 不代表同一状态或同一地图；未来关联需要明确映射，不直接合并 ID。
- 队伍面板与战场详情是两种入口，共用装备模型和图标。修一处必须回归另一处，避免建立第二份归属数据。
- 存档三层版本号各有含义；兼容旧固定内容和当前 Resource 快照并存。基础角色／装备／技能数值读当前资源，不能宣称整局全部数据不可变。
- 交易回滚与普通局内保存不同：购买、派遣、结算检查覆盖失败回滚；普通选路、换装等先改内存再保存，失败提示不等于回滚整个 Run。故障恢复策略需按操作分清。
- 证据位于忽略缓存；部署检查已跟随“首战空场、后续沿用”规则更新。仅有脚本或旧 PASS 仍不构成持续回归体系。

### 历史歧义清理结果

下列歧义已按当前代码与验证结果回写主题文档。设计稿保留历史提案用于追溯，但不再使用“当前”措辞覆盖后续实现；规则只在对应主题文档维护，不在 Roadmap 复制。

| 原歧义 | 当前判断 | 已处理 |
| --- | --- | --- |
| game-design 第 13／16／17 节曾把模板、固定格与无续玩称为当前状态 | Start 已进入完整短局；可移动战斗、续玩和 Resource 均存在 | 三节标为历史快照并链接当前状态／主题文档 |
| battle-demo 曾称上下对阵、全员占位，且 F5 进入实验室 | 当前左右接近、两名绘制角色；F5 进入探索 | 修正导言、素材状态和独立实验室入口 |
| campus-demo 曾写 profile v2 与单人派遣 | profile v3，多人任务兼容旧单人 | 更新存档版本；派遣细节归校园地图文档 |
| campus-demo／game-design 曾写 run schema 2、七奖励 | run schema 5；当前注册 9 奖励，非每次全部可抽 | 更新当前数字；历史 v0.6 数字保留并明确日期 |
| content-authoring 曾把初始排位写成固定目标规则 | 实际按空间距离、射程与动态位置选目标 | 改写目标语义并引用现行战斗规则 |
| game-design 的撤离带回资源提案与当前新局确认混淆 | 返回基地仅保存；替换新局丢弃未结算收入；没有独立带收益撤离 | 两处均标为未实现提案并写明当前规则 |
| web-publishing 曾称刷新不支持续玩 | 节点可恢复；战斗中断从同场战前重开 | 修正边界，并记录当前包的安全节点／立即刷新实测 |
| 摘要曾称原图加载必然导致导出不可用 | 导出路径使用导入 Texture2D，当前 Web 包资源完整 | 保留原生编辑器警告边界，不再把它列为发布阻塞 |

### 平台与发布风险

9/14 当前 release Web 包已完成本地桌面浏览器全流程和刷新恢复验证；这仍不能代替线上 Pages、其他浏览器或真机。模板项目名／版本与英文模板菜单仍在，属于 M3 发布身份清理，不在 M0 扩张。844×390 已确认文字、卡片与部署目标过小，故手机不列为通过。音频、后台切页、存储配额和不同浏览器的 IndexedDB 策略仍需目标设备验证。

## 7. 集中待核验清单

- E13 已证明四条原失败路径可通过站位调整赢回；仍需真人试玩判断默认提示是否足以促成这种调整、主线难度是否合适。
- 图鉴战斗暂停恢复已有自动证据；仍需在真机上检查图鉴滚动、关闭按钮和中文可读性。
- 当前导出资源、桌面浏览器全流程与刷新检查点已验证；Android／iOS 真机触控、其他目标浏览器、线上 CI／Pages 仍未检查。
- 陌生玩家能否根据短提示首次完成部署、是否会主动调整沿用阵位、战斗取舍是否可理解；20～30 分钟仍是体验目标，不是测量结果。
- 非正常关闭／磁盘失败时普通局内操作的一致性，系统时钟跳变的派遣行为；不以现有夹具保证任意异常安全。
- 动作预览工具各模式当前完整行为、设置逐项效果、最终视觉审查与资产版本批准；未覆盖项目继续保留边界，不当作下一里程碑已完成基础。
