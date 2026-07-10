## WellPolicy — the AI healer for the reworked class (both specs). The same Policy a
## human's click-cast + hold-release adapter replaces. Deterministic: no state.rng; a
## per-policy DetRng (set by the sim) drives skill jitter only.
##
## Skill knob = latency_ticks: gates decision cadence (slower triage), AND — for DRAW —
## smears the release timing off the STILL POINT / into an UNDERCOOK, AND — for BRIM —
## occasionally mis-sizes a heal (spill/plain instead of a pour). So expert pours/holds
## clean and sloppy wastes; the gradient is real.
class_name WellPolicy
extends Policy

const COST := {"flash": 2, "mend": 1, "skin": 1, "cascade": 3, "spring": 4, "dispel": 0, "rekindle": 6}
const RELEASE_BIAS := 1     # compensate the 1-tick input-enqueue delay so aim centres

var latency_ticks: int = 0
var rng: DetRng = null
var _next_act: int = 0
var _release_at: int = -1

func act(obs: Dictionary) -> Dictionary:
	var tick := int(obs.get("tick", 0))
	var aspect := String(obs.get("aspect", "brim"))

	# DRAW: fire a planned release at its tick (aimed at the Still Point). Emergencies are
	# handled by CASTING FLASH (fast, full heal) rather than undercooking a held mend.
	if _release_at >= 0:
		if obs.get("casting", {}).is_empty():
			_release_at = -1
		elif tick >= _release_at:
			_release_at = -1
			return {"type": "ability", "id": "release"}
		else:
			return {}

	# dodge an incoming aoe beat aimed at me (cancel a cast if need be — the design tension)
	if bool(obs.get("dodge_ready", false)):
		var tg: Dictionary = obs.get("telegraph", {})
		for b in tg.get("strikes", []):
			if bool(b.get("resolved", false)) or bool(b.get("answered", false)) \
					or not bool(b.get("mine", true)) or bool(b.get("feint", false)):
				continue
			if int(b.get("guard", 0)) == StrikeRes.Guard.UNANSWERABLE:
				continue
			if float(b.get("remaining", 9.0)) <= 0.14:
				_next_act = tick + 1 + latency_ticks
				return {"type": "dodge"}
			break

	# busy with a cast: for DRAW, make sure a release is scheduled, then wait
	var casting: Dictionary = obs.get("casting", {})
	if not casting.is_empty():
		# a HELD heal is cocked (⭐Vigil / Patient Hand) — release it on the spike or the gutter.
		if bool(casting.get("held", false)):
			return _decide_held(obs, tick, casting)
		# a normal draw cast runs: schedule its release — UNLESS we mean to BANK a held heal
		# (hold armed + a danger hit incoming to release into + nobody dying right now).
		if aspect == "draw" and _release_at < 0 and not _bank_hold(obs):
			_plan_release(obs, tick)
		return {}

	if tick < _next_act:
		return {}
	var action := _choose(obs, aspect)
	if not action.is_empty():
		_next_act = tick + 1 + latency_ticks
	return action

func _plan_release(obs: Dictionary, tick: int) -> void:
	var start := int(obs.get("cast_start", tick))
	var dur := int(obs.get("cast_dur", 1))
	var band := float(obs.get("draw_band", 0.15))
	var centre := start + int(round(float(dur) * (1.0 - band * 0.5)))
	var jit := 0
	if rng != null and latency_ticks > 0:
		jit = int(round((rng.next_float() * 2.0 - 1.0) * float(latency_ticks) * 0.6))
	_release_at = maxi(start + 1, centre - RELEASE_BIAS + jit)

