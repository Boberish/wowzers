## BulwarkRig — the tank as a 3D actor: an obsidian-armored knight with tower shield
## (left) and longsword (right), aspect-tinted (Warden steel / Juggernaut ember).
## Built facing -Z. Every combat verb has body language: abilities are authored
## sequences via act(), the defensive press uses the windup channel ("guard" deepens
## while the active window runs), and the M7 dodge grades each get their own react.
class_name BulwarkRig
extends PoseRig

var accent: Color = Color("8fb8e0")

func _init(aspect: String = "warden") -> void:
	accent = Color("e0862f") if aspect == "juggernaut" else Color("8fb8e0")

func _build() -> void:
	var armor := mat(Color(0.165, 0.165, 0.215), 0.5, 0.7)
	var plate := mat(Color(0.195, 0.195, 0.255), 0.44, 0.8)
	var gold := mat(Color("b98d43"), 0.34, 0.9)
	var cloth := mat(Color(0.20, 0.075, 0.085), 0.92, 0.0)
	var acc_glow := mat(accent.darkened(0.35), 0.5, 0.4, accent, 1.6)
	# faintly self-lit so the blade reads against the dark sanctum
	var blade_m := mat(Color(0.80, 0.83, 0.92), 0.28, 0.8, Color(0.75, 0.78, 0.9), 0.30)

	var root := joint(self, "root", Vector3.ZERO)
	var hips := joint(root, "hips", Vector3(0, 0.98, 0))
	var chest := joint(hips, "chest", Vector3(0, 0.30, 0))
	var head := joint(chest, "head", Vector3(0, 0.36, 0))
	var sh_l := joint(chest, "sh_l", Vector3(-0.30, 0.17, 0))
	var sh_r := joint(chest, "sh_r", Vector3(0.30, 0.17, 0))
	var el_l := joint(sh_l, "el_l", Vector3(0, -0.28, 0))
	var el_r := joint(sh_r, "el_r", Vector3(0, -0.28, 0))
	var hand_l := joint(el_l, "hand_l", Vector3(0, -0.27, 0))
	var hand_r := joint(el_r, "hand_r", Vector3(0, -0.27, 0))
	var leg_l := joint(hips, "leg_l", Vector3(-0.155, -0.04, 0))
	var leg_r := joint(hips, "leg_r", Vector3(0.155, -0.04, 0))
	var knee_l := joint(leg_l, "knee_l", Vector3(-0.02, -0.42, 0))
	var knee_r := joint(leg_r, "knee_r", Vector3(0.02, -0.42, 0))

	# pelvis + belt
	cap(hips, 0.165, 0.30, armor, Vector3(0, 0.02, 0))
	box(hips, Vector3(0.40, 0.10, 0.27), gold, Vector3(0, 0.10, 0))
	# torso + chestplate + gorget
	cap(chest, 0.215, 0.56, plate, Vector3(0, -0.06, 0))
	box(chest, Vector3(0.34, 0.20, 0.10), plate, Vector3(0, 0.02, -0.155))
	box(chest, Vector3(0.30, 0.045, 0.12), gold, Vector3(0, 0.13, -0.14))
	# cape (back = +Z)
	box(chest, Vector3(0.44, 0.68, 0.03), cloth, Vector3(0, -0.28, 0.20), Vector3(7, 0, 0))
	# helm: dome + crest + glowing visor slit
	sph(head, 0.145, plate, Vector3(0, 0.02, 0))
	box(head, Vector3(0.035, 0.13, 0.26), gold, Vector3(0, 0.13, 0.01))
	box(head, Vector3(0.15, 0.030, 0.03), acc_glow, Vector3(0, 0.0, -0.135), Vector3.ZERO, "visor")
	# pauldrons + arms
	sph(sh_l, 0.12, gold)
	sph(sh_r, 0.12, gold)
	cap(sh_l, 0.078, 0.30, armor, Vector3(0, -0.15, 0))
	cap(sh_r, 0.078, 0.30, armor, Vector3(0, -0.15, 0))
	cap(el_l, 0.068, 0.28, armor, Vector3(0, -0.14, 0))
	cap(el_r, 0.068, 0.28, armor, Vector3(0, -0.14, 0))
	# tower shield on the left hand (faces -Z): dark body, gilded rim, bright face
	box(hand_l, Vector3(0.46, 0.64, 0.045), armor, Vector3(0, -0.10, -0.09))
	box(hand_l, Vector3(0.48, 0.66, 0.02), gold, Vector3(0, -0.10, -0.105))
	box(hand_l, Vector3(0.38, 0.56, 0.03), plate, Vector3(0, -0.10, -0.118))
	sph(hand_l, 0.055, acc_glow, Vector3(0, -0.10, -0.138), Vector3.ZERO, "emblem")
	# longsword in the right hand (blade up at rest)
	cyl(hand_r, 0.022, 0.022, 0.14, gold, Vector3(0, -0.02, 0))
	box(hand_r, Vector3(0.17, 0.030, 0.05), gold, Vector3(0, 0.06, 0))
	box(hand_r, Vector3(0.050, 0.88, 0.016), blade_m, Vector3(0, 0.52, 0), Vector3.ZERO, "blade")
	# legs
	cap(leg_l, 0.098, 0.34, armor, Vector3(0, -0.19, 0))
	cap(leg_r, 0.098, 0.34, armor, Vector3(0, -0.19, 0))
	cap(knee_l, 0.078, 0.32, armor, Vector3(0, -0.16, 0))
	cap(knee_r, 0.078, 0.32, armor, Vector3(0, -0.16, 0))
	box(knee_l, Vector3(0.14, 0.09, 0.27), plate, Vector3(0, -0.335, -0.05))
	box(knee_r, Vector3(0.14, 0.09, 0.27), plate, Vector3(0, -0.335, -0.05))

	breath("chest", Vector3(1, 0, 0), 1.6, 2.1)
	breath("head", Vector3(1, 0, 0), 1.0, 2.1, 0.8)
	breath("sh_r", Vector3(0, 0, 1), 0.9, 2.1, 0.4)
	breath("root", Vector3(1, 0, 0), 0.0, 2.1, 0.0, Vector3(0, 0.008, 0))

