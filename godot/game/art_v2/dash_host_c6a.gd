## DashHostC6A — the REACTION-FIRST GRAYBOX HOST (GRAPHICS-PLAN §2.3 / P5 / C6A).
## Behind `--artv2=…,dash`, Duelist-only: proves the permanent screen anatomy with
## plain code-drawn panels and the EXISTING live controls — this packet is a
## layout/interaction proof, deliberately art-free (C6B skins it after Bill's
## rectangle verdict + Codex I3).
##
## THE ONE LAYOUT CONTRACT — `DashHostC6A.layout(vp)` owns every rectangle:
##   STATUS RAIL   (party island · boss HP/cast island · utility/meter island)
##   COMBAT THEATER (scene + actors + transient FX/numbers — NO persistent UI, ever)
##   ANSWER        (the dominant AnswerChannel — broad, unmistakably primary)
##   DASHBOARD     (HP · Flow/Aggro+30% lock · Wind · 5 combo sockets · 4 abilities)
##   HINT GUTTER   (collapses first at 720p)
## Responsive: 720p collapses hint/ornament but NEVER shrinks the answer
## instrument into unreadability; ultrawide grows the theater sideways while the
## central instruments keep a sane max width.
##
## TRUTH REUSE, NOT REIMPLEMENTATION: the host creates the REAL BossBar/
## BossCastBar (+ dial/judge, parked hidden by the one-bar law) and the REAL
## DuelistBand via ClassBand.for_hud — then RE-PLACES those live widgets through
## the contract. Same-frame press marks, ±ms readouts, comet resolution, grade
## vocabulary, event/tick/input routing: all untouched — the AnswerChannel is the
## same instance the legacy HUD builds, at a new size. RaidStage2D keeps SLOTS as
## its LOCAL spacing grammar and is placed INTO the theater (view-only
## `dash_scale`); SceneKit's floor reflows to the same line (`dash_floor_px`).
## View-only throughout: no CombatState/spec/protocol/checksum contact.
class_name DashHostC6A
extends Control

var hud                            ## the RaidHud (untyped — scene script)
var band: ClassBand = null         ## the REAL DuelistBand (hud._band points here)
var _overlay: Control = null       ## dev rect-label overlay (ArtV2.dash_debug)
var _party_grid: GridContainer = null
var _meter_clip: Control = null
var _late_done := false
var _r: Dictionary = {}            ## the live rects (recomputed on resize)
# --- C6B: the painted skin. null (any I3-B piece missing) ⇒ every widget keeps its
# legacy chrome and this host stays the C6A graybox — the missing-asset fail-safe.
# The LAYOUT CONTRACT (Bill's approved rectangles) is identical either way; C6B
# changes costumes, never anatomy.
var _skin: DashSkin = null
var _rows: Array = []              ## DashPartyRow[] (skinned party island)
var _tab = null                    ## DashUtilTab (untyped: inner class, dynamic .host)

## THE CONTRACT. Reference anatomy @1920×1080: status 0-150 · theater 150-560 ·
## answer 560-750 · dashboard 750-1040 · hint 1040-1080. Everything scales from
## vp; hint and ornament collapse first; the answer floor is 150px.
static func layout(vp: Vector2) -> Dictionary:
	var s := vp.y / 1080.0
	var status_h := roundf(150.0 * s)
	var hint_h := roundf(40.0 * s) if vp.y >= 900.0 else 0.0
	var answer_h := maxf(150.0, roundf(190.0 * s))
	var dash_h := maxf(120.0, roundf(150.0 * s))   # Bill (live, 2026-07-13): halve it — the theater gets the space
	var theater_top := status_h
	var theater_bot := vp.y - hint_h - dash_h - answer_h
	var answer_w := minf(vp.x * 0.66, 1240.0)
	var cluster_w := minf(vp.x * 0.62, 1000.0)   # the dashboard instrument cluster
	return {
		"status": Rect2(0, 0, vp.x, status_h),
		"theater": Rect2(0, theater_top, vp.x, theater_bot - theater_top),
		"answer": Rect2(vp.x * 0.5 - answer_w * 0.5, theater_bot, answer_w, answer_h),
		"dash": Rect2(0, theater_bot + answer_h, vp.x, dash_h),
		"hint": Rect2(0, vp.y - hint_h, vp.x, hint_h),
		"cluster_w": cluster_w,
		"floor_px": theater_top + (theater_bot - theater_top) * 0.80,
		"stage_scale": clampf((theater_bot - theater_top) / 520.0, 0.55, 1.0),
	}

