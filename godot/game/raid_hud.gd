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
		{"id": "fermata", "name": "FERMATA", "accent": Palette.VOID, "icon": "flurry",
			"desc": "HOLD to coil into shadow — release in the window to strike from the dark. The held note; Tempo's patient half."},
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
		"desc": "STACK seeds fast, then let the bed COOK from a trickle to a roar; BLOOM it for burst, and light Flourish across the raid with a full field."},
	{"id": "thornveil", "name": "THORNVEIL", "accent": Palette.THORN, "icon": "briarheart",
		"desc": "SNAP-STREAK wards: each Perfect Ward ramps the thorns that reflect damage back — heal by hurting the boss."},
]

## The blade seat is polymorphic too — Twinfang (rhythm) or Reckoner (the swing).
static var RECKONER_ASPECTS := [
	{"id": "colossus", "name": "THE COLOSSUS", "accent": Palette.RAGE, "icon": "rampage",
		"desc": "COMMIT the perfect swing — read the boss, land the True apex, bank Poise and STAGGER it. Punishing; precision is the whole game."},
	{"id": "berserker", "name": "THE BERSERKER", "accent": Palette.MOMENTUM, "icon": "avalanche",
		"desc": "Build MOMENTUM and hyperarmor THROUGH the hits — a Rage snowball that carries a sloppy rhythm. Forgiving; just keep swinging."},
]

## The caster seat's SECOND class — the Alchemist ("the Brew", ALCHEMIST-PLAN base).
## One aspect for now: the Brew IS the class (a second spec comes with the full build).
static var ALCHEMIST_ASPECTS := [
	{"id": "brew", "name": "THE BREW", "accent": Palette.REACT, "icon": "envenom",
		"desc": "Hold to charge the VIAL, release in the sweet band; feed two opposing poisons — Venom fades, Rot lingers — and RUPTURE the reaction at its ripe peak."},
	{"id": "cask", "name": "THE CASK", "accent": Palette.REACT, "icon": "envenom",
		"desc": "STACK 3–6 graded pours on a walking band — Venom = heat, Rot = time — a MISS dumps the batch; SEAL it, let it COOK, and TAP at the peak. (2nd spec · verb preview)"},
]

## The healer seat's THIRD class — the reworked direct-cast healer (codename "well",
## MENDER-PLAN). Two specs (dev-labels TARGET / SPEED) that grade the SAME book of casts.
static var WELL_ASPECTS := [
	{"id": "brim", "name": "TARGET · BRIM", "accent": Palette.GOLD_BRIGHT, "icon": "surge",
		"desc": "Grade the LANDING: pour each heal so the ally lands FULL with no spill — a PERFECT POUR GLINTS them (bonus damage). Read the party; size Flash vs Mend to the wound."},
	{"id": "draw", "name": "SPEED · DRAW", "accent": Palette.STEEL, "icon": "laststand",
		"desc": "Grade the RELEASE: let go at the last instant for a CLEAN draw that builds THE CURRENT (each stack casts faster); the dead-centre STILL POINT also GLINTS. Ride the streak; a slip or a dry Well breaks it."},
]

## The Aspect pair for a seat, honouring the seat's chosen CLASS.
func _aspects_for(seat_key: String) -> Array:
	if seat_key == "healer" and _healer_cls == "well":
		return WELL_ASPECTS
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return BLOOM_ASPECTS
	if seat_key == "blade" and _blade_cls == "reckoner":
		return RECKONER_ASPECTS
	if seat_key == "caster" and _caster_cls == "alchemist":
		return ALCHEMIST_ASPECTS
	return ASPECTS[seat_key]

## The Aspect pair for a lobby seat given an explicit class (online — the healer
## claimant may be a Mender or a Bloomweaver, independent of this client's _healer_cls).
func _lobby_aspects(seat_key: String, cls: String) -> Array:
	if seat_key == "healer" and cls == "well":
		return WELL_ASPECTS
	if seat_key == "healer" and cls == "bloomweaver":
		return BLOOM_ASPECTS
	if seat_key == "blade" and cls == "reckoner":
		return RECKONER_ASPECTS
	if seat_key == "caster" and cls == "alchemist":
		return ALCHEMIST_ASPECTS
	return ASPECTS[seat_key]

## The seat's display name, honouring the seat class.
func _seat_display_name(seat_key: String) -> String:
	if seat_key == "healer" and _healer_cls == "well":
		return "THE WELL-TENDER"
	if seat_key == "healer" and _healer_cls == "bloomweaver":
		return "THE BLOOMWEAVER"
	if seat_key == "blade" and _blade_cls == "reckoner":
		return "THE RECKONER"
	if seat_key == "caster" and _caster_cls == "alchemist":
		return "THE ALCHEMIST"
	return String(SEAT_NAMES.get(seat_key, "RAIDER"))

## The class currently filling a seat (the blade/caster/healer seats are polymorphic).
func _seat_cls_now() -> String:
	if _seat_key == "healer": return _healer_cls
	if _seat_key == "blade": return _blade_cls
	if _seat_key == "caster": return _caster_cls
	return String(SEAT_CLASS.get(_seat_key, "bulwark"))

## The spec's per-seat cfg for the human seat (carries its class so RaidNet builds the
## right kit + the lobby/sim/net all agree). Non-polymorphic seats keep their native class.
func _human_seat_cfg() -> Dictionary:
	_sync_healer_cls()
	_sync_blade_cls()
	_sync_caster_cls()
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
	elif _aspect == "tidecaller" or _aspect == "brinkwarden":
		_healer_cls = "mender"

## Keep _blade_cls consistent with the chosen aspect (the aspect uniquely identifies
## the blade class: Reckoner = colossus/berserker · Twinfang = tempo/fermata/venomancer).
func _sync_blade_cls() -> void:
	if _seat_key != "blade":
		return
	if _aspect == "colossus" or _aspect == "berserker":
		_blade_cls = "reckoner"
	elif _aspect == "tempo" or _aspect == "fermata" or _aspect == "venomancer":
		_blade_cls = "twinfang"

## Keep _caster_cls consistent with the chosen aspect (the aspect uniquely identifies
## the caster class: Alchemist = brew · Voidcaller = disruptor/silencer).
func _sync_caster_cls() -> void:
	if _seat_key != "caster":
		return
	if _aspect == "brew" or _aspect == "cask":
		_caster_cls = "alchemist"
	elif _aspect == "disruptor" or _aspect == "silencer":
		_caster_cls = "voidcaller"

## COMMANDER: make _party cover exactly the three seats the human doesn't occupy.
## Defaults = the verified comp RaidNet.make_spec would fill in anyway; prior picks
## survive a seat change between descents (only the vacated/claimed seats reset).
func _ensure_party() -> void:
	if _party.has(_seat_key):
		_party.erase(_seat_key)
	for key in RaidNet.SEAT_KEYS:
		if key == _seat_key or _party.has(key):
			continue
		var cls := String(SEAT_CLASS.get(key, "bulwark"))
		_party[key] = {"cls": cls, "aspect": RaidNet.default_aspect(key, cls)}

## COMMANDER: the full 4-seat spec cfg — your seat + the commanded AI raiders. With
## no party overrides this emits exactly the defaults make_spec fills in for missing
## keys, so the spec (and the fight) stays byte-identical to the pre-commander game.
func _party_seat_cfg() -> Dictionary:
	var cfg := _human_seat_cfg()
	_ensure_party()
	for key in _party:
		cfg[key] = {"aspect": String(_party[key]["aspect"]), "ai": true,
			"cls": String(_party[key]["cls"])}
	return cfg

## COMMANDER: per-seat boons for the spec (yours + the AI raiders'); RaidNet.build
## folds each into its seat's kit. Empty sets are omitted (spec unchanged = no drafts).
func _seat_boons_now() -> Dictionary:
	var out := {}
	if _run != null and not _run.boons.is_empty():
		out[_seat_key] = _run.boons
	for key in _ai_runs:
		var r: RunState = _ai_runs[key]
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
# start; _flags are cross-node ripple marks. All start inert (0/{}) — an event only
# touches them if it carries the matching fx, so a runless/dev path is unaffected.
var _entropy: int = 0
var _prior: int = 0
var _flags: Dictionary = {}
var _map_marks: Dictionary = {}    ## a pending fight-altering mark (KILL SWITCH cash-out / fight-curse)
var _map_charge: int = 0           ## ⏻ THE KILL SWITCH — a party-shared 0..100 meter, carries the descent
var _check_fails: int = 0          ## consecutive check fails → comeback pity (resets on any pass)

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

# COMMANDER (Bill, 2026-07-04): solo raid = you build the WHOLE party. The three AI
# raiders' class/aspect are picked on the pre-descent PARTY screen, and their boons
# are drafted BY YOU after every won fight — the AI only drives the rotation.
var _party: Dictionary = {}             ## AI seats only: seat_key -> {cls, aspect}
var _ai_runs: Dictionary = {}           ## AI seats only: seat_key -> RunState (their boon runs)

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
var _raid_col: VBoxContainer = null   # the movable raid-frame panel (drag its header)
var _raid_col_xl: bool = false        # which layout the panel was built with
var _raid_drag: bool = false
var _raid_drag_off := Vector2.ZERO
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
var _opening: OpeningBar           ## blade — THE OPENING (punish the boss's swing)
var _strike_idx: int = -1
var _vc_gauge: VoidcallerGauge     ## caster
var _pcast: PlayerCastBar          ## caster
var _spec_strip: SpecStrip         ## healer (Mender)
var _castbar: CastChannel          ## healer
var _mcfg: MenderConfig            ## healer (Mender)
var _bcfg: BloomweaverConfig       ## healer (Bloomweaver)
var _verd: VerdanceGauge           ## healer (Bloomweaver spec gauge)
var _wcfg: WellConfig              ## healer (the Well — reworked direct-cast)
var _well_gauge: WellGauge         ## the Well's charge vessel + Current + graded window
var _well_hold_key: int = -1       ## Well/DRAW: which heal key owns the live hold-release
var _well_hold_ms: int = 0         ## Well/DRAW: when the hold began (tap vs hold threshold)
var _well_mouse_ms: int = 0        ## Well/DRAW: when a mouse-started cast began (hold-release)
var _healer_cls: String = "mender" ## which class fills the healer seat: mender | bloomweaver | well
var _blade_cls: String = "twinfang" ## which class fills the blade seat: twinfang | reckoner
var _caster_cls: String = "voidcaller" ## which class fills the caster seat: voidcaller | alchemist
var _rcfg: ReckonerConfig             ## the Reckoner's config (set in _make_loadout when the blade is a Reckoner)
var _rk_gauge: ReckonerGauge          ## the Reckoner's WIND/APEX swing instrument
var _acfg: AlchemistConfig            ## the Alchemist's config (set in _make_loadout when the caster brews)
var _brew_gauge: BrewGauge            ## the Alchemist's ALEMBIC instrument (vial/reservoirs/chamber)
var _binds: Dictionary = {}        ## healer mouse chords
var _hover_seat: Seat = null
var _focus_seat: Seat = null
var _brew_hold_key: int = -1       ## Alchemist: which key (1/2) owns the live brew hold
var _coil_held: bool = false       ## FERMATA: the Strike coil is being held (key 1 or the slot-0 rune)

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
		elif a.begins_with("--autostart=world") or a.begins_with("--autostart=atlas"):
			# --autostart=world[:seat[:aspect]]  → THE WORLD preview, straight onto the Atlas
			var wspec := a.substr("--autostart=".length()).split(":")
			_seat_key = wspec[1] if wspec.size() > 1 and SEAT_IDX.has(wspec[1]) else "tank"
			_aspect = wspec[2] if wspec.size() > 2 else String((ASPECTS[_seat_key][0] as Dictionary)["id"])
			_sync_healer_cls()
			_sync_blade_cls()
			_sync_caster_cls()
			_show_atlas()
		elif a.begins_with("--autostart=zone"):
			# --autostart=zone[:seat[:aspect]]  → straight into ZONE 1 (the Gildfields)
			var zspec := a.substr("--autostart=".length()).split(":")
			_seat_key = zspec[1] if zspec.size() > 1 and SEAT_IDX.has(zspec[1]) else "tank"
			_aspect = zspec[2] if zspec.size() > 2 else String((ASPECTS[_seat_key][0] as Dictionary)["id"])
			_sync_healer_cls()
			_sync_blade_cls()
			_sync_caster_cls()
			_zone_id = WorldContent.ZONE1
			if _world == null:
				_world = WorldSave.load_save()
			_ensure_party()
			_show_zone()
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
	_armor_modal = null             # ditto — the modal lives under _ui
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
	_world_pending = false
	_zone_live = false
	_zone_id = ""
	_party_ctx = ""
	_gate_live = false
	_online_map = false
	_run = null                       # no descent = no boon run (fresh one per descent)
	_ai_runs = {}                     # COMMANDER: the AI raiders' boon runs die with it
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
	if WORLD_PREVIEW:   # W1: the world door (PLAY → ATLAS becomes the front door at W3)
		box.add_child(_menu_button("⟐    THE WORLD — preview", Palette.VERDANCE, _start_world_pick))
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
		["blade", "reckoner", "THE RECKONER", "rampage", Palette.RAGE, "MELEE · COMMIT — an auto-swing you shape with two timed taps (wind × strike): huge hits, hyperarmor, and STAGGER.  (Colossus / Berserker)"],
		["caster", "voidcaller", "THE VOIDCALLER", "overload", Palette.KICK, "CASTER · INTERRUPT — kick the boss's chants on the clean beat.  (Disruptor / Silencer)"],
		["caster", "alchemist", "THE ALCHEMIST", "envenom", Palette.REACT, "CASTER · BREW THE REACTION — charge the vial, feed two opposing poisons, RUPTURE the peak.  (The Brew · NEW)"],
		["healer", "mender", "THE MENDER", "surge", Palette.WIN, "HEALER · KEEP-ALIVE — react to the storm, click-cast big heals + shields.  (Tidecaller / Brinkwarden)"],
		["healer", "well", "THE WELL-TENDER", "laststand", Palette.GOLD_BRIGHT, "HEALER · POUR — discrete CHARGES, no mana; GRADE every heal (TARGET the landing / SPEED the release), and a perfect one GLINTS the ally you healed.  (Brim / Draw · NEW)"],
		["healer", "bloomweaver", "THE BLOOMWEAVER", "wildbloom", Palette.VERDANCE, "HEALER · ANTICIPATE — no mana; plant HoTs & wards AHEAD, bloom them on the spike.  (Wildgrove / Thornveil)"],
	]
	# AspectCard is a WIDE 680px card — STACK them vertically in a SCROLL box (8 cards over
	# the four seats now exceed one screen; the scroll keeps every class reachable).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, 0.5, 0.5, 0.5, 0.5, -360, -330, 360, 340)
	_ui.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)
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
	_seat_key = seat_id
	_aspect = aspect
	if _world_pending:              # THE WORLD (W1): the aspect ceremony opens the Atlas
		_world_pending = false
		_sync_healer_cls()
		_sync_blade_cls()
		_sync_caster_cls()
		_show_atlas()
		return
	_screen = "raidpick"
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
	card.chosen.connect(func(): _show_party_setup())   # COMMANDER: assemble the raid first
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

