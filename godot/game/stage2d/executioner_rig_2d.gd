## ExecutionerRig2D — the boss as a side-view cutout puppet (~520px, built facing
## +X; the stage flips it with scale.x = -1). A towering hooded headsman with a
## greataxe: wind-ups are the telegraph made flesh (low drag for Rend, full
## overhead for Decapitate, a planted axe + raised ritual hand for the KICKABLE
## Blood Ritual, a pointing curse for Wither, alternating high/low coils for the
## Judgment Cuts string — the feint beat coils identically, that's the lie). Kick
## connects -> stagger_anim rocks it off the ritual. Doubles as the stand-in body
## for other Twinfang bosses via variant(). Sign rule: arms NEGATIVE = forward.
class_name ExecutionerRig2D
extends PoseRig2D

var _eye_col := Color("d0413a")
var _enraged := false

func _build() -> void:
	var iron := Color(0.235, 0.225, 0.275)
	var cloth := Color(0.185, 0.175, 0.22)
	var hoodc := Color(0.15, 0.14, 0.18)
	var strap := Color("6b5426")
	var steel := Color(0.62, 0.64, 0.72)
	var skin := Color(0.40, 0.34, 0.32)

	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -205))
	# back leg
	var leg_b := joint(hips, "leg_b", Vector2(-18, 8))
	limb(leg_b, "capsule", Vector2.ZERO, Vector2(-4, 92), 20, 15, cloth)
	var shin_b := joint(leg_b, "shin_b", Vector2(-4, 92))
	limb(shin_b, "capsule", Vector2.ZERO, Vector2(2, 90), 14, 11, hoodc)
	limb(shin_b, "capsule", Vector2(2, 90), Vector2(28, 94), 11, 9, hoodc)
	# pelvis + chain belt
	limb(hips, "capsule", Vector2(0, 4), Vector2(2, 26), 26, 24, cloth)
	limb(hips, "capsule", Vector2(-20, 4), Vector2(20, 6), 6, 6, strap)
	# torso pivots at the waist — a mountain with the shoulders up top
	var chest := joint(hips, "chest", Vector2(2, -12))
	# tattered cloak behind
	poly(chest, PackedVector2Array([Vector2(-20, -150), Vector2(-58, -60), Vector2(-66, 30),
		Vector2(-44, 22), Vector2(-34, 34), Vector2(-16, 24), Vector2(-8, -20)]), hoodc.darkened(0.15))
	# back arm (behind torso) — reaches toward the haft at rest
	var arm_b := joint(chest, "arm_b", Vector2(-16, -132))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(10, 52), 16, 13, iron)
	var fore_b := joint(arm_b, "fore_b", Vector2(10, 52))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(16, 44), 12, 10, iron)
	var hand_b := joint(fore_b, "hand_b", Vector2(16, 44))
	limb(hand_b, "circle", Vector2.ZERO, Vector2.ZERO, 10, 0, skin, "ritual")
	# torso
	limb(chest, "capsule", Vector2(0, 6), Vector2(8, -142), 38, 50, iron)
	limb(chest, "capsule", Vector2(-12, -132), Vector2(24, -138), 9, 9, strap.darkened(0.3))   # yoke
	# glowing fissure across the chest (enrage / ritual feedback)
	limb(chest, "capsule", Vector2(2, -70), Vector2(18, -108), 3, 2, Color(0.09, 0.05, 0.05), "cracks")
	# head: skull mask under a tall executioner hood
	var head := joint(chest, "head", Vector2(20, -158))
	limb(head, "circle", Vector2(2, -6), Vector2.ZERO, 22, 0, skin.darkened(0.4))
	poly(head, PackedVector2Array([Vector2(-26, 6), Vector2(-30, -22), Vector2(-14, -46),
		Vector2(-30, -78), Vector2(4, -50), Vector2(20, -22), Vector2(22, 2), Vector2(6, 12),
		Vector2(-14, 13)]), hoodc)
	limb(head, "circle", Vector2(11, -8), Vector2.ZERO, 4.0, 0, _eye_col, "eye")
	# front leg
	var leg_f := joint(hips, "leg_f", Vector2(20, 8))
	limb(leg_f, "capsule", Vector2.ZERO, Vector2(4, 92), 21, 15, cloth)
	var shin_f := joint(leg_f, "shin_f", Vector2(4, 92))
	limb(shin_f, "capsule", Vector2.ZERO, Vector2(2, 90), 15, 11, hoodc)
	limb(shin_f, "capsule", Vector2(2, 90), Vector2(30, 94), 11, 9, hoodc)
	# front arm carries the axe
	var arm_f := joint(chest, "arm_f", Vector2(16, -138))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(12, 56), 17, 13, iron)
	var fore_f := joint(arm_f, "fore_f", Vector2(12, 56))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(18, 46), 13, 10, iron)
	var hand_f := joint(fore_f, "hand_f", Vector2(18, 46))
	limb(hand_f, "circle", Vector2.ZERO, Vector2.ZERO, 11, 0, skin)
	# THE AXE — haft up from the grip, crescent head at the top (+X side)
	var axe := joint(hand_f, "axe", Vector2.ZERO)
	limb(axe, "capsule", Vector2(0, 26), Vector2(0, -170), 6, 5, strap.darkened(0.35))
	poly(axe, PackedVector2Array([Vector2(2, -172), Vector2(34, -168), Vector2(58, -140),
		Vector2(62, -104), Vector2(38, -120), Vector2(4, -112)]), steel, "blade")
	poly(axe, PackedVector2Array([Vector2(-2, -168), Vector2(-24, -156), Vector2(-2, -146)]),
		steel.darkened(0.35))   # back spike
	limb(axe, "capsule", Vector2(0, -170), Vector2(0, -196), 4, 3, strap.darkened(0.35))

	breath("chest", 1.7, 1.6)
	breath("head", 1.1, 1.6, 0.7)
	breath("arm_f", 1.0, 1.6, 0.3)
	breath("root", 0.0, 1.6, 0.0, Vector2(0, 3.5))

