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
## are judged at the press; MISS/READ at the beat's impact. BULLSEYE (tank-v2,
## GRADING COHERENCE LAW) = the dead-center read ABOVE perfect — appended so no
## existing value shifts; the one game-wide ladder is GRAZE<GOOD<PERFECT<BULLSEYE.
enum Grade { MISS, GRAZE, GOOD, PERFECT, BAITED, READ, BULLSEYE }

@export var at: float = 1.0           ## impact moment, seconds from telegraph start
@export var amount_frac: float = 1.0  ## this beat's share of the ability's `amount`
@export var size: int = 1             ## AbilityRes.Size (1=LIGHT 2=HEAVY 3=CRUSH) — int to keep this file reference-free
@export var guard: Guard = Guard.DODGEABLE
@export var feint: bool = false       ## fake beat: pressing = BAITED, holding = READ
@export var aoe: bool = false         ## every seat answers individually — the HEALER included

## RANDOM PERSONAL BEAT (raid): the beat picks a random LIVING raider (healer
## included) at telegraph start — only that victim can answer it, and it pierces
## the healer's untargetability. False = classic (telegraph-target / aoe) beat.
@export var rand_target: bool = false

## Grade name for diagnostics / event labels — the INTERNAL KEY (diag counters, event families,
## boon/rig triggers, oaths, draft all key off these). NEVER rename — it is load-bearing.
static func grade_name(g: int) -> String:
	return ["miss", "graze", "good", "perfect", "baited", "read", "bullseye"][clampi(g, 0, 6)]

## Player-facing DISPLAY label (Bill's rename, 2026-07-13): the ladder reads
## GRAZE < GOOD < GREAT < PERFECT — the old "perfect" tier shows GREAT, the old dead-centre
## "bullseye" shows PERFECT. Display text ONLY; grade_name (the keys above) is unchanged.
static func grade_label(g: int) -> String:
	return ["MISS", "GRAZE", "GOOD", "GREAT", "BAITED", "READ", "PERFECT"][clampi(g, 0, 6)]
