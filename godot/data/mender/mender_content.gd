## Mender content: the 4-unit party (a tank + 3 AI DPS the healer keeps alive) and
## the ported encounters (Rendmaw = spike, Rotweaver = attrition). Built in code.
class_name MenderContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # default ally damage curve (Brinkwarden overrides via kit)
	c.enrage_base = 12.0
	return c

static func make_mender_config() -> MenderConfig:
	return MenderConfig.new()

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

## A multi-strike aoe STRING (M7): every beat hits the whole raid — the HEALER
## included — and each seat answers with the universal dodge. Stat-block allies
## auto-roll theirs (cfg.statblock_dodge); the healer must actually press, mid-
## triage, possibly cancelling a cast. `beats` = [{at, frac, size}...].
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
		st.feint = bool(b.get("feint", false))
		st.aoe = true
		a.strikes.append(st)
	return a

static func make_rendmaw() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"rendmaw"; e.name = "The Rendmaw"; e.hp = 2600
	e.intro = "A spike fight. Maw Crush punishes the tank; the Rending Barrage rakes EVERYONE — you too, dodge each claw; Hex rots a random ally."
	e.melee = {"every": 1.4, "min": 14.0, "max": 21.0}
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.15; p1.speed = 1.05
	var p2 := PhaseRes.new(); p2.at = 0.28; p2.mult = 1.3; p2.speed = 1.1
	e.phases = [p0, p1, p2]
	e.abilities = [
		_tankbuster(&"crush", "Maw Crush", 125.0, 2.5, 12.0, 2.0),
		# M7: the old one-shot Rending Nova, re-authored as a 3-claw rhythm rake.
		# Whole-raid pressure that the healer now shares personally.
		_barrage(&"barrage", "Rending Barrage", 54.0, 2.8, 14.0, 2.0, [
			{"at": 1.2, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.0, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.8, "frac": 0.34, "size": AbilityRes.Size.CRUSH},
		]),
		_dot(&"hex", "Hex", AbilityRes.Effect.DOT_RANDOM, 9.0, 9.0, 1, 1.8, 16.0, 3.0, false),
	]
	return e

static func make_rotweaver() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"rotweaver"; e.name = "The Rotweaver"; e.hp = 2600
	e.intro = "Attrition. Light on the tank but it rots the whole group — Contagion spreads, Virulence blankets everyone."
	e.melee = {"every": 1.7, "min": 8.0, "max": 13.0}
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.3; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_nova(&"spore", "Spore Burst", 20.0, 1.8, 7.0, 1.5),
		_dot(&"contagion", "Contagion", AbilityRes.Effect.DOT_RANDOM, 8.0, 8.0, 2, 1.6, 11.0, 2.0, false),
		_dot(&"virulence", "Virulence", AbilityRes.Effect.DOT_ALL, 6.0, 6.0, 0, 2.5, 18.0, 3.0, true),
		# M7 — attrition with a pulse: three soft spore waves everyone (you too)
		# side-steps; missed waves just add to the rot you're already out-healing.
		_barrage(&"volley", "Spore Volley", 36.0, 2.4, 12.0, 2.0, [
			{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
			{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
		]),
	]
	return e

static func _mark(id: StringName, name: String, amount: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Marked Nuke"
	a.effect = AbilityRes.Effect.MARK_NUKE; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true; a.size = AbilityRes.Size.CRUSH
	return a

static func _heal_absorb(id: StringName, name: String, amount: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Heal Absorb"
	a.effect = AbilityRes.Effect.HEAL_ABSORB; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func make_choir() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"choir"; e.name = "The Hollow Choir"; e.hp = 3800
	e.intro = "A race against the song. Top the MARKED ally before Dissonance detonates; Grave Chorus buries your heals — you must heal THROUGH it. Burn it before the enrage."
	e.melee = {"every": 1.5, "min": 12.0, "max": 18.0}
	e.enrage_at = 80.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.2; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.45; p2.speed = 1.25
	e.phases = [p0, p1, p2]
	e.abilities = [
		_mark(&"dissonance", "Dissonance", 85.0, 3.0, 12.0, 2.0),
		_nova(&"requiem", "Requiem", 28.0, 2.6, 14.0, 2.0),
		_heal_absorb(&"chorus", "Grave Chorus", 70.0, 2.0, 13.0, 2.0),
		_dot(&"dirge", "Dirge", AbilityRes.Effect.DOT_RANDOM, 7.0, 8.0, 2, 1.6, 15.0, 3.0, false),
		# M7 — the finale's discipline test: a four-count with a FALSE NOTE on the
		# second beat. Dodge the fake and you're locked out of the real third beat —
		# hold through it, mid-triage, with a mark probably ticking somewhere.
		_barrage(&"refrain", "Discordant Refrain", 60.0, 2.8, 15.0, 2.0, [
			{"at": 0.9, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 1.5, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},
			{"at": 2.1, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 2.8, "frac": 0.4, "size": AbilityRes.Size.CRUSH},
		]),
	]
	return e

static func run_encounters() -> Array:
	return [make_rendmaw(), make_rotweaver(), make_choir()]

# --- seats ---
static func _make_healer(aspect: String, mcfg: MenderConfig, boons: Dictionary) -> Seat:
	var h := Seat.new()
	h.role = "healer"; h.unit_name = "You"; h.is_player = true; h.fidelity = "full"
	h.hp_max = 200.0; h.hp = 200.0; h.dps = 0.0        # untargetable; deals no boss damage
	h.resource = mcfg.mana_max; h.resource_max = mcfg.mana_max
	var kit := MenderKit.new(aspect, mcfg)
	kit.boons = boons
	h.kit = kit
	h.policy = MenderPolicy.new()
	h.vars = {"reservoir": 0.0, "nerve": 0.0,
		"regen_mult": (1.6 if boons.get("conservation", false) else 1.0)}
	return h

static func _make_ally(name: String, role: String, hp: float, dps: float,
		aspect: String, mcfg: MenderConfig, boons: Dictionary) -> Seat:
	var u := Seat.new()
	u.role = role; u.unit_name = name; u.is_player = false; u.fidelity = "statblock"
	u.hp_max = hp; u.hp = hp; u.dps = dps
	u.kit = MenderAllyKit.new(aspect, mcfg, boons.get("bloodpact", false))
	return u

static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		mcfg: MenderConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [
		_make_healer(aspect, mcfg, boons),
		_make_ally("Bront", "tank", 300.0, 8.0, aspect, mcfg, boons),
		_make_ally("Kaelen", "dps", 120.0, 22.0, aspect, mcfg, boons),
		_make_ally("Mira", "dps", 110.0, 22.0, aspect, mcfg, boons),
		_make_ally("Sylas", "dps", 110.0, 22.0, aspect, mcfg, boons),
	]
	s.loss_mode = "raid"
	return s

static func build_fight(run: RunState, seed: int) -> CombatState:
	return make_state(seed, run.aspect, make_config(), make_mender_config(),
		run.current_encounter(), run.boons)
