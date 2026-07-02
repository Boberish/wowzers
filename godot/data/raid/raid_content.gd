## Raid content (R0 — see RAID-PLAN.md): the first ENSEMBLE encounter. Four
## FULL-fidelity seats of different classes — Bulwark tank, Mender healer,
## Twinfang + Voidcaller dps — against one raid boss, in a single CombatState with
## threat/taunt enabled. Every kit/config pairing is exactly the solo one; the only
## new rules are threat targeting and the role-extinction loss line.
##
## Boss exam coverage (one mechanic per raid verb):
##  - melee chip + Riftmaw Crush / Rending Talon → the TANK parries (threat target)
##  - Devouring Chant (interruptible self-heal)  → the VOIDCALLER kicks it
##  - Rift Cataclysm (raid nova) + chip          → the MENDER out-heals it
##  - Void Volley (3-beat aoe string)            → EVERYONE dodges, personally
##  - Baleful Curse (THREAT_DROP)                → the boss turns on a dps; the tank
##    must CHALLENGE (taunt) it back — the threat system's reason to exist
##  - enrage 90s                                 → the dps race underneath it all
class_name RaidContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # unused (all seats are full-fidelity, dps = 0)
	c.enrage_base = 12.0
	return c

# --- boss ability builders ---

static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float, danger: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Tank Swing"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.response = AbilityRes.Response.DEFENSIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = danger; a.size = size
	return a

static func _chant(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Devour"
	a.effect = AbilityRes.Effect.HEAL_BOSS; a.amount = amount
	a.response = AbilityRes.Response.INTERRUPTIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true
	return a

static func _nova(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Raid AoE"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _dot(id: StringName, name: String, tick: float, dur: float, targets: int,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Curse"
	a.effect = AbilityRes.Effect.DOT_RANDOM
	a.dot_tick = tick; a.dot_every = 1.5; a.dot_dur = dur; a.dot_targets = targets
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _curse(id: StringName, name: String, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Threat Drop"
	a.effect = AbilityRes.Effect.THREAT_DROP
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _barrage(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Barrage"
	a.effect = AbilityRes.Effect.DMG_ALL          # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.aoe = true
		a.strikes.append(st)
	return a

static func make_riftmaw() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"riftmaw"; e.name = "Vorathek, the Riftmaw"; e.hp = 13500
	e.intro = "The first raid Seal. Hold its gaze, kick the Chant, dodge the Volley, out-heal the rest — and when the Curse makes it forget you, take its eyes back."
	e.melee = {"every": 1.1, "min": 30.0, "max": 42.0}
	e.enrage_at = 75.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.2
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"crush", "Riftmaw Crush", AbilityRes.Size.CRUSH, 160.0, 2.5, 12.0, 2.0, true),
		_swing(&"rend", "Rending Talon", AbilityRes.Size.HEAVY, 80.0, 1.8, 9.0, 2.0, false),
		_chant(&"chant", "Devouring Chant", 450.0, 2.0, 9.0, 2.0),
		_nova(&"cataclysm", "Rift Cataclysm", 30.0, 2.0, 11.0, 2.0),
		_curse(&"curse", "Baleful Curse", 1.5, 18.0, 3.0),
		_dot(&"riftrot", "Riftrot", 9.0, 9.0, 2, 1.6, 13.0, 2.0),
		_barrage(&"volley", "Void Volley", 60.0, 2.4, 14.0, 2.0, [
			{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

static func run_encounters() -> Array:
	return [make_riftmaw()]

# --- seats (each is the solo factory's seat, minus is_player, plus a name) ---

static func _tank(aspect: String) -> Seat:
	var bcfg := BulwarkConfig.new()
	var u := Seat.new()
	u.role = "tank"; u.unit_name = "The Bulwark"; u.fidelity = "full"
	u.hp_max = bcfg.hp_max; u.hp = bcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = bcfg.rage_max
	u.kit = BulwarkKit.new(aspect, bcfg)
	u.policy = RaidTankPolicy.new()
	u.vars = {"counter": 0, "momentum": 0, "mom_decay_acc": 0.0,
		"last_aggro_tick": 0, "riposte_until_tick": 0}
	return u

static func _blade(aspect: String) -> Seat:
	var tcfg := TwinfangConfig.new()
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Twinfang"; u.fidelity = "full"
	u.hp_max = tcfg.hp_max; u.hp = tcfg.hp_max; u.dps = 0.0
	u.resource = tcfg.energy_max; u.resource_max = tcfg.energy_max
	u.kit = TwinfangKit.new(aspect, tcfg)
	u.policy = TwinfangPolicy.new()
	u.vars = {"flow": 0, "cp": 0, "flow_decay_acc": 0, "last_strike_tick": -100000,
		"perfect_count": 0}
	if aspect == "venomancer":
		u.vars["venom"] = TwinfangKit.new_venom()
	return u

static func _caster(aspect: String) -> Seat:
	var vcfg := VoidcallerConfig.new()
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Voidcaller"; u.fidelity = "full"
	u.hp_max = vcfg.hp_max; u.hp = vcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = vcfg.focus_max
	u.kit = VoidcallerKit.new(aspect, vcfg)
	u.policy = VoidcallerPolicy.new()
	u.vars = {"backlash": 0, "next_instant": false, "kicks": 0}
	return u

static func _mender(aspect: String) -> Seat:
	var mcfg := MenderConfig.new()
	var u := Seat.new()
	u.role = "healer"; u.unit_name = "The Mender"; u.fidelity = "full"
	u.hp_max = 200.0; u.hp = 200.0; u.dps = 0.0
	u.resource = mcfg.mana_max; u.resource_max = mcfg.mana_max
	u.kit = MenderKit.new(aspect, mcfg)
	u.policy = MenderPolicy.new()
	u.vars = {"reservoir": 0.0, "nerve": 0.0, "regen_mult": 1.0}
	return u

## Build a raid fight. `aspects` may override any seat's Aspect; `player` names the
## human seat ("tank"/"blade"/"caster"/"healer") for diag mirroring — every seat is
## policy-driven until a driver swaps a human adapter in (R1).
## Seat order puts the tank first among targetable seats, so the boss opens on it
## before anyone has threat (the pull).
static func make_state(seed: int, enc: EncounterRes, aspects: Dictionary = {},
		player: String = "tank") -> CombatState:
	var s := CombatCore.create_state(enc, make_config(), seed)
	var seats := {
		"tank": _tank(String(aspects.get("tank", "warden"))),
		"blade": _blade(String(aspects.get("blade", "venomancer"))),
		"caster": _caster(String(aspects.get("caster", "disruptor"))),
		"healer": _mender(String(aspects.get("healer", "tidecaller"))),
	}
	if seats.has(player):
		(seats[player] as Seat).is_player = true
	s.seats = [seats["tank"], seats["blade"], seats["caster"], seats["healer"]]
	s.loss_mode = "raid"
	s.threat_enabled = true
	return s
