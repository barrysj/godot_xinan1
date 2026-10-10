extends Node2D
## One stable ground-contact pivot shared by authored rigs and fallback drawings.
var game
var actor: Dictionary

func _draw() -> void:
	if not is_instance_valid(game) or actor.is_empty(): return
	var rig: Node2D = game.battle_presentations.get(actor.id)
	if is_instance_valid(rig) and (not rig.has_method("handles_presentation_state") or rig.call("handles_presentation_state", actor.animation.state)):
		return
	game._draw_fallback_pawn(self, actor, game._unit_center(actor) + Vector2(0,13))
