## WorldContent — the authored overworld (WORLD-PLAN W1). Pure data: Atlas pins +
## ZONE 1 "THE GILDFIELDS" (our Westfall — working name, Bill blesses later), a fixed
## ~20-node conquest map whose story funnels into the dungeon door (the Westfall steal:
## the zone's mystery IS the dungeon's setup).
##
## TONE LAW (WORLD-PLAN): the world outside realm doors is EARNEST dark fantasy —
## jokes live inside the doors. Zone fight nodes carry world fiction in their names/
## flavor; the fights themselves are W1 STAND-INS from the raid casting pool (canonical
## encounter ids, byte-identical to their source pulls — the W2 Forge recasts them).
##
## Node = plain Dictionary (authored, id == index):
##   {id, kind, name, sub, pos: Vector2, edges: [ids], fight: enc_id, event: id,
##    spine: bool, variants: {"flag=value": {overrides…}}}
## kind: "fight" | "elite" | "boss" | "gate" | "event" | "choice" | "camp" | "cache"
##       | "waystation" | "door"
class_name WorldContent

const REGION_TITLE := "THE RIFTLANDS"
const REGION_SUB := "REGION I  ·  the world is the map — conquer it once, keep it forever"

const ZONE1 := "gildfields"

# ============================================================ THE ATLAS

## Atlas pins. kind: "hub" | "zone" | "raid" | "fog" (fog = silhouette, unclickable).
static func atlas_pins() -> Array:
	return [
		{"id": "bastion", "kind": "hub", "name": "THE BASTION", "pos": Vector2(300, 640),
			"sub": "hearth & muster — the warband's home"},
		{"id": ZONE1, "kind": "zone", "name": "THE GILDFIELDS", "pos": Vector2(760, 500),
			"sub": "the gold harvest died standing"},
		{"id": "rift_scar", "kind": "raid", "name": "THE RIFT SCAR", "pos": Vector2(1450, 350),
			"sub": "REALM 1 · THE TAKEOVER — a raid descent (Ring 3 → 0)"},
		{"id": "fog_north", "kind": "fog", "name": "· · ·", "pos": Vector2(1100, 720),
			"sub": "the fog has not lifted"},
		{"id": "fog_west", "kind": "fog", "name": "· · ·", "pos": Vector2(480, 280),
			"sub": "the fog has not lifted"},
	]

# ============================================================ ZONE 1 — THE GILDFIELDS
## The Westfall arc: the harvest stopped ripening · the field-wards walk off their posts
## at night · masked HUSKMEN reap what nobody sowed · every road of it points at the
## OLD MILL, and under the mill, THE UNDERMILL — the dungeon this zone exists to set up.

static func zone(zid: String) -> Dictionary:
	match zid:
		ZONE1: return {
			"id": ZONE1,
			"name": "THE GILDFIELDS",
			"sub": "ZONE I — the gold harvest died standing. Find out why.",
			"entry_id": 0, "capstone_id": 7, "waystation_id": 8, "door_id": 19,
			"nodes": _gildfields_nodes(),
		}
	return {}

