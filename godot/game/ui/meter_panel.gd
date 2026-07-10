## MeterPanel — the DPS/HPS meter window (Recount, reliquary-styled). A right-rail
## glass plaque that reads `state.meter` (engine-truth accounting, never checksummed)
## live each frame:
##   COMPACT — one bar per combatant, ranked: name · total · DPS/HPS (bar ∝ leader).
##   DETAIL  — one combatant's per-SPELL breakdown: total · share · hits · avg · max
##             · crits (damage) / overheal (healing).
## Header click cycles the column (DAMAGE → HEALING → TAKEN); a compact row click
## drills into that combatant; M cycles compact → detail → hidden (session-sticky).
## `frozen` builds the end-screen recap variant (no live NOW readout, no key hints).
## Pure view layer — reads state, never writes it.
class_name MeterPanel
extends Control

const W := 300.0
const HDR := 34.0
const ROW_C := 24.0            # compact row
const ROW_D := 31.0            # detail row (name line + dim stat line)
const FOOT := 18.0

const MODES: Array = ["dmg", "heal", "shield", "taken", "amp", "disc"]
const MODE_NAMES := {"dmg": "DAMAGE DONE", "heal": "HEALING DONE",
	"shield": "SHIELDING DONE", "taken": "DAMAGE TAKEN", "amp": "AMPLIFY ⚡", "disc": "DISCIPLINE 🎯"}
const MODE_RATE := {"dmg": "DPS", "heal": "HPS", "shield": "SPS", "taken": "DTPS", "amp": "AMP", "disc": "CLEAN"}

## AMPLIFY — boon-impact display names. Mirrors StatsPage.BOON_NAMES, kept local so the meter
## widget never depends on the stats page (avoids a class-name reference cycle).
static var BOON_PRETTY := {
	"glint": "Glint", "sunder": "Sunder", "debilitate": "Debilitate",
	"tightrope": "Tightrope", "overdrive": "Double Time", "theBrink": "The Brink",
	"execute": "Finish It", "serrated": "Serrated Fate", "assassinsNote": "Assassin's Note",
	"opening": "The Opening", "onTheBeat": "On the Beat", "pressAdvantage": "Press the Advantage",
	"coldOpen": "Cold Open", "throughline": "Through-Line", "spitfire": "Spitfire",
	"decant": "Decant", "reduction": "Reduction",
	"rig_expose": "Expose (rig)", "rig_empower": "Overcharge (rig)",
}

## source label -> display name, where String.capitalize() isn't enough
static var PRETTY := {
	"attack": "Attack", "hot": "HoT", "ward": "Wards", "debuff": "DoT (Riftrot)",
	"enrage": "Enrage", "perfect": "Perfect Strike", "strike": "Strike",
	"finisher": "Eviscerate", "coup": "Coup de Grâce", "flurry": "Flurry",
	"poison": "Poison", "kick": "Kick", "medit": "Meditation", "flash": "Flash Heal",
	"mend": "Mend", "well": "Welling Tide", "laststand": "Last Stand",
	"perfect_burst": "Perfect Ward", "void_dot": "Void Rot", "lash": "Thornlash",
	"kick_heal": "Kick Recovery", "growth": "Growth", "bloom": "Bloom",
	"wildbloom": "Wildbloom", "renew": "Renew",
}

var mode: String = "dmg"
var frozen := false                 # end-screen recap: static, no NOW/hints
var focus_i := -1                   # detail view: seats[] index (-1 = the player)
var amp_focus := -999               # AMPLIFY drill: -999 = ranking · -1 = raid pool · ≥0 = seat

## session-sticky visibility the M key cycles: 0 compact · 1 detail · 2 hidden
static var view_state := 0

var _ctrl                           # CombatController (duck-typed .state / .player())
var _frozen_detail := false         # end-screen recap drill-down (frozen panels only)
var _hits: Array = []               # click regions rebuilt each draw: {rect, kind, i}
var _now_buf: Array = []            # rolling (time, total) samples for the NOW readout
var _now_rate := 0.0

func _init(ctrl, default_mode := "dmg", frozen_recap := false) -> void:
	_ctrl = ctrl
	mode = default_mode
	frozen = frozen_recap
	mouse_filter = Control.MOUSE_FILTER_STOP

