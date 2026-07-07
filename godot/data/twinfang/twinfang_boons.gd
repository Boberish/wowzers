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
const SHARED := [
	{"id": "strikeEnergy", "type": "upgrade", "rarity": "sonnet", "tags": ["perfect", "energy"], "title": "Efficiency", "desc": "Perfect Strikes refund 6 energy — sustain the rhythm longer."},
]

## TEMPO — the reworked address-organized slate (STRIKE · WINDOW · FLOW · EVISCERATE · COUP).
## Every card names the button or dial it touches (the legibility rule). Numbers = base;
## the tier ladder (Slice 2) scales them per instance. VENOM below is frozen (redone later).
const TEMPO := [
	# --- STRIKE — the crit + read package ---
	{"id": "heartseeker", "type": "relic", "rarity": "sonnet", "tags": ["crit", "bullseye", "strike"], "title": "Heartseeker", "desc": "BULLSEYE Strikes (dead centre of the window) are guaranteed crits."},
	{"id": "hone", "type": "relic", "rarity": "opus", "tags": ["crit", "strike", "keystone"], "title": "Hone", "desc": "KEYSTONE: unlocks the EDGE meter. A Perfect hones +1, a Bullseye +2, a slip dulls −3. While Edge is up, ALL your hits carry crit chance (~4.5% per point, x2 damage) — nothing is spent, so a whiffed dump wastes nothing. Hone the blade with clean rhythm."},
	{"id": "assassinsNote", "type": "relic", "rarity": "sonnet", "tags": ["crit", "opening", "strike"], "title": "Assassin\u2019s Note", "desc": "Crits landed inside the Opening deal +50% more — time the dump into the window with a honed blade."},
	{"id": "throughline", "type": "upgrade", "rarity": "haiku", "tags": ["strike", "perfect"], "title": "Through-Line", "desc": "Consecutive Perfects escalate your Strike damage +2% per stack (cap 5); a Miss resets the line. Reward the unbroken run."},
	{"id": "serrated", "type": "upgrade", "rarity": "haiku", "tags": ["crit", "strike"], "title": "Serrated Fate", "desc": "Your crits deal 40% more damage."},
	{"id": "pressAdvantage", "type": "relic", "rarity": "sonnet", "tags": ["strike", "opening"], "title": "Press the Advantage", "desc": "Your basic Strikes landed inside the Opening — the boss’s vulnerability window — deal +30%. Keep drumming through the punish; don’t just wait for the dump."},
	{"id": "coldOpen", "type": "upgrade", "rarity": "haiku", "tags": ["strike", "flow"], "title": "Cold Open", "desc": "While your Flow is 2 or less, your Strikes deal +25% — rebuild from a crash with teeth."},
	{"id": "understudy", "type": "relic", "rarity": "sonnet", "tags": ["defense", "flow"], "title": "Understudy", "desc": "An understudy steps in: the next swing that would crash your Flow is shrugged off (Flow kept). Recharges ~25s. Defence only — it guards your groove, never feeds offence."},
	# --- THE WINDOW — where the green sits ---
	{"id": "wideTempo", "type": "upgrade", "rarity": "haiku", "tags": ["window"], "title": "Wide Tempo", "desc": "Your Perfect window is 15% wider on each side."},
	{"id": "fencersLine", "type": "relic", "rarity": "sonnet", "tags": ["window", "bullseye"], "title": "Fencer's Line", "desc": "A Bullseye widens your NEXT window by 25% — nail one, the next comes easier."},
	{"id": "rubato", "type": "relic", "rarity": "sonnet", "tags": ["window"], "title": "Rubato", "desc": "The Perfect window sits earlier — same skill, a faster song."},
	# --- FLOW — the greed dial ---
	{"id": "flowCap", "type": "upgrade", "rarity": "haiku", "tags": ["flow"], "title": "Momentum", "desc": "Flow cap +2 — a higher ceiling for every Flow bonus."},
	{"id": "tightrope", "type": "relic", "rarity": "sonnet", "tags": ["flow"], "title": "Tightrope", "desc": "While at MAX Flow, your damage is +15% — living on the edge pays."},
	{"id": "battleHymn", "type": "relic", "rarity": "opus", "tags": ["flow", "support"], "title": "Battle Hymn", "desc": "SUPPORT: while you hold high Flow, the whole warband rides your tempo — a haste aura that scales with your Flow tier and blinks off the instant you crash. Your uptime IS the raid buff."},
	{"id": "encore", "type": "upgrade", "rarity": "sonnet", "tags": ["flow"], "title": "Encore", "desc": "The double-hit (Flow Tier 1) kicks in at Flow 2 instead of 3."},
	{"id": "shatterfall", "type": "relic", "rarity": "sonnet", "tags": ["flow", "crash"], "title": "Shatterfall", "desc": "When a slip crashes your Flow from 4+, the shattered tempo detonates for 25 per point lost."},
	{"id": "doubleTime", "type": "relic", "rarity": "opus", "tags": ["flow"], "title": "Double Time", "desc": "SIGNATURE: at max Flow the accelerando never stops — each further Perfect tightens the window AND adds +4% damage, stacking until you crash."},
	# --- EVISCERATE — the dump ---
	{"id": "eviPlus", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "combo"], "title": "Deep Cuts", "desc": "Eviscerate deals +8 damage per combo point.", "req": "eviscerate"},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "execute"], "title": "Finish It", "desc": "Below 35% boss HP, your Eviscerate deals +35% — hold combo for the kill.", "req": "eviscerate"},
	{"id": "overkill", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "combo"], "title": "Overkill", "desc": "Combo built past the cap banks (up to 3) into your next Eviscerate for +6 each.", "req": "eviscerate"},
	{"id": "staccato", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "crash"], "title": "Staccato Fury", "desc": "After a Flow crash, your next Eviscerate is FREE and deals +50%.", "req": "eviscerate"},
	# --- COUP DE GRÂCE ---
	{"id": "crescendo", "type": "upgrade", "rarity": "haiku", "tags": ["flow", "coupdegrace"], "title": "Crescendo", "desc": "Coup de Grâce hits 40% harder."},
	{"id": "syncopation", "type": "relic", "rarity": "opus", "tags": ["flow", "energy"], "title": "Syncopation", "desc": "SIGNATURE: at max Flow your Strikes cost no energy, and a GOOD grades up to Perfect — ride the solo forever."},
	{"id": "daCapo", "type": "relic", "rarity": "sonnet", "tags": ["flow", "coupdegrace"], "title": "Da Capo", "desc": "Coup leaves you +1 Flow seed — come back from the top, not from walking pace."},
	# On the Beat (§13 verdict pass, Bill's idea) — the Tempo mirror of Fermata's TUTTI creed.
	{"id": "onTheBeat", "type": "relic", "rarity": "sonnet", "tags": ["opening", "eviscerate", "coupdegrace"], "title": "On the Beat", "desc": "Dumps fired INSIDE your Strike window take the window's grade multiplier — a Bullseye-timed Eviscerate hits far harder. Time your finishers to the beat, not just the Opening."},
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
