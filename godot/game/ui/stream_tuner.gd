## StreamTuner — THE STREAM TUNER (TANK-PLAN §0 tunability law). A dev-only overlay (F9 on
## the tank band, debug builds) that live-tunes the ACTIVE body's texture profile mid-fight:
## sliders write straight into the encounter's melee dict, the publisher picks the new values
## up on its next committed bar (in-flight bars never change — LAW 1 holds even while tuning),
## and PRINT dumps the tuned dict to the console for paste-back into the body's definition.
##
## ⚠ OFFLINE ONLY by construction: it mutates the local encounter resource — never use it in
## a lockstep session (the band only spawns it in debug builds; online carries no tank band
## dev keys). Not part of any sim/checksum path.
class_name StreamTuner
extends PanelContainer

var ctrl                                ## the HUD's combat controller (untyped scene glue)
var _rows: Array = []                   ## [{key, slider, label, mult}]

const KNOBS := [
	["every", "cadence (s)", 0.4, 3.0, 1.0],
	["jig", "jig ±", 0.0, 0.6, 1.0],
	["heavy_odds", "heavy %", 0.0, 0.6, 100.0],
	["crush_odds", "buster %", 0.0, 0.3, 100.0],
	["feint_odds", "feint %", 0.0, 0.5, 100.0],
	["eat_odds", "eat %", 0.0, 0.4, 100.0],
	["flurry_odds", "flurry %", 0.0, 0.3, 100.0],
	["late_odds", "late %", 0.0, 0.6, 100.0],
	["min", "dmg min", 4.0, 80.0, 1.0],
	["max", "dmg max", 6.0, 110.0, 1.0],
]

func _ready() -> void:
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "THE STREAM TUNER (dev · F9)"
	title.add_theme_font_size_override("font_size", 12)
	v.add_child(title)
	var melee := _melee()
	for k in KNOBS:
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.custom_minimum_size = Vector2(120, 0)
		lab.add_theme_font_size_override("font_size", 11)
		row.add_child(lab)
		var sl := HSlider.new()
		sl.min_value = float(k[2])
		sl.max_value = float(k[3])
		sl.step = (float(k[3]) - float(k[2])) / 60.0
		sl.custom_minimum_size = Vector2(150, 0)
		sl.value = float(melee.get(String(k[0]), 0.0))
		row.add_child(sl)
		v.add_child(row)
		var entry := {"key": String(k[0]), "slider": sl, "label": lab, "name": String(k[1]), "mult": float(k[4])}
		_rows.append(entry)
		sl.value_changed.connect(_on_knob.bind(entry))
		_relabel(entry)
	var btn := Button.new()
	btn.text = "PRINT PROFILE → console"
	btn.pressed.connect(_print_profile)
	v.add_child(btn)

func _melee() -> Dictionary:
	if ctrl == null or ctrl.state == null:
		return {}
	var s: CombatState = ctrl.state
	if s.boss.add_i >= 0:
		return (s.encounter.adds[s.boss.add_i] as AddRes).melee
	return s.encounter.melee

func _on_knob(value: float, entry: Dictionary) -> void:
	var melee := _melee()
	if melee.is_empty():
		return
	melee[entry["key"]] = value
	_relabel(entry)

func _relabel(entry: Dictionary) -> void:
	var v := float((entry["slider"] as HSlider).value) * float(entry["mult"])
	(entry["label"] as Label).text = "%s  %.2f" % [entry["name"], v]

func _print_profile() -> void:
	var melee := _melee()
	var parts: Array = []
	for key in melee:
		var val = melee[key]
		parts.append("\"%s\": %s" % [key, ("%.2f" % val) if val is float else str(val)])
	print("STREAM PROFILE → {", ", ".join(parts), "}")
