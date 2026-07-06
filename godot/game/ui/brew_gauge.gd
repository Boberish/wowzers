## THE ALEMBIC — the Alchemist's brew instrument (ALCHEMIST-PLAN base minigame).
## Twin poison RESERVOIRS (Venom ember / Rot glacial) flank a central REACTION
## CHAMBER — a gilded ring whose acid bloom breathes with min(V,R)×balance and whose
## live dps burns in the middle; the chamber IS the Rupture button and grows a
## breathing RIPE halo as fuel × potency peak. Between them: the VIAL, a tall glass
## tube with the sweet band, red line and min-floor etched in — it fills with the held
## side's liquor (wobbling surface, rising bubbles, crimson urgency past the line) and
## stamps its verdict where you released. A balance BEAM see-saws under the chamber,
## the POTENCY strip runs the footer with a travelling shimmer at high boil, and the
## last eight pours sit as gems on a history rail. Verdict banners scale-punch top
## centre (the Forge idiom).
##
## INPUT: the reservoirs are HOLD zones (press = brew, release = pour) and the chamber
## is a TAP zone (rupture) — pointer/touch native, mirrored on 1/2/3. Pure view layer:
## the HUD feeds observe() fields each frame and pushes combat events via on_event();
## signals carry intent OUT — nothing here touches state.
class_name BrewGauge
extends Control

signal brew_pressed(side: String)   ## pointer went down on a reservoir — start the hold
signal brew_released()              ## the held pointer lifted — pour
signal rupture_tapped()             ## chamber tapped — detonate

# --- live fields fed each frame (from observe) ---
var venom := 0.0
var rot := 0.0
var cap := 12.0
var soft := 9.0
var charging := ""                  ## "" | "venom" | "rot"
var charge := 0.0
var charge_max := 1.30
var fizzle_below := 0.45
var sweet_lo := 0.70
var sweet_hi := 0.98
var overflow_at := 1.0
var balance := 0.0
var potency := 0.0
var pot_mult := 1.0
var react_dps := 0.0
var ripe_glow := 0.0
var brew_min := 0.0

# --- eased display state (the fluidity layer — springs toward the live fields) ---
var _venom_d := 0.0
var _rot_d := 0.0
var _pot_d := 0.0
var _dps_d := 0.0
var _bloom_d := 0.0
var _tilt_d := 0.0                  ## see-saw beam angle (−1 venom-heavy … +1 rot-heavy)
var _ripe_d := 0.0

# --- feedback state (driven by on_event) ---
var _pulse := 0.0
var _banner := ""
var _banner_col := Palette.GOLD_BRIGHT
var _banner_t := 0.0
var _banner_hold := 0.85
var _col_flash := {"venom": 0.0, "rot": 0.0}     ## pour landed — reservoir rim flash
var _vial_stamp := {}               ## {lvl, col, t} — verdict line where you released
var _pour_drops: Array = []         ## droplet stream vial → reservoir [{t, side, col}]
var _burst := {}                    ## rupture: {t, big} expanding rings + rays
var _dud_t := 0.0                   ## "nothing to rupture" shiver
var _history: Array = []            ## last 8 pours [{col, hollow, big}]
var _hist_pop := 0.0
var _held_zone := ""                ## pointer bookkeeping: which zone owns the press

