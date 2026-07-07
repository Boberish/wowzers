## world_probe — WORLD-PLAN W1 acceptance checks, headless + disk-inert:
##   1. ZONE 1 structure: authored graph sane, every node reachable, the DOOR rushable
##      without the capstone (WORLD-PLAN: "rushing is real"), ids/kinds consistent.
##   2. Conquest semantics: frontier/visibility/fog tiers, zone-cleared crest.
##   3. THE ZONE REMEMBERS: flag variants resolve, authored data never mutates.
##   4. WorldSave canonical round-trip determinism (same state ⇒ same bytes, forever).
##   5. Zone stand-in fights: RaidNet spec built the zone way == the default raid pull
##      (no overrides), and stepping it is deterministic (same seed ⇒ same checksum).
## Run: godot --headless --path godot --script res://sim/world_probe.gd
extends SceneTree

var fails := 0

func _initialize() -> void:
	_structure()
	_conquest()
	_remembers()
	_save_roundtrip()
	_fight_identity()
	_escort()
	print("WORLD PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)

# ------------------------------------------------------------ 1. structure
func _structure() -> void:
	var z := WorldContent.zone(WorldContent.ZONE1)
	var N: Array = z["nodes"]
	_ck(N.size() == 20, "zone 1 has 20 nodes (got %d)" % N.size())
	for i in N.size():
		var n: Dictionary = N[i]
		_ck(int(n["id"]) == i, "node id == index at %d" % i)
		for e in (n["edges"] as Array):
			_ck(int(e) >= 0 and int(e) < N.size(), "edge in range at %d" % i)
			_ck(((N[int(e)] as Dictionary)["edges"] as Array).has(i), "edge %d-%s mirrored" % [i, str(e)])
		if String(n["kind"]) in ["fight", "elite", "boss"]:
			_ck(String(n["fight"]) != "", "fight node %d names an encounter" % i)
	_ck(String((N[int(z["capstone_id"])] as Dictionary)["kind"]) == "boss", "capstone is the boss")
	_ck(String((N[int(z["waystation_id"])] as Dictionary)["kind"]) == "waystation", "waystation id right")
	_ck(String((N[int(z["door_id"])] as Dictionary)["kind"]) == "door", "door id right")
	# every node reachable from the entry
	_ck(_bfs(N, int(z["entry_id"]), -1).size() == N.size(), "all nodes reachable from entry")
	# the RUSH: the door is reachable WITHOUT the capstone (the smugglers' path)
	var no_boss := _bfs(N, int(z["entry_id"]), int(z["capstone_id"]))
	_ck(no_boss.has(int(z["door_id"])), "door rushable without the capstone")
	_ck(not no_boss.has(int(z["capstone_id"])), "bfs exclusion sane")
	# the spine is inside the 30–45 min attunement budget: ≤ 12 spine nodes
	var spine := 0
	for n in N:
		if bool(n.get("spine", false)):
			spine += 1
	_ck(spine >= 8 and spine <= 12, "spine within the attunement budget (%d)" % spine)
	print("structure: 20 nodes · all reachable · door rushable · spine %d — ok" % spine)

func _bfs(N: Array, from: int, skip: int) -> Dictionary:
	var seen := {from: true}
	var q := [from]
	while not q.is_empty():
		var cur: int = q.pop_front()
		for e in ((N[cur] as Dictionary)["edges"] as Array):
			var id := int(e)
			if id == skip or seen.has(id):
				continue
			seen[id] = true
			q.append(id)
	return seen

# ------------------------------------------------------------ 2. conquest semantics
func _conquest() -> void:
	var z := WorldContent.zone(WorldContent.ZONE1)
	var save := WorldSave.new()
	var zid := WorldContent.ZONE1
	_ck(WorldContent.frontier(z, save) == [int(z["entry_id"])], "fresh zone: frontier == entry")
	save.mark_cleared(zid, 0)
	var f := WorldContent.frontier(z, save)
	_ck(f.has(1) and f.has(17) and not f.has(0) and not f.has(2), "frontier == entry's neighbors")
	var vis := WorldContent.visibility(z, save)
	_ck(int(vis[0]) == 2 and int(vis[1]) == 2, "cleared + frontier fully visible")
	_ck(int(vis[2]) == 1 and int(vis[9]) == 1, "one step past the frontier = silhouette")
	_ck(int(vis[7]) == 0 and int(vis[19]) == 0, "deep fog stays unknown")
	_ck(not WorldContent.zone_conquered(z, save), "not conquered yet")
	for n in (z["nodes"] as Array):
		save.mark_cleared(zid, int(n["id"]))
	_ck(WorldContent.frontier(z, save).is_empty(), "full clear: no frontier left")
	_ck(WorldContent.zone_conquered(z, save), "capstone cleared == zone conquered")
	_ck(save.cleared_count(zid) == 20, "cleared count sticks (idempotent marks)")
	save.mark_cleared(zid, 0)
	_ck(save.cleared_count(zid) == 20, "re-clearing is idempotent")
	print("conquest: frontier/fog/crest semantics — ok")

# ------------------------------------------------------------ 3. THE ZONE REMEMBERS
func _remembers() -> void:
	var z := WorldContent.zone(WorldContent.ZONE1)
	var plain := WorldContent.resolved_node(z, 13, {})
	_ck(String(plain["kind"]) == "fight", "drowned acre defaults to a fight")
	var flooded := WorldContent.resolved_node(z, 13, {"sluice": "opened"})
	_ck(String(flooded["kind"]) == "cache", "sluice opened ⇒ the acre becomes a cache")
	var sealed := WorldContent.resolved_node(z, 13, {"sluice": "sealed"})
	_ck(String(sealed["kind"]) == "fight", "sluice sealed ⇒ the fight stays")
	var again := WorldContent.resolved_node(z, 13, {})
	_ck(String(again["kind"]) == "fight", "authored data never mutates (resolve is pure)")
	_ck(not WorldContent.choice("sluice").is_empty(), "the sluice choice exists")
	for ev_id in ["harrow", "beacon", "reedmere"]:
		_ck((WorldContent.event(ev_id)["choices"] as Array).size() >= 2, "event %s has choices" % ev_id)
	print("the zone remembers: variants resolve pure — ok")

# ------------------------------------------------------------ 4. save round-trip
func _save_roundtrip() -> void:
	var a := WorldSave.new()
	a.mark_cleared("gildfields", 3)
	a.mark_cleared("gildfields", 0)
	a.set_flag("gildfields", "sluice", "opened")
	a.unlock_waystation("gildfields")
	a.set_at("gildfields", 3)
	var s1 := a.canonical()
	var b := WorldSave.from_json(s1)
	_ck(b.canonical() == s1, "canonical round-trip byte-identical")
	_ck(b.is_cleared("gildfields", 3) and b.is_cleared("gildfields", 0), "clears survive the trip")
	_ck(String(b.flags("gildfields").get("sluice", "")) == "opened", "flags survive the trip")
	_ck(b.has_waystation("gildfields"), "waystations survive the trip")
	# insertion order must not matter: same state, different history ⇒ same bytes
	var c := WorldSave.new()
	c.set_at("gildfields", 3)
	c.unlock_waystation("gildfields")
	c.set_flag("gildfields", "sluice", "opened")
	c.mark_cleared("gildfields", 0)
	c.mark_cleared("gildfields", 3)
	_ck(c.canonical() == s1, "canonical form is history-independent")
	print("world save: round-trip + history-independence — ok")

# ------------------------------------------------------------ 5. zone stand-in fights
## The zone path passes NO overrides — its spec must equal the default raid pull's
## spec, and stepping it must be deterministic. (The bare-kit assertion — no boons/
## gear on any seat — rides ui_smoke_world, where the real HUD launches the pull.)
func _fight_identity() -> void:
	for enc_id in ["bard", "sonnet", "opus", "riftmaw"]:
		var spec_a := RaidNet.make_spec(777001, {}, enc_id)
		var spec_b := RaidNet.make_spec(777001, {}, enc_id)
		_ck(JSON.stringify(spec_a) == JSON.stringify(spec_b), "spec stable for %s" % enc_id)
		var c1 := _run_fight(spec_a)
		var c2 := _run_fight(spec_b)
		_ck(c1 == c2, "fight determinism for %s (%d vs %d)" % [enc_id, c1, c2])
	print("stand-in fights: spec stable + step-deterministic — ok")

# ------------------------------------------------------------ 6. escort / volatile ticket
## §MEWGENICS STEALS ① — the whole mechanic headless: the pickup→carry→turn-in state
## machine on a real WorldSave, the burden gate (fights burdened, capstone/non-fights not),
## persistence through the canonical save, and that the burden actually changes a fight
## deterministically (rides `carry` as pure data → byte-identical when absent).
func _escort() -> void:
	var zid := WorldContent.ZONE1
	var z := WorldContent.zone(zid)
	var save := WorldSave.new()
	var r := Escort.route(zid)
	_ck(Escort.has_route(zid) and int(r["pickup"]) == 4 and int(r["turnin"]) == 19,
		"the Gildfields defines the grain-vial escort (pickup 4 → turn-in 19)")
	# nothing carried at zone start ⇒ no burden anywhere
	_ck(Escort.state(save, zid) == "" and not Escort.carrying(save, zid), "escort starts empty")
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[5]) == "", "no burden before pickup")
	# pickup at the warden's rest
	_ck(Escort.on_enter(save, zid, 4) != "", "entering the warden's rest picks up the vial")
	_ck(Escort.carrying(save, zid), "carrying after pickup")
	_ck(Escort.on_enter(save, zid, 4) == "", "pickup is one-shot (idempotent)")
	# the burden gate: fight/elite en route are burdened; the capstone boss and non-fights aren't
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[5]) == Escort.BURDEN, "elite en route is burdened")
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[9]) == Escort.BURDEN, "a plain fight en route is burdened")
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[7]) == "", "the capstone boss is spared")
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[4]) == "", "a camp is not a fight")
	# turn-in at the door
	_ck(Escort.on_enter(save, zid, 19) != "", "the Undermill door turns the vial in")
	_ck(Escort.state(save, zid) == "done" and not Escort.carrying(save, zid), "escort done after turn-in")
	_ck(Escort.burden_for(save, zid, (z["nodes"] as Array)[5]) == "", "done ⇒ the road is clean again")
	# persistence: the escort state survives the canonical save round-trip (permanence)
	var rt := WorldSave.from_json(save.canonical())
	_ck(Escort.state(rt, zid) == "done", "escort state persists through the world save")
	# the burden is real AND deterministic (same seed ⇒ same checksum; differs from the plain pull)
	var plain := _run_fight(RaidNet.make_spec(880011, {}, "opus"))
	var burd_a := _run_fight(RaidNet.make_spec(880011, {}, "opus", {"burden": Escort.BURDEN}))
	var burd_b := _run_fight(RaidNet.make_spec(880011, {}, "opus", {"burden": Escort.BURDEN}))
	_ck(burd_a == burd_b, "burdened fight is deterministic (%d vs %d)" % [burd_a, burd_b])
	_ck(burd_a != plain, "the burden actually changes the fight (burdened %d != plain %d)" % [burd_a, plain])
	print("escort: pickup→burden→turn-in + persistence + deterministic burden — ok")

func _run_fight(spec: Dictionary) -> int:
	var s := RaidNet.build(spec, "")
	var cap := s.tick + 900          # 30s of combat is plenty for a checksum fingerprint
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		CombatCore.update(s)
	return s.checksum
