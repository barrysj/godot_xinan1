# 美术任务：M1 关键记忆载体

状态：结构性透视版 `concept_007` 已获概念批准；正式候选 `asset_008` 待人工资产评审。`asset_002`、`concept_003`、`concept_004` 与 `concept_006` 已否决。内部规则 ID 沿用 `m1_memory_artifact`；“关键记忆载体”是本任务工作称呼，不修改全局术语、存档或玩法规则。

## 目标与范围

- 用途、数量与本次要求：为三个区域首次通关获得、终局使用的三件同源永久记忆载体制作一张图标家族正式母版候选；本轮只生成 1 张具体资产，不制作三款区域变体。
- 对应规范、已有身份参考：`docs/art/STYLE_BIBLE.md` 的异常层与局部赛博强化；`docs/art/ART_CONTRACT.md`；`docs/art/WORKFLOW.md`；`docs/art/m1-static-assets.md`；`data/visual/colors.json` 的 anomaly 色组；`docs/art/specs/UI_SPEC.md` 的图标简洁、图形化和避免复杂拟物要求。
- 目标 Godot 场景、入口与依赖：本轮仍不接入 Godot；具体展示区域、裁切与缩放在资产批准后结合三台记忆终端入口确定。
- 不在本次范围内的内容：不画日常校园背景；不制作普通调查兴趣点、终端 UI、触摸设备、落地机柜或屏幕；不添加量子物理剧情、道具名称、终局文本、新玩法、动画、三件正式变体或主游戏接入。

## 当前版本与方案

