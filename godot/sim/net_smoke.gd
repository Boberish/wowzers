## End-to-end NETCODE smoke (R2): ONE headless process runs the real NetServer and
## TWO real WebSocket clients over loopback at accelerated time-scale.
##   Fight 1: human tank (Ava) + human healer (Bo, brinkwarden) + 2 AI — full fight,
##            assert zero desyncs and both replicas at the server outcome.
##   Fight 2: Bo hard-disconnects mid-fight — server swaps the seat to AI in-frame;
##            Ava's replica must run clean to the end.
##
##   godot --headless --path godot --script res://sim/net_smoke.gd
extends SceneTree

const PORT := 9177

var server: NetServer
var ava := {}     # {net, ctrl, state, last_in, ended, won, desync, room_n}
var bo := {}
var phase := "boot"
var t := 0.0
var fight_n := 0
var failed := false

func _initialize() -> void:
	server = NetServer.new()
	server.port = PORT
	server.time_scale = 5.0
	server.log_line.connect(func(m): print(m))
	root.add_child(server)
	if server.start() != OK:
		_fail("server bind failed")
	ava = _client("Ava")
	bo = _client("Bo")

func _client(pname: String) -> Dictionary:
	var c := {"name": pname, "net": NetClient.new(), "ctrl": NetCombatController.new(),
		"connected": false, "room": {}, "spec": {}, "you": "", "ended": false,
		"won": false, "desync": false, "last_in": 0, "errs": []}
	var net: NetClient = c["net"]
	var ctrl: NetCombatController = c["ctrl"]
	root.add_child(net)
	root.add_child(ctrl)
	net.controller = ctrl
	ctrl.client = net
	net.connected.connect(func(): c["connected"] = true)
	net.net_error.connect(func(m): c["errs"].append(m); print("[%s] err: %s" % [pname, m]))
	net.room_update.connect(func(r): c["room"] = r)
	net.desynced.connect(func(): c["desync"] = true)
	net.fight_started.connect(func(spec, you):
		c["spec"] = spec
		c["you"] = you
		c["ended"] = false
		c["last_in"] = 0
		var st := RaidNet.build(spec, you)
		ctrl.set_spec_seed(int(spec.get("seed", 1)))
		ctrl.begin_net(st, RaidNet.SEAT_KEYS.find(you))
		print("[%s] fight started: seat %s" % [pname, you]))
	ctrl.encounter_ended.connect(func(won): c["ended"] = true; c["won"] = won)
	net.connect_to("ws://127.0.0.1:%d" % PORT, pname, "TEST")
	return c

func _fail(msg: String) -> void:
	failed = true
	print("NET SMOKE FAIL: ", msg)
	quit(1)

func _process(delta: float) -> bool:
	if failed:
		return true
	t += delta
	if t > 240.0:
		_fail("timeout in phase " + phase)
		return true
	match phase:
		"boot":
			if ava["connected"] and bo["connected"] \
					and (ava["room"].get("players", []) as Array).size() == 2:
				print("both clients in room: ok")
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
				fight_n = 1
				_host().send({"t": "start"})
				phase = "fight1"
		"fight1":
			_drive(ava, "tank")
			_drive(bo, "healer")
			if ava["desync"] or bo["desync"]:
				_fail("desync in fight 1")
			elif ava["ended"] and bo["ended"]:
				var ca: CombatState = (ava["ctrl"] as NetCombatController).state
				var cb: CombatState = (bo["ctrl"] as NetCombatController).state
				print("fight 1 done: Ava %s cs=%d tick=%d | Bo %s cs=%d tick=%d" % [
					str(ava["won"]), ca.checksum, ca.tick, str(bo["won"]), cb.checksum, cb.tick])
				if ca.checksum != cb.checksum or ava["won"] != bo["won"]:
					_fail("replica mismatch after fight 1")
				else:
					print("replicas agree: ok — re-readying for the takeover test")
					ava["net"].send({"t": "ready", "on": true})
					bo["net"].send({"t": "ready", "on": true})
					phase = "ready2"
		"ready2":
			if _ready_of(ava, "Ava") and _ready_of(bo, "Bo"):
				fight_n = 2
				# the takeover test needs Bo droppable: if Bo is host, dropping him is
				# also fine (host migrates), but start must come from the CURRENT host
				_host().send({"t": "start"})
				phase = "fight2"
		"fight2":
			_drive(ava, "tank")
			var bstate: CombatState = (bo["ctrl"] as NetCombatController).state
			if bstate != null and bstate.tick > 200 and not bo["ctrl"].running:
				pass
			elif bstate != null and bstate.tick > 200:
				print("[Bo] hard-disconnecting at tick %d — AI takeover expected" % bstate.tick)
				(bo["net"] as NetClient).close("test drop")
				bo["ctrl"].running = false
			if ava["desync"]:
				_fail("desync in fight 2 (post-takeover)")
			elif ava["ended"]:
				var ca2: CombatState = (ava["ctrl"] as NetCombatController).state
				print("fight 2 done after takeover: Ava %s tick=%d cs=%d" % [
					str(ava["won"]), ca2.tick, ca2.checksum])
				print("NET SMOKE: ALL OK")
				quit()
				return true
	return false

func _host() -> NetClient:
	var host_id := int(ava["room"].get("host", -1))
	if (ava["net"] as NetClient).peer_id() == host_id:
		return ava["net"]
	return bo["net"]

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

## Scripted human play against the client's own replica (inputs go over the wire).
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
