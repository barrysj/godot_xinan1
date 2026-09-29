extends Node

const CampusLocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
const PlatformAssetPaths = preload("res://game/visual/platform_asset_paths.gd")

var menu: Control


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var checked := 0
	var failures := 0
	for location in CampusLocationSkin.LOCATIONS:
		for state in CampusLocationSkin.STATES:
			var path := CampusLocationSkin.path(location.id, state)
			if not _valid(path):
				failures += 1
			checked += 1
	for background in menu.BACKGROUNDS:
		for state in ["normal", "anomaly"]:
			var path: String = PlatformAssetPaths.resolve(background[state])
			if not _valid(path):
				failures += 1
			checked += 1
	print("WEB_BACKGROUND_CHECK checked=%d failures=%d" % [checked, failures])
	if failures > 0:
		return
	var preview := TextureRect.new()
	preview.texture = load(CampusLocationSkin.path("south_gate", "anomaly")) as Texture2D
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(preview)


func _valid(path: String) -> bool:
	var texture := load(path) as Texture2D
	if texture == null or texture.get_size() != Vector2(1920, 1080):
		push_error("Missing or wrong-sized Web background: " + path)
		return false
	return true
