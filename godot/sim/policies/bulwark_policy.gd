## BulwarkPolicy — a competent tank AI. The SAME Policy interface a human's keyboard
## adapter uses, so human and AI seats are interchangeable (solo/co-op fill + sims).
##
## Priorities: survive the big swings, keep rage flowing, cash out the spec resource.
## Deliberately EATS light jabs for rage (defending them wastes the cooldown you need
## for the Slam) — the same read a good human makes.
##
## `reaction_slack` is a skill knob (seconds of sloppiness). 0 = frame-perfect;
## raise it to model weaker play and produce win-rate BANDS in sims.
class_name BulwarkPolicy
extends Policy

var reaction_slack: float = 0.0
## Diagnostic knob: when true the AI reads every Feint perfectly (never flinches),
## so a sim can isolate how much of the Duelist's difficulty is the feint mechanic.
var perfect_feint_read: bool = false
## Per-policy PRNG for stochastic reads (the Duelist feint flinch). SEPARATE from the
## authoritative state RNG (never touches it), seeded per run by the sim so results
## stay reproducible. Left null for a human seat (the human makes the read).
var rng: DetRng = null
var _feint_tick: int = -1        # the feint we last rolled a read for
var _feint_flinched: bool = false
# M7 string beats: one aim/flinch roll per beat (cached per string), same
# reproducible per-policy rng as the whole-swing feint model.
var _beat_key: int = -1
var _beat_aims: Dictionary = {}
var _beat_flinches: Dictionary = {}

func act(obs: Dictionary) -> Dictionary:
	var tg: Dictionary = obs.get("telegraph", {})

	# 0) M7 string: answer each beat with the universal dodge, aimed just inside
	# the PERFECT window and smeared by skill. A feint beat is HELD unless the
	# skill roll flinches (dodging the fake = BAITED, and the lockout eats the
	# finisher — the same discipline test as the whole-swing feints).
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
				break                       # holding the fake — wait it out, never skip ahead
			if rem <= _beat_aim(tg, i):
				return {"type": "dodge"}
			break                           # next beat not in range yet

	# 1) Defend an incoming defensible swing, timed to its "zone", if it's worth it.
	if not tg.is_empty() and tg.get("defensible", false) and tg.get("targets_me", false) \
			and obs.get("defense_ready", false):
		var size := int(tg.get("size", 0))
		var aspect := String(obs.get("aspect", "warden"))
		var zone := float(obs.get("def_zone", 0.3))
		var in_window := float(tg.get("remaining", 99.0)) <= zone + reaction_slack
		# Warden parries heavies+crush (banks Counter); Juggernaut only bothers with
		# crush (eats heavies to keep its Momentum snowball alive).
		var worth := size >= AbilityRes.Size.CRUSH if aspect == "juggernaut" \
				else size >= AbilityRes.Size.HEAVY
		if bool(tg.get("feint", false)):
			# Duelist: a Feint must be HELD, never guarded. A sloppy read flinches and
			# commits guard as the swing bears down (in_window) — and committing guard to
			# a feint takes the bait at ANY timing (the engine punishes the press itself).
			if worth and in_window and _flinches(tg):
				return {"type": "defense"}
			# else hold — fall through to offense (and reap the Exposed reward)
		elif worth and in_window:
			return {"type": "defense"}

	# Everything below is GCD-gated.
	if not obs.get("gcd_ready", false):
		return {}

	var rage := float(obs.get("rage", 0.0))
	var aspect2 := String(obs.get("aspect", "warden"))

	# 2) Emergency self-heal.
	if float(obs.get("my_hp_frac", 1.0)) < 0.5 and rage >= 30.0:
		return {"type": "ability", "id": "fortify"}

	# 3) Spec spender.
	if aspect2 == "warden":
		if bool(obs.get("riposte_active", false)):
			return {"type": "ability", "id": ("rampage" if rage >= 40.0 else "cleave")}
		if int(obs.get("counter", 0)) >= 4:
			return {"type": "ability", "id": "vindicate"}
	else:
		if int(obs.get("momentum", 0)) >= 8 and rage >= 20.0:
			return {"type": "ability", "id": "avalanche"}

	# 4) Rage dump, else 5) free filler.
	if rage >= 40.0:
		return {"type": "ability", "id": "rampage"}
	return {"type": "ability", "id": "cleave"}

## Does the player misread THIS feint and guard the bait? One roll per feint (cached
## across the swing's in-window ticks), scaled by skill: expert (slack 0) never bites,
## and the flinch chance climbs with sloppiness. Uses the per-policy rng (seeded per
## run) so it's stochastic yet fully reproducible.
func _flinches(tg: Dictionary) -> bool:
	if perfect_feint_read or reaction_slack <= 0.0 or rng == null:
		return false
	var t := int(tg.get("tick", 0))
	if t != _feint_tick:
		_feint_tick = t
		_feint_flinched = rng.next_float() < minf(0.8, reaction_slack * 5.0)
	return _feint_flinched

## When (seconds-before-impact) this policy presses for beat `i` — rolled ONCE per
## beat per string. 0.10 sits inside the PERFECT window; slack smears it both ways
## (a big negative roll = the press never comes = an eaten beat).
func _beat_aim(tg: Dictionary, i: int) -> float:
	_beat_reset(tg)
	if not _beat_aims.has(i):
		var noise := 0.0
		if rng != null and reaction_slack > 0.0:
			noise = (rng.next_float() * 2.0 - 1.0) * reaction_slack * 2.0
		_beat_aims[i] = 0.10 + noise
	return float(_beat_aims[i])

## Does this policy dodge the fake at beat `i`? One roll per beat, skill-scaled.
func _beat_flinch(tg: Dictionary, i: int) -> bool:
	if perfect_feint_read or reaction_slack <= 0.0 or rng == null:
		return false
	_beat_reset(tg)
	if not _beat_flinches.has(i):
		_beat_flinches[i] = rng.next_float() < minf(0.8, reaction_slack * 5.0)
	return bool(_beat_flinches[i])

func _beat_reset(tg: Dictionary) -> void:
	var t := int(tg.get("tick", 0))
	if t != _beat_key:
		_beat_key = t
		_beat_aims = {}
		_beat_flinches = {}
