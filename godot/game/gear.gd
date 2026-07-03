## GEAR — the Curio drop roll + equip rules. Tables/items live in GearCatalog,
## permanent unlocks in GearStore, oath purses bend rolls (Oaths). Rolls draw ONLY
## from the caller's dedicated DetRng stream — combat rng is never touched.
class_name Gear
extends RefCounted

const SLOTS := 2

## GEAR-2: rarity-first weights by ring depth (PROGRESSION/GEAR-CATALOG table).
## ARMORY retune: drops are scarce EVENTS now (Seal/gate/first-kill only), so each
## roll pays richer — a full descent should all but guarantee one opus moment.
static func rarity_weights(ring: int) -> Dictionary:
	if ring <= 0:
		return {"haiku": 0.25, "sonnet": 0.40, "opus": 0.35}
	if ring <= 2:
		return {"haiku": 0.38, "sonnet": 0.40, "opus": 0.22}
	return {"haiku": 0.50, "sonnet": 0.35, "opus": 0.15}

## Clamp order when the rolled tier has nothing unlocked (nearest non-empty).
const _TIER_ORDER := {
	"opus": ["opus", "sonnet", "haiku"],
	"sonnet": ["sonnet", "opus", "haiku"],
	"haiku": ["haiku", "sonnet", "opus"],
}

## Roll the drop for a killed boss. Returns {} (no table, or nothing unlocked that
## this class can hold), else {"item": id, "first": bool}. `first` marks the
## SIGNATURE unlock (guaranteed, ceremony; no rng spent so later draws don't shift).
## GEAR-2: rarity is rolled FIRST — ring weights, +5pp effective opus per `pity`
## point, and an oath purse's `bend` (rarity floor / forced opus) — then the item
## is drawn uniformly inside the tier, clamping to the nearest non-empty tier.
static func roll(boss_id: String, seat_cls: String, unlocks: Dictionary, rng: DetRng,
		ring: int = 3, pity: int = 0, bend: Dictionary = {}) -> Dictionary:
	var rows := GearCatalog.table(boss_id)
	if rows.is_empty():
		return {}
	var got: Array = unlocks.get(boss_id, [])
	for r in rows:
		var id := String(r["item"])
		if String(r["row"]) == "signature" and not got.has(id) and _fits(id, seat_cls):
			return {"item": id, "first": true}
	# unlocked, class-fitting pool per tier
	var pools := {"haiku": [], "sonnet": [], "opus": []}
	for r in rows:
		var id2 := String(r["item"])
		if got.has(id2) and _fits(id2, seat_cls):
			(pools[String(GearCatalog.item(id2).get("rarity", "haiku"))] as Array).append(id2)
	if (pools["haiku"] as Array).is_empty() and (pools["sonnet"] as Array).is_empty() \
			and (pools["opus"] as Array).is_empty():
		return {}
	# tier roll (one rng draw, always spent — bends must not shift the stream shape)
	var w := rarity_weights(ring)
	var wo := minf(1.0, float(w["opus"]) + 0.05 * float(pity))
	var ws := float(w["sonnet"])
	var wh := maxf(0.0, 1.0 - wo - ws)
	if String(bend.get("floor", "")) == "sonnet":
		ws += wh
		wh = 0.0
	var x := rng.next_float()
	var tier := "opus" if x < wo else ("sonnet" if x < wo + ws else "haiku")
	if bool(bend.get("opus", false)):
		tier = "opus"
	for t in _TIER_ORDER[tier]:
		var pool: Array = pools[t]
		if not pool.is_empty():
			return {"item": String(pool[rng.next_u32() % pool.size()]), "first": false}
	return {}

## Does this boss still hold a LOCKED signature row this class could take? The
## first-kill shower: a locked signature keeps a skirmish kill ceremony-worthy;
## once it's inked, repeat kills stop rolling (drops stay EVENTS — ARMORY cadence).
static func first_locked(boss_id: String, seat_cls: String, unlocks: Dictionary) -> bool:
	var got: Array = unlocks.get(boss_id, [])
	for r in GearCatalog.table(boss_id):
		var id := String(r["item"])
		if String(r["row"]) == "signature" and not got.has(id) and _fits(id, seat_cls):
			return true
	return false

## Class-marked rows only drop for their class ("" = universal).
static func _fits(id: String, seat_cls: String) -> bool:
	var cls := String(GearCatalog.item(id).get("cls", ""))
	return cls == "" or cls == seat_cls
