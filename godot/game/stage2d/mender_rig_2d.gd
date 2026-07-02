## MenderRig2D — placeholder healer puppet (~295px, faces +X): hooded robes, open
## hands, a soft halo of the aspect colour. cast_react per spell (small heals one
## hand, big heals both up), windup("channel") is the cast bar, and the universal
## dodge still hops — the healer answers aoe beats too.
class_name MenderRig2D
extends PoseRig2D

var accent := Color("83c98d")

func _init(aspect: String = "tidecaller") -> void:
	accent = Color("e0862f") if aspect == "brinkwarden" else Color("8fb8e0")

func _build() -> void:
	var robe := Color(0.27, 0.29, 0.30)
	var dark := Color(0.20, 0.215, 0.225)
	var skin := Color(0.44, 0.38, 0.35)
	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -118))
	poly(hips, PackedVector2Array([Vector2(-15, 0), Vector2(15, 0), Vector2(22, 116),
		Vector2(4, 110), Vector2(-12, 118), Vector2(-20, 112)]), dark)
	limb(hips, "capsule", Vector2(0, 2), Vector2(2, 14), 12, 11, robe)
	var chest := joint(hips, "chest", Vector2(1, -6))
	var arm_b := joint(chest, "arm_b", Vector2(-8, -40))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(4, 25), 6.5, 5.5, robe)
	var fore_b := joint(arm_b, "fore_b", Vector2(4, 25))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(8, 23), 5, 4, robe)
	var hand_b := joint(fore_b, "hand_b", Vector2(8, 23))
	limb(hand_b, "circle", Vector2.ZERO, Vector2.ZERO, 4.5, 0, skin, "hand_b_p")
	limb(chest, "capsule", Vector2(0, 4), Vector2(3, -44), 12, 12, robe)
	var head := joint(chest, "head", Vector2(6, -52))
	limb(head, "circle", Vector2(0, -4), Vector2.ZERO, 12, 0, skin.darkened(0.3))
	poly(head, PackedVector2Array([Vector2(-15, 5), Vector2(-12, -14), Vector2(0, -20),
		Vector2(11, -12), Vector2(12, 4), Vector2(-2, 8)]), dark)
	limb(head, "circle", Vector2(0, -26), Vector2.ZERO, 4, 0, accent, "halo")
	var arm_f := joint(chest, "arm_f", Vector2(6, -42))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(6, 25), 7, 5.5, robe)
	var fore_f := joint(arm_f, "fore_f", Vector2(6, 25))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(9, 23), 5.5, 4, robe)
	var hand_f := joint(fore_f, "hand_f", Vector2(9, 23))
	limb(hand_f, "circle", Vector2.ZERO, Vector2.ZERO, 4.5, 0, skin, "hand_f_p")
	breath("chest", 1.4, 1.8)
	breath("root", 0.0, 1.8, 0.0, Vector2(0, 2.0))

func _define_poses() -> void:
	pose("idle", {"chest": [4, 0, 0], "head": [-3, 0, 0],
		"arm_f": [-38, 0, 0], "fore_f": [-58, 0, 0],
		"arm_b": [-34, 0, 0], "fore_b": [-56, 0, 0]})
	pose("channel", {"chest": [7, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-52, 0, 0], "fore_f": [-66, 0, 0],
		"arm_b": [-48, 0, 0], "fore_b": [-64, 0, 0]})
	pose("cast", {"chest": [9, 0, 0], "arm_f": [-82, 0, 0], "fore_f": [-14, 0, 0],
		"root": [0, 6, -2]})
	pose("big_cast", {"chest": [-8, 0, 0], "head": [-10, 0, 0],
		"arm_f": [-140, 0, 0], "fore_f": [-20, 0, 0],
		"arm_b": [-135, 0, 0], "fore_b": [-18, 0, 0], "root": [0, -4, 0]})
	pose("hop_back", {"chest": [-9, 0, 0], "root": [0, -24, -8]})
	pose("stumble", {"chest": [20, 0, 0], "head": [10, 0, 0], "root": [0, 8, 2]})
	pose("brace", {"chest": [7, 0, 0], "head": [-7, 0, 0],
		"arm_f": [-48, 0, 0], "fore_f": [-62, 0, 0]})
	pose("hit", {"chest": [-14, 0, 0], "head": [-10, 0, 0], "root": [0, -12, 0]})
	pose("hit_big", {"chest": [-24, 0, 0], "head": [-15, 0, 0], "root": [0, -22, 3]})
	pose("victory", {"chest": [-7, 0, 0], "arm_f": [-148, 0, 0], "arm_b": [-142, 0, 0]})
	pose("death", {"hips": [0, 0, 42], "chest": [42, 0, 0], "head": [26, 0, 0],
		"arm_f": [-4, 0, 0], "arm_b": [-2, 0, 0], "root": [0, 0, 28]})

func act(id: String, _flourish := false) -> Dictionary:
	cast_react(id)
	return {"delay": 0.12, "kind": "heal"}

func cast_react(id: String) -> void:
	match id:
		"cascade", "well", "surge", "laststand", "medit":
			seq([{"pose": "big_cast", "dur": 0.12, "ease": "out", "hold": 0.22}])
			flash_part("halo", accent, 1.0)
			flash_part("hand_f_p", accent, 1.0)
			flash_part("hand_b_p", accent, 1.0)
		_:
			seq([{"pose": "cast", "dur": 0.09, "ease": "snap", "hold": 0.12}])
			flash_part("hand_f_p", accent, 1.0)

func evade_react() -> void:
	hop_react(true)

func hop_react(_c: bool) -> void:
	seq([{"pose": "hop_back", "dur": 0.08, "ease": "snap", "hold": 0.16}])

func graze_react() -> void:
	seq([{"pose": "hop_back", "dur": 0.12, "ease": "out", "hold": 0.04},
		{"pose": "hit", "dur": 0.07, "ease": "snap", "hold": 0.06}])

func stumble_react() -> void:
	jolt(0.6)
	seq([{"pose": "stumble", "dur": 0.09, "ease": "snap", "hold": 0.35}])

func brace_react() -> void:
	seq([{"pose": "brace", "dur": 0.10, "ease": "out", "hold": 0.3}])

func hit_react(big: bool) -> void:
	jolt(0.9 if big else 0.45)
	seq([{"pose": "hit_big" if big else "hit", "dur": 0.07, "ease": "snap", "hold": 0.1 if big else 0.06}])

func power_glow(frac: float) -> void:
	part_glow("halo", accent, 0.25 + 0.7 * frac)

func die() -> void:
	windup_amt = 0.0
	breath_scale = 0.0
	rest_in("death", 0.7)
	part_glow("halo", accent, 0.0)

func win() -> void:
	windup_amt = 0.0
	rest_in("victory", 0.5)
	flash_part("halo", accent, 1.0)
