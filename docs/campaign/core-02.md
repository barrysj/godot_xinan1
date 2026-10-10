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
