# 实现状态索引

## 1. 基线与阅读方式

- 盘点日期：2026-09-14；分支：main；代码基线：`1ad601f0e2b59706b88a6f8d6c680b9fb5626ef1`。本轮只修改统筹文档，基线不含本轮文档提交。
- 粉笔精灵概念任务从已提交的 `62b58b0c6f1bc3f08b00076428f9081afebf9bb3` 基线开始；只新增待评概念及生产记录，未修改运行资源或游戏画面。
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
  → 战斗：空场部署四人、换装／候补 → 自动移动战斗
      → 胜利全恢复 → 战报 → 随机奖励 → 下一层
      → 失败 → 战报 → 保留构筑重新部署／调整 → 无限重试
  → 事件：条件选择与结果 → 奖励或下一层
  → Boss → 结算修复资源 → 基地升级 → 再次出发

探索中暂停 → 保存返回基地／主菜单／退出
  → 继续探索：地图、事件、待选奖励、战报恢复；半场战斗从战前重开

基地 → 成长解锁 → 大地图 → 地点详情与多人选队 → 扣费派遣
  → 出发动画 → 现实时间进度（可离线） → 领取一次 → 资源到账、人员归队
```

**已闭合的是短局系统循环，不是完整纪念主线。** 固定回归三条路线可完成；随机规则、事件与奖励已接入，但当前随机通关样本有失败，不能宣称所有目标路线已验收。图鉴可浏览，但战斗恢复专项检查失效，见 E17。

临时／断点：没有正式教学、校园恢复叙事与纪念结局；当前内容量和实际局长没有达到目标的证据；每个新遭遇重新空场部署，地图队伍调整不是“下场自动沿用站位”。派遣提供资源回流，但没有恢复校园场景或新故事的后续反馈。商店、消耗品和挑战模式未接入。

## 3. 本轮验证证据

引擎：`F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`。在仓库根目录通过 PowerShell 7 运行：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --log-file .godot/audit-20260914-action.log res://game/combat/action_check.tscn
# 按下表替换场景和参数；用户参数放在 -- 后。
# 图形检查移除 --headless，加 --rendering-method gl_compatibility。
```

探索简称指 [expedition.tscn](../scenes/expedition/expedition.tscn)；测试进入独立 `.godot/` 档案，未操作玩家 `user://` 存档。图形检查中断或断言失败时不能只看进程退出码，应核对完成标记；本轮图鉴检查在超时后终止。

