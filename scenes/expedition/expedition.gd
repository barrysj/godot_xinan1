extends "res://scenes/battle_demo/pixel_battle.gd"
## Five-node vertical slice; all gameplay state belongs to ShortRun.

const RunModel = preload("res://game/run/short_run.gd")
const ProgressModel = preload("res://game/meta/campus_progress.gd")
var run = RunModel.new()
var progress = ProgressModel.new()
var screen = "base"
var chosen_node = 0
var report: Array[Dictionary] = []
var notice = ""
var chosen_supply = false
var expedition_seconds = 0.0
var is_test = false

func _ready() -> void:
	super._ready()
	is_test = "--run-smoke" in OS.get_cmdline_user_args() or "--run-capture" in OS.get_cmdline_user_args() or "--pause-flow-smoke" in OS.get_cmdline_user_args()
	is_test = is_test or "--meta-smoke" in OS.get_cmdline_user_args() or "--meta-capture" in OS.get_cmdline_user_args()
	is_test = is_test or "--codex-check" in OS.get_cmdline_user_args()
	is_test = is_test or "--random-check" in OS.get_cmdline_user_args()
	is_test = is_test or "--team-check" in OS.get_cmdline_user_args()
	if is_test:
		progress.path = "res://.godot/expedition-test-progress.json"
		if "--meta-smoke" in OS.get_cmdline_user_args() or "--meta-capture" in OS.get_cmdline_user_args():
			progress.path = "res://.godot/meta-test-progress.json"
	else:
		progress.read_save()
	notice = progress.error_message
	if "--run-smoke" in OS.get_cmdline_user_args():
		_run_smoke()
	elif "--run-capture" in OS.get_cmdline_user_args():
		_capture_run()

func _new_run() -> void:
	run = RunModel.new()
	if not ("--run-smoke" in OS.get_cmdline_user_args() or "--meta-smoke" in OS.get_cmdline_user_args()): run.generate()
	if progress.supply_unlocked and chosen_supply:
		run.badge_owned = true
		run.badge_wearer = 2
	formation = run.formation.duplicate()
	equipment = run.shoe_wearer
	selected = 0
	inspected_enemy_slot = -1
	phase = "prepare"
	screen = "map"
	chosen_node = 0
	expedition_seconds = 0
	notice = "选择亮起的地点，再点击进入。每一层只走一条路线。"
	if run.route_seed >= 0: notice = "本局路线已随机生成。每层选择一个地点，奖励也会随机出现。"
	paused = false

func _sync_team() -> void:
	run.formation = formation.duplicate()
	run.shoe_wearer = equipment

func _enter_node() -> void:
	if screen != "map" or not run.choose(chosen_node):
		return
	if run.node.kind == "event":
		screen = "event"
	else:
		encounter = run.node.encounter
		screen = "battle"
		phase = "prepare"
		_build_units()
		_note(run.node.name + "：点击敌人查看技能，调整阵型后出发。")

func _build_units() -> void:
	super._build_units()
	if run == null:
		return
	for u in units:
		if u.side == 0:
			var levels = int(run.training.get(u.role, 0))
			u.max_hp += levels * 50
			u.atk += levels * 5
			if run.badge_owned and u.role == run.badge_wearer:
				u.max_hp += 80
			u.hp = u.max_hp
		elif not run.node.is_empty():
			u.max_hp = roundf(u.max_hp * run.node.power)
			u.hp = u.max_hp
			u.atk = roundf(u.atk * run.node.power)
			if run.node.kind == "boss" and u.role == 4:
				u.name = "粉笔巨像"

func _process(delta: float) -> void:
	if screen == "battle":
		super._process(delta)
		if phase == "result" and not paused:
			report.clear()
			for u in units:
				if u.side == 0:
					report.append({"name": u.name, "damage": int(u.damage), "healing": int(u.healing)})
			screen = "report"
	else:
		if not paused:
			visual_time += delta
		queue_redraw()
	if not paused and screen in ["map","battle","event","reward","report"]:
		expedition_seconds += delta

func _after_report() -> void:
	if screen != "report":
		return
	if not result_won:
		run.retries += 1
		phase = "prepare"
		screen = "battle"
		_build_units()
		return
	if run.node.kind == "boss":
		run.complete_node()
		_settle()
	else:
		screen = "reward"

