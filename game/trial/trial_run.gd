extends RefCounted
## Checkpoint state only: interrupted battles restart with this preparation state.
## Role indices are append-only catalog identities; six slots are board geometry.
const Catalog = preload("res://game/trial/trial_catalog.gd")
const Codes = preload("res://game/trial/code_catalog.gd")
const SAVE_VERSION := 3
const DEFAULT_PATH := "user://synergy_trial_v3.json"
const PREVIOUS_PATH := "user://synergy_trial_v2.json"
const LEGACY_PATH := "user://synergy_trial_v1.json"
const SLOT_COUNT := 6
const PARTY_SIZE := 4
const DEFAULT_FORMATION := [0, -1, -1, 2, 1, 3]

var formation: Array = DEFAULT_FORMATION.duplicate()
var battle := 0
var phase := "prepare"
var rewards: Array = []
var gear: Dictionary = {}
var trainee := -1
var unlocked := false
var report := ""
var starting_supply := ""
var claimed_rewards: Array = []
var path := DEFAULT_PATH
var last_error := ""
var load_blocked := false
var recovered_backup := false
var programs: Array = Array(Codes.RULES.default_loadout).duplicate()
var supplies: Dictionary = Codes.stock()

func snapshot() -> Dictionary:
	return {"version": SAVE_VERSION, "formation": formation.duplicate(), "battle": battle, "phase": phase,
		"rewards": rewards.duplicate(), "gear": gear.duplicate(), "trainee": trainee, "unlocked": unlocked,
		"report": report, "starting_supply": starting_supply, "claimed_rewards": claimed_rewards.duplicate(),
		"programs":programs.duplicate(), "supplies":supplies.duplicate()}

func restore(data) -> bool:
	var normalized := _normalize(data)
	if normalized.is_empty(): return false
	_apply(normalized)
	return true

func _apply(data: Dictionary) -> void:
	formation = data.formation.map(func(value): return int(value))
	battle = int(data.battle)
	phase = data.phase
	rewards = data.rewards.duplicate()
	gear.clear()
	for item in data.gear: gear[item] = int(data.gear[item])
	trainee = int(data.trainee)
	unlocked = data.unlocked
	report = data.report
	starting_supply = data.starting_supply
	claimed_rewards = data.claimed_rewards.duplicate()
	programs = data.programs.duplicate()
	supplies = data.supplies.duplicate()
	for id in supplies: supplies[id] = int(supplies[id])

func _normalize(data) -> Dictionary:
	if not data is Dictionary or not _integer(data.get("version"), 1, SAVE_VERSION): return {}
	var result: Dictionary = data.duplicate(true)
	if int(data.version) < 3:
		result.programs = Array(Codes.RULES.default_loadout).duplicate()
		result.supplies = Codes.stock()
	if not Codes.valid_loadout(result.get("programs")) or not Codes.valid_stock(result.get("supplies")): return {}
	var f = result.get("formation")
	if not f is Array or f.size() != SLOT_COUNT: return {}
	var used: Array = []
	for id in f:
		if not _integer(id, -1, Catalog.ROLES.size() - 1): return {}
		if id >= 0:
			if used.has(id): return {}
			used.append(id)
	if used.size() != PARTY_SIZE: return {}
	if not _integer(result.get("battle"), 0, Catalog.BATTLES.size() - 1): return {}
	if not result.get("phase") in ["prepare", "reward", "complete"]: return {}
	if not result.get("rewards") is Array or not result.get("gear") is Dictionary: return {}
	if not result.get("unlocked") is bool or not result.get("report") is String: return {}
	if not _integer(result.get("trainee"), -1, Catalog.ROLES.size() - 1): return {}
	var seen: Array = []
	for reward in result.rewards:
		if not reward is String or not Catalog.REWARDS.has(reward) or seen.has(reward): return {}
		seen.append(reward)
	var equipped: Array = []
	for item in result.gear:
		if not item is String or not _is_equipment(item) or not result.rewards.has(item): return {}
		var owner = result.gear[item]
		if not _integer(owner, -1, Catalog.ROLES.size() - 1): return {}
		if owner >= 0 and equipped.has(owner): return {}
		if owner >= 0: equipped.append(owner)
	for item in result.rewards:
		if _is_equipment(item) and not result.gear.has(item): return {}
	if result.rewards.has("training") != (result.trainee >= 0): return {}
	if result.phase == "reward" and int(result.battle) == Catalog.BATTLES.size() - 1: return {}
	if result.phase == "complete" and (int(result.battle) != Catalog.BATTLES.size() - 1 or not result.unlocked): return {}
	if int(result.version) == 1:
		# v1 appended supply first, then one reward per completed non-final battle.
		var expected_claims: int = int(result.battle)
		var old_rewards: Array = result.rewards.duplicate()
		result.starting_supply = ""
		if old_rewards.size() == expected_claims + 1 and result.unlocked and old_rewards[0] == "lens":
			result.starting_supply = old_rewards.pop_front()
		result.claimed_rewards = old_rewards
		result.version = SAVE_VERSION
	if not result.get("starting_supply") is String or not result.get("claimed_rewards") is Array: return {}
	if not result.starting_supply.is_empty():
		if not result.unlocked or result.starting_supply != "lens" or not _is_equipment(result.starting_supply): return {}
	if result.claimed_rewards.size() != int(result.battle): return {}
	var expected_rewards: Array = [] if result.starting_supply.is_empty() else [result.starting_supply]
	for index in range(result.claimed_rewards.size()):
		var id = result.claimed_rewards[index]
		if not id is String or not _reward_pool(index).has(id) or expected_rewards.has(id): return {}
		expected_rewards.append(id)
	if expected_rewards != result.rewards: return {}
	result.version = SAVE_VERSION
	return result

