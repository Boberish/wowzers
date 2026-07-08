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

## THE ONE DODGE: the Brew's swing-negate and barrage beat-dodge collapse onto the
## single SPACE press (DODGE-PLAN.md 2026-07-08).
func unified_dodge() -> bool:
	return true

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _m(id: String) -> bool:
	return bool(modules.get(id, false))

## THE CASK (§7) guard. aspect == "cask" is a brand-new code path; every Brew eval tests
## aspect == "brew" (or nothing), so widening never moves an existing checksum — the
## Fermata idiom. When false the cask branches below are never entered (byte-identical base).
func _cask() -> bool:
	return aspect == "cask"

## A creed modifier, identity-defaulted. creed_id == "" returns the IDENTITY value, so every
## base-build expression collapses to its original constant (byte-identical gate).
func _cr(key: String):
	return AlchemistCreeds.field(creed_id, key)

func _cr_f(key: String) -> float:
	return float(AlchemistCreeds.field(creed_id, key))

func _cr_b(key: String) -> bool:
	return bool(AlchemistCreeds.field(creed_id, key))

## BOONS — the effective poison cap (Deep Cauldron raises it). Base = cfg.cap exactly.
func _cap() -> float:
	return cfg.cap + (cfg.deep_cauldron_cap if _b("deepCauldron") else 0.0)

## BOONS — the additive reaction bonus from drafted cards (all stack). Base = 0.0.
func _boon_react_bonus(seat: Seat) -> float:
	var bonus := 0.0
	if _b("corrosiveBlood"):
		bonus += cfg.corrosive_blood_mult
	if _b("volatileReaction") and _potency(seat) > 0.66:
		bonus += cfg.volatile_reaction_mult
	if _b("perfectEmulsion") and _balance(seat) >= 0.9:
		bonus += cfg.perfect_emulsion_mult
	if _b("deepeningRot"):
		bonus += float(seat.vars.get("deep_rot_ramp", 0.0))
	return bonus

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
	# CREED: Volatile lifts the ceiling (+50%), Steady lowers it. BOON: Concentrate ×1.2. Base ×1.0.
	var amp := cfg.pot_amp * _cr_f("pot_amp_mult")
	if _b("concentrate"):
		amp *= cfg.concentrate_mult
	return 1.0 + _potency(seat) * amp

## Balance ∈ [0,1]: 1 = perfectly even, 0 = one-sided (or empty).
func _balance(seat: Seat) -> float:
	var sum := _venom(seat) + _rot(seat)
	if sum <= 0.0:
		return 0.0
	return 1.0 - absf(_venom(seat) - _rot(seat)) / sum

## The live reaction dps (before dmg_scale) — min × balance × potency, the core law.
## CREED: Purist trades Rupture for a fatter reaction. BOONS: Corrosive/Volatile/Perfect
## Emulsion/Deepening Rot add here. Base bonus +0.0 → the product collapses to the original.
func _react_dps(seat: Seat) -> float:
	var m := minf(_venom(seat), _rot(seat))
	return m * cfg.react_mult * (0.5 + 0.5 * _balance(seat)) * _pot_mult(seat) \
		* (1.0 + _cr_f("react_bonus") + _boon_react_bonus(seat))

