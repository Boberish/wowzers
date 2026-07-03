## BulwarkKit — the Tank class behaviour, ported from poc/bulwark.html. Handles both
## Aspects and the full draft pool: `boons` (a set of upgrade/relic ids) modifies the
## kit's behaviour throughout. Pure/deterministic.
class_name BulwarkKit
extends ClassKit

var aspect: String = "warden"          ## "warden" | "juggernaut"
var cfg: BulwarkConfig
var boons: Dictionary = {}             ## id -> true (acquired upgrades/relics)

func _init(_aspect: String, _cfg: BulwarkConfig) -> void:
	aspect = _aspect
	cfg = _cfg

func _b(id: String) -> bool:
	return bool(boons.get(id, false))

# effective (boon-modified) Momentum params
func _mom_max() -> int:
	return 14 if _b("unstoppable") else cfg.mom_max
func _mom_delay() -> float:
	return 3.6 if _b("snowball") else cfg.mom_delay
func _mom_decay_step() -> float:
	return 1.0 if _b("snowball") else cfg.mom_decay_step

# --- defensive params (propWide/propSwift are Phase-B Guard property mods) ---
func _def() -> Dictionary:
	return cfg.def_warden if aspect == "warden" else cfg.def_jugg
func defense_active() -> float:
	return _def()["active"] * (cfg.mod_wide_mult if _b("propWide") else 1.0)
func defense_cd() -> float:
	return _def()["cd"] * (cfg.mod_swift_mult if _b("propSwift") else 1.0)

func _tt(s: CombatState, seconds: float) -> int:
	return CombatCore.to_ticks(seconds, s.config.fixed_hz)

# --- per-tick upkeep: exposed-window flag + Juggernaut Momentum decay ---
func upkeep(s: CombatState, seat: Seat) -> void:
	# Duelist reward: correctly holding a Feint leaves the boss briefly Exposed.
	# Maintain a bool here so outgoing_mult (which has no tick) can read it.
	seat.vars["exposed"] = s.tick < int(seat.vars.get("exposed_until_tick", 0))
	# Sunder Guard (payExpose): its own per-seat Exposed window, same bool trick.
	# Guarded, so a run without the boon never writes the key → byte-identical.
	if _b("payExpose"):
		seat.vars["pay_exposed"] = s.tick < int(seat.vars.get("pay_expose_until", 0))
	# Twin Guard: the spent spare charge returns after mod_charge_recharge seconds.
	if _b("propCharge") and int(seat.vars.get("guard_spare", 1)) < 1 \
			and s.tick >= int(seat.vars.get("guard_recharge_tick", 0)):
		seat.vars["guard_spare"] = 1
	if aspect != "juggernaut":
		return
	var mo := int(seat.vars.get("momentum", 0))
	if mo <= 0:
		return
	# SUNDER floor: riding high Momentum slowly cracks the wall — the Juggernaut's sticky
	# FLOOR vs the Warden's parry SPIKES fill the same boss meter with different curves.
	if mo >= cfg.sunder_jugg_at:
		_crack(s, cfg.sunder_jugg_rate * s.dt)
	var since := float(s.tick - int(seat.vars.get("last_aggro_tick", 0))) * s.dt
	if since > _mom_delay():
		var acc := float(seat.vars.get("mom_decay_acc", 0.0)) + s.dt
		var step := _mom_decay_step()
		while acc >= step and mo > 0:
			acc -= step
			mo -= 1
		seat.vars["mom_decay_acc"] = acc
		seat.vars["momentum"] = mo

