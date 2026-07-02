## TwinfangRig2D — the rogue as a side-view cutout puppet (~300px, built facing +X).
## A hooded twin-dagger duelist whose IDLE BOUNCES ON THE STRIKE RHYTHM (the breath
## frequency matches the Perfect window's beat), whose Flow tier lights the scarf,
## eye and blades, and whose kit is all body language: alternating dagger strikes
## (Perfects become an X-cross with a lunge), a literal boot for Kick, a leaping
## two-dagger plunge for Coup de Grâce, backdash evades, and a slump when the
## rhythm dies (flow_lost). Sign rule: arms/legs NEGATIVE rotation = swing forward.
class_name TwinfangRig2D
extends PoseRig2D

var accent := Color("7fe0a0")     # Tempo mint; Venomancer gets poison green

func _init(aspect: String = "tempo") -> void:
	accent = Color("7fd44a") if aspect == "venomancer" else Color("7fe0a0")

func _build() -> void:
	var leather := Color(0.315, 0.315, 0.395)
	var hoodc := Color(0.235, 0.235, 0.30)
	var pants := Color(0.275, 0.275, 0.345)
	var sash := Color("8a7429")
	var steel := Color(0.78, 0.80, 0.88)
	var skin := Color(0.42, 0.36, 0.33)

	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -118))
	# back leg (drawn first = behind)
	var leg_b := joint(hips, "leg_b", Vector2(-10, 6))
	limb(leg_b, "capsule", Vector2.ZERO, Vector2(-4, 54), 9, 7, pants)
	var shin_b := joint(leg_b, "shin_b", Vector2(-4, 54))
	limb(shin_b, "capsule", Vector2.ZERO, Vector2(2, 52), 6.5, 5, hoodc)
	limb(shin_b, "capsule", Vector2(2, 52), Vector2(16, 54), 5, 4.5, hoodc)   # foot
	# pelvis + sash
	limb(hips, "capsule", Vector2(0, 2), Vector2(2, 14), 12, 11, pants)
	limb(hips, "capsule", Vector2(-8, 2), Vector2(10, 4), 4, 4, sash)
	# chest pivots at the waist
	var chest := joint(hips, "chest", Vector2(1, -6))
	# scarf trails behind (drawn before torso)
	var scarf := joint(chest, "scarf", Vector2(-6, -44))
	limb(scarf, "capsule", Vector2.ZERO, Vector2(-26, 12), 6, 3, accent.darkened(0.2), "scarf")
	# back arm behind torso
	var arm_b := joint(chest, "arm_b", Vector2(-8, -40))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(4, 26), 7, 6, leather)
	var fore_b := joint(arm_b, "fore_b", Vector2(4, 26))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(8, 24), 5.5, 4.5, leather)
	var hand_b := joint(fore_b, "hand_b", Vector2(8, 24))
	limb(hand_b, "circle", Vector2.ZERO, Vector2.ZERO, 5, 5, skin)
	limb(hand_b, "blade", Vector2(3, 0), Vector2(30, -2), 3.2, 0, steel, "dagger_b")
	# torso + shoulder pad
	limb(chest, "capsule", Vector2(0, 4), Vector2(3, -46), 12, 13, leather)
	limb(chest, "circle", Vector2(0, -44), Vector2.ZERO, 9, 0, hoodc)
	# head + hood + eye
	var head := joint(chest, "head", Vector2(8, -52))
	limb(head, "circle", Vector2(0, -4), Vector2.ZERO, 13, 0, skin.darkened(0.35))
	poly(head, PackedVector2Array([Vector2(-18, 4), Vector2(-14, -14), Vector2(-2, -21),
		Vector2(11, -14), Vector2(14, 0), Vector2(8, 8), Vector2(-10, 9)]), hoodc)
	limb(head, "circle", Vector2(7, -4), Vector2.ZERO, 2.6, 0, accent, "eye")
	# front leg
	var leg_f := joint(hips, "leg_f", Vector2(11, 6))
	limb(leg_f, "capsule", Vector2.ZERO, Vector2(4, 54), 9.5, 7, pants)
	var shin_f := joint(leg_f, "shin_f", Vector2(4, 54))
	limb(shin_f, "capsule", Vector2.ZERO, Vector2(2, 52), 7, 5, hoodc)
	limb(shin_f, "capsule", Vector2(2, 52), Vector2(17, 54), 5, 4.5, hoodc)
	# front arm on top
	var arm_f := joint(chest, "arm_f", Vector2(6, -42))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(6, 27), 7.5, 6, leather)
	var fore_f := joint(arm_f, "fore_f", Vector2(6, 27))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(9, 24), 6, 4.5, leather)
	var hand_f := joint(fore_f, "hand_f", Vector2(9, 24))
	limb(hand_f, "circle", Vector2.ZERO, Vector2.ZERO, 5, 5, skin)
	limb(hand_f, "blade", Vector2(3, 0), Vector2(32, -2), 3.4, 0, steel, "dagger_f")

	# the rhythm made flesh: the idle bounce beats at the Perfect window's tempo
	# (green window centre ~0.78s -> ~8.1 rad/s)
	breath("root", 0.0, 8.1, 0.0, Vector2(0, 3.2))
	breath("chest", 1.6, 8.1, 0.5)
	breath("scarf", 6.0, 2.3, 0.0)
	breath("arm_f", 1.5, 8.1, 0.9)
	breath("arm_b", -1.5, 8.1, 0.9)

