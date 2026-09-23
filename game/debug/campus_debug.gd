extends RefCounted
## Explicitly enabled developer commands; no direct profile unlocks or reward grants.
const Run = preload("res://game/run/short_run.gd")

static func reward_pool(hub) -> Array:
	var pool = Run.Rewards.eligible(hub.run.badge_owned,hub.run.roster,hub.run.inventory,hub.run.node.get("reward_pool","campus_rewards"),hub.run.training,hub.run.combat_rewards).duplicate(true)
	if not hub.campaign_mode.is_empty(): pool = pool.filter(func(offer): return offer.operation != "recruit")
	return pool

static func memory_alternative(hub) -> String:
	for spot in hub.journey.visit.data.get("hotspots",[]):
		if spot.kind != "memory" or hub.journey.visit.data.viewed.has(spot.id): continue
		for suffix in ["_system_1","_system_2"]:
			var id: String = hub.journey.visit.data.place + suffix
			if id != spot.id and not hub.progress.campaign.memories.has(id): return id
	return ""

static func reason(hub, command: String) -> String:
	if not hub.debug_enabled: return "请从 Debug 启动脚本进入。"
	if hub.progress.load_blocked: return "存档无法读取，请先在基地重开存档。"
	if hub.reset_pending or not hub.pending_exit.is_empty(): return "请先完成或取消当前确认。"
	var campaign: bool = not hub.campaign_mode.is_empty()
	var visit: Dictionary = hub.journey.visit.data
	if command in ["skip","restart"]:
		if command == "restart" and hub.screen not in ["battle","report"]: return "进入战斗或战报后可重开本场。"
		if campaign:
			if visit.is_empty() or visit.guard_won: return "当前没有尚未结算的守卫战。"
			if hub.screen not in ["battle","report","campaign"]: return "请先回到当前地点或战斗。"
		elif hub.screen not in ["battle","report"] or hub.run.node.is_empty() or hub.run.reward_taken:
			return "当前没有尚未结算的战斗。"
		return ""
	if command == "reroll":
		if campaign:
			if hub.screen != "campaign" or visit.is_empty(): return "在地点或待选奖励页重抽。"
			if hub.journey.data.screen == "reward" and not visit.reward_taken:
				var ids = hub.journey.data.offers.map(func(item): return item.id)
				if reward_pool(hub).any(func(item): return not ids.has(item.id)): return ""
				return "当前奖励池没有其他候选。"
			if hub.journey.data.screen == "visit" and not memory_alternative(hub).is_empty(): return ""
			return "本地点没有其他未查看的随机记录。已领取内容不会重置。"
		if hub.screen == "event" and not hub.run.event_done:
			if Run.Content.MANIFEST.events.any(func(item): return item.id != hub.run.current_event().get("id")): return ""
		if hub.screen == "reward" and not hub.run.reward_taken:
			var ids = hub.run.offers().map(func(item): return item.id)
			if reward_pool(hub).any(func(item): return not ids.has(item.id)): return ""
		return "当前没有可重抽的事件或其他奖励候选。"
	return "未知调试操作。"

static func execute(hub, command: String) -> bool:
	if not reason(hub,command).is_empty() or hub.paused: return false
	var previous = hub.run.to_dict()
	var previous_screen: String = hub.screen
	var previous_report = hub.report.duplicate(true)
	var previous_won: bool = hub.result_won
	if command == "restart":
		hub.report.clear()
		hub.result_won = false
		if not hub.campaign_mode.is_empty(): hub._guard()
		else:
			hub.screen = "battle"
			hub.phase = "prepare"
			hub._build_units()
			hub._checkpoint()
	elif command == "skip":
		hub.phase = "prepare"
		hub.result_won = true
		if not hub.campaign_mode.is_empty():
			hub.screen = "campaign"
			hub._victory()
		else:
			hub.screen = "report"
			hub._after_report()
	else:
		_reroll(hub)
		if not hub.campaign_mode.is_empty():
			if hub._save_campaign(): hub._show_journey()
		else: hub._checkpoint()
	if not hub.last_save_ok:
		# Campaign save already restores its committed model. Legacy runs need an
		# explicit rollback because their normal checkpoint helper only reports errors.
		if hub.campaign_mode.is_empty(): hub.run.restore(previous)
		hub.screen = previous_screen
		hub.report = previous_report
		hub.result_won = previous_won
		return false
	hub.queue_redraw()
	return true

static func _reroll(hub) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var campaign: bool = not hub.campaign_mode.is_empty()
	if campaign and hub.journey.data.screen == "visit":
		var replacement = memory_alternative(hub)
		for spot in hub.journey.visit.data.hotspots:
			if spot.kind == "memory" and not hub.journey.visit.data.viewed.has(spot.id): spot.id = replacement
	elif not campaign and hub.screen == "event":
		var pool = Run.Content.MANIFEST.events.filter(func(item): return item.id != hub.run.current_event().get("id"))
		var event = pool[rng.randi_range(0,pool.size()-1)].snapshot()
		hub.run.node.event = event
		for node in hub.run.stages[hub.run.stage]:
			if node.id == hub.run.node.id: node.event = event.duplicate(true)
	else:
		var current: Array = hub.journey.data.offers if campaign else hub.run.offers()
		var ids = current.map(func(item): return item.id)
		var pool = reward_pool(hub)
		Run.shuffle_with(pool,rng)
		var different = pool.filter(func(item): return not ids.has(item.id))[0]
		pool.erase(different)
		var offers = [different] + pool.slice(0,2)
		Run.shuffle_with(offers,rng)
		if campaign: hub.journey.data.offers = offers.duplicate(true)
		else:
			hub.run.reward_snapshots = offers.duplicate(true)
			hub.run.reward_ids = offers.map(func(item): return item.id)