# --------------------------------------------------------------------------
# Per-tick upkeep: vial fill, asymmetric decay, potency, the reaction burn
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	if _cask():
		_cask_upkeep(s, seat)
		return
	var dt := s.dt
	# 1) the vial fills while held — slow at the bottom, accelerating hard near the top.
	#    CREED (Anchorite): a LINEAR fill (no quad accel) at a faster base rate — predictable.
	var side := String(seat.vars.get("charging", ""))
	if side != "":
		var c := float(seat.vars.get("charge", 0.0))
		var rate := cfg.charge_rate * _cr_f("charge_rate_mult")
		if _b("practicedHand"):                    # BOON: a calmer, slower climb (sidegrade)
			rate *= cfg.practiced_hand_mult
		var quad := 0.0 if _cr_b("linear_charge") else cfg.charge_quad
		seat.vars["charge"] = minf(cfg.charge_max, c + (rate + quad * c * c) * dt)
	# 2) asymmetric decay: hot fades fast, cold lingers. CREED: Anchorite FREEZES Rot; Volatile
	#    fades both faster. BOONS: Preservative slows both, Clinging Rot slows Rot. Base ×1.0.
	var dmul := _cr_f("decay_mult")
	var pres := cfg.preservative_mult if _b("preservative") else 1.0
	var rotb := cfg.clinging_rot_mult if _b("clingingRot") else 1.0
	var dv := cfg.decay_venom * dmul * pres
	var dr := (0.0 if _cr_b("freeze_rot") else cfg.decay_rot) * dmul * pres * rotb
	seat.vars["venom"] = maxf(0.0, _venom(seat) - dv * dt)
	seat.vars["rot"] = maxf(0.0, _rot(seat) - dr * dt)
	# 3) potency — fills while balanced AND fed; drains fast when sloppy. CREED: Steady widens
	#    the gate + softens drain; Purist tightens + leaks; pot_cap caps the bar. BOONS: Quick
	#    Study fills faster, Distilled Focus drains slower, Killing Draught freezes drain in
	#    execute range. Base ×1.0 / cap 1.0 → identical.
	var m := minf(_venom(seat), _rot(seat))
	var bal := _balance(seat)
	var good := m >= cfg.soft * cfg.pot_feed_frac and bal > cfg.pot_bal_min * _cr_f("bal_min_mult")
	var fill := cfg.pot_fill
	if _b("quickStudy"):
		fill *= cfg.quick_study_mult
	var drain := cfg.pot_drain * _cr_f("pot_drain_mult")
	if _b("distilledFocus"):
		drain *= cfg.distilled_focus_mult
	if _b("killingDraught") and s.boss.hp_max > 0.0 and s.boss.hp / s.boss.hp_max < cfg.killing_draught_hp:
		drain = 0.0
	seat.vars["potency"] = clampf(
		_potency(seat) + (fill if good else -drain) * dt, 0.0, _cr_f("pot_cap"))
	seat.resource = _potency(seat) * seat.resource_max   # mirror for generic UI/policy reads
	# 3a) BOONS that track per-tick state (guarded — no boon = no var writes = byte-identical).
	if _b("deepeningRot"):                          # DEEPENING ROT: fed+balanced ramps the reaction
		if good:
			seat.vars["deep_rot_ramp"] = minf(cfg.deepening_rot_max,
				float(seat.vars.get("deep_rot_ramp", 0.0)) + cfg.deepening_rot_rate * dt)
		else:
			seat.vars["deep_rot_ramp"] = 0.0
	if _b("lastCall") and not _cr_b("no_rupture"):  # LAST CALL: a phase change auto-cashes the brew
		var pa := CombatCore.current_phase(s).at
		if pa != float(seat.vars.get("last_phase_at", pa)):
			_rupture(s, seat)
		seat.vars["last_phase_at"] = pa
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
	# BOON (Debilitator): a live reaction corrodes the boss — feed the raid-wide debuff. Guarded.
	if _b("debilitator") and m > 0.0:
		s.boss.debilitate = minf(cfg.debilitate_max, s.boss.debilitate + cfg.debilitate_per * dt)
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
	if _cask():
		return _cask_on_action(s, seat, id)
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
		&"spitfire":
			return _spitfire(s, seat)
		&"decant":
			return _decant(s, seat)
		&"reduction":
			return _reduction(s, seat)
	return false

## SPELL (Spitfire): an instant off-brew acid dart — cheap filler between pours, short cd.
func _spitfire(s: CombatState, seat: Seat) -> bool:
	if not _b("spitfire") or int(seat.vars.get("spitfire_rdy", 0)) > s.tick:
		return false
	seat.vars["spitfire_rdy"] = s.tick + _tt(s, cfg.spitfire_cd)
	CombatCore.damage_boss(s, seat, roundf(cfg.spitfire_dmg * cfg.dmg_scale), &"spitfire")
	CombatCore.emit_event(s, {"t": "brew_spitfire", "player": seat.is_player, "seat": seat})
	return true

