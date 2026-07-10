## DuelistPolicy — a competent dodge-tank AI on the SAME Policy interface a human's keyboard
## adapter uses (so human / AI / sim seats are interchangeable; load-bearing for solo + backfill,
## TANK-PLAN §1d). Pure/deterministic: reads the observation, emits one action.
##
## THE JOB (and why it holds aggro for free): the tank builds FLOW by answering its dense bar
## stream — a clean answer raises flow, and flow ≥ the lock floor holds the boss (no aggro code;
## legibility is the requirement — a human squishy peeled by an AI slip must read WHY off the flow
## bar). So the brain is just "answer well, by the height law":
##   • a TALL bar (CRUSH) — buster or beat → PARRY (main): answers any size, a perfect hits back (◆).
##   • a small/normal bar / the melee chip → DODGE (secondary): cheap, keeps flow up (the footwork).
##   • a FEINT beat → READ it (don't press); a sloppy tank flinches sometimes (wasted wind).
##   • nothing incoming + a full ◆ bank → ⚡ DUMP.
##
## THE SKILL TIERS ride `latency_ticks` (S2: expert 0 / good 6 / sloppy 14–18): reaction delay that
## pushes the press later → PERFECTs become GOODs/GRAZEs → flow thins → the boss peels → deaths
## climb, a visible gradient. `rng` is a SEPARATE per-policy stream (never state.rng) for the skill
## jitter (press smear + the feint flinch); null = a human seat (the human makes the read).
class_name DuelistPolicy
extends Policy

var latency_ticks: int = 0
var rng: DetRng = null
var _last_dodge_tick: int = -1000
var _feint_key: int = -1        # the barrage we last rolled a flinch for (one roll per string)
var _feint_flinch: bool = false

func act(obs: Dictionary) -> Dictionary:
	var tg: Dictionary = obs.get("telegraph", {})
	var tick := int(obs.get("tick", 0))
	var wind := float(obs.get("wind", 10.0))
	var parry_cost := float(obs.get("parry_cost", 3.5))
	var dodge_cost := float(obs.get("dodge_cost", 1.0))
	var combo := int(obs.get("combo", 0))
	var combo_max := int(obs.get("combo_max", 5))
	var answering := String(obs.get("answering", ""))
	var parry_ready := bool(obs.get("parry_ready", true))
	var dodge_ready := bool(obs.get("dodge_ready", true))
	if bool(obs.get("fumbling", false)):
		return {}
	# the reaction window (seconds before impact the AI commits) — latency + a per-tier smear
	var react := 0.10 + float(latency_ticks) / 30.0
	if rng != null and latency_ticks > 0:
		react += (rng.next_float() - 0.5) * (float(latency_ticks) / 30.0)
	react = maxf(0.03, react)

	# 0) THE RHYTHM bar (BOSS-PLAN §3½) — my visible auto-attack stream. Dodge it on the
	#    read like any small bar (checked FIRST: a bar can impact mid-wind-up of a real
	#    telegraph, and the sooner press wins). Falls through while it isn't due yet.
	var ry: Dictionary = obs.get("rhythm", {})
	if not ry.is_empty() and answering == "":
		var rrem := float(ry.get("remaining", 99.0))
		if rrem <= react:
			if dodge_ready and wind >= dodge_cost:
				return {"type": "dodge"}
			if parry_ready and wind >= parry_cost:
				return {"type": "defense"}               # wind-tight fallback

	# 1) a single DEFENSIBLE buster aimed at me → PARRY (main): it's a big hit, and a perfect
	#    parry hits back + banks ◆. Time it for the impact window.
	if not tg.is_empty() and bool(tg.get("targets_me", false)) and bool(tg.get("defensible", false)):
		var rem := float(tg.get("remaining", 99.0))
		if rem <= react and parry_ready and wind >= parry_cost and answering != "parry":
			return {"type": "defense"}
		return {}                                        # hold — wait for the impact window

	# 2) a barrage string → answer each beat by the HEIGHT LAW as it lands (the WEAVE).
	var beats: Array = tg.get("strikes", [])
	if not beats.is_empty():
		var key := int(tg.get("tick", -1))
		if key != _feint_key:                            # roll the flinch ONCE per string (skill)
			_feint_key = key
			_feint_flinch = rng != null and latency_ticks > 0 and rng.next_float() < float(latency_ticks) / 60.0
		for b in beats:
			if bool(b.get("resolved", false)):
				continue
			if not (bool(b.get("mine", false)) or bool(b.get("aoe", false))):
				continue
			var brem := float(b.get("remaining", 99.0))
			if brem > react:
				continue
			var sz := int(b.get("size", AbilityRes.Size.LIGHT))
			if bool(b.get("feint", false)):
				# READ it — pressing a feint wastes wind; only a sloppy tank flinches
				if _feint_flinch and dodge_ready and wind >= dodge_cost:
					return {"type": "dodge"}
				continue
			if sz >= AbilityRes.Size.CRUSH and parry_ready and wind >= parry_cost:
				return {"type": "defense"}               # tall beat → PARRY (the main)
			if dodge_ready and wind >= dodge_cost:
				return {"type": "dodge"}                  # small/normal beat → DODGE
			if parry_ready and wind >= parry_cost:
				return {"type": "defense"}                # wind-tight fallback
		return {}

	# 3) ⚡ DUMP a full ◆ bank when nothing is incoming
	if combo >= combo_max and wind >= dodge_cost:
		return {"type": "ability", "id": "dump"}

	# 4) the melee chip — DODGE on its rhythm ALWAYS (the dense footwork IS the mitigation, and a
	#    dodged bar feeds flow as a byproduct). Rate-limited to the melee cadence so it never starves
	#    the wind pool; slower when sloppy (latency widens the gap → thinner flow → the peel gradient).
	#    RHYTHM-LESS content only — a §3½ fight exposes the real bar (step 0) and this blind
	#    metronome would just bleed wind between bars.
	var min_gap := 26 + latency_ticks
	if ry.is_empty() and answering == "" and dodge_ready and wind >= dodge_cost + 1.0 \
			and tick - _last_dodge_tick >= min_gap:
		_last_dodge_tick = tick
		return {"type": "dodge"}
	return {}