func _define_poses() -> void:
	# combat stance
	pose("idle", {
		"hips": [0, 7, 0], "chest": [8, -7, 0], "head": [-5, 7, 0],
		"sh_l": [34, -6, -14], "el_l": [32, 0, 0],
		"sh_r": [14, 0, 20], "el_r": [24, 0, 0],
		"leg_l": [0, 0, 7, 0, 0, -0.03], "leg_r": [-4, 0, -7, 0, 0, 0.06],
		"knee_l": [6, 0, 0], "knee_r": [10, 0, 0],
		"root": [0, 0, 0, 0, -0.03, 0],
	})
	# defensive press (windup channel: deepens over the active window)
	pose("guard", {
		"hips": [0, 4, 0, 0, -0.07, 0], "chest": [13, 8, 0], "head": [2, 8, 0],
		"sh_l": [72, -22, -24], "el_l": [56, 0, 0],
		"sh_r": [4, 0, 26], "el_r": [30, 0, 0],
		"knee_l": [14, 0, 0], "knee_r": [16, 0, 0],
	})
	pose("parry", {
		"chest": [10, 16, 0], "head": [0, 12, 0],
		"sh_l": [78, -26, -8], "el_l": [12, 0, 0],
		"sh_r": [-14, 0, 30],
		"root": [0, 0, 0, 0, -0.02, -0.16],
	})
	pose("dodge_l", {
		"chest": [4, -18, 22], "head": [0, -14, -10], "hips": [0, -10, 8],
		"sh_l": [30, 0, -30], "sh_r": [20, 0, 36],
		"root": [0, 0, 0, -0.42, -0.06, 0.06], "knee_l": [20, 0, 0],
	})
	pose("dodge_r", {
		"chest": [4, 18, -22], "head": [0, 14, 10], "hips": [0, 10, -8],
		"sh_l": [30, 0, -36], "sh_r": [20, 0, 30],
		"root": [0, 0, 0, 0.42, -0.06, 0.06], "knee_r": [20, 0, 0],
	})
	pose("hit", {
		"chest": [-13, 0, -5], "head": [-14, 0, 0],
		"sh_l": [14, 0, -26], "sh_r": [0, 0, 30],
		"root": [0, 0, 0, 0, 0, 0.13],
	})
	pose("hit_big", {
		"chest": [-27, 0, -9], "head": [-20, 0, -6],
		"sh_l": [-16, 0, -44], "sh_r": [-22, 0, 48],
		"root": [0, 0, 0, 0, -0.05, 0.30], "knee_l": [16, 0, 0], "knee_r": [16, 0, 0],
	})
	# baited / whiffed — lurched forward, wide open
	pose("stumble", {
		"chest": [26, 0, 11], "head": [12, 0, 8], "hips": [6, 0, 0],
		"sh_l": [-18, 0, -34], "sh_r": [-28, 0, 28], "el_r": [10, 0, 0],
		"root": [0, 0, 0, 0.06, -0.05, -0.20],
	})
	# correctly HELD a feint — tucked, disciplined
	pose("brace", {
		"chest": [12, 0, 0], "head": [-10, 0, 0],
		"sh_l": [48, -12, -20], "el_l": [50, 0, 0], "sh_r": [8, 0, 14],
		"root": [0, 0, 0, 0, -0.05, 0],
	})
	# --- sword work ---
	pose("slash_wind", {
		"chest": [8, -30, 2], "hips": [0, -15, 0], "head": [-4, -16, 0],
		"sh_r": [62, -28, 58], "el_r": [42, 0, 0],
		"sh_l": [26, 0, -20],
		"root": [0, 0, 0, 0, -0.01, 0.06],
	})
	pose("slash_hit", {
		"chest": [12, 28, -2], "hips": [0, 13, 0], "head": [0, 18, 0],
		"sh_r": [74, 26, -38], "el_r": [8, 0, 0], "hand_r": [0, 0, -70],
		"sh_l": [22, 0, -26],
		"root": [0, 0, 0, 0, -0.03, -0.14],
	})
	pose("heavy_wind", {
		"chest": [-12, -9, 0], "head": [-14, 0, 0], "hips": [0, -6, 0],
		"sh_r": [152, 0, 16], "el_r": [32, 0, 0],
		"sh_l": [30, 0, -22],
		"root": [0, 0, 0, 0, 0.02, 0.09],
	})
	pose("heavy_hit", {
		"chest": [24, 0, 0], "head": [6, 0, 0], "hips": [4, 0, 0],
		"sh_r": [58, 0, 6], "el_r": [6, 0, 0], "hand_r": [-30, 0, 0],
		"sh_l": [22, 0, -24],
		"root": [0, 0, 0, 0, -0.07, -0.19], "knee_l": [14, 0, 0], "knee_r": [18, 0, 0],
	})
	pose("thrust_a", {
		"chest": [7, 20, 0], "hips": [0, 9, 0],
		"sh_r": [80, -8, 2], "el_r": [4, 0, 0], "hand_r": [-80, 0, 0],
		"sh_l": [28, 0, -28],
		"root": [0, 0, 0, 0, -0.02, -0.21],
	})
	pose("thrust_b", {
		"chest": [9, 10, 4], "hips": [0, 4, 0],
		"sh_r": [70, 10, 10], "el_r": [14, 0, 0], "hand_r": [-70, 0, 0],
		"sh_l": [34, 0, -22],
		"root": [0, 0, 0, 0, -0.03, -0.10],
	})
	pose("lunge", {
		"chest": [19, 13, 0], "head": [8, 8, 0], "hips": [6, 6, 0],
		"sh_r": [86, -10, 0], "el_r": [2, 0, 0], "hand_r": [-84, 0, 0],
		"sh_l": [18, 0, -38],
		"root": [0, 0, 0, 0, -0.05, -0.42], "knee_r": [24, 0, 0],
	})
	pose("slam_wind", {
		"chest": [-13, 0, 0], "head": [-16, 0, 0],
		"sh_l": [122, 0, -22], "sh_r": [122, 0, 22], "el_l": [42, 0, 0], "el_r": [42, 0, 0],
		"root": [0, 0, 0, 0, 0.04, 0.10],
	})
	pose("slam_hit", {
		"chest": [31, 0, 0], "head": [10, 0, 0], "hips": [6, 0, 0],
		"sh_l": [42, 0, -14], "sh_r": [42, 0, 14], "el_l": [8, 0, 0], "el_r": [8, 0, 0],
		"root": [0, 0, 0, 0, -0.17, -0.10], "knee_l": [26, 0, 0], "knee_r": [26, 0, 0],
	})
	pose("cast", {
		"chest": [10, 0, 0], "head": [-16, 0, 0],
		"sh_r": [36, 0, 6], "el_r": [16, 0, 0], "hand_r": [-52, 0, 0],
		"sh_l": [52, -16, -22], "el_l": [46, 0, 0],
		"root": [0, 0, 0, 0, -0.04, 0],
	})
	pose("victory", {
		"chest": [-9, 0, 0], "head": [-12, 0, 0],
		"sh_r": [166, 0, 10], "el_r": [8, 0, 0],
		"sh_l": [24, 0, -30],
	})
	pose("death", {
		"chest": [56, 0, 13], "head": [32, 0, 16], "hips": [12, 0, 0],
		"sh_l": [12, 0, -36], "sh_r": [8, 0, 36], "el_l": [10, 0, 0], "el_r": [6, 0, 0],
		"root": [0, 0, 0, 0.05, -0.62, 0.05],
		"leg_l": [0, 0, 14], "leg_r": [0, 0, -14],
		"knee_l": [-95, 0, 0], "knee_r": [-95, 0, 0],
	})

