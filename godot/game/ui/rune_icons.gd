## RuneIcons — maps ability ids to their hand-authored SVG rune glyphs
## (game/ui/icons/*.svg). The glyphs are white-on-transparent line art, so ONE
## grey source tints to any accent/aspect via a draw_texture_rect modulate — no
## per-state art needed. Lazy-loaded + cached; missing icons return null (the rune
## then falls back to its text label, so nothing breaks).
class_name RuneIcons
extends RefCounted

const _DIR := "res://game/ui/icons/"

# Every ability id -> its glyph filename (all under _DIR). "kick" is shared by the
# Twinfang interrupt AND the Voidcaller core-press; "guard"/"dodge" are defensive verbs.
const _NAMES := [
	# Bulwark (tank)
	"cleave", "rampage", "fortify", "vindicate", "avalanche", "bloodthirst", "shockwave", "guard",
	# shared interrupt
	"kick",
	# healer spell icons (shared ids — the Well's book reuses them)
	"flash", "mend", "renew", "ward", "cascade", "well", "dispel", "medit", "surge", "laststand",
	# Twinfang (melee dps)
	"strike", "eviscerate", "envenom", "coupdegrace", "rupture", "flurry", "dodge",
	# legacy caster icons (kept: shared ability/rune ids)
	"bolt", "fracture", "barrier", "overload", "quietus", "silence", "counterspell",
	# Bloomweaver (healer #2)
	"growth", "bark", "overgrowth", "lash", "saprot", "lifesurge", "wildbloom", "briarheart",
]

static var _cache: Dictionary = {}

static func tex(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var t: Texture2D = null
	if id in _NAMES:
		var p := _DIR + id + ".svg"
		if ResourceLoader.exists(p):
			var r: Resource = load(p)
			if r is Texture2D:
				t = r
	_cache[id] = t
	return t

# --- boss sigils (icons/bosses/*.svg) — heavier ritual marks, rasterised at 512px
# for the stage centrepiece. Keyed by NORMALISED display name: "The Hollow Choir"
# -> "hollowchoir", "The Choir-Priest" -> "choirpriest". Missing name -> null (the
# dial then draws no glyph, nothing breaks).
const _BOSS_DIR := "res://game/ui/icons/bosses/"
const _BOSSES := ["gatekeeper", "warcaller", "colossus", "duelist", "devourer",
	"rendmaw", "rotweaver", "hollowchoir", "choirpriest", "twincantors",
	"warden", "executioner", "ashmaul", "swarmheart", "hollowking"]

static var _boss_cache: Dictionary = {}

static func boss_tex(display_name: String) -> Texture2D:
	var key := display_name.to_lower().trim_prefix("the ").replace(" ", "").replace("-", "")
	if _boss_cache.has(key):
		return _boss_cache[key]
	var t: Texture2D = null
	if key in _BOSSES:
		var p := _BOSS_DIR + key + ".svg"
		if ResourceLoader.exists(p):
			var r: Resource = load(p)
			if r is Texture2D:
				t = r
	_boss_cache[key] = t
	return t
