## Bulwark content: the two ported encounters (Gatekeeper, Warcaller) and factories
## to build a ready-to-run fight. Built in code for M1; can be exported to .tres later.
class_name BulwarkContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	# f_floor/f_scale only matter for stat-block allies (used by the ally-path sim);
	# a solo Bulwark seat deals damage via abilities, not this curve.
	c.f_floor = 0.3
	c.f_scale = 0.7
	c.enrage_base = 6.0
	return c

static func make_bulwark_config() -> BulwarkConfig:
	return BulwarkConfig.new()   # defaults are the verified prototype numbers

static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float, dodgeable: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = ["", "Light", "Heavy", "Crush"][size]
	a.effect = AbilityRes.Effect.DMG_TARGET
	a.amount = amount
	a.cast = cast
	a.cd = cd
	a.jitter = jitter
	a.size = size
	a.response = AbilityRes.Response.DEFENSIBLE if dodgeable else AbilityRes.Response.UNAVOIDABLE
	a.danger = size == AbilityRes.Size.CRUSH   # crush wins scheduler ties (prototype)
	return a

static func make_gatekeeper() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"gatekeeper"
	e.name = "The Gatekeeper"
	e.hp = 1950
	e.intro = "Small jabs are rage you can bank; the wind-up Slam is what your defense is for."
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.4; p1.mult = 1.15; p1.speed = 1.15
	e.phases = [p0, p1]
	e.abilities = [
		_swing(&"jab",  "Jab",   AbilityRes.Size.LIGHT, 22.0,  1.3, 2.1, 0.6, true),
		_swing(&"slam", "Slam",  AbilityRes.Size.HEAVY, 112.0, 2.0, 5.0, 1.3, true),
		_swing(&"quake","Quake", AbilityRes.Size.CRUSH, 60.0,  2.6, 12.0, 2.0, false),
		# M7 — the run's combo TEACHER: two honest beats, evenly spaced, no tricks.
		_string(&"onetwo", "One-Two", "Combo!", 80.0, 1.4, 9.0, 1.5, [
			{"at": 0.7, "frac": 0.5, "size": AbilityRes.Size.LIGHT},
			{"at": 1.4, "frac": 0.5, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

static func make_warcaller() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"warcaller"
	e.name = "The Warcaller"
	e.hp = 2500
	e.intro = "Slams come in pairs — you can only answer one. Below 40% it frenzies."
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.12; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.4; p2.mult = 1.3; p2.speed = 1.3
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"jab",   "Jab",        AbilityRes.Size.LIGHT, 24.0,  1.15, 1.9, 0.5, true),
		_swing(&"slam",  "Cleaver",    AbilityRes.Size.HEAVY, 96.0,  1.8,  4.4, 1.2, true),
		_swing(&"crush", "Skullcrack", AbilityRes.Size.CRUSH, 178.0, 2.5,  12.0, 2.0, true),
		_swing(&"roar",  "War Roar",   AbilityRes.Size.CRUSH, 52.0,  2.2,  15.0, 3.0, false),
		# M7 — "slams come in pairs", now literally: an UNEVEN two-beat (the long gap
		# is the trap — don't press early) ending in a blockable crush.
		_string(&"twincleave", "Twin Cleave", "Combo!", 130.0, 1.9, 10.0, 1.8, [
			{"at": 0.8, "frac": 0.45, "size": AbilityRes.Size.HEAVY},
			{"at": 1.9, "frac": 0.55, "size": AbilityRes.Size.CRUSH,
				"guard": StrikeRes.Guard.BLOCKABLE},
		]),
	]
	return e

static func make_colossus() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"colossus"
	e.name = "The Colossus"
	e.hp = 3200
	e.intro = "No jabs to bank here — every swing is a decision. Its Sunder will end a careless run."
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.30; p2.mult = 1.35; p2.speed = 1.35
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"jab",    "Jab",     AbilityRes.Size.LIGHT, 26.0,  1.1, 1.8, 0.5, true),
		_swing(&"maul",   "Maul",    AbilityRes.Size.HEAVY, 120.0, 1.9, 4.0, 1.0, true),
		_swing(&"sunder", "Sunder",  AbilityRes.Size.CRUSH, 210.0, 2.6, 11.0, 2.0, true),
		_swing(&"stomp",  "Stomp",   AbilityRes.Size.CRUSH, 64.0,  2.0, 9.0, 2.0, false),
		# M7 — three falling boulders, the finisher blockable-only: sustained rhythm
		# from the boss with no jabs to breathe between.
		_string(&"rockslide", "Rockslide", "Combo!", 170.0, 2.3, 12.0, 2.0, [
			{"at": 0.8, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 1.5, "frac": 0.3, "size": AbilityRes.Size.HEAVY},
			{"at": 2.3, "frac": 0.4, "size": AbilityRes.Size.CRUSH,
				"guard": StrikeRes.Guard.BLOCKABLE},
		]),
	]
	return e

