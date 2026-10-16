extends "res://game/combat/synergy_simulation.gd"
## Currency/commands adapter; movement, hit resolution and traits remain shared.
const Codes = preload("res://game/combat/code_catalog.gd")
const CODE_CYCLE_DURATION := 0.30
const RewardCatalog = preload("res://game/run/reward_catalog.gd")
var pending_code_cycles: Array[Dictionary] = []
var next_code_cycle_id := 0
var blocks := {}
var loadout: Array = []
var items := {}
var attack_counts := {}
var credited_actions := {}
var pending_pulse := ""
var system_taken := false
var ready_at := 0.0
var casts := 0
var absorbed := 0.0
var validation_ready := 0.0
var program_ready := {}
var program_uses := {}
var item_ready := 0.0
var item_uses := {}
var generated := {}
var spent := {}
var overflow := {}
var reactions: Array[Dictionary] = []
var recoil_pending: Array[Dictionary] = []
var warnings := {}
var warning_next := {}
var reward_owners := {}
var lens_seen := {}
var backup_seen := {}
var last_error := ""

func reset(roster: Array[Dictionary]) -> void:
	pending_code_cycles.clear()
	next_code_cycle_id = 0
	super.reset(roster)

func _queue_code_cycle(actor: Dictionary, kind: String, reason: String) -> void:
	next_code_cycle_id += 1
	var ready := elapsed + CODE_CYCLE_DURATION
	pending_code_cycles.append({"cycle_id":next_code_cycle_id, "actor":actor, "code_type":kind,
		"amount":1, "reason":reason, "ready_at":ready})
	_emit("code_cycle_started", actor, actor, -1, {"cycle_id":next_code_cycle_id, "code_type":kind,
		"amount":1, "reason":reason, "duration":CODE_CYCLE_DURATION, "ready_at":ready, "shared":kind == "purple"})

func _release_code_cycles() -> void:
	# Remove before emitting: nested effect resolution must never release twice.
	var ready: Array[Dictionary] = pending_code_cycles.filter(func(cycle): return elapsed + EPSILON >= cycle.ready_at)
	pending_code_cycles = pending_code_cycles.filter(func(cycle): return elapsed + EPSILON < cycle.ready_at)
	for cycle in ready:
		var gain := _gain(cycle.actor, cycle.code_type, cycle.amount, cycle.reason, "", cycle.cycle_id)
		_emit("code_cycle_completed", cycle.actor, cycle.actor, -1, {"cycle_id":cycle.cycle_id,
			"code_type":cycle.code_type, "actual":gain, "overflow":cycle.amount - gain, "reason":cycle.reason})

func _apply_proc(binding: Dictionary, owner: Dictionary, context: Dictionary) -> bool:
	if binding.proc.effect == "hack":
		var kind: String = binding.proc.code_type
		if kind.is_empty(): kind = owner.get("code_type", "red")
		_gain(owner, kind, binding.proc.code_amount, binding.label)
		return true
	return super._apply_proc(binding, owner, context)

func _after_impact_batch(due: Array[Dictionary]) -> void:
	# Scan skills complete before validation. Followups never count as basic hits.
	for hit in due:
		if hit.get("valid", false) and hit.get("scan", false) and hit.target.hp > 0:
			_place_scan(hit.actor, hit.target)
	for hit in due:
		if not hit.get("valid", false) or hit.kind != "damage": continue
		if hit.target.side == 0 and hit.blocked > 0:
			absorbed += hit.blocked
			while absorbed + EPSILON >= Codes.RULES.shield_per_block:
				absorbed -= Codes.RULES.shield_per_block
				_queue_code_cycle(hit.target, "purple", "护盾吸收")
				if tag_ids.has("protect"):
					var ally := _target({}, _living(0).filter(func(u): return u.hp < u.max_hp), "low")
					if not ally.is_empty(): _heal(hit.target, ally, Codes.RULES.absorption_heal)
		if hit.actor.side != 0 or hit.special or hit.actual + hit.blocked <= 0: continue
		var key := "%d/%d" % [hit.actor.id, hit.action_id]
		if credited_actions.has(key): continue
		credited_actions[key] = true
		var actor: Dictionary = hit.actor
		if actor.code_type != "purple":
			attack_counts[actor.id] = attack_counts.get(actor.id, 0) + 1
			if attack_counts[actor.id] >= Codes.RULES.attacks_per_block:
				attack_counts[actor.id] -= Codes.RULES.attacks_per_block
				_queue_code_cycle(actor, actor.code_type, "普攻产出")
		if reward_owners.get("lens", "") == actor.content_id and not lens_seen.has(actor.id):
			lens_seen[actor.id] = true
			_place_scan(actor, hit.target)
		_verify(actor, hit.target)
	super._after_impact_batch(due)
	for actor in _living(0):
		if actor.hp < actor.max_hp * 0.4 and reward_owners.get("backup", "") == actor.content_id and not backup_seen.has(actor.id):
			backup_seen[actor.id] = true
			_apply_shield(actor, actor, 45, "backup", 5, "应急备份")
	if not reactions.is_empty():
		var follow: Array[Dictionary] = reactions.duplicate()
		reactions.clear()
		_resolve(follow)

