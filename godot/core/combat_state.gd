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

## Party-wide damage reduction {amt, until_tick} (Brinkwarden Last Stand).
var raid_dr: Dictionary = {}

# THE KILL SWITCH pre-fight primes (default-safe → every fight byte-identical when unset):
var party_out_mult: float = 1.0     ## OVERCLOCK DMG-amp — scales the raid's outgoing to the boss
var enrage_offset: float = 0.0      ## OVERCLOCK STALL (+s) / enrage-sooner curse (−s); NEVER mutate encounter.enrage_at

## How the fight is lost. "player" = solo duel (is_player death). "raid" = role
## extinction (no living tank / no living healer / no living dps → wipe).
var loss_mode: String = "player"

## Raid mode (R0): boss target selection runs off the threat table + taunts instead
## of "first living tank". GUARDED — no solo content sets this, so every solo sim
## stays byte-identical. See RAID-PLAN.md.
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

func time() -> float:
	return float(tick) * dt

func enqueue(at_tick: int, seat: Seat, action: Dictionary) -> void:
	input_queue.append({"tick": at_tick, "seat": seat, "action": action})
