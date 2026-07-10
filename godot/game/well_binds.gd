## Well click-cast mouse bindings — a chord ("left", "shift+right", ...) -> book id.
## The healers share the click-cast surface (hover a frame + chord); this is the Well's
## default layout. Persisted to user:// so a player's layout survives across sessions.
class_name WellBinds
extends RefCounted

## The mouse chords a raid frame can emit (see RaidFrame._gui_input / _mouse_chord).
const CHORDS := ["left", "right", "middle", "shift+left", "shift+right", "ctrl+left", "ctrl+right"]
const DEFAULTS := {
	"left": "flash", "right": "mend", "middle": "cascade",
	"shift+left": "spring", "shift+right": "dispel",
	"ctrl+left": "rekindle", "ctrl+right": "skin",
}
const SPELL_OPTIONS := ["none", "flash", "mend", "skin", "cascade", "spring", "dispel", "rekindle"]

## Disk moved to the Profile aggregate (REFIT P4 save unification — the old
## user://well_binds.json is legacy, imported once). Chord validation stays HERE.
static func load_binds() -> Dictionary:
	var b: Dictionary = DEFAULTS.duplicate(true)
	var stored := Profile.current().binds("well")
	for k in stored:
		if k in CHORDS:
			b[k] = String(stored[k])
	return b

static func save_binds(binds: Dictionary) -> void:
	Profile.current().set_binds("well", binds)