func _init(h) -> void:
	hud = h
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# --- the enemy island: REAL boss widgets, created synchronously so every
	# existing unguarded feed (_bar.hp etc) is satisfied from frame one ---
	hud._bar = BossBar.new()
	add_child(hud._bar)
	hud._castbar = BossCastBar.new()
	add_child(hud._castbar)
	# dial + judge: real widgets, parked — the one-bar law hides both for the
	# duelist seat every frame; their feeds keep writing into hidden controls.
	hud._dial = BossCastDial.new()
	hud._dial.verb = hud._verb()
	hud._dial.show_sigil = false
	hud._dial.visible = false
	add_child(hud._dial)
	hud._judge = StrikeJudge.new()
	hud._judge.verb = hud._verb()
	hud._judge.visible = false
	add_child(hud._judge)
	# --- the REAL class band (channel/gauge/orbs/runes build against the HUD
	# exactly as legacy does; we re-place its widgets through the contract) ---
	band = ClassBand.for_hud(hud)
	band.build()
	hud._band = band
	# --- C6B: dress the truth widgets in the approved I3-B paint. Every flag below
	# defaults OFF and is set ONLY here — legacy/default-off builds never see them.
	# DashSkin resolves all textures NOW, at construction (§3½ renderer law). ---
	_skin = DashSkin.make()
	if _skin != null:
		hud._bar.v2_naked = true
		hud._castbar.v2_skin = _skin
		if band is DuelistBand:
			var db := band as DuelistBand
			db.channel.v2_skin = _skin        # painted ◇⬡⯃⊘ comets + purple feints
			db.channel.v2_naked = true        # the painted answer frame owns the housing
			db.gauge.v2_skin = _skin          # Wind = central primary bar · 5 sockets below
			for rn in [db.dodge_rune, db.parry_rune, db.dump_rune, db.engarde_rune]:
				(rn as AbilityRune).v2_skin = _skin
		if band.hp_orb != null:               # horizontal safety bars (§2.3.1 E)
			band.hp_orb.v2_bar = _skin
		if band.res_orb != null:
			band.res_orb.v2_bar = _skin
			band.res_orb.v2_pct = true
			band.res_orb.v2_lock = 0.30       # the 30% Flow lock — code-drawn, by law

func _ready() -> void:
	# the host paints the graybox panels UNDER the band widgets it re-places —
	# band.build() already attached them to _shake_root before we were added
	get_parent().move_child(self, 0)
	resized.connect(_relayout_all)
	_relayout_all()
	call_deferred("_late_adopt")   # frames/meter/aggro/stage build after make_dash

