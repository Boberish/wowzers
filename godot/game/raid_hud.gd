## Raid HUD (R1 v2 — see RAID-PLAN.md) — THE RIFT: pick ANY of the four seats and
## play it live with three AI raiders. Each seat gets its faithful class band
## (Bulwark orbs/spec/Challenge · Twinfang rhythm/Flow · Voidcaller cast-bar/kick
## · Mender click-cast triage), around a shared raid grammar: boss plate + dial,
## reliquary party frames (gold-lit = the boss's current victim), aggro banners.
## Screens: seat/boss select -> Combat -> End. Single Seal, no draft.
extends Control

const SEAT_IDX := {"tank": 0, "blade": 1, "caster": 2, "healer": 3}
const SEAT_CLASS := {"tank": "bulwark", "blade": "twinfang", "caster": "voidcaller", "healer": "mender"}
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

## The SECOND healer's Aspects. The healer SEAT can be a Mender (ASPECTS["healer"]) or a
## Bloomweaver (below) — `_healer_cls` decides which pair the ceremony/toggles show.
static var BLOOM_ASPECTS := [
	{"id": "wildgrove", "name": "WILDGROVE", "accent": Palette.VERDANCE, "icon": "wildbloom",
		"desc": "RIPEN the garden: tend Growths to the harvest window, BLOOM them for burst, light Flourish across the raid."},
	{"id": "thornveil", "name": "THORNVEIL", "accent": Palette.THORN, "icon": "briarheart",
		"desc": "SNAP-STREAK wards: each Perfect Ward ramps the thorns that reflect damage back — heal by hurting the boss."},
]

## The Aspect pair for a seat, honouring the healer's chosen CLASS.
func _aspects_for(seat_key: String) -> Array:
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return BLOOM_ASPECTS
	return ASPECTS[seat_key]

## The Aspect pair for a lobby seat given an explicit class (online — the healer
## claimant may be a Mender or a Bloomweaver, independent of this client's _healer_cls).
func _lobby_aspects(seat_key: String, cls: String) -> Array:
	if seat_key == "healer" and cls == "bloomweaver":
		return BLOOM_ASPECTS
	return ASPECTS[seat_key]

## The seat's display name, honouring the healer class (Mender vs Bloomweaver).
func _seat_display_name(seat_key: String) -> String:
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return "THE BLOOMWEAVER"
	return String(SEAT_NAMES.get(seat_key, "RAIDER"))

## The class currently filling a seat (only the healer seat is polymorphic).
func _seat_cls_now() -> String:
	return _healer_cls if _seat_key == "healer" else String(SEAT_CLASS.get(_seat_key, "bulwark"))

## The spec's per-seat cfg for the human seat (carries its class so RaidNet builds the
## right kit + the lobby/sim/net all agree). Non-healer seats keep their native class.
func _human_seat_cfg() -> Dictionary:
	_sync_healer_cls()
	return {_seat_key: {"aspect": _aspect, "ai": false, "cls": _seat_cls_now()}}

## Keep _healer_cls consistent with the chosen aspect (the aspect uniquely identifies
## the healer class), so any entry path — normal ceremony or a debug autostart — agrees.
## No-op for non-healer seats; safe to call anytime after _aspect is set.
func _sync_healer_cls() -> void:
	if _seat_key != "healer":
		return
	if _aspect == "wildgrove" or _aspect == "thornveil":
		_healer_cls = "bloomweaver"
	elif _aspect == "tidecaller" or _aspect == "brinkwarden":
		_healer_cls = "mender"

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
var _pause: PauseOverlay = null     ## the in-combat pause menu + class codex (null = not paused)
var _net: NetClient = null
var _online: bool = false
var _online_map: bool = false      ## MAP-3b: an online Topology DESCENT is in progress
var _map_is_leader: bool = false   ## MAP-3b: am I the route-picker (server host)?
var _room: Dictionary = {}
var _my_ready: bool = false
var _net_status: Label = null
var _seat_key: String = "tank"
var _aspect: String = "warden"
var _enc_id: String = "riftmaw"    ## the Seal to pull offline (boss-select / autostart)
var _loadout: Array = []
var _screen: String = "home"

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
var _floor: int = 0                ## which RaidContent.FLOORS entry (the RING descent, MAP-3c)
var _gate_live := false            ## a Tier-1 PERSONAL GATE exam is the current fight (§GAME SHAPE)
var _map_tickets: Dictionary = {}  ## MAP-2: OPEN ticket ids (id -> title) carried this floor
var _map_ticket_total := 0         ## tickets placed on this floor (for the sprint-retro bonus)
var _map_closed := 0               ## tickets closed this floor
var _ticket_toast := ""            ## a one-shot ticket pop, shown on the next map screen

# GEAR-1 (Curios / Realm-1 "peripherals"): run-scoped loot. Items evaporate with the
# run (win or wipe); only Ledger UNLOCKS persist (GearStore). Offline-only in v1 —
# the online campaign spec folds `gear` in later (rides like tickets/inventory).
var _map_gear: Array = []               ## equipped curio ids (≤ Gear.SLOTS)
var _map_gear_charges: Dictionary = {}  ## active-item charges left this run
var _map_tokens := 0                    ## ⏣ fallback bank when no _run exists (see _gain_tokens)
var _gear_unlocks: Dictionary = {}      ## boss_id -> unlocked item ids (Ledger rows)
var _drop_rng: DetRng = null            ## the drop stream — NEVER the combat rng
var _run: RunState = null               ## the human's boon run (Draft 2.0 in the raid descent)
var _taken_boons: Array = []            ## drafted boon dicts (for the build panel: title/rarity)

# GEAR-2 (Sworn Oaths / Realm-1 SLAs): one oath per fight, sworn at the boss node.
var _sworn: Dictionary = {}             ## the CURRENT fight's sworn oath row (+ "boss")
var _oath_result: Dictionary = {}       ## resolved at fight end, consumed by the drop flow
var _oath_broken := false               ## live tracker latch (view-only)
var _oath_lbl: Label = null
var _drop_pity := 0                     ## opus dry-streak counter (purses add ticks)

var _stage: StageBackdrop
var _stage2d: RaidStage2D = null
var _ui: Control
var _fx: Control

# shared combat widgets
var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _meter: MeterPanel          # the raid DPS/HPS meter (M cycles views)
var _recap_stats := {}          # view-side fight tallies for THE RECKONING
var _frames: Array = []            ## [{seat, frame}]
var _aggro_warn: Label
var _shake_root: Control
var _shake_amt: float = 0.0
var _dmg_i: int = 0                 # rotating spawn-lane counter for damage numbers

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
var _spec_strip: SpecStrip         ## healer (Mender)
var _castbar: CastChannel          ## healer
var _mcfg: MenderConfig            ## healer (Mender)
var _bcfg: BloomweaverConfig       ## healer (Bloomweaver)
var _verd: VerdanceGauge           ## healer (Bloomweaver spec gauge)
var _healer_cls: String = "mender" ## which class fills the healer seat: mender | bloomweaver
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
	_local_ctrl.encounter_ended.connect(_on_end_moment)
	_net_ctrl = NetCombatController.new()
	add_child(_net_ctrl)
	_net_ctrl.encounter_ended.connect(_on_end_moment)
	_ctrl = _local_ctrl
	_show_home()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart=gate"):
			# --autostart=gate[:seat[:aspect]]  → straight into that seat's GATE exam
			# (no map context: the end screen closes it — a dev/verify entry)
			var gspec := a.substr("--autostart=".length()).split(":")
			_seat_key = gspec[1] if gspec.size() > 1 and SEAT_IDX.has(gspec[1]) else "tank"
			_aspect = gspec[2] if gspec.size() > 2 else String((ASPECTS[_seat_key][0] as Dictionary)["id"])
			_launch_gate_fight()
		elif a.begins_with("--autostart=raidmap"):
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
	_pause = null                   # the overlay is a _ui child — freed below; drop the freeze
	if _ctrl != null:
		_ctrl.paused = false
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT
## The one game front door (ONE GAME · ONE HUD, see MASTER-PLAN §GAME SHAPE): PLAY the
## raid campaign (solo-with-AI) or PLAY ONLINE (co-op). No mode select, no solo split.
func _show_home() -> void:
	_screen = "home"
	_map = null
	_map_pending = false
	_gate_live = false
	_online_map = false
	_run = null                       # no descent = no boon run (fresh one per descent)
	_clear()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_place(box, 0.5, 0.5, 0.5, 0.5, -260, -230, 260, 250)
	_ui.add_child(box)
	var t := _title(box, "THE RIFT", 76, Palette.GOLD)
	t.add_theme_font_override("font", UiKit.title(900))
	_title(box, "REALM 1 · THE TAKEOVER", 15, Palette.TEXT_DIM)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	box.add_child(gap)
	box.add_child(_menu_button("▶    PLAY", Palette.GOLD_BRIGHT, _show_class_select))
	box.add_child(_menu_button("🌐    PLAY ONLINE", Palette.FLOW, _show_online))
	box.add_child(_menu_button("QUIT", Palette.TEXT_DIM, func(): get_tree().quit()))

