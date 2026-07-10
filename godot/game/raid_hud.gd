## Raid HUD (R1 v2 — see RAID-PLAN.md) — THE RIFT: pick ANY of the four seats and
## play it live with three AI raiders. Each seat gets its faithful class band
## (Bulwark orbs/spec/Challenge · Twinfang rhythm/Flow · Alchemist ALEMBIC/brew
## · Well click-cast pours), around a shared raid grammar: boss plate + dial,
## reliquary party frames (gold-lit = the boss's current victim), aggro banners.
## Screens: seat/boss select -> Combat -> End. Single Seal, no draft.
extends Control

const SEAT_IDX := {"tank": 0, "blade": 1, "caster": 2, "healer": 3}
const SEAT_CLASS := {"tank": "duelist", "blade": "twinfang", "caster": "alchemist", "healer": "well"}
const SEAT_NAMES := {"tank": "THE BULWARK", "blade": "THE TWINFANG", "caster": "THE ALCHEMIST", "healer": "THE WELL-TENDER"}
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
		{"id": "fermata", "name": "FERMATA", "accent": Palette.VOID, "icon": "flurry",
			"desc": "HOLD to coil into shadow — release in the window to strike from the dark. The held note; Tempo's patient half."},
	],
	"caster": [
		{"id": "brew", "name": "THE BREW", "accent": Palette.REACT, "icon": "envenom",
			"desc": "Hold to charge the VIAL, release in the sweet band; feed two opposing poisons — Venom fades, Rot lingers — and RUPTURE the reaction at its ripe peak."},
		{"id": "cask", "name": "THE CASK", "accent": Palette.REACT, "icon": "envenom",
			"desc": "STACK 3–6 graded pours on a walking band — Venom = heat, Rot = time — a MISS dumps the batch; SEAL it, let it COOK, and TAP at the peak. (2nd spec · verb preview)"},
	],
	"healer": [
		{"id": "brim", "name": "TARGET · BRIM", "accent": Palette.GOLD_BRIGHT, "icon": "surge",
			"desc": "Grade the LANDING: pour each heal so the ally lands FULL with no spill — a PERFECT POUR GLINTS them (bonus damage). Read the party; size Flash vs Mend to the wound."},
		{"id": "draw", "name": "SPEED · DRAW", "accent": Palette.STEEL, "icon": "laststand",
			"desc": "Grade the RELEASE: let go at the last instant for a CLEAN draw that builds THE CURRENT (each stack casts faster); the dead-centre STILL POINT also GLINTS. Ride the streak; a slip or a dry Well breaks it."},
	],
}

## The SECOND healer class' Aspects: the healer SEAT is the Well (ASPECTS["healer"]) or a
## Bloomweaver (below) — `_healer_cls` decides which pair the ceremony/toggles show.
static var BLOOM_ASPECTS := [
	{"id": "wildgrove", "name": "WILDGROVE", "accent": Palette.VERDANCE, "icon": "wildbloom",
		"desc": "STACK seeds fast, then let the bed COOK from a trickle to a roar; BLOOM it for burst, and light Flourish across the raid with a full field."},
	{"id": "thornveil", "name": "THORNVEIL", "accent": Palette.THORN, "icon": "briarheart",
		"desc": "SNAP-STREAK wards: each Perfect Ward ramps the thorns that reflect damage back — heal by hurting the boss."},
]

## The Aspect pair for a seat, honouring the seat's chosen CLASS.
func _aspects_for(seat_key: String) -> Array:
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return BLOOM_ASPECTS
	return ASPECTS[seat_key]

## The Aspect pair for a lobby seat given an explicit class (online — the healer
## claimant may be a Well or a Bloomweaver, independent of this client's _healer_cls).
func _lobby_aspects(seat_key: String, cls: String) -> Array:
	if seat_key == "healer" and cls == "bloomweaver":
		return BLOOM_ASPECTS
	return ASPECTS[seat_key]

## The seat's display name, honouring the seat class.
func _seat_display_name(seat_key: String) -> String:
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return "THE BLOOMWEAVER"
	return String(SEAT_NAMES.get(seat_key, "RAIDER"))

## The class currently filling a seat (the blade/caster/healer seats are polymorphic).
func _seat_cls_now() -> String:
	if _seat_key == "healer": return _healer_cls
	if _seat_key == "blade": return _blade_cls
	if _seat_key == "caster": return _caster_cls
	return String(SEAT_CLASS.get(_seat_key, "duelist"))

## The spec's per-seat cfg for the human seat (carries its class so RaidNet builds the
## right kit + the lobby/sim/net all agree). Non-polymorphic seats keep their native class.
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
	elif _aspect == "brim" or _aspect == "draw":
		_healer_cls = "well"

## COMMANDER: make _d.party cover exactly the three seats the human doesn't occupy.
## Defaults = the verified comp RaidNet.make_spec would fill in anyway; prior picks
## survive a seat change between descents (only the vacated/claimed seats reset) —
## and, since REFIT P4, across SESSIONS: the first call seeds from the Profile roster.
func _ensure_party() -> void:
	if _d.party.has(_seat_key):
		_d.party.erase(_seat_key)
	if not _roster_seeded:
		_roster_seeded = true
		var stored := Profile.current().roster()
		for key in RaidNet.SEAT_KEYS:
			if key == _seat_key or _d.party.has(key):
				continue
			var e = stored.get(key)
			if _roster_entry_valid(key, e):
				_d.party[key] = {"cls": String(e["cls"]), "aspect": String(e["aspect"])}
	for key in RaidNet.SEAT_KEYS:
		if key == _seat_key or _d.party.has(key):
			continue
		var cls := String(SEAT_CLASS.get(key, "duelist"))
		_d.party[key] = {"cls": cls, "aspect": RaidNet.default_aspect(key, cls)}

## ROSTER PERSISTENCE (REFIT P4): a stored raider is only adopted if its class/aspect
## still exist for that seat in the LIVE tables — a roster saved before a class cut
## self-heals to defaults instead of crashing. A class is "known" for a seat iff it is
## the seat's native class or default_aspect() resolves it away from the seat default
## (the polymorphic pairs) — no separate class table to drift (registry comes with P4).
func _roster_entry_valid(key: String, e) -> bool:
	if not (e is Dictionary and e.has("cls") and e.has("aspect")):
		return false
	var cls := String(e["cls"])
	var known: bool = cls == String(SEAT_CLASS.get(key, "")) \
		or RaidNet.default_aspect(key, cls) != String(RaidNet.DEFAULT_ASPECT.get(key, ""))
	if not known:
		return false
	for a in _lobby_aspects(key, cls):
		if String(a["id"]) == String(e["aspect"]):
			return true
	return false

## Persist the commanded warband (called when the party screen CONFIRMS — edits you
## back out of are not committed). Headless keeps this memory-only (disk-inert).
func _save_roster() -> void:
	Profile.current().set_roster(_d.party)

## COMMANDER: the full 4-seat spec cfg — your seat + the commanded AI raiders. With
## no party overrides this emits exactly the defaults make_spec fills in for missing
## keys, so the spec (and the fight) stays byte-identical to the pre-commander game.
func _party_seat_cfg() -> Dictionary:
	var cfg := _human_seat_cfg()
	_ensure_party()
	for key in _d.party:
		cfg[key] = {"aspect": String(_d.party[key]["aspect"]), "ai": true,
			"cls": String(_d.party[key]["cls"])}
	return cfg

## COMMANDER: per-seat boons for the spec (yours + the AI raiders'); RaidNet.build
## folds each into its seat's kit. Empty sets are omitted (spec unchanged = no drafts).
func _seat_boons_now() -> Dictionary:
	var out := {}
	if _d.run != null and not _d.run.boons.is_empty():
		out[_seat_key] = _d.run.boons
	for key in _d.ai_runs:
		var r: RunState = _d.ai_runs[key]
		if r != null and not r.boons.is_empty():
			out[key] = r.boons
	return out

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
var _armor_modal: Control = null    ## ARMORY-UI: the YOUR SET inspection modal (null = closed)
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
var _shell: Control = null   ## the WorldShell above us (null = standalone probe boot)
## The offline descent STATE (P3.1b): the HUD renders _d, CampaignCore steps it.
## Everything that used to be ~30 _map_*/run/party/oath members lives on it now.
var _d := RunDirector.new()
var _roster_seeded := false        ## Profile roster folded into _d.party once per boot

# Topology raid floor (MAP-3a, offline): map-run state lives HERE, not in RunState —
# the raid never uses the solo run machinery (and draft2 owns run_state.gd right now).
var _map_pending := false          ## TOPOLOGY picked on the select — map starts after aspect pick

# THE WORLD (WORLD-PLAN W1, feature-flagged preview): the persistent overworld wrapping
# the instances. Zone fights are BARE KIT (overworld power rule) and fully isolated —
# no boons/gear/wounds/economy in or out; conquest is the only writeback. All state
# below stays inert until THE WORLD is entered, so every existing path is untouched.
const WORLD_PREVIEW := true        ## the home-menu door (front-door flip is W3)
const ESCORT_PREVIEW := true       ## §MEWGENICS STEALS ① escort/volatile tickets (thinnest slice; off ⇒ byte-identical)
## FIGHTLEN (dev feel-scalar, WORLD-PLAN §FIGHT LENGTH): `--fightlen=2.5` multiplies boss
## HP + enrage on OFFLINE pulls so the length bands can be FELT before the W2 grammar
## builds. 1.0 (absent) = untouched, byte-identical everywhere; online never reads it.
var _fightlen := 1.0
var _world: WorldSave = null       ## the permanence layer (null until the world is entered)
var _world_pending := false        ## WORLD picked on home — the Atlas opens after the aspect ceremony
var _zone_id := ""                 ## the zone the warband stands in ("" = not in a zone)
var _zone_node := -1               ## the zone node being resolved right now
var _zone_live := false            ## the current fight is a ZONE pull (isolated, bare kit)
var _zone_toast := ""              ## one-shot zone banner (conquest / withdrawal / crest)
var _escort_line := ""             ## one-shot escort transition line, folded into the next node stop
var _party_ctx := ""               ## "" = raid flow (DESCEND) · "bastion" = the Warband Camp

# The Inference Check meta (Topology deep events): ⚡ Entropy is the within-run luck
# pool spent to bias a roll; 📁 Prior is the across-run luck loaded once at descent
# start; _d.flags are cross-node ripple marks. All start inert (0/{}) — an event only
# touches them if it carries the matching fx, so a runless/dev path is unaffected.

# GEAR-1 (Curios / Realm-1 "peripherals"): run-scoped loot. Items evaporate with the
# run (win or wipe); only Ledger UNLOCKS persist (GearStore). Offline-only in v1 —
# the online campaign spec folds `gear` in later (rides like tickets/inventory).

# COMMANDER (Bill, 2026-07-04): solo raid = you build the WHOLE party. The three AI
# raiders' class/aspect are picked on the pre-descent PARTY screen, and their boons
# are drafted BY YOU after every won fight — the AI only drives the rotation.

# GEAR-2 (Sworn Oaths / Realm-1 SLAs): one oath per fight, sworn at the boss node.
var _oath_lbl: Label = null

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
var _raid_col: VBoxContainer = null   # the movable raid-frame panel (drag its header)
var _raid_col_xl: bool = false        # which layout the panel was built with
var _raid_drag: bool = false
var _raid_drag_off := Vector2.ZERO
var _aggro_warn: Label
var _shake_root: Control
var _shake_amt: float = 0.0
var _dmg_i: int = 0                 # rotating spawn-lane counter for damage numbers

# THE CLASS BAND (REFIT P4): the human seat's combat instrument cluster. Build /
# render / keys / mouse / gauge events all route to it — the ~25 per-class widget
# members and the 4-way match per surface that used to live here are the band's
# problem now (game/ui/bands/*.gd; ClassBand.for_hud picks by _seat_cls_now()).
var _band: ClassBand = null
var _pcast: PlayerCastBar          ## caster
var _bcfg: BloomweaverConfig       ## healer (Bloomweaver) — read by _hspells/_cast_on + the band
var _wcfg: WellConfig              ## healer (the Well) — read by _hspells/_cast_on + the band
var _acfg: AlchemistConfig         ## the Alchemist's config (set in _make_loadout when the caster brews)
var _healer_cls: String = "well" ## which class fills the healer seat: well | bloomweaver
var _blade_cls: String = "twinfang" ## the blade seat's class (Twinfang only, post-purge)
var _caster_cls: String = "alchemist" ## the caster seat's class (Alchemist only, post-purge)
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
		if a.begins_with("--fightlen="):   # dev feel-scalar — parse BEFORE any autostart pull
			_fightlen = maxf(1.0, float(a.substr("--fightlen=".length())))
			if _fightlen > 1.001:
				print("FIGHTLEN ×%.2f — offline boss HP + enrage scaled (dev feel toggle)" % _fightlen)
	# P3.2a: the dev autostart idioms moved UP to WorldShell.drive_autostart — the
	# shell owns the boot; this HUD is the instance surface it raises. (`--fightlen=`
	# stays above: an instance feel-scalar, parsed before any pull.)

func _clear() -> void:
	if _shell != null:
		_shell._clear_shell_ui()   # instance screens replace shell screens (leaf call)
	TransitionVeil.flash_on(self)   # screens settle in, never snap
	_band = null                    # its widgets die with _ui below
	_hover_seat = null
	_focus_seat = null
	_stage2d = null
	_pause = null                   # the overlay is a _ui child — freed below; drop the freeze
	_armor_modal = null             # ditto — the modal lives under _ui
	if _ctrl != null:
		_ctrl.paused = false
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT
## The one game front door (ONE GAME · ONE HUD, see MASTER-PLAN §GAME SHAPE): PLAY the
## raid campaign (solo-with-AI) or PLAY ONLINE (co-op). No mode select, no solo split.
# ============================================================ SHELL ROUTING
## P3.2b-2: every world-layer screen (home/select/party/atlas/bastion/zone) lives on
## the WorldShell now. These four stubs are the ONLY doors left — the instance's own
## flows (Esc, fight ends, zone conquest) route UP through them. Standalone boots
## (probes loading raid_main directly) have no shell: the stubs no-op, and probes
## drive instance methods directly.
func _show_home() -> void:
	if _shell != null:
		_shell._show_home()

func _show_select(_seat: String = "tank") -> void:
	_show_home()

func _show_zone() -> void:
	if _shell != null:
		_shell._show_zone()

func _zone_clear_node(nid: int) -> void:
	if _shell != null:
		_shell._zone_clear_node(nid)

# ------------------------------------------------------------ zone fights