- 当前使用版：无正式生效版本；未接入。
- 历史批准方向：对象 `m1_memory_artifact`，概念版本 `concept_001`；2026-09-18 负责人明确回复“方向通过”，同时要求完整核心保持对称或中心对称，并在正式资产阶段图形化简化、降低写实材质与微细节、加强“记忆分层／存储切片”身份。该版本不再是当前选用概念，但其有效约束继续保留。
- 已否决正式资产候选：`asset_002`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/002/`，阶段为资产，`unselected + rejected + not_integrated`。2026-09-18 负责人明确反馈“这一版我不喜欢”，该版本不用于后续生产种子。
- 已否决重新设计：`concept_003`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/003/`，阶段为概念，`unselected + rejected + not_integrated`。负责人指出它太像服务器，要求淡化存储，强化终端、核心与珍贵感。
- 已否决新方向：`concept_004`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/004/`，阶段为概念，`unselected + rejected + not_integrated`。负责人指出配色缺少特色、球体像精灵球、屏幕实体感过强，要求更透明的大屏与模糊文字主体，并提出金属球体或核心＋四周分离外壳。
- 待修改新方向：`concept_005`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/005/`，阶段为概念，`unselected + review + not_integrated`。负责人要求改变四片外壳透视，否则看不出共同球形外壳。
- 已否决透视修正版：`concept_006`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/006/`，阶段为概念，`unselected + rejected + not_integrated`。负责人指出其轮廓和遮挡没有形成可见的透视变化。
- 已批准结构性透视版：`concept_007`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/007/`，阶段为概念，`selected + approved + not_integrated`。负责人明确回复“方向可以。尝试生成资产吧（带微调）”。
- 待评审正式资产：`asset_008`，文件位于 `design/concepts/m1-memory-artifact/m1_memory_artifact/008/`，阶段为资产，`unselected + pending + not_integrated`。
- 推荐方案：**镜核文字终端**。中央为一枚暴露的珍珠光核心，四片互不接触的烟银虹彩镜面弧壳分居四角，只暗示保护球面而不闭合成球；面积远大于核心的无框透明信息场从后方穿过整个结构，以大量模糊文字行、段落和逐渐消失的换行作为主体内容。第一识别是文字型终端，第二识别是珍贵镜核，存储不再物化。
- 设计诊断：`concept_004` 用完整圆球、水平接缝和中央珠核组合出精灵球联想，厚弧屏又像实体三联显示器；青黑高亮虽符合基线，却与既有科幻物件趋同。新方案拆掉完整球体和实体屏幕，用四片游离壳制造虚拟结构，以烟银镜面和紫／品红／暖金薄膜虹彩建立专属材质；项目电青只保留为激活光。
- 视觉系统：正中轻俯视、整体严格左右对称；一枚小珠核、四片分离弧壳和一片无边界文字场。上方壳片位于远侧半球，较小、缩短并被珠核遮住内尖端；下方壳片位于近侧半球，较大、前探并覆盖珠核下缘。左右镜像而上下不复制，四片外缘共同暗示以珠核为中心的投影椭圆。屏幕没有边框、分栏、按钮或图像内容，文字不可读且边缘自然消失；金属壳不形成完整圆环、赤道、容器或飞行器。禁止精灵球式完整球体、服务器、存储架、宝石、魔法符文、眼球、摄像头、无人机、反应堆和实体显示器。
- 被否决版本的尝试：`asset_002` 将中央裂面改为完整的正面轴对称／中心对称菱形终端，外部断开模块成对布置；删除波形屏、细轨道和多数小节点，以三层宽大的透明存储切片承担“记忆分层”身份；材质改为更平整的赛璐璐色块并保留克制青黑与镜像品红。该具体造型不再继续，但“完整核心、图形化简化、记忆分层”的既有方向约束仍保留。
- 与普通调查兴趣点的区别：普通调查对象可采用校园内常规屏幕、触摸设备或机柜；本候选没有现实支架、投影器、键盘、底座或实体屏幕，文字场穿过珠核和金属壳，关闭后只剩游离镜核结构，依靠不可能遮挡关系和分离外壳识别为虚拟世界关键终端。
- 三件后续差异预留：共享珠核比例、四壳数量、烟银虹彩材质和文字场透明度，通过四壳曲率／开口方向、文字流方向、核心内部光纹和展开节奏区分；不以简单换色或添加小图标代替设计。其余两个区域身份尚未确定，当前不擅自绑定具体符号。
- 复用的批准方向／资产及原评审记录：复用项目现行 `Cyber Pop Campus` 总方向和 anomaly 色组；无现有关键记忆载体资产可复用；无历史批准记录。
- 资产微调：`asset_008` 保留 `concept_007` 的构图和遮挡，只将上壳尖翼收为圆钝球面四边片，将镜面材质简化为烟银、紫／品红宽色带和暖金边缘三段明暗；珠核内部用三片开放记忆薄层代替闭合镜头纹，文字场合并为少量宽行。
- 技术依据：正式候选源图 1254×1254、透明 PNG；以 96×96 与 48×48 检查图标可读性，并在浅色／深色底检查透明边缘。具体运行时尺寸、锚点、裁切、过滤和 mipmap 设置仍须等接入位置确认。
- 接入要求：本轮只推进资产评审，不接入 Godot；资产批准后再确定三款区域变体、正式路径和接入截图。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `design/concepts/m1-memory-artifact/m1_memory_artifact/001/m1_memory_artifact_concept_001.png`；`c6e0a4de5b5c54b75c3d9b40f01950986979eb9de8a2d465ac23f2b16ab87352` | 方向通过 | 完整核心应保持对称或中心对称；正式资产图形化简化，降低写实材质与微细节，加强“记忆分层／存储切片”身份 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 资产 | `design/concepts/m1-memory-artifact/m1_memory_artifact/002/m1_memory_artifact_asset_002.png`；`84b53dc1e5c457761441b9013f51c2e1cc695b554782a3cd58cb1f7eb536972d` | 未通过 | “这一版我不喜欢”；不作为后续生产种子，先从游戏资源库搜寻相近概念图再确定新方向 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 重新设计概念 | `design/concepts/m1-memory-artifact/m1_memory_artifact/003/m1_memory_terminal_concept_003.png`；`f701e632a41768dad45b8799802d2e6efb8b81e15b932707d44aa5ca6a03af78` | 未通过 | “太像服务器了”；淡化存储，强化终端、核心和珍贵感，允许采用不遵循现实物理的虚拟结构 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 新方向概念 | `design/concepts/m1-memory-artifact/m1_memory_artifact/004/m1_memory_terminal_concept_004.png`；`d10d25152fee43fce609333d0f6567c946059d7e17ae16598941149da2a954fa` | 未通过 | “有点丑陋”；配色缺少特色，球体像精灵球，屏幕实体感过强；改用更透明的大屏、模糊文字主体、金属球体或核心＋分离外壳 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 镜核概念 | `design/concepts/m1-memory-artifact/m1_memory_artifact/005/m1_memory_terminal_concept_005.png`；`6bb353ed6a3989f508d63c6531e59845707c6ab03dc0dc5f1819a74746d3cfa5` | 待评审 | “镜核文字终端”：四片烟银虹彩金属壳环绕暴露珠核，大面积无框透明文字场承担终端身份 | Codex 根据用户新方向制作并展示；2026-09-18 |
| 透视修正版 | `design/concepts/m1-memory-artifact/m1_memory_artifact/006/m1_memory_terminal_concept_006.png`；`c09104892af82f2ae192ea9096d90ef19045ec89f819ab84125e30067f5f64ea` | 未通过 | “看起来没有调整透视啊”；轮廓、缩短和遮挡不足，仍像四片平面徽标，不能用高光变化冒充透视 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 结构性透视版 | `design/concepts/m1-memory-artifact/m1_memory_artifact/007/m1_memory_terminal_concept_007.png`；`0d7f0585c7c0442bd7fa6b094e706e8eb34b39e906aff829794ae95078d198e3` | 方向通过 | “方向可以。尝试生成资产吧（带微调）”；保留球壳透视，正式资产收圆翼尖、降低写实材质和微细节 | 用户在当前 Codex 对话明确决定；2026-09-18 |
| 正式资产候选 | `design/concepts/m1-memory-artifact/m1_memory_artifact/008/m1_memory_terminal_asset_008.png`；`fd0aa629875c52a0ec2ae13a376867786f2d22c7130e5037e3f93019b09838b0` | 待评审 | 圆钝四壳、三段图形化金属、三片开放记忆薄层与分组文字场；作为三款记忆终端图标的家族母版候选 | Codex 根据批准方向制作并展示；2026-09-18 |
| 接入效果 | 尚未开始 | 待评审 | 需先取得资产批准和明确接入授权 | |

