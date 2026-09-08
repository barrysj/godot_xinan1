extends RefCounted
const DB = preload("res://game/content/content_db.gd")

func run_checks(hub) -> void:
	assert(DB.validate().is_empty(), str(DB.validate()))
	hub._new_run()
	hub.run.choose(0)
	hub.run.reward_ids = ["ribbon", "guard_training", "archer_training"]
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
	var legacy = hub.run._legacy_dict()
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
	hub.get_tree().quit()
