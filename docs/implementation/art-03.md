# ART-03 · 动作预览与切帧生产工具

> 持续功能档案；整体统筹见 [总览](../implementation-status.md)，规则见 [战斗动画](../battle-animation.md)。

- 功能 ID：ART-03；状态：生产入口已验证；姿态等价存在已记录的 120 Hz 跳变边界。
- 验证日期：2026-10-01（合入 `main` 规则后 Guard 008 留存与概念预览修复）；起点 `ee5b780`；运行修复基线 `76c8406`；工具归档基线 `7be8ffe`；本轮合并基线 `4bd7db6`、预览工具提交 `7c6c62d`。Guard 留存提交见本地 Git 历史。
- 实现入口：[预览器](../../scenes/battle_demo/motion_preview.tscn)、[共享控制器](../../scenes/battle_demo/presentations/hybrid_presentation.gd)、[捕获器](../../tools/art/animation/motion_capture.gd)、[GIF 后处理](../../tools/art/animation/motion_previews.py)、[确定性提升](../../tools/art/promotion/promote_animation.py)。

## 骨骼＋序列帧通用生产与预览

### M1 角色混合占位扩展（2026-09-29）

- 按[任务档案](../art/tasks/m1-player-cast-animation.md)开始五职业基础占位及远射手换貌复用验证。首个 Archer 001 用共用 RootBone／HeadBone 刚性动画库做待机、移动、受击、濒危；持枪远程、施法和死亡采用整帧关键姿势回退。入口为 [`build_placeholder_hybrid.py`](../../tools/art/animation/player_cast/build_placeholder_hybrid.py)、同目录共享 `animations.tres`、Archer 的 `presentation.tscn` 与 `battle_animation.tres`。本批仍为评审候选；不替换正式角色。
- 2026-09-30 按负责人反馈修订五版濒危／退场：`build_placeholder_hybrid.py` 从各版透明双姿势源图裁出独立濒危与侧卧倒地帧；移除共享库中覆盖濒危的骨骼片段，濒危由静态帧呈现，退场立即显示倒地帧并沿用战斗表现层渐隐。五版 Godot 检查、关键动作截图及全量 GIF 重录通过；轮廓、武器和实际画面证据见任务档案。候选批准及正式接入状态未改变。
- Godot 4.7.2 `run-motion-preview.ps1 -EnsureImport -Check` 与常规 `-Check` 通过，七动作检查成功；待机／远程三分辨率截图与七动作 GIF 已实际生成，1920×1080 已人工查看。Manifest 扫描无错误，本对象无警告，全局缺失／不一致为 0；Python 编译和 Git 差异检查通过。细节、命令和截图链接在任务档案。
- 已知边界：移动为根部上下动，并非腿部步态；头部水平切层只容许微小转角；出手帧与待机画法仍有细微差异。若后续提升正式资产，需要人工确认观感与进一步分层。**待统筹**：新批量占位制作取代先前暂停的精细动画路线；总览与 Roadmap 留待统筹会话核验。
- 冲刺手 001 复用同一动画库但换用双刀关键姿势与近战片段。Godot 4.7.2 `-EnsureImport -Check`、近战三分辨率截图、单动作 30 FPS GIF 成功；1920×1080 截图已人工查看。枪口光绘制逻辑扩展为近战贴刀尖短弧光，发现位置漂移后重建并复看。Manifest 扫描仍无错误、缺失或不一致。具体记录和证据见任务档案；正式配置未修改。
- 发明家 001 与应援者 001 继续引用同一根／头骨骼库；发明家用单张透明持枪图与短枪口光，应援者复用已批准 007 静态合成图与键盘绿光脉冲。各自 `-EnsureImport -Check` 通过，远程／施法三分辨率截图和单动作 GIF 成功，1920×1080 截图已人工查看。Manifest 扫描 `errors=[]`、本对象 `warnings=[]`、缺失／不一致均为 0；Python 编译和 Git 差异检查通过。局限是没有完整举枪后坐力与手指动作，不改变正式配置。证据与命令见任务档案。
- Archer 换貌 001 使用银蓝短发、圆眼镜、橙白短袖，与原 Archer 使用同一 `shared/animations.tres`；`verify_archer_reuse.py` 证实两套骨骼场景和动作资源仅角色素材路径不同，重叠可见像素颜色差异比例 0.391。Godot 4.7.2 `-EnsureImport -Check` 和重复 `-Check` 均通过；待机／远程三分辨率实机截图和各自 GIF 成功，1920×1080 已人工查看。证明范围限于当前根／头刚性骨骼与整帧出手姿势，不等于全身蒙皮动画可直接换皮。Manifest 无错误或缺失；细节见任务档案。

