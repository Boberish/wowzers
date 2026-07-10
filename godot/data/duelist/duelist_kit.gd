## DuelistKit — THE DUELIST, the dodge tank (TANK-PLAN §1/§1b/§3/§10, DUELIST-BRIEF). A pure,
## deterministic ClassKit: all state in seat.vars, zero RNG, integer-tick truth.
##
## THE MINIGAME. The boss's melee + telegraphs ARE this seat's incoming bar-stream (§1a). Two
## buttons, one rating rule, graded by press-timing via modify_incoming:
##   PARRY (main, F)   — answers ANY size incl. tall; a PERFECT parry HITS BACK (counter + banks ◆).
##   DODGE (secondary) — small/normal (any rating); leaks MORE the bigger the bar (the height law).
## Every mitigation leaks a sliver (partial-mit cap .90) — NO self-heal. WIND is the leash. FLOW is
## aggro (§1c): a clean answer raises seat.vars["flow"], an un-clean one drops it, taking damage never
## does; a PERFECT PARRY spikes it (the valve that replaced the taunt). The engine reads flow to target.
##
## THE DECK (creeds/modules/boons/rig — S5..S7) layers on top, EACH GUARDED so an empty creed + no
## modules + no boons + no rig reproduce the base numbers exactly (the sim's byte-identical gate):
##   CREEDS  — run-long temperament, _cr() (DuelistCreeds; "" = base). Veteran/Wager/Bellows/Dancer.
##   MODULES — a Floor-1 gauge, _m() (Crucible/Scales/Whetstone/Flow).
##   BOONS   — drafted upgrades, _b() (DuelistBoons); TRANSFORMS rewrite a button (Prise/Remise/Flèche).
##   RIG     — one wired WHEN→THEN, _rig_fire() (DuelistRig; empty = never touched).
##   EN GARDE — the ~1-min signature CD (invite + wall + double flow) — an amplifier, never a taunt.
class_name DuelistKit
extends ClassKit

var aspect: String = "duelist"
var cfg: DuelistConfig
var creed_id: String = ""              ## the run's temperament ("" = none, byte-identical base)
var rig: Dictionary = {}               ## the ONE Combo rig — {"when": id, "then": id}

func _init(_aspect: String, _cfg: DuelistConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func accent() -> Color:
	return Palette.STEEL   # the Duelist's tank steel (meter/HUD read this hook)

func bespoke_defense() -> bool:
	return true

# --- creed reads (identity-defaulted; "" collapses to base → byte-identical) ---
func _cr_f(key: String) -> float:
	return float(DuelistCreeds.field(creed_id, key))

func _cr_b(key: String) -> bool:
	return bool(DuelistCreeds.field(creed_id, key))

# --- wind / flow / combo accessors --------------------------------------------
func _wind(seat: Seat) -> float:
	return float(seat.vars.get("wind", cfg.wind_max))

func _flow(seat: Seat) -> float:
	return clampf(float(seat.vars.get("flow", cfg.flow_start)), 0.0, 1.0)

func _add_flow(s: CombatState, seat: Seat, x: float) -> void:
	# EN GARDE pays DOUBLE flow on a clean answer (x > 0 only)
	if x > 0.0 and _engarde_live(s, seat):
		x *= 2.0
	seat.vars["flow"] = clampf(_flow(seat) + x, 0.0, 1.0)

func _combo(seat: Seat) -> int:
	return int(seat.vars.get("combo", 0))

func _combo_max() -> int:
	return cfg.combo_max + (cfg.deep_pockets_cap if _b("deepPockets") else 0) + int(_cr_f("combo_cap_delta"))

func _bank(s: CombatState, seat: Seat, n: int) -> void:
	seat.vars["combo"] = mini(_combo_max(), _combo(seat) + n)
	if _m("whetstone"):                                  # a fresh pip starts dull, sharpens over time
		var sharp: Array = seat.vars.get("whet_sharp", [])
		for i in range(n):
			sharp.append(s.tick + _tt(s, cfg.whet_sharpen_sec))
		seat.vars["whet_sharp"] = sharp

# --- EN GARDE (the signature CD) ----------------------------------------------
func _engarde_live(s: CombatState, seat: Seat) -> bool:
	return s.tick < int(seat.vars.get("engarde_until", 0))

# --- per-tick upkeep: wind recharge, flow decay, answer expiry, modules, en garde ---
func upkeep(s: CombatState, seat: Seat) -> void:
	if not seat.vars.has("flow"):
		seat.vars["flow"] = cfg.flow_start                # first tick: the pull opens on the tank
	# WIND recharges — Bellows halves the passive drip, the Ease Dial speeds it, a Crucible CRASH kills it
	var regen := cfg.wind_regen * _cr_f("wind_regen_mult")
	if _b("easeDial"):
		regen *= 1.20
	if s.tick < int(seat.vars.get("crucible_crash_until", 0)):
		regen = 0.0
	seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + regen * s.dt)
	# FLOW drifts down — Lodestone slows the drift; never raised by upkeep
	var decay := s.config.flow_decay * (cfg.lodestone_decay_mult if _b("lodestone") else 1.0)
	seat.vars["flow"] = maxf(0.0, _flow(seat) - decay * s.dt)
	# the answer window expires
	if String(seat.vars.get("ans_kind", "")) != "" \
			and s.tick - int(seat.vars.get("ans_tick", -100000)) > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""
	# EN GARDE ends → normal flow drops resume (nothing to do; the flag lapses by tick)
	# HOLD THE LINE (support): while flow holds above the lock floor, the warband deals more
	if _b("holdTheLine"):
		_tick_hold_line(s, seat)
	# MODULE gauges
	if _m("crucible"):
		_tick_crucible(s, seat)
	if _m("scales"):
		_tick_scales(s, seat)
	if _m("whetstone"):
		_prune_whet(s, seat)
	# a live FLÈCHE load expires → half the ◆ return, rest fizzles
	if int(seat.vars.get("fleche_until", 0)) > 0 and s.tick >= int(seat.vars.get("fleche_until", 0)):
		var loaded := int(seat.vars.get("fleche_load", 0))
		seat.vars["fleche_until"] = 0
		seat.vars["fleche_load"] = 0
		if loaded > 0:
			_bank(s, seat, maxi(1, loaded / 2))            # half back, the rest fizzles
			CombatCore._emit(s, {"t": "duel_fleche_fizzle", "player": seat.is_player, "seat": seat})

