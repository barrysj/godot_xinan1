extends Control
const Catalog = preload("res://game/trial/trial_catalog.gd")
const Model = preload("res://game/trial/trial_run.gd")
const Simulation = preload("res://game/trial/code_trial_simulation.gd")
const Codes = preload("res://game/trial/code_catalog.gd")
const Sockets = preload("res://scenes/trial/code_sockets.gd")
const Board = preload("res://scenes/trial/trial_board.gd")
var run = Model.new()
var sim = Simulation.new()
var selected := 0
var running := false
var paused := false
var speed := 1
var accumulator := 0.0
var root_box: VBoxContainer
var board
var status: Label
var log_label: Label
var ally_status: Label
var enemy_status: Label
var pause_button: Button
var scroll: ScrollContainer
var error_text := ""
var save_blocked := false
var end_delay := -1.0
var pending_result: Dictionary = {}
var presentation_alpha := 1.0
var console: PanelContainer
var console_shade: ColorRect
var bank_labels := {}
var console_labels := {}
var program_controls := {}
var item_controls := {}

func _ready() -> void:
	if "--trial-check" in OS.get_cmdline_user_args():
		var check = load("res://game/trial/code_check.gd").new()
		add_child(check)
		return
	var content_errors: Array[String] = Catalog.CONTENT_ERRORS.duplicate()
	content_errors.append_array(Codes.validate())
	if not content_errors.is_empty():
		save_blocked = true
		error_text = "试炼内容暂时无法使用：\n" + "\n".join(content_errors)
	elif "--trial-capture" in OS.get_cmdline_user_args():
		run.path = "res://.godot/trial-capture-" + str(Time.get_ticks_usec()) + ".json"
	else:
		save_blocked = not run.read_save()
		error_text = run.last_error
	theme = preload("res://resources/theme/theme-main.tres")
	add_theme_font_override("font", preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	add_theme_font_size_override("font_size", 22)
	var bg = ColorRect.new()
	bg.color = Color("09121e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	root_box = VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 10)
	scroll.add_child(root_box)
	_render()
	if "--trial-capture" in OS.get_cmdline_user_args(): _capture_flow()

func _label(parent: Node, text: String, font_size := 23) -> Label:
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 48)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _row(parent: Node) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	return row

func _persist() -> bool:
	if save_blocked: return false
	var saved: bool = run.save()
	error_text = run.last_error
	save_blocked = run.load_blocked
	return saved

func _transaction(action: Callable) -> bool:
	var committed: bool = run.transact(action)
	error_text = run.last_error
	save_blocked = run.load_blocked
	_render()
	return committed

func _render() -> void:
	if is_instance_valid(console): console.queue_free()
	if is_instance_valid(console_shade): console_shade.queue_free()
	bank_labels.clear()
	console_labels.clear()
	program_controls.clear()
	item_controls.clear()
	for child in root_box.get_children():
		root_box.remove_child(child)
		child.queue_free()
	var header = _row(root_box)
	var title = _label(header, "三战试炼  /  羁绊与系统破解", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "主菜单", func(): get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	if not running: _label(root_box, "胜利全恢复 · 失败可调整重试 · 中断战斗从战前继续", 19)
	if not error_text.is_empty(): _label(root_box, error_text)
	if not pending_result.is_empty():
		_label(root_box, pending_result.summary, 24)
		_label(root_box, "战报尚未保存。重试成功后会继续结算；离开本页将回到战前检查点。", 20)
		_button(root_box, "重试保存", _commit_result).disabled = save_blocked
	elif save_blocked:
		_focus_first(root_box)
		return
	elif run.phase == "complete":
		_label(root_box, "试炼完成 · 调试镜片出发资格已解锁", 30)
		_label(root_box, run.report)
		_label(root_box, "下一局可选择携带一件镜片，或空手出发；不是永久属性提升。")
		_button(root_box, "携镜出发", func(): _transaction(func(): return run.restart("lens")))
		_button(root_box, "空手出发", func(): _transaction(func(): return run.restart()))
	elif run.phase == "reward":
		_label(root_box, run.report)
		_label(root_box, "成长选择 · 三选一，整个试炼有效", 28)
		var choices := _row(root_box)
		for id in run.options(): _reward_card(id, choices)
	elif running:
		_battle_view()
	else:
		_prepare_view()
	if not running: _focus_first(root_box)
	scroll.scroll_vertical = 0

func _focus_first(node: Node) -> bool:
	for child in node.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return true
		if _focus_first(child): return true
	return false

func _prepare_view() -> void:
	var encounter: Dictionary = Catalog.BATTLES[run.battle]
	var heading := _row(root_box)
	_label(heading, "%d / %d  %s" % [run.battle + 1, Catalog.BATTLES.size(), encounter.name], 28).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "开战", _start).disabled = not run.can_start()
	_label(root_box, encounter.hint + " 维护系统：每%.0f秒为敌方增加%.0f护盾。" % [encounter.pulse, encounter.shield])
	var enemy_names: Array[String] = []
	for u in Catalog.roster(run.formation, run.battle, run.rewards, run.gear, run.trainee):
		if u.side == 1: enemy_names.append("%s（生命%d / 攻击%d）" % [u.name, u.hp, u.atk])
	_label(root_box, "敌阵预告：" + "、".join(enemy_names), 19)
	_label(root_box, "每3次有效普攻产出1块代码；每色最多6块。战中点「破解」暂停使用配方和道具。", 20)
	_prepare_codes()
	if not run.report.is_empty(): _label(root_box, run.report, 20)
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 12)
	root_box.add_child(cards)
	for i in range(Catalog.ROLES.size()):
		var panel = VBoxContainer.new()
		panel.custom_minimum_size.x = 200
		cards.add_child(panel)
		var portrait = TextureRect.new()
		portrait.texture = Catalog.definition(i).portrait
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(64, 64)
		panel.add_child(portrait)
		var button = _button(panel, Catalog.NAMES[i], func(): selected = i; _render())
		button.tooltip_text = Catalog.DESCRIPTIONS[i]
		button.modulate = Color("79e4c5") if selected == i else Color.WHITE
		_label(panel, " / ".join(Catalog.TAGS[i]), 19)
		var kind: Dictionary = Codes.RULES.types[Catalog.MANIFEST.characters[i].code_type]
		_label(panel, kind.symbol + " " + kind.name, 18).modulate = kind.color
		_label(panel, "上阵" if run.formation.has(i) else "候补", 18)
	_label(root_box, "当前人物：" + Catalog.NAMES[selected] + " — " + Catalog.DESCRIPTIONS[selected], 22)
	var slots = _row(root_box)
	for slot in range(6):
		var index: int = run.formation[slot]
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(column)
		_label(column, ("前排" if slot < 3 else "后排") + str(slot % 3 + 1), 19)
		_button(column, "空位" if index < 0 else Catalog.NAMES[index], func(): _transaction(func(): return run.assign(selected, slot)))
	_label(root_box, "点人物，再点阵位部署或交换；四人上阵。", 19)
	var tags = Catalog.active_tags(run.formation)
	for tag in tags: _label(root_box, tag + "  ·  " + Catalog.TRAITS[tag], 20)
	for id in run.rewards:
		_label(root_box, "已获 " + Catalog.REWARDS[id].name + (" · " + Catalog.NAMES[run.trainee] if id == "training" else ""), 20)
	for item in run.gear:
		var row = _row(root_box)
		_label(row, Catalog.REWARDS[item].name + " · 当前归属：" + (Catalog.NAMES[int(run.gear[item])] if run.gear[item] >= 0 else "背包"), 21)
		_button(row, "转交", func(): _transaction(func(): return run.equip(item, selected)))
		_button(row, "卸下", func(): _transaction(func(): return run.equip(item, -1)))

