## NetServer — the authoritative Rift server (R2). A plain Node (embeddable in
## headless tests) that owns the WebSocket listener, the room/lobby bookkeeping,
## and the 30 Hz lockstep clock for every room in a fight. It runs the SAME
## RaidNet.step() as every client; its authority is the clock and the input order.
## Run standalone via net/server_main.gd; see server/README.md for deploys.
class_name NetServer
extends Node

signal log_line(msg: String)

const MAX_INPUTS_PER_TICK := 3     ## per seat per tick (parity with local key bursts)
const CS_EVERY := 30               ## checksum cadence, in ticks

var port: int = NetProtocol.DEFAULT_PORT
var time_scale: float = 1.0        ## >1 = fast headless soak (clients are frame-driven)

var _peer := WebSocketMultiplayerPeer.new()
var _peers := {}                   ## peer_id -> {name, room}
var _rooms := {}                   ## code -> room dict (see _make_room)

func start() -> int:
	var err := _peer.create_server(port)
	if err == OK:
		_peer.peer_connected.connect(_on_peer_connected)
		_peer.peer_disconnected.connect(_on_peer_disconnected)
		_log("listening on ws://0.0.0.0:%d (protocol v%d)" % [port, NetProtocol.VERSION])
	else:
		_log("FAILED to bind port %d (err %d)" % [port, err])
	return err

func _log(m: String) -> void:
	log_line.emit("[server] " + m)

func _make_room(code: String) -> Dictionary:
	return {
		"code": code,
		"phase": "lobby",              # "lobby" | "fight"
		"players": {},                 # peer_id -> {name, seat(""), aspect(""), ready}
		"host": 0,
		"enc": "riftmaw",              # the Seal the host picked (see RaidContent Seals)
		"spec": {},
		"state": null,                 # CombatState during a fight
		"accum": 0.0,
		"pending": {},                 # seat_i -> [actions] gathered for the next tick
		"pending_ai": [],              # seat_i list: disconnect takeovers for the next tick
	}

# ------------------------------------------------------------ connection events
func _on_peer_connected(id: int) -> void:
	_peers[id] = {"name": "", "room": ""}
	_send(id, {"t": "welcome", "id": id, "ver": NetProtocol.VERSION})

func _on_peer_disconnected(id: int) -> void:
	var info: Dictionary = _peers.get(id, {})
	_peers.erase(id)
	var code := String(info.get("room", ""))
	if code == "" or not _rooms.has(code):
		return
	var room: Dictionary = _rooms[code]
	var pl: Dictionary = room["players"].get(id, {})
	var seat := String(pl.get("seat", ""))
	room["players"].erase(id)
	_log("%s left %s" % [String(pl.get("name", str(id))), code])
	if room["players"].is_empty():
		_rooms.erase(code)               # last one out closes the room (fight dies with it)
		_log("room %s closed" % code)
		return
	if room["host"] == id:
		room["host"] = (room["players"].keys())[0]
	if room["phase"] == "fight" and seat != "":
		room["pending_ai"].append(RaidNet.SEAT_KEYS.find(seat))
		_log("seat %s -> AI takeover" % seat)
	_broadcast_room(room)

# ------------------------------------------------------------ main loop
func _process(delta: float) -> void:
	_peer.poll()
	while _peer.get_available_packet_count() > 0:
		var from := _peer.get_packet_peer()
		var msg := NetProtocol.decode(_peer.get_packet())
		if not msg.is_empty():
			_handle(from, msg)
	for code in _rooms.keys():
		var room: Dictionary = _rooms[code]
		if room["phase"] == "fight":
			_tick_room(room, delta)

func _tick_room(room: Dictionary, delta: float) -> void:
	var s: CombatState = room["state"]
	if s == null:
		return
	room["accum"] = float(room["accum"]) + delta * time_scale
	while float(room["accum"]) >= s.dt and not s.over:
		room["accum"] = float(room["accum"]) - s.dt
		var frame := {"t": "f", "n": s.tick + 1}
		var inputs: Array = []
		for seat_i in room["pending"]:
			for a in room["pending"][seat_i]:
				inputs.append([seat_i, a])
		room["pending"] = {}
		if not inputs.is_empty():
			frame["in"] = inputs
		var ai: Array = room["pending_ai"]
		room["pending_ai"] = []
		if not ai.is_empty():
			frame["ai"] = ai
			for i in ai:
				RaidNet.seat_to_ai(s, int(i), int(room["spec"]["seed"]))
		RaidNet.step(s, inputs)
		if s.tick % CS_EVERY == 0:
			frame["cs"] = str(s.checksum)   # string: 63-bit ints don't survive JSON floats
		_broadcast(room, frame)
		if s.over:
			_log("room %s fight over: %s at tick %d (cs %d)" % [
				room["code"], ("WIN" if s.won else s.loss_cause), s.tick, s.checksum])
			_broadcast(room, {"t": "end", "won": s.won, "n": s.tick, "cause": s.loss_cause})
			_end_fight(room)
			return

func _end_fight(room: Dictionary) -> void:
	room["phase"] = "lobby"
	room["state"] = null
	room["pending"] = {}
	room["pending_ai"] = []
	for pid in room["players"]:
		room["players"][pid]["ready"] = false
	_broadcast_room(room)

# ------------------------------------------------------------ messages
func _handle(id: int, msg: Dictionary) -> void:
	match String(msg.get("t", "")):
		"join":
			_join(id, msg)
		"claim":
			_claim(id, String(msg.get("seat", "")))
		"unclaim":
			_unclaim(id)
		"aspect":
			_aspect(id, String(msg.get("aspect", "")))
		"ready":
			_ready_flag(id, bool(msg.get("on", false)))
		"boss":
			_boss_pick(id, String(msg.get("enc", "")))
		"start":
			_start_fight(id)
		"input":
			_on_input_msg(id, msg)
		"leave":
			_peer.disconnect_peer(id)

