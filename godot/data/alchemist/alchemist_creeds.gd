## AlchemistCreeds — the CREED data for the Brew (ALCHEMIST-PLAN §2). Mirrors the
## TwinfangCreeds static API (get_creed / ids / v1_ids) so the shared HUD framework can
## dispatch to either class by name.
##
## A Creed is the run-long BREWING POSTURE — how the class trades control for power. Each
## is a bundle of identity-default modifiers the kit reads via AlchemistKit._cr(); an EMPTY
## creed_id ("") applies NONE of them, so the base build stays byte-identical (the sim's
## non-negotiable gate). Curated picks, NOT rarity-weighted (Hades-aspect style).
##
## The 4 (Reckless Brewer cut with saturation 2026-07-06):
##   Steady Hand  — forgiving learner (gentle drain, overflow fizzles, lower ceiling)
##   Volatile Mix — glass/greed (huge ceiling + Ruptures; a spoil CRASHES potency to 0)
##   Anchorite    — Rot frozen + linear vial + tight band: one-poison precision, low-APM
##   Purist       — NO Rupture at all; the sustained reaction is +35% (pure DoT)
class_name AlchemistCreeds
extends RefCounted

## Every field is an IDENTITY default — a creed only overrides what it changes, and the kit
## falls back to these when creed_id == "" (byte-identical base). See AlchemistKit._cr().
const IDENTITY := {
	"pot_amp_mult": 1.0,      # scales the potency ceiling (pot_amp)
	"pot_cap": 1.0,           # HARD ceiling on the potency bar itself — only bites hands that ride high
	"pot_drain_mult": 1.0,    # scales how fast potency bleeds when sloppy
	"bal_min_mult": 1.0,      # scales the "balanced" gate (pot_bal_min); <1 = easier, >1 = stricter
	"sweet_band_mult": 1.0,   # scales sweet-band WIDTH, anchored at the red line; <1 = tighter
	"charge_rate_mult": 1.0,  # scales the base vial fill rate
	"decay_mult": 1.0,        # scales BOTH poison decays — >1 = the brew is harder to keep fed
	"rupture_mult": 1.0,      # scales the Rupture burst
	"react_bonus": 0.0,       # ADDITIVE fraction on the sustained reaction (Purist)
	"freeze_rot": false,      # Rot never decays (Anchorite — set the anchor once)
	"linear_charge": false,   # kill the quadratic accel — a predictable, deliberate fill
	"overflow_fizzle": false, # overflow past the red line FIZZLES (nothing) instead of SPOILING
	"spoil_crashes": false,   # a SPOILED pour crashes potency to 0 (Volatile's downside)
	"no_rupture": false,      # Rupture is disabled entirely (Purist — all sustain)
}

const CREEDS := {
	"steady_hand": {
		"name": "The Steady Hand", "kicker": "Forgiving",
		"blurb": "Gentle potency drain, a wider balanced window, and an overflow just FIZZLES — no spoil crash. But your potency is CAPPED low: the smooth low road, never the dangerous heights. The learner.",
		"pot_drain_mult": 0.6,
		"bal_min_mult": 0.9,
		"pot_cap": 0.6,           # can't ride past 60% — only an expert who'd reach higher pays for this
		"overflow_fizzle": true,
	},
	"volatile_mix": {
		"name": "The Volatile Mix", "kicker": "Glass",
		"blurb": "+50% potency ceiling and bigger Ruptures — but the brew fades FASTER and a SPOILED pour crashes your potency to zero. Ride the red line or pay for it.",
		"pot_amp_mult": 1.5,
		"rupture_mult": 1.25,
		"decay_mult": 1.3,        # the greed is harder to sustain — sloppy hands can't keep it fed
		"spoil_crashes": true,
	},
	"anchorite": {
		"name": "The Anchorite", "kicker": "Precision",
		"blurb": "ROT IS FROZEN — set the anchor once, it never decays. The vial charges LINEARLY into a tighter sweet band: a low-APM precision game against a fixed side.",
		"freeze_rot": true,
		"linear_charge": true,
		"charge_rate_mult": 2.0,
		"sweet_band_mult": 0.6,
	},
	"purist": {
		"name": "The Purist", "kicker": "All sustain",
		"blurb": "NO RUPTURE AT ALL — the wave is gone. Your sustained reaction is +18% instead, but potency is LEAKIER and demands a tighter balance to climb: sustain becomes its own high-wire act. Pure, patient DoT; every Rupture card goes dead (the trade).",
		"no_rupture": true,
		"pot_amp_mult": 1.5,      # potency pays 50% MORE — the reward becomes "how high can you SUSTAIN it"
		"bal_min_mult": 1.05,     # a slightly stricter "balanced" gate — hold it to keep potency climbing
		"pot_drain_mult": 1.15,   # a touch leakier: without the wave to re-earn it, a dip costs you
	},
}

## The default shipping pool (all 4 are built; grows only if more are authored).
const V1 := ["steady_hand", "volatile_mix", "anchorite", "purist"]

static func get_creed(id: String) -> Dictionary:
	return CREEDS.get(id, {})

## A single modifier for a creed id, falling back to the IDENTITY default. "" = no creed.
static func field(id: String, key: String):
	if id == "":
		return IDENTITY[key]
	return CREEDS.get(id, {}).get(key, IDENTITY[key])

static func ids() -> Array:
	return CREEDS.keys()

static func v1_ids() -> Array:
	return V1.duplicate()

## Which draft/module/rig content a creed HIDES (creed-aware offers — ALCHEMIST-PLAN verdict 6).
## Purist has no burst, so it never sees Rupture-side cards, modules, or rig WHENs.
static func hides_tag(id: String, tag: String) -> bool:
	if id == "purist":
		return tag == "rupture"
	return false