## A ZONE fight (overworld power rule): bare kit + your commanded warband, NO boons /
## gear / wounds / carry — an isolated pull, full HP in, nothing out but conquest.
## Built by the SAME shared factory as every raid pull, with NO overrides — so a zone
## stand-in fight is byte-identical to its source encounter (the W1 acceptance bar).
## THE ONE EXCEPTION (§MEWGENICS STEALS ①): while escorting a payload, a fight/elite node
## rides a `carry.burden` — an enemy-side add — so the pull is *harder*, never buffed
## (bare-kit law intact; a no-burden pull is still byte-identical).
func _launch_zone_fight(n: Dictionary) -> void:
	_screen = "combat"
	_clear()
	_ensure_party()
	var run_seed := _mint_run_seed()   # recorded — a zone pull replays like any run
	var carry := {}
	if ESCORT_PREVIEW:
		var b := Escort.burden_for(_world, _zone_id, n)
		if b != "":
			carry = {"burden": b}
	# PACK: an authored member chain on the node = one battle, fought sequentially
	# (node["fight"] is always the chain's first id; [] = a classic single pull).
	var pk: Array = n.get("pack", [])
	var spec := RaidNet.make_spec(run_seed, _party_seat_cfg(), String(n["fight"]), carry, {}, pk, "zone")
	var s := RaidNet.build(spec, _seat_key)
	_apply_fightlen(s)
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_zone_live = true
	_ctrl = _local_ctrl
	_ctrl.begin(s, SEAT_IDX[_seat_key])

## FIGHTLEN: scale THIS pull's boss pool + enrage clock (the dev feel toggle, offline
## only). Mutates the built state exactly like RaidMarks does (post-build, pre-begin);
## phases key off HP fractions so they stay proportional; INF enrage (enrage-less
## fights) is guarded. _fightlen == 1.0 (flag absent) touches nothing.
func _apply_fightlen(s: CombatState) -> void:
	if _fightlen <= 1.001 or s == null or s.boss == null:
		return
	s.boss.hp = roundf(s.boss.hp * _fightlen)
	s.boss.hp_max = roundf(s.boss.hp_max * _fightlen)
	if s.encounter != null and is_finite(s.encounter.enrage_at) and s.encounter.enrage_at > 0.0:
		s.encounter.enrage_at *= _fightlen
	# PACK: the members still waiting scale too (s.encounter IS pack[0] — the lines
	# above already covered it; touching [0] again would double-scale).
	for i in range(1, s.pack.size()):
		var enc: EncounterRes = s.pack[i]
		enc.hp = int(roundf(float(enc.hp) * _fightlen))
		if is_finite(enc.enrage_at) and enc.enrage_at > 0.0:
			enc.enrage_at *= _fightlen
	_shake_amt = 0.0
	_online = false
	_ctrl = _local_ctrl
	_ctrl.begin(s, 0)

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
	_net.arming.connect(_on_net_arming)         # THE KILL SWITCH cash-out
	_net.campaign_ended.connect(_on_net_campaign)
	_net.draft_prompt.connect(_on_net_draft)    # online boons

func _set_net_status(m: String) -> void:
	if _net_status != null and is_instance_valid(_net_status):
		_net_status.text = m

# ---- P3.3: the CONNECTION-LIFECYCLE screens (connect form / lobby) live on the
# WorldShell now — connectivity is becoming a shell property. These stubs keep the
# net-signal wiring and the instance's own flows routing UP; the online DESCENT
# screens (net map/stops/draft/arming/wait) stay HERE — they are the online run.
func _show_online() -> void:
	if _shell != null:
		_shell._show_online()

func _show_lobby() -> void:
	if _shell != null:
		_shell._show_lobby()

func _on_room(room: Dictionary) -> void:
	_room = room
	if _shell != null:
		_shell._on_room_shell()

## Your player row in the room snapshot (a STATE reader — lives with _room/_net).
func _me() -> Dictionary:
	for p in _room.get("players", []):
		if int(p.get("id", -1)) == _net.peer_id():
			return p
	return {}

func _launch_online(spec: Dictionary, you: String) -> void:
	if you == "" or not SEAT_IDX.has(you):
		_set_net_status("✗ no seat — claim one first")
		return
	_seat_key = you
	for e in spec.get("seats", []):
		if String(e["key"]) == you:
			_aspect = String(e["aspect"])
			if you == "healer":
				_healer_cls = String(e.get("cls", "well"))
			elif you == "caster":
				_caster_cls = String(e.get("cls", "alchemist"))
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
	elif _shell != null and (String(_shell._screen) == "lobby" or String(_shell._screen) == "netconnect"):
		_show_online()   # routes up: rebuild the connect form with the reason
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
	if _d.run == null:
		var me := _me()
		if not me.is_empty():
			_seat_key = String(me.get("seat", _seat_key))
			_aspect = String(me.get("aspect", _aspect))
		_d.run = _make_run()
		_d.taken_boons = []
		var sd := int(msg.get("seed", 1))
		_d.run.draft_rng = DetRng.new((sd ^ (int(SEAT_IDX.get(_seat_key, 0)) * 2654435761)) & 0x7FFFFFFF)
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
	ms.entropy = int(msg.get("entropy", 0))   # ⚡ the within-run luck pool (server-owned, v6)
	ms.charge = int(msg.get("charge", 0))     # ⏻ THE KILL SWITCH meter (server-owned)
	ms.interactive = _map_is_leader
	if _map_is_leader:
		ms.node_entered.connect(func(id: int): _net.send_node(id))
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)
	if not _map_is_leader:
		var wait := UiKit.title_in(_ui, "◍  the leader is choosing the route…", 15, Palette.GOLD_DIM)
		UiKit.place(wait, 0.5, 0, 0.5, 0, -260, 946, 260, 976)

func _avg_frac(fracs: Array) -> float:
	if fracs.is_empty():
		return 1.0
	var t := 0.0
	for f in fracs:
		t += float(f)
	return t / float(fracs.size())

