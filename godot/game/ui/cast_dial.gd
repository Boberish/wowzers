## The stage centrepiece: the BOSS ITSELF, as a ritual sigil burning inside a gilded
## telegraph dial. The per-boss glyph (RuneIcons.boss_tex) breathes at rest, winds up
## in the swing's colour during a telegraph, flinches white when struck, pulses green
## while it heals, cracks gold when staggered, trembles as it nears death and burns
## crimson at enrage. The telegraph is a gradient sweep around the ring whose defensive
## window flares. All feint / interrupt / heal / size LOGIC is unchanged — presentation
## only; the HUD feeds fields each frame and calls react() from the event stream.
class_name BossCastDial
extends Control

var boss_name: String = "":
	set(v):
		if v != boss_name:
			boss_name = v
			_glyph = RuneIcons.boss_tex(v)
var boss_hp_frac: float = 1.0
var enraged: bool = false
var phase_num: int = 1
var tg_active: bool = false
var tg_name: String = ""
var tg_frac: float = 0.0          # elapsed / dur
var tg_remaining: float = 0.0
var tg_size: int = 0
var tg_defensible: bool = false
var tg_heal: bool = false          # boss is self-healing — out-damage or stagger it
var tg_interruptible: bool = false # it's a cast you can Kick outright (Voidcaller/Twinfang)
var tg_feint: bool = false         # it's a Feint — HOLD; guarding it is the bait
var tg_rhythm: bool = false        # THE RHYTHM (§3½): the victim's own auto-attack bar riding the dial
var size_verbs: bool = false       # §3½ height law words (the Duelist): small = DODGE, HEAVY+ = PARRY

func _prompt_verb() -> String:
	if tg_rhythm:
		return "DODGE"
	if size_verbs:
		return "PARRY" if tg_size >= AbilityRes.Size.HEAVY else "DODGE"
	return verb
var zone_frac: float = 0.3        # fraction of the cast that is the window
var in_zone: bool = false
var def_ready: bool = true        # is the defensive press off cooldown?
var verb: String = "PARRY"
# --- M7 strike strings: fed by the HUD each frame; empty = classic swing.
# A string renders as a CHAIN of full-looking short telegraphs: the sweep resets
# per beat (attack! attack! attack!), each with its own window + PERFECT sliver.
# tg_strikes = the preview pip track: {frac, remaining, size, feint, aoe, guard,
# resolved, answered, grade, mine} per beat.
var tg_strikes: Array = []
var dodge_ready: bool = true      # is the universal dodge past its recovery/lockout?
var combo_idx: int = 0            # current beat (1-based) of combo_total
var combo_total: int = 0
var perfect_frac: float = 0.0     # PERFECT window as a fraction of the current beat's wind-up
var beat_mine: bool = true        # is the current beat this viewer's to answer?
var beat_answered: bool = false   # already answered (press banked, impact pending)

## RETICLE mode (3D stage): the living 3D boss stands behind the dial, so the
## sigil disc + glyph are skipped and the dial reads as a targeting ring around
## its body. All telegraph/window/beat presentation is unchanged.
var show_sigil: bool = true

var _glyph: Texture2D
var _pulse: float = 0.0
var _t: float = 0.0
var _flinch: float = 0.0          # white flash on the glyph, decays
var _shake: float = 0.0           # glyph-local impact wobble, decays
var _stag: float = 0.0            # stagger cracks, decays
var _healp: float = 0.0           # heal pulse, decays
var _glow: GlowCore

func _ready() -> void:
	# central core glow behind the sigil: dim at rest, colours to the incoming swing,
	# flares gold the instant a defensive window is answerable (never for a Feint)
	_glow = GlowCore.new()
	_glow.setup(0.0, Palette.GOLD_DIM, 0.0, 0.34, 0.2)
	add_child(_glow)

## The HUD's event drain talks to the boss through this.
func react(kind: String, amt: float = 0.0) -> void:
	match kind:
		"impact":
			_flinch = maxf(_flinch, clampf(amt / 140.0, 0.22, 0.75))
			_shake = maxf(_shake, clampf(amt / 16.0, 2.0, 9.0))
		"stagger":
			_stag = 1.0
			_shake = maxf(_shake, 8.0)
		"heal":
			_healp = 1.0

func _swing_color() -> Color:
	if tg_feint:
		return Palette.RELIC
	if tg_interruptible:
		return Palette.KICK
	if tg_heal:
		return Palette.WIN
	return Palette.size_color(tg_size)