## Boss self-heal telegraph (HEAL_BOSS): the defensive verb can't stop it. A base
## Warden's only answer is to out-damage it (its default bar has no stagger); a
## stagger cancel — which denies the heal entirely — requires the Juggernaut's
## Avalanche, a drafted Shockwave, or the Vindicate-interrupt boon. `amount` is
## scaled by phase mult, so it heals for MORE the lower the boss gets: the DPS
## check tightens as the fight drags.
static func _heal_cast(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = "Healing!"
	a.effect = AbilityRes.Effect.HEAL_BOSS
	a.amount = amount
	a.cast = cast
	a.cd = cd
	a.jitter = jitter
	a.size = AbilityRes.Size.NONE
	a.response = AbilityRes.Response.UNAVOIDABLE
	a.danger = false            # a swing (Devour) should win scheduler ties over a heal
	return a

## The Devourer — the run's capstone DPS-check. Unlike the first three, it has NO
## jabs to bank: instead it CHIPS you with continuous melee (which still feeds your
## rage) while periodically Regenerating, and it hard-enrages if the fight drags.
## You cannot turtle your way out — you have to keep attacking while you tank, out-
## racing its self-heal before enrage catches you. Exercises three engine features
## the first three bosses never touch: continuous `melee`, `enrage_at`, and HEAL_BOSS.
static func make_devourer() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"devourer"
	e.name = "The Devourer"
	e.hp = 3600
	e.intro = "It knits its wounds shut and grinds you down between swings. Turtle and you lose the race — attack while you tank, or its enrage will end you."
	var p0 := PhaseRes.new(); p0.at = 1.0;  p0.mult = 1.0;  p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.50; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.30; p2.mult = 1.35; p2.speed = 1.35
	# LAST GASP (<=15%): it panics — heals and swings much faster. The finish becomes
	# a burst race: punch through the frantic Regenerates before it claws back out.
	var p3 := PhaseRes.new(); p3.at = 0.15; p3.mult = 1.4;  p3.speed = 1.8
	e.phases = [p0, p1, p2, p3]
	e.melee = {"every": 1.4, "min": 11.0, "max": 17.0}   # constant chip + rage feed
	e.enrage_at = 86.0                                    # hard timer: out-race the heal or die
	e.abilities = [
		_swing(&"gorge",  "Gorge",   AbilityRes.Size.HEAVY, 128.0, 1.9, 4.6, 1.0, true),
		_swing(&"devour", "Devour",  AbilityRes.Size.CRUSH, 205.0, 2.6, 11.0, 2.0, true),
		_heal_cast(&"regen", "Regenerate", 210.0, 2.4, 11.0, 2.0),
		# M7 — a fast, ravenous triplet of bites: eaten bites still feed your rage
		# (on-brand), dodged bites protect the HP you need for the race. Tuned HOT
		# (144 @ cd 10): the Frenzy itself carries the loose-tier difficulty, since
		# strings freeze the other timers and would otherwise soften the fight.
		_string(&"frenzy", "Feeding Frenzy", "Combo!", 144.0, 1.7, 10.0, 2.0, [
			{"at": 0.6, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.15, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.LIGHT},
		]),
	]
	return e

## A Feint: it LOOKS like a real defensible swing (shows a parry prompt at its size)
## so you're tempted to answer it — but the defensive press is a trap
## (BulwarkKit._feint_baited). HOLDING is the correct, rewarded read. Small damage so a
## correct hold barely stings. Comes at BOTH sizes so you can't read it off size alone.
static func _feint(id: StringName, name: String, size: AbilityRes.Size,
		amount: float, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := _swing(id, name, size, amount, cast, cd, jitter, true)
	a.feint = true
	a.tag = "Feint?"
	return a

## A multi-strike STRING (M7): beats resolve progressively during the wind-up and
## each is answered with the universal DODGE, graded by press timing.
## `beats` = [{at, frac, size, guard, feint, aoe}...] — see StrikeRes.
static func _string(id: StringName, name: String, tag: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = tag
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast
	a.cd = cd
	a.jitter = jitter
	a.danger = true
	a.response = AbilityRes.Response.UNAVOIDABLE # the classic guard can't answer a string
	a.size = AbilityRes.Size.HEAVY               # dial fallback colour
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		st.feint = bool(b.get("feint", false))
		st.aoe = bool(b.get("aoe", false))
		a.strikes.append(st)
	return a

## The Duelist — a fencer who baits your guard. The first boss to PUNISH the tank's
## core verb: it mixes real swings (parry them) with Feints (holding is correct;
## pressing guard gets you BAITED — chunk of HP, lost spec resource, guard lockout).
## Read right and the boss is left Exposed (your damage spikes). Feints come at heavy
## AND crush, so neither Aspect can lean on size — you must read the tell. Tests
## discipline, not reflexes — the emotional inverse of the Devourer. No melee, no
## self-heal: every telegraph is a yes/no read, and the cadence tightens as it drops.
static func make_the_duelist() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"duelist"
	e.name = "The Duelist"
	e.hp = 3000
	e.intro = "Most of its swings are lies. Parry the rare real ones; on a Feint DON'T press — guarding the bait is how it lands. Read it right and it's left wide open."
	var p0 := PhaseRes.new(); p0.at = 1.0;  p0.mult = 1.0;  p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.12; p1.speed = 1.25
	# FLURRY (<=25%): the feints come fast — misreads pile up here.
	var p2 := PhaseRes.new(); p2.at = 0.25; p2.mult = 1.25; p2.speed = 1.55
	e.phases = [p0, p1, p2]
	e.enrage_at = 96.0                                   # lenient anti-stall backstop only
	# The reads ARE the fight: feints are frequent, real swings are rarer and softer
	# (a whiffed parry stings but rarely kills) — so the difficulty is the yes/no read,
	# not raw parry timing. Getting baited is the real threat, and it stacks up.
	# INVARIANT: keep every feint `cast` longer than the defense active window
	# (0.34–0.55s) — a feint baits on ANY press during its telegraph, and a shorter
	# cast could let a stale dodge from a prior swing false-bait a correct hold.
	e.abilities = [
		_swing(&"lunge",  "Lunge",  AbilityRes.Size.HEAVY,  92.0, 1.6, 5.6, 1.2, true),
		_feint(&"feint",  "Feint",  AbilityRes.Size.HEAVY,  26.0, 1.5, 3.0, 0.8),
		_swing(&"impale", "Impale", AbilityRes.Size.CRUSH, 166.0, 2.4, 12.5, 2.5, true),
		_feint(&"bluff",  "Bluff",  AbilityRes.Size.CRUSH,  30.0, 2.1, 6.0, 1.2),
		# M7 — the fencer's COMBO: quick opener, a stutter feint on the half-beat,
		# then a blockable crush finisher (even a perfect dodge only shaves it).
		# Dodging the fake locks you out of the finisher — the string tests the
		# same discipline as the whole-swing feints, at rhythm speed.
		_string(&"flourish", "Flourish", "Combo!", 190.0, 2.2, 10.0, 1.6, [
			{"at": 0.9, "frac": 0.30, "size": AbilityRes.Size.HEAVY},
			{"at": 1.5, "feint": true, "size": AbilityRes.Size.HEAVY},
			{"at": 2.2, "frac": 0.55, "size": AbilityRes.Size.CRUSH,
				"guard": StrikeRes.Guard.BLOCKABLE},
		]),
	]
	return e

## The ordered encounter list for a Bulwark run. Difficulty ramps, and the last two
## alternate the two skills: a reads-duel (Duelist) then the DPS-race finale (Devourer).
static func run_encounters() -> Array:
	return [make_gatekeeper(), make_warcaller(), make_colossus(), make_the_duelist(),
		make_devourer()]

## Build a solo Bulwark fight (party of one) for `seed` and `aspect`.
static func make_state(seed: int, aspect: String, cfg: TuningConfig,
		bcfg: BulwarkConfig, enc: EncounterRes, boons: Dictionary = {}) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	s.seats = [_make_tank(aspect, bcfg, boons)]
	return s

## Build the current fight from a RunState (game-layer entry point).
static func build_fight(run: RunState, seed: int) -> CombatState:
	return make_state(seed, run.aspect, make_config(), make_bulwark_config(),
		run.current_encounter(), run.boons)

## Optional 2-seat variant: Bulwark tank + a stat-block DPS ally — used to prove the
## group-damage / ally path works (per the milestone-check advice), even though solo
## Bulwark doesn't need it.
static func make_state_with_ally(seed: int, aspect: String, cfg: TuningConfig,
		bcfg: BulwarkConfig, enc: EncounterRes, ally_dps: float) -> CombatState:
	var s := CombatCore.create_state(enc, cfg, seed)
	var ally := Seat.new()
	ally.role = "dps"; ally.is_player = false; ally.fidelity = "statblock"
	ally.hp_max = 300.0; ally.hp = 300.0; ally.dps = ally_dps
	s.seats = [_make_tank(aspect, bcfg), ally]
	return s

static func _make_tank(aspect: String, bcfg: BulwarkConfig, boons: Dictionary = {}) -> Seat:
	var tank := Seat.new()
	tank.role = "tank"
	tank.is_player = true
	tank.fidelity = "full"
	tank.hp_max = bcfg.hp_max
	tank.hp = bcfg.hp_max
	tank.dps = 0.0                      # damage comes from abilities, not the passive curve
	tank.resource = 0.0
	tank.resource_max = bcfg.rage_max
	var kit := BulwarkKit.new(aspect, bcfg)
	kit.boons = boons
	tank.kit = kit
	tank.policy = BulwarkPolicy.new()
	tank.vars = {"counter": 0, "momentum": 0, "mom_decay_acc": 0.0,
		"last_aggro_tick": 0, "riposte_until_tick": 0}
	return tank
