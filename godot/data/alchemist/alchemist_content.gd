## Alchemist content: two training encounters and the factory for a solo brew duel —
## one player seat vs the boss, no allies (the twinfang_content pattern). The base kit
## has NO interrupt (F22 open — interrupt-by-ability is a build-time call), so these
## bosses carry no HEAL_BOSS casts: the exam is footwork (swings + strings) against a
## hard enrage — keep the reaction fed and balanced THROUGH the dodging, cash the wave.
class_name AlchemistContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # unused (no stat-block allies); the brew deals via the kit
	c.enrage_base = 8.0      # ramp past the enrage timer — a dragged fight dies
	return c

static func make_alchemist_config() -> AlchemistConfig:
	return AlchemistConfig.new()   # defaults are the feel-test artifact numbers

# --- boss ability builders (per-class content copies — the repo idiom) ---

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

static func _string(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Combo!"
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	a.size = AbilityRes.Size.HEAVY
	a.response = AbilityRes.Response.UNAVOIDABLE # not dodge-verb answerable
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		st.feint = bool(b.get("feint", false))
		a.strikes.append(st)
	return a

## The brewing teacher: a slow golem whose swings leave room to charge — learn the
## vial and the see-saw under light pressure, race a generous enrage.
static func make_crucible() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"crucible"; e.name = "The Crucible"; e.hp = 2400
	e.intro = "The Crucible tests your brewing. Feed BOTH poisons, release in the sweet band, and cash the wave with Rupture before it grinds you down."
	e.enrage_at = 68.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.18; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"ladle",  "Ladle Sweep", AbilityRes.Size.LIGHT, 50.0,  1.7, 5.0, 1.0),
		_swing(&"slam",   "Kiln Slam",   AbilityRes.Size.HEAVY, 100.0, 2.2, 9.0, 1.5),
		_pulse(&"fumes",  "Caustic Fumes", 24.0, 1.3, 11.0, 2.0),
		_string(&"stir",  "The Stir", 66.0, 1.4, 12.0, 1.5, [
			{"at": 0.7, "frac": 0.5, "size": AbilityRes.Size.LIGHT},
			{"at": 1.4, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## The exam: faster, harder chip, and a feint mid-string — brew through the panic.
## No self-heal (the base kit can't kick) — the DPS check is the enrage alone.
static func make_leech() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"leech"; e.name = "The Leech"; e.hp = 3200
	e.intro = "Faster, meaner, and it lies. Keep pouring THROUGH the footwork — a panicked brewer stalls the reaction and loses the race."
	e.enrage_at = 74.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.25
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"lash",   "Tongue Lash",  AbilityRes.Size.LIGHT, 56.0,  1.5, 4.4, 0.9),
		_swing(&"drain",  "Drain Coil",   AbilityRes.Size.HEAVY, 105.0, 2.0, 8.0, 1.3),
		_pulse(&"seep",   "Seep",          26.0, 1.2, 10.0, 2.0),
		_string(&"spasm", "Triple Spasm", 62.0, 1.9, 13.5, 2.0, [
			{"at": 0.8, "frac": 0.45, "size": AbilityRes.Size.HEAVY},
			{"at": 1.4, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},
			{"at": 2.0, "frac": 0.55, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## The ordered encounter list for an Alchemist run.
static func run_encounters() -> Array:
	return [make_crucible(), make_leech()]

# --- seat ---

static func _make_brewer(aspect: String, acfg: AlchemistConfig, boons: Dictionary) -> Seat:
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Alchemist"; u.is_player = true; u.fidelity = "full"
	u.hp_max = acfg.hp_max; u.hp = acfg.hp_max
	u.dps = 0.0                                  # damage comes from the brew, not the passive curve
	u.resource = 0.0; u.resource_max = 100.0     # mirrors POTENCY (0–100) for generic UI reads
	var kit := AlchemistKit.new(aspect, acfg)
	kit.boons = boons
	u.kit = kit
	u.policy = AlchemistPolicy.new()
	u.vars = {"venom": 0.0, "rot": 0.0, "charging": "", "charge": 0.0,
		"potency": 0.0, "react_bank": 0.0}
	return u

## Build a solo Alchemist fight (party of one) for `seed`.
static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		acfg: AlchemistConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [_make_brewer(aspect, acfg, boons)]
	s.loss_mode = "player"
	return s
