## Base class for a decision-maker. `act` receives an OBSERVATION (exactly what a
## human sees on screen, via CombatCore.observe) and returns an ACTION dict, or {}
## for "do nothing this tick".
##
## Human input adapters, AI allies, and sim agents all subclass this. AI "skill"
## (reaction latency, timing accuracy) becomes parameters on the subclass — so
## "how strong is the AI ally" and "what skill band are we simming" are one knob.
class_name Policy
extends RefCounted

func act(_obs: Dictionary) -> Dictionary:
	return {}
