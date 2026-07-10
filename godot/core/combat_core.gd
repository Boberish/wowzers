## CombatCore — the PURE, DETERMINISTIC combat engine. Single source of truth run
## identically by the live client, the authoritative server, and headless sims.
## Purity rules (see CLAUDE.md): no rendering/nodes, no wall-clock (only state.tick),
## no unseeded RNG (only state.rng), no mutable module-level globals.
##
## Class-specific behaviour lives behind ClassKit hooks on each seat, so this file
## stays generic across all four combat classes.
class_name CombatCore
extends RefCounted

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

static func to_ticks(seconds: float, hz: int) -> int:
	return int(round(seconds * float(hz)))

## Win-condition curve for stat-block allies: healthy allies deal more. Aspects
## (Brinkwarden) will override via a hook later, not a special-case.
static func f_hp(frac: float, cfg: TuningConfig) -> float:
	return cfg.f_floor + cfg.f_scale * frac

## Build a fresh, seeded fight state. The caller (content factory) attaches seats.
static func create_state(enc: EncounterRes, cfg: TuningConfig, seed: int) -> CombatState:
	var s := CombatState.new()
	s.config = cfg
	s.encounter = enc
	s.dt = cfg.dt()
	s.rng = DetRng.new(seed)
	s.boss = BossState.new()
	s.boss.hp = float(enc.hp)
	s.boss.hp_max = float(enc.hp)
	var i := 0
	for ab in enc.abilities:
		var stagger := 2.0 + float(i) * 1.5 + s.rng.next_float() * (ab.cd * 0.3)
		s.boss.ability_timer[ab.id] = to_ticks(stagger, cfg.fixed_hz)
		i += 1
	if not enc.melee.is_empty():
		s.boss.melee_timer = to_ticks(float(enc.melee.get("every", 1.5)), cfg.fixed_hz)
	return s

# --------------------------------------------------------------------------
# The tick  (canonical order — see PORT-PLAN.md)
# --------------------------------------------------------------------------

static func update(s: CombatState) -> void:
	if s.over:
		return
	s.tick += 1
	_apply_inputs(s)                       # 1. drain queued player/AI actions for this tick
	for seat in s.seats:                   # 2. class upkeep (momentum decay, buff bookkeeping)
		if seat.kit != null and seat.alive():
			seat.kit.upkeep(s, seat)
	_apply_seat_effects(s)                 # 2b. HoTs heal, DoTs tick, wards expire
	if s.boss.sunder > 0.0:                # 2c. SUNDER bleeds toward 0 (guarded — only the tank feeds it)
		s.boss.sunder = maxf(0.0, s.boss.sunder - s.config.sunder_decay * s.dt)
	if s.boss.debilitate > 0.0:            # DEBILITATE bleeds toward 0 (guarded — only the Alchemist feeds it)
		s.boss.debilitate = maxf(0.0, s.boss.debilitate - s.config.debilitate_decay * s.dt)
	var ph := current_phase(s)             # 3. boss phase
	_boss_think(s, ph)                     # 4. melee + advance/resolve telegraph, else pick next
	_apply_group_damage(s, s.dt)           # 5. stat-block allies chip the boss
	_apply_enrage(s, s.dt)                 # 6. hard-timer ramp
	_check_end(s)                          # 7. win/lose
	if s.over:
		# A fight ending mid-cast can strand seat.casting.target == the seat itself
		# (raid healer self-cast) — a Seat -> Dictionary -> Seat refcount cycle that
		# never frees. Nothing reads cast bars after `over`; not in the checksum.
		for seat in s.seats:
			seat.casting = {}
	# add_hp is 0.0 whenever no add holds the field, so the extra term keeps every
	# pre-add fight's checksum byte-identical while covering add fights against drift.
	s.checksum = (s.checksum * 1000003 + int(s.boss.hp * 100.0) + int(s.boss.add_hp * 100.0) + s.tick) & 0x7FFFFFFFFFFFFFFF

# --------------------------------------------------------------------------
# Player / AI input
# --------------------------------------------------------------------------

static func perform(s: CombatState, seat: Seat, action: Dictionary) -> void:
	match String(action.get("type", "")):
		"defense":
			if seat.kit != null and seat.kit.unified_dodge():
				_unified_dodge(s, seat)          # the ONE dodge (Twinfang/Alchemist/Well)
			elif s.tick >= seat.defense_ready_tick:
				var active := _def_active(s, seat)
				var cd := _def_cd(s, seat)
				seat.dodging_until_tick = s.tick + to_ticks(active, s.config.fixed_hz)
				seat.defense_ready_tick = s.tick + to_ticks(cd, s.config.fixed_hz)
				if seat.kit != null:
					seat.kit.on_defense_press(s, seat)
				_emit(s, {"t": "defend", "player": seat.is_player, "seat": seat})
				# Instant negate: if a defensible swing aimed here is already inside the
				# active window, consume it NOW so the telegraph clears immediately rather
				# than finishing and "landing" after you've already answered it.
				if seat.kit != null and s.telegraph != null \
						and s.telegraph.ability.response == AbilityRes.Response.DEFENSIBLE \
						and s.telegraph.target == seat:
					var rem := (s.telegraph.start_tick + s.telegraph.dur_ticks) - s.tick
					if s.telegraph.ability.feint or rem <= to_ticks(active, s.config.fixed_hz):
						seat.kit.on_negate(s, seat, s.telegraph.ability)
						_emit(s, {"t": "negate", "player": seat.is_player, "seat": seat,
							"size": s.telegraph.ability.size, "feint": s.telegraph.ability.feint})
						s.telegraph = null
		"dodge":
			# M7 universal dodge — every class has it, separate from the class
			# defensive verb (guard/kick untouched). Short recovery between presses;
			# grading against the live string happens in _answer_strike.
			if seat.kit != null and seat.kit.unified_dodge():
				_unified_dodge(s, seat)
			elif s.tick >= seat.dodge_ready_tick:
				seat.dodge_ready_tick = s.tick + to_ticks(s.config.dodge_recovery, s.config.fixed_hz)
				if seat.kit != null:
					seat.kit.on_dodge_press(s, seat)
				_emit(s, {"t": "dodge", "player": seat.is_player, "seat": seat})
				_answer_strike(s, seat)
		"ability":
			if seat.kit != null:
				# on_action returns true only when the ability actually commits (past the
				# GCD + resource gates). Emit a view-layer "ability_fired" then, so the HUD
				# can spawn the cast VFX exactly when a press lands — not when it fizzles.
				if seat.kit.on_action(s, seat, StringName(action.get("id", "")), action.get("target")):
					_emit(s, {"t": "ability_fired", "player": seat.is_player, "seat": seat,
						"id": String(action.get("id", ""))})
		_:
			pass

static func _apply_inputs(s: CombatState) -> void:
	if s.input_queue.is_empty():
		return                              # the common case — no per-tick Array churn
	var remaining: Array = []
	for e in s.input_queue:
		if e["tick"] == s.tick:
			perform(s, e["seat"], e["action"])
		elif e["tick"] > s.tick:
			remaining.append(e)
	s.input_queue = remaining

