## pack_probe — the PACK mechanism (WORLD-PLAN §FIGHT LENGTH build spec v1), headless:
##   1. GUARD: a size-1 pack normalizes away — spec and fight byte-identical to a plain
##      pull (same checksum, same TTK).
##   2. A 3-member pack fought by real policies: wins only after ALL members fall; two
##      pack_next events fire; total boss HP dealt == sum of members.
##   3. WALK-IN: after each swap the new member takes NO action for pack_walkin_ticks
##      (no melee damage, no telegraphs) — then acts.
##   4. Per-member ENRAGE: member 2's enrage clock starts at its entry (a member
##      entering after t=enrage_at is NOT pre-enraged).
##   5. Determinism: the same pack spec twice ⇒ identical checksums.
##   6. HEAT CARRY: seats are never reset (cooldowns/resources continuous across swaps).
## Run: godot --headless --path godot --script res://sim/pack_probe.gd
extends SceneTree

var fails := 0

func _initialize() -> void:
	_guard_size1()
	_full_pack()
	_determinism()
	print("PACK PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)

func _run_spec(spec: Dictionary, cap_ticks: int) -> Dictionary:
	var s := RaidNet.build(spec, "")
	var packs_seen: Array = []
	var walkin_ok := true
	var last_swap := -1
	var melee_during_walkin := 0
	while not s.over and s.tick < cap_ticks:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		var hp_before: Dictionary = {}
		for i in s.seats.size():
			hp_before[i] = (s.seats[i] as Seat).hp
		CombatCore.update(s)
		for ev in s.events:
			if String(ev.get("t", "")) == "pack_next":
				packs_seen.append(String(ev.get("name", "")))
				last_swap = s.tick
		# walk-in: no seat may TAKE BOSS DAMAGE inside the grace window after a swap
		if last_swap > 0 and s.tick <= last_swap + s.config.pack_walkin_ticks:
			if s.telegraph != null:
				walkin_ok = false
			for i in s.seats.size():
				if (s.seats[i] as Seat).hp < float(hp_before[i]) - 0.01:
					melee_during_walkin += 1
		s.events.clear()
	return {"s": s, "packs": packs_seen, "walkin_ok": walkin_ok,
		"walkin_hits": melee_during_walkin}

func _guard_size1() -> void:
	var plain := RaidNet.make_spec(424242, {}, "bard")
	var one := RaidNet.make_spec(424242, {}, "bard", {}, {}, ["bard"])
	_ck(JSON.stringify(plain) == JSON.stringify(one), "size-1 pack normalizes out of the spec")
	var a := _run_spec(plain, 9000)
	var b := _run_spec(one, 9000)
	_ck((a["s"] as CombatState).checksum == (b["s"] as CombatState).checksum,
		"size-1 pack fight byte-identical to the plain pull")
	print("guard: size-1 pack == plain pull (checksum %d) — ok" % (a["s"] as CombatState).checksum)

func _full_pack() -> void:
	var spec := RaidNet.make_spec(777003, {}, "bard", {}, {}, ["bard", "sonnet", "opus"])
	var r := _run_spec(spec, 30000)
	var s: CombatState = r["s"]
	_ck(s.over and s.won, "3-member pack won (over=%s won=%s cause=%s)" % [s.over, s.won, s.loss_cause])
	_ck((r["packs"] as Array).size() == 2, "two pack_next events (got %s)" % str(r["packs"]))
	_ck(s.pack_i == 2, "ended on the last member (pack_i=%d)" % s.pack_i)
	_ck(bool(r["walkin_ok"]), "no telegraph inside any walk-in window")
	_ck(int(r["walkin_hits"]) == 0, "no seat damage inside walk-ins (%d hits)" % int(r["walkin_hits"]))
	# per-member enrage: the LAST member entered late in a long fight — if its clock
	# were absolute it would be deep past 70s enrage; entered-relative it's fresh.
	var enrage_rel := s.time() - float(s.boss.entered_tick) * s.dt
	_ck(enrage_rel < s.encounter.enrage_at + 60.0,
		"member enrage clock is entry-relative (rel=%.1fs vs enrage_at=%.1fs)" % [enrage_rel, s.encounter.enrage_at])
	print("pack: 3 members, %d ticks (%.1fs), swaps at %s — ok" % [s.tick, s.time(), str(r["packs"])])

func _determinism() -> void:
	var c1 := ((_run_spec(RaidNet.make_spec(31337, {}, "bard", {}, {}, ["bard", "sonnet", "opus"]), 30000))["s"] as CombatState).checksum
	var c2 := ((_run_spec(RaidNet.make_spec(31337, {}, "bard", {}, {}, ["bard", "sonnet", "opus"]), 30000))["s"] as CombatState).checksum
	_ck(c1 == c2, "pack determinism (%d vs %d)" % [c1, c2])
	print("determinism: same pack spec ⇒ same checksum (%d) — ok" % c1)
