extends RefCounted
const Run = preload("res://game/run/short_run.gd")

static func decode(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("schema",0) != 1 or not snapshot.get("run",null) is Dictionary: return {}
	for key in ["elapsed","seconds","selected","speed"]:
		var value = snapshot.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)): return {}
	if not snapshot.get("won",false) is bool: return {}
	var model = Run.new()
	if not model.restore(snapshot.run): return {}
	var screen = str(snapshot.get("screen",""))
	if not screen in ["map","battle","event","reward","report","summary"]: return {}
	if screen == "summary":
		if model.stage != 5 or not model.settled: return {}
	elif model.stage >= 5 or model.settled: return {}
	if screen == "map" and not model.node.is_empty(): return {}
	if screen in ["battle","event","reward","report"] and model.node.is_empty(): return {}
	if screen == "event" and (model.node.kind != "event" or model.event_done): return {}
	if screen in ["battle","report"] and model.node.kind == "event": return {}
	if screen == "reward" and model.reward_taken: return {}
	var report: Array[Dictionary] = []
	if not snapshot.get("report",[]) is Array: return {}
	for row in snapshot.get("report",[]):
		if not row is Dictionary or not row.get("name",null) is String: return {}
		for key in ["damage","healing"]:
			if not (row.get(key) is int or row.get(key) is float): return {}
		report.append({"name":row.name, "damage":maxi(0,int(row.damage)), "healing":maxi(0,int(row.healing))})
	if screen == "report" and report.size() != 4: return {}
	return {"run":model, "screen":screen, "report":report, "won":bool(snapshot.get("won",false)),
		"elapsed":maxf(0,float(snapshot.get("elapsed",0))), "seconds":maxf(0,float(snapshot.get("seconds",0))),
		"selected":Run.Content.role_index(snapshot.selected_id) if snapshot.get("selected_id") is String else int(snapshot.get("selected",0)), "speed":2 if snapshot.get("speed",1) == 2 else 1}
