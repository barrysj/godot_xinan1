extends "res://scenes/battle_demo/battle_demo.gd"
## View adapter for the shared combat simulation; existing art remains provisional.

const PAPER = Color("fff9ee")
const DARK = Color("181820")
const GRASS = Color("718951")
const BRICK = Color("b58360")
const ROLE_COLORS = [Color("71b8dc"), Color("eab765"), Color("99c983"), Color("d68c8c"), Color("ad98d2")]
signal presentation_cue(event: Dictionary)
const UnitPresentation = preload("res://scenes/battle_demo/unit_presentation.gd")
const BattleAnimation = preload("res://scenes/battle_demo/battle_animation.gd")
const Board = preload("res://scenes/battle_demo/battle_board.gd")
var inspector: Control
var battle_background: Texture2D
var background_canvas: CanvasTexture
var background_crop := Rect2(0.085, 0.123, 0.83, 0.833)
var town: Texture2D
var dungeon: Texture2D
var visual_time = 0.0
var effects: Array[Dictionary] = []
var skill_effects: Array[Dictionary] = []
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
var deployment: Control
var battle_presentations: Dictionary = {}

func _gear_inventory() -> Dictionary:
	return {"shoe": equipment}

func _battle_backdrop() -> Texture2D:
	var current_run = get("run")
	if current_run != null:
		for place in Content.MANIFEST.locations:
			if place.id == current_run.node.get("id", "") and place.battle_background != null:
				background_crop = place.battle_crop
				return place.battle_background
	background_crop = Rect2(0.085, 0.123, 0.83, 0.833)
	var path = "res://assets/art/backgrounds/battle_courtyard/day.png" if encounter == 0 else "res://assets/art/backgrounds/battle_classroom/anomaly.png"
	return load(path) if ResourceLoader.exists(path) else null

func _worn_item(role: int) -> String:
	for id in _gear_inventory():
		if _gear_inventory()[id] == role: return id
	return "none"

func _equip_item(id: String, role: int) -> bool:
	if phase != "prepare" or not _deployment_roster().has(role) or id not in ["shoe", "none"]: return false
	if id == "shoe": equipment = role
	elif equipment == role: equipment = -1
	_build_units()
	return true

func _open_codex() -> void:
	if is_instance_valid(codex_panel): return
	codex_panel = load("res://scenes/codex/codex_panel.gd").new()
	add_child(codex_panel)
	codex_panel.closed.connect(func():
		if pause_overlay.visible: pause_actions.get_child(0).grab_focus())

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
	deployment = preload("res://scenes/battle_demo/deployment_panel.gd").new()
	deployment.game = self
	add_child(deployment)
	inspector = preload("res://scenes/battle_demo/battle_inspector.gd").new()
	inspector.game = self
	add_child(inspector)
	if "--autobattle-capture" in OS.get_cmdline_user_args():
		_capture_autobattle()
	elif "--pause-smoke" in OS.get_cmdline_user_args():
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

func _capture_autobattle() -> void:
	set_process(false)
	for resolution in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1920, 1200)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		await get_tree().process_frame
		phase = "prepare"
		_build_units()
		queue_redraw()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/autobattle-prepare-%dx%d.png" % [resolution.x, resolution.y])
		formation = [0, -1, 3, 2, 1, -1]
		_start()
		for step in range(90): _process(STEP)
		queue_redraw()
		await RenderingServer.frame_post_draw
		var screenshot = get_viewport().get_texture().get_image()
		assert(screenshot.get_size() == resolution)
		screenshot.save_png("res://.godot/autobattle-combat-%dx%d.png" % [resolution.x, resolution.y])
		print("AUTO_BATTLE_CAPTURE ", screenshot.get_size())
	get_tree().quit()

func _load_atlas(path: String) -> Texture2D:
	# First-run local demos need no import pass; exports use imported textures.
	if OS.has_feature("editor"):
		return ImageTexture.create_from_image(Image.load_from_file(path))
	return load(path) as Texture2D

