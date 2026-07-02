## Headless scripted ONLINE client (R2 tooling): connects to a live server, claims a
## seat, readies, pulls (if host), plays the fight with the scripted brain, prints
## the outcome + checksum, exits. Two of these against one server = an automated
## cross-machine (or cross-OS) lockstep test.
##
##   godot --headless --path godot --script res://sim/net_probe.gd -- \
##       --url=ws://127.0.0.1:9077 --room=PROBE --seat=tank --name=WinTank
extends SceneTree

var net: NetClient
var ctrl: NetCombatController
var seat := "tank"
var started := false
var ended := false
var desync := false
var last_in := 0
var t := 0.0

func _initialize() -> void:
	seat = _arg("seat", "tank")
	net = NetClient.new()
	ctrl = NetCombatController.new()
	root.add_child(net)
	root.add_child(ctrl)
	net.controller = ctrl
	ctrl.client = net
	net.connected.connect(func(): print("[probe %s] connected" % seat))
	net.net_error.connect(func(m): print("[probe %s] err: %s" % [seat, m]))
	net.desynced.connect(func(): desync = true)
	net.room_update.connect(_on_room)
	net.fight_started.connect(_on_start)
	ctrl.encounter_ended.connect(func(_w): ended = true)
	net.connect_to(_arg("url", "ws://127.0.0.1:%d" % NetProtocol.DEFAULT_PORT),
		_arg("name", "Probe-" + seat), _arg("room", "PROBE"))

func _on_room(room: Dictionary) -> void:
	var me := {}
	var others_ready := true
	var count := 0
	for p in room.get("players", []):
		count += 1
		if int(p.get("id", -1)) == net.peer_id():
			me = p
		elif not bool(p.get("ready", false)):
			others_ready = false
	if String(me.get("seat", "")) == "":
		net.send({"t": "claim", "seat": seat})
	elif not bool(me.get("ready", false)):
		net.send({"t": "ready", "on": true})
	elif count >= 2 and others_ready and int(room.get("host", -1)) == net.peer_id() and not started:
		print("[probe %s] host pulling with %d players" % [seat, count])
		net.send({"t": "start"})

func _on_start(spec: Dictionary, you: String) -> void:
	started = true
	var st := RaidNet.build(spec, you)
	ctrl.set_spec_seed(int(spec.get("seed", 1)))
	ctrl.begin_net(st, RaidNet.SEAT_KEYS.find(you))
	print("[probe %s] fight started (seed %d)" % [seat, int(spec.get("seed", 1))])

func _process(delta: float) -> bool:
	t += delta
	if t > 300.0:
		print("PROBE RESULT seat=%s TIMEOUT" % seat)
		quit(1)
		return true
	if desync:
		print("PROBE RESULT seat=%s DESYNC at tick %d" % [seat, ctrl.state.tick if ctrl.state else -1])
		quit(1)
		return true
	if ended:
		var s := ctrl.state
		print("PROBE RESULT seat=%s won=%s tick=%d cs=%d" % [seat, str(s.won), s.tick, s.checksum])
		quit()
		return true
	_drive()
	return false

## The scripted brain (same shapes the smokes use), generic across seats.
func _drive() -> void:
	var s := ctrl.state
	if s == null or s.over or not ctrl.running:
		return
	if s.tick - last_in < 6:
		return
	last_in = s.tick
	var p := ctrl.player()
	if p == null or not p.alive():
		return
	var obs := CombatCore.observe(s, p)
	var tg: Dictionary = obs.get("telegraph", {})
	match seat:
		"tank":
			if not bool(obs.get("aggro_me", true)) and s.tick >= int(p.cooldowns.get("challenge", 0)):
				ctrl.human({"type": "ability", "id": "challenge"})
			elif not tg.is_empty() and bool(tg.get("defensible", false)) \
					and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)) \
					and float(tg.get("remaining", 9.0)) <= 0.3:
				ctrl.human({"type": "defense"})
			elif bool(obs.get("gcd_ready", false)):
				ctrl.human({"type": "ability",
					"id": ("rampage" if float(obs.get("rage", 0.0)) >= 40.0 else "cleave")})
		"healer":
			if (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
				ctrl.human({"type": "ability", "id": "mend", "target": s.seats[0]})
		"blade":
			if int(obs.get("since_strike", 0)) >= int(obs.get("perfect_lo", 18)):
				ctrl.human({"type": "ability", "id": "strike"})
		"caster":
			if not tg.is_empty() and bool(tg.get("interruptible", false)) and bool(obs.get("defense_ready", false)):
				ctrl.human({"type": "defense"})
			elif (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
				ctrl.human({"type": "ability",
					"id": ("fracture" if float(obs.get("focus", 0.0)) >= 26.0 else "bolt")})

func _arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def
