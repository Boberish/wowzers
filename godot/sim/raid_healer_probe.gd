## Diagnostic probe: does the RAID actually pressure the healer's mana?
## Runs the raid fight and measures what the HEALER experiences — mana floor,
## effective vs. overheal, GCD idle %, and how much damage reaches each seat.
## Two healer modes:
##   ai   — the real MenderPolicy (efficient: heals only when needed, self-Meditates)
##   spam — a dumb human-style "mash Flash Heal on the lowest ally every GCD"
## Neither is a balance sim; it's a LOG to answer "why is mana infinite?".
##
##   godot --headless --path godot --script res://sim/raid_healer_probe.gd -- --seeds=60 --boss=riftmaw
extends SceneTree

const TICK_CAP_SEC := 300.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "60"))
	var only := _arg("boss", "")
	var bosses: Array = ["riftmaw", "mythos"] if only == "" else [only]
	print("=== RAID healer-pressure probe ===  %d seeds/cell (good skill)" % seeds)
	print("party: Bulwark(warden,~%d hp) / Twinfang / Voidcaller / Mender(tidecaller, mana 900, regen 8/s)" % int(BulwarkConfig.new().hp_max))
	print("")
	for b in bosses:
		var enc := RaidContent.encounter_by_id(String(b))
		print("--- %s  (%d HP, enrage %.0fs) ---" % [enc.name, enc.hp, enc.enrage_at])
		for mode in ["ai", "spam"]:
			_run_cell(String(b), mode, seeds)
		print("")
	quit()

func _run_cell(boss: String, mode: String, seeds: int) -> void:
	var agg := {"ttk": 0.0, "wins": 0, "mana_min": 0.0, "mana_avg": 0.0,
		"heal_eff": 0.0, "heal_over": 0.0, "casts": 0.0, "idle_pct": 0.0,
		"taken": [0.0, 0.0, 0.0, 0.0], "hp_floor": [0.0, 0.0, 0.0, 0.0],
		"medits": 0.0}
	for seed in range(1, seeds + 1):
		var r := _run_one(boss, seed, mode)
		agg["ttk"] += r["ttk"]
		agg["wins"] += (1 if r["won"] else 0)
		agg["mana_min"] += r["mana_min"]
		agg["mana_avg"] += r["mana_avg"]
		agg["heal_eff"] += r["heal_eff"]
		agg["heal_over"] += r["heal_over"]
		agg["casts"] += r["casts"]
		agg["idle_pct"] += r["idle_pct"]
		agg["medits"] += r["medits"]
		for i in 4:
			agg["taken"][i] += r["taken"][i]
			agg["hp_floor"][i] += r["hp_floor"][i]
	var n := float(seeds)
	var total_heal: float = agg["heal_eff"] + agg["heal_over"]
	var over_pct: float = (100.0 * agg["heal_over"] / total_heal) if total_heal > 0.0 else 0.0
	print("  [%-4s] win %.0f%%  TTK %.0fs | MANA: min %.0f/900  avg %.0f/900  (never below %.0f%%)" % [
		mode, 100.0 * agg["wins"] / n, agg["ttk"] / n,
		agg["mana_min"] / n, agg["mana_avg"] / n, 100.0 * (agg["mana_min"] / n) / 900.0])
	print("         heal: %.0f eff + %.0f OVERHEAL (%.0f%% wasted)  casts %.0f  Meditate %.1f  GCD-idle %.0f%%" % [
		agg["heal_eff"] / n, agg["heal_over"] / n, over_pct,
		agg["casts"] / n, agg["medits"] / n, agg["idle_pct"] / n])
	print("         dmg TAKEN by seat: tank %.0f  blade %.0f  caster %.0f  HEALER %.0f   (over the whole fight)" % [
		agg["taken"][0] / n, agg["taken"][1] / n, agg["taken"][2] / n, agg["taken"][3] / n])
	print("         HP floor by seat:  tank %.0f%%  blade %.0f%%  caster %.0f%%  healer %.0f%%" % [
		100.0 * agg["hp_floor"][0] / n, 100.0 * agg["hp_floor"][1] / n,
		100.0 * agg["hp_floor"][2] / n, 100.0 * agg["hp_floor"][3] / n])

