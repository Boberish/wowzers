## Escort — the ESCORT / VOLATILE ticket (WORLD-PLAN §MEWGENICS STEALS ①), thinnest
## flagged slice. Carry a payload from a PICKUP node to a TURN-IN node; while carrying,
## fight/elite nodes gain an enemy-side BURDEN (an extra add the boss must withdraw to
## face) — a burden, NOT a buff, so the OVERWORLD POWER rule holds and the modifier lives
## on the enemy side. The carry state is PERMANENT: it rides the world save's per-zone
## flags (persistence-correct — stop mid-escort, come back still carrying).
##
## PURE LOGIC (a WorldSave + a node in → flag transitions + a burden id out), exactly like
## WorldContent is pure — so world_probe can exercise the whole state machine headlessly and
## raid_hud is only a thin caller behind raid_hud.ESCORT_PREVIEW. Flag off ⇒ nothing here is
## consulted and no flag is ever set ⇒ byte-identical. Even flag ON is byte-identical until a
## pickup fires (the burden only rides a spec's `carry` while carrying).
class_name Escort

const FLAG := "escort_grainvial"      ## per-zone world-save flag: "" | "carrying" | "done"
const BURDEN := "grain_rot"           ## RaidContent.apply_burden id applied while carrying

## Per-zone escort route (only the Gildfields defines one in this slice):
##   pickup — node id where you take the payload (a camp: the abandoned warden's post)
##   turnin — node id where you seal it (the Undermill door)
static func route(zid: String) -> Dictionary:
	match zid:
		WorldContent.ZONE1:
			return {"pickup": 4, "turnin": 19, "name": "THE CRACKED GRAIN-VIAL"}
	return {}

static func has_route(zid: String) -> bool:
	return not route(zid).is_empty()

static func state(save: WorldSave, zid: String) -> String:
	return String(save.flags(zid).get(FLAG, ""))

static func carrying(save: WorldSave, zid: String) -> bool:
	return state(save, zid) == "carrying"

## Entering node `nid`: fire any escort transition (pickup / turn-in) on the PERMANENT save
## and return a one-line message to fold into that node's stop ("" = nothing happened).
static func on_enter(save: WorldSave, zid: String, nid: int) -> String:
	var r := route(zid)
	if r.is_empty():
		return ""
	var st := String(save.flags(zid).get(FLAG, ""))
	if nid == int(r["pickup"]) and st == "":
		save.set_flag(zid, FLAG, "carrying")
		return "You lift %s from the warden's post. It weeps rot — every reaping thing on the road will smell it now." % String(r["name"])
	if nid == int(r["turnin"]) and st == "carrying":
		save.set_flag(zid, FLAG, "done")
		return "You seal %s beneath the Undermill. The wardens' rows will remember this. (escort complete)" % String(r["name"])
	return ""

## The burden a fight at this node carries right now — "" unless you're carrying and the
## node is a normal fight/elite (the capstone boss is spared so the slice stays fair).
static func burden_for(save: WorldSave, zid: String, node: Dictionary) -> String:
	if state(save, zid) != "carrying":
		return ""
	var k := String(node.get("kind", ""))
	if k == "fight" or k == "elite":
		return BURDEN
	return ""
