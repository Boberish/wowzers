## GatekeeperRig — the boss as a physical PRESENCE: a hulking stone gate-warden
## (a slab gate strapped to its back, ember eyes, gold-cracked hide). Built facing
## -Z, ~2.7m tall. Its wind-ups ARE the telegraph made flesh: the stage drives
## windup(kind, amt) every frame from the live telegraph, so the body coils exactly
## as the timer runs — light jab / heavy overhead / two-arm crush all read apart,
## strings coil beat-by-beat on alternating fists, and a heal cast folds inward.
## Doubles (scaled/tinted via variant()) as the stand-in body for every Bulwark boss
## until each gets its own sculpt.
class_name GatekeeperRig
extends PoseRig

var _stone: StandardMaterial3D
var _eyes_m: StandardMaterial3D
var _crack_m: StandardMaterial3D
var _eye_col: Color = Color("e6b463")
var _enraged := false

func _build() -> void:
	_stone = mat(Color(0.185, 0.185, 0.21), 0.88, 0.04)
	var dark := mat(Color(0.10, 0.095, 0.12), 0.7, 0.3)
	var gold := mat(Color("8a6a30"), 0.42, 0.85)
	_eyes_m = mat(Color(0.1, 0.08, 0.05), 0.5, 0.0, _eye_col, 2.4)
	_crack_m = mat(Color(0.135, 0.13, 0.145), 0.7, 0.0, Color("d0413a"), 0.0)

	var root := joint(self, "root", Vector3.ZERO)
	var hips := joint(root, "hips", Vector3(0, 1.28, 0))
	var chest := joint(hips, "chest", Vector3(0, 0.50, 0))
	var head := joint(chest, "head", Vector3(0, 0.54, -0.10))
	var sh_l := joint(chest, "sh_l", Vector3(-0.68, 0.30, 0))
	var sh_r := joint(chest, "sh_r", Vector3(0.68, 0.30, 0))
	var el_l := joint(sh_l, "el_l", Vector3(0, -0.54, 0))
	var el_r := joint(sh_r, "el_r", Vector3(0, -0.54, 0))
	var fist_l := joint(el_l, "fist_l", Vector3(0, -0.52, 0))
	var fist_r := joint(el_r, "fist_r", Vector3(0, -0.52, 0))
	var leg_l := joint(hips, "leg_l", Vector3(-0.30, -0.12, 0))
	var leg_r := joint(hips, "leg_r", Vector3(0.30, -0.12, 0))
	var knee_l := joint(leg_l, "knee_l", Vector3(-0.03, -0.55, 0))
	var knee_r := joint(leg_r, "knee_r", Vector3(0.03, -0.55, 0))

	# pelvis + girdle
	box(hips, Vector3(0.80, 0.44, 0.52), _stone, Vector3(0, -0.02, 0))
	box(hips, Vector3(0.82, 0.08, 0.54), dark, Vector3(0, 0.16, 0))
	# barrel torso + fissure cracks (near-invisible until they burn: enrage/heal)
	cap(chest, 0.60, 1.05, _stone, Vector3(0, -0.06, -0.04))
	box(chest, Vector3(0.035, 0.42, 0.015), _crack_m, Vector3(-0.16, 0.02, -0.575), Vector3(0, 0, 18), "cracks")
	box(chest, Vector3(0.030, 0.32, 0.015), _crack_m, Vector3(0.20, -0.08, -0.565), Vector3(0, 0, -14))
	box(chest, Vector3(0.030, 0.24, 0.015), _crack_m, Vector3(0.02, -0.30, -0.56), Vector3(0, 0, 40))
	# THE GATE — a great slab strapped to its back (silhouette + lore in one mesh;
	# hinge bars tucked inside the slab's width so they don't ring the torso from the front)
	box(chest, Vector3(1.34, 1.58, 0.13), dark, Vector3(0, 0.10, 0.56), Vector3(-7, 0, 0))
	box(chest, Vector3(1.28, 0.10, 0.16), gold, Vector3(0, 0.62, 0.62), Vector3(-7, 0, 0))
	box(chest, Vector3(1.28, 0.10, 0.16), gold, Vector3(0, -0.44, 0.49), Vector3(-7, 0, 0))
	# skull: dome + jaw + horns + ember eyes
	sph(head, 0.26, _stone, Vector3(0, 0.03, 0))
	box(head, Vector3(0.30, 0.14, 0.26), _stone, Vector3(0, -0.13, -0.06))
	cyl(head, 0.01, 0.075, 0.42, gold, Vector3(-0.24, 0.19, 0.02), Vector3(0, 0, 38))
	cyl(head, 0.01, 0.075, 0.42, gold, Vector3(0.24, 0.19, 0.02), Vector3(0, 0, -38))
	sph(head, 0.050, _eyes_m, Vector3(-0.10, 0.03, -0.225), Vector3.ZERO, "eye_l")
	sph(head, 0.050, _eyes_m, Vector3(0.10, 0.03, -0.225), Vector3.ZERO, "eye_r")
	# colossal arms
	sph(sh_l, 0.30, _stone)
	sph(sh_r, 0.30, _stone)
	cap(sh_l, 0.195, 0.62, _stone, Vector3(0, -0.28, 0))
	cap(sh_r, 0.195, 0.62, _stone, Vector3(0, -0.28, 0))
	cap(el_l, 0.175, 0.60, _stone, Vector3(0, -0.26, 0))
	cap(el_r, 0.175, 0.60, _stone, Vector3(0, -0.26, 0))
	sph(fist_l, 0.27, _stone, Vector3(0, -0.06, 0))
	sph(fist_r, 0.27, _stone, Vector3(0, -0.06, 0))
	box(fist_l, Vector3(0.30, 0.12, 0.30), gold, Vector3(0, -0.18, -0.04))
	box(fist_r, Vector3(0.30, 0.12, 0.30), gold, Vector3(0, -0.18, -0.04))
	# stumpy legs
	cap(leg_l, 0.225, 0.52, _stone, Vector3(0, -0.24, 0))
	cap(leg_r, 0.225, 0.52, _stone, Vector3(0, -0.24, 0))
	cap(knee_l, 0.185, 0.50, _stone, Vector3(0, -0.24, 0))
	cap(knee_r, 0.185, 0.50, _stone, Vector3(0, -0.24, 0))
	box(knee_l, Vector3(0.32, 0.16, 0.46), _stone, Vector3(0, -0.52, -0.06))
	box(knee_r, Vector3(0.32, 0.16, 0.46), _stone, Vector3(0, -0.52, -0.06))

	breath("chest", Vector3(1, 0, 0), 2.4, 1.55)
	breath("head", Vector3(1, 0, 0), 1.4, 1.55, 0.7)
	breath("sh_l", Vector3(0, 0, 1), 1.0, 1.55, 0.3)
	breath("sh_r", Vector3(0, 0, 1), -1.0, 1.55, 0.3)
	breath("root", Vector3(1, 0, 0), 0.0, 1.55, 0.0, Vector3(0, 0.02, 0))

