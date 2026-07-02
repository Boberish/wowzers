## RiftmawRig2D — Vorathek, the Riftmaw: the first raid Seal as a side-view puppet
## (~620px, built facing +X; the stage flips it). A hulking rift-beast that is
## mostly MAW — a huge jawed head slung low between crystal-spined shoulders, two
## talon arms. Wind-up per telegraph: one talon coiled = Rending Talon, both
## overhead = Riftmaw Crush, jaw wrenched OPEN + throat glow = Devouring Chant
## (kick it!), rearing spread-wide = Rift Cataclysm, a thrust glare = Baleful
## Curse / Riftrot, alternating talon coils = Void Volley beats.
class_name RiftmawRig2D
extends PoseRig2D

var _eye_col := Color("b072c9")
var _enraged := false

func _build() -> void:
	var hide := Color(0.21, 0.19, 0.26)
	var belly := Color(0.26, 0.235, 0.30)
	var dark := Color(0.155, 0.14, 0.20)
	var claw := Color(0.72, 0.70, 0.78)
	var crystal := Color("6a4a9e")

	var root := joint(self, "root", Vector2.ZERO)
	var hips := joint(root, "hips", Vector2(0, -190))
	var leg_b := joint(hips, "leg_b", Vector2(-30, 0))
	limb(leg_b, "capsule", Vector2.ZERO, Vector2(-8, 100), 26, 18, dark)
	var shin_b := joint(leg_b, "shin_b", Vector2(-8, 100))
	limb(shin_b, "capsule", Vector2.ZERO, Vector2(4, 84), 17, 13, dark)
	limb(shin_b, "capsule", Vector2(4, 84), Vector2(34, 90), 13, 10, dark)
	limb(hips, "capsule", Vector2(-6, 0), Vector2(4, 26), 34, 30, hide)
	# torso: a low hunched mass, crystal spines up the back
	var chest := joint(hips, "chest", Vector2(4, -16))
	limb(chest, "capsule", Vector2(-4, 8), Vector2(14, -138), 46, 56, hide)
	limb(chest, "capsule", Vector2(4, -30), Vector2(16, -110), 34, 40, belly)
	poly(chest, PackedVector2Array([Vector2(-38, -150), Vector2(-64, -196), Vector2(-46, -142),
		Vector2(-76, -158), Vector2(-52, -118), Vector2(-84, -108), Vector2(-50, -86)]),
		crystal, "spines")
	# back talon arm
	var arm_b := joint(chest, "arm_b", Vector2(-14, -118))
	limb(arm_b, "capsule", Vector2.ZERO, Vector2(12, 58), 18, 14, hide)
	var fore_b := joint(arm_b, "fore_b", Vector2(12, 58))
	limb(fore_b, "capsule", Vector2.ZERO, Vector2(18, 50), 13, 10, hide)
	var hand_b := joint(fore_b, "hand_b", Vector2(18, 50))
	limb(hand_b, "blade", Vector2(0, -4), Vector2(30, 6), 6, 0, claw)
	limb(hand_b, "blade", Vector2(2, 6), Vector2(26, 18), 5, 0, claw)
	# THE MAW — a head that is mostly jaw, slung forward and low
	var head := joint(chest, "head", Vector2(34, -128))
	limb(head, "circle", Vector2(10, -14), Vector2.ZERO, 30, 0, hide)
	poly(head, PackedVector2Array([Vector2(-8, -34), Vector2(30, -30), Vector2(62, -12),
		Vector2(56, 0), Vector2(20, -6), Vector2(-6, -4)]), hide)            # snout
	var jaw := joint(head, "jaw", Vector2(4, 4))
	poly(jaw, PackedVector2Array([Vector2(-4, 2), Vector2(28, 8), Vector2(56, 20),
		Vector2(44, 30), Vector2(12, 26), Vector2(-6, 16)]), dark)
	# teeth + throat glow (the Chant burns in its gullet)
	poly(head, PackedVector2Array([Vector2(50, -8), Vector2(56, 4), Vector2(44, -2)]), claw)
	poly(head, PackedVector2Array([Vector2(34, -6), Vector2(40, 6), Vector2(28, 0)]), claw)
	poly(jaw, PackedVector2Array([Vector2(40, 14), Vector2(48, 20), Vector2(34, 22)]), claw)
	limb(head, "circle", Vector2(22, -2), Vector2.ZERO, 8, 0, Color(0.12, 0.06, 0.10), "throat")
	limb(head, "circle", Vector2(6, -22), Vector2.ZERO, 5.5, 0, _eye_col, "eye")
	limb(head, "circle", Vector2(20, -18), Vector2.ZERO, 4.0, 0, _eye_col, "eye2")
	# front talon arm (drawn over)
	var leg_f := joint(hips, "leg_f", Vector2(30, 0))
	limb(leg_f, "capsule", Vector2.ZERO, Vector2(6, 100), 27, 18, dark)
	var shin_f := joint(leg_f, "shin_f", Vector2(6, 100))
	limb(shin_f, "capsule", Vector2.ZERO, Vector2(4, 84), 18, 13, dark)
	limb(shin_f, "capsule", Vector2(4, 84), Vector2(36, 90), 13, 10, dark)
	var arm_f := joint(chest, "arm_f", Vector2(16, -110))
	limb(arm_f, "capsule", Vector2.ZERO, Vector2(14, 62), 20, 15, hide)
	var fore_f := joint(arm_f, "fore_f", Vector2(14, 62))
	limb(fore_f, "capsule", Vector2.ZERO, Vector2(20, 52), 14, 11, hide)
	var hand_f := joint(fore_f, "hand_f", Vector2(20, 52))
	limb(hand_f, "blade", Vector2(0, -4), Vector2(36, 4), 7, 0, claw, "talon")
	limb(hand_f, "blade", Vector2(2, 8), Vector2(30, 20), 6, 0, claw)

	breath("chest", 1.9, 1.45)
	breath("head", 1.3, 1.45, 0.6)
	breath("jaw", 2.2, 1.45, 1.1)
	breath("root", 0.0, 1.45, 0.0, Vector2(0, 4.0))

