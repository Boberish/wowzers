## Probe: DEV · GENERATED SETUPS (DevSetups + raid_hud._launch_dev_gen). Proves:
##   A. determinism — the same (class, aspect, anchor, boss, seed) generates the
##      IDENTICAL build twice (creed/rig/modules/transform/boons/tokens/ai boons)
##   B. depth scaling — a deeper Seal means a bigger build (fights and boons grow
##      boss 0 → boss 3), and milestones land on their floors (module @1, transform @2)
##   C. the anchor — a module anchor (the Well's ⭐Vigil) is honored at depth
##   D. every class × every Seal generates without error (Duelist stays deckless)
##   E. the launch — _launch_dev_gen lands in combat with the generated boons/creed
##      folded into the human seat's kit and the AI runs riding the spec
##   godot --headless --path godot --script res://sim/dev_setup_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0

func _ck(cond: bool, label: String) -> void:
	if not cond:
		fails += 1
	print("  %s %s" % [("OK  " if cond else "FAIL"), label])

func _party_for(seat: String) -> Dictionary:
	var out := {}
	for key in RaidNet.SEAT_KEYS:
		if key == seat:
			continue
		var cls := String(RaidNet.SEAT_CLASS.get(key, "duelist"))
		out[key] = {"cls": cls, "aspect": RaidNet.default_aspect(key, cls)}
	return out

## A stable fingerprint of a generated setup (sorted keys — dict order independent).
func _fp(gen: Dictionary) -> String:
	var run: RunState = gen["run"]
	var boons: Array = run.boons.keys()
	boons.sort()
	var mods: Array = run.modules.keys()
	mods.sort()
	var ai_bits: Array = []
	for key in gen["ai"]:
		var ab: Array = (gen["ai"][key] as RunState).boons.keys()
		ab.sort()
		ai_bits.append("%s=%s" % [key, ",".join(ab)])
	ai_bits.sort()
	return "c=%s|m=%s|rig=%s>%s|tf=%s|b=%s|t=%d|g=%s|ai=%s" % [run.creed, ",".join(mods),
		String(run.rig.get("when", "")), String(run.rig.get("then", "")), run.transform,
		",".join(boons), run.tokens, ",".join(gen["gear"]), "|".join(ai_bits)]

func _process(_delta: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step != 1:
		return false
	print("dev_setup_probe:")

	# A. determinism — same inputs, identical build
	var party := _party_for("healer")
	var g1 := DevSetups.generate("well", "draw", "", 2, 424242, party)
	var g2 := DevSetups.generate("well", "draw", "", 2, 424242, party)
	_ck(_fp(g1) == _fp(g2), "A determinism: same seed -> identical setup")
	var g3 := DevSetups.generate("well", "draw", "", 2, 424243, party)
	_ck(_fp(g1) != _fp(g3), "A variance: a different seed -> a different setup")

	# B. depth scaling — deeper Seal, bigger build; milestones land on their floors
	var bparty := _party_for("blade")
	var prev_fights := -1
	var prev_boons := -1
	var mono := true
	var boons3 := 0
	for bi in 4:
		var g := DevSetups.generate("twinfang", "tempo", "", bi, 777001, bparty)
		var run: RunState = g["run"]
		if int(g["fights"]) <= prev_fights:
			mono = false
		prev_fights = int(g["fights"])
		if run.boons.size() < prev_boons:      # pool can exhaust late — never shrinks
			mono = false
		prev_boons = run.boons.size()
		boons3 = run.boons.size()
		if bi == 0:
			_ck(run.creed != "" and not run.rig.is_empty(), "B boss0: creed sworn + rig wired")
			_ck(run.modules.is_empty() and run.transform == "", "B boss0: no module/transform yet")
		if bi == 2:
			_ck(run.modules.size() == 1, "B boss2: the Floor-1 module is installed")
			_ck(run.transform != "", "B boss2: the Floor-2 transform is picked (twinfang)")
	_ck(mono, "B scaling: fights/boons grow with Seal depth")
	var g0 := DevSetups.generate("twinfang", "tempo", "", 0, 777001, bparty)
	_ck((g0["run"] as RunState).boons.size() < boons3, "B scaling: boss0 build < boss3 build")

	# C. the anchor — ⭐Vigil (Draw-only) honored at depth
	var ga := DevSetups.generate("well", "draw", "vigil", 3, 5150, party)
	_ck((ga["run"] as RunState).modules.has("vigil"), "C anchor: the Vigil module is installed")

	# D. every class × every Seal generates clean
	var combos := [["duelist", "duelist", "tank"], ["twinfang", "fermata", "blade"],
		["alchemist", "cask", "caster"], ["well", "brim", "healer"],
		["bloomweaver", "wildgrove", "healer"]]
	var all_ok := true
	for c in combos:
		for bi in 4:
			var g := DevSetups.generate(String(c[0]), String(c[1]), "", bi, 90210 + bi, _party_for(String(c[2])))
			if g.is_empty() or String(g["title"]) == "" or String(g["blurb"]) == "":
				all_ok = false
	_ck(all_ok, "D every class x every Seal generates (title + blurb present)")
	var gd := DevSetups.generate("duelist", "duelist", "", 3, 31337, _party_for("tank"))
	_ck((gd["run"] as RunState).boons.is_empty(), "D the Duelist stays deckless (no boons)")
	var gb := DevSetups.generate("bloomweaver", "wildgrove", "", 3, 31338, _party_for("healer"))
	_ck((gb["run"] as RunState).boons.size() > 0, "D the Bloomweaver drafts boons (catalog, no framework)")

	# E. the launch — the generated run rides into a real fight
	var g_launch := DevSetups.generate("well", "draw", "vigil", 1, 11111, party)
	hud._launch_dev_gen("well", "draw", "mistral", g_launch)
	_ck(hud._screen == "combat", "E launch: lands in combat")
	var st = hud._ctrl.state
	_ck(st != null and String(st.encounter.id) == "mistral", "E launch: the right Seal on the field")
	if st != null:
		var seat = st.seats[RaidNet.SEAT_KEYS.find("healer")]
		var lrun: RunState = g_launch["run"]
		_ck(seat.kit != null and seat.kit.boons == lrun.boons, "E launch: generated boons on the kit")
		_ck(String(seat.kit.creed_id) == lrun.creed and seat.kit.modules.has("vigil"),
			"E launch: creed + anchored module folded into the kit")
	_ck(hud._d.run == g_launch["run"] and hud._d.ai_runs.size() == 3,
		"E launch: the run + 3 AI runs seated on the director")

	print("dev_setup_probe: %s" % ("ALL OK" if fails == 0 else "%d FAIL(S)" % fails))
	quit(0 if fails == 0 else 1)
	return false
