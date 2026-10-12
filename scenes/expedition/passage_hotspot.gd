extends "res://scenes/expedition/exploration_hotspot.gd"
## One navigation marker, reusing the original hotspot's motion and focus treatment.
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const PASSAGE = preload("res://assets/art/ui/place_scenes/passage.svg")
var destination := ""

func _ready() -> void:
	kind = "passage"
	artwork = PASSAGE
	super._ready()

func _draw() -> void:
	super._draw()
	var caption := Rect2(0,118,size.x,30)
	draw_rect(caption,Color(0.025,0.04,0.08,0.90))
	draw_string(FONT,Vector2(0,140),destination,HORIZONTAL_ALIGNMENT_CENTER,size.x,18,Color("b7c9d7") if disabled else Color("f7fbff"))
	if disabled:
		# Closed padlock, distinct from the completed-investigation checkmark.
		draw_arc(Vector2(91,79),7,PI,TAU,12,Color("b7c9d7"),2,true)
		draw_rect(Rect2(82,78,18,15),Color("b7c9d7"),false,2)
