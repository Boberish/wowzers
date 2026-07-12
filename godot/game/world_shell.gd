## WorldShell — the game's FRONT DOOR (REFIT-PLAN P3.2a: the ownership inversion).
## The shell owns the boot: it raises the combat HUD as its INSTANCE SURFACE and
## drives the dev autostart idioms AGAINST it — the jump-ins are one explicit entry
## that drives the shell, not a parallel boot path baked into the instance. P3.2b
## migrates the world screens (home/atlas/zone/bastion/party) up here so the world
## OWNS the HUD outright; P3.3 gives the shell the online/presence door.
##
## Probes/smokes that load raid_main.tscn directly keep working — the HUD stays a
## self-contained instance surface; only the BOOT (project main_scene) is the shell.
class_name WorldShell
extends Control

const RaidHud := preload("res://game/raid_hud.gd")

var hud: RaidHud = null   ## the combat HUD instance surface — TYPED so the moved
                          ## builders' `:=` inference sees real member types
var _ui: Control           ## the shell's own screen surface (drawn OVER the instance)
var _screen: String = "home"   ## home/class/aspect/raidpick/party/atlas/bastion/zone/zonestop/bosstest · "instance" = the HUD drives
var _dev_seat: String = "tank"   ## DEV · BOSS TEST: which seat the jump-in takes (debug-only tooling)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate() as RaidHud
	add_child(hud)                      # child _ready runs here (blank until we route)
	hud._shell = self                   # the delegators (home/select/zone) route UP
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	# IGNORE: an EMPTY shell surface must never eat the instance's clicks; the shell's
	# own buttons are separate hit targets and still receive input fine.
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)                      # sits over the HUD — shell screens draw on top
	_show_home()
	drive_autostart(OS.get_cmdline_user_args())
	_maybe_boot_spike_web()   # web builds get no cmdline args — boot the spike from ?spike instead

## THROWAWAY: boot the mobile Tempo spike (a full-screen touch Control over the blank HUD).
## Its own _input drives it, so the IGNORE _ui surface doesn't block its touches.
func _boot_mobile_spike() -> void:
	_clear_shell_ui()
	var spike := MobileSpike.new()
	spike.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(spike)

## Web has no cmdline args; read the page URL (?spike) the same way the online field does.
func _maybe_boot_spike_web() -> void:
	if not OS.has_feature("web"):
		return
	var q := str(JavaScriptBridge.eval("window.location.search", true))
	if q.findn("spike") >= 0:
		_boot_mobile_spike()

## Clear the shell surface AND blank the instance surface under it (a shell screen
## replaces whatever the HUD showed). hud._clear() calls back to _clear_shell_ui —
## a leaf, so the mutual clears terminate.
func _clear() -> void:
	var scr := _screen              # builders stamp _screen BEFORE clearing; the
	for c in _ui.get_children():    # hud._clear() below leaf-calls _clear_shell_ui,
		c.queue_free()              # which stamps "instance" — restore ours after.
	hud._clear()
	hud._screen = "shell"
	_screen = scr

## Leaf: the HUD is building an instance screen — the shell surface gets out of the way.
func _clear_shell_ui() -> void:
	_screen = "instance"
	for c in _ui.get_children():
		c.queue_free()

