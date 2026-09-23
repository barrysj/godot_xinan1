extends RefCounted
## Build the actual campus units and encounter for combat rule checks.
const Sim = preload("res://game/combat/code_battle_simulation.gd")
const Catalog = preload("res://game/combat/combat_content_catalog.gd")
const Content = preload("res://game/content/content_db.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
const AutoBattle = preload("res://game/combat/auto_battle.gd")
const DEFAULT = [0, -1, 3, 2, 1, -1]

static func build(formation: Array = DEFAULT, rewards: Array = [], owners: Dictionary = {}, programs: Array = ["disconnect", "takeover"], supplies: Dictionary = {}) -> RefCounted:
	var units: Array[Dictionary] = []
	for slot in range(formation.size()):
		var index: int = formation[slot]
		if index < 0: continue
		var content_id: String = Catalog.MANIFEST.characters[index].id
		var definition = Content.character(Content.role_index(content_id))
		units.append(_unit(definition, index, 0, slot))
	var encounter = Content.encounter("encounter_patrol")
	for index in range(encounter.units.size()):
		units.append(_unit(encounter.units[index], -1, 1, encounter.slots[index]))
	for index in range(units.size()):
		units[index].id = index
		AutoBattle.initialize(units[index])
	var saved: Array[Dictionary] = []
	for reward_id in rewards:
		var entry: Dictionary = {"target":reward_id}
		if owners.has(reward_id): entry.owner = Catalog.MANIFEST.characters[int(owners[reward_id])].id
		saved.append(entry)
	var simulation = Sim.new()
	simulation.reset(units)
	simulation.configure_combat(programs, Codes.stock() if supplies.is_empty() else supplies, encounter.maintenance_interval, encounter.maintenance_shield, saved)
	return simulation

static func _unit(definition, role: int, side: int, slot: int) -> Dictionary:
	var unit := {"name":definition.display_name,"role":role,"side":side,"slot":slot,
		"max_hp":float(definition.health),"hp":float(definition.health),"atk":float(definition.attack),
		"interval":definition.interval,"timer":definition.interval,"def":float(definition.defense),
		"shield":0.0,"count":0,"flash":0.0,"damage":0.0,"healing":0.0,
		"attack_range":definition.attack_range,"attack_modes":definition.resolved_attack_modes(),
		"move_speed":definition.move_speed,"content_id":definition.id,"skill":definition.skill,
		"portrait":definition.portrait,"battle_animation":definition.battle_animation,
		"action_profile":definition.action_profile,"badge_color":definition.badge_color}
	return unit
