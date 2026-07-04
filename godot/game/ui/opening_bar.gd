## OpeningBar — the offense-side timing bar for Twinfang's THE OPENING verb. Where the
## RhythmBar reads YOUR cadence, this reads the BOSS: a telegraphed swing OVEREXTENDS it,
## and a vulnerability window opens around the impact. Land a DUMP (Eviscerate / Coup /
## Rupture / Flurry) in the bright sweet spot — right when/around/after the boss hits —
## for the biggest bonus. Pure view: fed each frame from observe()'s open_* fields.
class_name OpeningBar
extends Control

var active: bool = false        ## an opening is scheduled or live
var now_tick: int = 0
var from_tick: int = 0
var peak_tick: int = 0
var to_tick: int = 0
var core_ticks: int = 3
var bonus_now: float = 0.0      ## live grade of a dump RIGHT NOW (0 .. open_bonus)
var armed: bool = false         ## the player has a dump ready to spend into the window

# verdict flash on a landed dump ("peak" | "hit" | "whiff")
var _result: String = ""
var _result_t: float = 0.0
var _result_x: float = 0.0
var _pulse: float = 0.0

const HOLD := 0.6
const LEAD := 40.0              ## ticks of run-up drawn before the peak (~1.3s)
const TAIL := 13.0              ## ticks drawn after the peak (~0.43s)

func show_result(r: String) -> void:
	_result = r
	_result_t = HOLD
	_result_x = _tf(float(now_tick))   # flash where the needle landed

func _process(delta: float) -> void:
	_pulse += delta * 6.0
	if _result_t > 0.0:
		_result_t -= delta
	queue_redraw()

## Map an absolute tick to a 0..1 fraction across the track (peak sits near the right).
func _tf(t: float) -> float:
	return clampf((t - (float(peak_tick) - LEAD)) / (LEAD + TAIL), 0.0, 1.0)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ty := h * 0.34
	var th := h * 0.40
	var font := ThemeDB.fallback_font
	var in_window := active and now_tick >= from_tick and now_tick <= to_tick

	# caption
	var cap := "THE OPENING"
	var cap_c := Palette.GOLD_DIM
	if in_window:
		cap = "PUNISH!" if bonus_now >= 0.45 else "OPENING — DUMP NOW"
		cap_c = Palette.GOLD_BRIGHT
	elif active:
		cap = "the boss is overextending…"
		cap_c = Palette.GOLD
	draw_string(font, Vector2(2.0, ty - 6.0), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cap_c)

	# track backdrop
	var back := Color(0.10, 0.06, 0.05, 0.62)
	draw_rect(Rect2(0.0, ty, w, th), back)
	draw_rect(Rect2(0.0, ty, w, th), Color(0.0, 0.0, 0.0, 0.35), false, 1.0)

	if not active:
		draw_string(font, Vector2(w * 0.5 - 96.0, ty + th * 0.5 + 5.0),
			"watch for the swing", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.55))
		return

	# the vulnerability window [from, to] — the boss's exposed recovery
	var wx0 := _tf(from_tick) * w
	var wx1 := _tf(to_tick) * w
	var win := Palette.CRIMSON
	win.a = 0.22
	draw_rect(Rect2(wx0, ty + 2.0, maxf(wx1 - wx0, 2.0), th - 4.0), win)

	# the sweet spot (core) — brightest, centred just AFTER impact
	var cx0 := _tf(float(peak_tick - core_ticks)) * w
	var cx1 := _tf(float(peak_tick + core_ticks)) * w
	var core := Palette.GOLD_BRIGHT
	core.a = 0.30 + (0.30 if in_window else 0.0)
	draw_rect(Rect2(cx0, ty + 3.0, maxf(cx1 - cx0, 3.0), th - 6.0), core)
	# travelling shimmer inside the sweet spot while it's live
	if in_window:
		var sw := cx1 - cx0
		if sw > 6.0:
			var sx := cx0 + fmod(_pulse * 26.0, maxf(sw - 5.0, 1.0))
			var sh := Palette.GOLD_BRIGHT.lightened(0.4)
			sh.a = 0.5
			draw_rect(Rect2(sx, ty + 3.0, 5.0, th - 6.0), sh)

	# the peak plumb line
	var px := _tf(float(peak_tick)) * w
	draw_line(Vector2(px, ty), Vector2(px, ty + th), Color(1.0, 0.92, 0.6, 0.85), 2.0, true)

	# the needle = now, sweeping left→right toward the window
	var nx := _tf(float(now_tick)) * w
	var ncol := Palette.GOLD_BRIGHT if in_window else Palette.STEEL
	if armed and not in_window:
		ncol = Palette.GOLD          # ready to punish — the needle warms up as it nears
	draw_line(Vector2(nx, ty - 4.0), Vector2(nx, ty + th + 4.0), ncol, 3.0, true)
	draw_circle(Vector2(nx, ty - 4.0), 3.5, ncol)

	# verdict flash on a landed dump
	if _result_t > 0.0:
		var a := clampf(_result_t / HOLD, 0.0, 1.0)
		var vx := _result_x * w
		var txt := ""
		var vc := Palette.GOLD
		match _result:
			"peak":
				txt = "PUNISH!"; vc = Palette.GOLD_BRIGHT
			"hit":
				txt = "opening"; vc = Palette.GOLD
			"whiff":
				txt = "no opening"; vc = Palette.STEEL
		vc.a = a
		draw_string(font, Vector2(clampf(vx - 34.0, 2.0, w - 70.0), ty - 8.0),
			txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, vc)
