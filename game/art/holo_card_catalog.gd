extends RefCounted
## Resource-aware enumeration preserves original paths in exported packs.
const ROOT = "res://assets/art/holo_cards"
const Visual = preload("res://game/art/holo_card_visual.gd")

static func cards(root: String = ROOT) -> Array:
	var result: Array = []
	var directories = ResourceLoader.list_directory(root)
	directories.sort()
	for directory in directories:
		if not directory.ends_with("/") or directory.begins_with("."): continue
		var path = root.path_join(directory).path_join("card.tres")
		if not ResourceLoader.exists(path): continue
		var visual = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE)
		if not visual is Visual or visual.photo == null:
			push_warning("Skipping invalid holo card: " + path)
			continue
		result.append(visual)
	return result