# --- input: the two answer buttons + EN GARDE + DUMP --------------------------
func on_defense_press(s: CombatState, seat: Seat) -> void:
	# THE DANCER (creed): the PARRY button is GONE — a parry press becomes a DODGE (a perfect dodge
	# counters via dodge_is_parry). Keeps the AI's tall-bar parry legible as the one-button play.
	if _cr_b("no_parry"):
		_press(s, seat, "dodge", _dodge_cost(seat), cfg.dodge_recover)
		return
	# REMISE (transform): the parry is two half-presses — first press PRIMES, second COMMITS.
	if _b("remise"):
		_remise_press(s, seat)
		return
	_press(s, seat, "parry", _parry_cost(s, seat), cfg.parry_recover)

func on_dodge_press(s: CombatState, seat: Seat) -> void:
	_press(s, seat, "dodge", _dodge_cost(seat), cfg.dodge_recover)

func _parry_cost(s: CombatState, seat: Seat) -> float:
	# WHITE STEEL (Crucible ignited): parries cost 0 wind
	if s.tick < int(seat.vars.get("crucible_ignite_until", 0)):
		return 0.0
	var c := cfg.parry_cost * _cr_f("parry_cost_mult")
	# PERFECT FORM: a queued discount from a recent perfect dodge
	if _b("perfectForm") and s.tick < int(seat.vars.get("pf_cheap_until", 0)):
		c = maxf(0.0, c - 1.5)
	return c

func _dodge_cost(seat: Seat) -> float:
	var c := cfg.dodge_cost
	if _b("featherStep"):
		c = maxf(cfg.feather_step_floor, c * cfg.feather_step_mult)
	return c