## SPELL (Decant): pour the fuller poison into the emptier — a cd-gated snap toward balance.
func _decant(s: CombatState, seat: Seat) -> bool:
	if not _b("decant") or int(seat.vars.get("decant_rdy", 0)) > s.tick:
		return false
	var v := _venom(seat)
	var r := _rot(seat)
	var move := absf(v - r) * 0.5 * cfg.decant_frac
	if v > r:
		seat.vars["venom"] = v - move; seat.vars["rot"] = minf(_cap(), r + move)
	else:
		seat.vars["rot"] = r - move; seat.vars["venom"] = minf(_cap(), v + move)
	seat.vars["decant_rdy"] = s.tick + _tt(s, cfg.decant_cd)
	CombatCore.emit_event(s, {"t": "brew_decant", "player": seat.is_player, "seat": seat})
	return true

## SPELL (Reduction): boil VOLUME into POWER — sacrifice a fraction of the brew for an
## instant slug of Potency, right before a Rupture (the two-axis mastery, I6).
func _reduction(s: CombatState, seat: Seat) -> bool:
	if not _b("reduction") or int(seat.vars.get("reduction_rdy", 0)) > s.tick:
		return false
	seat.vars["venom"] = _venom(seat) * (1.0 - cfg.reduction_take)
	seat.vars["rot"] = _rot(seat) * (1.0 - cfg.reduction_take)
	seat.vars["potency"] = clampf(_potency(seat) + cfg.reduction_pot, 0.0, _cr_f("pot_cap"))
	seat.vars["reduction_rdy"] = s.tick + _tt(s, cfg.reduction_cd)
	CombatCore.emit_event(s, {"t": "brew_reduction", "player": seat.is_player, "seat": seat})
	return true

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
	# BOON (Steady Pour): a WIDER band — pull sweet_lo down. Both fold into one sweet_lo.
	var sweet_lo := cfg.sweet_lo
	var band_mult := _cr_f("sweet_band_mult")
	if _b("steadyPour"):
		band_mult *= (1.0 + cfg.steady_pour_widen)
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
	# BOON (Deepening Rot): a spoil breaks the patient ramp.
	if grade == "spoiled" and _b("deepeningRot"):
		seat.vars["deep_rot_ramp"] = 0.0
	if dose > 0.0:
		var cur := _venom(seat) if side == "venom" else _rot(seat)
		seat.vars[side] = minf(_cap(), cur + dose)   # BOON (Deep Cauldron): a bigger ceiling
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
	# BOON (Rupturing): a bigger detonation. Base: no-op.
	if _b("rupturing"):
		burst = roundf(burst * (1.0 + cfg.rupturing_mult))
	# BOON (Chain Rupture): keep MORE of the brew — a smaller crater, a faster rebuild.
	var keep := cfg.rupture_keep + (cfg.chain_rupture_keep if _b("chainRupture") else 0.0)
	seat.vars["venom"] = _venom(seat) * keep
	seat.vars["rot"] = _rot(seat) * keep
	CombatCore.damage_boss(s, seat, burst, &"rupture")
	CombatCore._bump_diag(s, seat, "ruptures")
	if peak:
		CombatCore._bump_diag(s, seat, "rupture_peak")
	# BOON (Catalyst): a PHANTOM copy — a snapshot of the burst's value, brew already intact.
	if _b("catalyst"):
		var phantom := roundf(burst * cfg.catalyst_phantom)
		if phantom >= 1.0:
			CombatCore.damage_boss(s, seat, phantom, &"rupture")
			CombatCore.emit_event(s, {"t": "brew_catalyst_phantom", "player": seat.is_player, "seat": seat, "amt": int(phantom)})
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
	if _cask():
		return _cask_observe(s, seat)
	var m := minf(_venom(seat), _rot(seat))
	# CREED- and BOON-effective values the policy needs (frozen/slowed Rot, wider/tighter band,
	# bigger cap, faster fade, capped potency) — projection + feed target + rupture timing read these.
	var dmul := _cr_f("decay_mult")
	var pres := cfg.preservative_mult if _b("preservative") else 1.0
	var rotb := cfg.clinging_rot_mult if _b("clingingRot") else 1.0
	var eff_decay_venom := cfg.decay_venom * dmul * pres
	var eff_decay_rot := (0.0 if _cr_b("freeze_rot") else cfg.decay_rot) * dmul * pres * rotb
	var sweet_lo := cfg.sweet_lo
	var band_mult := _cr_f("sweet_band_mult")
	if _b("steadyPour"):
		band_mult *= (1.0 + cfg.steady_pour_widen)
	if band_mult != 1.0:
		sweet_lo = cfg.sweet_hi - (cfg.sweet_hi - cfg.sweet_lo) * band_mult
	return {
		"tick": s.tick,
		"aspect": aspect,
		"venom": _venom(seat),
		"rot": _rot(seat),
		"cap": _cap(),
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
		# SPELLS (drafted) — availability + cooldown readiness for the policy/HUD.
		"has_spitfire": _b("spitfire"),
		"spitfire_ready": int(seat.vars.get("spitfire_rdy", 0)) <= s.tick,
		"has_decant": _b("decant"),
		"decant_ready": int(seat.vars.get("decant_rdy", 0)) <= s.tick,
		"has_reduction": _b("reduction"),
		"reduction_ready": int(seat.vars.get("reduction_rdy", 0)) <= s.tick,
		# the "ripe" cue: fuel × power, the artifact's rupGlow — the HUD sigil + policy read it
		"ripe_glow": minf(1.0, m / cfg.ripe_fuel) * (cfg.ripe_glow_min + (1.0 - cfg.ripe_glow_min) * _potency(seat)),
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
	}

