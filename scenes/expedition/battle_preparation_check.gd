extends RefCounted
## Mouse-driven regression against the original Campaign, deployment and simulator.
const Model = preload("res://game/debug/battle_tuning.gd")
const Helpers = preload("res://scenes/expedition/battle_tuning_check.gd")
var checks := 0
var failures := 0
var hub
var editor
var helpers = Helpers.new()

func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("BATTLE_PREPARATION_CHECK: "+label)

func frames() -> void:
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = editor.canvas.get_global_transform()*point
	event.pressed = pressed
	hub.get_viewport().push_input(event,true)
	await frames()

func type_value(spin: SpinBox, value: String) -> void:
	var at: Vector2 = editor.canvas.get_global_transform().affine_inverse()*spin.get_line_edit().get_global_rect().get_center()
	await mouse(at,true)
	await mouse(at,false)
	spin.get_line_edit().edit()
	await frames()
	spin.get_line_edit().select_all()
	for character in value:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.keycode = KEY_0+int(character)
		event.pressed = true
		hub.get_viewport().push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		hub.get_viewport().push_input(event,true)
	await frames()

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = editor.canvas.get_global_transform()*point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	hub.get_viewport().push_input(event,true)
	await frames()

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	hub.get_viewport().push_input(event,true)
	await frames()

func point(side: int, slot: int) -> Vector2:
	var unit: Dictionary = editor.unit_at(side,slot)
	for offset in [Vector2(0,-30),Vector2(0,-70),Vector2(20,-85),Vector2(-20,-85),Vector2(0,10)]:
		var at: Vector2 = hub._unit_center(unit)+offset
		var hit: Dictionary = hub.inspector.pick(at)
		if not hit.is_empty() and hit.id == unit.id: return at
	return hub._unit_center(unit)+Vector2(0,-30)

func click_unit(side: int, slot: int) -> void:
	var at := point(side,slot)
	await mouse(at,true)
	await mouse(at,false)
	verify(editor.panel.visible and hub.paused and editor.edit_side == side and editor.edit_slot == slot,"real unit click opens paused editor for %d:%d, got %d:%d phase=%s" % [side,slot,editor.edit_side,editor.edit_slot,hub.phase])

func drag(side: int, source: int, destination: Vector2, screenshot := "") -> void:
	await mouse(point(side,source),true)
	await motion(destination)
	verify(editor.dragging and editor.ghost.visible,"real mouse drag previews unit and destination")
	if side == 1: verify(editor.ghost.flip_h,"enemy drag preview faces left")
	if not screenshot.is_empty(): await capture(screenshot)
	await mouse(destination,false)
	verify(not editor.busy() and not hub.paused,"release ends gesture without opening menu")

func roster() -> Array:
	return hub.units.map(func(unit): return [unit.side,unit.slot,unit.content_id,Model.stats(unit)])

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or "--battle-preparation-capture" not in OS.get_cmdline_user_args(): return
	await frames()
	await RenderingServer.frame_post_draw
	verify(hub.get_viewport().get_texture().get_image().save_png("res://.godot/"+filename+".png") == OK,"actual screenshot saved")