## Open an answer window if wind + recovery allow; else FUMBLE. OVERREACH lets a winded PARRY pay
## in blood instead. Crucible white-steel + Feather Step already softened the cost above.
func _press(s: CombatState, seat: Seat, kind: String, cost: float, recover: float) -> void:
	if s.tick < int(seat.vars.get("fumble_until", 0)):
		return
	var ready_key := kind + "_ready"
	if s.tick < int(seat.vars.get(ready_key, 0)):
		return
	if _wind(seat) < cost:
		# OVERREACH: a winded PARRY pays in blood instead of fumbling (never below the HP floor)
		if kind == "parry" and _b("overreach") \
				and seat.hp > seat.hp_max * cfg.overreach_floor + seat.hp_max * cfg.overreach_hp_cost:
			seat.hp -= seat.hp_max * cfg.overreach_hp_cost
			seat.vars["overreach_blood"] = true          # a landing blood-parry banks ◆◆
			CombatCore._emit(s, {"t": "duel_blood_parry", "player": seat.is_player, "seat": seat})
		else:
			seat.vars["fumble_until"] = s.tick + _tt(s, cfg.fumble_recover)
			_add_flow(s, seat, -s.config.flow_slip)
			CombatCore._bump_diag(s, seat, "fumble")
			CombatCore._emit(s, {"t": "duel_fumble", "player": seat.is_player, "seat": seat})
			return
	else:
		seat.vars["wind"] = _wind(seat) - cost
	seat.vars[ready_key] = s.tick + _tt(s, recover)
	seat.vars["ans_kind"] = kind
	seat.vars["ans_tick"] = s.tick
	CombatCore._emit(s, {"t": ("duel_parry" if kind == "parry" else "duel_dodge"),
		"player": seat.is_player, "seat": seat})

# --- the mitigation funnel: every incoming BAR is graded + mitigated here ------
func modify_incoming(s: CombatState, seat: Seat, dmg: float, source: StringName, size: int) -> float:
	if source == &"enrage" or source == &"debuff":
		return dmg
	var kind := String(seat.vars.get("ans_kind", ""))
	if kind == "":
		# an un-answered bar. A PRIMED bar (Remise) still leaks less. Missing a BIG one costs aggro.
		var leaked := dmg
		if _b("remise") and s.tick < int(seat.vars.get("remise_prime_until", 0)):
			var cut := cfg.remise_leak_cut + (0.15 if _b("doorBeatParry") else 0.0)
			leaked *= (1.0 - cut)
		if size >= AbilityRes.Size.HEAVY:
			_add_flow(s, seat, -s.config.flow_slip)
			CombatCore._bump_diag(s, seat, "miss")
			# WAGER: a miss leaks MORE · VETERAN: a miss refunds half its wind (the learner's mercy)
			leaked *= (1.0 + _cr_f("miss_leak_bonus"))
			if _cr_f("miss_wind_refund") > 0.0:
				seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + _cr_f("miss_wind_refund"))
			# BLOOD PRICE: eating a big one isn't pure loss — bank ◆ + wind
			if _b("bloodPrice"):
				_bank(s, seat, 1)
				seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + 2.0)
		return _engarde_wall(s, seat, leaked, dmg)
	var age := s.tick - int(seat.vars.get("ans_tick", -100000))
	if age < 0 or age > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""
		return dmg
	var grade := _grade(s, kind, age)
	var mit := _mit(kind, grade, size)
	seat.vars["ans_kind"] = ""                            # one press answers one bar (the WEAVE)
	_on_answer(s, seat, kind, grade, size)
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": kind, "grade": grade, "size": size})
	return _engarde_wall(s, seat, dmg * (1.0 - mit), dmg)

## EN GARDE's wall (§10.2): while the challenge holds, leaks + slivers are HALVED. Base = no-op.
func _engarde_wall(s: CombatState, seat: Seat, leaked: float, _full: float) -> float:
	if _engarde_live(s, seat):
		return leaked * 0.5
	return leaked

func _grade(s: CombatState, kind: String, age: int) -> int:
	var pfw := (cfg.parry_perfect if kind == "parry" else cfg.dodge_perfect)
	pfw *= _cr_f("parry_perfect_mult")                    # VETERAN widens the perfect window
	if _b("easeDial"):
		pfw *= 1.25
	var pf := _tt(s, pfw)
	var gd := _tt(s, cfg.parry_good if kind == "parry" else cfg.dodge_good)
	if age <= pf:
		return StrikeRes.Grade.PERFECT
	if age <= gd:
		return StrikeRes.Grade.GOOD
	return StrikeRes.Grade.GRAZE

