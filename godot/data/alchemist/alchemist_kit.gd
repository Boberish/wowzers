## AlchemistKit — "the Brew" (ALCHEMIST-PLAN.md), the poison/DoT DPS class. The base
## minigame, ported faithfully from the feel-test artifact: hold to charge the VIAL
## (quadratic fill — the greed is how high you dare ride it), release to POUR into one
## of two opposing poisons (VENOM fades fast / ROT lingers), and the REACTION where they
## meet — min(V,R) × balance — is the damage. POTENCY fills while the reaction stays
## balanced-and-fed and multiplies everything; RUPTURE detonates FUEL × POWER and seeds
## the rebuild (the BUILD → PEAK → REBUILD wave, audit F4).
##
## Base build only: no creeds/modules/boons/rig yet — those layer on after live playtests.
## Faithful & deterministic: all class state lives in `seat.vars`, zero randomness, all
## math runs inside upkeep()/on_action() at the fixed 30 Hz step.
class_name AlchemistKit
extends ClassKit

var aspect: String = "brew"            ## working-name filler (the Brew IS the class)
var cfg: AlchemistConfig
var boons: Dictionary = {}             ## none exist yet — plumbing parity with other kits

## Reaction damage lands in discrete chunks on this cadence (ticks): threat/meter get
## honest whole hits and the HUD gets readable DoT numbers, not 30 Hz spam.
const REACT_LAND_EVERY := 15

