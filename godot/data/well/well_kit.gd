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
##   → plain full heal, Current untouched. THE CURRENT is a cast-haste streak (max
##   current_max, +current_haste/stack) that breaks on an undercook or a DRY well and
##   ebbs when idle.
## GLINT is personal: the healed ally's seat.vars glint_mult/glint_until, read by the
##   engine's group-damage step (guarded → byte-identical when unset).
class_name WellKit
extends ClassKit

var aspect: String = "brim"
var cfg: WellConfig
var boons: Dictionary = {}

# on_heal grading stash (heal_unit doesn't return overheal; capture it during a graded cast)
var _grading: bool = false
var _grading_over: float = 0.0

func _init(_aspect: String, _cfg: WellConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

# --- charges -------------------------------------------------------------------
func _charges(seat: Seat) -> int:
	return int(seat.vars.get("charges", 0))

func _spend_charge(seat: Seat, n: int) -> void:
	var c := maxi(0, _charges(seat) - n)
	seat.vars["charges"] = c
	# running the Well DRY breaks the Current (Draw): the rush burns its own fuel.
	if c == 0 and aspect == "draw" and int(seat.vars.get("current", 0)) > 0:
		seat.vars["current"] = 0

func _gain_charge(seat: Seat, n: int) -> void:
	seat.vars["charges"] = mini(cfg.charges_max, _charges(seat) + n)

# --- THE CURRENT (draw) --------------------------------------------------------
func _current_up(s: CombatState, seat: Seat) -> void:
	seat.vars["current"] = mini(cfg.current_max, int(seat.vars.get("current", 0)) + 1)
	seat.vars["current_ebb_next"] = s.tick + _tt(s, cfg.current_ebb)

func _current_break(seat: Seat) -> void:
	seat.vars["current"] = 0

# --- THE GLINT (personal — the healed ally) ------------------------------------
func _glint(s: CombatState, target: Seat) -> void:
	if target == null:
		return
	target.vars["glint_mult"] = cfg.glint_mult
	target.vars["glint_until"] = s.tick + _tt(s, cfg.glint_dur)
	CombatCore._emit(s, {"t": "well_glint", "seat": target})

# --- per-tick: charge pulse, Current ebb, cast resolution ----------------------
func upkeep(s: CombatState, seat: Seat) -> void:
	# charge pulse (the only base income)
	var np := int(seat.vars.get("pulse_next", 0))
	if np <= 0:
		seat.vars["pulse_next"] = s.tick + _tt(s, cfg.pulse_every)
	elif s.tick >= np:
		_gain_charge(seat, cfg.pulse_amount)
		seat.vars["pulse_next"] = s.tick + _tt(s, cfg.pulse_every)

	# THE CURRENT ebbs when you stop drawing
	if aspect == "draw" and int(seat.vars.get("current", 0)) > 0:
		var eb := int(seat.vars.get("current_ebb_next", 0))
		if s.tick >= eb:
			seat.vars["current"] = int(seat.vars.get("current", 0)) - 1
			seat.vars["current_ebb_next"] = s.tick + _tt(s, cfg.current_ebb)

	# resolve a finished cast
	if not seat.casting.is_empty():
		var c := seat.casting
		var tgt: Seat = c.get("target")
		if tgt != null and not tgt.alive() and String(c["id"]) != "rekindle":
			seat.casting = {}
			CombatCore._emit(s, {"t": "cast_cancelled"})
		elif s.tick - int(c["start_tick"]) >= int(c["dur_ticks"]):
			var id := String(c["id"])
			seat.casting = {}
			# BRIM grades the landing at resolve; DRAW auto-completes plain (OVERRUN).
			_resolve(s, seat, id, tgt, ("land" if aspect == "brim" else "overrun"))

# --- input: cast start / release -----------------------------------------------
func on_action(s: CombatState, seat: Seat, id: StringName, target: Seat = null) -> bool:
	var key := String(id)
	if key == "release":
		return _release(s, seat)
	var sp: Dictionary = cfg.book.get(key, {})
	if sp.is_empty():
		return false
	var offgcd := bool(sp.get("offgcd", false))
	if not offgcd and s.tick < seat.gcd_until_tick:
		return false
	if s.tick < int(seat.cooldowns.get(key, 0)):
		return false
	if not offgcd and not seat.casting.is_empty():
		return false
	# target validity
	if key == "rekindle":
		if target == null or target.alive():          # rekindle needs a DEAD ally
			return false
	elif bool(sp.get("target", false)):
		if target == null or not target.alive():
			return false
		if key == "dispel" and target.debuff.is_empty():
			return false
	# affordability (checked at start; charges paid at resolve)
	if _charges(seat) < int(sp.get("charges", 0)):
		return false

	var cast := float(sp.get("cast", 0.0))
	if cast > 0.0:
		var dur := cast
		if aspect == "draw":
			dur = cast * (1.0 - cfg.current_haste * float(int(seat.vars.get("current", 0))))
		var ct := maxi(1, _tt(s, dur))
		seat.casting = {"id": key, "target": target, "start_tick": s.tick, "dur_ticks": ct}
		if not offgcd:
			seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)   # GCD runs from cast START
		CombatCore._emit(s, {"t": "cast_started", "id": key, "dur": dur})
		return true
	# instant (dispel)
	_resolve(s, seat, key, target, "instant")
	return true

