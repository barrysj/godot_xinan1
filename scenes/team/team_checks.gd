extends RefCounted
func run_checks(hub) -> void:
	hub._new_run()
	hub.run.badge_owned = true
	hub.run.roster.append(4)
	hub._test_click(Vector2(835,50))
	assert(is_instance_valid(hub.team_panel) and hub.team_panel.editable)
	var panel = hub.team_panel
	panel.select_role(1)
	panel.select_tab(1)
	panel.equipment_slot.pressed.emit()
	panel.bag_buttons.badge.pressed.emit()
	assert(hub.run.badge_wearer == 1)
	panel.bag_buttons.shoe.pressed.emit()
	assert(hub.equipment == 1 and hub.run.badge_wearer == -1)
	panel.bag_buttons.remove.pressed.emit()
	panel.close_popup()
	assert(hub.equipment == -1)
	panel.select_role(4)
	panel.select_tab(0)
	panel.assign_slot(0)
	assert(hub.formation.has(4) and not hub.formation.has(0))
	panel.assign_slot(4)
	assert(hub.formation[4] == 4)
	var restored = hub.Checkpoint.decode(hub.progress.active_run)
	assert(not restored.is_empty() and restored.run.formation == hub.formation and restored.run.shoe_wearer == -1)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/team_status.png")
	panel.select_role(1)
	panel.select_tab(1)
	panel.equipment_slot.pressed.emit()
	panel.bag_buttons.badge.pressed.emit()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/team_equipment.png")
	panel.close_popup()
	panel.close_panel()
	await hub.get_tree().process_frame
	assert(not hub.paused)
	hub._enter_node()
	hub._start()
	hub._process(0.5)
	hub._open_team_panel()
	panel = hub.team_panel
	assert(not panel.editable)
	var before = [hub.elapsed,hub.units.duplicate(true),hub.formation.duplicate(),hub.equipment]
	panel.equip("shoe")
	panel.assign_slot(0)
	hub._process(5)
	assert(before == [hub.elapsed,hub.units,hub.formation,hub.equipment])
	panel.select_tab(2)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/team_skills.png")
	var escape = InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	Input.parse_input_event(escape)
	await hub.get_tree().process_frame
	assert(not is_instance_valid(hub.team_panel) and not hub.paused)
	hub._process(0.1)
	assert(hub.elapsed > before[0])
	print("TEAM_CHECK map/battle entry, gear exclusivity, unequip, reserve swap, formation persistence, battle read-only, freeze and Esc resume passed")
	hub.get_tree().quit()
