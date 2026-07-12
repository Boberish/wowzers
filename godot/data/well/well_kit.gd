## WellKit — the reworked direct-cast healer (MENDER-PLAN.md). A pure, deterministic
## ClassKit: all state in seat.vars, zero RNG, integer-tick truth.
##
## Economy: seat.vars["charges"] (int, Litany-pip precedent) refills +pulse_amount every
## pulse_every seconds and is the ONLY base income. Every heal is a CAST that pays charges
## at RESOLVE (checked affordable at start — a cancelled cast costs nothing but time).
##
## BRIM (aspect "brim"): a single-target heal is graded by where the target LANDS —
##   POUR (≥brim_band, no spill) → GLINT · SPILL (overheal) → waste · else PLAIN.
## DRAW (aspect "draw"): the cast completes MANUALLY via a "release" action, graded by
##   timing — CLEAN (final draw_band) → +CURRENT · STILL POINT (dead-centre) → +CURRENT
##   + GLINT · UNDERCOOK (early) → weak heal + breaks Current · OVERRUN (never released)
##   → plain full heal, Current untouched.
## GLINT is personal: a per-ally window on the boss's VULNERABILITY STACK (REFIT P4),
##   folded into BOTH damage paths (guarded → byte-identical when no window lives).
##
## THE DECK (MENDER-PLAN §2-5) layers on top, EACH GUARDED so an empty creed + no modules
## + no rig + no boons reproduce the base numbers exactly (the sim's byte-identical gate):
##   CREEDS  — run-long temperament, read via _cr() (WellCreeds; "" = IDENTITY = base).
##   MODULES — a Floor-1 gauge that auto-fires (Reservoir / Triage / Benediction), _m().
##   BOONS   — drafted upgrades keyed by id, _b() (WellBoons).
##   RIG     — one wired WHEN→THEN, _rig_fire() (WellRig; empty = never touched).
class_name WellKit
extends ClassKit

var aspect: String = "brim"
var cfg: WellConfig
var creed_id: String = ""              ## the run's healing temperament ("" = none, byte-identical base)
var rig: Dictionary = {}               ## the ONE Combo rig — {"when": id, "then": id}

# on_heal grading stash (heal_unit doesn't return overheal; capture it during a graded cast)
var _grading: bool = false
var _grading_over: float = 0.0

func accent() -> Color:
	return Color("4fc3e8")   # Palette.WATER — the Well's spring blue

func _init(_aspect: String, _cfg: WellConfig) -> void:
	aspect = _aspect
	cfg = _cfg

## A creed modifier, identity-defaulted. creed_id == "" returns the IDENTITY value, so every
## _cr read collapses to the base number and the deckless build stays byte-identical.
func _cr_f(key: String) -> float:
	return float(WellCreeds.field(creed_id, key))

func _cr_b(key: String) -> bool:
	return bool(WellCreeds.field(creed_id, key))

# --- charges -------------------------------------------------------------------
func _charges(seat: Seat) -> int:
	return int(seat.vars.get("charges", 0))

func _charges_max() -> int:
	return cfg.charges_max + (cfg.deep_well_bonus if _b("deepWell") else 0)

func _spend_charge(seat: Seat, n: int) -> void:
	var c := maxi(0, _charges(seat) - n)
	seat.vars["charges"] = c
	# running the Well DRY breaks the Current (Draw): the rush burns its own fuel.
	if c == 0 and aspect == "draw" and int(seat.vars.get("current", 0)) > 0:
		seat.vars["current"] = 0

func _gain_charge(seat: Seat, n: int) -> void:
	seat.vars["charges"] = mini(_charges_max(), _charges(seat) + n)

# --- THE CURRENT (draw) --------------------------------------------------------
func _current_up(s: CombatState, seat: Seat) -> void:
	seat.vars["current"] = mini(cfg.current_max, int(seat.vars.get("current", 0)) + 1)
	seat.vars["current_ebb_next"] = s.tick + _tt(s, cfg.current_ebb)

func _current_break(seat: Seat) -> void:
	seat.vars["current"] = 0

# --- band / still / glint (deck-adjusted; empty deck = the config base, bit-identical) ---
func _brim_band() -> float:
	var b := cfg.brim_band * _cr_f("brim_band_mult")
	if _b("wideBrim"):
		b -= cfg.wide_brim_delta
	return clampf(b, 0.05, 0.999)

func _draw_band() -> float:
	var d := cfg.draw_band * _cr_f("draw_band_mult")
	if _b("looseGrip"):
		d *= cfg.loose_grip_mult
	return clampf(d, 0.02, 0.9)

func _still_width() -> float:
	var w := cfg.still_point
	if _b("deepStill"):
		w *= cfg.deep_still_mult
	return w

func _undercook_exp() -> float:
	return cfg.short_pour_exp if _b("shortPour") else cfg.undercook_exp

func _glint_mult() -> float:
	var m := cfg.glint_mult + _cr_f("glint_bonus")
	if _b("blindfold"):
		m += cfg.blindfold_glint
	return m

# --- THE GLINT (personal — the healed ally) ------------------------------------
## Rides the generic VULNERABILITY STACK (REFIT P4): one window per ally, src
## &"glint" — refresh semantics for free, and a glinted FULL-fidelity blade (human
## or policy-driven) now cuts deeper too, not just the stat-block contrib.
func _glint(s: CombatState, target: Seat, extra_mult: float = 0.0, extra_secs: float = 0.0) -> void:
	if target == null or not target.alive():
		return
	var dur := cfg.glint_dur + (2.0 if _b("keptLight") else 0.0) + extra_secs
	var ti := s.seats.find(target)
	var until := s.tick + _tt(s, dur)
	# KEPT LIGHT: pouring on an already-lit ally EXTENDS the light instead of resetting it.
	if _b("keptLight"):
		var live := CombatCore.vuln_until(s, ti, &"glint")
		if live >= 0:
			until = live + _tt(s, dur)
	CombatCore.add_vuln(s, ti, _glint_mult() + extra_mult, until, &"glint")
	CombatCore._emit(s, {"t": "well_glint", "seat": target})

