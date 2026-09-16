# ART-03 · 动作预览与切帧生产工具

> 持续功能档案；整体统筹见 [总览](../implementation-status.md)，规则见 [战斗动画](../battle-animation.md)。

- 功能 ID：ART-03；状态：已验证（Windows 桌面与当前测试角色范围）。
- 验证日期：2026-09-16；起点 `ee5b780`；实现基线 `56dc3aa`＋本档案同提交的 F 清理树。
- 实现入口：[预览器](../../scenes/battle_demo/motion_preview.tscn)、[共享控制器](../../scenes/battle_demo/presentations/hybrid_presentation.gd)、[捕获器](../../tools/art/animation/motion_capture.gd)、[GIF 后处理](../../tools/art/animation/motion_previews.py)、[确定性提升](../../tools/art/promotion/promote_animation.py)。

## 骨骼＋序列帧通用生产与预览

战斗模拟决定动作方式、阶段、出手、命中、收招和朝向。共享表现只定位 context；AnimationPlayer 使用手动模式，不自行推进战斗时间。普通角色提供场景、AnimationLibrary、SpriteFrames 和元数据；特殊扩展须在 BattleAnimationSet 与 rig_manifest 显式登记脚本及理由。

动作契约为 idle、move、melee、ranged、cast、hurt、critical、death。旧 attack 根据角色 attack_modes 映射；双能力角色能提供独立 melee／ranged，共用同一模拟时钟。预览禁用不支持的攻击入口。粉笔精灵 006 的前六种可用状态走骨骼，death 保留批准的序列帧。

### 显式导出

```powershell
pwsh.exe -File ./run-motion-preview.ps1 -EnsureImport -Check -Unit res://resources/content/enemies/chalk.tres
pwsh.exe -File ./run-motion-preview.ps1 -ExportPreviews -Unit res://resources/content/enemies/chalk.tres -PythonPath '<含 Pillow 的 python.exe>'
pwsh.exe -File ./run-motion-preview.ps1 -ExportPreviews -Unit res://resources/content/enemies/chalk.tres -Action Ranged -PythonPath '<含 Pillow 的 python.exe>'
py -3 tools/art/promotion/promote_animation.py chalk_spirit --check
```

- 默认预览、-Action、-Tour、-Check 和资源台启动不生成 PNG／GIF，不写候选或正式包。-Capture 是单独的显式截图入口，仅写 .godot。
- -ExportPreviews 从 Manifest 精确解析候选，可显式传 -Animation 选择历史版本；未指定动画时取角色当前接入候选。输出仅写该候选 review/。
- 一个 Godot 进程连续导出全部支持动作；隔离 352×352 SubViewport 直接捕获角色，不落盘全屏中间帧。
- 每动作 30 FPS、3 秒，涵盖待机→动作→收招→待机；移动与濒危在尾段回待机，死亡停末帧且 GIF 不循环。全量导出同时生成 all-actions.gif。
- 捕获清单包含对象、版本、动作、后端、帧率、持续时间、循环、前后状态、事件与输出路径。后处理器不含角色 ID、骨骼名或动作公式。
- 临时帧限于已校验的 .godot/motion-capture/<作业>/frames；编码后删除，JSON 与抽样 PNG 保留为本地验证缓存。GIF 映射写入 Manifest，资源台只消费预生成文件。
- Python 后处理依赖 Pillow；-PythonPath 可指定环境，未指定则使用系统 py -3。当前系统 Python 可运行资源台单测，导出使用 Codex bundled Python。

### 运行包与提升

候选和正式运行核心同构：presentation.tscn、animations.tres、battle_animation.tres、battle_animation.frames.json、rig_manifest.json、图集和 parts/。正式目录只保留运行文件及 Godot PNG 导入设置；generation.md、GIF、截图与旧实现追溯留在候选或 Git。

提升工具先验证批准／选用状态、允许列表、动作集合、外部依赖、特殊扩展登记和 owner，再复制并改写包内引用及 owner。拒绝候选路径泄漏、丢失依赖、未批准版本和正式包中的非运行文件。重复提升内容相同；--check 校验正式包等于确定性提升结果。角色不再保留专用播放脚本。

## 验证结果

