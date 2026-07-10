## PROFILE — the ONE versioned save aggregate (REFIT-PLAN §3 P4 "save unification").
## Every persistent player-side domain lives here, behind the existing store facades:
##   world  — the overworld permanence layer (WorldSave's json dict)
##   gear   — the Ledger's permanent unlocks (GearStore)
##   binds  — click-cast layouts keyed by class id (WellBinds / BloomweaverBinds)
##   roster — the Commander party: seat_key -> {cls, aspect} (survives sessions)
##   runs   — the offline run-seed stream: root/counter/last_seed, so a whole descent
##            replays from one recorded integer (replay / ghost races)
##
## Disk: ONE canonical-JSON blob in user://rift_profile.cfg (WorldSave's idiom). The
## first load imports the legacy save files (rift_world.cfg / rift_gear.cfg /
## well_binds.json / bloomweaver_binds.json) once (rift_prior.cfg died with V#8); the legacy files
## stay on disk as inert backups — every reader routes through here now.
## (mender_binds.json is deliberately NOT imported — the class is leaving the roster.)
##
## HUD-flow ONLY: headless (sims / probes / smokes) NEVER touches disk — it gets a
## fresh in-memory profile with a FIXED seed root, so batch runs stay disk-inert AND
## byte-reproducible. All writers share the one cached instance (Profile.current()),
## so cross-domain saves can never clobber each other mid-session.
class_name Profile
extends RefCounted

const CFG_PATH := "user://rift_profile.cfg"
const VERSION := 1
## Headless seed root: fixed so a probe/smoke process draws the SAME run-seed
## sequence every time (reproducible), while successive draws still differ.
const HEADLESS_ROOT := 0x51F7EED

var data: Dictionary = {
	"version": VERSION,
	"world": {},
	"gear": {},
	"binds": {},
	"roster": {},
	"runs": {"root": 0, "counter": 0, "last_seed": -1},
}

static var _live: Profile = null

## The one live profile (cached — every store facade shares it).
static func current() -> Profile:
	if _live == null:
		_live = _load()
	return _live

## Probe hygiene: drop the cache so a test starts from a fresh in-memory profile.
static func reset_for_test() -> void:
	_live = null

# ============================================================ disk (HUD only)

static func _load() -> Profile:
	var p := Profile.new()
	if DisplayServer.get_name() == "headless":
		(p.data["runs"] as Dictionary)["root"] = HEADLESS_ROOT
		return p
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) == OK:
		var raw := String(cf.get_value("profile", "json", ""))
		if raw != "":
			var parsed = JSON.parse_string(raw)
			if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION:
				p._adopt(parsed)
				return p
	# no (valid) aggregate yet — first boot on this machine: import the legacy files
	p._import_legacy()
	(p.data["runs"] as Dictionary)["root"] = int(Time.get_ticks_usec() & 0x7FFFFFFF)
	p.save_to_disk()
	return p

func save_to_disk() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)   # keep future sections intact if the file grows
	cf.set_value("profile", "json", canonical())
	cf.save(CFG_PATH)

## Fold a parsed blob in WITHOUT trusting its shape — every domain falls back to the
## fresh default if the stored value has the wrong type (corruption-tolerant load).
## JSON parses every number as float, so numeric fields coerce via int(), never typeof.
func _adopt(parsed: Dictionary) -> void:
	for key in ["world", "gear", "binds", "roster", "runs"]:
		var v = parsed.get(key)
		if v is Dictionary:
			data[key] = v
	var runs: Dictionary = data["runs"]
	for rk in ["root", "counter", "last_seed"]:
		var dflt := -1 if rk == "last_seed" else 0
		var rv = runs.get(rk, dflt)
		runs[rk] = int(rv) if (rv is int or rv is float) else dflt

# ============================================================ legacy import (one-time)