## The persistent (seat-state) heal multiplier — FORESIGHT stacks. Per-cast timing bonuses
## ride the `mult` arg; the creed flat/bloodied scale rides heal_mult(). 1.0 when unset.
func _state_heal_mult(seat: Seat) -> float:
	if _cr_b("foresight"):
		return 1.0 + 0.07 * float(int(seat.vars.get("foresight", 0)))
	return 1.0

# --- per-tick: charge pulse, Current ebb, modules, cast resolution --------------
func upkeep(s: CombatState, seat: Seat) -> void:
	# charge pulse (the only base income) — Steady Pulse quickens it
	var every := cfg.pulse_every * (cfg.steady_pulse_mult if _b("steadyPulse") else 1.0)
	var np := int(seat.vars.get("pulse_next", 0))
	if np <= 0:
		seat.vars["pulse_next"] = s.tick + _tt(s, every)
	elif s.tick >= np:
		_gain_charge(seat, cfg.pulse_amount)
		seat.vars["pulse_next"] = s.tick + _tt(s, every)

	# THE CURRENT ebbs when you stop drawing
	if aspect == "draw" and int(seat.vars.get("current", 0)) > 0:
		var eb := int(seat.vars.get("current_ebb_next", 0))
		if s.tick >= eb:
			seat.vars["current"] = int(seat.vars.get("current", 0)) - 1
			seat.vars["current_ebb_next"] = s.tick + _tt(s, cfg.current_ebb)
	# THE MILLRACE counts casts only while the Current runs full — reset the moment it drops
	if aspect == "draw" and int(seat.vars.get("current", 0)) < cfg.current_max:
		seat.vars["millrace_n"] = 0

	# THE FLUME (keystone): hold MAX Current for flume_hold_sec and the river runs white
	# (flume_run_sec of auto-clean releases). The Current is NO LONGER spent (Bill 2026-07-12
	# — the empty-to-0 read as a random punish, not a payoff): you KEEP your max Current, so
	# it re-arms flume_hold_sec later — hold the river high and it runs white again. Earned by
	# maintenance, never toggled, never drained.
	if aspect == "draw" and _b("flume"):
		if int(seat.vars.get("current", 0)) >= cfg.current_max:
			var since := int(seat.vars.get("current_full_since", -1))
			if since < 0:
				seat.vars["current_full_since"] = s.tick
			elif s.tick - since >= _tt(s, cfg.flume_hold_sec):
				seat.vars["flume_until"] = s.tick + _tt(s, cfg.flume_run_sec)
				seat.vars["current_full_since"] = s.tick    # re-arm the hold from here (no drain)
				CombatCore._emit(s, {"t": "well_flume", "seat": seat, "player": seat.is_player})
		else:
			seat.vars["current_full_since"] = -1

	# FORESIGHT (creed): a dip below half CRASHES the banked stacks
	if _cr_b("foresight") and int(seat.vars.get("foresight", 0)) > 0:
		if not _all_topped(s, seat, 0.5):
			seat.vars["foresight"] = 0

	# MODULES + reactive/passive boons (all guarded; no module/boon → skipped entirely)
	_tick_modules(s, seat)
	if _b("brinkBell"):
		_tick_brink_bell(s, seat)
	if _b("shiningHour"):
		_tick_shining_hour(s, seat)

	# resolve a finished cast
	if not seat.casting.is_empty():
		var c := seat.casting
		var tgt: Seat = c.get("target")
		var id0 := String(c["id"])
		var needs_target := id0 != "rekindle" and id0 != "meditate" and id0 != "boil"
		if needs_target and tgt != null and not tgt.alive():
			seat.casting = {}
			CombatCore._emit(s, {"t": "cast_cancelled"})
		elif s.tick - int(c["start_tick"]) >= int(c["dur_ticks"]):
			var holdable := id0 == "flash" or id0 == "mend"
			# THE PATIENT HAND (creed, draw): a heal-cast that RUNS PAST its end doesn't fire —
			# it becomes a HELD heal cocked in the hand, released on the spike (or it gutters).
			if aspect == "draw" and _hold_armed() and holdable and not bool(c.get("held", false)):
				seat.casting["held"] = true
				seat.casting["held_start"] = s.tick
				seat.casting["held_until"] = s.tick + _tt(s, 3.0 + cfg.ease_gutter_delay)
				CombatCore._emit(s, {"t": "well_held", "seat": seat, "player": seat.is_player})
			elif bool(c.get("held", false)):
				if s.tick >= int(c.get("held_until", 0)):    # gutters — charge + cast wasted
					seat.casting = {}
					_spend_charge(seat, int(cfg.book[id0].get("charges", 0)))
					CombatCore._emit(s, {"t": "well_gutter", "seat": seat, "player": seat.is_player})
			else:
				seat.casting = {}
				# BRIM grades the landing at resolve; DRAW auto-completes plain (OVERRUN).
				_resolve(s, seat, id0, tgt, ("land" if aspect == "brim" else "overrun"))

