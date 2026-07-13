## BossCastBar — the boss's SPELL instrument (Bill 2026-07-11). The declutter: the
## dodge channel is now footwork ONLY (dodge/parry/fake/string); everything the boss
## CASTS — self-heal · self-empower · an interruptible verse · an unavoidable nova —
## reads here instead, a classic horizontal cast bar under the boss's HP. Shared by
## every seat (raid awareness): the tank reads "brace / burn it", the caster reads its
## kick window, the healer reads the DPS-check. Pure view: fed each frame by the HUD;
## resolve flashes ride the combat event stream. Hidden (α→0) whenever nothing casts.
class_name BossCastBar
extends Control

var active: bool = false
var boss_name: String = "":
	set(v):
		if v != boss_name:
			boss_name = v
			_glyph = RuneIcons.boss_tex(v)
var cast_name: String = ""
var kind: String = "brace"     ## heal | empower | kick | brace
var frac: float = 0.0          ## elapsed / dur (the fill)
var remaining: float = 0.0
var window: float = 0.0        ## kick clean window (seconds; 0 = none)
var in_zone: bool = false      ## a kick would land now
var kickable_seat: bool = false ## this seat can actually kick (else "uncontested")

var _glyph: Texture2D
# ART V2 / C6B (set ONLY by the dash host; default off ⇒ legacy byte-identical):
# the I3-B resource shell replaces the flat glass plate. It rides this control's
# own modulate, so the painted shell fades in/out WITH the cast — no dead chrome
# between casts. Fill, kick window, names, countdown, cue: all still code-drawn.
var v2_skin: DashSkin = null
var _pulse := 0.0
var _alpha := 0.0
var _flash := 0.0              ## resolve burst decay
var _flash_col := Color.WHITE
var _flash_txt := ""

func _process(delta: float) -> void:
	_pulse += delta * 6.0
	_flash = maxf(0.0, _flash - delta * 2.4)
	var want := 1.0 if (active or _flash > 0.0) else 0.0
	_alpha = lerpf(_alpha, want, minf(1.0, delta * 10.0))
	modulate.a = _alpha
	visible = _alpha > 0.01
	queue_redraw()

## Combat events the bar cares about (forwarded by the HUD's drain).
func on_event(ev: Dictionary) -> void:
	match String(ev.get("t", "")):
		"staggered", "interrupt":
			if bool(ev.get("was_heal", false)):
				_pop("DENIED!", Palette.WIN)
			else:
				_pop("KICKED!" if not bool(ev.get("clean", false)) else "CLEAN KICK!", Palette.KICK)
		"empower_land":
			_pop("IT GREW", Palette.CRIMSON)

func _pop(txt: String, col: Color) -> void:
	_flash = 1.0; _flash_txt = txt; _flash_col = col

func _accent() -> Color:
	match kind:
		"heal": return Palette.WIN
		"kick": return Palette.KICK
		_: return Palette.CRIMSON      # empower + brace

func _cue() -> Array:                  # [text, color]
	match kind:
		"heal": return ["BURN IT DOWN", Palette.WIN]
		"empower": return ["IT GROWS — BURN / INTERRUPT", Palette.CRIMSON]
		"kick":
			if not kickable_seat:
				return ["uncontested — no kicker", Palette.TEXT_DIM]
			return [">> INTERRUPT <<" if in_zone else "ready to interrupt", \
				Palette.GOLD_BRIGHT if in_zone else Palette.KICK]
		_: return ["BRACE — unavoidable", Palette.CRIMSON]

func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	var acc := _accent()

	# glass plate + gilded frame (C6B: the painted resource shell, fading with us)
	var cx := 40.0
	var cw := w - cx - 12.0
	var cy := 6.0
	var ch := h - 26.0
	if v2_skin != null:
		var srect := Rect2(0.0, 0.0, w, ch + 12.0)
		v2_skin.hshell(self, "shell_resource", srect, DashSkin.CAPS_RESOURCE)
		var op := v2_skin.sliced_opening("shell_resource", srect, DashSkin.CAPS_RESOURCE, DashSkin.OPEN_RESOURCE)
		cx = op.position.x + 26.0            # the medallion keeps the channel's west end
		cw = op.end.x - cx
		cy = op.position.y
		ch = op.size.y
	else:
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color(0.030, 0.026, 0.052, 0.66)
		plate.set_corner_radius_all(8)
		plate.border_color = Color(acc.r, acc.g, acc.b, 0.55)
		plate.set_border_width_all(1)
		draw_style_box(plate, Rect2(0, 0, w, h))

	# boss glyph medallion (left)
	var med := Vector2(20.0, (cy + ch * 0.5) if v2_skin != null else h * 0.5)
	draw_circle(med, 13.0, Color(0, 0, 0, 0.5))
	if _glyph != null:
		var gr := 11.0
		draw_texture_rect(_glyph, Rect2(med - Vector2(gr, gr), Vector2(gr, gr) * 2.0),
			false, Color(acc.r, acc.g, acc.b, 0.9))
	UiKit.gilded_ring(self, med, 13.0, 1.5, 20)

	# the fill channel
	draw_rect(Rect2(cx, cy, cw, ch), Color(0.024, 0.020, 0.043))
	# fill left->right (the cast progressing toward resolution)
	var fc := acc
	fc.a = 0.55 + 0.12 * sin(_pulse * 2.0)
	draw_rect(Rect2(cx, cy, cw * clampf(frac, 0.0, 1.0), ch), fc)
	# kick window: a bright band at the END of the channel
	if kind == "kick" and window > 0.0 and remaining > 0.0:
		var dur := remaining / maxf(0.001, 1.0 - frac)
		var zf := clampf(window / maxf(dur, 0.001), 0.0, 1.0)
		var zc := Palette.GOLD_BRIGHT if in_zone else Palette.KICK
		zc.a = 0.32
		draw_rect(Rect2(cx + cw * (1.0 - zf), cy, cw * zf, ch), zc)
	# resolution hairline at the right end
	draw_line(Vector2(cx + cw, cy - 3.0), Vector2(cx + cw, cy + ch + 3.0),
		Palette.GOLD if not in_zone else Palette.GOLD_BRIGHT, 2.0, true)

	# name (left, in-channel) + countdown (right)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(cx + 8.0, cy + ch * 0.5 + 4.0),
		cast_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, cw - 70.0, UiKit.SIZE["CAPTION"], Palette.TEXT)
	if remaining > 0.02:
		var cnt := ("%.1f" % remaining) if remaining >= 1.0 else ("%.2f" % remaining)
		UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(cx, cy + ch * 0.5 + 4.0),
			cnt, HORIZONTAL_ALIGNMENT_RIGHT, cw - 6.0, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)

	# the response cue, under the channel
	var cue := _cue()
	var ctxt: String = cue[0]
	var ccol: Color = cue[1]
	if _flash > 0.0:
		ctxt = _flash_txt
		ccol = _flash_col
		ccol.a = 0.5 + 0.5 * _flash
	UiKit.text_shadowed(self, font, Vector2(cx, h - 15.0), ctxt,
		HORIZONTAL_ALIGNMENT_CENTER, cw, UiKit.SIZE["LABEL"], ccol)