func _choose_reward(index: int) -> void:
	if screen != "reward":
		return
	var offers = run.offers()
	if index < 0 or index >= offers.size() or not run.take_reward(offers[index].id):
		return
	notice = "已获得「" + offers[index].title + "」。可以继续选择路线。"
	run.complete_node()
	chosen_node = 0
	screen = "map"

func _settle() -> void:
	if not run.settled:
		progress.points += run.points
		progress.completions += 1
		run.settled = true
		progress.write_save()
	screen = "summary"

func _swap_reserve() -> void:
	if phase != "prepare" or screen != "battle":
		return
	var reserve = -1
	for role in run.roster:
		if not formation.has(role):
			reserve = role
			break
	var slot = formation.find(selected)
	if reserve < 0 or slot < 0:
		return
	# Equipment stays with its owner, including when that owner is in reserve.
	formation[slot] = reserve
	selected = reserve
	pending_slot = -1
	_sync_team()
	_build_units()

func _return_to_formation() -> void:
	if screen != "battle":
		_resume_battle()
		return
	super._return_to_formation()

func _open_pause() -> void:
	super._open_pause()
	pause_actions.get_child(1).disabled = screen != "battle"

func _request_exit(destination: String) -> void:
	super._request_exit(destination)
	pause_caption.text = "本次探索尚未结算的进度将丢失。\n已保存的修复资源和解锁会保留。"

func _header(title: String, subtitle: String) -> void:
	_pixel_panel(Rect2(20, 16, 1220, 70), Color("344b42"))
	_text(Vector2(42, 47), title, PAPER, 27)
	_text(Vector2(43, 71), subtitle, Color("b8c0a0"), 14)
	_text(Vector2(936, 52), "修复资源  %d" % progress.points, GOLD, 18)
	_pixel_panel(Rect2(1148, 28, 78, 36), Color("e1d3ae"))
	_center(Vector2(1187, 53), "菜单", DARK, 17)

func _flow_button(rect: Rect2, title: String, enabled: bool = true) -> void:
	_pixel_panel(rect, Color("ddbb77") if enabled else Color("a2a18a"))
	_center(rect.get_center() + Vector2(0, 7), title, DARK, 20)

func _paragraph(at: Vector2, value: String, color: Color = DARK, font_size: int = 18) -> void:
	for line in value.split("\n"):
		_text(at, line, color, font_size)
		at.y += font_size + 12

func _node_pos(stage_index: int, index: int) -> Vector2:
	return Vector2(120 + stage_index * 165, 405 if stage_index == 0 else (295 if stage_index == 4 else ([265,230,280][stage_index-1] if index == 0 else [460,420,475][stage_index-1])))

func _draw() -> void:
	if font == null or town == null:
		return
	if screen == "battle":
		super._draw()
		# Replace sandbox enemy switching with expedition equipment and reserve controls.
		_pixel_panel(Rect2(950, 536, 290, 50), PAPER)
		var reserve_name = "暂无候补"
		for role in run.roster:
			if not formation.has(role): reserve_name = "换入" + ROLES[role]
		_flow_button(Rect2(950, 538, 140, 44), reserve_name, phase == "prepare" and run.roster.size() > 4 and inspected_enemy_slot < 0)
		_flow_button(Rect2(1100, 538, 138, 44), "装备笔记本", phase == "prepare" and run.badge_owned and inspected_enemy_slot < 0)
		_pixel_panel(Rect2(943, 495, 292, 30), PAPER)
		_text(Vector2(961, 514), "笔记本：" + (ROLES[run.badge_wearer] if run.badge_wearer >= 0 else ("背包中" if run.badge_owned else "未获得")), DARK, 14)
		_pixel_panel(Rect2(230, 25, 530, 48), Color("344b42"))
		_text(Vector2(244, 54), "%d / 5  ·  %s" % [run.stage + 1, run.node.name], PAPER, 23)
		return
	scale_factor = minf(size.x / 1280.0, size.y / 720.0)
	origin = (size - Vector2(1280, 720) * scale_factor) / 2
	draw_rect(Rect2(Vector2.ZERO, size), DARK)
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)
	match screen:
		"base": _draw_base()
		"map": _draw_map()
		"event": _draw_event()
		"reward": _draw_rewards()
		"report": _draw_report()
		"summary": _draw_summary()

