# 粉笔精灵混合动画资产 006

状态：已于 2026-09-16 获批为正式资产，并以 `chalk_spirit.asset_006` 归档；Godot 技术接入完成，接入效果待人工评审。

## 本轮反馈

负责人指出候选 002 的远程攻击把主体推向射击方向，违反后坐力方向；施法使用单色圆球，视觉表现粗糙。本轮修正运动逻辑并重做程序特效层。

## 修改

- 远程前摇：角色朝右前倾架枪，仅用于稳定瞄准。
- 远程出手：弹体与枪口光向右，主体在 0.12 秒内向左后坐并向上抬枪；两块浮游石因惯性短暂滞留在前方。
- 远程收招：主体从左侧后坐位回到脚底锚点，不再向前滑动。
- 施法特效：移除单色圆球，改为青色十二节点外环、紫色八节点内环、紫色菱形核心、白色内核、半透明光晕和八颗旋转粉尘。蓄力时双环反向旋转，释放时整体扩散并淡出。
- 死亡仍完整复用正式 005 的 8 帧序列。

法阵全部使用 Godot 原生 `Line2D`、`Polygon2D` 与既有粉尘纹理组成，不新增正式位图资产，也不进入 Manifest。可播放 GIF 留在 `review/`：待机、移动、远程、施法、受击、濒危和退场各有独立预览，`rig-all-actions.gif` 保留七动作巡演；仅供 Codex 工作流与任务记录使用的运行截图和 contact sheet 统一放在 `review/codex-workflow/`。

获批候选的自包含快照位于本目录，包含序列帧回退、全部骨骼拆件、候选动画资源与表现场景。正式资产采用稳定目录 `assets/art/characters/chalk_spirit/`，运行时不包含版本号，也不再依赖任何试验别名目录；Manifest 分别登记候选根和正式接入根，动作后端映射保存在对应 Godot 资源中。

## 技术验证

- `CHALK_SPIRIT_HYBRID_CHECK actions=7 rig=6 death=approved-005 failures=0`。
- Godot 实际渲染攻击 40 帧、七动作巡演 112 帧，并生成连续 GIF。
- 出手阶段通过 1920×1080、2560×1440、1920×1200 捕获；枪口光、弹体与法阵均未被裁切。
- 正式资源回归保持 `SKILL_VFX_CHECK failures=0`；角色定义、Manifest 和运行时引用已统一到粉笔精灵稳定路径。

## 数据化迁移（2026-09-16）

源实现为 5b65315 的已批准 006；原图、枢轴、遮挡、后坐方向、双环法阵和 005 死亡帧保留。通用 tools/art/archive/legacy-animation/bake_presentation.tscn 从输入 JSON 的 source、output、canvas、fps 与 actions 采样；此次 canvas 为 [288,288]、120 Hz，ranged／cast／hurt 分别为 2／2／1.4 秒，idle／move／critical 保存 96 秒复合曲线，覆盖当前 90 秒战斗上限与收尾。常规预览每轮重置时钟；关闭预览循环并连续观看超过 96 秒会从曲线起点循环。资源是交付事实源，不依赖旧脚本执行。

关键帧采用误差压缩、显隐边界保留和跳变细分；序列化时间向左偏置 0.00001 秒，避免 float32 把恰好位于帧边界的重生延迟到下一帧。比对覆盖前两秒 144 Hz 采样及持续动作到 89 秒；位置最大误差 0.0204、旋转 0.00049、缩放向量 0.00119、颜色通道 0.00049，显隐差异 0。对照截图与日志位于 review/codex-workflow/hybrid-before-after.png、hybrid-comparison.log。此为技术迁移，正式接入效果仍待原流程人工评审。

## 稀疏周期修复（当前，2026-09-16）

上方 96 秒密集烘焙方案已替代，不作为后续生产范例。当前运行库 288,124 B、4,824 keys，最长片段 3.401360544 秒。静态布局留在 presentation.tscn；只有动态属性入轨，必要固定姿态单键保存。独立周期通过 AnimationLibrary 的 cycle_layers 元数据组合，不新增角色播放脚本。

制作配置为 compact_authoring.json。历史重建入口 tools/art/archive/legacy-animation/compact_cycles.tscn；参数指定此 JSON。source_revision=ee5b780 的专用脚本／场景及 library_revision=804bd51 的 animations.tres 是离线迁移输入，可从 Git 提取到配置指明的 .godot/animation-benchmark/old.gd、old.tscn、dense.tres；old.tscn 的脚本引用需指向上述缓存 old.gd。输出先落本地缓存，再核验场景引用、复制运行核心到候选，通过通用提升进入正式包。运行时仅依赖当前包，离线来源不随正式包发布。

对照包括一次性动作与 600 秒以内多周期，最大全局位置误差 0.1411 源画布像素；显隐差异 0。粒子重生处四个属性采样按 ±0.0001 秒的单侧极限验证，细节与性能见 docs/implementation/art-03.md 的稀疏曲线修复。七 GIF 和 all-actions.gif 已重新生成；图片、死亡帧、尺寸、锚点、后坐方向与双环法阵保留。

证据：review/codex-workflow/compact-cast-comparison.png、compact-comparison.log、compact-real-battle.png。当前修复是技术优化，未新增视觉批准。

迁移缓存已清理；需要历史复现时先创建配置中的缓存及输出父目录，再从 Git 恢复输入。姿态对比改用 tools/art/verification/compare_presentation.tscn，读取 review/codex-workflow/pose-comparison.json；fps=120 的新增采样在收招跳变附近未通过，改为 144 可复现原通过结果。两份日志均保留，已知边界见 ART-03；不能把历史采样结果视作任意时间点完全相同。
