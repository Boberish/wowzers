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
var creed_id: String = "drumline"      ## TEMPO rework: the run's risk temperament (Tempo only)
var modules: Dictionary = {}           ## TEMPO rework: equipped UI Modules, id -> true (Opening/Edge/…)

func _init(_aspect: String, _cfg: TwinfangConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _m(id: String) -> bool:
	return bool(modules.get(id, false))

# --- CREEDS (Tempo rework, TEMPO-PLAN §3): a slip's cost + Flow's reward value ---
func _creed() -> Dictionary:
	return TwinfangCreeds.get_creed(creed_id)

func _creed_flow_value() -> float:
	if aspect != "tempo":
		return 1.0
	return float(_creed().get("flow_value", 1.0))

## A SLIP — a missed Perfect Strike or an eaten swing — paid in your groove/window per Creed.
func _creed_slip(s: CombatState, seat: Seat) -> void:
	if aspect != "tempo" or _flow(seat) <= 0:
		return
	var c := _creed()
	match String(c.get("slip", "flow_loss")):
		"shatter":
			seat.vars["flow"] = 0
		"freeze":
			pass                                   # Flow untouched — the window pays instead
		_:
			seat.vars["flow"] = maxi(0, _flow(seat) - int(c.get("slip_amt", 2)))
	seat.vars["flow_decay_acc"] = 0
	var lock := float(c.get("lock_sec", 0.0))
	if lock > 0.0:
		seat.vars["window_lock_until"] = s.tick + _tt(s, lock)
		seat.vars["window_locked"] = true
	CombatCore._bump_diag(s, seat, "slip")
	CombatCore.emit_event(s, {"t": "creed_slip", "player": seat.is_player, "creed": creed_id})

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
	return 1.0 + float(_flow(seat)) * cfg.flow_per * _creed_flow_value()   # CREED: glass pays more per point

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

# --- Tempo ACCELERANDO: the live rhythm window as a function of current Flow. Flow 0 =
#     the base anchors; max Flow = the *_lo anchors; lerp between (Flow = BPM). Venom pins
#     Flow at 0, so it always sees the base window (a steady beat, no accelerando). ONE
#     source of truth for _strike AND observe() so the RhythmBar/policy read exactly what
#     the kit judges a press against.
func _tempo_t(seat: Seat) -> float:
	# GEAR-2: Encore Bell — after a finisher the window holds at the wide Flow-0
	# anchors for 3 strikes (encore_left is only ever written by the gear branch).
	if int(seat.vars.get("encore_left", 0)) > 0:
		return 0.0
	# CREED (Held Breath): a slip locks the tight window to base for a beat (upkeep clears it).
	if bool(seat.vars.get("window_locked", false)):
		return 0.0
	return clampf(float(_flow(seat)) / float(max_flow()), 0.0, 1.0)
func _swing_min_sec(seat: Seat) -> float:
	return lerpf(cfg.swing_min, cfg.swing_min_lo, _tempo_t(seat))
func _perfect_lo_sec(seat: Seat) -> float:
	return _edge_window(seat)[0]
func _perfect_hi_sec(seat: Seat) -> float:
	return _edge_window(seat)[1]
## The live Perfect window [lo, hi] in seconds. MODULE (The Edge): narrows the window around
## its centre for a bigger Perfect payoff — "narrow for damage." Base window otherwise.
func _edge_window(seat: Seat) -> Array:
	var t := _tempo_t(seat)
	var lo := lerpf(cfg.perfect_start, cfg.perfect_start_lo, t)
	var hi := lerpf(cfg.perfect_end, cfg.perfect_end_lo, t)
	if aspect == "tempo" and _m("edge"):
		var mid := (lo + hi) * 0.5
		var half := (hi - lo) * 0.5 * cfg.edge_window_mult
		lo = mid - half
		hi = mid + half
	return [lo, hi]

# --- Venomancer POISON WHEEL: the lit lane (0=V, 1=F, 2=C) — the lane the NEXT Strike
#     feeds. A Strike stacks it then ADVANCES the wheel (riding V→F→C tops all three →
#     Toxic Synergy); Envenom stacks it WITHOUT advancing (fixate = over-stack a lane).
const WHEEL_KEYS := ["V", "F", "C"]
func _wheel(seat: Seat) -> int:
	return int(seat.vars.get("wheel", 0))
func _wheel_strike(s: CombatState, seat: Seat, perfect: bool) -> void:
	var lane := _wheel(seat)
	_apply_venom(seat, WHEEL_KEYS[lane], cfg.wheel_perfect_apply if perfect else cfg.wheel_strike_apply)
	if perfect and _b("contagion"):
		# Contagion: a Perfect also seeds a random OTHER lane — easier to keep all three live.
		var other := (lane + 1 + (1 if s.rng.next_float() < 0.5 else 0)) % 3
		_apply_venom(seat, WHEEL_KEYS[other], 1)
	seat.vars["wheel"] = (lane + 1) % 3

## The single outgoing-damage path: Flow multiplier, Execute relic, crit, then land.
## Poison ticks bypass this (they scale with neither Flow nor Execute — see _upkeep).
## `kind` tags the SOURCE for the view layer only (auto Strike vs a finisher/signature),
## so the HUD can colour non-auto-attacks distinctly — it never touches the checksum.
func _deal(s: CombatState, seat: Seat, raw: float, flow_scaled: bool, crit: bool,
		kind := "strike") -> float:
	var d := raw
	if flow_scaled:
		d *= _flow_mult(seat)
	if _b("execute") and s.boss.hp_max > 0.0 and s.boss.hp / s.boss.hp_max < 0.35:
		d *= 1.3
	if crit:
		d *= 2.0
	# THE OPENING: a dump landed in the boss's vulnerability window hits harder (graded
	# by how centred on the sweet spot). Strikes/perfects are NOT dumps — they keep their
	# own rhythm. All hits of a multi-hit dump (Flurry) share the same window.
	if _is_dump(kind):
		var ob := _opening_bonus(s, seat)
		if ob > 0.0:
			d *= (1.0 + ob)
	d = roundf(d)
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	if d > 0.0:
		CombatCore.meter_dmg(s, seat, StringName(kind), d, crit)
		# `seat` lets the RAID HUD tell your hits from an ally's (damage_boss already
		# carries seat); solo ignores it. View-only — never checksummed.
		CombatCore.emit_event(s, {"t": "boss_hit", "amt": int(d), "crit": crit, "kind": kind, "seat": seat})
	return d

func _poison_boss(s: CombatState, seat: Seat, dmg: float) -> void:
	var d := roundf(dmg)
	if d <= 0.0:
		return
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	CombatCore.meter_dmg(s, seat, &"poison", d)
	CombatCore.emit_event(s, {"t": "poison", "amt": int(d), "seat": seat})

# --------------------------------------------------------------------------
# THE OPENING — the offense-side timing verb. A telegraphed boss swing overextends
# it: the kit watches s.telegraph, stamps a vulnerability window around the impact
# tick into seat.vars (deterministic, no engine change), and your DUMPS punish it.
# --------------------------------------------------------------------------

const DUMP_KINDS := ["finisher", "coup", "rupture", "flurry"]

func _is_dump(kind: String) -> bool:
	return kind in DUMP_KINDS

## Called every upkeep tick: when a DEFENSIBLE single-swing telegraph appears, schedule
## its opening. Deferred while a previous window is still live so a fresh swing can't
## clobber an opening you're mid-punish on (boss cooldowns give the deferral room).
func _stamp_opening(s: CombatState, seat: Seat) -> void:
	if not cfg.open_enabled or s.telegraph == null:
		return
	var ab := s.telegraph.ability
	if ab.response != AbilityRes.Response.DEFENSIBLE or not ab.strikes.is_empty():
		return
	if int(seat.vars.get("open_tg", -999999)) == s.telegraph.start_tick:
		return
	if s.tick <= int(seat.vars.get("open_to", -1)):
		return
	var impact := s.telegraph.start_tick + s.telegraph.dur_ticks
	seat.vars["open_tg"] = s.telegraph.start_tick
	seat.vars["open_from"] = impact - _tt(s, cfg.open_pre_sec)
	seat.vars["open_to"] = impact + _tt(s, cfg.open_post_sec)
	seat.vars["open_peak"] = impact + _tt(s, cfg.open_peak_sec)
	seat.vars["open_size"] = int(ab.size)

## The graded damage bonus for a dump landing at s.tick: full open_bonus inside the core
## (sweet spot), tapering to open_min_bonus at the window edges, 0.0 outside the window.
func _opening_bonus(s: CombatState, seat: Seat) -> float:
	if not cfg.open_enabled:
		return 0.0
	var to := int(seat.vars.get("open_to", -1))
	if to < 0:
		return 0.0
	var frm := int(seat.vars.get("open_from", 0))
	if s.tick < frm or s.tick > to:
		return 0.0
	var peak := int(seat.vars.get("open_peak", frm))
	var core := _tt(s, cfg.open_core_sec)
	var dist: int = absi(s.tick - peak)
	if dist <= core:
		return cfg.open_bonus
	var half := (peak - frm) if s.tick <= peak else (to - peak)
	var span := maxf(1.0, float(half - core))
	var f := clampf((float(dist) - float(core)) / span, 0.0, 1.0)
	return lerpf(cfg.open_bonus, cfg.open_min_bonus, f)

## Fired once per dump (after it lands): diagnostics + the aspect kicker on a PEAK read
## (Tempo bank Flow, Venom stack the lit lane) + a view-only pop. The DAMAGE bonus itself
## already applied inside _deal — this is the feedback and the read-reward.
func _opening_note(s: CombatState, seat: Seat, kind: String) -> void:
	if not cfg.open_enabled:
		return
	var b := _opening_bonus(s, seat)
	if b <= 0.0:
		CombatCore._bump_diag(s, seat, "open_whiff")   # a dump with no opening to punish
		return
	var peak := b >= cfg.open_bonus - 0.0001
	CombatCore._bump_diag(s, seat, "open_peak" if peak else "open_hit")
	if peak:
		if aspect == "tempo":
			for _i in cfg.open_flow:
				_gain_flow(seat)
		elif aspect == "venomancer":
			_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], cfg.open_venom)
	CombatCore.emit_event(s, {"t": "opening", "grade": ("peak" if peak else "hit"),
		"player": seat.is_player, "kind": kind})

