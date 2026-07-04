## MapFx — the ONE place a Topology event's effect dict is applied to the campaign
## state. Before this existed there were THREE hand-copies (raid_hud._apply_map_fx
## offline, net_server._apply_fx_srv online, raid_map_sim._apply_fx in the walker)
## that silently diverged the moment a new reward key was added. They all route here
## now, so a new fx key lands everywhere at once.
##
## `cp` is a "campaign-view" Dictionary — a bag of live references the caller owns:
##   {fracs:[f×N], wounds:[f×N], mana:f, entropy:i, tokens:i, prior:i,
##    inv:{}, flags:{}}
## Only `fracs` is required; every other key is optional and its fx branch simply
## no-ops when absent (so the solo hp_frac path, the sim's {fracs,wounds,mana} carry,
## and the full online campaign all pass the same dict shape they already hold).
## Arrays mutate in place (by ref); SCALARS are written back onto the dict, so a
## caller holding mana/entropy/… as its own member must copy them back after the call
## (raid_hud does; net_server's cp IS the dict so it persists directly).
##
## BYTE-IDENTITY: for the keys the old appliers handled (heal/hurt/mana/repair/
## patch/draft) this reproduces their exact arithmetic and clamps. Order differs from
## the sim copy but every op is independent (fracs / mana / wounds / lowest-frac), and
## `patch` always reads fracs AFTER heal/hurt in all four, so results are identical.
## The new keys (wound/tokens/entropy/prior/key/shard/flag) are inert unless an event
## actually carries them — so every existing event/ticket/cooling reward is unchanged.
class_name MapFx
extends RefCounted

const HP_FLOOR := 0.05           ## events bruise but never kill — only combat kills
const WOUND_CAP := 0.6           ## corrupted sectors can pile, but not past this

static func apply(cp: Dictionary, fx: Dictionary) -> void:
	var fracs: Array = cp.get("fracs", [])

	# --- integrity (raid-wide heal / hurt), clamped to the 5% floor ---
	var heal := float(fx.get("heal", 0.0))
	var hurt := float(fx.get("hurt", 0.0))
	if heal != 0.0 or hurt != 0.0:
		for i in fracs.size():
			fracs[i] = clampf(float(fracs[i]) + heal - hurt, HP_FLOOR, 1.0)

	# --- healer reserve (carries as a fraction; a refuel only ever raises it) ---
	if fx.has("mana") and cp.has("mana"):
		cp["mana"] = clampf(maxf(float(cp["mana"]), float(fx["mana"])), HP_FLOOR, 1.0)

	# --- DEFRAG: clear every corrupted sector ---
	if bool(fx.get("repair", false)) and cp.has("wounds"):
		var w: Array = cp["wounds"]
		for i in w.size():
			w[i] = 0.0

	# --- CORRUPTED SECTOR: a max-HP cut only `repair` clears (the fail with teeth) ---
	if fx.has("wound") and cp.has("wounds"):
		var w2: Array = cp["wounds"]
		var amt := float(fx["wound"])
		for i in w2.size():
			w2[i] = minf(WOUND_CAP, float(w2[i]) + amt)

	# --- EMERGENCY PATCH: +25% to the single most-battered raider ---
	# (a solo "draft" salvage is raidified to this by the caller; treated identically)
	if bool(fx.get("draft", false)) or bool(fx.get("patch", false)):
		if fracs.size() > 0:
			var lo := 0
			for i in fracs.size():
				if float(fracs[i]) < float(fracs[lo]):
					lo = i
			fracs[lo] = clampf(float(fracs[lo]) + 0.25, HP_FLOOR, 1.0)

	# --- currencies (all inert unless the event carries them) ---
	var d_tok := int(fx.get("tokens", 0))
	if d_tok != 0 and cp.has("tokens"):
		cp["tokens"] = int(cp.get("tokens", 0)) + d_tok
	var d_ent := int(fx.get("entropy", 0)) + int(fx.get("refund_entropy", 0))
	if d_ent != 0 and cp.has("entropy"):
		cp["entropy"] = maxi(0, int(cp.get("entropy", 0)) + d_ent)
	var d_pri := int(fx.get("prior", 0))
	if d_pri != 0 and cp.has("prior"):
		cp["prior"] = maxi(0, int(cp.get("prior", 0)) + d_pri)

	# --- access / inventory ---
	if cp.has("inv"):
		var inv: Dictionary = cp["inv"]
		if bool(fx.get("key", false)):
			inv["api_key"] = true
		if bool(fx.get("shard", false)):
			inv["shards"] = int(inv.get("shards", 0)) + 1

	# --- P6 fight-altering mark: sabotage the NEXT Seal (merged into cp.marks; applied
	# at the next fight build, then cleared). Absent = untouched. ---
	if fx.has("mark") and cp.has("marks"):
		(cp["marks"] as Dictionary).merge(fx["mark"] as Dictionary, true)

	# --- cross-node run flags (Phase 3 ripple; map-layer only) ---
	if cp.has("flags"):
		var flags: Dictionary = cp["flags"]
		if fx.has("flag"):
			flags[String(fx["flag"])] = true
		if fx.has("clear_flag"):
			flags.erase(String(fx["clear_flag"]))
	# NOTE: `gear` (a specific curio drop) is equip-side and stays with the caller
	# (the offline HUD equips into _map_gear); MapFx leaves it untouched by design.
