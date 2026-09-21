# ART-02 · 美术正式包与运行接入

> 持续功能档案；全项目判断由统筹维护[总览](../implementation-status.md)。

- 功能 ID：ART-02；所属系统：美术；状态：部分实装（既有六项仍为 review；M1 图书馆九张背景已批准并完成技术接入，视觉效果待人工评审；记忆终端已完成技术接入，效果待人工评审；十二处校园地点日常背景已提升为正式资产但尚未接入；首轮异常态强度过高、第二轮日光方向不符均已拒绝；24张配对4K重制进行中，12张日常新版及1张墨蓝灰天空异常校准图待评，余11张异常待扩展）。
- 验证日期：2026-09-22；校园配对4K与天空校准基线 `70105e7` 加当前工作树；图书馆接入基线为 main `4389c1f` 加 `art/m1-asset-integration` 工作树；混合动画实现基线 `56dc3aa`；记忆终端正式提升基线 `58f0291`；校园地点概念批准基线 `c858661`。

## 玩家能力与接入范围

两名绘制角色、护盾特效、三张战斗背景，以及粉笔精灵七动作与粉笔弹体。M1 图书馆另有日常、夜间、异常三状态 × 三机位共九张正式背景，已通过正式路径接入现有探索页；主流程默认异常／中庭俯视，其他状态与机位保留为配置和预览入口。原六项保留已授权试接入；粉笔精灵 006 资产批准沿用任务记录，接入效果仍待人工评审。

M1 三款记忆终端静态图标已作为同一个 `asset_011` 家族批准并提升到 `assets/art/icons/m1_memory_artifact/`；当前只有干净正式 PNG 和 Manifest 登记，尚未绑定区域或接入 Godot，因此不计入玩家当前可见能力。

M1 校园地点十二个已批准概念及 `asset_daily_001` 正式日常保留不变。首轮异常因浮夸、第二轮白天收敛图因不符合黑紫氛围，均为 `unselected + rejected`。2026-09-22 按负责人要求重制12日常＋12异常：12张 `asset_daily_002` 已生成并交付4K，黑紫异常中间稿随后被反馈“天空过于紫色”；现仅活动中心 `asset_anomaly_003` 完成墨蓝灰天空校准并交付4K。当前13张均为 `unselected + pending`；等待代表样图确认再扩展剩余11张异常。本批不是24张已完成，不沿用旧资产批准，不提升到正式运行目录，全部地点仍 `not_integrated`。

## 实现与规则入口

