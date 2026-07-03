## Headless sim for the Topology RAID floor (MAP-3a — see MASTER-PLAN §MAPS):
## generates "RING 3: THE SHALLOW STACK" maps for the raid fight list
## (Vorathek gate → skirmishes → MISTRAL-7B), proves generation + full-run
## determinism, then WALKS whole runs with the AI raid at three skill tiers —
## per-seat integrity carried between nodes, events applied, dead raiders
## rebooting at 35% after won fights. Prints clear rates + attrition.
## Every map carries ONE personal GATE exam (Tier 1, MASTER-PLAN §GAME SHAPE):
## the walker fights it with `--gateseat=` (default tank) — its class's solo exam,
## carried integrity in, and a LOST gate wounds that seat instead of ending the run.
##
##   godot --headless --path godot --script res://sim/raid_map_sim.gd -- --seeds=60 [--gateseat=blade]
extends SceneTree

const FIGHT_CAP_SEC := 240.0
const REBOOT_FRAC := 0.35
const GATE_QUOTA := {RunMap.KIND_GATE: 1}
const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]

var _fights: Array = []
var _shard_req: int = 0       ## credential-shard gate for the current floor (MAP-3c ROOT)
var _gate_seat := "tank"

func _initialize() -> void:
	var seeds := int(_arg("seeds", "60"))
	_gate_seat = _arg("gateseat", "tank")
	if not RaidNet.SEAT_KEYS.has(_gate_seat):
		_gate_seat = "tank"
	print("=== Project Rift — raid map sim (Realm 1: the RING descent, MAP-3c) ===")
	print("gate exam seat: %s (%s)" % [_gate_seat, String(GateContent.exam(_gate_seat)["boss"])])
	# Walk EACH floor of the campaign (Ring 3 MISTRAL → Ring 2 GEMINI → Ring 0 MYTHOS):
	# the Seal escalates per ring, so clear% should fall as we descend. Every floor
	# also carries one personal GATE exam (Tier 1) and the ROOT floor a shard gate.
	for fl in RaidContent.FLOORS:
		_fights = RaidContent.floor_fights(int(fl["ring"]))
		_shard_req = int(fl["shard_req"])
		var seal_name := String((_fights[_fights.size() - 1] as EncounterRes).name)
		print("")
		print("######## %s  →  Seal: %s ########" % [String(fl["title"]), seal_name])
		print("fights: %s" % ", ".join(_fights.map(func(e): return String(e.name))))
		_prove_determinism()
		print("skill    clear%%   avg fights  avg integrity(end)  gates(won/fought)  losses at")
		print("---------------------------------------------------------------------------------")
		for sk in SKILLS:
			var cleared := 0
			var fight_sum := 0
			var integ_sum := 0.0
			var losses := {}
			var gates := 0
			var gate_wins := 0
			for seed in range(1, seeds + 1):
				var r := _walk(seed, sk)
				if r["cleared"]:
					cleared += 1
					integ_sum += float(r["integrity"])
				else:
					var k := String(r["loss_at"])
					losses[k] = int(losses.get(k, 0)) + 1
				fight_sum += int(r["fights"])
				gates += int(r["gates"])
				gate_wins += int(r["gate_wins"])
			var n := float(seeds)
			print("%-7s  %5.1f%%      %5.2f            %5.2f            %d/%d          %s" % [
				sk["label"], 100.0 * cleared / n, fight_sum / n,
				(integ_sum / maxf(1.0, float(cleared))), gate_wins, gates, _fmt(losses)])
	quit()

