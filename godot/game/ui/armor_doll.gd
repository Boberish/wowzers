## ARMORY — "YOUR SET": the run-armor paper doll. A PRESENTATION layer only —
## boons stay boons (Draft 2.0 stacking untouched); each drafted boon renders as a
## PIECE forged into one of five armor slots (ArmorSlots.slot_of), and the two curio
## equip slots render as TRINKET sockets. A slot's frame glows with its family's
## best rarity and shows its piece count; hover lists the pieces. Feed it with
## set_build() whenever the run's boons/curios change.
class_name ArmorDoll
extends Control

const W := 236.0
const H := 332.0

## socket centers on the doll (helm crown / weapon hand / cuirass heart /
## gauntlet hand / greaves feet / trinkets on the belt row)
const SPOTS := {
	"helm": Vector2(118, 46),
	"weapon": Vector2(40, 138),
	"cuirass": Vector2(118, 140),
	"gauntlets": Vector2(196, 138),
	"greaves": Vector2(118, 226),
}
const TRINKET_SPOTS := [Vector2(72, 296), Vector2(164, 296)]
const R_ARMOR := 27.0
const R_TRINKET := 21.0

var _sockets := {}          ## slot -> _Socket
var _trinkets: Array = []   ## [_Socket, _Socket]

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the sockets catch hover (tooltips)
	for slot in ArmorSlots.ORDER:
		var sk := _Socket.new()
		sk.kind = slot
		sk.radius = R_ARMOR
		_place_socket(sk, SPOTS[slot], R_ARMOR)
		_sockets[slot] = sk
	for i in 2:
		var tk := _Socket.new()
		tk.kind = "trinket"
		tk.radius = R_TRINKET
		_place_socket(tk, TRINKET_SPOTS[i], R_TRINKET)
		_trinkets.append(tk)

func _place_socket(sk: _Socket, at: Vector2, r: float) -> void:
	sk.position = at - Vector2(r + 6, r + 6)
	sk.custom_minimum_size = Vector2((r + 6) * 2, (r + 6) * 2)
	sk.size = sk.custom_minimum_size
	sk.mouse_filter = Control.MOUSE_FILTER_STOP     # hover tooltips
	add_child(sk)

## The one feed: the run's drafted boons + equipped curio ids (+ active charges).
func set_build(taken_boons: Array, gear_ids: Array, gear_charges: Dictionary = {}) -> void:
	var sum := ArmorSlots.summarize(taken_boons)
	for slot in ArmorSlots.ORDER:
		var e: Dictionary = sum[slot]
		var sk: _Socket = _sockets[slot]
		sk.count = int(e["count"])
		sk.best = String(e["best"])
		if sk.count == 0:
			sk.tooltip_text = "%s — empty (the draft forges pieces here)" % ArmorSlots.pretty(slot)
		else:
			sk.tooltip_text = "%s — %d piece%s\n%s" % [ArmorSlots.pretty(slot), sk.count,
				"" if sk.count == 1 else "s", "\n".join(PackedStringArray(e["titles"]))]
		sk.queue_redraw()
	for i in 2:
		var tk: _Socket = _trinkets[i]
		if i < gear_ids.size():
			var id := String(gear_ids[i])
			var it := GearCatalog.item(id)
			tk.count = 1
			tk.best = String(it.get("rarity", "haiku"))
			var line := "TRINKET — %s" % String(it.get("name", id))
			if gear_charges.has(id):
				line += "  ×%d" % int(gear_charges[id])
			tk.tooltip_text = line + "\n" + String(it.get("desc", ""))
		else:
			tk.count = 0
			tk.best = ""
			tk.tooltip_text = "TRINKET — empty (boss drops socket here)"
		tk.queue_redraw()
	queue_redraw()