const VERDICT_HOLD := 0.85
const STAMP_HOLD := 0.6
const EASE := 14.0                  ## display spring rate (fast attack, no lag feel)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	_pulse += delta * 3.0
	var k := minf(1.0, EASE * delta)
	_venom_d += (venom - _venom_d) * k
	_rot_d += (rot - _rot_d) * k
	_pot_d += (potency - _pot_d) * k
	_dps_d += (react_dps - _dps_d) * k
	_ripe_d += (ripe_glow - _ripe_d) * k
	var sum := venom + rot
	var tilt := ((rot - venom) / sum) if sum > 0.1 else 0.0
	_tilt_d += (tilt - _tilt_d) * minf(1.0, 8.0 * delta)
	var power := (minf(venom, rot) / maxf(1.0, cap)) * (0.5 + 0.5 * balance)
	_bloom_d += (power - _bloom_d) * minf(1.0, 10.0 * delta)
	_banner_t = maxf(0.0, _banner_t - delta)
	_dud_t = maxf(0.0, _dud_t - delta * 3.0)
	_hist_pop = maxf(0.0, _hist_pop - delta * 3.0)
	for side in _col_flash:
		_col_flash[side] = maxf(0.0, float(_col_flash[side]) - delta * 3.2)
	if _vial_stamp.has("t"):
		_vial_stamp["t"] = float(_vial_stamp["t"]) - delta
		if float(_vial_stamp["t"]) <= 0.0:
			_vial_stamp = {}
	for d in _pour_drops:
		d["t"] = float(d["t"]) + delta * 2.6
	_pour_drops = _pour_drops.filter(func(d): return float(d["t"]) < 1.0)
	if _burst.has("t"):
		_burst["t"] = float(_burst["t"]) - delta
		if float(_burst["t"]) <= 0.0:
			_burst = {}
	queue_redraw()

# ------------------------------------------------------------------ input zones
func _venom_zone() -> Rect2:
	return Rect2(size.x * 0.045, size.y * 0.14, size.x * 0.135, size.y * 0.66)
func _rot_zone() -> Rect2:
	return Rect2(size.x * 0.82, size.y * 0.14, size.x * 0.135, size.y * 0.66)
func _chamber_c() -> Vector2:
	return Vector2(size.x * 0.535, size.y * 0.42)
func _chamber_r() -> float:
	return minf(size.y * 0.235, size.x * 0.105)
func _vial_rect() -> Rect2:
	return Rect2(size.x * 0.245, size.y * 0.13, size.x * 0.062, size.y * 0.64)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var p: Vector2 = event.position
			if _venom_zone().has_point(p):
				_held_zone = "venom"
				brew_pressed.emit("venom")
				accept_event()
			elif _rot_zone().has_point(p):
				_held_zone = "rot"
				brew_pressed.emit("rot")
				accept_event()
			elif p.distance_to(_chamber_c()) <= _chamber_r() + 14.0:
				rupture_tapped.emit()
				accept_event()
		else:
			if _held_zone != "":
				_held_zone = ""
				brew_released.emit()
				accept_event()

# ------------------------------------------------------------------ feedback
func _set_banner(word: String, col: Color, punch := 1.0) -> void:
	_banner = word
	_banner_col = col
	_banner_hold = VERDICT_HOLD * punch
	_banner_t = _banner_hold

## The combat event stream (already filtered to MY seat by the HUD).
func on_event(ev: Dictionary) -> void:
	match String(ev.get("t", "")):
		"brew_pour":
			var side := String(ev.get("side", "venom"))
			var grade := String(ev.get("grade", "ok"))
			var dose := int(ev.get("dose", 0))
			var sat := bool(ev.get("sat", false))
			var scol := Palette.VENOM_BREW if side == "venom" else Palette.ROT_BREW
			var lvl := charge                       # release level (obs still holds it this frame)
			match grade:
				"fizzle":
					_set_banner("TOO SOON", Palette.TEXT_DIM, 0.7)
				"spoiled":
					_set_banner("SPOILED!", Palette.SPOIL, 1.1)
					_vial_stamp = {"lvl": maxf(lvl, 1.02), "col": Palette.SPOIL, "t": STAMP_HOLD}
				"hot":
					_set_banner("HOT +%d" % dose, Palette.GOLD_BRIGHT, 1.05)
					_vial_stamp = {"lvl": lvl, "col": Palette.GOLD_BRIGHT, "t": STAMP_HOLD}
				"potent":
					_set_banner(("SATURATED +%d" % dose) if sat else ("POTENT +%d" % dose),
						Palette.TEXT_DIM if sat else Palette.PERFECT, 1.0)
					_vial_stamp = {"lvl": lvl, "col": Palette.PERFECT, "t": STAMP_HOLD}
				_:
					_set_banner(("SATURATED +%d" % dose) if sat else ("+%d" % dose),
						Palette.TEXT_DIM if sat else scol, 0.75)
					_vial_stamp = {"lvl": lvl, "col": scol, "t": STAMP_HOLD}
			if grade != "fizzle":
				_col_flash[side] = 1.0
				for i in 5:
					_pour_drops.append({"t": -float(i) * 0.09, "side": side, "col": scol})
			var gcol := scol
			var hollow := false
			var big := false
			match grade:
				"potent": gcol = Palette.PERFECT; big = true
				"hot": gcol = Palette.GOLD_BRIGHT; big = true
				"spoiled": gcol = Palette.SPOIL; hollow = true
				"fizzle": gcol = Palette.TEXT_DIM; hollow = true
			if sat:
				gcol = Palette.TEXT_DIM
				big = false
			_push_gem(gcol, hollow, big)
		"brew_rupture":
			var amt := int(ev.get("amt", 0))
			var peak := bool(ev.get("peak", false))
			_set_banner(("RUPTURE  %d" % amt) + ("  — AT PEAK" if peak else ""),
				Palette.REACT_HOT, 1.35 if peak else 1.15)
			_burst = {"t": STAMP_HOLD, "big": peak}
			_push_gem(Palette.REACT_HOT, false, true)
		"brew_dud":
			_set_banner("nothing to rupture", Palette.TEXT_DIM, 0.6)
			_dud_t = 1.0

