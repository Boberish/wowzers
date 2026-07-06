## fightlen_probe — the FIGHTLEN dev feel-scalar (WORLD-PLAN §FIGHT LENGTH).
## Runs the raid HUD's offline launch paths and asserts:
##   flag ABSENT  → boss HP + enrage byte-equal the encounter's authored values;
##   flag PRESENT → both scaled by exactly ×N (phases stay fractional by construction).
## Run BOTH:  godot --headless --path godot --script res://sim/fightlen_probe.gd
##            godot --headless --path godot --script res://sim/fightlen_probe.gd -- --fightlen=2.5
extends SceneTree

var hud: Control
var step := 0
var fails := 0
var scale := 1.0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fightlen="):
			scale = maxf(1.0, float(a.substr("--fightlen=".length())))
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _process(_d: float) -> bool:
	step += 1
	if step == 1:
		# the single-Seal offline pull (riftmaw: authored 15500 HP / 90s enrage)
		var base := RaidContent.make_riftmaw()
		hud._launch("tank", "warden", "riftmaw")
		_expect("single Seal", base.hp, base.enrage_at)
		return false
	if step == 2:
		# a ZONE pull (bare kit; bard skirmish)
		hud._world = WorldSave.new()
		hud._zone_id = WorldContent.ZONE1
		var base := RaidContent.make_skirmish("bard")
		var z := WorldContent.zone(WorldContent.ZONE1)
		hud._zone_node = 0
		hud._launch_zone_fight(WorldContent.resolved_node(z, 0, {}))
		_expect("zone fight", base.hp, base.enrage_at)
		return false
	print("FIGHTLEN PROBE (×%.2f): %s" % [scale, "ALL OK" if fails == 0 else "%d FAILURES" % fails])
	quit(0 if fails == 0 else 1)
	return true

func _expect(what: String, base_hp: float, base_enrage: float) -> void:
	var s: CombatState = hud._ctrl.state
	var want_hp := roundf(base_hp * scale)
	var want_en := base_enrage * scale
	_ck(absf(s.boss.hp - want_hp) < 0.5, "%s boss HP %.0f == %.0f" % [what, s.boss.hp, want_hp])
	_ck(absf(s.boss.hp_max - want_hp) < 0.5, "%s boss hp_max scaled" % what)
	_ck(absf(s.encounter.enrage_at - want_en) < 0.01, "%s enrage %.1f == %.1f" % [what, s.encounter.enrage_at, want_en])
	print("  %s: hp %.0f · enrage %.1fs (×%.2f) ok" % [what, s.boss.hp, s.encounter.enrage_at, scale])

func _ck(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
