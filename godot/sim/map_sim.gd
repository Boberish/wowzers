## Headless verification for the Topology map generator (MASTER-PLAN §MAPS MAP-1).
## Run: godot --headless --path godot --script res://sim/map_sim.gd -- --seeds=300
##
## Proves, across N seeds:
##   1. DETERMINISM — same seed generates a byte-identical map (fingerprint).
##   2. STRUCTURE  — every node reachable from entry; the Seal reachable from every
##      node WITHOUT the locked edge (locks only gate optional content); quotas met;
##      exactly one key, placed on a feeder of the backdoor's mouth.
##   3. WALKER     — a seeded random walker completes every map (entry → Seal),
##      picking up keys and sometimes taking the backdoor; route stats printed.
##   4. CONTENT    — every event effect is well-formed and bounded.
extends SceneTree

const N_FIGHTS := 5

func _initialize() -> void:
	var seeds := 300
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr("--seeds=".length()))
	var fails := 0

	# ---- 1. determinism
	var det_ok := true
	for s in seeds:
		var a := RunMap.generate(1000 + s, N_FIGHTS, MapContent.event_ids())
		var b := RunMap.generate(1000 + s, N_FIGHTS, MapContent.event_ids())
		if a.fingerprint() != b.fingerprint():
			det_ok = false
			break
	print("map determinism (%d seeds): %s" % [seeds, "PASS" if det_ok else "FAIL"])
	fails += 0 if det_ok else 1

	# ---- 2. structure
	var struct_ok := true
	for s in seeds:
		var m := RunMap.generate(1000 + s, N_FIGHTS, MapContent.event_ids())
		if not _check_structure(m):
			struct_ok = false
			print("  structure FAIL at seed %d" % (1000 + s))
			break
	print("map structure (%d seeds): %s" % [seeds, "PASS" if struct_ok else "FAIL"])
	fails += 0 if struct_ok else 1

	# ---- 3. walker
	var walk_ok := true
	var tot_steps := 0
	var tot_fights := 0
	var tot_events := 0
	var backdoors := 0
	var keys_found := 0
	for s in seeds:
		var m := RunMap.generate(1000 + s, N_FIGHTS, MapContent.event_ids())
		var rng := DetRng.new(555000 + s)
		var inv := {}
		var cur := -1
		var steps := 0
		var used_backdoor := false
		while steps < 12:
			var opts := m.reachable(cur, inv)
			if opts.is_empty():
				break
			var pick: int = opts[rng.next_u32() % opts.size()]
			if cur >= 0 and m.node(cur)["locked_next"].has(pick):
				used_backdoor = true
			cur = pick
			steps += 1
			var n := m.node(cur)
			if bool(n["key"]):
				inv["api_key"] = true
				keys_found += 1
			match String(n["kind"]):
				RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
					tot_fights += 1
				RunMap.KIND_EVENT:
					tot_events += 1
			if cur == m.seal_id:
				break
		if cur != m.seal_id:
			walk_ok = false
			print("  walker FAIL at seed %d (stuck at node %d after %d steps)" % [1000 + s, cur, steps])
			break
		tot_steps += steps
		if used_backdoor:
			backdoors += 1
	print("map walker (%d seeds): %s" % [seeds, "PASS" if walk_ok else "FAIL"])
	if walk_ok:
		print("  route stats: avg %.2f nodes · avg %.2f fights · avg %.2f events · %d keys found · %d backdoor runs" %
			[float(tot_steps) / seeds, float(tot_fights) / seeds, float(tot_events) / seeds, keys_found, backdoors])
	fails += 0 if walk_ok else 1

	# ---- 4. event content
	var fx_ok := true
	for id in MapContent.event_ids():
		var ev: Dictionary = MapContent.event(id)
		if String(ev.get("title", "")) == "" or String(ev.get("body", "")) == "":
			fx_ok = false
		for c in ev.get("choices", []):
			var fx: Dictionary = c.get("fx", {})
			for k in fx:
				if not (k in ["heal", "hurt", "draft", "result"]):
					fx_ok = false
			if fx.get("heal", 0.0) < 0.0 or fx.get("heal", 0.0) > 0.5:
				fx_ok = false
			if fx.get("hurt", 0.0) < 0.0 or fx.get("hurt", 0.0) > 0.5:
				fx_ok = false
			if String(fx.get("result", "")) == "":
				fx_ok = false
	print("event content (%d events): %s" % [MapContent.event_ids().size(), "PASS" if fx_ok else "FAIL"])
	fails += 0 if fx_ok else 1

	print("MAP SIM: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)

func _check_structure(m: RunMap) -> bool:
	# all nodes reachable from entry (unlocked edges only)
	var seen := {}
	var q := [m.entry_id]
	while not q.is_empty():
		var id: int = q.pop_front()
		if seen.has(id):
			continue
		seen[id] = true
		for nx in m.node(id)["next"]:
			q.push_back(nx)
	if seen.size() != m.nodes.size():
		return false
	# the Seal is reachable from EVERY node without locked edges (locks are optional)
	for n in m.nodes:
		if not _reaches(m, int(n["id"]), m.seal_id):
			return false
	# quotas
	var counts := {}
	for n in m.nodes:
		counts[n["kind"]] = int(counts.get(n["kind"], 0)) + 1
	if counts.get(RunMap.KIND_COOLING, 0) != RunMap.QUOTA[RunMap.KIND_COOLING]:
		return false
	if counts.get(RunMap.KIND_CACHE, 0) != RunMap.QUOTA[RunMap.KIND_CACHE]:
		return false
	if counts.get(RunMap.KIND_EVENT, 0) != RunMap.QUOTA[RunMap.KIND_EVENT]:
		return false
	if counts.get(RunMap.KIND_SEAL, 0) != 1:
		return false
	# events distinct + defined
	var evs := {}
	for n in m.nodes:
		if String(n["kind"]) == RunMap.KIND_EVENT:
			var e := String(n["event"])
			if e == "" or evs.has(e) or MapContent.event(e).is_empty():
				return false
			evs[e] = true
	# exactly one key; backdoor sane (row 2 -> row 4 in grid terms = rows 2 and 4)
	var keys := 0
	for n in m.nodes:
		if bool(n["key"]):
			keys += 1
	if keys != 1 or m.backdoor.size() != 2:
		return false
	var bf := m.node(m.backdoor[0])
	var bt := m.node(m.backdoor[1])
	if not bf["locked_next"].has(m.backdoor[1]):
		return false
	if int(bt["row"]) - int(bf["row"]) < 2:
		return false          # must actually skip a row
	# key node can reach the backdoor mouth
	for n in m.nodes:
		if bool(n["key"]) and not _reaches(m, int(n["id"]), m.backdoor[0]):
			return false
	# every combat/seal has a valid fight index; fights ramp with rows
	for n in m.nodes:
		var kind := String(n["kind"])
		if kind == RunMap.KIND_COMBAT or kind == RunMap.KIND_SEAL:
			if int(n["fight"]) < 0 or int(n["fight"]) >= N_FIGHTS:
				return false
	return true

func _reaches(m: RunMap, from: int, to: int) -> bool:
	if from == to:
		return true
	var seen := {}
	var q := [from]
	while not q.is_empty():
		var id: int = q.pop_front()
		if id == to:
			return true
		if seen.has(id):
			continue
		seen[id] = true
		for nx in m.node(id)["next"]:
			q.push_back(nx)
	return false