## The dev jump-ins (CLAUDE.md run-book: raid / raidmap / world / zone).
## Moved verbatim off raid_hud._ready in P3.2a; `--fightlen=` stays HUD-side (it is
## an instance feel-scalar, parsed there before any pull).
func drive_autostart(args: PackedStringArray) -> void:
	for a in args:
		if a.begins_with("--autostart=mobilespike"):
			# THROWAWAY mobile touch spike (Twinfang·Tempo feel test). Native/editor entry;
			# the web build boots it via the ?spike URL param (see _maybe_boot_spike_web).
			_boot_mobile_spike()
		elif a.begins_with("--autostart=raidmap"):
			# --autostart=raidmap[:seat[:aspect]]  → straight onto the Topology floor
			var mspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = mspec[1] if mspec.size() > 1 and hud.SEAT_IDX.has(mspec[1]) else "tank"
			hud._aspect = mspec[2] if mspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._start_map_run()
		elif a.begins_with("--autostart=world") or a.begins_with("--autostart=atlas"):
			# --autostart=world[:seat[:aspect]]  → THE WORLD preview, straight onto the Atlas
			var wspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = wspec[1] if wspec.size() > 1 and hud.SEAT_IDX.has(wspec[1]) else "tank"
			hud._aspect = wspec[2] if wspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._sync_healer_cls()
			_show_atlas()
		elif a.begins_with("--autostart=zone"):
			# --autostart=zone[:seat[:aspect]]  → straight into ZONE 1 (the Gildfields)
			var zspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = zspec[1] if zspec.size() > 1 and hud.SEAT_IDX.has(zspec[1]) else "tank"
			hud._aspect = zspec[2] if zspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._sync_healer_cls()
			hud._zone_id = WorldContent.ZONE1
			if hud._world == null:
				hud._world = WorldSave.load_save()
			hud._ensure_party()
			_show_zone()
		elif a.begins_with("--autostart=raid"):
			# --autostart=raid[:seat[:aspect[:boss]]]  e.g. raid:blade:tempo:mythos
			var spec := a.substr("--autostart=".length()).split(":")
			var seat := spec[1] if spec.size() > 1 else "tank"
			var aspect := spec[2] if spec.size() > 2 else ""
			var enc := spec[3] if spec.size() > 3 else ""
			hud._launch(seat, aspect, enc)

# ============================================================ THE WORLD LAYER
# (REFIT P3.2b-2: every world-layer screen moved here VERBATIM from raid_hud,
#  instance state reached via `hud.` — state ownership lifts in a later pass.)

func _show_home() -> void:
	_screen = "home"
	hud._d.map = null
	hud._map_pending = false
	hud._world_pending = false
	hud._zone_live = false
	hud._zone_id = ""
	hud._party_ctx = ""
	hud._online_map = false
	hud._d.run = null                       # no descent = no boon run (fresh one per descent)
	hud._d.ai_runs = {}                     # COMMANDER: the AI raiders' boon runs die with it
	_clear()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -260, -270, 260, 290)
	_ui.add_child(box)
	var t := UiKit.title_in(box, "THE RIFT", 76, Palette.GOLD)
	t.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(box, "REALM 1 · THE TAKEOVER", 15, Palette.TEXT_DIM)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	box.add_child(gap)
	box.add_child(_menu_button("▶    PLAY", Palette.GOLD_BRIGHT, _show_class_select))
	box.add_child(_menu_button("🌐    PLAY ONLINE", Palette.FLOW, hud._show_online))
	if hud.WORLD_PREVIEW:   # W1: the world door (PLAY → ATLAS becomes the front door at W3)
		box.add_child(_menu_button("⟐    THE WORLD — preview", Palette.VERDANCE, _start_world_pick))
	if OS.is_debug_build():   # DEV · BOSS TEST — jump straight into any Seal (never in a release build)
		box.add_child(_menu_button("🐞    DEV · BOSS TEST", Palette.REACT, _show_boss_test))
	box.add_child(_menu_button("QUIT", Palette.TEXT_DIM, func(): get_tree().quit()))

