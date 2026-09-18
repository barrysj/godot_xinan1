# 013 M1 探索热点交互条带候选

013 延续已批准的 012 浮窗／按钮与 011 四枚热点图标，只新增一张可复用、无文字的 `interaction-strip.png`。负责人已确认概念方向：以倾斜、不规则的深色条带提示热点可交互，移除常驻“校园记忆”“人物事件”等文字；点击后由弹窗显示完整名称与说明。

## 设计与交互

- 常态：图标下方保留低强调的异形信号条，不显示名称。
- 鼠标悬停、键盘／手柄聚焦：条带提亮并显示程序文字名称。
- 点击：原详情弹窗继续显示标题与说明；不把文字烘焙进图片。
- 完成态：条带转为低饱和绿色并降低强调度，图标原有勾号与降亮逻辑保留。
- 条带不承担按钮职责，不使用规则圆角框、胶囊或白色描边；透明点击区仍由 118×118 的原生 Button 提供。

## 生成与处理

- 使用内置 imagegen，以已批准 012 深色按钮作为仅限材质与配色的视觉参考，生成独立透明 PNG。
- 提示要求：约 4.5:1 的短横向轮廓、左右不对称切口、整体轻微左低右高、深蓝黑半透明玻璃、克制青色边线与单个品红干扰刻度；中心保持安静；无文字、图标、箭头、白框、按钮或面板语义。
- 原始输出保存为 `interaction-strip-source.png`；裁去透明空边并以 Lanczos3 规范化为 `interaction-strip.png`（360×71 RGBA）。源图与运行候选均保留真实透明通道。

## 当前阶段

013 为 `unselected / pending` 资产候选，不替换 `assets/art/`，也不修改真实战役接入。Godot 独立预览复用 012/011 的已批准资产与正式图书馆背景，验证 default/detail/complete、鼠标、焦点、Esc、读取和奖励门槛。负责人批准具体条带及预览效果后，才提升到正式路径并改造真实 `exploration_board.gd`。

Godot 4.7.2 Compatibility 实际输出 `EXPLORATION_UI_CANDIDATE PASS three sizes; details, cancel, focus, read, reward gate`，九张截图保存于 `design/concepts/m1-exploration-ui/review/codex-workflow/preview-013/`。已查看 1920×1080 默认／详情和 1920×1200 完成态：常态条带不显示文字，首个键盘焦点显示名称，打开弹窗后热点名称自动隐藏，完成态条带降亮且勾号保留。两张 PNG 均为 RGBA，Alpha 0–255；资源台 33 项测试通过，目录扫描 0 mismatch / 0 missing / 0 errors。
