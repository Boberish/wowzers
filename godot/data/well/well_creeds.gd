## WellCreeds — the CREED data for the reworked healer (MENDER-PLAN §2). Mirrors the
## TwinfangCreeds / AlchemistCreeds static API (get_creed / field / ids / v1_ids /
## hides_tag) so the shared HUD framework dispatches to this class by name.
##
## A Creed is the run-long HEALING TEMPERAMENT — how the Well trades safety for reward.
## Each is a bundle of identity-default modifiers the kit reads via WellKit._cr(); an
## EMPTY creed_id ("") applies NONE of them, so the base build stays byte-identical (the
## sim's non-negotiable gate). Curated picks, NOT rarity-weighted (Hades-aspect style).
##
## The pools are PER-SPEC (the aspect grades in different places, so its risk knobs differ):
##   BRIM (grade the landing):
##     The Brink     — flagship greed: heals scale on the BLOODIED, the pour band drops low
##     Foresight     — play ahead: pours bank stacks while topped, a dip crashes them
##     The Levee     — forgiving: low band + a pour leaves a cushion, but a weaker Glint
##     The Shallows  — glass: a tight/high band, but the Glint burns far brighter
##   DRAW (grade the release):
##     The Patient Hand — the overrun becomes a HELD heal, released on the spike
##     The Long Draw    — the Largo mirror: slower casts, bigger heals, a tighter band
##     The Narrows      — all-or-nothing: outside the band heals ZERO, in-band much stronger
##     The Eddy         — the band DRIFTS every cast: read it, don't memorise it
class_name WellCreeds
extends RefCounted

## Every field is an IDENTITY default — a creed only overrides what it changes, and the kit
## falls back to these when creed_id == "" (byte-identical base). See WellKit._cr().
const IDENTITY := {
	"heal_mult": 1.0,          # flat multiplier on EVERY heal from the Well (Long Draw)
	"heal_bloodied": 0.0,      # Brink: heal ×(1 + this·(1−frac)) — the play-behind reward
	"brim_band_mult": 1.0,     # scales brim_band (the pour threshold); <1 = lower/easier, >1 = higher/harder
	"glint_bonus": 0.0,        # ADDITIVE to glint_mult (Shallows +, Levee −)
	"draw_band_mult": 1.0,     # scales the DRAW clean-band WIDTH (Long Draw ×0.75, Narrows ×0.55)
	"cast_mult": 1.0,          # scales cast time (Long Draw ×1.3 — slow & sharp)
	"pour_shield": 0.0,        # Levee: a POUR leaves this fraction of the heal as an absorb cushion
	"narrows_bonus": 0.0,      # Narrows: an in-band clean heals ×(1 + this)
	"foresight": false,        # Foresight posture — pours bank stacks while the party is topped
	"narrows": false,          # a release OUTSIDE the clean band heals ZERO (all-or-nothing)
	"eddy": false,             # the DRAW clean band's centre drifts cast-to-cast
	"patient_hold": false,     # an OVERRUN becomes a HELD heal cocked in the hand (release on the spike)
}

