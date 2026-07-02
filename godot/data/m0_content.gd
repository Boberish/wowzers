## M0 content, built in code (M1 moves bosses to authored .tres files). One dummy
## boss + a party of two seats: a human-controlled TANK and a stat-block DPS ally.
## Even though there's no class yet, this exercises the whole spine: telegraphs,
## phases, the defensive verb, the seat/party model, and the group-damage line.
class_name M0Content
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.defense_active = 0.5
	c.defense_cd = 2.2
	c.defense_mitigation = 0.7
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 6.0
	return c

static func make_encounter() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"m0_sentinel"
	e.name = "M0 Sentinel (skeleton dummy)"
	e.hp = 1000
	e.melee = {"every": 1.5, "min": 8.0, "max": 13.0}
	e.enrage_at = 75.0

	var p0 := PhaseRes.new()
	p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new()
	p1.at = 0.4; p1.mult = 1.2; p1.speed = 1.15
	e.phases = [p0, p1]

	var smash := AbilityRes.new()
	smash.id = &"smash"; smash.name = "Smash"; smash.tag = "Heavy"
	smash.cast = 1.6; smash.cd = 4.0; smash.jitter = 1.0; smash.danger = true
	smash.effect = AbilityRes.Effect.DMG_TARGET; smash.amount = 100.0
	smash.response = AbilityRes.Response.DEFENSIBLE; smash.size = AbilityRes.Size.HEAVY

	var nova := AbilityRes.new()
	nova.id = &"nova"; nova.name = "Pulse"; nova.tag = "Raid"
	nova.cast = 2.0; nova.cd = 7.0; nova.jitter = 1.5; nova.danger = false
	nova.effect = AbilityRes.Effect.DMG_ALL; nova.amount = 34.0
	nova.response = AbilityRes.Response.UNAVOIDABLE

	e.abilities = [smash, nova]
	return e

## Build a ready-to-run fight for `seed`. `ally_dps` is exposed so the sim can
## sweep it and watch the win-rate move.
static func make_state(seed: int, cfg: TuningConfig, enc: EncounterRes, ally_dps: float = 30.0) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)

	var tank := Seat.new()
	tank.role = "tank"; tank.is_player = true; tank.fidelity = "full"
	tank.hp_max = 650.0; tank.hp = 650.0; tank.dps = 8.0
	tank.policy = TankPolicy.new()

	var dps := Seat.new()
	dps.role = "dps"; dps.is_player = false; dps.fidelity = "statblock"
	dps.hp_max = 300.0; dps.hp = 300.0; dps.dps = ally_dps

	s.seats = [tank, dps]
	return s
