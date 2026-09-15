extends "res://scenes/battle_demo/pixel_battle.gd"
## Developer-only harness: same simulation and renderer, no saves or production art mutation.
const AnimationSet = preload("res://game/content/battle_animation_set.gd")
const ProjectileStyle = preload("res://game/content/battle_projectile_style.gd")
const UnitDefinition = preload("res://game/content/unit_def.gd")
const ActionProfile = preload("res://game/content/battle_action_profile.gd")
enum Mode { IDLE, MOVE, MELEE, RANGED, CAST, HURT, CRITICAL, DEATH }
const MODES = ["待机", "移动", "近战", "远程", "施法", "受击", "濒危", "退场"]
const ACTION_MODES = {"idle": Mode.IDLE, "move": Mode.MOVE, "melee": Mode.MELEE,
	"ranged": Mode.RANGED, "cast": Mode.CAST, "hurt": Mode.HURT,
	"critical": Mode.CRITICAL, "death": Mode.DEATH}
const EVENT_NAMES = {"action_started": "前摇", "action_released": "出手", "impact": "命中",
	"action_finished": "收招", "action_cancelled": "取消", "action_missed": "落空", "projectile_expired": "消散"}
@export var preview_animation: AnimationSet
@export var preview_projectile: ProjectileStyle
@export var preview_presentation_scene: PackedScene
var preview_unit: Resource
var mode := Mode.MELEE
var slow := false
var playback_speed := 1.0
var action_was_requested := false
var repeat := true
var preview_elapsed := 0.0
var history: Array[Dictionary] = []
var toolbar: HBoxContainer
var selector: OptionButton
var preview_pause: Button
var step_button: Button
var tour := false
var tour_stage := 0
var tour_clock := 0.0
var preview_presentations: Array[Node2D] = []

func _ready() -> void:
	super._ready()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview-animation="):
			var path = arg.trim_prefix("--preview-animation=")
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource is AnimationSet: preview_animation = resource
				else: push_warning("Preview requires a BattleAnimationSet resource")
			else: push_warning("Preview animation resource does not exist: " + path)
		elif arg.begins_with("--preview-unit="):
			var path = arg.trim_prefix("--preview-unit=")
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource is UnitDefinition: preview_unit = resource
				else: push_warning("Preview unit requires a CampusUnit resource")
			else: push_warning("Preview unit resource does not exist: " + path)
		elif arg.begins_with("--preview-projectile="):
			var path = arg.trim_prefix("--preview-projectile=")
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource is ProjectileStyle: preview_projectile = resource
				else: push_warning("Preview projectile requires a BattleProjectileStyle resource")
			else: push_warning("Preview projectile resource does not exist: " + path)
		elif arg.begins_with("--preview-presentation="):
			var path = arg.trim_prefix("--preview-presentation=")
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource is PackedScene: preview_presentation_scene = resource
				else: push_warning("Preview presentation requires a PackedScene resource")
			else: push_warning("Preview presentation scene does not exist: " + path)
		elif arg.begins_with("--preview-action="):
			var action := arg.trim_prefix("--preview-action=").to_lower()
			if ACTION_MODES.has(action):
				mode = ACTION_MODES[action]
				action_was_requested = true
			else: push_warning("Unknown preview action: " + action)
		elif arg.begins_with("--preview-speed="):
			var requested_speed := arg.trim_prefix("--preview-speed=").to_float()
			if requested_speed >= 0.05 and requested_speed <= 4.0: playback_speed = requested_speed
			else: push_warning("Preview speed must be between 0.05 and 4.0")
	var resolved_preview_animation: AnimationSet = preview_animation
	if resolved_preview_animation == null and preview_unit != null:
		resolved_preview_animation = preview_unit.battle_animation
	if preview_presentation_scene == null and resolved_preview_animation != null:
		preview_presentation_scene = resolved_preview_animation.presentation_scene
	_create_preview_presentations()
	_create_toolbar()
	_update_mode_availability()
	_reset_preview()
	if "--motion-preview-check" in OS.get_cmdline_user_args(): call_deferred("_check_preview")
	elif "--motion-preview-capture" in OS.get_cmdline_user_args(): call_deferred("_capture_preview")
	elif "--motion-preview-tour" in OS.get_cmdline_user_args():
		tour = true
		repeat = false
		mode = Mode.IDLE
		tour_stage = mode
		_reset_preview()
	get_viewport().size_changed.connect(_update_preview_presentations)

