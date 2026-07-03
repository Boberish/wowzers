## RunMap — the Across-the-Obelisk-style run map ("The Topology", see MASTER-PLAN §MAPS).
## A seeded layered DAG: ROWS rows × LANES lanes of nodes between a fixed entry fight and
## the Seal (act boss). Edges only go forward a row; ONE locked "backdoor" edge skips a row
## and needs the 🔑 access key found earlier. Locks only ever gate OPTIONAL edges — the
## row-by-row lattice always reaches the Seal, so every map is completable by construction.
##
## Game-layer only (RunState territory): generation runs on its OWN DetRng stream — the
## combat engine's RNG is never touched. Same seed ⇒ same map (co-op / daily seeds later).
##
## Node = plain Dictionary (serializable for the net layer later):
##   {id, kind, row, lane, name, fight, event, key, next: [ids], locked_next: [ids]}
## kind: "combat" | "event" | "cache" | "cooling" | "seal"
class_name RunMap
extends RefCounted

const ROWS := 6                ## row 0 = entry fight, ROWS-1 = the Seal
const LANES := 3
const KIND_COMBAT := "combat"
const KIND_EVENT := "event"
const KIND_CACHE := "cache"
const KIND_COOLING := "cooling"
const KIND_SEAL := "seal"

## mid-grid kind quota (LANES * 4 mid slots = 12): the rest fill with combat
const QUOTA := {KIND_COOLING: 2, KIND_CACHE: 1, KIND_EVENT: 4}

var seed: int = 0
var nodes: Array = []          ## Array[Dictionary], id == index
var entry_id: int = 0
var seal_id: int = 0
var backdoor: Array = []       ## [from_id, to_id] — the one locked edge
var seal_shard_req: int = 0    ## MAP-3c: credential shards needed to unlock the Seal (0 = ungated)

static func generate(map_seed: int, n_fights: int, event_ids: Array, shard_req: int = 0) -> RunMap:
	var m := RunMap.new()
	m.seed = map_seed
	var rng := DetRng.new(map_seed)
	m._build(rng, n_fights, event_ids, shard_req)
	return m

func node(id: int) -> Dictionary:
	return nodes[id]

## Nodes enterable from `from_id` (-1 = outside the map: only the entry).
## Locked edges are included only when the key is held. The Seal is gated until the
## party holds `seal_shard_req` credential shards (MAP-3c ROOT floor); shards are placed
## so every path collects enough before the last mid row, so this never dead-ends.
func reachable(from_id: int, inventory: Dictionary) -> Array:
	if from_id < 0:
		return [entry_id]
	var out: Array = []
	out.append_array(nodes[from_id]["next"])
	if inventory.get("api_key", false):
		out.append_array(nodes[from_id]["locked_next"])
	if seal_shard_req > 0 and int(inventory.get("shards", 0)) < seal_shard_req:
		out = out.filter(func(x): return x != seal_id)
	return out

## Stable serialization — the determinism check hashes this.
func fingerprint() -> String:
	var parts: Array = ["seed=%d;sreq=%d" % [seed, seal_shard_req]]
	for n in nodes:
		parts.append("%d:%s:r%d:l%d:f%d:e%s:k%s:s%s:n%s:x%s" % [n["id"], n["kind"], n["row"],
			n["lane"], n["fight"], n["event"], str(n["key"]), str(n.get("shard", false)),
			str(n["next"]), str(n["locked_next"])])
	return "|".join(parts)

# ============================================================ generation