func _choose(obs: Dictionary, aspect: String) -> Dictionary:
	var party: Array = obs.get("party", [])
	if party.is_empty():
		return {}
	var charges := int(obs.get("charges", 0))

	# lowest + 2nd-lowest living ally + hurt count
	var lowest: Dictionary = {}
	var second: Dictionary = {}
	var hurt := 0
	for p in party:
		if p["dead"]:
			continue
		if float(p["frac"]) < 0.7:
			hurt += 1
		if lowest.is_empty() or float(p["frac"]) < float(lowest["frac"]):
			second = lowest
			lowest = p
		elif second.is_empty() or float(p["frac"]) < float(second["frac"]):
			second = p
	# sloppy hands slip off the priority target (heal 2nd-lowest → the real lowest keeps
	# dropping, and the mis-timed heal is likelier to spill). Expert always nails the lowest.
	if not second.is_empty() and float(lowest["frac"]) >= 0.35 \
			and rng != null and latency_ticks > 0 and rng.next_float() < float(latency_ticks) * 0.045:
		lowest = second

	# 1) Dispel (free, off-GCD)
	for p in party:
		if not p["dead"] and p["debuff"]:
			return _cast("dispel", p["seat"])

	# 2) Group throughput when several are hurt (attrition demands AoE)
	if hurt >= 3 and charges >= COST["spring"] and _ready(obs, "spring"):
		return _cast("spring")
	if hurt >= 2 and charges >= COST["cascade"] and _ready(obs, "cascade"):
		return _cast("cascade")

	# 3) Battle-rez a fallen raider when nobody living is critical and we can afford it
	if bool(obs.get("raid", false)) and charges >= COST["rekindle"]:
		var critical := not lowest.is_empty() and float(lowest["frac"]) < 0.35
		if not critical:
			for p in party:
				if p["dead"]:
					return _cast("rekindle", p["seat"])

	# 3b) SKIN — film the tank AHEAD of a danger hit (the missing-heal answer): re-times the
	# spike so the cast bar can come around. It's the QUIET-MINUTE job, never a stolen heal —
	# only fires with real slack (party comfortable + a heal kept in reserve), so it can't
	# starve triage. A danger telegraph is imminent and the tank isn't already filmed.
	if charges >= COST["skin"] + COST["mend"] and _lowest_frac(obs) >= 0.6:
		var tg: Dictionary = obs.get("telegraph", {})
		if bool(tg.get("danger", false)) and float(tg.get("remaining", 9.0)) <= 2.2:
			for p in party:
				if not p["dead"] and String(p["role"]) == "tank" \
						and not bool(p.get("skin", false)) and float(p["frac"]) >= 0.6:
					return _cast("skin", p["seat"])

	if lowest.is_empty():
		return {}

	# 4) Single-target — spec-specific
	if aspect == "brim":
		return _brim_single(obs, lowest, charges)
	return _draw_single(obs, lowest, charges)

## BRIM: keep the party UP first, and PREFER the spell that pours (lands in band, no
## spill). Survival never waits on a pour — that is the whole triage job. The skill
## (expert vs sloppy) shows in HOW OFTEN the heal pours (Glint uptime, kill speed): the
## sloppy hand mis-sizes and the latency gate lands its heals late.
func _brim_single(obs: Dictionary, lowest: Dictionary, charges: int) -> Dictionary:
	if charges < COST["mend"]:
		return {}
	var seat: Seat = lowest["seat"]
	var frac := float(lowest["frac"])
	var band := float(obs.get("brim_band", 0.90))
	if frac >= 0.85:
		return {}                                    # topped enough — don't spill
	var missing := seat.hp_max - seat.hp
	var mend_pours := 95.0 <= missing + cfg_eps() and frac + 95.0 / seat.hp_max >= band
	var flash_pours := 70.0 <= missing + cfg_eps() and frac + 70.0 / seat.hp_max >= band
	var mis := rng != null and latency_ticks > 0 and rng.next_float() < float(latency_ticks) * 0.05

	# a pour is available → take it (sloppy hands sometimes fumble the size)
	if mend_pours:
		if mis and charges >= COST["flash"]:
			return _cast("flash", seat)              # over-heals → SPILL
		return _cast("mend", seat)
	if flash_pours and charges >= COST["flash"]:
		if mis:
			return _cast("mend", seat)               # over-heals → SPILL
		return _cast("flash", seat)
	# no clean pour, but they still need healing — SURVIVE (plain/spill is fine)
	if missing >= 70.0:
		return _cast("mend", seat)                   # big deficit: efficient mend (lands < band = plain)
	if charges >= COST["flash"]:
		return _cast("flash", seat)                  # small deficit: fast flash (may spill)
	return _cast("mend", seat)

