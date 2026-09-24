extends Node
## Uses the actual campaign scene; no parallel battle implementation.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Board = preload("res://scenes/battle_demo/battle_board.gd")
const Floor = preload("res://scenes/battle_demo/battle_floor.gd")
var failures := 0
var checks := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	for actor in [Vector2(3,3),Vector2(0,6),Vector2(6,0)]:
		for radius in [1.45,3.2]:
			var polygon := Floor.reach_polygon(actor,radius)
			for x in range(13):
				for y in range(13):
					var cell := Vector2(x,y)/2.0
					if absf(cell.distance_to(actor)-radius) < 0.01: continue
					verify(Geometry2D.is_point_in_polygon(Board.project(cell)+Vector2(0,13),polygon) == (cell.distance_to(actor)<radius),
						"projected range matches logical targeting, including field edges")
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/battlefield-visual-check.json"
	add_child(game)
	await get_tree().process_frame
	game.progress.path = "res://.godot/battlefield-visual-check.json"
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.run.node.encounter_id = "encounter_classroom"
	game.formation = [0,1,2,3,-1,-1]
	var roster: Array[int] = [0,1,2,3]
	game.run.roster = roster
	game._build_units()
	game.screen = "battle"
	game.inspector.set_process(false)
	game.inspector.observed = {}
	await get_tree().process_frame
	await get_tree().process_frame
	var before: Array = game.formation.duplicate()
	await drag(game,game._slot_rect(0,0).get_center(),game._slot_rect(0,4).get_center())
	verify(game.formation[4] == before[0] and game.formation[0] == -1,"real mouse drag onto new tactical pad")
	await drag(game,game._slot_rect(0,4).get_center(),game._slot_rect(0,0).get_center())
	verify(game.formation == before,"real mouse drag returns formation without changing roster")
	if "--capture" in OS.get_cmdline_user_args():
		await capture(game,"prepare")
	game._start()
	for tick in range(55): game._tick()
	game.inspector.observed = game.units.filter(func(u): return u.side == 0 and u.content_id == "archer")[0]
	game.paused = true
	if "--capture" in OS.get_cmdline_user_args():
		await capture(game,"range")
	verify(game.units.filter(func(u): return u.side == 1 and u.content_id == "chalk").size() == 2,"actual mainline includes chalk spirits")
	print("BATTLEFIELD_VISUAL_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture(game: Control, label: String) -> void:
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		verify(shot.get_size() == resolution,"actual screenshot resolution")
		shot.save_png("res://.godot/battlefield-%s-%dx%d.png" % [label,resolution.x,resolution.y])

func drag(game: Control, from: Vector2, to: Vector2) -> void:
	var transform: Transform2D = game.deployment.canvas.get_global_transform()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = transform * from
	get_viewport().push_input(down,true)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = transform * to
	get_viewport().push_input(motion,true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = transform * to
	get_viewport().push_input(up,true)
	await get_tree().process_frame
