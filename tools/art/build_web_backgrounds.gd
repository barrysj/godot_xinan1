extends SceneTree

## Rebuild the Web-only, 1080p derivatives of approved 4K campus art.
## Run with: godot --headless --path . --script res://tools/art/build_web_backgrounds.gd

const SOURCE_ROOT := "res://assets/art/backgrounds"
const PlatformAssetPaths = preload("res://game/visual/platform_asset_paths.gd")
const SIZE := Vector2i(1920, 1080)
const QUALITY := 0.85


func _initialize() -> void:
	var sources: Array[String] = []
	var campus_root := SOURCE_ROOT.path_join("m1_campus_locations")
	for location in DirAccess.get_directories_at(campus_root):
		for state in ["daily", "anomaly"]:
			var source := campus_root.path_join(location).path_join(state + ".png")
			if FileAccess.file_exists(source):
				sources.append(source)
	for state in ["normal", "anomaly"]:
		var menu_root := SOURCE_ROOT.path_join("m1_main_menu").path_join(state)
		for filename in DirAccess.get_files_at(menu_root):
			if filename.ends_with(".png"):
				sources.append(menu_root.path_join(filename))
	sources.sort()
	if sources.size() != 30:
		push_error("Expected 24 campus and 6 menu backgrounds, found %d" % sources.size())
		quit(1)
		return
	var source_bytes := 0
	var target_bytes := 0
	for source in sources:
		var image := Image.load_from_file(ProjectSettings.globalize_path(source))
		if image == null or image.get_size() != Vector2i(3840, 2160):
			push_error("Expected a 3840x2160 source: " + source)
			quit(1)
			return
		var target := PlatformAssetPaths.for_platform(source, "web")
		if target == source:
			push_error("No Web variant configured for: " + source)
			quit(1)
			return
		var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
		if directory_error != OK:
			push_error("Cannot create output directory: " + target.get_base_dir())
			quit(1)
			return
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		var save_error := image.save_webp(ProjectSettings.globalize_path(target), true, QUALITY)
		if save_error != OK:
			push_error("Cannot write WebP: " + target)
			quit(1)
			return
		var source_file := FileAccess.open(source, FileAccess.READ)
		var target_file := FileAccess.open(target, FileAccess.READ)
		source_bytes += source_file.get_length()
		target_bytes += target_file.get_length()
		print("WEB_BACKGROUND %s -> %s (%d bytes)" % [source, target, target_file.get_length()])
	print("WEB_BACKGROUNDS count=%d sources=%d bytes derivatives=%d bytes" % [sources.size(), source_bytes, target_bytes])
	quit()
