## StatsPage — THE FULL REPORT (STATS PAGE v2). The deep, number-heavy post-fight recap
## that sits behind THE RECKONING's "◆ FULL REPORT" button. Everything here is read from
## engine-truth state (seat.diag grades, state.meter per-source accounting, state.boon_meter
## impact, state.series time-line) — deterministic, identical on every lockstep client, so it
## works online untouched. Pure view layer: reads state, never writes it.
##
## Layout (scrolls inside a ScrollContainer the HUD wraps it in):
##   header · seat tabs · category grades ·
##   LEFT  col: % BREAKDOWN (grades/crit/dodge/interrupt/hits/aggro) · SPEC rows · MISSED
##   RIGHT col: DAMAGE MIX (share bars) · DAMAGE TAKEN · BOON IMPACT (+ raid amplifiers)
##   full-width: DAMAGE OVER TIME graph (boss HP% + per-seat DPS)
class_name StatsPage
extends Control

const PAD := 34.0
const COL_GAP := 28.0
const HEAD_H := 96.0
const TAB_H := 30.0
const GRAPH_H := 190.0
const SECT_GAP := 20.0
const ROW := 22.0

var _ctrl                       # CombatController (duck-typed .state / .player())
var _recap: Dictionary          # the HUD's view-side tallies (kicks/parries/strikes…)
var _focus_i := -1              # seats[] index being inspected (-1 = the player)
var _hits: Array = []           # click regions: {rect, i}
var _content_h := 900.0

func _init(ctrl, recap_stats: Dictionary = {}) -> void:
	_ctrl = ctrl
	_recap = recap_stats
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(1120, _content_h)

func _state() -> CombatState:
	return _ctrl.state if _ctrl != null else null

func _focus(s: CombatState) -> int:
	if _focus_i >= 0 and _focus_i < s.seats.size():
		return _focus_i
	var p = _ctrl.player() if _ctrl != null else null
	var i: int = s.seats.find(p) if p != null else -1
	return maxi(i, 0)

func _seat_name(seat: Seat) -> String:
	if seat != null and seat.unit_name != "":
		return seat.unit_name
	return "You" if (seat != null and seat.is_player) else "Ally"

func _accent(seat: Seat) -> Color:
	if seat == null or seat.kit == null:
		return Palette.STEEL
	var scr: Script = seat.kit.get_script()
	match (String(scr.get_global_name()) if scr != null else ""):
		"BulwarkKit": return Palette.GOLD
		"TwinfangKit": return Palette.FLOW
		"AlchemistKit": return Palette.VENOM_BREW
		"WellKit": return Palette.WATER
		"BloomweaverKit": return Palette.VERDANCE
		_: return Palette.STEEL

# ---------------------------------------------------------------- input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h["rect"] as Rect2).has_point(event.position):
				_focus_i = int(h["i"])
				accept_event()
				queue_redraw()
				return