func _reward_card(id: String, parent: Node) -> void:
	var reward: Dictionary = Catalog.REWARDS[id]
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 14)
	parent.add_child(card)
	_label(card, reward.name + " · " + reward.kind, 24)
	_label(card, reward.text, 21).custom_minimum_size.y = 100
	if run.rewards.has(id):
		_label(card, "已持有；请选择其他成长。", 20)
	elif reward.reward_type == "training":
		_label(card, "选择培养对象", 20)
		var target := OptionButton.new()
		target.custom_minimum_size.y = 48
		for i in range(Catalog.ROLES.size()): target.add_item(Catalog.NAMES[i], i)
		target.select(selected)
		card.add_child(target)
		_button(card, "选择", func(): _transaction(func(): return run.select_reward(id, target.get_selected_id())))
	else:
		if reward.reward_type == "exclusive" and not reward.character_id.is_empty():
			var owner: int = Catalog.ROLES.find(reward.character_id)
			if owner >= 0 and not run.formation.has(owner): _label(card, Catalog.NAMES[owner] + "当前在候补；可在下一场换上。", 19)
		_button(card, "选择", func(): _transaction(func(): return run.select_reward(id)))

func _start() -> void:
	if not run.can_start() or not pending_result.is_empty() or not _persist():
		_render()
		return
	sim.start(run.formation, run.battle, run.rewards, run.gear, run.trainee, run.programs, run.supplies)
	running = true
	paused = false
	accumulator = 0
	end_delay = -1.0
	presentation_alpha = 1.0
	_render()
	board.consume_events(sim.drain_events())

