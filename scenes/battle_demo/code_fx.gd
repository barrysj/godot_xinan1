extends Control
## Visual-only particles. Resource changes are already resolved by the simulation.
const Codes = preload("res://game/combat/code_catalog.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const Burst = preload("res://scenes/battle_demo/hack_burst.gd")
var host
var particles: Array[Dictionary] = []
var reduced_motion := false

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	z_index = 2 # Above battlefield art; below details and modal UI.

func consume(event: Dictionary) -> void:
	var kind: String = event.get("kind", "")
	if kind == "code_generated":
		var type: String = event.code_type
		var interface_event: bool = event.reason in ["代码补给", "转码器"]
		var from: Vector2 = host.code_origin(event) if host.has_method("code_origin") else host.board.global_position + host.board.point(event.from) - Vector2(0,45)
		if int(event.get("cycle_id",-1)) >= 0 and not event.get("reason","") == "护盾吸收":
			var status = host.game.battle_status_layer
			if status.anchors.has(event.actor_id): from = host.game.origin+(status.anchors[event.actor_id]+Vector2(8,38))*host.game.scale_factor
		var target: Control = host.bank_labels[type]
		if interface_event:
			var item: String = "supply" if event.reason == "代码补给" else "converter"
			from = host.item_controls[item].button.get_global_rect().get_center()
		for index in range(int(event.actual)):
			_append({"kind":"drop", "type":type, "from":from, "target":target, "offset":Vector2((index-1)*24,0), "age":-index*0.07, "duration":0.4, "ui":interface_event})
	elif kind == "enemy_release":
		_append({"kind":"enemy_release", "at":event.from, "center":event.get("center",event.from), "mode":event.get("mode",""), "age":0.0, "duration":0.55, "ui":false})
	elif kind == "recoil_burst":
		_append({"kind":"blast", "at":event.from, "radius":event.get("radius",2.0), "age":0.0, "duration":0.7, "ui":false})
	elif kind == "chain_followup":
		_append({"kind":"follow", "from":event.from, "to":event.to, "age":0.0, "duration":0.35, "ui":false})
	elif kind == "hack_completed":
		var id: String = event.choice
		_append({"kind":"program", "id":id, "targets":event.get("affected_ids",[]).duplicate(), "age":0.0, "duration":1.1, "ui":false})

func _append(particle: Dictionary) -> void:
	if particles.size() >= 64: particles.pop_front()
	particles.append(particle)
	queue_redraw()

func advance(delta: float, frozen: bool) -> void:
	for particle in particles:
		if particle.ui or not frozen: particle.age += maxf(0, delta)*(1.0 if particle.ui else float(host.game.speed))
	particles = particles.filter(func(p): return p.age < p.duration)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(host): advance(minf(delta, 0.05), host.feedback_frozen() if host.has_method("feedback_frozen") else host.paused)

func _draw() -> void:
	_draw_chain_states()
	for p in particles:
		if p.age < 0: continue
		var t: float = p.age / p.duration
		if p.kind == "drop": _draw_drop(p, t)
		elif p.kind == "blast":
			var ring := PackedVector2Array()
			for i in range(33): ring.append(_battle_point(p.at+Vector2.from_angle(TAU*i/32)*float(p.radius)*(0.3+0.7*t)))
			draw_polyline(ring,Color(0.7,0.45,1,1-t),3,true)
			if not reduced_motion:
				var center: Vector2 = _battle_point(p.at)-Vector2(0,28)*host.game.scale_factor
				for i in range(8):
					var direction := Vector2.from_angle(TAU*i/8)
					var at: Vector2 = center+direction*(18+65*(1-pow(1-t,3)))*host.game.scale_factor
					draw_line(at,at-direction*10*host.game.scale_factor,Color(0.88,0.7,1,1-t),2*host.game.scale_factor,true)
		elif p.kind == "enemy_release":
			var scale: float = host.game.scale_factor
			var eased := 1.0 - pow(1.0-t,3)
			var tint := Color("8bdfff") if p.mode == "radio" else Color("ffa070")
			tint.a = 1-t
			if p.mode == "board":
				var left := _battle_point(Vector2(0,p.center.y))
				var right := _battle_point(Vector2(6,p.center.y))
				draw_line(left,right,Color(tint,(1-t)*0.18),18*scale,true)
				draw_line(left,right,tint,3*scale,true)
			elif p.mode == "radio":
				var radius: float = 45 if reduced_motion else lerpf(25,95,eased)
				draw_arc(_battle_point(p.at)-Vector2(0,26)*scale,radius*scale,0,TAU,40,tint,2*scale,true)
			else:
				var ring := PackedVector2Array()
				for i in range(41): ring.append(_battle_point(p.center+Vector2.from_angle(TAU*i/40)*2*(1.0 if reduced_motion else eased)))
				draw_polyline(ring,Color(tint,(1-t)*0.12),12*scale,true)
				draw_polyline(ring,tint,2.5*scale,true)
		elif p.kind == "follow":
			draw_line(_battle_point(p.from)-Vector2(0,35), _battle_point(p.to)-Vector2(0,35), Color(0.4,0.85,1,1-t), 3, true)
		else: _draw_program(p, t)

func _draw_drop(p: Dictionary, t: float) -> void:
	if not is_instance_valid(p.target): return
	var data: Dictionary = Codes.RULES.types[p.type]
	var color: Color = data.color
	var destination: Vector2 = p.target.get_global_rect().get_center()
	var from: Vector2 = p.from + p.offset
	var at: Vector2
	if reduced_motion: at = destination
	else:
		var flight := clampf(t/0.85,0,1)
		var eased := 1-pow(1-flight,2)
		at = from.lerp(destination,eased)
		at.y -= sin(flight*PI)*35
	if t < 0.85:
		for i in range(3):
			draw_circle(at + Vector2(-i*7,i*5), 13-i*3, Color(color,0.13-i*0.03))
		draw_rect(Rect2(at-Vector2(15,15),Vector2(30,30)),Color("142638"))
		draw_rect(Rect2(at-Vector2(15,15),Vector2(30,30)),color,false,2)
		draw_string(FONT,at+Vector2(-12,7),data.symbol,HORIZONTAL_ALIGNMENT_CENTER,24,19,color)
	else:
		var fade: float = (1-t)/0.15
		draw_arc(destination, 18+(1-fade)*22,0,TAU,24,Color(color,fade),2,true)
		draw_string(FONT,destination+Vector2(20,-12),"+1",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(color,fade))

func _draw_program(p: Dictionary, t: float) -> void:
	Burst.draw(self,host.game,p,t,reduced_motion)


func _battle_point(at: Vector2) -> Vector2:
	return host.game.origin + host.game._project(at) * host.game.scale_factor

func _draw_chain_states() -> void:
	if not is_instance_valid(host) or not host.running: return
	var sim = host.sim
	for id in sim.marks:
		var unit: Dictionary = sim.unit(id)
		if unit.hp <= 0: continue
		var mark: Dictionary = sim.marks[id]
		var exposed: bool = mark.get("exposed_until", 0.0) > sim.elapsed
		var confirmed: bool = mark.get("confirmed_until", 0.0) > sim.elapsed
		var color := Color("ffb85c") if exposed else Color("67d7ff")
		var at := _battle_point(unit.position)
		draw_arc(at + Vector2(0,12), 34, 0, TAU, 28, color, 3 if exposed else 2, true)
		draw_string(FONT, at-Vector2(32,80), "暴露" if exposed else "漏洞已验证" if confirmed else "待验证", HORIZONTAL_ALIGNMENT_CENTER, 64, 16, color)
	for actor_id in sim.warnings:
		var warning: Dictionary = sim.warnings[actor_id]
		var actor: Dictionary = sim.unit(actor_id)
		if actor.hp <= 0: continue
		var center: Vector2 = warning.center
		var points := PackedVector2Array()
		if warning.get("mode", "") == "board" or warning.label == "整排写入":
			points = PackedVector2Array([_battle_point(Vector2(0,center.y-0.5)),_battle_point(Vector2(6,center.y-0.5)),_battle_point(Vector2(6,center.y+0.5)),_battle_point(Vector2(0,center.y+0.5))])
		elif warning.get("mode", "") == "colossus" or warning.label == "巨像重击":
			for i in range(33): points.append(_battle_point(center + Vector2.from_angle(TAU*i/32)*2))
		if points.size() > 0:
			draw_colored_polygon(points,Color(1,0.35,0.2,0.15))
			points.append(points[0])
			draw_polyline(points,Color("ff8b6d"),2,true)
