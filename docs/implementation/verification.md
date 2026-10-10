# 共享验证目录

> 记录来源：2026-09-14 初始统筹与后续 M0 功能验收，整理截至 2026-09-15。此次迁移未重跑测试。功能状态以各功能档案为准；本文件只维护跨功能共用检查入口，避免命令和结果复制多份。
>
> `audit-20260914-*` 为初始盘点日志命名，不能推定同名缓存已包含后来修复的 PASS；M0 结论以原功能提交、正式主题文档与重跑结果为依据。缓存缺失时重新验证，不补造永久证据。

2026-09-15 美术分支合并后的专项重跑另见 [E19](#美术集成验证-e19)，不覆盖未重跑的 M0 和发布结果。

引擎：`F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`。在仓库根目录通过 PowerShell 7 运行：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --log-file .godot/audit-20260914-action.log res://game/combat/action_check.tscn
# 按下表替换场景和参数；用户参数放在 -- 后。
# 图形检查移除 --headless，加 --rendering-method gl_compatibility。
```

探索简称指 [expedition.tscn](../../scenes/expedition/expedition.tscn)；测试进入独立 `.godot/` 档案，未操作玩家 `user://` 存档。图形检查中断或断言失败时不能只看进程退出码，应核对完成标记。

开发难度样本重跑入口（2026-10-09）：`pwsh.exe -NoProfile -File .\run-battle-demo.ps1 -Difficulty Easy/Normal/Hard -Smoke`，其中难度参数每次取一个值。默认使用本工作区候选动画，其他工作区可加 `-Animations Formal`。完成标记为 `DEMO_DIFFICULTY_CHECK result=PASS`；程序检查三档真实战斗、暂停、重试、循环切换及共享资源不变，困难候选还检查三名角色各七个动画状态。图形模式加 `-Capture` 并移除 `-Smoke`；实际像素尺寸检查与本轮结果见 [COMBAT-04](combat-04.md)。

| 证据 | 场景／用户参数 | 最近登记结果与范围 | 日志后缀 |
| --- | --- | --- | --- |
| E01 | [action_check.tscn](../../game/combat/action_check.tscn) | PASS，failures=0；前后摇、死亡取消、弹道、同时结算、高攻速 | action |
| E02 | [auto_battle_check.tscn](../../game/combat/auto_battle_check.tscn) | PASS，failures=0；寻路占位、射程、换目标、暂停倍速 | auto |
| E03 | [deployment_check.tscn](../../scenes/battle_demo/deployment_check.tscn)，`--deployment-check` | PASS，failures=0；真实 Viewport 输入、点击立即部署／换人／换位、部署菜单空白收起、交换来源发光与自身格／右键取消、拖拽、撤回、部分部署恢复与下场沿用 | deploy |
| E04 | 探索，`--run-smoke` | PASS；三条固定兼容路线完成，资源 7/9/7；首战部署、后续沿用、奖励、恢复、续玩、候补、重试、结算 | run |
| E05 | 探索，`--meta-smoke` | 67 checks，failures=0；成长生效时机、迁移、检查点、离线派遣、回滚 | meta |
| E06 | 探索，`--map-check` | PASS；地点浏览、缩放拖动、详情空白关闭、锁定交互 | map |
| E07 | 探索，`--dispatch-check` | 36 checks，failures=0；多人校验、交易、旧任务迁移和 UI | dispatch |
| E08 | 探索，`--journey-check` | 17 checks，failures=0；出发到达、进度、领取、返程与失败回滚 | journey |
| E09 | [presentation_check.tscn](../../scenes/battle_demo/presentation_check.tscn) | PASS，failures=0；插值、动作同步、不同帧率／倍速统计一致 | presentation |
| E10 | [authored_assets_check.tscn](../../scenes/battle_demo/authored_assets_check.tscn)，`--require-two-models` | models=2，failures=0；真实图集与七动作元数据，不是美术审批 | assets |
| E11 | [skill_vfx_check.tscn](../../scenes/battle_demo/skill_vfx_check.tscn) | failures=0；护盾出手一次、暂停倍速、回收与收尾 | vfx |
| E12 | [battle_ui_check.tscn](../../scenes/battle_demo/battle_ui_check.tscn)，`--deployment-check` | failures=0；侧视投影、角色详情、装备弹窗空白关闭与操作后自动关闭、背包装卸转移、存档、战中只读 | ui |
| E13 | 探索，`--random-check`，图形 | PASS：200 种子生成 197 种地图、146 种奖励序列；40 路径、156 场战斗，四次失败均经战报→重配→重试获胜；待选奖励磁盘恢复通过 | random |
| E14 | 探索，`--content-check`，图形 | `CONTENT_CHECK_COMPLETE`；装备、共享技能隔离、字符串身份、事件交易、冻结快照、旧档及非法资源拒绝 | content |
| E15 | 探索，`--team-check`，图形 | PASS；地图／战斗面板、换装卸装、详情空白关闭、候补、阵容保存、只读和 Esc 恢复 | team |
| E16 | 探索，`--pause-flow-smoke`，图形 | PASS；关闭窗口确认取消、主菜单返回、Play 再入及退出动作 | pause-flow |
| E17 | [menu.tscn](../../scenes/menu/menu.tscn)，`--codex-check`，图形 | PASS：35 条图鉴逐项浏览；真实部署四人并开战后，从暂停进入图鉴时状态冻结，Esc 返回暂停，继续后战斗时间恢复推进 | codex |
| E18 | `build-web.ps1` release 包，Codex 应用内浏览器 | PASS（桌面范围）：完整五层路线、暂停恢复、结算与离开；Boss 前刷新恢复；修复后奖励／开战后立刻刷新分别恢复最新地图／同场战前 4/4 阵容。844×390 可进入和点选但文字与确认控件过小 | web |

现行双流派强化专项入口为[combat_growth_check.tscn](../../scenes/battle_demo/combat_growth_check.tscn)，无头核验原构筑／存档与模拟结果，图形-- --capture增加实际奖励／对象按钮输入及三尺寸截图。资源定义另运行[combat_content_check.tscn](../../game/content/combat_content_check.tscn)，基础规则回归运行[chain_check.tscn](../../game/combat/chain_check.tscn)。空间强化专项运行[pierce_check.tscn](../../game/combat/pierce_check.tscn)，图形-- --capture覆盖原场景蓄力、弹道与落点。最新日期、基线、结果和边界统一见[CORE-05](core-05.md#八项强化与训练执行一致性待统筹)；旧提权／维护规则检查不代表现行基线。

E13 原失败均位于 stage=4：seed/path 为 `1/1`、`4/0`、`4/1`、`4/2`。定向枚举证明四条路径无需改变奖励或敌人数值，只需把默认站位中的应援者与冲刺手前后互换即可获胜；根因是旧检查把单一固定站位必胜误当作路线可完成。现检查保留默认站位首战，失败时必须走真实战报、重新部署和重试，再以替代站位获胜；胜利与路线完成断言未删除，且补跑了此前被提前退出遮断的磁盘恢复。该结果不替代真人难度与公平性数据。

E17 原夹具在 `_enter_node()` 清空部署后直接 `_start()`，被四人开战门槛拒绝。现通过实际部署组件依次部署四人，并在打开暂停前断言已进入战斗且时间推进；随后对图鉴冻结、关闭回到暂停及继续恢复逐项断言。原失败属于夹具前置过期，产品暂停／图鉴恢复行为在当前检查范围内正常。

所有引擎运行有根证书存储错误，部分有编辑器原图加载警告；通过项指专项断言通过，不是“引擎零报错”。`pixel_battle.gd::_load_atlas()` 已区分 editor 原图与导出 `load(Texture2D)` 路径，摘要所称“必须修复否则导出不可用”证据不足。M0 当前 Web 包已验证资源加载；其他平台不外推。

## 美术集成验证 E19

- 日期：2026-09-15；基线：main `1a2948e`、粉笔 `b661bad` 与资源台 `c44a862` 的合并树（首个合并提交 `17f7136`，最终合并见 Git 历史）。
- Python：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v`，11 tests PASS；八对象、71 文件，无缺失或哈希不一致。包含真实内容修改的哈希拒绝检查，不更新登记基准。
- Godot：以本文件 `$engine` 命令运行 `game/combat/action_check.tscn`、`scenes/battle_demo/presentation_check.tscn`、`scenes/battle_demo/skill_vfx_check.tscn`、`scenes/battle_demo/deployment_check.tscn -- --deployment-check`；分别出现 ACTION_CHECK、PRESENTATION_CHECK、SKILL_VFX_CHECK、DEPLOYMENT_CHECK 的 `failures=0`。覆盖动作时序、表现同步、粉笔弹体/旧护盾回退及 main 的部署行为。
- 动作：`pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Check -Unit res://resources/content/enemies/chalk.tres -Animation res://assets/art/characters/chalk_spirit/battle_animation.tres`，七种受支持模式 PASS，近战 SKIP，`MOTION_PREVIEW_CHECK failures=0`。
- 渲染：将上述 `-Check` 替换为 `-Capture`，完成 1920×1080、2560×1440、1920×1200，日志有三个 `MOTION_PREVIEW_CAPTURE`；截图为 `.godot/motion-preview-3-<分辨率>.png`。
- 页面：`pwsh.exe -NoProfile -File ./tools/art/asset_manager/run-server.ps1 -Port 8771 -NoOpen` 冷启动成功；8770 同项目验收页显示八对象/71文件/0不一致，实际点击弹体预览启动粉笔 Unit、005 Animation 与001 Projectile，未回退默认对象。截图 `.godot/art-merge-overview.png`、`.godot/art-merge-preview-launch.png` 为本机缓存，不是跨 checkout 唯一证据。
- 修复范围：启动器 v2 健康标识、旧六对象测试假设、登记文本字节被 Git 换行转换的问题；详见 [ART-05](art-05.md)。没有重写哈希或改变资产批准状态。
- 边界：既有原图加载警告及无头环境证书警告仍存在；未重导出 Web、未重新验收全套 M0/手机/真人体验。美术批准继续以任务与 Manifest 为准。

## M1 战役验证 E20

2026-09-16；基线为 `7f92ba8` 起点及 `8140863`、`8918005`、`2a89abe`、`7f95448` 后本文件所在提交。全部使用独立测试档，不覆盖玩家档。引擎路径沿用本页开头，命令显式PowerShell 7。

| 检查入口 | 结果与范围 |
| --- | --- |
| `--headless --path . res://game/meta/campaign_check.tscn` | 103 checks / 0 failures；旧v3迁移、不凭旧通关补终端、六顺序、幂等与写失败回滚 |
| `--headless --path . res://game/run/location_check.tscn` | 134 checks / 0 failures；全部分支、四访问、守卫门槛、可选回忆与不重抽 |
| `--headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012` | 六顺序012/021/102/120/201/210各124 checks / 0 failures；实际16场模拟战斗、报告/奖励/访问恢复、暂停、人物兑现、终局操作边界 |
| 同上去掉`--headless` | 1920×1080、2560×1440、1920×1200图书馆及结尾截图，保存于`.godot/m1-library-*.png`和`m1-ending-*.png`；小屏仍可滚动，不作真机结论 |
| 原`--meta-smoke` / `--dispatch-check` / `--run-smoke` | 67/0、36/0及旧三路线PASS（7/9/7资源）；旧档、派遣、战斗与续玩保留 |
| `game/combat/action_check.tscn` | ACTION_CHECK PASS failures=0；模拟层动作时序未改 |

桌面Web：使用主仓库缓存的4.7.2标准版引擎`E:/Documents/works/godot_xinan1/.godot/web-tools/engine/Godot_v4.7.2-stable_win64_console.exe`导出当前worktree的`builds/web/index.html`成功。新建输出目录后运行`--headless --path . --export-release Web builds/web/index.html`；不要用Mono导出。日志`.godot/m1-web-export.log`。已修复新面板子控件不继承中文字体造成Web方框的问题。

通过本地HTTP 127.0.0.1:8793、Codex应用内浏览器实测：Start→新档序章→真实拖动四人→开战后立即刷新→同场战前4/4恢复；首战胜利11.4秒→待选三奖励→刷新后同三奖励恢复。另在导出HTML副本`m1-check.html`把args设为`["--","--campaign-flow-check"]`，点击Start后独立`user://campaign-flow-test-profile.json`执行整条战役，浏览器控制台`CAMPAIGN_FLOW checks=124 failures=0`并展示结尾。标准Web模板不支持命令行覆盖场景路径，因此副本仍从真实菜单进入。HTML副本位于忽略的builds目录，不是正式入口。

边界：Web全流程检查为程序驱动，真实鼠标只覆盖序章与刷新；不能代替陌生玩家。Android横屏真机、真实照片、正式美术批准和60～90分钟体验均未验收。既有证书/原图警告、导出编辑器缓存权限提示仍在，但本次构建产物与上述完成标记已实际核验。

## M1 可理解性修复 E21

2026-09-16；基线3fb297a，战场a2750bc，路线/热点/反馈为577ad8b。测试使用campaign-flow独立档。

- Godot `--headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：124 checks / 0 failures。
- Godot `--headless --path . res://game/run/location_check.tscn`：134 checks / 0 failures。
- Godot `--path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check --exploration-capture`：102 checks / 0 failures。实际模拟经过图书馆四站，检查报告/奖励恢复，截图基地、路线、图书馆、出口开放与结算；新增断言核对真实像素尺寸1920×1080、2560×1440、1920×1200。缓存.godot/m1-readable-{home,route,library,rewards,opened,settlement}-*.png。
- `--readability-capture`：已有静态idle首帧/头像、目标、战报去向截图，缓存m1-readable-battle/report-*.png；截图不代表人工视觉批准。
- 标准版Godot `--headless --path . --export-release Web builds/web/index.html`导出成功。隔离HTML副本readable-preview.html args为["--","--campaign-flow-check","--exploration-preview"]，启动在教学完成后的测试基地，不覆盖正式玩家档。鼠标已检查图书馆入口、路线前往、热点选中只展开详情、读取保存、回到同地点标记已查看、出口禁用、战前整备、实际胜利、领取奖励后回到同地点并开放出口。
- 校门/步道/球场/走廊采用不同原生几何示意，图书馆为书架与阅读区；真实校园资料、正式背景、Android与陌生玩家验收仍未完成。原图加载和证书警告仍为既有环境问题。

### 混合动画独立验证入口

混合动画新增重跑入口：`res://scenes/battle_demo/hybrid_contract_check.tscn`、`py -3 tools/art/promotion/promote_animation.py chalk_spirit --check`；完整九组合与显式导出矩阵见 ART-03（2026-09-16，56dc3aa＋F 清理树）。

## M1 与美术管线合并验证 E22

2026-09-16；合并输入为M1 `577ad8b`与main `d595f07`，验证合并树为本章节所在提交。冲突仅在integration.md与本文件，保留两方有效内容；运行代码自动合并，没有重写美术资产或批准。

沿用页首PowerShell 7和Godot命令，各项独立日志为`.godot/merge-<检查名>-output.log`：

| 入口 | 本次结果 |
| --- | --- |
| `game/meta/campaign_check.tscn` | 103 checks / 0 failures |
| `game/run/location_check.tscn` | 134 checks / 0 failures |
| 探索场景 `-- --campaign-flow-check` | 124 checks / 0 failures，含三阶段终局 |
| 探索场景 `-- --run-smoke` | RUN_INPUT、RUN_SMOKE通过，旧路线/存档/奖励/重试/暂停 |
| `scenes/battle_demo/hybrid_contract_check.tscn` | failures=0 |
| 同目录 `animation_check.tscn`、`presentation_check.tscn`、`skill_vfx_check.tscn` | 全部PASS或failures=0 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 23 tests OK |
| `py -3 -B tools/art/promotion/promote_animation.py chalk_spirit --check` | PASS，13文件 |
| 图形探索 `-- --campaign-flow-check --exploration-capture` | 102 checks / 0 failures；三尺寸实际像素断言和完整图书馆路线通过，截图m1-readable-*.png |
| 标准版Godot `--headless --path . --export-release Web builds/web/index.html` | 退出码0，合并树本地Web构建成功；本轮未重新执行浏览器全流程 |

本轮未重新检验ART-03的120 Hz姿态等价边界，也未做Android/陌生玩家/时长验收；既有证书、原图及编辑器设置权限警告不作为脚本回归成功的替代证据。E20/E21的浏览器操作记录是此前版本证据。

## Debug 与重开存档 E23

2026-10-10 人物正式收尾（基线667e60e＋工作树）：五人 asset_002 稳定路径、守护者旧 asset_001 保留；225运行PNG与批准稿 SHA 一致，确定性提升五包通过、正式五人资源／0失败、两阵容三尺寸截图、共享特效26／0、ACTION／PRESENTATION／ANIMATION通过。最新实录678模拟步／344事件与已批准候选一致，录像完整解码通过；逐人七态预览及源模型检查通过。最终清理／启动／资源台结果归人物任务和 release-verification.json；旧试验路径已移除。待统筹。

2026-10-09 战斗启动修复（基线 `d269b50` 加功能改动）：`run-battle-demo.ps1 -Mode Debug -Smoke` 为 `DEBUG_BATTLE_CHECK 37 checks / 0 failures`，加 `-Animations Formal` 为 34／0；换成 `-Capture` 为 42／0。检查实际启动状态与原战斗推进、F8、鼠标调难度重开及三尺寸截图，不再由旧检查自行创建战斗。完整校园 `run-debug.ps1 -Check` 169／0，Release `-Smoke` 6／0，原 `-CodeCheck` 39／0。此前启动菜单记录没有覆盖默认进入战斗，当前行为、隔离边界与截图见 [DEV-01](dev-01.md)。

2026-10-09 启动菜单（基线 `63ab01a` 加功能改动）：`pwsh.exe -NoProfile -File .\run-battle-demo.ps1 -Mode Debug -Smoke` 为 169／0，换成 `-Capture` 为 193／0；`-Mode Release -Smoke` 为 6／0，换成 `-Capture` 为主线集成 41／0。Debug 加 `-Animations Formal -Smoke` 为 169／0。无参数菜单只提供 Debug / Release，非法输入重试与退出正常；模式参数冲突拒绝。旧无模式 `-Smoke`、显式 `-Difficulty Hard -Smoke` 及 `-CodeCheck` 兼容检查通过，截图与边界见 [DEV-01](dev-01.md)。

2026-10-09 游戏内难度选项（基线 `6173ad7` 加功能改动）：`run-debug.ps1 -Check` 为 169 checks / 0 failures，`-Capture` 为 193 checks / 0 failures；关闭模式 `--debug-check` 为 6 checks / 0 failures，主线 `--campaign-flow-check` 为 148 checks / 0 failures，原 `run-battle-demo.ps1 -CodeCheck` 为 39 checks / 0 failures。实际点击应用重开、三档与重复应用、构筑／敌阵／存档边界及三尺寸截图见 [DEV-01](dev-01.md)；按下方命令可重跑。

2026-09-17 弹窗修订（基线 `7160568`）：`pwsh.exe -File .\run-debug.ps1 -Capture` 为 71 checks / 0 failures，新增背景可见与遮罩点击不穿透；其余命令语义不变，下表 69 项为此前版本记录。当前截图 `debug-battle-panel.png`、`debug-reward-panel.png` 已更新为居中弹窗。

2026-09-17，基线 main `10dfbcd`，正式重开 `77afbd3`，Debug 为其后的功能提交；使用 Godot 4.7.2 Compatibility、PowerShell 7。实现边界见 [DEV-01](dev-01.md) 与 [SAVE-02](save-02.md)。

| 入口 | 结果与覆盖 |
| --- | --- |
| `pwsh.exe -File .\run-debug.ps1 -Check` | 59 checks / 0 failures，独立 `.godot` 测试档，主线／旧活动局命令和失败回滚 |
| `pwsh.exe -File .\run-debug.ps1 -Capture` | 69 checks / 0 failures，真实鼠标点击角落入口、暂停恢复、三尺寸截图与原菜单不相交 |
| Godot 探索场景 `-- --debug-check`，不带启用参数 | 5 checks / 0 failures，面板不存在且命令拒绝 |
| Godot 探索场景 `-- --profile-reset-check` | 14 checks / 0 failures，取消／清空／备份／坏档恢复／写入失败保留 |
| Godot 探索场景 `-- --campaign-flow-check` | 124 checks / 0 failures，主线正常战斗与结算回归 |

探索场景为 `res://scenes/expedition/expedition.tscn`。日志 `.godot/debug-mode.log`、`debug-disabled.log`、`profile-reset-check.log`、`debug-campaign-regression.log`；实际截图 `.godot/debug-corner-*.png`、`debug-battle-panel.png`、`debug-reward-panel.png`、`debug-home.png`、`profile-reset-confirm.png`。未做 Web／Android 与断电验证；证书和既有像素图导入警告仍存在。

## M1 探索 UI 011 接入验证 E24

2026-09-18；基线为已合并 main `7abef2e` 的 `art/m1-exploration-ui` 工作树，验证提交为本章节所在提交。仅图书馆地点启用 011 正式 UI 资产；其他地点、战斗和永久状态规则未改。全部命令使用 PowerShell 7 与 Godot 4.7.2 Compatibility。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --exploration-capture` | 132 checks / 0 failures；三尺寸真实视口、四热点、鼠标打开详情、Esc 关闭与焦点恢复、人物事件、守卫领奖、离场和检查点恢复 |
| 探索场景 `--headless -- --campaign-flow-check --order=<六顺序>` | 012/021/102/120/201/210 各 124 checks / 0 failures；真实完整战斗、奖励、地点恢复与三阶段终局无回归 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 资源台测试通过；011 候选与正式六图动态哈希一致，Manifest 生效状态可核验 |

实际接入截图位于 `design/concepts/m1-exploration-ui/review/codex-workflow/integration-011/`：三尺寸默认态，以及 1920×1080 详情／出口开放态。已看图确认弹窗未越界、热点不重叠、完成态和离开按钮同步。背景仍为主游戏原生抽象示意；研究参考图、其他对话背景和现实地点身份未纳入资产。技术验证不代替本次接入效果的人工视觉验收。

## M1 图书馆环境接入验证 E25

2026-09-18；基线为 main `4389c1f` 加 `art/m1-asset-integration` 工作树。仅替换图书馆探索页的环境绘制层，不新增昼夜循环、奖励、热点或访问规则；主流程默认 `anomaly / atrium-down`，日常／夜间与其他机位仅作为配置和预览变体。全部命令使用 PowerShell 7 与 Godot 4.7.2 Compatibility。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --library-environment-capture` | 104 checks / 0 failures；真实 M1 图书馆路线、四热点保留，3 状态 × 3 视角 × 1920×1080、2560×1440、1920×1200，共 27 张实际运行截图，逐张断言分辨率 |
| 探索场景 `-- --campaign-flow-check --exploration-capture` | 132 checks / 0 failures；四热点、详情弹窗、人物事件、守卫领奖、出口开放、离开地点、返回基地与三尺寸完整流程 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 资源台回归入口；正式九图、Manifest 映射和登记状态可核验 |
| `git diff --check` | 通过 |

实际截图写入 `.godot/m1-library-environment-*.png`，按状态／视角／分辨率生成 27 张；默认异变流程另由 `.godot/m1-readable-library*.png`、`m1-readable-library-detail*.png`、`m1-readable-opened*.png` 复核。技术检查通过不代替负责人对接入效果的人工视觉验收。运行环境仍有既有 `user://logs`、系统根证书和像素图 `Image.load_from_file` 警告，不影响本轮检查结果。

## M1 图书馆环境游戏内预览验证 E26

2026-09-18；基线为 `db10e7f` 加本轮预览工作树。预览使用临时 Journey，仅验证视觉切换，不写入 `active_run`；状态按钮为日常／夜间／异变，视角按钮为中庭／窗边／书架。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --library-environment-preview --library-environment-preview-capture` | 31 checks / 0 failures；预览页实际创建、3 个状态按钮和 3 个视角按钮实际驱动九种组合、1920×1080 截图尺寸、active run 保持不变 |
| 直接启动 `--library-environment-preview` | 游戏内打开只读“图书馆环境预览”页；“返回基地”回到普通基地页 |
| 调试模式 `--campus-debug` → F8 → “图书馆预览” | 复用同一预览入口；只读、不修改正式主线规则 |

## M1 探索 UI 012 浮窗按钮升级验证 E27

2026-09-18；基线为 `acc731d` 加本轮正式提升工作树。012 仅替换正式浮窗与按钮，四枚热点图标继续使用 011；真实战役改用 NinePatch 保持切角比例，并以同轮廓增亮替代旧规则白色焦点框。热点名称条仍为程序标签，后续视觉方向已记录但未在本次实现。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --exploration-capture` | 132 checks / 0 failures；三尺寸真实视口、四热点、鼠标打开详情、Esc 关闭与焦点恢复、人物事件、守卫领奖、出口开放、离场及检查点恢复 |
| 实际截图检查 | `integration-012/` 三尺寸默认态及 1080p 详情／完成态；面板和按钮切角无拉伸，焦点无额外白框，弹窗未越界 |
| 资源台单元测试与目录扫描 | 33 tests 通过；正式六图与 selected 组合动态哈希一致，0 mismatch / 0 missing / 0 errors |

## M1 探索热点无文字动效验证 E28

2026-09-18；基线为 `8c96a89` 加本轮真实战役改进工作树。013 条带候选不采用，正式图片不变；本轮只移除热点旁名称／Tooltip，并为已批准图标增加错相浮动、呼吸缩放、局部辉光与聚焦弹性反馈。动画作用于绘制层，118×118 按钮节点和焦点链保持固定。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --exploration-capture` | 150 checks / 0 failures；三尺寸真实视口、名称仅在点击详情、无热点 Tooltip、浮动／呼吸随时间变化、四热点错相、命中区在动画期间固定，以及原四热点／弹窗／Esc／人物事件／守卫领奖／离场流程 |
| 实际截图检查 | `interaction-motion/` 包含三尺寸默认态、1080p 详情、1200p 完成态及相隔 0.55 秒的两个真实运动相位；无条带、无热点文字，图标保持可辨且弹窗未越界 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 资源台 33 tests 通过；selected 正式组合保持 matched，013 仅保留为不提升的历史候选 |

实际截图写入 `.godot/m1-library-preview-*.png`，共九张 1920×1080 组合截图。预览页的按钮文案保持短动作名，当前状态显示在按钮组下方；没有把预览状态伪装成游戏内昼夜系统。

## M1 基地首页图标接入验证 E29

2026-09-21；正式资产提升基线 `00a38f8` 加本轮接入工作树。仅修改 M1 基地首页的资源状态与真实功能入口视觉，不改变战役状态、收益或开放规则；学习、队伍、设置、消息、通知因没有对应首页功能而不接入。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `-- --campaign-flow-check --hub-icon-capture` | 61 checks / 0 failures；核对回忆、成长、派遣、图鉴四个原生按钮及资源状态图标均映射 `asset_012_formal`、纹理为 64×64，图标宽度约束为 36；图鉴真实打开并关闭；捕获三种桌面分辨率及成长焦点态；无缓存回退与有缓存导入两条路径均通过 |
| 探索场景 `--headless -- --campaign-flow-check` | 124 checks / 0 failures；完整战役、战斗、奖励、恢复与终局无回归 |
| 探索场景 `--headless -- --meta-smoke` | 67 checks / 0 failures；旧基地、派遣与存档流程无回归 |
| Mono 引擎无导入缓存直接启动 | 修复前稳定出现 `Preload file ...png has no resource loaders` 并令 M1 脚本编译失败；改为运行期导入资源优先、PNG 字节回退后，同一启动命令无 Script Error |
| 标准版 Godot `--headless --path . --export-release Web builds/web/index.html` | release 导出成功；正式包使用已导入纹理路径 |
| 运行时 PNG 检查 | 10 张均为 64×64，透明角 alpha=0；正式 SVG 保留为源，PNG 为确定性运行时派生图 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 资源台 33 tests 通过；批准、正式路径与接入状态可核验 |

实际截图位于 `design/concepts/m1-campus-hub-ui/review/codex-workflow/integration-012/`：三尺寸基地首页与 1080p 成长按钮焦点态。普通入口使用青色边框，键盘焦点使用黄色细框；品红状态点没有烘焙到图标中，且当前无未读状态所以不显示。技术验证不代替负责人对接入效果的人工视觉验收。运行环境仍有既有 `user://logs`、系统根证书及像素图原图加载警告。

## M1 正式 UI 基础与基地骨架验证 E30

2026-09-21；在不修改玩法、存档 schema 或 `CampaignPanel.action(id)` 的前提下，新增日常层共享样式并将 M1 基地首页改为顶部状态栏、左任务、中布景、右功能的响应式容器布局。中部只使用现有终端资产与明确的概念占位提示，未接入未批准的阶梯教室或值班 AI 美术。

| 入口 | 结果与覆盖 |
| --- | --- |
| 探索场景 `--headless -- --campaign-flow-check --order=012` | 124 checks / 0 failures；完整战斗、奖励、恢复与终局无回归 |
| 探索场景 `-- --campaign-flow-check --hub-icon-capture` | 61 checks / 0 failures；三尺寸基地截图、五枚正式图标映射、图鉴开关与焦点态保持有效 |
| 实际截图检查 | 1920×1080、2560×1440、1920×1200 三栏不重叠；首个可操作按钮获得焦点，成长按钮显示黄色焦点边；修复 AI 状态条被压成竖排的问题后重跑通过 |

截图为 `.godot/m1-campus-hub-icons-*.png` 与 `.godot/m1-campus-hub-icons-focus-1920x1080.png`。阶梯教室环境和悬浮屏幕 AI 仍须按美术工作流完成概念、资产与接入审批。

## M1 主菜单异常／恢复背景接入验证 E29

2026-09-21；基线为 `art/m1-main-menu` 的六图正式资产包 `asset_001`。全部命令使用 PowerShell 7 与 Godot 4.7.2 Mono Compatibility；验证入口为 [menu_runtime_check.tscn](../../tools/menu_runtime_check.tscn)。

| 入口 | 结果与覆盖 |
| --- | --- |
| `tools/menu_runtime_check.tscn -- --test-size=1920x1080` | `MENU_CHECK passed`；异常／正常 2 状态、图书馆／品学楼／银杏主楼 6 张背景、6 次轮播推进，截图尺寸 1920×1080 |
| `tools/menu_runtime_check.tscn -- --test-size=1920x1200` | `MENU_CHECK passed`；六张背景与轮播通过，截图尺寸 1920×1200 |
| `tools/menu_runtime_check.tscn -- --test-size=2560x1440` | `MENU_CHECK passed`；六张背景与轮播通过，截图尺寸 2560×1440 |
| `scenes/menu/menu.tscn -- --codex-check` | `CODEX_CHECK entries=35 ... passed`；菜单、图鉴、暂停与战斗恢复回归通过 |

实际截图写入 `.godot/m1-main-menu-<state>-<index>.png`，并已检查异常态数字化湖面／双黑天鹅、正常态湖畔图、标题、按钮与状态提示。根证书读取、旧像素图加载和退出时单个 ObjectDB 泄漏为既有环境／测试边界，不属于本功能失败；不替代 Android、Web、真人体验验收。

## M1 主菜单 4K 背景升级验证 E30

2026-09-21；基线为 `art/main-menu-4k` 的 3840×2160 正式资产包 `asset_002`。Godot 使用线性背景过滤，运行检查新增六张源纹理尺寸断言。

| 入口 | 结果与覆盖 |
| --- | --- |
| `tools/menu_runtime_check.tscn -- --test-size=1920x1080` | `MENU_CHECK passed`；2 状态、6 张 4K 源背景、6 次轮播推进通过 |
| `tools/menu_runtime_check.tscn -- --test-size=1920x1200` | `MENU_CHECK passed`；16:10 裁切与 UI 安全区通过 |
| `tools/menu_runtime_check.tscn -- --test-size=2560x1440` | `MENU_CHECK passed`；用户 2K 目标尺寸实际截图通过 |
| `tools/menu_runtime_check.tscn -- --test-size=3840x2160` | `MENU_CHECK passed`；4K 实际截图通过 |
| `scenes/menu/menu.tscn -- --codex-check` | `CODEX_CHECK entries=35 ... passed`；主菜单、图鉴、暂停与战斗恢复回归通过 |
| `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v` | 资源台 33 tests 通过；Manifest `asset_002` 文件和审批结构可读取 |

截图写入 `.godot/m1-main-menu-<尺寸>-<state>-<index>.png`。质量闸门为 `PASS_WITH_NOTES`：六张达到精确 4K 像素尺寸并保持既有构图约束，但增强细节不视作原生 4K 摄影采样。Godot 仍有既有根证书、旧像素图动态加载和退出泄漏警告，不属于本功能失败。

## 羁绊与破解试炼验证 E30

2026-09-22；基线 `f6b79df` → 共享战斗 `599ea0d` 加本轮试炼工作树。PowerShell 7 / Godot 4.7.2 Windows，详情与已知边界见 [CORE-05](core-05.md)、[COMBAT-02](combat-02.md)。

- 历史独立试炼检查（运行器已退役）：八个入口全部退出0；内容95、效果70、存档76、三战104、表现34、准确性51项均无失败，原动作与自动战斗检查PASS。
- 历史独立试炼截图（运行器已退役）：1600×900真实三战、两次领奖、破解选择、暂停冻结、通关解锁PASS；独立`.godot`存档，截图已查看并在对话展示。
- `pwsh.exe -File ./run-battle-demo.ps1 -Smoke`：两敌阵、四装备归属与倍速一致PASS；探索场景`-- --campaign-flow-check --order=012` 124/0，`-- --run-smoke`三路线与输入／存档／恢复／重试PASS。

存档故障注入有一条预期备份写入错误；根证书及旧Kenney原图加载警告仍存在。没有据此扩展为Web、手机或平衡性验收。

## 四色代码与消耗道具验证 E31

2026-09-22；基线 `fce306c` 加四色代码工作树，PowerShell 7 / Godot 4.7.2 Windows。当前规则见 battle-demo.md，实施入口与边界见 CORE-05。

- 历史独立试炼检查（运行器已退役）：十场景通过，规则最终74/0（最后三项配置类型检查另行重跑）、真实鼠标UI13/0；内容95、效果70、存档76、旧三战104、表现34、准确性51均0失败；动作／自动战斗PASS。
- 历史独立试炼截图（运行器已退役）：真实三战获胜、6次程序、两件道具消耗、暂停冻结与终端视口内断言PASS；截图为 `.godot/trial-code-*.png`，已查看并在对话展示。
- 覆盖普攻按动作产色、护盾命中、漏洞颜色归属、上限、四程序、共享冷却、待执行指令、不可执行操作无扣费、道具转换、v1/v2迁移、v3保存与失败回滚、默认Resource数组不受装配污染。测试使用独立存档。

根证书读取错误与旧图片警告为既有环境边界；故障注入预期出现备份写入失败，不代表脚本失败。脚本运行器额外检查成功标记及SCRIPT ERROR，避免解析失败被误报通过。未覆盖手机、手柄、Web或真人平衡评估。

## 原主线代码战斗验证 E32

2026-09-24；基线 `b4b091e` 加奖励接入工作树，PowerShell 7 / Godot 4.7.2 Windows。直接运行原校园场景的集成夹具：

```powershell
& 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe' --path . --log-file .godot/main-code-final.log res://scenes/battle_demo/code_integration_check.tscn -- --capture --size=1920x1080
```

去掉 capture 并添加 --headless 可做无图形检查；截图仅图形模式。2026-09-24本次图形检查 37 项 / 0失败，无图检查35项 / 0失败。集成覆盖主线奖励池六项强化候选、实际混合奖励卡和强化对象页、程序／道具、真实鼠标道具／转码／提权、暂停退出与取消、真实胜利、schema7及schema5迁移、半场及胜利检查点恢复；日志 `.godot/main-code-integration.log`，截图见 `.godot/main-code-rewards.png`、`main-code-reward-owner.png`、`main-code-terminal-1920x1080.png` 和 `main-code-battle.png`。旧E32图形截图轮次22项 / 0失败为历史证据。

原入口回归：expedition.tscn 的 --campaign-flow-check --order=012 为124/0；--run-smoke 三路线PASS；--pause-flow-smoke PASS；deployment_check.tscn --deployment-check 为0失败。图形运行 expedition.tscn --content-check 输出 CONTENT_CHECK_COMPLETE；menu.tscn --codex-check 为36项PASS。参数均置于引擎 -- 后。原 trial runner -Check 十场景通过（代码74、UI27、内容95、效果70、存档76、三战104、表现34、准确性51以及动作/自动战斗PASS）。

1920×1080、1920×1200、2560×1440实际截图尺寸和终端边界通过；截图 .godot/main-code-terminal-<尺寸>.png 和 main-code-battle.png 已查看并展示。已有根证书读取错误、Kenney原图加载告警仍存在；未据此声明导出、手机或真人趣味性验收。

## M1 校园路线底图试接入 E23

2026-09-21；基线6bff72b后。PowerShell 7调用Godot 4.7.2 Mono；测试档位于`.godot`，不覆盖玩家档。

- `--headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：128 checks / 0 failures；新增三条未恢复路线异常态和一条恢复后日间态断言。
- 图形模式追加`--exploration-capture`：102 checks / 0 failures；实际输出基地、路线、地点、奖励、开放出口、结算的1920×1080、2560×1440、1920×1200截图，像素尺寸断言通过。
- 路线页实际目视16:9与16:10：1200×680异常底图未变形，原生节点、双层连线、选中态、详情和操作按钮可读；证据固化于地图027评审目录。
- `tools/art/campus_map/build_runtime_textures.py`校验三张源图均为1600×1200并按同框输出1200×680；日间、夜间、异常像素坐标对齐。

边界：未重新运行Web导出、Android或真人测试；夜间状态未绑定；节点仍是机制示意而非真实地点坐标。首次导入需要`design/.gdignore`排除Blender制作源；编辑器仍报告既有GGT设置脚本兼容错误，但专项运行退出码0且上述断言全部通过。

## M1 校园地图日间修订与三态预览 E24

2026-09-21；基线6a6fa2e后。PowerShell 7调用Blender 4.5.3与Godot 4.7.2 Mono；测试档位于`.godot`，不覆盖玩家档。

- Blender后台运行028/`build_daylight.py`，从015源模型生成日间修订；`verify_daylight.py` PASS：5584个受检原始对象的网格、变换和渲染可见性一致，相机一致，843棵树数量一致，PNG为1600×1200。
- `tools/art/campus_map/build_runtime_textures.py`重建三态1200×680运行纹理；日间来自028，夜间来自016，异常来自026，同框对齐。
- `--headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：128 checks / 0 failures。
- 图形模式追加`--exploration-capture`：108 checks / 0 failures；日间、夜间、异常分别输出1920×1080、2560×1440、1920×1200截图并断言实际像素尺寸。
- `create-game-assets`的`asset_report.py --expect-size 1920x1080`检查三张固化评审图，结果PASS。实际目视确认：日间具有蓝天、暖直射光与明确阴影；夜间路线与步骤文字可读；异常态保持原有侵入区域且交互叠层可读。

边界：028与三态接入效果仍待人工视觉批准；夜间仅有组件预览能力，没有剧情触发；异常沿用026资产，未随日间重新打光。未验证Web、Android、HDR显示或陌生玩家体验。

## M1 校园地图全场异常色域 E25

2026-09-22；基线ec98ea5后。PowerShell 7调用Blender 4.5.14与Godot 4.7.2 Mono。

- Blender后台运行029/`build_anomaly_palette.py`，从026可编辑异常模型生成全场异常色域；`verify_anomaly_palette.py` PASS：5584个受检非灯光对象的网格、变换与可见性一致，相机一致，843棵树、14控制器及14个区域节点组一致。
- `tools/art/campus_map/build_runtime_textures.py`重建异常1200×680运行纹理，来源切换至029；日间028与夜间016不变。
- `asset_report.py`检查1600×1200 RGB整图及1920×1080 RGBA游戏截图，均PASS。
- 图形模式`--exploration-capture`：108 checks / 0 failures；三态各自通过1920×1080、2560×1440、1920×1200实际像素断言。目视确认异常色域覆盖正常区域，同时原生路线、节点、步骤和按钮可读。
- `--headless --campaign-flow-check`：128 checks / 0 failures。

边界：029资产和接入效果均为review；异常状态有意比其他状态更暗，HDR与低亮度屏幕未测；夜间剧情触发、真实地点坐标、Web、Android及陌生玩家体验仍未验证。

## M1 校园三尺度异常光效 E26

2026-09-22；基线776b329。Blender 4.5.14与Godot 4.7.2 Mono，所有命令PowerShell 7。美术评审与重建命令见地图任务030及030/generation.md。

- 030/verify_lighting.py，Blender禁autoexec、python-exit-code 1：PASS／退出码0。5602原对象矩阵／可见性、5584网格实际顶点及拓扑摘要、相机、843树、银杏27+27与14控制器一致；新增24屋顶灯带和10局部灯；42条原属性驱动与10灯能量驱动有效。
- 030/core-anomaly.png的1600×1200 RGB与1920×1080游戏截图通过asset_report.py实际解码／尺寸检查。
- Godot `--path . --log-file .godot/campus-030-capture.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check --exploration-capture`：108 checks / 0 failures／退出码0；三态各完成1920×1080、2560×1440、1920×1200实际像素断言。实看1080截图，异常窗光、局部光晕与路线可读，证据固化030/review/codex-workflow。

仅修改源资产与运行纹理来源，未改玩法代码；本轮未重复完整战役或资源台单测。既有证书／原图警告和导入时编辑器设置写权限警告仍在。未重测Web／Android、真机性能或HDR；后续视觉批准见地图任务030。

## 两路线区域高亮验证 E27

2026-09-22；起点56e7053，Godot 4.7.2 Mono，PowerShell 7。实现与边界见CORE-02两路线预览。

- `--path . --log-file .godot/route-preview-check.log res://scenes/expedition/campus_route_preview.tscn -- --route-preview-check`：246 checks／0 failures，退出码0。真实GUI事件分发覆盖悬停、地图点击、按钮鼠标点击、键盘确认、移开恢复、清除、三态坐标与选择保持；三尺寸每态两路线共18张截图，实际像素尺寸断言通过。首次测试发现测试注入未处理缩放，改用项目既有viewport-local输入方式后通过，并非绕过控件命中。
- `--headless --path . --log-file .godot/route-preview-regression.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：132／0，退出码0，含基地预览打开／关闭、选择不改变campaign与active_run、原战役回归。
- 资源台实际扫描10对象／176文件，missing=0、mismatches=0；`git diff --check`通过。目视日间东湖路线、异常银杏路线与16:10夜间截图，无标签遮挡核心操作。代表截图保存在`design/concepts/m1-campus-map/review/codex-workflow/route-preview-*.png`。

未验证Web／Android及手柄实机；区域轮廓与连接线待用户视觉确认，不代表精确导航。保留既有证书／原图加载警告，未增加脚本错误。

## 连续区域聚焦验证 E28

2026-09-23；基线3a4ebbe。Godot 4.7.2 Mono，PowerShell 7。

- `--path . --log-file .godot/route-area-check.log res://scenes/expedition/campus_route_preview.tscn -- --route-preview-check`：318／0，退出码0。沿用E27三态／三尺寸／两路线输入测试，新增区域内非建筑绿地悬停、截图像素确认区域外变暗／区域内变亮、清除后恢复原图像素。输出18张实际截图，目视032日间东湖、异常银杏与16:10布局。
- `--headless --path . --log-file .godot/route-area-regression.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：132／0，退出码0。
- 保留031证据，032代表截图为`design/concepts/m1-campus-map/review/codex-workflow/route-area-032-*.png`。无新增PNG底图或几何变动。未测Web／移动设备与性能预算。

运行环境仍报告根证书读取问题；图形运行另报告GLES shader缓存写入失败（`_save_to_cache`），实际shader编译、图像捕获和像素断言通过。未将缓存写入问题冒称为零错误。连续区域为可评审选择范围，非真实导航边界。

## 地点详情与三站顺序预览 E29

2026-09-23；实现起点747da4d，032人工批准5d5e633。引擎沿用E28，PowerShell 7。

- Godot `--path . --log-file .godot/route-walk-check.log res://scenes/expedition/campus_route_preview.tscn -- --route-preview-check`：577／0，退出码0。保留E28全量输入与像素检查；新增纯内存状态边界、真实GUI开始／顺序推进／完成／返回／提前结束、按钮和地图查看不推进、禁用其他路线、三态切换保留当前位置、当前标记及操作按钮边界。两路线×三态×三尺寸均走完三站。运行图包含中间站与完成状态。
- Godot `--headless --path . --log-file .godot/route-walk-regression.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：133／0，退出码0，含基地进入预览、走到第二站后campaign与active_run仍不变、返回销毁页面及原战役流程。
- 证据：`design/concepts/m1-campus-map/review/codex-workflow/route-walk-033-*.png`。未测Web、手机、实体手柄。保留既有证书和战斗原图加载警告，无新增脚本错误。

此验证证明预览闭环，不表示正式战役节点已改为真实地标，不验证校园实景导航或真实照片内容。

## 当前地点显著性验证 E30

2026-09-24；基线c68d2d5，PowerShell 7，Godot 4.7.2 Mono。

- `--path . --log-file .godot/route-location-marker-check.log res://scenes/expedition/campus_route_preview.tscn -- --route-preview-check`：595／0，退出码0。保留E29两路线×三态×三尺寸的真实GUI与像素检查；新增到达第三站后当前位置标记仍在、右侧明确写出终点名称的断言。
- `--headless --path . --log-file .godot/route-location-marker-regression.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：133／0，退出码0。
- 已目视日间东湖、异常银杏大道和异常品学楼终点实际截图；持久评审证据为`design/concepts/m1-campus-map/review/codex-workflow/route-location-034-*.png`，对应任务034。旧033截图保留供对比。

本次只改原生UI标识，未改三态源图、地点坐标或战役规则。既有根证书／战斗原图警告仍在；未测Web、手机、手柄及真人辨识速度。

## 下一站方向提示验证 E31

2026-09-24；基线8004d36，PowerShell 7，Godot 4.7.2 Mono。

- `--path . --log-file .godot/route-next-035-check.log res://scenes/expedition/campus_route_preview.tscn -- --route-preview-check`：667／0，退出码0。两路线×三态×1920×1080／2560×1440／1920×1200真实GUI走完三站；新增第一站、第二站右侧下一站名称与地图状态同步，第三站及完成态下一站清空的断言。既有路线选择、跨状态保持及区域像素检查保留。
- `--headless --path . --log-file .godot/route-next-035-regression.log res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：133／0，退出码0。
- 实际目视日间东湖、夜间／异常银杏大道；评审截图保存于`design/concepts/m1-campus-map/review/codex-workflow/route-next-035-*.png`，034旧图保留比较。

未修改源位图、地标坐标或战役规则，未将示意线当作可行走导航。既有根证书／战斗原图警告仍在；Web、手机、手柄和真人辨识未测。

## 北部地图拼接概念验证 E32

2026-09-24；PowerShell 7、Blender 4.5.14；候选036，未改运行时。

- `derive_alignment.py --deps .godot/dxf-research-deps`：两份2D DXF的34对重合建筑轮廓，北部到核心区平移 `(133.8263886711211, 736.0842795609497)` 米，最大XY残差约 `1.35e-6` 米；见 `036/alignment.json`。
- Blender后台运行 `build_north_preview.py` 与 `verify_saved.py`：构建、保存重开均PASS；旧核心区5584个网格的几何和变换不变；新增148建筑、184道路、67绿地、6水面、1地面、353树位；见 `036/build-validation.json` 与 `reopen-validation.json`。
- 日间实际渲染 `036/north-day-preview.png` 已目视检查，1800×1500；仅为北部拼接与建筑关系样片。未验证北部真实建筑高度、商铺身份、行道银杏、完整校园边界、夜间／异常或Godot内交互；035当前路线预览不变。

## 东南地图拼接概念验证 E33

2026-09-24；PowerShell 7、Blender 4.5.14；候选037，未改运行时。

- `derive_alignment.py --deps .godot/dxf-research-deps`：东南与核心区DXF中79对重合建筑轮廓，平移 `(176.88917778449832, -262.414031310007)` 米，最大XY残差约 `9.54e-7` 米；见 `037/alignment.json`。
- Blender后台运行 `build_southeast_preview.py` 与 `verify_saved.py`：构建及保存重开PASS；036已有6696网格的几何、变换不变；新增45建筑、42绿地、2地形、75道路路带及270树位；见 `037/build-validation.json`、`reopen-validation.json`。
- 实际日间渲染 `037/core-north-southeast-day.png` 已目视，1800×1500。GLB道路只有线，路带宽度为概念示意。未覆盖范围仍呈背景；未核验实测路宽、建筑身份、夜间／异常或Godot交互。

## 右侧中部及运动场概念验证 E34

2026-09-24；PowerShell 7、Blender 4.5.14；概念038，尚未接入Godot。

- `inspect_dxf.py --deps .godot/dxf-research-deps`：与核心／北部／东南分别有11／34／29对匹配建筑，换算到核心区的平移一致；最大单组XY残差约 `1.35e-6` 米。
- Blender后台 `build_middle_east.py`、`add_sports_fields.py`、`verify_saved.py`：全部PASS。037已有7400网格不变；右块新增43建筑、72道路路带、168树位等；运动场新增96个可编辑对象，16个树网格有意隐藏，除此之外场景已有7955网格的几何与变换不变。来源与对象统计见038的JSON验证记录。
- 实际目视 `038/four-tile-sports-day.png`（1800×1500）和 `sports-detail-day.png`（1200×900）；球场细分与颜色为示意，未验证球场用途、真实赛线或Godot运行效果。

## 左侧第五分块概念验证 E35

2026-09-24；PowerShell 7、Blender 4.5.14；概念039，未改运行时。

- `align_west.py --deps .godot/dxf-research-deps`：与核心／北部分别28／13对重合建筑，变换到核心坐标一致；最大XY残差约 `1.35e-6` 米。
- Blender后台 `build_west.py`、`verify_saved.py`：构建、保存重开PASS，旧8051网格的几何／变换／可见性不变；新增205建筑、167道路路带及180树位等；结果见039的JSON报告。
- 实际日间渲染 `039/five-tile-day.png` 已目视，1800×1500；左下建筑内侧阴影偏黑，后续统一日间打光须修。尚未验证多态、游戏运行时、真实边界或五块之外的校园。

## 五分块三态概念验证 E36

2026-09-24；PowerShell 7、Blender 4.5.14；候选040，未改运行时。

- `build_states.py` 分别生成日／夜／异常三份可编辑场景与1800×1500实际渲染。`verify_states.py` 保存重开PASS：三态均8817个同名网格、同顶点数及世界位置，镜头位置和尺度相同；异常态新增5个可移动控制点。结果见040的 `reopen-validation.json`。
- 三张图已目视：日间补光减轻西南庭院过黑，夜间保留建筑及银杏大道轮廓，异常沿用030核心区异变并在扩展区稀疏增加光斑。新增异变光斑尚未逐栋核对，三态组合仍待人工视觉评审；未验证运行时交互或完整真实校园边界。

## 五分块全图试接入验证 E37

2026-09-24；Godot 4.7.2 Mono、PowerShell 7；041可选试用页，未替换战役地图。

- `expanded_campus_preview.tscn -- --expanded-map-check`：117／0。三路线×三态×1920×1080／2560×1440／1920×1200真实GUI截图与像素尺寸、按钮选择、地图区域悬停及地点点击检查通过。
- 原`campus_route_preview.tscn -- --route-preview-check`：670／0，含“全图”打开／返回；`expedition.tscn -- --campaign-flow-check`：133／0，战役流程未回归。实际目视041的日间西侧线、夜间北部线、异常东湖线引擎截图。
- 临时路线和地点仅供交互试验；未核验所有新落点与现实身份，不作为导航、剧情或存档事实。既有根证书与GLES缓存警告仍在；未测Web、手机、实体手柄及显卡性能预算。

## 右侧运动区几何纠错验证 E38

2026-09-24；Blender 4.5.14、PowerShell 7；042三态概念，未改游戏运行时。

- `repair_sports.py -- --state day/night/anomaly`：基于040三态、038 DXF场地和用户新增参考图，输出实际渲染与可编辑场景；仅隐藏20个场内误判屋顶和96个旧通用场地网格，原8817网格的几何与变换不变。
- `verify_saved.py`：三态保存重开均PASS，每态新增233个同名同形运动场网格；20／96隐藏对象状态一致。日间运动区近景已目视，训练馆保留，跑道与四类球场无遮挡；夜间、异常全图已目视。
- 2D轮廓可核实用地位置；具体单场划分仍是示意，不作为测绘数据。左下另一处足球场未在本次右侧地块独立定位。042待人工视觉评审，尚未验证Godot交互。

## 运动区纠错试接入验证 E39

2026-09-24；Godot 4.7.2 Mono、PowerShell 7；043仅更新041可选全图试用页的三张底图。

- 三态PNG与042产物SHA256逐一一致，Godot资源重新导入。全图GUI `--expanded-map-check` 117／0，核心路线GUI `--route-preview-check` 670／0，战役无头 `--campaign-flow-check` 133／0。
- 实际运行截图已目视：043日间、夜间、异常1920×1080东湖线；场地底图已更新，路线选中时的非选定区域依设计被压暗。未改地点／路线数据；正式战役地图未替换。
- 旧有日志写入、系统根证书及编辑器设置环境警告仍在；未做Web、手机及性能预算验证。

## 全图缩放交互验证 E40

2026-09-24；Godot 4.7.2 Mono、PowerShell 7；044可选全图试用页。

- GUI `--expanded-map-check`：144／0，覆盖三尺寸三态三路线及缩放后的投影往返、地点／区域命中、滚轮、按钮、拖动平移、复位与三态切换；保存并目视1920×1080异常态156%实际截图。
- 原核心预览GUI `--route-preview-check`：670／0；战役无头 `--campaign-flow-check`：133／0。未触及旧核心路线的缩放行为或正式战役地图。
- 键盘／手柄快捷缩放、手机触控手势和高倍纹理画质尚未验证；地图标记和路线的身份仍为试用数据。

## 全图战役选区接入验证 E41

2026-09-24；Godot 4.7.2 Mono、PowerShell 7；045可选战役首页入口。

- GUI `--campaign-flow-check`：148／0，无头147／0。新增覆盖地图选区开启／取消、取消后存档不变、缩放后地点命中、三视觉路线到已有战役ID映射、选中后悬停不误改出发区域、进入原战役流程、恢复后日间视图、1920×1080实际截图尺寸。
- GUI `--expanded-map-check`：144／0；原核心路线GUI `--route-preview-check`：670／0。已目视045战役选区截图。旧直达入口、战役四站逻辑及正式战役底图未移除。
- 映射和地点落点为可替换的试用数据；未验证三路线对应真实校园路网或完整导航，也未验收触控手势与小屏表现。

## 全图布局数据化验证 E42

2026-09-25；Godot 4.7.2 Mono、PowerShell 7。GUI `res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：144／0。布局 JSON 继承原坐标及视觉结果，新增数字范围、路线地点引用、顶点数和战役 ID 校验。无运行画面变化；编辑指南见`docs/campus-map-layout.md`。

## 全屏选区交互验证 E43

2026-09-25；Godot 4.7.2 Mono、PowerShell 7。GUI `res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：156／0，覆盖三尺寸三态、地图区域直点出现“选择”、聚焦缩放、双操作和返回复位；实际截图保存在`.godot/expanded-map-day-1-1920x1080.png`、`.godot/expanded-map-focused-1920x1080.png`。GUI `res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：149／0，战役选择后探索进入既有流程；原核心路线GUI `--route-preview-check`：670／0。图像已目视，未验证触控、小屏或新区域战役逻辑。

## 全图可视化编辑器验证 E44

2026-09-25；Node 22、PowerShell 7。本机 `node tools/campus-map-editor/server.mjs`；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`：9／0，覆盖坐标投影、顶点与边线命中、校验、自交拒绝、并发冲突、隔离目录真实保存及备份。应用内浏览器实操区域顶点拖动、地点拖动、路线加删点、地点文字修改和新增地点，撤销后全部恢复；截图`.godot/campus-map-editor-preview.png`。Godot 4.7.2 GUI `--expanded-map-check`：156／0。工具未改实际布局 JSON；人工改图后仍需运行Godot预览核对地理准确性。

## 全图边缘连续化验证 E45

2026-09-25；Blender 4.5.14、Godot 4.7.2 Mono、PowerShell 7；049三态边缘视觉试接入。三态构建时确认042的9050个原网格顶点数与世界变换不变，仅新增2个视觉网格；保存后各态重开PASS，PNG均1800×1500且相机尺度2200不变。三态运行PNG与049产物SHA256一致。

- Godot资源导入退出码0；图形 `res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：183／0，新增三态×三路线×三尺寸侧边像素连续性断言。日／夜／异常1920×1080实际运行截图在049目录，地图侧边与界面背景取样RGB差为0。
- 战役无头 `res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：148／0。交互区域、坐标、路线与探索映射未修改，正式战役旧底图未替换。
- 边界：退隐区不是测绘补全；窄屏、触控、HDR和真人视觉体验尚未验证。既有证书及编辑器设置／旧图集警告仍存在；049资产及接入效果仍待负责人视觉评审。

## 全图边缘清晰度修订验证 E46

2026-09-25；Blender 4.5.14、Godot 4.7.2 Mono、PowerShell 7；050为049反馈修订。三态从042重新构建，原9050网格顶点数／世界变换在构建时锁定，保存重开各为9050＋2视觉网格，PNG 1800×1500且相机尺度2200不变。运行三态PNG与050输出SHA256一致。

- Godot资源导入退出码0；图形 `res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：192／0，含三态×三尺寸未选路和选路时的宽屏接缝像素断言。日间、夜间、异常1920×1080无路线选中截图及日间选路截图存于050目录，已目视。
- 战役无头 `res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：148／0。固定地图坐标与路线逻辑未修改，正式战役旧底图未替换。
- 已知边界：为保住边缘建筑辨识度，五分块阶梯轮廓较049更明显；校外渐暗不代表真实校界。触控、HDR、真人体验未验证；050资产及接入继续待人工评审。

## 可编辑地图亮区边界验证 E47

2026-09-26；基线a3c656c，PowerShell 7／Blender 4.5.14／Godot 4.7.2 Mono／Node。051从050三态场景移除固定退隐层，并恢复连续地面中性材质；原9050校园网格的顶点数／世界变换构建断言通过，源图和运行图均1800×1500且各态SHA256相同。布局新增独立`light_boundary`，含12点闭合亮区、12像素过渡和三态默认校外亮度0.82，路线多边形与地点保持不变。

- 本机编辑器服务运行时`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`：10／0，含边界越界／自交／亮度校验、保存备份与路线数据不受边界编辑影响。实际浏览器切到“亮区边界”，拖动顶点后“未保存”，撤销后“已同步”；三态亮度控件可见。编辑器仅日间近似预览，不显示羽化。
- Godot `--headless --editor --path . --quit`资源导入退出码0；图形 `res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：194／0，三态×三尺寸及独立改动shader亮区后校外像素恢复／复原。战役 `res://scenes/expedition/expedition.tscn -- --campaign-flow-check`：148／0。
- 实际游戏三态1920×1080截图及选路截图、源`.blend`与脚本见`design/concepts/m1-campus-map/campus-map/051/`。已目视对照050并把默认亮度校回接近旧版；宽屏侧边颜色在三态均通过接缝断言。既有Godot用户日志／证书／旧图集警告未由此功能引入。
- 已知边界：亮区为视觉遮罩而非真实校界；边界编辑不能生成导出块外建筑，原数据分块的暗线仍可能可见。触控、HDR和游戏导出包未验证，资产和接入均待人工评审；影响地图美术资源管线，待统筹。

## 开发工具集整合验证 E48

2026-09-26；基线`b69c1d1`，PowerShell 7／Windows WinForms／Node.js／Python。项目根`run-tool-suite-control.ps1`自动构建并打开工具集；旧`run-art-manager-control.ps1`兼容。控制器两张工具卡分别显示美术资源台与地图编辑器的实时状态、PID、运行目录，按钮独立启停；健康接口核对应用ID与项目根，停止前再次核对PID。两个服务端口分别为8765、8767，关闭窗口不停止服务。

- `pwsh.exe -NoProfile -File tools/art/asset_manager/control/test-launcher.ps1`：缺失／缓存／源码过期三种构建入口均通过；控制器`--self-test`分别验证两服务启动、按钮状态与停止，美术资源台未启动时也能识别已运行的地图服务。`--screenshot`实际截图存于`.godot/tool-suite-running-map.png`并在对话展示。
- `node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`：11／0，新增健康接口应用ID、PID、项目根断言；`py -3 -B -m unittest discover -s tools/art/asset_manager/tests`：33／0。地图服务脚本在独立8877端口实测启动与健康响应；默认8767端口以同工作树服务实测识别。自检修正了启动后按钮启用态的取样时序，连续两次双服务生命周期复测通过；`git diff --check`通过。
- 边界：工具集为Windows桌面开发工具，需PowerShell 7与.NET Framework C#编译器；地图服务需要Node.js，美术资源台需要Python。自定义地图端口可用独立脚本，但工具集固定监控8767；不支持远程服务或跨工作树控制。待统筹：开发工具入口更新，不影响正式游戏地图资源或导出包。

## 右下角第六分块拼接验证 E49

2026-09-26；基线`bc9e776`，Blender 4.5.14／Godot 4.7.2 Mono／PowerShell 7。来源`topoexport-5FC002`，三态源场景051，制作与验证脚本位于`design/concepts/m1-campus-map/campus-map/052/`。本次使用用户工作区的未提交布局，其SHA256在施工前后均为`06cae23aec801e70847ed9bd61a93c6da6c884b507a6101230c54f8bb3280437`，未改写或提交该文件。

- `align_corner.py --deps .godot/dxf-research-deps`：核心／旧东南／右侧运动区20／48／7对建筑一致平移，最大二维轮廓残差约1.35e-6米；体育场GLB锚点XY包围框最大差3.81e-6米。数字反映数据配准一致性，不代表现实测绘精度。
- `build_corner.py --state <day|night|anomaly>`：新增57建筑、53路带、2水面、4地形，共116网格；无树。新接缝40米内向旧地形高度渐接，最大Z校正1.08米，XY不动。三态重开`verify_saved.py`PASS：原9051网格的几何摘要／变换／材质／可见性不变，新增几何三态相同，相机及1800×1500分辨率不变。
- `verify_assets.py --layout-hash <上述哈希>`PASS：三态PNG与运行资源逐字节相同且图像不同；编辑器`/api/map-image`响应SHA256与新日间一致；`node --test tools/campus-map-editor/editor-core.test.mjs`：6／0。
- Godot资源导入退出码0；图形`res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：194／0，覆盖三态、三种分辨率、路线命中、缩放、聚焦、可调明暗边界和宽屏接缝。三态1920×1080实际截图已保存于052并目视、在对话展示。既有证书存储、用户编辑器设置和shader缓存写入警告仍存在；检查退出码0。
- 边界：新分块未推测补树，没有新增异常控制点；相机不扩幅，导出中更南的校外部分保存在源场景但可能落在画面外。正式战役旧底图未修改；资产及接入为review，待负责人视觉评审与统筹。

## 编辑器坐标拾取验证 E50

2026-09-27；基线`e63f4b4`，PowerShell 7／Node.js／内置浏览器。入口`tools/campus-map-editor/`，说明`docs/campus-map-layout.md`。

- `node --check tools/campus-map-editor/editor.mjs`通过；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`：11／0。
- 浏览器实际点击取点、复制、缩放、清除、Shift点击和Delete；拾取坐标在缩放后不变，保存与撤销保持禁用，清除后复制禁用。首次复制文本由PowerShell `Get-Clipboard`核实；浏览器剪贴板接口读取为空，不能用该接口判断系统剪贴板。实际截图`.godot/campus-editor-coordinates.png`已在对话展示。
- 用户布局文件施工前后SHA256均为`6e931f8741d5284227ed31ebb1f7f770e2c777100b8b2e3c770c05a4737a2c92`；未保存地图、未提交该文件。
- 边界：单点临时标记，刷新不保留；原图坐标而非地理坐标。剪贴板权限被拒时选中文本供手动复制；未新增玩家功能。待统筹：开发工具能力更新。

## 全图缩放与平移平滑 E54

2026-09-28；基线4b23e5d，Godot4.7.2／PowerShell7。入口scenes/expedition/expanded_campus_map.gd，测试expanded_campus_preview_check.gd。目标zoom／map_offset仍接收累加输入，displayed_zoom／displayed_offset供绘制和命中；指数响应18/s、拖动32/s，无超调或速度惯性。约0.17秒／0.09秒消除95%距离，最终小误差收敛为精确目标。

- 图形 `--path . res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check` 202／0：三态、三尺寸、地点／路线命中、拖动／聚焦／返回；新增无瞬跳、中间帧、非中心缩放锚点、30与120fps一致、连续输入累加／上限和中断收敛。实际截图 `.godot/expanded-map-zoom-1920x1080.png`已目视展示；静态图仅验证最终布局，不代替上述时序断言。
- 无头 `--path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check`148／0。git diff --check通过；布局SHA256仍为6e931f8741d5284227ed31ebb1f7f770e2c777100b8b2e3c770c05a4737a2c92，用户编辑不提交。现有日志／证书／shader缓存权限警告、旧像素图直读警告仍存在，测试退出0。
- 仅游戏内扩展地图（战役和独立预览共用），不改变网页编辑器；边缘约束优先于鼠标锚点，地图小于视口的轴保持居中。未新增触控或3D；手感仍可由负责人实机调整，待统筹。

## 校园旧目录清除与参考登记 E53

2026-09-28；基线`0144849`。按负责人明确授权，将整套asset_031重编号为asset_001；001～053范围实际存在的45目录全部删除，含未跟踪手工副本。迁出34个文件，删除剩余218文件、34,998,119字节。副本不能从Git恢复；已跟踪旧资料可从本基线恢复。E52保留为上一轮历史记录，其中asset_031现已改名，不是当前入口。

- `design/references/m1-campus-map/`保存6 DXF、5 GLB、4配准JSON、3许可证及6截图；地图Manifest的两组reference逐文件登记24项，不改变视觉批准。旧战役源图移至`design/concepts/m1-campus-map/runtime-sources/`，必要批准证据归review，其余历史脚本链交给Git。
- Blender `-b -t 2 --python-exit-code 1 --python design/concepts/m1-campus-map/campus-map/asset_001/verify_bundle.py` PASS；三态重开、依赖、1800×1500及运行图一致性通过。34个迁移文件、除说明文档外全部整套文件、9张在用运行PNG与迁移前SHA256一致；布局哈希仍为`6e931f8741d5284227ed31ebb1f7f770e2c777100b8b2e3c770c05a4737a2c92`。
- 旧构建器`tools/art/campus_map/build_runtime_textures.py`在隔离临时输出目录实跑：三张full图逐字节一致，三张裁切图像素一致；没有覆盖正式运行图。AssetCatalog扫描155登记文件、0缺失／不一致，reference登记24文件全部可读。
- `py -3 -B -m unittest discover -s tools/art/asset_manager/tests`33／0；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`11／0。`git diff --check`通过；tools／scenes／game／Manifest中不存在数字旧目录或asset_031活动引用。
- 当前地图目录仅asset_001；目录／文档变更未改变运行画面，依项目规则不新渲染截图。待统筹：源资产路径与编号变更，不改布局接口或批准边界；无历史重写、main合并或远程推送。

## 校园全图三态高清替换 E55

2026-09-29；基线`e700f4f`，PowerShell 7／Blender 4.5.14／Godot 4.7.2 Mono／Node。`asset_001`三份Blend未保存或改动，使用同目录`render_hd.py -- --state <day|night|anomaly>`在内存中将画幅设为5400×4500；日间沿用先前评审通过的同源试渲染，夜间与异常态本轮重渲染。三张PNG替换到`asset_001`及`assets/art/campus_map/expanded_neutral`，对应SHA256分别为`297dd260…106936`、`c745081a…b86251`、`d0da4483…25fb0a`；`verify_bundle.py`验证三态源场景仍为1800×1500、无缺失外链，高清源图与运行图逐字节相同。`game/run/expanded_campus_layout.json`未改写／提交，SHA256为`6e931f87…05a4737a2c92`。

- Godot `--headless --editor --path . --import`退出0；图形`--path . res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：202／0。实拍截图`.godot/expanded-map-unselected-{day,night,anomaly}-1920x1080.png`已目视检查；三态地点、路线、选择、缩放和返回通过。导入与图形测试仍有编辑器设置／日志／证书写入权限警告，但退出状态和地图断言正常。
- `node --test tools/campus-map-editor/editor-core.test.mjs`：6／0；启动本地编辑器后`node --test tools/campus-map-editor/server.test.mjs`：5／0，编辑器`/api/map-image`返回高清日间图完整字节数。`py -3 -B -m unittest discover -s tools/art/asset_manager/tests`：33／0；AssetCatalog扫描10对象／155登记文件／0缺失／0不一致，`git diff --check`通过。
- 三态正式导入启用mipmap，视觉与坐标保持现有契约；低显存设备、多纹理驻留成本尚未实测。试验目录`tmp_001`的13个临时文件约98.8MB已在正式替换后删除，不进入Git。批准状态仍为review，高清替换与本地squash合并由负责人本轮明确授权。影响纹理内存与美术交付，待统筹。

合入main前隔离squash树补测：保留main的新基地、奖励归属与重开存档，并将“探索”接到高清全图、将“路线预览”放入基地菜单。Godot导入退出0（既有GGT设置脚本警告）；战役无界面148／0、图形149／0，全图图形202／0，旧派遣`--run-smoke`通过，合并图形截图`.godot/campaign-map-select-1920x1080.png`已目视。编辑器核心6／0、资产管理33／0，AssetCatalog合并树32对象／667文件／0缺失／0不一致。未覆盖低显存设备与Web导出。

## 校园全图低清配套图留存 E56

2026-09-30；起点`cc9361c`，PowerShell 7／Blender 4.5.14。`asset_001/web/{day,night,anomaly}.png`从高清替换前`e700f4f`的同名文件逐字节恢复，Git对象哈希分别为`c926cbc3`、`54173f95`、`8fd85123`，每张1800×1500；三张共11,101,654字节。`verify_bundle.py`重开三份Blend确认无外链、源场景仍为1800×1500，高清图5400×4500与正式运行图逐字节相同，新增低清图尺寸与三态互异断言PASS。AssetCatalog扫描10对象／158文件／0缺失／0不一致；Manifest记录低清三态但不提升审批状态。

本轮只增加留存文件、Manifest和说明，未修改游戏运行纹理、布局、相机或Web导出脚本；依美术工作流的纯资源／配置整理规则，不重复运行截图。Web发布仍需实现平台纹理切换并验证包体与画质，不能将源图留存视为已经完成Web优化。低清图置于带`.gdignore`的design目录，不因留存而自动打入现有导出包；对发布流程的影响待统筹。

## 素材收尾与最新三态归档 E52

2026-09-28；基线`3d16ad3`，PowerShell7／Blender4.5.14。项目美术技能、WORKFLOW、AGENTS、任务模板和tmp忽略规则同步；本轮不改变运行画面，依纯目录／规范整理规则不重跑截图。

- 最新053的14个Blender／PNG／JSON文件逐字节迁移到`design/concepts/m1-campus-map/campus-map/asset_031/`。删除154个已跟踪废弃文件（含43份历史Blender），1,860,802,587字节；保留未跟踪026手工副本及原始DXF／GLB／真实参考。删除项可从基线恢复，不清除Git历史。旧001～053命令与图片引用标记为历史复现，不再是活动入口。
- Blender `-b -t 2 --python-exit-code 1 --python design/concepts/m1-campus-map/campus-map/asset_031/verify_bundle.py` PASS：三态重开无缺失依赖，1800×1500，三张PNG互异且与运行图相同。搬迁前确认三态无外部贴图／链接模型；迁移14文件哈希全部一致。
- 9张现行运行PNG与清理前SHA256一致；用户`expanded_campus_layout.json`仍为`6e931f8741d5284227ed31ebb1f7f770e2c777100b8b2e3c770c05a4737a2c92`，不纳入提交。
- `py -3 -B -m unittest discover -s tools/art/asset_manager/tests`：33／0；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs`：11／0。AssetCatalog全库扫描131登记文件、0缺失／不一致，地图10个有效登记。`git check-ignore`确认tmp_001／tmp_999被忽略，asset／concept不被忽略；`git diff --check`通过。
- 技能`quick_validate.py`检查通过；校验器所需PyYAML仅安装在忽略的`.godot/skill-check-deps`，需具备该缓存读取权限，未改全局Python。最新三态批准仍review。影响留存／提交／合并规则，待统筹；无main合并、远程推送或历史重写。

## 北部道路可渲染修复 E51

2026-09-27；基线`256b846`，Blender4.5.14／OptiX／Godot4.7.2／PowerShell7。命令、源场景、渲染与实际截图位于`design/concepts/m1-campus-map/campus-map/053/`，详见其中`generation.md`。

- `verify_roads.py --version 052`红灯：`missing=24, nonrenderable=184`。修复后三態默认`verify_roads.py`通过：每态208路面／7428中心线采样全部命中，8983个其他网格与镜头不变，三态道路几何摘要相同。构建／测试均排除不足5厘米的退化边。
- `build_roads.py --state <day|night|anomaly>`三态生成；`verify_assets.py`确认运行图逐字节一致、1800×1500尺寸、HTTP编辑器底图一致，用户布局SHA256仍为`6e931f8741d5284227ed31ebb1f7f770e2c777100b8b2e3c770c05a4737a2c92`。未提交用户布局。
- Godot `--headless --editor --path . --import`退出0；图形`--path . res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`：194／0，三态三尺寸、缩放、选路及亮区通过。053实际游戏截图已目视并在对话展示；既有日志／证书／shader缓存权限警告仍存在。
- `node --test tools/campus-map-editor/editor-core.test.mjs`：6／0；AssetCatalog扫描无Manifest错误。仅北部路面修复，未改变地图交互、其他几何或光照；路宽仍为示意，资产和接入效果review，待统筹。

## Web 缩包与资源完整性验证 E56

2026-09-29；基线 `main` `06ad4e6`，分支 `codex/web-export-size`；Windows PowerShell 7、Godot 4.7.2 标准版、Codex 应用内浏览器本地 HTTP。Web 预设仅排除 `design/*`，保留 `all_resources` 及闪卡活动目录。

- `pwsh.exe -File ./build-web.ps1`：导出成功，整站 296.75 MiB（原包 1,299.91 MiB），其中 `index.pck` 258.74 MiB；导出记录无 `res://design/` 项。脚本与 Pages CI 均有 900 MB 整站体积门槛。
- 正式 `builds/web/index.html`：主菜单、基地阶梯教室背景、图鉴闪卡列表及详情实际显示；截图 `.godot/web-export-home.jpg`、`.godot/web-export-card.jpg`。浏览器隔离 HTML 副本加入 `--campaign-flow-check` 后全战役 124 checks / 0 failures；副本已移除，正式包不带测试入口。
- 图形场景 `res://scenes/expedition/expedition.tscn -- --campaign-flow-check --library-environment-preview-capture`：31 checks / 0 failures，覆盖九张环境图切换。
- 边界：线上 Pages、手机未测；自动 Web 全战役日志有两条 `_focus_home_action` 延迟调用错误。原生 `--memory-terminal-capture` 输出 12 checks / 3 failures（终局节点数量断言），不列为通过。Godot 导入过程仍有既有根证书与编辑器设置保存提示。

## Web 背景衍生图验证 E57

2026-09-29；基线为 `codex/web-export-size` 的 `75a1011`（此前整站 296.75 MiB、PCK 258.74 MiB）；Windows PowerShell 7、Godot 4.7.2 标准版、Codex 应用内浏览器本地 HTTP。

- `tools/art/build_web_backgrounds.gd` 从已批准的 24 张校园和 6 张主菜单 3840×2160 PNG 生成 30 张 1920×1080 WebP（Lanczos，品质 0.85）；原图共 514,775,538 字节，衍生图共 11,356,338 字节。生成器退出后 Godot 旧自动加载脚本报告空场景属性错误，但 30 张文件均已完成写入和解码检查。
- `pwsh.exe -File ./build-web.ps1`：整站约 182.4 MiB，其中 PCK 144.34 MiB、WASM 37.68 MiB；相对 E56 整站减少约 114.4 MiB（约 38.5%）。导出日志含 24 张校园、6 张菜单 Web 导入纹理，不含这两组原始 4K 图片。对应导入纹理由校园 138.40 MiB 降至 49.15 MiB、菜单 40.03 MiB 降至 14.88 MiB。
- 本地 Web 测试 HTML 仅添加 `--web-background-check` 启动参数，正式 `index.html` 不带此参数。浏览器日志 `WEB_BACKGROUND_CHECK checked=30 failures=0`，无背景加载错误；南门异常图 1920×1080、2560×1440、1920×1200 实际截图，主菜单同三尺寸截图见两项美术任务的 review/codex-workflow 证据目录。
- 原生主菜单图形检查 `tools/menu_runtime_check.tscn -- --test-size=1920x1080` 通过 2 状态、6 张原始背景及 6 次轮播；原生全战役 `expedition.tscn -- --campaign-flow-check --order=012` 为 124/0。校园预览专项 `--campaign-flow-check --campus-environment-preview-capture` 为 125/0，覆盖 24 张原始 4K 导入纹理与三种窗口尺寸。第一次战役检查被旧 `.godot/campaign-flow-profile.json` 已通关测试档干扰而失败；临时移开旧档后通过，并已恢复原档。
- 资源台单测 33 项通过；Manifest 实际扫描 32 对象、646 登记文件、缺失 0、不一致 0。非 Web 预设排除 Web 衍生图，原图版本状态未改变；Web 衍生图视觉效果及线上 Pages 仍待评审／验收。

## 平台素材路径适配验证 E58

2026-09-30；基线：`codex/web-export-size` 的 `4931b07` 加本次平台适配工作树；Godot 4.7.2 标准版、PowerShell 7、Codex 应用内浏览器本地 HTTP。

- `res://tools/platform_asset_check.tscn`：30 个原图到 WebP 的路径映射、文件存在、Android 原图回退、平台名大小写及非目标图路径共 30/0；当前 Windows 运行时仍指向原图。
- 原生主菜单 `res://tools/menu_runtime_check.tscn -- --test-size=1920x1080`：两种状态、六张 4K 背景、六次轮播通过；实际截图生成在 `.godot/m1-main-menu-1920x1080-*.png`。
- `pwsh.exe -File ./build-web.ps1`：正式包导出成功，整站 182.4 MiB。浏览器打开正式 `/web/`，主菜单显示正常；仅本地检查页加入 `--web-background-check`，日志 `WEB_BACKGROUND_CHECK checked=30 failures=0`，无浏览器错误。实际 Web 截图临时保存在 `.godot/platform-asset-web-check.png`，可复现；截图未纳入正式资产。
- 2026-09-30 在 `9590986` 基线上复测：`build_web_backgrounds.gd -- --check` 报告 `WEB_BACKGROUNDS_CHECK count=30 sources=514775538 bytes derivatives=11356338 bytes`，未写入衍生图；`platform_asset_check.tscn` 为 30/0；原生主菜单六图与轮播通过并实际截图。此项移除新图数量硬编码，尚未用新增图片样本、全新图片组或 Android 导出验证。脚本模式结束时旧 GGT 自动加载项仍报告空场景属性错误，检查成功标记与退出码为 0。
- `py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v`：33 项通过，Manifest 映射字段未破坏资源台读取。已验证按平台选择，不代表已验证 Android／iOS 新规格、不同浏览器视口的质量或线上 Pages 发布。Web 衍生图的视觉效果仍待负责人人工评审。
- 合入本地 `main` 复测（基线 `5939c80` + `5526aab`）：`pwsh.exe -File ./build-web.ps1` 导出整站 255.8 MiB，低于 900 MB 门槛；`platform_asset_check.tscn` 为 30/0；资源台单测 33 项通过。隔离并恢复旧 `.godot/campaign-flow-profile.json` 后，`expedition.tscn -- --campaign-flow-check --order=012` 为 148/0；`menu_runtime_check.tscn -- --test-size=1920x1080` 六图轮播通过并保存实际截图。浏览器打开正式 `/web/` 显示主菜单；临时 HTML 检查页报告 `WEB_BACKGROUND_CHECK checked=30 failures=0`，无浏览器错误，检查页已删除。实际 Web 截图为 `.godot/main-merged-web-menu.png`；未执行线上 Pages 部署。

## 校园全图 Web 三态集成 E59

2026-09-30；隔离分支`art/campus-map-web-merge`，基线`main`的`e611d5b`加低清留存提交`27a2d87`；PowerShell 7／Godot 4.7.2标准版。`asset_001/web/`三张1800×1500 PNG逐字节复制到正式`assets/art/web_campus_map/expanded_neutral/`；三份Godot导入元数据均开启mipmap。平台路径适配层只在Web选择低清图，桌面等平台继续使用5400×4500原图；Web预设排除高清全图，非Web预设排除Web专用图。

- Godot无头导入退出0；`res://tools/platform_asset_check.tscn`为33／0，覆盖三张新增映射、文件存在、非Web回退。图形`res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check`为202／0，桌面实际日／夜／异常截图保存在`.godot/expanded-map-unselected-{day,night,anomaly}-1920x1080.png`，日间图已在对话展示。
- `pwsh.exe -File ./build-web.ps1 -Godot <Godot 4.7.2标准版>`正式构建成功，整站199.3 MiB，PCK 169,134,436字节；PCK路径检查有3张Web全图、0张高清全图。三张正式Web源图与`asset_001/web`对应文件SHA256相同。
- 资源台单测33项通过；AssetCatalog扫描33对象、错误0，`asset_001`及`web_expanded_preview_001`均matched；`git diff --check`通过。Web实际浏览器三态切换、手机画质／显存及线上Pages尚未验收；衍生图视觉批准仍为review，不能由构建成功推定获批。随后在本地`main`按squash合入，复测导入退出0、映射33／0、桌面地图202／0、资源台33项通过，Web整站199.3 MiB且PCK含3张Web全图／0张高清全图；未推送。

## 奖励候选适配验证

2026-10-07，基线4913858加工作树；PowerShell7／Godot4.7.2。使用Godot console加 --path . --quit-after 600 res://scenes/battle_demo/reward_eligibility_check.tscn，无头加 --headless 得23／0，图形加 --rendering-method gl_compatibility 并在末尾附 -- --capture 得26／0。覆盖原RewardCatalog／ShortRun、原战役胜利生成、checkpoint冻结及实际鼠标领取，三种桌面截图.godot/reward-eligibility-<尺寸>.png。夹具只有奖励页面，不冒充本次完整战斗胜利或全战役通过。combat_growth_check.tscn38／0。规则与剩余边界见REWARD-01。

## 新／旧成长预算验证

2026-10-07，基线6126c11加工作树，PowerShell7／Godot4.7.2；growth_budget_check.tscn使用 --path . --quit-after 600，加 --headless 得38／0，GUI --rendering-method gl_compatibility -- --capture 得47／0。原奖励与对象真实鼠标操作，奖励／对象／装备详情各三尺寸.godot/growth-budget-<页面>-<尺寸>.png。验证原构筑schema8及旧schema7高成长往返、当前属性和拒绝非法快照；详细边界见CORE-05，截图发现既有动画层级遮挡需另行修正。combat_growth_check旧预算38／0、reward_eligibility_check23／0、chain_check36／0。不是所有强化组合或真人趣味性证据。

## 世界动画与面板遮挡验证

2026-10-07，基线8440dbe加工作树；growth_budget_check.tscn GUI -- --capture为49／0，新增动画分组／部件最大层级与原装备弹窗的边界检查，三种桌面截图.godot/growth-budget-bag-<尺寸>.png实际人物不再盖住说明。animation_check.tscn PASS；campaign_animation_check.tscn GUI -- --capture为8／0，实际原校园粉笔动作截图.godot/chalk-campaign-ranged.png。动画夹具改用每次唯一隔离存档，避免历史进度导致_guard未建立节点；先前包含脚本错误的7／0结果不作为此基线证据。未更改模拟规则或素材批准。

## 三方向奖励与JSON轮次验证

2026-10-07，基线42d479c加工作树，PowerShell7／Godot4.7.2：res://scenes/battle_demo/reward_slots_check.tscn加 --headless 为22／0，GUI --rendering-method gl_compatibility -- --capture 为29／0，均 --quit-after 600。128种子门槛／候补与1024种子链先抽对照、原校园冻结页／检查点／实际领取、真实JSON及坏字段边界通过。通用抽样是否进入对象页会改变检查数，不能将次数当额外覆盖。两页三尺寸.godot/reward-slots-<页面>-<尺寸>.png。combat_content_check51／0，growth_budget_check无头41／0；尚未重跑本轮全战役，补给填充与零候选继续未完成。详见REWARD-01与SAVE-02。

## 道具奖励与空池继续验证

2026-10-07，基线83437f6加工作树，PowerShell7／Godot4.7.2：res://scenes/battle_demo/item_reward_check.tscn，--path . --quit-after 650；--headless为69／0，GUI --rendering-method gl_compatibility -- --capture为78／0。原补给卡、校园空池、短局空池各三尺寸.godot/item-reward-<页面>-<尺寸>.png。内容引用／容量、真实JSON、原领取与库存、防重复和坏空页拒绝通过。reward_slots_check22／0、growth_budget_check41／0。原expedition.tscn -- --campaign-flow-check --order=012 GUI149／0，完整原战役通过，旧隔离档已保留；不写玩家档。不是双流派真实新档／真人平衡证据，边界见REWARD-01。

## 原出发双流派与伙伴验证

2026-10-07，基线aa61309加工作树，PowerShell7／Godot4.7.2 console；--path . --quit-after 1500 res://scenes/battle_demo/starting_strategy_check.tscn，无头加--headless得到109／0，GUI加--rendering-method gl_compatibility，末尾-- --capture得到125／0。检查独立新档经原序章、派遣、人物交谈、图书馆四战及实际奖励／结算，两档共10场，无代码或道具注入。原程序预览与释放按钮事件、真实页面鼠标输入、JSON／活动局和永久编队恢复、坏阵位原子拒绝通过。原expedition.tscn -- --campaign-flow-check --order=012 GUI150／0，原完整战役通过；旧隔离档保留，不写玩家档。

实际出发、伙伴与两队战斗各三尺寸截图.godot/starting-<页面>-<尺寸>.png，已目视1920×1080和1920×1200并展示出发；完整原始GUI战斗结果在docs/research/combat-starting-flow-evidence.json。此时前三个正式节点仍巡逻、末节点巨像；不宣称三类型敌阵、所有强化组合或真人趣味性已验证。具体实现与边界见CORE-05。

2026-10-07最终护盾成员说明复测：starting_strategy_check.tscn GUI -- --capture为124／0，三尺寸实际截图已更新；与先前125项的差异来自随机奖励是否进入对象选择页。原10场GUI证据保留原抽取结果，不用本次不同种子覆盖。

## 原路线巡逻／教室／巨像验证

2026-10-07，基线30389ff加工作树，PowerShell7／Godot4.7.2。使用starting_strategy_check.tscn，--path . --quit-after 1500；--headless得到132／0，GUI --rendering-method gl_compatibility -- --capture为154／0。两个原新档共10场，实际第三站教室预警与整排释放、自然产码与核心、原JSON检查点、旧缺字段再保存／重试仍巡逻、坏版本拒绝通过。程序驱动原模拟，页面选择使用实际鼠标，未注入人物／代码或使用道具。完整expedition.tscn -- --campaign-flow-check --order=012 GUI150／0，旧隔离档已保留，不写玩家档。

新增两队各三尺寸教室预警截图.godot/starting-classroom-warning-<队>-<尺寸>.png，护盾1920×1080已目视并在对话展示；本次原始10场保留在docs/research/combat-route-pressure-evidence.json。不是随机胜率、任意强化组合、其他区域的双流派新档或真人趣味性验收；详细边界见CORE-05。

## 原主菜单窗口标题与背景复核

2026-10-07，基线a59d42d加工作树。Godot4.7.2／PowerShell7；tools/menu_runtime_check.tscn图形模式，--path . --rendering-method gl_compatibility --quit-after 600 -- --test-size=1920x1080（另复验2560x1440、1920x1200）。每尺寸正常／异常6背景与6轮播通过，日志实际窗口标题“校园异闻”；18张PNG尺寸逐项正确，无脚本错误。1080与1200图已实际查看并在对话展示。具体实现、末尾空窗口纹理差异与证据路径见UI-05，不把本项通过扩大为全流程美术验收。

### 六敌人原战役接入专项

PowerShell7，Godot4.7.2：`--path . --rendering-method gl_compatibility res://scenes/battle_demo/enemy_integration_check.tscn -- --capture`。2026-10-07 / eca60f9加工作树，94 checks / 0 failures，三种敌阵×三分辨率，六名敌人攻击与头像实际绑定；原起始流程无头133/0。详细资源版本、授权和限制归 ART-02 与敌人任务。截图 .godot/enemies-<patrol/classroom/final>-<尺寸>.png；检查使用独立存档，不改玩家存档。

### 既有动作反馈与破解输入专项

2026-10-07 / 8e983ea加工作树。Godot4.7.2 / PowerShell7：`--path . --rendering-method gl_compatibility res://scenes/battle_demo/battle_feedback_check.tscn -- --capture`，68/0；三尺寸键盘、鼠标、暂停、紧凑面板、三原敌阵计时释放，12张实际截图。`presentation_check.tscn`无头PASS / 0；`starting_strategy_check.tscn`无头132/0。详细边界归UI-02与ART-01。

旧 `code_integration_check.tscn` 本轮失败，未纳入通过集合：旧强化数值／绑定断言以及analysis.effects[0]已不适配现行定义，脚本中止后停止进程，日志 .godot/feedback-code-main.log。不能将历史35/0当成本次通过证据。原链路验证使用现行starting_strategy入口。

## 五敌人动画合并后的主线验证

2026-10-07，基线9a52d06＋来源de3753b及接入修改。Godot4.7.2／PowerShell7：正式运行包promote_animation.py --check五包通过，library_contract_check.tscn -- --production为13160／0；enemy_integration_check.tscn GUI -- --capture为108／0；starting_strategy_check.tscn无头133／0；battle_feedback_check.tscn GUI -- --capture为68／0；growth_budget_check.tscn GUI -- --capture为50／0。每次指定新鲜.godot/enemy-merge-*.log，GUI使用gl_compatibility，三种尺寸1920×1080／2560×1440／1920×1200截图已查看。

资源台Python40项单测通过，实际浏览器52对象／1393文件全部引用有效；分类、复选框和施法GIF切换已操作。run-debug.ps1 -Check的旧循环问题修复后72／0，原始失败记录与原因见DEV-01。当前验证不含全量旧检查、Web导出、移动端、任意成长或真人试玩；先前code_integration_check旧断言问题仍按原档案记录，不声称全测试套件通过。


## 单位状态与产码可读性专项

2026-10-07，基线45656a3加HUD修改，Godot4.7.2 / PowerShell7：`--path . --rendering-method gl_compatibility res://scenes/battle_demo/status_hud_check.tscn --log-file .godot/status-hud-gui.log -- --capture`，61/0，headless同为61/0。原Campaign隔离档，三尺寸库存／意图、自然敌人施法、真实点击固定／Esc、模拟暂停与页面退出；实际截图status-hud-*.png，边界见UI-02。生成概念与正式美术审批独立维护，不将检查通过等同批准。


### 战斗组件纹理试接入

2026-10-07，f602b36＋试接入工作树，PowerShell7 / Godot4.7.2。`--path . --rendering-method gl_compatibility res://scenes/battle_demo/status_hud_check.tscn --log-file .godot/hud-skin-gui.log -- --capture`：85／0，三尺寸＋密集盾队＋产码来源；相同运行参数的 battle_feedback_check 68／0、screen_cleanup_check 64／0；`./run-debug.ps1 -Check -EnginePath <Godot console>` 73／0。实际截图在 design/concepts/battle-status-components/review/codex-workflow/trial-*.png。详细边界归UI-02，人工授权归美术任务；试接入不等于最终美术批准。


2026-10-07 紧凑布局修订：同一status_hud_check.tscn -- --capture，日志.godot/hud-compact-gui.log，101／0；新增友方简要详情、紫色共享吸收与缩小图形保留鼠标热区验证。三尺寸与密集截图为review/codex-workflow/compact-*（完整目录见UI-02）。前文其他通过数仅为各自当时基线，本次未重复全部运行。

2026-10-07 生命护盾／思考泡泡修订：status_hud_check.tscn -- --capture，.godot/hud-vitals.log，105／0；新增双向填充与盾伤不改变生命宽度检查，三尺寸实际截图vitals-*，范围见UI-02。

2026-10-08 反馈链收尾：feedback_progress_check -- --capture 15／0、status_hud_check无头105／0、code_layout_check三尺寸67／0、screen_cleanup_check无头64／0；播放51／0与产码队列33／0见UI-01/COMBAT-02。入口和边界归UI-02，截图feedback-*等已留存于战斗组件review/codex-workflow。

2026-10-08 Debug暂停兼容补验：run-debug -Check 74／0，-Capture 86／0，修复旧打开菜单方式留下暂停；新增手动暂停和已开菜单往返检查，详见DEV-01。battle_feedback_check无头56／0；截图帧附加检查与GUI68项区别归UI-02。


留存后复验（2026-10-08，e15be65＋本阶段工作树）：status_hud_check.tscn -- --capture 105／0，三尺寸、真实意图／详情输入和密集盾队截图为final-status-*；AssetCatalog全库53对象／1526文件，0缺失、0不一致、0错误，HUD133登记文件全部匹配。60份SVG／PNG／StyleBox源与运行逐字节相同，批准概念SHA匹配，无tmp目录。运行副本仅保留实际组件与元数据，完整生成／校验记录归asset_001。登记核验记录为review/codex-workflow/retention-validation.json。未扩大到移动端或全量旧玩法套件；视觉评审状态不变。

### 选择子页与热点关联

2026-10-08，基线51c4118＋art/event-choice-ui工作树。PowerShell7，Godot4.7.2 Compatibility。下列参数传给本机Godot console，cwd为项目根；使用隔离检查档，不覆盖玩家档。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| `--headless --path . res://scenes/expedition/choice_pages_check.tscn --log-file .godot/choice-exhausted-final.log` | 107／0 | 图谱、主线交互、保存与旧字段兼容 |
| `--path . --rendering-method gl_compatibility res://scenes/expedition/choice_pages_check.tscn --log-file .godot/choice-delivery-gui.log -- --capture` | 197／0 | 三尺寸、真实点击、多轮、跨地图、对象条件、滚动／焦点、结算去重 |
| 同场景 `--log-file .godot/choice-core-delivery.log -- --capture --core-only` | 54／0 | 三尺寸与已有记忆终端身份 |
| `--headless --path . res://scenes/expedition/expedition.tscn --log-file .godot/choice-delivery-campaign.log -- --campaign-flow-check --order=012` | 149／0 | 原序章、三区域、终局与结算 |
| 同战役入口去掉headless，加`--rendering-method gl_compatibility`，日志choice-campaign-gui.log | 150／0 | 实机完整原战役；含额外截图断言 |
| `scenes/battle_demo/item_reward_check.tscn`／`reward_slots_check.tscn`／`reward_eligibility_check.tscn`，`--headless --path .` | 69／0、22／0、23／0 | 旧奖励与适配回归 |
| `scenes/expedition/screen_cleanup_check.tscn`／`campus_playthrough_check.tscn`，`--headless --path .` | 64／0、61／0 | 页面清理、原地点／记忆交互 |

重跑choice检查会按随机原奖励分支进入对象页，断言总数可变化；固定对象夹具始终覆盖已满训练、返回候选和一次领取。choice夹具中的guard_won与结算遍历由测试设置，不当作自然战斗胜率；完整战役检查另行推进实际模拟。必要截图在design/concepts/event-choice-ui/review；原始临时输出在.godot/choice-*，不作为运行资产。Manifest全库检查与源副本一致见asset-validation.json。环境原有根证书／Kenney直接读图警告仍存在，无本次脚本错误。手机、手柄、Web导出包和真人阅读未验；导出配置加入事件JSON，未借配置修改声称包已验证。

最终边界补验：choice_pages_check无头107／0包含合法空奖励继续后进入事件的真实JSON恢复；run-debug.ps1 -Check -EnginePath <Godot console> 为75／0。旧短局／测试入口未创建campaign_panel时的输入仍安全转交原控制器。GUI197项与终端54项为本任务布局验证，空池后事件补验不涉及新的画面变化。


### 选择子页视觉修订 asset_002

2026-10-08，b2a1e83＋本轮工作树；使用相同Godot console，PowerShell7／Compatibility与隔离存档。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| `--path . --rendering-method gl_compatibility --log-file .godot/choice-chrome-delivery.log scenes/expedition/choice_pages_check.tscn -- --capture` | 205／0 | 三尺寸原流程、长文／焦点、多轮、跨地图、条件对象、结算去重 |
| 同入口 `--log-file .godot/choice-chrome-states.log`，用户参数`--capture --skin-only` | 55／0 | 共用图谱、真实悬停／按下、焦点卡片与禁用；不是55个纯视觉断言 |
| `--headless --path . --log-file .godot/choice-chrome-cleanup.log scenes/expedition/screen_cleanup_check.tscn` | 64／0 | 页面退出、悬停和原层级清理 |

确定性矢量重建：`python tools/art/ui/build_choice_chrome.py <输出目录>`，只生成矢量／chrome.json，不覆盖源PNG或替代生图。20张活动源图及chrome.json与运行一致；AssetCatalog54对象／1575登记文件，缺失和不一致均0。原证书／Kenney读图警告仍存在，无此次脚本错误。图片来源及QC归asset_002，三尺寸与状态实机证据归review/codex-workflow/asset-002。原001证据是历史基线，不用于冒充002验收；仍未验手机、实体手柄、Web包。

### 选择页字体与结果标记

2026-10-08，1365e70＋本轮工作树，PowerShell7／Godot4.7.2。以下参数传给本机Godot console，cwd为项目根；GUI采用Compatibility，检查使用隔离原战役档。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| `--path . --rendering-method gl_compatibility --log-file .godot/choice-semantic-categories-final.log scenes/expedition/choice_semantics_check.tscn -- --capture` | 214／0 | 三尺寸、十类标签文字／符号与≥4.5:1对比、字体角色、混合／长标签、静止热区、真实补给一次领取／重复防护、绘制无副作用 |
| 同渲染参数，`--log-file .godot/choice-semantic-final.log scenes/expedition/choice_pages_check.tscn -- --capture` | 200／0 | 原三尺寸流程、多轮／跨地图、对象、长文焦点、原结算；随后仅收口重复字号参数，最终实机候选由上一行重验 |
| `--headless --path . --log-file .godot/choice-semantic-flow-final.log scenes/expedition/choice_pages_check.tscn` | 103／0 | 最终代码的原流程、保存与对象回归；数量随随机奖励分支变化 |
| 同GUI参数，`--log-file .godot/choice-semantic-states.log scenes/expedition/choice_pages_check.tscn -- --capture --skin-only` | 55／0 | 实际按钮悬停／按下、聚焦卡与禁用；含共用图谱检查 |
| `--headless --path . --log-file .godot/choice-semantic-cleanup.log scenes/expedition/screen_cleanup_check.tscn` | 64／0 | 原页面、悬停及表现退出清理 |

负属性、消耗和混合数值属于明确标注的界面夹具，不代表新事件或数值执行；真实奖励仅使用现有供给／训练／装备快照。Native FontVariation按TextServer整数wght轴读取现有Typography字重，字号集中于choice_skin。图标Tween会回落，内容Tween可取消，验证不以移动按钮热区制造反馈。运行源及活动asset_002未改；21份文件一致、全库54对象／1575登记文件无缺失／不一致／错误。九张必要截图和两份精简JSON留存于review/codex-workflow/semantics；生成缓存和隔离存档不入Git。原环境证书／Kenney警告仍有，无最终脚本错误。未扩大为全游戏无障碍、移动端、实体手柄、Web包或真人趣味性验收。

### 紧凑三选项

2026-10-08，97d4fa6＋工作树；PowerShell7／Godot4.7.2 Compatibility、隔离原战役档。`--path . --rendering-method gl_compatibility --quit-after 3000 --log-file .godot/choice-compact-delivery.log scenes/expedition/choice_semantics_check.tscn -- --capture`为235／0，包含三桌面尺寸真实三候选整卡／按钮同屏和零滚动断言。`--headless --path . --quit-after 3000 --log-file .godot/choice-compact-flow.log scenes/expedition/choice_pages_check.tscn`为107／0；相同GUI参数的choice_pages_check加`--capture --skin-only`、日志choice-compact-states.log为55／0。长文／焦点、真实领取及悬停／按下仍正常，无最终脚本错误，原证书与Kenney警告保留。三张候选截图与精简JSON归event-choice-ui/review/codex-workflow/compact；未验证手机、实体手柄或Web包。

### 热点返回权限

2026-10-08，dbe4aa1＋工作树；PowerShell7／Godot4.7.2 console，cwd项目根，隔离原战役存档。下表参数均在`--path . --quit-after 3000`之后，GUI加`--rendering-method gl_compatibility`，无头加`--headless`。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| GUI `--log-file .godot/event-return-policy-final.log scenes/expedition/event_return_check.tscn -- --capture` | 111／0 | 三桌面尺寸，事件／节点优先级，原鼠标禁用、Esc、旧操作、第一可用焦点／长文Tab、磁盘／基地续玩、失败确认／返回保存、终页返回完成 |
| GUI `--log-file .godot/event-return-flow.log scenes/expedition/choice_pages_check.tscn -- --capture` | 197／0 | 原多轮／跨地图、条件对象、实际领取、长文焦点和结算；随后仅收口控制器守卫位置，最终由专项与下行重验 |
| 无头 `--log-file .godot/event-return-flow-final.log scenes/expedition/choice_pages_check.tscn` | 96／0 | 最终原流程、图谱、旧字段、条件、保存与领取 |
| GUI `--log-file .godot/event-return-compact-final.log scenes/expedition/choice_semantics_check.tscn -- --capture` | 235／0 | 最终三真实奖励整卡同屏／无滚动、字体／结果与真实领取 |
| 无头 `--log-file .godot/event-return-cleanup.log scenes/expedition/screen_cleanup_check.tscn` | 64／0 | 原页面、悬停及表现清理 |
| 无头 `--log-file .godot/event-return-campaign.log scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012` | 149／0 | 原序章→三区域→终局全战役 |

三尺寸1920×1080、2560×1440、1920×1200。必要禁止三尺寸／允许1080截图与精简JSON在design/concepts/event-choice-ui/review/codex-workflow/return-policy，当前asset_002未改。配置反例、长文和失败保存属于明确夹具；实际访问信息通过原Campaign／Profile读写。固定对话不新增随机结果，未来随机分支须先保存再展示；规则与未覆盖边界归RUN-02。原环境证书与Kenney读图警告保留，无最终脚本错误；未验手机、实体手柄、Web导出或真人阅读。

### 选择页纸面背景重绘

2026-10-08，abdfcad＋背景重绘工作树；PowerShell7／Godot4.7.2 console，cwd项目根。运行`--path . --rendering-method gl_compatibility --quit-after 3000 --log-file .godot/paper-redraw-final.log scenes/expedition/choice_pages_check.tscn -- --capture`，原隔离Campaign三尺寸GUI197／0。实际查看事件与三奖励页面，动态文案、条件、多轮／跨地图、长文焦点、领取／结算通过。改动只有paper.png，未重跑无关战斗数值套件。

AssetCatalog读取原主Manifest：54对象／1578登记文件，0缺失／不一致／错误，asset_003活动21份运行文件逐字节匹配，其他20份原asset_002依赖未改。源1659×948 RGB、不透明，无游戏文案；生成／清理提示词与来源归asset_003。必要事件三尺寸和奖励16:10截图、精简JSON归event-choice-ui/review/codex-workflow/paper-redraw。审批／留存归原美术任务，不借本检查升级review。

最终GUI没有SCRIPT ERROR／Parse Error，原证书与Kenney读图警告保留。无头编辑器已成功重新导入paper.png；退出时报告EditorSettings未实例化（shutdown_adb_on_exit），原导入日志在.godot/paper-redraw-final-import.log，不把进程退出0说成无报错。实际GUI使用最后导入的无键盘标记版本。未验手机、实体手柄、Web导出或真人阅读。


## 区域流程资源与编辑器分工

2026-10-09，基线 `10fb33b` 加 `codex/campus-flow-config` 工作树；PowerShell7／Godot4.7.2 console／Node。下面Godot参数在 `--path . --quit-after 3000 --log-file .godot/<检查名>.log` 之后使用。所有探索测试使用 `.godot` 隔离档，不写玩家档。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| `--headless scenes/content/campus_flow_preview.tscn -- --flow-preview-check` | 120／0 | 三区域资源、真实JSON、五站原控制器、配置错误及原主线状态保护、检查器校验与禁用、12站清单和重访 |
| 同入口改 `--rendering-method gl_compatibility`，用户参数加 `--capture` | 154／0 | 1280×720、1920×1080、1920×1200三桌面尺寸，三区域投影／命中／引用，五站原主线画面与长列表 |
| `--headless scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012` | 149／0 | 原序章、派遣、三区域、领奖、终局、结算与恢复 |
| `--rendering-method gl_compatibility scenes/battle_demo/starting_strategy_check.tscn -- --capture` | 151／0 | 两套真实出发队伍、当前多轮人物交谈、10场实际战斗、冻结阶段JSON、临时／永久编队与奖励 |
| `--headless game/run/location_check.tscn` | 134／0 | 地点、热点及原检查点 |
| `--headless scenes/expedition/campus_playthrough_check.tscn` | 61／0 | 原校园地点／回忆交互 |
| `node --check tools/campus-map-editor/editor.mjs`，`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs` | 语法通过，11／0 | 布局、几何、服务身份、读取、坏数据／并发覆盖拒绝、隔离保存与备份 |

Godot `--headless --editor --path . --quit --log-file .godot/campus-flow-final-import.log` 完成资源／插件导入，无脚本错误；退出仍有既有EditorSettings shutdown_adb_on_exit错误，不能把退出0称为无报错。运行检查仍有本机根证书和Kenney直接读图告警，没有最终Script／Parse错误。当前多轮人物事件已替代旧独立formation按钮，起始检查按真实事件按钮完成，不削弱战斗胜利与编队恢复断言。

实际浏览器127.0.0.1:8767核对地图选区切换、资源路径、路径拐点说明与配置指南；不保存或改动用户布局。GUI截图 `.godot/campus-flow-{library,region_b,region_c}-{1280x720,1920x1080,1920x1200}.png`，原主线五站截图 `.godot/campus-flow-main-five-stops-2560x1440.png`，已查看并在对话展示；本地验收缓存不入库。

边界：五／12站是明确的原内容夹具，五站遍历由测试设置胜利／领奖标记，不代表自然胜率；真实10战另由起始检查模拟。预览不执行战斗／发奖励／读写玩家存档。仅按站次前进、分叉后相邻层互通，未提供任意有向图。检查器组件按钮与插件导入已验，未逐字段鼠标录入原生Inspector；Web导出、触控和真人编辑可用性未验。负责人要求不做旧Journey兼容，当前schema2，旧活动探索需通过已有重开入口开始。


## 地图编辑器侧栏分区

2026-10-09，基线 `b764964` 加工作树；PowerShell7／Node，本轮只调整浏览器地图编辑器的面板布局。`node --check tools/campus-map-editor/editor.mjs` 语法通过；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs` 为11／0，覆盖原几何、读取、隔离保存／备份与并发保护。

真实浏览器 `http://127.0.0.1:8767/` 实际视口1280×720：选区显示顶点和属性；拐点只显示当前选区与点操作；亮区三态亮度控件同屏；地标显示名称／坐标与折叠的新建区。实际加点6→7、删点7→6恢复干净状态，输入地标名称后显示未保存、撤销恢复原名称和保存禁用；未保存到项目布局文件。取坐标自动展开置顶，画布中心拾取 `x=900, y=750`，复制／清除可用且保存仍禁用；退出回到折叠辅助区。Enter可展开关联地标和流程指引，展开后侧栏滚动276，切换拐点复位0。编辑页控制台错误0。用户 `expanded_campus_layout.json` SHA256前后一致。

必要实际截图为 `.godot/map-editor-sidebar-{area,path,boundary,place,coordinates}-1280x720.jpg`，拐点与亮区画面已查看，拐点截图在对话展示；验收缓存不入Git。尺寸覆盖限于实际1280×720：浏览器视口覆盖参数未生效，不能把尝试的900×720当作验收尺寸。未验触控；本轮未改Godot运行规则，不重复无关战斗／流程检查。


## 地图保存权限修复

2026-10-09，基线 `7d8f102` 加工作树；PowerShell7／Node22.17.1。真实根目录的POST保存检查修复前两次500，精确复现 `.editor-tmp` 写入EPERM；同一请求在正常执行环境两次200并恢复原文件。核验 `/api/health` 的应用ID／项目根及进程命令行后，重启8767后台服务；仅重启服务，不刷新用户编辑页、不改ACL。

`node --check tools/campus-map-editor/server.mjs` 通过；`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs` 为12／0。新增Windows只读临时文件夹具：修复前返回原始EPERM导致恢复提示断言失败，修复后提示包含不可写／重启／导出；原地图及保存前备份与原字节一致。其余几何、读取、坏数据／过期版本拒绝、隔离保存及备份原检查保留。Windows夹具在其他系统跳过，不宣称跨平台权限检查。

真实浏览器1280×720在独立验证页修改选区名称，点击保存后显示已同步／保存成功，并核对真实JSON写入与备份；撤销到原名称并再次保存也成功，控制台错误0。最终用户 `expanded_campus_layout.json` SHA256为 `C3C5665C66C8FC0C567AA1A9EB91DAD9479C4A3481EA8B019886F5CCDDA55292`，与验证前一致，用户已有未提交布局修改保留。实际截图 `.godot/map-editor-save-fixed.jpg` 已查看并在对话展示，本地缓存不入Git；临时复现脚本在收尾删除。只改工具后端失败提示并恢复当前服务运行权限，未改Godot规则，未重复无关战斗测试。

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
