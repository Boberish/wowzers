## One raid frame — a reliquary TRIAGE CARD. A glass panel with a role spine,
## cut role-gem + engraved name, a jeweled health bar (recessed well, two-tone
## fill, gloss, recent-damage ghost), a WOVEN GOLD ABSORB EXTENSION appended past
## the fill, and a dedicated SHIELD CREST on the card's right gutter (absorb value
## + ward-expiry countdown ring) so shields never bury the incoming-damage read.
## Incoming telegraphed damage renders as a hazard-striped slice right-anchored on
## the effective bar end (shield first, then HP — the true triage order); HoTs are
## real icon chips with countdown sweeps + seconds; the dispellable debuff is a wax
## seal with its own countdown. Casting is driven by the HUD off the *hovered*
## frame (mouseover targeting).
##
## Size variants (the frozen solo HUDs keep the classic footprint untouched):
##   "classic" 164×92 (default) · "raid" 218×102 · "xl" 312×120 (healer triage)
class_name RaidFrame
extends Control

signal hovered(frame)
signal unhovered(frame)

var unit_name: String = ""
var role: String = "dps"
var variant: String = "classic":
	set(v):
		variant = v
		custom_minimum_size = _min_size()
var frac: float = 1.0
var hp: int = 0
var maxhp: int = 0
var absorb_frac: float = 0.0
var absorb_val: float = 0.0      ## absolute shield points (feeds the crest)
var ward_remain: float = -1.0    ## seconds until the ward expires (-1 = untimed/none)
var incoming_frac: float = 0.0
var incoming_dmg_frac: float = 0.0
var incoming_lethal: bool = false
var has_debuff: bool = false
var debuff_remain: float = -1.0  ## seconds left on the DoT (-1 = unknown)
var hot_count: int = 0
var hots_rich: Array = []        ## [{icon:String, remain:float, total:float, src:String}]
var dead: bool = false
var bloodied: bool = false
var is_target: bool = false
var is_you: bool = false         ## the player's own card: gilded name
var read_mode: String = ""       ## Mender aspect read overlay: "" | "tide" | "brink"
var ripe: bool = false           ## Bloomweaver: this ally's Growth is in the harvest window
var glint: bool = false          ## Well: this ally is GLINTING (a perfect heal — bonus damage)
var brim_line: float = 0.0       ## Well/BRIM: the pour window start (0 = off) — always visible
var read_a: float = 0.60         ## Tidecaller waterline (keep bars above it)
var read_b: float = 0.40         ## Brinkwarden band top (catch bars inside 0.15..read_b)

const SHIELD_PTS := [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, -0.1),
	Vector2(0.72, 0.42), Vector2(0.38, 0.78), Vector2(0.0, 1.0),
	Vector2(-0.38, 0.78), Vector2(-0.72, 0.42), Vector2(-1.0, -0.1)]

var _pulse: float = 0.0
var _flash_a: float = 0.0
var _flash_col: Color = Color(1, 1, 1)
var _disp_frac: float = 1.0     # eased health fill
var _lag_frac: float = 1.0      # slow-falling "recent damage" trail
var _disp_hp: float = 0.0       # eased hp number
var _hover_t: float = 0.0       # 0..1 hover emphasis
var _disp_absorb: float = 0.0   # eased shield points (crest number)
var _prev_absorb: float = 0.0   # detects ward gained / ward eaten
var _crest_pop: float = 0.0     # 1→0 bloom when a ward lands
var _crest_hit: float = 0.0     # 1→0 shockwave when the shield eats a hit
var _ward_total: float = 0.0    # max-seen ward duration (countdown ring basis)
var _deb_total: float = 0.0     # max-seen debuff duration

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = _min_size()

func _min_size() -> Vector2:
	match variant:
		"xl":
			return Vector2(312, 120)
		"raid":
			return Vector2(240, 102)
		_:
			return Vector2(164, 92)

func flash(col: Color) -> void:
	_flash_col = col
	_flash_a = 0.55

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		hovered.emit(self)
	elif what == NOTIFICATION_MOUSE_EXIT:
		unhovered.emit(self)

