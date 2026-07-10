## The entire mutable state of one fight. A plain data bag — no logic lives here
## (logic is in CombatCore). This is what gets seeded, ticked, and (later) synced
## over the network / snapshotted for a sim replay.
class_name CombatState
extends RefCounted

var tick: int = 0                   ## integer tick is the source of truth for time
var dt: float = 1.0 / 30.0
var rng: DetRng

var boss: BossState
var seats: Array[Seat] = []
var telegraph: Telegraph = null

var over: bool = false
var won: bool = false
var loss_cause: String = ""

var config: TuningConfig
var encounter: EncounterRes

## PACK (WORLD-PLAN §FIGHT LENGTH): a chain of encounters fought sequentially inside
## THIS one battle — the win only fires on the last corpse, and heat carries because
## nothing about the seats ever resets. Empty = a classic single fight (every existing
## path, byte-identical). When set, pack[0] is the encounter already on the field.
var pack: Array = []                ## Array[EncounterRes]
var pack_i: int = 0                 ## which member currently holds the field

## Party-wide damage reduction {amt, until_tick} (Brinkwarden Last Stand).
var raid_dr: Dictionary = {}

# THE KILL SWITCH pre-fight primes (default-safe → every fight byte-identical when unset):
var party_out_mult: float = 1.0     ## OVERCLOCK DMG-amp — scales the raid's outgoing to the boss
var enrage_offset: float = 0.0      ## OVERCLOCK STALL (+s) / enrage-sooner curse (−s); NEVER mutate encounter.enrage_at

## How the fight is lost. "player" = solo duel (is_player death). "raid" = role
## extinction (no living tank / no living healer / no living dps → wipe).
var loss_mode: String = "player"

## THE AGGRO SUBSYSTEM enable (FLOW=AGGRO, TANK-PLAN §1c). When on, the boss's target
## is driven by the tank's FLOW (its clean-answer streak) + the progressive peel, instead
## of "first living tank". The taunt is GONE — aggro is 100% passive (BOSS-PLAN §1). Set by
## every game CONTENT builder (raid today; world/dungeon later — "universal, one habit").
## GUARDED — the solo class-training sims don't set it, so they stay byte-identical; only
## the ambient numbers scale by content, never how aggro works. (Field name kept from the
## old threat era for byte-stability; it now means "the flow/peel aggro system is live".)
var threat_enabled: bool = false

## Tick-stamped input queue. Nothing mutates state inside an input event; actions
## are queued and drained at the top of their owning tick (netcode-friendly).
var input_queue: Array = []         ## [{tick:int, seat:Seat, action:Dictionary}]

## Running hash of the sim — two runs of the same seed must produce the same value.
var checksum: int = 0

## Discrete combat events since the last drain (parry/dodge negate, hits, etc.).
## The view layer reads these for juice; the sim ignores them. (Foreshadows the
## signal-based approach netcode will use.)
var events: Array = []

## Deterministic diagnostics counters (M7 strike grades: perfect/good/graze/miss/
## baited/read/whiff). Engine-written for the PLAYER seat only, sim-read at fight
## end. Not part of the checksum, but fully reproducible per seed.
var diag: Dictionary = {}

## Recount-style combat accounting (the DPS/HPS meter): seats[] index ->
## {dmg:{src:{total,n,max,crit_n}}, heal:{src:{total,n,max,over}}, taken:{...},
##  dmg_total, heal_total, over_total, taken_total}. Diag-family data: engine-
## written at the damage/heal funnels, deterministic per seed, NEVER part of the
## checksum. The HUD meter window and end-screen recap read it; sims may print it.
var meter: Dictionary = {}

## Per-boon impact accounting (STATS PAGE v2): seats[] index -> {boon_id: {total, n}}.
## Credits the marginal contribution of a boon to a hit (inline multipliers via a delta
## captured in the kit; raid-wide amplifiers — Glint/Sunder/Debilitate — credited once in
## damage_boss at the vuln fold). Overlapping stacked amps make each marginal a shade
## generous, so the recap prints these as "≈". Diag-family: engine-written, deterministic
## per seed, NEVER checksummed. -1 keys the whole-raid amp pool (window credited to no seat).
var boon_meter: Dictionary = {}

## 1 Hz time-series for the damage-over-time graph (STATS PAGE v2). One flat row per
## sample tick: [tick, boss_hp_pct, dmg0,dmg1,dmg2,dmg3, taken0,taken1,taken2,taken3]
## (cumulative dmg_total / taken_total per seat). Diag-family, deterministic, NEVER
## checksummed. Sampled in CombatCore.update; the stats page differentiates for rates.
var series: Array = []

func time() -> float:
	return float(tick) * dt

func enqueue(at_tick: int, seat: Seat, action: Dictionary) -> void:
	input_queue.append({"tick": at_tick, "seat": seat, "action": action})