### Guard 动画方法比较候选（2026-09-25）

- **当前入口（2026-10-01）：**负责人确认 Guard 只留 008。`guard/008` 保存七态动画、62 张自持运行帧、源片、调色前帧、身份首帧与两张静态姿势源图；历史 001～007 和四法并排素材可从 `7c6c62d` 恢复，当前 Manifest 仅登记 008 为 `selected + pending + not_integrated`。`design/.gdignore` 排除概念图导入后，预览器用开发专用 PNG 解码器直接加载，并在显式动画加载失败时让检查失败。Godot 4.7.2 `-EnsureImport -Check` 七态 PASS、远程 SKIP、`failures=0`，近战／濒危／退场三分辨率截图已生成并人工查看；资源台扫描 51 对象、错误 0、缺失 0、不一致 0、Guard 警告 0。`b79729d` 补验正式资源缺一份导入描述时只重建一次，随后重复 `-EnsureImport -Check` 不再启动编辑器，仍为 `failures=0`。当前命令和证据见[Guard 任务档案](../art/tasks/guard-animation-study.md#008-留存收尾2026-10-01)。以下为历史过程记录，旧路径并非活动入口。

- 状态：001～004 四条五动作样片，005～008 四条即梦近战候选；全部未批准，未接入正式角色。004 通过中国站 MiniMax H3 生成五段原片；005～008 从负责人提供的即梦视频演进，后续版本增加择帧与调色。均由同一 Godot 预览器验证。样片、截图、生成来源及视觉结论见[Guard 动画方法对照](../art/tasks/guard-animation-study.md)，官方一手来源见[方法调研](../research/guard-animation-methods.md)。
- 输入为 M1 已批准 Guard 002 身份和剑盾方向；内置 image_gen 生成 7 张透明独立姿势，统一到 512×512 后构建 001 `SpriteFrames`；002 则用同一待机图做单图平移／旋转／缩放并烘焙五动作。003 从待机图切出头、盾与主体，`Skeleton2D` 驱动待机与受击，移动／近战／施法由 001 序列帧回退；施法骨骼尝试因无法表达盾牌展开而未采用，仅是粉笔精灵式混合的局部验证。
- 验证基线：本工作树，Godot 4.7.2，随工作区提供的 Python/Pillow 12.3。`design/concepts/guard-animation-study/build_previews.py`／`build_hybrid.py` 可复现输出；三候选均经 `run-motion-preview.ps1 -Check`，各支持动作与状态检查通过；003 `hybrid_check.tscn` 确认头盾骨骼转动和近战回退。`-Action Melee -Capture` 得到三分辨率实际截图，003 另抓取待机，1920×1080 截图已人工查看。资源台 33 项单测通过，Manifest 扫描 errors=[]，新对象 warnings=[]、五动作可识别、状态 `not_integrated`。
- 2026-09-25 补验：003 `hybrid_check.tscn` 再次通过，`run-motion-preview.ps1 -Check` 通过；`-ExportPreviews` 录制五动作 30 FPS GIF，施法与受击 `-Capture` 各得到三分辨率实际截图，1920×1080 已人工查看。导出器跳过总表内嵌对象后的真实导出通过；细节、失败骨骼施法及时间边界见任务档案。验证基线以本分支当前提交为准，不替代正式接入评审。
- 2026-09-30 网页预览：五职业候选以及 Guard 003／008 用 `-EnsureImport -ExportPreviews` 补齐逐动作 GIF 与全动作巡演；帧元数据写入与 Godot 资源一致的 `clips`，美术资源浏览器现能显示动作按钮并加载 GIF。实现入口为 [`build_placeholder_hybrid.py`](../../tools/art/animation/player_cast/build_placeholder_hybrid.py)、[`sync_browser_clips.py`](../../tools/art/animation/sync_browser_clips.py) 和两份 Manifest。网页实际打开检查：五职业各七动作，Guard 003／008 各六个真实片段；两版退场由旧 Guard 回退。验证细节见对应美术任务档案，批准与正式接入状态未改变。
- 2026-09-30 按负责人反馈，Guard 003／008 也补入区别于待机的濒危与退场静帧。透明双姿势源图经 [`add_defeat_poses.py`](../../tools/art/animation/guard/add_defeat_poses.py)裁切、定脚底并写入两个 `SpriteFrames` 片段，网页两版各有七个真实片段，退场不再借旧 Guard 回退。两版 `-EnsureImport -Check` 均通过，四个动作现场截图与两版全量 GIF 已重录；008 濒危和倒地截图已人工查看。画面直接换姿势，退场仍按既有表现层渐隐。候选状态与正式接入状态不变，详细证据见[Guard 任务档案](../art/tasks/guard-animation-study.md#003008--濒危与退场独立静帧2026-09-30)。
- 2026-09-25 同规格补验：001／002 各用 `run-motion-preview.ps1 -ExportPreviews` 完成五动作 Godot 30 FPS／352×352 实际录制；与 003 的原录制用 `design/concepts/guard-animation-study/compare_runtime.py` 生成 15 FPS 同步并排 GIF 和 0.55 秒五动作静帧总览。检查 001 待机静帧、近战／施法短停留，002 整体运动无腿步／独立剑击，003 待机／受击连续骨骼运动。登记原录制于 Manifest，不改变正式人物资源。验证命令、图像及局限见任务档案；验证基线以本分支当前提交为准。
- 2026-09-25 H3 补验：入口 `h3_generate.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/h3_generate.py`）使用中国站 V2 API 五动作各成功提交一次并下载 768×768、24 FPS 源片；`build_h3_candidate.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_h3_candidate.py`）每动作采九帧、抠绿、对齐脚底并生成 `guard/004/battle_animation.tres`。本分支工作树作为验证基线，Godot 4.7.2 `run-motion-preview.ps1 -Unit Guard -Animation design/concepts/guard-animation-study/guard/004/battle_animation.tres -Check` 与 `-ExportPreviews` 通过，`-Action Cast -Capture`／`-Action Hurt -Capture` 生成并人工查看 1920×1080 实际截图；`compare_runtime.py` 重建四组同步 GIF 和 0.55／0.75 秒静帧。Manifest 登记源片、帧、资源及预览；正式人物引用未变。
- 2026-09-27 H3 交互预览修复：补齐 004 的 45 张切帧 Godot 导入描述，普通预览窗口改为可见；首次或缓存清理后使用 `-EnsureImport`。本分支工作树在 Godot 4.7.2 增量导入后执行 004 `-Check`，七个适用状态 PASS、远程 SKIP；清理其他临时导入文件后，不加 `-EnsureImport` 的重复 `-Check` 无帧加载错误且 `failures=0`，`-Action Melee -Capture` 生成三分辨率截图并人工查看 1920×1080，交互预览进程存在可见主窗口。正式人物引用未变。
- 2026-09-27 即梦 005 试验：以 `build_jimeng_melee_candidate.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_jimeng_melee_candidate.py`）从负责人提供的 1280×720 可变帧率源片按时间戳抽取近战 12 帧，其他四动作借 004 帧并补边为 1024×512。Godot 4.7.2 增量导入后 `-Check` 通过，`-Action Melee -Capture` 三分辨率通过并人工查看 1920×1080，`-ExportPreviews -Action Melee` 得 30 FPS／608×352 的真实时序 GIF。宽画布预览按资源比例缩放，捕获器按角色显示高度扩展视口宽度；004 方形输出仍为 352×352。十二张新近战帧未触透明画布四边。005 的出手剑尖完整，峰值盾牌遮挡和绿幕细边仍待评审；正式 Guard 引用未变。验证基线：当前 art/guard-animation-study 工作树；详情及命令见任务档案。
- 2026-09-28 即梦 006 试验：沿用 005 原片，按时间戳重新择取 24 张近战姿势，出手区间加密；用输入首帧的脸部中位色校准，在跨帧一致的肤色遮罩内施加 `(18,28,24)` RGB 增量。内置 imagegen 的单帧修色样本改变了局部形状，仅存评审，不进入动画。Godot 4.7.2 `run-motion-preview.ps1 -EnsureImport -Check`、`-Action Melee -Capture`、`-Action Melee -ExportPreviews` 通过；24 张 1024×512 RGBA 帧邻帧不同，四边 alpha≤30，三分辨率实际截图已生成并人工查看 1920×1080，近战 GIF 为 30 FPS／608×352。复建入口、输入／输出及边界见[任务档案](../art/tasks/guard-animation-study.md#006--重新择帧与肤色校正2026-09-28)。006 仍待人工选择与批准，正式 Guard 引用未变；验证基线为本分支当前工作树。
- 2026-09-28 即梦 007 色彩复核：以 005 待机帧对比 006 起手帧，发现脸部亮色接近，衬衫／盾面／鞋较暗及后段肤色偏暖。以 `build_guard_palette_match.py`（历史脚本 `7c6c62d:design/concepts/guard-animation-study/build_guard_palette_match.py`）保留 006 姿势和 alpha，作同一平滑材质调色与按帧小幅肤色校准；24 张原帧 alpha 逐像素不变，最大可见 RGB 单通道改动 28。Godot 4.7.2 绝对脚本路径 `-EnsureImport -Check`、`-Action Melee -Capture`、`-Action Melee -ExportPreviews` 通过，三分辨率截图已生成并人工查看 1920×1080，GIF 为 30 FPS／608×352。详情与色彩比较见[任务档案](../art/tasks/guard-animation-study.md#007--对齐待机色板2026-09-28)；007 未批准，正式 Guard 引用未变。
- 2026-09-29 即梦 008 中性色复核：基于 007、参照 005 待机，压低后段浅色衣物的暖红偏差，并小幅冷却暗部／蓝色装备。`build_guard_neutral_palette.py` 可复现；24 张帧的 Alpha 逐像素不变，最大单通道改动 16。按 `Character_Action_Design` Skill v2 的身份、左右特征、持手、色板四锁建立当前右向近战动作卡；由于缺三视图，不声称 8 方向已验证。Godot 4.7.2 `-EnsureImport -Check` 和不带导入的重复 `-Check` 通过（`failures=0`）；`-Action Melee -Capture` 得三分辨率截图，1920×1080 已人工查看；`-ExportPreviews` 得 30 FPS／608×352 GIF。资源台扫描 `errors=[]`、Guard `warnings=[]`、缺失 0、不一致 0。008 未批准，正式 Guard 引用未变。详细色差与评审文件见[任务档案](../art/tasks/guard-animation-study.md#008--压低近战帧整体暖红偏色2026-09-29)。
- 2026-09-28 预览路径修复：`run-motion-preview.ps1` 在启动 Godot 前检查显式 `-Animation` 是否属于当前项目且文件存在，避免从另一份 checkout 运行时无声回退到占位资源。用不存在的 `guard/999/battle_animation.tres` 复现旧行为：原命令 exit 0、日志只有 warning 和 `MOTION_PREVIEW_CHECK failures=0`；修复后 exit 1 并指明缺失路径。使用本分支脚本绝对路径和 006 资源执行 `-EnsureImport -Action Melee -Capture` exit 0，三分辨率实际截图已生成并人工查看 1920×1080：左侧显示 006，右侧纸甲守卫是固定测试目标。用户入口及边界见任务档案；正式 Guard 引用未变。
- 2026-09-27 预览导入修复：`run-motion-preview.ps1 -EnsureImport` 先检查所选动画资源直引图片的 `.import` 描述及 `.godot/imported` 缓存；文件缺失或源图更新时才运行 Godot 编辑器导入。未提供 `-Animation` 或无法确认依赖时保守执行导入。005／004 缓存齐全时 `-EnsureImport -Check` 均通过且导入日志时间未变，005 约 2.3 秒完成检查；临时移走一张 005 纹理缓存后，同一命令触发编辑器导入、重建缓存且动作检查通过。资源台与手动命令沿用原参数时，不再每次启动编辑器。首次导入后直接运行预览的命令也继续可用。
- 质量边界：001 动作剪影比 002 清楚，但图生图人物约 5～6 头身，未满足 4 头身规范，细节跨姿势漂移；002 没有肢体独立运动；003 只验证头盾在待机与受击的小范围运动，没有人体四肢蒙皮；004 动作连续，但剑盾形态漂移、局部出画，绿幕抠像留彩边，压到 0.45 秒行动后关键细节易漏看。此轮不能认为人物骨骼翻折问题已修复；后续若继续混合骨骼，应先补正分层原画与遮挡再试。
- **待统筹**：若选择新的人物生产路线，需重新估算 Guard 和其他角色的分层／补帧成本，以及目标平台验证；本轮不改总览和 Roadmap。

### M1我方概念分离交付／动画停止（2026-09-25）

- 交付基线main `28c8d2f`，从`art/m1-player-cast`按人工批准分离002武器方向、006四人服装概念与007／008静态种子；保留7个批准登记项、29个唯一登记文件及原有PNG导入设置。任务与路径见[我方角色样板](../art/tasks/m1-player-cast.md)和`assets/art/asset_manifest.yaml`。
- 用户限定的最后两轮结束：022太抽象，023带入设定角色但可见网格翻折，质量未通过。原动画试验截至`8864a77`留在美术分支；本交付无009–023目录、动画资源、播放代码或正式人物引用，不把静态批准升级为动态／真人换脸批准。
- 验证：29文件逐一SHA256相等；`py -3 -m unittest discover -s tools/art/asset_manager/tests -q`在当前main基线33项通过；真实Manifest扫描30对象411文件、errors=[]、missing=0、mismatches=0。暂存差异检查发现旧generation.md的Markdown行末双空格／末尾空行；为保持来源文件哈希不改动，使用`git -c core.whitespace=-blank-at-eol,-blank-at-eof diff --cached --check`检查其余空白问题。与美术实验分支34项测试数量不同，未引入其额外工具改动。
- **待统筹**：概念可供后续美术任务复用，人物动画停止；新任务需先解决遮挡绘制、蒙皮拓扑与动作设计。没有提升正式运行资产或改变游戏画面，本次仅静态交付，不重复截图；不改高层总览／Roadmap，不自动推送远程。

制作契约、动作命名、运行包结构、显式导出与提升规则统一维护于[战斗动画](../battle-animation.md#hybrid-animation-package)。本档案只记录实现、验证及已知边界；通用工具与归档入口见[工具说明](../../tools/art/README.md)。

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

## 密集迁移版本历史对照（已替代）

`ee5b780` 旧公式脚本 → `09dccf7` 密集库的测量曾暴露严重回退：动画库 8,982,734 B、200,717 keys、每动作 180 轨，连续动作展开 96 秒；正式粉笔相关文件从 5.881 MiB 增至 14.439 MiB。历史完整测量见 Git `804bd51` 的本档案；原测量临时脚本和 JSON 已清理，不再作为可用工具入口。

下表保留密集版测量用于识别数量级，当前能力以稀疏版和最新验证边界为准。首次测量使用无主场景的 SceneTree，有既有插件初始化噪声，不宜与后续正常场景的微小差值直接比较。

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

同机 Godot 4.7.2 Debug headless，三组独立进程，每动作预热 200 次、5×6,000 次更新，中位数。此次使用正常主场景，避免上一轮自定义 SceneTree 的插件初始化噪声；不与 GPU、发布包或手机性能混同。旧基准脚本是本地实验产物，已随迁移缓存清理；此处保留测量方法与结果，不把缓存路径当作长期入口。以下原版与稀疏版为 `76c8406` 的最新复测中位数。

| 指标 | 原专用脚本（本轮） | 密集版（上轮） | 稀疏分层版（本轮） |
| --- | ---: | ---: | ---: |
| 首次加载 | 39.25 ms | 1,044.96 ms | 60.71 ms |
| 首资源＋实例静态内存增量 | 3.320 MiB | 11.181 MiB | 3.634 MiB |
| 待机更新 | 20.78 µs | 276.27 µs | 44.18 µs |
| 移动更新 | 20.44 µs | 263.04 µs | 33.19 µs |
| 远程更新 | 21.38 µs | 265.29 µs | 19.37 µs |
| 施法更新 | 35.87 µs | 267.37 µs | 33.64 µs |
| 受击更新 | 21.11 µs | 253.30 µs | 18.45 µs |
| 濒危更新 | 20.91 µs | 258.50 µs | 32.70 µs |

周期层使用最多 10 个附加 AnimationPlayer，节点为 48；额外 19 实例静态内存约 3.103 MiB，原专用脚本约 1.889 MiB。共享资源与无角色脚本的收益仍有实例开销，不能宣称全面快于原脚本；关键的数量级回退已消除。本轮不改美术审批状态。

最新 Git 文件统计：原版正式相关资源 6,167,150 B，当前 6,445,311 B（增加 4.5%），PNG 均为 6,100,917 B；统计不含 `.godot`，候选评审资料另计。七动作与巡演一次完整导出实测 53.63 秒，包含增量导入、捕获和编码；旧版没有等价导出基准，不宣称生产加速倍数。

**待统筹**：撤销“96 秒曲线为合理交付边界”的旧判断；采用资源预算、短周期、轨道稀疏性、状态切换一致性和性能复测作为生产验收。

## 通用验证与迁移归档（2026-09-16）

基线 `76c8406`。姿态对比移入 `tools/art/verification/`，共享 `presentation_math.gd` 为无场景生命周期的辅助函数；日常验证不再加载采样器。JSON 显式指定两个场景，采样覆盖配置的动作时长，附加长时点由配置提供；缺失节点、空动作表返回失败。配置格式只维护在[工具目录](../../tools/art/README.md#姿态对比)。旧采样、稀疏转换及入口归入 `archive/legacy-animation/`，保留 UID 和历史重建说明。

验证：Godot 增量导入后，等价场景通过；仅在 2 秒后产生差异的 3 秒动作、缺失节点和空动作配置均正确失败。归档 compact_cycles 重跑得到 4,824 keys。对照旧脚本的 144 Hz 结果与原验证一致；此次未改运行画面，无需重新截图。

清理 `.godot` 中旧迁移输入、重复运行包、性能临时脚本、捕获帧及重复截图／日志，共 200 文件、96,174,025 B（91.72 MiB）；保留 Godot 导入缓存、控制器和已登记候选／评审证据。清理后 `run-motion-preview -Check` 与提升 `--check`（13 文件）通过，日常入口不依赖已删除缓存。

**已知边界／待统筹**：旧对比工具硬编码 144 Hz，忽略 JSON 的 fps。配置生效后补测 120 Hz，ranged 1.65 秒收招跳变附近出现最大约 5.0001 源像素偏差（阈值 0.3），未通过；不能将原 144 Hz 通过扩展为任意采样点精确等价。本次整理保留失败证据，不改变已批准资产。复现配置与两份日志位于候选 `review/codex-workflow/pose-comparison.json`、`pose-120hz-boundary.log`、`pose-144hz.log`；旧输入恢复方式见候选 generation.md。该姿态误差不等于模拟事件或战斗结果改变。

### 后续优化：编辑器内完整动作预览

- 记录日期：2026-09-16；状态：待办，暂不实施，不阻塞当前美术生产。
- 当前安排：美术制作暂由 Codex 完成，用户暂不参与 Godot 编辑器中的资产制作与动画编辑。
- 使用限制：独立周期动画层可以分别图形化编辑，但编辑器内单独播放一个片段不等于共享控制器组合后的完整动作；当前完整效果通过通用运行预览查看。
- 后续目标：当需要人工参与动画编辑时，提供按 idle／move 等完整动作选择、播放及拖动时间轴的入口，同时预览主体、部件和特效的组合效果，减少手动理解和切换私有周期层的负担。
- 实施边界：届时再评估编辑器预览工具方案；复用现有动作数据与共享组合逻辑，不引入第二套战斗状态机，不为方便预览重新烘焙冗长公共周期。
- 验收方向：完整动作预览与相同 context 下的运行效果一致；修改关键帧后可方便复看组合效果。本项仅记录需求，尚未实施或验证功能。

### 工作流与 skill 精简

基线 `7be8ffe`；WORKFLOW 保留制作、评审与清理流程，字段和资源台界面细节引用工具说明／ART-05；动画契约与命令集中到 battle-animation.md。项目 art-implementation skill 只提供按任务读取的入口与关键决策，不复制字段表和样本预算。删除过期 96 秒生产边界、临时基准脚本命令及手动预构建控制器要求；密集版完整历史由 Git 保存，不在当前档案重复整份报告。未修改高层总览、Roadmap、人工批准或运行资产。

验证：受影响 Markdown 的 128 个相对文件链接存在；旧 migration 路径引用清零，通用验证无归档依赖；23 项资源台单测、JS 语法与 Python 编译、Git 差异检查通过。skill 的 name／description 未变，字段格式、引用和占位符静态检查通过；skill-creator 的 quick_validate 因本机缺 PyYAML 未运行成功，不将替代静态核对冒充该脚本通过。工作流正文约缩短 21%，档案合并重复历史后约缩短 35%；本轮只改说明，不重复截图。

## 序列帧正式提升补齐（2026-10-01）

基线 `3c8a741`：`tools/art/promotion/promote_animation.py` 支持纯序列帧包与 `frames/*.png`，沿用 `rig_manifest.json` 的运行文件允许列表；存在骨骼动作时仍强制成对交付场景和动画库。生成来源留在候选，正式帧元数据只保留播放字段。未绑定单位的批准外观可登记为 `not_integrated` 后入库。验证：`py -3 -m unittest discover -s tools/art/asset_manager/tests -q`，35项通过，覆盖帧包依赖改写、重复提升一致性和不完整骨骼包拒绝。此改动未更改运行画面，无需截图；后续人物正式接入见 ART-02。

2026-10-01人物目录迁移补充：调色与败北静帧工具迁到 tools/art/animation/guard/；刚性骨骼生成器和换皮验证迁到 tools/art/animation/player_cast/。源包统一 design/concepts/characters/<角色>/。只读复现检查确认Guard24帧逐像素一致、五套混合资源生成文本一致；远射手双外观的同库同动作检查通过。正式提升与六套动作检查见ART-02及人物任务。
