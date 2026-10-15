extends Control
const Progress = preload("res://game/meta/campus_progress.gd")
var failures := 0

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("DISPATCH_FRAMEWORK: " + message)

func _ready() -> void:
	var version := get_node_or_null("/root/GGT_Transitions/Version") as Control
	if version != null: version.hide()
	var profile := Progress.new()
	profile.path = "res://.godot/dispatch-framework-profile.json"
	profile.campaign.prologue_done = true
	profile.points = 20
	verify(profile.execute_commission("departure","archivist"),"tutorial transaction")
	verify(profile.campaign.routes_acquired and profile.commission_unlocks.has("departure"),"tutorial unlocks preparation and routes together")
	verify(not profile.execute_commission("departure","archivist"),"no double grant")
	var restored := Progress.new()
	restored.path = profile.path
	verify(restored.read_save(),"load new schema")
	verify(not restored.pending_dispatch_result.is_empty(),"interruption retains unacknowledged result")
	verify(restored.acknowledge_dispatch_result(restored.pending_dispatch_result.id),"acknowledge persisted result")
	verify(restored.execute_commission("shield_kit","technician"),"all staff selectable without unlock or stat differences")
	verify(restored.points == 17,"one resource deduction")
	verify(not restored.execute_commission("shield_kit","liaison") and restored.points == 17,"no duplicate cost")
	verify(restored.acknowledge_dispatch_result(restored.pending_dispatch_result.id),"clear result")
	var before := restored.to_dict()
	restored.path = "res://.godot/nonexistent-dispatch-folder/profile.json"
	verify(not restored.execute_commission("revive_kit","archivist"),"write failure fails transaction")
	verify(restored.to_dict() == before,"failed write rolls back both cost and unlock")
	restored.path = profile.path
	verify(restored.Commissions.preparation_reason(restored.commission_unlocks,["shield","supply","converter"]).is_empty(),"valid point and slot budget")
	verify(not restored.Commissions.preparation_reason(restored.commission_unlocks,["shield","shield","supply"]).is_empty(),"point budget enforced")
	verify(not restored.Commissions.preparation_reason(restored.commission_unlocks,["supply","supply","supply","supply"]).is_empty(),"slot budget enforced")
	var old := profile.to_dict()
	old.version = 4
	old.erase("commission_unlocks")
	old.erase("pending_dispatch_result")
	old.upgrades = {"fitness":2,"supply":1}
	old.points = 2
	var file := FileAccess.open(profile.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	verify(restored.read_save() and restored.points == 15 and restored.level("fitness") == 0,"legacy numeric upgrades refunded")
	verify(restored.write_save() and restored.read_save() and restored.points == 15,"migration is not repeatable")
	# Editor changes retain reward identities and tolerate relocated pending results.
	var catalog = restored.Commissions
	var extra := {"id":"editor_shield","name":"测试器材","description":"测试", "cost":1,"location":"gym","requires":"departure","kind":"preparation","value":"shield"}
	catalog.COMMISSIONS.append(extra)
	verify(catalog.preparation_reason(["departure","editor_shield"],["shield"]).is_empty(),"new editor commission unlocks supported preparation")
	extra.enabled = false
	verify(not catalog.at_location("gym").has(extra),"disabled commission disappears from board")
	verify(not restored.commission_reason("editor_shield","archivist").is_empty(),"disabled commission cannot be executed")
	catalog.COMMISSIONS.erase(extra)
	var pending_profile := Progress.new()
	pending_profile.path = "res://.godot/dispatch-editor-pending.json"
	pending_profile.campaign.prologue_done = true
	pending_profile.points = 20
	verify(pending_profile.execute_commission("departure","archivist"),"editor compatibility tutorial")
	pending_profile.acknowledge_dispatch_result(pending_profile.pending_dispatch_result.id)
	verify(pending_profile.execute_commission("shield_kit","archivist"),"editor compatibility pending result")
	var moved: Dictionary = catalog.find("shield_kit")
	var original_location: String = moved.location
	moved.location = "chunxi"
	verify(pending_profile.read_save(),"relocating a commission preserves pending save")
	moved.location = original_location
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1920,1080)
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--capture-size="):
				var dimensions := argument.trim_prefix("--capture-size=").split("x")
				get_window().size = Vector2i(int(dimensions[0]),int(dimensions[1]))
		var board := preload("res://scenes/expedition/dispatch_board.gd").new()
		board.progress = restored
		add_child(board)
		await get_tree().process_frame
		await get_tree().process_frame
		verify(is_equal_approx(board.campus_image.size.aspect(),board.CAMPUS.get_size().aspect()),"campus map preserves artwork aspect")
		verify(board.selected_staff.is_empty(),"personnel starts as empty slot")
		await capture("dispatch-empty-slot")
		var points_before: int = restored.points
		board.execute("field_supplies")
		verify(restored.points == points_before and not board.busy,"empty slot cannot dispatch")
		await click(board.staff_slot)
		verify(is_instance_valid(board.staff_picker),"slot click opens personnel list")
		await capture("dispatch-staff-picker")
		var picker_zoom: float = board.map_zoom
		wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
		verify(board.map_zoom == picker_zoom,"picker blocks underlying map")
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		get_viewport().push_input(cancel,true)
		await get_tree().process_frame
		verify(not is_instance_valid(board.staff_picker) and board.selected_staff.is_empty(),"escape cancels empty picker")
		for person in board.Staff.STAFF:
			await click(board.staff_slot)
			var chosen: Button
			for control in board.staff_picker.find_children("*","Button",true,false):
				if control.get_meta("staff","") == person.id: chosen = control
			await click(chosen)
			await get_tree().process_frame
			verify(board.selected_staff == person.id and not is_instance_valid(board.staff_picker),"select replaces empty slot with chosen portrait")
		await get_tree().create_timer(0.2).timeout
		verify(board.staff_slot.modulate == Color.WHITE,"selection feedback returns to rest")
		var previous: String = board.selected_staff
		await click(board.staff_slot)
		get_viewport().push_input(cancel,true)
		await get_tree().process_frame
		verify(board.selected_staff == previous and restored.points == points_before,"cancel replacement preserves selection and resources")
		await capture("dispatch-campus")
		verify(not board.city_image.visible,"city imagery does not bleed behind campus")
		var original_zoom: float = board.map_zoom
		wheel(board.side_panel.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
		verify(board.map_zoom == original_zoom,"scrolling details does not zoom map")
		wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
		verify(board.map_zoom < 1.0 and not board.outside and not board.busy,"one wheel step shrinks campus without immediate switching")
		wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
		wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
		await get_tree().create_timer(0.30).timeout
		verify(board.busy and board.campus_image.scale.x < 1.0 and board.campus_image.scale.x > 0.1,"campus actually shrinks during transition")
		await get_tree().create_timer(0.70).timeout
		await capture("dispatch-city")
		for pin in board.pins:
			if not pin.visible: continue
			var entry: Dictionary = board.PLACES[board.pins.find(pin)]
			var marker: Vector2 = board._map_rect().position + board._map_rect().size*entry.point
			verify(not pin.get_rect().has_point(marker),"leader line has a distinct geographic endpoint")
		for step in 3: wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_UP)
		await get_tree().create_timer(1.0).timeout
		verify(not board.outside,"continuous zoom returns to campus")
		var center: Vector2 = board.map.get_global_rect().get_center()
		touch(0,center-Vector2(180,0),true)
		touch(1,center+Vector2(180,0),true)
		var pinch := InputEventScreenDrag.new()
		pinch.index = 1
		pinch.position = center+Vector2(30,0)
		get_viewport().push_input(pinch,true)
		touch(0,center-Vector2(180,0),false)
		touch(1,pinch.position,false)
		await get_tree().create_timer(1.0).timeout
		verify(board.outside and board.touches.is_empty(),"two-finger pinch switches maps and releases contacts")
		board.execute("revive_kit")
		var paid: int = restored.points
		board.execute("field_supplies")
		verify(board.busy and restored.points == paid,"animation blocks repeat dispatch")
		await get_tree().create_timer(1.0).timeout
		verify(board.travel_marker.visible and board.travel_figure.texture != null,"travel uses generated staff portrait")
		await capture("dispatch-travel")
		await get_tree().create_timer(2.0).timeout
		verify(is_instance_valid(board.result_layer),"travel ends in settlement window")
		verify(board.navigation.get_children().filter(func(child): return child is Button).all(func(button): return button.disabled),"settlement locks background controls")
		await capture("dispatch-result")
		var result_zoom: float = board.map_zoom
		wheel(board.map.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_UP)
		verify(board.map_zoom == result_zoom and board.outside,"settlement blocks map gestures")
		board.queue_free()
		await get_tree().process_frame
		var hub := preload("res://scenes/expedition/expedition.tscn").instantiate()
		hub.progress.path = "res://.godot/dispatch-framework-hub.json"
		hub.progress.write_save()
		add_child(hub)
		await get_tree().process_frame
		verify(hub.campaign_enabled,"original campaign integration enabled")
		var whiteboard: Button = hub.campaign_panel.home_root.find_child("DispatchWhiteboard",true,false)
		verify(whiteboard != null,"base board entrance exists")
		await get_tree().process_frame
		if whiteboard != null: await click(whiteboard)
		verify(is_instance_valid(hub.dispatch_board),"base board opens shared dispatch UI")
		await capture("dispatch-base-entry")
		if is_instance_valid(hub.dispatch_board): hub.dispatch_board.closed.emit()
		await get_tree().process_frame
		var icon: Button = hub.campaign_panel.action_button("dispatch")
		verify(icon != null,"dispatch icon exists independently of scene board")
		if icon != null: await click(icon)
		verify(is_instance_valid(hub.dispatch_board),"actual icon click opens same UI")
	print("DISPATCH_FRAMEWORK failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://.godot/%s-%dx%d.png" % [id,image.get_width(),image.get_height()])

func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
	await get_tree().process_frame

func wheel(at: Vector2, direction: int) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = direction
	event.pressed = true
	get_viewport().push_input(event,true)

func touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	get_viewport().push_input(event,true)