## The observation a policy sees — exactly what a human reads off the screen.
## Base fields for everyone; the ClassKit merges class-specific fields on top.
static func observe(s: CombatState, seat: Seat) -> Dictionary:
	var tg := {}
	if s.telegraph != null:
		var elapsed := float(s.tick - s.telegraph.start_tick) * s.dt
		var dur := float(s.telegraph.dur_ticks) * s.dt
		tg = {
			"id": s.telegraph.ability.id,
			"danger": s.telegraph.ability.danger,
			"defensible": s.telegraph.ability.response == AbilityRes.Response.DEFENSIBLE,
			"interruptible": s.telegraph.ability.response == AbilityRes.Response.INTERRUPTIBLE,
			"heal": s.telegraph.ability.effect == AbilityRes.Effect.HEAL_BOSS,
			"empower": s.telegraph.ability.effect == AbilityRes.Effect.EMPOWER_BOSS,
			"feint": s.telegraph.ability.feint,
			"size": s.telegraph.ability.size,
			"targets_me": s.telegraph.target == seat,
			"remaining": dur - elapsed,
			"tick": s.telegraph.start_tick,   # stable per-swing id (AI feint-read model)
		}
		if not s.telegraph.ability.strikes.is_empty():
			tg["dur"] = dur
			var beats: Array = []
			for i in s.telegraph.ability.strikes.size():
				var st: StrikeRes = s.telegraph.ability.strikes[i]
				var a: Dictionary = s.telegraph.answers.get(i, {})
				var bv := _beat_victim(s.telegraph, i)
				beats.append({
					"at": st.at,
					"remaining": float((s.telegraph.start_tick + to_ticks(st.at, s.config.fixed_hz)) - s.tick) * s.dt,
					"size": st.size,
					"feint": st.feint,
					"aoe": st.aoe,
					"guard": st.guard,
					"mine": st.aoe or bv == seat,
					"victim": ("" if st.aoe or bv == null else bv.unit_name),
					"resolved": i < s.telegraph.next_strike,
					"answered": a.has(seat),
					"grade": int(a.get(seat, -1)),
				})
			tg["strikes"] = beats
	var base := {
		"boss_hp_frac": s.boss.hp / s.boss.hp_max,
		"my_hp_frac": seat.hp_frac(),
		"defense_ready": s.tick >= seat.defense_ready_tick,
		"dodge_ready": s.tick >= seat.dodge_ready_tick,
		"gcd_ready": s.tick >= seat.gcd_until_tick,
		"telegraph": tg,
	}
	if s.threat_enabled:
		base["aggro_me"] = _threat_target(s) == seat   # raid: am I the boss's victim?
	if s.boss.add_i >= 0:
		var ad: AddRes = s.encounter.adds[s.boss.add_i]
		base["add"] = {"name": ad.name,
			"hp_frac": s.boss.add_hp / maxf(1.0, s.boss.add_hp_max)}
	if seat.kit != null:
		base.merge(seat.kit.observe(s, seat), true)
	return base

# --------------------------------------------------------------------------
# Boss brain
# --------------------------------------------------------------------------

static func current_phase(s: CombatState) -> PhaseRes:
	var frac := s.boss.hp / s.boss.hp_max
	var chosen: PhaseRes = null
	for p in s.encounter.phases:      # phases descend by `at`; take the last that applies
		if p.at >= frac:
			chosen = p
	if chosen == null:
		chosen = PhaseRes.new()
	return chosen

static func _boss_think(s: CombatState, ph: PhaseRes) -> void:
	var enc := s.encounter

	# PACK walk-in (guarded — entered_tick is 0 for every classic fight): the next
	# member is still crossing the field. No forms, no melee, no telegraphs; the
	# players may open on it (WORLD-PLAN: the diegetic valley, not a hard stop).
	if s.boss.entered_tick > 0 and s.tick < s.boss.entered_tick + s.config.pack_walkin_ticks:
		return

	# Add waves (raid): form transitions happen only BETWEEN swings, never mid-telegraph.
	if s.telegraph == null and not enc.adds.is_empty():
		_update_form(s)

	# Continuous, untelegraphed melee — keeps ticking even during a telegraph.
	# While an add holds the field, its own melee (possibly none) replaces the boss's.
	var melee: Dictionary = enc.melee if s.boss.add_i < 0 else (enc.adds[s.boss.add_i] as AddRes).melee
	if not melee.is_empty():
		s.boss.melee_timer -= 1
		while s.boss.melee_timer <= 0:
			var mn := float(melee.get("min", 10.0))
			var mx := float(melee.get("max", 15.0))
			_damage(s, _tank_target(s), s.rng.next_range(mn, mx), &"melee")
			s.boss.melee_timer += to_ticks(float(melee.get("every", 1.5)), s.config.fixed_hz)

	# A telegraph is winding up: advance it; resolve on completion. Ability timers
	# are FROZEN meanwhile (faithful to the prototypes — only one swing at a time).
	# A multi-strike STRING resolves progressively, beat by beat, instead.
	if s.telegraph != null:
		if not s.telegraph.ability.strikes.is_empty():
			_advance_string(s, ph)
		elif s.tick >= s.telegraph.start_tick + s.telegraph.dur_ticks:
			_resolve_telegraph(s, ph)
		return

	# Tick every ACTIVE ability timer (the add's while one holds the field — the
	# withdrawn boss's own timers freeze, exactly as during a telegraph); pick the
	# most-overdue. `danger` (e.g. a crush) wins ties.
	# While the boss is silenced (Voidcaller) it can't START interruptible casts — those
	# are held (timer nudged) so pulses/channels still fire.
	var silenced := s.tick < s.boss.silenced_until_tick
	var abilities: Array = enc.abilities if s.boss.add_i < 0 else (enc.adds[s.boss.add_i] as AddRes).abilities
	var best: AbilityRes = null
	for ab_v in abilities:
		var ab: AbilityRes = ab_v
		s.boss.ability_timer[ab.id] = int(s.boss.ability_timer[ab.id]) - 1
		if int(s.boss.ability_timer[ab.id]) <= 0:
			if silenced and ab.response == AbilityRes.Response.INTERRUPTIBLE:
				s.boss.ability_timer[ab.id] = to_ticks(0.4, s.config.fixed_hz)
				continue
			if best == null or (ab.danger and not best.danger):
				best = ab
	if best != null:
		var gap := best.cd / maxf(0.01, ph.speed) + s.rng.next_float() * best.jitter
		s.boss.ability_timer[best.id] = to_ticks(gap, s.config.fixed_hz)
		_start_telegraph(s, best)

## Begin a telegraph for `ab` — shared by the scheduler and chain links. Its
## rand_target beats roll their victims NOW so the wind-up shows who is marked.
static func _start_telegraph(s: CombatState, ab: AbilityRes) -> void:
	var tg := Telegraph.new()
	tg.ability = ab
	tg.start_tick = s.tick
	var dur := ab.cast
	for st in ab.strikes:               # a string never ends before its last beat
		dur = maxf(dur, float((st as StrikeRes).at))
	tg.dur_ticks = to_ticks(dur, s.config.fixed_hz)
	tg.target = _pick_target(s, ab)     # tank for busters, random dps for marks
	for i in ab.strikes.size():
		if (ab.strikes[i] as StrikeRes).rand_target:
			tg.beat_targets[i] = _random_raider(s)
	if not ab.chain.is_empty():
		tg.chain_src = ab
		tg.chain_i = 0
	s.telegraph = tg