## Same seed twice ⇒ identical map fingerprint AND identical full-run trace
## (visited nodes + every fight checksum) — the co-op/daily-seed guarantee.
func _prove_determinism() -> void:
	var fp1 := RunMap.generate(1, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req).fingerprint()
	var fp2 := RunMap.generate(1, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req).fingerprint()
	var fp3 := RunMap.generate(2, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req).fingerprint()
	print("map determinism: seed1==seed1 -> %s · seed1 vs seed2 -> %s" % [
		("PASS" if fp1 == fp2 else "FAIL"),
		("differ (good)" if fp1 != fp3 else "IDENTICAL (suspect!)")])
	var sk: Dictionary = SKILLS[0]
	var a := _walk(1, sk)
	var b := _walk(1, sk)
	print("run determinism: %s  (trace %s, cleared=%s, fights=%d)" % [
		("PASS" if a["trace"] == b["trace"] else "FAIL"),
		String(a["trace"]).left(46) + "…", str(a["cleared"]), a["fights"]])
	# structure: every combat/seal node's fight index is valid; the Seal is the boss;
	# exactly ONE personal gate per map (the Tier-1 quota)
	var ok := true
	var gates_ok := true
	for seed in range(1, 40):
		var m := RunMap.generate(seed, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req)
		var n_gates := 0
		for nd in m.nodes:
			var fi := int(nd["fight"])
			if String(nd["kind"]) == RunMap.KIND_SEAL and fi != _fights.size() - 1:
				ok = false
			if fi >= 0 and (fi < 0 or fi >= _fights.size()):
				ok = false
			if String(nd["kind"]) == RunMap.KIND_GATE:
				n_gates += 1
				if fi != -1:
					ok = false           # a gate's exam resolves by SEAT, not fight index
		if n_gates != 1:
			gates_ok = false
	print("structure (40 maps): %s (seal = %s everywhere, fight indices in range) · one gate/map: %s" % [
		("PASS" if ok else "FAIL"), String((_fights[_fights.size() - 1] as EncounterRes).name),
		("PASS" if gates_ok else "FAIL")])
	_prove_gates()
	_prove_shard_gate(60)
	_prove_carry(50)

## Every seat's personal exam builds and replays deterministically (same seed ⇒
## same checksum), and a LOST gate wounds the seat without ending the walk.
func _prove_gates() -> void:
	var parts: Array = []
	var all_ok := true
	for key in RaidNet.SEAT_KEYS:
		var c1 := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0}
		var c2 := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0}
		var r1 := _gate_fight(4242, key, c1, SKILLS[1])
		var r2 := _gate_fight(4242, key, c2, SKILLS[1])
		var same: bool = int(r1["checksum"]) == int(r2["checksum"]) and r1["won"] == r2["won"]
		all_ok = all_ok and same
		parts.append("%s=%s%s" % [key, ("ok" if same else "DIVERGED"), ("W" if r1["won"] else "L")])
	print("gate exams (4 seats, det ×2): %s  (%s)" % [
		("PASS" if all_ok else "FAIL"), " ".join(parts)])

## Completability under the credential-shard gate (MAP-3c ROOT): BFS over
## (from_node, shards_collected) states via reachable(); the Seal must be reachable
## on EVERY seed and EVERY route — a gate that could strand you shard-short is a bug.
func _prove_shard_gate(seeds: int) -> void:
	if _shard_req <= 0:
		return
	var ok := true
	for seed in range(1, seeds + 1):
		var m := RunMap.generate(seed, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req)
		var seen := {}
		var stack: Array = [[-1, 0]]                 # [from_id, shards] — start outside the map
		var reached_seal := false
		var dead_end := false
		while not stack.is_empty():
			var st: Array = stack.pop_back()
			var reach: Array = m.reachable(int(st[0]), {"shards": int(st[1]), "api_key": true})
			if reach.is_empty() and int(st[0]) != m.seal_id:
				dead_end = true                      # a route with no way forward (not at the Seal)
			for nid in reach:
				if nid == m.seal_id:
					reached_seal = true
					continue
				var s2: int = int(st[1]) + (1 if bool(m.node(nid).get("shard", false)) else 0)
				var k := "%d:%d" % [nid, s2]
				if not seen.has(k):
					seen[k] = true
					stack.append([nid, s2])
		if not reached_seal or dead_end:
			ok = false
	print("shard gate (%d maps, req %d): %s — Seal reachable, no shard-short dead-ends" % [
		seeds, _shard_req, ("PASS" if ok else "FAIL")])

## The attrition mechanism must be REAL even where Ring 3 is too shallow to show
## it. HP/mana deficits alone are healed away (measured: no effect) — the carry
## that BITES is the CORRUPTED SECTOR wound (a max-HP cut no heal can fix,
## stacking with each death-reboot, repaired only at a Cooling Station). Probe:
## the gate fight, sloppy party, full vs twice-rebooted tank+healer.
func _prove_carry(seeds: int) -> void:
	var sk: Dictionary = SKILLS[2]
	var wins_full := 0
	var wins_wounded := 0
	for seed in range(1, seeds + 1):
		var full := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0}
		var wounded := {"fracs": [0.55, 1.0, 1.0, 0.55], "wounds": [0.4, 0.0, 0.0, 0.4], "mana": 0.25}
		var seal_i := _fights.size() - 1
		if bool(_fight(seed * 977 + 3, seal_i, full, sk)["won"]):
			wins_full += 1
		if bool(_fight(seed * 977 + 3, seal_i, wounded, sk)["won"]):
			wins_wounded += 1
	print("carry probe (Seal fight, sloppy, %d seeds): full %.1f%%  vs  corrupted tank+healer (-40%% max HP, 25%% mana) %.1f%%" % [
		seeds, 100.0 * wins_full / seeds, 100.0 * wins_wounded / seeds])
	print("  -> the wound must cost a visible chunk of win rate, or the map carries nothing")

