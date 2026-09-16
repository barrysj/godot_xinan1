# 美术任务：M1 探索 UI 视觉样板

状态：概念 004 已获人工批准；正式组件、交互与多分辨率运行效果待后续验收，尚未接入。

## 004 人工批准（2026-09-17）

用户本任务原话：“004 的视觉方向、布局与状态设计通过；正式组件、交互及多分辨率效果在后续运行验收”。

批准绑定提交 cac5703 中的 004 四状态图与配套 SVG，selection=selected、approval=approved、integration=not_integrated。范围仅为 UI 概念，不连带批准图书馆背景资产、正式组件或运行交互。下方待评审措辞为当时制作记录，当前状态以本节为准。

| 004 文件 | SHA-256 |
| --- | --- |
| review-default.png | f5b9df7805ad3286845a1b0f684ae76f444f0f586d834c528a62a05669725d91 |
| review-focus.png | adc1bda13a153544ca6e9d8781cdfb557e8b935529b800f42072a08589e0b14a |
| review-detail.png | 426f0b0a1e521ddb49ece203e493ad0bc30a4bbfde4586ebdd4b8e1105dcb5f4 |
| review-complete.png | 4aa4def084b6cd6a4053d6aeb1520861a34ac6c6b201968b3f47cf4043c75c02 |

本次仅回写人工决定，未改被评图像；资源台扫描与 Git 差异检查用于核对登记，不代替后续运行验收。

## 当前修订 004（2026-09-17，优先于下方历史方案）

用户采纳热点状态、文字可读性、危险标记、完成反馈，以及弹窗／按钮视觉建议，明确排除“热点缺少场景归属”。003 为要求修改，未批准；004 为待评审，未批准。

候选目录：design/concepts/m1-exploration-ui/m1_exploration_ui/004；default、focus、detail、complete 四状态分别展示普通、悬停／聚焦、选中详情、已查看及战斗领奖完成。热点位置保持不变，沿用 003 背景。

浮窗改紧凑蓝黑透底、阴影、单角切口、短侧边光；正文与标题字号提高，关闭命中区扩大，主按钮为右下实心“读取”。52px 图标保留、标签增至17px，命中示意72px。正式接入须让文字和命中区按设备设下限，不能把整图等比缩小当适配。

实现边界：静态概念而非可点击运行界面；弹窗连接线只说明选中关系，没有增加场景落点。无正式资产生产、Godot 接入或批准。生成细节见 004/generation.md。

验证：2026-09-17，基线 29ba781。node 004/render.cjs 输出四张1600×900 PNG，详情与完成状态已看图检查并修正完成标签底板宽度；AssetCatalog 扫描 errors=[]、warnings=[]，四版本均 matched；git diff --check 通过。字体缓存不可写提示沿用003，实际中文成功渲染。004 保持 unselected/pending/not_integrated。

## 目标与范围

- 用途：为 M1 图书馆地点探索建立一张 UI 信息层级样板，保持现有四站路线、四个热点、单个展开详情和终端反馈的语义。
- 对应规范：[工作流](../WORKFLOW.md)、[执行契约](../ART_CONTRACT.md)、[UI 规范](../specs/UI_SPEC.md)、[M1 静态资源清单](../m1-static-assets.md)。
- 已核对实现入口：`scenes/expedition/campaign_board.gd`、`campaign_panel.gd`、`campaign_hub.gd`；复用 `resources/theme/theme-main.tres` 与 `data/visual/{colors,typography,spacing}.json` 的日常层方向。
- 目标 Godot 入口：地点探索页；本轮不修改 Godot 场景或运行逻辑。
- 不在本次范围内：真实图书馆环境、建筑背景、照片、人物身份、地图重绘、终端图标家族、三终端状态组件、动画、代码接入。

## 当前版本与方案

