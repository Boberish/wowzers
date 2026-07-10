## Mutable per-run boss state (the EncounterRes is the immutable definition).
class_name BossState
extends RefCounted

var hp: float = 0.0
var hp_max: float = 0.0

## Total HP the boss has healed on itself (HEAL_BOSS abilities). Diagnostic for the
## balance sim (how much a DPS-check boss actually clawed back); ignored by the view.
var heal_total: float = 0.0

## Boss modifiers. Defaults are no-ops for every fight that doesn't feed them.
##  - silenced: while `tick < silenced_until_tick` the boss can't START interruptible
##    casts (pulses/channels still fire).
##  - dmg_buff: permanent self-empower — scales the boss's OUTGOING damage (cap in core).
var silenced_until_tick: int = -1
var dmg_buff: float = 0.0

## THE VULNERABILITY STACK (REFIT P4): every windowed "boss takes MORE" effect lives
## here — ONE list, ONE fold point (`CombatCore.vuln_mult`, applied in `damage_boss`
## and the stat-block ally path). Entry: {seat_i:int, mult:float, until:int(tick),
## src:StringName}; seat_i -1 = the whole raid, else only that attacker's hits.
## Same (seat_i, src) REFRESHES (never self-stacks); distinct sources multiply;
## expired entries prune lazily inside the fold (tick-driven — deterministic).
## Empty list = 1.0 = byte-identical for every fight without a vuln user. The Well's
## GLINT rides here; TEAM-COMP school amps + Depth affixes get their fold slot here.
## (The old boss-level exposed_until_tick/expose_amt died here — their one reader
## was the purged Voidcaller; per-seat Exposed lives on seat.vars in bulwark_kit.)
var vulns: Array = []
## SUNDER — the tank's break meter (Bulwark only feeds it; 0 for everyone else, so all
## other content is byte-identical). Every won mitigation read cracks the boss a little;
## while sunder > 0 the boss takes (1 + sunder * config.sunder_k) MORE from ALL sources
## (the co-op "break the wall" payoff). Decays aggressively toward 0 each tick.
var sunder: float = 0.0

## DEBILITATE — the Alchemist's SUPPORT debuff (only the Brew's Debilitator boon feeds it;
## 0 for everyone else, so all other content is byte-identical). While debilitate > 0 the boss
## takes (1 + debilitate * config.debilitate_k) MORE from the WHOLE raid — the class's
## raid-utility identity. Decays gently toward 0 (a sustained corrosion, unlike sunder's crack).
var debilitate: float = 0.0

## GEAR-2: tick of the last THREAT_DROP resolve — curse-answer timers/deeds read it
## (Sticky Note, "answer every curse" oaths). Write-only otherwise; never checksummed.
var last_curse_tick: int = -999999

## PACK: the tick this member took the field. 0 = fight start (every classic fight —
## the default keeps all single-fight math byte-identical). Drives the walk-in grace
## (no actions until entered_tick + config.pack_walkin_ticks) and the per-member
## enrage clock (enrage time = time since entry, so member 3 never arrives pre-enraged).
var entered_tick: int = 0

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
