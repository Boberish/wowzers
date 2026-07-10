## BloomweaverKit — Healer #2 on the player seat. The ANTICIPATION healer: no mana,
## no direct heals. Sap (fast energy) casts SEEDS and Barkskin wards; Verdance builds
## ONLY from effective proactive healing (ramped seed ticks into real damage, wards that
## actually absorb) and is spent on the aspect signature (+ over-capping seeds).
##
## SEEDFALL — the stacking, ramping garden:
##  - GROWTH stacks a seed onto an ally's BED (soft cap 3 / grove 4). Every bed carries
##    ONE SHARED RAMP: a fresh/reset bed ticks at ramp_floor and climbs to full over
##    ramp_time; applying ANY new seed RESETS that ramp. Stack FAST, then let it COOK.
##  - Past the soft cap, a 4th/5th seed OVER-CAPS by spending Verdance (efficiency).
##  - BLOOM (its own rune) cashes a bed's remaining fires × the current ramped tick.
##    Growth on a bed already at the HARD cap aliases to Bloom (the double-tap gesture).
##  - PERFECT WARD (a Barkskin fully consumed) COOKS the bed to full ramp on top of the
##    Sap/Verdance refund; a ward that expires unconsumed WILTS (waste). Barkskin's
##    absorb is sized by the seeds cooking under it (plant, then ward).
class_name BloomweaverKit
extends ClassKit

var aspect: String = "wildgrove"
var cfg: BloomweaverConfig
var flourish: bool = false      ## Wildgrove garden bonus, recomputed each tick in upkeep
var flourish_hi: bool = false   ## …and the field is LUSH (upgraded bonus)

func accent() -> Color:
	return Color("5fd6a3")   # Palette.VERDANCE — the garden-healer's living jade

func _init(_aspect: String, _cfg: BloomweaverConfig) -> void:
	aspect = _aspect
	cfg = _cfg

# --- boon-aware numbers ---
func _seed_dur() -> float:
	return cfg.seed_dur + (3.0 if _b("deeproots") else 0.0)
func _bloom_eff() -> float:
	return 1.10 if _b("quickbloom") else cfg.bloom_eff
func _ramp_time() -> float:
	var t := cfg.ramp_time
	if _b("bwPropQuick"):
		t -= cfg.mod_ramp_quick        # Quickening: seeds cook faster
	return maxf(2.0, t)
func _ramp_floor() -> float:
	return cfg.ramp_grove_floor if aspect == "wildgrove" else cfg.ramp_floor
func _soft_cap() -> int:
	var c := cfg.grove_soft_cap if aspect == "wildgrove" else cfg.soft_cap
	if _b("bounty"):
		c += 1
	return mini(c, cfg.hard_cap)
func _bark_base() -> float:
	return cfg.bark_base * (1.4 if _b("thickbark") else 1.0)
func _shield_per_seed() -> float:
	var base := cfg.thorn_shield_per_seed if aspect == "thornveil" else cfg.shield_per_seed
	return base + (0.10 if _b("ironbark") else 0.0)
func _thorn_charge(seat: Seat) -> int:
	return int(seat.vars.get("thorn_charge", 0))
func _thorns(seat: Seat) -> float:
	# reflect RAMPS with the snap-streak: base at 0 charge → thorns_max at full (barbs lifts both)
	var base := 0.55 if _b("barbs") else cfg.thorns_frac
	var top := (cfg.thorns_max + 0.10) if _b("barbs") else cfg.thorns_max
	return lerpf(base, top, float(_thorn_charge(seat)) / float(cfg.thorn_charge_max))
func _perfect_sap() -> float:
	return cfg.perfect_sap + (10.0 if _b("perfectharvest") else 0.0)
func _perfect_verd() -> float:
	return cfg.perfect_verd + (8.0 if _b("perfectharvest") else 0.0)
func _flourish_lo() -> int:
	return 4 if _b("evergreen") else cfg.flourish_seeds_lo
func _verd_heal_rate() -> float:
	return cfg.verd_per_heal * (1.5 if _b("photosynth") else 1.0)

