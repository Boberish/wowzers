## DuelistKit — THE DUELIST, the dodge tank, rebuilt from the base (TANK-PLAN §0 THE CHANNEL
## CONTRACT v3, tank-v2 2026-07-11). A pure, deterministic ClassKit: all state in seat.vars,
## zero RNG, integer-tick truth.
##
## THE MINIGAME (v3 + §0 THE PRESS pass 2, restored). The engine's committed STREAM is this
## seat's incoming bar timeline; a press CLAIMS the nearest bar within ±answer_claim and is
## judged INSTANTLY, symmetric around gate-touch (verdict + payoffs fire AT the press — the
## Twinfang model, Bill: "the twinfang is super good, do that"); resolve applies the stored
## grade. Telegraph busters/globals keep the open-window model (big slow reads):
##   PARRY (main)      — GRADED GOOD or BULLSEYE (SHAPE LAW 2026-07-13): land inside the perfect
##                       zone (parry_grade_frac) = GOOD, dead-centre (grade_bull_frac) = BULLSEYE,
##                       looser = the miss (.18 token mit, wind gone). Either land = mit .95 +
##                       COUNTER + ◆ + flow spike. 3.5 wind. Answers ◇ AUTO/light-beat + ⯃
##                       HEAVY/BUSTER aimed at YOU — never a ⬡ GLOBAL/FLURRY.
##   DODGE (secondary) — GRADED on the one game-wide ladder GRAZE<GOOD<PERFECT<BULLSEYE
##                       (|press−impact|/answer_claim on the grade_*_frac ladder). 1 wind.
##                       Answers ◇ AUTO/light-beat + ⬡ GLOBAL at any grade; ⯃ HEAVY/BUSTER are
##                       PARRY-ONLY (dodge illegal — the bullseye-dodge escape is GONE). No hit-back.
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

# --- per-tick upkeep: wind recharge, flow decay, stale-claim expiry --------------
func upkeep(s: CombatState, seat: Seat) -> void:
	if not seat.vars.has("flow"):
		seat.vars["flow"] = cfg.flow_start                # first tick: the pull opens on the tank
	seat.vars["wind"] = minf(cfg.wind_max, _wind(seat) + cfg.wind_regen * s.dt)
	seat.vars["flow"] = maxf(0.0, _flow(seat) - s.config.flow_decay * s.dt)
	if s.telegraph == null and seat.vars.has("tg_claims") \
			and not (seat.vars["tg_claims"] as Dictionary).is_empty():
		seat.vars["tg_claims"] = {}                       # the swing is gone — stale claims die with it

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
		return                                            # the press was consumed by its comet
	# nothing in claim range — a whiff (the wind was the price, same as any dry press)

## PARRY grades to GOOD or BULLSEYE only (SHAPE LAW 2026-07-13): inside grade_bull_frac of the
## claim window = BULLSEYE, inside parry_grade_frac (the perfect boundary) = a solid GOOD, looser
## = a MISS (wind gone). Ties parry to the one dodge ladder — retune the fracs and it tracks.
func _parry_grade(d: int, claim: int) -> int:
	var p := float(d) / maxf(1.0, float(claim))
	if p <= cfg.grade_bull_frac:
		return StrikeRes.Grade.BULLSEYE
	if p <= cfg.parry_grade_frac:
		return StrikeRes.Grade.GOOD
	return StrikeRes.Grade.MISS

