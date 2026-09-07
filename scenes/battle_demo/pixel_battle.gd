extends "res://scenes/battle_demo/battle_demo.gd"
## Pixel presentation only; simulation stays in battle_demo.gd.

const PAPER = Color("eee4c6")
const DARK = Color("253a36")
const GRASS = Color("718951")
const BRICK = Color("b58360")
const ROLE_COLORS = [Color("71b8dc"), Color("eab765"), Color("99c983"), Color("d68c8c"), Color("ad98d2")]
var town: Texture2D
var dungeon: Texture2D
var visual_time = 0.0
var effects: Array[Dictionary] = []
var banner = ""
var banner_time = 0.0
var pause_overlay: Control
var pause_content: Control
var pause_heading: Label
var pause_caption: Label
var pause_actions: VBoxContainer
var confirm_actions: HBoxContainer
var pending_exit = ""
var leaving = false
var previous_auto_quit = true
var debug_shortcuts: Node
var inspected_enemy_slot = -1
var codex_panel: Control

func _open_codex() -> void:
	if is_instance_valid(codex_panel): return
	codex_panel = load("res://scenes/codex/codex_panel.gd").new()
	add_child(codex_panel)
	codex_panel.closed.connect(func(): pause_actions.get_child(0).grab_focus())

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	town = _load_atlas("res://assets/pixel/kenney/tiny-town.png")
	dungeon = _load_atlas("res://assets/pixel/kenney/tiny-dungeon.png")
	super._ready()
	var shortcuts = get_node_or_null("/root/GGT_DebugShortcuts/CanvasLayer")
	if shortcuts:
		shortcuts.hide()
	debug_shortcuts = get_node_or_null("/root/GGT_DebugShortcuts")
	if debug_shortcuts:
		debug_shortcuts.set_process_unhandled_input(false)
	previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_create_pause_menu()
	if "--pause-smoke" in OS.get_cmdline_user_args():
		_pause_smoke()
	elif "--pause-flow-smoke" in OS.get_cmdline_user_args() and not get_tree().root.has_node("PauseFlowCheck"):
		var check = load("res://scenes/battle_demo/pause_flow_check.gd").new()
		check.name = "PauseFlowCheck"
		get_tree().root.call_deferred("add_child", check)
	elif "--pause-capture" in OS.get_cmdline_user_args():
		_start()
		await get_tree().create_timer(3.0).timeout
		_open_pause()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/pixel_pause.png")
		_request_exit("menu")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/pixel_exit.png")
		get_tree().quit()

func _load_atlas(path: String) -> Texture2D:
	# First-run local demos need no import pass; exports use imported textures.
	if OS.has_feature("editor"):
		return ImageTexture.create_from_image(Image.load_from_file(path))
	return load(path) as Texture2D

func _build_units() -> void:
	super._build_units()
	effects.clear()
	banner_time = 0

func _process(delta: float) -> void:
	if paused or leaving:
		queue_redraw()
		return
	if not paused:
		visual_time += delta
		banner_time = maxf(0, banner_time - delta)
		for fx in effects:
			fx.life -= delta
		effects = effects.filter(func(fx): return fx.life > 0)
	super._process(delta)

func _present_event(e: Dictionary) -> void:
	var start = _slot_rect(e.actor.side, e.actor.slot).get_center() + Vector2(0, -6)
	var finish = _slot_rect(e.target.side, e.target.slot).get_center() + Vector2(0, -6)
	var tint: Color = GOLD if e.special else (TEAL if e.actor.side == 0 else RED)
	if e.kind == "heal":
		tint = Color("a3ef98")
	elif e.kind == "shield":
		tint = Color("8ad8ff")
	effects.append({"from": start, "to": finish, "kind": e.kind, "special": e.special,
		"value": int(e.get("actual", e.value)),
		"color": tint, "life": 0.85, "actor_side": e.actor.side, "actor_slot": e.actor.slot})
	if e.special:
		banner = e.actor.name + "  ·  " + ["并肩护盾", "穿云", "应援", "冲刺", "整排擦除"][e.actor.role]
		banner_time = 1.3

