## Actor2D — THE ART CONTRACT. Every fighter on a 2D stage is an Actor2D; the
## stage directors (duel + raid) only ever call this surface. Two families
## implement it: procedural placeholder puppets (PoseRig2D subclasses, in code)
## and USER ART (SpriteActor2D wrapping an AnimationPlayer scene you author).
## Swapping placeholder -> real art is dropping a .tscn in res://game/art/actors/
## — no stage or engine code changes. See godot/ART-PIPELINE.md for the full
## animation-name contract.
class_name Actor2D
extends Node2D

## One-shot ability acting. Returns VFX hints for the stage (all optional):
## {delay: sec until the hit lands, kind: slash|cross|slam|kick|coup|cast|venom,
##  repeats: int, gap: sec}
func act(_id: String, _flourish := false) -> Dictionary:
	return {}

## Telegraph-driven coil, called EVERY FRAME while a cast winds up.
## kind: light|heavy|crush|channel|curse|nova|cut_hi|cut_lo   amt: 0..1
func windup(_kind: String, _amt: float) -> void:
	pass

func clear_windup() -> void:
	pass

## The wind-up releases (the swing lands or is answered).
func swing(_kind: String) -> void:
	pass

func curse_release() -> void:
	pass

# --- reacts (defense verbs, M7 dodge grades, damage) ---
func evade_react() -> void: pass           ## the class defensive verb answered
func hop_react(_clean: bool) -> void: pass ## universal dodge PERFECT/GOOD
func graze_react() -> void: pass
func stumble_react() -> void: pass         ## BAITED / whiff
func brace_react() -> void: pass           ## READ (held a feint)
func hit_react(_big: bool) -> void: pass
func slump_react() -> void: pass           ## a resource/rhythm collapse (flow lost)
func cast_react(_id: String) -> void: pass ## healer/caster spell fires
func stagger_anim() -> void: pass          ## interrupted / kicked
func heal_flash() -> void: pass            ## boss drinks a heal

# --- state-driven looks ---
func power_glow(_frac: float) -> void: pass   ## class resource made visible (0..1)
func set_highlight(_on: bool) -> void: pass   ## the boss's gaze / local-player marker
func set_enrage(_on: bool) -> void: pass
func variant(_id: String) -> void: pass       ## reskin per encounter/boss id

func die() -> void: pass
func win() -> void: pass

# ============================================================ factory
## Build the actor for a role. USER ART WINS: if res://game/art/actors/<id>.tscn
## exists it is wrapped in a SpriteActor2D; otherwise the built-in placeholder
## puppet is used. `id`: bulwark|twinfang|voidcaller|mender|riftmaw — the voidcaller/
## mender rigs stay as the caster/healer seat PLACEHOLDER puppets (per-class art owed)
static func make(id: String, aspect := "") -> Actor2D:
	var art := "res://game/art/actors/%s.tscn" % id
	if ResourceLoader.exists(art):
		return SpriteActor2D.new(art)
	match id:
		"bulwark":
			return BulwarkRig2D.new(aspect)
		"twinfang":
			return TwinfangRig2D.new(aspect)
		"voidcaller":
			return VoidcallerRig2D.new(aspect)
		"mender":
			return MenderRig2D.new(aspect)
		_:
			return RiftmawRig2D.new()
