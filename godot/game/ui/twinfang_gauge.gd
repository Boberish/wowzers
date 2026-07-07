## The Twinfang spec centrepiece — a winged reliquary medallion.
## CORE: the Flow crystal — a gilded ring of six facet-segments that fill cyan as Flow
## climbs (each gain flashes; at max the whole crystal blazes), the Flow numeral in
## display face, and the damage multiplier on an engraved plaque beneath.
## LEFT WING: the five combo gems on an engraved rail — the finisher gem is larger and
## pulses at full combo. RIGHT WING: the aspect readout — Tempo's three tier gems
## chained toward COUP, or the Venomancer's three-poison cocktail + Toxic Synergy ramp.
## Pure view; the HUD feeds the same fields as before.
class_name TwinfangGauge
extends Control

var aspect: String = "tempo"
## Fermata is Flow-based like Tempo — it shows the tier-gem wing, never the poison wheel.
func _flow_wing() -> bool:
	return aspect == "tempo" or aspect == "fermata"
var combo: int = 0
var combo_max: int = 5
var flow: int = 0
var flow_max: int = 6
var flow_mult: float = 1.0
var tier: int = 0
var venom: Dictionary = {"V": 0, "F": 0, "C": 0, "syn_ramp": 1.0, "syn_active": false}
var wheel: int = 0             ## Venom poison wheel: the lit (on-deck) lane a Strike feeds — 0=V 1=F 2=C
var _pulse: float = 0.0
var _flash: float = 0.0        # facet pop on a Flow gain
var _last_flow: int = 0

func _process(delta: float) -> void:
	_pulse += delta * 3.2
	if flow > _last_flow:
		_flash = 1.0
	_last_flow = flow
	_flash = maxf(0.0, _flash - delta * 2.6)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var c := Vector2(w * 0.5, h * 0.5 - 8.0)
	var R := 38.0
	var maxed := flow >= maxi(flow_max, 1)

	# ornamental wings (ignite with the payoff on their side)
	UiKit.wing_flourish(self, c, -1.0, 210.0, Palette.CP, combo >= combo_max)
	UiKit.wing_flourish(self, c, 1.0, 210.0, Palette.PERFECT if _flow_wing() else Palette.POISON,
		(tier >= 3) if _flow_wing() else bool(venom.get("syn_active", false)))

	# ---- the Flow crystal core ----
	if maxed or _flash > 0.0:
		var halo := Palette.FLOW
		halo.a = (0.16 + 0.10 * sin(_pulse * 2.2) if maxed else 0.0) + 0.22 * _flash
		draw_circle(c, R * 1.55, halo)
	draw_circle(c, R * 0.80, Palette.FILL_BOT)
	draw_circle(c - Vector2(0, R * 0.16), R * 0.66, Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.5))
	# six facet-segments around the crystal
	var nfac := maxi(flow_max, 1)
	for i in nfac:
		var a0 := -PI / 2.0 + TAU * float(i) / float(nfac) + 0.07
		var a1 := -PI / 2.0 + TAU * float(i + 1) / float(nfac) - 0.07
		var lit := i < flow
		var seg := Palette.FLOW.lerp(Palette.FLOW.lightened(0.35), float(i) / float(nfac)) if lit \
			else Color(0.07, 0.08, 0.12)
		if lit and maxed:
			seg = seg.lightened(0.15 + 0.15 * sin(_pulse * 2.2 + float(i)))
		if lit and i == flow - 1 and _flash > 0.0:
			seg = seg.lerp(Color(1, 1, 1), _flash * 0.6)
		draw_arc(c, R, a0, a1, 10, seg, 8.0, true)
		if lit:
			draw_arc(c, R + 4.5, a0 + 0.04, a1 - 0.04, 8,
				Color(Palette.FLOW.r, Palette.FLOW.g, Palette.FLOW.b, 0.5), 1.5, true)
	UiKit.gilded_ring(self, c, R + 8.0, 2.5, 48)
	# numeral + label inside the crystal
	UiKit.text_shadowed(self, UiKit.display(750), Vector2(c.x - R, c.y + 9.0), str(flow),
		HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["GAUGE"],
		Palette.FLOW.lightened(0.3) if maxed else Palette.GOLD_BRIGHT)
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(c.x - R, c.y + 23.0), "FLOW",
		HORIZONTAL_ALIGNMENT_CENTER, R * 2.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
	# damage multiplier plaque under the core
	UiKit.engraved_plaque(self, Vector2(c.x, h - 11.0),
		"+%d%% DMG" % int(round((flow_mult - 1.0) * 100.0)), maxed, 11)

	# ---- left wing: combo gems on an engraved rail ----
	var rail_y := c.y
	var gx0 := c.x - 92.0
	var spacing := 38.0
	var rail_x1 := gx0 - spacing * float(combo_max - 1) - 20.0
	draw_line(Vector2(rail_x1, rail_y), Vector2(gx0 + 16.0, rail_y), Palette.BG0, 4.0, true)
	draw_line(Vector2(rail_x1, rail_y + 1.0), Vector2(gx0 + 16.0, rail_y + 1.0),
		Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.2, true)
	var full := combo >= combo_max
	for i in combo_max:
		var gp := Vector2(gx0 - spacing * float(i), rail_y)
		var fin := i == combo_max - 1          # the finisher gem sits at the wing tip
		var r := 13.0 if fin else 10.0
		if fin and full:
			var burst := Palette.CP
			burst.a = 0.25 + 0.18 * sin(_pulse * 2.4)
			draw_circle(gp, r * 1.9, burst)
		_combo_gem(gp, r + (1.5 * sin(_pulse * 2.4) if (fin and full) else 0.0), i < combo)
	UiKit.engraved_plaque(self, Vector2(gx0 - spacing * 2.0, h - 11.0), "COMBO", full)

	# ---- right wing: the aspect readout ----
	if _flow_wing():
		_tempo_wing(c, h)
	else:
		_venom_wing(c, h)