| 证据 | 场景／用户参数 | 本轮结果与范围 | 日志后缀 |
| --- | --- | --- | --- |
| E01 | [action_check.tscn](../game/combat/action_check.tscn) | PASS，failures=0；前后摇、死亡取消、弹道、同时结算、高攻速 | action |
| E02 | [auto_battle_check.tscn](../game/combat/auto_battle_check.tscn) | PASS，failures=0；寻路占位、射程、换目标、暂停倍速 | auto |
| E03 | [deployment_check.tscn](../scenes/battle_demo/deployment_check.tscn)，`--deployment-check` | PASS，failures=0；真实 Viewport 输入、点选／拖拽／交换／撤回、部分部署恢复 | deploy |
| E04 | 探索，`--run-smoke` | PASS；三条固定兼容路线完成，资源 7/9/7；奖励、恢复、续玩、候补、重试、结算 | run |
| E05 | 探索，`--meta-smoke` | 67 checks，failures=0；成长生效时机、迁移、检查点、离线派遣、回滚 | meta |
| E06 | 探索，`--map-check` | PASS；地点浏览、缩放拖动、详情、锁定交互 | map |
| E07 | 探索，`--dispatch-check` | 36 checks，failures=0；多人校验、交易、旧任务迁移和 UI | dispatch |
| E08 | 探索，`--journey-check` | 17 checks，failures=0；出发到达、进度、领取、返程与失败回滚 | journey |
| E09 | [presentation_check.tscn](../scenes/battle_demo/presentation_check.tscn) | PASS，failures=0；插值、动作同步、不同帧率／倍速统计一致 | presentation |
| E10 | [authored_assets_check.tscn](../scenes/battle_demo/authored_assets_check.tscn)，`--require-two-models` | models=2，failures=0；真实图集与七动作元数据，不是美术审批 | assets |
| E11 | [skill_vfx_check.tscn](../scenes/battle_demo/skill_vfx_check.tscn) | failures=0；护盾出手一次、暂停倍速、回收与收尾 | vfx |
| E12 | [battle_ui_check.tscn](../scenes/battle_demo/battle_ui_check.tscn)，`--deployment-check` | failures=0；侧视投影、角色详情、背包装卸转移、存档、战中只读 | ui |
| E13 | 探索，`--random-check`，图形 | **失败**：200 种子生成 197 种地图、146 种奖励序列；40 路径、152 场战斗，8 条失败断言，详见下文 | random |
| E14 | 探索，`--content-check`，图形 | `CONTENT_CHECK_COMPLETE`；装备、共享技能隔离、字符串身份、事件交易、冻结快照、旧档及非法资源拒绝 | content |
| E15 | 探索，`--team-check`，图形 | PASS；地图／战斗面板、换装卸装、候补、阵容保存、只读和 Esc 恢复 | team |
| E16 | 探索，`--pause-flow-smoke`，图形 | PASS；关闭窗口确认取消、主菜单返回、Play 再入及退出动作 | pause-flow |
| E17 | [menu.tscn](../scenes/menu/menu.tscn)，`--codex-check`，图形 | **未通过**：`codex_check.gd:48` 恢复后时间推进断言失败，没有完成标记 | codex |
| E18 | [粉笔精灵任务](art/tasks/chalk-spirit.md)与[概念 001](../design/concepts/chalk-spirit/chalk-spirit/001/chalk_spirit_concept_001.png) | PASS：原始输出已入库；PNG 1254×1254、8-bit RGB、不透明，SHA-256 已记录；仅完成选项与概念候选，未运行或接入 | 静态概念检查 |

E13 的失败均位于 stage=4：seed/path 为 `1/1`、`4/0`、`4/1`、`4/2`；每条各出现胜利及路线完成断言失败。生成合法性部分没有报告失败，但后半段待选奖励磁盘恢复验证因提前退出未执行。检查固定阵容、奖励偏好且不尝试重配，因此不能推导“这些种子无解”；也不能以旧 PASS 覆盖当前失败。需区分平衡、战斗回归和测试策略过期。

