extends Node
## Exercise the real campaign view clock and simulation event boundary.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Style = preload("res://game/content/battle_cast_vfx_style.gd")
const AnimationSet = preload("res://game/content/battle_animation_set.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAST_VFX_CHECK: " + label)

func _ready() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/cast-vfx-check-profile.json"
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game.storage_ready = false
	game.run.node = {"id": "", "name": "特效验证", "kind": "battle", "encounter": 0,
		"encounter_id": "encounter_final", "power": 1.0}
	game.formation = [0, -1, -1, 2, 1, 4]
	var roster: Array[int] = [0, 1, 2, 4]
	game.run.roster = roster
	game.screen = "battle"
	game.campaign_panel.hide()
	game._start()
	var actor: Dictionary = game.units.filter(func(unit): return unit.side == 0 and unit.role == 1)[0]
	var target: Dictionary = game.units.filter(func(unit): return unit.side == 1)[0]
	var appearance = AnimationSet.new()
	appearance.cast_vfx_style = Style.new()
	actor.battle_animation = appearance
	var style: Resource = appearance.cast_vfx_style
	var release := {"kind": "action_released", "actor_id": actor.id, "target_id": target.id,
		"action_id": 100, "casts": true, "from": actor.position, "to": target.position}
	# Presentation consumes real-format cues, without invoking any damage effects.
	var hp_before: float = target.hp
	game._present_simulation_event(release)
	check(game.cast_vfx.bursts.size() == 1, "one cast release flash")
	game._present_simulation_event(release)
	check(game.cast_vfx.bursts.size() == 1, "repeated release cue does not duplicate shock rings")
	check(target.hp == hp_before and game.simulation.projectiles.is_empty(), "VFX never deals damage or creates simulation projectiles")
	game.paused = true
	game._process(0.1)
	check(game.cast_vfx.bursts[0].age == 0.0, "pause freezes transient age")
	game.paused = false
	game.speed = 2
	game._process(0.05)
	check(is_equal_approx(game.cast_vfx.bursts[0].age, 0.1), "2x presentation clock")
	game.speed = 1
	game._process(0.05)
	check(is_equal_approx(game.cast_vfx.bursts[0].age, 0.15), "1x presentation clock")
	var precise: Dictionary = game.cast_vfx.bursts[0].duplicate()
	precise.position = Vector2(50, 70)
	precise.direction = Vector2.RIGHT
	precise.age = 0.05
	var early: Dictionary = game.cast_vfx.sonic_rings(precise)[0]
	precise.age = 0.20
	var late: Dictionary = game.cast_vfx.sonic_rings(precise)[0]
	check(late.radius > early.radius and late.center.x > early.center.x and late.alpha < early.alpha, "shock wave expands, travels forward and fades")
	check(is_equal_approx(late.center.y, precise.position.y), "wave remains on the real shot axis")
	check(late.points[0].distance_to(late.center) < late.points[12].distance_to(late.center), "wavefront is flattened along shot direction")
	precise.direction = Vector2.LEFT
	var mirrored: Dictionary = game.cast_vfx.sonic_rings(precise)[0]
	check(mirrored.center.x < precise.position.x and is_equal_approx(mirrored.radius, late.radius), "left-facing wave mirrors without changing size")
	precise.direction = Vector2(-2, 3)
	var diagonal: Dictionary = game.cast_vfx.sonic_rings(precise)[0]
	check((diagonal.center - precise.position).normalized().is_equal_approx(precise.direction.normalized()), "diagonal wave follows actual aim")
	precise.direction = Vector2.ZERO
	check(game.cast_vfx.sonic_rings(precise)[0].center.is_finite(), "coincident target has finite fallback geometry")
	precise.age = precise.duration
	check(game.cast_vfx.sonic_rings(precise).is_empty(), "expired wave does not draw")
	game.cast_vfx.clear()
	var hit := {"kind": "impact", "special": true, "effect": "damage", "action_id": 100, "target_id": target.id}
	game.cast_vfx.consume(hit, style, Vector2.ZERO, Vector2.ONE)
	game.cast_vfx.consume(hit, style, Vector2.ZERO, Vector2.ONE)
	check(game.cast_vfx.bursts.size() == 1, "multiple same-action hits deduplicate per target")
	hit.target_id += 1
	game.cast_vfx.consume(hit, style, Vector2.ZERO, Vector2.ONE)
	check(game.cast_vfx.bursts.size() == 2, "separate targets each receive a flash")
	game.cast_vfx.advance(0.5)
	check(game.cast_vfx.bursts.is_empty(), "expired bursts removed")
	for kind in ["action_started", "action_missed", "action_cancelled", "action_finished"]:
		var cue := release.duplicate()
		cue.kind = kind
		game.cast_vfx.consume(cue, style, Vector2.ZERO, Vector2.ONE)
	check(game.cast_vfx.bursts.is_empty(), "no flash on preparation, miss or cancellation")
	release.casts = false
	game.cast_vfx.consume(release, style, Vector2.ZERO, Vector2.ONE)
	hit.special = false
	game.cast_vfx.consume(hit, style, Vector2.ZERO, Vector2.ONE)
	check(game.cast_vfx.bursts.is_empty(), "basic attack keeps legacy effects")
	release.casts = true
	game.cast_vfx.consume(release, null, Vector2.ZERO, Vector2.ONE)
	check(game.cast_vfx.bursts.is_empty(), "appearance without style keeps legacy effects")
	style.shape = 1
	game.cast_vfx.consume(release, style, Vector2.ZERO, Vector2.ONE)
	check(is_equal_approx(game.cast_vfx.remaining(), 0.60), "heavy release duration")
	var heavy: Dictionary = game.cast_vfx.bursts[0]
	check(game.cast_vfx.sonic_rings(heavy).size() == 1, "heavy ignition starts with one wave")
	heavy.age = 0.12
	var echoes: Array[Dictionary] = game.cast_vfx.sonic_rings(heavy)
	check(echoes.size() == 2 and echoes[1].radius < echoes[0].radius and echoes[1].center.distance_to(heavy.position) < echoes[0].center.distance_to(heavy.position), "heavy second wave follows behind with a staggered smaller radius")
	game.cast_vfx.advance(0.50)
	check(game.cast_vfx.bursts.is_empty(), "heavy echo removed after its full lifetime")
	actor.presentation.facing_right = false
	check(game._cast_muzzle(actor).x < game._unit_center(actor).x, "left-facing muzzle mirrors")
	actor.presentation.facing_right = true
	check(game._cast_muzzle(actor).x > game._unit_center(actor).x, "right-facing muzzle mirrors")
	game._build_units()
	check(game.cast_vfx.bursts.is_empty(), "battle rebuild clears all transients")
	print("CAST_VFX_CHECK %d checks / %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