func _menu_button(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(330, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", accent)
	b.pressed.connect(cb)
	return b

## PLAY → pick your CLASS (the four raid seats; you play one, AI fills the rest).
func _show_class_select() -> void:
	_screen = "class"
	_map = null
	_map_pending = false
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -420, 120, 420, 205)
	_ui.add_child(head)
	var hl := _title(head, "CHOOSE YOUR CLASS", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "you play one · AI raiders fill the other three seats", 14, Palette.TEXT_DIM)
	# [seat, class, name, icon, accent, blurb] — the healer SEAT has two classes
	# (Mender / Bloomweaver), so five cards map onto the four seats.
	var cards := [
		["tank", "bulwark", "THE BULWARK", "guard", Palette.STEEL, "TANK · MITIGATE — hold its gaze, parry its swings, CHALLENGE it back.  (Warden / Juggernaut)"],
		["blade", "twinfang", "THE TWINFANG", "flurry", Palette.FLOW, "MELEE · DRIVE THE RHYTHM — perfect your strikes, never out-threat the tank.  (Tempo / Venomancer)"],
		["caster", "voidcaller", "THE VOIDCALLER", "overload", Palette.KICK, "CASTER · INTERRUPT — kick the boss's chants on the clean beat.  (Disruptor / Silencer)"],
		["healer", "mender", "THE MENDER", "surge", Palette.WIN, "HEALER · KEEP-ALIVE — react to the storm, click-cast big heals + shields.  (Tidecaller / Brinkwarden)"],
		["healer", "bloomweaver", "THE BLOOMWEAVER", "wildbloom", Palette.VERDANCE, "HEALER · ANTICIPATE — no mana; plant HoTs & wards AHEAD, bloom them on the spike.  (Wildgrove / Thornveil)"],
	]
	# AspectCard is a WIDE 680px card — STACK them vertically (a row runs off-screen).
	# Matches the aspect ceremony's vertical layout; five fit the centered column.
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	_place(col, 0.5, 0.5, 0.5, 0.5, -350, -320, 350, 320)
	_ui.add_child(col)
	for c in cards:
		var card := AspectCard.new(String(c[2]), String(c[5]), c[4], String(c[3]))
		card.chosen.connect(_pick_class.bind(String(c[0]), String(c[1])))
		col.add_child(card)
	var back := Button.new()
	back.text = "◂ back"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(back, 0.5, 1, 0.5, 1, -80, -78, 80, -44)
	back.pressed.connect(_show_home)
	_ui.add_child(back)

## SUB-CLASS chosen → pick your RAID (one for now: Realm 1). Future realms add cards here.
func _show_raid_select(seat_id: String, aspect: String) -> void:
	_screen = "raidpick"
	_seat_key = seat_id
	_aspect = aspect
	_map_pending = false
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -420, 120, 420, 210)
	_ui.add_child(head)
	var hl := _title(head, "CHOOSE YOUR RAID", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "%s · %s" % [SEAT_NAMES.get(seat_id, "RAIDER"), aspect.capitalize()], 14, Palette.TEXT_DIM)
	var mid := CenterContainer.new()
	_place(mid, 0.5, 0.5, 0.5, 0.5, -360, -150, 360, 150)
	_ui.add_child(mid)
	var card := AspectCard.new("REALM 1 · THE TAKEOVER",
		"The ironic AI takeover. Descend the Topology, Ring 3 → 0 — MISTRAL → GEMINI → CLAUDE MYTHOS. Route the node map, carry your wounds, draft your build. (More realms to come.)",
		Palette.CRIMSON, "")
	card.chosen.connect(func(): _start_map_run())
	mid.add_child(card)
	var back := Button.new()
	back.text = "◂ back to aspect"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(back, 0.5, 1, 0.5, 1, -110, -78, 110, -44)
	back.pressed.connect(func(): _show_aspect_pick(seat_id))
	_ui.add_child(back)

## Legacy entry point — every fight-end / Esc / "leave" call routes here. Now it just
## returns to the one HOME menu (the old dev BossSelect front door is retired).
func _show_select(_seat: String = "tank") -> void:
	_show_home()

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

## Class-select card chosen. For the healer seat this also records WHICH healer class
## (mender / bloomweaver) — the rest of the flow reads _healer_cls to pick aspects/band.
func _pick_class(seat_id: String, cls: String) -> void:
	if seat_id == "healer":
		_healer_cls = cls
	_show_aspect_pick(seat_id)

func _show_aspect_pick(seat_id: String) -> void:
	_screen = "aspect"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -420, 150, 420, 260)
	_ui.add_child(head)
	var hl := _title(head, _seat_display_name(seat_id), 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "C H O O S E   Y O U R   A S P E C T", 15, Palette.TEXT_DIM)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	_place(box, 0.5, 0.5, 0.5, 0.5, -340, -130, 340, 130)
	_ui.add_child(box)
	for a in _aspects_for(seat_id):
		var card := AspectCard.new(String(a["name"]), String(a["desc"]), a["accent"], String(a["icon"]))
		card.chosen.connect(_show_raid_select.bind(seat_id, String(a["id"])))
		box.add_child(card)

	var back := Button.new()
	back.text = "◂ back to classes"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(back, 0.5, 1, 0.5, 1, -110, -90, 110, -56)
	back.pressed.connect(_show_class_select)
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
	_net.map_update.connect(_on_net_map)        # MAP-3b
	_net.map_stop.connect(_on_net_mapstop)
	_net.campaign_ended.connect(_on_net_campaign)
	_net.draft_prompt.connect(_on_net_draft)    # online boons

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
	_online_map = false               # MAP-3b: back in the lobby = not descending
	_run = null                       # online descents rebuild the boon run from the map seed
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
		var seat_disp := String(SEAT_NAMES[key])
		if key == "healer":       # the healer seat is Mender OR Bloomweaver
			seat_disp = "THE BLOOMWEAVER" if String(claimant.get("cls", "")) == "bloomweaver" else "THE MENDER"
		lab.text = "%-14s %s" % [seat_disp, who]
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
			if key == "healer":     # toggle the healer CLASS (Mender ⇄ Bloomweaver)
				var mycls := String(me.get("cls", "mender"))
				var clsb := Button.new()
				clsb.text = "◈ " + ("BLOOMWEAVER" if mycls == "bloomweaver" else "MENDER")
				clsb.custom_minimum_size = Vector2(150, 34)
				clsb.pressed.connect(func():
					_net.send({"t": "class", "cls": "mender" if mycls == "bloomweaver" else "bloomweaver"}))
				row.add_child(clsb)
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 34)
			ab.pressed.connect(func():
				var pool: Array = _lobby_aspects(key, String(me.get("cls", "")))
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
		var descend := Button.new()
		descend.text = "🌐  DESCEND"
		descend.custom_minimum_size = Vector2(170, 44)
		descend.add_theme_font_size_override("font_size", 17)
		descend.pressed.connect(func(): _net.send_mapstart())    # MAP-3b: the Topology descent
		ctlrow.add_child(descend)
	_net_status = _title(box, "PULL = one Seal · DESCEND = the Topology campaign (leader routes) · empty seats fight as AI", 12, Palette.TEXT_DIM)
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
			if you == "healer":
				_healer_cls = String(e.get("cls", "mender"))
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
	# In a DESCENT the server drives what comes next (a `map`/`campaign` message is
	# already inbound) — don't pop a single-fight end screen. A plain single-Seal pull
	# still shows its end. (Server-side aborts the replica never reached also caught.)
	if _online_map:
		return
	if _screen == "combat" and (_ctrl.state == null or not _ctrl.state.over):
		_show_end(won)

# ============================================================ ONLINE MAP (MAP-3b)
## The server owns the campaign and broadcasts it; we render its snapshot. Only the
## LEADER (server host) gets clickable nodes — everyone else watches the route.
func _on_net_map(msg: Dictionary) -> void:
	_online_map = true
	_map_is_leader = int(msg.get("host", -1)) == _net.peer_id()
	# online boons: on the FIRST map of the descent, start this seat's boon run — seeded
	# from the descent seed so its draft offers are reproducible (offline uses the same).
	if _run == null:
		var me := _me()
		if not me.is_empty():
			_seat_key = String(me.get("seat", _seat_key))
			_aspect = String(me.get("aspect", _aspect))
		_run = _make_run()
		_taken_boons = []
		var sd := int(msg.get("seed", 1))
		_run.draft_rng = DetRng.new((sd ^ (int(SEAT_IDX.get(_seat_key, 0)) * 2654435761)) & 0x7FFFFFFF)
	_screen = "map"
	_clear()
	var m := RunMap.from_dict(msg.get("map", {}))
	var ms := MapScreen.new()
	ms.map = m
	ms.current = int(msg.get("node", -1))
	ms.inventory = msg.get("inv", {})
	ms.hp_frac = _avg_frac(msg.get("fracs", []))
	ms.subtitle = String(msg.get("title", ""))
	ms.ring = int(msg.get("ring", -1))
	ms.open_tickets = msg.get("tickets", [])
	ms.toast = String(msg.get("toast", ""))
	ms.interactive = _map_is_leader
	if _map_is_leader:
		ms.node_entered.connect(func(id: int): _net.send_node(id))
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)
	if not _map_is_leader:
		var wait := _title(_ui, "◍  the leader is choosing the route…", 15, Palette.GOLD_DIM)
		_place(wait, 0.5, 0, 0.5, 0, -260, 946, 260, 976)

func _avg_frac(fracs: Array) -> float:
	if fracs.is_empty():
		return 1.0
	var t := 0.0
	for f in fracs:
		t += float(f)
	return t / float(fracs.size())

