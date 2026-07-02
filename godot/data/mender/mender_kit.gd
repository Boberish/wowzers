## MenderKit — the Healer class behaviour on the player seat. Mana + a player cast
## bar + the full heal spellbook + both Aspects (Tidecaller Reservoir/Surge,
## Brinkwarden low-HP scaling / Nerve / Last Stand). Ported from poc/mender.html.
class_name MenderKit
extends ClassKit

var aspect: String = "tidecaller"
var cfg: MenderConfig
var boons: Dictionary = {}

func _init(_aspect: String, _cfg: MenderConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

func _b(id: String) -> bool:
	return bool(boons.get(id, false))
func _res_max() -> float:
	return cfg.reservoir_max + (200.0 if _b("reservoirplus") else 0.0)
func _conv() -> float:
	return cfg.tide_conv * (1.2 if _b("tideconv") else 1.0)
func _nerve_rate() -> float:
	return cfg.nerve_rate + (3.0 if _b("nerveplus") else 0.0)

# --- per-tick: mana regen, Nerve accrual, advance the cast bar ---
func upkeep(s: CombatState, seat: Seat) -> void:
	var rm := float(seat.vars.get("regen_mult", 1.0))
	seat.resource = minf(cfg.mana_max, seat.resource + cfg.mana_regen * rm * s.dt)

	if aspect == "brinkwarden":
		var blood := 0
		for u in s.seats:
			if u.role != "healer" and u.alive() and u.hp_frac() <= cfg.blood_thresh:
				blood += 1
		if blood > 0:
			var nv := float(seat.vars.get("nerve", 0.0)) + _nerve_rate() * float(blood) * s.dt
			seat.vars["nerve"] = minf(cfg.nerve_max, nv)

	if not seat.casting.is_empty():
		var c := seat.casting
		var tgt: Seat = c.get("target")
		if tgt != null and not tgt.alive():
			seat.casting = {}
			CombatCore._emit(s, {"t": "cast_cancelled", "id": c["id"]})
		elif s.tick - int(c["start_tick"]) >= int(c["dur_ticks"]):
			var id: String = c["id"]
			seat.casting = {}
			_resolve_spell(s, seat, id, tgt)

# --- M7: dodging cancels your cast bar. The beat gets answered but the heal is
#     lost (mana is only charged at resolve, so nothing to refund — the cost is
#     the TIME). The cast-vs-dodge call is the healer's discipline test. ---
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	if not seat.casting.is_empty():
		var id: String = seat.casting["id"]
		seat.casting = {}
		CombatCore._emit(s, {"t": "cast_cancelled", "id": id})

# --- M7: grade payoff — a PERFECT dodge refunds a sip of mana (the healer's
#     currency), so clean footwork feeds the triage instead of just avoiding chip. ---
func on_strike_result(_s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	if grade == StrikeRes.Grade.PERFECT:
		seat.resource = minf(cfg.mana_max, seat.resource + cfg.strike_perfect_mana)
		if _b("mdTrigBeat"):
			_md_trigger(_s, seat, null, "beat")   # Phase B: PERFECT beat = proc moment

# --- cast / instant dispatch ---
func on_action(s: CombatState, seat: Seat, id: StringName, target: Seat = null) -> bool:
	var key := String(id)
	var sp: Dictionary = cfg.spells.get(key, {})
	if sp.is_empty():
		return false
	var offgcd := bool(sp.get("offgcd", false))
	if not offgcd and s.tick < seat.gcd_until_tick:
		return false
	if s.tick < int(seat.cooldowns.get(key, 0)):
		return false
	if not offgcd and not seat.casting.is_empty():
		return false                                     # can't restart while a cast is in progress
	if bool(sp.get("target", false)):
		if target == null or not target.alive():
			return false
		if key == "dispel" and target.debuff.is_empty():
			return false
	if key == "surge" and float(seat.vars.get("reservoir", 0.0)) <= 1.0:
		return false
	if key == "laststand" and float(seat.vars.get("nerve", 0.0)) <= 1.0:
		return false
	if seat.resource < float(sp.get("mana", 0.0)):      # check full price (faithful)
		return false

	var cast := float(sp.get("cast", 0.0))
	if cast > 0.0:
		var ct := _tt(s, cast)
		if _b("mdPropSwift"):
			ct = maxi(1, int(ceil(float(ct) * cfg.mod_cast_mult)))   # Phase B: Swift Litany
		seat.casting = {"id": key, "target": target, "start_tick": s.tick,
			"dur_ticks": ct}
		if not offgcd:
			seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)   # GCD runs from cast START
		CombatCore._emit(s, {"t": "cast_started", "id": key, "dur": cast})
		return true
	_resolve_spell(s, seat, key, target)
	return true

func _resolve_spell(s: CombatState, seat: Seat, id: String, target: Seat) -> void:
	var sp: Dictionary = cfg.spells[id]
	# pay mana (Brinkwarden discounts single-target heals by the target's missing HP)
	var pay := float(sp.get("mana", 0.0))
	if aspect == "brinkwarden" and bool(sp.get("target", false)) and id != "dispel" and target != null:
		pay *= _brink_mana_mult(target)
	seat.resource = maxf(0.0, seat.resource - pay)

	match id:
		"flash", "mend":
			var clutch: bool = target.hp_frac() < cfg.mod_clutch_frac
			CombatCore.heal_unit(s, target, float(sp["heal"]), seat)
			if id == "flash" and _b("afterglow"):
				target.hots.append({"tick": 10.0, "every": _tt(s, 1.5), "acc": 0, "left": _tt(s, 3.0),
					"caster_i": s.seats.find(seat)})
			if clutch:
				_triage_proc(s, seat, target, "clutch")   # Phase B: the innate proc moment
		"renew":
			target.hots.append({"tick": float(sp["hot_tick"]),
				"every": _tt(s, float(sp["hot_every"])), "acc": 0, "left": _tt(s, float(sp["hot_dur"])),
				"caster_i": s.seats.find(seat)})
		"ward":
			target.absorb += float(sp["shield"]) * (1.4 if _b("wardplus") else 1.0)
			target.absorb_owner_i = s.seats.find(seat)
			target.ward_until_tick = s.tick + _tt(s, float(sp["ward_dur"]))
		"cascade":
			_heal_lowest(s, seat, 4 if _b("cascade4") else 3, float(sp["heal"]))
		"well":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					CombatCore.heal_unit(s, u, float(sp["heal"]), seat)
		"dispel":
			target.debuff = {}
			CombatCore._bump_diag(s, seat, "dispel")   # class-signature skill signal (token mint)
			if _b("mdTrigDispel"):
				_md_trigger(s, seat, target, "dispel")  # Phase B: a Dispel = proc moment
		"medit":
			seat.resource = minf(cfg.mana_max, seat.resource + float(sp["restore"]))
		"surge":
			_surge(s, seat)
		"laststand":
			_laststand(s, seat)

	# instant spells put you on the GCD now; cast-time spells already did at cast start
	if not bool(sp.get("offgcd", false)) and float(sp.get("cast", 0.0)) <= 0.0:
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	var cd := float(sp.get("cd", 0.0))
	if cd > 0.0:
		seat.cooldowns[id] = s.tick + _tt(s, cd)
	CombatCore._emit(s, {"t": "cast_finished", "id": id})

# --- aspect mechanics ---
func heal_mult(target: Seat) -> float:
	if aspect == "brinkwarden":
		return 1.0 + (1.0 - target.hp_frac()) * cfg.brink_heal_scale
	return 1.0

func on_overheal(_s: CombatState, caster: Seat, target: Seat, over: float) -> void:
	if over <= 0.0:
		return
	if aspect == "tidecaller":
		var r := float(caster.vars.get("reservoir", 0.0)) + over * _conv()
		caster.vars["reservoir"] = minf(_res_max(), r)
	if _b("overflow") and target != null:                  # Overflow: shield the target with the spill
		target.absorb = minf(target.absorb + roundf(over * 0.3), target.hp_max * 0.5)
		target.absorb_owner_i = _s.seats.find(caster)

## Opus boon: a Ward fully consumed detonates in light — heal + cleanse its bearer.
func on_absorb(s: CombatState, healer: Seat, target: Seat, _eaten: float, emptied: bool) -> void:
	if emptied and _b("sanctifiedward") and target != null and target.alive():
		CombatCore.heal_unit(s, target, 120.0, healer)
		target.debuff = {}
	if emptied and _b("mdTrigWard"):
		_md_trigger(s, healer, target, "ward")   # Phase B: a consumed Ward = proc moment

# ---------------------------------------------------------------- slot-verb Triage mods
# Phase B (build-your-Triage): the innate proc moment is a CLUTCH HEAL (a single-target
# heal resolving on an ally below mod_clutch_frac); TRIGGER pieces add moments, PAYLOAD
# pieces fire on every proc, PROPERTY pieces reshape the verb. NO LOCKOUTS. All
# _b()-gated — boonless sims stay byte-identical.

func _has_payloads() -> bool:
	return _b("mdPayShield") or _b("mdPayMana") or _b("mdPayHot") or _b("mdPropBenediction")

## A drafted trigger fired: built-in mana sip + one proc moment.
func _md_trigger(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	seat.resource = minf(cfg.mana_max, seat.resource + cfg.mod_trig_mana)
	_triage_proc(s, seat, target, source)

## One proc moment: fire every drafted payload once on the triaged ally (fallback:
## the lowest-HP ally when the moment had no target, e.g. a dodged beat).
func _triage_proc(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic
	var tgt := target if (target != null and target.alive()) else _lowest_ally(s)
	if _b("mdPayShield") and tgt != null:
		tgt.absorb += cfg.mod_shield
		tgt.absorb_owner_i = s.seats.find(seat)
	if _b("mdPayMana"):
		seat.resource = minf(cfg.mana_max, seat.resource + cfg.mod_mana)
	if _b("mdPayHot") and tgt != null:
		tgt.hots.append({"tick": cfg.mod_hot_tick, "every": _tt(s, 1.5), "acc": 0,
			"left": _tt(s, 3.0), "caster_i": s.seats.find(seat)})
	if _b("mdPropBenediction"):
		var n := int(seat.vars.get("bene_count", 0)) + 1
		seat.vars["bene_count"] = n
		if n % cfg.mod_bene_every == 0:      # Opus: every Nth proc bathes the party
			for u in s.seats:
				if u.role != "healer" and u.alive():
					CombatCore.heal_unit(s, u, cfg.mod_bene_heal, seat)
			CombatCore.emit_event(s, {"t": "benediction", "player": seat.is_player})
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player, "src": source})

func _lowest_ally(s: CombatState) -> Seat:
	var best: Seat = null
	for u in s.seats:
		if u.role != "healer" and u.alive():
			if best == null or u.hp_frac() < best.hp_frac():
				best = u
	return best

func _brink_mana_mult(target: Seat) -> float:
	return 1.0 - (1.0 - target.hp_frac()) * cfg.brink_mana_disc

func _heal_lowest(s: CombatState, seat: Seat, n: int, amt: float) -> void:
	var pool: Array = []
	for u in s.seats:
		if u.role != "healer" and u.alive():
			pool.append(u)
	pool.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
	for i in mini(n, pool.size()):
		CombatCore.heal_unit(s, pool[i], amt, seat)

func _surge(s: CombatState, seat: Seat) -> void:
	var res := float(seat.vars.get("reservoir", 0.0))
	var living: Array = []
	for u in s.seats:
		if u.role != "healer" and u.alive():
			living.append(u)
	if living.is_empty():
		return
	var per := roundf(res / float(living.size()))
	var until := s.tick + _tt(s, 8.0)
	for u in living:
		u.absorb = minf(u.absorb + per, u.hp_max)
		u.absorb_owner_i = s.seats.find(seat)
		u.ward_until_tick = maxi(u.ward_until_tick, until)
		if _b("floodgate"):
			CombatCore.heal_unit(s, u, roundf(per * 0.25), seat)
	seat.vars["reservoir"] = 0.0
	CombatCore._emit(s, {"t": "surge"})

func _laststand(s: CombatState, seat: Seat) -> void:
	var base := roundf(float(seat.vars.get("nerve", 0.0)) * cfg.ls_heal)
	for u in s.seats:
		if u.role != "healer" and u.alive():
			CombatCore.heal_unit(s, u, base, seat)
			if _b("secondwind"):
				u.debuff = {}
	s.raid_dr = {"amt": cfg.ls_dr, "until_tick": s.tick + _tt(s, cfg.ls_dur)}
	seat.vars["nerve"] = 0.0
	CombatCore._emit(s, {"t": "laststand"})

# --- observation: mana, spec resource, cast bar, and the party frames ---
func observe(s: CombatState, seat: Seat) -> Dictionary:
	var party: Array = []
	for u in s.seats:
		# In a RAID the healer is personally hittable (rand-target bolts, aoe doom
		# beats), so its own frame joins the triage list — the AI can finally
		# self-heal, matching the human raid HUD's self-castable own frame.
		# threat_enabled-guarded: solo mender behavior (and its tuned bands)
		# stays byte-identical.
		if u.role != "healer" or (s.threat_enabled and u == seat):
			party.append({"seat": u, "name": u.unit_name, "role": u.role,
				"frac": u.hp_frac(), "hp": u.hp, "max": u.hp_max, "absorb": u.absorb,
				"debuff": not u.debuff.is_empty(), "hots": u.hots.size(), "dead": not u.alive()})
	return {
		"tick": s.tick,
		"aspect": aspect,
		"mana": seat.resource,
		"mana_max": cfg.mana_max,
		"reservoir": float(seat.vars.get("reservoir", 0.0)),
		"reservoir_max": _res_max(),
		"nerve": float(seat.vars.get("nerve", 0.0)),
		"nerve_max": cfg.nerve_max,
		"casting": seat.casting,
		"party": party,
	}