func _menu_button(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(330, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", accent)
	b.pressed.connect(cb)
	return b

## DEV · BOSS TEST (debug builds only, gated at the home button) — pick a seat, then a
## Seal, and jump STRAIGHT into that single-boss fight, skipping the class/aspect/raid/
## party ceremony. Pure dev tooling: it drives the same hud._launch() the raid autostart
## uses (--autostart=raid:seat:aspect:boss), so the AI party is filled and the fight
## starts exactly as a normal Seal pull. The seat tokens feed _launch's debug aliases.
func _show_boss_test() -> void:
	_screen = "bosstest"
	hud._d.map = null
	hud._map_pending = false
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -420, 70, 420, 150)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "DEV · BOSS TEST", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "pick a seat, then a Seal — jump straight into the fight (debug only)", 14, Palette.TEXT_DIM)
	# seat toggle — the token feeds hud._launch's debug aliases (tank/blade/alchemist/well/bloom)
	var seats := [
		["tank", "DUELIST"], ["blade", "TWINFANG"], ["alchemist", "ALCHEMIST"],
		["well", "WELL"], ["bloom", "BLOOM"],
	]
	var seatrow := HBoxContainer.new()
	seatrow.alignment = BoxContainer.ALIGNMENT_CENTER
	seatrow.add_theme_constant_override("separation", 8)
	UiKit.place(seatrow, 0.5, 0, 0.5, 0, -440, 165, 440, 205)
	_ui.add_child(seatrow)
	for s in seats:
		var sid := String(s[0])
		var sb := Button.new()
		sb.text = String(s[1])
		sb.custom_minimum_size = Vector2(155, 38)
		sb.add_theme_font_size_override("font_size", 15)
		sb.add_theme_color_override("font_color", Palette.GOLD_BRIGHT if sid == _dev_seat else Palette.TEXT_DIM)
		sb.pressed.connect(_dev_pick_seat.bind(sid))
		seatrow.add_child(sb)
	# the Seals, canonical from RaidContent (auto-tracks any boss added to run_encounters)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	UiKit.place(col, 0.5, 0.5, 0.5, 0.5, -280, -60, 280, 200)
	_ui.add_child(col)
	for e in RaidContent.run_encounters():
		var bid := String(e.id)
		col.add_child(_menu_button(String(e.name), Palette.CRIMSON, hud._launch.bind(_dev_seat, "", bid)))
	var back := Button.new()
	back.text = "◂ back"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	UiKit.place(back, 0.5, 1, 0.5, 1, -80, -78, 80, -44)
	back.pressed.connect(_show_home)
	_ui.add_child(back)

## DEV · BOSS TEST: switch the jump-in seat, then re-render to move the highlight.
func _dev_pick_seat(sid: String) -> void:
	_dev_seat = sid
	_show_boss_test()

## PLAY → pick your CLASS (the four raid seats; you play one, AI fills the rest).
func _show_class_select() -> void:
	_screen = "class"
	hud._d.map = null
	hud._map_pending = false
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -420, 120, 420, 205)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "CHOOSE YOUR CLASS", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "you play one · AI raiders fill the other three seats", 14, Palette.TEXT_DIM)
	# [seat, class, name, icon, accent, blurb] — the healer SEAT has two classes
	# (Well / Bloomweaver), so five cards map onto the four seats.
	var cards := [
		["tank", "duelist", "THE DUELIST", "guard", Palette.STEEL, "TANK · DODGE — dance the stream, parry the big ones, hit back. Play clean to HOLD its gaze (flow = aggro)."],
		["blade", "twinfang", "THE TWINFANG", "flurry", Palette.FLOW, "MELEE · DRIVE THE RHYTHM — perfect your strikes, never out-threat the tank.  (Tempo / Venomancer)"],
		["caster", "alchemist", "THE ALCHEMIST", "envenom", Palette.REACT, "CASTER · BREW THE REACTION — charge the vial, feed two opposing poisons, RUPTURE the peak.  (The Brew · NEW)"],
		["healer", "well", "THE WELL-TENDER", "laststand", Palette.GOLD_BRIGHT, "HEALER · POUR — discrete CHARGES, no mana; GRADE every heal (TARGET the landing / SPEED the release), and a perfect one GLINTS the ally you healed.  (Brim / Draw · NEW)"],
		["healer", "bloomweaver", "THE BLOOMWEAVER", "wildbloom", Palette.VERDANCE, "HEALER · ANTICIPATE — no mana; plant HoTs & wards AHEAD, bloom them on the spike.  (Wildgrove / Thornveil)"],
	]
	# AspectCard is a WIDE 680px card — STACK them vertically in a SCROLL box (the scroll
	# keeps every class reachable as the roster grows).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiKit.place(scroll, 0.5, 0.5, 0.5, 0.5, -360, -330, 360, 340)
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
	UiKit.place(back, 0.5, 1, 0.5, 1, -80, -78, 80, -44)
	back.pressed.connect(_show_home)
	_ui.add_child(back)

