# 界面验证

战斗状态、播放、产码、层级与页面清理的最新2026-10-10联合结果统一引用[战斗验证](../combat/verification.md#人物与战斗表现)，不复制表格。

## 选择子页

原场景scenes/expedition/choice_pages_check.tscn、choice_semantics_check.tscn；页面清理另用scenes/expedition/screen_cleanup_check.tscn。上述选择页场景使用GUI -- --capture，覆盖多轮节点、禁用原因、回退、真实奖励归属与原存档恢复。最新主线choice_pages197／0、清理52／0；语义专项曾214／0。隔离夹具支持损失等显示类型，不证明这些效果已经新增进主线。

## 菜单、图鉴与暂停

tools/development/tests/menu_runtime_check.tscn参数-- --test-size=1920x1080（另2560x1440、1920x1200）验证六背景和恢复状态；窗口显示名取“校园异闻”，工程元数据仍保留原身份。scenes/menu/menu.tscn -- --codex-check验证暂停图鉴与恢复；闪卡集合与详情另见[美术验证](../art/verification.md)。

三桌面尺寸实际截图有既有证据；手机、实体手柄、任意极端拥挤和当前Web仍待验证。美术接入状态见对应对象说明和Manifest，不由断言升级。

## 地图与下一站导览

2026-10-13，基线`d042663`＋完整地点节点修正，Godot4.7.2 Compatibility原生窗口。导航专项511／0、地图专项220／0、原Campaign149／0、流程资源120／0、地图编辑器几何／布局6／0。页面清理52／0继承本分支已有结果，本次退出由导航专项覆盖。分支art/campus-navigation-ui从main `2d7cda7`创建，负责人授权调整后squash合入main。

隔离profile的原Campaign控制器通过实际鼠标、方向键、Enter操作，覆盖1920×1080、2560×1440、1920×1200、1280×720。先选择区域，再展开5／5／6个地理地点节点；逐个点击验证边框、名称、图片，校验实验大楼(925,740)以及会堂hall／商业街shopping。三态外观不改选区，悬停不替换点击信息，滚轮／拖动不误选择，拖动后键盘仍可用。展开和返回交接焦点，主要动作／圆形节点／卡片在视口内。

“开始探索”进入原开局策略，策略后才启动Journey；下一站显示完整路线，当前候选可前往，后续地点可查看但禁用前往，原快照保持不变。会堂与商业街分别显示详情，但两个按钮共用enter:0并进入原end_c，不新增故事站次。确认进入地点／返回基地移除旧导航；日间地图、节点与详情使用正式daily素材。守卫／奖励标记与复合终点站次是UI夹具，不证明实际打赢战斗；原战斗、保存与恢复由Campaign回归覆盖。另核验精确旧占位快照使用实时校正，而手工自定义偏移继续有效。

在项目根使用PowerShell7，$godot指向Godot4.7.2 console.exe；日志使用.godot/art-workflow/navigation-ui下绝对路径：

```powershell
& $godot --path . --rendering-method gl_compatibility res://scenes/expedition/campus_navigation_check.tscn -- --capture
& $godot --path . --rendering-method gl_compatibility res://scenes/expedition/expanded_campus_preview.tscn -- --expanded-map-check
& $godot --headless --path . res://scenes/expedition/expedition.tscn -- --campaign-flow-check
& $godot --headless --path . res://scenes/content/campus_flow_preview.tscn -- --flow-preview-check
node --test tools/campus-map-editor/editor-core.test.mjs
```

截图位于.godot/art-workflow/navigation-ui：region-{0,1,2}-*、map-selection-*、next-station-*、next-station-day-*以及compound-next-station-1280x720.png，不入Git。已查看真实全路线图、实验大楼、拆分会堂商业街、深浅地图和四尺寸画面；节点使用深色隔离边／白环／选中暖黄双环与勾号，密集节点上方名称避让，透明按钮边距不挡邻居。位置只随地图移动或控件尺寸事件更新，不每帧轮询Journey。原地图专项仍覆盖三态宽底图、亮区、缩放平滑／拖动／复位和投影；三态底图与亮区参数不变，只调整地标和地点资源。

已知边界：未确认微地点仍为原暂定偏移，不能把正确绑定配置当作全部实地定位；会堂和商业街共用既有复合地点背景，不伪造两套独立素材。根证书／shader缓存权限和旧Kenney读图告警为已有环境边界，无Script／Parse错误；Web、移动端、实体手柄、任意拥挤长内容和色觉障碍用户体验未验。既有美术资产审批状态不因本轮原生UI修改升级。


2026-10-15地图数据校正及校验，基线742de3d：三区各六个地理节点与编辑器关联地标、名称和坐标一致，教学南门不再进入正式路线；旧固定出发／复合地点文案改读真实配置，内部gate和背景类型不决定地点。原四尺寸真实交互检查555／0，图已展示；当前格式存读档、旧格式拒绝、完整原战役及入口见[战役验证](../campaign/verification.md#地图路线一致性)。两个编辑入口仍分离，本次为一次数据对齐；旧坐标不纠偏。同站多地标交互仍复用原组件，资产批准状态不变；部分新对应的地点暂复用已有环境背景。

## Web 战斗中文字体

2026-10-16，基线 `c7184c6`＋本次修复，分支 `codex/fix-web-battle-fonts`，Godot 4.7.2 标准版、PowerShell 7。共用 Theme 默认改用随包的 `SourceHanSansSC-Medium.otf`，使战斗物品、破解预览、代码栏和下拉菜单不再依赖桌面系统字体回退。

在项目根执行，`$godot` 指向 `.godot/web-tools/engine/Godot_v4.7.2-stable_win64_console.exe`：

```powershell
& $godot --headless --path . --quit-after 500 --log-file .godot/art-workflow/battle-font-check/font.log res://scenes/battle_demo/battle_font_check.tscn
& $godot --path . --rendering-method gl_compatibility --quit-after 3000 --log-file .godot/art-workflow/battle-font-check/feedback.log res://scenes/battle_demo/battle_feedback_check.tscn -- --capture
pwsh.exe -File ./build-web.ps1
```

字体检查实例化原 Campaign 战斗，读取真实物品／程序说明、四类代码、按钮、下拉菜单和人物详情的实际解析字体，关闭测试字体的系统回退后逐字检查。旧字体112项中89项缺字；修复后112／0。原战斗反馈图形专项81／0，覆盖1920×1080、2560×1440和1920×1200的详情、键盘／鼠标操作与暂停。

本地 release Web 导出成功，正式 `/web/` 菜单→基地→继续探索→原战斗流程人工检查1280×720浏览器画面：四类代码名称、追踪破解／反冲护盾和代码补给说明正常，物品实际消耗成功；本次正式页面无脚本错误。浏览器截图保留在 `.godot/art-workflow/battle-font-check/web-after-program.jpg` 和 `web-after-item.jpg`，不入Git。Web release模板禁用场景路径覆写，浏览器验证使用正式入口；独立字体检查场景仅通过原生命令启动。

此证据仅覆盖本地桌面浏览器的文字与上述交互；线上Pages、手机真机与全流程平台验收仍沿用既有边界。

### 2026-10-16 单字体复测

`battle_font_check.tscn` 扩展至事件页 FontVariation 与教学标签，关闭 FontFile 及 FontVariation 基础字库的系统回退，115 项／0 失败。正式 Web 包仅保留思源字体，实际菜单、事件奖励页、教学卡、物品说明、破解目标与派遣／地图中文字形正常。发布包范围、截图与命令见 RELEASE-01 的单字体瘦身记录。

### 战斗布局收敛（2026-10-16）

基线05a41249＋本次布局实现。PowerShell 7运行Godot4.7.2：

```powershell
& $engine --path . res://scenes/battle_demo/battle_feedback_check.tscn -- --capture --demo-animations=formal
& $engine --path . res://scenes/ui/glossary_check.tscn -- --demo-animations=formal --demo-size=1920x1080
& $engine --path . res://scenes/expedition/tutorial_check.tscn -- --demo-animations=formal --demo-size=1920x1080
```

战斗85/0，覆盖1920×1080、2560×1440、1920×1200，真实键盘／鼠标释放与消耗、详情边界、底部区域不重叠、敌人预警与释放。术语30/0，覆盖暂停阅读、角色详情和羁绊链接；教学65/0，覆盖地图热点至首个解锁派遣与路线选择及“下一步”多帧点击。新布局下测试通过真实鼠标移出事件离开详情，不仅修改单个HUD内部指针。

截图：.godot/feedback-keyboard-1920x1080.png、feedback-overview-1920x1200.png、bonds-unit.png。实际画面已在对话展示；测试资源数量是QA设定，不代表常态满资源。

标准版 release Web 导出并通过 web_package_check.py 单字体检查。本地 layout-preview.html 仅向正式入口传入 --glossary-preview --preview，原生场景实例化原Campaign战斗，使用隔离验证存档；在1280×720浏览器查看生成图标、中文与暂停详情。未修改发布入口默认参数；不视为线上发布或手机验收。

Web补充：实际点击“漏洞”显示中文解释，预览检查0失败，截图 .godot/art-workflow/battle-layout/web.png。暂停预览中动态改变浏览器视口时，观察到部分敌人立绘与状态条位置短暂不一致；本轮未改角色渲染定位，尚未定位该问题，不把此结果表述为动态缩放完整验收。

### 战斗布局修订（2026-10-16，待评审）

基线f8f3f90a＋修订，开发分支art/battle-layout-revision；main回退05a41249，本版未合入。沿用上节三条图形验证命令：战斗97/0，术语30/0，教学64/0；新增底栏与战场分离、播放按钮不重叠且不超出底栏的三尺寸断言。另执行 `& $engine --headless --path . res://scenes/battle_demo/battle_font_check.tscn`，禁用系统回退后113/0，含播放符号字形。破解字体断言对应去除重复消耗后的实际正文，完整源描述仍检查字形。

实机截图：`.godot/feedback-layout-1920x1080.png`、`feedback-layout-2560x1440.png`、`feedback-layout-1920x1200.png`；画面已在对话展示。QA资源数量不代表正常战斗初始值。

使用标准版Godot4.7.2执行 `--headless --path . --export-release Web builds/web/index.html`；Python3执行 `tools/release/web_package_check.py builds/web/index.pck`，2205文件、1字体、521纹理、167370756字节、0失败。临时layout-preview.html沿用上节显式验收参数，1280×720实际浏览器画面显示新底栏、图标、中文与暂停详情，GLOSSARY_PREVIEW_READY failures=0，无浏览器error日志。截图 `.godot/art-workflow/battle-layout-revision/web.png`。未发布线上；上节暂停时动态改变视口的角色定位问题仍未修复，不升级动态缩放或移动端验收。

### 四槽与战斗信息反馈（2026-10-16，待评审）

基线a3c9a4a7，分支art/battle-layout-revision，四槽功能已本地提交347a06b8，后续反馈同分支；不合入、不推送。PowerShell 7／Godot4.7.2，复用上文$engine：

```powershell
& $engine --headless --path . res://game/combat/loadout_capacity_check.tscn
& $engine --path . res://scenes/battle_demo/battle_activity_check.tscn -- --demo-animations=formal
& $engine --path . res://scenes/battle_demo/battle_feedback_check.tscn -- --capture --demo-animations=formal
& $engine --headless --path . res://scenes/battle_demo/battle_font_check.tscn
& $engine --path . res://scenes/expedition/tutorial_check.tscn -- --demo-animations=formal --demo-size=1920x1080
& $engine --path . res://scenes/ui/glossary_check.tscn -- --demo-animations=formal --demo-size=1920x1080
```

结果分别4/0、16/0、100/0、128/0、64/0、30/0。容量专项用临时注册的第4个测试Resource验证上限，不新增正式技能；显示专项使用真实三种程序与一个空槽。真实施放反冲护盾、自然技能出手、日志超过4条保留、阅读暂停、程序冷却倒计时、缺码／无目标／可释放状态、已有协议缓冲说明、重试清空记录均有断言。三尺寸反馈另覆盖三类敌方特殊技能中央播报及释放结束，不改变模拟伤害。

截图：`.godot/activity-hack-shield.png`、`activity-personal-skill.png`、`activity-journal.png`，以及feedback-layout三尺寸与feedback-*-release系列；实际画面在对话展示。源码入口为battle_activity.gd、code_panel.gd、code_action_icon.gd、code_resource_chip.gd、pixel_battle.gd、hack_burst.gd、code_fx.gd。enemy_release补充原锁定center，仅供特效定位。

正式Web包单字体检查通过；浏览器1280×720实际查看白色任意代码、四槽、状态、单侧盾、中文与日志展开／收起，无error日志，GLOSSARY_PREVIEW_READY failures=0。截图`.godot/art-workflow/battle-activity/web.png`。该Web验收入口冻结模拟，不能据此宣称Web动态战斗全流程通过；技能运动由原生图形专项验证。未做线上发布、手机、实体手柄或真人平衡验收。

旧`code_rules_check.tscn`另有12项失败，包含旧takeover、旧追踪移盾与双目标修复等期待；将code_catalog临时换回a3c9a4a7后仍为47项／12失败，执行后按原始字节恢复。此旧检查未计入通过数，未在本轮重写其过时玩法期待。对照日志`.godot/code-rules-original-catalog.log`。原生Kenney直接读图告警仍属既有边界。

### 战斗反馈收敛（2026-10-16，待评审）

基线f15a603e＋本轮修订，沿用上节Godot4.7.2命令：activity22/0、feedback三尺寸100/0、font129/0、tutorial65/0、glossary30/0。新增断言覆盖零增益隐藏、反冲实际受益目标、中央最新播报与容量、日志时间与筛选、同目标同类飘字合并；原始日志不合并。日志为`.godot/polish-{activity,feedback,font,tutorial,glossary}.log`，实机截图沿用activity系列，已在对话展示。

标准版执行`--headless --path . --export-release Web builds/web/index.html`，Python3执行`tools/release/web_package_check.py builds/web/index.pck`：2218文件、1字体、522纹理、167576152字节、0失败。实际1280×720浏览器显示新顶部、四槽、中文详情；真实点击记录展开与重点／全部切换正常，空记录面板收缩，无浏览器error日志。截图`.godot/art-workflow/battle-polish/web.png`。Web验收预览冻结模拟，未宣称动态全流程通过；旧code_rules的12项失败、动态视口定位和真人可读性边界沿用上节。

破解状态辨识（2026-10-16，基线074eb48e）：沿用activity／feedback／font命令，结果24/0、100/0、130/0。新增实际缺码库存与不可用名称明暗断言，字体专项覆盖自绘状态短词。原战斗截图`.godot/activity-ready-target-dock.png`、`activity-hack-shield-dock.png`、`activity-missing-dock.png`分别展示可用与无目标、施放后的个人／共享冷却、缺码；仅裁取实际帧的底栏，未合成状态或改动正式数值。全部状态均可点击阅读，暂停释放限制沿用原逻辑。用尽为预留状态样式，本轮四种实际状态截图不含次数用尽。
Web补充：标准版正式导出成功，单字体包检查2218文件／1字体／0失败；实际1280×720浏览器核对缺码短词、费用缺口与暂停详情，未出现error日志。截图`.godot/art-workflow/hack-states/web.png`。其余动态状态由原生实机截图验证，未把冻结预览作为完整Web动态验收。
2026-10-16，基线5ba90b5d：按负责人要求将可释放勾号替换为绿色“就绪”，不改布局／判定。原生activity24/0、禁用系统字体回退的font130/0；实机截图activity-ready-target-dock.png已更新。本次仅文本替换，未重新导出Web。
2026-10-16，基线8a19a89d：状态底板细化，原生battle_activity_check（--demo-animations=formal）24/0，日志.godot/status-surface.log；就绪／无目标、冷却、缺码底栏实机截图已刷新。仅绘制调整，无字体／Theme资源改动，本次未重新导出Web。

### 顶部收紧与左右调速（2026-10-16）

基线d89dcbe4。Godot4.7.2／PowerShell7，`--path . scenes/battle_demo/playback_controls_check.tscn -- --capture --demo-animations=formal`：63/0，覆盖三尺寸实际点击、暂停菜单、上下限重复点击不循环、速度组与暂停按钮等宽。原feedback三尺寸100/0、glossary30/0、font136/0；tutorial追踪全流程83/0，教学高亮读取speed_up实际边界。命令沿用上节对应场景，日志`.godot/compact-{playback,feedback,glossary,font,tutorial}.log`。截图`.godot/playback-half-speed-1920x1080.png`及其他两尺寸，已在对话展示。羁绊名称／人数拆列后仍可实际点击术语查看说明。
Web补充：正式导出成功，单字体包2218文件／1字体／167585736字节／0失败。实际1280×720浏览器点击右侧+从1.0到1.5，再点击左侧−回到1.0；顶部、羁绊双列和中文正常，无error日志。截图.godot/art-workflow/compact-hud/web.png。预览冻结模拟，仅声明控件显示与点击验收，完整动态教学与选人仍以原生检查为证。

## 友敌人物卡与上半区整理

2026-10-17，基线 `10bedf08`，分支 `art/battle-hud-polish`。PowerShell7／Godot4.7.2标准版，`$engine` 为 `.godot/web-tools/engine/Godot_v4.7.2-stable_win64_console.exe`：

```powershell
& $engine --path . --rendering-method gl_compatibility res://scenes/battle_demo/battle_hud_polish_check.tscn -- --capture --demo-animations=formal
& $engine --path . --rendering-method gl_compatibility res://scenes/battle_demo/status_hud_check.tscn -- --demo-animations=formal
& $engine --path . --rendering-method gl_compatibility res://scenes/ui/glossary_check.tscn -- --demo-animations=formal --demo-size=1920x1080
& $engine --headless --path . res://scenes/battle_demo/battle_font_check.tscn
```

人物卡专项84/0：真实鼠标操作双方状态条、敌人意图、展开技能／装备差异、Esc、阅读暂停及退出，覆盖1920×1080、2560×1440、1920×1200、1280×720。原状态HUD111/0、术语32/0、禁系统字体回退145/0。状态夹具更新为当前2×2代码布局和标准事件快照。截图 `.godot/art-workflow/battle-hud-polish/{ally,enemy}-detail-*.png` 已实际查看并展示，不入Git。原生真实鼠标验证需有桌面输入权限；沙箱受限运行出现交互假失败，相同原码／新版在相同桌面权限下通过。既有Kenney读图警告保留，无Script／Parse错误。手机、实体手柄及本轮Web布局尚未验收。

顶部排布增量（基线6044cca2）：上方专项108/0；同引擎运行 `res://scenes/battle_demo/battle_activity_check.tscn -- --demo-animations=formal` 24/0，以及 `res://scenes/battle_demo/battle_feedback_check.tscn -- --capture --demo-animations=formal` 100/0。四尺寸新增时钟／完整羁绊、预警／记录分区和日志流式排布断言；原专项继续覆盖三种敌方实际预警与释放。截图 `.godot/art-workflow/battle-hud-polish/top-journal-*.png` 已展示；底部操作区和原战斗规则保留。Web与移动端此时尚未验。

最终技能名称框与整体回归（2026-10-17，基线c8f68b78＋本次实现）：`battle_hud_polish_check.tscn -- --capture --demo-animations=formal` 231/0，包含自然普通施法开始／释放、长于旧超时的敌方预警、死亡取消、读条暂停、重试与简化特效；八人同时施法使用真实模拟_start_cast入口的QA夹具，检查名称数量、相互分离、真实状态边界和顶部／底栏安全区，不代表常态八人同时施法。

原活动24/0、反馈100/0、播放63/0、教学96/0、术语32/0。沿上文引擎，播放场景为 `res://scenes/battle_demo/playback_controls_check.tscn -- --capture --demo-animations=formal`，教学为 `res://scenes/expedition/tutorial_check.tscn -- --demo-animations=formal --demo-size=1920x1080`。另执行 `--headless --path . res://game/combat/cast_check.tscn` 72/0；双方动态人物卡及名称禁系统字体回退检查254/0。没有Script／Parse错误，既有Kenney读图和受限环境根证书告警不计作玩法错误。

`pwsh.exe -File ./build-web.ps1`正式导出成功，`py -3 tools/release/web_package_check.py builds/web/index.pck`：2222文件、1字体、522纹理、167604852字节、0失败。临时hud-preview.html由正式index.html复制，仅显式传入既有 `--glossary-preview --preview` 参数；HTTP服务仅监听127.0.0.1。1280×720浏览器实际Esc关闭破解详情、点击敌人意图打开共享人物卡，GLOSSARY_PREVIEW_READY failures=0，error日志为空。截图 `.godot/art-workflow/battle-hud-polish/web-enemy.jpg` 已展示；未发布线上、未测手机。Web预览冻结模拟，不能将此结果升级为Web动态战斗全流程证据。

四尺寸 `skill-windup-*.png`、1920×1080的 `skill-release`／`enemy-windup`／`skill-interrupted`／`simultaneous-casts` 和统一人物卡／top-journal截图均在同一忽略目录，已查看关键实机画面。普通8人样本名称分离通过；任意长内容／极端聚集仍属于最小遮挡退让，不承诺无限空间。分支只作本地提交，不合入、不推送。

右下播放分组反馈修订（2026-10-17，基线43cd464c）：沿本节引擎运行playback_controls_check（--capture）72/0、battle_hud_polish_check（--capture）复测239/0；覆盖原三尺寸实际暂停、恢复、菜单、上下限和四尺寸时钟／状态属于底栏、时钟在播放按钮上方。首次连续窗口运行有8条关闭卡片断言失败，同码独立图形复测0失败；未据此修改关闭规则，保留更详细失败状态便于后续追查。截图 `.godot/playback-paused-*.png` 已查看并展示。字体与Web将随本轮剩余视觉反馈统一复验。

技能框宽度与关闭稳定性（基线b4fb5ea5）：同命令运行battle_hud_polish_check，255/0。新增8个实际字宽＋图标留白断言、8个Esc后同位置鼠标移动不重开断言；定位并修复上文偶发卡片重开问题，关闭抑制保持至实际移出刚关闭单位，再次点击仍可重开。截图simultaneous-casts及skill-windup四尺寸已展示。

## 伤害数字与来源图标

2026-10-17，基线6d9041d3加最终两类修订，功能分支art/battle-hud-polish；负责人明确要求整包squash合入main。PowerShell7／Godot4.7.2标准版，$engine沿上节：

```powershell
& $engine --headless --path . res://scenes/battle_demo/damage_feedback_check.tscn -- --source-only
& $engine --path . --rendering-method gl_compatibility res://scenes/battle_demo/damage_feedback_check.tscn -- --capture --demo-animations=formal
```

源专项22/0：真实普攻／技能、追加队列、追踪破解、反冲爆炸及远程弹道命中正确携带两类类别；is_followup独立于类别，新增展示字段不改变扣血、产码或战报program_effect归属。图形专项331/0，覆盖1920×1080、2560×1440、1920×1200、1280×720：仅两类后缀、两类追加均有更小的“追击！”、完整小字计入避让、当前样本避开人物头部与上下信息区、生命／吸收／治疗配色、同类同标记合并和不同标记分离、全盾吸收与血盾混合只标一次、暂停、简化特效、到期及重试清理。样本先明确移出阅读区，再固定到0.12模拟秒，避免真实鼠标位置令原生与Web采样到不同动画时点。原生截图damage-categories-*.png、damage-category-legend-1920x1080.png位于.godot/art-workflow/battle-hud-polish/，已查看并展示。两类同时受击使用原_event／_resolve入口布置QA样本，不代表自然战斗必然同时发生，也没有新增运行时玩法。

图形回归battle_hud_polish_check255/0、battle_feedback_check100/0、status_hud_check111/0、battle_activity_check25/0、playback_controls_check72/0，均以--capture --demo-animations=formal运行；tutorial_check（--demo-animations=formal --demo-size=1920x1080）96/0、glossary_check同参数32/0。人物卡专项的shot辅助函数无论是否保存截图都等待实际绘制，避免未带--capture时读取旧name_bounds。禁系统字体回退battle_font_check259/0，覆盖图例和自绘追击小字。原模拟cast_check72/0、chain_check37/0、pierce_check34/0、battle_report_check39/0。最终日志为同目录categories-native-final、categories-source、categories-*，无Script／Parse错误；既有Kenney直接读图和受限环境证书告警保留。

`pwsh.exe -File ./build-web.ps1`正式release导出成功；`py -3 tools/release/web_package_check.py builds/web/index.pck`为2226文件／1字体／522纹理／167624132字节／0失败。临时categories-preview.html复制最终正式index.html，仅显式传入`--damage-feedback-preview --preview`；由菜单进入同一验收场景，实例化原Campaign，使用隔离测试存档。HTTP仅监听127.0.0.1。1280×720实际浏览器DAMAGE_PREVIEW_READY checks=93 failures=0，最终重新加载后的error日志为空，开关记录正常，截图web-categories.jpg已展示。长标记补障碍物边缘候选后，原生与Web同一时点均通过头部避让断言。Web为冻结预览，只确认实际包中文字、布局、图标及记录交互；完整动态生命周期以原生证据为准，未声明动态缩放、手机或实体手柄验收。
