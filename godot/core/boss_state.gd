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
## SUNDER — the tank's break meter (Bulwark only feeds it; 0 for everyone else, so all
## other content is byte-identical). Every won mitigation read cracks the boss a little;
## while sunder > 0 the boss takes (1 + sunder * config.sunder_k) MORE from ALL sources
## (the co-op "break the wall" payoff). Decays aggressively toward 0 each tick.
var sunder: float = 0.0

## GEAR-2: tick of the last THREAT_DROP resolve — curse-answer timers/deeds read it
## (Sticky Note, "answer every curse" oaths). Write-only otherwise; never checksummed.
var last_curse_tick: int = -999999

## Countdown timers in TICKS (faithful to the prototypes: ability timers freeze
## while a telegraph is winding up; melee keeps ticking).
var melee_timer: int = 1000000
var ability_timer: Dictionary = {}     ## StringName ability id -> ticks until due

## Add-phase state (raid): while add_i >= 0 an AddRes unit holds the field — all
## boss damage routes to add_hp, the main body's ability timers freeze, and the
## main HP can't drop (it CAN still be healed — kick the medic add). Untouched solo.
var add_i: int = -1                    ## index into encounter.adds, -1 = main form
var add_hp: float = 0.0
var add_hp_max: float = 0.0
var adds_spawned: Dictionary = {}      ## AddRes index -> true (each wave fires once)

## Raid threat (threat_enabled fights only — see RAID-PLAN.md). Untouched solo.
## Keyed/indexed by seats[] position (never Seat refs — cycle/serialization safety).
var threat: Dictionary = {}            ## seat index (int) -> accumulated threat (float)
var taunt_seat_i: int = -1             ## forced-target seat index while tick < taunt_until_tick
var taunt_until_tick: int = -1
