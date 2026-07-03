## screenshot_armory.gd — visual probe of the ARMORY layer: the YOUR SET paper doll
## on the descent map, the REFORGE draft with forge chips + doll, and the trinket-
## framed drop ceremony. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_armory.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var frames := 0
var hud: Node = null
var steps: Array = []

## a spread of real boon ids across all five slots / three rarities
const SET_BOONS := [
	{"id": "rampagePlus", "title": "Heavy Rampage", "rarity": "haiku", "tags": ["rampage"],
		"desc": "Rampage deals +45 damage."},
	{"id": "execute", "title": "Last Stand", "rarity": "sonnet", "tags": ["rage"],
		"desc": "Below 35% HP your damage is +35%."},
	{"id": "payRage", "title": "Ironheart", "rarity": "haiku", "tags": ["guard", "rage"],
		"desc": "Every proc grants 8 rage."},
	{"id": "propCharge", "title": "Twin Guard", "rarity": "opus", "tags": ["guard"],
		"desc": "Second guard charge; the spare returns after 6s."},
	{"id": "propSwift", "title": "Swiftguard", "rarity": "haiku", "tags": ["guard"],
		"desc": "Guard cooldown -20%."},
	{"id": "deepCounter", "title": "Deep Counter", "rarity": "haiku", "tags": ["parry", "counter"],
		"desc": "Each parry banks +2 Counter instead of 1."},
	{"id": "trigBeat", "title": "Perfect Footwork", "rarity": "sonnet", "tags": ["guard", "dodge"],
		"desc": "A PERFECT combo-beat dodge procs Guard payloads."},
]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = ["map_set", "draft_forge", "drop_trinket", "drop_compare", "set_modal"]

func _process(_d: float) -> bool:
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
		return false
	idx += 1
	if idx >= steps.size():
		print("ARMORY TOUR DONE -> ", out_dir)
		return true
	if hud == null:
		hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
		root.add_child(hud)
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()
		hud._taken_boons = SET_BOONS.duplicate()
		hud._map_gear = ["riftmaw_tooth", "cooling_paste"]
		hud._map_gear_charges = {"cooling_paste": 2}
	match String(steps[idx]):
		"map_set":        # the YOUR SET doll bottom-left of the descent map
			hud._show_map()
		"draft_forge":    # forge chips on the cards + the set beside the forge
			if hud._run != null:
				hud._run.tokens = 5
			hud._show_boon_draft(hud._show_map)
		"drop_trinket":   # "a TRINKET for your set" framing on the ceremony
			hud._show_drop("lechat_bell", true, hud._show_map)
		"drop_compare":   # ARMORY-UI: the drop beside the EQUIPPED trinket cards
			hud._show_drop("grace_period", false, hud._show_map)
		"set_modal":      # ARMORY-UI: the YOUR SET inspection modal over the map
			hud._show_map()
			hud._open_armor_modal()
	frames = 14
	return false
