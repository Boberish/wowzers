## RaidNet — the SHARED lockstep core (R2). Server and every client build the
## identical fight from the same spec and advance it with the identical step() —
## determinism (seeded engine RNG + seeded per-policy DetRngs) is what makes the
## input-relay netcode model work at all. Everything here must stay PURE: no
## wall-clock, no unseeded randomness, no per-machine branches that touch sim state.
class_name RaidNet
extends RefCounted

const SEAT_KEYS := ["tank", "blade", "caster", "healer"]
const DEFAULT_ASPECT := {"tank": "warden", "blade": "venomancer", "caster": "disruptor", "healer": "tidecaller"}
## Each seat's native CLASS. Only the healer seat is polymorphic today — it may be
## "mender" (default, verified comp) or "bloomweaver" (the second healer). `cls` rides
## the fight spec per seat; absent/default → the original state builds byte-identical.
const SEAT_CLASS := {"tank": "bulwark", "blade": "twinfang", "caster": "voidcaller", "healer": "mender"}
const ALLY_LATENCY := 5
const ALLY_SLACK := 0.06

## The default Aspect for a seat given its class (Bloomweaver-healer defaults Wildgrove,
## every other seat/class keeps DEFAULT_ASPECT).
static func default_aspect(key: String, cls: String) -> String:
	if key == "healer" and cls == "bloomweaver":
		return "wildgrove"
	if key == "healer" and cls == "well":
		return "brim"
	if key == "blade" and cls == "reckoner":
		return "colossus"
	if key == "caster" and cls == "alchemist":
		return "brew"
	return String(DEFAULT_ASPECT.get(key, ""))

## Which healer class a seat is running (read off its kit) — so a disconnect takeover
## re-attaches the RIGHT AI policy. Returns "bloomweaver" only for a Bloomweaver seat.
static func cls_of(seat: Seat) -> String:
	if seat == null or seat.kit == null:
		return ""
	var scr: Script = seat.kit.get_script()
	if scr == null:
		return ""
	var gn := String(scr.get_global_name())
	if gn == "BloomweaverKit":
		return "bloomweaver"
	if gn == "WellKit":
		return "well"
	if gn == "ReckonerKit":
		return "reckoner"
	if gn == "AlchemistKit":
		return "alchemist"
	return ""

## A fight spec (broadcast in the server's `start` message):
##   {seed:int, enc:<Seal id>, seats:[{key,aspect,ai:bool} x4 in SEAT_KEYS order],
##    carry?:{fracs:[4], wounds:[4], mana:float}}
## `carry` (MAP-3b) folds the map campaign's persistent state into the fight so an
## online fight starts exactly where traversal left it — and because it rides the
## spec, every replica builds the identical opening state (lockstep-safe). Absent
## carry = a fresh full-HP pull (every existing Seal fight is byte-identical).
## `seat_boons` (online boons): seat_key -> {boon_id: true}. Ridden per seat so every
## replica builds the identical fight with each player's drafted boons applied. Absent /
## empty = a boon-less seat (AI raiders, or a seat that hasn't drafted) — byte-identical.
static func make_spec(seed: int, seat_cfg: Dictionary, enc: String = "riftmaw",
		carry: Dictionary = {}, seat_boons: Dictionary = {}, pack: Array = []) -> Dictionary:
	var seats: Array = []
	for key in SEAT_KEYS:
		var c: Dictionary = seat_cfg.get(key, {})
		var cls := String(c.get("cls", SEAT_CLASS[key]))
		var entry := {
			"key": key,
			"cls": cls,
			"aspect": String(c.get("aspect", default_aspect(key, cls))),
			"ai": bool(c.get("ai", true)),
		}
		var b: Dictionary = seat_boons.get(key, {})
		if not b.is_empty():
			entry["boons"] = b
		seats.append(entry)
	var spec := {"seed": seed, "enc": enc, "seats": seats}
	if not carry.is_empty():
		spec["carry"] = carry
	# PACK: a chain of encounter ids for one battle (pack[0] must equal `enc`). Size < 2
	# normalizes away — the spec (and the fight) stays byte-identical to a classic pull.
	if pack.size() >= 2:
		spec["pack"] = pack.duplicate()
	return spec

