## Raid HUD (R1 v2 — see RAID-PLAN.md) — THE RIFT: pick ANY of the four seats and
## play it live with three AI raiders. Each seat gets its faithful class band
## (Bulwark orbs/spec/Challenge · Twinfang rhythm/Flow · Voidcaller cast-bar/kick
## · Mender click-cast triage), around a shared raid grammar: boss plate + dial,
## reliquary party frames (gold-lit = the boss's current victim), aggro banners.
## Screens: seat/boss select -> Combat -> End. Single Seal, no draft.
extends Control

const SEAT_IDX := {"tank": 0, "blade": 1, "caster": 2, "healer": 3}
const SEAT_NAMES := {"tank": "THE BULWARK", "blade": "THE TWINFANG", "caster": "THE VOIDCALLER", "healer": "THE MENDER"}
const ALLY_LATENCY := 5            ## AI raiders play at "good-ish" (ticks of reaction)

## Both aspects per seat (v3): the pick-2 ceremony after choosing your seat.
static var ASPECTS := {
	"tank": [
		{"id": "warden", "name": "WARDEN", "accent": Palette.STEEL, "icon": "guard",
			"desc": "Parry swings in their window — reflect, bank Counter, punish with Vindicate. Read the swing; punish it."},
		{"id": "juggernaut", "name": "JUGGERNAUT", "accent": Palette.MOMENTUM, "icon": "avalanche",
			"desc": "Eat hits for Momentum: more damage AND mitigation. Dodge only what you must; cash out with Avalanche."},
	],
	"blade": [
		{"id": "tempo", "name": "TEMPO", "accent": Palette.FLOW, "icon": "flurry",
			"desc": "Chain Perfect Strikes — Flow tiers transform your kit, ending in Coup de Grâce at max Flow."},
		{"id": "venomancer", "name": "VENOMANCER", "accent": Palette.POISON, "icon": "envenom",
			"desc": "Keep three poisons alive, ramp Toxic Synergy, detonate the fat cocktail with Rupture."},
	],
	"caster": [
		{"id": "disruptor", "name": "DISRUPTOR", "accent": Palette.KICK, "icon": "overload",
			"desc": "Clean kicks bank Backlash — Overload it into instant, empowered Fractures. Race the Chant."},
		{"id": "silencer", "name": "SILENCER", "accent": Palette.VOID, "icon": "silence",
			"desc": "Kicks Silence and Expose — lock the boss out of its own spellbook. The control fantasy."},
	],
	"healer": [
		{"id": "tidecaller", "name": "TIDECALLER", "accent": Palette.STEEL, "icon": "surge",
			"desc": "Play AHEAD: overheal banks the Reservoir; Surge it into raid-wide shields before the spike."},
		{"id": "brinkwarden", "name": "BRINKWARDEN", "accent": Palette.MOMENTUM, "icon": "laststand",
			"desc": "Play the BRINK: heals on the dying hit harder and cost less, and bloodied allies deal MORE damage."},
	],
}

const ABILITY_NAMES := {
	"cleave": "Cleave", "rampage": "Rampage", "fortify": "Fortify", "vindicate": "Vindicate",
	"strike": "Strike", "eviscerate": "Eviscerate", "kick": "Kick", "envenom": "Envenom",
	"coupdegrace": "Coup", "rupture": "Rupture", "flurry": "Flurry",
	"bolt": "Bolt", "fracture": "Fracture", "barrier": "Barrier", "overload": "Overload",
	"quietus": "Quietus", "silence": "Silence", "counterspell": "Counterspell",
}

var _ctrl: CombatController
var _local_ctrl: CombatController
var _net_ctrl: NetCombatController
var _net: NetClient = null
var _online: bool = false
var _room: Dictionary = {}
var _my_ready: bool = false
var _net_status: Label = null
var _seat_key: String = "tank"
var _aspect: String = "warden"
var _enc_id: String = "riftmaw"    ## the Seal to pull offline (boss-select / autostart)
var _loadout: Array = []
var _screen: String = "select"

# Topology raid floor (MAP-3a, offline): map-run state lives HERE, not in RunState —
# the raid never uses the solo run machinery (and draft2 owns run_state.gd right now).
var _map: RunMap = null
var _map_node: int = -1
var _map_inv: Dictionary = {}
var _map_fracs: Array = [1.0, 1.0, 1.0, 1.0]   ## per-seat persistent integrity
var _map_wounds: Array = [0.0, 0.0, 0.0, 0.0]  ## CORRUPTED SECTORS: max-HP cut a heal can't fix
var _map_mana: float = 1.0         ## the healer's mana ALSO carries — the raid's fuel gauge
var _map_fights: Array = []        ## Array[EncounterRes], indexed by node "fight"
var _map_pending := false          ## TOPOLOGY picked on the select — map starts after aspect pick

var _stage: StageBackdrop
var _stage2d: RaidStage2D = null
var _ui: Control
var _fx: Control

# shared combat widgets
var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _recap_stats := {}          # view-side fight tallies for THE RECKONING
var _frames: Array = []            ## [{seat, frame}]
var _aggro_warn: Label
var _shake_root: Control
var _shake_amt: float = 0.0

# class-band widgets (only the active seat's set is built)
var _hp_orb: LiquidOrb
var _res_orb: LiquidOrb            ## rage / energy / focus / mana
var _runes: Array = []
var _rune_ids: Array = []
var _guard: AbilityRune
var _challenge: AbilityRune        ## tank only
var _spec: SpecGauge               ## tank
var _tf_gauge: TwinfangGauge       ## blade
var _rhythm: RhythmBar             ## blade
var _strike_idx: int = -1
var _vc_gauge: VoidcallerGauge     ## caster
var _pcast: PlayerCastBar          ## caster
var _spec_strip: SpecStrip         ## healer
var _castbar: CastChannel          ## healer
var _mcfg: MenderConfig            ## healer
var _binds: Dictionary = {}        ## healer mouse chords
var _hover_seat: Seat = null
var _focus_seat: Seat = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	seed(Time.get_ticks_usec())
	set_theme(UiKit.build_theme())
	_stage = StageBackdrop.new()
	add_child(_stage)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)
	_local_ctrl = CombatController.new()
	add_child(_local_ctrl)
	_local_ctrl.encounter_ended.connect(_on_end)
	_net_ctrl = NetCombatController.new()
	add_child(_net_ctrl)
	_net_ctrl.encounter_ended.connect(_on_end)
	_ctrl = _local_ctrl
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart=raidmap"):
			# --autostart=raidmap[:seat[:aspect]]  → straight onto the Topology floor
			var mspec := a.substr("--autostart=".length()).split(":")
			_seat_key = mspec[1] if mspec.size() > 1 and SEAT_IDX.has(mspec[1]) else "tank"
			_aspect = mspec[2] if mspec.size() > 2 else String((ASPECTS[_seat_key][0] as Dictionary)["id"])
			_start_map_run()
		elif a.begins_with("--autostart=raid"):
			# --autostart=raid[:seat[:aspect[:boss]]]  e.g. raid:blade:tempo:mythos
			var spec := a.substr("--autostart=".length()).split(":")
			var seat := spec[1] if spec.size() > 1 else "tank"
			var aspect := spec[2] if spec.size() > 2 else ""
			var enc := spec[3] if spec.size() > 3 else ""
			_launch(seat, aspect, enc)

func _clear() -> void:
	TransitionVeil.flash_on(self)   # screens settle in, never snap
	_hover_seat = null
	_focus_seat = null
	_stage2d = null
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT
func _show_select(seat: String = "tank") -> void:
	_screen = "select"
	_map = null                       # leaving for the select abandons any map run
	_map_pending = false
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE RIFT"
	sel.subtitle = "RAID — FOUR SEATS, ONE SEAL · PICK YOURS, AI FILLS THE REST"
	sel.aspects = [
		{"id": "tank", "label": "THE BULWARK", "accent": Palette.STEEL,
			"blurb": "Tank · Warden or Juggernaut — hold its gaze, CHALLENGE it back"},
		{"id": "blade", "label": "THE TWINFANG", "accent": Palette.FLOW,
			"blurb": "Melee · Tempo or Venomancer — don't out-threat the tank"},
		{"id": "caster", "label": "THE VOIDCALLER", "accent": Palette.KICK,
			"blurb": "Caster · Disruptor or Silencer — kick the Devouring Chant"},
		{"id": "healer", "label": "THE MENDER", "accent": Palette.WIN,
			"blurb": "Healer · Tidecaller or Brinkwarden — four lives through the storm"},
	]
	sel.encounters = RaidContent.run_encounters()
	sel.current = seat
	sel.hint = "Pick a Seal: Vorathek is the classic pull; II–IV are the Machine Seals (they escalate). Every seat: F = dodge combo beats · Esc = menu. Seat verbs: SPACE = parry / dodge / KICK · Mender click-casts the frames."
	sel.extras = [
		{"label": "THE TOPOLOGY — RING 3 raid floor (map run: Vorathek gate → MISTRAL-7B)",
			"cb": func(): _start_map_pick(sel.current)},
		{"label": "🌐  PLAY ONLINE (live co-op)", "cb": _show_online},
	]
	sel.chosen.connect(_start_raid)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ ASPECT PICK
