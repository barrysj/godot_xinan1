extends Control
## Presentation-only activity journal and tiered skill announcements.
const Codes = preload("res://game/combat/code_catalog.gd")
const StatusArt = preload("res://scenes/battle_demo/status_skin.gd")
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
var enter_seconds := 0.12
var exit_seconds := 0.18
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 10
	var tokens: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json"))
	enter_seconds = float(tokens.durations_ms.micro)/1000.0
	exit_seconds = float(tokens.durations_ms.normal)/1000.0
	var record_row := HBoxContainer.new()
	record_row.alignment = BoxContainer.ALIGNMENT_END
	record_row.add_theme_constant_override("separation",8)
	record_row.mouse_filter = MOUSE_FILTER_IGNORE
	host.journal_stack.add_child(record_row)
	toggle = Button.new()
	headline = Label.new()
	headline.size_flags_horizontal = SIZE_EXPAND_FILL
	headline.custom_minimum_size.y = 32
	headline.mouse_filter = MOUSE_FILTER_IGNORE
	headline.clip_text = true
	headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size",11)
	var headline_style := StyleBoxFlat.new()
	headline_style.bg_color = Color("132533",0.92)
	headline_style.set_corner_radius_all(4)
	headline_style.content_margin_left = 8
	headline_style.content_margin_right = 8
	headline.add_theme_stylebox_override("normal",headline_style)
	record_row.add_child(headline)
	toggle.custom_minimum_size = Vector2(48,32)
	toggle.add_theme_font_size_override("font_size",11)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("132533",0.96)
	style.border_color = Color("446477")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	toggle.add_theme_stylebox_override("normal",style)
	toggle.text = "记录"
	toggle.pressed.connect(func(): set_expanded(not expanded))
	record_row.add_child(toggle)
	history = RichTextLabel.new()
	filter_button = Button.new()
	filter_button.size_flags_horizontal = SIZE_SHRINK_END
	filter_button.custom_minimum_size = Vector2(88,26)
	filter_button.add_theme_font_size_override("font_size",11)
	filter_button.text = "重点记录"
	filter_button.tooltip_text = "切换重点与全部记录"
	filter_button.pressed.connect(func():
		important_only = not important_only
		filter_button.text = "重点记录" if important_only else "全部记录"
		_refresh_history())
	host.journal_stack.add_child(filter_button)
	filter_button.hide()
	history.custom_minimum_size = Vector2(302,36)
	history.add_theme_font_size_override("normal_font_size",12)
	var history_style := style.duplicate() as StyleBoxFlat
	history_style.bg_color = Color("132533",0.98)
	history_style.border_color = Color("557584")
	history_style.set_content_margin_all(8)
	history.add_theme_stylebox_override("normal",history_style)
	history.selection_enabled = true
	history.hide()
	host.journal_stack.add_child(history)
func set_expanded(value: bool) -> void:
	expanded = value
	history.visible = value
	filter_button.visible = value
	toggle.text = "收起" if value else "记录"
	headline.text = important
	headline.visible = not important.is_empty()
	headline.tooltip_text = important
	if value:
		if is_instance_valid(host.buff_details): host.buff_details.hide()
		_refresh_history()
	toggle.tooltip_text = ("查看本场战斗记录\n"+StatusArt.DAMAGE_SOURCE_HINT) if not value else "收起战斗记录"
func _refresh_history() -> void:
	var reverse := (highlights if important_only else records).duplicate()
	reverse.reverse()
	history.text = "\n".join(reverse) if not reverse.is_empty() else "暂无记录"
	call_deferred("_resize_history")
func _resize_history() -> void:
	history.custom_minimum_size.y = clampf(history.get_content_height()+16,36,232)
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
		for entry in names:
			entry.age += delta*host.game.speed
			if entry.exit_age >= 0: entry.exit_age += delta*host.game.speed
		names = names.filter(func(entry): return entry.exit_age < exit_seconds)
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
		"action_started":
			if event.get("casts",false): _begin_name(actor,event.action_id)
		"action_cancelled", "action_finished":
			_end_name(actor.id,event.action_id,event.kind == "action_cancelled")
		"action_released":
			_end_name(actor.id,event.action_id)
			if not event.get("casts",false): return
			if actor.side == 1 and host.sim._enemy_rule(actor) in ["radio","board","colossus"]: return
			record(actor_name+" · "+actor.skill.display_name,false,true)
		"enemy_warning":
			for entry in names:
				if entry.id == actor.id and entry.action_id == event.action_id: entry.text = str(event.label)
			record(actor_name+" · "+str(event.label)+"蓄力",true)
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
func _begin_name(actor: Dictionary, action_id: int) -> void:
	if actor.is_empty(): return
	if names.any(func(entry): return entry.id == actor.id and entry.action_id == action_id): return
	names = names.filter(func(entry): return entry.id != actor.id)
	var tint := Color("9be7d7") if actor.side == 0 else Color("ffc19c")
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("132533",0.97)
	surface.border_color = tint.darkened(0.48)
	surface.set_border_width_all(1)
	surface.border_width_left = 3
	surface.set_corner_radius_all(5)
	surface.shadow_color = Color(0.02,0.04,0.06,0.3)
	surface.shadow_size = 3
	names.append({"id":actor.id,"action_id":action_id,"text":actor.skill.display_name,"age":0.0,
		"exit_age":-1.0,"exit_alpha":1.0,"cancelled":false,"color":tint,"surface":surface})

