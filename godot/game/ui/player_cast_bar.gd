## Your own cast bar (Voidcaller's Fracture). An engraved plaque + jeweled glass bar
## with diamond end-gems that fills as you cast; turns crimson and rattles when a hit
## pushes it back. When Overload primes an instant Fracture, the idle bar ignites.
class_name PlayerCastBar
extends Control

var active: bool = false
var frac: float = 0.0
var label: String = ""
var pushed: bool = false
var next_instant: bool = false
var _pulse: float = 0.0

func _process(delta: float) -> void:
	_pulse += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var barh := 18.0
	var by := size.y - barh
	UiKit.engraved_plaque(self, Vector2(46.0, 9.0), "YOUR CAST", active)
	var accent := Palette.CRIMSON if pushed else Palette.VOID
	var bar := Rect2(12.0, by, w - 24.0, barh)
	var wob := Vector2(sin(_pulse * 14.0) * 2.0, 0.0) if (active and pushed) else Vector2.ZERO
	bar.position += wob
	UiKit.glass_bar_draw(self, bar, clampf(frac, 0.0, 1.0) if active else 0.0, accent)
	# diamond end-gems, lit while casting / primed
	var lit := active or next_instant
	for s: float in [-1.0, 1.0]:
		var gc := Vector2(bar.position.x if s < 0.0 else bar.end.x, by + barh * 0.5) + Vector2(s * 7.0, 0)
		var pts := PackedVector2Array([gc + Vector2(0, -6.0), gc + Vector2(4.5, 0),
			gc + Vector2(0, 6.0), gc + Vector2(-4.5, 0)])
		draw_colored_polygon(pts, (accent if active else Palette.PERFECT).darkened(0.15) if lit else Color(0.08, 0.09, 0.12))
		draw_line(pts[0], pts[1], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
		draw_line(pts[3], pts[0], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	if active:
		UiKit.text_shadowed(self, font, Vector2(0, by + 14.0),
			("Pushed back — " if pushed else "Casting ") + label,
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"],
			Palette.CRIMSON.lightened(0.2) if pushed else Palette.TEXT)
	elif next_instant:
		var g := Palette.PERFECT
		g.a = 0.25 + 0.20 * sin(_pulse * 2.0)
		draw_rect(Rect2(bar.position - Vector2(2, 2), bar.size + Vector2(4, 4)), g, false, 1.5)
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(0, by + 14.0), "NEXT FRACTURE: INSTANT",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"],
			Palette.PERFECT.lerp(Palette.GOLD_BRIGHT, 0.5 + 0.5 * sin(_pulse)))
