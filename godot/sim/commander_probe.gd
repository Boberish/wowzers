## Probe: COMMANDER mode — you build the WHOLE party (AI raiders' aspects, the
## healer's class, and every seat's boons; in combat the AI only drives the rotation).
## Proves:
##   A. byte-identity: the default party cfg produces the IDENTICAL spec the old
##      single-seat cfg did (no drafts, no overrides = the pre-commander game)
##   B. commanded AI aspects/classes + AI boons ride the built fight's kits
##   C. a commanded fight is DETERMINISTIC (same spec twice -> same checksum)
##   D. the post-fight REFORGE chain: your draft, then one per AI raider, on the
##      shared ⏣ bank — each AI run ends the chain one boon richer
##   godot --headless --path godot --script res://sim/commander_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0

func _ck(cond: bool, label: String) -> void:
	if not cond:
		fails += 1
	print("  %s %s" % [("OK  " if cond else "FAIL"), label])

func _find_draft(node: Node):
	# skip screens _clear() queue-freed this frame — the chain builds the next
	# DraftScreen synchronously, so exactly one is ever NOT queued for deletion
	if node is DraftScreen and not node.is_queued_for_deletion():
		return node
	for c in node.get_children():
		var r = _find_draft(c)
		if r != null:
			return r
	return null

func _process(_d: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step != 1:
		return false

	print("COMMANDER PROBE")
	# ---- A. byte-identity: full default party cfg == the old single-seat cfg's spec
	hud._seat_key = "tank"
	hud._aspect = "warden"
	hud._party = {}
	var sa: Dictionary = RaidNet.make_spec(4242, hud._party_seat_cfg(), "riftmaw")
	var sb: Dictionary = RaidNet.make_spec(4242, hud._human_seat_cfg(), "riftmaw")
	_ck(JSON.stringify(sa) == JSON.stringify(sb),
		"A: default party cfg -> spec identical to pre-commander")

	# ---- B. commanded aspects/classes/boons ride the built fight
	hud._party = {}
	hud._ensure_party()
	hud._party["blade"]["aspect"] = "tempo"
	hud._party["healer"] = {"cls": "bloomweaver", "aspect": "thornveil"}
	var br := RunState.start_twinfang("tempo", 77)
	var offers := Draft.roll_offers(br)
	Draft.take(br, offers[0])
	var spec: Dictionary = RaidNet.make_spec(4242, hud._party_seat_cfg(), "riftmaw",
		{}, {"blade": br.boons})
	var s: CombatState = RaidNet.build(spec, "tank")
	_ck(String(s.seats[1].kit.aspect) == "tempo",
		"B: commanded blade aspect rides its kit (tempo)")
	_ck(RaidNet.cls_of(s.seats[3]) == "bloomweaver"
		and String(s.seats[3].kit.aspect) == "thornveil",
		"B: commanded healer class+aspect ride (bloomweaver/thornveil)")
	_ck(not (s.seats[1].kit.boons as Dictionary).is_empty()
		and s.seats[1].kit.boons == br.boons,
		"B: the AI raider's boons folded into ITS kit (%d)" % s.seats[1].kit.boons.size())
	_ck(s.seats[0].policy == null and s.seats[1].policy != null
		and s.seats[2].policy != null and s.seats[3].policy != null,
		"B: human tank drives, the three commanded seats are AI")

	# ---- C. determinism: the same commanded spec twice -> the same checksum
	var s1: CombatState = RaidNet.build(spec, "tank")
	var s2: CombatState = RaidNet.build(spec, "tank")
	for i in 600:
		RaidNet.step(s1, [])
		RaidNet.step(s2, [])
	_ck(s1.checksum == s2.checksum and s1.tick == s2.tick,
		"C: commanded fight deterministic over 600 ticks (cs %d)" % s1.checksum)

	# ---- D. the REFORGE chain: you first, then each AI raider, shared bank
	hud._party = {}
	hud._ensure_party()
	hud._party["blade"]["aspect"] = "tempo"
	hud._start_map_run()
	_ck(hud._ai_runs.size() == 3, "D: descent spawned 3 AI boon runs")
	var rb: RunState = hud._ai_runs["blade"]
	_ck(String(rb.char_class) == "twinfang" and String(rb.aspect) == "tempo",
		"D: the AI run matches the command (twinfang/tempo)")
	hud._run.tokens = 5   # a banked pool to prove the mirror in/out
	var seen: Array = []
	hud._show_boon_draft(func(): seen.append("done"))
	var guard := 0
	while String(hud._screen) == "draft" and guard < 8:
		# the probe's `done` sentinel doesn't swap the screen like _show_map does —
		# stop once the chain has reported done
		if not seen.is_empty() and String(seen[seen.size() - 1]) == "done":
			break
		var ds = _find_draft(hud._ui)
		if ds == null:
			break
		seen.append(String((ds._run as RunState).char_class))
		ds.emit_signal("boon_taken", ds._offers[0])
		guard += 1
	_ck(seen.size() == 5 and String(seen[4]) == "done" and String(seen[0]) == "bulwark",
		"D: chain = your REFORGE then 3 AI drafts then done (%s)" % str(seen))
	var ai_boons := 0
	for k in hud._ai_runs:
		ai_boons += (hud._ai_runs[k] as RunState).boons.size()
	_ck(ai_boons == 3, "D: each AI raider took exactly one boon (n=%d)" % ai_boons)
	_ck(hud._run.boons.size() == 1, "D: your own pick landed too")
	_ck(hud._run.tokens == 5, "D: shared bank intact when nothing was spent (5)")
	_ck(hud._seat_boons_now().size() == 4,
		"D: all four seats' boons ride the next pull's spec")

	print("COMMANDER PROBE: %s (fails=%d)" % [("ALL OK" if fails == 0 else "FAIL"), fails])
	quit(1 if fails > 0 else 0)
	return false
