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
	# party → compact 2×2 island (the REAL RaidFrames — _render_frames keeps
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
	# into the theater below the rail)
	_meter_clip = Control.new()
	_meter_clip.clip_contents = true
	add_child(_meter_clip)
	if hud._meter != null:
		hud._meter.get_parent().remove_child(hud._meter)
		_meter_clip.add_child(hud._meter)
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
	UiKit.place(hud._bar, 0.5, 0, 0.5, 0, -bw * 0.5, status.size.y * 0.16, bw * 0.5, status.size.y * 0.52)
	UiKit.place(hud._castbar, 0.5, 0, 0.5, 0, -bw * 0.42, status.size.y * 0.56, bw * 0.42, status.size.y * 0.88)
	if hud._aggro_warn != null:
		UiKit.place(hud._aggro_warn, 0.5, 0, 0.5, 0, -360, status.size.y * 0.88, 360, status.size.y + 2.0)
	if _party_grid != null:
		_party_grid.scale = Vector2.ONE * clampf(status.size.y / 220.0, 0.55, 0.75)
		_party_grid.position = Vector2(10, 8)
	if _meter_clip != null:
		UiKit.place(_meter_clip, 1, 0, 1, 0, -330, 6, -8, status.size.y - 6.0)
		if hud._meter != null:
			hud._meter.position = Vector2.ZERO
			hud._meter.size = _meter_clip.size
	# --- the dominant answer instrument (the SAME live widget, re-placed) ---
	if band != null and band.get("channel") != null:
		UiKit.place(band.channel, 0, 0, 0, 0, answer.position.x, answer.position.y + 4.0,
			answer.end.x, answer.end.y - 4.0)
	# --- the connected dashboard cluster ---
	if band != null:
		var dh := dash.size.y
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
	# island backings (party / meter) — kept inside the rail
	if _party_grid != null:
		var pr := Rect2(_party_grid.position - Vector2(4, 4), _party_grid.size * _party_grid.scale + Vector2(8, 8))
		draw_rect(pr.intersection(status), Color(0.05, 0.06, 0.09, 0.5))
	# the 30% AGGRO LOCK tick on the Flow orb (graybox: hairline + label)
	if band != null and band.res_orb != null:
		var o := band.res_orb
		var oy := o.position.y + o.size.y * 0.70   # 30% fill = 70% down the orb
		draw_line(Vector2(o.position.x - 6, oy), Vector2(o.position.x + o.size.x + 6, oy),
			Color(1.0, 0.62, 0.30, 0.85), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(o.position.x + o.size.x + 10, oy + 4),
			"30% LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.62, 0.30, 0.9))

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