## An event panel: the LEADER picks a choice (sent to the server); others read it.
## INFERENCE CHECK (v7 — SEAT-PICKER): the server sends each choice's by_seat metadata
## (%/breakdown/gate for EVERY seat) + the suggested specialist + ⚡ entropy. The leader
## picks WHO steps up, renders that seat's real dice, and shows the ✓/✗ LOCALLY (the pure
## die keyed off map_seed+node matches the server's resolve for the SAME seat), then sends
## {i, nudge, seat}. Spectators read the prompt and see the outcome in the next map toast.
func _on_net_mapstop(msg: Dictionary) -> void:
	_online_map = true
	_screen = "mapstop"
	_clear()
	if _map_is_leader:
		var eid := String(msg.get("event", ""))
		var page := String(msg.get("page", ""))   # P3: the current branch stage
		var ev := MapContent.event(eid)
		var raw: Array = ev.get("choices", []) if page == "" \
			else ((ev.get("pages", {}) as Dictionary).get(page, {}) as Dictionary).get("choices", [])
		var meta: Array = msg.get("choices", [])
		var mseed := int(msg.get("map_seed", 0))
		var node := int(msg.get("node", 0))
		var ent := int(msg.get("entropy", 0))
		var descs: Array = []
		for i in raw.size():
			var c: Dictionary = raw[i]
			var sc: Dictionary = meta[i] if i < meta.size() else {}
			var d := {"label": String(c.get("label", "")), "kind": String(c.get("kind", "free")),
				"orig_index": i, "fx": c.get("fx", {}), "verb": String(sc.get("verb", "CHECK")),
				"entropy_have": ent, "by_seat": sc.get("by_seat", {})}
			if String(c.get("kind", "")) == "wager":
				d["stake_label"] = _stake_label(c.get("wager", {}))
			descs.append(d)
		var p := MapEventPanel.new()
		p.title_text = String(msg.get("title", ""))
		p.body_text = String(msg.get("body", ""))
		p.choices = descs
		p.seats = msg.get("seats", [])
		p.suggested = String(msg.get("suggested", ""))
		p.accent = Palette.VOID
		# Resolve locally for DISPLAY only, for the seat that STEPPED UP (p.committed_seat,
		# set on press). The pure die + that seat's broadcast % == the server's resolve for
		# the same seat. Never applies fx — the server broadcasts the resulting integrity.
		# Resolve locally for DISPLAY at the chosen seat + attempt (mulligan). The die is a
		# pure function of (map_seed, node, slot, attempt) so the server, resolving the SAME
		# committed attempt, lands the SAME ✓/✗. Uses the full choice (incl. wager stake) so
		# the reward hint matches what the server applies.
		p.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
			var sc: Dictionary = meta[orig] if orig < meta.size() else {}
			var bs: Dictionary = (sc.get("by_seat", {}) as Dictionary).get(p.committed_seat, {})
			var ladder: Array = bs.get("ladder", [])
			var pp := int(bs.get("chance", 0)) if nudge == 0 else int(ladder[nudge - 1])
			var roll := MapCheck.roll(mseed, node, MapCheck.choice_slot(page, orig), attempt)
			var success := roll < float(pp)
			var choice: Dictionary = raw[orig]
			var leg: Dictionary = choice.get("success" if success else "fail", {})
			var fx: Dictionary = (leg.get("fx", {}) as Dictionary).duplicate(true)
			var w: Dictionary = choice.get("wager", {})   # fold the wager stake for the hint
			if not w.is_empty():
				var amt := float(w.get("amount", 0))
				match String(w.get("stake", "integrity")):
					"integrity": fx["hurt"] = float(fx.get("hurt", 0.0)) + amt
					"tokens": fx["tokens"] = int(fx.get("tokens", 0)) - int(amt)
					"entropy": fx["entropy"] = int(fx.get("entropy", 0)) - int(amt)
			return {"success": success, "roll": roll, "p": pp,
				"result": String(leg.get("result", "")), "fx": fx}
		p.finished.connect(func(_fx: Dictionary):
			_net.send_choice(p.committed_index, p.committed_nudge, p.committed_seat, p.committed_attempt))
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
		UiKit.title_in(box, String(msg.get("title", "")), 30, Palette.GOLD)
		var body := UiKit.title_in(box, String(msg.get("body", "")), 15, Palette.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(760, 0)
		UiKit.title_in(box, "◍  the leader is deciding…", 14, Palette.GOLD_DIM)

## Online boons: the server asks every human seat to draft. Roll THIS seat's offers,
## take one, send the id, then wait for the raid to finish (the next `map` replaces us).
func _on_net_draft() -> void:
	if _d.run == null:
		_net.send_pick("")
		return
	# CURIO Expansion Bus: +1 slot → a 1-of-4 draft (online).
	var picks := Draft.roll_offers(_d.run, 1 if _d.gear.has("expansion_bus") else 0)
	if picks.is_empty():
		_net.send_pick("")
		_show_online_wait("Reforge pool exhausted — waiting for the raid…")
		return
	_screen = "draft"
	_clear()
	var ds := DraftScreen.new(_d.run, picks, "REFORGE — the kill reshapes your kit",
		"Take one. Your raid is drafting too.", [], Palette.GOLD)
	ds.free_reroll = _d.gear.has("hot_reload")  # CURIO Hot Reload
	ds.boon_taken.connect(func(boon: Dictionary):
		Draft.take(_d.run, boon)
		_d.taken_boons.append(boon)
		_net.send_pick(String(boon.get("id", "")))
		_show_online_wait("Reforged — waiting for the raid to finish drafting…"))
	_ui.add_child(ds)

func _show_online_wait(msg: String) -> void:
	_screen = "netwait"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	UiKit.title_in(center, msg, 18, Palette.GOLD_DIM)

## The whole descent is over (ROOT cleared, or a wipe) — a campaign end screen.
func _on_net_campaign(won: bool) -> void:
	_online_map = false
	_d.run = null                    # the descent's boon run is done
	_d.taken_boons = []
	_screen = "end"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := UiKit.title_in(box, "ROOT ACCESS GRANTED" if won else "THE DESCENT FALLS", 52,
		Palette.WIN if won else Palette.LOSE)
	banner.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, ("Realm 1 cleared — CLAUDE MYTHOS is unplugged, together." if won
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
	# debug alias: a "bloom"/"bloomweaver" seat token = the healer seat as a Bloomweaver
	if seat_id == "bloom" or seat_id == "bloomweaver":
		seat_id = "healer"
		_healer_cls = "bloomweaver"
	if seat_id == "alchemist" or seat_id == "brew" or seat_id == "cask":   # debug alias: the caster seat (Brew / Cask)
		if seat_id == "cask":
			aspect = "cask"
		seat_id = "caster"
		_caster_cls = "alchemist"
	if seat_id == "well" or seat_id == "brim" or seat_id == "draw":   # debug alias: the reworked healer
		if seat_id != "well":
			aspect = seat_id
		seat_id = "healer"
		_healer_cls = "well"
	_seat_key = seat_id if SEAT_IDX.has(seat_id) else "tank"
	# a healer aspect id disambiguates the class (must resolve BEFORE the pool lookup)
	if _seat_key == "healer":
		if aspect == "wildgrove" or aspect == "thornveil":
			_healer_cls = "bloomweaver"
		elif aspect == "brim" or aspect == "draw":
			_healer_cls = "well"
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
	# (COMMANDER: the assembled party's aspects/classes ride single-Seal pulls too)
	var run_seed := _mint_run_seed()   # recorded — a Seal pull replays like any run
	var spec := RaidNet.make_spec(run_seed, _party_seat_cfg(), _enc_id)
	var s := RaidNet.build(spec, _seat_key)
	_apply_fightlen(s)
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
	_d.floor_i = 0
	# integrity / wounds / mana reset ONLY at the start of the whole descent —
	# they carry from ring to ring (a floor Seal down = elevation, not a reset).
	_d.fracs = [1.0, 1.0, 1.0, 1.0]
	_d.wounds = [0.0, 0.0, 0.0, 0.0]
	_d.mana = 1.0
	# The Inference Check meta resets for a fresh descent. V#8 (DESCENT-PLAN): the
	# cross-run Prior file is DELETED — nothing follows you into a fresh run; every
	# descent opens on the same baseline ⚡.
	_d.entropy = MapCheck.START_ENTROPY
	_d.flags = {}
	_d.marks = {}
	_d.charge = 0
	_d.check_fails = 0
	# GEAR-1: fresh run-scoped loot; the Ledger's permanent unlocks load from disk.
	# Headless (smokes) stays disk-inert — tests inject _d.gear_unlocks directly.
	_d.gear = []
	_d.gear_charges = {}
	_d.tokens = 0
	_d.sworn = {}
	_d.oath_result = {}
	_d.oath_broken = false
	_d.drop_pity = 0
	_d.taken_boons = []
	if DisplayServer.get_name() != "headless":
		_d.gear_unlocks = GearStore.load_unlocks()
	# REPRODUCIBLE DESCENT (REFIT P4): ONE minted seed is the whole run's identity —
	# drops, floor topology, fights, and every boon draft derive from it closed-form,
	# so a descent replays from the one recorded integer (the Profile keeps the stream:
	# root/counter/last_seed — the replay/ghost-race hook).
	_d.run_seed = _mint_run_seed()
	_d.drop_rng = DetRng.new((_d.run_seed ^ 0x5EEDD07) & 0x7FFFFFFF)
	# Draft 2.0: the human's boon run — the 1-of-3 draft fires after each won fight and
	# its picks ride into every pull.
	_d.run = _make_run(_d.run_seed)
	# COMMANDER: each AI raider gets its own boon run too — you draft on their behalf
	# after every won fight. Seeds decorrelated from yours (disjoint draft streams).
	_ensure_party()
	_d.ai_runs = {}
	for key in _d.party:
		_d.ai_runs[key] = _make_seat_run(String(_d.party[key]["cls"]),
			String(_d.party[key]["aspect"]),
			int((_d.run.run_seed ^ (0x515EED + int(SEAT_IDX[key]) * 0x9E3779)) & 0x7FFFFFFF))
	_show_creed_pick(_build_floor)   # TEMPO: swear a Creed at descent start (blade/Twinfang only)

## A minimal RunState for the human seat, just to carry boons + the draft economy
## (class/aspect/draft_rng/tokens/pity). Its encounter chain is ignored — the raid
## drives its own fights; we only borrow the boon pool + Draft 2.0 machinery.
## seed_v: the descent seed offline (reproducible drafts); -1 online — the caller
## re-seeds draft_rng from the server's descent seed anyway.
func _make_run(seed_v: int = -1) -> RunState:
	_sync_healer_cls()
	return _make_seat_run(_seat_cls_now(), _aspect, seed_v)

## Mint a recorded run seed off the Profile's persisted stream (REFIT P4): every
## offline run/pull is reproducible from the profile's (root, counter) pair — and
## headless draws from the FIXED root, so smokes stay deterministic AND disk-inert.
func _mint_run_seed() -> int:
	return Profile.current().next_run_seed()

## COMMANDER: a boon RunState for ANY seat (class starter by cls) — the commander
## drafts on behalf of the AI raiders, so they carry the same run machinery you do.
## The starter ladder lives on the CLASS REGISTRY (unknown cls → the bulwark base).
func _make_seat_run(cls: String, aspect: String, seed_v: int) -> RunState:
	return ClassRegistry.start_run(cls, aspect, seed_v)

## Fold the human's drafted boons into their seat's kit (kits read `boons` via _b()).
## (Map pulls also ride ALL seats' boons through the spec — see _seat_boons_now;
## this direct injection stays for the GATE path, which builds outside RaidNet.)
func _inject_boons(seat: Seat) -> void:
	if _d.run != null and seat != null and seat.kit != null:
		seat.kit.boons = _d.run.boons
		# CLASS FRAMEWORK (offline plumbing): fold the run's Creed + Modules + Rig into a
		# reworked kit. Both Twinfang and Alchemist carry the same three fields; every other
		# class carries none, so this is skipped there (byte-identical no-op).
		if seat.kit is TwinfangKit:
			var tk := seat.kit as TwinfangKit
			if _d.run.creed != "":
				tk.creed_id = _d.run.creed
			tk.modules = _d.run.modules.duplicate()
			tk.rig = _d.run.rig.duplicate()      # TEMPO §5: the wired Combo rig
		elif seat.kit is AlchemistKit:
			var ak := seat.kit as AlchemistKit
			if _d.run.creed != "":
				ak.creed_id = _d.run.creed
			ak.modules = _d.run.modules.duplicate()
			ak.rig = _d.run.rig.duplicate()      # ALCHEMIST-PLAN §3/rig: the wired Combo rig
		elif seat.kit is WellKit:
			var wk := seat.kit as WellKit
			if _d.run.creed != "":
				wk.creed_id = _d.run.creed
			wk.modules = _d.run.modules.duplicate()
			wk.rig = _d.run.rig.duplicate()      # MENDER-PLAN §4/rig: the wired Combo rig
		elif seat.kit is DuelistKit:
			var dk := seat.kit as DuelistKit
			if _d.run.creed != "":
				dk.creed_id = _d.run.creed
			dk.rig = _d.run.rig.duplicate()      # TANK-PLAN §3/rig: the wired Combo rig
			# (DuelistKit reads modules via the shared kit.boons/modules dicts + _m())
			dk.modules = _d.run.modules.duplicate()

## Generate the current ring's map (RaidContent.FLOORS[_d.floor_i]). The party's carried
## integrity/wounds/mana are UNTOUCHED here — only _start_map_run resets them.
func _build_floor() -> void:
	var fl: Dictionary = RaidContent.FLOORS[_d.floor_i]
	_d.fights = RaidContent.floor_fights(int(fl["ring"]))
	# THE DESCENT REBUILD (DESCENT-PLAN §2/§5): the floor's WHOLE non-combat bag lives
	# on its FLOORS row (`quota` → RunMap quota_override; combat pads the rest) — one
	# source of truth for HUD + server + sims. The ROOT floor gates its Seal behind
	# credential shards; TICKETS are the quests.
	# floor topology derives from the descent seed (REFIT P4 reproducible runs);
	# +1 so floor 0 never collapses the fold to the bare run_seed.
	_d.map = RunMap.generate(int((_d.run_seed * 1000003 + (_d.floor_i + 1) * 7919 + 1) & 0x7FFFFFFF),
		_d.fights.size(), MapContent.raid_event_ids(),
		{}, int(fl["shard_req"]), int(fl.get("tickets", 0)), int(fl.get("rows", 8)),
		fl.get("quota", {}), String(fl.get("minigame", "")))
	_d.node = -1
	_d.inv = {}
	_d.tickets = {}
	_d.ticket_total = _d.map.tickets.size()
	_d.closed = 0
	_d.toast = ""
	_show_map()

## A floor Seal is down → descend one ring (privilege elevation). Past the last
## floor (CLAUDE MYTHOS) = Realm 1 is cleared.
func _advance_floor() -> void:
	_d.floor_i += 1
	if _d.floor_i >= RaidContent.FLOORS.size():
		_show_campaign_cleared()
	elif _d.floor_i == 1:
		_show_module_pick(_build_floor)   # TEMPO: end of Floor 1 elevation → install a Module
	elif _d.floor_i == 2:
		_show_rig_wire(_build_floor)      # TEMPO §5: re-wire the Combo at end of Floor 2
	else:
		_build_floor()

func _show_map() -> void:
	_screen = "map"
	_clear()
	var ms := MapScreen.new()
	ms.map = _d.map
	ms.current = _d.node
	ms.inventory = _d.inv
	ms.hp_frac = _party_integrity()
	ms.subtitle = String(RaidContent.FLOORS[_d.floor_i]["title"])
	ms.ring = int(RaidContent.FLOORS[_d.floor_i]["ring"])
	ms.open_tickets = _open_ticket_lines()
	ms.toast = _d.toast
	_d.toast = ""                 # one-shot — clears once shown
	ms.gear_line = _gear_line()
	ms.entropy = _d.entropy
	ms.charge = _d.charge
	ms.node_entered.connect(_enter_node)
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)
	# ARMORY: YOUR SET — the run's boons as armor pieces + curio trinkets, bottom-left
	# (below the lane band; the doll root ignores the mouse, only sockets hover)
	if _d.run != null:
		var doll := ArmorDoll.new()
		UiKit.place(doll, 0.0, 1.0, 0.0, 1.0, 14, -344, 14 + int(ArmorDoll.W), -12)
		_ui.add_child(doll)
		doll.set_build(_d.taken_boons, _d.gear, _d.gear_charges)
		doll.inspect_requested.connect(_open_armor_modal)
	# GEAR-1: Cooling Paste — a USE button rides the map while a wound needs it
	if _d.gear.has("cooling_paste") and int(_d.gear_charges.get("cooling_paste", 0)) > 0 \
			and _worst_wound() > 0.0:
		var pb := Button.new()
		pb.text = "USE COOLING PASTE — repair corrupted sectors (%d left)" \
			% int(_d.gear_charges["cooling_paste"])
		pb.add_theme_font_size_override("font_size", 15)
		pb.pressed.connect(func():
			_d.gear_charges["cooling_paste"] = int(_d.gear_charges["cooling_paste"]) - 1
			_apply_map_fx({"repair": true})
			_d.toast = "🧴  COOLING PASTE — corrupted sectors repaired"
			_show_map())
		UiKit.place(pb, 0.5, 1.0, 0.5, 1.0, -290, -96, 290, -56)
		_ui.add_child(pb)

## Short "still open" lines for the map header (title + where to turn it in).
func _open_ticket_lines() -> Array:
	var out: Array = []
	for tid in _d.tickets:
		out.append(String(_d.tickets[tid]))
	return out

func _party_integrity() -> float:
	var t := 0.0
	for f in _d.fracs:
		t += float(f)
	return t / maxf(1.0, float(_d.fracs.size()))

func _enter_node(id: int) -> void:
	_d.node = id
	var n: Dictionary = _d.map.node(id)
	# visited/shard/TICKET/key — the ONE rulebook (CampaignCore.ticket_at replaced the
	# HUD's _ticket_at twin); purse Tokens route through _gain_tokens (Hashgrinder ×2).
	var cp := _d.cp_view()
	var out := CampaignCore.enter_node(cp, n, _d.gear.has("ticket_stub"))
	_d.cp_sync(cp)
	if int(out["tokens"]) != 0:
		_gain_tokens(int(out["tokens"]))
	if bool(out["key_grabbed"]):
		_map_stop(String(n["name"]), MapContent.KEY_PICKUP,
			[{"label": "TAKE IT", "fx": {"key": true,
				"result": "Authorization acquired. The raid agrees to never speak of where it was taped."}}],
			Palette.GOLD_BRIGHT, _resolve_node.bind(n))
		return
	_resolve_node(n)

## THE DESCENT REBUILD: nodes resolve through RunMap.effective_kind — a WILD reveals
## its rolled payload; unbuilt interiors (market/jailbreak/minigame) fall back to the
## honest existing kind until their slice flips the flag. ELITE rides the combat path
## (its promotion lands in the packroll, its bounty in the win path).
func _resolve_node(n: Dictionary) -> void:
	match RunMap.effective_kind(n):
		RunMap.KIND_COMBAT, RunMap.KIND_SEAL, RunMap.KIND_ELITE:
			# GEAR-2: the boss's Ledger page offers its oaths before the pull
			var fi := int(n["fight"])
			var enc: EncounterRes = _d.fights[clampi(fi, 0, _d.fights.size() - 1)]
			var proceed := _offer_oath_then.bind(String(enc.id), _launch_map_fight.bind(fi))
			# THE KILL SWITCH: at a Seal, cash out the ⏻ meter (OVERCLOCK PRIME) before the pull
			if String(n["kind"]) == RunMap.KIND_SEAL and _d.charge > 0:
				_show_arming(String(enc.name), proceed)
			else:
				proceed.call()
		RunMap.KIND_EVENT:
			_event_stop(n)
		RunMap.KIND_COOLING:
			_map_stop(MapContent.COOLING_TITLE, MapContent.COOLING_BODY,
				[{"label": "THROTTLE  (+10 ⏻ toward the Kill Switch · ease the healer's reserves)",
					"fx": CampaignCore.COOLING_FX.merged({"result": MapContent.COOLING_RESULT})}],
				Palette.FLOW, _show_map)
		RunMap.KIND_CACHE:
			_map_stop(MapContent.CACHE_TITLE, MapContent.CACHE_BODY,
				[{"label": "SALVAGE THE COMPONENT  (+25 ⏻)",
					"fx": CampaignCore.CACHE_FX.merged({"result": MapContent.CACHE_RESULT})}],
				Palette.GOLD, _show_map)

## THE INFERENCE CHECK (offline). Builds a ctx from the human's build, prepares each
## choice (a check computes its % + breakdown; a gated choice greys if unmet), and hands
## the panel a resolver that rolls the deterministic die on commit. A free choice
## resolves exactly like before. Kind-less legacy choices route the free path too.
func _event_stop(n: Dictionary) -> void:
	var ev := MapContent.event(String(n["event"]))
	_render_event_page(n, "", String(ev.get("title", "")), String(ev.get("body", "")),
		ev.get("choices", []))

## Render ONE stage of an event (the root page, or a branch/goto sub-page). Multi-stage
## events chain client-side offline: a chosen leg with a `branch`/`goto` emits `staged`,
## which applies its fx and renders the target page. The die is keyed per (page, choice)
## via choice_slot, so a sub-page's checks get their own rolls; the root ("") is unchanged.
func _render_event_page(n: Dictionary, page_id: String, title: String, body: String,
		raw: Array) -> void:
	var ctx := _map_ctx()
	var map_seed := _d.map.seed if _d.map != null else 0
	var node_id := int(n["id"])
	var descs: Array = []
	for i in raw.size():
		descs.append(_prep_choice(raw[i], i, ctx))
	_screen = "mapstop"
	_clear()
	var p := MapEventPanel.new()
	p.title_text = title
	p.body_text = body
	p.choices = descs
	p.accent = Palette.VOID
	p.client_stages = true
	# Side-effect-free: the panel previews attempts (nudge + mulligan rerolls) freely; the
	# ⚡ spend + comeback pity are applied once, on COMMIT (see _commit_event_spend).
	p.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
		return MapCheck.resolve(raw[orig], ctx, map_seed, node_id,
			MapCheck.choice_slot(page_id, orig), attempt, {"nudge": nudge})
	p.staged.connect(func(fx: Dictionary, page: String):
		_commit_event_spend(p, fx)
		var ev := MapContent.event(String(n["event"]))
		var pg: Dictionary = (ev.get("pages", {}) as Dictionary).get(page, {})
		_render_event_page(n, page, String(pg.get("title", title)),
			String(pg.get("body", "")), pg.get("choices", [])))
	p.finished.connect(func(fx: Dictionary):
		_commit_event_spend(p, fx)
		_show_map())
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(p)

## Apply a committed event choice: its fx, the ⚡ spent (nudge + mulligan rerolls), and
## comeback pity (reset on a pass, +1 on a fail). One place so branch stages + the final
## commit account identically.
func _commit_event_spend(p: MapEventPanel, fx: Dictionary) -> void:
	_apply_map_fx(fx)
	var spend := int(p.committed_nudge) + int(p.committed_attempt) * MapCheck.MULLIGAN_COST
	if spend > 0:
		_d.entropy = maxi(0, _d.entropy - spend)
	if bool(p.committed_is_check):
		_d.check_fails = 0 if bool(p.committed_success) else _d.check_fails + 1

## Present a single choice: gate first (greyed if unmet), then a check gets its % +
## itemized breakdown; a free/branch choice carries its fx + the page it opens (next_page).
func _prep_choice(c: Dictionary, i: int, ctx: Dictionary) -> Dictionary:
	var kind := String(c.get("kind", "free"))
	var d := {"label": String(c["label"]), "kind": kind, "orig_index": i, "fx": c.get("fx", {}),
		"next_page": String(c.get("branch", String(c.get("goto", ""))))}   # branch/goto target
	var gate: Dictionary = c.get("gate", {})
	if not gate.is_empty() and not MapCheck.gate_ok(gate, ctx):
		d["gated"] = true
		d["locked_reason"] = MapCheck.gate_reason(gate)
		return d
	if kind == "check" or kind == "wager":
		var chk: Dictionary = c.get("check", {})
		var info := MapCheck.chance(chk, ctx)
		d["chance"] = int(info["p"])
		d["breakdown"] = info["parts"]
		d["verb"] = String(chk.get("verb", "CHECK"))
		d["entropy_have"] = int(ctx.get("entropy", 0))       # ⚡ the party can feed
		d["nudge_ladder"] = MapCheck.nudge_ladder(chk, ctx)   # the % at 1..min(3,⚡) fed
		if kind == "wager":
			d["stake_label"] = _stake_label(c.get("wager", {}))
	return d

## Human-readable wager stake ("10% integrity" / "2 ⏣" / "2 ⚡").
func _stake_label(w: Dictionary) -> String:
	var amt := float(w.get("amount", 0))
	match String(w.get("stake", "integrity")):
		"integrity": return "%d%% integrity" % int(round(amt * 100.0))
		"tokens": return "%d ⏣" % int(amt)
		"entropy": return "%d ⚡" % int(amt)
	return ""

## The build context an Inference Check reads. Offline the human's seat is the only
## full build (AI raiders carry no boons), so `boon_tags` is the human's owned boons
## resolved to their synergy tags; role = the seat you pilot; aspect = your aspect.
func _map_ctx() -> Dictionary:
	var cat = Draft.catalog(_d.run) if _d.run != null else null
	var aspect := String(_d.run.aspect) if _d.run != null else ""
	var boons: Dictionary = _d.run.boons if _d.run != null else {}
	var boon_tags := MapCheck.tags_for_boons(cat, aspect, boons)
	var gear_tags: Array = []
	for gid in _d.gear:
		gear_tags.append(GearCatalog.item(String(gid)).get("tags", []))
	return MapCheck.build_ctx(boon_tags, gear_tags, aspect, _seat_key,
		_avg_frac(_d.fracs), _d.entropy, _d.check_fails, _d.inv, _d.flags, _tokens_now())

## PACK QUOTAS v2 (WORLD-PLAN shape-assignment rule: "Topology floors roll shapes from
## the run seed inside authored quotas"). MID skirmish nodes only — the entry body and
## the Seal keep their authored shapes. Seeded from (map seed, node id): the same
## descent always rolls the same packs (replay-true); rerolling the map rerolls them.
## THE DESCENT REFIT: the walk-ins are takeover-palette Forge LIGHTWEIGHTS (swarm-
## weighted, tier riding the ring t1→t3), so a rolled trio lands mid-fight-sized —
## the v1 full-HP bard/sonnet wart is closed, and the weights open up with it:
## 30% solo · 45% duo · 25% trio. OFFLINE — the online descent's server builds its
## own specs (packs land there with the server pass).
const PACK_FILLER_BODIES := ["swarm", "swarm", "stalker"]   ## swarm-weighted walk-ins

## One rolled walk-in: a light Forge body at the FLOOR's tier (FLOORS "tier" —
## F1 teaches on t1, F4 holds root with t3), seed drawn from the node's own stream
## (variety across nodes, identical on replay).
func _pack_filler(rng: DetRng) -> String:
	var body := String(PACK_FILLER_BODIES[rng.next_u32() % PACK_FILLER_BODIES.size()])
	var tier := clampi(int(RaidContent.FLOORS[_d.floor_i].get("tier", 1)), 1, 3)
	return "forge:takeover:%s:%d:%d" % [body, tier, 900 + int(rng.next_u32() % 64)]

func _roll_map_pack(fi: int, enc: EncounterRes) -> Array:
	if _d.map == null or _online:
		return []
	if fi <= 0 or fi >= _d.fights.size() - 1:
		return []                        # entry + Seal: authored, never rolled
	var rng := DetRng.new((_d.map.seed ^ (0x9A7B * (_d.node + 7))) & 0x7FFFFFFF)
	# THE DESCENT REBUILD (§5): an ELITE node is a guaranteed REINFORCED trio — the
	# mutator is printed on the door; entry/Seal stay authored, never rolled.
	# (bounds-guarded: the packroll probe samples synthetic node ids past the map)
	if _d.node >= 0 and _d.node < _d.map.nodes.size() \
			and String(_d.map.node(_d.node).get("kind", "")) == RunMap.KIND_ELITE:
		return [_pack_filler(rng), _pack_filler(rng), String(enc.id)]
	# THE FIGHT LADDER (DESCENT-PLAN §3): pack size scales with the floor via the
	# FLOORS "packroll" thresholds — F1 mostly solos, F4 mostly trios; a normal
	# fight grows because MORE happens, never because the same body gets spongier.
	var pr: Array = RaidContent.FLOORS[_d.floor_i].get("packroll", [0.30, 0.75])
	var r := rng.next_float()
	if r < float(pr[0]):
		return []                        # a classic solo pull
	var pack: Array = [_pack_filler(rng)]
	if r >= float(pr[1]):
		pack.append(_pack_filler(rng))
	pack.append(String(enc.id))          # smalls → captain (the node's own body)
	return pack

## A map fight: the node's encounter through the SAME shared factory as every raid
## pull, then each seat starts at its carried integrity.
func _launch_map_fight(fi: int) -> void:
	_screen = "combat"
	_clear()
	var enc: EncounterRes = _d.fights[clampi(fi, 0, _d.fights.size() - 1)]
	# fight seed: closed-form off (descent seed, floor, fight, NODE) — the node id is
	# folded so two same-index nodes never replay the identical fight (the
	# RunState.fight_seed() idiom); same node re-entered = same fight, by design.
	var run_seed := int((_d.run_seed * 1000003 + (_d.floor_i + 1) * 7919 \
		+ (fi + 1) * 104729 + (_d.node + 2) * 6763) & 0x7FFFFFFF)
	# COMMANDER: the whole assembled party rides the spec — AI aspects/classes AND
	# every seat's drafted boons (RaidNet.build folds each into its seat's kit).
	# PACK QUOTAS: a rolled chain opens with fillers; the node's enc stays the KILL that
	# matters (oaths swear against it, the drop ceremony fires on it — it dies last).
	var pk := _roll_map_pack(fi, enc)
	var enc_id := String(pk[0]) if not pk.is_empty() else String(enc.id)
	var spec := RaidNet.make_spec(run_seed, _party_seat_cfg(), enc_id, {}, _seat_boons_now(), pk)
	var s := RaidNet.build(spec, _seat_key)
	_apply_fightlen(s)
	_arm_gear(s.seats[SEAT_IDX[_seat_key]])   # GEAR-1: your curios ride into the pull
	_inject_boons(s.seats[SEAT_IDX[_seat_key]])   # Draft 2.0: your boons ride in too
	for i in s.seats.size():
		if i < _d.wounds.size():
			var u: Seat = s.seats[i]
			# INTEGRITY RETIRED: CORRUPTED SECTORS cut max HP (the sole HP stake), then boot
			# FULL of what's left — a carried HP fraction is meaningless (a healer tops it off).
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(_d.wounds[i]))))
			u.hp = u.hp_max
			if u.role == "healer":    # the fuel gauge: mana carries between nodes (it bites now)
				u.resource = roundf(u.resource_max * _d.mana)
	_apply_next_fight_mark(s)   # the KILL SWITCH cash-out / a fight-curse weakens THIS boss, then clears
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_ctrl = _local_ctrl
	_ctrl.begin(s, SEAT_IDX[_seat_key])
	_spawn_oath_banner()   # GEAR-2: the sworn deed rides the HUD