func _mit(kind: String, grade: int, size: int) -> float:
	var m := 0.0
	if kind == "parry":
		m = _by_grade(grade, cfg.mit_parry_perfect, cfg.mit_parry_good, cfg.mit_parry_graze)
		if size <= AbilityRes.Size.LIGHT:
			m = maxf(m, cfg.mit_parry_good)
	else:
		m = _by_grade(grade, cfg.mit_dodge_perfect, cfg.mit_dodge_good, cfg.mit_dodge_graze)
		if size <= AbilityRes.Size.LIGHT:
			m = maxf(m, cfg.mit_dodge_good)
		else:
			m -= cfg.dodge_leak_per_size * float(size - AbilityRes.Size.LIGHT)
	return clampf(m, 0.0, cfg.mit_cap)

func _by_grade(grade: int, pf: float, gd: float, gz: float) -> float:
	match grade:
		StrikeRes.Grade.PERFECT: return pf
		StrikeRes.Grade.GOOD: return gd
		_: return gz

## A bar was answered: feed FLOW by grade, run the creed/module/boon payoffs, and (perfect PARRY,
## or a perfect DODGE under the Dancer) hit back — counter + ◆ + spike + the transforms.
func _on_answer(s: CombatState, seat: Seat, kind: String, grade: int, size: int) -> void:
	var gain := s.config.flow_gain_graze
	match grade:
		StrikeRes.Grade.PERFECT: gain = s.config.flow_gain_perfect
		StrikeRes.Grade.GOOD: gain = s.config.flow_gain_good
	_add_flow(s, seat, gain)
	CombatCore._bump_diag(s, seat, StrikeRes.grade_name(grade))
	# BELLOWS: every clean answer instantly refunds wind (the pool becomes a chain)
	if _cr_f("clean_wind_bonus") > 0.0:
		seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + _cr_f("clean_wind_bonus"))
	# SCALES: parries tip crimson, dodges tip blue
	if _m("scales"):
		seat.vars["scales"] = clampf(float(seat.vars.get("scales", 0.0)) + (0.34 if kind == "parry" else -0.34), -1.0, 1.0)
	# PERFECT FORM: a perfect DODGE refunds its wind + arms a cheaper next parry
	if _b("perfectForm") and kind == "dodge" and grade == StrikeRes.Grade.PERFECT:
		seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + _dodge_cost(seat))
		seat.vars["pf_cheap_until"] = s.tick + _tt(s, 2.0)
	# THE RALLY: every 3rd LAND in an unbroken chain banks double (a graze/miss breaks it)
	if _b("theRally"):
		if grade == StrikeRes.Grade.GRAZE:
			seat.vars["rally_chain"] = 0
		elif kind == "parry" or (_cr_b("dodge_is_parry") and grade == StrikeRes.Grade.PERFECT):
			var rc := int(seat.vars.get("rally_chain", 0)) + 1
			seat.vars["rally_chain"] = rc
	# THE HIT-BACK — a PERFECT PARRY (or a perfect DODGE under the Dancer, every other perfect).
	var is_parry_hit := kind == "parry" and grade == StrikeRes.Grade.PERFECT
	var is_dancer_hit := _cr_b("dodge_is_parry") and kind == "dodge" and grade == StrikeRes.Grade.PERFECT \
		and (int(seat.vars.get("dancer_alt", 0)) % 2 == 0)
	if _cr_b("dodge_is_parry") and kind == "dodge" and grade == StrikeRes.Grade.PERFECT:
		seat.vars["dancer_alt"] = int(seat.vars.get("dancer_alt", 0)) + 1
	if not (is_parry_hit or is_dancer_hit):
		return
	# PRISE DE FER (transform): a perfect parry SEIZES the bar instead of countering NOW.
	if _b("prisedefer") and is_parry_hit:
		seat.vars["seize_start"] = s.tick
		seat.vars["seize_size"] = size
		CombatCore._emit(s, {"t": "duel_seize", "player": seat.is_player, "seat": seat})
		return
	_counter(s, seat, size, kind)

