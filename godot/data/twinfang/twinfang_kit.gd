## TwinfangKit — the Melee DPS class behaviour, ported from poc/twinfang.html. Energy
## + a rhythm-gated Strike + combo points + Flow (a damage multiplier you keep alive by
## chaining Perfects) + both Aspects (Tempo Flow-tiers/Coup, Venomancer typed-poison/
## Rupture). `boons` (drafted upgrade/relic ids) modify behaviour throughout.
##
## Faithful & deterministic: all class state lives in `seat.vars` (ticks are truth,
## the only randomness is the shared seeded `s.rng` for Contagion). No GCD — the rhythm
## paces your Strikes; other abilities gate on energy + their own cooldown.
class_name TwinfangKit
extends ClassKit

var aspect: String = "tempo"           ## "tempo" | "venomancer"
var cfg: TwinfangConfig
var boons: Dictionary = {}             ## id -> true (drafted upgrades/relics/spells)

func _init(_aspect: String, _cfg: TwinfangConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

# --------------------------------------------------------------------------
# Flow / combo / resource helpers
# --------------------------------------------------------------------------

func _flow(seat: Seat) -> int:
	return int(seat.vars.get("flow", 0))

func max_flow() -> int:
	return cfg.flow_max + (2 if _b("flowCap") else 0)

func _flow_mult(seat: Seat) -> float:
	return 1.0 + float(_flow(seat)) * cfg.flow_per

## Tempo transforms the kit in tiers as Flow climbs: 1 = double-hit Perfects,
## 2 = +combo & energy refund, 3 = Coup de Grâce ready (max Flow).
func flow_tier(seat: Seat) -> int:
	var f := _flow(seat)
	var t1 := 2 if _b("encore") else 3
	if f >= max_flow():
		return 3
	if f >= 5:
		return 2
	if f >= t1:
		return 1
	return 0

func _gain_flow(seat: Seat) -> void:
	seat.vars["flow"] = clampi(_flow(seat) + 1, 0, max_flow())
	seat.vars["flow_decay_acc"] = 0

func _gain_cp(seat: Seat, n: int) -> void:
	seat.vars["cp"] = clampi(int(seat.vars.get("cp", 0)) + n, 0, cfg.cp_max)

func _gain_energy(seat: Seat, x: float) -> void:
	seat.resource = clampf(seat.resource + x, 0.0, cfg.energy_max)

## The single outgoing-damage path: Flow multiplier, Execute relic, crit, then land.
## Poison ticks bypass this (they scale with neither Flow nor Execute — see _upkeep).
func _deal(s: CombatState, seat: Seat, raw: float, flow_scaled: bool, crit: bool) -> float:
	var d := raw
	if flow_scaled:
		d *= _flow_mult(seat)
	if _b("execute") and s.boss.hp_max > 0.0 and s.boss.hp / s.boss.hp_max < 0.35:
		d *= 1.3
	if crit:
		d *= 2.0
	d = roundf(d)
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	if d > 0.0:
		CombatCore.emit_event(s, {"t": "boss_hit", "amt": int(d), "crit": crit})
	return d

func _poison_boss(s: CombatState, dmg: float) -> void:
	var d := roundf(dmg)
	if d <= 0.0:
		return
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	CombatCore.emit_event(s, {"t": "poison", "amt": int(d)})

# --------------------------------------------------------------------------
# Venom (Venomancer): three poison types on the boss, kept in seat.vars.
# --------------------------------------------------------------------------

static func new_venom() -> Dictionary:
	return {"V": 0, "F": 0, "C": 0, "fes_ticks": 0, "syn_ramp": 1.0,
		"syn_active": false, "tick_acc": 0, "decay_acc": 0}

func _venom(seat: Seat) -> Dictionary:
	var v: Dictionary = seat.vars.get("venom", {})
	if v.is_empty():
		v = new_venom()
		seat.vars["venom"] = v
	return v

func _apply_venom(seat: Seat, type: String, n: int) -> void:
	var v := _venom(seat)
	v[type] = clampi(int(v[type]) + n, 0, cfg.ven_cap)

func _venom_total(seat: Seat) -> int:
	if aspect != "venomancer":
		return 0
	var v: Dictionary = seat.vars.get("venom", {})
	if v.is_empty():
		return 0
	return int(v["V"]) + int(v["F"]) + int(v["C"])

# --------------------------------------------------------------------------
# Per-tick upkeep: energy regen, Flow decay, and the Venomancer poison engine.
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	_gain_energy(seat, cfg.energy_regen * s.dt)

	# Flow decays toward 0 between Perfects (Virtuoso relic slows it 50%).
	if _flow(seat) > 0:
		var acc := int(seat.vars.get("flow_decay_acc", 0)) + 1
		var every := _tt(s, cfg.flow_decay_every * (1.5 if _b("virtuoso") else 1.0))
		if acc >= every:
			acc -= every
			seat.vars["flow"] = _flow(seat) - 1
		seat.vars["flow_decay_acc"] = acc

	if aspect == "venomancer":
		_tick_venom(s, seat)

func _tick_venom(s: CombatState, seat: Seat) -> void:
	var v := _venom(seat)

	# Stacks bleed off slowly — the cocktail won't sit at cap, you must maintain it.
	v["decay_acc"] = int(v["decay_acc"]) + 1
	var decay_every := _tt(s, cfg.venom_decay_every)
	while int(v["decay_acc"]) >= decay_every:
		v["decay_acc"] = int(v["decay_acc"]) - decay_every
		if int(v["V"]) > 0: v["V"] = int(v["V"]) - 1
		if int(v["F"]) > 0: v["F"] = int(v["F"]) - 1
		if int(v["C"]) > 0: v["C"] = int(v["C"]) - 1

	if int(v["F"]) > 0:
		v["fes_ticks"] = int(v["fes_ticks"]) + 1
	else:
		v["fes_ticks"] = 0

	var three: bool = int(v["V"]) > 0 and int(v["F"]) > 0 and int(v["C"]) > 0
	if three:
		v["syn_active"] = true
		var rate := cfg.syn_rate * (1.6 if _b("catalyst") else 1.0)
		v["syn_ramp"] = minf(cfg.syn_cap, float(v["syn_ramp"]) + rate * s.dt)
	else:
		v["syn_active"] = false
		v["syn_ramp"] = 1.0

	v["tick_acc"] = int(v["tick_acc"]) + 1
	var tick_every := _tt(s, cfg.venom_tick_every)
	while int(v["tick_acc"]) >= tick_every:
		v["tick_acc"] = int(v["tick_acc"]) - tick_every
		var pot := 1.3 if _b("potent") else 1.0
		var fes_sec := float(v["fes_ticks"]) * s.dt
		var dmg := float(v["V"]) * 1.8 * pot \
			+ float(v["F"]) * 1.5 * pot * (1.0 + (0.20 if _b("fastRot") else 0.12) * fes_sec) \
			+ float(v["C"]) * 1.1 * pot
		if three:
			dmg += float(int(v["V"]) + int(v["F"]) + int(v["C"])) * 0.5 * float(v["syn_ramp"]) * pot
		_poison_boss(s, dmg)

# --------------------------------------------------------------------------
# Incoming damage: Debilitate (Crippling softens the boss) + Flow reset on a swing.
# --------------------------------------------------------------------------

func modify_incoming(_s: CombatState, seat: Seat, dmg: float, _source: StringName, _size: int) -> float:
	if aspect == "venomancer" and _b("debilitate"):
		var v: Dictionary = seat.vars.get("venom", {})
		var c := int(v.get("C", 0)) if not v.is_empty() else 0
		if c > 0:
			return dmg * (1.0 - minf(0.30, float(c) * 0.04))
	return dmg

## Eating a swing wipes your Flow — the core tension. Swings carry a Size; the
## unavoidable Hex pulse and enrage do not, so only swings reset Flow (faithful).
func on_damage_taken(s: CombatState, seat: Seat, _dmg: float, _source: StringName, size: int) -> void:
	if size != AbilityRes.Size.NONE and _flow(seat) > 0:
		seat.vars["flow"] = 0
		seat.vars["flow_decay_acc"] = 0
		CombatCore.emit_event(s, {"t": "flow_lost", "player": seat.is_player})

## M7 string beats join the rhythm: a PERFECT dodge plays like a Perfect Strike
## (+1 Flow); a GOOD one pays a little energy; holding a feint keeps the song
## going. A LANDED beat wipes Flow through on_damage_taken above (beats carry a
## Size) — dodging protects the solo, exactly like dodging a swing does.
func on_strike_result(_s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT:
			_gain_flow(seat)
		StrikeRes.Grade.GOOD:
			_gain_energy(seat, cfg.strike_good_energy)
		StrikeRes.Grade.READ:
			_gain_energy(seat, cfg.strike_read_energy)
		_:
			pass

# --------------------------------------------------------------------------
# Dodge: a clean negate (no reflect). Riposte relic feeds combo on a dodge.
# --------------------------------------------------------------------------

func defense_active() -> float:
	return cfg.dodge_active

func defense_cd() -> float:
	return cfg.dodge_cd

func on_negate(_s: CombatState, seat: Seat, _ability: AbilityRes) -> void:
	if _b("dodgeCp"):
		_gain_cp(seat, 2)

# --------------------------------------------------------------------------
# Abilities
# --------------------------------------------------------------------------

func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match String(id):
		"strike":      return _strike(s, seat)
		"eviscerate":  return _eviscerate(s, seat)
		"kick":        return _kick(s, seat)
		"envenom":     return _envenom(s, seat)
		"flurry":      return _flurry(s, seat)
		"coupdegrace": return _coup(s, seat)
		"rupture":     return _rupture(s, seat)
	return false

## The rhythm. Strike too early (< swing_min) and it's ignored (no cost). In the green
## window it's a Perfect: 1.6× damage, +2 combo, +1 Flow, and the Aspect kickers fire.
func _strike(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["strike"]
	var last := int(seat.vars.get("last_strike_tick", -100000))
	var since := s.tick - last
	if since < _tt(s, cfg.swing_min):
		return false                                   # too early — the press is dropped
	var cost := float(a["energy"])
	if aspect == "tempo" and _b("syncopation") and _flow(seat) >= max_flow():
		cost = 0.0
	if seat.resource < cost:
		return false                                   # out of energy
	var perfect := since >= _tt(s, cfg.perfect_start) and since <= _tt(s, cfg.perfect_end)
	seat.resource -= cost
	seat.vars["last_strike_tick"] = s.tick

	var base := float(a["dmg"])
	var cp := int(a["cp"])
	if perfect:
		CombatCore._bump_diag(s, seat, "perfect_strike")   # class-signature skill signal (token mint)
		base = roundf(base * 1.6)
		cp = 2
		var crit := false
		if _b("fifthCrit"):
			var pc := int(seat.vars.get("perfect_count", 0)) + 1
			seat.vars["perfect_count"] = pc
			if pc % 5 == 0:
				crit = true
		_deal(s, seat, base, true, crit)
		_gain_flow(seat)
		CombatCore.emit_event(s, {"t": "perfect", "player": seat.is_player})
		if aspect == "tempo":
			var t := flow_tier(seat)
			if t >= 1:
				_deal(s, seat, roundf(float(a["dmg"]) * 0.6), true, false)   # Tier 1: extra hit
			if t >= 2:
				cp += 1                                                       # Tier 2: +combo, refund
				_gain_energy(seat, 6.0)
		elif aspect == "venomancer":
			_apply_venom(seat, "V", 1)                                       # Perfect → Virulent
			if _b("contagion"):
				_apply_venom(seat, ("F" if s.rng.next_float() < 0.5 else "C"), 1)
	else:
		_deal(s, seat, base, true, false)
		if aspect == "venomancer":
			_apply_venom(seat, "C", 1)                                       # normal → Crippling
	_gain_cp(seat, cp)
	if _b("strikeEnergy") and perfect:
		_gain_energy(seat, 6.0)
	# Tell the view HOW this strike landed so the rhythm bar can flash a clear, held
	# verdict — otherwise the bar instantly resets and reads "too early" on your next
	# cycle, which looks like it's judging the click you just nailed.
	var result := "perfect" if perfect else ("early" if since < _tt(s, cfg.perfect_start) else "late")
	CombatCore.emit_event(s, {"t": "strike", "player": seat.is_player, "result": result})
	return true

func _eviscerate(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["eviscerate"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	var per := float(a["per_cp"]) + (8.0 if _b("eviPlus") else 0.0)
	_deal(s, seat, per * float(cp), true, false)
	seat.vars["cp"] = 0
	CombatCore.emit_event(s, {"t": "finisher", "id": "eviscerate", "cp": cp})
	return true

func _kick(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["kick"]
	if s.tick < int(seat.cooldowns.get("kick", 0)) or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["kick"] = s.tick + _tt(s, float(a["cd"]))
	if s.telegraph != null and s.telegraph.ability.response == AbilityRes.Response.INTERRUPTIBLE:
		CombatCore.stagger_boss(s)                      # cancels the cast; emits "staggered"/DENIED
	else:
		CombatCore.emit_event(s, {"t": "kick_whiff", "player": seat.is_player})
	return true

func _envenom(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["envenom"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	_apply_venom(seat, "F", cp)                          # spends combo for Festering stacks
	seat.vars["cp"] = 0
	CombatCore.emit_event(s, {"t": "finisher", "id": "envenom", "cp": cp})
	return true

func _flurry(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["flurry"]
	if seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	for _i in int(a["hits"]):
		_deal(s, seat, float(a["dmg"]), true, false)
	_gain_cp(seat, int(a["cp"]))
	return true

func _coup(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["coupdegrace"]
	if s.tick < int(seat.cooldowns.get("coupdegrace", 0)):
		return false
	if _flow(seat) < max_flow() or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["coupdegrace"] = s.tick + _tt(s, float(a["cd"]))
	_deal(s, seat, float(a["dmg"]) * (1.4 if _b("crescendo") else 1.0), true, false)
	_gain_cp(seat, 3)                                    # refeeds combo → chain into Eviscerate
	CombatCore.emit_event(s, {"t": "coup", "player": seat.is_player})
	return true

func _rupture(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["rupture"]
	if s.tick < int(seat.cooldowns.get("rupture", 0)):
		return false
	var total := _venom_total(seat)
	if total < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["rupture"] = s.tick + _tt(s, float(a["cd"]))
	var per := float(a["per"]) * (1.4 if _b("rupturing") else 1.0)
	var v := _venom(seat)
	_deal(s, seat, float(total) * per * float(v["syn_ramp"]), true, false)
	v["V"] = 0; v["F"] = 0; v["C"] = 0
	v["fes_ticks"] = 0; v["syn_ramp"] = 1.0; v["syn_active"] = false
	CombatCore.emit_event(s, {"t": "rupture", "total": total})
	return true

# --------------------------------------------------------------------------
# Observation (policy + HUD). All view/AI fields — never part of the checksum.
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var last := int(seat.vars.get("last_strike_tick", -100000))
	var v: Dictionary = seat.vars.get("venom", {})
	return {
		"tick": s.tick,
		"aspect": aspect,
		"energy": seat.resource,
		"energy_max": cfg.energy_max,
		"cp": int(seat.vars.get("cp", 0)),
		"cp_max": cfg.cp_max,
		"flow": _flow(seat),
		"flow_max": max_flow(),
		"flow_mult": _flow_mult(seat),
		"tier": flow_tier(seat),
		"since_strike": s.tick - last,
		"swing_min_ticks": _tt(s, cfg.swing_min),
		"perfect_lo": _tt(s, cfg.perfect_start),
		"perfect_hi": _tt(s, cfg.perfect_end),
		"strike_cost": float(cfg.abilities["strike"]["energy"]),
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
		"kick_ready": s.tick >= int(seat.cooldowns.get("kick", 0)),
		"coup_ready": aspect == "tempo" and _flow(seat) >= max_flow() \
			and s.tick >= int(seat.cooldowns.get("coupdegrace", 0)),
		"rupture_ready": aspect == "venomancer" and _venom_total(seat) >= 1 \
			and s.tick >= int(seat.cooldowns.get("rupture", 0)),
		"venom": {"V": int(v.get("V", 0)), "F": int(v.get("F", 0)), "C": int(v.get("C", 0)),
			"syn_ramp": float(v.get("syn_ramp", 1.0)), "syn_active": bool(v.get("syn_active", false))},
		"venom_total": _venom_total(seat),
	}