# --- input: cast start / release -----------------------------------------------
func on_action(s: CombatState, seat: Seat, id: StringName, target: Seat = null) -> bool:
	var key := String(id)
	if key == "release":
		return _release(s, seat)
	var sp: Dictionary = cfg.book.get(key, {})
	if sp.is_empty():
		return false
	if bool(sp.get("boon", false)) and not _b(key):        # drafted spells: locked until owned
		return false
	var offgcd := bool(sp.get("offgcd", false))
	if not offgcd and s.tick < seat.gcd_until_tick:
		return false
	if s.tick < int(seat.cooldowns.get(key, 0)):
		return false
	# SECOND HAND (boon): while a HELD heal is cocked, Flash stays castable — it fires INSTANTLY
	# (plain, ungraded, no Current), so you cover a second dip without dropping the hold. The held
	# heal keeps the casting slot; the flash resolves on the spot (GCD-gated so it can't be spammed).
	if key == "flash" and _b("secondHand") and bool(seat.casting.get("held", false)):
		if target == null or not target.alive() or _charges(seat) < int(sp.get("charges", 0)):
			return false
		_resolve(s, seat, "flash", target, "instant")
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
		return true
	if not offgcd and not seat.casting.is_empty():
		return false
	# target validity
	if key == "rekindle":
		if target == null or target.alive():               # rekindle needs a DEAD ally
			return false
	elif bool(sp.get("target", false)):
		if target == null or not target.alive():
			return false
		if key == "dispel" and target.debuff.is_empty():
			return false
	# affordability (checked at start; charges paid at resolve). THE MILLRACE can make the
	# imminent cast free, so a full-Current dry Well can still fire its free third cast.
	var need := int(sp.get("charges", 0))
	if _millrace_free(seat):
		need = 0
	if _charges(seat) < need:
		return false

	var cast := float(sp.get("cast", 0.0))
	if cast > 0.0:
		var dur := cast * _cr_f("cast_mult")               # Long Draw: slow & sharp
		if aspect == "draw":
			dur *= (1.0 - cfg.current_haste * float(int(seat.vars.get("current", 0))))
		if _b("lastDrops") and _charges(seat) <= cfg.last_drops_at:
			dur *= (1.0 - cfg.last_drops_haste)             # squeeze the dregs faster
		var ct := maxi(1, _tt(s, dur))
		seat.casting = {"id": key, "target": target, "start_tick": s.tick, "dur_ticks": ct}
		if not offgcd:
			seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)  # GCD runs from cast START
		CombatCore._emit(s, {"t": "cast_started", "id": key, "dur": dur})
		return true
	# instant (dispel / Boiling Over)
	_resolve(s, seat, key, target, "instant")
	return true

## DRAW's release: grade the timing and resolve early. Also releases a HELD (Patient Hand)
## heal instantly. No-op in BRIM with no held cast.
## THE EDDY's drifted clean-band centre — the SINGLE source of truth shared by the grade
## (_release) and the render read (observe()), so the drawn window can never desync from the
## graded one. Base centre = 1 - band/2 (the band ends at the bar's right edge); the Eddy creed
## drifts it LEFT deterministically from the cast's start tick; frozen (Glass River) stops drift.
func _eddy_centre(start: int, band: float, frozen: bool) -> float:
	var centre := 1.0 - band * 0.5
	if _cr_b("eddy") and not frozen:
		var rng := 0.16 * (cfg.deepeddy_drift_mult if _b("deepEddy") else 1.0)
		var h := (start * 2654435761) & 0xFFFFFF
		var drift := (float(h) / float(0xFFFFFF) - 0.5) * rng
		centre = clampf(centre + drift, 0.5, 1.0 - band * 0.5)
	return centre

func _release(s: CombatState, seat: Seat) -> bool:
	if seat.casting.is_empty():
		return false
	var c := seat.casting
	# a HELD heal (Patient Hand / ⭐Vigil) releases full & instant, and does NOT feed the Current
	if bool(c.get("held", false)):
		return _release_held(s, seat, c)
	if aspect != "draw":
		return false
	var start := int(c["start_tick"])
	var dur := int(c["dur_ticks"])
	var elapsed := s.tick - start
	if elapsed >= dur:
		return false                                        # at/past the end — upkeep handles it
	var p := float(elapsed) / float(dur)
	var id := String(c["id"])
	var tgt: Seat = c.get("target")
	var band := _draw_band()
	# THE GLASS RIVER (keystone): while the water is FROZEN, the drift stops.
	var frozen := s.tick < int(seat.vars.get("glassriver_until", -1))
	# THE EDDY (creed) drifts the clean band's centre (deterministic from start tick). ONE source
	# of truth (_eddy_centre) so the GRADE here and the RENDER read in observe() can never diverge.
	var centre := _eddy_centre(start, band, frozen)
	seat.casting = {}
	var lo := centre - band * 0.5
	var in_band := p >= lo and p <= centre + band * 0.5
	var is_still := absf(p - centre) <= _still_width() * 0.5
	# THE FLUME (keystone): while the river runs white, any release auto-grades CLEAN.
	var flume := s.tick < int(seat.vars.get("flume_until", -1))
	if frozen:
		in_band = true; is_still = true                     # frozen water = every release a Still Point
	elif flume:
		in_band = true; is_still = false                    # white water = every release a clean draw
	if in_band:
		var bonus := _draw_clean_bonus(s, seat)
		# CURRENT READING boon: a tag in the band's FIRST THIRD (of a genuine read) → +1 extra Current.
		var cr_extra := _b("currentReading") and not frozen and not flume \
			and p <= lo + band * cfg.currentreading_third
		if is_still:
			if _b("shootGap") and int(seat.vars.get("current", 0)) >= cfg.current_max:
				bonus *= cfg.shootgap_still_mult            # the hardened sliver pays at max Current
			if _b("deepEddy"):
				bonus *= cfg.deepeddy_still_mult            # a Still in the wandering water pays more
			_resolve(s, seat, id, tgt, "still", bonus)
		else:
			_resolve(s, seat, id, tgt, "clean", bonus)
		if cr_extra:
			_current_up(s, seat)                            # the fast-read reward, on top of the release's own
		_glassriver_tick(s, seat, is_still)
	else:
		# THE NARROWS (creed): a release OUTSIDE the band heals for NOTHING.
		var uf := 0.0 if _cr_b("narrows") else pow(maxf(0.05, p), _undercook_exp())
		_resolve(s, seat, id, tgt, "under", uf)
		_glassriver_tick(s, seat, false)
	return true