## DRAW's release: grade the timing and resolve early. No-op in BRIM or with no cast.
func _release(s: CombatState, seat: Seat) -> bool:
	if aspect != "draw" or seat.casting.is_empty():
		return false
	var c := seat.casting
	var start := int(c["start_tick"])
	var dur := int(c["dur_ticks"])
	var elapsed := s.tick - start
	if elapsed >= dur:
		return false                                   # at/past the end — upkeep handles OVERRUN
	var p := float(elapsed) / float(dur)
	var id := String(c["id"])
	var tgt: Seat = c.get("target")
	seat.casting = {}
	if p >= 1.0 - cfg.draw_band:
		var centre := 1.0 - cfg.draw_band * 0.5
		if absf(p - centre) <= cfg.still_point * 0.5:
			_resolve(s, seat, id, tgt, "still")
		else:
			_resolve(s, seat, id, tgt, "clean")
	else:
		_resolve(s, seat, id, tgt, "under", pow(maxf(0.05, p), cfg.undercook_exp))
	return true

# --- resolution ----------------------------------------------------------------
## mode ∈ {land, instant} (brim/dispel) | {clean, still, under, overrun} (draw).
func _resolve(s: CombatState, seat: Seat, id: String, target: Seat, mode: String, mult: float = 1.0) -> void:
	var sp: Dictionary = cfg.book[id]
	_spend_charge(seat, int(sp.get("charges", 0)))

	match id:
		"flash", "mend":
			_direct_heal(s, seat, target, float(sp["heal"]) * mult, id, mode)
		"cascade":
			_heal_lowest(s, seat, int(sp.get("aoe", 3)), float(sp["heal"]) * mult, id)
			_draw_feedback(s, seat, mode, null)        # AoE: Current only, no Glint (base)
		"spring":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					CombatCore.heal_unit(s, u, float(sp["heal"]) * mult, seat, &"spring")
			_draw_feedback(s, seat, mode, null)
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

## A single-target heal (flash/mend) with the aspect grade.
func _direct_heal(s: CombatState, seat: Seat, target: Seat, amt: float, id: String, mode: String) -> void:
	if target == null or not target.alive():
		return
	_grading = true
	_grading_over = 0.0
	CombatCore.heal_unit(s, target, amt, seat, StringName(id))   # fires on_heal → stashes overheal
	_grading = false
	var over := _grading_over

	if aspect == "brim":
		if over > cfg.spill_eps:
			CombatCore._emit(s, {"t": "well_spill", "seat": seat, "player": seat.is_player, "amt": int(over)})
		elif target.hp_frac() >= cfg.brim_band:
			_glint(s, target)
			CombatCore._bump_diag(s, seat, "well_pour")           # class-signature skill signal
			CombatCore._emit(s, {"t": "well_pour", "seat": seat, "player": seat.is_player})
		else:
			CombatCore._emit(s, {"t": "well_plain", "seat": seat, "player": seat.is_player})
	else:
		_draw_feedback(s, seat, mode, target)

## The DRAW release payoff: Current (inward) + Glint on a Still Point (outward).
func _draw_feedback(s: CombatState, seat: Seat, mode: String, target: Seat) -> void:
	match mode:
		"still":
			_current_up(s, seat)
			if target != null:
				_glint(s, target)
			CombatCore._bump_diag(s, seat, "well_pour")
			CombatCore._emit(s, {"t": "well_still", "seat": seat, "player": seat.is_player})
		"clean":
			_current_up(s, seat)
			CombatCore._emit(s, {"t": "well_clean", "seat": seat, "player": seat.is_player})
		"under":
			_current_break(seat)
			CombatCore._emit(s, {"t": "well_under", "seat": seat, "player": seat.is_player})
		_:
			pass                                        # overrun / instant: plain, Current untouched

func _heal_lowest(s: CombatState, seat: Seat, n: int, amt: float, src: String) -> void:
	var living: Array = []
	for u in s.seats:
		if u.role != "healer" and u.alive():
			living.append(u)
	living.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
	for i in range(mini(n, living.size())):
		CombatCore.heal_unit(s, living[i], amt, seat, StringName(src))

# --- hooks ---------------------------------------------------------------------
func heal_mult(_target: Seat) -> float:
	return 1.0                                          # Brink creed overrides this later

func on_heal(_s: CombatState, _caster: Seat, _target: Seat, _eff: float, over: float) -> void:
	if _grading:
		_grading_over = over

## Dodging cancels the cast bar — the healer's discipline test. Charges unspent
## (paid at resolve), Current untouched (only an undercook/DRY breaks it).
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	if not seat.casting.is_empty():
		seat.casting = {}
		CombatCore._emit(s, {"t": "cast_cancelled"})

func observe(s: CombatState, seat: Seat) -> Dictionary:
	# The triage list. In a RAID the healer is personally hittable, so its own frame
	# joins the list (self-heal) — matching the human HUD's self-castable frame.
	var party: Array = []
	for u in s.seats:
		if u.role != "healer" or (s.threat_enabled and u == seat):
			party.append({"seat": u, "name": u.unit_name, "role": u.role,
				"frac": u.hp_frac(), "hp": u.hp, "max": u.hp_max, "absorb": u.absorb,
				"debuff": not u.debuff.is_empty(), "hots": u.hots.size(), "dead": not u.alive()})
	var o := {
		"tick": s.tick,
		"aspect": aspect,
		"party": party,
		"casting": seat.casting,
		"raid": true,
		"charges": _charges(seat),
		"charges_max": cfg.charges_max,
		"current": int(seat.vars.get("current", 0)),
		"current_max": cfg.current_max,
		"brim_band": cfg.brim_band,
		"draw_band": cfg.draw_band,
		"still_point": cfg.still_point,
	}
	if not seat.casting.is_empty():
		var c := seat.casting
		var dur := maxi(1, int(c["dur_ticks"]))
		o["cast_id"] = String(c["id"])
		o["cast_start"] = int(c["start_tick"])
		o["cast_dur"] = dur
		o["cast_p"] = clampf(float(s.tick - int(c["start_tick"])) / float(dur), 0.0, 1.0)
	return o