static func _gildfields_nodes() -> Array:
	var N: Array = []
	# ---- the spine (west gate → the Old Mill → the beacon)
	N.append(_n(0, "fight", "FIELDGATE", Vector2(240, 600),
		"the broken tollgate where the goldroad enters the fields — something reaps here at night",
		{"fight": "bard", "spine": true}))
	N.append(_n(1, "fight", "THE LONG FURROWS", Vector2(430, 510),
		"rows cut arrow-straight to the horizon; no farmer walks them anymore",
		{"fight": "sonnet", "spine": true}))
	N.append(_n(2, "event", "HARROW CROSS", Vector2(610, 600),
		"a crossroads shrine, its offering bowl still warm", {"event": "harrow", "spine": true}))
	N.append(_n(3, "choice", "THE SLUICE", Vector2(790, 500),
		"the irrigation gate is jammed mid-turn — someone jammed it on purpose",
		{"choice": "sluice", "spine": true}))
	N.append(_n(4, "camp", "WARDEN'S REST", Vector2(950, 620),
		"a field-warden's shelter, cold hearth, fresh boot prints", {"spine": true}))
	N.append(_n(5, "elite", "THE GRANARY STEPS", Vector2(1120, 530),
		"the great granary, sealed from the inside — the HUSKMEN hold the steps",
		{"fight": "opus", "spine": true}))
	N.append(_n(6, "event", "MILLWATCH RISE", Vector2(1290, 620),
		"the watchtower still stands its post; its beacon is dark", {"event": "beacon", "spine": true}))
	N.append(_n(7, "boss", "THE OLD MILL", Vector2(1470, 530),
		"the sails turn with no wind. Whatever drinks this land is HERE.",
		{"fight": "riftmaw", "spine": true}))
	N.append(_n(8, "waystation", "GILDWATCH BEACON", Vector2(1650, 420),
		"the old flight beacon above the fields — light it, and the sky roads open", {"spine": true}))
	# ---- the cave chain (north): "go fight stuff in a cave…"
	N.append(_n(9, "fight", "THE HOLLOW WARREN", Vector2(520, 350),
		"burrows under the hedgerows, dug from BELOW", {"fight": "bard"}))
	N.append(_n(10, "fight", "ROOTCELLAR DEPTHS", Vector2(700, 290),
		"the farmsteads' cellars all connect. They didn't used to.", {"fight": "sonnet"}))
	N.append(_n(11, "elite", "THE PALE TILLER", Vector2(880, 250),
		"a named terror: the field-ward that never stopped tilling — it plants things now",
		{"fight": "opus"}))
	N.append(_n(12, "cache", "BURIED CACHE", Vector2(1050, 320),
		"the Tiller's hoard — seed-silver and a warden's strongbox", {}))
	# ---- the marsh chain (south): the smugglers' way — "…or rush to the dungeon"
	N.append(_n(13, "fight", "THE DROWNED ACRE", Vector2(710, 760),
		"the low field flooded years ago; the HUSKMEN nest in the wrecked barn",
		{"fight": "sonnet", "variants": {"sluice=opened": {
			"kind": "cache", "name": "THE DROWNED ACRE (flooded)",
			"sub": "your flood took the barn — the nest floats in pieces. The fields remember the sluice."}}}))
	N.append(_n(14, "event", "REEDMERE", Vector2(890, 820),
		"pale lights walk the bog at dusk — the reeds whisper in grain-talk", {"event": "reedmere"}))
	N.append(_n(15, "cache", "SALTWASH LANDING", Vector2(1070, 770),
		"a hidden jetty: HUSKMEN crates stamped with the mill's seal", {}))
	# ---- scattered
	N.append(_n(16, "camp", "THE WAYSIDE SHRINE", Vector2(990, 430),
		"a shrine to the harvest that was; travelers left tokens — and warnings", {}))
	N.append(_n(17, "camp", "OLD BOUNDARY STONE", Vector2(330, 740),
		"the zone's oldest marker. Someone has chiselled the mill's sigil OVER the old runes.", {}))
	N.append(_n(18, "gate", "THE THRESHOLD", Vector2(1250, 420),
		"a proving stone of the old wardens — one of you steps through ALONE", {}))
	N.append(_n(19, "door", "UNDERMILL GATE", Vector2(1660, 700),
		"under the mill: stairs, worked stone, and the smell of wet grain going DOWN — the delve waits",
		{}))
	# ---- edges (undirected; mirrored at load)
	_e(N, 0, 1); _e(N, 1, 2); _e(N, 2, 3); _e(N, 3, 4); _e(N, 4, 5)
	_e(N, 5, 6); _e(N, 6, 7); _e(N, 7, 8)                      # the spine
	_e(N, 1, 9); _e(N, 9, 10); _e(N, 10, 11); _e(N, 11, 12); _e(N, 12, 5)   # cave loop
	_e(N, 2, 13); _e(N, 13, 14); _e(N, 14, 15); _e(N, 15, 6)   # marsh loop
	_e(N, 15, 19)                                              # the smugglers' path: RUSH the door
	_e(N, 4, 16); _e(N, 16, 5)                                 # shrine cut
	_e(N, 0, 17)                                               # dead-end lore
	_e(N, 6, 18)                                               # the personal gate
	_e(N, 7, 19)                                               # the mill guards the door
	return N