## P6: apply a pending fight-altering MARK (an event's sabotage) to this fight's boss,
## then clear it. Absent (no mark) = the fight is byte-identical. Mirrors RaidNet.build's
## online carry-mark so offline + online sabotage land the same boss HP.
func _apply_next_fight_mark(s: CombatState) -> void:
	RaidMarks.apply(s, _d.marks)   # SHARED with RaidNet.build — one applier, never diverges
	_d.marks = {}

## Online OVERCLOCK arming at a Seal: the leader cash-outs (the server owns the ⏻ + mark);
## spectators wait. Sends {kind, spend}; the server pulls the fight after.
func _on_net_arming(msg: Dictionary) -> void:
	_online_map = true
	_screen = "arming"
	_clear()
	if _map_is_leader:
		var ap := ArmingPanel.new()
		ap.charge = int(msg.get("charge", 0))
		ap.boss_name = String(msg.get("boss", "THE SEAL"))
		ap.armed.connect(func(kind: String, spend: int): _net.send_arm(kind, spend))
		ap.banked.connect(func(): _net.send_arm("bank", 0))
		ap.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ui.add_child(ap)
	else:
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		_ui.add_child(center)
		UiKit.title_in(center, "⏻  the leader is arming the Kill Switch…", 18, Palette.CHARGE)

## THE KILL SWITCH cash-out (OVERCLOCK PRIME): a linear spend dial before a Seal. Committing
## a spend deducts ⏻ and folds the resolved mark into the pending fight-mark; banking skips it.
func _show_arming(boss_name: String, proceed: Callable) -> void:
	_screen = "arming"
	_clear()
	var ap := ArmingPanel.new()
	ap.charge = _d.charge
	ap.boss_name = boss_name
	ap.armed.connect(func(kind: String, spend: int):
		_d.charge = maxi(0, _d.charge - spend)
		(_d.marks as Dictionary).merge(RaidMarks.overclock(kind, spend), true)
		proceed.call())
	ap.banked.connect(func(): proceed.call())
	ap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ap)

## A Tier-1 PERSONAL GATE exam (§GAME SHAPE): YOUR seat's class exam, fought alone —
## the class's solo fight, recast to its Realm-1 identity. Carry-in applies only to
## YOUR raid slot (the healer's sandbox allies are phantoms — they carry nothing).
## Losing does NOT end the run: the checkpoint force-reboots you through, WOUNDED.
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
## Routes through the shared MapFx applier (single source of truth for offline +
## online + the sim walker). Integrity/wounds mutate in place through the cp view;
## scalar currencies are copied back after.
func _apply_map_fx(fx: Dictionary) -> void:
	var cp := _d.cp_view()
	MapFx.apply(cp, fx)
	_d.cp_sync(cp)
	# tokens live on the run purse, not cp — grant directly (Phase 1 checks use this)
	if int(fx.get("tokens", 0)) != 0:
		_gain_tokens(int(fx["tokens"]))

# ---------------------------------------------------------------- GEAR-1 (Curios)

## Which class this seat key plays (gear rows are class-marked by class name).
const SEAT_CLS := {"tank": "duelist", "blade": "twinfang", "caster": "alchemist", "healer": "well"}

## The human seat carries the run's equipped curios into a fight (offline map runs
## only — the seat starts each pull with fresh per-fight gear bookkeeping).
func _arm_gear(u: Seat) -> void:
	u.gear = _d.gear.duplicate()
	u.gear_vars = {}

## Tokens are ONE currency: scrap + oath purses feed the same purse the REFORGE
## boon draft spends (raid-boons' `_d.run.tokens`). `_d.tokens` stays only as the
## fallback bank for runless dev paths.
func _gain_tokens(n: int) -> void:
	if n > 0 and _d.gear.has("hashgrinder"):   # CURIO Hashgrinder: all Token income doubled
		n *= 2
	if _d.run != null:
		_d.run.tokens += n
	else:
		_d.tokens += n

func _tokens_now() -> int:
	return _d.run.tokens if _d.run != null else _d.tokens

# ---------------------------------------------------------------- GEAR-2 (Oaths)

func _stakes() -> int:
	return 3 - int(RaidContent.FLOORS[_d.floor_i]["ring"])   # + (version - 1), when versions exist

## The Ledger page, pre-pull: the boss's rows (locked greyed) + its swearable oaths.
## Swear one — or fight unsworn. Realm-1 skin: oaths render as SLAs.
func _offer_oath_then(boss_id: String, launch: Callable) -> void:
	_d.sworn = {}
	_d.oath_result = {}
	_d.oath_broken = false
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
	var banner := UiKit.title_in(box, "THE LEDGER", 40, Palette.GOLD_BRIGHT)
	banner.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, "an oath may be sworn before this pull — SLAs are strictly optional", 14, Palette.TEXT_DIM)
	# the page: every row — item name + rarity + WHAT IT DOES + how to unlock it
	var got: Array = _d.gear_unlocks.get(boss_id, [])
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
		UiKit.title_in(box, "%s  %s  ·  %s  ·  %s" % ["◆" if unlocked else "◇",
			String(it["name"]).to_upper(), String(it.get("rarity", "haiku")).to_upper(), how],
			14, Palette.GOLD if unlocked else Palette.TEXT)
		# the EFFECT — so you know exactly what you're chasing (rarity-tinted)
		var eff := UiKit.title_in(box, String(it.get("desc", "")), 12,
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
			_d.sworn = row.duplicate(true)
			_d.sworn["boss"] = boss_id
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
	if _d.sworn.is_empty():
		return
	var l := Label.new()
	l.text = "⚖ OATH — %s" % String(_d.sworn.get("deed_text", ""))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Palette.GOLD)
	UiKit.place(l, 0.0, 1.0, 0.0, 1.0, 24, -124, 620, -100)
	_ui.add_child(l)
	_oath_lbl = l

## Verdict at fight end (called from _on_end with the final state, win or lose).
func _resolve_oath(s: CombatState, seat: Seat, won: bool) -> void:
	_d.oath_result = {}
	if _d.sworn.is_empty() or s == null or seat == null:
		return
	_d.oath_result = {"kept": won and Oaths.kept(_d.sworn.get("deed", {}), s, seat),
		"sev": int(_d.sworn.get("sev", 1)), "item": String(_d.sworn.get("item", "")),
		"boss": String(_d.sworn.get("boss", "")), "text": String(_d.sworn.get("deed_text", ""))}
	_d.sworn = {}

## ARMORY cadence: what a repeat skirmish kill pays instead of a drop roll, by ring.
const SALVAGE_TOKENS := {3: 1, 2: 2, 1: 2, 0: 3}
## THE DESCENT REBUILD (§5): the elite's fat-⏣ bounty, by ring (F1 fields no elites).
const ELITE_TOKENS := {2: 4, 1: 5, 0: 6}