## The counter hit-back: damage_boss (× creed/boon mults), bank ◆ (×2 from several sources), spike.
func _counter(s: CombatState, seat: Seat, size: int, _kind: String) -> void:
	var mult := _cr_f("counter_mult")                     # Veteran ×0.75 / Wager ×1.4
	if _b("heavierSteel"):
		mult *= cfg.heavier_steel_mult
	if _b("highLine") and size >= AbilityRes.Size.CRUSH:
		mult *= 1.5
	if s.tick < int(seat.vars.get("crucible_ignite_until", 0)):
		mult *= 1.5                                       # WHITE STEEL counters ×1.5
	CombatCore.damage_boss(s, seat, cfg.counter_dmg * mult, &"counter")
	var pips := 1
	if _cr_b("parry_land_double"):                        # WAGER: a land banks ◆◆
		pips = 2
	if _b("highLine") and size >= AbilityRes.Size.CRUSH:  # HIGH LINE: tall land banks ◆◆ + wind
		pips = maxi(pips, 2)
		seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + 1.0)
	if bool(seat.vars.get("overreach_blood", false)):     # OVERREACH O: a blood-parry banks ◆◆
		pips = maxi(pips, 2)
		seat.vars["overreach_blood"] = false
	if s.tick < int(seat.vars.get("crucible_ignite_until", 0)):
		pips = maxi(pips, 2)                              # WHITE STEEL lands bank ◆◆
	# THE RALLY: the 3rd land in the chain banks double
	if _b("theRally") and int(seat.vars.get("rally_chain", 0)) % 3 == 0 and int(seat.vars.get("rally_chain", 0)) > 0:
		pips *= 2
	_bank(s, seat, pips)
	_add_flow(s, seat, s.config.flow_spike)               # the flow SPIKE (the valve)
	CombatCore._bump_diag(s, seat, "counter")
	CombatCore._emit(s, {"t": "duel_counter", "player": seat.is_player, "seat": seat})
	_rig_fire(s, seat, "tall_land" if size >= AbilityRes.Size.CRUSH else "")

# --- abilities: EN GARDE · ⚡ DUMP (+ FLÈCHE load) · the seize release --------
func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match String(id):
		"engarde":
			return _engarde(s, seat)
		"seize_release":
			return _seize_release(s, seat)
		"dump":
			return _dump(s, seat)
	return false

func _engarde(s: CombatState, seat: Seat) -> bool:
	if s.tick < int(seat.cooldowns.get("engarde", 0)):
		return false
	seat.vars["engarde_until"] = s.tick + _tt(s, cfg.engarde_dur)
	seat.vars["engarde_slips"] = 0
	seat.cooldowns["engarde"] = s.tick + _tt(s, cfg.engarde_cd)
	CombatCore._emit(s, {"t": "duel_engarde", "player": seat.is_player, "seat": seat})
	return true

func _dump(s: CombatState, seat: Seat) -> bool:
	if s.tick < seat.gcd_until_tick:
		return false
	var c := _combo(seat)
	if c <= 0:
		return false
	# FLÈCHE (transform): DUMP no longer fires from standing — it LOADS the bank onto the blade.
	if _b("fleche") and int(seat.vars.get("fleche_until", 0)) == 0:
		seat.vars["fleche_load"] = c
		seat.vars["fleche_until"] = s.tick + _tt(s, cfg.fleche_load_sec)
		seat.vars["combo"] = 0
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
		CombatCore._emit(s, {"t": "duel_fleche_load", "player": seat.is_player, "seat": seat, "n": c})
		return true
	_fire_dump(s, seat, c, 1.0)
	seat.vars["combo"] = 0
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	return true

## Fire the ◆ bank as damage — the shared dump math (base × Powder Keg × All In × Whetstone sharp
## × the FLOW module × any flèche bonus). Avalanche re-plays it as a returning string (functional).
func _fire_dump(s: CombatState, seat: Seat, pips: int, extra: float) -> void:
	var per := cfg.dump_per_combo
	if _b("powderKeg"):
		per *= (1.0 + cfg.powder_keg_per)
	var dmg := per * float(pips) * extra
	# WHETSTONE: sharpened pips hit ×1.5
	if _m("whetstone"):
		var sharp: Array = seat.vars.get("whet_sharp", [])
		var n_sharp := 0
		for t in sharp:
			if s.tick >= int(t):
				n_sharp += 1
		var bonus_pips := mini(n_sharp, pips)
		dmg += cfg.dump_per_combo * float(bonus_pips) * (cfg.whet_sharp_mult - 1.0)
		seat.vars["whet_sharp"] = []
	# ALL IN: a full-bank dump hits ×1.4
	if _b("allIn") and pips >= _combo_max():
		dmg *= cfg.all_in_mult
	# THE FLOW module: high flow ramps the dump
	if _m("flow"):
		dmg *= (1.0 + cfg.flow_dump_max * _flow(seat))
	CombatCore.damage_boss(s, seat, dmg, &"dump")
	CombatCore._bump_diag(s, seat, "dump")
	var ev := "duel_avalanche" if _b("ksAvalanche") else "duel_dump"
	CombatCore._emit(s, {"t": ev, "player": seat.is_player, "seat": seat, "amt": int(dmg)})
	_rig_fire(s, seat, "big_spend" if pips >= 4 else "")