func _process(delta: float) -> void:
	_pulse += delta * 5.0
	_flash_a = maxf(0.0, _flash_a - delta * 1.7)
	var k := clampf(delta * 12.0, 0.0, 1.0)
	_disp_frac += (frac - _disp_frac) * k
	_disp_hp += (float(hp) - _disp_hp) * k
	_disp_absorb += (absorb_val - _disp_absorb) * clampf(delta * 14.0, 0.0, 1.0)
	_hover_t += ((1.0 if is_target else 0.0) - _hover_t) * clampf(delta * 14.0, 0.0, 1.0)
	if frac >= _lag_frac:
		_lag_frac = frac
	else:
		_lag_frac = maxf(frac, _lag_frac - delta * 0.7)
	# crest reactions: bloom on a fresh/regrown ward, shockwave when it eats a hit
	if absorb_val > _prev_absorb + 0.5:
		_crest_pop = 1.0
	elif absorb_val < _prev_absorb - 0.5:
		_crest_hit = 1.0
	_prev_absorb = absorb_val
	_crest_pop = maxf(0.0, _crest_pop - delta * 3.2)
	_crest_hit = maxf(0.0, _crest_hit - delta * 3.6)
	# countdown ring bases track the longest remain seen on the live effect
	if absorb_val <= 0.0:
		_ward_total = 0.0
	else:
		_ward_total = maxf(_ward_total, ward_remain)
	if not has_debuff:
		_deb_total = 0.0
	else:
		_deb_total = maxf(_deb_total, debuff_remain)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var xl := variant == "xl"
	var rd := variant == "raid"
	# geometry per variant: the right gutter hosts the shield crest
	var gutter := 56.0 if xl else (46.0 if rd else 38.0)
	var bx := 16.0 if xl else (14.0 if rd else 12.0)
	var by := 32.0 if xl else (28.0 if rd else 32.0)
	var barh := 34.0 if xl else (28.0 if rd else 24.0)
	var barw := w - gutter - bx

	# --- state glow (drawn as the panel's soft shadow) ---
	var glow := Color(0, 0, 0, 0)
	var glow_size := 0.0
	if incoming_lethal and not dead:
		glow = Palette.CRIMSON
		glow_size = 6.0 + 4.0 * (0.5 + 0.5 * sin(_pulse * 1.9))
	elif bloodied and not dead:
		glow = Palette.CRIMSON
		glow_size = 3.0 + 2.0 * (0.5 + 0.5 * sin(_pulse))
	if is_target:
		glow = Palette.GOLD_BRIGHT
		glow_size = maxf(glow_size, 5.0 + 3.0 * _hover_t)

	# --- the glass slab ---
	var panel := StyleBoxFlat.new()
	panel.bg_color = (Palette.BG1 if dead else Palette.FILL_TOP).lerp(Color(1, 1, 1), 0.05 * _hover_t)
	panel.set_corner_radius_all(10)
	var border := _role_color().darkened(0.1)
	var bwidth := 1.0
	if bloodied and not dead:
		border = Palette.CRIMSON
	if is_target:
		border = Palette.GOLD_BRIGHT
		bwidth = 2.0
	panel.border_color = border
	panel.set_border_width_all(int(round(bwidth)))
	if glow_size > 0.0:
		glow.a = 0.55
		panel.shadow_color = glow
		panel.shadow_size = int(glow_size)
	draw_style_box(panel, Rect2(0, 0, w, h))

	# role spine — a lit ribbon down the left edge
	var sp := _role_color() if not dead else Palette.TEXT_DIM.darkened(0.3)
	draw_rect(Rect2(3.0, 7.0, 3.0, h - 14.0), Color(sp.r, sp.g, sp.b, 0.22))
	draw_rect(Rect2(4.0, 9.0, 1.5, h - 18.0), Color(sp.r, sp.g, sp.b, 0.85))

	# top gold sheen
	draw_line(Vector2(9, 3), Vector2(w - 9, 3),
		Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.14), 1.0)

	# --- cut role-gem + engraved name (+ live percent on the bigger cards) ---
	var gem_y := 17.0 if xl else 15.0
	_role_gem(Vector2(bx + 3.0, gem_y), 7.0 if xl else 6.0)
	var name_size: int = UiKit.SIZE["SUBHEAD"] if xl else (UiKit.SIZE["CAPTION"] if rd else UiKit.SIZE["LABEL"])
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(bx + 16.0, gem_y + (6.0 if xl else 5.0)),
		unit_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, barw - (52.0 if xl or rd else 44.0), name_size,
		Palette.TEXT_DIM if dead else (Palette.GOLD_BRIGHT if is_you else Palette.TEXT))
	if (xl or rd) and not dead:
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(bx, gem_y + 5.0),
			str(int(round(_disp_frac * 100.0))) + "%", HORIZONTAL_ALIGNMENT_RIGHT, barw,
			UiKit.SIZE["CAPTION"], _hp_color().lightened(0.25))

	# --- jeweled health bar ---
	var well := StyleBoxFlat.new()
	well.bg_color = Palette.BG0
	well.set_corner_radius_all(6)
	draw_style_box(well, Rect2(bx, by, barw, barh))
	draw_rect(Rect2(bx + 1, by + 1, barw - 2, barh * 0.45), Color(0, 0, 0, 0.35))

	if dead:
		UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(bx, by + barh * 0.5 + 5.0), "FALLEN",
			HORIZONTAL_ALIGNMENT_CENTER, barw, UiKit.SIZE["LABEL"], Palette.LOSE)
	else:
		var fw := barw * clampf(_disp_frac, 0.0, 1.0)
		# recent-damage trail (pale, slow-falling)
		if _lag_frac > _disp_frac + 0.001:
			draw_rect(Rect2(bx + fw, by + 2, barw * (_lag_frac - _disp_frac), barh - 4),
				Color(0.95, 0.85, 0.8, 0.30))
		# two-tone fill + gloss + bright leading edge
		if fw > 1.0:
			var hpc := _hp_color()
			var fill := StyleBoxFlat.new()
			fill.bg_color = hpc.darkened(0.12)
			fill.set_corner_radius_all(5)
			draw_style_box(fill, Rect2(bx, by, fw, barh))
			draw_rect(Rect2(bx, by + barh * 0.62, fw, barh * 0.38), Color(0, 0, 0, 0.22))
			draw_rect(Rect2(bx + 1, by + 2, maxf(0.0, fw - 2), barh * 0.36), Color(1, 1, 1, 0.12))
			if fw > 4.0 and _disp_frac < 0.995:
				draw_rect(Rect2(bx + fw - 2.0, by + 1, 2.0, barh - 2), hpc.lightened(0.45))
		# WOVEN GOLD ABSORB EXTENSION — the shield appended past the fill (WoW-style),
		# full bar height so it reads as "extra health", diagonal weave so it can never
		# be mistaken for the flat green heal ghost.
		var aw := 0.0
		if absorb_frac > 0.0:
			aw = minf(barw * absorb_frac, barw - fw)
			if aw > 0.5:
				var arect := Rect2(bx + fw, by + 1, aw, barh - 2)
				var sh := 0.72 + 0.22 * (0.5 + 0.5 * sin(_pulse * 1.6))
				draw_rect(arect, Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.42 * sh))
				_stripes(arect, Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.45 * sh), 6.0, 1.5)
				draw_rect(Rect2(arect.end.x - 2.0, by + 1, 2.0, barh - 2),
					Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, sh))
			# OVERSHIELD — more shield than the bar can show: bright chevron cap at the
			# bar's end (the crest number carries the truth)
			if barw * absorb_frac > barw - fw + 0.5:
				var cx := bx + barw - 3.0
				for i in 2:
					var ox := cx - float(i) * 5.0
					draw_line(Vector2(ox - 3.0, by + 2.0), Vector2(ox, by + barh * 0.5),
						Palette.GOLD_BRIGHT, 2.0, true)
					draw_line(Vector2(ox, by + barh * 0.5), Vector2(ox - 3.0, by + barh - 2.0),
						Palette.GOLD_BRIGHT, 2.0, true)
		# predicted incoming heal (soft green ghost, lands under the shield)
		if incoming_frac > 0.0:
			var gw := minf(barw * incoming_frac, barw - fw - aw)
			if gw > 0.5:
				draw_rect(Rect2(bx + fw + aw, by + 2, gw, barh - 4),
					Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.28))
		# INCOMING DAMAGE — hazard-striped slice, right-anchored on the EFFECTIVE bar
		# end (fill + shield): the swing eats shield first, then HP — the dodge read.
		if incoming_dmg_frac > 0.0:
			var lose := minf(fw + aw, barw * incoming_dmg_frac)
			var lrect := Rect2(bx + fw + aw - lose, by, lose, barh)
			var la := 0.34 + 0.14 * (0.5 + 0.5 * sin(_pulse * 2.4))
			draw_rect(lrect, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, la))
			_stripes(lrect, Color(Palette.CRIMSON.lightened(0.2).r, Palette.CRIMSON.lightened(0.2).g,
				Palette.CRIMSON.lightened(0.2).b, la + 0.22), 8.0, 2.0)
			draw_rect(Rect2(lrect.position.x, by, 2.0, barh), Palette.CRIMSON.lightened(0.35))
			if incoming_lethal:
				# pulsing lethal edge around the whole bar + warning wedge at the bite point
				var lp := 0.5 + 0.5 * sin(_pulse * 3.2)
				draw_rect(Rect2(bx - 1, by - 1, barw + 2, barh + 2),
					Color(1.0, 0.35, 0.3, 0.35 + 0.45 * lp), false, 2.0)
				if xl or rd:
					var wx := clampf(lrect.position.x, bx + 8.0, bx + barw - 8.0)
					var wy := by - 3.0
					var tri := PackedVector2Array([Vector2(wx, wy - 9.0),
						Vector2(wx + 5.5, wy), Vector2(wx - 5.5, wy)])
					draw_colored_polygon(tri, Palette.CRIMSON.lightened(0.15))
					UiKit.text_shadowed(self, UiKit.display(800), Vector2(wx - 5.5, wy - 1.5), "!",
						HORIZONTAL_ALIGNMENT_CENTER, 11.0, UiKit.SIZE["MICRO"], Color(1, 1, 1, 0.95))
		# hp numbers: the big cards read "hp / max", classic keeps the centered number
		if xl:
			UiKit.text_shadowed(self, UiKit.display(700), Vector2(bx + 9.0, by + barh * 0.5 + 6.0),
				str(int(round(_disp_hp))), HORIZONTAL_ALIGNMENT_LEFT, barw - 18.0,
				UiKit.SIZE["SUBHEAD"], Palette.GOLD_BRIGHT)
			UiKit.text_shadowed(self, UiKit.display(500), Vector2(bx + 9.0, by + barh * 0.5 + 5.0),
				"/ " + str(maxhp), HORIZONTAL_ALIGNMENT_RIGHT, barw - 18.0,
				UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		else:
			UiKit.text_shadowed(self, UiKit.display(600), Vector2(bx, by + barh * 0.5 + 5.0),
				str(int(round(_disp_hp))), HORIZONTAL_ALIGNMENT_CENTER, barw,
				UiKit.SIZE["LABEL"], Palette.GOLD_BRIGHT)

	# --- the Well/BRIM pour window: LAND the heal in this gilded band with no spill =
	#     PERFECT POUR. Always visible on every frame while playing Brim — the aim lives
	#     on the party's bars, so the read is the base click-cast UI itself. ---
	if brim_line > 0.0 and not dead:
		var bwx := bx + barw * clampf(brim_line, 0.0, 1.0)
		draw_rect(Rect2(bwx, by + 2.0, bx + barw - bwx, barh - 4.0),
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.15))
		var bwc := Palette.GOLD_BRIGHT
		bwc.a = 0.8 + (0.15 * sin(_pulse * 2.6) if _disp_frac < brim_line else 0.0)
		draw_line(Vector2(bwx, by - 1.0), Vector2(bwx, by + barh + 1.0), bwc, 2.0, true)
		draw_line(Vector2(bwx - 3.0, by - 3.5), Vector2(bwx, by - 0.5), bwc, 1.5, true)
		draw_line(Vector2(bwx + 3.0, by - 3.5), Vector2(bwx, by - 0.5), bwc, 1.5, true)

	# --- Mender aspect READ overlay: the two aspects want OPPOSITE things off the same
	#     bar. Tidecaller keeps every bar ABOVE a teal waterline; Brinkwarden PARKS bars
	#     inside a crimson band and catches them there. (Only the current aspect draws.) ---
	if read_mode != "" and not dead:
		if read_mode == "tide":
			var lx := bx + barw * clampf(read_a, 0.0, 1.0)
			var below := _disp_frac < read_a
			var lc := Palette.STEEL.lightened(0.4)
			lc.a = 0.75 + (0.2 * (0.5 + 0.5 * sin(_pulse * 2.0)) if below else 0.0)
			draw_line(Vector2(lx, by - 1.0), Vector2(lx, by + barh + 1.0), lc, 2.0, true)
			draw_line(Vector2(lx - 3.0, by - 3.5), Vector2(lx, by - 0.5), lc, 1.5, true)
			draw_line(Vector2(lx + 3.0, by - 3.5), Vector2(lx, by - 0.5), lc, 1.5, true)
		elif read_mode == "brink":
			var x1 := bx + barw * 0.15
			var x2 := bx + barw * clampf(read_b, 0.0, 1.0)
			draw_rect(Rect2(x1, by + 2.0, x2 - x1, barh - 4.0),
				Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.16))
			draw_line(Vector2(x2, by - 1.0), Vector2(x2, by + barh + 1.0),
				Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.6), 1.5, true)

	# thin gilded bevel over the bar frame (lit top-left)
	draw_line(Vector2(bx, by), Vector2(bx + barw, by), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.5), 1.0, true)
	draw_line(Vector2(bx, by + barh), Vector2(bx + barw, by + barh), Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)

	# --- THE SHIELD CREST — the card's right gutter belongs to the ward ---
	_draw_crest(Vector2(w - gutter * 0.5 - 2.0, h * 0.5), 20.0 if xl else (15.0 if rd else 12.0), xl, xl or rd)

	# --- HoT chips (real icons + countdown sweeps) or the classic gem fallback ---
	if not hots_rich.is_empty() and not dead:
		_draw_hot_chips(bx, by, barh, barw, xl)
	elif hot_count > 0 and not dead:
		for i in mini(hot_count, 3):
			var px := w - gutter - 6.0 - float(i) * 13.0
			var gcol := Palette.GOLD_BRIGHT if (ripe and i == 0) else Palette.WIN
			if ripe and i == 0:
				var rh := Palette.GOLD_BRIGHT
				rh.a = 0.28 + 0.22 * sin(_pulse * 2.2)
				draw_circle(Vector2(px, 13.0), 10.0, rh)     # "◆ RIPE" glow
			draw_circle(Vector2(px, 13.0), 6.5, Color(gcol.r, gcol.g, gcol.b, 0.20))
			UiKit.gilded_pip(self, Vector2(px, 13.0), 4.0, true, gcol)

	# --- GLINT (Well): a gold spark on the ally you perfectly healed — their blade
	# cuts deeper for a few seconds. A pulsing mark by the name.
	if glint and not dead:
		var gc := Palette.GOLD_BRIGHT
		gc.a = 0.55 + 0.35 * sin(_pulse * 3.2)
		draw_string(ThemeDB.fallback_font, Vector2(bx + 2.0, 12.0), "✦ GLINT",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, gc)

	# dispellable debuff: a pulsing crimson wax seal with its own countdown ring.
	# On the XL card it takes the first column of the chip row (timer beneath, in
	# line with the HoT timers); smaller cards keep it in the bottom-left corner.
	if has_debuff and not dead:
		var sr := 9.0 if xl else 7.5
		var sc := Vector2(bx + 14.0, by + barh + 20.0) if xl \
			else Vector2(bx + sr + 2.0, h - sr - 6.0)
		var sa := 0.55 + 0.40 * sin(_pulse)
		draw_circle(sc, sr, Color(Palette.CRIMSON_DEEP.r, Palette.CRIMSON_DEEP.g, Palette.CRIMSON_DEEP.b, 0.95))
		draw_circle(sc, sr - 2.0, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, sa))
		draw_circle(sc + Vector2(-1.5, -2.0), 1.4, Color(1, 1, 1, 0.6))
		if debuff_remain >= 0.0 and _deb_total > 0.05:
			var df := clampf(debuff_remain / _deb_total, 0.0, 1.0)
			draw_arc(sc, sr + 2.5, -PI * 0.5, -PI * 0.5 + TAU * df, 26,
				Palette.CRIMSON.lightened(0.25), 2.0, true)
			if xl:
				UiKit.text_shadowed(self, UiKit.display(600), Vector2(sc.x - 17.0, sc.y + sr + 11.0),
					_fmt_secs(debuff_remain), HORIZONTAL_ALIGNMENT_CENTER, 34.0,
					UiKit.SIZE["MICRO"], Palette.CRIMSON.lightened(0.35))
			else:
				UiKit.text_shadowed(self, UiKit.display(600), Vector2(sc.x + sr + 4.0, sc.y + 4.0),
					_fmt_secs(debuff_remain), HORIZONTAL_ALIGNMENT_LEFT, 30.0,
					UiKit.SIZE["MICRO"], Palette.CRIMSON.lightened(0.35))
		else:
			draw_arc(sc, sr, 0.0, TAU, 20, Palette.CRIMSON.lightened(0.2), 1.2, true)

	# flash overlay (rounded)
	if _flash_a > 0.0:
		var fl := StyleBoxFlat.new()
		fl.bg_color = Color(_flash_col.r, _flash_col.g, _flash_col.b, _flash_a)
		fl.set_corner_radius_all(10)
		draw_style_box(fl, Rect2(0, 0, w, h))

	# the hovered target earns filigree corners
	if is_target and _hover_t > 0.3:
		UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1), 9.0)
		UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1), 9.0)
		UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1), 9.0)
		UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1), 9.0)