func _create_preview_presentations() -> void:
	if preview_presentation_scene == null: return
	for index in 2:
		var instance = preview_presentation_scene.instantiate()
		if not instance is Node2D or not _can_apply_presentation(instance):
			push_warning("Preview presentation root must be Node2D and implement apply_presentation(context)")
			instance.queue_free()
			continue
		if instance.has_method("configure_motion_preview"):
			instance.call("configure_motion_preview")
		instance.name = "MotionPresentation%d" % index
		add_child(instance)
		preview_presentations.append(instance)

func _create_battle_presentations() -> void:
	# This harness owns two preview instances: one in battle and one enlarged.
	pass

func _can_apply_presentation(instance: Node) -> bool:
	return instance.has_method("apply_presentation") or instance.has_method("apply_motion_preview")

func _apply_preview_presentation(instance: Node, context: Dictionary) -> void:
	if instance.has_method("apply_presentation"):
		instance.call("apply_presentation", context)
	else:
		instance.call("apply_motion_preview", context)

func _create_toolbar() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_top = -100
	margin.offset_bottom = -20
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	margin.anchor_left = 0
	margin.anchor_right = 1
	margin.anchor_top = 1
	margin.anchor_bottom = 1
	margin.offset_top = -100
	margin.offset_bottom = -20
	toolbar = HBoxContainer.new()
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 12)
	margin.add_child(toolbar)
	selector = OptionButton.new()
	for title in MODES: selector.add_item(title)
	selector.selected = mode
	selector.item_selected.connect(func(index): mode = index; _reset_preview())
	toolbar.add_child(selector)
	preview_pause = _preview_button("暂停", func(): paused = not paused; _update_controls())
	_preview_button("重播", _reset_preview)
	var slow_button = _preview_button("慢速", func(): slow = not slow; _update_controls())
	slow_button.toggle_mode = true
	var loop_button = _preview_button("循环", func(): repeat = not repeat)
	loop_button.toggle_mode = true
	loop_button.button_pressed = repeat
	step_button = _preview_button("单步", func():
		paused = false
		advance_preview(STEP)
		paused = true
		_update_controls())
	step_button.tooltip_text = "暂停后推进 0.05 秒模拟"
	_update_controls()

func _attack_modes() -> int:
	return preview_unit.resolved_attack_modes() if preview_unit != null else UnitDefinition.ATTACK_ALL

func _mode_enabled(index: int) -> bool:
	var capabilities := _attack_modes()
	if index == Mode.MELEE:
		return (capabilities & UnitDefinition.ATTACK_MELEE) != 0
	if index == Mode.RANGED:
		return (capabilities & UnitDefinition.ATTACK_RANGED) != 0
	return true

func _update_mode_availability() -> void:
	selector.set_item_disabled(Mode.MELEE, not _mode_enabled(Mode.MELEE))
	selector.set_item_disabled(Mode.RANGED, not _mode_enabled(Mode.RANGED))
	if not _mode_enabled(mode):
		mode = Mode.RANGED if _mode_enabled(Mode.RANGED) else Mode.MELEE
	selector.selected = mode
	selector.tooltip_text = "灰色攻击入口不属于当前角色；双能力角色可同时启用近战和远程。"

