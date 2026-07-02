## A minimal tank AI: press the defensive verb when a dangerous, defensible swing
## aimed at me is about to land and my defense is off cooldown. This is the same
## Policy a human's keyboard adapter will implement — proving human = AI seats.
##
## `reaction` (seconds before resolve that it commits) is a SKILL knob: lower =
## sharper play. Sweeping it gives win-rate BANDS instead of a single number.
class_name TankPolicy
extends Policy

var reaction: float = 0.45

func act(obs: Dictionary) -> Dictionary:
	var tg: Dictionary = obs.get("telegraph", {})
	if tg.is_empty():
		return {}
	if tg.get("defensible", false) and tg.get("targets_me", false) \
			and obs.get("defense_ready", false) \
			and float(tg.get("remaining", 99.0)) <= reaction:
		return {"type": "defense"}
	return {}
