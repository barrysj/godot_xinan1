extends SceneTree
## Deterministic derivative of existing approved location backgrounds; no visual redesign.
const LocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")

func _initialize() -> void:
	_build.call_deferred()

func _build() -> void:
	var check_only := "--check" in OS.get_cmdline_user_args()
	for location in LocationSkin.LOCATIONS:
		for state in LocationSkin.STATES:
			var source := "res://assets/art/backgrounds/m1_campus_locations/%s/%s.png" % [location.id, state]
			var texture := load(source) as Texture2D
			var original := texture.get_image()
			var side := mini(original.get_width(), original.get_height())
			var crop := original.get_region(Rect2i((original.get_width()-side)/2, (original.get_height()-side)/2, side, side))
			crop.resize(128, 128, Image.INTERPOLATE_LANCZOS)
			var folder: String = "res://assets/art/map_thumbnails/" + location.id
			if check_only:
				if FileAccess.get_file_as_bytes(folder + "/" + state + ".png") != crop.save_png_to_buffer():
					push_error("Stale map thumbnail: " + folder + "/" + state)
					quit(1)
					return
				continue
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
			if crop.save_png(folder + "/" + state + ".png") != OK:
				quit(1)
				return
	print("MAP_THUMBNAILS ", "checked=" if check_only else "generated=", LocationSkin.LOCATIONS.size()*LocationSkin.STATES.size())
	quit()
