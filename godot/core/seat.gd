## A "seat" = one participant in the fight. The key abstraction that makes a human
## player, an AI ally, and a headless sim agent INTERCHANGEABLE: they differ only
## in `policy` and `fidelity`, never in the rules (see PORT-PLAN.md §"Seat model").
##
## Class-specific state (rage, momentum, counter, cooldowns) lives here generically;
## the class's ClassKit interprets it. Nothing in Seat knows what "momentum" means.
class_name Seat
extends RefCounted

var role: String = "dps"          ## "tank" | "dps" | "healer"
var unit_name: String = ""        ## display name (raid frames)
var is_player: bool = false       ## the primary/human seat (boss default target)
var fidelity: String = "full"     ## "full" (drives abilities) | "statblock" (dps * f(hp%))

var hp: float = 100.0
var hp_max: float = 100.0
var dps: float = 0.0              ## passive group-damage contribution (stat-block seats)

var resource: float = 0.0        ## rage / energy / focus / mana
var resource_max: float = 100.0

## Decision-maker (human input adapter or AI) and class behaviour hooks.
var policy: Policy = null
var kit: ClassKit = null

# --- generic combat state (ticks are the unit of time) ---
var gcd_until_tick: int = 0
var cooldowns: Dictionary = {}          ## ability id -> tick when ready again
var dodging_until_tick: int = -1        ## defensive-press "active" window end
var defense_ready_tick: int = 0         ## defensive press off cooldown at/after this tick
var dodge_ready_tick: int = 0           ## universal dodge (M7): press accepted at/after this tick
var dr: float = 0.0                     ## active damage-reduction fraction (Fortify/Vindicate)
var dr_until_tick: int = -1

## Class/aspect-specific scalars (counter, momentum, riposte_until_tick, ...).
var vars: Dictionary = {}

## Per-seat engine diagnostics (strike grades etc.) — every full-fidelity seat gets
## its own counts (raid sims); `state.diag` stays the is_player mirror solo sims read.
var diag: Dictionary = {}

# --- shields / heals / timed effects (used by the healer + anyone healable) ---
var absorb: float = 0.0                 ## damage shield; drained before HP
var absorb_owner_i: int = -1            ## seats[] index of who granted the ward (-1 → the first healer).
                                        ## An INDEX, not a Seat ref: seat→seat refs make RefCounted cycles (leaks)
var ward_until_tick: int = -1           ## absorb expiry tick (-1 = none)
var heal_absorb: float = 0.0            ## buries incoming HEALING (not dispellable)
var hots: Array = []                    ## stacking HoTs, each {tick,every,acc,left} in ticks
var debuff: Dictionary = {}             ## single DoT slot {tick,every,acc,left,id}; new DoT refreshes
var casting: Dictionary = {}            ## player cast-in-progress {id,target,start_tick,dur_ticks,mana}

func alive() -> bool:
	return hp > 0.0

func hp_frac() -> float:
	if hp_max <= 0.0:
		return 0.0
	return clampf(hp / hp_max, 0.0, 1.0)
