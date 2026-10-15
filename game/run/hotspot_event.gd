extends RefCounted
## Data graph over the existing hotspots; effects happen only on a confirmed transition.
static var definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/content/events/hotspot_dialogues.json"))
static var GRAPHS: Dictionary = definitions.graphs

static func valid_flags(value: Variant) -> bool:
	if not value is Dictionary or value.size() > 128: return false
	for key in value:
		if not key is String or key.is_empty() or key.length() > 64: return false
		var v: Variant = value[key]
		if v is bool: continue
		if v is String and v.length() <= 128: continue
		if (v is int or v is float) and is_finite(float(v)) and int(v) == v and absf(float(v)) <= 1000000: continue
		return false
	return true

static func begin(kind: String, spot_id: String, flags: Dictionary, place: String) -> Dictionary:
	var node := "intro"
	if kind == "system" and flags.get("rollback_trace",false):
		node = "known" if flags.get("rollback_origin","") == place else "linked"
	return {"kind":kind,"spot_id":spot_id,"node":node,"history":[],"closed":false}

static func valid_state(value: Variant, spot: Dictionary) -> bool:
	if not value is Dictionary or value.get("kind") != spot.get("kind") or value.get("spot_id") != spot.get("id"): return false
	if not GRAPHS.has(value.kind) or not GRAPHS[value.kind].has(value.get("node")): return false
	if not value.get("closed") is bool or not value.get("history") is Array or value.history.size() > 32: return false
	for node in value.history:
		if not node is String or not GRAPHS[value.kind].has(node): return false
	return true

static func can_return(state: Dictionary) -> bool:
	var kind: String = state.get("kind","")
	var node_id: String = state.get("node","")
	if not GRAPHS.has(kind) or not GRAPHS[kind].has(node_id): return false
	var settings: Variant = definitions.get("event_settings",{})
	if not settings is Dictionary: return false
	var config: Variant = settings.get(kind,{})
	if not config is Dictionary: return false
	var allowed: Variant = GRAPHS[kind][node_id].get("allow_return",config.get("allow_return",true))
	return allowed is bool and allowed

static func return_to_location(state: Dictionary) -> Dictionary:
	if not can_return(state): return {}
	var returned: Dictionary = state.duplicate(true)
	# Returning midway keeps the node; a read-only final page completes the event.
	if GRAPHS[state.kind][state.node].choices.is_empty(): returned.closed = true
	return returned

static func return_configuration_errors() -> Array[String]:
	var errors: Array[String] = []
	var settings: Variant = definitions.get("event_settings",{})
	if not settings is Dictionary:
		errors.append("event_settings必须为对象")
		return errors
	for kind in settings:
		var config: Variant = settings[kind]
		if not GRAPHS.has(kind) or not config is Dictionary or not config.get("allow_return",true) is bool:
			errors.append("无效事件返回配置："+str(kind))
	for kind in GRAPHS:
		for id in GRAPHS[kind]:
			var node: Dictionary = GRAPHS[kind][id]
			if not node.get("allow_return",true) is bool: errors.append("返回开关必须为布尔值："+kind+"/"+id)
			if node.choices.is_empty() and not can_return({"kind":kind,"node":id}):
				errors.append("无选项的结束页必须允许返回："+kind+"/"+id)
	return errors

static func reason(choice: Dictionary, flags: Dictionary, programs: Array) -> String:
	var requirement: Dictionary = choice.get("requires",{})
	if requirement.has("flag") and not flags.get(requirement.flag,false): return choice.get("blocked","尚未满足条件。")
	if requirement.has("program") and not programs.has(requirement.program): return choice.get("blocked","当前程序不满足条件。")
	if choice.has("once") and flags.get(choice.once,false): return "已经记录，不会重复取得。"
	return ""

static func page(state: Dictionary, flags: Dictionary, context: Dictionary) -> Dictionary:
	var node: Dictionary = GRAPHS[state.kind][state.node]
	var line_id: String = node.line
	var detail: String = context.get("memory","") if line_id == "$memory" else definitions.lines[line_id]
	var translated := String(TranslationServer.translate(line_id))
	if translated != line_id: detail = translated
	if line_id == "person.intro" and context.get("expedition_party",false):
		detail = "发明家：我正在帮忙整理校园里的线索。\n\n在基地完成联络派遣后，我会加入出发与途中会合的候选名单。这次交谈只交流线索，不会改变队伍。"
	detail = detail.replace("{origin}",context.get("origin","之前的地点"))
	var options: Array = []
	for source in node.choices:
		var choice: Dictionary = source.duplicate(true)
		var blocked := reason(choice,flags,context.get("programs",[]))
		if choice.get("command") == "formation:protect" and not context.get("can_form_protect",true): blocked = "当前队员尚不齐备；可在整备中自行调整站位。"
		choice.enabled = blocked.is_empty()
		choice.hint = blocked
		options.append(choice)
	return {"title":node.title,"description":detail,"line_id":line_id,"options":options,"round":state.history.size()+1,"allow_return":can_return(state)}

static func choose(state: Dictionary, id: String, flags: Dictionary, context: Dictionary) -> Dictionary:
	if state.closed: return {}
	var node: Dictionary = GRAPHS[state.kind][state.node]
	for choice in node.choices:
		if choice.id != id: continue
		if not reason(choice,flags,context.get("programs",[])).is_empty(): return {}
		if choice.get("command") == "formation:protect" and not context.get("can_form_protect",true): return {}
		var next_state: Dictionary = state.duplicate(true)
		var next_flags: Dictionary = flags.duplicate(true)
		next_state.history.append(state.node)
		if next_state.history.size() > 32: next_state.history.pop_front()
		for key in choice.get("set",{}):
			var value: Variant = choice.set[key]
			next_flags[key] = context.get("place","") if value is String and value == "$place" else value
		next_state.closed = choice.to == "END"
		if not next_state.closed: next_state.node = choice.to
		return {"state":next_state,"flags":next_flags,"command":choice.get("command","")}
	return {}
