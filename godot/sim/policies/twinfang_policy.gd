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
## THE OPENING: my aimed fire-tick for the current vulnerability window. Expert (lat 0)
## aims dead on the peak; latency smears the aim off it (per-policy rng, one roll per
## opening) so a sloppy blade lands in the window edge or misses it entirely.
var _open_key: int = -1
var _open_aim: int = 0
var _dump_wait: int = 0         ## ticks a ready dump has waited for an opening (patience)
var _draw_noise: float = 0.0    ## FERMATA (EDGE): this draw's release-DEPTH jitter (rolled per coil)

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

	var asp := String(obs.get("aspect", "tempo"))
	if asp == "tempo" or asp == "fermata":    # Fermata rides the Tempo brain — only the Strike coils
		return _tempo(obs, energy)
	return _venom(obs, energy)

# --- Tempo: chain Perfects to ride the accelerando (Flow = BPM); RIDE max Flow for the
#     fast+hard cadence, then SPEND it — Coup consumes Flow, so cash it as a finisher spike
#     in the execute window (boss < 40%) rather than dumping the BPM mid-fight.
func _tempo(obs: Dictionary, energy: float) -> Dictionary:
	# Classic path (openings disabled) — byte-identical to the pre-Opening Twinfang.
	if not bool(obs.get("open_on", false)):
		if bool(obs.get("coup_ready", false)) and energy >= 42.0 \
				and float(obs.get("boss_frac", 1.0)) < 0.50:
			return _ab("coupdegrace")
		if int(obs.get("cp", 0)) >= int(obs.get("cp_max", 5)) and energy >= 37.0:
			return _ab("eviscerate")
		return _tempo_strike(obs, energy)

	# D0 S4 · TREMOLO transform: keep the Eviscerate string going — press on the beat while combo
	# lasts (each press spends 2), hold off the beat, rebuild with strikes when the hand runs dry.
	if String(obs.get("transform", "")) == "tremolo":
		var tp := int(obs.get("trem_presses", 0))
		if tp > 0 and tp < 3 and int(obs.get("cp", 0)) >= 2 and energy >= 15.0:
			if int(obs.get("since_strike", 0)) >= int(float(obs.get("perfect_lo", 18)) * 0.9):
				return _ab("eviscerate")   # press on the beat (graded)
			return {}                      # combo's ready — hold this tick for the window
	# D0 S6 · THE SET PIECE: arm the phrase when the CD is up and Flow is humming — then the normal
	# strike logic below nails the marked beats (a clean run cashes the flourish).
	if bool(obs.get("setpiece_ready", false)) and int(obs.get("flow", 0)) >= 3:
		return _ab("setpiece")
	var ofire := _open_fire(obs)   # 1 = punish NOW · 0 = hold for the opening · -1 = no opening
	# Coup: spend max Flow INTO the opening for the spike; else cash it in the execute window.
	if bool(obs.get("coup_ready", false)) and energy >= 42.0:
		if ofire == 1:
			return _ab("coupdegrace")
		if ofire == -1 and float(obs.get("boss_frac", 1.0)) < 0.50:
			return _ab("coupdegrace")
	# Eviscerate: bank full combo and dump it INTO the opening; be patient (holding builds
	# Flow) but don't sandbag combo forever if the boss just won't swing.
	if int(obs.get("cp", 0)) >= int(obs.get("cp_max", 5)) and energy >= 37.0:
		if _patient(ofire, 45):
			return _ab("eviscerate")
	else:
		_dump_wait = 0
	return _tempo_strike(obs, energy)

## GRADED WINDOW (§2c): aim for the CENTRE of the green (Bullseye/Perfect), not its early
## edge — the flanks are now only a Good (no Flow). Latency smears the press LATE off centre,
## so a skilled blade nails the core while a sloppy one drifts into Good/Miss. Scaled because
## a full reaction delay dwarfs the ~10-tick window; ~0.35 lands the gradient across the tiers.
const STRIKE_LAT_SCALE := 0.30
func _tempo_strike(obs: Dictionary, energy: float) -> Dictionary:
	if bool(obs.get("fermata", false)):
		return _fermata_strike(obs, energy)
	var lo := int(obs.get("perfect_lo", 18))
	var hi := int(obs.get("perfect_hi", 28))
	# aim CENTRE (−1 compensates the 1-tick enqueue delay so lat 0 lands dead centre);
	# latency then smears the press late off centre → Bullseye/Perfect/Good/Miss gradient.
	var target := maxi(lo, (lo + hi) / 2 - 1 + int(round(float(latency_ticks) * STRIKE_LAT_SCALE)))
	if int(obs.get("since_strike", 0)) >= target and energy >= float(obs.get("strike_cost", 12.0)):
		return _ab("strike")
	return {}