## SUB-CLASS chosen → pick your RAID (one for now: Realm 1). Future realms add cards here.
func _show_raid_select(seat_id: String, aspect: String) -> void:
	hud._seat_key = seat_id
	hud._aspect = aspect
	if hud._world_pending:              # THE WORLD (W1): the aspect ceremony opens the Atlas
		hud._world_pending = false
		hud._sync_healer_cls()
		_show_atlas()
		return
	_screen = "raidpick"
	hud._map_pending = false
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -420, 120, 420, 210)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "CHOOSE YOUR RAID", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "%s · %s" % [hud.SEAT_NAMES.get(seat_id, "RAIDER"), aspect.capitalize()], 14, Palette.TEXT_DIM)
	var mid := CenterContainer.new()
	UiKit.place(mid, 0.5, 0.5, 0.5, 0.5, -360, -150, 360, 150)
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
	UiKit.place(back, 0.5, 1, 0.5, 1, -110, -78, 110, -44)
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
	hud._ensure_party()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -360, -300, 360, 300)
	_ui.add_child(box)
	var hl := UiKit.title_in(box, "ASSEMBLE YOUR RAID", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(box, "their class, their aspect, their boons — your call. the AI only drives the rotation.",
		13, Palette.TEXT_DIM)
	var gap0 := Control.new()
	gap0.custom_minimum_size = Vector2(0, 8)
	box.add_child(gap0)
	for key in RaidNet.SEAT_KEYS:
		var mine: bool = key == hud._seat_key
		var cls: String = hud._seat_cls_now() if mine else String(hud._d.party[key]["cls"])
		var aspect: String = hud._aspect if mine else String(hud._d.party[key]["aspect"])
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var disp := String(hud.SEAT_NAMES[key])
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
			if key == "healer":     # polymorphic CLASS toggle (Well ⇄ Bloomweaver)
				var clsb := Button.new()
				var cn: String = {"bloomweaver": "BLOOMWEAVER"}.get(cls, "WELL")
				clsb.text = "◈ " + cn
				clsb.custom_minimum_size = Vector2(150, 32)
				clsb.pressed.connect(func():
					# cycle the seat's classes off the CLASS REGISTRY (a 3rd healer would
					# appear here with zero UI work — the P4 seam this button exists for)
					var pool: Array = ClassRegistry.classes_for_seat(String(key))
					var nc: String = String(pool[(pool.find(cls) + 1) % pool.size()])
					hud._d.party[key] = {"cls": nc, "aspect": RaidNet.default_aspect(String(key), nc)}
					_show_party_setup())
				row.add_child(clsb)
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 32)
			ab.pressed.connect(func():
				var pool: Array = hud._lobby_aspects(String(key), cls)
				var idx := 0
				for i in pool.size():
					if String(pool[i]["id"]) == aspect:
						idx = i
				hud._d.party[key]["aspect"] = String(pool[(idx + 1) % pool.size()]["id"])
				_show_party_setup())
			row.add_child(ab)
		# the chosen aspect's one-line identity, dim, under each row
		for a in hud._lobby_aspects(String(key), cls):
			if String(a["id"]) == aspect:
				var d := UiKit.title_in(box, String(a["desc"]), 12, Palette.TEXT_DIM)
				d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				d.custom_minimum_size = Vector2(600, 0)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	var go := Button.new()
	# THE BASTION's Warband Camp reuses this screen as a PLACE — muster returns to the
	# hearth instead of pulling a descent (the raid flow is untouched when hud._party_ctx == "").
	go.text = "⚑    MUSTER — the warband stands ready" if hud._party_ctx == "bastion" else "⚔    DESCEND"
	go.custom_minimum_size = Vector2(260, 52)
	go.add_theme_font_size_override("font_size", 19)
	go.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	go.pressed.connect(func():
		hud._save_roster()   # ROSTER PERSISTENCE (REFIT P4): confirm = commit the warband
		if hud._party_ctx == "bastion":
			_show_bastion()
		else:
			hud._start_map_run())
	var goc := CenterContainer.new()
	goc.add_child(go)
	box.add_child(goc)
	var back := Button.new()
	back.text = "◂ back"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	if hud._party_ctx == "bastion":
		back.pressed.connect(_show_bastion)
	else:
		back.pressed.connect(func(): _show_raid_select(hud._seat_key, hud._aspect))
	UiKit.place(back, 0.5, 1, 0.5, 1, -80, -58, 80, -24)
	_ui.add_child(back)