## Adopt the widgets _build_combat creates after the v2dash guard: the party
## frames become a compact top-left grid, the meter a clipped top-right island,
## the stage is placed into the theater, SceneKit's floor reflows to match.
func _late_adopt() -> void:
	if _late_done or hud == null:
		return
	_late_done = true
	if _skin != null:
		# C6B party island: FOUR painted rows (portrait/HP/resource/cast/3 sockets).
		# The REAL RaidFrames ride inside each row invisible — still fed by
		# _render_frames, still the hover/click targets (healer click-cast law).
		for e in hud._frames:
			var fr2: RaidFrame = (e as Dictionary)["frame"]
			fr2.get_parent().remove_child(fr2)
			var row := DashPartyRow.new()
			row.setup(hud, (e as Dictionary)["seat"], fr2, _skin)
			add_child(row)
			_rows.append(row)
		if hud._raid_col != null:
			hud._raid_col.visible = false
	else:
		# C6A graybox: compact 2×2 island (the REAL RaidFrames — _render_frames keeps
		# feeding them; reparenting preserves every reference)
		_party_grid = GridContainer.new()
		_party_grid.columns = 2
		_party_grid.add_theme_constant_override("h_separation", 6)
		_party_grid.add_theme_constant_override("v_separation", 4)
		for e in hud._frames:
			var fr: Control = (e as Dictionary)["frame"]
			fr.get_parent().remove_child(fr)
			_party_grid.add_child(fr)
		if hud._raid_col != null:
			hud._raid_col.visible = false
		add_child(_party_grid)
	# meter → collapsed-but-reachable top-right island (clipped: NOTHING bleeds
	# into the theater below the rail). C6B: the painted utility tab is the
	# collapsed presentation — a live code-drawn raid-DPS spark in its window,
	# click to expand the real meter panel under it (still rail-clipped).
	_meter_clip = Control.new()
	_meter_clip.clip_contents = true
	add_child(_meter_clip)
	if hud._meter != null:
		hud._meter.get_parent().remove_child(hud._meter)
		_meter_clip.add_child(hud._meter)
	if _skin != null:
		_tab = DashUtilTab.new()
		_tab.host = self
		_tab.skin = _skin
		add_child(_tab)
		_meter_clip.visible = false          # collapsed by default; the tab expands it
		# the dev BUILD STAMP squats on the party island's rail spot — park it in
		# the hint gutter (bottom-left), clear of the four painted rows
		for ch in hud._ui.get_children():
			if ch is Label and (ch as Label).text == String(hud.BUILD_STAMP):
				UiKit.place(ch, 0, 1, 0, 1, 16, -24, 360, -4)
	if ArtV2.dash_debug:
		_overlay = Control.new()
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.draw.connect(_paint_overlay)
		hud._ui.add_child(_overlay)   # topmost — labels every contract rect
	_relayout_all()

