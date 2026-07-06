## TwinfangCreeds — the CREED data for the Tempo rework (TEMPO-PLAN §3).
##
## A Creed is your run-start risk temperament: how a SLIP is punished, paired with a
## matching reward so the punishing ones pay the most. A "slip" = a missed Perfect Strike
## (you landed outside the green window) OR eating a boss swing. The penalty is your
## groove / window — never a boring damage number.
##
## Tempo-only (Venomancer has no Flow, so Creeds don't touch it). Curated picks, NOT
## rarity-weighted (like Hades aspects). Numbers are illustrative — tuned after the systems land.
class_name TwinfangCreeds
extends RefCounted

const CREEDS := {
	"drumline": {
		"name": "The Drumline", "kicker": "Steady",
		"blurb": "A slip costs −2 Flow — nothing else. Stumble, keep dancing. The forgiving default.",
		"slip": "flow_loss",   # drop Flow by slip_amt (not to 0)
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,     # multiplier on Flow's damage bonus
	},
	"flourish": {
		"name": "The Flourish", "kicker": "Glass",
		"blurb": "A slip SHATTERS your tempo — Flow → 0, back to walking pace. But each Flow point pays +50% more.",
		"slip": "shatter",     # Flow → 0 (window resets to walking pace via _tempo_t)
		"slip_amt": 0,
		"lock_sec": 0.0,
		"flow_value": 1.5,
	},
	"heldbreath": {
		"name": "The Held Breath", "kicker": "Lockout",
		"blurb": "A slip FREEZES your Flow (no loss) but locks the tight window for 2s — play slow to earn the fast lane back.",
		"slip": "freeze",      # Flow unchanged, but the accelerando window locks to base
		"slip_amt": 0,
		"lock_sec": 2.0,
		"flow_value": 1.0,
	},
	"largo": {
		"name": "The Largo", "kicker": "Slow & sharp",
		"blurb": "The beat runs SLOW — strikes land farther apart and the accelerando is tamed — but the window is TIGHTER and Perfects hit harder. Fewer, weightier, more precise. A slip costs −2 Flow.",
		"slip": "flow_loss",
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,
		"largo": true,
	},
}

const DEFAULT := "drumline"

static func get_creed(id: String) -> Dictionary:
	return CREEDS.get(id, CREEDS[DEFAULT])

static func ids() -> Array:
	return CREEDS.keys()

## The v1 shipping set (Flourish + Drumline = the clean risk/safe pair; Held Breath later).
static func v1_ids() -> Array:
	return ["flourish", "drumline", "largo"]
