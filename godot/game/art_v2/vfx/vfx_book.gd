## VfxBook — the C7 flipbook registry: loads game/art_v2/vfx/manifest.json + the
## per-family atlases ONCE at construction (§3½ renderer law: textures resolve at
## make() time, never inside painters/draw). make() returns null on ANY missing or
## malformed piece — THE FAIL-SAFE LAW: no book ⇒ the stage builds no VfxPool and
## the legacy code-drawn sparks remain the only FX, exactly as today.
## Pure view layer — never checksummed, never read by policies or the engine.
class_name VfxBook
extends RefCounted

const DIR := "res://game/art_v2/vfx"
## the eight approved I4 families (README contract) — all must resolve or make() = null
const FAMILIES := ["parry", "dodge", "dump", "engarde_activate", "engarde_hold",
	"impact_light", "impact_heavy", "impact_crush"]

var tex: Dictionary = {}      ## family -> Texture2D (the packed atlas)
var fam: Dictionary = {}      ## family -> manifest record (frames/pivots/ms/scale/loop)

static func make(dir := DIR) -> VfxBook:
	var mp := dir + "/manifest.json"
	if not FileAccess.file_exists(mp):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(mp))
	if parsed == null or not (parsed is Dictionary):
		return null
	var families: Dictionary = (parsed as Dictionary).get("families", {})
	var b := VfxBook.new()
	for f in FAMILIES:
		var rec: Dictionary = families.get(f, {})
		var frames: Array = rec.get("frames", [])
		if rec.is_empty() or frames.is_empty():
			return null               # a family absent from the manifest — fall back whole
		var tp := "%s/%s.png" % [dir, f]
		if not ResourceLoader.exists(tp, "Texture2D"):
			return null               # a missing atlas — fall back whole (proven in probe)
		var t: Texture2D = load(tp)
		if t == null:
			return null
		b.tex[f] = t
		b.fam[f] = rec
	return b

## Per-frame draw data for the player: atlas region + the offset that puts the
## REGISTERED PIVOT at the node origin (cell-space math recorded by the prep).
func frame(family: String, i: int) -> Dictionary:
	var rec: Dictionary = fam.get(family, {})
	var frames: Array = rec.get("frames", [])
	if frames.is_empty():
		return {}
	var f: Dictionary = frames[clampi(i, 0, frames.size() - 1)]
	var r: Array = f["rect"]
	var trim: Array = f["trim"]
	var pv: Array = f["pivot"]
	return {
		"region": Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])),
		# sprite top-left relative to the pivot: trim offset − pivot (cell coords)
		"offset": Vector2(float(trim[0]) - float(pv[0]), float(trim[1]) - float(pv[1])),
	}

func frame_count(family: String) -> int:
	return (fam.get(family, {}) as Dictionary).get("frames", []).size()

func ms_per_frame(family: String) -> float:
	return float((fam.get(family, {}) as Dictionary).get("ms_per_frame", 30))

func base_scale(family: String) -> float:
	return float((fam.get(family, {}) as Dictionary).get("base_scale", 0.6))

func loops(family: String) -> bool:
	return bool((fam.get(family, {}) as Dictionary).get("loop", false))

func travel_rad(family: String) -> float:
	return deg_to_rad(float((fam.get(family, {}) as Dictionary).get("travel_deg", 0.0)))
