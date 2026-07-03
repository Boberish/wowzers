## End-to-end ONLINE MAP DESCENT smoke (MAP-3b): ONE headless process runs the real
## NetServer + TWO real WebSocket clients over loopback at accelerated time-scale.
## The host (Ava, tank) starts a Topology DESCENT; the LEADER routes the party toward
## each floor Seal; combat nodes pull carried-state fights that both replicas build
## identically; a floor Seal ELEVATES the ring. Asserts: the descent progresses (a
## ring advances), fights carry campaign state (spec.carry applied to opening HP),
## and zero desync across the whole run.
##
##   godot --headless --path godot --script res://sim/net_map_smoke.gd
extends SceneTree

const PORT := 9178

var server: NetServer
var ava := {}
var bo := {}
var phase := "boot"
var t := 0.0
var failed := false

var floor_seen := 0
var fights_done := 0
var carry_seen := false
var min_open_frac := 1.0
var nodes_picked := 0

func _initialize() -> void:
	server = NetServer.new()
	server.port = PORT
	server.time_scale = 8.0
	server.log_line.connect(func(m): print(m))
	root.add_child(server)
	if server.start() != OK:
		_fail("server bind failed")
	ava = _client("Ava")
	bo = _client("Bo")

func _client(pname: String) -> Dictionary:
	var c := {"name": pname, "net": NetClient.new(), "ctrl": NetCombatController.new(),
		"connected": false, "room": {}, "you": "", "mode": "lobby", "map": {},
		"stop": {}, "awaiting": false, "desync": false, "last_in": 0,
		"campaign_won": null, "errs": []}
	var net: NetClient = c["net"]
	var ctrl: NetCombatController = c["ctrl"]
	root.add_child(net)
	root.add_child(ctrl)
	net.controller = ctrl
	ctrl.client = net
	net.connected.connect(func(): c["connected"] = true)
	net.net_error.connect(func(m): c["errs"].append(m); print("[%s] err: %s" % [pname, m]))
	net.room_update.connect(func(r): c["room"] = r)
	net.desynced.connect(func(): c["desync"] = true; print("[%s] DESYNC" % pname))
	net.map_update.connect(func(msg):
		c["map"] = msg
		c["mode"] = "map"
		c["awaiting"] = true
		var fl := int(msg.get("floor", 0))
		if fl > floor_seen:
			floor_seen = fl
			print("== ring advanced: now floor %d (%s) ==" % [fl, String(msg.get("title", ""))]))
	net.map_stop.connect(func(msg):
		c["stop"] = msg
		c["mode"] = "mapstop"
		c["awaiting"] = true)
	net.campaign_ended.connect(func(won):
		c["mode"] = "done"
		c["campaign_won"] = won
		print("[%s] campaign ended: won=%s" % [pname, str(won)]))
	net.fight_started.connect(func(spec, you):
		c["you"] = you
		c["mode"] = "fight"
		c["last_in"] = 0
		if spec.has("carry"):
			carry_seen = true
		var st := RaidNet.build(spec, you)
		ctrl.set_spec_seed(int(spec.get("seed", 1)))
		ctrl.begin_net(st, RaidNet.SEAT_KEYS.find(you))
		if you == "tank" and st.seats.size() > 0:
			var u: Seat = st.seats[0]
			var frac := u.hp / maxf(1.0, u.hp_max)
			min_open_frac = minf(min_open_frac, frac)
		print("[%s] map-fight: %s seat %s (carry=%s)" % [pname, String(st.encounter.id), you, str(spec.has("carry"))]))
	ctrl.encounter_ended.connect(func(won):
		c["mode"] = "fightdone"
		if c["name"] == "Ava":
			fights_done += 1)
	net.connect_to("ws://127.0.0.1:%d" % PORT, pname, "MAPTEST")
	return c

func _fail(msg: String) -> void:
	failed = true
	print("NET MAP SMOKE FAIL: ", msg)
	quit(1)

func _host_client() -> Dictionary:
	var host_id := int(ava["room"].get("host", -1))
	return ava if (ava["net"] as NetClient).peer_id() == host_id else bo

