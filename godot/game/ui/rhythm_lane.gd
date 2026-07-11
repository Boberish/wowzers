## RhythmLane — THE RHYTHM's persistent lane (§3½ presentation v2, Bill 2026-07-11).
## The tank's auto-attack stream as a PERMANENT instrument: a channel that is ALWAYS on
## screen during a rhythm fight — comets ride left→right into the impact GATE, the next
## swing is visible while nothing is armed (projected ETA), a boss wind-up DIMS the lane
## but never removes it, answers flash their grade at the gate and bank a history gem.
## Nothing ever pops in from nowhere — this replaces the dial-borrowing strobe that read
## as "another global attack, glitching". Pure view: fed by DuelistBand from obs each
## frame; grade flashes ride the duel_answer event stream.
class_name RhythmLane
extends Control

# fed each frame (obs.rhythm_lane + band state)
var active: bool = false          ## this fight has a rhythm stream at all
var armed: bool = false           ## a swing is in flight
var mine: bool = true             ## the in-flight swing aims at me (false = strayed/peeled)
var paused: bool = false          ## a real telegraph is winding up (lane holds, dimmed)
var remaining: float = 0.0        ## armed: seconds to impact
var windup: float = 0.6           ## the swing's full wind-up
var next_eta: float = 0.0         ## unarmed: projected seconds to the NEXT impact
var cadence: float = 1.1
var dodge_ok: bool = true
var zone: float = 0.3             ## the answer window (visual aim cue)

var _pulse: float = 0.0
var _flash: float = 0.0           ## gate flash decay
var _flash_col: Color = Color.WHITE
var _flash_txt: String = ""
var _history: Array = []          ## last answers: Color per gem (newest last)
var _was_armed: bool = false
var _answered_this_swing: bool = false

const GATE_INSET := 64.0          ## gate x from the right edge
const HORIZON := 2.2              ## seconds of track the channel shows

func _process(delta: float) -> void:
	_pulse += delta * 5.0
	_flash = maxf(0.0, _flash - delta * 2.6)
	queue_redraw()

## An answered bar (duel_answer event) — flash the grade + bank a gem.
func flash_grade(grade: int) -> void:
	_answered_this_swing = true
	match grade:
		StrikeRes.Grade.PERFECT:
			_flash_col = Palette.GOLD_BRIGHT; _flash_txt = "PERFECT"
		StrikeRes.Grade.GOOD:
			_flash_col = Palette.GOLD; _flash_txt = "GOOD"
		_:
			_flash_col = Palette.STEEL; _flash_txt = "GRAZE"
	_flash = 1.0
	_bank(_flash_col)

func _bank(col: Color) -> void:
	_history.append(col)
	if _history.size() > 8:
		_history.pop_front()

## Per-frame feed (called from the band's render). Detects an EATEN swing (armed→gone
## with no answer flash in between) and banks it crimson — the miss needs a mark too.
func feed(lane: Dictionary, dodge_ready: bool) -> void:
	active = not lane.is_empty()
	if not active:
		return
	var now_armed := bool(lane.get("armed", false))
	if _was_armed and not now_armed and not _answered_this_swing and mine:
		_flash_col = Palette.CRIMSON; _flash_txt = "HIT"
		_flash = 1.0
		_bank(Palette.CRIMSON)
	if now_armed and not _was_armed:
		_answered_this_swing = false
	_was_armed = now_armed
	armed = now_armed
	mine = bool(lane.get("mine", true))
	paused = bool(lane.get("paused", false))
	remaining = float(lane.get("remaining", 0.0))
	windup = maxf(0.05, float(lane.get("windup", 0.6)))
	next_eta = float(lane.get("next_eta", 0.0))
	cadence = float(lane.get("cadence", 1.1))
	dodge_ok = dodge_ready