## Called once when a DUMP lands (Evis/Coup/Rupture/Flurry) — the Opening read-reward plus
## any equipped Module payoff (Deathmark detonation). Central "a dump landed" hook.
func _dump_landed(s: CombatState, seat: Seat, kind: String) -> void:
	_opening_note(s, seat, kind)
	_deathmark_detonate(s, seat)

## MODULE (The Deathmark): a dump cashes every stamped Mark for a burst, then clears them.
func _deathmark_detonate(s: CombatState, seat: Seat) -> void:
	if not _m("deathmark"):
		return
	var m := int(seat.vars.get("marks", 0))
	if m <= 0:
		return
	seat.vars["marks"] = 0
	_deal(s, seat, float(m) * cfg.mark_dmg, true, false, "detonate")
	CombatCore._bump_diag(s, seat, "detonate")
	CombatCore.emit_event(s, {"t": "detonate", "player": seat.is_player, "marks": m})

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
	# GEAR-1: LE CHAT's Bell — +30 starting energy, exactly once (gear-gated no-op).
	var bell := GearFx.bell_grant(seat)
	if bell > 0.0:
		_gain_energy(seat, bell)
	_gain_energy(seat, cfg.energy_regen * s.dt)
	# ARMORY (strong bell): the warm start hums — regen doubles for the first 10s.
	if GearFx.bell_live(s, seat):
		_gain_energy(seat, cfg.energy_regen * s.dt)
	# GEAR-2: Scratchpad — regen trebles while a long wind-up thinks.
	if GearFx.scratchpad_live(s, seat):
		_gain_energy(seat, cfg.energy_regen * s.dt * 2.0)
		if GearFx.flag_once(seat, &"scratchpad_pop"):
			GearFx.pop(s, seat, &"scratchpad")
	# Twin Step: the spent spare dodge charge returns after mod_step_recharge seconds.
	if _b("tfPropTwinStep") and int(seat.vars.get("dodge_spare", 1)) < 1 \
			and s.tick >= int(seat.vars.get("dodge_recharge_tick", 0)):
		seat.vars["dodge_spare"] = 1

	# CREED (Held Breath): the window lock expires here; Flow is frozen while it's active.
	if bool(seat.vars.get("window_locked", false)) and s.tick >= int(seat.vars.get("window_lock_until", 0)):
		seat.vars["window_locked"] = false

	# Flow decays toward 0 between Perfects (Virtuoso relic slows it 50%). Frozen while a
	# Held-Breath window lock is active.
	if _flow(seat) > 0 and not bool(seat.vars.get("window_locked", false)):
		var acc := int(seat.vars.get("flow_decay_acc", 0)) + 1
		var every := _tt(s, cfg.flow_decay_every * (1.5 if _b("virtuoso") else 1.0))
		if acc >= every:
			acc -= every
			seat.vars["flow"] = _flow(seat) - 1
		seat.vars["flow_decay_acc"] = acc

	if aspect == "venomancer":
		_tick_venom(s, seat)

	# THE OPENING: schedule a vulnerability window when the boss commits a swing.
	_stamp_opening(s, seat)

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
		_poison_boss(s, seat, dmg)

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
	GearFx.damage_taken(s, seat)   # GEAR-1: death procs (Swan Song) — gear-gated no-op
	if size != AbilityRes.Size.NONE and _flow(seat) > 0:
		if GearFx.once(seat, &"grace_period"):
			GearFx.pop(s, seat, &"grace_period")   # GEAR-2: the song survives one landed swing
		else:
			var before := _flow(seat)
			_creed_slip(s, seat)                   # REWORK: eating a swing is a SLIP (the Creed pays it)
			if _flow(seat) < before:
				CombatCore.emit_event(s, {"t": "flow_lost", "player": seat.is_player})

