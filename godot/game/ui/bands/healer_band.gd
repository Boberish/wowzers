## The healers' shared band base: click-cast chords (hover a raid frame + a bound
## mouse chord casts on it) and the shared CastChannel. Well and Bloomweaver extend
## this with their own instruments; the chord table (binds) is per-class.
class_name HealerBand
extends ClassBand

var binds: Dictionary = {}         ## mouse chord -> spell id (per-class defaults)
var castbar: CastChannel

## Healer click-cast (all healer classes): hover a frame, click a chord.
func mouse(event: InputEventMouseButton) -> void:
	if event.pressed and hud._hover_seat != null:
		var id := String(binds.get(hud._mouse_chord(event), "none"))
		if id == "signature":
			id = hud._signature()
		if id != "none" and hud._hspells().has(id):
			hud._focus_seat = hud._hover_seat
			hud._cast_on(hud._hover_seat, id)

## The shared cast channel's per-frame feed (spell names come from the class book).
func render_castbar(s: CombatState, casting: Dictionary, book: Dictionary) -> void:
	if castbar == null:
		return
	if casting.is_empty():
		castbar.active = false
		return
	castbar.active = true
	castbar.frac = clampf(float(s.tick - int(casting.get("start_tick", 0)))
		/ maxf(float(casting.get("dur_ticks", 1)), 1.0), 0.0, 1.0)
	var ct: Seat = casting.get("target")
	castbar.target = ct.unit_name if ct != null else ""
	castbar.spell_id = String(casting.get("id", ""))
	castbar.label = String(book.get(castbar.spell_id, {}).get("name", castbar.spell_id))
