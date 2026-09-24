extends RefCounted
## Bounded visual feedback only: all costs, healing and maintenance resolve upstream.
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const Floor = preload("res://scenes/battle_demo/battle_floor.gd")
const COLORS = {"disconnect":Color("#ff796c"),"redirect":Color("#54caff"),
	"repair":Color("#65efae"),"takeover":Color("#c69bff")}
const TITLES = {"disconnect":"链路熔断","redirect":"协议重定向","repair":"修复编译","takeover":"权限接管"}
const STATUS = {"disconnect":"已移除维护护盾 · 下次维护已阻断",
	"redirect":"指令已写入 · 下次维护转给我方","repair":"修复已送达受伤队员",
	"takeover":"维护系统已接管"}

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
	var color: Color = COLORS.get(p.id,Color.WHITE)
	var fade := minf(t*14.0,1.0)*clampf((1.0-t)*3.0,0,1)
	color.a = fade
	c.draw_set_transform(game.origin,0,Vector2.ONE*game.scale_factor)
	var center := Vector2(630,292)
	if reduced:
		c.draw_rect(Rect2(center-Vector2(120,58),Vector2(240,116)),Color("#142133",fade*0.90))
		glyph(c,center,color,p.id,1.0)
	else:
		# Thin world-space veil, never a fullscreen white flash or a hit-stop.
		c.draw_colored_polygon(Floor.stage_polygon(),Color("#101e31",fade*0.25))
		var release := clampf((t-0.22)/0.62,0,1)
		var charge := clampf(t/0.24,0,1)
		var burst_fade := fade*(1-release)
		var impact := pow(maxf(0,1-absf(t-0.30)/0.18),2)
		# A localized release flare and long data rays create the peak impact.
		for ring in range(8,0,-1):
			c.draw_circle(center,ring*11.0,Color(color,impact*0.022),true,-1,true)
		for ray in range(16):
			var direction := Vector2.from_angle(ray*TAU/16.0+0.12)
			direction.y *= 0.50
			glow_line(c,center+direction*52,center+direction*(120+impact*130),
				Color("#effaff",impact*0.8),1.2)
		# Sparse vertical code ribbons rise around the compiler, behind the emblem.
		for ribbon in range(11):
			var x := 390.0+ribbon*48.0
			var y := 230.0+fmod(ribbon*29.0+t*120.0,200.0)
			var ribbon_color := Color(color,fade*0.28*(1-release))
			c.draw_string(FONT,Vector2(x,y),["01","{}","<>","::"][ribbon%4],HORIZONTAL_ALIGNMENT_LEFT,-1,11,ribbon_color)
			glow_line(c,Vector2(x+6,y+12),Vector2(x+6,y+40),ribbon_color,1.0)
		for band in range(3):
			var radius := 50.0+release*(310.0+band*70.0)+band*14
			ellipse(c,Vector2(630,425),Vector2(radius,radius*0.34),Color(color,burst_fade*(0.75-band*0.16)),2.0)
		# Counter-rotating segmented compiler rings.
		for layer in range(3):
			var radius := 55.0+layer*22.0+sin(charge*PI)*12.0
			for segment in range(8):
				var angle := segment*TAU/8.0+t*(1.0 if layer%2 == 0 else -1.0)*2
				c.draw_arc(center,radius,angle,angle+0.42,12,Color(color,fade*(0.85-layer*0.18)),2.0,true)
		# Code tiles converge, then fragment into outward data streaks.
		for i in range(32):
			var angle := i*TAU/32.0
			var radial := 65.0+(1-charge)*180.0 if t < 0.24 else 65.0+release*(150.0+float(i%5)*29.0)
			var direction := Vector2(cos(angle),sin(angle)*0.57)
			var at := center+direction*radial
			var shard_color := Color(color,fade*(1-release*0.85))
			glow_line(c,at,at+direction*(8+release*29),shard_color,1.3)
			if i%3 == 0:
				c.draw_rect(Rect2(at-Vector2(3,3),Vector2(6,6)),shard_color)
		# Circuit rails terminate at field edges, not at fictitious hit targets.
		for side in [-1,1]:
			for lane in range(3):
				var a := center+Vector2(side*115,(lane-1)*29)
				var b := a+Vector2(side*(110+release*130),0)
				var d := b+Vector2(side*35,(lane-1)*38)
				glow_line(c,a,b,Color(color,fade*0.38),1.0)
				glow_line(c,b,d,Color(color,fade*0.38),1.0)
				c.draw_rect(Rect2(d-Vector2(4,4),Vector2(8,8)),Color(color,fade*0.65),false,1.5)
		# A crisp central program emblem anchors the bright particle layers.
		var diamond := PackedVector2Array([center+Vector2(0,-48),center+Vector2(48,0),
			center+Vector2(0,48),center+Vector2(-48,0)])
		c.draw_colored_polygon(diamond,Color("#101b2d",fade*0.90))
		diamond.append(diamond[0])
		c.draw_polyline(diamond,Color(color,fade*0.24),10.0,true)
		c.draw_polyline(diamond,color,2.0,true)
		glyph(c,center,color,p.id,charge)
		if t > 0.22:
			for id in p.targets:
				var actor = game.simulation.unit(id)
				if actor == null or actor.hp <= 0: continue
				var at: Vector2 = game._unit_center(actor)+Vector2(0,13)
				var line_fade := fade*clampf((t-0.22)*8,0,1)
				glow_line(c,center,at,Color(color,line_fade*0.45),1.7)
				ellipse(c,at,Vector2(38+release*22,13+release*8),Color(color,line_fade),2.2)
				if p.id == "repair":
					for i in range(4):
						var plus := at+Vector2((i-1.5)*19,-15-fmod(t*150+i*19,100))
						c.draw_line(plus-Vector2(4,0),plus+Vector2(4,0),color,2,true)
						c.draw_line(plus-Vector2(0,4),plus+Vector2(0,4),color,2,true)
	# The title stays below the resource HUD, away from the combat controls.
	c.draw_rect(Rect2(444,151,372,45),Color("#111d30",fade*0.88))
	c.draw_line(Vector2(444,196),Vector2(816,196),color,2,true)
	c.draw_string(FONT,Vector2(444,173),TITLES[p.id],HORIZONTAL_ALIGNMENT_CENTER,372,22,color)
	c.draw_string(FONT,Vector2(444,189),STATUS[p.id],HORIZONTAL_ALIGNMENT_CENTER,372,11,Color("#e7f6ff",fade))
	c.draw_set_transform(Vector2.ZERO)