## BossSelect chose a seat (+ optionally a Seal) — now the Aspect ceremony.
func _start_raid(seat_id: String, jump_to: String = "") -> void:
	_map_pending = false
	_enc_id = jump_to if jump_to != "" else "riftmaw"
	_show_aspect_pick(seat_id if SEAT_IDX.has(seat_id) else "tank")

## TOPOLOGY entry: same seat → aspect ceremony, but the pull lands on the map.
func _start_map_pick(seat_id: String) -> void:
	_map_pending = true
	_show_aspect_pick(seat_id if SEAT_IDX.has(seat_id) else "tank")

func _show_aspect_pick(seat_id: String) -> void:
	_screen = "aspect"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -420, 150, 420, 260)
	_ui.add_child(head)
	var hl := _title(head, SEAT_NAMES[seat_id], 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "C H O O S E   Y O U R   A S P E C T", 15, Palette.TEXT_DIM)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	_place(box, 0.5, 0.5, 0.5, 0.5, -340, -130, 340, 130)
	_ui.add_child(box)
	for a in ASPECTS[seat_id]:
		var card := AspectCard.new(String(a["name"]), String(a["desc"]), a["accent"], String(a["icon"]))
		card.chosen.connect(_launch.bind(seat_id, String(a["id"])))
		box.add_child(card)

	var back := Button.new()
	back.text = "◂ back to seats"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(back, 0.5, 1, 0.5, 1, -110, -90, 110, -56)
	back.pressed.connect(func(): _show_select(seat_id))
	_ui.add_child(back)

# ============================================================ ONLINE (R2)
func _ensure_net() -> void:
	if _net != null:
		return
	_net = NetClient.new()
	add_child(_net)
	_net.controller = _net_ctrl
	_net_ctrl.client = _net
	_net.connected.connect(func(): _set_net_status("joined — waiting for the room…"))
	_net.net_error.connect(func(m): _set_net_status("✗ " + m))
	_net.disconnected.connect(_on_net_dropped)
	_net.room_update.connect(_on_room)
	_net.fight_started.connect(_launch_online)
	_net.fight_ended.connect(_on_net_fight_ended)
	_net.desynced.connect(_on_desync)

func _set_net_status(m: String) -> void:
	if _net_status != null and is_instance_valid(_net_status):
		_net_status.text = m

func _show_online() -> void:
	_ensure_net()
	_online = true
	_screen = "netconnect"
	_clear()
	var cfg := NetClient.load_cfg()
	var url := String(cfg.get("url", ""))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			url = a.substr("--server=".length())
	if url == "":
		if OS.has_feature("web"):
			# browser build: default to the host that served this page (ws on http,
			# wss on https) — a sent link "just works" when one box runs both
			var host := str(JavaScriptBridge.eval("window.location.hostname", true))
			var scheme := "wss" if str(JavaScriptBridge.eval("window.location.protocol", true)) == "https:" else "ws"
			url = "%s://%s:%d" % [scheme, host, NetProtocol.DEFAULT_PORT]
		else:
			url = "ws://127.0.0.1:%d" % NetProtocol.DEFAULT_PORT
	var pname := String(cfg.get("name", ""))
	if pname == "":
		pname = "Raider%d" % (randi() % 1000)
	var room := String(cfg.get("room", NetProtocol.DEFAULT_ROOM))

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	_place(box, 0.5, 0.5, 0.5, 0.5, -260, -220, 260, 220)
	_ui.add_child(box)
	var hl := _title(box, "THE RIFT — ONLINE", 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(box, "Run the server (see server/README.md), share the address, pull together.", 13, Palette.TEXT_DIM)
	var name_edit := _edit(box, "your name", pname)
	var url_edit := _edit(box, "server (ws://host:port)", url)
	var room_edit := _edit(box, "room code", room)
	var go := Button.new()
	go.text = "CONNECT"
	go.custom_minimum_size = Vector2(240, 46)
	go.add_theme_font_size_override("font_size", 17)
	box.add_child(go)
	_net_status = _title(box, "", 13, Palette.TEXT_DIM)
	var back := Button.new()
	back.text = "◂ back"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	box.add_child(back)
	go.pressed.connect(func():
		var u := url_edit.text.strip_edges()
		var n := name_edit.text.strip_edges()
		var r := room_edit.text.strip_edges().to_upper()
		NetClient.save_cfg(u, n, r)
		_net.close()
		_set_net_status("connecting to %s …" % u)
		_net.connect_to(u, n, r))
	back.pressed.connect(func():
		_net.close()
		_online = false
		_show_select())

func _edit(parent: Node, placeholder: String, value: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = value
	e.custom_minimum_size = Vector2(420, 40)
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(e)
	return e

func _on_room(room: Dictionary) -> void:
	_room = room
	if _screen == "netconnect" or _screen == "lobby":
		_show_lobby()

func _me() -> Dictionary:
	for p in _room.get("players", []):
		if int(p.get("id", -1)) == _net.peer_id():
			return p
	return {}

func _show_lobby() -> void:
	_screen = "lobby"
	_clear()
	var me := _me()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	_place(box, 0.5, 0.5, 0.5, 0.5, -330, -280, 330, 280)
	_ui.add_child(box)
	var hl := _title(box, "ROOM  ·  %s" % String(_room.get("code", "")), 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(box, "claim a seat · pick your aspect · ready · the host pulls", 13, Palette.TEXT_DIM)

	for key in RaidNet.SEAT_KEYS:
		var claimant := {}
		for p in _room.get("players", []):
			if String(p.get("seat", "")) == key:
				claimant = p
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var lab := Label.new()
		var who := "— AI —"
		if not claimant.is_empty():
			who = String(claimant["name"]) + (" (YOU)" if claimant == me else "")
			who += "  ·  " + String(claimant.get("aspect", "")).capitalize()
			if bool(claimant.get("ready", false)):
				who += "  ✓"
		lab.text = "%-14s %s" % [SEAT_NAMES[key], who]
		lab.custom_minimum_size = Vector2(430, 34)
		lab.add_theme_font_size_override("font_size", 16)
		lab.add_theme_color_override("font_color",
			Palette.GOLD_BRIGHT if claimant == me and not claimant.is_empty() else Palette.TEXT)
		row.add_child(lab)
		if claimant.is_empty():
			var cb := Button.new()
			cb.text = "CLAIM"
			cb.custom_minimum_size = Vector2(110, 34)
			cb.pressed.connect(func(): _net.send({"t": "claim", "seat": key}))
			row.add_child(cb)
		elif claimant == me:
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 34)
			ab.pressed.connect(func():
				var pool: Array = ASPECTS[key]
				var cur := String(me.get("aspect", ""))
				var nxt := String(pool[0]["id"]) if cur == String(pool[1]["id"]) else String(pool[1]["id"])
				_net.send({"t": "aspect", "aspect": nxt}))
			row.add_child(ab)

	# The Seal for the next pull — everyone sees it; the host cycles it.
	var enc_id := String(_room.get("enc", "riftmaw"))
	var seals := RaidContent.run_encounters()
	var seal_name := enc_id
	var seal_i := 0
	for i in seals.size():
		if String((seals[i] as EncounterRes).id) == enc_id:
			seal_name = (seals[i] as EncounterRes).name
			seal_i = i
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 10)
	box.add_child(srow)
	var slab := Label.new()
	slab.text = "SEAL %s  ·  %s" % [["I", "II", "III", "IV"][mini(seal_i, 3)], seal_name]
	slab.custom_minimum_size = Vector2(430, 32)
	slab.add_theme_font_size_override("font_size", 15)
	slab.add_theme_color_override("font_color", Palette.GOLD)
	srow.add_child(slab)
	if int(_room.get("host", -1)) == _net.peer_id():
		var sb := Button.new()
		sb.text = "SEAL ⇄"
		sb.custom_minimum_size = Vector2(110, 32)
		sb.pressed.connect(func():
			var nxt: EncounterRes = seals[(seal_i + 1) % seals.size()]
			_net.send({"t": "boss", "enc": String(nxt.id)}))
		srow.add_child(sb)

	var ctlrow := HBoxContainer.new()
	ctlrow.alignment = BoxContainer.ALIGNMENT_CENTER
	ctlrow.add_theme_constant_override("separation", 16)
	box.add_child(ctlrow)
	_my_ready = bool(me.get("ready", false))
	var rb := Button.new()
	rb.text = "READY  ✓" if _my_ready else "READY?"
	rb.custom_minimum_size = Vector2(150, 44)
	rb.pressed.connect(func(): _net.send({"t": "ready", "on": not _my_ready}))
	ctlrow.add_child(rb)
	if int(_room.get("host", -1)) == _net.peer_id():
		var pull := Button.new()
		pull.text = "⚔  PULL"
		pull.custom_minimum_size = Vector2(150, 44)
		pull.add_theme_font_size_override("font_size", 17)
		pull.pressed.connect(func(): _net.send({"t": "start"}))
		ctlrow.add_child(pull)
	_net_status = _title(box, "empty seats fight as AI raiders", 12, Palette.TEXT_DIM)
	var back := Button.new()
	back.text = "◂ leave room"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	back.pressed.connect(func():
		_net.close()
		_online = false
		_show_select())
	box.add_child(back)

func _launch_online(spec: Dictionary, you: String) -> void:
	if you == "" or not SEAT_IDX.has(you):
		_set_net_status("✗ no seat — claim one first")
		return
	_seat_key = you
	for e in spec.get("seats", []):
		if String(e["key"]) == you:
			_aspect = String(e["aspect"])
	_loadout = _make_loadout()
	_screen = "combat"
	_clear()
	var s := RaidNet.build(spec, you)
	_build_combat(s)
	_shake_amt = 0.0
	_net_ctrl.set_spec_seed(int(spec.get("seed", 1)))
	_net_ctrl.begin_net(s, SEAT_IDX[you])
	_ctrl = _net_ctrl

func _on_net_dropped(reason: String) -> void:
	if not _online:
		return
	if _screen == "combat":
		_show_end(false)
	elif _screen == "lobby" or _screen == "netconnect":
		_show_online()
		_set_net_status("✗ " + reason)

func _on_net_fight_ended(won: bool, _cause: String) -> void:
	# normally encounter_ended already showed the end screen off the replica;
	# this catches server-side aborts the replica never reached
	if _screen == "combat" and (_ctrl.state == null or not _ctrl.state.over):
		_show_end(won)

func _on_desync() -> void:
	if _screen == "combat":
		_show_end(false)
		_set_net_status("desync — see log")

# ============================================================ START / BUILD
func _launch(seat_id: String, aspect: String = "", jump_to: String = "") -> void:
	_seat_key = seat_id if SEAT_IDX.has(seat_id) else "tank"
	var pool: Array = ASPECTS[_seat_key]
	_aspect = String(pool[0]["id"])
	for a in pool:
		if String(a["id"]) == aspect:
			_aspect = aspect
	if _map_pending:                  # TOPOLOGY: the aspect ceremony pulls onto the map
		_map_pending = false
		_start_map_run()
		return
	if jump_to != "":
		_enc_id = jump_to
	_screen = "combat"
	_clear()
	# offline uses the SAME shared fight factory the netcode locksteps on
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var spec := RaidNet.make_spec(run_seed, {_seat_key: {"aspect": _aspect, "ai": false}}, _enc_id)
	var s := RaidNet.build(spec, _seat_key)
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_ctrl = _local_ctrl
	_ctrl.begin(s, SEAT_IDX[_seat_key])

# ============================================================ TOPOLOGY RAID FLOOR (MAP-3a)
## "RING 3: THE SHALLOW STACK" — the generated node map run for the whole raid:
## Vorathek guards the perimeter login, stray subagent skirmishes prowl the racks,
## MISTRAL-7B is the floor Seal. The party's integrity persists across nodes
## (per SEAT — fights start at carried HP); events bruise or patch everyone; only
## combat kills. A raider dead at a won fight REBOOTS at 35%.
func _start_map_run() -> void:
	_map_fights = RaidContent.floor_fights()
	_map = RunMap.generate(int(Time.get_ticks_usec()) & 0x7FFFFFFF,
		_map_fights.size(), MapContent.event_ids())
	_map_node = -1
	_map_inv = {}
	_map_fracs = [1.0, 1.0, 1.0, 1.0]
	_map_wounds = [0.0, 0.0, 0.0, 0.0]
	_map_mana = 1.0
	_show_map()

func _show_map() -> void:
	_screen = "map"
	_clear()
	var ms := MapScreen.new()
	ms.map = _map
	ms.current = _map_node
	ms.inventory = _map_inv
	ms.hp_frac = _party_integrity()
	ms.node_entered.connect(_enter_node)
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)

