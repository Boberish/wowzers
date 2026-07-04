## One-off visual check: every DPS-medallion + rhythm-bar state side by side.
extends SceneTree
var n := 0
var _verdict_rb: RhythmBar
var _bloom_cc: CastChannel
func _initialize() -> void:
	var root_c := Control.new()
	root_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(root_c)
	var bg := ColorRect.new()
	bg.color = Palette.BG0
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_c.add_child(bg)

	var tf1 := TwinfangGauge.new()          # mid build
	tf1.aspect = "tempo"; tf1.combo = 3; tf1.flow = 2; tf1.flow_mult = 1.16; tf1.tier = 1
	var tf2 := TwinfangGauge.new()          # everything primed
	tf2.aspect = "tempo"; tf2.combo = 5; tf2.flow = 6; tf2.flow_mult = 1.48; tf2.tier = 3
	var tf3 := TwinfangGauge.new()          # venom cocktail ramping
	tf3.aspect = "venomancer"; tf3.combo = 4; tf3.flow = 3; tf3.flow_mult = 1.24
	tf3.venom = {"V": 3, "F": 2, "C": 1, "syn_ramp": 1.6, "syn_active": true}
	var vc1 := VoidcallerGauge.new()        # banked
	vc1.aspect = "disruptor"; vc1.backlash = 3
	var vc2 := VoidcallerGauge.new()        # primed
	vc2.aspect = "disruptor"; vc2.backlash = 5; vc2.next_instant = true
	var vc3 := VoidcallerGauge.new()        # locked + exposed
	vc3.aspect = "silencer"; vc3.silence_left = 3.4; vc3.boss_exposed = true; vc3.expose_amt = 0.5
	var gs: Array = [tf1, tf2, tf3, vc1, vc2, vc3]
	for i in gs.size():
		var g: Control = gs[i]
		g.position = Vector2(60 + 640 * float(i % 3), 120 + 320 * float(i / 3))
		g.size = Vector2(600, 130)
		root_c.add_child(g)
	# rhythm bar states: approaching / dead-centre green (plumb lit) / JUST past the green
	# (must read amber, NOT green — the bug fix) / held PERFECT verdict (off-centre → shows ms)
	var rb_since: Array = [15, 24, 31, 3]
	for i in 4:
		var rb := RhythmBar.new()
		rb.since = int(rb_since[i])
		rb.position = Vector2(60 + 900 * float(i % 2), 740 + 150 * float(i / 2))
		rb.size = Vector2(720, 100)
		root_c.add_child(rb)
		if i == 3:
			_verdict_rb = rb
	# blooming medallion: building garden / spendable + flourish / thornveil tally
	var vg1 := VerdanceGauge.new()
	vg1.aspect = "wildgrove"; vg1.verdance = 44.0; vg1.garden = 2
	var vg2 := VerdanceGauge.new()
	vg2.aspect = "wildgrove"; vg2.verdance = 86.0; vg2.garden = 4; vg2.flourish = true
	var vg3 := VerdanceGauge.new()
	vg3.aspect = "thornveil"; vg3.verdance = 100.0; vg3.thorns = 342
	var vgs: Array = [vg1, vg2, vg3]
	for i in vgs.size():
		var vg: Control = vgs[i]
		vg.position = Vector2(60 + 640 * float(i), 585)
		vg.size = Vector2(600, 130)
		root_c.add_child(vg)
	# healer cast channel: mid-channel, and the release bloom
	var cc1 := CastChannel.new()
	cc1.active = true; cc1.frac = 0.62; cc1.label = "Mend"; cc1.target = "Bront"; cc1.spell_id = "mend"
	cc1.position = Vector2(60, 1000)
	cc1.size = Vector2(480, 70)
	root_c.add_child(cc1)
	_bloom_cc = CastChannel.new()
	_bloom_cc.active = true; _bloom_cc.frac = 0.97; _bloom_cc.label = "Flash Heal"
	_bloom_cc.target = "Mira"; _bloom_cc.spell_id = "flash"
	_bloom_cc.position = Vector2(960, 1000)
	_bloom_cc.size = Vector2(480, 70)
	root_c.add_child(_bloom_cc)
func _process(_d: float) -> bool:
	n += 1
	if n == 26 and _bloom_cc != null:
		_bloom_cc.active = false               # the cast resolves -> release bloom
		_bloom_cc = null
	if n == 27 and _verdict_rb != null:
		_verdict_rb._prev_prog = 0.78          # pretend the press landed deep in the green
		_verdict_rb.show_result("perfect")
		_verdict_rb = null
	if n == 30:
		root.get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		print("saved")
		return true
	return false
