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
var bull_frac: float = 0.18    ## GRADED WINDOW (§2c): Bullseye = centre this fraction of the half-window
var perfect_frac: float = 0.55 ## …Perfect = centre this fraction; the flanks between it and the edge are GOOD
var scale_ticks: int = 33     ## FIXED time-scale denominator (constant, NOT perfect_hi) so the
                              ## accelerando is visible: as the window shrinks it slides LEFT on a
                              ## fixed ruler instead of the whole bar rescaling with it.
var flow: int = 0            ## Tempo/Fermata: drives the "how fast is the beat" readout
var flow_max: int = 6
# FERMATA: the coil (hold-release) state — the bar dims while coiling, the needle carries a
# charge ring that fills to the SHNK, and the cue line reads coil→sharp→release instead of tap.
var fermata: bool = false
var coiling: bool = false
var coil_charge: float = 0.0   ## 0..1 toward sharp
var coil_sharp: bool = false
var _pulse: float = 0.0
var _result: String = ""      ## "perfect" | "early" | "late"
var _result_t: float = 0.0    ## fade timer for the verdict flash
var _press_f: float = 0.0     ## track fraction where the last Strike landed
var _prev_prog: float = 0.0   ## last frame's needle position (pre-reset)
var _prev_aim_f: float = 0.0  ## last frame's aim-line position (snapshot with the press)
var _press_aim_f: float = 0.0 ## where the ideal beat sat when you pressed
var _press_off_ticks: float = 0.0  ## signed ticks off the aim line (+ = late of it, − = early)
var _bull: bool = false        ## a Perfect landed within ~50ms of the aim line

## Called by the HUD when a Strike lands (drained from the combat event stream).
func show_result(r: String) -> void:
	_result = r
	_result_t = HOLD
	_press_f = _prev_prog     # the needle has already snapped back — remember where it was
	# Snapshot the aim line WITH the press so an accelerando shift during the 0.55s hold
	# can't relabel how far off the ideal beat you were.
	_press_aim_f = _prev_aim_f
	var hi := maxf(1.0, float(maxi(scale_ticks, perfect_hi + 2)))
	_press_off_ticks = (_press_f - _press_aim_f) * hi
	_bull = _result == "perfect" and absf(_press_off_ticks) <= 1.5   # ~50ms — the flourish only

