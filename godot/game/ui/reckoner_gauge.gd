## THE FORGE — Bellows & Anvil: the Reckoner's two-timer swing instrument.
## A big linear WIND bellows bar (weight zones + a fixed EVEN aim gate + a sweeping
## hammer-notch with motion ghosts) stacked ABOVE a radial contracting ANVIL ring (the
## falling blade closing at constant speed onto a fixed emerald TRUE hub). Flanked by a
## Momentum pip-ladder + a Poise-Break meter that cracks to STAGGER, topped by a scale-
## punched VERDICT banner, and footed by a paired grade-history rail.
##   phase: 0 WIND · 1 STRIKE(apex) · 2 ULTRASWING · 3 onslaught-wind · 4 onslaught-strike.
## Pure view: the HUD feeds observe() fields each frame + pushes the combat event stream
## via on_event(); nothing here touches state.
class_name ReckonerGauge
extends Control

var aspect := "colossus"
var seat_ref = null            ## the player Seat — on_event filters raid events to it

# --- live fields fed each frame (from observe) ---
var phase := 0
var since_wind := 0
var wind_len := 27
var even_lo := 9
var heavy_lo := 18
var over_lo := 23
var over_armed := false
var to_apex := 999
var apex_total := 12
var true_half := 1
var momentum := 0.0
var momentum_max := 8.0
var poise := 0.0
var poise_max := 100.0
var stagger := false
var seq_nw := 0
var seq_ns := 0

# --- feedback state (driven by on_event) ---
var _pulse := 0.0
var _banner := ""
var _banner_col := Palette.GOLD_BRIGHT
var _banner_t := 0.0
var _commit_flash := 0.0
var _commit_col := Palette.GOLD
var _wind_stamp := {}          # {x_frac, col, t}
var _ring_burst := {}          # {col, t, rays}
var _history: Array = []       # [{wcol, whollow, pcol, big}] newest last, max 8
var _hist_pop := 0.0
var _pending := {}             # the wind gem awaiting its strike pair

const VERDICT_HOLD := 0.85
const STAMP_HOLD := 0.5

func _process(delta: float) -> void:
	_pulse += delta * 3.0
	_banner_t = maxf(0.0, _banner_t - delta)
	_commit_flash = maxf(0.0, _commit_flash - delta * 8.0)
	_hist_pop = maxf(0.0, _hist_pop - delta * 3.0)
	if _wind_stamp.has("t"):
		_wind_stamp["t"] = float(_wind_stamp["t"]) - delta
		if float(_wind_stamp["t"]) <= 0.0:
			_wind_stamp = {}
	if _ring_burst.has("t"):
		_ring_burst["t"] = float(_ring_burst["t"]) - delta
		if float(_ring_burst["t"]) <= 0.0:
			_ring_burst = {}
	queue_redraw()

# ------------------------------------------------------------------ feedback
func _set_banner(word: String, col: Color, punch := 1.0) -> void:
	_banner = word
	_banner_col = col
	_banner_t = VERDICT_HOLD * punch

## Held-verdict pop from the HUD's react() convenience (kind: true/over/clash/stagger/ultra).
func react(kind: String) -> void:
	match kind:
		"true", "perfect": _set_banner("TRUE!", Palette.PERFECT)
		"over": _set_banner("OVERSWING!", Palette.HEAVY)
		"clash": _set_banner("CLASH!", Palette.GOLD_BRIGHT, 1.1)
		"stagger": _set_banner("STAGGER!", Palette.GOLD_BRIGHT, 1.1)
		"ultra": _set_banner("ULTRA!", Palette.KICK)
		"onslaught": _set_banner("ONSLAUGHT!", Palette.PERFECT, 1.2)

