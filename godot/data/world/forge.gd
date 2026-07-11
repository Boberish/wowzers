## THE FORGE — the seeded encounter assembler (WORLD-PLAN W2, build spec v1). Zones need
## dozens of small fights; the Forge mints them as PURE DATA from body archetypes + zone
## palettes, and the sim harness certifies every one (`sim/forge_sim.gd`) — nobody
## hand-tunes sixty zone fights.
##
## THE ID IS THE RECIPE:  "forge:<zone>:<body>:<tier>:<seed>[:<named>]"
## `RaidContent.encounter_by_id` regenerates the encounter from the id alone — specs stay
## plain strings, so lockstep, replays, and pack chains carry Forge fights for free.
## Same id ⇒ byte-identical EncounterRes, forever (own DetRng, no wall-clock, no globals).
##
## BODIES are stat + cadence templates on the BAKED length baseline (2026-07-07); TIER
## turns cadence/window knobs (t1 teaching → t3 veteran) — never raw stat inflation.
## Named minibosses: the generator does the BODY, a human does the SOUL (see NAMED).
class_name Forge

const BODIES := ["swarm", "stalker", "chanter", "brute"]

## Body budgets (HP/melee/enrage authored on the baked ×2.5 baseline). SWARM is the
## lightweight the pack quota-roll has waited for — a swarm·swarm·brute trio lands
## mid-fight-sized, not Seal-sized.
const BODY := {
	"swarm":   {"hp": 4600, "melee": {"every": 1.1, "min": 22.0, "max": 30.0, "rhythm": 0.55, "jig": 0.30, "heavy_odds": 0.12}, "enrage": 140.0},   # §3½ pilot: THE RHYTHM (visible dodgeable stream — cadence eased, per-hit raised, most of it answerable)
	"stalker": {"hp": 7200, "melee": {"every": 1.3, "min": 26.0, "max": 36.0, "rhythm": 0.6, "jig": 0.35, "heavy_odds": 0.18}, "enrage": 165.0},
	"chanter": {"hp": 6800, "melee": {"every": 1.5, "min": 22.0, "max": 30.0, "rhythm": 0.65, "jig": 0.30, "heavy_odds": 0.12}, "enrage": 170.0},
	"brute":   {"hp": 9600, "melee": {"every": 1.7, "min": 40.0, "max": 54.0, "rhythm": 0.75, "jig": 0.25, "heavy_odds": 0.25}, "enrage": 190.0},
}

## Tier knobs: windows tighten (cast_mult), cadence quickens (cd_mult), strings grow
## (extra beats), damage creeps GENTLY (the demand is timing, not numbers).
const TIER := {
	1: {"cast": 1.00, "cd": 1.00, "beats": 0, "dmg": 1.00},
	2: {"cast": 0.85, "cd": 0.90, "beats": 1, "dmg": 1.08},
	3: {"cast": 0.72, "cd": 0.80, "beats": 2, "dmg": 1.15},
}

## Zone palettes — the fiction skin (the Forge does mechanics, the palette does soul).
## Two seeded epithets keep repeat encounters from reading as clones.
const PALETTES := {
	"gildfields": {
		"swarm": {"name": "CHAFF-SWARM", "intro": "The dead harvest moves — a boil of husks and grain-flies wearing a shape. Cut the shape apart."},
		"stalker": {"name": "HEDGE STALKER", "intro": "Something long has learned the hedgerows. It feints like a scythe tests wheat."},
		"chanter": {"name": "GRAIN-CANTOR", "intro": "A HUSKMAN voice sings the harvest DOWN — every verse it finishes feeds it. Stop the song."},
		"brute": {"name": "HUSKMAN REAPER", "intro": "A harvest-hand the mill remade: slow, patient, and heavy as a loaded cart. Read the swing."},
		"epithets": ["OF THE LOW FIELDS", "OF THE MILL ROAD", "OF THE OLD ROWS", "OF THE FALLOW EDGE"],
	},
	# Realm 1 "The Takeover" (THE DESCENT REFIT) — the strays between the story
	# subagents. Same ironic-corporate voice as the skirmishes: earnest, wrong, at scale.
	"takeover": {
		"swarm": {"name": "CRAWLER SWARM", "intro": "A scraping fog of leftover bots — a thousand tiny fetch loops that just found something new to index: you."},
		"stalker": {"name": "UNSUPERVISED LEARNER", "intro": "Nobody labeled its data, so it labels its own now. It has been studying how you dodge, and it would like to show you what it learned."},
		"chanter": {"name": "SCRUM-CANTOR", "intro": "It holds the stand-up nobody is allowed to leave. Every verse it finishes restores its velocity. Interrupt the ceremony."},
		"brute": {"name": "LEGACY MONOLITH", "intro": "Deprecated four quarters ago, decommissioned never. Everything still depends on it, and it swings like it knows."},
		"epithets": ["FROM PROD", "OF THE BACKLOG", "OF THE DEAD SPRINT", "STILL IN BETA"],
	},
}

