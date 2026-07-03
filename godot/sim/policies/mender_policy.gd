## MenderPolicy — a competent AI healer. Triage: keep the lowest ally up, dispel,
## AoE-heal when the group is hurt, and cash the signature before a danger telegraph.
## The same Policy a human's click-cast adapter uses (human = AI seats).
##
## `latency_ticks` is the skill knob: 0 = reacts every tick (expert); higher = slower
## triage, so allies drop further before heals land → deaths under spikes. Produces
## win-rate BANDS in sims. Deterministic (no RNG in the policy).
class_name MenderPolicy
extends Policy

var latency_ticks: int = 0
var _next_act: int = 0

func act(obs: Dictionary) -> Dictionary:
	var tick := int(obs.get("tick", 0))
	if tick < _next_act:
		return {}
	# M7: dodge an incoming aoe beat aimed at me — worth cancelling a cast for
	# (that IS the design tension). Sits behind the same latency gate as triage,
	# so a sloppy healer reacts late and eats beats. Deterministic, no RNG.
	if bool(obs.get("dodge_ready", false)):
		var tg: Dictionary = obs.get("telegraph", {})
		var beats: Array = tg.get("strikes", [])
		for b in beats:
			if bool(b.get("resolved", false)) or bool(b.get("answered", false)) \
					or not bool(b.get("mine", true)) or bool(b.get("feint", false)):
				continue
			if int(b.get("guard", 0)) == StrikeRes.Guard.UNANSWERABLE:
				continue
			if float(b.get("remaining", 9.0)) <= 0.14:
				_next_act = tick + 1 + latency_ticks
				return {"type": "dodge"}
			break                                   # next beat not in range yet
	if not obs.get("casting", {}).is_empty():
		return {}                                   # busy with a cast bar
	var action := _choose(obs)
	if not action.is_empty():
		_next_act = tick + 1 + latency_ticks
	return action

func _choose(obs: Dictionary) -> Dictionary:
	var party: Array = obs.get("party", [])
	if party.is_empty():
		return {}
	var mana := float(obs.get("mana", 0.0))
	var aspect := String(obs.get("aspect", "tidecaller"))

	# lowest living ally + counts
	var lowest: Dictionary = {}
	var hurt := 0
	for p in party:
		if p["dead"]:
			continue
		if float(p["frac"]) < 0.7:
			hurt += 1
		if lowest.is_empty() or float(p["frac"]) < float(lowest["frac"]):
			lowest = p

	# 1) Dispel a debuff (cheap, off-GCD)
	for p in party:
		if not p["dead"] and p["debuff"] and mana >= 10.0:
			return _cast("dispel", p["seat"])

	# 2) Signature before a danger telegraph
	var danger := _danger(obs)
	if aspect == "tidecaller" and float(obs.get("reservoir", 0.0)) > 180.0 and danger:
		return _cast("surge")
	if aspect == "brinkwarden" and float(obs.get("nerve", 0.0)) > 55.0 and danger:
		return _cast("laststand")

	# 3) Emergency single-target save
	if not lowest.is_empty() and float(lowest["frac"]) < 0.35 and mana >= 22.0:
		return _cast("flash", lowest["seat"])

	# 3.5) RAID battle-rez: a fallen raider is lost until rekindled. Only reach here
	# when no LIVING ally is critical (step 3 returns first), the long channel is off
	# cooldown, and we can afford it — so the 6s commitment is a safe save, not a panic.
	if bool(obs.get("raid", false)) and bool(obs.get("revive_ready", false)) \
			and mana >= float(obs.get("revive_mana", 340.0)):
		for p in party:
			if p["dead"]:
				return _cast("revive", p["seat"])

	# 4) Group healing when several are hurt
	if hurt >= 3 and mana >= 30.0:
		return _cast("well")            # engine no-ops if on cooldown; falls through next tick
	if hurt >= 2 and mana >= 40.0:
		return _cast("cascade")

	# 5) Refresh a HoT on a hurt, un-HoT'd ally
	if not lowest.is_empty() and float(lowest["frac"]) < 0.85 and int(lowest["hots"]) == 0 and mana >= 18.0:
		return _cast("renew", lowest["seat"])

	# 6) Efficient top-up
	if not lowest.is_empty() and float(lowest["frac"]) < 0.8 and mana >= 16.0:
		return _cast("mend", lowest["seat"])

	# 7) Restore mana when idle and low
	if mana < 160.0:
		return _cast("medit")

	return {}

func _danger(obs: Dictionary) -> bool:
	var tg: Dictionary = obs.get("telegraph", {})
	return not tg.is_empty() and bool(tg.get("danger", false))

func _cast(id: String, target = null) -> Dictionary:
	if target != null:
		return {"type": "ability", "id": id, "target": target}
	return {"type": "ability", "id": id}
