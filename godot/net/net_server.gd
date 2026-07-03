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
		"campaign": null,              # MAP-3b: the online Topology descent (see _start_map)
		"seat_cfg": {},                # seat -> {aspect, ai} fixed at descent start
		"map_fight": {},               # which node/kind the current fight came from
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
	# MAP-3b: a dropped raider's seat runs AI for the rest of the descent's fights
	if room.get("campaign", null) != null and seat != "" and (room["seat_cfg"] as Dictionary).has(seat):
		room["seat_cfg"][seat]["ai"] = true
	# a drop mid-DRAFT no longer owes a pick; if that was the last one, continue
	if room["phase"] == "draft" and room.get("campaign", null) != null and seat != "":
		var dp: Array = room["campaign"]["draft_pending"]
		dp.erase(seat)
		if dp.is_empty():
			_finish_draft(room)
			return
	if room["phase"] == "map" and room.get("campaign", null) != null:
		_broadcast_map(room)          # the (possibly new) leader keeps picking the route
	else:
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
	# MAP-3b: a map-run fight writes its result back into the campaign and returns to
	# the map (or advances a ring / ends the descent). A plain single-Seal pull just
	# returns to the lobby (unchanged).
	var cp = room.get("campaign", null)
	if cp != null and room.get("state") != null:
		var s: CombatState = room["state"]
		var fracs: Array = cp["fracs"]
		for i in s.seats.size():
			if i < fracs.size():
				var u: Seat = s.seats[i]
				if u.alive():
					fracs[i] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
				else:
					fracs[i] = 0.35            # reboot
					cp["wounds"][i] = minf(0.4, float(cp["wounds"][i]) + 0.2)  # + a corrupted sector
				if u.role == "healer":
					cp["mana"] = clampf(u.resource / maxf(1.0, u.resource_max), 0.05, 1.0)
		var won := s.won
		room["state"] = null
		room["pending"] = {}
		room["pending_ai"] = []
		if not won:
			_broadcast(room, {"t": "campaign", "won": false})   # wipe ends the descent
			room["campaign"] = null
			_reset_lobby(room)
			return
		var seal := bool((room.get("map_fight", {}) as Dictionary).get("is_seal", false))
		if seal and int(cp["floor"]) + 1 >= RaidContent.FLOORS.size():
			_broadcast(room, {"t": "campaign", "won": true})   # the last Seal (ROOT) — realm won
			room["campaign"] = null
			_reset_lobby(room)
			return
		# the descent continues → a boon DRAFT, then map (skirmish) or ring-advance (Seal)
		_begin_draft(room, "advance" if seal else "map")
		return
	_reset_lobby(room)

## Post-fight DRAFT phase: every human seat picks a boon before the run continues.
## Each client rolls its OWN offers (from its local run) and sends back only the picked
## id; the server records it per seat so it rides every future fight spec.
func _begin_draft(room: Dictionary, next_action: String) -> void:
	var cp: Dictionary = room["campaign"]
	cp["next_after_draft"] = next_action
	var humans: Array = []
	for pid in room["players"]:
		var seat := String(room["players"][pid]["seat"])
		if seat != "":
			humans.append(seat)
	cp["draft_pending"] = humans
	if humans.is_empty():
		_finish_draft(room)
		return
	room["phase"] = "draft"
	_broadcast(room, {"t": "draft"})
	_log("room %s DRAFT: %d seats picking" % [room["code"], humans.size()])