func run_checks(owner_hub) -> void:
	hub = owner_hub
	hub.set_process(false)
	if not hub.debug_enabled:
		verify(not is_instance_valid(hub.battle_context),"Release has no battlefield debug gestures")
		verify(Model.apply(hub,{}) != "","Release refuses temporary battle edits")
		finish()
		return
	editor = hub.battle_context
	await frames()
	var profiles := ["user://campus_progress.json","user://campus_debug_progress.json"]
	var bytes: Array = profiles.map(func(path): return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
	var resources: Array = (Model.Content.MANIFEST.characters+Model.Content.MANIFEST.enemies).map(func(definition): return [definition.id,definition.health,definition.attack,definition.defense,definition.interval])
	var build: Dictionary = hub.run.to_dict().duplicate(true)
	verify(hub.screen == "battle" and hub.phase == "prepare" and hub._living(0).size() == 4,"actual launcher stops in populated preparation")
	verify(hub.units.filter(func(unit): return unit.side == 1).all(func(unit): return not unit.presentation.facing_right),"enemies face left on first preparation frame")
	var before := roster()
	hub._process(3)
	verify(hub.elapsed == 0 and roster() == before,"waiting never runs combat")
	await capture("battle-preparation-start")
	var enemy: Dictionary = hub.units.filter(func(unit): return unit.side == 1)[0]
	var source: int = enemy.slot
	var empty: int = range(6).filter(func(slot): return editor.unit_at(1,slot).is_empty())[0]
	await drag(1,source,hub._slot_rect(1,empty).get_center(),"battle-preparation-drag")
	verify(editor.unit_at(1,source).is_empty() and editor.unit_at(1,empty).content_id == enemy.content_id,"enemy moves into empty ordinary slot")
	verify(Model.stats(editor.unit_at(1,empty)) == Model.stats(enemy) and hub.phase == "prepare" and hub.elapsed == 0,"movement preserves exact stats and preparation")
	var other: Dictionary = hub.units.filter(func(unit): return unit.side == 1 and unit.slot != empty)[0]
	await drag(1,empty,hub._slot_rect(1,other.slot).get_center())
	verify(editor.unit_at(1,other.slot).content_id == enemy.content_id and editor.unit_at(1,empty).content_id == other.content_id,"occupied enemy slots swap")
	before = roster()
	await drag(1,empty,Vector2(630,80))
	verify(roster() == before,"invalid outside drop changes nothing")
	await mouse(point(1,empty),true)
	await motion(hub._slot_rect(1,source).get_center())
	await key(KEY_ESCAPE)
	await mouse(hub._slot_rect(1,source).get_center(),false)
	verify(roster() == before and not editor.busy(),"Escape cancels dragged position")
	await click_unit(1,empty)
	helpers.choose(editor.selector,"cyber_librarian")
	editor.stat_fields.atk.value = 77
	await type_value(editor.stat_fields.max_hp,"4321")
	verify(roster() == before,"quick draft leaves live enemy unchanged")
	await capture("battle-preparation-enemy-menu")
	await helpers.click(hub,editor.apply_button)
	verify(not editor.panel.visible and hub.phase == "prepare" and hub.elapsed == 0,"quick apply returns to preparation")
	verify(editor.unit_at(1,empty).content_id == "cyber_librarian" and editor.unit_at(1,empty).max_hp == 4321 and editor.unit_at(1,empty).atk == 77,"typed enemy value and replacement apply")
	verify(hub.run.to_dict() == build,"enemy edits preserve authoritative build")
	var ally: Dictionary = hub.units.filter(func(unit): return unit.side == 0)[0]
	var ally_slot: int = ally.slot
	var anchor_role: int = ally.get("deployment_role",ally.role)
	await click_unit(0,ally_slot)
	helpers.choose(editor.selector,"inventor")
	for stat in {"max_hp":5321,"atk":83,"def":19,"interval":0.8,"attack_range":4.0,"move_speed":3.0}:
		editor.stat_fields[stat].value = {"max_hp":5321,"atk":83,"def":19,"interval":0.8,"attack_range":4.0,"move_speed":3.0}[stat]
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		if DisplayServer.get_name() != "headless": hub.get_window().size = resolution
		await frames()
		verify(hub.get_viewport_rect().encloses(editor.panel.get_global_rect()),"unit popup fits viewport at each resolution")
		verify(editor.panel.get_global_rect().encloses(editor.apply_button.get_global_rect()),"unit action is fully visible")
		await capture("battle-preparation-ally-%dx%d" % [resolution.x,resolution.y])
	await helpers.click(hub,editor.apply_button)
	var changed: Dictionary = editor.unit_at(0,ally_slot)
	verify(changed.content_id == "inventor" and changed.role == Model.Content.role_index("inventor"),"replacement uses actual combat character identity")
	verify(changed.max_hp == 5321 and changed.atk == 83 and changed.def == 19 and is_equal_approx(changed.interval,0.8) and changed.attack_range == 4 and changed.move_speed == 3,"all six ally attributes apply")
	verify(changed.skill == Model.Content.character(changed.role).skill and changed.portrait == Model.Content.character(changed.role).portrait,"replacement uses original skills and portrait")
	verify(hub._deployment_definition(anchor_role).id == "inventor" and hub._inspection_unit(anchor_role).content_id == "inventor","original deployment card and ghost follow replacement")
	verify(hub.run.to_dict() == build and hub.phase == "prepare","ally identity edits are transient and do not auto start")
	var ally_empty: int = hub.formation.find(-1)
	await drag(0,ally_slot,hub._slot_rect(0,ally_empty).get_center())
	verify(editor.unit_at(0,ally_slot).is_empty() and editor.unit_at(0,ally_empty).content_id == "inventor" and editor.unit_at(0,ally_empty).max_hp == 5321,"ally drag follows ordinary deployment and retains overrides")
	verify(hub.formation[ally_empty] == anchor_role and hub.run.formation == hub.formation,"ordinary deployment synchronizes original formation")
	var valid: Dictionary = Model.snapshot(hub)
	for bad in ["unknown","nan","duplicate"]:
		var invalid: Dictionary = valid.duplicate(true)
		var anchor: String = Model.Content.role_id(anchor_role)
		if bad == "unknown": invalid.allies[anchor].id = "missing_character"
		elif bad == "nan": invalid.allies[anchor].stats.def = NAN
		else: invalid.allies[anchor].id = hub.units.filter(func(unit): return unit.side == 0 and unit.slot != ally_empty)[0].content_id
		verify(Model.apply(hub,invalid) != "" and hub.debug_battle_tuning == valid,"invalid ally "+bad+" is rejected")
	before = roster()
	await click_unit(0,ally_empty)
	editor.stat_fields.atk.value = 999
	await key(KEY_ESCAPE)
	verify(not hub.paused and not editor.panel.visible and roster() == before,"Escape discards quick draft and restores pause")
	# Cancel preserves a separate manually paused state, with no open pause menu.
	hub.paused = true
	await click_unit(1,empty)
	await key(KEY_ESCAPE)
	verify(hub.paused and not editor.panel.visible,"cancel preserves preexisting manual pause")
	hub.paused = false
	await click_unit(1,empty)
	await key(KEY_F8)
	verify(hub.debug_panel.panel.visible and hub.paused and not editor.panel.visible,"F8 switches modal without retaining quick editor pause")
	await helpers.click(hub,hub.debug_panel.tuning_button)
	var full = hub.debug_panel.tuning_editor
	helpers.choose(full.background_selector,"lab")
	await helpers.click(hub,full.apply_button)
	verify(hub.phase == "prepare" and hub.elapsed == 0 and not hub.paused and hub.battle_background == load(Model.BACKGROUNDS.lab.path),"full editor applies background without starting preparation")
	await mouse(hub._action_rect(0).get_center(),true)
	await mouse(hub._action_rect(0).get_center(),false)
	verify(hub.phase == "battle" and hub.elapsed == 0,"actual original Start control enters combat only on request")
	hub._process(0.5)
	verify(hub.elapsed > 0 and hub.simulation.units == hub.units,"original simulation runs modified roster")
	verify(hub.units.filter(func(unit): return unit.side == 1).all(func(unit): return not unit.presentation.facing_right),"enemies keep left-facing presentation during combat")
	await click_unit(1,empty)
	var elapsed: float = hub.elapsed
	hub._process(1)
	verify(hub.elapsed == elapsed,"quick menu freezes live simulation")
	editor.stat_fields.atk.value = 78
	var save_path: String = hub.progress.path
	var previous: Dictionary = hub.debug_battle_tuning.duplicate(true)
	hub.progress.path = "res://.godot/missing-battle-preparation-directory/profile.json"
	await helpers.click(hub,editor.apply_button)
	verify(editor.panel.visible and hub.paused and hub.debug_battle_tuning == previous,"failed checkpoint keeps old config and editable paused menu")
	hub.progress.path = save_path
	await helpers.click(hub,editor.apply_button)
	verify(hub.phase == "prepare" and hub.elapsed == 0 and editor.unit_at(1,empty).atk == 78,"live edit restarts through original checkpoint into preparation")
	verify(hub.units.all(func(unit): return unit.hp == unit.max_hp and unit.damage == 0),"live edit resets health and statistics")
	verify(hub.simulation.units == hub.units,"simulation shares actual initialized units")
	var saved_text: String = JSON.stringify(hub.progress.active_run)
	verify(not saved_text.contains("debug_battle_tuning") and not saved_text.contains("5321"),"temporary identities and stats stay out of ordinary checkpoint")
	await capture("battle-preparation-final")
	verify((Model.Content.MANIFEST.characters+Model.Content.MANIFEST.enemies).map(func(definition): return [definition.id,definition.health,definition.attack,definition.defense,definition.interval]) == resources,"registered resources remain unchanged")
	for index in profiles.size():
		var current: PackedByteArray = FileAccess.get_file_as_bytes(profiles[index]) if FileAccess.file_exists(profiles[index]) else PackedByteArray()
		verify(current == bytes[index],"player profile bytes unchanged")
	finish()

func finish() -> void:
	print("BATTLE_PREPARATION_CHECK %d checks / %d failures" % [checks,failures])
	hub.get_tree().quit(1 if failures else 0)
