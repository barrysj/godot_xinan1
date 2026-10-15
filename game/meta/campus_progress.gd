extends RefCounted
## Atomic profile: meta progress, current expedition and dispatch jobs commit together.
const Catalog = preload("res://game/meta/meta_catalog.gd")
const Campaign = preload("res://game/meta/campaign_state.gd")
const Commissions = preload("res://game/meta/dispatch_catalog.gd")
var commission_unlocks: Array = []
var pending_dispatch_result: Dictionary = {}
var campaign: Dictionary = Campaign.fresh()
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
var last_backup_path = ""

func restart_profile() -> bool:
	# Copy the original bytes, including unreadable saves, before replacing anything.
	last_backup_path = ""
	if FileAccess.file_exists(path):
		var suffix = "%d-%s" % [int(Time.get_unix_time_from_system()), Crypto.new().generate_random_bytes(8).hex_encode()]
		var backup = path + ".backup-" + suffix
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup)) != OK:
			error_message = "旧档备份失败，未重开存档"
			return false
		last_backup_path = backup
	var before = to_dict()
	var was_blocked = load_blocked
	_apply(get_script().new().to_dict())
	load_blocked = false
	if write_save(): return true
	_apply(before)
	load_blocked = was_blocked
	return false

func to_dict() -> Dictionary:
	return {"version":5, "commission_unlocks":commission_unlocks.duplicate(), "pending_dispatch_result":pending_dispatch_result.duplicate(true), "campaign":campaign.duplicate(true), "points":points, "completions":completions, "supply_unlocked":supply_unlocked,
		"upgrades":upgrades.duplicate(true), "active_run":active_run.duplicate(true),
		"dispatches":dispatches.duplicate(true), "last_settled_run":last_settled_run}

func _apply(data: Dictionary) -> void:
	commission_unlocks = data.get("commission_unlocks", []).duplicate()
	pending_dispatch_result = data.get("pending_dispatch_result", {}).duplicate(true)
	campaign = data.get("campaign", Campaign.fresh()).duplicate(true)
	if not campaign.has("story_flags"): campaign.story_flags = {}
	campaign.schema = int(campaign.schema)
	campaign.finale_stage = int(campaign.finale_stage)
	if not campaign.has("formation"): campaign.formation = Campaign.fresh().formation
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
	if not (data.get("version") is int or data.get("version") is float): return _invalid_save()
	if int(data.version) != data.version or not int(data.version) in [1, 2, 3, 4, 5]: return _invalid_save()
	if data.version >= 4 and not Campaign.valid(data.get("campaign")): return _invalid_save()
	if data.version >= 5:
		if not data.get("commission_unlocks") is Array or not data.get("pending_dispatch_result") is Dictionary: return _invalid_save()
		var seen_unlocks: Array = []
		for id in data.commission_unlocks:
			if not id is String or Commissions.find(id).is_empty() or seen_unlocks.has(id): return _invalid_save()
			seen_unlocks.append(id)
		var result: Dictionary = data.pending_dispatch_result
		if not result.is_empty():
			if not result.get("id") is String or not result.get("commission") in seen_unlocks: return _invalid_save()
			if not result.get("staff_ids") is Array or result.staff_ids.size() != 1: return _invalid_save()
			if Catalog.find(Catalog.STAFF, str(result.staff_ids[0])).is_empty(): return _invalid_save()
			if not result.get("location") is String or str(result.location).is_empty(): return _invalid_save()
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
		var crew = job.get("staff_ids", [job.get("staff", "")] if data.version < 3 else [])
		if not crew is Array or crew.is_empty(): return _invalid_save()
		for member in crew:
			if not member is String or Catalog.find(Catalog.STAFF,member).is_empty() or workers.has(member): return _invalid_save()
			workers.append(member)
		if Catalog.find(Catalog.LOCATIONS,str(job.get("location",""))).is_empty(): return _invalid_save()
		for key in ["started_at","ready_at","reward"]:
			if not (job.get(key) is int or job.get(key) is float) or job[key] < 0: return _invalid_save()
		if job.ready_at < job.started_at: return _invalid_save()
		# Preserve old in-flight tasks even if today's location asks for a larger crew.
		job.staff_ids = crew.duplicate()
		job.erase("staff")
		ids.append(job.id)
	_apply(data)
	if int(data.version) < 5: _migrate_commissions()
	load_blocked = false
	error_message = ""
	return true

