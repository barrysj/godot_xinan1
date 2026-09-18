# 美术任务：M1 探索 UI 视觉样板

## 012 浮窗／按钮正式资产与接入（2026-09-18）

负责人查看 012 预览后明确回复“这版可以。提升为正式资产。”，批准范围为 012 的 `panel.png` 与 `button.png`。两图已原样复制到 `assets/art/ui/m1_exploration_ui/`；校园记忆、人物事件、借阅终端和敌对守卫继续使用 011 已批准图片。因此当前正式组合登记为 asset_012，并非重新生成四枚图标。

真实战役弹窗与按钮已改用 NinePatch，固定保留边角与切口；按钮悬停／焦点以同一素材轮廓增亮，已移除旧接入额外绘制的规则白色圆角框。Godot 4.7.2 Compatibility 执行 `--campaign-flow-check --exploration-capture` 为 `132 checks / 0 failures`。三尺寸默认态及 1080p 详情／出口开放态保存于 `design/concepts/m1-exploration-ui/review/codex-workflow/integration-012/`；看图确认 16:9／16:10 切角未被拉坏，按钮白框消失，正文可读且弹窗未越界。

### 热点名称条后续方向（已确认原则，待资产与接入）

现有“校园记忆”“人物事件”等名称是程序生成的 `Label`，不是烘焙图片。负责人提出以倾斜、不规则的深色条带替代常驻文字，用作“可交互”提示；该方向符合本项目“图标 → 悬停简要信息 → 点击详情”的渐进展示规则。正式实现建议为：常态只显示图标与无文字条带；鼠标悬停、键盘或手柄聚焦时，条带展开并显示对象名称；点击后由弹窗显示标题和说明；触屏点击直接打开弹窗。条带应为一张可复用、无文字的 NinePatch 或透明纹理，不为四个热点分别烘焙名称。完成态仍由降低强调度、勾号或状态色表达。

本次批准不包含尚未生成的条带，也不立即删除现有标签，避免在新的可交互提示完成前损失键盘／手柄的预激活识别。下一轮只需生成并评审一张复用条带，再实现常态／悬停／聚焦／完成四种状态。

## 012 浮窗／按钮候选记录（2026-09-18）

用户评审最新正式图书馆背景中的实际运行效果，指出浮窗与按钮融入度一般，尤其按钮的风格、形状和配色无法融入。使用 game-ui-ux 与 create-game-assets 复核后，问题拆为资产与接入两层：011 按钮的亮青玻璃胶囊、厚辉光和通用 CTA 形态与自由轮廓热点、图书馆异变背景不一致；同一 3:1 位图被用于不同比例控件且未设置 NinePatch，进一步拉伸切角和边线。浮窗方向可辨但视觉重量偏高，厚双框与机械 HUD 感压住场景。

按钮截图中的外层规则白色圆角框来自 Godot `focus` StyleBox，属于接入问题；素材内部另有亮色描边。012 只重做浮窗与按钮，并在独立预览中以 NinePatch 保持切角比例、以同轮廓增亮表达焦点。四枚 011 图标及正式图书馆背景不修改。

候选目录：`design/concepts/m1-exploration-ui/m1_exploration_ui/012/`。012 是具有实际视觉差异的新候选，因此版本递增有效；本段记录的是批准前状态，现行批准与接入状态以上方章节为准。具体生成、规范化与预览说明见同目录 `generation.md`。

012 独立 Godot 预览使用最新正式图书馆异变中庭，三尺寸 default/detail/complete 与鼠标、焦点、Esc、读取、奖励门槛断言通过，输出 `EXPLORATION_UI_CANDIDATE PASS`。已看图确认按钮在游戏尺度不再整块亮青，焦点沿自身轮廓增亮且无白色外框；浮窗比 011 更轻、更透，NinePatch 在 16:9／16:10 未破坏切角。截图位于 `design/concepts/m1-exploration-ui/review/codex-workflow/preview-012/`；随后已按上方批准提升并接入。

