extends Button
const Burst = preload("res://scenes/battle_demo/hack_burst.gd")
const ItemArt = preload("res://scenes/ui/preparation_art.gd")
var action_id := ""
var tint := Color("76e5cb")
var available := false
var remaining := -1
var ready_age := 1.0
var ready_notified := false
var program_card := false
func reset_readiness() -> void:
	available = false
	ready_notified = false
	ready_age = 1.0
func set_readiness(value: bool, reduced_motion: bool) -> void:
	if value and not ready_notified and not reduced_motion:
		ready_age = 0.0
		set_process(true)
	if value: ready_notified = true
	available = value
	if reduced_motion: ready_age = 1.0
	queue_redraw()
func _process(delta: float) -> void:
	ready_age += maxf(0,delta)
	queue_redraw()
	if ready_age >= 0.22: set_process(false)
func _ready() -> void:
	set_process(false)
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
	if ItemArt.ICONS.has(action_id):
		var extent := minf(size.x-8,size.y-4)
		draw_texture_rect(ItemArt.ICONS[action_id],Rect2(center-Vector2.ONE*extent/2,Vector2.ONE*extent),false,Color.WHITE if available else Color(0.6,0.6,0.6))
	else:
		draw_set_transform(Vector2(size.x-30,center.y) if program_card else center+Vector2(22,0),0,Vector2.ONE*0.5)
		Burst.glyph(self,Vector2.ZERO,color,action_id,0.0)
		draw_set_transform(Vector2.ZERO)
	if available and ready_age < 0.22:
		var t := ready_age/0.22
		var inset := 2.0+4.0*pow(1-t,3)
		draw_rect(Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2),Color(tint,1-t),false,3)
	if remaining >= 0:
		draw_circle(Vector2(size.x-10,11),10,Color("314759"))
		draw_string(get_theme_font("font"),Vector2(size.x-20,17),str(remaining),HORIZONTAL_ALIGNMENT_CENTER,20,15,Color.WHITE)
