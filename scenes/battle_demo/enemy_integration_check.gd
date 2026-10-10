extends Node
## Original campaign scene and registered encounters, with an isolated save.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Content = preload("res://game/content/content_db.gd")
const ENEMIES = ["radio", "pages", "desk", "board", "return_stamp", "great_volume", "cyber_librarian"]
var checks := 0
var failures := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _ready() -> void:
	verify(Content.validate().is_empty(), "Original content definitions remain valid")
	for enemy in Content.MANIFEST.enemies:
		if not enemy.id in ENEMIES: continue
		var model = enemy.battle_animation
		verify(model != null, enemy.id + " has an existing animation package")
		if model == null: continue
		verify(model.resource_path.begins_with("res://assets/art/characters/"), enemy.id + " uses a portable runtime path")
		verify(enemy.portrait is AtlasTexture and not "kenney" in enemy.portrait.atlas.resource_path, enemy.id + " shares its new portrait")
		var attack: StringName = &"ranged" if enemy.resolved_attack_modes() == 2 else &"melee"
		for clip in [&"idle", &"move", attack, &"cast", &"hurt", &"critical", &"death"]:
			verify(model.frames.has_animation(clip) and model.frames.get_frame_count(clip) > 0, enemy.id + " existing clip " + clip)
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/enemy-integration-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library", "prologue")
	game._guard()
	var seen := {}
	for encounter in ["patrol", "classroom", "final"]:
		for size in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
			get_window().size = size
			game.run.node.encounter_id = "encounter_" + encounter
			game.formation = [0, -1, 3, 2, 1, -1]
			game.screen = "battle"
			game._start()
			game.code_panel._process(0)
			if size == Vector2i(1920,1080):
				for actor in game.units:
					if actor.content_id not in ["return_stamp", "great_volume", "cyber_librarian"]: continue
					var due: Array[Dictionary] = []
					game.simulation._skill_events(actor, game.units[0], due)
					match actor.content_id:
						"return_stamp":
							verify(due.size() == 1 and due[0].kind == "shield" and due[0].target.id == actor.id and due[0].value == 50 and due[0].duration == 5, "Stamp keeps the existing self-shield skill")
						"great_volume":
							verify(due.size() == 1 and due[0].kind == "damage" and is_equal_approx(due[0].value, actor.atk * 1.3), "Melee book keeps the existing 130 percent skill")
						"cyber_librarian":
							verify(due.is_empty() and game.simulation.warning_next.get(actor.id) == 9.0, "Librarian uses timed warnings instead of attack-count casts")
			for frame in 450:
				game._process(1.0/60.0)
				for actor in game.units:
					if actor.side == 1 and actor.content_id in ENEMIES and actor.animation.state in [&"melee", &"ranged", &"cast"]:
						seen[actor.content_id] = true
			verify(game.units.filter(func(u): return u.side == 1).all(func(u): return u.animation.texture() != null), encounter + " all enemies render actual animation frames")
			if "--capture" in OS.get_cmdline_user_args():
				game.paused = true
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var picture := get_viewport().get_texture().get_image()
				verify(picture.get_size() == size, "Actual viewport size " + str(size))
				verify(picture.save_png("res://.godot/enemies-%s-%dx%d.png" % [encounter,size.x,size.y]) == OK, "Captured original campaign encounter")
			game.paused = false
	for id in ENEMIES: verify(seen.has(id), id + " actually played an attack in the original campaign")
	print("ENEMY_INTEGRATION_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