## A HELD heal (Patient Hand / ⭐Vigil) releasing: full & instant. RIDE THE TREMBLE scales it by
## how long it was held; LOOSED AT LAST turns a release timed to the ally's hit into an intercept
## (full heal + a 2s absorb). Held releases never feed the Current.
func _release_held(s: CombatState, seat: Seat, c: Dictionary) -> bool:
	var hid := String(c["id"])
	var htgt: Seat = c.get("target")
	var held_start := int(c.get("held_start", s.tick))
	seat.casting = {}
	var mult := 1.0
	if _b("rideTremble"):
		var halves := float(s.tick - held_start) / maxf(1.0, float(_tt(s, 0.5)))
		mult += minf(cfg.ridetremble_cap, cfg.ridetremble_per * halves)
	# LOOSED AT LAST (keystone): released within loosed_window of the ally's last hit = a PERFECT
	# INTERCEPT — the heal lands full AND half of it clings on as a short absorb.
	var intercept := false
	if _b("loosedAtLast") and htgt != null:
		var lh := int(htgt.vars.get("last_hit_tick", -999999))
		if lh >= 0 and s.tick - lh <= _tt(s, cfg.loosed_window):
			intercept = true
	_resolve(s, seat, hid, htgt, "held", mult)
	if intercept and htgt != null and htgt.alive():
		var sp: Dictionary = cfg.book.get(hid, {})
		var absorb := float(sp.get("heal", 0.0)) * mult * cfg.loosed_shield_frac
		_add_absorb(s, htgt, absorb, seat, cfg.loosed_shield_sec)   # a SHORT 2s intercept shield
		CombatCore._emit(s, {"t": "well_intercept", "seat": htgt, "caster": seat, "player": seat.is_player})
	return true

## THE GLASS RIVER (keystone): three Still Points IN A ROW freeze the water (5s of all-Still
## grading + no drift). Guarded on the boon; a non-still release breaks the streak. While already
## frozen it doesn't re-arm (the freeze runs its course, then the streak rebuilds).
func _glassriver_tick(s: CombatState, seat: Seat, still: bool) -> void:
	if not _b("glassRiver") or s.tick < int(seat.vars.get("glassriver_until", -1)):
		return
	if still:
		var n := int(seat.vars.get("still_streak", 0)) + 1
		if n >= cfg.glassriver_streak:
			seat.vars["still_streak"] = 0
			seat.vars["glassriver_until"] = s.tick + _tt(s, cfg.glassriver_sec)
			CombatCore._emit(s, {"t": "well_glassriver", "seat": seat, "player": seat.is_player})
		else:
			seat.vars["still_streak"] = n
	else:
		seat.vars["still_streak"] = 0

## Timing/state bonuses folded into a CLEAN/STILL draw's heal (guarded → 1.0 when unset).
func _draw_clean_bonus(s: CombatState, seat: Seat) -> float:
	var b := 1.0
	if _cr_b("narrows"):
		b *= 1.0 + _cr_f("narrows_bonus")
	if _b("whitewater"):
		b *= 1.0 + cfg.whitewater_per * float(int(seat.vars.get("current", 0)))   # +per stack of Current
	if _b("strongPull") and int(seat.vars.get("current", 0)) >= cfg.current_max:
		b *= 1.0 + cfg.strong_pull_bonus
	if _b("lastDrops") and _charges(seat) <= cfg.last_drops_at:
		b *= 1.0 + cfg.last_drops_heal
	if _b("doubleDraw"):
		var lc := int(seat.vars.get("last_clean_tick", -999999))
		if lc >= 0 and s.tick - lc <= _tt(s, cfg.double_draw_sec):
			b *= 1.0 + cfg.double_draw_bonus                # the chain's second clean
	return b

## The overrun-becomes-a-HELD-heal rule is armed by EITHER the Patient Hand creed OR the
## ⭐Vigil module (§12 — the transformer candidate made real). Same state, one gate.
func _hold_armed() -> bool:
	return _cr_b("patient_hold") or _m("vigil")

func _millrace_free(seat: Seat) -> bool:
	return _b("theMillrace") and aspect == "draw" \
		and int(seat.vars.get("current", 0)) >= cfg.current_max \
		and int(seat.vars.get("millrace_n", 0)) >= 2        # this would be the 3rd charged cast

# --- resolution ----------------------------------------------------------------
## mode ∈ {land, instant} (brim/dispel) | {clean, still, under, overrun, held} (draw).
func _resolve(s: CombatState, seat: Seat, id: String, target: Seat, mode: String, mult: float = 1.0) -> void:
	var sp: Dictionary = cfg.book[id]
	var cost := int(sp.get("charges", 0))
	# CADENCE OF MEND (brim boon): a live pour-chain shaves a charge off the next single heal.
	if _b("cadenceOfMend") and (id == "flash" or id == "mend") and int(seat.vars.get("pour_chain", 0)) > 0:
		cost = maxi(cfg.cadence_min, cost - 1)
	# THE MILLRACE: every 3rd charged cast at full Current is free.
	if cost > 0 and _millrace_free(seat):
		cost = 0
		seat.vars["millrace_n"] = 0
		CombatCore._emit(s, {"t": "well_millrace", "seat": seat, "player": seat.is_player})
	elif cost > 0 and _b("theMillrace") and aspect == "draw" \
			and int(seat.vars.get("current", 0)) >= cfg.current_max:
		seat.vars["millrace_n"] = int(seat.vars.get("millrace_n", 0)) + 1
	_spend_charge(seat, cost)

	var shm := _state_heal_mult(seat)                       # FORESIGHT etc (persistent)
	match id:
		"flash", "mend":
			_direct_heal(s, seat, target, float(sp["heal"]) * mult * shm, id, mode)
		"skin":
			_apply_skin(s, seat, target, mode)              # the water's film — heals 0, defers damage
		"cascade":
			_heal_lowest(s, seat, int(sp.get("aoe", 3)), float(sp["heal"]) * mult * shm, id)
			_draw_feedback(s, seat, mode, null)             # AoE: Current only, no Glint (base)
		"spring":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					_do_heal(s, u, float(sp["heal"]) * mult * shm, seat, &"spring")
			_draw_feedback(s, seat, mode, null)
		"meditate":
			_gain_charge(seat, cfg.meditate_charges)         # the drafted battery
			CombatCore._emit(s, {"t": "well_meditate", "seat": seat, "player": seat.is_player})
		"boil":
			_boiling_over(s, seat)                           # the clutch damage dump
		"dispel":
			if target != null:
				target.debuff = {}
			CombatCore._bump_diag(s, seat, "dispel")
		"rekindle":
			if target != null:
				target.hp = roundf(target.hp_max * float(sp.get("revive_frac", 0.40)))
				target.debuff = {}
				target.heal_absorb = 0.0
				CombatCore._emit(s, {"t": "revive", "seat": target})

	# GCD for instants (cast-time spells put you on the GCD at cast start)
	if not bool(sp.get("offgcd", false)) and float(sp.get("cast", 0.0)) <= 0.0:
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	var cd := float(sp.get("cd", 0.0))
	if cd > 0.0:
		seat.cooldowns[id] = s.tick + _tt(s, cd)
	CombatCore._emit(s, {"t": "cast_finished", "id": id})