func _state() -> CombatState:
	return _ctrl.state if _ctrl != null else null

## M key: compact -> detail -> hidden -> compact (shared across fights/HUDs)
func cycle() -> void:
	view_state = (view_state + 1) % 3

# ------------------------------------------------------------------ data reads
static func _row(s: CombatState, i: int) -> Dictionary:
	return s.meter.get(i, {})

static func _total(s: CombatState, i: int, m: String) -> float:
	return float(_row(s, i).get(m + "_total", 0.0))

## ranked [ [seat_i, total], ... ] for the mode, zeros dropped
static func _ranking(s: CombatState, m: String) -> Array:
	var out: Array = []
	for i in s.seats.size():
		var t := _total(s, i, m)
		if t > 0.0:
			out.append([i, t])
	out.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return out

## ranked [ [src, entry], ... ] inside one seat's mode dict
static func _sources(s: CombatState, i: int, m: String) -> Array:
	var by: Dictionary = _row(s, i).get(m, {})
	var out: Array = []
	for src in by:
		out.append([src, by[src]])
	out.sort_custom(func(a, b): return float(a[1]["total"]) > float(b[1]["total"]))
	return out

static func pretty_src(src) -> String:
	var k := String(src)
	return String(PRETTY.get(k, k.capitalize()))

static func boon_name(id) -> String:
	var k := String(id)
	return String(BOON_PRETTY.get(k, k.capitalize()))

static func _amp_sum(e: Dictionary) -> float:
	return float(e.get("total", 0.0)) + float(e.get("heal", 0.0))

## AMPLIFY — one row per contributor: each seat's OWN summed boon lift, plus a synthetic RAID
## row (key -1) for the raid-amp pool (Sunder/Glint/Debilitate — credited raid-wide, not to the
## applier). Ranked by total. Returns [[key:int, total], ...].
static func _amp_ranking(s: CombatState) -> Array:
	var out: Array = []
	for key in s.boon_meter:
		var pool: Dictionary = s.boon_meter[key]
		var sum := 0.0
		for bid in pool:
			sum += _amp_sum(pool[bid])
		if sum > 0.5:
			out.append([int(key), sum])
	out.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return out

## AMPLIFY — one contributor's per-boon breakdown, ranked. [[boon_id, entry], ...]
static func _amp_sources(s: CombatState, key: int) -> Array:
	var pool: Dictionary = s.boon_meter.get(key, {})
	var out: Array = []
	for bid in pool:
		if _amp_sum(pool[bid]) > 0.5:
			out.append([bid, pool[bid]])
	out.sort_custom(func(a, b): return _amp_sum(a[1]) > _amp_sum(b[1]))
	return out

func _amp_focused(s: CombatState) -> bool:
	return amp_focus != -999 and not _amp_sources(s, amp_focus).is_empty()

func _amp_label(s: CombatState, key: int) -> String:
	if key < 0:
		return "⚡ Raid amps"
	if key < s.seats.size():
		return _seat_name(s.seats[key])
	return "Seat %d" % key

func _amp_accent(s: CombatState, key: int) -> Color:
	return Palette.EXPOSE if key < 0 else _accent(s.seats[key])

# ---------------------------------------------------------------- DISCIPLINE data
## DISCIPLINE — a seat's clean-answer %: boss telegraphs answered cleanly (perfect/good/graze/
## read) vs eaten (miss/baited/whiff). -1 = fewer than 3 answers (not enough signal to grade).
## Mirrors StatsPage._pct_defense so the live read and the post-fight grade agree.
static func _disc_clean(d: Dictionary) -> float:
	var clean := int(d.get("perfect", 0)) + int(d.get("good", 0)) + int(d.get("graze", 0)) + int(d.get("read", 0))
	var bad := int(d.get("miss", 0)) + int(d.get("baited", 0)) + int(d.get("whiff", 0))
	var tot := clean + bad
	return (100.0 * float(clean) / float(tot)) if tot >= 3 else -1.0

