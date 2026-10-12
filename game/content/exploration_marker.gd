@tool
extends Marker2D
## Move with Godot's 2D tool; the node name binds to the existing hotspot kind.
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
func _draw() -> void:
	if not Engine.is_editor_hint(): return
	var labels := {"memory":"校园记忆","person":"同行伙伴","system":"终端线索","battle":"封锁守卫","passage":"通道"}
	draw_circle(Vector2.ZERO,59,Color(0,0.9,1,0.18))
	draw_arc(Vector2.ZERO,59,0,TAU,40,Color.CYAN,2,true)
	draw_string(FONT,Vector2(-64,-67),labels.get(str(name),str(name)),HORIZONTAL_ALIGNMENT_CENTER,128,22,Color.WHITE)
