extends Node
## Formal humanoid animation verification fixture. Uses the real campaign, simulation and animations.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Player2D = preload("res://scenes/battle_demo/battle_animation.gd")
const Content = preload("res://game/content/content_db.gd")
const SAMPLES = {
	0: "res://assets/art/characters/guard/",
	1: "res://assets/art/characters/archer/",
	2: "res://assets/art/characters/healer/",
	4: "res://assets/art/characters/inventor/"
}
const NAMES = {0: "guard", 1: "archer", 2: "healer", 4: "inventor"}
const REVIEW = "res://.godot/humanoid-gameplay/review/"
const CACHE = "res://.godot/humanoid-gameplay/"
const FPS = 30
var events: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("record")

func record() -> void:
	var size := Vector2i(1920, 1080)
	var stills_only := false
	var scan_only := false
	var power := 1.0
	var enemy_health_multiplier := 2.5
	var encounter := "encounter_final"
	var layout := 0
	var capture_fps := FPS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var parts := argument.trim_prefix("--size=").split("x")
			size = Vector2i(parts[0].to_int(), parts[1].to_int())
		elif argument == "--stills": stills_only = true
		elif argument == "--scan": scan_only = true
		elif argument.begins_with("--capture-fps="): capture_fps = argument.trim_prefix("--capture-fps=").to_int()
		elif argument.begins_with("--layout="): layout = argument.trim_prefix("--layout=").to_int()
		elif argument.begins_with("--power="):
			power = argument.trim_prefix("--power=").to_float()
		elif argument.begins_with("--enemy-health="):
			enemy_health_multiplier = argument.trim_prefix("--enemy-health=").to_float()
		elif argument.begins_with("--encounter="):
			encounter = argument.trim_prefix("--encounter=")
	assert(power > 0 and power <= 5)
	assert(capture_fps in [15, 30])
	assert(enemy_health_multiplier >= 1 and enemy_health_multiplier <= 10)
	assert(encounter in ["encounter_final", "encounter_classroom"])
	var root := get_tree().root
	DirAccess.make_dir_recursive_absolute(CACHE + "frames")
	DirAccess.make_dir_recursive_absolute(REVIEW)
	root.size = size
	root.content_scale_size = Vector2i(1280, 720)
	var game = Campaign.instantiate()
	game.progress.path = CACHE + "demo-profile.json"
	root.add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game.storage_ready = false
	game.run.node = {"id": "", "name": "困难战斗 · 动作演示", "kind": "battle",
		"encounter": 0, "encounter_id": encounter, "power": power}
	var layouts := [[0, -1, -1, 2, 1, 4], [0, -1, -1, 4, 1, 2], [-1, 0, -1, 4, 2, 1], [0, -1, 4, 2, 1, -1]]
	assert(layout >= 0 and layout < layouts.size())
	game.formation = layouts[layout].duplicate()
	var roster: Array[int] = [0, 1, 2, 4]
	game.run.roster = roster
	game.screen = "battle"
	if is_instance_valid(game.campaign_panel): game.campaign_panel.hide()
	game._start()
	var initial_units: Array[Dictionary] = []
	var actors: Dictionary = {}
	var states: Dictionary = {}
	var screenshots: Dictionary = {}
	for actor in game.units:
		# Configure enemy endurance once, before simulation time advances. Full-health
		# allies, normal damage and existing skills keep critical transitions organic.
		if actor.side == 1:
			actor.max_hp = roundf(actor.max_hp * enemy_health_multiplier)
			actor.hp = actor.max_hp
		initial_units.append({"id": actor.id, "name": actor.name, "side": actor.side,
			"role": actor.role, "hp": actor.hp, "max_hp": actor.max_hp, "atk": actor.atk,
			"defense": actor.def, "interval": actor.interval, "slot": actor.slot})
		if actor.side == 0 and SAMPLES.has(actor.role):
			var role: int = actor.role
			assert(Content.role_id(role) == NAMES[role])
			var animation = load(SAMPLES[role] + "battle_animation.tres")
			assert(animation != null and animation.presentation_scene == null)
			actor.battle_animation = animation
			actor.animation = Player2D.new(animation, actor.get("attack_modes", 1))
			actors[role] = actor
			states[NAMES[role]] = {}
	assert(actors.size() == 4)
	game.presentation_cue.connect(func(event: Dictionary): events.append(event.duplicate(true)))
	game._clear_battle_presentations()
	game._create_battle_presentations()
	game._update_battle_presentations()
	game.queue_redraw()
	var frames: Array[Dictionary] = []
	var image_index := 0
	var capture_every: int = FPS / capture_fps
	var finished := 0
	if not scan_only: Input.warp_mouse(Vector2(1900, 1060))
	for index in FPS * 96:
		game._process(1.0 / FPS)
		var observations := {}
		var vfx_observations: Array[Dictionary] = []
		for burst in game.cast_vfx.bursts:
			vfx_observations.append({"kind": burst.kind, "shape": burst.style.shape, "age": burst.age, "action_id": burst.action_id, "position": [burst.position.x, burst.position.y], "sonic_ring_count": game.cast_vfx.sonic_rings(burst).size()})
		var selected: Array[String] = []
		for role in actors:
			var actor: Dictionary = actors[role]
			var name: String = NAMES[role]
			var state: String = str(actor.animation.state)
			states[name][state] = int(states[name].get(state, 0)) + 1
			observations[name] = {"state": state, "age": actor.animation.age,
				"hp": actor.hp, "max_hp": actor.max_hp, "shield": actor.shield,
				"position": [actor.position.x, actor.position.y]}
			var label := name + "-" + state
			var sample_age: float = 0.15
			if state == "death": sample_age = actor.animation._duration(&"death")
			if not screenshots.has(label) and actor.animation.age >= sample_age:
				selected.append(label)
		# Resolution stills also capture the pressure wave after ignition, rather
		# than only the first cast pose during preparation.
		if stills_only:
			for burst in game.cast_vfx.bursts:
				if burst.kind != "release" or burst.age < 0.13 or burst.age > 0.20: continue
				var label: String = ("archer" if burst.style.shape == 0 else "inventor") + "-sonic"
				if not screenshots.has(label) and not selected.has(label): selected.append(label)
		frames.append({"frame": index, "seconds": float(index) / FPS,
			"actors": observations, "vfx": vfx_observations, "phase": game.phase, "screen": game.screen})
		var capture_this_frame := not stills_only and index % capture_every == 0
		if not scan_only and (capture_this_frame or not selected.is_empty()):
			await RenderingServer.frame_post_draw
			for role in actors:
				var foot: Vector2 = game.origin + (game._unit_center(actors[role]) + Vector2(0, 13)) * game.scale_factor
				var pixel: Vector2 = root.get_final_transform() * foot
				observations[NAMES[role]]["foot_px"] = [pixel.x, pixel.y]
			if capture_this_frame or not selected.is_empty():
				var image := root.get_texture().get_image()
				assert(image.get_size() == size)
				if capture_this_frame:
					assert(image.save_png(CACHE + "frames/game-%04d.png" % image_index) == OK)
					image_index += 1
				for label in selected:
					assert(image.save_png(REVIEW + label + "-%dx%d.png" % [size.x, size.y]) == OK)
					screenshots[label] = index
		if game.phase != "battle":
			finished += 1
			if finished >= FPS * 2: break
	var covered := true
	var cast_covered := true
	for role in [1, 2, 4]:
		if not states[NAMES[role]].has("cast"): cast_covered = false
	var critical_visibility := true
	for role in [2, 4]:
		for required in ["idle", "move", "cast", "hurt", "critical", "death", "ranged"]:
			if not states[NAMES[role]].has(required): covered = false
		if int(states[NAMES[role]].get("critical", 0)) < FPS / 2: critical_visibility = false
	# Coverage and preferred viewing time are separate evidence. Do not force states
	# or damage to stretch a short genuine low-health transition.
	var result := "FAIL"
	if covered and cast_covered: result = "PASS" if critical_visibility else "PASS_WITH_NOTES"
	var audit := {"result": result, "scene": "res://scenes/expedition/expedition.tscn",
		"seven_state_coverage": "PASS" if covered else "FAIL",
		"three_role_cast_coverage": "PASS" if cast_covered else "FAIL",
		"preferred_critical_visibility": "PASS" if critical_visibility else "FAIL",
		"preferred_critical_seconds": 0.5,
		"visibility_notes": [] if critical_visibility else ["At least one actual critical window is shorter than 0.5 seconds; standalone Godot previews show each action for 3 seconds."],
		"fps": FPS, "resolution": [size.x, size.y], "frames": frames, "events": events,
		"capture_fps": capture_fps, "captured_frame_count": image_index,
		"state_frame_counts": states, "screenshots": screenshots, "backend": "2D SpriteFrames",
		"animation_overrides": SAMPLES, "stills_only": stills_only, "scan_only": scan_only,
		"encounter_id": encounter, "enemy_power": power, "formation_layout": layout,
		"enemy_health_multiplier": enemy_health_multiplier, "initial_units": initial_units,
		"combat_rules_modified": false, "runtime_hp_or_animation_forced": false,
		"production_assets_modified": false, "profile": game.progress.path,
		"won": game.result_won, "simulation_finished": game.simulation.finished}
	var audit_name := "scan.json" if scan_only else ("stills-%dx%d.json" % [size.x, size.y] if stills_only else "capture.json")
	var file := FileAccess.open(CACHE + audit_name, FileAccess.WRITE)
	file.store_string(JSON.stringify(audit, "\t")); file.close()
	print("HEALER_INVENTOR_GAMEPLAY result=", audit.result, " frames=", frames.size(), " states=", states)
	get_tree().quit(0 if covered and cast_covered else 1)