# --- GEAR-1: a boss self-heal was DENIED somewhere — Riftmaw Tooth pays energy ---
func on_boss_heal_denied(s: CombatState, seat: Seat) -> void:
	var g := GearFx.tooth_grant(s, seat)
	if g > 0.0:
		_gain_energy(seat, g)

## M7 string beats join the rhythm: a PERFECT dodge plays like a Perfect Strike
## (+1 Flow); a GOOD one pays a little energy; holding a feint keeps the song
## going. A LANDED beat wipes Flow through on_damage_taken above (beats carry a
## Size) — dodging protects the solo, exactly like dodging a swing does.
func on_strike_result(s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT:
			if aspect == "tempo":
				_gain_flow(seat)                   # a perfect dodge keeps the accelerando alive
			else:
				_gain_energy(seat, cfg.strike_good_energy)   # Venom has no Flow — footwork pays energy
			if _b("dancersgrace"):
				seat.vars["next_perfect"] = true   # Opus: a perfect dodge primes the blades
			if _b("tfTrigBeat"):
				_tf_trigger(s, seat, "beat")       # Phase B: PERFECT beat = proc moment
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

## Twin Step (Phase B): the engine just charged the dodge cooldown — a spare charge
## eats it, so a second step is available back-to-back; upkeep restores the spare.
func on_defense_press(s: CombatState, seat: Seat) -> void:
	if _b("tfPropTwinStep") and int(seat.vars.get("dodge_spare", 1)) > 0:
		seat.vars["dodge_spare"] = int(seat.vars.get("dodge_spare", 1)) - 1
		seat.defense_ready_tick = s.tick
		seat.vars["dodge_recharge_tick"] = s.tick + _tt(s, cfg.mod_step_recharge)

func on_negate(s: CombatState, seat: Seat, _ability: AbilityRes) -> void:
	if _b("dodgeCp"):
		_gain_cp(seat, 2)
	if _b("tfTrigEvade"):
		_tf_trigger(s, seat, "evade")      # Phase B: a clean dodge = proc moment

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
	if since < _tt(s, _swing_min_sec(seat)):
		return false                                   # too early — the press is dropped
	var cost := float(a["energy"])
	if aspect == "tempo" and _b("syncopation") and _flow(seat) >= max_flow():
		cost = 0.0
	if aspect == "venomancer" and int(seat.vars.get("encore_left", 0)) > 0:
		cost = maxf(0.0, cost - 6.0)                   # GEAR-2: Encore Bell (Venom side)
	if seat.resource < cost:
		return false                                   # out of energy
	# ACCELERANDO: the window bounds ride current Flow (Venom's Flow is pinned 0 → base).
	var lo := _tt(s, _perfect_lo_sec(seat))
	var hi := _tt(s, _perfect_hi_sec(seat))
	var perfect := since >= lo and since <= hi
	if not perfect and _b("tfPropWindow"):
		var pad := int(ceil(float(hi - lo) * cfg.mod_window_pad))
		perfect = since >= lo - pad and since <= hi + pad
	if _b("dancersgrace") and bool(seat.vars.get("next_perfect", false)):
		perfect = true                                 # Opus: the primed strike IS perfect
		seat.vars["next_perfect"] = false
	seat.resource -= cost
	if int(seat.vars.get("encore_left", 0)) > 0:       # the encore spends a beat per Strike
		seat.vars["encore_left"] = int(seat.vars["encore_left"]) - 1
	seat.vars["last_strike_tick"] = s.tick

	var base := float(a["dmg"])
	var cp := int(a["cp"])
	if perfect:
		CombatCore._bump_diag(s, seat, "perfect_strike")   # class-signature skill signal (token mint)
		base = roundf(base * 1.6 * (cfg.edge_perfect_mult if _m("edge") else 1.0))   # MODULE (Edge): bigger Perfects
		cp = 1                                             # REWORK: Perfect gives +1 combo, not +2 (wind-up, not spam)
		var crit := false
		if _b("fifthCrit"):
			var pc := int(seat.vars.get("perfect_count", 0)) + 1
			seat.vars["perfect_count"] = pc
			if pc % 5 == 0:
				crit = true
		_deal(s, seat, base, true, crit, "perfect")
		# REWORK: NO innate "every Perfect" proc — payloads fire only on earned moments (drafted triggers).
		CombatCore.emit_event(s, {"t": "perfect", "player": seat.is_player})
		if aspect == "tempo":
			_gain_flow(seat)                                                  # Flow = BPM (Tempo only)
			if _m("deathmark"):                                              # MODULE (Deathmark): stamp the boss
				seat.vars["marks"] = mini(int(seat.vars.get("marks", 0)) + 1, cfg.mark_cap)
			var t := flow_tier(seat)
			if t >= 1:
				_deal(s, seat, roundf(float(a["dmg"]) * 0.6), true, false, "perfect")   # Tier 1: extra hit
			if t >= 2:
				_gain_energy(seat, 6.0)                                       # Tier 2: energy refund (combo bonus removed)
		else:
			_wheel_strike(s, seat, true)                                     # ride the wheel (Perfect)
	else:
		_deal(s, seat, base, true, false)
		if aspect == "venomancer":
			_wheel_strike(s, seat, false)                                    # ride the wheel (normal)
		else:
			_creed_slip(s, seat)                                             # REWORK: a missed Perfect is a SLIP (Creed pays it)
	_gain_cp(seat, cp)
	if _b("strikeEnergy") and perfect:
		_gain_energy(seat, 6.0)
	# Tell the view HOW this strike landed so the rhythm bar can flash a clear, held
	# verdict — otherwise the bar instantly resets and reads "too early" on your next
	# cycle, which looks like it's judging the click you just nailed.
	var result := "perfect" if perfect else ("early" if since < lo else "late")
	CombatCore.emit_event(s, {"t": "strike", "player": seat.is_player, "result": result})
	return true

func _eviscerate(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["eviscerate"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	var per := float(a["per_cp"]) + (8.0 if _b("eviPlus") else 0.0)
	_deal(s, seat, per * float(cp), true, false, "finisher")
	seat.vars["cp"] = 0
	if _b("tfTrigSpender") and cp >= cfg.cp_max:
		_tf_trigger(s, seat, "spender")    # Phase B: a full-point finisher = proc moment
	_dump_landed(s, seat, "finisher")     # THE OPENING: read-reward if it hit the window
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
	# GEAR-1 (ARMORY strong): Powder Vial — the boot carries the toxin
	# (Venom: 3 stacks on the lit lane; Tempo: +2 Flow).
	if GearFx.has(seat, &"powder_vial"):
		if aspect == "venomancer":
			_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], 3)
		else:
			_gain_flow(seat)
			_gain_flow(seat)
		GearFx.pop(s, seat, &"powder_vial")
	return true

func _envenom(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["envenom"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	# FIXATE: over-stack the lit lane WITHOUT advancing the wheel (the "double-down" tool).
	_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], cp)
	seat.vars["cp"] = 0
	if _b("tfTrigSpender") and cp >= cfg.cp_max:
		_tf_trigger(s, seat, "spender")    # Phase B: a full-point finisher = proc moment
	CombatCore.emit_event(s, {"t": "finisher", "id": "envenom", "cp": cp})
	return true

func _flurry(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["flurry"]
	if seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	for _i in int(a["hits"]):
		_deal(s, seat, float(a["dmg"]), true, false, "flurry")
	_gain_cp(seat, int(a["cp"]))
	_dump_landed(s, seat, "flurry")       # THE OPENING (all three hits shared the window)
	return true

func _coup(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["coupdegrace"]
	if s.tick < int(seat.cooldowns.get("coupdegrace", 0)):
		return false
	if _flow(seat) < max_flow() or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["coupdegrace"] = s.tick + _tt(s, float(a["cd"]))
	# Damage rides the Flow you spend (via _deal's flow_mult) — then Coup CONSUMES it.
	_deal(s, seat, float(a["dmg"]) * (1.4 if _b("crescendo") else 1.0), true, false, "coup")
	seat.vars["flow"] = clampi(cfg.coup_flow_seed, 0, max_flow())   # ride vs spend: the spike costs your BPM
	seat.vars["flow_decay_acc"] = 0
	_gain_cp(seat, 3)                                    # refeeds combo → chain into Eviscerate
	_dump_landed(s, seat, "coup")                       # THE OPENING (fires after the Flow reset)
	CombatCore.emit_event(s, {"t": "coup", "player": seat.is_player})
	if GearFx.has(seat, &"encore_bell"):                 # GEAR-2: the bell rings after the finisher
		seat.vars["encore_left"] = 3
		GearFx.pop(s, seat, &"encore_bell")
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
	if GearFx.has(seat, &"encore_bell"):                 # GEAR-2: the bell rings after the finisher
		seat.vars["encore_left"] = 3
		GearFx.pop(s, seat, &"encore_bell")
	var per := float(a["per"]) * (1.4 if _b("rupturing") else 1.0)
	var v := _venom(seat)
	# Lingering Venom (boon): a SIP — a smaller detonation that keeps HALF the cocktail +
	# Synergy warm, so the engine never craters (sustain). Default = SLAM (full, zeroes it).
	var sip := _b("lingerVenom")
	_deal(s, seat, float(total) * per * float(v["syn_ramp"]) * (0.62 if sip else 1.0), true, false, "rupture")
	if sip:
		v["V"] = int(v["V"]) / 2; v["F"] = int(v["F"]) / 2; v["C"] = int(v["C"]) / 2
		v["fes_ticks"] = 0                                 # keep stacks + syn_ramp/syn_active warm
	else:
		v["V"] = 0; v["F"] = 0; v["C"] = 0
		v["fes_ticks"] = 0; v["syn_ramp"] = 1.0; v["syn_active"] = false
	_dump_landed(s, seat, "rupture")      # THE OPENING: detonate in the window for the spike
	CombatCore.emit_event(s, {"t": "rupture", "total": total, "sip": sip})
	return true

# ---------------------------------------------------------------- slot-verb Rhythm mods
# Phase B (build-your-Rhythm): the innate proc moment is every PERFECT Strike; TRIGGER
# pieces add moments, PAYLOAD pieces fire on every proc, PROPERTY pieces reshape the
# verb. NO LOCKOUTS. All _b()-gated — boonless sims stay byte-identical.

func _has_payloads() -> bool:
	return _b("tfPayLash") or _b("tfPayEnergy") or _b("tfPayLeech")

## A drafted trigger fired: built-in energy sip + one proc moment.
func _tf_trigger(s: CombatState, seat: Seat, source: String) -> void:
	_gain_energy(seat, cfg.mod_trig_energy)
	_rhythm_proc(s, seat, source)

## One proc moment: fire every drafted payload once (payLash is flat — not Flow-scaled).
func _rhythm_proc(s: CombatState, seat: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic
	if _b("tfPayLash"):
		_deal(s, seat, cfg.mod_lash, false, false)
	if _b("tfPayEnergy"):
		_gain_energy(seat, cfg.mod_energy)
	if _b("tfPayLeech"):
		# meter the effective slice as self-healing (HP behavior unchanged)
		var leech_eff := maxf(0.0, minf(seat.hp_max - seat.hp, cfg.mod_leech))
		seat.hp = clampf(seat.hp + cfg.mod_leech, 0.0, seat.hp_max)
		CombatCore.meter_heal(s, seat, &"red_harvest", leech_eff, cfg.mod_leech - leech_eff)
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player, "src": source})

# --------------------------------------------------------------------------
# Observation (policy + HUD). All view/AI fields — never part of the checksum.
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var last := int(seat.vars.get("last_strike_tick", -100000))
	var v: Dictionary = seat.vars.get("venom", {})
	var out := {
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
		# ACCELERANDO: the window the kit will judge THIS press against — flow-adjusted, so
		# the RhythmBar visibly compresses and the policy re-aims as Flow climbs (Venom = base).
		"swing_min_ticks": _tt(s, _swing_min_sec(seat)),
		"perfect_lo": _tt(s, _perfect_lo_sec(seat)),
		"perfect_hi": _tt(s, _perfect_hi_sec(seat)),
		"rhythm_scale": _tt(s, cfg.perfect_end + 0.15),   # FIXED ruler (flow-0 anchor + margin) so the RhythmBar shows the accelerando
		"strike_cost": float(cfg.abilities["strike"]["energy"]),
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
		"kick_ready": s.tick >= int(seat.cooldowns.get("kick", 0)),
		"coup_ready": aspect == "tempo" and _flow(seat) >= max_flow() \
			and s.tick >= int(seat.cooldowns.get("coupdegrace", 0)),
		"rupture_ready": aspect == "venomancer" and _venom_total(seat) >= 1 \
			and s.tick >= int(seat.cooldowns.get("rupture", 0)),
		"wheel": _wheel(seat),   # Venom poison wheel: 0=V 1=F 2=C, the lit (on-deck) lane
		"venom": {"V": int(v.get("V", 0)), "F": int(v.get("F", 0)), "C": int(v.get("C", 0)),
			"syn_ramp": float(v.get("syn_ramp", 1.0)), "syn_active": bool(v.get("syn_active", false))},
		"venom_total": _venom_total(seat),
	}
	# THE OPENING — the vulnerability window (absolute ticks; -1 once it has expired /
	# none scheduled). The policy times its dumps to open_peak; the HUD draws the bar.
	out["open_on"] = cfg.open_enabled   # off → the policy uses the classic dump logic
	var o_to := int(seat.vars.get("open_to", -1))
	if cfg.open_enabled and o_to >= s.tick:
		var o_from := int(seat.vars.get("open_from", 0))
		out["open_from"] = o_from
		out["open_peak"] = int(seat.vars.get("open_peak", o_from))
		out["open_to"] = o_to
		out["open_core_ticks"] = _tt(s, cfg.open_core_sec)
		out["open_size"] = int(seat.vars.get("open_size", 0))
		out["open_active"] = s.tick >= o_from
		out["open_bonus_now"] = _opening_bonus(s, seat)   # HUD: live grade of a dump RIGHT NOW
	else:
		out["open_from"] = -1
		out["open_peak"] = -1
		out["open_to"] = -1
		out["open_active"] = false
		out["open_bonus_now"] = 0.0

	# CREED + MODULES (Tempo rework) — for the HUD combo board / verdict pops / policy
	out["creed"] = creed_id
	out["creed_name"] = String(_creed().get("name", ""))
	out["flow_value"] = _creed_flow_value()
	out["window_locked"] = bool(seat.vars.get("window_locked", false))
	out["modules"] = modules.keys()
	out["edge"] = _m("edge")                                     # MODULE gauges for the HUD
	if _m("deathmark"):
		out["marks"] = int(seat.vars.get("marks", 0))
		out["marks_max"] = cfg.mark_cap

	if _b("tfPropTwinStep"):   # Twin Step charge pips (Phase B)
		out["guard_charges"] = int(seat.vars.get("dodge_spare", 1)) \
			+ (1 if s.tick >= seat.defense_ready_tick else 0)
		out["guard_charges_max"] = 2
	return out
