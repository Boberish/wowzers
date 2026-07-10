## DuelistBand — THE DUELIST's HUD band (dodge tank, DUELIST-BRIEF S4). HP + the FLOW / AGGRO
## meter (on the resource orb — tank ONLY; non-tanks never get a flow bar), the WIND bubble + ◆
## COMBO pips (DuelistGauge), and the answer runes: DODGE (SPACE, secondary) · PARRY (F, main —
## a perfect parry hits back + banks ◆) · ⚡ DUMP (1, spend the bank). The incoming bar-stream is
## the HUD's shared telegraph rail; the peel/aggro box is the built party victim-frames + the
## reworded aggro banner. Pure view.
class_name DuelistBand
extends ClassBand

var gauge: DuelistGauge
var parry_rune: AbilityRune
var dodge_rune: AbilityRune
var dump_rune: AbilityRune

func build() -> void:
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.STEEL, "FLOW / AGGRO", true)   # the aggro driver, shown as %
	gauge = DuelistGauge.new()
	UiKit.place(gauge, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	hud._shake_root.add_child(gauge)
	var row: HBoxContainer = hud._rune_row(-380.0, 380.0)
	# DODGE (secondary, SPACE) — the bread
	dodge_rune = AbilityRune.new()
	dodge_rune.label = "Dodge"
	dodge_rune.key_label = "SPC"
	dodge_rune.icon_id = "dodge"
	dodge_rune.accent = Palette.FLOW
	dodge_rune.tooltip_text = "DODGE (secondary) — small/normal bars, any rating; leaks more the bigger the bar. Cheap WIND, fast recovery."
	dodge_rune.pressed.connect(func(): hud._ctrl.human({"type": "dodge"}))
	row.add_child(dodge_rune)
	# PARRY (main, F) — the commit + the hit-back
	parry_rune = AbilityRune.new()
	parry_rune.label = "Parry"
	parry_rune.key_label = "F"
	parry_rune.icon_id = "guard"
	parry_rune.accent = Palette.STEEL
	parry_rune.tooltip_text = "PARRY (main) — answers ANY size incl. tall; a PERFECT parry HITS BACK (counter + banks ◆). Costs WIND, slow recovery."
	parry_rune.pressed.connect(func(): hud._ctrl.human({"type": "defense"}))
	row.add_child(parry_rune)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	# ⚡ DUMP (1) — spend the ◆ bank
	dump_rune = AbilityRune.new()
	dump_rune.label = "Dump"
	dump_rune.key_num = 1
	dump_rune.icon_id = "avalanche"
	dump_rune.accent = Palette.GOLD_BRIGHT
	dump_rune.tooltip_text = "⚡ DUMP — spend the ◆ bank for a burst of pure damage."
	dump_rune.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "dump"}))
	row.add_child(dump_rune)
	hud._hint_line("SPACE — DODGE    ·    F — PARRY (perfect = counter + ◆)    ·    1 — ⚡ DUMP")

func render(_s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(float(obs.get("flow", 0.0)) * 100.0, 100.0)   # FLOW as an aggro %
	gauge.wind = float(obs.get("wind", 10.0))
	gauge.wind_max = float(obs.get("wind_max", 10.0))
	gauge.combo = int(obs.get("combo", 0))
	gauge.combo_max = int(obs.get("combo_max", 5))
	gauge.fumbling = bool(obs.get("fumbling", false))
	gauge.queue_redraw()
	dump_rune.affordable = int(obs.get("combo", 0)) > 0
	dump_rune.usable = bool(obs.get("gcd_ready", true))

func key_pressed(code: int) -> void:
	match code:
		KEY_SPACE:
			hud._ctrl.human({"type": "dodge"})     # DODGE (secondary)
		KEY_F:
			hud._ctrl.human({"type": "defense"})   # PARRY (main)
		KEY_1:
			hud._ctrl.human({"type": "ability", "id": "dump"})