| 验证 | 结果 |
| --- | --- |
| Godot 增量导入后 run-motion-preview.ps1 -Check | 正式与候选七动作 PASS，近战 SKIP；暂停、单步、慢速通过 |
| hybrid_contract_check.tscn | 候选直接加载、后端分配、尺寸／锚点、双朝向、手动定位与死亡末帧通过 |
| presentation_check.tscn | 30／60／144 FPS × 0.25／1／2 倍速九组合的全部模拟事件、结算时间、伤害和治疗一致；暂停、重开通过 |
| animation_check.tscn、skill_vfx_check.tscn | 双攻击、旧 attack 映射、缺失回退、帧时长、弹道和特效通过 |
| 显式单动作及全量导出 | 7 个 352×352 GIF＋完整巡演；一轮一个 Godot 捕获进程 |
| 普通预览与资源台 | 候选及正式包无新增文件、无内容变化 |
| Python 单测、JS 语法、Python 编译 | 通过；命令见 ART-05 |
| 三分辨率预览、真实战斗与新旧对照 | 1920×1080、2560×1440、1920×1200 无裁切；证据见粉笔精灵任务 |

运行日志无脚本错误、Bone2D 长度／角度警告；本机仍有既有根证书读取错误和像素原图加载提示。首次空缓存编辑器导入曾报告既有插件设置脚本问题，完成增量导入后的上述运行检查正常。

## 边界与统筹

- 通用姿态对比入口为 `tools/art/verification/compare_presentation.tscn`；一次性采样与曲线转换已归档到 `tools/art/archive/legacy-animation/`。交付运行及日常生产不依赖归档。
- 006 已使用独立短周期分层，最长周期 3.4014 秒；无 96 秒整体重置限制。原密集版本的测量保留在下方历史对照，当前数据以稀疏曲线修复章节为准。
- 当前骨骼样本是刚性分层动画；未引入 AnimationTree、商业骨骼格式或手机端验收。正式接入视觉评审仍单独保留。
- **待统筹**：共享动画所有权、正式包路径、Pillow 导出依赖及资源台只读／生产写入边界已改变；高层总览和 Roadmap 未改。

## 工具目录归类（2026-09-16）

基线 164c475。工具按职责归入 animation/（捕获、GIF 与既有图集构建）、migration/（采样迁移与对照）、promotion/（确定性提升）；资源台保留 asset_manager/。完整说明见 [工具目录](../../tools/art/README.md)。同步更新 Godot 场景／脚本引用、Python 导入、项目根定位、测试和文档命令；根目录日常入口不变。

验证：22 项 Python 测试、13 文件提升 --check、增量导入后 run-motion-preview -Check 通过；单动作 Cast 显式导出验证新路径的捕获和编码链。本次仅目录整理，不改角色画面与批准状态。待统筹：工具内部路径已迁移，外部保存的旧命令需使用新路径。

## 迁移前后体积与效率测量（2026-09-16）

对照 ee5b780 的旧专用表现脚本与 09dccf7 的正式 AnimationLibrary；同一台 Windows、Godot 4.7.2 Mono Debug 引擎，使用相同图片与 context。此次为只读分析，未修改动画曲线。资产统计取 Git 对象字节，不等于压缩发布包或显存占用。

### 资产数据量

| 范围 | 迁移前 | 迁移后 |
| --- | ---: | ---: |
| 正式粉笔相关文件（含原分散的脚本／场景／资源入口） | 6,167,150 B / 5.881 MiB | 15,140,759 B / 14.439 MiB |
| 其中 PNG | 6,100,917 B / 5.818 MiB | 相同 |
| 候选 006 全目录 | 21.944 MiB | 48.971 MiB |
| 其中 review 证据 | 16.065 MiB | 34.529 MiB |

新增 animations.tres 为 8,982,734 B（8.567 MiB），正式和候选各保存一份。六动作各 180 轨，总计 200,717 个 key；idle／move／critical 的 96 秒轨道分别含 49,768／109,476／32,958 个 key。候选增长还含新巡演与迁移对照截图，不应全部归为游戏运行资源增长。正式统计包含导入描述和元数据，旧版还含 generation.md；不含两版共用工程代码。

### 运行 CPU 与内存

独立进程每版本 3 次；每动作预热 200 次，计时 5 组 × 6,000 次 apply_presentation，取全部样本中位数。CPU 使用 headless，包含相同 context 更新循环，未测 GPU、真实战斗整帧或手机。加载是进程内首次加载，未清空操作系统磁盘缓存。原始 JSON 与脚本在本地 `.godot/animation-benchmark/`；可用 `Godot.exe --headless --path . --script res://.godot/animation-benchmark/bench.gd -- old res://.godot/animation-benchmark/repeat-old.json` 重跑，new 参数切换正式资源。旧实现由 `git show ee5b780:scenes/battle_demo/presentations/chalk_spirit_presentation.gd` 提取；本地场景只替换脚本位置，不改算法。