## 当前状态：011 正式资产已接入真实 M1 图书馆页（2026-09-18）

011 的六张正式图片已接入 `scenes/expedition/campaign_panel.gd` 的真实图书馆地点流程；四热点由 `exploration_board.gd` 和 `exploration_hotspot.gd` 呈现，面板与动作按钮加载正式 `panel.png` / `button.png`。点击热点打开紧凑弹窗，不常驻右侧信息台；读取、人物事件、借阅终端、守卫战、领奖开放出口及返回／续玩均继续调用原战役状态与存档逻辑。

接入只使用已批准的六张 UI 图片。图书馆环境仍沿用主游戏原生抽象示意，没有把研究参考图或其他对话生成的背景纳入资产。技术接入状态为 `authorized_active`，本次运行效果仍待用户人工验收，不由脚本通过代替视觉批准。

Godot 4.7.2 Compatibility 于 2026-09-18 执行真实战役 `--campaign-flow-check --exploration-capture`，结果 `132 checks / 0 failures`。检查覆盖真实鼠标打开弹窗、Esc 关闭与焦点恢复、四热点、人物事件写入、守卫战与领奖门槛、离场以及检查点恢复；实际截图保存于 `design/concepts/m1-exploration-ui/review/codex-workflow/integration-011/`，包含 1920×1080、2560×1440、1920×1200 默认态及 1080p 详情／出口开放态。

## 正式资产 011（2026-09-17）

用户查看 011 Godot 实际运行预览后回复“好，纳入正式资产吧”。该决定批准 011 所展示的浮窗、按钮、校园记忆、人物事件、借阅终端和敌对守卫六张图片，并批准其在 011 中的运行缩放效果。asset_011 状态为 selected / approved。

011 的六张获批图片逐文件原样复制到 `assets/art/ui/m1_exploration_ui/`；来源与 SHA-256 见 `design/concepts/m1-exploration-ui/m1_exploration_ui/011/generation.md`。资源台以动态哈希核对候选与正式文件，不在 Manifest 重复存储哈希。010 校园记忆仍保留 approved 历史决定，但由完整组合 011 取代为当前 selected 资产。

版本整理更正：正式提升没有改变任何视觉内容，不应另增版本号。先前仅为归档复制而建立的 012 已移除，图片归入用户实际评审的 011；正式目录与运行画面均不变。

提升后将 011 的六张图片加载路径全部切换到正式目录，并以 Godot 4.7.2 compatibility 重跑三尺寸 default/detail/complete 与交互断言，结果仍为 `EXPLORATION_UI_CANDIDATE PASS`；已查看 1920×1080 默认截图，画面与批准版一致。截图继续保存在 `review/codex-workflow/preview-011/`，现为正式副本的实际运行证据。

本段记录 2026-09-17 的资产提升边界：当时仅提升稳定正式图片，尚未修改 campaign_board、campaign_panel、campaign_hub 或存档逻辑。正式战役接入已于 2026-09-18 完成技术实现，以上方当前状态为准。

## 历史：009 异变事件热点候选（2026-09-17）

用户针对008运行截图指出热点图标“过于中规中矩、像PPT”，并确认按“事件正在发生”的不规则轮廓思路重新生成。008保留为被要求修改的引擎预览证据；004概念批准仍有效，但不覆盖新资产评审。

009使用内置imagegen重新生成四张独立RGBA：破碎照片记忆、人物与对话信号、终端扫描光片、敌人脸与向内短电击。共同规则只统一青／蓝黑材质、线条与受控辉光，不使用统一方形／圆形底座。视觉轮廓允许不规则，正式交互仍须使用规则且足够大的透明点击区。

首轮自检后定向修正三项：记忆内部由细碎场景简化为屋顶与钟楼大形；终端移除错误的书本语义，改为数据波形与光标；守卫将三根大电击缩短，使敌人脸成为主体。人物首轮已符合通用人形＋对话框，保留。

