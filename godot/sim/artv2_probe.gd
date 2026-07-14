## Probe for the ART V2 selector (GRAPHICS-PLAN Packet C1): the three independent
## view-only toggles + THE FAIL-SAFE LAW. Locks: defaults OFF · the --artv2=
## grammar (unknown tokens ignored) · OFF ⇒ the exact legacy factory classes ·
## flags ON with NO V2 assets ⇒ still the legacy graphics (never a null actor,
## never a blank stage, never a dead dashboard) · dash host absent until C6.
##   godot --headless --path godot --script res://sim/artv2_probe.gd
extends SceneTree
func _initialize() -> void:
	var fails: Array = []

	# [1] defaults: everything OFF — the old graphics are the release default
	_chk(fails, "default actors OFF", ArtV2.actors == false)
	_chk(fails, "default scene legacy", ArtV2.scene == "")
	_chk(fails, "default dash OFF", ArtV2.dash == false)

	# [2] OFF-purity: the factory returns the exact legacy classes per id
	# (duelist/alchemist/well → RiftmawRig2D is the live post-purge fallthrough
	# wart — locked AS-IS here; C4's adapter registration owns fixing the map)
	_legacy_chk(fails, "OFF")

	# [3] the boot grammar: any subset, any order, unknown tokens ignored
	ArtV2.boot(PackedStringArray(["--fightlen=2", "--artv2=dash, scene:v2_interior_test ,actors,typo"]))
	_chk(fails, "boot parses actors", ArtV2.actors == true)
	_chk(fails, "boot parses scene id", ArtV2.scene == "v2_interior_test")
	_chk(fails, "boot parses dash", ArtV2.dash == true)
	ArtV2.actors = false; ArtV2.scene = ""; ArtV2.dash = false
	ArtV2.boot(PackedStringArray(["--autostart=raid"]))   # no --artv2 ⇒ untouched
	_chk(fails, "no-arg boot stays OFF", not ArtV2.actors and ArtV2.scene == "" and not ArtV2.dash)

	# [4] FAIL-SAFE: flags ON but no V2 asset exists anywhere yet ⇒ legacy paths
	ArtV2.actors = true
	ArtV2.scene = "no_such_profile"
	ArtV2.dash = true
	var ma := ArtV2.make_actor("zzz_no_such_class")
	_chk(fails, "actor adapter: missing asset ⇒ null (fall through)", ma == null)
	_legacy_chk(fails, "ON")   # undelivered ids stay puppets; delivered ids go painted
	var st := ArtV2.make_scene()
	_chk(fails, "scene: unknown profile ⇒ legacy StageBackdrop", st is StageBackdrop)
	_chk(fails, "scene: legacy keeps the combat variant", st is StageBackdrop and (st as StageBackdrop).combat)
	st.free()
	_chk(fails, "dash: no C6 host ⇒ null (current widgets+band build)", ArtV2.make_dash(null) == null)
	ArtV2.scene = ""
	var st2 := ArtV2.make_scene()
	_chk(fails, "scene: '' ⇒ legacy StageBackdrop", st2 is StageBackdrop)
	st2.free()
	ArtV2.actors = false
	ArtV2.dash = false

	# [5] SceneKit (C2): the six-layer host + profile table — absence returns legacy
	var sk_legacy := SceneKit.make("")
	_chk(fails, "SceneKit '' => StageBackdrop combat", sk_legacy is StageBackdrop and (sk_legacy as StageBackdrop).combat)
	sk_legacy.free()
	var sk_menu := SceneKit.make("legacy", false)
	_chk(fails, "SceneKit 'legacy' keeps menu variant", sk_menu is StageBackdrop and not (sk_menu as StageBackdrop).combat)
	sk_menu.free()
	var sk_bogus := SceneKit.make("bogus_profile")
	_chk(fails, "SceneKit unknown => legacy", sk_bogus is StageBackdrop)
	sk_bogus.free()
	for pid in ["v2_interior_test", "v2_exterior_test"]:
		var host := SceneKit.make(String(pid))
		_chk(fails, "SceneKit %s => host" % pid, host is SceneKit and (host as SceneKit).profile_id == String(pid))
		host.free()
		var prof: Dictionary = SceneKit.PROFILES[pid]
		for layer in ["backdrop", "distant", "midground", "floor", "dressing", "atmosphere"]:
			_chk(fails, "%s has %s layer" % [pid, layer], prof.has(layer))
	ArtV2.scene = "v2_exterior_test"
	var routed := ArtV2.make_scene()
	_chk(fails, "ArtV2.make_scene routes to SceneKit", routed is SceneKit)
	routed.free()
	ArtV2.scene = ""
	var routed2 := ArtV2.make_scene()
	_chk(fails, "ArtV2.make_scene default => legacy", routed2 is StageBackdrop)
	routed2.free()

	# [6] C3 asset bindings: the stack profiles are dir-bound, six layers each;
	# no Codex layer is delivered yet, so layer_tex = null everywhere and the
	# labeled-placeholder path IS the live path (missing-layer fail-safe).
	for pid in ["stack_atrium", "stack_cold_aisle"]:
		var prof: Dictionary = SceneKit.PROFILES.get(pid, {})
		_chk(fails, "%s registered" % pid, not prof.is_empty())
		_chk(fails, "%s dir-bound" % pid, String(prof.get("dir", "")).begins_with("res://game/art_v2/scenes/"))
		for layer in ["backdrop", "distant", "midground", "floor", "dressing", "atmosphere"]:
			_chk(fails, "%s has %s layer" % [pid, layer], prof.has(layer))
		for layer in SceneKit.LAYER_FILES:
			# delivery-agnostic: the resolver must agree with the filesystem —
			# delivered => a real Texture2D, pending => null (the labeled fallback)
			var want := ResourceLoader.exists("%s/%s.png" % [String(prof["dir"]), layer], "Texture2D")
			var got := SceneKit.layer_tex(prof, String(layer))
			_chk(fails, "%s %s resolver matches delivery(%s)" % [pid, layer, want],
				(got != null) == want)
		var host := SceneKit.make(String(pid))
		_chk(fails, "%s => SceneKit host" % pid, host is SceneKit)
		host.free()
	_chk(fails, "undirred profile never resolves tex",
		SceneKit.layer_tex(SceneKit.PROFILES["v2_interior_test"], "backdrop") == null)

	# [7] C4 painted-actor adapter: metadata contract + fallback proof
	var dj := FileAccess.file_exists("res://game/art_v2/actors/duelist/actor.json")
	var pa := PaintedActor2D.try_make("duelist")
	_chk(fails, "try_make duelist matches delivery(%s)" % dj, (pa != null) == dj)
	if pa != null:
		_chk(fails, "adapter built parts", not pa._parts.is_empty())
		_chk(fails, "adapter has a deform part", not pa._deforms.is_empty())
		_chk(fails, "adapter resolved replacement frames", pa._frames.has("windup_heavy"))
		pa.free()
	_chk(fails, "try_make absent id => null (legacy fallback)", PaintedActor2D.try_make("zzz_no_such_class") == null)
	var pa2 := PaintedActor2D.try_make("duelist", "warden")   # unknown aspect variant falls back to the base folder
	_chk(fails, "aspect variant falls back to base", (pa2 != null) == dj)
	if pa2 != null:
		pa2.free()
	ArtV2.actors = false
	_chk(fails, "flag OFF: make_actor null even when delivered", ArtV2.make_actor("duelist") == null)

	# [8] C6A: the ONE layout contract + dash-host gating (view-only laws)
	for vp in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		var L := DashHostC6A.layout(vp)
		var rs: Rect2 = L["status"]
		var rt: Rect2 = L["theater"]
		var ra: Rect2 = L["answer"]
		var rd: Rect2 = L["dash"]
		var rh: Rect2 = L["hint"]
		_chk(fails, "%s bands tile the height" % vp,
			absf(rs.size.y + rt.size.y + ra.size.y + rd.size.y + rh.size.y - vp.y) < 1.5)
		_chk(fails, "%s theater clear of persistent UI" % vp,
			not rt.intersects(rs) and not rt.intersects(ra) and not rt.intersects(rd))
		_chk(fails, "%s answer readable (>=150px tall, >=800 wide)" % vp,
			ra.size.y >= 150.0 and ra.size.x >= 800.0)
		_chk(fails, "%s theater positive" % vp, rt.size.y > 200.0)
		_chk(fails, "%s stage_scale sane" % vp,
			float(L["stage_scale"]) >= 0.65 and float(L["stage_scale"]) <= 1.0)
		var bounds := Rect2(Vector2.ZERO, vp)
		for key in ["party", "boss_shell", "boss_cast", "utility", "answer",
				"health", "wind", "flow", "abilities"]:
			_chk(fails, "%s C6C %s stays on canvas" % [vp, key],
				bounds.encloses(L[key] as Rect2))
		var rp: Rect2 = L["party"]
		var rb: Rect2 = L["boss_shell"]
		var rbc: Rect2 = L["boss_cast"]
		var ru: Rect2 = L["utility"]
		var rhp: Rect2 = L["health"]
		var rw: Rect2 = L["wind"]
		var rf: Rect2 = L["flow"]
		var rab: Rect2 = L["abilities"]
		_chk(fails, "%s C6C four-row party island is substantial" % vp,
			rp.size.y >= 320.0 and rp.size.x >= 330.0)
		_chk(fails, "%s C6C upper islands stay mutually clear" % vp,
			not rp.intersects(rb) and not rp.intersects(rbc) and not rp.intersects(ru)
			and not rb.intersects(ru))
		_chk(fails, "%s C6C three resource instruments stay distinct" % vp,
			not rhp.intersects(rw) and not rw.intersects(rf) and not rhp.intersects(rf))
		_chk(fails, "%s C6C reaction stack has no overlap" % vp,
			not ra.intersects(rhp) and not ra.intersects(rw) and not ra.intersects(rf)
			and not rw.intersects(rab) and not rhp.intersects(rab) and not rf.intersects(rab))
		_chk(fails, "%s C6C ability dock reserves fifth-slot width" % vp, rab.size.x >= 434.0)
	_chk(fails, "720p collapses the hint gutter first",
		(DashHostC6A.layout(Vector2(1280, 720))["hint"] as Rect2).size.y == 0.0)
	_chk(fails, "ultrawide caps the answer width",
		(DashHostC6A.layout(Vector2(2560, 1080))["answer"] as Rect2).size.x <= 1240.0)
	_chk(fails, "ultrawide theater gains the side canvas",
		(DashHostC6A.layout(Vector2(2560, 1080))["theater"] as Rect2).size.x == 2560.0)
	ArtV2.dash = true
	_chk(fails, "make_dash: null hud => null (fallback)", ArtV2.make_dash(null) == null)
	ArtV2.dash = false

	# [9] C6B: the painted dashboard skin — asset registry · icon law · slice math ·
	# default-off widget flags (the fail-safe surface)
	var sk := DashSkin.make()
	_chk(fails, "C6B: DashSkin.make() finds all %d pieces" % DashSkin.PIECES.size(), sk != null)
	if sk != null:
		_chk(fails, "C6B: registry complete", sk.t.size() == DashSkin.PIECES.size())
		# THE ICON LAW: shape = the answer; purple only for the three pressables
		_chk(fails, "C6B icon: default/beat -> diamond", sk.icon("auto", false) == sk.t["icon_diamond"])
		_chk(fails, "C6B icon: global -> hexagon", sk.icon("global", false) == sk.t["icon_hexagon"])
		_chk(fails, "C6B icon: flurry -> hexagon", sk.icon("flurry", false) == sk.t["icon_hexagon"])
		_chk(fails, "C6B icon: heavy -> octagon", sk.icon("heavy", false) == sk.t["icon_octagon"])
		_chk(fails, "C6B icon: buster -> octagon", sk.icon("buster", false) == sk.t["icon_octagon"])
		_chk(fails, "C6B icon: eat -> BRACE disc", sk.icon("eat", false) == sk.t["icon_brace"])
		_chk(fails, "C6B icon: purple beat -> feint diamond", sk.icon("beat", true) == sk.t["icon_feint_diamond"])
		_chk(fails, "C6B icon: purple global -> feint hexagon", sk.icon("global", true) == sk.t["icon_feint_hexagon"])
		_chk(fails, "C6B icon: purple buster -> feint octagon", sk.icon("buster", true) == sk.t["icon_feint_octagon"])
		_chk(fails, "C6B icon LAW: a BRACE can NEVER be purple", sk.icon("eat", true) == sk.t["icon_brace"])
		# slice math: endpoints exact, openings stay inside the shell
		var rr := Rect2(100, 50, 500, 30)
		_chk(fails, "C6B slice_x endpoints",
			absf(DashSkin.slice_x(rr, DashSkin.CAPS_RESOURCE, 0.0, 800.0, 71.0) - rr.position.x) < 0.01
			and absf(DashSkin.slice_x(rr, DashSkin.CAPS_RESOURCE, 1.0, 800.0, 71.0) - rr.end.x) < 0.01)
		var op := sk.sliced_opening("shell_resource", rr, DashSkin.CAPS_RESOURCE, DashSkin.OPEN_RESOURCE)
		_chk(fails, "C6B opening inside its shell", rr.encloses(op) and op.size.x > 0.0 and op.size.y > 0.0)
		var prow := sk.sliced_opening("party_row", Rect2(0, 0, 320, 30), DashSkin.CAPS_ROW, DashSkin.ROW_HP)
		_chk(fails, "C6B party HP opening sane", prow.size.x > 150.0 and prow.size.y > 4.0)
		# C6C's dominant-read targets: the live size helper (not a second table)
		# produces 72–88px textures in the 1080 answer opening.
		var c6c_chan := AnswerChannel.new()
		c6c_chan.v2_skin = sk
		c6c_chan.size = Vector2(1160.0, 126.0)
		var light_h := c6c_chan._size_r("auto", AbilityRes.Size.LIGHT) * 2.6
		var heavy_h := c6c_chan._size_r("heavy", AbilityRes.Size.HEAVY) * 2.6
		var crush_h := c6c_chan._size_r("buster", AbilityRes.Size.CRUSH) * 2.6
		_chk(fails, "C6C answer icons hit 72–88px target",
			light_h >= 72.0 and heavy_h >= 80.0 and crush_h >= 88.0 and crush_h <= 89.0)
		c6c_chan.free()
	# default-off fail-safe: every C6B widget flag ships dark until the host sets it
	var ac := AnswerChannel.new()
	_chk(fails, "C6B default-off: channel unskinned", ac.v2_skin == null and not ac.v2_naked)
	ac.free()
	var lo := LiquidOrb.new()
	_chk(fails, "C6B default-off: orb stays an orb", lo.v2_bar == null and lo.v2_lock < 0.0)
	lo.free()
	var bb := BossBar.new()
	_chk(fails, "C6B default-off: boss plate keeps chrome", not bb.v2_naked)
	bb.free()
	var bcb := BossCastBar.new()
	_chk(fails, "C6B default-off: castbar keeps its plate", bcb.v2_skin == null)
	bcb.free()
	var ar := AbilityRune.new()
	_chk(fails, "C6B default-off: rune keeps its chamfer", ar.v2_skin == null)
	ar.free()
	var dg := DuelistGauge.new()
	_chk(fails, "C6B default-off: gauge unskinned", dg.v2_skin == null)
	dg.free()

	# [10] C7: the VFX flipbook runtime — book resolve · registration math · missing-
	# asset fallback · pool bounds · slot interruption · loop stop · default-off flag
	_chk(fails, "C7 default: vfx OFF", ArtV2.vfx == false)
	ArtV2.boot(PackedStringArray(["--artv2=vfx"]))
	_chk(fails, "C7 boot parses vfx", ArtV2.vfx == true)
	ArtV2.vfx = false
	var book := VfxBook.make()
	_chk(fails, "C7 book resolves (assets delivered)", book != null)
	if book != null:
		var want_frames := {"parry": 8, "dodge": 8, "dump": 8, "engarde_activate": 8,
			"engarde_hold": 4, "impact_light": 6, "impact_heavy": 8, "impact_crush": 8}
		for f in VfxBook.FAMILIES:
			_chk(fails, "C7 %s frames = %d (README contract)" % [f, want_frames[f]],
				book.frame_count(String(f)) == int(want_frames[f]))
			_chk(fails, "C7 %s atlas loaded" % f, book.tex.get(f) != null)
			# registration: every atlas rect inside its texture; every pivot inside its cell
			var rec: Dictionary = book.fam[f]
			var tex_sz: Vector2 = (book.tex[f] as Texture2D).get_size()
			var reg_ok := true
			for fr in (rec["frames"] as Array):
				var r: Array = (fr as Dictionary)["rect"]
				var pv: Array = (fr as Dictionary)["pivot"]
				var cell: Array = (fr as Dictionary)["cell"]
				if float(r[0]) + float(r[2]) > tex_sz.x + 0.5 or float(r[1]) + float(r[3]) > tex_sz.y + 0.5:
					reg_ok = false
				if float(pv[0]) < 0.0 or float(pv[0]) > float(cell[0]) \
						or float(pv[1]) < 0.0 or float(pv[1]) > float(cell[1]):
					reg_ok = false
			_chk(fails, "C7 %s registration sane (rects in atlas, pivot in cell)" % f, reg_ok)
		_chk(fails, "C7 only the hold loops", book.loops("engarde_hold")
			and not book.loops("parry") and not book.loops("impact_crush"))
		_chk(fails, "C7 frame() pivot math: offset = trim − pivot",
			_pivot_math_ok(book, "parry"))
	_chk(fails, "C7 book missing dir => null (fallback law)",
		VfxBook.make("res://game/art_v2/zzz_no_such_dir") == null)
	var pool := VfxPool.make()
	_chk(fails, "C7 pool resolves with delivered book", pool != null)
	if pool != null:
		# slot interruption: a same-slot spawn REUSES the voice (replace, never queue)
		var v1 := pool.spawn("parry", Vector2.ZERO, {}, "s0:act")
		var v2 := pool.spawn("dodge", Vector2.ZERO, {}, "s0:act")
		_chk(fails, "C7 same slot replaces (one voice)", v1 == v2 and v2.family == "dodge")
		# saturation: un-keyed spam stays bounded and never steals a named slot
		var eg := pool.spawn("engarde_hold", Vector2.ZERO, {}, "s0:eg")
		for i in 40:
			pool.spawn("impact_light", Vector2.ZERO, {})
		_chk(fails, "C7 pool bounded at %d voices" % VfxPool.MAX_VOICES,
			pool.live_count() <= VfxPool.MAX_VOICES
			and pool.get_child_count() == VfxPool.MAX_VOICES)
		_chk(fails, "C7 steal never takes a named slot", eg.busy() and eg.slot == "s0:eg"
			and eg.family == "engarde_hold")
		# one-shot lifecycle: ticks to the end, then the voice frees itself
		var vt := pool.spawn("impact_light", Vector2.ZERO, {}, "s9:test")
		for i in 40:
			vt.tick(0.016)
		_chk(fails, "C7 one-shot releases on finish", not vt.busy())
		# loop lifecycle: survives many ticks, stop() fades it out clean
		for i in 200:
			eg.tick(0.016)
		_chk(fails, "C7 hold loop persists", eg.busy())
		eg.stop()
		for i in 20:
			eg.tick(0.016)
		_chk(fails, "C7 stop() fades the loop out", not eg.busy())
		# teardown: clear() silences everything instantly (fight re-entry)
		pool.spawn("impact_crush", Vector2.ZERO, {}, "s0:act")
		pool.clear()
		_chk(fails, "C7 clear() silences the pool", pool.live_count() == 0)
		pool.free()

	for f in fails:
		print("  CHECK FAIL: %s" % f)
	print("ARTV2 PROBE: %s (%d checks)" % ["ALL OK" if fails.is_empty() else "FAIL", _n])
	quit(0 if fails.is_empty() else 1)

