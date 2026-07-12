## DuelistKit — THE DUELIST, the dodge tank, rebuilt from the base (TANK-PLAN §0 THE CHANNEL
## CONTRACT v3, tank-v2 2026-07-11). A pure, deterministic ClassKit: all state in seat.vars,
## zero RNG, integer-tick truth.
##
## THE MINIGAME (v3 + §0 THE PRESS pass 2, restored). The engine's committed STREAM is this
## seat's incoming bar timeline; a press CLAIMS the nearest bar within ±answer_claim and is
## judged INSTANTLY, symmetric around gate-touch (verdict + payoffs fire AT the press — the
## Twinfang model, Bill: "the twinfang is super good, do that"); resolve applies the stored
## grade. Telegraph busters/globals keep the open-window model (big slow reads):
##   PARRY (main)      — BINARY: land within ±parry_land of gate-touch = mit .95 + COUNTER
##                       hit-back + ◆ + flow spike; pressed-but-out = the miss (.18 token mit,
##                       wind gone). 3.5 wind. Answers AUTO / HEAVY / BUSTER — never a GLOBAL.
##   DODGE (secondary) — GRADED on the one game-wide ladder GRAZE<GOOD<PERFECT<BULLSEYE
##                       (|press−impact|/answer_claim on the grade_*_frac ladder). 1 wind.
##                       Answers AUTO at any grade; HEAVY/BUSTER at BULLSEYE only
##                       (the power leak still applies). Never hits back.
##   FEINT             — a disguised bar (purple is the only tell): press = BAITED at the
##                       press (flow slip + lockout), hold = READ (via on_stream_bar).
##   FLURRY MODE       — dodge-only, parry SEALED, wind FREE: miss one beat and the group is
##                       BLOWN (the rest land whole); a clean weave pays the free RIPOSTE.
##   EAT               — unavoidable; passes through whole (the healer's moment).
## Every mitigation leaks a sliver (partial-mit cap .90) — NO self-heal. WIND is the leash.
## FLOW is aggro (§1c): clean answers raise it, un-clean answers drop it, damage never does;
## a LANDED PARRY spikes it (the valve that replaced the taunt). The engine reads flow to target.
##
## DECKLESS BY DESIGN: tank-v2 ships the base kit only — creeds/modules/boons/rig/transforms
## re-land per-verdict AFTER Bill's base playtest (§0 · two-track law). The _b()/_m() hooks
## exist on ClassKit; nothing here reads them yet.
class_name DuelistKit
extends ClassKit

var aspect: String = "duelist"
var cfg: DuelistConfig

func _init(_aspect: String, _cfg: DuelistConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func accent() -> Color:
	return Palette.STEEL   # the Duelist's tank steel (meter/HUD read this hook)

func bespoke_defense() -> bool:
	return true

# --- wind / flow / combo accessors --------------------------------------------
func _wind(seat: Seat) -> float:
	return float(seat.vars.get("wind", cfg.wind_max))

func _flow(seat: Seat) -> float:
	return clampf(float(seat.vars.get("flow", cfg.flow_start)), 0.0, 1.0)

func _add_flow(s: CombatState, seat: Seat, x: float) -> void:
	if x > 0.0 and _engarde_live(s, seat):
		x *= 2.0                                          # EN GARDE pays DOUBLE on clean answers
	seat.vars["flow"] = clampf(_flow(seat) + x, 0.0, 1.0)

## Every skill-slip funnels here: flow drops, and a slip under EN GARDE counts toward its break.
func _slip(s: CombatState, seat: Seat) -> void:
	seat.vars["flow"] = maxf(0.0, _flow(seat) - s.config.flow_slip)
	if _engarde_live(s, seat):
		var n := int(seat.vars.get("engarde_slips", 0)) + 1
		seat.vars["engarde_slips"] = n
		if n >= cfg.engarde_break_slips:
			seat.vars["engarde_until"] = s.tick           # two slips break the challenge
			CombatCore._emit(s, {"t": "duel_engarde_break", "player": seat.is_player, "seat": seat})

func _combo(seat: Seat) -> int:
	return int(seat.vars.get("combo", 0))

func _bank(seat: Seat, n: int) -> void:
	seat.vars["combo"] = mini(cfg.combo_max, _combo(seat) + n)

func _engarde_live(s: CombatState, seat: Seat) -> bool:
	return s.tick < int(seat.vars.get("engarde_until", 0))

# --- per-tick upkeep: wind recharge, flow decay, answer expiry ------------------
func upkeep(s: CombatState, seat: Seat) -> void:
	if not seat.vars.has("flow"):
		seat.vars["flow"] = cfg.flow_start                # first tick: the pull opens on the tank
	seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + cfg.wind_regen * s.dt)
	seat.vars["flow"] = maxf(0.0, _flow(seat) - s.config.flow_decay * s.dt)
	if String(seat.vars.get("ans_kind", "")) != "" \
			and s.tick - int(seat.vars.get("ans_tick", -100000)) > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""                        # an unanswered press lapses (wind was the price)