func _define_poses() -> void:
	pose("idle", {
		"hips": [0, 0, 3], "chest": [7, 0, 0], "head": [-4, 0, 0],
		"arm_f": [-28, 0, 0], "fore_f": [-52, 0, 0],
		"arm_b": [-20, 0, 0], "fore_b": [-58, 0, 0],
		"leg_f": [-10, 0, 0], "shin_f": [12, 0, 0],
		"leg_b": [14, 0, 0], "shin_b": [6, 0, 0],
		"scarf": [4, 0, 0],
	})
	# --- daggers ---
	pose("wind_a", {
		"chest": [-7, 0, 0], "arm_f": [26, 0, 0], "fore_f": [-95, 0, 0],
		"arm_b": [-16, 0, 0], "fore_b": [-50, 0, 0],
		"root": [0, -10, 0], "scarf": [-10, 0, 0],
	})
	pose("hit_a", {
		"chest": [16, 0, 0], "head": [-2, 0, 0],
		"arm_f": [-88, 0, 0], "fore_f": [-4, 0, 0],
		"arm_b": [-8, 0, 0], "fore_b": [-46, 0, 0],
		"root": [0, 24, -2], "leg_b": [26, 0, 0], "scarf": [14, 0, 0],
	})
	pose("wind_b", {
		"chest": [-5, 0, 0], "arm_b": [30, 0, 0], "fore_b": [-100, 0, 0],
		"arm_f": [-20, 0, 0], "fore_f": [-55, 0, 0],
		"root": [0, -8, 0],
	})
	pose("hit_b", {
		"chest": [18, 0, 0], "arm_b": [-92, 0, 0], "fore_b": [-2, 0, 0],
		"arm_f": [-14, 0, 0], "fore_f": [-48, 0, 0],
		"root": [0, 24, -2], "leg_b": [26, 0, 0], "scarf": [14, 0, 0],
	})
	# Perfect / Eviscerate: the scissor X-cross
	pose("wind_x", {
		"chest": [-9, 0, 0], "arm_f": [30, 0, 0], "fore_f": [-108, 0, 0],
		"arm_b": [34, 0, 0], "fore_b": [-112, 0, 0],
		"root": [0, -12, 2], "scarf": [-12, 0, 0],
	})
	pose("hit_x", {
		"chest": [20, 0, 0], "head": [2, 0, 0],
		"arm_f": [-95, 0, 0], "fore_f": [8, 0, 0],
		"arm_b": [-70, 0, 0], "fore_b": [-6, 0, 0],
		"root": [0, 30, -4], "leg_b": [30, 0, 0], "scarf": [18, 0, 0],
	})
	# Kick — the interrupt is a literal boot
	pose("wind_kick", {
		"chest": [-14, 0, 0], "leg_f": [26, 0, 0], "shin_f": [70, 0, 0],
		"arm_f": [12, 0, 0], "arm_b": [10, 0, 0],
		"root": [0, -8, 2],
	})
	pose("hit_kick", {
		"chest": [-8, 0, 0], "leg_f": [-96, 0, 0], "shin_f": [4, 0, 0],
		"leg_b": [18, 0, 0], "arm_f": [22, 0, 0], "arm_b": [18, 0, 0],
		"root": [0, 18, -4], "head": [4, 0, 0],
	})
	# Coup de Grâce — crouch, leap, two-dagger plunge, land
	pose("coup_crouch", {
		"hips": [0, 0, 18], "chest": [22, 0, 0], "head": [-6, 0, 0],
		"arm_f": [24, 0, 0], "fore_f": [-70, 0, 0],
		"arm_b": [26, 0, 0], "fore_b": [-74, 0, 0],
		"leg_f": [-24, 0, 0], "shin_f": [40, 0, 0], "leg_b": [30, 0, 0], "shin_b": [30, 0, 0],
		"root": [0, -6, 0],
	})
	pose("coup_plunge", {
		"chest": [30, 0, 0], "head": [6, 0, 0],
		"arm_f": [-115, 0, 0], "fore_f": [16, 0, 0],
		"arm_b": [-108, 0, 0], "fore_b": [12, 0, 0],
		"leg_f": [-32, 0, 0], "shin_f": [30, 0, 0], "leg_b": [42, 0, 0], "shin_b": [46, 0, 0],
		"root": [0, 86, -66], "scarf": [-26, 0, 0],
	})
	pose("coup_land", {
		"hips": [0, 0, 14], "chest": [18, 0, 0],
		"arm_f": [-40, 0, 0], "fore_f": [-20, 0, 0], "arm_b": [-36, 0, 0],
		"leg_f": [-20, 0, 0], "shin_f": [34, 0, 0], "leg_b": [26, 0, 0], "shin_b": [26, 0, 0],
		"root": [0, 64, 0],
	})
	# venom finishers: plant a hand, lay the cocktail
	pose("cast_venom", {
		"hips": [0, 0, 10], "chest": [16, 0, 0], "head": [4, 0, 0],
		"arm_f": [-64, 0, 0], "fore_f": [-18, 0, 0],
		"arm_b": [14, 0, 0], "root": [0, 8, 0],
	})
	# --- defense / reacts ---
	pose("evade", {
		"chest": [-20, 0, 0], "head": [-8, 0, 0],
		"arm_f": [18, 0, 0], "fore_f": [-40, 0, 0], "arm_b": [24, 0, 0],
		"leg_f": [-30, 0, 0], "shin_f": [46, 0, 0], "leg_b": [34, 0, 0], "shin_b": [20, 0, 0],
		"root": [0, -52, -8], "scarf": [-20, 0, 0],
	})
	pose("hop_back", {
		"chest": [-10, 0, 0], "leg_f": [-22, 0, 0], "shin_f": [44, 0, 0],
		"leg_b": [26, 0, 0], "shin_b": [40, 0, 0],
		"root": [0, -30, -12], "scarf": [-14, 0, 0],
	})
	pose("stumble", {
		"chest": [26, 0, 0], "head": [12, 0, 0],
		"arm_f": [-48, 0, 0], "fore_f": [-20, 0, 0], "arm_b": [-30, 0, 0],
		"root": [0, 14, 2], "leg_b": [22, 0, 0],
	})
	pose("brace", {
		"chest": [8, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-36, 0, 0], "fore_f": [-88, 0, 0],
		"arm_b": [-32, 0, 0], "fore_b": [-86, 0, 0],
		"root": [0, -5, 2], "hips": [0, 0, 6],
	})
	pose("hit", {
		"chest": [-18, 0, 0], "head": [-12, 0, 0],
		"arm_f": [14, 0, 0], "arm_b": [10, 0, 0],
		"root": [0, -16, 0],
	})
	pose("hit_big", {
		"chest": [-30, 0, 0], "head": [-18, 0, 0],
		"arm_f": [28, 0, 0], "fore_f": [-20, 0, 0], "arm_b": [24, 0, 0],
		"root": [0, -30, 3], "leg_f": [-14, 0, 0], "leg_b": [26, 0, 0],
	})
	# the rhythm dies: everything sags
	pose("slump", {
		"hips": [0, 0, 8], "chest": [15, 0, 0], "head": [16, 0, 0],
		"arm_f": [-4, 0, 0], "fore_f": [-8, 0, 0],
		"arm_b": [-2, 0, 0], "fore_b": [-6, 0, 0],
		"scarf": [22, 0, 0],
	})
	pose("victory", {
		"chest": [-10, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-160, 0, 0], "fore_f": [-18, 0, 0],
		"arm_b": [-152, 0, 0], "fore_b": [-14, 0, 0],
		"root": [0, 0, -4],
	})
	pose("death", {
		"hips": [0, 0, 40], "chest": [42, 0, 0], "head": [26, 0, 0],
		"arm_f": [-10, 0, 0], "fore_f": [-6, 0, 0], "arm_b": [-6, 0, 0],
		"leg_f": [-58, 0, 0], "shin_f": [92, 0, 0], "leg_b": [62, 0, 0], "shin_b": [24, 0, 0],
		"root": [0, 0, 26], "scarf": [26, 0, 0],
	})

