## One beat of a multi-strike telegraph STRING (M7). PURE DATA, like AbilityRes —
## a string ability carries an array of these and resolves them progressively
## during its wind-up. Each beat is answered (or not) with the UNIVERSAL DODGE
## and graded by press timing; feint beats punish the press and reward the hold.
## An empty `AbilityRes.strikes` = classic single-resolve ability (all pre-M7 content).
class_name StrikeRes
extends Resource

## What the universal dodge can do against this beat.
enum Guard {
	DODGEABLE,     ## a timed dodge fully negates it (a GRAZE is partial)
	BLOCKABLE,     ## even a PERFECT dodge only reduces it (crush-weight beats)
	UNANSWERABLE,  ## no answer — eat it (press attribution skips these beats)
}

## Press-timing verdict for one seat against one beat. PERFECT/GOOD/GRAZE/BAITED
## are judged at the press; MISS/READ at the beat's impact.
enum Grade { MISS, GRAZE, GOOD, PERFECT, BAITED, READ }

@export var at: float = 1.0           ## impact moment, seconds from telegraph start
@export var amount_frac: float = 1.0  ## this beat's share of the ability's `amount`
@export var size: int = 1             ## AbilityRes.Size (1=LIGHT 2=HEAVY 3=CRUSH) — int to keep this file reference-free
@export var guard: Guard = Guard.DODGEABLE
@export var feint: bool = false       ## fake beat: pressing = BAITED, holding = READ
@export var aoe: bool = false         ## every seat answers individually — the HEALER included

## Grade name for diagnostics / event labels.
static func grade_name(g: int) -> String:
	return ["miss", "graze", "good", "perfect", "baited", "read"][clampi(g, 0, 5)]