## Add waves (raid). Main form: crossing a wave's HP threshold spawns its add — the
## boss withdraws (timers frozen, HP untouchable) while the add fights with its own
## HP pool, melee, and abilities. Add form: the add dying gives the field back.
static func _update_form(s: CombatState) -> void:
	var enc := s.encounter
	if s.boss.add_i >= 0:
		if s.boss.add_hp <= 0.0:
			var down: AddRes = enc.adds[s.boss.add_i]
			s.boss.add_i = -1
			s.boss.add_hp = 0.0
			s.boss.add_hp_max = 0.0
			if not enc.melee.is_empty():
				s.boss.melee_timer = to_ticks(float(enc.melee.get("every", 1.5)), s.config.fixed_hz)
			_emit(s, {"t": "add_down", "id": down.id, "name": down.name})
		return
	var frac := s.boss.hp / s.boss.hp_max
	for i in enc.adds.size():
		var ad: AddRes = enc.adds[i]
		if frac <= ad.at and not s.boss.adds_spawned.has(i):
			s.boss.adds_spawned[i] = true
			s.boss.add_i = i
			s.boss.add_hp = float(ad.hp)
			s.boss.add_hp_max = float(ad.hp)
			var j := 0
			for ab_v in ad.abilities:   # stagger the add's openers like create_state does
				var ab: AbilityRes = ab_v
				s.boss.ability_timer[ab.id] = to_ticks(
					1.0 + float(j) * 1.2 + s.rng.next_float() * (ab.cd * 0.25), s.config.fixed_hz)
				j += 1
			if not ad.melee.is_empty():
				s.boss.melee_timer = to_ticks(float(ad.melee.get("every", 1.5)), s.config.fixed_hz)
			_emit(s, {"t": "add_spawn", "id": ad.id, "name": ad.name})
			return

## Cast chains (raid): the next link starts the MOMENT the previous resolved or was
## kicked — a kick skips ONE verse, it doesn't end the litany. A live silence does
## (the Silencer's fantasy). Returns true if a new link replaced the telegraph.
static func _advance_chain(s: CombatState) -> bool:
	var tg := s.telegraph
	if tg == null or tg.chain_src == null or tg.chain_i >= tg.chain_src.chain.size():
		return false
	if s.tick < s.boss.silenced_until_tick:
		return false
	var src := tg.chain_src
	var next_i := tg.chain_i
	_start_telegraph(s, src.chain[next_i] as AbilityRes)
	s.telegraph.chain_src = src
	s.telegraph.chain_i = next_i + 1
	return true

static func _resolve_telegraph(s: CombatState, ph: PhaseRes) -> void:
	var ab := s.telegraph.ability
	var amt := roundf(ab.amount * ph.mult)
	match ab.effect:
		AbilityRes.Effect.DMG_TARGET:
			var tgt := s.telegraph.target
			if tgt == null or not tgt.alive():
				tgt = _tank_target(s)
			# Faithful negate model: a DEFENSIBLE swing answered inside the active
			# window is fully negated; the ClassKit applies the aspect consequence.
			var defended := ab.response == AbilityRes.Response.DEFENSIBLE \
					and tgt != null and tgt.dodging_until_tick > s.tick
			if defended and tgt.kit != null:
				tgt.kit.on_negate(s, tgt, ab)
				_emit(s, {"t": "negate", "player": tgt.is_player, "seat": tgt, "size": ab.size, "feint": ab.feint})
			else:
				var d := amt
				if defended:                       # kit-less fallback (M0): partial mitigation
					d *= (1.0 - s.config.defense_mitigation)
				_damage(s, tgt, d, ab.id, ab.size)
		AbilityRes.Effect.DMG_ALL, AbilityRes.Effect.NOVA:
			for seat in s.seats:
				if seat.alive() and _targetable(seat):
					_damage(s, seat, amt, ab.id, ab.size)
		AbilityRes.Effect.DOT_RANDOM:
			var pool := _living_dps(s)
			var clean: Array = []
			var dirty: Array = []
			for u in pool:
				if u.debuff.is_empty():
					clean.append(u)
				else:
					dirty.append(u)
			_rng_shuffle(s, clean)
			_rng_shuffle(s, dirty)
			var order: Array = clean + dirty       # prefer un-debuffed, then refresh
			var n := mini(ab.dot_targets, order.size())
			for i in n:
				_apply_dot(s, order[i], ab, ph)
		AbilityRes.Effect.DOT_ALL:
			for seat in s.seats:
				if seat.alive() and _targetable(seat):
					_apply_dot(s, seat, ab, ph)
		AbilityRes.Effect.MARK_NUKE:
			var t := s.telegraph.target
			if t != null and t.alive():
				_damage(s, t, amt, ab.id, ab.size)
		AbilityRes.Effect.HEAL_ABSORB:
			var t2 := s.telegraph.target
			if t2 == null or not t2.alive():
				t2 = _random_dps(s)
			if t2 != null:
				t2.heal_absorb += amt
				_damage(s, t2, roundf(amt * 0.28), ab.id, ab.size)
		AbilityRes.Effect.HEAL_BOSS:
			# Don't resurrect a boss a player burst already killed THIS tick: damage is
			# applied at step 1 (inputs) but death isn't checked until step 7 (_check_end),
			# so a heal resolving at step 4 must respect an already-lethal hp of 0.
			if s.boss.hp > 0.0:
				var before := s.boss.hp
				s.boss.hp = minf(s.boss.hp_max, s.boss.hp + amt)
				var healed := s.boss.hp - before
				s.boss.heal_total += healed
				if healed > 0.0:
					_emit(s, {"t": "boss_heal", "amt": int(healed)})
		AbilityRes.Effect.EMPOWER_BOSS:
			# Uninterrupted empower cast: the boss permanently hits harder (capped).
			s.boss.dmg_buff = minf(0.55, s.boss.dmg_buff + s.telegraph.ability.buff)
			_emit(s, {"t": "empower", "amt": s.telegraph.ability.buff})
		AbilityRes.Effect.THREAT_DROP:
			# Raid: the boss forgets its grudge against the top-threat unit — it turns
			# on whoever is next on the table until the tank taunts it back.
			if s.threat_enabled:
				var top := _threat_target(s)
				var ti := s.seats.find(top)
				if ti >= 0:
					s.boss.threat[ti] = 0.0
					# GEAR-2: stamp the curse + deed counter (diag-family, never checksummed)
					s.boss.last_curse_tick = s.tick
					_bump_diag(s, top, "curse_dropped")
					_emit(s, {"t": "threat_drop", "seat": top, "player": top.is_player})
	if not _advance_chain(s):          # a resolved chain verse flows into the next
		s.telegraph = null

## Cancel the current telegraph (Shockwave / Avalanche / Vindicate-interrupt).
## Kicking a CHAIN verse skips that verse only — the litany continues.
static func stagger_boss(s: CombatState) -> void:
	if s.telegraph != null:
		# View juice: denying a heal cast is the payoff moment; flag it so the HUD
		# can pop "DENIED!" vs a plain "STAGGERED!".
		var was_heal := s.telegraph.ability.effect == AbilityRes.Effect.HEAL_BOSS
		_emit(s, {"t": "staggered", "was_heal": was_heal})
		if was_heal:
			# GEAR-1: broadcast the denial to every living kitted seat (no-op base
			# hook — gearless runs execute nothing and stay byte-identical).
			for seat in s.seats:
				if seat.kit != null and seat.alive():
					seat.kit.on_boss_heal_denied(s, seat)
		if _advance_chain(s):
			return
	s.telegraph = null