## An event panel: the LEADER picks a choice (sent to the server); others read it.
func _on_net_mapstop(msg: Dictionary) -> void:
	_online_map = true
	_screen = "mapstop"
	_clear()
	if _map_is_leader:
		var p := MapEventPanel.new()
		p.title_text = String(msg.get("title", ""))
		p.body_text = String(msg.get("body", ""))
		var choices: Array = []
		var i := 0
		for c in msg.get("choices", []):
			choices.append({"label": String((c as Dictionary).get("label", "")), "fx": {"_i": i}})
			i += 1
		p.choices = choices
		p.accent = Palette.VOID
		p.finished.connect(func(fx: Dictionary): _net.send_choice(int(fx.get("_i", 0))))
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ui.add_child(p)
	else:
		# spectator: read-only title + body, no choices
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ui.add_child(center)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 16)
		center.add_child(box)
		_title(box, String(msg.get("title", "")), 30, Palette.GOLD)
		var body := _title(box, String(msg.get("body", "")), 15, Palette.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(760, 0)
		_title(box, "◍  the leader is deciding…", 14, Palette.GOLD_DIM)

## Online boons: the server asks every human seat to draft. Roll THIS seat's offers,
## take one, send the id, then wait for the raid to finish (the next `map` replaces us).
func _on_net_draft() -> void:
	if _run == null:
		_net.send_pick("")
		return
	var picks := Draft.roll_offers(_run)
	if picks.is_empty():
		_net.send_pick("")
		_show_online_wait("Reforge pool exhausted — waiting for the raid…")
		return
	_screen = "draft"
	_clear()
	var ds := DraftScreen.new(_run, picks, "REFORGE — the kill reshapes your kit",
		"Take one. Your raid is drafting too.", [], Palette.GOLD)
	ds.boon_taken.connect(func(boon: Dictionary):
		Draft.take(_run, boon)
		_taken_boons.append(boon)
		_net.send_pick(String(boon.get("id", "")))
		_show_online_wait("Reforged — waiting for the raid to finish drafting…"))
	_ui.add_child(ds)

func _show_online_wait(msg: String) -> void:
	_screen = "netwait"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	_title(center, msg, 18, Palette.GOLD_DIM)

## The whole descent is over (ROOT cleared, or a wipe) — a campaign end screen.
func _on_net_campaign(won: bool) -> void:
	_online_map = false
	_run = null                    # the descent's boon run is done
	_taken_boons = []
	_screen = "end"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := _title(box, "ROOT ACCESS GRANTED" if won else "THE DESCENT FALLS", 52,
		Palette.WIN if won else Palette.LOSE)
	banner.add_theme_font_override("font", UiKit.title(900))
	_title(box, ("Realm 1 cleared — CLAUDE MYTHOS is unplugged, together." if won
		else "The raid wiped. Reboot, re-ready, and descend again."), 16, Palette.TEXT)
	var again := Button.new()
	again.text = "BACK TO LOBBY"
	again.custom_minimum_size = Vector2(260, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(func(): _show_lobby())
	box.add_child(again)

func _on_desync() -> void:
	if _screen == "combat":
		_show_end(false)
		_set_net_status("desync — see log")

# ============================================================ START / BUILD
func _launch(seat_id: String, aspect: String = "", jump_to: String = "") -> void:
	_gate_live = false
	# debug alias: a "bloom"/"bloomweaver" seat token = the healer seat as a Bloomweaver
	if seat_id == "bloom" or seat_id == "bloomweaver":
		seat_id = "healer"
		_healer_cls = "bloomweaver"
	_seat_key = seat_id if SEAT_IDX.has(seat_id) else "tank"
	# a healer aspect id disambiguates the class (must resolve BEFORE the pool lookup)
	if _seat_key == "healer":
		if aspect == "wildgrove" or aspect == "thornveil":
			_healer_cls = "bloomweaver"
		elif aspect == "tidecaller" or aspect == "brinkwarden":
			_healer_cls = "mender"
	var pool: Array = _aspects_for(_seat_key)
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
	var spec := RaidNet.make_spec(run_seed, _human_seat_cfg(), _enc_id)
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
	_floor = 0
	# integrity / wounds / mana reset ONLY at the start of the whole descent —
	# they carry from ring to ring (a floor Seal down = elevation, not a reset).
	_map_fracs = [1.0, 1.0, 1.0, 1.0]
	_map_wounds = [0.0, 0.0, 0.0, 0.0]
	_map_mana = 1.0
	# GEAR-1: fresh run-scoped loot; the Ledger's permanent unlocks load from disk.
	# Headless (smokes) stays disk-inert — tests inject _gear_unlocks directly.
	_map_gear = []
	_map_gear_charges = {}
	_map_tokens = 0
	_sworn = {}
	_oath_result = {}
	_oath_broken = false
	_drop_pity = 0
	_taken_boons = []
	if DisplayServer.get_name() != "headless":
		_gear_unlocks = GearStore.load_unlocks()
	_drop_rng = DetRng.new(int(Time.get_ticks_usec()) & 0x7FFFFFFF)
	# Draft 2.0: the human's boon run — the 1-of-3 draft fires after each won fight and
	# its picks ride into every pull (AI raiders stay on the verified boon-less comp).
	_run = _make_run()
	_build_floor()

## A minimal RunState for the human seat, just to carry boons + the draft economy
## (class/aspect/draft_rng/tokens/pity). Its encounter chain is ignored — the raid
## drives its own fights; we only borrow the boon pool + Draft 2.0 machinery.
func _make_run() -> RunState:
	_sync_healer_cls()
	match _seat_key:
		"blade": return RunState.start_twinfang(_aspect)
		"caster": return RunState.start_voidcaller(_aspect)
		"healer": return (RunState.start_bloomweaver(_aspect) if _healer_cls == "bloomweaver"
			else RunState.start_mender(_aspect))
		_: return RunState.start(_aspect)

## Fold the human's drafted boons into their seat's kit (kits read `boons` via _b()).
func _inject_boons(seat: Seat) -> void:
	if _run != null and seat != null and seat.kit != null:
		seat.kit.boons = _run.boons

## Generate the current ring's map (RaidContent.FLOORS[_floor]). The party's carried
## integrity/wounds/mana are UNTOUCHED here — only _start_map_run resets them.
func _build_floor() -> void:
	var fl: Dictionary = RaidContent.FLOORS[_floor]
	_map_fights = RaidContent.floor_fights(int(fl["ring"]))
	# every raid floor carries ONE personal GATE exam (Tier 1, §GAME SHAPE); the ROOT
	# floor also gates its Seal behind credential shards (MAP-3c); TICKETS are the quests (MAP-2).
	_map = RunMap.generate(int(Time.get_ticks_usec()) & 0x7FFFFFFF,
		_map_fights.size(), MapContent.raid_event_ids(), {RunMap.KIND_GATE: 1},
		int(fl["shard_req"]), int(fl.get("tickets", 0)))
	_map_node = -1
	_map_inv = {}
	_map_tickets = {}
	_map_ticket_total = _map.tickets.size()
	_map_closed = 0
	_ticket_toast = ""
	_show_map()

## A floor Seal is down → descend one ring (privilege elevation). Past the last
## floor (CLAUDE MYTHOS) = Realm 1 is cleared.
func _advance_floor() -> void:
	_floor += 1
	if _floor >= RaidContent.FLOORS.size():
		_show_campaign_cleared()
	else:
		_build_floor()

func _show_map() -> void:
	_screen = "map"
	_clear()
	var ms := MapScreen.new()
	ms.map = _map
	ms.current = _map_node
	ms.inventory = _map_inv
	ms.hp_frac = _party_integrity()
	ms.subtitle = String(RaidContent.FLOORS[_floor]["title"])
	ms.ring = int(RaidContent.FLOORS[_floor]["ring"])
	ms.open_tickets = _open_ticket_lines()
	ms.toast = _ticket_toast
	_ticket_toast = ""                 # one-shot — clears once shown
	ms.gear_line = _gear_line()
	ms.node_entered.connect(_enter_node)
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)
	# GEAR-1: Cooling Paste — a USE button rides the map while a wound needs it
	if _map_gear.has("cooling_paste") and int(_map_gear_charges.get("cooling_paste", 0)) > 0 \
			and _worst_wound() > 0.0:
		var pb := Button.new()
		pb.text = "USE COOLING PASTE — repair corrupted sectors (%d left)" \
			% int(_map_gear_charges["cooling_paste"])
		pb.add_theme_font_size_override("font_size", 15)
		pb.pressed.connect(func():
			_map_gear_charges["cooling_paste"] = int(_map_gear_charges["cooling_paste"]) - 1
			_apply_map_fx({"repair": true})
			_ticket_toast = "🧴  COOLING PASTE — corrupted sectors repaired"
			_show_map())
		_place(pb, 0.5, 1.0, 0.5, 1.0, -290, -96, 290, -56)
		_ui.add_child(pb)

## Short "still open" lines for the map header (title + where to turn it in).
func _open_ticket_lines() -> Array:
	var out: Array = []
	for tid in _map_tickets:
		out.append(String(_map_tickets[tid]))
	return out

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
	if first_visit and bool(n.get("shard", false)):
		# a credential shard, assembled toward root access (MAP-3c ROOT floor)
		_map_inv["shards"] = int(_map_inv.get("shards", 0)) + 1
	if first_visit:
		_ticket_at(n)
	if first_visit and bool(n["key"]) and not _map_inv.get("api_key", false):
		_map_inv["api_key"] = true
		_map_stop(String(n["name"]), MapContent.KEY_PICKUP,
			[{"label": "TAKE IT", "fx": {"key": true,
				"result": "Authorization acquired. The raid agrees to never speak of where it was taped."}}],
			Palette.GOLD_BRIGHT, _resolve_node.bind(n))
		return
	_resolve_node(n)

## TICKETS (MAP-2): pick one up here, or close it if we're holding the matching one.
## Rewards feed the wound-attrition economy; closing the whole floor = a sprint-retro
## bonus. Toast shows on the next map screen (this node may launch a fight first).
func _ticket_at(n: Dictionary) -> void:
	var topen := String(n.get("ticket_open", ""))
	if topen != "" and not _map_tickets.has(topen):
		var td := MapContent.ticket(topen)
		_map_tickets[topen] = String(td.get("title", "TICKET"))
		_ticket_toast = "📋  %s  —  picked up (turn it in deeper on this lane)" % String(td.get("title", "TICKET"))
	var tclose := String(n.get("ticket_close", ""))
	if tclose != "" and _map_tickets.has(tclose):
		var td2 := MapContent.ticket(tclose)
		_map_tickets.erase(tclose)
		_map_closed += 1
		_apply_map_fx(td2.get("reward", {}))
		if _map_gear.has("ticket_stub"):   # GEAR-1: the stub pays +5% party integrity
			_apply_map_fx({"heal": 0.05})
		_ticket_toast = "✅  %s  —  CLOSED, reward claimed" % String(td2.get("title", "TICKET"))
		if _map_closed >= _map_ticket_total and _map_ticket_total > 0:
			_apply_map_fx(MapContent.SPRINT_RETRO_FX)
			_ticket_toast = "★  SPRINT RETRO — every ticket closed! Sectors repaired, reserves topped."

func _resolve_node(n: Dictionary) -> void:
	match String(n["kind"]):
		RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
			# GEAR-2: the boss's Ledger page offers its oaths before the pull
			var fi := int(n["fight"])
			var enc: EncounterRes = _map_fights[clampi(fi, 0, _map_fights.size() - 1)]
			_offer_oath_then(String(enc.id), _launch_map_fight.bind(fi))
		RunMap.KIND_GATE:
			# Tier-1 PERSONAL GATE (§GAME SHAPE): YOUR seat steps through alone
			var ex: Dictionary = GateContent.exam(_seat_key)
			_map_stop(String(n["name"]), String(ex["body"]),
				[{"label": "STEP THROUGH ALONE", "fx": {"result": String(ex["challenge"])}}],
				Palette.GOLD_BRIGHT,
				_offer_oath_then.bind(String(GATE_ENC[_seat_key]), _launch_gate_fight))
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
	_gate_live = false
	_screen = "combat"
	_clear()
	var enc: EncounterRes = _map_fights[clampi(fi, 0, _map_fights.size() - 1)]
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var spec := RaidNet.make_spec(run_seed, _human_seat_cfg(), String(enc.id))
	var s := RaidNet.build(spec, _seat_key)
	_arm_gear(s.seats[SEAT_IDX[_seat_key]])   # GEAR-1: your curios ride into the pull
	_inject_boons(s.seats[SEAT_IDX[_seat_key]])   # Draft 2.0: your boons ride in too
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
	_spawn_oath_banner()   # GEAR-2: the sworn deed rides the HUD

## A Tier-1 PERSONAL GATE exam (§GAME SHAPE): YOUR seat's class exam, fought alone —
## the class's solo fight, recast to its Realm-1 identity. Carry-in applies only to
## YOUR raid slot (the healer's sandbox allies are phantoms — they carry nothing).
## Losing does NOT end the run: the checkpoint force-reboots you through, WOUNDED.
func _launch_gate_fight() -> void:
	_screen = "combat"
	_clear()
	var seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var s := GateContent.make_state(seed, _seat_key, _aspect, _seat_cls_now())
	_arm_gear(s.seats[0])   # GEAR-1: the exam is fought with your curios on
	_inject_boons(s.seats[0])   # Draft 2.0: boons on for the exam too
	if _map != null:
		var ri: int = SEAT_IDX[_seat_key]
		var u: Seat = s.seats[0]
		u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(_map_wounds[ri]))))
		u.hp = maxf(1.0, roundf(u.hp_max * float(_map_fracs[ri])))
		if u.role == "healer":
			u.resource = roundf(u.resource_max * _map_mana)
	_gate_live = true
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_ctrl = _local_ctrl
	_ctrl.begin(s, 0)
	_spawn_oath_banner()   # GEAR-2: the sworn deed rides the HUD

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