## A single-target heal (flash/mend) with the aspect grade + the deck's brim payoffs.
func _direct_heal(s: CombatState, seat: Seat, target: Seat, amt: float, id: String, mode: String) -> void:
	if target == null or not target.alive():
		return
	var frac_before := target.hp_frac()
	_grading = true
	_grading_over = 0.0
	var eff := CombatCore.heal_unit(s, target, amt, seat, StringName(id))   # fires on_heal → over
	_grading = false
	var over := _grading_over

	if aspect == "brim":
		if over > cfg.spill_eps:
			seat.vars["pour_chain"] = 0                      # a spill breaks the cadence chain
			_on_spill(s, seat, over)
			CombatCore._emit(s, {"t": "well_spill", "seat": seat, "player": seat.is_player, "amt": int(over)})
			_rig_fire(s, seat, "spill_catch")
		elif target.hp_frac() >= _brim_band():
			_on_pour(s, seat, target, eff, frac_before)
			CombatCore._bump_diag(s, seat, "well_pour")       # class-signature skill signal
			CombatCore._emit(s, {"t": "well_pour", "seat": seat, "player": seat.is_player})
			_rig_fire(s, seat, "sweet_pour")
			if frac_before < cfg.low_catch_frac:
				_rig_fire(s, seat, "low_catch")
		else:
			seat.vars["pour_chain"] = 0
			CombatCore._emit(s, {"t": "well_plain", "seat": seat, "player": seat.is_player})
	else:
		_draw_feedback(s, seat, mode, target)

## The BRIM pour payoff: the Glint + every brim boon/creed/module that keys off a pour.
func _on_pour(s: CombatState, seat: Seat, target: Seat, eff: float, frac_before: float) -> void:
	# LOW CATCH boon: a pour on a near-dead ally fires a stronger Glint.
	var extra := cfg.low_catch_glint if (_b("lowCatch") and frac_before < cfg.low_catch_frac) else 0.0
	_glint(s, target, extra)
	# HIGH TIDE keystone: while EVERYONE is topped, the pour Glints the whole party.
	if _b("highTide") and _all_topped(s, seat, _brim_band()):
		for u in s.seats:
			if u.role != "healer" and u.alive() and u != target:
				_glint(s, u)
	# LEVEE creed / STILL WATER boon: a pour leaves an absorb cushion on the ally.
	var sh := _cr_f("pour_shield")
	if _b("stillWater"):
		sh = maxf(sh, cfg.still_water_frac)
	if sh > 0.0 and eff > 0.0:
		_add_absorb(s, target, eff * sh, seat)
	# SECOND RING boon: the pour ripples to the second-most-hurt ally.
	if _b("secondRing"):
		var second := _second_lowest(s, target)
		if second != null:
			_do_heal(s, second, eff * cfg.second_ring_frac, seat, &"ring")
	# FORESIGHT creed: bank a stack while the party is ahead.
	if _cr_b("foresight") and _all_topped(s, seat, 0.5):
		seat.vars["foresight"] = mini(5, int(seat.vars.get("foresight", 0)) + 1)
	# CADENCE OF MEND: extend the pour chain.
	seat.vars["pour_chain"] = int(seat.vars.get("pour_chain", 0)) + 1
	# BENEDICTION module: a good grade lights a pip.
	_bene_pip(s, seat)

## SKIN (the water's film — MENDER §13.2): the missing-heal cast. Sets a per-seat DEFERRAL on
## the ally for skin_dur seconds — the grade sizes the fraction (Draw grades the release; Brim
## casts it plain via mode "land"). It heals ZERO and blocks ZERO: the reducer's _tick_skin
## drains the deferred chunks later as real damage. The Still Point also fires the Glint (the
## F15 superset law). A graded Draw release feeds the Current like any clean/still draw — one
## grammar, the whole reason it's a cast and not a free proc.
func _apply_skin(s: CombatState, seat: Seat, target: Seat, mode: String) -> void:
	if target == null or not target.alive():
		return
	var frac := cfg.skin_defer_plain
	match mode:
		"still": frac = cfg.skin_defer_still
		"clean": frac = cfg.skin_defer_clean
		_:       frac = cfg.skin_defer_plain   # land (Brim) · overrun · under · held · instant
	target.vars["skin_until_tick"] = s.tick + _tt(s, cfg.skin_dur)
	target.vars["skin_frac"] = frac
	target.vars["skin_drip_ticks"] = maxi(1, _tt(s, cfg.skin_drip_sec))
	target.vars["skin_caster_i"] = s.seats.find(seat)   # index — cycle-safe co-op credit
	if mode == "still":
		_glint(s, target)
	CombatCore._bump_diag(s, seat, "well_skin")
	CombatCore._emit(s, {"t": "well_skin", "seat": target, "caster": seat, "player": seat.is_player, "frac": frac})
	if aspect == "draw":
		_draw_feedback(s, seat, mode, null)   # a graded skin release rides the Current/rig economy

## OVERFLOWING CUP boon: a share of the spill isn't wasted — it heals the most-hurt ally.
func _on_spill(s: CombatState, seat: Seat, over: float) -> void:
	if _b("overflowingCup"):
		var low := _lowest_living(s)
		if low != null:
			_do_heal(s, low, over * cfg.overflow_frac, seat, &"overflow")