E17 代码在 `_enter_node()` 清空部署后直接 `_start()`，没有部署四人；当前开战门槛会拒绝，因此该夹具没有真正开始战斗。前面的浏览、关闭和暂停入口断言已走过，但不能证明战斗恢复正确。修复夹具后再判断产品行为；本轮不改测试或游戏代码。

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
| COMBAT-04 | 战斗 | 主线无需刷成长、路线与阵容有策略差异 | 部分实装 | 可理解且公平的难度 | [random_checks.gd](../scenes/expedition/random_checks.gd) | [设计](game-design.md) | E13 失败 | 有通关样本，随机样本未全通过；无真人平衡数据 |
| DEPLOY-01 | 部署 | 卡片点选、预览确认、拖拽、交换撤回 | 已验证 | 快速调整阵容 | [deployment_panel.gd](../scenes/battle_demo/deployment_panel.gd) | [战斗](battle-demo.md) | E03、E12 | 新遭遇清空；未确认手势不保存；触控待验 |
| DEPLOY-02 | 部署 | 地图／战前队伍面板和候补轮换 | 已验证 | 角色与装备构筑 | [visual_team_panel.gd](../scenes/team/visual_team_panel.gd) | [校园](campus-demo.md) | E15、E04 | 战中只读；地图站位进入新战斗会清空 |
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
| SAVE-01 | 存档 | 节点续玩、战报奖励恢复、成长任务共存 | 已验证 | 可安全中断 | [run_checkpoint.gd](../game/run/run_checkpoint.gd)、[meta_hub.gd](../scenes/expedition/meta_hub.gd) | [校园](campus-demo.md)、[录入](content-authoring.md) | E03–E05、E14 | profile v3／checkpoint schema 1／run schema 5；半场不恢复 HP |
| SAVE-02 | 存档 | 旧档迁移、拒绝坏档、交易回滚与幂等结算 | 已验证 | 防重复领取和存档损坏 | [campus_progress.gd](../game/meta/campus_progress.gd)、[short_run.gd](../game/run/short_run.gd) | [录入](content-authoring.md) | E05、E07、E14 | 有限夹具；非断电故障注入；普通局内操作失败仅提示，不全量回滚内存 |
| UI-01 | 界面 | 暂停、倍速、菜单往返、确认退出 | 已验证 | 控制节奏与离开 | [battle_demo.gd](../scenes/battle_demo/battle_demo.gd)、[meta_hub.gd](../scenes/expedition/meta_hub.gd) | [战斗](battle-demo.md) | E02、E09、E16 | 实测 Windows；网页关闭逻辑未实测 |
| UI-02 | 界面 | 侧视战场、悬停摘要、点击详情与共享图标 | 已验证 | 减少遮挡与信息查找 | [battle_board.gd](../scenes/battle_demo/battle_board.gd)、[battle_inspector.gd](../scenes/battle_demo/battle_inspector.gd)、[object_icon.gd](../scenes/team/object_icon.gd) | [战斗](battle-demo.md) | E12 | 技术交互通过；本轮无人工多尺寸视觉复核 |
| UI-03 | 界面 | 五类校园图鉴与菜单／暂停入口 | 已实装 | 规则查询 | [codex_panel.gd](../scenes/codex/codex_panel.gd)、[codex_catalog.gd](../game/codex/codex_catalog.gd) | [校园](campus-demo.md) | E17 未通过 | 夹具漏部署；完整战斗恢复待验；条目总数旧文档过期风险 |
| UI-04 | 界面 | 模板设置、音量与显示设置 | 已实装 | 基础偏好控制 | [menu.gd](../scenes/menu/menu.gd)、[ggt-core](../addons/ggt-core/) | [设计](game-design.md) | 静态 | 未逐项运行；存在音量设置不代表已接游戏音频 |
| CONTENT-01 | 内容 | Resource 录入、校验、预览并进入探索 | 已验证 | 低代码扩充内容 | [content_db.gd](../game/content/content_db.gd)、[content_preview.tscn](../scenes/content/content_preview.tscn) | [录入](content-authoring.md) | E14 | 扩展已有机制无需分支，新机制仍需代码；未手动逐模式复验预览 UI |
| CONTENT-02 | 内容 | 当前虚构角色、敌人、地点和事件样本 | 原型 | 足够验证短局 | [manifest.tres](../resources/content/manifest.tres) | [录入](content-authoring.md) | 静态、E14 | 注册 6 人物、7 敌人、5 技能、3 敌群、3 装备、9 奖励、1 池、3 事件、9 地点；注册数非每局出现数 |
| CONTENT-03 | 内容 | 真实同学、回忆、校园恢复与结局内容 | 仅设计 | 纪念主题落地 | 无；[设计](game-design.md) | [设计](game-design.md) | 无 | 尚以虚构内容验证；具体身份素材未确定 |
| ART-01 | 美术 | 同步动作、受击与退场回退 | 已验证 | 看懂行动结果 | [unit_presentation.gd](../scenes/battle_demo/unit_presentation.gd)、[battle_animation.gd](../scenes/battle_demo/battle_animation.gd) | [动画](battle-animation.md) | E09–E11 | 未配动画仍回退旧图；无骨骼后端 |
| ART-02 | 美术 | 两名绘制角色、护盾特效、三张战斗背景 | 部分实装 | 主要战斗视觉样本 | [资产登记](../assets/art/asset_manifest.yaml)、[locations](../resources/content/locations/) | [动画](battle-animation.md)、[工作流](art/WORKFLOW.md) | E10–E12、E18 | 六项已接入资产均为 review、获试接入授权且未最终视觉批准；其余角色／敌人仍占位，粉笔精灵只有概念待评且未接入 |
| ART-03 | 美术 | 动作预览与切帧生产工具 | 已实装 | 降低后续动画试错 | [motion_preview.tscn](../scenes/battle_demo/motion_preview.tscn)、[build_battle_frames.py](../tools/art/build_battle_frames.py) | [动画](battle-animation.md) | 历史摘要；本轮静态 | 本轮未重跑七模式工具检查；不当作玩家内容 |
| ART-04 | 美术 | 分阶段人工评审、版本与登记工作流 | 部分实装 | 资产可追溯 | [工作流](art/WORKFLOW.md)、[粉笔精灵任务](art/tasks/chalk-spirit.md)、[资产登记](../assets/art/asset_manifest.yaml) | [工作流](art/WORKFLOW.md) | E18 | 已用新任务完成优先项选择、概念 001、版本／来源／技术记录；概念仍待人工评审，资产与接入阶段未开始，完整三阶段流程未走通 |
| AUDIO-01 | 音频 | 战斗命中、技能与环境声音 | 仅设计 | 战斗反馈与气氛 | [pixel_battle.gd](../scenes/battle_demo/pixel_battle.gd) 仅发事件 | [动画](battle-animation.md)、[设计](game-design.md) | 静态检索 | 未发现游戏音频消费者；模板音量不是声音内容 |
| RELEASE-01 | 发布 | Web 构建与 Pages 自动发布配置 | 已实装 | 可分发入口 | [build-web.ps1](../build-web.ps1)、[push-export.yml](../.github/workflows/push-export.yml) | [发布](web-publishing.md) | 配置与 9/7 正式记录 | 旧版曾本地导出浏览；当前 HEAD 与线上未复验，未触发部署 |
| RELEASE-02 | 发布 | 当前版本桌面／浏览器／手机可用性 | 待核验 | 真实设备可玩 | [export_presets.cfg](../export_presets.cfg) | [发布](web-publishing.md) | 当前原生专项＋旧版浏览记录 | 非当前导出包验收；触控、字体、刷新存档、性能未知 |
| CORE-04 | 兼容 | 旧固定站桩与固定内容主路径 | 已替代 | 保留旧档兼容价值 | [short_run.gd](../game/run/short_run.gd)、[gameplay.gd](../scenes/gameplay/gameplay.gd) | [录入](content-authoring.md) | 静态、E04、E14 | 旧 STAGES／算法保留兼容；新内容进入 Resource；不要删除迁移依赖 |

