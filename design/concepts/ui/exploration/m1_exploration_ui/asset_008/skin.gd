extends RefCounted

static func texture(path: String) -> ImageTexture:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert(image != null)
	image = image.get_region(image.get_used_rect())
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
