## VoidcallerRig2D — placeholder caster puppet (~300px, faces +X): robed, staff
## with a void orb. evade_react IS the Kick (staff jab — the interrupt verb);
## windup("channel") is its own cast bar (Fracture); acts are staff-thrust bolts.
class_name VoidcallerRig2D
extends PoseRig2D

var accent := Color("b48ee8")

func _init(aspect: String = "disruptor") -> void:
	accent = Color("8a5bd6") if aspect == "silencer" else Color("b48ee8")

func _build() -> void:
	var robe := Color(0.235, 0.22, 0.31)
	var dark := Color(0.175, 0.165, 0.235)
	var wood := Color("6b5426")
	var skin := Color(0.42, 0.36, 0.33)
	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -120))
	# robe skirt instead of legs
	poly(hips, PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(24, 118),
		Vector2(6, 112), Vector2(-10, 120), Vector2(-22, 114)]), dark)
	limb(hips, "capsule", Vector2(0, 2), Vector2(2, 14), 13, 12, robe)
	var chest := joint(hips, "chest", Vector2(1, -6))
	var arm_b := joint(chest, "arm_b", Vector2(-8, -42))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(4, 26), 7, 6, robe)
	var fore_b := joint(arm_b, "fore_b", Vector2(4, 26))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(8, 24), 5.5, 4.5, robe)
	limb(chest, "capsule", Vector2(0, 4), Vector2(3, -46), 13, 13, robe)
	var head := joint(chest, "head", Vector2(7, -54))
	limb(head, "circle", Vector2(0, -4), Vector2.ZERO, 12, 0, skin.darkened(0.4))
	poly(head, PackedVector2Array([Vector2(-16, 5), Vector2(-13, -14), Vector2(0, -22),
		Vector2(12, -13), Vector2(13, 3), Vector2(-2, 8)]), dark)
	limb(head, "circle", Vector2(6, -4), Vector2.ZERO, 2.4, 0, accent, "eye")
	var arm_f := joint(chest, "arm_f", Vector2(6, -44))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(6, 26), 7.5, 6, robe)
	var fore_f := joint(arm_f, "fore_f", Vector2(6, 26))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(9, 24), 6, 4.5, robe)
	var hand_f := joint(fore_f, "hand_f", Vector2(9, 24))
	# the staff: long haft + void orb at the top
	limb(hand_f, "capsule", Vector2(0, 30), Vector2(4, -120), 3.5, 3, wood)
	limb(hand_f, "circle", Vector2(5, -132), Vector2.ZERO, 9, 0, accent, "orb")
	breath("chest", 1.4, 1.9)
	breath("root", 0.0, 1.9, 0.0, Vector2(0, 2.0))
	breath("hand_f", 1.2, 1.3, 0.6)

func _define_poses() -> void:
	pose("idle", {"chest": [5, 0, 0], "head": [-3, 0, 0],
		"arm_f": [-30, 0, 0], "fore_f": [-40, 0, 0],
		"arm_b": [-12, 0, 0], "fore_b": [-30, 0, 0]})
	# its own cast bar (Fracture): both hands to the staff, leaning in
	pose("channel", {"chest": [10, 0, 0], "head": [4, 0, 0],
		"arm_f": [-48, 0, 0], "fore_f": [-50, 0, 0],
		"arm_b": [-44, 0, 0], "fore_b": [-58, 0, 0], "root": [0, -4, 2]})
	pose("cast", {"chest": [12, 0, 0], "arm_f": [-78, 0, 0], "fore_f": [-16, 0, 0],
		"root": [0, 12, -2]})
	pose("big_cast", {"chest": [-10, 0, 0], "head": [-10, 0, 0],
		"arm_f": [-130, 0, 0], "fore_f": [-30, 0, 0], "arm_b": [-40, 0, 0],
		"root": [0, -4, 2]})
	pose("kick_w", {"chest": [-10, 0, 0], "arm_f": [10, 0, 0], "root": [0, -8, 2]})
	pose("kick", {"chest": [14, 0, 0], "arm_f": [-84, 0, 0], "fore_f": [-8, 0, 0],
		"root": [0, 20, -4]})
	pose("hop_back", {"chest": [-10, 0, 0], "root": [0, -26, -8]})
	pose("stumble", {"chest": [22, 0, 0], "head": [10, 0, 0], "root": [0, 10, 2]})
	pose("brace", {"chest": [8, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-50, 0, 0], "fore_f": [-64, 0, 0]})
	pose("hit", {"chest": [-15, 0, 0], "head": [-11, 0, 0], "root": [0, -13, 0]})
	pose("hit_big", {"chest": [-26, 0, 0], "head": [-16, 0, 0], "root": [0, -24, 3]})
	pose("victory", {"chest": [-8, 0, 0], "arm_f": [-150, 0, 0], "fore_f": [-12, 0, 0]})
	pose("death", {"hips": [0, 0, 44], "chest": [44, 0, 0], "head": [26, 0, 0],
		"arm_f": [-6, 0, 0], "arm_b": [-2, 0, 0], "root": [0, 0, 30]})

func act(id: String, _flourish := false) -> Dictionary:
	match id:
		"fracture", "overload", "quietus":
			seq([{"pose": "big_cast", "dur": 0.10, "ease": "snap", "hold": 0.18}])
			flash_part("orb", accent, 1.0)
			return {"delay": 0.13, "kind": "cast_bolt"}
		"barrier", "silence", "counterspell":
			seq([{"pose": "big_cast", "dur": 0.12, "ease": "out", "hold": 0.2}])
			flash_part("orb", accent, 1.0)
			return {"delay": 0.15, "kind": "cast"}
		_:
			seq([{"pose": "cast", "dur": 0.08, "ease": "snap", "hold": 0.10}])
			flash_part("orb", accent, 0.8)
			return {"delay": 0.10, "kind": "cast_bolt"}

## The interrupt verb: KICK the cast (staff jab).
func evade_react() -> void:
	seq([{"pose": "kick_w", "dur": 0.06, "ease": "out"},
		{"pose": "kick", "dur": 0.06, "ease": "snap", "hold": 0.2}])
	flash_part("orb", Color("b48ee8"), 1.0)

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

func cast_react(_id: String) -> void:
	if _seq.is_empty():
		seq([{"pose": "cast", "dur": 0.08, "ease": "snap", "hold": 0.08}])

func power_glow(frac: float) -> void:
	part_glow("orb", accent, 0.3 + 0.7 * frac)
	part_glow("eye", accent, 0.2 + 0.5 * frac)

func die() -> void:
	windup_amt = 0.0
	breath_scale = 0.0
	rest_in("death", 0.7)
	part_glow("orb", accent, 0.0)
	part_glow("eye", accent, 0.0)

func win() -> void:
	windup_amt = 0.0
	rest_in("victory", 0.5)
	flash_part("orb", accent, 1.0)
