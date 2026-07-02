## The FIGHT-END BEAT — the second the fight is decided, before the end screen.
## A win detonates: white flash, expanding gold shock rings, an ember burst, and
## SLAIN slams in over the boss in Cinzel Decorative. A loss closes in: crimson
## vignette, inward rings, YOU FALL dropping like a verdict. ~1.25s, then the HUD
## proceeds to the end screen (via the wrapper's timer). Non-blocking overlay,
## self-freeing, view-only.
##
## Usage (the HUD's encounter_ended wrapper):
##     KillMoment.play(_ui, won, _ctrl.state.encounter.name)
class_name KillMoment
extends Control

const LIFE := 1.3

var _won := true
var _title := ""
var _boss := ""
var _t := 0.0
var _embers: Array = []       # win only: {pos, vel, size, spin}

static func play(host: Control, won: bool, boss_name: String) -> void:
	var m := KillMoment.new()
	m._won = won
	m._boss = boss_name.to_upper()
	m._title = "SLAIN" if won else "YOU FALL"
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(m)

func _ready() -> void:
	if _won:
		# a deterministic-enough ember fan (cosmetic rng is fine view-side)
		for i in 26:
			var a := TAU * float(i) / 26.0 + randf() * 0.2
			_embers.append({"dir": Vector2(cos(a), sin(a)),
				"spd": 180.0 + randf() * 260.0, "r": 2.0 + randf() * 3.0})

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var c := size * Vector2(0.5, 0.42)
	var enter := clampf(_t / 0.22, 0.0, 1.0)
	var leave := clampf((LIFE - _t) / 0.30, 0.0, 1.0)
	var a := minf(enter * 1.4, 1.0) * leave

	if _won:
		# the opening flash
		var flash := clampf(1.0 - _t / 0.16, 0.0, 1.0)
		if flash > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.95, 0.8, 0.5 * flash))
		# gold shock rings racing outward
		for k in 3:
			var rt := clampf((_t - 0.05 * float(k)) / 0.8, 0.0, 1.0)
			if rt <= 0.0 or rt >= 1.0:
				continue
			var rr := 40.0 + rt * size.x * 0.45
			var rc := Palette.GOLD_BRIGHT
			rc.a = (1.0 - rt) * 0.55
			draw_arc(c, rr, 0.0, TAU, 64, rc, 3.0 - rt * 2.0, true)
		# embers
		for e in _embers:
			var p: Vector2 = c + e["dir"] * (float(e["spd"]) * minf(_t, 0.9))
			var g := 90.0 * _t * _t
			p.y += g
			var ec := Palette.GOLD.lerp(Palette.CRIMSON, 0.25)
			ec.a = leave * 0.8
			draw_circle(p, float(e["r"]) * (1.0 - _t * 0.5), ec)
		# dark band + the stamp
		draw_rect(Rect2(0.0, c.y - 58.0, size.x, 116.0), Color(0, 0, 0, 0.5 * a))
	else:
		# the world closes in
		var vin := Color(Palette.CRIMSON_DEEP.r, Palette.CRIMSON_DEEP.g, Palette.CRIMSON_DEEP.b, 0.5 * a)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45 * a))
		for k in 2:
			var rt := clampf((_t - 0.1 * float(k)) / 0.9, 0.0, 1.0)
			if rt <= 0.0 or rt >= 1.0:
				continue
			var rr := size.x * 0.55 * (1.0 - rt) + 60.0
			vin.a = rt * 0.4 * leave
			draw_arc(c, rr, 0.0, TAU, 64, vin, 4.0, true)
		draw_rect(Rect2(0.0, c.y - 58.0, size.x, 116.0), Color(0.06, 0.01, 0.01, 0.55 * a))

	# the stamp itself: slams in (win: scale settle · loss: falls a few px)
	var slam := 1.0 - (1.0 - enter) * (1.0 - enter)
	var dy := 0.0 if _won else (1.0 - slam) * -26.0
	var col := (Palette.GOLD_BRIGHT if _won else Palette.CRIMSON)
	col.a = a
	var fsz := int(round(float(UiKit.SIZE["HERO"]) * (1.25 - 0.25 * slam)))
	UiKit.text_shadowed(self, UiKit.title(900), Vector2(0.0, c.y + 18.0 + dy), _title,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, fsz, col)
	var sub := _boss if _won else "the Rift keeps score"
	var sc := Palette.TEXT_DIM
	sc.a = 0.85 * a * slam
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0.0, c.y + 46.0), sub,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], sc)