func _gain(actor: Dictionary, kind: String, amount: int, reason: String, credit_name: String = "", cycle_id: int = -1) -> int:
	if not blocks.has(kind) or amount <= 0: return 0
	var gain := mini(amount, Codes.RULES.cache_cap - int(blocks[kind]))
	generated[kind] = generated.get(kind, 0) + amount
	overflow[kind] = overflow.get(kind, 0) + amount - gain
	if gain <= 0: return 0
	blocks[kind] += gain
	var credited: String = actor.name if credit_name.is_empty() else credit_name
	contributions[credited] = contributions.get(credited, 0) + gain
	_note("%s · %s +%d%s" % [actor.name, reason, gain, Codes.RULES.types[kind].name])
	_emit("code_generated", actor, actor, -1, {"code_type":kind, "actual":gain, "reason":reason, "cycle_id":cycle_id})
	return gain

func _place_scan(actor: Dictionary, target: Dictionary) -> void:
	if target.is_empty() or target.hp <= 0: return
	var mark: Dictionary = marks.get(target.id, {})
	if mark.get("exposed_until", 0.0) > elapsed: return
	mark.owner = actor.id
	mark.pending_until = elapsed + Codes.RULES.vulnerability_duration
	mark.until = maxf(mark.pending_until, mark.get("confirmed_until", 0.0))
	marks[target.id] = mark
	_emit("mark_applied", actor, target, active_action_id, {"duration":Codes.RULES.vulnerability_duration, "uses":1})

func _verify(actor: Dictionary, target: Dictionary) -> void:
	if actor.hp <= 0 or target.hp <= 0 or not marks.has(target.id): return
	var mark: Dictionary = marks[target.id]
	if mark.get("exposed_until", 0.0) > elapsed:
		if not mark.users.has(actor.id):
			mark.users.append(actor.id)
			_followup(actor, target, Codes.RULES.exposure_scale, "暴露追击")
		return
	if mark.get("pending_until", 0.0) <= elapsed or mark.owner == actor.id: return
	if tag_ids.has("analysis") and elapsed + EPSILON < validation_ready: return
	mark.pending_until = 0.0
	mark.confirmed_until = elapsed + Codes.RULES.confirmation_duration
	mark.until = mark.confirmed_until
	mark.extended = false
	_emit("mark_verified", actor, target, -1, {"owner_id":mark.owner, "duration":Codes.RULES.confirmation_duration})
	if tag_ids.has("analysis"):
		validation_ready = elapsed + Codes.RULES.validation_cooldown
		var scale: float = 1.1 if upgrades.has("verify") and unit(mark.owner).get("content_id", "") == "analyst" else Codes.RULES.validation_scale
		_followup(actor, target, scale, "协同验证")
		_gain(actor, "blue", 1, "漏洞验证")

func _followup(actor: Dictionary, target: Dictionary, scale: float, label: String) -> void:
	_event(reactions, actor, target, "damage", actor.atk * scale, true)
	_emit("chain_followup", actor, target, -1, {"label":label})
	_note(actor.name + " · " + label)