## Reskin the same silhouette as the other Twinfang boss until it gets its own puppet.
func variant(boss_id: String) -> void:
	match boss_id:
		"warden":
			scale *= 0.92
			_eye_col = Color("e6b463")
		_:
			pass
	part_glow("eye", _eye_col, 0.6)

func _define_poses() -> void:
	# hunched, axe resting back over the shoulder
	pose("idle", {
		"hips": [0, 0, 4], "chest": [10, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-12, 0, 0], "fore_f": [-24, 0, 0], "axe": [30, 0, 0],
		"arm_b": [-16, 0, 0], "fore_b": [-26, 0, 0],
		"leg_f": [-6, 0, 0], "shin_f": [8, 0, 0], "leg_b": [10, 0, 0], "shin_b": [6, 0, 0],
	})
	# --- telegraph wind-ups (deepened by the stage every frame) ---
	pose("windup_light", {
		"chest": [-10, 0, 0], "head": [-4, 0, 0],
		"arm_f": [34, 0, 0], "fore_f": [-30, 0, 0], "axe": [64, 0, 0],
		"arm_b": [-10, 0, 0],
		"root": [0, -16, 4],
	})
	pose("strike_light", {
		"chest": [20, 0, 0], "head": [2, 0, 0],
		"arm_f": [-78, 0, 0], "fore_f": [-16, 0, 0], "axe": [96, 0, 0],
		"arm_b": [-30, 0, 0],
		"root": [0, 30, -4], "leg_b": [22, 0, 0],
	})
	pose("windup_heavy", {
		"chest": [-22, 0, 0], "head": [-16, 0, 0],
		"arm_f": [-148, 0, 0], "fore_f": [-38, 0, 0], "axe": [-14, 0, 0],
		"arm_b": [-120, 0, 0], "fore_b": [-40, 0, 0],
		"root": [0, -12, 8], "hips": [0, 0, -6],
	})
	pose("strike_heavy", {
		"chest": [36, 0, 0], "head": [10, 0, 0],
		"arm_f": [-58, 0, 0], "fore_f": [26, 0, 0], "axe": [148, 0, 0],
		"arm_b": [-20, 0, 0],
		"root": [0, 34, 8], "leg_f": [-10, 0, 0], "shin_f": [16, 0, 0],
		"leg_b": [18, 0, 0], "hips": [0, 0, 8],
	})
	# Blood Ritual: axe planted dead, free hand raised — KICK THIS
	pose("windup_channel", {
		"chest": [-6, 0, 0], "head": [-14, 0, 0],
		"arm_f": [-30, 0, 0], "fore_f": [16, 0, 0], "axe": [86, 0, 0],
		"arm_b": [-165, 0, 0], "fore_b": [-30, 0, 0],
		"root": [0, -8, 4], "hips": [0, 0, 4],
	})
	# Wither: the pointing curse
	pose("windup_curse", {
		"chest": [2, 0, 0], "head": [-2, 0, 0],
		"arm_b": [-100, 0, 0], "fore_b": [-72, 0, 0],
		"arm_f": [-30, 0, 0], "fore_f": [-60, 0, 0], "axe": [46, 0, 0],
		"root": [0, -4, 0],
	})
	# Judgment Cuts string: alternating high / low coils
	pose("windup_cut_hi", {
		"chest": [-14, 0, 0], "head": [-8, 0, 0],
		"arm_f": [-118, 0, 0], "fore_f": [-30, 0, 0], "axe": [-6, 0, 0],
		"arm_b": [-40, 0, 0],
		"root": [0, -12, 2],
	})
	pose("windup_cut_lo", {
		"chest": [-6, 0, 0],
		"arm_f": [40, 0, 0], "fore_f": [-24, 0, 0], "axe": [58, 0, 0],
		"arm_b": [-16, 0, 0],
		"root": [0, -14, 4],
	})
	pose("strike_cut_hi", {
		"chest": [22, 0, 0], "head": [4, 0, 0],
		"arm_f": [-64, 0, 0], "fore_f": [4, 0, 0], "axe": [118, 0, 0],
		"root": [0, 26, -2], "leg_b": [18, 0, 0],
	})
	pose("strike_cut_lo", {
		"chest": [12, 0, 0],
		"arm_f": [-96, 0, 0], "fore_f": [-24, 0, 0], "axe": [70, 0, 0],
		"root": [0, 26, -6], "leg_b": [16, 0, 0],
	})
	# --- reacts ---
	pose("flinch", {
		"chest": [-7, 0, 0], "head": [-12, 0, 0],
		"root": [0, -8, 2],
	})
	pose("recoil", {
		"chest": [-22, 0, 0], "head": [-20, 0, 0],
		"arm_f": [-16, 0, 0], "axe": [16, 0, 0], "arm_b": [-56, 0, 0],
		"root": [0, -26, 4],
	})
	pose("stagger", {
		"chest": [-32, 0, 0], "head": [-24, 0, 0],
		"arm_f": [-4, 0, 0], "fore_f": [-40, 0, 0], "axe": [10, 0, 0],
		"arm_b": [-80, 0, 0], "fore_b": [-30, 0, 0],
		"root": [0, -44, 8], "leg_f": [-8, 0, 0], "shin_f": [14, 0, 0],
		"leg_b": [20, 0, 0], "hips": [0, 0, 6],
	})
	pose("victory", {
		"chest": [-14, 0, 0], "head": [-12, 0, 0],
		"arm_f": [-155, 0, 0], "fore_f": [-20, 0, 0], "axe": [-4, 0, 0],
		"arm_b": [-60, 0, 0],
	})
	pose("death", {
		"hips": [0, 0, 66], "chest": [48, 0, 0], "head": [28, 0, 0],
		"arm_f": [-40, 0, 0], "fore_f": [40, 0, 0], "axe": [150, 0, 0],
		"arm_b": [-16, 0, 0], "fore_b": [10, 0, 0],
		"leg_f": [-52, 0, 0], "shin_f": [96, 0, 0], "leg_b": [58, 0, 0], "shin_b": [30, 0, 0],
		"root": [0, 0, 44],
	})

