## VerdanceGauge — the Bloomweaver's spec centrepiece: a BLOOMING MEDALLION. A living
## jade core fills as Verdance builds (earned ONLY by effective healing); eight leaf
## petals unfurl around it as their slice of the gauge fills, shimmering gold once the
## pool is worth spending. Wildgrove grows Growth-pips along the left wing and ignites
## the ◆ FLOURISH ◆ line at 3+; Thornveil tallies reflected thorn damage in bark amber.
## Pure view; the HUD feeds the same fields as before.
class_name VerdanceGauge
extends ClassGauge

var aspect: String = "wildgrove"
var verdance: float = 0.0
var verdance_max: float = 100.0
var min_spend: float = 20.0
var flourish: bool = false          ## Wildgrove: garden bonus is live
var flourish_hi: bool = false       ## …and the field is LUSH (upgraded bonus)
var garden: int = 0                 ## allies carrying a seed bed
var total_seeds: int = 0            ## Σ seeds across the party (lights Flourish)
var flourish_lo: int = 6            ## total seeds that light Flourish
var flourish_ripe: bool = false     ## DEPRECATED (Seedfall dropped ripen) — kept so external setters don't error
var ripe_garden: int = 0            ## DEPRECATED — retained for raid_hud/gallery compatibility
var thorns: int = 0                 ## Thornveil: total reflected damage
var thorn_charge: int = 0           ## Thornveil: snap-streak (0..max)
var thorn_charge_max: int = 5
var thorns_pct: float = 0.45        ## current reflect fraction (ramps with charge)
var _bloom_t: float = 0.0           ## petal pop when a new petal completes
var _last_lit: int = 0