func _push_gem(col: Color, hollow: bool, big: bool) -> void:
	_history.append({"col": col, "hollow": hollow, "big": big})
	while _history.size() > 8:
		_history.pop_front()
	_hist_pop = 1.0

# ------------------------------------------------------------------ draw
func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 260.0 or h < 150.0:
		return
	_draw_panel(w, h)
	_draw_reservoir(_venom_zone(), _venom_d, venom, Palette.VENOM_BREW, "VENOM",
		"fades fast", charging == "venom", float(_col_flash["venom"]))
	_draw_reservoir(_rot_zone(), _rot_d, rot, Palette.ROT_BREW, "ROT",
		"lingers", charging == "rot", float(_col_flash["rot"]))
	_draw_vial(w, h)
	_draw_pour_drops(w, h)
	_draw_chamber(w, h)
	_draw_seesaw(w, h)
	_draw_potency(w, h)
	_draw_history(w, h)
	_draw_banner(w, h)

func _draw_panel(w: float, h: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.026, 0.052, 0.74)
	sb.border_color = Palette.EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	draw_style_box(sb, Rect2(0, 0, w, h))
	# the reaction breathes onto the glass — a soft acid wash that scales with the boil
	if _bloom_d > 0.03:
		var c := _chamber_c()
		var wash := Palette.REACT
		draw_circle(c, _chamber_r() * (2.1 + 0.5 * _bloom_d),
			Color(wash.r, wash.g, wash.b, 0.045 * _bloom_d + 0.02 * _bloom_d * sin(_pulse * 1.7)))
	UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1))
	UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1))
	UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1))
	UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1))