func _heal(actor: Dictionary, target: Dictionary, amount: float, program_effect: bool = false) -> void:
	var actual := minf(amount, target.max_hp - target.hp)
	target.hp += actual
	actor.healing += actual
	_emit("impact", actor, target, -1, {"effect":"heal", "actual":actual, "program_effect":program_effect, "special":true, "hp":target.hp, "shield":target.shield})

func _maintenance_pulse() -> void:
	if pending_pulse == "disconnect":
		_note("断链 · 已阻止维护脉冲")
	elif pending_pulse == "redirect" or system_taken:
		var ally := _target({}, _living(0), "low")
		if not ally.is_empty(): _apply_shield(ally, ally, pulse_amount, "maintenance", 0, "维护接管")
		_note("维护脉冲 · 保护我方")
	else:
		super._maintenance_pulse()
	pending_pulse = ""

func system_status() -> String:
	for warning in warnings.values():
		return "%s · %.1f秒" % [warning.label, maxf(0, warning.fire_at - elapsed)]
	return "吸收 %d / %d" % [int(absorbed), int(Codes.RULES.shield_per_block)]

func _active() -> bool:
	return not finished and not closing and not _living(0).is_empty() and not _living(1).is_empty()

func program_targets(id: String) -> Array[Dictionary]:
	var program = Codes.program(id)
	if program == null: return []
	if program.effect == "pursuit":
		return _living(1).filter(func(u): return marks.get(u.id, {}).get("confirmed_until", 0.0) > elapsed and marks.get(u.id, {}).get("exposed_until", 0.0) <= elapsed)
	if program.effect == "repair": return _living(0).filter(func(u): return u.hp < u.max_hp)
	return _living(0)

func payment_for(id: String) -> Dictionary:
	var program = Codes.program(id)
	if program == null: return {}
	if program.any_cost <= 0: return program.cost.duplicate()
	var result := {}
	var remaining: int = program.any_cost
	# Prefer surplus colors, then spend the largest remaining pile, stable color ties.
	var available: Dictionary = blocks.duplicate()
	var reserve := {}
	for other in loadout:
		var core = Codes.program(other)
		if core == null or core.any_cost > 0: continue
		for color in core.cost: reserve[color] = maxi(reserve.get(color, 0), core.cost[color])
	for pass_index in range(2):
		while remaining > 0:
			var best := ""
			var count := 0
			for color in Codes.RULES.types:
				var spare: int = available[color] - (reserve.get(color, 0) if pass_index == 0 else 0)
				if spare > count: best = color; count = spare
			if best.is_empty(): break
			result[best] = result.get(best, 0) + 1
			available[best] -= 1
			remaining -= 1
	return result

func program_error(id: String, target_id: int = -1, payment: Dictionary = {}) -> String:
	if not _active(): return "战斗已结束"
	var program = Codes.program(id)
	if program == null or not loadout.has(id): return "未携带此程序"
	if elapsed + EPSILON < ready_at: return "编译冷却 %.1f 秒" % (ready_at - elapsed)
	if elapsed + EPSILON < program_ready.get(id, 0.0): return "程序冷却 %.1f 秒" % (program_ready[id] - elapsed)
	if program.per_battle_limit > 0 and program_uses.get(id, 0) >= program.per_battle_limit: return "本场次数已用尽"
	if program.effect in ["pursuit", "repair"]:
		var targets := program_targets(id)
		if targets.is_empty(): return "需要先由另一名队友普攻验证目标的漏洞（验证后8秒内可用）" if program.effect == "pursuit" else "没有受伤友军"
		if target_id >= 0 and not targets.any(func(u): return u.id == target_id): return "目标已失效"
	var cost: Dictionary = payment_for(id) if payment.is_empty() else payment
	if program.any_cost <= 0 and cost != program.cost: return "配方不匹配"
	var total := 0
	for kind in cost:
		var amount = cost[kind]
		if not blocks.has(kind) or not amount is int or amount < 0: return "支付非法"
		if blocks[kind] < amount: return "缺少" + Codes.cost_text({kind:amount - blocks[kind]})
		total += amount
	if program.any_cost > 0 and total != program.any_cost: return "需要任意%d块代码" % program.any_cost
	return ""

