extends RefCounted
const Model = preload("res://game/run/short_run.gd")
const Checkpoint = preload("res://game/run/run_checkpoint.gd")
var failures = 0
var battles = 0
func verify(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("RANDOM_CHECK: "+message)
func run_checks(hub) -> void:
	var maps = {}
	var rewards = {}
	for seed_value in range(200):
		var run = Model.new()
		run.generate(seed_value)
		maps[JSON.stringify(run.stages)] = true
		var ids = []
		for i in range(5):
			var has_safe = false
			for place in run.stages[i]:
				verify(not ids.has(place.id),"duplicate location")
				ids.append(place.id)
				has_safe = has_safe or place.kind != "elite"
			verify(has_safe,"mandatory elite")
		verify(run.stages[0][0].id == "gate" and run.stages[4][0].id == "boss","endpoints")
		run.choose(0)
		var choices = run.offers()
		verify(choices.size() == 3,"three choices")
		rewards[JSON.stringify(run.reward_ids)] = true
		var clone = Model.new()
		verify(clone.restore(JSON.parse_string(JSON.stringify(run.to_dict()))),"JSON restore")
		verify(clone.stages == run.stages and clone.offers() == choices,"same route and reward after reload")
		verify(run.offers() == choices,"viewing does not reroll")
		verify(run.take_reward(choices[0].id) and not run.take_reward(choices[1].id),"single reward")
		run.complete_node()
		run.choose(0)
		for offer in run.offers():
			verify(not (offer.id == "badge" and run.badge_owned),"duplicate equipment excluded")
			verify(not (offer.id == "recruit" and run.roster.has(4)),"duplicate recruit excluded")
			verify(not (offer.id == "inventor_training" and not run.roster.has(4)),"training for available role only")
	verify(maps.size() > 20 and rewards.size() > 10,"random diversity")
	# Exercise all eight paths across several seeds, with no permanent upgrades.
	for seed_value in range(5):
		for path_index in range(8):
			hub._new_run()
			hub.run.generate(seed_value)
			hub.formation = [-1,0,3,1,2,-1]
			hub.equipment = 1
			hub._sync_team()
			while hub.run.stage < 5:
				hub.chosen_node = (path_index >> (hub.run.stage-1)) & 1 if hub.run.stage > 0 and hub.run.stage < 4 else 0
				hub._enter_node()
				verify(not Checkpoint.decode(hub.progress.active_run).is_empty(),"scene checkpoint valid")
				if hub.screen == "battle":
					hub._start()
					for frame in range(6000):
						if hub.screen != "battle": break
						hub._process(1.0/30.0)
					battles += 1
					verify(hub.screen == "report" and hub.result_won,"route win seed=%d path=%d stage=%d" % [seed_value,path_index,hub.run.stage])
					if not hub.result_won: break
					hub._after_report()
				else: hub.screen = "reward"
				if hub.screen == "reward":
					var offers = hub.run.offers()
					var choice = 0
					for i in range(offers.size()):
						if offers[i].id == "archer_training": choice = i
					hub._choose_reward(choice)
					if hub.run.badge_owned: hub.run.badge_wearer = 0
			verify(hub.screen == "summary","route completed")
	print("RANDOM_CHECK seeds=200 maps=",maps.size()," reward_sets=",rewards.size()," paths=40 battles=",battles," failures=",failures)
	if failures > 0:
		hub.get_tree().quit(1)
		return
	hub._new_run()
	hub.run.generate(42)
	hub._checkpoint()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/random_route.png")
	hub._enter_node()
	hub.formation = [-1,0,3,1,2,-1]
	hub.equipment = 1
	hub._start()
	while hub.screen == "battle": hub._process(1.0/30.0)
	hub._after_report()
	var saved_choices = hub.run.offers()
	hub._to_base()
	var loaded = hub.ProgressModel.new()
	loaded.path = hub.progress.path
	verify(loaded.read_save(),"disk reload")
	hub.progress = loaded
	hub._continue_run()
	verify(hub.screen == "reward" and hub.run.offers() == saved_choices,"pending reward survives disk reload")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/random_rewards.png")
	print("RANDOM_RELOAD pending reward and screenshot passed; failures=",failures)
	hub.get_tree().quit(0 if failures == 0 else 1)
