## Regression probe for the Overflow boon (fixed 2026-07-03): the spill-shield must
## only ever GROW a ward and only claim ownership on real growth — never let its
## hp_max*0.5 cap collapse an already-larger Surge/Ward shield, nor steal ownership
## when it added nothing. (The audit flagged that no sim exercised drafted-boon
## correctness; this pins THIS bug so it can't come back.)
##   godot --headless --path godot --script res://sim/mender_overflow_probe.gd
extends SceneTree
func _initialize() -> void:
	var kit := MenderKit.new("brinkwarden", MenderConfig.new())   # skips the tidecaller branch
	kit.boons = {"overflow": true}
	var s := CombatState.new()
	var caster := Seat.new(); caster.role = "healer"; caster.hp_max = 200.0; caster.hp = 200.0
	var ally := Seat.new(); ally.role = "dps"; ally.hp_max = 110.0; ally.hp = 110.0
	s.seats = [caster, ally]                        # Overflow cap = hp_max*0.5 = 55

	# [1] a big Surge/Ward shield (90 > 55) owned by seat 0 — must NOT shrink or lose owner
	ally.absorb = 90.0; ally.absorb_owner_i = 0
	kit.on_overheal(s, caster, ally, 50.0)
	var ok1 := ally.absorb == 90.0 and ally.absorb_owner_i == 0
	print("  [1] big ward (90) not shrunk: %s  -> absorb=%.0f owner=%d" % [ok1, ally.absorb, ally.absorb_owner_i])

	# [2] a small shield (10) — Overflow tops it up toward the cap and claims it
	ally.absorb = 10.0; ally.absorb_owner_i = -1
	kit.on_overheal(s, caster, ally, 50.0)          # +roundf(15)=25, under cap 55
	var ok2 := ally.absorb == 25.0 and ally.absorb_owner_i == 0
	print("  [2] small ward (10) topped to 25: %s  -> absorb=%.0f owner=%d" % [ok2, ally.absorb, ally.absorb_owner_i])

	# [3] exactly at cap (55) owned by seat 1 — no change, no ownership steal
	ally.absorb = 55.0; ally.absorb_owner_i = 1
	kit.on_overheal(s, caster, ally, 50.0)
	var ok3 := ally.absorb == 55.0 and ally.absorb_owner_i == 1
	print("  [3] at-cap ward (55) unchanged: %s  -> absorb=%.0f owner=%d" % [ok3, ally.absorb, ally.absorb_owner_i])

	print("MENDER OVERFLOW PROBE: %s" % ("ALL OK" if ok1 and ok2 and ok3 else "FAIL"))
	quit(0 if (ok1 and ok2 and ok3) else 1)