# --- input: the two answer buttons (binds: 1/SPACE/LMB = DODGE · 2/RMB = PARRY) --
func on_defense_press(s: CombatState, seat: Seat) -> void:
	# FLURRY MODE seals the parry button — the press is ignored (no cost, no lockout), the
	# channel yells; mid-weave a fumble lockout would be run-ending harshness for a mis-key.
	if CombatCore.stream_flurry_active(s, seat):
		CombatCore._emit(s, {"t": "duel_parry_sealed", "player": seat.is_player, "seat": seat})
		return
	_press(s, seat, "parry", cfg.parry_cost, cfg.parry_recover)

func on_dodge_press(s: CombatState, seat: Seat) -> void:
	# FLURRY MODE: wind-free, fast-clock presses — pure execution.
	if CombatCore.stream_flurry_active(s, seat):
		_press(s, seat, "dodge", 0.0, cfg.flurry_recover)
		return
	_press(s, seat, "dodge", cfg.dodge_cost, cfg.dodge_recover)

## The press: pay wind/recovery, then CLAIM instantly (THE PRESS §0 pass 2 — judged at the
## press, symmetric around the bar's gate-touch, verdict fires NOW). If no stream bar is in
## claim range, the press stays open as a telegraph answer (busters/globals keep the
## forgiving open-window model); with neither, it lapses (wind was the price).
func _press(s: CombatState, seat: Seat, kind: String, cost: float, recover: float) -> void:
	if s.tick < int(seat.vars.get("fumble_until", 0)):
		return
	var ready_key := kind + "_ready"
	if s.tick < int(seat.vars.get(ready_key, 0)):
		return
	if _wind(seat) < cost:
		seat.vars["fumble_until"] = s.tick + _tt(s, cfg.fumble_recover)
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "fumble")
		CombatCore._emit(s, {"t": "duel_fumble", "player": seat.is_player, "seat": seat})
		return
	seat.vars["wind"] = _wind(seat) - cost
	seat.vars[ready_key] = s.tick + _tt(s, recover)
	CombatCore._emit(s, {"t": ("duel_parry" if kind == "parry" else "duel_dodge"),
		"player": seat.is_player, "seat": seat})
	if _claim(s, seat, kind):
		seat.vars["ans_kind"] = ""                        # the press was consumed by its bar
		return
	# no stream bar in claim range — leave the answer open for the telegraph path
	seat.vars["ans_kind"] = kind
	seat.vars["ans_tick"] = s.tick

