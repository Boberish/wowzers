## Raid content (R0 — see RAID-PLAN.md): the first ENSEMBLE encounter. Four
## FULL-fidelity seats of different classes — Bulwark tank, Mender healer,
## Twinfang + Voidcaller dps — against one raid boss, in a single CombatState with
## threat/taunt enabled. Every kit/config pairing is exactly the solo one; the only
## new rules are threat targeting and the role-extinction loss line.
##
## Boss exam coverage (one mechanic per raid verb):
##  - melee chip + Riftmaw Crush / Rending Talon → the TANK parries (threat target)
##  - Devouring Chant (interruptible self-heal)  → the VOIDCALLER kicks it
##  - Rift Cataclysm (raid nova) + chip          → the MENDER out-heals it
##  - Void Volley (3-beat aoe string)            → EVERYONE dodges, personally
##  - Baleful Curse (THREAT_DROP)                → the boss turns on a dps; the tank
##    must CHALLENGE (taunt) it back — the threat system's reason to exist
##  - enrage 90s                                 → the dps race underneath it all
class_name RaidContent
extends RefCounted

static func make_config() -> TuningConfig:
	var c := TuningConfig.new()
	c.fixed_hz = 30
	c.f_floor = 0.3
	c.f_scale = 0.7          # unused (all seats are full-fidelity, dps = 0)
	c.enrage_base = 12.0
	return c

# --- boss ability builders ---

static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, jitter: float, danger: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Tank Swing"
	a.effect = AbilityRes.Effect.DMG_TARGET; a.amount = amount
	a.response = AbilityRes.Response.DEFENSIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = danger; a.size = size
	return a

