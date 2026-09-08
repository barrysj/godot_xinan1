extends RefCounted
const DB = preload("res://game/content/content_db.gd")

func run_checks(hub) -> void:
	assert(DB.validate().is_empty(), str(DB.validate()))
	hub._new_run()
	hub.run.generate(1)
	hub.run.choose(0)
	hub.run.reward_ids = ["ribbon", "guard_training", "archer_training"]
	hub.run.reward_snapshots = hub.run.reward_ids.map(func(id): return hub.run.Rewards.find(id))
	assert(hub.run.take_reward("ribbon"))
	assert(not hub.run.take_reward("ribbon"))
	hub.run.complete_node()
	hub._open_team_panel()
	var panel = hub.team_panel
	panel.select_role(1)
	panel.select_tab(1)
	panel.open_bag()
	panel.bag_buttons.ribbon.pressed.emit()
	assert(hub.run.worn_gear(1) == "ribbon")
	for unit in hub.units:
		if unit.side == 0 and unit.role == 1: assert(unit.atk == 43 and unit.max_hp == 195)
	var restored = hub.Checkpoint.decode(hub.progress.active_run)
	assert(not restored.is_empty() and restored.run.worn_gear(1) == "ribbon")
	var broken = hub.run.to_dict()
	broken.inventory.missing_content = -1
	var before = hub.run.to_dict()
	assert(not hub.run.restore(broken) and hub.run.to_dict() == before)
	var legacy_model = hub.RunModel.new()
	legacy_model.generate(1)
	legacy_model.stages = hub.RunModel.generated_stages(1)
	var legacy = legacy_model._legacy_dict()
	legacy.schema = legacy.legacy_schema
	legacy.erase("inventory")
	var old = hub.RunModel.new()
	assert(old.restore(legacy) and old.inventory == {"shoe":0})
	var entries = preload("res://game/codex/codex_catalog.gd").entries(2)
	assert(entries.any(func(entry): return entry.name == "晨光发带"))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/content-equipment.png")
	print("CONTENT_CHECK equipment reward, UI equip, combat stats, checkpoint, legacy migration, rejection rollback and codex passed")
	panel.close_popup()
	panel.close_panel()
	await hub.get_tree().process_frame
	var role = DB.role_index("morning")
	hub.run.roster.append(role)
	hub.formation[2] = role
	hub.selected = role
	hub._sync_team()
	hub.run.stages = hub.RunModel.STAGES.duplicate(true)
	hub.chosen_node = 1
	hub._enter_node()
	hub._start()
	var freshman = {}
	var archer = {}
	for unit in hub.units:
		if unit.side == 0 and unit.role == role: freshman = unit
		if unit.side == 0 and unit.role == 1: archer = unit
	assert(freshman.skill == archer.skill)
	freshman.hp -= 10
	freshman.count = 2
	freshman.timer = 0
	var archer_count = archer.count
	hub._tick()
	assert(archer.count == archer_count and freshman.count == 0 and DB.character(role).health == 190)
	assert(freshman.damage > 0)
	hub._checkpoint()
	var saved = hub.run.to_dict()
	assert(saved.roster.has("morning") and saved.formation.has("morning"))
	var clone = hub.RunModel.new()
	assert(clone.restore(JSON.parse_string(JSON.stringify(saved))))
	assert(clone.roster.has(role) and clone.formation.has(role))
	hub.paused = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/content-character.png")
	print("CONTENT_CHECK resource character, shared skill, isolated state, string identity and combat passed")
	# Pick a real generated route containing the new event; no synthetic node insertion.
	hub._new_run()
	var event_layer = -1
	var event_index = -1
	for seed_value in range(100):
		hub.run.generate(seed_value)
		for layer in range(1,4):
			for index in range(hub.run.stages[layer].size()):
				if hub.run.stages[layer][index].id == "reading":
					event_layer = layer
					event_index = index
		if event_layer >= 0: break
	assert(event_layer >= 0)
	for layer in range(event_layer):
		hub.run.choose(0)
		hub.run.complete_node()
	hub.chosen_node = event_index
	hub._enter_node()
	assert(hub.screen == "event")
	var event_save = hub.run.to_dict()
	var zero = hub.RunModel.new()
	assert(zero.restore(event_save))
	zero.points = 0
	assert(not zero.event_option_available(0) and not zero.take_event(0))
	assert(zero.event_option_available(1))
	var second = hub.RunModel.new()
	assert(second.restore(event_save) and second.take_event(1))
	assert(second.training[1] == 1 and not second.take_event(1))
	var restored_second = hub.RunModel.new()
	assert(restored_second.restore(JSON.parse_string(JSON.stringify(second.to_dict()))))
	assert(restored_second.event_done and not restored_second.take_event(1))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/content-event.png")
	var points_before = hub.run.points
	hub._test_click(Vector2(400,359))
	assert(hub.screen == "map" and hub.run.inventory.has("ribbon") and hub.run.points == points_before)
	# Node completion grants one point; exchange spends one, so the net total is unchanged.
	var after = hub.run.to_dict()
	hub._test_click(Vector2(400,359))
	assert(after == hub.run.to_dict())
	var disk = hub.ProgressModel.new()
	disk.path = hub.progress.path
	assert(disk.read_save())
	var resumed = hub.Checkpoint.decode(disk.active_run)
	assert(not resumed.is_empty() and resumed.run.inventory.has("ribbon") and resumed.run.points == points_before)
	var frozen = hub.RunModel.new()
	frozen.generate(4)
	frozen.choose(0)
	var frozen_save = JSON.parse_string(JSON.stringify(frozen.to_dict()))
	var first_reward = DB.MANIFEST.rewards[0]
	var old_name = first_reward.display_name
	first_reward.display_name = "改名验证"
	DB.MANIFEST.locations.reverse()
	DB.MANIFEST.reward_pools[0].rewards.reverse()
	DB.MANIFEST.characters.reverse()
	var frozen_clone = hub.RunModel.new()
	assert(frozen_clone.restore(frozen_save))
	assert(frozen_clone.stages == frozen.stages and frozen_clone.offers() == frozen.offers())
	DB.MANIFEST.characters.reverse()
	DB.MANIFEST.reward_pools[0].rewards.reverse()
	DB.MANIFEST.locations.reverse()
	first_reward.display_name = old_name
	var missing = frozen_save.duplicate(true)
	missing.stages[0][0].id = "removed_location"
	assert(not frozen_clone.restore(missing))
	print("CONTENT_CHECK conditional event, atomic grants, one-time payment, disk reload, frozen route/rewards and removed references passed")
	hub.get_tree().quit()