## ONE place computes, everything follows — never scatter pixel coordinates.
func _relayout_all() -> void:
	var vp := size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	_r = DashHostC6A.layout(vp)
	var status: Rect2 = _r["status"]
	var answer: Rect2 = _r["answer"]
	var dash: Rect2 = _r["dash"]
	var hint: Rect2 = _r["hint"]
	var theater: Rect2 = _r["theater"]
	var cw: float = _r["cluster_w"]
	var cx := vp.x * 0.5
	# --- status rail islands ---
	var bw := minf(560.0, vp.x * 0.36)
	if _skin != null:
		# the painted boss shell: uniform scale (the medallion never stretches);
		# the REAL BossBar's fill lands in the shell's recessed window
		bw = minf(500.0, vp.x * 0.32)
		var sh_h := minf(bw * 0.175, status.size.y * 0.56)
		var sh_w := sh_h / 0.175
		var shell := Rect2(vp.x * 0.5 - sh_w * 0.5, status.size.y * 0.03, sh_w, sh_h)
		_r["boss_shell"] = shell
		var win := DashSkin.uniform_opening(shell, DashSkin.OPEN_BOSS)
		UiKit.place(hud._bar, 0, 0, 0, 0, win.position.x + 4.0, maxf(2.0, win.end.y - 72.0),
			win.end.x - 4.0, win.end.y - 6.0)
		UiKit.place(hud._castbar, 0, 0, 0, 0, win.position.x + 10.0, shell.end.y + 2.0,
			win.end.x - 10.0, minf(shell.end.y + 44.0, status.size.y * 0.93))
	else:
		UiKit.place(hud._bar, 0.5, 0, 0.5, 0, -bw * 0.5, status.size.y * 0.16, bw * 0.5, status.size.y * 0.52)
		UiKit.place(hud._castbar, 0.5, 0, 0.5, 0, -bw * 0.42, status.size.y * 0.56, bw * 0.42, status.size.y * 0.88)
	if hud._aggro_warn != null:
		UiKit.place(hud._aggro_warn, 0.5, 0, 0.5, 0, -360, status.size.y * 0.88, 360, status.size.y + 2.0)
	if _party_grid != null:
		_party_grid.scale = Vector2.ONE * clampf(status.size.y / 220.0, 0.55, 0.75)
		_party_grid.position = Vector2(10, 8)
	if not _rows.is_empty():                # C6B: four painted rows, stacked in the rail
		var row_h := clampf((status.size.y - 16.0) / 4.0 - 3.0, 22.0, 40.0)
		var row_w := minf(row_h * 4.38 * 2.4, minf(340.0, vp.x * 0.18))
		for i in _rows.size():
			var pr: Control = _rows[i]
			pr.position = Vector2(10, 6.0 + float(i) * (row_h + 3.0))
			pr.size = Vector2(row_w, row_h)
	if _tab != null:                        # the collapsed utility tab, top-right
		var tab_h := clampf(status.size.y * 0.36, 34.0, 64.0)
		var tex: Texture2D = _skin.t["utility_tab"]
		var tab_w := tab_h * float(tex.get_width()) / float(tex.get_height())
		_tab.position = Vector2(vp.x - tab_w - 10.0, 6.0)
		_tab.size = Vector2(tab_w, tab_h)
	if _meter_clip != null:
		if _tab != null:                    # expanded meter drops in UNDER the tab, rail-clipped
			UiKit.place(_meter_clip, 1, 0, 1, 0, -330, _tab.size.y + 10.0, -8, status.size.y - 4.0)
		else:
			UiKit.place(_meter_clip, 1, 0, 1, 0, -330, 6, -8, status.size.y - 6.0)
		if hud._meter != null:
			hud._meter.position = Vector2.ZERO
			hud._meter.size = _meter_clip.size
	# --- the dominant answer instrument (the SAME live widget, re-placed).
	#     C6B: the channel sits INSIDE the painted frame's opening — same contract
	#     rect, the frame just wears it. ---
	if band != null and band.get("channel") != null:
		if _skin != null:
			var frect := answer.grow_individual(12.0, 8.0, 12.0, 12.0)
			_r["answer_frame"] = frect
			var op := _skin.sliced_opening("frame_answer", frect, DashSkin.CAPS_ANSWER, DashSkin.OPEN_ANSWER)
			UiKit.place(band.channel, 0, 0, 0, 0, op.position.x, op.position.y, op.end.x, op.end.y)
		else:
			UiKit.place(band.channel, 0, 0, 0, 0, answer.position.x, answer.position.y + 4.0,
				answer.end.x, answer.end.y - 4.0)
	# --- the connected dashboard cluster ---
	if band != null:
		var dh := dash.size.y
		if _skin != null:
			# Wind = the central primary bar with the socket bank under it (taller
			# gauge row); bars flank at the cluster edges as horizontal safety rails
			if band.get("gauge") != null:
				UiKit.place(band.gauge, 0.5, 0, 0.5, 0, -240, dash.position.y + dh * 0.02, 240, dash.position.y + dh * 0.40)
			var vrow: Control = band.dodge_rune.get_parent() if band.get("dodge_rune") != null else null
			if vrow != null:
				UiKit.place(vrow, 0.5, 0, 0.5, 0, -220, dash.position.y + dh * 0.42, 220, dash.position.y + dh * 0.98)
			var bar_w := minf(300.0, cw * 0.5 - 245.0)
			var bar_h := clampf(dh * 0.24, 24.0, 34.0)
			var bar_y := dash.position.y + dh * 0.30
			if band.hp_orb != null:
				UiKit.place(band.hp_orb, 0.5, 0, 0.5, 0, -cw * 0.5, bar_y, -cw * 0.5 + bar_w, bar_y + bar_h)
			if band.res_orb != null:    # the 30% lock line rides the bar itself (code-drawn)
				UiKit.place(band.res_orb, 0.5, 0, 0.5, 0, cw * 0.5 - bar_w, bar_y, cw * 0.5, bar_y + bar_h)
		else:
			if band.get("gauge") != null:   # Wind bubble + the 5 combo sockets
				UiKit.place(band.gauge, 0.5, 0, 0.5, 0, -230, dash.position.y + dh * 0.05, 230, dash.position.y + dh * 0.33)
			var row: Control = band.dodge_rune.get_parent() if band.get("dodge_rune") != null else null
			if row != null:                 # the 4 compact abilities, docked under the spine
				# fraction rows: an HBox taller than its runes STRETCHES them (the
				# smeared-glow ghost bug) — the runes keep their own minimum size
				UiKit.place(row, 0.5, 0, 0.5, 0, -220, dash.position.y + dh * 0.36, 220, dash.position.y + dh * 0.97)
			if band.hp_orb != null:         # HP west of the spine, inside the cluster
				UiKit.place(band.hp_orb, 0.5, 0, 0.5, 0, -cw * 0.5, dash.position.y + dh * 0.08, -cw * 0.5 + 120.0, dash.position.y + dh * 0.90)
			if band.res_orb != null:        # FLOW/AGGRO east — the 30% lock tick rides _draw
				UiKit.place(band.res_orb, 0.5, 0, 0.5, 0, cw * 0.5 - 120.0, dash.position.y + dh * 0.08, cw * 0.5, dash.position.y + dh * 0.90)
	if hud._hint_lbl != null:           # the hint gutter collapses FIRST at 720p
		hud._hint_lbl.visible = hint.size.y > 0.0
		if hint.size.y > 0.0:
			UiKit.place(hud._hint_lbl, 0.5, 1, 0.5, 1, -430, -hint.size.y, 430, -6)
	# --- THE THEATER: stage INTO the rect (SLOTS stay the local grammar) ---
	if hud._stage2d != null:
		UiKit.place(hud._stage2d, 0, 0, 1, 0, 0, theater.position.y, 0, theater.end.y)
		hud._stage2d.dash_scale = float(_r["stage_scale"])
		hud._stage2d._layout()
	if hud._stage is SceneKit:          # scenery floor = the SAME screen line
		(hud._stage as SceneKit).dash_floor_px = float(_r["floor_px"])
		(hud._stage as SceneKit)._relayout()
	queue_redraw()
	if _overlay != null:
		_overlay.queue_redraw()

