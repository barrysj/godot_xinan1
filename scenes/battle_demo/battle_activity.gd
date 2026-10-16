extends Control
## Presentation-only activity journal and tiered skill announcements.
const Codes = preload("res://game/combat/code_catalog.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var host
var records: Array[String] = []
var highlights: Array[String] = []
var filter_button: Button
var important_only := true
var name_bounds: Array[Rect2] = []
var important := ""
var names: Array[Dictionary] = []
var announcements: Array[Dictionary] = []
var headline: Label
var toggle: Button
var history: RichTextLabel
var expanded := false
var fallen := {}
var simulation_ref
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	toggle = Button.new()
	headline = Label.new()
	headline.position = Vector2(950,86)
	headline.size = Vector2(246,28)
	headline.clip_text = true
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size",11)
	add_child(headline)
	toggle.position = Vector2(1204,86)
	toggle.custom_minimum_size = Vector2(48,28)
	toggle.add_theme_font_size_override("font_size",11)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04,0.10,0.15,0.32)
	style.set_corner_radius_all(4)
	toggle.add_theme_stylebox_override("normal",style)
	toggle.text = "记录"
	toggle.pressed.connect(func(): set_expanded(not expanded))
	add_child(toggle)
	history = RichTextLabel.new()
	filter_button = Button.new()
	filter_button.position = Vector2(950,118)
	filter_button.custom_minimum_size = Vector2(88,26)
	filter_button.add_theme_font_size_override("font_size",11)
	filter_button.text = "重点记录"
	filter_button.tooltip_text = "切换重点与全部记录"
	filter_button.pressed.connect(func():
		important_only = not important_only
		filter_button.text = "重点记录" if important_only else "全部记录"
		_refresh_history())
	add_child(filter_button)
	filter_button.hide()
	history.position = Vector2(950,148)
	history.size = Vector2(302,232)
	history.add_theme_font_size_override("normal_font_size",12)
	var history_style := style.duplicate() as StyleBoxFlat
	history_style.bg_color = Color(0.04,0.10,0.15,0.78)
	history_style.set_content_margin_all(8)
	history.add_theme_stylebox_override("normal",history_style)
	history.selection_enabled = true
	history.hide()
	add_child(history)
func set_expanded(value: bool) -> void:
	expanded = value
	history.visible = value
	filter_button.visible = value
	toggle.text = "收起" if value else "记录"
	headline.text = important
	headline.tooltip_text = important
	if value:
		if is_instance_valid(host.buff_details): host.buff_details.hide()
		_refresh_history()
	toggle.tooltip_text = "查看本场战斗记录" if not value else "收起战斗记录"
func _refresh_history() -> void:
	var reverse := (highlights if important_only else records).duplicate()
	reverse.reverse()
	history.text = "\n".join(reverse) if not reverse.is_empty() else "暂无记录"
	call_deferred("_resize_history")
func _resize_history() -> void:
	history.size.y = clampf(history.get_content_height()+16,36,232)
func owns_pointer(at: Vector2) -> bool:
	return is_visible_in_tree() and (toggle.get_global_rect().has_point(at) or (expanded and (history.get_global_rect().has_point(at) or filter_button.get_global_rect().has_point(at))))
func _input(event: InputEvent) -> void:
	if expanded and event.is_action_pressed("ui_cancel"):
		set_expanded(false)
		get_viewport().set_input_as_handled()
func reset_journal() -> void:
	simulation_ref = host.game.simulation
	records.clear(); highlights.clear(); names.clear(); announcements.clear(); fallen.clear(); important = ""
	history.text = ""
	set_expanded(false)
func _process(delta: float) -> void:
	if simulation_ref != host.sim:
		reset_journal()
	visible = host.running and host.is_visible_in_tree()
	if not visible: return
	if not host.feedback_frozen():
		for entry in names: entry.age += delta*host.game.speed
		names = names.filter(func(entry): return entry.age < 1.3)
		for entry in announcements: entry.age += delta*host.game.speed
		announcements = announcements.filter(func(entry): return entry.age < 1.4)
	queue_redraw()
func record(message: String, prominent := false, key_event := false) -> void:
	var seconds := int(host.sim.elapsed)
	var row := "%02d:%02d  %s" % [seconds/60,seconds%60,message]
	records.append(row)
	if prominent or key_event: highlights.append(row)
	if expanded: _refresh_history()
	if prominent:
		important = message
		set_expanded(expanded)
func announce(title: String, tint: Color) -> void:
	announcements.push_front({"text":title,"color":tint,"age":0.0})
	if announcements.size() > 2: announcements.resize(2)
func _unit_label(unit: Dictionary) -> String:
	if unit.is_empty(): return ""
	var duplicates: Array = host.sim.units.filter(func(other): return other.side == unit.side and other.name == unit.name)
	return "%s·%d号位" % [unit.name,int(unit.slot)+1] if duplicates.size() > 1 else str(unit.name)