# ============================================================ ASPECT PICK
## BossSelect chose a seat (+ optionally a Seal) — now the Aspect ceremony.
func _start_raid(seat_id: String, jump_to: String = "") -> void:
	hud._map_pending = false
	hud._enc_id = jump_to if jump_to != "" else "riftmaw"
	_show_aspect_pick(seat_id if hud.SEAT_IDX.has(seat_id) else "tank")

## TOPOLOGY entry: same seat → aspect ceremony, but the pull lands on the map.
func _start_map_pick(seat_id: String) -> void:
	hud._map_pending = true
	_show_aspect_pick(seat_id if hud.SEAT_IDX.has(seat_id) else "tank")

## Class-select card chosen. For the healer seat this also records WHICH healer class
## (well / bloomweaver) — the rest of the flow reads hud._healer_cls to pick aspects/band.
func _pick_class(seat_id: String, cls: String) -> void:
	if seat_id == "healer":
		hud._healer_cls = cls
	elif seat_id == "blade":
		hud._blade_cls = cls
	elif seat_id == "caster":
		hud._caster_cls = cls
	_show_aspect_pick(seat_id)

func _show_aspect_pick(seat_id: String) -> void:
	_screen = "aspect"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -420, 150, 420, 260)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, hud._seat_display_name(seat_id), 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(head, "C H O O S E   Y O U R   A S P E C T", 15, Palette.TEXT_DIM)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -340, -130, 340, 130)
	_ui.add_child(box)
	for a in hud._aspects_for(seat_id):
		var card := AspectCard.new(String(a["name"]), String(a["desc"]), a["accent"], String(a["icon"]))
		card.chosen.connect(_show_raid_select.bind(seat_id, String(a["id"])))
		box.add_child(card)

	var back := Button.new()
	back.text = "◂ back to classes"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	UiKit.place(back, 0.5, 1, 0.5, 1, -110, -90, 110, -56)
	back.pressed.connect(_show_class_select)
	_ui.add_child(back)

# ============================================================ THE WORLD (WORLD-PLAN W1)
## The persistent overworld preview: HOME → seat/aspect ceremony → THE ATLAS → zones
## (persistent conquest, bare-kit isolated fights) / THE BASTION (the meta as a place) /
## the raid door (the existing descent, untouched). The world is PERMANENCE; the runs
## behind doors keep the whole rolling economy — the Split, made playable.

## HOME's world door: pick who YOU are first (the warband follows), then the Atlas.
func _start_world_pick() -> void:
	hud._world_pending = true
	_show_class_select()

func _show_atlas() -> void:
	_screen = "atlas"
	hud._zone_live = false
	hud._party_ctx = ""
	if hud._world == null:
		hud._world = WorldSave.load_save()
	hud._ensure_party()
	_clear()
	var at := AtlasScreen.new()
	at.save = hud._world
	at.at_pin = hud._zone_id if hud._zone_id != "" else "bastion"
	at.pin_entered.connect(_enter_atlas_pin)
	at.back_requested.connect(_show_home)
	at.reset_requested.connect(_world_dev_reset)
	at.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(at)

## DEV (W1 preview): wipe the world — fresh fog, fresh conquest, on disk too.
func _world_dev_reset() -> void:
	hud._world = WorldSave.wipe()
	hud._zone_id = ""
	_show_atlas()

func _enter_atlas_pin(id: String) -> void:
	match id:
		"bastion":
			hud._zone_id = ""
			_show_bastion()
		"rift_scar":
			# the raid DOOR: the existing Realm-1 descent, verbatim (full run economy
			# lives behind doors — the Split). Campaign end routes home as it always has.
			hud._party_ctx = ""
			hud._start_map_run()
		_:
			if not WorldContent.zone(id).is_empty():
				hud._zone_id = id
				_show_zone()

