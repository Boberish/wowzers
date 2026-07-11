## The Well's band — built on the SHARED healer surfaces: click-cast chords
## (WellBinds), the healer CastChannel (extended with DRAW's release window,
## always-visible track, tap-to-release), and the WellGauge (charges + Current +
## the big TARGET bar Brim aims on). No mana orb — the Well IS the resource, in the
## gauge. DRAW's two release styles (tap-tap and hold-release, key or mouse) live
## here: the hold bookkeeping was ~5 members on the HUD, now band state.
class_name WellBand
extends HealerBand

var well_gauge: WellGauge
var hold_key: int = -1             ## DRAW: which heal key owns the live hold-release
var hold_ms: int = 0               ## DRAW: when the hold began (tap vs hold threshold)
var mouse_ms: int = 0              ## DRAW: when a mouse-started cast began (hold-release)

func build() -> void:
	binds = WellBinds.load_binds()
	# the shared healer cast bar; DRAW marks the release window on it (and wears the
	# Well's water blue — spec color identity), clicking the channel is a release press.
	# The idle track keeps the window readable between casts. Added BEFORE the gauge:
	# the gauge's verdict banner rises over the channel, so it must draw on top.
	castbar = CastChannel.new()
	if hud._aspect == "draw":
		castbar.accent = Palette.WATER
		castbar.zone_lo = 1.0 - hud._wcfg.draw_band
		var sp_c: float = 1.0 - hud._wcfg.draw_band * 0.5
		castbar.mark_lo = sp_c - hud._wcfg.still_point * 0.5
		castbar.mark_hi = sp_c + hud._wcfg.still_point * 0.5
		castbar.show_idle_track = true
		castbar.tapped.connect(func(): hud._ctrl.human({"type": "ability", "id": "release"}))
	# the Well's channel is placed TALL — the shared CastChannel scales its whole
	# instrument with height, so this one bar is the big AAA read (classic healers
	# keep their 60-tall placement).
	UiKit.place(castbar, 0.5, 1, 0.5, 1, -330, -420, 330, -304)
	hud._shake_root.add_child(castbar)
	well_gauge = WellGauge.new()
	well_gauge.aspect = hud._aspect
	UiKit.place(well_gauge, 0.5, 1, 0.5, 1, -330, -300, 330, -166)
	hud._shake_root.add_child(well_gauge)
	var row: HBoxContainer = hud._rune_row(-380.0, 380.0)
	runes = []
	rune_ids = []
	for id in hud._loadout:
		var sp: Dictionary = hud._wcfg.book.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		rune.custom_minimum_size = Vector2(62, 62)
		rune.pressed.connect(hud._cast.bind(String(id)))
		row.add_child(rune)
		runes.append(rune)
		rune_ids.append(id)
	hud._hint_line(_hint())

func _hint() -> String:
	var verb := "click/tap to heal — LAND it in the gold band (no spill) = POUR" if hud._aspect == "brim" \
		else "click/tap starts the cast — click/tap AGAIN (or hold & release) in the window = CLEAN"
	return "Hover an ally · L flash · R mend · Mid cascade · Sh+L spring · Sh+R dispel · Ctrl+R/E skin · 1-4 keys · %s · SPACE dodge" % verb

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	var g := well_gauge
	if g == null:
		return
	g.seat_ref = p
	g.aspect = hud._aspect
	g.charges = int(obs.get("charges", 0))
	g.charges_max = int(obs.get("charges_max", 12))
	g.current = int(obs.get("current", 0))
	g.current_max = int(obs.get("current_max", 5))
	g.current_haste = float(obs.get("current_haste", 0.06))
	g.millrace_ready = bool(obs.get("millrace_ready", false))
	# the SHARED cast channel (with DRAW's release window baked in at build)
	var casting: Dictionary = obs.get("casting", {})
	render_castbar(s, casting, hud._wcfg.book)
	# DRAW: feed the channel the LIVE per-cast geometry + banked state, so the DRAWN window is the
	# one the kit grades — THE EDDY's window now moves; Narrows/Long-Draw/Deep-Still widths correct;
	# the BANKED (Patient Hand / ⭐Vigil) held heal reads as spendable, not as a finished cast.
	if hud._aspect == "draw" and castbar != null:
		var cc := castbar
		cc.frozen = bool(obs.get("frozen", false))
		cc.flume = bool(obs.get("flume", false))
		if obs.has("draw_lo"):                                   # a live draw cast — drifted geometry
			cc.zone_lo = float(obs["draw_lo"]); cc.zone_hi = float(obs["draw_hi"])
			cc.mark_lo = float(obs["still_lo"]); cc.mark_hi = float(obs["still_hi"])
			cc.cr_hi = float(obs.get("cr_hi", -1.0))
		else:                                                   # idle track — deck-adjusted, undrifted
			var db := float(obs.get("draw_band", hud._wcfg.draw_band))
			var sw := float(obs.get("still_point", hud._wcfg.still_point))
			var sp_c := 1.0 - db * 0.5
			cc.zone_lo = 1.0 - db; cc.zone_hi = -1.0
			cc.mark_lo = sp_c - sw * 0.5; cc.mark_hi = sp_c + sw * 0.5
			cc.cr_hi = -1.0
		cc.held = bool(obs.get("held", false))
		if cc.held:
			var t := int(obs.get("tick", 0))
			var hs := int(obs.get("held_start", t))
			var hu := int(obs.get("held_until", t))
			cc.held_frac = clampf(float(t - hs) / maxf(1.0, float(hu - hs)), 0.0, 1.0)
			cc.held_left = maxf(0.0, float(hu - t) / 30.0)
			cc.tremble_frac = float(obs.get("tremble_frac", -1.0))
			cc.loosed_ready = bool(obs.get("loosed_ready", false))
		else:
			cc.held_left = -1.0; cc.tremble_frac = -1.0; cc.loosed_ready = false
	# THE TARGET BAR: the cast's target while casting, else the hovered/focused ally.
	# Brim aims the pour here (band + the in-flight heal's ghost landing).
	var tgt: Seat = casting.get("target") if not casting.is_empty() else null
	if tgt == null:
		tgt = hud._hover_seat if hud._hover_seat != null else hud._focus_seat
	if tgt != null and tgt.alive():
		g.t_show = true
		g.t_name = tgt.unit_name
		g.t_frac = tgt.hp_frac()
		g.t_hp = int(round(tgt.hp))
		g.t_hpmax = int(round(tgt.hp_max))
		g.t_band = hud._wcfg.brim_band if hud._aspect == "brim" else -1.0
		g.t_glint = CombatCore.vuln_until(s, s.seats.find(tgt), &"glint") >= 0
		g.t_ghost = -1.0
		if not casting.is_empty() and casting.get("target") == tgt:
			var wsp: Dictionary = hud._wcfg.book.get(String(casting.get("id", "")), {})
			if wsp.has("heal"):
				g.t_ghost = clampf(tgt.hp_frac() + float(wsp.get("heal", 0.0)) / maxf(tgt.hp_max, 1.0), 0.0, 1.0)
	else:
		g.t_show = false

