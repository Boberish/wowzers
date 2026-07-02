## Mutable per-run boss state (the EncounterRes is the immutable definition).
class_name BossState
extends RefCounted

var hp: float = 0.0
var hp_max: float = 0.0

## Total HP the boss has healed on itself (HEAL_BOSS abilities). Diagnostic for the
## balance sim (how much a DPS-check boss actually clawed back); ignored by the view.
var heal_total: float = 0.0

## Caster (Voidcaller) boss modifiers. Defaults are no-ops for every other class.
##  - silenced: while `tick < silenced_until_tick` the boss can't START interruptible
##    casts (pulses/channels still fire).
##  - dmg_buff: permanent self-empower — scales the boss's OUTGOING damage (cap in core).
##  - exposed: while active the PLAYER deals `1 + expose_amt` more to the boss (read by
##    the class kit, which routes its damage through it — the core stays generic).
var silenced_until_tick: int = -1
var exposed_until_tick: int = -1
var expose_amt: float = 0.0
var dmg_buff: float = 0.0

## Countdown timers in TICKS (faithful to the prototypes: ability timers freeze
## while a telegraph is winding up; melee keeps ticking).
var melee_timer: int = 1000000
var ability_timer: Dictionary = {}     ## StringName ability id -> ticks until due

## Raid threat (threat_enabled fights only — see RAID-PLAN.md). Untouched solo.
## Keyed/indexed by seats[] position (never Seat refs — cycle/serialization safety).
var threat: Dictionary = {}            ## seat index (int) -> accumulated threat (float)
var taunt_seat_i: int = -1             ## forced-target seat index while tick < taunt_until_tick
var taunt_until_tick: int = -1