func cast_program(id: String, target_id: int = -1, payment: Dictionary = {}) -> bool:
	last_error = program_error(id, target_id, payment)
	if not last_error.is_empty(): return false
	var program = Codes.program(id)
	var cost: Dictionary = payment_for(id) if payment.is_empty() else payment
	var candidates := program_targets(id)
	var target := unit(target_id) if target_id >= 0 else _target({}, candidates, "low")
	for kind in cost:
		blocks[kind] -= cost[kind]
		spent[kind] = spent.get(kind, 0) + cost[kind]
	var actor: Dictionary = _living(0)[0]
	var affected_ids: Array[int] = []
	match program.effect:
		"pursuit":
			var mark: Dictionary = marks[target.id]
			mark.confirmed_until = 0.0
			mark.pending_until = 0.0
			mark.exposed_until = elapsed + program.duration
			mark.until = mark.exposed_until
			mark.users = []
			var hit: Array[Dictionary] = []
			_event(hit, actor, target, "damage", program.damage, true)
			hit[-1].program_effect = true
			_resolve(hit)
			affected_ids.append(target.id)
		"recoil":
			for ally in _living(0):
				_recoil_shield(ally, program)
				affected_ids.append(ally.id)
		"repair":
			_heal(actor, target, program.heal_amount, true)
			affected_ids.append(target.id)
	casts += 1
	program_uses[id] = program_uses.get(id, 0) + 1
	program_ready[id] = elapsed + program.cooldown
	ready_at = elapsed + Codes.RULES.shared_cooldown
	_dispatch("hack_complete")
	_note("执行破解 · " + program.display_name)
	_emit("hack_completed", actor, actor, -1, {"choice":id, "label":program.display_name+"已执行", "affected_ids":affected_ids})
	return true

func item_error(id: String, destination: String, source: String = "") -> String:
	if not _active(): return "战斗已结束"
	var entry = Codes.item(id)
	if entry == null or items.get(id, 0) <= 0: return "道具已用尽"
	if item_uses.has(id): return "本场已使用"
	if elapsed + EPSILON < item_ready: return "道具冷却 %.1f 秒" % (item_ready - elapsed)
	if entry.effect in ["shield","revive"]:
		if not destination.is_valid_int(): return "请选择队员"
		var target := unit(int(destination))
		if target.is_empty() or target.side != 0: return "请选择我方队员"
		if entry.effect == "revive": return "队员尚未倒下" if target.hp > 0 else ""
		if target.hp <= 0: return "需要存活队员"
		return "护盾已满" if target.shield >= SHIELD_CAP else ""
	if not blocks.has(destination): return "请选择目标代码类型"
	if blocks[destination] + entry.amount > Codes.RULES.cache_cap: return "目标缓存空间不足，不会消耗道具"
	if entry.effect == "convert":
		if not blocks.has(source) or source == destination: return "请选择两种不同代码"
		if blocks[source] < entry.amount: return "转换来源不足%d块" % entry.amount
	return ""

func use_item(id: String, destination: String, source: String = "") -> bool:
	last_error = item_error(id, destination, source)
	if not last_error.is_empty(): return false
	var entry = Codes.item(id)
	if entry.effect == "convert":
		blocks[source] -= entry.amount
		report_stats.converted[source] = report_stats.converted.get(source, 0) + entry.amount
	items[id] -= 1
	item_uses[id] = true
	item_ready = elapsed + Codes.RULES.item_cooldown
	var actor: Dictionary = _living(0)[0]
	if entry.effect == "shield":
		_apply_shield(actor,unit(int(destination)),float(entry.amount),"preparation",8.0,entry.display_name)
	elif entry.effect == "revive":
		var target := unit(int(destination))
		target.hp = maxf(1.0,target.max_hp * entry.amount / 100.0)
		target.action = {}
		target.pending_cast = {}
		target.timer = target.interval
		target.shield_layers = []
		_sync_shields(target)
		_emit("revived",actor,target,-1,{"hp":target.hp})
	else:
		_gain(actor, destination, entry.amount, entry.display_name, entry.display_name)
	_note("道具消耗 · " + entry.display_name)
	return true


