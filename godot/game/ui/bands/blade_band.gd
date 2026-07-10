## The blade's band (Twinfang — Tempo AND Fermata): the RhythmBar metronome, THE
## OPENING vulnerability gauge, HP + ENERGY orbs, the TwinfangGauge (combo/flow),
## the one-dodge defense rune, and the ability rail. FERMATA's hold-release Strike
## (coil on press, release to strike) lives here — key 1 and the slot-0 rune.
class_name BladeBand
extends ClassBand

var rhythm: RhythmBar
var opening: OpeningBar
var tf_gauge: TwinfangGauge
var strike_idx: int = -1
var coil_held: bool = false        ## FERMATA: the Strike coil is being held

func build() -> void:
	rhythm = RhythmBar.new()
	# YOUR metronome sits in your own column — the boss's Judgment Channel owns
	# the line under the reticle on the right
	UiKit.place(rhythm, 0.35, 0, 0.35, 0, -360, 646, 360, 746)
	hud._shake_root.add_child(rhythm)
	# THE OPENING — the offense-side vulnerability gauge, stacked above your metronome:
	# read the boss's swing and slam your dumps into the molten sweet spot.
	opening = OpeningBar.new()
	opening.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.place(opening, 0.35, 0, 0.35, 0, -360, 548, 360, 636)
	hud._shake_root.add_child(opening)
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.ENERGY, "ENERGY", true)
	tf_gauge = TwinfangGauge.new()
	tf_gauge.aspect = hud._aspect
	UiKit.place(tf_gauge, 0.5, 1, 0.5, 1, -300, -302, 300, -172)
	hud._shake_root.add_child(tf_gauge)
	var row: HBoxContainer = hud._rune_row(-360.0, 360.0)
	build_guard(row, "DODGE", "dodge", Palette.FLOW,
		"Dodge the swing aimed at YOU — a landed hit wipes your Flow.")
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	add_runes(row, hud._loadout)
	strike_idx = rune_ids.find("strike")
	hud._hint_line("SPACE — DODGE (negate a swing OR answer beats; protects Flow)    ·    hold aggro low — the boss eats loose blades")

