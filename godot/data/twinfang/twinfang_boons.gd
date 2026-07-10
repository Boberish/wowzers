## The Twinfang draft pool — the upgrades/relics/spell from poc/twinfang.html, the Opus
## transform, and the Phase-B SLOT-VERB mods (build-your-RHYTHM), as data. Effects are
## implemented in TwinfangKit (keyed by these ids). Draft 2.0: `rarity` = offer frequency
## (never a cap), `tags` = synergy vocabulary; the roll lives in the shared engine (Draft).
## Slot-verbs: entries with `slot` are RHYTHM MOD PIECES — the innate proc moment is
## every PERFECT Strike; triggers add moments, payloads fire on EVERY proc, properties
## reshape the verb. NO LOCKOUTS — all pieces stack.
class_name TwinfangBoons
extends RefCounted

## SHARED — both aspects can draft these (spells + universal utility). Kept small so the
## Venomancer draft (frozen, being redone) isn't flooded with Tempo-only Flow cards.
## D0 S1 TRIM (GO §17.12): Efficiency PARKED 🔮 (Encore kept — base refunds already self-fuel);
## the `strikeEnergy` kit path stays dormant (no card offers it). Pool now empty.
const SHARED := []

## TEMPO — the v4 deck (D0: WOUND · EDGE · FINISH branches + generics + keystones). `theme`
## tags the branch a card serves (generics untagged) — Resonance (S2) counts them. Numbers = base;
## the tier ladder (Slice 2) scales them per instance. VENOM below is frozen (redone later).
const TEMPO := [
	# --- THE WOUND (v4 branch - bleed, then cash) ---
	{"id": "lacerate", "type": "upgrade", "rarity": "haiku", "tags": ["wound", "perfect", "bleed"], "theme": "wound", "title": "Lacerate", "desc": "Perfect Strikes also inscribe a BLEED (half-value) - widen the pot's income past just Bullseyes."},
	{"id": "slowBleed", "type": "upgrade", "rarity": "haiku", "tags": ["wound", "bleed"], "theme": "wound", "title": "Slow Bleed", "desc": "Your bleeds last longer and tick +10% (capped ~5 beats). A fatter, slower pot."},
	{"id": "arterialNote", "type": "relic", "rarity": "sonnet", "tags": ["wound", "bleed", "greed"], "theme": "wound", "title": "Arterial Note", "desc": "Bleeds tick +30% harder but expire a beat sooner - a hotter, shorter pot you must cash in rhythm."},
	# --- THE EDGE (v4 branch - cleanliness becomes crits; the A7 package, offer-gated on a crit source) ---
	{"id": "heartseeker", "type": "relic", "rarity": "sonnet", "tags": ["crit", "bullseye", "strike"], "theme": "edge", "title": "Heartseeker", "desc": "BULLSEYE Strikes (dead centre of the window) are guaranteed crits."},
	{"id": "assassinsNote", "type": "relic", "rarity": "sonnet", "tags": ["crit", "opening", "strike"], "theme": "edge", "title": "Assassin's Note", "desc": "Crits landed inside the Opening deal +50% more - time the dump into the window with a honed blade."},
	{"id": "serrated", "type": "upgrade", "rarity": "haiku", "tags": ["crit", "strike"], "theme": "edge", "title": "Serrated Fate", "desc": "Your crits deal 40% more damage."},
	# --- STRIKE - generics (governor-clamped; no theme, they season every build) ---
	{"id": "throughline", "type": "upgrade", "rarity": "haiku", "tags": ["strike", "perfect"], "title": "Through-Line", "desc": "Consecutive Perfects escalate your Strike damage +2% per stack (cap 5); a Miss resets the line. Reward the unbroken run."},
	{"id": "quickstep", "type": "relic", "rarity": "sonnet", "tags": ["strike", "perfect", "speed", "greed"], "title": "Quickstep", "desc": "Each Perfect speeds AND tightens your next window ~8% - self-bite for pace. The governor keeps it readable; a slip resets the ride."},
	{"id": "pressAdvantage", "type": "relic", "rarity": "sonnet", "tags": ["strike", "opening"], "title": "Press the Advantage", "desc": "Your basic Strikes landed inside the Opening deal +30%. Keep drumming through the punish; don't just wait for the dump."},
	{"id": "coldOpen", "type": "upgrade", "rarity": "haiku", "tags": ["strike", "flow"], "title": "Cold Open", "desc": "While your Flow is 2 or less, your Strikes deal +25% - rebuild from a crash with teeth."},
	{"id": "understudy", "type": "relic", "rarity": "sonnet", "tags": ["defense", "flow"], "title": "Understudy", "desc": "An understudy steps in: the next swing that would crash your Flow is shrugged off (Flow kept). Recharges ~25s. Defence only - it guards your groove, never feeds offence."},
	# --- THE WINDOW - where the green sits ---
	{"id": "wideTempo", "type": "upgrade", "rarity": "haiku", "tags": ["window"], "title": "Wide Tempo", "desc": "Your Perfect window is 15% wider on each side."},
	{"id": "fencersLine", "type": "relic", "rarity": "sonnet", "tags": ["window", "bullseye"], "title": "Fencer's Line", "desc": "A Bullseye widens your windows for the next 3 strikes (+25%) - nail one, the run comes easier."},
	{"id": "rubato", "type": "relic", "rarity": "sonnet", "tags": ["window"], "title": "Rubato", "desc": "The Perfect window sits earlier - same skill, a faster song."},
	# --- FLOW - the greed dial (Momentum/flowCap PARKED, GO trim) ---
	{"id": "tightrope", "type": "relic", "rarity": "sonnet", "tags": ["flow"], "title": "Tightrope", "desc": "While at MAX Flow, your damage is +15% - living on the edge pays."},
	{"id": "battleHymn", "type": "relic", "rarity": "opus", "tags": ["flow", "support"], "title": "Battle Hymn", "desc": "SUPPORT: while you hold high Flow, the whole warband rides your tempo - a haste aura that scales with your Flow tier and blinks off the instant you crash. Your uptime IS the raid buff."},
	{"id": "encore", "type": "upgrade", "rarity": "sonnet", "tags": ["flow"], "title": "Encore", "desc": "The double-hit (Flow Tier 1) kicks in at Flow 2 instead of 3."},
	{"id": "shatterfall", "type": "relic", "rarity": "sonnet", "tags": ["flow", "crash"], "title": "Shatterfall", "desc": "When a slip crashes your Flow from 4+, the shattered tempo detonates for 25 per point lost."},
	# --- THE FINISH (v4 branch - fewer, bigger hits) ---
	{"id": "eviPlus", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "combo"], "theme": "finish", "title": "Deep Cuts", "desc": "Eviscerate deals +8 damage per combo point.", "req": "eviscerate"},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "execute"], "theme": "finish", "title": "Finish It", "desc": "Below 35% boss HP, your Eviscerate deals +35% - hold combo for the kill.", "req": "eviscerate"},
	{"id": "overkill", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "combo"], "theme": "finish", "title": "Overkill", "desc": "Combo built past the cap banks (up to 3) into your next Eviscerate for +6 each.", "req": "eviscerate"},
	{"id": "staccato", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "crash"], "theme": "finish", "title": "Staccato Fury", "desc": "After a Flow crash, your next Eviscerate is FREE and deals +50%.", "req": "eviscerate"},
	{"id": "grandPause", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "combo"], "theme": "finish", "title": "Grand Pause", "desc": "A full-combo (5/5) Eviscerate hits +25% - cash the whole hand (you cannot hold more than max; Overkill's over-cap bank is a separate pot).", "req": "eviscerate"},
	{"id": "heavyInk", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "combo", "greed"], "theme": "finish", "title": "Heavy Ink", "desc": "Combo points above 3 each add +10% to your next finisher; one drips off per missed beat. Hold the fat hand in rhythm.", "req": "eviscerate"},
	# --- COUP DE GRACE (Da Capo parked from the open pool -> returns as the Rondo door, S4) ---
	{"id": "crescendo", "type": "upgrade", "rarity": "haiku", "tags": ["flow", "coupdegrace"], "title": "Crescendo", "desc": "Coup de Grace hits 40% harder."},
	{"id": "onTheBeat", "type": "relic", "rarity": "sonnet", "tags": ["opening", "eviscerate", "coupdegrace"], "title": "On the Beat", "desc": "Dumps fired INSIDE your Strike window take the window's grade multiplier - a Bullseye-timed Eviscerate hits far harder. Time your finishers to the beat, not just the Opening."},
	# --- KEYSTONES (elite; theme-weighted 1-of-2 elite offers, the offer rule) ---
	{"id": "hone", "type": "relic", "rarity": "opus", "tags": ["crit", "strike", "keystone"], "theme": "edge", "title": "Hone", "desc": "KEYSTONE: unlocks the EDGE meter. A Perfect hones +1, a Bullseye +2, a slip dulls -3. While Edge is up, ALL your hits carry crit chance (~4.5% per point, x2 damage) - nothing is spent, so a whiffed dump wastes nothing. Hone the blade with clean rhythm."},
	{"id": "exsanguinate", "type": "relic", "rarity": "opus", "tags": ["wound", "eviscerate", "keystone"], "theme": "wound", "title": "Exsanguinate", "desc": "KEYSTONE: an Eviscerate consuming 5+ live bleeds ERUPTS - the pot detonates as a chained blood-burst across the next 3 beats."},
	{"id": "theCoda", "type": "relic", "rarity": "opus", "tags": ["finish", "eviscerate", "opening", "keystone"], "theme": "finish", "title": "The Coda", "desc": "KEYSTONE: a max-combo Eviscerate inside an Opening ECHOES as a second, free finisher - the double-hit fills the screen."},
	{"id": "doubleTime", "type": "relic", "rarity": "opus", "tags": ["flow", "speed", "keystone"], "title": "Double Time", "desc": "KEYSTONE (class-generic): sustained max-Flow clean play opens ~8s of GHOST half-beats - each Perfect+ also lands a free ghost strike (no Flow risk). Twice the notes, never a faster beat."},
	{"id": "syncopation", "type": "relic", "rarity": "opus", "tags": ["flow", "energy", "keystone"], "title": "Syncopation", "desc": "KEYSTONE (class-generic): at max Flow your Strikes cost no energy - ride the solo forever."},
]

