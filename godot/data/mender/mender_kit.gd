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
	# GEAR-1: LE CHAT's Bell — +30 starting mana, exactly once (gear-gated no-op).
	var bell := GearFx.bell_grant(seat)
	if bell > 0.0:
		seat.resource = minf(cfg.mana_max, seat.resource + bell)
	var rm := float(seat.vars.get("regen_mult", 1.0))
	seat.resource = minf(cfg.mana_max, seat.resource + cfg.mana_regen * rm * s.dt)
	# GEAR-2: Scratchpad — regen trebles while a long wind-up thinks.
	if GearFx.scratchpad_live(s, seat):
		seat.resource = minf(cfg.mana_max, seat.resource + cfg.mana_regen * rm * s.dt * 2.0)
		if GearFx.flag_once(seat, &"scratchpad_pop"):
			GearFx.pop(s, seat, &"scratchpad")

	# LITANY decays a pip after litany_decay seconds without an in-condition beat — the
	# chain is a live thing you must keep feeding, not a bank.
	if _litany(seat) > 0:
		var idle := int(seat.vars.get("litany_idle", 0)) + 1
		if idle >= _tt(s, cfg.litany_decay):
			idle = 0
			if GearFx.once(seat, &"grace_period"):
				GearFx.pop(s, seat, &"grace_period")   # GEAR-2: one pip stays lit
			else:
				seat.vars["litany"] = _litany(seat) - 1
		seat.vars["litany_idle"] = idle

	if aspect == "brinkwarden":
		var blood := 0
		for u in s.seats:
			if u.role != "healer" and u.alive() and u.hp_frac() <= cfg.blood_thresh:
				blood += 1
		if blood > 0:
			# Blood Pact (re-cut): bloodied allies feed the healer MORE Nerve — rewarding the
			# ride-the-edge gamble through YOUR resource, not standing alone as a DPS stat.
			var rate := _nerve_rate() * (1.5 if _b("bloodpact") else 1.0)
			var nv := float(seat.vars.get("nerve", 0.0)) + rate * float(blood) * s.dt
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

# --- GEAR-1: gear proc seams. The healer is hittable (aoe beats), so it carries
#     the death procs too; a denied boss heal pays the Riftmaw Tooth in mana. ---
func on_damage_taken(s: CombatState, seat: Seat, _dmg: float, _source: StringName, _size: int) -> void:
	GearFx.damage_taken(s, seat)   # Swan Song — gear-gated no-op