## Roll the kill's drop (map mode only), run the ceremony, then continue the run.
## Rolls draw from _d.drop_rng only — the combat stream never notices loot.
## ARMORY cadence: drops are EVENTS — `event` is true for Seal/gate kills; a plain
## skirmish only rolls while its SIGNATURE row is still locked (the first-kill
## shower). Repeat skirmish kills pay salvage Tokens so the ceremony stays scarce.
func _after_drop(boss_id: String, done: Callable, event: bool = true) -> void:
	if _d.map == null or _d.drop_rng == null:
		done.call()
		return
	# GEAR-2: a KEPT oath cashes first — its row joins THIS kill's pool, and the
	# purse bends THIS roll (rarity floor / pity ticks) + banks Tokens.
	var bend: Dictionary = {}
	var verdict := ""
	if not _d.oath_result.is_empty() and String(_d.oath_result["boss"]) == boss_id:
		if bool(_d.oath_result["kept"]):
			var p := Oaths.purse(int(_d.oath_result["sev"]), _stakes())
			var oid := String(_d.oath_result["item"])
			var got0: Array = _d.gear_unlocks.get(boss_id, [])
			var fresh: bool = not got0.has(oid)
			if fresh:
				got0.append(oid)
				_d.gear_unlocks[boss_id] = got0
				if DisplayServer.get_name() != "headless":
					GearStore.save_unlocks(_d.gear_unlocks)
			_gain_tokens(int(p["tokens"]))
			_d.drop_pity += int(p["pity"])
			bend = p
			verdict = "⚖  OATH KEPT — SLA MET: +%d⏣%s" % [int(p["tokens"]),
				"  ·  a new row is inked into the Ledger" if fresh else ""]
		else:
			verdict = "⚖  OATH BROKEN — SLA BREACHED (penalty clauses waived)"
		_d.oath_result = {}
	if not event and not Gear.first_locked(boss_id, _seat_cls_now(), _d.gear_unlocks):
		# no ceremony for a farmed skirmish — pay parts + any oath verdict and move on
		# (a KEPT oath's purse Tokens/pity were already banked above; only the one-kill
		# roll bend evaporates, and no shipped skirmish carries an oath row today)
		if verdict != "":
			_toast_add(verdict)
		var pay := int(SALVAGE_TOKENS.get(int(RaidContent.FLOORS[_d.floor_i]["ring"]), 1))
		_gain_tokens(pay)
		_toast_add("⚙  SALVAGE — subagent parts stripped (+%d⏣)" % pay)
		done.call()
		return
	# _seat_cls_now(): a Bloomweaver player rolls its OWN class page (parked → no drop)
	var d := Gear.roll(boss_id, _seat_cls_now(), _d.gear_unlocks, _d.drop_rng,
		int(RaidContent.FLOORS[_d.floor_i]["ring"]), _d.drop_pity, bend)
	if d.is_empty():
		if verdict != "":
			_toast_add(verdict)
		done.call()
		return
	var id := String(d["item"])
	# pity rides the OUTCOME: an opus drop resets the drought, anything else deepens it
	if String(GearCatalog.item(id).get("rarity", "haiku")) == "opus":
		_d.drop_pity = 0
	else:
		_d.drop_pity += 1
	if bool(d["first"]):
		# the SIGNATURE row is inked into the Ledger forever (survives the run)
		var got: Array = _d.gear_unlocks.get(boss_id, [])
		got.append(id)
		_d.gear_unlocks[boss_id] = got
		if DisplayServer.get_name() != "headless":
			GearStore.save_unlocks(_d.gear_unlocks)
	if _d.gear.has(id):
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
		UiKit.title_in(box, verdict, 17,
			Palette.WIN if verdict.contains("KEPT") else Palette.CRIMSON)
	var banner := UiKit.title_in(box, "PERIPHERAL ACQUIRED", 42, Palette.GOLD_BRIGHT)
	banner.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, "a TRINKET for your set — socket it, or scrap it for ⏣", 13, Palette.TEXT_DIM)
	if first:
		UiKit.title_in(box, "★  FIRST KILL — a new row is inked into the Ledger", 15, Palette.GOLD)
	# ARMORY-UI: choose WITH your current gear in view — the drop stands beside the
	# equipped trinket cards (WoW comparison idiom; a free socket shows as room)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 30)
	box.add_child(cards)
	var dcol := VBoxContainer.new()
	dcol.alignment = BoxContainer.ALIGNMENT_CENTER
	dcol.add_theme_constant_override("separation", 7)
	dcol.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	UiKit.title_in(dcol, "· THE DROP ·", 12, Palette.GOLD_BRIGHT)
	var card := RelicCard.new(String(it["name"]),
		String(it["desc"]) + "\n\n\"" + String(it.get("flavor", "")) + "\"",
		"curio", String(it.get("rarity", "haiku")), false, "")
	card.ribbon_text = "◆ NEW ◆"                      # display only — buttons decide
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dcol.add_child(card)
	cards.add_child(dcol)
	for si in Gear.SLOTS:
		var ecol := VBoxContainer.new()
		ecol.alignment = BoxContainer.ALIGNMENT_CENTER
		ecol.add_theme_constant_override("separation", 7)
		ecol.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if si < _d.gear.size():
			var oid := String(_d.gear[si])
			var oit := GearCatalog.item(oid)
			UiKit.title_in(ecol, "· EQUIPPED ·", 12, Palette.TEXT_DIM)
			var ocard := RelicCard.new(String(oit.get("name", oid)),
				String(oit.get("desc", "")), "curio",
				String(oit.get("rarity", "haiku")), false, "")
			ocard.ribbon_text = "◆ EQUIPPED · ×%d ◆" % int(_d.gear_charges[oid]) \
				if _d.gear_charges.has(oid) else "◆ EQUIPPED ◆"
			ocard.custom_minimum_size = Vector2(206, 280)
			ocard.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ocard.modulate = Color(1, 1, 1, 0.86)
			ecol.add_child(ocard)
		else:
			UiKit.title_in(ecol, "· FREE SOCKET ·", 12, Palette.TEXT_DIM)
			var ph := GlassPanel.new("WELL", Palette.EDGE)
			ph.custom_minimum_size = Vector2(206, 268)
			var pl := Label.new()
			pl.text = "EMPTY\n\nequipping costs nothing"
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pl.add_theme_font_size_override("font_size", 12)
			pl.add_theme_color_override("font_color", Color(Palette.TEXT_DIM, 0.85))
			pl.set_anchors_preset(Control.PRESET_FULL_RECT)
			ph.add_child(pl)
			ecol.add_child(ph)
		cards.add_child(ecol)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if _d.gear.size() < Gear.SLOTS:
		var eb := Button.new()
		eb.text = "EQUIP"
		eb.custom_minimum_size = Vector2(200, 44)
		eb.pressed.connect(func():
			_gear_equip(id, -1)
			done.call())
		row.add_child(eb)
	else:
		# slots full: equipping means choosing which piece the new one replaces
		for si in _d.gear.size():
			var old := String(_d.gear[si])
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
	if replace_i >= 0 and replace_i < _d.gear.size():
		var old := String(_d.gear[replace_i])
		_gain_tokens(GearCatalog.scrap_value(old))
		_d.gear_charges.erase(old)
		_d.gear[replace_i] = id
	else:
		_d.gear.append(id)
	var it := GearCatalog.item(id)
	if bool(it.get("active", false)):
		_d.gear_charges[id] = int(it.get("charges", 1))

## The map header's curio strip ("" hides it before the first drop).
func _gear_line() -> String:
	if _d.gear.is_empty() and _tokens_now() == 0:
		return ""
	var names: Array = []
	for g in _d.gear:
		var nm := String(GearCatalog.item(String(g)).get("name", String(g)))
		if _d.gear_charges.has(g):
			nm += " ×%d" % int(_d.gear_charges[g])
		names.append(nm)
	var line := "PERIPHERALS:  " + ("  ·  ".join(PackedStringArray(names)) if not names.is_empty() else "—")
	return line + "      ⏣ %d" % _tokens_now()

func _worst_wound() -> float:
	var w := 0.0
	for x in _d.wounds:
		w = maxf(w, float(x))
	return w

## Stack a gear toast under any pending ticket toast (both show on the next map).
func _toast_add(msg: String) -> void:
	_d.toast = msg if _d.toast == "" else _d.toast + "\n" + msg

## A floor Seal is down (but not the last): PRIVILEGE ELEVATION — descend to the
## next ring carrying the party's integrity/wounds/mana, or bank out to the Rift.
## Draft 2.0 REFORGE (the raid's boon draft): mint Tokens from this fight's skill, then
## offer 1-of-3 (rarity-weighted, synergy slot, build-your-verb pieces). Taking one folds
## it into `_d.run.boons` — it rides every future pull. Pool exhausted / no run = skip.
func _show_boon_draft(done: Callable) -> void:
	if _d.run == null:
		done.call()
		return
	# FRAMEWORK: the FIRST draft is where you wire your Combo rig (any reworked class), then boons.
	if _fw() != "" and _d.run.rig.is_empty():
		_show_rig_wire(func(): _show_boon_draft(done))
		return
	if _ctrl != null and _ctrl.state != null:
		_gain_tokens(Draft.mint(_ctrl.state, _d.run.char_class))  # routes through Hashgrinder ×2
	# COMMANDER: after YOUR reforge, you draft each AI raider's boon too. Build the
	# callable chain back-to-front so it runs you → the AI seats in SEAT_KEYS order.
	var chain := done
	var order: Array = []
	for key in RaidNet.SEAT_KEYS:
		if _d.ai_runs.has(key):
			order.append(key)
	order.reverse()
	for key in order:
		var k := String(key)
		var next := chain
		chain = func(): _show_seat_draft(k, next)
	_show_seat_draft(_seat_key, chain)

## One REFORGE screen for one seat — yours or a commanded AI raider's (COMMANDER).
## AI drafts spend the SHARED ⏣ bank: Draft's economy reads run.tokens, so the bank
## is mirrored into the AI run for the screen and the remainder banked back out.
func _show_seat_draft(key: String, done: Callable) -> void:
	var mine: bool = key == _seat_key
	var run: RunState = _d.run if mine else (_d.ai_runs.get(key) as RunState)
	if run == null:
		done.call()
		return
	if not mine and _d.run != null:
		run.tokens = _d.run.tokens
	# CURIO Expansion Bus (your seat only): +1 slot → a 1-of-4 draft.
	var picks := Draft.roll_offers(run, 1 if (mine and _d.gear.has("expansion_bus")) else 0)
	if picks.is_empty():
		done.call()
		return
	_screen = "draft"
	_clear()
	var extras: Array = []
	if run.tokens > 0:
		extras.append("%d Tokens banked — REROLL / LOCK a card." % run.tokens)
	var disp := "THE BLOOMWEAVER" if (key == "healer" and run.char_class == "bloomweaver") \
		else String(SEAT_NAMES.get(key, "RAIDER"))
	var headline := "REFORGE — the kill reshapes your kit" if mine \
		else "REFORGE — %s · AI ALLY" % disp
	var flavor := "Take one — every piece forges into your set." if mine \
		else "You command the build — the AI only drives the rotation."
	var ds := DraftScreen.new(run, picks, headline, flavor, extras, Palette.GOLD)
	ds.free_reroll = mine and _d.gear.has("hot_reload")  # CURIO Hot Reload (your seat only)
	ds.boon_taken.connect(func(boon: Dictionary):
		Draft.take(run, boon)
		if mine:
			_d.taken_boons.append(boon)      # for the build panel (title + rarity)
			# ARMORY: the pick visibly upgrades its armor slot (toast on the next map)
			var slot := ArmorSlots.slot_of(boon)
			var n := int((ArmorSlots.summarize(_d.taken_boons)[slot] as Dictionary)["count"])
			_toast_add("⚒  %s REFORGED — %s is piece %d" % [
				ArmorSlots.pretty(slot), String(boon.get("title", "?")), n])
		else:
			if _d.run != null:
				_d.run.tokens = run.tokens   # bank the remainder back to the shared pool
			_toast_add("⚒  %s takes %s" % [disp, String(boon.get("title", "?"))])
		done.call())
	_ui.add_child(ds)
	# ARMORY: the set-so-far stands beside YOUR forge (cards stay centered)
	if mine and (not _d.taken_boons.is_empty() or not _d.gear.is_empty()):
		var doll := ArmorDoll.new()
		UiKit.place(doll, 0.0, 0.5, 0.0, 0.5, 26, -int(ArmorDoll.H) / 2,
			26 + int(ArmorDoll.W), int(ArmorDoll.H) / 2)
		_ui.add_child(doll)
		doll.set_build(_d.taken_boons, _d.gear, _d.gear_charges)
		doll.inspect_requested.connect(_open_armor_modal)

## ARMORY-UI: the YOUR SET modal — opened by clicking any doll socket; Esc /
## click-outside / ✕ close it (raid_hud._input routes Esc while it lives).
func _open_armor_modal() -> void:
	if _armor_modal != null or _d.run == null:
		return
	var crest := "%s  ·  %s" % [String(_seat_key).to_upper(), String(_aspect).capitalize()]
	var m := ArmorModal.new(_d.taken_boons, _d.gear, _d.gear_charges, _tokens_now(), crest)
	m.closed.connect(_close_armor_modal)
	_ui.add_child(m)
	_armor_modal = m

func _close_armor_modal() -> void:
	if _armor_modal != null:
		_armor_modal.queue_free()
	_armor_modal = null

# ============================================================ TEMPO REWORK — Creed / Module picks
## The framework picks only exist for a HUMAN blade running the reworked class (Twinfang).
## Every other seat/class skips straight through — empty is fine (per Bill: non-conforming
## classes leave empty pages). Offline plumbing; online carry is a later follow-up.
func _blade_tempo_human() -> bool:
	return _seat_key == "blade" and _seat_cls_now() == "twinfang"

## The CLASS-FRAMEWORK provider for the HUMAN seat: which reworked class's Creed/Module/Rig
## content drives the pick screens, or "" if this seat's class has no framework yet. Twinfang
## on the blade, the Brew (Alchemist) on the caster; every other seat/class skips the screens
## (empty pages — per Bill, non-conforming classes leave them blank). Generalizes the old
## _blade_tempo_human() gate so a second reworked class snaps onto the same ceremony.
func _fw() -> String:
	if _seat_key == "blade" and _seat_cls_now() == "twinfang":
		return "twinfang"
	if _seat_key == "caster" and _seat_cls_now() == "alchemist":
		return "alchemist"
	if _seat_key == "healer" and _seat_cls_now() == "well":
		return "well"
	if _seat_key == "tank" and _seat_cls_now() == "duelist":
		return "duelist"
	return ""

## Creed data dispatch (both classes mirror the TwinfangCreeds static API).
func _fw_creed_ids(fw: String) -> Array:
	if fw == "alchemist":
		return AlchemistCreeds.v1_ids()
	if fw == "well":
		return WellCreeds.v1_ids(_aspect)      # per-spec pools (brim vs draw)
	if fw == "duelist":
		return DuelistCreeds.v1_ids()
	return TwinfangCreeds.v1_ids()