const CREEDS := {
	# --- BRIM pool (grade the landing) ---
	"brink": {
		"name": "The Brink", "kicker": "Play behind", "spec": "brim",
		"blurb": "Heal from the edge: every heal scales UP the more BLOODIED the target — up to ×2.2 at death's door — and the pour band drops LOW, so a clean catch is a catch from the brink. But those bigger heals overtop easily, and overtopping is the slip. The flagship greed.",
		"heal_bloodied": 1.2,      # ×(1 + 1.2·(1−frac)); at 0% HP → ×2.2
		"brim_band_mult": 0.72,    # band 0.80 → ~0.58: rewarded for catching from low
	},
	"foresight": {
		"name": "Foresight", "kicker": "Play ahead", "spec": "brim",
		"blurb": "Stay ahead of the damage: while NOBODY sits below half, every pour banks FORESIGHT (+7% healing per stack, up to 5). The moment an ally dips under 50%, the stacks CRASH. Rewards the healer who never lets it get scary.",
		"foresight": true,
	},
	"levee": {
		"name": "The Levee", "kicker": "Forgiving", "spec": "brim",
		"blurb": "Hold the water back: the pour band sits LOW (easy pours) and every pour leaves a small ABSORB on the ally — a cushion against the next hit. But your Glint runs weaker: the safe, low-ceiling road. The learner.",
		"brim_band_mult": 0.78,
		"glint_bonus": -0.15,      # 1.40 → 1.25
		"pour_shield": 0.30,       # a pour leaves 30% of the heal as an absorb
	},
	"shallows": {
		"name": "The Shallows", "kicker": "Glass", "spec": "brim",
		"blurb": "Every pour must run to the very TOP — the band is tight and high, so a POUR is hard to catch. But when you do, the Glint burns far brighter. Precision healing: small margins, huge payoff.",
		"brim_band_mult": 1.18,    # band 0.80 → ~0.94: must nearly top the ally
		"glint_bonus": 0.35,       # 1.40 → 1.75
	},
	# --- DRAW pool (grade the release) ---
	"patient": {
		"name": "The Patient Hand", "kicker": "Cool bank", "spec": "draw",
		"blurb": "Let a cast RUN PAST its end and it doesn't fire — it becomes a HELD heal cocked in your hand (~3s). Release it the instant the spike lands for a full, instant heal. Hold too long and it gutters, charge and cast both wasted. A held release does NOT feed the Current.",
		"patient_hold": true,
	},
	"longdraw": {
		"name": "The Long Draw", "kicker": "Slow & sharp", "spec": "draw",
		"blurb": "The Largo of the Well: every cast runs 30% SLOWER, but heals land 35% bigger and the clean band tightens. Fewer, weightier pulls — precision over speed.",
		"cast_mult": 1.30,
		"heal_mult": 1.35,
		"draw_band_mult": 0.75,
	},
	"narrows": {
		"name": "The Narrows", "kicker": "All or nothing", "spec": "draw",
		"blurb": "The clean band shrinks to a sliver — and a release OUTSIDE it heals for NOTHING. Land it and the heal hits far harder. No safe middle: nail the release or waste the cast.",
		"draw_band_mult": 0.55,
		"narrows": true,
		"narrows_bonus": 0.6,      # an in-band clean heals ×1.6
	},
	"eddy": {
		"name": "The Eddy", "kicker": "Fresh water", "spec": "draw",
		"blurb": "The clean band never sits still — its centre DRIFTS a little every cast. Tag it as it passes (the heal still resolves at cast end); you can never memorise the timing, only read it. Reading beats rhythm-memory.",
		"eddy": true,
	},
}

## The per-spec shipping pools (all built; grow only if more are authored). BRIM default.
const BRIM_V1 := ["brink", "foresight", "levee", "shallows"]
const DRAW_V1 := ["patient", "longdraw", "narrows", "eddy"]

static func get_creed(id: String) -> Dictionary:
	return CREEDS.get(id, {})

## A single modifier for a creed id, falling back to the IDENTITY default. "" = no creed.
static func field(id: String, key: String):
	if id == "":
		return IDENTITY[key]
	return CREEDS.get(id, {}).get(key, IDENTITY[key])

static func ids() -> Array:
	return CREEDS.keys()

## The offer pool for a spec (the HUD samples 3 of these at descent start). Brim is the default.
static func v1_ids(aspect := "") -> Array:
	return (DRAW_V1 if aspect == "draw" else BRIM_V1).duplicate()

## Which draft/module/rig content a creed HIDES (creed-aware offers). No Well creed hides
## content in v1 — the per-spec split already scopes the pools — but the framework calls this.
static func hides_tag(_id: String, _tag: String) -> bool:
	return false