func _draw_base() -> void:
	_header("重返校园 · 安全教室", "一次短途探索，找回放学铃声。")
	_campus()
	_pixel_panel(Rect2(155, 242, 630, 222), PAPER)
	_center(Vector2(470, 287), "今天，也一起回学校吧。", DARK, 29)
	_paragraph(Vector2(198, 334), "五个地点，两条分支，一个最终 Boss。\n胜利全员恢复，失败可以无限重新编队。\n沿途获得装备、训练和新同学。", DARK, 19)
	_pixel_panel(Rect2(936, 101, 306, 482), PAPER)
	_text(Vector2(959, 139), "校园修复", DARK, 23)
	_paragraph(Vector2(959, 185), "已完成探索：%d 次\n现有修复资源：%d" % [progress.completions, progress.points], DARK, 18)
	_text(Vector2(959, 298), "出发补给 · 厚笔记本", DARK, 19)
	_paragraph(Vector2(959, 335), "解锁后可在每次出发时携带。\n增加一名同学的生命上限。", DARK, 15)
	_flow_button(Rect2(956, 410, 270, 53), "补给：" + ("携带" if chosen_supply else "不携带") if progress.supply_unlocked else "3 修复资源 · 解锁", progress.supply_unlocked or progress.points >= 3)
	_paragraph(Vector2(959, 493), "通关后自动保存局外成长。\n当前探索暂不支持中途续玩。", Color("6b705a"), 14)
	_flow_button(Rect2(936, 610, 306, 64), "出发")
	_text(Vector2(40, 654), notice.left(54), GOLD, 17)

func _draw_map() -> void:
	_header("校园路线", "第 %d / 5 个地点  ·  本局修复资源 %d  ·  候补 %d 人" % [run.stage + 1, run.points, run.roster.size() - 4])
	_campus()
	for stage_index in range(4):
		for a in range(run.stages[stage_index].size()):
			for b in range(run.stages[stage_index + 1].size()):
				draw_line(_node_pos(stage_index, a), _node_pos(stage_index + 1, b), Color("b7b088"), 8)
	for stage_index in range(5):
		for index in range(run.stages[stage_index].size()):
			var node: Dictionary = run.stages[stage_index][index]
			var p = _node_pos(stage_index, index)
			var active: bool = stage_index == run.stage
			var visited: bool = run.visited.has(node.id)
			var fill = Color("ddbb77") if active else (Color("acbf8c") if visited else Color("a0a68a"))
			_pixel_panel(Rect2(p - Vector2(55, 52), Vector2(110, 104)), fill)
			if active and index == chosen_node:
				draw_rect(Rect2(p - Vector2(59, 56), Vector2(118, 112)), PAPER, false, 3)
			if node.kind == "event":
				_book_icon(p - Vector2(24, 37), 48)
			else:
				var tile = Vector2i(4, 9) if node.kind == "boss" else Vector2i(4, 7)
				_tile(dungeon, tile.x, tile.y, p - Vector2(24, 37), 3)
			_center(p + Vector2(0, 34), "已完成" if visited else {"battle":"战斗", "elite":"精英", "event":"事件", "boss":"BOSS"}[node.kind], DARK, 15)
			_center(p + Vector2(0, 79), node.name, DARK, 16)
	_pixel_panel(Rect2(936, 104, 306, 500), PAPER)
	var node: Dictionary = run.stages[run.stage][chosen_node]
	_text(Vector2(956, 146), node.name, DARK, 23)
	# Manual line breaks keep the small notebook readable on landscape screens.
	var snippets = {
		"gate": "首场战斗，敌人较弱。\n点击敌人可以查看技能。\n守护者适合放前排。",
		"library": "不用战斗，获得一次奖励。\n装备、训练、新同学三选一。",
		"court": "守卫搭配后排治疗。\n用远射技能打击治疗者。\n精英胜利多得 1 修复资源。",
		"hall": "回声广播不断治疗敌人。\n后排打击可以打破僵局。",
		"lab": "对方擅长整排攻击。\n分散站位、保护后排。",
		"supply": "同学准备的构筑补给。\n无需战斗，直接三选一。",
		"classroom": "整排攻击与后排投手。\n额外获得 1 修复资源。",
		"boss": "粉笔巨像堵住最终裂隙。\n战胜它，恢复校园铃声。\n失败可以无限重新编队。"}
	_paragraph(Vector2(956, 199), snippets[node.id], DARK, 17)
	_paragraph(Vector2(956, 378), "已拥有：篮球鞋\n笔记本：" + ("已获得" if run.badge_owned else "未获得") + "\n队伍人数：%d" % run.roster.size(), Color("6b705a"), 17)
	_flow_button(Rect2(956, 521, 266, 60), "进入")
	_pixel_panel(Rect2(24, 625, 1218, 67), Color("344b42"))
	_text(Vector2(44, 665), notice.left(66), PAPER, 17)

