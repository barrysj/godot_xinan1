# META-02 · 资源派遣与永久解锁

- 状态：已实装并验证；2026-10-14，基线 932f72e 后的新分支改动。
- 入口：game/meta/dispatch_catalog.gd、game/meta/campus_progress.gd、scenes/expedition/dispatch_board.gd；原 campaign_hub 与 campaign_panel 主流程。

## 当前能力

基地右侧地图白板和派遣图标进入同一界面。默认校内，校外以缩放动画转到成都示意图；图书馆、体育馆、春熙路、沙河校区承载委托。后勤三名人员任选一人，无数值差别。资源一次扣除，永久解锁与未读成果同事务保存，重复执行无效。教学派遣免费开放出发准备和区域选择。

成长入口从主基地移除，原体能升级不继续出售。Profile 5 延续原原子存档；旧数值／设施购买退款，旧派遣兑现原约定成果，旧路线已开放则自动补出发准备资格。迁移后首次保存落为 v5，再次加载不重复退款。

功能、准备池、人物资格、物品出现池、规则buff五类已接入原玩家流程。出发准备见META-01，两人队伍与必定会合见CORE-02，物品池和每局一次刷新详见dispatch-map。派遣地图、白板、三名后勤、准备物品采用AI素材；准备与招募复用原玩家流程，最终验证见下。

## 验证

2026-10-14：dispatch_framework_check.tscn headless failures=0；覆盖扣费与解锁原子性、重复提交、失败回滚、未读成果恢复、旧升级退款与迁移幂等、准备点数及格子限制。GUI --capture 实际运行覆盖校内／市区／旅途／成果与原基地入口。只使用 .godot 下独立档。引擎根证书警告为环境既有问题，原像素图集另有导出警告；当前未宣称导出平台验证。

命令：Godot 4.7.2 --headless --path . --quit-after 300 res://scenes/expedition/dispatch_framework_check.tscn；GUI 移除 headless，添加 --rendering-method gl_compatibility 和用户参数 --capture --capture-size=1920x1080（另验 2560x1440、1920x1200）。

## 待统筹

成长／派遣经济已改变；本档案状态优先于旧高层快照。原主线全流程、效果消费与本次美术接入已验证；高层总览由统筹更新。

## 出现池与规则buff验证

2026-10-14，基线b748617后：dispatch_effects_check.tscn无头和1920×1080 GUI各25／0，覆盖派遣→下次新局→真实加权奖励池→原战斗库存、满库存过滤、准备池与掉落池独立、刷新后的候选和次数保存、写入失败回滚、重复动作拒绝、schema9不赠送迁移。实际奖励页截图.godot/dispatch-reward-refresh.png与dispatch-reward-refreshed.png；原道具奖励69／0、战斗内容51／0。此检查直接调用胜利奖励入口，不冒充完整战斗；完整战斗与战役证据分别见CORE-02、META-01。
## 本次整体接入收尾

2026-10-14，代码基线6a4b0be后的美术接入：dispatch_framework_check在1920×1080／2560×1440／1920×1200均0失败，含真实白板及图标鼠标点击、缩放中间态、派遣防连点、动画后结果层和底层锁定；preparation_check三尺寸0失败，出发／返回按钮完整可达。party_progression_check实际两条四战链95／0；starting_strategy_check GUI真实点击160／0；原expedition.tscn -- --campaign-flow-check为150／0。animation_check与presentation_check均PASS，资源台59对象／2106文件，missing／mismatch／errors均0。

美术源图、原始提示词、参考输入与Manifest已登记。分析员为绘制立绘沿原程序演出，不宣称完成逐帧动作；既有战斗特效、原生文字与控制按钮仍保留。验证为桌面Godot4.7.2，未进行Web／移动端导出或长期随机平衡测试。运行仍有既有根证书与旧像素fallback图集读取警告，没有脚本错误；原生完整流程正常退出。

## 城市底图分层修正