| 指标 | 迁移前 | 迁移后 |
| --- | ---: | ---: |
| 表现场景首次加载 | 41.24 ms | 1,044.96 ms |
| 资源＋首实例 Godot 静态内存增量 | 3.320 MiB | 11.181 MiB |
| 额外 19 实例静态内存增量 | 1.889 MiB | 1.934 MiB |
| 首次实例化＋加入场景 | 0.485 ms | 0.338 ms |
| 待机单次更新 | 22.35 µs | 276.27 µs |
| 移动单次更新 | 21.81 µs | 263.04 µs |
| 远程单次更新 | 24.18 µs | 265.29 µs |
| 施法单次更新 | 37.07 µs | 267.37 µs |
| 受击单次更新 | 21.34 µs | 253.30 µs |
| 濒危单次更新 | 21.66 µs | 258.50 µs |

内存为 OS.get_static_memory_usage 差值，不是进程 RSS 或显存；同种角色共享曲线库，所以新增实例没有复制整份约 8 MiB 增量。节点由 37 增为 38；图像未变，不能据此声称 GPU 更快。此微基准的自定义 SceneTree 没有主场景，既有 ggt 自动加载报告 current_scene 为空；两版都出现，计时循环及 JSON 输出完成。桌面后台进程及导出会引入噪声，结果用于识别数量级回退，不作正式性能预算。

### 生产与维护效率

新链完整七动作＋巡演一次实测 47.93 秒（含 PowerShell、增量导入、一个捕获进程和 GIF 编码）；一轮 630 张 352×352 临时帧。该耗时不是人工开发时间，也不是稳定性能指标。旧基线没有等价、可直接复跑的通用 GIF 导出入口，不能报告加速倍数。相同帧数下 352×352 相对 1920×1080 的原始像素量少 94.0%，不等于 PNG 字节或耗时同比下降。

维护收益是普通角色无需专用播放脚本、动作资源可在编辑器查看修改、统一批量导出、正式提升自动校验；近远程与回退共用时钟。代价是当前采样结果过密，长曲线人工编辑也不便利。不能把流程通用化等同于运行性能优化。

**待统筹／优化建议**：当前版姿态更新约慢 7–12 倍、加载约慢 25 倍。保留共享控制器和动作契约，后续优先验证无变化轨道裁剪、关键帧减量、连续动作短周期／分层表达，以及避免每次 apply 重复 play／pause；每项需重跑新旧姿态误差和战斗时钟测试。二进制／压缩资源只解决体积与解析的一部分，不能代替轨道求值优化。未在此次对比中实施优化。

## 稀疏曲线与独立短周期修复（2026-09-16）

修复基线 804bd51。本节替代上方密集迁移版本的当前能力与限制；历史测量保留用于说明回退原因。保留 hybrid_presentation 共享混合控制器；骨骼后端仍为 AnimationPlayer／AnimationLibrary，死亡及缺失动作仍用 SpriteFrames。没有角色专用播放脚本。

- 周期运动按独立周期拆层，仅存一周期；不求巨大的公共周期，不按整场战斗长度烘焙。库元数据 cycle_layers 是状态到私有片段的映射，私有片段不进入动作入口。各播放器手动 seek，时间来自 context；不重复 play／pause。
- 静态属性放在场景；某动作的固定姿态只用必要的单键。共享 RESET 包含 59 条确实被动画修改的属性，仅切换时应用。主动作轨道 idle／move／critical 为 2／2／6，ranged／cast／hurt 为 29／54／28；周期层各 1～8 条；把主动作与其循环层一起计算，待机／移动／濒危／远程／施法／受击实际为 28／29／30／29／54／28 轨。全部库合计 257 条（包括 RESET），不再是每动作 180 条。
- 本次历史转换使用 compact_cycles 的属性与周期配置；相关入口现已归档。新角色直接制作动画资源，不先写角色公式再采样迁移。
- 库 288,124 B（281.37 KiB），4,824 keys，最长片段 3.401360544 秒；较密集版本的 8,982,734 B／200,717 keys 分别减少 96.79%／97.60%。候选与正式运行包一致。
- 006 门槛写入 rig_manifest：512 KiB、6,000 keys、4 秒片段；提升前拒绝超限。Godot 契约检查还约束每片段不超过 64 轨，禁止多键恒定轨道。多种复杂角色可单独制定预算，不自动沿用当前样本数值。

### 修复验证

增量导入后，run-motion-preview -Check、hybrid_contract_check、presentation_check、animation_check、skill_vfx_check 全部通过；23 项 Python 测试通过（含体积、keys、时长超限时禁止提升）。九组 FPS／倍速模拟事件与结算、暂停／单步／重开／双朝向／死亡回退保留通过。