func _process(delta: float) -> void:
	_pulse += delta * 6.5
	_t += delta
	_flinch = maxf(0.0, _flinch - delta * 3.2)
	_shake = maxf(0.0, _shake - delta * 26.0)
	_stag = maxf(0.0, _stag - delta * 2.0)
	_healp = maxf(0.0, _healp - delta * 1.7)
	if _glow != null:
		var base := 0.12
		var col := Palette.GOLD_DIM
		if tg_active:
			base = 0.4
			col = _swing_color()
			if in_zone and not tg_feint:
				base = 1.0
				col = Palette.GOLD_BRIGHT
			elif in_zone:
				base = 0.8
		elif enraged:
			base = 0.30
			col = Palette.CRIMSON
		_glow.set_glow_color(col)
		_glow.set_base(base)
	queue_redraw()

func _draw() -> void:
	# ring sits in the top square of the rect; prompt text lives under it when the
	# rect is taller than wide (the stage layout), else falls back inside the disc
	var R := size.x * 0.5 - 12.0
	var c := Vector2(size.x * 0.5, R + 12.0)
	if size.y < size.x:
		R = minf(size.x, size.y) * 0.5 - 10.0
		c = size * 0.5
	var top := -PI / 2.0
	var dead := boss_hp_frac <= 0.001
	var low := clampf((0.28 - boss_hp_frac) / 0.28, 0.0, 1.0)

	if show_sigil:
		# enrage / near-death under-burn behind the disc
		if (enraged or low > 0.0) and not dead:
			var ua := (0.10 if enraged else 0.06 * low) + 0.05 * (0.5 + 0.5 * sin(_t * (5.0 if enraged else 2.4)))
			draw_circle(c, R * 0.80, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, ua))
		# top-lit glass sigil disc
		draw_circle(c, R * 0.66, Palette.FILL_BOT)
		draw_circle(c - Vector2(0, R * 0.14), R * 0.54, Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.4))
		_draw_boss(c, R, dead, low)
		UiKit.gilded_ring(self, c, R * 0.66, 2.0, 48)      # inner disc rim
	# engraved track + gilded outer metal ring
	UiKit.engraved_ticks(self, c, R * 0.885, R * 0.955, 24)
	UiKit.gilded_ring(self, c, R, 4.0, 72)

	# telegraph sweep
	var r2 := R * 0.79
	if tg_active:
		var col := _swing_color()
		var is_string := not tg_strikes.is_empty()
		# the answer-window backing (strings: this BEAT's window — never for a feint)
		if tg_defensible or tg_interruptible or (is_string and beat_mine and not tg_feint):
			var zstart := top + TAU * (1.0 - clampf(zone_frac, 0.0, 1.0))
			var zcol := Palette.KICK.darkened(0.35) if tg_interruptible else Palette.CRUSH.darkened(0.45)
			draw_arc(c, r2, zstart, top + TAU, 24, zcol, 7.0, true)
			# the PERFECT sliver, right at impact (strings feed perfect_frac; a
			# classic swing derives its own so EVERY window has an aim mark)
			var pfrac := perfect_frac
			if not is_string and tg_defensible and not tg_feint and tg_frac < 0.999:
				var dur_est := tg_remaining / maxf(1.0 - tg_frac, 0.001)
				pfrac = clampf(0.14 / maxf(dur_est, 0.001), 0.0, zone_frac)
			if pfrac > 0.0:
				var pstart := top + TAU * (1.0 - clampf(pfrac, 0.0, 1.0))
				var pscol := Palette.GOLD_BRIGHT
				pscol.a = 0.85
				draw_arc(c, r2, pstart, top + TAU, 12, pscol, 7.0, true)
			# the IMPACT HAIRLINE at 12 o'clock — the narrow "aim here" mark the
			# sweep races toward
			var hcol := Palette.GOLD_BRIGHT if in_zone else Palette.GOLD
			draw_line(c + Vector2(0, -(r2 - 11.0)), c + Vector2(0, -(r2 + 11.0)), Color(0, 0, 0, 0.7), 4.0, true)
			draw_line(c + Vector2(0, -(r2 - 10.0)), c + Vector2(0, -(r2 + 10.0)), hcol, 2.0, true)
		var a_end := top + TAU * clampf(tg_frac, 0.0, 1.0)
		UiKit.gradient_arc(self, c, r2, top, a_end, 7.0, col.darkened(0.45), col, 40)
		if in_zone:                                      # pulse overlay when actionable
			var pcol := Palette.GOLD_BRIGHT if not tg_feint else col
			pcol.a = 0.5 + 0.5 * sin(_pulse)
			draw_arc(c, r2, top, a_end, 40, pcol, 7.0, true)
		# M7 string: a small PREVIEW track of the whole combo on the outer ring —
		# the big sweep is the current beat; these show what's still coming.
		# Feints are hollow (don't press!), answered beats hold their grade colour,
		# missed beats burn crimson, aoe beats ring outward (everyone answers).
		var r3 := R * 0.925
		for b in tg_strikes:
			var ang := top + TAU * clampf(float(b.get("frac", 0.0)), 0.0, 1.0)
			var p := c + Vector2(cos(ang), sin(ang)) * r3
			var resolved := bool(b.get("resolved", false))
			var rad := 5.0 if bool(b.get("aoe", false)) else 4.0
			if bool(b.get("feint", false)):
				var fcol := Palette.RELIC
				fcol.a = 0.35 if resolved else 0.95
				draw_arc(p, rad, 0.0, TAU, 20, fcol, 2.0, true)
				if int(b.get("grade", -1)) == StrikeRes.Grade.BAITED:
					draw_circle(p, rad * 0.55, Palette.CRIMSON)
				continue
			var bcol := _grade_color(int(b.get("grade", -1)), int(b.get("size", 0)),
				resolved, bool(b.get("answered", false)))
			draw_circle(p, rad, Color(0, 0, 0, 0.6))     # socket
			draw_circle(p, rad - 1.2, bcol)
			if bool(b.get("aoe", false)):
				var acol := bcol
				acol.a = 0.5
				draw_arc(p, rad + 2.5, 0.0, TAU, 20, acol, 1.5, true)

	# heal pulse: green rings collapsing INTO the boss (it's drinking HP back)
	if _healp > 0.0 and not dead:
		var hr := R * (0.66 + 0.30 * _healp)
		draw_arc(c, hr, 0.0, TAU, 48, Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.45 * _healp), 3.0, true)
		draw_arc(c, hr * 0.86, 0.0, TAU, 48, Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.25 * _healp), 2.0, true)

	# stagger: gold fracture lines bursting from the disc
	if _stag > 0.0:
		for i in 6:
			var a := TAU * float(i) / 6.0 + 0.5
			var d := Vector2(cos(a), sin(a))
			var scol := Palette.GOLD_BRIGHT
			scol.a = _stag * 0.8
			draw_line(c + d * R * 0.30, c + d * R * (0.30 + 0.42 * (1.0 - _stag * 0.5)), scol, 2.5, true)
		var rcol := Palette.GOLD_BRIGHT
		rcol.a = _stag * 0.5
		draw_arc(c, R * 0.66 * (1.0 + 0.25 * (1.0 - _stag)), 0.0, TAU, 48, rcol, 2.0, true)

	# prompt text under the ring (or inside the lower disc on square layouts)
	var font := ThemeDB.fallback_font
	var ty := c.y + R + 10.0
	if ty + 46.0 > size.y:
		ty = c.y + R * 0.40
	if tg_active:
		var name_col := _swing_color()
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(0.0, ty + 14.0), tg_name.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["HEADER"], name_col)
		var prompt := ""
		var pcol := Palette.TEXT_DIM
		if not tg_strikes.is_empty():
			var tag := "%d / %d" % [combo_idx, combo_total]
			if not beat_mine:
				prompt = "COMBO %s" % tag
			elif tg_feint:
				prompt = "FEINT — DON'T PRESS!  (%s)" % tag; pcol = Palette.RELIC
			elif beat_answered:
				prompt = "DODGED — %s" % tag; pcol = Palette.GOLD
			elif not dodge_ready:
				prompt = "dodge locked  (%s)" % tag; pcol = Palette.CRIMSON.darkened(0.2)
			elif in_zone:
				prompt = ">> DODGE <<"; pcol = Palette.GOLD_BRIGHT
			else:
				prompt = "STRIKE %s — dodge on the flash" % tag
		elif tg_feint:
			prompt = "FEINT — DON'T PRESS!"; pcol = Palette.RELIC
		elif in_zone:
			prompt = ">> %s <<" % _prompt_verb(); pcol = Palette.GOLD_BRIGHT
		elif tg_interruptible:
			prompt = "%s — interrupt!" % verb; pcol = Palette.KICK
		elif tg_heal:
			prompt = "HEALING — BURN IT DOWN"; pcol = Palette.WIN
		elif tg_defensible and not def_ready:
			prompt = ("dodge locked" if tg_rhythm else "guard recharging"); pcol = Palette.CRIMSON.darkened(0.2)
		elif tg_defensible:
			prompt = "%s on the flash" % _prompt_verb()
		else:
			prompt = "UNAVOIDABLE"; pcol = Palette.CRIMSON
		UiKit.text_shadowed(self, font, Vector2(0.0, ty + 38.0), prompt,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["SUBHEAD"], pcol)
	elif not dead:
		var wcol := Palette.TEXT_DIM
		wcol.a = 0.45 + 0.15 * sin(_t * 0.9)
		UiKit.text_shadowed(self, font, Vector2(0.0, ty + 14.0), "watching you",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["BODY"], wcol)