## One poison reservoir: recessed glass well, liquor with a wobbling lit surface,
## saturation etch-line, live numeral, HOLD affordance + engraved nameplate.
func _draw_reservoir(z: Rect2, val_d: float, val_live: float, col: Color, name_s: String,
		temper: String, held: bool, flash: float) -> void:
	# hold affordance — the whole well is a button; it brightens under the thumb
	var well := StyleBoxFlat.new()
	well.bg_color = Color(col.r, col.g, col.b, 0.16 if held else 0.05)
	well.border_color = Color(col.r, col.g, col.b, 0.95 if held else 0.38)
	well.set_border_width_all(2 if held else 1)
	well.set_corner_radius_all(9)
	draw_style_box(well, z.grow(4.0))
	# recessed glass
	draw_rect(z, Color(0.02, 0.02, 0.04, 0.9))
	# fill: deep→bright vertical liquor
	var frac := clampf(val_d / cap, 0.0, 1.0)
	var fh := z.size.y * frac
	if fh > 1.0:
		var top_y := z.position.y + z.size.y - fh
		var steps := 7
		for i in steps:
			var t0 := float(i) / float(steps)
			var seg_col := col.darkened(0.62 - 0.5 * t0)
			draw_rect(Rect2(z.position.x + 1, top_y + fh * (1.0 - t0 - 1.0 / steps),
				z.size.x - 2, fh / steps + 1.0), seg_col)
		# the lit, wobbling surface — the liquid is ALIVE
		var wob := sin(_pulse * 2.4 + z.position.x) * 1.6
		draw_rect(Rect2(z.position.x + 1, top_y + wob - 1.5, z.size.x - 2, 3.0), col.lightened(0.35))
		draw_rect(Rect2(z.position.x + 1, top_y + wob + 1.5, z.size.x - 2, 2.0),
			Color(1, 1, 1, 0.18))
		# side gloss
		draw_rect(Rect2(z.position.x + 2, top_y, 2.5, fh), Color(1, 1, 1, 0.10))
	# saturation etch-line — above it, pours waste
	var sat_y := z.position.y + z.size.y * (1.0 - soft / cap)
	draw_line(Vector2(z.position.x - 2, sat_y), Vector2(z.position.x + z.size.x + 2, sat_y),
		Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.8), 1.2, true)
	var over_soft := val_live >= soft
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(z.position.x - 3, sat_y - 6),
		"SAT", HORIZONTAL_ALIGNMENT_LEFT, 40, 8,
		Palette.GOLD if over_soft else Palette.GOLD_DIM)
	# pour-landed flash: rim ring + splash ripple
	if flash > 0.0:
		draw_rect(z.grow(3.0), Color(col.r, col.g, col.b, 0.55 * flash), false, 2.5)
		var cy := z.position.y + z.size.y * (1.0 - clampf(val_live / cap, 0.0, 1.0))
		draw_arc(Vector2(z.get_center().x, cy), 6.0 + 22.0 * (1.0 - flash), 0.0, TAU, 24,
			Color(col.r, col.g, col.b, flash * 0.9), 2.0, true)
	# frame + numeral + plates
	draw_rect(z, Color(col.r, col.g, col.b, 0.5), false, 1.2)
	var num_y := clampf(z.position.y + z.size.y * (1.0 - frac) - 13.0,
		z.position.y + 26.0, z.position.y + z.size.y - 12.0)
	UiKit.text_shadowed(self, UiKit.display(750, 0), Vector2(z.get_center().x - 30, num_y),
		"%d" % int(round(val_live)), HORIZONTAL_ALIGNMENT_CENTER, 60, UiKit.SIZE["HEADER"], Palette.TEXT)
	UiKit.engraved_plaque(self, Vector2(z.get_center().x, z.position.y + z.size.y + 13.0), name_s, held, 10)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(z.get_center().x - 40, z.position.y + z.size.y + 28.0),
		temper, HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Palette.TEXT_DIM)
	# HOLD cue above the well
	var cue := "…POURING" if held else "HOLD"
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(z.get_center().x - 40, z.position.y - 10.0),
		cue, HORIZONTAL_ALIGNMENT_CENTER, 80, 9,
		col if held else Color(col.r, col.g, col.b, 0.55 + 0.2 * sin(_pulse * 2.0)))

