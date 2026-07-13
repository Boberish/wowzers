## DashPartyRow — C6B: one painted party row (I3-B `party_row` shell) repainting the
## REAL RaidFrame's already-fed state. The frame stays alive as an invisible child
## covering this row (modulate α=0, mouse untouched) — `_render_frames` keeps feeding
## it, its hover/click targeting keeps working (the healer click-cast law), and this
## row is a pure second view of the same fields: NOTHING is re-derived from CombatState
## that the HUD doesn't already read per frame (seat resource/cast are the same pure
## view reads `_render_frames` makes on Seat). Openings, in shell order: portrait/role ·
## HP · class resource · thin cast/progress · three status/debuff sockets. All values,
## fills, names, countdowns: code-drawn (I3-B README law).
class_name DashPartyRow
extends Control

var hud                        ## RaidHud (state tick for the cast fraction; duck-typed)
var seat                       ## the Seat this row watches (resource / casting reads)
var fr: RaidFrame = null       ## the REAL frame — truth + mouse target, repainted here
var skin: DashSkin = null
var _pulse := 0.0

func setup(h, st, frame: RaidFrame, sk: DashSkin) -> void:
	hud = h
	seat = st
	fr = frame
	skin = sk
	mouse_filter = Control.MOUSE_FILTER_IGNORE       # the frame child owns the mouse
	fr.modulate = Color(1, 1, 1, 0.0)                # fed + clickable, painted by US
	fr.position = Vector2.ZERO
	add_child(fr)

func _process(delta: float) -> void:
	_pulse += delta * 5.0
	if fr != null:
		fr.size = size                               # hover/click rect tracks the row
	queue_redraw()

func _row_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)

func _open(frac: Array) -> Rect2:
	return skin.sliced_opening("party_row", _row_rect(), DashSkin.CAPS_ROW, frac)

