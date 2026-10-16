extends Control
## Team stock is separate from per-unit generation and team shield absorption.
const Codes = preload("res://game/combat/code_catalog.gd")
const StatusArt = preload("res://scenes/battle_demo/status_skin.gd")
var kind := "red"
var count := 0
var capacity := 6
var caption := ""
var absorbed := 0.0
var pulse := 0.0
var reduced_motion := false
var compact := false
var slim := false
var cycle_ratio := -1.0

func _init() -> void:
	custom_minimum_size = Vector2(174,52)
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(type: String,amount: int,slots: int,title: String = "") -> void:
	kind = type
	count = amount
	capacity = slots
	caption = title
	queue_redraw()

func celebrate() -> void:
	pulse = 0.22
	queue_redraw()

func _process(delta: float) -> void:
	if pulse <= 0: return
	pulse = maxf(0,pulse-delta)
	queue_redraw()

func _draw() -> void:
	if slim:
		_draw_slim()
		return
	if compact:
		_draw_compact()
		return
	var data: Dictionary = Codes.RULES.types[kind]
	var tint: Color = data.color
	var font := get_theme_font("font")
	StatusArt.draw(self,"stock_frame",Rect2(Vector2.ZERO,Vector2(174,52)))
	StatusArt.draw(self,"code_tile",Rect2(9,11,30,30),tint)
	StatusArt.draw(self,"code_"+kind,Rect2(13,15,22,22),Color("11151c"))
	draw_string(font,Vector2(48,18),data.name if caption.is_empty() else caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("cdd9e1"))
	draw_string(font,Vector2(47,44),"%d / %d" % [count,capacity],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f4f8fc"))
	var node_y := 33
	if kind == "purple":
		draw_string(font,Vector2(108,14),"全队吸收",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d6c7ee"))
		draw_string(font,Vector2(108,29),"%d/%d" % [int(absorbed),int(Codes.RULES.shield_per_block)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f4f8fc"))
		draw_rect(Rect2(108,33,54,3),Color("394653"))
		draw_rect(Rect2(108,33,54*clampf(absorbed/Codes.RULES.shield_per_block,0,1),3),tint)
		node_y = 40
	for i in range(capacity):
		StatusArt.draw(self,"slot_filled" if i<count else "slot_empty",Rect2(106+i*10,node_y,9,9),tint if i<count else Color.WHITE)
	if count >= capacity and kind != "purple":
		draw_string(font,Vector2(140,18),"已满",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f4f8fc"))
	if pulse > 0 and not reduced_motion:
		StatusArt.draw(self,"stock_focus",Rect2(Vector2.ZERO,Vector2(174,52)),Color(tint,pulse/0.22))

func _draw_compact() -> void:
	var tint: Color = Codes.RULES.types[kind].color
	var font := get_theme_font("font")
	draw_rect(Rect2(Vector2.ZERO,size),Color("15232e",0.65))
	StatusArt.draw(self,"code_"+kind,Rect2(6,6,20,20),tint)
	draw_string(font,Vector2(32,22),Codes.RULES.types[kind].name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("abbcc8"))
	draw_string(font,Vector2(65,23),"%d/%d" % [count,capacity],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f4f8fc"))
	if kind == "purple":
		var threshold: int = int(Codes.RULES.shield_per_block)
		var shown := threshold if cycle_ratio >= 0 else int(absorbed)
		draw_string(font,Vector2(112,19),"吸收 %d/%d" % [shown,threshold],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d6c7ee"))
		var ratio := cycle_ratio if cycle_ratio >= 0 else clampf(absorbed/threshold,0,1)
		draw_rect(Rect2(112,24,94,3),Color("394653"))
		draw_rect(Rect2(112,24,94*ratio,3),tint)
	elif count >= capacity:
		draw_circle(Vector2(117,16),3,tint)
	if pulse > 0 and not reduced_motion:
		draw_rect(Rect2(4,4,24,24),Color(tint,pulse/0.22),false,1.5)

func _draw_slim() -> void:
	var data: Dictionary = Codes.RULES.types[kind]
	var tint: Color = data.color
	draw_rect(Rect2(Vector2.ZERO,size),Color("1d303f"))
	draw_rect(Rect2(0,0,2,size.y),tint)
	StatusArt.draw(self,"code_"+kind,Rect2(7,4,18,18),tint)
	draw_string(get_theme_font("font"),Vector2(31,18),data.name,HORIZONTAL_ALIGNMENT_LEFT,32,11,Color("bacbd5"))
	draw_string(get_theme_font("font"),Vector2(67,19),"%d/%d" % [count,capacity],HORIZONTAL_ALIGNMENT_LEFT,40,15,Color.WHITE)
	if kind == "purple":
		var ratio := cycle_ratio if cycle_ratio >= 0 else clampf(absorbed/Codes.RULES.shield_per_block,0,1)
		draw_rect(Rect2(4,24,(size.x-8)*ratio,2),tint)
	tooltip_text = "%s %d/%d" % [data.name,count,capacity]
	if kind == "purple": tooltip_text += " · 吸收 %d/%d" % [int(absorbed),int(Codes.RULES.shield_per_block)]