# ==========================================================================
# THE CASK (§7) — the 2nd spec. A brand-new verb reached only via aspect == "cask", never
# by the Brew (byte-identical base). STACK graded pours on a walking band → SEAL → COOK →
# PEAK tap. All state under a cask_ prefix in seat.vars; zero randomness; fixed 30 Hz.
# ==========================================================================
const CASK_TAIL_EVERY := 15   ## a Rot tail lands on this cadence (ticks) — 0.5s at 30 Hz

func _cask_strain(seat: Seat, side: String) -> int:
	return int(seat.vars.get("cask_strain_v" if side == "venom" else "cask_strain_r", 0))

## The effective band half is width/2; width shrinks ×cask_strain_shrink per chain level.
func _cask_band_width(seat: Seat, side: String) -> float:
	return cfg.cask_sweet_w * pow(cfg.cask_strain_shrink, float(_cask_strain(seat, side)))

func _cask_proof(seat: Seat) -> int:
	return int(seat.vars.get("cask_proof", 0))

## Set proof (clamped) and mirror it to the generic resource bar (proof IS this spec's power).
func _cask_set_proof(seat: Seat, v: int) -> void:
	var p := clampi(v, 0, cfg.cask_proof_max)
	seat.vars["cask_proof"] = p
	seat.resource = float(p) / float(cfg.cask_proof_max) * seat.resource_max

## Cooking age in seconds, derived from the seal tick (integer tick is truth).
func _cask_age(s: CombatState, seat: Seat) -> float:
	return float(s.tick - int(seat.vars.get("cask_seal_tick", s.tick))) * s.dt

## The age→value curve: a quadratic ramp up to the peak window (flat 1.0), then a sour decay
## with a hard floor. Its shape decides EARLY (weak) / PEAK (full) / SOUR (bleeding) taps.
func _cask_age_factor(age: float, cook: float, win: float) -> float:
	if age < cook - win:
		var x := age / maxf(0.001, cook - win)
		return cfg.cask_ramp_floor + cfg.cask_ramp_span * x * x
	if age <= cook + win:
		return 1.0
	return maxf(cfg.cask_sour_floor, pow(0.5, (age - (cook + win)) / cfg.cask_sour_half))