static func _n(id: int, kind: String, name: String, pos: Vector2, sub: String,
		extra: Dictionary) -> Dictionary:
	var d := {"id": id, "kind": kind, "name": name, "sub": sub, "pos": pos,
		"edges": [], "fight": "", "event": "", "choice": "", "spine": false, "variants": {}}
	for k in extra:
		d[k] = extra[k]
	return d

static func _e(N: Array, a: int, b: int) -> void:
	if not (N[a]["edges"] as Array).has(b):
		(N[a]["edges"] as Array).append(b)
	if not (N[b]["edges"] as Array).has(a):
		(N[b]["edges"] as Array).append(a)

## THE ZONE REMEMBERS: apply any variant whose "flag=value" key matches the zone's
## permanent flags. Geography never changes — only payload/dressing (authored-map law).
static func resolved_node(z: Dictionary, nid: int, flags: Dictionary) -> Dictionary:
	var n: Dictionary = (z["nodes"] as Array)[nid]
	var out := n.duplicate(true)
	for key in (n.get("variants", {}) as Dictionary):
		var kv := String(key).split("=")
		if kv.size() == 2 and String(flags.get(kv[0], "")) == kv[1]:
			for f in (n["variants"] as Dictionary)[key]:
				out[f] = (n["variants"] as Dictionary)[key][f]
	return out

# ============================================================ zone traversal
## Frontier rule: you may ENTER any node adjacent to conquered ground (or the entry,
## when nothing is conquered yet). Cleared nodes are free travel — never re-fought.

static func frontier(z: Dictionary, save: WorldSave) -> Array:
	var zid := String(z["id"])
	var out: Array = []
	if save.cleared_count(zid) == 0:
		return [int(z["entry_id"])]
	for n in (z["nodes"] as Array):
		var id := int(n["id"])
		if save.is_cleared(zid, id):
			continue
		for e in (n["edges"] as Array):
			if save.is_cleared(zid, int(e)):
				out.append(id)
				break
	return out

## Fog tiers for the render: 2 = known ground (cleared/frontier), 1 = silhouette
## (borders the frontier — a shape in the fog), 0 = unknown.
static func visibility(z: Dictionary, save: WorldSave) -> Dictionary:
	var zid := String(z["id"])
	var vis: Dictionary = {}
	var front := frontier(z, save)
	for n in (z["nodes"] as Array):
		var id := int(n["id"])
		vis[id] = 2 if (save.is_cleared(zid, id) or front.has(id)) else 0
	for n in (z["nodes"] as Array):
		var id := int(n["id"])
		if int(vis[id]) == 2 and front.has(id):
			for e in (n["edges"] as Array):
				if int(vis.get(int(e), 0)) == 0:
					vis[int(e)] = 1
	return vis

static func zone_conquered(z: Dictionary, save: WorldSave) -> bool:
	return save.is_cleared(String(z["id"]), int(z["capstone_id"]))

# ============================================================ zone EVENTS & CHOICES
## Earnest world fiction. All fx are flavor + optional world_flag — zones mint NOTHING
## (lane law); pool/access rewards arrive with the W2 quest pass.

static func event(id: String) -> Dictionary:
	match id:
		"harrow": return {
			"title": "HARROW CROSS",
			"body": "A crossroads shrine to the harvest-saints. The offering bowl is STILL WARM — someone tends this road, and left in a hurry. A toll cart stands abandoned, grain sacks full.",
			"choices": [
				{"label": "LEAVE THE GRAIN — honor the shrine", "fx": {"result":
					"The warband bows and moves on. Whoever tends the shrine will know a warband passed — and that it could be trusted."}},
				{"label": "SEARCH THE CART", "fx": {"result":
					"Under the sacks: a HUSKMAN's mask, and a manifest stamped with the OLD MILL's seal. The grain was never meant for market."}},
			]}
		"beacon": return {
			"title": "MILLWATCH RISE",
			"body": "The watchtower kept the fields for three generations. Its keeper is gone; his ledger isn't. The last line reads: \"the mill turns with no wind — DO NOT SELL TO THE MASKED MEN.\" The beacon brazier stands ready.",
			"choices": [
				{"label": "LIGHT THE BEACON", "fx": {"world_flag": ["beacon", "lit"], "result":
					"The flame takes. For the first time in a season, the Gildfields answer the dark with light — and the mill's sails STOP, just for a breath. It noticed."}},
				{"label": "LEAVE IT DARK — no need to announce yourselves", "fx": {"result":
					"The warband moves quiet. The mill's sails keep their slow, windless turn."}},
			]}
		"reedmere": return {
			"title": "REEDMERE",
			"body": "Pale lights walk the bog. Not spirits — LANTERNS, hooded, moving crates along a plank-road only the HUSKMEN know. You could watch where they go.",
			"choices": [
				{"label": "FOLLOW THE LIGHTS", "fx": {"result":
					"The plank-road runs east, to a hidden jetty — and every crate is stamped with the mill's seal. The smugglers' path to the UNDERMILL is real. (The landing lies ahead.)"}},
				{"label": "DOUSE A LANTERN AND TAKE ITS HOOD", "fx": {"result":
					"One lantern gutters out in the reeds. The warband keeps the hood — a HUSKMAN's colors, if you ever need to walk unchallenged."}},
			]}
	return {"title": "THE FIELDS", "body": "Wind through dead wheat.", "choices":
		[{"label": "MOVE ON", "fx": {"result": "The road goes on."}}]}

