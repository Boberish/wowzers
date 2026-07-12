## screenshot_duelist_raid.gd — visual probe for THE DUELIST claim moment (tank-v3 juice pass).
## Drives DuelistPolicy on the real HUD and CATCHES the claim moments the pass added — a
## position-anchored graded verdict (+ death anim + gate pulse), a leak (crimson X + edge-flash),
## a feint puff, and a busy track (trails/glows must stay readable). It watches the live channel
## widget (AnswerChannel._deaths / _verdicts / bars) and snapshots a couple frames INTO each
## effect, and it forces a leak (an early parry) + a feint bait so the hard-to-roll shots land.
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_duelist_raid.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var phase := 0
var cur: Node = null
var pol: Policy = null
var last_tick := -1
var settle := 0
var pending: Dictionary = {}          ## {name, wait} — hold N frames so the effect renders, then save
var shots: Dictionary = {}            ## name -> saved path
var last_force := -999                ## throttle the forced-leak parry
var last_bait := -999                 ## throttle the forced feint bait
var frames := 0
var enriched := false
var dbg := {"purplemax": 0, "puff": 0, "read": 0, "baited": 0, "burst": 0}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _channel() -> Object:
	if cur == null:
		return null
	var band = cur.get("_band")
	if band == null:
		return null
	return band.get("channel")

## [nearest eta overall, nearest FEINT (purple) eta, any purple present]
func _scan_bars(ch: Object) -> Array:
	var fe := 9.0e9
	var fp := 9.0e9
	var any := false
	for b_v in ch.bars:
		var b: Dictionary = b_v
		var e := float(b.get("eta", 9.0e9))
		fe = minf(fe, e)
		if bool(b.get("purple", false)):
			any = true
			fp = minf(fp, e)
	return [fe, fp, any]

## is there a fresh (just-spawned) claim effect of this death-shape on the channel?
func _fresh_death(ch: Object, shape: String) -> bool:
	for e_v in ch._deaths:
		var e: Dictionary = e_v
		if String(e["shape"]) == shape and float(e["t"]) < 0.18:
			return true
	return false

## is there a fresh graded verdict whose word matches any of these?
func _fresh_verdict(ch: Object, words: Array) -> bool:
	for e_v in ch._verdicts:
		var e: Dictionary = e_v
		if float(e["t"]) < 0.18 and words.has(String(e["txt"])):
			return true
	return false

func _cap(name: String) -> void:
	if shots.has(name) or not pending.is_empty():
		return
	pending = {"name": name, "wait": 2}

