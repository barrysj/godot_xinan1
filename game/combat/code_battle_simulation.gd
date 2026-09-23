extends "res://game/combat/synergy_simulation.gd"
## Currency/commands adapter; movement, hit resolution and traits remain shared.
const Codes = preload("res://game/combat/code_catalog.gd")
const RewardCatalog = preload("res://game/run/reward_catalog.gd")
var blocks := {}
var loadout: Array = []
var items := {}
var attack_counts := {}
var credited_actions := {}
var pending_pulse := ""
var system_taken := false
var ready_at := 0.0
var casts := 0
var last_error := ""

func _apply_proc(binding: Dictionary, owner: Dictionary, context: Dictionary) -> bool:
	if binding.proc.effect == "hack":
		var kind: String = binding.proc.code_type
		if kind.is_empty(): kind = owner.get("code_type", "red")
		_gain(owner, kind, binding.proc.code_amount, binding.label)
		return true
	return super._apply_proc(binding, owner, context)

func _after_impact_batch(due: Array[Dictionary]) -> void:
	for hit in due:
		if hit.get("valid", false) and hit.actor.side == 0 and hit.kind == "damage" and not hit.special and hit.actual + hit.blocked > 0:
			_verify(hit.actor, hit.target)
	super._after_impact_batch(due)
	for hit in due:
		if not hit.get("valid", false) or hit.actor.side != 0 or hit.kind != "damage" or hit.special or hit.actual + hit.blocked <= 0: continue
		var key := "%d/%d" % [hit.actor.id, hit.action_id]
		if credited_actions.has(key): continue
		credited_actions[key] = true
		var actor: Dictionary = hit.actor
		attack_counts[actor.id] = attack_counts.get(actor.id, 0) + 1
		if attack_counts[actor.id] >= Codes.RULES.attacks_per_block:
			attack_counts[actor.id] -= Codes.RULES.attacks_per_block
			_gain(actor, actor.code_type, 1, "普攻产出")

func _gain(actor: Dictionary, kind: String, amount: int, reason: String, credit_name: String = "") -> int:
	if not blocks.has(kind) or amount <= 0: return 0
	var gain := mini(amount, Codes.RULES.cache_cap - int(blocks[kind]))
	if gain <= 0: return 0
	blocks[kind] += gain
	var credited: String = actor.name if credit_name.is_empty() else credit_name
	contributions[credited] = contributions.get(credited, 0) + gain
	_note("%s · %s +%d%s" % [actor.name, reason, gain, Codes.RULES.types[kind].name])
	_emit("code_generated", actor, actor, -1, {"code_type":kind, "actual":gain, "reason":reason})
	return gain

func _verify(actor: Dictionary, target: Dictionary) -> void:
	if not marks.has(target.id): return
	var mark: Dictionary = marks[target.id]
	if mark.until <= elapsed + EPSILON or mark.owner == actor.id or mark.users.has(actor.id): return
	mark.users.append(actor.id)
	var author := unit(mark.owner)
	if not author.is_empty(): _gain(author, author.code_type, 1, "漏洞验证")
	_emit("mark_verified", actor, target, -1, {"owner_id":mark.owner})
	_dispatch("verify", actor)
	if mark.users.size() >= mark.limit: marks.erase(target.id)

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
	if system_taken: return "系统已接管"
	if pending_pulse == "disconnect": return "下次维护已阻止"
	if pending_pulse == "redirect": return "下次维护将转给我方"
	return "敌方维护中"

func _active() -> bool:
	return not finished and not closing and not _living(0).is_empty() and not _living(1).is_empty()

func program_error(id: String) -> String:
	if not _active(): return "战斗已结束"
	var program = Codes.program(id)
	if program == null or not loadout.has(id): return "未携带此技能"
	if elapsed + EPSILON < ready_at: return "编译冷却 %.1f 秒" % (ready_at - elapsed)
	if program.effect in ["disconnect", "redirect", "takeover"]:
		if system_taken: return "系统已接管"
		if not pending_pulse.is_empty(): return "已有指令等待下次维护"
	if program.effect == "repair" and _living(0).all(func(u): return u.hp >= u.max_hp): return "没有受伤友军"
	for kind in program.cost:
		if blocks[kind] < program.cost[kind]: return "缺少" + Codes.cost_text({kind:program.cost[kind] - blocks[kind]})
	return ""

func cast_program(id: String) -> bool:
	last_error = program_error(id)
	if not last_error.is_empty(): return false
	var program = Codes.program(id)
	for kind in program.cost: blocks[kind] -= program.cost[kind]
	var actor: Dictionary = _living(0)[0]
	match program.effect:
		"disconnect":
			for foe in _living(1):
				var amount := remove_shields(foe, "maintenance")
				if amount > 0: _emit("shield_removed", actor, foe, -1, {"actual":amount, "shield":foe.shield})
			pending_pulse = "disconnect"
		"redirect": pending_pulse = "redirect"
		"takeover": system_taken = true
		"repair":
			var candidates := _living(0).filter(func(u): return u.hp < u.max_hp)
			for index in range(mini(2, candidates.size())):
				var target := _target({}, candidates, "low")
				var actual := minf(target.max_hp * program.heal_ratio, target.max_hp - target.hp)
				target.hp += actual
				_emit("impact", actor, target, -1, {"effect":"heal", "actual":actual, "special":true, "hp":target.hp, "shield":target.shield})
				candidates.erase(target)
	casts += 1
	ready_at = elapsed + Codes.RULES.shared_cooldown
	_dispatch("hack_complete")
	_note("执行破解 · " + program.display_name)
	_emit("hack_completed", actor, actor, -1, {"choice":program.effect, "label":program.display_name + "已执行"})
	return true

func item_error(id: String, destination: String, source: String = "") -> String:
	if not _active(): return "战斗已结束"
	var entry = Codes.item(id)
	if entry == null or items.get(id, 0) <= 0: return "道具已用尽"
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
	if entry.effect == "convert": blocks[source] -= entry.amount
	items[id] -= 1
	_gain(_living(0)[0], destination, entry.amount, entry.display_name, entry.display_name)
	_note("道具消耗 · " + entry.display_name)
	return true


## Attach shared rules to the original scene's roster, preserving its stats and enemies.
func configure_combat(programs: Array, supplies: Dictionary, maintenance_interval: float = 6.0, maintenance_shield: float = 35.0, combat_rewards: Array = []) -> void:
	blocks = {}
	for kind in Codes.RULES.types: blocks[kind] = 0
	loadout = programs.duplicate() if Codes.valid_loadout(programs) else Array(Codes.RULES.default_loadout).duplicate()
	items = supplies.duplicate() if Codes.valid_stock(supplies) else Codes.stock()
	attack_counts.clear()
	credited_actions.clear()
	pending_pulse = ""
	system_taken = false
	ready_at = 0
	casts = 0
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
	pulse_interval = maintenance_interval
	pulse_amount = maintenance_shield
	next_pulse = pulse_interval
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
			var matches_owner: bool = definition.category == "羁绊" or (definition.category == "专属" and definition.character_id == u.get("content_id", "")) or (definition.category == "装备" and reward.get("owner", "") == u.get("content_id", ""))
			if matches_owner:
				install_effects(u,definition.effects,"reward/"+definition.id,definition.display_name)
	_dispatch("battle_start")