## Feed one frame of string state from an observation's telegraph dict (M7).
## The CURRENT beat is re-presented as its own full short telegraph: the sweep
## (tg_frac), size colour, feint flag, window arc and PERFECT sliver all describe
## just this beat's wind-up — so a combo reads as several quick, normal-looking
## attacks instead of dots on one slow cast. Later beats stay as a preview track.
func feed_strikes(tg: Dictionary, dur: float, dodge_ok: bool, good_window: float,
		perfect_window: float = 0.14) -> void:
	var beats: Array = tg.get("strikes", [])
	dodge_ready = dodge_ok
	if beats.is_empty():
		tg_strikes = []
		combo_idx = 0
		combo_total = 0
		perfect_frac = 0.0
		beat_answered = false
		beat_mine = true
		return
	var arr: Array = []
	for b in beats:
		var e: Dictionary = (b as Dictionary).duplicate()
		e["frac"] = clampf(float(e.get("at", 0.0)) / maxf(dur, 0.001), 0.04, 1.0)
		arr.append(e)
	tg_strikes = arr
	combo_total = beats.size()
	var cur_i := -1
	for i in beats.size():
		if not bool(beats[i].get("resolved", false)):
			cur_i = i
			break
	if cur_i < 0:                     # every beat landed; the telegraph is clearing
		combo_idx = combo_total
		in_zone = false
		return
	combo_idx = cur_i + 1
	var b: Dictionary = beats[cur_i]
	var seg_start := 0.0 if cur_i == 0 else float(beats[cur_i - 1].get("at", 0.0))
	var seg_len := maxf(0.05, float(b.get("at", 0.0)) - seg_start)
	var rem := float(b.get("remaining", 0.0))
	tg_frac = clampf(1.0 - rem / seg_len, 0.0, 1.0)     # this beat's OWN fast wind-up
	tg_remaining = rem
	tg_size = int(b.get("size", 0))
	tg_feint = bool(b.get("feint", false))
	beat_mine = bool(b.get("mine", true)) \
		and int(b.get("guard", 0)) != StrikeRes.Guard.UNANSWERABLE
	beat_answered = bool(b.get("answered", false))
	zone_frac = clampf(good_window / seg_len, 0.0, 1.0)
	perfect_frac = clampf(perfect_window / seg_len, 0.0, 1.0)
	in_zone = beat_mine and not tg_feint and not beat_answered \
		and rem <= good_window and dodge_ok