## The gilded shield crest: absorb value cut into a heater shield, ringed by the
## ward-expiry countdown. Blooms when a ward lands, shockwaves when it eats a hit.
## An empty gutter shows a ghost socket on the raid/XL cards (classic stays bare).
func _draw_crest(c: Vector2, s: float, xl: bool, socket: bool) -> void:
	var live := absorb_val > 0.5 and not dead
	var ring_r := s * 1.5
	if not live:
		if socket and not dead:
			var ghost := _shield_poly(c, s * 0.9)
			ghost.append(ghost[0])
			draw_polyline(ghost, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.28), 1.0, true)
			draw_arc(c, ring_r, 0.0, TAU, 40, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.14), 1.5, true)
		return
	var pop := 1.0 + 0.22 * _crest_pop
	var sp := s * pop
	# ward countdown ring (dim track + live arc; hurries to crimson as it runs out)
	draw_arc(c, ring_r, 0.0, TAU, 40, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.30), 2.5, true)
	if ward_remain >= 0.0 and _ward_total > 0.05:
		var wf := clampf(ward_remain / _ward_total, 0.0, 1.0)
		var rc := Palette.GOLD_BRIGHT
		if ward_remain < 1.6:
			rc = Palette.GOLD_BRIGHT.lerp(Palette.CRIMSON, 0.5 + 0.5 * sin(_pulse * 3.0))
		draw_arc(c, ring_r, -PI * 0.5, -PI * 0.5 + TAU * wf, 40, rc, 3.0 if xl else 2.5, true)
	# shockwave when the shield eats a hit
	if _crest_hit > 0.0:
		draw_arc(c, ring_r + (1.0 - _crest_hit) * 13.0, 0.0, TAU, 40,
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.7 * _crest_hit), 2.0, true)
	# the shield body: shadow → plate → inner facet → top gloss → gilded outline
	draw_colored_polygon(_shield_poly(c + Vector2(0, 1.5), sp), Color(0, 0, 0, 0.45))
	draw_colored_polygon(_shield_poly(c, sp), Palette.GOLD.darkened(0.42).lerp(Palette.GOLD_BRIGHT, 0.35 * _crest_pop))
	draw_colored_polygon(_shield_poly(c, sp * 0.82), Palette.GOLD.darkened(0.18))
	var gl := PackedVector2Array()
	for p in [Vector2(-0.78, -0.95), Vector2(0.78, -0.95), Vector2(0.7, -0.38), Vector2(-0.7, -0.38)]:
		gl.append(c + Vector2(p.x * sp * 0.85, p.y * sp))
	draw_colored_polygon(gl, Color(1, 1, 1, 0.13))
	var outline := _shield_poly(c, sp)
	outline.append(outline[0])
	draw_polyline(outline, Palette.GOLD_BRIGHT, 1.5, true)
	# the number IS the shield
	var vs: int = UiKit.SIZE["LABEL"] if xl else UiKit.SIZE["CAPTION"]
	var vtxt := str(int(round(_disp_absorb)))
	UiKit.text_shadowed(self, UiKit.display(800), Vector2(c.x - sp, c.y + (5.0 if xl else 4.0) - sp * 0.12),
		vtxt, HORIZONTAL_ALIGNMENT_CENTER, sp * 2.0, vs, Color(0.1, 0.08, 0.04, 0.9))
	UiKit.text_shadowed(self, UiKit.display(800), Vector2(c.x - sp, c.y + (4.0 if xl else 3.0) - sp * 0.12),
		vtxt, HORIZONTAL_ALIGNMENT_CENTER, sp * 2.0, vs, Color(1, 0.96, 0.82))
	# ward seconds under the ring (XL triage card only)
	if xl and ward_remain >= 0.0:
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(c.x - 20.0, c.y + ring_r + 12.0),
			_fmt_secs(ward_remain), HORIZONTAL_ALIGNMENT_CENTER, 40.0,
			UiKit.SIZE["MICRO"], Palette.GOLD)

