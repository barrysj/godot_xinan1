extends Control
## Contextual information and equipment exchange; no persistent side notebook.
const Codes = preload("res://game/combat/code_catalog.gd")
const Icon = preload("res://scenes/team/object_icon.gd")
var game: Control
var canvas: Control
var panel: PanelContainer
var heading: Label
var summary: Label
var bond_tags: RichTextLabel
var description: RichTextLabel
var face: TextureRect
var bond_section: VBoxContainer
var skill_section: VBoxContainer
var skill_name: Label
var skill_trigger: Label
var skill_icon: TextureRect
var combat_stats: Label
var attack_value: Label
var shield_value: Label
var allegiance: Label
var action_section: VBoxContainer
var action_name: Label
var action_target: Label
var generation: Label
var card_style: StyleBoxFlat
var gear_row: HBoxContainer
var gear_button: Button
var gear_name: Label
var hover_blocked_id := -1
var pinned := false
var focus_side := -1
var focus_key := -1
var observed: Dictionary = {}
var bag: PanelContainer
var shade: ColorRect
var bag_items: HBoxContainer
var bag_description: Label
var bag_heading: Label
var equip_button: Button
var bag_role := -1
var picked_item := "none"
var rendered_inventory := ""
var pointer := Vector2(-1000, -1000)
var theme_surface: Color
var theme_ink: Color
var theme_accent: Color

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	theme = preload("res://resources/theme/theme-main.tres")
	theme_surface = Color("132533",0.98)
	theme_ink = Color("eef5fa")
	theme_accent = Color("446477")
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	panel = _panel(Vector2(300, 0))
	card_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	canvas.add_child(panel)
	var column = _column(panel)
	var top = HBoxContainer.new()
	column.add_child(top)
	face = _image(top,"health",40)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",0)
	top.add_child(identity)
	heading = _label("", 19)
	heading.clip_text = true
	identity.add_child(heading)
	allegiance = _label("",10)
	identity.add_child(allegiance)
	var close = _button("收起", close_info.bind(true))
	top.add_child(close)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation",12)
	column.add_child(stats_row)
	_image(stats_row,"health",18).tooltip_text = "生命"
	summary = _label("",14)
	stats_row.add_child(summary)
	_image(stats_row,"intent_attack",18).tooltip_text = "攻击"
	attack_value = _label("",14)
	stats_row.add_child(attack_value)
	_image(stats_row,"intent_shield",18).tooltip_text = "护盾"
	shield_value = _label("",14)
	stats_row.add_child(shield_value)
	bond_section = VBoxContainer.new()
	bond_section.add_theme_constant_override("separation",2)
	column.add_child(bond_section)
	var field := _label("羁绊",11)
	field.modulate = Color("9aaebb")
	bond_section.add_child(field)
	bond_tags = preload("res://scenes/ui/glossary_text.gd").make("",14)
	bond_tags.custom_minimum_size.x = 264
	bond_section.add_child(bond_tags)
	action_section = VBoxContainer.new()
	action_section.add_theme_constant_override("separation",3)
	column.add_child(action_section)
	action_section.add_child(HSeparator.new())
	action_name = _label("",13)
	action_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_section.add_child(action_name)
	action_target = _label("",11)
	action_target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_target.modulate = Color("b7c8d3")
	action_section.add_child(action_target)
	generation = _label("",11)
	generation.modulate = Color("b7c8d3")
	action_section.add_child(generation)
	skill_section = VBoxContainer.new()
	skill_section.add_theme_constant_override("separation",5)
	column.add_child(skill_section)
	skill_section.add_child(HSeparator.new())
	var skill_row := HBoxContainer.new()
	skill_section.add_child(skill_row)
	skill_icon = _image(skill_row,"intent_charge",26)
	var skill_titles := VBoxContainer.new()
	skill_titles.add_theme_constant_override("separation",1)
	skill_row.add_child(skill_titles)
	skill_name = _label("",16)
	skill_name.modulate = Color("e6ce9d")
	skill_titles.add_child(skill_name)
	skill_trigger = _label("",11)
	skill_trigger.modulate = Color("9aaebb")
	skill_titles.add_child(skill_trigger)
	description = preload("res://scenes/ui/glossary_text.gd").make("",13)
	description.custom_minimum_size.x = 264
	skill_section.add_child(description)
	combat_stats = _label("",11)
	combat_stats.modulate = Color("9aaebb")
	skill_section.add_child(combat_stats)
	gear_row = HBoxContainer.new()
	column.add_child(gear_row)
	gear_button = Icon.new()
	gear_button.custom_minimum_size = Vector2(40, 40)
	gear_button.pressed.connect(open_bag)
	gear_row.add_child(gear_button)
	gear_name = _label("", 13)
	gear_row.add_child(gear_name)
	shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.4)
	shade.size = Vector2(1280, 720)
	canvas.add_child(shade)
	bag = _panel(Vector2(640, 350))
	bag.position = Vector2(320, 180)
	canvas.add_child(bag)
	var contents = _column(bag)
	var bar = HBoxContainer.new()
	contents.add_child(bar)
	bag_heading = _label("背包 · 装备交换", 23)
	bag_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(bag_heading)
	bar.add_child(_button("关闭", close_bag))
	bag_items = HBoxContainer.new()
	bag_items.add_theme_constant_override("separation", 16)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 130)
	contents.add_child(scroll)
	scroll.add_child(bag_items)
	bag_description = _label("", 18)
	bag_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bag_description.custom_minimum_size = Vector2(600, 95)
	contents.add_child(bag_description)
	equip_button = _button("装备", exchange)
	contents.add_child(equip_button)
	bag.hide()
	shade.hide()
	panel.hide()

