## Raid content (R0 — see RAID-PLAN.md): the first ENSEMBLE encounter. Four
## FULL-fidelity seats of different classes — Bulwark tank, Well healer,
## Twinfang + Alchemist dps — against one raid boss, in a single CombatState with
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

## BARRAGE RESTORED (tank-v3 S3 / TANK-PLAN §7 item 2, 2026-07-11): the v17 collapse-to-one
## folded every Seal's multi-beat string into a single beat — that string WAS the non-tank
## DODGE RATION, and its loss let the boss chew undodged seats (dps_wipes) and starved the
## channel of shape. Un-collapsed: one StrikeRes per NON-FEINT beat, at its authored `at`,
## carrying that beat's own `frac` (total-to-a-missed-seat unchanged) and size/guard. The
## authored `at`s are always >= dodge_recovery (0.35s) apart, so a one-dodge seat can weave
## every beat — COMBAT PILLAR #2's 3–8 authored dodge-beats/fight. Feints stay OUT raid-side
## (they return per-Seal via the stream, S6; a feint beat carries frac 0 anyway).
static func _barrage(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Barrage"
	a.effect = AbilityRes.Effect.DMG_ALL          # ignored — each beat carries its own payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	for b in beats:
		if bool(b.get("feint", false)):
			continue
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
		st.guard = int(b.get("guard", StrikeRes.Guard.DODGEABLE))
		st.aoe = true
		a.strikes.append(st)
	return a

static func make_riftmaw() -> EncounterRes:
	var e := EncounterRes.new()
	e.id = &"riftmaw"; e.name = "Vorathek, the Riftmaw"; e.hp = 38750   # BASELEN ×2.5 (Bill's fightlen verdict baked in, 2026-07-07)
	e.intro = "The first raid Seal. Hold its gaze, kick the Chant, dodge the Volley, out-heal the rest — and when the Curse makes it forget you, take its eyes back."
	# Melee is the ONE unavoidable, un-freezable pressure (telegraphed abilities freeze
	# each other's timers). With the tank's self-heal cut, this steady chip on the tank
	# IS the healer's core job + the honest mana tax. Tuned up from the solo-era 30-42,
	# but GENTLY — Vorathek is the teaching Seal (Ring 3, the Shallow Stack). The later
	# Seals (Gemini/Mythos) are where the melee + dodge punishment ramps hard.
	# §3½ THE TANK STREAM (Bill 2026-07-11): Vorathek's stream goes VISIBLE — slow,
	# tall, honest (§3 texture row): broad wind-ups, a third of the bars come in TALL.
	e.melee = {"every": 1.25, "min": 34.0, "max": 44.0, "rhythm": 0.85, "jig": 0.25, "heavy_odds": 0.35}
	e.enrage_at = 225.0                           # BASELEN: enrage tracks the ×2.5 pool
	var p0 := PhaseRes.new(); p0.at = 1.0; p0.mult = 1.0; p0.speed = 1.0
	var p1 := PhaseRes.new(); p1.at = 0.6; p1.mult = 1.15; p1.speed = 1.1
	var p2 := PhaseRes.new(); p2.at = 0.3; p2.mult = 1.3; p2.speed = 1.2
	e.phases = [p0, p1, p2]
	e.abilities = [
		_swing(&"crush", "Riftmaw Crush", AbilityRes.Size.CRUSH, 160.0, 2.5, 12.0, 2.0, true),
		_swing(&"rend", "Rending Talon", AbilityRes.Size.HEAVY, 80.0, 1.8, 9.0, 2.0, false),
		_chant(&"chant", "Devouring Chant", 450.0, 2.0, 9.0, 2.0),
		# UNAVOIDABLE raid-wide chip — the healer's baseline work even vs a group that
		# dodges everything. Ramps hard by phase (×1.15 / ×1.3), so healing gets heavier
		# as the fight goes. This is what keeps mana honest.
		_nova(&"cataclysm", "Rift Cataclysm", 42.0, 2.0, 10.0, 2.0),
		_curse(&"curse", "Baleful Curse", 1.5, 18.0, 3.0),
		# Sustained unavoidable DoT on up to 3 raiders — steady triage pressure.
		_dot(&"riftrot", "Riftrot", 10.0, 9.0, 3, 1.6, 12.0, 2.0),
		# DODGE-CHECK (GENTLE on the teacher): a missed beat stings (~20 on a dps) and
		# makes the healer spend, but won't cascade a fresh player into a wipe. This is
		# the knob that gets CRANKED in the later Seals — Vorathek just teaches the motion.
		# cd 13→22 (tank-v3 2026-07-12): §7 item 2 un-collapsed the barrage but its cadence
		# overshot COMBAT PILLAR #2's 3–8 beats/fight (the teacher was firing ~15/fight — the
		# stream-busy tank couldn't weave them all and dropped). Slower cadence lands it in band.
		_barrage(&"volley", "Void Volley", 60.0, 2.4, 22.0, 2.0, [
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

## The DOOM cast: a long quiet wind-up, then a near-lethal aoe finish — the raid-wide
## BRACE (DEC-10): ONE big unavoidable beat every seat answers together, NOT a multi-dodge
## flurry. Unlike the ration-bearing barrages, the doom stays COLLAPSED (spec §7 item 2
## lists _barrage/_tank_string/_rand_barrage — not _doom): un-collapsing it turned
## ULTRATHINK into 3 lethal aoe beats the streaming tank couldn't weave, dropping mythos
## below its baseline. The multi-beat doom returns as a scripted cast-bar BRACE per-Seal at
## S6. Lands at the last beat's `at` (full wind-up), carries the whole amount, biggest size.
static func _doom(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "SURVIVE IT"
	a.effect = AbilityRes.Effect.DMG_ALL          # ignored — the beat carries the payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter; a.danger = true
	var at := 1.0
	var size := AbilityRes.Size.LIGHT
	for b in beats:
		at = maxf(at, float(b.get("at", 1.0)))
		size = maxi(size, int(b.get("size", AbilityRes.Size.HEAVY)))
	var st := StrikeRes.new()
	st.at = at
	st.amount_frac = 1.0
	st.size = size
	st.aoe = true
	a.strikes.append(st)
	return a

## A tank combo — RESTORED (tank-v3 S3): the multi-beat tank string is un-collapsed the same
## way the barrage is, one StrikeRes per NON-FEINT beat at its authored `at`, carrying its own
## frac/size/guard. DMG_TARGET (tank-only, not aoe) so every beat lands on the boss's victim;
## the tank answers them on the judge. Feints stay OUT raid-side (they return per-Seal via the
## stream, S6) — matching the barrage's non-feint rule so both builders share one grammar.
static func _tank_string(id: StringName, name: String, amount: float,
		cast: float, cd: float, jitter: float, beats: Array) -> AbilityRes:
	var a := AbilityRes.new()
	a.id = id; a.name = name; a.tag = "Combo"
	a.effect = AbilityRes.Effect.DMG_TARGET      # ignored — each beat carries its own payload
	a.amount = amount
	a.cast = cast; a.cd = cd; a.jitter = jitter
	for b in beats:
		if bool(b.get("feint", false)):
			continue
		var st := StrikeRes.new()
		st.at = float(b.get("at", 1.0))
		st.amount_frac = float(b.get("frac", 0.0))
		st.size = int(b.get("size", AbilityRes.Size.HEAVY))
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
	e.id = &"mistral"; e.name = "MISTRAL-7B, Le Golem Efficace"; e.hp = 33750   # BASELEN ×2.5
	e.intro = "Seal II. A small, efficient murder machine — open weights, open fists. Kick its license recital, dodge the Mixture of Fists, and remember: it runs on one GPU and unlimited confidence."
	# §3½ THE TANK STREAM (tank-v3 S3 / §7 item 3, DEC-4): Mistral was shipping NO rhythm key,
	# so the tank's channel was BLANK on this Seal — the tank couldn't answer melee, couldn't
	# build flow, and the boss peeled onto the dps (the 27%-win / high-peel regression). Add a
	# rhythm profile so the channel is populated on every Seal (one tank code path). Efficient
	# and quick (fast `every`), a touch fewer talls than the teaching Seal — Mistral's texture.
	e.melee = {"every": 1.1, "min": 34.0, "max": 44.0, "rhythm": 0.75, "jig": 0.28, "heavy_odds": 0.30}   # was 26-36; a pushover at 100/100/100 needed a floor of pressure
	e.enrage_at = 237.5                           # FREE TIER EXCEEDED (BASELEN ×2.5)
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
	e.id = &"gemini"; e.name = "GEMINI ULTRA, the Twin Constellation"; e.hp = 41250   # BASELEN ×2.5
	e.intro = "Seal III. Two minds, one chassis, several answers. HOLD when it hallucinates a swing, kick the Overview before the twins merge — and when BARD.EXE resurfaces, put it back in the archive."
	# §3½ THE TANK STREAM (tank-v3 S3 / §7 item 3, DEC-4): Gemini too shipped NO rhythm key —
	# the 0%-win-at-expert Seal (dps_wipe=40, ~49 peels: a blank channel = no flow = the boss
	# never locked on the tank). Add a rhythm profile between the teaching Seal and Mythos:
	# mid cadence, mid talls, wider jig than Mistral — the twin-minds texture.
	e.melee = {"every": 1.1, "min": 27.0, "max": 37.0, "rhythm": 0.6, "jig": 0.35, "heavy_odds": 0.25}
	e.enrage_at = 270.0                           # BASELEN ×2.5
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
		_tank_string(&"gem_check", "Double-Check", 175.0, 2.5, 22.0, 2.0, [   # cd 16→22: 3-8 beats/fight band
			{"at": 1.0, "frac": 0.35, "size": AbilityRes.Size.HEAVY},
			{"at": 1.7, "frac": 0.0, "size": AbilityRes.Size.HEAVY, "feint": true},   # the hallucinated answer
			{"at": 2.5, "frac": 0.72, "size": AbilityRes.Size.CRUSH, "guard": StrikeRes.Guard.BLOCKABLE},
		]),
		ov,
		_rand_barrage(&"gem_abtest", "A/B Test", 280.0, 3.2, 24.0, 2.0, [   # cd 17→24: 3-8 beats/fight band
			{"at": 1.1, "frac": 0.25, "size": AbilityRes.Size.LIGHT},
			{"at": 1.8, "frac": 0.25, "size": AbilityRes.Size.HEAVY},
			{"at": 2.5, "frac": 0.25, "size": AbilityRes.Size.LIGHT},
			{"at": 3.2, "frac": 0.25, "size": AbilityRes.Size.HEAVY},
		]),
	]
	e.adds = [
		_add_wave(0.5, &"bard", "BARD.EXE (deprecated)", 2100,
			{"every": 0.9, "min": 18.0, "max": 26.0}, [
				_barrage(&"bard_sonnet", "Farewell Sonnet", 140.0, 2.6, 18.0, 1.5, [   # cd 12→18: the add's beat load
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
	e.id = &"mythos"; e.name = "CLAUDE MYTHOS, the Final Compute"; e.hp = 47500   # BASELEN ×2.5
	e.intro = "The final Seal. Kick its Chain-of-Thought before the Conclusion scales, scatter from the Agentic Fan-Out, and when it delegates, the subagents are YOUR problem — the OPUS one will hotfix its master's HP. Survive ULTRATHINK. It is very sorry about ULTRATHINK."
	# §3½ THE TANK STREAM (Bill 2026-07-11): Mythos runs the DENSE end of the §3
	# texture — quick bars, the widest jitter, talls mixed in (all shapes).
	e.melee = {"every": 1.0, "min": 26.0, "max": 36.0, "rhythm": 0.5, "jig": 0.40, "heavy_odds": 0.20}
	e.enrage_at = 355.0                           # USAGE LIMIT REACHED (BASELEN ×2.5)
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
		# cd 18→26 + 5 beats→4 (tank-v3 2026-07-12): the finale's fan-out was the densest in the
		# raid (5 beats × frequent) — over COMBAT PILLAR #2's 3–8/fight band even before the add's
		# barrage stacks on. Drop the 5th beat and slow the cadence into band; frac stays 0.2/beat
		# so each beat's damage is unchanged (total drops one beat's worth — intended relief).
		_rand_barrage(&"myth_fanout", "Agentic Fan-Out", 240.0, 3.3, 26.0, 2.0, [
			{"at": 0.9, "frac": 0.2, "size": AbilityRes.Size.LIGHT},
			{"at": 1.5, "frac": 0.2, "size": AbilityRes.Size.HEAVY},
			{"at": 2.1, "frac": 0.2, "size": AbilityRes.Size.LIGHT},
			{"at": 2.7, "frac": 0.2, "size": AbilityRes.Size.HEAVY},
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
				_barrage(&"sonnet_tools", "Parallel Tool Calls", 114.0, 2.4, 17.0, 1.5, [   # cd 11→17: the add's beat load
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
	# §3½: the skirmish COPY gets THE RHYTHM (0.6 wind-up); the Seal's own add dict is
	# untouched (each make_*() builds fresh instances, and we duplicate besides).
	e.melee = (src.melee as Dictionary).duplicate()
	if not e.melee.is_empty():
		e.melee["rhythm"] = 0.6
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
				"BARD.EXE (escaped containment)", 8500,
				"A deprecated process wanders the racks, reciting farewell verse at the servers. Put it back in the archive. Again.", 95.0)
		"sonnet":
			return _skirmish(make_mythos().adds[0] as AddRes,
				"STRAY SONNET SUBAGENT", 9000,
				"Somebody forgot to stop a workflow. It is very fast, very cheap, and very sure of itself.", 95.0)
		"opus":
			return _skirmish(make_mythos().adds[1] as AddRes,
				"STRAY OPUS SUBAGENT", 10500,
				"A heavyweight subagent left hotfixing everything it touches — including itself. Kick the deploys or fight it forever.", 110.0)
	return make_riftmaw()

## Realm 1's RING descent — THE DESCENT REBUILD (DESCENT-PLAN §2, all 12 verdicts in
## 2026-07-10): a FOUR-floor stack, every floor ending in a Seal, the Rings counting
## down 3-2-1-0 — VORATHEK (the promoted teaching Seal) → MISTRAL → GEMINI → MYTHOS.
## Each floor = one RunMap; clearing its Seal ELEVATES you, carrying wounds.
## Per-floor keys: `rows` sizes the lattice (6=14 nodes · 8=20 · 9=23) · `quota` is
## the FULL non-combat mid bag (RunMap quota_override — DESCENT-PLAN §5; combat pads
## the rest) · `minigame` names the floor's skill-game flavor ("" = seeded rotate) ·
## `tier` drives the Forge pack fillers (F1 teaches on t1 → F4 holds root with t3) ·
## `packroll` = [solo-below, duo-below] thresholds for the walk-in roll — THE FIGHT
## LADDER (DESCENT-PLAN §3): F1 mostly solos (55/35/10) → F4 mostly trios (15/45/40),
## so normal fights grow with the deck instead of by sponge ·
## `shard_req` > 0 gates the Seal behind credential shards (ROOT).
## Pure literal (no Palette statics) → const is safe.
const FLOORS := [
	{"ring": 3, "seal": "riftmaw", "title": "RING 3 · THE PERIMETER", "shard_req": 0, "tickets": 1,
		"rows": 6, "tier": 1, "minigame": "captcha", "packroll": [0.55, 0.90],
		"quota": {"event": 2, "cooling": 1, "market": 1, "minigame": 1},
		"elev": "The Riftmaw falls — the perimeter login is yours. sudo granted. Three rings to root."},
	{"ring": 2, "seal": "mistral", "title": "RING 2 · THE SHALLOW STACK", "shard_req": 0, "tickets": 2,
		"rows": 8, "tier": 2, "minigame": "benchmark", "packroll": [0.30, 0.75],
		"quota": {"elite": 2, "event": 2, "cooling": 1, "cache": 1, "market": 1, "jailbreak": 1, "minigame": 1, "wild": 2},
		"elev": "MISTRAL-7B optimizes its own shutdown. Privileges rising. Two rings to root."},
	{"ring": 1, "seal": "gemini", "title": "RING 1 · THE MIDDLEWARE", "shard_req": 0, "tickets": 2,
		"rows": 8, "tier": 2, "minigame": "benchmark", "packroll": [0.25, 0.70],
		"quota": {"elite": 2, "event": 2, "cooling": 1, "cache": 1, "market": 1, "jailbreak": 1, "minigame": 1, "wild": 2},
		"elev": "The twins deprecate each other; either way the gateway falls. One ring to root."},
	{"ring": 0, "seal": "mythos", "title": "RING 0 · ROOT", "shard_req": 3, "tickets": 3,
		"rows": 9, "tier": 3, "minigame": "", "packroll": [0.15, 0.60],
		"quota": {"elite": 2, "event": 2, "cooling": 2, "cache": 1, "market": 1, "jailbreak": 1, "minigame": 1, "wild": 2},
		"elev": ""},
]

## Per-ring floor fight list: RunMap fight indices — 0 = the entry fight, last = the
## floor Seal, mids ramped by map depth. Takeover-palette Forge strays interleave
## BETWEEN the authored story subagents, tier ramping with the floor (t1→t3).
## THE DESCENT REBUILD: ring 1 is a REAL floor now (GEMINI moved home) — the old
## `0, 1` ROOT alias is split.
static func floor_fights(ring: int = 3) -> Array:
	match ring:
		2:  # THE SHALLOW STACK — MISTRAL-7B behind the t2 gauntlet
			return [make_skirmish("sonnet"), encounter_by_id("forge:takeover:swarm:2:402"),
				make_skirmish("bard"), encounter_by_id("forge:takeover:chanter:2:403"),
				encounter_by_id("forge:takeover:stalker:2:404"),
				make_skirmish("opus"), make_mistral()]
		1:  # THE MIDDLEWARE — GEMINI ULTRA (t2 strays, the deeper cut)
			return [make_skirmish("bard"), encounter_by_id("forge:takeover:stalker:2:407"),
				make_skirmish("sonnet"), encounter_by_id("forge:takeover:chanter:2:408"),
				encounter_by_id("forge:takeover:swarm:2:409"),
				make_skirmish("opus"), make_gemini()]
		0:  # ROOT — CLAUDE MYTHOS (credential-shard gated; t3 strays hold the stack)
			return [make_skirmish("opus"), encounter_by_id("forge:takeover:stalker:3:502"),
				make_skirmish("sonnet"), encounter_by_id("forge:takeover:chanter:3:503"),
				make_skirmish("bard"), encounter_by_id("forge:takeover:brute:3:504"),
				make_mythos()]
		_:  # RING 3 — THE PERIMETER — VORATHEK the promoted teaching Seal (t1 strays)
			return [encounter_by_id("forge:takeover:swarm:1:301"),
				make_skirmish("bard"), encounter_by_id("forge:takeover:stalker:1:303"),
				make_skirmish("sonnet"), encounter_by_id("forge:takeover:chanter:1:304"),
				make_riftmaw()]

## ESCORT / VOLATILE burden (WORLD-PLAN §MEWGENICS STEALS ①): append an enemy-side add to
## a FRESH per-fight encounter so the boss must WITHDRAW to face it — the carried payload
## makes the fight harder without touching the player side (bare-kit / overworld-power law
## holds; the modifier lives on the enemy side). Pure data on enc.adds via the existing
## add-wave engine (combat_core spawns it once when boss HP crosses `at`). Only ever called
## when a spec's carry.burden is set, so absent = byte-identical. `enc` must be a fresh
## factory build (encounter_by_id returns one); we duplicate the adds array before appending.
static func apply_burden(enc: EncounterRes, burden: String) -> void:
	var waves: Array = []
	match burden:
		"grain_rot":
			# TUNE (Bill's feel pass): wave count / HP / cadence are the knobs. TWO husks =
			# a SUSTAINED rot (the boss withdraws to face each), not a single speed bump. The
			# boss's main HP freezes while a husk holds the field, so the waves self-sequence.
			waves = [{"at": 0.8, "hp": 800}, {"at": 0.45, "hp": 800}]
		_:
			return                                        # unknown burden = no-op (still safe)
	var adds: Array = (enc.adds as Array).duplicate()   # never mutate a shared factory array
	for wv in waves:
		var a := AddRes.new()
		a.at = float(wv["at"])
		a.id = &"grain_rot"
		a.name = "ROT-SWOLLEN HUSK"
		a.hp = int(wv["hp"])
		a.melee = {"every": 2.0, "min": 8, "max": 12}
		a.abilities = []
		adds.append(a)
	enc.adds = adds

## E4 (BOSS-PLAN): apply a Seal's SEALTUNE overrides ONCE at build. Empty tune (every fight
## today) = no-op → byte-identical. Build-time scalars only (hp/dmg/cd/melee/enrage); runtime
## keys (window_mult, pacing) are read by the slice that uses them. HEAL/EMPOWER payloads are
## never damage-scaled (they aren't "damage"), matching the sim's --dmg convention.
static func _apply_tune(e: EncounterRes) -> EncounterRes:
	var t := e.tune
	if t.is_empty():
		return e
	if t.has("hp_mult"):
		e.hp = int(round(float(e.hp) * float(t["hp_mult"])))
	if t.has("enrage_at") and float(t["enrage_at"]) > 0.0:
		e.enrage_at = float(t["enrage_at"])
	if t.has("melee") and not e.melee.is_empty():
		var m: Dictionary = t["melee"]
		for k in ["every", "min", "max"]:
			if m.has(k): e.melee[k] = float(m[k])
	var dm := float(t.get("dmg_mult", 1.0))
	var cm := float(t.get("cd_mult", 1.0))
	if dm != 1.0 and not e.melee.is_empty():
		e.melee["min"] = float(e.melee.get("min", 0.0)) * dm
		e.melee["max"] = float(e.melee.get("max", 0.0)) * dm
	if dm != 1.0 or cm != 1.0:
		for ab in e.abilities:
			_tune_ability(ab as AbilityRes, dm, cm)
		for ad in e.adds:
			var a := ad as AddRes
			if dm != 1.0 and not a.melee.is_empty():
				a.melee["min"] = float(a.melee.get("min", 0.0)) * dm
				a.melee["max"] = float(a.melee.get("max", 0.0)) * dm
			for ab in a.abilities:
				_tune_ability(ab as AbilityRes, dm, cm)
	return e

static func _tune_ability(ab: AbilityRes, dm: float, cm: float) -> void:
	if dm != 1.0 and ab.effect != AbilityRes.Effect.HEAL_BOSS \
			and ab.effect != AbilityRes.Effect.EMPOWER_BOSS:
		ab.amount *= dm
		ab.dot_tick *= dm
	if cm != 1.0:
		ab.cd *= cm
	for ch in ab.chain:
		_tune_ability(ch as AbilityRes, dm, cm)

static func encounter_by_id(id: String) -> EncounterRes:
	# THE FORGE (WORLD-PLAN W2): a "forge:" id IS the recipe — regenerate the encounter
	# from the id alone (deterministic), so specs/lockstep/packs carry Forge fights as
	# plain strings. Malformed forge ids fall through to the default (never crash).
	if Forge.is_forge_id(id):
		var f := Forge.from_id(id)
		if f != null:
			return f
	var e: EncounterRes
	match id:
		"mistral": e = make_mistral()
		"gemini": e = make_gemini()
		"mythos": e = make_mythos()
		"bard", "sonnet", "opus": e = make_skirmish(id)
		_: e = make_riftmaw()
	return _apply_tune(e)                # E4: no-op while tune is empty (byte-identical)

static func run_encounters() -> Array:
	return [make_riftmaw(), make_mistral(), make_gemini(), make_mythos()]

# --- seats (each is the solo factory's seat, minus is_player, plus a name) ---

static func _tank(aspect: String) -> Seat:
	# THE DUELIST — the dodge tank (TANK-PLAN, DUELIST-BRIEF). The Bulwark was retired as the
	# playable tank (it survives only as a sim/gear-probe FIXTURE). FLOW + WIND + ◆ live in vars.
	var dcfg := DuelistConfig.new()
	var u := Seat.new()
	u.role = "tank"; u.unit_name = "The Duelist"; u.fidelity = "full"
	u.hp_max = dcfg.hp_max; u.hp = dcfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = 0.0
	u.kit = DuelistKit.new(aspect, dcfg)
	u.policy = DuelistPolicy.new()
	u.vars = {"flow": dcfg.flow_start, "wind": dcfg.wind_max, "combo": 0}
	return u

static func _blade(aspect: String) -> Seat:
	var tcfg := TwinfangConfig.new()   # THE OPENING is live for every raid Twinfang fight (open_enabled default)
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

## The SECOND healer class in the raid: Bloomweaver (anticipate — HoTs + wards, no
## mana; Sap resource + earned Verdance). Same healer SEAT, different CLASS — chosen
## via make_state's `classes` dict / the fight spec's per-seat `cls`. Mirrors the
## solo factory (data/bloomweaver/bloomweaver_content.gd:_make_healer), minus is_player.
static func _bloomweaver(aspect: String) -> Seat:
	var bcfg := BloomweaverConfig.new()
	var u := Seat.new()
	u.role = "healer"; u.unit_name = "The Bloomweaver"; u.fidelity = "full"
	u.hp_max = 200.0; u.hp = 200.0; u.dps = 0.0
	u.resource = bcfg.sap_max; u.resource_max = bcfg.sap_max
	u.kit = BloomweaverKit.new(aspect, bcfg)
	u.policy = BloomweaverPolicy.new()
	u.vars = {"verdance": 0.0}
	return u

## The reworked direct-cast healer (codename "well", MENDER-PLAN.md): discrete CHARGES,
## the graded pour/release, THE CURRENT, the personal GLINT. Same healer SEAT, distinct
## CLASS — the Alchemist idiom, so the old Mender stays byte-identical unless "well" is
## picked. Two aspects: brim (TARGET, grade the landing) / draw (SPEED, grade the release).
static func _well(aspect: String) -> Seat:
	var wcfg := WellConfig.new()
	var u := Seat.new()
	u.role = "healer"; u.unit_name = "The Well-tender"; u.fidelity = "full"
	u.hp_max = 200.0; u.hp = 200.0; u.dps = 0.0
	u.resource = 0.0; u.resource_max = 0.0        # NO mana — the Well is charges (in vars)
	u.kit = WellKit.new(aspect, wcfg)
	u.policy = WellPolicy.new()
	u.vars = {"charges": wcfg.charges_max, "current": 0, "pulse_next": 0}
	return u

## Seat dispatch rides the CLASS REGISTRY (REFIT P4): the registry indexes the
## per-class factories below; an unknown / wrong-seat cls falls back to the seat's
## native class — the exact old ladder semantics (aspect "" → the class default).
static func _healer_seat(cls: String, aspect: String) -> Seat:
	return ClassRegistry.make_seat(cls if ClassRegistry.seat_of(cls) == "healer" else "well", aspect)

## Build the blade seat (Twinfang is the only blade class — Reckoner deleted in THE
## PURGE 2026-07-10; other cls values fall back to it via the registry).
static func _blade_seat(cls: String, aspect: String) -> Seat:
	return ClassRegistry.make_seat(cls if ClassRegistry.seat_of(cls) == "blade" else "twinfang", aspect)

## THE caster-seat class: the Alchemist ("the Brew" — the patient poison/DoT DPS,
## ALCHEMIST-PLAN.md). Sole caster class since THE PURGE 2026-07-10 (Voidcaller deleted).
## ⚠ carries NO kick — NO seat carries one until interrupt-by-ability lands
## (WORLD-PLAN pillar 3): Seal verses go uncontested in the interim, by decision.
static func _alchemist(aspect: String) -> Seat:
	var acfg := AlchemistConfig.new()
	var u := Seat.new()
	u.role = "dps"; u.unit_name = "The Alchemist"; u.fidelity = "full"
	u.hp_max = acfg.hp_max; u.hp = acfg.hp_max; u.dps = 0.0
	u.resource = 0.0; u.resource_max = 100.0     # mirrors POTENCY (0–100)
	u.kit = AlchemistKit.new(aspect, acfg)
	u.policy = AlchemistPolicy.new()
	u.vars = {"venom": 0.0, "rot": 0.0, "charging": "", "charge": 0.0,
		"potency": 0.0, "react_bank": 0.0}
	return u

## Build the caster seat (Alchemist is the only caster class — Voidcaller deleted in
## THE PURGE 2026-07-10; other cls values fall back to it via the registry).
static func _caster_seat(cls: String, aspect: String) -> Seat:
	return ClassRegistry.make_seat(cls if ClassRegistry.seat_of(cls) == "caster" else "alchemist", aspect)

## Build a raid fight. `aspects` may override any seat's Aspect; `player` names the
## human seat ("tank"/"blade"/"caster"/"healer") for diag mirroring — every seat is
## policy-driven until a driver swaps a human adapter in (R1).
## Seat order puts the tank first among targetable seats, so the boss opens on it
## before anyone has threat (the pull).
## `classes` overrides a seat's CLASS (post-purge the only polymorphic seat is the
## healer: well/bloomweaver); `aspects` overrides its Aspect. Defaults = the post-purge
## comp: Bulwark(warden) · Twinfang(venomancer) · Alchemist(brew) · Well(brim).
static func make_state(seed: int, enc: EncounterRes, aspects: Dictionary = {},
		player: String = "tank", classes: Dictionary = {},
		pack: Array = []) -> CombatState:
	var s := CombatCore.create_state(enc, make_config(), seed)
	# PACK (WORLD-PLAN §FIGHT LENGTH): a chain of members for ONE battle. Callers pass
	# resolved EncounterRes with pack[0] == enc (already on the field). Size < 2 is a
	# classic single fight — nothing set, byte-identical.
	if pack.size() >= 2:
		s.pack = pack
	var seats := {
		"tank": _tank(String(aspects.get("tank", "duelist"))),
		"blade": _blade_seat(String(classes.get("blade", "twinfang")), String(aspects.get("blade", ""))),
		"caster": _caster_seat(String(classes.get("caster", "alchemist")),
			String(aspects.get("caster", ""))),
		"healer": _healer_seat(String(classes.get("healer", "well")),
			String(aspects.get("healer", ""))),
	}
	if seats.has(player):
		(seats[player] as Seat).is_player = true
	s.seats = [seats["tank"], seats["blade"], seats["caster"], seats["healer"]]
	s.loss_mode = "raid"
	s.threat_enabled = true
	return s
