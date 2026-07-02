## NetClient — the Rift connection (R2). Owns the WebSocket to the server, the
## lobby handshake, and routes lockstep frames into a NetCombatController. The HUD
## listens to the signals; combat itself renders off the controller's replica
## state exactly like offline play.
class_name NetClient
extends Node

signal connected
signal disconnected(reason: String)
signal net_error(msg: String)
signal room_update(room: Dictionary)
signal fight_started(spec: Dictionary, you: String)
signal fight_ended(won: bool, cause: String)
signal desynced

const CFG_PATH := "user://rift_net.cfg"

var controller: NetCombatController = null   ## assigned by the HUD before a fight
var player_name: String = "Raider"
var room_code: String = NetProtocol.DEFAULT_ROOM

var _peer := WebSocketMultiplayerPeer.new()
var _phase := "idle"      ## idle | connecting | lobby | fight

func connect_to(url: String, pname: String, room: String) -> void:
	player_name = pname
	room_code = room
	var err := _peer.create_client(url)
	if err != OK:
		net_error.emit("could not open %s (err %d)" % [url, err])
		return
	_phase = "connecting"

func close(reason: String = "left") -> void:
	if _phase != "idle":
		_peer.close()
		_phase = "idle"
		disconnected.emit(reason)

func send(msg: Dictionary) -> void:
	if _phase == "idle" or _phase == "connecting":
		return
	_peer.set_target_peer(1)
	_peer.put_packet(NetProtocol.encode(msg))

func send_input(action: Dictionary) -> void:
	send({"t": "input", "action": action})

func peer_id() -> int:
	return _peer.get_unique_id()

func _process(_delta: float) -> void:
	if _phase == "idle":
		return
	_peer.poll()
	var st := _peer.get_connection_status()
	if st == MultiplayerPeer.CONNECTION_DISCONNECTED:
		var was := _phase
		_phase = "idle"
		if was == "connecting":
			net_error.emit("could not reach the server")
		else:
			disconnected.emit("connection lost")
		return
	if st != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	while _peer.get_available_packet_count() > 0:
		var msg := NetProtocol.decode(_peer.get_packet())
		if not msg.is_empty():
			_handle(msg)

func _handle(msg: Dictionary) -> void:
	match String(msg.get("t", "")):
		"welcome":
			if int(msg.get("ver", -1)) != NetProtocol.VERSION:
				net_error.emit("server protocol v%s ≠ client v%d" % [str(msg.get("ver")), NetProtocol.VERSION])
				close("version mismatch")
				return
			_phase = "lobby"
			send({"t": "join", "ver": NetProtocol.VERSION, "name": player_name, "room": room_code})
			connected.emit()
		"err":
			net_error.emit(String(msg.get("msg", "server error")))
		"room":
			room_update.emit(msg)
		"start":
			_phase = "fight"
			fight_started.emit(msg.get("spec", {}), String(msg.get("you", "")))
		"f":
			if controller != null:
				if not controller.on_frame(msg):
					desynced.emit()
		"end":
			_phase = "lobby"
			fight_ended.emit(bool(msg.get("won", false)), String(msg.get("cause", "")))

# --- remembered connection settings (server URL / name / room) ---
static func load_cfg() -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return {}
	return {
		"url": String(cf.get_value("net", "url", "")),
		"name": String(cf.get_value("net", "name", "")),
		"room": String(cf.get_value("net", "room", "")),
	}

static func save_cfg(url: String, pname: String, room: String) -> void:
	var cf := ConfigFile.new()
	cf.set_value("net", "url", url)
	cf.set_value("net", "name", pname)
	cf.set_value("net", "room", room)
	cf.save(CFG_PATH)