# ============================================================ acting API
var _alt := false
## An ability committed. Returns {delay, kind} VFX hints for the stage.
func act(id: String, perfect := false) -> Dictionary:
	match id:
		"strike":
			if perfect:
				seq([{"pose": "wind_x", "dur": 0.07, "ease": "out"},
					{"pose": "hit_x", "dur": 0.07, "ease": "snap", "hold": 0.14}])
				flash_part("dagger_f", accent, 1.0)
				flash_part("dagger_b", accent, 1.0)
				return {"delay": 0.12, "kind": "perfect"}
			_alt = not _alt
			seq([{"pose": "wind_a" if _alt else "wind_b", "dur": 0.06, "ease": "out"},
				{"pose": "hit_a" if _alt else "hit_b", "dur": 0.06, "ease": "snap", "hold": 0.10}])
			return {"delay": 0.10, "kind": "slash"}
		"eviscerate":
			seq([{"pose": "wind_x", "dur": 0.10, "ease": "out"},
				{"pose": "hit_x", "dur": 0.08, "ease": "snap", "hold": 0.18}])
			flash_part("dagger_f", Color("ffdc93"), 1.0)
			flash_part("dagger_b", Color("ffdc93"), 1.0)
			return {"delay": 0.15, "kind": "cross"}
		"flurry":
			seq([{"pose": "hit_a", "dur": 0.06, "ease": "snap", "hold": 0.02},
				{"pose": "hit_b", "dur": 0.08, "ease": "snap", "hold": 0.02},
				{"pose": "hit_a", "dur": 0.08, "ease": "snap", "hold": 0.08}])
			return {"delay": 0.06, "kind": "slash", "repeats": 3, "gap": 0.11}
		"kick":
			seq([{"pose": "wind_kick", "dur": 0.09, "ease": "out"},
				{"pose": "hit_kick", "dur": 0.07, "ease": "snap", "hold": 0.20}])
			return {"delay": 0.14, "kind": "kick"}
		"coupdegrace":
			seq([{"pose": "coup_crouch", "dur": 0.12, "ease": "out", "hold": 0.04},
				{"pose": "coup_plunge", "dur": 0.12, "ease": "snap", "hold": 0.10},
				{"pose": "coup_land", "dur": 0.12, "ease": "out", "hold": 0.06}])
			flash_part("dagger_f", accent, 1.0)
			flash_part("dagger_b", accent, 1.0)
			flash_part("scarf", accent, 1.0)
			return {"delay": 0.28, "kind": "coup"}
		"envenom", "rupture":
			seq([{"pose": "cast_venom", "dur": 0.12, "ease": "out", "hold": 0.16}])
			return {"delay": 0.16, "kind": "venom"}
		_:
			_alt = not _alt
			seq([{"pose": "hit_a" if _alt else "hit_b", "dur": 0.08, "ease": "snap", "hold": 0.08}])
			return {"delay": 0.10, "kind": "slash"}