## The combat event stream — derives stamps / banner / history from the kit's view events.
func on_event(ev: Dictionary) -> void:
	if seat_ref != null:
		if ev.has("seat"):
			if ev["seat"] != seat_ref:
				return
		elif not bool(ev.get("player", false)):
			return
	match String(ev.get("t", "")):
		"wind_commit":
			var wt := String(ev.get("weight", "Even"))
			var forced := bool(ev.get("forced", false))
			var col := _weight_col(wt)
			_commit_flash = 1.0
			_commit_col = col
			_wind_stamp = {"x_frac": clampf(float(ev.get("frac", 0.5)), 0.0, 1.0), "col": col, "t": STAMP_HOLD}
			_pending = {"col": col, "hollow": forced}
			if forced:
				_set_banner("TOO SLOW", Palette.STEEL, 0.8)
			else:
				_set_banner(wt.to_upper() + (" ARMED" if wt == "Over" else ""), col, 0.85)
		"swing":
			var power := String(ev.get("power", ""))
			var weight := String(ev.get("weight", ""))
			var clash := bool(ev.get("clash", false))
			var pcol := _power_col(power, weight, clash)
			_ring_burst = {"col": pcol, "t": STAMP_HOLD, "rays": (power == "True" or clash)}
			_set_banner(_verdict_word(power, weight, clash), pcol, 1.15 if (power == "True" or clash) else 0.95)
			_push_pair(_pending.get("col", Palette.STEEL), bool(_pending.get("hollow", false)),
				pcol, (power == "True" or clash))
			_pending = {}
		"poise_break": _set_banner("STAGGER!", Palette.GOLD_BRIGHT, 1.1)
		"ultra": _set_banner("ULTRA!", Palette.KICK)
		"onslaught": _set_banner("ONSLAUGHT — ALL TRUE!" if bool(ev.get("all_true", false)) else "ONSLAUGHT", Palette.PERFECT, 1.2)
		"negate": _set_banner("CLASH!", Palette.GOLD_BRIGHT, 1.1)

func _push_pair(wcol: Color, whollow: bool, pcol: Color, big: bool) -> void:
	_history.append({"wcol": wcol, "whollow": whollow, "pcol": pcol, "big": big})
	while _history.size() > 8:
		_history.pop_front()
	_hist_pop = 1.0

# ------------------------------------------------------------------ palette
func _weight_col(w: String) -> Color:
	match w:
		"Quick": return Palette.STEEL
		"Even": return Palette.GOLD
		"Heavy": return Palette.HEAVY
		"Over", "Brink": return Palette.CRIMSON
		"Snap": return Palette.PERFECT
	return Palette.GOLD
func _power_col(power: String, weight: String, clash: bool) -> Color:
	if clash: return Palette.GOLD_BRIGHT
	if weight == "Over": return Palette.HEAVY
	match power:
		"True": return Palette.PERFECT
		"Overload": return Palette.HEAVY
		"Finesse": return Palette.GOLD
	return Palette.STEEL
func _verdict_word(power: String, weight: String, clash: bool) -> String:
	if clash: return "CLASH!"
	if weight == "Over": return "OVERSWING!"
	match power:
		"True": return "TRUE!"
		"Overload": return "OVERLOAD"
		"Finesse": return "FINESSE"
	return "GLANCE"
func _weight_at_frac(f: float) -> String:
	var qf := float(even_lo) / maxf(1.0, float(wind_len))
	var ef := float(heavy_lo) / maxf(1.0, float(wind_len))
	var ov := float(over_lo) / maxf(1.0, float(wind_len))
	if over_armed and f >= ov: return "OVER"
	if f < qf: return "QUICK"
	if f < ef: return "EVEN"
	return "HEAVY"

# ------------------------------------------------------------------ draw
func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 220.0 or h < 140.0:
		return
	_draw_panel(w, h)
	_draw_wind(w, h, phase == 0 or phase == 3)
	_draw_anvil(w, h, phase == 1 or phase == 2 or phase == 4)
	_draw_momentum(w, h)
	_draw_poise(w, h)
	_draw_history(w, h)
	if phase == 3 or phase == 4 or seq_nw > 0 or seq_ns > 0:
		_draw_phrase(w, h)
	_draw_banner(w, h)

func _draw_panel(w: float, h: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.026, 0.052, 0.74)
	sb.border_color = Palette.EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	draw_style_box(sb, Rect2(0, 0, w, h))
	UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1))
	UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1))
	UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1))
	UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1))

