extends Node
const Codes = preload("res://game/combat/code_catalog.gd")
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
var failures := 0

func expect(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("PREPARATION: " + label)

func _ready() -> void:
	expect(Codes.validate().is_empty(),"expanded resources valid")
	var stock := Codes.stock()
	stock.shield = 1
	stock.revive = 1
	var sim = Fixture.build(Fixture.DEFAULT,[],{},["redirect","repair"],stock)
	var ally: Dictionary = sim._living(0)[0]
	var other: Dictionary = sim._living(0)[1]
	var foe: Dictionary = sim._living(1)[0]
	expect(not sim.use_item("revive",str(ally.id)) and sim.items.revive == 1,"cannot revive living actor or consume invalid item")
	var prior_shield: float = ally.shield
	expect(sim.use_item("shield",str(ally.id)) and ally.shield == minf(sim.SHIELD_CAP,prior_shield+120) and sim.items.shield == 0,"shield applies and consumes")
	var hits: Array[Dictionary] = []
	sim._event(hits,foe,ally,"damage",110)
	sim._resolve(hits)
	expect(ally.shield < minf(sim.SHIELD_CAP,prior_shield+120),"item shield absorbs real resolved damage")
	sim.elapsed += 0.31
	sim._release_code_cycles()
	expect(sim.blocks.purple >= 1,"actual absorption produces purple code")
	other.hp = 0
	expect(not sim.use_item("revive",str(other.id)),"shared item cooldown enforced")
	sim.elapsed += Codes.RULES.item_cooldown
	expect(sim.use_item("revive",str(other.id)) and other.hp == other.max_hp*0.5,"dead actor revives at half health")
	expect(other.action.is_empty() and other.pending_cast.is_empty() and other.timer > 0,"revive resets stale actions")
	sim.advance(0.1)
	expect(other.hp > 0 and sim._living(0).has(other),"revived actor reenters simulation")
	var wipe = Fixture.build(Fixture.DEFAULT,[],{},["redirect","repair"],stock)
	for actor in wipe._living(0): actor.hp = 0
	expect(not wipe.use_item("revive","0"),"wipe cannot be undone")
	var old := Codes.migrate_stock({"supply":0,"converter":1})
	expect(old == {"supply":0,"converter":1,"shield":0,"revive":0},"old stocks gain no free items")
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/preparation-check-profile.json"
	game.progress.campaign.prologue_done = true
	game.progress.campaign.routes_acquired = true
	game.progress.commission_unlocks = ["departure","shield_kit","revive_kit"]
	game.progress.write_save()
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game._campaign_action("strategy:library:region:protect")
	expect(game.screen == "departure","strategy leads to preparation")
	game._campaign_action("prep:shield")
	expect(game.departure_items == ["supply","converter","shield"],"valid selection added")
	game._campaign_action("prep:revive")
	expect(game.departure_items.size() == 3,"over-budget selection rejected")
	if "--capture" in OS.get_cmdline_user_args(): await capture("preparation-pool")
	game._campaign_action("depart")
	expect(game.run.code_supplies == {"supply":1,"converter":1,"shield":1,"revive":0},"new run contains exactly selected stock")
	game.run.code_supplies.supply = 0
	game._save_campaign()
	game._continue_run()
	expect(game.run.code_supplies.supply == 0,"resume does not replenish stock")
	game.journey.enter(0,[])
	game._guard()
	game._start()
	expect(game.phase == "battle","original battle starts")
	game.simulation.items.shield = 1
	game.simulation.items.revive = 1
	var fallen: Dictionary = game.simulation._living(0)[1]
	fallen.hp = 0
	game.code_panel._process(0.0)
	game.code_panel._update_hud()
	game.code_panel._select_item("revive")
	game.code_panel._update_hud()
	expect(game.code_panel.item_controls.revive.destination.item_count == 1,"HUD selects fallen actors")
	if "--capture" in OS.get_cmdline_user_args(): await capture("preparation-revive")
	game.code_panel._use_code_item("revive")
	expect(fallen.hp > 0 and game.simulation.items.revive == 0,"actual HUD uses revival")
	print("PREPARATION failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = resolution
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		for button in get_tree().root.find_children("*","Button",true,false):
			if button.is_visible_in_tree() and button.get_meta("action_id","") in ["depart","base"]:
				expect(get_viewport().get_visible_rect().encloses(button.get_global_rect()),"departure actions fit viewport "+str(resolution))
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://.godot/%s-%dx%d.png" % [id,resolution.x,resolution.y])
		if resolution == Vector2i(1920,1080): image.save_png("res://.godot/%s.png" % id)
