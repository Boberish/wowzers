## Bloomweaver click-cast mouse bindings — a chord ("left", "shift+right", ...) ->
## spell id. Persisted to user:// so a player's layout survives across sessions.
class_name BloomweaverBinds
extends RefCounted

const PATH := "user://bloomweaver_binds.json"

const CHORDS := ["left", "right", "middle", "shift+left", "shift+right", "ctrl+left", "ctrl+right"]
const CHORD_NAMES := {
	"left": "Left Click", "right": "Right Click", "middle": "Middle Click",
	"shift+left": "Shift + Left", "shift+right": "Shift + Right",
	"ctrl+left": "Ctrl + Left", "ctrl+right": "Ctrl + Right",
}
const CHORD_SHORT := {
	"left": "L", "right": "R", "middle": "Mid",
	"shift+left": "Sh+L", "shift+right": "Sh+R", "ctrl+left": "Ct+L", "ctrl+right": "Ct+R",
}
## Left = Growth (double-click a Growth'd frame = BLOOM — the core gesture).
const DEFAULTS := {
	"left": "growth", "right": "bark",
	"middle": "saprot",
	"shift+left": "overgrowth", "shift+right": "signature",
	"ctrl+left": "lifesurge", "ctrl+right": "lash",
}
## Spells assignable to a chord ("none" = unbound; "signature" = the Aspect's spender).
const SPELL_OPTIONS := ["none", "growth", "bark", "overgrowth", "lash", "saprot", "lifesurge", "signature"]

static func load_binds() -> Dictionary:
	var b: Dictionary = DEFAULTS.duplicate(true)
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var data = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Dictionary:
				for k in data:
					if k in CHORDS:
						b[k] = String(data[k])
	return b

static func save_binds(binds: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(binds))
		f.close()
