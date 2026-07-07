## The Alchemist ("the Brew") draft pool — ALCHEMIST-PLAN §4, grouped by the brew part each
## touches (FUEL / VIAL / POTENCY / REACTION-RUPTURE / SPELLS). Mirrors the TwinfangBoons
## static API (spec_pool / SHARED / aspect_tags / apply / verb_summary) so the shared Draft
## engine and REFORGE screen are class-agnostic.
##
## RARITY = fixed offer frequency this slice (verdict 3: the per-offer H/S/O roll + authored
## runes is a DESIGNED-NOT-BUILT shared engine slice — Tempo is in the same boat). Effects are
## implemented in AlchemistKit keyed by these ids. `hide_creeds` = creed-aware offers (verdict
## 6): a Purist never sees the Rupture-side cards its no-burst posture makes dead.
class_name AlchemistBoons
extends RefCounted

## SHARED — the class's spells (SLICE F) + universal utility. Kept small.
const SHARED := [
	{"id": "spitfire", "type": "spell", "rarity": "haiku", "tags": ["spell"], "title": "Spitfire",
		"desc": "New spell (key 5): an instant off-brew acid dart — free filler damage between pours. The designated interrupt carrier when pillar 3 lands."},
	{"id": "decant", "type": "spell", "rarity": "sonnet", "tags": ["spell", "balance"], "title": "Decant",
		"desc": "New spell (key 6, cd 8): pour the fuller poison into the emptier — a snap-to-balance recovery when the see-saw tips."},
	{"id": "reduction", "type": "spell", "rarity": "sonnet", "tags": ["spell", "potency"], "title": "Reduction",
		"desc": "New spell (key 7, cd 12): boil VOLUME into POWER — trade half your brew for an instant slug of Potency, right before a Rupture."},
]

## BREW — the one aspect's pool, addressed by the brew part it touches.
const BREW := [
	# --- FUEL: the two poison pools + their decay ---
	{"id": "deepCauldron", "type": "upgrade", "rarity": "haiku", "tags": ["fuel"], "title": "Deep Cauldron",
		"desc": "Both poison caps +4 — a bigger brew to react and to Rupture."},
	{"id": "preservative", "type": "upgrade", "rarity": "haiku", "tags": ["fuel"], "title": "Preservative",
		"desc": "Both poisons decay 25% slower — the brew holds while you breathe."},
	{"id": "clingingRot", "type": "relic", "rarity": "sonnet", "tags": ["fuel", "rot"], "title": "Clinging Rot",
		"desc": "Rot barely decays (−80%) — set the cold side and forget it; feed the hot."},
	# --- VIAL: the hold-release minigame ---
	{"id": "steadyPour", "type": "upgrade", "rarity": "haiku", "tags": ["vial"], "title": "Steady Pour",
		"desc": "The sweet band is 40% wider — a POTENT pour is easier to catch."},
	{"id": "practicedHand", "type": "relic", "rarity": "haiku", "tags": ["vial"], "title": "Practiced Hand",
		"desc": "The vial charges 25% slower — a calmer climb to the sweet band (a sidegrade, not a buff)."},
	# --- POTENCY: the earned power bar ---
	{"id": "quickStudy", "type": "upgrade", "rarity": "haiku", "tags": ["potency"], "title": "Quick Study",
		"desc": "Potency fills 30% faster while you brew clean."},
	{"id": "distilledFocus", "type": "upgrade", "rarity": "haiku", "tags": ["potency"], "title": "Distilled Focus",
		"desc": "Potency drains 30% slower on a slip — a mistake costs less power."},
	{"id": "concentrate", "type": "relic", "rarity": "sonnet", "tags": ["potency"], "title": "Concentrate",
		"desc": "Potency's ceiling is +20% — the same bar multiplies everything harder."},
	{"id": "killingDraught", "type": "relic", "rarity": "sonnet", "tags": ["potency", "execute"], "title": "Killing Draught",
		"desc": "Below 30% boss HP your Potency stops draining — locked at your peak for the kill."},
	# --- REACTION / RUPTURE (split reaction-DoT vs Rupture-burst — the F7 fix) ---
	{"id": "corrosiveBlood", "type": "upgrade", "rarity": "haiku", "tags": ["reaction"], "title": "Corrosive Blood",
		"desc": "The sustained reaction deals +18%."},
	{"id": "volatileReaction", "type": "relic", "rarity": "sonnet", "tags": ["reaction", "potency"], "title": "Volatile Reaction",
		"desc": "While Potency is above 66%, the reaction deals +25% — reward for riding the boil."},
	{"id": "perfectEmulsion", "type": "relic", "rarity": "sonnet", "tags": ["reaction", "balance"], "title": "Perfect Emulsion",
		"desc": "While your balance is near-perfect (≥0.9), the reaction deals +30% — balance is REWARDED, never eased."},
	{"id": "deepeningRot", "type": "relic", "rarity": "sonnet", "tags": ["reaction", "rot"], "title": "Deepening Rot",
		"desc": "A fed, balanced reaction RAMPS — up to +40% the longer you hold it clean; a stall or spoil resets the ramp. Pays the patient brewer."},
	{"id": "debilitator", "type": "relic", "rarity": "sonnet", "tags": ["support", "reaction"], "title": "Debilitator",
		"desc": "SUPPORT: your reaction corrodes the boss — it takes MORE damage from the WHOLE raid (a stacking debuff). The Brew's raid-utility identity."},
	{"id": "rupturing", "type": "upgrade", "rarity": "haiku", "tags": ["rupture"], "hide_creeds": ["purist"], "title": "Rupturing",
		"desc": "Rupture detonates for +35%."},
	{"id": "chainRupture", "type": "relic", "rarity": "sonnet", "tags": ["rupture"], "hide_creeds": ["purist"], "title": "Chain Rupture",
		"desc": "Rupture keeps +30 points more of the brew (≈65% total) — a smaller crater, a faster rebuild. The wave-shaper."},
	{"id": "catalyst", "type": "relic", "rarity": "opus", "tags": ["rupture"], "hide_creeds": ["purist"], "title": "Catalyst",
		"desc": "SIGNATURE: Rupture also detonates a PHANTOM copy — a snapshot of the burst's value, brew intact. A second bang for one cash-out."},
	{"id": "lastCall", "type": "relic", "rarity": "opus", "tags": ["rupture", "phase"], "hide_creeds": ["purist"], "title": "Last Call",
		"desc": "SIGNATURE: when the boss changes phase — the moment that would scatter your brew — it AUTO-RUPTURES for full value first, leaving a seed. The scariest beat becomes your best detonation."},
]

const SPELL_CAP := 5

static func spec_pool(_aspect: String) -> Array:
	return BREW

## The mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(_aspect: String) -> Array:
	return ["fuel", "vial", "potency", "reaction", "rupture", "balance", "rot"]

## Apply a chosen boon to the run (spells append to the bar up to the cap; else set the boon).
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
		run.boons[b["id"]] = true   # also flag it so the kit's _b()/observe see the spell
	else:
		run.boons[b["id"]] = true

## The Brew's build-summary lines for the raid build panel. The rig line is added by the HUD
## (_verb_summary_lines); this returns the drafted spells so the bar reads honestly.
static func verb_summary(_boons: Dictionary, _aspect: String) -> Array:
	return []