func _inspection_unit(role: int) -> Dictionary:
	for unit in units:
		if unit.side == 0 and unit.role == role: return unit
	var unit = _ally_unit(role, 0)
	unit.animation = BattleAnimation.new(unit.battle_animation)
	unit.presentation = UnitPresentation.new()
	return unit

func _start() -> void:
	super._start()
	if phase == "battle" and is_instance_valid(deployment): deployment.cancel()

func _build_units() -> void:
	_clear_battle_presentations()
	super._build_units()
	battle_background = _battle_backdrop()
	background_canvas = CanvasTexture.new()
	background_canvas.diffuse_texture = battle_background
	background_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()
	for u in units:
		u.animation = BattleAnimation.new(u.battle_animation)
		u.presentation = UnitPresentation.new()
	_create_battle_presentations()
	_update_battle_presentations()
	effects.clear()
	skill_effects.clear()
	banner_time = 0

func _process(delta: float) -> void:
	if paused or leaving:
		queue_redraw()
		return
	if not paused:
		var presentation_delta: float = delta * speed if phase == "battle" else delta
		for u in units:
			u.screen_facing = Board.direction(u.facing)
			u.animation.advance(presentation_delta)
			u.presentation.advance(presentation_delta, u)
		visual_time += presentation_delta
		banner_time = maxf(0, banner_time - presentation_delta)
		for fx in effects:
			fx.life -= presentation_delta
		effects = effects.filter(func(fx): return fx.life > 0)
		for fx in skill_effects: fx.age += presentation_delta
		skill_effects = skill_effects.filter(func(fx): return fx.age < fx.resource.duration())
	super._process(delta)
	for u in units:
		if not u.get("action", {}).is_empty() and not u.presentation.action.is_empty():
			u.presentation.action.age = minf(u.action.age + accumulator, u.action.duration)
		u.animation.sync_motion(u.moving and not simulation.closing, u.presentation.action)
	_update_battle_presentations()

func _tick() -> void:
	super._tick()
	for u in units:
		u.screen_facing = Board.direction(u.facing)
		u.animation.sync_health(u.hp, u.max_hp)
		u.presentation.advance(0, u)
	_update_battle_presentations()

func _clear_battle_presentations() -> void:
	for instance in battle_presentations.values():
		if is_instance_valid(instance):
			instance.queue_free()
	battle_presentations.clear()

func _create_battle_presentations() -> void:
	for u in units:
		if u.battle_animation == null or u.battle_animation.presentation_scene == null:
			continue
		var instance = u.battle_animation.presentation_scene.instantiate()
		if not instance is Node2D or not instance.has_method("apply_presentation"):
			push_warning("Battle presentation root must be Node2D and implement apply_presentation(context)")
			instance.queue_free()
			continue
		instance.name = "UnitPresentation%d" % u.id
		add_child(instance)
		battle_presentations[u.id] = instance

func _presentation_context(actor: Dictionary, at: Vector2, factor: float) -> Dictionary:
	var pose: Dictionary = actor.presentation.pose(actor, true)
	var center: Vector2 = origin + (at + pose.offset * factor / 4.0) * scale_factor
	var display_size: Vector2 = actor.battle_animation.display_size
	return {
		"center": center,
		"display_size": display_size * factor / 4.0 * scale_factor,
		"state": actor.animation.state,
		"age": actor.animation.age,
		"duration": actor.animation._duration(actor.animation.state),
		"motion_time": actor.presentation.motion_time,
		"facing_right": actor.presentation.facing_right,
		"tint": pose.tint,
	}

func _update_battle_presentations() -> void:
	for u in units:
		var instance: Node2D = battle_presentations.get(u.id)
		if not is_instance_valid(instance):
			continue
		if phase == "prepare" and u.side == 0 and is_instance_valid(deployment) and deployment.previews_unit(u.role):
			instance.visible = false
			continue
		var at := _unit_center(u) + Vector2(0, 13)
		instance.z_index = int(round(at.y))
		instance.call("apply_presentation", _presentation_context(u, at, 4.0))

