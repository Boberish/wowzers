## AlchemistKit — "the Brew" (ALCHEMIST-PLAN.md), the poison/DoT DPS class. The base
## minigame, ported faithfully from the feel-test artifact: hold to charge the VIAL
## (quadratic fill — the greed is how high you dare ride it), release to POUR into one
## of two opposing poisons (VENOM fades fast / ROT lingers), and the REACTION where they
## meet — min(V,R) × balance — is the damage. POTENCY fills while the reaction stays
## balanced-and-fed and multiplies everything; RUPTURE detonates FUEL × POWER and seeds
## the rebuild (the BUILD → PEAK → REBUILD wave, audit F4).
##
## The card layers (creeds/modules/rig/boons) fold on top of the base loop, each GUARDED so
## an empty run is byte-identical to the base minigame (the determinism gate). Faithful &
## deterministic: all class state lives in `seat.vars`, zero randomness, all math runs inside
## upkeep()/on_action() at the fixed 30 Hz step.
class_name AlchemistKit
extends ClassKit

var aspect: String = "brew"            ## working-name filler (the Brew IS the class)
var cfg: AlchemistConfig
var boons: Dictionary = {}             ## drafted boon ids -> true (AlchemistBoons)
var creed_id: String = ""              ## the run's brewing posture ("" = none, byte-identical base)
var modules: Dictionary = {}           ## equipped UI Modules id -> true (Third Reagent / Fermentation / Vessel)
var rig: Dictionary = {}               ## the ONE Combo rig — {"when": id, "then": id}

## Reaction damage lands in discrete chunks on this cadence (ticks): threat/meter get
## honest whole hits and the HUD gets readable DoT numbers, not 30 Hz spam.
const REACT_LAND_EVERY := 15
## Rig THEN tuning: Residue spreads its total over this many landings; Fume/amp lasts this long.
const RESIDUE_LANDINGS := 6
const FUME_SEC := 2.0
const EMULSION_SEC := 4.0     ## Emulsion WHEN fires per this many seconds of unbroken ≥0.9 balance

