## DuelistKit — THE DUELIST, the dodge tank (TANK-PLAN §1/§1b, DUELIST-BRIEF S1). A pure,
## deterministic ClassKit: all state in seat.vars, zero RNG, integer-tick truth.
##
## THE MINIGAME. The boss's melee + telegraphs ARE this seat's incoming bar-stream (TANK skips
## the universal dodge ration, §1a — its stream IS its defense). Two buttons, one rating rule:
##   PARRY (main, F)   — answers ANY size incl. tall; a PERFECT parry HITS BACK (counter + banks ◆).
##   DODGE (secondary) — small/normal only; leaks MORE the bigger the bar (the height law); never hits back.
## Every mitigation flows through modify_incoming, graded by how tight the press was to the bar's
## impact (fresh = PERFECT). Even a perfect leaks a sliver (partial-mit law, cap .90) — NO self-heal.
##
## THE LEASH is WIND (a small, fast-recharging pool), NOT a global cooldown: a press costs wind;
## dry = you can't answer. DODGE recovers fast, PARRY slow even on a land; a mis-press FUMBLES.
##
## FLOW = AGGRO (§1c, BASE — every tank). A clean answer raises seat.vars["flow"]; an un-clean one
## (miss/whiff/fumble) drops it; taking damage NEVER lowers it. A PERFECT PARRY spikes it (the valve
## that replaced the taunt). The engine reads flow to target the boss (CombatCore._flow_aggro / the
## progressive peel) — playing clean HOLDS the boss's attention; slipping lets it drift to the warband.
##
## THE DECK (creeds/modules/boons/rig — S5) layers on top, EACH GUARDED so an empty deck reproduces
## these base numbers (the sim's byte-identical gate). At S1 the kit is deckless (base only).
class_name DuelistKit
extends ClassKit

var aspect: String = "duelist"
var cfg: DuelistConfig

func _init(_aspect: String, _cfg: DuelistConfig) -> void:
	aspect = _aspect
	cfg = _cfg

# --- the tank owns its own graded parry + dodge (never the shared dodge ration / binary negate) ---
func bespoke_defense() -> bool:
	return true

# --- wind / flow / combo accessors --------------------------------------------
func _wind(seat: Seat) -> float:
	return float(seat.vars.get("wind", cfg.wind_max))

func _flow(seat: Seat) -> float:
	return clampf(float(seat.vars.get("flow", cfg.flow_start)), 0.0, 1.0)

func _add_flow(seat: Seat, x: float) -> void:
	seat.vars["flow"] = clampf(_flow(seat) + x, 0.0, 1.0)

func _combo(seat: Seat) -> int:
	return int(seat.vars.get("combo", 0))

# --- per-tick upkeep: wind recharge, flow decay, answer-window expiry ----------
func upkeep(s: CombatState, seat: Seat) -> void:
	# WIND recharges (the fast bubble) — the anti-spam leash
	seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + cfg.wind_regen * s.dt)
	# FLOW drifts down — hold it by playing clean (never by taking hits)
	if seat.vars.has("flow"):
		seat.vars["flow"] = maxf(0.0, _flow(seat) - s.config.flow_decay * s.dt)
	else:
		seat.vars["flow"] = cfg.flow_start   # first tick: the pull opens on the tank
	# the answer window expires
	var atick := int(seat.vars.get("ans_tick", -100000))
	if String(seat.vars.get("ans_kind", "")) != "" \
			and s.tick - atick > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""

# --- input: the two answer buttons (routed here by CombatCore's bespoke_defense seam) ---
## PARRY (main): the commit. Answers any size; a PERFECT parry hits back.
func on_defense_press(s: CombatState, seat: Seat) -> void:
	_press(s, seat, "parry", cfg.parry_cost, cfg.parry_recover)

## DODGE (secondary): the bread. Answers small/normal; the height law leaks the rest of a tall bar.
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	_press(s, seat, "dodge", cfg.dodge_cost, cfg.dodge_recover)

## Open an answer window if wind + recovery allow; else FUMBLE (dry / too soon = a slip + a lockout).
func _press(s: CombatState, seat: Seat, kind: String, cost: float, recover: float) -> void:
	if s.tick < int(seat.vars.get("fumble_until", 0)):
		return                                   # still shaking off the last fumble
	var ready_key := kind + "_ready"
	if s.tick < int(seat.vars.get(ready_key, 0)):
		return                                   # this button is still recovering
	if _wind(seat) < cost:
		# a dry press FUMBLES: no answer, a longer lockout, and flow slips (an un-clean action)
		seat.vars["fumble_until"] = s.tick + _tt(s, cfg.fumble_recover)
		_add_flow(seat, -s.config.flow_slip)
		CombatCore._bump_diag(s, seat, "fumble")
		CombatCore._emit(s, {"t": "duel_fumble", "player": seat.is_player, "seat": seat})
		return
	seat.vars["wind"] = _wind(seat) - cost
	seat.vars[ready_key] = s.tick + _tt(s, recover)
	seat.vars["ans_kind"] = kind
	seat.vars["ans_tick"] = s.tick
	CombatCore._emit(s, {"t": ("duel_parry" if kind == "parry" else "duel_dodge"),
		"player": seat.is_player, "seat": seat})

