## Headless sim for the Topology RAID floor (MAP-3a — see MASTER-PLAN §MAPS):
## generates "RING 3: THE SHALLOW STACK" maps for the raid fight list
## (Vorathek gate → skirmishes → MISTRAL-7B), proves generation + full-run
## determinism, then WALKS whole runs with the AI raid at three skill tiers —
## per-seat integrity carried between nodes, events applied, dead raiders
## rebooting at 35% after won fights. Prints clear rates + attrition.
##
##   godot --headless --path godot --script res://sim/raid_map_sim.gd -- --seeds=60
extends SceneTree

const FIGHT_CAP_SEC := 240.0
const REBOOT_FRAC := 0.35
const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]

var _fights: Array = []

func _initialize() -> void:
	var seeds := int(_arg("seeds", "60"))
	print("=== Project Rift — raid map sim (Realm 1: the RING descent, MAP-3c) ===")
	# Walk EACH floor of the campaign (Ring 3 MISTRAL → Ring 2 GEMINI → Ring 0 MYTHOS):
	# the Seal escalates per ring, so clear% should fall as we descend.
	for fl in RaidContent.FLOORS:
		_fights = RaidContent.floor_fights(int(fl["ring"]))
		var seal_name := String((_fights[_fights.size() - 1] as EncounterRes).name)
		print("")
		print("######## %s  →  Seal: %s ########" % [String(fl["title"]), seal_name])
		print("fights: %s" % ", ".join(_fights.map(func(e): return String(e.name))))
		_prove_determinism()
		print("skill    clear%%   avg fights  avg integrity(end)  losses at")
		print("------------------------------------------------------------------")
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
			print("%-7s  %5.1f%%      %5.2f            %5.2f         %s" % [
				sk["label"], 100.0 * cleared / n, fight_sum / n,
				(integ_sum / maxf(1.0, float(cleared))), _fmt(losses)])
	quit()

## Same seed twice ⇒ identical map fingerprint AND identical full-run trace
## (visited nodes + every fight checksum) — the co-op/daily-seed guarantee.
func _prove_determinism() -> void:
	var fp1 := RunMap.generate(1, _fights.size(), MapContent.event_ids()).fingerprint()
	var fp2 := RunMap.generate(1, _fights.size(), MapContent.event_ids()).fingerprint()
	var fp3 := RunMap.generate(2, _fights.size(), MapContent.event_ids()).fingerprint()
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
		var m := RunMap.generate(seed, _fights.size(), MapContent.event_ids())
		for nd in m.nodes:
			var fi := int(nd["fight"])
			if String(nd["kind"]) == RunMap.KIND_SEAL and fi != _fights.size() - 1:
				ok = false
			if fi >= 0 and (fi < 0 or fi >= _fights.size()):
				ok = false
	print("structure (40 maps): %s (seal = %s everywhere, fight indices in range)" % [
		("PASS" if ok else "FAIL"), String((_fights[_fights.size() - 1] as EncounterRes).name)])
	_prove_carry(50)

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
	var map := RunMap.generate(seed, _fights.size(), MapContent.event_ids())
	var route := DetRng.new(seed * 7919 + 17)
	var carry := {"fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0}
	var inv := {}
	var pos := -1
	var fights := 0
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
		match String(n["kind"]):
			RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
				fights += 1
				var res := _fight(seed * 131 + pos, int(n["fight"]), carry, sk)
				trace.append(int(res["checksum"]))
				if not bool(res["won"]):
					return {"cleared": false, "fights": fights, "integrity": _avg(carry["fracs"]),
						"loss_at": String((_fights[int(n["fight"])] as EncounterRes).id),
						"trace": str(trace)}
				if String(n["kind"]) == RunMap.KIND_SEAL:
					return {"cleared": true, "fights": fights, "integrity": _avg(carry["fracs"]),
						"loss_at": "", "trace": str(trace)}
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
	return {"cleared": false, "fights": fights, "integrity": _avg(carry["fracs"]),
		"loss_at": "walk_stuck", "trace": str(trace)}

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
