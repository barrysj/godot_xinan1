extends RefCounted
## Verify real battles, retry/pause and difficulty cycling through the shared view.
const Content = preload("res://game/content/content_db.gd")
const Presets = preload("res://game/combat/demo_battle_presets.gd")
const Options = preload("res://scenes/battle_demo/demo_options.gd")

static func run(battle: Control) -> void:
	var failures: Array[String] = []
	var difficulty: String = battle.demo_options.difficulty
	var original_animations: String = battle.demo_options.animations
	var original_definitions := {}
	for definition in Content.MANIFEST.enemies:
		original_definitions[definition.id] = [definition.health, definition.attack]
	var unknown = Options.new()
	if unknown.configure(PackedStringArray(["--demo-difficulty=invalid"])):
		failures.append("Invalid difficulty must be rejected")
	var bad_size = Options.new()
	if bad_size.configure(PackedStringArray(["--demo-size=0x0"])):
		failures.append("Invalid window size must be rejected")
	for actor in battle.units:
		if actor.side == 0 and actor.hp != actor.max_hp: failures.append("Allies start at full health")
	for repeat in range(2):
		battle._start()
		var enemy_definitions: Array = Content.encounter(battle.encounter_id).units
		var enemies: Array = battle.units.filter(func(u): return u.side == 1)
		for i in enemies.size():
			if enemies[i].max_hp != roundf(enemy_definitions[i].health * Presets.preset(difficulty).health):
				failures.append("Retry must not compound enemy health")
			if enemies[i].atk != roundf(enemy_definitions[i].attack * Presets.preset(difficulty).attack):
				failures.append("Preset enemy attack")
		for actor in battle.units:
			if actor.side == 0 and Options.CURRENT.has(actor.content_id):
				var expected: String = Options.CURRENT[actor.content_id] if original_animations == "current" else Content.character(actor.role).battle_animation.resource_path
				if actor.battle_animation.resource_path != expected: failures.append("Actual animation must match the selected set")
	var states := {}
	for actor in battle.units:
		if actor.side == 0 and Options.CURRENT.has(actor.content_id): states[actor.content_id] = {}
	for step in 3000:
		battle._process(1.0 / 30)
		for actor in battle.units:
			if states.has(actor.content_id):
				var state: String = str(actor.animation.state)
				states[actor.content_id][state] = int(states[actor.content_id].get(state, 0)) + 1
				if state == "critical" and not (actor.hp > 0 and actor.hp <= actor.max_hp * actor.battle_animation.critical_ratio):
					failures.append("Critical must come from actual low health")
				if state == "death" and actor.hp != 0: failures.append("Death must come from zero health")
		if step == 60:
			battle._open_pause()
			var frozen = [battle.elapsed, battle.visual_time, battle.accumulator]
			battle._process(1.0)
			if frozen != [battle.elapsed, battle.visual_time, battle.accumulator]: failures.append("Pause must freeze the battle")
			battle._resume_battle()
		if battle.phase != "battle": break
	if battle.phase != "result": failures.append("Battle must reach the normal result screen")
	if difficulty == "hard" and original_animations == "current":
		if battle.result_won: failures.append("Hard sample must provide a defeat demonstration")
		for id in states:
			var required := ["idle", "move", "cast", "hurt", "critical", "death", "ranged" if id == "archer" else "melee"]
			for action in required:
				if not states[id].has(action): failures.append(id + " missing " + action)
	battle._return_to_formation()
	var visited: Array[String] = []
	for i in 3:
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = battle.origin + battle._action_rect(3).get_center() * battle.scale_factor
		battle._gui_input(click)
		visited.append(battle.demo_options.difficulty)
		if battle.encounter_id != battle.demo_options.preset().encounter: failures.append("Difficulty button must update the actual encounter")
		if battle.encounter != (1 if battle.encounter_id == "encounter_final" else 0): failures.append("Backdrop must follow the selected encounter")
	if visited.size() != 3 or not visited.has("easy") or not visited.has("normal") or not visited.has("hard"):
		failures.append("Difficulty button must cycle all presets")
	if battle.demo_options.difficulty != difficulty: failures.append("Difficulty cycling must return to the original preset")
	for definition in Content.MANIFEST.enemies:
		if original_definitions[definition.id] != [definition.health, definition.attack]: failures.append("Shared content definitions must remain unchanged")
	print("DEMO_DIFFICULTY_CHECK result=", "PASS" if failures.is_empty() else "FAIL",
		" difficulty=", difficulty, " animations=", original_animations, " states=", states, " failures=", failures)
	battle.get_tree().quit(0 if failures.is_empty() else 1)
