extends Control
signal inspected(text: String)
## Read-only projection of the shared battle positions.
var simulation
var font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for u in simulation.units:
			if point(u.position).distance_to(event.position) < 35:
				inspected.emit("%s · 生命%d/%d · 护盾%d · 攻击%d · 防御%d · 攻击间隔%.2f秒 · 伤害贡献%d" % [u.name, u.hp, u.max_hp, u.shield, u.atk, u.def, u.interval, u.damage])
				accept_event()
				return

func _get_tooltip(at_position: Vector2) -> String:
	if simulation != null:
		for u in simulation.units:
			if point(u.position).distance_to(at_position) < 35: return u.name + " · 点击查看属性与贡献"
	return ""

func point(position_in_board: Vector2) -> Vector2:
	return Vector2(85 + (6 - position_in_board.y) / 6.0 * (size.x - 170), 65 + position_in_board.x / 6.0 * (size.y - 135))

func _draw() -> void:
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	if simulation == null: return
	for y in range(7):
		var x = 85 + y / 6.0 * (size.x - 170)
		draw_line(Vector2(x, 35), Vector2(x, size.y - 30), Color(0.2, 0.45, 0.5, 0.16))
	for u in simulation.units:
		if u.hp <= 0: continue
		var p = point(u.position)
		var color = Color("6ce4c1") if u.side == 0 else Color("ff948c")
		draw_circle(p, 19, Color("172c3e"))
		draw_arc(p, 20, 0, TAU, 32, color, 2)
		if u.portrait != null: draw_texture_rect(u.portrait, Rect2(p - Vector2(15, 17), Vector2(30, 30)), false)
		draw_string(font, p + Vector2(-35, 6), str(u.id + 1), HORIZONTAL_ALIGNMENT_LEFT, 20, 17, color)
		draw_rect(Rect2(p + Vector2(-20, 22), Vector2(40, 4)), Color("253341"))
		draw_rect(Rect2(p + Vector2(-20, 22), Vector2(40 * u.hp / u.max_hp, 4)), color)
		if simulation.marks.has(u.id): draw_arc(p, 24, 0, TAU, 32, Color("ffd87e"), 3)
	for shot in simulation.projectiles:
		draw_circle(point(shot.position), 5, Color("ffd87e"))

func _panel() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("0c1928")
	style.set_corner_radius_all(14)
	return style
