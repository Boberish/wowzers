## NetCombatController — the online drop-in for CombatController (R2). Same
## surface the HUD already uses (`state`, `player()`, `human()`, encounter_ended),
## but the sim is a lockstep REPLICA: it only advances when a server frame
## arrives, and human input is sent to the server instead of enqueued locally.
## Catch-up is natural — apply every buffered frame as it lands.
class_name NetCombatController
extends CombatController

var client: NetClient = null

func begin_net(state_in: CombatState, human_index: int) -> void:
	state = state_in
	human_seat_index = clampi(human_index, 0, state.seats.size() - 1)
	running = true

## Frames drive the replica; nothing steps locally.
func _process(_delta: float) -> void:
	pass

func human(action: Dictionary) -> void:
	if running and client != null and state != null and not state.over:
		# wire actions must be pure data: a Seat target becomes its seats[] index
		if action.get("target") is Seat:
			action = action.duplicate()
			action["target_i"] = state.seats.find(action["target"])
			action.erase("target")
		client.send_input(action)

## Apply one lockstep frame. Returns false on desync (order gap or checksum
## mismatch on a live fight — final-tick drift after state.over is view-only).
func on_frame(f: Dictionary) -> bool:
	if state == null or state.over:
		return true
	var n := int(f.get("n", -1))
	if n != state.tick + 1:
		push_warning("[net] frame order gap: got %d at tick %d" % [n, state.tick])
		running = false
		return false
	for i in f.get("ai", []):
		RaidNet.seat_to_ai(state, int(i), _spec_seed)
	RaidNet.step(state, f.get("in", []))
	if f.has("cs") and not state.over and String(f["cs"]) != str(state.checksum):
		push_warning("[net] DESYNC at tick %d: server cs %s != local %d" % [
			state.tick, String(f["cs"]), state.checksum])
		running = false
		return false
	if state.over:
		running = false
		encounter_ended.emit(state.won)
	return true

var _spec_seed: int = 1
func set_spec_seed(seed_v: int) -> void:
	_spec_seed = seed_v
