## The Alchemist's band: HP + POTENCY orbs and THE ALEMBIC — the brew instrument
## (hold-zones + vial + reaction chamber + potency strip). The brew itself is the
## whole bar: HOLD 1/2 (or the reservoirs) to charge, release to pour, 3 (or tap
## the chamber) to Rupture. No standard rune rail — the instrument IS the kit;
## the module's active button + drafted spells get their own runes.
class_name BrewBand
extends ClassBand

var brew_gauge: BrewGauge
var brew_hold_key: int = -1        ## which key (1/2) owns the live brew hold

func build() -> void:
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.REACT, "POTENCY", true)
	brew_gauge = BrewGauge.new()
	# THE ALEMBIC: 780×316, shifted into the player's column (the Forge idiom) so the
	# boss's Judgment Channel + telegraph rail under the reticle stay clear of it.
	UiKit.place(brew_gauge, 0.5, 1, 0.5, 1, -550, -486, 230, -170)
	hud._shake_root.add_child(brew_gauge)
	brew_gauge.brew_pressed.connect(func(side: String):
		hud._ctrl.human({"type": "ability", "id": "brew_" + side}))
	brew_gauge.brew_released.connect(func():
		hud._ctrl.human({"type": "ability", "id": "pour"}))
	brew_gauge.rupture_tapped.connect(func():
		hud._ctrl.human({"type": "ability", "id": "rupture"}))
	var row: HBoxContainer = hud._rune_row(-360.0, 360.0)
	build_guard(row, "DODGE", "dodge", Palette.REACT,
		"Dodge the swing aimed at YOU — the brew keeps cooking through your footwork.")
	runes = []
	rune_ids = []
	# The module's active button + any drafted spells get their own runes (only when owned —
	# read from the campaign run, which _inject_boons folds into this fight's kit).
	var extras := "3 — RUPTURE"
	if hud._d.run != null and hud._d.run.modules.has("third_reagent"):
		row.add_child(_rune("catalyst", "CATALYST", "4", "flash", Palette.GOLD_BRIGHT,
			"Drop the Third Reagent — amplify the reaction for a few seconds. Best while potency is high."))
		extras += " · 4 — CATALYST"
	var spell_runes := [
		["spitfire", "SPITFIRE", "5", "bolt", "An instant off-brew acid dart — free filler between pours."],
		["decant", "DECANT", "6", "cascade", "Pour the fuller poison into the emptier — a cd-gated snap toward balance."],
		["reduction", "REDUCTION", "7", "surge", "Boil VOLUME into POWER — trade brew for a slug of Potency before a Rupture."],
	]
	for sp in spell_runes:
		if hud._d.run != null and (String(sp[0]) in hud._d.run.loadout or hud._d.run.boons.has(String(sp[0]))):
			row.add_child(_rune(String(sp[0]), String(sp[1]), String(sp[2]), String(sp[3]),
				Palette.REACT, String(sp[4])))
			extras += " · %s — %s" % [String(sp[2]), String(sp[1])]
	hud._hint_line("HOLD 1 — VENOM · HOLD 2 — ROT (release = POUR) · %s · SPACE — DODGE (swing or beats)" % extras)

## One Alchemist ability rune (catalyst / a drafted spell) wired to send its action.
func _rune(id: String, label: String, key: String, icon: String, accent: Color, tip: String) -> AbilityRune:
	var r := AbilityRune.new()
	r.label = label
	r.key_label = key
	r.icon_id = icon
	r.accent = accent
	r.tooltip_text = tip
	r.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": id}))
	return r

## THE ALEMBIC eats the whole observe() surface — the instrument renders everything.
func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(float(obs.get("potency", 0.0)) * 100.0, 100.0)
	var g := brew_gauge
	g.venom = float(obs.get("venom", 0.0))
	g.rot = float(obs.get("rot", 0.0))
	g.cap = float(obs.get("cap", 12.0))
	g.charging = String(obs.get("charging", ""))
	g.charge = float(obs.get("charge", 0.0))
	g.charge_max = float(obs.get("charge_max", 1.30))
	g.fizzle_below = float(obs.get("fizzle_below", 0.45))
	g.sweet_lo = float(obs.get("sweet_lo", 0.70))
	g.sweet_hi = float(obs.get("sweet_hi", 0.98))
	g.overflow_at = float(obs.get("overflow_at", 1.0))
	g.balance = float(obs.get("balance", 0.0))
	g.potency = float(obs.get("potency", 0.0))
	g.pot_mult = float(obs.get("pot_mult", 1.0))
	g.react_dps = float(obs.get("react_dps", 0.0))
	g.ripe_glow = float(obs.get("ripe_glow", 0.0))
	g.brew_min = float(obs.get("brew_min", 0.0))
	# MODULES (slice B): the equipped one lights a compact gauge on the instrument.
	g.mod_third_reagent = bool(obs.get("mod_third_reagent", false))
	g.mod_fermentation = bool(obs.get("mod_fermentation", false))
	g.mod_reaction_vessel = bool(obs.get("mod_reaction_vessel", false))
	g.mod_reagent = float(obs.get("reagent", 0.0))
	g.mod_reagent_active = bool(obs.get("reagent_active", false))
	g.mod_ferment = float(obs.get("ferment", 0.0))
	g.mod_vessel = float(obs.get("vessel", 0.0))
	render_guard(s, p, obs, 2.4)

## HOLD 1 = brew Venom · HOLD 2 = brew Rot (the RELEASE pours — key_released) ·
## 3/R = Rupture · SPACE = dodge · 4-7 = module button + drafted spells.
func key_pressed(code: int) -> void:
	match code:
		KEY_SPACE:
			hud._ctrl.human({"type": "defense"})   # THE ONE DODGE
		KEY_1:
			if brew_hold_key == -1:
				brew_hold_key = KEY_1
				hud._ctrl.human({"type": "ability", "id": "brew_venom"})
		KEY_2:
			if brew_hold_key == -1:
				brew_hold_key = KEY_2
				hud._ctrl.human({"type": "ability", "id": "brew_rot"})
		KEY_3, KEY_R:
			hud._ctrl.human({"type": "ability", "id": "rupture"})
		KEY_4:
			hud._ctrl.human({"type": "ability", "id": "catalyst"})   # MODULE (Third Reagent): drop it in
		KEY_5:
			hud._ctrl.human({"type": "ability", "id": "spitfire"})   # SPELL (drafted): filler dart
		KEY_6:
			hud._ctrl.human({"type": "ability", "id": "decant"})     # SPELL (drafted): snap-to-balance
		KEY_7:
			hud._ctrl.human({"type": "ability", "id": "reduction"})  # SPELL (drafted): volume→power

## The hold-release verb: releasing the held brew key POURS the vial.
func key_released(event: InputEventKey) -> bool:
	if event.keycode == brew_hold_key:
		brew_hold_key = -1
		hud._ctrl.human({"type": "ability", "id": "pour"})
	return true

func on_event(ev: Dictionary, mine: bool) -> void:
	if brew_gauge != null and mine:
		brew_gauge.on_event(ev)   # THE ALEMBIC: pour verdicts / rupture burst / history
