## Headless end-to-end check for FERMATA's hold-release input path: enqueue coil/release
## actions exactly as raid_hud does (via the tick-stamped input queue → perform → on_action)
## and assert the verb behaves — a sharp release deals damage, an early release UNRAVELS
## (no damage), and a bare release with no coil is a no-op. Proves the fix that made the raid
## blade actually play as Fermata instead of falling back to the instant Tempo strike.
##   godot --headless --path godot --script res://sim/fermata_input_check.gd
extends SceneTree

func _initialize() -> void:
	print("=== FERMATA input path check ===")
	var enc := RaidContent.make_mistral()
	# human = blade, blade aspect = fermata
	var s := RaidContent.make_state(1, enc, {"blade": "fermata"}, "blade", {})
	var blade: Seat = s.seats[1]
	var kit := blade.kit as TwinfangKit
	print("blade aspect: %s   (expect fermata)" % kit.aspect)
	print("blade loadout: %s" % str(kit.cfg.loadout(kit.aspect)))

	# drop the AI policy so ONLY our scripted inputs drive the blade (isolate the verb).
	blade.policy = null

	# --- 1) a SHARP release deals damage ---
	var hp0 := s.boss.hp
	_enq(s, blade, {"type": "ability", "id": "coil"})
	_step(s, 1)
	print("after coil: coiling=%s" % str(blade.vars.get("coiling", false)))
	_step(s, 24)                                   # hold ~0.8s — well past the 0.35s sharpen floor
	print("held ~0.8s: sharp=%s" % str(blade.vars.get("sharp", false)))
	_enq(s, blade, {"type": "ability", "id": "release"})
	_step(s, 2)
	var dealt := hp0 - s.boss.hp
	print("SHARP release -> boss dmg = %.0f   (expect > 0)  %s" % [dealt, "PASS" if dealt > 0.0 else "FAIL"])

	# --- 2) an EARLY release UNRAVELS (no strike) ---
	var hp1 := s.boss.hp
	var unr0 := int(s.diag.get("unravel", 0))
	_enq(s, blade, {"type": "ability", "id": "coil"})
	_step(s, 3)                                    # hold only ~0.1s — below the floor
	_enq(s, blade, {"type": "ability", "id": "release"})
	_step(s, 2)
	var dealt2 := hp1 - s.boss.hp
	var unr1 := int(s.diag.get("unravel", 0))
	print("EARLY release -> boss dmg = %.0f (expect 0), unravels +%d (expect +1)  %s" % [
		dealt2, unr1 - unr0, "PASS" if (dealt2 == 0.0 and unr1 > unr0) else "FAIL"])

	# --- 3) a bare release with NO coil is a clean no-op ---
	# clear the unravel stagger first
	_step(s, 16)
	var hp2 := s.boss.hp
	_enq(s, blade, {"type": "ability", "id": "release"})
	_step(s, 2)
	var dealt3 := hp2 - s.boss.hp
	print("bare release (no coil) -> boss dmg = %.0f (expect 0)  %s" % [dealt3, "PASS" if dealt3 == 0.0 else "FAIL"])

	# --- 4) THE ROAMING WINDOW: the green relocates after every resolve ---
	# Strike a few beats and collect the live window centre each time — the tester's core read
	# (no autopilot rhythm; the next window lands somewhere new).
	var centers: Array = []
	for _i in 4:
		var obs := CombatCore.observe(s, blade)
		centers.append((float(obs["perfect_lo"]) + float(obs["perfect_hi"])) * 0.5)
		_enq(s, blade, {"type": "ability", "id": "coil"})
		_step(s, 24)                                # sharpen well past the floor
		_enq(s, blade, {"type": "ability", "id": "release"})
		_step(s, 2)
	var distinct := {}
	for c in centers:
		distinct[snappedf(float(c), 0.01)] = true
	print("window centres over 4 beats (ticks): %s  -> %d distinct (expect >= 3)  %s" % [
		str(centers), distinct.size(), "PASS" if distinct.size() >= 3 else "FAIL"])

	# --- 5) THE SNAP: hold PAST the lip and the note breaks (auto-miss + Flow crash) ---
	_step(s, 16)                                   # clear any lock
	blade.vars["flow"] = 3                          # so we can see the crash
	var snap0 := int(s.diag.get("snap", 0))
	var hpS := s.boss.hp
	_enq(s, blade, {"type": "ability", "id": "coil"})
	_step(s, 62)                                   # hold ~2s — well past any lip (ruler is 1.8s)
	var snapped := int(s.diag.get("snap", 0)) > snap0
	var dealtS := hpS - s.boss.hp
	var crashed := int(blade.vars.get("flow", 9)) == 0 and not bool(blade.vars.get("coiling", true))
	print("held past the lip -> snap +%d (expect +1), dmg %.0f (expect 0), Flow crashed+idle %s  %s" % [
		int(s.diag.get("snap", 0)) - snap0, dealtS, str(crashed),
		"PASS" if (snapped and dealtS == 0.0 and crashed) else "FAIL"])

	quit()

func _enq(s: CombatState, seat: Seat, action: Dictionary) -> void:
	s.enqueue(s.tick + 1, seat, action)

func _step(s: CombatState, n: int) -> void:
	for _i in n:
		CombatCore.update(s)
		s.events.clear()