func _tick(delta: float) -> void:
	var lit := int(clampf(verdance / maxf(verdance_max, 1.0), 0.0, 1.0) * 8.0)
	if lit > _last_lit:
		_bloom_t = 1.0                 # a petal just unfurled
	_last_lit = lit
	_bloom_t = maxf(0.0, _bloom_t - delta * 2.4)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var c := Vector2(w * 0.5, h * 0.5 - 6.0)
	var R := 34.0
	var frac := clampf(verdance / maxf(verdance_max, 1.0), 0.0, 1.0)
	var spendable := verdance >= min_spend

	# ornamental wings (left carries the garden, right ignites with the aspect payoff)
	UiKit.wing_flourish(self, c, -1.0, 205.0, Palette.VERDANCE, spendable)
	UiKit.wing_flourish(self, c, 1.0, 205.0,
		Palette.VERDANCE if aspect == "wildgrove" else Palette.THORN,
		flourish if aspect == "wildgrove" else thorn_charge > 0)

	# ---- the jade core ----
	if spendable or _bloom_t > 0.0:
		var halo := Palette.VERDANCE
		halo.a = (0.14 + 0.10 * sin(pulse * 2.0) if spendable else 0.0) + 0.18 * _bloom_t
		draw_circle(c, R * 1.65, halo)
	draw_circle(c, R * 0.80, Palette.FILL_BOT)
	draw_circle(c - Vector2(0, R * 0.16), R * 0.66, Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.5))
	# recessed track + living fill
	draw_arc(c, R, 0.0, TAU, 48, Color(0.07, 0.08, 0.12), 7.0, true)
	if frac > 0.01:
		var col_hi := Palette.GOLD_BRIGHT if spendable else Palette.VERDANCE
		UiKit.gradient_arc(self, c, R, -PI / 2.0, -PI / 2.0 + TAU * frac, 7.0,
			Palette.VERDANCE.darkened(0.45), col_hi, 48)

	# ---- eight leaf petals, unfurling as their slice fills ----
	for i in range(8):
		var pf := clampf(frac * 8.0 - float(i), 0.0, 1.0)
		if pf < 0.05:
			continue
		var a := -PI / 2.0 + TAU * (float(i) + 0.5) / 8.0
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		var base := c + dir * (R + 6.0)
		var ln := (7.0 + 9.0 * pf)
		if i == _last_lit - 1 and _bloom_t > 0.0:
			ln += 3.0 * _bloom_t
		var tip := base + dir * ln
		var mid := base + dir * ln * 0.5
		var col := Palette.VERDANCE if pf >= 1.0 else Palette.VERDANCE.darkened(0.45)
		if pf >= 1.0 and spendable:
			col = col.lerp(Palette.GOLD_BRIGHT, 0.25 + 0.25 * sin(pulse + float(i)))
		# the leaf: a pointed four-vertex blade with a darker vein
		draw_colored_polygon(PackedVector2Array([base, mid + side * 3.4 * pf, tip, mid - side * 3.4 * pf]), col)
		draw_line(base, tip, col.darkened(0.35), 1.0, true)
		if pf >= 1.0:
			draw_circle(tip, 1.8, col.lightened(0.25))
	UiKit.gilded_ring(self, c, R + 26.0, 1.8, 52)

	# numeral + label
	UiKit.text_shadowed(self, UiKit.display(750), Vector2(c.x - R, c.y + 9.0), str(int(verdance)),
		HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["GAUGE"],
		Palette.GOLD_BRIGHT if spendable else Palette.TEXT)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(c.x - R * 1.5, c.y + 23.0), "VERDANCE",
		HORIZONTAL_ALIGNMENT_CENTER, R * 3.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

	# ---- left wing: the garden — Growth pips on an engraved rail (Wildgrove) ----
	if aspect == "wildgrove":
		var gx0 := c.x - 96.0
		var spacing := 34.0
		draw_line(Vector2(gx0 - spacing * 3.0 - 14.0, c.y), Vector2(gx0 + 12.0, c.y), Palette.BG0, 4.0, true)
		draw_line(Vector2(gx0 - spacing * 3.0 - 14.0, c.y + 1.0), Vector2(gx0 + 12.0, c.y + 1.0),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.2, true)
		for i in 4:
			var gp := Vector2(gx0 - spacing * float(i), c.y)
			var on := i < garden                       # allies carrying a bed (breadth)
			if on and flourish:
				var gh := Palette.VERDANCE
				gh.a = 0.20 + 0.14 * sin(pulse * 2.2 + float(i))
				draw_circle(gp, 14.0, gh)
			UiKit.gilded_pip(self, gp, 8.0, on, Palette.VERDANCE)
		UiKit.engraved_plaque(self, Vector2(gx0 - spacing * 1.5, h - 11.0),
			"%d SEEDS" % total_seeds, flourish)

	# ---- the payoff line ----
	if aspect == "wildgrove":
		if flourish_hi:
			UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(c.x + 40.0, h - 7.0),
				"◆ LUSH FIELD +40% ◆", HORIZONTAL_ALIGNMENT_CENTER, 260.0, UiKit.SIZE["CAPTION"],
				Palette.GOLD_BRIGHT.lerp(Palette.VERDANCE, 0.5 + 0.5 * sin(pulse * 2.0)))
		elif flourish:
			UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(c.x + 40.0, h - 7.0),
				"FLOURISH +25% — STACK FOR MORE", HORIZONTAL_ALIGNMENT_CENTER, 260.0, UiKit.SIZE["CAPTION"],
				Palette.VERDANCE.lerp(Palette.GOLD_BRIGHT, 0.4))
		else:
			UiKit.engraved_plaque(self, Vector2(c.x + 168.0, h - 13.0),
				"%d / %d SEEDS → FLOURISH" % [total_seeds, flourish_lo], false)
	else:
		# THORN CHARGE — the snap-streak: pips light per consecutive Perfect Ward, reflect ramps.
		var tx0 := c.x + 78.0
		var tsp := 26.0
		for i in thorn_charge_max:
			var tp := Vector2(tx0 + tsp * float(i), c.y + 30.0)
			var lit := i < thorn_charge
			if lit and i == thorn_charge - 1:
				var th := Palette.THORN
				th.a = 0.25 + 0.2 * sin(pulse * 2.4)
				draw_circle(tp, 11.0, th)
			UiKit.gilded_pip(self, tp, 6.5, lit, Palette.THORN)
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(c.x + 40.0, h - 8.0),
			"SNAP ×%d  ·  reflect %d%%" % [thorn_charge, int(round(thorns_pct * 100.0))],
			HORIZONTAL_ALIGNMENT_CENTER, 280.0, UiKit.SIZE["CAPTION"],
			Palette.THORN.lightened(0.2) if thorn_charge > 0 else Palette.TEXT_DIM)