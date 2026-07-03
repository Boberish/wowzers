## ReckonerPolicy — a competent AI Warrior. Plays the auto-advancing swing: WINDs to
## the best weight (Heavy, or the OVER end-zone when Overswing is armed) and lands the
## STRIKE on the True apex, drives the ability rotation (arm Overswing when Rage is fat,
## VENT the Onslaught when the gauge is up, insert Ultraswings), and dodges the boss's
## heavy swings (light chip is eaten on purpose — it feeds Rage).
##
## `latency_ticks` is the skill knob: a per-swing DetRng jitter (seeded by the sim, never
## state rng) smears the WIND commit and the STRIKE apex by ~latency, so a sloppy player
## misses True (→ less damage, less Momentum, less Poise) and mistimes weights. Colossus
## lives on that timing; Berserker's Momentum DR + snowball carries a sloppy tempo — the
## forgiving/punishing split. Wholly deterministic given (seed, latency).
class_name ReckonerPolicy
extends Policy

const PH_WIND := 0
const PH_FALL := 1
const PH_ULTRA := 2
const PH_SEQW := 3
const PH_SEQS := 4

var latency_ticks: int = 0
var rng: DetRng = null

var _wind_key: int = -0x7FFFFFFF
var _wind_jit: int = 0
var _apex_key: int = -0x7FFFFFFF
var _apex_jit: int = 0

func act(obs: Dictionary) -> Dictionary:
	var tg: Dictionary = obs.get("telegraph", {})
	var phase := int(obs.get("phase", 0))
	var rage := float(obs.get("rage", 0.0))

	# 1) Dodge a HEAVY/CRUSH swing aimed at me, in its answer window (eat light chip → Rage).
	if not tg.is_empty() and bool(tg.get("defensible", false)) and bool(tg.get("targets_me", false)) \
			and int(tg.get("size", 0)) >= AbilityRes.Size.HEAVY and bool(obs.get("defense_ready", false)):
		if float(tg.get("remaining", 99.0)) <= float(obs.get("def_zone", 0.45)):
			return {"type": "defense"}

	match phase:
		PH_WIND:
			if not bool(obs.get("wind_open", false)):
				return {}
			var sw := int(obs.get("since_wind", 0))
			# arm ONE ability, early in the window (before committing the wind)
			if sw <= 2:
				if bool(obs.get("ons_ready", false)) and rage >= 55.0 and float(obs.get("boss_frac", 1.0)) > 0.12:
					return _ab("onslaught")
				if bool(obs.get("over_ready", false)) and rage >= 60.0 and not bool(obs.get("over_armed", false)):
					return _ab("overswing")
				if bool(obs.get("ultra_ready", false)) and rage >= 30.0 and rage < 60.0 \
						and not bool(obs.get("ultra_armed", false)):
					return _ab("ultraswing")
			if sw >= _wind_target(obs) - 1:
				return _ab("wind")
			return {}
		PH_FALL, PH_ULTRA:
			if int(obs.get("to_apex", 999)) <= 1 - _apex_jitter(obs):
				return _ab("strike")
			return {}
		PH_SEQW:
			if int(obs.get("seq_since_wind", 0)) >= int(obs.get("heavy_lo", 18)) + 2 + _wind_jitter(obs):
				return _ab("wind")
			return {}
		PH_SEQS:
			if int(obs.get("to_apex", 999)) <= 1 - _apex_jitter(obs):
				return _ab("strike")
			return {}
	return {}

# --- WIND commit target: the Heavy zone centre (or the OVER end-zone when armed) ---
func _wind_target(obs: Dictionary) -> int:
	var wl := int(obs.get("wind_len", 27))
	var base: int
	if bool(obs.get("over_armed", false)):
		base = int(obs.get("over_lo", 23)) + 1
	else:
		base = (int(obs.get("heavy_lo", 18)) + wl) / 2   # Heavy centre
	return base + _wind_jitter(obs)

# --- per-swing jitter (rolled once per WIND / per apex; scaled by latency) ---
func _jit(scale: float) -> int:
	if rng == null or latency_ticks <= 0:
		return 0
	return int(round((rng.next_float() * 2.0 - 1.0) * float(latency_ticks) * scale))

func _wind_jitter(obs: Dictionary) -> int:
	var key := int(obs.get("tick", 0)) - int(obs.get("since_wind", 0))   # = wind_start (stable per wind)
	if int(obs.get("phase", 0)) == PH_SEQW:
		key = int(obs.get("tick", 0)) - int(obs.get("seq_since_wind", 0))
	if key != _wind_key:
		_wind_key = key
		_wind_jit = _jit(0.5)
	return _wind_jit

func _apex_jitter(obs: Dictionary) -> int:
	var key := int(obs.get("tick", 0)) + int(obs.get("to_apex", 0))       # = apex_tick (stable per apex)
	if key != _apex_key:
		_apex_key = key
		_apex_jit = _jit(0.5)
	return _apex_jit

func _ab(id: String) -> Dictionary:
	return {"type": "ability", "id": id}