2026-10-14，基线e9b34ce：城市图采用asset_004，按地图参考区分一环、二环、三环及最外绕城；无地点缩略图。地点、道路文字和委托迁移到game/meta/dispatch_map.json；清水河标记同时驱动缩放及出发锚点。现有校园编辑器服务新增/dispatch页面，支持拖动、坐标／内容编辑、新增、停用、撤销／重做、导入／导出与校验保存。奖励身份稳定、教学入口受保护；移动委托不破坏未领取成果。导出预设已包含新JSON。

验证：Godot4.7.2、PowerShell7；dispatch_framework_check GUI在1920×1080、2560×1440、1920×1200均failures=0，覆盖缩放、往返、成果、基地双入口及编辑后存档兼容。dispatch_effects_check为25／0，preparation_check为0失败，party_progression_check为95／0；expedition.tscn -- --campaign-flow-check --order=012为150／0。具体运行方式见[派遣地图](dispatch-map.md#验证入口与范围)。node --test tools/campus-map-editor/dispatch.test.mjs tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs共17／0（服务端测试使用CAMPUS_MAP_EDITOR_PORT=8871）。浏览器实际修改名称和坐标、保存、拖动撤销、费用编辑撤销，重新启动游戏已读取保存后的清水河坐标。隔离API验证备份、并发409及不存在底图拒绝；未修改战役探索布局。

实际截图.godot/dispatch-city-各尺寸和.godot/art-workflow/chengdu-geography/editor.png已复核并在会话展示。运行保留既有根证书和旧图集fallback告警，无脚本错误。待统筹：派遣内容现已可视化编辑，取代旧“工具后续范围”的状态；不宣称GIS精度、移动端操作或平台导出验证。

## main合入兼容验证（2026-10-14，待统筹）

本分支7db24ce合入本地main 7146bb5，保留派遣输入隔离、两人出发及动态部署人数，并接入main的新启动器、调试整备和详细战报。战报的复苏与护盾统计适配见[COMBAT-03](../combat/combat-03.md)。dispatch_framework_check.tscn、dispatch_effects_check.tscn、preparation_check.tscn的GUI --capture均0失败（效果25项）；party_progression_check为111/0，原expedition.tscn -- --campaign-flow-check --order=012为150/0。地图编辑器dispatch、editor-core、server三组Node测试共17/0，服务端使用8871端口；文档链接检查0错误。截图与日志保存在忽略的.godot内，本轮实际展示两人队伍战报。沿用当前原玩家流程与存档，不重新引入固定四人或旧计时派遣。

## 校园地图与图形化派遣交互（2026-10-15，待统筹）

基线9f65717后的修正：校内采用asset_005，按项目真实校园底图构图重绘并校准图书馆、体育馆落点；不同底图保持自身比例。城市沿用asset_004地形，移除道路文字，地点按钮由引导线连接落点。地图区域滚轮连续缩小／放大和双指缩放可跨校内外切换；动画与成果窗口锁定缩放，详情区域滚轮不触发地图切换。保留按钮切换。

面板使用人员头像卡、奖励图标卡、资源图标与费用、简短派遣按钮；原子扣费和动画后结算规则不变。竖屏采用地图在上、详情在下及独立UI缩放。派遣编辑器按底图实际宽高比显示，归一化坐标契约不变。

验证：Godot4.7.2 / PowerShell7；dispatch_framework_check.tscn -- --capture 在1920×1080与900×1600均failures=0，覆盖实际滚轮、模拟双指触点、跨层切换、引导线端点、动画及结算输入隔离；截图.godot/dispatch-campus-对应尺寸.png、dispatch-city-对应尺寸.png。Node的dispatch.test.mjs和editor-core.test.mjs共11/0。桌面模拟触屏已验证，未验证实体手机或移动端导出。既有根证书、旧像素fallback告警仍存在，无脚本错误。

补充验证：最终布局在1920×1200同样0失败；浏览器实际切换校内并核对图书馆／体育馆落点与宽高比，无保存改动。

## 人员选择与白板边界修正（2026-10-15）

基线2c4c5c6：人员区由头像加独立名字按钮改为76逻辑像素高的整卡按钮，头像、文字和留白均可选择；ButtonGroup保证单选，保留键盘焦点。选中底色和边框持续显示，160ms柔和亮色反馈独立于状态更新，不刷新整个详情列表。滚动内容底部增加安全留白，避免奖励卡压住白板底框。

验证：dispatch_framework_check GUI在1920×1080、900×1600均0失败，新增逐张点击卡片边缘选择、选中保持及反馈归位检查；原派遣动画、结算与缩放隔离继续通过。截图.godot/dispatch-campus-对应尺寸.png。此次复用既有美术，未新增或替换资产；实体手机未验证。

## 人员槽位与选择弹窗（2026-10-15，替代上一版整排人员按钮）

基线998f487：默认空槽0/1，点击空槽打开人员列表，选人后显示头像和1/1，点击头像更换；不扩展多人派遣规则。取消／Esc保留原选择，不扣资源；空槽不可执行委托。弹窗阻止底层点击与缩放，Tab／上下焦点在名单与取消间循环，关闭回到槽位。原事务、派遣演出和结算保持不变。

入口scenes/expedition/dispatch_board.gd；asset_006空槽图按原UI风格生成，源提示词见design/concepts/ui/dispatch/asset_006/generation.json，登记于dispatch_board.yaml，review / authorized_active。此版替代整排人员按钮，不再以压缩名单作为主界面交互。

Godot4.7.2 / PowerShell7：dispatch_framework_check.tscn -- --capture及--capture-size=900x1600均failures=0；验证空槽、实际点击开窗、逐人选择／更换、Esc取消保留选择、零资源变动、弹窗输入隔离与原派遣闭环。实机截图dispatch-empty-slot、dispatch-staff-picker、dispatch-campus保存于.godot并在对话展示。Manifest校验22文件matched，missing/mismatch/errors均0。实体手机未验，沿用既有根证书及像素fallback警告；无脚本错误。

2026-10-15，基线d757def：人员槽位去除原生按钮重复边框，保留84×84点击范围及图标亮度反馈。dispatch_framework_check GUI 1920×1080为failures=0，空位／选人／取消／更换与原派遣闭环通过；实际截图dispatch-empty-slot-1920x1080.png。美术原文件未变，复核见派遣白板档案。

2026-10-15，基线479f6e3：人员空位换用asset_007薄轮廓／大人形加号图标，撤回旧厚框可读性通过判断。交互不变；dispatch_framework_check GUI 1920×1080 failures=0，实际截图dispatch-empty-slot-1920x1080.png；素材与源链见派遣白板档案，Manifest无缺失／错配。

## main squash整合验证（2026-10-15，待统筹）

将art/dispatch-campus-systems最终版本bfe834e整合到main基线1b8fa30。保留main的地图地标一致性、教学南门隔离及旧探索拒绝策略；三处战役文档冲突保留双方有效章节。未纳入功能工作区的expanded_campus_layout.json未提交修改及编辑器临时文件。

在实际主工程E:/Documents/works/godot_xinan1完成资源导入与验证：dispatch_framework_check GUI 1920×1080为0失败；dispatch_effects_check 25/0、preparation_check 0失败、party_progression_check 112/0、campus_map_sync_check 349/0、expedition --campaign-flow-check --order=012为150/0；Node dispatch与editor-core共12/0。全Manifest missing/mismatch/errors均0。首次导入的新增贴图暂不可用在导入完成后消失，最终无脚本解析／资源加载错误；仍有Godot关闭编辑器ADB设置及旧像素fallback告警。

实际派遣截图已在会话展示，日志归忽略的.godot/art-workflow/dispatch-main；只合入本地main，不推送远程。
