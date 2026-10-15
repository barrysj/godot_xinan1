# CORE-02 · 校园战役、教学与结局

- 状态：部分实装；战役机制有桌面工程证据，纪念内容和发布验收未完成
- 统筹：2026-10-10，代码核对基线 `d99750b`；以下运行结果继承已登记验证，本次目录整理不重新宣称玩法通过。

## 当前能力

2026-10-16 地图加载修复（main 基线 `c7184c6`）：已实装并验证底图异步预读／跨实例缓存、预生成圆形节点缩略图、选择区域后平滑聚焦与持续亮区。图书馆配置改为背景路径，修复 Web 导出排除原图后整条路线无节点的问题，仍沿原 Journey／场景／存档流程。入口为 `expanded_campus_map.gd`、`expanded_campus_preview.gd`、`campus_route_nodes.gd`、`campus_place_scene.gd` 与 `exploration_layout.gd`。

桌面与本地 release Web 专项均67项／0失败，原地图四尺寸555／0、地点场景94／0、流程资源120／0。执行命令和测量口径见[地图加载验证](verification.md#地图加载与-web-图书馆)。待统筹：地图加载能力与 Web 图书馆局部验收已更新；未覆盖线上部署、手机真机或全部 Web 战斗。

新档经过序章、一次立即完成的教学派遣、三个可任选顺序的区域、三台记忆终端与三阶段终局。地点守卫胜利＋领奖后主动离开；临时伙伴在区域成功时永久兑现。重复结算不刷终端或人物。最终恢复校园并开放重看。

战役选路复用完整校园图；15处区域地点绑定与12张外景共用热点和详情。图书馆有三态三视角室内，原照片资源仍须真实资料。基地使用紧凑原生控件和既有背景，不再维护历轮布局说明。

## 实现与契约

`game/meta/campaign_state.gd` 与 `campus_progress.gd` 维护永久事实和原子交易；`game/run/campaign_journey.gd`、`campaign_checkpoint.gd`、`location_visit.gd` 维护访问／奖励／战前快照；`resources/campaign/` 配置站次、分支与显示；`scenes/expedition/campaign_hub.gd`、`campaign_panel.gd`、`campaign_route_map.gd`、`exploration_board.gd` 复用原玩家流程。

设定归[设计](design.md)，使用归[游玩说明](play-guide.md)，录入归[流程配置](flow-authoring.md)，地图空间归[布局](map-layout.md)，保存归[SAVE-02](../progression/save-02.md)。

## 验证与边界

最近整合证据：2026-10-10，地图回退 `ed4d275`＋人物 `c3dc5c2` 合并树，完整战役149／0、流程资源120／0、Debug174／0；2026-10-09流程配置专项GUI154／0、地点134／0、双队伍GUI151／0。入口和覆盖见[本领域验证](verification.md)。

三个区域名称／落点、人物与系统故事仍有样本内容，未达到真实纪念内容验收。60～90分钟和真人上手尚未实测；当前Web包、移动端、实体手柄未按最新版本验收。Journey只支持schema2，旧活动战役需重开，永久profile保留。

2026-10-13，`d042663`＋完整地点导览修正，原Campaign回归149／0、流程资源120／0；入口与定位边界见[地图导览验证](../ui/verification.md#地图与下一站导览)。两个会堂商业街地理图标共用一个探索站点，不改变保存schema或战斗门槛；落点只按资源的 Landmark／Offset 计算。

## 地点多场景与小地图（待统筹）

2026-10-11，基线 `78bb5b8` 加本次修订：已实装并通过桌面专项。所有地点共用 CampusPlaceScene 数组配置，原单背景可留空兼容；图书馆接入中庭、书架区、窗边走廊、馆前广场四张既有图。原探索界面提供随内容收拢的“探索场景”栏与可点击小地图，没有上一处／下一处按钮；小地图用颜色／楼层文字／当前圆环表示位置，支持全部与单层筛选。门形通行热点顺序前往后续场景，末场景离开地点回路线图，区域末站及教学沿原结束流程。现用 UI asset_002 已按用户明确豁免审批的授权制作、登记和接入；封锁出口有置灰、锁图形与原因提示。

入口：`game/content/campus_place_scene.gd`、`game/run/place_scenes.gd`、`campaign_journey.gd`、原 `campaign_hub`／`campaign_panel`／`exploration_board`、`place_scene_navigation.gd` 和 `passage_hotspot.gd`。续用原检查点，场景切换不重抽访问、推进路线或绕过守卫；事件期间禁止切换，保存失败回到原场景。配置和保存契约见 [区域配置](flow-authoring.md#地点内多个场景)。

验证：`place_scenes_check.tscn` 无头 88／0、三尺寸 GUI 208／0；完整战役 149／0；继承前版全地点遍历 61／0、区域流程 JSON／配置检查 120／0。日期、完整命令、截图位置与覆盖见 [验证页](verification.md#地点多场景与小地图)。资源台登记 missing／mismatch／errors 均为 0。

待统筹影响：地点内容模型及原 Journey2 的可选快照字段扩展；现行旧 Journey2 保留原冻结定义和单图，新的场景配置从新探索生效，不要求重置永久档。已统筹快照与 Roadmap 本次不改。边界：其他地点尚未补齐多张背景；图书馆坐标／楼层是玩法示意，非真实测绘。不支持自定义门锁或导航寻路；Web、手机与实体手柄未验。

2026-10-11，基线 `e4da771` 后的探索优化：原生 Godot 2D 布局 `.tscn`＋Marker2D 可拖动热点与通道；CampusPlaceScene.Layout 冻结位置到原检查点。图书馆按中庭伙伴、书架记忆、走廊终端、广场守卫分房间显示，地点进度继续共享。切换复用现有画板，保留筛选／有效焦点；增加短转场、按压回弹、详情淡入、完成／解锁提示和低音量程序化提示音，时长读取既有动画 Token。小地图文字加大、当前位置白环、悬停联动及实际顺序通路；底部离场／回基地降为次级按钮。编辑步骤与边界见[原生布局录入](flow-authoring.md#在-godot-中拖动热点与通道)。新增实现入口：`game/content/exploration_layout.gd`、`exploration_marker.gd`、`resources/campaign/layouts/library/`、`scenes/expedition/exploration_feedback.gd`。验证结果归本领域验证页，待统筹合入能力快照。

2026-10-13，按负责人要求将 `art/location-scenes` 的三个功能提交 squash 整合到 `main` 基线 `301b838`。保留地图导览的完整地点节点、点击详情、当前站次权限、实验大楼地标及会堂／商业街共用站点；离开地点回到最新下一站导览。整合检查覆盖场景与地图导览的衔接，结果见下述验证页；待统筹同步高层能力快照。

主工程合入新增地点场景后，首次命令行运行须先完成目标checkout的Godot脚本类型与SVG导入；否则合法的scenes字段和图标preload也会解析失败。2026-10-13主工程缓存修复的启动与界面证据见[战役验证](verification.md)，执行步骤见[合并后本地导入](../development/verification.md#检出合并后的本地导入)。


## 地图路线一致性（2026-10-15，待统筹）

基线 `742de3d` 加本次修正。已验证：正式图书馆／主楼／体育场线的全部节点、文字、位置和区域归属与地图编辑器一致，南门独立为教学单站，三阶段终局使用图书馆核心。保留四站、原敌阵及强度；新增候选共享原站次内容，不增加每次探索的战斗场数。会堂／商业街仍共享一次访问。原地图 JSON 未改。

根因是编辑器布局与旧区域地点配置分离，三区域复用了教学南门；界面还有固定“从南门开始”文案，并将内部 `gate` 和所复用背景当作地点身份。实现入口：原 `CampusRegionFlow`／`CampusRoutePlace`、`campus_flow_rules.gd`／`campus_flow_catalog.gd`、`campus_presentation.gd`，区域资源及独立 prologue／finale 配置，原区域选择／下一站与地点界面。

地图编辑器与 Godot 路线编辑仍为独立入口；本次只是一次数据校正并增加一致性校验，没有统一编辑或自动生成站次。地图编辑器维护地标／选区／展示路径，Godot 维护 Stages／Choices／地点和敌阵；改变关联地标成员仍须手动同步 Godot 资源。校验负责报错，不能代替编辑。

按负责人要求不兼容旧探索：已删除旧模板迁移、旧占位坐标纠偏及复合地点推断。旧格式检查点按现有读取失败流程拒绝，不自动转换、覆盖或删除存档；当前格式照常保存与继续，不改写本次流程。新快照的地图契约与 JSON 类型归一化属于当前格式校验，启动预检能捕获遗漏、跨区地标及南门误接入。

自动化：`tools/development/tests/campus-map-sync.test.ps1`，GUI加 `-Capture`；349项地图／当前格式各阶段存读档与拒绝旧格式检查、120项原生配置、149项完整原战役通过。四尺寸真实导航结果和命令归[战役验证](verification.md#地图路线一致性)。地图编辑器读写与并发保护使用隔离端口验证，源布局 SHA-256 保持 `826e443c1b89ffe32f3147a87e4f848d8dac1b5da48a88fcdfe6010c95f037ee`。

待统筹影响：正式区域地理候选及名称与现有编辑器对齐，教学／终局用途分开；不迁移旧探索，没有重建探索、战斗或存档。部分新对应地点复用已有背景，尚无独立建筑美术；站次线不等同道路测绘，未验证手机／Web／实体手柄或真人平衡。总览与 Roadmap 保持原统筹快照。

## 两人出发与途中会合（待统筹）

2026-10-14，基线3d9a29f后改动：新普通探索只拥有所选两人，第二、第三节点进入时各选择一名出发时已解锁、尚未入队的同伴。人数2→3→4→4，未选同伴不能进入下一场战斗；序章和终局保持四人。派遣角色资格同时用于出发和会合候选，下次新局生效。旧活动探索保留原规则，新ShortRun schema9复用原检查点，失败写入回滚，非本局角色不能部署开战。人物交谈不再给新局隐式加人。

入口：原campaign_hub、ShortRun、campaign_checkpoint、deployment_panel；权威数值与具体规则见combat/rules.md。party_progression_check.tscn无头和1920×1080 GUI均97项／0失败，真实模拟两条推荐队各完成四站，同时覆盖候选冻结、坏档、重复选择、保存失败回滚、待选会合续玩与四人终局。截图.godot/party-departure-*.png、party-meeting-*.png、party-formation-*.png；命令见战役验证页。此阶段界面为功能接入版，后续美术包装仍在任务内。

## 可操作教学指引（2026-10-16，待统筹）

基线 `fb4febe` 加本次修改。已实装原主线按钮高亮、呼吸边框与箭头，入口 `scenes/expedition/tutorial_guide.gd`，由原 `campaign_hub.gd` 更新。覆盖南门热点／详情／阅读返回、守卫挑战、卡片选择与阵位、开战、手动暂停／恢复、四档速度、补给类型与使用、自然积码与破解确认、战报领奖／归属／出口、基地教学派遣、人员／免费出发准备委托／成果、校园地图选路和首次出发。提示卡放在目标旁边，保留真实按钮和原输入；支持点击与原拖拽编队，不增设平行教学战斗。

战斗操作步骤暂缓模拟，积码阶段放行原模拟；核心程序可用时暂缓并提示确认，成功破解后放行。代码来源和费用仍来自原战斗规则，不额外发币或改变敌方数值。补给引导根据队伍选择数据／权限类型；玩家另选类型时，积码超过10秒且热修复可用可教学热修复。可以跳过本次引导，菜单暂停与教学暂缓分离。战前重试重新提示，存档恢复按实际访问状态继续；首次区域出发将 `tutorial_route_selected` 写入原 campaign.story_flags，与检查点同事务提交。已有终端或完成标记的档不重复基地引导；不增加存档schema。

真实点击发现状态／人物详情可能抢走前景物品面板的输入，现由 code_panel.owns_pointer 明确前景区域，battle_inspector 与 unit_status_layer 避让。

验证：Godot 4.7.2 标准版，PowerShell7，`--path . --rendering-method gl_compatibility --log-file .godot/tutorial-analysis-verified.log res://scenes/expedition/tutorial_check.tscn` 追踪60项／0失败；同入口 `-- --protect` 护盾59项／0失败（路径分支导致计数不同）。覆盖真实鼠标点击、实际物品消耗／积码／破解、完整胜利及派遣交易、首条路线出发、完成标记重载、再次暂停恢复与跳过释放。实机截图 `.godot/tutorial-{hotspot,formation,item,hack,dispatch,route}.png`。原 `expedition.tscn -- --campaign-flow-check` 150／0，`battle_feedback_check.tscn` 69／0。Web验证随发布档案登记；真人上手、手机真机与实体手柄未验收。

待统筹：新玩家上手具备明确点击目标与操作停顿；总览和Roadmap保留原统筹快照。
