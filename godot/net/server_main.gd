## Headless Rift server entry point (R2):
##   godot --headless --path godot --script res://net/server_main.gd -- --port=9077
## Options: --port=N (default 9077) · --timescale=X (test soak speed, default 1)
extends SceneTree

var _server: NetServer

func _initialize() -> void:
	# An always-on headless server must not spin a core at 100%: cap the frame loop.
	# 60 fps keeps the 30 Hz fight clock comfortably fed (rooms drain on real delta).
	Engine.max_fps = 60
	_server = NetServer.new()
	_server.port = int(_arg("port", str(NetProtocol.DEFAULT_PORT)))
	_server.time_scale = float(_arg("timescale", "1.0"))
	_server.log_line.connect(func(m): print(m))
	root.add_child(_server)
	print("=== Project Rift — dedicated server ===")
	if _server.start() != OK:
		quit(1)

func _arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def
