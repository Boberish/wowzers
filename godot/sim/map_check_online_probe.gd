## Deterministic proof of the ONLINE check contract (v6): the leader shows the ✓/✗
## LOCALLY (from the server-broadcast % + the pure die keyed off map_seed/node/choice),
## while the server resolves AUTHORITATIVELY. They MUST agree for every input, or a
## co-op check desyncs. This drives both sides over a matrix and asserts identical
## p / roll / success / leg-fx — the guarantee behind "no new netcode for the dice."
##   godot --headless --path godot --script res://sim/map_check_online_probe.gd
extends SceneTree

func _initialize() -> void:
	var fails := 0
	# The acting seat's server-side build ctx (a caster with interrupt/counter boons).
	var ctx := MapCheck.build_ctx([["interrupt"], ["interrupt"], ["counter"]], [],
		"disruptor", "caster", 0.8, 20, 4, 1, {}, {}, 0)
	var checked := 0
	var matched := 0
	for eid in ["helpdesk", "prompt_injection", "model_graveyard"]:
		var ev := MapContent.event(eid)
		var raw: Array = ev["choices"]
		for i in raw.size():
			var c: Dictionary = raw[i]
			if String(c.get("kind", "")) != "check":
				continue
			var chk: Dictionary = c["check"]
			# what the SERVER broadcasts to the leader for this choice:
			var info := MapCheck.chance(chk, ctx)
			var p0 := int(info["p"])
			var ladder: Array = MapCheck.nudge_ladder(chk, ctx)
			for seed in [1, 7, 4242, 0x5EED, 918273]:
				for node in [0, 3, 9]:
					for nudge in range(0, mini(MapCheck.NUDGE_MAX, int(ctx["entropy"])) + 1):
						checked += 1
						# ---- CLIENT (leader) resolves locally for display ----
						var p_cli := p0 if nudge == 0 else int(ladder[nudge - 1])
						var roll_cli := MapCheck.roll(seed, node, i, 0)
						var succ_cli := roll_cli < float(p_cli)
						var leg_cli: Dictionary = c.get("success" if succ_cli else "fail", {})
						# ---- SERVER resolves authoritatively ----
						var res := MapCheck.resolve(c, ctx, seed, node, i, 0, {"nudge": nudge})
						var ok := int(res["p"]) == p_cli \
							and bool(res["success"]) == succ_cli \
							and is_equal_approx(float(res["roll"]), roll_cli) \
							and str(res["fx"]) == str(leg_cli.get("fx", {}))
						if ok:
							matched += 1
						else:
							fails += 1
							if fails <= 3:
								print("  MISMATCH %s[%d] seed=%d node=%d nudge=%d : cli(p=%d,%s) vs srv(p=%d,%s)" % [
									eid, i, seed, node, nudge, p_cli, str(succ_cli),
									int(res["p"]), str(res["success"])])
	print("online check contract: %d/%d client==server  (%d check choices swept)" % [matched, checked, checked])
	# a gated choice: server rejection == client greying (same gate_ok), both ways
	var no_key := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, 0, {}, {}, 0)
	var have := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, 0, {"api_key": true}, {}, 0)
	var badge: Dictionary = (MapContent.event("prompt_injection")["choices"] as Array)[0]
	var gate_ok := not MapCheck.gate_ok(badge["gate"], no_key) and MapCheck.gate_ok(badge["gate"], have)
	print("gate: server rejects locked / accepts unlocked (== client grey): %s" % ("PASS" if gate_ok else "FAIL"))
	if not gate_ok:
		fails += 1

	# ---- the SERVER glue (NetServer.resolve_event_choice): nudge clamp, ⚡ spend, toast,
	# gate reject — driven directly, and cross-checked against the client-local resolve.
	var glue_ok := true
	var hd := MapContent.event("helpdesk")
	var hack: Dictionary = (hd["choices"] as Array)[1]        # the HACK check
	for nudge in [0, 1, 3, 9]:                                # 9 must clamp to min(3, ⚡hold)
		var hold := 4
		var srv := NetServer.resolve_event_choice(hack, ctx, 4242, 5, 1, nudge, hold)
		var eff_nudge: int = mini(3, mini(nudge, hold))
		var cli := MapCheck.resolve(hack, ctx, 4242, 5, 1, 0, {"nudge": eff_nudge})
		var toast_ok: bool = String(srv["toast"]).begins_with("✓") or String(srv["toast"]).begins_with("✗")
		var this_ok: bool = bool(srv["accept"]) and bool(srv["is_check"]) \
			and int(srv["entropy_after"]) == hold - eff_nudge \
			and bool(srv["success"]) == bool(cli["success"]) \
			and int(srv["p"]) == int(cli["p"]) and toast_ok
		if not this_ok:
			glue_ok = false
			print("  GLUE MISMATCH nudge=%d: srv(p=%d,%s,ent→%d) vs cli(p=%d,%s) toast=%s" % [
				nudge, int(srv["p"]), str(srv["success"]), int(srv["entropy_after"]),
				int(cli["p"]), str(cli["success"]), str(toast_ok)])
	# a free choice: accepted, not a check, ⚡ untouched
	var free0: Dictionary = (hd["choices"] as Array)[0]
	var fr := NetServer.resolve_event_choice(free0, ctx, 1, 1, 0, 0, 4)
	glue_ok = glue_ok and bool(fr["accept"]) and not bool(fr["is_check"]) and int(fr["entropy_after"]) == 4
	# the locked badge: rejected server-side
	var lg := NetServer.resolve_event_choice((MapContent.event("prompt_injection")["choices"] as Array)[0],
		no_key, 1, 1, 0, 0, 0)
	glue_ok = glue_ok and not bool(lg["accept"])
	print("server glue: nudge-clamp + ⚡-spend + ✓/✗ toast + free + gate-reject: %s" % ("PASS" if glue_ok else "FAIL"))
	if not glue_ok:
		fails += 1

	print("MAP CHECK ONLINE PROBE: %s" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)