func _init(_aspect: String, _cfg: AlchemistConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func defense_active() -> float:
	return cfg.dodge_active

func defense_cd() -> float:
	return cfg.dodge_cd

# --------------------------------------------------------------------------
# Brew state helpers (all state in seat.vars — Seat stays class-agnostic)
# --------------------------------------------------------------------------

func _venom(seat: Seat) -> float:
	return float(seat.vars.get("venom", 0.0))

func _rot(seat: Seat) -> float:
	return float(seat.vars.get("rot", 0.0))

func _potency(seat: Seat) -> float:
	return float(seat.vars.get("potency", 0.0))

func _pot_mult(seat: Seat) -> float:
	return 1.0 + _potency(seat) * cfg.pot_amp

## Balance ∈ [0,1]: 1 = perfectly even, 0 = one-sided (or empty).
func _balance(seat: Seat) -> float:
	var sum := _venom(seat) + _rot(seat)
	if sum <= 0.0:
		return 0.0
	return 1.0 - absf(_venom(seat) - _rot(seat)) / sum

## The live reaction dps (before dmg_scale) — min × balance × potency, the core law.
func _react_dps(seat: Seat) -> float:
	var m := minf(_venom(seat), _rot(seat))
	return m * cfg.react_mult * (0.5 + 0.5 * _balance(seat)) * _pot_mult(seat)

# --------------------------------------------------------------------------
# Per-tick upkeep: vial fill, asymmetric decay, potency, the reaction burn
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	var dt := s.dt
	# 1) the vial fills while held — slow at the bottom, accelerating hard near the top
	var side := String(seat.vars.get("charging", ""))
	if side != "":
		var c := float(seat.vars.get("charge", 0.0))
		seat.vars["charge"] = minf(cfg.charge_max, c + (cfg.charge_rate + cfg.charge_quad * c * c) * dt)
	# 2) asymmetric decay: hot fades fast, cold lingers
	seat.vars["venom"] = maxf(0.0, _venom(seat) - cfg.decay_venom * dt)
	seat.vars["rot"] = maxf(0.0, _rot(seat) - cfg.decay_rot * dt)
	# 3) potency — fills while the reaction is balanced AND fed; drains fast when sloppy
	var m := minf(_venom(seat), _rot(seat))
	var bal := _balance(seat)
	var good := m >= cfg.soft * cfg.pot_feed_frac and bal > cfg.pot_bal_min
	seat.vars["potency"] = clampf(
		_potency(seat) + (cfg.pot_fill if good else -cfg.pot_drain) * dt, 0.0, 1.0)
	seat.resource = _potency(seat) * seat.resource_max   # mirror for generic UI/policy reads
	# 4) the reaction EATS the brew — no banking a stable pile
	if m > 0.0:
		var burn := m * cfg.react_consume * dt
		seat.vars["venom"] = maxf(0.0, _venom(seat) - burn)
		seat.vars["rot"] = maxf(0.0, _rot(seat) - burn)
	# 5) damage: reaction + the weak single-poison drip, banked into discrete landings
	var dps := _react_dps(seat) + (_venom(seat) + _rot(seat)) * cfg.raw_mult
	seat.vars["react_bank"] = float(seat.vars.get("react_bank", 0.0)) + dps * dt * cfg.dmg_scale
	if s.tick % REACT_LAND_EVERY == 0:
		var bank := float(seat.vars.get("react_bank", 0.0))
		if bank >= 1.0:
			var d := floorf(bank)
			seat.vars["react_bank"] = bank - d
			CombatCore.damage_boss(s, seat, d, &"reaction")

# --------------------------------------------------------------------------
# Actions: brew (start a charge) / pour (release) / rupture (the cash-out)
# --------------------------------------------------------------------------

func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match id:
		&"brew_venom":
			return _start_charge(seat, "venom")
		&"brew_rot":
			return _start_charge(seat, "rot")
		&"pour":
			return _pour(s, seat)
		&"rupture":
			return _rupture(s, seat)
	return false

func _start_charge(seat: Seat, side: String) -> bool:
	if String(seat.vars.get("charging", "")) != "":
		return false                       # one brew at a time
	seat.vars["charging"] = side
	seat.vars["charge"] = 0.0
	return true

## Release the held vial: grade the charge level and apply the dose.
##   < fizzle_below        → TOO SOON, nothing (no tap-spam)
##   [sweet_lo, sweet_hi]  → POTENT (the skill target)
##   (sweet_hi, overflow]  → HOT (the greed edge — biggest honest dose)
##   > overflow            → SPOILED (~nothing)
## SATURATION CUT (Bill 2026-07-06): a full side no longer wastes the pour — the dose
## just lands (clamped at the hard cap). The vial grade is the only thing that matters.
func _pour(s: CombatState, seat: Seat) -> bool:
	var side := String(seat.vars.get("charging", ""))
	if side == "":
		return false
	var lvl := float(seat.vars.get("charge", 0.0))
	seat.vars["charging"] = ""
	seat.vars["charge"] = 0.0
	if lvl < cfg.fizzle_below:
		CombatCore._bump_diag(s, seat, "pour_fizzle")
		CombatCore.emit_event(s, {"t": "brew_pour", "player": seat.is_player, "seat": seat,
			"side": side, "grade": "fizzle", "dose": 0})
		return true
	var dose: float
	var grade: String
	if lvl > cfg.overflow_at:
		dose = cfg.dose_spoiled; grade = "spoiled"
	elif lvl > cfg.sweet_hi:
		dose = cfg.dose_hot; grade = "hot"
	elif lvl >= cfg.sweet_lo:
		dose = cfg.dose_sweet; grade = "potent"
	else:
		dose = cfg.dose_ok; grade = "ok"
	var cur := _venom(seat) if side == "venom" else _rot(seat)
	seat.vars[side] = minf(cfg.cap, cur + dose)
	CombatCore._bump_diag(s, seat, "pour_" + grade)
	CombatCore.emit_event(s, {"t": "brew_pour", "player": seat.is_player, "seat": seat,
		"side": side, "grade": grade, "dose": int(dose)})
	return true

## The cash-out: FUEL (balanced volume) × POWER (potency), multiplicative — the peak
## is both-high. Consumes most of the brew; the keep-fraction seeds the rebuild.
func _rupture(s: CombatState, seat: Seat) -> bool:
	var m := minf(_venom(seat), _rot(seat))
	if m < cfg.rupture_min:
		CombatCore.emit_event(s, {"t": "brew_dud", "player": seat.is_player, "seat": seat})
		return false
	var peak := _potency(seat) >= 0.9
	var burst := roundf(m * cfg.rupture_per * _pot_mult(seat) * cfg.dmg_scale)
	seat.vars["venom"] = _venom(seat) * cfg.rupture_keep
	seat.vars["rot"] = _rot(seat) * cfg.rupture_keep
	CombatCore.damage_boss(s, seat, burst, &"rupture")
	CombatCore._bump_diag(s, seat, "ruptures")
	if peak:
		CombatCore._bump_diag(s, seat, "rupture_peak")
	CombatCore.emit_event(s, {"t": "brew_rupture", "player": seat.is_player, "seat": seat,
		"amt": int(burst), "peak": peak})
	return true

# --------------------------------------------------------------------------
# Observation (policy + HUD). All view/AI fields — never part of the checksum.
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var m := minf(_venom(seat), _rot(seat))
	return {
		"tick": s.tick,
		"aspect": aspect,
		"venom": _venom(seat),
		"rot": _rot(seat),
		"cap": cfg.cap,
		"decay_venom": cfg.decay_venom,
		"decay_rot": cfg.decay_rot,
		"charging": String(seat.vars.get("charging", "")),
		"charge": float(seat.vars.get("charge", 0.0)),
		"charge_max": cfg.charge_max,
		"fizzle_below": cfg.fizzle_below,
		"sweet_lo": cfg.sweet_lo,
		"sweet_hi": cfg.sweet_hi,
		"overflow_at": cfg.overflow_at,
		"balance": _balance(seat),
		"potency": _potency(seat),
		"pot_mult": _pot_mult(seat),
		"pot_feed_ok": m >= cfg.soft * cfg.pot_feed_frac,
		"pot_bal_ok": _balance(seat) > cfg.pot_bal_min,
		"react_dps": _react_dps(seat) * cfg.dmg_scale,   # display dps (post-scale, honest)
		"brew_min": m,
		"rupture_min": cfg.rupture_min,
		# the "ripe" cue: fuel × power, the artifact's rupGlow — the HUD sigil + policy read it
		"ripe_glow": minf(1.0, m / cfg.ripe_fuel) * (cfg.ripe_glow_min + (1.0 - cfg.ripe_glow_min) * _potency(seat)),
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
	}