## DRAW: MEND-heavy (1 charge) and let THE CURRENT supply the speed — riding the streak,
## not spamming Flash, is the design (a dry well breaks the Current, so greed self-limits).
## Flash only for a true critical. The pour/Current comes from the release TIMING (skill).
func _draw_single(_obs: Dictionary, lowest: Dictionary, charges: int) -> Dictionary:
	if charges < COST["mend"]:
		return {}
	var seat: Seat = lowest["seat"]
	var frac := float(lowest["frac"])
	if frac >= 0.85:
		return {}
	if frac < 0.35 and charges >= COST["flash"]:
		return _cast("flash", seat)                  # critical: fast, full
	return _cast("mend", seat)                       # ride the Current for speed

## The lowest living-ally HP fraction (1.0 if the party is empty/all topped) — the triage read.
func _lowest_frac(obs: Dictionary) -> float:
	var lo := 1.0
	for p in obs.get("party", []):
		if not p["dead"]:
			lo = minf(lo, float(p["frac"]))
	return lo

## The lowest living-ally party ENTRY ({} if none) — for aiming an off-hand cast.
func _lowest_seat(obs: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for p in obs.get("party", []):
		if p["dead"]:
			continue
		if best.is_empty() or float(p["frac"]) < float(best["frac"]):
			best = p
	return best

## Should the running draw cast be BANKED into a held heal instead of released now? Only when
## the hold is armed (⭐Vigil / Patient Hand), nobody is dying, and a danger hit is close enough
## to release the held heal into. Otherwise the cast releases normally (the streak/Current game).
func _bank_hold(obs: Dictionary) -> bool:
	if not bool(obs.get("hold_armed", false)):
		return false
	if _lowest_frac(obs) < 0.45:
		return false
	var tg: Dictionary = obs.get("telegraph", {})
	return bool(tg.get("danger", false)) and float(tg.get("remaining", 9.0)) <= 2.5

## A HELD heal is cocked: keep it for the spike, but don't let a SECOND dip fall through —
## SECOND HAND (when drafted) lets an instant off-hand Flash cover a moderate dip while the
## hold stays cocked. A CRITICAL dip looses the full held heal now; the gutter always looses it.
func _decide_held(obs: Dictionary, tick: int, casting: Dictionary) -> Dictionary:
	var until := int(casting.get("held_until", -1))
	if until >= 0 and until - tick <= 6:              # ~0.2s before the gutter — loose it
		return {"type": "ability", "id": "release"}
	var lo := _lowest_frac(obs)
	if lo < 0.4:                                       # critical — the big held heal, full & instant
		return {"type": "ability", "id": "release"}
	# SECOND HAND: a moderate dip while holding — cover it with the off-hand flash, keep the hold.
	if lo < 0.55 and bool(obs.get("secondhand", false)) and int(obs.get("charges", 0)) >= COST["flash"]:
		var s := _lowest_seat(obs)
		if not s.is_empty():
			return {"type": "ability", "id": "flash", "target": s["seat"]}
	if lo < 0.55:                                      # no off-hand available — loose the hold
		return {"type": "ability", "id": "release"}
	return {}

func cfg_eps() -> float:
	return 0.5

func _party_critical(obs: Dictionary) -> bool:
	for p in obs.get("party", []):
		if not p["dead"] and float(p["frac"]) < 0.30:
			return true
	return false

func _ready(_obs: Dictionary, _id: String) -> bool:
	return true                                      # engine no-ops if on cooldown; falls through next tick

func _cast(id: String, target = null) -> Dictionary:
	if target != null:
		return {"type": "ability", "id": id, "target": target}
	return {"type": "ability", "id": id}
