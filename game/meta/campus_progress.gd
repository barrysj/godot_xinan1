extends RefCounted
## Atomic profile: meta progress, current expedition and dispatch jobs commit together.
const Catalog = preload("res://game/meta/meta_catalog.gd")
var points = 0
var completions = 0
var supply_unlocked = false
var upgrades: Dictionary = {}
var active_run: Dictionary = {}
var dispatches: Array = []
var last_settled_run = ""
var path = "user://campus_progress.json"
var error_message = ""
var load_blocked = false

func to_dict() -> Dictionary:
	return {"version":2, "points":points, "completions":completions, "supply_unlocked":supply_unlocked,
		"upgrades":upgrades.duplicate(true), "active_run":active_run.duplicate(true),
		"dispatches":dispatches.duplicate(true), "last_settled_run":last_settled_run}

func _apply(data: Dictionary) -> void:
	points = maxi(0,int(data.get("points",0)))
	completions = maxi(0,int(data.get("completions",0)))
	upgrades = data.get("upgrades",{}).duplicate(true)
	supply_unlocked = bool(data.get("supply_unlocked",false)) or level("supply") > 0
	if supply_unlocked: upgrades.supply = 1
	active_run = data.get("active_run",{}).duplicate(true)
	dispatches = data.get("dispatches",[]).duplicate(true)
	last_settled_run = str(data.get("last_settled_run",""))

func read_save() -> bool:
	if not FileAccess.file_exists(path): return true
	var file = FileAccess.open(path,FileAccess.READ)
	if file == null: return _invalid_save()
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return _invalid_save()
	var data = parser.data
	if not data is Dictionary: return _invalid_save()
	if data.get("version",0) != 1 and data.get("version",0) != 2: return _invalid_save()
	if not data.get("upgrades",{}) is Dictionary or not data.get("active_run",{}) is Dictionary or not data.get("dispatches",[]) is Array: return _invalid_save()
	for key in ["points","completions"]:
		if not (data.get(key,0) is int or data.get(key,0) is float): return _invalid_save()
	for item in Catalog.UNLOCKS:
		var count = data.get("upgrades",{}).get(item.id,0)
		if not (count is int or count is float) or count < 0 or count > item.costs.size() or int(count) != count: return _invalid_save()
	var workers: Array = []
	var ids: Array = []
	if data.get("dispatches",[]).size() > 2: return _invalid_save()
	for job in data.get("dispatches",[]):
		if not job is Dictionary: return _invalid_save()
		if not job.get("id",null) is String or ids.has(job.id): return _invalid_save()
		if Catalog.find(Catalog.STAFF,str(job.get("staff",""))).is_empty() or workers.has(job.staff): return _invalid_save()
		if Catalog.find(Catalog.LOCATIONS,str(job.get("location",""))).is_empty(): return _invalid_save()
		for key in ["started_at","ready_at","reward"]:
			if not (job.get(key) is int or job.get(key) is float) or job[key] < 0: return _invalid_save()
		if job.ready_at < job.started_at: return _invalid_save()
		workers.append(job.staff)
		ids.append(job.id)
	_apply(data)
	load_blocked = false
	error_message = ""
	return true

func _invalid_save() -> bool:
	load_blocked = true
	error_message = "存档无法识别，已保留原文件并禁止覆盖"
	return false

func write_save() -> bool:
	if load_blocked: return false
	var file = FileAccess.open(path + ".tmp",FileAccess.WRITE)
	if file == null:
		error_message = "自动保存失败：无法写入，请重试"
		return false
	file.store_string(JSON.stringify(to_dict()))
	file.flush()
	var code = file.get_error()
	file.close()
	if code != OK:
		error_message = "自动保存失败：写入未完成"
		return false
	code = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"),ProjectSettings.globalize_path(path))
	if code != OK:
		error_message = "自动保存失败：无法替换存档"
		return false
	error_message = ""
	return true

func _commit(before: Dictionary) -> bool:
	if write_save(): return true
	_apply(before)
	return false

func level(id: String) -> int:
	return int(upgrades.get(id,0))

func unlock_reason(id: String) -> String:
	var item = Catalog.find(Catalog.UNLOCKS,id)
	if item.is_empty(): return "没有这个升级"
	if level(id) >= item.costs.size(): return "已满级"
	if not item.requires.is_empty() and level(item.requires) == 0: return "需要先解锁派遣事务所"
	if points < item.costs[level(id)]: return "修复资源不足"
	return ""

func purchase(id: String) -> bool:
	var reason = unlock_reason(id)
	if not reason.is_empty():
		error_message = reason
		return false
	var before = to_dict()
	var item = Catalog.find(Catalog.UNLOCKS,id)
	points -= int(item.costs[level(id)])
	upgrades[id] = level(id) + 1
	supply_unlocked = level("supply") > 0
	return _commit(before)

func unlock_supply() -> bool:
	return purchase("supply")

func save_checkpoint(snapshot: Dictionary) -> bool:
	var before = to_dict()
	active_run = snapshot.duplicate(true)
	return _commit(before)

func finish_run(snapshot: Dictionary, earned: int) -> bool:
	var before = to_dict()
	var id = str(snapshot.run.id)
	if last_settled_run != id:
		points += maxi(0,earned)
		completions += 1
		last_settled_run = id
	active_run = snapshot.duplicate(true)
	return _commit(before)

func available_staff() -> Array:
	return Catalog.STAFF.filter(func(staff): return staff.requires.is_empty() or level(staff.requires) > 0)

func busy(staff_id: String) -> bool:
	for job in dispatches:
		if job.staff == staff_id: return true
	return false

func dispatch_reason(staff_id: String, location_id: String) -> String:
	var location = Catalog.find(Catalog.LOCATIONS,location_id)
	if location.is_empty(): return "地点不存在"
	if level(location.requires) == 0: return "地点尚未解锁"
	if Catalog.find(available_staff(),staff_id).is_empty(): return "请选择已加入的支援同学"
	if busy(staff_id): return "同学执行任务中"
	if dispatches.size() >= (2 if level("staffing") > 0 else 1): return "派遣队伍已满"
	if points < location.cost: return "修复资源不足"
	return ""

func start_dispatch(staff_id: String, location_id: String, now: int = -1) -> bool:
	var reason = dispatch_reason(staff_id,location_id)
	if not reason.is_empty():
		error_message = reason
		return false
	if now < 0: now = int(Time.get_unix_time_from_system())
	var before = to_dict()
	var location = Catalog.find(Catalog.LOCATIONS,location_id)
	points -= int(location.cost)
	dispatches.append({"id":Crypto.new().generate_random_bytes(16).hex_encode(), "staff":staff_id,
		"location":location_id, "started_at":now, "ready_at":now + int(location.duration), "reward":int(location.reward)})
	return _commit(before)

func claim_dispatch(id: String, now: int = -1) -> bool:
	if now < 0: now = int(Time.get_unix_time_from_system())
	for i in range(dispatches.size()):
		var job: Dictionary = dispatches[i]
		if job.id != id: continue
		if now < int(job.ready_at):
			error_message = "队伍还未返回"
			return false
		var before = to_dict()
		points += int(job.reward)
		dispatches.remove_at(i)
		return _commit(before)
	error_message = "这份成果已经领取"
	return false