## THE BASTION v1: the meta screens becoming a PLACE (WORLD-PLAN hometown). One hearth
## screen with stations; the Warband Camp is real (Commander party setup re-doored),
## the rest are foundations laid for W3.
func _show_bastion() -> void:
	_screen = "bastion"
	hud._party_ctx = "bastion"
	_clear()
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.place(head, 0.5, 0, 0.5, 0, -420, 110, 420, 210)
	_ui.add_child(head)
	var hl := UiKit.title_in(head, "THE BASTION", 40, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.title(900))
	UiKit.title_in(head, "hearth & muster — the warband's home. The stations are rising.", 14, Palette.TEXT_DIM)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	UiKit.place(col, 0.5, 0.5, 0.5, 0.5, -350, -220, 350, 260)
	_ui.add_child(col)
	var camp := AspectCard.new("THE WARBAND CAMP",
		"The Commander's tent: every AI raider's class and aspect is YOUR muster call. (The party you set here rides every fight — zone, dungeon, raid.)",
		Palette.GOLD_BRIGHT, "shockwave")
	camp.chosen.connect(func():
		hud._party_ctx = "bastion"
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
	hud._zone_live = false
	if hud._world == null:
		hud._world = WorldSave.load_save()
	_clear()
	var zs := ZoneScreen.new()
	zs.zone = WorldContent.zone(hud._zone_id)
	zs.save = hud._world
	zs.toast = hud._zone_toast
	hud._zone_toast = ""                  # one-shot — clears once shown
	zs.node_entered.connect(_enter_zone_node)
	zs.back_requested.connect(_show_atlas)
	zs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(zs)

func _enter_zone_node(id: int) -> void:
	var z := WorldContent.zone(hud._zone_id)
	hud._zone_node = id
	hud._world.set_at(hud._zone_id, id)
	# §MEWGENICS STEALS ① — escort transitions fire on ENTERING the node, cleared or not, so a
	# turn-in at a door you already marked (rushed there before picking up) still completes the
	# carry. For an uncleared escort node the message folds into its stop (camp/door) below.
	if hud.ESCORT_PREVIEW:
		hud._escort_line = Escort.on_enter(hud._world, hud._zone_id, id)
	if hud._world.is_cleared(hud._zone_id, id):
		if hud._escort_line != "":        # a cleared node has no stop panel — surface it as a banner
			hud._zone_toast = hud._escort_line
			hud._escort_line = ""
		_world_autosave()             # free travel — the token moves, conquered ground never re-fights
		_show_zone()
		return
	var n := WorldContent.resolved_node(z, id, hud._world.flags(hud._zone_id))
	match String(n["kind"]):
		"fight", "elite", "boss":
			var body := WorldContent.BOSS_INTRO if String(n["kind"]) == "boss" else String(n["sub"])
			# §MEWGENICS STEALS ① — if the vial you're carrying will burden this fight, say so
			# BEFORE the pull: the player must connect the extra pressure to the escort.
			if hud.ESCORT_PREVIEW and Escort.burden_for(hud._world, hud._zone_id, n) != "":
				body = "◈  The vial weeps — the harvest-rot rises to meet you here. This fight is worse for the carrying.\n\n" + body
			_zone_stop(String(n["name"]), body,
				[{"label": "MOVE IN", "fx": {"result": "The warband forms up."}}],
				ZoneScreen.KIND_COL[String(n["kind"])], hud._launch_zone_fight.bind(n))
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
		if wf.size() == 2 and hud._world != null and hud._zone_id != "":
			hud._world.set_flag(hud._zone_id, String(wf[0]), String(wf[1]))
		done.call())
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(p)

func _zone_stop_event(n: Dictionary, ev: Dictionary) -> void:
	var accent: Color = ZoneScreen.KIND_COL[String(n["kind"])]
	_zone_stop(String(ev["title"]), String(ev["body"]), ev["choices"], accent,
		func(): _zone_clear_node(hud._zone_node))

