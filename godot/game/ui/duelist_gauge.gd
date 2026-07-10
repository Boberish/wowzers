## DuelistGauge — the dodge tank's instrument (S4): the WIND bubble (fatigue leash) + the ◆ COMBO
## pips (banked by perfect parries, spent by ⚡ DUMP). The FLOW / AGGRO meter rides the band's
## resource orb; this gauge carries the two smaller readouts. Pure view (no gameplay).
class_name DuelistGauge
extends ClassGauge

func _init() -> void:
	pulse_rate = 4.0

var wind: float = 10.0
var wind_max: float = 10.0
var combo: int = 0
var combo_max: int = 5
var fumbling: bool = false

func _draw() -> void:
	# --- WIND: a slim bubble bar (the fast-recharge fatigue leash) ---
	var bw := size.x * 0.62
	var bx := size.x * 0.5 - bw * 0.5
	var by := size.y * 0.34
	draw_rect(Rect2(bx, by, bw, 10.0), Palette.BG0)
	var frac := clampf(wind / maxf(1.0, wind_max), 0.0, 1.0)
	var wc: Color = Palette.CRIMSON if fumbling else Palette.STEEL
	if not fumbling and frac < 0.25:
		wc = Palette.GOLD_DIM                       # low wind warning tint
	draw_rect(Rect2(bx, by, bw * frac, 10.0), wc)
	draw_rect(Rect2(bx, by, bw, 10.0), Palette.GOLD_DIM, false, 1.0)

	# --- ◆ COMBO pips (banked by perfect parries) ---
	var y2 := size.y * 0.72
	var n := maxi(1, combo_max)
	var spacing := minf(size.x / float(n + 1), 30.0)
	for i in range(n):
		var x := size.x * 0.5 + (float(i) - float(n - 1) / 2.0) * spacing
		var lit := i < combo
		var col: Color = Palette.GOLD_BRIGHT if lit else Palette.BG0
		if lit and combo >= combo_max:
			col.a = 0.6 + 0.35 * sin(pulse * 2.0)    # full bank pulses (ready to DUMP)
		_diamond(Vector2(x, y2), 9.0, col)

func _diamond(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
		Palette.GOLD_DIM, 1.0, true)