## THE PRESS (§0 pass 2): find the nearest unanswered, claimable bar within ±answer_claim of
## NOW (late side bounded by the resolve slack) and judge the press against it INSTANTLY.
## Returns true if a bar (real or fake) consumed the press. Winner ordering = DEC-14 verbatim
## (nearest |impact−now| → earliest impact → lowest id — the rule _press_claims enforces);
## only bars aimed at THIS seat can claim (v3 peel model: an unseen bar never eats a press).
func _claim(s: CombatState, seat: Seat, kind: String) -> bool:
	var my_i := s.seats.find(seat)
	var claim := _tt(s, cfg.answer_claim)
	var late := CombatCore.to_ticks(s.config.stream_resolve_slack, s.config.fixed_hz)
	var best: Dictionary = {}
	var best_d := 1 << 30
	var best_imp := 1 << 30
	var best_id := 1 << 30
	for b_v in s.boss.stream:
		var b: Dictionary = b_v
		if int(b["victim_i"]) != my_i:
			continue
		var bk := String(b["kind"])
		if bk == "eat":
			continue                                      # unavoidable — never eats a press
		if bk == "flurry" and kind == "parry":
			continue                                      # the weave is dodge-only
		var id := int(b["id"])
		if s.boss.stream_answers.has(id):
			continue                                      # one press answers one bar
		var delta := s.tick - int(b["impact_tick"])       # + = late of the gate
		if delta > late or -delta > claim:
			continue
		var imp := int(b["impact_tick"])
		var d := absi(delta)
		if d < best_d or (d == best_d and imp < best_imp) \
				or (d == best_d and imp == best_imp and id < best_id):
			best_d = d
			best_imp = imp
			best_id = id
			best = b
	if best.is_empty():
		return false
	var off_ms := (s.tick - best_imp) * 33                # signed: − = early, + = late
	var bk := String(best["kind"])
	if bk == "feint":
		# the press took the bait — judged NOW (the purple was the tell)
		s.boss.stream_answers[best_id] = {"kind": kind, "grade": StrikeRes.Grade.BAITED}
		seat.vars["fumble_until"] = s.tick + _tt(s, cfg.fumble_recover)
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "baited")
		CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
			"kind": kind, "grade": StrikeRes.Grade.BAITED, "size": AbilityRes.Size.LIGHT,
			"off_ms": off_ms, "id": best_id})
		return true
	var size := CombatCore._stream_size(bk)
	var grade := StrikeRes.Grade.MISS
	if kind == "parry":
		grade = StrikeRes.Grade.BULLSEYE if best_d <= _tt(s, cfg.parry_land) else StrikeRes.Grade.MISS
	else:
		var p := float(best_d) / maxf(1.0, float(claim))  # 0 at the gate line … 1 at the edge
		if p <= cfg.grade_bull_frac:
			grade = StrikeRes.Grade.BULLSEYE
		elif p <= cfg.grade_perfect_frac:
			grade = StrikeRes.Grade.PERFECT
		elif p <= cfg.grade_good_frac:
			grade = StrikeRes.Grade.GOOD
		else:
			grade = StrikeRes.Grade.GRAZE
		if size >= AbilityRes.Size.HEAVY and grade != StrikeRes.Grade.BULLSEYE:
			grade = StrikeRes.Grade.MISS                  # DEC-15: heavy/buster = bullseye-dodge only
	s.boss.stream_answers[best_id] = {"kind": kind, "grade": grade}
	# the payoffs land NOW — instant feedback is the whole point
	if grade == StrikeRes.Grade.MISS:
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "miss")
	else:
		_add_flow(s, seat, _flow_gain(s, grade))
		CombatCore._bump_diag(s, seat, "land" if (kind == "parry") else StrikeRes.grade_name(grade))
		if kind == "parry":
			_counter(s, seat, size)
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": ("weave" if bk == "flurry" else kind), "grade": grade, "size": size,
		"off_ms": off_ms, "id": best_id})
	return true