交付目录：`design/concepts/m1-exploration-ui/m1_exploration_ui/009/`。四张均为1254×1254 RGBA，Alpha范围0–255；提示词和选择记录见generation.md。当前asset_009为unselected/pending，不接入游戏；尚未以56px运行验证清晰度、焦点、完成状态与多分辨率布局。

## 历史：008 游戏引擎内预览（2026-09-17）

用户在007展示后回复“可以了，尝试在游戏内预览”，确认007两张图标方向并授权运行预览；不推导其余006资产或最终战役接入验收通过。008 复用005交互验证场景，加载006浮窗／按钮／记忆／终端及007人物／敌人图片；原始图片未修改，仅运行时去透明空边并生成 mipmaps，使用线性缩小采样。文字、点击区与焦点仍是原生控件。

入口：`design/concepts/m1-exploration-ui/m1_exploration_ui/008/preview.tscn`。Godot 4.7.2 compatibility 运行附加 `-- --ui-capture`，输出 `review/codex-workflow/preview-008/` 的三尺寸 default/detail/complete 截图。基线51ed6df；1920×1080、2560×1440、1920×1200尺寸与鼠标打开、Tab、Esc焦点恢复、空白关闭、读取、模拟领奖门槛断言通过，日志标记 EXPLORATION_UI_CANDIDATE PASS。

此为独立可点击引擎预览，不是campaign_hub内的真实战役接入；不修改存档，不发放奖励。006/007图标状态还使用着色与勾号叠层，图片缩小后玻璃边缘较软，后续以用户观感决定调整。底板按当前固定详情比例缩放，尚非完整NinePatch正式组件。原005证据没有被覆盖。

状态：概念 004 已获人工批准；005 被要求修改；006 人物／守卫图标按意见修订为 007，其余006资产保留待评；主游戏尚未接入。

## 007 图标语义评审与修订（2026-09-17）

用户要求使用 game-ui-ux 评审：人物应强调人物事件与交互，用简化人物＋对话框；守卫感叹号像任务，改凶恶敌人简笔画。评审认同其语义区分：人物旧图偏角色资料，盾牌旧图偏安保提示；不能只靠颜色区分事件与战斗。

## 校园记忆正式资产 010（2026-09-17）

用户在 009 的首轮结果中重新选定细节较丰富的“校园记忆”图标，并明确要求“提升为资产。之后在游戏内预览”。批准仅绑定 `design/concepts/m1-exploration-ui/m1_exploration_ui/010/memory.png`，SHA-256 为 `f0ba02597736f247beb3fd2ddc6549972854e8389e95a80dbc3207570e5c61e8`。该文件已原样复制到 `assets/art/ui/m1_exploration_ui/memory.png`，未裁切、未重绘、未压缩。

010 在当时状态为 selected / approved；009 的人物事件、借阅终端和敌对守卫仍是 unselected / pending，不能由该次决定推定批准。当时正式文件尚未接入正式游戏场景；用户同时授权下一步做 Godot 运行预览，预览授权不等于最终接入验收。后续整套批准与接入状态以上方 011 当前状态为准。

011 是上述授权对应的独立 Godot 运行评审装配：校园记忆从正式路径读取，另三枚热点仅用 009 候选陪衬；入口为 `design/concepts/m1-exploration-ui/m1_exploration_ui/011/preview.tscn`。该装配不修改 campaign_board、campaign_panel 或 campaign_hub，也不改变 `integration: not_integrated`。

运行验证：2026-09-17，以正式资产提交 `1777315` 为基线，Godot 4.7.2 compatibility 执行 `preview.tscn -- --ui-capture`，输出 `EXPLORATION_UI_CANDIDATE PASS three sizes; details, cancel, focus, read, reward gate`。实际截图保存于 `design/concepts/m1-exploration-ui/review/codex-workflow/preview-011/`，包含 1920×1080、2560×1440、1920×1200 的 default/detail/complete 共九张；已看图检查 1080p 默认／详情和 16:10 默认状态。