# ---------------------------------------------------------------- GEAR-1 (Curios)

## Which class this seat key plays (gear rows are class-marked by class name).
const SEAT_CLS := {"tank": "bulwark", "blade": "twinfang", "caster": "voidcaller", "healer": "mender"}

## The human seat carries the run's equipped curios into a fight (offline map runs
## only — the seat starts each pull with fresh per-fight gear bookkeeping).
func _arm_gear(u: Seat) -> void:
	u.gear = _map_gear.duplicate()
	u.gear_vars = {}

## Tokens are ONE currency: scrap + oath purses feed the same purse the REFORGE
## boon draft spends (raid-boons' `_run.tokens`). `_map_tokens` stays only as the
## fallback bank for runless dev paths.
func _gain_tokens(n: int) -> void:
	if _run != null:
		_run.tokens += n
	else:
		_map_tokens += n

func _tokens_now() -> int:
	return _run.tokens if _run != null else _map_tokens

# ---------------------------------------------------------------- GEAR-2 (Oaths)

## Gate exams key their Ledger pages by the exam's canonical encounter id.
const GATE_ENC := {"tank": "gatekeeper", "blade": "warden", "caster": "priest", "healer": "rendmaw"}

func _stakes() -> int:
	return 3 - int(RaidContent.FLOORS[_floor]["ring"])   # + (version - 1), when versions exist

## The Ledger page, pre-pull: the boss's rows (locked greyed) + its swearable oaths.
## Swear one — or fight unsworn. Realm-1 skin: oaths render as SLAs.
func _offer_oath_then(boss_id: String, launch: Callable) -> void:
	_sworn = {}
	_oath_result = {}
	_oath_broken = false
	var orows := Oaths.rows(boss_id)
	if orows.is_empty():
		launch.call()
		return
	_screen = "ledger"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var banner := _title(box, "THE LEDGER", 40, Palette.GOLD_BRIGHT)
	banner.add_theme_font_override("font", UiKit.title(900))
	_title(box, "an oath may be sworn before this pull — SLAs are strictly optional", 14, Palette.TEXT_DIM)
	# the page: every row — item name + rarity + WHAT IT DOES + how to unlock it
	var got: Array = _gear_unlocks.get(boss_id, [])
	for r in GearCatalog.table(boss_id):
		var it := GearCatalog.item(String(r["item"]))
		var unlocked: bool = got.has(String(r["item"]))
		var how: String
		if String(r["row"]) == "oath":
			how = "swear its oath below"
		elif unlocked:
			how = "unlocked ✓"
		else:
			how = "first-kill reward"
		# header: name · rarity · how to get it
		_title(box, "%s  %s  ·  %s  ·  %s" % ["◆" if unlocked else "◇",
			String(it["name"]).to_upper(), String(it.get("rarity", "haiku")).to_upper(), how],
			14, Palette.GOLD if unlocked else Palette.TEXT)
		# the EFFECT — so you know exactly what you're chasing (rarity-tinted)
		var eff := _title(box, String(it.get("desc", "")), 12,
			Palette.rarity_color(String(it.get("rarity", "haiku"))))
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff.custom_minimum_size = Vector2(740, 0)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)
	for r2 in orows:
		var row: Dictionary = r2
		var it2 := GearCatalog.item(String(row["item"]))
		var unlocked2: bool = got.has(String(row["item"]))
		var p := Oaths.purse(int(row.get("sev", 1)), _stakes())
		var reward := ("+%d⏣ · the drop leans richer" % int(p["tokens"])) if unlocked2 \
			else "kept = %s joins your Ledger" % String(it2["name"]).to_upper()
		var b := Button.new()
		b.text = "%s  ·  SEV %s  ·  %s   →   %s" % [
			"RE-SWEAR" if unlocked2 else "SWEAR",
			Oaths.sev_label(int(row.get("sev", 1))), String(row.get("deed_text", "")), reward]
		b.add_theme_font_size_override("font_size", 15)
		b.custom_minimum_size = Vector2(760, 42)
		b.pressed.connect(func():
			_sworn = row.duplicate(true)
			_sworn["boss"] = boss_id
			launch.call())
		box.add_child(b)
	var fb := Button.new()
	fb.text = "FIGHT UNSWORN"
	fb.add_theme_font_size_override("font_size", 15)
	fb.custom_minimum_size = Vector2(300, 42)
	fb.pressed.connect(func(): launch.call())
	var cc2 := CenterContainer.new()
	cc2.add_child(fb)
	box.add_child(cc2)

## The in-fight tracker: a quiet banner that turns crimson the moment a monotone
## deed becomes unkeepable (view-only; verdict truth stays at _resolve_oath).
func _spawn_oath_banner() -> void:
	_oath_lbl = null
	if _sworn.is_empty():
		return
	var l := Label.new()
	l.text = "⚖ OATH — %s" % String(_sworn.get("deed_text", ""))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Palette.GOLD)
	_place(l, 0.0, 1.0, 0.0, 1.0, 24, -124, 620, -100)
	_ui.add_child(l)
	_oath_lbl = l

## Verdict at fight end (called from _on_end with the final state, win or lose).
func _resolve_oath(s: CombatState, seat: Seat, won: bool) -> void:
	_oath_result = {}
	if _sworn.is_empty() or s == null or seat == null:
		return
	_oath_result = {"kept": won and Oaths.kept(_sworn.get("deed", {}), s, seat),
		"sev": int(_sworn.get("sev", 1)), "item": String(_sworn.get("item", "")),
		"boss": String(_sworn.get("boss", "")), "text": String(_sworn.get("deed_text", ""))}
	_sworn = {}

