extends RefCounted
## Verify the actual launch state; do not create an encounter in this check.
const Commands = preload("res://game/debug/campus_debug.gd")
var checks := 0
var failures := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DEBUG_BATTLE_CHECK: " + label)

func capture(hub, filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = hub.get_viewport().get_texture().get_image()
	verify(image.get_size() == hub.get_window().size, "actual viewport size")
	image.save_png("res://.godot/" + filename + ".png")

func click(hub, button: Button) -> void:
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		return
	await hub.get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hub.get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	hub.get_viewport().push_input(event, true)

func run_checks(hub) -> void:
	hub.set_process(false)
	var profiles := ["user://campus_progress.json", "user://campus_debug_progress.json"]
	var originals: Array = profiles.map(func(path): return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
	if not hub.debug_enabled:
		verify(not hub.debug_battle_preview, "preview flag requires explicit Debug")
		verify(hub.screen == "base", "normal startup stays at the original base")
		verify(not is_instance_valid(hub.debug_panel), "normal startup has no debug panel")
		finish(hub)
		return
	verify(hub.debug_battle_preview, "launcher requests battle preview")
	verify(hub.screen == "battle" and hub.phase == "prepare" and hub.elapsed == 0, "startup waits in preparation without check setup")
	verify(hub.formation == hub.RunModel.new().formation and hub._living(0).size() == 4, "four original characters deployed at startup")
	verify(hub._living(1).size() > 0 and hub.encounter_id == "encounter_patrol", "ordinary encounter loaded")
	verify(not hub.campaign_panel.visible and not hub.paused, "base panel does not cover battle")
	verify(hub.progress.path == "res://.godot/debug-battle-preview.json" and not hub.progress.load_blocked, "preview does not depend on previous player progress")
	verify(hub.last_save_ok and not hub.CampaignSave.decode(hub.progress.active_run).is_empty(), "existing campaign checkpoint can restore preview")
	verify(is_instance_valid(hub.debug_panel), "battle has the existing Debug menu")
	if hub.demo_options.animations == "current":
		for id in ["guard", "archer", "striker", "healer"]:
			verify(hub.units.any(func(unit): return unit.side == 0 and unit.content_id == id and unit.battle_animation == hub.demo_options.overrides[id]), "current animation loaded for " + id)
	var build: Dictionary = hub.run.to_dict()
	var encounter: String = hub.encounter_id
	hub._process(1.0)
	verify(hub.elapsed == 0 and hub.phase == "prepare", "preparation never advances combat")
	hub._start()
	verify(hub.phase == "battle", "explicit original start enters combat")
	hub._process(1.0)
	verify(hub.elapsed > 0 and hub.phase == "battle", "explicitly started simulation advances")
	if "--debug-battle-capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
			hub.get_window().size = resolution
			await capture(hub, "debug-battle-launch-%dx%d" % [resolution.x, resolution.y])
	var toggle := InputEventKey.new()
	toggle.keycode = KEY_F8
	toggle.pressed = true
	hub._input(toggle)
	verify(hub.debug_panel.panel.visible and hub.paused, "F8 opens Debug directly from startup battle")
	for difficulty in ["hard", "hard", "easy", "normal"]:
		if not hub.debug_panel.panel.visible: hub.debug_panel.open()
		var elapsed: float = hub.elapsed
		hub._process(1.0)
		verify(hub.elapsed == elapsed, "Debug pauses the startup battle")
		var selector: OptionButton = hub.debug_panel.difficulty_selector
		selector.select(Commands.Difficulties.ORDER.find(difficulty))
		selector.item_selected.emit(selector.selected)
		if difficulty == "hard" and "--debug-battle-capture" in OS.get_cmdline_user_args():
			await capture(hub, "debug-battle-launch-menu")
		await click(hub, hub.debug_panel.difficulty_apply)
		verify(hub.debug_battle_difficulty == difficulty and hub.phase == "battle" and hub.elapsed == 0, "apply restarts startup battle at " + difficulty)
		verify(not hub.paused and not hub.debug_panel.panel.visible, "apply returns to running battle")
		verify(hub.run.to_dict() == build and hub.encounter_id == encounter, "restart preserves original build and encounter")
		verify(hub.units.all(func(unit): return unit.hp == unit.max_hp and unit.damage == 0), "restart restores health and damage statistics")
		hub._process(1.0)
	for index in 4000:
		if hub.screen == "report": break
		hub._process(0.05)
	verify(hub.screen == "report", "startup battle reaches ordinary report")
	verify(Commands.execute(hub, "restart") and hub.screen == "battle" and hub.phase == "prepare", "preview report restarts into preparation")
	for index in profiles.size():
		var current: PackedByteArray = FileAccess.get_file_as_bytes(profiles[index]) if FileAccess.file_exists(profiles[index]) else PackedByteArray()
		verify(current == originals[index], "player profile unchanged: " + profiles[index])
	finish(hub)

func finish(hub) -> void:
	print("DEBUG_BATTLE_CHECK %d checks / %d failures" % [checks, failures])
	hub.get_tree().quit(1 if failures else 0)
