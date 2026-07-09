## GEAR-1 — the permanent Ledger unlock store. A facade over the Profile aggregate
## (REFIT P4 save unification — user://rift_gear.cfg is legacy, imported once).
## HUD-flow ONLY: sims and probes inject an unlocks Dictionary directly; headless
## batch runs stay disk-inert (the Profile guards user:// itself).
class_name GearStore
extends RefCounted

## boss_id -> Array of unlocked item ids.
static func load_unlocks() -> Dictionary:
	return Profile.current().gear_unlocks()

static func save_unlocks(unlocks: Dictionary) -> void:
	Profile.current().set_gear_unlocks(unlocks)
