extends Node
## Drive the real region snapshots and map-node adapter, not a copied route table.
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const Geometry = preload("res://game/run/expanded_campus_geometry.gd")
const Presentation = preload("res://game/run/campus_presentation.gd")
const Journey = preload("res://game/run/campaign_journey.gd")
const Save = preload("res://game/run/campaign_checkpoint.gd")
const Run = preload("res://game/run/short_run.gd")
const Rules = preload("res://game/run/campus_flow_rules.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MAP_ROUTE_SYNC: "+label)

func _ready() -> void:
	var geometry = Geometry.new()
	for region in Catalog.PATHS:
		var flow: Dictionary = Catalog.snapshot(region)
		expect(not flow.is_empty(),"region snapshot loads: "+region)
		if flow.is_empty(): continue
		var forbidden: Array = flow.stops.values().filter(func(stop): return stop.place_id == "south_gate" or stop.title == "南门")
		expect(forbidden.is_empty(),"formal region must not contain tutorial South Gate: "+region)
		var nodes: Array[Dictionary] = Presentation.map_nodes(region,geometry,flow)
		var route: Dictionary = geometry.ROUTES.filter(func(entry): return entry.campaign_region == region)[0]
		expect(flow.title == route.title,"region title comes from editor: "+region)
		var actual: Array = nodes.map(func(node): return node.landmark)
		var expected: Array = route.places.duplicate()
		actual.sort()
		expected.sort()
		expect(actual == expected,"all route landmarks equal editor membership: "+region)
		for node in nodes: expect(node.point == geometry.PLACES[node.landmark].point,"route node uses exact editor coordinate: "+node.landmark)
		expect(not nodes.any(func(node): return node.title == "南门"),"rendered route must not mark South Gate: "+region)
		print("MAP_ROUTE_SNAPSHOT ",region," layers=",flow.layers," nodes=",nodes.map(func(node): return node.title))
	var tutorial: Dictionary = Catalog.snapshot("library","prologue")
	expect(tutorial.layers == [["gate"]] and tutorial.stops.gate.place_id == "south_gate","South Gate remains a single tutorial visit")
	var finale: Dictionary = Catalog.snapshot("library","finale")
	expect(finale.stops.library.place_id == "library_front","finale uses the actual library core, not the tutorial gate")
	check_saved_routes()
	print("MAP_ROUTE_SYNC_CHECK %d checks / %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func legacy(region: String) -> Dictionary:
	var flow := Catalog.snapshot(region).duplicate(true)
	flow.erase("map_contract")
	flow.erase("usage")
	flow.revision = 1
	flow.title = {"library":"图书馆区域","region_b":"第二终端区域","region_c":"第三终端区域"}[region]
	flow.layers = {"library":[["gate"],["walk","court"],["hall"],["library"]],
		"region_b":[["gate"],["hall","walk"],["court"],["end_b"]],
		"region_c":[["gate"],["court","hall"],["walk"],["end_c"]]}[region]
	var identities := {"library":{"gate":"south_gate","walk":"west_lake_entrance","court":"pinxue_courtyard","hall":"pinxue_atrium","library":"library_front"},
		"region_b":{"gate":"south_gate","hall":"xuezi_cafeteria","walk":"yinhua_halal_cafeterias","court":"student_activity_center","end_b":"basic_laboratory_building"},
		"region_c":{"gate":"south_gate","court":"sports_field","hall":"student_activity_center","walk":"west_lake_center","end_c":"chengdian_auditorium_commercial_street"}}
	var stops := {}
	for id in identities[region]:
		var place = load("res://resources/campaign/places/%s.tres" % identities[region][id])
		var row: Dictionary = flow.stops[id].duplicate(true)
		row.merge({"title":place.display_name,"place_id":place.id,"landmark":place.landmark,
			"offset":[place.offset.x,place.offset.y],"background":place.background_id,"library_interior":place.library_interior},true)
		row.erase("map_landmarks")
		row.scenes = []
		for scene in place.scenes: row.scenes.append(scene.snapshot())
		stops[id] = row
	flow.stops = stops
	return flow

func old_journey(region: String, stage: int) -> RefCounted:
	var journey := Journey.new()
	journey.begin(region,2)
	journey.data.flow = legacy(region)
	journey.data.map = journey.data.flow.layers.duplicate(true)
	for step in stage:
		journey.enter(0,[])
		journey.visit.data.guard_won = true
		journey.visit.data.reward_taken = true
		journey.leave()
	return journey

func check_saved_routes() -> void:
	for region in Catalog.PATHS:
		for stage in 4:
			for phase in ["route","visit","battle","report","reward"]:
				var journey = old_journey(region,stage)
				if phase != "route": journey.enter(0,[])
				journey.data.screen = phase
				if phase == "report":
					journey.data.won = true
					journey.data.report = [{"name":"守护者","damage":10,"healing":0}]
					journey.data.elapsed = 10
				if phase == "reward":
					journey.visit.data.guard_won = true
					journey.data.offers = []
					journey.data.rewards_exhausted = true
				var before_visit: Dictionary = journey.visit.data.duplicate(true)
				var before_visited: Array = journey.data.visited.duplicate()
				var build := Run.new()
				var snapshot := Save.pack(journey,build,"region")
				var json_snapshot: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
				var baseline := Run.new()
				baseline.restore(json_snapshot.build)
				var decoded := Save.decode(json_snapshot)
				expect(not decoded.is_empty(),"legacy region phase restores: %s/%s/%s" % [region,stage,phase])
				if decoded.is_empty(): continue
				expect(decoded.journey.data.flow.get("map_contract",0) == 1 and decoded.journey.data.flow.title == Catalog.snapshot(region).title,"old route receives current map binding")
				expect(decoded.journey.data.step == stage and decoded.journey.data.visited == before_visited and decoded.journey.visit.data == before_visit,"migration preserves exact visit and completed station state")
				expect(json_equal(decoded.build.to_dict(),baseline.to_dict()),"migration preserves original build, equipment and supplies")
				var second := Save.decode(JSON.parse_string(JSON.stringify(Save.pack(decoded.journey,decoded.build,"region"))))
				expect(not second.is_empty() and json_equal(second.journey.snapshot(),decoded.journey.snapshot()),"migration is idempotent through the existing JSON codec")
		var custom = old_journey(region,1)
		custom.data.flow.revision = 3
		var original: Dictionary = custom.snapshot()
		var decoded := Save.decode(Save.pack(custom,Run.new(),"region"))
		expect(not decoded.is_empty() and decoded.journey.snapshot() == original,"custom frozen flow is not overwritten")
	for usage in ["prologue","finale"]:
		var journey = old_journey("library",0)
		journey.enter(0,[])
		if usage == "finale": journey.data.finale_phase = 1
		var decoded := Save.decode(Save.pack(journey,Run.new(),usage))
		expect(not decoded.is_empty() and decoded.journey.data.map.size() == 1,"old special flow restores as its own single place")
		if decoded.is_empty(): continue
		expect(decoded.journey.stop().place_id == ("south_gate" if usage == "prologue" else "library_front"),"South Gate is isolated to tutorial, including resumed games")
		var second := Save.decode(JSON.parse_string(JSON.stringify(Save.pack(decoded.journey,decoded.build,usage))))
		expect(not second.is_empty(),"special flow remains a valid saved checkpoint")
	var wrong := Catalog.snapshot("library").duplicate(true)
	wrong.stops.library.landmark = "north"
	wrong.stops.library.map_landmarks = []
	expect(not Rules.validate_snapshot(wrong,"library").is_empty(),"foreign-region landmark is rejected before gameplay")
	wrong = Catalog.snapshot("library").duplicate(true)
	wrong.stops.gate.place_id = "south_gate"
	expect(not Rules.validate_snapshot(wrong,"library").is_empty(),"future formal South Gate regressions are rejected by actual validation")
	# Sharing an image never changes the physical place: the original bug moved
	# a stadium to the playground because both used the sports-field environment.
	var geometry = Geometry.new()
	expect(Presentation.point("region_c","end_c",geometry) == geometry.PLACES.stadium.point,"background reuse cannot redirect the stadium")

func json_equal(first: Dictionary, second: Dictionary) -> bool:
	# Typed Resource arrays and parsed JSON arrays differ in numeric representation.
	return JSON.parse_string(JSON.stringify(first)) == JSON.parse_string(JSON.stringify(second))
