extends "res://scenes/expedition/meta_hub.gd"
## F6 运行此场景。使用独立内存档案，预览不写入用户存档。
@export_group("内容预览")
@export var preview_character: CampusUnit
@export var preview_equipment: CampusEquipment
@export var preview_location: CampusLocation
@export_enum("battle", "equipment", "event") var preview_mode: String = "battle"

func _ready() -> void:
	super._ready()
	if not storage_ready: return
	_new_run()
	var role = Content.role_index(preview_character.id) if preview_character != null else 1
	if role < 0:
		push_error("预览人物尚未加入 manifest.characters")
		return
	if not run.roster.has(role): run.roster.append(role)
	if not formation.has(role): formation[2] = role
	selected = role
	if preview_equipment != null:
		run.grant_gear(preview_equipment.id)
		run.equip_gear(preview_equipment.id,role)
		equipment = run.shoe_wearer
	_sync_team_data()
	if preview_mode == "equipment":
		_open_team_panel()
		team_panel.select_tab(1)
		team_panel.open_bag()
	else:
		var place = preview_location
		if place == null:
			place = load("res://resources/content/locations/reading.tres" if preview_mode == "event" else "res://resources/content/locations/gate.tres")
		var layer_index = -1
		for layer in range(run.stages.size()):
			for index in range(run.stages[layer].size()):
				if run.stages[layer][index].id == place.id:
					layer_index = layer
					chosen_node = index
		if layer_index < 0:
			layer_index = 1
			chosen_node = 0
			run.stages[1][0] = place.snapshot()
		for layer in range(layer_index):
			run.choose(0)
			run.complete_node()
		_enter_node()
		if screen == "battle": _start()
	notice = "内容预览：关闭后丢弃，实际探索存档不受影响。"
	if "--preview-capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/content-preview.png")
		print("CONTENT_PREVIEW loaded inspector resources and captured runtime")
		get_tree().quit()

func _checkpoint() -> bool:
	return true

func _settle() -> void:
	screen = "summary"
	run.settled = true
