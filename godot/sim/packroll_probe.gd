## packroll_probe — PACK QUOTAS v2 (the Topology pack roll, THE DESCENT REFIT), headless:
##   · entry + Seal slots NEVER roll a pack (authored shapes stand);
##   · a mid slot's roll is DETERMINISTIC per (map seed, node id) — same twice;
##   · the distribution over many nodes ≈ the 30/45/25 quota (±10pp);
##   · every walk-in is a takeover-palette Forge LIGHTWEIGHT whose tier rides the
##     ring (Ring 3 → t1 · Ring 0 → t3) — the full-HP bard/sonnet v1 wart stays closed;
##   · a rolled chain always captains with the node's own encounter (dies last —
##     oaths + the drop ceremony stay anchored to the kill that matters).
## Run: godot --headless --path godot --script res://sim/packroll_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0

func _initialize() -> void:
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _process(_d: float) -> bool:
	step += 1
	if step < 2:
		return false
	hud._d.floor_i = 0                     # RING 3 — fillers must come out t1
	hud._d.map = RunMap.generate(90210, 8, MapContent.raid_event_ids(), {}, 0, 0, 8)
	hud._d.fights = RaidContent.floor_fights(3)
	var enc: EncounterRes = hud._d.fights[2]
	# entry + Seal slots never roll
	hud._d.node = 3
	_ck((hud._roll_map_pack(0, hud._d.fights[0]) as Array).is_empty(), "entry never rolls")
	_ck((hud._roll_map_pack(hud._d.fights.size() - 1,
		hud._d.fights[hud._d.fights.size() - 1]) as Array).is_empty(), "the Seal never rolls")
	# determinism per (seed, node)
	var a: Array = hud._roll_map_pack(2, enc)
	var b: Array = hud._roll_map_pack(2, enc)
	_ck(str(a) == str(b), "roll deterministic per (map seed, node)")
	# distribution + filler/captain rules across many synthetic nodes
	var solo := 0
	var duo := 0
	var trio := 0
	for nid in range(400):
		hud._d.node = nid
		var p: Array = hud._roll_map_pack(2, enc)
		if p.is_empty():
			solo += 1
		else:
			_ck(String(p[p.size() - 1]) == String(enc.id), "node enc captains (dies last)")
			for wi in p.size() - 1:
				_ck(String(p[wi]).begins_with("forge:takeover:"),
					"walk-in is a takeover Forge body (got %s)" % String(p[wi]))
				_ck(":1:" in String(p[wi]), "Ring 3 walk-in is t1 (got %s)" % String(p[wi]))
			if p.size() == 2:
				duo += 1
			elif p.size() == 3:
				trio += 1
			else:
				_ck(false, "pack size sane (%d)" % p.size())
	var fs := 100.0 * solo / 400.0
	var fd := 100.0 * duo / 400.0
	var ft := 100.0 * trio / 400.0
	_ck(absf(fs - 30.0) < 10.0, "solo share ≈30%% (got %.0f%%)" % fs)
	_ck(absf(fd - 45.0) < 10.0, "duo share ≈45%% (got %.0f%%)" % fd)
	_ck(absf(ft - 25.0) < 10.0, "trio share ≈25%% (got %.0f%%)" % ft)
	print("quota over 400 nodes: solo %.0f%% · duo %.0f%% · trio %.0f%%" % [fs, fd, ft])
	# tier rides the ring: the ROOT floor's walk-ins come out t3
	hud._d.floor_i = 2
	hud._d.node = _first_packed_node(enc)
	var pr: Array = hud._roll_map_pack(2, enc)
	_ck(":3:" in String(pr[0]), "Ring 0 walk-in is t3 (got %s)" % String(pr[0]))
	hud._d.floor_i = 0
	# a rolled pack builds a real state whose LAST member is the captain — and the
	# forge walk-in regenerates from its id alone through the shared spec path
	hud._d.node = _first_packed_node(enc)
	var pk: Array = hud._roll_map_pack(2, enc)
	var spec := RaidNet.make_spec(1234, {}, String(pk[0]), {}, {}, pk)
	var s := RaidNet.build(spec, "")
	_ck(s.pack.size() == pk.size(), "state carries the rolled chain")
	_ck(String((s.pack[s.pack.size() - 1] as EncounterRes).id) == String(enc.id),
		"built chain captains with the node enc")
	_ck(String((s.pack[0] as EncounterRes).id) == String(pk[0]),
		"forge walk-in regenerated from its id (the id is the recipe)")
	print("PACKROLL PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)
	return true

func _first_packed_node(enc: EncounterRes) -> int:
	for nid in range(200):
		hud._d.node = nid
		if not (hud._roll_map_pack(2, enc) as Array).is_empty():
			return nid
	return 0

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