# --- the mitigation funnel. STREAM bars were judged AT THE PRESS (stream_answers, §0
#     pass 2) — settle just applies the stored grade. Telegraph busters/globals keep the
#     open-window model below. ---
func modify_incoming(s: CombatState, seat: Seat, dmg: float, source: StringName, size: int) -> float:
	if source == &"enrage" or source == &"debuff":
		return dmg
	if source == &"eat":
		return dmg                                        # EAT takes no press (legality) — whole, never consumes one
	if source == &"rhythm" or source == &"flurry":
		return _engarde_wall(s, seat, dmg * (1.0 - _stream_settle(s, seat, source, size)))
	var kind := String(seat.vars.get("ans_kind", ""))
	if kind == "":
		return _unanswered(s, seat, dmg, size)
	var age := s.tick - int(seat.vars.get("ans_tick", -100000))
	if age < 0 or age > _tt(s, cfg.answer_active):
		seat.vars["ans_kind"] = ""
		return _engarde_wall(s, seat, dmg)
	seat.vars["ans_kind"] = ""                            # one press answers one bar
	# WHAT is this bar? (the v3 matrix) — only telegraph damage reaches here now: aimed at ME
	# with no beats = a BUSTER on the cast channel (parry rules, like a heavy); an aoe beat
	# = a GLOBAL (dodge-only for every seat, never parried, no size leak).
	var is_global := not (s.telegraph != null \
		and s.telegraph.ability.strikes.is_empty() and s.telegraph.target == seat)
	# DEC-15 LEGALITY MATRIX — one explicit gate before grading; an illegal press leaks whole.
	var grade := _dodge_grade(s, age) if kind == "dodge" else StrikeRes.Grade.BULLSEYE
	if not _answer_legal(kind, size, is_global, grade):
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "miss")
		CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
			"kind": kind, "grade": StrikeRes.Grade.MISS, "size": size})
		return _engarde_wall(s, seat, dmg)
	# legal → grade + mitigate:
	if is_global:                                         # room-wide dodge: graded, NO size leak
		_add_flow(s, seat, _flow_gain(s, grade))
		CombatCore._bump_diag(s, seat, StrikeRes.grade_name(grade))
		CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
			"kind": "dodge", "grade": grade, "size": size})
		return _engarde_wall(s, seat, dmg * (1.0 - clampf(_dodge_mit(grade), 0.0, cfg.mit_cap)))
	if kind == "parry":
		return _engarde_wall(s, seat, dmg * (1.0 - _parry_result(s, seat, age, size)))
	return _engarde_wall(s, seat, dmg * (1.0 - _dodge_result(s, seat, age, size)))

## The unanswered path: no valid press covered this bar — letting a big one through costs aggro.
func _unanswered(s: CombatState, seat: Seat, dmg: float, size: int) -> float:
	if size >= AbilityRes.Size.HEAVY:
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "miss")
	return _engarde_wall(s, seat, dmg)

## DEC-14 claim tie-break. Among every bar aimed at this seat within ±answer_claim of now, the
## press answers the nearest |impact−now|, then the earliest impact, then the lowest id. Returns
## whether `bar` (the one being resolved/judged, already popped from the stream) is that winner:
## a strictly-better claim target still pending in the stream means `bar` is NOT it. EAT bars are
## excluded (they take no press). Deterministic, rng-free; `bar` self-comparison never rejects.
func _press_claims(s: CombatState, seat: Seat, bar: Dictionary) -> bool:
	var my_i := s.seats.find(seat)
	var claim := _tt(s, cfg.answer_claim)
	var w_dist := absi(int(bar["impact_tick"]) - s.tick)
	var w_imp := int(bar["impact_tick"])
	var w_id := int(bar["id"])
	for b_v in s.boss.stream:
		var b: Dictionary = b_v
		if int(b["victim_i"]) != my_i or String(b["kind"]) == "eat":
			continue
		if s.boss.stream_answers.has(int(b["id"])):
			continue                                      # already claimed — can't compete (§0 pass 2)
		var imp := int(b["impact_tick"])
		var d := absi(imp - s.tick)
		if d > claim:
			continue
		var bid := int(b["id"])
		if d < w_dist or (d == w_dist and imp < w_imp) \
				or (d == w_dist and imp == w_imp and bid < w_id):
			return false                                  # a better claim target is still pending
	return true

