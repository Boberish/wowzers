## ArtV2 — the GRAPHICS-PLAN V2 selector (Packet C1). Three INDEPENDENT view-only
## toggles — actors · scene profile · dashboard — ALL DEFAULT OFF; the old
## graphics remain the release default until the P7 vertical-slice verdict.
## One tiny static holder, no autoload: WorldShell parses `--artv2=` at the top
## of the boot (BEFORE the HUD instances — its _ready builds the backdrop) and
## each seam does one guarded read here.
##
## THE FAIL-SAFE LAW (GRAPHICS-PLAN §3/§7): a missing or unknown V2 asset,
## profile, or host ALWAYS falls back to the current playable graphics — never
## a null actor, never a blank stage, never a dead dashboard. No CombatState /
## spec / protocol / checksum contact anywhere: flags OFF ⇒ byte-identical.
class_name ArtV2
extends RefCounted

## the three independent selectors (GDScript gotcha: static var, never const)
static var actors := false   ## ON: V2 actor art may answer Actor2D.make()
static var scene := ""       ## scene profile id — "" = legacy StageBackdrop
static var dash := false     ## ON: a V2 dashboard host may replace the widgets
static var hud_low := false  ## DEV/test (LEGACY inspection only): duck+fade the channel — unnecessary under the C6A host
static var dash_debug := false  ## C6A dev overlay: label the contract rectangles on screen

## The non-canonical V2 namespace (§3): runtime assets live here until approved.
const ACTOR_DIR := "res://game/art_v2/actors"

## Parse the boot arg: --artv2=actors,scene:<id>,dash  (any subset, any order).
## Unknown tokens warn and are IGNORED — a typo can't take the old graphics away.
static func boot(args: PackedStringArray) -> void:
	for a in args:
		if not a.begins_with("--artv2="):
			continue
		for tok in a.substr("--artv2=".length()).split(",", false):
			var t := tok.strip_edges()
			if t == "actors":
				actors = true
			elif t == "dash":
				dash = true
			elif t == "hudlow":
				hud_low = true
			elif t == "dashdebug":
				dash_debug = true
			elif t.begins_with("scene:"):
				scene = t.substr("scene:".length()).strip_edges()
			elif t != "":
				push_warning("ArtV2: unknown --artv2 token '%s' (ignored)" % t)
	if actors or dash or scene != "":
		print("ART V2 selector ON — actors:%s scene:'%s' dash:%s (view-only; missing V2 assets fall back to the current graphics)" % [actors, scene, dash])

## ACTOR seam — consumed at the head of Actor2D.make(). A V2 actor wins only
## when the flag is ON and its scene exists under art_v2/actors/; it rides the
## same SpriteActor2D wrapper as user art, so the full Actor2D contract holds.
## null ⇒ the factory falls through to the user-art check + placeholder puppets.
static func make_actor(id: String, aspect := "") -> Actor2D:
	if not actors:
		return null
	# C4: the painted layered adapter answers first (actors/<id>/actor.json —
	# the ACTORS.md contract); a plain .tscn drop-in (C1's user-art path) second.
	var painted := PaintedActor2D.try_make(id, aspect)
	if painted != null:
		return painted
	var p := "%s/%s.tscn" % [ACTOR_DIR, id]
	if ResourceLoader.exists(p):
		return SpriteActor2D.new(p)
	return null   # missing V2 asset — the current puppet, never a null actor

## SCENE seam — consumed at raid_hud._ready (the ONE environment node). C2:
## routes through the SceneKit six-layer host (game/art_v2/scene_kit.gd), which
## owns the profile table AND the fail-safe — "" / "legacy" / unknown ⇒ the
## legacy StageBackdrop, byte-for-byte the old construction.
static func make_scene() -> Control:
	return SceneKit.make(scene)

## DASHBOARD seam — consumed in raid_hud._build_combat. C6A: the reaction-first
## graybox host answers for the DUELIST seat only (this proof); every other
## class returns null and receives the complete legacy HUD unchanged — the same
## missing-host fail-safe C1 shipped. The host satisfies the render feed by
## creating the REAL boss widgets + band synchronously (no null seams).
static func make_dash(hud: Control) -> Control:
	if not dash or hud == null:
		return null
	if not hud.has_method("_seat_cls_now") or String(hud.call("_seat_cls_now")) != "duelist":
		return null
	return DashHostC6A.new(hud)
