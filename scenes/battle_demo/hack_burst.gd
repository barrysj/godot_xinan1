extends RefCounted
## Bounded visual feedback only: all costs, healing and maintenance resolve upstream.
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const Floor = preload("res://scenes/battle_demo/battle_floor.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
const COLORS = {"disconnect":Color("67d7ff"),"redirect":Color("be95ff"),"repair":Color("65efae")}
const STATUS = {"disconnect":"漏洞暴露 · 每名队友一次追击", "redirect":"限时护盾 · 失去后爆炸", "repair":"单目标修复已送达"}

static func glow_line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width := 2.0) -> void:
	c.draw_line(a,b,Color(color,color.a*0.10),width*8,true)
	c.draw_line(a,b,Color(color,color.a*0.23),width*3,true)
	c.draw_line(a,b,color,width,true)

static func ellipse(c: CanvasItem, at: Vector2, radius: Vector2, color: Color, width := 2.0) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		points.append(at+Vector2(cos(TAU*i/96.0),sin(TAU*i/96.0))*radius)
	c.draw_polyline(points,Color(color,color.a*0.15),width*5,true)
	c.draw_polyline(points,color,width,true)

static func draw(c: CanvasItem, game: Control, p: Dictionary, t: float, reduced: bool) -> void:
	var program = Codes.program(p.id)
	if program == null: return
	var fade := minf(t*12.0,1.0)*clampf((1.0-t)*4.0,0,1)
	var color: Color = COLORS.get(p.id,Color.WHITE)
	color.a = fade
	c.draw_set_transform(game.origin,0,Vector2.ONE*game.scale_factor)
	# Effects attach only to the actual recipients. Keep the field and warnings visible.
	for id in p.targets:
		var actor: Dictionary = game.simulation.unit(id)
		if actor.is_empty() or actor.hp <= 0: continue
		var at: Vector2 = game._unit_center(actor)
		ellipse(c,at+Vector2(0,13),Vector2(34,11)*(1.0 if reduced else 1.0+t*0.35),color,1.8)
		if p.id == "disconnect":
			for side in [-1,1]:
				var start := at+Vector2(side*25,-58)
				glow_line(c,start,start+Vector2(-side*9,0),color,2)
				glow_line(c,start,start+Vector2(0,12),color,2)
		elif p.id == "redirect":
			var shield := PackedVector2Array([at+Vector2(-23,-50),at+Vector2(23,-50),at+Vector2(20,-14),at+Vector2(0,-3),at+Vector2(-20,-14),at+Vector2(-23,-50)])
			c.draw_polyline(shield,color,2,true)
		else:
			var plus := at+Vector2(0,-58-(0 if reduced else t*18))
			glow_line(c,plus-Vector2(7,0),plus+Vector2(7,0),color,2)
			glow_line(c,plus-Vector2(0,7),plus+Vector2(0,7),color,2)
		if not reduced:
			for i in range(3):
				var point := at+Vector2((i-1)*18,-18-t*30-i*8)
				c.draw_rect(Rect2(point,Vector2(3,3)),Color(color,fade*.6))
	var box := Rect2(42,628,670,62)
	c.draw_rect(box,Color("111d30",fade*.9))
	c.draw_line(box.position+Vector2(0,62),box.position+Vector2(670,62),color,1.5,true)
	c.draw_string(FONT,box.position+Vector2(8,24),program.display_name,HORIZONTAL_ALIGNMENT_LEFT,670,19,color)
	c.draw_string(FONT,box.position+Vector2(8,48),STATUS.get(p.id,""),HORIZONTAL_ALIGNMENT_LEFT,670,12,Color("e7f6ff",fade))
	c.draw_set_transform(Vector2.ZERO)

static func glyph(c: CanvasItem, at: Vector2, color: Color, id: String, charge: float) -> void:
	match id:
		"disconnect":
			for side in [-1,1]:
				var offset := Vector2(side*(12+charge*8),0)
				glow_line(c,at+offset+Vector2(-8,-20),at+offset+Vector2(8,20),color,3)
			glow_line(c,at+Vector2(-8,22),at+Vector2(8,-22),Color("#fff4df",color.a),2)
		"redirect":
			var shield := PackedVector2Array([at+Vector2(-22,-22),at+Vector2(22,-22),at+Vector2(20,7),at+Vector2(0,24),at+Vector2(-20,7),at+Vector2(-22,-22)])
			c.draw_polyline(shield,color,3,true)
			glow_line(c,at+Vector2(4,-12),at+Vector2(-5,0),color,2)
			glow_line(c,at+Vector2(-5,0),at+Vector2(5,0),color,2)
			glow_line(c,at+Vector2(5,0),at+Vector2(-4,12),color,2)
		"repair":
			glow_line(c,at-Vector2(24,0),at+Vector2(24,0),color,6)
			glow_line(c,at-Vector2(0,24),at+Vector2(0,24),color,6)
		"takeover":
			c.draw_rect(Rect2(at-Vector2(22,10),Vector2(44,32)),Color(color,color.a*0.16))
			c.draw_rect(Rect2(at-Vector2(22,10),Vector2(44,32)),color,false,2)
			c.draw_arc(at+Vector2(0,-10),15,PI,TAU,20,color,3,true)
			glow_line(c,at+Vector2(0,1),at+Vector2(0,13),Color("#fff3fd",color.a),3)