func _slot_rect(side: int, slot: int) -> Rect2:
	var row = int(slot / 3)
	var y = (292 if row == 0 else 200) if side == 1 else (404 if row == 0 else 496)
	return Rect2(252 + (slot % 3) * 148, y, 116, 82)

func _action_rect(index: int) -> Rect2:
	return [Rect2(950, 601, 288, 60), Rect2(752, 624, 136, 44), Rect2(962, 397, 264, 42), Rect2(950, 538, 288, 44), Rect2(950, 674, 288, 30)][index]

func _pixel_panel(rect: Rect2, fill: Color, edge: Color = DARK) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("142728"))
	draw_rect(rect, edge)
	draw_rect(rect.grow(-3), fill)
	draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(rect.size.x - 10, 2)), fill.lightened(0.15))

func _sprite(sheet: Texture2D, source: Rect2, at: Vector2, factor: float = 3, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(sheet, Rect2(at.round(), source.size * factor), source, tint)

func _tile(sheet: Texture2D, x: int, y: int, at: Vector2, factor: float = 3, tint: Color = Color.WHITE) -> void:
	_sprite(sheet, Rect2(x * 16, y * 16, 16, 16), at, factor, tint)

func _center(at: Vector2, value: String, color: Color = PAPER, font_size: int = 16) -> void:
	_text(at - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0), value, color, font_size)

func _campus() -> void:
	# Tiled quadrangle, framed by school architecture and Kenney vegetation.
	draw_rect(Rect2(24, 92, 894, 516), GRASS)
	for y in range(100, 603, 16):
		for x in range(30, 915, 16):
			if (x * 3 + y * 7) % 11 < 3:
				draw_rect(Rect2(x, y, 3, 3), Color("92a565"))
	# Main courtyard and individual stone courses.
	draw_rect(Rect2(198, 180, 554, 410), Color("6f7360"))
	for y in range(184, 584, 24):
		for x in range(202, 748, 28):
			var shade = Color("b8b497") if (x + y) % 5 < 2 else Color("b0ad91")
			draw_rect(Rect2(x, y, 26, 22), shade)
	# Running track/brick edging and flower beds.
	for x in range(198, 752, 24):
		draw_rect(Rect2(x, 584, 22, 12), BRICK)
	for y in range(186, 588, 24):
		draw_rect(Rect2(184, y, 12, 22), BRICK)
		draw_rect(Rect2(756, y, 12, 22), BRICK)
	# School facade with tiled roof, windows, and central entry.
	draw_rect(Rect2(122, 105, 686, 74), Color("e0cb9c"))
	for x in range(126, 808, 24):
		draw_rect(Rect2(x, 160, 22, 16), Color("baa885"))
	for x in [154, 234, 314, 562, 642, 722]:
		draw_rect(Rect2(x, 121, 46, 36), DARK)
		draw_rect(Rect2(x + 4, 125, 38, 27), Color("7ba4aa"))
		draw_rect(Rect2(x + 23, 125, 3, 29), Color("d7d2ac"))
		draw_rect(Rect2(x + 4, 135, 38, 3), Color("d7d2ac"))
	draw_rect(Rect2(419, 116, 88, 63), Color("4b655c"))
	draw_rect(Rect2(425, 123, 76, 54), Color("314944"))
	draw_rect(Rect2(461, 123, 4, 54), Color("9a9f7f"))
	draw_rect(Rect2(110, 96, 710, 18), Color("674d52"))
	for x in range(110, 820, 20):
		draw_rect(Rect2(x, 98, 17, 8), Color("a87568"))
	_pixel_panel(Rect2(390, 93, 148, 31), Color("e5d6b0"))
	_center(Vector2(464, 115), "忆 · 夏 学 园", DARK, 17)
	# Vegetation repeats only within the same 16 px asset family.
	for pos in [Vector2(64, 159), Vector2(796, 157), Vector2(58, 454), Vector2(798, 450)]:
		_sprite(town, Rect2(64, 0, 16, 32), pos, 4)
	for pos in [Vector2(99, 312), Vector2(804, 322)]:
		_tile(town, 4, 2, pos, 3)
		_tile(town, 5, 2, pos + Vector2(25, 36), 2)
	# Benches and a basketball hoop anchor the scene as a school courtyard.
	for pos in [Vector2(108, 280), Vector2(788, 280)]:
		draw_rect(Rect2(pos + Vector2(8, 24), Vector2(5, 24)), DARK)
		draw_rect(Rect2(pos + Vector2(53, 24), Vector2(5, 24)), DARK)
		for line in range(3):
			draw_rect(Rect2(pos + Vector2(0, line * 9), Vector2(66, 6)), Color("ae7953"))
	draw_rect(Rect2(845, 381, 6, 59), Color("4b635a"))
	draw_rect(Rect2(819, 365, 58, 37), PAPER)
	draw_rect(Rect2(833, 374, 28, 19), Color("bc765a"), false, 3)
	draw_line(Vector2(837, 395), Vector2(859, 395), GOLD, 4)
	# Battle boundary is integrated into the pavement.
	for x in range(212, 748, 22):
		draw_rect(Rect2(x, 390, 12, 3), Color("ded5b0"))
	_center(Vector2(468, 386), "裂 隙 边 界", Color("655f5c"), 12)
	# Floating corruption motes near the enemy backline.
	for i in range(9):
		var p = Vector2(235 + i * 57, 185 + int(sin(visual_time * 1.7 + i) * 7))
		draw_rect(Rect2(p, Vector2(4, 4)), Color("b28bbb"))

