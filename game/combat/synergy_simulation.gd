extends "res://game/combat/battle_simulation.gd"
## Trial rules subscribe to shared combat results. Resources never store run state.
const Catalog = preload("res://game/trial/trial_catalog.gd")
var tags: Array[String] = []
var tag_ids: Array[String] = []
var upgrades: Array = []
var progress := 0
var awaiting_choice := false
var hack_choice := ""
var pulse_interval := 6.0
var pulse_amount := 70.0
var next_pulse := 6.0
var marks := {}
var contributions := {}
var notes: Array[String] = []
var bindings: Array[Dictionary] = []
var proc_uses := {}
var skill_seen := {}
var half_seen := {}
var speed_modifiers := {}

func start(formation: Array, battle: int, rewards: Array, gear: Dictionary, trainee: int) -> void:
	tags = Catalog.active_tags(formation)
	tag_ids = Catalog.active_tag_ids(formation)
	upgrades = rewards.duplicate()
	progress = 0
	awaiting_choice = false
	hack_choice = ""
	marks.clear()
	contributions.clear()
	notes.clear()
	bindings.clear()
	proc_uses.clear()
	skill_seen.clear()
	half_seen.clear()
	speed_modifiers.clear()
	pulse_interval = Catalog.BATTLES[battle].pulse
	pulse_amount = Catalog.BATTLES[battle].shield
	next_pulse = pulse_interval
	reset(Catalog.roster(formation, battle, rewards, gear, trainee))
	for u in units: u.base_interval = u.interval
	for u in _living(0):
		var character = Catalog.MANIFEST.characters[u.role]
		install_effects(u, character.effects, "character/" + character.id, character.display_name)
		for id in tag_ids:
			if not u.tags.has(id): continue
			var synergy = Catalog.synergy(id)
			install_effects(u, synergy.effects, "synergy/" + id, synergy.display_name)
		for id in upgrades:
			var reward = Catalog.reward(id)
			if reward == null: continue
			if reward.category == "装备" and u.gear != id: continue
			if reward.category == "专属" and reward.character_id != u.content_id: continue
			if reward.category == "训练" and u.role != trainee: continue
			install_effects(u, reward.effects, "reward/" + id, reward.display_name)
	_dispatch("battle_start")

## A stable source ID namespaces one-shot counters across characters and traits.
## Additional content only needs resources using supported trigger/effect pairs.
func install_effects(owner: Dictionary, effects: Array, source: String, label: String) -> void:
	for proc in effects:
		if not proc.required_tag.is_empty() and (not tag_ids.has(proc.required_tag) or not owner.tags.has(proc.required_tag)): continue
		bindings.append({"owner":owner.id, "proc":proc, "source":source, "label":label})

func drain_events() -> Array[Dictionary]:
	var output: Array[Dictionary] = events.duplicate(true)
	events.clear()
	return output

func _add_progress(actor: Dictionary, amount: int, reason: String) -> void:
	var goal: int = Catalog.MANIFEST.hack_goal
	if not hack_choice.is_empty() or progress >= goal or amount <= 0: return
	var actual := mini(amount, goal - progress)
	progress += actual
	contributions[actor.name] = contributions.get(actor.name, 0) + actual
	_note("%s · %s +%d" % [actor.name, reason, actual])
	_emit("hack_progress", actor, actor, -1, {"actual":actual, "progress":progress, "reason":reason})

func _note(message: String) -> void:
	notes.append("%.1fs  %s" % [elapsed, message])
	if notes.size() > 100: notes.pop_front()

func advance(delta: float) -> Array[Dictionary]:
	if awaiting_choice or finished: return []
	if not is_finite(delta) or delta <= 0: return []
	for id in marks.keys():
		if marks[id].until <= elapsed + delta + EPSILON: marks.erase(id)
	var output = super.advance(delta)
	if not finished and not closing and progress >= Catalog.MANIFEST.hack_goal and hack_choice.is_empty():
		awaiting_choice = true
	return output

func choose_hack(choice: String) -> bool:
	if not awaiting_choice or not choice in ["disconnect", "takeover"]: return false
	hack_choice = choice
	awaiting_choice = false
	if choice == "disconnect":
		for u in units:
			var removed := remove_shields(u, "maintenance")
			if removed > 0: _emit("shield_removed", u, u, -1, {"actual":removed, "shield":u.shield})
	_dispatch("hack_complete")
	var allies := _living(0)
	if not allies.is_empty(): _emit("hack_completed", allies[0], allies[0], -1, {"choice":choice})
	_note("破解完成 · " + ("断开维护" if choice == "disconnect" else "接管维护"))
	return true

