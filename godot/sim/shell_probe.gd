## Headless probe for the WorldShell boot chain (REFIT P3.2a): the shell raises the
## combat HUD as its instance surface, and every dev autostart idiom drives the right
## screen THROUGH the shell (the idioms left raid_hud._ready in P3.2a).
## Run: godot --headless --path godot --script res://sim/shell_probe.gd
extends SceneTree

var shell: Control
var step := 0
var fails := 0

func _process(_d: float) -> bool:
	step += 1
	if step == 1:
		shell = (load("res://game/world_shell.tscn") as PackedScene).instantiate()
		root.add_child(shell)
		return false
	if step == 2:
		_check(shell.hud != null, "shell raised the HUD")
		_check(String(shell._screen) == "home", "boot lands on HOME (got %s)" % shell._screen)
		shell.drive_autostart(["--autostart=raid:tank"])
		_check(String(shell.hud._screen) == "combat", "raid idiom -> combat (got %s)" % shell.hud._screen)
		shell.hud._show_home()
		shell.drive_autostart(["--autostart=raidmap:tank"])
		_check(String(shell.hud._screen) == "map", "raidmap idiom -> map (got %s)" % shell.hud._screen)
		shell.hud._show_home()
		shell.drive_autostart(["--autostart=world"])
		_check(String(shell._screen) == "atlas", "world idiom -> atlas (got %s)" % shell._screen)
		shell.hud._show_home()
		shell.drive_autostart(["--autostart=zone"])
		_check(String(shell._screen) == "zone", "zone idiom -> zone (got %s)" % shell._screen)
		# (the gate idiom died with THE PURGE 2026-07-10 — gates are gone from the game)
		print("SHELL PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAILURES" % fails))
		quit(1 if fails > 0 else 0)
		return true
	return false

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