static func glyph(c: CanvasItem, at: Vector2, color: Color, id: String, charge: float) -> void:
	match id:
		"disconnect":
			for side in [-1,1]:
				var offset := Vector2(side*(12+charge*8),0)
				glow_line(c,at+offset+Vector2(-8,-20),at+offset+Vector2(8,20),color,3)
			glow_line(c,at+Vector2(-8,22),at+Vector2(8,-22),Color("#fff4df",color.a),2)
		"redirect":
			for side in [-1,1]:
				var a := at+Vector2(-side*27,side*12)
				var b := at+Vector2(side*27,side*12)
				glow_line(c,a,b,color,3)
				glow_line(c,b,b+Vector2(-side*12,-10),color,3)
		"repair":
			glow_line(c,at-Vector2(24,0),at+Vector2(24,0),color,6)
			glow_line(c,at-Vector2(0,24),at+Vector2(0,24),color,6)
		"takeover":
			c.draw_rect(Rect2(at-Vector2(22,10),Vector2(44,32)),Color(color,color.a*0.16))
			c.draw_rect(Rect2(at-Vector2(22,10),Vector2(44,32)),color,false,2)
			c.draw_arc(at+Vector2(0,-10),15,PI,TAU,20,color,3,true)
			glow_line(c,at+Vector2(0,1),at+Vector2(0,13),Color("#fff3fd",color.a),3)