func on_boss_heal_denied(s: CombatState, seat: Seat) -> void:
	var g := GearFx.tooth_grant(s, seat)
	if g > 0.0:
		seat.resource = minf(cfg.mana_max, seat.resource + g)

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
			var pre := target.hp_frac()
			CombatCore.heal_unit(s, target, float(sp["heal"]), seat, StringName(id))
			if id == "flash" and _b("afterglow"):
				target.hots.append({"tick": 10.0, "every": _tt(s, 1.5), "acc": 0, "left": _tt(s, 3.0),
					"caster_i": s.seats.find(seat), "src": &"afterglow"})
			# LITANY: the aspect condition decides if this heal is a combo BEAT — Tidecaller
			# banks a pip by topping AHEAD (leaves them ≥ foresight), Brinkwarden by catching
			# BEHIND (the target WAS at/below bloodied). Mirror-image play, one meter.
			var beat := (target.hp_frac() >= cfg.foresight_line) if aspect == "tidecaller" \
				else (pre <= cfg.blood_thresh)
			if beat:
				_litany_beat(s, seat, target, "heal")
		"renew":
			target.hots.append({"tick": float(sp["hot_tick"]),
				"every": _tt(s, float(sp["hot_every"])), "acc": 0, "left": _tt(s, float(sp["hot_dur"])),
				"caster_i": s.seats.find(seat), "src": &"renew"})
		"ward":
			target.absorb += float(sp["shield"]) * (1.4 if _b("wardplus") else 1.0)
			target.absorb_owner_i = s.seats.find(seat)
			target.ward_until_tick = s.tick + _tt(s, float(sp["ward_dur"]))
		"cascade":
			_heal_lowest(s, seat, 4 if _b("cascade4") else 3, float(sp["heal"]))
		"well":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					CombatCore.heal_unit(s, u, float(sp["heal"]), seat, &"well")
		"dispel":
			target.debuff = {}
			CombatCore._bump_diag(s, seat, "dispel")   # class-signature skill signal (token mint)
			if _b("mdTrigDispel"):
				_md_trigger(s, seat, target, "dispel")  # Phase B: a Dispel = proc moment
			if GearFx.has(seat, &"salt_vial"):          # GEAR-1: the cleanse also soothes
				CombatCore.heal_unit(s, target, 25.0, seat, &"salt_vial")
				GearFx.pop(s, seat, &"salt_vial")
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
		# GEAR-2: Overflow Sluice — spill past a FULL Reservoir wards the tank at 0.5x.
		if GearFx.has(caster, &"overflow_sluice") and r > _res_max():
			var tk := CombatCore._tank_target(_s)
			if tk != null and tk.alive():
				tk.absorb += roundf((r - _res_max()) * 0.5)
				tk.absorb_owner_i = _s.seats.find(caster)
				tk.ward_until_tick = maxi(tk.ward_until_tick,
					_s.tick + CombatCore.to_ticks(8.0, _s.config.fixed_hz))
				if GearFx.flag_once(caster, &"sluice_pop"):
					GearFx.pop(_s, caster, &"overflow_sluice")
	if _b("overflow") and target != null:                  # Overflow: shield the target with the spill
		# Top up toward Overflow's cap (hp_max*0.5) but ONLY GROW — never let the minf
		# collapse an already-larger ward (Surge caps at hp_max, Ward is uncapped) down
		# to the cap, and only claim ownership when Overflow actually added shield.
		var grown := minf(target.absorb + roundf(over * 0.3), target.hp_max * 0.5)
		if grown > target.absorb:
			target.absorb = grown
			target.absorb_owner_i = _s.seats.find(caster)

## Tidecaller FLYWHEEL: damage a shield absorbs re-banks a share into the Reservoir
## (capped by reservoir_max — Surge re-arms out of the very hits it eats). Plus the Opus
## Ward-consumed detonation (heal + cleanse its bearer).
func on_absorb(s: CombatState, healer: Seat, target: Seat, eaten: float, emptied: bool) -> void:
	if aspect == "tidecaller" and eaten > 0.0:
		var r := float(healer.vars.get("reservoir", 0.0)) + eaten * cfg.surge_rebank_frac
		healer.vars["reservoir"] = minf(_res_max(), r)
	if emptied and _b("sanctifiedward") and target != null and target.alive():
		CombatCore.heal_unit(s, target, 120.0, healer, &"sanctified_ward")
		target.debuff = {}
	if emptied and _b("mdTrigWard"):
		_md_trigger(s, healer, target, "ward")   # Phase B: a consumed Ward = proc moment

# ---------------------------------------------------------------- LITANY + slot-verb Triage
# The combo backbone: an IN-CONDITION heal (see _resolve_spell) or a drafted TRIGGER fires
# a LITANY BEAT — it lights a pip, fires the drafted PAYLOAD pieces SCALED by the current
# pip count, and the 5th pip cashes a party Benediction bloom then resets. The aspect
# INVERTS the fill condition (Tidecaller top-ahead vs Brinkwarden catch-behind). All
# payloads stay _b()-gated; boonless Mender now runs the pip meter + Benediction as its
# core loop (no payloads) → retuned, NOT byte-identical (this is the rework).

func _litany(seat: Seat) -> int:
	return int(seat.vars.get("litany", 0))

func _has_payloads() -> bool:
	return _b("mdPayShield") or _b("mdPayMana") or _b("mdPayHot")