# --- per-tick: advance the vial (fill + red-line spoil), age a cooking cask, drip the tail ---
func _cask_upkeep(s: CombatState, seat: Seat) -> void:
	var dt := s.dt
	# 1) the vial fills while held — the tester curve, sped up by strain on the held side.
	var side := String(seat.vars.get("charging", ""))
	if side != "":
		var c := float(seat.vars.get("charge", 0.0))
		var rate := (cfg.cask_charge_base + cfg.cask_charge_quad * c) / cfg.cask_charge_time
		rate *= (1.0 + cfg.cask_strain_spd * float(_cask_strain(seat, side)))
		c += rate * dt
		if c >= cfg.cask_red_line:                 # held too long → SPOILED, the batch is dumped
			seat.vars["charge"] = cfg.cask_red_line
			seat.vars["charging"] = ""
			_cask_miss(s, seat, "spoiled")
		else:
			seat.vars["charge"] = c
	# 2) a cooking cask ages toward its peak; too long past the window and it's WASTED.
	if bool(seat.vars.get("cask_cooking", false)):
		var age := _cask_age(s, seat)
		var cook := float(seat.vars.get("cask_cook", cfg.cask_cook))
		var win := float(seat.vars.get("cask_win", cfg.cask_peak_base))
		if age >= cook - win and not bool(seat.vars.get("cask_chimed", false)):
			seat.vars["cask_chimed"] = true
			CombatCore.emit_event(s, {"t": "cask_ripe", "player": seat.is_player, "seat": seat})
		if age >= cook + win + 2.0 * cfg.cask_sour_half + cfg.cask_waste_extra:
			_cask_waste(s, seat)
	# 3) the Rot tail from the last tap drips on a fixed cadence (banked count + per-hit value).
	if s.tick % CASK_TAIL_EVERY == 0:
		var left := int(seat.vars.get("cask_tail_left", 0))
		if left > 0:
			var per := float(seat.vars.get("cask_tail_per", 0.0))
			if per >= 1.0:
				CombatCore.damage_boss(s, seat, roundf(per), &"cask_tail")
			seat.vars["cask_tail_left"] = left - 1
	# keep the generic resource mirror live even on an idle exhale (proof drives it).
	_cask_set_proof(seat, _cask_proof(seat))

# --- actions: the shared surface (hold 1/2 charge · release pour · tap 3 = seal / peak-tap) ---
func _cask_on_action(s: CombatState, seat: Seat, id: StringName) -> bool:
	match id:
		&"brew_venom":
			return _cask_start_charge(seat, "venom")
		&"brew_rot":
			return _cask_start_charge(seat, "rot")
		&"pour":
			return _cask_pour(s, seat)
		&"rupture":
			return _cask_tap(s, seat)
	return false

func _cask_start_charge(seat: Seat, side: String) -> bool:
	if String(seat.vars.get("charging", "")) != "":
		return false
	if bool(seat.vars.get("cask_cooking", false)):
		return false                          # can't pour while a cask cooks — that's the exhale
	seat.vars["charging"] = side
	seat.vars["charge"] = 0.0
	return true

## Release the vial → grade against the strained band. BULLSEYE/PERFECT/GOOD land a dose;
## anything wider (or held past the red line) MISSES and dumps the whole in-progress batch.
func _cask_pour(s: CombatState, seat: Seat) -> bool:
	var side := String(seat.vars.get("charging", ""))
	if side == "":
		return false
	var lvl := float(seat.vars.get("charge", 0.0))
	seat.vars["charging"] = ""
	seat.vars["charge"] = 0.0
	if lvl < cfg.cask_fizzle:                 # the bail — a low release costs nothing
		CombatCore.emit_event(s, {"t": "cask_pour", "player": seat.is_player, "seat": seat,
			"side": side, "grade": "bail"})
		return true
	if lvl >= cfg.cask_red_line:
		_cask_miss(s, seat, "spoiled")
		return true
	var center := float(seat.vars.get("cask_band", cfg.cask_band_start))
	var half := _cask_band_width(seat, side) * 0.5
	var d := absf(lvl - center)
	var gmult: float
	var grade: String
	if d <= half * cfg.cask_bull_frac:
		gmult = cfg.cask_grade_bull; grade = "bull"
	elif d <= half:
		gmult = cfg.cask_grade_perfect; grade = "perfect"
	elif d <= half * cfg.cask_good_frac:
		gmult = cfg.cask_grade_good; grade = "good"
	else:
		_cask_miss(s, seat, "wide")
		return true
	_cask_add_dose(s, seat, side, lvl, gmult, grade)
	return true

