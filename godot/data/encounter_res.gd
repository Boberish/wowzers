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