func _import_legacy() -> void:
	var wcf := ConfigFile.new()
	if wcf.load("user://rift_world.cfg") == OK:
		var parsed = JSON.parse_string(String(wcf.get_value("world", "json", "")))
		if parsed is Dictionary and int(parsed.get("version", 0)) == 1:
			data["world"] = parsed
	var gcf := ConfigFile.new()
	if gcf.load("user://rift_gear.cfg") == OK and gcf.has_section("unlocks"):
		var unlocks: Dictionary = {}
		for boss in gcf.get_section_keys("unlocks"):
			unlocks[boss] = Array(gcf.get_value("unlocks", boss, []))
		data["gear"] = unlocks
	for cls in [["well", "user://well_binds.json"], ["bloomweaver", "user://bloomweaver_binds.json"]]:
		if FileAccess.file_exists(String(cls[1])):
			var f := FileAccess.open(String(cls[1]), FileAccess.READ)
			if f != null:
				var b = JSON.parse_string(f.get_as_text())
				f.close()
				if b is Dictionary:
					(data["binds"] as Dictionary)[String(cls[0])] = b

# ============================================================ domains

## world — the WorldSave dict (WorldSave keeps its own live copy; this is the store).
func world() -> Dictionary:
	return (data["world"] as Dictionary).duplicate(true)

func set_world(d: Dictionary) -> void:
	data["world"] = d.duplicate(true)
	save_to_disk()

## gear — boss_id -> Array of unlocked item ids.
func gear_unlocks() -> Dictionary:
	return (data["gear"] as Dictionary).duplicate(true)

func set_gear_unlocks(unlocks: Dictionary) -> void:
	data["gear"] = unlocks.duplicate(true)
	save_to_disk()

## binds — chord -> spell id, per class. Validation (which chords/spells are legal)
## stays in each class's binds facade; this is just the store.
func binds(cls: String) -> Dictionary:
	return ((data["binds"] as Dictionary).get(cls, {}) as Dictionary).duplicate(true)

func set_binds(cls: String, b: Dictionary) -> void:
	(data["binds"] as Dictionary)[cls] = b.duplicate(true)
	save_to_disk()

## roster — the Commander party (AI seats only): seat_key -> {cls, aspect}.
## Stored verbatim; the HUD validates ids against the live codex on load, so a
## roster saved before a class cut self-heals to defaults instead of crashing.
func roster() -> Dictionary:
	return (data["roster"] as Dictionary).duplicate(true)

func set_roster(party: Dictionary) -> void:
	data["roster"] = party.duplicate(true)
	save_to_disk()

# ============================================================ the run-seed stream

## Mint the next offline run seed — closed-form off (root, counter), persisted, and
## recorded as last_seed. One profile's Nth descent is always the same seed: a run
## replays from (profile root, counter) or from the recorded integer alone.
func next_run_seed() -> int:
	var runs: Dictionary = data["runs"]
	var n := int(runs["counter"])
	var s := int((int(runs["root"]) * 1000003 + n * 7919 + 1) & 0x7FFFFFFF)
	runs["counter"] = n + 1
	runs["last_seed"] = s
	save_to_disk()
	return s

func last_run_seed() -> int:
	return int((data["runs"] as Dictionary)["last_seed"])

# ============================================================ canonical serialization
## Sorted-key JSON so the same profile always emits the same bytes — the round-trip
## probe hashes this. This is the save layer's ONE canonical serializer; WorldSave
## delegates here.

func canonical() -> String:
	return canon(data)

static func from_json(raw: String) -> Profile:
	var p := Profile.new()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION:
		p._adopt(parsed)
	return p

static func canon(v) -> String:
	if v is Dictionary:
		var keys: Array = (v as Dictionary).keys()
		keys.sort()
		var parts: Array = []
		for k in keys:
			parts.append("%s:%s" % [JSON.stringify(String(k)), canon(v[k])])
		return "{%s}" % ",".join(parts)
	if v is Array:
		var items: Array = []
		for x in v:
			items.append(canon(x))
		return "[%s]" % ",".join(items)
	if v is float and v == floorf(v):
		return str(int(v))   # JSON floats: 3.0 and 3 must canonicalize identically
	return JSON.stringify(v)
