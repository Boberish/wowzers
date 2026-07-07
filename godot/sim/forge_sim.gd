## forge_sim — THE FORGE's certification harness (WORLD-PLAN W2 acceptance bar).
## Sweeps the generated pool (bodies × tiers × seeds) at 3 policy tiers and CERTIFIES:
##   · DETERMINISM — the same forge id twice ⇒ identical checksums (the id is the recipe);
##   · ZERO UNWINNABLE — expert clears EVERY generated fight inside the cap;
##   · BAND SANITY per tier — win rates inside authored tolerances, TTK inside sane
##     bounds (no degenerate too-free / too-lethal outputs).
## Prints per-cell bands + a per-seed CSV. psim-sharded (--seed0/--seeds/--out).
## Run: godot --headless --path godot --script res://sim/forge_sim.gd -- --seeds=20
extends SceneTree

const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]
const TICK_CAP_SEC := 400.0
const ZONE := "gildfields"

## Certification tolerances (v1 — generous until the pool's shape settles; expert is HARD).
const MIN_WIN := {"expert": 100.0, "good": 70.0, "sloppy": 20.0}
## Degeneracy floor, NOT a pacing target — pacing is the zone author's job (a lone
## SWARM body kills in ~19s BY DESIGN; the authoring rule is "a swarm is never alone").
const TTK_MIN_SEC := 15.0

var seeds := 20
var seed0 := 1
var out_path := "res://out/forge_sim_results.csv"
var only_body := ""
var only_tier := 0
var fails := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.substr(8))
		elif a.begins_with("--seed0="):
			seed0 = int(a.substr(8))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--body="):
			only_body = a.substr(7)
		elif a.begins_with("--tier="):
			only_tier = int(a.substr(7))
	var rows: Array = []
	print("cell                                   win%%    avgTTK   ttk[min–max]   n")
	for body in Forge.BODIES:
		if only_body != "" and body != only_body:
			continue
		for tier in [1, 2, 3]:
			if only_tier != 0 and tier != only_tier:
				continue
			_cell(body, tier, rows)
	_write_csv(rows)
	print("FORGE SIM: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)

func _cell(body: String, tier: int, rows: Array) -> void:
	for sk in SKILLS:
		var wins := 0
		var ttk_sum := 0.0
		var ttk_min := 1e9
		var ttk_max := 0.0
		var n := 0
		for k in seeds:
			var fseed := seed0 + k
			var enc_id := "forge:%s:%s:%d:%d" % [ZONE, body, tier, fseed]
			var r := _run_one(enc_id, 1000 + fseed, sk)
			# determinism: the first seed of every cell re-runs and must checksum-match
			if k == 0:
				var r2 := _run_one(enc_id, 1000 + fseed, sk)
				if int(r["checksum"]) != int(r2["checksum"]):
					fails += 1
					print("  CERT FAIL determinism: %s %s (%d vs %d)" % [enc_id,
						sk["label"], int(r["checksum"]), int(r2["checksum"])])
			n += 1
			if bool(r["won"]):
				wins += 1
				ttk_sum += float(r["ttk"])
				ttk_min = minf(ttk_min, float(r["ttk"]))
				ttk_max = maxf(ttk_max, float(r["ttk"]))
			elif String(sk["label"]) == "expert":
				fails += 1
				print("  CERT FAIL unwinnable-at-expert: %s seed %d (%s)" % [enc_id, fseed, r["cause"]])
			rows.append([body, tier, String(sk["label"]), fseed, int(r["won"]),
				"%.2f" % float(r["ttk"]), String(r["cause"]), int(r["checksum"])])
		var wr := 100.0 * wins / maxf(1.0, float(n))
		var avg := (ttk_sum / maxf(1.0, float(wins))) if wins > 0 else 0.0
		print("%-14s t%d %-8s %6.1f%%   %6.1fs   [%5.1f–%5.1f]   %d" % [body, tier,
			sk["label"], wr, avg, (ttk_min if wins > 0 else 0.0), ttk_max, n])
		if wr < float(MIN_WIN[String(sk["label"])]):
			fails += 1
			print("  CERT FAIL band: %s t%d %s %.1f%% < %.0f%%" % [body, tier,
				sk["label"], wr, float(MIN_WIN[String(sk["label"])])])
		if wins > 0 and ttk_min < TTK_MIN_SEC and String(sk["label"]) == "expert":
			fails += 1
			print("  CERT FAIL too-free: %s t%d fastest kill %.1fs" % [body, tier, ttk_min])

func _run_one(enc_id: String, seed: int, sk: Dictionary) -> Dictionary:
	var enc := RaidContent.encounter_by_id(enc_id)
	var s := RaidContent.make_state(seed, enc, {}, "tank", {})
	var tp := s.seats[0].policy as RaidTankPolicy
	tp.reaction_slack = float(sk["slack"])
	tp.rng = DetRng.new(seed * 2749 + 1337)
	var bp := s.seats[1].policy as TwinfangPolicy
	bp.latency_ticks = int(sk["lat"])
	bp.rng = DetRng.new(seed * 2749 + 2338)
	var cp := s.seats[2].policy as VoidcallerPolicy
	cp.latency_ticks = int(sk["lat"])
	cp.rng = DetRng.new(seed * 2749 + 3339)
	var hp := s.seats[3].policy as MenderPolicy
	hp.latency_ticks = int(sk["hlat"])
	var cap := int(TICK_CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		CombatCore.update(s)
	return {"won": s.won, "ttk": s.time(),
		"cause": (s.loss_cause if not s.won else ("timeout" if not s.over else "")),
		"checksum": s.checksum}

func _write_csv(rows: Array) -> void:
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("body,tier,skill,seed,won,ttk_sec,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%d,%s,%d,%d,%s,%s,%d" % [r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7]])
