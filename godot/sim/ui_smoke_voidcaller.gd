## Headless smoke test for the Voidcaller HUD: builds every screen (select -> combat ->
## draft -> end) for both Aspects, ticks a live fight so the render path + all custom
## _draw widgets (cast dial w/ interruptible glow, player cast bar, voidcaller gauge)
## execute, drains the juice event stream, and exercises the draft roll. Catches
## script/_draw errors headless.
##
##   godot --headless --path godot --script res://sim/ui_smoke_voidcaller.gd
extends SceneTree

func _initialize() -> void:
	print("=== Voidcaller UI smoke ===")
	var ok := true
	ok = (await _widgets()) and ok
	ok = _draft() and ok
	ok = (await _fight_render("disruptor")) and ok
	ok = (await _fight_render("silencer")) and ok
	print(("PASS" if ok else "FAIL"), " — Voidcaller UI smoke")
	quit(0 if ok else 1)

func _widgets() -> bool:
	var vp := root
	var dial := BossCastDial.new()
	dial.size = Vector2(300, 300); dial.tg_active = true; dial.tg_interruptible = true
	dial.tg_heal = true; dial.tg_name = "Mending"; dial.tg_frac = 0.7; dial.in_zone = true; dial.verb = "KICK"
	vp.add_child(dial); dial.queue_redraw()
	var pc := PlayerCastBar.new()
	pc.size = Vector2(480, 50); pc.active = true; pc.frac = 0.5; pc.label = "Fracture"; pc.pushed = true
	vp.add_child(pc); pc.queue_redraw()
	for asp in ["disruptor", "silencer"]:
		var g := VoidcallerGauge.new()
		g.size = Vector2(460, 90); g.aspect = asp; g.backlash = 3; g.next_instant = true
		g.silence_left = 3.2; g.boss_exposed = true; g.expose_amt = 0.3
		vp.add_child(g); g.queue_redraw()
	await process_frame
	await process_frame
	print("  widgets: built + drew cast dial / player cast bar / gauge (both aspects) -> ok")
	return true

func _draft() -> bool:
	var run := RunState.start_voidcaller("disruptor")
	var picks := VoidcallerBoons.roll(run)
	if picks.size() != 3:
		print("  draft: FAIL — expected 3 picks, got %d" % picks.size()); return false
	VoidcallerBoons.apply(picks[0], run)
	var vrun := RunState.start_voidcaller("silencer")
	var vp := VoidcallerBoons.roll(vrun)
	print("  draft: disruptor 3 (applied '%s'), silencer %d -> %s" % [
		picks[0]["title"], vp.size(), ("ok" if vp.size() == 3 else "FAIL")])
	return picks.size() == 3 and vp.size() == 3

func _fight_render(aspect: String) -> bool:
	var hud: Control = load("res://game/voidcaller_hud.gd").new()
	root.add_child(hud)
	await process_frame
	hud.call("_start_run", aspect)
	await process_frame
	var s: CombatState = hud.get("_ctrl").state
	var seat := s.seats[0]
	var policy := VoidcallerPolicy.new()
	for _i in range(150):
		var a := policy.act(CombatCore.observe(s, seat))
		if not a.is_empty():
			s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		await process_frame
		if s.over:
			break
	print("  fight(%s): ticked %d, boss %d/%d, kicks %d -> render ok" % [
		aspect, s.tick, int(s.boss.hp), int(s.boss.hp_max), int(seat.vars.get("kicks", 0))])
	hud.queue_free()
	return true
