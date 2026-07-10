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
##   + THE DESCENT REBUILD kinds (DESCENT-PLAN §5, raid floors only — enter via
##   `quota_override`, so the solo map never draws them): "elite" | "market" |
##   "jailbreak" | "minigame" | "wild". A WILD node's real payload is rolled at
##   generation (`wild_kind` + fight/event fields) and revealed on entry; its
##   fight tier still prints (the one rationed mystery, V#9).
## (the old "gate" kind died in THE PURGE 2026-07-10.)
class_name RunMap
extends RefCounted

const ROWS := 6                ## row 0 = entry fight, ROWS-1 = the Seal
const LANES := 3
const KIND_COMBAT := "combat"
const KIND_EVENT := "event"
const KIND_CACHE := "cache"
const KIND_COOLING := "cooling"
const KIND_SEAL := "seal"
const KIND_ELITE := "elite"          ## DESCENT: mutator fight — keystone 1-of-2 + curio roll
const KIND_MARKET := "market"        ## DESCENT: THE PROMPT MARKET (stubbed → cache until live)
const KIND_JAILBREAK := "jailbreak"  ## DESCENT: printed curse deals (stubbed → event until live)
const KIND_MINIGAME := "minigame"    ## DESCENT: CAPTCHA / BENCHMARK (stubbed → event until live)
const KIND_WILD := "wild"            ## DESCENT: the sealed envelope — payload rolled at gen

## kinds that resolve as a FIGHT (tier pips print; the deck-cycle ladder applies)
const FIGHT_KINDS := [KIND_COMBAT, KIND_ELITE]

## mid-grid kind quota (LANES * 4 mid slots = 12): the rest fill with combat
const QUOTA := {KIND_COOLING: 2, KIND_CACHE: 1, KIND_EVENT: 4}

var seed: int = 0
var nodes: Array = []          ## Array[Dictionary], id == index
var entry_id: int = 0
var seal_id: int = 0
var backdoor: Array = []       ## [from_id, to_id] — the one locked edge
var seal_shard_req: int = 0    ## MAP-3c: credential shards needed to unlock the Seal (0 = ungated)
var tickets: Array = []        ## MAP-2: ticket ids placed on this map (pickup→turn-in quests)

## `extra_quota` adds node kinds to the mid-grid bag (e.g. {KIND_COOLING: 1} on raid
## floors). The bag is ALWAYS padded to the same size, so an empty extra_quota
## leaves every rng draw — and therefore every existing map — byte-identical.
## `shard_req` > 0 gates the Seal behind credential shards (MAP-3c ROOT floor).
## `n_tickets` > 0 seeds pickup→turn-in TICKET quests (MAP-2). All three default to
## off, so the solo map and every classic call stay byte-identical.
## `rows` sizes the lattice (THE DESCENT REFIT): raid floors pass 8 (= 6 mid rows,
## 20 nodes); the default keeps every classic 6-row call byte-identical. Min 6 —
## the backdoor's fixed grid rows (1→3) need at least 4 mid rows to exist.
## `quota_override` (THE DESCENT REBUILD): a non-empty dict REPLACES the base QUOTA
## as the whole non-combat bag (raid floors pass their FLOORS "quota" verbatim —
## DESCENT-PLAN §5); combat still pads to fill. {} = classic behavior, byte-identical.
## Passing it also arms the descent constraint passes (pre-Seal valley band ·
## elite placement rules · market/elite mid-lane reachability).
## `minigame` names the floor's MINIGAME flavor ("captcha"/"benchmark"); "" with a
## minigame in the bag = a seeded coin flip (the F4 "rotate").
static func generate(map_seed: int, n_fights: int, event_ids: Array,
		extra_quota: Dictionary = {}, shard_req: int = 0, n_tickets: int = 0,
		rows: int = ROWS, quota_override: Dictionary = {}, minigame: String = "") -> RunMap:
	var m := RunMap.new()
	m.seed = map_seed
	var rng := DetRng.new(map_seed)
	m._build(rng, n_fights, event_ids, extra_quota, shard_req, n_tickets, maxi(rows, ROWS),
		quota_override, minigame)
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

