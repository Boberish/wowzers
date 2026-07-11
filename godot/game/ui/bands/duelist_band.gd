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
var engarde_rune: AbilityRune

func build() -> void:
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.STEEL, "FLOW / AGGRO", true)   # the aggro driver, shown as %
	gauge = DuelistGauge.new()
	UiKit.place(gauge, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	hud._shake_root.add_child(gauge)
	# §3½ THE ONE BAR: the tank answers EVERYTHING on the one Judgment Channel —
	# re-seat it bottom-center (where the tank's eyes live), wider. Globals and the
	# rhythm stream take turns on it; smalls read DODGE, bigs PARRY, fakes DON'T.
	if hud._judge != null:
		UiKit.place(hud._judge, 0.5, 1, 0.5, 1, -320, -388, 320, -284)
	var row: HBoxContainer = hud._rune_row(-380.0, 380.0)
	# DODGE (secondary, SPACE) — the bread
	dodge_rune = AbilityRune.new()
	dodge_rune.label = "Dodge"
	dodge_rune.key_num = 1
	dodge_rune.icon_id = "dodge"
	dodge_rune.accent = Palette.FLOW
	dodge_rune.tooltip_text = "DODGE (secondary) — 1 / SPACE / LEFT CLICK. Small/normal bars, any rating; leaks more the bigger the bar. Cheap WIND, fast recovery."
	dodge_rune.pressed.connect(func(): hud._ctrl.human({"type": "dodge"}))
	row.add_child(dodge_rune)
	# PARRY (main, F) — the commit + the hit-back
	parry_rune = AbilityRune.new()
	parry_rune.label = "Parry"
	parry_rune.key_num = 2
	parry_rune.icon_id = "guard"
	parry_rune.accent = Palette.STEEL
	parry_rune.tooltip_text = "PARRY (main) — 2 / RIGHT CLICK. Answers ANY size incl. tall; a PERFECT parry HITS BACK (counter + banks ◆). Costs WIND, slow recovery."
	parry_rune.pressed.connect(func(): hud._ctrl.human({"type": "defense"}))
	row.add_child(parry_rune)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	# ⚡ DUMP (1) — spend the ◆ bank
	dump_rune = AbilityRune.new()
	dump_rune.label = "Dump"
	dump_rune.key_num = 3
	dump_rune.icon_id = "avalanche"
	dump_rune.accent = Palette.GOLD_BRIGHT
	dump_rune.tooltip_text = "⚡ DUMP — spend the ◆ bank for a burst of pure damage."
	dump_rune.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "dump"}))
	row.add_child(dump_rune)
	# ⏱ EN GARDE (the signature CD, S6) — the challenge: invite + wall + double flow
	engarde_rune = AbilityRune.new()
	engarde_rune.label = "En Garde"
	engarde_rune.key_num = 4
	engarde_rune.icon_id = "shockwave"
	engarde_rune.accent = Palette.CRIMSON
	engarde_rune.tooltip_text = "⏱ EN GARDE (~1-min CD) — plant your feet and CALL IT OUT: +25% melee tempo, leaks HALVED, clean answers pay DOUBLE flow, a perfect MAIN banks ◆◆. Two slips break it early. An amplifier — pays nothing if you don't answer."
	engarde_rune.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "engarde"}))
	row.add_child(engarde_rune)
	hud._hint_line("1 / SPACE / LMB — DODGE    ·    2 / RMB — PARRY (perfect = counter + ◆)    ·    3 — ⚡ DUMP    ·    4 — ⏱ EN GARDE")

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
	# EN GARDE cd rune (glows while live)
	engarde_rune.usable = bool(obs.get("engarde_ready", false))
	engarde_rune.affordable = not bool(obs.get("engarde_live", false))
	var eg := int(p.cooldowns.get("engarde", 0))
	engarde_rune.cd_frac = clampf(float(eg - _s.tick) / float(CombatCore.to_ticks(60.0, _s.config.fixed_hz)), 0.0, 1.0)
	# THE DANCER: the parry button is gone — grey the parry rune (SPACE does it all)
	parry_rune.usable = not bool(obs.get("no_parry", false))

func key_pressed(code: int) -> void:
	match code:
		KEY_1, KEY_SPACE:
			hud._ctrl.human({"type": "dodge"})     # DODGE (secondary)
		KEY_2, KEY_F:
			hud._ctrl.human({"type": "defense"})   # PARRY (main; F = legacy alias)
		KEY_3:
			hud._ctrl.human({"type": "ability", "id": "dump"})
		KEY_4:
			hud._ctrl.human({"type": "ability", "id": "engarde"})

## Mouse grammar (Bill, 2026-07-11): LEFT CLICK = DODGE · RIGHT CLICK = PARRY.
## Clicks that land on real buttons (pause / the runes / dev) keep their click —
## the hovered-control check stops the double-fire.
func mouse(event: InputEventMouseButton) -> void:
	if not event.pressed or event.button_index > MOUSE_BUTTON_RIGHT:
		return
	var hov: Control = hud.get_viewport().gui_get_hovered_control()
	if hov is BaseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		hud._ctrl.human({"type": "dodge"})
	else:
		hud._ctrl.human({"type": "defense"})