## DISCIPLINE — ranked [[seat_i, clean_pct], ...] over full-fidelity seats. Stat-block AI has no
## timed inputs to grade, so it is skipped. Ungradeable seats (<3 answers, pct -1) sort last.
static func _disc_ranking(s: CombatState) -> Array:
	var out: Array = []
	for i in s.seats.size():
		var seat: Seat = s.seats[i]
		if seat.fidelity == "statblock":
			continue
		out.append([i, _disc_clean(seat.diag)])
	out.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return out

static func _disc_letter(p: float) -> String:
	if p >= 92.0: return "S"
	if p >= 82.0: return "A"
	if p >= 70.0: return "B"
	if p >= 55.0: return "C"
	return "D"

func _disc_col(p: float) -> Color:
	if p >= 82.0: return Palette.GOLD_BRIGHT
	if p >= 70.0: return Palette.GOLD
	if p >= 55.0: return Palette.STEEL
	return Palette.CRIMSON

## DISCIPLINE — a seat's fault tally for the compact hint: times hit (from the taken meter) and
## stray hits taken off the tank (raid non-tanks). Returns [times_hit, strays].
func _disc_faults(s: CombatState, i: int) -> Array:
	var taken_n := 0
	var by: Dictionary = (s.meter.get(i, {}) as Dictionary).get("taken", {})
	for src in by:
		taken_n += int(by[src]["n"])
	var strays := int((s.seats[i].diag as Dictionary).get("stray_hit", 0))
	return [taken_n, strays]

static func _fmt(x: float) -> String:
	if x >= 100000.0:
		return "%.0fk" % (x / 1000.0)
	if x >= 10000.0:
		return "%.1fk" % (x / 1000.0)
	return str(int(round(x)))

static func _fmt_rate(x: float) -> String:
	return ("%.0f" % x) if x >= 99.5 else ("%.1f" % x)

## Class accent — the kit self-declares it (ClassKit.accent()), so a new/reworked class lights
## up the meter the day it merges with no edit here. No-kit (stat-block) seats stay dim.
func _accent(seat: Seat) -> Color:
	if seat == null or seat.kit == null:
		return Palette.TEXT_DIM
	return seat.kit.accent()

func _seat_name(seat: Seat) -> String:
	if seat.unit_name != "":
		return seat.unit_name
	return "You" if seat.is_player else "Ally"

func _focus_seat_i(s: CombatState) -> int:
	if focus_i >= 0 and focus_i < s.seats.size():
		return focus_i
	var p = _ctrl.player() if _ctrl != null else null
	var i: int = s.seats.find(p) if p != null else -1
	return maxi(i, 0)

# ------------------------------------------------------------------ live loop
func _process(delta: float) -> void:
	var s := _state()
	if s == null:
		return
	if not frozen:
		# rolling NOW rate over the last ~5s of the focused seat's column
		var t := s.time()
		_now_buf.append(Vector2(t, _total(s, _focus_seat_i(s), mode)))
		while _now_buf.size() > 2 and _now_buf[0].x < t - 5.0:
			_now_buf.pop_front()
		var span: float = _now_buf[-1].x - _now_buf[0].x
		_now_rate = ((_now_buf[-1].y - _now_buf[0].y) / span) if span > 0.5 else 0.0
	queue_redraw()

# ------------------------------------------------------------------ input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h["rect"] as Rect2).has_point(event.position):
				match String(h["kind"]):
					"mode":
						mode = MODES[(MODES.find(mode) + 1) % MODES.size()]
						_now_buf.clear()
						amp_focus = -999
					"seat":
						focus_i = int(h["i"])
						if frozen:
							_frozen_detail = true
						else:
							view_state = 1
					"ampseat":
						amp_focus = int(h["i"])
					"back":
						focus_i = -1
						amp_focus = -999
						if frozen:
							_frozen_detail = false
						else:
							view_state = 0
				accept_event()
				queue_redraw()
				return