func _party_integrity() -> float:
	var t := 0.0
	for f in _map_fracs:
		t += float(f)
	return t / maxf(1.0, float(_map_fracs.size()))

func _enter_node(id: int) -> void:
	_map_node = id
	var n: Dictionary = _map.node(id)
	var first_visit: bool = not bool(n.get("visited", false))
	n["visited"] = true
	if first_visit and bool(n["key"]) and not _map_inv.get("api_key", false):
		_map_inv["api_key"] = true
		_map_stop(String(n["name"]), MapContent.KEY_PICKUP,
			[{"label": "TAKE IT", "fx": {"key": true,
				"result": "Authorization acquired. The raid agrees to never speak of where it was taped."}}],
			Palette.GOLD_BRIGHT, _resolve_node.bind(n))
		return
	_resolve_node(n)

func _resolve_node(n: Dictionary) -> void:
	match String(n["kind"]):
		RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
			_launch_map_fight(int(n["fight"]))
		RunMap.KIND_EVENT:
			var ev := MapContent.event(String(n["event"]))
			_map_stop(String(ev["title"]), String(ev["body"]), ev["choices"], Palette.VOID, _show_map)
		RunMap.KIND_COOLING:
			_map_stop(MapContent.COOLING_TITLE, MapContent.COOLING_BODY,
				[{"label": "THROTTLE  (rest — +%d%% integrity · healer refuels · corrupted sectors repaired)" % int(MapContent.COOLING_HEAL * 100),
					"fx": {"heal": MapContent.COOLING_HEAL, "mana": 1.0, "repair": true,
						"result": MapContent.COOLING_RESULT}}],
				Palette.FLOW, _show_map)
		RunMap.KIND_CACHE:
			_map_stop(MapContent.CACHE_TITLE, MapContent.CACHE_BODY,
				[{"label": "SALVAGE A COMPONENT", "fx": {"draft": true, "result": MapContent.CACHE_RESULT}}],
				Palette.GOLD, _show_map)

## A map fight: the node's encounter through the SAME shared factory as every raid
## pull, then each seat starts at its carried integrity.
func _launch_map_fight(fi: int) -> void:
	_screen = "combat"
	_clear()
	var enc: EncounterRes = _map_fights[clampi(fi, 0, _map_fights.size() - 1)]
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var spec := RaidNet.make_spec(run_seed, {_seat_key: {"aspect": _aspect, "ai": false}}, String(enc.id))
	var s := RaidNet.build(spec, _seat_key)
	for i in s.seats.size():
		if i < _map_fracs.size():
			var u: Seat = s.seats[i]
			# CORRUPTED SECTORS first (a max-HP cut no heal can fix), then the
			# carried integrity fraction of what's LEFT.
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(_map_wounds[i]))))
			u.hp = maxf(1.0, roundf(u.hp_max * float(_map_fracs[i])))
			if u.role == "healer":    # the fuel gauge: mana carries between nodes
				u.resource = roundf(u.resource_max * _map_mana)
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_ctrl = _local_ctrl
	_ctrl.begin(s, SEAT_IDX[_seat_key])

## One node stop = one MapEventPanel; apply the chosen fx, then continue.
func _map_stop(title: String, body: String, choices: Array, accent: Color, done: Callable) -> void:
	_screen = "mapstop"
	_clear()
	var p := MapEventPanel.new()
	p.title_text = title
	p.body_text = body
	p.choices = _raidify(choices)
	p.accent = accent
	p.finished.connect(func(fx: Dictionary):
		_apply_map_fx(fx)
		done.call())
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(p)

## The raid has no boon draft — a solo "draft" reward becomes an EMERGENCY PATCH:
## +25% integrity to the most damaged raider. Same texture (a prize), raid-shaped.
func _raidify(choices: Array) -> Array:
	var out: Array = []
	for c in choices:
		var c2: Dictionary = (c as Dictionary).duplicate(true)
		var fx: Dictionary = c2.get("fx", {})
		if bool(fx.get("draft", false)):
			fx.erase("draft")
			fx["patch"] = true
			fx["result"] = String(fx.get("result", "")) \
				+ " (Salvage routed to the most damaged raider: +25% integrity.)"
		out.append(c2)
	return out

## Events bruise or patch the WHOLE raid; only combat kills (integrity floors at 5%).
func _apply_map_fx(fx: Dictionary) -> void:
	var heal := float(fx.get("heal", 0.0))
	var hurt := float(fx.get("hurt", 0.0))
	for i in _map_fracs.size():
		_map_fracs[i] = clampf(float(_map_fracs[i]) + heal - hurt, 0.05, 1.0)
	if fx.has("mana"):
		_map_mana = clampf(maxf(_map_mana, float(fx["mana"])), 0.05, 1.0)
	if bool(fx.get("repair", false)):
		for i in _map_wounds.size():
			_map_wounds[i] = 0.0
	if bool(fx.get("patch", false)):
		var lo := 0
		for i in _map_fracs.size():
			if float(_map_fracs[i]) < float(_map_fracs[lo]):
				lo = i
		_map_fracs[lo] = clampf(float(_map_fracs[lo]) + 0.25, 0.05, 1.0)

