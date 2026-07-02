## The Voidcaller spec centrepiece — a winged void-conduit medallion.
## DISRUPTOR: the core is a contained mote of void (rotating violet containment arcs);
## five Backlash gems sit on a crescent conduit over the top, banked by clean kicks.
## When Overload primes an instant Fracture, the gems BEAM into the core and it blazes.
## SILENCER: the core is the lockout clock — a draining radial ring with the countdown
## in display numerals — and the Exposed readout burns amber beneath. Pure view; the
## HUD feeds the same fields as before.
class_name VoidcallerGauge
extends Control

var aspect: String = "disruptor"
var backlash: int = 0
var backlash_max: int = 5
var next_instant: bool = false
var silence_left: float = 0.0
var expose_amt: float = 0.0
var boss_exposed: bool = false
var _pulse: float = 0.0
var _flash: float = 0.0        # pop on a newly banked stack
var _last_bl: int = 0

func _process(delta: float) -> void:
	_pulse += delta * 3.2
	if backlash > _last_bl:
		_flash = 1.0
	_last_bl = backlash
	_flash = maxf(0.0, _flash - delta * 2.6)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var c := Vector2(w * 0.5, h * 0.5 - 2.0)
	if aspect == "disruptor":
		_disruptor(c, h)
	else:
		_silencer(c, h)

# ---------------------------------------------------------------- Disruptor
func _disruptor(c: Vector2, h: float) -> void:
	var R := 34.0
	var banked := backlash > 0

	UiKit.wing_flourish(self, c, -1.0, 200.0, Palette.KICK, next_instant)
	UiKit.wing_flourish(self, c, 1.0, 200.0, Palette.KICK, next_instant)

	# crescent conduit of Backlash gems arched over the core
	var cr := 62.0
	for i in backlash_max:
		var a := deg_to_rad(-160.0 + 35.0 * float(i))
		var gp := c + Vector2(cos(a), sin(a)) * cr
		var lit := i < backlash
		# conduit groove between gems
		if i < backlash_max - 1:
			var a2 := deg_to_rad(-160.0 + 35.0 * (float(i) + 0.5))
			var mid := c + Vector2(cos(a2), sin(a2)) * cr
			var lcol := Palette.KICK if (lit and i + 1 < backlash + 1 and i + 1 <= backlash) else Palette.GOLD_DIM
			lcol.a = 0.55 if lit else 0.25
			draw_arc(c, cr, a + 0.12, deg_to_rad(-160.0 + 35.0 * float(i + 1)) - 0.12, 8, lcol, 1.4, true)
		# primed: the banked gems beam into the core
		if next_instant and lit:
			var beam := Palette.KICK.lightened(0.2)
			beam.a = 0.30 + 0.25 * (0.5 + 0.5 * sin(_pulse * 2.6 + float(i)))
			draw_line(gp.lerp(c, 0.18), c + (gp - c).normalized() * R * 0.5, beam, 2.0, true)
		if lit and i == backlash - 1 and _flash > 0.0:
			var fb := Palette.KICK
			fb.a = 0.4 * _flash
			draw_circle(gp, 15.0, fb)
		UiKit.gilded_pip(self, gp, 8.5 + (1.0 * sin(_pulse * 2.6) if (next_instant and lit) else 0.0),
			lit, Palette.KICK)

	# the void core
	if next_instant:
		var halo := Palette.KICK
		halo.a = 0.18 + 0.12 * sin(_pulse * 2.6)
		draw_circle(c, R * 1.5, halo)
	draw_circle(c, R * 0.82, Palette.FILL_BOT)
	draw_circle(c - Vector2(0, R * 0.16), R * 0.66, Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.5))
	# rotating containment arcs — the void mote swirling in its cage
	var vcol := Palette.VOID.lightened(0.15) if next_instant else Palette.VOID
	vcol.a = 0.75
	draw_arc(c, R * 0.52, _pulse * 0.9, _pulse * 0.9 + 2.1, 12, vcol, 2.0, true)
	draw_arc(c, R * 0.40, -_pulse * 1.3 + PI, -_pulse * 1.3 + PI + 1.7, 10, vcol.darkened(0.15), 1.6, true)
	UiKit.gilded_ring(self, c, R, 2.5, 44)
	# numeral + label
	UiKit.text_shadowed(self, UiKit.display(750), Vector2(c.x - R, c.y + 9.0), str(backlash),
		HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["GAUGE"],
		Palette.KICK.lightened(0.3) if next_instant else Palette.GOLD_BRIGHT)
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(c.x - R, c.y + 23.0), "BACKLASH",
		HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

	# payoff line
	if next_instant:
		UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(0, h - 7.0), "◆ NEXT FRACTURE: INSTANT ◆",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"],
			Palette.PERFECT.lerp(Palette.GOLD_BRIGHT, 0.5 + 0.5 * sin(_pulse * 2.0)))
	elif banked:
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(0, h - 7.0),
			"OVERLOAD READY — %d STACKS" % backlash,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.KICK)
	else:
		UiKit.engraved_plaque(self, Vector2(c.x, h - 13.0), "CLEAN KICKS BANK BACKLASH", false)

