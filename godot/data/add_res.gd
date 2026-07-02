## An ADD wave (raid): at a main-boss HP-fraction threshold the boss WITHDRAWS and
## this unit takes the field with its own HP pool, melee, and ability set — kill it
## and the boss returns (main HP frozen meanwhile). PURE DATA like AbilityRes /
## PhaseRes so waves can be authored as .tres. Each wave fires ONCE per fight.
## Ability ids must not collide with the owning boss's (they share one timer table).
## No solo content defines adds, so every solo fight is untouched (see RAID-PLAN.md).
class_name AddRes
extends Resource

@export var at: float = 0.5            ## main-boss HP fraction that triggers the spawn
@export var id: StringName = &""
@export var name: String = ""          ## boss-plate name while it holds the field
@export var hp: int = 1000
@export var melee: Dictionary = {}     ## {every,min,max} — empty = no melee chip
@export var abilities: Array = []      ## Array of AbilityRes
