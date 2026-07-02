## SpecStrip — a labelled reliquary meter: an engraved plaque title, a jeweled glass
## bar with diamond end-gems, display-face numerals, and an IGNITE state while its
## payoff is castable (Surge / Last Stand ready): the gems light and the frame pulses.
## Generic: title / value / max_value / accent / charged / hint.
class_name SpecStrip
extends Control

var title: String = "RESERVOIR"
var value: float = 0.0
var max_value: float = 100.0
var accent: Color = Palette.STEEL
var charged: bool = false          # the payoff is castable right now
var hint: String = ""              # small right-aligned extra ("2 bloodied")
var _pulse: float = 0.0
var _disp: float = 0.0             # eased fill

func _process(delta: float) -> void:
	_pulse += delta * 3.2
	_disp += (value - _disp) * clampf(delta * 10.0, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var barh := 14.0
	var by := h - barh - 2.0
	var frac := clampf(_disp / maxf(max_value, 1.0), 0.0, 1.0)

	# header row: plaque left, numerals right, hint centre
	UiKit.engraved_plaque(self, Vector2(52.0, 10.0), title, charged)
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, 15.0),
		"%d / %d" % [int(round(_disp)), int(round(max_value))],
		HORIZONTAL_ALIGNMENT_RIGHT, w - 12.0, UiKit.SIZE["LABEL"],
		Palette.GOLD_BRIGHT if charged else Palette.TEXT_DIM)
	if hint != "":
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(0, 14.0), hint,
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], Palette.CRIMSON.lightened(0.15))

	# the jeweled bar
	var bar := Rect2(14.0, by, w - 28.0, barh)
	var acc := accent.lightened(0.18) if charged else accent
	UiKit.glass_bar_draw(self, bar, frac, acc)
	# diamond end-gems, lit while charged
	_gem(Vector2(bar.position.x - 7.0, by + barh * 0.5), 6.5, charged)
	_gem(Vector2(bar.end.x + 7.0, by + barh * 0.5), 6.5, charged)
	# ignite: a soft pulsing halo line over the frame
	if charged:
		var g := Palette.GOLD_BRIGHT
		g.a = 0.25 + 0.20 * (0.5 + 0.5 * sin(_pulse * 2.0))
		draw_rect(Rect2(bar.position - Vector2(2, 2), bar.size + Vector2(4, 4)), g, false, 1.5)

func _gem(at: Vector2, r: float, lit: bool) -> void:
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.72, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.72, 0)])
	draw_colored_polygon(pts, accent.darkened(0.15) if lit else Color(0.08, 0.09, 0.12))
	draw_line(pts[0], pts[1], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[3], pts[0], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	if lit:
		draw_circle(at + Vector2(-r * 0.2, -r * 0.28), r * 0.22, Color(1, 1, 1, 0.75))
