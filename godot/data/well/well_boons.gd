## WellBoons — the reworked healer's draft pool (MENDER-PLAN §4 + the ⚖ board verdicts),
## grouped by the part of the Well each touches. Mirrors the TwinfangBoons / AlchemistBoons
## static API (spec_pool / SHARED / aspect_tags / apply / verb_summary) so the shared Draft
## engine and REFORGE screen are class-agnostic.
##
## RARITY = fixed offer frequency this slice (the per-offer H/S/O roll is the shared Draft
## engine — Haiku common / Sonnet rare / Opus legendary). Effects are implemented in WellKit
## keyed by these ids and GUARDED (no boon ⇒ byte-identical base). SHARED offers to both specs;
## BRIM/DRAW are the per-spec pools (the aspect grades in different places, so its cards differ).
class_name WellBoons
extends RefCounted

## SHARED — the class's drafted SPELLS (Meditate battery · Boiling Over clutch) + universal
## Well utility + the glint/shield locks that read on either spec. Kept tight.
const SHARED := [
	{"id": "deepWell", "type": "upgrade", "rarity": "haiku", "tags": ["well"], "ctype": "POWER", "title": "Deep Well",
		"desc": "The Well holds +4 charges (16 total) — a deeper reserve to pour from."},
	{"id": "steadyPulse", "type": "upgrade", "rarity": "haiku", "tags": ["well"], "ctype": "EASE", "title": "Steady Pulse",
		"desc": "The charge pulse arrives 20% faster — the Well refills quicker between pours."},
	{"id": "meditate", "type": "spell", "rarity": "sonnet", "tags": ["well", "spell"], "ctype": "STRAT", "title": "Meditate",
		"desc": "New spell (key 5, cd 25): a long channel that refills the Well — +6 charges over the cast. The battery, drafted back (base book carries no Meditate)."},
	{"id": "keptLight", "type": "relic", "rarity": "sonnet", "tags": ["glint"], "ctype": "STRAT", "title": "The Kept Light",
		"desc": "Your Glint lasts +2s, and pouring on an ally who is ALREADY glinting EXTENDS the light instead of resetting it — keep your striker lit through the fight."},
	{"id": "brinkBell", "type": "relic", "rarity": "opus", "tags": ["shield", "support"], "ctype": "EASE", "title": "Brink Bell",
		"desc": "SIGNATURE: the first time each ally drops below 35%, a bell tolls — an emergency absorb braces them (once per ally; rearms at a Cooling). A drafted shield, legal by the book cut."},
	{"id": "shiningHour", "type": "relic", "rarity": "opus", "tags": ["support"], "ctype": "TEAM", "title": "The Shining Hour",
		"desc": "SUPPORT: while EVERY ally stands at or above 80%, the whole warband deals +12% damage. Topping the team IS the raid buff — no extra button."},
	{"id": "boilingOver", "type": "spell", "rarity": "sonnet", "tags": ["spell", "clutch"], "ctype": "GREED", "title": "Boiling Over",
		"desc": "New spell (key 6, cd 30): DUMP the Well's heat at the boss — a burst of direct damage that scales with your unspent charges. The healer's clutch swing (may SAVE a fight, never run one)."},
	{"id": "warmRekindle", "type": "upgrade", "rarity": "haiku", "tags": ["well"], "ctype": "EASE", "title": "Warm Rekindle",
		"desc": "Rekindle costs 2 fewer charges and casts 1.5s faster — bring the fallen back sooner."},
]

