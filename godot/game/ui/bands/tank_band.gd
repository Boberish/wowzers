## The tank's band (Bulwark until the Duelist wave): HP + RAGE orbs, the SpecGauge
## (Counter / Momentum), the defense rune, CHALLENGE (taunt), and the ability rail.
## Also the martial fallback band — its key map is the old `_martial_key`.
class_name TankBand
extends ClassBand

var spec: SpecGauge
var challenge: AbilityRune

func build() -> void:
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.RAGE, "RAGE", true)
	spec = SpecGauge.new()
	spec.aspect = hud._aspect
	UiKit.place(spec, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	hud._shake_root.add_child(spec)
	var row: HBoxContainer = hud._rune_row(-380.0, 380.0)
	build_guard(row, String(hud._verb()).capitalize(), "guard", Palette.STEEL,
		"Your defensive verb — own cooldown, off-GCD.")
	challenge = AbilityRune.new()
	challenge.label = "Challenge"
	challenge.key_label = "T"
	challenge.icon_id = "shockwave"
	challenge.accent = Palette.CRIMSON
	challenge.tooltip_text = "Taunt — force the boss onto you and seize top threat. 8s cd, off-GCD."
	challenge.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "challenge"}))
	row.add_child(challenge)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	add_runes(row, hud._loadout)
	hud._hint_line("SPACE — %s    ·    F — DODGE beats    ·    T — CHALLENGE (taunt)" % hud._verb())

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(p.resource, p.resource_max)
	spec.counter = int(obs.get("counter", 0))
	spec.momentum = int(obs.get("momentum", 0))
	spec.momentum_max = int(obs.get("momentum_max", 10))
	spec.riposte = bool(obs.get("riposte_active", false))
	var gcd_ticks := float(CombatCore.to_ticks(1.0, s.config.fixed_hz))
	var rage := float(obs.get("rage", 0.0))
	for i in runes.size():
		var afford := true
		match rune_ids[i]:
			"rampage": afford = rage >= 40.0
			"fortify": afford = rage >= 30.0
			"vindicate": afford = int(obs.get("counter", 0)) >= 1
			"avalanche": afford = rage >= 20.0 and int(obs.get("momentum", 0)) >= 1
		runes[i].affordable = afford
		runes[i].usable = bool(obs.get("gcd_ready", false))
		runes[i].cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)
	render_guard(s, p, obs, 2.2)
	if challenge != null:
		var ch := int(p.cooldowns.get("challenge", 0))
		challenge.usable = s.tick >= ch
		challenge.cd_frac = clampf(float(ch - s.tick) / float(CombatCore.to_ticks(8.0, s.config.fixed_hz)), 0.0, 1.0)

func key_pressed(code: int) -> void:
	match code:
		KEY_SPACE:
			hud._ctrl.human({"type": "defense"})
		KEY_F:
			hud._ctrl.human({"type": "dodge"})
		KEY_T:
			if hud._seat_key == "tank":
				hud._ctrl.human({"type": "ability", "id": "challenge"})
		KEY_1: press_rune(0)
		KEY_2: press_rune(1)
		KEY_3: press_rune(2)
		KEY_4: press_rune(3)
		KEY_5: press_rune(4)