func _migrate_commissions() -> void:
	# Migration only changes the loaded snapshot. The next atomic save writes v5;
	# a failed write leaves the original file intact and never double-refunds it.
	for id in ["fitness", "dispatch", "gym", "staffing", "supply"]:
		var legacy := Catalog.find(Catalog.UNLOCKS, id)
		for index in level(id): points += int(legacy.costs[index])
		upgrades.erase(id)
	supply_unlocked = false
	for job in dispatches: points += int(job.reward)
	dispatches.clear()
	if campaign.routes_acquired: commission_unlocks.append("departure")

func commission_reason(id: String, staff_id: String) -> String:
	if load_blocked: return "存档无法读取"
	var task := Commissions.find(id)
	if task.is_empty(): return "委托不存在"
	if not task.get("enabled", true): return "委托已停用"
	if not campaign.prologue_done: return "请先完成序章"
	if not pending_dispatch_result.is_empty(): return "请先查看上次成果"
	if commission_unlocks.has(id): return "委托已完成"
	if not task.requires.is_empty() and not commission_unlocks.has(task.requires): return "请先完成出发准备"
	if Catalog.find(Catalog.STAFF, staff_id).is_empty(): return "请选择派遣人员"
	if points < int(task.cost): return "修复资源不足"
	return ""

func execute_commission(id: String, staff_id: String) -> bool:
	error_message = commission_reason(id, staff_id)
	if not error_message.is_empty(): return false
	var before := to_dict()
	var task := Commissions.find(id)
	points -= int(task.cost)
	commission_unlocks.append(id)
	if id == "departure": campaign.routes_acquired = true
	if task.kind == "character" and not campaign.characters.has(task.value):
		campaign.characters.append(task.value)
	pending_dispatch_result = {"id":Crypto.new().generate_random_bytes(16).hex_encode(),
		"commission":id, "location":task.location, "staff_ids":[staff_id]}
	return _commit(before)

func acknowledge_dispatch_result(id: String) -> bool:
	if pending_dispatch_result.get("id", "") != id or id.is_empty(): return false
	var before := to_dict()
	pending_dispatch_result.clear()
	return _commit(before)

func has_dispatch_effect(kind: String, value: String) -> bool:
	for id in commission_unlocks:
		var task := Commissions.find(id)
		if task.get("kind") == kind and task.get("value") == value: return true
	return false

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
	# FileAccess closes the temporary file before the atomic rename. On Web, sync
	# the renamed file as well so an immediate page refresh cannot restore the
	# previous IndexedDB checkpoint.
	if OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()
	error_message = ""
	return true

func _commit(before: Dictionary) -> bool:
	if write_save(): return true
	_apply(before)
	return false

func level(id: String) -> int:
	return int(upgrades.get(id,0))

func complete_prologue() -> bool:
	if campaign.prologue_done: return not load_blocked
	var before = to_dict()
	campaign.prologue_done = true
	return _commit(before)

func complete_tutorial_dispatch() -> bool:
	if not campaign.prologue_done: return false
	if campaign.routes_acquired and commission_unlocks.has("departure"): return not load_blocked
	var before = to_dict()
	campaign.routes_acquired = true
	if not commission_unlocks.has("departure"): commission_unlocks.append("departure")
	return _commit(before)

func record_memory(id: String) -> bool:
	if id.is_empty(): return false
	if campaign.memories.has(id): return not load_blocked
	var before = to_dict()
	campaign.memories.append(id)
	return _commit(before)

func settle_region(run_id: String, region: String, characters: Array, earned: int, lineup: Array = []) -> bool:
	if not campaign.routes_acquired or not Campaign.REGIONS.has(region) or run_id.is_empty(): return false
	if campaign.settled_runs.has(run_id): return not load_blocked
	for id in characters:
		if not id is String or id.is_empty(): return false
	if not lineup.is_empty() and not Campaign.formation_valid(lineup,campaign.characters+characters): return false
	var before = to_dict()
	campaign.settled_runs.append(run_id)
	if not campaign.terminals.has(region): campaign.terminals.append(region)
	for id in characters:
		if not campaign.characters.has(id): campaign.characters.append(id)
	if not lineup.is_empty(): campaign.formation = lineup.duplicate()
	points += maxi(0, earned)
	completions += 1
	return _commit(before)