## The Well's keys. BRIM taps 1-4 (grades on landing). DRAW holds 1-4 to cast and
## RELEASES the key to pour (key_released sends the "release" action).
## Q dispel · R rekindle (hover a fallen ally) · SPACE dodge (cancels a cast).
func key_pressed(code: int) -> void:
	match code:
		KEY_SPACE:
			hud._ctrl.human({"type": "dodge"})   # THE ONE DODGE (healers face only barrage beats)
		KEY_1, KEY_2, KEY_3, KEY_4:
			# DRAW does BOTH release styles: a press while casting = the release (tap-tap),
			# and a key HELD past the tap threshold releases on key-up (hold-release).
			if hud._aspect == "draw" and not hud._ctrl.player().casting.is_empty():
				hold_key = -1
				hud._ctrl.human({"type": "ability", "id": "release"})
				return
			var id: String = {KEY_1: "flash", KEY_2: "mend", KEY_3: "cascade", KEY_4: "spring"}[code]
			if hud._aspect == "draw":
				hold_key = code
				hold_ms = Time.get_ticks_msec()
			hud._cast(id)
		KEY_E:
			# SKIN — a graded DRAW cast like 1-4 (the advertised [E] keycap, now wired): a press
			# while casting = the release; else arm the hold + start it on the hovered ally.
			if hud._aspect == "draw" and not hud._ctrl.player().casting.is_empty():
				hold_key = -1
				hud._ctrl.human({"type": "ability", "id": "release"})
				return
			if hud._aspect == "draw":
				hold_key = code
				hold_ms = Time.get_ticks_msec()
			hud._cast("skin")
		KEY_Q: hud._cast("dispel")
		KEY_R: hud._cast("rekindle")

## DRAW hold-release: a heal key HELD past the tap threshold pours on key-up.
## A quick TAP leaves the cast running — tap/click again to pour (the two-click style).
func key_released(event: InputEventKey) -> bool:
	if hud._aspect != "draw":
		return false
	if event.keycode == hold_key:
		var held := Time.get_ticks_msec() - hold_ms
		hold_key = -1
		if held >= 250 and not hud._ctrl.player().casting.is_empty():
			hud._ctrl.human({"type": "ability", "id": "release"})
	return true

## DRAW mouse grammar first (a bound chord pressed WHILE CASTING = the release —
## click-click; a mouse button held past the threshold releases on button-up),
## then the shared healer click-cast.
func mouse(event: InputEventMouseButton) -> void:
	if hud._aspect == "draw":
		if event.pressed and not hud._ctrl.player().casting.is_empty() \
				and String(binds.get(hud._mouse_chord(event), "none")) != "none":
			mouse_ms = 0
			hud._ctrl.human({"type": "ability", "id": "release"})
			return
		if not event.pressed and mouse_ms > 0:
			var mheld := Time.get_ticks_msec() - mouse_ms
			mouse_ms = 0
			if mheld >= 300 and not hud._ctrl.player().casting.is_empty():
				hud._ctrl.human({"type": "ability", "id": "release"})
				return
	super.mouse(event)

func on_event(ev: Dictionary, _mine: bool) -> void:
	if well_gauge != null:
		well_gauge.on_event(ev)   # THE WELL: pour/still/clean/under/spill verdicts + history
