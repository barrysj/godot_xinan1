extends Node
## Render the actual registered radio through the original battle renderer.
var failures := 0
class RenderedActor extends Node2D:
	var battle
	var actor: Dictionary
	func _draw() -> void:
		var origin: Vector2 = battle.origin
		var factor: float = battle.scale_factor
		battle.origin = Vector2.ZERO
		battle.scale_factor = 1
		battle._draw_fallback_pawn(self,actor,Vector2(128,232.5),4)
		battle.origin = origin
		battle.scale_factor = factor

func verify(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("RADIO_FACING_CHECK: "+label)

func _ready() -> void:
	call_deferred("run_check")

func run_check() -> void:
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	battle.set_process(false)
	battle.formation = [0,-1,3,2,1,-1]
	battle.phase = "prepare"
	battle._build_units()
	var actor: Dictionary = battle.units.filter(func(unit): return unit.content_id == "radio")[0]
	if DisplayServer.get_name() != "headless":
		battle.origin = Vector2.ZERO
		battle.scale_factor = 1
		var viewport := SubViewport.new()
		viewport.size = Vector2i(256,256)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var view := RenderedActor.new()
		view.battle = battle
		view.actor = actor
		viewport.add_child(view)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image: Image = viewport.get_texture().get_image()
		var total := 0.0
		var weighted := 0.0
		# The blue microphone eye is above the speakers. Its screen centroid
		# must lie to the left of the sprite center, as in the original sheet.
		for y in range(139,151):
			for x in range(80,176):
				var color: Color = image.get_pixel(x,y)
				if color.a > 0.25 and color.r < 0.35 and color.g > 0.55 and color.b > 0.55:
					var weight := color.g+color.b-2*color.r
					total += weight
					weighted += x*weight
		print("RADIO_EYE_SCREEN_X=",weighted/maxf(total,0.001)," center=128 weight=",total)
		verify(total > 0.5 and weighted/total < 128,"actual rendered microphone points left")
		verify(image.save_png("res://.godot/radio-facing.png") == OK,"actual sprite capture saved")
		viewport.queue_free()
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			get_window().size = resolution
			await get_tree().process_frame
			await get_tree().process_frame
			battle._update_battle_presentations()
			await RenderingServer.frame_post_draw
			verify(get_viewport().get_texture().get_image().save_png("res://.godot/radio-battle-%dx%d.png" % [resolution.x,resolution.y]) == OK,"actual battle screenshot saved")
	else:
		verify(not actor.battle_animation.should_flip(actor.presentation.facing_right),"native left-facing radio must not be flipped to the right")
	print("RADIO_FACING_CHECK ","PASS" if failures == 0 else "FAIL"," failures=",failures)
	get_tree().quit(failures)
