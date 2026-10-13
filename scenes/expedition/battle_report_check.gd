extends Node
## Actual report UI and existing checkpoint/reward flows, in isolated profiles.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Model = preload("res://game/debug/battle_tuning.gd")
const Report = preload("res://game/combat/battle_report.gd")
const LegacySave = preload("res://game/run/run_checkpoint.gd")
var hub
var checks := 0
var failures := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BATTLE_REPORT_UI_CHECK: "+label)

func frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	await frames()

func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await frames()
	await RenderingServer.frame_post_draw
	verify(get_viewport().get_texture().get_image().save_png("res://.godot/battle-report-"+name+".png") == OK,"actual report screenshot saved")

func _ready() -> void:
	var profiles := ["user://campus_progress.json","user://campus_debug_progress.json"]
	var originals: Array = profiles.map(func(path): return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
	hub = Campaign.instantiate()
	add_child(hub)
	hub.set_process(false)
	await frames()
	hub._begin_region("library","prologue","protect")
	hub._guard()
	if hub.debug_battle_preview:
		var settings: Dictionary = Model.snapshot(hub)
		settings.enabled = true
		settings.ally_health = 5.0
		for enemy in settings.enemies:
			enemy.id = "radio"
			enemy.stats = Model.default_stats(hub,"radio")
			enemy.stats.max_hp = 180
			enemy.stats.atk = 18
			enemy.stats.interval = 1.5
		verify(Model.apply(hub,settings,true) == "","six-enemy trial uses original battle modifier")
	hub._start()
	for step in 2400:
		if hub.screen == "report": break
		if hub.phase == "battle" and not hub.simulation.closing:
			for id in hub.simulation.loadout:
				if hub.simulation.program_error(id).is_empty(): hub.simulation.cast_program(id)
		hub._process(0.05)
	await frames()
	verify(hub.screen == "report" and hub.result_won,"original natural battle reaches victory report")
	if hub.screen != "report" or hub.report_details.is_empty():
		print("BATTLE_REPORT_UI_CHECK %d checks / %d failures" % [checks,failures])
		get_tree().quit(1)
		return
	verify(Report.valid_snapshot(hub.report_details),"full terminal report validates")
	verify(hub.report_details.rows.size() == hub.units.size(),"all units on both sides have exactly one record")
	var saved: Dictionary = hub.report_details.duplicate(true)
	var view = hub.report_view
	verify(view.is_visible_in_tree() and not hub.battle_actor_layer.visible,"shared statistics replace original battle visuals")
	verify(view.rows.size() == 4 and view.table.get_root().get_child_count() == 4,"default table shows original four allies")
	verify(view.milestones.text.contains("首次核心") and saved.first_core >= 0,"first core uses an actual successful program cast")
	verify(saved.program_uses.get("redirect",0) > 0,"actual program counts are visible")
	verify(hub.units.filter(func(unit): return unit.side == 0).all(func(unit): return unit.hp == unit.max_hp),"original full recovery still applies")
	verify(saved.rows.any(func(row): return row.side == 0 and row.hp < row.max_hp),"terminal life freezes before victory full recovery")
	for side in [0,1]:
		var dealt: float = saved.program_damage if side == 0 else 0.0
		var received := 0.0
		for row in saved.rows:
			if row.side == side: dealt += row.damage
			else: received += row.received
		verify(is_equal_approx(dealt,received),"team effective damage equals opposing HP damage")
	verify(saved.rows.any(func(row): return row.absorbed > 0),"report retains real absorption")
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		if DisplayServer.get_name() != "headless": get_window().size = resolution
		await frames()
		var panel := Rect2(view.canvas.global_position+Vector2(80,127)*view.canvas.scale,Vector2(1115,422)*view.canvas.scale)
		for control in [view.table,view.tabs,view.detail,view.resource_grid,view.milestones.get_parent(),view.note]:
			verify(panel.grow(2).encloses(control.get_global_rect()),"statistics fit original paper panel: "+str(control.get_class()))
		verify(view.tabs.get_tab_rect(1).end.x <= view.tabs.size.x,"both side tabs fit without collapsed arrows")
		await capture(("preview" if hub.debug_battle_preview else "main")+"-%dx%d" % [resolution.x,resolution.y])
	# Real mouse selection and keyboard tab navigation.
	var tab_rect: Rect2 = view.tabs.get_tab_rect(1)
	await click(view.tabs.global_position+tab_rect.get_center()*view.canvas.scale)
	verify(view.tabs.current_tab == 1 and view.rows.size() == hub.units.filter(func(unit): return unit.side == 1).size(),"actual enemy tab shows all enemy records")
	verify(view.table.get_root().get_first_child().get_text(0) != view.table.get_selected().get_text(0),"identical enemy kinds remain distinguishable by formation slot")
	var selected_rect := Rect2(view.table.global_position+view.table.get_item_area_rect(view.table.get_selected()).position*view.canvas.scale,view.table.get_item_area_rect(view.table.get_selected()).size*view.canvas.scale)
	verify(view.table.get_global_rect().encloses(selected_rect),"selected enemy row is fully visible")
	await capture("enemies")
	view.tabs.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_LEFT
	key.pressed = true
	get_viewport().push_input(key,true)
	await frames()
	verify(view.tabs.current_tab == 0,"keyboard can switch back to friendly statistics")
	var item: TreeItem = view.table.get_root().get_first_child().get_next()
	var item_rect: Rect2 = view.table.get_item_area_rect(item)
	await click(view.table.global_position+item_rect.get_center()*view.canvas.scale)
	verify(view.detail.text.begins_with(item.get_metadata(0).name) and view.detail.text.contains("普攻"),"actual row click shows life, survival and action detail")
	verify(hub._checkpoint(),"report persists through existing atomic checkpoint")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(hub.progress.active_run))
	verify(not hub.CampaignSave.decode(checkpoint).is_empty(),"JSON roundtrip keeps original campaign codec valid")
	hub._home()
	verify(not view.visible,"report UI hides at home")
	hub.progress.active_run = checkpoint
	hub._continue_run()
	await frames()
	verify(hub.screen == "report" and hub.report_details == JSON.parse_string(JSON.stringify(saved)),"Continue restores all statistics without replaying the fight")
	verify(view.rows.size() == 4 and view.title.text.contains(hub.run.node.name),"restored report updates shared controls")
	# The legacy run codec also accepts and retains the optional extension.
	var run = hub.RunModel.new()
	run.choose(0)
	var legacy_snapshot := {"schema":1,"run":run.to_dict(),"screen":"report","report":hub.report,"report_details":saved,"won":true,"elapsed":saved.duration,"selected":0,"seconds":0,"speed":1.0}
	var decoded: Dictionary = LegacySave.decode(JSON.parse_string(JSON.stringify(legacy_snapshot)))
	verify(not decoded.is_empty() and decoded.report_details == JSON.parse_string(JSON.stringify(saved)),"legacy run checkpoint preserves new statistics")
	legacy_snapshot.erase("report_details")
	verify(not LegacySave.decode(legacy_snapshot).is_empty(),"old legacy report remains readable")
	checkpoint.journey.erase("report_details")
	hub._home()
	hub.progress.active_run = checkpoint
	hub._continue_run()
	await frames()
	verify(view.snapshot.is_empty() and view.tabs.is_tab_disabled(1) and view.note.text.contains("未记录"),"old campaign report displays unknowns rather than invented zeroes")
	await capture("legacy")
	# Resume the current report and exercise the original terminal transition.
	checkpoint.journey.report_details = saved.duplicate(true)
	hub._home()
	hub.progress.active_run = checkpoint
	hub._continue_run()
	if hub.debug_battle_preview:
		hub._preview_result_action("retry")
		verify(hub.screen == "battle" and hub.phase == "prepare" and hub.report_details.is_empty() and not view.visible,"preview repeat clears old report and returns to preparation")
	else:
		hub._after_report()
		verify(hub.journey.data.screen == "reward" and not view.visible,"normal victory still reaches original campaign rewards")
	for index in profiles.size():
		var current: PackedByteArray = FileAccess.get_file_as_bytes(profiles[index]) if FileAccess.file_exists(profiles[index]) else PackedByteArray()
		verify(current == originals[index],"real player profile bytes unchanged")
	print("BATTLE_REPORT_UI_CHECK %d checks / %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
