## The rhythm centrepiece — a gilded metronome channel. A jeweled needle with a motion
## trail sweeps a recessed glass track over the cadence since your last Strike: a
## hatched crimson "too early" reach, a neutral approach engraved with beat ticks, and
## a stained-glass emerald PERFECT window (gem-marked, glowing, with a travelling
## shimmer while you're inside it). Diamond end-caps + filigree corners frame the
## instrument; the live cue sits on its own line beneath the track.
##
## On every Strike the instrument flashes a HELD verdict — PERFECT! / EARLY / LATE —
## with a ghost needle + burst AT THE SPOT YOU PRESSED, so you see exactly how deep in
## the window you were. Without the hold, the bar would instantly reset and its live
## hint would read "too early", which looks like it's judging the press you just landed.
class_name RhythmBar
extends Control

const HOLD := 0.55

var since: int = 0            ## ticks since last Strike
var swing_min: int = 13       ## ticks; before this a Strike is ignored
var perfect_lo: int = 18
var perfect_hi: int = 29
var _pulse: float = 0.0
var _result: String = ""      ## "perfect" | "early" | "late"
var _result_t: float = 0.0    ## fade timer for the verdict flash
var _press_f: float = 0.0     ## track fraction where the last Strike landed
var _prev_prog: float = 0.0   ## last frame's needle position (pre-reset)

## Called by the HUD when a Strike lands (drained from the combat event stream).
func show_result(r: String) -> void:
	_result = r
	_result_t = HOLD
	_press_f = _prev_prog     # the needle has already snapped back — remember where it was

