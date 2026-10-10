extends Node
const Content = preload("res://game/content/content_db.gd")
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const ROLES = ["guard", "archer", "healer", "striker", "inventor"]
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	var models := 0
	for unit in Content.characters():
		if not unit.id in ROLES: continue
		var model = unit.battle_animation
		check(model != null, unit.id + " has the approved animation")
		if model == null: continue
		models += 1
		var prefix: String = "res://assets/art/characters/" + unit.id + "/"
		check(model.resource_path == prefix + "battle_animation.tres", unit.id + " uses the formal package")
		check(unit.portrait is AtlasTexture and unit.portrait.atlas.resource_path.begins_with(prefix + "frames/"), unit.id + " portrait uses the new identity")
		var attack: StringName = &"ranged" if unit.resolved_attack_modes() == 2 else &"melee"
		var canvas := Vector2(1024, 896) if unit.id == "guard" else Vector2(1536, 1024)
		for clip in [&"idle", &"move", attack, &"cast", &"hurt", &"critical", &"death"]:
			check(model.frames.has_animation(clip), unit.id + " has " + clip)
			if not model.frames.has_animation(clip): continue
			check(model.frames.get_frame_count(clip) > 0, unit.id + " nonempty " + clip)
			for index in model.frames.get_frame_count(clip):
				var frame = model.frames.get_frame_texture(clip, index)
				check(frame != null and frame.get_size() == canvas, unit.id + " consistent canvas")
				check(frame.resource_path.begins_with(prefix + "frames/"), unit.id + " frame uses the formal package")
		var idle = model.frames.get_frame_texture(&"idle", 0)
		var critical = model.frames.get_frame_texture(&"critical", 0)
		var death = model.frames.get_frame_texture(&"death", 0)
		check(idle.get_image().get_data() != critical.get_image().get_data(), unit.id + " critical is a different drawn pose")
		check(idle.get_image().get_data() != death.get_image().get_data(), unit.id + " death is a different drawn pose")
		check(critical.get_image().get_data() != death.get_image().get_data(), unit.id + " defeat poses are distinct")
		var animator = Animator.new(model, unit.resolved_attack_modes())
		animator.sync_health(10, 100)
		animator.sync_motion(false, {})
		check(animator.state == &"critical" and animator.texture() == critical, unit.id + " low health selects critical")
		animator.sync_health(0, 100)
		animator.sync_motion(false, {})
		animator.advance(5)
		var fallen = model.frames.get_frame_texture(&"death", model.frames.get_frame_count(&"death") - 1)
		check(animator.state == &"death" and animator.texture() == fallen, unit.id + " death holds the final fallen pose")
		check(model.presentation_scene == null and model.animation_library == null, unit.id + " uses the approved whole-body frame package")
		check(model.anchor.is_equal_approx(Vector2(0.5, 0.81808036) if unit.id == "guard" else Vector2(0.5, 0.715820312)), unit.id + " fixed foot anchor")
		print("AUTHORED_MODEL ", unit.id, " seven clips validated")
	check(models == ROLES.size(), "All five approved roles are integrated")
	if "--combat" in OS.get_cmdline_user_args():
		await check_combat()
	elif "--capture" in OS.get_cmdline_user_args():
		await capture_battle()
	print("AUTHORED_ASSETS_CHECK models=", models, " failures=", failures)
	get_tree().quit(failures)

func capture_battle() -> void:
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	# Two legal four-unit parties cover all five roles without bypassing deployment.
	for party in 2:
		for size in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1920, 1200)]:
			get_window().size = size
			battle.formation = [0, -1, 3 if party == 0 else 4, 2, 1, -1]
			battle._start()
			await get_tree().create_timer(1.0).timeout
			battle.paused = true
			check(battle.phase == "battle" and battle.units.filter(func(unit): return unit.side == 0).size() == 4, "Legal four-unit battle started")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := "res://.godot/characters-battle-party%d-%dx%d.png" % [party + 1, size.x, size.y]
			check(get_viewport().get_texture().get_image().save_png(path) == OK, "Saved actual battle " + str(size))