func _battle_view() -> void:
	var controls = _row(root_box)
	_label(controls, "%d / %d  %s" % [run.battle + 1, Catalog.BATTLES.size(), Catalog.BATTLES[run.battle].name], 26).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button = _button(controls, "破解", _toggle_pause)
	_button(controls, "倍速", func(): speed = 2 if speed == 1 else 1; _update_hud())
	status = _label(root_box, "", 20)
	bank_labels = _code_row(root_box)
	var battlefield := _row(root_box)
	board = Board.new()
	board.custom_minimum_size.y = 440
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.simulation = sim
	battlefield.add_child(board)
	board.reset_presentation()
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 330
	sidebar.add_theme_constant_override("separation", 12)
	battlefield.add_child(sidebar)
	ally_status = _label(sidebar, "", 18)
	enemy_status = _label(sidebar, "", 18)
	var detail = _label(sidebar, "每3次有效普攻产出1块；验证漏洞额外产出标记者类型的1块。\n点击人物查看属性。", 18)
	board.inspected.connect(func(text): detail.text = text)
	log_label = _label(root_box, "", 18)
	_build_console()
	_update_hud()
	pause_button.grab_focus()

func _toggle_pause() -> void:
	if not running or sim.finished: return
	if paused:
		_close_console()
	else:
		paused = true
		_update_hud()
		console_shade.show()
		console.show()
		console.position = (get_viewport_rect().size - console.size) / 2
		_focus_first(console)

