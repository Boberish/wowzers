## screenshot_draft.gd — boots the Draft 2.0 screen for every class in a real window
## and saves PNGs (rarity frames, RESONANT mark, token plaque, REROLL/UPSELL, end-screen
## token line). Seeded + pity-forced so an Opus card is on the table in every shot.
## Run (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_draft.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var steps: Array = []
var idx := -1
var frames_left := 0
var phase := 0
var cur: Node = null

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = [
		{"name": "draft_bulwark", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); _stage(h); h._show_draft(), "wait": 25},
		{"name": "draft_mender", "scene": "res://game/mender_main.tscn",
			"setup": func(h): h._start_run("tidecaller"); _stage(h); h._show_draft(), "wait": 25},
		{"name": "draft_twinfang", "scene": "res://game/twinfang_main.tscn",
			"setup": func(h): h._start_run("tempo"); _stage(h); h._show_draft(), "wait": 25},
		{"name": "draft_voidcaller", "scene": "res://game/voidcaller_main.tscn",
			"setup": func(h): h._start_run("disruptor"); _stage(h); h._show_draft(), "wait": 25},
		{"name": "draft_bloomweaver", "scene": "res://game/bloomweaver_main.tscn",
			"setup": func(h): h._start_run("wildgrove"); _stage(h); h._show_draft(), "wait": 25},
		{"name": "end_tokens", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); _stage(h); h._show_end(true), "wait": 20},
		# Phase B slot-verbs: a draft with a LOCKED card, the modded spellbook
		# (YOUR GUARD assembled rules), and Twin Guard charge pips live in combat.
		{"name": "b_draft_locked", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); _stage(h); h._show_draft(); _lock_one(h), "wait": 25},
		{"name": "b_spellbook_guard", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); _modded(h); h._toggle_book(), "wait": 20},
		{"name": "b_charge_pips", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); _modded(h), "wait": 60},
		# Phase B port: assembled YOUR RHYTHM tooltip + Twin Void pips on the kick socket.
		{"name": "p_twinfang_tip", "scene": "res://game/twinfang_main.tscn",
			"setup": func(h): h._start_run("venomancer"); _modded_tf(h); h._show_guard_tip(), "wait": 30},
		{"name": "p_voidcaller_pips", "scene": "res://game/voidcaller_main.tscn",
			"setup": func(h): h._start_run("disruptor"); _modded_vc(h), "wait": 60},
	]

## Modded Rhythm build (Twin Step + triggers/payloads), fight rebuilt with it.
func _modded_tf(h) -> void:
	for id in ["tfTrigEvade", "tfTrigSpender", "tfPayLash", "tfPayEnergy", "tfPropTwinStep"]:
		h._run.boons[id] = true
	h._begin_fight()

## Modded Kick build (Twin Void + triggers/payloads), fight rebuilt with it.
func _modded_vc(h) -> void:
	for id in ["vcTrigClean", "vcTrigDeny", "vcPayVoid", "vcPayFocus", "vcPropTwinVoid"]:
		h._run.boons[id] = true
	h._begin_fight()

## Lock slot 1 on the live DraftScreen (the ◆ HELD banner + LOCKED button state).
func _lock_one(h) -> void:
	for c in h._ui.get_children():
		if c is DraftScreen:
			c._locked = [1]
			c._rebuild()

## A modded Guard build (2 triggers + 2 payloads + Twin Guard), fight rebuilt with it.
func _modded(h) -> void:
	for id in ["trigThird", "trigRead", "payReflect", "payHeal", "propCharge"]:
		h._run.boons[id] = true
	h._begin_fight()

## Reproducible + showcase state: seeded draft stream, Tokens to spend, a fresh mint
## line, and pity at the hard threshold (slot 2 is forced Opus).
func _stage(h) -> void:
	h._run.draft_rng = DetRng.new(42)
	h._run.tokens = 5
	h._run.pity_opus = Draft.OPUS_PITY_HARD
	h._minted = 2

func _process(_delta: float) -> bool:
	match phase:
		0:
			idx += 1
			if idx >= steps.size():
				print("DRAFT SHOTS DONE -> ", out_dir)
				return true
			if cur != null:
				cur.queue_free()
				cur = null
			var st: Dictionary = steps[idx]
			cur = (load(String(st["scene"])) as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			var st: Dictionary = steps[idx]
			if st.has("setup"):
				(st["setup"] as Callable).call(cur)
			frames_left = int(st["wait"])
			phase = 2
		2:
			frames_left -= 1
			if frames_left <= 0:
				phase = 3
		3:
			var st: Dictionary = steps[idx]
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(st["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
