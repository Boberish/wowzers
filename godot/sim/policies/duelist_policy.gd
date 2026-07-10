## DuelistPolicy — a competent dodge-tank AI on the SAME Policy interface a human's keyboard
## adapter uses (so human / AI / sim seats are interchangeable; load-bearing for solo + backfill,
## TANK-PLAN §1d). Pure/deterministic: reads the observation, emits one action.
##
## THE JOB (and why it holds aggro for free): the tank builds FLOW by answering its dense bar
## stream — a clean answer raises flow, and flow ≥ the lock floor holds the boss (no aggro code,
## legibility is the requirement). So the brain is just "answer well":
##   1. a big DEFENSIBLE buster aimed at me → PARRY it, timed for a PERFECT (the counter + ◆).
##   2. a barrage string → DODGE each beat (the WEAVE).
##   3. the constant melee chip → DODGE on its rhythm (the dense footwork — each dodge feeds flow).
##   4. nothing incoming + a full ◆ bank → ⚡ DUMP.
##
## `latency_ticks` is the skill knob (S2 tiers: expert 0 / good / sloppy) — reaction delay that
## smears the press timing, turning PERFECTs into GOODs/GRAZEs and thinning flow. `rng` is a
## SEPARATE per-policy stream (never state.rng) for the skill jitter; null = a human seat.
class_name DuelistPolicy
extends Policy

var latency_ticks: int = 0
var rng: DetRng = null
var _last_dodge_tick: int = -1000

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
	# reaction window (seconds before impact the AI presses) — latency + a per-tier jitter smear
	var react := 0.10 + float(latency_ticks) / 30.0
	if rng != null and latency_ticks > 0:
		react += (rng.next_float() - 0.5) * (float(latency_ticks) / 30.0)

	# 1) a big DEFENSIBLE buster aimed at me → PARRY, timed for the perfect (the counter + ◆)
	if not tg.is_empty() and bool(tg.get("targets_me", false)) and bool(tg.get("defensible", false)):
		var rem := float(tg.get("remaining", 99.0))
		if rem <= react and parry_ready and wind >= parry_cost and answering != "parry":
			return {"type": "defense"}
		return {}                                        # hold — wait for the impact window

	# 2) a barrage string → DODGE each beat as it lands (the WEAVE)
	var beats: Array = tg.get("strikes", [])
	if not beats.is_empty():
		for b in beats:
			if bool(b.get("resolved", false)):
				continue
			if not (bool(b.get("mine", false)) or bool(b.get("aoe", false))):
				continue
			var brem := float(b.get("remaining", 99.0))
			if brem <= react and dodge_ready and wind >= dodge_cost:
				return {"type": "dodge"}
		return {}

	# 3) ⚡ DUMP a full ◆ bank when nothing is incoming
	if combo >= combo_max and wind >= dodge_cost:
		return {"type": "ability", "id": "dump"}

	# 4) the melee chip — DODGE on its rhythm ALWAYS (the dense footwork IS the mitigation, and
	#    a dodged bar feeds flow as a byproduct — never stop defending just because aggro is fine).
	#    Rate-limited to the melee cadence so it never starves the wind pool.
	var min_gap := 26 + latency_ticks                    # ~0.87s at 30 Hz (+ slower when sloppy)
	if answering == "" and dodge_ready and wind >= dodge_cost + 1.0 \
			and tick - _last_dodge_tick >= min_gap:
		_last_dodge_tick = tick
		return {"type": "dodge"}
	return {}