## BRIM — the TARGET spec's pool, keyed off where the heal LANDS (pours · spills · catches).
const BRIM := [
	{"id": "wideBrim", "type": "upgrade", "rarity": "haiku", "tags": ["brim", "band"], "ctype": "EASE", "title": "Wide Brim",
		"desc": "The pour band widens — a POUR lands from a lower catch, so clean pours come easier."},
	{"id": "secondRing", "type": "upgrade", "rarity": "haiku", "tags": ["brim"], "ctype": "POWER", "title": "Second Ring",
		"desc": "A pour ripples: the second-most-hurt ally catches 30% of the heal too — one pour, two mended."},
	{"id": "overflowingCup", "type": "upgrade", "rarity": "haiku", "tags": ["brim"], "ctype": "EASE", "title": "Overflowing Cup",
		"desc": "A SPILL isn't all wasted — a third of the overflow washes onto the most-hurt ally instead. A softer punish for overpouring."},
	{"id": "stillWater", "type": "relic", "rarity": "sonnet", "tags": ["brim", "shield"], "ctype": "STRAT", "title": "Still Water",
		"desc": "Every POUR leaves a thin absorb on the ally (25% of the heal) — a cushion against the next hit. A legal drafted shield."},
	{"id": "lowCatch", "type": "relic", "rarity": "sonnet", "tags": ["brim", "glint", "execute"], "ctype": "GREED", "title": "Low Catch",
		"desc": "Pouring on an ally below 25% fires a STRONGER Glint (+30% damage on top). The clutch save pays double."},
	{"id": "cadenceOfMend", "type": "relic", "rarity": "sonnet", "tags": ["brim", "well"], "ctype": "STRAT", "title": "Cadence of Mend",
		"desc": "Each Mend that pours in a row shaves 1 charge off the next (min 1) — reward the metronome; a miss resets it."},
	{"id": "blindfold", "type": "relic", "rarity": "sonnet", "tags": ["brim", "glint"], "ctype": "GREED", "title": "The Blindfold",
		"desc": "The landing preview goes DARK — but every pour's Glint burns +40% harder. Heal by feel, get paid for the nerve."},
	{"id": "highTide", "type": "relic", "rarity": "opus", "tags": ["brim", "glint", "keystone"], "ctype": "RULE", "title": "High Tide",
		"desc": "KEYSTONE: while EVERY ally is at or above the pour band, your next POUR Glints the WHOLE party at once. A full tide lifts every blade — build to keep the team topped."},
]

