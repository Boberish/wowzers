## Well click-cast mouse bindings — a chord ("left", "shift+right", ...) -> book id.
## The healers share the click-cast surface (hover a frame + chord); this is the Well's
## default layout. Persisted to user:// so a player's layout survives across sessions.
class_name WellBinds
extends RefCounted

const PATH := "user://well_binds.json"

## The mouse chords a raid frame can emit (see RaidFrame._gui_input / _mouse_chord).
const CHORDS := ["left", "right", "middle", "shift+left", "shift+right", "ctrl+left", "ctrl+right"]
const DEFAULTS := {
	"left": "flash", "right": "mend", "middle": "cascade",
	"shift+left": "spring", "shift+right": "dispel",
	"ctrl+left": "rekindle",
}
const SPELL_OPTIONS := ["none", "flash", "mend", "cascade", "spring", "dispel", "rekindle"]

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
