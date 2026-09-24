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
	z_index = 4000

func consume(event: Dictionary) -> void:
	var kind: String = event.get("kind", "")
	if kind == "code_generated":
		var type: String = event.code_type
		var interface_event: bool = event.reason in ["代码补给", "转码器"]
		var from: Vector2 = host.code_origin(event) if host.has_method("code_origin") else host.board.global_position + host.board.point(event.from) - Vector2(0,45)
		var target: Control = host.bank_labels[type]
		if interface_event:
			var item: String = "supply" if event.reason == "代码补给" else "converter"
			from = host.item_controls[item].button.get_global_rect().get_center()
		for index in range(int(event.actual)):
			_append({"kind":"drop", "type":type, "from":from, "target":target, "offset":Vector2((index-1)*24,0), "age":-index*0.07, "duration":1.15, "ui":interface_event})
	elif kind == "hack_completed":
		var id: String = event.choice
		_append({"kind":"program", "id":id, "targets":event.get("affected_ids",[]).duplicate(), "age":0.0, "duration":2.2, "ui":false})

func _append(particle: Dictionary) -> void:
	if particles.size() >= 64: particles.pop_front()
	particles.append(particle)
	queue_redraw()

func advance(delta: float, frozen: bool) -> void:
	for particle in particles:
		if particle.ui or not frozen: particle.age += maxf(0, delta)
	particles = particles.filter(func(p): return p.age < p.duration)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(host): advance(minf(delta, 0.05), host.feedback_frozen() if host.has_method("feedback_frozen") else host.paused)

func _draw() -> void:
	for p in particles:
		if p.age < 0: continue
		var t: float = p.age / p.duration
		if p.kind == "drop": _draw_drop(p, t)
		else: _draw_program(p, t)

func _draw_drop(p: Dictionary, t: float) -> void:
	if not is_instance_valid(p.target): return
	var data: Dictionary = Codes.RULES.types[p.type]
	var color: Color = data.color
	var destination: Vector2 = p.target.get_global_rect().get_center()
	var from: Vector2 = p.from + p.offset
	var at: Vector2
	if reduced_motion: at = destination
	elif t < 0.35:
		var bounce: float = t / 0.35
		at = from + Vector2(20*bounce, -65*sin(bounce*PI))
	else:
		var flight := clampf((t-0.35)/0.5,0,1)
		at = (from+Vector2(20,0)).lerp(destination, flight*flight)
		at.y -= sin(flight*PI)*50
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
