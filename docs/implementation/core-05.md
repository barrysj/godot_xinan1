# CORE-05 · 原主线羁绊、破解与战后强化

- 状态：已接入校园主线；桌面工程验证通过；数值和真人趣味性待验。
- 当前玩家入口：原主菜单 → 校园流程 → 胜利战报 → 战利品。
- 规则事实源：[战斗文档](../battle-demo.md#原主线战斗接入)。内容录入：[内容录入](../content-authoring.md#主线羁绊与代码资源接入)。

## 实现入口

- 模拟规则：`game/combat/synergy_simulation.gd`、`code_battle_simulation.gd`；沿用原 BattleSimulation 的结算、伤害和事件时序。
- 原战斗操作：`scenes/battle_demo/code_panel.tscn` 与 `code_panel.gd`；代码掉落与收集：`code_fx.gd`、`code_sockets.gd`。
- 战后奖励进入校园既有 `RewardCatalog`、`ShortRun`、`campaign_hub` 与 `campaign_panel`。八种强化保存在当前构筑，角色选择类奖励有独立选择页。
- 定义使用 `resources/combat/` 下已校验的人物标签、羁绊、奖励和代码 Resource；共享目录在 `game/combat/combat_content_catalog.gd`，校验在 `game/content/combat_content_check.tscn`。旧独立试炼入口和专属代码已移除。

## 验证与交付

2026-09-24，基线 `b4b091e` 加奖励接入工作树；PowerShell 7 / Godot 4.7.2 Windows。

2026-09-24，共享资源改名基线 `b8ff16d`，清理基线 `f44cdf4` 加当前工作树；PowerShell 7 / Godot 4.7.2 Windows。改名后 `-CodeCheck` 35/0、`-CodeCapture` 37/0；校园流程 124/0、短局 smoke PASS；代码规则 47/0、羁绊 69/0、共享内容 40/0。截图重新生成于 `.godot/main-code-rewards.png`。旧独立试炼专属文件已清理，清理后复测结果见下。

清理后 Godot 编辑器无脚本解析错误；`-CodeCapture` 37/0、校园流程 124/0、短局 smoke PASS、代码规则 47/0、羁绊 69/0、共享内容 40/0。主线之外的旧三战回归入口随专属场景删除，不再作为当前验收。

- `pwsh.exe -File ./run-battle-demo.ps1 -EnginePath <Godot 4.7.2 console> -CodeCheck`：`MAIN_CODE_CHECK checks=35 failures=0`，覆盖六种强化候选、应用和去重，程序／道具、绑定效果、构筑 schema 7 与 schema 5 迁移、对象选择检查点、真实战斗胜利及库存提交。
- 同命令 `-CodeCapture`：`MAIN_CODE_CHECK checks=37 failures=0`，截图实际原校园战后混合奖励卡、强化对象选择页、终端与战斗。截图位于 `.godot/main-code-rewards.png`、`main-code-reward-owner.png`、`main-code-terminal-1920x1080.png` 和 `main-code-battle.png`。
- `expedition.tscn -- --campaign-flow-check`：`CAMPAIGN_FLOW checks=124 failures=0`；`expedition.tscn -- --run-smoke`：原短局三路线、奖励、恢复及暂停流程 PASS。
- `game/combat/code_rules_check.tscn`：`CODE_CHECK checks=47 failures=0`；`synergy_check.tscn`：`SYNERGY_CHECK checks=69 failures=0`；`game/content/combat_content_check.tscn`：`COMBAT_CONTENT_CHECK checks=40 failures=0`。共享校验只覆盖当前主线定义；旧三战校验用例已移除。
- 原 M1 区域流程、随机路线、暂停、部署、内容和图鉴入口沿用 E32 回归，不代表本次重新证明手机、手柄或导出。
- 2026-09-24，基线 `d8efeb2` 加当前工作树：战役模式恢复粉笔精灵混合动画，主线原场景直接创建并驱动表现场景；`campaign_animation_check.tscn` 7/0、图形截图 8/0，校园流程 124/0、短局 smoke 和代码检查 35/0。动画资源未修改，视觉接入评审仍见 ART-02。

## 当前边界

2026-09-25，演出基线 1e4d4f6（终端交互已由下述平铺 HUD 替代）：code_fx / hack_burst 播放 2.2 秒代码汇聚、反向程序环、数据射线、地面扩散波与程序标记。断链／重定向／修复／接管分别采用红／蓝／绿／紫，修复与断链的目标光束只读取模拟器新增的 affected_ids，待下一次维护生效的程序不伪装成立即伤害。HUD 提供“简化特效”，本场景内保留选择。特效时钟冻结跟随暂停，演出不改逻辑时间、生命和库存。

验证（Godot 4.7.2 Windows）：hack_feedback_check.tscn -- --capture --frames 为 39 checks / 0 failures，覆盖四种程序实际按钮点击、关窗、真实效果目标、暂停恢复、纯表现不改状态、结束清理、三种桌面尺寸与简化模式；44 帧接管演出在固定战况下采样为 GIF。code_integration_check.tscn 为 36/0，原程序／道具／奖励／存档／胜利流程通过；code_rules_check.tscn 为 47/0。截图及 GIF 在 design/concepts/battlefield-redesign/review/codex-workflow/hack-*。环境仍有证书库访问提示及原有 atlas 直接读图警告，无本次脚本或绘制错误。旧 deployment_check 入口失配边界见 UI-02。

待统筹：B 战场与破解演出已原生接入现有主线表现，概念选用获批准，最终实机效果待用户评审；未增加音效、未测手机及导出。

六项试炼强化已接入校园原战利品候选池，与原奖励共同抽取；每项强化每局限领一次。角色专属奖励仅在对应人物已进入本局队伍或候补名单时出现，角色培养类奖励进入对象选择页，装备受原有单件装备规则限制。奖励数量、出现率和强度尚待真人试玩调整；历史活动存档保留原队伍，分析员仅加入新局候补。移动设备、手柄和导出未验。

独立试炼主菜单入口、专属场景、短局存档模型和启动脚本已移除，规则与回归入口统一在 `game/combat/`。共享的 `resources/combat/` 定义、`combat_content_catalog.gd` 与内容校验流程继续由主线使用。


## 平铺破解与悬停暂停

2026-09-25，基线 `1643e54` 加本次工作树。状态：已接入原校园战斗，桌面运行及截图验证通过。

- `code_panel.gd` 移除原二级终端，两个装配程序平铺顶部，消耗以共享资源图标和数量呈现，区别形状与颜色，类型名称在悬停提示中保留；合法且资源足够才高亮。左侧道具常态仅显示图标和剩余次数；点击后展开效果、类型选择及使用按钮。资源不足或无次数可查看原因。
- `code_action_icon.gd` 复用破解演出的图形；`code_type_picker.gd` 为内联颜色选择。原战前程序装配、库存与存档规则保持同一入口。
- `pixel_battle.gd`、`expedition.gd` 通过独立 hover 状态冻结战斗及局内计时，不覆写手动 paused。图标、消耗说明、类型按钮属于完整悬停区域；鼠标离窗、离开战斗后解除临时暂停。`code_fx.gd` 道具粒子继续在 UI 内收集，战场演出随悬停冻结，离开恢复。
- 验证命令（PowerShell 7，Godot 4.7.2 console）：`& <Godot> --path . --quit-after 1200 res://scenes/battle_demo/code_hud_check.tscn -- --capture`，39 checks / 0 failures，覆盖真实鼠标输入、模拟暂停恢复、手动暂停保护、禁用按钮悬停、道具次数与资源、UI 收集、破解演出暂停及 1920×1080／2560×1440／1920×1200 实机截图。截图 `.godot/code-hud-<宽>x<高>.png`。
- 同引擎加 `--headless` 分别运行 `code_integration_check.tscn` 36/0、`hack_feedback_check.tscn` 32/0。覆盖真实点击补给／转码／破解、胜利库存提交与重试检查点、四种演出目标与清理。
- 待统筹：玩家操作从二级终端变为平铺 HUD；不改变战斗规则或奖励池。鼠标桌面验证完成，触屏和手柄专用暂停交互未验；本场景特效简化开关未持久化。原证书库和 atlas 读图警告仍存在，无本次脚本错误。

2026-09-25，图标化修订：code_resource_glyph.gd 为库存格、破解配方、道具类型和投入／产出预览提供统一的四色轮廓；code_resource_chip.gd 与 code_resource_button.gd 替换原文字标签。图标旁只保留数量与正负方向，颜色之外仍可凭形状辨认。原模拟及悬停暂停规则不变。验证：code_hud_check.tscn -- --capture 43/0（含三种尺寸实机截图），主线集成 `code_integration_check.tscn` 36/0、破解演出 `hack_feedback_check.tscn` 32/0 均通过。

2026-09-25，道具详情交互：点击图标选择一个道具，展开相邻详情中的效果说明、资源投入／产出、类型选择、状态与「使用」；再次点击收起，选择另一道具直接切换。未选中时无法使用，使用成功自动收起。列表图标与展开详情均保留悬停暂停。验证基线 `f068ccf` 加本次工作树：`code_hud_check.tscn -- --capture` 52/0（常态及展开态各三种桌面截图），`code_integration_check.tscn` 38/0（原主线真实点击、道具消耗及结算），`hack_feedback_check.tscn` 32/0（破解演出）。触屏／手柄交互仍未验。

2026-09-25，合并验证（`main` 基线 `f8117d4` + `codex/combat-cost-icons` 的 `305204a`）：原战斗 HUD 图形捕获 52/0（收起、展开两态，各三种桌面尺寸），原主线代码集成 38/0，破解演出 32/0，完整战役 124/0；资源台 33 项通过。合并后的 Manifest 扫描 31 个对象／616 个文件，缺失 0、不一致 0、错误 0。三处冲突保留双方美术条目和历史验证记录。

2026-09-26，程序预览交互，基线 `e093c96` + `codex/program-preview` 工作树：程序图标悬停或点按仅打开贴附的半透明详情；详情显示效果、可释放状态与「释放」按钮，资源不足时可查看而不可释放。鼠标离开临时详情恢复战斗；点击／触屏点按固定详情与暂停，点击外侧关闭；释放成功收起。程序图标不再直接施放。原道具详情、规则、库存与特效均复用。

验证（PowerShell 7，Godot 4.7.2 Windows）：`code_hud_check.tscn -- --capture` 62/0，含悬停、真实点击、触屏事件、手动暂停保护、资源不足与三种桌面尺寸实际截图 `.godot/code-program-preview-<宽>x<高>.png`；`code_integration_check.tscn` 39/0，原主线真实点击两步释放与道具／胜利流程；`hack_feedback_check.tscn` 36/0，四种程序演出和暂停冻结。待统筹：触屏事件有自动化覆盖，手机实体与导出尚未验证；本次未改战斗模拟规则。

## 双流派数值设计（2026-10-01）

- 状态：七人物、两羁绊、三程序、七敌人/三敌阵、道具与八强化已形成v0.2提案，尚未实现或实机平衡验证。
- 规则入口：[战斗文档数值提案](../battle-demo.md)，数值仅维护于该文档。
- 验证基线：93d9c3c；2026-10-01，PowerShell 7，git diff --check及JS/PowerShell纸面产码、DPS、供盾上界和反馈算式检查。无运行画面改动，无需截图；旧工程测试不代表新方案通过。
- 已知边界：追击状态链、护盾吸收产码/爆炸、敌人预警待原主线接入；首发和战斗时长为目标。
- 待统筹：提案仅启用两个新标签，测试配置关闭旧全局维护脉冲；涉及内容与未来存档迁移，未改全局总览或Roadmap。

- v0.2补充：使用card-game与roguelike的资源/成长设计方法，修订普通供盾、验证机会刷新、通用修复、敌方生命预算，并给出时间账本、奖励权重/保底、原主线成型路径及验收标准。仍为设计交付，不新增运行能力。

## 双流派第一阶段接入（2026-10-07）

- 状态：原主线模拟器已实装漏洞验证/确认/暴露追击、吸收产紫、反冲盾耗尽/到期爆炸、程序独立冷却与通用修复、道具每场限制、三类敌人预警。成长池及完整美术覆盖继续实施，未声称全目标完成。
- 实现入口：code_battle_simulation.gd、battle_simulation.gd来源护盾结束钩子、原code_panel.gd目标/支付预览、code_fx.gd真实状态显示；规则和角色/敌人数据仍来自共享Resource。旧提权ID仅在旧存档载入时映射到反冲，未建平行存档。
- 验证基线：2eaa397加codex/combat-campus-integration工作树；Godot4.7.2/PowerShell7。chain_check.tscn为36/0，覆盖验证再触发、追击不递归、致死破盾与到期去重、余量、支付原子性、道具限制、schema7迁移和真实整场。chain_integration_check.tscn为8/0，使用原expedition入口/面板；图形模式8/0并捕获.godot/chain-main-battle.png。action_check PASS，accuracy_check51/0。
- 实际巡逻样本（无成长、固定布阵、够资源即放）：漏洞队27.8秒胜利/首发10.2秒/2次；护盾队47.2秒胜利/首发9.2秒/4次；混合队31秒失败。是固定样本，不代表真人难度或完整81配置通过。护盾队减员后清场偏慢待调。
- 已知边界：旧code_rules_check/synergy_check仍含被替代机制的期望，需迁至新基线；本次新检查不能宣称旧所有回归通过。八项强化中新增两项与奖励成型/权重尚未接入。校园美术整合在后续阶段核验。
- 待统筹：运行规则已从旧六羁绊/维护系统变为两个标签链及可预警敌人；未更新高层总览。原有图集直接读图警告仍需随占位美术替换清理。

## 双流派设计细化与数值诊断（2026-10-07）

- 状态：v0.3首版设计已细化，基线模拟与敏感性对照完成；新成长预算/成型保底/完整真人平衡仍待实施或验证。本次不改运行资源。
- 规则与数值只维护于[战斗文档v0.3](../battle-demo.md#双流派设计细化-v032026-10-07)；原始实验记录为docs/research/combat-balance-evidence.json。不得将临时造队当成真实新档已成型。
- 验证基线b55139d，Godot4.7.2/PowerShell7，0.05秒逻辑步；81配置基线+45布阵/生命+27预警+39装备+12修复=204次确定性运行，包含重复对照，不是胜率样本。临时原模拟驱动依次运行.godot/balance_design_probe.tscn、balance_design_variants.tscn、balance_design_warning.tscn、balance_design_growth.tscn、balance_design_repair.tscn；最终各日志正常完成，无脚本错误。临时脚本不属于持久化验证入口，参数与结果已保留；下次正式检查需纳入原验证体系。
- 新发现：主线集中训练仍硬编码两项1.15，Resource却为1.10/1.08；盾granted事件含刷新重发量，不能当净新增量；旧鞋/可重复训练与无装备基准须分开。新增两强化注册、贯穿几何及奖励成型仍未完成。
- 待统筹：提出新局装备/训练预算与原存档规则版本边界，未实际迁移或改动高层总览/Roadmap。无运行画面改动，本次仅文档、实验和证据，无新增截图。


## 当前破解规则的局部视觉反馈（2026-10-07，待统筹）

基线4005781。hack_burst.gd直接读取现有程序Resource名称，更新追踪、反冲与单目标热修复的提示；仅围绕affected_ids显示目标标记／护盾／修复，移除大范围遮罩与中央巨型图案。简化模式保留相同对象与语义。程序短提示复用下方战场动态区域，避免盖住人物头部或敌人预警。反冲爆炸按事件半径经同一战场投影绘制，保持真实范围；pixel_battle.gd撤去PIXEL DEMO占位文案，不改变数值、支付或时序。

验证：PowerShell7／Godot4.7.2。hack_feedback_check.tscn迁移到现行三个程序，检查真实原控制器施放、追踪前置、单目标／全体受益、暂停冻结、视觉不改HP／库存和完成清理；GUI -- --capture 37／0，输出三个程序各三尺寸及简化模式实际截图.godot/hack-<程序>-<尺寸>.png；已查看1920×1080与1920×1200。chain_integration_check.tscn -- --capture为8／0，使用原主线战斗及目标／支付界面。旧提权不再作为生效程序测试；其他尚未迁移的旧规则检查不能据此宣称全部通过。

边界：本次仅程序绘制与原图标调整，无新位图或资产版本。人物五套批准动画保持原资源，部分人物和敌人仍是占位，广播透明候选等待人工资产评审；接入整体视觉和真人读性尚未验收。待统筹：新版破解反馈进入原流程，总览／Roadmap未改。

## 八项强化与训练执行一致性（待统筹）

- 状态：八项强化已进入原RewardCatalog与校园战后候选池；集中训练现读取Resource倍率。新局装备／训练份数预算、三槽权重、流派成型与招募展示保底仍待实施，不能将登记候选等同于已保证成型。
- 实现入口：scenes/expedition/expedition.gd、campaign_panel.gd；resources/combat/rewards/buffer.tres、isolation.tres及manifest.tres；game/content/combat_reward_def.gd／combat_content_validator.gd；game/combat/code_battle_simulation.gd。程序类通过Resource显式注册目标及加法增益，解释器当前仅支持反冲；旧固定训练、装备和局外加成顺序保留，规则只在battle-demo.md维护。
- 验证日期2026-10-07，基线f8fcf6a加工作树，PowerShell7／Godot4.7.2：combat_growth_check.tscn无头38／0，图形-- --capture为44／0；实际鼠标点击原战利品、训练对象按钮，检查原checkpoint恢复、领取去重、候补归属、旧训练／装备／局外叠加与重建不重复。独立使用原模拟器对照基础、缓冲、隔离、两项组合，核验盾量／支付、到期时间、真实爆炸与空盾不产码。图形输出奖励／对象页三尺寸.godot/combat-growth-<页面>-<尺寸>.png；已目视1080与1200，移除空TextureRect占位。
- 资源校验迁移为独立反应夹具，避免依赖已移除羁绊数组及可选空effects；combat_content_check.tscn为46／0，含程序引用与增益非法配置拒绝。chain_check.tscn仍36／0；其他旧检查尚未迁移，不宣称全部通过。原图集直接读图提示与环境根证书提示仍存在。
- 边界：奖励页为隔离的确定性页面夹具，非本次全战役通关或真人趣味性证据；此次未更改原存档schema、普通训练与装备预算。程序奖励未按携带程序过滤、随机成型仍待后续。待统筹：原主线完整强化内容扩至八项，总览／Roadmap未改。

## 贯穿射击空间契约

- 当前状态：已修正并验证。synergy_simulation.gd的贯穿候选改为主目标后方的有限射线段，保留一人、射手真实射程及原稳定选敌规则；零长度射线不生效。资源描述同步，其他数值与代码产出不改。空间数值事实源仍为battle-demo.md。
- 2026-10-07，基线91cc3e9加工作树，PowerShell7／Godot4.7.2：game/combat/pierce_check.tscn无头34／0，图形-- --capture为40／0。使用原CodeBattleSimulation._skill_events核验前后／长度／偏移／射程／边界／多个与等距目标、数组换序、原始伤害比例和不产普攻代码；原expedition场景真实蓄力释放三条弹道，主目标命中后贯穿弹道继续并落到后方目标。accuracy_check51／0、combat_content_check46／0。
- 实际截图.godot/pierce-main-1920x1080.png、2560x1440.png、1920x1200.png，使用原动画、战场与暂停。隔离弹道布阵是规则夹具，不是一次完整真人战斗，也没有改变或批准任何美术资产。修正之前的204次数值实验无此强化成长，不能据此推定所有强化组合平衡。
- 待统筹：站位相关强化现与有限射线设计一致；奖励成型与其他占位美术仍待后续，高层总览未改。

## 新局成长预算与旧局兼容（待统筹）

- 状态：已接入原ShortRun、原校园与短局战斗、战利品／对象页、装备详情及队伍页。规则数值仅维护于battle-demo.md；旧活动局不会中途削减成长。
- 实现入口：game/run/short_run.gd的growth_rules与原schema8；reward_catalog.gd的训练过滤与预览；equipment_def.gd的预算覆盖；expedition.gd／battle_demo.gd的装备读取和属性组装；原装备Resource、battle_inspector.gd及team_panel／visual_team_panel。旧schema1～7载入版本1，新局版本2，写回仍保留本局版本；新预算按基础属性加法，普通与集中训练共享份数上限，固定效果不放大。新局装备不能再与同人战斗装备重叠。
- 验证日期2026-10-07，基线6126c11加工作树，PowerShell7／Godot4.7.2：growth_budget_check.tscn无头38／0、图形-- --capture为47／0；覆盖新局默认、属性取整、两种训练组合／第三份拒绝与对象禁用、候补归属、装备／局外固定值、说明一致、原checkpoint恢复、重建不重复、坏版本和超份数原子拒绝、旧schema1～6迁移、schema7高成长／满普通训练的独立集中训练保留及再次写回。原expedition.tscn -- --campaign-flow-check --order=012为148／0，完整序章、三区域、终局及原结算流程通过；保留旧隔离测试档，未写玩家档。实际训练与对象按钮使用鼠标输入，奖励／对象／原装备详情各三尺寸截图.godot/growth-budget-<页面>-<尺寸>.png。combat_growth_check旧预算夹具38／0；reward_eligibility_check23／0、chain_check36／0。
- 边界：单角色属性与原页面／兼容夹具通过不代表所有强化组合已平衡；旧最高属性尚未整场验收。图形检查发现的动画节点高于装备详情问题已由后续独立修正解决，当前层级验证见ART-03；数值检查不能替代最终美术和真人验收。原图集直接读图提示仍存在。三槽权重／招募保底和真实双流派新档入口仍待实施；高层总览／Roadmap未改。

## 三方向奖励接入（待统筹）

新成长版本的原战后抽取已按链路／通用／变化分槽，第一／第二轮门槛、链先抽和短局适配候补展示使用原检查点字段。实施入口与验证统一见REWARD-01“新局三方向奖励”，规则只见battle-demo.md；不重复数值。校园随机奖励继续不发剧情人物，真实新档启动入口、补给填充与零池继续流程尚未完成。2026-10-07基线42d479c加工作树，reward_slots_check无头22／0、GUI29／0及两页三尺寸；combat_content_check51／0，growth_budget_check无头41／0。总览／Roadmap未改。

### 成长后续接入

原代码补给／转码战后奖励与合法空池继续现已接入；实现与可重复证据统一见REWARD-01“道具补充与合法空池继续”。2026-10-07，基线83437f6加工作树，item_reward_check69／0、GUI78／0，原完整校园GUI149／0。真实双链新档启动、全部成长组合和未完成美术覆盖继续推进，不能用固定基础队全流程替代流派验收。总览／Roadmap未改。

## 两条原出发构筑与可选伙伴（待统筹）

- 状态：原序章、正式区域和终局提供追踪／护盾参考编队，正式出发可沿用原队伍；双新档链路可达性已验证。不是另建试炼，也不意味着所有强化、三敌阵或真人趣味性验收。
- 实现入口：campaign_panel.gd的starting_strategy与原campaign_hub.gd出发／人物／结算动作；ShortRun.configure_starting_strategy、recommended_formation；CampaignState共享合法阵位校验、CampusProgress原事务。原角色候补和程序配置，不新增角色授予或第二存档。
- 发明家未加入的护盾局在正式区域首站增加原人物热点，保留守卫与回忆；真实交谈才加入临时名单，可选“采用编队”。区域成功后永久人物与最终合法编队一起提交。基础分析员可保存为出发成员；未兑现发明家仅保留在活动探索，不进入永久偏好。坏重复阵位／未解锁成员在提交前原子拒绝。
- 2026-10-07，基线aa61309加工作树；PowerShell7／Godot4.7.2：starting_strategy_check.tscn无头109／0，GUI -- --capture为125／0；原expedition.tscn -- --campaign-flow-check --order=012 GUI150／0。两个独立真实新档，各经原序章、教学派遣、首次区域四战、原奖励与永久结算，共10场。无注入人物、代码或道具，局外体能0；核心合法即放，修复按既有阈值，第一项合法奖励。出发、奖励、对象、编队使用真实鼠标；核心仍经原CodePanel预览与释放按钮事件，不宣称全程都是物理鼠标操作。
- 覆盖未知起始方向拒绝、已成长构筑不可重置、选择取消不改档、真实JSON、原检查点恢复、首站交谈与临时伙伴恢复、永久结算阵位、基础分析员保存。GUI原始10场结果保存在docs/research/combat-starting-flow-evidence.json；正式区域首战首次追踪10.2秒、反冲10.8秒。奖励种子取原Journey ID，不是固定抽样或随机胜率。后续不同抽取会改变时间，不能把一次结果当难度保证。
- 三尺寸出发／伙伴／两种实际战斗截图.godot/starting-{choice-analysis,choice-protect,partner,battle-analysis,battle-protect}-<尺寸>.png；1920×1080、2560×1440、1920×1200，已查看出发1080、伙伴1200、反冲战斗1080并在对话展示出发。
- 边界：此时正式区域前三战仍巡逻、末战巨像，教室需要接原节点；序章护盾最小队不含发明家。测试保存隔离档，不改玩家档；手机／导出、真人体验、最高旧成长与全部强化组合未验。敌人与部分人物仍占位，候选资产等待负责人评审。原证书库与图集读图提示存在，无当前脚本错误；高层总览／Roadmap未改。

2026-10-07最终护盾成员说明复测：starting_strategy_check.tscn GUI -- --capture为124／0，三尺寸实际截图已更新；与先前125项的差异来自随机奖励是否进入对象选择页。原10场GUI证据保留原抽取结果，不用本次不同种子覆盖。

## 原路线三敌阵递进（待统筹）

- 状态：新局既有四站使用巡逻、巡逻、教室、巨像，原地区、分岔、探索、领奖与离开门槛保留。实际两条新档出现教室预警及整排释放，非夹具注入；规则数值只维护于battle-demo.md。
- 历史入口：campaign_hub.gd原_guard与Journey schema1的encounter_rules。2026-10-09 已改由站点Resource引用现有敌阵与强度；当前schema2不兼容旧活动探索，默认四站压力保持。最新实现和验证见[CORE-02](core-02.md)与[流程配置](../campus-flow-authoring.md)。
- 2026-10-07，基线30389ff加工作树，PowerShell7／Godot4.7.2；starting_strategy_check无头132／0，GUI -- --capture154／0；完整原expedition.tscn -- --campaign-flow-check --order=012 GUI150／0。覆盖新档序章＋四战、三类实际敌阵、教室真实预警／释放、真实JSON、旧缺字段重新保存与失败重试、未知／小数版本拒绝。所有10场自然产码、无道具／注入；奖励取原随机Journey ID，故不同运行的对象页检查数与时间可变化。
- 教室预警两队各三尺寸实际截图.godot/starting-classroom-warning-<analysis|protect>-<尺寸>.png，已查看并展示护盾1080；出发／伙伴／首战截图也随本次更新。原始GUI10场与预警／释放事件保存于docs/research/combat-route-pressure-evidence.json。原始Vector2由Godot JSON序列化为字符串，不能当成数值数组使用。
- 边界：完整战役回归固定基础队伍，双流派新档只覆盖首个图书馆区域；未验任意奖励／布阵、最高旧成长、手机／导出、真人趣味性或美术审批。旧原图读图／环境证书提示存在，无本次脚本错误；高层总览／Roadmap未改。
