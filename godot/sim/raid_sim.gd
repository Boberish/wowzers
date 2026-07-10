## Headless RAID sim — all four Seals (see MASTER-PLAN §RAID SEALS): four
## FULL-fidelity seats (Bulwark tank / Twinfang + Alchemist dps / Well healer),
## one shared CombatState, threat + taunt live. Proves determinism per Seal, prints
## win-rate bands by uniform party skill with Seal-specific diagnostics (kick-chain
## verses, doom beats, add waves, hotfix healing), and probes that THREAT is
## load-bearing on the classic Seal.
##
##   godot --headless --path godot --script res://sim/raid_sim.gd -- --seeds=200
##   optional: --boss=riftmaw|mistral|gemini|mythos (default: all)
extends SceneTree

# Which healer CLASS fills the healer seat, and its aspect. Default = the WELL
# (post-purge comp; --healer=bloomweaver [--haspect=wildgrove|thornveil] runs the
# second healer).
var _healer_cls := "well"
var _haspect := ""
var _baspect := ""    # --blade=tempo runs the reworked Tempo blade (default = the venomancer comp)
var _brig := ""       # --rig=when:then wires the blade's Combo rig (e.g. --rig=coup:overcharge)
var _caster_cls := "alchemist"    # the Brew is THE caster (post-purge)
                                  # (⚠ NO kicker in the comp until interrupt-by-ability)

# --- FAST-ITERATION + LIVE TUNING knobs (for playtest tweaking — see ./tune.sh) ---
# During tuning you don't need 200 seeds or the correctness gates; you need a fast
# read you can re-run after each tweak. These make that loop cheap:
var _probes := true       # --probes=0  : skip determinism + threat-gate probes (they're gates, not tuning signals)
var _dmg := 1.0           # --dmg=1.3   : scale ALL boss damage (melee/swings/novas/dots/beats) — the difficulty dial
var _regen := -1.0        # --regen=0.5 : legacy mana dial (inert on the charge-based Well; bites only for mana healers)
var _fortify := -1.0      # --fortify=0.5: override the tank's raid Fortify self-heal mult (the tank-sustain dial)
var _skills: Array = []   # --skills=good  or  --skills=good,sloppy  (default = all three)

const TICK_CAP_SEC := 300.0
const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]
# S0 (BOSS-BRIEF): the DESCENT §4 timer contract, in seconds — the target good-tier
# TTK the boss rework must fill with STRUCTURE. The instrumentation flags a fight
# ⚠ OFF-TARGET when it lands outside ±20% (a report line, not a hard fail — numbers
# are still SealTune-loose until Bill locks them). Baseline today reads WAY under.
const CONTRACT_TTK := {"riftmaw": 300.0, "mistral": 420.0, "gemini": 540.0, "mythos": 720.0}