func _close_console() -> void:
	console.hide()
	console_shade.hide()
	paused = false
	accumulator = 0
	_update_hud()
	pause_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if running and event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _update_hud() -> void:
	if not running or not is_instance_valid(status): return
	status.text = "%.1f秒 · %d× · %s · 距维护 %.1f秒 · 已执行%d次破解" % [sim.elapsed, speed, sim.system_status(), maxf(0, sim.next_pulse - sim.elapsed), sim.casts]
	pause_button.text = "继续" if paused else "破解"
	pause_button.disabled = sim.finished
	for group in [bank_labels, console_labels]:
		for kind in group:
			group[kind].configure(kind, sim.blocks[kind], Codes.RULES.cache_cap)
	for id in program_controls:
		var error: String = sim.program_error(id)
		program_controls[id].button.disabled = not error.is_empty()
		program_controls[id].state.text = "就绪" if error.is_empty() else error
		for kind in program_controls[id].recipe:
			program_controls[id].recipe[kind].configure(kind, mini(sim.blocks[kind], Codes.program(id).cost[kind]), Codes.program(id).cost[kind])
	for id in item_controls:
		var controls: Dictionary = item_controls[id]
		var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
		var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
		var error: String = sim.item_error(id, destination, source)
		controls.button.disabled = not error.is_empty()
		controls.preview.configure(destination, Codes.item(id).amount, Codes.item(id).amount, "生成 · " + Codes.RULES.types[destination].name)
		controls.state.text = "剩余%d次 · %s" % [sim.items[id], error if not error.is_empty() else ("%s → %d" % [Codes.RULES.types[destination].name, sim.blocks[destination] + Codes.item(id).amount])]
	if paused: _link_console_focus()
	var summaries: Array = [[], []]
	for u in sim.units:
		summaries[u.side].append("%s  %d/%d  盾%d%s" % [u.name, u.hp, u.max_hp, u.shield, " · 漏洞" if sim.marks.has(u.id) else ""])
	ally_status.text = "我方\n" + "\n".join(summaries[0])
	enemy_status.text = "敌方\n" + "\n".join(summaries[1])
	log_label.text = "\n".join(sim.notes.slice(maxi(0, sim.notes.size() - 2)))

func _process(delta: float) -> void:
	if not running: return
	if sim.finished:
		board.advance_presentation(delta, 1.0)
		end_delay -= delta
		if end_delay <= 0.0: _finish()
		return
	if paused:
		console.size = Vector2(1120, 700)
		console.position = (get_viewport_rect().size - console.size) / 2
		board.advance_presentation(0.0, presentation_alpha)
		return
	var before: float = sim.elapsed
	accumulator += minf(delta, 0.25) * speed
	while accumulator >= 0.05 and running and not paused:
		accumulator -= 0.05
		board.consume_events(sim.advance(0.05))
		if sim.finished:
			end_delay = 0.7
			break
	presentation_alpha = 1.0 if sim.finished else clampf(accumulator / 0.05, 0.0, 1.0)
	board.advance_presentation(sim.elapsed - before, presentation_alpha)
	if sim.elapsed > before: _update_hud()

func _code_row(parent: Node) -> Dictionary:
	var row := _row(parent)
	var sockets := {}
	for kind in Codes.RULES.types:
		var display := Sockets.new()
		display.configure(kind, 0, Codes.RULES.cache_cap)
		row.add_child(display)
		sockets[kind] = display
	return sockets

