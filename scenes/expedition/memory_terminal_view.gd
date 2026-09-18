extends PanelContainer
class_name MemoryTerminalView
## Dedicated diegetic presentation for the three permanent memory terminals.

const TEXTURE_PATHS: Dictionary = {
	"library": "res://assets/art/icons/m1_memory_artifact/cyan_magenta.png",
	"region_b": "res://assets/art/icons/m1_memory_artifact/green_cyan.png",
	"region_c": "res://assets/art/icons/m1_memory_artifact/red_violet.png",
}
const REGION_NAMES: Dictionary = {
	"library": "图书馆终端",
	"region_b": "第二终端",
	"region_c": "第三终端",
}

var region_id: String = ""
var acquired: bool = false
var view_mode: String = "compact"
var finale_stage: int = 0
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily
var textures: Dictionary = {}

func setup(id: String, is_acquired: bool, mode: String = "compact", stage: int = 0) -> MemoryTerminalView:
	region_id = id
	acquired = is_acquired
	view_mode = mode
	finale_stage = stage
	_rebuild()
	return self

func _ready() -> void:
	if not region_id.is_empty(): _rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(palette.surface if acquired else palette.surface_blue)
	style.border_color = Color(palette.accent_secondary if acquired else palette.text_secondary)
	style.set_border_width_all(2 if acquired else 1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12 if view_mode == "compact" else 18)
	add_theme_stylebox_override("panel", style)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6 if view_mode == "compact" else 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(box)

	var picture := TextureRect.new()
	picture.texture = _texture_for(region_id)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.custom_minimum_size = Vector2(0, _image_height())
	picture.modulate = Color.WHITE if acquired else Color(0.42, 0.50, 0.54, 0.38)
	box.add_child(picture)

	var title := Label.new()
	title.text = REGION_NAMES.get(region_id, "记忆终端")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _title_size())
	title.add_theme_color_override("font_color", Color(palette.text_primary))
	box.add_child(title)

	var status := Label.new()
	status.text = _status_text()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 17 if view_mode == "compact" else 19)
	status.add_theme_color_override("font_color", Color(palette.accent_secondary if acquired else palette.text_secondary))
	box.add_child(status)

func _texture_for(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var path: String = TEXTURE_PATHS.get(id, "")
	if path.is_empty(): return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK:
		push_warning("记忆终端纹理读取失败：" + path)
		return null
	var texture: Texture2D = ImageTexture.create_from_image(image)
	textures[id] = texture
	return texture

func _image_height() -> float:
	match view_mode:
		"reveal": return 390.0
		"finale": return 188.0
		_: return 138.0

func _title_size() -> int:
	match view_mode:
		"reveal": return 30
		"finale": return 23
		_: return 21

func _status_text() -> String:
	if not acquired: return "未回收 · 通路受阻"
	match view_mode:
		"reveal": return "首次回收 · 永久保存"
		"finale": return "已接入终局 · 阶段 %d / 3" % maxi(finale_stage, 0)
		_: return "已回收 · 区域稳定"