## Reskin the same body as another boss until each gets its own sculpt.
func variant(boss_id: String) -> void:
	match boss_id:
		"warcaller":
			scale = Vector3.ONE * 0.94
			_eye_col = Color("df8f3c")
		"colossus":
			scale = Vector3.ONE * 1.18
			_eye_col = Color("8fb8e0")
		"duelist":
			scale = Vector3(0.78, 0.86, 0.78)
			_eye_col = Color("b072c9")
			_stone.albedo_color = Color(0.20, 0.17, 0.22)
		"devourer":
			scale = Vector3(1.12, 1.02, 1.12)
			_eye_col = Color("d0413a")
			_stone.albedo_color = Color(0.22, 0.16, 0.16)
		_:
			pass
	_eyes_m.emission = _eye_col

func _define_poses() -> void:
	# knuckle-heavy hunch
	pose("idle", {
		"chest": [17, 0, 0], "head": [-15, 0, 0],
		"sh_l": [9, 0, -13], "sh_r": [9, 0, 13],
		"el_l": [16, 0, 0], "el_r": [16, 0, 0],
		"knee_l": [10, 0, 0], "knee_r": [10, 0, 0],
		"root": [0, 0, 0, 0, -0.06, 0],
	})
	# --- telegraph wind-ups (held + deepened by the stage each frame) ---
	pose("windup_light", {
		"chest": [10, 24, 0], "head": [-10, -16, 0],
		"sh_r": [-52, 0, 20], "el_r": [64, 0, 0],
		"sh_l": [30, 0, -18], "el_l": [40, 0, 0],
		"root": [0, 0, 0, 0.05, -0.02, 0.08],
	})
	pose("windup_heavy", {
		"chest": [-13, 17, 0], "head": [-22, 0, 0],
		"sh_r": [160, 0, 26], "el_r": [36, 0, 0],
		"sh_l": [24, 0, -24],
		"root": [0, 0, 0, 0, 0.06, 0.10], "knee_l": [14, 0, 0], "knee_r": [14, 0, 0],
	})
	pose("windup_crush", {
		"chest": [-25, 0, 0], "head": [-30, 0, 0],
		"sh_l": [168, 0, -30], "sh_r": [168, 0, 30],
		"el_l": [26, 0, 0], "el_r": [26, 0, 0],
		"root": [0, 0, 0, 0, 0.11, 0.16], "knee_l": [16, 0, 0], "knee_r": [16, 0, 0],
	})
	pose("windup_channel", {
		"chest": [23, 0, 0], "head": [-30, 0, 0],
		"sh_l": [44, 28, -18], "sh_r": [44, -28, 18],
		"el_l": [72, 0, 0], "el_r": [72, 0, 0],
		"root": [0, 0, 0, 0, -0.10, 0],
	})
	pose("windup_jab_l", {
		"chest": [12, -20, 0], "head": [-12, 12, 0],
		"sh_l": [-46, 0, -18], "el_l": [58, 0, 0],
		"sh_r": [36, 0, 20], "el_r": [50, 0, 0],
		"root": [0, 0, 0, -0.05, -0.02, 0.06],
	})
	pose("windup_jab_r", {
		"chest": [12, 20, 0], "head": [-12, -12, 0],
		"sh_r": [-46, 0, 18], "el_r": [58, 0, 0],
		"sh_l": [36, 0, -20], "el_l": [50, 0, 0],
		"root": [0, 0, 0, 0.05, -0.02, 0.06],
	})
	# --- strikes ---
	pose("strike_light", {
		"chest": [14, -19, 0], "head": [-6, 10, 0],
		"sh_r": [76, -6, 6], "el_r": [8, 0, 0],
		"sh_l": [22, 0, -16],
		"root": [0, 0, 0, 0, -0.02, -0.26],
	})
	pose("strike_heavy", {
		"chest": [36, -7, 0], "head": [6, 0, 0],
		"sh_r": [58, 0, 8], "el_r": [10, 0, 0],
		"sh_l": [20, 0, -20],
		"root": [0, 0, 0, 0, -0.11, -0.32], "knee_l": [18, 0, 0], "knee_r": [22, 0, 0],
	})
	pose("strike_crush", {
		"chest": [42, 0, 0], "head": [10, 0, 0],
		"sh_l": [62, 0, -10], "sh_r": [62, 0, 10],
		"el_l": [12, 0, 0], "el_r": [12, 0, 0],
		"root": [0, 0, 0, 0, -0.20, -0.28], "knee_l": [26, 0, 0], "knee_r": [26, 0, 0],
	})
	pose("strike_jab_l", {
		"chest": [14, 22, 0], "sh_l": [74, 6, -6], "el_l": [8, 0, 0],
		"sh_r": [30, 0, 18], "root": [0, 0, 0, 0.03, -0.02, -0.22],
	})
	pose("strike_jab_r", {
		"chest": [14, -22, 0], "sh_r": [74, -6, 6], "el_r": [8, 0, 0],
		"sh_l": [30, 0, -18], "root": [0, 0, 0, -0.03, -0.02, -0.22],
	})
	# --- reacts ---
	pose("flinch", {
		"chest": [7, 0, -4], "head": [-24, 7, 0],
		"root": [0, 0, 0, 0, 0.02, 0.10],
	})
	pose("recoil", {
		"chest": [-19, 0, -7], "head": [-32, -12, 0],
		"sh_l": [-18, 0, -42], "sh_r": [-32, 0, 44],
		"el_l": [20, 0, 0], "el_r": [24, 0, 0],
		"root": [0, 0, 0, 0.04, 0.03, 0.32],
	})
	pose("stagger", {
		"chest": [-31, 0, -11], "head": [-34, 14, 0],
		"sh_l": [-26, 0, -52], "sh_r": [-30, 0, 55],
		"root": [0, 0, 0, 0.06, -0.09, 0.46], "knee_l": [26, 0, 0], "knee_r": [30, 0, 0],
	})
	pose("victory", {
		"chest": [-17, 0, 0], "head": [-26, 0, 0],
		"sh_l": [152, 0, -32], "sh_r": [152, 0, 32],
		"el_l": [26, 0, 0], "el_r": [26, 0, 0],
	})
	pose("death", {
		"chest": [68, 0, 7], "head": [38, 0, 10], "hips": [14, 0, 0],
		"sh_l": [46, 0, -30], "sh_r": [42, 0, 34],
		"el_l": [14, 0, 0], "el_r": [10, 0, 0],
		"root": [0, 0, 0, 0.08, -0.88, -0.18],
		"knee_l": [-70, 0, 0], "knee_r": [-70, 0, 0],
	})