func _pick_boon(id: int, boon_id: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "draft":
		return
	var cp = room.get("campaign", null)
	if cp == null:
		return
	var seat := String(room["players"][id].get("seat", ""))
	if seat == "" or not (cp["draft_pending"] as Array).has(seat):
		return
	if boon_id != "":                       # "" = skipped (pool exhausted); still counts
		if not cp["boons"].has(seat):
			cp["boons"][seat] = {}
		cp["boons"][seat][boon_id] = true
	(cp["draft_pending"] as Array).erase(seat)
	if (cp["draft_pending"] as Array).is_empty():
		_finish_draft(room)

func _finish_draft(room: Dictionary) -> void:
	var cp: Dictionary = room["campaign"]
	if String(cp["next_after_draft"]) == "advance":
		cp["floor"] = int(cp["floor"]) + 1
		cp["toast"] = "PRIVILEGE ELEVATED — descending to the next ring."
		_build_floor_srv(room)
	cp["next_after_draft"] = ""
	room["phase"] = "map"
	_broadcast_map(room)

func _reset_lobby(room: Dictionary) -> void:
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
			# v10: the client transmits its 📁 Prior tier (the dedicated server can't read a
			# client's user:// file, so it TRUSTS + caps it). Folds into the seat's check floor.
			var rm := _room_of(id)
			if not rm.is_empty() and (rm.get("players", {}) as Dictionary).has(id):
				rm["players"][id]["prior"] = clampi(int(msg.get("prior", 0)), 0, LuckProfile.PRIOR_CAP)
		"unclaim":
			_unclaim(id)
		"aspect":
			_aspect(id, String(msg.get("aspect", "")))
		"class":
			_class(id, String(msg.get("cls", "")))
		"ready":
			_ready_flag(id, bool(msg.get("on", false)))
		"boss":
			_boss_pick(id, String(msg.get("enc", "")))
		"start":
			_start_fight(id)
		"mapstart":
			_start_map(id)
		"node":
			_pick_node(id, int(msg.get("id", -1)))
		"choice":
			_pick_choice(id, msg)
		"pick":
			_pick_boon(id, String(msg.get("id", "")))
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
	# the healer seat has two classes; claim it as the default Mender (toggle in lobby)
	var cls := "mender" if seat == "healer" else ""
	room["players"][id]["cls"] = cls
	room["players"][id]["aspect"] = RaidNet.default_aspect(seat, cls)
	_broadcast_room(room)

func _unclaim(id: int) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	room["players"][id]["seat"] = ""
	room["players"][id]["aspect"] = ""
	room["players"][id]["cls"] = ""
	_broadcast_room(room)

func _aspect(id: int, a: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	var seat := String(room["players"][id].get("seat", ""))
	var cls := String(room["players"][id].get("cls", ""))
	if seat != "" and a in _valid_aspects(seat, cls):
		room["players"][id]["aspect"] = a
		_broadcast_room(room)

## Toggle the healer seat's CLASS (Mender / Bloomweaver). Resets the aspect to the new
## class's default so the pair shown in the lobby always matches the class.
func _class(id: int, cls: String) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "lobby":
		return
	var seat := String(room["players"][id].get("seat", ""))
	if seat == "healer" and (cls == "mender" or cls == "bloomweaver"):
		room["players"][id]["cls"] = cls
		room["players"][id]["aspect"] = RaidNet.default_aspect(seat, cls)
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

func _valid_aspects(seat: String, cls: String = "") -> Array:
	match seat:
		"tank": return ["warden", "juggernaut"]
		"blade": return ["tempo", "venomancer"]
		"caster": return ["disruptor", "silencer"]
		_: return ["wildgrove", "thornveil"] if cls == "bloomweaver" else ["tidecaller", "brinkwarden"]

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
	room["players"][id] = {"name": pname, "seat": "", "aspect": "", "cls": "", "ready": false, "prior": 0}
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
		seat_cfg[String(pl["seat"])] = {"aspect": String(pl["aspect"]), "ai": false, "cls": String(pl.get("cls", ""))}
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

# ------------------------------------------------------------ MAP-3b campaign
## Host begins the Topology descent (instead of a single-Seal PULL). Same
## seat/ready validation; then the server generates floor 0 and enters "map" phase.
func _start_map(id: int) -> void:
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
		seat_cfg[String(pl["seat"])] = {"aspect": String(pl["aspect"]), "ai": false,
			"cls": String(pl.get("cls", "")), "prior": int(pl.get("prior", 0))}   # v10: trusted client Prior
	room["seat_cfg"] = seat_cfg
	var leader_prior := int((room["players"] as Dictionary).get(room["host"], {}).get("prior", 0))
	room["campaign"] = {
		"map_seed": randi() & 0x7FFFFFFF, "floor": 0, "node": -1,
		"inv": {}, "fracs": [1.0, 1.0, 1.0, 1.0], "wounds": [0.0, 0.0, 0.0, 0.0], "mana": 1.0,
		"tickets": {}, "total": 0, "closed": 0, "map": null, "fights": [],
		"toast": "", "pending_event": "", "pending_page": "",   # P3: current branch stage
		"boons": {},                 # online boons: seat_key -> {boon_id: true}, drafted over the descent
		"draft_pending": [],         # human seats that still owe a pick this draft phase
		"next_after_draft": "",      # "map" | "advance" — what to do once everyone's picked
		# THE INFERENCE CHECK meta: ⚡ Entropy is server-owned & broadcast; flags ripple across
		# nodes; check_fails drives comeback pity. Starting ⚡ scales off the LEADER's trusted
		# 📁 Prior (v10); each seat's own Prior rides seat_cfg into its check floor.
		"entropy": LuckProfile.starting_entropy(leader_prior), "flags": {}, "check_fails": 0,
	}
	_build_floor_srv(room)
	room["phase"] = "map"
	_log("room %s DESCENT started (seed %d)" % [room["code"], int(room["campaign"]["map_seed"])])
	_broadcast_map(room)

## Generate the current ring's map. Online v1 carries NO personal GATE nodes
## (extra_quota {}); the ROOT floor keeps its credential-shard gate + tickets.
func _build_floor_srv(room: Dictionary) -> void:
	var cp: Dictionary = room["campaign"]
	var fl: Dictionary = RaidContent.FLOORS[int(cp["floor"])]
	cp["fights"] = RaidContent.floor_fights(int(fl["ring"]))
	cp["map"] = RunMap.generate(int(cp["map_seed"]) + int(cp["floor"]) * 101,
		(cp["fights"] as Array).size(), MapContent.raid_event_ids(), {},
		int(fl["shard_req"]), int(fl.get("tickets", 0)))
	cp["node"] = -1
	cp["inv"] = {}
	cp["tickets"] = {}
	cp["total"] = (cp["map"] as RunMap).tickets.size()
	cp["closed"] = 0
	cp["pending_event"] = ""

## The leader picks the next node. Validated against reachability (key/shard gates).
func _pick_node(id: int, node_id: int) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "map" or room["host"] != id:
		return
	var cp = room.get("campaign", null)
	if cp == null or String(cp.get("pending_event", "")) != "":
		return
	var m: RunMap = cp["map"]
	if not (m.reachable(int(cp["node"]), cp["inv"]) as Array).has(node_id):
		return
	cp["node"] = node_id
	cp["toast"] = ""
	_enter_node_srv(room, node_id)

func _enter_node_srv(room: Dictionary, node_id: int) -> void:
	var cp: Dictionary = room["campaign"]
	var m: RunMap = cp["map"]
	var n: Dictionary = m.node(node_id)
	var first := not bool(n.get("visited", false))
	n["visited"] = true
	if first and bool(n.get("shard", false)):
		cp["inv"]["shards"] = int(cp["inv"].get("shards", 0)) + 1
	if first:
		_ticket_srv(cp, n)
	if first and bool(n["key"]) and not cp["inv"].get("api_key", false):
		cp["inv"]["api_key"] = true
		cp["toast"] = "API KEY acquired — 401 doors are yours."
	_resolve_node_srv(room, n)

## Mirror of raid_hud._ticket_at, server-side.
func _ticket_srv(cp: Dictionary, n: Dictionary) -> void:
	var topen := String(n.get("ticket_open", ""))
	if topen != "" and not cp["tickets"].has(topen):
		var td := MapContent.ticket(topen)
		cp["tickets"][topen] = String(td.get("title", "TICKET"))
		cp["toast"] = "📋  %s  —  picked up (turn it in deeper on this lane)" % String(td.get("title", "TICKET"))
	var tclose := String(n.get("ticket_close", ""))
	if tclose != "" and cp["tickets"].has(tclose):
		var td2 := MapContent.ticket(tclose)
		cp["tickets"].erase(tclose)
		cp["closed"] = int(cp["closed"]) + 1
		_apply_fx_srv(cp, td2.get("reward", {}))
		cp["toast"] = "✅  %s  —  CLOSED, reward claimed" % String(td2.get("title", "TICKET"))
		if int(cp["closed"]) >= int(cp["total"]) and int(cp["total"]) > 0:
			_apply_fx_srv(cp, MapContent.SPRINT_RETRO_FX)
			cp["toast"] = "★  SPRINT RETRO — every ticket closed! Sectors repaired, reserves topped."

func _resolve_node_srv(room: Dictionary, n: Dictionary) -> void:
	var cp: Dictionary = room["campaign"]
	match String(n["kind"]):
		RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
			room["map_fight"] = {"node": int(n["id"]), "is_seal": String(n["kind"]) == RunMap.KIND_SEAL}
			_launch_map_fight_srv(room, int(n["fight"]))
		RunMap.KIND_EVENT:
			# INFERENCE CHECK (v7 — the SEAT-PICKER): compute each choice's % / breakdown /
			# gate for EVERY candidate seat and broadcast `by_seat`, so the party can send
			# their SPECIALIST to the terminal (the seat's build drives the check). The pure
			# die (map_seed,node,choice) is seat-independent, so the leader shows the ✓/✗
			# locally for the chosen seat, identical to the server's authoritative resolve.
			cp["pending_event"] = String(n["event"])
			cp["pending_page"] = ""
			_broadcast_mapstop(room, String(n["event"]), "")
		RunMap.KIND_COOLING:
			_apply_fx_srv(cp, {"heal": MapContent.COOLING_HEAL, "mana": 1.0, "repair": true})
			cp["toast"] = "COOLING STATION — throttled: integrity up, sectors repaired, reserves topped."
			_broadcast_map(room)
		RunMap.KIND_CACHE:
			_apply_fx_srv(cp, {"patch": true})
			cp["toast"] = "CACHE HIT — salvage routed to your most battered raider (+25%)."
			_broadcast_map(room)
		_:
			_broadcast_map(room)

## The campaign `cp` is already MapFx's cp-view shape (fracs/wounds/mana/inv/…), so
## the authoritative server resolves every event effect through the SAME applier the
## offline HUD and the sim walker use — a new reward key can't diverge across them.
func _apply_fx_srv(cp: Dictionary, fx: Dictionary) -> void:
	MapFx.apply(cp, fx)

## Leader answers an event panel. `msg` = {i, nudge, seat}. A CHECK is resolved
## authoritatively here: the acting seat's ctx gives the same % the leader saw, and the
## pure die (map_seed,node,i) gives the same roll — so the leader's local ✓/✗ and this
## resolve MATCH by construction (no desync). Free choices apply their fx; a gate the
## acting seat can't meet is rejected (anti-cheat).
func _pick_choice(id: int, msg: Dictionary) -> void:
	var room := _room_of(id)
	if room.is_empty() or room["phase"] != "map" or room["host"] != id:
		return
	var cp = room.get("campaign", null)
	if cp == null:
		return
	var eid := String(cp.get("pending_event", ""))
	if eid == "":
		return
	var ev := MapContent.event(eid)
	var page := String(cp.get("pending_page", ""))
	var choices: Array = _page_choices(ev, page)
	var i := int(msg.get("i", -1))
	if i < 0 or i >= choices.size():
		return
	var c: Dictionary = choices[i]
	# the party's chosen specialist (v7); an unknown seat falls back to the leader
	var seat := String(msg.get("seat", ""))
	if not (room.get("seat_cfg", {}) as Dictionary).has(seat):
		seat = _leader_seat(room)
	var ctx := _map_ctx_srv(room, seat)
	# the pure decision (gate / roll / toast / ⚡ spend). The die slot is per (page, choice)
	# so a branch sub-page has its own roll — identical to the leader's local resolve.
	var r := resolve_event_choice(c, ctx, int((cp["map"] as RunMap).seed), int(cp["node"]),
		MapCheck.choice_slot(page, i), int(msg.get("nudge", 0)), int(cp["entropy"]),
		int(msg.get("attempt", 0)))     # post-fail mulligans the leader committed to
	if not bool(r["accept"]):
		return                               # can't commit a locked choice
	if bool(r["is_check"]):
		cp["check_fails"] = 0 if bool(r["success"]) else int(cp["check_fails"]) + 1
	cp["entropy"] = int(r["entropy_after"])
	_apply_fx_srv(cp, r["fx"])                # MapFx handles heal/hurt/wound/draft→patch/⚡/📁/…
	cp["toast"] = String(r["toast"])
	# P3 STAGING: a branch/goto leg advances to a sub-page (a fresh mapstop); else the
	# event ends and we broadcast the map.
	var nxt := String(r.get("goto", ""))
	if nxt != "" and (ev.get("pages", {}) as Dictionary).has(nxt):
		cp["pending_page"] = nxt
		_broadcast_mapstop(room, eid, nxt)
	else:
		cp["pending_event"] = ""
		cp["pending_page"] = ""
		_broadcast_map(room)

## The choices for the current stage: the event's root, or a branch sub-page.
func _page_choices(ev: Dictionary, page: String) -> Array:
	if page == "":
		return ev.get("choices", [])
	return ((ev.get("pages", {}) as Dictionary).get(page, {}) as Dictionary).get("choices", [])

## Broadcast a mapstop for one STAGE (root page = "", or a branch sub-page): per-seat
## metadata for the stage's choices + the suggested specialist. The client looks the
## stage's choice bodies up locally from MapContent by (event, page).
func _broadcast_mapstop(room: Dictionary, event_id: String, page: String) -> void:
	var cp: Dictionary = room["campaign"]
	var ev := MapContent.event(event_id)
	var raw: Array = _page_choices(ev, page)
	var src: Dictionary = ev if page == "" else (ev.get("pages", {}) as Dictionary).get(page, {})
	var seats := _candidate_seats(room)
	var choices: Array = []
	for i in raw.size():
		var c: Dictionary = raw[i]
		var d := {"i": i, "label": String(c.get("label", "")),
			"kind": String(c.get("kind", "free")),
			"verb": String((c.get("check", {}) as Dictionary).get("verb", "CHECK")), "by_seat": {}}
		for st in seats:
			d["by_seat"][st] = _choice_meta_for(c, _map_ctx_srv(room, st))
		choices.append(d)
	_broadcast(room, {"t": "mapstop", "event": event_id, "page": page,
		"node": int(cp["node"]), "map_seed": int((cp["map"] as RunMap).seed),
		"seats": seats, "suggested": _suggest_seat(seats, choices), "entropy": int(cp["entropy"]),
		"title": String(src.get("title", ev.get("title", ""))),
		"body": String(src.get("body", "")), "choices": choices, "accent": "void"})

## PURE, authoritative resolution of an event choice (Node-free, testable). Gate-checks,
## rolls a CHECK on the deterministic die (identical to the leader's local display), spends
## ⚡ (always, on commit), and formats the ✓/✗ toast. Returns everything the caller applies.
## `accept:false` = a locked gate (reject). The die matches the client because both use the
## same (map_seed, node, i) and the same server-broadcast %.
static func resolve_event_choice(c: Dictionary, ctx: Dictionary, map_seed: int, node_id: int,
		i: int, nudge_req: int, entropy_have: int, attempt: int = 0) -> Dictionary:
	var gate: Dictionary = c.get("gate", {})
	if not gate.is_empty() and not MapCheck.gate_ok(gate, ctx):
		return {"accept": false}
	if MapCheck.check_like(String(c.get("kind", "free"))):
		var nudge := clampi(nudge_req, 0, mini(MapCheck.NUDGE_MAX, entropy_have))
		var att := clampi(attempt, 0, MapCheck.MULLIGAN_MAX)
		# ⚡ spent = nudge (pre-commit) + rerolls (attempt × cost); the die honours `att`
		var spend := nudge + att * MapCheck.MULLIGAN_COST
		var res := MapCheck.resolve(c, ctx, map_seed, node_id, i, att, {"nudge": nudge})
		var toast := ("✓ %d%% — " % int(res["p"]) if bool(res["success"]) \
			else "✗ rolled %d vs %d%% — " % [int(res["roll"]), int(res["p"])]) + String(res["result"])
		return {"accept": true, "is_check": true, "fx": res["fx"], "toast": toast,
			"entropy_after": maxi(0, entropy_have - spend), "success": bool(res["success"]),
			"p": int(res["p"]), "roll": int(res["roll"]), "nudge": nudge,
			"goto": String(res.get("goto", ""))}          # a check leg may fail-forward
	var fx: Dictionary = (c.get("fx", {}) as Dictionary).duplicate()
	# a free/branch choice's next stage: `branch` (kind branch) or `goto` (free)
	return {"accept": true, "is_check": false, "fx": fx, "toast": String(fx.get("result", "")),
		"entropy_after": entropy_have, "success": true,
		"goto": String(c.get("branch", String(c.get("goto", ""))))}

## Candidate seats a check can be attempted by — every seat in the descent, in the
## canonical tank→blade→caster→healer order (stable across machines).
func _candidate_seats(room: Dictionary) -> Array:
	var cfg: Dictionary = room.get("seat_cfg", {})
	var out: Array = []
	for st in RaidNet.SEAT_KEYS:
		if cfg.has(st):
			out.append(st)
	return out

## One choice's per-seat metadata: gate state, and (for a check) the % / breakdown /
## ⚡ ladder as that seat's build reads it.
func _choice_meta_for(c: Dictionary, ctx: Dictionary) -> Dictionary:
	var m := {}
	var gate: Dictionary = c.get("gate", {})
	if not gate.is_empty() and not MapCheck.gate_ok(gate, ctx):
		m["gated"] = true
		m["locked_reason"] = MapCheck.gate_reason(gate)
		return m
	if MapCheck.check_like(String(c.get("kind", ""))):
		var info := MapCheck.chance(c.get("check", {}), ctx)
		m["chance"] = int(info["p"])
		m["breakdown"] = info["parts"]
		m["ladder"] = MapCheck.nudge_ladder(c.get("check", {}), ctx)
	return m

## The seat the UI suggests: the one whose build gives the highest total check % (the
## "specialist"). Ties break by seat order. No checks ⇒ the leader.
static func _suggest_seat(seats: Array, choices: Array) -> String:
	var best := ""
	var best_score := -1
	for st in seats:
		var score := 0
		for c in choices:
			if String((c as Dictionary).get("kind", "")) == "check":
				score += int(((c["by_seat"] as Dictionary).get(st, {}) as Dictionary).get("chance", 0))
		if score > best_score:
			best_score = score
			best = String(st)
	return best if best != "" else (String(seats[0]) if not seats.is_empty() else "tank")

## The seat that owns the route (the acting seat for checks, MVP).
func _leader_seat(room: Dictionary) -> String:
	var host = room.get("host", -1)
	var pl: Dictionary = (room.get("players", {}) as Dictionary).get(host, {})
	return String(pl.get("seat", "tank"))

## The build ctx an Inference Check reads for a seat, server-side: its drafted boons
## (resolved to synergy tags via the class module), aspect, role, party integrity, the
## server-owned ⚡ Entropy pool, comeback pity, inventory + flags.
func _map_ctx_srv(room: Dictionary, seat: String) -> Dictionary:
	var cp: Dictionary = room["campaign"]
	var cfg: Dictionary = (room.get("seat_cfg", {}) as Dictionary).get(seat, {})
	var aspect := String(cfg.get("aspect", ""))
	var cls := String(SEAT_CLASS.get(seat, String(cfg.get("cls", "mender"))))
	var boons: Dictionary = (cp.get("boons", {}) as Dictionary).get(seat, {})
	var boon_tags := MapCheck.tags_for_boons(MapCheck.catalog_for(cls), aspect, boons)
	return MapCheck.build_ctx(boon_tags, [], aspect, seat,
		_avg_frac_srv(cp["fracs"]), int(cfg.get("prior", 0)), int(cp["entropy"]),
		int(cp["check_fails"]), cp["inv"], cp["flags"], 0)

const SEAT_CLASS := {"tank": "bulwark", "blade": "twinfang", "caster": "voidcaller"}

func _avg_frac_srv(fracs: Array) -> float:
	if fracs.is_empty():
		return 1.0
	var t := 0.0
	for f in fracs:
		t += float(f)
	return t / float(fracs.size())

## A fight node: fold the carried campaign state into the spec and PULL, identically
## to a single-Seal fight — the lockstep replicas build the same carried opening.
func _launch_map_fight_srv(room: Dictionary, fi: int) -> void:
	var cp: Dictionary = room["campaign"]
	var fights: Array = cp["fights"]
	var enc: EncounterRes = fights[clampi(fi, 0, fights.size() - 1)]
	var carry := {"fracs": (cp["fracs"] as Array).duplicate(),
		"wounds": (cp["wounds"] as Array).duplicate(), "mana": float(cp["mana"])}
	var spec := RaidNet.make_spec(randi() & 0x7FFFFFFF, room["seat_cfg"], String(enc.id),
		carry, cp["boons"])                         # online boons ride the spec, per seat
	room["spec"] = spec
	room["spec"] = spec
	room["state"] = RaidNet.build(spec, "")
	room["phase"] = "fight"
	room["accum"] = 0.0
	room["pending"] = {}
	room["pending_ai"] = []
	for pid in room["players"]:
		_send(pid, {"t": "start", "spec": spec, "you": String(room["players"][pid]["seat"])})
	_log("room %s map-fight PULL: %s (seed %d)" % [room["code"], enc.id, int(spec["seed"])])

func _broadcast_map(room: Dictionary) -> void:
	var cp: Dictionary = room["campaign"]
	var m: RunMap = cp["map"]
	var fl: Dictionary = RaidContent.FLOORS[int(cp["floor"])]
	var titles: Array = []
	for tid in cp["tickets"]:
		titles.append(String(cp["tickets"][tid]))
	_broadcast(room, {"t": "map", "code": room["code"], "host": room["host"],
		"seed": int(cp["map_seed"]),                # lets clients seed their boon-draft run
		"floor": int(cp["floor"]), "ring": int(fl["ring"]), "title": String(fl["title"]),
		"map": m.to_dict(), "node": int(cp["node"]), "inv": cp["inv"],
		"fracs": cp["fracs"], "wounds": cp["wounds"], "mana": float(cp["mana"]),
		"tickets": titles, "closed": int(cp["closed"]), "total": int(cp["total"]),
		"entropy": int(cp["entropy"]),              # ⚡ the within-run luck pool (server-owned)
		"toast": String(cp["toast"])})

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
			"aspect": pl["aspect"], "cls": pl.get("cls", ""), "ready": pl["ready"]})
	_broadcast(room, {"t": "room", "code": room["code"], "phase": room["phase"],
		"host": room["host"], "enc": String(room["enc"]), "players": players})