# ============================================================ PARTY SETUP (COMMANDER)
## You command the whole warband: each AI raider's class + aspect is YOUR call here,
## and their boons are yours to draft after every won fight — in combat the AI only
## drives the rotation. Defaults = the verified comp, so pressing straight through
## DESCEND is the same raid as before commander mode existed.
func _show_party_setup() -> void:
	_screen = "party"
	_clear()
	_ensure_party()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	_place(box, 0.5, 0.5, 0.5, 0.5, -360, -300, 360, 300)
	_ui.add_child(box)
	var hl := _title(box, "ASSEMBLE YOUR RAID", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(box, "their class, their aspect, their boons — your call. the AI only drives the rotation.",
		13, Palette.TEXT_DIM)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 8)
	box.add_child(gap0)
	for key in RaidNet.SEAT_KEYS:
		var mine: bool = key == _seat_key
		var cls: String = _seat_cls_now() if mine else String(_party[key]["cls"])
		var aspect: String = _aspect if mine else String(_party[key]["aspect"])
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var disp := String(SEAT_NAMES[key])
		if key == "healer" and cls == "bloomweaver":
			disp = "THE BLOOMWEAVER"
		elif key == "healer" and cls == "well":
			disp = "THE WELL-TENDER"
		elif key == "caster" and cls == "alchemist":
			disp = "THE ALCHEMIST"
		var lab := Label.new()
		lab.text = "%-15s %s  ·  %s" % [disp, ("YOU" if mine else "AI"), aspect.capitalize()]
		lab.custom_minimum_size = Vector2(420, 32)
		lab.add_theme_font_size_override("font_size", 16)
		lab.add_theme_color_override("font_color", Palette.GOLD_BRIGHT if mine else Palette.TEXT)
		row.add_child(lab)
		if not mine:
			if key == "healer":     # polymorphic CLASS toggle (Mender → Well → Bloomweaver)
				var clsb := Button.new()
				var cn: String = {"bloomweaver": "BLOOMWEAVER", "well": "WELL"}.get(cls, "MENDER")
				clsb.text = "◈ " + cn
				clsb.custom_minimum_size = Vector2(150, 32)
				clsb.pressed.connect(func():
					var nc: String = {"mender": "well", "well": "bloomweaver", "bloomweaver": "mender"}.get(cls, "well")
					_party[key] = {"cls": nc, "aspect": RaidNet.default_aspect(String(key), nc)}
					_show_party_setup())
				row.add_child(clsb)
			if key == "caster":     # polymorphic CLASS toggle (Voidcaller ⇄ Alchemist)
				var cclsb := Button.new()
				cclsb.text = "◈ " + ("ALCHEMIST" if cls == "alchemist" else "VOIDCALLER")
				cclsb.custom_minimum_size = Vector2(150, 32)
				cclsb.pressed.connect(func():
					var nc := "voidcaller" if cls == "alchemist" else "alchemist"
					_party[key] = {"cls": nc, "aspect": RaidNet.default_aspect(String(key), nc)}
					_show_party_setup())
				row.add_child(cclsb)
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 32)
			ab.pressed.connect(func():
				var pool: Array = _lobby_aspects(String(key), cls)
				var idx := 0
				for i in pool.size():
					if String(pool[i]["id"]) == aspect:
						idx = i
				_party[key]["aspect"] = String(pool[(idx + 1) % pool.size()]["id"])
				_show_party_setup())
			row.add_child(ab)
		# the chosen aspect's one-line identity, dim, under each row
		for a in _lobby_aspects(String(key), cls):
			if String(a["id"]) == aspect:
				var d := _title(box, String(a["desc"]), 12, Palette.TEXT_DIM)
				d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				d.custom_minimum_size = Vector2(600, 0)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	var go := Button.new()
	# THE BASTION's Warband Camp reuses this screen as a PLACE — muster returns to the
	# hearth instead of pulling a descent (the raid flow is untouched when _party_ctx == "").
	go.text = "⚑    MUSTER — the warband stands ready" if _party_ctx == "bastion" else "⚔    DESCEND"
	go.custom_minimum_size = Vector2(260, 52)
	go.add_theme_font_size_override("font_size", 19)
	go.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	go.pressed.connect(_show_bastion if _party_ctx == "bastion" else _start_map_run)
	var goc := CenterContainer.new()
	goc.add_child(go)
	box.add_child(goc)
	var back := Button.new()
	back.text = "◂ back"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	if _party_ctx == "bastion":
		back.pressed.connect(_show_bastion)
	else:
		back.pressed.connect(func(): _show_raid_select(_seat_key, _aspect))
	_place(back, 0.5, 1, 0.5, 1, -80, -58, 80, -24)
	_ui.add_child(back)

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
	elif seat_id == "blade":
		_blade_cls = cls
	elif seat_id == "caster":
		_caster_cls = cls
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

# ============================================================ THE WORLD (WORLD-PLAN W1)
## The persistent overworld preview: HOME → seat/aspect ceremony → THE ATLAS → zones
## (persistent conquest, bare-kit isolated fights) / THE BASTION (the meta as a place) /
## the raid door (the existing descent, untouched). The world is PERMANENCE; the runs
## behind doors keep the whole rolling economy — the Split, made playable.

## HOME's world door: pick who YOU are first (the warband follows), then the Atlas.
func _start_world_pick() -> void:
	_world_pending = true
	_show_class_select()

func _show_atlas() -> void:
	_screen = "atlas"
	_zone_live = false
	_party_ctx = ""
	if _world == null:
		_world = WorldSave.load_save()
	_ensure_party()
	_clear()
	var at := AtlasScreen.new()
	at.save = _world
	at.at_pin = _zone_id if _zone_id != "" else "bastion"
	at.pin_entered.connect(_enter_atlas_pin)
	at.back_requested.connect(_show_home)
	at.reset_requested.connect(_world_dev_reset)
	at.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(at)

## DEV (W1 preview): wipe the world — fresh fog, fresh conquest, on disk too.
func _world_dev_reset() -> void:
	_world = WorldSave.wipe()
	_zone_id = ""
	_show_atlas()

func _enter_atlas_pin(id: String) -> void:
	match id:
		"bastion":
			_zone_id = ""
			_show_bastion()
		"rift_scar":
			# the raid DOOR: the existing Realm-1 descent, verbatim (full run economy
			# lives behind doors — the Split). Campaign end routes home as it always has.
			_party_ctx = ""
			_start_map_run()
		_:
			if not WorldContent.zone(id).is_empty():
				_zone_id = id
				_show_zone()

## THE BASTION v1: the meta screens becoming a PLACE (WORLD-PLAN hometown). One hearth
## screen with stations; the Warband Camp is real (Commander party setup re-doored),
## the rest are foundations laid for W3.
func _show_bastion() -> void:
	_screen = "bastion"
	_party_ctx = "bastion"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -420, 110, 420, 210)
	_ui.add_child(head)
	var hl := _title(head, "THE BASTION", 40, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.title(900))
	_title(head, "hearth & muster — the warband's home. The stations are rising.", 14, Palette.TEXT_DIM)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	_place(col, 0.5, 0.5, 0.5, 0.5, -350, -220, 350, 260)
	_ui.add_child(col)
	var camp := AspectCard.new("THE WARBAND CAMP",
		"The Commander's tent: every AI raider's class and aspect is YOUR muster call. (The party you set here rides every fight — zone, dungeon, raid.)",
		Palette.GOLD_BRIGHT, "shockwave")
	camp.chosen.connect(func():
		_party_ctx = "bastion"
		_show_party_setup())
	col.add_child(camp)
	var ledger := AspectCard.new("THE LEDGER HALL",
		"Boss pages, oaths, standing — the save file made beautiful. The masons are still at work (arrives with W3's doors).",
		Palette.RELIC, "")
	ledger.chosen.connect(func(): _bastion_stop("THE LEDGER HALL",
		"Scaffolds and gold leaf. A hall for every boss's page, every oath sworn, every crest earned — raised when the doors open (W3)."))
	col.add_child(ledger)
	var yard := AspectCard.new("THE PRACTICE YARD",
		"Sparring against the casting pool, unlock-inert as the law demands. The dummies are being carved.",
		Palette.STEEL, "guard")
	yard.chosen.connect(func(): _bastion_stop("THE PRACTICE YARD",
		"A roped square, straw men, chalk lines. Practice earns NOTHING here but skill — exactly as the law demands. Open with W3."))
	col.add_child(yard)
	var out := AspectCard.new("SET OUT  —  THE ATLAS",
		"The world waits: the Gildfields' harvest died standing, and something under the Old Mill knows why.",
		Palette.VERDANCE, "growth")
	out.chosen.connect(_show_atlas)
	col.add_child(out)

## A one-line Bastion station stop (the tease panels while stations rise).
func _bastion_stop(title: String, body: String) -> void:
	_zone_stop(title, body, [{"label": "RETURN TO THE HEARTH", "fx": {"result": "The hearth holds."}}],
		Palette.GOLD, _show_bastion)

# ------------------------------------------------------------ zones

func _show_zone() -> void:
	_screen = "zone"
	_zone_live = false
	if _world == null:
		_world = WorldSave.load_save()
	_clear()
	var zs := ZoneScreen.new()
	zs.zone = WorldContent.zone(_zone_id)
	zs.save = _world
	zs.toast = _zone_toast
	_zone_toast = ""                  # one-shot — clears once shown
	zs.node_entered.connect(_enter_zone_node)
	zs.back_requested.connect(_show_atlas)
	zs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(zs)

func _enter_zone_node(id: int) -> void:
	var z := WorldContent.zone(_zone_id)
	_zone_node = id
	_world.set_at(_zone_id, id)
	# §MEWGENICS STEALS ① — escort transitions fire on ENTERING the node, cleared or not, so a
	# turn-in at a door you already marked (rushed there before picking up) still completes the
	# carry. For an uncleared escort node the message folds into its stop (camp/door) below.
	if ESCORT_PREVIEW:
		_escort_line = Escort.on_enter(_world, _zone_id, id)
	if _world.is_cleared(_zone_id, id):
		if _escort_line != "":        # a cleared node has no stop panel — surface it as a banner
			_zone_toast = _escort_line
			_escort_line = ""
		_world_autosave()             # free travel — the token moves, conquered ground never re-fights
		_show_zone()
		return
	var n := WorldContent.resolved_node(z, id, _world.flags(_zone_id))
	match String(n["kind"]):
		"fight", "elite", "boss":
			var body := WorldContent.BOSS_INTRO if String(n["kind"]) == "boss" else String(n["sub"])
			# §MEWGENICS STEALS ① — if the vial you're carrying will burden this fight, say so
			# BEFORE the pull: the player must connect the extra pressure to the escort.
			if ESCORT_PREVIEW and Escort.burden_for(_world, _zone_id, n) != "":
				body = "◈  The vial weeps — the harvest-rot rises to meet you here. This fight is worse for the carrying.\n\n" + body
			_zone_stop(String(n["name"]), body,
				[{"label": "MOVE IN", "fx": {"result": "The warband forms up."}}],
				ZoneScreen.KIND_COL[String(n["kind"])], _launch_zone_fight.bind(n))
		"gate":
			var ex: Dictionary = GateContent.exam(_seat_key, _seat_cls_now())
			_zone_stop(String(n["name"]), WorldContent.GATE_TEXT + "\n\n" + String(ex["body"]),
				[{"label": "STEP THROUGH ALONE", "fx": {"result": String(ex["challenge"])}}],
				Palette.GOLD_BRIGHT, _launch_zone_gate)
		"event":
			_zone_stop_event(n, WorldContent.event(String(n["event"])))
		"choice":
			_zone_stop_event(n, WorldContent.choice(String(n["choice"])))
		"camp", "cache", "waystation", "door":
			_zone_simple_stop(n)

