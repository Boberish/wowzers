## CampaignCore — the ONE campaign rulebook (REFIT-PLAN P3.1). The pure descent
## transitions that the offline HUD, the authoritative server, and any future shell
## all step: node entry, TICKET open/close, post-fight writeback, the Kill-Switch
## scavenge, and event-choice resolution. Node-free statics over the cp VIEW dict
## (MapFx's shape: fracs/wounds/mana/entropy/prior/inv/flags/marks/charge, plus
## tickets/closed/total/toast). Arrays mutate in place; scalar keys are the caller's
## to copy back (see raid_hud._cp_view / _cp_writeback; the server's campaign dict
## IS this shape already).
##
## This file KILLED the hand-kept mirrors ("_ticket_srv: Mirror of raid_hud._ticket_at,
## server-side" + the twin post-fight writebacks) — campaign rules land HERE once,
## never per-side again.
class_name CampaignCore
extends RefCounted

const REBOOT_FRAC := 0.35   ## a raider dead at a WON fight reboots at this integrity
const WOUND_STEP := 0.2     ## …and the crash leaves a CORRUPTED SECTOR (-max HP)…
const WOUND_CAP := 0.4      ## …stacking to this (only a Cooling DEFRAG repairs)
const MANA_FLOOR := 0.05    ## the healer's persisted reserves never go dry
const COOLING_FX := {"charge": 10, "mana": 0.75}   ## THROTTLE: +⏻, ease the reserves
const CACHE_FX := {"charge": 25}                    ## SALVAGE: +⏻ toward the Kill Switch

## First-visit bookkeeping for an entered node, in the canonical order both sides
## always ran: visited flag → credential shard → TICKET open/close → API key.
## Returns {first, key_grabbed, tokens}: the caller ceremonies the key (panel offline,
## toast online) and grants `tokens` where a purse exists (offline run economy).
static func enter_node(cp: Dictionary, n: Dictionary, has_stub := false) -> Dictionary:
	var first := not bool(n.get("visited", false))
	n["visited"] = true
	var tokens := 0
	if first and bool(n.get("shard", false)):
		# a credential shard, assembled toward root access (MAP-3c ROOT floor)
		cp["inv"]["shards"] = int(cp["inv"].get("shards", 0)) + 1
	if first:
		tokens = ticket_at(cp, n, has_stub)
	var key_grabbed := false
	if first and bool(n["key"]) and not cp["inv"].get("api_key", false):
		cp["inv"]["api_key"] = true
		key_grabbed = true
	return {"first": first, "key_grabbed": key_grabbed, "tokens": tokens}

## TICKETS (MAP-2): pick one up here, or close it if we're holding the matching one.
## Rewards feed the wound-attrition economy; closing the whole floor = a sprint-retro
## bonus. Sets cp.toast for the next map screen; returns the purse Tokens granted
## (reward + CURIO ticket-stub bonus + retro) — offline routes them through
## _gain_tokens (Hashgrinder doubling lives there), online has no purse yet.
static func ticket_at(cp: Dictionary, n: Dictionary, has_stub := false) -> int:
	var tokens := 0
	var topen := String(n.get("ticket_open", ""))
	if topen != "" and not cp["tickets"].has(topen):
		var td := MapContent.ticket(topen)
		cp["tickets"][topen] = String(td.get("title", "TICKET"))
		cp["toast"] = "📋  %s  —  picked up (turn it in deeper on this lane)" % String(td.get("title", "TICKET"))
	var tclose := String(n.get("ticket_close", ""))
	if tclose != "" and cp["tickets"].has(tclose):
		var td2 := MapContent.ticket(tclose)
		cp["tickets"].erase(tclose)
		cp["closed"] = int(cp["closed"]) + 1
		var reward: Dictionary = td2.get("reward", {})
		MapFx.apply(cp, reward)
		tokens += int(reward.get("tokens", 0))
		if has_stub:   # GEAR-1 (ARMORY strong) ticket stub: +10% integrity +1⏣
			MapFx.apply(cp, {"heal": 0.10})
			tokens += 1
		cp["toast"] = "✅  %s  —  CLOSED, reward claimed" % String(td2.get("title", "TICKET"))
		if int(cp["closed"]) >= int(cp["total"]) and int(cp["total"]) > 0:
			MapFx.apply(cp, MapContent.SPRINT_RETRO_FX)
			tokens += int(MapContent.SPRINT_RETRO_FX.get("tokens", 0))
			cp["toast"] = "★  SPRINT RETRO — every ticket closed! Sectors repaired, reserves topped."
	return tokens

