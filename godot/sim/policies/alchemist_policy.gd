## AlchemistPolicy — a competent AI brewer. Rides the vial (release in the sweet band),
## feeds whichever poison is starving (Venom decays 4× faster, so it usually is), holds
## the RUPTURE tap for the ripe peak (fuel AND potency high — the F4 wave), and answers
## swings/beats with the standard footwork. The same Policy a human's input adapter
## replaces (human = AI seat).
##
## `latency_ticks` is the skill knob and it degrades play the way a real hand does:
## the release aim smears off the sweet band (fizzles / spoils), the rupture fires off
## the peak (weak cash-outs), and telegraph reactions arrive late. Per-policy DetRng
## only — never state.rng. Wholly deterministic.
class_name AlchemistPolicy
extends Policy

var latency_ticks: int = 0
var rng: DetRng = null
var _tg_id: int = -1          ## stable id of the telegraph we're tracking
var _tg_seen: int = 0         ## tick we first saw it (reaction delay baseline)
var _beat_key: int = -1
var _beat_aims: Dictionary = {}
var _beat_flinches: Dictionary = {}
## The vial-release aim for the CURRENT charge — rolled once when the hold starts;
## latency smears it off the sweet band the way a rushed thumb does.
var _release_aim: float = 0.74

## Release aim: the sweet band is [0.70, 0.98]; aiming its low edge + the 1-tick
## enqueue delay lands an expert ~0.80. Latency noise pushes pours early (fizzle/ok)
## or deep (hot/spoiled) — the skill gradient IS the vial.
const RELEASE_BASE := 0.74
const RELEASE_NOISE_PER_LAT := 0.022
## Rupture: cash at the ripe peak. ripe_glow = fuel × power ∈ [0,1]; experts hold for
## the true peak (potency ~0.9 on full fuel), sloppy hands cash early and weak.
const RIPE_BASE := 0.93
const RIPE_LOSS_PER_LAT := 0.024
## A charge rides ~1.2s to the sweet band — poison decays IN FLIGHT, so the side to
## feed is the one that will be lower at POUR time, not now (venom fades 4× faster).
const CHARGE_FLIGHT_SEC := 1.2

