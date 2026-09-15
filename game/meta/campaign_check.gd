extends Node
const Profile = preload("res://game/meta/campus_progress.gd")
var failures = 0
var checks = 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	var p = Profile.new()
	p.path = "res://.godot/campaign-check.json"
	var legacy = {"version":3, "points":12, "completions":8,
		"active_run":{"legacy":"untouched"}}
	var file = FileAccess.open(p.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	verify(p.read_save(), "v3 read")
	verify(p.points == 12 and p.completions == 8 and p.campaign.terminals.is_empty(), "no invented terminals")
	verify(p.active_run == legacy.active_run and p.write_save(), "legacy snapshot retained")
	verify(not p.complete_tutorial_dispatch(), "tutorial needs prologue")
	verify(p.complete_prologue() and p.complete_prologue(), "prologue idempotent")
	verify(p.complete_tutorial_dispatch() and p.complete_tutorial_dispatch(), "tutorial idempotent")
	for order in [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]:
		p.campaign = p.Campaign.fresh()
		p.complete_prologue()
		p.complete_tutorial_dispatch()
		for i in order:
			var id = p.Campaign.REGIONS[i]
			verify(p.settle_region(id,id,["placeholder_person"],2), "region " + id)
			var before = p.to_dict()
			verify(p.settle_region(id,id,["placeholder_person"],2) and before == p.to_dict(), "duplicate settlement")
		verify(p.campaign.terminals.size() == 3 and p.campaign.characters.size() == 1, "order independent")
		verify(not p.complete_finale_stage(2), "cannot skip phase")
		for stage in [1,2,3]:
			verify(p.complete_finale_stage(stage), "phase committed")
			var loaded = Profile.new()
			loaded.path = p.path
			verify(loaded.read_save() and loaded.campaign == p.campaign, "phase restored")
			p = loaded
		verify(p.campaign.restored and p.complete_finale_stage(3), "ending idempotent")
	var before = p.to_dict()
	p.path = "res://.godot/missing-campaign-directory/profile.json"
	verify(not p.record_memory("library_photo") and p.to_dict() == before, "memory write rollback")
	verify(not p.settle_region("replay", "library", ["new_person"], 5) and p.to_dict() == before, "settlement write rollback")
	p.campaign = p.Campaign.fresh()
	before = p.to_dict()
	verify(not p.complete_prologue() and p.to_dict() == before, "prologue rollback")
	p.campaign.prologue_done = true
	before = p.to_dict()
	verify(not p.complete_tutorial_dispatch() and p.to_dict() == before, "tutorial rollback")
	verify(not p.Campaign.valid({"schema":1}), "malformed campaign rejected")
	print("CAMPAIGN_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(1 if failures else 0)
