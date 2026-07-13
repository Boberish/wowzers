## DuelistPolicy — the dodge-tank AI on the SAME Policy interface a human's keyboard adapter
## uses (human / AI / sim seats are interchangeable — load-bearing for solo + backfill). Pure/
## deterministic: reads the observation, emits one action. Rebuilt for tank-v2 (TANK-PLAN §0):
## the policy reads the COMMITTED STREAM — exactly the comets a human sees on the channel,
## including the purple tell (never the true feint flag) and LATE bars only once they pop.
##
## THE BRAIN is the SHAPE-LAW matrix (2026-07-13):
##   ◇ AUTO / light beat    → DODGE (cheap bread; parry when the bank is hungry and wind is fat)
##   ⯃ HEAVY / BUSTER       → PARRY ONLY (the commit; a land hits back + banks ◆ — dodge is illegal,
##                            so a too-winded tank just holds and eats it)
##   ⬡ GLOBAL (aoe beat)    → DODGE (every seat's answer; never parry)
##   ⬡ FLURRY MODE          → DODGE every beat (wind-free, don't miss one)
##   PURPLE (the tell)      → hold — only a sloppy tank flinches
##   nothing incoming + ◆   → ⚡ DUMP
## Skill tiers ride `latency_ticks` (expert 0 / good 6 / sloppy 14–18): reaction delay pushes
## presses later → BULLSEYEs become GOODs → flow thins → the boss peels — a visible gradient.
## `rng` is a SEPARATE per-policy stream (never state.rng); null = a human seat.
class_name DuelistPolicy
extends Policy

var latency_ticks: int = 0
var rng: DetRng = null
var _flinch_id: int = -1        # the purple bar we last rolled a flinch for (one roll per bar)
var _flinch: bool = false
var _react_key: int = -1        # the bar/telegraph the current smear was rolled for
var _react: float = 0.08

## The press moment for THIS bar — rolled ONCE per bar (a per-tick re-roll would fire on the
## earliest sample and turn every mid-tier press into a graze; one roll = a uniform press
## point inside the tier's smear, the honest gradient). `focus` models ATTENTION: a human
## gives the big obvious bar their best timing — heavies/busters get half the smear, so a
## mid-tier tank lands a real share of parries (the binary window is elite-tight by design).
func _react_for(key: int, focus := false) -> float:
	if key != _react_key:
		_react_key = key
		_react = 0.08
		if rng != null and latency_ticks > 0:
			_react += rng.next_float() * (float(latency_ticks) / (45.0 if focus else 22.0))
	return _react

func act(obs: Dictionary) -> Dictionary:
	if bool(obs.get("fumbling", false)):
		return {}
	var tg: Dictionary = obs.get("telegraph", {})
	var wind := float(obs.get("wind", 10.0))
	var parry_cost := float(obs.get("parry_cost", 3.5))
	var dodge_cost := float(obs.get("dodge_cost", 1.0))
	var combo := int(obs.get("combo", 0))
	var combo_max := int(obs.get("combo_max", 5))
	var answering := String(obs.get("answering", ""))
	var parry_ready := bool(obs.get("parry_ready", true))
	var dodge_ready := bool(obs.get("dodge_ready", true))
	var in_flurry := bool(obs.get("flurry", false))
	# the timing model: every tier AIMS at the window center (press ~0.08s before impact);
	# skill = NOISE, not a shifted window — the smear rolls once per bar (_react_for), so
	# expert stays in the bullseye/perfect core while good drifts to good/graze and sloppy
	# sprays across the ladder — the visible gradient, without a tier that only ever grazes.

	# 0) THE STREAM — the committed bars, nearest first (peeled ones too: answering them
	#    is the aggro comeback — pass 2). Skip what's already answered and the eats.
	var stream: Dictionary = obs.get("stream", {})
	var bars: Array = stream.get("bars", [])
	var b: Dictionary = {}
	for cand_v in bars:
		var cand: Dictionary = cand_v
		if bool(cand.get("answered", false)) or String(cand.get("kind", "")) == "eat":
			continue
		b = cand
		break
	if not b.is_empty() and answering == "":
		var eta := float(b.get("eta", 99.0))
		var bk := String(b.get("kind", "auto"))
		var react := _react_for(int(b.get("id", -1)), bk == "heavy" or bk == "buster")
		if eta <= react:
			if bool(b.get("purple", false)):
				# the tell: HOLD. Only a sloppy tank flinches (one roll per bar).
				if int(b.get("id", -1)) != _flinch_id:
					_flinch_id = int(b.get("id", -1))
					_flinch = rng != null and latency_ticks > 0 \
						and rng.next_float() < float(latency_ticks) / 60.0
				if _flinch and dodge_ready:
					return {"type": "dodge"}
				return {}
			match String(b.get("kind", "auto")):
				"flurry":
					if dodge_ready:
						return {"type": "dodge"}           # wind-free in the mode
				"heavy", "buster":
					# ⯃ octagon = PARRY ONLY; too winded to parry → hold and eat it (dodge is illegal)
					if parry_ready and wind >= parry_cost:
						return {"type": "defense"}         # the commit
				_:
					# AUTO: dodge is the bread; parry instead when the bank is hungry + wind is fat
					if combo < combo_max and wind >= parry_cost + dodge_cost * 2.0 and parry_ready:
						return {"type": "defense"}
					if dodge_ready and wind >= dodge_cost:
						return {"type": "dodge"}
					if parry_ready and wind >= parry_cost:
						return {"type": "defense"}
			return {}

	# 1) a telegraph BUSTER aimed at me (no beats) → PARRY at the impact window.
	if not tg.is_empty() and bool(tg.get("targets_me", false)) and bool(tg.get("defensible", false)) \
			and (tg.get("strikes", []) as Array).is_empty():
		var rem := float(tg.get("remaining", 99.0))
		if rem <= _react_for(int(tg.get("tick", -1)), true) and parry_ready and wind >= parry_cost \
				and answering != "parry":
			return {"type": "defense"}
		return {}                                          # hold — wait for the window

	# 2) telegraph beats: ⬡ GLOBAL (aoe) + ◇ light personal beat → DODGE · ⯃ HEAVY personal
	#    beat → PARRY (octagon; dodge is illegal).
	var beats: Array = tg.get("strikes", [])
	for bt in beats:
		if bool(bt.get("resolved", false)) or not (bool(bt.get("mine", false)) or bool(bt.get("aoe", false))):
			continue
		var bt_heavy := not bool(bt.get("aoe", false)) \
			and int(bt.get("size", AbilityRes.Size.LIGHT)) >= AbilityRes.Size.HEAVY
		if float(bt.get("remaining", 99.0)) <= _react_for(int(tg.get("tick", -1)), bt_heavy) \
				and answering == "":
			if bt_heavy:
				if parry_ready and wind >= parry_cost:
					return {"type": "defense"}     # ⯃ parry the heavy beat
			elif dodge_ready:
				return {"type": "dodge"}           # ◇/⬡ dodge the light beat / global

	# 3) ⚡ DUMP a full ◆ bank when nothing is incoming
	if not in_flurry and combo >= combo_max and answering == "":
		return {"type": "ability", "id": "dump"}
	return {}