func _draw() -> void:
	if fr == null or skin == null:
		return
	var rect := _row_rect()
	var dead := fr.dead
	# --- state edge BEHIND the shell (bloodied pulse / hovered-target gold) ---
	if fr.is_target:
		draw_rect(rect.grow(2.0), Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g,
			Palette.GOLD_BRIGHT.b, 0.35 + 0.25 * fr._hover_t))
	elif fr.bloodied and not dead:
		draw_rect(rect.grow(1.0), Color(Palette.CRIMSON.r, Palette.CRIMSON.g,
			Palette.CRIMSON.b, 0.22 + 0.16 * sin(_pulse)))
	skin.hshell(self, "party_row", rect, DashSkin.CAPS_ROW,
		Color(0.55, 0.55, 0.6, 1.0) if dead else Color.WHITE)
	# --- portrait: role gem + letter inside the painted ring ---
	var por := _open(DashSkin.ROW_PORTRAIT)
	var pc := por.get_center()
	var prr := minf(por.size.x, por.size.y) * 0.5
	draw_circle(pc, prr, Palette.BG0 if not dead else Palette.BG1)
	var rc := fr._role_color() if not dead else Palette.TEXT_DIM.darkened(0.3)
	draw_circle(pc, prr, Color(rc.r, rc.g, rc.b, 0.20))
	var letter := "D"
	match fr.role:
		"tank": letter = "T"
		"healer": letter = "H"
	UiKit.text_shadowed(self, UiKit.display(800), Vector2(pc.x - prr, pc.y + prr * 0.42),
		letter, HORIZONTAL_ALIGNMENT_CENTER, prr * 2.0, UiKit.SIZE["LABEL"],
		rc.lightened(0.25) if not dead else Palette.TEXT_DIM)
	if fr.glint and not dead:
		var gc := Palette.GOLD_BRIGHT
		gc.a = 0.55 + 0.35 * sin(_pulse * 3.2)
		draw_circle(Vector2(pc.x + prr * 0.72, pc.y - prr * 0.72), 2.4, gc)
	# --- HP (the wide upper opening): well · lag ghost · fill · absorb weave · name · % ---
	var hpo := _open(DashSkin.ROW_HP)
	draw_rect(hpo, Palette.BG0)
	if dead:
		UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(hpo.position.x, hpo.get_center().y + 4.0),
			"FALLEN", HORIZONTAL_ALIGNMENT_CENTER, hpo.size.x, UiKit.SIZE["MICRO"], Palette.LOSE)
	else:
		var frac := clampf(fr._disp_frac, 0.0, 1.0)
		var fw := hpo.size.x * frac
		if fr._lag_frac > frac + 0.001:
			draw_rect(Rect2(hpo.position.x + fw, hpo.position.y + 1.0,
				hpo.size.x * (fr._lag_frac - frac), hpo.size.y - 2.0), Color(0.95, 0.85, 0.8, 0.30))
		if fw > 1.0:
			var hpc := fr._hp_color()
			UiKit.grad_rect(self, Rect2(hpo.position, Vector2(fw, hpo.size.y)),
				hpc.lightened(0.12), hpc.darkened(0.24))
			if frac < 0.995:
				draw_rect(Rect2(hpo.position.x + fw - 1.2, hpo.position.y, 1.2, hpo.size.y),
					hpc.lightened(0.45))
		if fr.absorb_frac > 0.0:                     # the woven-gold ward extension
			var aw := minf(hpo.size.x * fr.absorb_frac, hpo.size.x - fw)
			if aw > 0.5:
				var sh := 0.72 + 0.22 * (0.5 + 0.5 * sin(_pulse * 1.6))
				draw_rect(Rect2(hpo.position.x + fw, hpo.position.y + 0.5, aw, hpo.size.y - 1.0),
					Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.42 * sh))
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(hpo.position.x + 4.0, hpo.get_center().y + 4.0),
			fr.unit_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, hpo.size.x * 0.62,
			UiKit.SIZE["MICRO"], Palette.GOLD_BRIGHT if fr.is_you else Palette.TEXT)
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(hpo.position.x, hpo.get_center().y + 4.0),
			str(int(round(fr._disp_frac * 100.0))) + "%", HORIZONTAL_ALIGNMENT_RIGHT,
			hpo.size.x - 4.0, UiKit.SIZE["MICRO"], fr._hp_color().lightened(0.25))
	# --- class resource (the second opening): the seat's live resource pool ---
	var reo := _open(DashSkin.ROW_RESOURCE)
	draw_rect(reo, Palette.BG0)
	if not dead and seat != null and float(seat.resource_max) > 0.0:
		var rfrac := clampf(float(seat.resource) / float(seat.resource_max), 0.0, 1.0)
		if rfrac > 0.01:
			var rcol := Palette.STEEL.lightened(0.15)
			UiKit.grad_rect(self, Rect2(reo.position, Vector2(reo.size.x * rfrac, reo.size.y)),
				rcol.lightened(0.2), rcol.darkened(0.25))
	# --- cast/progress (the thin third opening): the seat's cast-in-flight ---
	var cao := _open(DashSkin.ROW_CAST)
	draw_rect(cao, Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.8))
	if not dead and seat != null and not seat.casting.is_empty() \
			and hud != null and hud._ctrl != null and hud._ctrl.state != null:
		var st0 := int(seat.casting.get("start_tick", 0))
		var dur := maxi(int(seat.casting.get("dur_ticks", 1)), 1)
		var cf := clampf(float(hud._ctrl.state.tick - st0) / float(dur), 0.0, 1.0)
		draw_rect(Rect2(cao.position, Vector2(cao.size.x * cf, cao.size.y)), Palette.GOLD_BRIGHT)
	# --- the three status/debuff sockets: ⚠ dispellable seal · HoT chips w/ sweeps ---
	var hots: Array = fr.hots_rich
	var hi := 0
	for si in DashSkin.ROW_SOCKETS.size():
		var so := _open(DashSkin.ROW_SOCKETS[si])
		var sc := so.get_center()
		var sr := minf(so.size.x, so.size.y) * 0.5
		if dead:
			continue
		if si == 0:
			if fr.has_debuff:                        # the crimson wax seal + countdown
				var sa := 0.55 + 0.40 * sin(_pulse)
				draw_circle(sc, sr * 0.9, Color(Palette.CRIMSON_DEEP.r, Palette.CRIMSON_DEEP.g, Palette.CRIMSON_DEEP.b, 0.95))
				draw_circle(sc, sr * 0.62, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, sa))
				if fr.debuff_remain >= 0.0 and fr._deb_total > 0.05:
					draw_arc(sc, sr * 0.98, -PI * 0.5,
						-PI * 0.5 + TAU * clampf(fr.debuff_remain / fr._deb_total, 0.0, 1.0),
						20, Palette.CRIMSON.lightened(0.25), 1.6, true)
			continue
		if hi < hots.size():                         # HoT chip: icon + countdown sweep
			var hd: Dictionary = hots[hi]
			hi += 1
			var accent := Palette.WIN
			if fr.ripe and String(hd.get("src", "")) == "growth":
				accent = Palette.GOLD_BRIGHT
			var tex := RuneIcons.tex(String(hd.get("icon", "")))
			if tex != null:
				draw_texture_rect(tex, Rect2(sc.x - sr * 0.78, sc.y - sr * 0.78, sr * 1.56, sr * 1.56),
					false, accent)
			else:
				UiKit.gilded_pip(self, sc, sr * 0.4, true, accent)
			var total := maxf(float(hd.get("total", 0.0)), 0.05)
			draw_arc(sc, sr * 0.98, -PI * 0.5,
				-PI * 0.5 + TAU * clampf(float(hd.get("remain", 0.0)) / total, 0.0, 1.0),
				20, accent, 1.6, true)
			var cnt := int(hd.get("count", 1))
			if cnt > 1:
				UiKit.text_shadowed(self, UiKit.display(800), Vector2(sc.x - sr, sc.y + sr * 0.5),
					"×%d" % cnt, HORIZONTAL_ALIGNMENT_CENTER, sr * 2.0, UiKit.SIZE["MICRO"], accent)
	# --- SKIN film rim (Well/DRAW) — the water-blue protection read, kept ---
	if fr.skinned and not dead:
		var fc := Palette.WATER
		fc.a = 0.30 + 0.16 * sin(_pulse * 1.8)
		draw_rect(Rect2(1.0, 1.0, size.x - 2.0, size.y - 2.0), fc, false, 1.2)
	# flash overlay (heals/hits ping the row exactly like the card)
	if fr._flash_a > 0.0:
		draw_rect(rect, Color(fr._flash_col.r, fr._flash_col.g, fr._flash_col.b, fr._flash_a * 0.7))