## A zone node panel. Deliberately NOT _map_stop: zone fx never touch the run economy
## (no integrity/mana/charge/tokens exist out here — the overworld power rule). The only
## effect a zone choice can carry is a PERMANENT flag: THE ZONE REMEMBERS.
func _zone_stop(title: String, body: String, choices: Array, accent: Color, done: Callable) -> void:
	_screen = "zonestop"
	_clear()
	var p := MapEventPanel.new()
	p.title_text = title
	p.body_text = body
	p.choices = choices
	p.accent = accent
	p.finished.connect(func(fx: Dictionary):
		var wf: Array = fx.get("world_flag", [])
		if wf.size() == 2 and _world != null and _zone_id != "":
			_world.set_flag(_zone_id, String(wf[0]), String(wf[1]))
		done.call())
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(p)

func _zone_stop_event(n: Dictionary, ev: Dictionary) -> void:
	var accent: Color = ZoneScreen.KIND_COL[String(n["kind"])]
	_zone_stop(String(ev["title"]), String(ev["body"]), ev["choices"], accent,
		func(): _zone_clear_node(_zone_node))

## Camps, caches, the waystation, the instance door — one beat of fiction, then conquest.
func _zone_simple_stop(n: Dictionary) -> void:
	var nn := String(n["name"])   # (not `name` — shadows the Node property)
	# §MEWGENICS STEALS ① — an escort pickup/turn-in fired on this node: lead the fiction
	# with it (camp = the vial; door = sealing it away). One-shot, empty otherwise.
	var pre := ""
	if _escort_line != "":
		pre = "◈  " + _escort_line + "\n\n"
		_escort_line = ""
	match String(n["kind"]):
		"camp":
			_zone_stop(nn, pre + String(WorldContent.CAMP_TEXT.get(nn, "The warband rests.")),
				[{"label": "REST A WHILE", "fx": {"result": "The fields keep their quiet."}}],
				Palette.FLOW, func(): _zone_clear_node(_zone_node))
		"cache":
			_zone_stop(nn, pre + String(WorldContent.CACHE_TEXT.get(nn, "Spoils of the fields.")),
				[{"label": "TAKE STOCK", "fx": {"result": "Marked, counted, carried."}}],
				Palette.GOLD, func(): _zone_clear_node(_zone_node))
		"waystation":
			_zone_stop(nn, pre + WorldContent.WAYSTATION_TEXT,
				[{"label": "LIGHT THE BEACON", "fx": {"result": "The sky roads answer."}}],
				Palette.WIN, func(): _zone_clear_node(_zone_node))
		"door":
			_zone_stop(nn, pre + WorldContent.DOOR_TEXT,
				[{"label": "MARK THE ATLAS", "fx": {"result": "The route is yours. The door will know you."}}],
				Palette.RELIC, func(): _zone_clear_node(_zone_node))

## Conquest writeback — the ONLY thing a zone hands the permanence layer. Cleared is
## cleared forever; the waystation joins the flight web; the capstone crests the zone.
func _zone_clear_node(nid: int) -> void:
	var z := WorldContent.zone(_zone_id)
	var first := not _world.is_cleared(_zone_id, nid)
	_world.mark_cleared(_zone_id, nid)
	if first:
		var n := WorldContent.resolved_node(z, nid, _world.flags(_zone_id))
		_zone_toast = "⚑  %s — YOURS, forever" % String(n["name"])
		if String(n["kind"]) == "waystation":
			_world.unlock_waystation(_zone_id)
			_zone_toast = "^  FLIGHT PATH OPENED — Gildwatch joins the sky roads"
		if nid == int(z["capstone_id"]):
			_zone_toast = "★  THE OLD MILL FALLS — ZONE CLEARED. The Gildfields are yours."
	_world_autosave()
	_show_zone()

func _world_autosave() -> void:
	if _world != null:
		_world.save_to_disk()

# ------------------------------------------------------------ zone fights

## A ZONE fight (overworld power rule): bare kit + your commanded warband, NO boons /
## gear / wounds / carry — an isolated pull, full HP in, nothing out but conquest.
## Built by the SAME shared factory as every raid pull, with NO overrides — so a zone
## stand-in fight is byte-identical to its source encounter (the W1 acceptance bar).
## THE ONE EXCEPTION (§MEWGENICS STEALS ①): while escorting a payload, a fight/elite node
## rides a `carry.burden` — an enemy-side add — so the pull is *harder*, never buffed
## (bare-kit law intact; a no-burden pull is still byte-identical).
func _launch_zone_fight(n: Dictionary) -> void:
	_gate_live = false
	_screen = "combat"
	_clear()
	_ensure_party()
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var carry := {}
	if ESCORT_PREVIEW:
		var b := Escort.burden_for(_world, _zone_id, n)
		if b != "":
			carry = {"burden": b}
	# PACK: an authored member chain on the node = one battle, fought sequentially
	# (node["fight"] is always the chain's first id; [] = a classic single pull).
	var pk: Array = n.get("pack", [])
	var spec := RaidNet.make_spec(run_seed, _party_seat_cfg(), String(n["fight"]), carry, {}, pk)
	var s := RaidNet.build(spec, _seat_key)
	_apply_fightlen(s)
	_loadout = _make_loadout()
	_build_combat(s)
	_shake_amt = 0.0
	_online = false
	_zone_live = true
	_ctrl = _local_ctrl
	_ctrl.begin(s, SEAT_IDX[_seat_key])

## THE THRESHOLD: the zone's personal gate — your class exam, alone, bare kit.
## No wound stakes out here (zones carry nothing): lose and the stone simply waits.
func _launch_zone_gate() -> void:
	_screen = "combat"
	_clear()
	var seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var s := GateContent.make_state(seed, _seat_key, _aspect, _seat_cls_now())
	_apply_fightlen(s)
	_gate_live = true
	_zone_live = true
	_loadout = _make_loadout()
	_build_combat(s)

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
			cb.pressed.connect(func(): _net.send({"t": "claim", "seat": key, "prior": _my_prior()}))
			row.add_child(cb)
		elif claimant == me:
			if key == "healer":     # toggle the healer CLASS (Mender ⇄ Bloomweaver)
				var mycls := String(me.get("cls", "mender"))
				var clsb := Button.new()
				var mcn: String = {"bloomweaver": "BLOOMWEAVER", "well": "WELL"}.get(mycls, "MENDER")
				clsb.text = "◈ " + mcn
				clsb.custom_minimum_size = Vector2(150, 34)
				clsb.pressed.connect(func():
					var nc: String = {"mender": "well", "well": "bloomweaver", "bloomweaver": "mender"}.get(mycls, "well")
					_net.send({"t": "class", "cls": nc}))
				row.add_child(clsb)
			if key == "blade":      # toggle the blade CLASS (Twinfang ⇄ Reckoner)
				var bcls := String(me.get("cls", "twinfang"))
				if bcls == "":
					bcls = "twinfang"
				var bclsb := Button.new()
				bclsb.text = "◈ " + ("RECKONER" if bcls == "reckoner" else "TWINFANG")
				bclsb.custom_minimum_size = Vector2(150, 34)
				bclsb.pressed.connect(func():
					_net.send({"t": "class", "cls": "twinfang" if bcls == "reckoner" else "reckoner"}))
				row.add_child(bclsb)
			if key == "caster":     # toggle the caster CLASS (Voidcaller ⇄ Alchemist)
				var ccls := String(me.get("cls", "voidcaller"))
				if ccls == "":
					ccls = "voidcaller"
				var cclsb := Button.new()
				cclsb.text = "◈ " + ("ALCHEMIST" if ccls == "alchemist" else "VOIDCALLER")
				cclsb.custom_minimum_size = Vector2(150, 34)
				cclsb.pressed.connect(func():
					_net.send({"t": "class", "cls": "voidcaller" if ccls == "alchemist" else "alchemist"}))
				row.add_child(cclsb)
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 34)
			ab.pressed.connect(func():
				var pool: Array = _lobby_aspects(key, String(me.get("cls", "")))
				var cur := String(me.get("aspect", ""))
				var idx := 0
				for i in pool.size():
					if String(pool[i]["id"]) == cur:
						idx = i
				_net.send({"t": "aspect", "aspect": String(pool[(idx + 1) % pool.size()]["id"])}))
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
			elif you == "caster":
				_caster_cls = String(e.get("cls", "voidcaller"))
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
	ms.entropy = int(msg.get("entropy", 0))   # ⚡ the within-run luck pool (server-owned, v6)
	ms.charge = int(msg.get("charge", 0))     # ⏻ THE KILL SWITCH meter (server-owned)
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
	# CURIO Expansion Bus: +1 slot → a 1-of-4 draft (online).
	var picks := Draft.roll_offers(_run, 1 if _map_gear.has("expansion_bus") else 0)
	if picks.is_empty():
		_net.send_pick("")
		_show_online_wait("Reforge pool exhausted — waiting for the raid…")
		return
	_screen = "draft"
	_clear()
	var ds := DraftScreen.new(_run, picks, "REFORGE — the kill reshapes your kit",
		"Take one. Your raid is drafting too.", [], Palette.GOLD)
	ds.free_reroll = _map_gear.has("hot_reload")  # CURIO Hot Reload
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
	if seat_id == "reckoner":              # debug alias: the blade seat as a Reckoner
		seat_id = "blade"
		_blade_cls = "reckoner"
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
		elif aspect == "tidecaller" or aspect == "brinkwarden":
			_healer_cls = "mender"
	if _seat_key == "blade":
		if aspect == "colossus" or aspect == "berserker":
			_blade_cls = "reckoner"
		elif aspect == "tempo" or aspect == "venomancer":
			_blade_cls = "twinfang"
	if _seat_key == "caster":
		if aspect == "brew" or aspect == "cask":
			_caster_cls = "alchemist"
		elif aspect == "disruptor" or aspect == "silencer":
			_caster_cls = "voidcaller"
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
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
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
	_floor = 0
	# integrity / wounds / mana reset ONLY at the start of the whole descent —
	# they carry from ring to ring (a floor Seal down = elevation, not a reset).
	_map_fracs = [1.0, 1.0, 1.0, 1.0]
	_map_wounds = [0.0, 0.0, 0.0, 0.0]
	_map_mana = 1.0
	# The Inference Check meta resets for a fresh descent. ⚡ Entropy seeds from 📁 Prior
	# (the veteran's warm welcome); Prior itself loads once from the permanent file
	# (headless stays disk-inert — smokes/sims start from a clean file).
	_prior = _my_prior()
	_entropy = LuckProfile.starting_entropy(_prior)
	_flags = {}
	_map_marks = {}
	_map_charge = clampi(_prior / 25, 0, 4)   # a veteran's file pre-warms the switch a little
	_check_fails = 0
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
	# its picks ride into every pull.
	_run = _make_run()
	# COMMANDER: each AI raider gets its own boon run too — you draft on their behalf
	# after every won fight. Seeds decorrelated from yours (disjoint draft streams).
	_ensure_party()
	_ai_runs = {}
	for key in _party:
		_ai_runs[key] = _make_seat_run(String(_party[key]["cls"]),
			String(_party[key]["aspect"]),
			int((_run.run_seed ^ (0x515EED + int(SEAT_IDX[key]) * 0x9E3779)) & 0x7FFFFFFF))
	_show_creed_pick(_build_floor)   # TEMPO: swear a Creed at descent start (blade/Twinfang only)

## A minimal RunState for the human seat, just to carry boons + the draft economy
## (class/aspect/draft_rng/tokens/pity). Its encounter chain is ignored — the raid
## drives its own fights; we only borrow the boon pool + Draft 2.0 machinery.
func _make_run() -> RunState:
	_sync_healer_cls()
	_sync_blade_cls()
	_sync_caster_cls()
	return _make_seat_run(_seat_cls_now(), _aspect, -1)

## COMMANDER: a boon RunState for ANY seat (class starter by cls) — the commander
## drafts on behalf of the AI raiders, so they carry the same run machinery you do.
func _make_seat_run(cls: String, aspect: String, seed_v: int) -> RunState:
	match cls:
		"reckoner": return RunState.start_reckoner(aspect, seed_v)
		"twinfang": return RunState.start_twinfang(aspect, seed_v)
		"voidcaller": return RunState.start_voidcaller(aspect, seed_v)
		"alchemist": return RunState.start_alchemist(aspect, seed_v)
		"mender": return RunState.start_mender(aspect, seed_v)
		"bloomweaver": return RunState.start_bloomweaver(aspect, seed_v)
		"well": return RunState.start_well(aspect, seed_v)
		_: return RunState.start(aspect, seed_v)