func _skill_events(actor: Dictionary, target: Dictionary, due: Array[Dictionary]) -> void:
	var begin := due.size()
	super._skill_events(actor, target, due)
	if actor.side != 0: return
	for i in range(begin, due.size()): due[i].trial_skill = true
	_dispatch("skill_emit", actor, {"target":target, "action_id":active_action_id, "effects":due, "begin":begin})

func _resolve(due: Array[Dictionary]) -> void:
	# Decide which hit consumes a once-only damage bonus before the base batch.
	due.sort_custom(func(a, b):
		if a.action_id != b.action_id: return a.action_id < b.action_id
		if a.actor.id != b.actor.id: return a.actor.id < b.actor.id
		return a.target.id < b.target.id)
	for e in due:
		if e.kind == "damage" and e.special and e.actor.side == 0 and e.target.hp > 0:
			_dispatch("before_damage_skill", e.actor, e)
	super._resolve(due)

func _after_impact_batch(due: Array[Dictionary]) -> void:
	_expire_speed_modifiers()
	for e in due:
		if not e.get("valid", false) or e.actor.side != 0: continue
		var actor: Dictionary = e.actor
		if e.kind == "damage" and not e.special and e.actual + e.blocked > 0: _verify(actor, e.target)
		if e.get("trial_skill", false):
			if not skill_seen.has(e.action_id):
				skill_seen[e.action_id] = true
				_add_progress(actor, Catalog.MANIFEST.skill_progress, "技能")
			_dispatch("skill_impact", actor, e)
	for actor in _living(0):
		if actor.hp <= actor.max_hp * 0.5 and not half_seen.has(actor.id):
			half_seen[actor.id] = true
			_dispatch("half_health", actor)
	# Periodic systems resolve after the impact batch, before new action requests.
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90: return
	while elapsed + EPSILON >= next_pulse:
		next_pulse += pulse_interval
		_maintenance_pulse()

func _maintenance_pulse() -> void:
	if hack_choice.is_empty():
		for foe in _living(1): _apply_shield(foe, foe, pulse_amount, "maintenance", 0, "维护脉冲")
		_note("维护脉冲 · 敌方补盾")
	elif hack_choice == "takeover":
		var ally := _target({}, _living(0), "low")
		_apply_shield(ally, ally, pulse_amount, "maintenance", 0, "接管维护")
		_note("维护脉冲 · 保护我方")

func _dispatch(trigger: String, actor: Dictionary = {}, context: Dictionary = {}) -> void:
	for binding in bindings:
		var proc = binding.proc
		if proc.trigger != trigger: continue
		var owner := unit(binding.owner)
		if owner.is_empty(): continue
		# Verification is a team event. A broadcast member can heal after any ally verifies.
		if trigger == "verify" and proc.limit == "team":
			# Activation was locked at preparation; fallen members do not revoke it.
			if not actor.is_empty(): owner = actor
		elif not actor.is_empty() and owner.id != actor.id: continue
		elif actor.is_empty() and owner.hp <= 0: continue
		var key := "%s/%s" % [binding.source, proc.id]
		match proc.limit:
			"owner": key += "/owner/%d" % owner.id
			"action": key += "/action/%d/%d" % [owner.id, context.get("action_id", -1)]
		if proc.limit != "none" and proc_uses.has(key): continue
		if _apply_proc(binding, owner, context):
			if proc.limit != "none": proc_uses[key] = true
			_emit("trait_triggered", owner, owner, context.get("action_id", -1), {"label":binding.label, "effect":proc.effect})

func _proc_target(proc, owner: Dictionary, context: Dictionary) -> Dictionary:
	match proc.target:
		"lowest_ally": return _target({}, _living(owner.side), "low")
		"lowest_other_near":
			var allies: Array[Dictionary] = _living(owner.side).filter(func(u): return u.id != owner.id and AutoBattle.distance(u, owner) <= proc.radius)
			return _target(owner, allies, "low")
		"skill_target": return context.get("target", {})
	return owner

