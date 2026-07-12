## Probe for the ART V2 selector (GRAPHICS-PLAN Packet C1): the three independent
## view-only toggles + THE FAIL-SAFE LAW. Locks: defaults OFF · the --artv2=
## grammar (unknown tokens ignored) · OFF ⇒ the exact legacy factory classes ·
## flags ON with NO V2 assets ⇒ still the legacy graphics (never a null actor,
## never a blank stage, never a dead dashboard) · dash host absent until C6.
##   godot --headless --path godot --script res://sim/artv2_probe.gd
extends SceneTree
func _initialize() -> void:
	var fails: Array = []

	# [1] defaults: everything OFF — the old graphics are the release default
	_chk(fails, "default actors OFF", ArtV2.actors == false)
	_chk(fails, "default scene legacy", ArtV2.scene == "")
	_chk(fails, "default dash OFF", ArtV2.dash == false)

	# [2] OFF-purity: the factory returns the exact legacy classes per id
	# (duelist/alchemist/well → RiftmawRig2D is the live post-purge fallthrough
	# wart — locked AS-IS here; C4's adapter registration owns fixing the map)
	_legacy_chk(fails, "OFF")

	# [3] the boot grammar: any subset, any order, unknown tokens ignored
	ArtV2.boot(PackedStringArray(["--fightlen=2", "--artv2=dash, scene:v2_interior_test ,actors,typo"]))
	_chk(fails, "boot parses actors", ArtV2.actors == true)
	_chk(fails, "boot parses scene id", ArtV2.scene == "v2_interior_test")
	_chk(fails, "boot parses dash", ArtV2.dash == true)
	ArtV2.actors = false; ArtV2.scene = ""; ArtV2.dash = false
	ArtV2.boot(PackedStringArray(["--autostart=raid"]))   # no --artv2 ⇒ untouched
	_chk(fails, "no-arg boot stays OFF", not ArtV2.actors and ArtV2.scene == "" and not ArtV2.dash)

	# [4] FAIL-SAFE: flags ON but no V2 asset exists anywhere yet ⇒ legacy paths
	ArtV2.actors = true
	ArtV2.scene = "no_such_profile"
	ArtV2.dash = true
	_chk(fails, "actor adapter: missing asset ⇒ null (fall through)", ArtV2.make_actor("duelist") == null)
	_legacy_chk(fails, "ON+missing")   # the factory still hands out the puppets
	var st := ArtV2.make_scene()
	_chk(fails, "scene: unknown profile ⇒ legacy StageBackdrop", st is StageBackdrop)
	_chk(fails, "scene: legacy keeps the combat variant", st is StageBackdrop and (st as StageBackdrop).combat)
	st.free()
	_chk(fails, "dash: no C6 host ⇒ null (current widgets+band build)", ArtV2.make_dash(null) == null)
	ArtV2.scene = ""
	var st2 := ArtV2.make_scene()
	_chk(fails, "scene: '' ⇒ legacy StageBackdrop", st2 is StageBackdrop)
	st2.free()
	ArtV2.actors = false
	ArtV2.dash = false

	# [5] SceneKit (C2): the six-layer host + profile table — absence returns legacy
	var sk_legacy := SceneKit.make("")
	_chk(fails, "SceneKit '' => StageBackdrop combat", sk_legacy is StageBackdrop and (sk_legacy as StageBackdrop).combat)
	sk_legacy.free()
	var sk_menu := SceneKit.make("legacy", false)
	_chk(fails, "SceneKit 'legacy' keeps menu variant", sk_menu is StageBackdrop and not (sk_menu as StageBackdrop).combat)
	sk_menu.free()
	var sk_bogus := SceneKit.make("bogus_profile")
	_chk(fails, "SceneKit unknown => legacy", sk_bogus is StageBackdrop)
	sk_bogus.free()
	for pid in ["v2_interior_test", "v2_exterior_test"]:
		var host := SceneKit.make(String(pid))
		_chk(fails, "SceneKit %s => host" % pid, host is SceneKit and (host as SceneKit).profile_id == String(pid))
		host.free()
		var prof: Dictionary = SceneKit.PROFILES[pid]
		for layer in ["backdrop", "distant", "midground", "floor", "dressing", "atmosphere"]:
			_chk(fails, "%s has %s layer" % [pid, layer], prof.has(layer))
	ArtV2.scene = "v2_exterior_test"
	var routed := ArtV2.make_scene()
	_chk(fails, "ArtV2.make_scene routes to SceneKit", routed is SceneKit)
	routed.free()
	ArtV2.scene = ""
	var routed2 := ArtV2.make_scene()
	_chk(fails, "ArtV2.make_scene default => legacy", routed2 is StageBackdrop)
	routed2.free()

	for f in fails:
		print("  CHECK FAIL: %s" % f)
	print("ARTV2 PROBE: %s (%d checks)" % ["ALL OK" if fails.is_empty() else "FAIL", _n])
	quit(0 if fails.is_empty() else 1)

## The legacy factory contract, checked with the flags in a given state: every
## id must yield its current placeholder class (user art dir is empty in-repo).
func _legacy_chk(fails: Array, tag: String) -> void:
	var want := {"twinfang": "TwinfangRig2D", "voidcaller": "VoidcallerRig2D",
		"mender": "MenderRig2D", "duelist": "RiftmawRig2D", "riftmaw": "RiftmawRig2D"}
	for id in want:
		var a := Actor2D.make(String(id), "")
		var ok := a != null and a.get_script() != null and String(a.get_script().get_global_name()) == String(want[id])
		_chk(fails, "%s factory %s -> %s" % [tag, id, want[id]], ok)
		if a != null:
			a.free()

var _n := 0
func _chk(fails: Array, name: String, ok: bool) -> void:
	_n += 1
	if not ok:
		fails.append(name)