# ------------------------------------------------------------------ draw
func _draw() -> void:
	_hits = []
	var s := _state()
	if s == null:
		return
	if view_state == 2 and not frozen:
		# collapsed chip — discoverable without stealing space
		var chip := Rect2(size.x - 92, 0, 92, 20)
		draw_rect(chip, Color(0.03, 0.026, 0.052, 0.55))
		draw_rect(chip, Palette.EDGE, false, 1.0)
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(chip.position.x, 14),
			"METER · M", HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		return

	var is_amp := mode == "amp"
	var is_disc := mode == "disc"
	var rk: Array
	if is_amp:
		rk = _amp_ranking(s)
	elif is_disc:
		rk = _disc_ranking(s)
	else:
		rk = _ranking(s, mode)
	var detail := (_frozen_detail if frozen else view_state == 1)
	if is_amp:
		detail = _amp_focused(s)               # amp uses amp_focus, not the M-cycle
	elif is_disc:
		detail = false                         # disc is a compact-only scoreboard
	elif rk.size() <= 1:
		detail = true                          # solo duel: the ranking IS you — skip to spells
	var fi := _focus_seat_i(s)

	# ---- content height first (bg fits what's shown; detail adds its crumb line) ----
	var rows: int
	if is_amp:
		rows = maxi((_amp_sources(s, amp_focus).size() if detail else rk.size()), 1)
	elif is_disc:
		rows = maxi(rk.size(), 1)
	else:
		rows = (_sources(s, fi, mode).size() if detail else rk.size())
	var row_h := ROW_D if (detail and not is_amp) else ROW_C
	var h := HDR + 6.0 + (18.0 if detail else 0.0) \
		+ float(rows) * row_h + FOOT + 4.0
	h = maxf(h, HDR + FOOT + 26.0)

	# ---- plaque ----
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.030, 0.026, 0.052, 0.66)
	plate.set_corner_radius_all(8)
	plate.border_color = Palette.EDGE
	plate.set_border_width_all(1)
	draw_style_box(plate, Rect2(0, 0, size.x, h))
	draw_line(Vector2(10, 1), Vector2(size.x - 10, 1), Palette.GOLD_DIM, 1.2, true)

	# ---- header: mode (click to cycle) · clock · NOW ----
	var hdr := Rect2(0, 0, size.x, HDR)
	_hits.append({"rect": hdr, "kind": "mode", "i": 0})
	var secs := s.time()
	var clock := "%d:%04.1f" % [int(secs) / 60, fmod(secs, 60.0)] if secs >= 60.0 else "%.0fs" % secs
	var mname := String(MODE_NAMES[mode])
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(12, 21),
		"◆ " + mname, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, UiKit.SIZE["MICRO"], Palette.GOLD)
	var right := clock
	if not frozen and not s.over and _now_rate > 0.0:
		right = "NOW %s/s · %s" % [_fmt_rate(_now_rate), clock]
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, 21), right,
		HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

	var y := HDR + 2.0
	if is_amp:
		y = _draw_amp(s, rk, y)
	elif is_disc:
		y = _draw_disc(s, rk, y)
	elif detail:
		y = _draw_detail(s, fi, rk, y)
	else:
		y = _draw_compact(s, rk, y)

	# ---- footer hint ----
	if not frozen:
		var hint := "M · view      click title · column"
		if (is_amp and detail) or (detail and rk.size() > 1):
			hint = "M · view      ‹ back to ranking"
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, h - 6.0), hint,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["MICRO"],
			Palette.TEXT_DIM.darkened(0.2))

## COMPACT: ranked combatant bars (bar length ∝ the leader), total + rate.
## series column base for the current mode's per-second sparkline. The 1 Hz series tracks only
## cumulative damage (cols 2-5) and damage-taken (cols 6-9), so only dmg/taken modes get a trace;
## heal/shield/amp/disc return -1 (no sparkline). Column for seat i is base + i.
func _spark_col(m: String) -> int:
	match m:
		"dmg": return 2
		"taken": return 6
		_: return -1

