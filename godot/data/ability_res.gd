## One boss ability. This is PURE DATA — no script closures — so a boss can be
## authored as a .tres file (see PORT-PLAN.md §"Exact Godot Resource schema").
## The behavior is selected by `effect` (an enum), dispatched in CombatCore.
##
## Timeline of one ability: it becomes "due" -> boss_think starts a telegraph of
## length `cast` seconds -> when the telegraph completes, `effect` resolves.
class_name AbilityRes
extends Resource

## What happens when the telegraph resolves. Add kinds as new bosses need them.
enum Effect {
	DMG_TARGET,   ## hit the current target (tankbuster -> the tank)
	DMG_ALL,      ## hit every combatant (raid nova)
	NOVA,         ## alias of DMG_ALL for readability in data
	HEAL_BOSS,    ## boss heals itself (Voidcaller DPS-check)
	DOT_RANDOM,   ## apply a DoT debuff to N random dps (prefers un-debuffed)
	DOT_ALL,      ## apply a DoT debuff to every combatant
	MARK_NUKE,    ## detonate a big hit on a victim marked at cast start
	HEAL_ABSORB,  ## bury a victim's incoming healing (not dispellable)
	EMPOWER_BOSS, ## boss buffs its own outgoing damage (Voidcaller: interrupt it or it hits harder)
	THREAT_DROP,  ## raid: zero the tank's FLOW (the "context-window shift" curse — flow dump)
	## --- THE SEAL REWORK (BOSS-PLAN E2/E3; appended so existing ordinals never shift) ---
	STANCE_SHIFT, ## E2: advance boss.stance = (stance+1) % encounter.stance_count (Mistral experts)
	BREAK,        ## E3: a dialogue curtain — a no-strike telegraph whose `cast` IS the pause;
	              ##     `script_lines` shows as prose (view-only); re-staggers timers on resolve
	MARK,         ## E5 (authored at S5): start THE ESCALATION mark relay (mark_seat_i/fuse)
}

## How the player can answer this telegraph. (Named "Response" to avoid clashing
## with the live-object class `Telegraph` in core/.)
enum Response {
	UNAVOIDABLE,      ## no counter-play; you eat it (or out-heal it)
	DEFENSIBLE,       ## a timed defensive press mitigates/negates (tank)
	INTERRUPTIBLE,    ## a kick stops it (caster)
}

## Visual/priority weight for the swing (also a tank tie-break hint).
enum Size { NONE, LIGHT, HEAVY, CRUSH }

@export var id: StringName = &""
@export var name: String = ""
@export var tag: String = ""            ## short label shown on the telegraph
@export var cast: float = 1.5           ## telegraph length, seconds
@export var cd: float = 5.0             ## base recast, seconds (divided by phase speed)
@export var jitter: float = 1.0         ## random padding added to cd, seconds
@export var danger: bool = false        ## priority + red styling; wins scheduler ties
@export var effect: Effect = Effect.DMG_TARGET
@export var amount: float = 0.0         ## damage/heal payload (scaled by phase mult)
@export var response: Response = Response.UNAVOIDABLE
@export var size: Size = Size.NONE

## FEINT: the swing LOOKS defensible (shows a parry prompt) but answering it with the
## defensive press is a mistake — the ClassKit punishes the bait instead of rewarding
## a parry, and eating it is the correct (rewarded) read. Used by the Duelist boss.
@export var feint: bool = false

## MULTI-STRIKE STRING (M7): beats resolved progressively during the wind-up.
## Non-empty = this ability is a string — `effect`/`response` are ignored (each
## StrikeRes beat carries its own payload/answerability) and beats are answered
## with the universal DODGE, graded by press timing. Empty = classic single-resolve.
@export var strikes: Array = []         ## Array of StrikeRes

# --- DoT payload (DOT_RANDOM / DOT_ALL) ---
@export var dot_tick: float = 0.0       ## damage per DoT interval (scaled by phase mult)
@export var dot_every: float = 1.5      ## DoT interval, seconds
@export var dot_dur: float = 0.0        ## DoT duration, seconds
@export var dot_targets: int = 1        ## how many random victims (DOT_RANDOM)

# --- EMPOWER_BOSS payload ---
@export var buff: float = 0.0           ## damage buff added to the boss on resolve

## CAST CHAIN (raid): after this telegraph RESOLVES or is KICKED, the next link
## starts immediately (a kick SKIPS one verse — it doesn't end the litany; a
## silence kills the whole chain). Only the opener carries the array; links leave
## it empty. Empty = classic single cast (all solo content).
@export var chain: Array = []           ## Array of AbilityRes

# --- THE SEAL REWORK addenda (BOSS-PLAN §7; every default is a no-op → byte-identical) ---

## E1 · GATED ABILITY SETS. Empty = always eligible (every existing ability). Keys:
##  `phase_from`:int  eligible only when the current phase INDEX >= this
##  `phase_until`:int eligible only when the current phase INDEX <= this
##  `stance`:int      eligible only when boss.stance == this (Mistral experts / Gemini voices)
##  `featured`:int    eligible only when boss.featured == this (Gemini's promoted voice)
## The scheduler skips an ineligible ability in the PICK; its timer still ticks, so it
## fires the instant it becomes eligible (re-staggered on the flip so it never bursts).
@export var gate: Dictionary = {}

## E3 · BREAK prose (view-only, NEVER checksummed / never read by update() logic).
@export var script_lines: PackedStringArray = PackedStringArray()

## E8 · KICK WINDOW (the §1½ contract): a kick lands ONLY when remaining cast <= this
## (absolute seconds). 0 = whole cast kickable = legacy. FIELD ONLY in S1 — the honoring
## press lands with the class-side `interrupts` flag (interrupt-by-ability, S7).
@export var kick_window: float = 0.0

## E9 · CHARGE-COUNTER PIPS (Mistral's Batch Job). 0 = no pips. FIELD + Telegraph.pips_left
## plumbing in S1; the perfect-decrement + payload-scale are authored with Batch Job at S3.
@export var pips: int = 0

## E6 · DENY-RACE EMPOWER. deny_denom 0 = no scaling (every existing empower). When > 0, the
## resolved buff scales down by the damage dealt to the boss DURING this cast (deny_dmg /
## deny_denom), clamped to [deny_floor, 1.0] — burst into the wind-up to shrink the escalation.
@export var deny_denom: float = 0.0
@export var deny_floor: float = 0.5
