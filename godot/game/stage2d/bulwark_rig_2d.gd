## BulwarkRig2D — placeholder tank puppet (~320px, faces +X): tower shield front,
## sword back, steel/ember aspect accent. Raid-lineup anchor: guard is the windup
## channel, evade_react is the parry punch, Challenge is a shield-up roar.
class_name BulwarkRig2D
extends PoseRig2D

var accent := Color("8fb8e0")

func _init(aspect: String = "warden") -> void:
	accent = Color("e0862f") if aspect == "juggernaut" else Color("8fb8e0")

func _build() -> void:
	var armor := Color(0.30, 0.30, 0.38)
	var dark := Color(0.22, 0.22, 0.285)
	var gold := Color("9a7a3d")
	var steel := Color(0.72, 0.75, 0.85)
	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -128))
	var leg_b := joint(hips, "leg_b", Vector2(-11, 6))
	limb(leg_b, "capsule", Vector2.ZERO, Vector2(-4, 58), 11, 8, dark)
	var shin_b := joint(leg_b, "shin_b", Vector2(-4, 58))
	limb(shin_b, "capsule", Vector2.ZERO, Vector2(2, 56), 8, 6, dark)
	limb(shin_b, "capsule", Vector2(2, 56), Vector2(18, 58), 6, 5, dark)
	limb(hips, "capsule", Vector2(0, 2), Vector2(2, 16), 14, 13, armor)
	limb(hips, "capsule", Vector2(-10, 2), Vector2(12, 4), 5, 5, gold)
	var chest := joint(hips, "chest", Vector2(1, -6))
	var arm_b := joint(chest, "arm_b", Vector2(-9, -44))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(4, 28), 8, 7, armor)
	var fore_b := joint(arm_b, "fore_b", Vector2(4, 28))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(8, 26), 6, 5, armor)
	var hand_b := joint(fore_b, "hand_b", Vector2(8, 26))
	limb(hand_b, "blade", Vector2(2, 0), Vector2(52, -3), 4.5, 0, steel, "sword")
	limb(chest, "capsule", Vector2(0, 4), Vector2(3, -50), 14, 15, armor)
	var head := joint(chest, "head", Vector2(7, -58))
	limb(head, "circle", Vector2(0, -4), Vector2.ZERO, 13, 0, dark)
	poly(head, PackedVector2Array([Vector2(-14, 4), Vector2(-13, -14), Vector2(0, -19),
		Vector2(12, -12), Vector2(13, 4), Vector2(-2, 8)]), armor)
	limb(head, "capsule", Vector2(4, -4), Vector2(12, -4), 2.2, 2.2, accent, "visor")
	var leg_f := joint(hips, "leg_f", Vector2(12, 6))
	limb(leg_f, "capsule", Vector2.ZERO, Vector2(4, 58), 11.5, 8, dark)
	var shin_f := joint(leg_f, "shin_f", Vector2(4, 58))
	limb(shin_f, "capsule", Vector2.ZERO, Vector2(2, 56), 8.5, 6, dark)
	limb(shin_f, "capsule", Vector2(2, 56), Vector2(19, 58), 6, 5, dark)
	var arm_f := joint(chest, "arm_f", Vector2(7, -46))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(6, 28), 8.5, 7, armor)
	var fore_f := joint(arm_f, "fore_f", Vector2(6, 28))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(9, 26), 6.5, 5, armor)
	var hand_f := joint(fore_f, "hand_f", Vector2(9, 26))
	# tower shield on the front arm
	poly(hand_f, PackedVector2Array([Vector2(6, -34), Vector2(20, -30), Vector2(22, 26),
		Vector2(12, 38), Vector2(2, 26), Vector2(0, -30)]), dark, "shield")
	limb(hand_f, "circle", Vector2(11, 0), Vector2.ZERO, 5, 0, accent, "emblem")
	breath("chest", 1.5, 2.0)
	breath("root", 0.0, 2.0, 0.0, Vector2(0, 2.2))