# --------------------------------------------------------------------------
# Strike strings (M7) — multi-beat telegraphs answered with the universal dodge
# --------------------------------------------------------------------------

## THE ONE DODGE (Bill 2026-07-08 — DODGE-PLAN.md). A single press answers BOTH shapes:
## an instant negate of a single DEFENSIBLE swing aimed here, OR a graded barrage-beat.
## The boss resolves one telegraph per tick, so only one shape is ever live — no ambiguity.
## One cooldown replaces the old defense_cd/dodge split: fast recovery on a connect, whiff
## lockout on a wasted press. Only kits that opt in via unified_dodge() route here; every
## other class keeps the split "defense"/"dodge" branches above, byte-identical.
static func _unified_dodge(s: CombatState, seat: Seat) -> void:
	if s.tick < seat.dodge_ready_tick:
		return
	var active := _def_active(s, seat)
	seat.dodging_until_tick = s.tick + to_ticks(active, s.config.fixed_hz)  # pre-emptive negate window
	if seat.kit != null:
		seat.kit.on_dodge_press(s, seat)        # healer cast-cancel / Fermata coil-break
	_emit(s, {"t": "dodge", "player": seat.is_player, "seat": seat})
	var connected := false
	# A single DEFENSIBLE swing aimed here, already inside the active window -> negate it now.
	if seat.kit != null and s.telegraph != null \
			and s.telegraph.ability.response == AbilityRes.Response.DEFENSIBLE \
			and s.telegraph.target == seat:
		var rem := (s.telegraph.start_tick + s.telegraph.dur_ticks) - s.tick
		if s.telegraph.ability.feint or rem <= to_ticks(active, s.config.fixed_hz):
			seat.kit.on_negate(s, seat, s.telegraph.ability)
			_emit(s, {"t": "negate", "player": seat.is_player, "seat": seat,
				"size": s.telegraph.ability.size, "feint": s.telegraph.ability.feint})
			s.telegraph = null
			connected = true
	# Else a live barrage string with a beat I can still answer -> grade it (owns no cd here).
	if not connected and s.telegraph != null and not s.telegraph.ability.strikes.is_empty():
		connected = _answer_strike(s, seat, false)
	# The one cooldown: fast recovery on a connect, whiff lockout on a wasted press.
	var cd := s.config.dodge_recovery if connected else s.config.dodge_whiff_cd
	seat.dodge_ready_tick = s.tick + to_ticks(cd, s.config.fixed_hz)
	seat.defense_ready_tick = seat.dodge_ready_tick   # keep the rune/policy gates in lockstep
	if seat.kit != null:
		seat.kit.on_defense_press(s, seat)      # Twin Step spare-charge recharge (may refund the gate)

## Attribute a universal-dodge press to the next answerable beat of the live
## string and grade it by how tight the press was. Pressing a FEINT beat takes
## the bait; a press too early for any beat WHIFFS into the long lockout —
## panic-mashing eats the rest of the combo. No live string = free movement.
## Grade the seat's next answerable barrage beat. Returns true only when a REAL beat
## connected (graze/good/perfect) — a too-early whiff or a baited feint returns false.
## apply_cd=true (the split "dodge" verb) sets the whiff lockout itself, byte-identical
## to before; the unified dodge passes false and owns the one cooldown from the return.
static func _answer_strike(s: CombatState, seat: Seat, apply_cd := true) -> bool:
	var tg := s.telegraph
	if tg == null or tg.ability.strikes.is_empty():
		return false
	var idx := _next_answerable(tg, seat)
	if idx < 0:
		return false                            # none of the remaining beats are yours
	var st: StrikeRes = tg.ability.strikes[idx]
	var early := float((tg.start_tick + to_ticks(st.at, s.config.fixed_hz)) - s.tick) * s.dt
	if early > s.config.strike_graze:           # too early even for a graze
		if apply_cd:
			seat.dodge_ready_tick = s.tick + to_ticks(s.config.dodge_whiff_cd, s.config.fixed_hz)
		_bump_diag(s, seat, "whiff")
		_emit(s, {"t": "dodge_whiff", "seat": seat, "player": seat.is_player})
		return false
	var grade := StrikeRes.Grade.GRAZE
	if st.feint:
		grade = StrikeRes.Grade.BAITED          # committing the dodge to a fake IS the mistake
		if apply_cd:
			seat.dodge_ready_tick = s.tick + to_ticks(s.config.dodge_whiff_cd, s.config.fixed_hz)
	elif early <= s.config.strike_perfect:
		grade = StrikeRes.Grade.PERFECT
	elif early <= s.config.strike_good:
		grade = StrikeRes.Grade.GOOD
	if not tg.answers.has(idx):
		tg.answers[idx] = {}
	tg.answers[idx][seat] = grade
	_bump_diag(s, seat, StrikeRes.grade_name(grade))
	if seat.kit != null:
		seat.kit.on_strike_result(s, seat, tg.ability, st, grade)
	_emit(s, {"t": "strike_graded", "grade": grade, "seat": seat,
		"player": seat.is_player, "idx": idx, "feint": st.feint, "size": st.size})
	return grade != StrikeRes.Grade.BAITED     # a real beat connected; a bait/whiff did not

## First unresolved beat this seat can still answer (skips UNANSWERABLE beats,
## beats aimed at someone else, and beats this seat already answered).
static func _next_answerable(tg: Telegraph, seat: Seat) -> int:
	for i in range(tg.next_strike, tg.ability.strikes.size()):
		var st: StrikeRes = tg.ability.strikes[i]
		if st.guard == StrikeRes.Guard.UNANSWERABLE:
			continue
		if not st.aoe and _beat_victim(tg, i) != seat:
			continue
		var a: Dictionary = tg.answers.get(i, {})
		if a.has(seat):
			continue
		return i
	return -1

## The victim of a non-aoe beat: its rolled rand_target raider if the beat has one,
## else the telegraph's target (all pre-raid strings — behavior unchanged).
static func _beat_victim(tg: Telegraph, i: int) -> Seat:
	return tg.beat_targets.get(i, tg.target)

## Progressive resolution: each beat lands at its own impact tick inside the
## wind-up; the telegraph clears after the LAST beat. Boss ability timers stay
## frozen for the whole string (it is ONE swing to the scheduler).
static func _advance_string(s: CombatState, ph: PhaseRes) -> void:
	var tg := s.telegraph
	while tg.next_strike < tg.ability.strikes.size():
		var st: StrikeRes = tg.ability.strikes[tg.next_strike]
		if s.tick < tg.start_tick + to_ticks(st.at, s.config.fixed_hz):
			break
		_resolve_strike(s, ph, tg.next_strike)
		tg.next_strike += 1
	if tg.next_strike >= tg.ability.strikes.size() \
			and s.tick >= tg.start_tick + tg.dur_ticks:
		if not _advance_chain(s):
			s.telegraph = null

