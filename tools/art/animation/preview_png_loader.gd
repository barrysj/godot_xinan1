extends ResourceFormatLoader
## Preview-only loader for concept PNGs excluded from editor import by design/.gdignore.

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["png"])

func _handles_type(type: StringName) -> bool:
	return type == &"Texture2D" or type == &"Resource"

func _get_resource_type(path: String) -> String:
	if path.begins_with("res://design/concepts/") and path.get_extension().to_lower() == "png":
		return "Texture2D"
	return ""

func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	if not path.begins_with("res://design/concepts/"):
		return ERR_FILE_UNRECOGNIZED
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return FileAccess.get_open_error()
	var image := Image.new()
	var error := image.load_png_from_buffer(bytes)
	if error != OK:
		return error
	return ImageTexture.create_from_image(image)