func _claim(id: int, seat: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby" or not seat in RaidNet.SEAT_KEYS:
		return
	for opid in room["players"]:                 # seat already taken?
		if String(room["players"][opid]["seat"]) == seat:
			return
	room["players"][id]["seat"] = seat
	room["players"][id]["aspect"] = String(RaidNet.DEFAULT_ASPECT[seat])
	_broadcast_room(room)

func _unclaim(id: int) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	room["players"][id]["seat"] = ""
	room["players"][id]["aspect"] = ""
	_broadcast_room(room)

func _aspect(id: int, a: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	var seat := String(room["players"][id].get("seat", ""))
	if seat != "" and a in _valid_aspects(seat):
		room["players"][id]["aspect"] = a
		_broadcast_room(room)

func _ready_flag(id: int, on: bool) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	room["players"][id]["ready"] = on
	_broadcast_room(room)

## Host picks the Seal (boss) for the next pull. Validated against the roster.
func _boss_pick(id: int, enc: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby" or room["host"] != id:
		return
	for e in RaidContent.run_encounters():
		if String((e as EncounterRes).id) == enc:
			room["enc"] = enc
			_broadcast_room(room)
			return

func _valid_aspects(seat: String) -> Array:
	match seat:
		"tank": return ["warden", "juggernaut"]
		"blade": return ["tempo", "venomancer"]
		"caster": return ["disruptor", "silencer"]
		_: return ["tidecaller", "brinkwarden"]

func _join(id: int, msg: Dictionary) -> void:
	if int(msg.get("ver", -1)) != NetProtocol.VERSION:
		_send(id, {"t": "err", "msg": "version mismatch — update your client"})
		_peer.disconnect_peer(id)
		return
	var code := String(msg.get("room", NetProtocol.DEFAULT_ROOM)).to_upper().strip_edges()
	if code == "":
		code = NetProtocol.DEFAULT_ROOM
	var pname := String(msg.get("name", "Raider")).strip_edges().left(18)
	if pname == "":
		pname = "Raider%d" % id
	if not _rooms.has(code):
		_rooms[code] = _make_room(code)
	var room: Dictionary = _rooms[code]
	if room["phase"] != "lobby":
		_send(id, {"t": "err", "msg": "that room's fight is in progress — try again soon"})
		return
	if room["players"].size() >= 4:
		_send(id, {"t": "err", "msg": "room is full"})
		return
	_peers[id] = {"name": pname, "room": code}
	room["players"][id] = {"name": pname, "seat": "", "aspect": "", "ready": false}
	if room["host"] == 0 or not room["players"].has(room["host"]):
		room["host"] = id
	_log("%s joined %s" % [pname, code])
	_broadcast_room(room)

func _start_fight(id: int) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby" or room["host"] != id:
		return
	var seat_cfg := {}
	for pid in room["players"]:
		var pl: Dictionary = room["players"][pid]
		if String(pl["seat"]) == "":
			_send(id, {"t": "err", "msg": "%s hasn't claimed a seat" % pl["name"]})
			return
		if not bool(pl["ready"]) and pid != id:
			_send(id, {"t": "err", "msg": "%s isn't ready" % pl["name"]})
			return
		seat_cfg[String(pl["seat"])] = {"aspect": String(pl["aspect"]), "ai": false}
	var spec := RaidNet.make_spec(randi() & 0x7FFFFFFF, seat_cfg, String(room["enc"]))
	room["spec"] = spec
	room["state"] = RaidNet.build(spec, "")
	room["phase"] = "fight"
	room["accum"] = 0.0
	room["pending"] = {}
	room["pending_ai"] = []
	for pid in room["players"]:
		_send(pid, {"t": "start", "spec": spec, "you": String(room["players"][pid]["seat"])})
	_log("room %s PULL: seed %d, humans %d" % [room["code"], int(spec["seed"]), room["players"].size()])

func _on_input_msg(id: int, msg: Dictionary) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "fight":
		return
	var seat := String(room["players"][id].get("seat", ""))
	if seat == "":
		return
	var seat_i := RaidNet.SEAT_KEYS.find(seat)
	var action = msg.get("action")
	if not (action is Dictionary):
		return
	if not room["pending"].has(seat_i):
		room["pending"][seat_i] = []
	if (room["pending"][seat_i] as Array).size() < MAX_INPUTS_PER_TICK:
		room["pending"][seat_i].append(action)

# ------------------------------------------------------------ send helpers
func _room_of(id: int) -> Dictionary:
	var code := String(_peers.get(id, {}).get("room", ""))
	if code != "" and _rooms.has(code):
		var room: Dictionary = _rooms[code]
		if room["players"].has(id):
			return room
	return {}

func _send(id: int, msg: Dictionary) -> void:
	_peer.set_target_peer(id)
	_peer.put_packet(NetProtocol.encode(msg))

func _broadcast(room: Dictionary, msg: Dictionary) -> void:
	var pkt := NetProtocol.encode(msg)
	for pid in room["players"]:
		_peer.set_target_peer(pid)
		_peer.put_packet(pkt)

func _broadcast_room(room: Dictionary) -> void:
	var players: Array = []
	for pid in room["players"]:
		var pl: Dictionary = room["players"][pid]
		players.append({"id": pid, "name": pl["name"], "seat": pl["seat"],
			"aspect": pl["aspect"], "ready": pl["ready"]})
	_broadcast(room, {"t": "room", "code": room["code"], "phase": room["phase"],
		"host": room["host"], "enc": String(room["enc"]), "players": players})