## Faint body silhouette behind the sockets, so the sockets read as a FIGURE.
func _draw() -> void:
	UiKit.engraved_plaque(self, Vector2(W * 0.5, 10), "YOUR SET", true)
	var sil := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.20)
	var cx := W * 0.5
	draw_arc(Vector2(cx, 46), 16.0, 0.0, TAU, 24, sil, 1.5, true)               # head
	draw_line(Vector2(cx, 66), Vector2(cx, 196), sil, 1.5, true)                # spine
	draw_line(Vector2(cx - 52, 106), Vector2(cx + 52, 106), sil, 1.5, true)     # shoulders
	draw_line(Vector2(cx - 52, 106), Vector2(SPOTS["weapon"].x, 128), sil, 1.5, true)
	draw_line(Vector2(cx + 52, 106), Vector2(SPOTS["gauntlets"].x, 128), sil, 1.5, true)
	draw_line(Vector2(cx, 196), Vector2(cx - 26, 250), sil, 1.5, true)          # legs
	draw_line(Vector2(cx, 196), Vector2(cx + 26, 250), sil, 1.5, true)
	draw_line(Vector2(46, 296), Vector2(W - 46, 296), Color(sil, 0.6), 1.0, true)   # belt row

## One armor/trinket socket: dark well + rarity ring + engraved glyph + count.
class _Socket:
	extends Control
	var kind := "helm"
	var radius := 27.0
	var count := 0
	var best := ""

	func _draw() -> void:
		var c := size * 0.5
		var lit := count > 0
		var rar := Palette.rarity_color(best) if lit else Palette.EDGE
		# recessed well + rarity glow
		draw_circle(c, radius, Color(Palette.BG1.r, Palette.BG1.g, Palette.BG1.b, 0.92))
		if lit:
			draw_circle(c, radius + 4.0, Color(rar.r, rar.g, rar.b, 0.10))
		draw_arc(c, radius, 0.0, TAU, 40, rar if lit else Color(rar, 0.8),
			2.2 if lit else 1.2, true)
		if lit:
			UiKit.gilded_ring(self, c, radius + 2.5, 1.6, 36)
		# glyph: engraved dark metal, warmed by the rarity when lit
		var metal := Color(0.34, 0.33, 0.38) if lit else Color(0.20, 0.20, 0.24)
		var edge := metal.lerp(rar, 0.45) if lit else metal.lightened(0.15)
		_glyph(c, radius * 0.62, metal.lerp(rar, 0.25) if lit else metal, edge)
		# piece count badge, bottom-right of the well
		if count > 0 and kind != "trinket":
			var bc := c + Vector2(radius * 0.78, radius * 0.78)
			draw_circle(bc, 8.5, Palette.BG0)
			draw_arc(bc, 8.5, 0.0, TAU, 20, rar, 1.2, true)
			UiKit.text_shadowed(self, UiKit.body(700), bc + Vector2(-8, 4), "+%d" % count,
				HORIZONTAL_ALIGNMENT_CENTER, 16, 10, Palette.TEXT)
		# slot name under the well
		var nm := ArmorSlots.pretty(kind) if kind != "trinket" else "TRINKET"
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(c.x - 40, c.y + radius + 13),
			nm, HORIZONTAL_ALIGNMENT_CENTER, 80, 8,
			Palette.GOLD if lit else Palette.TEXT_DIM)

	func _glyph(c: Vector2, s: float, fill: Color, edge: Color) -> void:
		match kind:
			"helm":
				# dome + visor slit + crest
				var pts := PackedVector2Array()
				for i in 13:
					var a := PI + PI * float(i) / 12.0
					pts.append(c + Vector2(cos(a), sin(a)) * s + Vector2(0, s * 0.1))
				pts.append(c + Vector2(s, s * 0.55))
				pts.append(c + Vector2(-s, s * 0.55))
				draw_colored_polygon(pts, fill)
				draw_polyline(pts, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.7, s * 0.18), c + Vector2(s * 0.7, s * 0.18),
					Palette.BG0, 2.5, true)
				draw_line(c + Vector2(0, -s * 1.05), c + Vector2(0, -s * 0.55), edge, 2.0, true)
			"weapon":
				# sword: blade up, crossguard, grip
				var tip := c + Vector2(0, -s * 1.05)
				draw_colored_polygon(PackedVector2Array([
					tip, c + Vector2(s * 0.18, -s * 0.1), c + Vector2(s * 0.18, s * 0.35),
					c + Vector2(-s * 0.18, s * 0.35), c + Vector2(-s * 0.18, -s * 0.1)]), fill)
				draw_line(tip, c + Vector2(0, s * 0.35), Palette.BG0, 1.2, true)   # fuller
				draw_line(c + Vector2(-s * 0.55, s * 0.35), c + Vector2(s * 0.55, s * 0.35),
					edge, 3.0, true)
				draw_line(c + Vector2(0, s * 0.35), c + Vector2(0, s * 0.95), edge, 2.6, true)
				draw_circle(c + Vector2(0, s * 1.0), 2.6, edge)
			"cuirass":
				# breastplate: shouldered torso + center ridge
				var p := PackedVector2Array([
					c + Vector2(-s * 0.95, -s * 0.75), c + Vector2(-s * 0.35, -s * 0.95),
					c + Vector2(s * 0.35, -s * 0.95), c + Vector2(s * 0.95, -s * 0.75),
					c + Vector2(s * 0.7, s * 0.35), c + Vector2(0, s * 0.95),
					c + Vector2(-s * 0.7, s * 0.35)])
				draw_colored_polygon(p, fill)
				draw_polyline(p, edge, 1.2, true)
				draw_line(c + Vector2(0, -s * 0.9), c + Vector2(0, s * 0.9), Palette.BG0, 2.0, true)
				draw_arc(c + Vector2(0, -s * 0.15), s * 0.5, PI * 0.15, PI * 0.85, 12,
					Palette.BG0, 1.4, true)
			"gauntlets":
				# gauntlet: cuff + fist with knuckle grooves
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-s * 0.85, -s * 0.9), c + Vector2(s * 0.45, -s * 0.9),
					c + Vector2(s * 0.45, -s * 0.4), c + Vector2(-s * 0.85, -s * 0.4)]), fill)
				draw_circle(c + Vector2(-s * 0.1, s * 0.25), s * 0.62, fill)
				draw_arc(c + Vector2(-s * 0.1, s * 0.25), s * 0.62, 0.0, TAU, 26, edge, 1.2, true)
				for k in 3:
					var kx := -s * 0.45 + float(k) * s * 0.36
					draw_line(c + Vector2(kx, -s * 0.05), c + Vector2(kx, s * 0.5),
						Palette.BG0, 1.6, true)
				draw_line(c + Vector2(-s * 0.85, -s * 0.4), c + Vector2(s * 0.45, -s * 0.4),
					edge, 1.4, true)
			"greaves":
				# boot: shin + foot
				var b := PackedVector2Array([
					c + Vector2(-s * 0.4, -s * 0.95), c + Vector2(s * 0.25, -s * 0.95),
					c + Vector2(s * 0.25, s * 0.35), c + Vector2(s * 0.95, s * 0.7),
					c + Vector2(s * 0.95, s * 0.95), c + Vector2(-s * 0.4, s * 0.95)])
				draw_colored_polygon(b, fill)
				draw_polyline(b, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.4, s * 0.0), c + Vector2(s * 0.25, s * 0.0),
					Palette.BG0, 1.6, true)
				draw_line(c + Vector2(-s * 0.4, -s * 0.5), c + Vector2(s * 0.25, -s * 0.5),
					Palette.BG0, 1.6, true)
			_:
				# trinket: amulet gem on a loop
				draw_arc(c + Vector2(0, -s * 0.55), s * 0.35, 0.0, TAU, 20, edge, 1.6, true)
				var gem := PackedVector2Array([
					c + Vector2(0, -s * 0.25), c + Vector2(s * 0.55, s * 0.15),
					c + Vector2(0, s * 0.75), c + Vector2(-s * 0.55, s * 0.15)])
				draw_colored_polygon(gem, fill)
				draw_polyline(gem, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.2, 0), c + Vector2(s * 0.1, s * 0.3),
					Color(1, 1, 1, 0.25), 1.2, true)