func _define_poses() -> void:
	pose("idle", {"chest": [12, 0, 0], "head": [-6, 0, 0], "jaw": [6, 0, 0],
		"arm_f": [-14, 0, 0], "fore_f": [-20, 0, 0],
		"arm_b": [-8, 0, 0], "fore_b": [-14, 0, 0],
		"leg_f": [-4, 0, 0], "leg_b": [6, 0, 0], "root": [0, 0, 4]})
	# Rending Talon: one claw coiled back high
	pose("windup_heavy", {"chest": [-12, 0, 0], "head": [-10, 0, 0],
		"arm_f": [64, 0, 0], "fore_f": [-88, 0, 0], "root": [0, -18, 6]})
	pose("strike_heavy", {"chest": [24, 0, 0], "head": [6, 0, 0], "jaw": [14, 0, 0],
		"arm_f": [-92, 0, 0], "fore_f": [-4, 0, 0], "root": [0, 34, -4], "leg_b": [18, 0, 0]})
	# Riftmaw Crush: BOTH talons overhead
	pose("windup_crush", {"chest": [-24, 0, 0], "head": [-16, 0, 0], "jaw": [18, 0, 0],
		"arm_f": [-150, 0, 0], "fore_f": [-40, 0, 0],
		"arm_b": [-142, 0, 0], "fore_b": [-36, 0, 0],
		"root": [0, -16, 10], "hips": [0, 0, -8]})
	pose("strike_crush", {"chest": [34, 0, 0], "head": [10, 0, 0], "jaw": [24, 0, 0],
		"arm_f": [-60, 0, 0], "fore_f": [22, 0, 0],
		"arm_b": [-54, 0, 0], "fore_b": [18, 0, 0],
		"root": [0, 36, 8], "hips": [0, 0, 10], "leg_f": [-8, 0, 0]})
	# Devouring Chant: jaw wrenched open, throat burning — KICK IT
	pose("windup_channel", {"chest": [-8, 0, 0], "head": [-22, 0, 0], "jaw": [42, 0, 0],
		"arm_f": [-24, 0, 0], "fore_f": [-40, 0, 0],
		"arm_b": [-18, 0, 0], "fore_b": [-34, 0, 0],
		"root": [0, -10, 2]})
	# Rift Cataclysm: rears back, arms spread wide
	pose("windup_nova", {"chest": [-34, 0, 0], "head": [-24, 0, 0], "jaw": [30, 0, 0],
		"arm_f": [-110, 0, 20], "fore_f": [-70, 0, 0],
		"arm_b": [-104, 0, -16], "fore_b": [-64, 0, 0],
		"root": [0, -30, 14], "hips": [0, 0, -10], "leg_f": [-10, 0, 0], "leg_b": [14, 0, 0]})
	pose("strike_nova", {"chest": [28, 0, 0], "head": [8, 0, 0], "jaw": [26, 0, 0],
		"arm_f": [-40, 0, 0], "fore_f": [10, 0, 0],
		"arm_b": [-36, 0, 0], "fore_b": [8, 0, 0],
		"root": [0, 30, 6], "hips": [0, 0, 8]})
	# Baleful Curse / Riftrot: head thrust forward, glare
	pose("windup_curse", {"chest": [6, 0, 0], "head": [10, 0, 6], "jaw": [-4, 0, 0],
		"root": [0, -6, 0]})
	# Void Volley: alternating talon coils
	pose("windup_cut_hi", {"chest": [-14, 0, 0], "arm_f": [-120, 0, 0], "fore_f": [-36, 0, 0],
		"root": [0, -12, 2]})
	pose("windup_cut_lo", {"chest": [-6, 0, 0], "arm_b": [56, 0, 0], "fore_b": [-80, 0, 0],
		"root": [0, -12, 4]})
	pose("strike_cut_hi", {"chest": [20, 0, 0], "arm_f": [-70, 0, 0], "fore_f": [0, 0, 0],
		"root": [0, 24, -2]})
	pose("strike_cut_lo", {"chest": [14, 0, 0], "arm_b": [-84, 0, 0], "fore_b": [-8, 0, 0],
		"root": [0, 24, -4]})
	pose("flinch", {"chest": [-6, 0, 0], "head": [-12, 0, 0], "root": [0, -8, 2]})
	pose("stagger", {"chest": [-26, 0, 0], "head": [-26, 0, 8], "jaw": [34, 0, 0],
		"arm_f": [-10, 0, 0], "arm_b": [-60, 0, 0],
		"root": [0, -40, 8], "hips": [0, 0, 6]})
	pose("victory", {"chest": [-18, 0, 0], "head": [-22, 0, 0], "jaw": [40, 0, 0],
		"arm_f": [-130, 0, 0], "arm_b": [-124, 0, 0]})
	pose("death", {"hips": [0, 0, 70], "chest": [46, 0, 0], "head": [30, 0, 10],
		"jaw": [36, 0, 0], "arm_f": [-30, 0, 0], "fore_f": [30, 0, 0],
		"arm_b": [-20, 0, 0], "leg_f": [-40, 0, 0], "shin_f": [70, 0, 0],
		"leg_b": [46, 0, 0], "root": [0, 0, 48]})