func _draw_banner(w: float, h: float) -> void:
	var cx := w * 0.5
	var y := h * 0.115
	if _banner_t > 0.0 and _banner != "":
		var f := _banner_t / VERDICT_HOLD
		var scale := 1.0 + 0.32 * f * f          # scale-punch: overshoot then settle
		var a := clampf(0.35 + f, 0.0, 1.0)
		var col := Color(_banner_col.r, _banner_col.g, _banner_col.b, a)
		var fnt := UiKit.display(750, 2)
		var sz := int(UiKit.SIZE["GAUGE"] * scale)
		UiKit.text_shadowed(self, fnt, Vector2(cx - 320, y - sz * 0.5), _banner,
			HORIZONTAL_ALIGNMENT_CENTER, 640, sz, col)
	else:
		var cue := ""
		var ccol := Palette.TEXT_DIM
		if phase == 0:
			var f := clampf(float(since_wind) / maxf(1.0, float(wind_len)), 0.0, 1.0)
			var qf := float(even_lo) / maxf(1.0, float(wind_len))
			var ef := float(heavy_lo) / maxf(1.0, float(wind_len))
			if over_armed and f >= float(over_lo) / maxf(1.0, float(wind_len)):
				cue = ">>  OVERSWING  <<"; ccol = Palette.HEAVY
			elif f >= qf and f < ef:
				cue = ">>  COMMIT  <<"; ccol = Palette.GOLD_BRIGHT
			else:
				cue = "WIND — COMMIT"; ccol = Palette.TEXT_DIM
		elif phase == 1:
			cue = "STRIKE — THE APEX"; ccol = Palette.PERFECT
		elif phase == 2:
			cue = "ULTRASWING — TAP"; ccol = Palette.KICK
		elif phase == 3:
			cue = "ONSLAUGHT — WIND %d/3" % (seq_nw + 1); ccol = Palette.PERFECT
		elif phase == 4:
			cue = "ONSLAUGHT — STRIKE %d/3" % (seq_ns + 1); ccol = Palette.PERFECT
		var pa := 0.7 + 0.3 * sin(_pulse * 2.0) if ccol != Palette.TEXT_DIM else 0.85
		UiKit.text_shadowed(self, UiKit.display(700, 3), Vector2(cx - 300, y - 10),
			cue, HORIZONTAL_ALIGNMENT_CENTER, 600, UiKit.SIZE["TITLE"],
			Color(ccol.r, ccol.g, ccol.b, pa))

