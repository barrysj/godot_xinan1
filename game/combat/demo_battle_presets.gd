extends RefCounted
## Developer samples; normal campaign encounter definitions remain authoritative.
const ORDER = ["easy", "normal", "hard"]
const PRESETS = {
	"easy": {"name": "简单", "encounter": "encounter_patrol", "health": 0.75, "attack": 0.8},
	"normal": {"name": "普通", "encounter": "encounter_patrol", "health": 1.0, "attack": 1.0},
	"hard": {"name": "困难", "encounter": "encounter_final", "health": 2.5, "attack": 1.0}
}

static func preset(difficulty: String) -> Dictionary:
	return PRESETS.get(difficulty, {})

static func next(difficulty: String) -> String:
	return ORDER[(ORDER.find(difficulty) + 1) % ORDER.size()]
