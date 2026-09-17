extends RefCounted
## Runtime preparation for the approved exploration UI images.

static func texture(path: String) -> ImageTexture:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null and not image.is_empty())
	var used := image.get_used_rect()
	assert(used.size.x > 0 and used.size.y > 0)
	image = image.get_region(used)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
