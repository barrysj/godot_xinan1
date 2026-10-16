extends Control
## Project settings, backed by the existing settings.cfg (never a second save system).
signal confirm_button_clicked
var snapshot: ConfigFile
var sliders: Dictionary = {}
var tutorial_toggle: CheckButton
var motion_toggle: CheckButton
var fullscreen_toggle: CheckButton
var vsync_toggle: CheckButton
var fps_picker: OptionButton
var save_button: Button
var cancel_button: Button
var reset_button: Button
var status: Label
var sheet: PanelContainer

func label(value: String, parent: Node, font_size := 20) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size",font_size)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result

func row(title: String, parent: Node) -> HBoxContainer:
	var result := HBoxContainer.new()
	result.add_theme_constant_override("separation",24)
	parent.add_child(result)
	var caption := label(title,result)
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	return result

func toggle(title: String, parent: Node, handler: Callable) -> CheckButton:
	var line := row(title,parent)
	var control := CheckButton.new()
	control.text = "开启"
	control.toggled.connect(handler)
	control.toggled.connect(func(v): control.text = "开启" if v else "关闭")
	line.add_child(control)
	return control

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	theme = preload("res://resources/theme/theme-main.tres")
	var dim := ColorRect.new()
	dim.color = Color(0.02,0.06,0.10,0.88)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	sheet = PanelContainer.new()
	sheet.minimum_size_changed.connect(func(): _layout.call_deferred())
	var style := preload("res://scenes/ui/campus_ui.gd").panel_style("night")
	sheet.add_theme_stylebox_override("panel",style)
	add_child(sheet)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",14)
	sheet.add_child(box)
	label("校园设置",box,32)
	label("调整游玩偏好 · 简体中文",box,18)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size.y = 120
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	label("操作与表现",content,24)
	tutorial_toggle = toggle("操作指引",content,func(v): GGT_GameConfig.config.set_value("game","tutorial_enabled",v))
	label("为教学阶段显示按钮高亮与箭头；不重置探索进度。",content,17)
	motion_toggle = toggle("简化特效",content,func(v): GGT_GameConfig.config.set_value("game","reduced_motion",v))
	label("简化破解粒子和代码飞行动画，保留效果提示。",content,17)
	label("声音",content,24)
	for entry in [["master","总音量"],["sfx","音效"],["music","音乐"]]:
		var line := row(entry[1],content)
		var slider := HSlider.new()
		slider.custom_minimum_size.x = 260
		slider.max_value = 100
		slider.step = 1
		line.add_child(slider)
		var percent := label("100%",line,18)
		percent.custom_minimum_size.x = 60
		sliders[entry[0]] = slider
		slider.value_changed.connect(func(v):
			percent.text = "%d%%" % v
			var db := -80.0 if v <= 0 else linear_to_db(v/100.0)
			match entry[0]:
				"master": GGT_GameConfig.set_master_volume(db)
				"sfx": GGT_GameConfig.set_sfx_volume(db)
				"music": GGT_GameConfig.set_music_volume(db)
		)
		percent.set_meta("channel",entry[0])
	label("音量控制已接入声道；当前部分场景尚未配置音乐与音效。",content,17)
	label("显示",content,24)
	if not OS.has_feature("web"):
		fullscreen_toggle = toggle("全屏显示",content,GGT_GameConfig.set_fullscreen)
		vsync_toggle = toggle("垂直同步",content,GGT_GameConfig.set_vsync)
		var line := row("帧率上限",content)
		fps_picker = OptionButton.new()
		for fps in [30,60,120,144,0]:
			fps_picker.add_item("不限" if fps == 0 else "%d FPS" % fps,fps)
		fps_picker.item_selected.connect(func(index): GGT_GameConfig.set_fps_limit(fps_picker.get_item_id(index)))
		line.add_child(fps_picker)
		label("开启垂直同步时，实际帧率也受显示器刷新率限制。",content,17)
	else:
		label("浏览器自动适配窗口；显示刷新与全屏由浏览器控制。",content,18)
	label("操作速查",content,24)
	label("点击地图热点查看详情；点击或拖动同学调整阵型。
战斗中 P 暂停／继续，Esc 打开菜单；速度按钮切换 0.5×、1×、1.5×、2×。
彩色下划线是术语，悬停查看解释，点击可固定阅读。",content,18)
	var terms = preload("res://scenes/ui/glossary_text.gd").make("常用术语：代码 · 破解 · 追踪 · 验证 · 护盾",18)
	content.add_child(terms)
	status = label("调整即时预览，保存后下次启动生效。",box,17)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation",16)
	box.add_child(actions)
	reset_button = button("恢复默认",actions,_defaults)
	cancel_button = button("取消",actions,_cancel)
	save_button = button("保存",actions,_save)
	visibility_changed.connect(_visibility)
	resized.connect(_layout)
	_layout.call_deferred()

func button(title: String, parent: Node, handler: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size = Vector2(110,44)
	result.pressed.connect(handler)
	parent.add_child(result)
	return result

func _layout() -> void:
	if sheet == null: return
	sheet.position = Vector2(maxf(16,(size.x-900)/2),24)
	sheet.size = Vector2(minf(900,size.x-32),size.y-48)

func _visibility() -> void:
	if not is_visible_in_tree(): return
	snapshot = ConfigFile.new()
	snapshot.parse(GGT_GameConfig.config.encode_to_text())
	_refresh()
	tutorial_toggle.grab_focus()

func _refresh() -> void:
	var config = GGT_GameConfig.config
	tutorial_toggle.set_pressed_no_signal(config.get_value("game","tutorial_enabled",true))
	motion_toggle.set_pressed_no_signal(config.get_value("game","reduced_motion",false))
	for key in sliders:
		var value := clampf(db_to_linear(float(config.get_value("audio",key,0.0)))*100,0,100)
		if float(config.get_value("audio",key,0.0)) <= -80: value = 0
		sliders[key].set_value_no_signal(roundf(value))
		for child in sliders[key].get_parent().get_children():
			if child.has_meta("channel"): child.text = "%d%%" % roundi(value)
	if fps_picker != null:
		fullscreen_toggle.set_pressed_no_signal(config.get_value("gfx","fullscreen",true))
		vsync_toggle.set_pressed_no_signal(config.get_value("gfx","vsync",true))
		var fps: int = config.get_value("gfx","fps_limit",60)
		var index := fps_picker.get_item_index(fps)
		if index < 0:
			fps_picker.add_item("%d FPS" % fps,fps)
			index = fps_picker.item_count-1
		fps_picker.select(index)
	for control in [tutorial_toggle,motion_toggle,fullscreen_toggle,vsync_toggle]:
		if control != null: control.text = "开启" if control.button_pressed else "关闭"
	status.text = "调整即时预览，保存后下次启动生效。"

func _defaults() -> void:
	# Defaults remain a preview until Save; Cancel restores the complete snapshot.
	GGT_GameConfig.initialize_default_file()
	GGT_GameConfig._apply_settings()
	_refresh()
	status.text = "已预览默认设置，点击保存确认。"

func _cancel() -> void:
	if snapshot != null: GGT_GameConfig.revert_to(snapshot)
	confirm_button_clicked.emit()

func _save() -> void:
	var error := GGT_GameConfig.config.save(GGT_GameConfig.settings_path)
	if error != OK:
		status.text = "设置保存失败，请检查存储空间后重试。"
		return
	confirm_button_clicked.emit()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