# ---------------------------------------------------------------- the shared ramp
## A bed's ramp fraction (0 = just planted/reset, 1 = cooked). cook forces full.
func _seed_frac(s: CombatState, bed: Dictionary) -> float:
	if bool(bed.get("cook", false)):
		return 1.0
	var rt := maxf(1.0, float(_tt(s, _ramp_time())))
	return clampf(float(s.tick - int(bed.get("ramp_start", s.tick))) / rt, 0.0, 1.0)

## The bed's per-tick heal, PER whole bed (seed_base × ramp × stacks). RAW — the caster
## heal_mult (Flourish) is applied later inside heal_unit. This is what upkeep writes
## into bed["tick"] every frame BEFORE the engine fires the HoT the same tick.
func _seed_tick(s: CombatState, bed: Dictionary) -> float:
	var frac := _seed_frac(s, bed)
	var ramp := _ramp_floor() + (1.0 - _ramp_floor()) * frac
	return cfg.seed_base * ramp * float(bed.get("stacks", 1))

## Rewind a bed's ramp on a fresh stack. ramp_reset_frac 0.0 = full reset to the floor;
## a higher value restarts the ramp partway (softer sawtooth). Sim knob.
func _reset_ramp(s: CombatState, bed: Dictionary) -> void:
	var rt := float(_tt(s, _ramp_time()))
	bed["ramp_start"] = s.tick - int(round(clampf(cfg.ramp_reset_frac, 0.0, 1.0) * rt))
	bed["cook"] = false

# ---------------------------------------------------------------- per-tick
func upkeep(s: CombatState, seat: Seat) -> void:
	var rm := 1.25 if _b("sapflow") else 1.0
	seat.resource = minf(cfg.sap_max, seat.resource + cfg.sap_regen * rm * s.dt)

	# THE RAMP: rewrite every living ally's bed per-tick heal from its maturity. Runs at
	# update() step 2 (upkeep), BEFORE _apply_seat_effects fires HoTs at step 2b — so the
	# engine fires this exact ramped value this tick. Pure tick-math → determinism holds.
	for u in s.seats:
		if u.alive():
			var bi := _find_growth(u)
			if bi >= 0:
				u.hots[bi]["tick"] = _seed_tick(s, u.hots[bi])

	# FLOURISH lights on TOTAL PARTY SEEDS (Σ stacks) — breadth × depth, no timing gate.
	if aspect == "wildgrove":
		var total := _total_seeds(s)
		flourish = total >= _flourish_lo()
		flourish_hi = flourish and total >= cfg.flourish_seeds_hi

	# WILT: a ward about to expire (this tick, in _apply_seat_effects) with absorb
	# left = wasted Sap. View feedback + a sim diagnostic; no gameplay effect.
	for u in s.seats:
		if u.role != "healer" and u.alive() and u.absorb > 0.0 \
				and u.ward_until_tick >= 0 and s.tick >= u.ward_until_tick:
			seat.vars["stat_wilted"] = float(seat.vars.get("stat_wilted", 0.0)) + u.absorb
			CombatCore.emit_event(s, {"t": "wilt", "seat": u, "amt": int(u.absorb)})
			# a wilted ward BREAKS the Thornveil snap-streak (the "miss")
			if aspect == "thornveil" and _thorn_charge(seat) > 0:
				seat.vars["thorn_charge"] = 0
				CombatCore.emit_event(s, {"t": "thorn_break", "player": seat.is_player})

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
	# ALIAS: Growth on a bed at the HARD cap has nowhere to stack → it BLOOMS (the
	# double-tap-to-cash gesture). Redirect before the gates so it pays Bloom's cost.
	if key == "growth" and target != null and target.alive():
		var abi := _find_growth(target)
		if abi >= 0 and int(target.hots[abi].get("stacks", 1)) >= cfg.hard_cap:
			key = "bloom"
			sp = cfg.spells["bloom"]
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
		if key == "bloom" and _find_growth(target) < 0:
			return false                                    # nothing planted = nothing to cash
	if sp.has("spec") and float(seat.vars.get("verdance", 0.0)) < cfg.verd_min_spend:
		return false
	if key == "lifesurge" and _garden_count(s) == 0:
		return false                                        # nothing planted = nothing to surge
	# OVER-CAP gate: stacking past the soft cap costs Verdance — refuse if you lack it
	# (so a Growth press never silently drains the gauge; you over-load deliberately).
	if key == "growth" and target != null:
		var gbi := _find_growth(target)
		if gbi >= 0 and int(target.hots[gbi].get("stacks", 1)) >= _soft_cap() \
				and float(seat.vars.get("verdance", 0.0)) < cfg.overcap_verd:
			return false
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
			var bi := _find_growth(target)
			if bi < 0:
				_plant(s, seat, target)
			elif int(target.hots[bi].get("stacks", 1)) < _soft_cap():
				_stack(s, seat, target, false)
			else:
				_stack(s, seat, target, true)               # over-cap: spends Verdance
		"bloom":
			_bloom(s, seat, target, -1.0, true)             # dedicated cash-out (Clean Harvest eligible)
		"bark":
			var sh := _bark_shield(target)
			target.absorb += sh
			target.absorb_owner_i = s.seats.find(seat)
			target.ward_until_tick = maxi(target.ward_until_tick, s.tick + _tt(s, cfg.bark_dur))
			CombatCore.emit_event(s, {"t": "warded", "seat": target})
		"overgrowth":
			for u in s.seats:
				if u.role != "healer" and u.alive():
					if _find_growth(u) >= 0:
						_refresh(s, u)                       # extend, do NOT reset the ramp
					else:
						_plant(s, seat, u)
		"lash":
			CombatCore.damage_boss(s, seat, float(sp["dmg"]), &"lash")
		"saprot":
			target.debuff = {}
			if _find_growth(target) >= 0:
				_refresh(s, target)
			else:
				_plant(s, seat, target)                     # rot becomes flowers
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