## One beat lands. `aoe` beats hit EVERY living seat — the healer included (the
## only damage in the game that reaches a healer). Stat-block allies can't press,
## so they auto-roll their dodge on the authoritative rng (fixed seat order keeps
## it deterministic). Feint beats deal nothing: pressing was punished at the
## press; holding pays out here as a READ.
static func _resolve_strike(s: CombatState, ph: PhaseRes, idx: int) -> void:
	var tg := s.telegraph
	var st: StrikeRes = tg.ability.strikes[idx]
	var ans: Dictionary = tg.answers.get(idx, {})
	var victims: Array = []
	if st.aoe:
		for seat in s.seats:
			if seat.alive():
				victims.append(seat)
	else:
		var t: Seat = _beat_victim(tg, idx)
		if tg.beat_targets.has(idx):
			if t == null or not t.alive():
				t = null                # a personal bolt aimed at the fallen fizzles
		elif t == null or not t.alive():
			t = _tank_target(s)
		if t != null:
			victims.append(t)
	var base := roundf(tg.ability.amount * st.amount_frac * ph.mult)
	for seat in victims:
		if st.feint:
			if not ans.has(seat) and seat.fidelity != "statblock":
				_bump_diag(s, seat, "read")
				if seat.kit != null:
					seat.kit.on_strike_result(s, seat, tg.ability, st, StrikeRes.Grade.READ)
				_emit(s, {"t": "strike_graded", "grade": StrikeRes.Grade.READ, "seat": seat,
					"player": seat.is_player, "idx": idx, "feint": true, "size": st.size})
			continue
		var grade := int(ans.get(seat, StrikeRes.Grade.MISS))
		if not ans.has(seat) and seat.fidelity == "statblock" \
				and st.guard != StrikeRes.Guard.UNANSWERABLE:
			if s.rng.next_float() < s.config.statblock_dodge:
				grade = StrikeRes.Grade.GOOD
		var d := roundf(base * _strike_mult(s, st, grade))
		if grade == StrikeRes.Grade.MISS and st.guard != StrikeRes.Guard.UNANSWERABLE \
				and seat.fidelity != "statblock":
			_bump_diag(s, seat, "miss")
			if seat.kit != null:
				seat.kit.on_strike_result(s, seat, tg.ability, st, StrikeRes.Grade.MISS)
		if d > 0.0:
			# rand_target beats pierce like aoe — a personal bolt CAN find the healer
			_damage(s, seat, d, tg.ability.id, st.size, st.aoe or tg.beat_targets.has(idx))
		else:
			_emit(s, {"t": "negate", "player": seat.is_player, "size": st.size, "feint": false})
	_emit(s, {"t": "strike_landed", "idx": idx})

## Damage fraction a beat still deals, by guard type and grade.
static func _strike_mult(s: CombatState, st: StrikeRes, grade: int) -> float:
	match st.guard:
		StrikeRes.Guard.UNANSWERABLE:
			return 1.0
		StrikeRes.Guard.BLOCKABLE:
			match grade:
				StrikeRes.Grade.PERFECT: return s.config.block_perfect
				StrikeRes.Grade.GOOD: return s.config.block_good
				StrikeRes.Grade.GRAZE: return s.config.block_graze
				_: return 1.0
		_:
			match grade:
				StrikeRes.Grade.PERFECT, StrikeRes.Grade.GOOD: return 0.0
				StrikeRes.Grade.GRAZE: return s.config.graze_mult
				_: return 1.0

## Deterministic diagnostics (grade counts). Every full-fidelity seat keeps its own
## counts (seat.diag — raid sims); s.diag stays the is_player mirror solo sims read.
static func _bump_diag(s: CombatState, seat: Seat, key: String) -> void:
	if seat == null:
		return
	if seat.fidelity != "statblock":
		seat.diag[key] = int(seat.diag.get(key, 0)) + 1
	if seat.is_player:
		s.diag[key] = int(s.diag.get(key, 0)) + 1

# --------------------------------------------------------------------------
# Meter — Recount-style per-seat per-source accounting (the DPS/HPS window).
# Diag-family data: deterministic, engine-written, never checksummed. Keyed by
# seats[] INDEX (RefCounted-cycle + serialization safety, same rule as threat).
# Kits that damage the boss OUTSIDE damage_boss (Twinfang's direct path) call
# meter_dmg themselves with their source label.
# --------------------------------------------------------------------------

static func _meter_row(s: CombatState, seat: Seat) -> Dictionary:
	var i := s.seats.find(seat)
	if i < 0:
		return {}
	if not s.meter.has(i):
		s.meter[i] = {"dmg": {}, "heal": {}, "shield": {}, "taken": {},
			"dmg_total": 0.0, "heal_total": 0.0, "over_total": 0.0,
			"shield_total": 0.0, "taken_total": 0.0}
	return s.meter[i]

static func _meter_hit(by: Dictionary, src: StringName, amt: float, discrete: bool) -> void:
	if not by.has(src):
		by[src] = {"total": 0.0, "n": 0, "max": 0.0, "crit_n": 0, "over": 0.0}
	var e: Dictionary = by[src]
	e["total"] = float(e["total"]) + amt
	if discrete:                       # continuous chip (statblock autos) skips n/max —
		e["n"] = int(e["n"]) + 1       # per-tick fractions would make count/avg/max lies
		e["max"] = maxf(float(e["max"]), amt)

## Damage dealt to the boss (or the add holding the field), by source label.
static func meter_dmg(s: CombatState, seat: Seat, src: StringName, amt: float,
		crit := false, discrete := true) -> void:
	if seat == null or amt <= 0.0:
		return
	var row := _meter_row(s, seat)
	if row.is_empty():
		return
	_meter_hit(row["dmg"], src, amt, discrete)
	if crit:
		var e: Dictionary = row["dmg"][src]
		e["crit_n"] = int(e["crit_n"]) + 1
	row["dmg_total"] = float(row["dmg_total"]) + amt

## Effective healing done by `caster` (overheal tracked beside it, absorbs count
## as healing with eff and src &"ward" — the Recount convention).
static func meter_heal(s: CombatState, caster: Seat, src: StringName, eff: float, over: float) -> void:
	if caster == null or (eff <= 0.0 and over <= 0.0):
		return
	var row := _meter_row(s, caster)
	if row.is_empty():
		return
	if eff > 0.0:
		_meter_hit(row["heal"], src, eff, true)
	elif not row["heal"].has(src):     # full-overheal casts still register the source
		row["heal"][src] = {"total": 0.0, "n": 0, "max": 0.0, "crit_n": 0, "over": 0.0}
	var e: Dictionary = row["heal"][src]
	e["over"] = float(e["over"]) + over
	row["heal_total"] = float(row["heal_total"]) + eff
	row["over_total"] = float(row["over_total"]) + over

## Shielding done by `caster` — damage absorbed by a ward it granted. Tracked in a
## bucket SEPARATE from heal (a ward mitigates a hit; it never restores lost HP), so
## the meter can show HEALING and SHIELDING as distinct output — the honest split a
## ward-heavy healer (Bloomweaver) needs (no more "Wards" inflating the HPS number).
static func meter_shield(s: CombatState, caster: Seat, src: StringName, amt: float) -> void:
	if caster == null or amt <= 0.0:
		return
	var row := _meter_row(s, caster)
	if row.is_empty():
		return
	_meter_hit(row["shield"], src, amt, true)
	row["shield_total"] = float(row["shield_total"]) + amt

## Damage a seat actually took (post-mitigation, post-absorb), by boss source.
static func meter_taken(s: CombatState, seat: Seat, src: StringName, amt: float,
		discrete := true) -> void:
	if seat == null or amt <= 0.0:
		return
	var row := _meter_row(s, seat)
	if row.is_empty():
		return
	_meter_hit(row["taken"], src, amt, discrete)
	row["taken_total"] = float(row["taken_total"]) + amt