func act(obs: Dictionary) -> Dictionary:
	var tick := int(obs.get("tick", 0))
	var tg: Dictionary = obs.get("telegraph", {})
	if tg.is_empty():
		_tg_id = -1
	else:
		var id := int(tg.get("tick", -1))
		if id != _tg_id:
			_tg_id = id
			_tg_seen = tick
	var reacted := tg.is_empty() or tick - _tg_seen >= latency_ticks

	# 0) string beats: dodge each one (feints held unless the skill roll flinches).
	var beats: Array = tg.get("strikes", [])
	if not beats.is_empty() and obs.get("dodge_ready", false):
		for i in beats.size():
			var b: Dictionary = beats[i]
			if bool(b.get("resolved", false)) or bool(b.get("answered", false)) \
					or not bool(b.get("mine", true)):
				continue
			if int(b.get("guard", 0)) == StrikeRes.Guard.UNANSWERABLE:
				continue
			var rem := float(b.get("remaining", 9.0))
			if bool(b.get("feint", false)):
				if rem <= _beat_aim(tg, i) and _beat_flinch(tg, i):
					return {"type": "dodge"}
				break                       # holding the fake — never skip ahead of it
			if rem <= _beat_aim(tg, i):
				return {"type": "dodge"}
			break                           # next beat not in range yet

	# 1) dodge the incoming telegraphed swing in its answer window.
	if reacted and not tg.is_empty() and bool(tg.get("defensible", false)) \
			and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)):
		if float(tg.get("remaining", 99.0)) <= float(obs.get("def_zone", 0.42)):
			return {"type": "defense"}

	# 2) the vial is up — ride it to my aim, then pour. (Charging never blocks the
	#    footwork above: the hold persists through a dodge, same as a human's thumb.)
	var charging := String(obs.get("charging", ""))
	if charging != "":
		if float(obs.get("charge", 0.0)) >= _release_aim:
			return {"type": "ability", "id": "pour"}
		return {}

	# 3) the ripe peak — cash the wave. Fuel + potency high, or potency pinned at the
	#    plateau with real fuel banked (no hoarding — the F4 wave law). CREED (Purist): no
	#    Rupture exists — skip entirely and let the reaction plateau (pure sustain).
	if not bool(obs.get("no_rupture", false)):
		var fuel := float(obs.get("brew_min", 0.0))
		var cap := float(obs.get("pot_cap", 1.0))
		if cap < 1.0:
			# CREED (Steady): potency is capped low, so ripe/0.98 never trip — cash near YOUR
			# own ceiling instead (weaker ruptures, but the wave still fires).
			if fuel >= 4.0 and float(obs.get("potency", 0.0)) >= 0.88 * cap:
				return {"type": "ability", "id": "rupture"}
		else:
			var ripe := float(obs.get("ripe_glow", 0.0))
			var ripe_at := maxf(0.4, RIPE_BASE - float(latency_ticks) * RIPE_LOSS_PER_LAT)
			if fuel >= 4.0 and (ripe >= ripe_at or (float(obs.get("potency", 0.0)) >= 0.98 and fuel >= 6.0)):
				return {"type": "ability", "id": "rupture"}

	# 4) feed the starving side — judged at PROJECTED pour time (a charge rides ~1.2s
	#    and Venom fades 4× faster in flight). Both sides at the cap = wait a beat; the
	#    reaction is eating, it'll be hungry again shortly.
	var venom := float(obs.get("venom", 0.0))
	var rot := float(obs.get("rot", 0.0))
	# no saturation (cut): full pours always land, so keep feeding the lower side to the cap
	var feed_to := float(obs.get("cap", 12.0))
	var venom_p := venom - float(obs.get("decay_venom", 2.0)) * CHARGE_FLIGHT_SEC
	var rot_p := rot - float(obs.get("decay_rot", 0.5)) * CHARGE_FLIGHT_SEC
	if minf(venom_p, rot_p) < feed_to:
		_release_aim = RELEASE_BASE               # roll THIS pour's aim once, at the hold
		# CREED (Anchorite): a raised/tighter sweet band — aim its centre, not the base low
		# edge, or every pour grades merely "ok". Base band sits below RELEASE_BASE → no-op.
		var slo := float(obs.get("sweet_lo", 0.70))
		if slo > _release_aim:
			_release_aim = slo + 0.5 * (float(obs.get("sweet_hi", 0.98)) - slo)
		if rng != null and latency_ticks > 0:
			_release_aim += (rng.next_float() * 2.0 - 1.0) * float(latency_ticks) * RELEASE_NOISE_PER_LAT
		return {"type": "ability", "id": "brew_venom" if venom_p <= rot_p else "brew_rot"}
	return {}

# --- M7 beat rolls (cached per string; latency_ticks doubles as the noise knob) ---
func _beat_aim(tg: Dictionary, i: int) -> float:
	_beat_reset(tg)
	if not _beat_aims.has(i):
		var noise := 0.0
		if rng != null and latency_ticks > 0:
			noise = (rng.next_float() * 2.0 - 1.0) * float(latency_ticks) / 30.0
		_beat_aims[i] = 0.10 + noise
	return float(_beat_aims[i])

func _beat_flinch(tg: Dictionary, i: int) -> bool:
	if latency_ticks <= 0 or rng == null:
		return false
	_beat_reset(tg)
	if not _beat_flinches.has(i):
		_beat_flinches[i] = rng.next_float() < minf(0.8, float(latency_ticks) * 0.025)
	return bool(_beat_flinches[i])

func _beat_reset(tg: Dictionary) -> void:
	var t := int(tg.get("tick", 0))
	if t != _beat_key:
		_beat_key = t
		_beat_aims = {}
		_beat_flinches = {}
