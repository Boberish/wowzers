## artv2_dash_states.gd — C6B state-matrix gate: every required dashboard state on
## one deterministic sheet, no fight needed (pure view widgets, hand-fed exactly the
## fields the band feeds them). Proves: all four comet shapes + the three purple
## feints (never a purple BRACE) + peeled/flurry status + answered/missed husks ·
## the claim moment · Wind bar + all combo states + fumbling · low HP + the 30%
## Flow lock · ability ready/cooldown/unaffordable · party rows (hots/debuff/dead/
## shield/cast/resource) · skinned castbar kick window · the collapsed utility tab.
## Run under WSLg (custom _draw ⇒ NOT --headless):
##   godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://sim/artv2_dash_states.gd -- --out=/abs/dir [--legacy]
## --legacy renders the same states with every V2 flag off (the A/B pair).
extends SceneTree

var out_dir := "user://shots_artv2"
var legacy := false
var frame := -1
var chan: AnswerChannel
var chan2: AnswerChannel

class FakeState:
	var tick := 100
class FakeCtrl:
	var state := FakeState.new()
class FakeHud:
	var _ctrl := FakeCtrl.new()

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
		elif a == "--legacy":
			legacy = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	var skin: DashSkin = null if legacy else DashSkin.make()
	if not legacy and skin == null:
		print("DASH STATES: FAIL — DashSkin.make() returned null (missing pieces)")
		quit(1)
		return
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	# --- [1] the channel, busy: every shape + status on one committed runway ---
	chan = AnswerChannel.new()
	if skin != null:
		chan.v2_skin = skin
		chan.v2_naked = true
	if skin != null:                       # the channel sits IN the frame's opening (host law)
		var opn := skin.sliced_opening("frame_answer", Rect2(40, 44, 1220, 222),
			DashSkin.CAPS_ANSWER, DashSkin.OPEN_ANSWER)
		UiKit.place(chan, 0, 0, 0, 0, opn.position.x, opn.position.y, opn.end.x, opn.end.y)
	else:
		UiKit.place(chan, 0, 0, 0, 0, 60, 60, 1240, 250)
	bg.add_child(chan)
	chan.horizon = 3.0
	chan.bars = [
		{"id": 1, "kind": "auto", "purple": false, "eta": 2.6, "answered": false},
		{"id": 2, "kind": "beat", "purple": true, "eta": 2.2, "answered": false},
		{"id": 3, "kind": "global", "purple": false, "eta": 1.8, "answered": false},
		{"id": 4, "kind": "global", "purple": true, "eta": 1.45, "answered": false},
		{"id": 5, "kind": "heavy", "purple": false, "eta": 1.1, "answered": false, "size": 2},
		{"id": 6, "kind": "buster", "purple": true, "eta": 0.8, "answered": false, "size": 3},
		{"id": 7, "kind": "eat", "purple": false, "eta": 0.55, "answered": false},
		{"id": 8, "kind": "auto", "purple": false, "eta": 0.3, "answered": true},
		{"id": 9, "kind": "beat", "purple": false, "eta": 1.6, "peeled": true, "victim": "MIRA", "answered": false},
	]
	if skin != null:                       # the painted frame around the naked channel
		var fra := FrameHost.new()
		fra.skin = skin
		UiKit.place(fra, 0, 0, 0, 0, 40, 44, 1260, 266)
		bg.add_child(fra)
		bg.move_child(fra, bg.get_children().find(chan))
		fra.size = Vector2(1220, 222)      # place-then-add sizing for the _draw shell
	# --- [2] flurry mode + the claim moment (resolve fires just before the shot) ---
	chan2 = AnswerChannel.new()
	if skin != null:
		chan2.v2_skin = skin
		chan2.v2_naked = true
	UiKit.place(chan2, 0, 0, 0, 0, 60, 300, 1240, 470)
	bg.add_child(chan2)
	chan2.horizon = 3.0
	chan2.flurry = true
	chan2.bars = [
		{"id": 21, "kind": "flurry", "purple": false, "eta": 1.2, "flurry_i": 0, "answered": false},
		{"id": 22, "kind": "flurry", "purple": false, "eta": 1.45, "flurry_i": 1, "answered": false},
		{"id": 23, "kind": "flurry", "purple": false, "eta": 1.7, "flurry_i": 2, "answered": false},
		{"id": 24, "kind": "auto", "purple": false, "eta": 0.12, "answered": false},
		{"id": 25, "kind": "heavy", "purple": false, "eta": 2.3, "answered": false},
	]
	# --- [3] Wind + combo bank states (0 · 3 · 5/full) + fumbling ---
	for i in 4:
		var g := DuelistGauge.new()
		g.v2_skin = skin
		g.wind = [10.0, 6.0, 2.0, 10.0][i]
		g.combo = [0, 3, 5, 2][i]
		g.fumbling = i == 3
		UiKit.place(g, 0, 0, 0, 0, 1300 + (i % 2) * 300, 60 + (i / 2) * 110, 1580 + (i % 2) * 300, 160 + (i / 2) * 110)
		bg.add_child(g)
	# --- [4] HP low + Flow with the code-drawn 30% lock ---
	var hp := LiquidOrb.new()
	hp.fill = Palette.BLOOD
	hp.caption = "HEALTH"
	hp.set_values(19.0, 100.0)
	var fl := LiquidOrb.new()
	fl.fill = Palette.STEEL
	fl.caption = "FLOW / AGGRO"
	fl.set_values(24.0, 100.0)
	if skin != null:
		hp.v2_bar = skin
		fl.v2_bar = skin
		fl.v2_pct = true
		fl.v2_lock = 0.30
	UiKit.place(hp, 0, 0, 0, 0, 1300, 290, 1600, 324)
	UiKit.place(fl, 0, 0, 0, 0, 1300, 334, 1600, 368)
	bg.add_child(hp)
	bg.add_child(fl)
	# --- [5] ability slots: ready · cooldown · out-of-resource · En Garde live ---
	var rowbox := HBoxContainer.new()
	rowbox.add_theme_constant_override("separation", 12)
	UiKit.place(rowbox, 0, 0, 0, 0, 1300, 390, 1780, 480)
	bg.add_child(rowbox)
	var labels := ["Dodge", "Parry", "Dump", "En Garde"]
	var icons := ["dodge", "guard", "avalanche", "shockwave"]
	for i in 4:
		var rn := AbilityRune.new()
		rn.v2_skin = skin
		rn.label = labels[i]
		rn.key_num = i + 1
		rn.icon_id = icons[i]
		rn.accent = [Palette.FLOW, Palette.STEEL, Palette.GOLD_BRIGHT, Palette.CRIMSON][i]
		rn.cd_frac = 0.62 if i == 1 else 0.0
		rn.usable = i != 1
		rn.affordable = i != 2
		rowbox.add_child(rn)
	# --- [6] party rows: healthy+HoTs · bloodied+debuff · shielded+cast+resource · dead ---
	for i in 4:
		var fr := RaidFrame.new()
		fr.variant = "raid"
		fr.unit_name = ["YOU", "SERA", "KORVO", "MIRA"][i]
		fr.role = ["tank", "healer", "dps", "dps"][i]
		fr.is_you = i == 0
		fr.frac = [0.94, 0.31, 0.62, 0.0][i]
		fr.hp = [188, 46, 93, 0][i]
		fr.maxhp = [200, 150, 150, 150][i]
		fr.dead = i == 3
		fr.bloodied = i == 1
		fr.has_debuff = i == 1
		fr.debuff_remain = 3.2
		fr.absorb_frac = 0.22 if i == 2 else 0.0
		fr.absorb_val = 33.0 if i == 2 else 0.0
		if i == 0:
			fr.hots_rich = [{"icon": "renew", "remain": 5.0, "total": 9.0, "src": "renew"},
				{"icon": "growth", "remain": 7.0, "total": 9.0, "src": "growth", "count": 3}]
		var seat := Seat.new()
		seat.resource = [80.0, 40.0, 65.0, 0.0][i]
		seat.resource_max = 100.0
		if i == 2:
			seat.casting = {"start_tick": 70, "dur_ticks": 60}
		if legacy:
			fr.position = Vector2(60, 520 + i * 112)
			fr.size = Vector2(320, 102)
			bg.add_child(fr)
		else:
			var row := DashPartyRow.new()
			row.setup(FakeHud.new(), seat, fr, skin)
			row.position = Vector2(60, 520 + i * 40)
			row.size = Vector2(340, 34)
			bg.add_child(row)
	# --- [7] the skinned castbar, kick window open ---
	var cb := BossCastBar.new()
	cb.v2_skin = skin
	cb.active = true
	cb.boss_name = "Mistral"
	cb.cast_name = "Verse of Static"
	cb.kind = "kick"
	cb.frac = 0.72
	cb.remaining = 1.4
	cb.window = 0.6
	cb.in_zone = true
	cb.kickable_seat = true
	UiKit.place(cb, 0, 0, 0, 0, 480, 530, 940, 574)
	bg.add_child(cb)
	# --- [8] the collapsed utility tab, spark pre-fed ---
	if skin != null:
		var tab := DashHostC6A.DashUtilTab.new()
		tab.skin = skin
		tab._samples = [40.0, 90.0, 70.0, 120.0, 100.0, 160.0, 130.0, 90.0, 140.0, 180.0, 150.0, 170.0]
		tab.position = Vector2(480, 610)
		tab.size = Vector2(236, 60)
		bg.add_child(tab)
	print("DASH STATES: staged (%s)" % ("LEGACY" if legacy else "SKINNED"))

## A painted answer frame around a hand-placed naked channel (the host does this
## in play; the strip needs the same composition without a fight).
class FrameHost:
	extends Control
	var skin: DashSkin
	func _draw() -> void:
		skin.hshell(self, "frame_answer", Rect2(Vector2.ZERO, size), DashSkin.CAPS_ANSWER)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 25:
		# the claim moment on chan2: a graded verdict + press burst at the comet
		chan2.press_tick("dodge")
		chan2.resolve(24, "bullseye", "PERFECT!", "+12 ms")
		# and a miss husk on chan: the unpressed BRACE-neighbour crosses the line
		chan.missed(8)
	if frame == 32:
		var vp := root.get_visible_rect().size
		var name := "dash_states_%s_%dx%d" % ["legacy" if legacy else "skinned", int(vp.x), int(vp.y)]
		root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		print("  shot: ", out_dir.path_join(name + ".png"))
	if frame >= 36:
		print("DASH STATES DONE")
		quit(0)
	return false