func _integer(value, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= low and value <= high and value == int(value)

func _is_equipment(id: String) -> bool:
	var definition: Dictionary = Catalog.REWARDS.get(id, {})
	return definition.get("reward_type", definition.get("kind", "")) in ["equipment", "装备"]

func _reward_pool(index: int) -> Array:
	if index < 0 or index >= Catalog.BATTLES.size() - 1: return []
	return Catalog.BATTLES[index].get("rewards", ["cover", "lens", "training"] if index == 0 else ["verify", "pierce", "backup"]).duplicate()

func _read_payload(source: String):
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null: return null
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

func _newer_version(data) -> bool:
	return data is Dictionary and (data.get("version") is int or data.get("version") is float) and data.version > SAVE_VERSION

func read_save() -> bool:
	last_error = ""
	recovered_backup = false
	var source := path
	if not FileAccess.file_exists(source) and not FileAccess.file_exists(source + ".bak"):
		if path == DEFAULT_PATH and (FileAccess.file_exists(PREVIOUS_PATH) or FileAccess.file_exists(PREVIOUS_PATH + ".bak")): source = PREVIOUS_PATH
		elif path == DEFAULT_PATH and (FileAccess.file_exists(LEGACY_PATH) or FileAccess.file_exists(LEGACY_PATH + ".bak")): source = LEGACY_PATH
		else:
			load_blocked = false
			return true
	var raw = _read_payload(source)
	if _newer_version(raw):
		load_blocked = true
		last_error = "试炼存档来自更新版本，已保留原文件并停止写入。"
		return false
	if restore(raw):
		load_blocked = false
		return true
	if restore(_read_payload(source + ".bak")):
		load_blocked = false
		recovered_backup = source == path
		last_error = "已从上次有效备份恢复；本次进度可能回退一个操作。"
		return true
	load_blocked = true
	last_error = "试炼存档和备份无法读取，已保留原文件并停止写入。"
	return false

func _error(message: String) -> bool:
	last_error = message
	return false

func save() -> bool:
	if load_blocked: return _error("试炼存档不可读取，禁止覆盖。")
	if _normalize(snapshot()).is_empty(): return _error("试炼状态不完整，未写入存档。")
	var had_primary := FileAccess.file_exists(path)
	var existing_valid := false
	if had_primary:
		var existing = _read_payload(path)
		if _newer_version(existing):
			load_blocked = true
			return _error("试炼存档来自更新版本，禁止覆盖。")
		existing_valid = not _normalize(existing).is_empty()
		if not existing_valid and not recovered_backup:
			load_blocked = true
			return _error("磁盘上的试炼存档无法读取，禁止覆盖。")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return _error("无法创建试炼临时存档，请检查保存位置后重试。")
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return _error("试炼存档写入失败，原有进度已保留。")
	# Read back the flushed temporary payload before touching any previous checkpoint.
	if _normalize(_read_payload(path + ".tmp")).is_empty(): return _error("试炼临时存档校验失败，原有进度已保留。")
	if had_primary:
		if existing_valid:
			if DirAccess.copy_absolute(path, path + ".bak.tmp") != OK: return _error("试炼备份失败，原有进度已保留。")
			if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK: return _error("试炼备份替换失败，原有进度已保留。")
		else:
			# Keep the damaged bytes for recovery instead of replacing the good backup.
			var damaged_path := path + ".corrupt-" + str(Time.get_ticks_usec())
			if DirAccess.copy_absolute(path, damaged_path) != OK: return _error("无法保留损坏存档，本次保存已取消。")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return _error("试炼存档替换失败，请重试；上次进度仍可恢复。")
	recovered_backup = false
	last_error = ""
	return true

## Commit one legal command and its durable checkpoint together. No player save is
## touched by the command methods themselves, so isolated simulations can use them.
func transact(action: Callable) -> bool:
	if load_blocked: return _error("试炼存档不可读取，禁止操作。")
	var before := snapshot()
	var result = action.call()
	if result is bool and not result:
		_apply(before)
		return _error("当前阶段无法执行这个操作。")
	if save(): return true
	_apply(before)
	return false

func can_start() -> bool:
	return phase == "prepare" and not _normalize(snapshot()).is_empty()

func assign(role: int, slot: int) -> bool:
	if phase != "prepare" or role < 0 or role >= Catalog.ROLES.size() or slot < 0 or slot >= SLOT_COUNT: return false
	var previous := formation.find(role)
	if previous < 0 and formation[slot] < 0 and formation.count(-1) <= SLOT_COUNT - PARTY_SIZE: return false
	if previous >= 0: formation[previous] = formation[slot]
	formation[slot] = role
	return true

func equip(item: String, owner: int) -> bool:
	if phase != "prepare" or not _is_equipment(item) or not rewards.has(item) or owner < -1 or owner >= Catalog.ROLES.size(): return false
	for other in gear:
		if owner >= 0 and gear[other] == owner: gear[other] = -1
	gear[item] = owner
	return true

func options() -> Array:
	return _reward_pool(battle) if phase == "reward" else []

func select_reward(id: String, owner: int = -1) -> bool:
	if phase != "reward" or not options().has(id) or rewards.has(id): return false
	if id == "training" and (owner < 0 or owner >= Catalog.ROLES.size()): return false
	rewards.append(id)
	claimed_rewards.append(id)
	if _is_equipment(id): gear[id] = -1
	if id == "training": trainee = owner
	battle += 1
	phase = "prepare"
	return true

func finish(won: bool, summary: String, remaining_items: Dictionary = {}) -> bool:
	if phase != "prepare": return false
	if won and not remaining_items.is_empty():
		if not Codes.valid_stock(remaining_items): return false
		for id in supplies:
			if remaining_items[id] > supplies[id]: return false
		supplies = remaining_items.duplicate()
	report = summary
	phase = "prepare" if not won else ("reward" if battle < Catalog.BATTLES.size() - 1 else "complete")
	if phase == "complete": unlocked = true
	return true

func restart(supply: String = "") -> bool:
	if not supply.is_empty() and (not unlocked or supply != "lens"): return false
	battle = 0
	phase = "prepare"
	formation = DEFAULT_FORMATION.duplicate()
	starting_supply = supply
	claimed_rewards.clear()
	rewards = [] if supply.is_empty() else [supply]
	gear = {} if supply.is_empty() else {supply: 1}
	trainee = -1
	report = ""
	programs = Array(Codes.RULES.default_loadout).duplicate()
	supplies = Codes.stock()
	return true

func set_program(slot: int, id: String) -> bool:
	if phase != "prepare" or slot < 0 or slot >= 2 or Codes.program(id) == null: return false
	var other := programs.find(id)
	if other >= 0: programs[other] = programs[slot]
	programs[slot] = id
	return true
