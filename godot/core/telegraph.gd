## A boss ability currently "winding up". Only ONE telegraph is live at a time
## (the prototypes resolve one swing per think even if several are due — preserved).
class_name Telegraph
extends RefCounted

var ability: AbilityRes
var start_tick: int = 0
var dur_ticks: int = 0
var target: Seat = null     ## victim chosen at cast START (shown during the wind-up)

# --- multi-strike strings (M7) — unused (and untouched) for classic abilities ---
var next_strike: int = 0            ## index of the first unresolved beat
var answers: Dictionary = {}        ## beat idx -> {Seat: StrikeRes.Grade}, recorded at the press