## THE DESCENT stub layer (DESCENT-PLAN §5): unbuilt interiors resolve as an HONEST
## existing kind until their slice lands, WITHOUT touching generation — flipping a
## flag never re-rolls a map. market → cache (free loot, no lying storefront);
## jailbreak/minigame → their stub event (a real authored event rides every such
## node); wild → its rolled payload on reveal. HUD, server, and sims all resolve
## through this ONE mapping.
const MARKET_LIVE := true       ## slice 3 (PROMPT MARKET + per-seat wallets) — LIVE
const JAILBREAK_LIVE := false   ## slice 4 (THE JAILBREAK printed deals)
const MINIGAME_LIVE := false    ## slice 5 (CAPTCHA / BENCHMARK)

static func effective_kind(n: Dictionary) -> String:
	match String(n.get("kind", "")):
		KIND_MARKET:
			return KIND_MARKET if MARKET_LIVE else KIND_CACHE
		KIND_JAILBREAK:
			return KIND_JAILBREAK if JAILBREAK_LIVE else KIND_EVENT
		KIND_MINIGAME:
			return KIND_MINIGAME if MINIGAME_LIVE else KIND_EVENT
		KIND_WILD:
			# the reveal: a wild IS its rolled payload once entered
			return String(n.get("wild_kind", KIND_CACHE))
	return String(n.get("kind", ""))

## Stable serialization — the determinism check hashes this.
## New-kind fields print only when set, so classic (solo) maps hash to the exact
## pre-descent string — their byte-identity gate holds.
func fingerprint() -> String:
	var parts: Array = ["seed=%d;sreq=%d" % [seed, seal_shard_req]]
	for n in nodes:
		var extra := ""
		if String(n.get("wild_kind", "")) != "":
			extra += ":w%s" % String(n["wild_kind"])
		if String(n.get("minigame", "")) != "":
			extra += ":m%s" % String(n["minigame"])
		parts.append("%d:%s:r%d:l%d:f%d:e%s:k%s:s%s:to%s:tc%s:n%s:x%s%s" % [n["id"], n["kind"], n["row"],
			n["lane"], n["fight"], n["event"], str(n["key"]), str(n.get("shard", false)),
			String(n.get("ticket_open", "")), String(n.get("ticket_close", "")),
			str(n["next"]), str(n["locked_next"]), extra])
	return "|".join(parts)

# ============================================================ serialization (MAP-3b)
## The server owns the map and broadcasts it; clients rebuild a RunMap to render +
## test reachability. JSON turns every number into a float, so from_dict coerces the
## numeric fields back to int (node ids index arrays — floats would break node()).
func to_dict() -> Dictionary:
	return {"seed": seed, "nodes": nodes, "entry_id": entry_id, "seal_id": seal_id,
		"backdoor": backdoor, "seal_shard_req": seal_shard_req, "tickets": tickets}

static func from_dict(d: Dictionary) -> RunMap:
	var m := RunMap.new()
	m.seed = int(d.get("seed", 0))
	m.entry_id = int(d.get("entry_id", 0))
	m.seal_id = int(d.get("seal_id", 0))
	m.seal_shard_req = int(d.get("seal_shard_req", 0))
	var tk: Array = []
	for t in d.get("tickets", []):
		tk.append(String(t))
	m.tickets = tk
	m.backdoor = []
	for v in d.get("backdoor", []):
		m.backdoor.append(int(v))
	m.nodes = []
	for nd in d.get("nodes", []):
		var n: Dictionary = nd
		var nn := {
			"id": int(n.get("id", 0)), "kind": String(n.get("kind", "")),
			"row": int(n.get("row", 0)), "lane": int(n.get("lane", 0)),
			"name": String(n.get("name", "")), "fight": int(n.get("fight", -1)),
			"event": String(n.get("event", "")), "key": bool(n.get("key", false)),
			"shard": bool(n.get("shard", false)),
			"wild_kind": String(n.get("wild_kind", "")),
			"minigame": String(n.get("minigame", "")),
			"ticket_open": String(n.get("ticket_open", "")),
			"ticket_close": String(n.get("ticket_close", "")),
			"next": [], "locked_next": [], "visited": bool(n.get("visited", false)),
		}
		for x in n.get("next", []):
			(nn["next"] as Array).append(int(x))
		for x in n.get("locked_next", []):
			(nn["locked_next"] as Array).append(int(x))
		m.nodes.append(nn)
	return m

