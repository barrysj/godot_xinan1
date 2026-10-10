extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		get_viewport().push_input(event,true)
func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var size := get_window().size
	verify(get_viewport().get_texture().get_image().save_png("res://.godot/feedback-%s-%dx%d.png" % [name,size.x,size.y]) == OK,"Captured "+name)
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/battle-feedback-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game.run.code_programs = ["redirect","repair"]
	var panel = game.code_panel
	panel._process(0)
	game._start()
	panel._process(0)
	await get_tree().process_frame
	for color in game.simulation.blocks: game.simulation.blocks[color] = 6
	panel._update_hud()
	var button: Button = panel.program_controls.redirect.button
	verify(button.has_focus(),"Actual prepare-to-battle transition gives keyboard an initial focus")
	verify(button.ready_age == 0.0,"Readiness edge triggers one short pulse")
	button._process(0.3)
	panel._update_hud()
	verify(button.ready_age >= 0.22,"Repeated HUD update does not restart pulse")
	button.set_readiness(false,true)
	button.set_readiness(true,true)
	verify(button.ready_age >= 0.22,"Reduced motion suppresses readiness animation")
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		panel._process(0)
		button.grab_focus()
		key(KEY_ENTER)
		await get_tree().process_frame
		verify(panel.program_preview.visible and panel.preview_pinned,"Keyboard opens program detail")
		verify(panel.preview_release.has_focus(),"Focus moves to available release button")
		verify(panel.hover_paused() and not game.paused,"Keyboard inspection owns only its operation pause")
		var before: float = game.simulation.elapsed
		game._process(0.2)
		verify(game.simulation.elapsed == before,"Keyboard detail freezes combat")
		verify(panel.get_viewport_rect().encloses(panel.program_preview.get_global_rect()),"Program detail fits viewport")
		verify(panel.program_preview.size.x <= 300,"Program detail remains compact")
		await capture("keyboard")
		key(KEY_ESCAPE)
		await get_tree().process_frame
		verify(not panel.program_preview.visible and not game.paused and button.has_focus(),"Escape closes only detail and restores focus")
		panel.item_controls.supply.icon.grab_focus()
		key(KEY_ENTER)
		await get_tree().process_frame
		verify(panel.selected_item == "supply" and panel.hover_paused(),"Keyboard opens item detail with operation pause")
		verify(panel.item_controls.supply.destination.get_child(0).has_focus(),"Item picker receives focus")
		await capture("item")
		key(KEY_ESCAPE)
		await get_tree().process_frame
		verify(panel.selected_item.is_empty() and not game.paused,"Escape closes item without opening pause menu")
	# Real keyboard confirmation spends the existing recipe exactly once.
	button.grab_focus()
	key(KEY_ENTER)
	await get_tree().process_frame
	var casts: int = game.simulation.casts
	key(KEY_ENTER)
	await get_tree().process_frame
	verify(game.simulation.casts == casts+1 and game.simulation.blocks.purple == 4 and game.simulation.blocks.green == 5,"Keyboard release spends one real shield recipe")
	verify(not panel.program_preview.visible,"Successful keyboard cast closes detail")
	# Mouse remains usable after keyboard operations; real item consumption stays atomic.
	game.simulation.blocks.red = 0
	panel._update_hud()
	click(panel.item_controls.supply.icon)
	await get_tree().process_frame
	verify(panel.selected_item == "supply","Mouse opens item after keyboard navigation")
	click(panel.item_controls.supply.button)
	await get_tree().process_frame
	verify(game.simulation.blocks.red == 3 and panel.selected_item.is_empty(),"Mouse confirms one existing supply and closes the detail")
	# A keyboard-only hover pause must refresh even with a frozen simulation clock.
	panel.pointer = panel.item_controls.converter.icon.get_global_rect().get_center()
	panel._process(0)
	verify(panel.summary.text.contains("悬停暂停"),"Hover label updates without advancing the simulation")
	panel.pointer = Vector2(-10000,-10000)
	panel._process(0)
	verify(not panel.summary.text.contains("暂停"),"Hover exit removes pause label immediately")
	game.paused = true
	key(KEY_ESCAPE)
	verify(not panel.program_preview.visible,"Manual pause cannot reopen a program")
	game.paused = false
	# Actual timed windup and release; observe simulation events, not removed visual caches.
	for encounter in ["patrol","classroom","final"]:
		get_window().size = Vector2i(1920,1080) if encounter == "patrol" else Vector2i(2560,1440) if encounter == "classroom" else Vector2i(1920,1200)
		game.run.node.encounter_id = "encounter_"+encounter
		game.run.node.power = 1.0
		game._start()
		panel._process(0)
		panel.pointer = Vector2(-10000,-10000)
		var release_ids: Array[int] = []
		var record_release := func(event: Dictionary):
			if event.get("kind", "") == "enemy_release": release_ids.append(event.actor_id)
		game.presentation_cue.connect(record_release)
		var warned := false
		var released := false
		var warning_captured := false
		var release_captured := false
		for frame in 900:
			if game.phase != "battle": break
			game._process(1.0/60.0)
			if not game.simulation.warnings.is_empty():
				warned = true
				if not warning_captured and game.simulation.elapsed >= 10.0:
					await capture(encounter+"-warning")
					warning_captured = true
					panel._process(0)
					verify(panel.warning_row.visible and panel.warning_text.text.contains("秒"),"Warning countdown stays in the dedicated footer")
			if not release_ids.is_empty():
				released = true
				var actor = game.simulation.unit(release_ids[0])
				verify(actor.animation.state == &"cast","Timed release drives existing cast in "+encounter)
				if not release_captured:
					await capture(encounter+"-release")
					release_captured = true
				for step in 40: game._process(1.0/60.0)
				verify(actor.action.get("kind", "") != "cast","Real timed cast completes recovery and returns to regular actions")
				break
		game.presentation_cue.disconnect(record_release)
		verify(warned and released,encounter+" reached real warning and release")
		panel.code_fx.advance(2.0,false)
		verify(not panel.code_fx.particles.any(func(p): return p.kind == "enemy_release"),"Release feedback settles without leftover effects")
	print("BATTLE_FEEDBACK_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