## The VIAL — the skill instrument: sweet band, red line, min floor, live liquor.
func _draw_vial(w: float, h: float) -> void:
	var v := _vial_rect()
	var live := charging != ""
	var col := Palette.VENOM_BREW if charging == "venom" else Palette.ROT_BREW
	# glass tube (rounded) + neck flare
	var tube := StyleBoxFlat.new()
	tube.bg_color = Color(0.015, 0.015, 0.03, 0.92)
	tube.border_color = Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.8 if live else 0.4)
	tube.set_border_width_all(1)
	tube.set_corner_radius_all(7)
	draw_style_box(tube, v)
	var lvl_y := func(f: float) -> float:
		return v.position.y + v.size.y * (1.0 - clampf(f / charge_max, 0.0, 1.0))
	# zones etched in the glass: sweet band glow, red line, min floor
	var sweet_top: float = lvl_y.call(sweet_hi)
	var sweet_bot: float = lvl_y.call(sweet_lo)
	# the band breathes while the vial is live — the target zone begs for the release
	var band_a := (0.34 + 0.10 * sin(_pulse * 4.0)) if live else 0.14
	draw_rect(Rect2(v.position.x + 1, sweet_top, v.size.x - 2, sweet_bot - sweet_top),
		Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, band_a))
	draw_rect(Rect2(v.position.x + 1, sweet_top, v.size.x - 2, sweet_bot - sweet_top),
		Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.5 if live else 0.25), false, 1.0)
	var red_y: float = lvl_y.call(overflow_at)
	draw_line(Vector2(v.position.x - 3, red_y), Vector2(v.position.x + v.size.x + 3, red_y),
		Palette.SPOIL, 2.0, true)
	var min_y: float = lvl_y.call(fizzle_below)
	draw_dashed_line(Vector2(v.position.x, min_y), Vector2(v.position.x + v.size.x, min_y),
		Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.6), 1.0, 4.0)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(v.position.x - 34, min_y - 4),
		"min", HORIZONTAL_ALIGNMENT_RIGHT, 30, 8, Palette.TEXT_DIM)
	# the liquor
	if live and charge > 0.005:
		var over := charge > overflow_at
		var lcol := Palette.SPOIL if over else col
		var top: float = lvl_y.call(charge)
		var wob := sin(_pulse * 6.0) * 1.2
		var fill_top := top + wob
		draw_rect(Rect2(v.position.x + 2, fill_top, v.size.x - 4,
			v.position.y + v.size.y - fill_top - 2.0), Color(lcol.r, lcol.g, lcol.b, 0.85))
		draw_rect(Rect2(v.position.x + 2, fill_top - 1.0, v.size.x - 4, 3.0), lcol.lightened(0.45))
		# rising bubbles — the brew is working
		for i in 4:
			var ph := fmod(_pulse * (0.9 + 0.23 * float(i)) + float(i) * 1.7, 1.0)
			var by := v.position.y + v.size.y - 4.0 - (v.position.y + v.size.y - fill_top - 6.0) * ph
			if by > fill_top + 3.0:
				var bx := v.get_center().x + sin(_pulse * 3.0 + float(i) * 2.1) * v.size.x * 0.22
				draw_circle(Vector2(bx, by), 1.4 + 0.7 * float(i % 2),
					Color(1, 1, 1, 0.30 * (1.0 - ph)))
		# urgency: past the sweet band the tube pulses toward the red line
		if charge > sweet_hi:
			var u := clampf((charge - sweet_hi) / (charge_max - sweet_hi), 0.0, 1.0)
			draw_rect(v.grow(3.0), Color(Palette.SPOIL.r, Palette.SPOIL.g, Palette.SPOIL.b,
				(0.25 + 0.30 * sin(_pulse * 9.0)) * u), false, 2.5)
		# release cue
		var in_sweet := charge >= sweet_lo and charge <= sweet_hi
		var cue := "OVERFLOW!" if over else ("RELEASE!" if in_sweet else ("keep holding" if charge < fizzle_below else "…"))
		var ccol := Palette.SPOIL if over else (Palette.PERFECT if in_sweet else Palette.TEXT_DIM)
		UiKit.text_shadowed(self, UiKit.display(800, 1), Vector2(v.get_center().x - 60, v.position.y - 12.0),
			cue, HORIZONTAL_ALIGNMENT_CENTER, 120, 12 if (in_sweet or over) else 10, ccol)
	else:
		UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(v.get_center().x - 40, v.position.y - 12.0),
			"THE VIAL", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Palette.GOLD_DIM)
	# the frozen verdict stamp (where you released)
	if _vial_stamp.has("t"):
		var sf := float(_vial_stamp["t"]) / STAMP_HOLD
		var scol: Color = _vial_stamp["col"]
		var sy: float = lvl_y.call(float(_vial_stamp["lvl"]))
		draw_line(Vector2(v.position.x - 4, sy), Vector2(v.position.x + v.size.x + 4, sy),
			Color(scol.r, scol.g, scol.b, sf), 2.0, true)
		draw_arc(Vector2(v.get_center().x, sy), 5.0 + 20.0 * (1.0 - sf), 0.0, TAU, 20,
			Color(scol.r, scol.g, scol.b, sf * 0.8), 2.0, true)

