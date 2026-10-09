extends RefCounted
## Launch-only configuration. No simulation clock, save state or animation state.
const Presets = preload("res://game/combat/demo_battle_presets.gd")
const CURRENT = {
	"guard": "res://assets/art/characters/guard/battle_animation.tres",
	"archer": "res://assets/art/characters/archer/battle_animation.tres",
	"striker": "res://assets/art/characters/striker/battle_animation.tres",
	"healer": "res://assets/art/characters/healer/battle_animation.tres",
	"inventor": "res://assets/art/characters/inventor/battle_animation.tres"
}
var difficulty := ""
var animations := "formal"
var resolution := Vector2i.ZERO
var overrides := {}
var error := ""

func configure(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if argument.begins_with("--demo-difficulty="):
			difficulty = argument.trim_prefix("--demo-difficulty=").to_lower()
		elif argument.begins_with("--demo-animations="):
			animations = argument.trim_prefix("--demo-animations=").to_lower()
		elif argument.begins_with("--demo-size="):
			var size = argument.trim_prefix("--demo-size=")
			if size not in ["1920x1080", "2560x1440", "1920x1200"]:
				error = "Unknown demo size: " + size
				return false
			var parts = size.split("x")
			resolution = Vector2i(parts[0].to_int(), parts[1].to_int())
	if difficulty == "manual": difficulty = ""
	if not difficulty.is_empty() and not Presets.ORDER.has(difficulty):
		error = "Unknown demo difficulty: " + difficulty
		return false
	if animations not in ["current", "formal"]:
		error = "Unknown demo animation set: " + animations
		return false
	if animations == "formal": return true
	for id in CURRENT:
		if not FileAccess.file_exists(CURRENT[id]):
			error = "Formal animation is missing: " + CURRENT[id] + "."
			return false
	for id in CURRENT:
		var animation = load(CURRENT[id])
		if animation == null or animation.frames == null:
			error = "Cannot load formal animation: " + CURRENT[id]
			break
		for clip in animation.frames.get_animation_names():
			for index in animation.frames.get_frame_count(clip):
				if animation.frames.get_frame_texture(clip, index) == null:
					error = "Missing formal frame: " + CURRENT[id]
		if not error.is_empty(): break
		overrides[id] = animation
	return error.is_empty()

func preset() -> Dictionary:
	return Presets.preset(difficulty)

func cycle() -> void:
	difficulty = Presets.next(difficulty)

func caption() -> String:
	return preset().get("name", "手动") + "战斗 · " + ("当前动画" if animations == "current" else "正式动画")