# --------------------------------------------------------------------------
# Damage
# --------------------------------------------------------------------------

# --- THE VULNERABILITY STACK (REFIT P4) ------------------------------------------
# The one generic "boss takes MORE" window. Effects feed windows via add_vuln; BOTH
# damage paths (damage_boss + the stat-block ally contrib) fold them at vuln_mult.
# The Well's GLINT rides here today; TEAM-COMP school amps and Depth affix windows
# get this same fold slot instead of hand-rolling new BossState fields.

## Add or REFRESH a window. Same (seat_i, src) overwrites — a source never stacks
## with itself (re-applying refreshes strength + deadline); distinct sources multiply.
## seat_i -1 = the whole raid; else only that attacker's hits. `until_tick` absolute.
static func add_vuln(s: CombatState, seat_i: int, mult: float, until_tick: int,
		src: StringName) -> void:
	for v in s.boss.vulns:
		if int(v["seat_i"]) == seat_i and StringName(v["src"]) == src:
			v["mult"] = mult
			v["until"] = until_tick
			return
	s.boss.vulns.append({"seat_i": seat_i, "mult": mult, "until": until_tick, "src": src})

## The live deadline a source already holds on a seat (-1 if none) — lets an effect
## EXTEND a window instead of resetting it (the Well's keptLight idiom).
static func vuln_until(s: CombatState, seat_i: int, src: StringName) -> int:
	for v in s.boss.vulns:
		if int(v["seat_i"]) == seat_i and StringName(v["src"]) == src and s.tick < int(v["until"]):
			return int(v["until"])
	return -1

## Fold every live window that applies to this attacker (raid-wide + personal),
## lazily pruning expired entries — driven by s.tick only, deterministic.
static func vuln_mult(s: CombatState, seat_i: int) -> float:
	var m := 1.0
	var i := s.boss.vulns.size() - 1
	while i >= 0:
		var v: Dictionary = s.boss.vulns[i]
		if s.tick >= int(v["until"]):
			s.boss.vulns.remove_at(i)
		elif int(v["seat_i"]) < 0 or int(v["seat_i"]) == seat_i:
			m *= float(v["mult"])
		i -= 1
	return m

## Outgoing damage from a seat's ability to the boss. Returns damage dealt.
## `src` is the meter's source label (ability id); it also rides the boss_hit
## event as `kind` so HUD damage numbers can colour by source.
static func damage_boss(s: CombatState, seat: Seat, raw: float, src: StringName = &"attack",
		crit := false) -> float:
	var mult := 1.0
	if seat != null and seat.kit != null:
		mult = seat.kit.outgoing_mult(seat)
	if s.boss.sunder > 0.0:                     # SUNDER: the cracked wall takes MORE from everyone
		mult *= 1.0 + s.boss.sunder * s.config.sunder_k
	if s.boss.debilitate > 0.0:                 # DEBILITATE: the corroded boss takes MORE from the whole raid
		mult *= 1.0 + s.boss.debilitate * s.config.debilitate_k
	if not s.boss.vulns.is_empty():             # THE VULNERABILITY STACK (empty = byte-identical)
		mult *= vuln_mult(s, s.seats.find(seat))
	if s.party_out_mult != 1.0:                 # OVERCLOCK DMG-amp prime (default 1.0 → byte-neutral)
		mult *= s.party_out_mult
	var d := roundf(raw * mult)
	if s.boss.add_i >= 0:
		s.boss.add_hp = maxf(0.0, s.boss.add_hp - d)   # an add holds the field — it eats the hit
	else:
		s.boss.hp = maxf(0.0, s.boss.hp - d)
	if s.threat_enabled and seat != null and d > 0.0:
		_add_threat(s, seat, d * (s.config.threat_tank_mult if seat.role == "tank" else 1.0))
	if d > 0.0:
		meter_dmg(s, seat, src, d, crit)
		_emit(s, {"t": "boss_hit", "amt": int(d), "seat": seat, "kind": String(src), "crit": crit})
	return d

# --------------------------------------------------------------------------
# Raid threat (threat_enabled fights only — every call site is guarded, so solo
# content never touches these paths; see RAID-PLAN.md §R0). The table is keyed by
# seats[] INDEX, never Seat refs (RefCounted-cycle + future-serialization safety).
# --------------------------------------------------------------------------

static func _add_threat(s: CombatState, seat: Seat, amt: float) -> void:
	var i := s.seats.find(seat)
	if i >= 0:
		s.boss.threat[i] = float(s.boss.threat.get(i, 0.0)) + amt

## Public taunt entry for ClassKits (Bulwark "Challenge"): force the boss onto
## `seat` for taunt_dur and jump its threat to the table top × taunt_threat_bonus.
static func taunt(s: CombatState, seat: Seat, dur: float = -1.0) -> void:
	if not s.threat_enabled or seat == null:
		return
	var i := s.seats.find(seat)
	if i < 0:
		return
	if dur < 0.0:
		dur = s.config.taunt_dur
	s.boss.taunt_seat_i = i
	s.boss.taunt_until_tick = s.tick + to_ticks(dur, s.config.fixed_hz)
	# GEAR-2: a taunt within 2s of a THREAT_DROP answers the curse (deed detector).
	# Capped at one answer per drop so re-taunts can't outpace curse_dropped.
	if s.tick - s.boss.last_curse_tick <= to_ticks(2.0, s.config.fixed_hz) \
			and int(seat.diag.get("curse_answered", 0)) < int(seat.diag.get("curse_dropped", 0)):
		_bump_diag(s, seat, "curse_answered")
	var top := 0.0
	for t in s.boss.threat.values():
		top = maxf(top, float(t))
	s.boss.threat[i] = maxf(float(s.boss.threat.get(i, 0.0)), top * s.config.taunt_threat_bonus)
	_emit(s, {"t": "taunt", "seat": seat, "player": seat.is_player})

## The boss's current victim under threat rules: an active taunt wins; else the
## highest-threat living targetable seat (ties: earliest in seat order — deterministic).
static func _threat_target(s: CombatState) -> Seat:
	if s.boss.taunt_seat_i >= 0 and s.tick < s.boss.taunt_until_tick \
			and s.boss.taunt_seat_i < s.seats.size():
		var forced: Seat = s.seats[s.boss.taunt_seat_i]
		if forced.alive():
			return forced
	var best: Seat = null
	var best_t := -1.0
	for i in s.seats.size():
		var seat: Seat = s.seats[i]
		if seat.alive() and _targetable(seat):
			var t := float(s.boss.threat.get(i, 0.0))
			if t > best_t:
				best = seat
				best_t = t
	if best != null:
		return best
	return _primary_target(s)


## Append a view-layer combat event (bounded; the sim ignores these).
static func _emit(s: CombatState, ev: Dictionary) -> void:
	s.events.append(ev)
	if s.events.size() > 64:
		s.events.pop_front()

## Public entry so ClassKits can push view-layer juice events (drained by the HUD,
## ignored by the sim; never part of the checksum). Do NOT drive gameplay off these.
static func emit_event(s: CombatState, ev: Dictionary) -> void:
	_emit(s, ev)

