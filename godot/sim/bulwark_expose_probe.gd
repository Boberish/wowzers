## Regression probe for Sunder Guard (payExpose), fixed 2026-07-03: a guard proc must
## leave the SOLO TANK's own outgoing damage boosted by +mod_expose_amt for the window
## (it used to write boss-level fields only the Voidcaller reads → zero solo benefit).
##   godot --headless --path godot --script res://sim/bulwark_expose_probe.gd
extends SceneTree
func _initialize() -> void:
	var cfg := BulwarkConfig.new()
	var tune := TuningConfig.new()                     # provides fixed_hz for _tt
	var kit := BulwarkKit.new("warden", cfg)
	kit.boons = {"payExpose": true}
	var s := CombatState.new(); s.config = tune
	var seat := Seat.new(); seat.role = "tank"; seat.hp_max = 100.0; seat.hp = 100.0
	seat.resource_max = 100.0
	s.seats = [seat]; s.tick = 100

	kit.upkeep(s, seat)
	var before := kit.outgoing_mult(seat)              # no proc yet → 1.0
	kit._guard_proc(s, seat, "test")                   # sets pay_expose_until
	kit.upkeep(s, seat)                                # → pay_exposed = true
	var during := kit.outgoing_mult(seat)              # → 1 + 0.15
	s.tick = 100 + 40                                  # past the 1.2s (36-tick) window
	kit.upkeep(s, seat)
	var after := kit.outgoing_mult(seat)               # → 1.0

	# boonless control: a guard proc with no payloads must leave outgoing at 1.0
	var kit0 := BulwarkKit.new("warden", cfg); kit0.boons = {}
	var s0 := CombatState.new(); s0.config = tune
	var seat0 := Seat.new(); seat0.role = "tank"; seat0.hp_max = 100.0; seat0.hp = 100.0
	s0.seats = [seat0]; s0.tick = 100
	kit0._guard_proc(s0, seat0, "test")                # _has_payloads() false → no-op
	kit0.upkeep(s0, seat0)
	var boonless := kit0.outgoing_mult(seat0)

	var exp := 1.0 + cfg.mod_expose_amt
	var ok1 := is_equal_approx(before, 1.0)
	var ok2 := is_equal_approx(during, exp)
	var ok3 := is_equal_approx(after, 1.0)
	var ok4 := is_equal_approx(boonless, 1.0)
	print("  [1] before proc = 1.0:        %s  (%.3f)" % [ok1, before])
	print("  [2] during window = %.2f:     %s  (%.3f)" % [exp, ok2, during])
	print("  [3] after window = 1.0:       %s  (%.3f)" % [ok3, after])
	print("  [4] boonless = 1.0:           %s  (%.3f)" % [ok4, boonless])
	print("BULWARK EXPOSE PROBE: %s" % ("ALL OK" if ok1 and ok2 and ok3 and ok4 else "FAIL"))
	quit(0 if (ok1 and ok2 and ok3 and ok4) else 1)
