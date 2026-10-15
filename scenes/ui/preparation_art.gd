extends RefCounted
const ICONS = {
	"supply":preload("res://assets/art/ui/preparation/asset_001/supply.png"),
	"converter":preload("res://assets/art/ui/preparation/asset_001/converter.png"),
	"shield":preload("res://assets/art/ui/preparation/asset_001/shield.png"),
	"revive":preload("res://assets/art/ui/preparation/asset_001/revive.png"),
}

static func icon(parent: Node, id: String, extent: float = 64) -> TextureRect:
	var view := TextureRect.new()
	view.texture = ICONS.get(id)
	view.custom_minimum_size = Vector2.ONE * extent
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	return view