## DEC-15 legality: reject an illegal press before grading. GLOBAL = dodge only (parry never);
## AUTO = parry or dodge any grade; HEAVY/BUSTER = parry, or dodge at BULLSEYE only. (EAT never
## reaches here — source==eat returns above; FEINT is judged in on_stream_bar.)
func _answer_legal(kind: String, size: int, is_global: bool, grade: int) -> bool:
	if is_global:
		return kind == "dodge"
	if kind == "parry":
		return true
	if size >= AbilityRes.Size.HEAVY:
		return grade == StrikeRes.Grade.BULLSEYE
	return true

## PARRY — binary: the land or the miss. A land on ANY size aimed at you; the top payout.
func _parry_result(s: CombatState, seat: Seat, age: int, size: int) -> float:
	if age <= _tt(s, cfg.parry_window):
		_add_flow(s, seat, s.config.flow_gain_perfect)
		CombatCore._bump_diag(s, seat, "land")
		CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
			"kind": "parry", "grade": StrikeRes.Grade.BULLSEYE, "size": size})
		_counter(s, seat, size)
		# DEC-6: a LANDED PARRY is the one explicit ABOVE-cap payout — mit_cap is the DODGE/partial
		# ceiling, not the parry's. It still leaks a sliver (mit_parry_land < 1.0; never full-negate).
		return minf(cfg.mit_parry_land, 0.99)
	_slip(s, seat)
	CombatCore._bump_diag(s, seat, "miss")
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": "parry", "grade": StrikeRes.Grade.MISS, "size": size})
	return clampf(cfg.mit_parry_miss, 0.0, cfg.mit_cap)

## DODGE — graded on the one ladder. AUTO: any grade. HEAVY/BUSTER: reaches here only at
## BULLSEYE (the legality matrix already rejected any lesser dodge on a big bar). The power
## leak still applies, so parry stays the preferred answer on the big ones.
func _dodge_result(s: CombatState, seat: Seat, age: int, size: int) -> float:
	var grade := _dodge_grade(s, age)
	var mit := _dodge_mit(grade)
	if size > AbilityRes.Size.LIGHT:
		mit -= cfg.dodge_leak_per_size * float(size - AbilityRes.Size.LIGHT)
	_add_flow(s, seat, _flow_gain(s, grade))
	CombatCore._bump_diag(s, seat, StrikeRes.grade_name(grade))
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": "dodge", "grade": grade, "size": size})
	return clampf(mit, 0.0, cfg.mit_cap)

func _dodge_grade(s: CombatState, age: int) -> int:
	if age <= _tt(s, cfg.dodge_bullseye):
		return StrikeRes.Grade.BULLSEYE
	if age <= _tt(s, cfg.dodge_perfect):
		return StrikeRes.Grade.PERFECT
	if age <= _tt(s, cfg.dodge_good):
		return StrikeRes.Grade.GOOD
	return StrikeRes.Grade.GRAZE

func _dodge_mit(grade: int) -> float:
	match grade:
		StrikeRes.Grade.BULLSEYE: return cfg.mit_dodge_bullseye
		StrikeRes.Grade.PERFECT: return cfg.mit_dodge_perfect
		StrikeRes.Grade.GOOD: return cfg.mit_dodge_good
		_: return cfg.mit_dodge_graze

func _flow_gain(s: CombatState, grade: int) -> float:
	match grade:
		StrikeRes.Grade.BULLSEYE, StrikeRes.Grade.PERFECT: return s.config.flow_gain_perfect
		StrikeRes.Grade.GOOD: return s.config.flow_gain_good
		_: return s.config.flow_gain_graze

