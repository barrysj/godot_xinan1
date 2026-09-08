extends "res://scenes/team/team_panel.gd"
const Icon = preload("res://scenes/team/object_icon.gd")
var visual: Control
var popup: Control
var equipment_slot: Button
var bag_buttons: Dictionary = {}
var roster_visual: Control
var formation_buttons: Array[Button] = []
var candidate_buttons: Dictionary = {}
var formation_target = 0
var skill_buttons: Dictionary = {}
var health_bar: ProgressBar

func _ready() -> void:
	super._ready()
	visual = Control.new()
	visual.position = Vector2(332,369)
	visual.size = Vector2(906,295)
	content.add_child(visual)
	roster_visual = Control.new()
	roster_visual.position = Vector2(40,128)
	content.add_child(roster_visual)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(448,246)
	health_bar.size = Vector2(652,10)
	health_bar.show_percentage = false
	health_bar.add_theme_font_size_override("font_size",1)
	for part in ["background","fill"]:
		var style = StyleBoxFlat.new()
		style.bg_color = ACCENT if part == "fill" else Color("304653")
		style.set_corner_radius_all(5)
		health_bar.add_theme_stylebox_override(part,style)
	content.add_child(health_bar)
	refresh()

func refresh() -> void:
	super.refresh()
	if not is_instance_valid(visual): return
	health_bar.hide()
	for unit in game.units:
		if unit.side == 0 and unit.role == selected_role:
			health_bar.show()
			health_bar.value = 100.0*unit.hp/unit.max_hp
	roster_box.hide()
	for child in roster_visual.get_children():
		roster_visual.remove_child(child)
		child.queue_free()
	for i in range(game.run.roster.size()):
		var role = game.run.roster[i]
		var at = Vector2((i%2)*130,int(i/2)*153)
		var tile = icon(roster_visual,"empty",at,Vector2(111,103),select_role.bind(role),role)
		if role == selected_role: highlight(tile)
		caption(roster_visual,game.ROLES[role],at+Vector2(14,105),17)
		caption(roster_visual,"● 上阵" if game.formation.has(role) else "○ 候补",at+Vector2(16,128),14,ACCENT if game.formation.has(role) else MUTED)
	for child in visual.get_children():
		visual.remove_child(child)
		child.queue_free()
	visual.visible = true
	if tab == 0:
		details.hide()
		slot_box.hide()
		draw_formation()
	if tab == 1:
		details.hide()
		actions.hide()
		var equipped = equipped_kind()
		equipment_slot = icon(visual,equipped,Vector2(36,40),Vector2(125,125),open_bag)
		caption(visual,"装备槽",Vector2(62,181))
		caption(visual,"点击槽位查看与替换",Vector2(31,219),16,MUTED)
		caption(visual,"背包",Vector2(246,21),22,INK)
		var i = 0
		for kind in game.run.inventory:
			if kind == "badge" and not game.run.badge_owned: continue
			var tile = icon(visual,kind,Vector2(247+i*141,64),Vector2(110,110),open_bag)
			tile.tooltip_text = gear_name(kind)
			caption(visual,gear_name(kind),Vector2(252+i*141,188),16,MUTED)
			i += 1
		caption(visual,"每人 1 件",Vector2(690,95),22,ACCENT)
	elif tab == 2:
		details.hide()
		draw_skills()

func draw_skills() -> void:
	skill_buttons.clear()
	var names = ["shield","arrow","heart","bolt","flask"]
	skill_buttons.attack = icon(visual,"attack",Vector2(45,39),Vector2(114,114),open_skill.bind(false))
	skill_buttons.ability = icon(visual,names[selected_role],Vector2(353,39),Vector2(114,114),open_skill.bind(true))
	caption(visual,"普通攻击",Vector2(65,168),18)
	caption(visual,game.SKILLS[selected_role].split("：")[0],Vector2(375,168),18)
	caption(visual,"× 3   →",Vector2(212,74),26,ACCENT)
	var count = 0
	for unit in game.units:
		if unit.side == 0 and unit.role == selected_role: count = int(unit.count)%3
	for i in range(3):
		var pip = ColorRect.new()
		pip.position = Vector2(354+i*43,199)
		pip.size = Vector2(29,9)
		pip.color = ACCENT if i < count else Color("79737f")
		visual.add_child(pip)
	caption(visual,"%d / 3" % count,Vector2(493,190),17,MUTED)
	caption(visual,"自动释放",Vector2(631,59),25,ACCENT)
	caption(visual,"点击图标查看效果",Vector2(631,106),19)
	caption(visual,"角色专属 · 无需手动施放",Vector2(631,152),16,MUTED)

func open_skill(ability: bool) -> void:
	close_popup()
	popup = Control.new()
	popup.size = Vector2(1280,720)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(popup)
	var shade = ColorRect.new()
	shade.size = Vector2(1280,720)
	shade.color = Color(0.02,0.04,0.07,0.96)
	popup.add_child(shade)
	var glyph = ["shield","arrow","heart","bolt","flask"][selected_role] if ability else "attack"
	icon(popup,glyph,Vector2(305,246),Vector2(136,136),func(): pass)
	icon(popup,"remove",Vector2(1034,179),Vector2(48,48),close_popup)
	caption(popup,game.SKILLS[selected_role].split("：")[0] if ability else "普通攻击",Vector2(481,239),32,ACCENT)
	var description = RichTextLabel.new()
	description.position = Vector2(483,305)
	description.size = Vector2(577,230)
	description.text = (game.SKILLS[selected_role]+"\n\n每 3 次普攻自动触发。" if ability else "按角色的攻击间隔自动攻击。\n\n篮球鞋可以缩短攻击间隔，加快普攻和技能触发。")+"\n\n当前技能固定，通过角色、站位和装备配置改变战术。"
	popup.add_child(description)

