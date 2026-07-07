## WorldSave — the persistent overworld state (WORLD-PLAN W1): conquered nodes, zone
## flags (THE ZONE REMEMBERS), waystations, where the warband stands. The world/instance
## line is the permanence/variance line — this file is the PERMANENCE side: cleared is
## cleared forever, flags never reset, nothing here is run-scoped.
##
## Versioned ConfigFile at user://rift_world.cfg (the rift_net.cfg idiom). HUD-flow
## ONLY: sims and probes build saves in memory and never touch disk (headless batch
## runs stay disk-inert — mirror of GearStore).
class_name WorldSave
extends RefCounted

const CFG_PATH := "user://rift_world.cfg"
const VERSION := 1

## {version, at_zone, zones: {zone_id: {cleared: {node_id_str: true}, flags: {name: value}, at: int}},
##  waystations: [zone_id]} — node ids serialize as String keys (JSON round-trip safe).
var data: Dictionary = {"version": VERSION, "at_zone": "", "zones": {}, "waystations": []}

# ============================================================ disk (HUD only)

static func load_save() -> WorldSave:
	var w := WorldSave.new()
	if DisplayServer.get_name() == "headless":
		return w
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return w
	var raw := String(cf.get_value("world", "json", ""))
	if raw == "":
		return w
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION:
		w.data = parsed
	return w

func save_to_disk() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)   # keep future sections intact if the file grows
	cf.set_value("world", "json", canonical())
	cf.save(CFG_PATH)

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

func canonical() -> String:
	return _canon(data)

static func from_json(raw: String) -> WorldSave:
	var w := WorldSave.new()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION:
		w.data = parsed
	return w

static func _canon(v) -> String:
	if v is Dictionary:
		var keys: Array = (v as Dictionary).keys()
		keys.sort()
		var parts: Array = []
		for k in keys:
			parts.append("%s:%s" % [JSON.stringify(String(k)), _canon(v[k])])
		return "{%s}" % ",".join(parts)
	if v is Array:
		var items: Array = []
		for x in v:
			items.append(_canon(x))
		return "[%s]" % ",".join(items)
	if v is float and v == floorf(v):
		return str(int(v))   # JSON floats: 3.0 and 3 must canonicalize identically
	return JSON.stringify(v)
