## GEAR-1 — the Curio drop roll + equip rules. Tables/items live in GearCatalog,
## permanent unlocks in GearStore. Rolls draw ONLY from the caller's dedicated
## DetRng stream — combat rng is never touched (spends/drops can't shift a fight).
class_name Gear
extends RefCounted

const SLOTS := 2

## Roll the drop for a killed boss. Returns {} (no table, or nothing unlocked that
## this class can hold), else {"item": id, "first": bool} — `first` marks the
## SIGNATURE unlock (first-kill ceremony; the caller records it in the Ledger).
static func roll(boss_id: String, seat_cls: String, unlocks: Dictionary, rng: DetRng) -> Dictionary:
	var rows := GearCatalog.table(boss_id)
	if rows.is_empty():
		return {}
	var got: Array = unlocks.get(boss_id, [])
	# A locked SIGNATURE row IS the drop — guaranteed unlock + ceremony (spec: the
	# first-kill shower). No rng spent: the guarantee must not shift later rolls.
	for r in rows:
		var id := String(r["item"])
		if String(r["row"]) == "signature" and not got.has(id) and _fits(id, seat_cls):
			return {"item": id, "first": true}
	# Repeat kill: draw among this boss's unlocked rows this class can hold.
	# GEAR-1 tables are all-Haiku so there's no tier roll yet — GEAR-2's rarity
	# weights/pity slot in here, in front of this in-tier draw.
	var pool: Array = []
	for r in rows:
		var id2 := String(r["item"])
		if got.has(id2) and _fits(id2, seat_cls):
			pool.append(id2)
	if pool.is_empty():
		return {}
	return {"item": String(pool[rng.next_u32() % pool.size()]), "first": false}

## Class-marked rows only drop for their class ("" = universal).
static func _fits(id: String, seat_cls: String) -> bool:
	var cls := String(GearCatalog.item(id).get("cls", ""))
	return cls == "" or cls == seat_cls