# --- defensive press: Juggernaut dumps (or halves) Momentum. Twin Guard (Phase B):
#     the engine just charged the base cooldown — a spare charge eats it, so a second
#     press is available back-to-back; the spare recharges via upkeep. A press that
#     gets BAITED still burns the spare (Twin Guard doesn't protect misreads). ---
func on_defense_press(s: CombatState, seat: Seat) -> void:
	if aspect == "juggernaut":
		var mo := int(seat.vars.get("momentum", 0))
		# OVERDRIVE: at cap the snowball is HOT — dodging no longer dumps it (the reward for
		# living at the redline, and the fix for "my own dodge kills my Momentum"). Below
		# cap, the greed tension stands: a dodge still costs the snowball (halved w/ sureFoot).
		if mo < _mom_max():
			seat.vars["momentum"] = int(mo / 2) if _b("sureFoot") else 0
	if _b("propCharge") and int(seat.vars.get("guard_spare", 1)) > 0:
		seat.vars["guard_spare"] = int(seat.vars.get("guard_spare", 1)) - 1
		seat.defense_ready_tick = s.tick
		seat.vars["guard_recharge_tick"] = s.tick + _tt(s, cfg.mod_charge_recharge)

# --- a defensible swing was negated. FEINT: the negate was a bait — punish it.
#     Otherwise: Warden reflects + banks Counter + Riposte. ---
func on_negate(s: CombatState, seat: Seat, _ability: AbilityRes) -> void:
	if _ability != null and _ability.feint:
		_feint_baited(s, seat)
		return
	CombatCore._bump_diag(s, seat, "negate")   # class-signature skill signal (token mint)
	_crack(s, cfg.sunder_parry)                # a won read cracks the boss's wall (SUNDER)
	if _b("retaliation") and _ability != null:
		CombatCore.damage_boss(s, seat, _ability.amount, &"retaliation")   # Opus: hurl the swing back
	if aspect == "warden":
		var refl := cfg.parry_reflect * (2.0 if _b("perfectReflect") else 1.0)
		CombatCore.damage_boss(s, seat, refl, &"parry")
		_gain_counter(seat, 2 if _b("deepCounter") else cfg.parry_counter)
		_gain_rage(seat, cfg.parry_rage)
		seat.vars["riposte_until_tick"] = s.tick + _tt(s, cfg.riposte_dur)
		if _b("riposteChain"):
			seat.defense_ready_tick = s.tick + _tt(s, 0.1)   # near-instant re-parry
	# Phase B: a clean negate is the Guard's INNATE proc moment; Rhythm of Iron
	# (trigThird) adds an extra proc every 3rd successful guard.
	if _b("trigThird"):
		var n := int(seat.vars.get("guard_count", 0)) + 1
		seat.vars["guard_count"] = n
		if n % 3 == 0:
			_trigger_fire(s, seat, "third")
	_guard_proc(s, seat, "negate")

