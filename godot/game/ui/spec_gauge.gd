## Spec resource display. Warden: a row of cut Counter gems on an engraved rail —
## they blaze and throw a radiant burst while a Riposte window is live. Juggernaut:
## a gilded Momentum core — an engraved ring that fills, ticks, and flares as the
## snowball grows, with the payoff readout on a plaque.
class_name SpecGauge
extends Control

var aspect: String = "warden"
var counter: int = 0
var counter_max: int = 5
var momentum: int = 0
var momentum_max: int = 10
var riposte: bool = false
var _pulse: float = 0.0

func _process(delta: float) -> void:
	_pulse += delta * 4.0
	queue_redraw()

func _draw() -> void:
	if aspect == "warden":
		var n := counter_max
		var spacing := minf(size.x / float(n + 1), 34.0)
		var y := size.y * 0.4
		# engraved rail behind the gems
		var rail_w := spacing * float(n - 1) + 40.0
		var rx := size.x * 0.5 - rail_w * 0.5
		draw_line(Vector2(rx, y), Vector2(rx + rail_w, y), Palette.BG0, 4.0, true)
		draw_line(Vector2(rx, y + 1.0), Vector2(rx + rail_w, y + 1.0),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.2, true)
		# riposte: radiant burst behind the lit gems
		if riposte:
			var ba := 0.20 + 0.15 * sin(_pulse * 2.0)
			for i in range(counter):
				var bx := size.x * 0.5 + (float(i) - float(n - 1) / 2.0) * spacing
				draw_circle(Vector2(bx, y), 16.0, Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, ba))
		for i in range(n):
			var x := size.x * 0.5 + (float(i) - float(n - 1) / 2.0) * spacing
			_gem_pip(Vector2(x, y), 11.0, i < counter)
		if riposte:
			UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(0, y + 32.0), "◆ RIPOSTE READY ◆",
				HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"],
				Palette.GOLD_BRIGHT.lerp(Palette.GOLD, 0.5 + 0.5 * sin(_pulse)))
		else:
			UiKit.engraved_plaque(self, Vector2(size.x * 0.5, y + 30.0), "COUNTER", counter > 0)
	else:
		var c := Vector2(size.x * 0.5, size.y * 0.42)
		var r := 22.0
		var f := clampf(float(momentum) / float(maxi(momentum_max, 1)), 0.0, 1.0)
		# core flare as the snowball grows
		if f > 0.0:
			var fl := Palette.MOMENTUM
			fl.a = 0.10 + 0.14 * f + (0.06 * sin(_pulse * 2.0) if f >= 1.0 else 0.0)
			draw_circle(c, r * (1.15 + 0.25 * f), fl)
		draw_arc(c, r, 0.0, TAU, 40, Palette.BG0, 6.0, true)      # recessed well
		UiKit.gradient_arc(self, c, r, -PI / 2.0, -PI / 2.0 + TAU * f, 6.0,
			Palette.MOMENTUM.darkened(0.3), Palette.GOLD_BRIGHT, 40)
		UiKit.engraved_ticks(self, c, r + 5.0, r + 9.0, momentum_max)
		UiKit.gilded_ring(self, c, r + 4.0, 2.0, 40)
		UiKit.text_shadowed(self, UiKit.display(700), Vector2(c.x - 30.0, c.y + 7.0), str(momentum),
			HORIZONTAL_ALIGNMENT_CENTER, 60, UiKit.SIZE["SUBHEAD"], Palette.GOLD_BRIGHT)
		UiKit.engraved_plaque(self, Vector2(c.x, c.y + r + 20.0),
			"MOMENTUM  +%d%% DMG / +%d%% MIT" % [int(momentum * 6), int(momentum * 2.5)], momentum > 0)

func _gem_pip(c: Vector2, r: float, on: bool) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0 - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Palette.STEEL.darkened(0.12) if on else Color(0.08, 0.09, 0.12))
	var outline := pts
	outline.append(pts[0])
	draw_polyline(outline, Palette.GOLD_BRIGHT if on else Palette.GOLD_DIM, 1.5, true)
	if on:
		draw_circle(c - Vector2(r * 0.3, r * 0.35), 2.0, Color(1, 1, 1, 0.7))   # specular
