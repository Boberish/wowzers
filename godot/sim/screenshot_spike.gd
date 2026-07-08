## Throwaway: render the MobileSpike scene to a PNG (WSLg, NOT headless — custom _draw needs a
## real GL context). Steps the fight a few seconds so Flow/rhythm/opening show, then saves.
## Run: godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_spike.gd
extends SceneTree

var _spike: Control
var _frames := 0

func _initialize() -> void:
	var win := get_root()
	win.size = Vector2i(1280, 720)      # a phone-ish landscape
	_spike = MobileSpike.new()
	_spike.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_child(_spike)

func _process(_dt: float) -> bool:
	_frames += 1
	# drive some play so the widgets have state: tap STRIKE periodically, dodge occasionally
	if _spike != null and _spike._state != null and not _spike._state.over:
		if _frames % 20 == 0:
			_spike._fire("strike")
		if _frames % 140 == 0:
			_spike._fire("dodge")
	if _frames == 200:
		var img := get_root().get_texture().get_image()
		img.save_png("/home/bill/projects/wow-mobile-spike/spike_shot.png")
		print("SAVED spike_shot.png  (fight tick=", _spike._state.tick if _spike._state else -1, ")")
		quit()
	return false