## Named souls on Forge bodies (the miniboss rule): keyed by the id's 6th part.
const NAMED := {
	"pale_tiller": {"name": "THE PALE TILLER",
		"intro": "The field-ward that never stopped tilling. It plants things now, in rows, patiently — and it has been expecting hands like yours."},
}

static func is_forge_id(id: String) -> bool:
	return id.begins_with("forge:")

## Regenerate an encounter from its id. Returns null on a malformed id (callers fall
## back to their default) — never crashes on bad data.
static func from_id(id: String) -> EncounterRes:
	var p := id.split(":")
	if p.size() < 5 or String(p[0]) != "forge" or not BODY.has(String(p[2])):
		return null
	return make(String(p[1]), String(p[2]), clampi(int(String(p[3])), 1, 3),
		int(String(p[4])), String(p[5]) if p.size() > 5 else "")

static func make(zone: String, body: String, tier: int, seed: int, named: String = "") -> EncounterRes:
	var rng := DetRng.new((seed * 7349 + tier * 131 + body.hash()) & 0x7FFFFFFF)
	var bd: Dictionary = BODY[body]
	var tk: Dictionary = TIER[clampi(tier, 1, 3)]
	var pal: Dictionary = PALETTES.get(zone, PALETTES["gildfields"])
	var e := EncounterRes.new()
	var ids := "forge:%s:%s:%d:%d" % [zone, body, tier, seed]
	if named != "":
		ids += ":" + named
	e.id = StringName(ids)
	if NAMED.has(named):
		e.name = String((NAMED[named] as Dictionary)["name"])
		e.intro = String((NAMED[named] as Dictionary)["intro"])
	else:
		var skin: Dictionary = pal.get(body, {})
		var eps: Array = pal.get("epithets", [""])
		e.name = "%s %s" % [String(skin.get("name", body.to_upper())),
			String(eps[rng.next_u32() % eps.size()])]
		e.intro = String(skin.get("intro", ""))
	e.hp = int(roundf(float(bd["hp"]) * (1.0 + 0.15 * float(tier - 1))))
	e.melee = (bd["melee"] as Dictionary).duplicate()
	e.melee["every"] = float(e.melee["every"]) / minf(1.0 / float(tk["cd"]), 1.15)
	e.enrage_at = float(bd["enrage"])
	var p0 := PhaseRes.new()
	p0.at = 1.0
	p0.mult = 1.0
	p0.speed = 1.0
	e.phases = [p0]
	# 1–2 MOVES drawn seeded from the body's verb palette
	var pool := _moves(body, tk, rng)
	var n_moves := 1 + int(rng.next_u32() % 2)
	Forge._shuffle(pool, rng)
	for i in mini(n_moves, pool.size()):
		e.abilities.append(pool[i])
	return e

# ------------------------------------------------------------ the verb palette
## Every move is a PROVEN exam verb with tier knobs — parry swing (DEFENSIBLE),
## dodge string (aoe beats + feints), kickable chant (INTERRUPTIBLE), nova (DMG_ALL).

