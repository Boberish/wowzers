## The BOSS INTRO CARD — every fight opens with a ceremony: the boss's sigil
## ghosts in behind its name in Cinzel Decorative, gold filigree rules sweep
## outward from the centre, a dark readability band breathes underneath, and the
## whole card burns off before the first telegraph matters (~2.4s). Non-blocking
## (mouse-transparent, gameplay runs beneath), self-freeing, and added to `_ui`
## so a mid-intro screen swap frees it with everything else.
##
## Usage (one line at the end of a HUD's `_build_combat()`):
##     BossIntro.play(_ui, s.encounter.name)
class_name BossIntro
extends Control

const LIFE := 2.4             ## seconds on screen
const IN_T := 0.38            ## entrance ease time

var _title := ""
var _glyph: Texture2D
var _t := 0.0

static func play(host: Control, boss_name: String) -> void:
	var card := BossIntro.new()
	card._title = boss_name.to_upper()
	card._glyph = RuneIcons.boss_tex(boss_name)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(card)

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var enter := clampf(_t / IN_T, 0.0, 1.0)
	enter = 1.0 - (1.0 - enter) * (1.0 - enter)              # ease-out
	var leave := clampf((LIFE - _t) / 0.5, 0.0, 1.0)         # fade at the end
	var a := enter * leave
	if a <= 0.001:
		return
	var cx := size.x * 0.5
	var cy := size.y * 0.36
	# readability band, widest mid-life
	var band := Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.55 * a)
	draw_rect(Rect2(0.0, cy - 64.0, size.x, 128.0), band)
	# the sigil ghosts in behind the name, settling as it fades
	if _glyph != null:
		var gs := 150.0 * (1.12 - 0.12 * enter)
		var gc := Palette.GOLD
		gc.a = 0.20 * a
		draw_texture_rect(_glyph, Rect2(cx - gs * 0.5, cy - gs * 0.5 - 14.0, gs, gs), false, gc)
	# gold rules sweeping outward from centre
	var reach := (size.x * 0.30) * enter
	for s: float in [-1.0, 1.0]:
		var y := cy + 34.0
		var x0 := cx + s * 120.0
		var x1 := cx + s * (120.0 + reach)
		var rc := Palette.GOLD
		rc.a = 0.85 * a
		draw_line(Vector2(x0, y), Vector2(x1, y), rc, 1.6, true)
		var dc := Palette.GOLD_BRIGHT
		dc.a = a
		var pts := PackedVector2Array([Vector2(x1, y - 4.0), Vector2(x1 + s * 7.0, y),
			Vector2(x1, y + 4.0), Vector2(x1 - s * 7.0, y)])
		draw_colored_polygon(pts, dc)
	# the name itself — long Seal titles step down a size
	var fsz: int = UiKit.SIZE["DISPLAY"] if _title.length() <= 22 else UiKit.SIZE["HEADER"] + 6
	var tc := Palette.GOLD_BRIGHT
	tc.a = a
	UiKit.text_shadowed(self, UiKit.title(800), Vector2(0.0, cy + 12.0), _title,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, fsz, tc)
	var sc := Palette.TEXT_DIM
	sc.a = 0.8 * a
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0.0, cy + 56.0), "— let the judgment begin —",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], sc)
