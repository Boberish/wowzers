## VfxPool — the C7 bounded flipbook stage layer: owns every VfxPlayer voice, routes
## effects by SLOT (the interrupt law) and enforces the overdraw budget. Lives inside
## RaidStage2D's world (so stage hit-stop holds impact frames) and exists ONLY when
## `ArtV2.vfx` is on AND VfxBook.make() resolved — otherwise the stage never builds
## it and the legacy code-drawn sparks remain the whole FX story (fail-safe law).
##
## SLOTS: a keyed effect ("seat3:answer", "seat3:engarde") REPLACES its live
## predecessor instantly — a new committed action scrubs an obsolete recovery; effects
## never queue behind presentation. Un-keyed effects ("" — impacts) take any free
## voice, or STEAL the oldest un-keyed one when the pool is saturated (bounded, never
## grows past MAX_VOICES). Budget: ≤ MAX_VOICES sprites × ≤3 layers, one shared
## additive material — the bounded-overdraw contract from GRAPHICS-PLAN §7.
class_name VfxPool
extends Node2D

const MAX_VOICES := 14

var book: VfxBook = null
var slowmo := 1.0             ## DEV/tour knob: scales every playback (capture on slow GL)
var _voices: Array = []       ## all VfxPlayer children, fixed at MAX_VOICES
var _age := 0                 ## monotonically increasing spawn stamp (steal = oldest)

static func make() -> VfxPool:
	var b := VfxBook.make()
	if b == null:
		return null               # missing/partial assets — no pool, legacy FX only
	var p := VfxPool.new()
	p.book = b
	return p

func _init() -> void:
	for i in MAX_VOICES:
		var v := VfxPlayer.new()
		add_child(v)
		_voices.append(v)

## Fire one effect. slot "" = fire-and-forget (impacts); a named slot replaces its
## own live playback (answers/engarde). Returns the voice (tests introspect it).
func spawn(family: String, pos: Vector2, opts: Dictionary = {}, slot := "") -> VfxPlayer:
	if book == null or book.frame_count(family) == 0:
		return null
	var v := _claim(slot)
	if v == null:
		return null
	if slowmo != 1.0:
		opts = opts.duplicate()
		opts["speed"] = float(opts.get("speed", 1.0)) * slowmo
	v.slot = slot if slot != "" else "~"      # "~" = live un-keyed (steal candidate)
	v.set_meta("age", _age)
	_age += 1
	v.position = pos
	v.play(book, family, opts)
	return v

## Stop a keyed playback cleanly (loop fade) — En Garde end / teardown of one seat.
func stop_slot(slot: String) -> void:
	for v in _voices:
		if (v as VfxPlayer).slot == slot:
			(v as VfxPlayer).stop()

## Instantly silence everything (fight teardown / re-entry).
func clear() -> void:
	for v in _voices:
		(v as VfxPlayer).release()

func live_count() -> int:
	var n := 0
	for v in _voices:
		if (v as VfxPlayer).busy():
			n += 1
	return n

func _claim(slot: String) -> VfxPlayer:
	# 1 · a named slot replaces its own live voice (the interrupt path)
	if slot != "":
		for v in _voices:
			if (v as VfxPlayer).slot == slot:
				return v
	# 2 · any free voice
	for v in _voices:
		if not (v as VfxPlayer).busy():
			return v
	# 3 · saturated: steal the OLDEST un-keyed voice (never a named slot — an
	# En Garde hold can't be stolen by impact spam)
	var best: VfxPlayer = null
	for v in _voices:
		if (v as VfxPlayer).slot == "~" and (best == null
				or int(v.get_meta("age", 0)) < int(best.get_meta("age", 0))):
			best = v
	return best