## 5. 已形成的能力组合

1. **构筑—战斗—回报**：部署、装备、自动移动和技能、有效贡献统计、恢复与重试、奖励接在同一条短局中；不需要另造战斗或奖励框架。
2. **可中断的探索**：随机内容与检查点、统一档案、基地往返和幂等结算组合；恢复的是节点状态，不是逐帧战斗。
3. **基地资源循环**：通关收入、升级、新局能力快照、多人离线派遣形成回流；现阶段回报主要是数值与功能解锁。
4. **内容生产到实战**：资源注册和校验、事件与奖励快照、角色技能实例隔离、战斗与队伍共用显示；工具和存档边界已有基础。
5. **动画集成样本**：两名真实图集角色、动作时序、技能特效、地点背景和详情交互已组合；全队美术一致性与审批尚不完整。

## 6. 系统断点、依赖与冲突

### 核心流程阻塞与验收缺口

- 没有证据显示所有短局都被硬阻塞；已知验收红项是 E13 随机通关样本和 E17 图鉴战斗恢复夹具。前者不能直接归因为数值，后者不能当作玩家暂停损坏。
- 纪念主线的“为什么出发—发生了什么—恢复了什么”未闭合，通关目前主要得到资源。
- 地图编队可保存，但进入新遭遇清空阵型；此为当前明确行为，不是丢档。是否增加复用部署需要体验判断，不能在状态盘点中擅改规则。

### 体验质量与内容不足

- 缺陌生玩家教学、可核对的失败解释和实际局长数据。现有贡献统计不能证明玩家理解目标选择；无限重试也不能替代合理难度。
- 随机地点、奖励已有，但敌群和装备组合有限；重复刷相同内容可能只改变数值。没有商店不构成当前短局硬缺陷。
- 派遣有完整操作反馈，但标签未产生实质要求，收益未映射为校园恢复展示；不宜仅按脚本可配置性宣称玩法深度。
- 六项已接入美术为待评版本；角色完成度混合。粉笔精灵另有概念 001 待评，尚非正式资产且未接入。背景只显式覆盖部分地点，不能把三张图说成全校园完成。

### 技术债与重复边界