func _process(delta: float) -> void:
	_pulse += delta * 8.0
	if _result_t > 0.0:
		_result_t = maxf(0.0, _result_t - delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	# Normalize to a FIXED scale, never perfect_hi — otherwise the accelerando is invisible
	# (the whole bar would rescale with the shrinking window). On a fixed ruler the green
	# window visibly moves EARLIER and NARROWS as Flow climbs, and the needle reaches it sooner.
	var hi := maxf(1.0, float(maxi(scale_ticks, perfect_hi + 2)))
	var early_f := clampf(float(swing_min) / hi, 0.0, 1.0)
	var lo_f := clampf(float(perfect_lo) / hi, 0.0, 1.0)          # green START (the window mouth)
	var hi_f := clampf(float(perfect_hi) / hi, 0.0, 1.0)          # green END (bounded — no more overshoot)
	var aim_tick := (float(perfect_lo) + float(perfect_hi)) * 0.5 # the bullseye = max margin either side
	var aim_f := clampf(aim_tick / hi, 0.0, 1.0)
	var near := clampf(1.0 - absf(float(since) - aim_tick) / 2.0, 0.0, 1.0)  # needle proximity to the plumb (±2t)
	var prog := clampf(float(since) / hi, 0.0, 1.0)
	var in_green := since >= perfect_lo and since <= perfect_hi
	var past := since > perfect_hi
	var flashing := _result_t > 0.0
	var fa := clampf(_result_t / HOLD, 0.0, 1.0)   # 1 -> 0 fade

	# ---- header: plaque + live cue + TEMPO readout (the accelerando made explicit) ----
	UiKit.engraved_plaque(self, Vector2(76.0, 10.0), "STRIKE TIMING", in_green)
	if flow > 0:
		# Flow = BPM: a row of chevrons that light + a "×N" as the beat quickens, hotter at max.
		var fmax := maxi(flow_max, 1)
		var hot := float(flow) / float(fmax)
		var tcol := Palette.PERFECT.lerp(Palette.RAGE, hot)
		var cx0 := w - 128.0
		for i in fmax:
			var lit := i < flow
			var ca := 0.9 if lit else 0.18
			var cc := tcol if lit else Palette.TEXT_DIM
			var chx := cx0 + float(i) * 9.0
			draw_line(Vector2(chx, 16.0), Vector2(chx + 5.0, 12.0), Color(cc.r, cc.g, cc.b, ca), 2.0, true)
			draw_line(Vector2(chx, 16.0), Vector2(chx + 5.0, 20.0), Color(cc.r, cc.g, cc.b, ca), 2.0, true)
		UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(0, 12.0),
			"TEMPO ×%.1f — beat's faster!" % (1.0 + hot * 0.6) if flow >= fmax else "TEMPO ×%.1f" % (1.0 + hot * 0.6),
			HORIZONTAL_ALIGNMENT_RIGHT, w - 18.0, UiKit.SIZE["CAPTION"], tcol)
	else:
		var cue := "hold 1, release in the green" if fermata else "tap 1 in the green"
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(0, 14.0), cue,
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

	# ---- the PERFECT window — a BOUNDED emerald band [perfect_lo, perfect_hi] ----
	# Bounded on BOTH sides (the old fill ran to the track edge, so late-but-in-view read
	# as green). A brighter core pulls the eye toward the plumb without narrowing the hit
	# test — the whole band still scores Perfect; the plumb is just where you AIM.
	var lo_x := tx + tw * lo_f
	var hi_x := tx + tw * hi_f
	var aim_x := tx + tw * aim_f
	var bw := maxf(hi_x - lo_x, 2.0)
	var gem_r := clampf(bw * 0.15, 3.0, 5.0)   # boundary gems shrink when the band pinches (accelerando)
	var gz := Palette.PERFECT
	gz.a = 0.20 + (0.20 if in_green else 0.0)
	draw_rect(Rect2(lo_x, ty + 2, bw - 1, th - 4), gz)
	# GRADED WINDOW (§2c): the flat band above is the GOOD zone (it LANDS, no Flow). A
	# brighter PERFECT core and a gold BULLSEYE centre show where the beat actually scores —
	# the whole point of aiming dead-centre now that the flanks only tread water.
	var half := bw * 0.5
	var pf := clampf(perfect_frac, 0.05, 1.0)
	var bf := clampf(bull_frac, 0.02, pf)
	var core := Palette.PERFECT.lightened(0.18)
	core.a = 0.22 + 0.16 * near + (0.10 if in_green else 0.0)
	draw_rect(Rect2(aim_x - half * pf, ty + 3, half * pf * 2.0, th - 6), core)
	var bull := Palette.GOLD_BRIGHT
	bull.a = 0.30 + 0.28 * near + (0.12 if in_green else 0.0)
	draw_rect(Rect2(aim_x - half * bf, ty + 4, half * bf * 2.0, th - 8), bull)
	# inner glow border + gloss
	var ig := Palette.PERFECT
	ig.a = 0.45 if in_green else 0.25
	draw_rect(Rect2(lo_x + 1, ty + 3, bw - 3, th - 6), ig, false, 1.2)
	draw_rect(Rect2(lo_x + 1, ty + 3, bw - 3, th * 0.30), Color(1, 1, 1, 0.10))
	if in_green and bw > 16.0:      # travelling shimmer while the press would be Perfect
		var sx := lo_x + fmod(_pulse * 34.0, maxf(bw - 8.0, 1.0))
		var sh := Palette.PERFECT.lightened(0.5)
		sh.a = 0.38
		draw_rect(Rect2(sx, ty + 3, 7.0, th - 6), sh)

	# ---- the "too LATE" reach past perfect_hi — amber, the mirror of the crimson early wall ----
	# so the green now has an unmistakable END: early-fail (crimson, back-lean) and late-fail
	# (amber→crimson, forward-lean) bracket the band. A late press still LANDS but earns no Flow.
	var late_w := (tx + tw) - hi_x
	if late_w > 1.0:
		var late := Palette.RAGE
		late.a = 0.28
		draw_rect(Rect2(hi_x, ty + 2, late_w - 2, th - 4), late)
		var deep := Palette.CRIMSON_DEEP    # opportunity visibly runs out toward the edge
		deep.a = 0.20
		draw_rect(Rect2(hi_x + late_w * 0.45, ty + 2, late_w * 0.55 - 2, th - 4), deep)
		for hx in range(int(hi_x) + 6, int(tx + tw) - 2, 11):
			draw_line(Vector2(float(hx) - 4.0, ty + 4.0), Vector2(float(hx) + 6.0, ty + th - 4.0),
				Color(0, 0, 0, 0.22), 2.0, true)

	# ---- three gem-set mullions: early wall · green OPEN · green CLOSE ----
	for bd in [[tx + ex, Palette.GOLD_DIM, Palette.CRIMSON_DEEP.lightened(0.15), false, gem_r],
			[lo_x, Palette.PERFECT, Palette.PERFECT.darkened(0.1), in_green, gem_r],
			[hi_x, Palette.PERFECT, Palette.PERFECT, in_green, gem_r + 0.5]]:
		var bx: float = bd[0]
		var accent: Color = bd[1]
		var gembody: Color = bd[2]
		var glow: bool = bd[3]
		var gr: float = bd[4]
		draw_line(Vector2(bx, ty + 2), Vector2(bx, ty + th - 2), Palette.BG0, 3.0, true)
		draw_line(Vector2(bx + 1.0, ty + 2), Vector2(bx + 1.0, ty + th - 2), accent, 1.5, true)
		_gem(Vector2(bx, ty - 3.0), gr, gembody, glow)

	# ---- THE AIM PLUMB — a thin STATIONARY gilded sight through the band centre ----
	# Gold (not mint) + still (not sweeping) + sight-post chevrons (not a diamond head) so it
	# never reads as the moving needle. It LOCKS ON: bloom + pip brighten as the needle nears.
	if near > 0.0:
		var bloom := Palette.GOLD_BRIGHT
		bloom.a = 0.10 + 0.30 * near
		draw_rect(Rect2(aim_x - (3.0 + 3.0 * near), ty - 2.0, 2.0 * (3.0 + 3.0 * near), th + 4.0), bloom)
	# a dark seat for contrast, a bold gilded stroke, and a crisp white hairline core so the
	# target reads as a definite AIM-HERE line at all times — the whole green still scores.
	draw_line(Vector2(aim_x, ty - 6.0), Vector2(aim_x, ty + th + 6.0), Palette.BG0, 3.0, true)
	var acol := Palette.GOLD_BRIGHT
	acol.a = 0.82 + 0.18 * near
	draw_line(Vector2(aim_x, ty - 6.0), Vector2(aim_x, ty + th + 6.0), acol, 1.6, true)
	draw_line(Vector2(aim_x, ty - 4.0), Vector2(aim_x, ty + th + 4.0), Color(1, 1, 1, 0.45 + 0.40 * near), 0.7, true)
	_sight_post(Vector2(aim_x, ty - 7.0), 1.0, near)
	_sight_post(Vector2(aim_x, ty + th + 7.0), -1.0, near)
	_gem(Vector2(aim_x, ty + th * 0.5), 3.4 + 1.4 * near,
		Palette.GOLD_BRIGHT if near > 0.5 else Palette.GOLD, near > 0.6)

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
		# offset connector — SEE how far the press landed from the ideal beat (the plumb)
		var conn := Palette.GOLD_BRIGHT if _bull else _result_color()
		conn.a = 0.55 * fa
		draw_line(Vector2(px, ty - 12.0), Vector2(aim_x, ty - 12.0), conn, 1.0, true)
		draw_line(Vector2(px, ty - 15.0), Vector2(px, ty - 9.0), conn, 1.0, true)
		draw_line(Vector2(aim_x, ty - 15.0), Vector2(aim_x, ty - 9.0), conn, 1.0, true)
		if _result == "perfect":
			var reach := 9.0 + (7.0 if _bull else 0.0)   # tighter aim → longer, brighter rays
			for k in 6:
				var a := TAU * float(k) / 6.0 - PI / 2.0
				var d := Vector2(cos(a), sin(a))
				var rc := Palette.GOLD_BRIGHT
				rc.a = (0.95 if _bull else 0.8) * fa
				draw_line(Vector2(px, ty - 8.0) + d * (br + 2.0), Vector2(px, ty - 8.0) + d * (br + reach), rc, 1.6, true)
			if _bull:      # dead-centre flourish
				var ring := Palette.PERFECT
				ring.a = 0.7 * fa
				draw_arc(Vector2(px, ty - 8.0), 14.0, 0.0, TAU, 28, ring, 2.0, true)

	# ---- the gilded needle: motion trail, shaft, diamond head ----
	var mx := tx + tw * prog
	var mcol := Palette.PERFECT if in_green else (Palette.CRIMSON if past else Color(0.85, 0.87, 0.92))
	if fermata and coiling and not in_green and not past:
		mcol = Color(0.72, 0.62, 1.0)   # coiled: the needle rides umbra-violet — you're in shadow
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

	# ---- FERMATA: the coil socket — a FIXED charge ring on the left end-cap (off the needle;
	# a marker-chasing ring read as noise). The violet arc fills to the SHNK, then the whole
	# ring runs white-hot while the release is live. The needle's umbra tint carries the rest.
	if fermata and coiling:
		var umbra := Color(0.72, 0.62, 1.0)
		var ctr := Vector2(tx, ty + th * 0.5)
		var rr := 14.0
		draw_arc(ctr, rr, 0.0, TAU, 40, Color(umbra.r, umbra.g, umbra.b, 0.25), 3.0, true)
		if coil_sharp:
			var hot := Color(1, 1, 1, 0.80 + 0.20 * sin(_pulse * 1.4))   # white-hot pulse = release-live
			draw_arc(ctr, rr, 0.0, TAU, 40, hot, 3.5, true)
		else:
			var fill := TAU * clampf(coil_charge, 0.0, 1.0)
			draw_arc(ctr, rr, -PI / 2.0, -PI / 2.0 + fill, 40, umbra, 3.5, true)

	# ---- frame: 2-tone bevel, filigree corners, diamond end-caps ----
	draw_line(track.position, Vector2(tx + tw, ty), Palette.GOLD_BRIGHT, 1.6, true)
	draw_line(track.position, Vector2(tx, ty + th), Palette.GOLD, 1.6, true)
	draw_line(Vector2(tx, ty + th), track.end, Palette.GOLD_DIM, 1.6, true)
	draw_line(Vector2(tx + tw, ty), track.end, Palette.GOLD_DIM, 1.6, true)
	UiKit.filigree_corner(self, Vector2(tx - 2, ty - 2), Vector2(1, 1), 8.0)
	UiKit.filigree_corner(self, Vector2(tx + tw + 2, ty - 2), Vector2(-1, 1), 8.0)
	_gem(Vector2(tx, ty + th * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1), false)
	# right cap now terminates the LATE reach, not the green — amber until you're truly past
	_gem(Vector2(tx + tw, ty + th * 0.5), 8.0, (Palette.CRIMSON if past else Palette.RAGE).darkened(0.15), past)

	# ---- the message line beneath the track ----
	var my := ty + th + 22.0
	if fermata and coiling and not flashing:
		# FERMATA cue: coiling → sharpen → (in green) release. Overrides the tap cues while held.
		var umb := Color(0.72, 0.62, 1.0)
		if not coil_sharp:
			UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(0, my), "coiling…",
				HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], umb)
		elif in_green:
			UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(0, my), "RELEASE!",
				HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["HEADER"],
				Color(1, 1, 1, 0.6 + 0.4 * sin(_pulse)))
		elif past:
			UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(0, my), "LATE — RELEASE NOW",
				HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], Palette.RAGE)
		else:
			UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(0, my), "sharp — wait for green…",
				HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], umb)
	elif flashing:
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
	_prev_aim_f = aim_f

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
	if _bull:
		return "BULLSEYE!"
	match _result:
		"perfect":
			# high-granularity feedback: how many ms off the ideal beat you were
			return "PERFECT!  %+.0f ms" % (_press_off_ticks * (1000.0 / 30.0))
		"early": return "EARLY — NO FLOW"
		_: return "LATE — NO FLOW"

## an inward sight-post chevron that points at the aim plumb (dir +1 above the track / −1 below),
## fattening + brightening as the needle locks on. Together the two form the bullseye crosshair.
func _sight_post(at: Vector2, dir: float, near: float) -> void:
	var sz := 4.0 + 1.5 * near
	var col := Palette.GOLD_BRIGHT
	col.a = 0.70 + 0.30 * near
	var lft := Vector2(at.x - sz, at.y - dir * sz)
	var rgt := Vector2(at.x + sz, at.y - dir * sz)
	draw_line(lft, at, col, 2.0, true)
	draw_line(rgt, at, col, 2.0, true)
	var hl := Color(1, 1, 1, 0.25 + 0.30 * near)   # a specular edge so it reads as cut metal
	draw_line(lft, at, hl, 1.0, true)
