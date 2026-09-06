extends Control
## Disposable battle prototype: formation and automatic skill readability.

const STEP = 0.05
const INK = Color("e5edf3")
const MUTED = Color("94a8b7")
const TEAL = Color("62e4c1")
const RED = Color("ff8c82")
const GOLD = Color("f7cc78")
const ROLES = ["守护者", "远射手", "应援者", "冲刺手", "发明家"]
const SKILLS = ["并肩：自身与相邻友军获得护盾", "穿云：优先射击后排，造成高伤害", "应援：治疗生命比例最低的队友", "冲刺：追击生命比例最低的敌人", "实验：对目标所在整排造成伤害"]

var font: Font
var formation = [0, -1, 3, 2, 1, -1]
var selected = 0
var pending_slot = -1
var equipment = 0
var encounter = 0
var phase = "prepare"
var units: Array[Dictionary] = []
var elapsed = 0.0
var accumulator = 0.0
var speed = 1
var paused = false
var result_won = false
var logs: Array[String] = []
var beams: Array[Dictionary] = []
var scale_factor = 1.0
var origin = Vector2.ZERO

func _ready() -> void:
	font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	_build_units()
	_note("点击同学，再点击目标格换位。前排承伤，技能每 3 次普攻自动释放。")
	if "--demo-smoke" in OS.get_cmdline_user_args():
		_smoke()
	elif "--demo-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/battle_demo.png")
		_start()
		await get_tree().create_timer(6.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/battle_demo_combat.png")
		get_tree().quit()

func _unit(label: String, role: int, side: int, slot: int, hp: float, atk: float, interval: float, defense: float) -> Dictionary:
	return {"name": label, "role": role, "side": side, "slot": slot,
		"max_hp": hp, "hp": hp, "atk": atk, "interval": interval,
		"timer": interval, "def": defense, "shield": 0.0, "count": 0,
		"flash": 0.0, "damage": 0.0, "healing": 0.0}

func _build_units() -> void:
	units.clear()
	beams.clear()
	var stats = [[350.0, 22.0, 1.8, 25.0], [175.0, 35.0, 1.45, 5.0], [195.0, 19.0, 1.8, 8.0], [210.0, 29.0, 1.25, 10.0], [230.0, 24.0, 1.9, 8.0]]
	for slot in range(6):
		var role: int = formation[slot]
		if role < 0:
			continue
		var s: Array = stats[role]
		var u = _unit(ROLES[role], role, 0, slot, s[0], s[1], s[2], s[3])
		if role == equipment:
			u.interval *= 0.75
			u.timer = u.interval
		units.append(u)
	if encounter == 0:
		units.append(_unit("纸甲守卫", 0, 1, 0, 330, 27, 1.7, 25))
		units.append(_unit("巡游课桌", 3, 1, 2, 240, 29, 1.6, 12))
		units.append(_unit("回声广播", 2, 1, 4, 185, 18, 1.8, 5))
		units.append(_unit("飞页投手", 1, 1, 5, 165, 29, 1.65, 5))
	else:
		units.append(_unit("错位黑板", 4, 1, 1, 680, 38, 2.0, 20))
		units.append(_unit("粉笔精灵", 1, 1, 3, 190, 28, 1.6, 5))
		units.append(_unit("粉笔精灵", 1, 1, 5, 190, 28, 1.6, 5))
	elapsed = 0
	accumulator = 0
	paused = false

func _start() -> void:
	pending_slot = -1
	_build_units()
	phase = "battle"
	logs.clear()
	_note("开战！阵型已锁定，技能全自动。")

func _process(delta: float) -> void:
	for u in units:
		u.flash = maxf(0, u.flash - delta)
	for b in beams:
		b.life -= delta
	beams = beams.filter(func(b): return b.life > 0)
	if phase == "battle" and not paused:
		accumulator += delta * speed
		while accumulator >= STEP and phase == "battle":
			accumulator -= STEP
			_tick()
	queue_redraw()

func _living(side: int) -> Array[Dictionary]:
	return units.filter(func(u): return u.side == side and u.hp > 0)

func _target(actor: Dictionary, candidates: Array[Dictionary], rule: String = "normal") -> Dictionary:
	var best: Dictionary = {}
	var best_score = INF
	for u in candidates:
		var score: float
		if rule == "low":
			score = u.hp / u.max_hp * 1000.0 + u.slot * 0.001
		elif rule == "back":
			score = (0 if u.slot >= 3 else 100) + absi(u.slot % 3 - actor.slot % 3) * 10 + u.slot
		else:
			score = (0 if u.slot < 3 else 100) + absi(u.slot % 3 - actor.slot % 3) * 10 + u.slot
		if score < best_score:
			best_score = score
			best = u
	return best

func _event(events: Array[Dictionary], actor: Dictionary, target: Dictionary, kind: String, value: float, special: bool = false) -> void:
	if not target.is_empty():
		events.append({"actor": actor, "target": target, "kind": kind, "value": value, "special": special})

func _tick() -> void:
	elapsed += STEP
	var events: Array[Dictionary] = []
	for actor in units:
		if actor.hp <= 0:
			continue
		actor.timer -= STEP
		if actor.timer > 0.00001:
			continue
		actor.timer += actor.interval
		var foes = _living(1 - actor.side)
		var allies = _living(actor.side)
		_event(events, actor, _target(actor, foes), "damage", actor.atk)
		actor.count += 1
		if actor.count < 3:
			continue
		actor.count = 0
		match actor.role:
			0:
				for ally in allies:
					var distance = absi(ally.slot % 3 - actor.slot % 3) + absi(int(ally.slot / 3) - int(actor.slot / 3))
					if distance <= 1:
						_event(events, actor, ally, "shield", 48, true)
				_note(actor.name + " · 并肩护盾")
			1:
				_event(events, actor, _target(actor, foes, "back"), "damage", actor.atk * 2.6, true)
				_note(actor.name + " · 穿云：瞄准后排")
			2:
				_event(events, actor, _target(actor, allies, "low"), "heal", 85, true)
				_note(actor.name + " · 应援治疗")
			3:
				_event(events, actor, _target(actor, foes, "low"), "damage", actor.atk * 2.1, true)
				_note(actor.name + " · 冲刺追击")
			4:
				var first = _target(actor, foes)
				if not first.is_empty():
					for foe in foes:
						if int(foe.slot / 3) == int(first.slot / 3):
							_event(events, actor, foe, "damage", 72, true)
				_note(actor.name + " · 整排打击！")
	# Collect every action before resolving; support precedes simultaneous damage.
	for e in events:
		if e.kind == "shield":
			e.actual = minf(e.value, 144 - e.target.shield)
			e.target.shield = minf(e.target.shield + e.value, 144)
		elif e.kind == "heal":
			var healed = minf(e.value, e.target.max_hp - e.target.hp)
			e.actual = healed
			e.target.hp += healed
			e.actor.healing += healed
	for e in events:
		if e.kind == "damage":
			var damage = maxf(1, roundf(e.value * 100.0 / (100.0 + e.target.def)))
			var blocked = minf(damage, e.target.shield)
			e.actual = minf(maxf(0, e.target.hp), damage - blocked)
			e.target.shield -= blocked
			e.target.hp -= damage - blocked
			e.actor.damage += e.actual
			e.target.flash = 0.2
		_present_event(e)
		beams.append({"from": _slot_rect(e.actor.side, e.actor.slot).get_center(),
			"to": _slot_rect(e.target.side, e.target.slot).get_center(),
			"color": (GOLD if e.special else (TEAL if e.actor.side == 0 else RED)), "life": 0.18})
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90:
		result_won = not _living(0).is_empty() and _living(1).is_empty()
		phase = "result"
		_note("胜利！全员恢复，点击重新编队继续实验。" if result_won else "挑战失败。可无限重试，试试换位或调整装备。")
		if result_won:
			for u in units:
				if u.side == 0:
					u.hp = u.max_hp
					u.shield = 0
					u.count = 0
					u.timer = u.interval

func _present_event(_event_data: Dictionary) -> void:
	pass

func _action_rect(index: int) -> Rect2:
	return [Rect2(40, 503, 230, 48), Rect2(282, 503, 150, 48), Rect2(444, 503, 240, 48), Rect2(696, 503, 270, 48), Rect2(978, 503, 260, 48)][index]

func _note(message: String) -> void:
	logs.push_front(message)
	if logs.size() > 4:
		logs.resize(4)

func _slot_rect(side: int, slot: int) -> Rect2:
	var row = int(slot / 3)
	var y = (164 + (1 - row) * 124) if side == 1 else (164 + row * 124)
	return Rect2(42 + side * 650 + (slot % 3) * 174, y, 162, 112)

func _box(rect: Rect2, color: Color, border: Color = Color.TRANSPARENT) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	draw_style_box(style, rect)

func _text(at: Vector2, value: String, color: Color = INK, font_size: int = 18) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _button(rect: Rect2, label: String, active: bool = false) -> void:
	_box(rect, Color("255d53") if active else Color("253443"), TEAL if active else Color("415565"))
	_text(rect.position + Vector2(18, 31), label, INK, 20)

func _draw() -> void:
	scale_factor = minf(size.x / 1280.0, size.y / 720.0)
	origin = (size - Vector2(1280, 720) * scale_factor) / 2
	draw_rect(Rect2(Vector2.ZERO, size), Color("101820"))
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)
	_text(Vector2(40, 42), "重返校园 / 战斗实验室", INK, 28)
	_text(Vector2(40, 73), "FORMATION DEMO 01     ·     固定阵型 / 全自动技能 / 胜利全恢复", MUTED, 16)
	var state_label = "准备：点击同学 → 点击格子换位"
	if phase == "battle":
		state_label = ("已暂停" if paused else "自动战斗中") + "  ·  %.1f 秒" % elapsed
	elif phase == "result":
		state_label = ("胜利 · 全员已恢复" if result_won else "失败 · 可无限重试") + "  ·  %.1f 秒" % elapsed
	_text(Vector2(40, 117), state_label, TEAL, 23)
	_text(Vector2(42, 150), "我方  /  上方前排 · 下方后排", MUTED)
	_text(Vector2(692, 150), "敌方  /  上方后排 · 下方前排", MUTED)
	for side in range(2):
		for slot in range(6):
			var rect = _slot_rect(side, slot)
			var occupant: Dictionary = {}
			for u in units:
				if u.side == side and u.slot == slot:
					occupant = u
			var is_selected = side == 0 and formation[slot] == selected
			_box(rect, Color("1b2a36"), TEAL if is_selected and phase == "prepare" else Color("2c4050"))
			if occupant.is_empty():
				_text(rect.position + Vector2(45, 60), "空位 +", MUTED)
				continue
			var u = occupant
			var alive: bool = u.hp > 0
			if u.flash > 0:
				_box(rect, Color(1, 0.5, 0.4, 0.25))
			_text(rect.position + Vector2(12, 27), u.name, (TEAL if side == 0 else RED) if alive else MUTED, 22)
			var health_rect = Rect2(rect.position + Vector2(12, 42), Vector2(138, 8))
			draw_rect(health_rect, Color("101820"))
			health_rect.size.x *= clampf(u.hp / u.max_hp, 0, 1)
			draw_rect(health_rect, TEAL if side == 0 else RED)
			_text(rect.position + Vector2(12, 70), "%d/%d%s" % [maxi(0, int(u.hp)), int(u.max_hp), "  盾%d" % int(u.shield) if u.shield > 0 else ""], INK if alive else MUTED, 16)
			var detail = "普攻 %d/3" % u.count if alive else "已退场"
			if side == 0 and u.role == equipment:
				detail += " · 鞋"
			_text(rect.position + Vector2(12, 98), detail, GOLD if alive else MUTED, 16)
	for b in beams:
		draw_line(b.from, b.to, b.color, 3, true)
	_box(Rect2(40, 416, 1200, 72), Color("1b2a36"))
	_text(Vector2(56, 442), ROLES[selected] + "  /  " + SKILLS[selected], INK, 20)
	_text(Vector2(56, 469), "篮球鞋：攻击间隔 -25%  ·  当前携带：" + ROLES[equipment] + "    |    护盾保护上下左右相邻友军", MUTED, 17)
	_button(Rect2(40, 503, 230, 48), "开始自动战斗" if phase == "prepare" else ("继续 / 暂停" if phase == "battle" else "重新编队"), true)
	_button(Rect2(282, 503, 150, 48), "速度  %d×" % speed)
	_button(Rect2(444, 503, 240, 48), "装备给选中角色", phase == "prepare")
	_button(Rect2(696, 503, 270, 48), "敌阵：" + ("守卫与治疗" if encounter == 0 else "整排攻击"), phase == "prepare")
	_button(Rect2(978, 503, 260, 48), "结束实验 / 重新编队")
	for i in range(logs.size()):
		_text(Vector2(48, 584 + i * 26), logs[i], INK if i == 0 else MUTED, 18)
	_text(Vector2(48, 692), "前排优先承受普攻；后排并非绝对安全。金色连线表示技能。试试让守护者保护两位队友。", MUTED, 16)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var point: Vector2 = (event.position - origin) / scale_factor
	if _action_rect(0).has_point(point):
		if phase == "prepare":
			_start()
		elif phase == "battle":
			paused = not paused
		else:
			phase = "prepare"
			_build_units()
	elif _action_rect(1).has_point(point):
		speed = 2 if speed == 1 else 1
	elif _action_rect(4).has_point(point):
		phase = "prepare"
		_build_units()
		_note("已返回准备。可自由换位，再次开战。")
	elif phase == "prepare":
		if _action_rect(2).has_point(point):
			equipment = selected
			_build_units()
		elif _action_rect(3).has_point(point):
			encounter = 1 - encounter
			_build_units()
			_note("敌方技能：" + ("守卫提供护盾，广播治疗残血，飞页投手攻击后排。" if encounter == 0 else "黑板每 3 次普攻打击一整排；分散布阵可以减少受击人数。"))
		else:
			for slot in range(6):
				if _slot_rect(0, slot).has_point(point):
					if pending_slot < 0:
						if formation[slot] >= 0:
							selected = formation[slot]
							pending_slot = slot
							_note("已选中 " + ROLES[selected] + "：点击目标格换位，或点击装备按钮。")
					elif pending_slot == slot:
						pending_slot = -1
					else:
						var old_slot = formation.find(selected)
						var other: int = formation[slot]
						formation[slot] = selected
						formation[old_slot] = other
						pending_slot = -1
						_build_units()
						_note("站位已调整。点击同学，再点击目标格，可继续换位。")
	accept_event()