## Droplet stream: vial → the fed reservoir (a quadratic arc of fading beads).
func _draw_pour_drops(w: float, h: float) -> void:
	if _pour_drops.is_empty():
		return
	var v := _vial_rect()
	var from := Vector2(v.get_center().x, v.position.y + v.size.y * 0.15)
	for d in _pour_drops:
		var t := float(d["t"])
		if t < 0.0:
			continue
		var side := String(d["side"])
		var zone := _venom_zone() if side == "venom" else _rot_zone()
		var to := Vector2(zone.get_center().x, zone.position.y + zone.size.y * 0.35)
		var ctrl := Vector2((from.x + to.x) * 0.5, minf(from.y, to.y) - h * 0.16)
		var p := from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t)
		var col: Color = d["col"]
		draw_circle(p, 3.0 * (1.0 - t * 0.4), Color(col.r, col.g, col.b, 0.9 * (1.0 - t * 0.5)))
		draw_circle(p, 1.2, Color(1, 1, 1, 0.5 * (1.0 - t)))

## The REACTION CHAMBER — bloom, dps numeral, RIPE halo; the ring is the Rupture tap.
func _draw_chamber(w: float, h: float) -> void:
	var c := _chamber_c()
	var r := _chamber_r()
	# acid bloom behind the ring (radius + brightness = the boil)
	if _bloom_d > 0.01:
		var pr := r * (0.5 + 1.1 * _bloom_d) * (1.0 + 0.05 * sin(_pulse * 2.6))
		var steps := 5
		for i in steps:
			var t := 1.0 - float(i) / float(steps)
			var bc := Palette.REACT_HOT if i == steps - 1 else Palette.REACT
			draw_circle(c, pr * t, Color(bc.r, bc.g, bc.b, (0.06 + 0.34 * _bloom_d) * (0.35 + 0.16 * float(i))))
	# RIPE halo — breathing, brightening ring outside the bezel as fuel × power peak
	if _ripe_d > 0.05:
		var halo_r := r + 9.0 + 3.5 * sin(_pulse * (2.0 + 2.5 * _ripe_d))
		var hcol := Palette.REACT.lerp(Palette.REACT_HOT, _ripe_d)
		draw_arc(c, halo_r, 0.0, TAU, 48, Color(hcol.r, hcol.g, hcol.b, 0.15 + 0.55 * _ripe_d),
			2.0 + 4.0 * _ripe_d, true)
	# gilded bezel + engraved ticks (the chamber is an instrument)
	UiKit.gilded_ring(self, c, r, 5.0, 48)
	UiKit.engraved_ticks(self, c, r - 9.0, r - 3.0, 16)
	# dud shiver — an empty rupture tap rattles the bezel
	if _dud_t > 0.0:
		var sx := sin(_pulse * 30.0) * 2.5 * _dud_t
		draw_arc(c + Vector2(sx, 0), r - 1.0, 0.0, TAU, 48,
			Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.5 * _dud_t), 1.5, true)
	# the live reaction numeral
	var hot := _bloom_d > 0.05
	var ncol := Palette.REACT_HOT if hot else Color(Palette.TEXT_DIM.r, Palette.TEXT_DIM.g, Palette.TEXT_DIM.b, 0.6)
	UiKit.text_shadowed(self, UiKit.display(760, 0), Vector2(c.x - 70, c.y - 20),
		"%d" % int(round(_dps_d)), HORIZONTAL_ALIGNMENT_CENTER, 140, UiKit.SIZE["DISPLAY"], ncol)
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(c.x - 60, c.y + 4),
		"REACTION /s", HORIZONTAL_ALIGNMENT_CENTER, 120, 9,
		Palette.REACT if hot else Palette.TEXT_DIM)
	# the tap affordance — "ripe" only when the cash-out is genuinely worth it
	var ripe := _ripe_d > 0.62
	UiKit.engraved_plaque(self, Vector2(c.x, c.y + r + 14.0),
		"RIPE — TAP TO RUPTURE" if ripe else "RUPTURE", ripe, 10)
	# rupture burst: expanding rings + rays
	if _burst.has("t"):
		var bf := float(_burst["t"]) / STAMP_HOLD
		var big := bool(_burst.get("big", false))
		var bcol := Palette.REACT_HOT
		for ring_i in (3 if big else 2):
			var rr := r * (0.4 + (1.6 - 0.3 * float(ring_i)) * (1.0 - bf))
			draw_arc(c, rr, 0.0, TAU, 44, Color(bcol.r, bcol.g, bcol.b, bf * (0.9 - 0.25 * float(ring_i))), 3.0, true)
		var rays := 10 if big else 7
		for i in rays:
			var a := TAU * float(i) / float(rays) + (0.5 if big else 0.0)
			var dir := Vector2(cos(a), sin(a))
			draw_line(c + dir * (r * 0.4), c + dir * (r * 0.4 + (34.0 if big else 22.0) * (1.0 - bf)),
				Color(bcol.r, bcol.g, bcol.b, bf), 2.2, true)