func _draw_event() -> void:
	_header(run.node.name, "校园记忆 / 补给事件")
	_campus()
	_pixel_panel(Rect2(194, 208, 580, 312), PAPER)
	_center(Vector2(484, 265), "有人把补给留在了这里。", DARK, 28)
	_paragraph(Vector2(239, 318), "纸条上写着：\n“如果你先到，就带上这些。\n我们在放学铃响起的地方见。”", DARK, 22)
	_flow_button(Rect2(277, 442, 414, 55), "收下心意 · 选择奖励")

func _draw_rewards() -> void:
	_header("带上新的可能", "从三份奖励中选择一份。本次选择会保留到探索结束。")
	var offers = run.offers()
	for i in range(3):
		var x = 58 + i * 409
		_pixel_panel(Rect2(x, 174, 346, 391), PAPER)
		if offers[i].id == "badge":
			_book_icon(Vector2(x + 125, 206), 90)
		elif offers[i].id == "recruit":
			_tile(dungeon, 3, 8, Vector2(x + 125, 206), 6)
		else:
			var p = Vector2(x + 116, 245)
			draw_rect(Rect2(p + Vector2(0, 6), Vector2(113, 13)), DARK)
			for offset in [0, 85]:
				draw_rect(Rect2(p + Vector2(offset, -18), Vector2(28, 62)), Color("587783"))
				draw_rect(Rect2(p + Vector2(offset + 5, -13), Vector2(7, 52)), Color("a6bfc0"))
		_center(Vector2(x + 173, 341), offers[i].title, DARK, 26)
		var description: String = offers[i].description
		# Wrap by character count rather than relying on hover text.
		var y = 387
		for line in description.split("\n"):
			while line.length() > 17:
				_text(Vector2(x + 24, y), line.left(17), DARK, 17)
				line = line.substr(17)
				y += 27
			_text(Vector2(x + 24, y), line, DARK, 17)
			y += 27
		_flow_button(Rect2(x + 26, 493, 294, 52), "选择")
	_text(Vector2(60, 635), "装备可在下场战前重新分配；新同学进入候补，通过“轮换候补”上阵。", PAPER, 19)

func _book_icon(p: Vector2, width: float) -> void:
	draw_rect(Rect2(p, Vector2(width, width)), DARK)
	draw_rect(Rect2(p + Vector2(4, 4), Vector2(width - 8, width - 8)), Color("c18c64"))
	draw_rect(Rect2(p + Vector2(width * 0.18, 4), Vector2(width * 0.12, width - 8)), Color("855d4e"))
	draw_rect(Rect2(p + Vector2(width * 0.40, width * 0.18), Vector2(width * 0.42, width * 0.3)), PAPER)

func _draw_report() -> void:
	_header("战斗胜利" if result_won else "暂时受阻", "全员已恢复，准备收取战利品。" if result_won else "保留本局构筑和装备，重新编队后可以无限重试。")
	_pixel_panel(Rect2(80, 127, 1115, 422), PAPER)
	_text(Vector2(112, 171), "%s  /  %.1f 秒" % [run.node.name, elapsed], DARK, 25)
	_text(Vector2(540, 221), "造成伤害", DARK, 19)
	_text(Vector2(866, 221), "有效治疗", DARK, 19)
	var max_damage = 1
	for entry in report:
		max_damage = maxi(max_damage, entry.damage)
	for i in range(report.size()):
		var entry = report[i]
		var y = 271 + i * 57
		_text(Vector2(115, y), entry.name, DARK, 23)
		draw_rect(Rect2(332, y - 17, 425 * float(entry.damage) / max_damage, 20), Color("90b37c"))
		_text(Vector2(772, y), str(entry.damage), DARK, 19)
		_text(Vector2(899, y), str(entry.healing), DARK, 19)
	_flow_button(Rect2(405, 587, 470, 66), ("结算" if run.node.kind == "boss" else "领奖") if result_won else "重试")