func _image(parent: Node, id: String, extent: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = preload("res://scenes/battle_demo/status_skin.gd").TEXTURES[id]
	icon.custom_minimum_size = Vector2.ONE*extent
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(icon)
	return icon

func _panel(minimum: Vector2) -> PanelContainer:
	var result = PanelContainer.new()
	result.custom_minimum_size = minimum
	var style = StyleBoxFlat.new()
	style.bg_color = theme_surface
	style.border_color = theme_accent
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.02,0.04,0.06,0.28)
	style.shadow_size = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	result.add_theme_stylebox_override("panel", style)
	return result

func _column(parent: Control) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	parent.add_child(box)
	return box

func _label(value: String, font_size: int) -> Label:
	var result = Label.new()
	result.text = value
	result.add_theme_color_override("font_color", theme_ink)
	result.add_theme_font_size_override("font_size", font_size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _button(title: String, callback: Callable) -> Button:
	var result = Button.new()
	result.text = title
	result.add_theme_font_size_override("font_size",13)
	result.custom_minimum_size = Vector2(48,28)
	result.pressed.connect(callback)
	return result

func active() -> bool:
	var context = game.get("battle_context")
	if is_instance_valid(context) and context.busy(): return false
	return not (is_instance_valid(game.get("pause_overlay")) and game.get("pause_overlay").visible) and not game.leaving and not is_instance_valid(game.get("team_panel")) and not is_instance_valid(game.get("codex_panel")) and game.get("preview_elapsed") == null and (game.get("screen") == null or game.get("screen") == "battle")

func _process(_delta: float) -> void:
	visible = active()
	if not visible:
		close_info()
		close_bag()
		return
	var factor = minf(size.x / 1280, size.y / 720)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - Vector2(1280, 720) * factor) / 2
	if not pinned and not bag.visible and not (panel.visible and Rect2(panel.position, panel.size).has_point(pointer)):
		observed = {} if _code_hud_owns_pointer(canvas.get_global_transform()*pointer) else pick(pointer)
	if is_instance_valid(game.deployment) and game.deployment.dragging:
		close_info()
	if pinned:
		observed = {}
		for unit in game.units:
			if unit.side == focus_side and (unit.role if unit.side == 0 else unit.slot) == focus_key:
				observed = unit
		if observed.is_empty(): close_info()
	refresh()

func pick(point: Vector2) -> Dictionary:
	var unit := _pick_unit(point)
	if hover_blocked_id >= 0:
		if not unit.is_empty() and unit.id == hover_blocked_id: return {}
		hover_blocked_id = -1
	return unit