func _pawn(u: Dictionary, at: Vector2, factor: float = 4) -> void:
	var alive: bool = u.hp > 0
	var tint = Color.WHITE if alive else Color(0.48, 0.49, 0.47, 0.55)
	var offset = Vector2.ZERO
	if alive:
		offset.y = roundf(sin(visual_time * 3 + u.slot) * 2)
		for fx in effects:
			if fx.actor_side == u.side and fx.actor_slot == u.slot and fx.life > 0.60:
				offset += (fx.to - fx.from).normalized() * sin((0.85 - fx.life) / 0.25 * PI) * 12
		if u.flash > 0:
			tint = Color(1.6, 1.3, 1.3)
	var p = (at + offset).round()
	# Kenney humanoids and monsters; provisional costumes for fictional students.
	var cell: Vector2i
	if u.side == 0:
		cell = [Vector2i(1, 8), Vector2i(3, 7), Vector2i(0, 7), Vector2i(2, 7), Vector2i(3, 8)][u.role]
	else:
		cell = [Vector2i(4, 7), Vector2i(0, 9), Vector2i(1, 9), Vector2i(4, 8), Vector2i(4, 9)][u.role]
	_sprite(dungeon, Rect2(cell.x * 16, cell.y * 16, 16, 16), p - Vector2(8, 14) * factor, factor, tint)
	if u.side == 0 and alive:
		# Role badges create readable team identity without recoloring the source art.
		draw_rect(Rect2(p + Vector2(20, -25), Vector2(10, 10)), ROLE_COLORS[u.role])
		if u.role == equipment:
			_tile(dungeon, 8, 10, p + Vector2(24, -3), 1.3)
	if u.shield > 0 and alive:
		var poly = PackedVector2Array([p + Vector2(-32,-52), p + Vector2(32,-52), p + Vector2(38,-34), p + Vector2(24,8), p + Vector2(0,18), p + Vector2(-24,8), p + Vector2(-38,-34), p + Vector2(-32,-52)])
		draw_polyline(poly, Color("8dd7e7"), 3)