# ============================================================ acting API
## Telegraph -> body language, every frame. kind: light|heavy|crush|heal|jab_l|jab_r
func windup(kind: String, amt: float) -> void:
	var p := "windup_light"
	match kind:
		"heavy": p = "windup_heavy"
		"crush": p = "windup_crush"
		"heal": p = "windup_channel"
		"jab_l": p = "windup_jab_l"
		"jab_r": p = "windup_jab_r"
	set_windup(p, amt)
	if kind == "heal":
		part_glow("cracks", Color("83c98d"), 1.2 + 1.6 * amt)

## The swing lands (or is answered) — release the coil into the strike.
func swing(kind: String) -> void:
	clear_windup()
	if not _enraged:
		part_glow("cracks", Color("d0413a"), 0.0)
	var p := "strike_light"
	var hold := 0.16
	match kind:
		"heavy": p = "strike_heavy"; hold = 0.22
		"crush": p = "strike_crush"; hold = 0.26
		"jab_l": p = "strike_jab_l"; hold = 0.10
		"jab_r": p = "strike_jab_r"; hold = 0.10
	seq([{"pose": p, "dur": 0.07, "ease": "snap", "hold": hold}])

## Untelegraphed melee chip (Devourer): a lazy backhand, no wind-up.
var _jab_flip := false
func melee_swipe() -> void:
	if windup_amt > 0.3:
		return          # mid-coil on a real telegraph — don't break the read
	_jab_flip = not _jab_flip
	seq([{"pose": "strike_jab_l" if _jab_flip else "strike_jab_r", "dur": 0.09, "ease": "snap", "hold": 0.06}])