static func _damage(s: CombatState, seat: Seat, amt: float, src: StringName,
		size: int = AbilityRes.Size.NONE, pierce_healer: bool = false) -> void:
	if seat == null or not seat.alive():
		return
	if seat.role == "healer" and not pierce_healer:
		return                                 # the healer is untargetable — except by aoe strike beats (M7)
	var d := amt
	if s.boss.dmg_buff > 0.0:                  # boss self-empower (Voidcaller): harder hits
		d *= (1.0 + s.boss.dmg_buff)
	# party-wide DR (Brinkwarden Last Stand)
	if not s.raid_dr.is_empty() and s.tick < int(s.raid_dr.get("until_tick", -1)):
		d *= (1.0 - float(s.raid_dr.get("amt", 0.0)))
	if seat.kit != null:
		d = seat.kit.modify_incoming(s, seat, d, src, size)
		d = roundf(d)                         # bulwark rounds; kit-less M0 stays fractional
	if d < 0.0:
		d = 0.0
	# absorb shield drains before HP; ward expires the instant it empties
	if seat.absorb > 0.0 and d > 0.0:
		var eaten := minf(seat.absorb, d)
		seat.absorb -= eaten
		d -= eaten
		var emptied := seat.absorb <= 0.0
		if emptied:
			seat.ward_until_tick = s.tick
		# The ward OWNER's kit sees its absorb eat the hit (Bloomweaver thorns /
		# Perfect Ward). Owner index is stamped by whoever granted the ward; legacy
		# wards (-1) fall back to the first healer — identical solo, and correct
		# once two shield-source classes share a raid.
		if eaten > 0.0:
			var hseat: Seat = null
			if seat.absorb_owner_i >= 0 and seat.absorb_owner_i < s.seats.size():
				hseat = s.seats[seat.absorb_owner_i]
			if hseat == null:
				hseat = _healer(s)
			meter_shield(s, hseat, &"ward", eaten)      # mitigation, tracked apart from heals
			if hseat != null and hseat.kit != null:
				hseat.kit.on_absorb(s, hseat, seat, eaten, emptied)
	var pre_frac := seat.hp / maxf(1.0, seat.hp_max)   # GEAR-2: dip detector reads the crossing
	seat.hp -= d
	if seat.hp < 0.0:
		seat.hp = 0.0
	if pre_frac >= 0.3 and seat.hp / maxf(1.0, seat.hp_max) < 0.3:
		_bump_diag(s, seat, "bloodied_dip")            # deed detector (diag-only, never checksummed)
	if seat.kit != null and d > 0.0:
		seat.kit.on_damage_taken(s, seat, d, src, size)
	if d > 0.0:
		meter_taken(s, seat, src, d, src != &"enrage")   # enrage is per-tick chip — totals only
		_emit(s, {"t": "hurt", "seat": seat, "player": seat.is_player, "amt": int(d), "size": size})

## Win condition (stat-block allies): boss loses Σ (living ally.dps * f(hp%)) * dt.
static func _apply_group_damage(s: CombatState, dt: float) -> void:
	var total := 0.0
	for seat in s.seats:
		if seat.alive() and seat.dps > 0.0:
			var f := -1.0
			if seat.kit != null:
				f = seat.kit.dps_factor(s, seat, seat.hp_frac())   # Brinkwarden override
			if f < 0.0:
				f = f_hp(seat.hp_frac(), s.config)                 # default curve
			var contrib := seat.dps * f
			# THE VULNERABILITY STACK: raid-wide windows + this ally's personal ones
			# (the Well's GLINT lives here now). Empty stack = 1.0 = byte-identical.
			if not s.boss.vulns.is_empty():
				contrib *= vuln_mult(s, s.seats.find(seat))
			# THE SHINING HOUR (Well support boon): while the whole party is topped, the
			# warband deals more. Same guarded idiom — absent well_hour_until (-1) = no-op.
			if s.tick < int(seat.vars.get("well_hour_until", -1)):
				contrib *= float(seat.vars.get("well_hour_mult", 1.0))
			total += contrib
			meter_dmg(s, seat, &"attack", contrib * dt, false, false)
			if s.threat_enabled:
				_add_threat(s, seat, contrib * dt)
	if s.boss.add_i >= 0:
		s.boss.add_hp = maxf(0.0, s.boss.add_hp - total * dt)
	else:
		s.boss.hp -= total * dt
		if s.boss.hp < 0.0:
			s.boss.hp = 0.0

static func _apply_enrage(s: CombatState, dt: float) -> void:
	# OVERCLOCK STALL (+s) delays enrage; a curse (−s) hastens it. Read off a COPY —
	# never mutate the shared EncounterRes. Default offset 0.0 → byte-identical.
	# PACK: the clock is time-since-THIS-member-entered (entered_tick is 0 for every
	# classic fight, so the math below is byte-identical there).
	var e := s.encounter.enrage_at + s.enrage_offset
	var t := s.time() - float(s.boss.entered_tick) * s.dt
	if e > 0.0 and t >= e:
		var over := t - e
		var ed := s.config.enrage_base * over * dt
		for seat in s.seats:
			if seat.alive():
				_damage(s, seat, ed, &"enrage")

static func _check_end(s: CombatState) -> void:
	if s.boss.hp <= 0.0:
		# PACK: a member fell but the battle isn't over — the next one takes the field.
		# (Guarded: pack is empty for every classic fight, so this branch never fires.)
		if not s.pack.is_empty() and s.pack_i < s.pack.size() - 1:
			_pack_advance(s)
			return
		s.boss.hp = 0.0
		s.over = true
		s.won = true
		return
	if s.loss_mode == "raid":
		# Role extinction: the raid stands while every present role has a living
		# member. With one tank/one healer this is exactly the old "any tank/healer
		# death" rule (byte-identical for all solo-era content); with raid comps a
		# dead member spectates until their whole role is gone.
		var has := {"tank": false, "healer": false, "dps": false}
		var alive := {"tank": false, "healer": false, "dps": false}
		for seat in s.seats:
			if has.has(seat.role):
				has[seat.role] = true
				if seat.alive():
					alive[seat.role] = true
		if bool(has["healer"]) and not bool(alive["healer"]):
			s.over = true; s.won = false; s.loss_cause = "healer_death"
		elif bool(has["tank"]) and not bool(alive["tank"]):
			s.over = true; s.won = false; s.loss_cause = "tank_death"
		elif bool(has["dps"]) and not bool(alive["dps"]):
			s.over = true; s.won = false; s.loss_cause = "dps_wipe"
	else:
		# solo duel: lose if the player dies (or the whole party wipes)
		var any_alive := false
		var player_dead := false
		for seat in s.seats:
			if seat.alive():
				any_alive = true
			elif seat.is_player:
				player_dead = true
		if player_dead:
			s.over = true; s.won = false; s.loss_cause = "player_death"
		elif not any_alive:
			s.over = true; s.won = false; s.loss_cause = "wipe"

