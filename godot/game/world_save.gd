## WorldSave — the persistent overworld state (WORLD-PLAN W1): conquered nodes, zone
## flags (THE ZONE REMEMBERS), waystations, where the warband stands. The world/instance
## line is the permanence/variance line — this file is the PERMANENCE side: cleared is
## cleared forever, flags never reset, nothing here is run-scoped.
##
## Stored in the Profile aggregate (REFIT P4 save unification — the old standalone
## user://rift_world.cfg is legacy, imported once). HUD-flow ONLY: sims and probes
## build saves in memory and never touch disk (headless batch runs stay disk-inert —
## the Profile guards user:// itself).
class_name WorldSave
extends RefCounted

const VERSION := 1

## {version, at_zone, zones: {zone_id: {cleared: {node_id_str: true}, flags: {name: value}, at: int}},
##  waystations: [zone_id]} — node ids serialize as String keys (JSON round-trip safe).
var data: Dictionary = {"version": VERSION, "at_zone": "", "zones": {}, "waystations": []}

# ============================================================ disk (HUD only)

static func load_save() -> WorldSave:
	var w := WorldSave.new()
	if DisplayServer.get_name() == "headless":
		return w
	var stored := Profile.current().world()
	if int(stored.get("version", 0)) == VERSION:
		w.data = stored
	return w

func save_to_disk() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Profile.current().set_world(data)

## DEV RESET (the Atlas corner button, W1 preview): a fresh world — fog everywhere,
## nothing conquered — written straight over the save. The permanence law is for the
## GAME; playtesting needs do-overs.
static func wipe() -> WorldSave:
	var w := WorldSave.new()
	w.save_to_disk()
	return w

# ============================================================ zone state

func zone_state(zid: String) -> Dictionary:
	var zones: Dictionary = data["zones"]
	if not zones.has(zid):
		zones[zid] = {"cleared": {}, "flags": {}, "at": -1}
	return zones[zid]

func is_cleared(zid: String, nid: int) -> bool:
	return bool((zone_state(zid)["cleared"] as Dictionary).get(str(nid), false))

func mark_cleared(zid: String, nid: int) -> void:
	(zone_state(zid)["cleared"] as Dictionary)[str(nid)] = true

func cleared_count(zid: String) -> int:
	return (zone_state(zid)["cleared"] as Dictionary).size()

func flags(zid: String) -> Dictionary:
	return zone_state(zid)["flags"]

func set_flag(zid: String, flag: String, value: String) -> void:
	(zone_state(zid)["flags"] as Dictionary)[flag] = value

func at_node(zid: String) -> int:
	return int(zone_state(zid).get("at", -1))

func set_at(zid: String, nid: int) -> void:
	zone_state(zid)["at"] = nid

func unlock_waystation(zid: String) -> void:
	var w: Array = data["waystations"]
	if not w.has(zid):
		w.append(zid)

func has_waystation(zid: String) -> bool:
	return (data["waystations"] as Array).has(zid)

# ============================================================ canonical serialization
## Sorted-key JSON so the same world state always emits the same bytes — the
## round-trip determinism probe hashes this (and future co-op write-back diffs it).
## The one canonical serializer lives on Profile (the save layer's root).

func canonical() -> String:
	return Profile.canon(data)

static func from_json(raw: String) -> WorldSave:
	var w := WorldSave.new()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION:
		w.data = parsed
	return w
