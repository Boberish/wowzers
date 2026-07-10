## A whole boss fight as data. In the full game these are authored as .tres files
## (M1+). For M0 we build one in code (see m0_content.gd).
class_name EncounterRes
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var hp: int = 1000
@export var intro: String = ""

## Continuous, untelegraphed tank auto-attacks: {every, min, max} in seconds/damage.
## Empty dict = no melee.
@export var melee: Dictionary = {}

@export var phases: Array[PhaseRes] = []
@export var abilities: Array[AbilityRes] = []

## ADD WAVES (raid): each AddRes spawns once when the boss's HP fraction crosses
## its `at` — the boss withdraws until the add dies. Empty = no adds (all solo content).
@export var adds: Array = []           ## Array of AddRes

## Hard timer (seconds). After this, escalating raid-wide damage forces a kill.
## -1 = no enrage.
@export var enrage_at: float = -1.0

# --- THE SEAL REWORK addenda (BOSS-PLAN §7; defaults are no-ops → byte-identical) ---

## E2 · how many stances the STANCE_SHIFT effect cycles through (Mistral experts = 3,
## Gemini voices = 2). 0 = no stance system (every existing fight; STANCE_SHIFT no-ops).
@export var stance_count: int = 0

## E4 · SEALTUNE — per-Seal tuning overrides, applied ONCE at build (RaidContent._apply_tune).
## Empty = the authored numbers stand (every existing fight). Keys (all optional): hp_mult,
## dmg_mult, cd_mult, melee{every,min,max}, enrage_at, window_mult (runtime grade width),
## plus the pacing knobs the fights read (phase_fracs, act_gates, stance_period, break_len,
## kick_window_mult, verse_miss_mult, …). S1 applies the build-time scalars; runtime keys are
## honored by the slice that uses them.
@export var tune: Dictionary = {}
