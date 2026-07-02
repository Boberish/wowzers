## SpriteActor2D — the USER-ART implementation of the Actor2D contract. Wraps a
## scene you author (any node tree + an AnimationPlayer named "anim") and maps
## contract calls to your animation names (see godot/ART-PIPELINE.md):
##   · one-shots play normally:  act_<ability>  (fallback act), hit, hit_big,
##     evade, hop, graze, stumble, brace, slump, cast, stagger, death, victory,
##     swing_<kind>, curse
##   · WINDUPS ARE SCRUBBED, not played: windup_<kind> is paused and its playhead
##     is set to amt * length every frame — your authored anticipation animation
##     stays perfectly glued to the live telegraph timer, whatever its speed.
##   · idle loops whenever nothing else is playing.
class_name SpriteActor2D
extends Actor2D

var _anim: AnimationPlayer = null
var _scrubbing := ""

func _init(scene_path: String) -> void:
	var sc := load(scene_path) as PackedScene
	if sc == null:
		return
	var inst := sc.instantiate()
	add_child(inst)
	_anim = inst.get_node_or_null("anim") as AnimationPlayer
	if _anim == null:
		for c in inst.get_children():
			if c is AnimationPlayer:
				_anim = c
				break
	_idle()

func _has(n: String) -> bool:
	return _anim != null and _anim.has_animation(n)

func _play(n: String, fallback := "") -> bool:
	if _has(n):
		_scrubbing = ""
		_anim.play(n)
		return true
	if fallback != "" and _has(fallback):
		_scrubbing = ""
		_anim.play(fallback)
		return true
	return false

func _idle() -> void:
	if _has("idle"):
		_scrubbing = ""
		_anim.play("idle")

func _process(_delta: float) -> void:
	# return to the idle loop when a one-shot finishes
	if _anim != null and _scrubbing == "" and not _anim.is_playing():
		_idle()

func act(id: String, flourish := false) -> Dictionary:
	if flourish and _play("act_%s_perfect" % id):
		return {"delay": 0.12, "kind": "perfect"}
	_play("act_%s" % id, "act")
	return {"delay": 0.12, "kind": "slash"}

func windup(kind: String, amt: float) -> void:
	var n := "windup_%s" % kind
	if not _has(n):
		return
	if _scrubbing != n:
		_scrubbing = n
		_anim.play(n)
		_anim.pause()
	_anim.seek(clampf(amt, 0.0, 1.0) * _anim.get_animation(n).length, true)

func clear_windup() -> void:
	if _scrubbing != "":
		_scrubbing = ""
		_idle()

func swing(kind: String) -> void:
	_scrubbing = ""
	_play("swing_%s" % kind, "swing")

func curse_release() -> void:
	_scrubbing = ""
	_play("curse")

func evade_react() -> void: _play("evade", "hop")
func hop_react(_clean: bool) -> void: _play("hop", "evade")
func graze_react() -> void: _play("graze", "hop")
func stumble_react() -> void: _play("stumble", "hit")
func brace_react() -> void: _play("brace")
func hit_react(big: bool) -> void: _play("hit_big" if big else "hit", "hit")
func slump_react() -> void: _play("slump")
func cast_react(id: String) -> void: _play("cast_%s" % id, "cast")
func stagger_anim() -> void: _play("stagger", "hit_big")

func die() -> void:
	_scrubbing = ""
	if not _play("death"):
		modulate = Color(0.4, 0.35, 0.35, 0.5)

func win() -> void:
	_scrubbing = ""
	_play("victory", "idle")
