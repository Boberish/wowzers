## BloomweaverPolicy — a competent AI anticipation-healer. Triage order: pre-ward the
## telegraph victim, convert rot, BLOOM the garden under a dying ally, cash the
## signature, keep Growth rolling on the tank, blanket when sprawl damage comes.
## The same Policy surface a human's click-cast adapter uses (human = AI seats).
##
## `latency_ticks` is the skill knob: 0 = reacts every tick (expert); higher = slower
## triage → wards land late (wilt), blooms miss, allies die. Deterministic (no RNG).
class_name BloomweaverPolicy
extends Policy

var latency_ticks: int = 0
var _next_act: int = 0

func act(obs: Dictionary) -> Dictionary:
	var tick := int(obs.get("tick", 0))
	if tick < _next_act:
		return {}
	# M7: dodge an incoming aoe beat aimed at me — worth cancelling an Overgrowth
	# for. Behind the same latency gate as triage (sloppy healers react late and
	# eat beats); feints are held. Deterministic, no RNG.
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
		return {}                                   # Overgrowth cast bar running
	var action := _choose(obs)
	if not action.is_empty():
		_next_act = tick + 1 + latency_ticks
	return action

func _choose(obs: Dictionary) -> Dictionary:
	var party: Array = obs.get("party", [])
	if party.is_empty():
		return {}
	var sap := float(obs.get("sap", 0.0))
	var verd := float(obs.get("verdance", 0.0))
	var aspect := String(obs.get("aspect", "wildgrove"))
	var garden := int(obs.get("garden", 0))

	var lowest: Dictionary = {}
	var hurt := 0
	var dire := 0
	var tank: Dictionary = {}
	var no_growth := 0
	for p in party:
		if p["dead"]:
			continue
		if p["role"] == "tank":
			tank = p
		if float(p["frac"]) < 0.7:
			hurt += 1
		if float(p["frac"]) < 0.45:
			dire += 1
		if not bool(p["growth"]):
			no_growth += 1
		if lowest.is_empty() or float(p["frac"]) < float(lowest["frac"]):
			lowest = p

	# 1) PRE-WARD the telegraph: single-target danger -> ward the victim; a raid
	#    nova -> ward whoever is most likely to drop. The whole class in one rule.
	var tg: Dictionary = obs.get("telegraph", {})
	var tg_live := not tg.is_empty()
	var victim = obs.get("tg_victim")
	if tg_live and sap >= 25.0:
		if victim != null:
			var vp := _entry(party, victim)
			if not vp.is_empty() and not vp["dead"] and float(vp["absorb"]) <= 0.0:
				return _cast("bark", victim)
		elif bool(obs.get("tg_all", false)) and not lowest.is_empty() \
				and float(lowest["frac"]) < 0.6 and float(lowest["absorb"]) <= 0.0:
			return _cast("bark", lowest["seat"])       # save bark for single-target marks otherwise

	# 2) Sap Rot a debuff into flowers (off-GCD)
	for p in party:
		if not p["dead"] and p["debuff"] and sap >= 20.0:
			return _cast("saprot", p["seat"])

	# 3) EMERGENCY: bloom the garden under a dying ally; mass-surge if several drop.
	#    The tank triages earlier — a buster on a half-tank is lethal.
	if dire >= 2 and garden >= 2:
		return _cast("lifesurge")
	var save: Dictionary = {}
	if not tank.is_empty() and float(tank["frac"]) < 0.5:
		save = tank
	elif not lowest.is_empty() and float(lowest["frac"]) < 0.35:
		save = lowest
	if not save.is_empty():
		if bool(save["growth"]) and float(save["growth_heal"]) >= 20.0 and sap >= 15.0:
			return _cast("growth", save["seat"])         # double-tap = BLOOM
		if garden >= 2:
			return _cast("lifesurge")
		if sap >= 15.0 and not bool(save["growth"]):
			return _cast("growth", save["seat"])         # late plant — better than nothing

	# 4) Signature when the gauge is worth cashing
	if aspect == "wildgrove" and verd >= 65.0 and garden >= 3 and hurt >= 2:
		return _cast("wildbloom")
	if aspect == "thornveil" and verd >= 65.0 and (tg_live or hurt >= 2):
		return _cast("briarheart")

	# 5) The tank's Growth never drops (melee chip never stops)
	if not tank.is_empty() and not bool(tank["growth"]) and sap >= 15.0:
		return _cast("growth", tank["seat"])

	# 6) Blanket: several bare allies + real damage flowing -> Overgrowth
	if no_growth >= 3 and hurt >= 2 and sap >= 40.0:
		return _cast("overgrowth")

	# 7) Plant on a hurt, bare ally
	if not lowest.is_empty() and float(lowest["frac"]) < 0.85 and not bool(lowest["growth"]) and sap >= 15.0:
		return _cast("growth", lowest["seat"])

	# 8) Rich and safe: extend the garden (Wildgrove wants Flourish lit), or a
	#    Thornveil pre-ward on the tank — melee will eat it (thorns + Verdance)
	if sap >= 70.0:
		if aspect == "thornveil" and not tank.is_empty() and float(tank["absorb"]) <= 0.0:
			return _cast("bark", tank["seat"])
		for p in party:
			if not p["dead"] and not bool(p["growth"]):
				return _cast("growth", p["seat"])

	# 9) Greed window: everyone healthy, gauge idle -> Thornlash the boss
	if sap >= 80.0 and hurt == 0:
		return _cast("lash")

	return {}

func _entry(party: Array, seat) -> Dictionary:
	for p in party:
		if p["seat"] == seat:
			return p
	return {}

func _cast(id: String, target = null) -> Dictionary:
	if target != null:
		return {"type": "ability", "id": id, "target": target}
	return {"type": "ability", "id": id}