## 验证与结果

- 本任务验收条件：候选必须是可读取的真实位图；珠核、四片游离金属壳和大面积透明文字场在几秒内可辨；第一印象应为关键交互终端与珍贵核心，不得读成服务器、普通显示器、精灵球、水晶球、眼球、摄像头、无人机或魔法圣物；不得出现可读伪文字、水印或密集 HUD 图标；概念阶段不以技术检查替代人工批准。
- 概念图片质量闸门：`PASS_WITH_NOTES`。技术完整性 PASS（1254×1254，PNG，非空，`Format32bppArgb`）；主体、结构、prompt、构图和生成伪影检查通过。负责人已在后续审核指出不对称裂面不适合完整终端，该问题由 `asset_002` 修正。
- `asset_002` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工资产评审。技术完整性 PASS（1254×1254，PNG，1,376,540 bytes，`Format32bppArgb`，四角 Alpha `0,0,1,0`）；主体与身份 PASS；对称结构与悬浮物理逻辑 PASS；prompt／内容 PASS；构图与 96×96、48×48 缩略图可读性 PASS；生成伪影 PASS。备注：正式提升时仍需依据真实 UI 展示尺寸确定最终源图尺寸、边距、过滤与 mipmap 设置。
- `concept_003` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工概念评审。技术完整性 PASS（1254×1254，PNG，1,043,307 bytes，`Format32bppArgb`，四角 Alpha 均为 0）；主体、严格左右对称、三片存储晶片和 prompt／内容 PASS；96×96 与 48×48 下三层仍可辨；未发现文字、水印、重复物或融合结构。备注：晶片内部电路线在游戏尺寸消失，正式资产应删除或合并为一个粗明暗切面；外壳少量硬表面细分不作为最终细节承诺。
- `concept_004` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工概念评审。技术完整性 PASS（1254×1254，PNG，1,169,415 bytes，`Format32bppArgb`，四角 Alpha 均为 0）；单一球核、内部珍珠、弧形全息屏、严格左右对称及 prompt／内容 PASS；96×96 与 48×48 下“屏幕＋球＋内核”三级轮廓仍可辨；定向修正已移除摄像头镜头、机器人脸、奇幻场景和怪物剪影误读。备注：屏幕中的人物回声在小尺寸只承担氛围；正式资产需降低辉光并检查浅色背景边缘。
- `concept_005` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工概念评审。技术完整性 PASS（1254×1254，PNG，1,766,466 bytes，`Format32bppArgb`，四角 Alpha `1,0,1,0`）；单一珠核、四片分离壳、镜面材质、透明文字场、严格左右对称及 prompt／内容 PASS；96×96 与 48×48 下核心和四壳仍可辨，文字场缩小时压成柔和色块但不破坏中心轮廓；未发现水印、签名或可读正文。备注：正式资产需清理透明边缘残留，并把屏幕与静态核心拆层，由 Godot 原生渲染文字场。
- `concept_006` 图片质量闸门复核：`REGENERATE_MAJOR`，不得作为后续输入。技术文件可读，但四壳轮廓与 `concept_005` 基本相同；上下壳缺少足够的透视缩短、尺度差和前后遮挡，核心任务失败。此前 `PASS_WITH_NOTES` 结论撤销，以本次复核为准。
- `concept_007` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工概念评审。技术完整性 PASS（1254×1254，PNG，1,753,313 bytes，`Format32bppArgb`，四角 Alpha 均为 0）；单一珠核、四片分离壳、前后遮挡链、共同球面包络、透明文字场和严格左右对称 PASS；96×96 下尺寸差和遮挡清楚，48×48 下仍读成球壳包围珠核；未发现水印、签名、可读正文或结构融合。备注：上壳仍略带翼片感，正式资产阶段可减少尖角并继续图形化简化。
- `asset_008` 图片质量闸门：`PASS_WITH_NOTES`，可进入人工资产评审。技术完整性 PASS（1254×1254，PNG，1,981,693 bytes，`Format32bppArgb`，四角 Alpha `0,0,1,0`）；珠核、圆钝四壳、三片开放记忆层、前后遮挡、透明文字场和严格左右对称 PASS；96×96 与 48×48 下主体可辨，浅色／深色对比预览未见黑边或明显透明污染；未发现水印、签名、可读正文或结构融合。备注：左下角 Alpha 1 可在批准提升时钳制；金属仍保留少量柔和渐变，但已移除高频写实细节。
- 复现检查命令：`Add-Type -AssemblyName System.Drawing` 后读取 `Image.FromFile()` 检查尺寸与像素格式；`Get-FileHash -Algorithm SHA256` 检查文件摘要。
- Manifest 回写：`concept_001` 保留历史批准但改为 `unselected + approved`；`asset_002`、`concept_003`、`concept_004` 与 `concept_006` 为 `unselected + rejected`；`concept_005` 为 `unselected + review`；`concept_007` 为 `selected + approved`；`asset_008` 已登记实际候选与生成记录，当前 `unselected + pending`；`integration.status: not_integrated`，没有正式路径或 Godot 资源绑定。工作流缩略图与对比预览不登记为资产。
- 一致性检查：Manifest 的 `root` 指向本候选目录，`files` 仅指向实际存在的概念 PNG 与 `generation.md`；不声明运行时生效文件，不声明透明图标参数。
- 实际截图／动作预览证据：无 Godot 运行截图；`asset_008` 原图、`review/codex-workflow/thumbnail-{96,48}.png` 及 `contrast-preview.png` 已查看。候选展示不等于接入效果验收。
- 未解决问题：等待负责人判断 `asset_008` 是否可作为三款记忆终端图标的正式家族母版；三件区域变体、最终显示尺寸和接入位置仍未决定。外部图片只作参考，未核对并获得可用授权前不纳入项目资产。
- 本地提交：`concept_001` 提交 `42c45c2`；`concept_007` 提交 `65fe340`；其余历史版本以对应任务记录所在提交为准。不 push、不 merge main。