## Fold the human's drafted boons into their seat's kit (kits read `boons` via _b()).
## (Map pulls also ride ALL seats' boons through the spec — see _seat_boons_now;
## this direct injection stays for the GATE path, which builds outside RaidNet.)
func _inject_boons(seat: Seat) -> void:
	if _run != null and seat != null and seat.kit != null:
		seat.kit.boons = _run.boons
		# CLASS FRAMEWORK (offline plumbing): fold the run's Creed + Modules + Rig into a
		# reworked kit. Both Twinfang and Alchemist carry the same three fields; every other
		# class carries none, so this is skipped there (byte-identical no-op).
		if seat.kit is TwinfangKit:
			var tk := seat.kit as TwinfangKit
			if _run.creed != "":
				tk.creed_id = _run.creed
			tk.modules = _run.modules.duplicate()
			tk.rig = _run.rig.duplicate()      # TEMPO §5: the wired Combo rig
		elif seat.kit is AlchemistKit:
			var ak := seat.kit as AlchemistKit
			if _run.creed != "":
				ak.creed_id = _run.creed
			ak.modules = _run.modules.duplicate()
			ak.rig = _run.rig.duplicate()      # ALCHEMIST-PLAN §3/rig: the wired Combo rig
		elif seat.kit is WellKit:
			var wk := seat.kit as WellKit
			if _run.creed != "":
				wk.creed_id = _run.creed
			wk.modules = _run.modules.duplicate()
			wk.rig = _run.rig.duplicate()      # MENDER-PLAN §4/rig: the wired Combo rig

## Generate the current ring's map (RaidContent.FLOORS[_floor]). The party's carried
## integrity/wounds/mana are UNTOUCHED here — only _start_map_run resets them.
func _build_floor() -> void:
	var fl: Dictionary = RaidContent.FLOORS[_floor]
	_map_fights = RaidContent.floor_fights(int(fl["ring"]))
	# every raid floor carries ONE personal GATE exam (Tier 1, §GAME SHAPE); the ROOT
	# floor also gates its Seal behind credential shards (MAP-3c); TICKETS are the quests (MAP-2).
	# THE DESCENT REFIT: floors run `rows` deep (8 = 20 nodes) — quest/story quotas stay
	# authored (4 events, tickets per FLOORS), the extra mid slots pad to COMBAT filler;
	# +1 cooling/+1 cache keep the breather + ⏻ economy proportional to the longer floor.
	_map = RunMap.generate(int(Time.get_ticks_usec()) & 0x7FFFFFFF,
		_map_fights.size(), MapContent.raid_event_ids(),
		{RunMap.KIND_GATE: 1, RunMap.KIND_COOLING: 1, RunMap.KIND_CACHE: 1},
		int(fl["shard_req"]), int(fl.get("tickets", 0)), int(fl.get("rows", 8)))
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
	elif _floor == 1:
		_show_module_pick(_build_floor)   # TEMPO: end of Floor 1 elevation → install a Module
	elif _floor == 2:
		_show_rig_wire(_build_floor)      # TEMPO §5: re-wire the Combo at end of Floor 2
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
	ms.entropy = _entropy
	ms.charge = _map_charge
	ms.prior = _prior
	ms.node_entered.connect(_enter_node)
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)
	# ARMORY: YOUR SET — the run's boons as armor pieces + curio trinkets, bottom-left
	# (below the lane band; the doll root ignores the mouse, only sockets hover)
	if _run != null:
		var doll := ArmorDoll.new()
		_place(doll, 0.0, 1.0, 0.0, 1.0, 14, -344, 14 + int(ArmorDoll.W), -12)
		_ui.add_child(doll)
		doll.set_build(_taken_boons, _map_gear, _map_gear_charges)
		doll.inspect_requested.connect(_open_armor_modal)
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
		if _map_gear.has("ticket_stub"):   # GEAR-1 (ARMORY strong): +10% integrity +1⏣
			_apply_map_fx({"heal": 0.10})
			_gain_tokens(1)
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
			var proceed := _offer_oath_then.bind(String(enc.id), _launch_map_fight.bind(fi))
			# THE KILL SWITCH: at a Seal, cash out the ⏻ meter (OVERCLOCK PRIME) before the pull
			if String(n["kind"]) == RunMap.KIND_SEAL and _map_charge > 0:
				_show_arming(String(enc.name), proceed)
			else:
				proceed.call()
		RunMap.KIND_GATE:
			# Tier-1 PERSONAL GATE (§GAME SHAPE): YOUR seat steps through alone
			var ex: Dictionary = GateContent.exam(_seat_key, _seat_cls_now())
			_map_stop(String(n["name"]), String(ex["body"]),
				[{"label": "STEP THROUGH ALONE", "fx": {"result": String(ex["challenge"])}}],
				Palette.GOLD_BRIGHT,
				_offer_oath_then.bind(String(GATE_ENC[_seat_key]), _launch_gate_fight))
		RunMap.KIND_EVENT:
			_event_stop(n)
		RunMap.KIND_COOLING:
			_map_stop(MapContent.COOLING_TITLE, MapContent.COOLING_BODY,
				[{"label": "THROTTLE  (+10 ⏻ toward the Kill Switch · ease the healer's reserves)",
					"fx": {"charge": 10, "mana": 0.75, "result": MapContent.COOLING_RESULT}}],
				Palette.FLOW, _show_map)
		RunMap.KIND_CACHE:
			_map_stop(MapContent.CACHE_TITLE, MapContent.CACHE_BODY,
				[{"label": "SALVAGE THE COMPONENT  (+25 ⏻)", "fx": {"charge": 25, "result": MapContent.CACHE_RESULT}}],
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
	var map_seed := _map.seed if _map != null else 0
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
		_entropy = maxi(0, _entropy - spend)
	if bool(p.committed_is_check):
		_check_fails = 0 if bool(p.committed_success) else _check_fails + 1

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
	var cat = Draft.catalog(_run) if _run != null else null
	var aspect := String(_run.aspect) if _run != null else ""
	var boons: Dictionary = _run.boons if _run != null else {}
	var boon_tags := MapCheck.tags_for_boons(cat, aspect, boons)
	var gear_tags: Array = []
	for gid in _map_gear:
		gear_tags.append(GearCatalog.item(String(gid)).get("tags", []))
	return MapCheck.build_ctx(boon_tags, gear_tags, aspect, _seat_key,
		_avg_frac(_map_fracs), _prior, _entropy, _check_fails, _map_inv, _flags, _tokens_now())

## Persist 📁 Prior at a DESCENT end (win or wipe): the run's earned prior (already in
## _prior from mercy/event grants) plus leftover ⚡ Entropy (÷2) plus a clear bonus, banked
## to the permanent file. "Better luck next time." Headless stays disk-inert. Returns the
## amount gained THIS descent (leftover-⚡ + clear bonus) for the end-screen line.
func _bank_prior(won: bool) -> int:
	var gained := int(_entropy / 2) + (4 if won else 0)
	_prior = clampi(_prior + gained, 0, LuckProfile.PRIOR_CAP)
	if DisplayServer.get_name() != "headless":
		LuckProfile.save_prior(_prior)
	return gained

## This client's 📁 Prior tier (headless/sims stay disk-inert). Sent to the server at
## seat-claim (v10) so co-op checks read the veteran's warm welcome — the server can't
## read a client's user:// file, so it trusts this.
func _my_prior() -> int:
	return LuckProfile.load_prior() if DisplayServer.get_name() != "headless" else 0

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

## One rolled walk-in: a light Forge body at the ring's tier, seed drawn from the
## node's own stream (variety across nodes, identical on replay).
func _pack_filler(rng: DetRng) -> String:
	var body := String(PACK_FILLER_BODIES[rng.next_u32() % PACK_FILLER_BODIES.size()])
	var tier := clampi(4 - int(RaidContent.FLOORS[_floor]["ring"]), 1, 3)   # ring 3→t1 · 2→t2 · 0→t3
	return "forge:takeover:%s:%d:%d" % [body, tier, 900 + int(rng.next_u32() % 64)]

func _roll_map_pack(fi: int, enc: EncounterRes) -> Array:
	if _map == null or _online:
		return []
	if fi <= 0 or fi >= _map_fights.size() - 1:
		return []                        # entry + Seal: authored, never rolled
	var rng := DetRng.new((_map.seed ^ (0x9A7B * (_map_node + 7))) & 0x7FFFFFFF)
	var r := rng.next_float()
	if r < 0.30:
		return []                        # a classic solo pull
	var pack: Array = [_pack_filler(rng)]
	if r >= 0.75:
		pack.append(_pack_filler(rng))
	pack.append(String(enc.id))          # smalls → captain (the node's own body)
	return pack

## A map fight: the node's encounter through the SAME shared factory as every raid
## pull, then each seat starts at its carried integrity.
func _launch_map_fight(fi: int) -> void:
	_gate_live = false
	_screen = "combat"
	_clear()
	var enc: EncounterRes = _map_fights[clampi(fi, 0, _map_fights.size() - 1)]
	var run_seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
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
		if i < _map_wounds.size():
			var u: Seat = s.seats[i]
			# INTEGRITY RETIRED: CORRUPTED SECTORS cut max HP (the sole HP stake), then boot
			# FULL of what's left — a carried HP fraction is meaningless (a healer tops it off).
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(_map_wounds[i]))))
			u.hp = u.hp_max
			if u.role == "healer":    # the fuel gauge: mana carries between nodes (it bites now)
				u.resource = roundf(u.resource_max * _map_mana)
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
	RaidMarks.apply(s, _map_marks)   # SHARED with RaidNet.build — one applier, never diverges
	_map_marks = {}

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
		_title(center, "⏻  the leader is arming the Kill Switch…", 18, Palette.CHARGE)

## THE KILL SWITCH cash-out (OVERCLOCK PRIME): a linear spend dial before a Seal. Committing
## a spend deducts ⏻ and folds the resolved mark into the pending fight-mark; banking skips it.
func _show_arming(boss_name: String, proceed: Callable) -> void:
	_screen = "arming"
	_clear()
	var ap := ArmingPanel.new()
	ap.charge = _map_charge
	ap.boss_name = boss_name
	ap.armed.connect(func(kind: String, spend: int):
		_map_charge = maxi(0, _map_charge - spend)
		(_map_marks as Dictionary).merge(RaidMarks.overclock(kind, spend), true)
		proceed.call())
	ap.banked.connect(func(): proceed.call())
	ap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ap)

## A Tier-1 PERSONAL GATE exam (§GAME SHAPE): YOUR seat's class exam, fought alone —
## the class's solo fight, recast to its Realm-1 identity. Carry-in applies only to
## YOUR raid slot (the healer's sandbox allies are phantoms — they carry nothing).
## Losing does NOT end the run: the checkpoint force-reboots you through, WOUNDED.
func _launch_gate_fight() -> void:
	_screen = "combat"
	_clear()
	var seed := int(Time.get_ticks_usec() & 0x7FFFFFFF)
	var s := GateContent.make_state(seed, _seat_key, _aspect, _seat_cls_now())
	_apply_fightlen(s)
	_arm_gear(s.seats[0])   # GEAR-1: the exam is fought with your curios on
	_inject_boons(s.seats[0])   # Draft 2.0: boons on for the exam too
	if _map != null:
		var ri: int = SEAT_IDX[_seat_key]
		var u: Seat = s.seats[0]
		u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(_map_wounds[ri]))))
		u.hp = u.hp_max                 # integrity retired: boot full of the wounded pool
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
## Routes through the shared MapFx applier (single source of truth for offline +
## online + the sim walker). Integrity/wounds mutate in place through the cp view;
## scalar currencies are copied back after.
func _apply_map_fx(fx: Dictionary) -> void:
	var cp := {
		"fracs": _map_fracs, "wounds": _map_wounds, "mana": _map_mana,
		"entropy": _entropy, "prior": _prior, "inv": _map_inv, "flags": _flags, "marks": _map_marks,
		"charge": _map_charge,
	}
	MapFx.apply(cp, fx)
	_map_mana = float(cp["mana"])
	_entropy = int(cp["entropy"])
	_prior = int(cp["prior"])
	_map_charge = int(cp["charge"])
	# tokens live on the run purse, not cp — grant directly (Phase 1 checks use this)
	if int(fx.get("tokens", 0)) != 0:
		_gain_tokens(int(fx["tokens"]))

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
	if n > 0 and _map_gear.has("hashgrinder"):   # CURIO Hashgrinder: all Token income doubled
		n *= 2
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

## ARMORY cadence: what a repeat skirmish kill pays instead of a drop roll, by ring.
const SALVAGE_TOKENS := {3: 1, 2: 2, 0: 3}

