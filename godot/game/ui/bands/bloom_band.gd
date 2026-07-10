## The Bloomweaver's band: Sap orb + Blooming Medallion (Verdance) + benediction cast
## channel + the Growth/ward rune rail. No mana, no Reservoir/Nerve strip — the whole
## class is planted AHEAD and bloomed on the spike (click-cast the frames, same grammar).
class_name BloomBand
extends HealerBand

var verd: VerdanceGauge

func build() -> void:
	binds = BloomweaverBinds.load_binds()
	hp_orb = hud._orb(Palette.SAP.darkened(0.2), "SAP", false)   # Sap — Bloomweaver has no mana
	verd = VerdanceGauge.new()
	verd.aspect = hud._aspect
	verd.verdance_max = hud._bcfg.verdance_max
	verd.min_spend = hud._bcfg.verd_min_spend
	UiKit.place(verd, 0.5, 1, 0.5, 1, -300, -298, 300, -168)
	hud._shake_root.add_child(verd)
	castbar = CastChannel.new()
	castbar.accent = Palette.VERDANCE
	UiKit.place(castbar, 0.5, 1, 0.5, 1, -240, -358, 240, -298)
	hud._shake_root.add_child(castbar)
	var row: HBoxContainer = hud._rune_row(-320.0, 320.0)
	runes = []
	rune_ids = []
	for id in hud._loadout:
		var sp: Dictionary = hud._bcfg.spells.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		if sp.has("spec"):
			rune.accent = Palette.VERDANCE if hud._aspect == "wildgrove" else Palette.THORN
		rune.custom_minimum_size = Vector2(62, 62)
		rune.pressed.connect(hud._cast.bind(String(id)))
		row.add_child(rune)
		runes.append(rune)
		rune_ids.append(id)
	hud._hint_line(_hint())

func _hint() -> String:
	var chords: Array = BloomweaverBinds.CHORDS
	var shorts: Dictionary = BloomweaverBinds.CHORD_SHORT
	var parts: Array = []
	for chord in chords:
		var id := String(binds.get(chord, "none"))
		if id != "none":
			parts.append("%s=%s" % [shorts.get(chord, chord), id.capitalize()])
	return "Hover a frame + click:  " + "  ·  ".join(parts) + "    ·    SPACE/F — dodge beats"

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.resource, hud._bcfg.sap_max)
	verd.verdance = float(obs.get("verdance", 0.0))
	verd.flourish = bool(obs.get("flourish", false))
	verd.flourish_hi = bool(obs.get("flourish_hi", false))
	verd.garden = int(obs.get("garden", 0))
	verd.total_seeds = int(obs.get("total_seeds", 0))
	verd.flourish_lo = int(hud._bcfg.flourish_seeds_lo)
	verd.thorns = int(float(p.vars.get("stat_thorns", 0.0)))
	verd.thorn_charge = int(obs.get("thorn_charge", 0))
	verd.thorn_charge_max = int(obs.get("thorn_charge_max", 5))
	verd.thorns_pct = float(obs.get("thorns_pct", 0.45))
	render_castbar(s, obs.get("casting", {}), hud._bcfg.spells)
	var gcd_ticks := float(CombatCore.to_ticks(hud._bcfg.gcd, s.config.fixed_hz))
	for i in runes.size():
		var id: String = rune_ids[i]
		var sp: Dictionary = hud._bcfg.spells[id]
		var offgcd := bool(sp.get("offgcd", false))
		var afford: bool = p.resource >= float(sp.get("sap", 0.0))
		if sp.has("spec"):
			afford = afford and float(obs.get("verdance", 0.0)) >= hud._bcfg.verd_min_spend
		var cd_until := int(p.cooldowns.get(id, 0))
		var gcd_block: bool = (not offgcd) and s.tick < p.gcd_until_tick
		var cd_block: bool = s.tick < cd_until
		runes[i].affordable = afford
		runes[i].usable = not gcd_block and not cd_block
		if cd_block:
			runes[i].cd_frac = clampf(float(cd_until - s.tick) / maxf(1.0, float(CombatCore.to_ticks(float(sp.get("cd", 1.0)), s.config.fixed_hz))), 0.0, 1.0)
		elif gcd_block:
			runes[i].cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)
		else:
			runes[i].cd_frac = 0.0

func key_pressed(code: int) -> void:
	match code:
		KEY_SPACE, KEY_F:
			hud._ctrl.human({"type": "dodge"})
		KEY_1: hud._cast("growth")
		KEY_2: hud._cast("bark")
		KEY_3: hud._cast("overgrowth")
		KEY_4: hud._cast("bloom")
		KEY_5: hud._cast("lash")
		KEY_Q: hud._cast("saprot")
		KEY_E: hud._cast("lifesurge")
		KEY_7: hud._cast(hud._signature())
