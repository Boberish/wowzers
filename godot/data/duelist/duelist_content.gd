## DuelistContent — the party + encounters THE DUELIST (the dodge tank) trains and sims against
## (the tank + 3 statblock DPS burning a boss that pressures the tank so there is a bar-stream to
## answer AND an HP bar to end). Built in code; used by duelist_sim (S3) and RunState.start_duelist.
## Mirrors the WellContent idiom. The raid seat factory lives in RaidContent._tank (the registry's
## make_seat); this file owns the SOLO/sim tank + the training bosses.
class_name DuelistContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 12.0
	return c

static func make_duelist_config() -> DuelistConfig:
	return DuelistConfig.new()

# --- boss ability builders (tank-facing: melee chip + busters + barrages) ---
static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float, danger: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Swing"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.response = AbilityRes.Response.DEFENSIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = danger; a.size = size
	return a

static func _barrage(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Barrage"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.feint = bool(b.get("feint", false))
		st.aoe = true
		a.strikes.append(st)
	return a

## MELEE fight: dense chip + frequent HEAVY busters — trains the dodge rhythm + parry timing.
static func make_dense() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"dense"; e.name = "The Sparring Golem"; e.hp = 9000
	e.intro = "Dense footwork: constant chip, frequent swings. Dodge the stream, parry the big ones."
	e.melee = {"every": 1.0, "min": 20.0, "max": 28.0}
	e.enrage_at = 150.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.15; p1.speed = 1.1
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"jab", "Jab", AbilityRes.Size.HEAVY, 90.0, 1.4, 6.0, 1.5, false),
		_swing(&"hook", "Overhand Hook", AbilityRes.Size.CRUSH, 150.0, 2.0, 9.0, 2.0, true),
		_barrage(&"flurry", "Flurry", 66.0, 2.4, 12.0, 2.0, [
			{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## SPIKE fight: lighter chip, BIGGER telegraphed swings — trains the parry (the big-bar commit).
static func make_spike() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"spike"; e.name = "The Siege Ram"; e.hp = 8400
	e.intro = "Big, slow, telegraphed. Read the swing, commit the parry, hit back."
	e.melee = {"every": 1.5, "min": 12.0, "max": 18.0}
	e.enrage_at = 165.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.25; p1.speed = 1.12
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"ram", "Ram", AbilityRes.Size.CRUSH, 180.0, 2.6, 8.0, 2.0, true),
		_swing(&"gore", "Gore", AbilityRes.Size.HEAVY, 100.0, 1.8, 10.0, 2.0, false),
	]
	return e

static func encounters() -> Array:
	return [make_dense(), make_spike()]

static func run_encounters() -> Array:
	return [make_dense(), make_spike()]

# --- seats ---
static func make_tank(aspect: String, dcfg: DuelistConfig, is_player: bool) -> Seat:
	var u := Seat.new()
	u.role = "tank"; u.unit_name = "You"; u.is_player = is_player; u.fidelity = "full"
	u.hp_max = dcfg.hp_max; u.hp = dcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = 0.0                # NO mana/rage — WIND + ◆ live in vars
	u.kit = DuelistKit.new(aspect, dcfg)
	u.policy = DuelistPolicy.new()
	u.vars = {"flow": dcfg.flow_start, "wind": dcfg.wind_max, "combo": 0}
	return u

static func _make_ally(name: String, role: String, hp: float, dps: float) -> Seat:
	var u := Seat.new()
	u.role = role; u.unit_name = name; u.is_player = false; u.fidelity = "statblock"
	u.hp_max = hp; u.hp = hp; u.dps = dps
	return u

## The sim party: the Duelist tank (seat 0) + 3 statblock DPS burning the boss. threat_enabled
## on so FLOW=AGGRO is exercised (a good tank holds the boss; a sloppy one lets it peel). No
## healer — duelist_sim measures the tank's ECONOMY (flow uptime, wind floor, ◆, parry rates),
## not the healer duet (that lives in raid_sim). Boss damage is tuned so mitigation alone carries.
static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		dcfg: DuelistConfig, enc: EncounterRes) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [
		make_tank(aspect, dcfg, true),
		_make_ally("Kaelen", "dps", 130.0, 20.0),
		_make_ally("Mira", "dps", 120.0, 18.0),
		_make_ally("Sylas", "dps", 120.0, 18.0),
	]
	s.loss_mode = "raid"
	s.threat_enabled = true
	return s