func flinch(big: bool) -> void:
	jolt(0.9 if big else 0.45)
	if _seq.is_empty() and windup_amt < 0.3:
		seq([{"pose": "flinch", "dur": 0.06, "ease": "snap", "hold": 0.05}])
	flash_part("eye_l", _eye_col, 4.0)
	flash_part("eye_r", _eye_col, 4.0)

## Parried/dodged — the riposte rocks it back hard.
func recoil() -> void:
	clear_windup()
	jolt(1.2)
	seq([{"pose": "recoil", "dur": 0.08, "ease": "snap", "hold": 0.28}])

func stagger_anim() -> void:
	clear_windup()
	jolt(1.4)
	seq([{"pose": "stagger", "dur": 0.10, "ease": "snap", "hold": 0.55}])

func heal_flash() -> void:
	flash_part("cracks", Color("83c98d"), 3.0)

func set_enrage(on: bool) -> void:
	if on == _enraged:
		return
	_enraged = on
	breath_scale = 1.9 if on else 1.0
	part_glow("eye_l", Color("d0413a") if on else _eye_col, 4.5 if on else 2.4)
	part_glow("eye_r", Color("d0413a") if on else _eye_col, 4.5 if on else 2.4)
	part_glow("cracks", Color("d0413a"), 2.2 if on else 0.0)

func die() -> void:
	clear_windup()
	breath_scale = 0.0
	rest_in("death", 1.1)
	part_glow("eye_l", _eye_col, 0.0)
	part_glow("eye_r", _eye_col, 0.0)
	part_glow("cracks", _eye_col, 0.0)

func win() -> void:
	clear_windup()
	rest_in("victory", 0.6)
	flash_part("eye_l", _eye_col, 5.0)
	flash_part("eye_r", _eye_col, 5.0)