# ---------------------------------------------------------------- draw
func _draw() -> void:
	_hits = []
	var s := _state()
	if s == null:
		return
	var w := size.x
	# ---- page backdrop ----
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.028, 0.024, 0.05, 1.0)
	plate.set_corner_radius_all(10)
	plate.border_color = Palette.EDGE
	plate.set_border_width_all(1)
	draw_style_box(plate, Rect2(0, 0, w, maxf(size.y, _content_h)))
	draw_line(Vector2(14, 1), Vector2(w - 14, 1), Palette.GOLD_DIM, 1.4, true)

	var fi := _focus(s)
	var seat: Seat = s.seats[fi] if fi < s.seats.size() else null

	# ---- header ----
	UiKit.text_shadowed(self, UiKit.display(750, 3), Vector2(0, 40), "· COMBAT REPORT ·",
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["TITLE"], Palette.GOLD)
	var secs := float(s.tick) * s.dt
	var dur := "%d:%04.1f" % [int(secs) / 60, fmod(secs, 60.0)] if secs >= 60.0 else "%.1fs" % secs
	var ename := String(s.encounter.name) if s.encounter != null else "Encounter"
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, 62),
		"%s   ·   %s   ·   %s" % [ename, dur, ("VICTORY" if s.won else "WIPE")],
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["BODY"],
		Palette.WIN if s.won else Palette.LOSE)

	# ---- seat tabs (raid only) ----
	var y := HEAD_H
	if s.seats.size() > 1:
		var tw := 150.0
		var tx := (w - tw * float(s.seats.size())) * 0.5
		for i in s.seats.size():
			var st: Seat = s.seats[i]
			var sel := i == fi
			var r := Rect2(tx, y, tw - 6, TAB_H - 4)
			_hits.append({"rect": Rect2(tx, y, tw, TAB_H), "i": i})
			var ac := _accent(st)
			draw_rect(r, Color(ac.r, ac.g, ac.b, 0.26 if sel else 0.08))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), ac if sel else Palette.EDGE)
			var nm := _seat_name(st) + (" ◆" if st.is_player else "")
			if not st.alive():
				nm += " †"
			UiKit.text_shadowed(self, UiKit.body(600 if sel else 500), Vector2(tx, y + 20),
				nm, HORIZONTAL_ALIGNMENT_CENTER, tw, UiKit.SIZE["CAPTION"],
				Palette.GOLD_BRIGHT if sel else Palette.TEXT_DIM)
			tx += tw
		y += TAB_H + 8.0

	# ---- category grade badges ----
	y = _draw_grades(s, seat, y, w)
	y += SECT_GAP

	# ---- two columns ----
	var col_w := (w - PAD * 2.0 - COL_GAP) * 0.5
	var lx := PAD
	var rx := PAD + col_w + COL_GAP
	var ly := y
	var ry := y

	ly = _sect(lx, ly, col_w, "PERFORMANCE BREAKDOWN")
	ly = _draw_breakdown(s, seat, fi, lx, ly, col_w)
	ly += SECT_GAP
	var spec := (seat.kit.recap_spec(s, seat) if seat != null and seat.kit != null else [])
	if not spec.is_empty():
		ly = _sect(lx, ly, col_w, "SPEC · " + _spec_name(seat))
		ly = _draw_kv(spec, lx, ly, col_w)
		ly += SECT_GAP
	ly = _sect(lx, ly, col_w, "MISSED OPPORTUNITIES")
	ly = _draw_missed(s, seat, fi, lx, ly, col_w)

	ry = _sect(rx, ry, col_w, "DAMAGE MIX")
	ry = _draw_mix(s, fi, "dmg", rx, ry, col_w)
	ry += SECT_GAP
	ry = _sect(rx, ry, col_w, "DAMAGE TAKEN")
	ry = _draw_mix(s, fi, "taken", rx, ry, col_w)
	ry += SECT_GAP
	ry = _sect(rx, ry, col_w, "BOON IMPACT")
	ry = _draw_boons(s, fi, rx, ry, col_w)

	# ---- full-width graph ----
	var gy := maxf(ly, ry) + SECT_GAP
	gy = _sect(PAD, gy, w - PAD * 2.0, "DAMAGE OVER TIME")
	gy = _draw_graph(s, PAD, gy, w - PAD * 2.0)

	var need := gy + PAD
	if absf(need - _content_h) > 4.0:
		_content_h = need
		custom_minimum_size = Vector2(1120, _content_h)

# ---------------------------------------------------------------- sections
func _sect(x: float, y: float, w: float, title: String) -> float:
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(x, y + 12), title,
		HORIZONTAL_ALIGNMENT_LEFT, w, UiKit.SIZE["LABEL"], Palette.GOLD)
	draw_line(Vector2(x, y + 18), Vector2(x + w, y + 18), Palette.GOLD_DIM.darkened(0.2), 1.0, true)
	return y + 26.0

## a labelled proportion bar: label (left) · value (right) · fill ∝ frac
func _bar(label: String, value: String, frac: float, col: Color, x: float, y: float, w: float) -> float:
	var bh := 15.0
	draw_rect(Rect2(x, y, w, bh), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(x, y, w * clampf(frac, 0.0, 1.0), bh), Color(col.r, col.g, col.b, 0.5))
	UiKit.text_shadowed(self, UiKit.body(600), Vector2(x + 6, y + 12), label,
		HORIZONTAL_ALIGNMENT_LEFT, w * 0.62, UiKit.SIZE["CAPTION"], Palette.TEXT)
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, y + 12), value,
		HORIZONTAL_ALIGNMENT_RIGHT, x + w - 6, UiKit.SIZE["CAPTION"], Palette.GOLD_BRIGHT)
	return y + bh + 4.0

