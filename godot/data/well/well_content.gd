## WellContent — the party + encounters the reworked healer trains and sims against
## (a tank + 3 statblock DPS the healer keeps alive; a boss that pressures the group so
## there is something to heal AND a boss HP bar the Glint can measurably shorten). Built
## in code, mirroring MenderContent's shape. Used by well_sim + the GATE exam.
class_name WellContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 12.0
	return c

static func make_well_config() -> WellConfig:
	return WellConfig.new()

# --- boss ability builders ---
static func _tankbuster(id: StringName, name: String, amount: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Tankbuster"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true; a.size = AbilityRes.Size.CRUSH
	return a

static func _nova(id: StringName, name: String, amount: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Raid AoE"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _dot(id: StringName, name: String, effect: AbilityRes.Effect, tick: float, dur: float,
		targets: int, cast: float, cd: float, jitter: float, danger: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = ("Raid DoT" if effect == AbilityRes.Effect.DOT_ALL else "Curse")
	a.effect = effect
	a.dot_tick = tick; a.dot_every = 1.5; a.dot_dur = dur; a.dot_targets = targets
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = danger
	return a

## A multi-strike AoE STRING — every beat hits the whole raid (healer included); each
## seat answers with the universal dodge. `beats` = [{at, frac, size}...].
static func _barrage(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Barrage"
	a.effect = AbilityRes.Effect.DMG_ALL
	a.amount = amount
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

static func make_spike() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"maw"; e.name = "The Rendmaw"; e.hp = 7200
	e.intro = "A spike fight. Maw Crush punishes the tank; the Rending Barrage rakes EVERYONE — dodge each claw; Hex rots a random ally."
	e.melee = {"every": 1.4, "min": 14.0, "max": 21.0}
	e.enrage_at = 120.0        # efficiency matters: a glinted (faster) kill beats the enrage
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.15; p1.speed = 1.05
	var p2 := PhaseRes.new(); p2.at = 0.28; p2.mult = 1.3; p2.speed = 1.1
	e.phases = [p0, p1, p2]
	e.abilities = [
		_tankbuster(&"crush", "Maw Crush", 125.0, 2.5, 12.0, 2.0),
		_barrage(&"barrage", "Rending Barrage", 54.0, 2.8, 14.0, 2.0, [
			{"at": 1.2, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.0, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.8, "frac": 0.34, "size": AbilityRes.Size.CRUSH},
		]),
		_dot(&"hex", "Hex", AbilityRes.Effect.DOT_RANDOM, 9.0, 9.0, 1, 1.8, 16.0, 3.0, false),
	]
	return e

static func make_attrition() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"rot"; e.name = "The Rotweaver"; e.hp = 6600
	e.intro = "Attrition. Light on the tank but it rots the whole group — Contagion spreads, Virulence blankets everyone."
	e.melee = {"every": 1.7, "min": 8.0, "max": 13.0}
	e.enrage_at = 210.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.3; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_nova(&"spore", "Spore Burst", 15.0, 1.8, 7.0, 1.5),
		_dot(&"contagion", "Contagion", AbilityRes.Effect.DOT_RANDOM, 7.0, 8.0, 2, 1.6, 11.0, 2.0, false),
		_dot(&"virulence", "Virulence", AbilityRes.Effect.DOT_ALL, 4.0, 6.0, 0, 2.5, 18.0, 3.0, true),
		_barrage(&"volley", "Spore Volley", 36.0, 2.4, 12.0, 2.0, [
			{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
			{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
		]),
	]
	return e

static func encounters() -> Array:
	return [make_spike(), make_attrition()]

# --- seats ---
static func make_healer(aspect: String, wcfg: WellConfig, boons: Dictionary, is_player: bool) -> Seat:
	var h := Seat.new()
	h.role = "healer"; h.unit_name = "You"; h.is_player = is_player; h.fidelity = "full"
	h.hp_max = 200.0; h.hp = 200.0; h.dps = 0.0        # untargetable-ish; deals no boss damage
	h.resource = 0.0; h.resource_max = 0.0             # NO mana — the Well is charges, in vars
	var kit := WellKit.new(aspect, wcfg)
	kit.boons = boons
	h.kit = kit
	h.policy = WellPolicy.new()
	h.vars = {"charges": wcfg.charges_max, "current": 0, "pulse_next": 0}
	return h

static func _make_ally(name: String, role: String, hp: float, dps: float) -> Seat:
	var u := Seat.new()
	u.role = role; u.unit_name = name; u.is_player = false; u.fidelity = "statblock"
	u.hp_max = hp; u.hp = hp; u.dps = dps
	return u

static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		wcfg: WellConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [
		make_healer(aspect, wcfg, boons, true),
		_make_ally("Bront", "tank", 300.0, 8.0),
		_make_ally("Kaelen", "dps", 120.0, 22.0),
		_make_ally("Mira", "dps", 110.0, 20.0),
		_make_ally("Sylas", "dps", 110.0, 20.0),
	]
	s.loss_mode = "raid"
	return s