## PACK (WORLD-PLAN §FIGHT LENGTH): the fallen member's replacement walks in. The SAME
## BossState object resets in place (no stale references anywhere), the encounter swaps,
## and the walk-in grace begins. The SEATS are untouched — that's the heat carry: your
## Flow / vials / rig charge / cooldowns ride into the next pull. A fresh threat table
## (the tank re-establishes) is the new pull's texture. Runs inside update() on the
## seeded stream — deterministic, lockstep-safe, and absent from every classic fight.
static func _pack_advance(s: CombatState) -> void:
	s.pack_i += 1
	var enc: EncounterRes = s.pack[s.pack_i]
	s.encounter = enc
	s.telegraph = null                      # the dead member's swing dies with it
	var b := s.boss
	b.hp = float(enc.hp)
	b.hp_max = float(enc.hp)
	b.heal_total = 0.0
	b.silenced_until_tick = -1
	b.dmg_buff = 0.0
	b.sunder = 0.0
	b.debilitate = 0.0
	b.vulns = []                            # windows die with the member (fresh wall, fresh cracks)
	b.last_curse_tick = -999999
	b.melee_timer = 1000000
	b.ability_timer = {}
	b.add_i = -1
	b.add_hp = 0.0
	b.add_hp_max = 0.0
	b.adds_spawned = {}
	b.threat = {}
	b.taunt_seat_i = -1
	b.taunt_until_tick = -1
	b.entered_tick = s.tick                 # walk-in grace + per-member enrage key off this
	var i := 0
	for ab in enc.abilities:
		var stagger := 2.0 + float(i) * 1.5 + s.rng.next_float() * (ab.cd * 0.3)
		b.ability_timer[ab.id] = to_ticks(stagger, s.config.fixed_hz)
		i += 1
	if not enc.melee.is_empty():
		b.melee_timer = to_ticks(float(enc.melee.get("every", 1.5)), s.config.fixed_hz)
	_emit(s, {"t": "pack_next", "i": s.pack_i, "n": s.pack.size(), "name": enc.name})

static func _primary_target(s: CombatState) -> Seat:
	for seat in s.seats:
		if seat.is_player and seat.alive():
			return seat
	for seat in s.seats:
		if seat.alive():
			return seat
	return null

# --------------------------------------------------------------------------
# Healing + timed effects + role-aware targeting (healer support)
# --------------------------------------------------------------------------

## Heal `target` for `amt`, funnelled through the CASTER's aspect (Brinkwarden low-HP
## scaling), consuming heal-absorb, applying to HP, and routing overheal (Tidecaller
## Reservoir / Overflow shield). Returns effective HP restored.
static func heal_unit(s: CombatState, target: Seat, amt: float, caster: Seat,
		src: StringName = &"heal") -> float:
	if target == null or not target.alive():
		return 0.0
	var mult := 1.0
	if caster != null and caster.kit != null:
		mult = caster.kit.heal_mult(target)
	amt = roundf(amt * mult)
	if target.heal_absorb > 0.0:               # heal-absorb eats healing first
		var a := minf(target.heal_absorb, amt)
		target.heal_absorb -= a
		amt -= a
	if amt <= 0.0:
		return 0.0
	var missing := target.hp_max - target.hp
	var eff := minf(missing, amt)
	var over := amt - eff
	target.hp += eff
	if s.threat_enabled and caster != null and eff > 0.0:
		_add_threat(s, caster, eff * s.config.threat_heal_factor)
	if caster != null and caster.kit != null:
		caster.kit.on_overheal(s, caster, target, over)
		caster.kit.on_heal(s, caster, target, eff, over)
	meter_heal(s, caster, src, eff, over)
	if eff > 0.0 or over > 0.0:
		_emit(s, {"t": "heal", "seat": target, "amt": int(eff), "over": int(over)})
	return eff

## Advance HoTs (heal), the single DoT slot (damage), and ward expiry, each tick.
static func _apply_seat_effects(s: CombatState) -> void:
	var healer := _healer(s)
	for seat in s.seats:
		if not seat.alive():
			continue
		if seat.ward_until_tick >= 0 and s.tick >= seat.ward_until_tick:
			seat.absorb = 0.0
			seat.ward_until_tick = -1
		if not seat.hots.is_empty():           # HoTs stack (array)
			var keep: Array = []
			for h in seat.hots:
				h["acc"] = int(h["acc"]) + 1
				# credit the HoT's CASTER (index stamped at apply); unstamped legacy
				# HoTs fall back to the first healer — identical solo, correct in a raid
				var ci := int(h.get("caster_i", -1))
				var hcaster: Seat = (s.seats[ci] if ci >= 0 and ci < s.seats.size() else healer)
				while int(h["acc"]) >= int(h["every"]) and int(h["left"]) > 0:
					h["acc"] = int(h["acc"]) - int(h["every"])
					h["left"] = int(h["left"]) - int(h["every"])
					heal_unit(s, seat, float(h["tick"]), hcaster, StringName(h.get("src", &"hot")))
				if int(h["left"]) > 0 and seat.alive():
					keep.append(h)
			seat.hots = keep
		if not seat.debuff.is_empty():         # single DoT slot (refreshes on reapply)
			var d := seat.debuff
			d["acc"] = int(d["acc"]) + 1
			while int(d["acc"]) >= int(d["every"]) and int(d["left"]) > 0:
				d["acc"] = int(d["acc"]) - int(d["every"])
				d["left"] = int(d["left"]) - int(d["every"])
				_damage(s, seat, float(d["tick"]), &"debuff")
			if int(d["left"]) <= 0:
				seat.debuff = {}

static func _apply_dot(s: CombatState, seat: Seat, ab: AbilityRes, ph: PhaseRes) -> void:
	seat.debuff = {
		"id": ab.id,
		"tick": ab.dot_tick * ph.mult,
		"every": to_ticks(ab.dot_every, s.config.fixed_hz),
		"acc": 0,
		"left": to_ticks(ab.dot_dur, s.config.fixed_hz),
	}
	_emit(s, {"t": "debuff", "seat": seat, "id": ab.id})

static func _pick_target(s: CombatState, ab: AbilityRes) -> Seat:
	match ab.effect:
		AbilityRes.Effect.MARK_NUKE, AbilityRes.Effect.HEAL_ABSORB:
			return _random_dps(s)
		_:
			return _tank_target(s)

static func _tank_target(s: CombatState) -> Seat:
	if s.threat_enabled:
		return _threat_target(s)
	for seat in s.seats:
		if seat.role == "tank" and seat.alive():
			return seat
	return _primary_target(s)

static func _living_dps(s: CombatState) -> Array:
	var out: Array = []
	for seat in s.seats:
		if seat.role == "dps" and seat.alive():
			out.append(seat)
	return out

static func _random_dps(s: CombatState) -> Seat:
	var pool := _living_dps(s)
	if pool.is_empty():
		return _tank_target(s)
	return pool[s.rng.next_u32() % pool.size()]

## A random LIVING raider, the healer included — rand_target beats are the one
## mechanic that can find anyone. Deterministic via the state rng (rolled only
## when a rand_target beat exists, so non-raid rng order is untouched).
static func _random_raider(s: CombatState) -> Seat:
	var pool: Array = []
	for seat in s.seats:
		if seat.alive():
			pool.append(seat)
	if pool.is_empty():
		return null
	return pool[s.rng.next_u32() % pool.size()]

static func _healer(s: CombatState) -> Seat:
	for seat in s.seats:
		if seat.role == "healer":
			return seat
	return null

## A seat the boss can hit (everyone except a pure healer).
static func _targetable(seat: Seat) -> bool:
	return seat.role != "healer"

static func _rng_shuffle(s: CombatState, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := s.rng.next_u32() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

static func _def_active(s: CombatState, seat: Seat) -> float:
	if seat.kit != null:
		var v := seat.kit.defense_active()
		if v >= 0.0:
			return v
	return s.config.defense_active

static func _def_cd(s: CombatState, seat: Seat) -> float:
	if seat.kit != null:
		var v := seat.kit.defense_cd()
		if v >= 0.0:
			return v
	return s.config.defense_cd