## Camps, caches, the waystation, the instance door — one beat of fiction, then conquest.
func _zone_simple_stop(n: Dictionary) -> void:
	var nn := String(n["name"])   # (not `name` — shadows the Node property)
	# §MEWGENICS STEALS ① — an escort pickup/turn-in fired on this node: lead the fiction
	# with it (camp = the vial; door = sealing it away). One-shot, empty otherwise.
	var pre := ""
	if hud._escort_line != "":
		pre = "◈  " + hud._escort_line + "\n\n"
		hud._escort_line = ""
	match String(n["kind"]):
		"camp":
			_zone_stop(nn, pre + String(WorldContent.CAMP_TEXT.get(nn, "The warband rests.")),
				[{"label": "REST A WHILE", "fx": {"result": "The fields keep their quiet."}}],
				Palette.FLOW, func(): _zone_clear_node(hud._zone_node))
		"cache":
			_zone_stop(nn, pre + String(WorldContent.CACHE_TEXT.get(nn, "Spoils of the fields.")),
				[{"label": "TAKE STOCK", "fx": {"result": "Marked, counted, carried."}}],
				Palette.GOLD, func(): _zone_clear_node(hud._zone_node))
		"waystation":
			_zone_stop(nn, pre + WorldContent.WAYSTATION_TEXT,
				[{"label": "LIGHT THE BEACON", "fx": {"result": "The sky roads answer."}}],
				Palette.WIN, func(): _zone_clear_node(hud._zone_node))
		"door":
			_zone_stop(nn, pre + WorldContent.DOOR_TEXT,
				[{"label": "MARK THE ATLAS", "fx": {"result": "The route is yours. The door will know you."}}],
				Palette.RELIC, func(): _zone_clear_node(hud._zone_node))

## Conquest writeback — the ONLY thing a zone hands the permanence layer. Cleared is
## cleared forever; the waystation joins the flight web; the capstone crests the zone.
func _zone_clear_node(nid: int) -> void:
	var z := WorldContent.zone(hud._zone_id)
	var first := not hud._world.is_cleared(hud._zone_id, nid)
	hud._world.mark_cleared(hud._zone_id, nid)
	if first:
		var n := WorldContent.resolved_node(z, nid, hud._world.flags(hud._zone_id))
		hud._zone_toast = "⚑  %s — YOURS, forever" % String(n["name"])
		if String(n["kind"]) == "waystation":
			hud._world.unlock_waystation(hud._zone_id)
			hud._zone_toast = "^  FLIGHT PATH OPENED — Gildwatch joins the sky roads"
		if nid == int(z["capstone_id"]):
			hud._zone_toast = "★  THE OLD MILL FALLS — ZONE CLEARED. The Gildfields are yours."
	_world_autosave()
	_show_zone()

func _world_autosave() -> void:
	if hud._world != null:
		hud._world.save_to_disk()


# ============================================================ ONLINE (P3.3)
# The connection lifecycle — connect form + lobby — lives on the shell (the
# presence door). The online DESCENT (net map/draft/arming/fights) stays on the
# instance surface; the shell hands off the moment the server starts a fight.

func _show_online() -> void:
	hud._ensure_net()
	hud._online = true
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
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -260, -220, 260, 220)
	_ui.add_child(box)
	var hl := UiKit.title_in(box, "THE RIFT — ONLINE", 34, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(box, "Run the server (see server/README.md), share the address, pull together.", 13, Palette.TEXT_DIM)
	var name_edit := _edit(box, "your name", pname)
	var url_edit := _edit(box, "server (ws://host:port)", url)
	var room_edit := _edit(box, "room code", room)
	var go := Button.new()
	go.text = "CONNECT"
	go.custom_minimum_size = Vector2(240, 46)
	go.add_theme_font_size_override("font_size", 17)
	box.add_child(go)
	hud._net_status = UiKit.title_in(box, "", 13, Palette.TEXT_DIM)
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
		hud._net.close()
		hud._set_net_status("connecting to %s …" % u)
		hud._net.connect_to(u, n, r))
	back.pressed.connect(func():
		hud._net.close()
		hud._online = false
		_show_home())