## PRISE DE FER: release the seized bar — throws it back, scaling with size + hold length.
func _seize_release(s: CombatState, seat: Seat) -> bool:
	if int(seat.vars.get("seize_start", 0)) <= 0:
		return false
	var held := float(s.tick - int(seat.vars.get("seize_start", 0))) * s.dt
	var frac := clampf(held / cfg.seize_max_hold, 0.0, 1.0)
	var size := int(seat.vars.get("seize_size", 1))
	var mult := _cr_f("counter_mult") * (1.0 + cfg.seize_throw_mult * frac) * (1.0 + 0.25 * float(size))
	if _b("doorWrenchedSteel"):
		mult *= 1.40
	CombatCore.damage_boss(s, seat, cfg.counter_dmg * mult, &"seize")
	_bank(s, seat, 1)
	_add_flow(s, seat, s.config.flow_spike)
	seat.vars["seize_start"] = 0
	if _b("doorDisarm") and frac >= 0.95:                 # a full seize downgrades the next bar
		seat.vars["disarm_next"] = true
	if frac >= 0.95:
		_rig_fire(s, seat, "full_seize")
	CombatCore._emit(s, {"t": "duel_throw", "player": seat.is_player, "seat": seat})
	return true

## REMISE: parry as two half-presses — PRIME (early, cheap) then COMMIT (in-window, the rest).
func _remise_press(s: CombatState, seat: Seat) -> void:
	if s.tick < int(seat.vars.get("fumble_until", 0)):
		return
	# already primed + still in the prime window → this press is the COMMIT (full parry)
	if s.tick < int(seat.vars.get("remise_prime_until", 0)):
		seat.vars["remise_prime_until"] = 0
		var rest := _parry_cost(s, seat) * (1.0 - cfg.remise_prime_frac)
		if _wind(seat) >= rest:
			seat.vars["wind"] = _wind(seat) - rest
			seat.vars["ans_kind"] = "parry"
			seat.vars["ans_tick"] = s.tick
			seat.vars["remise_committed"] = true
			CombatCore._emit(s, {"t": "duel_parry", "player": seat.is_player, "seat": seat})
		return
	# else PRIME: pay ~1/3, open the prime window (a primed-then-missed bar leaks less)
	var prime := _parry_cost(s, seat) * cfg.remise_prime_frac
	if _wind(seat) < prime:
		return
	seat.vars["wind"] = _wind(seat) - prime
	seat.vars["remise_prime_until"] = s.tick + _tt(s, cfg.answer_active)
	CombatCore._emit(s, {"t": "duel_prime", "player": seat.is_player, "seat": seat})

# --- MODULE ticks -------------------------------------------------------------
func on_damage_taken(s: CombatState, seat: Seat, dmg: float, _source: StringName, _size: int) -> void:
	if _m("crucible") and s.tick >= int(seat.vars.get("crucible_ignite_until", 0)) \
			and s.tick >= int(seat.vars.get("crucible_crash_until", 0)):
		seat.vars["crucible"] = float(seat.vars.get("crucible", 0.0)) + dmg

func _tick_crucible(s: CombatState, seat: Seat) -> void:
	if s.tick == int(seat.vars.get("crucible_ignite_until", 0)):     # ignite just ended → CRASH
		seat.vars["crucible_crash_until"] = s.tick + _tt(s, cfg.crucible_crash_sec)
	if float(seat.vars.get("crucible", 0.0)) >= cfg.crucible_full \
			and s.tick >= int(seat.vars.get("crucible_ignite_until", 0)) \
			and s.tick >= int(seat.vars.get("crucible_crash_until", 0)):
		seat.vars["crucible"] = 0.0
		seat.vars["crucible_ignite_until"] = s.tick + _tt(s, cfg.crucible_ignite_sec)
		CombatCore._emit(s, {"t": "duel_ignite", "player": seat.is_player, "seat": seat})

func _tick_scales(s: CombatState, seat: Seat) -> void:
	# drift back toward balance; the edge is fed in _on_answer, read in outgoing/mit
	var v := float(seat.vars.get("scales", 0.0))
	seat.vars["scales"] = v - signf(v) * minf(absf(v), 0.15 * s.dt)