# ============================================================ generation

func _build(rng: DetRng, n_fights: int, event_ids: Array, extra_quota: Dictionary = {},
		shard_req: int = 0, n_tickets: int = 0, rows: int = ROWS,
		quota_override: Dictionary = {}, minigame: String = "") -> void:
	nodes.clear()
	# entry (row 0) and the mid grid (rows 1..rows-2), then the Seal (row rows-1)
	entry_id = _add(KIND_COMBAT, 0, 1)
	nodes[entry_id]["fight"] = 0
	var grid: Array = []                       # grid[row][lane] -> id
	for r in range(1, rows - 1):
		var lane_ids: Array = []
		for l in LANES:
			lane_ids.append(_add("", r, l))
		grid.append(lane_ids)
	seal_id = _add(KIND_SEAL, rows - 1, 1)
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
	# THE DESCENT REBUILD: a non-empty quota_override IS the whole non-combat bag
	# (FLOORS "quota" verbatim); classic callers keep base QUOTA + extra_quota.
	var descent := not quota_override.is_empty()
	var bag: Array = []
	var src: Dictionary = quota_override if descent else QUOTA
	for kind in src:
		for i in src[kind]:
			bag.append(kind)
	if not descent:
		for kind in extra_quota:       # raid-floor extras; {} = identical bag
			for i in extra_quota[kind]:
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
				n["fight"] = _ramp_fight(gi, grid.size(), n_fights)
			elif n["kind"] == KIND_EVENT and not ev_pool.is_empty():
				n["event"] = ev_pool.pop_front()
			elif n["kind"] == KIND_JAILBREAK or n["kind"] == KIND_MINIGAME:
				# a STUB event id rides along so the flag-off fallback (→ event) is a
				# fully real node today; the live interiors (slices 4–5) ignore it
				if not ev_pool.is_empty():
					n["event"] = ev_pool.pop_front()
				if n["kind"] == KIND_MINIGAME:
					n["minigame"] = minigame if minigame != "" \
						else ("captcha" if rng.next_u32() % 2 == 0 else "benchmark")
			elif n["kind"] == KIND_WILD:
				# the sealed envelope: payload rolled NOW (deterministic, serialized,
				# server-agreeable), revealed on entry. Fight tier still prints (V#9).
				var r := rng.next_float()
				if r < 0.40:
					n["wild_kind"] = KIND_COMBAT   # fight index set in the ramp pass below
				elif r < 0.75 and not ev_pool.is_empty():
					n["wild_kind"] = KIND_EVENT
					n["event"] = ev_pool.pop_front()
				else:
					n["wild_kind"] = KIND_CACHE

	# ---- THE DESCENT constraint passes (DESCENT-PLAN §2/§3 — deterministic, rng-free):
	# pre-Seal valley band · elite placement laws · market/elite mid-lane reachability;
	# then the fight ramp recomputed post-swap (elites + wild-combats included).
	if descent:
		_descent_pass(grid)
		for gi in grid.size():
			for l in LANES:
				var n: Dictionary = nodes[grid[gi][l]]
				if n["kind"] == KIND_COMBAT or n["kind"] == KIND_ELITE \
						or (n["kind"] == KIND_WILD and String(n.get("wild_kind", "")) == KIND_COMBAT):
					n["fight"] = _ramp_fight(gi, grid.size(), n_fights)
				else:
					n["fight"] = -1

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

	# ---- TICKETS (quests, MAP-2): each = a pickup on an early node → a turn-in on a
	# LATER same-lane node. The always-present same-lane edge guarantees a closeable
	# route; detour to another lane and you forfeit the reward (the routing decision).
	# Tickets gate NOTHING mandatory, so completability is untouched. One ticket per
	# lane (≤ LANES). n_tickets == 0 skips every draw → byte-identical map.
	tickets = []
	if n_tickets > 0:
		var tpool := MapContent.ticket_ids()
		_shuffle(tpool, rng)
		var want_t: int = mini(n_tickets, mini(tpool.size(), LANES))
		for t in want_t:
			var la: int = t % LANES
			var ra: int = int(rng.next_u32() % 2)          # pickup on grid row 0 or 1 (early)
			var rb: int = grid.size() - 1                  # turn-in on the last mid row, same lane
			if rb <= ra:
				continue
			var tid: String = String(tpool[t])
			nodes[grid[ra][la]]["ticket_open"] = tid
			nodes[grid[rb][la]]["ticket_close"] = tid
			tickets.append(tid)

	# ---- names come from the realm skin (MapContent)
	for n in nodes:
		n["name"] = MapContent.name_for(n, rng)