func consume(event: Dictionary) -> void:
	var actor: Dictionary = host.sim.unit(event.actor_id)
	var target: Dictionary = host.sim.unit(event.target_id)
	var actor_name := _unit_label(actor)
	var target_name := _unit_label(target)
	match event.kind:
		"action_released":
			if not event.get("casts",false): return
			if actor.side == 1 and host.sim._enemy_rule(actor) in ["radio","board","colossus"]: return
			names = names.filter(func(entry): return entry.id != actor.id)
			names.append({"id":actor.id,"text":actor.skill.display_name,"age":0.0,"color":Color("82e4d0") if actor.side == 0 else Color("ffad88")})
			record(actor_name+" · "+actor.skill.display_name,false,true)
		"enemy_warning": record(actor_name+" · "+str(event.label)+"蓄力",true)
		"enemy_release":
			announce(str(event.label),Color("ff9977"))
			record(actor_name+" · "+str(event.label),true)
		"hack_completed":
			var definition = Codes.program(event.choice)
			if definition != null:
				announce(definition.display_name,Color("7ce8d4"))
				record("破解 · "+definition.display_name,true)
		"impact":
			var amount := int(event.get("actual",event.get("value",0)))
			var verb: String = {"damage":"伤害","heal":"治疗","shield":"护盾"}.get(event.get("effect",""),"")
			if event.get("hp",target.get("hp",1)) <= 0 and not fallen.has(target.id):
				fallen[target.id] = true
				record(target_name+"退场",true)
			if not verb.is_empty(): record(("%s · %s %d" % [actor_name,verb,amount]) if actor.id == target.id else ("%s → %s · %s %d" % [actor_name,target_name,verb,amount]))
		"code_generated": record("%s · %s +%d" % [actor_name,Codes.RULES.types[event.code_type].name,event.actual])
		"revived":
			fallen.erase(target.id)
			record(target_name+"复苏",true)
		"mark_applied": record(actor_name+" → "+target_name+" · 漏洞")
		"mark_verified": record(target_name+" · 漏洞已验证")
		"chain_followup": record(actor_name+" → "+target_name+" · 追击")
		"shield_expired": record(target_name+" · 护盾结束")
		"recoil_burst": record(actor_name+" · 反冲护盾爆发",true)
func _draw() -> void:
	name_bounds.clear()
	var occupied: Array[Rect2] = []
	if is_instance_valid(host.game.battle_status_layer):
		for rect in host.game.battle_status_layer.status_rects.values(): occupied.append(rect.grow(3))
	for entry in names:
		var actor: Dictionary = host.sim.unit(entry.id)
		if actor.is_empty(): continue
		var at: Vector2 = host.game._unit_center(actor)+Vector2(0,-106)
		at.x = clampf(at.x,100,1180); at.y = clampf(at.y,150,555)
		var alpha := minf(1,(1.3-float(entry.age))*4)
		var width := FONT.get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+20
		var rect := Rect2(at-Vector2(width/2,20),Vector2(width,27))
		for offset in [Vector2.ZERO,Vector2(0,-32),Vector2(-width-12,0),Vector2(width+12,0),Vector2(0,-64)]:
			var candidate := Rect2(rect.position+offset,rect.size)
			if not Rect2(16,140,1248,460).encloses(candidate): continue
			if occupied.any(func(other): return other.intersects(candidate)): continue
			rect = candidate
			break
		occupied.append(rect.grow(3))
		name_bounds.append(rect)
		var surface := StyleBoxFlat.new()
		surface.bg_color = Color(0.04,0.09,0.14,0.82*alpha)
		surface.set_corner_radius_all(3)
		draw_style_box(surface,rect)
		draw_string(FONT,rect.position+Vector2(10,19),entry.text,HORIZONTAL_ALIGNMENT_LEFT,width-20,14,Color(entry.color,alpha))

	if announcements.is_empty(): return
	var entry: Dictionary = announcements[0]
	var alpha := minf(1,float(entry.age)*12)*minf(1,(1.4-float(entry.age))*4)
	var rect := Rect2(450,87,380,46)
	draw_rect(rect,Color(0.03,0.09,0.15,0.88*alpha))
	draw_line(rect.position,rect.position+Vector2(380,0),Color(entry.color,alpha),2,true)
	var width := FONT.get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
	draw_string(FONT,Vector2(640-width/2,118),entry.text,HORIZONTAL_ALIGNMENT_LEFT,360,21,Color(entry.color,alpha))

	if announcements.size() > 1:
		var recent: Dictionary = announcements[1]
		var recent_alpha := minf(1,(1.4-float(recent.age))*4)*0.72
		var recent_width := FONT.get_string_size(recent.text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(FONT,Vector2(640-recent_width/2,151),recent.text,HORIZONTAL_ALIGNMENT_LEFT,360,13,Color(recent.color,recent_alpha))
