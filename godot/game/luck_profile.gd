## LuckProfile — 📁 YOUR PRIOR, the across-run "better luck next time" file. A single
## capped integer saved between descents; loaded ONCE into the run at descent start
## (constant all run, like the seed) and written back only at run end. It grants a
## small permanent floor on every Inference Check plus a bit of starting ⚡ Entropy —
## a veteran's file makes the facility a hair more cooperative, never a win button.
##
## HUD-flow ONLY: sims/probes/headless never touch disk (batch runs must not read or
## write user:// — the Profile aggregate guards it).
class_name LuckProfile
extends RefCounted

const PRIOR_CAP := 100
const FLOOR_CAP := 10            ## +% ceiling the Prior floor can ever add to a check
const FLOOR_DIV := 20           ## prior/20 → the floor %  (prior 100 → +5, capped 10 anyway)
const START_BASE := 2            ## ⚡ everyone opens with
const START_PER := 10           ## +1 starting ⚡ per this much Prior …
const START_CAP := 5            ## … up to this many bonus ⚡

## The permanent floor a given Prior adds to EVERY check (hard-capped, never a win button).
static func prior_floor(prior: int) -> int:
	return clampi(int(prior) / FLOOR_DIV, 0, FLOOR_CAP)

## Starting ⚡ Entropy for a descent, scaled by the file.
static func starting_entropy(prior: int) -> int:
	return START_BASE + clampi(int(prior) / START_PER, 0, START_CAP)

## True once the file is warm enough to grant a free once-per-run mulligan (Phase 4 use).
static func has_free_mulligan(prior: int) -> bool:
	return int(prior) >= 50

## Disk moved to the Profile aggregate (REFIT P4 save unification —
## user://rift_prior.cfg is legacy, imported once). The caps live HERE.
static func load_prior() -> int:
	return clampi(Profile.current().prior(), 0, PRIOR_CAP)

static func save_prior(prior: int) -> void:
	Profile.current().set_prior(clampi(int(prior), 0, PRIOR_CAP))
