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
	# --- FERMATA (§13.2) creeds — coil temperament. Only offered on the fermata aspect. ---
	"patient": {
		"name": "The Patient Knife", "kicker": "Greed",
		"blurb": "The coil keeps charging PAST sharp for up to +20% — but release too early and it UNRAVELS into a full Flow crash. Greed on the hold. A sharp Miss only bleeds −2 Flow.",
		"slip": "flow_loss",
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,
		"patient": true,          # coil-duration bonus (TwinfangKit._coil_release_bonus)
		"unravel_slip": true,     # an unravel is a full crash
	},
	"fleeting": {
		"name": "The Fleeting Shade", "kicker": "Forgiving",
		"blurb": "A short coil (0.20s), a painless unravel, and a Miss only bleeds −2 Flow instead of crashing. The cost: your Flow ceiling is 4. The fast, forgiving crossover for Tempo hands.",
		"slip": "flow_loss",
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,
		"coil_min": 0.20,         # TwinfangKit._coil_min reads this
		"flow_cap": 4,            # TwinfangKit.max_flow reads this
	},
	"longnight": {
		"name": "The Long Night", "kicker": "Slow & sharp",
		"blurb": "The Largo mirror: the beat runs SLOW and the window TIGHTER, but releases hit harder. Slow, small, heavy — precision in the dark. A slip costs −2 Flow.",
		"slip": "flow_loss",
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,
		"largo": true,            # reuses the Largo beat/window/hit knobs
	},
	"tutti": {
		"name": "Tutti", "kicker": "Everyone plays",
		"blurb": "EVERY button coils — Evis, utility, the kick. Sharp dumps take the window's grade multiplier (a Bullseye Evis ×1.8); an off-window dump is a shade weaker. The coil tax on everything, paid back in dump power.",
		"slip": "flow_loss",
		"slip_amt": 2,
		"lock_sec": 0.0,
		"flow_value": 1.0,
		"tutti": true,            # TwinfangKit._tutti / _dump_beat_bonus
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

## The FERMATA creed pool (§13.2) — the coil temperaments, offered on the fermata aspect.
static func fermata_ids() -> Array:
	return ["patient", "fleeting", "longnight", "tutti"]