## One full run: random route (its own DetRng — never the combat stream).
## `carry` = {fracs: per-seat integrity, mana: the healer's fuel gauge} — mirrors
## the HUD's persistence exactly.
func _walk(seed: int, sk: Dictionary) -> Dictionary:
	var map := RunMap.generate(seed, _fights.size(), MapContent.event_ids(), GATE_QUOTA, _shard_req)
	var route := DetRng.new(seed * 7919 + 17)
	var carry := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0}
	var inv := {}
	var pos := -1
	var fights := 0
	var gates := 0
	var gate_wins := 0
	var trace: Array = []
	for hop in 32:
		var choices: Array = map.reachable(pos, inv)
		if choices.is_empty():
			break
		pos = choices[route.next_u32() % choices.size()]
		trace.append(pos)
		var n: Dictionary = map.node(pos)
		if bool(n["key"]):
			inv["api_key"] = true
		if bool(n.get("shard", false)):
			inv["shards"] = int(inv.get("shards", 0)) + 1
		match String(n["kind"]):
			RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
				fights += 1
				var res := _fight(seed * 131 + pos, int(n["fight"]), carry, sk)
				trace.append(int(res["checksum"]))
				if not bool(res["won"]):
					return {"cleared": false, "fights": fights, "gates": gates, "gate_wins": gate_wins,
						"integrity": _avg(carry["fracs"]),
						"loss_at": String((_fights[int(n["fight"])] as EncounterRes).id),
						"trace": str(trace)}
				if String(n["kind"]) == RunMap.KIND_SEAL:
					return {"cleared": true, "fights": fights, "gates": gates, "gate_wins": gate_wins,
						"integrity": _avg(carry["fracs"]), "loss_at": "", "trace": str(trace)}
			RunMap.KIND_GATE:
				# the personal exam: one seat fights alone; a LOSS wounds it and the
				# run continues (force-rebooted through — MASTER-PLAN §GAME SHAPE)
				fights += 1
				gates += 1
				var gres := _gate_fight(seed * 131 + pos, _gate_seat, carry, sk)
				trace.append(int(gres["checksum"]))
				if bool(gres["won"]):
					gate_wins += 1
			RunMap.KIND_EVENT:
				var ev := MapContent.event(String(n["event"]))
				var chs: Array = ev.get("choices", [])
				if not chs.is_empty():
					var fx: Dictionary = (chs[route.next_u32() % chs.size()] as Dictionary).get("fx", {})
					_apply_fx(fx, carry)
			RunMap.KIND_COOLING:
				_apply_fx({"heal": MapContent.COOLING_HEAL, "mana": 1.0, "repair": true}, carry)
			RunMap.KIND_CACHE:
				_apply_fx({"draft": true}, carry)
	return {"cleared": false, "fights": fights, "gates": gates, "gate_wins": gate_wins,
		"integrity": _avg(carry["fracs"]), "loss_at": "walk_stuck", "trace": str(trace)}

## Mirrors the HUD's _apply_map_fx/_raidify: raid-wide heal/hurt (floor 5%),
## a solo "draft" prize = emergency patch on the most damaged raider, cooling refuels.
func _apply_fx(fx: Dictionary, carry: Dictionary) -> void:
	var fracs: Array = carry["fracs"]
	var heal := float(fx.get("heal", 0.0))
	var hurt := float(fx.get("hurt", 0.0))
	for i in fracs.size():
		fracs[i] = clampf(float(fracs[i]) + heal - hurt, 0.05, 1.0)
	if bool(fx.get("draft", false)):
		var lo := 0
		for i in fracs.size():
			if float(fracs[i]) < float(fracs[lo]):
				lo = i
		fracs[lo] = clampf(float(fracs[lo]) + 0.25, 0.05, 1.0)
	if fx.has("mana"):
		carry["mana"] = clampf(maxf(float(carry["mana"]), float(fx["mana"])), 0.05, 1.0)
	if bool(fx.get("repair", false)):
		var w: Array = carry["wounds"]
		for i in w.size():
			w[i] = 0.0