func _draw_unit(u: Dictionary) -> void:
	var rect = _slot_rect(u.side, u.slot)
	var p = rect.get_center() + Vector2(0, 13)
	var alive: bool = u.hp > 0
	var chosen: bool = phase == "prepare" and u.side == 0 and u.role == selected
	# Small base, not a character card: the actor stands on the map.
	draw_rect(Rect2(p + Vector2(-29, -3), Vector2(58, 12)), Color(0.15, 0.23, 0.20, 0.3))
	if chosen:
		draw_rect(Rect2(p + Vector2(-37,-7), Vector2(74, 20)), GOLD, false, 3)
		_center(p + Vector2(0,-72), "▼", GOLD, 16)
	_pawn(u, p)
	var hp = Rect2(p + Vector2(-36, 19), Vector2(72, 6))
	draw_rect(hp.grow(2), DARK)
	draw_rect(hp, Color("566354"))
	hp.size.x *= clampf(u.hp / u.max_hp, 0, 1)
	draw_rect(hp, Color("a7d684") if u.side == 0 else Color("df9386"))
	_center(p + Vector2(0, 41), u.name if alive else "已退场", DARK, 14)
	for i in range(3):
		draw_rect(Rect2(p + Vector2(-10 + i * 8, 46), Vector2(5, 3)), GOLD if i < u.count else Color("747a62"))

func _draw_effects() -> void:
	for fx in effects:
		var age: float = 0.85 - fx.life
		var travel = clampf(age / 0.24, 0, 1)
		var p: Vector2 = fx.from.lerp(fx.to, travel)
		if fx.kind == "damage":
			if travel < 1:
				for tail in range(4):
					var q: Vector2 = p - (fx.to - fx.from).normalized() * tail * 7
					draw_rect(Rect2(q, Vector2(7 - tail, 7 - tail)), fx.color)
			elif age < 0.48:
				var r = 8 + (age - 0.24) * 100
				for i in range(8):
					var q: Vector2 = fx.to + Vector2.from_angle(i * PI / 4) * r
					draw_rect(Rect2(q, Vector2(5, 5)), fx.color)
		else:
			for i in range(5):
				var q: Vector2 = fx.to + Vector2((i - 2) * 12, -age * 50 + (i % 2) * 12)
				draw_rect(Rect2(q, Vector2(4, 12)), fx.color)
				if fx.kind == "heal":
					draw_rect(Rect2(q + Vector2(-4,4), Vector2(12, 4)), fx.color)
		if age > 0.18 and fx.value > 0:
			var label = ("-" if fx.kind == "damage" else "+") + str(fx.value)
			var at: Vector2 = fx.to + Vector2(22, -38 - age * 30)
			_center(at + Vector2(2,2), label, DARK, 22 if fx.special else 18)
			_center(at, label, fx.color, 22 if fx.special else 18)

func _pixel_button(index: int, text: String, active: bool = false, enabled: bool = true) -> void:
	var rect = _action_rect(index)
	var fill = Color("c5a66c") if active else Color("e1d3ae")
	if not enabled:
		fill = Color("a2a18a")
	_pixel_panel(rect, fill)
	_center(rect.get_center() + Vector2(0, 7), text, DARK, 20 if index == 0 else 16)