## A LITANY BEAT: +1 pip; payloads fire scaled by the pip count; the 5th pip cashes
## Benediction then resets. `target` may be null (a dodged beat) → payloads/flash fall
## back to the lowest ally.
func _litany_beat(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	seat.vars["litany_idle"] = 0
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic (= the meter)
	var lit := _litany(seat) + 1
	if lit >= cfg.litany_max:
		_triage_payloads(s, seat, target, cfg.litany_max)   # payloads at full tier
		_benediction(s, seat)                                # the 5th-pip party cash
		seat.vars["litany"] = 0
	else:
		seat.vars["litany"] = lit
		_triage_payloads(s, seat, target, lit)
	CombatCore.emit_event(s, {"t": "litany", "seat": target, "player": seat.is_player,
		"aspect": aspect, "pips": int(seat.vars["litany"]), "src": source})

## The 5th-pip cash: bathe the party in light. mdPropBenediction (opus) makes it heal 50%
## more AND cleanse a debuff per ally.
func _benediction(s: CombatState, seat: Seat) -> void:
	var heal := cfg.bene_heal * (1.5 if _b("mdPropBenediction") else 1.0)
	for u in s.seats:
		if u.role != "healer" and u.alive():
			CombatCore.heal_unit(s, u, heal, seat, &"benediction")
			if _b("mdPropBenediction"):
				u.debuff = {}
	CombatCore.emit_event(s, {"t": "benediction", "player": seat.is_player})

## A drafted TRIGGER fired (Dispel / consumed Ward / PERFECT beat): mana sip + a Litany beat.
func _md_trigger(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	seat.resource = minf(cfg.mana_max, seat.resource + cfg.mod_trig_mana)
	_litany_beat(s, seat, target, source)

## Fire every drafted PAYLOAD once, magnitudes scaled by the Litany tier.
func _triage_payloads(s: CombatState, seat: Seat, target: Seat, tier: int) -> void:
	if not _has_payloads():
		return
	var scale := 1.0 + cfg.litany_per_pip * float(tier)
	var tgt := target if (target != null and target.alive()) else _lowest_ally(s)
	if _b("mdPayShield") and tgt != null:
		tgt.absorb += roundf(cfg.mod_shield * scale)
		tgt.absorb_owner_i = s.seats.find(seat)
	if _b("mdPayMana"):
		seat.resource = minf(cfg.mana_max, seat.resource + roundf(cfg.mod_mana * scale))
	if _b("mdPayHot") and tgt != null:
		tgt.hots.append({"tick": roundf(cfg.mod_hot_tick * scale), "every": _tt(s, 1.5), "acc": 0,
			"left": _tt(s, 3.0), "caster_i": s.seats.find(seat), "src": &"lingering_grace"})
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player})

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
		CombatCore.heal_unit(s, pool[i], amt, seat, &"cascade")

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
			CombatCore.heal_unit(s, u, roundf(per * 0.25), seat, &"floodgate")
	seat.vars["reservoir"] = 0.0
	CombatCore._emit(s, {"t": "surge"})

## Last Stand — the brinkmanship save that stops eating its own engine. Instead of an
## instant top (which yanks everyone OUT of bloodied, zeroing your Nerve income AND the
## ally-damage buff), it lays a Nerve-scaled ROLLING HoT + the party DR window and spends
## only ls_spend_frac of Nerve — so allies survive the spike but STAY on the edge, and the
## high-wire keeps climbing across the save.
func _laststand(s: CombatState, seat: Seat) -> void:
	var nerve := float(seat.vars.get("nerve", 0.0))
	var spent := nerve * cfg.ls_spend_frac
	var every := _tt(s, 1.5)
	var ticks := maxi(1, int(round(cfg.ls_dur / 1.5)))
	var per := roundf(spent * cfg.ls_heal / float(ticks))   # total heal spread over the window
	for u in s.seats:
		if u.role != "healer" and u.alive():
			u.hots.append({"tick": per, "every": every, "acc": 0, "left": _tt(s, cfg.ls_dur),
				"caster_i": s.seats.find(seat), "src": &"laststand"})
			if _b("secondwind"):
				u.debuff = {}
	s.raid_dr = {"amt": cfg.ls_dr, "until_tick": s.tick + _tt(s, cfg.ls_dur)}
	seat.vars["nerve"] = nerve - spent   # keep the rest — the gamble survives the save
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
		"litany": _litany(seat),
		"litany_max": cfg.litany_max,
		"foresight_line": cfg.foresight_line,
		"blood_thresh": cfg.blood_thresh,
		"casting": seat.casting,
		"party": party,
	}