## The DRAW release payoff: Current (inward) + Glint on a Still Point (outward) + boons.
func _draw_feedback(s: CombatState, seat: Seat, mode: String, target: Seat) -> void:
	match mode:
		"still":
			_current_up(s, seat)
			if target != null:
				_glint(s, target)
			CombatCore._bump_diag(s, seat, "well_pour")
			CombatCore._emit(s, {"t": "well_still", "seat": seat, "player": seat.is_player})
			_after_clean(s, seat)
			_rig_fire(s, seat, "still_point")
			if int(seat.vars.get("current", 0)) >= cfg.current_max:
				_rig_fire(s, seat, "high_water")
			_bene_pip(s, seat)
		"clean":
			_current_up(s, seat)
			CombatCore._emit(s, {"t": "well_clean", "seat": seat, "player": seat.is_player})
			_after_clean(s, seat)
			_rig_fire(s, seat, "clean_draw")
			if int(seat.vars.get("current", 0)) >= cfg.current_max:
				_rig_fire(s, seat, "high_water")
			_bene_pip(s, seat)
		"under":
			# EDDYLINE (boon): once per 10s an undercook DOWNGRADES the Current by 1 instead of
			# breaking it — costs the stack, and the sip still lands weak (a play, not a pardon).
			# A SAVE reads as its own event (well_eddyline), never the plain Current-break flash.
			if _b("eddyline") and s.tick >= int(seat.vars.get("eddyline_next", 0)) \
					and int(seat.vars.get("current", 0)) > 0:
				seat.vars["current"] = int(seat.vars.get("current", 0)) - 1
				seat.vars["eddyline_next"] = s.tick + _tt(s, cfg.eddyline_cd)
				CombatCore._emit(s, {"t": "well_eddyline", "seat": seat, "player": seat.is_player})
			else:
				if not _b("shortPour"):                      # SHORT POUR: the quick-sip keeps the Current
					_current_break(seat)
				CombatCore._emit(s, {"t": "well_under", "seat": seat, "player": seat.is_player})
		_:
			pass                                             # overrun / instant / held: plain, Current untouched

## Bookkeeping after a clean/still draw: Cool Hand's cd feed + Double Draw's chain stamp.
func _after_clean(s: CombatState, seat: Seat) -> void:
	if _b("coolHand"):
		var cd := int(seat.cooldowns.get("cascade", 0))
		if cd > s.tick:
			seat.cooldowns["cascade"] = maxi(s.tick, cd - _tt(s, cfg.cool_hand_cd))
	seat.vars["last_clean_tick"] = s.tick

# --- MODULES (auto-fire off a gauge) -------------------------------------------
func _tick_modules(s: CombatState, seat: Seat) -> void:
	# THE RESERVOIR: banking happens in on_heal; SURGE when the chamber fills.
	if _m("reservoir") and float(seat.vars.get("reserve", 0.0)) >= cfg.reserve_full:
		var bank := float(seat.vars["reserve"])
		var low := _lowest_living(s)
		if low != null:
			_do_heal(s, low, bank, seat, &"surge")
		seat.vars["reserve"] = bank * cfg.reserve_rebank    # the flywheel re-banks a share
		CombatCore._emit(s, {"t": "well_surge", "seat": seat, "player": seat.is_player, "amt": int(bank)})
	# TRIAGE PROTOCOL: bloodied allies build Nerve → LAST STAND fires itself.
	if _m("triage"):
		var bleeding := 0
		for u in s.seats:
			if u.role != "healer" and u.alive() and u.hp_frac() < cfg.nerve_at:
				bleeding += 1
		if bleeding > 0:
			seat.vars["nerve"] = float(seat.vars.get("nerve", 0.0)) + cfg.nerve_rate * float(bleeding) * s.dt
		if float(seat.vars.get("nerve", 0.0)) >= cfg.nerve_full:
			seat.vars["nerve"] = 0.0
			for u in s.seats:
				if u.role != "healer" and u.alive():
					_do_heal(s, u, cfg.last_stand_heal, seat, &"laststand")
			s.raid_dr = {"amt": cfg.last_stand_dr, "until_tick": s.tick + _tt(s, cfg.last_stand_dr_sec)}
			CombatCore._emit(s, {"t": "well_laststand", "seat": seat, "player": seat.is_player})

func _bene_pip(s: CombatState, seat: Seat) -> void:
	if not _m("benediction"):
		return
	var pips := int(seat.vars.get("bene", 0)) + 1
	if pips >= cfg.bene_pips:
		pips = 0
		for u in s.seats:
			if u.role != "healer" and u.alive():
				_do_heal(s, u, cfg.bene_heal, seat, &"benediction")
		CombatCore._emit(s, {"t": "well_bene", "seat": seat, "player": seat.is_player})
	seat.vars["bene"] = pips

func _tick_brink_bell(s: CombatState, seat: Seat) -> void:
	var used: Dictionary = seat.vars.get("bell_used", {})
	for i in range(s.seats.size()):
		var u := s.seats[i]
		if u.role == "healer" or not u.alive():
			continue
		if u.hp_frac() < cfg.brink_bell_at and not bool(used.get(i, false)):
			_add_absorb(s, u, cfg.brink_bell_absorb, seat)
			used[i] = true
			CombatCore._emit(s, {"t": "well_bell", "seat": u})
	seat.vars["bell_used"] = used

## THE SHINING HOUR (support boon): while EVERY ally is topped, the warband deals +damage.
## Sets a guarded per-ally aura the engine's group-damage step multiplies in (mirrors GLINT);
## refreshed each tick it holds, so it lapses within a couple ticks the moment the party dips.
func _tick_shining_hour(s: CombatState, seat: Seat) -> void:
	if not _all_topped(s, seat, cfg.shining_hour_floor):
		return
	var until := s.tick + 2
	for u in s.seats:
		if u.role != "healer" and u.alive():
			u.vars["well_hour_mult"] = cfg.shining_hour_mult
			u.vars["well_hour_until"] = until

