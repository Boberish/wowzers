## THE RECKONING — the end-of-fight recap plaque. Engine truth (seat.diag strike
## grades, fight duration, the boss's reclaimed HP) plus the HUD's view-side
## event tallies (damage dealt/taken, classic parries, kicks) rendered as one
## engraved reliquary panel: an epithet for the fight (FLAWLESS / CLEAN /
## SCRAPPY / BLOODY), a JUDGMENT bar segmented in the Judgment Channel's grade
## colours, DEALT/TAKEN stat tiles with counting numerals, and a footnote row of
## class-flavoured lines. Rows reveal one beat apart; numerals count up.
##
## Usage on any end screen (state survives into it):
##     if _ctrl != null and _ctrl.state != null and _ctrl.player() != null:
##         box.add_child(RecapPanel.new(_ctrl.state, _ctrl.player(), _recap_stats))
## and in the HUD event drain, one line:  RecapPanel.track(_recap_stats, ev)
class_name RecapPanel
extends Control

var _s: CombatState
var _seat: Seat
var _v: Dictionary            # view-side tallies from track()
var _t := 0.0

# judgment tallies resolved at build (engine diag + classic view tallies)
var _j := {}                  # perfect/good/graze/miss/baited/read/whiff/parries
var _dealt := 0
var _taken := 0
var _epithet := ""
var _ep_col: Color = Palette.GOLD
var _foot: Array = []         # extra footnote lines [[text, Color], ...]

## One line in every HUD's _handle_event — accumulates the view-side tallies.
static func track(stats: Dictionary, ev: Dictionary) -> void:
	match String(ev.get("t", "")):
		"boss_hit":
			stats["dealt"] = float(stats.get("dealt", 0.0)) + float(ev.get("amt", 0.0))
		"hurt":
			if bool(ev.get("player", false)):
				stats["taken"] = float(stats.get("taken", 0.0)) + float(ev.get("amt", 0.0))
		"negate":
			# classic press verdicts only (string echoes carry no seat ref)
			if bool(ev.get("player", false)) and ev.has("seat"):
				var key := "baited" if bool(ev.get("feint", false)) else "parries"
				stats[key] = int(stats.get(key, 0)) + 1
		"interrupt", "staggered":
			stats["kicks"] = int(stats.get("kicks", 0)) + 1
			if bool(ev.get("clean", false)):
				stats["clean_kicks"] = int(stats.get("clean_kicks", 0)) + 1
			if bool(ev.get("was_heal", false)):
				stats["denials"] = int(stats.get("denials", 0)) + 1
		"strike":
			stats["strikes"] = int(stats.get("strikes", 0)) + 1
			if String(ev.get("result", "")) == "perfect":
				stats["perfect_strikes"] = int(stats.get("perfect_strikes", 0)) + 1

func _init(s: CombatState, seat: Seat, view_stats: Dictionary) -> void:
	_s = s
	_seat = seat
	_v = view_stats
	custom_minimum_size = Vector2(640, 296)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve()

func _resolve() -> void:
	var d: Dictionary = _seat.diag if _seat != null else {}
	for k in ["perfect", "good", "graze", "miss", "baited", "read", "whiff"]:
		_j[k] = int(d.get(k, 0))
	_j["baited"] += int(_v.get("baited", 0))          # classic feint bites join the tally
	_j["parries"] = int(_v.get("parries", 0))
	_dealt = int(_v.get("dealt", 0.0))
	_taken = int(_v.get("taken", 0.0))

	# ---- the epithet: how the Rift remembers this fight ----
	var bad: int = _j["miss"] + _j["baited"] + _j["whiff"]
	var shine: int = _j["perfect"] + _j["read"] + _j["parries"]
	if _taken <= 0:
		_epithet = "UNTOUCHED"
		_ep_col = Palette.GOLD_BRIGHT
	elif bad == 0 and shine >= 3:
		_epithet = "FLAWLESS"
		_ep_col = Palette.GOLD_BRIGHT
	elif bad <= 1:
		_epithet = "CLEAN"
		_ep_col = Palette.GOLD
	elif bad <= shine:
		_epithet = "SCRAPPY"
		_ep_col = Palette.STEEL
	else:
		_epithet = "BLOODY"
		_ep_col = Palette.CRIMSON

	# ---- class-flavoured footnotes (only what actually happened) ----
	if _s != null and _s.boss.heal_total > 0.5:
		_foot.append(["it reclaimed %d HP — deny the checkpoint" % int(_s.boss.heal_total), Palette.WIN])
	var kicks := int(_v.get("kicks", 0))
	if kicks > 0:
		var kline := "%d casts cut short" % kicks
		if int(_v.get("clean_kicks", 0)) > 0:
			kline += " · %d clean" % int(_v.get("clean_kicks", 0))
		if int(_v.get("denials", 0)) > 0:
			kline += " · %d heals DENIED" % int(_v.get("denials", 0))
		_foot.append([kline, Palette.KICK])
	if int(_v.get("strikes", 0)) > 0:
		var ps := int(_v.get("perfect_strikes", 0))
		var st := int(_v.get("strikes", 0))
		_foot.append(["rhythm: %d%% perfect strikes (%d / %d)" % [int(100.0 * ps / maxf(st, 1)), ps, st],
			Palette.PERFECT])
	if _j["read"] > 0:
		_foot.append(["%d feints READ — it cannot fool you" % _j["read"], Palette.RELIC])
	if _j["whiff"] > 0:
		_foot.append(["%d dodges thrown too early" % _j["whiff"], Palette.CRIMSON.darkened(0.1)])

