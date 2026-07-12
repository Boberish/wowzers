## artv2_tex_probe.gd — C3 texture-visibility bisect (GUI, WSLg — NOT headless).
## Draws the delivered Stack textures through four distinct paths side by side:
##   A draw_texture_rect + CompressedTexture2D loaded UP FRONT (in _initialize)
##   B draw_texture_rect + CompressedTexture2D loaded INSIDE the draw callback
##     (SceneKit's layer_tex-per-draw pattern — the suspect)
##   C draw_texture_rect + ImageTexture rebuilt from the decoded Image (fresh
##     RGBA8 GPU upload — bypasses the .ctex GPU path entirely)
##   D a TextureRect node (the engine's own texture drawing, no custom _draw)
## Plus a solid color square as the render reference. Whichever quadrants come
## out white name the broken path.
##   godot --path godot --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://sim/artv2_tex_probe.gd -- --out=/abs/dir
extends SceneTree

const BD := "res://game/art_v2/scenes/stack_atrium/backdrop.png"
const DI := "res://game/art_v2/scenes/stack_atrium/distant.png"

var out_dir := "user://shots_texprobe"
var frame := -1
var tex_a: Texture2D = null
var tex_c: Texture2D = null

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	tex_a = load(BD) as Texture2D
	var img := (tex_a as CompressedTexture2D).get_image() if tex_a is CompressedTexture2D else tex_a.get_image()
	print("A: %s %dx%d  img_format=%d" % [tex_a.get_class(), tex_a.get_width(), tex_a.get_height(), img.get_format()])
	img.convert(Image.FORMAT_RGBA8)
	tex_c = ImageTexture.create_from_image(img)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.draw.connect(_paint.bind(host))
	root.add_child(host)
	var tr := TextureRect.new()
	tr.texture = load(BD)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = Vector2(650, 370)
	tr.size = Vector2(560, 315)
	root.add_child(tr)

func _paint(ci: Control) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), Color(0.12, 0.12, 0.16))       # dark ground
	ci.draw_rect(Rect2(20, 20, 80, 80), Color(0.2, 0.9, 0.3))           # reference green
	ci.draw_texture_rect(tex_a, Rect2(120, 20, 500, 281), false)        # A up-front .ctex
	var b := load(BD) as Texture2D                                       # B load-in-draw
	ci.draw_texture_rect(b, Rect2(650, 20, 500, 281), false)
	ci.draw_texture_rect(tex_c, Rect2(120, 370, 500, 281), false)       # C ImageTexture
	var di := load(DI) as Texture2D                                      # distant, in-draw
	ci.draw_texture_rect(di, Rect2(20, 660, 1024, 50), false)
	ci.draw_string(ThemeDB.fallback_font, Vector2(130, 315), "A ctex up-front", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	ci.draw_string(ThemeDB.fallback_font, Vector2(660, 315), "B ctex in-draw", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	ci.draw_string(ThemeDB.fallback_font, Vector2(130, 665), "C ImageTexture", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	ci.draw_string(ThemeDB.fallback_font, Vector2(660, 700), "D TextureRect ^", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 12:
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join("texprobe.png"))
		print("  shot: ", out_dir.path_join("texprobe.png"))
		quit(0)
	return false
