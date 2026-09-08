extends Control
signal closed
var game: Control
var editable = false
var content: Control
var selected_role = 0
var tab = 0
var details: RichTextLabel
var stats: Label
var title: Label
var roster_box: VBoxContainer
var actions: HBoxContainer
var slot_box: HBoxContainer
var tabs: Array[Button] = []
var portrait: TextureRect
const INK = Color("fff9ee")
const MUTED = Color("c2bdc9")
const ACCENT = Color("ff4562")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var skin = Theme.new()
	skin.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	skin.default_font_size = 19
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("202027") if state != "pressed" else Color("b4213c")
		style.border_color = ACCENT if state in ["focus","hover"] else Color("79737f")
		style.set_border_width_all(1)
		style.set_corner_radius_all(0)
		style.skew = Vector2(-0.06,0)
		skin.set_stylebox(state,"Button",style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: skin.set_color(state,"Button",INK)
	skin.set_color("font_disabled_color","Button",MUTED)
	theme = skin
	var shade = preload("res://scenes/ui/comic_backdrop.gd").new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new()
	add_child(content)
	label_at("队伍作战终端",Vector2(45,28),30,INK)
	label_at("战前整备" if editable else "战斗快照 · 只读查看",Vector2(45,75),18,ACCENT)
	add_button("返回探索",Vector2(1070,33),Vector2(165,50),close_panel)
	roster_box = VBoxContainer.new()
	roster_box.position = Vector2(40,128)
	roster_box.size = Vector2(264,466)
	roster_box.add_theme_constant_override("separation",14)
	content.add_child(roster_box)
	panel_at(Rect2(332,128,906,148))
	title = label_at("",Vector2(448,151),29,INK)
	stats = label_at("",Vector2(448,205),18,MUTED)
	portrait = TextureRect.new()
	portrait.position = Vector2(354,158)
	portrait.size = Vector2(72,72)
	portrait.texture_filter = Control.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	content.add_child(portrait)
	for i in range(3):
		var item = add_button(["状态总览","装备配置","自动技能"][i],Vector2(333+i*304,297),Vector2(288,52),select_tab.bind(i))
		item.toggle_mode = true
		tabs.append(item)
	panel_at(Rect2(332,369,906,220))
	details = RichTextLabel.new()
	details.position = Vector2(357,388)
	details.size = Vector2(853,180)
	details.add_theme_color_override("default_color",INK)
	content.add_child(details)
	actions = HBoxContainer.new()
	actions.position = Vector2(333,609)
	actions.size = Vector2(905,54)
	actions.add_theme_constant_override("separation",12)
	content.add_child(actions)
	slot_box = HBoxContainer.new()
	slot_box.position = Vector2(333,609)
	slot_box.size = Vector2(905,54)
	slot_box.add_theme_constant_override("separation",10)
	content.add_child(slot_box)
	label_at("查看期间战斗暂停，返回后恢复原状态。",Vector2(420,686),15,MUTED)
	resized.connect(layout)
	layout()
	selected_role = game.selected if game.run.roster.has(game.selected) else 0
	refresh()
	tabs[0].grab_focus()

func panel_at(rect: Rect2) -> void:
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("19191f")
	style.set_corner_radius_all(0)
	style.border_color = Color("77717e")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",style)
	panel.position = rect.position
	panel.size = rect.size
	content.add_child(panel)

func label_at(text_value: String, at: Vector2, font_size: int, tint: Color) -> Label:
	var label = Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",tint)
	content.add_child(label)
	return label

func add_button(text_value: String, at: Vector2, extent: Vector2, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text_value
	button.position = at
	button.size = extent
	button.custom_minimum_size = Vector2(0,54)
	button.pressed.connect(callback)
	content.add_child(button)
	return button

func clear_box(box: Container) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func box_button(box: Container, text_value: String, callback: Callable, enabled: bool = true) -> void:
	var button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0,64 if box == roster_box else 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not enabled
	button.pressed.connect(callback)
	box.add_child(button)

func select_role(role: int) -> void:
	selected_role = role
	refresh()

func select_tab(index: int) -> void:
	tab = index
	refresh()

func refresh() -> void:
	clear_box(roster_box)
	for role in game.run.roster:
		box_button(roster_box,game.ROLES[role]+(" · 上阵" if game.formation.has(role) else " · 候补"),select_role.bind(role))
		roster_box.get_child(roster_box.get_child_count()-1).modulate = ACCENT if role == selected_role else Color.WHITE
	title.text = game.ROLES[selected_role]
	portrait.texture = game.Content.character(selected_role).portrait
	var unit = {}
	for candidate in game.units:
		if candidate.side == 0 and candidate.role == selected_role: unit = candidate
	stats.text = "候补中 · 可在状态页选择格子换入" if unit.is_empty() else "生命 %d / %d    攻击 %d    防御 %d    间隔 %.2f 秒" % [unit.hp,unit.max_hp,unit.atk,unit.def,unit.interval]
	for i in range(3): tabs[i].button_pressed = i == tab
	clear_box(actions)
	clear_box(slot_box)
	slot_box.visible = tab == 0
	actions.visible = tab == 1
	var gear = "厚笔记本 · 生命 +80" if game.run.badge_wearer == selected_role else ("篮球鞋 · 攻击间隔 -25%" if game.equipment == selected_role else "未装备")
	match tab:
		0:
			details.text = "当前装备    "+gear+"\n\n本局训练    %d 级（每级生命 +50 / 攻击 +5）\n永久加成    生命 +%d\n\n" % [game.run.training.get(selected_role,0),game.run.permanent_hp]
			details.text += "点击格子换位；选择候补再点已占用格可替换同学。" if editable else "战斗中阵型锁定。"
			for i in range(6):
				var occupant = game.formation[i]
				box_button(slot_box,("前" if i < 3 else "后")+str(i%3+1)+" · "+(game.ROLES[occupant] if occupant >= 0 else "空"),assign_slot.bind(i),editable and (game.formation.has(selected_role) or occupant >= 0))
		1:
			details.text = "当前装备    "+gear+"\n\n篮球鞋    缩短普通攻击间隔 25%\n厚笔记本    装备者生命上限 +80\n\n每人一件；换装时另一件自动退回背包。"
			box_button(actions,"篮球鞋",equip.bind("shoe"),editable)
			box_button(actions,"厚笔记本" if game.run.badge_owned else "未获得",equip.bind("badge"),editable and game.run.badge_owned)
			box_button(actions,"卸下装备",equip.bind("none"),editable)
		2:
			details.text = game.SKILLS[selected_role]+"\n\n触发规则    每 3 次普攻自动释放，无需手动操作。\n"
			if not unit.is_empty(): details.text += "当前进度    %d / 3 次普攻    护盾 %d\n" % [int(unit.count)%3,unit.shield]
			details.text += "\n当前角色的技能固定；可在战前通过换人、站位与装备调整战术。"

func assign_slot(index: int) -> void:
	if not editable: return
	var old = game.formation.find(selected_role)
	if old < 0 and game.formation[index] < 0: return
	if old >= 0: game.formation[old] = game.formation[index]
	game.formation[index] = selected_role
	apply_changes()

func equip(kind: String) -> void:
	if not editable: return
	if not game.run.equip_gear(kind, selected_role): return
	game.equipment = game.run.shoe_wearer
	apply_changes()

func apply_changes() -> void:
	game.selected = selected_role
	game._sync_team()
	game._build_units()
	game.paused = true
	refresh()
	if not game.last_save_ok: details.text += "\n保存失败，请返回后重试。"

func layout() -> void:
	var factor = minf(size.x/1280.0,size.y/720.0)
	content.scale = Vector2.ONE*factor
	content.position = (size-Vector2(1280,720)*factor)/2

func close_panel() -> void:
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ggt_debug_pause_game"):
		if event is InputEventKey and event.echo: return
		get_viewport().set_input_as_handled()
		close_panel()