# ============================================================ acting API
## Telegraph -> body language, every frame. kind: light|heavy|channel|curse|cut_hi|cut_lo
func windup(kind: String, amt: float) -> void:
	var p := "windup_light"
	match kind:
		"heavy": p = "windup_heavy"
		"channel": p = "windup_channel"
		"curse": p = "windup_curse"
		"cut_hi": p = "windup_cut_hi"
		"cut_lo": p = "windup_cut_lo"
	set_windup(p, amt)
	if kind == "channel":
		part_glow("ritual", Color("d0413a"), 0.2 + 0.8 * amt)
		part_glow("cracks", Color("d0413a"), 0.15 + 0.5 * amt)
	elif kind == "curse":
		part_glow("ritual", Color("8a5bd6"), 0.2 + 0.7 * amt)

## The swing lands (or is evaded) — release the coil.
func swing(kind: String) -> void:
	clear_windup()
	_ritual_off()
	var p := "strike_light"
	var hold := 0.14
	match kind:
		"heavy": p = "strike_heavy"; hold = 0.22
		"cut_hi": p = "strike_cut_hi"; hold = 0.10
		"cut_lo": p = "strike_cut_lo"; hold = 0.10
	seq([{"pose": p, "dur": 0.07, "ease": "snap", "hold": hold}])

