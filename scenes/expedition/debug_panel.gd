extends CanvasLayer
const Commands = preload("res://game/debug/campus_debug.gd")
var hub
var panel: PanelContainer
var entry: Button
var was_paused = false
var backdrop: ColorRect

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
	panel.size = Vector2(minf(800,available.x-64),minf(800,available.y-64))
	panel.position = (available-panel.size)/2

func open() -> void:
	if panel.visible: return
	# Do not replace an exit confirmation or another interactive modal.
	if not hub.pending_exit.is_empty() or hub.reset_pending or is_instance_valid(hub.team_panel) or is_instance_valid(hub.location_panel) or is_instance_valid(hub.codex_panel): return
	was_paused = hub.paused
	hub._open_pause()
	hub.pause_overlay.hide()
	panel.show()
	entry.hide()
	_refresh()

func _refresh(message: String = "") -> void:
	panel.clear("DEBUG · 调试模式", "独立调试存档 · 不影响正式进度\n面板打开时战斗暂停。地点路线、已领取奖励和永久记录不随重抽重置。")
	if not message.is_empty(): panel.text(message,20)
	for item in [["skip","跳过战斗","按胜利处理当前战斗，继续领奖或终局操作。"], ["restart","重开战斗","保留阵容、装备和局内成长，恢复全体状态并返回战前部署。"], ["reroll","重抽事件","地点页更换未查看记录；旧事件页更换未选择事件；奖励页更换候选。"]]:
		var blocked = Commands.reason(hub,item[0])
		panel.button(item[1],item[0],blocked.is_empty())
		panel.text(item[2] if blocked.is_empty() else blocked,18)
	panel.button("返回游戏","close")
	panel.text("重开整个进度：返回基地 → 重开存档。Debug 下只重开调试存档。",18)

func close() -> void:
	panel.hide()
	entry.show()
	if was_paused: hub._open_pause()
	else: hub._resume_battle()

func _action(id: String) -> void:
	if id == "close":
		close()
		return
	if not Commands.reason(hub,id).is_empty(): return
	panel.hide()
	entry.show()
	hub._resume_battle()
	if not Commands.execute(hub,id):
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
