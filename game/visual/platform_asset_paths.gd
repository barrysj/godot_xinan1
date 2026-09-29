extends RefCounted

## Runtime delivery variants. The art Manifest tracks approval; this table only
## maps source paths to files included by each export preset.
const VARIANTS: Dictionary = {
	"web": [
		{
			"source_prefix": "res://assets/art/backgrounds/m1_campus_locations/",
			"target_prefix": "res://assets/art/web_backgrounds/m1_campus_locations/",
			"source_extension": ".png",
			"target_extension": ".webp",
		},
		{
			"source_prefix": "res://assets/art/backgrounds/m1_main_menu/",
			"target_prefix": "res://assets/art/web_backgrounds/m1_main_menu/",
			"source_extension": ".png",
			"target_extension": ".webp",
		},
	],
}


static func current_platform() -> String:
	if OS.has_feature("web"):
		return "web"
	return OS.get_name().to_lower()


static func resolve(source_path: String) -> String:
	return for_platform(source_path, current_platform())


static func for_platform(source_path: String, platform: String) -> String:
	for rule in VARIANTS.get(platform.to_lower(), []):
		var source_prefix: String = rule.source_prefix
		var source_extension: String = rule.source_extension
		if source_path.begins_with(source_prefix) and source_path.ends_with(source_extension):
			var relative_path := source_path.trim_prefix(source_prefix)
			return rule.target_prefix + relative_path.trim_suffix(source_extension) + rule.target_extension
	return source_path