func _presentation_handles(u: Dictionary) -> bool:
	var instance: Node2D = battle_presentations.get(u.id)
	if not is_instance_valid(instance):
		return false
	return not instance.has_method("handles_presentation_state") or instance.call(
		"handles_presentation_state", u.animation.state)

func _finish_delay() -> float:
	var remaining := 0.65
	for fx in skill_effects:
		remaining = maxf(remaining, fx.resource.duration() - fx.age)
	for u in units:
		if u.hp <= 0:
			remaining = maxf(remaining, u.animation._duration(&"death") - (u.animation.age if u.animation.state == &"death" else 0.0))
	return remaining

func _present_action(actor: Dictionary, casts_skill: bool) -> void:
	actor.animation.play(&"cast" if casts_skill else &"attack")

func _present_simulation_event(event: Dictionary) -> void:
	var visual_event = event.duplicate(true)
	visual_event.from = _project(event.from)
	visual_event.to = _project(event.to)
	if event.kind.begins_with("action_"):
		simulation.unit(event.actor_id).presentation.consume(visual_event)
	if event.kind == "impact":
		simulation.unit(event.target_id).presentation.consume(visual_event)
	presentation_cue.emit(event.duplicate(true))
	super._present_simulation_event(event)
	if event.kind == "action_released" and event.casts:
		var actor = simulation.unit(event.actor_id)
		if actor.skill.battle_effect != null and actor.skill.battle_effect.duration() > 0:
			skill_effects.append({"resource": actor.skill.battle_effect, "actor_id": actor.id,
				"age": 0.0, "action_id": event.action_id})
		banner = actor.name + "  ·  " + actor.skill.display_name
		banner_time = 1.3

func _project(position: Vector2) -> Vector2:
	return Board.project(position)

func _unit_center(unit: Dictionary) -> Vector2:
	if phase != "battle" or simulation.finished: return _project(unit.position)
	return _project(UnitPresentation.position(unit, accumulator / STEP))

func _present_event(e: Dictionary) -> void:
	if e.kind == "damage" and e.get("actual", 0) > 0:
		e.target.animation.play(&"hurt")
	var tint: Color = GOLD if e.special else (TEAL if e.actor.side == 0 else RED)
	if e.kind == "heal": tint = Color("a3ef98")
	elif e.kind == "shield": tint = Color("8ad8ff")
	var occupied_lanes = {}
	for fx in effects:
		if fx.target_id == e.target.id and fx.life > 0: occupied_lanes[fx.lane] = true
	var lane := 0
	while occupied_lanes.has(lane): lane += 1
	effects.append({"from": _project(e.get("from", e.actor.position)) + Vector2(0, -6),
		"to": _project(e.get("to", e.target.position)) + _hit_offset(e.target),
		"kind": e.kind, "special": e.special, "value": int(e.get("actual", e.value)),
		"color": tint, "life": 0.65, "target_id": e.target.id, "lane": lane,
		"blocked": e.get("blocked", 0), "shield_break": e.get("shield_break", false)})

func _slot_rect(side: int, slot: int) -> Rect2:
	return Board.slot_rect(side, slot)

func _action_rect(index: int) -> Rect2:
	return [Rect2(1050, 622, 180, 46), Rect2(908, 622, 128, 46), Rect2(-500, -500, 1, 1), Rect2(1070, 565, 160, 36), Rect2(1050, 678, 180, 30)][index]

func _pixel_panel(rect: Rect2, fill: Color, edge: Color = DARK) -> void:
	preload("res://scenes/ui/comic_ui.gd").card(self,rect,fill,edge)

func _sprite(sheet: Texture2D, source: Rect2, at: Vector2, factor: float = 3, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(sheet, Rect2(at.round(), source.size * factor), source, tint)

func _tile(sheet: Texture2D, x: int, y: int, at: Vector2, factor: float = 3, tint: Color = Color.WHITE) -> void:
	_sprite(sheet, Rect2(x * 16, y * 16, 16, 16), at, factor, tint)

func _center(at: Vector2, value: String, color: Color = PAPER, font_size: int = 16) -> void:
	_text(at - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0), value, color, font_size)

