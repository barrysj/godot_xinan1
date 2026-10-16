extends Node
## Opt-in timing harness: the actual launcher and campaign, with an isolated profile.
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/game-launcher/startup-game.png")
	print("STARTUP_RENDERED engine_msec=%d" % Time.get_ticks_msec())
	get_tree().quit()
