## CombatController — owns a live fight and drives CombatCore on a fixed timestep.
## The bridge between the pure engine and the interactive world: it accumulates real
## frame time into whole 30 Hz ticks, lets AI seats act via their policy, feeds the
## human seat's input in, and announces the end. (Netcode later swaps this local
## driver for a server-authoritative one — the engine underneath is unchanged.)
class_name CombatController
extends Node

signal encounter_ended(won: bool)

var state: CombatState
var running: bool = false
var paused: bool = false            ## view-layer freeze (pause menu). OFFLINE only —
                                    ## an online lockstep fight must never freeze locally.
var human_seat_index: int = 0      ## which seat the human drives (raid: any seat)
var _accum: float = 0.0

## Begin a fight from a prebuilt state (the HUD builds it from the RunState).
## `human_index` picks the human's seat (default 0 — every solo HUD's layout).
func begin(state_in: CombatState, human_index: int = 0) -> void:
	state = state_in
	human_seat_index = clampi(human_index, 0, state.seats.size() - 1)
	state.seats[human_seat_index].policy = null   # the human drives this seat; AI policy removed
	_accum = 0.0
	running = true

func _process(delta: float) -> void:
	if not running or paused or state == null or state.over:
		return   # paused: don't accumulate — resume picks up where the fight froze
	_accum += minf(0.25, delta)
	var dt := state.dt
	while _accum >= dt and not state.over:
		_accum -= dt
		for seat in state.seats:                 # AI allies (if any) act; human is input-driven
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(state, seat))
				if not a.is_empty():
					state.enqueue(state.tick + 1, seat, a)
		CombatCore.update(state)
	if state.over:
		running = false
		encounter_ended.emit(state.won)

## Queue a human action (defense / ability) for the next tick.
func human(action: Dictionary) -> void:
	if state != null and not state.over:
		state.enqueue(state.tick + 1, state.seats[human_seat_index], action)

func player() -> Seat:
	return state.seats[human_seat_index] if state != null else null