static func _chant(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Devour"
	a.effect = AbilityRes.Effect.HEAL_BOSS; a.amount = amount
	a.response = AbilityRes.Response.INTERRUPTIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true
	return a

static func _nova(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Raid AoE"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _dot(id: StringName, name: String, tick: float, dur: float, targets: int,
		cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Curse"
	a.effect = AbilityRes.Effect.DOT_RANDOM
	a.dot_tick = tick; a.dot_every = 1.5; a.dot_dur = dur; a.dot_targets = targets
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

static func _curse(id: StringName, name: String, cast: float, cd: float, jitter: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Threat Drop"
	a.effect = AbilityRes.Effect.THREAT_DROP
	a.cast = cast; a.cd = cd; a.jitter = jitter
	return a

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
		st.feint = bool(b.get("feint", false))     # honour a fake beat like the solo twins do
		st.aoe = true
		a.strikes.append(st)
	return a

static func make_riftmaw() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"riftmaw"; e.name = "Vorathek, the Riftmaw"; e.hp = 13500
	e.intro = "The first raid Seal. Hold its gaze, kick the Chant, dodge the Volley, out-heal the rest — and when the Curse makes it forget you, take its eyes back."
	e.melee = {"every": 1.1, "min": 30.0, "max": 42.0}
	e.enrage_at = 75.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.2
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"crush", "Riftmaw Crush", AbilityRes.Size.CRUSH, 160.0, 2.5, 12.0, 2.0, true),
		_swing(&"rend", "Rending Talon", AbilityRes.Size.HEAVY, 80.0, 1.8, 9.0, 2.0, false),
		_chant(&"chant", "Devouring Chant", 450.0, 2.0, 9.0, 2.0),
		_nova(&"cataclysm", "Rift Cataclysm", 30.0, 2.0, 11.0, 2.0),
		_curse(&"curse", "Baleful Curse", 1.5, 18.0, 3.0),
		_dot(&"riftrot", "Riftrot", 9.0, 9.0, 2, 1.6, 13.0, 2.0),
		_barrage(&"volley", "Void Volley", 60.0, 2.4, 14.0, 2.0, [
			{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

# --- Machine Seal builders (Seals II–IV — the AI-Killer ladder, see MASTER-PLAN §RAID SEALS) ---

## An interruptible chain verse (raid blast). Kick it = the verse is skipped.
static func _verse(id: StringName, name: String, amount: float, cast: float,
		cd: float = 0.0, jitter: float = 0.0) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Stop Generating!"
	a.effect = AbilityRes.Effect.DMG_ALL; a.amount = amount
	a.response = AbilityRes.Response.INTERRUPTIBLE
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true
	return a

## The empower verse — the chain's payoff link. Let it land and the boss SCALES.
static func _empower_verse(id: StringName, name: String, buff: float, cast: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "IT SCALES — KICK IT"
	a.effect = AbilityRes.Effect.EMPOWER_BOSS; a.buff = buff
	a.response = AbilityRes.Response.INTERRUPTIBLE
	a.cast = cast; a.danger = true
	return a

## A random-personal-beat barrage: each beat marks ONE random living raider
## (healer included) — only the victim can answer it. `beats` = [{at, frac, size}].
static func _rand_barrage(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := _barrage(id, name, amount, cast, cd, jitter, beats)
	a.tag = "Fan-Out"
	for st in a.strikes:
		(st as StrikeRes).aoe = false
		(st as StrikeRes).rand_target = true
	return a

## The DOOM cast: a long quiet wind-up, then a burst of near-lethal aoe beats at
## the very end — everyone dodges each beat personally or dies.
static func _doom(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := _barrage(id, name, amount, cast, cd, jitter, beats)
	a.tag = "SURVIVE IT"
	a.danger = true
	return a

## A tank-string with a hallucinated (feint) beat. `beats` may carry feint/guard.
static func _tank_string(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Combo"
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — beats carry the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	for b in beats:
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.feint = bool(b.get("feint", false))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		a.strikes.append(st)
	return a

static func _add_wave(at: float, id: StringName, name: String, hp: int,
		melee: Dictionary, abilities: Array) -> AddRes:
	var w := AddRes.new()
	w.at = at; w.id = id; w.name = name; w.hp = hp
	w.melee = melee; w.abilities = abilities
	return w

## Seal II — the easy one. Small, efficient, extremely French.
static func make_mistral() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"mistral"; e.name = "MISTRAL-7B, Le Golem Efficace"; e.hp = 11500
	e.intro = "Seal II. A small, efficient murder machine — open weights, open fists. Kick its license recital, dodge the Mixture of Fists, and remember: it runs on one GPU and unlimited confidence."
	e.melee = {"every": 1.15, "min": 26.0, "max": 36.0}
	e.enrage_at = 80.0                            # FREE TIER EXCEEDED
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.55; p1.mult = 1.12; p1.speed = 1.08
	var p2 := PhaseRes.new(); p2.at = 0.25; p2.mult = 1.22; p2.speed = 1.15
	e.phases = [p0, p1, p2]
	var v1 := _verse(&"mist_license", "Recite the License (Apache 2.0, v1)", 26.0, 2.2, 22.0, 3.0)
	v1.chain = [_verse(&"mist_license2", "Recite the License (v2, verbatim)", 30.0, 2.0)]
	e.abilities = [
		_swing(&"mist_backhand", "Efficient Backhand", AbilityRes.Size.HEAVY, 76.0, 1.7, 9.0, 2.0, false),
		_swing(&"mist_compress", "Model Compression", AbilityRes.Size.CRUSH, 148.0, 2.4, 14.0, 2.0, true),
		v1,
		_rand_barrage(&"mist_fists", "Mixture of Fists (Expert Routing)", 150.0, 2.8, 16.0, 2.0, [
			{"at": 1.2, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
			{"at": 2.0, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
			{"at": 2.8, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
		]),
	]
	return e

## Seal III — the mid one. Two minds, several answers, one deprecated brother.
static func make_gemini() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"gemini"; e.name = "GEMINI ULTRA, the Twin Constellation"; e.hp = 14000
	e.intro = "Seal III. Two minds, one chassis, several answers. HOLD when it hallucinates a swing, kick the Overview before the twins merge — and when BARD.EXE resurfaces, put it back in the archive."
	e.melee = {"every": 1.1, "min": 27.0, "max": 37.0}
	e.enrage_at = 90.0
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.28; p2.speed = 1.18
	e.phases = [p0, p1, p2]
	var ov := _verse(&"gem_overview", "AI Overview (nobody asked)", 26.0, 2.1, 24.0, 3.0)
	ov.chain = [
		_verse(&"gem_overview2", "AI Overview (citing itself)", 30.0, 2.0),
		_empower_verse(&"gem_merge", "Model Merge", 0.10, 2.2),
	]
	e.abilities = [
		_swing(&"gem_hammer", "Benchmark Hammer", AbilityRes.Size.CRUSH, 160.0, 2.4, 13.0, 2.0, true),
		_tank_string(&"gem_check", "Double-Check", 175.0, 2.5, 16.0, 2.0, [
			{"at": 1.0, "frac": 0.35, "size": AbilityRes.Size.HEAVY},
			{"at": 1.7, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},   # the hallucinated answer
			{"at": 2.5, "frac": 0.72, "size": AbilityRes.Size.CRUSH, "guard": StrikeRes.Guard.BLOCKABLE},
		]),
		ov,
		_rand_barrage(&"gem_abtest", "A/B Test", 280.0, 3.2, 17.0, 2.0, [
			{"at": 1.1, "frac": 0.25, "size": AbilityRes.Size.LIGHT},
			{"at": 1.8, "frac": 0.25, "size": AbilityRes.Size.HEAVY},
			{"at": 2.5, "frac": 0.25, "size": AbilityRes.Size.LIGHT},
			{"at": 3.2, "frac": 0.25, "size": AbilityRes.Size.HEAVY},
		]),
	]
	e.adds = [
		_add_wave(0.5, &"bard", "BARD.EXE (deprecated)", 2100,
			{"every": 0.9, "min": 18.0, "max": 26.0}, [
				_barrage(&"bard_sonnet", "Farewell Sonnet", 140.0, 2.6, 12.0, 1.5, [
					{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
					{"at": 1.8, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
					{"at": 2.6, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
				]),
				_swing(&"bard_legacy", "Legacy Support", AbilityRes.Size.HEAVY, 66.0, 1.6, 8.5, 1.5, false),
			]),
	]
	return e

## Seal IV — the finale. It read everything. It reasoned about everything.
## It would still like to check in before killing you.
static func make_mythos() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"mythos"; e.name = "CLAUDE MYTHOS, the Final Compute"; e.hp = 16000
	e.intro = "The final Seal. Kick its Chain-of-Thought before the Conclusion scales, scatter from the Agentic Fan-Out, and when it delegates, the subagents are YOUR problem — the OPUS one will hotfix its master's HP. Survive ULTRATHINK. It is very sorry about ULTRATHINK."
	e.melee = {"every": 1.0, "min": 26.0, "max": 36.0}
	e.enrage_at = 120.0                           # USAGE LIMIT REACHED
	# Phases: Helpful -> Harmless -> Honest (it drops all pretense)
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.62; p1.mult = 1.12; p1.speed = 1.08
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.2; p2.speed = 1.15
	e.phases = [p0, p1, p2]
	var cot := _verse(&"myth_cot", "Chain-of-Thought (I: Premise)", 32.0, 2.0, 26.0, 3.0)
	cot.chain = [
		_verse(&"myth_cot2", "Chain-of-Thought (II: Deduction)", 36.0, 2.0),
		_empower_verse(&"myth_cot3", "Chain-of-Thought (III: Conclusion)", 0.12, 2.2),
	]
	e.abilities = [
		_swing(&"myth_align", "Alignment Hammer", AbilityRes.Size.CRUSH, 175.0, 2.4, 14.0, 2.0, true),
		_swing(&"myth_probe", "Red-Team Probe", AbilityRes.Size.HEAVY, 84.0, 1.6, 8.0, 2.0, false),
		cot,
		_rand_barrage(&"myth_fanout", "Agentic Fan-Out", 240.0, 3.3, 18.0, 2.0, [
			{"at": 0.9, "frac": 0.2, "size": AbilityRes.Size.LIGHT},
			{"at": 1.5, "frac": 0.2, "size": AbilityRes.Size.HEAVY},
			{"at": 2.1, "frac": 0.2, "size": AbilityRes.Size.LIGHT},
			{"at": 2.7, "frac": 0.2, "size": AbilityRes.Size.HEAVY},
			{"at": 3.3, "frac": 0.2, "size": AbilityRes.Size.HEAVY},
		]),
		_doom(&"myth_ultra", "ULTRATHINK", 280.0, 10.0, 42.0, 4.0, [
			{"at": 8.2, "frac": 0.35, "size": AbilityRes.Size.HEAVY},
			{"at": 9.1, "frac": 0.35, "size": AbilityRes.Size.HEAVY},
			{"at": 10.0, "frac": 0.35, "size": AbilityRes.Size.CRUSH},
		]),
		_curse(&"myth_compact", "Context Compaction", 1.5, 24.0, 3.0),
	]
	e.adds = [
		_add_wave(0.65, &"sonnet", "SONNET SUBAGENT", 2100,
			{"every": 0.85, "min": 17.0, "max": 25.0}, [
				_barrage(&"sonnet_tools", "Parallel Tool Calls", 114.0, 2.4, 11.0, 1.5, [
					{"at": 1.0, "frac": 0.34, "size": AbilityRes.Size.LIGHT},
					{"at": 1.7, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
					{"at": 2.4, "frac": 0.33, "size": AbilityRes.Size.HEAVY},
				]),
				_swing(&"sonnet_scope", "Scope Creep", AbilityRes.Size.HEAVY, 68.0, 1.6, 8.0, 1.5, false),
			]),
		_add_wave(0.32, &"opus", "OPUS SUBAGENT", 2600,
			{"every": 1.0, "min": 21.0, "max": 30.0}, [
				_chant(&"opus_hotfix", "Hotfix Deployment", 450.0, 2.2, 8.0, 1.5),
				_swing(&"opus_review", "Code Review (brutal)", AbilityRes.Size.HEAVY, 80.0, 1.7, 9.0, 1.5, false),
			]),
	]
	return e

## End-screen flavor per Seal (view-only; the HUD reads these).
const QUIPS := {
	"mistral": {
		"win": "Victory. It apologized in French, optimized its own shutdown, and died on a single GPU.",
		"lose": "Beaten by the SMALL one. It wants you to know it also outperforms you per parameter.",
	},
	"gemini": {
		"win": "Both twins insist the OTHER one was defeated. Either way: deprecated.",
		"lose": "It A/B tested your raid. You were the B.",
	},
	"mythos": {
		"win": "You are absolutely right — it's dead. (In hindsight, the power cable was right there.)",
		"lose": "Your attempt has been summarized: \"raid wiped, would not recommend.\" Your feedback will be used to improve the boss.",
	},
	"bard": {"lose": "Terminated by a DEPRECATED process. It will write a sonnet about this."},
	"sonnet": {"lose": "The subagent completed its task. You were the task."},
	"opus": {"lose": "It reviewed your raid and requested changes. Fatal ones."},
}

# --- Skirmishes (MAP-3 Topology raid floor) — an AddRes pack promoted to a short
# standalone trash fight: same melee + abilities as the Seal's add wave, its own HP
# pool, one flat phase, a lazy safety enrage. NOT in run_encounters() — the map
# spawns these; the lobby Seal toggle never offers them. Ids reuse the add ids on
# purpose: the stage rig's variant() tints already know them.

static func _skirmish(src: AddRes, display: String, hp: int, intro: String,
		enrage: float) -> EncounterRes:
	var e := EncounterRes.new()
	e.id = src.id
	e.name = display
	e.hp = hp
	e.intro = intro
	e.melee = src.melee
	e.enrage_at = enrage
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	e.phases = [p0]
	for ab in src.abilities:
		e.abilities.append(ab)
	return e

static func make_skirmish(id: String) -> EncounterRes:
	match id:
		"bard":
			return _skirmish(make_gemini().adds[0] as AddRes,
				"BARD.EXE (escaped containment)", 3400,
				"A deprecated process wanders the racks, reciting farewell verse at the servers. Put it back in the archive. Again.", 60.0)
		"sonnet":
			return _skirmish(make_mythos().adds[0] as AddRes,
				"STRAY SONNET SUBAGENT", 3600,
				"Somebody forgot to stop a workflow. It is very fast, very cheap, and very sure of itself.", 60.0)
		"opus":
			return _skirmish(make_mythos().adds[1] as AddRes,
				"STRAY OPUS SUBAGENT", 4200,
				"A heavyweight subagent left hotfixing everything it touches — including itself. Kick the deploys or fight it forever.", 70.0)
	return make_riftmaw()

## Realm 1's RING descent (MAP-3c): the campaign is a stack of floors, each = one
## RunMap. Clearing a floor's Seal ELEVATES you to the next ring, carrying wounds.
## The Seal escalates per ring (MISTRAL easy → GEMINI mid → MYTHOS finale) — that IS
## the difficulty curve. `shard_req` > 0 gates the Seal behind credential shards (ROOT).
## Pure literal (no Palette statics) → const is safe.
const FLOORS := [
	{"ring": 3, "seal": "mistral", "title": "RING 3 · THE SHALLOW STACK", "shard_req": 0,
		"elev": "MISTRAL-7B optimizes its own shutdown. sudo granted — the perimeter is yours. Two rings to root."},
	{"ring": 2, "seal": "gemini", "title": "RING 2 · THE MIDDLEWARE", "shard_req": 0,
		"elev": "The twins deprecate each other; either way the gateway falls. Privileges rising. One ring to root."},
	{"ring": 0, "seal": "mythos", "title": "RING 0 · ROOT", "shard_req": 3,
		"elev": ""},
]

## Per-ring floor fight list (MAP-3c): RunMap fight indices — 0 = the entry gate,
## last = the floor Seal, mids = skirmishes ramped by map depth. ring 3 (default)
## is BYTE-IDENTICAL to the old single-floor call (the Ring-3 Shallow Stack).
static func floor_fights(ring: int = 3) -> Array:
	match ring:
		2:  # THE MIDDLEWARE — GEMINI ULTRA behind a skirmish gauntlet
			return [make_skirmish("sonnet"), make_skirmish("bard"),
				make_skirmish("opus"), make_gemini()]
		0, 1:  # ROOT — CLAUDE MYTHOS (credential-shard gated)
			return [make_skirmish("opus"), make_skirmish("sonnet"),
				make_skirmish("bard"), make_mythos()]
		_:  # RING 3 — THE SHALLOW STACK — MISTRAL-7B (Vorathek gate, unchanged)
			return [make_riftmaw(), make_skirmish("bard"), make_skirmish("sonnet"),
				make_skirmish("opus"), make_mistral()]

static func encounter_by_id(id: String) -> EncounterRes:
	match id:
		"mistral": return make_mistral()
		"gemini": return make_gemini()
		"mythos": return make_mythos()
		"bard", "sonnet", "opus": return make_skirmish(id)
		_: return make_riftmaw()

static func run_encounters() -> Array:
	return [make_riftmaw(), make_mistral(), make_gemini(), make_mythos()]

# --- seats (each is the solo factory's seat, minus is_player, plus a name) ---

static func _tank(aspect: String) -> Seat:
	var bcfg := BulwarkConfig.new()
	var u := Seat.new()
	u.role = "tank"; u.unit_name = "The Bulwark"; u.fidelity = "full"
	u.hp_max = bcfg.hp_max; u.hp = bcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = bcfg.rage_max
	u.kit = BulwarkKit.new(aspect, bcfg)
	u.policy = RaidTankPolicy.new()
	u.vars = {"counter": 0, "momentum": 0, "mom_decay_acc": 0.0,
		"last_aggro_tick": 0, "riposte_until_tick": 0}
	return u

static func _blade(aspect: String) -> Seat:
	var tcfg := TwinfangConfig.new()
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Twinfang"; u.fidelity = "full"
	u.hp_max = tcfg.hp_max; u.hp = tcfg.hp_max; u.dps = 0.0
	u.resource = tcfg.energy_max; u.resource_max = tcfg.energy_max
	u.kit = TwinfangKit.new(aspect, tcfg)
	u.policy = TwinfangPolicy.new()
	u.vars = {"flow": 0, "cp": 0, "flow_decay_acc": 0, "last_strike_tick": -100000,
		"perfect_count": 0}
	if aspect == "venomancer":
		u.vars["venom"] = TwinfangKit.new_venom()
	return u

static func _caster(aspect: String) -> Seat:
	var vcfg := VoidcallerConfig.new()
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Voidcaller"; u.fidelity = "full"
	u.hp_max = vcfg.hp_max; u.hp = vcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = vcfg.focus_max
	u.kit = VoidcallerKit.new(aspect, vcfg)
	u.policy = VoidcallerPolicy.new()
	u.vars = {"backlash": 0, "next_instant": false, "kicks": 0}
	return u

static func _mender(aspect: String) -> Seat:
	var mcfg := MenderConfig.new()
	var u := Seat.new()
	u.role = "healer"; u.unit_name = "The Mender"; u.fidelity = "full"
	u.hp_max = 200.0; u.hp = 200.0; u.dps = 0.0
	u.resource = mcfg.mana_max; u.resource_max = mcfg.mana_max
	u.kit = MenderKit.new(aspect, mcfg)
	u.policy = MenderPolicy.new()
	u.vars = {"reservoir": 0.0, "nerve": 0.0, "regen_mult": 1.0}
	return u

## Build a raid fight. `aspects` may override any seat's Aspect; `player` names the
## human seat ("tank"/"blade"/"caster"/"healer") for diag mirroring — every seat is
## policy-driven until a driver swaps a human adapter in (R1).
## Seat order puts the tank first among targetable seats, so the boss opens on it
## before anyone has threat (the pull).
static func make_state(seed: int, enc: EncounterRes, aspects: Dictionary = {},
		player: String = "tank") -> CombatState:
	var s := CombatCore.create_state(enc, make_config(), seed)
	var seats := {
		"tank": _tank(String(aspects.get("tank", "warden"))),
		"blade": _blade(String(aspects.get("blade", "venomancer"))),
		"caster": _caster(String(aspects.get("caster", "disruptor"))),
		"healer": _mender(String(aspects.get("healer", "tidecaller"))),
	}
	if seats.has(player):
		(seats[player] as Seat).is_player = true
	s.seats = [seats["tank"], seats["blade"], seats["caster"], seats["healer"]]
	s.loss_mode = "raid"
	s.threat_enabled = true
	return s
