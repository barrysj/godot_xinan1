extends "res://scenes/expedition/campus_map_targets.gd"
## Every geographic place in one region's route, including completed/future stops.
const Presentation = preload("res://game/run/campus_presentation.gd")
var region := ""
var flow: Dictionary
var nodes: Array[Dictionary] = []
var texture_state := ""
var current_layer := -1
var visited: Array = []

func _ready() -> void:
	nodes = Presentation.map_nodes(region, board.layout, flow)
	compact = true
	draw_all_connections = true
	for node in nodes:
		points.append(node.point)
		titles.append(node.title)
		thumbnails.append(load(Presentation.background(region, node.stop, "daily" if board.map_state == "day" else "anomaly", flow)))
		numbers.append(str(node.layer+1))
	for first in nodes:
		for next in nodes:
			if int(next.layer) == int(first.layer)+1:
				connections.append({"index":0,"from":first.point,"to":next.point})
	super._ready()
	texture_state = board.map_state

func sync() -> void:
	super.sync()

	if nodes.is_empty() or texture_state == board.map_state: return
	texture_state = board.map_state
	for i in range(nodes.size()):
		buttons[i].set_thumbnail(load(Presentation.background(region, nodes[i].stop, "daily" if board.map_state == "day" else "anomaly", flow)))

func _position_buttons() -> void:
	super._position_buttons()
	# Closely stacked places keep circles at their anchors, with the upper caption above.
	for i in range(buttons.size()):
		buttons[i].name_label.position.y = 100
		buttons[i].badge.text = "✓" if visited.has(nodes[i].stop) else str(nodes[i].layer+1)
		buttons[i].photo.modulate.a = .65 if current_layer >= 0 and nodes[i].layer != current_layer and i != selected else 1.0
		buttons[i].tooltip_text = nodes[i].title + (" · 当前可选" if nodes[i].layer == current_layer else " · 点击查看")
		for j in range(buttons.size()):
			if i == j: continue
			var delta: Vector2 = buttons[j].position - buttons[i].position
			if absf(delta.x) < 90 and delta.y > 0 and delta.y < 110:
				buttons[i].name_label.position.y = -44