画面结论：自由轮廓与不规则碎片消除了统一方形图标的 PPT 感；校园记忆在当前 106px 绘制尺寸仍能读成破碎照片，并保留用户偏好的校园细节。弹窗在三尺寸内未越界，热点之间无重叠。统一黑色名称底条仍略偏规整，可作为后续效果优化项；本段“待实施”是 2026-09-17 的历史状态，正式战役技术接入已于次日完成。

内置 imagegen 分别编辑006两张原图，保存到 `design/concepts/m1-exploration-ui/m1_exploration_ui/007/`，完整提示词见 generation.md。人物去除头发服饰与轨道，敌人去除盾牌和感叹号，保留原系列色彩与玻璃底座。仅修改两个图标，不生成新人物身份或战斗单位设计；007 是局部候选，不是整套资产替换。

看图确认语义修改已呈现；技术检查确认两图为有真实透明像素的RGBA。边光仍偏强，人物底座尺寸略有漂移；需后续缩小、视觉重量及游戏适配验证。本轮无运行画面变更，未借用005截图证明新图标效果。asset_007 保持 unselected/pending/not_integrated。

## Imagegen 资产候选 006（2026-09-17）

用户明确反馈 005“锯齿严重，并且设计感粗糙”，要求使用 image gen 生成符合风格的资产。005 技术验证仍为历史事实，但不代表视觉通过。006 按用户新授权使用位图皮肤与图标，替代此前仅原生绘制的制作限制；文字、交互及布局仍由原生 UI 承载。

交付目录 `design/concepts/m1-exploration-ui/m1_exploration_ui/006/`：panel.png（1536×1024）、button.png（2172×724）及 memory/character/terminal/guardian.png（各1254×1254）。六张独立内置 imagegen 输出；面板追加一次透明背景编辑。已看图并以 sharp 检查 RGBA，六张 Alpha 最小值均为0；面板最大254，其余255。原图完整保存，未程序重绘，提示词与来源说明见 generation.md。

批准状态：asset_006 / unselected / pending。当前仅基础皮肤候选，无运行接入，不复用005截图作为006证据。仍需校验缩小可读性、透明边缘、实际布局、NinePatch边距和交互状态；人物与记忆图标细节偏多，可能需简化。不替换其他任务持有的图书馆原图，不自动批准背景或人物身份。


## 原生组件候选 005（2026-09-17）

用户在概念批准后回复“继续吧”，据此制作正式组件候选，不扩展为主游戏接入授权。当前选定概念仍是 004；005 为 asset / unselected / pending。以下历史范围与未开始表述由本节更新。

- 实现入口：`design/concepts/m1-exploration-ui/m1_exploration_ui/005/preview.tscn`，配套 preview.gd、hotspot.gd、detail_panel.gd；全是原生节点与绘制，未改 campaign_board/panel/hub。
- 样式：紧凑蓝黑切角浮窗、侧边短光、实心短动作按钮，普通／聚焦／选中／已查看／守卫解除状态；保持四热点相对位置，不增加场景落点。
- 验证基线：0643761；Godot 4.7.2 compatibility。运行命令：`Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility design/concepts/m1-exploration-ui/m1_exploration_ui/005/preview.tscn -- --ui-capture`。
- 实际截图：`design/concepts/m1-exploration-ui/review/codex-workflow/asset-005/`，1920×1080、2560×1440、1920×1200 各 default/detail/complete。检查鼠标移动＋按下＋释放打开热点、Tab 弹窗焦点、Esc 关闭与恢复、空白关闭、读取完成、弹窗边界、胜利未领奖保持封锁以及领奖开放。
- 结果：运行输出 `EXPLORATION_UI_CANDIDATE PASS`；截图真实来自 Godot 视口。导入阶段发现已有 addons/ggt-core/settings/settings_menu.gd 编辑器解析问题，未修改任务外插件，独立预览不受影响。
- 边界：奖励与调查是本场景样例状态，不接存档或玩法；没有实体手柄测试、手机／超宽屏、动态信号特效验收。背景仍仅研究稿。人工通过 005 后方可提升正式资源并进入主游戏接入评审。


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