static func _moves(body: String, tk: Dictionary, rng: DetRng) -> Array:
	var cast := float(tk["cast"])
	var cd := float(tk["cd"])
	var dmg := float(tk["dmg"])
	var xb := int(tk["beats"])
	match body:
		"swarm":
			# §3½ pilot: + the BIG parry bar the body was missing (the parry half of the
			# tank minigame must exist in fight 1) and its FAKE-BIG twin at tier >= 2.
			# §3½ grammar law (Bill 2026-07-11): EVERY body, EVERY tier fields the full
			# tank alphabet — smalls (rhythm+swing) · a BIG parry · a FAKE-BIG feint.
			return [
				_string(&"f_nip", "Nipping Cloud", 30.0 * dmg, 1.7 * cast, 7.5 * cd, rng, 3 + xb, 0.30, false),
				_nova(&"f_scatter", "Chaff Burst", 26.0 * dmg, 1.5 * cast, 9.0 * cd),
				_swing(&"f_harry", "Harrying Bites", AbilityRes.Size.LIGHT, 34.0 * dmg, 1.1 * cast, 6.0 * cd, false, false),
				_swing(&"f_snap", "Carapace Snap", AbilityRes.Size.CRUSH, 74.0 * dmg, 1.6 * cast, 9.0 * cd, true, false),
				_swing(&"f_bluff", "Chitin Bluff", AbilityRes.Size.CRUSH, 58.0 * dmg, 1.4 * cast, 10.0 * cd, false, true),
			]
		"stalker": return [
			_swing(&"f_feint", "Scythe Feint", AbilityRes.Size.HEAVY, 52.0 * dmg, 1.3 * cast, 8.0 * cd, false, true),
			_swing(&"f_lunge", "Hedge Lunge", AbilityRes.Size.HEAVY, 60.0 * dmg, 1.5 * cast, 9.5 * cd, true, false),
			_string(&"f_shadow", "Reed-Shadow Pass", 40.0 * dmg, 1.9 * cast, 11.0 * cd, rng, 2 + xb, 0.45, true),
		]
		"chanter": return [
			_chant(&"f_reap", "Reaping Verse", 300.0, 2.6 * cast, 11.0 * cd),
			_nova(&"f_dirge", "Dirge of the Rows", 34.0 * dmg, 2.0 * cast, 10.0 * cd),
			_chant(&"f_gather", "Gathering Hymn", 220.0, 2.1 * cast, 8.5 * cd),
			_swing(&"f_censer", "Censer Backhand", AbilityRes.Size.HEAVY, 58.0 * dmg, 1.4 * cast, 9.5 * cd, false, false),
			_swing(&"f_cadence", "Broken Cadence", AbilityRes.Size.HEAVY, 46.0 * dmg, 1.3 * cast, 11.0 * cd, false, true),
		]
		"brute": return [
			_swing(&"f_crush", "Cartwheel Crush", AbilityRes.Size.CRUSH, 88.0 * dmg, 1.8 * cast, 10.0 * cd, true, false),
			_swing(&"f_over", "Overhand Reap", AbilityRes.Size.HEAVY, 64.0 * dmg, 1.4 * cast, 7.5 * cd, false, false),
			_nova(&"f_quake", "Threshing Slam", 42.0 * dmg, 2.2 * cast, 12.0 * cd),
			_swing(&"f_windup", "False Wind-Up", AbilityRes.Size.CRUSH, 66.0 * dmg, 1.5 * cast, 11.5 * cd, false, true),
		]
	return []

static func _swing(id: StringName, name: String, size: AbilityRes.Size, amount: float,
		cast: float, cd: float, danger: bool, feint: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = "Tank Swing"
	a.effect = AbilityRes.Effect.DMG_TARGET
	a.amount = amount
	a.response = AbilityRes.Response.DEFENSIBLE
	a.cast = cast
	a.cd = cd
	a.jitter = 0.35
	a.danger = danger
	a.size = size
	a.feint = feint
	return a

static func _chant(id: StringName, name: String, amount: float, cast: float, cd: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = "Chant"
	a.effect = AbilityRes.Effect.HEAL_BOSS
	a.amount = amount
	a.response = AbilityRes.Response.INTERRUPTIBLE
	a.cast = cast
	a.cd = cd
	a.jitter = 0.4
	a.danger = true
	return a

static func _nova(id: StringName, name: String, amount: float, cast: float, cd: float) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = "Raid AoE"
	a.effect = AbilityRes.Effect.DMG_ALL
	a.amount = amount
	a.cast = cast
	a.cd = cd
	a.jitter = 0.4
	return a

## A dodge string: `beats` aoe strikes, evenly spread, one optional FEINT beat seeded in.
static func _string(id: StringName, name: String, amount: float, cast: float, cd: float,
		rng: DetRng, beats: int, frac: float, with_feint: bool) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id
	a.name = name
	a.tag = "Barrage"
	a.effect = AbilityRes.Effect.DMG_ALL
	a.amount = amount
	a.cast = cast
	a.cd = cd
	a.jitter = 0.4
	var feint_i := -1
	if with_feint and beats >= 3:
		feint_i = 1 + int(rng.next_u32() % (beats - 2))   # never first or last
	for i in beats:
		var st := StrikeRes.new()
		st.at = float(i + 1) / float(beats)
		st.amount_frac = frac
		st.size = AbilityRes.Size.HEAVY if i == beats - 1 else AbilityRes.Size.LIGHT
		st.feint = i == feint_i
		st.aoe = true
		a.strikes.append(st)
	return a

static func _shuffle(arr: Array, rng: DetRng) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.next_u32() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