func _initialize() -> void:
	var seeds := int(SimUtil.arg("seeds", "200"))
	var seed0 := int(SimUtil.arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	var only := SimUtil.arg("boss", "")
	_healer_cls = SimUtil.arg("healer", "well")
	_haspect = SimUtil.arg("haspect", "")
	_baspect = SimUtil.arg("blade", "")
	_brig = SimUtil.arg("rig", "")
	_caster_cls = SimUtil.arg("caster", "alchemist")
	_probes = SimUtil.arg("probes", "1") != "0"
	_dmg = float(SimUtil.arg("dmg", "1"))
	_regen = float(SimUtil.arg("regen", "-1"))
	_fortify = float(SimUtil.arg("fortify", "-1"))
	_skills = _pick_skills(SimUtil.arg("skills", ""))
	var bosses: Array = ["riftmaw", "mistral", "gemini", "mythos"] if only == "" else [only]
	var healer_desc := "Well(%s)" % (_haspect if _haspect != "" else "brim")
	if _healer_cls == "bloomweaver":
		healer_desc = "Bloomweaver(%s)" % (_haspect if _haspect != "" else "wildgrove")
	var caster_desc := "Alchemist(brew)"
	var blade_desc := "Twinfang(%s)" % (_baspect if _baspect != "" else "venomancer")
	print("=== Project Rift — raid sim (the Seals) ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("party: Duelist / %s / %s / %s" % [blade_desc, caster_desc, healer_desc])
	if _dmg != 1.0 or _regen >= 0.0 or _fortify >= 0.0:
		print("OVERRIDES:  dmg ×%.2f   regen %s   fortify %s   (live tweaks, not saved to files)" % [
			_dmg, ("%.2f" % _regen if _regen >= 0.0 else "—"),
			("%.2f" % _fortify if _fortify >= 0.0 else "—")])
	if not _probes:
		print("(quick mode: determinism + threat-gate probes SKIPPED)")
	print("")
	if seed0 == 1 and _probes:             # shard 0 only (probes are seed-independent diagnostics)
		for b in bosses:
			_prove_determinism(String(b))
	print("")

	var rows: Array = []
	for b in bosses:
		var enc := RaidContent.encounter_by_id(String(b))
		print("--- %s  (%d HP, enrage %.0fs) ---" % [enc.name, enc.hp, enc.enrage_at])
		# healer-engagement cols: hlMana = healer's MIN mana over the fight (% of pool),
		# hlOver = share of its healing that was OVERHEAL (wasted), hlIdle = % of the
		# healer's decision ticks it had NOTHING worth casting. Low hlOver+low hlIdle+
		# a mana floor that actually dips = the healer's resource is a real constraint;
		# hlMana pinned near 100 with high hlIdle = the fight doesn't pressure the healer.
		print("skill    win-rate   avg TTK(win)  peels   kicks  healed  scaled  beatmiss  adds  hlMana hlOver hlIdle  rez  losses")
		var inst_by_skill := {}                   # S0: per-skill instrumentation accumulators
		for sk in _skills:
			var wins := 0
			var ttk_sum := 0.0
			var agg := {"peels": 0.0, "kicks": 0.0, "healed": 0.0, "buff": 0.0,
				"miss": 0.0, "adds": 0.0, "hmana": 0.0, "hover": 0.0, "hidle": 0.0, "rez": 0.0}
			var causes := {}
			var i_beats: Array = [{}, {}, {}, {}]   # S0: per-seat beat-budget sums
			var i_casts := {}                       # S0: ability id -> cast count sum
			var i_pf := 0.0; var i_as := 0.0; var i_vp := 0.0
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(String(b), seed, sk)
				r["skill"] = sk["label"]; r["seed"] = seed; r["boss"] = b; r["probe"] = "flow"
				rows.append(r)
				agg["peels"] += float(int(r["peels"]))
				agg["kicks"] += float(int(r["kicks"]))
				agg["healed"] += float(r["boss_healed"])
				agg["buff"] += float(r["dmg_buff"])
				agg["miss"] += float(int(r["beat_miss"]))
				agg["adds"] += float(int(r["adds_killed"]))
				agg["hmana"] += float(r["hl_mana_pct"])
				agg["hover"] += float(r["hl_over_pct"])
				agg["hidle"] += float(r["hl_idle_pct"])
				agg["rez"] += float(int(r["revives"]))
				_accum_inst(i_beats, i_casts, r)
				i_pf += float(r["phase_flips"]); i_as += float(r["add_spawns"]); i_vp += float(r["valley_pct"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			var n := float(seeds)
			print("%-7s  %6.1f%%   %8.1fs    %5.2f  %5.2f  %6.1f  %5.2f    %6.2f  %4.2f  %5.0f%% %5.0f%% %5.0f%%  %3.2f  %s" % [
				sk["label"], wr, avg, agg["peels"] / n, agg["kicks"] / n, agg["healed"] / n,
				agg["buff"] / n, agg["miss"] / n, agg["adds"] / n,
				agg["hmana"] / n, agg["hover"] / n, agg["hidle"] / n, agg["rez"] / n, SimUtil.fmt_causes(causes)])
			inst_by_skill[sk["label"]] = {"beats": i_beats, "casts": i_casts,
				"pf": i_pf, "as": i_as, "vp": i_vp, "n": n, "ttk": avg}
		print("")
		_print_instrumentation(String(b), enc, inst_by_skill)
		print("")

	_write_csv(SimUtil.arg("out", "res://out/raid_results.csv"), rows)
	print("")
	print("wrote %d rows -> %s" % [rows.size(),
		ProjectSettings.globalize_path(SimUtil.arg("out", "res://out/raid_results.csv"))])
	quit()

func _run_one(boss: String, seed: int, sk: Dictionary) -> Dictionary:
	var enc := RaidContent.encounter_by_id(boss)
	if _dmg != 1.0:
		_scale_damage(enc)                               # --dmg override (fresh enc per run — no leak)
	var _asp := {}
	if _haspect != "": _asp["healer"] = _haspect
	if _baspect != "": _asp["blade"] = _baspect
	var s := RaidContent.make_state(seed, enc, _asp, "tank",
		{"healer": _healer_cls, "caster": _caster_cls})
	var tank := s.seats[0]
	var blade := s.seats[1]
	var caster := s.seats[2]
	var healer := s.seats[3]
	if _regen >= 0.0:
		healer.vars["regen_mult"] = _regen               # --regen override (mana dial)
	# --fortify is inert now: the Duelist has NO self-heal (partial-mit law); tank sustain
	# is the healer duet + the flow/peel knobs (TuningConfig). Flag kept as a harmless no-op.
	var tp := tank.policy as DuelistPolicy
	tp.latency_ticks = int(sk["lat"])
	tp.rng = DetRng.new(seed * 2749 + 6737)   # NEW salt — never Bulwark's 1337
	if _brig != "" and blade.kit is TwinfangKit:      # wire the Combo rig for the probe
		var parts := _brig.split(":")
		if parts.size() == 2:
			(blade.kit as TwinfangKit).rig = {"when": parts[0], "then": parts[1]}
	var bp := blade.policy as TwinfangPolicy
	bp.latency_ticks = int(sk["lat"])
	bp.rng = DetRng.new(seed * 2749 + 2338)
	var ap := caster.policy as AlchemistPolicy
	ap.latency_ticks = int(sk["lat"])
	ap.rng = DetRng.new(seed * 2749 + 3339)
	# both healer classes expose latency_ticks (extends Policy); pick the real type
	if healer.policy is BloomweaverPolicy:
		(healer.policy as BloomweaverPolicy).latency_ticks = int(sk["hlat"])
	else:
		var lp := healer.policy as WellPolicy
		lp.latency_ticks = int(sk["hlat"])
		lp.rng = DetRng.new(seed * 2749 + 5531)
	return _run(s)

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	# healer-engagement sampling (read-only — does not touch the sim, so checksums
	# stay byte-identical): min mana over the fight + how often the healer idled.
	var healer := _healer_seat(s)
	var mana_max := (healer.resource_max if healer != null else 900.0)
	var mana_min := (healer.resource if healer != null else 0.0)
	var h_idle := 0
	var h_acts := 0
	# --- S0 instrumentation (BOSS-BRIEF): pure reads of state AFTER each update, so
	# checksums stay byte-identical. Watches telegraph transitions (cast counts),
	# phase/add/walk-in transitions (the act/valley timeline). ---
	var casts: Dictionary = {}                 # ability id (String) -> telegraphs started for it
	var prev_tele: Telegraph = null
	var phase_flips := 0
	var phase_last := CombatCore.current_phase(s).at
	var add_spawns := 0
	var add_kills := 0
	var add_last := s.boss.add_i
	var valley_ticks := 0
	var total_ticks := 0
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if seat == healer:
					h_acts += 1
					# TRULY idle = nothing to do AND not mid-cast (a cast bar is work,
					# not idleness — counting it as idle inflated the number).
					if a.is_empty() and seat.casting.is_empty():
						h_idle += 1
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		if healer != null:
			mana_min = minf(mana_min, healer.resource)
		# --- S0 sampling (read-only) ---
		total_ticks += 1
		var tele := s.telegraph
		if tele != null and tele != prev_tele:      # a NEW telegraph began this tick
			var aid := String(tele.ability.id)
			casts[aid] = int(casts.get(aid, 0)) + 1
		prev_tele = tele
		var ph_at := CombatCore.current_phase(s).at
		if ph_at != phase_last:
			phase_flips += 1; phase_last = ph_at
		if s.boss.add_i != add_last:
			if s.boss.add_i >= 0: add_spawns += 1
			else: add_kills += 1
			add_last = s.boss.add_i
		# valley = a diegetic breather the raid isn't dodging through. Today only PACK
		# walk-ins qualify (Seals have no packs yet) → ~0% baseline; the BREAK/stance
		# valleys the rework adds light this up in S2+.
		if s.boss.entered_tick > 0 and s.tick < s.boss.entered_tick + s.config.pack_walkin_ticks:
			valley_ticks += 1
	if not s.over:
		s.loss_cause = "timeout"
	var dps_deaths := 0
	var beat_miss := 0
	var peels := 0
	for seat in s.seats:
		if seat.role == "dps" and not seat.alive():
			dps_deaths += 1
		beat_miss += int(seat.diag.get("miss", 0))
		peels += int(seat.diag.get("aggro_pulled", 0))   # FLOW=AGGRO: times the boss strayed off the tank
	var adds_killed := s.boss.adds_spawned.size() - (1 if s.boss.add_i >= 0 else 0)
	# healer output from the meter (eff vs overheal) → % wasted; mana floor as % of pool.
	var hrow: Dictionary = s.meter.get(s.seats.find(healer), {})
	var h_eff := float(hrow.get("heal_total", 0.0))
	var h_over := float(hrow.get("over_total", 0.0))
	var h_total := h_eff + h_over
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"boss_healed": s.boss.heal_total,
		"dmg_buff": s.boss.dmg_buff,           # scaled: landed empower verses × buff
		"peels": peels,                        # aggro pulls (the tank slipped below the lock floor)
		"kicks": int(s.seats[2].vars.get("kicks", 0)),
		"beat_miss": beat_miss,                # missed string beats, all four seats
		"adds_killed": adds_killed,
		"dps_deaths": dps_deaths,
		"hl_mana_pct": 100.0 * mana_min / maxf(1.0, mana_max),
		"hl_over_pct": (100.0 * h_over / h_total) if h_total > 0.0 else 0.0,
		"hl_idle_pct": 100.0 * float(h_idle) / float(maxi(1, h_acts)),
		"hl_eff": h_eff,
		"revives": int(healer.vars.get("revives", 0)) if healer != null else 0,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
		# --- S0 instrumentation payload (byte-identical: never read by update()) ---
		"beats": _seat_beats(s),
		"casts": casts,
		"phase_flips": phase_flips,
		"add_spawns": add_spawns,
		"valley_pct": 100.0 * float(valley_ticks) / float(maxi(1, total_ticks)),
	}

## --skills filter: "" = all three; "good" or "good,sloppy" = just those tiers (faster).
func _pick_skills(spec: String) -> Array:
	if spec == "":
		return SKILLS
	var picked: Array = []
	for sk in SKILLS:
		if spec.findn(String(sk["label"])) >= 0:
			picked.append(sk)
	return picked if not picked.is_empty() else SKILLS

## --dmg override: scale every DAMAGE payload on a FRESH encounter (never the boss's
## own self-heal or empower — those aren't "damage"). Melee, swings, novas, DoT ticks,
## and barrage/string beats (beats are amount_frac × ability.amount) all ride this.
func _scale_damage(enc: EncounterRes) -> void:
	if not enc.melee.is_empty():
		enc.melee["min"] = float(enc.melee.get("min", 0.0)) * _dmg
		enc.melee["max"] = float(enc.melee.get("max", 0.0)) * _dmg
	for ab in enc.abilities:
		_scale_ability(ab as AbilityRes)
	for ad in enc.adds:
		var a := ad as AddRes
		if not a.melee.is_empty():
			a.melee["min"] = float(a.melee.get("min", 0.0)) * _dmg
			a.melee["max"] = float(a.melee.get("max", 0.0)) * _dmg
		for ab in a.abilities:
			_scale_ability(ab as AbilityRes)

func _scale_ability(ab: AbilityRes) -> void:
	if ab.effect != AbilityRes.Effect.HEAL_BOSS and ab.effect != AbilityRes.Effect.EMPOWER_BOSS:
		ab.amount = ab.amount * _dmg
	ab.dot_tick = ab.dot_tick * _dmg
	for ch in ab.chain:                # chained verses carry their own payloads
		_scale_ability(ch as AbilityRes)

## The single healer seat (role == "healer"); null if a comp ever runs without one.
func _healer_seat(s: CombatState) -> Seat:
	for seat in s.seats:
		if seat.role == "healer":
			return seat
	return null

func _prove_determinism(boss: String) -> void:
	var sk: Dictionary = SKILLS[0]
	var a := _run_one(boss, 1, sk)
	var b := _run_one(boss, 1, sk)
	var c := _run_one(boss, 2, sk)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism %-8s seed1==seed1 -> %s  (checksum %d, TTK %.3fs, %s) · seed1 vs seed2 -> %s" % [
		boss, ("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"],
		("win" if a["won"] else a["loss_cause"]),
		("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)")])

# --------------------------------------------------------------------------
# S0 INSTRUMENTATION (BOSS-BRIEF) — beat budget · cast sources · TTK-vs-contract ·
# act/valley timeline · the verse (kick) baseline. All fed by pure reads in _run(),
# so the whole block is byte-identical to the pre-S0 sim.
# --------------------------------------------------------------------------

## Per-seat beat-budget snapshot from seat.diag at end of run. presented = the
## answerable beats put to this seat (perfect+good+graze+miss); feints = the
## hallucination reads (baited+read). Two dps seats print separately (blade/caster).
func _seat_beats(s: CombatState) -> Array:
	var labels := ["tank", "blade", "caster", "healer"]
	var out: Array = []
	for i in range(mini(4, s.seats.size())):
		var d: Dictionary = s.seats[i].diag
		var perfect := int(d.get("perfect", 0))
		var good := int(d.get("good", 0))
		var graze := int(d.get("graze", 0))
		var miss := int(d.get("miss", 0))
		out.append({"label": labels[i],
			"presented": perfect + good + graze + miss,
			"perfect": perfect, "good": good, "graze": graze, "miss": miss,
			"feints": int(d.get("baited", 0)) + int(d.get("read", 0))})
	return out

## Merge one run's instrumentation into the per-skill accumulators.
func _accum_inst(i_beats: Array, i_casts: Dictionary, r: Dictionary) -> void:
	var beats: Array = r.get("beats", [])
	for i in range(mini(beats.size(), i_beats.size())):
		var b: Dictionary = beats[i]
		var acc: Dictionary = i_beats[i]
		acc["label"] = b["label"]
		for k in ["presented", "perfect", "good", "graze", "miss", "feints"]:
			acc[k] = float(acc.get(k, 0.0)) + float(b[k])
	var casts: Dictionary = r.get("casts", {})
	for k in casts:
		i_casts[k] = int(i_casts.get(k, 0)) + int(casts[k])

## Collect the INTERRUPTIBLE (kickable verse) ability ids on an encounter, walking
## chains — used to mark verses in the cast table and print the §1½ kick baseline.
func _collect_verse_ids(ab: AbilityRes, out: Dictionary) -> void:
	if ab.response == AbilityRes.Response.INTERRUPTIBLE:
		out[String(ab.id)] = true
	for ch in ab.chain:
		_collect_verse_ids(ch as AbilityRes, out)

## The S0 tables, printed per boss off the good-tier aggregate (the budget's
## reference tier; falls back to whatever tier ran if good was filtered out).
func _print_instrumentation(boss: String, enc: EncounterRes, by_skill: Dictionary) -> void:
	if by_skill.is_empty():
		return
	var ref: String = "good" if by_skill.has("good") else String(by_skill.keys()[0])
	var d: Dictionary = by_skill[ref]
	var n: float = maxf(1.0, float(d["n"]))
	print("  [S0] instrumentation @ %s tier (%d seeds) — the pre-rework baseline:" % [ref, int(n)])

	# 1 · TTK vs the DESCENT §4 contract
	var target := float(CONTRACT_TTK.get(boss, 0.0))
	var meas := float(d["ttk"])
	if target > 0.0 and meas > 0.0:
		var dev := 100.0 * (meas - target) / target
		var flag := "⚠ OFF-TARGET" if absf(dev) > 20.0 else "ok"
		print("    TTK(%s) %.0fs vs contract %.0fs  (%+.0f%%)  %s" % [ref, meas, target, dev, flag])

	# 2 · beat budget per seat (the ~3–8/fight non-tank ration lives here)
	print("    beat budget/seat    presented  perfect  good  graze  miss  feints")
	for acc in d["beats"]:
		if acc.is_empty():
			continue
		print("      %-7s           %7.1f  %7.1f %5.1f %6.1f %5.1f %6.1f" % [
			acc["label"], float(acc["presented"]) / n, float(acc["perfect"]) / n,
			float(acc["good"]) / n, float(acc["graze"]) / n, float(acc["miss"]) / n,
			float(acc["feints"]) / n])

	# 3 · cast-source counts (verses tagged) + the §1½ verse baseline
	var verse_ids := {}
	for ab in enc.abilities:
		_collect_verse_ids(ab as AbilityRes, verse_ids)
	var ids: Array = d["casts"].keys(); ids.sort()
	var line := "    casts/run: "
	for id in ids:
		line += "%s×%.1f%s  " % [id, float(d["casts"][id]) / n, (" [verse]" if verse_ids.has(id) else "")]
	print(line)
	if not verse_ids.is_empty():
		# no class carries a kick yet (KICK POSTURE) → every verse lands uncontested;
		# landed==casts, kicked==0. S7 flips this live once a class carries interrupts.
		var vline := "    verses (uncontested, no kicker): "
		for id in verse_ids:
			vline += "%s landed×%.1f (kicked 0)  " % [id, float(d["casts"].get(id, 0)) / n]
		print(vline)

	# 4 · act / valley timeline
	print("    timeline: phase-flips %.2f/run · add-spawns %.2f/run · valley(walk-in) %.1f%%" % [
		float(d["pf"]) / n, float(d["as"]) / n, float(d["vp"]) / n])

func _write_csv(path: String, rows: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("boss,skill,seed,probe,won,ttk_sec,boss_hp_left,boss_healed,dmg_buff,peels,kicks,beat_miss,adds_killed,dps_deaths,hl_mana_pct,hl_over_pct,hl_idle_pct,hl_eff,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%d,%s,%d,%.3f,%.1f,%.1f,%.2f,%d,%d,%d,%d,%d,%.1f,%.1f,%.1f,%.1f,%s,%d" % [
			r["boss"], r["skill"], r["seed"], r["probe"], (1 if r["won"] else 0), r["ttk_sec"],
			r["boss_hp_left"], r["boss_healed"], r["dmg_buff"], r["peels"], r["kicks"],
			r["beat_miss"], r["adds_killed"], r["dps_deaths"],
			r["hl_mana_pct"], r["hl_over_pct"], r["hl_idle_pct"], r["hl_eff"],
			r["loss_cause"], r["checksum"]])
	f.close()

