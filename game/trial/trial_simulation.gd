extends "res://game/combat/battle_simulation.gd"
## Opt-in extension: original campaigns keep using the unchanged base simulator.
const Catalog = preload("res://game/trial/trial_catalog.gd")
var tags: Array[String] = []
var upgrades: Array = []
var progress := 0
var awaiting_choice := false
var hack_choice := ""
var pulse_interval := 9.0
var pulse_amount := 22.0
var next_pulse := 9.0
var marks := {}
var contributions := {}
var notes: Array[String] = []
var broadcast_used := false
var first_hits := {}
var half_used := {}
var backup_used := {}
var skill_seen := {}

func start(formation: Array, battle: int, rewards: Array, gear: Dictionary, trainee: int) -> void:
	tags = Catalog.active_tags(formation)
	upgrades = rewards.duplicate()
	progress = 0
	awaiting_choice = false
	hack_choice = ""
	marks.clear()
	contributions.clear()
	notes.clear()
	first_hits.clear()
	half_used.clear()
	backup_used.clear()
	skill_seen.clear()
	broadcast_used = false
	pulse_interval = Catalog.BATTLES[battle].pulse
	pulse_amount = Catalog.BATTLES[battle].shield
	next_pulse = pulse_interval
	reset(Catalog.roster(formation, battle, rewards, gear, trainee))
	for u in units:
		u.system_shield = 0.0
		u.sport_shield = 0.0
		u.base_interval = u.interval
		u.boost_until = 0.0
		if _member(u, "运动社"):
			u.sport_shield = 40.0
			u.shield += 40.0

func _member(u: Dictionary, tag: String) -> bool:
	return u.side == 0 and u.role >= 0 and tags.has(tag) and Catalog.TAGS[u.role].has(tag)

func _add_progress(u: Dictionary, amount: int, reason: String) -> void:
	if not hack_choice.is_empty() or progress >= 100: return
	var actual = mini(amount, 100 - progress)
	progress += actual
	contributions[u.name] = contributions.get(u.name, 0) + actual
	_note("%s · %s +%d" % [u.name, reason, actual])

func _note(message: String) -> void:
	notes.append("%.1fs  %s" % [elapsed, message])
	if notes.size() > 100: notes.pop_front()

func _shield(u: Dictionary, amount: float) -> void:
	u.shield += minf(amount, maxf(0, 144.0 - u.shield))

func _lowest(allies: Array[Dictionary]) -> Dictionary:
	return _target({}, allies, "low")

func advance(delta: float) -> Array[Dictionary]:
	if awaiting_choice or finished: return []
	for id in marks.keys():
		if marks[id].until < elapsed: marks.erase(id)
	for u in units:
		if elapsed >= 6 and u.sport_shield > 0:
			u.shield = maxf(0, u.shield - u.sport_shield)
			u.sport_shield = 0.0
		if u.boost_until > 0 and elapsed >= u.boost_until:
			u.interval = u.base_interval
			u.boost_until = 0.0
	if not closing and elapsed >= next_pulse:
		next_pulse += pulse_interval
		if hack_choice == "":
			for u in _living(1):
				var gain = minf(pulse_amount, maxf(0, 144 - u.shield))
				u.system_shield += gain
				u.shield += gain
			_note("维护脉冲 · 敌方补盾")
		elif hack_choice == "takeover" and not _living(0).is_empty():
			_shield(_lowest(_living(0)), pulse_amount)
			_note("维护脉冲 · 保护我方")
	var output = super.advance(delta)
	if not finished and not closing and progress >= 100 and hack_choice.is_empty():
		awaiting_choice = true
	return output

func choose_hack(choice: String) -> bool:
	if not awaiting_choice or not choice in ["disconnect", "takeover"]: return false
	hack_choice = choice
	awaiting_choice = false
	if choice == "disconnect":
		for u in units:
			u.shield = maxf(0, u.shield - u.system_shield)
			u.system_shield = 0.0
	for u in _living(0):
		if _member(u, "创客社"):
			u.interval = u.base_interval * 0.75
			u.boost_until = elapsed + 8
	_note("破解完成 · " + ("断开维护" if choice == "disconnect" else "接管维护"))
	return true