func _campus(show_battle_marks: bool = true) -> void:
	var wide = get("screen") == null or get("screen") == "battle"
	if wide and battle_background != null:
		var source = Rect2(background_crop.position * battle_background.get_size(), background_crop.size * battle_background.get_size())
		draw_texture_rect_region(background_canvas, Rect2(24, 92, 1220, 516), source)
		return
	if wide: draw_set_transform(origin, 0, Vector2(1.365, 1) * scale_factor)
	_legacy_campus(false if wide else show_battle_marks)
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)

func _legacy_campus(show_battle_marks: bool = true) -> void:
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
	if not show_battle_marks: return
	for x in range(212, 748, 22):
		draw_rect(Rect2(x, 390, 12, 3), Color("ded5b0"))
	_center(Vector2(468, 386), "裂 隙 边 界", Color("655f5c"), 12)
	# Floating corruption motes near the enemy backline.
	for i in range(9):
		var p = Vector2(235 + i * 57, 185 + int(sin(visual_time * 1.7 + i) * 7))
		draw_rect(Rect2(p, Vector2(4, 4)), Color("b28bbb"))

func _pawn(u: Dictionary, at: Vector2, factor: float = 4) -> void:
	if _presentation_handles(u):
		return
	var alive: bool = u.hp > 0
	var animated_texture: Texture2D = u.animation.texture()
	var pose: Dictionary = u.presentation.pose(u, animated_texture != null)
	var p: Vector2 = at + pose.offset * factor / 4.0
	var world = Transform2D(0, Vector2.ONE * scale_factor, 0, origin)
	var stretch: Vector2 = pose.stretch
	if animated_texture != null and u.battle_animation.flip_with_facing and pose.flip:
		stretch.x *= -1
	var local = Transform2D(pose.rotation, stretch, 0, p)
	draw_set_transform_matrix(world * local)
	if animated_texture != null:
		var dimensions: Vector2 = u.battle_animation.display_size * factor / 4.0
		var rect = Rect2(-dimensions * u.battle_animation.anchor, dimensions)
		draw_texture_rect(animated_texture, rect, false, pose.tint)
	else:
		draw_texture_rect(u.portrait, Rect2(-Vector2(8, 14) * factor, Vector2(16, 16) * factor), false, pose.tint)
	draw_set_transform_matrix(world)
	if u.side == 0 and alive:
		draw_rect(Rect2(p + Vector2(20, -25), Vector2(10, 10)), u.badge_color)
		if u.role == equipment: _tile(dungeon, 8, 10, p + Vector2(24, -3), 1.3)
	if u.shield > 0 and alive:
		var poly = PackedVector2Array([p + Vector2(-32,-52), p + Vector2(32,-52), p + Vector2(38,-34), p + Vector2(24,8), p + Vector2(0,18), p + Vector2(-24,8), p + Vector2(-38,-34), p + Vector2(-32,-52)])
		draw_polyline(poly, Color("8dd7e7"), 3)