## Build the fight state from a spec — identically on every machine.
## `my_seat` only sets the view-side is_player flag (diag/event tagging; audited
## sim-neutral in raid mode) — pass "" on the server.
static func build(spec: Dictionary, my_seat: String = "") -> CombatState:
	var aspects := {}
	var classes := {}
	for e in spec.get("seats", []):
		var k := String(e["key"])
		aspects[k] = String(e["aspect"])
		classes[k] = String(e.get("cls", SEAT_CLASS.get(k, "")))
	var carry: Dictionary = spec.get("carry", {})
	# PACK (main): resolve the member chain (pure data in the spec → every replica builds
	# the same battle). pack[0] is the encounter on the field; absent = classic single fight.
	var pack_res: Array = []
	var pk: Array = spec.get("pack", [])
	if pk.size() >= 2:
		for pid in pk:
			pack_res.append(RaidContent.encounter_by_id(String(pid)))
	var enc_res: EncounterRes = pack_res[0] if not pack_res.is_empty() \
		else RaidContent.encounter_by_id(String(spec.get("enc", "riftmaw")))
	# ESCORT/VOLATILE burden (WORLD-PLAN §MEWGENICS STEALS ①) rides the carry as pure data:
	# append an enemy-side add to the ON-FIELD encounter (pack lead, or the single fight).
	# Absent burden = untouched, so every existing raid/zone/pack pull stays byte-identical.
	var burden := String(carry.get("burden", ""))
	if burden != "":
		RaidContent.apply_burden(enc_res, burden)
	var s := RaidContent.make_state(int(spec.get("seed", 1)),
		enc_res, aspects, my_seat, classes, pack_res)
	var seed_v := int(spec.get("seed", 1))
	for e in spec.get("seats", []):
		var key := String(e["key"])
		var seat: Seat = s.seats[SEAT_KEYS.find(key)]
		if bool(e.get("ai", true)):
			seat.policy = make_policy(key, seed_v, String(e.get("cls", SEAT_CLASS.get(key, ""))))
		else:
			seat.policy = null            # a human drives this seat via input frames
		# online boons: apply this seat's drafted boons to its kit (kits read `boons`)
		var sb: Dictionary = e.get("boons", {})
		if not sb.is_empty() and seat.kit != null:
			seat.kit.boons = sb
	# MAP-3b: fold the carried campaign state in (wounds cut max HP, then integrity of
	# what's left; the healer's mana carries too). Mirrors the offline _launch_map_fight.
	# (`carry` was hoisted above for the escort burden — same dict, reused here.)
	if not carry.is_empty():
		# INTEGRITY RETIRED: fights boot at FULL HP of the WOUND-reduced pool (a carried HP
		# fraction is meaningless — a healer tops it off in seconds). WOUNDS (max-HP cuts a
		# heal can't fix) are the sole HP stake; MANA still carries (the resource-tax pass
		# made it bite). An empty carry (a bare raid/single-Seal fight) skips this → identical.
		var wounds: Array = carry.get("wounds", [])
		var mana := float(carry.get("mana", 1.0))
		for i in s.seats.size():
			var u: Seat = s.seats[i]
			if i < wounds.size():
				u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - float(wounds[i]))))
			u.hp = u.hp_max                       # boot FULL of the (wounded) pool
			if u.role == "healer":
				u.resource = roundf(u.resource_max * mana)
	# FIGHT-ALTERING MARK (THE KILL SWITCH cash-out + devil's-bargain curse): rides the
	# carry → the spec, applied identically on every replica via the SHARED RaidMarks.
	RaidMarks.apply(s, carry.get("mark", {}))
	return s

## The standard AI raider for a seat — MUST be constructed identically everywhere
## (disconnect takeover swaps this in at an agreed tick on every replica).
static func make_policy(key: String, seed_v: int, cls: String = "") -> Policy:
	match key:
		"tank":
			var tp := RaidTankPolicy.new()
			tp.reaction_slack = ALLY_SLACK
			tp.rng = DetRng.new(seed_v * 2749 + 1337)
			return tp
		"blade":
			if cls == "reckoner":
				var rp := ReckonerPolicy.new()
				rp.latency_ticks = ALLY_LATENCY
				rp.rng = DetRng.new(seed_v * 2749 + 2338)
				return rp
			var bp := TwinfangPolicy.new()
			bp.latency_ticks = ALLY_LATENCY
			bp.rng = DetRng.new(seed_v * 2749 + 2338)
			return bp
		"caster":
			if cls == "alchemist":
				var ap := AlchemistPolicy.new()
				ap.latency_ticks = ALLY_LATENCY
				ap.rng = DetRng.new(seed_v * 2749 + 3339)
				return ap
			var cp := VoidcallerPolicy.new()
			cp.latency_ticks = ALLY_LATENCY
			cp.rng = DetRng.new(seed_v * 2749 + 3339)
			return cp
		_:
			# healer — the reworked Well, the Bloomweaver, or the default Mender
			if cls == "well":
				var lp := WellPolicy.new()
				lp.latency_ticks = ALLY_LATENCY
				lp.rng = DetRng.new(seed_v * 2749 + 5531)
				return lp
			if cls == "bloomweaver":
				var wp := BloomweaverPolicy.new()
				wp.latency_ticks = ALLY_LATENCY
				return wp
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
		s.seats[seat_i].policy = make_policy(SEAT_KEYS[seat_i], seed_v, cls_of(s.seats[seat_i]))
