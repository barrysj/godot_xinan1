extends PanelContainer
var artwork: Texture2D
func _draw() -> void:
	if artwork != null: draw_texture_rect(artwork,Rect2(Vector2.ZERO,size),false)
