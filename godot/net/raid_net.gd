## RaidNet — the SHARED lockstep core (R2). Server and every client build the
## identical fight from the same spec and advance it with the identical step() —
## determinism (seeded engine RNG + seeded per-policy DetRngs) is what makes the
## input-relay netcode model work at all. Everything here must stay PURE: no
## wall-clock, no unseeded randomness, no per-machine branches that touch sim state.
class_name RaidNet
extends RefCounted

const SEAT_KEYS := ["tank", "blade", "caster", "healer"]
const DEFAULT_ASPECT := {"tank": "warden", "blade": "venomancer", "caster": "disruptor", "healer": "tidecaller"}
const ALLY_LATENCY := 5
const ALLY_SLACK := 0.06

## A fight spec (broadcast in the server's `start` message):
##   {seed:int, enc:"riftmaw", seats:[{key,aspect,ai:bool} x4 in SEAT_KEYS order]}
static func make_spec(seed: int, seat_cfg: Dictionary) -> Dictionary:
	var seats: Array = []
	for key in SEAT_KEYS:
		var c: Dictionary = seat_cfg.get(key, {})
		seats.append({
			"key": key,
			"aspect": String(c.get("aspect", DEFAULT_ASPECT[key])),
			"ai": bool(c.get("ai", true)),
		})
	return {"seed": seed, "enc": "riftmaw", "seats": seats}

## Build the fight state from a spec — identically on every machine.
## `my_seat` only sets the view-side is_player flag (diag/event tagging; audited
## sim-neutral in raid mode) — pass "" on the server.
static func build(spec: Dictionary, my_seat: String = "") -> CombatState:
	var aspects := {}
	for e in spec.get("seats", []):
		aspects[String(e["key"])] = String(e["aspect"])
	var s := RaidContent.make_state(int(spec.get("seed", 1)), RaidContent.make_riftmaw(),
		aspects, my_seat)
	var seed_v := int(spec.get("seed", 1))
	for e in spec.get("seats", []):
		var key := String(e["key"])
		var seat: Seat = s.seats[SEAT_KEYS.find(key)]
		if bool(e.get("ai", true)):
			seat.policy = make_policy(key, seed_v)
		else:
			seat.policy = null            # a human drives this seat via input frames
	return s

## The standard AI raider for a seat — MUST be constructed identically everywhere
## (disconnect takeover swaps this in at an agreed tick on every replica).
static func make_policy(key: String, seed_v: int) -> Policy:
	match key:
		"tank":
			var tp := RaidTankPolicy.new()
			tp.reaction_slack = ALLY_SLACK
			tp.rng = DetRng.new(seed_v * 2749 + 1337)
			return tp
		"blade":
			var bp := TwinfangPolicy.new()
			bp.latency_ticks = ALLY_LATENCY
			bp.rng = DetRng.new(seed_v * 2749 + 2338)
			return bp
		"caster":
			var cp := VoidcallerPolicy.new()
			cp.latency_ticks = ALLY_LATENCY
			cp.rng = DetRng.new(seed_v * 2749 + 3339)
			return cp
		_:
			var mp := MenderPolicy.new()
			mp.latency_ticks = ALLY_LATENCY
			return mp

## One lockstep tick: enqueue this frame's human inputs, let AI seats act, update.
## `inputs` = Array of [seat_i:int, action:Dictionary]; the frame number must be
## exactly state.tick + 1 (the caller guarantees ordering). Wire actions are pure
## data — a targeted action carries "target_i" (seat index), restored to the Seat
## ref here so the engine sees the same shape as local play.
static func step(s: CombatState, inputs: Array) -> void:
	var n := s.tick + 1
	for e in inputs:
		var i := int(e[0])
		if i >= 0 and i < s.seats.size() and (e[1] is Dictionary):
			var a: Dictionary = e[1]
			if a.has("target_i"):
				a = a.duplicate()
				var ti := int(a["target_i"])
				a.erase("target_i")
				if ti >= 0 and ti < s.seats.size():
					a["target"] = s.seats[ti]
			s.enqueue(n, s.seats[i], a)
	for seat in s.seats:
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(n, seat, a)
	CombatCore.update(s)

## Disconnect takeover: attach the standard AI to a seat — called on every replica
## at the same frame so the lockstep stays aligned.
static func seat_to_ai(s: CombatState, seat_i: int, seed_v: int) -> void:
	if seat_i >= 0 and seat_i < s.seats.size():
		s.seats[seat_i].policy = make_policy(SEAT_KEYS[seat_i], seed_v)