func _end_name(actor_id: int, action_id: int, cancelled := false) -> void:
	for entry in names:
		if entry.id != actor_id or entry.action_id != action_id or entry.exit_age >= 0: continue
		entry.exit_alpha = name_alpha(entry)
		entry.exit_age = 0.0
		entry.cancelled = cancelled

func name_alpha(entry: Dictionary) -> float:
	if entry.exit_age >= 0:
		return float(entry.exit_alpha)*pow(clampf(1-float(entry.exit_age)/exit_seconds,0,1),2)
	if host.code_fx.reduced_motion: return 1.0
	return 1-pow(1-clampf(float(entry.age)/enter_seconds,0,1),3)

func _name_rect(base: Rect2, occupied: Array[Rect2]) -> Rect2:
	var safe := Rect2(16,174,1248,422)
	var best := Rect2(base.position.clamp(safe.position,safe.end-base.size),base.size)
	var best_score := INF
	for dy in [0,-38,38,-76,76,114]:
		for dx in [0,-base.size.x-12,base.size.x+12,-160,160,-280,280]:
			var at := (base.position+Vector2(dx,dy)).clamp(safe.position,safe.end-base.size)
			var candidate := Rect2(at,base.size)
			var score := at.distance_squared_to(base.position)
			for other in occupied:
				if other.intersects(candidate): score += candidate.intersection(other).get_area()*10000
			if score < best_score:
				best = candidate
				best_score = score
	return best

func _fit_name(value: String, width: float, font_size := 14) -> String:
	if FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= width: return value
	while value.length() > 1:
		value = value.left(value.length()-1)
		if FONT.get_string_size(value+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= width: return value+"…"
	return "…"

func _draw() -> void:
	name_bounds.clear()
	var occupied: Array[Rect2] = []
	if is_instance_valid(host.game.battle_status_layer):
		for rect in host.game.battle_status_layer.status_rects.values(): occupied.append(rect.grow(4))
		for unit in host.sim.units:
			if unit.hp <= 0: continue
			occupied.append(Rect2(host.game._unit_center(unit)+Vector2(-32,-102),Vector2(64,116)))
			if unit.side == 1: occupied.append(Rect2(host.game.battle_status_layer._bubble_position(unit),Vector2(32,36)).grow(3))
	for entry in names:
		var actor: Dictionary = host.sim.unit(entry.id)
		if actor.is_empty(): continue
		var at: Vector2 = host.game._unit_center(actor)
		var text := _fit_name(entry.text,202)
		var width := FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+42
		var base := Rect2(at-Vector2(width/2,138),Vector2(width,30))
		var rect := _name_rect(base,occupied)
		occupied.append(rect.grow(4))
		name_bounds.append(rect)
		var alpha := name_alpha(entry)
		var tint: Color = Color("c7a9a3") if entry.cancelled else entry.color
		var surface: StyleBoxFlat = entry.surface
		surface.bg_color = Color(Color("132533"),0.97*alpha)
		surface.border_color = Color(tint.darkened(0.48),alpha)
		surface.shadow_color.a = 0.3*alpha
		if rect.get_center().distance_to(base.get_center()) > 24:
			var edge := rect.get_center().clamp(rect.position,rect.end)
			draw_line(edge,at+Vector2(0,-78),Color(tint,0.3*alpha),1,true)
		draw_style_box(surface,rect)
		StatusArt.draw(self,"intent_charge",Rect2(rect.position+Vector2(8,7),Vector2(16,16)),Color(tint,alpha))
		draw_string(FONT,rect.position+Vector2(31,21),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(tint,alpha))

	if announcements.is_empty(): return
	var entry: Dictionary = announcements[0]
	var alpha := minf(1,float(entry.age)*12)*minf(1,(1.4-float(entry.age))*4)
	var text := _fit_name(entry.text,432,21)
	var width := FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
	var rect := Rect2(640-(width+48)/2,104,width+48,40)
	draw_rect(rect,Color(0.03,0.09,0.15,0.88*alpha))
	draw_line(rect.position,rect.position+Vector2(rect.size.x,0),Color(entry.color,alpha),2,true)
	draw_string(FONT,Vector2(640-width/2,132),text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color(entry.color,alpha))

	if announcements.size() > 1:
		var recent: Dictionary = announcements[1]
		var recent_alpha := minf(1,(1.4-float(recent.age))*4)*0.72
		var recent_width := FONT.get_string_size(recent.text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(FONT,Vector2(640-recent_width/2,161),recent.text,HORIZONTAL_ALIGNMENT_LEFT,360,13,Color(recent.color,recent_alpha))
