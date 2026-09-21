extends Control
const Catalog = preload("res://game/trial/trial_catalog.gd")
const Model = preload("res://game/trial/trial_run.gd")
const Simulation = preload("res://game/trial/trial_simulation.gd")
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
var bar: ProgressBar
var status: Label
var log_label: Label
var decision: VBoxContainer
var ally_status: Label
var enemy_status: Label
var error_text := ""
var save_blocked := false

func _ready() -> void:
	if "--trial-check" in OS.get_cmdline_user_args():
		var check = load("res://scenes/trial/trial_check.gd").new()
		add_child(check)
		return
	if "--trial-capture" in OS.get_cmdline_user_args(): run.path = "res://.godot/trial-capture.json"
	elif not run.read_save():
		save_blocked = true
		error_text = "试炼存档无法读取，已停止写入。请保留原文件后检查。"
	theme = preload("res://resources/theme/theme-main.tres")
	add_theme_font_override("font", preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	add_theme_font_size_override("font_size", 23)
	var bg = ColorRect.new()
	bg.color = Color("09121e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var scroll = ScrollContainer.new()
	margin.add_child(scroll)
	root_box = VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 14)
	scroll.add_child(root_box)
	_render()
	if "--trial-capture" in OS.get_cmdline_user_args(): _capture_flow()

func _label(parent: Node, text: String, font_size := 23) -> Label:
	var label = Label.new()
	label.text = text
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
	if run.save():
		error_text = ""
		return true
	error_text = "保存失败：当前操作未确认，请重试。"
	return false

func _transaction(action: Callable) -> void:
	var before = run.snapshot()
	action.call()
	if not _persist(): run.restore(before)
	_render()

func _render() -> void:
	for child in root_box.get_children():
		root_box.remove_child(child)
		child.queue_free()
	var header = _row(root_box)
	var title = _label(header, "三战试炼  /  羁绊与系统破解", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "主菜单", func(): get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	_label(root_box, "虚构人物 · 三场固定战斗 · 胜利全恢复 · 失败可重新编队 · 中断战斗从战前继续", 20)
	if not error_text.is_empty(): _label(root_box, error_text)
	if save_blocked: return
	if run.phase == "complete":
		_label(root_box, "试炼完成 · 调试镜片出发资格已解锁", 30)
		_label(root_box, run.report)
		_label(root_box, "下一局可选择携带一件镜片，或空手出发；不是永久属性提升。")
		_button(root_box, "携镜出发", func(): _transaction(func(): run.restart("lens")))
		_button(root_box, "空手出发", func(): _transaction(func(): run.restart()))
	elif run.phase == "reward":
		_label(root_box, run.report)
		_label(root_box, "成长选择 · 三选一，整个试炼有效", 28)
		for id in run.options(): _reward_card(id)
	elif running:
		_battle_view()
	else:
		_prepare_view()
	_focus_first(root_box)

func _focus_first(node: Node) -> bool:
	for child in node.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return true
		if _focus_first(child): return true
	return false

func _prepare_view() -> void:
	var encounter: Dictionary = Catalog.BATTLES[run.battle]
	_label(root_box, "%d / 3  %s" % [run.battle + 1, encounter.name], 30)
	_label(root_box, encounter.hint + " 维护系统：每%.0f秒为敌方增加%.0f护盾。" % [encounter.pulse, encounter.shield])
	var enemy_names: Array[String] = []
	for u in Catalog.roster(run.formation, run.battle, run.rewards, run.gear, run.trainee):
		if u.side == 1: enemy_names.append("%s（生命%d / 攻击%d）" % [u.name, u.hp, u.atk])
	_label(root_box, "敌阵预告：" + "、".join(enemy_names), 19)
	_label(root_box, "破解100点时暂停：断开维护＝清除系统护盾；接管维护＝保留现存护盾，后续保护我方。", 20)
	if not run.report.is_empty(): _label(root_box, run.report, 20)
	var cards = _row(root_box)
	for i in range(6):
		var panel = VBoxContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		_label(panel, "上阵" if run.formation.has(i) else "候补", 18)
	_label(root_box, "当前人物：" + Catalog.NAMES[selected] + " — " + Catalog.DESCRIPTIONS[selected], 22)
	var slots = _row(root_box)
	for slot in range(6):
		var index: int = run.formation[slot]
		var column = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(column)
		_label(column, ("前排" if slot < 3 else "后排") + str(slot % 3 + 1), 19)
		_button(column, "空位" if index < 0 else Catalog.NAMES[index], func(): _transaction(func(): run.assign(selected, slot)))
	_label(root_box, "点人物，再点阵位部署或交换；四人上阵。", 19)
	var tags = Catalog.active_tags(run.formation)
	for tag in tags: _label(root_box, tag + "  ·  " + Catalog.TRAITS[tag], 20)
	for id in run.rewards:
		_label(root_box, "已获 " + Catalog.REWARDS[id].name + (" · " + Catalog.NAMES[run.trainee] if id == "training" else ""), 20)
	for item in run.gear:
		var row = _row(root_box)
		_label(row, Catalog.REWARDS[item].name + " · 当前归属：" + (Catalog.NAMES[int(run.gear[item])] if run.gear[item] >= 0 else "背包"), 21)
		_button(row, "转交", func(): _transaction(func(): run.equip(item, selected)))
		_button(row, "卸下", func(): _transaction(func(): run.equip(item, -1)))
	var start_button = _button(root_box, "开战", _start)
	start_button.disabled = run.formation.count(-1) != 2

func _reward_card(id: String) -> void:
	var reward: Dictionary = Catalog.REWARDS[id]
	_label(root_box, reward.name + " · " + reward.kind, 26)
	_label(root_box, reward.text, 21)
	if run.rewards.has(id):
		_label(root_box, "已持有；请选择其他成长。", 20)
	elif id == "training":
		var row = _row(root_box)
		for i in range(6): _button(row, Catalog.NAMES[i], func(): _transaction(func(): run.select_reward(id, i)))
	else:
		_button(root_box, "选择", func(): _transaction(func(): run.select_reward(id)))

func _start() -> void:
	if run.phase != "prepare" or run.formation.count(-1) != 2 or not _persist():
		_render()
		return
	sim.start(run.formation, run.battle, run.rewards, run.gear, run.trainee)
	running = true
	paused = false
	accumulator = 0
	_render()

func _battle_view() -> void:
	_label(root_box, Catalog.BATTLES[run.battle].name, 30)
	var controls = _row(root_box)
	_button(controls, "继续" if paused else "暂停", func(): paused = not paused; _render())
	_button(controls, "倍速", func(): speed = 2 if speed == 1 else 1; _update_hud())
	status = _label(root_box, "", 22)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 28
	root_box.add_child(bar)
	board = Board.new()
	board.custom_minimum_size.y = 270
	board.simulation = sim
	root_box.add_child(board)
	var roster_row = _row(root_box)
	ally_status = _label(roster_row, "", 18)
	enemy_status = _label(roster_row, "", 18)
	ally_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail = _label(root_box, "技能成功生效贡献4点，队友普攻验证漏洞贡献16点。点击人物查看当前属性。", 19)
	board.inspected.connect(func(text): detail.text = text)
	decision = VBoxContainer.new()
	root_box.add_child(decision)
	log_label = _label(root_box, "", 19)
	_update_hud()
	if sim.awaiting_choice: _show_choice()

func _update_hud() -> void:
	if not running or not is_instance_valid(status): return
	status.text = "%.1f秒 · %d× · 破解 %d/100 · %s" % [sim.elapsed, speed, sim.progress, "等待选择" if sim.awaiting_choice else ("维护中" if sim.hack_choice.is_empty() else "系统已修改")]
	bar.value = sim.progress
	var summaries: Array = [[], []]
	for u in sim.units:
		summaries[u.side].append("%d %s  %d/%d  盾%d%s" % [u.id + 1, u.name, u.hp, u.max_hp, u.shield, " · 漏洞" if sim.marks.has(u.id) else ""])
	ally_status.text = "我方\n" + "\n".join(summaries[0])
	enemy_status.text = "敌方\n" + "\n".join(summaries[1])
	log_label.text = "\n".join(sim.notes.slice(maxi(0, sim.notes.size() - 3)))
	board.queue_redraw()

func _process(delta: float) -> void:
	if not running or paused or sim.awaiting_choice: return
	accumulator += minf(delta, 0.25) * speed
	while accumulator >= 0.05 and running and not sim.awaiting_choice:
		accumulator -= 0.05
		sim.advance(0.05)
		if sim.finished:
			_finish()
			return
	_update_hud()
	if sim.awaiting_choice: _show_choice()

func _show_choice() -> void:
	_label(decision, "破解完成 · 战斗已暂停，请查看双方状态后选择。", 24)
	_label(decision, "断开：立即清除系统护盾并停止补盾。接管：保留敌方现有护盾，后续脉冲保护我方。", 20)
	var row = _row(decision)
	var button = _button(row, "断开维护", func(): _choose("disconnect"))
	_button(row, "接管维护", func(): _choose("takeover"))
	button.grab_focus()

func _choose(choice: String) -> void:
	if not sim.choose_hack(choice): return
	accumulator = 0
	for child in decision.get_children(): child.queue_free()
	_update_hud()

func _finish() -> void:
	running = false
	var lines: Array[String] = ["%s · %.1f秒 · 破解%d点" % ["胜利，全队恢复" if sim.won else "失败，可调整后重试", sim.elapsed, sim.progress]]
	for name in sim.contributions: lines.append("%s：破解贡献%d" % [name, sim.contributions[name]])
	var before = run.snapshot()
	run.finish(sim.won, "；".join(lines))
	if not _persist(): run.restore(before)
	_render()

func _capture_flow() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/trial-prepare.png")
	_start()
	while running and not sim.awaiting_choice: await get_tree().process_frame
	if not sim.awaiting_choice:
		push_error("Capture expected a real hacking decision before battle end")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/trial-hack.png")
	if sim.awaiting_choice: _choose("disconnect")
	while running: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/trial-reward.png")
	get_tree().quit()
