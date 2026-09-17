extends RefCounted
var checks = 0
var failures = 0

class FailedWriter extends "res://game/meta/campus_progress.gd":
	func write_save() -> bool:
		error_message = "injected write failure"
		return false

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROFILE_RESET: " + label)

func run_checks(hub) -> void:
	hub.set_process(false)
	hub.progress = hub.ProgressModel.new()
	hub.progress.path = "res://.godot/profile-reset-ui.json"
	hub.progress.points = 37
	hub.progress.complete_prologue()
	hub._home()
	var original = FileAccess.get_file_as_bytes(hub.progress.path)
	hub._campaign_action("reset_confirm")
	verify(hub.progress.points == 37,"unconfirmed reset rejected")
	hub._campaign_action("reset_profile")
	if DisplayServer.get_name() != "headless":
		await hub.get_tree().process_frame
		await RenderingServer.frame_post_draw
		hub.get_viewport().get_texture().get_image().save_png("res://.godot/profile-reset-confirm.png")
	hub._campaign_action("reset_cancel")
	verify(FileAccess.get_file_as_bytes(hub.progress.path) == original,"cancel preserves bytes")
	hub._campaign_action("reset_profile")
	hub._campaign_action("reset_confirm")
	verify(hub.progress.to_dict() == hub.ProgressModel.new().to_dict(),"all profile fields reset")
	verify(FileAccess.get_file_as_bytes(hub.progress.last_backup_path) == original,"backup matches original bytes")
	var reloaded = hub.ProgressModel.new()
	reloaded.path = hub.progress.path
	verify(reloaded.read_save() and reloaded.to_dict() == hub.progress.to_dict(),"fresh save reloads")
	verify(hub.campaign_mode.is_empty() and hub.screen == "base" and not hub.reset_pending,"runtime returns to clean home")
	var first_backup = hub.progress.last_backup_path
	verify(hub.progress.restart_profile() and hub.progress.last_backup_path != first_backup,"unique backup per restart")
	verify(FileAccess.get_file_as_bytes(first_backup) == original,"previous backup preserved")
	var broken = FileAccess.open(hub.progress.path,FileAccess.WRITE)
	broken.store_string("not a valid profile")
	broken.close()
	verify(not hub.progress.read_save(),"corrupt fixture rejected")
	hub._home()
	hub._campaign_action("reset_profile")
	hub._campaign_action("reset_confirm")
	verify(not hub.progress.load_blocked and reloaded.read_save(),"explicit reset recovers corrupt profile")
	verify(FileAccess.get_file_as_string(hub.progress.last_backup_path) == "not a valid profile","corrupt bytes preserved")
	var failed = FailedWriter.new()
	failed.path = hub.progress.path
	failed.points = 91
	failed.load_blocked = true
	var disk = FileAccess.get_file_as_bytes(failed.path)
	verify(not failed.restart_profile() and failed.points == 91 and failed.load_blocked,"write failure restores memory and blocked state")
	verify(FileAccess.get_file_as_bytes(failed.path) == disk,"write failure preserves original disk")
	failed.path = "res://.godot/nonexistent-reset-directory/profile.json"
	verify(not failed.restart_profile() and failed.points == 91,"missing directory fails safely")
	print("PROFILE_RESET_CHECK %d checks / %d failures" % [checks,failures])
	hub.get_tree().quit(0 if failures == 0 else 1)