## frame(i).offset must equal trim − pivot for every frame (the registration law).
func _pivot_math_ok(book: VfxBook, f: String) -> bool:
	var frames: Array = (book.fam[f] as Dictionary)["frames"]
	for i in frames.size():
		var fr: Dictionary = frames[i]
		var got: Vector2 = book.frame(f, i)["offset"]
		var want := Vector2(float(fr["trim"][0]) - float(fr["pivot"][0]),
			float(fr["trim"][1]) - float(fr["pivot"][1]))
		if (got - want).length() > 0.01:
			return false
	return true

## The legacy factory contract, checked with the flags in a given state: every
## id must yield its current placeholder class (user art dir is empty in-repo).
func _legacy_chk(fails: Array, tag: String) -> void:
	var want := {"twinfang": "TwinfangRig2D", "voidcaller": "VoidcallerRig2D",
		"mender": "MenderRig2D", "duelist": "RiftmawRig2D", "riftmaw": "RiftmawRig2D"}
	for id in want:
		# C4, delivery-agnostic: with the actors flag ON and a painted folder
		# delivered, the id maps to the adapter; otherwise the legacy class.
		# Flags OFF ("OFF" tag) must ALWAYS be pure legacy — the release default.
		var expect := String(want[id])
		if ArtV2.actors and FileAccess.file_exists("res://game/art_v2/actors/%s/actor.json" % id):
			expect = "PaintedActor2D"
		var a := Actor2D.make(String(id), "")
		var ok := a != null and a.get_script() != null and String(a.get_script().get_global_name()) == expect
		_chk(fails, "%s factory %s -> %s" % [tag, id, expect], ok)
		if a != null:
			a.free()

var _n := 0
func _chk(fails: Array, name: String, ok: bool) -> void:
	_n += 1
	if not ok:
		fails.append(name)
