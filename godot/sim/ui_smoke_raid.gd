## Headless smoke test for the RAID HUD (R1 v2 — any seat): instantiate the scene,
## then for EACH of the four playable seats build the combat screen, run ~30s of
## live raid with scripted human input, and exercise the juice handlers.
##
##   godot --headless --path godot --script res://sim/ui_smoke_raid.gd
extends SceneTree

var shell: Control
var hud: Control
var done := false

func _process(_delta: float) -> bool:
	if done:
		return true
	if hud == null:
		shell = load("res://game/world_shell.tscn").instantiate()
		root.add_child(shell)
		hud = shell.hud
		return false
	done = true

	print("select screen: ok (ui=", hud._ui != null, " ctrl=", hud._ctrl != null, ")")

	for seat_key in ["tank", "blade", "caster", "healer"]:
		shell._show_aspect_pick(seat_key)
	print("aspect-pick screens (x4): ok")

	# TEMPO REWORK framework plumbing: SWEAR A CREED → INSTALL A MODULE → fold into the blade kit.
	hud._seat_key = "blade"
	hud._aspect = "tempo"
	hud._d.run = hud._make_run()
	assert(hud._d.run.char_class == "twinfang", "blade run should be twinfang")
	var flags := {"creed": false, "mod": false, "skip": false}   # dict = by-ref so lambdas can mutate it
	hud._show_creed_pick(func(): flags.creed = true)
	assert(hud._screen == "creed" and not flags.creed, "creed pick should SHOW and wait for a choice")
	hud._pick_creed("flourish", func(): flags.creed = true)
	assert(hud._d.run.creed == "flourish" and flags.creed, "picking a creed sets run.creed + continues")
	hud._show_module_pick(func(): flags.mod = true)
	assert(hud._screen == "module" and not flags.mod, "module pick should SHOW and wait")
	hud._pick_module("edge", func(): flags.mod = true)
	assert(hud._d.run.modules.has("edge") and flags.mod, "picking a module sets run.modules + continues")
	# the blade kit actually CARRIES the sworn creed + installed module after injection
	var bseat: Seat = RaidContent._blade_seat("twinfang", "tempo")
	hud._inject_boons(bseat)
	var bk := bseat.kit as TwinfangKit
	assert(bk.creed_id == "flourish" and bk.modules.has("edge"), "creed+module fold into the blade kit")
	# TANK-V2 (TANK-PLAN §0): the rebuilt Duelist runs DECKLESS — no creed pick, no module
	# floor, no rig board (the deck re-lands per-verdict after Bill's base playtest). The
	# ceremony must SKIP the tank seat and continue straight through.
	hud._seat_key = "tank"
	hud._d.run.creed = ""
	hud._show_creed_pick(func(): flags.skip = true)
	assert(flags.skip and hud._screen != "creed", "the DECKLESS Duelist skips the creed pick (tank-v2)")
	hud._seat_key = "blade"
	print("TEMPO framework: creed pick + module pick + kit inject ok; the deckless Duelist skips the ceremony")

	# WELL REWORK framework: the healer seat (class "well") snaps onto the SAME ceremony,
	# with PER-SPEC creed pools + the deck folding into the WellKit (MENDER-PLAN §2-5).
	hud._seat_key = "healer"
	hud._aspect = "brim"
	hud._sync_healer_cls()
	assert(hud._healer_cls == "well", "brim aspect selects the well healer class")
	hud._d.run = hud._make_run()
	assert(hud._d.run.char_class == "well", "healer run should be well")
	var wflags := {"creed": false, "mod": false}
	hud._show_creed_pick(func(): wflags.creed = true)
	assert(hud._screen == "creed" and not wflags.creed, "well creed pick should SHOW and wait")
	hud._pick_creed("brink", func(): wflags.creed = true)
	assert(hud._d.run.creed == "brink" and wflags.creed, "picking a well creed sets run.creed + continues")
	hud._show_module_pick(func(): wflags.mod = true)
	assert(hud._screen == "module" and not wflags.mod, "well module pick should SHOW and wait")
	hud._pick_module("reservoir", func(): wflags.mod = true)
	assert(hud._d.run.modules.has("reservoir") and wflags.mod, "picking a well module sets run.modules + continues")
	hud._d.run.rig = {"when": "sweet_pour", "then": "gleam"}
	var wseat: Seat = RaidContent._healer_seat("well", "brim")
	hud._inject_boons(wseat)
	var wk := wseat.kit as WellKit
	assert(wk.creed_id == "brink" and wk.modules.has("reservoir") and String(wk.rig.get("when", "")) == "sweet_pour",
		"creed + module + rig all fold into the well kit")
	hud._seat_key = "blade"
	print("WELL framework: per-spec creed + module + rig fold into the well kit ok")

	# TEMPO §5 — the Combo rig: the wire board builds, a WHEN+THEN pick enables it, it folds in.
	hud._d.run.rig = {}
	flags.skip = false
	hud._show_rig_wire(func(): flags.skip = true)
	assert(hud._screen == "rig" and not flags.skip and hud._rig_confirm != null and hud._rig_confirm.disabled,
		"rig wire shows + waits, confirm disabled until both picked")
	hud._rig_on_when(true, "coup")
	hud._rig_on_then(true, "overcharge")
	assert(not hud._rig_confirm.disabled and hud._rig_w == "coup" and hud._rig_t == "overcharge",
		"picking a WHEN + THEN enables WIRE IT")
	hud._d.run.rig = {"when": "coup", "then": "overcharge"}   # simulate the confirm
	var bseat2: Seat = RaidContent._blade_seat("twinfang", "tempo")
	hud._inject_boons(bseat2)
	assert((bseat2.kit as TwinfangKit).rig.get("when", "") == "coup", "the rig folds into the blade kit")
	print("TEMPO rig: %s — board builds, pick enables, folds into kit" % TwinfangRig.describe("coup", "overcharge"))

	# THE RECKONING — the per-fight recap builds off a driven fight's damage meter.
	hud._launch("blade", "tempo")
	var rs: CombatState = hud._ctrl.state
	_drive(rs, "blade")
	var big: Dictionary = hud._biggest_hit(rs)
	flags.skip = false
	hud._show_fight_recap(func(): flags.skip = true)
	assert(hud._screen == "recap" and not flags.skip, "fight recap should SHOW + wait for CONTINUE")
	print("THE RECKONING: recap builds; biggest hit amt=%d src=%s" % [
		int(big.get("amt", 0)), str(big.get("src", "-"))])

	# the healer seat's TWO classes: the Well (brim/draw) + Bloomweaver
	# (wildgrove/thornveil) — _launch infers the class from aspect.
	for combo in [["tank", "warden"], ["tank", "juggernaut"], ["blade", "venomancer"],
			["blade", "tempo"], ["caster", "brew"], ["caster", "cask"],
			["healer", "wildgrove"], ["healer", "thornveil"],
			["healer", "brim"], ["healer", "draw"]]:
		hud._launch(combo[0], combo[1])
		var s: CombatState = hud._ctrl.state
		var ticks := _drive(s, String(combo[0]))
		print("%-6s %-11s ok  loadout=%s ticks=%d boss_hp=%d over=%s" % [
			combo[0], combo[1], str(hud._loadout), ticks, int(s.boss.hp), str(s.over)])
		# pause menu + class codex: opens (freezes the fight), builds, resumes clean
		hud._toggle_pause()
		var codex_ok: bool = hud._pause != null and hud._pause.get_child_count() > 0 and hud._ctrl.paused
		hud._resume_pause()
		assert(codex_ok and hud._pause == null and not hud._ctrl.paused, "pause+codex round-trip failed")
		print("   pause+codex: built+frozen+resumed ok")

	# the Machine Seals (II-IV): launch each, drive live combat, and force-render
	# an ADD PHASE on the finale (bar/dial swap + banners + stage body swap)
	for seal in ["mistral", "gemini", "mythos"]:
		hud._launch("tank", "warden", seal)
		var ss: CombatState = hud._ctrl.state
		var ticks2 := _drive(ss, "tank")
		print("seal %-8s ok  enc=%s ticks=%d boss_hp=%d" % [
			seal, String(ss.encounter.id), ticks2, int(ss.boss.hp)])
	hud._launch("tank", "warden", "mythos")     # fresh combat screen for the add pass
	hud._handle_event({"t": "add_spawn", "id": "opus", "name": "OPUS SUBAGENT"})
	hud._handle_event({"t": "add_down", "id": "opus", "name": "OPUS SUBAGENT"})
	print("add banners: ok")
	var sm: CombatState = hud._ctrl.state       # force the SONNET wave live
	CombatCore.damage_boss(sm, sm.seats[0], sm.boss.hp - sm.boss.hp_max * 0.60)
	for i in 240:
		if sm.over:
			break
		hud._ctrl._process(1.0 / 30.0)
		hud._process(1.0 / 30.0)
		if sm.boss.add_i >= 0:
			break
	if sm.boss.add_i >= 0 and not sm.over:
		hud._process(1.0 / 30.0)                # one render with the add on the plate
		print("mythos add phase live: add_i=%d bar='%s' ok" % [sm.boss.add_i, hud._bar.boss_name])
	else:
		print("mythos add phase: skipped (over=%s) — banners still exercised" % str(sm.over))

	# COMMANDER: the pre-descent PARTY screen — assemble the AI raiders (aspect ⇄,
	# healer class toggle), DESCEND spawns their boon runs, and the post-fight
	# REFORGE chains one draft per seat (yours first) on the shared ⏣ bank.
	hud._seat_key = "tank"
	hud._aspect = "warden"
	hud._d.party = {}
	shell._show_party_setup()
	assert(String(shell._screen) == "party", "party screen didn't build (shell screen, P3.2b)")
	var cpa := _press(hud, "ASPECT")          # SOME AI row's toggle (row order is a UI detail)
	var cpc := _press(hud, "◈")               # healer class toggle: Well ⇄ Bloomweaver
	assert(cpa and cpc, "party toggle buttons missing")
	assert(String(hud._d.party["healer"]["cls"]) == "bloomweaver",
		"healer class toggle (1st) should reach Bloomweaver: %s" % str(hud._d.party))
	_press(hud, "◈")                          # second press -> back to the Well
	assert(String(hud._d.party["healer"]["cls"]) == "well",
		"healer class toggle (2nd) should return to Well: %s" % str(hud._d.party))
	hud._d.party["blade"]["aspect"] = "tempo"   # command the blade directly (probe-style)
	print("party setup: ok toggles=%s/%s party=%s" % [str(cpa), str(cpc), str(hud._d.party)])
	var cpd := _press(hud, "⚔")               # DESCEND
	if hud._d.map == null:   # reworked player: descent opens on the creed ceremony — complete it
		hud._d.run.creed = hud._fw_creed_ids(hud._fw())[0]
		hud._build_floor()
	assert(cpd and hud._d.map != null and hud._d.ai_runs.size() == 3,
		"DESCEND didn't start the commanded descent")
	print("commander descent: ok blade=%s healer=%s" % [
		String((hud._d.ai_runs["blade"] as RunState).aspect),
		String((hud._d.ai_runs["healer"] as RunState).char_class)])
	if hud._d.run.rig.is_empty():   # reworked player: pre-wire the rig so the chain skips the rig-wire
		hud._d.run.rig = {"when": hud._fw_rig_when_table(hud._fw()).keys()[0], "then": hud._fw_rig_then_table(hud._fw()).keys()[0]}
	hud._show_boon_draft(hud._show_map)       # the chain: you, then each AI raider
	var ctakes := 0
	while String(hud._screen) == "draft" and ctakes < 8:
		var cds = _find_draft(hud)
		if cds == null:
			break
		cds.emit_signal("boon_taken", cds._offers[0])
		ctakes += 1
	assert(String(hud._screen) == "map", "draft chain didn't hand back to the map")
	print("commander REFORGE chain: ok drafts=%d ai_boons=%d/%d/%d" % [ctakes,
		(hud._d.ai_runs["blade"] as RunState).boons.size(),
		(hud._d.ai_runs["caster"] as RunState).boons.size(),
		(hud._d.ai_runs["healer"] as RunState).boons.size()])
	hud._d.party = {}                            # back to the verified default comp

	# Topology raid floor (MAP-3a): map screen -> entry fight -> back on the map,
	# node fx (raid patch, refuel, wound repair), the privilege-elevated screen
	hud._seat_key = "tank"
	hud._aspect = "duelist"
	hud._start_map_run()
	if hud._d.map == null:   # the reworked Duelist tank opens on the creed ceremony — complete it
		hud._d.run.creed = hud._fw_creed_ids(hud._fw())[0]
		hud._build_floor()
	print("raid map screen: ok (nodes=%d screen=%s)" % [hud._d.map.nodes.size(), hud._screen])
	hud._enter_node(hud._d.map.entry_id)
	# GEAR-2: the boss's Ledger page interposes — swear the first oath, then pull
	print("ledger offer: screen=%s" % hud._screen)
	var psw := _press(hud, "SWEAR")
	print("oath sworn: ok=%s -> screen=%s sworn=%s" % [
		str(psw), hud._screen, str(not hud._d.sworn.is_empty())])
	var sgate: CombatState = hud._ctrl.state
	print("entry fight: enc=%s screen=%s" % [String(sgate.encounter.id), hud._screen])
	CombatCore.damage_boss(sgate, sgate.seats[0], sgate.boss.hp)   # burst-win the entry pull
	for i in 30:
		hud._ctrl._process(1.0 / 30.0)
		hud._process(1.0 / 30.0)
		if hud._screen != "combat":
			break
	# GEAR-1: the entry kill is a FIRST KILL -> the drop ceremony interposes
	print("entry fight won -> drop ceremony: screen=%s" % hud._screen)
	if hud._screen == "drop":
		var pe := _press(hud, "EQUIP")
		print("drop EQUIP: ok=%s -> screen=%s gear=%s unlocks=%s" % [
			str(pe), hud._screen, str(hud._d.gear), str(hud._d.gear_unlocks)])
	print("back on map: fracs=%s mana=%.2f" % [str(hud._d.fracs), hud._d.mana])
	hud._d.wounds[0] = 0.2
	hud._apply_map_fx({"heal": 0.1, "mana": 1.0, "repair": true, "patch": true})
	print("map fx (heal/patch/refuel/repair): ok wounds=%s" % str(hud._d.wounds))

	# GEAR-1 (Curios): ceremony paths — EQUIP an active, SCRAP pays ⏣, the paste
	# button repairs wounds from the map, and curios ride the next pull's seat
	hud._show_drop("cooling_paste", true, hud._show_map)
	var p1 := _press(hud, "EQUIP")
	print("ceremony EQUIP active: ok=%s gear=%s charges=%s" % [
		str(p1), str(hud._d.gear), str(hud._d.gear_charges)])
	hud._show_drop("swan_song", false, hud._show_map)
	var p2 := _press(hud, "SCRAP")
	print("ceremony SCRAP: ok=%s tokens=%d screen=%s" % [str(p2), hud._tokens_now(), hud._screen])
	hud._d.wounds[0] = 0.2
	hud._show_map()
	var p3 := _press(hud, "USE COOLING PASTE")
	print("cooling paste: ok=%s wounds=%s charges=%s" % [
		str(p3), str(hud._d.wounds), str(hud._d.gear_charges)])

	# ARMORY-UI: the YOUR SET modal opens off the doll, swallows Esc, and closes;
	# the drop ceremony builds its EQUIPPED-comparison cards alongside the drop
	hud._d.taken_boons = [{"id": "propSwift", "title": "Swiftguard", "rarity": "haiku",
		"tags": ["guard"], "desc": "Guard cooldown -20%."}]
	hud._show_map()
	hud._open_armor_modal()
	var modal_open: bool = hud._armor_modal != null
	hud._close_armor_modal()
	var modal_closed: bool = hud._armor_modal == null
	print("armor modal: open=%s closed=%s" % [str(modal_open), str(modal_closed)])
	hud._show_drop("swan_song", false, hud._show_map)
	var have_equipped := false
	var stack: Array = [hud._ui]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is RelicCard and String(nd.ribbon_text) != "":
			have_equipped = true
		for c2 in nd.get_children():
			stack.append(c2)
	print("drop comparison: equipped cards present=%s" % str(have_equipped))
	var pcmp := _press(hud, "SCRAP")
	print("drop comparison scrapped on: ok=%s" % str(pcmp))

	# GEAR-2: a KEPT oath — resolved on the last fight's final state; the purse and
	# the fresh row unlock ride THIS kill's roll (sonnet floor -> the new row drops)
	hud._d.sworn = {"row": "oath", "item": "grace_period", "sev": 2,
		"deed": {"kind": "zero_deaths"}, "deed_text": "zero raider deaths", "boss": "riftmaw"}
	hud._resolve_oath(hud._ctrl.state, hud._ctrl.player(), true)
	var tok0: int = hud._tokens_now()
	hud._after_drop("riftmaw", hud._show_map)
	print("oath KEPT: tokens %d->%d row_unlocked=%s screen=%s" % [tok0, hud._tokens_now(),
		str((hud._d.gear_unlocks.get("riftmaw", []) as Array).has("grace_period")), hud._screen])
	if hud._screen == "drop":
		var pk := _press(hud, "SCRAP")
		print("kept-oath drop scrapped: ok=%s tokens=%d" % [str(pk), hud._tokens_now()])

	# (the personal-GATE walk died 2026-07-10 — THE PURGE: gates + exam bosses deleted)
	hud._seat_key = "tank"
	hud._aspect = "warden"
	# MAP-3c floor progression screens (replaces the old single _show_map_cleared):
	hud._d.floor_i = 0
	hud._show_floor_cleared()          # inter-floor elevation (Ring 3 -> descend to Ring 2)
	print("floor-cleared (privilege-elevated) screen: ok")
	hud._show_campaign_cleared()       # last Seal down -> Realm 1 cleared
	print("campaign-cleared (root access) screen: ok")

	# juice handlers across every class-specific event, on the healer build
	var s2: CombatState = hud._ctrl.state
	for ev in [
		{"t": "negate", "player": true, "size": 3, "feint": false},
		{"t": "hurt", "player": true, "seat": s2.seats[3], "amt": 40, "size": 0},
		{"t": "hurt", "player": false, "seat": s2.seats[0], "amt": 80, "size": 2},
		{"t": "heal", "seat": s2.seats[1], "amt": 40, "over": 5},
		{"t": "debuff", "seat": s2.seats[2], "id": "riftrot"},
		{"t": "boss_hit", "amt": 120, "seat": s2.seats[2]},
		{"t": "boss_heal", "amt": 300},
		{"t": "staggered", "was_heal": true},
		{"t": "interrupt", "player": false, "clean": true, "was_heal": false},
		{"t": "taunt", "player": false, "seat": s2.seats[0]},
		{"t": "threat_drop", "player": true, "seat": s2.seats[3]},
		{"t": "strike_graded", "player": true, "grade": StrikeRes.Grade.PERFECT},
		{"t": "dodge_whiff", "player": true},
		{"t": "strike", "player": true, "result": "perfect"},
		{"t": "perfect", "player": true},
		{"t": "flow_lost", "player": true},
		{"t": "rupture", "player": true},
		{"t": "coup", "player": true},
		{"t": "kick_whiff", "player": true},
		{"t": "int_whiff", "player": true},
		{"t": "overload", "player": true},
		{"t": "quietus", "player": true},
		{"t": "silence", "player": true},
		{"t": "empower", "amt": 0.1},
		{"t": "pushback", "player": true},
		{"t": "cast_cancelled", "id": "mend"},
		# Bloomweaver (second healer) events
		{"t": "bloom", "seat": s2.seats[0], "amt": 60},
		{"t": "warded", "seat": s2.seats[1]},
		{"t": "saprot", "seat": s2.seats[2]},
		{"t": "wilt", "seat": s2.seats[3], "amt": 30},
		{"t": "perfect_ward", "seat": s2.seats[0]},
		{"t": "lifesurge"},
		{"t": "wildbloom", "n": 3},
		{"t": "briarheart"},
		{"t": "thorn_snap", "player": true, "charge": 3},
		{"t": "thorn_break", "player": true},
		# Alchemist (the Brew) events
		{"t": "brew_pour", "player": true, "side": "venom", "grade": "potent", "dose": 8},
		{"t": "brew_pour", "player": true, "side": "rot", "grade": "spoiled", "dose": 1},
		{"t": "brew_pour", "player": true, "side": "venom", "grade": "hot", "dose": 9},
		{"t": "brew_pour", "player": true, "side": "rot", "grade": "fizzle", "dose": 0},
		{"t": "brew_rupture", "player": true, "amt": 320, "peak": true},
		{"t": "brew_rupture", "player": false, "amt": 120, "peak": false},
		{"t": "brew_dud", "player": true},
	]:
		hud._handle_event(ev)
	print("juice handlers (all classes): ok")

	hud._launch("tank", "warden", "mythos")   # a Seal state -> exercises the QUIPS path

	# the raid panel is movable: drag its header +60,+40 -> panel moves + position
	# persists to user://rift_ui.cfg; double-click resets and erases the save
	var col: VBoxContainer = hud._raid_col
	assert(col != null)
	var before := Vector2(col.offset_left, col.offset_top)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = col.global_position + Vector2(30, 8)
	hud._raid_col_input(press)
	var move := InputEventMouseMotion.new()
	move.global_position = press.global_position + Vector2(60, 40)
	hud._raid_col_input(move)
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.global_position = move.global_position
	hud._raid_col_input(rel)
	var after := Vector2(col.offset_left, col.offset_top)
	assert(after.distance_to(before + Vector2(60, 40)) < 2.0)
	var cfg_chk := ConfigFile.new()
	assert(cfg_chk.load("user://rift_ui.cfg") == OK
		and cfg_chk.has_section_key("raid_frames", "col_std"))
	var dbl := InputEventMouseButton.new()
	dbl.button_index = MOUSE_BUTTON_LEFT
	dbl.pressed = true
	dbl.double_click = true
	hud._raid_col_input(dbl)
	assert(Vector2(col.offset_left, col.offset_top).distance_to(before) < 2.0)
	print("raid panel drag + persist + reset: ok")

	hud._show_end(true)
	hud._show_end(false)
	print("end screens (with Seal quips): ok")
	shell._show_home()
	shell._show_class_select()
	print("reselect: ok")

	# online screens build (R2): connect form + a synthetic lobby (with the v2
	# Seal row — host sees the SEAL ⇄ toggle), no live server
	hud._show_online()
	hud._room = {"code": "TEST", "phase": "lobby", "host": 1, "enc": "mythos", "players": [
		{"id": 1, "name": "Ava", "seat": "tank", "aspect": "warden", "ready": true},
		{"id": 2, "name": "Bo", "seat": "", "aspect": "", "ready": false},
	]}
	hud._show_lobby()
	print("online connect + lobby screens (Seal row): ok")

	print("RAID UI SMOKE: ALL OK")
	quit()
	return true