## The curse fires (Wither/Hex lands — unavoidable chip, not a swing).
func curse_release() -> void:
	clear_windup()
	_ritual_off()
	flash_part("ritual", Color("8a5bd6"), 1.0)
	seq([{"pose": "windup_curse", "dur": 0.06, "ease": "snap", "hold": 0.10}])

func flinch(big: bool) -> void:
	jolt(0.9 if big else 0.45)
	if _seq.is_empty() and windup_amt < 0.35:
		seq([{"pose": "flinch", "dur": 0.06, "ease": "snap", "hold": 0.05}])
	flash_part("eye", _eye_col, 1.0)

func recoil() -> void:
	clear_windup()
	_ritual_off()
	jolt(1.1)
	seq([{"pose": "recoil", "dur": 0.08, "ease": "snap", "hold": 0.26}])

## Kicked off the ritual (or any interrupt): rocked back hard.
func stagger_anim() -> void:
	clear_windup()
	_ritual_off()
	jolt(1.4)
	seq([{"pose": "stagger", "dur": 0.09, "ease": "snap", "hold": 0.55}])

func heal_flash() -> void:
	flash_part("cracks", Color("83c98d"), 1.0)
	flash_part("ritual", Color("83c98d"), 1.0)

func set_enrage(on: bool) -> void:
	if on == _enraged:
		return
	_enraged = on
	breath_scale = 1.9 if on else 1.0
	part_glow("eye", Color("d0413a"), 1.0 if on else 0.6)
	part_glow("cracks", Color("d0413a"), 0.8 if on else 0.0)
	part_glow("blade", Color("d0413a"), 0.35 if on else 0.0)

func die() -> void:
	clear_windup()
	_ritual_off()
	breath_scale = 0.0
	rest_in("death", 1.0)
	part_glow("eye", _eye_col, 0.0)
	part_glow("blade", _eye_col, 0.0)

func win() -> void:
	clear_windup()
	rest_in("victory", 0.55)
	flash_part("eye", _eye_col, 1.0)

func _ritual_off() -> void:
	if not _enraged:
		part_glow("ritual", _eye_col, 0.0)
		part_glow("cracks", _eye_col, 0.0)