func _draw_unit(u: Dictionary) -> void:
	if phase == "prepare" and u.side == 0 and is_instance_valid(deployment) and deployment.previews_unit(u.role): return
	var p = _unit_center(u) + Vector2(0, 13)
	var alive: bool = u.hp > 0
	var chosen: bool = phase == "prepare" and u.side == 0 and u.role == selected and (not is_instance_valid(deployment) or deployment.selected_role == u.role)
	var swap_source: bool = phase == "prepare" and u.side == 0 and is_instance_valid(deployment) and deployment.is_swap_source(u.role)
	# Small base, not a character card: the actor stands on the map.
	draw_rect(Rect2(p + Vector2(-29, -3), Vector2(58, 12)), Color(0.15, 0.23, 0.20, 0.3))
	if swap_source:
		draw_rect(Rect2(p + Vector2(-45, -11), Vector2(90, 28)), Color(GOLD, 0.18))
		draw_rect(Rect2(p + Vector2(-43, -9), Vector2(86, 24)), Color("fff0a8"), false, 4)
		draw_line(p + Vector2(-53, 3), p + Vector2(-43, 3), Color("fff0a8"), 4)
		draw_line(p + Vector2(43, 3), p + Vector2(53, 3), Color("fff0a8"), 4)
	if chosen:
		draw_rect(Rect2(p + Vector2(-37,-7), Vector2(74, 20)), GOLD, false, 3)
		_center(p + Vector2(0,-72), "▼", GOLD, 16)
	_pawn(u, p)
	var hp = Rect2(p + Vector2(-36, 19), Vector2(72, 6))
	draw_rect(hp.grow(2), DARK)
	draw_rect(hp, Color("566354"))
	hp.size.x *= clampf(u.hp / u.max_hp, 0, 1)
	draw_rect(hp, Color("a7d684") if u.side == 0 else Color("df9386"))
	draw_rect(Rect2(p + Vector2(-40, 27), Vector2(80, 21)), Color(PAPER, 0.92))
	_center(p + Vector2(0, 41), u.name if alive else "已退场", DARK, 14)
	for i in range(u.skill.attacks_to_trigger):
		draw_rect(Rect2(p + Vector2(-10 + i * 8, 46), Vector2(5, 3)), GOLD if i < u.count else Color("747a62"))

func _hit_offset(unit: Dictionary) -> Vector2:
	return unit.battle_animation.hit_offset if unit.battle_animation != null else Vector2(0, -6)

func _projectile_style(shot: Dictionary) -> Resource:
	var actor = simulation.unit(shot.actor_id)
	return actor.battle_animation.projectile_style if actor != null and actor.battle_animation != null else null

func _projectile_point(shot: Dictionary, alpha: float) -> Vector2:
	var target = simulation.unit(shot.target_id)
	var actor = simulation.unit(shot.actor_id)
	var position: Vector2 = shot.previous_position.lerp(shot.position, clampf(alpha, 0, 1))
	var launch := Vector2(0, -6)
	if actor.battle_animation != null:
		launch = actor.battle_animation.launch_offset
		if actor.battle_animation.flip_with_facing and _project(target.position).x < _project(shot.origin).x: launch.x *= -1
	var distance: float = shot.origin.distance_to(target.position)
	var progress := clampf(shot.origin.distance_to(position) / maxf(0.001, distance), 0, 1)
	return _project(position) + launch.lerp(_hit_offset(target), progress)