## Roll the kill's drop (map mode only), run the ceremony, then continue the run.
## Rolls draw from _drop_rng only — the combat stream never notices loot.
func _after_drop(boss_id: String, done: Callable) -> void:
	if _map == null or _drop_rng == null:
		done.call()
		return
	# GEAR-2: a KEPT oath cashes first — its row joins THIS kill's pool, and the
	# purse bends THIS roll (rarity floor / pity ticks) + banks Tokens.
	var bend: Dictionary = {}
	var verdict := ""
	if not _oath_result.is_empty() and String(_oath_result["boss"]) == boss_id:
		if bool(_oath_result["kept"]):
			var p := Oaths.purse(int(_oath_result["sev"]), _stakes())
			var oid := String(_oath_result["item"])
			var got0: Array = _gear_unlocks.get(boss_id, [])
			var fresh: bool = not got0.has(oid)
			if fresh:
				got0.append(oid)
				_gear_unlocks[boss_id] = got0
				if DisplayServer.get_name() != "headless":
					GearStore.save_unlocks(_gear_unlocks)
			_gain_tokens(int(p["tokens"]))
			_drop_pity += int(p["pity"])
			bend = p
			verdict = "⚖  OATH KEPT — SLA MET: +%d⏣%s" % [int(p["tokens"]),
				"  ·  a new row is inked into the Ledger" if fresh else ""]
		else:
			verdict = "⚖  OATH BROKEN — SLA BREACHED (penalty clauses waived)"
		_oath_result = {}
	# _seat_cls_now(): a Bloomweaver player rolls its OWN class page (parked → no drop)
	var d := Gear.roll(boss_id, _seat_cls_now(), _gear_unlocks, _drop_rng,
		int(RaidContent.FLOORS[_floor]["ring"]), _drop_pity, bend)
	if d.is_empty():
		if verdict != "":
			_toast_add(verdict)
		done.call()
		return
	var id := String(d["item"])
	# pity rides the OUTCOME: an opus drop resets the drought, anything else deepens it
	if String(GearCatalog.item(id).get("rarity", "haiku")) == "opus":
		_drop_pity = 0
	else:
		_drop_pity += 1
	if bool(d["first"]):
		# the SIGNATURE row is inked into the Ledger forever (survives the run)
		var got: Array = _gear_unlocks.get(boss_id, [])
		got.append(id)
		_gear_unlocks[boss_id] = got
		if DisplayServer.get_name() != "headless":
			GearStore.save_unlocks(_gear_unlocks)
	if _map_gear.has(id):
		# a dupe of an equipped curio auto-scraps — Tokens without ceremony
		if verdict != "":
			_toast_add(verdict)
		_gain_tokens(GearCatalog.scrap_value(id))
		_toast_add("⚙  %s — duplicate recycled responsibly (+%d⏣)" % [
			String(GearCatalog.item(id)["name"]), GearCatalog.scrap_value(id)])
		done.call()
		return
	_show_drop(id, bool(d["first"]), done, verdict)

## The drop ceremony: the curio arrives on a tarot card ("PERIPHERAL ACQUIRED");
## EQUIP (2 slots — replacing scraps the old piece) or SCRAP straight to ⏣.
func _show_drop(id: String, first: bool, done: Callable, verdict: String = "") -> void:
	_screen = "drop"
	_clear()
	var it := GearCatalog.item(id)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	if verdict != "":   # GEAR-2: the oath's verdict crowns the ceremony
		_title(box, verdict, 17,
			Palette.WIN if verdict.contains("KEPT") else Palette.CRIMSON)
	var banner := _title(box, "PERIPHERAL ACQUIRED", 42, Palette.GOLD_BRIGHT)
	banner.add_theme_font_override("font", UiKit.title(900))
	if first:
		_title(box, "★  FIRST KILL — a new row is inked into the Ledger", 15, Palette.GOLD)
	var card := RelicCard.new(String(it["name"]),
		String(it["desc"]) + "\n\n\"" + String(it.get("flavor", "")) + "\"",
		"curio", String(it.get("rarity", "haiku")), false, "")
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE   # display only — buttons decide
	var cc := CenterContainer.new()
	cc.add_child(card)
	box.add_child(cc)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if _map_gear.size() < Gear.SLOTS:
		var eb := Button.new()
		eb.text = "EQUIP"
		eb.custom_minimum_size = Vector2(200, 44)
		eb.pressed.connect(func():
			_gear_equip(id, -1)
			done.call())
		row.add_child(eb)
	else:
		# slots full: equipping means choosing which piece the new one replaces
		for si in _map_gear.size():
			var old := String(_map_gear[si])
			var rb := Button.new()
			rb.text = "REPLACE %s  (+%d⏣)" % [
				String(GearCatalog.item(old)["name"]).to_upper(), GearCatalog.scrap_value(old)]
			rb.custom_minimum_size = Vector2(300, 44)
			rb.pressed.connect(func():
				_gear_equip(id, si)
				done.call())
			row.add_child(rb)
	var sb := Button.new()
	sb.text = "SCRAP  (+%d⏣)" % GearCatalog.scrap_value(id)
	sb.custom_minimum_size = Vector2(200, 44)
	sb.pressed.connect(func():
		_gain_tokens(GearCatalog.scrap_value(id))
		done.call())
	row.add_child(sb)

## Equip into a free slot (replace_i = -1) or over an existing piece (which scraps).
func _gear_equip(id: String, replace_i: int) -> void:
	if replace_i >= 0 and replace_i < _map_gear.size():
		var old := String(_map_gear[replace_i])
		_gain_tokens(GearCatalog.scrap_value(old))
		_map_gear_charges.erase(old)
		_map_gear[replace_i] = id
	else:
		_map_gear.append(id)
	var it := GearCatalog.item(id)
	if bool(it.get("active", false)):
		_map_gear_charges[id] = int(it.get("charges", 1))

## The map header's curio strip ("" hides it before the first drop).
func _gear_line() -> String:
	if _map_gear.is_empty() and _tokens_now() == 0:
		return ""
	var names: Array = []
	for g in _map_gear:
		var nm := String(GearCatalog.item(String(g)).get("name", String(g)))
		if _map_gear_charges.has(g):
			nm += " ×%d" % int(_map_gear_charges[g])
		names.append(nm)
	var line := "PERIPHERALS:  " + ("  ·  ".join(PackedStringArray(names)) if not names.is_empty() else "—")
	return line + "      ⏣ %d" % _tokens_now()

func _worst_wound() -> float:
	var w := 0.0
	for x in _map_wounds:
		w = maxf(w, float(x))
	return w

## Stack a gear toast under any pending ticket toast (both show on the next map).
func _toast_add(msg: String) -> void:
	_ticket_toast = msg if _ticket_toast == "" else _ticket_toast + "\n" + msg

## A floor Seal is down (but not the last): PRIVILEGE ELEVATION — descend to the
## next ring carrying the party's integrity/wounds/mana, or bank out to the Rift.
## Draft 2.0 REFORGE (the raid's boon draft): mint Tokens from this fight's skill, then
## offer 1-of-3 (rarity-weighted, synergy slot, build-your-verb pieces). Taking one folds
## it into `_run.boons` — it rides every future pull. Pool exhausted / no run = skip.
func _show_boon_draft(done: Callable) -> void:
	if _run == null:
		done.call()
		return
	if _ctrl != null and _ctrl.state != null:
		_run.tokens += Draft.mint(_ctrl.state, _run.char_class)
	var picks := Draft.roll_offers(_run)
	if picks.is_empty():
		done.call()
		return
	_screen = "draft"
	_clear()
	var extras: Array = []
	if _run.tokens > 0:
		extras.append("%d Tokens banked — REROLL / LOCK a card." % _run.tokens)
	var ds := DraftScreen.new(_run, picks, "REFORGE — the kill reshapes your kit",
		"Take one. The ✦ card resonates with your build.", extras, Palette.GOLD)
	ds.boon_taken.connect(func(boon: Dictionary):
		Draft.take(_run, boon)
		_taken_boons.append(boon)      # for the build panel (title + rarity)
		done.call())
	_ui.add_child(ds)

func _show_floor_cleared() -> void:
	_screen = "end"
	_clear()
	var fl: Dictionary = RaidContent.FLOORS[_floor]
	var nxt: Dictionary = RaidContent.FLOORS[_floor + 1]
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := _title(box, "PRIVILEGE ELEVATED", 52, Palette.WIN)
	banner.add_theme_font_override("font", UiKit.title(900))
	_title(box, String(fl["elev"]), 16, Palette.TEXT)
	_title(box, String((RaidContent.QUIPS.get(String(fl["seal"]), {}) as Dictionary).get("win", "")), 13, Palette.TEXT_DIM)
	var descend := Button.new()
	descend.text = "DESCEND TO %s" % String(nxt["title"])
	descend.custom_minimum_size = Vector2(380, 52)
	descend.add_theme_font_size_override("font_size", 18)
	descend.pressed.connect(_advance_floor)
	box.add_child(descend)
	var leave := Button.new()
	leave.text = "BANK & LEAVE TO THE RIFT"
	leave.custom_minimum_size = Vector2(300, 44)
	leave.add_theme_font_size_override("font_size", 15)
	leave.pressed.connect(func(): _show_select(_seat_key))
	box.add_child(leave)

