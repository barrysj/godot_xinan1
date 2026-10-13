extends RefCounted
## Actual Campaign/F8 editor integration, never a parallel battle or save model.
const Model = preload("res://game/debug/battle_tuning.gd")
var checks := 0
var failures := 0

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("BATTLE_TUNING_CHECK: " + label)

func click(hub, button: Button) -> void:
	if DisplayServer.get_name() == "headless": button.pressed.emit(); return
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hub.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	hub.get_viewport().push_input(event,true)

func choose(selector: OptionButton, id: String) -> void:
	for index in selector.item_count:
		if selector.get_item_metadata(index) == id:
			selector.select(index)
			selector.item_selected.emit(index)
			return
	verify(false,"choice is registered: " + id)

func capture(hub, path: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = hub.get_viewport().get_texture().get_image()
	verify(image.get_size() == hub.get_window().size,"capture uses actual viewport")
	verify(image.save_png("res://.godot/" + path) == OK,"actual screenshot saved")

func open_editor(hub):
	hub.debug_panel.open()
	if "--battle-tuning-capture" in OS.get_cmdline_user_args(): await capture(hub,"battle-tuning-menu.png")
	await click(hub,hub.debug_panel.tuning_button)
	return hub.debug_panel.tuning_editor

func run_checks(hub) -> void:
	hub.set_process(false)
	var profile_paths := ["user://campus_progress.json","user://campus_debug_progress.json"]
	var originals: Array = profile_paths.map(func(path): return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
	if not hub.debug_enabled:
		verify(Model.apply(hub,{}) != "","normal mode refuses modifiers")
		verify(hub.debug_battle_tuning.is_empty() and not is_instance_valid(hub.debug_panel),"normal mode has no modifier UI or settings")
		finish(hub)
		return
	verify(hub.screen == "battle" and hub.phase == "battle","original launcher starts actual battle")
	var build: Dictionary = hub.run.to_dict().duplicate(true)
	var encounter: String = hub.encounter_id
	var default_background: Texture2D = hub.battle_background
	var resource_values: Array = Model.Content.MANIFEST.enemies.map(func(definition): return [definition.id,definition.health,definition.attack,definition.defense,definition.interval])
	var baseline := {}
	for unit in hub.units: baseline["%s:%d" % [unit.side,unit.slot]] = Model.stats(unit)
	hub._process(0.7)
	var editor = await open_editor(hub)
	verify(hub.paused and hub.debug_panel.editing_battle,"actual F8 modification page pauses battle")
	verify(editor.slot_buttons.size() == 6 and editor.enemy_selector.item_count == Model.Content.MANIFEST.enemies.size()+1,"six graphical slots expose registered enemies plus empty")
	var before_edit: Array = hub.units.map(func(unit): return [unit.content_id,unit.hp,unit.atk])
	await click(hub,editor.slot_buttons[0])
	choose(editor.enemy_selector,"cyber_librarian")
	choose(editor.background_selector,"lab")
	for key in {"max_hp":777,"atk":66,"def":17,"interval":0.75,"attack_range":4.0,"move_speed":3.0}:
		editor.stat_fields[key].value = {"max_hp":777,"atk":66,"def":17,"interval":0.75,"attack_range":4.0,"move_speed":3.0}[key]
	editor.ally_health.value = 1.5
	editor.ally_attack.value = 1.2
	verify(hub.units.map(func(unit): return [unit.content_id,unit.hp,unit.atk]) == before_edit and hub.battle_background == default_background,"editing draft leaves live stats and background unchanged")
	if "--battle-tuning-capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			hub.get_window().size = resolution
			await capture(hub,"battle-tuning-editor-%dx%d.png" % [resolution.x,resolution.y])
			verify(hub.debug_panel.panel.page_scroll.get_global_rect().encloses(editor.apply_button.get_global_rect()),"apply action remains fully visible in scroll viewport at each size")
			verify(editor.ally_health.size.y < 80 and editor.ally_attack.size.y < 80,"ally numeric inputs keep a compact readable row")
	await click(hub,editor.apply_button)
	verify(not hub.paused and not hub.debug_panel.panel.visible and hub.phase == "battle" and hub.elapsed == 0,"actual apply button restarts and resumes")
	var changed: Dictionary = hub.units.filter(func(unit): return unit.side == 1 and unit.slot == 0)[0]
	verify(changed.content_id == "cyber_librarian" and changed.max_hp == 777 and changed.atk == 66 and changed.def == 17,"enemy identity and integer values apply to actual unit")
	verify(changed.interval == 0.75 and changed.attack_range == 4 and changed.move_speed == 3 and changed.timer == changed.interval,"timing and spatial stats apply")
	verify(hub.battle_background == load(Model.BACKGROUNDS.lab.path) and hub.background_canvas.diffuse_texture == hub.battle_background,"actual renderer uses selected background")
	for unit in hub.units:
		verify(unit.hp == unit.max_hp and unit.damage == 0 and unit.healing == 0,"applied battle starts with full health and cleared statistics")
		if unit.side == 0:
			var base: Dictionary = baseline["0:%d" % unit.slot]
			verify(unit.max_hp == roundf(base.max_hp*1.5) and unit.atk == roundf(base.atk*1.2),"ally multipliers preserve original equipment and growth base")
	var actor_ids := {}
	for unit in hub.units: actor_ids[unit.id] = true
	verify(hub.simulation.units == hub.units and actor_ids.size() == hub.units.size(),"original simulation consumes rebuilt roster with unique actor identities")
	verify(hub.run.to_dict() == build and hub.encounter_id == encounter,"modifier never changes original run build or encounter identity")
	if "--battle-tuning-capture" in OS.get_cmdline_user_args(): await capture(hub,"battle-tuning-applied.png")
	hub._process(1.0)
	verify(hub.elapsed > 0,"modified battle advances through original simulation")
	# Reapply and share the same enemy resource across multiple independent slots.
	editor = await open_editor(hub)
	verify(hub.debug_panel.difficulty_selector.disabled,"custom stats visibly take precedence over difficulty presets")
	await click(hub,editor.slot_buttons[1])
	choose(editor.enemy_selector,"cyber_librarian")
	editor.stat_fields.max_hp.value = 888
	await click(hub,editor.apply_button)
	verify(hub.units.filter(func(unit): return unit.side == 1 and unit.content_id == "cyber_librarian").size() == 2,"same enemy resource can occupy different slots")
	verify(hub.units.filter(func(unit): return unit.side == 1 and unit.slot == 0)[0].max_hp == 777,"reapply does not multiply already modified health")
	var ally: Dictionary = hub.units.filter(func(unit): return unit.side == 0)[0]
	verify(ally.max_hp == roundf(baseline["0:%d" % ally.slot].max_hp*1.5),"ally modifiers do not accumulate on reapply")
	var valid: Dictionary = Model.snapshot(hub)
	for bad in ["empty","unknown","duplicate","nan","background","scope"]:
		var invalid: Dictionary = valid.duplicate(true)
		match bad:
			"empty":
				for row in invalid.enemies: row.id = ""
			"unknown": invalid.enemies[0].id = "missing_enemy"
			"duplicate": invalid.enemies[1].slot = 0
			"nan": invalid.enemies[0].stats.atk = NAN
			"background": invalid.background = "../../outside"
			"scope": invalid.scope = "other_battle"
		verify(Model.apply(hub,invalid) != "" and hub.debug_battle_tuning == valid,"invalid " + bad + " is rejected before changing live configuration")
	var save_path: String = hub.progress.path
	hub.progress.path = "res://.godot/missing-battle-tuning-directory/profile.json"
	verify(Model.apply(hub,valid) != "" and hub.debug_battle_tuning == valid,"failed checkpoint refuses configuration changes")
	hub.progress.path = save_path
	editor = await open_editor(hub)
	await click(hub,editor.reset_button)
	verify(Model.active(hub),"reset preserves live configuration until applied")
	verify(not editor.draft.enabled,"reset marks draft as ordinary configuration")
	await click(hub,editor.apply_button)
	verify(hub.debug_battle_tuning.is_empty() and hub.battle_background == default_background,"reset restores ordinary enemy roster and background")
	for unit in hub.units: verify(Model.stats(unit) == baseline["%s:%d" % [unit.side,unit.slot]],"reset restores exact ordinary stats")
	var restore_error: String = Model.apply(hub,valid)
	verify(restore_error == "","valid configuration can be restored: " + restore_error)
	hub.run.node.id = "different_place"
	hub._build_units()
	verify(hub.debug_battle_tuning.is_empty(),"leaving current encounter clears process-local modifiers")
	verify(Model.Content.MANIFEST.enemies.map(func(definition): return [definition.id,definition.health,definition.attack,definition.defense,definition.interval]) == resource_values,"all original enemy resource values remain unchanged")
	for index in profile_paths.size():
		var current: PackedByteArray = FileAccess.get_file_as_bytes(profile_paths[index]) if FileAccess.file_exists(profile_paths[index]) else PackedByteArray()
		verify(current == originals[index],"player profile unchanged: " + profile_paths[index])
	finish(hub)

func finish(hub) -> void:
	print("BATTLE_TUNING_CHECK %d checks / %d failures" % [checks,failures])
	hub.get_tree().quit(1 if failures else 0)