# ============================================================ acting API
func windup(kind: String, amt: float) -> void:
	var p := "windup_heavy"
	match kind:
		"crush": p = "windup_crush"
		"channel": p = "windup_channel"
		"curse": p = "windup_curse"
		"nova": p = "windup_nova"
		"cut_hi": p = "windup_cut_hi"
		"cut_lo": p = "windup_cut_lo"
	set_windup(p, amt)
	match kind:
		"channel":
			part_glow("throat", Color("d0413a"), 0.3 + 0.9 * amt)
		"nova":
			part_glow("spines", Color("8a5bd6"), 0.2 + 0.8 * amt)
		"curse":
			part_glow("eye", Color("8a5bd6"), 0.4 + 0.8 * amt)
			part_glow("eye2", Color("8a5bd6"), 0.4 + 0.8 * amt)

func swing(kind: String) -> void:
	clear_windup()
	_glows_off()
	var p := "strike_heavy"
	var hold := 0.18
	match kind:
		"crush": p = "strike_crush"; hold = 0.24
		"nova": p = "strike_nova"; hold = 0.22
		"cut_hi": p = "strike_cut_hi"; hold = 0.10
		"cut_lo": p = "strike_cut_lo"; hold = 0.10
		"light": p = "strike_cut_lo"; hold = 0.08
	seq([{"pose": p, "dur": 0.07, "ease": "snap", "hold": hold}])