func _draw_summary() -> void:
	_header("放学铃，再次响起", "本次探索已完成。把找回的记忆带回安全教室。")
	_campus()
	_pixel_panel(Rect2(163, 224, 629, 308), PAPER)
	_center(Vector2(478, 275), "校园的裂隙安静下来了。", DARK, 28)
	_paragraph(Vector2(206, 325), "完成地点：%d / 5\n本次带回：%d 修复资源\n重新挑战：%d 次" % [run.visited.size(), run.points, run.retries], DARK, 22)
	_text(Vector2(207, 457), "同学们约好了，下次还一起出发。", Color("6b705a"), 20)
	_pixel_panel(Rect2(936, 117, 306, 413), PAPER)
	_paragraph(Vector2(960, 164), "校园修复\n\n总资源：%d\n完成探索：%d 次" % [progress.points, progress.completions], DARK, 21)
	_paragraph(Vector2(960, 364), "回基地后可花 3 点资源\n解锁新的出发补给。", DARK, 17)
	_text(Vector2(958, 478), "已保存" if progress.error_message.is_empty() else "保存失败，可点击下方重试", DARK, 16)
	_flow_button(Rect2(936, 582, 306, 69), "返回基地" if progress.error_message.is_empty() else "重试保存")

func _gui_input(event: InputEvent) -> void:
	if paused or leaving:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var p: Vector2 = (event.position - origin) / scale_factor
	if Rect2(1148, 28, 78, 36).has_point(p):
		_open_pause()
		accept_event()
		return
	if screen == "battle":
		if Rect2(950, 538, 140, 44).has_point(p):
			if inspected_enemy_slot < 0: _swap_reserve()
		elif Rect2(1100, 538, 138, 44).has_point(p):
			if phase == "prepare" and run.badge_owned and inspected_enemy_slot < 0:
				run.badge_wearer = selected
				if equipment == selected:
					equipment = -1
				_sync_team()
				_build_units()
		else:
			if _action_rect(2).has_point(p) and phase == "prepare" and run.badge_wearer == selected and inspected_enemy_slot < 0:
				run.badge_wearer = -1
			super._gui_input(event)
			_sync_team()
		accept_event()
		return
	match screen:
		"base":
			if Rect2(936, 610, 306, 64).has_point(p): _new_run()
			elif Rect2(956, 410, 270, 53).has_point(p):
				if progress.supply_unlocked: chosen_supply = not chosen_supply
				elif progress.unlock_supply(): chosen_supply = true
				notice = progress.error_message
		"map":
			for i in range(run.stages[run.stage].size()):
				if Rect2(_node_pos(run.stage, i) - Vector2(60, 60), Vector2(120, 145)).has_point(p): chosen_node = i
			if Rect2(956, 521, 266, 60).has_point(p): _enter_node()
		"event":
			if Rect2(277, 442, 414, 55).has_point(p): screen = "reward"
		"reward":
			for i in range(3):
				if Rect2(84 + i * 409, 493, 294, 52).has_point(p):
					_choose_reward(i)
					break
		"report":
			if Rect2(405, 587, 470, 66).has_point(p): _after_report()
		"summary":
			if Rect2(936, 582, 306, 69).has_point(p):
				if not progress.error_message.is_empty(): progress.write_save()
				else:
					screen = "base"
					notice = "修复资源已保存，可以解锁补给或再次出发。"
	accept_event()

