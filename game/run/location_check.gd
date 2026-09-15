extends Node
const Journey = preload("res://game/run/campaign_journey.gd")
var failures = 0
var checks = 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	for region in Journey.Regions.MAPS:
		for branch in [0,1]:
			var journey = Journey.new()
			verify(journey.begin(region,2),"begin")
			while not journey.data.finished:
				verify(journey.enter(branch if journey.data.step == 1 else 0,[]),"enter branch")
				verify(not journey.leave(),"guard gate")
				var snapshot = journey.snapshot()
				var restored = Journey.new()
				verify(restored.restore(JSON.parse_string(JSON.stringify(snapshot))),"disk shape restore")
				verify(restored.snapshot() == snapshot,"no reroll")
				journey = restored
				journey.visit.data.guard_won = true
				journey.visit.data.reward_taken = true
				verify(journey.leave(),"optional memories skipped")
			verify(journey.data.visited.size() == 4,"four visits")
	var a = Journey.new()
	a.begin("library",0)
	a.enter(0,["gate_system_1"])
	verify(a.visit.data.hotspots[1].id == "gate_system_2","unrecorded first")
	verify(not a.enter(0,[]),"cannot overwrite active visit")
	if "--capture" in OS.get_cmdline_user_args():
		var panel = preload("res://scenes/expedition/campaign_panel.gd").new()
		add_child(panel)
		a.visit.data = {}
		panel.route(a)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/m1-route.png")
		a.visit.begin("library",0,[],1)
		panel.location(a)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/m1-location.png")
	print("LOCATION_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(1 if failures else 0)
