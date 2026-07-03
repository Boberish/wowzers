## TwinfangPolicy — a competent AI melee DPS. Drives the rhythm (Strike in the green
## for Perfects → Flow), spends combo (Eviscerate / Envenom), pops the signature at the
## right moment (Coup at max Flow / Rupture a fat cocktail), Kicks the boss's heal, and
## dodges swings. The same Policy a human's input adapter fills in (human = AI seat).
##
## `latency_ticks` is the skill knob and it degrades play the way a real player does: it
## delays the Perfect timing (missed green → no Flow → less damage) and the dodge. Tempo
## lives or dies on that rhythm; the Venomancer leans on poison (which ignores Flow), so
## it stays strong even at a sloppy tempo — the source's "setup and payoff, not
## execution." Wholly deterministic — no RNG in the policy.
class_name TwinfangPolicy
extends Policy

var latency_ticks: int = 0
var _tg_id: int = -1          ## stable id of the telegraph we're tracking
var _tg_seen: int = 0         ## tick we first saw it (reaction delay baseline)
## M7 string beats: per-policy rng (seeded by the sim, never state rng) smears the
## per-beat dodge aim by latency and rolls feint flinches — one roll per beat.
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

	var energy := float(obs.get("energy", 0.0))
	var reacted := tg.is_empty() or tick - _tg_seen >= latency_ticks

	# 0) M7 string: dodge each beat (a LANDED beat wipes Flow — footwork IS rhythm
	#    here). Feints are held unless the skill roll flinches into the bait.
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

	# 1) Dodge the incoming swing in its answer window. A telegraphed swing (1.4-2.6s
	#    wind-up) is easy to read at any skill — the Twinfang's skill is the RHYTHM below.
	if reacted and not tg.is_empty() and bool(tg.get("defensible", false)) \
			and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)):
		if float(tg.get("remaining", 99.0)) <= float(obs.get("def_zone", 0.42)):
			return {"type": "defense"}

	# 2) Kick the interruptible self-heal.
	if reacted and not tg.is_empty() and bool(tg.get("interruptible", false)) \
			and bool(obs.get("kick_ready", false)) and energy >= 10.0:
		return _ab("kick")

	if String(obs.get("aspect", "tempo")) == "tempo":
		return _tempo(obs, energy)
	return _venom(obs, energy)

# --- Tempo: chain Perfects to ride the accelerando (Flow = BPM); RIDE max Flow for the
#     fast+hard cadence, then SPEND it — Coup consumes Flow, so cash it as a finisher spike
#     in the execute window (boss < 40%) rather than dumping the BPM mid-fight.
func _tempo(obs: Dictionary, energy: float) -> Dictionary:
	if bool(obs.get("coup_ready", false)) and energy >= 42.0 \
			and float(obs.get("boss_frac", 1.0)) < 0.50:
		return _ab("coupdegrace")
	if int(obs.get("cp", 0)) >= int(obs.get("cp_max", 5)) and energy >= 37.0:
		return _ab("eviscerate")
	var target := int(obs.get("perfect_lo", 18)) + latency_ticks
	if int(obs.get("since_strike", 0)) >= target and energy >= float(obs.get("strike_cost", 12.0)):
		return _ab("strike")
	return {}

# --- Venomancer: PLAY THE WHEEL. Striking in the green rides V→F→C, topping all three
#     so Toxic Synergy ramps on its own (the ticking cocktail is the bulk of the damage);
#     Envenom FIXATES the lit lane to dump banked combo into extra poison; detonate only a
#     FAT, synergised cocktail with Rupture. No Flow — a sloppy tempo just leaks a little
#     poison uptime, so Venom stays the forgiving aspect.
func _venom(obs: Dictionary, energy: float) -> Dictionary:
	var venom: Dictionary = obs.get("venom", {})
	var cp := int(obs.get("cp", 0))
	var since := int(obs.get("since_strike", 0))

	# Detonate a big, synergised cocktail (rare — cd + the high bar keep the ramp alive).
	if bool(obs.get("rupture_ready", false)) and int(obs.get("venom_total", 0)) >= 14 \
			and bool(venom.get("syn_active", false)):
		return _ab("rupture")

	# Fixate: spend banked combo into the lit lane (extra poison) once it's stocked up.
	if cp >= 4 and energy >= 27.0:
		return _ab("envenom")

	# Strike in the green: rides the wheel (tops all three → synergy) + builds combo.
	var target := int(obs.get("perfect_lo", 18)) + latency_ticks
	if since >= target and energy >= float(obs.get("strike_cost", 12.0)):
		return _ab("strike")
	return {}

func _ab(id: String) -> Dictionary:
	return {"type": "ability", "id": id}

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
		# gentler than the tank's read model (0.045/tick): Twinfang fights are LONG
		# (venom 50s+) so bait cascades compound — 0.025 keeps the forgiving-aspect
		# contract (venom shrugs off sloppy rhythm) while feints still sting.
		_beat_flinches[i] = rng.next_float() < minf(0.8, float(latency_ticks) * 0.025)
	return bool(_beat_flinches[i])

func _beat_reset(tg: Dictionary) -> void:
	var t := int(tg.get("tick", 0))
	if t != _beat_key:
		_beat_key = t
		_beat_aims = {}
		_beat_flinches = {}