## The balance BEAM — a fine see-saw under the chamber: tilts toward the heavier
## poison, carries a bubble that slides to the light side, goes mint when even.
func _draw_seesaw(w: float, h: float) -> void:
	var c := Vector2(_chamber_c().x, size.y * 0.80)
	var half := w * 0.085
	var ang := _tilt_d * 0.22
	var dirv := Vector2(cos(ang), sin(ang))
	var even := balance > 0.82 and brew_min > 1.0
	var bcol := Palette.PERFECT if even else Palette.GOLD_DIM
	# pivot jewel
	draw_circle(c, 3.5, Palette.GOLD)
	draw_circle(c, 1.6, Palette.GOLD_BRIGHT)
	# the beam (venom end warm / rot end cool)
	draw_line(c - dirv * half, c + dirv * half, bcol, 2.4, true)
	draw_circle(c - dirv * half, 3.0, Palette.VENOM_BREW)
	draw_circle(c + dirv * half, 3.0, Palette.ROT_BREW)
	# the bubble rides toward the LIGHT side (what needs feeding)
	var bub := clampf(-_tilt_d, -1.0, 1.0) * half * 0.7
	draw_circle(c + dirv * bub + Vector2(0, -4.0), 2.6,
		Color(1, 1, 1, 0.75 if even else 0.4))
	var verdict := "BALANCED — potency climbing" if even else \
		("apply BOTH poisons to react" if brew_min <= 1.0 else "tipped — reaction weak")
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(c.x - 110, c.y + 12),
		verdict, HORIZONTAL_ALIGNMENT_CENTER, 220, 9,
		Palette.REACT if even else Palette.TEXT_DIM)