func _draw() -> void:
	if town == null:
		return
	scale_factor = minf(size.x / 1280.0, size.y / 720.0)
	origin = (size - Vector2(1280, 720) * scale_factor) / 2
	draw_rect(Rect2(Vector2.ZERO, size), Color("253a36"))
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)
	_pixel_panel(Rect2(20, 16, 1220, 62), Color("344b42"), Color("132c2d"))
	_text(Vector2(40, 45), "重返校园", PAPER, 27)
	_text(Vector2(42, 65), "RETURN TO SUMMER", Color("c0b792"), 11)
	_text(Vector2(238, 45), "01 / 旧校庭院", PAPER, 20)
	_text(Vector2(238, 66), "找回同学，驱散校园里的异常。", Color("b2baa0"), 12)
	var state_text = "战前整备" if phase == "prepare" else ("战斗胜利 · 全员恢复" if phase == "result" and result_won else ("重整旗鼓 · 无限重试" if phase == "result" else ("战斗暂停" if paused else "自动战斗中")))
	_center(Vector2(790, 53), state_text, GOLD, 20)
	_text(Vector2(972, 53), "%02d:%02d / %d×" % [int(elapsed) / 60, int(elapsed) % 60, speed], PAPER, 17)
	_pixel_panel(Rect2(1148, 28, 78, 36), Color("e1d3ae"))
	_center(Vector2(1187, 53), "菜单", DARK, 17)
	_campus()
	for entry in [["敌后", 252], ["敌前", 344], ["我前", 456], ["我后", 548]]:
		_text(Vector2(201, entry[1]), entry[0], DARK, 12)
	for side in range(2):
		for slot in range(6):
			var rect = _slot_rect(side, slot)
			if phase == "prepare":
				var tint = Color(0.65, 0.26, 0.36, 0.12) if side == 1 else Color(0.22, 0.44, 0.36, 0.15)
				draw_rect(Rect2(rect.position + Vector2(5,14), rect.size - Vector2(10,20)), tint)
				if side == 0:
					draw_rect(Rect2(rect.position + Vector2(5,14), rect.size - Vector2(10,20)), Color("899574"), false, 2)
					if formation[slot] < 0:
						_center(rect.get_center() + Vector2(0,10), "+", Color("728369"), 24)
					if selected == 0 and inspected_enemy_slot < 0:
						var guard_slot = formation.find(0)
						if guard_slot >= 0 and absi(slot % 3 - guard_slot % 3) + absi(int(slot / 3) - int(guard_slot / 3)) <= 1:
							draw_rect(rect.grow(-9), Color(0.45, 0.85, 1.0, 0.2))
	for u in units:
		_draw_unit(u)
	_draw_effects()
	if banner_time > 0 and phase == "battle":
		_pixel_panel(Rect2(267, 99, 418, 40), Color("413b4b"))
		_center(Vector2(476, 126), banner, GOLD, 21)
	# Right-side field notebook: short, actionable information.
	_pixel_panel(Rect2(936, 93, 310, 428), PAPER)
	_text(Vector2(958, 122), "同 学 手 册", DARK, 18)
	draw_line(Vector2(957, 136), Vector2(1226, 136), Color("b8af8c"), 2)
	var current: Dictionary = {}
	for u in units:
		if (inspected_enemy_slot < 0 and u.side == 0 and u.role == selected) or (u.side == 1 and u.slot == inspected_enemy_slot):
			current = u
	if not current.is_empty():
		_pawn(current, Vector2(1000, 213), 4)
		_text(Vector2(1053, 177), current.name, DARK, 24)
		_text(Vector2(1053, 202), ["保护 / 相邻护盾", "远程 / 后排打击", "支援 / 自动治疗", "突击 / 残血追击", "范围 / 整排伤害"][current.role], Color("69745c"), 13)
		_text(Vector2(962, 245), "生命  %d / %d" % [maxi(0, int(current.hp)), int(current.max_hp)], DARK, 17)
		_text(Vector2(962, 274), "攻击 %d    间隔 %.2fs" % [current.atk, current.interval], DARK, 16)
		_text(Vector2(962, 306), "每 3 次普攻自动释放：", Color("6b705a"), 15)
		var descriptions = [["为自己与上下左右的队友", "提供 48 点护盾。"], ["优先攻击敌方后排，", "造成 2.6 倍攻击伤害。"], ["治疗生命比例最低的队友，", "恢复 85 点生命。"], ["追击生命比例最低的敌人，", "造成 2.1 倍攻击伤害。"], ["攻击当前目标所在的一整排，", "每个目标受到 72 点基础伤害。"]]
		_text(Vector2(962, 334), descriptions[current.role][0], DARK, 16)
		_text(Vector2(962, 358), descriptions[current.role][1], DARK, 16)
	_pixel_button(2, "篮球鞋 → 装备给这位同学" if inspected_enemy_slot < 0 else "敌方信息 · 无法装备", false, phase == "prepare" and inspected_enemy_slot < 0)
	_text(Vector2(963, 468), "现由「" + ROLES[equipment] + "」携带" if equipment >= 0 else "篮球鞋在背包中，可重新装备", DARK, 16)
	_text(Vector2(963, 493), "效果：攻击间隔缩短 25%", Color("6b705a"), 14)
	_pixel_button(3, "切换敌阵 · " + ("守卫与治疗" if encounter == 0 else "整排攻击"), false, phase == "prepare")
	_pixel_button(0, "出发 · 开始战斗" if phase == "prepare" else ("继续战斗" if paused else "暂停战斗") if phase == "battle" else "重新编队 · 再来一次", true)
	_pixel_button(4, "返回整备")
	_pixel_panel(Rect2(24, 620, 712, 83), Color("344b42"))
	_text(Vector2(42, 646), "点击同学，再点击格子换位" if phase == "prepare" else "战场动态", GOLD, 17)
	var message: String = logs[0] if not logs.is_empty() else "准备出发。"
	if message.length() > 37:
		message = message.left(36) + "…"
	_text(Vector2(42, 677), message, PAPER, 15)
	_pixel_button(1, "速度 %d×" % speed)
	_center(Vector2(822, 697), "PIXEL DEMO / 02", Color("a9b393"), 11)