# ---------------------------------------------------------------- the garden
## The ally's SEED BED index (one dict, gid "growth"), or -1. Named _find_growth for
## HUD compatibility (the bloom-value ghost calls it).
func _find_growth(u: Seat) -> int:
	for i in u.hots.size():
		if String(u.hots[i].get("gid", "")) == "growth":
			return i
	return -1

## Living allies (non-healer) carrying a bed — drives Lifesurge/the gauge pip rail.
func _garden_count(s: CombatState) -> int:
	var n := 0
	for u in s.seats:
		if u.role != "healer" and u.alive() and _find_growth(u) >= 0:
			n += 1
	return n

## Total seeds across the living party (Σ stacks) — lights Flourish.
func _total_seeds(s: CombatState) -> int:
	var n := 0
	for u in s.seats:
		if u.role != "healer" and u.alive():
			var bi := _find_growth(u)
			if bi >= 0:
				n += int(u.hots[bi].get("stacks", 1))
	return n

func _new_bed(s: CombatState, seat: Seat) -> Dictionary:
	var bed := {"gid": "growth", "stacks": 1, "ramp_start": s.tick, "cook": false,
		"every": _tt(s, cfg.seed_every), "acc": 0,
		"left": _tt(s, _seed_dur()), "dur": _tt(s, _seed_dur()),
		"tick": 0.0, "caster_i": s.seats.find(seat), "src": &"growth"}
	bed["tick"] = _seed_tick(s, bed)
	return bed

func _plant(s: CombatState, seat: Seat, u: Seat) -> void:
	u.hots.append(_new_bed(s, seat))
	seat.vars["stat_planted"] = int(seat.vars.get("stat_planted", 0)) + 1
	_plant_tick(s, seat, u)

## Add a seed to an existing bed: +1 stack, RESET the shared ramp, refresh the lifetime.
func _stack(s: CombatState, seat: Seat, u: Seat, over: bool) -> void:
	var bi := _find_growth(u)
	if bi < 0:
		_plant(s, seat, u)
		return
	var bed: Dictionary = u.hots[bi]
	bed["stacks"] = mini(int(bed.get("stacks", 1)) + 1, cfg.hard_cap)
	_reset_ramp(s, bed)                                     # stacking DELAYS the payoff
	bed["left"] = _tt(s, _seed_dur())
	bed["dur"] = _tt(s, _seed_dur())
	bed["acc"] = 0
	bed["tick"] = _seed_tick(s, bed)
	if over:
		seat.vars["verdance"] = maxf(0.0, float(seat.vars.get("verdance", 0.0)) - cfg.overcap_verd)
		seat.vars["stat_overcaps"] = int(seat.vars.get("stat_overcaps", 0)) + 1
	seat.vars["stat_planted"] = int(seat.vars.get("stat_planted", 0)) + 1
	_plant_tick(s, seat, u)