## Post-fight persistence for ONE seat: integrity carries; a dead raider at a won
## fight REBOOTS (+ a corrupted sector); the healer's remaining mana carries.
static func writeback_seat(cp: Dictionary, u: Seat, i: int) -> void:
	var fracs: Array = cp["fracs"]
	if i < 0 or i >= fracs.size():
		return
	if u.alive():
		fracs[i] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
	else:
		fracs[i] = REBOOT_FRAC
		cp["wounds"][i] = minf(WOUND_CAP, float(cp["wounds"][i]) + WOUND_STEP)
	if u.role == "healer":
		cp["mana"] = clampf(u.resource / maxf(1.0, u.resource_max), MANA_FLOOR, 1.0)

## Post-fight persistence for the whole warband (the server's _end_fight and the
## HUD's floor path ran this same loop as twins — now it's one).
static func writeback(cp: Dictionary, s: CombatState) -> void:
	for i in s.seats.size():
		writeback_seat(cp, s.seats[i], i)

## GATE-exam variant: the VERDICT is the key, not the pulse — a lost exam reboots
## your slot even if its fail state left you standing (e.g. the healer's patient
## dying), and only your one raid slot carries in or out.
static func writeback_exam(cp: Dictionary, u: Seat, i: int, won: bool) -> void:
	var fracs: Array = cp["fracs"]
	if i < 0 or i >= fracs.size():
		return
	if won:
		fracs[i] = clampf(u.hp / maxf(1.0, u.hp_max), 0.0, 1.0)
	else:
		fracs[i] = REBOOT_FRAC
		cp["wounds"][i] = minf(WOUND_CAP, float(cp["wounds"][i]) + WOUND_STEP)
	if u.role == "healer":
		cp["mana"] = clampf(u.resource / maxf(1.0, u.resource_max), MANA_FLOOR, 1.0)

## THE KILL SWITCH: scavenge ⏻ from a cleared SKIRMISH (not a Seal — you cash out there).
static func skirmish_scavenge(cp: Dictionary) -> void:
	cp["charge"] = mini(100, int(cp["charge"]) + MapFx.SKIRMISH_CHARGE)

## PURE, authoritative resolution of an event choice (Node-free, testable). Gate-checks,
## rolls a CHECK on the deterministic die (identical to the leader's local display), spends
## ⚡ (always, on commit), and formats the ✓/✗ toast. Returns everything the caller applies.
## `accept:false` = a locked gate (reject). The die matches the client because both use the
## same (map_seed, node, i) and the same server-broadcast %.
## (MOVED verbatim from NetServer in P3.1 — the shell and the server resolve identically.)
static func resolve_event_choice(c: Dictionary, ctx: Dictionary, map_seed: int, node_id: int,
		i: int, nudge_req: int, entropy_have: int, attempt: int = 0) -> Dictionary:
	var gate: Dictionary = c.get("gate", {})
	if not gate.is_empty() and not MapCheck.gate_ok(gate, ctx):
		return {"accept": false}
	if MapCheck.check_like(String(c.get("kind", "free"))):
		var nudge := clampi(nudge_req, 0, mini(MapCheck.NUDGE_MAX, entropy_have))
		var att := clampi(attempt, 0, MapCheck.MULLIGAN_MAX)
		# ⚡ spent = nudge (pre-commit) + rerolls (attempt × cost); the die honours `att`
		var spend := nudge + att * MapCheck.MULLIGAN_COST
		var res := MapCheck.resolve(c, ctx, map_seed, node_id, i, att, {"nudge": nudge})
		var toast := ("✓ %d%% — " % int(res["p"]) if bool(res["success"]) \
			else "✗ rolled %d vs %d%% — " % [int(res["roll"]), int(res["p"])]) + String(res["result"])
		return {"accept": true, "is_check": true, "fx": res["fx"], "toast": toast,
			"entropy_after": maxi(0, entropy_have - spend), "success": bool(res["success"]),
			"p": int(res["p"]), "roll": int(res["roll"]), "nudge": nudge,
			"goto": String(res.get("goto", ""))}          # a check leg may fail-forward
	var fx: Dictionary = (c.get("fx", {}) as Dictionary).duplicate()
	# a free/branch choice's next stage: `branch` (kind branch) or `goto` (free)
	return {"accept": true, "is_check": false, "fx": fx, "toast": String(fx.get("result", "")),
		"entropy_after": entropy_have, "success": true,
		"goto": String(c.get("branch", String(c.get("goto", ""))))}
