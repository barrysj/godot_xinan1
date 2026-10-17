extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const OUT := "res://.godot/art-workflow/battle-hud-polish/"
var checks := 0
var failures := 0
var game
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func fresh():
	var sim = Fixture.build([0,5,-1,3,1,-1])
	for u in sim.units:
		u.hp = 10000.0
		u.max_hp = 10000.0
		u.timer = 1000.0
	return sim
func damage_events(sim) -> Array:
	return sim.drain_events().filter(func(e): return e.kind == "impact" and e.effect == "damage")
func source_checks() -> void:
	var sim = fresh()
	var actor: Dictionary = sim.units.filter(func(u): return u.content_id == "archer")[0]
	var target: Dictionary = sim._living(1)[0]
	for special in [false,true]:
		var due: Array[Dictionary] = []
		var before: float = target.hp
		sim._event(due,actor,target,"damage",40,special)
		sim._resolve(due)
		var hits := damage_events(sim)
		verify(hits.size() == 1 and hits[0].damage_source == ("skill" if special else "attack") and not hits[0].is_followup,"Ordinary and skill impacts retain category without a followup tag")
		verify(hits.size() == 1 and is_equal_approx(before-target.hp,hits[0].actual),"Provenance does not change resolved damage")
	for source in ["attack","skill"]:
		var due: Array[Dictionary] = []
		var counts: Dictionary = sim.attack_counts.duplicate()
		sim._event(due,actor,target,"damage",40,true,source,true)
		sim._resolve(due)
		var tagged := damage_events(sim)
		verify(tagged.size() == 1 and tagged[0].damage_source == source and tagged[0].is_followup,"Followup flag is independent of attack category")
		verify(sim.attack_counts == counts,"Presentation category does not turn followups into code-generating normal hits")
	sim._followup(actor,target,0.5,"验证追击")
	var empty: Array[Dictionary] = []
	sim._resolve(empty)
	var hits := damage_events(sim)
	verify(not hits.is_empty() and hits.all(func(e): return e.damage_source == "skill" and e.is_followup),"Current real followups are skill damage with a separate followup flag")
	var analyst: Dictionary = sim.units.filter(func(u): return u.content_id == "analyst")[0]
	sim._place_scan(analyst,target)
	sim.marks[target.id].confirmed_until = 10
	for kind in sim.blocks: sim.blocks[kind] = 6
	verify(sim.cast_program("disconnect",target.id),"Cast real pursuit program")
	hits = damage_events(sim)
	verify(not hits.is_empty() and hits.all(func(e): return e.damage_source == "skill" and not e.is_followup and e.program_effect),"Program damage uses skill icon and retains report ownership")
	sim = fresh()
	actor = sim._living(0)[0]
	target = sim._living(1)[0]
	var blast: Array[Dictionary] = []
	sim._append_blast(blast,{"actor":actor,"position":target.position,"reason":"broken"})
	sim._resolve(blast)
	hits = damage_events(sim)
	verify(not hits.is_empty() and hits.all(func(e): return e.damage_source == "skill" and not e.is_followup and not e.program_effect),"Recoil explosion uses skill icon without changing report ownership")
	sim = fresh()
	actor = sim.units.filter(func(u): return u.content_id == "archer")[0]
	target = sim._living(1)[0]
	actor.position = Vector2(2,3)
	actor.previous_position = actor.position
	target.position = Vector2(4,3)
	target.previous_position = target.position
	sim._start_cast(actor,target,0.1)
	var saw_projectile := false
	var saw_impact := false
	for step in 60:
		var events: Array = sim.advance(0.05)
		if not sim.projectiles.is_empty():
			saw_projectile = true
			verify(sim.projectiles.all(func(shot): return shot.effect.damage_source == "skill"),"Projectile stores provenance at launch")
		for event in events:
			if event.kind == "impact" and event.actor_id == actor.id and event.effect == "damage":
				verify(event.damage_source == "skill","Delayed projectile impact retains source after release")
				saw_impact = true
		if saw_impact: break
	verify(saw_projectile and saw_impact,"Real ranged cast reaches projectile impact")
func frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func shot(label: String) -> void:
	game.queue_redraw()
	await frame()
	await RenderingServer.frame_post_draw
	if not "--capture" in OS.get_cmdline_user_args(): return
	var size := get_window().size
	verify(get_viewport().get_texture().get_image().save_png(OUT+"%s-%dx%d.png" % [label,size.x,size.y]) == OK,"Captured "+label)
func _ready() -> void:
	if not OS.has_feature("web"): DirAccess.make_dir_recursive_absolute(OUT)
	source_checks()
	if "--source-only" not in OS.get_cmdline_user_args(): await visuals()
	print(("DAMAGE_PREVIEW_READY" if "--preview" in OS.get_cmdline_user_args() else "DAMAGE_FEEDBACK_CHECK")+" checks=%d failures=%d" % [checks,failures])
	if "--preview" in OS.get_cmdline_user_args(): return
	get_tree().quit(0 if failures == 0 else 1)
func visuals() -> void:
	game = Campaign.instantiate()
	game.progress.path = ("user://" if OS.has_feature("web") else OUT)+"damage-profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	game.storage_ready = false
	game.set_process(false)
	game.tutorial_guide.skipped = true
	game.tutorial_guide.hide()
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game.run.code_programs = ["disconnect","redirect","repair"]
	game._start()
	await frame()
	var hud = game.battle_status_layer
	var initial_motion := InputEventMouseMotion.new()
	initial_motion.position = Vector2(8,180)
	initial_motion.global_position = initial_motion.position
	if not OS.has_feature("web"): get_viewport().warp_mouse(initial_motion.position)
	get_viewport().push_input(initial_motion,true)
	game.inspector.close_info()
	await frame()
	game.paused = true
	var sim = game.simulation
	var actor: Dictionary = sim._living(0)[0]
	var foes: Array = sim._living(1)
	var due: Array[Dictionary] = []
	var kinds := ["attack","skill","attack","skill"]
	for i in range(4): sim._event(due,actor,foes[i],"damage",34+18*i,i != 0,kinds[i],i >= 2)
	var ally: Dictionary = sim._living(0)[1]
	sim.grant_shield(ally,25,"fixture")
	sim._event(due,foes[0],ally,"damage",70,false,"attack")
	sim._resolve(due)
	game.code_panel._consume_pending()
	sim._heal(actor,ally,20)
	game.code_panel._consume_pending()
	game.paused = false
	hud._visual_update(0.12)
	verify(hud.damage_numbers.all(func(n): return is_equal_approx(n.age,0.12)),"Sample starts after its pop, with no accidental reading pause")
	game.paused = true
	var sizes := [get_window().size] if OS.has_feature("web") else [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(1280,720)]
	for size in sizes:
		if not OS.has_feature("web"): get_window().size = size
		await frame()
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(8,180)
		motion.global_position = motion.position
		if not OS.has_feature("web"): get_viewport().warp_mouse(motion.position)
		get_viewport().push_input(motion,true)
		game.inspector.close_info()
		game._update_battle_presentations()
		hud._process(0)
		await shot("damage-categories")
		verify(hud.damage_source_bounds.size() >= 4,"Damage rows have trailing category icons")
		verify(hud.damage_source_bounds.all(func(icon): return icon.kind in ["attack","skill"]),"Only two damage categories appear")
		verify(hud.followup_bounds.size() == 2,"Both ordinary and skill followups have the text tag")
		for tag in hud.followup_bounds:
			verify(tag.rect.position.x >= tag.icon_end+5,"Followup text follows its own damage icon")
			verify(tag.font < 20,"Followup text remains smaller than shield and health values")
			verify(hud.damage_bounds.any(func(bounds): return bounds.encloses(tag.rect)),"Layout includes the full followup tag")
		for icon in hud.damage_source_bounds:
			verify(icon.rect.position.x >= icon.text_end+5,"Source icon follows the number with a clear gap")
		for bounds in hud.damage_bounds:
			verify(Rect2(16,174,1248,430).encloses(bounds),"Floating damage stays clear of header and dock")
			for unit in game.units:
				var head := Rect2(game._unit_center(unit)+Vector2(-26,-102),Vector2(52,46))
				verify(not bounds.intersects(head),"Damage avoids character faces: %s vs %s (unit %d)" % [bounds,head,unit.id])
		verify(game.code_panel.dock.get_global_rect().encloses(game.code_panel.clock.get_global_rect()),"Clock remains beside playback during damage")
	if "--preview" in OS.get_cmdline_user_args(): return
	get_window().size = Vector2i(1920,1080)
	await frame()
	game._update_battle_presentations()
	var toggle: Button = game.code_panel.activity.toggle
	var motion := InputEventMouseMotion.new()
	motion.position = toggle.get_global_rect().get_center()
	motion.global_position = motion.position
	get_viewport().warp_mouse(motion.position)
	get_viewport().push_input(motion,true)
	await get_tree().create_timer(0.8,true,false,true).timeout
	await shot("damage-category-legend")
	motion.position = Vector2(8,180)
	motion.global_position = motion.position
	get_viewport().warp_mouse(motion.position)
	get_viewport().push_input(motion,true)
	game.inspector.close_info()
	for n in hud.damage_numbers:
		var rows: Array = hud.damage_rows(n,true)
		if n.actual > 0:
			verify(rows[0].tint == (hud.HEAL_COLOR if n.effect == "heal" else hud.DAMAGE_COLOR),"Health loss is red and healing is green")
			verify(rows[0].font >= 22,"Floating values keep larger readable type")
		if n.blocked > 0: verify(rows[-1].shield and rows[-1].tint == hud.SHIELD_COLOR,"Absorption stays a separate purple shield row")
	var ages: Array = hud.damage_numbers.map(func(n): return n.age)
	hud._visual_update(0.5)
	verify(ages == hud.damage_numbers.map(func(n): return n.age),"Manual pause freezes damage pop and lifetime")
	hud.damage_numbers.clear()
	var event := {"kind":"impact","effect":"damage","actual":10.0,"blocked":0.0,"actor_id":actor.id,"target_id":foes[0].id,"to":foes[0].position,"damage_source":"attack","special":false}
	hud.consume(event); hud.consume(event)
	verify(hud.damage_numbers.size() == 1 and hud.damage_numbers[0].actual == 20,"Same-source rapid damage can still merge")
	event.is_followup = true
	hud.consume(event)
	verify(hud.damage_numbers.size() == 2,"Followup damage never merges into an untagged ordinary hit")
	for followup in [false,true]:
		event.damage_source = "skill"
		event.special = true
		event.is_followup = followup
		hud.consume(event)
	verify(hud.damage_numbers.size() == 4,"Two categories and their followup flags remain distinct")
	var shield_only := {"actual":0.0,"blocked":10.0,"effect":"damage","source":"skill","special":true,"followup":true,"age":0.2}
	verify(hud.damage_rows(shield_only,true).size() == 1 and hud.damage_rows(shield_only,true)[0].followup,"Fully absorbed followup still shows its tag")
	shield_only.actual = 10.0
	verify(hud.damage_rows(shield_only,true).filter(func(row): return row.followup).size() == 1,"Mixed shield and health loss shows followup only once")
	shield_only.effect = "heal"
	shield_only.blocked = 0.0
	verify(not hud.damage_rows(shield_only,true)[0].followup,"Healing does not acquire an attack followup tag")
	var n: Dictionary = hud.damage_numbers[0]
	var first: int = hud.damage_rows(n,true)[0].font
	n.age = 0.1
	verify(hud.damage_rows(n,true)[0].font == first,"Reduced motion removes size pop")
	game.paused = false
	hud._visual_update(hud.DAMAGE_SECONDS+1)
	verify(hud.damage_numbers.is_empty(),"Damage figures disappear completely after their bounded lifetime")
	game._build_units()
	hud._process(0)
	verify(hud.damage_numbers.is_empty(),"New battle resets damage feedback")
	game.free()