## Roll the kill's drop (map mode only), run the ceremony, then continue the run.
## Rolls draw from _drop_rng only — the combat stream never notices loot.
## ARMORY cadence: drops are EVENTS — `event` is true for Seal/gate kills; a plain
## skirmish only rolls while its SIGNATURE row is still locked (the first-kill
## shower). Repeat skirmish kills pay salvage Tokens so the ceremony stays scarce.
func _after_drop(boss_id: String, done: Callable, event: bool = true) -> void:
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
	if not event and not Gear.first_locked(boss_id, _seat_cls_now(), _gear_unlocks):
		# no ceremony for a farmed skirmish — pay parts + any oath verdict and move on
		# (a KEPT oath's purse Tokens/pity were already banked above; only the one-kill
		# roll bend evaporates, and no shipped skirmish carries an oath row today)
		if verdict != "":
			_toast_add(verdict)
		var pay := int(SALVAGE_TOKENS.get(int(RaidContent.FLOORS[_floor]["ring"]), 1))
		_gain_tokens(pay)
		_toast_add("⚙  SALVAGE — subagent parts stripped (+%d⏣)" % pay)
		done.call()
		return
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
	_title(box, "a TRINKET for your set — socket it, or scrap it for ⏣", 13, Palette.TEXT_DIM)
	if first:
		_title(box, "★  FIRST KILL — a new row is inked into the Ledger", 15, Palette.GOLD)
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
	_title(dcol, "· THE DROP ·", 12, Palette.GOLD_BRIGHT)
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
		if si < _map_gear.size():
			var oid := String(_map_gear[si])
			var oit := GearCatalog.item(oid)
			_title(ecol, "· EQUIPPED ·", 12, Palette.TEXT_DIM)
			var ocard := RelicCard.new(String(oit.get("name", oid)),
				String(oit.get("desc", "")), "curio",
				String(oit.get("rarity", "haiku")), false, "")
			ocard.ribbon_text = "◆ EQUIPPED · ×%d ◆" % int(_map_gear_charges[oid]) \
				if _map_gear_charges.has(oid) else "◆ EQUIPPED ◆"
			ocard.custom_minimum_size = Vector2(206, 280)
			ocard.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ocard.modulate = Color(1, 1, 1, 0.86)
			ecol.add_child(ocard)
		else:
			_title(ecol, "· FREE SOCKET ·", 12, Palette.TEXT_DIM)
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
	# FRAMEWORK: the FIRST draft is where you wire your Combo rig (any reworked class), then boons.
	if _fw() != "" and _run.rig.is_empty():
		_show_rig_wire(func(): _show_boon_draft(done))
		return
	if _ctrl != null and _ctrl.state != null:
		_gain_tokens(Draft.mint(_ctrl.state, _run.char_class))  # routes through Hashgrinder ×2
	# COMMANDER: after YOUR reforge, you draft each AI raider's boon too. Build the
	# callable chain back-to-front so it runs you → the AI seats in SEAT_KEYS order.
	var chain := done
	var order: Array = []
	for key in RaidNet.SEAT_KEYS:
		if _ai_runs.has(key):
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
	var run: RunState = _run if mine else (_ai_runs.get(key) as RunState)
	if run == null:
		done.call()
		return
	if not mine and _run != null:
		run.tokens = _run.tokens
	# CURIO Expansion Bus (your seat only): +1 slot → a 1-of-4 draft.
	var picks := Draft.roll_offers(run, 1 if (mine and _map_gear.has("expansion_bus")) else 0)
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
	ds.free_reroll = mine and _map_gear.has("hot_reload")  # CURIO Hot Reload (your seat only)
	ds.boon_taken.connect(func(boon: Dictionary):
		Draft.take(run, boon)
		if mine:
			_taken_boons.append(boon)      # for the build panel (title + rarity)
			# ARMORY: the pick visibly upgrades its armor slot (toast on the next map)
			var slot := ArmorSlots.slot_of(boon)
			var n := int((ArmorSlots.summarize(_taken_boons)[slot] as Dictionary)["count"])
			_toast_add("⚒  %s REFORGED — %s is piece %d" % [
				ArmorSlots.pretty(slot), String(boon.get("title", "?")), n])
		else:
			if _run != null:
				_run.tokens = run.tokens   # bank the remainder back to the shared pool
			_toast_add("⚒  %s takes %s" % [disp, String(boon.get("title", "?"))])
		done.call())
	_ui.add_child(ds)
	# ARMORY: the set-so-far stands beside YOUR forge (cards stay centered)
	if mine and (not _taken_boons.is_empty() or not _map_gear.is_empty()):
		var doll := ArmorDoll.new()
		_place(doll, 0.0, 0.5, 0.0, 0.5, 26, -int(ArmorDoll.H) / 2,
			26 + int(ArmorDoll.W), int(ArmorDoll.H) / 2)
		_ui.add_child(doll)
		doll.set_build(_taken_boons, _map_gear, _map_gear_charges)
		doll.inspect_requested.connect(_open_armor_modal)

## ARMORY-UI: the YOUR SET modal — opened by clicking any doll socket; Esc /
## click-outside / ✕ close it (raid_hud._input routes Esc while it lives).
func _open_armor_modal() -> void:
	if _armor_modal != null or _run == null:
		return
	var crest := "%s  ·  %s" % [String(_seat_key).to_upper(), String(_aspect).capitalize()]
	var m := ArmorModal.new(_taken_boons, _map_gear, _map_gear_charges, _tokens_now(), crest)
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
	return ""

## Creed data dispatch (both classes mirror the TwinfangCreeds static API).
func _fw_creed_ids(fw: String) -> Array:
	if fw == "alchemist":
		return AlchemistCreeds.v1_ids()
	if fw == "well":
		return WellCreeds.v1_ids(_aspect)      # per-spec pools (brim vs draw)
	return TwinfangCreeds.v1_ids()

func _fw_creed(fw: String, id: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistCreeds.get_creed(id)
	if fw == "well":
		return WellCreeds.get_creed(id)
	return TwinfangCreeds.get_creed(id)

## Module data dispatch. `_fw_module_offer_ids` applies creed-aware filtering (ALCHEMIST
## verdict 6): the Purist never draws a burst/detonation module (Fermentation, Vessel).
func _fw_module_offer_ids(fw: String, creed: String) -> Array:
	if fw == "well":
		return WellModules.built_ids()         # no Well creed hides a module in v1
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
	return TwinfangModules.get_module(id)

## Rig data dispatch (both classes mirror the TwinfangRig static API).
func _fw_rig_when_table(fw: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistRig.WHENS
	if fw == "well":
		return WellRig.WHENS
	return TwinfangRig.WHENS

func _fw_rig_then_table(fw: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistRig.THENS
	if fw == "well":
		return WellRig.THENS
	return TwinfangRig.THENS

func _fw_rig_describe(fw: String, w: String, t: String) -> String:
	if fw == "alchemist":
		return AlchemistRig.describe(w, t)
	if fw == "well":
		return WellRig.describe(w, t)
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
	if _run == null or fw == "" or _run.creed != "":
		done.call()
		return
	var ids: Array = _fw_creed_ids(fw).duplicate()         # the shipping pool (grows with unlocks)
	if ids.size() > 3 and _run.draft_rng != null:          # sample 3 deterministically when it's bigger
		for i in range(ids.size() - 1, 0, -1):
			var j := int(_run.draft_rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
		ids = ids.slice(0, 3)
	_screen = "creed"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -430, 120, 430, 235)
	_ui.add_child(head)
	var hl := _title(head, "SWEAR A CREED", 34, Palette.CRIMSON)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	var sub := "H O W   Y O U   P A Y   F O R   A   S L I P  —  one vow, the whole run"
	if fw == "alchemist":
		sub = "H O W   Y O U   B R E W  —  one posture, the whole run"
	elif fw == "well":
		sub = "H O W   Y O U   T E N D   T H E   W E L L  —  one temperament, the whole run"
	_title(head, sub, 15, Palette.TEXT_DIM)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	_place(box, 0.5, 0.5, 0.5, 0.5, -370, -150, 370, 175)
	_ui.add_child(box)
	for id in ids:
		var c: Dictionary = _fw_creed(fw, String(id))
		var card := AspectCard.new(String(c.get("name", id)) + "  ·  " + String(c.get("kicker", "")),
			String(c.get("blurb", "")), Palette.CRIMSON, "flurry")
		card.chosen.connect(_pick_creed.bind(String(id), done))
		box.add_child(card)

func _pick_creed(id: String, done: Callable) -> void:
	if _run != null:
		_run.creed = id
	_toast_add("⚔  Creed sworn — %s" % String(_fw_creed(_fw(), id).get("name", id)))
	done.call()

## End of Floor 1: INSTALL A MODULE — a new HUD gauge + way to play (§4). Forced pick.
func _show_module_pick(done: Callable) -> void:
	var fw := _fw()
	if _run == null or fw == "":
		done.call()
		return
	var avail: Array = []
	for id in _fw_module_offer_ids(fw, _run.creed):        # implemented + creed-allowed modules
		if not _run.modules.has(String(id)):
			avail.append(String(id))
	if avail.is_empty():
		done.call()
		return
	_screen = "module"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -430, 120, 430, 235)
	_ui.add_child(head)
	var hl := _title(head, "INSTALL A MODULE", 34, Palette.FLOW)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "A   N E W   G A U G E ,   A   N E W   W A Y   T O   P L A Y  —  pick one", 15, Palette.TEXT_DIM)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	_place(box, 0.5, 0.5, 0.5, 0.5, -370, -150, 370, 175)
	_ui.add_child(box)
	for id in avail:
		var m: Dictionary = _fw_module(fw, String(id))
		var card := AspectCard.new(String(m.get("name", id)) + "  ·  " + String(m.get("kicker", "")),
			String(m.get("blurb", "")), Palette.FLOW, "flurry")
		card.chosen.connect(_pick_module.bind(String(id), done))
		box.add_child(card)

func _pick_module(id: String, done: Callable) -> void:
	if _run != null:
		_run.modules[id] = true
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
	if _run == null or fw == "":
		done.call()
		return
	var offered := _fw_rig_offered(fw, _run.creed, _run.draft_rng)
	var whens: Array = offered["whens"]
	var thens: Array = offered["thens"]
	_rig_w = ""
	_rig_t = ""
	_screen = "rig"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(head, 0.5, 0, 0.5, 0, -450, 46, 450, 150)
	_ui.add_child(head)
	var hl := _title(head, "RE-WIRE YOUR COMBO" if not _run.rig.is_empty() else "WIRE YOUR COMBO", 32, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(head, "one MOMENT → one PAYOFF, all run  —  rare moments pay MORE, if you can land them", 14, Palette.TEXT_DIM)
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 54)
	_place(cols, 0.5, 0.5, 0.5, 0.5, -440, -180, 440, 150)
	_ui.add_child(cols)
	cols.add_child(_rig_col("WHEN — the moment", whens, _fw_rig_when_table(fw), true))
	cols.add_child(_rig_col("THEN — the payoff", thens, _fw_rig_then_table(fw), false))
	var foot := VBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 12)
	_place(foot, 0.5, 1, 0.5, 1, -320, -160, 320, -28)
	_ui.add_child(foot)
	_rig_readout = _title(foot, "pick a moment and a payoff", 18, Palette.TEXT_DIM)
	_rig_confirm = Button.new()
	_rig_confirm.text = "WIRE IT ▸"
	_rig_confirm.custom_minimum_size = Vector2(200, 44)
	_rig_confirm.disabled = true
	_rig_confirm.pressed.connect(func():
		_run.rig = {"when": _rig_w, "then": _rig_t}
		_toast_add("⚡  Combo wired — " + _fw_rig_describe(fw, _rig_w, _rig_t))
		done.call())
	foot.add_child(_rig_confirm)