func _define_poses() -> void:
	pose("idle", {"hips": [0, 0, 2], "chest": [6, 0, 0], "head": [-3, 0, 0],
		"arm_f": [-34, 0, 0], "fore_f": [-48, 0, 0],
		"arm_b": [-10, 0, 0], "fore_b": [-40, 0, 0],
		"leg_f": [-8, 0, 0], "shin_f": [10, 0, 0], "leg_b": [12, 0, 0], "shin_b": [6, 0, 0]})
	pose("guard", {"chest": [12, 0, 0], "head": [2, 0, 0], "hips": [0, 0, 8],
		"arm_f": [-58, 0, 0], "fore_f": [-64, 0, 0],
		"leg_f": [-14, 0, 0], "shin_f": [20, 0, 0], "root": [0, -4, 2]})
	pose("parry", {"chest": [14, 0, 0], "arm_f": [-74, 0, 0], "fore_f": [-30, 0, 0],
		"root": [0, 18, -2], "leg_b": [20, 0, 0]})
	pose("slash_w", {"chest": [-8, 0, 0], "arm_b": [34, 0, 0], "fore_b": [-96, 0, 0], "root": [0, -8, 0]})
	pose("slash", {"chest": [16, 0, 0], "arm_b": [-90, 0, 0], "fore_b": [-6, 0, 0],
		"root": [0, 22, -2], "leg_b": [22, 0, 0]})
	pose("slam_w", {"chest": [-14, 0, 0], "arm_b": [70, 0, 0], "fore_b": [-120, 0, 0],
		"head": [-8, 0, 0], "root": [0, -10, 2]})
	pose("slam", {"chest": [26, 0, 0], "arm_b": [-70, 0, 0], "fore_b": [16, 0, 0],
		"root": [0, 26, 2], "leg_f": [-12, 0, 0], "shin_f": [18, 0, 0], "hips": [0, 0, 8]})
	pose("roar", {"chest": [-14, 0, 0], "head": [-12, 0, 0],
		"arm_f": [-96, 0, 0], "fore_f": [-40, 0, 0], "arm_b": [20, 0, 0],
		"root": [0, -8, 0]})
	pose("cast", {"chest": [8, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-50, 0, 0], "fore_f": [-70, 0, 0], "arm_b": [10, 0, 0], "hips": [0, 0, 5]})
	pose("hop_back", {"chest": [-10, 0, 0], "leg_f": [-20, 0, 0], "shin_f": [40, 0, 0],
		"leg_b": [24, 0, 0], "shin_b": [36, 0, 0], "root": [0, -26, -10]})
	pose("stumble", {"chest": [24, 0, 0], "head": [10, 0, 0],
		"arm_f": [-20, 0, 0], "arm_b": [-26, 0, 0], "root": [0, 12, 2]})
	pose("brace", {"chest": [10, 0, 0], "head": [-6, 0, 0],
		"arm_f": [-62, 0, 0], "fore_f": [-70, 0, 0], "hips": [0, 0, 6]})
	pose("hit", {"chest": [-16, 0, 0], "head": [-12, 0, 0], "root": [0, -14, 0]})
	pose("hit_big", {"chest": [-28, 0, 0], "head": [-16, 0, 0],
		"arm_b": [24, 0, 0], "root": [0, -26, 3], "leg_b": [22, 0, 0]})
	pose("victory", {"chest": [-8, 0, 0], "arm_b": [-150, 0, 0], "fore_b": [-16, 0, 0],
		"arm_f": [-40, 0, 0]})
	pose("death", {"hips": [0, 0, 42], "chest": [40, 0, 0], "head": [24, 0, 0],
		"arm_f": [-8, 0, 0], "arm_b": [-4, 0, 0],
		"leg_f": [-56, 0, 0], "shin_f": [92, 0, 0], "leg_b": [60, 0, 0], "shin_b": [26, 0, 0],
		"root": [0, 0, 28]})

func act(id: String, _flourish := false) -> Dictionary:
	match id:
		"cleave":
			seq([{"pose": "slash_w", "dur": 0.08, "ease": "out"},
				{"pose": "slash", "dur": 0.07, "ease": "snap", "hold": 0.12}])
			flash_part("sword", Color("ffdc93"), 1.0)
			return {"delay": 0.12, "kind": "slash"}
		"rampage", "avalanche", "shockwave":
			seq([{"pose": "slam_w", "dur": 0.12, "ease": "out"},
				{"pose": "slam", "dur": 0.08, "ease": "snap", "hold": 0.16}])
			flash_part("sword", Color("ffdc93"), 1.0)
			return {"delay": 0.18, "kind": "slam"}
		"fortify":
			seq([{"pose": "cast", "dur": 0.16, "ease": "io", "hold": 0.35}])
			flash_part("emblem", accent, 1.0)
			return {"delay": 0.2, "kind": "cast"}
		"challenge":
			seq([{"pose": "roar", "dur": 0.10, "ease": "snap", "hold": 0.3}])
			flash_part("emblem", Color("d0413a"), 1.0)
			flash_part("visor", Color("d0413a"), 1.0)
			return {"delay": 0.1, "kind": "kick"}
		"vindicate", "bloodthirst":
			seq([{"pose": "slash_w", "dur": 0.07, "ease": "out"},
				{"pose": "slash", "dur": 0.06, "ease": "snap", "hold": 0.04},
				{"pose": "slash_w", "dur": 0.09, "ease": "out"},
				{"pose": "slash", "dur": 0.06, "ease": "snap", "hold": 0.10}])
			flash_part("sword", accent, 1.0)
			return {"delay": 0.10, "kind": "slash", "repeats": 2, "gap": 0.2}
		_:
			seq([{"pose": "slash", "dur": 0.08, "ease": "snap", "hold": 0.1}])
			return {"delay": 0.1, "kind": "slash"}

func evade_react() -> void:
	seq([{"pose": "parry", "dur": 0.06, "ease": "snap", "hold": 0.26}])
	flash_part("emblem", Color("ffdc93"), 1.0)

func hop_react(_c: bool) -> void:
	seq([{"pose": "hop_back", "dur": 0.08, "ease": "snap", "hold": 0.16}])

func graze_react() -> void:
	seq([{"pose": "hop_back", "dur": 0.12, "ease": "out", "hold": 0.04},
		{"pose": "hit", "dur": 0.07, "ease": "snap", "hold": 0.06}])

func stumble_react() -> void:
	jolt(0.7)
	seq([{"pose": "stumble", "dur": 0.09, "ease": "snap", "hold": 0.35}])

func brace_react() -> void:
	seq([{"pose": "brace", "dur": 0.10, "ease": "out", "hold": 0.3}])

func hit_react(big: bool) -> void:
	jolt(1.0 if big else 0.5)
	seq([{"pose": "hit_big" if big else "hit", "dur": 0.07, "ease": "snap", "hold": 0.12 if big else 0.07}])

func power_glow(frac: float) -> void:
	part_glow("emblem", accent, 0.2 + 0.7 * frac)
	part_glow("visor", accent, 0.2 + 0.5 * frac)

func die() -> void:
	windup_amt = 0.0
	breath_scale = 0.0
	rest_in("death", 0.7)
	part_glow("emblem", accent, 0.0)
	part_glow("visor", accent, 0.0)

func win() -> void:
	windup_amt = 0.0
	rest_in("victory", 0.5)