## A faint per-second trace behind a compact row — the shape of the seat's output over the fight,
## from `series` (cumulative col `base+i`, differentiated to per-second, normalized to its own
## peak). Low-alpha under the text so it adds life without clutter. Pure view; reads state.series.
func _draw_spark(s: CombatState, i: int, base: int, rr: Rect2, acc: Color) -> void:
	var ser: Array = s.series
	if ser.size() < 3:
		return
	var col := base + i
	if col >= (ser[0] as Array).size():
		return
	var vals: Array = []
	var peak := 0.0
	for k in range(1, ser.size()):
		var dv := maxf(0.0, float((ser[k] as Array)[col]) - float((ser[k - 1] as Array)[col]))
		vals.append(dv)
		peak = maxf(peak, dv)
	var n := vals.size()
	if peak <= 0.0 or n < 2:
		return
	var pts := PackedVector2Array()
	for k in n:
		var fx := rr.position.x + rr.size.x * float(k) / float(n - 1)
		var fy := rr.position.y + rr.size.y * (1.0 - float(vals[k]) / peak)
		pts.append(Vector2(fx, fy))
	draw_polyline(pts, Color(acc.r, acc.g, acc.b, 0.30), 1.0, true)

func _draw_compact(s: CombatState, rk: Array, y: float) -> float:
	var elapsed := maxf(s.time(), 1.0)
	var top := (float(rk[0][1]) if not rk.is_empty() else 1.0)
	var party := 0.0
	for r in rk:
		party += float(r[1])
	for ri in rk.size():
		var r: Array = rk[ri]
		var i := int(r[0])
		var t := float(r[1])
		var seat: Seat = s.seats[i]
		var acc := _accent(seat)
		var rr := Rect2(8, y + 2, size.x - 16, ROW_C - 5)
		_hits.append({"rect": Rect2(0, y, size.x, ROW_C), "kind": "seat", "i": i})
		# player row wash (sits under the bar so the player is findable at a glance)
		if seat.is_player:
			draw_rect(Rect2(0, y, size.x, ROW_C), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.055))
		# ranked bar (∝ leader) + a brighter leading edge cap
		var bw := rr.size.x * (t / maxf(top, 1.0))
		draw_rect(Rect2(rr.position, Vector2(bw, rr.size.y)), Color(acc.r, acc.g, acc.b, 0.26))
		draw_rect(Rect2(rr.position, Vector2(2.5, rr.size.y)), acc)
		if bw > 6.0:
			draw_rect(Rect2(rr.position.x + bw - 2.0, rr.position.y, 2.0, rr.size.y),
				Color(acc.r, acc.g, acc.b, 0.5))
		# per-second sparkline (dmg/taken modes) — the shape of the fight, behind the text
		var scol := _spark_col(mode)
		if scol >= 0:
			_draw_spark(s, i, scol, Rect2(8, y + 3.0, size.x - 118.0, ROW_C - 8.0), acc.lightened(0.15))
		if not seat.alive():
			draw_rect(rr, Color(0, 0, 0, 0.35))
		var by := y + ROW_C - 8.0
		# rank number — #1 gilded, the rest dim
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(10, by), str(ri + 1),
			HORIZONTAL_ALIGNMENT_LEFT, 16.0, UiKit.SIZE["MICRO"],
			Palette.GOLD if ri == 0 else Palette.TEXT_DIM)
		# name
		var name_col := Palette.GOLD_BRIGHT if seat.is_player else Palette.TEXT
		if not seat.alive():
			name_col = Palette.TEXT_DIM
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(26, by),
			_seat_name(seat) + (" ◆" if seat.is_player else ""),
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 140.0, UiKit.SIZE["CAPTION"], name_col)
		# three right columns: share% (dim) · total (bright) · rate (dim) — never read as one
		var share := (100.0 * t / party) if party > 0.5 else 0.0
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, by), "%d%%" % int(round(share)),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 104, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, by), _fmt(t),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 56, UiKit.SIZE["CAPTION"],
			Palette.GOLD_BRIGHT if seat.is_player else Palette.TEXT)
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, by), _fmt_rate(t / elapsed),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		y += ROW_C
	if rk.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· nothing yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		y += ROW_C
	return y