## THE ZONE REMEMBERS teaser (Bill's pick): a permanent choice with a visible
## consequence — flooding the acre deletes its fight and leaves a cache (the flag
## variant on node 13). Sealing it keeps the fight (its conquest is yours to take).
static func choice(id: String) -> Dictionary:
	match id:
		"sluice": return {
			"title": "THE SLUICE",
			"body": "The irrigation gate hangs jammed mid-turn — WEDGED, deliberately, so the low fields drain toward the mill. Open it, and the stored water takes the DROWNED ACRE (and the HUSKMEN nesting there) in one flood. Seal it, and the acre stays theirs to hold — and yours to take.\n\nTHE ZONE REMEMBERS. This is forever.",
			"choices": [
				{"label": "WRENCH IT OPEN — flood the Drowned Acre", "fx": {"world_flag": ["sluice", "opened"], "result":
					"The gate screams and gives. Water walks the low fields like a grey wall — the wrecked barn folds under it. The HUSKMEN's nest is gone; so is the fight. The fields will remember what you chose."}},
				{"label": "SEAL IT SHUT — keep the water; take the acre yourselves", "fx": {"world_flag": ["sluice", "sealed"], "result":
					"The gate grinds closed and the wedge goes in the mire. The Drowned Acre stays theirs — for now. Steel will have to do what the water would have. The fields will remember what you chose."}},
			]}
	return {}

# ============================================================ simple node stops

const CAMP_TEXT := {
	"WARDEN'S REST": "The warband rests by a dead hearth. On the wall, the warden's field map — half the marks point at the OLD MILL, drawn heavier each season.",
	"THE WAYSIDE SHRINE": "Tokens of the old harvest: ribbons, a child's straw doll, a soldier's clasp. And newer offerings — LEFT FACING THE MILL, like appeasement.",
	"OLD BOUNDARY STONE": "The oldest stone in the zone. Someone chiselled the mill's sigil OVER the founding runes. This didn't start last season.",
}

const CACHE_TEXT := {
	"BURIED CACHE": "Seed-silver, a warden's strongbox, and tools that still hold an edge. The warband takes stock. (Spoils that MATTER — pool and Ledger rewards — arrive with the zone's quest pass.)",
	"SALTWASH LANDING": "Crates on a hidden jetty, every lid stamped with the mill's seal. Grain out, coin in — and a plank-road pointing straight at the UNDERMILL.",
}

const WAYSTATION_TEXT := "The brazier atop Gildwatch takes the flame. A FLIGHT PATH opens: from the Atlas, the warband can now travel here on the sky roads, instantly, forever."
const DOOR_TEXT := "Stairs under the mill: worked stone older than the fields, and the smell of wet grain going DOWN. This is where the harvest goes. This is where the answers are.\n\nTHE UNDERMILL — a delve for another day (the door opens at W3). Mark it. You've earned the route."
const GATE_TEXT := "The wardens' proving stone. Its law is older than the warband: ONE steps through, ALONE, and is measured."
const BOSS_INTRO := "The sails turn with no wind, and now you know why: something under the mill DRINKS — water, harvest, land. Tonight it surfaces. The warband forms up at the doors.\n\n(W1 stand-in: the Riftmaw answers for the mill — the W2 Forge casts the zone's own terrors.)"