## Attach shared rules to the original scene's roster, preserving its stats and enemies.
func configure_combat(programs: Array, supplies: Dictionary, maintenance_interval: float = 6.0, maintenance_shield: float = 35.0, combat_rewards: Array = []) -> void:
	pending_code_cycles.clear()
	next_code_cycle_id = 0
	blocks = {}
	for kind in Codes.RULES.types: blocks[kind] = 0
	loadout = programs.duplicate() if Codes.valid_loadout(programs) else Array(Codes.RULES.default_loadout).duplicate()
	var migrated_stock := Codes.migrate_stock(supplies)
	items = migrated_stock if not migrated_stock.is_empty() else Codes.stock()
	attack_counts.clear()
	credited_actions.clear()
	pending_pulse = ""
	system_taken = false
	ready_at = 0
	casts = 0
	absorbed = 0
	validation_ready = 0
	program_ready.clear()
	program_uses.clear()
	item_ready = 0
	item_uses.clear()
	generated.clear()
	spent.clear()
	overflow.clear()
	reactions.clear()
	recoil_pending.clear()
	warnings.clear()
	warning_next.clear()
	reward_owners.clear()
	lens_seen.clear()
	backup_seen.clear()
	for reward in combat_rewards: reward_owners[reward.get("target", "")] = reward.get("owner", "")
	for foe in _living(1):
		if _enemy_rule(foe) in ["radio", "board", "colossus"]: warning_next[foe.id] = 9.0
	last_error = ""
	marks.clear()
	contributions.clear()
	notes.clear()
	bindings.clear()
	proc_uses.clear()
	half_seen.clear()
	speed_modifiers.clear()
	tag_ids.clear()
	tags.clear()
	upgrades.clear()
	for reward in combat_rewards: upgrades.append(reward.get("target", ""))
	pulse_interval = 0.0 # Enemy telegraphs replace the legacy global maintenance pulse.
	pulse_amount = maintenance_shield
	next_pulse = INF
	var counts := {}
	var definitions := {}
	for u in units:
		u.base_interval = u.interval
		if u.side != 0: continue
		u.tags = []
		u.code_type = "red"
		for character in Catalog.MANIFEST.characters:
			if character.id != u.get("content_id", ""): continue
			definitions[u.id] = character
			u.tags = Array(character.tags)
			u.code_type = character.code_type
			for tag in u.tags: counts[tag] = counts.get(tag,0)+1
	for synergy in Catalog.MANIFEST.synergies:
		if counts.get(synergy.id,0) >= synergy.required_count:
			tag_ids.append(synergy.id)
			tags.append(synergy.display_name)
	for u in _living(0):
		if definitions.has(u.id):
			var character = definitions[u.id]
			install_effects(u, character.effects, "character/"+character.id, character.display_name)
		for tag in tag_ids:
			if u.tags.has(tag):
				var synergy = Catalog.synergy(tag)
				install_effects(u, synergy.effects,"synergy/"+tag,synergy.display_name)
	for reward in combat_rewards:
		var definition = RewardCatalog.find_combat(reward.get("target", ""))
		if definition == null: continue
		for u in _living(0):
			var matches_owner: bool = definition.category in ["羁绊", "程序"] or (definition.category == "专属" and definition.character_id == u.get("content_id", "")) or (definition.category == "装备" and reward.get("owner", "") == u.get("content_id", ""))
			if matches_owner:
				install_effects(u,definition.effects,"reward/"+definition.id,definition.display_name)
	_dispatch("battle_start")
	if tag_ids.has("protect"):
		var frontline := _living(0)
		frontline.sort_custom(func(a, b): return a.position.y < b.position.y if a.position.y != b.position.y else a.id < b.id)
		for i in range(mini(2, frontline.size())):
			var ally: Dictionary = frontline[i]
			_apply_shield(ally, ally, Codes.RULES.opening_shield + (15 if upgrades.has("cover") else 0), "opening", 5, "容错工程")


