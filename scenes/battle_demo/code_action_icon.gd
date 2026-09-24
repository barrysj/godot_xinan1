extends Button
const Burst = preload("res://scenes/battle_demo/hack_burst.gd")
var action_id := ""
var tint := Color("76e5cb")
var available := false
var remaining := -1
func _ready() -> void:
	custom_minimum_size = Vector2(64,48)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("142432")
		style.border_color = tint if state in ["hover","focus"] else Color("486078")
		style.set_border_width_all(2 if state in ["hover","focus"] else 1)
		style.set_corner_radius_all(6)
		add_theme_stylebox_override(state,style)
func _draw() -> void:
	var color := tint if available else Color("7b8798")
	var center := size/2
	if available:
		draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color(tint,0.15))
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),tint,false,2)
	if action_id in ["supply","converter"]:
		draw_rect(Rect2(center-Vector2(13,12),Vector2(26,24)),color,false,2)
		draw_line(center-Vector2(8,0),center+Vector2(8,0),color,3)
		if action_id == "supply": draw_line(center-Vector2(0,8),center+Vector2(0,8),color,3)
		else:
			draw_line(center+Vector2(8,0),center+Vector2(3,-5),color,2)
			draw_line(center-Vector2(8,0),center-Vector2(3,-5),color,2)
	else:
		draw_set_transform(center+Vector2(22,0),0,Vector2.ONE*0.5)
		Burst.glyph(self,Vector2.ZERO,color,action_id,0.0)
		draw_set_transform(Vector2.ZERO)
	if remaining >= 0:
		draw_circle(Vector2(size.x-10,11),10,Color("314759"))
		draw_string(get_theme_font("font"),Vector2(size.x-20,17),str(remaining),HORIZONTAL_ALIGNMENT_CENTER,20,15,Color.WHITE)
