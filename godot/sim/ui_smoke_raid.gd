## Headless smoke test for the RAID HUD (R1 v2 — any seat): instantiate the scene,
## then for EACH of the four playable seats build the combat screen, run ~30s of
## live raid with scripted human input, and exercise the juice handlers.
##
##   godot --headless --path godot --script res://sim/ui_smoke_raid.gd
extends SceneTree

var hud: Control
var done := false

func _process(_delta: float) -> bool:
	if done:
		return true
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	done = true

	print("select screen: ok (ui=", hud._ui != null, " ctrl=", hud._ctrl != null, ")")

	for seat_key in ["tank", "blade", "caster", "healer"]:
		hud._show_aspect_pick(seat_key)
	print("aspect-pick screens (x4): ok")

	# the healer seat's TWO classes: Mender (tidecaller/brinkwarden) + the second
	# healer Bloomweaver (wildgrove/thornveil) — _launch infers the class from aspect.
	for combo in [["tank", "warden"], ["tank", "juggernaut"], ["blade", "venomancer"],
			["blade", "tempo"], ["caster", "disruptor"], ["caster", "silencer"],
			["healer", "tidecaller"], ["healer", "brinkwarden"],
			["healer", "wildgrove"], ["healer", "thornveil"]]:
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

	# Topology raid floor (MAP-3a): map screen -> gate fight -> back on the map,
	# node fx (raid patch, refuel, wound repair), the privilege-elevated screen
	hud._seat_key = "tank"
	hud._aspect = "warden"
	hud._start_map_run()
	print("raid map screen: ok (nodes=%d screen=%s)" % [hud._map.nodes.size(), hud._screen])
	hud._enter_node(hud._map.entry_id)
	# GEAR-2: the boss's Ledger page interposes — swear the first oath, then pull
	print("ledger offer: screen=%s" % hud._screen)
	var psw := _press(hud, "SWEAR")
	print("oath sworn: ok=%s -> screen=%s sworn=%s" % [
		str(psw), hud._screen, str(not hud._sworn.is_empty())])
	var sgate: CombatState = hud._ctrl.state
	print("gate fight: enc=%s screen=%s" % [String(sgate.encounter.id), hud._screen])
	CombatCore.damage_boss(sgate, sgate.seats[0], sgate.boss.hp)   # burst-win the gate
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
			str(pe), hud._screen, str(hud._map_gear), str(hud._gear_unlocks)])
	print("back on map: fracs=%s mana=%.2f" % [str(hud._map_fracs), hud._map_mana])
	hud._map_wounds[0] = 0.2
	hud._apply_map_fx({"heal": 0.1, "mana": 1.0, "repair": true, "patch": true})
	print("map fx (heal/patch/refuel/repair): ok wounds=%s" % str(hud._map_wounds))

	# GEAR-1 (Curios): ceremony paths — EQUIP an active, SCRAP pays ⏣, the paste
	# button repairs wounds from the map, and curios ride the next pull's seat
	hud._show_drop("cooling_paste", true, hud._show_map)
	var p1 := _press(hud, "EQUIP")
	print("ceremony EQUIP active: ok=%s gear=%s charges=%s" % [
		str(p1), str(hud._map_gear), str(hud._map_gear_charges)])
	hud._show_drop("swan_song", false, hud._show_map)
	var p2 := _press(hud, "SCRAP")
	print("ceremony SCRAP: ok=%s tokens=%d screen=%s" % [str(p2), hud._tokens_now(), hud._screen])
	hud._map_wounds[0] = 0.2
	hud._show_map()
	var p3 := _press(hud, "USE COOLING PASTE")
	print("cooling paste: ok=%s wounds=%s charges=%s" % [
		str(p3), str(hud._map_wounds), str(hud._map_gear_charges)])

	# ARMORY-UI: the YOUR SET modal opens off the doll, swallows Esc, and closes;
	# the drop ceremony builds its EQUIPPED-comparison cards alongside the drop
	hud._taken_boons = [{"id": "propSwift", "title": "Swiftguard", "rarity": "haiku",
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
	hud._sworn = {"row": "oath", "item": "grace_period", "sev": 2,
		"deed": {"kind": "zero_deaths"}, "deed_text": "zero raider deaths", "boss": "riftmaw"}
	hud._resolve_oath(hud._ctrl.state, hud._ctrl.player(), true)
	var tok0: int = hud._tokens_now()
	hud._after_drop("riftmaw", hud._show_map)
	print("oath KEPT: tokens %d->%d row_unlocked=%s screen=%s" % [tok0, hud._tokens_now(),
		str((hud._gear_unlocks.get("riftmaw", []) as Array).has("grace_period")), hud._screen])
	if hud._screen == "drop":
		var pk := _press(hud, "SCRAP")
		print("kept-oath drop scrapped: ok=%s tokens=%d" % [str(pk), hud._tokens_now()])

	# Tier-1 PERSONAL GATE (§GAME SHAPE): intro panel -> exam fight -> result ->
	# map; a LOST gate = force-reboot (wound) and the run CONTINUES
	var gid := -1
	for nd in hud._map.nodes:
		if String(nd["kind"]) == RunMap.KIND_GATE:
			gid = int(nd["id"])
	print("gate node present: %s (id=%d)" % [str(gid >= 0), gid])
	hud._enter_node(gid)
	var intro_ok: bool = hud._screen == "mapstop"
	print("gate intro panel: ok=%s screen=%s" % [str(intro_ok), hud._screen])
	hud._launch_gate_fight()                       # what STEP THROUGH ALONE does
	var sx: CombatState = hud._ctrl.state
	print("gate exam fight: enc=%s boss='%s' seats=%d gate_live=%s" % [
		String(sx.encounter.id), String(sx.encounter.name), sx.seats.size(), str(hud._gate_live)])
	print("exam seat armed with curios: %s" % str(sx.seats[0].gear))
	CombatCore.damage_boss(sx, sx.seats[0], sx.boss.hp)      # burst-win the exam
	for i in 30:
		hud._ctrl._process(1.0 / 30.0)
		hud._process(1.0 / 30.0)
		if hud._screen != "combat":
			break
	print("gate won -> result panel: screen=%s frac[tank]=%.2f" % [
		hud._screen, hud._map_fracs[0]])
	hud._launch_gate_fight()                       # loss path: the exam kills you
	var sl: CombatState = hud._ctrl.state
	sl.seats[0].hp = 0.0
	for i in 30:
		hud._ctrl._process(1.0 / 30.0)
		hud._process(1.0 / 30.0)
		if hud._screen != "combat":
			break
	print("gate LOST -> rebooted through: screen=%s frac=%.2f wound=%.2f map_alive=%s" % [
		hud._screen, hud._map_fracs[0], hud._map_wounds[0], str(hud._map != null)])
	# every other seat's exam builds its band + fights live for a moment
	for gseat in ["blade", "caster", "healer"]:
		hud._seat_key = gseat
		hud._aspect = String((hud.ASPECTS[gseat][0] as Dictionary)["id"])
		hud._launch_gate_fight()
		var gs: CombatState = hud._ctrl.state
		for i in 60:
			hud._ctrl._process(1.0 / 30.0)
			hud._process(1.0 / 30.0)
		print("gate exam %-6s ok  enc=%s boss='%s' seats=%d" % [
			gseat, String(gs.encounter.id), String(gs.encounter.name), gs.seats.size()])
	hud._seat_key = "tank"
	hud._aspect = "warden"
	# MAP-3c floor progression screens (replaces the old single _show_map_cleared):
	hud._floor = 0
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
	]:
		hud._handle_event(ev)
	print("juice handlers (all classes): ok")

	hud._launch("tank", "warden", "mythos")   # a Seal state -> exercises the QUIPS path
	hud._show_end(true)
	hud._show_end(false)
	print("end screens (with Seal quips): ok")
	hud._show_select("healer")
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
					if not bool(obs.get("aggro_me", true)) and s.tick >= int(p.cooldowns.get("challenge", 0)):
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
					if not tg.is_empty() and bool(tg.get("interruptible", false)) \
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
							hud._bloomweaver_key(KEY_7)          # the aspect signature
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
func _press(hud: Node, prefix: String) -> bool:
	var stack: Array = [hud._ui]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and String((n as Button).text).begins_with(prefix):
			(n as Button).pressed.emit()
			return true
		for c in n.get_children():
			stack.append(c)
	return false