## Tempo: three tier gems chained toward Coup de Grâce, linked by an engraving that
## lights as the chain climbs.
func _tempo_wing(c: Vector2, h: float) -> void:
	var labels := ["2-HIT", "ENERGY", "COUP"]
	var xs := [c.x + 96.0, c.x + 162.0, c.x + 232.0]
	var rs := [8.0, 9.5, 12.0]
	# chain line, lit up to the current tier
	for i in 2:
		var lit := tier >= i + 2
		var lcol := Palette.PERFECT if lit else Palette.GOLD_DIM
		lcol.a = 0.8 if lit else 0.35
		draw_line(Vector2(xs[i] + rs[i] + 4.0, c.y), Vector2(xs[i + 1] - rs[i + 1] - 4.0, c.y), lcol, 1.6, true)
	for i in 3:
		var on := tier >= i + 1
		var gp := Vector2(xs[i], c.y)
		if i == 2 and tier >= 3:
			var burst := Palette.PERFECT
			burst.a = 0.28 + 0.18 * sin(_pulse * 2.4)
			draw_circle(gp, rs[i] * 2.0, burst)
		UiKit.gilded_pip(self, gp, rs[i] + ((1.5 * sin(_pulse * 2.4)) if (i == 2 and tier >= 3) else 0.0),
			on, Palette.PERFECT)
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(gp.x - 34.0, c.y + rs[i] + 16.0), labels[i],
			HORIZONTAL_ALIGNMENT_CENTER, 68.0, UiKit.SIZE["MICRO"],
			Palette.TEXT if on else Palette.TEXT_DIM)
	if tier >= 3:
		UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(c.x + 70.0, h - 7.0), "◆ COUP READY ◆",
			HORIZONTAL_ALIGNMENT_CENTER, 224.0, UiKit.SIZE["CAPTION"],
			Palette.PERFECT.lerp(Palette.GOLD_BRIGHT, 0.5 + 0.5 * sin(_pulse * 2.0)))

