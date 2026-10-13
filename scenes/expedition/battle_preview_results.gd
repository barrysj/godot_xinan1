extends Control
## The ordinary report owns statistics; preview adds only two terminal actions.
var hub
var canvas: Control
var actions: HBoxContainer
var quit_button: Button
var retry_button: Button
var error_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = hub.theme
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	error_label = preload("res://scenes/ui/campus_ui.gd").label("",17,"daily")
	error_label.position = Vector2(290,550)
	error_label.size = Vector2(700,30)
	canvas.add_child(error_label)
	error_label.hide()
	actions = HBoxContainer.new()
	actions.position = Vector2(290,587)
	actions.size = Vector2(700,66)
	actions.add_theme_constant_override("separation",20)
	canvas.add_child(actions)
	quit_button = hub._menu_button("退出游戏",func(): hub._preview_result_action("quit"))
	retry_button = hub._menu_button("重新战斗",func(): hub._preview_result_action("retry"))
	for button in [quit_button,retry_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(button)
	quit_button.focus_next = quit_button.get_path_to(retry_button)
	quit_button.focus_previous = quit_button.focus_next
	retry_button.focus_next = retry_button.get_path_to(hub.report_view.tabs)
	hub.report_view.tabs.focus_previous = hub.report_view.tabs.get_path_to(retry_button)
	hub.report_view.tabs.focus_next = hub.report_view.tabs.get_path_to(hub.report_view.table)
	hub.report_view.table.focus_previous = hub.report_view.table.get_path_to(hub.report_view.tabs)
	hub.report_view.table.focus_next = hub.report_view.table.get_path_to(quit_button)
	quit_button.focus_previous = quit_button.get_path_to(hub.report_view.table)
	retry_button.focus_previous = retry_button.focus_next
	quit_button.focus_neighbor_right = quit_button.focus_next
	retry_button.focus_neighbor_left = retry_button.focus_next
	resized.connect(_layout)
	visibility_changed.connect(func():
		if visible:
			error_label.hide()
			retry_button.grab_focus())
	_layout()
	hide()

func _layout() -> void:
	var factor := minf(size.x/1280,size.y/720)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (size-canvas.size*factor)/2

func show_error(message: String) -> void:
	error_label.text = message
	error_label.show()
