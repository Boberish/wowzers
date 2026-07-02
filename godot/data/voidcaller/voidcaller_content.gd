## Voidcaller content: the two ported encounters (The Choir-Priest, The Twin Cantors)
## and the factory for a solo caster-DPS duel. Reading the boss's purple cast bar IS the
## fight: kick the Mending (or it heals), kick the Empower (or it hits harder), and
## Barrier the uninterruptible channels you can't stop. No enrage — the boss's self-heal
## is the DPS check. Numbers lifted from poc/voidcaller.html.
class_name VoidcallerContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # unused (no stat-block allies); a solo Voidcaller deals via abilities
	c.enrage_base = 0.0      # no hard enrage — the boss's Mending is the check
	return c

static func make_voidcaller_config() -> VoidcallerConfig:
	return VoidcallerConfig.new()

# --- boss ability builders (casts are INTERRUPTIBLE + danger so they win scheduler ties) ---

static func _cast_heal(id: StringName, name: String, heal: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Interrupt!"
	a.effect = AbilityRes.Effect.HEAL_BOSS; a.amount = heal
	a.cast = cast; a.cd = cd; a.jitter = jitter
	a.response = AbilityRes.Response.INTERRUPTIBLE; a.danger = true
	return a

static func _cast_nova(id: StringName, name: String, dmg: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Interrupt!"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = dmg
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.HEAVY
	a.response = AbilityRes.Response.INTERRUPTIBLE; a.danger = true
	return a

static func _cast_empower(id: StringName, name: String, buff: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Interrupt!"
	a.effect = AbilityRes.Effect.EMPOWER_BOSS; a.buff = buff
	a.cast = cast; a.cd = cd; a.jitter = jitter
	a.response = AbilityRes.Response.INTERRUPTIBLE; a.danger = true
	return a

## An uninterruptible channel (big) — Barrier through it. UNAVOIDABLE, not danger.
static func _channel(id: StringName, name: String, dmg: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Can't stop"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = dmg
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.CRUSH
	a.response = AbilityRes.Response.UNAVOIDABLE
	return a

## Unavoidable chip pulse — small, you just eat it.
static func _pulse(id: StringName, name: String, dmg: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Unavoidable"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = dmg
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.LIGHT
	a.response = AbilityRes.Response.UNAVOIDABLE
	return a

## A multi-strike STRING (M7): beats answered with the universal dodge (F) — a
## THIRD thing to read alongside kickable casts and Barrier channels. Landed
## beats also push your Fracture back (on_damage_taken pushback), so footwork
## protects the cast bar. `beats` = [{at, frac, size, guard, feint}...].
static func _string(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Combo!"
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	a.size = AbilityRes.Size.HEAVY
	a.response = AbilityRes.Response.UNAVOIDABLE # can't be kicked — dodge each beat
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		st.feint = bool(b.get("feint", false))
		a.strikes.append(st)
	return a

static func make_priest() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"priest"; e.name = "The Choir-Priest"; e.hp = 1550
	e.intro = "The Choir-Priest never stops casting — reading the purple bar IS the fight. Kick the green Mending first; the Searing Word stings but won't kill you. The Purge can't be stopped — Barrier through it."
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.12; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_cast_heal(&"mend", "Mending", 300.0, 2.2, 5.5, 0.8),
		_cast_nova(&"sear", "Searing Word", 56.0, 1.8, 4.5, 0.8),
		_channel(&"purge", "Purge", 55.0, 2.3, 15.0, 2.0),
		# M7 — a whipping two-count between casts: dodge it or your Fracture slips.
		_string(&"lashverse", "Lash Verse", 62.0, 1.35, 10.0, 1.5, [
			{"at": 0.7, "frac": 0.5, "size": AbilityRes.Size.LIGHT},
			{"at": 1.35, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

static func make_cantors() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"cantors"; e.name = "The Twin Cantors"; e.hp = 2200
	e.intro = "Two voices, overlapping casts. A heal and a nuke wind up close together and your interrupt is on cooldown — kick the heal, eat the nuke. It Empowers itself too; let that stack and the nukes start to bite."
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.1; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.4; p2.mult = 1.25; p2.speed = 1.3
	e.phases = [p0, p1, p2]
	e.abilities = [
		_cast_heal(&"mend", "Antiphon", 340.0, 2.0, 5.0, 0.8),
		_cast_nova(&"sear", "Dirge", 62.0, 1.7, 4.2, 0.7),
		_cast_empower(&"emp", "Crescendo", 0.12, 2.0, 11.0, 1.5),
		_pulse(&"smite", "Dissonance", 20.0, 1.0, 9.0, 2.0),
		_channel(&"purge", "Requiem", 62.0, 2.1, 15.0, 2.0),
		# M7 — two voices strike as one... except when only ONE of them does. The
		# middle beat is the silent twin: dodge it and you're locked out of the real
		# closing note.
		_string(&"duet", "Duet", 78.0, 2.0, 11.0, 1.8, [
			{"at": 0.7, "frac": 0.4, "size": AbilityRes.Size.LIGHT},
			{"at": 1.35, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},
			{"at": 2.0, "frac": 0.6, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

static func run_encounters() -> Array:
	return [make_priest(), make_cantors()]

# --- seat ---

static func _make_caster(aspect: String, vcfg: VoidcallerConfig, boons: Dictionary) -> Seat:
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Voidcaller"; u.is_player = true; u.fidelity = "full"
	u.hp_max = vcfg.hp_max; u.hp = vcfg.hp_max
	u.dps = 0.0
	u.resource = 0.0; u.resource_max = vcfg.focus_max      # Focus starts empty — build with Bolt
	var kit := VoidcallerKit.new(aspect, vcfg)
	kit.boons = boons
	u.kit = kit
	u.policy = VoidcallerPolicy.new()
	u.vars = {"backlash": 0, "next_instant": false, "kicks": 0}
	return u

static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		vcfg: VoidcallerConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [_make_caster(aspect, vcfg, boons)]
	s.loss_mode = "player"
	return s

static func build_fight(run: RunState, seed: int) -> CombatState:
	return make_state(seed, run.aspect, make_config(), make_voidcaller_config(),
		run.current_encounter(), run.boons)