func _preview_button(title: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(88, 42)
	button.pressed.connect(callback)
	toolbar.add_child(button)
	return button

func _update_controls() -> void:
	preview_pause.text = "继续" if paused else "暂停"
	step_button.disabled = not paused

func _reset_preview() -> void:
	formation = [0, -1, 3, 2, 1, -1]
	_build_units()
	var actor = units.filter(func(u): return u.side == 0 and u.role == (1 if mode == Mode.RANGED else 0))[0]
	var target = units.filter(func(u): return u.side == 1)[0]
	if preview_unit != null:
		actor = _from_definition(preview_unit, 0, 0, 0)
		actor.animation = BattleAnimation.new(actor.battle_animation)
		actor.presentation = UnitPresentation.new()
	units.assign([actor, target])
	selected = actor.role
	equipment = -1
	actor.id = 0
	target.id = 1
	actor.position = Vector2(2, 3)
	target.position = Vector2(3, 3)
	if mode in [Mode.MOVE, Mode.RANGED]:
		actor.position = Vector2(1, 3)
		target.position = Vector2(4 if mode == Mode.RANGED else 6, 3)
	for u in units:
		u.position = Vector2(u.position.y, 6 - u.position.x)
		u.cell = Vector2i(u.position)
		u.destination = u.cell
		u.target_id = -1
		u.moving = false
		u.timer = 1000.0
		u.interval = 1000.0
		u.hp = 500.0
		u.max_hp = 500.0
		u.atk = 40.0
		u.shield = 0
		if u.get("attack_range") == null: u.attack_range = 6.0
		u.action_profile = u.action_profile.duplicate() if u.get("action_profile") != null else ActionProfile.new()
	if preview_animation != null:
		actor.battle_animation = preview_animation
		actor.animation = BattleAnimation.new(preview_animation)
	if preview_projectile != null:
		actor.battle_animation = actor.battle_animation.duplicate(true) if actor.battle_animation != null else AnimationSet.new()
		actor.battle_animation.projectile_style = preview_projectile
		actor.animation = BattleAnimation.new(actor.battle_animation)
	actor.attack_range = 3.2 if mode == Mode.RANGED else (1.45 if mode in [Mode.MOVE, Mode.MELEE] else actor.attack_range)
	if mode == Mode.MELEE: actor.action_profile.delivery = "melee"
	if mode == Mode.RANGED: actor.action_profile.delivery = "projectile"
	if mode == Mode.CAST: actor.count = actor.skill.attacks_to_trigger - 1
	simulation.reset(units)
	phase = "battle"
	paused = false
	finish_age = 0
	finish_duration = 0.65
	accumulator = 0
	elapsed = 0
	preview_elapsed = 0
	visual_time = 0
	history.clear()
	if mode == Mode.CRITICAL:
		actor.hp = maxf(1.0, actor.max_hp * minf(0.2, actor.battle_animation.critical_ratio if actor.battle_animation != null else 0.2))
		actor.animation.sync_health(actor.hp, actor.max_hp)
	elif mode in [Mode.MELEE, Mode.RANGED, Mode.CAST]:
		actor.timer = 0
		simulation.request_action(0, 1)
	elif mode in [Mode.HURT, Mode.DEATH]:
		target.timer = 0
		if mode == Mode.DEATH: target.atk = 1000
		simulation.request_action(1, 0)
	if is_instance_valid(selector): selector.selected = mode
	if is_instance_valid(step_button): _update_controls()
	queue_redraw()

func advance_preview(delta: float) -> void:
	preview_elapsed += delta
	super._process(delta)
	_update_preview_presentations()

func _process(delta: float) -> void:
	if paused or leaving: return
	var amount = delta * playback_speed * (0.25 if slow else 1.0)
	advance_preview(amount)
	if tour:
		tour_clock += delta
		if tour_clock >= 2.0:
			tour_clock -= 2.0
			tour_stage += 1
			while tour_stage < MODES.size() and not _mode_enabled(tour_stage):
				tour_stage += 1
			if tour_stage >= MODES.size():
				print("MOTION_PREVIEW_TOUR completed all modes")
				get_tree().quit()
				return
			mode = tour_stage
			_reset_preview()
	elif repeat and preview_elapsed >= maxf(2.0, finish_duration + 0.5): _reset_preview()

func _presentation_context(actor: Dictionary, at: Vector2, factor: float) -> Dictionary:
	var pose: Dictionary = actor.presentation.pose(actor, true)
	var center: Vector2 = origin + (at + pose.offset * factor / 4.0) * scale_factor
	var display_size: Vector2 = actor.battle_animation.display_size if actor.battle_animation != null else Vector2(64, 64)
	var state: StringName = actor.animation.state
	return {
		"center": center,
		"display_size": display_size * factor / 4.0 * scale_factor,
		"state": state,
		"age": actor.animation.age,
		"duration": actor.animation._duration(state),
		"motion_time": actor.presentation.motion_time,
		"facing_right": actor.presentation.facing_right,
		"tint": pose.tint,
		"preview_mode": mode,
	}

func _update_preview_presentations() -> void:
	if preview_presentations.size() != 2 or units.is_empty(): return
	var actor: Dictionary = units[0]
	_apply_preview_presentation(preview_presentations[0], _presentation_context(
		actor, _unit_center(actor) + Vector2(0, 13), 4.0))
	_apply_preview_presentation(preview_presentations[1], _presentation_context(
		actor, Vector2(1080, 520), 8.0))

func _presentation_handles(u: Dictionary) -> bool:
	if preview_presentations.is_empty() or u.id != 0: return false
	var presentation := preview_presentations[0]
	if presentation.has_method("handles_presentation_state"):
		return presentation.call("handles_presentation_state", u.animation.state)
	return not presentation.has_method("handles_motion_preview_state") or presentation.call(
		"handles_motion_preview_state", u.animation.state)

func _pawn(u: Dictionary, at: Vector2, factor: float = 4) -> void:
	if _presentation_handles(u): return
	super._pawn(u, at, factor)

func _present_simulation_event(event: Dictionary) -> void:
	super._present_simulation_event(event)
	history.append(event.duplicate(true))
	if history.size() > 12: history.pop_front()

func _return_to_formation() -> void:
	_resume_battle()
	_reset_preview()

func _gui_input(_event: InputEvent) -> void:
	pass

func _draw() -> void:
	if town == null or units.size() != 2: return
	scale_factor = minf(size.x / 1280, size.y / 720)
	origin = (size - Vector2(1280, 720) * scale_factor) / 2
	draw_rect(Rect2(Vector2.ZERO, size), Color("253a36"))
	draw_set_transform(origin, 0, Vector2.ONE * scale_factor)
	_pixel_panel(Rect2(24, 18, 1220, 58), PAPER)
	_text(Vector2(44, 56), "动作预览 · " + MODES[mode], DARK, 24)
	var source_name: String = preview_unit.display_name if preview_unit != null else "预设角色"
	var source_detail := "骨骼＋序列帧" if preview_presentation_scene != null else ("自定义序列帧" if preview_animation != null else "角色动作图集")
	var active_projectile = units[0].battle_animation.projectile_style if not units.is_empty() and units[0].battle_animation != null else null
	if preview_projectile != null or active_projectile != null: source_detail += "＋弹体"
	var effective_speed := playback_speed * (0.25 if slow else 1.0)
	_text(Vector2(520, 53), "开发测试 / " + source_name + " / " + source_detail + " / %.2f×" % effective_speed, DARK, 17)
	_campus(false)
	var ordered = units.duplicate()
	ordered.sort_custom(func(a, b): return _unit_center(a).y < _unit_center(b).y)
	for u in ordered:
		_draw_unit(u)
		var point = _unit_center(u) + Vector2(0, 13)
		draw_line(point - Vector2(8, 0), point + Vector2(8, 0), GOLD, 1)
		draw_line(point - Vector2(0, 8), point + Vector2(0, 8), GOLD, 1)
	_draw_effects()
	_pixel_panel(Rect2(936, 92, 310, 516), PAPER)
	_text(Vector2(957, 124), "事件与命中", DARK, 22)
	_text(Vector2(957, 153), "模拟 %.2fs / 弹道 %d" % [simulation.elapsed, simulation.projectiles.size()], DARK, 16)
	var y := 186
	for event in history.slice(maxi(0, history.size() - 6)):
		var description: String = EVENT_NAMES.get(event.kind, event.kind)
		if event.kind == "impact": description += "  %d" % event.actual
		_text(Vector2(957, y), "%.2f  #%d  %s" % [event.time, event.action_id, description], DARK, 15)
		y += 24
	_pawn(units[0], Vector2(1080, 520), 8)
	_text(Vector2(957, 564), "十字标记为逻辑脚底", DARK, 15)
	_text(Vector2(957, 586), "右侧为角色放大预览", DARK, 15)
	_pixel_panel(Rect2(24, 617, 894, 34), PAPER)
	_text(Vector2(40, 641), "前摇 → 出手 → 命中 → 收招；暂停后可单步检查。", DARK, 16)

func _check_preview() -> void:
	set_process(false)
	repeat = false
	var failures = 0
	if selector.is_item_disabled(Mode.MELEE) != (not _mode_enabled(Mode.MELEE)):
		failures += 1
	if selector.is_item_disabled(Mode.RANGED) != (not _mode_enabled(Mode.RANGED)):
		failures += 1
	if preview_presentation_scene != null and preview_presentations.size() != 2:
		failures += 1
	for index in MODES.size():
		if not _mode_enabled(index):
			print("MOTION_PREVIEW_MODE ", MODES[index], " SKIP unsupported")
			continue
		mode = index
		_reset_preview()
		for i in 25: advance_preview(STEP)
		var impacts = history.filter(func(e): return e.kind == "impact")
		var ok = true
		if mode in [Mode.IDLE, Mode.MOVE, Mode.CRITICAL]: ok = impacts.is_empty()
		else: ok = not impacts.is_empty()
		if mode == Mode.MOVE: ok = ok and units[0].position.y < 5
		if mode == Mode.RANGED:
			var release = history.filter(func(e): return e.kind == "action_released")
			ok = ok and impacts[0].time > release[0].time
			if preview_presentation_scene != null: ok = ok and _presentation_handles(units[0])
		if mode == Mode.CRITICAL: ok = ok and units[0].animation.state == &"critical"
		if mode == Mode.DEATH:
			ok = ok and units[0].hp <= 0
			if preview_presentation_scene != null: ok = ok and not _presentation_handles(units[0])
		if not ok:
			failures += 1
			push_error("Preview mode failed: " + MODES[mode])
		print("MOTION_PREVIEW_MODE ", MODES[mode], " ", "PASS" if ok else "FAIL")
	mode = Mode.RANGED if _mode_enabled(Mode.RANGED) else Mode.MELEE
	_reset_preview()
	preview_pause.pressed.emit()
	var before = simulation.elapsed
	_process(1.0)
	if not paused or simulation.elapsed != before: failures += 1
	step_button.pressed.emit()
	if not paused or not is_equal_approx(simulation.elapsed, before + STEP): failures += 1
	preview_pause.pressed.emit()
	toolbar.get_child(3).pressed.emit()
	before = preview_elapsed
	_process(0.2)
	if not slow or not is_equal_approx(preview_elapsed - before, 0.2 * playback_speed * 0.25): failures += 1
	print("MOTION_PREVIEW_CHECK failures=", failures)
	get_tree().quit(failures)

func _capture_preview() -> void:
	set_process(false)
	repeat = false
	var capture_modes: Array = [mode] if action_was_requested else [Mode.MELEE, Mode.RANGED, Mode.CAST, Mode.HURT, Mode.CRITICAL, Mode.DEATH]
	for resolution in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1920, 1200)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		await get_tree().process_frame
		for index in capture_modes:
			if not _mode_enabled(index): continue
			mode = index
			_reset_preview()
			for i in (10 if mode == Mode.CAST else (7 if mode == Mode.RANGED else 5)): advance_preview(STEP)
			queue_redraw()
			await RenderingServer.frame_post_draw
			var screenshot = get_viewport().get_texture().get_image()
			assert(screenshot.get_size() == resolution)
			var source_tag := "rig-" if preview_presentation_scene != null else ""
			screenshot.save_png("res://.godot/motion-preview-%s%d-%dx%d.png" % [source_tag, mode, resolution.x, resolution.y])
		print("MOTION_PREVIEW_CAPTURE ", resolution)
	get_tree().quit()