## The dodge VERB (Space): full backdash — protects HP and Flow both.
func evade_react() -> void:
	seq([{"pose": "evade", "dur": 0.08, "ease": "snap", "hold": 0.24}])
	flash_part("scarf", accent, 1.0)

## M7 universal-dodge grades.
func hop_react(clean: bool) -> void:
	seq([{"pose": "hop_back", "dur": 0.07 if clean else 0.12, "ease": "snap", "hold": 0.18}])

func graze_react() -> void:
	seq([{"pose": "hop_back", "dur": 0.13, "ease": "out", "hold": 0.04},
		{"pose": "hit", "dur": 0.08, "ease": "snap", "hold": 0.06}])

func stumble_react() -> void:
	jolt(0.7)
	seq([{"pose": "stumble", "dur": 0.09, "ease": "snap", "hold": 0.4}])

func brace_react() -> void:
	seq([{"pose": "brace", "dur": 0.10, "ease": "out", "hold": 0.35}])
	flash_part("eye", accent, 1.0)

func hit_react(big: bool) -> void:
	jolt(1.0 if big else 0.5)
	seq([{"pose": "hit_big" if big else "hit", "dur": 0.07, "ease": "snap", "hold": 0.15 if big else 0.08}])

func slump_react() -> void:
	seq([{"pose": "slump", "dur": 0.22, "ease": "io", "hold": 0.45}])

## Flow tier lights the body up and quickens the bounce — the rhythm made visible.
## Actor2D contract: generic resource glow routes into the Flow look.
func power_glow(frac: float) -> void:
	flow_glow(int(round(frac * 6.0)), frac)

func flow_glow(tier: int, flow_frac: float) -> void:
	var g := 0.15 + 0.75 * flow_frac
	part_glow("eye", accent, g)
	part_glow("scarf", accent, g * 0.5)
	part_glow("dagger_f", accent, 0.4 * flow_frac)
	part_glow("dagger_b", accent, 0.4 * flow_frac)
	breath_scale = 1.0 + 0.10 * float(tier)

func die() -> void:
	windup_amt = 0.0
	breath_scale = 0.0
	rest_in("death", 0.7)
	part_glow("eye", accent, 0.0)
	part_glow("scarf", accent, 0.0)

func win() -> void:
	windup_amt = 0.0
	rest_in("victory", 0.45)
	flash_part("dagger_f", accent, 1.0)
	flash_part("dagger_b", accent, 1.0)