# --- M7 string beats: grade payoffs. PERFECT = the riposte fantasy (Warden banks
#     Counter + opens the Riposte window; Jugg banks Momentum). BAITED wipes the
#     riposte window — the real cost is the dodge lockout eating the next beat.
#     READ mirrors the whole-swing feint hold, scaled down for a single beat. ---
func on_strike_result(s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT:
			_gain_rage(seat, cfg.strike_perfect_rage)
			_crack(s, cfg.sunder_beat)             # a perfect beat cracks the wall (SUNDER)
			if aspect == "warden":
				_gain_counter(seat, cfg.strike_perfect_counter)
				seat.vars["riposte_until_tick"] = s.tick + _tt(s, cfg.riposte_dur)
			else:
				_gain_momentum(s, seat, cfg.strike_perfect_momentum)
			if _b("trigBeat"):
				_trigger_fire(s, seat, "beat")     # Phase B: PERFECT beat = proc moment
		StrikeRes.Grade.GOOD:
			_gain_rage(seat, cfg.strike_good_rage)
			if aspect == "juggernaut":
				_gain_momentum(s, seat, 1)
		StrikeRes.Grade.BAITED:
			seat.vars["baits"] = int(seat.vars.get("baits", 0)) + 1   # sim diagnostic
			if aspect == "warden":
				seat.vars["riposte_until_tick"] = 0
		StrikeRes.Grade.READ:
			_gain_rage(seat, cfg.strike_read_rage)
			_crack(s, cfg.sunder_read)             # holding a feint beat cracks the wall (SUNDER)
			seat.vars["exposed_until_tick"] = maxi(int(seat.vars.get("exposed_until_tick", 0)),
				s.tick + _tt(s, cfg.strike_read_exposed))
			if _b("trigRead"):
				_trigger_fire(s, seat, "read")     # Phase B: a held feint beat = proc moment
		_:
			pass

# --- incoming damage: Fortify/Vindicate DR, then Juggernaut Momentum mitigation ---
func modify_incoming(s: CombatState, seat: Seat, dmg: float, _source: StringName, size: int) -> float:
	var d := dmg
	if s.tick < seat.dr_until_tick:
		d *= (1.0 - seat.dr)
	if aspect == "juggernaut":
		var mo := int(seat.vars.get("momentum", 0))
		var mit := mo * cfg.mom_dr
		if _b("overrun") and size == AbilityRes.Size.CRUSH and mo >= 8:
			mit += 0.40
		d *= (1.0 - clampf(mit, 0.0, cfg.mom_dr_cap))
	return d

# --- damage taken generates rage (all specs) and Momentum (Juggernaut) ---
func on_damage_taken(s: CombatState, seat: Seat, dmg: float, source: StringName, size: int) -> void:
	var fury := 1.3 if _b("furyGain") else 1.0
	_gain_rage(seat, roundf(dmg * cfg.rage_from_dmg * fury))
	# GUARD CHAIN: eating a heavy/crush you should have PARRIED drops the chain to HALF —
	# the streak you protect survives a mistake but punishes it. (A landed FEINT is a
	# correct HOLD, rewarded below, and never breaks the chain.)
	if aspect == "warden" and size >= AbilityRes.Size.HEAVY and not _is_feint(s, source):
		var c := int(seat.vars.get("counter", 0))
		if c > 0:
			seat.vars["counter"] = c / 2
			CombatCore.emit_event(s, {"t": "chain_break", "player": seat.is_player})
	if aspect == "juggernaut":
		var mg := 3 if (_b("bulldoze") and size >= AbilityRes.Size.HEAVY) else 1
		_gain_momentum(s, seat, mg)
	# Duelist: taking Feint damage means you correctly HELD (a parried feint is
	# negated → never reaches here). Reward the read: bonus rage + Exposed window.
	# Keyed off the ability's feint flag (not its id) so EVERY feint — heavy Feint
	# AND crush Bluff — pays out.
	# CO-OP CAVEAT: routed through on_damage_taken, which only fires when d > 0. Solo
	# Bulwark has no absorb, so this is always correct today; if a Mender ward ever
	# fully eats a feint's small hit in co-op, the hold reward would be skipped —
	# revisit via a resolution-time hook if/when tanks can carry absorbs.
	if _is_feint(s, source):
		_gain_rage(seat, cfg.feint_read_rage)
		_crack(s, cfg.sunder_read)   # reading a feint cracks the wall (SUNDER)
		if aspect == "warden":
			_gain_counter(seat, 1)   # a held feint is a WON READ → links the chain
		seat.vars["exposed_until_tick"] = s.tick + _tt(s, cfg.feint_exposed_dur)
		CombatCore.emit_event(s, {"t": "read", "player": seat.is_player})
		if _b("trigRead"):
			_trigger_fire(s, seat, "read")     # Phase B: a held whole-swing feint = proc moment

# Is this ability id a Feint? Reads the authoritative flag off the encounter data
# so the kit never has to hardcode which swings are feints.
func _is_feint(s: CombatState, id: StringName) -> bool:
	for ab in s.encounter.abilities:
		if ab.id == id:
			return ab.feint
	return false

# --- outgoing damage multiplier: Exposed (Duelist) + Juggernaut Momentum + Last Stand ---
func outgoing_mult(seat: Seat) -> float:
	var m := 1.0
	if bool(seat.vars.get("exposed", false)):
		m *= cfg.feint_exposed_mult
	if bool(seat.vars.get("pay_exposed", false)):     # Sunder Guard: +15% while Exposed
		m *= 1.0 + cfg.mod_expose_amt
	if aspect == "warden":
		m *= 1.0 + float(int(seat.vars.get("counter", 0))) * cfg.chain_dmg_per   # the CHAIN's teeth
	if aspect == "juggernaut":
		m *= 1.0 + float(int(seat.vars.get("momentum", 0))) * cfg.mom_dmg
	if _b("execute") and seat.hp_max > 0.0 and seat.hp / seat.hp_max < 0.35:
		m *= 1.35
	return m

# You pressed guard on a Feint. The bait connects: eat a chunk, lose your spec
# resource (Counter / Momentum), and your guard is disrupted for a beat.
func _feint_baited(s: CombatState, seat: Seat) -> void:
	seat.vars["baits"] = int(seat.vars.get("baits", 0)) + 1   # sim diagnostic
	seat.hp = maxf(0.0, seat.hp - cfg.feint_bait_dmg)
	if aspect == "warden":
		seat.vars["counter"] = 0
		seat.vars["riposte_until_tick"] = 0
	else:
		seat.vars["momentum"] = 0
		seat.vars["mom_decay_acc"] = 0.0
	seat.defense_ready_tick = maxi(seat.defense_ready_tick, s.tick + _tt(s, cfg.feint_lockout))

# --- abilities ---
func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	if String(id) == "challenge":
		return _challenge(s, seat)      # raid taunt — off-GCD (checked before the gate)
	if s.tick < seat.gcd_until_tick:
		return false
	match String(id):
		"vindicate":
			return _vindicate(s, seat)
		"avalanche":
			return _avalanche(s, seat)
		_:
			return _generic(s, seat, String(id))

## Challenge (raid-only taunt): force the boss onto you and jump the threat table.
## Off-GCD with its own cooldown, WoW-style. No solo loadout/policy ever presses it,
## and CombatCore.taunt() no-ops unless threat is enabled — solo stays byte-identical.
func _challenge(s: CombatState, seat: Seat) -> bool:
	if not s.threat_enabled:
		return false
	if s.tick < int(seat.cooldowns.get("challenge", 0)):
		return false
	CombatCore.taunt(s, seat)
	seat.cooldowns["challenge"] = s.tick + _tt(s, cfg.challenge_cd)
	seat.vars["taunts"] = int(seat.vars.get("taunts", 0)) + 1   # raid-sim diagnostic
	return true

func _generic(s: CombatState, seat: Seat, id: String) -> bool:
	var ab: Dictionary = cfg.abilities.get(id, {})
	if ab.is_empty():
		return false
	var cost := float(ab.get("cost", 0.0))
	if seat.resource < cost:
		return false
	seat.resource -= cost
	var dmg := float(ab.get("dmg", 0.0))
	if id == "rampage" and _b("rampagePlus"):
		dmg += 45.0
	var riposted := false
	if aspect == "warden" and s.tick < int(seat.vars.get("riposte_until_tick", 0)) \
			and (id == "cleave" or id == "rampage") and dmg > 0.0:
		dmg += cfg.riposte_bonus
		riposted = true
		seat.vars["riposte_until_tick"] = 0
		if _b("trigRiposte"):
			_trigger_fire(s, seat, "riposte")  # Phase B: a landed Riposte = proc moment
	if dmg > 0.0:
		CombatCore.damage_boss(s, seat, dmg, StringName(id))
	if ab.has("lifesteal"):
		_heal(s, seat, roundf(dmg * float(ab["lifesteal"])), &"lifesteal")
	if ab.has("heal"):
		_heal(s, seat, float(ab["heal"]), StringName(id))
	if ab.has("dr"):
		seat.dr = float(ab["dr"])
		seat.dr_until_tick = s.tick + _tt(s, float(ab["drDur"]))
		if _b("fortRage"):
			_gain_rage(seat, 20.0)
	if bool(ab.get("stagger", false)) and s.telegraph != null:
		CombatCore.stagger_boss(s)
	if id == "cleave":
		_gain_rage(seat, float(ab.get("rage", 0.0)))
	if riposted and _b("riposteHeal"):
		_heal(s, seat, 60.0, &"vengeful_guard")
	if aspect == "juggernaut" and dmg > 0.0:
		_gain_momentum(s, seat, 1)
	_set_gcd(s, seat, float(ab.get("gcd", cfg.gcd)), id)
	return true

func _vindicate(s: CombatState, seat: Seat) -> bool:
	var c := int(seat.vars.get("counter", 0))
	if c < 1:
		return false
	CombatCore.damage_boss(s, seat, cfg.vindicate_dmg_per * float(c), &"vindicate")
	seat.vars["counter"] = 0
	seat.dr = cfg.vindicate_dr
	seat.dr_until_tick = s.tick + _tt(s, cfg.vindicate_dr_dur)
	if _b("vindInterrupt") and s.telegraph != null:
		CombatCore.stagger_boss(s)
	_set_gcd(s, seat, cfg.gcd, "vindicate")
	return true

func _avalanche(s: CombatState, seat: Seat) -> bool:
	if seat.resource < cfg.avalanche_cost:
		return false
	var mo := int(seat.vars.get("momentum", 0))
	if mo < 1:
		return false
	seat.resource -= cfg.avalanche_cost
	var vent := mini(mo, cfg.avalanche_vent)   # PARTIAL vent — cash some for burst, keep riding
	var dealt := CombatCore.damage_boss(s, seat, cfg.avalanche_dmg_per * float(vent), &"avalanche")
	if _b("landslide"):
		_heal(s, seat, roundf(dealt * 0.4), &"landslide")
	if s.telegraph != null:
		CombatCore.stagger_boss(s)
	seat.vars["momentum"] = mo - vent
	seat.vars["last_aggro_tick"] = s.tick       # venting keeps the snowball hot (no instant decay)
	_set_gcd(s, seat, cfg.gcd, "avalanche")
	return true

func _set_gcd(s: CombatState, seat: Seat, gcd: float, id: String) -> void:
	var until := s.tick + _tt(s, gcd)
	seat.gcd_until_tick = until
	seat.cooldowns[id] = until

# ---------------------------------------------------------------- slot-verb Guard mods
# Phase B (build-your-Guard): TRIGGER pieces add proc moments, PAYLOAD pieces fire on
# EVERY proc moment (innate: any clean negate), PROPERTY pieces reshape the verb.
# NO LOCKOUTS — N triggers × M payloads all live. Everything _b()-gated: with no mods
# drafted these paths are inert and boonless sims stay byte-identical.

func _has_payloads() -> bool:
	return _b("payReflect") or _b("payHeal") or _b("payRage") \
		or _b("payCounter") or _b("payMomentum") or _b("payExpose")

## A drafted trigger fired: built-in rage sip (standalone value) + one proc moment.
func _trigger_fire(s: CombatState, seat: Seat, source: String) -> void:
	_gain_rage(seat, cfg.mod_trig_rage)
	_guard_proc(s, seat, source)

## One proc moment: fire every drafted payload once.
func _guard_proc(s: CombatState, seat: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["guard_procs"] = int(seat.vars.get("guard_procs", 0)) + 1   # probe diagnostic
	if _b("payReflect"):
		CombatCore.damage_boss(s, seat, cfg.mod_reflect, &"reflect")
	if _b("payHeal"):
		_heal(s, seat, cfg.mod_heal, &"warding_light")
	if _b("payRage"):
		_gain_rage(seat, cfg.mod_rage)
	if _b("payCounter") and aspect == "warden":
		_gain_counter(seat, 1)
	if _b("payMomentum") and aspect == "juggernaut":
		_gain_momentum(s, seat, 2)
	if _b("payExpose"):
		# PER-SEAT expose window (upkeep maintains the `pay_exposed` flag; outgoing_mult
		# applies +mod_expose_amt). NOT boss-level: those fields are the Voidcaller's
		# (its _deal reads them) — writing them here did nothing for a solo tank AND
		# would leak Expose to a co-op Voidcaller. This is the tank's own bonus.
		seat.vars["pay_expose_until"] = maxi(int(seat.vars.get("pay_expose_until", 0)),
			s.tick + _tt(s, cfg.mod_expose_dur))
	CombatCore.emit_event(s, {"t": "guard_proc", "player": seat.is_player, "src": source})

# --- resource helpers ---
func _gain_rage(seat: Seat, x: float) -> void:
	seat.resource = clampf(seat.resource + x, 0.0, seat.resource_max)
func _gain_counter(seat: Seat, x: int) -> void:
	seat.vars["counter"] = clampi(int(seat.vars.get("counter", 0)) + x, 0, cfg.counter_max)
func _gain_momentum(s: CombatState, seat: Seat, x: int) -> void:
	seat.vars["momentum"] = clampi(int(seat.vars.get("momentum", 0)) + x, 0, _mom_max())
	seat.vars["last_aggro_tick"] = s.tick
	seat.vars["mom_decay_acc"] = 0.0
## Kit self-heal: clamp to max AND meter the effective slice, credited to the seat
## itself — the HEALING column's "self-sustain vs the healer" answer. HP behavior
## unchanged; the meter is never checksummed.
func _heal(s: CombatState, seat: Seat, x: float, src: StringName) -> void:
	var eff := maxf(0.0, minf(seat.hp_max - seat.hp, x))
	seat.hp = clampf(seat.hp + x, 0.0, seat.hp_max)
	CombatCore.meter_heal(s, seat, src, eff, x - eff)

## SUNDER: crack the boss's wall. Every won read feeds it; while it's up the boss takes
## more from the whole team (co-op break-the-wall). Capped; decays fast in the engine.
func _crack(s: CombatState, amt: float) -> void:
	var before := s.boss.sunder
	s.boss.sunder = minf(s.config.sunder_max, s.boss.sunder + amt)
	if s.boss.sunder > before + 0.24:   # only pop the view on a meaningful chunk (not the jugg trickle)
		CombatCore.emit_event(s, {"t": "sunder", "amt": s.boss.sunder})

# --- observation for policies / HUD ---
func observe(s: CombatState, seat: Seat) -> Dictionary:
	var out := {
		"rage": seat.resource,
		"rage_max": seat.resource_max,
		"counter": int(seat.vars.get("counter", 0)),
		"counter_max": cfg.counter_max,
		"chain_bonus": float(int(seat.vars.get("counter", 0))) * cfg.chain_dmg_per if aspect == "warden" else 0.0,
		"momentum": int(seat.vars.get("momentum", 0)),
		"momentum_max": _mom_max(),
		"overdrive": aspect == "juggernaut" and int(seat.vars.get("momentum", 0)) >= _mom_max(),
		"sunder": s.boss.sunder,
		"sunder_max": s.config.sunder_max,
		"riposte_active": s.tick < int(seat.vars.get("riposte_until_tick", 0)),
		"aspect": aspect,
		"def_zone": _def()["zone"],
		"def_cd": _def()["cd"],
	}
	if s.threat_enabled:
		out["challenge_ready"] = s.tick >= int(seat.cooldowns.get("challenge", 0))
	if _b("propCharge"):   # Twin Guard: ready charges for the HUD's rune pips
		out["guard_charges"] = int(seat.vars.get("guard_spare", 1)) \
			+ (1 if s.tick >= seat.defense_ready_tick else 0)
		out["guard_charges_max"] = 2
	return out
