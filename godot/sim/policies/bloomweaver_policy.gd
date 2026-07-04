## BloomweaverPolicy — a competent AI anticipation-healer for the SEEDFALL kit. Triage
## order: pre-ward the telegraph victim, convert rot, cash a COOKED bed under a dying
## ally (dedicated Bloom) / mass-surge, spend the signature, then STACK-TO-DEPTH and go
## hands-off so beds can cook (the new discipline: never re-stack a bed that's already
## cooking near full — that would reset its ramp). The same Policy surface a human's
## click-cast adapter uses (human = AI seats).
##
## `latency_ticks` is the skill knob: 0 = reacts every tick (expert — stacks early,
## blooms cooked); higher = slower triage → stacks late (never cooks), blooms cold,
## wards wilt, allies die. Deterministic (no RNG).
class_name BloomweaverPolicy
extends Policy

var latency_ticks: int = 0
var _next_act: int = 0

func act(obs: Dictionary) -> Dictionary:
	var tick := int(obs.get("tick", 0))
	if tick < _next_act:
		return {}
	# M7: dodge an incoming aoe beat aimed at me — worth cancelling an Overgrowth for.
	# Behind the same latency gate as triage; feints are held. Deterministic, no RNG.
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
	var total_seeds := int(obs.get("total_seeds", 0))
	var soft := int(obs.get("soft_cap", 3))
	var hard := int(obs.get("hard_cap", 5))

	var lowest: Dictionary = {}
	var hurt := 0
	var dire := 0
	var tank: Dictionary = {}
	var no_bed := 0
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
			no_bed += 1
		if lowest.is_empty() or float(p["frac"]) < float(lowest["frac"]):
			lowest = p

	# 1) PRE-WARD the telegraph: single-target danger -> ward the victim; a raid nova ->
	#    ward whoever is most likely to drop. The ward is now sized by the seeds under it.
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

	# 3) EMERGENCY: cash a COOKED bed under a dying ally (dedicated Bloom); mass-surge if
	#    several drop. The tank triages earlier — a buster on a half-tank is lethal.
	if dire >= 2 and garden >= 2:
		return _cast("lifesurge")
	var save: Dictionary = {}
	if not tank.is_empty() and float(tank["frac"]) < 0.5:
		save = tank
	elif not lowest.is_empty() and float(lowest["frac"]) < 0.35:
		save = lowest
	if not save.is_empty():
		if bool(save["growth"]) and bool(save.get("cooked", false)) \
				and float(save["growth_heal"]) >= 25.0 and sap >= 5.0:
			return _cast("bloom", save["seat"])         # cash the cooked bed — the payoff
		if garden >= 2:
			return _cast("lifesurge")
		if bool(save["growth"]) and float(save["growth_heal"]) >= 20.0 and sap >= 5.0:
			return _cast("bloom", save["seat"])         # desperate: cash even a half-cooked bed
		if sap >= 15.0 and not bool(save["growth"]):
			return _cast("growth", save["seat"])        # late plant — better than nothing

	# 4) Signature when the gauge is worth cashing
	if aspect == "wildgrove" and verd >= 65.0 and total_seeds >= 6 and hurt >= 2:
		return _cast("wildbloom")
	if aspect == "thornveil" and verd >= 65.0 and (tg_live or hurt >= 2):
		return _cast("briarheart")

	# 5) OVER-CAP the tank right before a heavy single-target hit (spend efficiency to
	#    overload the wall). Never at the hard cap (a Growth there aliases to Bloom).
	if tg_live and victim != null and verd >= 15.0 and sap >= 15.0:
		var vt := _entry(party, victim)
		if not vt.is_empty() and vt["role"] == "tank" \
				and int(vt["stacks"]) >= soft and int(vt["stacks"]) < hard:
			return _cast("growth", victim)

	# 6) STACK-TO-DEPTH, then HANDS-OFF: build the tank to the soft cap FAST, then leave
	#    it to cook. Never re-stack a bed already at target depth (that resets its ramp).
	var tank_depth := mini(soft, 3)
	if not tank.is_empty() and sap >= 15.0:
		if not bool(tank["growth"]):
			return _cast("growth", tank["seat"])
		elif int(tank["stacks"]) < tank_depth:
			return _cast("growth", tank["seat"])

	# 7) Keep the dps seeded to depth 2 — pick the most-hurt bare/shallow ally.
	if sap >= 15.0:
		var pick: Dictionary = {}
		for p in party:
			if p["dead"] or p["role"] == "tank":
				continue
			var want := (not bool(p["growth"])) or int(p["stacks"]) < 2
			if want and (pick.is_empty() or float(p["frac"]) < float(pick["frac"])):
				pick = p
		if not pick.is_empty() and float(pick["frac"]) < 0.95:
			return _cast("growth", pick["seat"])

	# 8) Blanket: several bare allies + real damage flowing -> Overgrowth
	if no_bed >= 3 and hurt >= 2 and sap >= 40.0:
		return _cast("overgrowth")

	# 9) Rich and safe: a Thornveil pre-ward on the tank (melee eats it → thorns + Verdance).
	if sap >= 70.0:
		if aspect == "thornveil" and not tank.is_empty() and float(tank["absorb"]) <= 0.0:
			return _cast("bark", tank["seat"])

	# 10) Greed window: everyone healthy, gauge idle -> Thornlash the boss
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