# --- BOILING OVER (clutch damage dump) -----------------------------------------
func _boiling_over(s: CombatState, seat: Seat) -> void:
	var charges := _charges(seat)
	var dmg := cfg.boiling_base + cfg.boiling_per_charge * float(charges)
	seat.vars["charges"] = 0                                 # dump the whole Well
	if aspect == "draw":
		seat.vars["current"] = 0
	if s.boss.add_i >= 0:
		s.boss.add_hp = maxf(0.0, s.boss.add_hp - dmg)
	else:
		s.boss.hp = maxf(0.0, s.boss.hp - dmg)
	CombatCore.meter_dmg(s, seat, &"boil", dmg, false, false)
	CombatCore._emit(s, {"t": "well_boil", "seat": seat, "player": seat.is_player, "amt": int(dmg)})

# --- THE RIG (one wired WHEN→THEN; empty rig never touched → byte-identical base) ---
func _rig_fire(s: CombatState, seat: Seat, when_id: String) -> void:
	if rig.is_empty() or String(rig.get("when", "")) != when_id:
		return
	var then_id := String(rig.get("then", ""))
	match WellRig.then_kind(then_id):
		"heal":
			var low := _lowest_living(s)
			if low != null:
				_do_heal(s, low, float(WellRig.magnitude(when_id, then_id)), seat, &"rig")
		"shield":
			var low2 := _lowest_living(s)
			if low2 != null:
				_add_absorb(s, low2, float(WellRig.magnitude(when_id, then_id)), seat)
		"party":
			var per := float(WellRig.magnitude(when_id, then_id))
			for u in s.seats:
				if u.role != "healer" and u.alive():
					_do_heal(s, u, per, seat, &"rig")
		"charge":
			var acc := float(seat.vars.get("rig_charge_acc", 0.0)) + WellRig.raw_amount(when_id, then_id)
			if acc >= 1.0:
				_gain_charge(seat, int(acc))
				acc -= float(int(acc))
			seat.vars["rig_charge_acc"] = acc
		"glint":
			var low3 := _lowest_living(s)
			if low3 != null:
				_glint(s, low3, 0.0, WellRig.raw_amount(when_id, then_id))
	CombatCore._emit(s, {"t": "well_rig", "player": seat.is_player, "seat": seat, "when": when_id, "then": then_id})

# --- small helpers -------------------------------------------------------------
func _do_heal(s: CombatState, target: Seat, amt: float, caster: Seat, src: StringName) -> void:
	if target != null and target.alive() and amt > 0.0:
		CombatCore.heal_unit(s, target, amt, caster, src)

func _add_absorb(s: CombatState, target: Seat, amt: float, caster: Seat, secs: float = 12.0) -> void:
	if target == null or not target.alive() or amt <= 0.0:
		return
	target.absorb = minf(target.absorb + roundf(amt), target.hp_max)
	target.absorb_owner_i = s.seats.find(caster)            # co-op credit (index — cycle-safe)
	target.ward_until_tick = maxi(target.ward_until_tick, s.tick + _tt(s, secs))

## The still-pending deferred damage on an ally (the drip yet to land) — the HUD reads it to
## draw the film's trailing wound. 0.0 when the ally was never skinned (byte-neutral read).
func _skin_pending(u: Seat) -> float:
	var drip: Array = u.vars.get("skin_drip", [])
	var pending := 0.0
	for chunk in drip:
		pending += float(chunk.get("rem", 0.0))
	return pending

func _all_topped(s: CombatState, _seat: Seat, frac: float) -> bool:
	for u in s.seats:
		if u.role == "healer":
			continue
		if u.alive() and u.hp_frac() < frac:
			return false
	return true

func _lowest_living(s: CombatState) -> Seat:
	var best: Seat = null
	for u in s.seats:
		if u.role != "healer" and u.alive():
			if best == null or u.hp_frac() < best.hp_frac():
				best = u
	return best

func _second_lowest(s: CombatState, exclude: Seat) -> Seat:
	var best: Seat = null
	for u in s.seats:
		if u.role != "healer" and u.alive() and u != exclude:
			if best == null or u.hp_frac() < best.hp_frac():
				best = u
	return best

func _heal_lowest(s: CombatState, seat: Seat, n: int, amt: float, src: String) -> void:
	var living: Array = []
	for u in s.seats:
		if u.role != "healer" and u.alive():
			living.append(u)
	living.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
	for i in range(mini(n, living.size())):
		CombatCore.heal_unit(s, living[i], amt, seat, StringName(src))

# --- hooks ---------------------------------------------------------------------
## Creed flat + bloodied scaling — applied by heal_unit to EVERY heal from the Well. Empty
## creed → 1.0 (byte-identical base). Bloodied reads the target's pre-heal HP (Brink flywheel).
func heal_mult(target: Seat) -> float:
	var m := _cr_f("heal_mult")
	var bl := _cr_f("heal_bloodied")
	if bl > 0.0 and target != null:
		m *= 1.0 + bl * (1.0 - target.hp_frac())
	return m

func on_heal(_s: CombatState, _caster: Seat, _target: Seat, _eff: float, over: float) -> void:
	if _grading:
		_grading_over = over
	# THE RESERVOIR: every drop of overheal banks into the chamber.
	if _m("reservoir") and over > 0.0 and _caster != null:
		_caster.vars["reserve"] = float(_caster.vars.get("reserve", 0.0)) + over * cfg.reserve_bank

## THE ONE DODGE: the Well answers barrage beats on the single SPACE press (its only
## dodge — healers face no DEFENSIBLE swings), F retired (DODGE-PLAN.md 2026-07-08).
func unified_dodge() -> bool:
	return true

## Dodging cancels the cast bar — the healer's discipline test. Charges unspent (paid at
## resolve), Current untouched. A HELD (Patient Hand) heal survives — it's cocked, not casting.
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	if not seat.casting.is_empty() and not bool(seat.casting.get("held", false)):
		seat.casting = {}
		CombatCore._emit(s, {"t": "cast_cancelled"})

