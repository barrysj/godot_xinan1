extends Control
## Isolated asset candidate: no campaign state or player saves.
signal action_requested(index: int)
const Hotspot = preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/005/hotspot.gd")
const POINTS = [Vector2(255,572),Vector2(543,358),Vector2(946,597),Vector2(1294,372)]
const TITLES = ["校园记忆","人物事件","借阅终端","守卫战"]
var buttons: Array[Button] = []
var labels: Array[Label] = []
var popup: PanelContainer
var heading: Label
var body: Label
var hint: Label
var primary: Button
var close_button: Button
var footer: Label
var connector: Control
var selected := -1
var guard_won := false
var reward_taken := false
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).anomaly

func style(bg: Color, border: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(8)
	result.set_content_margin_all(8)
	return result

func label(value: String, font_size := 20) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size",font_size)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func _ready() -> void:
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	theme.default_font_size = 20
	var background := TextureRect.new()
	background.texture = load("res://design/concepts/m1-exploration-ui/m1_exploration_ui/003/background-study.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	connector = Control.new()
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(connector)
	connector.draw.connect(_draw_connector)
	var title := PanelContainer.new()
	title.position = Vector2(28,24)
	title.add_theme_stylebox_override("panel",style(Color(0.03,0.05,0.09,0.85),Color(0.3,0.5,0.6,0.3)))
	add_child(title)
	title.add_child(label("图书馆    ●  ◉  ○  ○\n探索 · 第 2 / 4 站",20))
	footer = label("出口封锁 · 战胜守卫并领取奖励",20)
	footer.add_theme_stylebox_override("normal",style(Color(0.03,0.05,0.09,0.9),Color.TRANSPARENT))
	add_child(footer)
	var interference := label("∿  信号干扰",18)
	add_child(interference)
	interference.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	interference.position = Vector2(size.x-220,24)
	interference.add_theme_stylebox_override("normal",style(Color(0.03,0.05,0.09,0.85),Color.TRANSPARENT))
	for i in range(4):
		var button := Hotspot.new()
		button.kind = i
		button.tooltip_text = TITLES[i]
		add_child(button)
		button.pressed.connect(open_detail.bind(i))
		buttons.append(button)
		var caption := label(TITLES[i],20)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_stylebox_override("normal",style(Color(0.03,0.05,0.09,0.85),Color.TRANSPARENT))
		add_child(caption)
		labels.append(caption)
	for i in range(4):
		buttons[i].focus_next = buttons[(i+1)%4].get_path()
		buttons[i].focus_previous = buttons[(i+3)%4].get_path()
		buttons[i].focus_neighbor_right = buttons[(i+1)%4].get_path()
		buttons[i].focus_neighbor_left = buttons[(i+3)%4].get_path()
	popup = preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/005/detail_panel.gd").new()
	var panel := style(Color.TRANSPARENT,Color.TRANSPARENT)
	panel.set_content_margin_all(20)
	panel.corner_radius_top_right = 0
	panel.shadow_color = Color.TRANSPARENT
	panel.shadow_size = 0
	panel.shadow_offset = Vector2(0,7)
	popup.add_theme_stylebox_override("panel",panel)
	popup.custom_minimum_size = Vector2(360,0)
	add_child(popup)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	popup.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	heading = label("",24)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	close_button = Button.new()
	close_button.text = "×"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(44,44)
	close_button.tooltip_text = "关闭"
	close_button.pressed.connect(close_detail)
	row.add_child(close_button)
	body = label("",20)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 300
	column.add_child(body)
	hint = label("可选调查 · 不影响离场条件",17)
	column.add_child(hint)
	primary = Button.new()
	primary.text = "读取"
	primary.custom_minimum_size = Vector2(116,48)
	primary.size_flags_horizontal = Control.SIZE_SHRINK_END
	for state in ["normal","hover","pressed","focus"]:
		primary.add_theme_stylebox_override(state,style(Color("57bcd0") if state=="normal" else Color("91e1ec"),Color.TRANSPARENT))
	primary.add_theme_color_override("font_color",Color("102333"))
	primary.add_theme_color_override("font_hover_color",Color("102333"))
	primary.add_theme_color_override("font_focus_color",Color("102333"))
	primary.add_theme_color_override("font_pressed_color",Color("102333"))
	column.add_child(primary)
	primary.pressed.connect(_activate)
	primary.focus_next = close_button.get_path()
	primary.focus_previous = close_button.get_path()
	close_button.focus_next = primary.get_path()
	close_button.focus_previous = primary.get_path()
	primary.focus_neighbor_top = close_button.get_path()
	primary.focus_neighbor_bottom = close_button.get_path()
	close_button.focus_neighbor_top = primary.get_path()
	close_button.focus_neighbor_bottom = primary.get_path()
	popup.hide()
	resized.connect(_layout)
	_layout()
	buttons[0].grab_focus()
	if "--ui-capture" in OS.get_cmdline_user_args(): call_deferred("_capture")

func _layout() -> void:
	# Same cover transform as the background, while HUD remains screen anchored.
	var scale_value := maxf(size.x/1600.0,size.y/900.0)
	var offset := (size-Vector2(1600,900)*scale_value)/2
	for i in range(buttons.size()):
		buttons[i].size = Vector2(80,80)
		buttons[i].position = offset+POINTS[i]*scale_value-Vector2(40,40)
		labels[i].size = Vector2(172,36)
		labels[i].position = buttons[i].position+Vector2(-46,68)
	footer.position = Vector2(28,size.y-72)
	if selected >= 0:
		popup.reset_size()
		var target := buttons[selected].position+Vector2(110,-75)
		if target.x+popup.size.x > size.x-28:
			target.x = buttons[selected].position.x-popup.size.x-30
		popup.position = target.clamp(Vector2(28,28),size-popup.size-Vector2(28,28))
	connector.queue_redraw()

func open_detail(index: int) -> void:
	selected = index
	for i in range(4):
		buttons[i].selected = i==index
		buttons[i].focus_mode = Control.FOCUS_NONE
		buttons[i].queue_redraw()
	heading.text = TITLES[index]
	body.text = ["查看校园记忆记录。","与虚拟伙伴交流。","前代系统仍在执行早期目标。","守卫阻挡通路，胜利并领奖后才能离开。"][index]
	primary.text = "挑战" if index==3 else "读取"
	hint.text = "必经战斗 · 胜利后需领取奖励" if index==3 else "可选调查 · 不影响离场条件"
	popup.show()
	_layout()
	primary.grab_focus()

func close_detail() -> void:
	var previous := selected
	selected = -1
	popup.hide()
	for button in buttons:
		button.selected = false
		button.focus_mode = Control.FOCUS_ALL
		button.queue_redraw()
	if previous >= 0: buttons[previous].grab_focus()
	connector.queue_redraw()

func _activate() -> void:
	var index := selected
	action_requested.emit(index)
	if index < 3:
		buttons[index].completed = true
		labels[index].text = TITLES[index]+" · 已查看"
	close_detail()

func set_guard_result(won: bool, claimed: bool) -> void:
	guard_won = won
	reward_taken = won and claimed
	buttons[3].completed = won
	buttons[3].queue_redraw()
	labels[3].text = "守卫已解除" if won else "守卫战"
	footer.text = "出口开放 · 可离开或继续调查" if reward_taken else ("待领取奖励 · 出口仍封锁" if won else "出口封锁 · 战胜守卫并领取奖励")

func _input(event: InputEvent) -> void:
	if popup.visible and event.is_action_pressed("ui_cancel"):
		close_detail()
		get_viewport().set_input_as_handled()
	if popup.visible and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if not popup.get_global_rect().has_point(event.position):
			var over_hotspot := false
			for button in buttons:
				over_hotspot = over_hotspot or button.get_global_rect().has_point(event.position)
			if not over_hotspot: close_detail()

func _draw_connector() -> void:
	if selected >= 0 and popup.visible:
		var start := buttons[selected].position+buttons[selected].size/2
		var finish := popup.position+Vector2(0,70)
		if popup.position.x < start.x: finish.x += popup.size.x
		connector.draw_line(start,finish,Color(palette.cyan),1.5,true)

func _capture() -> void:
	# Hide the template version watermark only in isolated review captures.
	var transitions: Node = get_node("/root/GGT").get("_transitions")
	if is_instance_valid(transitions): transitions.get_node("Version").hide()
	var output := "res://design/concepts/m1-exploration-ui/review/codex-workflow/asset-005"
	DirAccess.make_dir_recursive_absolute(output)
	for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = dimensions
		await get_tree().process_frame
		await get_tree().process_frame
		close_detail()
		await _snap(output,dimensions,"default")
		await _click(buttons[2].get_global_rect().get_center())
		assert(selected==2 and popup.visible)
		var tab := InputEventAction.new()
		tab.action = "ui_focus_next"
		tab.pressed = true
		get_viewport().push_input(tab)
		await get_tree().process_frame
		assert(close_button.has_focus())
		primary.grab_focus()
		await _snap(output,dimensions,"detail")
		assert(Rect2(Vector2.ZERO,size).encloses(popup.get_rect()))
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		Input.parse_input_event(cancel)
		await get_tree().process_frame
		assert(not popup.visible and buttons[2].has_focus())
		await _click(buttons[3].get_global_rect().get_center())
		await get_tree().process_frame
		assert(selected==3 and Rect2(Vector2.ZERO,size).encloses(popup.get_rect()))
		await _click(Vector2(500,100))
		assert(not popup.visible)
		open_detail(0)
		await get_tree().process_frame
		await _click(primary.get_global_rect().get_center())
		assert(buttons[0].completed and not popup.visible)
		set_guard_result(true,false)
		assert(not reward_taken)
		set_guard_result(true,true)
		await _snap(output,dimensions,"complete")
		set_guard_result(false,false)
		buttons[0].completed = false
		labels[0].text = TITLES[0]
	print("EXPLORATION_UI_CANDIDATE PASS three sizes; details, cancel, focus, read, reward gate")
	get_tree().quit()

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion,true)
	await get_tree().process_frame
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event,true)
		await get_tree().process_frame

func _snap(output: String, dimensions: Vector2i, state: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size()==dimensions)
	assert(image.save_png(output+"/%s-%dx%d.png" % [state,dimensions.x,dimensions.y])==OK)