func _gui_input(event: InputEvent) -> void:
	if paused or leaving:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = (event.position - origin) / scale_factor
		if inspected_enemy_slot >= 0 and _action_rect(2).has_point(point):
			accept_event()
			return
		for slot in range(6):
			if _slot_rect(1, slot).has_point(point):
				for u in units:
					if u.side == 1 and u.slot == slot:
						inspected_enemy_slot = slot
				accept_event()
				return
			if _slot_rect(0, slot).has_point(point):
				inspected_enemy_slot = -1
				if phase == "battle" and formation[slot] >= 0:
					selected = formation[slot]
					accept_event()
					return
		if Rect2(1148, 28, 78, 36).has_point(point) or (phase == "battle" and _action_rect(0).has_point(point)):
			_open_pause()
			accept_event()
			return
	super._gui_input(event)

func _input(event: InputEvent) -> void:
	if is_instance_valid(codex_panel): return
	if leaving or pause_overlay == null:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ggt_debug_pause_game"):
		if event is InputEventKey and event.echo:
			return
		if not pending_exit.is_empty():
			_open_pause()
		elif paused:
			_resume_battle()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and pause_overlay != null and not leaving:
		_request_exit("quit")

func _exit_tree() -> void:
	get_tree().auto_accept_quit = previous_auto_quit
	if is_instance_valid(debug_shortcuts):
		debug_shortcuts.set_process_unhandled_input(true)