func advance(delta: float) -> Array[Dictionary]:
	if finished or not is_finite(delta) or delta <= 0: return []
	for ally in _living(0):
		var targets := _living(1).filter(func(u): return AutoBattle.in_range(ally, u) and marks.get(u.id, {}).get("exposed_until", 0.0) > elapsed)
		if not targets.is_empty() and ally.action.is_empty(): ally.target_id = _target(ally, targets).id
	var output := super.advance(delta)
	# Completed natural production is earned even when its author or final enemy
	# dies. Close combat immediately, but finish only after the short queue settles.
	if finished and not pending_code_cycles.is_empty(): finished = false
	return output

func _resolve(due: Array[Dictionary]) -> void:
	_release_code_cycles()
	# Expiry occurs during advance before this batch; broken shields queue the next batch.
	for blast in recoil_pending:
		_append_blast(due, blast)
	recoil_pending.clear()
	super._resolve(due)
	if not recoil_pending.is_empty():
		var blasts: Array[Dictionary] = []
		for blast in recoil_pending: _append_blast(blasts, blast)
		recoil_pending.clear()
		if not blasts.is_empty(): _resolve(blasts)

func grant_shield(target: Dictionary, amount: float, source: String = "skill", duration: float = 0.0) -> float:
	if source.begins_with("ordinary/") or source in ["opening", "backup", "broadcast"]:
		var previous := 0.0
		for layer in target.get("shield_layers", []):
			if layer.source == source: previous += layer.amount
		remove_shields(target, source)
		var gained := super.grant_shield(target, maxf(previous, amount), source, duration)
		return maxf(0, gained - previous)
	return super.grant_shield(target, amount, source, duration)

func _program_reward_bonus(program_id: String, field: String) -> float:
	var total := 0.0
	for reward_id in upgrades:
		var definition = Catalog.reward(reward_id)
		if definition != null and definition.category == "程序" and definition.program_id == program_id:
			total += float(definition.get(field))
	return total

func _recoil_shield(ally: Dictionary, program) -> void:
	_sync_shields(ally)
	var trim: float = maxf(0, ally.shield + program.shield - SHIELD_CAP)
	ally.shield_layers.sort_custom(func(a, b): return a.expires_at > b.expires_at)
	for layer in ally.shield_layers:
		var taken := minf(trim, layer.amount)
		layer.amount -= taken
		ally.shield -= taken
		trim -= taken
		if trim <= EPSILON: break
	var gain := super.grant_shield(ally, program.shield, "recoil", program.duration + _program_reward_bonus(program.id, "program_duration_bonus"))
	for layer in ally.shield_layers:
		if layer.source == "recoil": layer.priority = 1; layer.exploded = false
	_emit("impact", ally, ally, -1, {"effect":"shield", "actual":gain, "program_effect":true, "special":true, "hp":ally.hp, "shield":ally.shield})

func _shield_ended(target: Dictionary, layer: Dictionary, reason: String) -> void:
	if layer.source != "recoil" or layer.get("exploded", false) or closing or finished: return
	layer.exploded = true
	recoil_pending.append({"actor":target, "position":target.position, "reason":reason})

func _append_blast(due: Array[Dictionary], blast: Dictionary) -> void:
	var program = Codes.program("redirect")
	for foe in _living(1):
		if foe.position.distance_to(blast.position) <= program.radius:
			_event(due, blast.actor, foe, "damage", program.damage + _program_reward_bonus(program.id, "program_damage_bonus"), true)
	_emit("recoil_burst", blast.actor, blast.actor, -1, {"from":blast.position, "reason":blast.reason, "radius":program.radius})
	_note(blast.actor.name + " · 反冲爆炸")

func _enemy_rule(actor: Dictionary) -> String:
	# Reuse registered skill behavior when another approved enemy shares that skill.
	var skill = actor.get("skill")
	if skill != null and skill.id.begins_with("skill_enemy_"):
		return skill.id.trim_prefix("skill_enemy_")
	return actor.content_id