## a plain label:value line (no bar)
func _line(label: String, value: String, hint: String, col: Color, x: float, y: float, w: float) -> float:
	UiKit.text_shadowed(self, UiKit.body(600), Vector2(x + 2, y + 12), label,
		HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, UiKit.SIZE["CAPTION"], Palette.TEXT)
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, y + 12), value,
		HORIZONTAL_ALIGNMENT_RIGHT, x + w - 2, UiKit.SIZE["CAPTION"], col)
	if hint != "":
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(x + 2, y + 24), hint,
			HORIZONTAL_ALIGNMENT_LEFT, w, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		return y + 30.0
	return y + ROW

# ---------------------------------------------------------------- category grades
func _draw_grades(s: CombatState, seat: Seat, y: float, w: float) -> float:
	var d: Dictionary = seat.diag if seat != null else {}
	var cats := [
		["OFFENSE", _pct_offense(d)],
		["DEFENSE", _pct_defense(d)],
		["DISCIPLINE", _pct_discipline(s, d)],
	]
	var bw := 200.0
	var bx := (w - bw * float(cats.size())) * 0.5
	for c in cats:
		var pct: float = c[1]
		if pct < 0.0:
			continue
		var letter := _letter(pct)
		var col := _grade_col(pct)
		UiKit.text_shadowed(self, UiKit.display(800, 2), Vector2(bx, y + 34), letter,
			HORIZONTAL_ALIGNMENT_CENTER, bw, UiKit.SIZE["DISPLAY"], col)
		UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(bx, y + 52), String(c[0]),
			HORIZONTAL_ALIGNMENT_CENTER, bw, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		bx += bw
	return y + 60.0

func _pct_offense(d: Dictionary) -> float:
	# window sharpness: tempo strike windows if present, else dodge-grade quality
	var sharp := int(d.get("s_bull", 0)) + int(d.get("s_perfect", 0)) + int(d.get("s_good", 0))
	var all := sharp + int(d.get("s_miss", 0))
	if all >= 3:
		return 100.0 * float(sharp) / float(all)
	var good := int(d.get("perfect", 0)) + int(d.get("good", 0))
	var tot := good + int(d.get("graze", 0)) + int(d.get("miss", 0))
	return (100.0 * float(good) / float(tot)) if tot >= 3 else -1.0

func _pct_defense(d: Dictionary) -> float:
	var clean := int(d.get("perfect", 0)) + int(d.get("good", 0)) + int(d.get("graze", 0)) + int(d.get("read", 0))
	var bad := int(d.get("miss", 0)) + int(d.get("baited", 0)) + int(d.get("whiff", 0))
	var tot := clean + bad
	return (100.0 * float(clean) / float(tot)) if tot >= 3 else -1.0

func _pct_discipline(s: CombatState, d: Dictionary) -> float:
	# start at 100, dock for strays / whiffs / uncontested casts you could have answered
	var strays := int(d.get("stray_hit", 0))
	var whiffs := int(d.get("whiff", 0))
	var uncon := int(s.diag.get("kick_open_missed", 0))
	var faults := strays + whiffs + uncon
	if faults == 0 and int(d.get("miss", 0)) == 0:
		return 100.0
	return maxf(0.0, 100.0 - float(faults) * 6.0 - float(int(d.get("miss", 0))) * 4.0)

func _letter(pct: float) -> String:
	if pct >= 92.0: return "S"
	if pct >= 82.0: return "A"
	if pct >= 70.0: return "B"
	if pct >= 55.0: return "C"
	return "D"

func _grade_col(pct: float) -> Color:
	if pct >= 82.0: return Palette.GOLD_BRIGHT
	if pct >= 70.0: return Palette.GOLD
	if pct >= 55.0: return Palette.STEEL
	return Palette.CRIMSON

