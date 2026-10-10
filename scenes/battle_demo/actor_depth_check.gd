extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var size := get_window().size
	get_viewport().get_texture().get_image().save_png("res://.godot/actor-depth-%s-%dx%d.png" % [label,size.x,size.y])
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/actor-depth-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game._start()
	game.paused = true
	var hybrid: Dictionary = game.units.filter(func(u): return u.content_id == "desk")[0]
	var fallback: Dictionary = game.units.filter(func(u): return u.content_id == "radio")[0]
	verify(game.battle_actor_views.size() == game.units.size(), "Every actor shares the depth group, including frame-only units")
	verify(game.battle_actor_layer.y_sort_enabled, "Unified depth group enables Y sorting")
	verify(game.battle_presentations.has(hybrid.id) and not game.battle_presentations.has(fallback.id), "Check mixes a real hybrid rig with a real frame-only enemy")
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		for front in [fallback,hybrid]:
			hybrid.position = Vector2(3,2)
			fallback.position = Vector2(3,2)
			front.position.x += 0.28
			for u in [hybrid,fallback]: u.previous_position = u.position
			game._update_battle_presentations()
			for u in game.units:
				if u.id not in [hybrid.id,fallback.id]: game.battle_actor_views[u.id].hide()
			var view: Node2D = game.battle_actor_views[front.id]
			var back: Node2D = game.battle_actor_views[hybrid.id if front.id == fallback.id else fallback.id]
			verify(view.get_parent() == back.get_parent() and view.position.y > back.position.y, "Front depth follows projected ground position")
			verify(view.z_index == back.z_index and view.z_index == 0, "Animation type cannot override depth or HUD stacking")
			var ground: Vector2 = view.position
			front.presentation.hurt_age = 0.05
			front.presentation.hurt_direction = Vector2(0,1)
			game._update_battle_presentations()
			verify(view.position == ground, "Recoil cannot change ground-contact sorting")
			front.presentation.hurt_age = 1
			await capture("frames-front" if front.id == fallback.id else "hybrid-front")
		game._update_battle_presentations()
	game.screen = "report"
	verify(not game.battle_actor_layer.visible, "Unified actors still disappear at report boundary")
	print("ACTOR_DEPTH_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
