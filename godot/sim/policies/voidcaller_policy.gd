## VoidcallerPolicy — a competent AI caster DPS. Reads the boss's cast bar and kicks it
## (the verb), Barriers the uninterruptible channels, casts Fracture/Bolt for damage +
## Focus, and pops the signature (Overload / Quietus). The same Policy a human's input
## adapter fills (human = AI seat).
##
## `latency_ticks` is the skill knob, and for a caster it degrades DISCIPLINE, not just
## reflex: an expert saves its single interrupt for the Mending (and lands it CLEAN for
## the bonus); a sloppy hand kicks reactively — wasting the interrupt on a nuke so the
## heal lands and the boss out-heals the fight. Deterministic — no RNG in the policy.
class_name VoidcallerPolicy
extends Policy

var latency_ticks: int = 0
var _tg_id: int = -1
var _tg_seen: int = 0
## M7 string beats: per-policy rng (seeded by the sim) smears the per-beat dodge
## aim by latency and rolls feint flinches — one roll per beat, cached per string.
var rng: DetRng = null
var _beat_key: int = -1
var _beat_aims: Dictionary = {}
var _beat_flinches: Dictionary = {}

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
	var aspect := String(obs.get("aspect", "disruptor"))
	var focus := float(obs.get("focus", 0.0))
	var disciplined := latency_ticks <= 8

	# 0) M7 string: dodge each beat (a landed beat also pushes your Fracture back —
	#    footwork protects the cast bar). Feints held unless the skill roll flinches.
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
				break
			if rem <= _beat_aim(tg, i):
				return {"type": "dodge"}
			break

	# 1) INTERRUPT — off-GCD, its own cooldown. Kick the current cast whenever the
	#    interrupt is up (heals prolong the fight, empowers compound, nukes chip — all
	#    worth stopping). The skill is the TIMING: an expert waits for the CLEAN window
	#    (last slice → bonus Backlash / longer Silence); a sloppy hand kicks early.
	if reacted and not tg.is_empty() and bool(tg.get("interruptible", false)) \
			and bool(obs.get("defense_ready", false)):
		if not disciplined:
			return {"type": "defense"}                # kick early — not clean, less reward
		if float(tg.get("remaining", 9.0)) <= float(obs.get("clean_zone", 0.62)):
			return {"type": "defense"}                # aim for a CLEAN interrupt

	# 2) BARRIER an incoming uninterruptible channel (big) before it lands — but never
	#    burn it on a string (those are answered with the dodge, step 0).
	if _can_cast(obs) and not tg.is_empty() and not bool(tg.get("interruptible", false)) \
			and not tg.has("strikes") \
			and int(tg.get("size", 0)) >= AbilityRes.Size.HEAVY \
			and bool(obs.get("barrier_ready", false)) and not bool(obs.get("barrier_active", false)):
		return _ab("barrier")

	if not _can_cast(obs):
		return {}

	# 3) Signature.
	if aspect == "disruptor" and int(obs.get("backlash", 0)) >= 4:
		return _ab("overload")                        # dump Backlash → next Fracture instant
	if aspect == "silencer" and bool(obs.get("quietus_ready", false)) and focus >= 30.0 \
			and not tg.is_empty() and bool(tg.get("interruptible", false)):
		return _ab("quietus")                         # cancel a cast + hard silence + Exposed → burst

	# 4) Cast rotation: Fracture when Focus allows, else Bolt to build Focus.
	if focus >= 26.0:
		return _ab("fracture")
	return _ab("bolt")

func _can_cast(obs: Dictionary) -> bool:
	return (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true))

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
		_beat_flinches[i] = rng.next_float() < minf(0.8, float(latency_ticks) * 0.045)
	return bool(_beat_flinches[i])

func _beat_reset(tg: Dictionary) -> void:
	var t := int(tg.get("tick", 0))
	if t != _beat_key:
		_beat_key = t
		_beat_aims = {}
		_beat_flinches = {}

func _ab(id: String) -> Dictionary:
	return {"type": "ability", "id": id}
