## A boss phase breakpoint. Bosses ramp by crossing HP-fraction thresholds.
## `at` = HP fraction at/below which this phase is active (list them descending).
## `mult` scales ability/effect damage; `speed` divides ability cooldowns (faster).
class_name PhaseRes
extends Resource

@export var at: float = 1.0
@export var mult: float = 1.0
@export var speed: float = 1.0
