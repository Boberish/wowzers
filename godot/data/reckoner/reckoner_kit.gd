## ReckonerKit — the Warrior. Verb: COMMIT. An AUTO-ADVANCING swing clock (driven in
## upkeep) that the player SHAPES with two tick-stamped presses per swing:
##   "wind"   — commit; WHERE in the wind window you tap picks the WEIGHT.
##   "strike" — land the contracting apex; timing picks the POWER (True = full).
## No tap = the swing auto-resolves a mediocre Even × Glance (the accessible floor).
## Abilities: OVERSWING (arm → the wind grows an OVER end-zone for a huge blow),
## ULTRASWING (arm → an inserted bonus beat after the strike), ONSLAUGHT (the signature:
## suspend the clock, bank 3 winds + 3 strikes, resolve the SUM).
## Resources: RAGE (builds from swinging + taking chip), MOMENTUM (clock speed),
## POISE-BREAK (banked on True/Clash → a stagger/execute window; Colossus-weighted).
##
## Faithful & deterministic: all state in seat.vars (ints/floats/strings + seat indices,
## never Seat refs); the kit uses NO rng (the boss/policy own the seeds). No GCD.
class_name ReckonerKit
extends ClassKit

const PH_WIND := 0
const PH_FALL := 1
const PH_ULTRA := 2
const PH_SEQW := 3
const PH_SEQS := 4

var aspect: String = "colossus"      ## "colossus" (punishing) | "berserker" (forgiving)
var cfg: ReckonerConfig
var boons: Dictionary = {}

