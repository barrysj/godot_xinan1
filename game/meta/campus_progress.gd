extends RefCounted
## Permanent progress is separate from the disposable expedition state.

var points = 0
var completions = 0
var supply_unlocked = false
var path = "user://campus_progress.json"
var error_message = ""

func read_save() -> void:
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "无法读取进度文件"
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version", 0) != 1:
		error_message = "进度文件格式无法识别，未覆盖原文件"
		return
	points = maxi(0, int(data.get("points", 0)))
	completions = maxi(0, int(data.get("completions", 0)))
	supply_unlocked = bool(data.get("supply_unlocked", false))

func write_save() -> bool:
	# Write a sibling temporary file first; preserve the previous save on failure.
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error_message = "进度未能保存，请检查存储权限"
		return false
	file.store_string(JSON.stringify({"version": 1, "points": points, "completions": completions, "supply_unlocked": supply_unlocked}))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		error_message = "进度写入失败"
		return false
	var result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	if result != OK:
		error_message = "无法替换进度文件"
		return false
	error_message = ""
	return true

func unlock_supply() -> bool:
	if supply_unlocked or points < 3:
		return false
	points -= 3
	supply_unlocked = true
	if not write_save():
		points += 3
		supply_unlocked = false
		return false
	return true