func _cask_add_dose(s: CombatState, seat: Seat, side: String, lvl: float, gmult: float, grade: String) -> void:
	seat.vars["cask_vol"] = float(seat.vars.get("cask_vol", 0.0)) + lvl
	seat.vars["cask_doses"] = int(seat.vars.get("cask_doses", 0)) + 1
	seat.vars["cask_grade_sum"] = float(seat.vars.get("cask_grade_sum", 0.0)) + gmult
	seat.vars["cask_finish"] = side
	if side == "venom":                       # heat comes from Venom, window + tail from Rot
		seat.vars["cask_vcount"] = int(seat.vars.get("cask_vcount", 0)) + 1
	else:
		seat.vars["cask_rcount"] = int(seat.vars.get("cask_rcount", 0)) + 1
	# STRAIN: this side climbs; the other relieves (a swap unwinds the built-up side).
	var kv := "cask_strain_v" if side == "venom" else "cask_strain_r"
	var ko := "cask_strain_r" if side == "venom" else "cask_strain_v"
	seat.vars[kv] = int(seat.vars.get(kv, 0)) + 1
	seat.vars[ko] = maxi(0, int(seat.vars.get(ko, 0)) - cfg.cask_swap_relief)
	# the band walks: Venom climbs toward the red line, Rot settles down — plannable, no rng.
	var band := float(seat.vars.get("cask_band", cfg.cask_band_start))
	band += (cfg.cask_band_step if side == "venom" else -cfg.cask_band_step)
	seat.vars["cask_band"] = clampf(band, cfg.cask_band_lo, cfg.cask_band_hi)
	CombatCore._bump_diag(s, seat, "cask_pour_" + grade)
	CombatCore.emit_event(s, {"t": "cask_pour", "player": seat.is_player, "seat": seat,
		"side": side, "grade": grade, "doses": int(seat.vars["cask_doses"])})
	if int(seat.vars["cask_doses"]) >= cfg.cask_max_doses:
		_cask_seal(s, seat)

## The tap does double duty: SEAL a filling cask, or PEAK-TAP a cooking one.
func _cask_tap(s: CombatState, seat: Seat) -> bool:
	if bool(seat.vars.get("cask_cooking", false)):
		return _cask_peak_tap(s, seat)
	return _cask_seal(s, seat)

func _cask_seal(s: CombatState, seat: Seat) -> bool:
	var doses := int(seat.vars.get("cask_doses", 0))
	if doses < cfg.cask_min_doses:
		return false                          # too thin — nothing to seal
	var rc := int(seat.vars.get("cask_rcount", 0))
	var vc := int(seat.vars.get("cask_vcount", 0))
	seat.vars["cask_q"] = float(seat.vars.get("cask_grade_sum", 0.0)) / float(doses)
	seat.vars["cask_win"] = minf(cfg.cask_cook * cfg.cask_peak_cap_frac,
		cfg.cask_peak_base + cfg.cask_rot_win * float(rc))
	seat.vars["cask_heat"] = 1.0 + cfg.cask_ven_heat * float(vc)
	seat.vars["cask_cook"] = cfg.cask_cook
	seat.vars["cask_cooking"] = true
	seat.vars["cask_seal_tick"] = s.tick
	seat.vars["cask_chimed"] = false
	seat.vars["cask_strain_v"] = 0           # seal clears strain + re-centres the band
	seat.vars["cask_strain_r"] = 0
	seat.vars["cask_band"] = cfg.cask_band_start
	CombatCore._bump_diag(s, seat, "cask_seal")
	if doses >= cfg.cask_max_doses:
		CombatCore._bump_diag(s, seat, "cask_seal_full")
	CombatCore.emit_event(s, {"t": "cask_seal", "player": seat.is_player, "seat": seat,
		"doses": doses, "q": float(seat.vars["cask_q"])})
	return true