## Ring 3 cleared: the floor Seal (MISTRAL-7B) is down — privilege elevation.
func _show_map_cleared() -> void:
	_screen = "end"
	_map = null
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := _title(box, "PRIVILEGE ELEVATED", 52, Palette.WIN)
	banner.add_theme_font_override("font", UiKit.title(900))
	_title(box, "Ring 3 cleared — the floor Seal breaks. sudo granted. Root is three rings down.", 16, Palette.TEXT)
	_title(box, String((RaidContent.QUIPS.get("mistral", {}) as Dictionary).get("win", "")), 13, Palette.TEXT_DIM)
	var again := Button.new()
	again.text = "BACK TO THE RIFT"
	again.custom_minimum_size = Vector2(260, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(func(): _show_select(_seat_key))
	box.add_child(again)

func _make_loadout() -> Array:
	match _seat_key:
		"blade":
			return TwinfangConfig.new().loadout(_aspect)
		"caster":
			return VoidcallerConfig.new().loadout(_aspect)
		"healer":
			_mcfg = MenderConfig.new()
			return _mcfg.order(_aspect)
		_:
			return ["cleave", "rampage", "fortify", ("vindicate" if _aspect == "warden" else "avalanche")]

## The seat's defensive-verb label (the tank's depends on its Aspect).
func _verb() -> String:
	match _seat_key:
		"tank":
			return "PARRY" if _aspect == "warden" else "DODGE"
		"caster":
			return "KICK"
		_:
			return "DODGE"

func _build_combat(s: CombatState) -> void:
	# THE RIFT, embodied: all four raiders + Vorathek as puppets behind the HUD.
	# Actors come from Actor2D.make — drop art in res://game/art/actors/ to
	# replace any placeholder (see godot/ART-PIPELINE.md).
	_stage2d = RaidStage2D.new()
	_ui.add_child(_stage2d)
	var aspects := {}
	for i in s.seats.size():
		var key: String = RaidNet.SEAT_KEYS[i] if i < RaidNet.SEAT_KEYS.size() else "tank"
		var kit = s.seats[i].kit
		aspects[key] = String(kit.get("aspect")) if kit != null and kit.get("aspect") != null else ""
	_stage2d.setup(s, aspects)
	_stage2d.bind_seats(s.seats)

	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_shake_root)

	_bar = BossBar.new()
	_place(_bar, 0.5, 0, 0.5, 0, -340, 52, 340, 104)
	_shake_root.add_child(_bar)

	_dial = BossCastDial.new()
	_dial.verb = _verb()
	# reticle mode, ringed around the Riftmaw puppet (x-anchor = the boss slot)
	_dial.show_sigil = false
	_place(_dial, 0.72, 0, 0.72, 0, -210, 128, 210, 640)
	_shake_root.add_child(_dial)

	# the Judgment Channel under the reticle — seat-aware: parry gate for the
	# tank, dodge gate for the blade, clean-kick band for the caster, barrage
	# timing for the healer; off-target swings fly dim with their victim's name
	_judge = StrikeJudge.new()
	_judge.verb = _verb()
	_place(_judge, 0.72, 0, 0.72, 0, -260, 648, 260, 752)
	_shake_root.add_child(_judge)

	# every fight opens with a ceremony: the boss's name-card burns in and off
	BossIntro.play(_ui, s.encounter.name)
	_recap_stats = {}              # a fresh reckoning per fight

	# THE RAID — reliquary frames down the left. Gold-lit = the boss's victim;
	# for the Mender seat the frames are also your click-cast targets.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_place(col, 0, 0.5, 0, 0.5, 26, -220, 210, 220)
	_ui.add_child(col)              # NOT under shake — the healer aims clicks at these
	var head := Label.new()
	head.text = "THE RAID   ·   ◆ = its gaze" if _seat_key != "healer" else "THE RAID   ·   hover + click-cast"
	head.add_theme_font_size_override("font_size", 12)
	head.add_theme_color_override("font_color", Palette.TEXT_DIM)
	col.add_child(head)
	_frames = []
	for seat in s.seats:
		var fr := RaidFrame.new()
		fr.unit_name = seat.unit_name + (" (YOU)" if seat.is_player else "")
		fr.role = seat.role
		fr.hovered.connect(_on_frame_hover)
		fr.unhovered.connect(_on_frame_unhover)
		col.add_child(fr)
		_frames.append({"seat": seat, "frame": fr})

	_aggro_warn = Label.new()
	_aggro_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aggro_warn.add_theme_font_size_override("font_size", 20)
	_aggro_warn.add_theme_color_override("font_color", Palette.CRIMSON)
	_aggro_warn.visible = false
	_place(_aggro_warn, 0.5, 0, 0.5, 0, -360, 106, 360, 130)
	_shake_root.add_child(_aggro_warn)

	match _seat_key:
		"tank":
			_build_band_tank()
		"blade":
			_build_band_blade()
		"caster":
			_build_band_caster()
		"healer":
			_build_band_healer()

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fx)

func _orb(fill: Color, caption: String, right: bool) -> LiquidOrb:
	var o := LiquidOrb.new()
	o.fill = fill
	o.caption = caption
	if right:
		_place(o, 1, 1, 1, 1, -175, -172, -55, -52)
	else:
		_place(o, 0, 1, 0, 1, 55, -172, 175, -52)
	_shake_root.add_child(o)
	return o

