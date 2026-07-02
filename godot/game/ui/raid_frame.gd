## One raid frame — a reliquary card. A glass panel with a cut role-gem and engraved
## name plaque, a jeweled health bar (recessed well, two-tone fill, gloss, leading
## edge, gilded bevel) with a "recent damage" ghost trail, a shimmering gold absorb
## cap, gilded HoT gems, a pulsing wax-seal debuff marker, and hover/bloodied/lethal
## state glows with filigree corners on the hovered target. Casting is driven by the
## HUD off the *hovered* frame (mouseover targeting).
class_name RaidFrame
extends Control

signal hovered(frame)
signal unhovered(frame)

var unit_name: String = ""
var role: String = "dps"
var frac: float = 1.0
var hp: int = 0
var maxhp: int = 0
var absorb_frac: float = 0.0
var incoming_frac: float = 0.0
var incoming_dmg_frac: float = 0.0
var incoming_lethal: bool = false
var has_debuff: bool = false
var hot_count: int = 0
var dead: bool = false
var bloodied: bool = false
var is_target: bool = false

var _pulse: float = 0.0
var _flash_a: float = 0.0
var _flash_col: Color = Color(1, 1, 1)
var _disp_frac: float = 1.0     # eased health fill
var _lag_frac: float = 1.0      # slow-falling "recent damage" trail
var _disp_hp: float = 0.0       # eased hp number
var _hover_t: float = 0.0       # 0..1 hover emphasis

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(164, 92)

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
	_hover_t += ((1.0 if is_target else 0.0) - _hover_t) * clampf(delta * 14.0, 0.0, 1.0)
	if frac >= _lag_frac:
		_lag_frac = frac
	else:
		_lag_frac = maxf(frac, _lag_frac - delta * 0.7)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	# --- state glow (drawn as the panel's soft shadow) ---
	var glow := Color(0, 0, 0, 0)
	var glow_size := 0.0
	if incoming_lethal and not dead:
		glow = Palette.CRIMSON
		glow_size = 5.0 + 4.0 * (0.5 + 0.5 * sin(_pulse * 1.9))
	elif bloodied and not dead:
		glow = Palette.CRIMSON
		glow_size = 3.0 + 2.0 * (0.5 + 0.5 * sin(_pulse))
	if is_target:
		glow = Palette.GOLD_BRIGHT
		glow_size = maxf(glow_size, 5.0 + 3.0 * _hover_t)

	# --- the glass slab ---
	var panel := StyleBoxFlat.new()
	panel.bg_color = (Palette.BG1 if dead else Palette.FILL_TOP).lerp(Color(1, 1, 1), 0.05 * _hover_t)
	panel.set_corner_radius_all(9)
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

	# top gold sheen
	draw_line(Vector2(8, 3), Vector2(w - 8, 3),
		Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.14), 1.0)

	# --- cut role-gem + engraved name ---
	_role_gem(Vector2(14.0, 15.0), 6.0)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(26, 20), unit_name.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, w - 34, UiKit.SIZE["LABEL"],
		Palette.TEXT_DIM if dead else Palette.TEXT)

	# --- jeweled health bar ---
	var bx := 10.0
	var by := 34.0
	var barw := w - 20.0
	var barh := 24.0
	# recessed well
	var well := StyleBoxFlat.new()
	well.bg_color = Palette.BG0
	well.set_corner_radius_all(6)
	draw_style_box(well, Rect2(bx, by, barw, barh))
	draw_rect(Rect2(bx + 1, by + 1, barw - 2, barh * 0.45), Color(0, 0, 0, 0.35))

	if dead:
		UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(bx, by + 17), "FALLEN",
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
		# predicted incoming damage (red) on the "about to lose" slice
		if incoming_dmg_frac > 0.0:
			var lose := minf(fw, barw * incoming_dmg_frac)
			draw_rect(Rect2(bx + fw - lose, by, lose, barh), Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.42))
		# predicted incoming heal (soft green ghost)
		if incoming_frac > 0.0:
			var gw := minf(barw * incoming_frac, barw - fw)
			draw_rect(Rect2(bx + fw, by, gw, barh), Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.28))
		# absorb — a shimmering gold cap along the top of the bar
		if absorb_frac > 0.0:
			var sw := minf(barw, (clampf(_disp_frac, 0.0, 1.0) + absorb_frac) * barw)
			var sh := 0.6 + 0.4 * (0.5 + 0.5 * sin(_pulse * 1.6))
			draw_rect(Rect2(bx, by, sw, 5.0), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, sh))
			draw_rect(Rect2(bx + sw - 2.0, by, 2.0, barh), Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, sh))
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(bx, by + 17), str(int(round(_disp_hp))),
			HORIZONTAL_ALIGNMENT_CENTER, barw, UiKit.SIZE["LABEL"], Palette.GOLD_BRIGHT)

	# thin gilded bevel over the bar frame (lit top-left)
	draw_line(Vector2(bx, by), Vector2(bx + barw, by), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.5), 1.0, true)
	draw_line(Vector2(bx, by + barh), Vector2(bx + barw, by + barh), Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)

	# flash overlay (rounded)
	if _flash_a > 0.0:
		var fl := StyleBoxFlat.new()
		fl.bg_color = Color(_flash_col.r, _flash_col.g, _flash_col.b, _flash_a)
		fl.set_corner_radius_all(9)
		draw_style_box(fl, Rect2(0, 0, w, h))

	# HoT gems (gilded, glowing green)
	for i in mini(hot_count, 3):
		var px := w - 14.0 - float(i) * 13.0
		draw_circle(Vector2(px, 13.0), 6.5, Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.20))
		UiKit.gilded_pip(self, Vector2(px, 13.0), 4.0, true, Palette.WIN)

	# dispellable debuff: a pulsing crimson wax seal
	if has_debuff and not dead:
		var sc := Vector2(16.0, h - 14.0)
		var sa := 0.55 + 0.40 * sin(_pulse)
		draw_circle(sc, 7.5, Color(Palette.CRIMSON_DEEP.r, Palette.CRIMSON_DEEP.g, Palette.CRIMSON_DEEP.b, 0.95))
		draw_circle(sc, 5.5, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, sa))
		draw_arc(sc, 7.5, 0.0, TAU, 20, Palette.CRIMSON.lightened(0.2), 1.2, true)
		draw_circle(sc + Vector2(-1.5, -2.0), 1.4, Color(1, 1, 1, 0.6))

	# the hovered target earns filigree corners
	if is_target and _hover_t > 0.3:
		UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1), 9.0)
		UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1), 9.0)
		UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1), 9.0)
		UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1), 9.0)

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
