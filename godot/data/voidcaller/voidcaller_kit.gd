## VoidcallerKit — the Caster DPS class behaviour, ported from poc/voidcaller.html.
## Focus + a player cast bar (Fracture, with pushback) + the interrupt verb (Space, its
## own cooldown) + both Aspects (Disruptor Backlash/Overload, Silencer Silence/Exposed/
## Quietus). `boons` (drafted ids) modify behaviour throughout.
##
## The interrupt reuses the engine's defensive-verb plumbing: defense_cd() = the interrupt
## cooldown, and on_defense_press() does the kick — so a whiffed panic-kick still burns the
## cooldown (faithful). Silence/Empower/Expose live on BossState (generic, default no-ops).
##
## Fixed leak (fix-not-port): the prototype's resolveCast added a fresh GCD after a *cast*
## (the `/* instant path */` line leaked), making Fracture sluggish. Here a cast occupies
## the GCD for its duration and hands control back immediately — the commented intent.
class_name VoidcallerKit
extends ClassKit

var aspect: String = "disruptor"       ## "disruptor" | "silencer"
var cfg: VoidcallerConfig
var boons: Dictionary = {}

func _init(_aspect: String, _cfg: VoidcallerConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

# --------------------------------------------------------------------------
# The interrupt verb — mapped onto the engine's defensive press.
# --------------------------------------------------------------------------

func defense_active() -> float:
	return 0.1                                       # unused (no DEFENSIBLE swings for a caster)

func defense_cd() -> float:
	return cfg.int_cd_snap if _b("quickint") else cfg.int_cd

func on_defense_press(s: CombatState, seat: Seat) -> void:
	# Twin Void (Phase B): the engine just charged the kick cooldown — a spare charge
	# eats it (even on a whiff — faithful to the whiffed-kick-burns-cd rule).
	if _b("vcPropTwinVoid") and int(seat.vars.get("kick_spare", 1)) > 0:
		seat.vars["kick_spare"] = int(seat.vars.get("kick_spare", 1)) - 1
		seat.defense_ready_tick = s.tick
		seat.vars["kick_recharge_tick"] = s.tick + _tt(s, cfg.mod_void_recharge)
	_do_interrupt(s, seat, "space")

## Interrupt the boss's current cast. `source` is "space" or an interrupt-spell id.
func _do_interrupt(s: CombatState, seat: Seat, source: String) -> void:
	if s.telegraph == null or s.telegraph.ability.response != AbilityRes.Response.INTERRUPTIBLE:
		if source == "space":
			# GEAR-2: the WHIFF counts for oath deeds whether or not gear saves the
			# cooldown (diag-only); Grace Period hands the wasted press back once.
			CombatCore._bump_diag(s, seat, "kick_whiff")
			if GearFx.once(seat, &"grace_period"):
				seat.defense_ready_tick = s.tick
				GearFx.pop(s, seat, &"grace_period")
		CombatCore.emit_event(s, {"t": "int_whiff", "player": seat.is_player})
		return
	var rem := float(s.telegraph.start_tick + s.telegraph.dur_ticks - s.tick) * s.dt
	var clean := rem <= cfg.clean_zone * (cfg.mod_zone_mult if _b("vcPropZone") else 1.0)
	var was_heal := s.telegraph.ability.effect == AbilityRes.Effect.HEAL_BOSS
	var denied_heal := float(s.telegraph.ability.amount) if was_heal else 0.0
	CombatCore.stagger_boss(s)                        # cancels the cast (emits "staggered")
	seat.vars["kicks"] = int(seat.vars.get("kicks", 0)) + 1
	if clean:
		CombatCore._bump_diag(s, seat, "clean_kick")  # class-signature skill signal (token mint)
	if _b("nullbrand") and clean:
		_apply_silence(s, 1.5, 0.0)                   # Opus: clean kicks brand a Silence
	if _b("voidfeast") and was_heal:
		_deal(s, seat, roundf(denied_heal * 0.5), &"voidfeast")   # Opus: the denied heal strikes back
	_heal(s, seat, cfg.int_heal, &"kick_heal")

	if source == "space":
		if aspect == "disruptor":
			var dmg := (cfg.bl_dmg_clean if clean else cfg.bl_dmg) * (1.4 if _b("punish") else 1.0)
			_deal(s, seat, dmg, &"kick")
			# GEAR-2: Echo Chamber — a clean kick at an already-FULL bank echoes a
			# free 0.6x Overload without spending the stacks (the full-bank rider).
			if GearFx.has(seat, &"echo_chamber") and clean \
					and int(seat.vars.get("backlash", 0)) >= cfg.backlash_max:
				_deal(s, seat, cfg.overload_per_bl * float(cfg.backlash_max) * 0.6, &"echo_chamber")
				GearFx.pop(s, seat, &"echo_chamber")
			_gain_backlash(seat, 2 if clean else 1)
			if _b("backdot"):
				seat.vars["boss_dot"] = {"until_tick": s.tick + _tt(s, 4.0), "dps": 14.0}
		else:
			var dur := (cfg.sil_dur_clean if clean else cfg.sil_dur) * (1.4 if _b("longsil") else 1.0)
			_apply_silence(s, dur, cfg.expose_amt * (1.5 if _b("deepexpose") else 1.0))
			if _b("silheal"):
				_heal(s, seat, 30.0, &"reprieve")
		if _b("refund") and clean:                    # clean kick refunds half its cooldown
			seat.defense_ready_tick = s.tick + _tt(s, defense_cd() * 0.5)
		if GearFx.once(seat, &"spark_plug"):          # GEAR-1: first kick refunds half its cd
			seat.defense_ready_tick = s.tick + _tt(s, defense_cd() * 0.5)
			GearFx.pop(s, seat, &"spark_plug")
	else:
		var a: Dictionary = cfg.abilities[source]
		if a.has("reflect"):
			_deal(s, seat, float(a["reflect"]), StringName(source))
		if bool(a.get("silences", false)):
			_apply_silence(s, cfg.sil_spell_dur, cfg.expose_amt if aspect == "silencer" else 0.0)
		if aspect == "disruptor":
			_gain_backlash(seat, 1)
	# Phase B: a landed kick is the innate proc moment; CLEAN/DENY triggers add more.
	_kick_proc(s, seat, "kick")
	if _b("vcTrigClean") and clean:
		_vc_trigger(s, seat, "clean")
	if _b("vcTrigDeny") and was_heal:
		_vc_trigger(s, seat, "deny")
	CombatCore.emit_event(s, {"t": "interrupt", "player": seat.is_player, "clean": clean, "was_heal": was_heal})

func _apply_silence(s: CombatState, dur_sec: float, expose: float) -> void:
	var until := s.tick + _tt(s, dur_sec)
	s.boss.silenced_until_tick = maxi(s.boss.silenced_until_tick, until)
	s.boss.exposed_until_tick = maxi(s.boss.exposed_until_tick, until)
	s.boss.expose_amt = maxf(s.boss.expose_amt, expose)
	CombatCore.emit_event(s, {"t": "silence", "dur": dur_sec, "expose": expose})

# --------------------------------------------------------------------------
# Damage / focus / resource helpers
# --------------------------------------------------------------------------

## Player damage to the boss, scaled by Exposed (Silencer). Routes through the engine's
## damage_boss (outgoing_mult stays 1.0 for the caster).
func _deal(s: CombatState, seat: Seat, raw: float, src: StringName = &"attack") -> float:
	var m := 1.0
	if s.boss.exposed_until_tick >= 0 and s.tick < s.boss.exposed_until_tick:
		m *= (1.0 + s.boss.expose_amt)
	return CombatCore.damage_boss(s, seat, raw * m, src)

func _gain_focus(seat: Seat, x: float) -> void:
	seat.resource = clampf(seat.resource + x, 0.0, cfg.focus_max)

func _gain_backlash(seat: Seat, n: int) -> void:
	seat.vars["backlash"] = clampi(int(seat.vars.get("backlash", 0)) + n, 0, cfg.backlash_max)

## Kit self-heal: clamp to max AND meter the effective slice, credited to the seat
## itself (the HEALING column's "self-sustain vs the healer" answer). HP behavior
## unchanged; the meter is never checksummed.
func _heal(s: CombatState, seat: Seat, x: float, src: StringName) -> void:
	var eff := maxf(0.0, minf(seat.hp_max - seat.hp, x))
	seat.hp = clampf(seat.hp + x, 0.0, seat.hp_max)
	CombatCore.meter_heal(s, seat, src, eff, x - eff)

## M7 string beats: clean footwork feeds the cast engine — a PERFECT dodge grants
## Focus, a held feint a little too. (A LANDED beat already punishes through
## on_damage_taken: it pushes your Fracture back.)
func on_strike_result(_s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT:
			_gain_focus(seat, cfg.strike_perfect_focus)
			if _b("vcTrigBeat"):
				_vc_trigger(_s, seat, "beat")   # Phase B: PERFECT beat = proc moment
		StrikeRes.Grade.READ:
			_gain_focus(seat, cfg.strike_read_focus)
		_:
			pass

# --------------------------------------------------------------------------
# Per-tick upkeep: resolve the player's cast + tick the Backlash Burn DoT.
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	# GEAR-1: LE CHAT's Bell — +30 starting focus, exactly once (gear-gated no-op).
	var bell := GearFx.bell_grant(seat)
	if bell > 0.0:
		_gain_focus(seat, bell)
	# GEAR-2: Scratchpad — focus trickles in while a long wind-up thinks.
	if GearFx.scratchpad_live(s, seat):
		_gain_focus(seat, 4.0 * s.dt)
		if GearFx.flag_once(seat, &"scratchpad_pop"):
			GearFx.pop(s, seat, &"scratchpad")
	# Twin Void: the spent spare kick charge returns after mod_void_recharge seconds.
	if _b("vcPropTwinVoid") and int(seat.vars.get("kick_spare", 1)) < 1 \
			and s.tick >= int(seat.vars.get("kick_recharge_tick", 0)):
		seat.vars["kick_spare"] = 1
	if not seat.casting.is_empty():
		var c := seat.casting
		if s.tick - int(c["start_tick"]) >= int(c["dur_ticks"]):
			var id: String = c["id"]
			seat.casting = {}
			_resolve_cast(s, seat, id, false)
	if seat.vars.has("boss_dot"):
		var d: Dictionary = seat.vars["boss_dot"]
		if s.tick < int(d["until_tick"]):
			s.boss.hp = maxf(0.0, s.boss.hp - float(d["dps"]) * s.dt)
			CombatCore.meter_dmg(s, seat, &"void_dot", float(d["dps"]) * s.dt, false, false)
		else:
			seat.vars.erase("boss_dot")

# --------------------------------------------------------------------------
# Incoming damage: Barrier DR + Fracture pushback.
# --------------------------------------------------------------------------

func modify_incoming(_s: CombatState, seat: Seat, dmg: float, _source: StringName, _size: int) -> float:
	if _s.tick < seat.dr_until_tick:
		return dmg * (1.0 - seat.dr)
	return dmg

func on_damage_taken(s: CombatState, seat: Seat, _dmg: float, _source: StringName, _size: int) -> void:
	GearFx.damage_taken(s, seat)   # GEAR-1: death procs (Swan Song) — gear-gated no-op
	if seat.casting.is_empty():
		return
	var c := seat.casting                             # pushback, capped at cast+push_cap
	var max_dur := _tt(s, cfg.fracture_cast + cfg.push_cap)
	c["dur_ticks"] = mini(int(c["dur_ticks"]) + _tt(s, cfg.pushback), max_dur)
	c["pushed"] = true
	seat.gcd_until_tick = int(c["start_tick"]) + int(c["dur_ticks"])

# --- GEAR-1: a boss self-heal was DENIED somewhere — Riftmaw Tooth pays focus ---
func on_boss_heal_denied(s: CombatState, seat: Seat) -> void:
	var g := GearFx.tooth_grant(s, seat)
	if g > 0.0:
		_gain_focus(seat, g)
	CombatCore.emit_event(s, {"t": "pushback", "player": seat.is_player})

# --------------------------------------------------------------------------
# Abilities
# --------------------------------------------------------------------------

func _can_act(s: CombatState, seat: Seat) -> bool:
	return seat.casting.is_empty() and s.tick >= seat.gcd_until_tick

func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	var key := String(id)
	if not _can_act(s, seat):
		return false
	match key:
		"overload":     return _overload(s, seat)
		"quietus":      return _quietus(s, seat)
		"silence", "counterspell": return _int_spell(s, seat, key)
		_:              return _cast_ability(s, seat, key)

func _cast_ability(s: CombatState, seat: Seat, id: String) -> bool:
	var a: Dictionary = cfg.abilities.get(id, {})
	if a.is_empty():
		return false
	var cost := float(a.get("cost", 0.0))
	if cost > 0.0 and seat.resource < cost:
		return false
	if a.has("cd") and s.tick < int(seat.cooldowns.get(id, 0)):
		return false
	if cost > 0.0:
		seat.resource -= cost
	_start_cast(s, seat, id)
	return true

func _start_cast(s: CombatState, seat: Seat, id: String) -> void:
	var a: Dictionary = cfg.abilities[id]
	var instant := bool(a.get("instant", false)) or (id == "fracture" and bool(seat.vars.get("next_instant", false)))
	if id == "fracture" and bool(seat.vars.get("next_instant", false)):
		seat.vars["next_instant"] = false
	if instant:
		_resolve_cast(s, seat, id, true)
		return
	var dur := _tt(s, float(a["cast"]))
	seat.casting = {"id": id, "start_tick": s.tick, "dur_ticks": dur, "pushed": false}
	seat.gcd_until_tick = s.tick + dur                # the cast occupies the GCD
	CombatCore.emit_event(s, {"t": "cast_started", "id": id, "dur": float(a["cast"])})

func _resolve_cast(s: CombatState, seat: Seat, id: String, instant: bool) -> void:
	var a: Dictionary = cfg.abilities[id]
	var dmg := float(a.get("dmg", 0.0))
	if id == "fracture" and _b("fracplus"):
		dmg += 30.0
	if dmg > 0.0:
		_deal(s, seat, dmg, StringName(id))
	if a.has("focus"):
		_gain_focus(seat, float(a["focus"]))
	if a.has("dr"):
		seat.dr = float(a["dr"])
		seat.dr_until_tick = s.tick + _tt(s, float(a["dr_dur"]))
	if instant:
		seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	if a.has("cd"):
		seat.cooldowns[id] = s.tick + _tt(s, float(a["cd"]))
	CombatCore.emit_event(s, {"t": "cast_finished", "id": id})

func _overload(s: CombatState, seat: Seat) -> bool:
	var bl := int(seat.vars.get("backlash", 0))
	if bl < 1:
		return false
	_deal(s, seat, cfg.overload_per_bl * float(bl), &"overload")
	seat.vars["backlash"] = 0
	seat.vars["next_instant"] = true                  # next Fracture is instant
	if _b("overfocus"):
		_gain_focus(seat, 20.0)
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	CombatCore.emit_event(s, {"t": "overload", "bl": bl})
	return true

func _quietus(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["quietus"]
	if s.tick < int(seat.cooldowns.get("quietus", 0)) or seat.resource < float(a["cost"]):
		return false
	seat.resource -= float(a["cost"])
	if s.telegraph != null and s.telegraph.ability.response == AbilityRes.Response.INTERRUPTIBLE:
		CombatCore.stagger_boss(s)                    # also cancels the current cast
	_apply_silence(s, cfg.quietus_sil, cfg.quietus_expose)
	seat.cooldowns["quietus"] = s.tick + _tt(s, float(a["cd"]))
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	CombatCore.emit_event(s, {"t": "quietus", "player": seat.is_player})
	return true

func _int_spell(s: CombatState, seat: Seat, id: String) -> bool:
	var a: Dictionary = cfg.abilities[id]
	if s.tick < int(seat.cooldowns.get(id, 0)):
		return false
	seat.cooldowns[id] = s.tick + _tt(s, float(a["cd"]))   # cd + gcd spent even on a whiff
	seat.gcd_until_tick = s.tick + _tt(s, cfg.gcd)
	_do_interrupt(s, seat, id)
	return true

# ---------------------------------------------------------------- slot-verb Kick mods
# Phase B (build-your-Kick): the innate proc moment is every LANDED interrupt; TRIGGER
# pieces add moments, PAYLOAD pieces fire on every proc, PROPERTY pieces reshape the
# verb. NO LOCKOUTS. All _b()-gated — boonless sims stay byte-identical.

func _has_payloads() -> bool:
	return _b("vcPayVoid") or _b("vcPayFocus") or _b("vcPayMend")

## A drafted trigger fired: built-in focus sip + one proc moment.
func _vc_trigger(s: CombatState, seat: Seat, source: String) -> void:
	_gain_focus(seat, cfg.mod_trig_focus)
	_kick_proc(s, seat, source)

## One proc moment: fire every drafted payload once (payVoid rides Exposed via _deal).
func _kick_proc(s: CombatState, seat: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic
	if _b("vcPayVoid"):
		_deal(s, seat, cfg.mod_void, &"null_lash")
	if _b("vcPayFocus"):
		_gain_focus(seat, cfg.mod_focus)
	if _b("vcPayMend"):
		_heal(s, seat, cfg.mod_mend, &"umbral_mending")
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player, "src": source})

# --------------------------------------------------------------------------
# Observation (policy + HUD)
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var out := {
		"tick": s.tick,
		"aspect": aspect,
		"focus": seat.resource,
		"focus_max": cfg.focus_max,
		"backlash": int(seat.vars.get("backlash", 0)),
		"backlash_max": cfg.backlash_max,
		"next_instant": bool(seat.vars.get("next_instant", false)),
		"casting": seat.casting,
		"clean_zone": cfg.clean_zone,
		"barrier_ready": s.tick >= int(seat.cooldowns.get("barrier", 0)),
		"barrier_active": s.tick < seat.dr_until_tick,
		"quietus_ready": s.tick >= int(seat.cooldowns.get("quietus", 0)),
		"boss_silenced": s.tick < s.boss.silenced_until_tick,
		"boss_exposed": s.boss.exposed_until_tick >= 0 and s.tick < s.boss.exposed_until_tick,
		"expose_amt": s.boss.expose_amt if (s.boss.exposed_until_tick >= 0 and s.tick < s.boss.exposed_until_tick) else 0.0,
		"silence_left": maxf(0.0, float(s.boss.silenced_until_tick - s.tick) * s.dt),
		"dmg_buff": s.boss.dmg_buff,
		"kicks": int(seat.vars.get("kicks", 0)),
	}
	if _b("vcPropTwinVoid"):   # Twin Void charge pips (Phase B)
		out["guard_charges"] = int(seat.vars.get("kick_spare", 1)) \
			+ (1 if s.tick >= seat.defense_ready_tick else 0)
		out["guard_charges_max"] = 2
	return out
