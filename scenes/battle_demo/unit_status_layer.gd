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
var pulses := {}
var anchors := {}
var status_rects := {}
var shield_peaks := {}
var bubble_styles := {}
var visual_values := {}
var cycles := {}
var overflow_until := {}
const DAMAGE_SECONDS := 0.95
const DAMAGE_COLOR := Color("ff6868")
const SHIELD_COLOR := Color("c59aff")
const HEAL_COLOR := Color("87f2b0")
const FOLLOWUP_TEXT := "追击！"
const FOLLOWUP_FONT_SIZE := 14
var damage_numbers: Array[Dictionary] = []
var damage_bounds: Array[Rect2] = []
var damage_source_bounds: Array[Dictionary] = []
var followup_bounds: Array[Dictionary] = []
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
	game.presentation_cue.connect(consume)
	get_window().mouse_exited.connect(func(): pointer = Vector2(-10000,-10000))

func active() -> bool:
	return is_instance_valid(game) and game.get("screen") in [null,"battle"] and game.phase in ["prepare","battle"]

func hover_paused() -> bool:
	return is_instance_valid(game.inspector) and game.inspector.hover_paused()

func consume(event: Dictionary) -> void:
	var kind: String = event.get("kind","")
	if kind == "impact" and event.get("effect","") in ["damage","heal"]:
		var lost := float(event.get("actual",0))
		var blocked := float(event.get("blocked",0))
		if lost > 0 or blocked > 0:
			var id: int = event.get("target_id",-1)
			var source: String = event.get("damage_source","skill" if event.get("special",false) or event.get("program_effect",false) else "attack")
			var followup: bool = event.get("is_followup",false)
			var special: bool = event.get("special",false)
			var merged := false
			for n in damage_numbers:
				if n.id == id and n.effect == event.effect and n.source == source and n.followup == followup and n.special == special and n.age < 0.12:
					n.actual += lost
					n.blocked += blocked
					merged = true
					break
			if not merged:
				var lane := damage_numbers.filter(func(n): return n.id == id).size()%3
				damage_numbers.append({"id":id,"effect":event.effect,"actual":lost,"blocked":blocked,"age":0.0,"lane":lane,"at":game._project(event.to),"special":special,"source":source,"followup":followup})
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
	damage_bounds.clear()
	damage_source_bounds.clear()
	followup_bounds.clear()
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
	damage_numbers = damage_numbers.filter(func(n): return n.age < DAMAGE_SECONDS)

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
	if is_instance_valid(game.code_panel) and game.code_panel.owns_pointer(pointer): hovered_id = -1
	if pinned_id >= 0 and not hit_rects.has(pinned_id): pinned_id = -1
	_visual_update(delta)
	if not game.paused and not hover_paused():
		for id in pulses.keys():
			pulses[id] -= delta
			if pulses[id] <= 0: pulses.erase(id)
	queue_redraw()

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