- 实际入口继承链为 `meta_hub → expedition → pixel_battle → battle_demo`；存档钩子、战斗和画面复用有效，但场景职责较集中。增量拆分应围绕变更痛点，不重建一套平行框架。
- 两套地图：局内地点 Resource 与局外 `MetaCatalog.LOCATIONS` 职责不同，同名 library 不代表同一状态或同一地图；未来关联需要明确映射，不直接合并 ID。
- 队伍面板与战场详情是两种入口，共用装备模型和图标。修一处必须回归另一处，避免建立第二份归属数据。
- 存档三层版本号各有含义；兼容旧固定内容和当前 Resource 快照并存。基础角色／装备／技能数值读当前资源，不能宣称整局全部数据不可变。
- 交易回滚与普通局内保存不同：购买、派遣、结算检查覆盖失败回滚；普通选路、换装等先改内存再保存，失败提示不等于回滚整个 Run。故障恢复策略需按操作分清。
- 证据在忽略缓存且部分旧检查落后于空场部署规则；仅有脚本或旧 PASS 不构成持续回归体系。

### 正式文档冲突与建议归属

本轮不大规模改写主题文档；下列现行判断来自代码，后续在原文标明历史版本或修正过期段落，不在 Roadmap 再维护规则。

| 冲突 | 当前判断 | 建议处理 |
| --- | --- | --- |
| game-design 第 13/16/17 节称模板／固定站桩／无续玩；后续追加节已演进 | Play 已进入完整短局；可移动战斗、续玩和 Resource 均存在 | 保留设计提案，历史进展标日期；当前状态只链接本索引 |
| battle-demo 开头称上下对阵、无角色美术，且 Play 进入实验室 | 当前左右对阵、两绘制角色；Play 进入探索 | 修正导言和启动说明；保留实验室不存档的边界 |
| campus-demo 写 profile v2、单人派遣；campus-map 写 v3 多人 | profile v3，多人任务兼容旧单人 | 派遣以 campus-map 为规则源，校园只保留流程摘要 |
| campus-demo／game-design 写 run schema 2、七奖励；录入文档支持新快照 | run schema 5；当前注册 9 奖励，非每次全部可抽 | 版本兼容归录入文档，减少重复数字 |
| content-authoring 目标描述仍有固定前排／正交相邻用语 | 实际按空间射程与邻近目标；battle-demo 较新 | 在内容录入目标说明引用现行战斗规则，核对资源自然语言 |
| game-design 撤离保留资源提案，与新局确认不同 | 返回基地仅保存；替换新局丢弃未结算收入；没有独立带收益撤离 | 区分已确认规则和提案，另行判断是否值得实现 |
| web-publishing 称不支持刷新续玩；当前已有本地节点存档 | 原生恢复通过，浏览器持久化尚未本轮验证 | 不能照旧断言不支持，也不能直接承诺浏览器恢复 |
| 摘要称原图加载必然导致导出不可用 | 当前有导出 load 分支 | 当前导出验证后再决定是否修复；勿仅因警告建任务 |

### 平台与发布风险

9/7 本地 Web 记录不能证明 9/14 新资源、部署和存档可发布；也不能说项目从未导出过。模板项目名／版本仍在 project.godot。线上状态未查询，手机小屏和触控没有当前证据。音频、浏览器后台行为、存档空间限制、切页及刷新恢复均需目标包验证。

## 7. 集中待核验清单

- E13 失败的可复现战况、是否可通过调整赢回、是否符合主线易通关目标；修复或明确调整旧测试预期后再验。
- E17 补全真实部署前置后，图鉴进入／退出是否确实保持战斗暂停状态。
- 当前导出资源完整性、中文字体、桌面及浏览器全流程、刷新／重开存档、真机触控；线上 CI／Pages 结果未检查。
- 陌生玩家能否首次完成部署，重复空场是否繁琐，战斗取舍是否可理解；20～30 分钟仍是体验目标，不是测量结果。
- 非正常关闭／磁盘失败时普通局内操作的一致性，系统时钟跳变的派遣行为；不以现有夹具保证任意异常安全。
- 动作预览工具各模式当前完整行为、设置逐项效果、最终视觉审查与资产版本批准；未覆盖项目继续保留边界，不当作下一里程碑已完成基础。
