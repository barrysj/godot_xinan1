# ART-02 · 角色、粉笔精灵与配套特效及背景

> 持续功能档案；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：ART-02；所属系统：美术；状态：部分实装（既有六项仍为 review；M1 图书馆九张背景已批准并完成技术接入，视觉效果待人工评审）。
- 验证日期：2026-09-18；图书馆接入基线为 main `4389c1f` 加 `art/m1-asset-integration` 工作树，混合动画实现基线仍为 `56dc3aa`＋本档案同提交的 F 清理树。

## 玩家能力与接入范围

两名绘制角色、护盾特效、三张战斗背景，以及粉笔精灵七动作与粉笔弹体。M1 图书馆另有日常、夜间、异常三状态 × 三机位共九张正式背景，已通过正式路径接入现有探索页；主流程默认异常／中庭俯视，其他状态与机位保留为配置和预览入口。原六项保留已授权试接入；粉笔精灵 006 资产批准沿用任务记录，接入效果仍待人工评审。

## 实现与规则入口

- [Manifest](../../assets/art/asset_manifest.yaml)、[粉笔精灵正式包](../../assets/art/characters/chalk_spirit/)、[图书馆正式背景](../../assets/art/backgrounds/m1_library/)、[角色定义](../../resources/content/enemies/chalk.tres)。
- 图书馆运行映射：`scenes/expedition/exploration_skin.gd`、`exploration_board.gd`、`campaign_panel.gd`；环境接入不改变 `game/run/` 的访问、奖励或离场规则。
- 规则事实源：[战斗动画](../battle-animation.md)、[美术工作流](../art/WORKFLOW.md)、[粉笔精灵任务](../art/tasks/chalk-spirit.md)。
- 工具与完整验证矩阵见 [ART-03](art-03.md#骨骼序列帧通用生产与预览)，资源台见 [ART-05](art-05.md)。

## 混合动画资产包归一（已实装）

候选 006 与正式包共享 13 个运行文件：presentation.tscn 保存层级、枢轴、遮挡、部件与特效挂点；animations.tres 保存六种骨骼动作；battle_animation.tres 保存入口与七动作 SpriteFrames 回退；帧元数据、rig_manifest、三张图集和五张 parts 同包。

普通角色不附带专用播放脚本，共享控制器位于稳定工程路径。旧候选与正式专用脚本、旧场景和旧动画入口已删除。特殊扩展只有在 BattleAnimationSet 与 rig_manifest 同时登记脚本和原因后才允许提升。

正式 assets/art/characters/chalk_spirit/ 为批准候选的干净运行子集，不含版本目录、review、截图、生成记录、临时帧或专用工具。生成来源与评审证据留在候选和 Git。提升入口为 `py -3 tools/art/promotion/promote_animation.py chalk_spirit`，只校验时加 `--check`。

## 验证与证据

- 图书馆九张正式 PNG 均为 1672 × 941、RGB、不透明，与批准候选逐文件 SHA-256 一致；批准来源、状态组合和文件清单见图书馆任务。Manifest 登记 `asset_005_environment_set` 为 `selected + approved`，集成状态为 `authorized_active`，默认 `anomaly / atrium_down`，视觉评审仍为 pending。
- `--library-environment-capture` 真实运行通过 104 checks / 0 failures，覆盖九张正式图、三种状态、三种视角和三种桌面分辨率；既有 `--exploration-capture` 通过 132 checks / 0 failures，确认热点、详情、奖励、离开与恢复流程不受遮挡。
- Godot 增量导入后，候选直接复现、正式七动作、四个 Godot 专项均通过；九组帧率／倍速的事件与结算一致。
- 新旧逐节点对照、七动作 GIF、完整巡演、三分辨率预览与真实战斗截图通过；证据见粉笔精灵任务。
- 13 文件重复提升内容一致；正式依赖不引用 design/concepts；资源台 8 对象、101 登记文件，缺失 0、不一致 0。
- 继承历史证据 E10–E12、E19，重跑入口见[验证目录](verification.md)。技术通过不替代人工或手机端验收。

## 已知边界与统筹

006 已改为独立短周期分层，不再保存 96 秒曲线；跨周期及 600 秒时间点对照通过。资源 288,124 B／4,824 keys，详见 ART-03 的稀疏曲线修复。当前样本是刚性分层骨骼，不代表复杂蒙皮角色验收。

**待统筹**：共享控制器、正式包路径、确定性提升与资源台递归依赖校验已落地；需要统筹复核 ART-03／ART-05 和战斗表现边界。高层总览与 Roadmap 未在本功能任务改动。

**待统筹补充**：M1 图书馆九张背景已有 Godot 映射、默认状态和三分辨率接入截图；日常／夜间没有被虚构为游戏内自然时间系统，视觉效果仍需负责人人工评审，不能据此宣布最终美术验收完成。
