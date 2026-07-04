## OpeningBar — THE OPENING, the blade's offense-side timing gauge. Where the RhythmBar is
## a cool metronome of YOUR cadence, this is a molten WOUND that reads the BOSS: a
## telegraphed swing overextends it, a vulnerability window tears open around the impact,
## and you slam a DUMP (Eviscerate / Coup / Rupture / Flurry) into the bright core — right
## when/around/after the boss hits. Gilded Reliquary grammar: gold frame + filigree, an
## engraved plaque caption, a crimson→ember wound that breathes, a sweet-spot that IGNITES
## when the needle enters it, a sweeping plumb needle with a motion trail, and a spark-burst
## PUNISH! on a peak read. Pure view — fed each frame from observe()'s open_* fields.
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

# animation state (all view-only)
var _pulse: float = 0.0
var _ignite: float = 0.0        ## 0→1 glow ramp while the needle sits in the window
var _arm_glow: float = 0.0      ## 0→1 ramp while a dump is ready
var _trail: Array[float] = []   ## recent needle x-fractions → motion trail
var _result: String = ""        ## "peak" | "hit" | "whiff"
var _result_t: float = 0.0
var _result_x: float = 0.0
var _burst_t: float = 0.0       ## PUNISH spark-burst timer

const HOLD := 0.72
const LEAD := 44.0              ## ticks of run-up drawn before the peak (~1.47s)
const TAIL := 16.0              ## ticks drawn after the peak (~0.53s)
const PAD := 14.0

func show_result(r: String) -> void:
	_result = r
	_result_t = HOLD
	_result_x = _track_x(_tf(float(now_tick)))
	if r == "peak":
		_burst_t = 1.0

func _process(delta: float) -> void:
	_pulse += delta * 5.0
	var in_win := active and now_tick >= from_tick and now_tick <= to_tick
	_ignite = move_toward(_ignite, 1.0 if in_win else 0.0, delta * (7.0 if in_win else 4.0))
	_arm_glow = move_toward(_arm_glow, 1.0 if (armed and active) else 0.0, delta * 5.0)
	if _result_t > 0.0: _result_t -= delta
	if _burst_t > 0.0: _burst_t = maxf(0.0, _burst_t - delta * 1.7)
	if active:
		_trail.push_back(_tf(float(now_tick)))
		while _trail.size() > 7: _trail.pop_front()
	elif not _trail.is_empty():
		_trail.clear()
	queue_redraw()

## absolute tick → 0..1 across the visible span (peak sits near the right).
func _tf(t: float) -> float:
	return clampf((t - (float(peak_tick) - LEAD)) / (LEAD + TAIL), 0.0, 1.0)