## The last Seal (CLAUDE MYTHOS at Ring 0) is down — Realm 1, "The Takeover," is over.
func _show_campaign_cleared() -> void:
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
	var banner := _title(box, "ROOT ACCESS GRANTED", 56, Palette.WIN)
	banner.add_theme_font_override("font", UiKit.title(900))
	_title(box, "Ring 0 is yours. CLAUDE MYTHOS is unplugged. THE TAKEOVER ends — Realm 1 cleared.", 17, Palette.TEXT)
	_title(box, String((RaidContent.QUIPS.get("mythos", {}) as Dictionary).get("win", "")), 13, Palette.TEXT_DIM)
	var again := Button.new()
	again.text = "BACK TO THE RIFT"
	again.custom_minimum_size = Vector2(260, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(func(): _show_select(_seat_key))
	box.add_child(again)

func _make_loadout() -> Array:
	_sync_healer_cls()
	match _seat_key:
		"blade":
			return TwinfangConfig.new().loadout(_aspect)
		"caster":
			return VoidcallerConfig.new().loadout(_aspect)
		"healer":
			if _healer_cls == "bloomweaver":
				_bcfg = BloomweaverConfig.new()
				return _bcfg.order(_aspect)
			_mcfg = MenderConfig.new()
			return _mcfg.order(_aspect) + ["revive"]   # RAID adds the battle-rez rune (R)
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
	if _gate_live:
		# the exam: your puppet (plus any sandboxed phantoms) vs the recast checkpoint
		var ex: Dictionary = GateContent.exam(_seat_key)
		_stage2d.setup(s, {}, GateContent.stage_cast(_seat_key, _aspect),
			String(ex.get("actor", "")), String(ex.get("variant", "")))
	else:
		var aspects := {}
		for i in s.seats.size():
			var key: String = RaidNet.SEAT_KEYS[i] if i < RaidNet.SEAT_KEYS.size() else "tank"
			var kit = s.seats[i].kit
			aspects[key] = String(kit.get("aspect")) if kit != null and kit.get("aspect") != null else ""
		_stage2d.setup(s, aspects)
	_stage2d.bind_seats(s.seats)
	_add_dev_tools()
	_add_build_panel()

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

	# the raid meter — right rail: all four raiders ranked, engine-truth accounting;
	# M cycles ranking / your spells / hidden. Works identically offline and online
	# (it only READS state — the lockstep replica never notices it).
	_meter = MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg")
	_place(_meter, 1, 0, 1, 0, -318, 118, -18, 600)
	_ui.add_child(_meter)

	# THE RAID — reliquary frames down the left. Gold-lit = the boss's victim;
	# for the Mender seat the frames are also your click-cast targets.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_place(col, 0, 0.5, 0, 0.5, 26, -220, 210, 220)
	_ui.add_child(col)              # NOT under shake — the healer aims clicks at these
	var head := Label.new()
	head.text = "THE RAID   ·   ◆ = its gaze" if _seat_key != "healer" else "THE RAID   ·   hover + click-cast"
	if _gate_live:
		head.text = "THE EXAM   ·   the raid watches" if _seat_key != "healer" \
			else "THE SANDBOX   ·   hover + click-cast"
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
	_add_pause_button()

## The PAUSE button (top-right). Always available in real play (offline freezes the
## fight, online just opens the guide); hidden only in headless (sims/smokes drive
## _toggle_pause directly). It's the entry to the Class Codex — the playtest cheat-sheet.
func _add_pause_button() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var pb := Button.new()
	pb.text = "PAUSE  (P)"
	pb.add_theme_font_size_override("font_size", 12)
	pb.modulate = Color(1.0, 1.0, 1.0, 0.72)
	pb.pressed.connect(_toggle_pause)
	_place(pb, 1, 0, 1, 0, -150, 14, -18, 46)
	_ui.add_child(pb)

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
	_challenge = null
	if not _gate_live:                 # Challenge is a raid verb — no one to taunt off at a gate
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
	_hint_line("SPACE — %s    ·    F — DODGE beats%s" % [_verb(),
		"" if _gate_live else "    ·    T — CHALLENGE (taunt)"])

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
	if _healer_cls == "bloomweaver":
		_build_band_bloomweaver()
		return
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

## The SECOND healer's band: Sap orb + Blooming Medallion (Verdance) + benediction cast
## channel + the Growth/ward rune rail. No mana, no Reservoir/Nerve strip — the whole
## class is planted AHEAD and bloomed on the spike (click-cast the frames, same as Mender).
func _build_band_bloomweaver() -> void:
	_binds = BloomweaverBinds.load_binds()
	_hp_orb = _orb(Palette.SAP.darkened(0.2), "SAP", false)   # Sap — Bloomweaver has no mana
	_verd = VerdanceGauge.new()
	_verd.aspect = _aspect
	_verd.verdance_max = _bcfg.verdance_max
	_verd.min_spend = _bcfg.verd_min_spend
	_place(_verd, 0.5, 1, 0.5, 1, -300, -298, 300, -168)
	_shake_root.add_child(_verd)
	_castbar = CastChannel.new()
	_castbar.accent = Palette.VERDANCE
	_place(_castbar, 0.5, 1, 0.5, 1, -240, -358, 240, -298)
	_shake_root.add_child(_castbar)
	var row := _rune_row(-320.0, 320.0)
	_runes = []
	_rune_ids = []
	for id in _loadout:
		var sp: Dictionary = _bcfg.spells.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		if sp.has("spec"):
			rune.accent = Palette.VERDANCE if _aspect == "wildgrove" else Palette.THORN
		rune.custom_minimum_size = Vector2(62, 62)
		rune.pressed.connect(_cast.bind(String(id)))
		row.add_child(rune)
		_runes.append(rune)
		_rune_ids.append(id)
	_hint_line(_healer_hint())

## DEV TOOL: an instant-WIN button to test the post-fight flow (drops, floor advance,
## ring elevation, campaign clear) without grinding each fight. Debug/source builds
## only, and OFFLINE only — killing the boss locally in an online lockstep fight would
## desync every replica. Auto-hidden in headless (sims/smokes) and release exports.
func _add_dev_tools() -> void:
	if _online or DisplayServer.get_name() == "headless" or not OS.is_debug_build():
		return
	var win := Button.new()
	win.text = "DEV ▶ WIN"
	win.add_theme_font_size_override("font_size", 12)
	win.modulate = Color(1.0, 1.0, 1.0, 0.5)
	win.pressed.connect(_dev_win)
	_place(win, 0, 0, 0, 0, 14, 14, 116, 44)     # top-left corner, out of the way
	_ui.add_child(win)

func _dev_win() -> void:
	if _ctrl == null or _ctrl.state == null or _ctrl.state.over:
		return
	var s: CombatState = _ctrl.state
	# overkill the boss (and any active add) — the normal update loop then resolves
	# the win exactly like a real kill, so drops/floor-advance run unchanged.
	CombatCore.damage_boss(s, s.seats[0], s.boss.hp + s.boss.hp_max + 1.0)

## The player's assembled verb, in the class's own words (build-your-verb boons).
const VERB_LABEL := {"tank": "GUARD", "blade": "RHYTHM", "caster": "KICK", "healer": "TRIAGE"}

## The verb label shown on the build panel (Bloomweaver's verb is the GARDEN).
func _verb_label() -> String:
	if _seat_key == "healer" and _healer_cls == "bloomweaver":
		return "GARDEN"
	return String(VERB_LABEL.get(_seat_key, "BUILD"))

func _verb_summary_lines() -> Array:
	if _run == null:
		return []
	match _seat_key:
		"blade": return TwinfangBoons.verb_summary(_run.boons, _aspect)
		"caster": return VoidcallerBoons.verb_summary(_run.boons, _aspect)
		"healer": return (BloomweaverBoons.verb_summary(_run.boons, _aspect) if _healer_cls == "bloomweaver" else MenderBoons.verb_summary(_run.boons, _aspect))
		_: return BulwarkBoons.guard_summary(_run.boons, _aspect)

## BUILD PANEL: a compact top-right readout of the assembled verb + drafted boons —
## so you can always see the run you've drafted. Offline descent only (_run present;
## online boons ride the spec later). Rebuilt each fight, so it reflects new picks.
func _add_build_panel() -> void:
	if _run == null:               # online + offline descents both carry a boon run now
		return
	var lines := _verb_summary_lines()
	if _taken_boons.is_empty() and lines.is_empty():
		return                                    # nothing drafted yet
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.BG0, 0.74)
	sb.border_color = Color(Palette.GOLD_DIM, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	frame.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	frame.add_child(col)
	var hdr := Label.new()
	hdr.text = "◆  YOUR %s" % _verb_label()
	hdr.add_theme_font_size_override("font_size", 14)
	hdr.add_theme_color_override("font_color", Palette.GOLD)
	col.add_child(hdr)
	for l in lines:
		var lbl := Label.new()
		lbl.text = "·  " + String(l)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Palette.TEXT)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(276, 0)
		col.add_child(lbl)
	if not _taken_boons.is_empty():
		var cap := Label.new()
		cap.text = "BOONS  ·  %d" % _taken_boons.size()
		cap.add_theme_font_size_override("font_size", 10)
		cap.add_theme_color_override("font_color", Palette.GOLD_DIM)
		col.add_child(cap)
		for b in _taken_boons:
			var bd: Dictionary = b
			var bl := Label.new()
			bl.text = "•  " + String(bd.get("title", "?"))
			bl.add_theme_font_size_override("font_size", 11)
			bl.add_theme_color_override("font_color", Palette.rarity_color(String(bd.get("rarity", "haiku"))))
			col.add_child(bl)
	_ui.add_child(frame)
	# TOP-LEFT (below the dev button, above the party frames) — the top-right is the
	# DPS meter's. Grows DOWN as the build fills out (content-sized height).
	frame.anchor_left = 0.0
	frame.anchor_top = 0.0
	frame.anchor_right = 0.0
	frame.anchor_bottom = 0.0
	frame.grow_horizontal = Control.GROW_DIRECTION_END
	frame.grow_vertical = Control.GROW_DIRECTION_END
	frame.offset_left = 14
	frame.offset_right = 320
	frame.offset_top = 56
	frame.offset_bottom = 56