## Scripted human input per seat so every band's input surface gets exercised.
func _drive(s: CombatState, seat_key: String) -> int:
	for i in 600:
		var p: Seat = hud._ctrl.player()
		if p != null and p.alive() and (i % 8) == 0 and not s.over:
			var obs := CombatCore.observe(s, p)
			var tg: Dictionary = obs.get("telegraph", {})
			match seat_key:
				"tank":
					if bool(obs.get("charging", false)):
						# §11.1 THE CHARGED PARRY: ride the hold, release on the beat (the 8-tick
						# poll cadence lands the release inside the parry zone at <= 0.15s out)
						if tg.is_empty() or float(tg.get("remaining", 9.0)) <= 0.15:
							hud._ctrl.human({"type": "defense_release"})
					elif bool(obs.get("charge_eligible", false)) and bool(obs.get("defense_ready", false)):
						hud._ctrl.human({"type": "defense"})   # commit the gather EARLY (the full hold)
					elif not bool(obs.get("aggro_me", true)) and s.tick >= int(p.cooldowns.get("challenge", 0)):
						hud._ctrl.human({"type": "ability", "id": "challenge"})
					elif not tg.is_empty() and bool(tg.get("defensible", false)) \
							and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)) \
							and float(tg.get("remaining", 9.0)) <= 0.3:
						hud._ctrl.human({"type": "defense"})
					elif bool(obs.get("gcd_ready", false)):
						hud._ctrl.human({"type": "ability", "id": ("rampage" if float(obs.get("rage", 0.0)) >= 40.0 else "cleave")})
				"blade":
					if not tg.is_empty() and bool(tg.get("defensible", false)) \
							and bool(tg.get("targets_me", false)) and bool(obs.get("defense_ready", false)) \
							and float(tg.get("remaining", 9.0)) <= 0.4:
						hud._ctrl.human({"type": "defense"})
					elif int(obs.get("since_strike", 0)) >= int(obs.get("perfect_lo", 18)):
						hud._ctrl.human({"type": "ability", "id": "strike"})
				"caster":
					if hud._caster_cls == "alchemist":
						# the Brew: hold → sweet-band pour, feed the lower side, rupture ripe
						var chg := String(obs.get("charging", ""))
						if chg != "":
							if float(obs.get("charge", 0.0)) >= float(obs.get("sweet_lo", 0.7)):
								hud._ctrl.human({"type": "ability", "id": "pour"})
						elif float(obs.get("ripe_glow", 0.0)) >= 0.6:
							hud._ctrl.human({"type": "ability", "id": "rupture"})
						else:
							hud._ctrl.human({"type": "ability",
								"id": ("brew_venom" if float(obs.get("venom", 0.0)) <= float(obs.get("rot", 0.0)) else "brew_rot")})
					elif not tg.is_empty() and bool(tg.get("interruptible", false)) \
							and bool(obs.get("defense_ready", false)):
						hud._ctrl.human({"type": "defense"})
					elif (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
						hud._ctrl.human({"type": "ability",
							"id": ("fracture" if float(obs.get("focus", 0.0)) >= 26.0 else "bolt")})
				"healer":
					# hover the tank and keep it topped; exercise click-cast gating too
					hud._hover_seat = s.seats[0]
					if hud._healer_cls == "bloomweaver":
						# Bloomweaver: plant/bloom Growth, ward (click-cast), lifesurge, signature
						if (i % 48) == 0:
							hud._cast("lifesurge")
						elif (i % 40) == 0:
							hud._band.key_pressed(KEY_7)         # the aspect signature (band-routed since P4)
						elif (i % 16) == 0:
							hud._cast_on(s.seats[0], "bark")     # ward the tank (chord path)
						elif (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
							hud._cast("growth")
					elif (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true)):
						if (i % 24) == 0:
							hud._cast_on(s.seats[0], "flash")
						else:
							hud._cast("mend")
		hud._ctrl._process(1.0 / 30.0)
		hud._process(1.0 / 30.0)
		if s.over:
			return s.tick
	return s.tick

## GEAR-1: find + press the first Button under the HUD whose text starts with
## `prefix` (drives the drop-ceremony / cooling-paste choices like a click).
func _press(_h: Node, prefix: String) -> bool:
	var stack: Array = [shell]   # shell-wide: buttons live on EITHER surface (P3.2b)
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and String((n as Button).text).begins_with(prefix):
			(n as Button).pressed.emit()
			return true
		for c in n.get_children():
			stack.append(c)
	return false

## The one LIVE DraftScreen (skips screens _clear() queue-freed this frame — the
## COMMANDER chain builds the next seat's screen in the same frame).
func _find_draft(_h: Node):
	var stack: Array = [shell]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is DraftScreen and not n.is_queued_for_deletion():
			return n
		for c in n.get_children():
			stack.append(c)
	return null