# ---------------------------------------------------------------- graybox paint
## Plain code-drawn panels — INTENTIONALLY unskinned (C6B consumes Codex I3 art
## after Bill approves these rectangles). The theater rect is never painted.
func _draw() -> void:
	if _r.is_empty():
		return
	var status: Rect2 = _r["status"]
	var answer: Rect2 = _r["answer"]
	var dash: Rect2 = _r["dash"]
	var hint: Rect2 = _r["hint"]
	var panel := Color(0.055, 0.065, 0.095, 0.86)
	var edge := Color(0.75, 0.62, 0.32, 0.30)
	draw_rect(status, panel)
	draw_line(Vector2(0, status.end.y), Vector2(size.x, status.end.y), edge, 1.5)
	draw_rect(dash, panel)
	draw_line(Vector2(0, dash.position.y), Vector2(size.x, dash.position.y), edge, 1.5)
	if hint.size.y > 0.0:
		draw_rect(hint, Color(0.04, 0.05, 0.075, 0.9))
	# a quiet backing so the broad channel reads as THE primary instrument
	draw_rect(answer.grow_individual(10, 4, 10, 4), Color(0.05, 0.06, 0.09, 0.62))
	# --- C6B: the painted shells (drawn UNDER the truth widgets — host is child 0).
	# Modular authored components only, never one baked HUD image. ---
	if _skin != null:
		if _r.has("answer_frame"):
			_skin.hshell(self, "frame_answer", _r["answer_frame"], DashSkin.CAPS_ANSWER)
		if _r.has("boss_shell"):
			var sh: Rect2 = _r["boss_shell"]
			var stex: Texture2D = _skin.t["shell_boss"]
			var win := DashSkin.uniform_opening(sh, DashSkin.OPEN_BOSS)
			draw_rect(win.grow(2.0), Color(0.03, 0.035, 0.055, 0.85))   # the recessed well
			draw_texture_rect(stex, sh, false)
	# island backings (party / meter) — kept inside the rail
	if _party_grid != null:
		var pr := Rect2(_party_grid.position - Vector2(4, 4), _party_grid.size * _party_grid.scale + Vector2(8, 8))
		draw_rect(pr.intersection(status), Color(0.05, 0.06, 0.09, 0.5))
	# the 30% AGGRO LOCK tick on the Flow orb (graybox: hairline + label; the C6B
	# bar draws its own code-owned lock line — LiquidOrb.v2_lock)
	if _skin == null and band != null and band.res_orb != null:
		var o := band.res_orb
		var oy := o.position.y + o.size.y * 0.70   # 30% fill = 70% down the orb
		draw_line(Vector2(o.position.x - 6, oy), Vector2(o.position.x + o.size.x + 6, oy),
			Color(1.0, 0.62, 0.30, 0.85), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(o.position.x + o.size.x + 10, oy + 4),
			"30% LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.62, 0.30, 0.9))

## The utility tab's chevron expands/collapses the real meter panel (rail-clipped).
func _toggle_meter() -> void:
	if _meter_clip != null:
		_meter_clip.visible = not _meter_clip.visible

## DashUtilTab — the collapsed utility/damage-meter island in the approved I3-B
## shell. The data window carries a LIVE code-drawn raid-DPS spark (derived from
## boss HP falling — real combat truth, nothing baked; the dedicated alpha source's
## window is transparent BY DESIGN so this stays code-owned). Click = expand the
## real MeterPanel below (unchanged widget, still clipped inside the status rail).
class DashUtilTab:
	extends Control
	var host                       ## DashHostC6A
	var skin: DashSkin
	var _samples: Array = []       ## rolling dps samples (view-only, cosmetic)
	var _acc := 0.0
	var _prev_hp := -1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = "Damage meter — click to expand/collapse"

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			host._toggle_meter()

	func _process(delta: float) -> void:
		_acc += delta
		if _acc >= 0.25:
			_acc = 0.0
			var s: CombatState = null
			if host != null and host.hud != null and host.hud._ctrl != null:
				s = host.hud._ctrl.state
			if s != null and not s.over:
				var hp := s.boss.hp
				if _prev_hp >= 0.0:
					_samples.append(maxf(0.0, (_prev_hp - hp) / 0.25))
					if _samples.size() > 48:
						_samples.pop_front()
				_prev_hp = hp
			queue_redraw()

	func _draw() -> void:
		if skin == null:
			return
		var rect := Rect2(Vector2.ZERO, size)
		draw_texture_rect(skin.t["utility_tab"], rect, false)
		var win := DashSkin.uniform_opening(rect, DashSkin.OPEN_UTIL)
		draw_rect(win, Color(0.02, 0.025, 0.04, 0.9))
		if _samples.size() >= 2:
			var peak := 1.0
			for v in _samples:
				peak = maxf(peak, float(v))
			var pts := PackedVector2Array()
			for i in _samples.size():
				pts.append(Vector2(
					win.position.x + win.size.x * float(i) / float(_samples.size() - 1),
					win.end.y - 1.5 - (win.size.y - 4.0) * clampf(float(_samples[i]) / peak, 0.0, 1.0)))
			draw_polyline(pts, Palette.GOLD_BRIGHT, 1.2, true)
			UiKit.text_shadowed(self, UiKit.display(600), Vector2(win.position.x, win.position.y + 9.0),
				str(int(round(float(_samples.back())))) + " dps", HORIZONTAL_ALIGNMENT_RIGHT,
				win.size.x - 3.0, UiKit.SIZE["MICRO"], Palette.GOLD_DIM.lightened(0.3))
		else:
			UiKit.text_shadowed(self, UiKit.display(600), Vector2(win.position.x, win.get_center().y + 3.5),
				"DPS", HORIZONTAL_ALIGNMENT_CENTER, win.size.x, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

## The dev overlay: labeled contract rectangles for tour screenshots.
func _paint_overlay() -> void:
	if _r.is_empty():
		return
	var names := {"status": Color(0.4, 0.8, 1.0), "theater": Color(0.4, 1.0, 0.5),
		"answer": Color(1.0, 0.85, 0.3), "dash": Color(1.0, 0.5, 0.7), "hint": Color(0.8, 0.6, 1.0)}
	for key in names:
		var r: Rect2 = _r[key]
		if r.size.y <= 0.0:
			continue
		var col: Color = names[key]
		_overlay.draw_rect(r, Color(col.r, col.g, col.b, 0.09))
		_overlay.draw_rect(r, col, false, 2.0)
		_overlay.draw_string(ThemeDB.fallback_font, r.position + Vector2(10, 24),
			"%s  %d×%d @ y%d" % [String(key).to_upper(), int(r.size.x), int(r.size.y), int(r.position.y)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
