## Bloomweaver content: the 4-unit party and three authored encounters that exercise
## the ANTICIPATION verb from different angles:
##   Ashmaul    — spike teacher: big readable hits reward ward-before-the-swing.
##   Swarmheart — attrition sprawl: constant chip makes the full garden shine.
##   Hollowking — finale: marks + heal-absorb + enrage; anticipate or fall behind.
class_name BloomweaverContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 12.0
	return c

static func make_bloom_config() -> BloomweaverConfig:
	return BloomweaverConfig.new()

# --- boss ability builders (same shapes the Mender bosses use) ---
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

## A multi-strike aoe STRING (M7): every beat hits the whole raid — the HEALER
## included — each seat answering with the universal dodge (statblock allies
## auto-roll cfg.statblock_dodge). The anticipation healer's REACTIVE test: you
## can plant the garden ahead, but the beats you must step yourself.
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

## Spike teacher. Everything is BIG and telegraphed — a ward cast on the victim
## during the wind-up eats the hit whole (Perfect Ward food). Slow chip between.
static func make_ashmaul() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"ashmaul"; e.name = "The Ashmaul"; e.hp = 2600
	e.intro = "A spike fight. Skullmaul crushes the tank; Cinder Nova burns everyone. Every hit is telegraphed — ward the victim BEFORE it lands."
	e.melee = {"every": 1.5, "min": 13.0, "max": 19.0}
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.15; p1.speed = 1.05
	var p2 := PhaseRes.new(); p2.at = 0.28; p2.mult = 1.3; p2.speed = 1.1
	e.phases = [p0, p1, p2]
	e.abilities = [
		_tankbuster(&"skullmaul", "Skullmaul", 128.0, 2.6, 12.0, 2.0),
		_nova(&"cindernova", "Cinder Nova", 32.0, 3.0, 14.0, 2.0),
		_dot(&"charbrand", "Charbrand", AbilityRes.Effect.DOT_RANDOM, 9.0, 9.0, 1, 1.8, 16.0, 3.0, false),
		# M7 — two heavy claw rakes across the whole raid; the gardener steps too.
		_barrage(&"skullrake", "Skull Rake", 40.0, 1.8, 13.0, 2.0, [
			{"at": 1.0, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
			{"at": 1.8, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## Attrition sprawl. Light, RELENTLESS chip across the whole party — one big heal
## can't answer it, but a garden of ticking Growths can. Rot pressure for Sap Rot.
static func make_swarmheart() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"swarmheart"; e.name = "The Swarmheart"; e.hp = 2600
	e.intro = "Attrition. Swarm Pulse stings everyone, constantly; Burrowers gnaw at random allies. No single spike kills — the thousand cuts do. Blanket the garden."
	e.melee = {"every": 1.7, "min": 9.0, "max": 14.0}
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.5; p1.mult = 1.35; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_nova(&"swarmpulse", "Swarm Pulse", 21.0, 1.6, 6.0, 1.5),
		_dot(&"burrowers", "Burrowers", AbilityRes.Effect.DOT_RANDOM, 8.0, 8.0, 2, 1.6, 11.0, 2.0, false),
		_dot(&"hivemind", "Hivemind", AbilityRes.Effect.DOT_ALL, 7.0, 7.5, 0, 2.5, 18.0, 3.0, true),
		# M7 — three soft waves of the swarm washing over everyone: more thousand-cuts
		# for the garden to out-tick, and footwork for the gardener between plants.
		_barrage(&"swarmsurge", "Swarm Surge", 33.0, 2.3, 11.0, 2.0, [
			{"at": 0.9, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.6, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
			{"at": 2.3, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
		]),
	]
	return e

## The finale. Kingsmark demands a pre-planted answer on a random ally; Gravebind
## buries your heals (HoTs already rolling tick straight through it as it drains);
## the enrage clock punishes a healer who never finds Thornlash/greed windows.
static func make_hollowking() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"hollowking"; e.name = "The Hollowking"; e.hp = 3600
	e.intro = "The crown demands tribute. Kingsmark nukes a random ally — have the answer PLANTED before it lands. Gravebind buries your healing. Burn him before the enrage."
	e.melee = {"every": 1.5, "min": 13.0, "max": 19.0}
	e.enrage_at = 72.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.2; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.45; p2.speed = 1.25
	e.phases = [p0, p1, p2]
	e.abilities = [
		_mark(&"kingsmark", "Kingsmark", 105.0, 3.0, 12.0, 2.0),
		_nova(&"hollowtoll", "Hollow Toll", 33.0, 2.6, 14.0, 2.0),
		_heal_absorb(&"gravebind", "Gravebind", 85.0, 2.0, 13.0, 2.0),
		_dot(&"rotcrown", "Rotcrown", AbilityRes.Effect.DOT_RANDOM, 7.0, 8.0, 2, 1.6, 15.0, 3.0, false),
		# M7 — the finale's four-count procession with a SILENT toll on the second
		# beat: flinch at it and the crown's real notes land while you're locked out.
		_barrage(&"cadence", "King's Cadence", 63.0, 2.8, 15.0, 2.0, [
			{"at": 0.9, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 1.5, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},
			{"at": 2.1, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 2.8, "frac": 0.4, "size": AbilityRes.Size.CRUSH},
		]),
	]
	return e

static func run_encounters() -> Array:
	return [make_ashmaul(), make_swarmheart(), make_hollowking()]

# --- seats ---
static func _make_healer(aspect: String, bcfg: BloomweaverConfig, boons: Dictionary) -> Seat:
	var h := Seat.new()
	h.role = "healer"; h.unit_name = "You"; h.is_player = true; h.fidelity = "full"
	h.hp_max = 200.0; h.hp = 200.0; h.dps = 0.0        # untargetable; damage only via Thornlash/thorns
	h.resource = bcfg.sap_max; h.resource_max = bcfg.sap_max
	var kit := BloomweaverKit.new(aspect, bcfg)
	kit.boons = boons
	h.kit = kit
	h.policy = BloomweaverPolicy.new()
	h.vars = {"verdance": 0.0}
	return h

static func _make_ally(name: String, role: String, hp: float, dps: float) -> Seat:
	var u := Seat.new()
	u.role = role; u.unit_name = name; u.is_player = false; u.fidelity = "statblock"
	u.hp_max = hp; u.hp = hp; u.dps = dps
	u.kit = ClassKit.new()      # plain kit → damage rounds like the Mender party
	return u

static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		bcfg: BloomweaverConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [
		_make_healer(aspect, bcfg, boons),
		_make_ally("Darga", "tank", 300.0, 8.0),
		_make_ally("Vex", "dps", 120.0, 22.0),
		_make_ally("Ilya", "dps", 110.0, 22.0),
		_make_ally("Corin", "dps", 110.0, 22.0),
	]
	s.loss_mode = "raid"
	return s

static func build_fight(run: RunState, seed: int) -> CombatState:
	return make_state(seed, run.aspect, make_config(), make_bloom_config(),
		run.current_encounter(), run.boons)