## DRAW — the SPEED spec's pool (MENDER §12 reshape, themes VIGIL · RAPIDS · EDDY), keyed off
## the RELEASE + THE CURRENT (clean · still · undercook · held). `theme` files each card into its
## lane (offer-weighting/build-panel data — generics are untagged). The SKIM pair (Loose Grip ·
## Short Pour) is PARKED with its unbuilt theme (§0): the kit machinery stays (guarded), it just
## leaves the offer pool — a wider clean band is the EASE dial's job now (the widener law).
const DRAW := [
	# --- generic release bread (no theme) ---
	{"id": "coolHand", "type": "upgrade", "rarity": "haiku", "tags": ["draw", "well"], "ctype": "STRAT", "title": "Cool Hand",
		"desc": "A CLEAN draw shaves 1s off Cascade's cooldown — steady hands feed the big button."},
	{"id": "doubleDraw", "type": "relic", "rarity": "sonnet", "tags": ["draw"], "ctype": "STRAT", "title": "Double Draw",
		"desc": "Two clean draws within 3s: the second heals +28%. Reward the chain — a broken streak starts it over."},
	# --- RAPIDS (the Current ladder) ---
	{"id": "whitewater", "type": "upgrade", "rarity": "haiku", "theme": "rapids", "tags": ["draw", "current"], "ctype": "POWER", "title": "Whitewater",
		"desc": "Every clean or Still-Point draw heals +4% per Current stack — at max Current, a +20% river. The Current pays in power the more of it you hold."},
	{"id": "shootGap", "type": "relic", "rarity": "sonnet", "theme": "rapids", "tags": ["draw", "current", "glint"], "ctype": "GREED", "title": "Shoot the Gap",
		"desc": "At MAX Current, a STILL POINT tag heals ×1.3 — the sliver hardens as you ride higher, and hitting it up there pays the most."},
	{"id": "eddyline", "type": "relic", "rarity": "sonnet", "theme": "rapids", "tags": ["draw", "current"], "ctype": "STRAT", "title": "Eddyline",
		"desc": "Once every 10s, an UNDERCOOK downgrades the Current by 1 instead of breaking it — a play, not a pardon: it still costs the stack and the sip still lands weak."},
	{"id": "strongPull", "type": "relic", "rarity": "opus", "theme": "rapids", "tags": ["draw", "current"], "ctype": "GREED", "title": "Strong Pull",
		"desc": "SIGNATURE: at MAX Current, every clean draw heals +30%. The Current pays in power, not just speed — the reward for riding high."},
	{"id": "theMillrace", "type": "relic", "rarity": "sonnet", "theme": "rapids", "tags": ["draw", "current", "well"], "ctype": "POWER", "title": "The Millrace",
		"desc": "While the Current runs FULL, every third cast is FREE (0 charges). The rush's one economy valve — ride high or run dry. (Demoted from keystone: honest economy, not a spectacle.)"},
	{"id": "flume", "type": "relic", "rarity": "opus", "theme": "rapids", "tags": ["draw", "current", "keystone"], "ctype": "RULE", "title": "The Flume",
		"desc": "KEYSTONE: hold MAX Current for 12s and the river runs white — for 6s every release auto-grades CLEAN and the whole party rides the flow. Your Current is NOT spent — keep it maxed and the river runs white again. Earned by holding high, never toggled."},
	# --- VIGIL (held heals — pairs with The Patient Hand / ⭐The Vigil module) ---
	{"id": "secondHand", "type": "upgrade", "rarity": "haiku", "theme": "vigil", "tags": ["draw", "hold"], "ctype": "STRAT", "title": "Second Hand",
		"desc": "Flash stays castable while a held heal is cocked in your hand — the stance, not a lockout. Cover a second dip without dropping the one you're holding."},
	{"id": "rideTremble", "type": "relic", "rarity": "sonnet", "theme": "vigil", "tags": ["draw", "hold", "execute"], "ctype": "GREED", "title": "Ride the Tremble",
		"desc": "A held heal releases +8% stronger per half-second you hold it (up to +60%) — ride the sway to the brink, but a gutter still wastes the charge and the cast."},
	{"id": "lastDrops", "type": "relic", "rarity": "sonnet", "theme": "vigil", "tags": ["draw", "execute", "well"], "ctype": "GREED", "title": "Last Drops",
		"desc": "While the Well is nearly dry (≤2 charges), casts run 20% faster and heal +15% — squeeze the dregs."},
	{"id": "loosedAtLast", "type": "relic", "rarity": "opus", "theme": "vigil", "tags": ["draw", "hold", "shield", "keystone"], "ctype": "RULE", "title": "Loosed at Last",
		"desc": "KEYSTONE: release a HELD heal within 0.2s of the ally being hit and it lands as a PERFECT INTERCEPT — full heal, and half of it clings on as a 2s absorb. The archer's photo-finish."},
	# --- EDDY (drift reads — pairs with The Eddy creed) ---
	{"id": "currentReading", "type": "upgrade", "rarity": "haiku", "theme": "eddy", "tags": ["draw", "current", "band"], "ctype": "STRAT", "title": "Current Reading",
		"desc": "Tag the clean band in the first third of its drift and the fast read grants +1 Current — reading the water quickly pays rhythm (the Eddy→Rapids bridge)."},
	{"id": "deepEddy", "type": "relic", "rarity": "sonnet", "theme": "eddy", "tags": ["draw", "band", "glint"], "ctype": "GREED", "title": "Deep Eddy",
		"desc": "The band's drift range DOUBLES — but land a Still Point in the wandering water and it heals ×1.5. Wilder reads, bigger payoff."},
	{"id": "deepStill", "type": "relic", "rarity": "sonnet", "theme": "eddy", "tags": ["draw", "glint"], "ctype": "EASE", "title": "Deep Still",
		"desc": "The Still Point sliver runs 60% wider — the Glint-tier release is easier to tag while you ride the Current."},
	{"id": "glassRiver", "type": "relic", "rarity": "opus", "theme": "eddy", "tags": ["draw", "band", "glint", "keystone"], "ctype": "RULE", "title": "The Glass River",
		"desc": "KEYSTONE: land three moving Still Points in a row and the water FREEZES — for 5s the bands stop drifting and every release grades as a Still Point. Read the river until it holds still."},
]

const SPELL_CAP := 9   ## the book is now 7 casts (SKIN added, MENDER §13); +2 drafted spells (Meditate/
                       ## Boiling Over) → 9. Bumped from 8 so SKIN doesn't silently crowd out a drafted
                       ## spell — the 8-cap TRIM stays PARKED per Bill (§13.6 pt 6), not applied here.

static func spec_pool(aspect: String) -> Array:
	return DRAW if aspect == "draw" else BRIM

## The mechanic vocabulary — feeds the synergy slot's build-tag set (per spec).
static func aspect_tags(aspect: String) -> Array:
	if aspect == "draw":
		return ["draw", "current", "band", "glint", "well", "execute", "support", "hold"]
	return ["brim", "band", "glint", "shield", "execute", "well", "support"]

## Apply a chosen boon to the run (spells append to the bar up to the cap; else set the boon).
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
		run.boons[b["id"]] = true   # also flag it so the kit's _b()/observe see the spell
	else:
		run.boons[b["id"]] = true

## The Well's build-summary lines for the raid build panel. The rig line is added by the HUD
## (_verb_summary_lines); this returns the drafted spells so the bar reads honestly.
static func verb_summary(_boons: Dictionary, _aspect: String) -> Array:
	return []
