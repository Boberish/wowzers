## WellGauge — the reworked healer's instrument (MENDER-PLAN). A plain view Control fed
## observe() fields each frame + verdict events via on_event; never touches combat state.
##   • THE WELL: a vessel of discrete CHARGE segments (income by pulse, spent per cast).
##   • THE CURRENT (draw): the cast-haste pip row.
##   • THE TARGET BAR: the ally under your hands, writ large — BRIM aims the pour here
##     (the gilded window + the in-flight heal's ghost landing, mirrored from their frame).
##   • Verdict banner + grade-history rail (POUR / STILL / CLEAN / UNDER / SPILL).
## The cast bar itself is the SHARED healer CastChannel (extended with the release window).
class_name WellGauge
extends Control

# fed each frame by _render_band_well
var aspect: String = "brim"
var charges: int = 12
var charges_max: int = 12
var current: int = 0
var current_max: int = 5
# the target bar
var t_show: bool = false
var t_name: String = ""
var t_frac: float = 0.0
var t_ghost: float = -1.0        ## where the in-flight heal LANDS (-1 = no cast)
var t_band: float = -1.0         ## the brim window start (-1 = no band; draw hides it)
var t_glint: bool = false

# feedback (set by on_event, decayed in _process)
var _banner: String = ""
var _banner_col: Color = Color.WHITE
var _banner_t: float = 0.0
var _hist: Array = []            # [{col}], last 8 verdicts
var _pulse: float = 0.0

var seat_ref: Seat = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_pulse += delta
	if _banner_t > 0.0:
		_banner_t = maxf(0.0, _banner_t - delta)
	queue_redraw()

func on_event(ev: Dictionary) -> void:
	if not bool(ev.get("player", false)) and ev.get("seat") != seat_ref:
		return
	match String(ev.get("t", "")):
		"well_pour":  _flash("PERFECT POUR — GLINT!", Palette.GOLD_BRIGHT)
		"well_still": _flash("STILL POINT — GLINT!", Palette.GOLD_BRIGHT)
		"well_clean": _flash("CLEAN — the current rises", Palette.STEEL)
		"well_under": _flash("UNDERCOOKED", Palette.THORN)
		"well_spill": _flash("SPILL — %d wasted" % int(ev.get("amt", 0)), Palette.BLOOD)

func _flash(msg: String, col: Color) -> void:
	_banner = msg
	_banner_col = col
	_banner_t = 1.3
	_hist.push_back({"col": col})
	if _hist.size() > 8:
		_hist.pop_front()

func _draw() -> void:
	var w := size.x
	var font := ThemeDB.fallback_font
	var dim := Palette.TEXT_DIM

	# --- title ---
	var title := "THE WELL — %s" % ("BRIM · land it in the gold" if aspect == "brim" else "DRAW · release in the window")
	draw_string(font, Vector2(6, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)

	# --- charge vessel ---
	var vy := 18.0
	var vh := 22.0
	var gap := 3.0
	var seg := (w - 90.0 - gap * float(charges_max - 1)) / float(charges_max)
	for i in range(charges_max):
		var x := 6.0 + float(i) * (seg + gap)
		var r := Rect2(x, vy, seg, vh)
		if i < charges:
			draw_rect(r, Palette.GOLD_BRIGHT if i == charges - 1 else Palette.GOLD)
		else:
			draw_rect(r, Color(0.17, 0.28, 0.30), false, 1.0)
	if charges == 0:
		draw_string(font, Vector2(w * 0.45, vy + 16), "DRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.BLOOD)
	draw_string(font, Vector2(w - 78, vy + 16), "%d / %d ◍" % [charges, charges_max],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT)

	# --- the Current (draw) ---
	var yy := vy + vh + 8.0
	if aspect == "draw":
		draw_string(font, Vector2(6, yy + 10), "CURRENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, dim)
		var px := 66.0
		for i in range(current_max):
			draw_circle(Vector2(px + float(i) * 17.0, yy + 5.0), 5.5,
				Palette.STEEL if i < current else Color(0.22, 0.31, 0.33))
		if current > 0:
			draw_string(font, Vector2(px + float(current_max) * 17.0 + 6, yy + 10),
				"+%d%% cast speed" % int(current * 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Palette.STEEL)
		yy += 20.0

	# --- THE TARGET BAR: the ally under your hands, writ large ---
	var th := 26.0
	var tw := w - 12.0
	if t_show:
		var nm := t_name + ("   ✦ GLINTING" if t_glint else "")
		draw_string(font, Vector2(6, yy + 10), nm.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Palette.GOLD_BRIGHT if t_glint else Palette.TEXT)
		var br := Rect2(6, yy + 14, tw, th)
		draw_rect(br, Color(0.07, 0.10, 0.11))
		# HP fill
		draw_rect(Rect2(br.position.x, br.position.y, tw * clampf(t_frac, 0.0, 1.0), th),
			Color(0.24, 0.47, 0.35))
		# the in-flight heal's landing (the ghost pour)
		if t_ghost > t_frac:
			var gx := br.position.x + tw * t_frac
			var gw2 := tw * (clampf(t_ghost, 0.0, 1.0) - t_frac)
			var gc := Palette.GOLD_BRIGHT
			gc.a = 0.45 + 0.20 * sin(_pulse * 5.0)
			draw_rect(Rect2(gx, br.position.y + 2.0, gw2, th - 4.0), gc)
		# the brim window (brim only): gilded band + hairline + label
		if t_band > 0.0:
			var bx2 := br.position.x + tw * clampf(t_band, 0.0, 1.0)
			draw_rect(Rect2(bx2, br.position.y + 1.0, br.end.x - bx2, th - 2.0),
				Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.18))
			draw_line(Vector2(bx2, br.position.y - 3.0), Vector2(bx2, br.end.y + 3.0),
				Palette.GOLD_BRIGHT, 2.0, true)
			draw_string(font, Vector2(bx2 - 34.0, br.position.y - 4.0), "POUR ▸",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Palette.GOLD_BRIGHT)
		draw_rect(br, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.6), false, 1.0)
	else:
		draw_string(font, Vector2(6, yy + 24), "— hover an ally to aim —",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
	yy += 14.0 + th + 6.0

	# --- verdict banner + grade rail ---
	if _banner_t > 0.0:
		draw_string(font, Vector2(6, yy + 12), _banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(_banner_col, clampf(_banner_t, 0.0, 1.0)))
	var gx2 := w - 12.0 - float(_hist.size()) * 14.0
	for h in _hist:
		draw_circle(Vector2(gx2, yy + 8.0), 5.0, h["col"])
		gx2 += 14.0