func _save(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	shots[name] = path
	print("  shot[", name, "]: ", path)

func _all_core() -> bool:
	return shots.has("claim_good") and shots.has("miss") and shots.has("feint") and shots.has("busy")

func _drive(ctrl: Object, forced) -> void:
	if ctrl == null or ctrl.state == null or ctrl.state.over:
		return
	if ctrl.state.tick == last_tick:
		return
	last_tick = ctrl.state.tick
	if forced != null:
		ctrl.human(forced)
		return
	var seat: Seat = ctrl.player() if ctrl.has_method("player") else ctrl.state.seats[0]
	if pol != null and seat != null and seat.alive():
		var a: Dictionary = pol.act(CombatCore.observe(ctrl.state, seat))
		if not a.is_empty():
			ctrl.human(a)

func _process(_d: float) -> bool:
	frames += 1
	if frames > 20000:
		print("DUELIST CLAIM TOUR TIMEOUT -> ", out_dir)
		return true
	match phase:
		0:  # instantiate the raid HUD scene
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:  # launch the tank/duelist fight + build the driving policy
			cur.call("_launch", "tank", "duelist")
			pol = DuelistPolicy.new()
			pol.latency_ticks = 2
			pol.rng = DetRng.new(9137)
			last_tick = -1
			settle = 0
			phase = 2
		2:  # let the HUD _ready + first frames settle
			settle += 1
			if settle > 8:
				phase = 3
		3:  # the capture loop
			# a pending shot renders for a couple frames, then saves
			if not pending.is_empty():
				pending["wait"] = int(pending["wait"]) - 1
				if int(pending["wait"]) <= 0:
					_save(String(pending["name"]))
					pending = {}
				return false
			var ctrl = cur.get("_ctrl")
			if ctrl == null or ctrl.state == null:
				return false
			var st = ctrl.state
			# PROBE-ONLY: enrich the LIVE encounter's melee texture so the tank's stream shows the
			# whole vocabulary (the raid Seals emit only autos+heavies — feints/flurries/eats/lates
			# live in the practice bosses the raid factory can't launch). Runtime tweak, no file
			# touched; it just lets these shots prove the feint/late claim language on the real HUD.
			if not enriched and st.encounter != null and st.encounter.melee is Dictionary:
				st.encounter.melee["feint_odds"] = 0.24
				st.encounter.melee["flurry_odds"] = 0.08
				st.encounter.melee["eat_odds"] = 0.05
				st.encounter.melee["late_odds"] = 0.12
				enriched = true
			if st.over:
				phase = 4
				return false
			var ch := _channel()
			# decide a forced input this tick. Prioritise BAITING a feint (dodge it when it is the
			# strictly-nearest claimable bar) so the feint puff lands; only force the leak (early
			# parry) once feint+busy are captured so its damage never ends the run early.
			var forced = null
			if ch != null and st.tick > 150:
				var sb := _scan_bars(ch)
				var fe: float = sb[0]       # nearest overall
				var fp: float = sb[1]       # nearest feint
				if not shots.has("feint") and fp >= 0.18 and fp <= 0.55 \
						and fp <= fe + 0.05 and st.tick - last_bait >= 10:
					forced = {"type": "dodge"}     # press the nearest feint -> BAITED puff
					last_bait = st.tick
				elif shots.has("feint") and shots.has("busy") and not shots.has("miss") \
						and fe >= 0.30 and fe <= 0.60 and st.tick - last_force >= 24:
					forced = {"type": "defense"}   # an early parry -> a leak (crimson X)
					last_force = st.tick
			_drive(ctrl, forced)
			# inspect the live channel and snapshot fresh effects (scan, not just newest)
			if ch != null:
				var np := 0
				for b_v in ch.bars:
					if bool((b_v as Dictionary).get("purple", false)):
						np += 1
				dbg["purplemax"] = maxi(int(dbg["purplemax"]), np)
				if _fresh_death(ch, "puff"): dbg["puff"] = int(dbg["puff"]) + 1
				if _fresh_death(ch, "burst"): dbg["burst"] = int(dbg["burst"]) + 1
				if _fresh_verdict(ch, ["READ"]): dbg["read"] = int(dbg["read"]) + 1
				if _fresh_verdict(ch, ["BAITED!"]): dbg["baited"] = int(dbg["baited"]) + 1
				if not shots.has("busy") and ch.bars.size() >= 3:
					_cap("busy")
				elif not shots.has("feint") and (_fresh_death(ch, "puff") \
						or _fresh_verdict(ch, ["READ", "BAITED!"])):
					_cap("feint")
				elif not shots.has("claim_good") and _fresh_verdict(ch, ["PERFECT", "BULLSEYE!", "PARRY!"]):
					_cap("claim_good")
				elif not shots.has("miss") and _fresh_death(ch, "burst"):
					_cap("miss")
				elif not shots.has("feint") and st.tick > 2200 and np > 0:
					_cap("feint")                  # fallback: at least show a feint comet on the track
			if _all_core() and not shots.has("overview") and pending.is_empty():
				_cap("overview")
			if shots.has("overview") or st.tick > 3200:
				phase = 4
		4:  # last-ditch overview + report
			if not shots.has("overview") and pending.is_empty():
				_cap("overview")
				return false
			if not pending.is_empty():
				pending["wait"] = int(pending["wait"]) - 1
				if int(pending["wait"]) <= 0:
					_save(String(pending["name"]))
					pending = {}
				return false
			print("DUELIST CLAIM TOUR DONE -> ", out_dir, "  (", shots.size(), " shots)")
			print("   DBG ", dbg)
			for k in shots:
				print("   ", k, " = ", shots[k])
			return true
	return false