## difficulty ramps with depth: mid rows map onto fights 1..n-2
static func _ramp_fight(gi: int, grid_rows: int, n_fights: int) -> int:
	return 1 + mini(n_fights - 3, int(float(gi) / float(grid_rows - 1) * float(n_fights - 3) + 0.5))

# ------------------------------------------------ THE DESCENT constraint passes
## All rng-free (pure swaps + forced edges), so they run AFTER the seeded draws and
## never disturb the stream. Invariants delivered (DESCENT-PLAN §2/§3, proven in
## raid_map_sim): (a) the last mid row always offers a non-fight option (the pre-Seal
## valley band); (b) no ELITE in the last mid row (never adjacent to the Seal);
## (c) no two ELITEs on one edge (no stacked spikes); (d) the MARKET and the first
## ELITE sit in the MIDDLE lane with both adjacent crossings forced in, so every
## route can reach them (the same-lane spine + an adjacent crossing covers all lanes).
func _descent_pass(grid: Array) -> void:
	var last: int = grid.size() - 1
	# (1) MARKET: pin to (row ≥ 1, lane 1) + force both crossings in — reachable from
	# every committed lane. (2) the first ELITE: same treatment on a DIFFERENT row.
	var market_id := _pin_reachable(grid, KIND_MARKET, -1)
	var market_gi := -1 if market_id < 0 else int(nodes[market_id]["row"]) - 1
	var pinned_elite := _pin_reachable(grid, KIND_ELITE, market_gi)
	# (3) no ELITE in the last mid row — swap each out with an earlier combat
	for l in LANES:
		if String(nodes[grid[last][l]]["kind"]) == KIND_ELITE:
			for gi in range(last - 1, -1, -1):
				var moved := false
				for l2 in LANES:
					var c: Dictionary = nodes[grid[gi][l2]]
					if String(c["kind"]) == KIND_COMBAT and int(c["id"]) != pinned_elite:
						_swap_payload(nodes[grid[last][l]], c)
						moved = true
						break
				if moved:
					break
	# (4) pre-Seal valley band: ≥1 non-fight kind in the last mid row
	var has_valley := false
	for l in LANES:
		if not _fighty(nodes[grid[last][l]]):
			has_valley = true
	if not has_valley:
		for gi in range(last - 1, -1, -1):
			var done := false
			for l in LANES:
				var src: Dictionary = nodes[grid[gi][l]]
				if not _fighty(src) and String(src["kind"]) != KIND_MARKET:
					_swap_payload(src, nodes[grid[last][1]])
					done = true
					break
			if done:
				break
	# (5) LAST: no two ELITEs sharing an edge — relocate the non-pinned one onto a
	# combat slot that touches no elite (runs after every other move, so nothing
	# re-breaks it; forced crossings from (1)/(2) are already in the edge set).
	for pass_i in 4:
		var moved_any := false
		for gi in grid.size():
			for l in LANES:
				var a: Dictionary = nodes[grid[gi][l]]
				if String(a["kind"]) != KIND_ELITE:
					continue
				for nid in a["next"]:
					var b: Dictionary = nodes[nid]
					if String(b["kind"]) != KIND_ELITE:
						continue
					# move whichever of the pair is NOT the pinned elite
					var mover: Dictionary = b if int(b["id"]) != pinned_elite else a
					for gj in grid.size():
						var placed := false
						for l3 in LANES:
							var c: Dictionary = nodes[grid[gj][l3]]
							if String(c["kind"]) == KIND_COMBAT and gj != last \
									and not _touches_elite(c):
								_swap_payload(mover, c)
								placed = true
								moved_any = true
								break
						if placed:
							break
		if not moved_any:
			break