func _init(_aspect: String, _cfg: AlchemistConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func defense_active() -> float:
	return cfg.dodge_active

func defense_cd() -> float:
	return cfg.dodge_cd

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _m(id: String) -> bool:
	return bool(modules.get(id, false))

## A creed modifier, identity-defaulted. creed_id == "" returns the IDENTITY value, so every
## base-build expression collapses to its original constant (byte-identical gate).
func _cr(key: String):
	return AlchemistCreeds.field(creed_id, key)

func _cr_f(key: String) -> float:
	return float(AlchemistCreeds.field(creed_id, key))

func _cr_b(key: String) -> bool:
	return bool(AlchemistCreeds.field(creed_id, key))

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
	# CREED: Volatile lifts the ceiling (+50%), Steady lowers it (×0.85). Base ×1.0.
	return 1.0 + _potency(seat) * cfg.pot_amp * _cr_f("pot_amp_mult")

## Balance ∈ [0,1]: 1 = perfectly even, 0 = one-sided (or empty).
func _balance(seat: Seat) -> float:
	var sum := _venom(seat) + _rot(seat)
	if sum <= 0.0:
		return 0.0
	return 1.0 - absf(_venom(seat) - _rot(seat)) / sum

## The live reaction dps (before dmg_scale) — min × balance × potency, the core law.
## CREED: Purist trades away Rupture for a fatter sustained reaction (+35%). Base +0.0.
func _react_dps(seat: Seat) -> float:
	var m := minf(_venom(seat), _rot(seat))
	return m * cfg.react_mult * (0.5 + 0.5 * _balance(seat)) * _pot_mult(seat) * (1.0 + _cr_f("react_bonus"))

# --------------------------------------------------------------------------
# Per-tick upkeep: vial fill, asymmetric decay, potency, the reaction burn
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	var dt := s.dt
	# 1) the vial fills while held — slow at the bottom, accelerating hard near the top.
	#    CREED (Anchorite): a LINEAR fill (no quad accel) at a faster base rate — predictable.
	var side := String(seat.vars.get("charging", ""))
	if side != "":
		var c := float(seat.vars.get("charge", 0.0))
		var rate := cfg.charge_rate * _cr_f("charge_rate_mult")
		var quad := 0.0 if _cr_b("linear_charge") else cfg.charge_quad
		seat.vars["charge"] = minf(cfg.charge_max, c + (rate + quad * c * c) * dt)
	# 2) asymmetric decay: hot fades fast, cold lingers. CREED: Anchorite FREEZES Rot;
	#    Volatile fades both faster (×1.3). Base decay_mult ×1.0 → identical.
	var dmul := _cr_f("decay_mult")
	var drot := (0.0 if _cr_b("freeze_rot") else cfg.decay_rot) * dmul
	seat.vars["venom"] = maxf(0.0, _venom(seat) - cfg.decay_venom * dmul * dt)
	seat.vars["rot"] = maxf(0.0, _rot(seat) - drot * dt)
	# 3) potency — fills while balanced AND fed; drains fast when sloppy. CREED: Steady widens
	#    the balanced gate (×0.9) and softens the drain (×0.6); Purist tightens + leaks; the
	#    ceiling (pot_cap) caps the bar itself (Steady ×0.6). Base ×1.0 / cap 1.0 → identical.
	var m := minf(_venom(seat), _rot(seat))
	var bal := _balance(seat)
	var good := m >= cfg.soft * cfg.pot_feed_frac and bal > cfg.pot_bal_min * _cr_f("bal_min_mult")
	var drain := cfg.pot_drain * _cr_f("pot_drain_mult")
	seat.vars["potency"] = clampf(
		_potency(seat) + (cfg.pot_fill if good else -drain) * dt, 0.0, _cr_f("pot_cap"))
	seat.resource = _potency(seat) * seat.resource_max   # mirror for generic UI/policy reads
	# 3b) RIG bookkeeping (guarded — the base build with no rig never writes these vars).
	if not rig.is_empty():
		# EMULSION WHEN: reward an EVEN hand — accumulate time at near-perfect balance and
		# fire every EMULSION_SEC of it. A real imbalance (bal < 0.70) breaks the streak.
		if bal >= 0.85 and m > 0.0:
			var et := int(seat.vars.get("emul_ticks", 0)) + 1
			seat.vars["emul_ticks"] = et
			if et % maxi(1, _tt(s, EMULSION_SEC)) == 0:
				_rig_fire(s, seat, "emulsion")
		elif bal < 0.70 or m <= 0.0:
			seat.vars["emul_ticks"] = 0
		# BOIL WHEN: potency driven to a full boil (0.9 of your ceiling; re-armable after it
		# drops back down). The boil_tick timestamp also gates PERFECT WAVE (a Rupture within
		# 2s of the boil — see _rupture).
		var capp := _cr_f("pot_cap")
		if _potency(seat) >= 0.9 * capp:
			if not bool(seat.vars.get("boiled", false)):
				seat.vars["boiled"] = true
				seat.vars["boil_tick"] = s.tick
				_rig_fire(s, seat, "boil")
		elif _potency(seat) < 0.7 * capp:
			seat.vars["boiled"] = false
	# 4) the reaction EATS the brew — no banking a stable pile
	if m > 0.0:
		var burn := m * cfg.react_consume * dt
		seat.vars["venom"] = maxf(0.0, _venom(seat) - burn)
		seat.vars["rot"] = maxf(0.0, _rot(seat) - burn)
	# 4b) MODULES that run off the reaction (all guarded — no module = base path below).
	var react := _react_dps(seat)
	# THIRD REAGENT: an ACTIVE catalyst amps the reaction for its window; the bar charges.
	if _m("third_reagent"):
		if int(seat.vars.get("reagent_until", 0)) >= s.tick:
			react *= (1.0 + cfg.reagent_amp)
		seat.vars["reagent"] = minf(1.0, float(seat.vars.get("reagent", 0.0)) + cfg.reagent_fill * dt)
	# RIG (Fume THEN): an active fume window amps your outgoing reaction. Base: no-op.
	if int(seat.vars.get("fume_until", 0)) >= s.tick:
		react *= (1.0 + float(seat.vars.get("fume_amt", 0.0)))
	# FERMENTATION: a meter fills while the reaction is good; at full it auto-detonates.
	if _m("fermentation"):
		if good:
			var fm := float(seat.vars.get("ferment", 0.0)) + cfg.ferment_fill * dt
			if fm >= 1.0:
				seat.vars["ferment"] = fm - 1.0
				var fb := roundf(cfg.ferment_burst * _pot_mult(seat) * cfg.dmg_scale)
				CombatCore.damage_boss(s, seat, fb, &"ferment")
				CombatCore._bump_diag(s, seat, "ferments")
				CombatCore.emit_event(s, {"t": "brew_ferment", "player": seat.is_player, "seat": seat, "amt": int(fb)})
			else:
				seat.vars["ferment"] = fm
	# 5) damage: reaction + the weak single-poison drip, banked into discrete landings.
	#    REACTION-VESSEL ⭐: the reaction BANKS (deals nothing) — Rupture dumps it (see _rupture).
	var raw := (_venom(seat) + _rot(seat)) * cfg.raw_mult
	if _m("reaction_vessel"):
		seat.vars["vessel"] = float(seat.vars.get("vessel", 0.0)) + react * dt * cfg.dmg_scale
		react = 0.0
	var dps := react + raw
	seat.vars["react_bank"] = float(seat.vars.get("react_bank", 0.0)) + dps * dt * cfg.dmg_scale
	if s.tick % REACT_LAND_EVERY == 0:
		var bank := float(seat.vars.get("react_bank", 0.0))
		if bank >= 1.0:
			var d := floorf(bank)
			seat.vars["react_bank"] = bank - d
			CombatCore.damage_boss(s, seat, d, &"reaction")
		# RIG (Residue THEN): a short lingering bleed lands with the reaction. Base: no-op.
		if int(seat.vars.get("residue_left", 0)) > 0:
			var rp := roundf(float(seat.vars.get("residue_per", 0.0)))
			if rp >= 1.0:
				CombatCore.damage_boss(s, seat, rp, &"reaction")
			seat.vars["residue_left"] = int(seat.vars["residue_left"]) - 1

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
		&"catalyst":
			return _catalyst(s, seat)
	return false

## COMBO RIG (ALCHEMIST-PLAN verdict 2): a WHEN moment fired. If the run's wired WHEN matches,
## apply the wired THEN at its computed magnitude (a modest side-boost). Deterministic; a
## view-only pop shows it. Early-returns when no rig is wired → the base build never touches it.
func _rig_fire(s: CombatState, seat: Seat, when_id: String) -> void:
	if rig.is_empty() or String(rig.get("when", "")) != when_id:
		return
	var then_id := String(rig.get("then", ""))
	var mag := AlchemistRig.magnitude(when_id, then_id)
	if mag <= 0:
		return
	match AlchemistRig.then_kind(then_id):
		"damage":
			CombatCore.damage_boss(s, seat, float(mag), &"reaction")   # SPLASH — instant spatter
		"fuel":
			var fu := AlchemistRig.raw_amount(when_id, then_id)                # BACKWASH — fractional fuel
			seat.vars["venom"] = minf(cfg.cap, _venom(seat) + fu)
			seat.vars["rot"] = minf(cfg.cap, _rot(seat) + fu)
		"potency":
			seat.vars["potency"] = clampf(_potency(seat) + float(mag) / 100.0, 0.0, _cr_f("pot_cap"))  # QUICKEN
		"dot":
			seat.vars["residue_left"] = RESIDUE_LANDINGS                    # RESIDUE — a short bleed
			seat.vars["residue_per"] = maxf(1.0, float(mag) / float(RESIDUE_LANDINGS))
		"amp":
			seat.vars["fume_until"] = s.tick + _tt(s, FUME_SEC)             # FUME — your damage +% for 2s
			seat.vars["fume_amt"] = float(mag) / 100.0
		"empower":
			seat.vars["rig_overfill"] = maxi(int(seat.vars.get("rig_overfill", 0)), mag)  # OVERFILL — next Rupture +%
	CombatCore._bump_diag(s, seat, "rig_fire")
	CombatCore.emit_event(s, {"t": "brew_rig", "player": seat.is_player, "seat": seat,
		"when": when_id, "then": then_id, "mag": mag})

## The outgoing-damage multiplier from an active FUME window (rig THEN). 1.0 unless live —
## reads a default-0 var, so the base build (no rig) always returns 1.0 (byte-identical).
func _fume_mult(s: CombatState, seat: Seat) -> float:
	if int(seat.vars.get("fume_until", 0)) >= s.tick:
		return 1.0 + float(seat.vars.get("fume_amt", 0.0))
	return 1.0

## THIRD REAGENT (module): spend a FULL catalyst bar → amp the reaction for reagent_dur.
## A partial bar can't drop (the gauge must fill). Guarded — a no-op without the module.
func _catalyst(s: CombatState, seat: Seat) -> bool:
	if not _m("third_reagent") or float(seat.vars.get("reagent", 0.0)) < 1.0:
		return false
	seat.vars["reagent"] = 0.0
	seat.vars["reagent_until"] = s.tick + _tt(s, cfg.reagent_dur)
	CombatCore._bump_diag(s, seat, "catalysts")
	CombatCore.emit_event(s, {"t": "brew_catalyst", "player": seat.is_player, "seat": seat})
	return true

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

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
	# CREED (Anchorite): a tighter sweet band, anchored at the red line (harder potent).
	var sweet_lo := cfg.sweet_lo
	var band_mult := _cr_f("sweet_band_mult")
	if band_mult != 1.0:
		sweet_lo = cfg.sweet_hi - (cfg.sweet_hi - cfg.sweet_lo) * band_mult
	var dose: float
	var grade: String
	if lvl > cfg.overflow_at:
		dose = cfg.dose_spoiled; grade = "spoiled"
	elif lvl > cfg.sweet_hi:
		dose = cfg.dose_hot; grade = "hot"
	elif lvl >= sweet_lo:
		dose = cfg.dose_sweet; grade = "potent"
	else:
		dose = cfg.dose_ok; grade = "ok"
	# CREED (Steady): an overflow just FIZZLES — no dose, no crash (the forgiving edge).
	if grade == "spoiled" and _cr_b("overflow_fizzle"):
		grade = "fizzle"; dose = 0.0
	# CREED (Volatile): a SPOILED pour crashes your hard-won potency to zero (the glass).
	if grade == "spoiled" and _cr_b("spoil_crashes"):
		seat.vars["potency"] = 0.0
	if dose > 0.0:
		var cur := _venom(seat) if side == "venom" else _rot(seat)
		seat.vars[side] = minf(cfg.cap, cur + dose)
	CombatCore._bump_diag(s, seat, "pour_" + grade)
	CombatCore.emit_event(s, {"t": "brew_pour", "player": seat.is_player, "seat": seat,
		"side": side, "grade": grade, "dose": int(dose)})
	# RIG: a potent/hot release is a WHEN moment (Sweet Pour / Hot Pour). Base: no-op.
	if grade == "potent":
		_rig_fire(s, seat, "sweet_pour")
	elif grade == "hot":
		_rig_fire(s, seat, "hot_pour")
	return true

## The cash-out: FUEL (balanced volume) × POWER (potency), multiplicative — the peak
## is both-high. Consumes most of the brew; the keep-fraction seeds the rebuild.
func _rupture(s: CombatState, seat: Seat) -> bool:
	# CREED (Purist): NO Rupture at all — the wave is gone (never runs at base; the button
	# is filtered off the Purist bar, this is the belt-and-braces block).
	if _cr_b("no_rupture"):
		return false
	var m := minf(_venom(seat), _rot(seat))
	if m < cfg.rupture_min:
		CombatCore.emit_event(s, {"t": "brew_dud", "player": seat.is_player, "seat": seat})
		return false
	var peak := _potency(seat) >= 0.9
	# CREED (Volatile): bigger Ruptures (×1.25). Base ×1.0.
	var burst := roundf(m * cfg.rupture_per * _pot_mult(seat) * cfg.dmg_scale * _cr_f("rupture_mult"))
	# REACTION-VESSEL ⭐: dump the whole banked Vessel on top of the burst, then empty it.
	var vessel := 0.0
	if _m("reaction_vessel"):
		vessel = float(seat.vars.get("vessel", 0.0))
		burst += roundf(vessel * cfg.vessel_release)
		seat.vars["vessel"] = 0.0
	# RIG: Overfill empowers THIS Rupture (then clears); an active Fume window amps it too.
	# Both read default-0 vars → the base build (no rig) leaves burst untouched.
	var overfill := int(seat.vars.get("rig_overfill", 0))
	if overfill > 0:
		burst = roundf(burst * (1.0 + float(overfill) / 100.0))
		seat.vars["rig_overfill"] = 0
	if int(seat.vars.get("fume_until", 0)) >= s.tick:
		burst = roundf(burst * (1.0 + float(seat.vars.get("fume_amt", 0.0))))
	seat.vars["venom"] = _venom(seat) * cfg.rupture_keep
	seat.vars["rot"] = _rot(seat) * cfg.rupture_keep
	CombatCore.damage_boss(s, seat, burst, &"rupture")
	CombatCore._bump_diag(s, seat, "ruptures")
	if peak:
		CombatCore._bump_diag(s, seat, "rupture_peak")
	CombatCore.emit_event(s, {"t": "brew_rupture", "player": seat.is_player, "seat": seat,
		"amt": int(burst), "peak": peak, "vessel": int(vessel)})
	# RIG WHEN moments on the cash-out: Ripe (rupture at peak) + Perfect Wave (within 2s of
	# hitting max Potency). Fired AFTER the burst so Overfill lands on the NEXT one. Base: no-op.
	if peak:
		_rig_fire(s, seat, "ripe")
	if not rig.is_empty():
		var bt := int(seat.vars.get("boil_tick", 0))
		if bt > 0 and s.tick - bt <= _tt(s, 2.0):
			_rig_fire(s, seat, "perfect_wave")
	return true

# --------------------------------------------------------------------------
# Observation (policy + HUD). All view/AI fields — never part of the checksum.
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var m := minf(_venom(seat), _rot(seat))
	# CREED-effective values the policy needs to play the posture (frozen Rot, tight band,
	# faster fade, capped potency) — projection + rupture timing read these.
	var dmul := _cr_f("decay_mult")
	var eff_decay_venom := cfg.decay_venom * dmul
	var eff_decay_rot := (0.0 if _cr_b("freeze_rot") else cfg.decay_rot) * dmul
	var sweet_lo := cfg.sweet_lo
	var band_mult := _cr_f("sweet_band_mult")
	if band_mult != 1.0:
		sweet_lo = cfg.sweet_hi - (cfg.sweet_hi - cfg.sweet_lo) * band_mult
	return {
		"tick": s.tick,
		"aspect": aspect,
		"venom": _venom(seat),
		"rot": _rot(seat),
		"cap": cfg.cap,
		"decay_venom": eff_decay_venom,
		"decay_rot": eff_decay_rot,
		"charging": String(seat.vars.get("charging", "")),
		"charge": float(seat.vars.get("charge", 0.0)),
		"charge_max": cfg.charge_max,
		"fizzle_below": cfg.fizzle_below,
		"sweet_lo": sweet_lo,
		"sweet_hi": cfg.sweet_hi,
		"overflow_at": cfg.overflow_at,
		"balance": _balance(seat),
		"potency": _potency(seat),
		"pot_cap": _cr_f("pot_cap"),                     # CREED (Steady): rupture near YOUR ceiling, not 1.0
		"pot_mult": _pot_mult(seat),
		"pot_feed_ok": m >= cfg.soft * cfg.pot_feed_frac,
		"pot_bal_ok": _balance(seat) > cfg.pot_bal_min * _cr_f("bal_min_mult"),
		"react_dps": _react_dps(seat) * cfg.dmg_scale,   # display dps (post-scale, honest)
		"brew_min": m,
		"rupture_min": cfg.rupture_min,
		"no_rupture": _cr_b("no_rupture"),               # CREED (Purist): don't tap Rupture, sustain
		# MODULES — gauges + policy hooks (only meaningful when the module is equipped).
		"mod_third_reagent": _m("third_reagent"),
		"mod_fermentation": _m("fermentation"),
		"mod_reaction_vessel": _m("reaction_vessel"),
		"reagent": float(seat.vars.get("reagent", 0.0)),
		"reagent_ready": float(seat.vars.get("reagent", 0.0)) >= 1.0,
		"reagent_active": int(seat.vars.get("reagent_until", 0)) >= s.tick,
		"ferment": float(seat.vars.get("ferment", 0.0)),
		"vessel": float(seat.vars.get("vessel", 0.0)),
		# the "ripe" cue: fuel × power, the artifact's rupGlow — the HUD sigil + policy read it
		"ripe_glow": minf(1.0, m / cfg.ripe_fuel) * (cfg.ripe_glow_min + (1.0 - cfg.ripe_glow_min) * _potency(seat)),
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
	}