func _prune_whet(s: CombatState, seat: Seat) -> void:
	pass  # pips sharpen by tick comparison in _fire_dump; a dulled pip is dropped on an unanswered hit

# --- HOLD THE LINE (support) — reuses the engine's group-damage aura hook ------
func _tick_hold_line(s: CombatState, seat: Seat) -> void:
	if _flow(seat) < s.config.flow_lock_floor:
		return
	var until := s.tick + 2
	for u in s.seats:
		if u.role != "healer" and u.alive():
			u.vars["well_hour_mult"] = cfg.hold_line_mult   # generic party-dmg aura (shared hook)
			u.vars["well_hour_until"] = until

# --- THE RIG (one wired WHEN→THEN; empty rig never touched → byte-identical base) ---
func _rig_fire(s: CombatState, seat: Seat, when_id: String) -> void:
	if when_id == "" or rig.is_empty() or String(rig.get("when", "")) != when_id:
		return
	var then_id := String(rig.get("then", ""))
	match DuelistRig.then_kind(then_id):
		"strike":
			CombatCore.damage_boss(s, seat, float(DuelistRig.magnitude(when_id, then_id)), &"rig")
		"breath":
			seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + float(DuelistRig.magnitude(when_id, then_id)))
		"pip":
			_bank(s, seat, DuelistRig.magnitude(when_id, then_id))
		"iron":
			seat.dr = 0.20
			seat.dr_until_tick = s.tick + _tt(s, 2.0)
		"banner":
			var until := s.tick + _tt(s, 2.5)
			for u in s.seats:
				if u.role != "healer" and u.alive():
					u.vars["well_hour_mult"] = 1.05
					u.vars["well_hour_until"] = until
	CombatCore._emit(s, {"t": "duel_rig", "player": seat.is_player, "seat": seat, "when": when_id, "then": then_id})

# --- observation for policies / HUD -------------------------------------------
func observe(s: CombatState, seat: Seat) -> Dictionary:
	var o := {
		"tick": s.tick,
		"aspect": aspect,
		"flow": _flow(seat),
		"flow_lock": s.config.flow_lock_floor,
		"wind": _wind(seat),
		"wind_max": cfg.wind_max,
		"parry_cost": _parry_cost(s, seat),
		"dodge_cost": _dodge_cost(seat),
		"combo": _combo(seat),
		"combo_max": _combo_max(),
		"answering": String(seat.vars.get("ans_kind", "")),
		"parry_ready": s.tick >= int(seat.vars.get("parry_ready", 0)),
		"dodge_ready": s.tick >= int(seat.vars.get("dodge_ready", 0)),
		"fumbling": s.tick < int(seat.vars.get("fumble_until", 0)),
		"no_parry": _cr_b("no_parry"),
		"engarde_ready": s.tick >= int(seat.cooldowns.get("engarde", 0)),
		"engarde_live": _engarde_live(s, seat),
		"seizing": int(seat.vars.get("seize_start", 0)) > 0,
		"fleche_loaded": int(seat.vars.get("fleche_until", 0)) > 0,
	}
	if _m("crucible"):
		o["crucible"] = float(seat.vars.get("crucible", 0.0))
		o["crucible_full"] = cfg.crucible_full
		o["white_steel"] = s.tick < int(seat.vars.get("crucible_ignite_until", 0))
	if _m("scales"):
		o["scales"] = float(seat.vars.get("scales", 0.0))
	return o

func recap_spec(_s: CombatState, seat: Seat) -> Array:
	var d: Dictionary = seat.diag
	var rows: Array = []
	var counters := int(d.get("counter", 0))
	if counters > 0:
		rows.append({"label": "Counters", "value": str(counters), "hint": "perfect parries (hit back)"})
	var perf := int(d.get("perfect", 0))
	var total := perf + int(d.get("good", 0)) + int(d.get("graze", 0)) + int(d.get("miss", 0))
	if total > 0:
		rows.append({"label": "Sharp", "value": "%d%%" % int(round(100.0 * float(perf) / float(total))),
			"hint": "answers graded perfect"})
	var fum := int(d.get("fumble", 0))
	if fum > 0:
		rows.append({"label": "Fumbles", "value": str(fum), "hint": "dry / mis-pressed"})
	return rows