func _fighty(n: Dictionary) -> bool:
	var k := String(n["kind"])
	return k == KIND_COMBAT or k == KIND_ELITE \
		or (k == KIND_WILD and String(n.get("wild_kind", "")) == KIND_COMBAT)

func _touches_elite(n: Dictionary) -> bool:
	for nid in n["next"]:
		if String(nodes[nid]["kind"]) == KIND_ELITE:
			return true
	for other in nodes:
		if (other["next"] as Array).has(n["id"]) and String(other["kind"]) == KIND_ELITE:
			return true
	return false

## Pin the first node of `kind` to (grid row ≥ 1, lane 1) and force both adjacent
## crossings into it: the same-lane spine reaches (row-1, any lane), and the forced
## crossings carry every lane into the pinned node — reachable from EVERY route.
## `avoid_gi` keeps two pinned kinds off one row (the second would displace the
## first). Returns the pinned node id, or -1 when the kind isn't in this floor's bag.
## Rows here are grid rows; grid[gi] sits at node-row gi+1.
func _pin_reachable(grid: Array, kind: String, avoid_gi: int) -> int:
	for gi in grid.size():
		for l in LANES:
			var n: Dictionary = nodes[grid[gi][l]]
			if String(n["kind"]) != kind:
				continue
			# target row: deep enough to be routable (gi ≥ 1), never the last mid row
			# (the valley band + elite-beside-Seal laws own that row), not the avoided row
			var tg: int = clampi(gi, 1, grid.size() - 2)
			if tg == avoid_gi:
				tg = tg + 1 if tg + 1 <= grid.size() - 2 else tg - 1
			var target: Dictionary = nodes[grid[tg][1]]
			if int(target["id"]) != int(n["id"]):
				_swap_payload(n, target)
			_link(grid[tg - 1][0], grid[tg][1])
			_link(grid[tg - 1][2], grid[tg][1])
			return int(target["id"])
	return -1

## Exchange everything that makes a node "what it is" — position-bound payloads
## (key/shard/tickets) are placed AFTER this pass, and fight indices are recomputed
## after it, so only the kind-identity fields travel.
func _swap_payload(a: Dictionary, b: Dictionary) -> void:
	for f in ["kind", "event", "wild_kind", "minigame"]:
		var t = a.get(f, "")
		a[f] = b.get(f, "")
		b[f] = t

func _add(kind: String, row: int, lane: int) -> int:
	var id := nodes.size()
	nodes.append({"id": id, "kind": kind, "row": row, "lane": lane, "name": "",
		"fight": -1, "event": "", "key": false, "shard": false, "wild_kind": "", "minigame": "",
		"ticket_open": "", "ticket_close": "", "next": [], "locked_next": []})
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