func _draw_wind(w: float, h: float, active: bool) -> void:
	var bw := w * 0.62
	var bx := w * 0.19
	var by := h * 0.23
	var bh := 44.0
	var rect := Rect2(bx, by, bw, bh)
	UiKit.glass_bar_draw(self, rect, 0.0, Palette.GOLD)
	var qf := float(even_lo) / maxf(1.0, float(wind_len))
	var ef := float(heavy_lo) / maxf(1.0, float(wind_len))
	var ov := float(over_lo) / maxf(1.0, float(wind_len))
	var zones: Array = [[0.0, qf, Palette.STEEL, "QUICK", false], [qf, ef, Palette.GOLD, "EVEN", true]]
	if over_armed:
		zones.append([ef, ov, Palette.HEAVY, "HEAVY", false])
		zones.append([ov, 1.0, Palette.CRIMSON, "OVER", false])
	else:
		zones.append([ef, 1.0, Palette.HEAVY, "HEAVY", false])
	var live_f := clampf(float(since_wind) / maxf(1.0, float(wind_len)), 0.0, 1.0)
	for z in zones:
		var x0 := bx + bw * float(z[0])
		var x1 := bx + bw * float(z[1])
		var zc: Color = z[2]
		var money: bool = z[4]
		var lit_zone: bool = active and live_f >= float(z[0]) and live_f < float(z[1])
		var base_a := (0.9 if money else 0.42) * (1.0 if active else 0.5)
		if lit_zone:
			base_a = 1.0
		draw_rect(Rect2(x0 + 1, by + 3, maxf(1.0, x1 - x0 - 2), bh - 6), Color(zc.r, zc.g, zc.b, base_a), true)
		if money:
			# EVEN money core + a travelling shimmer
			draw_rect(Rect2(x0 + 2, by + bh * 0.32, maxf(1.0, x1 - x0 - 4), bh * 0.36), Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.5 if active else 0.25), true)
			if active:
				var sh := x0 + fmod(_pulse * 30.0, maxf(1.0, x1 - x0))
				draw_rect(Rect2(sh, by + 3, 5, bh - 6), Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.35), true)
		if lit_zone:
			draw_rect(Rect2(x0 + 1, by + 1, maxf(1.0, x1 - x0 - 2), bh - 2), zc, false, 1.6)
		# engraved divider
		draw_line(Vector2(x1, by), Vector2(x1, by + bh), Palette.BG0, 1.5, true)
	# commit-flash wash
	if _commit_flash > 0.0:
		draw_rect(rect, Color(_commit_col.r, _commit_col.g, _commit_col.b, 0.30 * _commit_flash), true)
	# fixed EVEN aim gate (the target)
	var gx := bx + bw * 0.5
	draw_line(Vector2(gx, by - 7), Vector2(gx, by + bh + 7), Palette.GOLD_BRIGHT, 1.5, true)
	draw_circle(Vector2(gx, by - 9), 3.0, Palette.GOLD_BRIGHT)
	# zone plaques
	var plq_y := by - 18.0
	for z in zones:
		var midx := bx + bw * (float(z[0]) + float(z[1])) * 0.5
		if (float(z[1]) - float(z[0])) > 0.14:
			UiKit.engraved_plaque(self, Vector2(midx, plq_y), String(z[3]),
				active and live_f >= float(z[0]) and live_f < float(z[1]), 10)
	# the live hammer-notch + motion ghosts + weight label
	if active:
		var nx := bx + bw * live_f
		var ncol := Palette.GOLD_BRIGHT
		# urgency: warm to crimson near the end
		if live_f > 0.72:
			ncol = Palette.GOLD_BRIGHT.lerp(Palette.CRIMSON, clampf((live_f - 0.72) / 0.28, 0.0, 1.0))
			draw_circle(Vector2(nx, by + bh * 0.5), 9.0 + 3.0 * sin(_pulse * 4.0), Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.28))
		for gi in 3:
			var gx2 := nx - float(gi + 1) * 7.0
			if gx2 > bx:
				draw_rect(Rect2(gx2 - 1.5, by - 3, 3, bh + 6), Color(ncol.r, ncol.g, ncol.b, 0.20 * (1.0 - float(gi) / 3.0)), true)
		draw_rect(Rect2(nx - 2.5, by - 8, 5, bh + 16), ncol, true)
		UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(nx - 40, by - 34),
			_weight_at_frac(live_f), HORIZONTAL_ALIGNMENT_CENTER, 80, UiKit.SIZE["LABEL"], ncol)
	# the frozen wind stamp (last commit)
	if _wind_stamp.has("t"):
		var sf := float(_wind_stamp["t"]) / STAMP_HOLD
		var sx := bx + bw * float(_wind_stamp["x_frac"])
		var scol: Color = _wind_stamp["col"]
		draw_line(Vector2(sx, by - 4), Vector2(sx, by + bh + 4), Color(scol.r, scol.g, scol.b, sf), 2.0, true)
		draw_arc(Vector2(sx, by + bh * 0.5), 6.0 + 24.0 * (1.0 - sf), 0.0, TAU, 20, Color(scol.r, scol.g, scol.b, sf * 0.8), 2.0, true)

func _draw_anvil(w: float, h: float, active: bool) -> void:
	var c := Vector2(w * 0.5, h * 0.70)
	var R := minf(h * 0.27, 86.0)
	var hub := R * 0.16
	# bezel + ticks + hub
	UiKit.gilded_ring(self, c, R + 8.0, 5.0, 48)
	UiKit.engraved_ticks(self, c, R - 4.0, R + 6.0, 24)
	draw_circle(c, hub, Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.55 if active else 0.22))
	draw_arc(c, hub, 0.0, TAU, 22, Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.9 if active else 0.35), 2.0, true)
	if active:
		var t := clampf(float(to_apex) / maxf(1.0, float(apex_total)), -0.4, 1.1)
		var r := maxf(6.0, hub + (R - hub) * t)
		var near := absi(to_apex) <= true_half
		var col := Palette.PERFECT if near else (Palette.CRIMSON if t < 0.0 else Palette.GOLD_BRIGHT)
		# glow ramp as it closes
		draw_arc(c, r, 0.0, TAU, 44, Color(col.r, col.g, col.b, 0.28), 12.0, true)
		draw_arc(c, r, 0.0, TAU, 44, col, 5.0, true)
		if near:
			draw_circle(c, hub * 1.5, Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.5))
			UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(c.x - 60, c.y - 11),
				"NOW", HORIZONTAL_ALIGNMENT_CENTER, 120, UiKit.SIZE["TITLE"], Palette.PERFECT)
	# the ring burst (apex verdict)
	if _ring_burst.has("t"):
		var bf := float(_ring_burst["t"]) / STAMP_HOLD
		var bcol: Color = _ring_burst["col"]
		draw_arc(c, hub + 36.0 * (1.0 - bf), 0.0, TAU, 40, Color(bcol.r, bcol.g, bcol.b, bf), 3.0, true)
		if bool(_ring_burst.get("rays", false)):
			for i in 8:
				var a := TAU * float(i) / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * (hub + 6), c + d * (hub + 6 + 22 * bf), Color(bcol.r, bcol.g, bcol.b, bf * 0.9), 2.0, true)