func _edit(parent: Node, placeholder: String, value: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = value
	e.custom_minimum_size = Vector2(420, 40)
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(e)
	return e

## The hud's _on_room stub stored the snapshot; re-render if a lobby surface is up.
func _on_room_shell() -> void:
	if _screen == "netconnect" or _screen == "lobby":
		_show_lobby()

func _show_lobby() -> void:
	_screen = "lobby"
	hud._online_map = false               # MAP-3b: back in the lobby = not descending
	hud._d.run = null                       # online descents rebuild the boon run from the map seed
	_clear()
	var me := hud._me()
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	UiKit.place(box, 0.5, 0.5, 0.5, 0.5, -330, -280, 330, 280)
	_ui.add_child(box)
	var hl := UiKit.title_in(box, "ROOM  ·  %s" % String(hud._room.get("code", "")), 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	UiKit.title_in(box, "claim a seat · pick your aspect · ready · the host pulls", 13, Palette.TEXT_DIM)

	for key in RaidNet.SEAT_KEYS:
		var claimant := {}
		for p in hud._room.get("players", []):
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
		var seat_disp := String(hud.SEAT_NAMES[key])
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
			cb.pressed.connect(func(): hud._net.send({"t": "claim", "seat": key}))
			row.add_child(cb)
		elif claimant == me:
			if key == "healer":     # toggle the healer CLASS (Well ⇄ Bloomweaver)
				var mycls := String(me.get("cls", "well"))
				var clsb := Button.new()
				var mcn: String = {"bloomweaver": "BLOOMWEAVER"}.get(mycls, "WELL")
				clsb.text = "◈ " + mcn
				clsb.custom_minimum_size = Vector2(150, 34)
				clsb.pressed.connect(func():
					var nc: String = "bloomweaver" if mycls == "well" else "well"
					hud._net.send({"t": "class", "cls": nc}))
				row.add_child(clsb)
			var ab := Button.new()
			ab.text = "ASPECT ⇄"
			ab.custom_minimum_size = Vector2(110, 34)
			ab.pressed.connect(func():
				var pool: Array = hud._lobby_aspects(key, String(me.get("cls", "")))
				var cur := String(me.get("aspect", ""))
				var idx := 0
				for i in pool.size():
					if String(pool[i]["id"]) == cur:
						idx = i
				hud._net.send({"t": "aspect", "aspect": String(pool[(idx + 1) % pool.size()]["id"])}))
			row.add_child(ab)

	# The Seal for the next pull — everyone sees it; the host cycles it.
	var enc_id := String(hud._room.get("enc", "riftmaw"))
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
	if int(hud._room.get("host", -1)) == hud._net.peer_id():
		var sb := Button.new()
		sb.text = "SEAL ⇄"
		sb.custom_minimum_size = Vector2(110, 32)
		sb.pressed.connect(func():
			var nxt: EncounterRes = seals[(seal_i + 1) % seals.size()]
			hud._net.send({"t": "boss", "enc": String(nxt.id)}))
		srow.add_child(sb)

	var ctlrow := HBoxContainer.new()
	ctlrow.alignment = BoxContainer.ALIGNMENT_CENTER
	ctlrow.add_theme_constant_override("separation", 16)
	box.add_child(ctlrow)
	hud._my_ready = bool(me.get("ready", false))
	var rb := Button.new()
	rb.text = "READY  ✓" if hud._my_ready else "READY?"
	rb.custom_minimum_size = Vector2(150, 44)
	rb.pressed.connect(func(): hud._net.send({"t": "ready", "on": not hud._my_ready}))
	ctlrow.add_child(rb)
	if int(hud._room.get("host", -1)) == hud._net.peer_id():
		var pull := Button.new()
		pull.text = "⚔  PULL"
		pull.custom_minimum_size = Vector2(150, 44)
		pull.add_theme_font_size_override("font_size", 17)
		pull.pressed.connect(func(): hud._net.send({"t": "start"}))
		ctlrow.add_child(pull)
		var descend := Button.new()
		descend.text = "🌐  DESCEND"
		descend.custom_minimum_size = Vector2(170, 44)
		descend.add_theme_font_size_override("font_size", 17)
		descend.pressed.connect(func(): hud._net.send_mapstart())    # MAP-3b: the Topology descent
		ctlrow.add_child(descend)
	hud._net_status = UiKit.title_in(box, "PULL = one Seal · DESCEND = the Topology campaign (leader routes) · empty seats fight as AI", 12, Palette.TEXT_DIM)
	var back := Button.new()
	back.text = "◂ leave room"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	back.pressed.connect(func():
		hud._net.close()
		hud._online = false
		_show_home())
	box.add_child(back)