## Blanket refresh (Overgrowth / Sap Rot): extend the lifetime WITHOUT resetting the
## ramp or adding a stack — so topping a cooked field doesn't knock it down.
func _refresh(s: CombatState, u: Seat) -> void:
	var i := _find_growth(u)
	if i >= 0:
		u.hots[i]["left"] = _tt(s, _seed_dur())
		u.hots[i]["dur"] = _tt(s, _seed_dur())

func _plant_tick(s: CombatState, seat: Seat, u: Seat) -> void:
	if _b("bwTrigPlant"):
		var n := int(seat.vars.get("plant_count", 0)) + 1
		seat.vars["plant_count"] = n
		if n % 3 == 0:
			_bw_trigger(s, seat, u, "plant")                # Phase B: every 3rd seed = proc moment

func _bark_shield(target: Seat) -> float:
	var st := 0
	var bi := _find_growth(target)
	if bi >= 0:
		st = int(target.hots[bi].get("stacks", 1))
	var bonus := minf(_shield_per_seed() * float(st), cfg.seed_shield_cap)
	return roundf(_bark_base() * (1.0 + bonus))

## Remaining bloomable heal in a bed: fires-left × the current ramped per-tick (cached
## in bed["tick"] by upkeep). One-arg (HUD bloom-ghost calls it).
func _remaining(h: Dictionary) -> float:
	var every := maxi(1, int(h["every"]))
	var fires := int(ceil(float(h["left"]) / float(every)))
	return float(fires) * float(h.get("tick", 0.0))

func _bloom(s: CombatState, seat: Seat, u: Seat, mult: float = -1.0, clean: bool = false) -> void:
	var i := _find_growth(u)
	if i < 0:
		return
	var bed: Dictionary = u.hots[i]
	var m := _bloom_eff() if mult < 0.0 else mult
	# Clean Harvest boon: spend Verdance to cash losslessly (+) instead of the lossy ×0.9.
	if clean and mult < 0.0 and _b("cleanharvest") \
			and float(seat.vars.get("verdance", 0.0)) >= cfg.clean_harvest_verd:
		seat.vars["verdance"] = float(seat.vars["verdance"]) - cfg.clean_harvest_verd
		m = cfg.clean_harvest_mult
	var stacks := int(bed.get("stacks", 1))
	# sim diagnostics: how COOKED was the bed when cashed (skill signal), and how deep
	seat.vars["stat_bloom_cook_sum"] = float(seat.vars.get("stat_bloom_cook_sum", 0.0)) + _seed_frac(s, bed)
	seat.vars["stat_bloom_stack_sum"] = int(seat.vars.get("stat_bloom_stack_sum", 0)) + stacks
	var amt := roundf(_remaining(bed) * m)
	u.hots.remove_at(i)
	var eff := CombatCore.heal_unit(s, u, amt, seat, &"bloom")
	seat.vars["stat_blooms"] = int(seat.vars.get("stat_blooms", 0)) + 1
	# Thornbomb (Thornveil boon): a cashed bloom rakes the boss for its seed count.
	if aspect == "thornveil" and _b("thornbomb"):
		var rake := roundf(float(stacks) * cfg.thornbomb_per_seed)
		CombatCore.damage_boss(s, seat, rake, &"thornbomb")
		seat.vars["stat_thorns"] = float(seat.vars.get("stat_thorns", 0.0)) + rake
	_garden_proc(s, seat, u, "bloom")   # Phase B: the innate proc moment
	CombatCore.emit_event(s, {"t": "bloom", "seat": u, "amt": int(eff), "stacks": stacks})

func _lifesurge(s: CombatState, seat: Seat) -> void:
	for u in s.seats:
		if u.role != "healer" and u.alive() and _find_growth(u) >= 0:
			_bloom(s, seat, u, cfg.lifesurge_eff)
	CombatCore.emit_event(s, {"t": "lifesurge"})