func _draw_effects() -> void:
	for fx in skill_effects:
		var texture: Texture2D = fx.resource.texture(fx.age)
		if texture == null: continue
		var actor = simulation.unit(fx.actor_id)
		var center: Vector2 = _unit_center(actor) + fx.resource.offset
		draw_texture_rect(texture, Rect2(center - fx.resource.display_size * fx.resource.anchor,
			fx.resource.display_size), false)
	for shot in simulation.projectiles:
		var p = _projectile_point(shot, accumulator / STEP)
		var target = simulation.unit(shot.target_id)
		var direction = (_project(target.position) + _hit_offset(target) - p).normalized()
		if direction.is_zero_approx(): direction = Vector2.RIGHT
		var color = GOLD if shot.special else (TEAL if simulation.unit(shot.actor_id).side == 0 else RED)
		var projectile_style = _projectile_style(shot)
		if projectile_style != null and projectile_style.usable():
			var world := Transform2D(0.0, Vector2.ONE * scale_factor, 0.0, origin)
			var local := Transform2D(direction.angle() + deg_to_rad(projectile_style.rotation_offset_degrees), Vector2.ONE, 0.0, p)
			draw_set_transform_matrix(world * local)
			draw_texture_rect(projectile_style.texture,
				Rect2(-projectile_style.display_size * projectile_style.anchor, projectile_style.display_size), false)
			draw_set_transform_matrix(world)
			var rear: float = projectile_style.display_size.x * projectile_style.anchor.x + projectile_style.trail_gap
			for tail in range(3):
				var q: Vector2 = p - direction * (rear + tail * 6.0)
				draw_circle(q, 2.85 - tail * 0.65, Color(color, 0.8 - tail * 0.2))
		else:
			for tail in range(4):
				var q: Vector2 = p - direction * tail * 6
				draw_circle(q, 3.5 - tail * 0.65, Color(color, 1 - tail * 0.2))
	for fx in effects:
		var age: float = 0.65 - fx.life
		var opacity = clampf(fx.life / 0.2, 0, 1)
		var color = Color(fx.color, opacity)
		if fx.kind == "damage":
			if age < 0.22:
				var r = 5 + age * 80
				for i in range(6):
					var direction = Vector2.from_angle(i * TAU / 6)
					draw_line(fx.to + direction * r, fx.to + direction * (r + 7), color, 2)
			if fx.shield_break and age < 0.35:
				for i in range(6):
					var q: Vector2 = fx.to + Vector2.from_angle(i * TAU / 6) * (18 + age * 60)
					draw_line(q, q + Vector2(4, 8), Color("8ad8ff"), 2)
		else:
			for i in range(4):
				var q: Vector2 = fx.to + Vector2((i - 1.5) * 10, -age * 35 + (i % 2) * 9)
				draw_line(q, q + Vector2(0, 8), color, 2)
				if fx.kind == "heal": draw_line(q + Vector2(-4, 4), q + Vector2(4, 4), color, 2)
		if fx.value > 0 or fx.blocked > 0:
			var label = ("-" if fx.kind == "damage" else "+") + str(fx.value)
			if fx.kind == "damage" and fx.value == 0: label = "格挡"
			var at: Vector2 = fx.to + Vector2(18 + fx.lane * 8, -35 - age * 28 - fx.lane * 20)
			_center(at + Vector2(1, 1), label, Color(DARK, opacity), 22 if fx.special else 18)
			_center(at, label, color, 22 if fx.special else 18)

