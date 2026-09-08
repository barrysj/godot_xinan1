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
	var legacy = hub.run.to_dict()
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
	hub.get_tree().quit()