# ============================================================ PAUSE + CLASS CODEX
## Open/close the pause menu. OFFLINE freezes the fight (`CombatController.paused`);
## ONLINE never freezes a lockstep replica — the guide just opens over the running fight.
func _toggle_pause() -> void:
	if _screen != "combat":
		return
	if _pause != null:
		_resume_pause()
		return
	if not _online and _ctrl != null:
		_ctrl.paused = true
	_pause = PauseOverlay.new(SEAT_CLASS.get(_seat_key, "bulwark"), _aspect,
		_owned_boon_labels(), not _online)
	_pause.resumed.connect(_resume_pause)
	_pause.quit_to_menu.connect(_pause_quit)
	_ui.add_child(_pause)

func _resume_pause() -> void:
	if _ctrl != null:
		_ctrl.paused = false
	if _pause != null and is_instance_valid(_pause):
		_pause.queue_free()
	_pause = null

func _pause_quit() -> void:
	# one HUD: "quit to menu" returns to the HOME screen (the retired main.tscn is gone)
	_resume_pause()
	if _net != null:
		_net.close()
	_online = false
	_show_home()

## The boons the human seat has drafted, resolved to {title,rarity,type} for the codex
## header. Only the map/campaign run carries a boon pool (`_run`); a bare Seal pull has
## none → []. Scans the current class's boon pools by id.
func _owned_boon_labels() -> Array:
	if _run == null or _run.boons.is_empty():
		return []
	var pools: Array = []
	match _seat_key:
		"blade": pools = [TwinfangBoons.SHARED, TwinfangBoons.TEMPO, TwinfangBoons.VENOM]
		"caster": pools = [VoidcallerBoons.SHARED, VoidcallerBoons.DISRUPTOR, VoidcallerBoons.SILENCER]
		"healer": pools = ([BloomweaverBoons.SHARED, BloomweaverBoons.GROVE, BloomweaverBoons.THORN] if _healer_cls == "bloomweaver" else [MenderBoons.SHARED, MenderBoons.TIDE, MenderBoons.BRINK])
		_: pools = [BulwarkBoons.SHARED, BulwarkBoons.WARDEN, BulwarkBoons.JUGG]
	var out: Array = []
	for pool in pools:
		for b in pool:
			if _run.boons.get(String(b.get("id", "")), false):
				out.append({"title": b.get("title", b.get("id", "?")),
					"rarity": b.get("rarity", "haiku"), "type": b.get("type", "")})
	return out

func _healer_hint() -> String:
	var bloom := _healer_cls == "bloomweaver"
	var chords: Array = BloomweaverBinds.CHORDS if bloom else MenderBinds.CHORDS
	var shorts: Dictionary = BloomweaverBinds.CHORD_SHORT if bloom else MenderBinds.CHORD_SHORT
	var parts: Array = []
	for chord in chords:
		var id := String(_binds.get(chord, "none"))
		if id != "none":
			parts.append("%s=%s" % [shorts.get(chord, chord), id.capitalize()])
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
		# pause menu open: Esc / P resume, everything else is swallowed (fight frozen)
		if _pause != null:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
				_resume_pause()
			return
		if event.keycode == KEY_ESCAPE:
			if _screen == "combat":
				_toggle_pause()      # Esc in a fight = PAUSE (Quit-to-menu lives inside it)
				return
			if _net != null:
				_net.close()
			get_tree().change_scene_to_file("res://game/main.tscn")
			return
		if _screen != "combat":
			return
		if event.keycode == KEY_P:
			_toggle_pause()
			return
		if event.keycode == KEY_M and _meter != null:
			_meter.cycle()
			return
		match _seat_key:
			"healer":
				_healer_key(event.keycode)
			_:
				_martial_key(event.keycode)
		return
	# Mender click-cast: hover a frame, click a chord
	if _pause == null and _seat_key == "healer" and _screen == "combat" \
			and event is InputEventMouseButton and event.pressed and _hover_seat != null:
		var id := String(_binds.get(_mouse_chord(event), "none"))
		if id == "signature":
			id = _signature()
		if id != "none" and _hspells().has(id):
			_focus_seat = _hover_seat
			_cast_on(_hover_seat, id)

func _martial_key(code: int) -> void:
	match code:
		KEY_SPACE:
			_ctrl.human({"type": "defense"})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_T:
			if _seat_key == "tank" and not _gate_live:
				_ctrl.human({"type": "ability", "id": "challenge"})
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_5: _use_ability(4)

## The healer's spellbook for the current class (Mender mana spells / Bloomweaver Sap).
func _hspells() -> Dictionary:
	if _healer_cls == "bloomweaver":
		return _bcfg.spells if _bcfg != null else {}
	return _mcfg.spells if _mcfg != null else {}

func _healer_key(code: int) -> void:
	if _healer_cls == "bloomweaver":
		_bloomweaver_key(code)
		return
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
		KEY_R: _cast("revive")             # battle-rez: hover a FALLEN raider's frame, press R

## Bloomweaver keys: 1-4 Growth/Barkskin/Overgrowth/Thornlash · Q Sap Rot · E Lifesurge
## · 7 the aspect signature. SPACE/F dodges (cancels an Overgrowth cast — the discipline).
func _bloomweaver_key(code: int) -> void:
	match code:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1: _cast("growth")
		KEY_2: _cast("bark")
		KEY_3: _cast("overgrowth")
		KEY_4: _cast("lash")
		KEY_Q: _cast("saprot")
		KEY_E: _cast("lifesurge")
		KEY_7: _cast(_signature())

func _use_ability(i: int) -> void:
	if _screen == "combat" and i >= 0 and i < _rune_ids.size():
		_ctrl.human({"type": "ability", "id": _rune_ids[i]})

func _signature() -> String:
	if _healer_cls == "bloomweaver":
		return "wildbloom" if _aspect == "wildgrove" else "briarheart"
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
	if _screen != "combat":
		return
	var sp: Dictionary = _hspells().get(id, {})
	if sp.is_empty():
		return
	var target: Seat = null
	if bool(sp.get("target", false)):
		target = _hover_seat if _hover_seat != null else _focus_seat
		if id == "revive":
			if target == null or target.alive():   # battle-rez needs a DEAD hovered ally
				return
		elif target == null or not target.alive():
			return
	_ctrl.human({"type": "ability", "id": id, "target": target})

## Mirror the engine's gates so a click flashes gold (accepted) or dim (blocked).
func _cast_on(seat: Seat, id: String) -> void:
	if _healer_cls == "bloomweaver":
		_cast_on_bloom(seat, id)
		return
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

## Bloomweaver click-cast: mirror the Sap/Verdance/garden gates for the gold/dim flash.
func _cast_on_bloom(seat: Seat, id: String) -> void:
	var s := _ctrl.state
	var p := _ctrl.player()
	var sp: Dictionary = _bcfg.spells.get(id, {})
	if sp.is_empty():
		return
	var offgcd := bool(sp.get("offgcd", false))
	var ready := true
	if not offgcd and s.tick < p.gcd_until_tick: ready = false
	if s.tick < int(p.cooldowns.get(id, 0)): ready = false
	if not offgcd and not p.casting.is_empty(): ready = false
	if p.resource < float(sp.get("sap", 0.0)): ready = false
	if id == "saprot" and seat.debuff.is_empty(): ready = false
	if sp.has("spec") and float(p.vars.get("verdance", 0.0)) < _bcfg.verd_min_spend: ready = false
	if id == "lifesurge" and int(CombatCore.observe(s, p).get("garden", 0)) <= 0: ready = false
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

	# GEAR-2: the oath tracker turns the moment a monotone deed becomes unkeepable
	if _oath_lbl != null and not _oath_broken and not _sworn.is_empty() and p != null \
			and Oaths.broken_live(_sworn.get("deed", {}), s, p):
		_oath_broken = true
		_oath_lbl.text = "⚖ OATH BROKEN — %s" % String(_sworn.get("deed_text", ""))
		_oath_lbl.add_theme_color_override("font_color", Palette.CRIMSON)
		_big_text("OATH BROKEN", Palette.CRIMSON, 34, 0.9)

	var live_add := _active_add(s)
	if live_add != null:
		_bar.boss_name = live_add.name
		_bar.hp = s.boss.add_hp
		_bar.hp_max = s.boss.add_hp_max
	else:
		_bar.boss_name = s.encounter.name
		_bar.hp = s.boss.hp
		_bar.hp_max = s.boss.hp_max
	_bar.phase_num = BossBar.phase_index(s)
	if _bar.phase_ats.is_empty():	# immutable per fight; set once (bar is fresh each fight)
		_bar.phase_ats = s.encounter.phases.map(func(ph): return ph.at)
	_bar.enrage_in = (s.encounter.enrage_at - float(s.tick) * s.dt) if s.encounter.enrage_at > 0.0 else INF
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
		fr.ripe = false                      # Bloomweaver drives this per-frame below
		if _seat_key == "healer":
			fr.is_target = (seat == _hover_seat) or (_hover_seat == null and seat == _focus_seat)
		else:
			fr.is_target = seat == victim and seat.alive()
	if _seat_key == "healer":
		_healer_predictions(s, obs)
	# aggro banner (a gate exam has no threat game — you're alone with it)
	if _gate_live:
		_aggro_warn.visible = false
		return
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

