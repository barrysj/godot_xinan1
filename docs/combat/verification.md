# 战斗验证

运行方式见[共用说明](../development/verification.md)。最近联合基线为2026-10-10的7ad0c84同树＋QA修复；这里继承原结果，本次文档整理不重跑全部战斗。

## 规则与构筑

| 场景 | 作用与最近记录 |
| --- | --- |
| game/combat/action_check.tscn、accuracy_check.tscn、auto_battle_check.tscn | 行动／同批命中／寻路基本契约；行动最近整合PASS，旧全量套件仍须按修改范围重跑 |
| game/combat/chain_check.tscn、pierce_check.tscn | 双羁绊与贯穿有限射线；完整强化组合与真人平衡未验 |
| game/content/combat_content_check.tscn | 原主线共享资源注册、引用与基本数值 |
| scenes/battle_demo/combat_growth_check.tscn、growth_budget_check.tscn | 强化归属、成长版本、新旧预算和JSON恢复 |
| scenes/battle_demo/reward_eligibility_check.tscn、reward_slots_check.tscn、item_reward_check.tscn | 合法候选、分槽／候补、道具补充、空池继续；图形加-- --capture |
| scenes/battle_demo/starting_strategy_check.tscn | 原双队新档、可选伙伴、JSON和三敌阵；流程配置后GUI151／0 |

204次确定性调参诊断和两条真实新档链见[平衡研究](research/balance-diagnostics.md)与同目录JSON，不能当作随机胜率。

## 人物与战斗表现

## 合入后人物动画与战斗 HUD 联合验证

2026-10-10，基线本地main `7ad0c84`（当前967301e同树）加QA修复；PowerShell7／Godot4.7.2 console，项目根目录。所有场景使用独立 `.godot` 进度路径，不写玩家档。以下参数均放在 `--path . --quit-after 3000 --log-file .godot/<日志名>.log` 之后；GUI加 `--rendering-method gl_compatibility`，无头加 `--headless`。

| 场景／参数 | 结果 | 日志与覆盖 |
| --- | --- | --- |
| `scenes/battle_demo/authored_assets_check.tscn -- --combat --capture` GUI | 42／0，5包／0失败 | postmerge-authored-combat；原Campaign两场自然教室战斗、两组四人阵容覆盖五人正式帧、攻击／施法推进、恢复、暂停／慢速／倍速、战报隐藏；四张实机图 |
| 同场景 `-- --combat` 无头 | 38／0，5包／0失败 | postmerge-authored-combat-scan；相同核心行为，无截图附加断言 |
| `scenes/battle_demo/status_hud_check.tscn -- --capture` GUI | 105／0 | postmerge-status-fixed；三桌面尺寸、真实意图鼠标／Esc、血盾填充、唯一行动条、图标底色、密集避让 |
| `scenes/battle_demo/battle_feedback_check.tscn -- --capture` GUI | 81／0 | postmerge-feedback-final；三敌阵三尺寸，键盘／鼠标程序与道具、真实预警／释放／恢复，横幅和库存不重叠、预警与日志分行、父子刷新顺序一致、菜单夹具清理 |
| `scenes/battle_demo/feedback_progress_check.tscn -- --capture` GUI | 15／0 | postmerge-battle-progress；真实第三格全亮、收拢／飞码、伤害、暂停冻结、新战满血 |
| `scenes/battle_demo/playback_controls_check.tscn -- --capture` GUI | 51／0 | postmerge-battle-playback；独立暂停／菜单、0.5／1／1.5／2倍速及状态恢复 |
| `scenes/battle_demo/actor_depth_check.tscn -- --capture` GUI | 22／0 | postmerge-battle-depth；三尺寸真实混合／帧角色上下互换、统一脚底排序 |
| `scenes/expedition/screen_cleanup_check.tscn -- --capture` GUI | 52／0 | postmerge-battle-cleanup；战报→领奖→地点及其他原页面，无人物／奖励说明残留 |
| `scenes/battle_demo/cast_vfx_check.tscn` 无头 | 26／0 | postmerge-battle-cast；独立蓄力、释放、音爆环、暂停倍速与消隐 |
| `scenes/battle_demo/animation_check.tscn` 无头 | PASS | postmerge-battle-animation；基础状态／生命周期／时钟 |