func _menu_button(title: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", DARK)
	button.add_theme_color_override("font_hover_color", DARK)
	button.add_theme_color_override("font_pressed_color", DARK)
	button.add_theme_color_override("font_focus_color", DARK)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("e1d3ae") if state == "normal" else Color("ddbb77")
		style.border_color = DARK if state != "focus" else Color("b78739")
		style.set_border_width_all(3)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(callback)
	return button

func _create_pause_menu() -> void:
	pause_overlay = Control.new()
	add_child(pause_overlay)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	pause_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.13, 0.13, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_content = Control.new()
	pause_overlay.add_child(pause_content)
	var panel = Panel.new()
	pause_content.add_child(panel)
	panel.position = Vector2(410, 134)
	panel.size = Vector2(460, 454)
	var style = StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = DARK
	style.set_border_width_all(5)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	pause_heading = Label.new()
	pause_content.add_child(pause_heading)
	pause_heading.position = Vector2(435, 157)
	pause_heading.size = Vector2(410, 48)
	pause_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_heading.add_theme_font_override("font", font)
	pause_heading.add_theme_font_size_override("font_size", 28)
	pause_heading.add_theme_color_override("font_color", DARK)
	pause_caption = Label.new()
	pause_content.add_child(pause_caption)
	pause_caption.position = Vector2(435, 211)
	pause_caption.size = Vector2(410, 56)
	pause_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_caption.add_theme_font_override("font", font)
	pause_caption.add_theme_font_size_override("font_size", 16)
	pause_caption.add_theme_color_override("font_color", DARK)
	pause_actions = VBoxContainer.new()
	pause_content.add_child(pause_actions)
	pause_actions.position = Vector2(450, 287)
	pause_actions.size = Vector2(380, 236)
	pause_actions.add_theme_constant_override("separation", 12)
	pause_actions.add_child(_menu_button("继续游戏", _resume_battle))
	pause_actions.add_child(_menu_button("重新编队", _return_to_formation))
	pause_actions.add_child(_menu_button("校园图鉴", _open_codex))
	pause_actions.add_child(_menu_button("返回主菜单", func(): _request_exit("menu")))
	if not OS.has_feature("web"):
		pause_actions.add_child(_menu_button("退出游戏", func(): _request_exit("quit")))
	panel.size.y = 530
	confirm_actions = HBoxContainer.new()
	pause_content.add_child(confirm_actions)
	confirm_actions.position = Vector2(450, 340)
	confirm_actions.size = Vector2(380, 56)
	confirm_actions.add_theme_constant_override("separation", 16)
	for entry in [["取消", _open_pause], ["确认离开", _confirm_exit]]:
		var button = _menu_button(entry[0], entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		confirm_actions.add_child(button)
	resized.connect(_layout_pause_menu)
	_layout_pause_menu()
	pause_overlay.hide()

func _layout_pause_menu() -> void:
	var ratio = minf(size.x / 1280.0, size.y / 720.0)
	pause_content.scale = Vector2.ONE * ratio
	pause_content.position = (size - Vector2(1280, 720) * ratio) / 2

func _open_pause() -> void:
	paused = true
	pending_exit = ""
	pause_heading.text = "稍作休息"
	pause_caption.text = "战斗与特效已暂停\n按 Esc / P 或点击按钮继续"
	pause_actions.show()
	confirm_actions.hide()
	pause_overlay.show()
	pause_actions.get_child(0).grab_focus()

func _resume_battle() -> void:
	pending_exit = ""
	pause_overlay.hide()
	paused = false

func _return_to_formation() -> void:
	_resume_battle()
	phase = "prepare"
	pending_slot = -1
	_build_units()
	_note("已重新编队，保留阵型与装备，可以再次出发。")

func _request_exit(destination: String) -> void:
	if is_instance_valid(codex_panel): codex_panel.close_guide()
	_open_pause()
	pending_exit = destination
	pause_heading.text = "返回主菜单？" if destination == "menu" else "退出游戏？"
	pause_caption.text = "离开会结束本次战斗。\n此 Demo 暂不保存进度。"
	pause_actions.hide()
	confirm_actions.show()
	confirm_actions.get_child(0).grab_focus()

func _confirm_exit() -> void:
	if leaving:
		return
	leaving = true
	if pending_exit == "quit":
		get_tree().quit()
	else:
		GGT.change_scene("res://scenes/menu/menu.tscn", {"show_progress_bar": false})

func _pause_smoke() -> void:
	_start()
	_process(1.5)
	_open_pause()
	var snapshot = [elapsed, accumulator, visual_time, units.duplicate(true), effects.duplicate(true)]
	_process(8.0)
	assert(snapshot == [elapsed, accumulator, visual_time, units, effects])
	_request_exit("menu")
	assert(paused and pending_exit == "menu" and confirm_actions.visible)
	_open_pause()
	assert(pending_exit.is_empty() and paused)
	_resume_battle()
	_process(0.1)
	assert(elapsed > snapshot[0])
	_open_pause()
	_return_to_formation()
	assert(phase == "prepare" and not paused and elapsed == 0)
	print("PAUSE_SMOKE freeze, confirmation/cancel, resume, formation passed")
	get_tree().quit()
