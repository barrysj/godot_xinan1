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
var pause_button: Button
var scroll: ScrollContainer
var error_text := ""
var save_blocked := false
var end_delay := -1.0
var pending_result: Dictionary = {}
var decision_visible := false
var presentation_alpha := 1.0

func _ready() -> void:
	if "--trial-check" in OS.get_cmdline_user_args():
		var check = load("res://scenes/trial/trial_check.gd").new()
		add_child(check)
		return
	var content_errors: Array[String] = Catalog.CONTENT_ERRORS
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
	_label(root_box, "破解%d点时暂停选择：断开维护立即破盾；接管维护在后续保护我方。" % Catalog.MANIFEST.hack_goal, 20)
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
	sim.start(run.formation, run.battle, run.rewards, run.gear, run.trainee)
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
	pause_button = _button(controls, "暂停", _toggle_pause)
	_button(controls, "倍速", func(): speed = 2 if speed == 1 else 1; _update_hud())
	status = _label(root_box, "", 20)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 24
	bar.max_value = Catalog.MANIFEST.hack_goal
	bar.show_percentage = false
	root_box.add_child(bar)
	decision = VBoxContainer.new()
	root_box.add_child(decision)
	decision.visible = false
	decision_visible = false
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
	var detail = _label(sidebar, "点击战场人物查看属性与当前行动。\n技能生效贡献%d点；队友验证漏洞贡献%d点。" % [Catalog.MANIFEST.skill_progress, Catalog.MANIFEST.verification_progress], 18)
	board.inspected.connect(func(text): detail.text = text)
	log_label = _label(root_box, "", 18)
	_update_hud()
	if sim.awaiting_choice: _show_choice()
	else: pause_button.grab_focus()

func _toggle_pause() -> void:
	if not running or sim.awaiting_choice or sim.finished: return
	paused = not paused
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if running and event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _update_hud() -> void:
	if not running or not is_instance_valid(status): return
	var state := "战斗结束" if sim.finished else ("等待选择" if sim.awaiting_choice else ("已暂停" if paused else ("维护中" if sim.hack_choice.is_empty() else "系统已修改")))
	status.text = "%.1f秒 · %d× · 破解 %d/%d · %s" % [sim.elapsed, speed, sim.progress, Catalog.MANIFEST.hack_goal, state]
	pause_button.text = "继续" if paused else "暂停"
	pause_button.disabled = sim.awaiting_choice or sim.finished
	bar.value = sim.progress
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
	if paused or sim.awaiting_choice:
		board.advance_presentation(0.0, presentation_alpha)
		return
	var before: float = sim.elapsed
	accumulator += minf(delta, 0.25) * speed
	while accumulator >= 0.05 and running and not sim.awaiting_choice:
		accumulator -= 0.05
		board.consume_events(sim.advance(0.05))
		if sim.finished:
			end_delay = 0.7
			break
	presentation_alpha = 1.0 if sim.finished else clampf(accumulator / 0.05, 0.0, 1.0)
	board.advance_presentation(sim.elapsed - before, presentation_alpha)
	if sim.elapsed > before: _update_hud()
	if sim.awaiting_choice: _show_choice()

func _show_choice() -> void:
	if decision_visible: return
	decision_visible = true
	decision.visible = true
	_label(decision, "破解完成 · 查看战况，选择如何改写维护系统", 22)
	var row = _row(decision)
	var cut := _row(row)
	cut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button = _button(cut, "断开维护", func(): _choose("disconnect"))
	_label(cut, "停止补盾，立即清除敌方系统护盾。", 19)
	var take := _row(row)
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(take, "接管维护", func(): _choose("takeover"))
	_label(take, "保留现存敌盾，后续改为保护我方。", 19)
	button.grab_focus()
	_update_hud()

func _choose(choice: String) -> void:
	if not sim.choose_hack(choice): return
	accumulator = 0
	board.consume_events(sim.drain_events())
	for child in decision.get_children():
		decision.remove_child(child)
		child.queue_free()
	decision_visible = false
	decision.visible = false
	_update_hud()
	pause_button.grab_focus()

func _finish() -> void:
	running = false
	var lines: Array[String] = ["%s · %.1f秒 · 破解%d点" % ["胜利，全队恢复" if sim.won else "失败，可调整后重试", sim.elapsed, sim.progress]]
	for name in sim.contributions: lines.append("%s：破解贡献%d" % [name, sim.contributions[name]])
	pending_result = {"won": sim.won, "summary": "；".join(lines)}
	_commit_result()

func _commit_result() -> void:
	if pending_result.is_empty(): return
	var committed: bool = run.transact(func(): return run.finish(pending_result.won, pending_result.summary))
	error_text = run.last_error
	save_blocked = run.load_blocked
	if committed: pending_result.clear()
	_render()

func _capture_flow() -> void:
	var choice_seen := false
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1600, 900)
	await get_tree().process_frame
	await _capture_image("trial-prepare")
	for encounter in range(Catalog.BATTLES.size()):
		_start()
		if not running:
			_capture_fail("无法开始第%d场：%s" % [encounter + 1, error_text])
			return
		var deadline := Time.get_ticks_msec() + 180000
		while running and sim.elapsed < 3.0 and not sim.awaiting_choice:
			await get_tree().process_frame
		await _capture_image("trial-combat-%d" % (encounter + 1))
		if encounter == 0:
			await _capture_image("trial-combat")
			_toggle_pause()
			var frozen_time: float = sim.elapsed
			var frozen_visual: float = board.visual_time
			var board_id: int = board.get_instance_id()
			await _capture_image("trial-paused")
			if not paused or board.get_instance_id() != board_id or sim.elapsed != frozen_time or board.visual_time != frozen_visual:
				_capture_fail("暂停必须保留棋盘并冻结模拟与动画")
				return
			_toggle_pause()
		while running:
			if Time.get_ticks_msec() > deadline:
				_capture_fail("第%d场超出截图等待时间" % (encounter + 1))
				return
			if sim.awaiting_choice:
				await _capture_image("trial-hack-%d" % (encounter + 1))
				if not choice_seen: await _capture_image("trial-hack")
				choice_seen = true
				_choose("disconnect")
			await get_tree().process_frame
		if not sim.won or not pending_result.is_empty():
			_capture_fail("第%d场未完成胜利结算：%s" % [encounter + 1, error_text])
			return
		if encounter < Catalog.BATTLES.size() - 1:
			await _capture_image("trial-reward-%d" % (encounter + 1))
			if encounter == 0: await _capture_image("trial-reward")
			var reward_id := "training" if encounter == 0 else "verify"
			if not _transaction(func(): return run.select_reward(reward_id, 3 if reward_id == "training" else -1)):
				_capture_fail("无法领取截图流程奖励：" + error_text)
				return
	if not choice_seen or run.phase != "complete":
		_capture_fail("截图流程必须实际抵达破解选择并通关")
		return
	await _capture_image("trial-complete")
	print("TRIAL CAPTURE PASS: three battles, hacking choices, two rewards, completion")
	get_tree().quit()

func _capture_image(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png("res://.godot/" + name + ".png") != OK:
		_capture_fail("无法写入截图：" + name)

func _capture_fail(message: String) -> void:
	push_error("TRIAL CAPTURE FAIL: " + message)
	get_tree().quit(1)