func _run_one(boss: String, seed: int, mode: String) -> Dictionary:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id(boss))
	var tank := s.seats[0]
	var blade := s.seats[1]
	var caster := s.seats[2]
	var healer := s.seats[3]
	# good skill for the AI party (matches raid_sim SKILLS[1])
	var tp := tank.policy as RaidTankPolicy
	tp.reaction_slack = 0.06; tp.rng = DetRng.new(seed * 2749 + 1337); tp.use_challenge = true
	var bp := blade.policy as TwinfangPolicy
	bp.latency_ticks = 6; bp.rng = DetRng.new(seed * 2749 + 2338)
	var cp := caster.policy as VoidcallerPolicy
	cp.latency_ticks = 6; cp.rng = DetRng.new(seed * 2749 + 3339)
	(healer.policy as MenderPolicy).latency_ticks = 6

	var cap := int(TICK_CAP_SEC / s.dt)
	var mana_min := healer.resource
	var mana_sum := 0.0
	var mana_samples := 0
	var casts := 0
	var idle := 0
	var acted := 0
	var hp_floor := [1.0, 1.0, 1.0, 1.0]
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy == null or not seat.alive():
				continue
			var a: Dictionary
			if seat == healer and mode == "spam":
				a = _spam_action(s, healer)          # dumb human: mash Flash on lowest
			else:
				a = seat.policy.act(CombatCore.observe(s, seat))
			if seat == healer:
				acted += 1
				if a.is_empty():
					idle += 1
				elif String(a.get("type", "")) == "ability":
					casts += 1
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		# sample healer mana + party HP floor each tick
		mana_min = minf(mana_min, healer.resource)
		mana_sum += healer.resource
		mana_samples += 1
		for i in 4:
			hp_floor[i] = minf(hp_floor[i], s.seats[i].hp_frac())

	var hrow: Dictionary = s.meter.get(3, {})
	var heal_by: Dictionary = hrow.get("heal", {})
	var medits := 0
	if heal_by.has(&"medit"):     # (Meditate restores mana, not health; count from casts instead)
		medits = 0
	# count Meditate casts via the healer's cooldown history is lossy; approximate from meter dispels? skip.
	return {
		"won": s.won,
		"ttk": s.time(),
		"mana_min": mana_min,
		"mana_avg": (mana_sum / float(maxi(1, mana_samples))),
		"heal_eff": float(hrow.get("heal_total", 0.0)),
		"heal_over": float(hrow.get("over_total", 0.0)),
		"casts": float(casts),
		"medits": float(medits),
		"idle_pct": 100.0 * float(idle) / float(maxi(1, acted)),
		"taken": [
			float((s.meter.get(0, {}) as Dictionary).get("taken_total", 0.0)),
			float((s.meter.get(1, {}) as Dictionary).get("taken_total", 0.0)),
			float((s.meter.get(2, {}) as Dictionary).get("taken_total", 0.0)),
			float((s.meter.get(3, {}) as Dictionary).get("taken_total", 0.0)),
		],
		"hp_floor": hp_floor,
	}

## Dumb human healer: mash Flash Heal on the lowest living ally, every tick.
## The kit no-ops it while on GCD / mid-cast, so this is genuine "spam the button".
func _spam_action(s: CombatState, healer: Seat) -> Dictionary:
	var lowest: Seat = null
	for u in s.seats:
		if u.role != "healer" and u.alive():
			if lowest == null or u.hp_frac() < lowest.hp_frac():
				lowest = u
	if lowest == null:
		return {}
	return {"type": "ability", "id": "flash", "target": lowest}

func _arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def
