extends Button
const PROGRAM_ART = preload("res://assets/art/ui/battle_actions/asset_001/programs.png")
const PROGRAM_CELLS = {"disconnect":0,"redirect":1,"repair":2}
const Burst = preload("res://scenes/battle_demo/hack_burst.gd")
const ItemArt = preload("res://scenes/ui/preparation_art.gd")
var action_id := ""
var tint := Color("76e5cb")
var available := false
var remaining := -1
var ready_age := 1.0
var ready_notified := false
var program_card := false
var state_code := ""
var cooldown_left := 0.0
var cooldown_duration := 1.0
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
		style.border_color = Color("e4eaf0") if state == "focus" else Color("8697a5") if state == "hover" else Color("486078")
		if state == "focus": style.bg_color = Color.TRANSPARENT
		style.set_border_width_all(2 if state in ["hover","focus"] else 1)
		style.set_corner_radius_all(6)
		add_theme_stylebox_override(state,style)
func _draw() -> void:
	var color := tint if available else Color("7b8798")
	var center := size/2
	if program_card and state_code in ["missing","cooldown","target","spent"]:
		var surface: Color = {"missing":Color("171d23"),"cooldown":Color("151e29"),"target":Color("191d26"),"spent":Color("272b31")}[state_code]
		var inset_surface := StyleBoxFlat.new()
		inset_surface.bg_color = surface
		inset_surface.set_corner_radius_all(4)
		draw_style_box(inset_surface,Rect2(Vector2(2,2),size-Vector2(4,4)))
	if available:
		draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color(tint,0.18))
		if not program_card: draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(tint,0.7),false,1)
	if ItemArt.ICONS.has(action_id):
		var extent := minf(size.x-8,size.y-4)
		draw_texture_rect(ItemArt.ICONS[action_id],Rect2(center-Vector2.ONE*extent/2,Vector2.ONE*extent),false,Color.WHITE if available else Color(0.6,0.6,0.6))
	elif PROGRAM_CELLS.has(action_id):
		var cell := PROGRAM_ART.get_height()
		var extent := minf(size.y-2,42)
		var at := Vector2(2,(size.y-extent)/2) if program_card else center-Vector2.ONE*extent/2
		draw_texture_rect_region(PROGRAM_ART,Rect2(at,Vector2.ONE*extent),Rect2(PROGRAM_CELLS[action_id]*cell,0,cell,cell),Color.WHITE if available else Color(0.38,0.40,0.43))
	else:
		draw_set_transform(Vector2(size.x-30,center.y) if program_card else center+Vector2(22,0),0,Vector2.ONE*0.5)
		Burst.glyph(self,Vector2.ZERO,color,action_id,0.0)
		draw_set_transform(Vector2.ZERO)
	if available and ready_age < 0.22:
		var t := ready_age/0.22
		var inset := 2.0+4.0*pow(1-t,3)
		draw_line(Vector2(inset,size.y-2),Vector2(size.x-inset,size.y-2),Color(tint,(1-t)*0.7),2,true)
	if program_card and state_code == "cooldown":
		var ratio := clampf(cooldown_left/maxf(cooldown_duration,0.01),0,1)
		draw_rect(Rect2(2,2,(size.x-4)*ratio,size.y-4),Color(0.04,0.09,0.15,0.32))
	if program_card and not state_code.is_empty():
		var accent: Color = {"ready":Color("72efcc"),"missing":Color("cc9b59"),"cooldown":Color("79b7ff"),"target":Color("e3abff"),"spent":Color("8d96a4")}.get(state_code,Color.WHITE)
		draw_line(Vector2(2,size.y-2),Vector2(size.x-2,size.y-2),accent,2,true)
		var badge := Rect2(size.x-34,3,31,size.y-6)
		# Status shares the card surface; a quiet separator replaces the inset tile.
		var divider_x := badge.position.x-2
		draw_line(Vector2(divider_x,8),Vector2(divider_x,size.y-8),Color("a4b6c5",0.22),1,true)
		var font := get_theme_font("font")
		if state_code == "ready":
			draw_string(font,Vector2(badge.position.x,size.y-10),"就绪",HORIZONTAL_ALIGNMENT_CENTER,31,10,accent)
		elif state_code == "cooldown":
			draw_string(font,Vector2(badge.position.x,size.y-9),"%.1f" % cooldown_left,HORIZONTAL_ALIGNMENT_CENTER,31,14,accent)
		else:
			var caption: String = {"missing":"缺码","target":"无目标","spent":"用尽"}.get(state_code,"")
			draw_string(font,Vector2(badge.position.x,size.y-10),caption,HORIZONTAL_ALIGNMENT_CENTER,31,10,Color("c2cbd3"))

	if remaining >= 0:
		draw_circle(Vector2(size.x-10,11),10,Color("314759"))
		draw_string(get_theme_font("font"),Vector2(size.x-20,17),str(remaining),HORIZONTAL_ALIGNMENT_CENTER,20,15,Color.WHITE)