# ---------------------------------------------------------------- Silencer
func _silencer(c: Vector2, h: float) -> void:
	var R := 36.0
	var locked := silence_left > 0.05

	UiKit.wing_flourish(self, c, -1.0, 200.0, Palette.KICK, locked)
	UiKit.wing_flourish(self, c, 1.0, 200.0, Palette.EXPOSE, boss_exposed)

	# the lockout clock
	if locked:
		var halo := Palette.KICK
		halo.a = 0.16 + 0.12 * sin(_pulse * 2.2)
		draw_circle(c, R * 1.5, halo)
	draw_circle(c, R * 0.82, Palette.FILL_BOT)
	draw_circle(c - Vector2(0, R * 0.16), R * 0.66, Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.5))
	var f := clampf(silence_left / 6.0, 0.0, 1.0)
	draw_arc(c, R, 0.0, TAU, 44, Color(0.07, 0.08, 0.12), 7.0, true)          # recessed track
	if f > 0.001:
		UiKit.gradient_arc(self, c, R, -PI / 2.0, -PI / 2.0 + TAU * f, 7.0,
			Palette.KICK.darkened(0.35), Palette.KICK.lightened(0.25), 44)
	UiKit.engraved_ticks(self, c, R + 5.0, R + 9.0, 12)
	UiKit.gilded_ring(self, c, R + 11.0, 2.0, 44)
	if locked:
		UiKit.text_shadowed(self, UiKit.display(750), Vector2(c.x - R, c.y + 9.0), "%.1f" % silence_left,
			HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["TITLE"], Palette.KICK.lightened(0.3))
		UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(c.x - R, c.y + 23.0), "SILENCED",
			HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["MICRO"],
			Palette.KICK.lightened(0.1 + 0.2 * sin(_pulse * 2.0)))
	else:
		UiKit.text_shadowed(self, UiKit.display(700), Vector2(c.x - R, c.y + 8.0), "—",
			HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["TITLE"], Palette.TEXT_DIM)
		UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(c.x - R, c.y + 22.0), "FREE TO CAST",
			HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

	# Exposed readout — amber gems flanking the payoff line
	if boss_exposed:
		var txt := "EXPOSED  +%d%% DAMAGE" % int(round(expose_amt * 100.0))
		UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(0, h - 7.0), txt,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["LABEL"],
			Palette.EXPOSE.lerp(Palette.GOLD_BRIGHT, 0.3 + 0.3 * sin(_pulse * 2.0)))
		var etw := UiKit.display(700, 1).get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZE["LABEL"]).x
		for s: float in [-1.0, 1.0]:
			var gx := size.x * 0.5 + s * (etw * 0.5 + 16.0)
			var gy := h - 12.0
			var pts := PackedVector2Array([Vector2(gx, gy - 5.0), Vector2(gx + 4.0, gy),
				Vector2(gx, gy + 5.0), Vector2(gx - 4.0, gy)])
			draw_colored_polygon(pts, Palette.EXPOSE.darkened(0.2))
			draw_line(pts[0], pts[1], Palette.GOLD, 1.0, true)
			draw_line(pts[3], pts[0], Palette.GOLD, 1.0, true)
	else:
		UiKit.engraved_plaque(self, Vector2(c.x, h - 13.0), "CLEAN KICKS SILENCE LONGER", false)
