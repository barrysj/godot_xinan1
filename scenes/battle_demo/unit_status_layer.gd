extends Node2D
## World-following status; simulation owns every counter and timer.
const Codes = preload("res://game/combat/code_catalog.gd")
const StatusArt = preload("res://scenes/battle_demo/status_skin.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var game
var pointer := Vector2(-10000,-10000)
var intents := {}
var hit_rects := {}
var hovered_id := -1
var pinned_id := -1
var detail: PanelContainer
var detail_text: Label
var pulses := {}
var anchors := {}
var status_rects := {}
var shield_peaks := {}
var bubble_styles := {}
var visual_values := {}
var cycles := {}
var overflow_until := {}
var damage_numbers: Array[Dictionary] = []
var last_elapsed := -1.0
var simulation_ref

func _ready() -> void:
	z_index = 3 # Floating numbers above actors/effects, below modal details.
	for key in ["normal","cast"]:
		var bubble := StyleBoxFlat.new()
		bubble.bg_color = Color("18232e")
		bubble.border_color = Color("ffbf66") if key == "cast" else Color("dce7ec")
		bubble.set_border_width_all(1)
		bubble.set_corner_radius_all(11)
		bubble_styles[key] = bubble
	detail = PanelContainer.new()
	detail.z_index = 80
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.theme = preload("res://resources/theme/theme-main.tres")
	var style: StyleBoxTexture = StatusArt.DETAIL.duplicate()
	style.set_content_margin_all(12)
	detail.add_theme_stylebox_override("panel",style)
	add_child(detail)
	detail_text = Label.new()
	detail_text.custom_minimum_size.x = 268
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.add_theme_font_override("font",FONT)
	detail_text.add_theme_font_size_override("font_size",16)
	detail_text.add_theme_color_override("font_color",Color("f4f8fc"))
	detail.add_child(detail_text)
	detail.hide()
	game.presentation_cue.connect(consume)
	get_window().mouse_exited.connect(func(): pointer = Vector2(-10000,-10000))

func active() -> bool:
	return is_instance_valid(game) and game.get("screen") in [null,"battle"] and game.phase in ["prepare","battle"]

func hover_paused() -> bool:
	return active() and game.phase == "battle" and (hovered_id >= 0 or pinned_id >= 0)

func _input(event: InputEvent) -> void:
	if not active(): return
	if event is InputEventMouse: pointer = event.position
	if event.is_action_pressed("ui_cancel") and (pinned_id >= 0 or hovered_id >= 0):
		pinned_id = -1
		pointer = Vector2(-10000,-10000)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hovered_id >= 0:
			pinned_id = -1 if pinned_id == hovered_id else hovered_id
			get_viewport().set_input_as_handled()
		elif pinned_id >= 0: pinned_id = -1

func consume(event: Dictionary) -> void:
	var kind: String = event.get("kind","")
	if kind == "impact" and event.get("effect","") in ["damage","heal"]:
		var lost := float(event.get("actual",0))
		var blocked := float(event.get("blocked",0))
		if lost > 0 or blocked > 0:
			var id: int = event.get("target_id",-1)
			var merged := false
			for n in damage_numbers:
				if n.id == id and n.effect == event.effect and n.age < 0.12:
					n.actual += lost
					n.blocked += blocked
					merged = true
					break
			if not merged:
				var lane := damage_numbers.filter(func(n): return n.id == id).size()%3
				damage_numbers.append({"id":id,"effect":event.effect,"actual":lost,"blocked":blocked,"age":0.0,"lane":lane,"at":game._project(event.to),"special":event.get("special",false)})
			if damage_numbers.size() > 48: damage_numbers.pop_front()
	if kind == "code_cycle_started" and not event.get("shared",false):
		cycles[event.cycle_id] = event.duplicate()
	elif kind == "code_cycle_completed":
		cycles.erase(event.cycle_id)
		if event.get("overflow",0) > 0: overflow_until[event.actor_id] = game.simulation.elapsed+0.5
	elif kind == "code_generated" and float(event.get("actual",0)) > 0 and event.get("reason","") == "普攻产出":
		pulses[int(event.get("actor_id",-1))] = 0.22

func _clear_feedback() -> void:
	shield_peaks.clear()
	visual_values.clear()
	cycles.clear()
	overflow_until.clear()
	damage_numbers.clear()
	pulses.clear()

func _visual_update(delta: float) -> void:
	var frozen: bool = game.paused or (is_instance_valid(game.code_panel) and game.code_panel.hover_paused())
	var dt: float = 0 if frozen else delta*game.speed
	for u in game.units:
		var target := Vector2(float(u.hp),float(u.shield))
		if not visual_values.has(u.id): visual_values[u.id] = {"vitals":target,"count":float(game.simulation.attack_counts.get(u.id,0))}
		var state: Dictionary = visual_values[u.id]
		var amount := 1-exp(-dt/0.045)
		state.vitals = (state.vitals as Vector2).lerp(target,amount)
		if state.vitals.distance_to(target)<0.1: state.vitals = target
		state.count = move_toward(float(state.count),float(game.simulation.attack_counts.get(u.id,0)),dt*12)
	for n in damage_numbers: n.age += dt
	damage_numbers = damage_numbers.filter(func(n): return n.age < 0.75)

func action_progress(timing: Dictionary) -> float:
	if timing.waiting_target or timing.remaining <= 0: return float(timing.progress)
	return minf(0.999,float(timing.progress)+float(game.accumulator)/maxf(0.001,float(timing.duration)))

func threshold_for_cycle() -> int:
	return Codes.RULES.attacks_per_block

func cycle_remaining(cycle: Dictionary) -> float:
	var age: float = game.simulation.elapsed+game.accumulator-(cycle.ready_at-cycle.duration)
	return float(Codes.RULES.attacks_per_block)*(1-clampf((age-0.08)/0.22,0,1))

func _ideal_anchor(u: Dictionary) -> Vector2:
	return game._unit_center(u)+Vector2(-146 if u.side == 0 else 42,-14)

func _layout_status() -> void:
	anchors.clear()
	status_rects.clear()
	var occupied: Array[Rect2] = []
	# Stable unit order; displaced cards keep a leader line to their owner.
	for u in game.units:
		if u.hp <= 0: continue
		if game.phase == "prepare" and u.side == 0 and is_instance_valid(game.deployment) and game.deployment.previews_unit(u.role): continue
		shield_peaks[u.id] = maxf(float(shield_peaks.get(u.id,0)),float(u.shield))
		var ideal := _ideal_anchor(u)
		var extent := Vector2(136,48)
		var base := ideal+Vector2(-20,-2)
		base = base.clamp(Vector2(16,170),Vector2(1264,612)-extent)
		var candidates: Array[Vector2] = [base]
		for used in occupied:
			candidates.append(Vector2(base.x,used.end.y+4))
			candidates.append(Vector2(base.x,used.position.y-extent.y-4))
			candidates.append(Vector2(used.end.x+4,base.y))
			candidates.append(Vector2(used.position.x-extent.x-4,base.y))
		candidates.sort_custom(func(a,b): return a.distance_squared_to(base)<b.distance_squared_to(base))
		var chosen := Rect2(base,extent)
		for candidate in candidates:
			var rect := Rect2(candidate,extent)
			if not Rect2(16,170,1248,442).encloses(rect): continue
			if occupied.any(func(used): return used.grow(2).intersects(rect)): continue
			chosen = rect
			break
		occupied.append(chosen)
		status_rects[u.id] = chosen
		anchors[u.id] = chosen.position-Vector2(-20,-2)

func _process(delta: float) -> void:
	visible = active()
	if not visible:
		hovered_id = -1
		pinned_id = -1
		_clear_feedback()
		intents.clear()
		hit_rects.clear()
		pulses.clear()
		detail.hide()
		return
	if simulation_ref != game.simulation or game.simulation.elapsed < last_elapsed:
		_clear_feedback()
		simulation_ref = game.simulation
		pulses.clear()
		pinned_id = -1
	last_elapsed = game.simulation.elapsed
	_layout_status()
	intents.clear()
	hit_rects.clear()
	hovered_id = -1
	for u in game.units:
		if u.hp <= 0 or game.phase != "battle": continue
		var p: Vector2 = anchors.get(u.id,_ideal_anchor(u))
		var bounds: Rect2 = status_rects[u.id]
		hit_rects[u.id] = Rect2(game.origin+bounds.position*game.scale_factor,bounds.size*game.scale_factor)
		if u.side == 1:
			intents[u.id] = Rect2(game.origin+_bubble_position(u)*game.scale_factor,Vector2(32,36)*game.scale_factor)
		if hit_rects[u.id].has_point(pointer) or (intents.has(u.id) and intents[u.id].has_point(pointer)): hovered_id = u.id
	if pinned_id >= 0 and not hit_rects.has(pinned_id): pinned_id = -1
	_visual_update(delta)
	_update_detail()
	if not game.paused and not hover_paused():
		for id in pulses.keys():
			pulses[id] -= delta
			if pulses[id] <= 0: pulses.erase(id)
	queue_redraw()

func _update_detail() -> void:
	var id: int = pinned_id if pinned_id >= 0 else hovered_id
	detail.visible = id >= 0 and hit_rects.has(id)
	if not detail.visible: return
	var intent: Dictionary = game.simulation.intent_for(id)
	if intent.is_empty(): detail.hide(); return
	var u: Dictionary = game.simulation.unit(id)
	var target: Dictionary = game.simulation.unit(int(intent.get("target_id",-1)))
	var target_text: String = intent.get("target_description",target.get("name","范围目标" if intent.get("locked",false) else "进入射程后选定"))
	var timing: Dictionary = game.simulation.action_timing(id)
	var release_label := "接近目标" if timing.get("waiting_target",false) else "施法释放" if intent.kind == "cast" else "普攻释放"
	var vitals := "生命 %d/%d · 护盾 %d" % [u.hp,u.max_hp,u.shield]
	var progress := ""
	if u.side == 0:
		progress = "\n全队吸收 %d/%d" % [game.simulation.absorbed,Codes.RULES.shield_per_block] if u.get("code_type","") == "purple" else "\n普攻产码 %d/%d" % [game.simulation.attack_counts.get(id,0),Codes.RULES.attacks_per_block]
	detail_text.text = "%s · %s\n%s%s\n%s\n目标：%s\n%s · %.1f 秒%s" % [u.name,intent.label,vitals,progress,intent.description,target_text,release_label,intent.remaining,"\n点击固定 · Esc 收起" if pinned_id < 0 else "\n已固定 · Esc 收起"]
	if u.side == 0 and pinned_id < 0:
		detail_text.text = "%s\n%s%s\n%s · %.1f 秒\n点击详情 · Esc 收起" % [u.name,vitals,progress,"施法："+intent.label if intent.kind == "cast" else release_label,intent.remaining]
	detail.scale = Vector2.ONE*game.scale_factor
	detail.reset_size()
	var rect: Rect2 = intents.get(id,hit_rects[id])
	var dims: Vector2 = detail.get_combined_minimum_size()*game.scale_factor
	var x := rect.end.x+8
	if x+dims.x > game.size.x-8: x = rect.position.x-dims.x-8
	detail.position = Vector2(clampf(x,8,game.size.x-dims.x-8),clampf(rect.position.y-dims.y-8,game.origin.y+162*game.scale_factor,game.size.y-dims.y-8))

func _draw() -> void:
	if not active(): return
	draw_set_transform(game.origin,0,Vector2.ONE*game.scale_factor)
	var sim = game.simulation
	var reduced: bool = is_instance_valid(game.code_panel) and game.code_panel.code_fx.reduced_motion
	for u in game.units:
		if u.hp <= 0: continue
		if game.phase == "prepare" and u.side == 0 and is_instance_valid(game.deployment) and game.deployment.previews_unit(u.role): continue
		var p: Vector2 = anchors.get(u.id,_ideal_anchor(u))
		if p.distance_to(_ideal_anchor(u)) > 8:
			var center: Vector2 = game._unit_center(u)+Vector2(0,13)
			var edge := p+Vector2(114 if u.side == 0 else -22,7)
			draw_line(center,edge,Color(0.8,0.88,1,0.35),1,true)
		var hp_tint := Color("36d399") if u.side == 0 else Color("ff4d6d")
		_badge("health",p+Vector2(-18,0),hp_tint)
		StatusArt.draw(self,"bar_frame",Rect2(p,Vector2(76,14)))
		var shown: Vector2 = visual_values.get(u.id,{"vitals":Vector2(u.hp,u.shield)}).vitals
		var parts := vitals_parts(shown.x,float(u.max_hp),shown.y,float(shield_peaks.get(u.id,0)))
		if shown.y > 0.1: StatusArt.draw(self,"bar_frame",Rect2(p+Vector2(76,0),Vector2(24,14)))
		if parts.health.size.x > 0: draw_rect(Rect2(p+parts.health.position,parts.health.size),hp_tint)
		if parts.shield.size.x > 0: draw_rect(Rect2(p+parts.shield.position,parts.shield.size),Color("9564d8"))
		var caption := "%d/%d" % [u.hp,u.max_hp]
		if u.shield > 0:
			caption += "+%d" % u.shield
			_badge("intent_shield",p+Vector2(100,0),Color("c287ff"))
		var text_at := p+Vector2(((100 if u.shield > 0 else 76)-FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x)/2,11)
		draw_string_outline(FONT,text_at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,2,Color("101820"))
		draw_string(FONT,text_at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
		if game.phase != "battle": continue
		var timing: Dictionary = sim.action_timing(u.id)
		if timing.is_empty(): continue
		var casting: bool = timing.kind == "cast"
		var tint := Color("ffbf66") if casting else Color("20d8f2")
		_badge("intent_charge" if casting else "intent_attack",p+Vector2(-18,17),tint)
		StatusArt.bar(self,p+Vector2(0,20),action_progress(timing),tint,Vector2(96,5),1)
		if u.side == 1:
			var at := _bubble_position(u)
			var border := Color("ffbf66") if casting else Color("dce7ec")
			draw_style_box(bubble_styles["cast" if casting else "normal"],Rect2(at,Vector2(32,28)))
			for dot in [Vector3(-2,29,3),Vector3(-8,35,2)]:
				draw_circle(at+Vector2(dot.x,dot.y),dot.z,border)
				draw_circle(at+Vector2(dot.x,dot.y),maxf(0.5,dot.z-1),Color("18232e"))
			StatusArt.draw(self,StatusArt.intent_icon(u,sim.intent_for(u.id)),Rect2(at+Vector2(7,5),Vector2(18,18)),tint)
		else:
			if u.get("code_type","red") == "purple": continue
			var kind: String = u.get("code_type","red")
			var color: Color = Codes.RULES.types[kind].color
			_badge("code_"+kind,p+Vector2(0,30),color)
			var count: float = float(visual_values.get(u.id,{"count":float(sim.attack_counts.get(u.id,0))}).count)
			for cycle in cycles.values():
				if cycle.actor_id == u.id:
					count = float(threshold_for_cycle()) if reduced else cycle_remaining(cycle)
					break
			var threshold: int = Codes.RULES.attacks_per_block
			var step := 36.0/maxi(threshold,1)
			for i in range(threshold):
				var slot := Rect2(p+Vector2(20+i*step,34),Vector2(minf(8,step-1),8))
				StatusArt.draw(self,"slot_empty",slot)
				var ratio := clampf(count-i,0,1)
				if ratio > 0: draw_rect(Rect2(slot.position+Vector2.ONE,Vector2((slot.size.x-2)*ratio,6)),color)
			if pulses.has(u.id) and not reduced:
				draw_rect(Rect2(p+Vector2(-1,29),Vector2(18,18)),Color(color,float(pulses[u.id])/0.22),false,1)

			if float(overflow_until.get(u.id,0)) > sim.elapsed:
				draw_string(FONT,p+Vector2(62,43),"已满",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ffbf66"))
	_draw_damage_numbers()

func _draw_damage_numbers() -> void:
	for n in damage_numbers:
		var alpha := clampf((0.75-float(n.age))/0.2,0,1)
		var at: Vector2 = n.at+Vector2(8+int(n.lane)*14,-48-int(n.lane)*50-12*(1-pow(1-float(n.age)/0.75,2)))
		if at.y < 132: at.y = n.at.y-40+int(n.lane)*34
		var font_size := 20 if n.special else 17
		var label := "%s%d" % ["+" if n.effect == "heal" else "−",int(n.actual)]
		if n.actual > 0:
			draw_string_outline(FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color(0.04,0.06,0.08,alpha))
			draw_string(FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.5,1,0.6,alpha) if n.effect == "heal" else Color(1,0.95,0.84,alpha))
			at.y += 18
		if n.blocked > 0:
			StatusArt.draw(self,"intent_shield",Rect2(at+Vector2(-15,-12),Vector2(13,13)),Color(0.8,0.6,1,alpha))
			label = "−%d" % int(n.blocked)
			draw_string_outline(FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,3,Color(0.04,0.06,0.08,alpha))
			draw_string(FONT,at,label,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(0.8,0.6,1,alpha))

func _bubble_position(u: Dictionary) -> Vector2:
	return (game._unit_center(u)+Vector2(38,-70)).clamp(Vector2(16,174),Vector2(1232,570))

func _badge(id: String,at: Vector2,tint: Color) -> void:
	StatusArt.draw(self,"intent_plate",Rect2(at,Vector2(16,16)))
	StatusArt.draw(self,id,Rect2(at+Vector2(2,2),Vector2(12,12)),tint)

static func vitals_parts(hp: float,max_hp: float,shield: float,peak_shield: float) -> Dictionary:
	# HP always uses max HP; optional shield extension never steals HP width.
	var health_width := 72*clampf(hp/maxf(1,max_hp),0,1)
	var shield_width := 20*clampf(shield/maxf(1,maxf(peak_shield,shield)),0,1)
	return {"health":Rect2(2,2,health_width,10),"shield":Rect2(98-shield_width,2,shield_width,10)}
