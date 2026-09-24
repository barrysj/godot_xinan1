extends Control
## Semantic schematic, not a reconstruction of the real campus.
signal picked(index: int)
const Content = preload("res://game/content/content_db.gd")
const CampusLocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
var mode = "location"
var journey
var selected = 0
var font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var points: Array[Vector2] = []
var controls: Array[Control] = []
var location_background: Texture2D
const INK = Color("17202B")
const BLUE = Color("4AAFD0")

func _ready() -> void:
	custom_minimum_size = Vector2(820,680) if mode == "location" and journey != null and journey.visit.data.place == "gate" else Vector2(600,360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if mode == "location" and journey != null and journey.visit.data.place == "gate":
		location_background = ExplorationSkin.texture(CampusLocationSkin.path("south_gate", "anomaly"))
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_layout)
	_build()

func _node(label: String, at: Vector2, index: int, enabled: bool, hint: String) -> void:
	var item = Button.new()
	item.text = label
	item.tooltip_text = hint
	item.disabled = not enabled
	item.add_theme_font_size_override("font_size",20)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("F8FAFB") if enabled else Color("DDE7EB")
		style.border_color = BLUE if enabled else Color("99AAB5")
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		item.add_theme_stylebox_override(state,style)
	item.add_theme_color_override("font_color",INK)
	item.add_theme_color_override("font_hover_color",INK)
	item.add_theme_color_override("font_pressed_color",INK)
	item.add_theme_color_override("font_disabled_color",Color("677482"))
	item.pressed.connect(func(): selected = index; queue_redraw(); picked.emit(index))
	points.append(at)
	controls.append(item)
	add_child(item)

func _build() -> void:
	if mode == "route":
		for step in range(journey.data.map.size()):
			var choices = journey.data.map[step]
			for i in range(choices.size()):
				var at = Vector2(0.14+step*0.24,0.50 if choices.size() == 1 else 0.35+i*0.35)
				_node(journey.Regions.PLACES[choices[i]],at,i,step == journey.data.step,"选择目的地，查看详情后前往")
				if step < journey.data.step and journey.data.visited[step] == choices[i]:
					controls.back().add_theme_color_override("font_disabled_color",Color("207761"))
	else:
		var positions = [Vector2(0.20,0.72),Vector2(0.22,0.28),Vector2(0.53,0.65),Vector2(0.80,0.32)]
		for i in range(journey.visit.data.hotspots.size()):
			var spot = journey.visit.data.hotspots[i]
			var titles = {"battle":"守卫","memory":"回忆档案","person":"发明家","system":"借阅终端" if journey.visit.data.place == "library" else "系统终端"}
			_node(titles[spot.kind],positions[i],i,true,"点击查看；调查回忆与人物是可选行动")
	_layout()

func _layout() -> void:
	for i in range(controls.size()):
		controls[i].size = Vector2(132,48)
		controls[i].position = size*points[i]-controls[i].size/2
	queue_redraw()