# ---------------------------------------------------------------- breakdown
func _draw_breakdown(s: CombatState, seat: Seat, fi: int, x: float, y: float, w: float) -> float:
	var d: Dictionary = seat.diag if seat != null else {}
	if d.is_empty() and seat != null and seat.fidelity == "statblock":
		return _line("AI raider (stat-block)", "—", "no timed inputs to grade", Palette.TEXT_DIM, x, y, w)
	# judgment segments (answers to the boss)
	var segs := [
		[int(d.get("perfect", 0)), Palette.GOLD_BRIGHT, "perfect"],
		[int(d.get("good", 0)), Palette.GOLD, "good"],
		[int(d.get("graze", 0)), Palette.STEEL, "graze"],
		[int(d.get("read", 0)), Palette.RELIC, "read"],
		[int(d.get("baited", 0)) + int(d.get("whiff", 0)), Palette.CRIMSON.darkened(0.15), "baited/whiff"],
		[int(d.get("miss", 0)), Palette.CRIMSON, "hit"],
	]
	var tot := 0
	for sg in segs:
		tot += int(sg[0])
	if tot > 0:
		var bx := x
		var bw := w
		draw_rect(Rect2(bx, y, bw, 16), Color(0, 0, 0, 0.4))
		for sg in segs:
			var n := int(sg[0])
			if n == 0:
				continue
			var sw := bw * float(n) / float(tot)
			draw_rect(Rect2(bx, y, sw - 1.0, 16), sg[1])
			bx += sw
		y += 22.0
		# per-grade % legend
		for sg in segs:
			var n2 := int(sg[0])
			if n2 == 0:
				continue
			y = _bar(String(sg[2]), "%d%%  (%d)" % [int(round(100.0 * float(n2) / float(tot))), n2],
				float(n2) / float(tot), sg[1], x, y, w)
		y += 6.0
	# hard counters — crit rate, times hit, interrupts, aggro
	var row: Dictionary = s.meter.get(fi, {})
	var dmg_by: Dictionary = row.get("dmg", {})
	var hits := 0
	var crits := 0
	for src in dmg_by:
		hits += int(dmg_by[src]["n"])
		crits += int(dmg_by[src]["crit_n"])
	if hits > 0:
		y = _line("Crit rate", "%d%%" % int(round(100.0 * float(crits) / float(hits))),
			"%d crits of %d hits" % [crits, hits], Palette.GOLD, x, y, w)
	var taken_n := 0
	var taken_by: Dictionary = row.get("taken", {})
	for src in taken_by:
		taken_n += int(taken_by[src]["n"])
	y = _line("Times hit", str(taken_n), "%d dmg taken" % int(float(row.get("taken_total", 0.0))),
		Palette.CRIMSON if taken_n > 0 else Palette.TEXT, x, y, w)
	# interrupts (view tally) + uncontested casts (engine, raid-wide)
	var kicks := int(_recap.get("kicks", 0))
	if kicks > 0:
		y = _line("Interrupts", str(kicks),
			"%d clean · %d heals denied" % [int(_recap.get("clean_kicks", 0)), int(_recap.get("denials", 0))],
			Palette.KICK, x, y, w)
	var uncon := int(s.diag.get("kick_open_missed", 0))
	if uncon > 0:
		y = _line("Casts let finish", str(uncon), "kickable casts went uncontested", Palette.CRIMSON, x, y, w)
	# aggro / strays (raid)
	if s.threat_enabled and seat != null and seat.role != "tank":
		var pulls := int(d.get("aggro_pulled", 0))
		var strays := int(d.get("stray_hit", 0))
		if pulls > 0 or strays > 0:
			y = _line("Aggro pulled", str(pulls), "%d stray hits taken off the tank" % strays,
				Palette.CRIMSON, x, y, w)
	return y

# ---------------------------------------------------------------- damage mix
func _draw_mix(s: CombatState, fi: int, mode: String, x: float, y: float, w: float) -> float:
	var srcs := MeterPanel._sources(s, fi, mode)
	var col_total := MeterPanel._total(s, fi, mode)
	if srcs.is_empty() or col_total <= 0.0:
		return _line("—", "nothing", "", Palette.TEXT_DIM, x, y, w)
	var top := float(srcs[0][1]["total"])
	var shown := 0
	for e in srcs:
		var entry: Dictionary = e[1]
		var t := float(entry["total"])
		var share := 100.0 * t / maxf(col_total, 1.0)
		var col := Palette.GOLD_BRIGHT if mode == "dmg" else Palette.CRIMSON
		y = _bar(MeterPanel.pretty_src(e[0]), "%d%%  ·  %s" % [int(round(share)), MeterPanel._fmt(t)],
			t / maxf(top, 1.0), col, x, y, w)
		shown += 1
		if shown >= 8:
			break
	return y

