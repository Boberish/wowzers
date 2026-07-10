## DuelistCreeds — the CREED data for THE DUELIST (TANK-PLAN §3). Mirrors the WellCreeds /
## TwinfangCreeds static API (get_creed / field / ids / v1_ids / hides_tag) so the shared HUD
## framework dispatches by name. A Creed is the run-long TEMPERAMENT — how the tank trades safety
## for reward. Each is a bundle of IDENTITY-default modifiers the kit reads via DuelistKit._cr();
## an EMPTY creed_id ("") applies NONE of them → the base build stays byte-identical (the gate).
## Numbers are first-cut (playtest tunes). Curated picks, NOT rarity-weighted (Hades-aspect style).
class_name DuelistCreeds
extends RefCounted

const IDENTITY := {
	"parry_perfect_mult": 1.0,   # scales the PERFECT parry window (Veteran widens = easier timing)
	"counter_mult": 1.0,         # scales the counter hit-back (Veteran ×0.75, Wager ×1.4)
	"combo_cap_delta": 0,        # ◆ cap change (Veteran −1)
	"parry_cost_mult": 1.0,      # scales parry WIND cost (Wager ~×1.3 = 4.5)
	"miss_leak_bonus": 0.0,      # Wager: an un-answered/whiffed hit leaks +this
	"parry_land_double": false,  # Wager: a PERFECT parry banks ◆◆ (double the pip)
	"wind_regen_mult": 1.0,      # Bellows halves passive regen (×0.5)
	"clean_wind_bonus": 0.0,     # Bellows: every clean answer instantly refunds +this wind
	"miss_wind_refund": 0.0,     # Veteran: a MISS/whiff refunds this much wind (the learner's mercy)
	"no_parry": false,           # Dancer: the parry button is GONE
	"dodge_is_parry": false,     # Dancer: a PERFECT dodge counters + banks ◆ (every other perfect)
	"baited_lockout_bonus": 0.0, # Dancer: a baited dodge locks out +this seconds
}

const CREEDS := {
	"veteran": {
		"name": "The Veteran", "kicker": "The learner's blade", "type": "EASE",
		"blurb": "Forgiving timing, a wider PERFECT window, and a missed swing refunds half its wind — but the counter runs −25% and the ◆ cap is 4. Caps itself so you graduate out.",
		"parry_perfect_mult": 1.45,
		"counter_mult": 0.75,
		"combo_cap_delta": -1,
		"miss_wind_refund": 0.5,
	},
	"wager": {
		"name": "The Wager", "kicker": "The greed pole", "type": "GREED",
		"blurb": "Parry costs 4.5 and a miss leaks +10% — but a LAND banks ◆◆ and the counter runs +40%. Live at the edge; the hit-back pays for it.",
		"parry_cost_mult": 1.29,     # 3.5 → ~4.5
		"miss_leak_bonus": 0.10,
		"parry_land_double": true,
		"counter_mult": 1.40,
	},
	"bellows": {
		"name": "The Bellows", "kicker": "The rhythm-changer", "type": "STRAT",
		"blurb": "Passive WIND regen is halved — but every clean answer refunds +1.5 wind instantly. The pool becomes a chain: keep answering and you never run dry; miss and you starve.",
		"wind_regen_mult": 0.5,
		"clean_wind_bonus": 1.5,
	},
	"dancer": {
		"name": "The Dancer", "kicker": "The WILD — one button", "type": "RULE",
		"blurb": "The PARRY button is GONE. A PERFECT dodge IS the parry (counter + ◆ every other perfect); a GOOD stays a dodge; a baited lockout runs +0.2s. Pure height-reading, one press.",
		"no_parry": true,
		"dodge_is_parry": true,
		"baited_lockout_bonus": 0.20,
	},
}

const V1 := ["veteran", "wager", "bellows", "dancer"]

static func get_creed(id: String) -> Dictionary:
	return CREEDS.get(id, {})

static func field(id: String, key: String):
	if id == "":
		return IDENTITY[key]
	return CREEDS.get(id, {}).get(key, IDENTITY[key])

static func ids() -> Array:
	return CREEDS.keys()

static func v1_ids(_aspect := "") -> Array:
	return V1.duplicate()

static func hides_tag(_id: String, _tag: String) -> bool:
	return false
