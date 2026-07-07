## WellGauge — the reworked healer's instrument (MENDER-PLAN). A plain view Control fed
## observe() fields each frame + verdict events via on_event; never touches combat state.
##   • THE WELL: a vessel of discrete CHARGE segments (income by pulse, spent per cast).
##   • DRAW: a row of CURRENT pips + a release band + Still-Point sliver on the cast bar.
##   • Verdict banner + grade-history rail (POUR / GLINT / STILL / CLEAN / SPILL / UNDER).
## Modeled on reckoner_gauge / brew_gauge (Control + _process→queue_redraw + _draw).
class_name WellGauge
extends Control

# fed each frame by _render_band_well
var aspect: String = "brim"
var charges: int = 12
var charges_max: int = 12
var current: int = 0
var current_max: int = 5
var brim_band: float = 0.90
var draw_band: float = 0.15
var still_point: float = 0.04
var cast_active: bool = false
var cast_p: float = 0.0
var cast_name: String = ""

# feedback (set by on_event, decayed in _process)
var _banner: String = ""
var _banner_col: Color = Color.WHITE
var _banner_t: float = 0.0
var _hist: Array = []            # [{col}], last 8 verdicts

var seat_ref: Seat = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _banner_t > 0.0:
		_banner_t = maxf(0.0, _banner_t - delta)
	queue_redraw()

func on_event(ev: Dictionary) -> void:
	if not bool(ev.get("player", false)) and ev.get("seat") != seat_ref:
		return
	var t := String(ev.get("t", ""))
	match t:
		"well_pour":  _flash("PERFECT POUR", Palette.GOLD_BRIGHT)
		"well_still": _flash("STILL POINT", Palette.GOLD_BRIGHT)
		"well_clean": _flash("CLEAN — the current rises", Palette.STEEL)
		"well_under": _flash("UNDERCOOKED", Palette.THORN)
		"well_spill": _flash("SPILL", Palette.BLOOD)
		"well_glint": pass

func _flash(msg: String, col: Color) -> void:
	_banner = msg
	_banner_col = col
	_banner_t = 1.0
	_hist.push_back({"col": col})
	if _hist.size() > 8:
		_hist.pop_front()

func _draw() -> void:
	var w := size.x
	var font := ThemeDB.fallback_font
	var ink := Palette.TEXT
	var dim := Palette.TEXT_DIM

	# --- title ---
	var title := "THE WELL — %s" % ("BRIM · grade the landing" if aspect == "brim" else "DRAW · grade the release")
	draw_string(font, Vector2(6, 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, dim)

	# --- charge vessel: charges_max segments, filled = have ---
	var vy := 26.0
	var vh := 26.0
	var gap := 3.0
	var seg := (w - 12.0 - gap * float(charges_max - 1)) / float(charges_max)
	for i in range(charges_max):
		var x := 6.0 + float(i) * (seg + gap)
		var r := Rect2(x, vy, seg, vh)
		if i < charges:
			var top := charges > 0 and i == charges - 1
			draw_rect(r, Palette.GOLD_BRIGHT if top else Palette.GOLD, true)
		else:
			draw_rect(r, Color(0.17, 0.28, 0.30), false, 1.0)
	if charges == 0:
		draw_string(font, Vector2(w * 0.5 - 14, vy + 18), "DRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.BLOOD)
	draw_string(font, Vector2(w - 78, vy + 18), "%d / %d ◍" % [charges, charges_max],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)

	# --- DRAW: the Current pips ---
	var by := vy + vh + 12.0
	if aspect == "draw":
		draw_string(font, Vector2(6, by + 11), "CURRENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, dim)
		var px := 70.0
		for i in range(current_max):
			var c := Color(0.22, 0.31, 0.33)
			if i < current:
				c = Palette.STEEL
			draw_circle(Vector2(px + float(i) * 18.0, by + 6.0), 6.0, c)
		if current > 0:
			draw_string(font, Vector2(px + float(current_max) * 18.0 + 6, by + 11),
				"+%d%% cast speed" % int(current * 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.STEEL)
		by += 22.0

	# --- the cast bar (DRAW marks the release band + Still Point; BRIM shows progress) ---
	var cw := w - 12.0
	var ch := 18.0
	var cr := Rect2(6, by, cw, ch)
	draw_rect(cr, Color(0.10, 0.17, 0.19), true)
	if cast_active:
		draw_rect(Rect2(6, by, cw * clampf(cast_p, 0.0, 1.0), ch), Palette.GOLD.darkened(0.1), true)
	if aspect == "draw":
		var bx := 6.0 + cw * (1.0 - draw_band)
		draw_rect(Rect2(bx, by, cw * draw_band, ch), Color(Palette.STEEL, 0.35), true)   # the clean band
		var sx := 6.0 + cw * (1.0 - draw_band * 0.5) - cw * still_point * 0.5
		draw_rect(Rect2(sx, by, maxf(2.0, cw * still_point), ch), Palette.GOLD_BRIGHT, true)  # Still Point
	draw_rect(cr, Color(0.20, 0.30, 0.32), false, 1.0)
	if cast_active and cast_name != "":
		draw_string(font, Vector2(10, by + 14), cast_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)

	# --- verdict banner + grade rail ---
	var yy := by + ch + 16.0
	if _banner_t > 0.0:
		var a := clampf(_banner_t, 0.0, 1.0)
		draw_string(font, Vector2(6, yy + 4), _banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color(_banner_col, a))
	var gx := w - 12.0 - float(_hist.size()) * 14.0
	for h in _hist:
		draw_circle(Vector2(gx, yy), 5.0, h["col"])
		gx += 14.0
