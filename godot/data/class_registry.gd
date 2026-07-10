## CLASS REGISTRY (REFIT P4) — the ONE `class_id → factory` table. Every "which
## class goes with which seat / builds which seat / starts which run / drives which
## policy" question answers HERE instead of a match-ladder per call site — the seam
## the roster wave and online spec-carry of arbitrary builds both need.
##
## The registry INDEXES content, it never authors it: seat factories stay in
## RaidContent, run starters in RunState, policies in their class files — the table
## holds Callables at them. Adding a class = one entry here + its content files.
##
## Lazy init (built on first lookup, never at class-load) so the table can reference
## every content class with ZERO load-order risk in the class cache.
##
## Policy seed salts are BYTE-EXACT history (the old RaidNet.make_policy constants,
## keyed by the seat each class occupies) — including Bloomweaver's no-rng quirk.
## Changing any of them is a lockstep/protocol event, not a refactor.
class_name ClassRegistry
extends RefCounted

static var _t: Dictionary = {}

static func table() -> Dictionary:
	if _t.is_empty():
		_t = {
			"duelist": {
				"seat": "tank", "display": "The Duelist",
				"aspects": ["duelist"], "default_aspect": "duelist",
				"kit": &"DuelistKit",
				"make_seat": RaidContent._tank,
				"start_run": RunState.start_duelist,
				"policy": func(seed_v: int) -> Policy:
					var p := DuelistPolicy.new()
					p.latency_ticks = RaidNet.ALLY_LATENCY
					p.rng = DetRng.new(seed_v * 2749 + 6737)   # NEW salt — never Bulwark's 1337 (byte-exact-history rule)
					return p,
			},
			"twinfang": {
				"seat": "blade", "display": "The Twinfang",
				"aspects": ["tempo", "fermata"], "default_aspect": "venomancer",
				"kit": &"TwinfangKit",
				"make_seat": RaidContent._blade,
				"start_run": RunState.start_twinfang,
				"policy": func(seed_v: int) -> Policy:
					var p := TwinfangPolicy.new()
					p.latency_ticks = RaidNet.ALLY_LATENCY
					p.rng = DetRng.new(seed_v * 2749 + 2338)
					return p,
			},
			"alchemist": {
				"seat": "caster", "display": "The Alchemist",
				"aspects": ["brew", "cask"], "default_aspect": "brew",
				"kit": &"AlchemistKit",
				"make_seat": RaidContent._alchemist,
				"start_run": RunState.start_alchemist,
				"policy": func(seed_v: int) -> Policy:
					var p := AlchemistPolicy.new()
					p.latency_ticks = RaidNet.ALLY_LATENCY
					p.rng = DetRng.new(seed_v * 2749 + 3339)
					return p,
			},
			"well": {
				"seat": "healer", "display": "The Well-tender",
				"aspects": ["brim", "draw"], "default_aspect": "brim",
				"kit": &"WellKit",
				"make_seat": RaidContent._well,
				"start_run": RunState.start_well,
				"policy": func(seed_v: int) -> Policy:
					var p := WellPolicy.new()
					p.latency_ticks = RaidNet.ALLY_LATENCY
					p.rng = DetRng.new(seed_v * 2749 + 5531)
					return p,
			},
			"bloomweaver": {
				"seat": "healer", "display": "The Bloomweaver",
				"aspects": ["wildgrove", "thornveil"], "default_aspect": "wildgrove",
				"kit": &"BloomweaverKit",
				"make_seat": RaidContent._bloomweaver,
				"start_run": RunState.start_bloomweaver,
				"policy": func(_seed_v: int) -> Policy:
					var p := BloomweaverPolicy.new()
					p.latency_ticks = RaidNet.ALLY_LATENCY
					return p,   # no rng — byte-exact history
			},
		}
	return _t

static func has_class(cls: String) -> bool:
	return table().has(cls)

static func seat_of(cls: String) -> String:
	return String((table().get(cls, {}) as Dictionary).get("seat", ""))

## Class ids that can occupy a seat, table order (the seat's NATIVE class first is
## a convention the table keeps by construction).
static func classes_for_seat(key: String) -> Array:
	var out: Array = []
	for cls in table():
		if String((table()[cls] as Dictionary)["seat"]) == key:
			out.append(cls)
	return out

## The class's default aspect ("" for an unknown class — callers keep their own
## seat-level fallback, mirroring the old behavior).
static func default_aspect(cls: String) -> String:
	return String((table().get(cls, {}) as Dictionary).get("default_aspect", ""))

## Build the class's raid SEAT (aspect "" → the class default).
static func make_seat(cls: String, aspect: String) -> Seat:
	var e: Dictionary = table().get(cls, {})
	if e.is_empty():
		return null
	var a := aspect if aspect != "" else String(e["default_aspect"])
	return (e["make_seat"] as Callable).call(a)

## Start the class's boon RunState (Draft 2.0 machinery; seed < 0 = wall-clock).
static func start_run(cls: String, aspect: String, seed_v: int = -1) -> RunState:
	var e: Dictionary = table().get(cls, {})
	if e.is_empty():
		return RunState.start(aspect, seed_v)   # the old _make_seat_run fallback
	return (e["start_run"] as Callable).call(aspect, seed_v)

## The class's deterministic AI policy — MUST construct identically everywhere
## (disconnect takeover swaps it in at an agreed tick on every replica).
static func make_policy(cls: String, seed_v: int) -> Policy:
	var e: Dictionary = table().get(cls, {})
	if e.is_empty():
		return null
	return (e["policy"] as Callable).call(seed_v)