# ---------------------------------------------------------------- signatures
func _wildbloom(s: CombatState, seat: Seat) -> void:
	var verd := float(seat.vars.get("verdance", 0.0))
	var soft := float(maxi(1, _soft_cap()))
	var n := 0
	for u in s.seats:
		if u.role == "healer" or not u.alive():
			continue
		var bi := _find_growth(u)
		if bi >= 0:
			var st := int(u.hots[bi].get("stacks", 1))
			var per := roundf(verd * cfg.wildbloom_heal * (0.5 + 0.5 * float(st) / soft))  # depth pays
			CombatCore.heal_unit(s, u, per, seat, &"wildbloom")
			u.hots[bi]["cook"] = true                       # snap the WHOLE garden to peak
			u.hots[bi]["tick"] = _seed_tick(s, u.hots[bi])
			_refresh(s, u)                                  # …and restart the lifetime
			n += 1
		elif _b("verdantsurge"):
			_plant(s, seat, u)
	seat.vars["verdance"] = 0.0
	# BRIDGE: cashing Verdance refuels the pre-planting — Sap back per ally healed (breadth).
	seat.resource = minf(cfg.sap_max, seat.resource + float(n) * cfg.wildbloom_sap)
	CombatCore.emit_event(s, {"t": "wildbloom", "n": n})

func _briarheart(s: CombatState, seat: Seat) -> void:
	var verd := float(seat.vars.get("verdance", 0.0))
	var charge := float(_thorn_charge(seat))
	var until := s.tick + _tt(s, cfg.briar_dur)
	var n := 0
	for u in s.seats:
		if u.role != "healer" and u.alive():
			var st := 0
			var bi := _find_growth(u)
			if bi >= 0:
				st = int(u.hots[bi].get("stacks", 1))
			# UNLEASH the streak + the seeds grown under the ward: deep beds bite harder.
			var per := roundf(verd * cfg.briar_conv * (1.0 + 0.1 * charge) + float(st) * 15.0)
			u.absorb = minf(u.absorb + per, u.hp_max)
			u.absorb_owner_i = s.seats.find(seat)
			u.ward_until_tick = maxi(u.ward_until_tick, until)
			n += 1
	seat.vars["verdance"] = 0.0
	# BRIDGE: Sap back per thorn ward placed (throughput).
	seat.resource = minf(cfg.sap_max, seat.resource + float(n) * cfg.briar_sap)
	CombatCore.emit_event(s, {"t": "briarheart"})

# ---------------------------------------------------------------- aspect hooks
## Flourish (Wildgrove): a full garden empowers ALL your healing (ticks + blooms).
func heal_mult(_target: Seat) -> float:
	if aspect == "wildgrove" and flourish:
		return 1.0 + (cfg.flourish_bonus_hi if flourish_hi else cfg.flourish_bonus)
	return 1.0

## Verdance builds from EFFECTIVE healing only — overheal earns nothing.
func on_heal(_s: CombatState, caster: Seat, _target: Seat, eff: float, _over: float) -> void:
	if eff <= 0.0:
		return
	var v := float(caster.vars.get("verdance", 0.0)) + eff * _verd_heal_rate()
	caster.vars["verdance"] = minf(cfg.verdance_max, v)