func _rune_row(off_l: float, off_r: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_place(row, 0.5, 1, 0.5, 1, off_l, -160, off_r, -76)
	_shake_root.add_child(row)
	return row

func _hint_line(text: String) -> void:
	var hint := Label.new()
	hint.text = text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(hint, 0.5, 1, 0.5, 1, -330, -70, 330, -46)
	_shake_root.add_child(hint)

func _add_runes(row: HBoxContainer, ids: Array, accent = null) -> void:
	_runes = []
	_rune_ids = []
	for i in ids.size():
		var id: String = ids[i]
		var rune := AbilityRune.new()
		rune.label = ABILITY_NAMES.get(id, id)
		rune.key_num = i + 1
		rune.icon_id = id
		if accent != null:
			rune.accent = accent
		rune.pressed.connect(_use_ability.bind(i))
		row.add_child(rune)
		_runes.append(rune)
		_rune_ids.append(id)

# ---- per-seat bands ----
func _build_band_tank() -> void:
	_hp_orb = _orb(Palette.BLOOD, "HEALTH", false)
	_res_orb = _orb(Palette.RAGE, "RAGE", true)
	_spec = SpecGauge.new()
	_spec.aspect = _aspect
	_place(_spec, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	_shake_root.add_child(_spec)
	var row := _rune_row(-380.0, 380.0)
	_guard = AbilityRune.new()
	_guard.label = _verb().capitalize()
	_guard.key_label = "SPC"
	_guard.icon_id = "guard"
	_guard.accent = Palette.STEEL
	_guard.tooltip_text = "Your defensive verb — own cooldown, off-GCD."
	_guard.pressed.connect(func(): _ctrl.human({"type": "defense"}))
	row.add_child(_guard)
	_challenge = AbilityRune.new()
	_challenge.label = "Challenge"
	_challenge.key_label = "T"
	_challenge.icon_id = "shockwave"
	_challenge.accent = Palette.CRIMSON
	_challenge.tooltip_text = "Taunt — force the boss onto you and seize top threat. 8s cd, off-GCD."
	_challenge.pressed.connect(func(): _ctrl.human({"type": "ability", "id": "challenge"}))
	row.add_child(_challenge)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	_add_runes(row, _loadout)
	_hint_line("SPACE — %s    ·    F — DODGE beats    ·    T — CHALLENGE (taunt)" % _verb())

func _build_band_blade() -> void:
	_rhythm = RhythmBar.new()
	# YOUR metronome sits in your own column — the boss's Judgment Channel owns
	# the line under the reticle on the right
	_place(_rhythm, 0.35, 0, 0.35, 0, -360, 646, 360, 746)
	_shake_root.add_child(_rhythm)
	_hp_orb = _orb(Palette.BLOOD, "HEALTH", false)
	_res_orb = _orb(Palette.ENERGY, "ENERGY", true)
	_tf_gauge = TwinfangGauge.new()
	_tf_gauge.aspect = _aspect
	_place(_tf_gauge, 0.5, 1, 0.5, 1, -300, -302, 300, -172)
	_shake_root.add_child(_tf_gauge)
	var row := _rune_row(-360.0, 360.0)
	_guard = AbilityRune.new()
	_guard.label = "DODGE"
	_guard.key_label = "SPC"
	_guard.icon_id = "dodge"
	_guard.accent = Palette.FLOW
	_guard.tooltip_text = "Dodge the swing aimed at YOU — a landed hit wipes your Flow."
	_guard.pressed.connect(func(): _ctrl.human({"type": "defense"}))
	row.add_child(_guard)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	_add_runes(row, _loadout)
	_strike_idx = _rune_ids.find("strike")
	_hint_line("SPACE — DODGE (protects Flow)    ·    F — DODGE beats    ·    hold aggro low — the boss eats loose blades")

func _build_band_caster() -> void:
	_pcast = PlayerCastBar.new()
	# YOUR cast bar sits in your own column — the boss's casts (and the clean-kick
	# band) live on the Judgment Channel under the reticle
	_place(_pcast, 0.35, 0, 0.35, 0, -240, 654, 240, 704)
	_shake_root.add_child(_pcast)
	_hp_orb = _orb(Palette.BLOOD, "HEALTH", false)
	_res_orb = _orb(Palette.VOID, "FOCUS", true)
	_vc_gauge = VoidcallerGauge.new()
	_vc_gauge.aspect = _aspect
	_place(_vc_gauge, 0.5, 1, 0.5, 1, -300, -302, 300, -172)
	_shake_root.add_child(_vc_gauge)
	var row := _rune_row(-360.0, 360.0)
	_guard = AbilityRune.new()
	_guard.label = "KICK"
	_guard.key_label = "SPC"
	_guard.icon_id = "kick"
	_guard.accent = Palette.KICK
	_guard.tooltip_text = "Kick the boss's cast — clean (last slice) pays extra Backlash."
	_guard.pressed.connect(func(): _ctrl.human({"type": "defense"}))
	row.add_child(_guard)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	_add_runes(row, _loadout, Palette.VOID)
	_hint_line("SPACE — KICK the Devouring Chant (clean = last slice)    ·    F — DODGE beats")

func _build_band_healer() -> void:
	_binds = MenderBinds.load_binds()
	_hp_orb = _orb(Color("2f5e93"), "MANA", false)     # the healer is untargetable — mana IS the health bar
	_spec_strip = SpecStrip.new()
	_spec_strip.title = "RESERVOIR" if _aspect == "tidecaller" else "NERVE"
	_spec_strip.accent = Palette.STEEL if _aspect == "tidecaller" else Palette.MOMENTUM
	_place(_spec_strip, 0.5, 1, 0.5, 1, -220, -254, 220, -206)
	_shake_root.add_child(_spec_strip)
	_castbar = CastChannel.new()
	_place(_castbar, 0.5, 1, 0.5, 1, -240, -322, 240, -262)
	_shake_root.add_child(_castbar)
	var row := _rune_row(-380.0, 380.0)
	_runes = []
	_rune_ids = []
	for id in _loadout:
		var sp: Dictionary = _mcfg.spells.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		if sp.has("spec"):
			rune.accent = Palette.STEEL if _aspect == "tidecaller" else Palette.MOMENTUM
		rune.custom_minimum_size = Vector2(62, 62)
		rune.pressed.connect(_cast.bind(String(id)))
		row.add_child(rune)
		_runes.append(rune)
		_rune_ids.append(id)
	_hint_line(_healer_hint())

func _healer_hint() -> String:
	var parts: Array = []
	for chord in MenderBinds.CHORDS:
		var id := String(_binds.get(chord, "none"))
		if id != "none":
			parts.append("%s=%s" % [MenderBinds.CHORD_SHORT.get(chord, chord), id.capitalize()])
	return "Hover a frame + click:  " + "  ·  ".join(parts) + "    ·    SPACE/F — dodge beats"

# ============================================================ INPUT
func _on_frame_hover(fr) -> void:
	for e in _frames:
		if e["frame"] == fr:
			_hover_seat = e["seat"]
			return

func _on_frame_unhover(fr) -> void:
	for e in _frames:
		if e["frame"] == fr and _hover_seat == e["seat"]:
			_hover_seat = null
			return

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _net != null:
				_net.close()
			get_tree().change_scene_to_file("res://game/main.tscn")
			return
		if _screen != "combat":
			return
		match _seat_key:
			"healer":
				_healer_key(event.keycode)
			_:
				_martial_key(event.keycode)
		return
	# Mender click-cast: hover a frame, click a chord
	if _seat_key == "healer" and _screen == "combat" \
			and event is InputEventMouseButton and event.pressed and _hover_seat != null:
		var id := String(_binds.get(_mouse_chord(event), "none"))
		if id == "signature":
			id = _signature()
		if id != "none" and _mcfg.spells.has(id):
			_focus_seat = _hover_seat
			_cast_on(_hover_seat, id)

func _martial_key(code: int) -> void:
	match code:
		KEY_SPACE:
			_ctrl.human({"type": "defense"})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_T:
			if _seat_key == "tank":
				_ctrl.human({"type": "ability", "id": "challenge"})
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_5: _use_ability(4)

func _healer_key(code: int) -> void:
	match code:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})     # cancels your cast — the discipline test
		KEY_1: _cast("flash")
		KEY_2: _cast("mend")
		KEY_3: _cast("renew")
		KEY_4: _cast("ward")
		KEY_5: _cast("cascade")
		KEY_6: _cast("well")
		KEY_Q: _cast("dispel")
		KEY_E: _cast("medit")
		KEY_7: _cast(_signature())

func _use_ability(i: int) -> void:
	if _screen == "combat" and i >= 0 and i < _rune_ids.size():
		_ctrl.human({"type": "ability", "id": _rune_ids[i]})

func _signature() -> String:
	return "surge" if _aspect == "tidecaller" else "laststand"

func _mouse_chord(e: InputEventMouseButton) -> String:
	var mods := ""
	if e.shift_pressed: mods += "shift+"
	if e.ctrl_pressed: mods += "ctrl+"
	if e.alt_pressed: mods += "alt+"
	match e.button_index:
		MOUSE_BUTTON_LEFT: return mods + "left"
		MOUSE_BUTTON_RIGHT: return mods + "right"
		MOUSE_BUTTON_MIDDLE: return mods + "middle"
	return mods + "other"

func _cast(id: String) -> void:
	if _screen != "combat" or _mcfg == null:
		return
	var sp: Dictionary = _mcfg.spells.get(id, {})
	if sp.is_empty():
		return
	var target: Seat = null
	if bool(sp.get("target", false)):
		target = _hover_seat if _hover_seat != null else _focus_seat
		if target == null or not target.alive():
			return
	_ctrl.human({"type": "ability", "id": id, "target": target})

## Mirror the engine's gates so a click flashes gold (accepted) or dim (blocked).
func _cast_on(seat: Seat, id: String) -> void:
	var s := _ctrl.state
	var p := _ctrl.player()
	var sp: Dictionary = _mcfg.spells[id]
	var offgcd := bool(sp.get("offgcd", false))
	var ready := true
	if not offgcd and s.tick < p.gcd_until_tick: ready = false
	if s.tick < int(p.cooldowns.get(id, 0)): ready = false
	if not offgcd and not p.casting.is_empty(): ready = false
	if p.resource < float(sp.get("mana", 0.0)): ready = false
	if id == "dispel" and seat.debuff.is_empty(): ready = false
	if id == "surge" and float(p.vars.get("reservoir", 0.0)) <= 1.0: ready = false
	if id == "laststand" and float(p.vars.get("nerve", 0.0)) <= 1.0: ready = false
	var fr := _frame_of(seat)
	if fr != null:
		fr.flash(Palette.GOLD if ready else Palette.TEXT_DIM)
	if ready:
		_ctrl.human({"type": "ability", "id": id, "target": seat if bool(sp.get("target", false)) else null})

func _frame_of(seat: Seat) -> RaidFrame:
	for e in _frames:
		if e["seat"] == seat:
			return e["frame"]
	return null

# ============================================================ RENDER
func _process(delta: float) -> void:
	if _screen != "combat" or _dial == null or _ctrl.state == null:
		return
	_shake_amt = maxf(0.0, _shake_amt - delta * 42.0)
	if _shake_root != null:
		_shake_root.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amt

	var s := _ctrl.state
	var p := _ctrl.player()
	var obs := CombatCore.observe(s, p)

	var live_add := _active_add(s)
	if live_add != null:
		_bar.boss_name = live_add.name
		_bar.hp = s.boss.add_hp
		_bar.hp_max = s.boss.add_hp_max
	else:
		_bar.boss_name = s.encounter.name
		_bar.hp = s.boss.hp
		_bar.hp_max = s.boss.hp_max
	_bar.phase_num = _phase_num(s)
	_bar.phase_ats = s.encounter.phases.map(func(ph): return ph.at)
	_render_dial(s, obs)
	_render_frames(s, obs)
	match _seat_key:
		"tank":
			_render_band_tank(s, p, obs)
		"blade":
			_render_band_blade(s, p, obs)
		"caster":
			_render_band_caster(s, p, obs)
		"healer":
			_render_band_healer(s, p, obs)

	if _stage2d != null:
		_stage2d.sync(s)
	for ev in s.events:
		if _stage2d != null:
			_stage2d.on_event(ev)
		_handle_event(ev)
	s.events.clear()

