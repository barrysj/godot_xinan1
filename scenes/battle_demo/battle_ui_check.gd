extends Node
var game: Control
var ui: Control
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _ready() -> void:
	call_deferred("run_checks")
func move(point: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = ui.canvas.get_global_transform() * point
	get_viewport().push_input(event, true)
	await get_tree().process_frame
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = ui.canvas.get_global_transform() * point
		get_viewport().push_input(event,true)
		await get_tree().process_frame
func button_point(button: Control) -> Vector2:
	return ui.canvas.get_global_transform().affine_inverse() * (button.get_global_transform() * (button.size / 2))
func run_checks() -> void:
	game = load("res://scenes/expedition/expedition.tscn").instantiate()
	add_child(game)
	game._new_run()
	game.run.generate(1)
	game._enter_node()
	game.formation = [0,-1,3,2,1,-1]
	game.run.grant_gear("badge")
	game._build_units()
	game.set_process(false)
	ui = game.inspector
	await get_tree().process_frame
	await get_tree().process_frame
	if "--battle-equipment-capture" in OS.get_cmdline_user_args():
		await capture_equipment_states()
		game.free()
		get_tree().quit(failures)
		return
	check(not ui.panel.visible, "No persistent character sidebar")
	for slot in 6:
		check(game._slot_rect(0,slot).end.x < 520 and game._slot_rect(1,slot).position.x > 740, "Left/right deployment with open center")
	var unit = game.units.filter(func(u): return u.side == 0 and u.role == 0)[0]
	var point: Vector2 = game._unit_center(unit) + Vector2(0,-35)
	await move(point)
	check(ui.panel.visible and not ui.pinned and not ui.description.visible, "Hover only shows summary")
	await click(point)
	check(ui.pinned and ui.description.visible and ui.gear_row.visible, "Click pins details and equipment slot")
	check(ui.panel.position.x >= 490 and ui.panel.position.x + ui.panel.size.x <= 790, "Details favor center lane")
	await click(button_point(ui.gear_button))
	check(ui.bag.visible and ui.bag_description.text.contains("篮球鞋"), "Equipment icon opens description and bag")
	await click(Vector2(40,170))
	check(not ui.bag.visible, "Clicking the equipment backdrop closes the bag")
	await click(button_point(ui.gear_button))
	check(ui.bag.visible, "Equipment bag can reopen after backdrop dismissal")
	ui.picked_item = "badge"
	ui._refresh_bag()
	await get_tree().process_frame
	await click(button_point(ui.equip_button))
	check(game.run.worn_gear(0) == "badge" and game.equipment == -1 and not ui.bag.visible,
		"Replacing equipment returns old item to bag and closes the popup")
	var restored = game.Checkpoint.decode(game.progress.active_run)
	check(not restored.is_empty() and restored.run.worn_gear(0) == "badge", "Equipment persists through existing checkpoint")
	ui.close_bag()
	ui.show_unit(game.units.filter(func(u): return u.side == 0 and u.role == 1)[0],true)
	ui.open_bag()
	ui.picked_item = "badge"
	ui._refresh_bag()
	check(ui.bag_description.text.contains("守护者") and ui.equip_button.text == "转移", "Transfer explains current owner")
	ui.exchange()
	check(game.run.worn_gear(1) == "badge" and game.run.worn_gear(0) == "empty" and not ui.bag.visible,
		"Transfer has a single owner and closes the popup")
	game.phase = "battle"
	ui.open_bag()
	ui._refresh_bag()
	ui._process(0)
	check(ui.bag.visible, "Combat equipment description remains available as read-only")
	check(ui.equip_button.disabled and not game._equip_item("shoe",1), "Combat locks equipment mutation")
	game.phase = "prepare"
	ui.close_bag()
	ui.close_info()
	await move(Vector2(630,570))
	check(not ui.panel.visible, "Moving to blank space hides hover")
	if "--battle-ui-capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			get_window().size = resolution
			await get_tree().process_frame
			for location_id in ["gate", "lab", "classroom"]:
				var place = game.Content.MANIFEST.locations.filter(func(p): return p.id == location_id)[0]
				game.run.node = place.snapshot()
				game._build_units()
				check(game.battle_background == place.battle_background, "Location selects its authored background")
				ui.show_unit(game.units.filter(func(u): return u.side == 0 and u.role == 0)[0],true)
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var image = get_viewport().get_texture().get_image()
				check(image.get_size() == resolution, "Capture has requested resolution")
				image.save_png("res://.godot/battle-background-%s-%dx%d.png" % [location_id,resolution.x,resolution.y])
				image.save_png("res://.godot/battle-wide-%dx%d.png" % [resolution.x,resolution.y])
				print("BACKGROUND_CAPTURE ",location_id," ",resolution)
			ui.open_bag()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/battle-bag-%dx%d.png" % [resolution.x,resolution.y])
			ui.close_bag()
			ui.close_info()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/battle-bag-dismissed-%dx%d.png" % [resolution.x,resolution.y])
	print("BATTLE_UI_CHECK failures=",failures)
	game.free()
	get_tree().quit(failures)

func capture_equipment_states() -> void:
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = resolution
		await get_tree().process_frame
		ui.show_unit(game.units.filter(func(u): return u.side == 0 and u.role == 0)[0],true)
		ui.open_bag()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/battle-bag-%dx%d.png" % [resolution.x,resolution.y])
		ui.close_bag()
		ui.close_info()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/battle-bag-dismissed-%dx%d.png" % [resolution.x,resolution.y])
		print("BATTLE_EQUIPMENT_CAPTURE ",resolution)
