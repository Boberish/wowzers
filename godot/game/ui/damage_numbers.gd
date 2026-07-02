## DamageNumbers — floating boss-damage numerals, styled BY SOURCE. One source of
## truth for the solo Twinfang HUD and the raid HUD (and any future HUD): the kit
## tags each `boss_hit` event with a `kind`, and this renders it so a non-auto never
## looks like an auto-Strike. YOUR OWN hits get the full treatment (source colour,
## bigger, longer, scale-punch, crit burst); an ALLY's hit (raid) is quiet ambient
## DPS texture so your rotation still reads. Pure view layer — never checksummed.
class_name DamageNumbers
extends RefCounted

## Per-source look. Unknown / empty `kind` (non-Twinfang classes route damage through
## the generic `damage_boss`, no source tag) falls back to the caller's class accent.
static var STYLE := {
	"strike":   {"col": Palette.GOLD,        "base": 24, "life": 1.15, "punch": 1.0,  "special": false},
	"perfect":  {"col": Palette.GOLD_BRIGHT, "base": 29, "life": 1.30, "punch": 1.12, "special": false},
	"flurry":   {"col": Palette.CP,          "base": 27, "life": 1.30, "punch": 1.12, "special": true},
	"finisher": {"col": Palette.CP,          "base": 38, "life": 1.60, "punch": 1.28, "special": true},
	"coup":     {"col": Palette.PERFECT,     "base": 46, "life": 1.85, "punch": 1.40, "special": true},
	"rupture":  {"col": Palette.POISON,      "base": 46, "life": 1.85, "punch": 1.40, "special": true},
	"poison":   {"col": Palette.POISON,      "base": 22, "life": 1.05, "punch": 1.0,  "special": false},
}

## Spawn one numeral on `layer` (a full-rect fx Control; it owns the tween + children).
##   amt     damage magnitude (<=0 is ignored)
##   kind    source tag; a STYLE key uses that look, "" / unknown → `accent`
##   crit    bold outlined burst + spark ring (only honoured for own hits)
##   mine    true = the local player's hit (full emphasis) · false = an ally's (dim ambient)
##   base_at FRACTIONAL spawn anchor over the boss, e.g. Vector2(0.72, 0.28)
##   lane    rotating index (bump it per call) so a burst fans across lanes not a pile
##   accent  colour for a generic own-hit (the seat's class colour)
static func spawn(layer: Control, amt: float, kind: String, crit: bool, mine: bool,
		base_at: Vector2, lane: int, accent: Color = Palette.GOLD) -> void:
	if layer == null or amt <= 0.0:
		return
	var style: Dictionary = STYLE.get(kind, STYLE["strike"])
	var special := bool(style["special"])
	var col: Color = style["col"]
	if not STYLE.has(kind):
		col = accent                          # no source info → the class accent
	var fs := int(style["base"])
	var life := float(style["life"])
	var punch := float(style["punch"])

	if not mine:
		# ally damage is ambient: small, dim, quick, no flourish — your hits lead
		col = accent.lerp(Palette.GOLD, 0.35)
		fs = clampi(int(round(float(fs) * 0.6)), 15, 23)
		life = 0.7
		punch = 1.0
		special = false
		crit = false

	# heavier hits are physically bigger, on top of the per-kind base
	if amt >= 200.0: fs += (16 if mine else 5)
	elif amt >= 110.0: fs += (10 if mine else 4)
	elif amt >= 55.0: fs += (5 if mine else 2)

	var text := "-%d" % int(amt)
	if crit:
		fs = int(round(float(fs) * 1.55))
		life += 0.45
		punch = maxf(punch, 1.35) + 0.25
		col = col.lightened(0.28)
		text = "✦ %d ✦" % int(amt)

	# fan across 5 rotating lanes (odd lanes staggered down a row) so bursts spread
	var l5 := ((lane % 5) + 5) % 5
	var lane_x := lerpf(-0.175, 0.175, float(l5) / 4.0)
	var lane_y := 0.05 if l5 % 2 == 1 else 0.0
	var at := layer.size * (base_at + Vector2(lane_x, lane_y)) \
		+ Vector2(randf_range(-12.0, 12.0), randf_range(-14.0, 14.0))

	var box := 320.0
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(box, 0)
	l.add_theme_font_override("font", UiKit.display(900 if crit else (800 if special else 750)))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if crit or special:
		l.add_theme_color_override("font_outline_color", Color(0.06, 0.02, 0.0, 0.92))
		l.add_theme_constant_override("outline_size", 8 if crit else 5)
	l.modulate.a = 1.0 if mine else 0.66
	l.position = at - Vector2(box * 0.5, float(fs) * 0.5)
	l.pivot_offset = Vector2(box * 0.5, float(fs) * 0.5)
	layer.add_child(l)

	var rise := (-40.0 - float(fs)) if mine else -26.0
	var tw := layer.create_tween()
	tw.set_parallel(true)
	if punch > 1.0:
		l.scale = Vector2(punch, punch)
		tw.tween_property(l, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + rise, life) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:x", l.position.x + randf_range(-16.0, 16.0), life)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.42).set_delay(life * 0.58)
	tw.chain().tween_callback(l.queue_free)

	if crit:
		_crit_burst(layer, at, col)

## A crit spark: an expanding ring + radiating spokes at the numeral, self-freeing.
static func _crit_burst(layer: Control, pos: Vector2, col: Color) -> void:
	var n := Node2D.new()
	n.position = pos
	var st := {"r": 10.0, "a": 0.95}
	n.draw.connect(func():
		var c := Color(col, float(st["a"]))
		n.draw_arc(Vector2.ZERO, float(st["r"]), 0.0, TAU, 40, c, 3.0, true)
		for k in 8:
			var ang := TAU * float(k) / 8.0
			var d := Vector2(cos(ang), sin(ang))
			n.draw_line(d * (float(st["r"]) * 0.6), d * (float(st["r"]) * 0.95), c, 2.0, true))
	layer.add_child(n)
	var tw := layer.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(r): st["r"] = r; n.queue_redraw(), 10.0, 74.0, 0.42) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(av): st["a"] = av, 0.95, 0.0, 0.42)
	tw.chain().tween_callback(n.queue_free)