func complete_finale_stage(stage: int) -> bool:
	if campaign.terminals.size() != 3 or stage < 1 or stage > 3: return false
	if stage <= campaign.finale_stage: return not load_blocked
	if stage != campaign.finale_stage + 1: return false
	var before = to_dict()
	campaign.finale_stage = stage
	campaign.restored = stage == 3
	return _commit(before)

func unlock_reason(id: String) -> String:
	var item = Catalog.find(Catalog.UNLOCKS,id)
	if item.is_empty(): return "没有这个升级"
	if campaign.routes_acquired and id in ["dispatch","gym"]: return "战役中由记忆终端开放"
	if level(id) >= item.costs.size(): return "已满级"
	if not item.requires.is_empty() and level(item.requires) == 0:
		if not (campaign.routes_acquired and item.requires == "dispatch" and dispatch_unlocked("library")): return "需要先解锁派遣事务所"
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

func save_campaign_checkpoint(snapshot: Dictionary, lineup: Array, story_flags: Variant = null) -> bool:
	if story_flags != null and not preload("res://game/run/hotspot_event.gd").valid_flags(story_flags): return false
	var before = to_dict()
	if story_flags != null: campaign.story_flags = story_flags.duplicate(true)
	if Campaign.formation_valid(lineup,campaign.characters): campaign.formation = lineup.duplicate()
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
		if job.get("staff_ids", [job.get("staff", "")]).has(staff_id): return true
	return false

func staff_reason(staff_id: String) -> String:
	if Catalog.find(available_staff(),staff_id).is_empty(): return "尚未加入"
	if busy(staff_id): return "执行任务中"
	return ""

func dispatch_reason(staff_ids: Variant, location_id: String) -> String:
	var location = Catalog.find(Catalog.LOCATIONS,location_id)
	if location.is_empty(): return "地点不存在"
	if load_blocked: return "存档无法读取，暂不可派遣"
	if not dispatch_unlocked(location_id): return "地点尚未解锁"
	var crew: Array = [staff_ids] if staff_ids is String else (staff_ids if staff_ids is Array else [])
	var required: int = location.get("crew_size", 1)
	if crew.size() != required: return "请选择 %d 名同学（已选 %d 人）" % [required, crew.size()]
	var seen: Array = []
	var tags: Array = []
	for member in crew:
		if not member is String or seen.has(member): return "派遣成员不能重复或无效"
		var reason := staff_reason(member)
		if not reason.is_empty(): return reason
		seen.append(member)
		tags.append_array(Catalog.find(Catalog.STAFF, member).get("tags", []))
	for tag in location.get("required_tags", []):
		if not tags.has(tag): return "队伍需要技能：" + Catalog.DISPATCH_TAGS.get(tag, {}).get("name", tag)
	if dispatches.size() >= (2 if level("staffing") > 0 else 1): return "派遣队伍已满"
	if points < location.cost: return "修复资源不足"
	return ""

func dispatch_unlocked(location_id: String) -> bool:
	var location = Catalog.find(Catalog.LOCATIONS,location_id)
	if location.is_empty(): return false
	if campaign.routes_acquired:
		return campaign.terminals.size() >= (1 if location_id == "library" else 2)
	return level(location.requires) > 0

func start_dispatch(staff_ids: Variant, location_id: String, now: int = -1) -> bool:
	var reason = dispatch_reason(staff_ids,location_id)
	if not reason.is_empty():
		error_message = reason
		return false
	if now < 0: now = int(Time.get_unix_time_from_system())
	var before = to_dict()
	var location = Catalog.find(Catalog.LOCATIONS,location_id)
	points -= int(location.cost)
	var crew: Array = [staff_ids] if staff_ids is String else staff_ids.duplicate()
	dispatches.append({"id":Crypto.new().generate_random_bytes(16).hex_encode(), "staff_ids":crew,
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
