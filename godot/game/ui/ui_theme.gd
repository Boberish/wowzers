## UiTheme (autoload) — installs the Gilded Reliquary type system game-wide.
## Spectral Medium becomes the fallback font every draw_string/Label/Button inherits,
## so nothing in the game ever renders in the engine's default face. Display faces
## (Cinzel / Cinzel Decorative) are fetched explicitly via UiKit.display()/title().
## Guarded: if the bundled fonts are ever missing, the game still boots on the stock font.
extends Node

func _ready() -> void:
	var body := _load_font("res://game/ui/fonts/spectral/Spectral-Medium.ttf")
	if body != null:
		ThemeDB.fallback_font = body
		ThemeDB.fallback_font_size = 15

func _load_font(p: String) -> Font:
	if ResourceLoader.exists(p):
		var r: Resource = load(p)
		if r is Font:
			return r
	return null