func _fw_creed(fw: String, id: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistCreeds.get_creed(id)
	if fw == "well":
		return WellCreeds.get_creed(id)
	if fw == "duelist":
		return DuelistCreeds.get_creed(id)
	return TwinfangCreeds.get_creed(id)

## Module data dispatch. `_fw_module_offer_ids` applies creed-aware filtering (ALCHEMIST
## verdict 6): the Purist never draws a burst/detonation module (Fermentation, Vessel).
func _fw_module_offer_ids(fw: String, creed: String) -> Array:
	if fw == "well":
		return WellModules.built_ids()         # no Well creed hides a module in v1
	if fw == "duelist":
		return DuelistModules.built_ids()
	if fw != "alchemist":
		return TwinfangModules.built_ids()
	var out: Array = []
	for id in AlchemistModules.built_ids():
		if creed != "" and AlchemistModules.has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		out.append(id)
	return out

func _fw_module(fw: String, id: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistModules.get_module(id)
	if fw == "well":
		return WellModules.get_module(id)
	if fw == "duelist":
		return DuelistModules.get_module(id)
	return TwinfangModules.get_module(id)

## Rig data dispatch (both classes mirror the TwinfangRig static API).
func _fw_rig_when_table(fw: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistRig.WHENS
	if fw == "well":
		return WellRig.WHENS
	if fw == "duelist":
		return DuelistRig.WHENS
	return TwinfangRig.WHENS

func _fw_rig_then_table(fw: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistRig.THENS
	if fw == "well":
		return WellRig.THENS
	if fw == "duelist":
		return DuelistRig.THENS
	return TwinfangRig.THENS

func _fw_rig_describe(fw: String, w: String, t: String) -> String:
	if fw == "alchemist":
		return AlchemistRig.describe(w, t)
	if fw == "well":
		return WellRig.describe(w, t)
	if fw == "duelist":
		return DuelistRig.describe(w, t)
	return TwinfangRig.describe(w, t)

## The 3-of-N WHEN + THEN offers for the wiring board, creed-filtered (verdict 6: the Purist
## board hides the burst WHENs Ripe/Perfect Wave and the Overfill THEN). Twinfang: unfiltered.
func _fw_rig_offered(fw: String, creed: String, rng) -> Dictionary:
	if fw == "well":
		# WELL rig WHENs are per-spec (Brim landings vs Draw releases) — scope to the aspect.
		var wp: Array = []
		for id in WellRig.when_ids():
			if WellRig.when_spec(String(id)) == _aspect:
				wp.append(id)
		return {"whens": WellRig.offer(wp, rng, 3), "thens": WellRig.offer(WellRig.then_ids(), rng, 3)}
	if fw == "duelist":
		return {"whens": DuelistRig.offer(DuelistRig.base_when_ids(), rng, 3), "thens": DuelistRig.offer(DuelistRig.then_ids(), rng, 3)}
	if fw != "alchemist":
		return {"whens": TwinfangRig.offer(TwinfangRig.when_ids(), rng, 3),
			"thens": TwinfangRig.offer(TwinfangRig.then_ids(), rng, 3)}
	var wpool: Array = []
	for id in AlchemistRig.when_ids():
		if creed != "" and AlchemistRig.when_has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		wpool.append(id)
	var tpool: Array = []
	for id in AlchemistRig.then_ids():
		if creed != "" and AlchemistRig.then_has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		tpool.append(id)
	return {"whens": AlchemistRig.offer(wpool, rng, 3), "thens": AlchemistRig.offer(tpool, rng, 3)}

## Run-start: SWEAR A CREED — the risk temperament for the whole descent (§3). Forced pick.
func _show_creed_pick(done: Callable) -> void:
	var fw := _fw()
	if _d.run == null or fw == "" or _d.run.creed != "":
		done.call()
		return
	var ids: Array = _fw_creed_ids(fw).duplicate()         # the shipping pool (grows with unlocks)
	if ids.size() > 3 and _d.run.draft_rng != null:          # sample 3 deterministically when it's bigger
		for i in range(ids.size() - 1, 0, -1):
			var j := int(_d.run.draft_rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
		ids = ids.slice(0, 3)
	_screen = "creed"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -430, 120, 430, 235)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "SWEAR A CREED", 34, Palette.CRIMSON)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	var sub := "H O W   Y O U   P A Y   F O R   A   S L I P  —  one vow, the whole run"
	if fw == "alchemist":
		sub = "H O W   Y O U   B R E W  —  one posture, the whole run"
	elif fw == "well":
		sub = "H O W   Y O U   T E N D   T H E   W E L L  —  one temperament, the whole run"
	UiKit.title_in(head, sub, 15, Palette.TEXT_DIM)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -370, -150, 370, 175)
	_ui.add_child(box)
	for id in ids:
		var c: Dictionary = _fw_creed(fw, String(id))
		var card := AspectCard.new(String(c.get("name", id)) + "  ·  " + String(c.get("kicker", "")),
			String(c.get("blurb", "")), Palette.CRIMSON, "flurry")
		card.chosen.connect(_pick_creed.bind(String(id), done))
		box.add_child(card)

func _pick_creed(id: String, done: Callable) -> void:
	if _d.run != null:
		_d.run.creed = id
	_toast_add("⚔  Creed sworn — %s" % String(_fw_creed(_fw(), id).get("name", id)))
	done.call()

## End of Floor 1: INSTALL A MODULE — a new HUD gauge + way to play (§4). Forced pick.
func _show_module_pick(done: Callable) -> void:
	var fw := _fw()
	if _d.run == null or fw == "":
		done.call()
		return
	var avail: Array = []
	for id in _fw_module_offer_ids(fw, _d.run.creed):        # implemented + creed-allowed modules
		if not _d.run.modules.has(String(id)):
			avail.append(String(id))
	if avail.is_empty():
		done.call()
		return
	_screen = "module"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -430, 120, 430, 235)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "INSTALL A MODULE", 34, Palette.FLOW)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "A   N E W   G A U G E ,   A   N E W   W A Y   T O   P L A Y  —  pick one", 15, Palette.TEXT_DIM)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -370, -150, 370, 175)
	_ui.add_child(box)
	for id in avail:
		var m: Dictionary = _fw_module(fw, String(id))
		var card := AspectCard.new(String(m.get("name", id)) + "  ·  " + String(m.get("kicker", "")),
			String(m.get("blurb", "")), Palette.FLOW, "flurry")
		card.chosen.connect(_pick_module.bind(String(id), done))
		box.add_child(card)

func _pick_module(id: String, done: Callable) -> void:
	if _d.run != null:
		_d.run.modules[id] = true
	_toast_add("⬡  Module installed — %s" % String(_fw_module(_fw(), id).get("name", id)))
	done.call()

# ---- TEMPO §5: the ONE Combo rig — wire a WHEN → THEN (first draft; re-wire at Floor 2) ----
var _rig_w := ""
var _rig_t := ""
var _rig_readout: Label = null
var _rig_confirm: Button = null

## WIRE YOUR COMBO — pick 1 of 3 WHENs + 1 of 3 THENs; the readout shows the computed number
## (the greed-dial payout: rare moments pay more, if you can land them). Blade/Tempo only.
func _show_rig_wire(done: Callable) -> void:
	var fw := _fw()
	if _d.run == null or fw == "":
		done.call()
		return
	var offered := _fw_rig_offered(fw, _d.run.creed, _d.run.draft_rng)
	var whens: Array = offered["whens"]
	var thens: Array = offered["thens"]
	_rig_w = ""
	_rig_t = ""
	_screen = "rig"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -450, 46, 450, 150)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "RE-WIRE YOUR COMBO" if not _d.run.rig.is_empty() else "WIRE YOUR COMBO", 32, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "one MOMENT → one PAYOFF, all run  —  rare moments pay MORE, if you can land them", 14, Palette.TEXT_DIM)
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 54)
	UiKit.place(cols, 0.5, 0.5, 0.5, 0.5, -440, -180, 440, 150)
	_ui.add_child(cols)
	cols.add_child(_rig_col("WHEN — the moment", whens, _fw_rig_when_table(fw), true))
	cols.add_child(_rig_col("THEN — the payoff", thens, _fw_rig_then_table(fw), false))
	var foot := VBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 12)
	UiKit.place(foot, 0.5, 1, 0.5, 1, -320, -160, 320, -28)
	_ui.add_child(foot)
	_rig_readout = UiKit.title_in(foot, "pick a moment and a payoff", 18, Palette.TEXT_DIM)
	_rig_confirm = Button.new()
	_rig_confirm.text = "WIRE IT ▸"
	_rig_confirm.custom_minimum_size = Vector2(200, 44)
	_rig_confirm.disabled = true
	_rig_confirm.pressed.connect(func():
		_d.run.rig = {"when": _rig_w, "then": _rig_t}
		_toast_add("⚡  Combo wired — " + _fw_rig_describe(fw, _rig_w, _rig_t))
		done.call())
	foot.add_child(_rig_confirm)

func _rig_col(label: String, ids: Array, table: Dictionary, is_when: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	UiKit.title_in(col, label, 13, Palette.CRIMSON if is_when else Palette.FLOW)
	var group := ButtonGroup.new()
	var accent: Color = Palette.CRIMSON if is_when else Palette.FLOW
	for id in ids:
		var d: Dictionary = table.get(String(id), {})
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(330, 84)
		b.clip_text = false
		# The blurb is too long for one clipped line — render name + WRAPPED blurb as child
		# labels (mouse passes through to the button, so the whole card stays clickable).
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 3)
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 12; box.offset_top = 8; box.offset_right = -12; box.offset_bottom = -8
		var name_l := Label.new()
		name_l.text = String(d.get("name", id))
		name_l.add_theme_font_size_override("font_size", 15)
		name_l.add_theme_color_override("font_color", accent)
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(name_l)
		var blurb_l := Label.new()
		blurb_l.text = String(d.get("blurb", ""))
		blurb_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb_l.add_theme_font_size_override("font_size", 11)
		blurb_l.add_theme_color_override("font_color", Palette.TEXT_DIM)
		blurb_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(blurb_l)
		b.add_child(box)
		if is_when:
			b.toggled.connect(_rig_on_when.bind(String(id)))
		else:
			b.toggled.connect(_rig_on_then.bind(String(id)))
		col.add_child(b)
	return col

func _rig_on_when(on: bool, id: String) -> void:
	if on: _rig_w = id
	_rig_refresh()

func _rig_on_then(on: bool, id: String) -> void:
	if on: _rig_t = id
	_rig_refresh()

func _rig_refresh() -> void:
	if _rig_readout == null:
		return
	if _rig_w != "" and _rig_t != "":
		_rig_readout.text = _fw_rig_describe(_fw(), _rig_w, _rig_t)
		_rig_readout.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
		if _rig_confirm != null:
			_rig_confirm.disabled = false
	else:
		_rig_readout.text = "pick a moment and a payoff"
		if _rig_confirm != null:
			_rig_confirm.disabled = true

func _show_floor_cleared() -> void:
	_screen = "end"
	_clear()
	var fl: Dictionary = RaidContent.FLOORS[_d.floor_i]
	var nxt: Dictionary = RaidContent.FLOORS[_d.floor_i + 1]
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := UiKit.title_in(box, "PRIVILEGE ELEVATED", 52, Palette.WIN)
	banner.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, String(fl["elev"]), 16, Palette.TEXT)
	UiKit.title_in(box, String((RaidContent.QUIPS.get(String(fl["seal"]), {}) as Dictionary).get("win", "")), 13, Palette.TEXT_DIM)
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
	_d.map = null
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := UiKit.title_in(box, "ROOT ACCESS GRANTED", 56, Palette.WIN)
	banner.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, "Ring 0 is yours. CLAUDE MYTHOS is unplugged. THE TAKEOVER ends — Realm 1 cleared.", 17, Palette.TEXT)
	UiKit.title_in(box, String((RaidContent.QUIPS.get("mythos", {}) as Dictionary).get("win", "")), 13, Palette.TEXT_DIM)
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
			_acfg = AlchemistConfig.new()
			return _acfg.loadout(_aspect)
		"healer":
			if _healer_cls == "bloomweaver":
				_bcfg = BloomweaverConfig.new()
				return _bcfg.order(_aspect)
			_wcfg = WellConfig.new()
			return _wcfg.loadout(_aspect)
		_:
			return ["cleave", "rampage", "fortify", ("vindicate" if _aspect == "warden" else "avalanche")]

## The seat's defensive-verb label (the tank's depends on its Aspect; the caster's
## on its class — the Alchemist has no kick, it dodges like everyone else).
func _verb() -> String:
	match _seat_key:
		"tank":
			return "PARRY" if _aspect == "warden" else "DODGE"
		"caster":
			return "DODGE"   # the Alchemist has no kick — nobody does until pillar #3
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
	_add_dev_tools()
	_add_build_panel()

	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_shake_root)

	_bar = BossBar.new()
	UiKit.place(_bar, 0.5, 0, 0.5, 0, -340, 52, 340, 104)
	_shake_root.add_child(_bar)

	_dial = BossCastDial.new()
	_dial.verb = _verb()
	# reticle mode, ringed around the Riftmaw puppet (x-anchor = the boss slot)
	_dial.show_sigil = false
	UiKit.place(_dial, 0.72, 0, 0.72, 0, -210, 128, 210, 640)
	_shake_root.add_child(_dial)

	# the Judgment Channel under the reticle — seat-aware: parry gate for the
	# tank, dodge gate for the blade, clean-kick band for the caster, barrage
	# timing for the healer; off-target swings fly dim with their victim's name
	_judge = StrikeJudge.new()
	_judge.verb = _verb()
	UiKit.place(_judge, 0.72, 0, 0.72, 0, -260, 648, 260, 752)
	_shake_root.add_child(_judge)

	# every fight opens with a ceremony: the boss's name-card burns in and off
	BossIntro.play(_ui, s.encounter.name)
	_recap_stats = {}              # a fresh reckoning per fight

	# the raid meter — right rail: all four raiders ranked, engine-truth accounting;
	# M cycles ranking / your spells / hidden. Works identically offline and online
	# (it only READS state — the lockstep replica never notices it).
	_meter = MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg")
	UiKit.place(_meter, 1, 0, 1, 0, -318, 118, -18, 600)
	_ui.add_child(_meter)

	# THE RAID — reliquary TRIAGE CARDS down the left (XL for the healer seat: the
	# frames ARE its combat surface — shield crest, HoT countdown chips, debuff
	# timers). Gold-lit = the boss's victim; for the healer seat the frames are also
	# your click-cast targets. Drag the ≡ header to move the panel (persists);
	# double-click the header to snap it back.
	# XL cards for the healer's 4-seat raid; the 5-frame gate SANDBOX party falls
	# back to the compact cards so the column clears the mana orb.
	var xl_frames := _seat_key == "healer" and s.seats.size() <= 4
	_raid_col_xl = xl_frames
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12 if xl_frames else 10)
	if xl_frames:
		UiKit.place(col, 0, 0.5, 0, 0.5, 22, -276, 334, 276)
	else:
		UiKit.place(col, 0, 0.5, 0, 0.5, 26, -238, 266, 238)
	_ui.add_child(col)              # NOT under shake — the healer aims clicks at these
	_raid_col = col
	var head := Label.new()
	head.text = "≡  THE RAID   ·   ◆ = its gaze" if _seat_key != "healer" else "≡  THE RAID   ·   hover + click-cast"
	head.add_theme_font_size_override("font_size", 12)
	head.add_theme_color_override("font_color", Palette.TEXT_DIM)
	head.mouse_filter = Control.MOUSE_FILTER_STOP
	head.mouse_default_cursor_shape = Control.CURSOR_MOVE
	head.tooltip_text = "Drag to move the raid panel — double-click to reset"
	head.gui_input.connect(_raid_col_input)
	col.add_child(head)
	_frames = []
	for seat in s.seats:
		var fr := RaidFrame.new()
		fr.variant = "xl" if xl_frames else "raid"
		# XL has header room for the explicit tag; the compact card gilds your name
		fr.unit_name = seat.unit_name + (" (YOU)" if seat.is_player and xl_frames else "")
		fr.is_you = seat.is_player
		fr.role = seat.role
		fr.hovered.connect(_on_frame_hover)
		fr.unhovered.connect(_on_frame_unhover)
		col.add_child(fr)
		_frames.append({"seat": seat, "frame": fr})
	_restore_raid_col()

	_aggro_warn = Label.new()
	_aggro_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aggro_warn.add_theme_font_size_override("font_size", 20)
	_aggro_warn.add_theme_color_override("font_color", Palette.CRIMSON)
	_aggro_warn.visible = false
	UiKit.place(_aggro_warn, 0.5, 0, 0.5, 0, -360, 106, 360, 130)
	_shake_root.add_child(_aggro_warn)

	_band = ClassBand.for_hud(self)   # the class's instrument cluster (REFIT P4)
	_band.build()

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
	UiKit.place(pb, 1, 0, 1, 0, -150, 14, -18, 46)
	_ui.add_child(pb)

