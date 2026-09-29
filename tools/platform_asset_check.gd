extends Node

const PlatformAssetPaths = preload("res://game/visual/platform_asset_paths.gd")
const CampusLocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var checked := 0
	for location in CampusLocationSkin.LOCATIONS:
		for state in CampusLocationSkin.STATES:
			var source := "res://assets/art/backgrounds/m1_campus_locations/%s/%s.png" % [location.id, state]
			_check(source, failures)
			checked += 1
	for state in ["normal", "anomaly"]:
		var directory: String = "res://assets/art/backgrounds/m1_main_menu/" + state
		for filename in DirAccess.get_files_at(directory):
			if filename.ends_with(".png"):
				_check(directory.path_join(filename), failures)
				checked += 1
	if checked == 0:
		failures.append("no assets checked")
	var unrelated := "res://assets/art/backgrounds/m1_library/daily/atrium-down.png"
	if PlatformAssetPaths.for_platform(unrelated, "web") != unrelated:
		failures.append("unrelated art changed")
	if not CampusLocationSkin.path("invalid", "daily").is_empty():
		failures.append("invalid location accepted")
	if not CampusLocationSkin.path("south_gate", "invalid").is_empty():
		failures.append("invalid state accepted")
	print("PLATFORM_ASSET_CHECK checked=%d failures=%d platform=%s" % [checked, failures.size(), PlatformAssetPaths.current_platform()])
	for failure in failures:
		push_error(failure)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _check(source: String, failures: Array[String]) -> void:
	var web := PlatformAssetPaths.for_platform(source, "web")
	if web == source or not web.begins_with("res://assets/art/web_backgrounds/") or not web.ends_with(".webp"):
		failures.append("web mapping: " + source)
	if not FileAccess.file_exists(web):
		failures.append("missing web asset: " + web)
	if not FileAccess.file_exists(source):
		failures.append("missing source asset: " + source)
	if PlatformAssetPaths.for_platform(source, "android") != source:
		failures.append("android fallback: " + source)
	if PlatformAssetPaths.for_platform(source, "WEB") != web:
		failures.append("platform case: " + source)
	if PlatformAssetPaths.resolve(source) != source:
		failures.append("native selection: " + source)