# --- the mitigation funnel: every incoming BAR is graded + mitigated here (no binary negate) ---
func modify_incoming(s: CombatState, seat: Seat, dmg: float, source: StringName, size: int) -> float:
	# DoT / enrage aren't "bars" — they bypass the answer (the honest bleed the healer covers)
	if source == &"enrage" or source == &"debuff":
		return dmg
	var kind := String(seat.vars.get("ans_kind", ""))
	if kind == "":
		# an un-answered bar: only MISSING A BIG ONE (heavy+) costs aggro — chip is just chip
		if size >= AbilityRes.Size.HEAVY:
			_add_flow(seat, -s.config.flow_slip)
			CombatCore._bump_diag(s, seat, "miss")
		return dmg
	var age := s.tick - int(seat.vars.get("ans_tick", -100000))
	if age < 0 or age > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""
		return dmg
	var grade := _grade(s, kind, age)
	var mit := _mit(kind, grade, size)
	seat.vars["ans_kind"] = ""                   # one press answers one bar (the WEAVE: re-press per beat)
	_on_answer(s, seat, kind, grade, size)
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": kind, "grade": grade, "size": size})
	return dmg * (1.0 - mit)

## Grade a press by how tight it was to the bar's impact (small age = fresh press = PERFECT).
func _grade(s: CombatState, kind: String, age: int) -> int:
	var pf := _tt(s, cfg.parry_perfect if kind == "parry" else cfg.dodge_perfect)
	var gd := _tt(s, cfg.parry_good if kind == "parry" else cfg.dodge_good)
	if age <= pf:
		return StrikeRes.Grade.PERFECT
	if age <= gd:
		return StrikeRes.Grade.GOOD
	return StrikeRes.Grade.GRAZE

## Mitigation fraction, by button × grade × size — THE HEIGHT LAW (§1b) + the .90 cap:
##   small  (NONE/LIGHT): EITHER button, ANY rating → floor at GOOD (you don't need tight timing).
##   normal (HEAVY): MAIN any; a DODGE (secondary) leaks more (it "needs good+").
##   tall   (CRUSH): MAIN only — a DODGE barely helps (leak scales with size).
func _mit(kind: String, grade: int, size: int) -> float:
	var m := 0.0
	if kind == "parry":
		m = _by_grade(grade, cfg.mit_parry_perfect, cfg.mit_parry_good, cfg.mit_parry_graze)
		if size <= AbilityRes.Size.LIGHT:
			m = maxf(m, cfg.mit_parry_good)
	else:
		m = _by_grade(grade, cfg.mit_dodge_perfect, cfg.mit_dodge_good, cfg.mit_dodge_graze)
		if size <= AbilityRes.Size.LIGHT:
			m = maxf(m, cfg.mit_dodge_good)                # small: any rating answers
		else:
			m -= cfg.dodge_leak_per_size * float(size - AbilityRes.Size.LIGHT)  # normal/tall leak more
	return clampf(m, 0.0, cfg.mit_cap)

func _by_grade(grade: int, pf: float, gd: float, gz: float) -> float:
	match grade:
		StrikeRes.Grade.PERFECT: return pf
		StrikeRes.Grade.GOOD: return gd
		_: return gz

## A bar was answered: feed FLOW by the grade, and a PERFECT PARRY hits back (counter + ◆ + spike).
func _on_answer(s: CombatState, seat: Seat, kind: String, grade: int, _size: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT: _add_flow(seat, s.config.flow_gain_perfect)
		StrikeRes.Grade.GOOD: _add_flow(seat, s.config.flow_gain_good)
		_: _add_flow(seat, s.config.flow_gain_graze)
	CombatCore._bump_diag(s, seat, StrikeRes.grade_name(grade))
	if kind == "parry" and grade == StrikeRes.Grade.PERFECT:
		# THE COUNTER: the perfect parry hits back — the "look at me" that replaced the taunt
		CombatCore.damage_boss(s, seat, cfg.counter_dmg, &"counter")
		seat.vars["combo"] = mini(cfg.combo_max, _combo(seat) + 1)   # ◆ income is PARRY-only at base
		_add_flow(seat, s.config.flow_spike)                         # the flow SPIKE (the valve)
		CombatCore._bump_diag(s, seat, "counter")
		CombatCore._emit(s, {"t": "duel_counter", "player": seat.is_player, "seat": seat})

# --- abilities: ⚡ DUMP (spend the ◆ bank for pure damage — off-rhythm burst) -----
func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	if String(id) != "dump":
		return false
	if s.tick < seat.gcd_until_tick:
		return false
	var c := _combo(seat)
	if c <= 0:
		return false
	var dmg := cfg.dump_per_combo * float(c)
	CombatCore.damage_boss(s, seat, dmg, &"dump")
	seat.vars["combo"] = 0
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	CombatCore._bump_diag(s, seat, "dump")
	CombatCore._emit(s, {"t": "duel_dump", "player": seat.is_player, "seat": seat, "amt": int(dmg)})
	return true

# --- observation for policies / HUD -------------------------------------------
func observe(s: CombatState, seat: Seat) -> Dictionary:
	return {
		"tick": s.tick,
		"aspect": aspect,
		"flow": _flow(seat),
		"flow_lock": s.config.flow_lock_floor,
		"wind": _wind(seat),
		"wind_max": cfg.wind_max,
		"parry_cost": cfg.parry_cost,
		"dodge_cost": cfg.dodge_cost,
		"combo": _combo(seat),
		"combo_max": cfg.combo_max,
		"answering": String(seat.vars.get("ans_kind", "")),
		"parry_ready": s.tick >= int(seat.vars.get("parry_ready", 0)),
		"dodge_ready": s.tick >= int(seat.vars.get("dodge_ready", 0)),
		"fumbling": s.tick < int(seat.vars.get("fumble_until", 0)),
	}

## STATS PAGE v2 — the Duelist's spec rows for the FULL REPORT (read-only from seat.diag).
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