func draw_formation() -> void:
	formation_buttons.clear()
	var background = Panel.new()
	background.size = Vector2(906,295)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("19191f")
	style.set_corner_radius_all(0)
	style.border_color = INK
	style.set_border_width_all(4)
	style.skew = Vector2(-0.025,0)
	style.shadow_color = ACCENT
	style.shadow_size = 7
	style.shadow_offset = Vector2(8,8)
	background.add_theme_stylebox_override("panel",style)
	visual.add_child(background)
	caption(visual,"前排",Vector2(8,46),16,MUTED)
	caption(visual,"后排",Vector2(8,181),16,MUTED)
	for i in range(6):
		var role = game.formation[i]
		var at = Vector2(61+(i%3)*140,10+int(i/3)*130)
		var tile = icon(visual,"empty",at,Vector2(113,100),open_formation_slot.bind(i),role)
		if role == selected_role: highlight(tile)
		formation_buttons.append(tile)
		if role >= 0: caption(visual,game.ROLES[role],at+Vector2(20,102),15,MUTED)
	caption(visual,"点选头像格",Vector2(535,37),24,INK)
	caption(visual,"查看同学 · 选择替换",Vector2(535,78),19,ACCENT)
	caption(visual,"上阵 4 / 4",Vector2(535,135),22)
	caption(visual,"点击空格可移动上阵同学" if editable else "战斗中阵容锁定",Vector2(535,185),17,MUTED)

func open_formation_slot(index: int) -> void:
	formation_target = index
	var role = game.formation[index]
	if role >= 0: select_role(role)
	close_popup()
	popup = Control.new()
	popup.size = Vector2(1280,720)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(popup)
	var shade = ColorRect.new()
	shade.color = Color(0.02,0.04,0.07,0.96)
	shade.size = Vector2(1280,720)
	popup.add_child(shade)
	caption(popup,("前排" if index < 3 else "后排")+str(index%3+1)+" / "+(game.ROLES[role] if role >= 0 else "空格"),Vector2(320,178),29)
	icon(popup,"remove",Vector2(1034,179),Vector2(48,48),close_popup)
	icon(popup,"empty",Vector2(320,244),Vector2(106,106),func(): pass,role)
	var text = "选择已上阵同学移动到这里。" if role < 0 else game.SKILLS[role]
	var description = RichTextLabel.new()
	description.text = text
	description.position = Vector2(461,254)
	description.size = Vector2(586,99)
	popup.add_child(description)
	caption(popup,"选择同学替换 / 换位" if editable else "战斗中只读",Vector2(321,379),21,ACCENT)
	candidate_buttons.clear()
	for i in range(game.run.roster.size()):
		var candidate = game.run.roster[i]
		var at = Vector2(321+i*148,430)
		var tile = icon(popup,"empty",at,Vector2(107,103),choose_candidate.bind(candidate),candidate)
		tile.disabled = not editable or (role < 0 and not game.formation.has(candidate))
		candidate_buttons[candidate] = tile
		caption(popup,game.ROLES[candidate],at+Vector2(12,111),17)
		caption(popup,"上阵" if game.formation.has(candidate) else "候补",at+Vector2(24,141),15,MUTED)

func choose_candidate(role: int) -> void:
	if not editable: return
	selected_role = role
	assign_slot(formation_target)
	close_popup()

func equipped_kind() -> String:
	return game.run.worn_gear(selected_role)

func highlight(tile: Button) -> void:
	var style = tile.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.border_color = ACCENT
	style.set_border_width_all(3)
	tile.add_theme_stylebox_override("normal",style)

func gear_name(kind: String) -> String:
	var item = game.RunModel.Content.gear(kind)
	return item.display_name if item != null else {"empty":"空槽","remove":"卸下装备"}.get(kind,kind)

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
	style.bg_color = Color("19191f")
	style.set_corner_radius_all(0)
	style.border_color = INK
	style.set_border_width_all(4)
	style.skew = Vector2(-0.025,0)
	style.shadow_color = ACCENT
	style.shadow_size = 7
	style.shadow_offset = Vector2(8,8)
	style.border_color = INK
	style.set_border_width_all(4)
	panel.add_theme_stylebox_override("panel",style)
	popup.add_child(panel)
	caption(popup,game.ROLES[selected_role]+" / 装备",Vector2(330,189),27)
	icon(popup,"remove",Vector2(1034,179),Vector2(48,48),close_popup)
	var equipped = equipped_kind()
	icon(popup,equipped,Vector2(335,253),Vector2(110,110),func(): pass)
	caption(popup,gear_name(equipped),Vector2(472,251),23,ACCENT)
	caption(popup,game.RunModel.Content.gear(equipped).description if equipped != "empty" else "选择背包中的装备填入此槽位",Vector2(472,299),18)
	caption(popup,"背包备选 · 点选即装备" if editable else "战斗中只读",Vector2(334,383),19,MUTED)
	bag_buttons.clear()
	var i = 0
	for kind in game.run.inventory.keys()+["remove"]:
		if kind == "badge" and not game.run.badge_owned: continue
		var tile = icon(popup,kind,Vector2(335+i*178,421),Vector2(92,92),choose_gear.bind(kind))
		tile.disabled = not editable or (kind == "remove" and equipped == "empty")
		bag_buttons[kind] = tile
		caption(popup,gear_name(kind),Vector2(337+i*178,527),17)
		var owner_role = int(game.run.inventory.get(kind,-1))
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