## One personal GATE exam (Tier 1): the seat's class solo fight via GateContent,
## carried integrity in for THAT raid slot only. A win writes the frac back; a
## loss is the force-reboot (REBOOT_FRAC + a corrupted sector). Mirrors the HUD's
## `_launch_gate_fight` / `_on_end` gate branch exactly.
func _gate_fight(fight_seed: int, seat_key: String, carry: Dictionary, sk: Dictionary) -> Dictionary:
	var s := GateContent.make_state(fight_seed, seat_key, String(RaidNet.DEFAULT_ASPECT[seat_key]))
	var u: Seat = s.seats[0]
	match seat_key:
		"tank":
			var tp := u.policy as BulwarkPolicy
			tp.reaction_slack = float(sk["slack"])
			tp.rng = DetRng.new(fight_seed * 2749 + 4441)
		"blade":
			var bp := u.policy as TwinfangPolicy
			bp.latency_ticks = int(sk["lat"])
			bp.rng = DetRng.new(fight_seed * 2749 + 4442)
		"caster":
			var cp := u.policy as VoidcallerPolicy
			cp.latency_ticks = int(sk["lat"])
			cp.rng = DetRng.new(fight_seed * 2749 + 4443)
		"healer":
			(u.policy as MenderPolicy).latency_ticks = int(sk["hlat"])
	var ri: int = RaidNet.SEAT_KEYS.find(seat_key)
	var fracs: Array = carry["fracs"]
	var wounds: Array = carry["wounds"]
	u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(wounds[ri]))))
	u.hp = maxf(1.0, roundf(u.hp_max * float(fracs[ri])))
	if u.role == "healer":
		u.resource = roundf(u.resource_max * float(carry["mana"]))
	var cap := int(FIGHT_CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	if s.won:
		fracs[ri] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
	else:
		fracs[ri] = REBOOT_FRAC
		wounds[ri] = minf(0.4, float(wounds[ri]) + 0.2)
	if u.role == "healer":
		carry["mana"] = clampf(u.resource / maxf(1.0, u.resource_max), 0.05, 1.0)
	return {"won": s.won, "checksum": s.checksum}

func _fight(fight_seed: int, fi: int, carry: Dictionary, sk: Dictionary) -> Dictionary:
	var fracs: Array = carry["fracs"]
	var enc: EncounterRes = _fights[clampi(fi, 0, _fights.size() - 1)]
	var s := RaidContent.make_state(fight_seed, RaidContent.encounter_by_id(String(enc.id)))
	var tp := s.seats[0].policy as RaidTankPolicy
	tp.reaction_slack = float(sk["slack"])
	tp.rng = DetRng.new(fight_seed * 2749 + 1337)
	var bp := s.seats[1].policy as TwinfangPolicy
	bp.latency_ticks = int(sk["lat"])
	bp.rng = DetRng.new(fight_seed * 2749 + 2338)
	var cp := s.seats[2].policy as VoidcallerPolicy
	cp.latency_ticks = int(sk["lat"])
	cp.rng = DetRng.new(fight_seed * 2749 + 3339)
	(s.seats[3].policy as MenderPolicy).latency_ticks = int(sk["hlat"])
	var wounds: Array = carry["wounds"]
	for i in s.seats.size():
		if i < fracs.size():
			var u: Seat = s.seats[i]
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(wounds[i]))))
			u.hp = maxf(1.0, roundf(u.hp_max * float(fracs[i])))
			if u.role == "healer":
				u.resource = roundf(u.resource_max * float(carry["mana"]))
	var cap := int(FIGHT_CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	if s.won:
		for i in s.seats.size():
			if i < fracs.size():
				var u: Seat = s.seats[i]
				if u.alive():
					fracs[i] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
				else:
					fracs[i] = REBOOT_FRAC
					wounds[i] = minf(0.4, float(wounds[i]) + 0.2)
				if u.role == "healer":
					carry["mana"] = clampf(u.resource / maxf(1.0, u.resource_max), 0.05, 1.0)
	return {"won": s.won, "checksum": s.checksum}

func _avg(fracs: Array) -> float:
	var t := 0.0
	for f in fracs:
		t += float(f)
	return t / maxf(1.0, float(fracs.size()))

func _fmt(losses: Dictionary) -> String:
	if losses.is_empty():
		return "-"
	var parts: Array = []
	for k in losses:
		parts.append("%s=%d" % [k, losses[k]])
	return ", ".join(parts)

func _arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def