func _process(delta: float) -> void:
	_pulse += delta * 8.0
	if _result_t > 0.0:
		_result_t = maxf(0.0, _result_t - delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var hi := maxf(1.0, float(perfect_hi))
	var early_f := clampf(float(swing_min) / hi, 0.0, 1.0)
	var green_f := clampf(float(perfect_lo) / hi, 0.0, 1.0)
	var prog := clampf(float(since) / hi, 0.0, 1.0)
	var in_green := since >= perfect_lo and since <= perfect_hi
	var past := since > perfect_hi
	var flashing := _result_t > 0.0
	var fa := clampf(_result_t / HOLD, 0.0, 1.0)   # 1 -> 0 fade

	# ---- header: plaque + live cue ----
	UiKit.engraved_plaque(self, Vector2(76.0, 10.0), "STRIKE TIMING", in_green)
	UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(0, 14.0), "tap 1 in the green",
		HORIZONTAL_ALIGNMENT_RIGHT, w - 18.0, UiKit.SIZE["CAPTION"], Palette.PERFECT)

	# ---- the recessed glass channel ----
	var track := Rect2(16.0, 26.0, w - 32.0, 36.0)
	var tx := track.position.x
	var tw := track.size.x
	var ty := track.position.y
	var th := track.size.y
	var well := StyleBoxFlat.new()
	well.bg_color = Color(0.028, 0.024, 0.048)
	well.set_corner_radius_all(7)
	draw_style_box(well, track)
	draw_rect(Rect2(tx + 2, ty + 2, tw - 4, th * 0.42), Color(0, 0, 0, 0.38))   # inner shadow

	# "too early" reach — deep crimson glass with engraved hatching
	var ex := tw * early_f
	var early := Palette.CRIMSON_DEEP
	early.a = 0.62
	draw_rect(Rect2(tx + 2, ty + 2, ex - 2, th - 4), early)
	for hx in range(8, int(ex), 11):
		draw_line(Vector2(tx + float(hx) - 6.0, ty + th - 4.0), Vector2(tx + float(hx) + 4.0, ty + 4.0),
			Color(0, 0, 0, 0.22), 2.0, true)

	# the beat ruler — engraved ticks along the channel floor (majors at the boundaries)
	for i in range(1, 12):
		var rx := tx + tw * float(i) / 12.0
		draw_line(Vector2(rx, ty + th - 8.0), Vector2(rx, ty + th - 3.0), Palette.BG0, 2.0, true)
		draw_line(Vector2(rx + 0.6, ty + th - 8.0), Vector2(rx + 0.6, ty + th - 3.0),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.4), 1.0, true)

	# ---- the PERFECT window — stained emerald glass with gem-marked boundaries ----
	var gx := tx + tw * green_f
	var gw := tw * (1.0 - green_f)
	var gz := Palette.PERFECT
	gz.a = 0.20 + (0.26 if in_green else 0.0)
	draw_rect(Rect2(gx, ty + 2, gw - 2, th - 4), gz)
	# inner glow border + gloss
	var ig := Palette.PERFECT
	ig.a = 0.45 if in_green else 0.25
	draw_rect(Rect2(gx + 1, ty + 3, gw - 4, th - 6), ig, false, 1.2)
	draw_rect(Rect2(gx + 1, ty + 3, gw - 4, th * 0.30), Color(1, 1, 1, 0.10))
	if in_green:      # travelling shimmer while the press would be Perfect
		var sx := gx + fmod(_pulse * 34.0, maxf(gw - 8.0, 1.0))
		var sh := Palette.PERFECT.lightened(0.5)
		sh.a = 0.38
		draw_rect(Rect2(sx, ty + 3, 7.0, th - 6), sh)
	# chiselled boundary + cut gems at the window mouth and the early line
	for bd in [[tx + ex, false], [gx, true]]:
		var bx: float = bd[0]
		var is_green: bool = bd[1]
		draw_line(Vector2(bx, ty + 2), Vector2(bx, ty + th - 2), Palette.BG0, 3.0, true)
		draw_line(Vector2(bx + 1.0, ty + 2), Vector2(bx + 1.0, ty + th - 2),
			Palette.PERFECT if is_green else Palette.GOLD_DIM, 1.5, true)
		_gem(Vector2(bx, ty - 3.0), 5.0, Palette.PERFECT if is_green else Palette.CRIMSON_DEEP.lightened(0.15),
			is_green and in_green)

	# ---- verdict tint + ghost needle at the pressed spot ----
	if flashing:
		var tc := _result_color()
		tc.a = 0.26 * fa
		draw_rect(Rect2(tx + 2, ty + 2, tw - 4, th - 4), tc)
		var px := tx + tw * _press_f
		var gcol := _result_color()
		gcol.a = 0.85 * fa
		draw_line(Vector2(px, ty - 2.0), Vector2(px, ty + th + 2.0), gcol, 3.0, true)
		# burst where you pressed
		var br := 6.0 + 22.0 * (1.0 - fa)
		gcol.a = 0.7 * fa
		draw_arc(Vector2(px, ty - 8.0), br, 0.0, TAU, 24, gcol, 2.0, true)
		if _result == "perfect":
			for k in 6:
				var a := TAU * float(k) / 6.0 - PI / 2.0
				var d := Vector2(cos(a), sin(a))
				var rc := Palette.GOLD_BRIGHT
				rc.a = 0.8 * fa
				draw_line(Vector2(px, ty - 8.0) + d * (br + 2.0), Vector2(px, ty - 8.0) + d * (br + 9.0), rc, 1.6, true)

	# ---- the gilded needle: motion trail, shaft, diamond head ----
	var mx := tx + tw * prog
	var mcol := Palette.PERFECT if in_green else (Palette.CRIMSON if past else Color(0.85, 0.87, 0.92))
	# trail (the needle always travels left -> right)
	var trail_w := minf(30.0, mx - tx)
	if trail_w > 2.0:
		for k in 5:
			var seg := trail_w / 5.0
			var tcol := mcol
			tcol.a = 0.05 + 0.05 * float(k)
			draw_rect(Rect2(mx - trail_w + seg * float(k), ty + 3, seg, th - 6), tcol)
	if in_green:
		var halo := Palette.PERFECT
		halo.a = 0.30 + 0.20 * sin(_pulse)
		draw_rect(Rect2(mx - 5.0, ty - 3.0, 10.0, th + 6.0), halo)
	draw_rect(Rect2(mx - 1.5, ty - 4.0, 3.0, th + 10.0), mcol)
	draw_rect(Rect2(mx - 0.5, ty - 4.0, 1.0, th + 10.0), Color(1, 1, 1, 0.5))
	_needle_head(Vector2(mx, ty - 9.0), mcol, in_green)

	# ---- frame: 2-tone bevel, filigree corners, diamond end-caps ----
	draw_line(track.position, Vector2(tx + tw, ty), Palette.GOLD_BRIGHT, 1.6, true)
	draw_line(track.position, Vector2(tx, ty + th), Palette.GOLD, 1.6, true)
	draw_line(Vector2(tx, ty + th), track.end, Palette.GOLD_DIM, 1.6, true)
	draw_line(Vector2(tx + tw, ty), track.end, Palette.GOLD_DIM, 1.6, true)
	UiKit.filigree_corner(self, Vector2(tx - 2, ty - 2), Vector2(1, 1), 8.0)
	UiKit.filigree_corner(self, Vector2(tx + tw + 2, ty - 2), Vector2(-1, 1), 8.0)
	_gem(Vector2(tx, ty + th * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1), false)
	_gem(Vector2(tx + tw, ty + th * 0.5), 8.0, Palette.PERFECT.darkened(0.25), in_green)

	# ---- the message line beneath the track ----
	var my := ty + th + 22.0
	if flashing:
		UiKit.text_shadowed(self, UiKit.display(750, 1), Vector2(0, my), _result_text(),
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["HEADER"],
			Color(_result_color().r, _result_color().g, _result_color().b, 0.55 + 0.45 * fa))
	elif in_green:
		UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(0, my), "STRIKE!",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["HEADER"],
			Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.55 + 0.45 * sin(_pulse)))
	elif past:
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(0, my), "LATE — STRIKE NOW",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], Palette.RAGE)
	elif since < swing_min:
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(0, my), "wait for the beat…",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], Palette.TEXT_DIM)
	else:
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(0, my), "almost — hold…",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], Palette.TEXT_DIM)

	_prev_prog = prog

