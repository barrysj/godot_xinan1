extends RefCounted
## Shared character tags, synergies and combat upgrades for the campus battle.
const MANIFEST = preload("res://resources/combat/manifest.tres")
const Validator = preload("res://game/content/combat_content_validator.gd")
static var CONTENT_ERRORS: Array[String] = Validator.validate(MANIFEST)

static func character(id: String):
	for entry in MANIFEST.characters:
		if entry.id == id: return entry
	return null

static func synergy(id: String):
	for entry in MANIFEST.synergies:
		if entry.id == id: return entry
	return null

static func reward(id: String):
	for entry in MANIFEST.rewards:
		if entry.id == id: return entry
	return null

static func validate(content = MANIFEST) -> Array[String]:
	return Validator.validate(content)