## HoT chips along the card's footer: icon in a recessed well, countdown sweep
## around it, seconds underneath (XL). A ripe Growth turns gold (harvest now!).
func _draw_hot_chips(bx: float, by: float, barh: float, barw: float, xl: bool) -> void:
	var cs := 26.0 if xl else 20.0
	var y0 := by + barh + (7.0 if xl else 6.0)
	var x0 := bx + (34.0 if xl else 28.0)          # clear of the debuff seal
	var maxn := maxi(1, int(floor((barw - (x0 - bx)) / (cs + 8.0))))
	var n := mini(hots_rich.size(), maxn)
	for i in n:
		var hd: Dictionary = hots_rich[i]
		var cc := Vector2(x0 + float(i) * (cs + 8.0) + cs * 0.5, y0 + cs * 0.5)
		var is_ripe: bool = ripe and String(hd.get("src", "")) == "growth"
		var accent := Palette.GOLD_BRIGHT if is_ripe else Palette.WIN
		if is_ripe:
			var rh := Palette.GOLD_BRIGHT
			rh.a = 0.22 + 0.18 * sin(_pulse * 2.2)
			draw_circle(cc, cs * 0.85, rh)
		var wellb := StyleBoxFlat.new()
		wellb.bg_color = Palette.BG0
		wellb.set_corner_radius_all(5)
		wellb.border_color = Color(accent.r, accent.g, accent.b, 0.45)
		wellb.set_border_width_all(1)
		draw_style_box(wellb, Rect2(cc.x - cs * 0.5, cc.y - cs * 0.5, cs, cs))
		var tex := RuneIcons.tex(String(hd.get("icon", "")))
		if tex != null:
			draw_texture_rect(tex, Rect2(cc.x - cs * 0.5 + 3.0, cc.y - cs * 0.5 + 3.0, cs - 6.0, cs - 6.0),
				false, accent)
		else:
			UiKit.gilded_pip(self, cc, cs * 0.22, true, accent)
		var remain := float(hd.get("remain", 0.0))
		var total := maxf(float(hd.get("total", 0.0)), 0.05)
		var hf := clampf(remain / total, 0.0, 1.0)
		draw_arc(cc, cs * 0.62, -PI * 0.5, -PI * 0.5 + TAU * hf, 26, accent, 2.5, true)
		# stacking-HoT depth badge (Bloomweaver seed bed): "×N" in a gilded pip, top-right
		var cnt := int(hd.get("count", 1))
		if cnt > 1:
			var bc := cc + Vector2(cs * 0.46, -cs * 0.46)
			draw_circle(bc, cs * 0.34, Palette.BG0)
			draw_circle(bc, cs * 0.30, accent)
			UiKit.text_shadowed(self, UiKit.display(800), Vector2(bc.x - cs * 0.5, bc.y - cs * 0.36),
				"×%d" % cnt, HORIZONTAL_ALIGNMENT_CENTER, cs, UiKit.SIZE["MICRO"], Palette.BG0)
		if xl:
			UiKit.text_shadowed(self, UiKit.display(600), Vector2(cc.x - cs * 0.5 - 4.0, y0 + cs + 11.0),
				_fmt_secs(remain), HORIZONTAL_ALIGNMENT_CENTER, cs + 8.0,
				UiKit.SIZE["MICRO"], accent.darkened(0.1))
	if hots_rich.size() > n:
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(x0 + float(n) * (cs + 8.0), y0 + cs * 0.5 + 4.0),
			"+" + str(hots_rich.size() - n), HORIZONTAL_ALIGNMENT_LEFT, 24.0,
			UiKit.SIZE["CAPTION"], Palette.WIN)