func _rig_col(label: String, ids: Array, table: Dictionary, is_when: bool) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_title(col, label, 13, Palette.CRIMSON if is_when else Palette.FLOW)
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
	var prior_gain := _bank_prior(true)   # bank BEFORE clearing the run
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
	_title(box, "📁 TRAINING SIGNAL RECORDED — your prior is now %d (+%d). Welcome back, valued user." % [_prior, prior_gain],
		13, Palette.VOID)
	var again := Button.new()
	again.text = "BACK TO THE RIFT"
	again.custom_minimum_size = Vector2(260, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(func(): _show_select(_seat_key))
	box.add_child(again)

func _make_loadout() -> Array:
	_sync_healer_cls()
	_sync_blade_cls()
	_sync_caster_cls()
	match _seat_key:
		"blade":
			if _blade_cls == "reckoner":
				_rcfg = ReckonerConfig.new()
				return _rcfg.loadout(_aspect)
			return TwinfangConfig.new().loadout(_aspect)
		"caster":
			if _caster_cls == "alchemist":
				_acfg = AlchemistConfig.new()
				return _acfg.loadout(_aspect)
			return VoidcallerConfig.new().loadout(_aspect)
		"healer":
			if _healer_cls == "well":
				_wcfg = WellConfig.new()
				return _wcfg.loadout(_aspect)
			if _healer_cls == "bloomweaver":
				_bcfg = BloomweaverConfig.new()
				return _bcfg.order(_aspect)
			_mcfg = MenderConfig.new()
			return _mcfg.order(_aspect) + ["revive"]   # RAID adds the battle-rez rune (R)
		_:
			return ["cleave", "rampage", "fortify", ("vindicate" if _aspect == "warden" else "avalanche")]

## The seat's defensive-verb label (the tank's depends on its Aspect; the caster's
## on its class — the Alchemist has no kick, it dodges like everyone else).
func _verb() -> String:
	match _seat_key:
		"tank":
			return "PARRY" if _aspect == "warden" else "DODGE"
		"caster":
			return "DODGE" if _caster_cls == "alchemist" else "KICK"
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
		var ex: Dictionary = GateContent.exam(_seat_key, _seat_cls_now())
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

	# THE RAID — reliquary TRIAGE CARDS down the left (XL for the healer seat: the
	# frames ARE its combat surface — shield crest, HoT countdown chips, debuff
	# timers). Gold-lit = the boss's victim; for the Mender seat the frames are also
	# your click-cast targets. Drag the ≡ header to move the panel (persists);
	# double-click the header to snap it back.
	# XL cards for the healer's 4-seat raid; the 5-frame gate SANDBOX party falls
	# back to the compact cards so the column clears the mana orb.
	var xl_frames := _seat_key == "healer" and s.seats.size() <= 4
	_raid_col_xl = xl_frames
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12 if xl_frames else 10)
	if xl_frames:
		_place(col, 0, 0.5, 0, 0.5, 22, -276, 334, 276)
	else:
		_place(col, 0, 0.5, 0, 0.5, 26, -238, 266, 238)
	_ui.add_child(col)              # NOT under shake — the healer aims clicks at these
	_raid_col = col
	var head := Label.new()
	head.text = "≡  THE RAID   ·   ◆ = its gaze" if _seat_key != "healer" else "≡  THE RAID   ·   hover + click-cast"
	if _gate_live:
		head.text = "≡  THE EXAM   ·   the raid watches" if _seat_key != "healer" \
			else "≡  THE SANDBOX   ·   hover + click-cast"
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
		# FERMATA: the slot-0 Strike rune is a HOLD (press = coil, release = strike). Every other
		# rune, and every other seat, stays a tap. Mirrors the keyboard hold in _fermata_key/_input.
		if i == 0 and _seat_key == "blade" and _aspect == "fermata" and id == "strike":
			rune.held.connect(func():
				if _screen == "combat" and not _coil_held:
					_coil_held = true
					_ctrl.human({"type": "ability", "id": "coil"}))
			rune.released.connect(func():
				if _screen == "combat" and _coil_held:
					_coil_held = false
					_ctrl.human({"type": "ability", "id": "release"}))
		else:
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
	if _blade_cls == "reckoner":
		_build_band_reckoner()
		return
	_rhythm = RhythmBar.new()
	# YOUR metronome sits in your own column — the boss's Judgment Channel owns
	# the line under the reticle on the right
	_place(_rhythm, 0.35, 0, 0.35, 0, -360, 646, 360, 746)
	_shake_root.add_child(_rhythm)
	# THE OPENING — the offense-side vulnerability gauge, stacked above your metronome:
	# read the boss's swing and slam your dumps into the molten sweet spot.
	_opening = OpeningBar.new()
	_opening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_opening, 0.35, 0, 0.35, 0, -360, 548, 360, 636)
	_shake_root.add_child(_opening)
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

## The Reckoner's band: HP + RAGE orbs, the WIND/APEX swing instrument, and the
## Overswing/Ultraswing/Onslaught/Signature rune rail. The SWING itself is SPACE
## (tap to wind, tap again for the apex) — not a rune.
func _build_band_reckoner() -> void:
	_hp_orb = _orb(Palette.BLOOD, "HEALTH", false)
	_res_orb = _orb(Palette.RAGE, "RAGE", true)
	_rk_gauge = ReckonerGauge.new()
	_rk_gauge.aspect = _aspect
	_place(_rk_gauge, 0.5, 1, 0.5, 1, -540, -470, 180, -170)   # THE FORGE: 720×300, in the player's column, clear of the boss cast bar
	_shake_root.add_child(_rk_gauge)
	var row := _rune_row(-360.0, 360.0)
	_guard = AbilityRune.new()
	_guard.label = "DODGE"
	_guard.key_label = "F"
	_guard.icon_id = "dodge"
	_guard.accent = Palette.STEEL
	_guard.tooltip_text = "Dodge the boss's swing (F). The Colossus would rather hyperarmor through — but the dodge is there when you need it."
	_guard.pressed.connect(func(): _ctrl.human({"type": "dodge"}))
	row.add_child(_guard)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	_add_runes(row, _loadout, Palette.RAGE)
	_strike_idx = -1
	_hint_line("SPACE — the SWING: tap to WIND (weight), tap again for the STRIKE apex (power)    ·    1/2/3/4 — Overswing · Ultraswing · Onslaught · Signature    ·    F — DODGE")

func _build_band_caster() -> void:
	if _caster_cls == "alchemist":
		_build_band_alchemist()
		return
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

## The Alchemist's band: HP + POTENCY orbs and THE ALEMBIC — the brew instrument
## (hold-zones + vial + reaction chamber + potency strip). The brew itself is the
## whole bar: HOLD 1/2 (or the reservoirs) to charge, release to pour, 3 (or tap
## the chamber) to Rupture. No rune rail — the instrument IS the kit.
func _build_band_alchemist() -> void:
	_hp_orb = _orb(Palette.BLOOD, "HEALTH", false)
	_res_orb = _orb(Palette.REACT, "POTENCY", true)
	_brew_gauge = BrewGauge.new()
	# THE ALEMBIC: 780×316, shifted into the player's column (the Forge idiom) so the
	# boss's Judgment Channel + telegraph rail under the reticle stay clear of it.
	_place(_brew_gauge, 0.5, 1, 0.5, 1, -550, -486, 230, -170)
	_shake_root.add_child(_brew_gauge)
	_brew_gauge.brew_pressed.connect(func(side: String):
		_ctrl.human({"type": "ability", "id": "brew_" + side}))
	_brew_gauge.brew_released.connect(func():
		_ctrl.human({"type": "ability", "id": "pour"}))
	_brew_gauge.rupture_tapped.connect(func():
		_ctrl.human({"type": "ability", "id": "rupture"}))
	var row := _rune_row(-360.0, 360.0)
	_guard = AbilityRune.new()
	_guard.label = "DODGE"
	_guard.key_label = "SPC"
	_guard.icon_id = "dodge"
	_guard.accent = Palette.REACT
	_guard.tooltip_text = "Dodge the swing aimed at YOU — the brew keeps cooking through your footwork."
	_guard.pressed.connect(func(): _ctrl.human({"type": "defense"}))
	row.add_child(_guard)
	_runes = []
	_rune_ids = []
	# The module's active button + any drafted spells get their own runes (only when owned —
	# read from the campaign run, which _inject_boons folds into this fight's kit).
	var extras := "3 — RUPTURE"
	if _run != null and _run.modules.has("third_reagent"):
		row.add_child(_alch_rune("catalyst", "CATALYST", "4", "flash", Palette.GOLD_BRIGHT,
			"Drop the Third Reagent — amplify the reaction for a few seconds. Best while potency is high."))
		extras += " · 4 — CATALYST"
	var spell_runes := [
		["spitfire", "SPITFIRE", "5", "bolt", "An instant off-brew acid dart — free filler between pours."],
		["decant", "DECANT", "6", "cascade", "Pour the fuller poison into the emptier — a cd-gated snap toward balance."],
		["reduction", "REDUCTION", "7", "surge", "Boil VOLUME into POWER — trade brew for a slug of Potency before a Rupture."],
	]
	for sp in spell_runes:
		if _run != null and (String(sp[0]) in _run.loadout or _run.boons.has(String(sp[0]))):
			row.add_child(_alch_rune(String(sp[0]), String(sp[1]), String(sp[2]), String(sp[3]),
				Palette.REACT, String(sp[4])))
			extras += " · %s — %s" % [String(sp[2]), String(sp[1])]
	_hint_line("HOLD 1 — VENOM · HOLD 2 — ROT (release = POUR) · %s · SPACE — DODGE · F — DODGE beats" % extras)

## One Alchemist ability rune (catalyst / a drafted spell) wired to send its action.
func _alch_rune(id: String, label: String, key: String, icon: String, accent: Color, tip: String) -> AbilityRune:
	var r := AbilityRune.new()
	r.label = label
	r.key_label = key
	r.icon_id = icon
	r.accent = accent
	r.tooltip_text = tip
	r.pressed.connect(func(): _ctrl.human({"type": "ability", "id": id}))
	return r

func _build_band_healer() -> void:
	if _healer_cls == "well":
		_build_band_well()
		return
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

## The Well's band — built on the SHARED healer surfaces: click-cast chords (WellBinds),
## the healer CastChannel (extended with DRAW's release window, always-visible track,
## tap-to-release), and the WellGauge (charges + Current + the big TARGET bar Brim aims
## on). No mana orb — the Well IS the resource, in the gauge.
func _build_band_well() -> void:
	_binds = WellBinds.load_binds()
	# the shared healer cast bar; DRAW marks the release window on it (and wears the
	# Well's water blue — spec color identity), clicking the channel is a release press.
	# The idle track keeps the window readable between casts. Added BEFORE the gauge:
	# the gauge's verdict banner rises over the channel, so it must draw on top.
	_castbar = CastChannel.new()
	if _aspect == "draw":
		_castbar.accent = Palette.WATER
		_castbar.zone_lo = 1.0 - _wcfg.draw_band
		var sp_c := 1.0 - _wcfg.draw_band * 0.5
		_castbar.mark_lo = sp_c - _wcfg.still_point * 0.5
		_castbar.mark_hi = sp_c + _wcfg.still_point * 0.5
		_castbar.show_idle_track = true
		_castbar.tapped.connect(func(): _ctrl.human({"type": "ability", "id": "release"}))
	# the Well's channel is placed TALL — the shared CastChannel scales its whole
	# instrument with height, so this one bar is the big AAA read (classic healers
	# keep their 60-tall placement).
	_place(_castbar, 0.5, 1, 0.5, 1, -330, -420, 330, -304)
	_shake_root.add_child(_castbar)
	_well_gauge = WellGauge.new()
	_well_gauge.aspect = _aspect
	_place(_well_gauge, 0.5, 1, 0.5, 1, -330, -300, 330, -166)
	_shake_root.add_child(_well_gauge)
	var row := _rune_row(-380.0, 380.0)
	_runes = []
	_rune_ids = []
	for id in _loadout:
		var sp: Dictionary = _wcfg.book.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		rune.custom_minimum_size = Vector2(62, 62)
		rune.pressed.connect(_cast.bind(String(id)))
		row.add_child(rune)
		_runes.append(rune)
		_rune_ids.append(id)
	_hint_line(_well_hint())

func _well_hint() -> String:
	var verb := "click/tap to heal — LAND it in the gold band (no spill) = POUR" if _aspect == "brim" \
		else "click/tap starts the cast — click/tap AGAIN (or hold & release) in the window = CLEAN"
	return "Hover an ally · L flash · R mend · Mid cascade · Sh+L spring · Sh+R dispel · 1-4 keys · %s · SPACE/F dodge" % verb