func curse_release() -> void:
	clear_windup()
	flash_part("eye", Color("8a5bd6"), 1.0)
	flash_part("eye2", Color("8a5bd6"), 1.0)
	seq([{"pose": "windup_curse", "dur": 0.06, "ease": "snap", "hold": 0.10}])
	_glows_off()

var _jab_flip := false
func melee_swipe() -> void:
	if windup_amt > 0.3:
		return
	_jab_flip = not _jab_flip
	seq([{"pose": "strike_cut_lo" if _jab_flip else "strike_cut_hi", "dur": 0.08, "ease": "snap", "hold": 0.05}])

func hit_react(big: bool) -> void:
	jolt(0.8 if big else 0.4)
	if _seq.is_empty() and windup_amt < 0.35:
		seq([{"pose": "flinch", "dur": 0.06, "ease": "snap", "hold": 0.05}])
	flash_part("eye", _eye_col, 1.0)

func stagger_anim() -> void:
	clear_windup()
	_glows_off()
	jolt(1.4)
	seq([{"pose": "stagger", "dur": 0.09, "ease": "snap", "hold": 0.55}])

func heal_flash() -> void:
	flash_part("throat", Color("83c98d"), 1.0)

func set_enrage(on: bool) -> void:
	if on == _enraged:
		return
	_enraged = on
	breath_scale = 1.9 if on else 1.0
	part_glow("eye", Color("d0413a") if on else _eye_col, 1.0 if on else 0.6)
	part_glow("eye2", Color("d0413a") if on else _eye_col, 1.0 if on else 0.6)
	part_glow("spines", Color("d0413a"), 0.7 if on else 0.0)

## Reskin per Seal / add id — the placeholder pass for the Machine Seals (tint,
## eye colour, bulk) until per-boss robot puppets land (see MASTER-PLAN §Graphics).
## Also the add-wave body swap: the stage calls variant(<add id>) on add_spawn and
## variant(<encounter id>) on add_down. Preserves the stage's facing flip.
func variant(id: String) -> void:
	var tint := Color(1, 1, 1)
	var eye := Color("b072c9")
	var bulk := 1.0
	match id:
		"mistral":                       # wind-cooled, efficient, single-GPU blue
			tint = Color(0.80, 0.96, 1.12); eye = Color("7fd4ff"); bulk = 0.86
		"gemini":                        # twin constellation indigo
			tint = Color(0.94, 0.88, 1.20); eye = Color("9fb4ff")
		"mythos":                        # the Final Compute — gilded void
			tint = Color(1.14, 1.02, 0.82); eye = Color("ffd37a"); bulk = 1.07
		"bard":                          # deprecated amber, slightly translucent
			tint = Color(1.06, 0.94, 0.70, 0.92); eye = Color("ffb35c"); bulk = 0.70
		"sonnet":                        # quick copper subagent
			tint = Color(1.04, 0.88, 0.76); eye = Color("ff9d5c"); bulk = 0.68
		"opus":                          # the heavy subagent
			tint = Color(1.10, 0.84, 0.84); eye = Color("ff6a5c"); bulk = 0.84
		_:
			pass                         # riftmaw / unknown = the classic look
	modulate = tint
	_eye_col = eye
	scale = Vector2(signf(scale.x if scale.x != 0.0 else 1.0) * bulk, bulk)
	part_glow("eye", _eye_col, 0.6)
	part_glow("eye2", _eye_col, 0.6)

func die() -> void:
	clear_windup()
	breath_scale = 0.0
	rest_in("death", 1.0)
	for p in ["eye", "eye2", "throat", "spines"]:
		part_glow(p, _eye_col, 0.0)

func win() -> void:
	clear_windup()
	rest_in("victory", 0.6)
	flash_part("eye", _eye_col, 1.0)
	flash_part("eye2", _eye_col, 1.0)

func _glows_off() -> void:
	if _enraged:
		return
	part_glow("throat", _eye_col, 0.0)
	part_glow("spines", _eye_col, 0.0)
	part_glow("eye", _eye_col, 0.6)
	part_glow("eye2", _eye_col, 0.6)