func _process(delta: float) -> void:
	_t += delta
	if _t < 2.6:
		queue_redraw()

## eased 0..1 reveal for row i (rows land one beat apart)
func _rv(i: int) -> float:
	var x := clampf((_t - 0.12 * float(i)) / 0.45, 0.0, 1.0)
	return 1.0 - (1.0 - x) * (1.0 - x)

## a numeral mid count-up
func _cnt(n: int, rev: float) -> String:
	return str(int(round(float(n) * clampf(rev * 1.15, 0.0, 1.0))))

func _draw() -> void:
	var w := size.x
	# ---- the plaque: glass panel + bevel + filigree ----
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.030, 0.026, 0.052, 0.72)
	plate.set_corner_radius_all(10)
	plate.border_color = Palette.EDGE
	plate.set_border_width_all(1)
	draw_style_box(plate, Rect2(0, 0, w, size.y))
	draw_line(Vector2(14, 1), Vector2(w - 14, 1), Palette.GOLD_DIM, 1.2, true)
	UiKit.filigree_corner(self, Vector2(6, 6), Vector2(1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - 6, 6), Vector2(-1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(6, size.y - 6), Vector2(1, -1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - 6, size.y - 6), Vector2(-1, -1), 10.0)

	# ---- header: THE RECKONING · boss · duration · epithet ----
	var r0 := _rv(0)
	var hc := Palette.GOLD
	hc.a = r0
	UiKit.text_shadowed(self, UiKit.display(700, 3), Vector2(0, 30), "· THE RECKONING ·",
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["LABEL"], hc)
	if _s != null:
		var secs := float(_s.tick) * _s.dt
		var dur := "%d:%04.1f" % [int(secs) / 60, fmod(secs, 60.0)] if secs >= 60.0 else "%.1fs" % secs
		var bc := Palette.TEXT
		bc.a = r0
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, 52),
			"%s  ·  %s" % [_s.encounter.name, dur], HORIZONTAL_ALIGNMENT_CENTER, w,
			UiKit.SIZE["BODY"], bc)
	var r1 := _rv(1)
	var ec := _ep_col
	ec.a = r1
	UiKit.text_shadowed(self, UiKit.title(800), Vector2(0, 86), _epithet,
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["TITLE"], ec)

	# ---- the JUDGMENT bar: your presses, in the gate's own colours ----
	var segs: Array = [
		[_j["perfect"] + _j["parries"], Palette.GOLD_BRIGHT, "perfect"],
		[_j["good"], Palette.GOLD, "good"],
		[_j["graze"], Palette.STEEL, "graze"],
		[_j["read"], Palette.RELIC, "read"],
		[_j["baited"] + _j["whiff"], Palette.CRIMSON.darkened(0.15), "baited"],
		[_j["miss"], Palette.CRIMSON, "hit"],
	]
	var total := 0
	for sg in segs:
		total += int(sg[0])
	var r2 := _rv(2)
	if total > 0 and r2 > 0.0:
		var bx := 56.0
		var bw := (w - 112.0) * r2
		var by := 108.0
		draw_rect(Rect2(bx - 2, by - 2, w - 112.0 + 4, 18), Color(0, 0, 0, 0.5 * r2))
		var x := bx
		for sg in segs:
			var n := int(sg[0])
			if n == 0:
				continue
			var sw := bw * float(n) / float(total)
			var scol: Color = sg[1]
			scol.a = r2
			draw_rect(Rect2(x, by, sw - 1.0, 14), scol)
			x += sw
		# legend: gem + count per non-zero grade
		var legend := ""
		for sg in segs:
			if int(sg[0]) > 0:
				legend += "%d %s   " % [int(sg[0]), String(sg[2])]
		var lc := Palette.TEXT_DIM
		lc.a = r2
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, 140), legend.strip_edges(),
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], lc)

	# ---- stat tiles: DEALT · TAKEN ----
	var r3 := _rv(3)
	if r3 > 0.0:
		var tiles: Array = [[_dealt, "DAMAGE DEALT", Palette.GOLD_BRIGHT],
			[_taken, "DAMAGE TAKEN", Palette.CRIMSON if _taken > 0 else Palette.GOLD_BRIGHT]]
		for i in tiles.size():
			var cx := w * (0.32 + 0.36 * float(i))
			var tcol: Color = tiles[i][2]
			tcol.a = r3
			UiKit.text_shadowed(self, UiKit.display(750), Vector2(cx - 120, 186),
				_cnt(int(tiles[i][0]), r3), HORIZONTAL_ALIGNMENT_CENTER, 240,
				UiKit.SIZE["DISPLAY"], tcol)
			var cc := Palette.TEXT_DIM
			cc.a = r3
			UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(cx - 120, 208),
				String(tiles[i][1]), HORIZONTAL_ALIGNMENT_CENTER, 240, UiKit.SIZE["MICRO"], cc)
		# engraved divider between the tiles
		var dc := Palette.GOLD_DIM
		dc.a = 0.6 * r3
		draw_line(Vector2(w * 0.5, 168), Vector2(w * 0.5, 212), dc, 1.2, true)

	# ---- footnotes ----
	var fy := 238.0
	for i in _foot.size():
		var rf := _rv(4 + i)
		if rf <= 0.0:
			continue
		var fcol: Color = _foot[i][1]
		fcol.a = 0.9 * rf
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, fy), String(_foot[i][0]),
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], fcol)
		fy += 18.0
