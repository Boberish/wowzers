## ClassBand — one class's combat instrument cluster (REFIT P4: the ClassBand
## registry). The HUD raises ONE band for the human seat and routes build / render /
## input / events to it; each band owns its class's widgets and input state, so
## raid_hud stops carrying a per-class nullable pile and a 4-way match per surface.
##
## Bands are VIEW-layer glue: they build through the HUD's layout helpers
## (hud._orb / hud._rune_row / hud._hint_line) and drive combat ONLY through
## hud._ctrl.human() — the one input surface. Nothing here touches the reducer.
##
## The shared shell every band raises (HP/resource orbs, the ability-rune rail, the
## defense rune) lives HERE; subclasses add their class instruments on top. Adding a
## class = one band file + one arm in for_hud() (the view twin of ClassRegistry —
## kept HERE so the data-layer registry never references UI scripts).
class_name ClassBand
extends RefCounted

var hud                            ## the RaidHud (untyped — it is a scene script)
var hp_orb: LiquidOrb
var res_orb: LiquidOrb
var runes: Array = []              ## AbilityRune per loadout slot (number keys)
var rune_ids: Array = []
var guard: AbilityRune             ## the defense press (SPACE)

## The band for the class the human seat is running right now.
static func for_hud(h) -> ClassBand:
	var b: ClassBand
	match String(h._seat_cls_now()):
		"twinfang": b = BladeBand.new()
		"alchemist": b = BrewBand.new()
		"well": b = WellBand.new()
		"bloomweaver": b = BloomBand.new()
		_: b = TankBand.new()          # bulwark — and the old martial `_:` fallback
	b.hud = h
	return b

# --- the per-class surface (subclasses override) -----------------------------

func build() -> void:
	pass

func render(_s: CombatState, _p: Seat, _obs: Dictionary) -> void:
	pass

## Combat-screen key press (already filtered: pressed, no echo, no pause).
func key_pressed(_code: int) -> void:
	pass

## Key release (hold-release verbs). Return true = this band's release grammar owns
## key-ups (the old per-seat guard blocks returned unconditionally once matched).
func key_released(_event: InputEventKey) -> bool:
	return false

## Mouse events on the combat screen (healer click-cast / hold-release grammars).
func mouse(_event: InputEventMouseButton) -> void:
	pass

## Engine events for gauge juice (verdict banners / burst history). `mine` = the
## human seat's own event.
func on_event(_ev: Dictionary, _mine: bool) -> void:
	pass

# --- the shared shell ---------------------------------------------------------

## The ability-rune rail: one rune per loadout id, number-keyed. Subclasses may
## claim a slot's wiring via _wire_rune (FERMATA's hold-release Strike).
func add_runes(row: HBoxContainer, ids: Array, accent = null) -> void:
	runes = []
	rune_ids = []
	for i in ids.size():
		var id: String = ids[i]
		var rune := AbilityRune.new()
		rune.label = hud.ABILITY_NAMES.get(id, id)
		rune.key_num = i + 1
		rune.icon_id = id
		if accent != null:
			rune.accent = accent
		if not _wire_rune(rune, i, id):
			rune.pressed.connect(press_rune.bind(i))
		row.add_child(rune)
		runes.append(rune)
		rune_ids.append(id)

## A subclass claims a rune's signal wiring by returning true (default: tap = press).
func _wire_rune(_rune: AbilityRune, _i: int, _id: String) -> bool:
	return false

## Fire rail slot i (number keys + rune taps share this).
func press_rune(i: int) -> void:
	if hud._screen == "combat" and i >= 0 and i < rune_ids.size():
		hud._ctrl.human({"type": "ability", "id": rune_ids[i]})

## The standard defense rune (SPACE). Label/icon/tip vary per band.
func build_guard(row: HBoxContainer, label: String, icon: String, accent: Color, tip: String) -> void:
	guard = AbilityRune.new()
	guard.label = label
	guard.key_label = "SPC"
	guard.icon_id = icon
	guard.accent = accent
	guard.tooltip_text = tip
	guard.pressed.connect(func(): hud._ctrl.human({"type": "defense"}))
	row.add_child(guard)

func render_guard(s: CombatState, p: Seat, obs: Dictionary, def_cd_default: float) -> void:
	var dcd := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", def_cd_default)), s.config.fixed_hz)))
	guard.usable = bool(obs.get("defense_ready", false))
	guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd, 0.0, 1.0)