# ---------------------------------------------------------------- boon impact
func _draw_boons(s: CombatState, fi: int, x: float, y: float, w: float) -> float:
	var pool: Dictionary = s.boon_meter.get(fi, {})
	var rows: Array = []
	for id in pool:
		var e: Dictionary = pool[id]
		var v := float(e.get("total", 0.0))
		var hv := float(e.get("heal", 0.0))
		if v > 0.5 or hv > 0.5:
			rows.append([id, v, hv])
	rows.sort_custom(func(a, b): return maxf(float(a[1]), float(a[2])) > maxf(float(b[1]), float(b[2])))
	var top := 1.0
	if not rows.is_empty():
		top = maxf(float(rows[0][1]), float(rows[0][2]))
	if rows.is_empty():
		y = _line("—", "no boon signal", "proc/ramp boons show in the mix above", Palette.TEXT_DIM, x, y, w)
	for r in rows:
		var big := maxf(float(r[1]), float(r[2]))
		var unit := "≈ +%s dmg" % MeterPanel._fmt(float(r[1])) if float(r[1]) >= float(r[2]) else "≈ +%s heal" % MeterPanel._fmt(float(r[2]))
		y = _bar(_boon_name(String(r[0])), unit, big / maxf(top, 1.0), Palette.FLOW, x, y, w)
	# drafted-but-silent boons (the player seat only) listed dim
	var seat: Seat = s.seats[fi] if fi < s.seats.size() else null
	if seat != null and seat.kit != null:
		var silent: Array = []
		for bid in seat.kit.boons:
			if not pool.has(StringName(bid)):
				silent.append(_boon_name(String(bid)))
		if not silent.is_empty():
			y += 2.0
			y = _line("no measured impact", "", ", ".join(silent), Palette.TEXT_DIM, x, y, w)
	# raid-wide amplifiers (glint / sunder / debilitate)
	var amp: Dictionary = s.boon_meter.get(-1, {})
	if not amp.is_empty():
		y += 4.0
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(x + 2, y + 10), "RAID AMPLIFIERS",
			HORIZONTAL_ALIGNMENT_LEFT, w, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		y += 16.0
		var arows: Array = []
		for id in amp:
			arows.append([id, float(amp[id].get("total", 0.0))])
		arows.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
		var atop := (float(arows[0][1]) if not arows.is_empty() else 1.0)
		for r in arows:
			if float(r[1]) < 0.5:
				continue
			y = _bar(_boon_name(String(r[0])), "≈ +%s raid dmg" % MeterPanel._fmt(float(r[1])),
				float(r[1]) / maxf(atop, 1.0), Palette.EXPOSE, x, y, w)
	return y

# ---------------------------------------------------------------- spec rows
func _draw_kv(rows: Array, x: float, y: float, w: float) -> float:
	for r in rows:
		var rd: Dictionary = r
		y = _line(String(rd.get("label", "")), String(rd.get("value", "")),
			String(rd.get("hint", "")), Palette.GOLD, x, y, w)
	return y

# ---------------------------------------------------------------- missed opportunities
func _draw_missed(s: CombatState, seat: Seat, fi: int, x: float, y: float, w: float) -> float:
	var d: Dictionary = seat.diag if seat != null else {}
	var items: Array = []          # [severity, text]
	var ow := int(d.get("open_whiff", 0))
	if ow > 0:
		items.append([ow, "%d dumps landed outside the Opening — center the window for the bonus" % ow])
	var wf := int(d.get("whiff", 0))
	if wf > 0:
		items.append([wf, "%d dodges thrown too early — wait for the beat" % wf])
	var bt := int(d.get("baited", 0))
	if bt > 0:
		items.append([bt, "%d feints bitten — hold when it's a bait" % bt])
	var sm := int(d.get("s_miss", 0))
	if sm > 0:
		items.append([sm, "%d strike windows missed — tighten the tempo" % sm])
	var ms := int(d.get("miss", 0))
	if ms > 0:
		items.append([ms, "%d avoidable hits taken — answer the telegraph" % ms])
	var uncon := int(s.diag.get("kick_open_missed", 0))
	if uncon > 0:
		items.append([uncon, "%d kickable casts went uncontested" % uncon])
	var strays := int(d.get("stray_hit", 0))
	if strays > 0 and seat != null and seat.role != "tank":
		items.append([strays, "%d stray hits — you out-threated the tank" % strays])
	if items.is_empty():
		return _line("Clean fight", "—", "nothing stood out", Palette.WIN, x, y, w)
	items.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	var n := mini(3, items.size())
	for i in n:
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(x + 4, y + 12),
			"• " + String(items[i][1]), HORIZONTAL_ALIGNMENT_LEFT, w - 4,
			UiKit.SIZE["CAPTION"], Palette.TEXT)
		y += ROW
	return y