func _smoke() -> void:
	# Exercise the same click handler used by mouse/touch-emulated mouse input.
	for point in [_slot_rect(0, 0).get_center(), _slot_rect(0, 1).get_center()]:
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = point
		_gui_input(click)
	assert(formation[0] == -1 and formation[1] == 0)
	formation = [0, -1, 3, 2, 1, -1]
	print("DEMO_INPUT click-to-move passed")
	selected = 1
	var equip_click = InputEventMouseButton.new()
	equip_click.button_index = MOUSE_BUTTON_LEFT
	equip_click.pressed = true
	equip_click.position = _action_rect(2).get_center()
	_gui_input(equip_click)
	assert(equipment == 1)
	equipment = 0
	selected = 0
	print("DEMO_INPUT equipment button passed")
	for variant in range(2):
		encounter = variant
		_start()
		while phase == "battle":
			_tick()
		print("DEMO_SMOKE encounter=", variant, " won=", result_won, " seconds=", elapsed)
		if result_won:
			for u in units:
				if u.side == 0:
					assert(u.hp == u.max_hp and u.shield == 0 and u.count == 0)
	encounter = 0
	formation = [-1, 0, 3, 1, 2, -1]
	for wearer in range(4):
		equipment = wearer
		_start()
		while phase == "battle":
			_tick()
		print("DEMO_FORMATION centered_guard equipment=", wearer, " won=", result_won, " seconds=", elapsed)
	# Fixed simulation steps must produce the same outcome at both display speeds.
	var outcomes: Array = []
	for multiplier in [1, 2]:
		speed = multiplier
		equipment = 1
		_start()
		while phase == "battle":
			_process(1.0 / 60.0)
		outcomes.append([result_won, elapsed])
	assert(outcomes[0] == outcomes[1])
	print("DEMO_SPEED 1x/2x identical: ", outcomes[0])
	get_tree().quit()