func _skill_events(actor: Dictionary, target: Dictionary, due: Array[Dictionary]) -> void:
	var begin := due.size()
	var skill = actor.skill
	if actor.side == 1:
		match _enemy_rule(actor):
			"radio", "board", "colossus": return
			"paper_guard": _skill_shield(due, actor, actor, skill.effects[0].value, 5)
			"desk": _event(due, actor, _target(actor, _living(0).filter(func(u): return AutoBattle.in_range(actor,u)), "low"), "damage", actor.atk * skill.effects[0].attack_scale, true)
			"pages": _event(due, actor, _target(actor, _living(0).filter(func(u): return AutoBattle.in_range(actor,u)), "back"), "damage", actor.atk * skill.effects[0].attack_scale, true)
			"chalk":
				if not target.is_empty() and AutoBattle.in_range(actor, target): _event(due, actor, target, "damage", actor.atk * skill.effects[0].attack_scale, true)
		return
	match actor.content_id:
		"guard":
			_skill_shield(due, actor, actor, skill.effects[0].value, 6)
			var allies := _living(0).filter(func(u): return u.id != actor.id and AutoBattle.distance(actor,u) <= 2.0)
			_skill_shield(due, actor, _target(actor, allies, "low"), skill.effects[0].value, 6)
		"inventor":
			var allies := _living(0)
			for i in range(mini(2, allies.size())):
				var ally := _target({}, allies, "low")
				_skill_shield(due, actor, ally, skill.effects[0].value, 6)
				allies.erase(ally)
		"healer":
			var hurt := _living(0).filter(func(u): return u.hp < u.max_hp)
			if hurt.is_empty(): _skill_shield(due, actor, _target({}, _living(0), "low"), 25, 5)
			else: _event(due, actor, _target({}, hurt, "low"), "heal", skill.effects[0].value, true)
		"analyst":
			if target.is_empty() or not AutoBattle.in_range(actor, target): return
			_event(due, actor, target, "damage", actor.atk * skill.effects[0].attack_scale, true)
			due[-1].scan = true
		"archer":
			var foes := _living(1).filter(func(u): return AutoBattle.in_range(actor,u))
			var marked := foes.filter(func(u): return marks.get(u.id, {}).get("confirmed_until", 0.0) > elapsed or marks.get(u.id, {}).get("exposed_until", 0.0) > elapsed)
			_event(due, actor, _target(actor, marked if not marked.is_empty() else foes, "back"), "damage", actor.atk * skill.effects[0].attack_scale, true)
		"striker":
			var victim := _target(actor, _living(1).filter(func(u): return AutoBattle.in_range(actor,u)), "low")
			if not victim.is_empty(): _event(due, actor, victim, "damage", actor.atk * (2.1 if victim.hp < victim.max_hp * 0.35 else skill.effects[0].attack_scale), true)
		"morning":
			if target.is_empty() or not AutoBattle.in_range(actor, target): return
			_event(due, actor, target, "damage", actor.atk * skill.effects[0].attack_scale, true)
			var mark: Dictionary = marks.get(target.id, {})
			if mark.get("confirmed_until", 0.0) > elapsed and not mark.get("extended", false):
				mark.confirmed_until += 2
				mark.until = maxf(mark.until, mark.confirmed_until)
				mark.extended = true
	for i in range(begin, due.size()): due[i].synergy_skill = true
	_dispatch("skill_emit", actor, {"target":target, "action_id":active_action_id, "effects":due, "begin":begin})

func _skill_shield(due: Array[Dictionary], actor: Dictionary, target: Dictionary, amount: float, duration: float) -> void:
	if target.is_empty(): return
	_event(due, actor, target, "shield", amount, true)
	due[-1].source = "ordinary/%d" % actor.id
	due[-1].duration = duration

func _uses_attack_skill(actor: Dictionary) -> bool:
	if actor.side == 1 and _enemy_rule(actor) in ["radio", "board", "colossus"]: return false
	return super._uses_attack_skill(actor)

func _start_pending_action(actor: Dictionary) -> bool:
	if warning_next.has(actor.id) and elapsed + EPSILON >= warning_next[actor.id]:
		return _start_warning(actor)
	return super._start_pending_action(actor)