# ---------------------------------------------------------------- graph
func _draw_graph(s: CombatState, x: float, y: float, w: float) -> float:
	var series: Array = s.series
	var gh := GRAPH_H
	draw_rect(Rect2(x, y, w, gh), Color(0, 0, 0, 0.3))
	if series.size() < 2:
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(x, y + gh * 0.5), "· fight too short to chart ·",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		return y + gh
	var last: Array = series[series.size() - 1]
	var t_max := maxf(1.0, float(last[0]))
	# per-second DPS peak for the y-scale (differentiate cumulative columns)
	var nseat := s.seats.size()
	var dps_peak := 1.0
	for k in range(1, series.size()):
		var a: Array = series[k - 1]
		var b: Array = series[k]
		var span := maxf(1.0, (float(b[0]) - float(a[0])) * s.dt)
		for si in mini(nseat, 4):
			var dps := (float(b[2 + si]) - float(a[2 + si])) / span
			dps_peak = maxf(dps_peak, dps)
	# boss HP% line (crimson) across the top-to-bottom band
	var pts_hp: PackedVector2Array = []
	for r in series:
		var px := x + w * clampf(float(r[0]) / t_max, 0.0, 1.0)
		var py := y + gh - gh * clampf(float(r[1]) / 100.0, 0.0, 1.0)
		pts_hp.append(Vector2(px, py))
	if pts_hp.size() >= 2:
		draw_polyline(pts_hp, Palette.CRIMSON, 1.6, true)
	# per-seat DPS lines
	for si in mini(nseat, 4):
		var seat: Seat = s.seats[si]
		var col := _accent(seat)
		var pts: PackedVector2Array = []
		for k in range(1, series.size()):
			var a2: Array = series[k - 1]
			var b2: Array = series[k]
			var span2 := maxf(1.0, (float(b2[0]) - float(a2[0])) * s.dt)
			var dps2 := (float(b2[2 + si]) - float(a2[2 + si])) / span2
			var px2 := x + w * clampf(float(b2[0]) / t_max, 0.0, 1.0)
			var py2 := y + gh - gh * clampf(dps2 / dps_peak, 0.0, 1.0)
			pts.append(Vector2(px2, py2))
		if pts.size() >= 2:
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.9), 1.4, true)
	# legend
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(x + 6, y + 14), "boss HP%",
		HORIZONTAL_ALIGNMENT_LEFT, 120, UiKit.SIZE["MICRO"], Palette.CRIMSON)
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "lines = per-seat DPS  ·  peak %s/s" % MeterPanel._fmt(dps_peak),
		HORIZONTAL_ALIGNMENT_RIGHT, x + w - 6, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
	return y + gh

# ---------------------------------------------------------------- names
func _spec_name(seat: Seat) -> String:
	if seat == null or seat.kit == null:
		return ""
	var scr: Script = seat.kit.get_script()
	match (String(scr.get_global_name()) if scr != null else ""):
		"TwinfangKit": return "Twinfang"
		"AlchemistKit": return "Alchemist"
		"WellKit": return "The Well"
		"BulwarkKit": return "Bulwark"
		"BloomweaverKit": return "Bloomweaver"
		_: return ""

## boon id -> readable name (best-effort; unknown ids get a capitalized fallback)
static var BOON_NAMES := {
	"tightrope": "Tightrope", "overdrive": "Double Time", "theBrink": "The Brink",
	"rig_expose": "Expose (rig)", "rig_empower": "Overcharge (rig)", "execute": "Finish It",
	"serrated": "Serrated Fate", "assassinsNote": "Assassin's Note", "opening": "The Opening",
	"onTheBeat": "On the Beat", "pressAdvantage": "Press the Advantage", "coldOpen": "Cold Open",
	"throughline": "Through-Line", "glint": "Glint", "sunder": "Sunder", "debilitate": "Debilitate",
	"spitfire": "Spitfire", "decant": "Decant", "reduction": "Reduction",
}

func _boon_name(id: String) -> String:
	return String(BOON_NAMES.get(id, id.capitalize()))