func _render_band_well(s: CombatState, p: Seat, obs: Dictionary) -> void:
	var g := _well_gauge
	if g == null:
		return
	g.seat_ref = p
	g.aspect = _aspect
	g.charges = int(obs.get("charges", 0))
	g.charges_max = int(obs.get("charges_max", 12))
	g.current = int(obs.get("current", 0))
	g.current_max = int(obs.get("current_max", 5))
	# the SHARED cast channel (with DRAW's release window baked in at build)
	var casting: Dictionary = obs.get("casting", {})
	if _castbar != null:
		if casting.is_empty():
			_castbar.active = false
		else:
			_castbar.active = true
			_castbar.frac = clampf(float(s.tick - int(casting.get("start_tick", 0)))
				/ maxf(float(casting.get("dur_ticks", 1)), 1.0), 0.0, 1.0)
			var ct: Seat = casting.get("target")
			_castbar.target = ct.unit_name if ct != null else ""
			_castbar.spell_id = String(casting.get("id", ""))
			_castbar.label = String(_wcfg.book.get(_castbar.spell_id, {}).get("name", _castbar.spell_id))
	# THE TARGET BAR: the cast's target while casting, else the hovered/focused ally.
	# Brim aims the pour here (band + the in-flight heal's ghost landing).
	var tgt: Seat = casting.get("target") if not casting.is_empty() else null
	if tgt == null:
		tgt = _hover_seat if _hover_seat != null else _focus_seat
	if tgt != null and tgt.alive():
		g.t_show = true
		g.t_name = tgt.unit_name
		g.t_frac = tgt.hp_frac()
		g.t_hp = int(round(tgt.hp))
		g.t_hpmax = int(round(tgt.hp_max))
		g.t_band = _wcfg.brim_band if _aspect == "brim" else -1.0
		g.t_glint = s.tick < int(tgt.vars.get("glint_until", -1))
		g.t_ghost = -1.0
		if not casting.is_empty() and casting.get("target") == tgt:
			var wsp: Dictionary = _wcfg.book.get(String(casting.get("id", "")), {})
			if wsp.has("heal"):
				g.t_ghost = clampf(tgt.hp_frac() + float(wsp.get("heal", 0.0)) / maxf(tgt.hp_max, 1.0), 0.0, 1.0)
	else:
		g.t_show = false

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
	if _run == null:
		return []
	match _seat_key:
		"blade":
			# TEMPO §5: show the wired Combo rig in the build panel (Twinfang only).
			if _blade_cls == "twinfang" and not _run.rig.is_empty():
				return ["⚡ Combo — " + TwinfangRig.describe(
					String(_run.rig.get("when", "")), String(_run.rig.get("then", "")))]
			return TwinfangBoons.verb_summary(_run.boons, _aspect)
		"caster":
			if _caster_cls == "alchemist":
				# show the wired Combo rig in the build panel (the Brew's rig)
				if not _run.rig.is_empty():
					return ["⚡ Combo — " + AlchemistRig.describe(
						String(_run.rig.get("when", "")), String(_run.rig.get("then", "")))]
				return []
			return VoidcallerBoons.verb_summary(_run.boons, _aspect)
		"healer":
			if _healer_cls == "well":
				# MENDER-PLAN §4: show the wired Combo rig in the build panel (the Well's rig)
				if not _run.rig.is_empty():
					return ["⚡ Combo — " + WellRig.describe(
						String(_run.rig.get("when", "")), String(_run.rig.get("then", "")))]
				return WellBoons.verb_summary(_run.boons, _aspect)
			return (BloomweaverBoons.verb_summary(_run.boons, _aspect) if _healer_cls == "bloomweaver" else MenderBoons.verb_summary(_run.boons, _aspect))
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
		# ARMORY: the build reads as a SET — pieces grouped under their armor slots
		var cap := Label.new()
		cap.text = "THE SET  ·  %d PIECES" % _taken_boons.size()
		cap.add_theme_font_size_override("font_size", 10)
		cap.add_theme_color_override("font_color", Palette.GOLD_DIM)
		col.add_child(cap)
		var summed := ArmorSlots.summarize(_taken_boons)
		for slot in ArmorSlots.ORDER:
			var e: Dictionary = summed[slot]
			if int(e["count"]) == 0:
				continue
			var sl := Label.new()
			sl.text = "%s  +%d" % [ArmorSlots.pretty(slot), int(e["count"])]
			sl.add_theme_font_size_override("font_size", 11)
			sl.add_theme_color_override("font_color", Palette.rarity_color(String(e["best"])))
			col.add_child(sl)
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
## header. Only the map/campaign run carries a boon pool (`_run`); a bare Seal pull has
## none → []. Scans the current class's boon pools by id.
func _owned_boon_labels() -> Array:
	if _run == null or _run.boons.is_empty():
		return []
	var pools: Array = []
	match _seat_key:
		"blade": pools = [TwinfangBoons.SHARED, TwinfangBoons.TEMPO, TwinfangBoons.VENOM]
		"caster": pools = ([AlchemistBoons.SHARED, AlchemistBoons.BREW] if _caster_cls == "alchemist" \
			else [VoidcallerBoons.SHARED, VoidcallerBoons.DISRUPTOR, VoidcallerBoons.SILENCER])
		"healer":
			if _healer_cls == "well":
				pools = [WellBoons.SHARED, WellBoons.BRIM, WellBoons.DRAW]
			elif _healer_cls == "bloomweaver":
				pools = [BloomweaverBoons.SHARED, BloomweaverBoons.GROVE, BloomweaverBoons.THORN]
			else:
				pools = [MenderBoons.SHARED, MenderBoons.TIDE, MenderBoons.BRINK]
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
		_place(_raid_col, 0, 0.5, 0, 0.5, 22, -276, 334, 276)
	else:
		_place(_raid_col, 0, 0.5, 0, 0.5, 26, -238, 266, 238)
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
		match _seat_key:
			"healer":
				_healer_key(event.keycode)
			"blade":
				if _blade_cls == "reckoner":
					_reckoner_key(event.keycode)
				elif _aspect == "fermata":
					_fermata_key(event.keycode)          # the hold-release blade
				else:
					_martial_key(event.keycode)
			"caster":
				if _caster_cls == "alchemist":
					_alchemist_key(event.keycode)
				else:
					_martial_key(event.keycode)
			_:
				_martial_key(event.keycode)
		return
	# the Alchemist's hold-release verb: releasing the held brew key POURS the vial.
	# (Key releases are otherwise unused — every other kit is tap-driven.)
	if event is InputEventKey and not event.pressed and _pause == null \
			and _screen == "combat" and _seat_key == "caster" and _caster_cls == "alchemist":
		if event.keycode == _brew_hold_key:
			_brew_hold_key = -1
			_ctrl.human({"type": "ability", "id": "pour"})
		return
	# FERMATA's hold-release Strike: releasing key 1 RELEASES the coil (resolves the strike).
	if event is InputEventKey and not event.pressed and _pause == null \
			and _screen == "combat" and _seat_key == "blade" and _aspect == "fermata":
		if event.keycode == KEY_1 and _coil_held:
			_coil_held = false
			_ctrl.human({"type": "ability", "id": "release"})
		return
	# the Well/DRAW hold-release: a heal key HELD past the tap threshold pours on key-up.
	# A quick TAP leaves the cast running — tap/click again to pour (the two-click style).
	if event is InputEventKey and not event.pressed and _pause == null and _screen == "combat" \
			and _seat_key == "healer" and _healer_cls == "well" and _aspect == "draw":
		if event.keycode == _well_hold_key:
			var held := Time.get_ticks_msec() - _well_hold_ms
			_well_hold_key = -1
			if held >= 250 and not _ctrl.player().casting.is_empty():
				_ctrl.human({"type": "ability", "id": "release"})
		return
	# the Well/DRAW mouse release: a bound chord pressed WHILE CASTING = the release
	# (click-click), and a mouse button held past the threshold releases on button-up.
	if _pause == null and _screen == "combat" and _seat_key == "healer" \
			and _healer_cls == "well" and _aspect == "draw" and event is InputEventMouseButton:
		if event.pressed and not _ctrl.player().casting.is_empty() \
				and String(_binds.get(_mouse_chord(event), "none")) != "none":
			_well_mouse_ms = 0
			_ctrl.human({"type": "ability", "id": "release"})
			return
		if not event.pressed and _well_mouse_ms > 0:
			var mheld := Time.get_ticks_msec() - _well_mouse_ms
			_well_mouse_ms = 0
			if mheld >= 300 and not _ctrl.player().casting.is_empty():
				_ctrl.human({"type": "ability", "id": "release"})
				return
	# healer click-cast (all healer classes): hover a frame, click a chord
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

## FERMATA: the Strike is a HOLD — key 1 DOWN coils into shadow, key 1 UP (in _input) releases.
## The dumps (Eviscerate/Kick/Coup, keys 2-4) stay instant taps at base — same as Tempo.
func _fermata_key(code: int) -> void:
	match code:
		KEY_SPACE:
			_ctrl.human({"type": "defense"})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1:
			if not _coil_held:
				_coil_held = true
				_ctrl.human({"type": "ability", "id": "coil"})
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_5: _use_ability(4)

## The healer's spellbook for the current class (Mender mana spells / Bloomweaver Sap).
func _hspells() -> Dictionary:
	if _healer_cls == "well":
		return _wcfg.book if _wcfg != null else {}
	if _healer_cls == "bloomweaver":
		return _bcfg.spells if _bcfg != null else {}
	return _mcfg.spells if _mcfg != null else {}

## The Well's keys. BRIM taps 1-4 (grades on landing). DRAW holds 1-4 to cast and
## RELEASES the key to pour (the release branch in _input sends the "release" action).
## Q dispel · R rekindle (hover a fallen ally) · SPACE/F dodge (cancels a cast).
func _well_key(code: int) -> void:
	match code:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1, KEY_2, KEY_3, KEY_4:
			# DRAW does BOTH release styles: a press while casting = the release (tap-tap),
			# and a key HELD past the tap threshold releases on key-up (hold-release).
			if _aspect == "draw" and not _ctrl.player().casting.is_empty():
				_well_hold_key = -1
				_ctrl.human({"type": "ability", "id": "release"})
				return
			var id: String = {KEY_1: "flash", KEY_2: "mend", KEY_3: "cascade", KEY_4: "spring"}[code]
			if _aspect == "draw":
				_well_hold_key = code
				_well_hold_ms = Time.get_ticks_msec()
			_cast(id)
		KEY_Q: _cast("dispel")
		KEY_R: _cast("rekindle")

func _healer_key(code: int) -> void:
	if _healer_cls == "well":
		_well_key(code)
		return
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

## Bloomweaver keys: 1 Growth (STACKS a seed) · 2 Barkskin · 3 Overgrowth · 4 BLOOM
## (cash a bed) · 5 Thornlash · Q Sap Rot · E Lifesurge · 7 the aspect signature.
## SPACE/F dodges (cancels an Overgrowth cast — the discipline).
func _bloomweaver_key(code: int) -> void:
	match code:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1: _cast("growth")
		KEY_2: _cast("bark")
		KEY_3: _cast("overgrowth")
		KEY_4: _cast("bloom")
		KEY_5: _cast("lash")
		KEY_Q: _cast("saprot")
		KEY_E: _cast("lifesurge")
		KEY_7: _cast(_signature())

## The Alchemist's keys: HOLD 1 = brew Venom · HOLD 2 = brew Rot (the RELEASE pours —
## see the release branch in _input) · 3/R = Rupture · SPACE = dodge · F = dodge beats.
func _alchemist_key(code: int) -> void:
	match code:
		KEY_SPACE:
			_ctrl.human({"type": "defense"})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1:
			if _brew_hold_key == -1:
				_brew_hold_key = KEY_1
				_ctrl.human({"type": "ability", "id": "brew_venom"})
		KEY_2:
			if _brew_hold_key == -1:
				_brew_hold_key = KEY_2
				_ctrl.human({"type": "ability", "id": "brew_rot"})
		KEY_3, KEY_R:
			_ctrl.human({"type": "ability", "id": "rupture"})
		KEY_4:
			_ctrl.human({"type": "ability", "id": "catalyst"})   # MODULE (Third Reagent): drop it in
		KEY_5:
			_ctrl.human({"type": "ability", "id": "spitfire"})   # SPELL (drafted): filler dart
		KEY_6:
			_ctrl.human({"type": "ability", "id": "decant"})     # SPELL (drafted): snap-to-balance
		KEY_7:
			_ctrl.human({"type": "ability", "id": "reduction"})  # SPELL (drafted): volume→power

## The Reckoner's keys: SPACE = the two-tap SWING (phase-aware — a WIND press, then
## the STRIKE apex press); F = dodge; 1-4 = Overswing / Ultraswing / Onslaught / Signature.
func _reckoner_key(code: int) -> void:
	match code:
		KEY_SPACE:
			var ph := int(_ctrl.player().vars.get("phase", 0))
			# wind phases (0 WIND, 3 onslaught-wind) send "wind"; strike phases send "strike"
			var id := "wind" if (ph == 0 or ph == 3) else "strike"
			_ctrl.human({"type": "ability", "id": id})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)

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
	if _healer_cls == "well":
		_cast_on_well(seat, id)
		return
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
		if _aspect == "draw" and float(sp.get("cast", 0.0)) > 0.0:
			_well_mouse_ms = Time.get_ticks_msec()   # arm mouse hold-release for this cast

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
		fr.glint = s.tick < int(seat.vars.get("glint_until", -1))   # Well: this ally is glinting
		# Well/BRIM: the pour window lives on EVERY frame, always (the aim IS the party bars)
		fr.brim_line = _wcfg.brim_band if (_seat_key == "healer" and _healer_cls == "well" \
			and _aspect == "brim" and _wcfg != null) else 0.0
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