func _draw_momentum(w: float, h: float) -> void:
	var n := maxi(1, int(round(momentum_max)))
	var lit := int(floor(momentum))
	var x := w * 0.05
	var y0 := h * 0.78
	var step := (h * 0.42) / float(n)
	for i in n:
		var y := y0 - step * float(i)
		UiKit.gilded_pip(self, Vector2(x, y), 5.0, i < lit, Palette.MOMENTUM)
	UiKit.engraved_plaque(self, Vector2(x, y0 + 22.0), "MOMENTUM", lit > 0, 10)

func _draw_poise(w: float, h: float) -> void:
	var x := w * 0.92
	var by := h * 0.22
	var bh := h * 0.50
	var bw := 24.0
	draw_rect(Rect2(x, by, bw, bh), Palette.BG1, true)
	var f := clampf(poise / maxf(1.0, poise_max), 0.0, 1.0)
	var col := Palette.STEEL
	if stagger:
		col = Palette.GOLD_BRIGHT
	elif f > 0.75:
		col = Palette.STEEL.lightened(0.2 + 0.2 * sin(_pulse * 4.0))
	draw_rect(Rect2(x, by + bh * (1.0 - f), bw, bh * f), col, true)
	# crack lines as it nears full
	if f > 0.5:
		for i in 3:
			var cy := by + bh * (0.3 + 0.2 * float(i))
			draw_line(Vector2(x, cy), Vector2(x + bw, cy - 6), Color(0, 0, 0, 0.4 * f), 1.0, true)
	UiKit.gilded_ring(self, Vector2(x + bw * 0.5, by + bh * 0.5), 0.0, 4, 4)
	draw_rect(Rect2(x, by, bw, bh), Palette.GOLD_DIM, false, 1.5)
	UiKit.engraved_plaque(self, Vector2(x + bw * 0.5, by - 14.0), "STAGGER" if stagger else "POISE", stagger, 10)

func _draw_history(w: float, h: float) -> void:
	var rx := w * 0.84
	var y := h * 0.925
	for i in range(_history.size() - 1, -1, -1):
		var e: Dictionary = _history[i]
		var age := _history.size() - 1 - i
		var a := clampf(1.0 - float(age) * 0.11, 0.25, 1.0)
		var px := rx - float(age) * 34.0
		# wind gem (small) then strike gem (larger)
		var wc: Color = e["wcol"]
		draw_circle(Vector2(px - 9, y), 3.5, Color(wc.r, wc.g, wc.b, a))
		if bool(e.get("whollow", false)):
			draw_circle(Vector2(px - 9, y), 2.0, Color(0.05, 0.05, 0.08, a))
		var pc: Color = e["pcol"]
		var pr := 6.0 if bool(e.get("big", false)) else 4.5
		if i == _history.size() - 1 and _hist_pop > 0.0:
			pr *= 1.0 + 0.6 * _hist_pop
		draw_circle(Vector2(px, y), pr, Color(pc.r, pc.g, pc.b, a))
		UiKit.gilded_ring(self, Vector2(px, y), pr, 1.5, 12)

func _draw_phrase(w: float, h: float) -> void:
	var cx := w * 0.5
	var y := h * 0.055
	var total := 6
	var gap := 26.0
	var x0 := cx - gap * 2.5
	for i in total:
		var on := (i < 3 and i < seq_nw) or (i >= 3 and (i - 3) < seq_ns)
		var col := Palette.GOLD if i < 3 else Palette.PERFECT
		UiKit.gilded_pip(self, Vector2(x0 + gap * float(i), y), 6.0, on, col)