新旧对照覆盖 144 Hz 前两秒、连续状态至 179 秒，以及 95.99／96／96.01／359.123／600.123 秒。全局位置误差最大 0.1411 源画布像素（140 显示尺寸约 0.069 像素），旋转 0.001105 弧度、缩放向量 0.001985、颜色通道 0.000999，显隐差异 0。4 个属性采样恰落在粒子重生跳变处，按明确的 ±0.0001 秒单侧极限核对；不把 78 像素粒子重生位移冒充连续插值误差。所有动作切换后的属性与全新实例同 context 完全一致，包括 600 秒后切换和回零。

全量七动作 GIF＋巡演重新生成；三分辨率施法截图、真实教室战斗及修复前后施法图已实际查看。截图与日志归粉笔精灵任务记录。无 Bone2D 长度／角度警告或运行脚本错误；根证书和既有像素原图加载提示仍存在。

### 性能复测

同机 Godot 4.7.2 Debug headless，三组独立进程，每动作预热 200 次、5×6,000 次更新，中位数。此次使用正常主场景，避免上一轮自定义 SceneTree 的插件初始化噪声；不与 GPU、发布包或手机性能混同。本地可复跑入口 `.godot/animation-benchmark/bench-final.tscn`，参数 `-- old/new res://.godot/animation-benchmark/result.json`。

| 指标 | 原专用脚本（本轮） | 密集版（上轮） | 稀疏分层版（本轮） |
| --- | ---: | ---: | ---: |
| 首次加载 | 38.57 ms | 1,044.96 ms | 65.93 ms |
| 首资源＋实例静态内存增量 | 3.320 MiB | 11.181 MiB | 3.634 MiB |
| 待机更新 | 21.45 µs | 276.27 µs | 39.76 µs |
| 移动更新 | 21.94 µs | 263.04 µs | 31.31 µs |
| 远程更新 | 21.71 µs | 265.29 µs | 18.01 µs |
| 施法更新 | 36.41 µs | 267.37 µs | 30.78 µs |
| 受击更新 | 20.65 µs | 253.30 µs | 16.22 µs |
| 濒危更新 | 20.94 µs | 258.50 µs | 31.30 µs |

周期层使用最多 10 个附加 AnimationPlayer，节点为 48；额外 19 实例静态内存约 3.103 MiB，原专用脚本约 1.889 MiB。共享资源与无角色脚本的收益仍有实例开销，不能宣称全面快于原脚本；关键的数量级回退已消除。本轮不改美术审批状态。

**待统筹**：撤销“96 秒曲线为合理交付边界”的旧判断；采用资源预算、短周期、轨道稀疏性、状态切换一致性和性能复测作为生产验收。

## 通用验证与迁移归档（2026-09-16）

基线 `76c8406`。姿态对比移入 `tools/art/verification/`，共享 `presentation_math.gd` 为无场景生命周期的辅助函数；日常验证不再加载采样器。JSON 显式指定两个场景，采样覆盖配置的动作时长，附加长时点由配置提供；缺失节点、空动作表返回失败。配置格式只维护在[工具目录](../../tools/art/README.md#姿态对比)。旧采样、稀疏转换及入口归入 `archive/legacy-animation/`，保留 UID 和历史重建说明。

验证：Godot 增量导入后，等价场景通过；仅在 2 秒后产生差异的 3 秒动作、缺失节点和空动作配置均正确失败。归档 compact_cycles 重跑得到 4,824 keys。对照旧脚本的 144 Hz 结果与原验证一致；此次未改运行画面，无需重新截图。

清理 `.godot` 中旧迁移输入、重复运行包、性能临时脚本、捕获帧及重复截图／日志，共 200 文件、96,174,025 B（91.72 MiB）；保留 Godot 导入缓存、控制器和已登记候选／评审证据。清理后 `run-motion-preview -Check` 与提升 `--check`（13 文件）通过，日常入口不依赖已删除缓存。

**已知边界／待统筹**：旧对比工具硬编码 144 Hz，忽略 JSON 的 fps。配置生效后补测 120 Hz，ranged 1.65 秒收招跳变附近出现最大约 5.0001 源像素偏差（阈值 0.3），未通过；不能将原 144 Hz 通过扩展为任意采样点精确等价。本次整理保留失败证据，不改变已批准资产。复现配置与两份日志位于候选 `review/codex-workflow/pose-comparison.json`、`pose-120hz-boundary.log`、`pose-144hz.log`；旧输入恢复方式见候选 generation.md。该姿态误差不等于模拟事件或战斗结果改变。
