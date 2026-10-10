extends Node
## Validate both growth versions in the original controller and build/checkpoint codecs.
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Run = preload("res://game/run/short_run.gd")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func _ready() -> void:
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/growth-budget-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	expect(game.run.growth_rules == 2, "actual new journey uses balanced growth")
	game.run.roster.assign([0,1,2,3,4,5,6])
	game.formation = [0,3,-1,6,1,-1]
	game.run.formation = game.formation.duplicate()
	game.run.training[0] = 2
	var guard: Dictionary = game._ally_unit(0,0)
	expect(guard.max_hp == 432 and guard.atk == 26 and is_equal_approx(guard.interval,1.62), "two additive training shares and balanced shoe")
	var archer_training: Dictionary = Run.Rewards.find("archer_training")
	expect(game.run.apply_reward(archer_training), "original normal training grants one share")
	var archer: Dictionary = game._ally_unit(1,5)
	expect(archer.max_hp == 226 and archer.atk == 37, "one normal share uses character base and rounding")
	var pool: Array = Run.Rewards.for_build(game.run)
	var concentrated: Dictionary = pool.filter(func(offer): return offer.operation == "combat" and offer.target == "training")[0]
	expect(pool.filter(func(offer): return offer.operation == "train").all(func(offer): return offer.description.contains("+10%") and not offer.description.contains("+50")), "new training previews match actual growth")
	game.journey.visit.data.guard_won = true
	game.journey.data.screen = "reward"
	game.journey.data.offers = [concentrated]
	game._show_journey()
	await get_tree().process_frame
	await choose(game,"reward:0")
	expect(game.journey.data.screen == "reward_owner", "concentrated training enters original owner selection")
	var guard_buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == "reward_owner:guard")
	expect(guard_buttons.size() == 1 and guard_buttons[0].disabled and not guard_buttons[0].tooltip_text.is_empty(), "full training owner is disabled with explanation")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"owner")
	await choose(game,"reward_owner:archer")
	archer = game._ally_unit(1,5)
	expect(game.run.training_count(1) == 2 and archer.max_hp == 246 and archer.atk == 39, "normal and concentrated training share additive cap")
	expect(not game.run.apply_reward(archer_training) and game.run.training_count(1) == 2, "third share rejected without mutation")
	expect(not Run.Rewards.for_build(game.run).any(func(offer): return offer.id == "archer_training"), "full owner normal training leaves pool")
	game.run.grant_gear("badge")
	game.run.equip_gear("badge",1)
	game.run.permanent_hp = 40
	archer = game._ally_unit(1,5)
	expect(archer.max_hp == 326 and archer.atk == 39, "equipment and meta fixed health are added after base growth")
	game.run.grant_gear("ribbon")
	game.run.equip_gear("ribbon",2)
	var healer: Dictionary = game._ally_unit(2,3)
	expect(healer.max_hp == 290 and healer.atk == 22, "balanced ribbon keeps twenty health and four attack")
	expect(game._gear_definition("badge").description.contains("+40") and game._gear_definition("shoe").description.contains("-10%"), "inspector source uses current run equipment values")
	expect(Run.Content.gear("badge").health_bonus == 80 and Run.Content.gear("shoe").interval_multiplier == 0.75, "legacy resource values remain available")
	pool = Run.Rewards.for_build(game.run)
	game.journey.visit.data.reward_taken = false
	game.journey.data.screen = "reward"
	game.journey.data.offers = pool.filter(func(offer): return offer.id in ["healer_training","combat_backup","combat_verify"]).slice(0,3)
	game._show_journey()
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"rewards")
	expect(game._save_campaign(), "new growth saves through original campaign checkpoint")
	var saved = game.CampaignSave.decode(game.progress.active_run)
	expect(not saved.is_empty() and saved.build.growth_rules == 2 and saved.build.training_count(1) == 2, "schema eight preserves growth version and shares")
	game.run = saved.build
	archer = game._ally_unit(1,5)
	expect(archer.max_hp == 326 and archer.atk == 39, "rebuilding restored run adds growth exactly once")
	game.journey.visit.data.guard_won = false
	game._guard()
	await get_tree().process_frame
	game.inspector.observed = game.units.filter(func(unit): return unit.side == 0 and unit.role == 1)[0]
	game.inspector.open_bag()
	expect(game.inspector.bag_description.text.contains("+40"), "actual equipment bag shows new budget")
	expect(game.battle_actor_layer.y_sort_enabled and game.battle_actor_views.size() == game.units.size() and game.battle_actor_views.values().all(func(actor): return actor.get_parent() == game.battle_actor_layer), "world actor depth uses one Y-sorted group")
	expect(maximum_z(game.battle_actor_layer,0) < game.inspector.z_index, "all actor parts stay below the actual equipment panel")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"bag")
	game.inspector.close_bag()
	var serialized: Dictionary = game.run.to_dict()
	var disk_clone = Run.new()
	expect(disk_clone.restore(JSON.parse_string(JSON.stringify(serialized))) and disk_clone.growth_rules == 2 and disk_clone.training_count(1) == 2, "JSON numeric schema retains the current growth build")
	var broken = serialized.duplicate(true)
	broken.training.archer = 2
	var target = Run.new()
	var before: Dictionary = target.to_dict()
	expect(not target.restore(broken) and target.to_dict() == before, "over-cap new snapshot rejected atomically")
	broken = serialized.duplicate(true)
	broken.growth_rules = 99
	expect(not target.restore(broken), "future growth rule rejected")
	broken = serialized.duplicate(true)
	broken.growth_rules = 1.5
	expect(not target.restore(broken), "fractional growth rule rejected")
	var legacy: Dictionary = serialized.duplicate(true)
	legacy.schema = 7
	legacy.erase("growth_rules")
	legacy.training.archer = 100
	expect(target.restore(legacy) and target.growth_rules == 1 and target.training[1] == 100, "schema seven retains high historical training without clipping")
	game.run = target
	archer = game._ally_unit(1,5)
	expect(archer.max_hp == 5854 and archer.atk == 577 and game._gear_definition("badge").health_bonus == 80, "legacy fixed training and concentrated multiplication stay unchanged")
	var legacy_pending: Dictionary = legacy.duplicate(true)
	legacy_pending.combat_rewards = []
	var old_pending_build = Run.new()
	expect(old_pending_build.restore(legacy_pending) and old_pending_build.apply_reward(concentrated,"archer"), "legacy ordinary cap does not block its independent concentrated reward")
	for schema in [1,2,3]:
		var old_build = Run.new()
		if schema == 2: old_build.generate(12345)
		var old_source: Dictionary = old_build._legacy_dict()
		old_source.schema = schema
		var migrated = Run.new()
		expect(migrated.restore(old_source) and migrated.growth_rules == 1, "numeric historical build schema "+str(schema))
	for schema in [4,5,6]:
		var old_source: Dictionary = serialized.duplicate(true)
		old_source.schema = schema
		old_source.erase("growth_rules")
		var migrated = Run.new()
		expect(migrated.restore(old_source) and migrated.growth_rules == 1, "stable-id historical build schema "+str(schema))
	var rewritten: Dictionary = target.to_dict()
	expect(rewritten.schema == 8 and rewritten.growth_rules == 1, "rewritten old snapshot explicitly keeps legacy budget")
	var clone = Run.new()
	expect(clone.restore(rewritten) and clone.growth_rules == 1 and clone.training[1] == 100, "old budget remains stable on later reload")
	# Equipment slots are still scarce after a combat equipment reward.
	var slot_build = Run.new()
	slot_build.inventory.shoe = -1
	var lens: Dictionary = Run.Rewards.for_build(slot_build).filter(func(offer): return offer.operation == "combat" and offer.target == "lens")[0]
	expect(slot_build.apply_reward(lens,"guard"), "combat equipment occupies one owner slot")
	expect(not slot_build.equip_gear("shoe",0) and slot_build.inventory.shoe == -1, "ordinary equipment cannot overlap a new combat equipment slot")
	var equipment = Run.Content.gear("shoe")
	var original: float = equipment.balanced_interval_multiplier
	equipment.balanced_interval_multiplier = NAN
	expect(not Run.Content.validate().is_empty(), "invalid balanced equipment value is rejected")
	equipment.balanced_interval_multiplier = original
	expect(Run.Content.validate().is_empty(), "registered content remains valid")
	print("GROWTH_BUDGET checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func choose(game, action: String) -> void:
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action)
	expect(buttons.size() == 1 and not buttons[0].disabled, "actual enabled button "+action)
	if buttons.size() != 1: return
	if "--capture" in OS.get_cmdline_user_args():
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = buttons[0].get_global_rect().get_center()
			event.global_position = event.position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			get_viewport().push_input(event,true)
		await get_tree().process_frame
	else:
		buttons[0].pressed.emit()
		await get_tree().process_frame

func capture(game, page: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.campaign_panel.get_viewport_rect().encloses(game.campaign_panel.get_global_rect()), "growth page fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/growth-budget-%s-%dx%d.png" % [page,size.x,size.y])

func maximum_z(node: Node, inherited: int) -> int:
	var own: int = inherited
	if node is CanvasItem: own = inherited + node.z_index if node.z_as_relative else node.z_index
	var result: int = own
	for child in node.get_children(): result = maxi(result,maximum_z(child,own))
	return result