func _draw() -> void:
	if not active:
		return
	var w := size.x
	var h := size.y
	var gate_x := w - GATE_INSET
	var cy := h * 0.58
	var dim := 0.45 if paused else 1.0

	# glass channel + gilded frame (the lane is FURNITURE — it never leaves)
	draw_rect(Rect2(0, 0, w, h), Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.55))
	draw_rect(Rect2(0, 0, w, h), Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.55 * dim), false, 1.0)
	# track line
	var tl := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.35 * dim)
	draw_line(Vector2(10, cy), Vector2(gate_x, cy), tl, 1.0, true)
	# approach chevrons (subtle motion grain toward the gate)
	for i in 5:
		var cxx := 10.0 + fposmod(_pulse * 26.0 + float(i) * ((gate_x - 20.0) / 5.0), gate_x - 20.0)
		var ca := Color(tl.r, tl.g, tl.b, tl.a * 0.7)
		draw_line(Vector2(cxx, cy - 3.5), Vector2(cxx + 5.0, cy), ca, 1.0, true)
		draw_line(Vector2(cxx + 5.0, cy), Vector2(cxx, cy + 3.5), ca, 1.0, true)

	# the answer WINDOW band before the gate (aim here), + the gate itself
	var px_per_s := (gate_x - 14.0) / HORIZON
	var zw := zone * px_per_s
	var zcol := Palette.CRUSH.darkened(0.35)
	zcol.a = 0.5 * dim
	draw_rect(Rect2(gate_x - zw, cy - 7.0, zw, 14.0), zcol)
	var in_zone := armed and mine and remaining <= zone and dodge_ok and not paused
	var gcol := Palette.GOLD_BRIGHT if in_zone else Palette.GOLD
	gcol.a = dim
	draw_line(Vector2(gate_x, 7.0), Vector2(gate_x, h - 7.0), Color(0, 0, 0, 0.7), 4.0, true)
	draw_line(Vector2(gate_x, 7.0), Vector2(gate_x, h - 7.0), gcol, 2.0, true)

	# THE COMET — armed: the real swing; unarmed: the projected next (hollow)
	var eta := remaining if armed else next_eta
	if eta >= 0.0 and eta <= HORIZON:
		var x := gate_x - eta * px_per_s
		if armed:
			var body := Palette.size_color(AbilityRes.Size.LIGHT)
			if not mine:
				body = Color(0.5, 0.5, 0.55)          # strayed — not yours, watch it go
			# trail sells the approach
			for i in 4:
				var ta := body
				ta.a = (0.28 - 0.06 * float(i)) * dim
				draw_circle(Vector2(x - 8.0 - 6.0 * float(i), cy), 4.5 - 0.6 * float(i), ta)
			var bcol := body
			bcol.a = dim
			draw_circle(Vector2(x, cy), 7.0, Color(0, 0, 0, 0.6))
			draw_circle(Vector2(x, cy), 6.0, bcol)
			if not mine:
				UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(x - 34.0, cy - 12.0),
					"PEELED", HORIZONTAL_ALIGNMENT_CENTER, 68.0, 10, Color(0.6, 0.6, 0.65, dim))
		else:
			var hcol := Palette.STEEL
			hcol.a = 0.55 * dim
			draw_arc(Vector2(x, cy), 5.5, 0.0, TAU, 20, hcol, 1.5, true)

	# gate flash (grade) + label
	if _flash > 0.0:
		var fc := _flash_col
		fc.a = _flash * 0.9
		draw_arc(Vector2(gate_x, cy), 10.0 + 16.0 * (1.0 - _flash), 0.0, TAU, 28, fc, 2.5, true)
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(gate_x - 60.0, 2.0), _flash_txt,
			HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, fc)

	# history gems (newest at the right, tucked past the gate)
	var hx := w - 12.0
	for i in range(_history.size() - 1, -1, -1):
		var col: Color = _history[i]
		col.a = clampf(0.35 + 0.65 * (float(i + 1) / float(maxi(1, _history.size()))), 0.0, 1.0) * dim
		var r := 4.4
		var c := Vector2(hx, h - 9.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, 0),
			c + Vector2(0, r), c + Vector2(-r * 0.8, 0)]), col)
		hx -= 11.0

	# title + state cue
	var font := ThemeDB.fallback_font
	UiKit.text_shadowed(self, font, Vector2(8.0, 2.0), "THE RHYTHM",
		HORIZONTAL_ALIGNMENT_LEFT, 160.0, 10, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.9 * dim))
	if paused:
		UiKit.text_shadowed(self, font, Vector2(w * 0.5 - 90.0, 2.0), "— the boss winds up —",
			HORIZONTAL_ALIGNMENT_CENTER, 180.0, 10, Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.8))
	elif in_zone:
		var pc := Palette.GOLD_BRIGHT
		pc.a = 0.6 + 0.4 * sin(_pulse * 2.2)
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(gate_x - 130.0, cy - 8.0), ">> DODGE <<",
			HORIZONTAL_ALIGNMENT_RIGHT, 110.0, 12, pc)