- [Manifest](../../assets/art/asset_manifest.yaml)、[粉笔精灵正式包](../../assets/art/characters/chalk_spirit/)、[图书馆正式背景](../../assets/art/backgrounds/m1_library/)、[记忆终端正式包](../../assets/art/icons/m1_memory_artifact/)、[角色定义](../../resources/content/enemies/chalk.tres)。
- 图书馆运行映射：`scenes/expedition/exploration_skin.gd`、`exploration_board.gd`、`campaign_panel.gd`；环境接入不改变 `game/run/` 的访问、奖励或离场规则。
- 游戏内预览入口：启动参数 `--library-environment-preview`，或 `--campus-debug` 后按 F8 选择“图书馆预览”；预览页可分别切换三种状态与三张视角，使用临时 Journey 且不写入存档。
- 规则事实源：[战斗动画](../battle-animation.md)、[美术工作流](../art/WORKFLOW.md)、[粉笔精灵任务](../art/tasks/chalk-spirit.md)、[记忆终端任务](../art/tasks/m1-memory-artifact.md)。
- 校园地点概念批准事实源：[M1 校园地点任务](../art/tasks/m1-campus-locations.md)与对应对象 Manifest；概念文件仍在 `design/concepts/m1-campus-locations/`，不得按正式资产路径或运行时绑定使用。
- 工具与完整验证矩阵见 [ART-03](art-03.md#骨骼序列帧通用生产与预览)，资源台见 [ART-05](art-05.md)。

## 混合动画资产包归一（已实装）

候选 006 与正式包共享 13 个运行文件：presentation.tscn 保存层级、枢轴、遮挡、部件与特效挂点；animations.tres 保存六种骨骼动作；battle_animation.tres 保存入口与七动作 SpriteFrames 回退；帧元数据、rig_manifest、三张图集和五张 parts 同包。

普通角色不附带专用播放脚本，共享控制器位于稳定工程路径。旧候选与正式专用脚本、旧场景和旧动画入口已删除。特殊扩展只有在 BattleAnimationSet 与 rig_manifest 同时登记脚本和原因后才允许提升。

正式 assets/art/characters/chalk_spirit/ 为批准候选的干净运行子集，不含版本目录、review、截图、生成记录、临时帧或专用工具。生成来源与评审证据留在候选和 Git。提升入口为 `py -3 tools/art/promotion/promote_animation.py chalk_spirit`，只校验时加 `--check`。

## M1 记忆终端正式包（已接入，待效果评审）

`asset_011` 以一个版本登记青品红、绿青、红紫三款颜色方案；三款共享结构、透视和环绕文字场，只以颜色区分。正式目录仅保留 3 张透明运行 PNG，不复制评审图、生成记录或冗余 012／013 版本。

Manifest 状态为 `selected + approved`、`authorized_active`，三项正式文件绑定均与候选哈希一致。三区域默认映射为图书馆青品红、第二终端绿青、第三终端红紫；代码通过专用 `MemoryTerminalView` 复用同一资产家族，接入效果仍待人工评审。

接入入口为 `scenes/expedition/memory_terminal_view.gd`、`campaign_panel.gd` 与 `campaign_hub.gd`：基地三卡显示回收状态，首次区域结算显示单枚大图，三阶段终局显示三枚终端阵列。接入不修改 `CampusProgress`、存档 schema 或终端领取规则。

## 验证与证据

- 图书馆九张正式 PNG 均为 1672 × 941、RGB、不透明，与批准候选逐文件 SHA-256 一致；批准来源、状态组合和文件清单见图书馆任务。Manifest 登记 `asset_005_environment_set` 为 `selected + approved`，集成状态为 `authorized_active`，默认 `anomaly / atrium_down`，视觉评审仍为 pending。
- `--library-environment-capture` 真实运行通过 104 checks / 0 failures，覆盖九张正式图、三种状态、三种视角和三种桌面分辨率；既有 `--exploration-capture` 通过 132 checks / 0 failures，确认热点、详情、奖励、离开与恢复流程不受遮挡。
- 游戏内预览捕获通过 31 checks / 0 failures，确认 3 个状态按钮 × 3 个视角按钮实际驱动环境切换，并保持 active run 不变；截图见验证 E26。
- Godot 增量导入后，候选直接复现、正式七动作、四个 Godot 专项均通过；九组帧率／倍速的事件与结算一致。
- 新旧逐节点对照、七动作 GIF、完整巡演、三分辨率预览与真实战斗截图通过；证据见粉笔精灵任务。
- 13 文件重复提升内容一致；正式依赖不引用 design/concepts；资源台 8 对象、101 登记文件，缺失 0、不一致 0。
- 继承历史证据 E10–E12、E19，重跑入口见[验证目录](verification.md)。技术通过不替代人工或手机端验收。
- 2026-09-18：记忆终端 `asset_011` 的青品红、绿青、红紫三款候选与正式文件逐项一致，资源台扫描无缺失／不一致；三款为同一版本，不保留 012／013 冗余记录。视觉批准与提升证据见[任务记录](../art/tasks/m1-memory-artifact.md)。
- 2026-09-18：`MemoryTerminalView` 已接入基地状态卡、区域首次回收结算和三阶段终局阵列；三处均复用正式 PNG，未引入新的存档字段或运行时 Manifest 读取。Godot 图形截图与负责人接入效果评审仍待完成。
- 2026-09-21：校园地点任务与对象 Manifest 已记录十二个具体版本为 `selected + approved`，其中南门批准沿用 2026-09-20 证据，两个品学楼地点及新增九处实景使用 2026-09-21 负责人确认。资源台 33 项测试通过；扫描 26 个对象、263 个登记文件，缺失 0、哈希不一致 0。此验证只证明概念文件与批准登记完整，不代表正式资产制作、运行时地点映射、Godot 接入或接入效果验收完成。
- 2026-09-21：十二张校园地点异常态候选均为 1672×941、24bpp RGB、不透明，实际画面与质量闸门检查通过；图书馆正面异常元素密度高于其余地点，且未恢复旗帜／旗杆。资源台 33 项测试通过；扫描 26 个对象、299 个登记文件，缺失 0、哈希不一致 0。异常态仍为 `unselected + pending`，本条不代表资产批准、正式提升或运行接入。
- 2026-09-21：上述首轮异常态经负责人复核为“过于夸张”，全部改记 `unselected + rejected`，仅保留为历史探索证据。十二张收敛版 `asset_anomaly_002` 已交付为 3840×2160、24bpp RGB、不透明 PNG；生成源 1672×941，以高质量双三次插值放大，明确不宣称原生 4K。普通地点异常覆盖约 15%–25%，图书馆约 35%–45%；同源生成输出通过逐张视觉检查，最终 4K 文件通过逐张解码、尺寸、格式与透明度检查，资产状态仍为 `unselected + pending`。
- 2026-09-21：收敛版登记后，资源台 33 项测试通过；`AssetCatalog.scan()` 扫描 26 个对象、323 个登记文件，缺失 0、哈希不一致 0；`git diff --check` 通过。最终 4K PNG 因体积较大触发 `view_image` 的 Base64 解码限制，故画面判断使用同源生成输出，4K 文件本身使用 `System.Drawing.Image` 完成技术核验；此限制不改变其待人工资产评审状态。

- 2026-09-22：12张日常新版＋1张活动中心天空校准图均经 `asset_report.py --expect-size 3840x2160 --json` 检查通过；最终图为RGB不透明PNG，全部从1672×941以高质量双三次重采样生成，不宣称原生4K。生成源逐图检查、校准图最终文件制作前后对照后检查，通用QA为 `PASS_WITH_NOTES`。各候选完整提示词在generation.md；批次来源、技术属性、哈希和QA在 `design/concepts/m1-campus-locations/review/codex-workflow/paired-4k-*.json`。未进行Godot接入或运行画面修改。

## 已知边界与统筹

- 2026-09-22 天空校准与配对日常候选登记验证：资源台33项测试通过，扫描26对象／348登记文件，缺失0、哈希不一致0、错误0；`git diff --check` 通过。技术检查不替代本次天空校准的人工确认。

006 已改为独立短周期分层，不再保存 96 秒曲线；跨周期及 600 秒时间点对照通过。资源 288,124 B／4,824 keys，详见 ART-03 的稀疏曲线修复。当前样本是刚性分层骨骼，不代表复杂蒙皮角色验收。

**待统筹**：共享控制器、正式包路径、确定性提升与资源台递归依赖校验已落地；需要统筹复核 ART-03／ART-05 和战斗表现边界。高层总览与 Roadmap 未在本功能任务改动。

**待统筹补充**：M1 图书馆九张背景已有 Godot 映射、默认状态和三分辨率接入截图；日常／夜间没有被虚构为游戏内自然时间系统，视觉效果仍需负责人人工评审，不能据此宣布最终美术验收完成。

**待统筹补充**：十二处校园地点已形成概念方向基线并提升日常正式背景；首轮与第二轮异常态已拒绝；最新12张日常4K候选及1张天空校准异常待评，其余11张异常待制作；整套仍待资产批准与正式提升，运行时地点映射与 Godot 接入也未开始。不得将候选生成或日常资产提升汇总成“十二处场景已接入”或“地点美术全部完成”。