## FERMATA: the slot-0 Strike rune is a HOLD (press = coil, release = strike). Every
## other rune, and every other band, stays a tap — mirrors key 1 in key_pressed.
func _wire_rune(rune: AbilityRune, i: int, id: String) -> bool:
	if i == 0 and hud._seat_key == "blade" and hud._aspect == "fermata" and id == "strike":
		rune.held.connect(func():
			if hud._screen == "combat" and not coil_held:
				coil_held = true
				hud._ctrl.human({"type": "ability", "id": "coil"}))
		rune.released.connect(func():
			if hud._screen == "combat" and coil_held:
				coil_held = false
				hud._ctrl.human({"type": "ability", "id": "release"}))
		return true
	return false

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(float(obs.get("energy", 0.0)), float(obs.get("energy_max", 100.0)))
	rhythm.since = int(obs.get("since_strike", 0))
	rhythm.swing_min = int(obs.get("swing_min_ticks", 13))
	rhythm.perfect_lo = int(obs.get("perfect_lo", 18))
	rhythm.perfect_hi = int(obs.get("perfect_hi", 29))
	rhythm.bull_frac = float(obs.get("grade_bull_frac", 0.18))       # GRADED WINDOW (§2c) zones
	rhythm.perfect_frac = float(obs.get("grade_perfect_frac", 0.55))
	rhythm.scale_ticks = int(obs.get("rhythm_scale", 33))   # fixed ruler → accelerando visible
	var _asp := String(obs.get("aspect", ""))
	rhythm.flow = int(obs.get("flow", 0)) if (_asp == "tempo" or _asp == "fermata") else 0
	rhythm.flow_max = int(obs.get("flow_max", 6))
	# FERMATA: feed the coil (hold-release) state so the bar shows the charge ring + coil cues.
	rhythm.fermata = _asp == "fermata"
	rhythm.coiling = bool(obs.get("coiling", false))
	var _cmin := maxi(1, int(obs.get("coil_min_ticks", 11)))
	rhythm.coil_charge = clampf(float(obs.get("coil_ticks", 0)) / float(_cmin), 0.0, 1.0)
	rhythm.coil_sharp = bool(obs.get("coil_sharp", false))
	# FERMATA · THE RAMP & THE SNAP — feed the depth bands + the lip (the cliff) for the ramp draw.
	rhythm.ramp = bool(obs.get("fermata_ramp", false))
	rhythm.ramp_good_frac = float(obs.get("ramp_good_frac", 0.45))
	rhythm.ramp_perfect_frac = float(obs.get("ramp_perfect_frac", 0.37))
	rhythm.lip = int(obs.get("lip_ticks", 0))
	rhythm.dance_no_snap = bool(obs.get("dance_no_snap", false))
	tf_gauge.combo = int(obs.get("cp", 0))
	tf_gauge.combo_max = int(obs.get("cp_max", 5))
	tf_gauge.flow = int(obs.get("flow", 0))
	tf_gauge.flow_max = int(obs.get("flow_max", 6))
	tf_gauge.flow_mult = float(obs.get("flow_mult", 1.0))
	tf_gauge.tier = int(obs.get("tier", 0))
	tf_gauge.venom = obs.get("venom", {"V": 0, "F": 0, "C": 0, "syn_ramp": 1.0, "syn_active": false})
	if opening != null:
		# THE OPENING — the boss's vulnerability window; armed = a dump is ready to punish it
		opening.now_tick = int(obs.get("tick", 0))
		opening.from_tick = int(obs.get("open_from", -1))
		opening.peak_tick = int(obs.get("open_peak", -1))
		opening.to_tick = int(obs.get("open_to", -1))
		opening.core_ticks = int(obs.get("open_core_ticks", 3))
		opening.bonus_now = float(obs.get("open_bonus_now", 0.0))
		opening.active = int(obs.get("open_to", -1)) >= opening.now_tick
		opening.armed = int(obs.get("cp", 0)) >= 1 or bool(obs.get("coup_ready", false)) \
			or bool(obs.get("rupture_ready", false)) or float(obs.get("energy", 0.0)) >= 28.0
	var energy := float(obs.get("energy", 0.0))
	var cpn := int(obs.get("cp", 0))
	var in_green: bool = rhythm.since >= rhythm.perfect_lo and rhythm.since <= rhythm.perfect_hi
	for i in runes.size():
		var id: String = rune_ids[i]
		var afford := true
		var usable := true
		var cd := 0.0
		match id:
			"strike":
				afford = energy >= 12.0
				if hud._aspect == "fermata":
					# THE DRAW: the coil button is live whenever you're not staggered — while
					# holding it's "usable" once sharp (release-ready), idle it's always startable.
					usable = (bool(obs.get("coil_sharp", false)) if bool(obs.get("coiling", false))
						else not bool(obs.get("strike_locked", false)))
				else:
					usable = rhythm.since >= rhythm.swing_min
			"eviscerate", "envenom":
				afford = energy >= 25.0
				usable = cpn >= 1
			"flurry":
				afford = energy >= 28.0
			"kick":
				afford = energy >= 10.0
				cd = hud._cd_frac(p, s, "kick", 7.0)
				usable = cd <= 0.0
			"coupdegrace":
				afford = energy >= 30.0
				cd = hud._cd_frac(p, s, "coupdegrace", 5.0)
				usable = cd <= 0.0 and int(obs.get("flow", 0)) >= int(obs.get("flow_max", 6))
			"rupture":
				afford = energy >= 22.0
				cd = hud._cd_frac(p, s, "rupture", 3.5)
				usable = cd <= 0.0 and int(obs.get("venom_total", 0)) >= 1
		runes[i].affordable = afford
		runes[i].usable = usable
		runes[i].cd_frac = cd
		if i == strike_idx:
			runes[i].accent = Palette.PERFECT if in_green else Palette.GOLD
	render_guard(s, p, obs, 2.4)

## Twinfang (Tempo): SPACE is THE ONE DODGE. FERMATA: key 1 DOWN coils into shadow,
## key 1 UP (key_released) releases; the dumps (keys 2-5) stay instant taps.
func key_pressed(code: int) -> void:
	if hud._aspect == "fermata":
		match code:
			KEY_SPACE:
				hud._ctrl.human({"type": "defense"})   # THE ONE DODGE
			KEY_1:
				if not coil_held:
					coil_held = true
					hud._ctrl.human({"type": "ability", "id": "coil"})
			KEY_2: press_rune(1)
			KEY_3: press_rune(2)
			KEY_4: press_rune(3)
			KEY_5: press_rune(4)
		return
	match code:
		KEY_SPACE:
			hud._ctrl.human({"type": "defense"})
		KEY_1: press_rune(0)
		KEY_2: press_rune(1)
		KEY_3: press_rune(2)
		KEY_4: press_rune(3)
		KEY_5: press_rune(4)

## FERMATA's hold-release Strike: releasing key 1 RELEASES the coil (resolves the strike).
func key_released(event: InputEventKey) -> bool:
	if hud._aspect != "fermata":
		return false
	if event.keycode == KEY_1 and coil_held:
		coil_held = false
		hud._ctrl.human({"type": "ability", "id": "release"})
	return true

## Widget flashes for the blade's own verdicts (the HUD keeps the big-text body).
func on_event(ev: Dictionary, mine: bool) -> void:
	if not mine:
		return
	match String(ev.get("t", "")):
		"strike":
			if rhythm != null:
				var res := String(ev.get("result", ""))
				# FERMATA ramp: pass the real grade so the DEPTH verdict reads; Tempo folds bull→perfect.
				rhythm.show_result(res if rhythm.ramp else ("perfect" if (res == "perfect" or res == "bullseye") else res))
		"snap":
			if rhythm != null:
				rhythm.show_result("snap")
		"opening":
			if opening != null:
				opening.show_result(String(ev.get("grade", "")))