## The AddRes currently holding the field, or null (main form).
func _active_add(s: CombatState) -> AddRes:
	if s.boss.add_i >= 0 and s.boss.add_i < s.encounter.adds.size():
		return s.encounter.adds[s.boss.add_i]
	return null

func _render_dial(s: CombatState, obs: Dictionary) -> void:
	var live_add := _active_add(s)
	if live_add != null:
		_dial.boss_name = live_add.name
		_dial.boss_hp_frac = s.boss.add_hp / maxf(s.boss.add_hp_max, 1.0)
	else:
		_dial.boss_name = s.encounter.name
		_dial.boss_hp_frac = s.boss.hp / maxf(s.boss.hp_max, 1.0)
	_dial.enraged = s.encounter.enrage_at > 0.0 and float(s.tick) * s.dt >= s.encounter.enrage_at
	var tg: Dictionary = obs.get("telegraph", {})
	if tg.is_empty():
		_dial.tg_active = false
		_dial.tg_strikes = []
		_dial.dodge_ready = bool(obs.get("dodge_ready", true))
		_dial.def_ready = bool(obs.get("defense_ready", true))
		return
	var dur := float(s.telegraph.dur_ticks) * s.dt
	var mine := bool(tg.get("targets_me", false))
	_dial.tg_active = true
	_dial.tg_name = s.telegraph.ability.name
	if not mine and s.telegraph.target != null and not bool(tg.get("heal", false)):
		_dial.tg_name = "%s → %s" % [s.telegraph.ability.name, s.telegraph.target.unit_name]
	_dial.tg_frac = (dur - float(tg.get("remaining", 0.0))) / maxf(dur, 0.001)
	_dial.tg_remaining = float(tg.get("remaining", 0.0))
	_dial.tg_size = int(tg.get("size", 0))
	_dial.tg_heal = bool(tg.get("heal", false))
	_dial.tg_feint = bool(tg.get("feint", false)) and mine
	_dial.tg_interruptible = bool(tg.get("interruptible", false))
	match _seat_key:
		"caster":
			# the kick answers the CAST, not the target — clean zone is the window
			_dial.tg_defensible = false
			var cz := float(obs.get("clean_zone", 0.62))
			_dial.zone_frac = clampf(cz / maxf(dur, 0.001), 0.0, 1.0)
			_dial.in_zone = _dial.tg_interruptible and _dial.tg_remaining <= cz \
				and bool(obs.get("defense_ready", false))
		"healer":
			_dial.tg_defensible = false
		_:
			# tank / blade: the timed defensive press — only armed when it's YOUR swing
			_dial.tg_defensible = bool(tg.get("defensible", false)) and mine
			var zone := float(obs.get("def_zone", 0.3))
			_dial.zone_frac = clampf(zone / maxf(dur, 0.001), 0.0, 1.0)
			_dial.in_zone = _dial.tg_defensible and _dial.tg_remaining <= zone \
				and bool(obs.get("defense_ready", false))
	_dial.feed_strikes(tg, dur, bool(obs.get("dodge_ready", true)), s.config.strike_good, s.config.strike_perfect)
	_dial.def_ready = bool(obs.get("defense_ready", true))
	_dial.dodge_ready = bool(obs.get("dodge_ready", true))
	if _judge != null:
		var jw := 0.0
		match _seat_key:
			"caster":
				jw = float(obs.get("clean_zone", 0.62))
			"healer":
				jw = 0.0
			_:
				jw = float(obs.get("def_zone", 0.3))
		_judge.feed(s, obs, jw)

func _render_frames(s: CombatState, obs: Dictionary) -> void:
	var victim := CombatCore._threat_target(s)
	for e in _frames:
		var seat: Seat = e["seat"]
		var fr: RaidFrame = e["frame"]
		fr.frac = seat.hp_frac()
		fr.hp = int(round(seat.hp))
		fr.maxhp = int(round(seat.hp_max))
		fr.absorb_frac = (seat.absorb / seat.hp_max) if seat.hp_max > 0.0 else 0.0
		fr.hot_count = seat.hots.size()
		fr.has_debuff = not seat.debuff.is_empty()
		fr.dead = not seat.alive()
		fr.bloodied = seat.alive() and seat.hp_frac() <= 0.4
		fr.incoming_frac = 0.0
		fr.incoming_dmg_frac = 0.0
		fr.incoming_lethal = false
		if _seat_key == "healer":
			fr.is_target = (seat == _hover_seat) or (_hover_seat == null and seat == _focus_seat)
		else:
			fr.is_target = seat == victim and seat.alive()
	if _seat_key == "healer":
		_healer_predictions(s)
	# aggro banner
	var aggro_me := bool(obs.get("aggro_me", false))
	match _seat_key:
		"tank":
			_aggro_warn.text = "IT TURNS ON YOUR RAID  —  CHALLENGE IT BACK  (T)"
			_aggro_warn.visible = not aggro_me and not s.over
		"blade", "caster":
			_aggro_warn.text = "IT'S HUNTING YOU  —  SURVIVE UNTIL THE TAUNT"
			_aggro_warn.visible = aggro_me and not s.over
		_:
			_aggro_warn.visible = false

## Healer-only frame overlays: telegraphed incoming damage + your cast's heal ghost.
func _healer_predictions(s: CombatState) -> void:
	if s.telegraph != null:
		var ab := s.telegraph.ability
		var amt := ab.amount * CombatCore.current_phase(s).mult
		var victims: Array = []
		if not ab.strikes.is_empty():
			var fracsum := 0.0
			for i in range(s.telegraph.next_strike, ab.strikes.size()):
				var st: StrikeRes = ab.strikes[i]
				if st.aoe and not st.feint:
					fracsum += st.amount_frac
				elif not st.feint and s.telegraph.beat_targets.has(i):
					# a random personal bolt — mark ITS victim's frame directly
					var bv: Seat = s.telegraph.beat_targets[i]
					if bv != null and bv.alive():
						var fb := _frame_of(bv)
						if fb != null:
							var bd := ab.amount * st.amount_frac * CombatCore.current_phase(s).mult
							fb.incoming_dmg_frac += bd / bv.hp_max
							fb.incoming_lethal = fb.incoming_lethal or bd >= bv.hp + bv.absorb
			amt *= fracsum
			for e in _frames:
				if not (e["seat"] as Seat).alive():
					continue
				victims.append(e["seat"])
		else:
			match ab.effect:
				AbilityRes.Effect.DMG_TARGET, AbilityRes.Effect.MARK_NUKE:
					if s.telegraph.target != null:
						victims = [s.telegraph.target]
				AbilityRes.Effect.DMG_ALL, AbilityRes.Effect.NOVA:
					for e in _frames:
						var u: Seat = e["seat"]
						if u.alive() and u.role != "healer":
							victims.append(u)
		for v in victims:
			var fr := _frame_of(v)
			if fr != null and amt > 0.0:
				fr.incoming_dmg_frac = amt / v.hp_max
				fr.incoming_lethal = amt >= v.hp + v.absorb
	var p := _ctrl.player()
	if p != null and not p.casting.is_empty():
		var cid := String(p.casting.get("id", ""))
		var csp: Dictionary = _mcfg.spells.get(cid, {})
		if csp.has("heal"):
			if bool(csp.get("target", false)) and p.casting.get("target") != null:
				var t: Seat = p.casting.get("target")
				var fr2 := _frame_of(t)
				if fr2 != null:
					fr2.incoming_frac = _predict_heal(csp, t)
			elif cid == "cascade":
				var pool: Array = []
				for e in _frames:
					var u: Seat = e["seat"]
					if u.alive() and u.role != "healer":
						pool.append(u)
				pool.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
				for i in mini(3, pool.size()):
					var fr3 := _frame_of(pool[i])
					if fr3 != null:
						fr3.incoming_frac = _predict_heal(csp, pool[i])

func _predict_heal(sp: Dictionary, seat: Seat) -> float:
	var m := 1.0
	if _aspect == "brinkwarden":
		m = 1.0 + (1.0 - seat.hp_frac()) * _mcfg.brink_heal_scale
	return (float(sp.get("heal", 0.0)) * m) / maxf(seat.hp_max, 1.0)

func _cd_frac(p: Seat, s: CombatState, id: String, cd_sec: float) -> float:
	var left := int(p.cooldowns.get(id, 0)) - s.tick
	if left <= 0:
		return 0.0
	return clampf(float(left) / float(CombatCore.to_ticks(cd_sec, s.config.fixed_hz)), 0.0, 1.0)