## Settle a resolving STREAM bar against its press-time answer (payoffs/verdicts already
## fired at the press — this only converts the stored grade into mitigation + handles the
## unanswered-bar bookkeeping and the weave group). Returns the mit FRACTION.
func _stream_settle(s: CombatState, seat: Seat, source: StringName, size: int) -> float:
	var bar: Dictionary = s.boss.stream_resolving
	if source == &"flurry":
		return _flurry_settle(s, seat, bar)
	var akind := String(bar.get("ans_kind", ""))
	var grade := int(bar.get("ans_grade", -1))
	if akind == "":
		if size >= AbilityRes.Size.HEAVY:                 # letting a big one through costs aggro
			_slip(s, seat)
			CombatCore._bump_diag(s, seat, "miss")
		return 0.0
	if grade == StrikeRes.Grade.MISS:
		return clampf(cfg.mit_parry_miss if akind == "parry" else 0.0, 0.0, cfg.mit_cap)
	if akind == "parry":
		# DEC-6: a LANDED PARRY is the one explicit ABOVE-cap payout (never full-negate)
		return minf(cfg.mit_parry_land, 0.99)
	var mit := _dodge_mit(grade)
	if size > AbilityRes.Size.LIGHT:
		mit -= cfg.dodge_leak_per_size * float(size - AbilityRes.Size.LIGHT)
	return clampf(mit, 0.0, cfg.mit_cap)

## The weave group: an unanswered/missed beat BLOWS it (the rest land whole); the last
## beat of an unblown group pays the free RIPOSTE. Flow for clean beats was paid at press.
func _flurry_settle(s: CombatState, seat: Seat, bar: Dictionary) -> float:
	var group := int(bar.get("flurry_group", -1))
	var blown := int(seat.vars.get("flurry_blown", -1)) == group
	var akind := String(bar.get("ans_kind", ""))
	var grade := int(bar.get("ans_grade", -1))
	var clean := akind != "" and grade != StrikeRes.Grade.MISS and grade != StrikeRes.Grade.BAITED
	if not clean or blown:
		if not blown:                                     # the first miss blows the weave
			seat.vars["flurry_blown"] = group
			_slip(s, seat)
			CombatCore._bump_diag(s, seat, "miss")
			CombatCore._emit(s, {"t": "duel_weave_blown", "player": seat.is_player, "seat": seat})
		return 0.0                                        # eat it all
	if int(bar.get("flurry_i", 0)) == int(bar.get("flurry_n", 1)) - 1:
		CombatCore.damage_boss(s, seat, cfg.counter_dmg * cfg.flurry_riposte_mult, &"riposte")
		_bank(seat, 1)
		_add_flow(s, seat, s.config.flow_gain_perfect)
		CombatCore._bump_diag(s, seat, "riposte")
		CombatCore._emit(s, {"t": "duel_riposte", "player": seat.is_player, "seat": seat})
	return _dodge_mit(grade)

## Unclaimed-FEINT + EAT bookkeeping (the engine routes non-damage bars here). BAITED now
## fires at the press (_claim) — a feint reaching this hook was HELD through = the READ.
## EAT here is the authored tank-specific channel comet (DEC-10) — a distinct event from the
## raid-wide BRACE that rides the cast bar for every seat; the two never share a path.
func on_stream_bar(s: CombatState, seat: Seat, bar: Dictionary) -> void:
	match String(bar.get("kind", "")):
		"feint":
			_add_flow(s, seat, s.config.flow_gain_graze)
			CombatCore._bump_diag(s, seat, "read")
			CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
				"kind": "hold", "grade": StrikeRes.Grade.READ, "size": AbilityRes.Size.LIGHT})
		"eat":
			CombatCore._bump_diag(s, seat, "eaten")
			CombatCore._emit(s, {"t": "duel_eat", "player": seat.is_player, "seat": seat})

## EN GARDE's wall: while the challenge holds, leaks + slivers are HALVED. Base = no-op.
func _engarde_wall(s: CombatState, seat: Seat, leaked: float) -> float:
	if _engarde_live(s, seat):
		return leaked * 0.5
	return leaked