## 0..1 span fraction → x pixel inside the padded track.
func _track_x(f: float) -> float:
	return PAD + f * (size.x - PAD * 2.0)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ty := h * 0.42
	var th := h * 0.40
	var trk_l := PAD
	var trk_w := w - PAD * 2.0
	var in_win := active and now_tick >= from_tick and now_tick <= to_tick

	# ---- gilded frame (glass panel + gold border + filigree corners) ----
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(Palette.FILL_BOT.r, Palette.FILL_BOT.g, Palette.FILL_BOT.b, 0.80)
	panel.border_color = Palette.GOLD_DIM if not in_win else Palette.GOLD
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(7)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 5
	var frame := Rect2(2.0, ty - 12.0, w - 4.0, th + 30.0)
	draw_style_box(panel, frame)
	UiKit.filigree_corner(self, frame.position, Vector2(1, 1), 11.0)
	UiKit.filigree_corner(self, frame.position + Vector2(frame.size.x, 0), Vector2(-1, 1), 11.0)
	UiKit.filigree_corner(self, frame.position + Vector2(0, frame.size.y), Vector2(1, -1), 11.0)
	UiKit.filigree_corner(self, frame.position + frame.size, Vector2(-1, -1), 11.0)

	# ---- the incised track groove ----
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.04, 0.03, 0.03, 0.92)
	groove.set_corner_radius_all(4)
	groove.border_color = Palette.BG0
	groove.set_border_width_all(1)
	draw_style_box(groove, Rect2(trk_l, ty, trk_w, th))
	# engraved linear ticks
	for i in 13:
		var gx := trk_l + trk_w * float(i) / 12.0
		draw_line(Vector2(gx, ty + th - 7.0), Vector2(gx, ty + th - 3.0), Palette.BG0, 2.0, true)
		draw_line(Vector2(gx + 0.6, ty + th - 7.0), Vector2(gx + 0.6, ty + th - 3.0),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)

	# ---- caption plaque ----
	var cap := "THE OPENING"
	var lit := false
	if in_win:
		cap = "PUNISH — STRIKE!" if bonus_now >= 0.45 else "OPENING — DUMP"
		lit = true
	elif active:
		cap = "the boss is exposed…"
		lit = _arm_glow > 0.3
	UiKit.engraved_plaque(self, Vector2(w * 0.5, ty - 10.0), cap, lit, 10)

	if not active:
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(trk_l, ty + th * 0.5 + 5.0),
			"watch for the swing", HORIZONTAL_ALIGNMENT_CENTER, trk_w, 13,
			Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.5))
		_draw_verdict(trk_l, trk_w, ty, th)
		return

	# ---- the WOUND (vulnerability window): crimson→ember, breathing outer glow ----
	var wx0 := _track_x(_tf(float(from_tick)))
	var wx1 := _track_x(_tf(float(to_tick)))
	var breath := 0.5 + 0.5 * sin(_pulse * 1.3)
	# soft outer bloom (concentric fading rects)
	for g in range(4, 0, -1):
		var gm := float(g)
		var gc := Palette.CRIMSON.lerp(Palette.GOLD, 0.25)
		gc.a = (0.05 + 0.05 * breath + 0.06 * _ignite) * (1.0 - gm / 5.0) * 1.4
		draw_rect(Rect2(wx0 - gm * 2.0, ty + 1.0 - gm, wx1 - wx0 + gm * 4.0, th - 2.0 + gm * 2.0), gc)
	# the wound body — a crimson→ember horizontal gradient
	var segs := 22
	for i in segs:
		var f0 := float(i) / float(segs)
		var sx := lerpf(wx0, wx1, f0)
		var sw := (wx1 - wx0) / float(segs) + 1.0
		var wc := Palette.CRIMSON_DEEP.lerp(Palette.CRIMSON, 0.4 + 0.6 * f0)
		wc = wc.lerp(Palette.GOLD, 0.20 * f0 + 0.25 * _ignite)
		wc.a = 0.42 + 0.30 * _ignite
		draw_rect(Rect2(sx, ty + 2.0, sw, th - 4.0), wc)

	# ---- the molten CORE (sweet spot) — ignites when the needle enters ----
	var cx0 := _track_x(_tf(float(peak_tick - core_ticks)))
	var cx1 := _track_x(_tf(float(peak_tick + core_ticks)))
	var cw := maxf(cx1 - cx0, 3.0)
	# core bloom
	for g in range(3, 0, -1):
		var gm2 := float(g)
		var cb := Palette.GOLD_BRIGHT
		cb.a = (0.10 + 0.22 * _ignite) * (1.0 - gm2 / 4.0)
		draw_rect(Rect2(cx0 - gm2 * 2.0, ty - gm2, cw + gm2 * 4.0, th + gm2 * 2.0), cb)
	var core := Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.4 + 0.6 * _ignite)
	core.a = 0.55 + 0.35 * _ignite
	draw_rect(Rect2(cx0, ty + 2.0, cw, th - 4.0), core)
	# white-hot center seam
	var seam := Color(1.0, 0.97, 0.86, 0.5 + 0.4 * _ignite)
	var px := _track_x(_tf(float(peak_tick)))
	draw_line(Vector2(px, ty + 1.0), Vector2(px, ty + th - 1.0), seam, 2.0, true)
	# travelling shimmer inside the core while live
	if _ignite > 0.4 and cw > 8.0:
		var shx := cx0 + fmod(_pulse * 30.0, maxf(cw - 5.0, 1.0))
		draw_rect(Rect2(shx, ty + 3.0, 4.0, th - 6.0), Color(1, 1, 1, 0.35 * _ignite))

	# ---- boundary gems (window edges) + peak gem ----
	var gy := ty + th * 0.5
	UiKit.gilded_pip(self, Vector2(wx0, gy), 3.2, false, Palette.CRIMSON)
	UiKit.gilded_pip(self, Vector2(wx1, gy), 3.2, false, Palette.CRIMSON)
	UiKit.gilded_pip(self, Vector2(px, ty - 3.0), 3.6, true, Palette.GOLD_BRIGHT)

	# ---- the needle (now), with a motion trail ----
	for i in _trail.size():
		var tf := _trail[i]
		var a := float(i + 1) / float(_trail.size())
		var txp := _track_x(tf)
		draw_line(Vector2(txp, ty + 2.0), Vector2(txp, ty + th - 2.0),
			Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.10 * a), 2.0, true)
	var nf := _tf(float(now_tick))
	var nx := _track_x(nf)
	# proximity to peak → needle warms steel→gold→white
	var prox := clampf(1.0 - absf(float(now_tick) - float(peak_tick)) / maxf(LEAD, 1.0), 0.0, 1.0)
	var ncol := Palette.STEEL.lerp(Palette.GOLD, prox)
	if in_win: ncol = Palette.GOLD.lerp(Color(1, 1, 1), _ignite * 0.6)
	# armed aura
	if _arm_glow > 0.02:
		draw_line(Vector2(nx, ty - 3.0), Vector2(nx, ty + th + 3.0),
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.22 * _arm_glow), 6.0, true)
	draw_line(Vector2(nx, ty - 4.0), Vector2(nx, ty + th + 4.0), ncol, 2.4, true)
	# needle head — a small gilded plumb
	draw_circle(Vector2(nx, ty - 4.0), 3.4, ncol)
	draw_circle(Vector2(nx, ty - 4.0) - Vector2(1.0, 1.0), 1.1, Color(1, 1, 1, 0.7))

	# ---- PUNISH spark-burst at the strike point ----
	if _burst_t > 0.0:
		var bt := _burst_t
		var by := ty + th * 0.5
		var bc := Vector2(_result_x, by)
		# expanding ring
		var rr := (1.0 - bt) * 30.0 + 4.0
		draw_arc(bc, rr, 0.0, TAU, 28, Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.6 * bt), 2.0, true)
		# radial spokes
		for k in 10:
			var ang := TAU * float(k) / 10.0 + 0.3
			var d := Vector2(cos(ang), sin(ang))
			var r0 := (1.0 - bt) * 10.0 + 3.0
			var r1 := r0 + 6.0 + bt * 8.0
			draw_line(bc + d * r0, bc + d * r1,
				Color(1.0, 0.92, 0.7, 0.8 * bt), 2.0, true)

	_draw_verdict(trk_l, trk_w, ty, th)

func _draw_verdict(_l: float, _w: float, ty: float, _th: float) -> void:
	if _result_t <= 0.0:
		return
	var a := clampf(_result_t / HOLD, 0.0, 1.0)
	var grow := 1.0 + (1.0 - a) * 0.4
	var txt := ""
	var vc := Palette.GOLD
	var sz := 18
	match _result:
		"peak":
			txt = "PUNISH!"; vc = Palette.GOLD_BRIGHT; sz = 22
		"hit":
			txt = "opening"; vc = Palette.GOLD; sz = 16
		"whiff":
			txt = "no opening"; vc = Palette.STEEL; sz = 14
	vc.a = a
	var f := UiKit.display(700, 1)
	var fs := int(sz * grow)
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var vx := clampf(_result_x - tw * 0.5, 2.0, size.x - tw - 2.0)
	UiKit.text_shadowed(self, f, Vector2(vx, ty - 16.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, vc)
