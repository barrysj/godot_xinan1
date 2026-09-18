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
