## GEAR-1 — the permanent Ledger unlock store (save file). HUD-flow ONLY: sims and
## probes inject an unlocks Dictionary directly and never touch disk (headless
## batch runs must not read or write user://). Mirrors net_client's ConfigFile idiom.
class_name GearStore
extends RefCounted

const CFG_PATH := "user://rift_gear.cfg"

## boss_id -> Array of unlocked item ids.
static func load_unlocks() -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK or not cf.has_section("unlocks"):
		return {}
	var out: Dictionary = {}
	for boss in cf.get_section_keys("unlocks"):
		out[boss] = Array(cf.get_value("unlocks", boss, []))
	return out

static func save_unlocks(unlocks: Dictionary) -> void:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)   # keep future sections intact if the file grows
	for boss in unlocks:
		cf.set_value("unlocks", String(boss), unlocks[boss])
	cf.save(CFG_PATH)