func damage_rows(n: Dictionary, reduced: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var pop := 1.0 if reduced else 1+0.15*pow(1-clampf(float(n.age)/0.12,0,1),3)
	if n.actual > 0:
		var healing: bool = n.effect == "heal"
		rows.append({"text":("+" if healing else "−")+str(int(n.actual)),"font":int(round((22 if healing else 28 if n.special else 24)*pop)),
			"tint":HEAL_COLOR if healing else DAMAGE_COLOR,"shield":false,"source":"" if healing else n.source,"followup":not healing and n.get("followup",false)})
	if n.blocked > 0:
		rows.append({"text":"−"+str(int(n.blocked)),"font":int(round(20*pop)),"tint":SHIELD_COLOR,"shield":true,"source":n.source,"followup":n.actual <= 0 and n.get("followup",false)})
	for row in rows:
		row.height = FONT.get_height(row.font)+2
		row.text_width = FONT.get_string_size(row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.font).x
		row.prefix = 22 if row.shield else 0
		row.followup_width = FONT.get_string_size(FOLLOWUP_TEXT,HORIZONTAL_ALIGNMENT_LEFT,-1,FOLLOWUP_FONT_SIZE).x if row.followup else 0
		row.width = row.prefix+row.text_width+(26 if not row.source.is_empty() else 0)+(6+row.followup_width if row.followup else 0)
	return rows

func _damage_rect(base: Rect2, occupied: Array[Rect2]) -> Rect2:
	var safe := Rect2(16,174,1248,430)
	var best := Rect2(base.position.clamp(safe.position,safe.end-base.size),base.size)
	var best_score := INF
	var candidates: Array[Vector2] = []
	for dy in [0,-40,40,-80,80]:
		for dx in [0,-base.size.x-24,base.size.x+18,-148,148]:
			candidates.append(base.position+Vector2(dx,dy))
	# A long followup tag can land between grid samples; include nearby obstacle edges.
	for other in occupied:
		if not other.grow(8).intersects(base): continue
		candidates.append(Vector2(other.position.x-base.size.x-6,base.position.y))
		candidates.append(Vector2(other.end.x+6,base.position.y))
		candidates.append(Vector2(base.position.x,other.position.y-base.size.y-6))
		candidates.append(Vector2(base.position.x,other.end.y+6))
	for point in candidates:
		var at := point.clamp(safe.position,safe.end-base.size)
		var candidate := Rect2(at,base.size)
		var score := at.distance_squared_to(base.position)
		for other in occupied:
			if other.intersects(candidate): score += candidate.intersection(other).get_area()*10000
		if score < best_score: best = candidate; best_score = score
	return best

func _draw_damage_numbers() -> void:
	damage_bounds.clear()
	damage_source_bounds.clear()
	followup_bounds.clear()
	var reduced: bool = is_instance_valid(game.code_panel) and game.code_panel.code_fx.reduced_motion
	var occupied: Array[Rect2] = []
	for rect in status_rects.values(): occupied.append(rect.grow(3))
	if is_instance_valid(game.code_panel) and is_instance_valid(game.code_panel.activity):
		for rect in game.code_panel.activity.name_bounds: occupied.append(rect.grow(3))
	for u in game.units:
		if u.hp <= 0: continue
		occupied.append(Rect2(game._unit_center(u)+Vector2(-26,-102),Vector2(52,46)))
		if u.side == 1: occupied.append(Rect2(_bubble_position(u),Vector2(32,36)).grow(3))
	for n in damage_numbers:
		var rows := damage_rows(n,reduced)
		if rows.is_empty(): continue
		var extent := Vector2.ZERO
		for row in rows:
			extent.x = maxf(extent.x,row.width)
			extent.y += row.height
		var lift := 0.0 if reduced else 24*(1-pow(1-clampf(float(n.age)/DAMAGE_SECONDS,0,1),2))
		var base := Rect2(n.at+Vector2(8+int(n.lane)*12,-90-int(n.lane)*42-lift),extent)
		var bounds := _damage_rect(base,occupied)
		damage_bounds.append(bounds)
		occupied.append(bounds.grow(3))
		var alpha := clampf((DAMAGE_SECONDS-float(n.age))/0.25,0,1)
		var y := bounds.position.y
		for row in rows:
			var tint := Color(row.tint,alpha)
			var baseline := Vector2(bounds.position.x+row.prefix,y+FONT.get_ascent(row.font))
			if row.shield:
				StatusArt.draw(self,"intent_shield",Rect2(Vector2(bounds.position.x,y+(row.height-18)/2),Vector2(18,18)),tint)
			draw_string_outline(FONT,baseline+Vector2(1,2),row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.font,6,Color(0.02,0.04,0.06,0.28*alpha))
			draw_string_outline(FONT,baseline,row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.font,4,Color(0.035,0.055,0.075,alpha))
			draw_string(FONT,baseline,row.text,HORIZONTAL_ALIGNMENT_LEFT,-1,row.font,tint)
			if not row.source.is_empty():
				var icon := Rect2(Vector2(baseline.x+row.text_width+6,y+(row.height-20)/2),Vector2(20,20))
				StatusArt.draw_damage_source(self,row.source,icon,tint)
				damage_source_bounds.append({"kind":row.source,"rect":icon,"text_end":baseline.x+row.text_width})
				if row.followup:
					var tag := Rect2(Vector2(icon.end.x+6,y+(row.height-FONT.get_height(FOLLOWUP_FONT_SIZE))/2),Vector2(row.followup_width,FONT.get_height(FOLLOWUP_FONT_SIZE)))
					var tag_at := tag.position+Vector2(0,FONT.get_ascent(FOLLOWUP_FONT_SIZE))
					draw_string_outline(FONT,tag_at,FOLLOWUP_TEXT,HORIZONTAL_ALIGNMENT_LEFT,-1,FOLLOWUP_FONT_SIZE,3,Color(0.035,0.055,0.075,alpha))
					draw_string(FONT,tag_at,FOLLOWUP_TEXT,HORIZONTAL_ALIGNMENT_LEFT,-1,FOLLOWUP_FONT_SIZE,Color(Color("e7ccc0"),alpha*0.86))
					followup_bounds.append({"rect":tag,"icon_end":icon.end.x,"font":FOLLOWUP_FONT_SIZE})
			y += row.height

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