func _code_card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172b3e")
	style.border_color = Color("38556c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box
func _prepare_codes() -> void:
	var row := _row(root_box)
	for slot in range(2):
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var select := OptionButton.new()
		select.custom_minimum_size.y = 44
		for program in Codes.RULES.programs:
			select.add_item(program.display_name + " · " + Codes.cost_text(program.cost))
			if program.id == run.programs[slot]: select.select(select.item_count - 1)
		column.add_child(select)
		select.item_selected.connect(func(index): _transaction(func(): return run.set_program(slot, Codes.RULES.programs[index].id)))
		var program = Codes.program(run.programs[slot])
		_label(column, program.description, 18)
		var available: Array = []
		for role in run.formation:
			if role >= 0: available.append(Catalog.MANIFEST.characters[role].code_type)
		for kind in program.cost:
			if not available.has(kind): _label(column, "缺少" + Codes.RULES.types[kind].name + "产出人物，可换阵或用道具补足。", 17)
	var stock: Array[String] = []
	for id in run.supplies: stock.append("%s×%d" % [Codes.item(id).display_name, run.supplies[id]])
	_label(root_box, "道具：" + " · ".join(stock) + "；三战共享，失败重试返还本场消耗。", 19)

func _build_console() -> void:
	console_shade = ColorRect.new()
	console_shade.color = Color(0, 0, 0, 0.72)
	console_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	console_shade.z_index = 3998
	console_shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _close_console())
	add_child(console_shade)
	console_shade.hide()
	console = PanelContainer.new()
	console.name = "CodeConsole"
	console.custom_minimum_size = Vector2(1120, 700)
	console.size = Vector2(1120, 700)
	console.z_index = 3999
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("101f30")
	surface.border_color = Color("76e5cb")
	surface.set_border_width_all(2)
	surface.set_corner_radius_all(12)
	console.add_theme_stylebox_override("panel", surface)
	add_child(console)
	console.hide()
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 22)
	console.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 1072
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var heading := _row(box)
	_label(heading, "代码终端 · 战斗已暂停", 26)
	_button(heading, "继续", _close_console)
	console_labels = _code_row(box)
	_label(box, "实心代码已备齐 · 空槽仍需收集  /  程序共享3秒冷却", 17)
	var programs := _row(box)
	for id in run.programs:
		var program = Codes.program(id)
		var card := _code_card(programs)
		var header := _row(card)
		var symbols := {"disconnect":"⌁", "redirect":"⇄", "repair":"+", "takeover":"#"}
		_label(header, symbols[id] + "  " + program.display_name, 26)
		var button := _button(header, "执行", func(): _cast_code(id))
		button.tooltip_text = program.description
		var ingredients := _row(card)
		var recipe := {}
		for kind in program.cost:
			var sockets := Sockets.new()
			sockets.configure(kind, 0, program.cost[kind])
			ingredients.add_child(sockets)
			recipe[kind] = sockets
		_label(card, program.description, 17)
		var state := _label(card, "", 17)
		program_controls[id] = {"button":button, "state":state, "recipe":recipe}
	var items := _row(box)
	for entry in Codes.RULES.items:
		var id: String = entry.id
		var card := _code_card(items)
		var header := _row(card)
		_label(header, ("⊞  " if entry.effect == "generate" else "⇄  ") + entry.display_name, 22)
		var button := _button(header, "使用", func(): _use_code_item(id))
		button.tooltip_text = entry.description
		var row := _row(card)
		var controls := {"button":button}
		if entry.effect == "convert":
			controls.source = _type_picker(row)
			var arrow := _label(row, "−2 →", 18)
			arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
			arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		controls.destination = _type_picker(row)
		if entry.effect == "convert": controls.destination.select(1)
		controls.preview = Sockets.new()
		card.add_child(controls.preview)
		controls.state = _label(card, "", 17)
		item_controls[id] = controls
func _type_picker(parent: Node) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(150, 44)
	for kind in Codes.RULES.types:
		var data: Dictionary = Codes.RULES.types[kind]
		picker.add_item(data.symbol + " " + data.name)
	parent.add_child(picker)
	picker.item_selected.connect(func(_index): _update_hud())
	return picker

func _link_console_focus() -> void:
	var buttons: Array[Control] = []
	_collect_console_focus(console, buttons)
	for index in range(buttons.size()):
		buttons[index].focus_next = buttons[index].get_path_to(buttons[(index + 1) % buttons.size()])
		buttons[index].focus_previous = buttons[index].get_path_to(buttons[posmod(index - 1, buttons.size())])

func _collect_console_focus(node: Node, output: Array[Control]) -> void:
	for child in node.get_children():
		if child is BaseButton and not child.disabled: output.append(child)
		_collect_console_focus(child, output)

func _cast_code(id: String) -> void:
	if not running or not paused or not sim.cast_program(id): return
	board.consume_events(sim.drain_events())
	_update_hud()

func _use_code_item(id: String) -> void:
	if not running or not paused: return
	var controls: Dictionary = item_controls[id]
	var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
	var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
	if sim.use_item(id, destination, source): board.consume_events(sim.drain_events())
	_update_hud()

