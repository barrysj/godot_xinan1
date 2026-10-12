# CORE-02 · 校园战役、教学与结局

- 状态：部分实装；战役机制有桌面工程证据，纪念内容和发布验收未完成
- 统筹：2026-10-10，代码核对基线 `d99750b`；以下运行结果继承已登记验证，本次目录整理不重新宣称玩法通过。

## 当前能力

新档经过序章、一次立即完成的教学派遣、三个可任选顺序的区域、三台记忆终端与三阶段终局。地点守卫胜利＋领奖后主动离开；临时伙伴在区域成功时永久兑现。重复结算不刷终端或人物。最终恢复校园并开放重看。

战役选路复用完整校园图；15处区域地点绑定与12张外景共用热点和详情。图书馆有三态三视角室内，原照片资源仍须真实资料。基地使用紧凑原生控件和既有背景，不再维护历轮布局说明。

## 实现与契约

`game/meta/campaign_state.gd` 与 `campus_progress.gd` 维护永久事实和原子交易；`game/run/campaign_journey.gd`、`campaign_checkpoint.gd`、`location_visit.gd` 维护访问／奖励／战前快照；`resources/campaign/` 配置站次、分支与显示；`scenes/expedition/campaign_hub.gd`、`campaign_panel.gd`、`campaign_route_map.gd`、`exploration_board.gd` 复用原玩家流程。

设定归[设计](design.md)，使用归[游玩说明](play-guide.md)，录入归[流程配置](flow-authoring.md)，地图空间归[布局](map-layout.md)，保存归[SAVE-02](../progression/save-02.md)。

## 验证与边界

最近整合证据：2026-10-10，地图回退 `ed4d275`＋人物 `c3dc5c2` 合并树，完整战役149／0、流程资源120／0、Debug174／0；2026-10-09流程配置专项GUI154／0、地点134／0、双队伍GUI151／0。入口和覆盖见[本领域验证](verification.md)。

三个区域名称／落点、人物与系统故事仍有样本内容，未达到真实纪念内容验收。60～90分钟和真人上手尚未实测；当前Web包、移动端、实体手柄未按最新版本验收。Journey只支持schema2，旧活动战役需重开，永久profile保留。

2026-10-13，`d042663`＋完整地点导览修正，原Campaign回归149／0、流程资源120／0；入口与定位边界见[地图导览验证](../ui/verification.md#地图与下一站导览)。两个会堂商业街地理图标共用一个探索站点，不改变保存schema或战斗门槛；仅精确旧占位坐标使用实时地标纠正。

## 地点多场景与小地图（待统筹）

2026-10-11，基线 `78bb5b8` 加本次修订：已实装并通过桌面专项。所有地点共用 CampusPlaceScene 数组配置，原单背景可留空兼容；图书馆接入中庭、书架区、窗边走廊、馆前广场四张既有图。原探索界面提供随内容收拢的“探索场景”栏与可点击小地图，没有上一处／下一处按钮；小地图用颜色／楼层文字／当前圆环表示位置，支持全部与单层筛选。门形通行热点顺序前往后续场景，末场景离开地点回路线图，区域末站及教学沿原结束流程。现用 UI asset_002 已按用户明确豁免审批的授权制作、登记和接入；封锁出口有置灰、锁图形与原因提示。

入口：`game/content/campus_place_scene.gd`、`game/run/place_scenes.gd`、`campaign_journey.gd`、原 `campaign_hub`／`campaign_panel`／`exploration_board`、`place_scene_navigation.gd` 和 `passage_hotspot.gd`。续用原检查点，场景切换不重抽访问、推进路线或绕过守卫；事件期间禁止切换，保存失败回到原场景。配置和保存契约见 [区域配置](flow-authoring.md#地点内多个场景)。

验证：`place_scenes_check.tscn` 无头 88／0、三尺寸 GUI 208／0；完整战役 149／0；继承前版全地点遍历 61／0、区域流程 JSON／配置检查 120／0。日期、完整命令、截图位置与覆盖见 [验证页](verification.md#地点多场景与小地图)。资源台登记 missing／mismatch／errors 均为 0。

待统筹影响：地点内容模型及原 Journey2 的可选快照字段扩展；现行旧 Journey2 保留原冻结定义和单图，新的场景配置从新探索生效，不要求重置永久档。已统筹快照与 Roadmap 本次不改。边界：其他地点尚未补齐多张背景；图书馆坐标／楼层是玩法示意，非真实测绘。不支持自定义门锁或导航寻路；Web、手机与实体手柄未验。

2026-10-11，基线 `e4da771` 后的探索优化：原生 Godot 2D 布局 `.tscn`＋Marker2D 可拖动热点与通道；CampusPlaceScene.Layout 冻结位置到原检查点。图书馆按中庭伙伴、书架记忆、走廊终端、广场守卫分房间显示，地点进度继续共享。切换复用现有画板，保留筛选／有效焦点；增加短转场、按压回弹、详情淡入、完成／解锁提示和低音量程序化提示音，时长读取既有动画 Token。小地图文字加大、当前位置白环、悬停联动及实际顺序通路；底部离场／回基地降为次级按钮。编辑步骤与边界见[原生布局录入](flow-authoring.md#在-godot-中拖动热点与通道)。新增实现入口：`game/content/exploration_layout.gd`、`exploration_marker.gd`、`resources/campaign/layouts/library/`、`scenes/expedition/exploration_feedback.gd`。验证结果归本领域验证页，待统筹合入能力快照。

2026-10-13，按负责人要求将 `art/location-scenes` 的三个功能提交 squash 整合到 `main` 基线 `301b838`。保留地图导览的完整地点节点、点击详情、当前站次权限、实验大楼地标及会堂／商业街共用站点；离开地点回到最新下一站导览。整合检查覆盖场景与地图导览的衔接，结果见下述验证页；待统筹同步高层能力快照。
