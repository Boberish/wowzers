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

## STATS PAGE v2: seats[] index the boss's melee last landed on (raid aggro accounting) —
## lets the aggro-pull detector fire an event only when the victim CHANGES, not per swing.
## Write-only; never checksummed. -1 = no melee has landed yet.
var last_melee_victim_i: int = -1

## PACK: the tick this member took the field. 0 = fight start (every classic fight —
## the default keeps all single-fight math byte-identical). Drives the walk-in grace
## (no actions until entered_tick + config.pack_walkin_ticks) and the per-member
## enrage clock (enrage time = time since entry, so member 3 never arrives pre-enraged).
var entered_tick: int = 0

## Countdown timers in TICKS (faithful to the prototypes: ability timers freeze
## while a telegraph is winding up; melee keeps ticking).
var melee_timer: int = 1000000
var ability_timer: Dictionary = {}     ## StringName ability id -> ticks until due

## THE STREAM (TANK-PLAN §0 — tank-v2) — the committed attack timeline. LAW 1: the
## engine PUBLISHES every bar (kind/impact tick/victim/damage, all rolled at publish
## time from state.rng in fixed order) the moment it enters the visible horizon, and
## NEVER mutates it after — the UI draws entries verbatim, so nothing can pop, morph,
## or jump. Victims are INDICES (RefCounted-cycle safe, the absorb_owner_i idiom).
## Bars vanish only by RESOLVING (impact) or SHATTERING (their body died — a rule,
## not a mutation). Only encounters whose melee dict carries a "rhythm" key ever
## write these — every other fight is byte-identical by construction.
## Bar entry: {id:int, kind:String (auto/heavy/buster/feint/eat/flurry),
##   disguise:String (feints: the costume kind), publish_tick:int, impact_tick:int,
##   victim_i:int, dmg:float, late:bool, flurry_i:int, flurry_n:int}
var stream: Array = []                 ## committed unresolved bars, ordered by impact_tick
var stream_seq: int = 0                ## stable per-bar id (UI keys + the immutability probe)
var stream_next_impact: int = -1       ## cadence chain head: the NEXT unpublished bar's impact tick
var stream_after_cast: bool = true     ## grammar: the first bar after a telegraph (or the pull) stays plain
var stream_flurry_cd_until: int = 0    ## grammar: min spacing between flurry bursts
var stream_last_eat_tick: int = -100000## grammar: no back-to-back unavoidables
var stream_tempo: float = 1.0          ## whole-flow speed multiplier (SPEED LAW: view pacing +
                                       ## publish cadence together; per-bar variance is forbidden)
var stream_last_kind: String = ""      ## grammar memory (no double buster, etc.)
var stream_resolving: Dictionary = {}  ## the bar mid-resolve — the kit funnel reads flurry
                                       ## group/index + the claimed answer here (cleared same tick)
var stream_answers: Dictionary = {}    ## bar id -> {kind, grade} — press-time claims (THE TWINFANG
                                       ## MODEL: judged at the press, applied at resolve). Lives
                                       ## BESIDE the committed bars, so LAW 1 immutability holds.

## Add-phase state (raid): while add_i >= 0 an AddRes unit holds the field — all
## boss damage routes to add_hp, the main body's ability timers freeze, and the
## main HP can't drop (it CAN still be healed — kick the medic add). Untouched solo.
var add_i: int = -1                    ## index into encounter.adds, -1 = main form
var add_hp: float = 0.0
var add_hp_max: float = 0.0
var adds_spawned: Dictionary = {}      ## AddRes index -> true (each wave fires once)

## FLOW=AGGRO (TANK-PLAN §1c · BOSS-PLAN §1): the tank's FLOW (on seat.vars["flow"], 0..1)
## IS the boss's attention. ≥ config.flow_lock_floor → the boss locks on the tank; below it
## each incoming attack has a rising chance to PEEL to a random other seat; 0 = fully random.
## The old threat TABLE + taunt (taunt_seat_i / taunt_until_tick / CombatCore.taunt) were
## DELETED here — aggro is passive, driven by the flow minigame, never a damage-threat rotation.
## The boss's current focus is a pure read of flow (CombatCore._threat_target, kept by name for
## the HUD/stage victim highlight); last_melee_victim_i (above) tracks the wandering focus.

## THE SEAL REWORK addenda (BOSS-PLAN §7; every default keeps existing fights byte-identical:
## stance 0 + featured -1 + deny_dmg 0 contribute a constant to the checksum, and no existing
## content ever moves them). E2 stance cycler · E1 featured gate · E6 deny-race accumulator.
var stance: int = 0                    ## E2: current expert/voice (STANCE_SHIFT advances it)
var featured: int = -1                 ## E1: Gemini's promoted voice (-1 = none yet)
var deny_dmg: float = 0.0              ## E6: damage dealt to the boss during the live empower cast
