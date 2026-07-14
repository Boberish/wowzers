## VfxPlayer — ONE pooled flipbook voice: a base color Sprite2D + up to two BOUNDED
## additive layers (duplicate + glint) flipping regions on the family's packed atlas.
## GL Compatibility/WebGL2-safe by construction: Sprite2D + CanvasItemMaterial ADD —
## no shader, no particles, no backbuffer. Painted frames carry the trails; this node
## adds modulation, additive intensity, scale, rotation and timing only.
##
## HIGH-FLOW LAW: play() on a live voice REPLACES the playback instantly (no queue,
## no blend) — the pool routes same-slot effects here so a new committed action
## scrubs an obsolete recovery. stop() ends a loop with a short fade, never a pop.
## Idle voices are hidden with _process disabled — idle cost ≈ zero.
class_name VfxPlayer
extends Node2D

const ADD_A := 0.55           ## additive duplicate strength at full intensity
const GLINT_A := 0.38         ## glint layer strength (PERFECT-only treatment)
const GLINT_SCALE := 1.12     ## glint rides slightly larger, brightening edges
const FADE_S := 0.12          ## loop stop-fade (reuses the live frame — no new art)

var slot := ""                ## the pool's replace key ("" = free)
var family := ""
var _book: VfxBook = null
var _base: Sprite2D
var _add: Sprite2D
var _glint: Sprite2D
var _i := 0                   ## current frame
var _t := 0.0                 ## time into current frame, s
var _ms := 30.0               ## per-frame ms after speed scaling
var _n := 0
var _loop := false
var _fade := -1.0             ## >=0: fading out (loop stop)
var _layers := 0              ## 0 = base only · 1 = +additive · 2 = +glint

## the shared additive material — one instance for every voice (bounded, cheap)
static var _add_mat: CanvasItemMaterial = null

func _init() -> void:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_base = Sprite2D.new()
	_base.centered = false
	_base.region_enabled = true
	add_child(_base)
	_add = Sprite2D.new()
	_add.centered = false
	_add.region_enabled = true
	_add.material = _add_mat
	add_child(_add)
	_glint = Sprite2D.new()
	_glint.centered = false
	_glint.region_enabled = true
	_glint.material = _add_mat
	add_child(_glint)
	visible = false
	set_process(false)

func busy() -> bool:
	return slot != ""

## Start (or REPLACE — the interrupt path) a playback on this voice.
## opts: scale (1.0) · layers (0..2) · tint (WHITE) · speed (1.0) · rot (0.0) · flip_h
func play(book: VfxBook, fam_id: String, opts: Dictionary = {}) -> void:
	_book = book
	family = fam_id
	_n = book.frame_count(fam_id)
	_ms = book.ms_per_frame(fam_id) / maxf(0.05, float(opts.get("speed", 1.0)))
	_loop = book.loops(fam_id)
	_layers = clampi(int(opts.get("layers", 0)), 0, 2)
	_i = 0
	_t = 0.0
	_fade = -1.0
	var tint: Color = opts.get("tint", Color.WHITE)
	modulate = Color(tint.r, tint.g, tint.b, 1.0)
	rotation = float(opts.get("rot", 0.0))
	var sc := book.base_scale(fam_id) * float(opts.get("scale", 1.0))
	scale = Vector2(-sc if bool(opts.get("flip_h", false)) else sc, sc)
	var t: Texture2D = book.tex[fam_id]
	_base.texture = t
	_add.texture = t
	_glint.texture = t
	_add.visible = _layers >= 1
	_add.modulate = Color(1, 1, 1, ADD_A)
	_glint.visible = _layers >= 2
	_glint.modulate = Color(1, 1, 1, GLINT_A)
	_show_frame(0)
	visible = true
	set_process(true)

## End a LOOP (or any playback) cleanly: short fade on the current frame, then free.
func stop() -> void:
	if not busy():
		return
	if _fade < 0.0:
		_fade = FADE_S

## Hard release — teardown/steal path: no fade, instantly reusable.
func release() -> void:
	slot = ""
	family = ""
	_fade = -1.0
	visible = false
	set_process(false)

func _show_frame(i: int) -> void:
	_i = i
	var f := _book.frame(family, i)
	if f.is_empty():
		release()
		return
	var region: Rect2 = f["region"]
	var off: Vector2 = f["offset"]
	_base.region_rect = region
	_base.offset = off
	if _layers >= 1:
		_add.region_rect = region
		_add.offset = off
	if _layers >= 2:
		_glint.region_rect = region
		# center-preserving: the scaled glint shares the base layer's visual center
		_glint.offset = (off + region.size * 0.5) / GLINT_SCALE - region.size * 0.5
		_glint.scale = Vector2.ONE * GLINT_SCALE

func _process(delta: float) -> void:
	# the tick is factored out so the probe can drive a voice headless, no frames needed
	tick(delta)

func tick(delta: float) -> void:
	if not busy():
		return
	if _fade >= 0.0:
		_fade -= delta
		modulate.a = maxf(0.0, _fade / FADE_S)
		if _fade <= 0.0:
			release()
		return
	_t += delta
	while _t >= _ms / 1000.0:
		_t -= _ms / 1000.0
		var nxt := _i + 1
		if nxt >= _n:
			if _loop:
				nxt = 0
			else:
				release()
				return
		_show_frame(nxt)