func _skill_events(actor: Dictionary, target: Dictionary, due: Array[Dictionary]) -> void:
	var begin = due.size()
	super._skill_events(actor, target, due)
	if actor.side != 0: return
	# Attach contribution to actual effects: cancelled/expired projectiles earn nothing.
	for i in range(begin, due.size()): due[i].trial_skill = true
	if actor.role == 1 and upgrades.has("pierce"):
		for i in range(begin, due.size()):
			var e = due[i]
			if e.kind != "damage": continue
			var direction: Vector2 = actor.position.direction_to(e.target.position)
			var candidates = _living(1).filter(func(foe):
				var offset: Vector2 = foe.position - actor.position
				return foe.id != e.target.id and offset.dot(direction) > actor.position.distance_to(e.target.position) and absf(offset.cross(direction)) <= 0.65 and AutoBattle.in_range(actor, foe))
			if not candidates.is_empty(): _event(due, actor, _target(actor, candidates), "damage", e.value * 0.6, true)
			break

func _resolve(due: Array[Dictionary]) -> void:
	# Tag the first damage skill once, not every projectile or area target.
	for e in due:
		if e.kind == "damage" and e.special and _member(e.actor, "突击") and not first_hits.has(e.actor.id):
			e.value += 25
			first_hits[e.actor.id] = true
	super._resolve(due)
	for e in due:
		var u: Dictionary = e.actor
		var target: Dictionary = e.target
		if e.kind == "damage":
			var remaining: float = e.get("blocked", 0)
			var consumed = minf(target.system_shield, remaining)
			target.system_shield -= consumed
			remaining -= consumed
			target.sport_shield = maxf(0, target.sport_shield - remaining)
			if u.side == 0 and not e.special: _verify(u, target)
		if e.get("trial_skill", false) and not skill_seen.has("action_%d" % e.action_id):
			skill_seen["action_%d" % e.action_id] = true
			_add_progress(u, 8 if u.role == 4 else 4, "技能")
			if _member(u, "解析") and not skill_seen.has(u.id): _add_progress(u, 12, "解析")
			skill_seen[u.id] = true
			if hack_choice.is_empty() and (u.role == 3 or (u.get("gear", "") == "lens" and not u.get("lens_used", false))):
				var mark_target = target if target.side != u.side and target.hp > 0 else _target(u, _living(1).filter(func(foe): return AutoBattle.in_range(u, foe)))
				if not mark_target.is_empty():
					marks[mark_target.id] = {"owner": u.id, "until": elapsed + 4, "users": [], "limit": 2 if u.role == 3 and upgrades.has("verify") else 1}
					u.lens_used = true
					_note(u.name + " · 暴露漏洞")
	for u in _living(0):
		if u.hp > u.max_hp * 0.5: continue
		if _member(u, "守护") and not half_used.has(u.id):
			half_used[u.id] = true
			_shield(u, 45)
			_note(u.name + " · 守护触发")
			if upgrades.has("cover"):
				var nearby = _living(0).filter(func(a): return a.id != u.id and AutoBattle.distance(a, u) <= 2.05)
				if not nearby.is_empty(): _shield(_lowest(nearby), 45)
		if u.get("gear", "") == "backup" and not backup_used.has(u.id):
			backup_used[u.id] = true
			_shield(u, u.max_hp * 0.25)
			_note(u.name + " · 应急备份")

func _verify(actor: Dictionary, target: Dictionary) -> void:
	if not marks.has(target.id) or not hack_choice.is_empty(): return
	var mark: Dictionary = marks[target.id]
	if mark.until < elapsed or mark.owner == actor.id or mark.users.has(actor.id): return
	mark.users.append(actor.id)
	_add_progress(actor, 16, "验证漏洞")
	if tags.has("广播站") and not broadcast_used and not _living(0).is_empty():
		broadcast_used = true
		var ally = _lowest(_living(0))
		ally.hp = minf(ally.max_hp, ally.hp + 45)
		_note("广播站 · 协作治疗")
	if mark.users.size() >= mark.limit: marks.erase(target.id)