func _run_smoke() -> void:
	for branch in range(3):
		_new_run()
		formation = [-1, 0, 3, 1, 2, -1]
		equipment = 1
		_sync_team()
		while run.stage < 5:
			chosen_node = branch % 2 if run.stages[run.stage].size() > 1 else 0
			_enter_node()
			if screen == "battle":
				if branch == 2 and run.roster.has(4) and formation.has(3):
					selected = 3
					_swap_reserve()
				_start()
				while screen == "battle": _process(1.0 / 30.0)
				print("RUN_BATTLE branch=", branch, " node=", run.node.id, " won=", result_won, " seconds=", elapsed)
				assert(result_won, "Route must be beatable without permanent upgrades")
				for u in units:
					if u.side == 0: assert(u.hp == u.max_hp)
				_after_report()
			else:
				screen = "reward"
			if screen == "reward":
				var old_stage: int = run.stage
				_choose_reward(0 if run.stage == 0 else (2 if run.stage == 1 else 1))
				assert(run.stage == old_stage + 1)
				_choose_reward(1)
				assert(run.stage == old_stage + 1, "Double reward prevented")
				if run.badge_owned: run.badge_wearer = 0
		assert(screen == "summary" and run.settled)
		var earned: int = progress.points
		_settle()
		assert(progress.points == earned, "Settlement idempotent")
		print("RUN_COMPLETE branch=", branch, " points=", run.points)
	assert(progress.error_message.is_empty(), progress.error_message)
	assert(progress.unlock_supply())
	var loaded = ProgressModel.new()
	loaded.path = progress.path
	loaded.read_save()
	assert(loaded.points == progress.points and loaded.supply_unlocked and loaded.completions == 3)
	chosen_supply = true
	_new_run()
	assert(run.badge_owned and run.badge_wearer == 2)
	_enter_node()
	formation = [-1, 0, 3, 1, 2, -1]
	run.roster.append(4)
	selected = 3
	_swap_reserve()
	assert(formation.has(4) and not formation.has(3))
	_start()
	for u in units:
		if u.side == 0: u.hp = 1
		else: u.atk = 9999; u.timer = 0
	while screen == "battle": _process(1.0 / 30.0)
	assert(not result_won)
	var saved_formation = formation.duplicate()
	_after_report()
	assert(screen == "battle" and phase == "prepare" and run.retries == 1)
	assert(formation == saved_formation and run.badge_owned)
	_start()
	_open_pause()
	var stopped = elapsed
	_process(5)
	assert(elapsed == stopped)
	_resume_battle()
	_process(0.1)
	assert(elapsed > stopped)
	# Follow the same clickable controls as a player, in virtual canvas coordinates.
	_resume_battle()
	screen = "base"
	_new_run()
	assert(screen == "map")
	_test_click(Vector2(1050, 550))
	assert(screen == "battle" and phase == "prepare")
	_test_click(_slot_rect(1, 0).get_center())
	assert(inspected_enemy_slot == 0)
	var former_equipment = equipment
	_test_click(_action_rect(2).get_center())
	assert(equipment == former_equipment)
	_test_click(_slot_rect(0, 0).get_center())
	_test_click(_slot_rect(0, 1).get_center())
	assert(formation[1] == 0)
	_test_click(_action_rect(0).get_center())
	assert(phase == "battle")
	_test_click(Vector2(1187, 46))
	assert(paused and pause_overlay.visible)
	pause_actions.get_child(0).pressed.emit()
	assert(not paused)
	while screen == "battle": _process(1.0 / 30.0)
	assert(result_won)
	_test_click(Vector2(600, 615))
	assert(screen == "reward")
	_test_click(Vector2(200, 520))
	assert(screen == "map" and run.stage == 1)
	_test_click(_node_pos(1, 1))
	assert(chosen_node == 1)
	print("RUN_INPUT base, route, enemy inspection, equipment guard, formation, battle, pause, report, reward passed")
	print("RUN_SMOKE full routes, rewards, restore, persistence, unlock, reserve, retry, pause passed")
	get_tree().quit()

func _test_click(point: Vector2) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = origin + point * scale_factor
	_gui_input(event)

func _capture_run() -> void:
	_new_run()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_map.png")
	_enter_node()
	formation = [-1, 0, 3, 1, 2, -1]
	equipment = 1
	_start()
	while screen == "battle": _process(1.0 / 30.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_report.png")
	_after_report()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_reward.png")
	_choose_reward(0)
	run.badge_wearer = 0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_map.png")
	while run.stage < 5:
		chosen_node = 0
		_enter_node()
		if screen == "battle":
			_start()
			while screen == "battle": _process(1.0 / 30.0)
			if not result_won:
				get_tree().quit(1)
				return
			_after_report()
		else:
			screen = "reward"
		if screen == "reward": _choose_reward(2 if run.stage == 1 else 1)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_summary.png")
	screen = "base"
	notice = "修复资源已保存，可以解锁补给或再次出发。"
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/expedition_base.png")
	get_tree().quit()
