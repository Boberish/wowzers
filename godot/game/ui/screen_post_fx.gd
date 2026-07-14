## ScreenPostFx — THE one full-screen back-buffer pass (wires the formerly dormant
## screen_post.gdshader): radial shockwave, RGB aberration, colour wash, low-HP
## vignette. The HUD fires flash()/shock()/aberr() from its event handler — each takes
## an optional delay so a hit can land on the STAGE's impact frame instead of the
## press — and feeds set_vignette() per frame. All decay lives here; the node hides
## itself whenever every uniform is at rest (the shader is identity then, and reading
## the screen forces a back-buffer copy, so hidden = idle frames pay nothing).
## Pure view layer — never checksummed.
##
## THE ANSWER-READ SHIELD (C7): set_protect() marks the AnswerChannel's screen rect;
## the shader attenuates wash/aberration/shock INSIDE it so a full-screen celebration
## can never smear the timing gate, nail, or the next incoming shape (GRAPHICS-PLAN
## §2.4 / I4 law). protect defaults OFF ⇒ the shader is byte-identical to its old
## dormant self.
class_name ScreenPostFx
extends ColorRect

const SHOCK_DUR := 0.45           # one ring sweep across the screen
const PROTECT_AMT := 0.85         # how much of the wash the channel rect refuses

var _flash_col := Color.WHITE
var _flash_amt := 0.0
var _aberr := 0.0
var _shock_t := -1.0              # 0..1 while sweeping; <0 = off
var _shock_amt := 0.0
var _shock_center := Vector2(0.5, 0.5)
var _vign := 0.0
var _vign_target := 0.0
var _protect := Rect2()           # AnswerChannel rect in screen UV; zero = off
var _delayed: Array = []          # {t, kind, ...} scheduled calls

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://game/ui/screen_post.gdshader")
	material = mat
	visible = false

## A screen-wide colour wash (gold parry / crimson hit / green deny / mint coup).
func flash(col: Color, amt: float, delay := 0.0) -> void:
	if delay > 0.0:
		_delayed.append({"t": delay, "kind": "flash", "col": col, "amt": amt})
		return
	if amt >= _flash_amt:
		_flash_col = col
		_flash_amt = amt

## An expanding shockwave ring from `center` (screen fraction, e.g. the boss chest).
func shock(center: Vector2, amt := 1.0, delay := 0.0) -> void:
	if delay > 0.0:
		_delayed.append({"t": delay, "kind": "shock", "center": center, "amt": amt})
		return
	_shock_center = center
	_shock_amt = maxf(_shock_amt, amt)
	_shock_t = 0.0

## An RGB-split pulse (big impacts only — it reads as damage, spend it rarely).
func aberr(amt: float, delay := 0.0) -> void:
	if delay > 0.0:
		_delayed.append({"t": delay, "kind": "aberr", "amt": amt})
		return
	_aberr = maxf(_aberr, amt)

## Continuous low-HP crimson vignette (0..1); the HUD feeds this every frame.
func set_vignette(v: float) -> void:
	_vign_target = clampf(v, 0.0, 1.0)

## The AnswerChannel's live rect in SCREEN UV — washes attenuate inside it. The HUD
## feeds this per frame (the widget moves between legacy and dash layouts).
func set_protect(uv_rect: Rect2) -> void:
	_protect = uv_rect

func _process(delta: float) -> void:
	var keep: Array = []
	for job in _delayed:
		job["t"] = float(job["t"]) - delta
		if float(job["t"]) > 0.0:
			keep.append(job)
			continue
		match String(job["kind"]):
			"flash": flash(job["col"], float(job["amt"]))
			"shock": shock(job["center"], float(job["amt"]))
			"aberr": aberr(float(job["amt"]))
	_delayed = keep

	_flash_amt = maxf(0.0, _flash_amt - delta * 3.2)
	_aberr = maxf(0.0, _aberr - delta * 2.6)
	if _shock_t >= 0.0:
		_shock_t += delta / SHOCK_DUR
		if _shock_t >= 1.0:
			_shock_t = -1.0
			_shock_amt = 0.0
	# fast in, eased out — the vignette breathes rather than flickers
	_vign = lerpf(_vign, _vign_target, minf(delta * 6.0, 1.0))

	var active := _flash_amt > 0.004 or _aberr > 0.004 or _shock_t >= 0.0 or _vign > 0.01
	visible = active
	if not active:
		return
	var m := material as ShaderMaterial
	m.set_shader_parameter("flash_color", _flash_col)
	m.set_shader_parameter("flash_amt", _flash_amt)
	m.set_shader_parameter("aberration", _aberr)
	m.set_shader_parameter("shock_center", _shock_center)
	m.set_shader_parameter("shock_t", _shock_t)
	m.set_shader_parameter("shock_amt", _shock_amt)
	m.set_shader_parameter("vignette", _vign)
	m.set_shader_parameter("protect_rect", Vector4(_protect.position.x, _protect.position.y,
		_protect.end.x, _protect.end.y))
	m.set_shader_parameter("protect_amt", PROTECT_AMT if _protect.size.x > 0.0 else 0.0)