## Exercise the original campaign with normal stats and natural actions. No asset or HP overrides.
func check_combat() -> void:
	var before := checks
	var game = load("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "res://.godot/authored-combat-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	var hud = game.battle_status_layer
	var panel = game.code_panel
	hud.set_process(false)
	panel.set_process(false)
	panel.code_fx.set_process(false)
	var frames_seen := {}
	var recovered := {}
	var mismatches := {}
	for role in ROLES: frames_seen[role] = {"attack":{},"cast":{}}
	for party in 2:
		get_window().size = Vector2i(1920,1080) if party == 0 else Vector2i(1920,1200)
		game.run.node = {"id":"", "kind":"battle", "name":"联合验证", "encounter":0, "encounter_id":"encounter_classroom", "power":1.0}
		game.formation = [0,-1,3 if party == 0 else 4,2,1,-1]
		var roster: Array[int] = [0,1,2,3,4]
		game.run.roster = roster
		game.screen = "battle"
		game.phase = "prepare"
		game._start()
		game.speed = 1.0
		panel._process(0)
		hud._process(0)
		var previous := {}
		var paused_cast := false
		var captured_cast := false
		var captured_attack := false
		for frame in 3600:
			game._process(1.0/60)
			panel._process(1.0/60)
			hud._process(1.0/60)
			panel.code_fx._process(1.0/60)
			for actor in game.units:
				if actor.side != 0 or actor.hp <= 0: continue
				var role: String = actor.content_id
				var action: Dictionary = actor.action
				var casting: bool = action.get("casts",false)
				if previous.get(role,false) and not casting: recovered[role] = true
				previous[role] = casting
				if action.is_empty(): continue
				var timing: Dictionary = game.simulation.action_timing(actor.id)
				var expected: String = "cast" if casting else action.mode
				if actor.animation.state != StringName(expected) or (timing.kind == "cast") != casting:
					mismatches[role] = "animation=%s timing=%s action=%s" % [actor.animation.state,timing.kind,expected]
				var texture: Texture2D = actor.animation.texture()
				check_texture(role,texture,mismatches)
				if texture != null: frames_seen[role]["cast" if casting else "attack"][texture.resource_path] = true
				if casting and not action.released and action.age >= 0.25 and not paused_cast:
					var age: float = actor.animation.age
					var clock: float = game.simulation.elapsed+game.accumulator
					var progress: float = hud.action_progress(timing)
					game.paused = true
					game._process(0.5)
					hud._process(0.5)
					panel.code_fx._process(0.5)
					check(is_equal_approx(game.simulation.elapsed+game.accumulator,clock),"Pause freezes real cast clock")
					check(is_equal_approx(actor.animation.age,age) and actor.animation.texture() == texture,"Pause freezes authored pose")
					check(is_equal_approx(hud.action_progress(game.simulation.action_timing(actor.id)),progress),"Pause freezes the same unit's action strip")
					game.paused = false
					for speed in [0.5,2.0]:
						game.speed = speed
						clock = game.simulation.elapsed+game.accumulator
						age = actor.animation.age
						game._process(1.0/60)
						check(absf(game.simulation.elapsed+game.accumulator-clock-speed/60)<0.0001,"Speed advances the authoritative clock")
						check(actor.animation.age > age and actor.animation.state == &"cast","Speed advances the authored cast without resetting it")
					game.speed = 1.0
					paused_cast = true
				if not captured_attack and not casting and actor.animation.age > 0.15:
					await capture_combat(game,"party%d-attack" % (party+1))
					captured_attack = true
				var cast_role: String = "guard" if party == 0 else "inventor"
				if role == cast_role and casting and action.released and not captured_cast:
					await capture_combat(game,"party%d-cast" % (party+1))
					captured_cast = true
			if game.phase != "battle": break
		check(paused_cast,"Natural casts exercise pause and speed in party %d" % (party+1))
		check(captured_cast and captured_attack,"Both action phases reached naturally in party %d" % (party+1))
		check(game.simulation.finished,"Natural encounter completes in party %d" % (party+1))
		check(not game.battle_actor_layer.is_visible_in_tree() and not hud.visible,"Result hides authored actors and their HUD")
	check(mismatches.is_empty(),"Authored frames and the single action strip agree: "+str(mismatches))
	for role in ROLES:
		check(frames_seen[role].attack.size() >= 2,role+" naturally advances through different attack frames")
		check(frames_seen[role].cast.size() >= 2,role+" naturally advances through different cast frames")
		check(recovered.has(role),role+" naturally exits casting and resumes normal actions")
		print("AUTHORED_COMBAT_ROLE ",role," attack_frames=",frames_seen[role].attack.size()," cast_frames=",frames_seen[role].cast.size()," recovered=",recovered.has(role))
	print("AUTHORED_COMBAT_CHECK checks=%d parties=2 roles=5 failures=%d" % [checks-before,failures])
	game.free()

func check_texture(role: String, texture: Texture2D, mismatches: Dictionary) -> void:
	if texture == null or not texture.resource_path.begins_with("res://assets/art/characters/"+role+"/frames/"):
		mismatches[role] = "Natural action did not use the formal frame package"

func capture_combat(game, label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	game.paused = true
	game.code_panel._process(0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var size := get_window().size
	check(get_viewport().get_texture().get_image().save_png("res://.godot/authored-combat-%s-%dx%d.png" % [label,size.x,size.y]) == OK,"Saved combined animation/HUD "+label)
	game.paused = false