- 当前使用版：无；对象 `m1_exploration_ui` 尚未接入。
- 本轮候选：`concept_003`，目录 `design/concepts/m1-exploration-ui/m1_exploration_ui/003/`；review-default.png 与 review-detail.png 分别展示默认探索与点击详情。001、002 保留对比。
- 推荐方案：全幅背景，四个缩小并分散的热点；取消常驻详情，点击后在热点旁显示小浮窗。顶部保留紧凑四站进度。三个小闪电指向守卫中心。
- 当前方向：探索页使用既有异常层配色，深色底、青色可操作标记、品红危险电弧与局部霓虹雾光；文字与核心操作保持清楚。日常基地的视觉不在本次调整范围。
- 明确限制：003 获用户明确授权以所提供的另一任务概念图生成背景研究；原参考图不复制、不登记。派生背景仅用于 UI 审核，不替代其他任务的环境资产或批准。正式按钮、文字、边框使用 Godot 原生组件或矢量，不使用整屏烘焙图。
- 技术依据：读取 colors.json 的 anomaly 配色；正式实现复用 Theme 和 Container，本次不改共享 Token。
- 接入要求：概念获批后，先用现有 `Container`、Theme、锚点与热点交互构建；再按 1920×1080、2560×1440、1920×1200 的实际运行截图单独评审接入效果。
- 提前试接入授权：无。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `concept_001` · `library-exploration-layout.svg` · `1437759b8ffcdd76a73a03107e4d34abac2c35183d7ebe0024aadcdf5f2ff9b1` | 要求修改，未批准 | 太日常、像汇报 PPT；探索主要发生在异变场景，需要霓虹虚化、信号干扰、电流危险信号 | 用户本任务反馈，2026-09-16 |
| 概念 | `concept_002` · SVG 与 review.png | 要求修改，未批准 | 电弧像涂鸦、占地过大；详情改小弹窗；缩小图标并提高间距 | 用户反馈，2026-09-17 |
| 概念 | `concept_003` · review-default.png、review-detail.png | 待评审 | 场景优先、短闪电、按需小详情 | 2026-09-17 提交审核 |
| 资产 | 未开始 | 待评审 | | |
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 本任务验收条件：实际文件可解析；资源台能发现该对象与概念版本；状态为 `unselected + pending + not_integrated`；无 Godot 引用或运行画面变更。
- 验证日期／基线：2026-09-16；本地 `main` 基线 `10dfbcd`。
- 技术检查结果及复现命令：PowerShell 的 XML 解析确认 SVG 根节点、1600 × 900 与 viewBox；`Get-FileHash -Algorithm SHA256` 得到表中哈希；`AssetCatalog('.').scan('assets/art/asset_manifest.yaml')` 返回 `errors=[]`、UI 分类、候选文件 `matched`、`warnings=[]`、`integration=not_integrated`；`py -3 -m unittest discover -s tools/art/asset_manager/tests -v` 为 33 项通过；`py -3 -m py_compile tools/art/asset_manager/catalog.py tools/art/asset_manager/server.py` 与 `git diff --check` 通过。
- Manifest 回写：`m1_exploration_ui/concept_001`；不写批准依据、正式文件、预览 GIF、Godot 预览或 bindings。
- 一致性检查：概念阶段没有 selected-to-effective binding，故只校验候选文件存在与格式；不得由校验动作生成接入状态。
- 实际截图／动作预览证据：矢量原图路径见当前版本；没有运行截图，因为本轮未改 Godot 画面。内置浏览器安全策略拒绝本地 SVG 导航，未绕过该限制生成伪截图。
- 未解决问题：需要负责人审核此布局；图书馆原照、来源／许可、地点身份和短回忆仍缺，故不得开始场景概念、正式资产或接入。
- 本地提交：本档案、候选与 Manifest 已在同一独立本地提交中完成；远程未推送。

## 003 验证与边界

2026-09-17，基线 0a281bd。两状态实际渲染 1600×900 并看图检查，四个热点不重叠，详情不覆盖其他热点，短闪电聚焦守卫。源背景独立保存，参考原图未入库。原生交互尚未实现，无游戏接入或批准。现行候选路径与用户新授权以上方当前版本为准，下方为历史记录。

## 002 验证与边界

基线 03c89bb；2026-09-16。SVG 使用 bundled sharp 本地渲染 PNG，实测 1600×900，已查看画面；001 同时补导出 PNG 作比较。渲染器报告字体缓存不可写，但成功输出中文图像。没有使用浏览器或变更 Godot。
资源台实际扫描：两个概念均可发现、文件 matched、errors 与 warnings 均为空；002 保留 unselected + pending + not_integrated。git diff --check 通过。接入、动画表现和三尺寸游戏适配未开始；场景仍等真实参考。