## Venomancer: the three-poison cocktail with stack numerals + the Synergy ramp meter.
func _venom_wing(c: Vector2, h: float) -> void:
	var types := [
		["V", int(venom.get("V", 0)), Palette.POISON],
		["F", int(venom.get("F", 0)), Palette.KICK],
		["C", int(venom.get("C", 0)), Palette.GOLD],
	]
	var syn_active: bool = bool(venom.get("syn_active", false))
	var lane_x := func(i: int) -> float: return c.x + 96.0 + float(i) * 66.0
	for i in 3:
		var t = types[i]
		var gp := Vector2(lane_x.call(i), c.y)
		var lit: bool = int(t[1]) > 0
		if lit and syn_active:
			var halo := t[2] as Color
			halo.a = 0.18 + 0.12 * sin(_pulse * 2.2 + float(i))
			draw_circle(gp, 17.0, halo)
		UiKit.gilded_pip(self, gp, 9.5, lit, t[2] as Color)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(gp.x - 24.0, c.y + 26.0),
			"%s %d" % [t[0], int(t[1])], HORIZONTAL_ALIGNMENT_CENTER, 48.0, UiKit.SIZE["CAPTION"],
			Palette.TEXT if lit else Palette.TEXT_DIM)
	# ON-DECK marker: the wheel's lit lane — the poison your NEXT Strike feeds. A pulsing
	# gold ring + chevron, so "ride vs Envenom-fixate" is a glance, not memory.
	var wl := clampi(wheel, 0, 2)
	var wp := Vector2(lane_x.call(wl), c.y)
	var pull := 0.5 + 0.5 * sin(_pulse * 2.4)
	var mk := Palette.GOLD_BRIGHT
	mk.a = 0.55 + 0.35 * pull
	UiKit.gilded_ring(self, wp, 15.0 + 1.5 * pull, 1.6, 22)
	var ct := wp + Vector2(0.0, -21.0 - 3.0 * pull)         # chevron pointing down at the lane
	draw_line(ct + Vector2(-6.0, -5.0), ct, mk, 2.2, true)
	draw_line(ct + Vector2(6.0, -5.0), ct, mk, 2.2, true)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(wp.x - 34.0, c.y - 40.0), "NEXT",
		HORIZONTAL_ALIGNMENT_CENTER, 68.0, UiKit.SIZE["MICRO"], mk)
	# Synergy ramp beneath the cocktail
	var ramp := float(venom.get("syn_ramp", 1.0))
	var bar := Rect2(c.x + 82.0, h - 18.0, 150.0, 9.0)
	UiKit.glass_bar_draw(self, bar, clampf((ramp - 1.0) / 0.8, 0.0, 1.0),
		Palette.POISON.lightened(0.1) if syn_active else Palette.POISON.darkened(0.2))
	if syn_active:
		var g := Palette.POISON
		g.a = 0.30 + 0.20 * sin(_pulse * 2.0)
		draw_rect(Rect2(bar.position - Vector2(2, 2), bar.size + Vector2(4, 4)), g, false, 1.2)
	UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(bar.end.x + 8.0, h - 9.5),
		"x%.1f" % ramp if syn_active else "—",
		HORIZONTAL_ALIGNMENT_LEFT, 60.0, UiKit.SIZE["CAPTION"],
		Palette.POISON.lightened(0.2) if syn_active else Palette.TEXT_DIM)

## an ember-cut combo gem (diamond, gold bezel, specular)
func _combo_gem(gp: Vector2, r: float, on: bool) -> void:
	var pts := PackedVector2Array([
		gp + Vector2(0, -r), gp + Vector2(r * 0.78, 0), gp + Vector2(0, r), gp + Vector2(-r * 0.78, 0)])
	draw_colored_polygon(pts, Palette.CP if on else Color(0.10, 0.11, 0.16))
	if on:
		var inner := PackedVector2Array([gp + Vector2(0, -r * 0.5), gp + Vector2(r * 0.4, 0),
			gp + Vector2(0, r * 0.5), gp + Vector2(-r * 0.4, 0)])
		draw_colored_polygon(inner, Palette.CP.lightened(0.3))
	draw_line(pts[0], pts[1], Palette.GOLD_BRIGHT if on else Palette.GOLD_DIM, 1.5, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.5, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.5, true)
	draw_line(pts[3], pts[0], Palette.GOLD if on else Palette.GOLD_DIM, 1.5, true)
	if on:
		draw_circle(gp - Vector2(r * 0.25, r * 0.35), r * 0.24, Color(1, 1, 1, 0.75))