## Healer-only frame overlays: telegraphed incoming damage + (Mender) the cast's heal
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
	if _blade_cls == "reckoner":
		_render_band_reckoner(s, p, obs)
		return
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(float(obs.get("energy", 0.0)), float(obs.get("energy_max", 100.0)))
	_rhythm.since = int(obs.get("since_strike", 0))
	_rhythm.swing_min = int(obs.get("swing_min_ticks", 13))
	_rhythm.perfect_lo = int(obs.get("perfect_lo", 18))
	_rhythm.perfect_hi = int(obs.get("perfect_hi", 29))
	_rhythm.bull_frac = float(obs.get("grade_bull_frac", 0.18))       # GRADED WINDOW (§2c) zones
	_rhythm.perfect_frac = float(obs.get("grade_perfect_frac", 0.55))
	_rhythm.scale_ticks = int(obs.get("rhythm_scale", 33))   # fixed ruler → accelerando visible
	var _asp := String(obs.get("aspect", ""))
	_rhythm.flow = int(obs.get("flow", 0)) if (_asp == "tempo" or _asp == "fermata") else 0
	_rhythm.flow_max = int(obs.get("flow_max", 6))
	# FERMATA: feed the coil (hold-release) state so the bar shows the charge ring + coil cues.
	_rhythm.fermata = _asp == "fermata"
	_rhythm.coiling = bool(obs.get("coiling", false))
	var _cmin := maxi(1, int(obs.get("coil_min_ticks", 11)))
	_rhythm.coil_charge = clampf(float(obs.get("coil_ticks", 0)) / float(_cmin), 0.0, 1.0)
	_rhythm.coil_sharp = bool(obs.get("coil_sharp", false))
	# FERMATA · THE RAMP & THE SNAP — feed the depth bands + the lip (the cliff) for the ramp draw.
	_rhythm.ramp = bool(obs.get("fermata_ramp", false))
	_rhythm.ramp_good_frac = float(obs.get("ramp_good_frac", 0.45))
	_rhythm.ramp_perfect_frac = float(obs.get("ramp_perfect_frac", 0.37))
	_rhythm.lip = int(obs.get("lip_ticks", 0))
	_rhythm.dance_no_snap = bool(obs.get("dance_no_snap", false))
	_tf_gauge.combo = int(obs.get("cp", 0))
	_tf_gauge.combo_max = int(obs.get("cp_max", 5))
	_tf_gauge.flow = int(obs.get("flow", 0))
	_tf_gauge.flow_max = int(obs.get("flow_max", 6))
	_tf_gauge.flow_mult = float(obs.get("flow_mult", 1.0))
	_tf_gauge.tier = int(obs.get("tier", 0))
	_tf_gauge.venom = obs.get("venom", {"V": 0, "F": 0, "C": 0, "syn_ramp": 1.0, "syn_active": false})
	if _opening != null:
		# THE OPENING — the boss's vulnerability window; armed = a dump is ready to punish it
		_opening.now_tick = int(obs.get("tick", 0))
		_opening.from_tick = int(obs.get("open_from", -1))
		_opening.peak_tick = int(obs.get("open_peak", -1))
		_opening.to_tick = int(obs.get("open_to", -1))
		_opening.core_ticks = int(obs.get("open_core_ticks", 3))
		_opening.bonus_now = float(obs.get("open_bonus_now", 0.0))
		_opening.active = int(obs.get("open_to", -1)) >= _opening.now_tick
		_opening.armed = int(obs.get("cp", 0)) >= 1 or bool(obs.get("coup_ready", false)) \
			or bool(obs.get("rupture_ready", false)) or float(obs.get("energy", 0.0)) >= 28.0
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
				if _aspect == "fermata":
					# THE DRAW: the coil button is live whenever you're not staggered — while
					# holding it's "usable" once sharp (release-ready), idle it's always startable.
					usable = (bool(obs.get("coil_sharp", false)) if bool(obs.get("coiling", false))
						else not bool(obs.get("strike_locked", false)))
				else:
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

func _render_band_reckoner(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(float(obs.get("rage", 0.0)), float(obs.get("rage_max", 100.0)))
	var g := _rk_gauge
	g.phase = int(obs.get("phase", 0))
	g.since_wind = int(obs.get("seq_since_wind", 0)) if g.phase == 3 else int(obs.get("since_wind", 0))
	g.wind_len = int(obs.get("wind_len", 27))
	g.even_lo = int(obs.get("even_lo", 9))
	g.heavy_lo = int(obs.get("heavy_lo", 18))
	g.over_lo = int(obs.get("over_lo", 23))
	g.over_armed = bool(obs.get("over_armed", false))
	g.to_apex = int(obs.get("to_apex", 999))
	g.true_half = int(obs.get("true_half", 1))
	g.apex_total = maxi(1, int(round((_rcfg.apex_delay if _rcfg != null else 0.4) * s.config.fixed_hz)))
	g.momentum = float(obs.get("momentum", 0.0))
	g.momentum_max = float(obs.get("momentum_max", 8.0))
	g.poise = float(obs.get("poise", 0.0))
	g.poise_max = float(obs.get("poise_max", 100.0))
	g.stagger = bool(obs.get("stagger", false))
	g.seq_nw = int(obs.get("seq_nw", 0))
	g.seq_ns = int(obs.get("seq_ns", 0))
	g.seat_ref = p
	for i in _runes.size():
		var id: String = _rune_ids[i]
		var usable := true
		match id:
			"overswing": usable = bool(obs.get("over_ready", true))
			"ultraswing": usable = bool(obs.get("ultra_ready", true))
			"onslaught", "sunder", "berserk": usable = bool(obs.get("ons_ready", true))
		_runes[i].affordable = usable
		_runes[i].usable = usable
		_runes[i].cd_frac = 0.0
	_guard.usable = s.tick >= int(p.defense_ready_tick)
	_guard.cd_frac = 0.0

func _render_band_caster(s: CombatState, p: Seat, obs: Dictionary) -> void:
	if _caster_cls == "alchemist":
		_render_band_alchemist(s, p, obs)
		return
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

## THE ALEMBIC eats the whole observe() surface — the instrument renders everything.
func _render_band_alchemist(s: CombatState, p: Seat, obs: Dictionary) -> void:
	_hp_orb.set_values(p.hp, p.hp_max)
	_res_orb.set_values(float(obs.get("potency", 0.0)) * 100.0, 100.0)
	var g := _brew_gauge
	g.venom = float(obs.get("venom", 0.0))
	g.rot = float(obs.get("rot", 0.0))
	g.cap = float(obs.get("cap", 12.0))
	g.charging = String(obs.get("charging", ""))
	g.charge = float(obs.get("charge", 0.0))
	g.charge_max = float(obs.get("charge_max", 1.30))
	g.fizzle_below = float(obs.get("fizzle_below", 0.45))
	g.sweet_lo = float(obs.get("sweet_lo", 0.70))
	g.sweet_hi = float(obs.get("sweet_hi", 0.98))
	g.overflow_at = float(obs.get("overflow_at", 1.0))
	g.balance = float(obs.get("balance", 0.0))
	g.potency = float(obs.get("potency", 0.0))
	g.pot_mult = float(obs.get("pot_mult", 1.0))
	g.react_dps = float(obs.get("react_dps", 0.0))
	g.ripe_glow = float(obs.get("ripe_glow", 0.0))
	g.brew_min = float(obs.get("brew_min", 0.0))
	# MODULES (slice B): the equipped one lights a compact gauge on the instrument.
	g.mod_third_reagent = bool(obs.get("mod_third_reagent", false))
	g.mod_fermentation = bool(obs.get("mod_fermentation", false))
	g.mod_reaction_vessel = bool(obs.get("mod_reaction_vessel", false))
	g.mod_reagent = float(obs.get("reagent", 0.0))
	g.mod_reagent_active = bool(obs.get("reagent_active", false))
	g.mod_ferment = float(obs.get("ferment", 0.0))
	g.mod_vessel = float(obs.get("vessel", 0.0))
	var dcd := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", 2.4)), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd, 0.0, 1.0)

func _render_band_healer(s: CombatState, p: Seat, obs: Dictionary) -> void:
	if _healer_cls == "well":
		_render_band_well(s, p, obs)
		return
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
	_verd.flourish_hi = bool(obs.get("flourish_hi", false))
	_verd.garden = int(obs.get("garden", 0))
	_verd.total_seeds = int(obs.get("total_seeds", 0))
	_verd.flourish_lo = int(_bcfg.flourish_seeds_lo)
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
	if _rk_gauge != null:
		_rk_gauge.on_event(ev)     # THE FORGE: wind/apex stamps + verdict banner + history
		if mine and _blade_cls == "reckoner":
			_reckoner_juice(ev)
	if _brew_gauge != null and mine:
		_brew_gauge.on_event(ev)   # THE ALEMBIC: pour verdicts / rupture burst / history
	if _well_gauge != null:
		_well_gauge.on_event(ev)   # THE WELL: pour/still/clean/under/spill verdicts + history
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
			# GRADED WINDOW (§2c): flash the rhythm bar + pop the graded verdict.
			if mine and _rhythm != null:
				var res := String(ev.get("result", ""))
				# FERMATA ramp: pass the real grade so the DEPTH verdict reads; Tempo folds bull→perfect.
				_rhythm.show_result(res if _rhythm.ramp else ("perfect" if (res == "perfect" or res == "bullseye") else res))
				match res:
					"bullseye":
						_big_text("BULLSEYE!", Palette.GOLD_BRIGHT, 38)
						_add_shake(5.0)
					"perfect":
						_big_text("PERFECT!", Palette.PERFECT, 34)
					"good":
						_big_text("good", Palette.TEXT_DIM, 22, 0.42)
		"snap":
			# FERMATA (EDGE): rode past the lip — the note broke and Flow crashed.
			if mine and _rhythm != null:
				_rhythm.show_result("snap")
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
			if mine and _opening != null:
				var g := String(ev.get("grade", ""))
				_opening.show_result(g)
				if g == "peak":
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
		"caster": return Palette.REACT if _caster_cls == "alchemist" else Palette.KICK
		"healer": return Palette.WIN
	return Palette.GOLD

## THE FORGE screen juice — verdict floats + shake + boss recoil for the Reckoner's hits
## (the instrument's own stamps/banner/history come from _rk_gauge.on_event; damage floats
## ride the paired boss_hit event for free).
func _reckoner_juice(ev: Dictionary) -> void:
	match String(ev.get("t", "")):
		"swing":
			if bool(ev.get("clash", false)):
				_big_text("CLASH!", Palette.GOLD_BRIGHT, 46)
				_add_shake(12.0)
				_dial.react("stagger")
			elif String(ev.get("weight", "")) == "Over":
				_big_text("OVERSWING!", Palette.HEAVY, 42)
				_add_shake(10.0)
			elif String(ev.get("power", "")) == "True":
				_big_text("TRUE!", Palette.PERFECT, 40)
				_add_shake(8.0)
		"poise_break":
			_big_text("STAGGER!", Palette.STEEL, 34, 0.6)
			_add_shake(6.0)
			_dial.react("stagger")
		"ultra":
			_big_text("ULTRA!", Palette.KICK, 36)
			_add_shake(6.0)
		"onslaught":
			_big_text("ONSLAUGHT — ALL TRUE!" if bool(ev.get("all_true", false)) else "ONSLAUGHT", Palette.PERFECT, 40)
			_add_shake(10.0)

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
		# pull again anytime. Handles zone gates too (this branch outranks _gate_live).
		_zone_live = false
		_gate_live = false
		if won:
			_show_fight_recap(func(): _zone_clear_node(_zone_node))
		else:
			_zone_toast = "the warband withdraws — the frontier holds. Pull again anytime."
			_show_zone()
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
		var ex: Dictionary = GateContent.exam(_seat_key, _seat_cls_now())
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
		# THE KILL SWITCH: scavenge ⏻ from a cleared SKIRMISH (not the Seal — you cash out there)
		if String(_map.node(_map_node)["kind"]) == RunMap.KIND_COMBAT:
			_map_charge = mini(100, _map_charge + MapFx.SKIRMISH_CHARGE)
		# GEAR-1: the kill's drop ceremony runs first, then the run continues wherever
		# it was headed (map / elevation / campaign clear).
		var after: Callable = _show_map
		if String(_map.node(_map_node)["kind"]) == RunMap.KIND_SEAL:
			# a floor Seal fell: elevate to the next ring, or clear the realm on the last
			after = _show_campaign_cleared if _floor >= RaidContent.FLOORS.size() - 1 \
				else _show_floor_cleared
		# THE RECKONING first — the raid ranked by damage + the fight's biggest hit —
		# THEN gear drop, THEN the boon REFORGE (1-of-3), THEN continue (map/elevate/clear).
		# ARMORY: only a Seal kill is a drop EVENT here — skirmish repeats pay salvage
		var seal_kill: bool = String(_map.node(_map_node)["kind"]) == RunMap.KIND_SEAL
		var enc_id := String(_ctrl.state.encounter.id)
		_show_fight_recap(func(): _after_drop(enc_id,
			func(): _show_boon_draft(after), seal_kill))
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
	_place(box, 0.5, 0.5, 0.5, 0.5, -320, -250, 320, 265)
	_ui.add_child(box)
	var hl := _title(box, "THE RECKONING", 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_title(box, String(s.encounter.name) + "  —  DOWN", 14, Palette.TEXT_DIM)
	var big := _biggest_hit(s)
	if not big.is_empty():
		_title(box, "★  BIGGEST HIT   %s  —  %d   (%s)" % [MeterPanel.pretty_src(big["src"]),
			int(big["amt"]), String(big["who"])], 16, Palette.GOLD_BRIGHT)
	if _ctrl.player() != null:
		box.add_child(RecapPanel.new(s, _ctrl.player(), _recap_stats))
	var cont := Button.new()
	cont.custom_minimum_size = Vector2(220, 48)
	cont.add_theme_font_size_override("font_size", 18)
	cont.text = "CONTINUE ▸"
	cont.pressed.connect(func(): done.call())
	box.add_child(cont)
	# the raid RANKED by damage, top-right — click a raider for their per-spell breakdown
	var rmeter := MeterPanel.new(_ctrl, "heal" if _seat_key == "healer" else "dmg", true)
	_place(rmeter, 1, 0, 1, 0, -318, 118, -18, 600)
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
	# A Topology descent that WIPED still banks 📁 Prior (leftover ⚡ converts) — the
	# facility trains on every run. (A map win banks via _show_campaign_cleared instead.)
	if _map != null and not _online:
		var pg := _bank_prior(false)
		_title(box, "📁 TRAINING SIGNAL RECORDED — prior %d (+%d). The facility remembers." % [_prior, pg], 13, Palette.VOID)
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