func _cask_peak_tap(s: CombatState, seat: Seat) -> bool:
	var age := _cask_age(s, seat)
	var cook := float(seat.vars.get("cask_cook", cfg.cask_cook))
	var win := float(seat.vars.get("cask_win", cfg.cask_peak_base))
	var af := _cask_age_factor(age, cook, win)
	var dead := cfg.cask_dead_mult if absf(age - cook) < cfg.cask_dead_frac * win else 1.0
	var finish := String(seat.vars.get("cask_finish", ""))
	var fin_burst := cfg.cask_ven_finish if finish == "venom" else 1.0
	var vol := float(seat.vars.get("cask_vol", 0.0))
	var q := float(seat.vars.get("cask_q", 0.0))
	var heat := float(seat.vars.get("cask_heat", 1.0))
	var pmult := 1.0 + cfg.cask_proof_per * float(_cask_proof(seat))
	var burst := roundf(cfg.cask_base * vol * q * heat * fin_burst * af * dead * pmult * cfg.dmg_scale)
	var in_peak := age >= cook - win and age <= cook + win
	if in_peak:
		_cask_set_proof(seat, _cask_proof(seat) + cfg.cask_proof_peak)
		CombatCore._bump_diag(s, seat, "cask_tap_peak")
	elif age < cook - win:
		_cask_set_proof(seat, _cask_proof(seat) - cfg.cask_proof_miss)
		CombatCore._bump_diag(s, seat, "cask_tap_early")
	else:
		_cask_set_proof(seat, _cask_proof(seat) - cfg.cask_proof_miss)
		CombatCore._bump_diag(s, seat, "cask_tap_sour")
	if burst >= 1.0:
		CombatCore.damage_boss(s, seat, burst, &"cask_tap")
	# the Rot tail — a lingering aftershock, doubled by a Rot finish. Banked so overlaps keep total.
	var rc := int(seat.vars.get("cask_rcount", 0))
	if rc > 0:
		var fin_tail := cfg.cask_rot_finish if finish == "rot" else 1.0
		var total := burst * cfg.cask_tail_frac * float(rc) * fin_tail
		var ticks := rc * 2
		var prev := float(seat.vars.get("cask_tail_left", 0)) * float(seat.vars.get("cask_tail_per", 0.0))
		seat.vars["cask_tail_left"] = ticks
		seat.vars["cask_tail_per"] = (total + prev) / float(ticks)
	CombatCore.emit_event(s, {"t": "cask_tap", "player": seat.is_player, "seat": seat,
		"amt": int(burst), "peak": in_peak})
	_cask_reset_fill(seat)
	seat.vars["cask_cooking"] = false
	return true

## A MISS: dump the whole in-progress batch (or a light whiff if nothing was stacked).
func _cask_miss(s: CombatState, seat: Seat, why: String) -> void:
	var doses := int(seat.vars.get("cask_doses", 0))
	if doses > 0:
		_cask_set_proof(seat, _cask_proof(seat) - cfg.cask_proof_miss)
		CombatCore._bump_diag(s, seat, "cask_dump")
		CombatCore.emit_event(s, {"t": "cask_dump", "player": seat.is_player, "seat": seat,
			"doses": doses, "why": why})
	else:
		_cask_set_proof(seat, _cask_proof(seat) - cfg.cask_proof_whiff)
		CombatCore._bump_diag(s, seat, "cask_whiff")
	_cask_reset_fill(seat)

func _cask_waste(s: CombatState, seat: Seat) -> void:
	_cask_set_proof(seat, _cask_proof(seat) - cfg.cask_proof_miss)
	CombatCore._bump_diag(s, seat, "cask_waste")
	CombatCore.emit_event(s, {"t": "cask_waste", "player": seat.is_player, "seat": seat})
	_cask_reset_fill(seat)
	seat.vars["cask_cooking"] = false