# ============================================================ acting API
## An ability committed — act it out. Returns VFX hints for the stage:
## {delay: seconds until the hit lands (impact FX timing), kind: slash|slam|thrust|cast}
func act(id: String) -> Dictionary:
	match id:
		"cleave":
			seq([{"pose": "slash_wind", "dur": 0.12, "ease": "out"},
				{"pose": "slash_hit", "dur": 0.09, "ease": "snap", "hold": 0.14}])
			flash_part("blade", Color("ffdc93"), 2.6)
			return {"delay": 0.16, "kind": "slash"}
		"rampage":
			seq([{"pose": "heavy_wind", "dur": 0.16, "ease": "out", "hold": 0.05},
				{"pose": "heavy_hit", "dur": 0.09, "ease": "snap", "hold": 0.18}])
			flash_part("blade", Color("ffdc93"), 3.4)
			return {"delay": 0.26, "kind": "slam"}
		"bloodthirst":
			seq([{"pose": "slash_wind", "dur": 0.10, "ease": "out"},
				{"pose": "lunge", "dur": 0.09, "ease": "snap", "hold": 0.16}])
			flash_part("blade", Color("d0413a"), 3.0)
			return {"delay": 0.15, "kind": "thrust"}
		"vindicate":
			seq([{"pose": "thrust_a", "dur": 0.09, "ease": "snap", "hold": 0.03},
				{"pose": "thrust_b", "dur": 0.11, "ease": "out"},
				{"pose": "thrust_a", "dur": 0.08, "ease": "snap", "hold": 0.03},
				{"pose": "thrust_b", "dur": 0.11, "ease": "out"},
				{"pose": "thrust_a", "dur": 0.08, "ease": "snap", "hold": 0.10}])
			flash_part("blade", accent, 3.2)
			return {"delay": 0.09, "kind": "thrust", "repeats": 3, "gap": 0.20}
		"avalanche":
			seq([{"pose": "slam_wind", "dur": 0.15, "ease": "out", "hold": 0.04},
				{"pose": "slam_hit", "dur": 0.10, "ease": "snap", "hold": 0.22}])
			flash_part("blade", accent, 3.0)
			return {"delay": 0.24, "kind": "slam"}
		"shockwave":
			seq([{"pose": "slam_wind", "dur": 0.13, "ease": "out"},
				{"pose": "slam_hit", "dur": 0.09, "ease": "snap", "hold": 0.26}])
			flash_part("emblem", Color("8fb8e0"), 4.0)
			return {"delay": 0.20, "kind": "slam"}
		"fortify":
			seq([{"pose": "cast", "dur": 0.24, "ease": "io", "hold": 0.5}])
			flash_part("emblem", accent, 4.0)
			return {"delay": 0.28, "kind": "cast"}
		_:
			seq([{"pose": "thrust_a", "dur": 0.10, "ease": "snap", "hold": 0.1}])
			return {"delay": 0.12, "kind": "thrust"}