## POTENCY — the footer strip: cool → acid → white-hot, shimmer past 66%, ×mult plate.
func _draw_potency(w: float, h: float) -> void:
	var x := w * 0.20
	var bw := w * 0.56
	var y := h * 0.895
	var bh := 13.0
	UiKit.glass_bar_draw(self, Rect2(x, y, bw, bh), 0.0, Palette.REACT)
	var frac := clampf(_pot_d, 0.0, 1.0)
	if frac > 0.004:
		var fw := bw * frac
		var steps := 8
		for i in steps:
			var t := float(i) / float(steps)
			var seg := Palette.ROT_BREW.lerp(Palette.REACT, minf(1.0, t * 1.8))
			seg = seg.lerp(Palette.REACT_HOT, maxf(0.0, t - 0.55) * 2.2)
			draw_rect(Rect2(x + fw * t, y + 2, fw / steps + 1.0, bh - 4), seg)
		draw_rect(Rect2(x + fw - 2.0, y + 1, 2.5, bh - 2), Palette.REACT_HOT.lightened(0.2))
		# hot shimmer: a travelling highlight once the boil is real
		if frac > 0.66:
			var sh := x + fmod(_pulse * 60.0, maxf(1.0, fw))
			draw_rect(Rect2(sh, y + 2, 6.0, bh - 4), Color(1, 1, 1, 0.22))
			draw_rect(Rect2(x, y + 2, fw, bh - 4), Color(1, 1, 1, 0.05 + 0.06 * sin(_pulse * 5.0)))
	UiKit.engraved_plaque(self, Vector2(x - 42.0, y + bh * 0.5), "POTENCY", frac > 0.66, 9)
	var hot := frac > 0.66
	UiKit.text_shadowed(self, UiKit.display(800, 0), Vector2(x + bw + 8.0, y + bh * 0.5 - 8.0),
		"×%.1f" % pot_mult, HORIZONTAL_ALIGNMENT_LEFT, 60, UiKit.SIZE["TITLE"] - 6,
		Palette.REACT_HOT if hot else Palette.REACT)

## Pour-history rail — the last 8 pours as gems (mint/gold = money, hollow = waste),
## sitting in the calm gap between the chamber and the Rot reservoir.
func _draw_history(w: float, h: float) -> void:
	var rx := w * 0.76
	var y := h * 0.20
	for i in range(_history.size() - 1, -1, -1):
		var e: Dictionary = _history[i]
		var age := _history.size() - 1 - i
		var a := clampf(1.0 - float(age) * 0.11, 0.25, 1.0)
		var px := rx - float(age) * 22.0
		var col: Color = e["col"]
		var pr := 5.0 if bool(e.get("big", false)) else 3.6
		if i == _history.size() - 1 and _hist_pop > 0.0:
			pr *= 1.0 + 0.6 * _hist_pop
		draw_circle(Vector2(px, y), pr, Color(col.r, col.g, col.b, a))
		if bool(e.get("hollow", false)):
			draw_circle(Vector2(px, y), pr * 0.55, Color(0.05, 0.05, 0.08, a))
		UiKit.gilded_ring(self, Vector2(px, y), pr, 1.2, 12)

func _draw_banner(w: float, h: float) -> void:
	var cx := w * 0.5
	var y := h * 0.085
	if _banner_t > 0.0 and _banner != "":
		var f := _banner_t / maxf(0.01, _banner_hold)
		var scale := 1.0 + 0.32 * f * f          # scale-punch: overshoot then settle
		var a := clampf(0.35 + f, 0.0, 1.0)
		var col := Color(_banner_col.r, _banner_col.g, _banner_col.b, a)
		var fnt := UiKit.display(750, 2)
		var sz := int((UiKit.SIZE["GAUGE"] - 6) * scale)
		UiKit.text_shadowed(self, fnt, Vector2(cx - 320, y - sz * 0.5), _banner,
			HORIZONTAL_ALIGNMENT_CENTER, 640, sz, col)
	else:
		# idle cue line — what to do next, in the instrument's own voice
		var cue := ""
		var ccol := Palette.TEXT_DIM
		if charging != "":
			return                              # the vial carries its own cue while held
		if _ripe_d > 0.62:
			cue = ">>  RIPE — CASH THE WAVE  <<"; ccol = Palette.REACT_HOT
		elif brew_min <= 1.0:
			cue = "BREW BOTH POISONS — THEY REACT WHERE THEY MEET"
		elif balance <= 0.72:
			cue = "TIPPED — FEED THE LIGHT SIDE"
		else:
			cue = "KEEP IT FED — THE REACTION EATS THE BREW"
		var pa := 0.7 + 0.3 * sin(_pulse * 2.0) if ccol != Palette.TEXT_DIM else 0.85
		UiKit.text_shadowed(self, UiKit.display(700, 3), Vector2(cx - 300, y - 8),
			cue, HORIZONTAL_ALIGNMENT_CENTER, 600, UiKit.SIZE["LABEL"],
			Color(ccol.r, ccol.g, ccol.b, pa))
