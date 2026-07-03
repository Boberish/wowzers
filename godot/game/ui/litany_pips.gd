## LitanyPips — the Mender's combo read: a row of 5 gilded pips that light as the LITANY
## chain climbs, with the aspect's FILL RULE engraved beneath (Tidecaller "TOP AHEAD" vs
## Brinkwarden "CATCH LOW" — the two builds fill the same meter from opposite play). The
## 5th pip is the Benediction bloom: the whole row flares gold, then resets. Pure view.
class_name LitanyPips
extends Control

var pips: int = 0
var pip_max: int = 5
var accent: Color = Palette.STEEL      ## aspect tint (tide = teal-steel, brink = crimson)
var rule: String = "TOP AHEAD"         ## the aspect fill condition, engraved under the row
var _pulse: float = 0.0
var _flare: float = 0.0                ## Benediction cash flash
var _last: int = 0

func bloom() -> void:                  ## called by the HUD on a Benediction event
	_flare = 1.0

func _process(delta: float) -> void:
	_pulse += delta * 3.4
	_flare = maxf(0.0, _flare - delta * 1.8)
	if pips < _last and _last >= pip_max - 1:   # rolled over from full → the cash flare
		_flare = 1.0
	_last = pips
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var full := pips >= pip_max
	UiKit.engraved_plaque(self, Vector2(w * 0.5, 9.0), "LITANY", full or _flare > 0.0)
	# the pip row
	var r := 7.0
	var gap := 22.0
	var total := gap * float(pip_max - 1)
	var x0 := w * 0.5 - total * 0.5
	var y := 30.0
	for i in pip_max:
		var at := Vector2(x0 + gap * float(i), y)
		var lit := i < pips
		if _flare > 0.0:                          # Benediction bloom: the whole row flares
			var halo := Palette.GOLD_BRIGHT
			halo.a = 0.5 * _flare
			draw_circle(at, r * 2.2, halo)
		elif lit and i == pips - 1:               # the newest pip breathes
			var h := accent
			h.a = 0.25 + 0.2 * (0.5 + 0.5 * sin(_pulse * 2.2))
			draw_circle(at, r * 1.9, h)
		UiKit.gilded_pip(self, at, r, lit, accent.lerp(Palette.GOLD_BRIGHT, _flare))
	# the aspect fill rule, engraved beneath
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(0, y + 14.0), rule,
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["MICRO"],
		accent.lightened(0.2) if pips > 0 else Palette.TEXT_DIM)