func _start_warning(foe: Dictionary) -> bool:
	var victim := _target(foe, _living(0))
	if victim.is_empty(): return false
	var center: Vector2 = victim.position
	var rule := _enemy_rule(foe)
	if rule == "board":
		var best_count := -1
		for row in range(7):
			var count := _living(0).filter(func(u): return absf(u.position.y - row) <= 0.5).size()
			if count > best_count: best_count = count; center.y = row
	var label: String = "护盾广播" if rule == "radio" else "整排写入" if rule == "board" else "书库重击" if foe.content_id == "cyber_librarian" else "巨像重击"
	_start_cast(foe, victim, 3.0)
	warnings[foe.id] = {"fire_at":elapsed + 3.0, "center":center, "label":label, "mode":rule}
	_emit("enemy_warning", foe, victim, foe.action.id, {"label":label, "center":center, "fire_at":elapsed + 3.0, "mode":rule})
	return true

func _cast_effects(actor: Dictionary, target: Dictionary, due: Array[Dictionary]) -> void:
	if not warnings.has(actor.id):
		super._cast_effects(actor, target, due)
		return
	var warning: Dictionary = warnings[actor.id]
	var rule := _enemy_rule(actor)
	if rule == "radio":
		for ally in _living(1):
			if ally.id != actor.id:
				_event(due, actor, ally, "shield", actor.skill.effects[0].value, true)
				due[-1].source = "broadcast"; due[-1].duration = 5.0
	else:
		for ally in _living(0):
			var inside: bool = absf(ally.position.y - warning.center.y) <= 0.5 if rule == "board" else ally.position.distance_to(warning.center) <= 2.0
			if inside: _event(due, actor, ally, "damage", actor.skill.effects[0].value, true)
	_emit("enemy_release", actor, actor, actor.action.id, {"label":warning.label, "mode":rule, "center":warning.center})
	# Preserve the ten-second start-to-start cadence, including delayed starts.
	warning_next[actor.id] = elapsed + 7.0
	warnings.erase(actor.id)

func _deliver_effects(actor: Dictionary, effects: Array[Dictionary], due: Array[Dictionary]) -> void:
	# Telegraph damage lands at release on the locked ground, never as homing shots.
	if actor.action.get("kind", "attack") == "cast" and actor.side == 1 and _enemy_rule(actor) in ["radio", "board", "colossus"]:
		due.append_array(effects)
		return
	super._deliver_effects(actor, effects, due)

func _end_action(actor: Dictionary) -> void:
	warnings.erase(actor.id)
	super._end_action(actor)

func intent_for(actor_id: int) -> Dictionary:
	var intent := super.intent_for(actor_id)
	if intent.is_empty(): return intent
	var actor := unit(actor_id)
	if not warnings.has(actor_id):
		if intent.kind == "cast" and actor.side == 0:
			match actor.content_id:
				"guard": intent.target_description = "自身及两格内一名最低生命比例友方"; intent.target_id = -1
				"inventor": intent.target_description = "两名最低生命比例友方（释放时选定）"; intent.target_id = -1
				"healer": intent.target_description = "最低生命比例受伤友方；无人受伤时为最低生命比例友方加盾"; intent.target_id = -1
				"archer": intent.target_description = "射程内优先漏洞已验证或暴露的后排敌方（释放时选定）"; intent.target_id = -1
		if intent.kind == "cast" and actor.side == 1 and _enemy_rule(actor) in ["radio", "board", "colossus"]:
			var rule := _enemy_rule(actor)
			intent.target_id = -1
			intent.target_description = "其他存活敌人" if rule == "radio" else "锁定横排" if rule == "board" else "锁定半径 2 格区域"
		return intent
	var warning: Dictionary = warnings[actor_id]
	intent.label = warning.label
	intent.icon = "shield" if warning.mode == "radio" else "area"
	intent.locked = warning.mode != "radio"
	intent.target_id = -1
	intent.target_description = "其他存活敌人" if warning.mode == "radio" else "锁定横排" if warning.mode == "board" else "锁定半径 2 格区域"
	intent.center = warning.center
	intent.description = "其他存活敌人获得 %d 点护盾，持续 5 秒。施法者阵亡取消。" % actor.skill.effects[0].value if warning.mode == "radio" else "对锁定%s内友方造成 %d 点基础伤害；位置不追踪，施法者阵亡取消。" % ["横排" if warning.mode == "board" else "半径 2 格区域", actor.skill.effects[0].value]
	return intent
