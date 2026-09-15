extends RefCounted
## Permanent campaign facts. Mutations are committed by CampusProgress.
const REGIONS = ["library", "region_b", "region_c"]

static func fresh() -> Dictionary:
	return {"schema": 1, "prologue_done": false, "routes_acquired": false,
		"terminals": [], "memories": [], "characters": [], "settled_runs": [],
		"finale_stage": 0, "restored": false, "formation":["guard","","striker","healer","archer",""]}

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != 1: return false
	for key in ["prologue_done", "routes_acquired", "restored"]:
		if not data.get(key) is bool: return false
	for key in ["terminals", "memories", "characters", "settled_runs"]:
		if not data.get(key) is Array: return false
		var seen = []
		for id in data[key]:
			if not id is String or id.is_empty() or seen.has(id): return false
			if key == "terminals" and not REGIONS.has(id): return false
			seen.append(id)
	var stage = data.get("finale_stage")
	if not (stage is int or stage is float): return false
	if stage != int(stage) or stage < 0 or stage > 3: return false
	if data.routes_acquired and not data.prologue_done: return false
	if not data.terminals.is_empty() and not data.routes_acquired: return false
	if stage > 0 and data.terminals.size() != 3: return false
	var formation = data.get("formation",fresh().formation)
	if not formation is Array or formation.size() != 6: return false
	var active = []
	for id in formation:
		if not id is String: return false
		if id.is_empty(): continue
		if not id in ["guard","archer","healer","striker"] and not data.characters.has(id): return false
		if active.has(id): return false
		active.append(id)
	if active.size() != 4: return false
	return data.restored == (stage == 3)

static func objective(data: Dictionary) -> String:
	if data.restored: return "校园已恢复 · 记录者只读运行"
	if data.terminals.size() == 3: return "接入三台记忆终端 · 修正前代指令"
	if data.routes_acquired: return "选择区域 · 记忆终端 %d / 3" % data.terminals.size()
	if data.prologue_done: return "教学派遣 · 取回校园路线资料"
	return "序章 · 认识虚拟校园与当前 AI"