## FERMATA · THE DRAW: the sweep is PRESS-relative — the clock only runs while you hold, so the
## policy simply begins a draw whenever it has the energy (a human paces theirs around dumps),
## then releases on the centre-aim once sharp. Same latency smear as Tempo — the timing gradient
## is identical; obs `since_strike` is already the press-relative sweep position (0 when idle).
func _fermata_strike(obs: Dictionary, energy: float) -> Dictionary:
	if bool(obs.get("strike_locked", false)):
		return {}                                   # staggered from an unravel — wait it out
	if not bool(obs.get("coiling", false)):
		if energy >= float(obs.get("strike_cost", 12.0)):
			# roll this draw's release-DEPTH jitter once (per-policy rng; a clean expert = 0).
			# Fractional (not a tick offset) so it scales with the window — a narrow high-Flow
			# window snaps as readily as a wide one, which the additive smear got catastrophically
			# wrong (it snapped every narrow window). Symmetric: latency spreads deep AND shallow.
			_draw_noise = ((rng.next_float() * 2.0 - 1.0) * float(latency_ticks) * 0.016) if (rng != null and latency_ticks > 0) else 0.0
			return _ab("coil")                      # begin the draw — the window is already placed
		return {}
	# EDGE verb — DEPTH aim: ride toward the lip. Aim deep (0.84 = the Bullseye band, a hair short
	# of the cliff at 1.0); the jitter spreads a sloppy release deep (occasional SNAP) or shallow
	# (a safe Perfect/Good). Expert lands 0.84 clean; sloppy lives on the brink.
	var lo := int(obs.get("perfect_lo", 18))
	var hi := int(obs.get("perfect_hi", 28))
	var depth := clampf(0.84 + _draw_noise, 0.30, 1.06)
	var target := lo + int(round(float(hi - lo) * depth))
	if bool(obs.get("coil_sharp", false)) and int(obs.get("since_strike", 0)) >= target:
		return _ab("release")
	return {}

# --- Venomancer: PLAY THE WHEEL. Striking in the green rides V→F→C, topping all three
#     so Toxic Synergy ramps on its own (the ticking cocktail is the bulk of the damage);
#     Envenom FIXATES the lit lane to dump banked combo into extra poison; detonate only a
#     FAT, synergised cocktail with Rupture. No Flow — a sloppy tempo just leaks a little
#     poison uptime, so Venom stays the forgiving aspect.
func _venom(obs: Dictionary, energy: float) -> Dictionary:
	var venom: Dictionary = obs.get("venom", {})
	var cp := int(obs.get("cp", 0))
	var rupt_rdy := bool(obs.get("rupture_ready", false)) \
		and int(obs.get("venom_total", 0)) >= 14 and bool(venom.get("syn_active", false))

	# Classic path (openings disabled) — byte-identical to the pre-Opening Twinfang.
	if not bool(obs.get("open_on", false)):
		if rupt_rdy:
			return _ab("rupture")
		if cp >= 4 and energy >= 27.0:
			return _ab("envenom")
		return _tempo_strike(obs, energy)

	# Detonate a fat, synergised cocktail INTO an opening — but only a HARD-capped wait, so
	# Rupture still fires near its normal cadence (holding longer just ticks more DoT and
	# would rework Venom). The Opening rewards Tempo's timing far more than Venom's DoT bulk.
	var ofire := _open_fire(obs)
	if rupt_rdy:
		if _patient(ofire, 18, true):
			return _ab("rupture")
	else:
		_dump_wait = 0
	# Fixate: spend banked combo into the lit lane (extra poison) once it's stocked up.
	if cp >= 4 and energy >= 27.0:
		return _ab("envenom")
	return _tempo_strike(obs, energy)

func _ab(id: String) -> Dictionary:
	return {"type": "ability", "id": id}

# --- THE OPENING: decide whether to punish the boss's vulnerability window now ---
## Returns 1 (fire a ready dump NOW — inside the window, at/after my aimed tick),
## 0 (HOLD a ready dump — an opening is imminent, wait for it), or -1 (no opening —
## fire opportunistically). My aim is cached once per opening; latency smears it off
## the peak (per-policy rng), so sloppy play lands at the window edge or misses it.
func _open_fire(obs: Dictionary) -> int:
	var to := int(obs.get("open_to", -1))
	if to < 0:
		return -1
	var tick := int(obs.get("tick", 0))
	if tick > to:
		return -1                       # window already closed → opportunistic
	var peak := int(obs.get("open_peak", to))
	if peak != _open_key:               # roll my aim once per opening
		_open_key = peak
		var noise := 0
		if rng != null and latency_ticks > 0:
			noise = int(round((rng.next_float() * 2.0 - 1.0) * float(latency_ticks) * 0.6))
		_open_aim = peak + noise
	var frm := int(obs.get("open_from", tick))
	if tick >= _open_aim and tick >= frm:
		return 1                        # inside the window, at/after my aim → punish
	if float(frm - tick) <= 45.0:       # opening's peak within ~1.5s → hold for it
		return 0
	return -1                           # no opening near → bank (see _patient) then let go

## Patience gate for a READY dump: punish the peak if we're in a window (ofire 1),
## otherwise wait for one — up to `cap` ticks, then let it go so DPS never stalls.
## `hard` = whether an already-VISIBLE opening (ofire 0) counts toward the cap: Tempo
## sets hard=false, so it holds as long as a swing's peak is on the way (banking builds
## Flow for free); Venom sets hard=true, so it waits only briefly and detonates near its
## normal cadence (any held Rupture would just tick more DoT — that would rework Venom).
func _patient(ofire: int, cap: int, hard: bool = false) -> bool:
	if ofire == 1:
		_dump_wait = 0
		return true
	if ofire == 0 and not hard:
		return false                    # opening on the way — keep banking (no cap)
	_dump_wait += 1                     # no opening near, or Venom's hard cap is ticking
	if _dump_wait >= cap:
		_dump_wait = 0
		return true                     # waited long enough — don't sandbag
	return false

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