func _finish() -> void:
	running = false
	var lines: Array[String] = ["%s · %.1f秒 · 执行%d次破解" % ["胜利，全队恢复" if sim.won else "失败，可调整后重试", sim.elapsed, sim.casts]]
	for name in sim.contributions: lines.append("%s：代码贡献%d块" % [name, sim.contributions[name]])
	pending_result = {"won": sim.won, "summary": "；".join(lines), "items":sim.items.duplicate()}
	_commit_result()

func _commit_result() -> void:
	if pending_result.is_empty(): return
	var committed: bool = run.transact(func(): return run.finish(pending_result.won, pending_result.summary, pending_result.items))
	error_text = run.last_error
	save_blocked = run.load_blocked
	if committed: pending_result.clear()
	_render()

func _capture_flow() -> void:
	speed = 2
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	await _capture_image("trial-code-prepare")
	var casts_seen := 0
	var items_seen := 0
	for encounter in range(Catalog.BATTLES.size()):
		_start()
		if not running: _capture_fail("无法开战：" + error_text); return
		var deadline := Time.get_ticks_msec() + 180000
		var shown := false
		var next_decision := 6.0
		while running:
			if Time.get_ticks_msec() > deadline: _capture_fail("战斗超时"); return
			if not sim.finished and sim.elapsed >= next_decision:
				next_decision = sim.elapsed + 1.0
				_toggle_pause()
				var frozen_time: float = sim.elapsed
				var visual_time: float = board.visual_time
				var board_id: int = board.get_instance_id()
				for id in sim.items:
					if sim.items[id] == 0: continue
					var controls: Dictionary = item_controls[id]
					for destination in Codes.RULES.types:
						var source := ""
						if controls.has("source"):
							for candidate in Codes.RULES.types:
								if sim.item_error(id, destination, candidate).is_empty(): source = candidate; break
						if not sim.item_error(id, destination, source).is_empty(): continue
						controls.destination.select(Codes.RULES.types.keys().find(destination))
						if controls.has("source"): controls.source.select(Codes.RULES.types.keys().find(source))
						_update_hud()
						controls.button.pressed.emit()
						items_seen += 1
						break
				if not shown:
					await _capture_image("trial-code-console-%d" % (encounter + 1))
					if encounter == 0: await _capture_image("trial-code-console")
					if not get_viewport_rect().encloses(console.get_global_rect()): _capture_fail("终端越出视口"); return
					shown = true
				if sim.elapsed != frozen_time or board.visual_time != visual_time or board.get_instance_id() != board_id:
					_capture_fail("终端必须冻结战斗并保留棋盘"); return
				for id in run.programs:
					if sim.program_error(id).is_empty():
						program_controls[id].button.pressed.emit()
						casts_seen += 1
						break
				_close_console()
			await get_tree().process_frame
		if not sim.won or not pending_result.is_empty(): _capture_fail("未完成胜利结算"); return
		if encounter < Catalog.BATTLES.size() - 1:
			await _capture_image("trial-code-reward-%d" % (encounter + 1))
			var id := "training" if encounter == 0 else "verify"
			if not _transaction(func(): return run.select_reward(id, 3 if id == "training" else -1)):
				_capture_fail("领奖失败"); return
	if casts_seen < 2 or items_seen != 2 or run.phase != "complete": _capture_fail("须真实使用两道具、破解并通关"); return
	await _capture_image("trial-code-complete")
	print("CODE CAPTURE PASS casts=%d items=%d three victories" % [casts_seen, items_seen])
	get_tree().quit()

func _capture_image(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png("res://.godot/" + name + ".png") != OK:
		_capture_fail("无法写入截图：" + name)

func _capture_fail(message: String) -> void:
	push_error("TRIAL CAPTURE FAIL: " + message)
	get_tree().quit(1)
