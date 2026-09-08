extends "res://scenes/team/team_panel.gd"
const Icon = preload("res://scenes/team/object_icon.gd")
var visual: Control
var popup: Control
var equipment_slot: Button
var bag_buttons: Dictionary = {}

func _ready() -> void:
	super._ready()
	visual = Control.new()
	visual.position = Vector2(332,369)
	visual.size = Vector2(906,295)
	content.add_child(visual)
	refresh()

func refresh() -> void:
	super.refresh()
	if not is_instance_valid(visual): return
	for child in visual.get_children():
		visual.remove_child(child)
		child.queue_free()
	visual.visible = tab == 1
	if tab == 1:
		details.hide()
		actions.hide()
		var equipped = equipped_kind()
		equipment_slot = icon(visual,equipped,Vector2(36,40),Vector2(125,125),open_bag)
		caption(visual,"装备槽",Vector2(62,181))
		caption(visual,"点击槽位查看与替换",Vector2(31,219),16,MUTED)
		caption(visual,"背包",Vector2(246,21),22,INK)
		var i = 0
		for kind in ["shoe","badge"]:
			if kind == "badge" and not game.run.badge_owned: continue
			var tile = icon(visual,kind,Vector2(247+i*141,64),Vector2(110,110),open_bag)
			tile.tooltip_text = gear_name(kind)
			caption(visual,gear_name(kind),Vector2(252+i*141,188),16,MUTED)
			i += 1
		caption(visual,"每人 1 件",Vector2(690,95),22,ACCENT)
	else: details.show()

func equipped_kind() -> String:
	return "badge" if game.run.badge_wearer == selected_role else ("shoe" if game.equipment == selected_role else "empty")

func gear_name(kind: String) -> String:
	return {"shoe":"篮球鞋","badge":"厚笔记本","empty":"空槽","remove":"卸下装备"}.get(kind,kind)

func icon(parent: Control, kind: String, at: Vector2, extent: Vector2, callback: Callable, role_value: int = -1) -> Button:
	var tile = Icon.new()
	tile.glyph = kind
	tile.role = role_value
	tile.position = at
	tile.size = extent
	tile.texture_filter = Control.TEXTURE_FILTER_NEAREST
	tile.pressed.connect(callback)
	parent.add_child(tile)
	return tile

func caption(parent: Control, text_value: String, at: Vector2, font_size: int = 18, tint: Color = INK) -> Label:
	var label = Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",tint)
	parent.add_child(label)
	return label

func open_bag() -> void:
	close_popup()
	popup = Control.new()
	popup.size = Vector2(1280,720)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(popup)
	var shade = ColorRect.new()
	shade.color = Color(0.02,0.04,0.07,0.9)
	shade.size = Vector2(1280,720)
	popup.add_child(shade)
	var panel = Panel.new()
	panel.position = Vector2(300,164)
	panel.size = Vector2(805,420)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("142735")
	style.set_corner_radius_all(16)
	style.border_color = ACCENT
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",style)
	popup.add_child(panel)
	caption(popup,game.ROLES[selected_role]+" / 装备",Vector2(330,189),27)
	icon(popup,"remove",Vector2(1034,179),Vector2(48,48),close_popup)
	var equipped = equipped_kind()
	icon(popup,equipped,Vector2(335,253),Vector2(110,110),func(): pass)
	caption(popup,gear_name(equipped),Vector2(472,251),23,ACCENT)
	caption(popup,"生命上限 +80" if equipped == "badge" else ("攻击间隔 -25%" if equipped == "shoe" else "选择背包中的装备填入此槽位"),Vector2(472,299),18)
	caption(popup,"背包备选 · 点选即装备" if editable else "战斗中只读",Vector2(334,383),19,MUTED)
	bag_buttons.clear()
	var i = 0
	for kind in ["shoe","badge","remove"]:
		if kind == "badge" and not game.run.badge_owned: continue
		var tile = icon(popup,kind,Vector2(335+i*178,421),Vector2(92,92),choose_gear.bind(kind))
		tile.disabled = not editable or (kind == "remove" and equipped == "empty")
		bag_buttons[kind] = tile
		caption(popup,gear_name(kind),Vector2(337+i*178,527),17)
		var owner_role = game.equipment if kind == "shoe" else (game.run.badge_wearer if kind == "badge" else -1)
		tile.tooltip_text = gear_name(kind)+(" · "+game.ROLES[owner_role]+"携带，点击转移" if owner_role >= 0 else "")
		i += 1

func choose_gear(kind: String) -> void:
	equip("none" if kind == "remove" else kind)
	open_bag()

func close_popup() -> void:
	if is_instance_valid(popup):
		content.remove_child(popup)
		popup.queue_free()
	popup = null

func _input(event: InputEvent) -> void:
	if is_instance_valid(popup) and (event.is_action_pressed("pause") or event.is_action_pressed("ggt_debug_pause_game")):
		if event is InputEventKey and event.echo: return
		get_viewport().set_input_as_handled()
		close_popup()
		return
	super._input(event)