## THE PRESS (§0 pass 2 + ONE CLAIM, Bill 2026-07-12): find the nearest unanswered, claimable
## COMET within ±answer_claim of NOW (late side bounded by the resolve slack) and judge the
## press against it INSTANTLY — stream bars AND the live telegraph's events (GLOBALS / beats /
## BUSTERS) compete in the SAME decision, so the press always goes to the comet the eye is on
## (kills the press-stealing overlap bug: a melee note no longer eats the dodge you aimed at a
## global). Winner ordering = DEC-14 verbatim (nearest |impact−now| → earliest impact → lowest
## id — telegraph ids are negative, so an exact tie goes to the bigger read). PEELED bars claim
## too (§0 pass 2): the tank answers EVERY bar — the damage stays the victim's.
func _claim(s: CombatState, seat: Seat, kind: String) -> bool:
	var claim := _tt(s, cfg.answer_claim)
	var late := CombatCore.to_ticks(s.config.stream_resolve_slack, s.config.fixed_hz)
	var best: Dictionary = {}
	var best_d := 1 << 30
	var best_imp := 1 << 30
	var best_id := 1 << 30
	for b_v in s.boss.stream:
		var b: Dictionary = b_v
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
	# --- the telegraph candidates (same window, same tie-break; ids mirror the view's) ---
	var best_tg: Dictionary = {}
	var tg := s.telegraph
	if tg != null and not tg.ability.feint:
		var tgc: Dictionary = seat.vars.get("tg_claims", {})
		var strikes: Array = tg.ability.strikes
		if strikes.is_empty():
			# a BUSTER: DEFENSIBLE swing aimed at me, no beats — lands at the wind-up's end
			if tg.ability.response == AbilityRes.Response.DEFENSIBLE and tg.target == seat:
				var tid := -(1000 + tg.start_tick * 8)
				var timp := tg.start_tick + tg.dur_ticks
				var tdelta := s.tick - timp
				if not tgc.has(tid) and not (tdelta > late or -tdelta > claim):
					var td := absi(tdelta)
					if td < best_d or (td == best_d and timp < best_imp) \
							or (td == best_d and timp == best_imp and tid < best_id):
						best_d = td
						best_imp = timp
						best_id = tid
						best_tg = {"id": tid, "imp": timp, "aoe": false, "size": int(tg.ability.size)}
		else:
			for i in range(tg.next_strike, strikes.size()):
				var st: StrikeRes = strikes[i]
				if st.feint or st.guard == StrikeRes.Guard.UNANSWERABLE:
					continue                              # fakes bait nothing here; dooms take no press
				if not (st.aoe or CombatCore._beat_victim(tg, i) == seat):
					continue                              # someone else's bolt — their dodge, not mine
				var tid2 := -(1000 + tg.start_tick * 8 + 1 + i)
				if tgc.has(tid2):
					continue
				var timp2 := tg.start_tick + CombatCore.to_ticks(st.at, s.config.fixed_hz)
				var tdelta2 := s.tick - timp2
				if tdelta2 > late or -tdelta2 > claim:
					continue
				var td2 := absi(tdelta2)
				if td2 < best_d or (td2 == best_d and timp2 < best_imp) \
						or (td2 == best_d and timp2 == best_imp and tid2 < best_id):
					best_d = td2
					best_imp = timp2
					best_id = tid2
					best_tg = {"id": tid2, "imp": timp2, "aoe": st.aoe, "size": int(st.size)}
	if not best_tg.is_empty():
		return _claim_tg(s, seat, kind, best_tg, s.tick - int(best_tg["imp"]))
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
		grade = _parry_grade(best_d, claim)               # SHAPE LAW: GOOD or BULLSEYE, else miss
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
		if size >= AbilityRes.Size.HEAVY:
			grade = StrikeRes.Grade.MISS                  # SHAPE LAW: ⯃ octagon = PARRY ONLY (dodge illegal)
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