# ---- per-seat band renders ----
func _render_band_tank(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(p.resource, p.resource_max)
	_spec.counter = int(obs.get("counter", 0))
	_spec.momentum = int(obs.get("momentum", 0))
	_spec.momentum_max = int(obs.get("momentum_max", 10))
	_spec.riposte = bool(obs.get("riposte_active", false))
	var gcd_ticks := float(CombatCore.to_ticks(1.0, s.config.fixed_hz))
	var rage := float(obs.get("rage", 0.0))
	for i in _runes.size():
		var afford := true
		match _rune_ids[i]:
			"rampage": afford = rage >= 40.0
			"fortify": afford = rage >= 30.0
			"vindicate": afford = int(obs.get("counter", 0)) >= 1
			"avalanche": afford = rage >= 20.0 and int(obs.get("momentum", 0)) >= 1
		_runes[i].affordable = afford
		_runes[i].usable = bool(obs.get("gcd_ready", false))
		_runes[i].cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)
	var dcd := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", 2.2)), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd, 0.0, 1.0)
	var ch := int(p.cooldowns.get("challenge", 0))
	_challenge.usable = s.tick >= ch
	_challenge.cd_frac = clampf(float(ch - s.tick) / float(CombatCore.to_ticks(8.0, s.config.fixed_hz)), 0.0, 1.0)