## FERMATA (§13) — the hold-release aspect's own slate, keyed off the coil STATE (COIL / VEIL /
## RELEASE). Every card names the part of the coil it touches (the address rule). Numbers = the
## Haiku rung (Slice-2 ladders scale per instance). The A7 crit package, Crescendo, Da Capo,
## Understudy, Efficiency and the WINDOW bread (Wide Tempo / Fencer's Line / Rubato) CARRY from
## TEMPO/SHARED and work unchanged (Fermata shares Tempo's Flow + window).
const FERMATA := [
	# --- THE ROLL — control where the window lands ---
	{"id": "stretto", "type": "upgrade", "rarity": "haiku", "tags": ["roll", "speed"], "title": "Stretto", "desc": "Your windows roll ~15% nearer — more notes and more cliffs per minute. The speed pole (Stretto: the voices enter closer together)."},
	{"id": "refrain", "type": "relic", "rarity": "sonnet", "tags": ["roll", "precision"], "title": "Refrain", "desc": "A BULLSEYE HOLDS the window in place — your next draw plays the same note (no re-roll). Nail the lip and the game lets you prove it wasn't luck."},
	# --- THE RIDE — how deep you take each note ---
	{"id": "coldCut", "type": "upgrade", "rarity": "haiku", "tags": ["ride", "combo"], "title": "Cold Cut", "desc": "A shallow GOOD-band release grants +1 combo. The safe release stops being a chicken-out and becomes a PLAY — farm combo for Eviscerate instead of chasing the lip."},
	{"id": "theBrink", "type": "relic", "rarity": "sonnet", "tags": ["ride", "greed"], "title": "The Brink", "desc": "A NERVE meter: each Perfect-or-deeper release +1 (max 5), each stack +3% to ALL your damage. A SNAP zeroes it; a plain miss just holds it. Five deep rides and everything bites harder."},
	{"id": "killingWhisper", "type": "upgrade", "rarity": "haiku", "tags": ["release", "bullseye"], "title": "Killing Whisper", "desc": "Bullseye releases deal +15% — the lip's own payoff, the deepest safe strike."},
	# --- THE DRAW — while the needle runs (defense) ---
	{"id": "vanish", "type": "relic", "rarity": "sonnet", "tags": ["draw", "defense"], "title": "Vanish", "desc": "The first boss hit you take during a draw is softened by 50% — the shadow takes it, the note continues. Defence only."},
	{"id": "restlessDark", "type": "upgrade", "rarity": "haiku", "tags": ["draw", "energy"], "title": "Restless Dark", "desc": "Energy regenerates +30% while you're drawing — the stalk pays for itself."},
	{"id": "quietFuse", "type": "upgrade", "rarity": "haiku", "tags": ["draw", "speed"], "title": "Quiet Fuse", "desc": "Your blade sharpens 0.08s sooner and windows may land a touch nearer — everything slightly closer to your hand."},
	{"id": "veilWarband", "type": "relic", "rarity": "opus", "tags": ["draw", "support"], "title": "Veil Over the Warband", "desc": "SUPPORT: while you're drawing the whole warband takes 4% less damage. Your patience is the party's shield."},
	# --- THE REST — idle is a resource ---
	{"id": "composure", "type": "relic", "rarity": "sonnet", "tags": ["rest", "pacing"], "title": "Composure", "desc": "For 2s after a Perfect-or-deeper release your Flow does not decay — rest, Eviscerate, answer a mechanic without bleeding the streak. The song holds its breath while you work."},
	{"id": "firstNote", "type": "upgrade", "rarity": "haiku", "tags": ["rest", "window"], "title": "First Note", "desc": "Rest 1.5s+ before a draw and that window gets +20% ENTRY runway — the lip never moves, just the safe side. A real breath, then a generous note."},
	# --- FLOW & COMEBACK ---
	{"id": "twinEcho", "type": "relic", "rarity": "sonnet", "tags": ["release", "flow"], "title": "Twin Echo", "desc": "Releases at MAX Flow echo a second strike for 30%. At full heat every note doubles."},
	{"id": "firstBlood", "type": "relic", "rarity": "sonnet", "tags": ["release", "crash"], "title": "First Blood", "desc": "Your first release after any miss, SNAP or unravel lands an automatic Perfect — the crash never spirals, one clean note back onto the horse."},
]

