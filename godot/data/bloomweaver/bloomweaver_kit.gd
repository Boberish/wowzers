## BloomweaverKit — Healer #2 on the player seat. The ANTICIPATION healer: no mana,
## no direct heals. Sap (fast energy) casts Growth HoTs and Barkskin wards; Verdance
## builds ONLY from effective proactive healing (HoT ticks into real damage, wards
## that actually absorb) and is spent on the aspect signature.
##
## Timing skill:
##  - BLOOM (double-tap): recasting Growth on a Growth'd ally cashes its remaining
##    ticks instantly (× bloom_eff, slightly lossy) — the emergency button is the
##    garden you already planted.
##  - PERFECT WARD: a Barkskin fully consumed by damage refunds Sap + bonus Verdance
##    (Thornveil also spikes the boss); a ward that expires unconsumed WILTS (waste).
class_name BloomweaverKit
extends ClassKit

var aspect: String = "wildgrove"
var cfg: BloomweaverConfig
var boons: Dictionary = {}
var flourish: bool = false      ## Wildgrove garden bonus, recomputed each tick in upkeep

func _init(_aspect: String, _cfg: BloomweaverConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

# --- boon-aware numbers ---
func _growth_dur() -> float:
	return cfg.growth_dur + (3.0 if _b("deeproots") else 0.0)
func _bloom_eff() -> float:
	return 1.05 if _b("quickbloom") else cfg.bloom_eff
func _bark_shield() -> float:
	return cfg.bark_shield * (1.4 if _b("thickbark") else 1.0)
func _thorns() -> float:
	return 0.70 if _b("barbs") else cfg.thorns_frac
func _perfect_sap() -> float:
	return cfg.perfect_sap + (10.0 if _b("perfectharvest") else 0.0)
func _perfect_verd() -> float:
	return cfg.perfect_verd + (8.0 if _b("perfectharvest") else 0.0)
func _flourish_need() -> int:
	return 2 if _b("evergreen") else cfg.flourish_need
func _verd_heal_rate() -> float:
	return cfg.verd_per_heal * (1.5 if _b("photosynth") else 1.0)

# ---------------------------------------------------------------- per-tick
func upkeep(s: CombatState, seat: Seat) -> void:
	var rm := 1.25 if _b("sapflow") else 1.0
	seat.resource = minf(cfg.sap_max, seat.resource + cfg.sap_regen * rm * s.dt)

	# Flourish: the garden bonus is live while enough allies carry a Growth
	if aspect == "wildgrove":
		var n := 0
		for u in s.seats:
			if u.role != "healer" and u.alive() and _find_growth(u) >= 0:
				n += 1
		flourish = n >= _flourish_need()

	# WILT: a ward about to expire (this tick, in _apply_seat_effects) with absorb
	# left = wasted Sap. View feedback + a sim diagnostic; no gameplay effect.
	for u in s.seats:
		if u.role != "healer" and u.alive() and u.absorb > 0.0 \
				and u.ward_until_tick >= 0 and s.tick >= u.ward_until_tick:
			seat.vars["stat_wilted"] = float(seat.vars.get("stat_wilted", 0.0)) + u.absorb
			CombatCore.emit_event(s, {"t": "wilt", "seat": u, "amt": int(u.absorb)})

	# advance the cast bar (Overgrowth)
	if not seat.casting.is_empty():
		var c := seat.casting
		if s.tick - int(c["start_tick"]) >= int(c["dur_ticks"]):
			var id: String = c["id"]
			seat.casting = {}
			_resolve_spell(s, seat, id, c.get("target"))

# ---------------------------------------------------------------- M7 dodge
## Dodging cancels an in-flight Overgrowth (Sap is spent at resolve, so the cost
## is the TIME) — the anticipation healer's cast-vs-dodge call.
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	if not seat.casting.is_empty():
		var id: String = seat.casting["id"]
		seat.casting = {}
		CombatCore._emit(s, {"t": "cast_cancelled", "id": id})

## Grade payoff: a PERFECT dodge refunds Sap (the triage currency). Verdance is
## deliberately NOT granted — that gauge stays earned by effective healing only.
func on_strike_result(_s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	if grade == StrikeRes.Grade.PERFECT:
		seat.resource = minf(cfg.sap_max, seat.resource + cfg.strike_perfect_sap)
		if _b("bwTrigBeat"):
			_bw_trigger(_s, seat, null, "beat")   # Phase B: PERFECT beat = proc moment

# ---------------------------------------------------------------- dispatch
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
		return false
	if bool(sp.get("target", false)):
		if target == null or not target.alive():
			return false
		if key == "saprot" and target.debuff.is_empty():
			return false
	if sp.has("spec") and float(seat.vars.get("verdance", 0.0)) < cfg.verd_min_spend:
		return false
	if key == "lifesurge" and _garden_count(s) == 0:
		return false                                    # nothing planted = nothing to surge
	if seat.resource < float(sp.get("sap", 0.0)):
		return false

	var cast := float(sp.get("cast", 0.0))
	if cast > 0.0:
		seat.casting = {"id": key, "target": target, "start_tick": s.tick,
			"dur_ticks": _tt(s, cast)}
		if not offgcd:
			seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)   # GCD runs from cast START
		CombatCore.emit_event(s, {"t": "cast_started", "id": key, "dur": cast})
		return true
	_resolve_spell(s, seat, key, target)
	return true

func _resolve_spell(s: CombatState, seat: Seat, id: String, target) -> void:
	var sp: Dictionary = cfg.spells[id]
	seat.resource = maxf(0.0, seat.resource - float(sp.get("sap", 0.0)))

	match id:
		"growth":
			if _find_growth(target) >= 0:
				_bloom(s, seat, target)                 # double-tap = cash out
			else:
				_plant(s, seat, target)
		"bark":
			target.absorb += _bark_shield()
			target.absorb_owner_i = s.seats.find(seat)
			target.ward_until_tick = maxi(target.ward_until_tick, s.tick + _tt(s, cfg.bark_dur))
			CombatCore.emit_event(s, {"t": "warded", "seat": target})
		"overgrowth":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					if _find_growth(u) >= 0:
						_refresh_growth(s, u)
					else:
						_plant(s, seat, u)
		"lash":
			CombatCore.damage_boss(s, seat, float(sp["dmg"]))
		"saprot":
			target.debuff = {}
			if _find_growth(target) >= 0:
				_refresh_growth(s, target)
			else:
				_plant(s, seat, target)                 # rot becomes flowers
			CombatCore.emit_event(s, {"t": "saprot", "seat": target})
		"lifesurge":
			_lifesurge(s, seat)
		"wildbloom":
			_wildbloom(s, seat)
		"briarheart":
			_briarheart(s, seat)

	# instant spells put you on the GCD now; cast-time spells already did at cast start
	if not bool(sp.get("offgcd", false)) and float(sp.get("cast", 0.0)) <= 0.0:
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	var cd := float(sp.get("cd", 0.0))
	if id == "overgrowth" and _b("greenfuse"):
		cd -= 4.0
	elif id == "bark" and _b("ringbark"):
		cd -= 3.0
	if cd > 0.0:
		seat.cooldowns[id] = s.tick + _tt(s, cd)
	CombatCore.emit_event(s, {"t": "cast_finished", "id": id})

# ---------------------------------------------------------------- garden
func _find_growth(u: Seat) -> int:
	for i in u.hots.size():
		if String(u.hots[i].get("gid", "")) == "growth":
			return i
	return -1

func _garden_count(s: CombatState) -> int:
	var n := 0
	for u in s.seats:
		if u.role != "healer" and u.alive() and _find_growth(u) >= 0:
			n += 1
	return n

func _plant(s: CombatState, seat: Seat, u: Seat) -> void:
	var ev := _tt(s, cfg.growth_every)
	if _b("bwPropQuick"):
		ev = maxi(1, int(ceil(float(ev) * cfg.mod_tick_mult)))   # Phase B: Quickening
	u.hots.append({"gid": "growth", "tick": cfg.growth_tick,
		"every": ev, "acc": 0, "left": _tt(s, _growth_dur()),
		"caster_i": s.seats.find(seat)})
	seat.vars["stat_planted"] = int(seat.vars.get("stat_planted", 0)) + 1
	if _b("bwTrigPlant"):
		var n := int(seat.vars.get("plant_count", 0)) + 1
		seat.vars["plant_count"] = n
		if n % 3 == 0:
			_bw_trigger(s, seat, u, "plant")   # Phase B: every 3rd Growth = proc moment

func _refresh_growth(s: CombatState, u: Seat) -> void:
	var i := _find_growth(u)
	if i >= 0:
		u.hots[i]["left"] = _tt(s, _growth_dur())
		u.hots[i]["acc"] = 0

## Remaining bloomable heal in a growth hot: fires-left × tick amount.
func _remaining(h: Dictionary) -> float:
	var every := maxi(1, int(h["every"]))
	var fires := int(ceil(float(h["left"]) / float(every)))
	return float(fires) * float(h["tick"])

func _bloom(s: CombatState, seat: Seat, u: Seat, mult: float = -1.0) -> void:
	var i := _find_growth(u)
	if i < 0:
		return
	var m := _bloom_eff() if mult < 0.0 else mult
	var amt := roundf(_remaining(u.hots[i]) * m)
	u.hots.remove_at(i)
	var eff := CombatCore.heal_unit(s, u, amt, seat)
	seat.vars["stat_blooms"] = int(seat.vars.get("stat_blooms", 0)) + 1
	_garden_proc(s, seat, u, "bloom")   # Phase B: the innate proc moment
	CombatCore.emit_event(s, {"t": "bloom", "seat": u, "amt": int(eff)})

func _lifesurge(s: CombatState, seat: Seat) -> void:
	for u in s.seats:
		if u.role != "healer" and u.alive() and _find_growth(u) >= 0:
			_bloom(s, seat, u, cfg.lifesurge_eff)
	CombatCore.emit_event(s, {"t": "lifesurge"})

# ---------------------------------------------------------------- signatures
func _wildbloom(s: CombatState, seat: Seat) -> void:
	var verd := float(seat.vars.get("verdance", 0.0))
	var per := roundf(verd * cfg.wildbloom_heal)
	var n := 0
	for u in s.seats:
		if u.role == "healer" or not u.alive():
			continue
		if _find_growth(u) >= 0:
			CombatCore.heal_unit(s, u, per, seat)
			_refresh_growth(s, u)                       # the garden restarts
			n += 1
		elif _b("verdantsurge"):
			_plant(s, seat, u)
	seat.vars["verdance"] = 0.0
	CombatCore.emit_event(s, {"t": "wildbloom", "n": n})

func _briarheart(s: CombatState, seat: Seat) -> void:
	var verd := float(seat.vars.get("verdance", 0.0))
	var per := roundf(verd * cfg.briar_conv)
	var until := s.tick + _tt(s, cfg.briar_dur)
	for u in s.seats:
		if u.role != "healer" and u.alive():
			u.absorb = minf(u.absorb + per, u.hp_max)
			u.absorb_owner_i = s.seats.find(seat)
			u.ward_until_tick = maxi(u.ward_until_tick, until)
	seat.vars["verdance"] = 0.0
	CombatCore.emit_event(s, {"t": "briarheart"})

# ---------------------------------------------------------------- aspect hooks
## Flourish (Wildgrove): a full garden empowers ALL your healing (ticks + blooms).
func heal_mult(_target: Seat) -> float:
	if aspect == "wildgrove" and flourish:
		return 1.0 + cfg.flourish_bonus
	return 1.0

## Verdance builds from EFFECTIVE healing only — overheal earns nothing.
func on_heal(_s: CombatState, caster: Seat, _target: Seat, eff: float, _over: float) -> void:
	if eff <= 0.0:
		return
	var v := float(caster.vars.get("verdance", 0.0)) + eff * _verd_heal_rate()
	caster.vars["verdance"] = minf(cfg.verdance_max, v)

## A ward ate damage: Verdance for the absorb; Thornveil reflects; a FULL consume
## is a Perfect Ward — Sap refund + bonus Verdance (+ a Thornveil spike).
func on_absorb(s: CombatState, healer: Seat, target: Seat, eaten: float, emptied: bool) -> void:
	var v := float(healer.vars.get("verdance", 0.0)) + eaten * cfg.verd_per_absorb
	healer.vars["verdance"] = minf(cfg.verdance_max, v)
	if aspect == "thornveil":
		var reflect := roundf(eaten * _thorns())
		if reflect > 0.0:
			CombatCore.damage_boss(s, healer, reflect)
			healer.vars["stat_thorns"] = float(healer.vars.get("stat_thorns", 0.0)) + reflect
	if emptied:
		healer.resource = minf(cfg.sap_max, healer.resource + _perfect_sap())
		healer.vars["verdance"] = minf(cfg.verdance_max,
			float(healer.vars["verdance"]) + _perfect_verd())
		if aspect == "thornveil":
			CombatCore.damage_boss(s, healer, cfg.perfect_burst)
			healer.vars["stat_thorns"] = float(healer.vars.get("stat_thorns", 0.0)) + cfg.perfect_burst
		healer.vars["stat_perfect"] = int(healer.vars.get("stat_perfect", 0)) + 1
		CombatCore._bump_diag(s, healer, "perfect_ward")   # class-signature skill signal (token mint)
		if _b("evergreencycle") and target != null and target.role != "healer" and target.alive():
			if _find_growth(target) >= 0:                  # Opus: the ward seeds itself
				_refresh_growth(s, target)
			else:
				_plant(s, healer, target)
		if _b("bwTrigPerfect"):
			_bw_trigger(s, healer, target, "perfect")      # Phase B: Perfect Ward = proc moment
		CombatCore.emit_event(s, {"t": "perfect_ward", "seat": target})

# ---------------------------------------------------------------- slot-verb Garden mods
# Phase B (build-your-Garden): the innate proc moment is every cashed BLOOM (Lifesurge
# mass-blooms count individually); TRIGGER pieces add moments, PAYLOAD pieces fire on
# every proc, PROPERTY pieces reshape the verb. Deep Garden (opus) doubles the payloads
# while the garden is full. NO LOCKOUTS. All _b()-gated — boonless sims byte-identical.

func _has_payloads() -> bool:
	return _b("bwPayThorn") or _b("bwPaySap") or _b("bwPayMend")

## A drafted trigger fired: built-in Sap sip + one proc moment.
func _bw_trigger(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	seat.resource = minf(cfg.sap_max, seat.resource + cfg.mod_trig_sap)
	_garden_proc(s, seat, target, source)

## One proc moment: fire every drafted payload once (twice under a full Deep Garden).
func _garden_proc(s: CombatState, seat: Seat, target: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic
	var times := 2 if (_b("bwPropDeepGarden") and _garden_count(s) >= cfg.mod_garden_need) else 1
	for _i in times:
		if _b("bwPayThorn"):
			CombatCore.damage_boss(s, seat, cfg.mod_thorn)
		if _b("bwPaySap"):
			seat.resource = minf(cfg.sap_max, seat.resource + cfg.mod_sap)
		if _b("bwPayMend"):
			var tgt := target if (target != null and target.alive() and target.role != "healer") \
				else _lowest_ally(s)
			if tgt != null:
				CombatCore.heal_unit(s, tgt, cfg.mod_mend, seat)
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player, "src": source})

func _lowest_ally(s: CombatState) -> Seat:
	var best: Seat = null
	for u in s.seats:
		if u.role != "healer" and u.alive():
			if best == null or u.hp_frac() < best.hp_frac():
				best = u
	return best

# ---------------------------------------------------------------- observation
func observe(s: CombatState, seat: Seat) -> Dictionary:
	var party: Array = []
	for u in s.seats:
		if u.role == "healer":
			continue
		var gi := _find_growth(u)
		party.append({"seat": u, "name": u.unit_name, "role": u.role,
			"frac": u.hp_frac(), "hp": u.hp, "max": u.hp_max, "absorb": u.absorb,
			"debuff": not u.debuff.is_empty(), "hots": u.hots.size(),
			"growth": gi >= 0,
			"growth_heal": (_remaining(u.hots[gi]) * _bloom_eff()) if gi >= 0 else 0.0,
			"dead": not u.alive()})
	var tg_victim: Seat = null
	var tg_all := false
	if s.telegraph != null:
		match s.telegraph.ability.effect:
			AbilityRes.Effect.DMG_TARGET, AbilityRes.Effect.MARK_NUKE:
				tg_victim = s.telegraph.target
			AbilityRes.Effect.DMG_ALL, AbilityRes.Effect.NOVA:
				tg_all = true
	return {
		"tick": s.tick,
		"aspect": aspect,
		"sap": seat.resource,
		"sap_max": cfg.sap_max,
		"verdance": float(seat.vars.get("verdance", 0.0)),
		"verdance_max": cfg.verdance_max,
		"flourish": flourish,
		"garden": _garden_count(s),
		"casting": seat.casting,
		"tg_victim": tg_victim,
		"tg_all": tg_all,
		"party": party,
	}