func _cask_reset_fill(seat: Seat) -> void:
	seat.vars["cask_vol"] = 0.0
	seat.vars["cask_doses"] = 0
	seat.vars["cask_vcount"] = 0
	seat.vars["cask_rcount"] = 0
	seat.vars["cask_grade_sum"] = 0.0
	seat.vars["cask_finish"] = ""
	seat.vars["cask_strain_v"] = 0
	seat.vars["cask_strain_r"] = 0
	seat.vars["cask_band"] = cfg.cask_band_start

## View/AI fields for the cask (never checksummed). Includes a brew-key superset so the
## current ALEMBIC HUD renders mapped cask state instead of erroring (the real CASKWORKS
## instrument is slice 3); the cask_* keys are what the cask policy reads.
func _cask_observe(s: CombatState, seat: Seat) -> Dictionary:
	var cooking := bool(seat.vars.get("cask_cooking", false))
	var side := String(seat.vars.get("charging", ""))
	var band := float(seat.vars.get("cask_band", cfg.cask_band_start))
	var half := _cask_band_width(seat, side if side != "" else "venom") * 0.5
	var proof := _cask_proof(seat)
	var cook := float(seat.vars.get("cask_cook", cfg.cask_cook))
	var win := float(seat.vars.get("cask_win", cfg.cask_peak_base))
	var age := _cask_age(s, seat) if cooking else 0.0
	var ripe := cooking and age >= cook - win and age <= cook + win
	return {
		"tick": s.tick,
		"aspect": aspect,
		"charging": side,
		"charge": float(seat.vars.get("charge", 0.0)),
		"charge_max": cfg.cask_red_line,
		# --- the cask verb (policy reads these) ---
		"cask_band": band,
		"cask_band_half": half,
		"cask_red_line": cfg.cask_red_line,
		"cask_fizzle": cfg.cask_fizzle,
		"cask_bull_frac": cfg.cask_bull_frac,
		"cask_cooking": cooking,
		"cask_age": age,
		"cask_cook": cook,
		"cask_win": win,
		"cask_doses": int(seat.vars.get("cask_doses", 0)),
		"cask_min_doses": cfg.cask_min_doses,
		"cask_max_doses": cfg.cask_max_doses,
		"cask_vcount": int(seat.vars.get("cask_vcount", 0)),
		"cask_rcount": int(seat.vars.get("cask_rcount", 0)),
		"cask_strain_v": int(seat.vars.get("cask_strain_v", 0)),
		"cask_strain_r": int(seat.vars.get("cask_strain_r", 0)),
		"cask_proof": proof,
		"cask_proof_max": cfg.cask_proof_max,
		# --- brew-key superset so the ALEMBIC HUD renders (mapped) rather than erroring ---
		"venom": float(seat.vars.get("cask_vcount", 0)),
		"rot": float(seat.vars.get("cask_rcount", 0)),
		"cap": float(cfg.cask_max_doses),
		"decay_venom": 0.0, "decay_rot": 0.0,
		"sweet_lo": clampf(band - half, 0.0, 1.0),
		"sweet_hi": clampf(band + half, 0.0, 1.0),
		"overflow_at": cfg.cask_red_line,
		"fizzle_below": cfg.cask_fizzle,
		"balance": 0.5,
		"potency": float(proof) / float(cfg.cask_proof_max),
		"pot_cap": 1.0,
		"pot_mult": 1.0 + cfg.cask_proof_per * float(proof),
		"pot_feed_ok": true, "pot_bal_ok": true,
		"react_dps": 0.0,
		"brew_min": float(seat.vars.get("cask_doses", 0)),
		"rupture_min": 0.0, "no_rupture": false,
		"mod_third_reagent": false, "mod_fermentation": false, "mod_reaction_vessel": false,
		"reagent": 0.0, "reagent_ready": false, "reagent_active": false,
		"ferment": 0.0, "vessel": 0.0,
		"has_spitfire": false, "spitfire_ready": false,
		"has_decant": false, "decant_ready": false,
		"has_reduction": false, "reduction_ready": false,
		"ripe_glow": 1.0 if ripe else 0.0,
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
	}
