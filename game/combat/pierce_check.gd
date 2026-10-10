extends Node
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func sample(extras: Array, primary_position := Vector2(2,4), reversed := false) -> Dictionary:
	var sim = Fixture.build([0,5,-1,3,1,-1], ["pierce"])
	var actor: Dictionary = sim._living(0).filter(func(unit): return unit.content_id == "archer")[0]
	var analyst: Dictionary = sim._living(0).filter(func(unit): return unit.content_id == "analyst")[0]
	var foes: Array = sim._living(1)
	actor.position = Vector2(2,5)
	for foe in foes:
		foe.position = Vector2(20,20)
		foe.hp = 500.0
		foe.max_hp = 500.0
		foe.def = 0.0
	foes[0].position = primary_position
	for i in range(extras.size()): foes[i+1].position = extras[i]
	sim.marks[foes[0].id] = {"owner":analyst.id,"confirmed_until":100.0,"pending_until":0.0,"exposed_until":0.0,"until":100.0,"users":[]}
	if reversed: sim.units.reverse()
	sim.active_action_id = 10
	var due: Array[Dictionary] = []
	sim._skill_events(actor,foes[0],due)
	var target_ids: Array = due.map(func(event): return event.target.id)
	var raw: Array = due.map(func(event): return event.value)
	sim._resolve(due)
	expect(sim.generated.get("red",0) == 0 and sim.attack_counts.is_empty(), "skill piercing creates no basic-attack code")
	expect(target_ids[0] == foes[0].id and raw[0] == 68.0, "primary skill remains unchanged")
	if target_ids.size() == 2: expect(raw[1] == 34.0, "single extra hit is half raw skill damage")
	return {"targets":target_ids,"primary":foes[0].id,"extra":foes[1].id,"other":foes[2].id}

func _ready() -> void:
	var valid := sample([Vector2(2,3.1)])
	expect(valid.targets == [valid.primary,valid.extra], "enemy directly behind can be pierced")
	var before := sample([Vector2(2,4.5)])
	expect(before.targets.size() == 1, "enemy between shooter and primary is excluded")
	var far := sample([Vector2(2,2.4)])
	expect(far.targets.size() == 1, "behind distance over one and a half excluded")
	var wide := sample([Vector2(2.36,3.1)])
	expect(wide.targets.size() == 1, "off-line enemy excluded")
	var edge := sample([Vector2(2.35,2.5)])
	expect(edge.targets.size() == 2, "width and length boundary included")
	var unreachable := sample([Vector2(2,0.9)],Vector2(2,2))
	expect(unreachable.targets.size() == 1, "behind enemy outside shooter range excluded")
	var several := sample([Vector2(2,3.4),Vector2(2,2.8)])
	expect(several.targets == [several.primary,several.extra], "only nearest valid enemy pierced")
	var tied := sample([Vector2(1.8,3),Vector2(2.2,3)])
	var tied_reverse := sample([Vector2(1.8,3),Vector2(2.2,3)],Vector2(2,4),true)
	expect(tied.targets == tied_reverse.targets and tied.targets.size() == 2, "equal-distance choice stable under array reorder")
	var coincident := sample([Vector2(2,4)],Vector2(2,5))
	expect(coincident.targets.size() == 1, "zero-length direction cannot pierce")
	if "--capture" in OS.get_cmdline_user_args(): await capture_main()
	print("PIERCE_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture_main() -> void:
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/pierce-main-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,6,1,-1]
	game.run.formation = game.formation.duplicate()
	var offer: Dictionary = game.RunModel.Rewards.eligible(false,game.run.roster,game.run.inventory).filter(func(entry): return entry.get("target") == "pierce")[0]
	expect(game.run.apply_reward(offer), "main build grants actual archer exclusive")
	game._build_units()
	game._start()
	var sim = game.simulation
	var actor: Dictionary = sim._living(0).filter(func(unit): return unit.content_id == "archer")[0]
	var analyst: Dictionary = sim._living(0).filter(func(unit): return unit.content_id == "analyst")[0]
	var foes: Array = sim._living(1)
	for unit in sim.units:
		unit.timer = 1000.0
		unit.move_speed = 0.0
		unit.moving = false
	actor.position = Vector2(3,4.5)
	actor.previous_position = actor.position
	actor.timer = 0.0
	actor.count = actor.skill.attacks_to_trigger - 1
	for foe in foes:
		foe.position = Vector2(5,1)
		foe.previous_position = foe.position
		foe.def = 0.0
		foe.hp = 500.0
		foe.max_hp = 500.0
	foes[0].position = Vector2(3,3.5)
	foes[1].position = Vector2(3,2.5)
	for foe in foes: foe.previous_position = foe.position
	sim.marks[foes[0].id] = {"owner":analyst.id,"confirmed_until":100.0,"pending_until":0.0,"exposed_until":0.0,"until":100.0,"users":[]}
	expect(sim.request_action(actor.id,foes[0].id), "original action system starts charged ranged attack")
	for tick in range(12):
		game._tick()
		if not sim.projectiles.is_empty(): break
	expect(sim.projectiles.size() == 3, "real release creates basic plus primary and piercing projectiles")
	for tick in range(12):
		if foes[0].hp < 500: break
		game._tick()
	expect(sim.projectiles.any(func(shot): return shot.target_id == foes[1].id) and foes[0].hp < 500 and foes[1].hp == 500, "piercing flight continues beyond the struck primary")
	game.paused = true
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		game.queue_redraw()
		game.code_panel._process(0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/pierce-main-%dx%d.png" % [size.x,size.y])
	game.paused = false
	for tick in range(20): game._tick()
	expect(foes[0].hp == 398 and foes[1].hp == 466, "original projectiles land with full primary and half extra damage")
	expect(sim.generated.get("red",0) == 0, "one real basic attack does not gain code from piercing")
	game.queue_free()