func _render_band_blade(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(float(obs.get("energy", 0.0)), float(obs.get("energy_max", 100.0)))
	_rhythm.since = int(obs.get("since_strike", 0))
	_rhythm.swing_min = int(obs.get("swing_min_ticks", 13))
	_rhythm.perfect_lo = int(obs.get("perfect_lo", 18))
	_rhythm.perfect_hi = int(obs.get("perfect_hi", 29))
	_tf_gauge.combo = int(obs.get("cp", 0))
	_tf_gauge.combo_max = int(obs.get("cp_max", 5))
	_tf_gauge.flow = int(obs.get("flow", 0))
	_tf_gauge.flow_max = int(obs.get("flow_max", 6))
	_tf_gauge.flow_mult = float(obs.get("flow_mult", 1.0))
	_tf_gauge.tier = int(obs.get("tier", 0))
	_tf_gauge.venom = obs.get("venom", {"V": 0, "F": 0, "C": 0, "syn_ramp": 1.0, "syn_active": false})
	var energy := float(obs.get("energy", 0.0))
	var cpn := int(obs.get("cp", 0))
	var in_green: bool = _rhythm.since >= _rhythm.perfect_lo and _rhythm.since <= _rhythm.perfect_hi
	for i in _runes.size():
		var id: String = _rune_ids[i]
		var afford := true
		var usable := true
		var cd := 0.0
		match id:
			"strike":
				afford = energy >= 12.0
				usable = _rhythm.since >= _rhythm.swing_min
			"eviscerate", "envenom":
				afford = energy >= 25.0
				usable = cpn >= 1
			"flurry":
				afford = energy >= 28.0
			"kick":
				afford = energy >= 10.0
				cd = _cd_frac(p, s, "kick", 7.0)
				usable = cd <= 0.0
			"coupdegrace":
				afford = energy >= 30.0
				cd = _cd_frac(p, s, "coupdegrace", 5.0)
				usable = cd <= 0.0 and int(obs.get("flow", 0)) >= int(obs.get("flow_max", 6))
			"rupture":
				afford = energy >= 22.0
				cd = _cd_frac(p, s, "rupture", 3.5)
				usable = cd <= 0.0 and int(obs.get("venom_total", 0)) >= 1
		_runes[i].affordable = afford
		_runes[i].usable = usable
		_runes[i].cd_frac = cd
		if i == _strike_idx:
			_runes[i].accent = Palette.PERFECT if in_green else Palette.GOLD
	var dcd := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", 2.4)), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd, 0.0, 1.0)

func _render_band_caster(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(float(obs.get("focus", 0.0)), float(obs.get("focus_max", 100.0)))
	var casting: Dictionary = obs.get("casting", {})
	if casting.is_empty():
		_pcast.active = false
		_pcast.next_instant = bool(obs.get("next_instant", false))
	else:
		_pcast.active = true
		_pcast.frac = clampf(float(s.tick - int(casting.get("start_tick", 0))) / maxf(float(casting.get("dur_ticks", 1)), 1.0), 0.0, 1.0)
		_pcast.label = ABILITY_NAMES.get(String(casting.get("id", "")), String(casting.get("id", "")))
		_pcast.pushed = bool(casting.get("pushed", false))
	_vc_gauge.backlash = int(obs.get("backlash", 0))
	_vc_gauge.backlash_max = int(obs.get("backlash_max", 5))
	_vc_gauge.next_instant = bool(obs.get("next_instant", false))
	_vc_gauge.silence_left = float(obs.get("silence_left", 0.0))
	_vc_gauge.boss_exposed = bool(obs.get("boss_exposed", false))
	_vc_gauge.expose_amt = float(obs.get("expose_amt", 0.0))
	var focus := float(obs.get("focus", 0.0))
	var can_cast: bool = casting.is_empty() and bool(obs.get("gcd_ready", true))
	for i in _runes.size():
		var id: String = _rune_ids[i]
		var afford := true
		var usable := can_cast
		var cd := 0.0
		match id:
			"fracture": afford = focus >= 26.0
			"overload": afford = int(obs.get("backlash", 0)) >= 1
			"quietus":
				afford = focus >= 30.0
				cd = _cd_frac(p, s, "quietus", 9.0)
				usable = can_cast and cd <= 0.0
			"barrier":
				cd = _cd_frac(p, s, "barrier", 10.0)
				usable = can_cast and cd <= 0.0
			"silence":
				cd = _cd_frac(p, s, "silence", 11.0)
				usable = can_cast and cd <= 0.0
			"counterspell":
				cd = _cd_frac(p, s, "counterspell", 9.0)
				usable = can_cast and cd <= 0.0
		if cd <= 0.0 and not can_cast:
			cd = clampf(float(p.gcd_until_tick - s.tick) / float(CombatCore.to_ticks(1.0, s.config.fixed_hz)), 0.0, 1.0)
		_runes[i].affordable = afford
		_runes[i].usable = usable
		_runes[i].cd_frac = cd
	var icd := maxf(1.0, float(CombatCore.to_ticks(5.0, s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / icd, 0.0, 1.0)

func _render_band_healer(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.resource, _mcfg.mana_max)
	if _aspect == "tidecaller":
		_spec_strip.value = float(obs.get("reservoir", 0.0))
		_spec_strip.max_value = _mcfg.reservoir_max
		_spec_strip.charged = _spec_strip.value > 1.0
	else:
		_spec_strip.value = float(obs.get("nerve", 0.0))
		_spec_strip.max_value = _mcfg.nerve_max
		_spec_strip.charged = _spec_strip.value > 1.0
		var blood := 0
		for e in _frames:
			var u: Seat = e["seat"]
			if u.role != "healer" and u.alive() and u.hp_frac() <= _mcfg.blood_thresh:
				blood += 1
		_spec_strip.hint = ("%d bloodied" % blood) if blood > 0 else ""
	var casting: Dictionary = obs.get("casting", {})
	if casting.is_empty():
		_castbar.active = false
	else:
		_castbar.active = true
		_castbar.frac = clampf(float(s.tick - int(casting.get("start_tick", 0))) / maxf(float(casting.get("dur_ticks", 1)), 1.0), 0.0, 1.0)
		var ct: Seat = casting.get("target")
		_castbar.target = ct.unit_name if ct != null else ""
		_castbar.spell_id = String(casting.get("id", ""))
		_castbar.label = String(_mcfg.spells.get(_castbar.spell_id, {}).get("name", _castbar.spell_id))
	var gcd_ticks := float(CombatCore.to_ticks(_mcfg.gcd, s.config.fixed_hz))
	for i in _runes.size():
		var id: String = _rune_ids[i]
		var sp: Dictionary = _mcfg.spells[id]
		var offgcd := bool(sp.get("offgcd", false))
		var afford: bool = p.resource >= float(sp.get("mana", 0.0))
		if id == "surge": afford = afford and float(obs.get("reservoir", 0.0)) > 1.0
		if id == "laststand": afford = afford and float(obs.get("nerve", 0.0)) > 1.0
		var cd_until := int(p.cooldowns.get(id, 0))
		var gcd_block: bool = (not offgcd) and s.tick < p.gcd_until_tick
		var cd_block: bool = s.tick < cd_until
		_runes[i].affordable = afford
		_runes[i].usable = not gcd_block and not cd_block
		if cd_block:
			_runes[i].cd_frac = clampf(float(cd_until - s.tick) / maxf(1.0, float(CombatCore.to_ticks(float(sp.get("cd", 1.0)), s.config.fixed_hz))), 0.0, 1.0)
		elif gcd_block:
			_runes[i].cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)
		else:
			_runes[i].cd_frac = 0.0

# ============================================================ JUICE
func _handle_event(ev: Dictionary) -> void:
	var mine := bool(ev.get("player", false))
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	RecapPanel.track(_recap_stats, ev)
	match String(ev.get("t", "")):
		"negate":
			# seat-less negates are string-impact echoes; strike_graded already
			# judged that press — don't double-pop over it
			if mine and ev.has("seat"):
				_big_text("%s!" % _verb(), Palette.GOLD_BRIGHT, 44)
				_add_shake(6.0)
				_dial.react("impact", 40.0)
		"hurt":
			var seat: Seat = ev.get("seat", null)
			if mine:
				var a := float(ev.get("amt", 0))
				_add_shake(clampf(a / 9.0, 3.0, 17.0))
				_float_num("-%d" % int(a), _fx.size * Vector2(0.14, 0.66), Palette.CRIMSON, 30.0)
			_flash_frame(seat, Palette.CRIMSON)
		"heal":
			_flash_frame(ev.get("seat", null), Palette.WIN)
		"debuff":
			_flash_frame(ev.get("seat", null), Palette.CRIMSON)
		"boss_hit":
			var a := float(ev.get("amt", 0))
			_float_num("-%d" % int(a),
				_fx.size * Vector2(0.5, 0.28) + Vector2(randf_range(-34.0, 34.0), 0.0),
				Palette.GOLD_BRIGHT, -32.0)
			_dial.react("impact", a)
		"boss_heal":
			var hh := float(ev.get("amt", 0))
			_float_num("+%d" % int(hh),
				_fx.size * Vector2(0.5, 0.22) + Vector2(randf_range(-30.0, 30.0), 0.0),
				Palette.WIN, -28.0)
			_dial.react("heal")
		"staggered":
			if bool(ev.get("was_heal", false)):
				_big_text("CHANT DENIED!", Palette.WIN, 42)
			else:
				_big_text("STAGGERED!", Palette.STEEL, 34, 0.6)
			_dial.react("stagger")
			_add_shake(5.0)
		"interrupt":
			if bool(ev.get("was_heal", false)):
				_big_text("DENIED!", Palette.KICK, 42)
			elif bool(ev.get("clean", false)):
				_big_text("CLEAN KICK!", Palette.GOLD_BRIGHT, 36)
			else:
				_big_text("KICK!", Palette.KICK, 34)
			_dial.react("stagger")
			_add_shake(5.0)
		"taunt":
			if mine:
				_big_text("CHALLENGED — IT'S YOURS!", Palette.GOLD_BRIGHT, 38)
				_add_shake(5.0)
				_dial.react("impact", 30.0)
			elif _seat_key != "tank":
				_big_text("taunted back", Palette.STEEL, 22, 0.5)
		"threat_drop":
			if mine:
				_big_text("IT FORGETS YOU!" if _seat_key == "tank" else "ITS GAZE FALLS ON YOU!", Palette.CRIMSON, 42)
				_add_shake(8.0)
		"strike_graded":
			if mine:
				match int(ev.get("grade", 0)):
					StrikeRes.Grade.PERFECT:
						_big_text("PERFECT DODGE!", Palette.GOLD_BRIGHT, 42)
					StrikeRes.Grade.GOOD:
						_big_text("DODGED", Palette.GOLD, 32, 0.6)
					StrikeRes.Grade.GRAZE:
						_big_text("graze", Palette.STEEL, 24, 0.5)
					StrikeRes.Grade.BAITED:
						_big_text("BAITED!", Palette.CRIMSON, 44)
						_add_shake(10.0)
					StrikeRes.Grade.READ:
						_big_text("READ!", Palette.RELIC, 28, 0.6)
		"dodge_whiff":
			if mine:
				_big_text("TOO EARLY!", Palette.CRIMSON.darkened(0.1), 28, 0.6)
		"add_spawn":
			_big_text("IT DELEGATES — KILL %s!" % String(ev.get("name", "THE ADD")), Palette.CRIMSON, 36)
			_add_shake(9.0)
			if _dial != null:
				_dial.react("stagger")
		"add_down":
			_big_text("%s TERMINATED — THE SEAL RETURNS" % String(ev.get("name", "IT")), Palette.GOLD_BRIGHT, 32)
			_add_shake(6.0)
		# ---- class extras (only fire for the class that emits them) ----
		"strike":
			if mine and _rhythm != null:
				_rhythm.show_result(String(ev.get("result", "")))
		"perfect":
			if mine:
				_big_text("PERFECT!", Palette.PERFECT, 34)
		"flow_lost":
			if mine:
				_big_text("FLOW LOST!", Palette.CRIMSON, 30)
		"rupture":
			_big_text("RUPTURE!", Palette.POISON, 36)
			_add_shake(7.0)
		"coup":
			_big_text("COUP DE GRÂCE!", Palette.PERFECT, 34)
			_add_shake(7.0)
		"kick_whiff", "int_whiff":
			if mine:
				_big_text("whiff", Palette.TEXT_DIM, 20, 0.5)
		"overload":
			if mine:
				_big_text("OVERLOAD!", Palette.KICK, 38)
				_add_shake(8.0)
		"quietus":
			if mine:
				_big_text("QUIETUS — LOCKED", Palette.VOID, 30)
				_add_shake(6.0)
		"silence":
			_big_text("SILENCED", Palette.VOID, 28, 0.6)
		"empower":
			_big_text("EMPOWERED", Palette.EXPOSE, 26, 0.6)
		"pushback":
			if mine:
				_big_text("pushed!", Palette.CRIMSON, 20, 0.5)
		"cast_cancelled":
			if _seat_key == "healer":
				_big_text("cast cancelled", Palette.TEXT_DIM, 16, 0.5)

func _flash_frame(seat: Seat, col: Color) -> void:
	if seat == null:
		return
	var fr := _frame_of(seat)
	if fr != null:
		fr.flash(col)

func _add_shake(amt: float) -> void:
	_shake_amt = minf(20.0, maxf(_shake_amt, amt))

func _big_text(text: String, col: Color, fs: int = 40, life: float = 0.7) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(460, 0)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.position = _fx.size * Vector2(0.5, 0.44) - Vector2(230.0, 0.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 34.0, life)
	tw.tween_property(l, "modulate:a", 0.0, life).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(l.queue_free)

func _float_num(text: String, pos: Vector2, color: Color, dy: float) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + dy, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(l.queue_free)

func _phase_num(s: CombatState) -> int:
	var fr := s.boss.hp / s.boss.hp_max
	var n := 1
	for i in s.encounter.phases.size():
		if s.encounter.phases[i].at >= fr:
			n = i + 1
	return n

# ============================================================ END
func _on_end(won: bool) -> void:
	if _screen != "combat":
		return
	if _map != null and not _online:
		# Topology floor: persist per-seat integrity + the healer's remaining mana.
		# A raider dead at a WON fight REBOOTS at 35% (only a wipe ends the run);
		# the Seal node ends the floor.
		for i in _ctrl.state.seats.size():
			if i < _map_fracs.size():
				var u: Seat = _ctrl.state.seats[i]
				if u.alive():
					_map_fracs[i] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
				else:
					# reboot: back at 35% — and the crash leaves a CORRUPTED SECTOR
					# (-20% max HP, stacking to 40%) only a Cooling Station repairs
					_map_fracs[i] = 0.35
					_map_wounds[i] = minf(0.4, float(_map_wounds[i]) + 0.2)
				if u.role == "healer":
					_map_mana = clampf(u.resource / maxf(1.0, u.resource_max), 0.05, 1.0)
		if not won:
			_show_end(false)
		elif String(_map.node(_map_node)["kind"]) == RunMap.KIND_SEAL:
			_show_map_cleared()
		else:
			_show_map()
		return
	_show_end(won)

func _show_end(won: bool) -> void:
	_screen = "end"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := _title(box, "THE SEAL BREAKS" if won else "THE RAID FALLS", 52,
		Palette.WIN if won else Palette.LOSE)
	banner.add_theme_font_override("font", UiKit.title(900))
	var quips: Dictionary = {}
	if _ctrl.state != null and _ctrl.state.encounter != null:
		quips = RaidContent.QUIPS.get(String(_ctrl.state.encounter.id), {})
	if won:
		_title(box, String(quips.get("win", "Four seats, one kill. The Rift shudders.")), 16, Palette.TEXT)
	else:
		var cause := _ctrl.state.loss_cause if _ctrl.state != null else ""
		_title(box, "Wipe — %s. Re-form and pull again." % cause.replace("_", " "), 16, Palette.TEXT)
		if quips.has("lose"):
			_title(box, String(quips["lose"]), 13, Palette.TEXT_DIM)
	# THE RECKONING — the fight's recap plaque (state survives into this screen)
	if _ctrl != null and _ctrl.state != null and _ctrl.player() != null:
		box.add_child(RecapPanel.new(_ctrl.state, _ctrl.player(), _recap_stats))
	var again := Button.new()
	again.custom_minimum_size = Vector2(220, 48)
	again.add_theme_font_size_override("font_size", 18)
	if _online:
		again.text = "BACK TO LOBBY"
		again.pressed.connect(func(): _show_lobby())
	else:
		again.text = "PULL AGAIN"
		again.pressed.connect(func(): _show_select(_seat_key))
	box.add_child(again)

func _title(parent: Node, text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _place(node: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	node.anchor_left = al
	node.anchor_top = at
	node.anchor_right = ar
	node.anchor_bottom = ab
	node.offset_left = ol
	node.offset_top = ot
	node.offset_right = orr
	node.offset_bottom = ob
