extends RefCounted
const Journey = preload("res://game/run/campaign_journey.gd")
const Build = preload("res://game/run/short_run.gd")

static func decode(source: Dictionary) -> Dictionary:
	if source.get("kind") != "campaign" or source.get("schema") != 1: return {}
	if not source.get("mode") in ["region","prologue","finale"]: return {}
	var journey = Journey.new()
	var build = Build.new()
	if not journey.restore(source.get("journey")): return {}
	if source.mode == "finale":
		var phase = journey.data.get("finale_phase")
		if not (phase is int or phase is float) or int(phase) != phase or phase < 0 or phase > 2: return {}
		journey.data.finale_phase = int(phase)
	if not source.get("build") is Dictionary or not build.restore(source.build): return {}
	return {"journey":journey,"build":build,"mode":source.mode}

static func pack(journey, build, mode: String) -> Dictionary:
	# Reuse the existing build codec without pretending its legacy route is M1.
	var saved: Dictionary = build.to_dict()
	saved.stage = 0
	saved.visited = []
	saved.node_id = ""
	saved.reward_ids = []
	saved.reward_snapshots = []
	saved.event_done = false
	saved.event_points = 0
	saved.reward_taken = false
	saved.settled = false
	return {"kind":"campaign","schema":1,"mode":mode,"journey":journey.snapshot(),"build":saved}
