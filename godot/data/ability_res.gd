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
	THREAT_DROP,  ## raid: zero the top-threat unit's threat — the boss turns; taunt it back
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
