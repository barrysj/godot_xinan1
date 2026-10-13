extends CanvasLayer
const Commands = preload("res://game/debug/campus_debug.gd")
var hub
var panel: PanelContainer
var entry: Button
var was_paused = false
var was_menu_open = false
var backdrop: ColorRect
var difficulty_selector: OptionButton
var difficulty_apply: Button
var tuning_button: Button
var tuning_editor: VBoxContainer
var editing_battle := false

func _ready() -> void:
	layer = 20
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	entry = Button.new()
	entry.text = "调试"
	entry.tooltip_text = "打开调试面板（F8）"
	entry.theme = hub.theme
	entry.add_theme_font_size_override("font_size",16)
	for state in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("233943") if state == "normal" else Color("365666")
		style.border_color = Color("4AAFD0")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		style.content_margin_left = 8
		style.content_margin_right = 8
		entry.add_theme_stylebox_override(state,style)
	entry.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	entry.offset_left = -88
	entry.offset_right = -12
	entry.offset_top = 6
	entry.offset_bottom = 38
	root.add_child(entry)
	entry.pressed.connect(open)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04,0.08,0.12,0.48)
	root.add_child(backdrop)
	backdrop.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			backdrop.accept_event()
			close())
	panel = preload("res://scenes/expedition/campaign_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color(panel.palette.background)
	frame.border_color = Color(panel.palette.accent_primary)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(14)
	frame.shadow_color = Color(0,0,0,0.3)
	frame.shadow_size = 18
	panel.add_theme_stylebox_override("panel",frame)
	panel.visibility_changed.connect(func(): backdrop.visible = panel.visible)
	root.resized.connect(_layout_popup)
	_layout_popup()
	panel.hide()
	panel.action.connect(_action)

func _layout_popup() -> void:
	var available: Vector2 = panel.get_parent().size
	panel.size = Vector2(minf(1240 if editing_battle else 800,available.x-64),minf(960 if editing_battle else 800,available.y-64))
	panel.position = (available-panel.size)/2

func open() -> void:
	if panel.visible or (hub.debug_battle_preview and hub.screen == "report"): return
	if is_instance_valid(hub.battle_context): hub.battle_context.close()
	# Do not replace an exit confirmation or another interactive modal.
	if not hub.pending_exit.is_empty() or hub.reset_pending or is_instance_valid(hub.team_panel) or is_instance_valid(hub.location_panel) or is_instance_valid(hub.codex_panel): return
	was_paused = hub.paused
	was_menu_open = hub.pause_overlay.visible
	hub.paused = true
	hub.pause_overlay.hide()
	panel.show()
	entry.hide()
	_refresh()

func _refresh(message: String = "") -> void:
	editing_battle = false
	_layout_popup()
	panel.clear("DEBUG · 调试模式", "独立调试存档 · 不影响正式进度\n面板打开时战斗暂停。地点路线、已领取奖励和永久记录不随重抽重置。")
	panel.page_scroll.scroll_vertical = 0
	if not message.is_empty(): panel.text(message,20)
	var tuning_blocked: String = Commands.reason(hub,"restart")
	tuning_button = panel.button("战斗修改","tuning",tuning_blocked.is_empty())
	panel.text("调整敌人、背景与属性；整备中应用后继续整备。" if tuning_blocked.is_empty() else tuning_blocked,18)
	panel.text("战斗难度 · 当前：" + Commands.Difficulties.preset(hub.debug_battle_difficulty).name,22)
	var difficulty_row = HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation",16)
	panel.column.add_child(difficulty_row)
	var difficulty_blocked = Commands.reason(hub,"difficulty")
	if difficulty_blocked.is_empty() and hub.BattleTuning.active(hub): difficulty_blocked = "已启用自定义属性；在战斗修改中恢复默认后可使用难度预设。"
	difficulty_selector = OptionButton.new()
	difficulty_selector.custom_minimum_size = Vector2(220,58)
	difficulty_selector.add_theme_font_size_override("font_size",24)
	preload("res://scenes/ui/campus_ui.gd").apply_button(difficulty_selector,"daily")
	for id in Commands.Difficulties.ORDER:
		difficulty_selector.add_item(Commands.Difficulties.preset(id).name)
		difficulty_selector.set_item_metadata(difficulty_selector.item_count-1,id)
	difficulty_selector.select(Commands.Difficulties.ORDER.find(hub.debug_battle_difficulty))
	difficulty_selector.disabled = not difficulty_blocked.is_empty()
	difficulty_selector.tooltip_text = difficulty_blocked
	difficulty_row.add_child(difficulty_selector)
	difficulty_apply = panel.button("应用重开","difficulty",difficulty_blocked.is_empty(),difficulty_row)
	difficulty_apply.custom_minimum_size.x = 180
	difficulty_apply.tooltip_text = difficulty_blocked
	panel.text("保留当前敌阵与构筑，满血重启并立即开战；难度仅在本次 Debug 运行生效。" if difficulty_blocked.is_empty() else difficulty_blocked,18)
	for item in [["skip","跳过战斗","按胜利处理当前战斗，继续领奖或终局操作。"], ["restart","重开战斗","保留阵容、装备和局内成长，恢复全体状态并返回战前部署。"], ["reroll","重抽事件","地点页更换未查看记录；旧事件页更换未选择事件；奖励页更换候选。"]]:
		var blocked = Commands.reason(hub,item[0])
		panel.button(item[1],item[0],blocked.is_empty())
		panel.text(item[2] if blocked.is_empty() else blocked,18)
	panel.button("图书馆预览","library_preview")
	panel.text("查看九张正式环境图；只读，不写入正式存档。",18)
	panel.button("返回游戏","close")
	panel.text("重开整个进度：返回基地 → 重开存档。Debug 下只重开调试存档。",18)

func close() -> void:
	panel.hide()
	entry.show()
	hub.paused = was_paused
	hub.pause_overlay.visible = was_menu_open
	hub.queue_redraw()

func _show_tuning() -> void:
	editing_battle = true
	panel.clear("战斗修改", "六个敌方位置 · 修改只在应用后生效 · 切换地点恢复默认")
	panel.page_scroll.scroll_vertical = 0
	tuning_editor = preload("res://scenes/expedition/battle_tuning_panel.gd").new()
	panel.column.add_child(tuning_editor)
	tuning_editor.setup(hub)
	tuning_editor.back_requested.connect(_refresh)
	tuning_editor.apply_requested.connect(_apply_tuning)
	_layout_popup()

func _apply_tuning(settings: Dictionary) -> void:
	var error: String = hub.BattleTuning.validate(hub,settings)
	if not error.is_empty():
		tuning_editor.show_error(error)
		return
	panel.hide()
	entry.show()
	hub.pause_overlay.hide()
	hub.paused = false
	hub.pause_before_menu = false
	error = hub.BattleTuning.apply(hub,settings)
	if not error.is_empty():
		open()
		_show_tuning()
		tuning_editor.show_error(error)

func _action(id: String) -> void:
	if id == "tuning":
		if Commands.reason(hub,"restart").is_empty(): _show_tuning()
		return
	if id == "close":
		close()
		return
	if id == "library_preview":
		close()
		hub._show_library_environment_preview()
		return
	if not Commands.reason(hub,id).is_empty(): return
	var difficulty: String = str(difficulty_selector.get_selected_metadata()) if id == "difficulty" else ""
	panel.hide()
	entry.show()
	hub.pause_overlay.hide()
	hub.paused = false
	hub.pause_before_menu = false
	if not Commands.execute(hub,id,difficulty):
		open()
		_refresh("操作未完成：" + hub.progress.error_message)

func handle_input(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo: return false
	if event.keycode == KEY_F8:
		if panel.visible: close()
		else: open()
		return true
	if panel.visible and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		close()
		return true
	return false
