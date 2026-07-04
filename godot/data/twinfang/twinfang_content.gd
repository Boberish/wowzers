## Twinfang content: the two ported encounters (The Warden, The Executioner) and the
## factory for a solo melee-DPS duel. The Twinfang is the damage — one player seat vs
## the boss, no allies (a true 1v1, faithful to poc/twinfang.html). Built in code.
##
## Each boss mixes: dodgeable swings (eat one and lose your Flow), an interruptible
## self-heal (Kick it or the fight drags), an unavoidable pulse (chip you can't answer),
## and a hard enrage timer (out-DPS it or die). Numbers lifted from the prototype.
class_name TwinfangContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # unused (no stat-block allies); a solo Twinfang deals via abilities
	c.enrage_base = 8.0      # ramp past the enrage timer — a real threat to a dragged fight
	return c

static func make_twinfang_config() -> TwinfangConfig:
	return TwinfangConfig.new()   # defaults are the verified prototype numbers

# --- boss ability builders ---

## A dodgeable swing (DEFENSIBLE): answer with Space in its window, or eat it and lose
## Flow. Carries a Size so the kit knows a landed swing wipes Flow (pulses/enrage don't).
static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = ["", "Swing", "Heavy Swing", "Crush"][size]
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = size
	a.response = AbilityRes.Response.DEFENSIBLE
	return a

## An unavoidable single-target pulse (Hex): no counter-play, no Size → never touches
## your Flow. Pure chip that pressures your health while you keep the rhythm.
static func _pulse(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Unavoidable"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.NONE
	a.response = AbilityRes.Response.UNAVOIDABLE
	return a

## The boss self-heal (HEAL_BOSS, INTERRUPTIBLE): Kick it mid-cast (danger=true so it
## wins scheduler ties, faithful to the prototype's "a cast preempts a swing"). Left
## uninterrupted it heals (scaled by phase mult) and the fight drags toward enrage.
static func _heal(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Interrupt!"
	a.effect = AbilityRes.Effect.HEAL_BOSS; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.size = AbilityRes.Size.NONE
	a.response = AbilityRes.Response.INTERRUPTIBLE; a.danger = true
	return a

## A multi-strike STRING (M7): beats resolve progressively; each is answered with
## the universal dodge (F). Beats CARRY a Size, so a landed beat wipes Flow like
## any swing — while a PERFECT dodge *builds* Flow. Strings are the rhythm made
## hostile. `beats` = [{at, frac, size, guard, feint}...].
static func _string(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Combo!"
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	a.size = AbilityRes.Size.HEAVY
	a.response = AbilityRes.Response.UNAVOIDABLE # not dodge-verb/kick-answerable
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		st.feint = bool(b.get("feint", false))
		a.strikes.append(st)
	return a

static func make_warden() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"warden"; e.name = "The Warden"; e.hp = 2800
	e.intro = "The Warden tests your rhythm. Dodge the Cleave, Kick its Mending, and keep your Flow alive between hits."
	e.enrage_at = 56.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.18; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"swipe",  "Swipe",   AbilityRes.Size.LIGHT, 52.0,  1.6, 4.6, 1.0),
		_swing(&"cleave", "Cleave",  AbilityRes.Size.HEAVY, 104.0, 2.2, 8.5, 1.5),
		_heal(&"mend",    "Mending", 230.0, 2.3, 12.0, 2.0),
		_pulse(&"hex",    "Hex Bolt", 26.0, 1.3, 11.0, 2.0),
		# M7 — an honest two-count: the boss answers your rhythm with its own.
		_string(&"crossslash", "Cross Slash", 70.0, 1.4, 11.0, 1.5, [
			{"at": 0.7, "frac": 0.5, "size": AbilityRes.Size.LIGHT},
			{"at": 1.4, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

static func make_executioner() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"executioner"; e.name = "The Executioner"; e.hp = 3600
	e.intro = "Faster and it heals more. Your Flow gets wiped if you eat swings — dodge tight, Kick every heal, and burst it before it enrages."
	e.enrage_at = 66.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.3
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"swipe",  "Rend",        AbilityRes.Size.LIGHT, 58.0,  1.4, 4.0, 0.8),
		_swing(&"cleave", "Decapitate",  AbilityRes.Size.HEAVY, 120.0, 2.0, 7.5, 1.3),
		_heal(&"mend",    "Blood Ritual", 300.0, 2.0, 10.5, 1.5),
		_pulse(&"hex",    "Wither",        30.0, 1.2, 10.0, 2.0),
		# M7 — it toys with its prey: a real cut, a FAKE lifted blade (hold!), then
		# the true edge. Flinching at the fake wipes your window AND your Flow.
		# (64 @ cd 14 — venom fights run long, so per-string chip must stay light or
		# the forgiving-aspect contract erodes; the feint READ is the real test here)
		_string(&"judgment", "Judgment Cuts", 64.0, 2.0, 14.0, 2.0, [
			{"at": 0.8, "frac": 0.45, "size": AbilityRes.Size.HEAVY},
			{"at": 1.4, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},
			{"at": 2.0, "frac": 0.55, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## The ordered encounter list for a Twinfang run.
static func run_encounters() -> Array:
	return [make_warden(), make_executioner()]

# --- seat ---

static func _make_blade(aspect: String, tcfg: TwinfangConfig, boons: Dictionary,
		creed := "drumline", mods := {}) -> Seat:
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Twinfang"; u.is_player = true; u.fidelity = "full"
	u.hp_max = tcfg.hp_max; u.hp = tcfg.hp_max
	u.dps = 0.0                                  # damage comes from abilities, not the passive curve
	u.resource = tcfg.energy_max; u.resource_max = tcfg.energy_max
	var kit := TwinfangKit.new(aspect, tcfg)
	kit.boons = boons
	kit.creed_id = creed                         # TEMPO rework: run-start risk temperament
	kit.modules = mods                           # TEMPO rework: equipped UI Modules
	u.kit = kit
	u.policy = TwinfangPolicy.new()
	u.vars = {"flow": 0, "cp": 0, "flow_decay_acc": 0, "last_strike_tick": -100000,
		"perfect_count": 0}
	if aspect == "venomancer":
		u.vars["venom"] = TwinfangKit.new_venom()
	return u

## Build a solo Twinfang fight (party of one) for `seed` and `aspect`.
static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		tcfg: TwinfangConfig, enc: EncounterRes, boons: Dictionary = {},
		creed := "drumline", mods := {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [_make_blade(aspect, tcfg, boons, creed, mods)]
	s.loss_mode = "player"
	return s

## Build the current fight from a RunState (game-layer entry point).
## TODO(tempo-pilot): the Creed run-start pick + Module Floor-1 pick will feed creed/mods here.
static func build_fight(run: RunState, seed: int) -> CombatState:
	var creed: Variant = run.get("tf_creed")     # dynamic get — null until the pick UI adds it
	var mods: Variant = run.get("tf_modules")
	return make_state(seed, run.aspect, make_config(), make_twinfang_config(),
		run.current_encounter(), run.boons,
		String(creed) if creed != null else "drumline",
		mods if mods is Dictionary else {})