## Beat-pip colour: answered beats keep their grade, landed beats burn crimson,
## upcoming beats wear the swing-size colour.
func _grade_color(grade: int, sz: int, resolved: bool, answered: bool) -> Color:
	if answered:
		match grade:
			StrikeRes.Grade.PERFECT: return Palette.GOLD_BRIGHT
			StrikeRes.Grade.GOOD: return Palette.GOLD
			StrikeRes.Grade.GRAZE: return Palette.STEEL
	if resolved:
		return Palette.CRIMSON
	return Palette.size_color(sz).darkened(0.15)

## the living glyph: breathe, tremble, flinch, burn, die
func _draw_boss(c: Vector2, R: float, dead: bool, low: float) -> void:
	if _glyph == null:
		return
	var breathe := 1.0 + 0.016 * sin(_t * 1.7)
	if enraged:
		breathe = 1.0 + 0.022 * sin(_t * 3.4)
	breathe += low * 0.008 * sin(_t * 12.0)               # near-death tremor
	if dead:
		breathe = 0.94
	var side := R * 0.86 * breathe
	var gc := c + Vector2(sin(_t * 51.0), cos(_t * 43.0)) * _shake
	var rect := Rect2(gc - Vector2(side, side) * 0.5, Vector2(side, side))

	if not dead:
		# aura copy in the current mood colour
		var mood := _swing_color() if tg_active else (Palette.CRIMSON if enraged else Palette.GOLD)
		var aura := mood
		aura.a = 0.15 + 0.07 * sin(_t * 1.7) + (0.10 if tg_active else 0.0)
		var aside := side * 1.10
		draw_texture_rect(_glyph, Rect2(gc - Vector2(aside, aside) * 0.5, Vector2(aside, aside)), false, aura)

	# drop shadow, then the tinted mark itself
	draw_texture_rect(_glyph, Rect2(rect.position + Vector2(0, 3), rect.size), false, Color(0, 0, 0, 0.55))
	var tint := Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.25)
	tint = tint.lerp(Palette.CRIMSON, maxf(1.0 if enraged else 0.0, low) * 0.55)
	if dead:
		tint = Color(0.42, 0.38, 0.35, 0.30)
	draw_texture_rect(_glyph, rect, false, tint)
	if _flinch > 0.0 and not dead:
		draw_texture_rect(_glyph, rect, false, Color(1, 1, 1, _flinch))
	if _healp > 0.0 and not dead:
		draw_texture_rect(_glyph, rect, false, Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.30 * _healp))
