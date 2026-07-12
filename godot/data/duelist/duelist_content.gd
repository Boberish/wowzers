## DuelistContent — the party + encounters THE DUELIST trains and sims against (tank-v2).
## The tank + 3 statblock DPS burning a boss that pressures the tank so there is a bar-stream
## to answer AND an HP bar to end. Built in code; used by duelist_sim and RunState.start_duelist.
##
## Bosses here are STREAM-first (TANK-PLAN §0): the melee dict IS the texture profile — the
## generated sequence exercises the full vocabulary (autos/heavies/busters/feints/flurries/
## eats/LATE bars). Globals are single-beat aoe strings (BARRAGE RETIREMENT: multi-beat
## dodge-strings are dead game-wide; one beat = the party dodge moment, dodge-only, every seat).
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

## A GLOBAL: the boss's big move — ONE aoe dodge beat at the cast's end (every seat answers
## with the one dodge; the tank reads it as the boss-colored octagon, word DODGE).
static func _global(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Global"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	var st := StrikeRes.new()
	st.at = cast; st.amount_frac = 1.0
	st.size = AbilityRes.Size.CRUSH
	st.aoe = true
	a.strikes.append(st)
	return a

## DENSE fight: the full-vocabulary stream — trains the read (feints/lates) + the weave.
static func make_dense() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"dense"; e.name = "The Sparring Golem"; e.hp = 9000
	e.intro = "Dense footwork: the full stream. Parry what's aimed at you, don't touch the purple."
	e.melee = {"every": 1.0, "min": 20.0, "max": 28.0, "rhythm": 0.55, "jig": 0.30,
		"heavy_odds": 0.15, "feint_odds": 0.15, "flurry_odds": 0.06, "eat_odds": 0.05,
		"late_odds": 0.08,   # legacy fallback (unused while `phrases` is present; SPIKE keeps the odds path live)
		# THE SONGBOOK (2026-07-12): the training golem drills the full vocabulary in phrases
		"phrases": [
			{"name": "one_two", "weight": 1.0, "rest": 1.7,
				"steps": [{"kind": "auto"}, {"gap": 0.55, "kind": "auto"}]},
			{"name": "windup_tall", "weight": 0.9, "rest": 1.9,
				"steps": [{"kind": "auto"}, {"gap": 0.8, "kind": "auto"}, {"gap": 0.55, "kind": "heavy"}]},
			{"name": "the_lie", "weight": 0.8, "rest": 1.7,
				"steps": [{"kind": "auto"}, {"gap": 0.6, "kind": "feint"}]},
			{"name": "the_weave", "weight": 0.5, "rest": 2.0,
				"steps": [{"kind": "flurry"}]},
			{"name": "brace_bell", "weight": 0.45, "rest": 1.9,
				"steps": [{"kind": "auto"}, {"gap": 0.85, "kind": "eat"}]},
			{"name": "late_jab", "weight": 0.5, "rest": 1.7,
				"steps": [{"kind": "auto"}, {"gap": 0.75, "kind": "auto", "late": true}]},
		]}
	e.enrage_at = 150.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.15; p1.speed = 1.1
	e.phases = [p0, p1]
	e.abilities = [
		# gentle: the training sim runs HEALER-LESS (tank economy only) — one full-amount
		# aoe beat (post barrage-retirement) at old per-beat weight, not the whole string's
		_global(&"shockwave", "Shockwave", 34.0, 2.4, 18.0, 2.0),
	]
	return e

## SPIKE fight: sparser, heavier — trains the parry commit + the bullseye-dodge escape.
static func make_spike() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"spike"; e.name = "The Siege Ram"; e.hp = 8400
	e.intro = "Big, slow, telegraphed. Commit the parry, hit back — or thread the bullseye."
	e.melee = {"every": 1.5, "min": 12.0, "max": 18.0, "rhythm": 0.6, "jig": 0.35,
		"heavy_odds": 0.25, "crush_odds": 0.08, "feint_odds": 0.10, "late_odds": 0.05}
	e.enrage_at = 165.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.25; p1.speed = 1.12
	e.phases = [p0, p1]
	e.abilities = [
		_global(&"quake", "Quake", 42.0, 2.6, 20.0, 2.0),
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
## healer — duelist_sim measures the tank's ECONOMY (flow uptime, wind floor, ◆, answer rates),
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