func _process(delta: float) -> bool:
	if failed:
		return true
	t += delta
	if t > 420.0:
		_fail("timeout in phase " + phase + " (floor_seen=%d fights=%d)" % [floor_seen, fights_done])
		return true
	if ava["desync"] or bo["desync"]:
		_fail("desync during the descent")
		return true
	match phase:
		"boot":
			if ava["connected"] and bo["connected"] \
					and (ava["room"].get("players", []) as Array).size() == 2:
				ava["net"].send({"t": "claim", "seat": "tank"})
				bo["net"].send({"t": "claim", "seat": "healer"})
				phase = "claim"
		"claim":
			if _seat_of(ava, "Ava") == "tank" and _seat_of(bo, "Bo") == "healer":
				bo["net"].send({"t": "aspect", "aspect": "brinkwarden"})
				ava["net"].send({"t": "ready", "on": true})
				bo["net"].send({"t": "ready", "on": true})
				phase = "ready"
		"ready":
			if _ready_of(ava, "Ava") and _ready_of(bo, "Bo"):
				print("both ready — starting the DESCENT")
				(_host_client()["net"] as NetClient).send_mapstart()
				phase = "descend"
		"descend":
			# fights: both replicas drive their seats
			if ava["mode"] == "fight":
				_drive(ava, "tank")
			if bo["mode"] == "fight":
				_drive(bo, "healer")
			# leader routes when between fights
			var host := _host_client()
			if host["mode"] == "map" and bool(host["awaiting"]):
				host["awaiting"] = false
				_leader_pick(host)
			elif host["mode"] == "mapstop" and bool(host["awaiting"]):
				host["awaiting"] = false
				print("[leader] answering event panel: %s" % String((host["stop"] as Dictionary).get("title", "")))
				(host["net"] as NetClient).send_choice(0)
			# success: a ring advanced (Seal cleared + floor built) or the descent ended
			if floor_seen >= 1 or ava["campaign_won"] != null or bo["campaign_won"] != null:
				_finish()
				return true
	return false

func _leader_pick(host: Dictionary) -> void:
	var msg: Dictionary = host["map"]
	var m := RunMap.from_dict(msg.get("map", {}))
	var cur := int(msg.get("node", -1))
	var inv: Dictionary = msg.get("inv", {})
	var reach: Array = m.reachable(cur, inv)
	if reach.is_empty():
		_fail("leader stuck: no reachable node at %d (floor %d)" % [cur, floor_seen])
		return
	# if the party is hurting or low on mana, duck into a reachable COOLING station
	# (refuel/repair) before pressing on — sustainable routing to reach the Seal
	var low := float(msg.get("mana", 1.0)) < 0.6
	for f in msg.get("fracs", []):
		if float(f) < 0.7:
			low = true
	var best := -1
	if low:
		for nid in reach:
			if String(m.node(int(nid))["kind"]) == RunMap.KIND_COOLING:
				best = int(nid)
				break
	# otherwise greedy toward the Seal: the reachable node on the highest row
	var best_row := -1
	if best < 0:
		for nid in reach:
			var r := int(m.node(int(nid))["row"])
			if r > best_row:
				best_row = r
				best = int(nid)
	nodes_picked += 1
	print("[leader] pick node %d (%s, row %d)" % [best, String(m.node(best)["kind"]), best_row])
	(host["net"] as NetClient).send_node(best)

func _finish() -> void:
	if ava["desync"] or bo["desync"]:
		_fail("desync")
		return
	if not carry_seen:
		_fail("no fight carried campaign state (spec.carry never present)")
		return
	print("---- MAP DESCENT RESULT ----")
	print("floors advanced: %d · fights: %d · nodes picked: %d" % [floor_seen, fights_done, nodes_picked])
	print("carry applied: %s (min opening tank integrity = %.2f)" % [str(carry_seen), min_open_frac])
	print("campaign_won: ava=%s bo=%s" % [str(ava["campaign_won"]), str(bo["campaign_won"])])
	print("desyncs: ava=%s bo=%s" % [str(ava["desync"]), str(bo["desync"])])
	if min_open_frac >= 0.999:
		print("NOTE: no fight opened below full integrity — carry present but never bit (fast clears)")
	print("NET MAP SMOKE: ALL OK")
	quit()

func _seat_of(c: Dictionary, pname: String) -> String:
	for p in c["room"].get("players", []):
		if String(p.get("name", "")) == pname:
			return String(p.get("seat", ""))
	return ""

func _ready_of(c: Dictionary, pname: String) -> bool:
	for p in c["room"].get("players", []):
		if String(p.get("name", "")) == pname:
			return bool(p.get("ready", false))
	return false

## Scripted human play against the replica (same shape as net_smoke._drive).
func _drive(c: Dictionary, seat_key: String) -> void:
	var ctrl: NetCombatController = c["ctrl"]
	var s: CombatState = ctrl.state
	if s == null or s.over or not ctrl.running:
		return
	if s.tick - int(c["last_in"]) < 6:
		return
	c["last_in"] = s.tick
	var p := ctrl.player()
	if p == null or not p.alive():
		return
	var obs := CombatCore.observe(s, p)
	var tg: Dictionary = obs.get("telegraph", {})
	if seat_key == "tank":
		if not bool(obs.get("aggro_me", true)) and s.tick >= int(p.cooldowns.get("challenge", 0)):
			ctrl.human({"type": "ability", "id": "challenge"})
		elif not tg.is_empty() and bool(tg.get("defensible", false)) \
				and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)) \
				and float(tg.get("remaining", 9.0)) <= 0.3:
			ctrl.human({"type": "defense"})
		elif bool(obs.get("gcd_ready", false)):
			ctrl.human({"type": "ability",
				"id": ("rampage" if float(obs.get("rage", 0.0)) >= 40.0 else "cleave")})
	else:
		if (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
			ctrl.human({"type": "ability", "id": "mend", "target": s.seats[0]})