## The negate moment: Warden punches the shield through the swing; Jugg sidesteps.
func negate_react(warden: bool) -> void:
	if warden:
		seq([{"pose": "parry", "dur": 0.07, "ease": "snap", "hold": 0.30}])
		flash_part("emblem", Color("ffdc93"), 5.0)
	else:
		dodge_react(true)

var _dodge_flip := false
func dodge_react(clean: bool) -> void:
	_dodge_flip = not _dodge_flip
	var p := "dodge_l" if _dodge_flip else "dodge_r"
	seq([{"pose": p, "dur": 0.08 if clean else 0.13, "ease": "snap", "hold": 0.22}])

func graze_react() -> void:
	_dodge_flip = not _dodge_flip
	seq([{"pose": "dodge_l" if _dodge_flip else "dodge_r", "dur": 0.16, "ease": "out", "hold": 0.06},
		{"pose": "hit", "dur": 0.08, "ease": "snap", "hold": 0.08}])

func hit_react(big: bool) -> void:
	jolt(1.0 if big else 0.5)
	seq([{"pose": "hit_big" if big else "hit", "dur": 0.07, "ease": "snap", "hold": 0.16 if big else 0.08}])

func stumble_react() -> void:
	jolt(0.8)
	seq([{"pose": "stumble", "dur": 0.10, "ease": "snap", "hold": 0.45}])

func brace_react() -> void:
	seq([{"pose": "brace", "dur": 0.12, "ease": "out", "hold": 0.4}])
	flash_part("visor", accent, 3.0)

func die() -> void:
	windup_amt = 0.0
	rest_in("death", 0.8)
	part_glow("visor", accent, 0.0)
	part_glow("emblem", accent, 0.0)

func win() -> void:
	windup_amt = 0.0
	rest_in("victory", 0.5)
	flash_part("blade", Color("ffdc93"), 4.0)