## FERMATA keystones (§13.6) — elite-node drops, NEVER in the normal draft pool.
const FERMATA_KEYSTONES := [
	{"id": "unseenBlade", "type": "relic", "rarity": "opus", "tags": ["coil", "keystone"], "title": "The Unseen Blade", "desc": "KEYSTONE: while you REST (idle) you bank a SHADE every 0.7s (max 5); your next release spends them all at +6% each. Resting bleeds Flow but gathers the dark — chain or stalk is a choice every beat."},
	{"id": "eclipse", "type": "relic", "rarity": "opus", "tags": ["release", "bullseye", "keystone"], "title": "Eclipse", "desc": "KEYSTONE: a sharp Bullseye instantly re-draws you, already sharp, and the chained window lands NEAR — bull, bull, bull, a drumroll of dares until one note misses or snaps."},
	{"id": "phantom", "type": "relic", "rarity": "opus", "tags": ["release", "bullseye", "keystone"], "title": "Phantom", "desc": "KEYSTONE: a Bullseye release fires a PHANTOM twin strike for full damage — the second blade from the dark."},
]
const VENOM := [
	{"id": "potent", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Potent Toxins", "desc": "All poison ticks 30% harder."},
	{"id": "fastRot", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Fast Rot", "desc": "Festering grows faster the longer it sits."},
	{"id": "catalyst", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Catalyst", "desc": "Toxic Synergy ramps up 60% faster."},
	{"id": "rupturing", "type": "relic", "rarity": "haiku", "tags": ["rupture", "poison"], "title": "Rupturing Blades", "desc": "Rupture detonates for 40% more."},
	{"id": "contagion", "type": "relic", "rarity": "opus", "tags": ["perfect", "poison"], "title": "Contagion", "desc": "Perfect Strikes also apply a random second poison type — easier to keep all three live."},
	{"id": "debilitate", "type": "relic", "rarity": "sonnet", "tags": ["poison"], "title": "Debilitate", "desc": "Crippling stacks reduce the boss's damage to you (up to 30%)."},
	{"id": "lingerVenom", "type": "relic", "rarity": "sonnet", "tags": ["rupture", "poison"], "title": "Lingering Venom", "desc": "Rupture becomes a SIP: a smaller detonation that keeps HALF your cocktail + Synergy warm. Sustain the brew instead of cratering it."},
]

## D0 S4 · TRANSFORMS — the Floor-2 1-of-3 pick (≤1 per run). Each REWRITES an existing ability
## (the Hades Daedalus-hammer steal at ability scale) and is never a new touch target. Taking one
## gates its 2 sub-boons (below) into later offers. Kit reads `transform`; "" = the vanilla path.
const TRANSFORMS := [
	{"id": "cadenza", "ability": "coup", "title": "Cadenza", "kicker": "Coup, unlocked",
		"desc": "Coup casts from Flow >= 2, consuming whatever you have; damage scales steeply with Flow spent (full-Flow = today's Coup). Cash small before a phase you fear, or ride to max.",
		"doors": ["dalSegno", "bravura"]},
	{"id": "rondo", "ability": "coup", "title": "The Rondo", "kicker": "Coup's second act",
		"desc": "After your Coup, the next 4 beats are THE RETURN: each Perfect+ re-strikes 15% of it (a Bullseye 25%). The crash valley becomes the payoff's second act.",
		"doors": ["secondTheme", "daCapo"]},
	{"id": "tremolo", "ability": "eviscerate", "title": "Tremolo", "kicker": "Eviscerate, a string",
		"desc": "Eviscerate becomes a STRING: up to 3 presses, each spending 2 combo, each graded on its own beat; land all three Perfect+ and the final hit pays +40%.",
		"doors": ["triplet", "rolledChord"]},
]

## The 6 transform DOOR boons — offered ONLY while their transform is held (door-gated by the
## raid draft). Kit hooks live in TwinfangKit (dalSegno/bravura/secondTheme/daCapo/triplet/rolledChord).
const TRANSFORM_DOORS := [
	{"id": "dalSegno", "type": "upgrade", "rarity": "sonnet", "tags": ["coupdegrace", "flow"], "door": "cadenza", "title": "Dal Segno", "desc": "A Cadenza spending 4+ Flow seeds +1 (absorbs Da Capo's job)."},
	{"id": "bravura", "type": "relic", "rarity": "sonnet", "tags": ["coupdegrace", "opening", "greed"], "door": "cadenza", "title": "Bravura", "desc": "A full-Flow Cadenza inside an Opening +25%."},
	{"id": "secondTheme", "type": "upgrade", "rarity": "sonnet", "tags": ["coupdegrace", "flow"], "door": "rondo", "title": "Second Theme", "desc": "The Rondo return re-strikes a tier harder (+10%)."},
	{"id": "daCapo", "type": "relic", "rarity": "sonnet", "tags": ["coupdegrace", "flow"], "door": "rondo", "title": "Da Capo", "desc": "Coup leaves you +1 Flow seed - come back from the top, not from walking pace."},
	{"id": "triplet", "type": "upgrade", "rarity": "sonnet", "tags": ["eviscerate", "bullseye", "greed"], "door": "tremolo", "title": "Triplet", "desc": "An all-Bullseye Tremolo string pays the final hit +40% more."},
	{"id": "rolledChord", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "window"], "door": "tremolo", "title": "Rolled Chord", "desc": "Tremolo string windows pad ENTRY-side (the widener law)."},
]

## The door boons unlocked by a held transform (for the draft to fold into later offers). "" = none.
static func doors_for(transform_id: String) -> Array:
	var out: Array = []
	if transform_id == "":
		return out
	for d in TRANSFORM_DOORS:
		if String(d.get("door", "")) == transform_id:
			out.append(d)
	return out

## D0 S3 · THE DUOS — cross-theme capstone boons, offered ONLY while ARMED (>=2 drafted cards from
## EACH of the two themes; Reprise also needs the Rondo transform). Opus slot, two-tone frame
## (render deferred), no run cap (prereqs + rarity gate it). Duos are BOONS with kit hooks.
const DUOS := [
	{"id": "bloodCoda", "type": "relic", "rarity": "opus", "tags": ["wound", "finish", "eviscerate", "duo"], "themes": ["wound", "finish"], "title": "Blood Coda", "desc": "Wound x Finish: a full-combo Eviscerate cashing 4+ live bleeds pays both bonuses ×1.15 - the burst paints the phrase-mark red."},
	{"id": "redEdge", "type": "relic", "rarity": "opus", "tags": ["wound", "edge", "crit", "duo"], "themes": ["wound", "edge"], "title": "The Red Edge", "desc": "Wound x Edge: every CRIT pulses ALL live bleeds for one immediate extra tick - crit-fish while the pot is fat, against expiry."},
	{"id": "grandFinale", "type": "relic", "rarity": "opus", "tags": ["edge", "finish", "crit", "duo"], "themes": ["edge", "finish"], "title": "Grand Finale", "desc": "Edge x Finish: a full-combo finisher with your crit build hot is a GUARANTEED crit at +50% crit damage; the screen holds a half-beat on the number."},
	{"id": "reprise", "type": "relic", "rarity": "opus", "tags": ["wound", "coupdegrace", "duo"], "themes": ["wound"], "req_transform": "rondo", "title": "The Reprise", "desc": "Rondo x Wound: during the RETURN, each re-strike also re-opens one expired bleed - the song reopens the wounds."},
]

## The theme counts across a run's drafted deck (creed + modules + boons) — for duo arming.
static func theme_counts(run) -> Dictionary:
	var c := {"wound": 0, "edge": 0, "finish": 0}
	var creed: Dictionary = TwinfangCreeds.get_creed(String(run.creed))
	var ct := String(creed.get("theme", ""))
	if c.has(ct):
		c[ct] = int(c[ct]) + 1
	for mid in run.modules:
		if bool(run.modules[mid]):
			var mt := String(TwinfangModules.get_module(String(mid)).get("theme", ""))
			if c.has(mt):
				c[mt] = int(c[mt]) + 1
	for card in TEMPO:
		if run.boons.has(String(card.get("id", ""))):
			var bt := String(card.get("theme", ""))
			if c.has(bt):
				c[bt] = int(c[bt]) + 1
	return c

## The duos currently ARMED for `run` (>=2 from each theme; req_transform honored) — for the draft.
static func armed_duos(run) -> Array:
	var counts := theme_counts(run)
	var out: Array = []
	for d in DUOS:
		var ok := true
		for th in d.get("themes", []):
			if int(counts.get(String(th), 0)) < 2:
				ok = false
		if d.has("req_transform") and String(run.transform) != String(d["req_transform"]):
			ok = false
		if ok:
			out.append(d)
	return out

const SPELL_CAP := 5

static func spec_pool(aspect: String) -> Array:
	match aspect:
		"tempo": return TEMPO
		"fermata": return FERMATA          # Fermata's own coil-state slate (§13.4)
		_: return VENOM

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	match aspect:
		"tempo": return ["flow", "perfect", "combo", "crit", "bullseye", "window", "tempo"]
		"fermata": return ["coil", "release", "flow", "crit", "bullseye", "window", "opening"]
		_: return ["poison", "combo", "perfect"]

## Apply a chosen boon to the run.
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true

## The blade's build-summary lines for the raid build panel (raid_hud._verb_summary_lines).
## The reworked Tempo has no WHEN/THEN slot-verb board anymore — its build IS the drafted
## boons + its Creed/Module — so this is empty for now. verb_board() and the old slot-verb
## display were RETIRED 2026-07-05 with the dead VerbBoard combo GUI.
static func verb_summary(_boons: Dictionary, _aspect: String) -> Array:
	return []