func _apply_proc(binding: Dictionary, owner: Dictionary, context: Dictionary) -> bool:
	var proc = binding.proc
	var target := _proc_target(proc, owner, context)
	var source: String = proc.source if not proc.source.is_empty() else binding.source + "/" + proc.id
	match proc.effect:
		"damage_bonus":
			context.value += proc.value
			return true
		"pierce": return _pierce(owner, context, proc.value)
		"hack":
			if not hack_choice.is_empty(): return false
			_add_progress(owner, int(proc.value), binding.label)
			return true
		"mark":
			if not hack_choice.is_empty(): return false
			# A support skill's lens exposes the nearest enemy within actual range.
			if target.is_empty() or target.side == owner.side:
				target = _target(owner, _living(1 - owner.side).filter(func(u): return AutoBattle.in_range(owner, u)))
			if target.is_empty() or target.hp <= 0: return false
			var uses := 1
			for id in upgrades:
				var reward = Catalog.reward(id)
				if reward != null and reward.character_id == owner.content_id: uses += reward.mark_uses_bonus
			var duration: float = proc.duration if proc.duration > 0 else Catalog.MANIFEST.vulnerability_duration
			marks[target.id] = {"owner":owner.id, "until":elapsed + duration, "users":[], "limit":uses}
			_emit("mark_applied", owner, target, context.get("action_id", -1), {"duration":duration, "uses":uses})
			_note(owner.name + " · 暴露漏洞")
			return true
		"shield":
			if target.is_empty() or target.hp <= 0: return false
			_apply_shield(owner, target, proc.value + target.max_hp * proc.max_health_ratio, source, proc.duration, binding.label)
		"heal":
			if target.is_empty() or target.hp <= 0: return false
			var actual := minf(proc.value + target.max_hp * proc.max_health_ratio, target.max_hp - target.hp)
			target.hp += actual
			owner.healing += actual
			_emit("impact", owner, target, -1, {"effect":"heal", "actual":actual, "special":true, "label":binding.label, "hp":target.hp, "shield":target.shield})
		"attack_speed":
			if target.is_empty() or target.hp <= 0: return false
			var key := "%d/%s" % [target.id, source]
			speed_modifiers[key] = {"owner":target.id, "factor":proc.value, "until":elapsed + proc.duration}
			_refresh_interval(target)
		_:
			return false
	_note(owner.name + " · " + binding.label)
	return true

func _apply_shield(actor: Dictionary, target: Dictionary, amount: float, source: String, duration: float, label: String) -> void:
	var actual := grant_shield(target, amount, source, duration)
	if actual > 0:
		_emit("impact", actor, target, -1, {"effect":"shield", "actual":actual, "special":true, "label":label, "hp":target.hp, "shield":target.shield})

func _expire_speed_modifiers() -> void:
	var changed := {}
	for key in speed_modifiers.keys():
		var modifier: Dictionary = speed_modifiers[key]
		if modifier.until <= elapsed + EPSILON:
			changed[modifier.owner] = true
			speed_modifiers.erase(key)
	for id in changed: _refresh_interval(unit(id))

func _refresh_interval(target: Dictionary) -> void:
	var interval: float = target.base_interval
	for modifier in speed_modifiers.values():
		if modifier.owner == target.id: interval *= modifier.factor
	interval = clampf(interval, 0.1, 10)
	target.timer *= interval / maxf(target.interval, 0.1)
	target.interval = interval

func _set_attack_interval(target: Dictionary, value: float) -> void:
	target.base_interval = clampf(value, 0.1, 10)
	_refresh_interval(target)

func _pierce(actor: Dictionary, context: Dictionary, scale: float) -> bool:
	var due: Array[Dictionary] = context.effects
	for i in range(int(context.begin), due.size()):
		var e: Dictionary = due[i]
		if e.kind != "damage": continue
		var direction: Vector2 = actor.position.direction_to(e.target.position)
		var candidates := _living(1 - actor.side).filter(func(foe):
			var offset: Vector2 = foe.position - actor.position
			return foe.id != e.target.id and offset.dot(direction) > 0 and absf(offset.cross(direction)) <= 0.65 and AutoBattle.in_range(actor, foe))
		if candidates.is_empty(): return false
		_event(due, actor, _target(actor, candidates), "damage", e.value * scale, true)
		due[-1].trial_skill = true
		return true
	return false

func _verify(actor: Dictionary, target: Dictionary) -> void:
	if not marks.has(target.id) or not hack_choice.is_empty(): return
	var mark: Dictionary = marks[target.id]
	if mark.until <= elapsed + EPSILON or mark.owner == actor.id or mark.users.has(actor.id): return
	mark.users.append(actor.id)
	_add_progress(actor, Catalog.MANIFEST.verification_progress, "验证漏洞")
	_emit("mark_verified", actor, target, -1, {"owner_id":mark.owner})
	_dispatch("verify", actor)
	if mark.users.size() >= mark.limit: marks.erase(target.id)
