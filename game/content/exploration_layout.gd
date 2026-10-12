@tool
extends Node2D
## Native 2D authoring canvas. Direct Marker2D children use 1920 x 1080 coordinates.
@export var background: Texture2D:
	set(value):
		background = value
		queue_redraw()
const CANVAS := Vector2(1920,1080)

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	if background != null:
		var source := background.get_size()
		var scale_factor := maxf(CANVAS.x/source.x,CANVAS.y/source.y)
		var crop := CANVAS/scale_factor
		draw_texture_rect_region(background,Rect2(Vector2.ZERO,CANVAS),Rect2((source-crop)/2,crop))
	draw_rect(Rect2(Vector2.ZERO,CANVAS),Color.CYAN,false,2)
	# Reference HUD exclusion zones; final placement must still be checked in game.
	for rect in [Rect2(1594,84,306,292),Rect2(20,928,620,72),Rect2(20,18,330,70)]:
		draw_rect(rect,Color(1,0.3,0.5,0.18))

func snapshot() -> Dictionary:
	var points := {}
	for child in get_children():
		if child is Marker2D:
			points[str(child.name)] = [child.position.x/CANVAS.x,child.position.y/CANVAS.y]
	if position != Vector2.ZERO or scale != Vector2.ONE or rotation != 0: points["invalid_root_transform"] = []
	return points