func _build(rng: DetRng, n_fights: int, event_ids: Array, shard_req: int = 0) -> void:
	nodes.clear()
	# entry (row 0) and the mid grid (rows 1..ROWS-2), then the Seal (row ROWS-1)
	entry_id = _add(KIND_COMBAT, 0, 1)
	nodes[entry_id]["fight"] = 0
	var grid: Array = []                       # grid[row][lane] -> id
	for r in range(1, ROWS - 1):
		var lane_ids: Array = []
		for l in LANES:
			lane_ids.append(_add("", r, l))
		grid.append(lane_ids)
	seal_id = _add(KIND_SEAL, ROWS - 1, 1)
	nodes[seal_id]["fight"] = n_fights - 1

	# ---- edges: entry fans out to every lane of row 1
	for l in LANES:
		_link(entry_id, grid[0][l])
	# same-lane edge is ALWAYS present (keeps every node on a live route);
	# adjacent-lane crossings appear with 45% probability each side.
	for gi in grid.size() - 1:
		for l in LANES:
			_link(grid[gi][l], grid[gi + 1][l])
			for dl in [-1, 1]:
				var l2: int = l + dl
				if l2 >= 0 and l2 < LANES and rng.next_float() < 0.45:
					_link(grid[gi][l], grid[gi + 1][l2])
	# last mid row converges on the Seal
	for l in LANES:
		_link(grid[grid.size() - 1][l], seal_id)

	# ---- kinds: shuffle the quota bag over the mid slots (Fisher-Yates, seeded)
	var bag: Array = []
	for kind in QUOTA:
		for i in QUOTA[kind]:
			bag.append(kind)
	while bag.size() < grid.size() * LANES:
		bag.append(KIND_COMBAT)
	_shuffle(bag, rng)
	var ev_pool := event_ids.duplicate()
	_shuffle(ev_pool, rng)
	for gi in grid.size():
		for l in LANES:
			var n: Dictionary = nodes[grid[gi][l]]
			n["kind"] = bag.pop_front()
			if n["kind"] == KIND_COMBAT:
				# difficulty ramps with depth: mid rows map onto fights 1..n-2
				n["fight"] = 1 + mini(n_fights - 3, int(float(gi) / float(grid.size() - 1) * float(n_fights - 3) + 0.5))
			elif n["kind"] == KIND_EVENT and not ev_pool.is_empty():
				n["event"] = ev_pool.pop_front()

	# ---- the backdoor: one locked edge row2 → row4 (skips row 3), key placed on a
	# row-1 node that actually leads to the backdoor's mouth.
	var from_id: int = grid[1][rng.next_u32() % LANES]
	var to_id: int = grid[3][rng.next_u32() % LANES]
	nodes[from_id]["locked_next"].append(to_id)
	backdoor = [from_id, to_id]
	var feeders: Array = []                    # row-1 nodes with an edge into the mouth
	for l in LANES:
		if nodes[grid[0][l]]["next"].has(from_id):
			feeders.append(grid[0][l])
	# prefer a non-combat carrier for the key (nicer pacing); any feeder is fine
	var key_id: int = feeders[0]
	for f in feeders:
		if nodes[f]["kind"] != KIND_COMBAT:
			key_id = f
			break
	nodes[key_id]["key"] = true

	# ---- credential shards (MAP-3c ROOT floor): gate the Seal behind `shard_req`
	# shards, placed on WHOLE mid rows (all lanes) so every path collects exactly one
	# per shard row. Skip the row the backdoor jumps over — else a backdoor run could
	# reach the last row shard-short and dead-end at the gated Seal. With rows chosen
	# this way the count is guaranteed by construction (no solver, still completable).
	seal_shard_req = 0
	if shard_req > 0:
		var skip_lo: int = nodes[backdoor[0]]["row"] + 1   # node-rows the backdoor skips
		var skip_hi: int = nodes[backdoor[1]]["row"]       # (exclusive)
		var shard_rows: Array = []
		for gi in grid.size():
			var node_row: int = gi + 1                     # grid[gi] sits at node-row gi+1
			if node_row < skip_lo or node_row >= skip_hi:
				shard_rows.append(gi)
		var want: int = mini(shard_req, shard_rows.size())
		for k in want:
			for l in LANES:
				nodes[grid[shard_rows[k]][l]]["shard"] = true
		seal_shard_req = want

	# ---- names come from the realm skin (MapContent)
	for n in nodes:
		n["name"] = MapContent.name_for(n, rng)

func _add(kind: String, row: int, lane: int) -> int:
	var id := nodes.size()
	nodes.append({"id": id, "kind": kind, "row": row, "lane": lane, "name": "",
		"fight": -1, "event": "", "key": false, "shard": false, "next": [], "locked_next": []})
	return id

func _link(a: int, b: int) -> void:
	if not nodes[a]["next"].has(b):
		nodes[a]["next"].append(b)

static func _shuffle(arr: Array, rng: DetRng) -> void:
	# Fisher-Yates on the seeded stream (the prototypes' sort(()=>rand-0.5) bug — never again)
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.next_u32() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