## a small cut gem (rotated diamond, gold bezel, specular; glows when live)
func _gem(at: Vector2, r: float, body: Color, live: bool) -> void:
	if live:
		var halo := body.lightened(0.2)
		halo.a = 0.30 + 0.20 * sin(_pulse)
		draw_circle(at, r * 1.8, halo)
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.75, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.75, 0)])
	draw_colored_polygon(pts, body)
	draw_line(pts[0], pts[1], Palette.GOLD, 1.3, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.3, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.3, true)
	draw_line(pts[3], pts[0], Palette.GOLD_BRIGHT if live else Palette.GOLD, 1.3, true)
	draw_circle(at + Vector2(-r * 0.22, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.7))

## the metronome needle head — a gilded diamond riding above the track
func _needle_head(at: Vector2, col: Color, live: bool) -> void:
	if live:
		var halo := col
		halo.a = 0.35 + 0.25 * sin(_pulse)
		draw_circle(at, 10.0, halo)
	var pts := PackedVector2Array([at + Vector2(0, -7.0), at + Vector2(5.5, 0),
		at + Vector2(0, 7.0), at + Vector2(-5.5, 0)])
	draw_colored_polygon(pts, col.darkened(0.15))
	draw_line(pts[0], pts[1], Palette.GOLD_BRIGHT, 1.3, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.3, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.3, true)
	draw_line(pts[3], pts[0], Palette.GOLD, 1.3, true)
	draw_circle(at + Vector2(-1.6, -2.2), 1.6, Color(1, 1, 1, 0.8))

func _result_color() -> Color:
	match _result:
		"perfect": return Palette.PERFECT
		"early": return Palette.RAGE
		_: return Palette.CRIMSON

func _result_text() -> String:
	match _result:
		"perfect": return "PERFECT!"
		"early": return "EARLY — NO FLOW"
		_: return "LATE — NO FLOW"