## The counter hit-back: a LANDED PARRY only. Damage + bank a ◆ + the flow SPIKE (the valve).
func _counter(s: CombatState, seat: Seat, _size: int) -> void:
	CombatCore.damage_boss(s, seat, cfg.counter_dmg, &"counter")
	_bank(seat, 1)
	_add_flow(s, seat, s.config.flow_spike)
	CombatCore._bump_diag(s, seat, "counter")
	CombatCore._emit(s, {"t": "duel_counter", "player": seat.is_player, "seat": seat})

# --- abilities: ⚡ DUMP · ⏱ EN GARDE -------------------------------------------
func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match String(id):
		"dump":
			return _dump(s, seat)
		"engarde":
			return _engarde(s, seat)
	return false

func _dump(s: CombatState, seat: Seat) -> bool:
	if s.tick < seat.gcd_until_tick:
		return false
	var c := _combo(seat)
	if c <= 0:
		return false
	CombatCore.damage_boss(s, seat, cfg.dump_per_combo * float(c), &"dump")
	CombatCore._bump_diag(s, seat, "dump")
	CombatCore._emit(s, {"t": "duel_dump", "player": seat.is_player, "seat": seat,
		"amt": int(cfg.dump_per_combo * float(c))})
	seat.vars["combo"] = 0
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	return true

func _engarde(s: CombatState, seat: Seat) -> bool:
	if s.tick < int(seat.cooldowns.get("engarde", 0)):
		return false
	seat.vars["engarde_until"] = s.tick + _tt(s, cfg.engarde_dur)
	seat.vars["engarde_slips"] = 0
	seat.cooldowns["engarde"] = s.tick + _tt(s, cfg.engarde_cd)
	CombatCore._emit(s, {"t": "duel_engarde", "player": seat.is_player, "seat": seat})
	return true

# --- observation for policies / HUD --------------------------------------------
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
		"engarde_ready": s.tick >= int(seat.cooldowns.get("engarde", 0)),
		"engarde_live": _engarde_live(s, seat),
		"flurry": CombatCore.stream_flurry_active(s, seat),
		# the gate's grading geometry (THE CHANNEL draws exactly these — one source of truth):
		# claim fractions of ±answer_claim, SYMMETRIC around gate-touch (§0 THE PRESS)
		"win_bullseye": cfg.answer_claim * cfg.grade_bull_frac,
		"win_perfect": cfg.answer_claim * cfg.grade_perfect_frac,
		"win_good": cfg.answer_claim * cfg.grade_good_frac,
		"win_graze": cfg.answer_claim,
		"parry_window": cfg.parry_land,
	}

func recap_spec(_s: CombatState, seat: Seat) -> Array:
	var d: Dictionary = seat.diag
	var rows: Array = []
	var counters := int(d.get("counter", 0))
	if counters > 0:
		rows.append({"label": "Counters", "value": str(counters), "hint": "landed parries (hit back)"})
	var bulls := int(d.get("bullseye", 0)) + int(d.get("land", 0))
	var total := bulls + int(d.get("perfect", 0)) + int(d.get("good", 0)) \
		+ int(d.get("graze", 0)) + int(d.get("miss", 0))
	if total > 0:
		rows.append({"label": "Sharp", "value": "%d%%" % int(round(100.0 * float(bulls) / float(total))),
			"hint": "answers graded bullseye (or landed)"})
	var baited := int(d.get("baited", 0))
	if baited > 0:
		rows.append({"label": "Baited", "value": str(baited), "hint": "pressed a purple fake"})
	var reads := int(d.get("read", 0))
	if reads > 0:
		rows.append({"label": "Reads", "value": str(reads), "hint": "held through a fake"})
	var fum := int(d.get("fumble", 0))
	if fum > 0:
		rows.append({"label": "Fumbles", "value": str(fum), "hint": "dry / mis-pressed"})
	return rows
