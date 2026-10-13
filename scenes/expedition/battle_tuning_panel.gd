extends VBoxContainer
## A paused draft editor. Clicking controls never edits the live simulation.
signal apply_requested(settings: Dictionary)
signal back_requested
const Model = preload("res://game/debug/battle_tuning.gd")
const Ui = preload("res://scenes/ui/campus_ui.gd")
var hub
var draft: Dictionary
var selected_slot := 0
var slot_buttons: Dictionary = {}
var enemy_selector: OptionButton
var background_selector: OptionButton
var background_preview: TextureRect
var stat_fields: Dictionary = {}
var ally_health: SpinBox
var ally_attack: SpinBox
var message: Label
var apply_button: Button
var reset_button: Button
var loading := false

func setup(owner_hub) -> void:
	hub = owner_hub
	draft = Model.snapshot(hub)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",14)
	var backgrounds := HBoxContainer.new()
	backgrounds.add_theme_constant_override("separation",16)
	add_child(backgrounds)
	var background_choices := VBoxContainer.new()
	background_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backgrounds.add_child(background_choices)
	background_choices.add_child(Ui.label("战斗背景",22))
	background_selector = OptionButton.new()
	background_selector.custom_minimum_size = Vector2(240,48)
	background_selector.add_item("跟随地点")
	background_selector.set_item_metadata(0,"")
	for key in Model.BACKGROUNDS:
		background_selector.add_item(Model.BACKGROUNDS[key].name)
		background_selector.set_item_metadata(background_selector.item_count-1,key)
	Ui.apply_button(background_selector)
	background_choices.add_child(background_selector)
	background_selector.item_selected.connect(func(index: int):
		if loading: return
		draft.background = background_selector.get_item_metadata(index)
		draft.enabled = true
		_refresh_background())
	background_preview = TextureRect.new()
	background_preview.custom_minimum_size = Vector2(230,112)
	background_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	backgrounds.add_child(background_preview)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",24)
	add_child(body)
	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(roster)
	roster.add_child(Ui.label("敌方阵容 · 点击位置编辑",22))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	roster.add_child(grid)
	for slot in [3,4,5,0,1,2]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		cell.add_child(Ui.label(("前排" if slot < 3 else "后排") + " · " + ["左","中","右"][slot%3],16,"daily",true))
		var button := Button.new()
		button.custom_minimum_size = Vector2(162,100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_constant_override("icon_max_width",58)
		button.expand_icon = true
		button.add_theme_font_size_override("font_size",17)
		button.pressed.connect(func(): select_slot(slot))
		cell.add_child(button)
		slot_buttons[slot] = button
	var inspector := VBoxContainer.new()
	inspector.custom_minimum_size.x = 370
	inspector.add_theme_constant_override("separation",10)
	body.add_child(inspector)
	inspector.add_child(Ui.label("当前敌人",22))
	enemy_selector = OptionButton.new()
	enemy_selector.custom_minimum_size.y = 46
	enemy_selector.add_item("空位")
	enemy_selector.set_item_metadata(0,"")
	for definition in Model.Content.MANIFEST.enemies:
		enemy_selector.add_item(definition.display_name)
		enemy_selector.set_item_metadata(enemy_selector.item_count-1,definition.id)
	Ui.apply_button(enemy_selector)
	inspector.add_child(enemy_selector)
	enemy_selector.item_selected.connect(_select_enemy)
	var numbers := GridContainer.new()
	numbers.columns = 2
	numbers.add_theme_constant_override("h_separation",16)
	numbers.add_theme_constant_override("v_separation",8)
	inspector.add_child(numbers)
	for key in Model.STATS:
		var column := VBoxContainer.new()
		numbers.add_child(column)
		column.add_child(Ui.label(Model.STATS[key].name,17))
		var spin := number(Model.STATS[key].min,Model.STATS[key].max,Model.STATS[key].step)
		spin.custom_minimum_size.x = 170
		column.add_child(spin)
		spin.value_changed.connect(func(value: float):
			if not loading:
				draft.enemies[selected_slot].stats[key] = value
				draft.enabled = true)
		stat_fields[key] = spin
	var allies := HBoxContainer.new()
	allies.add_theme_constant_override("separation",16)
	add_child(allies)
	var health_label := Ui.label("己方生命 ×",20)
	health_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	health_label.custom_minimum_size.x = 130
	allies.add_child(health_label)
	ally_health = number(0.1,5,0.1)
	allies.add_child(ally_health)
	var attack_label := Ui.label("己方攻击 ×",20)
	attack_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	attack_label.custom_minimum_size.x = 130
	allies.add_child(attack_label)
	ally_attack = number(0.1,5,0.1)
	allies.add_child(ally_attack)
	ally_health.value_changed.connect(func(value: float):
		if loading: return
		draft.ally_health = value
		draft.enabled = true)
	ally_attack.value_changed.connect(func(value: float):
		if loading: return
		draft.ally_attack = value
		draft.enabled = true)
	message = Ui.label("输入最终属性；整备时应用后继续调整。单独编辑的同学使用绝对数值，优先于己方倍率。",17,"daily",true)
	add_child(message)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",16)
	add_child(actions)
	apply_button = _button("应用修改" if hub.phase == "prepare" else "应用重开",actions)
	apply_button.pressed.connect(func(): apply_requested.emit(draft.duplicate(true)))
	reset_button = _button("恢复默认",actions)
	reset_button.pressed.connect(func(): draft = Model.defaults(hub); _refresh())
	var back := _button("返回调试",actions)
	back.pressed.connect(func(): back_requested.emit())
	_refresh()

static func number(minimum: float, maximum: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.custom_minimum_size = Vector2(130,44)
	spin.add_theme_font_size_override("font_size",20)
	spin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var edit: LineEdit = spin.get_line_edit()
	# Commit before Button.pressed; Godot submits SpinBox focus loss deferred.
	edit.focus_exited.connect(spin.apply)
	var normal := Ui.panel_style("daily","quiet")
	normal.set_content_margin_all(8)
	edit.add_theme_stylebox_override("normal",normal)
	var focus := Ui.panel_style("daily","strong")
	focus.set_content_margin_all(8)
	edit.add_theme_stylebox_override("focus",focus)
	edit.add_theme_color_override("font_color",Color(Ui.colors("daily").text_primary))
	edit.add_theme_color_override("font_uneditable_color",Color(Ui.colors("daily").text_secondary))
	return spin

func _button(title: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(178,54)
	button.add_theme_font_size_override("font_size",22)
	Ui.apply_button(button)
	parent.add_child(button)
	return button

func _refresh() -> void:
	loading = true
	for index in background_selector.item_count:
		if background_selector.get_item_metadata(index) == draft.background: background_selector.select(index)
	ally_health.value = draft.ally_health
	ally_attack.value = draft.ally_attack
	loading = false
	select_slot(selected_slot)
	_refresh_background()

func select_slot(slot: int) -> void:
	selected_slot = slot
	loading = true
	var row: Dictionary = draft.enemies[slot]
	for index in enemy_selector.item_count:
		if enemy_selector.get_item_metadata(index) == row.id: enemy_selector.select(index)
	for key in stat_fields:
		stat_fields[key].editable = not row.id.is_empty()
		stat_fields[key].value = row.stats.get(key,Model.STATS[key].min)
	loading = false
	for index in slot_buttons:
		var definition = Model.enemy(draft.enemies[index].id)
		var button: Button = slot_buttons[index]
		button.text = "空位" if definition == null else definition.display_name
		button.icon = null if definition == null else definition.portrait
		Ui.apply_button(button,"daily","reward" if index == selected_slot else "primary")
		var values: Dictionary = draft.enemies[index].stats
		button.tooltip_text = "空位 · 点击配置敌人" if definition == null else "%s\n生命 %.0f · 攻击 %.0f · 防御 %.0f\n点击调整属性" % [definition.display_name,values.max_hp,values.atk,values.def]

func _select_enemy(index: int) -> void:
	if loading: return
	var row: Dictionary = draft.enemies[selected_slot]
	row.id = enemy_selector.get_item_metadata(index)
	row.stats = Model.default_stats(hub,row.id)
	draft.enabled = true
	select_slot(selected_slot)

func _refresh_background() -> void:
	background_preview.texture = hub.battle_background if draft.background.is_empty() else load(Model.BACKGROUNDS[draft.background].path)

func show_error(error: String) -> void:
	message.text = error
	message.add_theme_color_override("font_color",Color(Ui.colors("anomaly").error))