func _init(_aspect: String, _cfg: ReckonerConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

# --- small seat.vars accessors ---
func _ph(seat: Seat) -> int:      return int(seat.vars.get("phase", PH_WIND))
func _mom(seat: Seat) -> float:   return float(seat.vars.get("momentum", 0.0))
func _poise(seat: Seat) -> float: return float(seat.vars.get("poise", 0.0))

func _gain_rage(seat: Seat, x: float) -> void:
	seat.resource = clampf(seat.resource + x, 0.0, cfg.rage_max)

func _true_half(s: CombatState) -> int:
	return maxi(1, _tt(s, cfg.true_half) + (2 if _b("rkSteady") else 0))

# --------------------------------------------------------------------------
# Weight / power grid
# --------------------------------------------------------------------------

func _weight_at(f: float) -> String:
	if _b("rkSwap"):
		if f < cfg.quick_hi: return "Quick"
		elif f < cfg.even_hi: return "Heavy"
		return "Even"
	if _b("rkSnap") and f < 0.13: return "Snap"
	if _b("rkBrink") and f >= 0.88: return "Brink"
	if f < cfg.quick_hi: return "Quick"
	elif f < cfg.even_hi: return "Even"
	return "Heavy"

func _wmult(weight: String) -> float:
	var m := cfg.w_even
	match weight:
		"Quick": m = cfg.w_quick
		"Even": m = cfg.w_even
		"Heavy": m = cfg.w_heavy
		"Over": m = cfg.w_over
		"Snap": m = cfg.w_snap
		"Brink": m = cfg.w_brink
	if _b("rkHeavyFocus") and (weight == "Heavy" or weight == "Over" or weight == "Brink"):
		m *= 1.35
	return m

func _pmult(power: String) -> float:
	if aspect == "berserker":
		match power:
			"Finesse": return cfg.pb_finesse
			"True": return cfg.pb_true
			"Overload": return cfg.pb_overload
		return cfg.pb_glance
	match power:
		"Finesse": return cfg.p_finesse
		"True": return cfg.p_true
		"Overload": return cfg.p_overload
	return cfg.p_glance

## Berserker: Momentum snowballs damage (the forgiving aspect's floor); Colossus relies
## on tight True + Poise-Break executes (no passive scaling — the punishing aspect).
func outgoing_mult(seat: Seat) -> float:
	if aspect == "berserker":
		return 1.0 + _mom(seat) * cfg.bers_out_per_mom
	return 1.0

## Grade the STRIKE press: press tick vs the apex tick.
func _power_grade(s: CombatState, seat: Seat, press_tick: int) -> String:
	var d := press_tick - int(seat.vars.get("apex_tick", press_tick))
	var th := _true_half(s)
	if d < -th: return "Finesse"
	elif d <= th: return "True"
	return "Overload"   # anything past True (a real press) crushes; no tap = Glance (auto)

# --------------------------------------------------------------------------
# Damage funnel (mirrors TwinfangKit._deal — direct hp + meter + view event)
# --------------------------------------------------------------------------

func _deal(s: CombatState, seat: Seat, raw: float, kind := "swing") -> float:
	var d := roundf(raw * outgoing_mult(seat))   # direct path bypasses damage_boss, so apply it here
	if d <= 0.0:
		return 0.0
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	CombatCore.meter_dmg(s, seat, StringName(kind), d, false)
	CombatCore.emit_event(s, {"t": "boss_hit", "amt": int(d), "crit": false, "kind": kind, "seat": seat})
	return d

# --------------------------------------------------------------------------
# Per-tick upkeep: advance the auto-swing phase machine (timeouts → auto-resolve).
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	var ph := _ph(seat)
	if ph == PH_WIND:
		var ws := int(seat.vars.get("wind_start", 0))
		if s.tick > ws + _tt(s, cfg.wind_len):
			_commit(s, seat, "Even", ws + _tt(s, cfg.wind_len))   # no tap → mediocre auto-Even
	elif ph == PH_FALL:
		var dl := int(seat.vars.get("apex_tick", 0)) + _tt(s, cfg.overload_late) + _tt(s, cfg.strike_deadline)
		if s.tick > dl:
			_resolve_swing(s, seat, "Glance")
	elif ph == PH_ULTRA:
		var dlu := int(seat.vars.get("ultra_apex", 0)) + _tt(s, cfg.overload_late) + _tt(s, cfg.strike_deadline)
		if s.tick > dlu:
			_resolve_ultra(s, seat, "Glance")
	elif ph == PH_SEQW:
		if s.tick > int(seat.vars.get("seq_substart", 0)) + _tt(s, cfg.seq_wind):
			_bank_wind(s, seat, "Even")
	elif ph == PH_SEQS:
		var dls := int(seat.vars.get("seq_subapex", 0)) + _tt(s, cfg.overload_late) + _tt(s, cfg.strike_deadline)
		if s.tick > dls:
			_bank_strike(s, seat, "Glance")

# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------

func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match String(id):
		"wind":       return _press_wind(s, seat)
		"strike":     return _press_strike(s, seat)
		"overswing":  return _arm_over(s, seat)
		"ultraswing": return _arm_ultra(s, seat)
		"onslaught", "sunder", "berserk": return _start_onslaught(s, seat)
	return false

func _press_wind(s: CombatState, seat: Seat) -> bool:
	var ph := _ph(seat)
	if ph == PH_WIND:
		var ws := int(seat.vars.get("wind_start", 0))
		if s.tick < ws:
			return false                        # window not open yet
		var f := clampf(float(s.tick - ws) / float(maxi(1, _tt(s, cfg.wind_len))), 0.0, 0.999)
		var weight := "Over" if bool(seat.vars.get("over_armed", false)) and f >= cfg.over_lo else _weight_at(f)
		_commit(s, seat, weight, s.tick)
		return true
	elif ph == PH_SEQW:
		var ss := int(seat.vars.get("seq_substart", 0))
		if s.tick < ss:
			return false
		var f2 := clampf(float(s.tick - ss) / float(maxi(1, _tt(s, cfg.seq_wind))), 0.0, 0.999)
		_bank_wind(s, seat, _weight_at(f2))
		return true
	return false

func _commit(s: CombatState, seat: Seat, weight: String, at_tick: int) -> void:
	seat.vars["over_armed"] = false
	seat.vars["weight"] = weight
	seat.vars["commit_tick"] = at_tick
	seat.vars["apex_tick"] = at_tick + _tt(s, cfg.apex_delay)
	seat.vars["phase"] = PH_FALL

func _press_strike(s: CombatState, seat: Seat) -> bool:
	var ph := _ph(seat)
	if ph == PH_FALL:
		_resolve_swing(s, seat, _power_grade(s, seat, s.tick))
		return true
	elif ph == PH_ULTRA:
		var d := s.tick - int(seat.vars.get("ultra_apex", s.tick))
		var th := _true_half(s)
		var power := "Finesse" if d < -th else ("True" if d <= th else "Overload")
		_resolve_ultra(s, seat, power)
		return true
	elif ph == PH_SEQS:
		_bank_strike(s, seat, _power_grade_seq(s, seat, s.tick))
		return true
	return false

func _power_grade_seq(s: CombatState, seat: Seat, press_tick: int) -> String:
	var d := press_tick - int(seat.vars.get("seq_subapex", press_tick))
	var th := _true_half(s)
	if d < -th: return "Finesse"
	elif d <= th: return "True"
	return "Overload"

# --------------------------------------------------------------------------
# Resolve a normal swing
# --------------------------------------------------------------------------

func _resolve_swing(s: CombatState, seat: Seat, power: String) -> void:
	var weight := String(seat.vars.get("weight", "Even"))
	var clashed := _try_clash(s, seat, power)
	var mult := _wmult(weight) * _pmult(power)
	if clashed:
		mult *= cfg.clash_bonus
	if s.tick < int(seat.vars.get("stagger_until", 0)):
		mult *= cfg.stagger_bonus
	var kind := "overswing" if weight == "Over" else ("true" if power == "True" else "swing")
	_deal(s, seat, cfg.base_swing * mult, kind)

	# rage
	var rg := cfg.rage_even
	if weight == "Heavy" or weight == "Over" or weight == "Brink": rg = cfg.rage_heavy
	elif weight == "Quick": rg = cfg.rage_quick
	_gain_rage(seat, rg)

	# momentum (clock speed)
	var mom := _mom(seat)
	if power == "True": mom = minf(cfg.momentum_max, mom + cfg.mom_gain_true)
	elif power == "Glance": mom = maxf(0.0, mom - cfg.mom_loss_glance)
	else: mom = maxf(0.0, mom - 1.0)
	seat.vars["momentum"] = mom

	# poise-break (Colossus-weighted) → stagger/execute window
	if power == "True" or power == "Overload":
		var pg := cfg.poise_true_colossus if aspect == "colossus" else cfg.poise_true_berserker
		if clashed: pg += cfg.poise_clash
		var poise := _poise(seat) + pg
		if poise >= cfg.poise_max:
			poise = 0.0
			seat.vars["stagger_until"] = s.tick + _tt(s, cfg.stagger_dur)
			CombatCore.emit_event(s, {"t": "poise_break", "player": seat.is_player, "seat": seat})
		seat.vars["poise"] = poise
		if power == "True":
			CombatCore._bump_diag(s, seat, "apex")   # class-signature skill signal (token mint)

	CombatCore.emit_event(s, {"t": "swing", "player": seat.is_player, "weight": weight,
		"power": power, "clash": clashed})

	# recover → the next wind, or insert an Ultraswing
	var rec := _tt(s, cfg.over_recover if weight == "Over" else cfg.recover)
	seat.vars["weight"] = ""
	if bool(seat.vars.get("ultra_armed", false)):
		seat.vars["ultra_armed"] = false
		seat.vars["phase"] = PH_ULTRA
		seat.vars["ultra_start"] = s.tick
		seat.vars["ultra_apex"] = s.tick + _tt(s, cfg.ultra_delay)
	else:
		_open_wind(s, seat, s.tick + rec)

func _open_wind(s: CombatState, seat: Seat, base_tick: int) -> void:
	var gap := maxi(_tt(s, cfg.gap_floor), _tt(s, cfg.base_gap) - int(_mom(seat)))
	seat.vars["wind_start"] = base_tick + gap
	seat.vars["phase"] = PH_WIND

func _resolve_ultra(s: CombatState, seat: Seat, power: String) -> void:
	var m := cfg.ultra_glance
	match power:
		"True": m = cfg.ultra_true
		"Overload": m = cfg.ultra_overload
		"Finesse": m = cfg.ultra_finesse
	_deal(s, seat, cfg.ultra_base * m, "ultra")
	_gain_rage(seat, cfg.rage_quick)
	CombatCore.emit_event(s, {"t": "ultra", "player": seat.is_player, "power": power})
	_open_wind(s, seat, s.tick + _tt(s, cfg.recover))

# --------------------------------------------------------------------------
# Onslaught (the signature): suspend the clock, bank 3 winds + 3 strikes, sum them.
# --------------------------------------------------------------------------

func _start_onslaught(s: CombatState, seat: Seat) -> bool:
	if _ph(seat) != PH_WIND:
		return false
	if s.tick < int(seat.cooldowns.get("onslaught", 0)) or seat.resource < cfg.ons_cost:
		return false
	seat.resource -= cfg.ons_cost
	seat.cooldowns["onslaught"] = s.tick + _tt(s, cfg.ons_cd)
	seat.vars["seq_winds"] = []
	seat.vars["seq_strikes"] = []
	seat.vars["seq_substart"] = s.tick
	seat.vars["phase"] = PH_SEQW
	CombatCore.emit_event(s, {"t": "onslaught_start", "player": seat.is_player})
	return true

func _bank_wind(s: CombatState, seat: Seat, weight: String) -> void:
	var w: Array = seat.vars.get("seq_winds", [])
	w.append(weight)
	seat.vars["seq_winds"] = w
	if w.size() < 3:
		seat.vars["seq_substart"] = s.tick
	else:
		seat.vars["seq_subapex"] = s.tick + _tt(s, cfg.seq_apex)
		seat.vars["phase"] = PH_SEQS

func _bank_strike(s: CombatState, seat: Seat, power: String) -> void:
	var p: Array = seat.vars.get("seq_strikes", [])
	p.append(power)
	seat.vars["seq_strikes"] = p
	if p.size() < 3:
		seat.vars["seq_subapex"] = s.tick + _tt(s, cfg.seq_apex)
	else:
		_resolve_onslaught(s, seat)

func _resolve_onslaught(s: CombatState, seat: Seat) -> void:
	var w: Array = seat.vars.get("seq_winds", [])
	var p: Array = seat.vars.get("seq_strikes", [])
	var total := 0.0
	var all_true := true
	for i in 3:
		var wi := String(w[i]) if i < w.size() else "Even"
		var pi := String(p[i]) if i < p.size() else "Glance"
		total += cfg.ons_base * _wmult(wi) * _pmult(pi)
		if pi != "True":
			all_true = false
	if all_true:
		total *= cfg.ons_all_true
	if s.tick < int(seat.vars.get("stagger_until", 0)):
		total *= cfg.stagger_bonus
	_deal(s, seat, total, "onslaught")
	var poise := _poise(seat) + 20.0
	if poise >= cfg.poise_max:
		poise = 0.0
		seat.vars["stagger_until"] = s.tick + _tt(s, cfg.stagger_dur)
	seat.vars["poise"] = poise
	CombatCore.emit_event(s, {"t": "onslaught", "player": seat.is_player, "all_true": all_true})
	seat.vars["seq_winds"] = []
	seat.vars["seq_strikes"] = []
	_open_wind(s, seat, s.tick + _tt(s, cfg.recover) + 4)

# --------------------------------------------------------------------------
# Clash: release the apex onto a boss impact tick → negate the swing (defensible only).
# --------------------------------------------------------------------------

func _try_clash(s: CombatState, seat: Seat, power: String) -> bool:
	if power != "True" and power != "Overload":
		return false
	if s.telegraph == null:
		return false
	if s.telegraph.ability.response != AbilityRes.Response.DEFENSIBLE:
		return false
	if s.telegraph.target != seat:
		return false
	var impact := s.telegraph.start_tick + s.telegraph.dur_ticks
	if absi(s.tick - impact) <= _tt(s, cfg.clash_window):
		CombatCore._bump_diag(s, seat, "clash")
		CombatCore.emit_event(s, {"t": "negate", "player": seat.is_player, "seat": seat,
			"size": s.telegraph.ability.size, "feint": s.telegraph.ability.feint})
		s.telegraph = null
		return true
	return false

# --------------------------------------------------------------------------
# Arming abilities
# --------------------------------------------------------------------------

func _arm_over(s: CombatState, seat: Seat) -> bool:
	if s.tick < int(seat.cooldowns.get("overswing", 0)) or seat.resource < cfg.over_cost:
		return false
	seat.resource -= cfg.over_cost
	seat.cooldowns["overswing"] = s.tick + _tt(s, cfg.over_cd)
	seat.vars["over_armed"] = true
	return true

func _arm_ultra(s: CombatState, seat: Seat) -> bool:
	if s.tick < int(seat.cooldowns.get("ultraswing", 0)) or seat.resource < cfg.ultra_cost:
		return false
	seat.resource -= cfg.ultra_cost
	seat.cooldowns["ultraswing"] = s.tick + _tt(s, cfg.ultra_cd)
	seat.vars["ultra_armed"] = true
	return true

# --------------------------------------------------------------------------
# Incoming damage: Berserker mitigation + the greed loop (chip feeds Rage).
# --------------------------------------------------------------------------

func modify_incoming(_s: CombatState, seat: Seat, dmg: float, _source: StringName, _size: int) -> float:
	if aspect == "berserker":
		return dmg * (1.0 - minf(cfg.bers_dr_cap, _mom(seat) * cfg.bers_dr_per_mom))
	return dmg

func on_damage_taken(_s: CombatState, seat: Seat, _dmg: float, _source: StringName, size: int) -> void:
	if size != AbilityRes.Size.NONE:
		_gain_rage(seat, cfg.rage_on_hit)   # being hit feeds you — swing through the danger

# --------------------------------------------------------------------------
# The dodge (defensive verb): negate a heavy swing, bank a little Rage + Poise.
# --------------------------------------------------------------------------

func defense_active() -> float:
	return cfg.def_active

func defense_cd() -> float:
	return cfg.def_cd

func on_negate(_s: CombatState, seat: Seat, _ability: AbilityRes) -> void:
	_gain_rage(seat, 6.0)
	seat.vars["poise"] = minf(cfg.poise_max, _poise(seat) + 6.0)

# --------------------------------------------------------------------------
# Observation (policy + HUD)
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var ph := _ph(seat)
	var wl := maxi(1, _tt(s, cfg.wind_len))
	var ws := int(seat.vars.get("wind_start", 0))
	var apex := int(seat.vars.get("apex_tick", 0))
	if ph == PH_ULTRA:
		apex = int(seat.vars.get("ultra_apex", 0))
	elif ph == PH_SEQS:
		apex = int(seat.vars.get("seq_subapex", 0))
	var seq_ss := int(seat.vars.get("seq_substart", 0))
	return {
		"tick": s.tick,
		"aspect": aspect,
		"phase": ph,
		"rage": seat.resource,
		"rage_max": cfg.rage_max,
		"momentum": _mom(seat),
		"momentum_max": cfg.momentum_max,
		"poise": _poise(seat),
		"poise_max": cfg.poise_max,
		"over_armed": bool(seat.vars.get("over_armed", false)),
		"ultra_armed": bool(seat.vars.get("ultra_armed", false)),
		"wind_open": ph == PH_WIND and s.tick >= ws,
		"since_wind": (s.tick - ws) if ph == PH_WIND else 0,
		"seq_since_wind": (s.tick - seq_ss) if ph == PH_SEQW else 0,
		"wind_len": wl,
		"even_lo": int(cfg.quick_hi * wl),
		"heavy_lo": int(cfg.even_hi * wl),
		"over_lo": int(cfg.over_lo * wl),
		"to_apex": (apex - s.tick) if (ph == PH_FALL or ph == PH_ULTRA or ph == PH_SEQS) else 999,
		"true_half": _true_half(s),
		"over_ready": s.tick >= int(seat.cooldowns.get("overswing", 0)) and seat.resource >= cfg.over_cost,
		"ultra_ready": s.tick >= int(seat.cooldowns.get("ultraswing", 0)) and seat.resource >= cfg.ultra_cost,
		"ons_ready": s.tick >= int(seat.cooldowns.get("onslaught", 0)) and seat.resource >= cfg.ons_cost,
		"stagger": s.tick < int(seat.vars.get("stagger_until", 0)),
		"def_zone": cfg.def_zone,
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
	}