func _pick_unit(point: Vector2) -> Dictionary:
	var status = game.battle_status_layer
	if game.phase == "battle" and is_instance_valid(status):
		var screen_point: Vector2 = canvas.get_global_transform()*point
		for id in status.hit_rects:
			if status.hit_rects[id].has_point(screen_point) or (status.intents.has(id) and status.intents[id].has_point(screen_point)):
				return game.simulation.unit(id)
	var ordered = game.units.duplicate()
	ordered.sort_custom(func(a,b): return game._unit_center(a).y > game._unit_center(b).y)
	for unit in ordered:
		var feet: Vector2 = game._unit_center(unit) + Vector2(0,13)
		if Rect2(feet + Vector2(-44,-105),Vector2(88,136)).has_point(point): return unit
	return {}

func show_unit(unit: Dictionary, detailed: bool) -> void:
	observed = unit
	pinned = detailed
	if unit.is_empty(): close_info(); return
	focus_side = unit.side
	focus_key = unit.role if unit.side == 0 else unit.slot
	if detailed:
		game.inspected_enemy_slot = unit.slot if unit.side == 1 else -1
		if unit.side == 0: game.selected = unit.role
	refresh()

func close_info(block_hover := false) -> void:
	if block_hover and not observed.is_empty(): hover_blocked_id = observed.id
	pinned = false
	observed = {}
	if panel != null: panel.hide()
	if hover_blocked_id < 0: pointer = Vector2(-1000,-1000)

func hover_paused() -> bool:
	return active() and game.phase == "battle" and panel.visible and not observed.is_empty()

func refresh() -> void:
	panel.visible = not observed.is_empty()
	if observed.is_empty(): return
	heading.text = observed.name
	var tint := Color("82dfcc") if observed.side == 0 else Color("f5ae94")
	allegiance.text = "%s · %d号位" % ["友方" if observed.side == 0 else "敌方",int(observed.slot)+1]
	allegiance.modulate = tint
	card_style.border_color = tint.darkened(0.45)
	face.texture = observed.portrait
	summary.text = "%d / %d" % [maxi(0,observed.hp),observed.max_hp]
	attack_value.text = "%d" % observed.atk
	shield_value.text = "%d" % observed.shield
	var tags := preload("res://game/content/glossary.gd").unit_tags(observed)
	bond_section.visible = not tags.is_empty()
	bond_tags.visible = bond_section.visible
	bond_tags.set_copy(tags)
	action_section.visible = game.phase == "battle"
	if action_section.visible:
		var sim = game.simulation
		var intent: Dictionary = sim.intent_for(observed.id)
		var timing: Dictionary = sim.action_timing(observed.id)
		var target: Dictionary = sim.unit(int(intent.get("target_id",-1)))
		var label: String = "接近目标" if timing.get("waiting_target",false) else str(intent.get("label","待机"))
		action_name.text = "%s · %.1f 秒" % [label,float(intent.get("remaining",0))]
		action_name.modulate = Color("efca8b") if intent.get("kind","") == "cast" else Color("bce0ea")
		action_target.text = "目标："+str(intent.get("target_description",target.get("name","进入射程后选定")))
		generation.visible = observed.side == 0
		generation.text = ("全队吸收 %d/%d" % [sim.absorbed,Codes.RULES.shield_per_block]) if observed.get("code_type","") == "purple" else ("普攻产码 %d/%d" % [sim.attack_counts.get(observed.id,0),Codes.RULES.attacks_per_block])
	skill_section.visible = pinned
	skill_name.text = observed.skill.display_name
	skill_trigger.text = "自动技能  ·  每 %d 次普攻触发" % observed.skill.attacks_to_trigger
	if observed.side == 1 and game.simulation._enemy_rule(observed) in ["radio","board","colossus"]:
		skill_trigger.text = "特殊技能 · 预警后释放"
	skill_icon.texture = preload("res://scenes/battle_demo/status_skin.gd").TEXTURES[preload("res://scenes/battle_demo/status_skin.gd").intent_icon(observed,{"kind":"skill"})]
	description.set_copy(observed.skill.description)
	combat_stats.text = "攻击间隔 %.2f 秒    射程 %.1f 格" % [observed.interval,observed.attack_range]
	gear_row.visible = pinned and observed.side == 0
	if gear_row.visible:
		var id: String = game._worn_item(observed.role)
		gear_button.glyph = id
		gear_button.queue_redraw()
		gear_button.tooltip_text = "装备栏：点击查看描述和背包"
		var item = game._gear_definition(id)
		gear_name.text = "装备\n" + (item.display_name if item != null else "空槽")
	panel.reset_size()
	var feet: Vector2 = game._unit_center(observed)
	# Prefer the open central lane; clamp vertically inside the battlefield.
	var wanted = Vector2((1280 - panel.size.x) / 2, feet.y - panel.size.y / 2)
	if feet.x > 500 and feet.x < 784:
		wanted.x = feet.x + 60 if feet.x < 640 else feet.x - panel.size.x - 60
	panel.position = Vector2(clampf(wanted.x, 30, 1250 - panel.size.x), clampf(wanted.y, 100, 603 - panel.size.y))

