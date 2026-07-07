## WorldShell — the game's FRONT DOOR (REFIT-PLAN P3.2a: the ownership inversion).
## The shell owns the boot: it raises the combat HUD as its INSTANCE SURFACE and
## drives the dev autostart idioms AGAINST it — the jump-ins are one explicit entry
## that drives the shell, not a parallel boot path baked into the instance. P3.2b
## migrates the world screens (home/atlas/zone/bastion/party) up here so the world
## OWNS the HUD outright; P3.3 gives the shell the online/presence door.
##
## Probes/smokes that load raid_main.tscn directly keep working — the HUD stays a
## self-contained instance surface; only the BOOT (project main_scene) is the shell.
class_name WorldShell
extends Control

var hud: Control = null   ## the combat HUD instance surface (raid_hud)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	add_child(hud)                      # child _ready runs here — home screen is up
	drive_autostart(OS.get_cmdline_user_args())

## The dev jump-ins (CLAUDE.md run-book: raid / raidmap / gate / world / zone).
## Moved verbatim off raid_hud._ready in P3.2a; `--fightlen=` stays HUD-side (it is
## an instance feel-scalar, parsed there before any pull).
func drive_autostart(args: PackedStringArray) -> void:
	for a in args:
		if a.begins_with("--autostart=gate"):
			# --autostart=gate[:seat[:aspect]]  → straight into that seat's GATE exam
			# (no map context: the end screen closes it — a dev/verify entry)
			var gspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = gspec[1] if gspec.size() > 1 and hud.SEAT_IDX.has(gspec[1]) else "tank"
			hud._aspect = gspec[2] if gspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._launch_gate_fight()
		elif a.begins_with("--autostart=raidmap"):
			# --autostart=raidmap[:seat[:aspect]]  → straight onto the Topology floor
			var mspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = mspec[1] if mspec.size() > 1 and hud.SEAT_IDX.has(mspec[1]) else "tank"
			hud._aspect = mspec[2] if mspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._start_map_run()
		elif a.begins_with("--autostart=world") or a.begins_with("--autostart=atlas"):
			# --autostart=world[:seat[:aspect]]  → THE WORLD preview, straight onto the Atlas
			var wspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = wspec[1] if wspec.size() > 1 and hud.SEAT_IDX.has(wspec[1]) else "tank"
			hud._aspect = wspec[2] if wspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._sync_healer_cls()
			hud._sync_blade_cls()
			hud._sync_caster_cls()
			hud._show_atlas()
		elif a.begins_with("--autostart=zone"):
			# --autostart=zone[:seat[:aspect]]  → straight into ZONE 1 (the Gildfields)
			var zspec := a.substr("--autostart=".length()).split(":")
			hud._seat_key = zspec[1] if zspec.size() > 1 and hud.SEAT_IDX.has(zspec[1]) else "tank"
			hud._aspect = zspec[2] if zspec.size() > 2 else String((hud.ASPECTS[hud._seat_key][0] as Dictionary)["id"])
			hud._sync_healer_cls()
			hud._sync_blade_cls()
			hud._sync_caster_cls()
			hud._zone_id = WorldContent.ZONE1
			if hud._world == null:
				hud._world = WorldSave.load_save()
			hud._ensure_party()
			hud._show_zone()
		elif a.begins_with("--autostart=raid"):
			# --autostart=raid[:seat[:aspect[:boss]]]  e.g. raid:blade:tempo:mythos
			var spec := a.substr("--autostart=".length()).split(":")
			var seat := spec[1] if spec.size() > 1 else "tank"
			var aspect := spec[2] if spec.size() > 2 else ""
			var enc := spec[3] if spec.size() > 3 else ""
			hud._launch(seat, aspect, enc)