## A ward ate damage: Verdance for the absorb; Thornveil reflects (scaled by streak AND
## the seeds under the ward); a FULL consume is a Perfect Ward — Sap/Verdance refund, it
## COOKS the bed, and (Thornveil) ramps the streak + spikes the boss.
func on_absorb(s: CombatState, healer: Seat, target: Seat, eaten: float, emptied: bool) -> void:
	var v := float(healer.vars.get("verdance", 0.0)) + eaten * cfg.verd_per_absorb
	healer.vars["verdance"] = minf(cfg.verdance_max, v)
	var tbi := _find_growth(target)
	var tstacks := int(target.hots[tbi].get("stacks", 1)) if tbi >= 0 else 0
	if aspect == "thornveil":
		var frac := clampf(_thorns(healer) * (1.0 + cfg.thorn_per_seed * float(tstacks)), 0.0, cfg.thorns_max)
		var reflect := roundf(eaten * frac)                 # reflect RAMPS with streak × seeds
		if reflect > 0.0:
			CombatCore.damage_boss(s, healer, reflect, &"thorns")
			healer.vars["stat_thorns"] = float(healer.vars.get("stat_thorns", 0.0)) + reflect
	if emptied:
		# A Perfect Ward is a SNAP — refunds + it COOKS the bed under it (roots surge).
		healer.resource = minf(cfg.sap_max, healer.resource + _perfect_sap())
		healer.vars["verdance"] = minf(cfg.verdance_max,
			float(healer.vars["verdance"]) + _perfect_verd())
		if tbi >= 0:
			target.hots[tbi]["cook"] = true
			target.hots[tbi]["tick"] = _seed_tick(s, target.hots[tbi])
		if aspect == "thornveil":
			var ch := mini(_thorn_charge(healer) + 1, cfg.thorn_charge_max)
			healer.vars["thorn_charge"] = ch
			var burst := roundf(cfg.perfect_burst * (1.0 + 0.15 * float(ch)))   # burst scales w/ streak
			CombatCore.damage_boss(s, healer, burst, &"perfect_burst")
			healer.vars["stat_thorns"] = float(healer.vars.get("stat_thorns", 0.0)) + burst
			CombatCore.emit_event(s, {"t": "thorn_snap", "player": healer.is_player, "charge": ch})
		healer.vars["stat_perfect"] = int(healer.vars.get("stat_perfect", 0)) + 1
		CombatCore._bump_diag(s, healer, "perfect_ward")   # class-signature skill signal (token mint)
		if _b("evergreencycle") and target != null and target.role != "healer" and target.alive():
			if tbi >= 0:                                   # the ward seeds itself
				_refresh(s, target)
			else:
				_plant(s, healer, target)
		if _b("bwTrigPerfect"):
			_bw_trigger(s, healer, target, "perfect")      # Phase B: Perfect Ward = proc moment
		CombatCore.emit_event(s, {"t": "perfect_ward", "seat": target})

# ---------------------------------------------------------------- slot-verb Garden mods
# Phase B (build-your-Garden): the innate proc moment is every cashed BLOOM (Lifesurge
# mass-blooms count individually); TRIGGER pieces add moments, PAYLOAD pieces fire on
# every proc, PROPERTY pieces reshape the verb. Deep Garden (opus) doubles the payloads
# while the garden is wide. NO LOCKOUTS. All _b()-gated — boonless sims byte-identical.

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
			CombatCore.damage_boss(s, seat, cfg.mod_thorn, &"bramble")
		if _b("bwPaySap"):
			seat.resource = minf(cfg.sap_max, seat.resource + cfg.mod_sap)
		if _b("bwPayMend"):
			var tgt := target if (target != null and target.alive() and target.role != "healer") \
				else _lowest_ally(s)
			if tgt != null:
				CombatCore.heal_unit(s, tgt, cfg.mod_mend, seat, &"petalfall")
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
		# Skip OTHER healers; but in a RAID (threat_enabled) the healer sees its OWN
		# frame as a triage target. threat_enabled-guarded → solo observation byte-identical.
		if u.role == "healer" and not (s.threat_enabled and u == seat):
			continue
		var gi := _find_growth(u)
		var stacks := int(u.hots[gi].get("stacks", 1)) if gi >= 0 else 0
		var rfrac := _seed_frac(s, u.hots[gi]) if gi >= 0 else 0.0
		party.append({"seat": u, "name": u.unit_name, "role": u.role,
			"frac": u.hp_frac(), "hp": u.hp, "max": u.hp_max, "absorb": u.absorb,
			"debuff": not u.debuff.is_empty(), "hots": u.hots.size(),
			"growth": gi >= 0,
			"stacks": stacks,                               # seeds on this ally
			"ramp_frac": rfrac,                             # 0 = fresh, 1 = cooked
			"cooked": gi >= 0 and rfrac >= 0.85,            # bed at/near full ramp
			"growth_heal": (_remaining(u.hots[gi]) * _bloom_eff() * heal_mult(u)) if gi >= 0 else 0.0,
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
		"flourish_hi": flourish_hi,
		"garden": _garden_count(s),
		"total_seeds": _total_seeds(s),
		"soft_cap": _soft_cap(),
		"hard_cap": cfg.hard_cap,
		"thorn_charge": _thorn_charge(seat),
		"thorn_charge_max": cfg.thorn_charge_max,
		"thorns_pct": _thorns(seat),
		"casting": seat.casting,
		"tg_victim": tg_victim,
		"tg_all": tg_all,
		"party": party,
	}