func blocks_event(event: InputEvent) -> bool:
	if not active(): return false
	if bag.visible: return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	var point: Vector2 = canvas.get_global_transform().affine_inverse() * event.position
	return panel.visible and Rect2(panel.position, panel.size).has_point(point)

func _input(event: InputEvent) -> void:
	if not active(): return
	if bond_tags.pinned and event.is_action_pressed("ui_cancel"): return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and (panel.visible or bag.visible):
		if bag.visible: close_bag()
		else: close_info(true)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton): return
	pointer = canvas.get_global_transform().affine_inverse() * event.position
	if _code_hud_owns_pointer(event.position):
		if not pinned: close_info()
		return
	if bag.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not Rect2(bag.position, bag.size).has_point(pointer):
			close_bag()
			get_viewport().set_input_as_handled()
		return
	if blocks_event(event): return
	var point: Vector2 = canvas.get_global_transform().affine_inverse() * event.position
	if event is InputEventMouseMotion and not pinned:
		show_unit(pick(point), false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		hover_blocked_id = -1
		var unit = pick(point)
		if unit.is_empty(): close_info()
		else:
			show_unit(unit, true)
			if game.phase != "prepare": get_viewport().set_input_as_handled()

func open_bag() -> void:
	if observed.is_empty() or observed.side != 0: return
	bag_role = observed.role
	picked_item = game._worn_item(bag_role)
	bag.show()
	shade.show()
	_refresh_bag()

func _refresh_bag() -> void:
	bag_heading.text = "背包 · " + game.ROLES[bag_role]
	for child in bag_items.get_children():
		bag_items.remove_child(child)
		child.queue_free()
	var inventory: Dictionary = game._gear_inventory()
	var ids = ["none"] + inventory.keys()
	for id in ids:
		var column = VBoxContainer.new()
		bag_items.add_child(column)
		var icon = Icon.new()
		icon.glyph = "remove" if id == "none" else id
		icon.custom_minimum_size = Vector2(76,76)
		icon.pressed.connect(func(): picked_item = id; _refresh_bag())
		icon.toggle_mode = true
		icon.button_pressed = picked_item == id
		var item = game._gear_definition(id)
		icon.tooltip_text = "卸下装备" if item == null else item.display_name
		column.add_child(icon)
		column.add_child(_label("空槽" if item == null else item.display_name,14))
		var owner: int = inventory.get(id,-1)
		column.add_child(_label("背包" if owner < 0 else game.ROLES[owner],13))
	var item = game._gear_definition(picked_item)
	var owner: int = inventory.get(picked_item,-1)
	bag_description.text = ("空槽\n将当前装备放回背包。" if item == null else item.display_name + "\n" + item.description)
	if owner >= 0 and owner != bag_role:
		bag_description.text += "\n交换给「%s」，原穿戴者「%s」的槽位会腾空。" % [game.ROLES[bag_role],game.ROLES[owner]]
	if game.phase != "prepare": bag_description.text += "\n战斗中可查看，返回整备后交换。"
	equip_button.text = "卸下" if picked_item == "none" else ("转移" if owner >= 0 and owner != bag_role else "装备")
	var legal: bool = game._can_equip_item(picked_item,bag_role)
	if not legal and game.phase == "prepare": bag_description.text += "\n该同学的战斗装备占用了装备槽。"
	equip_button.disabled = game.phase != "prepare" or picked_item == game._worn_item(bag_role) or not legal

func exchange() -> void:
	if game._equip_item(picked_item, bag_role):
		close_bag()
		_process(0)

func close_bag() -> void:
	if bag != null: bag.hide()
	if shade != null: shade.hide()


func _code_hud_owns_pointer(at: Vector2) -> bool:
	return is_instance_valid(game.code_panel) and game.code_panel.owns_pointer(at)
