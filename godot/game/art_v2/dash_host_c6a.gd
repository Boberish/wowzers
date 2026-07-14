## DashHostC6A — the REACTION-FIRST GRAYBOX HOST (GRAPHICS-PLAN §2.3 / P5 / C6A).
## Behind `--artv2=…,dash`, Duelist-only: proves the permanent screen anatomy with
## plain code-drawn panels and the EXISTING live controls — this packet is a
## layout/interaction proof, deliberately art-free (C6B skins it after Bill's
## rectangle verdict + Codex I3).
##
## THE ONE LAYOUT CONTRACT — `DashHostC6A.layout(vp)` owns every rectangle:
##   UPPER ISLANDS (large party island · boss HP/cast · quiet utility/meter)
##   COMBAT THEATER (scene + actors + transient FX; player/boss centreline stays clear)
##   ANSWER        (the dominant AnswerChannel — broad, unmistakably primary)
##   DASHBOARD     (HP · Flow/Aggro · Wind · 5 combo sockets · modular abilities)
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
## The large party island may overlay the theater's safe west edge like the anchor;
## it never covers the player/boss reaction line. View-only throughout: no
## CombatState/spec/protocol/checksum contact.
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

## THE CONTRACT. C6C rebuilds the old full-width rails as modular islands matching
## the approved dream-dashboard anchor. Reference anatomy @1920×1080: party
## 459×450 at the west edge · boss 789×138 top-centre · theater 120-610 · answer
## 1240×176 · three large resource instruments + a five-slot-capable ability dock.
## All numbers derive from this function; the live widgets only consume its rects.
static func layout(vp: Vector2) -> Dictionary:
	var s := clampf(vp.y / 1080.0, 2.0 / 3.0, 1.0)
	var status_h := roundf(120.0 * s)
	var hint_h := 40.0 if vp.y >= 900.0 else 0.0
	var answer_h := maxf(150.0, roundf(176.0 * s))
	var dash_h := maxf(172.0, roundf(254.0 * s))
	var answer_y := vp.y - hint_h - dash_h - answer_h
	var answer_w := minf(vp.x * 0.66, 1240.0)
	var answer := Rect2(vp.x * 0.5 - answer_w * 0.5, answer_y, answer_w, answer_h)
	var theater := Rect2(0.0, status_h, vp.x, answer_y - status_h)

	# Party rows keep the source art's ~4.38:1 shape instead of being crushed into
	# the former 30px rail. Four rows plus three gaps are one deliberate island.
	var row_h := clampf(roundf(108.0 * s), 78.0, 108.0)
	var row_gap := clampf(roundf(6.0 * s), 4.0, 6.0)
	var party_w := clampf(vp.x * 0.26, 332.0, 459.0)
	var party := Rect2(roundf(14.0 * s), roundf(12.0 * s), party_w,
		row_h * 4.0 + row_gap * 3.0)

	# Authored shells are scaled uniformly by height; their medallions/corners never
	# stretch. The cast overlaps the boss shell by a few pixels as one joined island.
	var boss_sz := Vector2(789.0, 138.0) * s
	var boss_shell := Rect2(Vector2(vp.x * 0.5 - boss_sz.x * 0.5, roundf(10.0 * s)), boss_sz)
	var cast_sz := Vector2(560.0 * s, maxf(34.0, 44.0 * s))
	var boss_cast := Rect2(vp.x * 0.5 - cast_sz.x * 0.5,
		boss_shell.end.y - 6.0 * s, cast_sz.x, cast_sz.y)
	var util_sz := Vector2(259.0, 66.0) * s
	var utility := Rect2(vp.x - util_sz.x - 16.0 * s, 16.0 * s, util_sz.x, util_sz.y)
	var meter_top := utility.end.y + 8.0 * s
	var meter_h := minf(420.0 * s, maxf(220.0, answer.position.y - meter_top - 12.0 * s))
	var meter := Rect2(vp.x - 370.0 * s - 16.0 * s, meter_top, 370.0 * s, meter_h)

	# Three large live resource instruments form the lower backbone. The arithmetic
	# deliberately reserves exact room for a fifth 92px rune at 1080p (76px at 720).
	var gauge_sz := Vector2(560.0 * s, maxf(76.0, 114.0 * s))
	var bar_sz := Vector2(520.0 * s, maxf(44.0, 62.0 * s))
	var rail_gap := 35.0 * s
	var cluster_w := bar_sz.x * 2.0 + gauge_sz.x + rail_gap * 2.0
	var cluster_x := vp.x * 0.5 - cluster_w * 0.5
	var rail_y := answer.end.y + 26.0 * s
	var wind := Rect2(vp.x * 0.5 - gauge_sz.x * 0.5, answer.end.y + 2.0 * s,
		gauge_sz.x, gauge_sz.y)
	var health := Rect2(cluster_x, rail_y, bar_sz.x, bar_sz.y)
	var flow := Rect2(cluster_x + bar_sz.x + rail_gap + gauge_sz.x + rail_gap,
		rail_y, bar_sz.x, bar_sz.y)
	var ability_sz := Vector2(maxf(434.0, 534.0 * s), maxf(94.0, 110.0 * s))
	var abilities := Rect2(vp.x * 0.5 - ability_sz.x * 0.5,
		vp.y - hint_h - ability_sz.y, ability_sz.x, ability_sz.y)
	return {
		"status": Rect2(0, 0, vp.x, status_h),
		"theater": theater,
		"answer": answer,
		"dash": Rect2(0, answer.end.y, vp.x, dash_h),
		"hint": Rect2(0, vp.y - hint_h, vp.x, hint_h),
		"party": party,
		"party_gap": row_gap,
		"boss_shell": boss_shell,
		"boss_cast": boss_cast,
		"utility": utility,
		"meter": meter,
		"health": health,
		"wind": wind,
		"flow": flow,
		"abilities": abilities,
		"cluster_w": cluster_w,
		"scale": s,
		"floor_px": theater.position.y + theater.size.y * 0.80,
		"stage_scale": clampf(theater.size.y / 490.0, 0.65, 1.0),
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
			# Discover the live rail rather than naming today's four verbs. A future
			# fifth AbilityRune inherits the same painted slot without host surgery.
			for rn in _ability_runes():
				rn.v2_skin = _skin
		if band.hp_orb != null:               # horizontal safety bars (§2.3.1 E)
			band.hp_orb.v2_bar = _skin
		if band.res_orb != null:
			band.res_orb.v2_bar = _skin
			band.res_orb.v2_pct = true
			# C6C anchor verdict: keep the Flow read clean; no fixed diamond/threshold
			# marker. The percentage and all underlying aggro truth remain live.
			band.res_orb.v2_lock = -1.0

func _ready() -> void:
	# the host paints the graybox panels UNDER the band widgets it re-places —
	# band.build() already attached them to _shake_root before we were added
	get_parent().move_child(self, 0)
	resized.connect(_relayout_all)
	_relayout_all()
	call_deferred("_late_adopt")   # frames/meter/aggro/stage build after make_dash

## The Duelist owns one semantic spacer inside its HBox; every other child that is
## an AbilityRune is a real current/future verb. Keeping this discovery local makes
## the C6C dock genuinely 4–5-slot modular without changing DuelistBand's API.
func _ability_runes() -> Array[AbilityRune]:
	var out: Array[AbilityRune] = []
	if band == null or band.get("dodge_rune") == null:
		return out
	var row: Node = band.dodge_rune.get_parent()
	if row == null:
		return out
	for child in row.get_children():
		if child is AbilityRune:
			out.append(child as AbilityRune)
	return out

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
	var party: Rect2 = _r["party"]
	var boss_shell: Rect2 = _r["boss_shell"]
	var boss_cast: Rect2 = _r["boss_cast"]
	var utility: Rect2 = _r["utility"]
	var meter: Rect2 = _r["meter"]
	var health: Rect2 = _r["health"]
	var wind: Rect2 = _r["wind"]
	var flow: Rect2 = _r["flow"]
	var abilities: Rect2 = _r["abilities"]
	var s: float = _r["scale"]
	# --- independent upper islands (party deliberately overlaps only the safe west
	#     edge of the theater, matching the approved anchor) ---
	if _skin != null:
		# The shell stays at its authored 720:126 aspect; the live BossBar occupies
		# the recessed window and the live cast bar joins beneath it.
		var win := DashSkin.uniform_opening(boss_shell, DashSkin.OPEN_BOSS)
		UiKit.place(hud._bar, 0, 0, 0, 0, win.position.x + 4.0, win.position.y - 4.0,
			win.end.x - 4.0, win.end.y - 3.0)
		UiKit.place(hud._castbar, 0, 0, 0, 0, boss_cast.position.x, boss_cast.position.y,
			boss_cast.end.x, boss_cast.end.y)
	else:
		var bw := minf(560.0, vp.x * 0.36)
		UiKit.place(hud._bar, 0.5, 0, 0.5, 0, -bw * 0.5, status.size.y * 0.16, bw * 0.5, status.size.y * 0.52)
		UiKit.place(hud._castbar, 0.5, 0, 0.5, 0, -bw * 0.42, status.size.y * 0.56, bw * 0.42, status.size.y * 0.88)
	if hud._aggro_warn != null:
		var warn_w := minf(720.0 * s, vp.x * 0.60)
		UiKit.place(hud._aggro_warn, 0.5, 0, 0.5, 0, -warn_w * 0.5,
			boss_cast.end.y + 3.0 * s, warn_w * 0.5, boss_cast.end.y + maxf(22.0, 25.0 * s))
	if _party_grid != null:
		_party_grid.scale = Vector2.ONE * clampf(s, 0.67, 1.0)
		_party_grid.position = party.position
	if not _rows.is_empty():                # C6C: four substantial, readable painted rows
		var gap := float(_r["party_gap"])
		var row_h := (party.size.y - gap * 3.0) / 4.0
		for i in _rows.size():
			var pr: Control = _rows[i]
			pr.position = party.position + Vector2(0.0, float(i) * (row_h + gap))
			pr.size = Vector2(party.size.x, row_h)
	if _tab != null:                        # the collapsed utility tab, top-right
		_tab.position = utility.position
		_tab.size = utility.size
	if _meter_clip != null:
		if _tab != null:                    # expanded meter drops in UNDER the tab, rail-clipped
			UiKit.place(_meter_clip, 0, 0, 0, 0, meter.position.x, meter.position.y,
				meter.end.x, meter.end.y)
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
			_r["answer_frame"] = answer
			var op := _skin.sliced_opening("frame_answer", answer, DashSkin.CAPS_ANSWER, DashSkin.OPEN_ANSWER)
			UiKit.place(band.channel, 0, 0, 0, 0, op.position.x, op.position.y, op.end.x, op.end.y)
		else:
			UiKit.place(band.channel, 0, 0, 0, 0, answer.position.x, answer.position.y + 4.0,
				answer.end.x, answer.end.y - 4.0)
	# --- the connected dashboard cluster ---
	if band != null:
		if _skin != null:
			# Wind = the central primary read; the live Health and Flow/Aggro bars
			# flank it. Their authored resource shells now get room to read as art.
			if band.get("gauge") != null:
				UiKit.place(band.gauge, 0, 0, 0, 0, wind.position.x, wind.position.y,
					wind.end.x, wind.end.y)
			var vrow: Control = band.dodge_rune.get_parent() if band.get("dodge_rune") != null else null
			if vrow != null:
				UiKit.place(vrow, 0, 0, 0, 0, abilities.position.x, abilities.position.y,
					abilities.end.x, abilities.end.y)
				# At either scale the reserved dock fits exactly one future fifth rune:
				# 5×slot + the existing semantic spacer + all HBox gaps.
				var sep_px := lerpf(8.0, 12.0, clampf((s - 2.0 / 3.0) * 3.0, 0.0, 1.0))
				(vrow as HBoxContainer).add_theme_constant_override("separation", int(round(sep_px)))
				var rune_min := Vector2(maxf(76.0, 92.0 * s), maxf(94.0, 110.0 * s))
				for rn in _ability_runes():
					rn.custom_minimum_size = rune_min
			if band.hp_orb != null:
				UiKit.place(band.hp_orb, 0, 0, 0, 0, health.position.x, health.position.y,
					health.end.x, health.end.y)
			if band.res_orb != null:
				UiKit.place(band.res_orb, 0, 0, 0, 0, flow.position.x, flow.position.y,
					flow.end.x, flow.end.y)
		else:
			var dh := dash.size.y
			var cw: float = _r["cluster_w"]
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
	if hud._hint_lbl != null:           # the dream HUD is learned through the large icons/buttons
		hud._hint_lbl.visible = _skin == null and hint.size.y > 0.0
		if hud._hint_lbl.visible:
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
	if _skin == null:
		# The fallback remains an explicit graybox: full rails make missing art
		# obvious without ever producing a hole or a broken HUD.
		draw_rect(status, panel)
		draw_line(Vector2(0, status.end.y), Vector2(size.x, status.end.y), edge, 1.5)
		draw_rect(dash, panel)
		draw_line(Vector2(0, dash.position.y), Vector2(size.x, dash.position.y), edge, 1.5)
		if hint.size.y > 0.0:
			draw_rect(hint, Color(0.04, 0.05, 0.075, 0.9))
		draw_rect(answer.grow_individual(10, 4, 10, 4), Color(0.05, 0.06, 0.09, 0.62))
	else:
		# C6C: authored islands float over the scene instead of sitting on two
		# opaque footer/header slabs. Reuse the approved answer-frame caps as quiet
		# sliced backbones; this keeps the lower cluster painted (not gray rectangles)
		# while every value, fill, socket and button remains a separate live widget.
		var hp: Rect2 = _r["health"]
		var fl: Rect2 = _r["flow"]
		var ab: Rect2 = _r["abilities"]
		var rail := Rect2(hp.position - Vector2(12.0, 7.0),
			Vector2(fl.end.x - hp.position.x + 24.0, maxf(hp.size.y, fl.size.y) + 14.0))
		_skin.hshell(self, "frame_answer", rail, DashSkin.CAPS_ANSWER,
			Color(0.78, 0.86, 0.90, 0.62))
		var dock := ab.grow_individual(10.0, 5.0, 10.0, 4.0)
		_skin.hshell(self, "frame_answer", dock, DashSkin.CAPS_ANSWER,
			Color(0.72, 0.80, 0.84, 0.68))
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
	# fallback island backing (the painted rows carry their own authored bodies)
	if _party_grid != null:
		var pr := Rect2(_party_grid.position - Vector2(4, 4), _party_grid.size * _party_grid.scale + Vector2(8, 8))
		draw_rect(pr, Color(0.05, 0.06, 0.09, 0.5))
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
		"answer": Color(1.0, 0.85, 0.3), "dash": Color(1.0, 0.5, 0.7),
		"hint": Color(0.8, 0.6, 1.0), "party": Color(0.3, 0.9, 0.9),
		"boss_shell": Color(1.0, 0.35, 0.35), "boss_cast": Color(1.0, 0.55, 0.25),
		"utility": Color(0.7, 0.7, 1.0), "health": Color(0.95, 0.25, 0.35),
		"wind": Color(0.55, 0.85, 1.0), "flow": Color(0.35, 0.75, 1.0),
		"abilities": Color(1.0, 0.75, 0.25)}
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
