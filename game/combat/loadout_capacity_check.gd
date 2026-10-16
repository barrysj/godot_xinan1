extends Node
const Codes = preload("res://game/combat/code_catalog.gd")
var failures := 0
func expect(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _ready() -> void:
	var expanded = Codes.RULES.duplicate(true)
	var fourth = expanded.programs[0].duplicate(true)
	fourth.id = "qa_fourth"
	expanded.programs.append(fourth)
	expect(Codes.valid_loadout(["disconnect","redirect","repair","qa_fourth"],expanded),"Four distinct registered programs accepted")
	expect(not Codes.valid_loadout(["disconnect","redirect","repair","qa_fourth","repair"],expanded),"Fifth slot rejected")
	expect(not Codes.valid_loadout(["repair","repair"]),"Duplicate programs rejected")
	expect(Codes.migrate_loadout(["disconnect","repair"]) == ["disconnect","repair"],"Existing two-slot saves preserved")
	print("LOADOUT_CAPACITY_CHECK checks=4 failures=%d" % failures)
	get_tree().quit(failures)