## DETAIL: one combatant's spells — total · share% · hits/avg/max · crit/overheal.
func _draw_detail(s: CombatState, fi: int, rk: Array, y: float) -> float:
	var seat: Seat = s.seats[fi]
	var acc := _accent(seat)
	var col_total := _total(s, fi, mode)
	# whose spells + back affordance
	var crumb := _seat_name(seat) + " — " + String(MODE_RATE[mode])
	if rk.size() > 1:
		crumb = "‹ " + crumb
		_hits.append({"rect": Rect2(0, y, size.x, 18), "kind": "back", "i": 0})
	var elapsed := maxf(s.time(), 1.0)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(12, y + 12),
		crumb + " %s" % _fmt_rate(_total(s, fi, mode) / elapsed),
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, UiKit.SIZE["MICRO"], acc.lightened(0.2))
	y += 18.0
	var srcs := _sources(s, fi, mode)
	var top := (float(srcs[0][1]["total"]) if not srcs.is_empty() else 1.0)
	for e in srcs:
		var entry: Dictionary = e[1]
		var t := float(entry["total"])
		var rr := Rect2(8, y + 2, size.x - 16, ROW_D - 6)
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * (t / maxf(top, 1.0)), 12.0)),
			Color(acc.r, acc.g, acc.b, 0.22))
		draw_rect(Rect2(rr.position, Vector2(2.5, 12.0)), acc)
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(16, y + 13),
			pretty_src(e[0]), HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.55,
			UiKit.SIZE["CAPTION"], Palette.TEXT)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, y + 13),
			"%s  %d%%" % [_fmt(t), int(round(100.0 * t / maxf(col_total, 1.0)))],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, UiKit.SIZE["CAPTION"], Palette.GOLD_BRIGHT)
		# dim stat line: hits · avg · max, then crits (gold) / overheal (dim)
		var n := int(entry["n"])
		var stat := ""
		if n > 0:
			stat = "%d× · avg %s · max %s" % [n, _fmt(t / float(n)), _fmt(float(entry["max"]))]
		else:
			stat = "continuous"
		var extra := ""
		var extra_col := Palette.TEXT_DIM
		if mode == "heal" and float(entry.get("over", 0.0)) > 0.5:
			var ov := float(entry["over"])
			extra = " · %d%% over" % int(round(100.0 * ov / maxf(t + ov, 1.0)))
		elif int(entry.get("crit_n", 0)) > 0:
			extra = " · %d crit" % int(entry["crit_n"])
			extra_col = Palette.GOLD
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(16, y + ROW_D - 4.0),
			stat, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, UiKit.SIZE["MICRO"],
			Palette.TEXT_DIM.darkened(0.1))
		if extra != "":
			UiKit.text_shadowed(self, UiKit.body(600), Vector2(0, y + ROW_D - 4.0),
				extra.trim_prefix(" · "), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14,
				UiKit.SIZE["MICRO"], extra_col)
		y += ROW_D
	if srcs.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· nothing yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		y += ROW_D
	return y

## AMPLIFY: who enables the raid. Compact = ranked contributors (each seat's own boon lift + a
## RAID row for the shared amp pool); drill a row → that contributor's per-boon "≈ +X". Reads
## state.boon_meter (diag-family, never checksummed) — the live twin of STATS PAGE v2's BOON IMPACT.
func _draw_amp(s: CombatState, rk: Array, y: float) -> float:
	if _amp_focused(s):
		return _draw_amp_detail(s, y)
	if rk.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· no amplify signal yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		return y + ROW_C
	var top := float(rk[0][1])
	var col := 0.0
	for r in rk:
		col += float(r[1])
	for r in rk:
		var key := int(r[0])
		var t := float(r[1])
		var acc := _amp_accent(s, key)
		var rr := Rect2(8, y + 2, size.x - 16, ROW_C - 5)
		_hits.append({"rect": Rect2(0, y, size.x, ROW_C), "kind": "ampseat", "i": key})
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * (t / maxf(top, 1.0)), rr.size.y)),
			Color(acc.r, acc.g, acc.b, 0.24))
		draw_rect(Rect2(rr.position, Vector2(2.5, rr.size.y)), acc)
		var by := y + ROW_C - 8.0
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(16, by), _amp_label(s, key),
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 120.0, UiKit.SIZE["CAPTION"],
			Palette.EXPOSE if key < 0 else Palette.TEXT)
		var share := (100.0 * t / col) if col > 0.5 else 0.0
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, by), "%d%%" % int(round(share)),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 88, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, by), "≈+" + _fmt(t),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["CAPTION"], Palette.EXPOSE)
		y += ROW_C
	return y

