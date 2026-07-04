## Reckoner content: solo duel bosses + the factory for a 1v1 (party of one). The
## Reckoner is the damage — it races an enrage DPS-check. Its defense is a dodge
## (negate a heavy swing) + the Clash (apex onto a boss beat); light chip is EATEN
## on purpose (it feeds Rage — swing through the danger). Numbers are tuned to a
## skill-graded band (see reckoner_sim). Built in code, mirroring TwinfangContent.
class_name ReckonerContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 8.0
	return c

static func make_reckoner_config() -> ReckonerConfig:
	return ReckonerConfig.new()

# --- boss ability builders (mirror TwinfangContent) ---

static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = ["", "Swing", "Heavy Swing", "Crush"][size]
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = size
	a.response = AbilityRes.Response.DEFENSIBLE
	return a

static func _pulse(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Unavoidable"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.NONE
	a.response = AbilityRes.Response.UNAVOIDABLE
	return a

static func make_sentinel() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"sentinel"; e.name = "The Sentinel"; e.hp = 3450
	e.intro = "The Sentinel grinds you down. Wind up, land the apex, and out-race its enrage — dodge the Cleave, eat the chip (it feeds your Rage)."
	e.enrage_at = 49.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.45; p1.mult = 1.15; p1.speed = 1.12
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"swipe",  "Swipe",   AbilityRes.Size.LIGHT, 30.0, 1.6, 4.5, 1.0),
		_swing(&"cleave", "Cleave",  AbilityRes.Size.HEAVY, 72.0, 2.2, 8.0, 1.5),
		_pulse(&"grind",  "Grind",    18.0, 1.3, 10.0, 2.0),
	]
	return e

static func make_adjudicator() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"adjudicator"; e.name = "The Adjudicator"; e.hp = 4000
	e.intro = "Faster, and it hits harder late. Chain True apexes to ride Momentum, break its Poise, and burst it before the enrage."
	e.enrage_at = 60.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.15; p1.speed = 1.12
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.28
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"swipe",  "Rend",       AbilityRes.Size.LIGHT, 30.0, 1.4, 4.2, 0.8),
		_swing(&"cleave", "Decree",     AbilityRes.Size.HEAVY, 78.0, 2.0, 7.5, 1.3),
		_pulse(&"grind",  "Attrition",   18.0, 1.2, 9.5, 2.0),
	]
	return e

static func run_encounters() -> Array:
	return [make_sentinel(), make_adjudicator()]

# --- seat ---

static func _make_reckoner(aspect: String, rcfg: ReckonerConfig, boons: Dictionary) -> Seat:
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Reckoner"; u.is_player = true; u.fidelity = "full"
	u.hp_max = rcfg.hp_max; u.hp = rcfg.hp_max
	u.dps = 0.0
	u.resource = 40.0; u.resource_max = rcfg.rage_max   # starts with a little Rage
	var kit := ReckonerKit.new(aspect, rcfg)
	kit.boons = boons
	u.kit = kit
	u.policy = ReckonerPolicy.new()
	u.vars = _init_vars()
	return u

static func _init_vars() -> Dictionary:
	return {"phase": 0, "wind_start": 6, "momentum": 0.0, "poise": 0.0, "weight": "",
		"over_armed": false, "ultra_armed": false, "stagger_until": 0,
		"seq_winds": [], "seq_strikes": []}

## Build a solo Reckoner fight (party of one) for `seed` and `aspect`.
static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		rcfg: ReckonerConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [_make_reckoner(aspect, rcfg, boons)]
	s.loss_mode = "player"
	return s

static func build_fight(run: RunState, seed: int) -> CombatState:
	return make_state(seed, run.aspect, make_config(), make_reckoner_config(),
		run.current_encounter(), run.boons)