## ONE CLAIM: a telegraph event (GLOBAL / beat / BUSTER) won the press. Judged NOW on the one
## game-wide ladder — symmetric |press − impact| / answer_claim, exactly like a stream bar
## (same comet shape ⇒ same timing, the grading-coherence law). Payoffs fire at the press;
## the mitigation is STORED on the seat and applied when the strike lands (modify_incoming).
## Legality (SHAPE LAW 2026-07-13): ⬡ GLOBAL (aoe) = dodge only, any grade, no size leak ·
## ◇ light personal beat = dodge (graded) or parry (good/bullseye) · ⯃ HEAVY beat / BUSTER =
## PARRY ONLY (dodge illegal — no bullseye-dodge escape).
func _claim_tg(s: CombatState, seat: Seat, kind: String, cand: Dictionary, off_ticks: int) -> bool:
	var aoe := bool(cand["aoe"])
	var size := int(cand["size"])
	var d := absi(off_ticks)
	var claim := _tt(s, cfg.answer_claim)
	var grade := StrikeRes.Grade.MISS
	if kind == "parry":
		# a room-wide blast is a ⬡ hexagon (dodge-only); a personal hit grades GOOD or BULLSEYE
		if not aoe:
			grade = _parry_grade(d, claim)
	else:
		var p := float(d) / maxf(1.0, float(claim))       # 0 at the gate line … 1 at the edge
		if p <= cfg.grade_bull_frac:
			grade = StrikeRes.Grade.BULLSEYE
		elif p <= cfg.grade_perfect_frac:
			grade = StrikeRes.Grade.PERFECT
		elif p <= cfg.grade_good_frac:
			grade = StrikeRes.Grade.GOOD
		else:
			grade = StrikeRes.Grade.GRAZE
		if not aoe and size >= AbilityRes.Size.HEAVY:
			grade = StrikeRes.Grade.MISS                  # SHAPE LAW: ⯃ octagon = PARRY ONLY (dodge illegal)
	# the payoffs land NOW (instant feedback is the whole point); the mit waits for the hit
	var mit := 0.0
	if grade == StrikeRes.Grade.MISS:
		if kind == "parry" and not aoe:
			mit = clampf(cfg.mit_parry_miss, 0.0, cfg.mit_cap)   # the pressed-but-out token cut
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "miss")
	else:
		if kind == "parry":
			mit = minf(cfg.mit_parry_land, 0.99)          # DEC-6: the one above-cap payout
			_counter(s, seat, size)
			CombatCore._bump_diag(s, seat, "land")
		else:
			mit = _dodge_mit(grade)
			if not aoe and size > AbilityRes.Size.LIGHT:
				mit -= cfg.dodge_leak_per_size * float(size - AbilityRes.Size.LIGHT)
			mit = clampf(mit, 0.0, cfg.mit_cap)           # globals: full ladder, NO size leak
			CombatCore._bump_diag(s, seat, StrikeRes.grade_name(grade))
		_add_flow(s, seat, _flow_gain(s, grade))
	var tgc: Dictionary = seat.vars.get("tg_claims", {})
	tgc[int(cand["id"])] = {"mit": mit}
	seat.vars["tg_claims"] = tgc
	CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
		"kind": kind, "grade": grade, "size": size,
		"off_ms": off_ticks * 33, "id": int(cand["id"])})
	return true

# --- the mitigation funnel. EVERY comet was judged AT THE PRESS (ONE CLAIM, 2026-07-12):
#     stream bars via stream_answers, telegraph events via tg_claims — resolution just
#     applies the stored result. The old open-window (ans_kind/answer_active) is RETIRED:
#     a press either claims a comet or whiffs; nothing is graded at impact anymore. ---
func modify_incoming(s: CombatState, seat: Seat, dmg: float, source: StringName, size: int) -> float:
	if source == &"enrage" or source == &"debuff":
		return dmg
	if source == &"eat":
		return dmg                                        # EAT takes no press (legality) — whole, never consumes one
	if source == &"rhythm" or source == &"flurry":
		return _engarde_wall(s, seat, dmg * (1.0 - _stream_settle(s, seat, source, size)))
	# TELEGRAPH damage (a GLOBAL beat / my beat / a strikeless BUSTER) — derive the resolving
	# event's claim key (same synthetic id scheme as _claim + the view) and apply the stored mit.
	var tgc: Dictionary = seat.vars.get("tg_claims", {})
	if s.telegraph != null and not tgc.is_empty():
		var key := -(1000 + s.telegraph.start_tick * 8)   # the strikeless buster's key…
		if not s.telegraph.ability.strikes.is_empty():
			key = -(1000 + s.telegraph.start_tick * 8 + 1 + s.telegraph.next_strike)   # …or the resolving beat's
		if tgc.has(key):
			var mit := float((tgc[key] as Dictionary).get("mit", 0.0))
			tgc.erase(key)
			return _engarde_wall(s, seat, dmg * (1.0 - mit))
	return _unanswered(s, seat, dmg, size)

## The unanswered path: no valid press covered this bar — letting a big one through costs aggro.
func _unanswered(s: CombatState, seat: Seat, dmg: float, size: int) -> float:
	if size >= AbilityRes.Size.HEAVY:
		_slip(s, seat)
		CombatCore._bump_diag(s, seat, "miss")
	return _engarde_wall(s, seat, dmg)

