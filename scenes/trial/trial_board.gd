extends Control
## Read-only event projection. No targeting, damage or resource writes occur here.
signal inspected(text: String)
const ActorView = preload("res://scenes/trial/trial_actor.gd")
const Presenter = preload("res://scenes/battle_demo/unit_presentation.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const TEAL = Color("76e5cb")
const RED = Color("ff958f")
const GOLD = Color("ffe08d")
const BLUE = Color("8fdfff")
var simulation
var actors: Dictionary = {}
var effects: Array[Dictionary] = []
var skill_effects: Array[Dictionary] = []
var visual_time := 0.0
var interpolation := 1.0
var selected_id := -1
var show_target_lines := true
var reduced_motion := false
var overlay: Node2D
var _bound_simulation
var _last_elapsed := -1.0
var _banner := ""
var _banner_age := 9.0

class EffectOverlay extends Node2D:
	var board
	func _draw() -> void:
		if is_instance_valid(board): board.draw_overlay(self)

func _ready() -> void:
	clip_contents = true
	if custom_minimum_size.y < 380: custom_minimum_size.y = 380
	resized.connect(func(): advance_presentation(0, interpolation))
	reset_presentation()

func reset_presentation() -> void:
	for view in actors.values():
		if is_instance_valid(view): view.free()
	actors.clear()
	effects.clear()
	skill_effects.clear()
	visual_time = 0
	_banner_age = 9
	_bound_simulation = simulation
	_last_elapsed = -1
	if not is_instance_valid(overlay):
		overlay = EffectOverlay.new()
		overlay.board = self
		overlay.z_index = 2000
		add_child(overlay)
	advance_presentation(0, 1)

func _ensure_actors() -> void:
	if simulation == null: return
	if _bound_simulation != simulation or simulation.elapsed < _last_elapsed:
		reset_presentation()
	_last_elapsed = simulation.elapsed
	for unit in simulation.units:
		if actors.has(unit.id): continue
		var view = ActorView.new()
		view.name = "Combatant%d" % unit.id
		actors[unit.id] = view
		add_child(view)
		view.configure(unit)
		view.synchronize(unit, 0, 1, point(unit.position), _actor_scale(), _has_mark(unit.id), selected_id == unit.id)

func consume_events(events: Array) -> void:
	_ensure_actors()
	for event in events:
		var converted: Dictionary = event.duplicate(true)
		converted.from = point(event.get("from", Vector2.ZERO))
		converted.to = point(event.get("to", Vector2.ZERO))
		var actor_id: int = event.get("actor_id", -1)
		var target_id: int = event.get("target_id", actor_id)
		if actors.has(actor_id): actors[actor_id].consume(converted)
		if target_id != actor_id and actors.has(target_id): actors[target_id].consume(converted)
		match event.get("kind", ""):
			"impact":
				var effect: String = event.get("effect", "damage")
				var amount: float = event.get("actual", 0)
				var blocked: float = event.get("blocked", 0)
				if amount <= 0 and blocked <= 0: continue
				var text = ("-" if effect == "damage" else "+") + str(roundi(amount))
				if effect == "shield": text = "护盾 +%d" % roundi(amount)
				elif effect == "damage" and amount == 0: text = "格挡 %d" % roundi(blocked)
				var color = RED if effect == "damage" else (BLUE if effect == "shield" else TEAL)
				_spawn(event, effect, text, color, 0.85)
			"action_released":
				if event.get("casts", false):
					var actor: Dictionary = simulation.unit(actor_id)
					var skill = actor.get("skill")
					if skill != null and skill.battle_effect != null and skill.battle_effect.duration() > 0:
						skill_effects.append({"actor_id": actor_id, "resource": skill.battle_effect, "age": 0.0})
					_spawn(event, "cast", "", GOLD, 0.36)
			"action_missed": _spawn(event, "status", "落空", Color("a1afbc"), 0.65)
			"mark_applied": _spawn(event, "mark", "发现漏洞", GOLD, 0.85)
			"mark_verified": _spawn(event, "verify", "协同验证", GOLD, 0.85)
			"hack_progress":
				if event.get("actual", 0) > 0: _spawn(event, "packet", "+%d" % event.actual, TEAL, 0.8)
			"trait_triggered": _spawn(event, "trait", event.get("label", "羁绊触发"), GOLD, 1.0)
			"hack_completed":
				_banner = "维护已断开" if event.get("choice", "") == "disconnect" else "维护已接管"
				_banner_age = 0
				_spawn(event, "system", "", BLUE, 1.2)
	queue_redraw()
	if is_instance_valid(overlay): overlay.queue_redraw()

func _spawn(event: Dictionary, kind: String, text: String, color: Color, duration: float) -> void:
	var target_id: int = event.get("target_id", event.get("actor_id", -1))
	var lane := 0
	for fx in effects:
		if fx.target_id == target_id and fx.age < 0.55 and not fx.text.is_empty(): lane += 1
	if effects.size() >= 120: effects.pop_front()
	effects.append({"kind": kind, "text": text, "color": color, "duration": duration, "age": 0.0,
		"from": event.get("from", Vector2.ZERO), "to": event.get("to", Vector2.ZERO),
		"actor_id": event.get("actor_id", -1), "target_id": target_id, "lane": lane % 4,
		"special": event.get("special", false), "shield_break": event.get("shield_break", false)})

func advance_presentation(delta: float, alpha: float = 1.0) -> void:
	if simulation == null: return
	_ensure_actors()
	interpolation = clampf(alpha, 0, 1)
	var duration = maxf(delta, 0)
	visual_time += duration
	_banner_age += duration
	for fx in effects: fx.age += duration
	effects = effects.filter(func(fx): return fx.age < fx.duration)
	for fx in skill_effects: fx.age += duration
	skill_effects = skill_effects.filter(func(fx): return fx.age < fx.resource.duration())
	for unit in simulation.units:
		var at = point(Presenter.position(unit, interpolation))
		var facing: Vector2 = unit.get("facing", Vector2.ZERO)
		var screen_direction = point(unit.position + facing) - point(unit.position)
		actors[unit.id].synchronize(unit, duration, interpolation, at, _actor_scale(), _has_mark(unit.id), selected_id == unit.id, screen_direction)
	queue_redraw()
	if is_instance_valid(overlay): overlay.queue_redraw()

func _has_mark(id: int) -> bool:
	return simulation != null and simulation.marks.has(id)

func _actor_scale() -> float:
	return clampf(minf(size.x / 1700.0, size.y / 580.0), 0.68, 1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var unit = _pick(event.position)
		if unit.is_empty(): return
		selected_id = unit.id
		inspected.emit("%s · 生命 %d/%d · 护盾 %d · 攻击 %d · 防御 %d · 间隔 %.2f 秒 · 射程 %.1f · 伤害 %d · 治疗 %d" % [unit.name, unit.hp, unit.max_hp, unit.shield, unit.atk, unit.def, unit.interval, unit.attack_range, unit.damage, unit.get("healing", 0)])
		advance_presentation(0, interpolation)
		accept_event()

func _pick(at: Vector2) -> Dictionary:
	if simulation == null: return {}
	var best: Dictionary = {}
	var distance := INF
	for unit in simulation.units:
		var view = actors.get(unit.id)
		var center: Vector2 = view.position if is_instance_valid(view) else point(unit.position)
		var rect = Rect2(center - Vector2(39, 85) * _actor_scale(), Vector2(78, 135) * _actor_scale())
		if rect.has_point(at) and (center - Vector2(0, 30)).distance_squared_to(at) < distance:
			best = unit
			distance = (center - Vector2(0, 30)).distance_squared_to(at)
	return best

func _get_tooltip(at_position: Vector2) -> String:
	var unit = _pick(at_position)
	return "" if unit.is_empty() else unit.name + " · 点击查看属性与当前目标"

func point(logical: Vector2) -> Vector2:
	return Vector2(145 + (6 - logical.y) / 6.0 * maxf(100, size.x - 290) + (logical.x - 3) * 34, 108 + logical.x / 6.0 * maxf(80, size.y - 180))

func _draw() -> void:
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("0b1928")
	panel.border_color = Color("284452")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(12)
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	for row in 7:
		draw_line(point(Vector2(row, 0)), point(Vector2(row, 6)), Color("203b49"), 1)
	for depth in 7:
		draw_line(point(Vector2(0, depth)), point(Vector2(6, depth)), Color("203b49"), 1)
	for step in range(58, int(size.y - 28), 18):
		draw_line(Vector2(size.x / 2, step), Vector2(size.x / 2, step + 7), Color(0.4, 0.7, 0.75, 0.18), 2)
	draw_string(FONT, Vector2(22, 29), "我方", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, TEAL)
	draw_string(FONT, Vector2(size.x - 62, 29), "敌方", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, RED)
	if simulation == null: return
	if show_target_lines and selected_id >= 0:
		var unit: Dictionary = simulation.unit(selected_id)
		var action: Dictionary = unit.get("action", {})
		var target: Dictionary = simulation.unit(action.get("target_id", unit.get("target_id", -1)))
		if not target.is_empty() and not unit.is_empty() and unit.hp > 0:
			var from = point(unit.position) + Vector2(0,-20)
			var to = point(target.position) + Vector2(0,-20)
			draw_line(from, to, Color(GOLD, 0.22), 2, true)
			draw_arc(to, 22, 0, TAU, 28, Color(GOLD, 0.4), 2, true)

func draw_overlay(canvas: Node2D) -> void:
	if simulation == null: return
	for fx in skill_effects:
		var texture: Texture2D = fx.resource.texture(fx.age)
		var actor: Dictionary = simulation.unit(fx.actor_id)
		if texture == null or actor.is_empty(): continue
		var at = point(Presenter.position(actor, interpolation)) + fx.resource.offset * _actor_scale()
		var dimensions: Vector2 = fx.resource.display_size * _actor_scale()
		canvas.draw_texture_rect(texture, Rect2(at - dimensions * fx.resource.anchor, dimensions), false)
	_draw_projectiles(canvas)
	for fx in effects: _draw_effect(canvas, fx)
	if _banner_age < 1.8: _center(canvas, Vector2(size.x / 2, 35), _banner, BLUE, 23)
	elif simulation.awaiting_choice: _center(canvas, Vector2(size.x / 2, 35), "破解完成 · 等待指令", GOLD, 22)
	else:
		var system_text = "维护系统" if simulation.hack_choice.is_empty() else ("系统已断开" if simulation.hack_choice == "disconnect" else "系统已接管")
		_center(canvas, Vector2(size.x / 2, 30), system_text, Color("a4c3cd"), 16)
	if simulation.awaiting_choice:
		canvas.draw_rect(Rect2(3,3,size.x-6,size.y-6), Color(GOLD,0.5), false, 2)

func _hit_point(unit: Dictionary) -> Vector2:
	return point(Presenter.position(unit, interpolation)) + Vector2(0, -33) * _actor_scale()

func _draw_projectiles(canvas: Node2D) -> void:
	for shot in simulation.projectiles:
		var actor: Dictionary = simulation.unit(shot.actor_id)
		var target: Dictionary = simulation.unit(shot.target_id)
		if actor.is_empty() or target.is_empty(): continue
		var logical: Vector2 = shot.get("previous_position", shot.position).lerp(shot.position, interpolation)
		var from: Vector2 = shot.get("origin", actor.position)
		var fraction = clampf(from.distance_to(logical) / maxf(0.001, from.distance_to(target.position)), 0, 1)
		var config = actor.get("battle_animation")
		var launch = Vector2(0,-35)
		var hit = Vector2(0,-33)
		var style: Resource
		if config != null:
			launch = config.launch_offset
			if config.flip_with_facing and point(target.position).x < point(from).x: launch.x *= -1
			style = config.projectile_style
		var to_config = target.get("battle_animation")
		if to_config != null: hit = to_config.hit_offset
		var p = point(logical) + launch.lerp(hit, fraction) * _actor_scale()
		var direction = (_hit_point(target) - p).normalized()
		if direction.is_zero_approx(): direction = Vector2.RIGHT
		var color = GOLD if shot.get("special", false) else (TEAL if actor.side == 0 else RED)
		for i in 4:
			canvas.draw_circle(p - direction * (i * 6 + 4), (4.2 - i * 0.8) * _actor_scale(), Color(color, 0.8 - i * 0.17))
		if style != null and style.usable():
			canvas.draw_set_transform(p, direction.angle() + deg_to_rad(style.rotation_offset_degrees), Vector2.ONE * _actor_scale())
			canvas.draw_texture_rect(style.texture, Rect2(-style.display_size * style.anchor, style.display_size), false)
			canvas.draw_set_transform(Vector2.ZERO)
		else:
			canvas.draw_line(p - direction * 9, p + direction * 4, color, 3 if not shot.get("special", false) else 5, true)

func _draw_effect(canvas: Node2D, fx: Dictionary) -> void:
	var t: float = fx.age / fx.duration
	var opacity = minf(1, (1 - t) * 3)
	var color = Color(fx.color, opacity)
	var p = point(fx.to) + Vector2(0, -33) * _actor_scale()
	var begin = point(fx.from) + Vector2(0,-33) * _actor_scale()
	var motion = 0.0 if reduced_motion else 1.0
	match fx.kind:
		"damage":
			if t < 0.4:
				for i in 6:
					var direction = Vector2.from_angle(i * TAU / 6 + 0.3)
					var radius = 4 + t * 55 * motion
					canvas.draw_line(p + direction * radius, p + direction * (radius + 8), color, 2, true)
			if fx.shield_break and t < 0.6:
				canvas.draw_arc(p, 24+t*35*motion, 0, PI*1.7, 20, Color(BLUE, opacity), 2, true)
		"heal":
			for i in 3:
				var q = p + Vector2((i-1)*17, -t*24*motion + i%2*9)
				canvas.draw_line(q - Vector2(4,0), q + Vector2(4,0), color, 2, true)
				canvas.draw_line(q - Vector2(0,4), q + Vector2(0,4), color, 2, true)
		"shield", "cast": canvas.draw_arc(p, 15 + t*26*motion, 0, TAU, 32, Color(color,opacity*0.6), 2, true)
		"mark": canvas.draw_arc(p, 39 - t*9*motion, 0, TAU, 24, color, 2, true)
		"verify":
			if t < 0.45: canvas.draw_line(begin, p, Color(GOLD, opacity*0.7), 2, true)
			canvas.draw_arc(p, 16+t*30*motion, 0, TAU, 24, color, 2, true)
		"packet":
			var destination = Vector2(size.x/2,38)
			var packet = begin.lerp(destination, t)
			canvas.draw_line(packet - (destination-begin).normalized()*10, packet, color, 3, true)
			if t > 0.5: _center(canvas, packet+Vector2(8,-5), fx.text, color, 15)
			return
		"system": canvas.draw_line(Vector2(size.x*t,45), Vector2(size.x*t,size.y-12), Color(BLUE,opacity*0.4), 3, true)
	if not fx.text.is_empty():
		var label_at = p + Vector2(0,-40 - fx.lane*19 - t*22*motion)
		# Keep stacked numbers below the system caption even for the topmost row.
		if label_at.y < 56: label_at.y = 56 + fx.lane * 19
		_center(canvas, label_at, fx.text, color, 20 if fx.special else 16)

func _center(canvas: CanvasItem, at: Vector2, text: String, color: Color, font_size: int) -> void:
	var width = FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string_outline(FONT, at - Vector2(width/2,0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(Color("07121f"), color.a))
	canvas.draw_string(FONT, at - Vector2(width/2,0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