## diagonal 45° stripes clipped to a rect — the hazard/weave texture
func _stripes(rect: Rect2, col: Color, spacing: float, width: float) -> void:
	var x := rect.position.x - rect.size.y
	while x < rect.end.x:
		var p1 := Vector2(x, rect.end.y)
		var p2 := Vector2(x + rect.size.y, rect.position.y)
		if p2.x > p1.x:
			if p1.x < rect.position.x:
				p1 = p1.lerp(p2, (rect.position.x - p1.x) / (p2.x - p1.x))
			if p2.x > rect.end.x:
				p2 = p2.lerp(p1, (p2.x - rect.end.x) / (p2.x - p1.x))
			if p2.x > p1.x:
				draw_line(p1, p2, col, width, false)
		x += spacing

func _shield_poly(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in SHIELD_PTS:
		pts.append(c + Vector2(p.x * s * 0.85, p.y * s))
	return pts

func _fmt_secs(t: float) -> String:
	if t >= 3.0:
		return str(int(ceil(t)))
	return "%.1f" % maxf(t, 0.0)

## a small cut gem in the unit's role colour (tank = shield-ish diamond, dps = spark)
func _role_gem(at: Vector2, r: float) -> void:
	var col := _role_color()
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0),
		at + Vector2(0, r), at + Vector2(-r, 0)])
	draw_colored_polygon(pts, col.darkened(0.25))
	draw_line(pts[0], pts[1], Palette.GOLD, 1.2, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[3], pts[0], Palette.GOLD, 1.2, true)
	draw_circle(at + Vector2(-r * 0.25, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.7))

func _role_color() -> Color:
	match role:
		"tank":
			return Palette.STEEL
		"healer":
			return Palette.WIN
		_:
			return Palette.GOLD_DIM

func _hp_color() -> Color:
	var f := clampf(_disp_frac, 0.0, 1.0)
	if f > 0.5:
		return Palette.RAGE.lerp(Palette.WIN, clampf((f - 0.5) * 2.0, 0.0, 1.0))
	return Palette.CRIMSON.lerp(Palette.RAGE, clampf(f * 2.0, 0.0, 1.0))