## DEC-14 claim tie-break. Among every unanswered bar within ±answer_claim of now (peeled ones
## included — §0 pass 2), the press answers the nearest |impact−now|, then the earliest impact,
## then the lowest id. Returns whether `bar` (the one being resolved/judged, already popped from
## the stream) is that winner: a strictly-better claim target still pending in the stream means
## `bar` is NOT it. EAT bars are excluded (they take no press). Deterministic, rng-free;
## `bar` self-comparison never rejects.
func _press_claims(s: CombatState, _seat: Seat, bar: Dictionary) -> bool:
	var claim := _tt(s, cfg.answer_claim)
	var w_dist := absi(int(bar["impact_tick"]) - s.tick)
	var w_imp := int(bar["impact_tick"])
	var w_id := int(bar["id"])
	for b_v in s.boss.stream:
		var b: Dictionary = b_v
		if String(b["kind"]) == "eat":
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

# _answer_legal / _parry_result / _dodge_result / _dodge_grade — DELETED with the open
# window (ONE CLAIM, 2026-07-12): legality + grading live inline in _claim/_claim_tg now,
# on the one press-time ladder. The age-based knobs (answer_active · parry_window ·
# dodge_bullseye/perfect/good) are retired with them; the claim fracs are the law.

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
		# the view's MISS AFTERLIFE signal (Bill 2026-07-12): an unclaimed bar crossed the
		# line — it turns red and keeps flowing. Local event, never networked/checksummed.
		CombatCore._emit(s, {"t": "duel_bar_missed", "player": seat.is_player, "seat": seat,
			"id": int(bar.get("id", -1)), "size": size})
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

## Non-funnel stream bookkeeping (the engine routes here): an UNCLAIMED feint = the READ
## (BAITED fires at the press now) · an EAT = the brace · a PEELED damage bar (§0 pass 2,
## restored) = settle the tank's weave/miss state — the victim eats the damage; the tank's
## press-time payoffs already fired (the comeback). EAT here is the authored tank-specific
## channel comet (DEC-10) — distinct from the raid-wide BRACE on the cast bar.
func on_stream_bar(s: CombatState, seat: Seat, bar: Dictionary) -> void:
	match String(bar.get("kind", "")):
		"feint":
			_add_flow(s, seat, s.config.flow_gain_graze)
			CombatCore._bump_diag(s, seat, "read")
			CombatCore._emit(s, {"t": "duel_answer", "player": seat.is_player, "seat": seat,
				"kind": "hold", "grade": StrikeRes.Grade.READ, "size": AbilityRes.Size.LIGHT,
				"id": int(bar.get("id", -1))})   # the view anchors the READ on the fake itself
		"eat":
			CombatCore._bump_diag(s, seat, "eaten")
			CombatCore._emit(s, {"t": "duel_eat", "player": seat.is_player, "seat": seat})
		"flurry":
			var prev := s.boss.stream_resolving
			s.boss.stream_resolving = bar
			_flurry_settle(s, seat, bar)                  # group state only; damage is the victim's
			s.boss.stream_resolving = prev
		_:
			# peeled auto/heavy/buster: an unanswered big one still costs aggro discipline
			if String(bar.get("ans_kind", "")) == "":
				if CombatCore._stream_size(String(bar.get("kind", ""))) >= AbilityRes.Size.HEAVY:
					_slip(s, seat)
					CombatCore._bump_diag(s, seat, "miss")
				CombatCore._emit(s, {"t": "duel_bar_missed", "player": seat.is_player,
					"seat": seat, "id": int(bar.get("id", -1)),
					"size": CombatCore._stream_size(String(bar.get("kind", "")))})

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

## INTERRUPT-BY-ABILITY (pillar #3): the combo dump carries the tank's kick — spend the combo
## during a boss's interruptible cast and it stops (CombatCore._try_interrupt). The dump always
## deals its combo damage; kicking a live verse is the bonus for timing it into a cast.
func ability_interrupts(id: StringName) -> bool:
	return String(id) == "dump"

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
		"carries_kick": true,   # INTERRUPT-BY-ABILITY (pillar #3): the combo dump kicks — the cast bar reads "interrupt", not "uncontested"
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