## AMPLIFY detail — one contributor's per-boon "≈ +X" (damage, or heal for a heal-boon).
func _draw_amp_detail(s: CombatState, y: float) -> float:
	var key := amp_focus
	var acc := _amp_accent(s, key)
	_hits.append({"rect": Rect2(0, y, size.x, 18), "kind": "back", "i": 0})
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(12, y + 12),
		"‹ " + _amp_label(s, key) + " — enabled", HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 24, UiKit.SIZE["MICRO"], acc.lightened(0.2))
	y += 18.0
	var srcs := _amp_sources(s, key)
	var col := 0.0
	for e in srcs:
		col += _amp_sum(e[1])
	var top := (_amp_sum(srcs[0][1]) if not srcs.is_empty() else 1.0)
	for e in srcs:
		var entry: Dictionary = e[1]
		var dmg := float(entry.get("total", 0.0))
		var hv := float(entry.get("heal", 0.0))
		var big := maxf(dmg, hv)
		var unit := ("≈+%s dmg" % _fmt(dmg)) if dmg >= hv else ("≈+%s heal" % _fmt(hv))
		var rr := Rect2(8, y + 2, size.x - 16, ROW_C - 5)
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * (big / maxf(top, 1.0)), rr.size.y)),
			Color(acc.r, acc.g, acc.b, 0.20))
		draw_rect(Rect2(rr.position, Vector2(2.5, rr.size.y)), acc)
		var by := y + ROW_C - 8.0
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(16, by), boon_name(e[0]),
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.5, UiKit.SIZE["CAPTION"], Palette.TEXT)
		var share := (100.0 * big / col) if col > 0.5 else 0.0
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, by), "%d%%" % int(round(share)),
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 96, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, by), unit,
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["CAPTION"], Palette.EXPOSE)
		y += ROW_C
	if srcs.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· nothing yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		y += ROW_C
	return y

## DISCIPLINE: a live "who's playing clean" scoreboard. One row per gradeable seat, ranked by
## clean-answer %, colored by grade (S..D). Bar ∝ clean%; the dim tail shows the fault count
## (times hit · strays off the tank). Reads seat.diag + the taken meter — the live twin of STATS
## PAGE v2's DEFENSE/DISCIPLINE grades (full grade breakdown lives on that page).
func _draw_disc(s: CombatState, rk: Array, y: float) -> float:
	if rk.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· no timed inputs to grade ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		return y + ROW_C
	for ri in rk.size():
		var r: Array = rk[ri]
		var i := int(r[0])
		var pct := float(r[1])
		var seat: Seat = s.seats[i]
		var graded := pct >= 0.0
		var col := _disc_col(pct) if graded else Palette.TEXT_DIM
		var rr := Rect2(8, y + 2, size.x - 16, ROW_C - 5)
		if seat.is_player:
			draw_rect(Rect2(0, y, size.x, ROW_C), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.055))
		if graded:
			draw_rect(Rect2(rr.position, Vector2(rr.size.x * (pct / 100.0), rr.size.y)),
				Color(col.r, col.g, col.b, 0.22))
			draw_rect(Rect2(rr.position, Vector2(2.5, rr.size.y)), col)
		var by := y + ROW_C - 8.0
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(10, by), str(ri + 1),
			HORIZONTAL_ALIGNMENT_LEFT, 16.0, UiKit.SIZE["MICRO"],
			Palette.GOLD if (ri == 0 and graded) else Palette.TEXT_DIM)
		var name_col := Palette.GOLD_BRIGHT if seat.is_player else Palette.TEXT
		if not seat.alive():
			name_col = Palette.TEXT_DIM
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(26, by),
			_seat_name(seat) + (" ◆" if seat.is_player else ""),
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 132.0, UiKit.SIZE["CAPTION"], name_col)
		# fault tail (dim): times hit · strays
		var f := _disc_faults(s, i)
		var fault := "%d hit" % int(f[0])
		if int(f[1]) > 0:
			fault += " · %d stray" % int(f[1])
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, by), fault,
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 78, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		# grade: letter + clean% (or — when ungradeable)
		var grade := ("%s %d%%" % [_disc_letter(pct), int(round(pct))]) if graded else "—"
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, by), grade,
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["CAPTION"], col)
		y += ROW_C
	return y