func _orb(fill: Color, caption: String, right: bool) -> LiquidOrb:
	var o := LiquidOrb.new()
	o.fill = fill
	o.caption = caption
	if right:
		UiKit.place(o, 1, 1, 1, 1, -175, -172, -55, -52)
	else:
		UiKit.place(o, 0, 1, 0, 1, 55, -172, 175, -52)
	_shake_root.add_child(o)
	return o

func _rune_row(off_l: float, off_r: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	UiKit.place(row, 0.5, 1, 0.5, 1, off_l, -160, off_r, -76)
	_shake_root.add_child(row)
	return row

func _hint_line(text: String) -> void:
	var hint := Label.new()
	hint.text = text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.GOLD_DIM)
	UiKit.place(hint, 0.5, 1, 0.5, 1, -330, -70, 330, -46)
	_shake_root.add_child(hint)

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
	UiKit.place(win, 0, 0, 0, 0, 14, 14, 116, 44)     # top-left corner, out of the way
	_ui.add_child(win)

func _dev_win() -> void:
	if _ctrl == null or _ctrl.state == null or _ctrl.state.over:
		return
	var s: CombatState = _ctrl.state
	# overkill the boss (and any active add) — the normal update loop then resolves
	# the win exactly like a real kill, so drops/floor-advance run unchanged.
	CombatCore.damage_boss(s, s.seats[0], s.boss.hp + s.boss.hp_max + 1.0)

## The healer's spellbook for the current class (Well charge-book / Bloomweaver Sap).
func _hspells() -> Dictionary:
	if _healer_cls == "bloomweaver":
		return _bcfg.spells if _bcfg != null else {}
	return _wcfg.book if _wcfg != null else {}

func _signature() -> String:
	return "wildbloom" if _aspect == "wildgrove" else "briarheart"

## The player's assembled verb, in the class's own words (build-your-verb boons).
const VERB_LABEL := {"tank": "GUARD", "blade": "RHYTHM", "caster": "KICK", "healer": "TRIAGE"}

## The verb label shown on the build panel (Bloomweaver's verb is the GARDEN;
## the Alchemist's is the BREW).
func _verb_label() -> String:
	if _seat_key == "healer" and _healer_cls == "bloomweaver":
		return "GARDEN"
	if _seat_key == "healer" and _healer_cls == "well":
		return "THE WELL"
	if _seat_key == "caster" and _caster_cls == "alchemist":
		return "BREW"
	return String(VERB_LABEL.get(_seat_key, "BUILD"))

func _verb_summary_lines() -> Array:
	if _d.run == null:
		return []
	match _seat_key:
		"blade":
			# TEMPO §5: show the wired Combo rig in the build panel (Twinfang only).
			if _blade_cls == "twinfang" and not _d.run.rig.is_empty():
				return ["⚡ Combo — " + TwinfangRig.describe(
					String(_d.run.rig.get("when", "")), String(_d.run.rig.get("then", "")))]
			return TwinfangBoons.verb_summary(_d.run.boons, _aspect)
		"caster":
			# show the wired Combo rig in the build panel (the Brew's rig)
			if not _d.run.rig.is_empty():
				return ["⚡ Combo — " + AlchemistRig.describe(
					String(_d.run.rig.get("when", "")), String(_d.run.rig.get("then", "")))]
			return []
		"healer":
			if _healer_cls == "well":
				# MENDER-PLAN §4: show the wired Combo rig in the build panel (the Well's rig)
				if not _d.run.rig.is_empty():
					return ["⚡ Combo — " + WellRig.describe(
						String(_d.run.rig.get("when", "")), String(_d.run.rig.get("then", "")))]
				return WellBoons.verb_summary(_d.run.boons, _aspect)
			return BloomweaverBoons.verb_summary(_d.run.boons, _aspect)
		_: return DuelistBoons.verb_summary(_d.run.boons, _aspect)