静态五人七片段与两合法阵容三分辨率另由原 `authored_assets_check.tscn -- --capture` 验证5包／0失败，日志postmerge-battle-authored。自然两战不强制濒死／死亡来追求状态覆盖，不代表全流程招募或平衡；生命、盾和动作均来自原模拟。最终查看并展示守护／发明家释放与敌人施法预警实机图；所有缓存仍归 `.godot`，无需新美术版本。修改和边界统一见UI-02；ART-02引用该结果。既有环境根证书／Kenney读图警告保留，最终无Script／Parse错误；未重新导出Web或验证触控／实体手柄。

表中的状态、选择页和页面清理结果也供[UI验证](../ui/verification.md)引用。当前支持纯帧和混合后端，不声称最新Web／手机／手柄验收。

## 敌方朝向与 Debug 整备（2026-10-13，待统筹）

基线76b9540加当前修改；原表现层的敌方在整备、移动、出招、死亡与重开时固定朝左，逻辑寻路／技能／弹道方向不变。`scenes/battle_demo/presentation_check.tscn`无头PASS／0失败：10种注册敌人的四逻辑方向、序列帧翻转、混合上下文与节点镜像，以及原不同帧率／速度的模拟结果、事件和暂停一致性。`scenes/battle_demo/deployment_check.tscn -- --deployment-check`无头PASS／0失败，覆盖原手牌与交换保存；必须带隔离标志。Debug直接整备的真实鼠标／键盘、拖动预览朝向、三尺寸与存档隔离结果和入口归[DEV-01](../development/dev-01.md)。截图已展示，仅Windows本地验收。

广播中继素材基准专项（2026-10-13，基线d6cedc0）：原共享镜像规则未区分素材已经朝左，现按BattleAnimationSet声明的基准判断帧／混合／拖动镜像。`scenes/battle_demo/radio_facing_check.tscn`GUI实测镜头位于中心左侧，修复前能明确报错；headless与混合后端契约通过，三桌面尺寸实机已展示。制作工具字段保留与批准边界见[ART-03](../art/art-03.md)。

## 详细结算报告（2026-10-13，待统筹）

基线 `5894923` 加本次工作树；共享实现与统计口径见 [COMBAT-03](combat-03.md)。PowerShell 7／Godot 4.7.2，所有运行使用独立 `.godot` 测试档，不修改真实玩家档。

| 入口 | 结果与覆盖 |
| --- | --- |
| `tools/development/tests/battle-report.test.ps1`，console | 统计33／0，主线49／0，试玩50／0；命中／盾／治疗、真实动作和程序、追击来源、四色转换收支、快照合法性、原保存和重开 |
| 同入口 `-Capture`，GUI | 统计33／0，主线54／0，试玩55／0；1920×1080、2560×1440、1920×1200，真实鼠标／键盘、同类六敌阵位、行完整可见、结束生命冻结、新旧 Campaign／Run JSON、原领奖和整备重开，截图已展示 |
| `tools/development/tests/battle-tuning.test.ps1 -Capture` | 原修改器70／0、直接整备71／0、试玩结束36／0；三项关闭模式各2／0。真实自然胜败、仅两个结束动作、保存失败时数据和可见战报不丢失，两玩家档字节不变 |
| `game/combat/accuracy_check.tscn`、`code_cycle_check.tscn`，console | 命中准确性51／0，产码33／0 |
| `scenes/battle_demo/presentation_check.tscn`、`scenes/expedition/screen_cleanup_check.tscn`，console | 表现时钟PASS／0失败，原战报→领奖→地点清理52／0 |

界面可滚动显示较长程序和同批退场记录，旧报告缺失指标显示未记录；不推断胜负因果。没有改变原伤害／技能规则。仅本地 Windows 源码和桌面图形运行验收，不代表最新发布包、Web、手机或实体手柄通过。