## Healer-only frame overlays: telegraphed incoming damage + (Mender) the cast's heal
## ghost / (Bloomweaver) Growth ripeness on every frame + the BLOOM cash-out on hover.
func _healer_predictions(s: CombatState, obs: Dictionary) -> void:
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
	# Bloomweaver: Growth ripeness on every frame (gold gem) + the BLOOM value a
	# double-tap would cash right now, ghosted on the hovered frame.
	if _healer_cls == "bloomweaver":
		for pe in obs.get("party", []):
			var u: Seat = pe.get("seat")
			if u == null:
				continue
			var frp := _frame_of(u)
			if frp == null:
				continue
			frp.ripe = bool(pe.get("ripe", false))
			if u == _hover_seat and u.hp_max > 0.0:
				frp.incoming_frac = clampf(float(pe.get("growth_heal", 0.0)) / u.hp_max, 0.0, 1.0)
		return
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
	if _challenge != null:             # absent at a GATE exam (raid verb)
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
	_rhythm.scale_ticks = int(obs.get("rhythm_scale", 33))   # fixed ruler → accelerando visible
	_rhythm.flow = int(obs.get("flow", 0)) if String(obs.get("aspect", "")) == "tempo" else 0
	_rhythm.flow_max = int(obs.get("flow_max", 6))
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
	if _healer_cls == "bloomweaver":
		_render_band_bloomweaver(s, p, obs)
		return
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

func _render_band_bloomweaver(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.resource, _bcfg.sap_max)
	_verd.verdance = float(obs.get("verdance", 0.0))
	_verd.flourish = bool(obs.get("flourish", false))
	_verd.flourish_ripe = bool(obs.get("flourish_ripe", false))
	_verd.garden = int(obs.get("garden", 0))
	_verd.ripe_garden = int(obs.get("ripe_garden", 0))
	_verd.thorns = int(float(p.vars.get("stat_thorns", 0.0)))
	_verd.thorn_charge = int(obs.get("thorn_charge", 0))
	_verd.thorn_charge_max = int(obs.get("thorn_charge_max", 5))
	_verd.thorns_pct = float(obs.get("thorns_pct", 0.45))
	var casting: Dictionary = obs.get("casting", {})
	if casting.is_empty():
		_castbar.active = false
	else:
		_castbar.active = true
		_castbar.frac = clampf(float(s.tick - int(casting.get("start_tick", 0))) / maxf(float(casting.get("dur_ticks", 1)), 1.0), 0.0, 1.0)
		var ct: Seat = casting.get("target")
		_castbar.target = ct.unit_name if ct != null else ""
		_castbar.spell_id = String(casting.get("id", ""))
		_castbar.label = String(_bcfg.spells.get(_castbar.spell_id, {}).get("name", _castbar.spell_id))
	var gcd_ticks := float(CombatCore.to_ticks(_bcfg.gcd, s.config.fixed_hz))
	for i in _runes.size():
		var id: String = _rune_ids[i]
		var sp: Dictionary = _bcfg.spells[id]
		var offgcd := bool(sp.get("offgcd", false))
		var afford: bool = p.resource >= float(sp.get("sap", 0.0))
		if sp.has("spec"):
			afford = afford and float(obs.get("verdance", 0.0)) >= _bcfg.verd_min_spend
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
			var crit := bool(ev.get("crit", false))
			var mine_hit := _is_my_hit(ev)
			DamageNumbers.spawn(_fx, a, String(ev.get("kind", "")), crit, mine_hit,
				Vector2(0.72, 0.28), _dmg_i, _seat_accent())
			_dmg_i += 1
			_dial.react("impact", a)
			if mine_hit and crit:
				_add_shake(8.0)
		"poison":
			# venom ticks (a blade in the comp) — your own read as green, an ally's dim
			DamageNumbers.spawn(_fx, float(ev.get("amt", 0)), "poison", false,
				_is_my_hit(ev), Vector2(0.72, 0.34), _dmg_i, Palette.POISON)
			_dmg_i += 1
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
		"curio":
			# GEAR-1: a curio proc — pop the item's name so the fortune reads
			if mine:
				var cnm := String(GearCatalog.item(String(ev.get("id", ""))).get("name", "CURIO"))
				_big_text("⚙ %s" % cnm.to_upper(), Palette.GOLD_BRIGHT, 30, 0.8)
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
		# ---- Bloomweaver (second healer) extras ----
		"bloom":
			_flash_frame(ev.get("seat", null), Palette.VERDANCE)
		"warded":
			_flash_frame(ev.get("seat", null), Palette.GOLD)
		"saprot":
			_flash_frame(ev.get("seat", null), Palette.VERDANCE)
		"wilt":
			_flash_frame(ev.get("seat", null), Palette.TEXT_DIM)
		"perfect_ward":
			_flash_frame(ev.get("seat", null), Palette.GOLD_BRIGHT)
			if _seat_key == "healer":
				_big_text("PERFECT WARD!", Palette.GOLD_BRIGHT, 30, 0.6)
		"lifesurge":
			if _seat_key == "healer":
				_big_text("LIFESURGE — THE GARDEN BLOOMS!", Palette.VERDANCE, 32)
				_add_shake(5.0)
		"wildbloom":
			if _seat_key == "healer":
				_big_text("WILDBLOOM", Palette.VERDANCE, 36)
				_add_shake(6.0)
		"briarheart":
			if _seat_key == "healer":
				_big_text("BRIARHEART", Palette.THORN, 36)
				_add_shake(6.0)
		"thorn_snap":
			if bool(ev.get("player", false)):
				var ch := int(ev.get("charge", 0))
				_big_text("SNAP x%d" % ch, Palette.THORN, 26 + ch * 2, 0.6)
		"thorn_break":
			if bool(ev.get("player", false)):
				_big_text("streak broken", Palette.TEXT_DIM, 18, 0.5)
		"cast_cancelled":
			if _seat_key == "healer":
				_big_text("cast cancelled", Palette.TEXT_DIM, 16, 0.5)

func _flash_frame(seat: Seat, col: Color) -> void:
	if seat == null:
		return
	var fr := _frame_of(seat)
	if fr != null:
		fr.flash(col)

## Did this boss-damage event come from the seat I'm playing? (raid: emphasise mine)
func _is_my_hit(ev: Dictionary) -> bool:
	var p: Seat = _ctrl.player() if _ctrl != null else null
	return p != null and ev.get("seat", null) == p

## The local seat's class colour — the base tint for a generic own-hit number.
func _seat_accent() -> Color:
	match _seat_key:
		"tank": return Palette.STEEL
		"blade": return Palette.FLOW
		"caster": return Palette.KICK
		"healer": return Palette.WIN
	return Palette.GOLD

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
	DamageNumbers.float_num(_fx, text, pos, color, dy)


# ============================================================ END
func _on_end(won: bool) -> void:
	if _screen != "combat":
		return
	if _online_map:
		# a DESCENT fight ended — the server is already sending the next map/campaign;
		# don't run the offline floor logic or pop a single-fight end screen.
		return
	if _gate_live and not _online:
		# Tier-1 GATE exam resolves: only YOUR raid slot carries in or out —
		# and a lost gate does NOT end the run (force-rebooted through, WOUNDED).
		_gate_live = false
		if _map == null:               # --autostart=gate dev entry: plain end screen
			_show_end(won)
			return
		var ri: int = SEAT_IDX[_seat_key]
		var u: Seat = _ctrl.state.seats[0]
		if won:
			_map_fracs[ri] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
		else:
			_map_fracs[ri] = 0.35
			_map_wounds[ri] = minf(0.4, float(_map_wounds[ri]) + 0.2)
		if u.role == "healer":
			_map_mana = clampf(u.resource / maxf(1.0, u.resource_max), 0.05, 1.0)
		var ex: Dictionary = GateContent.exam(_seat_key)
		# GEAR-2: the sworn oath resolves on the exam's final state (win OR loss)
		_resolve_oath(_ctrl.state, _ctrl.player(), won)
		if not won and not _oath_result.is_empty():
			_toast_add("⚖  OATH BROKEN — SLA BREACHED (penalty clauses waived)")
			_oath_result = {}
		# GEAR-1: a gate CLEAR is a kill — its Ledger table drops (class-marked page).
		var after_gate: Callable = _show_map
		if won:
			var gate_bid := String(_ctrl.state.encounter.id)
			after_gate = func(): _after_drop(gate_bid, _show_map)
		_map_stop(String(_ctrl.state.encounter.name),
			String(ex["win"] if won else ex["lose"]),
			[{"label": "REJOIN THE RAID", "fx": {"result": String(GateContent.CAPPER[won])}}],
			Palette.WIN if won else Palette.CRIMSON, after_gate)
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
		# GEAR-2: the sworn oath resolves on the fight's final state
		_resolve_oath(_ctrl.state, _ctrl.player(), won)
		if not won:
			_show_end(false)
			return
		# GEAR-1: the kill's drop ceremony runs first, then the run continues wherever
		# it was headed (map / elevation / campaign clear).
		var after: Callable = _show_map
		if String(_map.node(_map_node)["kind"]) == RunMap.KIND_SEAL:
			# a floor Seal fell: elevate to the next ring, or clear the realm on the last
			after = _show_campaign_cleared if _floor >= RaidContent.FLOORS.size() - 1 \
				else _show_floor_cleared
		# gear drop first, THEN the boon REFORGE (1-of-3), THEN continue (map/elevate/clear)
		_after_drop(String(_ctrl.state.encounter.id), func(): _show_boon_draft(after))
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
		# the meter's recap: the raid ranked, click a raider for their spells
		var rmeter := MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg", true)
		_place(rmeter, 1, 0, 1, 0, -318, 118, -18, 600)
		_ui.add_child(rmeter)
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


## The fight-end BEAT: SLAIN / YOU FALL slams over the arena for a breath,
## THEN the normal end flow (draft / end screen / map) runs. Headless runs
## (smokes, sims) skip the beat entirely.
func _on_end_moment(won: bool) -> void:
	if _screen != "combat" or DisplayServer.get_name() == "headless":
		_on_end(won)
		return
	var bname := _ctrl.state.encounter.name if _ctrl != null and _ctrl.state != null else ""
	KillMoment.play(_ui, won, bname)
	get_tree().create_timer(1.25).timeout.connect(func():
		if _screen == "combat":
			_on_end(won))
