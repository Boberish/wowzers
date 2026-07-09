## Headless sim for the Topology RAID floor (MAP-3a — see MASTER-PLAN §MAPS):
## generates "RING 3: THE SHALLOW STACK" maps for the raid fight list
## (Vorathek gate → skirmishes → MISTRAL-7B), proves generation + full-run
## determinism, then WALKS whole runs with the AI raid at three skill tiers —
## per-seat integrity carried between nodes, events applied, dead raiders
## rebooting at 35% after won fights. Prints clear rates + attrition.
## (GATE exams died in THE PURGE 2026-07-10 — floors carry no personal-exam node.)
##
##   godot --headless --path godot --script res://sim/raid_map_sim.gd -- --seeds=60
extends SceneTree

const FIGHT_CAP_SEC := 420.0   ## past the deepest baked enrage (MYTHOS 355s) — a capped
                               ## fight must mean STUCK, never "would have won at 241s"
const REBOOT_FRAC := 0.35
## Mirrors the HUD's _build_floor quota exactly (THE DESCENT REFIT: +1 cooling/+1 cache
## ride the 8-row floors).
const FLOOR_QUOTA := {RunMap.KIND_COOLING: 1, RunMap.KIND_CACHE: 1}
const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]

var _fights: Array = []
var _shard_req: int = 0       ## credential-shard gate for the current floor (MAP-3c ROOT)
var _n_tickets: int = 0       ## MAP-2 ticket quests placed on the current floor
var _rows: int = 8            ## the floor's lattice rows (THE DESCENT REFIT — FLOORS "rows")
var _charge_at_seal: Array = []   # ⏻ ECON diagnostic: charge banked when a Seal is reached

func _initialize() -> void:
	var seeds := int(SimUtil.arg("seeds", "60"))
	print("=== Project Rift — raid map sim (Realm 1: the RING descent, MAP-3c) ===")
	# Walk EACH floor of the campaign (Ring 3 MISTRAL → Ring 2 GEMINI → Ring 0 MYTHOS):
	# the Seal escalates per ring, so clear% should fall as we descend. The ROOT
	# floor adds a shard gate.
	for fl in RaidContent.FLOORS:
		_fights = RaidContent.floor_fights(int(fl["ring"]))
		_shard_req = int(fl["shard_req"])
		_n_tickets = int(fl.get("tickets", 0))
		_rows = int(fl.get("rows", 8))
		var seal_name := String((_fights[_fights.size() - 1] as EncounterRes).name)
		print("")
		print("######## %s  →  Seal: %s ########" % [String(fl["title"]), seal_name])
		print("fights: %s" % ", ".join(_fights.map(func(e): return String(e.name))))
		_prove_determinism()
		_charge_at_seal = []
		print("skill    clear%%   avg fights  avg integrity(end)  losses at")
		print("----------------------------------------------------------------")
		for sk in SKILLS:
			var cleared := 0
			var fight_sum := 0
			var integ_sum := 0.0
			var losses := {}
			for seed in range(1, seeds + 1):
				var r := _walk(seed, sk)
				if r["cleared"]:
					cleared += 1
					integ_sum += float(r["integrity"])
				else:
					var k := String(r["loss_at"])
					losses[k] = int(losses.get(k, 0)) + 1
				fight_sum += int(r["fights"])
			var n := float(seeds)
			print("%-7s  %5.1f%%      %5.2f            %5.2f          %s" % [
				sk["label"], 100.0 * cleared / n, fight_sum / n,
				(integ_sum / maxf(1.0, float(cleared))), SimUtil.fmt_causes(losses)])
		# ⏻ ECON: avg charge banked when a Seal is reached, + the SURGE cut it buys
		var avg_ch := _avg_i(_charge_at_seal)
		print("  ⏻ charge@Seal: avg %.0f · max %d · SURGE cut ~%.0f%% boss HP" % [
			avg_ch, _max_i(_charge_at_seal), avg_ch / 100.0 * RaidMarks.HP_CUT_CAP * 100.0])
	quit()

func _avg_i(a: Array) -> float:
	if a.is_empty(): return 0.0
	var t := 0
	for v in a: t += int(v)
	return float(t) / a.size()

func _max_i(a: Array) -> int:
	var m := 0
	for v in a: m = maxi(m, int(v))
	return m

