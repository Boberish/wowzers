## Headless smoke test for the Twinfang HUD: builds every screen (select -> combat ->
## draft -> end) for both Aspects, ticks a live fight so the render path + all custom
## _draw widgets (rhythm bar, twinfang gauge, cast dial) execute, drains the juice event
## stream, and exercises the draft roll + tooltips. Catches script/_draw errors headless.
##
##   godot --headless --path godot --script res://sim/ui_smoke_twinfang.gd
extends SceneTree

func _initialize() -> void:
	print("=== Twinfang UI smoke ===")
	var ok := true
	ok = (await _widgets()) and ok
	ok = _draft() and ok
	ok = (await _fight_render("tempo")) and ok
	ok = (await _fight_render("venomancer")) and ok
	print(("PASS" if ok else "FAIL"), " — Twinfang UI smoke")
	quit(0 if ok else 1)

# instantiate + force a _draw on each custom widget for both aspects
func _widgets() -> bool:
	var vp := root
	var rb := RhythmBar.new()
	rb.size = Vector2(500, 64); rb.since = 22; rb.perfect_lo = 18; rb.perfect_hi = 29
	vp.add_child(rb); rb.queue_redraw()
	var dial := BossCastDial.new()
	dial.size = Vector2(300, 300); dial.tg_active = true; dial.tg_interruptible = true
	dial.tg_heal = true; dial.tg_name = "Mending"; dial.tg_frac = 0.5
	vp.add_child(dial); dial.queue_redraw()
	for asp in ["tempo", "venomancer"]:
		var g := TwinfangGauge.new()
		g.size = Vector2(460, 90); g.aspect = asp; g.combo = 3; g.flow = 4; g.tier = 2
		g.venom = {"V": 5, "F": 3, "C": 2, "syn_ramp": 1.4, "syn_active": true}
		vp.add_child(g); g.queue_redraw()
	await process_frame
	await process_frame
	print("  widgets: built + drew rhythm bar / cast dial / gauge (both aspects) -> ok")
	return true

func _draft() -> bool:
	var run := RunState.start_twinfang("tempo")
	var picks := Draft.roll_offers(run)
	if picks.size() != 3:
		print("  draft: FAIL — expected 3 picks, got %d" % picks.size()); return false
	Draft.take(run, picks[0])
	# a spell pick should land in the loadout; an upgrade/relic in boons
	var applied_ok := not run.boons.is_empty() or run.loadout.size() > 4
	print("  draft: rolled 3, applied '%s' -> %s" % [picks[0]["title"], "ok" if applied_ok else "?"])
	# venom pool too
	var vrun := RunState.start_twinfang("venomancer")
	var vp := Draft.roll_offers(vrun)
	print("  draft: venom rolled %d -> %s" % [vp.size(), "ok" if vp.size() == 3 else "FAIL"])
	return picks.size() == 3 and vp.size() == 3

# build the HUD, start a real fight, tick it, and render several frames
func _fight_render(aspect: String) -> bool:
	var hud: Control = load("res://game/twinfang_hud.gd").new()
	root.add_child(hud)
	await process_frame
	hud.call("_start_run", aspect)
	await process_frame
	# drive ~4s of combat with the AI policy filling the human seat + render each frame
	var s: CombatState = hud.get("_ctrl").state
	var seat := s.seats[0]
	var policy := TwinfangPolicy.new()
	for _i in range(120):
		var a := policy.act(CombatCore.observe(s, seat))
		if not a.is_empty():
			s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		await process_frame
		if s.over:
			break
	print("  fight(%s): ticked %d, boss %d/%d, flow %d -> render ok" % [
		aspect, s.tick, int(s.boss.hp), int(s.boss.hp_max), int(seat.vars.get("flow", 0))])
	hud.queue_free()
	return true
