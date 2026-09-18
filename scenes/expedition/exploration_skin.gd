extends RefCounted
## Runtime preparation for the approved exploration UI images.

const LIBRARY_ENVIRONMENT_PATHS: Dictionary = {
	"daily": {
		"atrium-down": "res://assets/art/backgrounds/m1_library/daily/atrium-down.png",
		"window-corridor": "res://assets/art/backgrounds/m1_library/daily/window-corridor.png",
		"shelf-to-atrium": "res://assets/art/backgrounds/m1_library/daily/shelf-to-atrium.png",
	},
	"night": {
		"atrium-down": "res://assets/art/backgrounds/m1_library/night/atrium-down.png",
		"window-corridor": "res://assets/art/backgrounds/m1_library/night/window-corridor.png",
		"shelf-to-atrium": "res://assets/art/backgrounds/m1_library/night/shelf-to-atrium.png",
	},
	"anomaly": {
		"atrium-down": "res://assets/art/backgrounds/m1_library/anomaly/atrium-down.png",
		"window-corridor": "res://assets/art/backgrounds/m1_library/anomaly/window-corridor.png",
		"shelf-to-atrium": "res://assets/art/backgrounds/m1_library/anomaly/shelf-to-atrium.png",
	},
}

const LIBRARY_ENVIRONMENT_STATES: Array[String] = ["daily", "night", "anomaly"]
const LIBRARY_ENVIRONMENT_VIEWPOINTS: Array[String] = ["atrium-down", "window-corridor", "shelf-to-atrium"]

static func library_environment_path(state: String, viewpoint: String) -> String:
	var state_paths: Variant = LIBRARY_ENVIRONMENT_PATHS.get(state, {})
	if not state_paths is Dictionary:
		return ""
	return str(state_paths.get(viewpoint, ""))

static func texture(path: String) -> ImageTexture:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null and not image.is_empty())
	var used := image.get_used_rect()
	assert(used.size.x > 0 and used.size.y > 0)
	image = image.get_region(used)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