func observe(s: CombatState, seat: Seat) -> Dictionary:
	# The triage list. In a RAID the healer is personally hittable, so its own frame
	# joins the list (self-heal) — matching the human HUD's self-castable frame.
	var party: Array = []
	for u in s.seats:
		if u.role != "healer" or (s.threat_enabled and u == seat):
			var skinned := s.tick < int(u.vars.get("skin_until_tick", -1))
			party.append({"seat": u, "name": u.unit_name, "role": u.role,
				"frac": u.hp_frac(), "hp": u.hp, "max": u.hp_max, "absorb": u.absorb,
				"debuff": not u.debuff.is_empty(), "hots": u.hots.size(), "dead": not u.alive(),
				"skin": skinned, "skin_drip": _skin_pending(u)})
	var o := {
		"tick": s.tick,
		"aspect": aspect,
		"party": party,
		"casting": seat.casting,
		"raid": true,
		"charges": _charges(seat),
		"charges_max": _charges_max(),
		"current": int(seat.vars.get("current", 0)),
		"current_max": cfg.current_max,
		"brim_band": _brim_band(),
		"draw_band": _draw_band(),
		"still_point": _still_width(),
		"held": bool(seat.casting.get("held", false)),
		"held_start": int(seat.casting.get("held_start", -1)),   # tremble read (S5 render)
		"held_until": int(seat.casting.get("held_until", -1)),   # the gutter clock (AI hold-release)
		"hold_armed": _hold_armed(),                             # Patient Hand creed OR ⭐Vigil module
		"secondhand": _b("secondHand"),                          # off-hand flash stays castable while holding
		"blindfold": _b("blindfold"),
		"flume": s.tick < int(seat.vars.get("flume_until", -1)),       # RAPIDS: white water
		"frozen": s.tick < int(seat.vars.get("glassriver_until", -1)), # EDDY: still water
		"current_haste": cfg.current_haste,                            # per-stack cast-time cut (readout)
	}
	# THE MILLRACE: signal the next cast is free so the HUD can flag it before you press.
	if _b("theMillrace"):
		o["millrace_ready"] = _millrace_free(seat)
	# deck gauges (only meaningful when the module/creed is equipped — the HUD reads them then)
	if _m("reservoir"):
		o["reserve"] = float(seat.vars.get("reserve", 0.0))
		o["reserve_full"] = cfg.reserve_full
	if _m("triage"):
		o["nerve"] = float(seat.vars.get("nerve", 0.0))
		o["nerve_full"] = cfg.nerve_full
	if _m("benediction"):
		o["bene"] = int(seat.vars.get("bene", 0))
		o["bene_pips"] = cfg.bene_pips
	if _m("vigil"):
		o["hold_active"] = bool(seat.casting.get("held", false))
		o["hold_start"] = int(seat.casting.get("held_start", -1))
		o["hold_until"] = int(seat.casting.get("held_until", -1))   # the gutter clock (tremble render, S5)
	if _cr_b("foresight"):
		o["foresight"] = int(seat.vars.get("foresight", 0))
	if not seat.casting.is_empty():
		var c := seat.casting
		var dur := maxi(1, int(c["dur_ticks"]))
		o["cast_id"] = String(c["id"])
		o["cast_start"] = int(c["start_tick"])
		o["cast_dur"] = dur
		o["cast_p"] = clampf(float(s.tick - int(c["start_tick"])) / float(dur), 0.0, 1.0)
		# PER-CAST BAND GEOMETRY (DRAW) — the drifted, deck-adjusted release window so the HUD
		# draws the SAME window the kit grades (fixes THE EDDY not moving + Narrows/Long-Draw/
		# Deep-Still/Deep-Eddy widths). Read-only; mirrors _release exactly (shares _eddy_centre).
		if aspect == "draw":
			var band := _draw_band()
			var frz := s.tick < int(seat.vars.get("glassriver_until", -1))
			var centre := _eddy_centre(int(c["start_tick"]), band, frz)
			var sw := _still_width()
			o["draw_lo"] = centre - band * 0.5
			o["draw_hi"] = centre + band * 0.5           # true clean upper edge (< 1.0 when drifted)
			o["still_lo"] = centre - sw * 0.5
			o["still_hi"] = centre + sw * 0.5
			# CURRENT READING's fast-read sub-region (band's first third), when it can pay.
			if _b("currentReading") and not frz and not (s.tick < int(seat.vars.get("flume_until", -1))):
				o["cr_hi"] = (centre - band * 0.5) + band * cfg.currentreading_third
			# RIDE THE TREMBLE cap meter (0..1) + LOOSED AT LAST intercept-ready, when held.
			if bool(c.get("held", false)):
				if _b("rideTremble"):
					var halves := float(s.tick - int(c.get("held_start", s.tick))) / maxf(1.0, float(_tt(s, 0.5)))
					o["tremble_frac"] = clampf((cfg.ridetremble_per * halves) / maxf(0.001, cfg.ridetremble_cap), 0.0, 1.0)
				if _b("loosedAtLast"):
					var htgt: Seat = c.get("target")
					if htgt != null:
						var lh := int(htgt.vars.get("last_hit_tick", -999999))
						o["loosed_ready"] = lh >= 0 and (s.tick - lh) <= _tt(s, cfg.loosed_window)
	return o

## STATS PAGE v2 — the Well's spec rows for the FULL REPORT: pours cast, dispels, and the
## charge count at the final bell. Read-only from seat.diag / seat.vars; empty rows self-skip.
func recap_spec(_s: CombatState, seat: Seat) -> Array:
	var d: Dictionary = seat.diag
	var rows: Array = []
	if int(d.get("well_pour", 0)) > 0:
		rows.append({"label": "Pours", "value": str(int(d.get("well_pour", 0))), "hint": "charged heals cast"})
	if int(d.get("dispel", 0)) > 0:
		rows.append({"label": "Dispels", "value": str(int(d.get("dispel", 0))), "hint": ""})
	if int(d.get("well_skin", 0)) > 0:
		rows.append({"label": "Skins", "value": str(int(d.get("well_skin", 0))), "hint": "films cast"})
	var deferred := int(seat.vars.get("skin_deferred", 0.0))
	if deferred > 0:
		rows.append({"label": "Damage re-timed", "value": str(deferred), "hint": "deferred by Skin"})
	var cur := int(seat.vars.get("charges", -1))
	if cur >= 0:
		rows.append({"label": "Charges left", "value": str(cur), "hint": "at the final bell"})
	return rows