## BUILD PANEL: a compact top-right readout of the assembled verb + drafted boons —
## so you can always see the run you've drafted. Offline descent only (_d.run present;
## online boons ride the spec later). Rebuilt each fight, so it reflects new picks.
func _add_build_panel() -> void:
	if _d.run == null:               # online + offline descents both carry a boon run now
		return
	var lines := _verb_summary_lines()
	if _d.taken_boons.is_empty() and lines.is_empty():
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
	if not _d.taken_boons.is_empty():
		# ARMORY: the build reads as a SET — pieces grouped under their armor slots
		var cap := Label.new()
		cap.text = "THE SET  ·  %d PIECES" % _d.taken_boons.size()
		cap.add_theme_font_size_override("font_size", 10)
		cap.add_theme_color_override("font_color", Palette.GOLD_DIM)
		col.add_child(cap)
		var summed := ArmorSlots.summarize(_d.taken_boons)
		for slot in ArmorSlots.ORDER:
			var e: Dictionary = summed[slot]
			if int(e["count"]) == 0:
				continue
			var sl := Label.new()
			sl.text = "%s  +%d" % [ArmorSlots.pretty(slot), int(e["count"])]
			sl.add_theme_font_size_override("font_size", 11)
			sl.add_theme_color_override("font_color", Palette.rarity_color(String(e["best"])))
			col.add_child(sl)
		for b in _d.taken_boons:
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
	_pause = PauseOverlay.new(_seat_cls_now(), _aspect,
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
## header. Only the map/campaign run carries a boon pool (`_d.run`); a bare Seal pull has
## none → []. Scans the current class's boon pools by id.
func _owned_boon_labels() -> Array:
	if _d.run == null or _d.run.boons.is_empty():
		return []
	var pools: Array = []
	match _seat_key:
		"blade": pools = [TwinfangBoons.SHARED, TwinfangBoons.TEMPO, TwinfangBoons.VENOM]
		"caster": pools = [AlchemistBoons.SHARED, AlchemistBoons.BREW]
		"healer":
			if _healer_cls == "bloomweaver":
				pools = [BloomweaverBoons.SHARED, BloomweaverBoons.GROVE, BloomweaverBoons.THORN]
			else:
				pools = [WellBoons.SHARED, WellBoons.BRIM, WellBoons.DRAW]
		_: pools = [DuelistBoons.POOL]
	var out: Array = []
	for pool in pools:
		for b in pool:
			if _d.run.boons.get(String(b.get("id", "")), false):
				out.append({"title": b.get("title", b.get("id", "?")),
					"rarity": b.get("rarity", "haiku"), "type": b.get("type", "")})
	return out

# ============================================================ INPUT
## The raid panel is MOVABLE: drag its ≡ header anywhere (clamped on-screen, saved
## per layout size to user://rift_ui.cfg); double-click the header to snap back.
const UI_CFG := "user://rift_ui.cfg"

func _raid_col_input(ev: InputEvent) -> void:
	if _raid_col == null:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.double_click:
			_raid_drag = false
			_reset_raid_col()
		elif ev.pressed:
			_raid_drag = true
			_raid_drag_off = _raid_col.global_position - ev.global_position
		else:
			_raid_drag = false
			_save_raid_col()
	elif ev is InputEventMouseMotion and _raid_drag:
		var vp := _raid_col.get_viewport_rect().size
		var p: Vector2 = ev.global_position + _raid_drag_off
		p.x = clampf(p.x, 0.0, maxf(0.0, vp.x - _raid_col.size.x))
		p.y = clampf(p.y, 0.0, maxf(0.0, vp.y - _raid_col.size.y))
		_raid_col.global_position = p

func _raid_col_key() -> String:
	return "col_xl" if _raid_col_xl else "col_std"

func _save_raid_col() -> void:
	var cf := ConfigFile.new()
	cf.load(UI_CFG)                    # keep whatever else lives in the file
	cf.set_value("raid_frames", _raid_col_key(),
		Vector2(_raid_col.offset_left, _raid_col.offset_top))
	cf.save(UI_CFG)

func _restore_raid_col() -> void:
	var cf := ConfigFile.new()
	if cf.load(UI_CFG) != OK:
		return
	if not cf.has_section_key("raid_frames", _raid_col_key()):
		return   # nothing saved for this layout (a null default still ERROR-spams the logs)
	var v = cf.get_value("raid_frames", _raid_col_key(), null)
	if v is Vector2:
		# saved as offsets off the panel's own anchors — size preserved
		var wdt := _raid_col.offset_right - _raid_col.offset_left
		var hgt := _raid_col.offset_bottom - _raid_col.offset_top
		_raid_col.offset_left = v.x
		_raid_col.offset_right = v.x + wdt
		_raid_col.offset_top = v.y
		_raid_col.offset_bottom = v.y + hgt

func _reset_raid_col() -> void:
	if _raid_col_xl:
		UiKit.place(_raid_col, 0, 0.5, 0, 0.5, 22, -276, 334, 276)
	else:
		UiKit.place(_raid_col, 0, 0.5, 0, 0.5, 26, -238, 266, 238)
	var cf := ConfigFile.new()
	if cf.load(UI_CFG) == OK and cf.has_section_key("raid_frames", _raid_col_key()):
		cf.erase_section_key("raid_frames", _raid_col_key())
		cf.save(UI_CFG)

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
		# ARMORY-UI: the YOUR SET modal swallows keys while open; Esc closes only it
		if _armor_modal != null:
			if event.keycode == KEY_ESCAPE:
				_close_armor_modal()
			return
		if event.keycode == KEY_ESCAPE:
			if _screen == "combat":
				_toggle_pause()      # Esc in a fight = PAUSE (Quit-to-menu lives inside it)
				return
			if _net != null:
				_net.close()
			_show_home()   # ONE HUD: home IS the front door (main.tscn is retired)
			return
		if _screen != "combat":
			return
		if event.keycode == KEY_P:
			_toggle_pause()
			return
		if event.keycode == KEY_M and _meter != null:
			_meter.cycle()
			return
		if _band != null:
			_band.key_pressed(event.keycode)   # the class's key map lives on its band
		return
	# hold-release verbs (Alchemist pour / FERMATA release / Well DRAW): key-ups
	# route to the band — a band that owns a release grammar consumes them.
	if event is InputEventKey and not event.pressed and _pause == null \
			and _screen == "combat" and _band != null:
		if _band.key_released(event):
			return
	# mouse grammar (healer click-cast, the Well/DRAW release styles) — band-owned.
	if _pause == null and _screen == "combat" and _band != null \
			and event is InputEventMouseButton:
		_band.mouse(event)

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
	_cast_on_well(seat, id)

## Well click-cast: mirror the CHARGES/GCD/cast gates for the gold/dim frame flash.
func _cast_on_well(seat: Seat, id: String) -> void:
	var s := _ctrl.state
	var p := _ctrl.player()
	var sp: Dictionary = _wcfg.book.get(id, {})
	if sp.is_empty():
		return
	var offgcd := bool(sp.get("offgcd", false))
	var ready := true
	if not offgcd and s.tick < p.gcd_until_tick: ready = false
	if s.tick < int(p.cooldowns.get(id, 0)): ready = false
	if not offgcd and not p.casting.is_empty(): ready = false
	if int(p.vars.get("charges", 0)) < int(sp.get("charges", 0)): ready = false
	if id == "dispel" and seat.debuff.is_empty(): ready = false
	var fr := _frame_of(seat)
	if fr != null:
		fr.flash(Palette.GOLD if ready else Palette.TEXT_DIM)
	if ready:
		_ctrl.human({"type": "ability", "id": id, "target": seat if bool(sp.get("target", false)) else null})
		if _aspect == "draw" and float(sp.get("cast", 0.0)) > 0.0 and _band is WellBand:
			(_band as WellBand).mouse_ms = Time.get_ticks_msec()   # arm mouse hold-release for this cast

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
	var kit := p.kit as BloomweaverKit
	if id == "bloom" and (kit == null or kit._find_growth(seat) < 0): ready = false   # nothing to cash
	if id == "growth" and kit != null:
		var gbi := kit._find_growth(seat)
		if gbi >= 0 and int(seat.hots[gbi].get("stacks", 1)) >= kit._soft_cap() \
				and int(seat.hots[gbi].get("stacks", 1)) < _bcfg.hard_cap \
				and float(p.vars.get("verdance", 0.0)) < _bcfg.overcap_verd:
			ready = false                                                            # over-cap needs Verdance
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
	if _oath_lbl != null and not _d.oath_broken and not _d.sworn.is_empty() and p != null \
			and Oaths.broken_live(_d.sworn.get("deed", {}), s, p):
		_d.oath_broken = true
		_oath_lbl.text = "⚖ OATH BROKEN — %s" % String(_d.sworn.get("deed_text", ""))
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
	if _band != null:
		_band.render(s, p, obs)

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
	var hzf := float(s.config.fixed_hz)
	for e in _frames:
		var seat: Seat = e["seat"]
		var fr: RaidFrame = e["frame"]
		fr.frac = seat.hp_frac()
		fr.hp = int(round(seat.hp))
		fr.maxhp = int(round(seat.hp_max))
		fr.absorb_frac = (seat.absorb / seat.hp_max) if seat.hp_max > 0.0 else 0.0
		fr.absorb_val = seat.absorb if seat.alive() else 0.0
		fr.ward_remain = (float(seat.ward_until_tick - s.tick) / hzf) \
			if (seat.alive() and seat.absorb > 0.0 and seat.ward_until_tick >= 0) else -1.0
		fr.hot_count = seat.hots.size()
		fr.hots_rich = _rich_hots(seat, hzf) if seat.alive() else []
		fr.has_debuff = not seat.debuff.is_empty()
		fr.debuff_remain = (float(int(seat.debuff["left"]) - int(seat.debuff["acc"])) / hzf) \
			if not seat.debuff.is_empty() else -1.0
		fr.dead = not seat.alive()
		fr.bloodied = seat.alive() and seat.hp_frac() <= 0.4
		fr.incoming_frac = 0.0
		fr.incoming_dmg_frac = 0.0
		fr.incoming_lethal = false
		fr.ripe = false                      # Bloomweaver drives this per-frame below
		fr.glint = CombatCore.vuln_until(s, s.seats.find(seat), &"glint") >= 0   # Well: this ally is glinting (rides the vuln stack since 855ac2f)
		# Well/BRIM: the pour window lives on EVERY frame, always (the aim IS the party bars)
		fr.brim_line = _wcfg.brim_band if (_seat_key == "healer" and _healer_cls == "well" \
			and _aspect == "brim" and _wcfg != null) else 0.0
		if _seat_key == "healer":
			fr.is_target = (seat == _hover_seat) or (_hover_seat == null and seat == _focus_seat)
		else:
			fr.is_target = seat == victim and seat.alive()
	if _seat_key == "healer":
		_healer_predictions(s, obs)
	var aggro_me := bool(obs.get("aggro_me", false))
	match _seat_key:
		"tank":
			_aggro_warn.text = "IT DRIFTS TO YOUR RAID  —  PLAY CLEAN, IT COMES BACK"
			_aggro_warn.visible = not aggro_me and not s.over
		"blade", "caster":
			_aggro_warn.text = "IT'S HUNTING YOU  —  DODGE!"
			_aggro_warn.visible = aggro_me and not s.over
		_:
			_aggro_warn.visible = false

## HoT source → [rune icon id, full duration s] — feeds the frame's countdown chips.
## Durations mirror the kits (renew hot_dur 9 · afterglow/lingering_grace/laststand 3
## · growth 9); a refresh past the listed max just clamps the sweep full.
const HOT_META := {
	"renew": ["renew", 9.0], "afterglow": ["flash", 3.0],
	"lingering_grace": ["mend", 3.0], "laststand": ["laststand", 3.0],
	"growth": ["growth", 9.0], "hot": ["renew", 6.0],
}

func _rich_hots(seat: Seat, hzf: float) -> Array:
	var out: Array = []
	for h in seat.hots:
		var src := String(h.get("src", "hot"))
		var meta: Array = HOT_META.get(src, HOT_META["hot"])
		out.append({"icon": String(meta[0]), "src": src,
			"remain": maxf(float(int(h["left"]) - int(h["acc"])) / hzf, 0.0),
			"total": float(meta[1]),
			"count": int(h.get("stacks", 1))})   # Bloomweaver seed bed: show the stack depth (×N)
	return out

## Healer-only frame overlays: telegraphed incoming damage + the cast's heal
## ghost / (Bloomweaver) seed-bed COOK state on every frame + the BLOOM cash-out on hover.
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
	# Bloomweaver: the seed bed's COOK state on every frame (gold chip at full ramp) +
	# the BLOOM value a cash-out would restore right now, ghosted on the hovered frame.
	if _healer_cls == "bloomweaver":
		for pe in obs.get("party", []):
			var u: Seat = pe.get("seat")
			if u == null:
				continue
			var frp := _frame_of(u)
			if frp == null:
				continue
			frp.ripe = bool(pe.get("cooked", false))       # gold chip when the bed is COOKED (full ramp)
			if u == _hover_seat and u.hp_max > 0.0:
				frp.incoming_frac = clampf(float(pe.get("growth_heal", 0.0)) / u.hp_max, 0.0, 1.0)
		return
	# THE WELL: BRIM's landing preview — ghost where the in-flight heal will land, so you
	# can size it into the pour band (base feature per MENDER-PLAN B-V3).
	if _healer_cls == "well":
		var pw := _ctrl.player()
		if pw != null and not pw.casting.is_empty() and _wcfg != null:
			var wcid := String(pw.casting.get("id", ""))
			var wsp: Dictionary = _wcfg.book.get(wcid, {})
			if wsp.has("heal") and bool(wsp.get("target", false)) and pw.casting.get("target") != null:
				var wt: Seat = pw.casting.get("target")
				var wfr := _frame_of(wt)
				if wfr != null:
					wfr.incoming_frac = clampf(float(wsp.get("heal", 0.0)) / maxf(wt.hp_max, 1.0), 0.0, 1.0)
		return
func _cd_frac(p: Seat, s: CombatState, id: String, cd_sec: float) -> float:
	var left := int(p.cooldowns.get(id, 0)) - s.tick
	if left <= 0:
		return 0.0
	return clampf(float(left) / float(CombatCore.to_ticks(cd_sec, s.config.fixed_hz)), 0.0, 1.0)

func _handle_event(ev: Dictionary) -> void:
	var mine := bool(ev.get("player", false))
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	if _band != null:
		_band.on_event(ev, mine)   # gauge juice (ALEMBIC / WELL verdict banners + history)
	RecapPanel.track(_recap_stats, ev)
	match String(ev.get("t", "")):
		"pack_next":
			# PACK: the next member takes the field — the name-card ceremony IS the
			# walk-in banner. The plate/dial rebind free (they read s.encounter live).
			BossIntro.play(_ui, "%s   ·   %d / %d" % [String(ev.get("name", "")),
				int(ev.get("i", 0)) + 1, int(ev.get("n", 0))])
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
		"duel_counter":                       # FLOW=AGGRO: the perfect-parry hit-back (the tank's "look at me")
			if mine:
				_big_text("COUNTER!", Palette.GOLD_BRIGHT, 34)
				_add_shake(4.0)
				_dial.react("impact", 24.0)
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
		# ---- class extras (only fire for the class that emits them; the band
		# flashes its own widgets via _band.on_event — the HUD adds the body) ----
		"strike":
			# GRADED WINDOW (§2c): the band flashes the rhythm bar; the HUD pops the verdict.
			if mine:
				match String(ev.get("result", "")):
					"bullseye":
						_big_text("BULLSEYE!", Palette.GOLD_BRIGHT, 38)
						_add_shake(5.0)
					"perfect":
						_big_text("PERFECT!", Palette.PERFECT, 34)
					"good":
						_big_text("good", Palette.TEXT_DIM, 22, 0.42)
		"snap":
			# FERMATA (EDGE): rode past the lip — the note broke and Flow crashed.
			if mine:
				_big_text("SNAPPED!", Palette.CRIMSON, 36)
				_add_shake(9.0)
		"perfect":
			pass   # the graded "strike" verdict (Bullseye/Perfect) owns the pop now (§2c)
		"flow_lost":
			if mine:
				_big_text("FLOW LOST!", Palette.CRIMSON, 30)
		"rupture":
			_big_text("RUPTURE!", Palette.POISON, 36)
			_add_shake(7.0)
		"coup":
			_big_text("COUP DE GRÂCE!", Palette.PERFECT, 34)
			_add_shake(7.0)
		# ---- the Brew (Alchemist) — the ALEMBIC owns the banners; the HUD adds body ----
		"brew_rupture":
			if mine:
				_add_shake(9.0 if bool(ev.get("peak", false)) else 6.0)
				_dial.react("impact", float(ev.get("amt", 40)))
			else:
				_big_text("the brew RUPTURES", Palette.REACT, 24, 0.5)
		"brew_pour":
			if mine:
				match String(ev.get("grade", "")):
					"spoiled":
						_add_shake(5.0)          # the flinch — you cooked it
					"hot":
						_add_shake(3.0)
		"rig_fire":
			# TEMPO §5 — the Combo rig fired: a small pop so you SEE your build work.
			if mine:
				var tn := String((TwinfangRig.THENS.get(String(ev.get("then", "")), {}) as Dictionary).get("name", "?"))
				_big_text("%s +%d" % [tn, int(ev.get("mag", 0))], Palette.FLOW, 22, 0.5)
		"brew_rig":
			# ALCHEMIST rig fired — same pop, off the Brew's rig vocabulary.
			if mine:
				var tn := String((AlchemistRig.THENS.get(String(ev.get("then", "")), {}) as Dictionary).get("name", "?"))
				_big_text("%s +%d" % [tn, int(ev.get("mag", 0))], Palette.REACT, 22, 0.5)
		"opening":
			# THE OPENING — a dump landed in the boss's vulnerability window
			if mine and String(ev.get("grade", "")) == "peak":
				_big_text("PUNISH!", Palette.GOLD_BRIGHT, 30, 0.5)
				_add_shake(4.0)
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
		"caster": return Palette.REACT
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
	if _zone_live and not _online:
		# THE WORLD (W1): a zone pull resolves — conquest is the ONLY writeback (no
		# wounds, no economy, no oaths out here). A loss just returns the frontier;
		# pull again anytime.
		_zone_live = false
		if won:
			_show_fight_recap(func(): _zone_clear_node(_zone_node))
		else:
			_zone_toast = "the warband withdraws — the frontier holds. Pull again anytime."
			_show_zone()
		return
	if _d.map != null and not _online:
		# Topology floor: persist per-seat integrity + the healer's remaining mana.
		# A raider dead at a WON fight REBOOTS (only a wipe ends the run); the Seal
		# node ends the floor. Integrity/reboot-wound/mana = the ONE rulebook.
		var fcp := _d.cp_view()
		CampaignCore.writeback(fcp, _ctrl.state)
		_d.cp_sync(fcp)
		# GEAR-2: the sworn oath resolves on the fight's final state
		_resolve_oath(_ctrl.state, _ctrl.player(), won)
		if not won:
			_show_end(false)
			return
		# THE DESCENT REBUILD: the node's EFFECTIVE kind drives the win ceremonies
		# (a WILD that revealed a fight pays like the fight it was).
		var ek := RunMap.effective_kind(_d.map.node(_d.node))
		# THE KILL SWITCH: scavenge ⏻ from a cleared trash pull (not the Seal — you cash out there)
		if ek == RunMap.KIND_COMBAT or ek == RunMap.KIND_ELITE:
			var scp := _d.cp_view()
			CampaignCore.skirmish_scavenge(scp)
			_d.cp_sync(scp)
		# ELITE bounty (DESCENT §5): fat ⏣ on top of the curio-roll drop event below.
		# (The keystone 1-of-2 slot is reserved here — lands with the per-class deck
		# slices; no class ships a granter-ready keystone pool yet.)
		if ek == RunMap.KIND_ELITE:
			var bounty := int(ELITE_TOKENS.get(int(RaidContent.FLOORS[_d.floor_i]["ring"]), 4))
			_gain_tokens(bounty)
			_toast_add("☠  ELITE DOWN — bounty claimed (+%d⏣)" % bounty)
		# GEAR-1: the kill's drop ceremony runs first, then the run continues wherever
		# it was headed (map / elevation / campaign clear).
		var after: Callable = _show_map
		if ek == RunMap.KIND_SEAL:
			# a floor Seal fell: elevate to the next ring, or clear the realm on the last
			after = _show_campaign_cleared if _d.floor_i >= RaidContent.FLOORS.size() - 1 \
				else _show_floor_cleared
		# THE RECKONING first — the raid ranked by damage + the fight's biggest hit —
		# THEN gear drop, THEN the boon REFORGE (1-of-3), THEN continue (map/elevate/clear).
		# ARMORY: a Seal kill OR an elite is a drop EVENT here — skirmish repeats pay salvage
		var drop_event: bool = ek == RunMap.KIND_SEAL or ek == RunMap.KIND_ELITE
		var enc_id := String(_ctrl.state.encounter.id)
		_show_fight_recap(func(): _after_drop(enc_id,
			func(): _show_boon_draft(after), drop_event))
		return
	_show_end(won)

## The single biggest DAMAGE hit of the fight — across every raider + source (the meter
## tracks per-source `max`). Returns {src, amt, who} or {} if nothing discrete landed.
func _biggest_hit(s: CombatState) -> Dictionary:
	var best := {}
	for i in s.meter:
		var dmg: Dictionary = (s.meter[i] as Dictionary).get("dmg", {})
		for src in dmg:
			var mx := float((dmg[src] as Dictionary).get("max", 0.0))
			if mx > float(best.get("amt", 0.0)):
				var who := ""
				if int(i) >= 0 and int(i) < s.seats.size():
					who = String((s.seats[int(i)] as Seat).unit_name)
				best = {"src": src, "amt": mx, "who": who}
	return best

## AFTER EVERY WON FIGHT: THE RECKONING — the raid ranked by damage (click a raider for
## their per-spell breakdown), your personal grade plaque, and the fight's BIGGEST HIT.
## Reuses MeterPanel/RecapPanel; CONTINUE runs `done` (→ loot drop → boon reforge → map).
func _show_fight_recap(done: Callable) -> void:
	if _ctrl == null or _ctrl.state == null:
		done.call()
		return
	_screen = "recap"
	_clear()
	var s: CombatState = _ctrl.state
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -320, -250, 320, 265)
	_ui.add_child(box)
	var hl := UiKit.title_in(box, "THE RECKONING", 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(box, String(s.encounter.name) + "  —  DOWN", 14, Palette.TEXT_DIM)
	var big := _biggest_hit(s)
	if not big.is_empty():
		UiKit.title_in(box, "★  BIGGEST HIT   %s  —  %d   (%s)" % [MeterPanel.pretty_src(big["src"]),
			int(big["amt"]), String(big["who"])], 16, Palette.GOLD_BRIGHT)
	if _ctrl.player() != null:
		box.add_child(RecapPanel.new(s, _ctrl.player(), _recap_stats))
	var cont := Button.new()
	cont.custom_minimum_size = Vector2(220, 48)
	cont.add_theme_font_size_override("font_size", 18)
	cont.text = "CONTINUE ▸"
	cont.pressed.connect(func(): done.call())
	box.add_child(cont)
	_report_button(box, func(): _show_fight_recap(done))
	# the raid RANKED by damage, top-right — click a raider for their per-spell breakdown
	var rmeter := MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg", true)
	UiKit.place(rmeter, 1, 0, 1, 0, -318, 118, -18, 600)
	_ui.add_child(rmeter)

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
	var banner := UiKit.title_in(box, "THE SEAL BREAKS" if won else "THE RAID FALLS", 52,
		Palette.WIN if won else Palette.LOSE)
	banner.add_theme_font_override("font", UiKit.title(900))
	var quips: Dictionary = {}
	if _ctrl.state != null and _ctrl.state.encounter != null:
		quips = RaidContent.QUIPS.get(String(_ctrl.state.encounter.id), {})
	if won:
		UiKit.title_in(box, String(quips.get("win", "Four seats, one kill. The Rift shudders.")), 16, Palette.TEXT)
	else:
		var cause := _ctrl.state.loss_cause if _ctrl.state != null else ""
		UiKit.title_in(box, "Wipe — %s. Re-form and pull again." % cause.replace("_", " "), 16, Palette.TEXT)
		if quips.has("lose"):
			UiKit.title_in(box, String(quips["lose"]), 13, Palette.TEXT_DIM)
	# V#8 (DESCENT-PLAN): the cross-run Prior bank is deleted — a wipe carries nothing
	# out, and the next descent opens fresh. Nothing follows you into a fresh run.
	# THE RECKONING — the fight's recap plaque (state survives into this screen)
	if _ctrl != null and _ctrl.state != null and _ctrl.player() != null:
		box.add_child(RecapPanel.new(_ctrl.state, _ctrl.player(), _recap_stats))
		# the meter's recap: the raid ranked, click a raider for their spells
		var rmeter := MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg", true)
		UiKit.place(rmeter, 1, 0, 1, 0, -318, 118, -18, 600)
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
	_report_button(box, func(): _show_end(won))

## STATS PAGE v2 — the "◆ FULL REPORT" affordance on every end screen, and the page it opens.
## `back` re-shows the screen it was pressed from. Guarded null-state (smoke-built end screens).
func _report_button(box: Node, back: Callable) -> void:
	if _ctrl == null or _ctrl.state == null:
		return
	var rep := Button.new()
	rep.custom_minimum_size = Vector2(220, 34)
	rep.add_theme_font_size_override("font_size", 14)
	rep.text = "◆ FULL REPORT"
	rep.pressed.connect(func(): _show_stats_page(back))
	box.add_child(rep)

func _show_stats_page(back: Callable) -> void:
	if _ctrl == null or _ctrl.state == null:
		back.call()
		return
	_screen = "report"
	_clear()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ui.add_child(scroll)
	var page := StatsPage.new(_ctrl, _recap_stats)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	var backb := Button.new()
	backb.custom_minimum_size = Vector2(150, 38)
	backb.add_theme_font_size_override("font_size", 15)
	backb.text = "‹ BACK"
	backb.pressed.connect(func(): back.call())
	UiKit.place(backb, 0, 0, 0, 0, 20, 16, 170, 54)
	_ui.add_child(backb)




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