func _label(at: Vector2, value: String, color: Color = INK, pixels: int = 17) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func _draw() -> void:
	if location_background != null:
		var image_size := location_background.get_size()
		var scale := maxf(size.x / image_size.x, size.y / image_size.y)
		var source_size := size / scale
		var source := Rect2((image_size - source_size) * 0.5, source_size)
		draw_texture_rect_region(location_background, Rect2(Vector2.ZERO,size), source)
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.025,0.065,0.30))
	else:
		draw_style_box(_surface(),Rect2(Vector2.ZERO,size))
	if journey == null: return
	if mode == "route":
		for step in range(3):
			for a in range(journey.data.map[step].size()):
				for b in range(journey.data.map[step+1].size()):
					var from = size*Vector2(0.14+step*0.24,0.50 if journey.data.map[step].size() == 1 else 0.35+a*0.35)
					var to = size*Vector2(0.14+(step+1)*0.24,0.50 if journey.data.map[step+1].size() == 1 else 0.35+b*0.35)
					draw_line(from,to,Color("A3BFCB"),4)
					var arrow = from.lerp(to,0.62)
					draw_line(arrow-Vector2(9,7),arrow,Color("677482"),2)
					draw_line(arrow-Vector2(9,-7),arrow,Color("677482"),2)
		for step in range(4):
			var state = "已通过" if step < journey.data.step else ("选择下一站" if step == journey.data.step else "尚未到达")
			_label(Vector2(size.x*(0.14+step*0.24)-50,44),"%d · %s" % [step+1,state],BLUE if step == journey.data.step else INK)
		_label(Vector2(20,size.y-20),"路线示意 · 每站胜利后继续前进，终点取得记忆终端")
	else:
		var library: bool = journey.visit.data.place == "library"
		# Readable floor plan assembled with native geometry, with no new bitmap assets.
		if library:
			for i in range(5):
				var shelf = Rect2(Vector2(size.x*(0.10+i*0.17),64),Vector2(size.x*0.12,46))
				draw_rect(shelf,Color("A7BDC5"))
				for book in range(6): draw_line(shelf.position+Vector2(9+book*12,5),shelf.position+Vector2(9+book*12,40),Color("E6F0F4"),3)
		elif location_background == null: _site(journey.visit.data.place)
		_label(Vector2(20,30),"阅览室 · 场景示意" if library else ("南门 · 异常态" if location_background != null else journey.Regions.PLACES[journey.visit.data.place]+" · 场景示意"),Color.WHITE if location_background != null else INK)
		var desk = Rect2(size*Vector2(0.42,0.38),size*Vector2(0.22,0.16))
		if library:
			draw_rect(desk,Color("CFBDA2"))
			draw_rect(Rect2(desk.position+Vector2(16,9),Vector2(33,24)),Color("F8FAFB"))
			_label(desk.position+Vector2(58,30),"阅读区")
		for i in range(journey.visit.data.hotspots.size()):
			var spot = journey.visit.data.hotspots[i]
			var at = size*points[i]
			var done: bool = journey.visit.data.guard_won if spot.kind == "battle" else journey.visit.data.viewed.has(spot.id)
			if i == selected: draw_rect(Rect2(at-Vector2(72,30),Vector2(144,60)),BLUE,false,3)
			_label(at+Vector2(-52,48),"已解除" if spot.kind == "battle" and done else ("已查看" if done else ("主线必经" if spot.kind == "battle" else "可选调查")),Color.WHITE if location_background != null else INK)
			if spot.kind == "person": draw_texture_rect(Content.character(4).portrait,Rect2(at-Vector2(24,84),Vector2(48,48)),false)
			if spot.kind == "battle":
				var shield = PackedVector2Array([at+Vector2(-18,-72),at+Vector2(18,-72),at+Vector2(18,-48),at+Vector2(0,-37),at+Vector2(-18,-48)])
				draw_colored_polygon(shield,Color("3D8F78") if done else Color("B76560"))
				_label(at+Vector2(-9,-49),"✓" if done else "!",Color.WHITE,23)
		_label(Vector2(20,size.y-20),"出口已开放 · 可以离开，也可以继续调查" if journey.visit.can_leave() else "出口封锁 · 击败守卫并领取奖励后开放",Color.WHITE if location_background != null else BLUE)

func _site(place: String) -> void:
	var middle = size.x*0.52
	match place:
		"gate":
			draw_rect(Rect2(middle-100,68,200,228),Color("CCDCE1"))
			for x in [middle-120,middle+92]: draw_rect(Rect2(x,72,28,140),Color("8AA8B5"))
			draw_rect(Rect2(middle-140,52,280,38),Color("8AA8B5"))
			_label(Vector2(middle-42,78),"校园入口",Color.WHITE,21)
		"walk":
			draw_line(Vector2(size.x*0.1,220),Vector2(size.x*0.9,160),Color("C8C2AF"),68)
			for i in range(6): draw_circle(Vector2(size.x*(0.1+i*0.15),70 if i%2 == 0 else 285),23,Color("8CB7A0"))
		"court":
			var court = Rect2(size*Vector2(0.34,0.18),size*Vector2(0.40,0.64))
			draw_rect(court,Color("ABCBBF"))
			draw_rect(court.grow(-12),Color("F8FAFB"),false,3)
			draw_line(Vector2(court.get_center().x,court.position.y+12),Vector2(court.get_center().x,court.end.y-12),Color.WHITE,3)
			draw_arc(court.get_center(),34,0,TAU,40,Color.WHITE,3)
		"hall":
			draw_rect(Rect2(size*Vector2(0.08,0.4),size*Vector2(0.84,0.23)),Color("CCDCE1"))
			for i in range(4):
				var door = Rect2(size.x*(0.31+i*0.15),58,64,75)
				draw_rect(door,Color("8AA8B5"))
				draw_rect(door.grow(-10),Color("DFECF1"))
		_:
			draw_rect(Rect2(middle-60,80,120,130),Color("8AA8B5"))
			draw_rect(Rect2(middle-45,95,90,65),Color("C9E5E6"))
			_label(Vector2(middle-42,195),"终端节点")

func _surface() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("E6F0F4")
	style.border_color = Color("AEC6D0")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