## Same seed twice ⇒ identical map fingerprint AND identical full-run trace
## (visited nodes + every fight checksum) — the co-op/daily-seed guarantee.
func _prove_determinism() -> void:
	var fp1 := RunMap.generate(1, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows).fingerprint()
	var fp2 := RunMap.generate(1, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows).fingerprint()
	var fp3 := RunMap.generate(2, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows).fingerprint()
	print("map determinism: seed1==seed1 -> %s · seed1 vs seed2 -> %s" % [
		("PASS" if fp1 == fp2 else "FAIL"),
		("differ (good)" if fp1 != fp3 else "IDENTICAL (suspect!)")])
	var sk: Dictionary = SKILLS[0]
	var a := _walk(1, sk)
	var b := _walk(1, sk)
	print("run determinism: %s  (trace %s, cleared=%s, fights=%d)" % [
		("PASS" if a["trace"] == b["trace"] else "FAIL"),
		String(a["trace"]).left(46) + "…", str(a["cleared"]), a["fights"]])
	# structure: every combat/seal node's fight index is valid; the Seal is the boss
	var ok := true
	for seed in range(1, 40):
		var m := RunMap.generate(seed, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
		for nd in m.nodes:
			var fi := int(nd["fight"])
			if String(nd["kind"]) == RunMap.KIND_SEAL and fi != _fights.size() - 1:
				ok = false
			if fi >= 0 and (fi < 0 or fi >= _fights.size()):
				ok = false
	print("structure (40 maps): %s (seal = %s everywhere, fight indices in range)" % [
		("PASS" if ok else "FAIL"), String((_fights[_fights.size() - 1] as EncounterRes).name)])
	_prove_shard_gate(60)
	_prove_tickets(40)
	_prove_carry(50)

## TICKETS (MAP-2): placement is deterministic, and every placed ticket is closeable
## by construction — pickup and turn-in share a lane with the turn-in strictly later,
## so the always-present same-lane spine connects them on some route.
func _prove_tickets(seeds: int) -> void:
	if _n_tickets <= 0:
		return
	var ok := true
	var placed := 0
	var closeable := 0
	for seed in range(1, seeds + 1):
		var m := RunMap.generate(seed, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
		for tid in m.tickets:
			placed += 1
			var pu := -1
			var ti := -1
			for nd in m.nodes:
				if String(nd.get("ticket_open", "")) == String(tid):
					pu = int(nd["id"])
				if String(nd.get("ticket_close", "")) == String(tid):
					ti = int(nd["id"])
			if pu >= 0 and ti >= 0 and int(m.node(pu)["lane"]) == int(m.node(ti)["lane"]) \
					and int(m.node(pu)["row"]) < int(m.node(ti)["row"]):
				closeable += 1
			else:
				ok = false
	var a := RunMap.generate(7, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
	var b := RunMap.generate(7, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
	var det: bool = str(a.tickets) == str(b.tickets) and a.fingerprint() == b.fingerprint()
	print("tickets (%d maps, %d/floor): placement det %s · closeable %d/%d %s" % [
		seeds, _n_tickets, ("PASS" if det else "FAIL"), closeable, placed,
		("PASS" if ok and closeable == placed else "FAIL")])

## Completability under the credential-shard gate (MAP-3c ROOT): BFS over
## (from_node, shards_collected) states via reachable(); the Seal must be reachable
## on EVERY seed and EVERY route — a gate that could strand you shard-short is a bug.
func _prove_shard_gate(seeds: int) -> void:
	if _shard_req <= 0:
		return
	var ok := true
	for seed in range(1, seeds + 1):
		var m := RunMap.generate(seed, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
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
	var map := RunMap.generate(seed, _fights.size(), MapContent.raid_event_ids(), FLOOR_QUOTA, _shard_req, _n_tickets, _rows)
	var route := DetRng.new(seed * 7919 + 17)
	var carry := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0,
		"marks": {}, "charge": 0}
	var inv := {}
	var pos := -1
	var fights := 0
	var closed := 0                    # tickets closed this walk (MAP-2)
	var event_fails := 0               # consecutive Inference-Check fails → comeback pity
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
		# TICKETS (MAP-2): a SIMPLIFIED walker take (set-shaped, no toast/stub/purse).
		# The shipping rule is CampaignCore.ticket_at (P3.1) — if the reward economy
		# changes there, mirror it here (this walker is a diagnostic, not UI).
		var topen := String(n.get("ticket_open", ""))
		if topen != "":
			if not inv.has("tickets"):
				inv["tickets"] = {}
			(inv["tickets"] as Dictionary)[topen] = true
		var tclose := String(n.get("ticket_close", ""))
		if tclose != "":
			var held: Dictionary = inv.get("tickets", {})
			if held.has(tclose):
				held.erase(tclose)
				closed += 1
				_apply_fx(MapContent.ticket(tclose).get("reward", {}), carry)
				if closed >= map.tickets.size() and map.tickets.size() > 0:
					_apply_fx(MapContent.SPRINT_RETRO_FX, carry)
		match String(n["kind"]):
			RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
				fights += 1
				# THE KILL SWITCH: at a Seal, auto-cash-out the whole meter as an OVERCLOCK
				# SURGE (mirrors the arming panel's spend-all) so the sim exercises the loop.
				if String(n["kind"]) == RunMap.KIND_SEAL:
					_charge_at_seal.append(int(carry["charge"]))   # econ diagnostic
				if String(n["kind"]) == RunMap.KIND_SEAL and int(carry["charge"]) > 0:
					var ch := int(carry["charge"])
					(carry["marks"] as Dictionary).merge(
						RaidMarks.overclock("surge", ch), true)
					carry["charge"] = 0
				var res := _fight(seed * 131 + pos, int(n["fight"]), carry, sk)
				trace.append(int(res["checksum"]))
				if not bool(res["won"]):
					return {"cleared": false, "fights": fights,
						"integrity": _avg(carry["fracs"]),
						"loss_at": String((_fights[int(n["fight"])] as EncounterRes).id),
						"trace": str(trace)}
				if String(n["kind"]) == RunMap.KIND_COMBAT:   # scavenge a breaker component
					carry["charge"] = mini(100, int(carry["charge"]) + MapFx.SKIRMISH_CHARGE)
				if String(n["kind"]) == RunMap.KIND_SEAL:
					return {"cleared": true, "fights": fights,
						"integrity": _avg(carry["fracs"]), "loss_at": "", "trace": str(trace)}
			RunMap.KIND_EVENT:
				# Resolve the event like the HUD: build a ctx (the AI raid carries no
				# boons, so checks read at ~base + integrity), pick a random AVAILABLE
				# choice (skip locked gates), and roll checks on the deterministic die.
				var ev := MapContent.event(String(n["event"]))
				var chs: Array = ev.get("choices", [])
				var ctx := MapCheck.build_ctx([], [], "", "tank", _avg(carry["fracs"]),
					0, 0, event_fails, inv, {}, 0)
				var avail: Array = []
				for ci in chs.size():
					var cc: Dictionary = chs[ci]
					var g: Dictionary = cc.get("gate", {})
					if g.is_empty() or MapCheck.gate_ok(g, ctx):
						avail.append(ci)
				if not avail.is_empty():
					var pick_i: int = avail[route.next_u32() % avail.size()]
					var c: Dictionary = chs[pick_i]
					if MapCheck.check_like(String(c.get("kind", "free"))):
						var res := MapCheck.resolve(c, ctx, map.seed, pos, pick_i, 0, {})
						event_fails = 0 if bool(res["success"]) else event_fails + 1
						_apply_fx(res["fx"], carry)
					else:
						_apply_fx(c.get("fx", {}), carry)
			RunMap.KIND_COOLING:
				_apply_fx({"heal": MapContent.COOLING_HEAL, "mana": 1.0, "repair": true}, carry)
			RunMap.KIND_CACHE:
				_apply_fx({"draft": true}, carry)
	return {"cleared": false, "fights": fights,
		"integrity": _avg(carry["fracs"]), "loss_at": "walk_stuck", "trace": str(trace)}

## Routes through the shared MapFx applier (same as the offline HUD + online server),
## so the attrition walk stays representative of what actually happens in-game. The
## walker's carry ({fracs,wounds,mana}) is a subset of MapFx's cp-view; absent keys
## no-op. mana is a scalar in the dict, so MapFx mutates carry["mana"] in place.
func _apply_fx(fx: Dictionary, carry: Dictionary) -> void:
	MapFx.apply(carry, fx)

func _fight(fight_seed: int, fi: int, carry: Dictionary, sk: Dictionary) -> Dictionary:
	var fracs: Array = carry["fracs"]      # vestigial (integrity retired) — only the reboot
	var enc: EncounterRes = _fights[clampi(fi, 0, _fights.size() - 1)]   # write-back + readout use it
	var s := RaidContent.make_state(fight_seed, RaidContent.encounter_by_id(String(enc.id)))
	# consume a pending fight-mark (KILL SWITCH cash-out / curse) via the SHARED applier
	RaidMarks.apply(s, carry.get("marks", {}))
	carry["marks"] = {}
	var tp := s.seats[0].policy as RaidTankPolicy
	tp.reaction_slack = float(sk["slack"])
	tp.rng = DetRng.new(fight_seed * 2749 + 1337)
	var bp := s.seats[1].policy as TwinfangPolicy
	bp.latency_ticks = int(sk["lat"])
	bp.rng = DetRng.new(fight_seed * 2749 + 2338)
	var cp := s.seats[2].policy as AlchemistPolicy
	cp.latency_ticks = int(sk["lat"])
	cp.rng = DetRng.new(fight_seed * 2749 + 3339)
	var hp := s.seats[3].policy as WellPolicy
	hp.latency_ticks = int(sk["hlat"])
	hp.rng = DetRng.new(fight_seed * 2749 + 5531)
	var wounds: Array = carry["wounds"]
	for i in s.seats.size():
		if i < wounds.size():
			var u: Seat = s.seats[i]
			# integrity retired: boot FULL of the wound-reduced pool; mana still carries
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(wounds[i]))))
			u.hp = u.hp_max
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