func _pixel_button(index: int, text: String, active: bool = false, enabled: bool = true) -> void:
	var rect = _action_rect(index)
	var fill = Color("c5a66c") if active else Color("fff9ee")
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
	_pixel_panel(Rect2(20, 16, 1220, 62), Color("202027"), Color("132c2d"))
	_text(Vector2(40, 45), "重返校园", PAPER, 27)
	_text(Vector2(42, 65), "RETURN TO SUMMER", Color("c0b792"), 11)
	_text(Vector2(238, 45), "01 / 旧校庭院", PAPER, 20)
	_text(Vector2(238, 66), "悬停角色简览，点击详情与装备。", Color("b2baa0"), 12)
	var state_text = "战前整备" if phase == "prepare" else ("战斗胜利 · 全员恢复" if phase == "result" and result_won else ("重整旗鼓 · 无限重试" if phase == "result" else ("战斗暂停" if paused else ("战斗收尾" if simulation.closing else "自走棋战斗"))))
	_center(Vector2(790, 53), state_text, GOLD, 20)
	_text(Vector2(972, 53), ("部署 %d / 4" % (6 - formation.count(-1))) if phase == "prepare" else ("%02d:%02d / %d×" % [int(elapsed) / 60, int(elapsed) % 60, speed]), PAPER, 17)
	_pixel_panel(Rect2(1148, 28, 78, 36), Color("fff9ee"))
	_center(Vector2(1187, 53), "菜单", DARK, 17)
	_campus()
	if phase == "prepare":
		for entry in [["我后", 260], ["我前", 450], ["敌前", 810], ["敌后", 1000]]:
			draw_rect(Rect2(Vector2(entry[1] - 28, 106), Vector2(56, 26)), Color(DARK, 0.78))
			_center(Vector2(entry[1], 125), entry[0], PAPER, 15)
	# Only the inspected unit shows reach, avoiding a field of overlapping rings.
	for u in units:
		if u.hp <= 0: continue
		if phase == "prepare" and u.side == 0 and is_instance_valid(deployment) and deployment.previews_unit(u.role): continue
		if not is_instance_valid(inspector) or inspector.observed.is_empty(): continue
		if u.id != inspector.observed.id: continue
		var ring = PackedVector2Array()
		for i in range(65):
			var logical_offset = Vector2.from_angle(TAU * i / 64.0) * u.attack_range
			var point = _project(u.position + logical_offset)
			ring.append(point.clamp(Vector2(40, 150), Vector2(1240, 580)))
		draw_polyline(ring, GOLD, 1.5, true)
		if phase == "battle" and u.target_id >= 0 and units[u.target_id].hp > 0:
			draw_dashed_line(_unit_center(u), _unit_center(units[u.target_id]), GOLD, 1.5, 5)
	for side in range(2):
		for slot in range(6):
			var rect = _slot_rect(side, slot)
			if phase == "prepare":
				var tint = Color(0.65, 0.26, 0.36, 0.12) if side == 1 else Color(0.22, 0.44, 0.36, 0.15)
				draw_rect(Rect2(rect.position + Vector2(5,14), rect.size - Vector2(10,20)), tint)
				if side == 0:
					draw_rect(Rect2(rect.position + Vector2(5,14), rect.size - Vector2(10,20)), inspector.theme_accent, false, 2)
					if formation[slot] < 0:
						_center(rect.get_center() + Vector2(0,10), "+", Color("728369"), 24)
					if selected == 0 and inspected_enemy_slot < 0 and (not is_instance_valid(deployment) or deployment.selected_role == 0) and not (is_instance_valid(deployment) and deployment.previews_unit(0)):
						var guard_slot = formation.find(0)
						if guard_slot >= 0 and Vector2(slot % 3 - guard_slot % 3, int(slot / 3) - int(guard_slot / 3)).length() <= 1.025:
							draw_rect(rect.grow(-9), Color(0.45, 0.85, 1.0, 0.2))
	var ordered = units.duplicate()
	ordered.sort_custom(func(a, b): return _unit_center(a).y < _unit_center(b).y)
	for u in ordered:
		_draw_unit(u)
	_draw_effects()
	if banner_time > 0 and phase == "battle":
		_pixel_panel(Rect2(267, 99, 418, 40), Color("413b4b"))
		_center(Vector2(476, 126), banner, GOLD, 21)
	if get("screen") == null: _pixel_button(3, "切换敌阵", false, phase == "prepare")
	_pixel_button(0, "开战" if phase == "prepare" else ("继续战斗" if paused else "暂停战斗") if phase == "battle" else "重试", true, phase != "prepare" or formation.count(-1) == 2)
	_pixel_button(4, "返回整备")
	if phase != "prepare":
		_pixel_panel(Rect2(24, 620, 712, 83), Color("202027"))
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
		if phase != "prepare":
			var ordered = units.duplicate()
			ordered.sort_custom(func(a, b): return a.position.y > b.position.y)
			for u in ordered:
				if u.hp > 0 and Rect2(_unit_center(u) - Vector2(36, 48), Vector2(72, 92)).has_point(point):
					inspected_enemy_slot = u.slot if u.side == 1 else -1
					if u.side == 0: selected = u.role
					accept_event()
					return
		if inspected_enemy_slot >= 0 and _action_rect(2).has_point(point):
			accept_event()
			return
		for slot in range(6):
			if phase != "prepare": break
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
	if phase == "prepare" and event is InputEventMouseButton:
		var point: Vector2 = (event.position - origin) / scale_factor
		for slot in range(6):
			if _slot_rect(0, slot).has_point(point):
				return
	super._gui_input(event)

func _input(event: InputEvent) -> void:
	if is_instance_valid(deployment) and event.is_action_pressed("pause") and deployment.active() and deployment.selected_role >= 0:
		deployment.cancel()
		get_viewport().set_input_as_handled()
		return
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
		style.bg_color = Color("fff9ee") if state == "normal" else Color("ef7184")
		style.border_color = DARK if state != "focus" else Color("e92746")
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
	pause_actions.add_child(_menu_button("图鉴", _open_codex))
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
	if is_instance_valid(deployment): deployment.cancel()
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
	formation = [0, -1, 3, 2, 1, -1]
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
