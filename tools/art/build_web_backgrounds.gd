extends SceneTree

## Rebuild or check the Web-only, 1080p derivatives of approved 4K campus art.
## Run with: godot --headless --path . --script res://tools/art/build_web_backgrounds.gd
## Add: -- --check to validate existing derivatives without rewriting them.

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
			if not FileAccess.file_exists(source):
				_fail("Missing campus state image: " + source)
				return
			sources.append(source)
	for state in ["normal", "anomaly"]:
		var menu_root := SOURCE_ROOT.path_join("m1_main_menu").path_join(state)
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(menu_root)):
			_fail("Missing menu image directory: " + menu_root)
			return
		var menu_count := 0
		for filename in DirAccess.get_files_at(menu_root):
			if filename.ends_with(".png"):
				sources.append(menu_root.path_join(filename))
				menu_count += 1
		if menu_count == 0:
			_fail("No menu images in: " + menu_root)
			return
	sources.sort()
	if sources.is_empty():
		_fail("No Web background sources found")
		return
	var check_only := OS.get_cmdline_user_args().has("--check")
	var source_bytes := 0
	var target_bytes := 0
	for source in sources:
		var image := Image.load_from_file(ProjectSettings.globalize_path(source))
		if image == null or image.get_size() != Vector2i(3840, 2160):
			_fail("Expected a 3840x2160 source: " + source)
			return
		var target := PlatformAssetPaths.for_platform(source, "web")
		if target == source:
			_fail("No Web variant configured for: " + source)
			return
		if check_only:
			var existing := Image.load_from_file(ProjectSettings.globalize_path(target))
			if existing == null or existing.get_size() != SIZE:
				_fail("Missing or wrong-sized WebP derivative: " + target)
				return
		else:
			var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
			if directory_error != OK:
				_fail("Cannot create output directory: " + target.get_base_dir())
				return
			image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
			var save_error := image.save_webp(ProjectSettings.globalize_path(target), true, QUALITY)
			if save_error != OK:
				_fail("Cannot write WebP: " + target)
				return
		var source_file := FileAccess.open(source, FileAccess.READ)
		var target_file := FileAccess.open(target, FileAccess.READ)
		source_bytes += source_file.get_length()
		target_bytes += target_file.get_length()
		if not check_only:
			print("WEB_BACKGROUND %s -> %s (%d bytes)" % [source, target, target_file.get_length()])
	print("WEB_BACKGROUNDS%s count=%d sources=%d bytes derivatives=%d bytes" % ["_CHECK" if check_only else "", sources.size(), source_bytes, target_bytes])
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
