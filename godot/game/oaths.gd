## GEAR-2 — SWORN OATHS (Realm-1 display: SLAs). ONE oath per seat per fight, sworn
## at the boss node; kept = the Ledger row unlocks forever + a stakes-scaled purse
## (re-swearing an unlocked row is the replayable-fortune loop). Detectors read ONLY
## deterministic per-seat state (`seat.diag` / `seat.vars`) — never `state.events`.
## Design of record: PROGRESSION-PLAN.md (severity/purse table) + GEAR-CATALOG.md.
class_name Oaths
extends RefCounted

## The swearable rows on a boss's Ledger page.
static func rows(boss_id: String) -> Array:
	var out: Array = []
	for r in GearCatalog.table(boss_id):
		if String(r["row"]) == "oath":
			out.append(r)
	return out

## Deed verdict at the KILL (win path only — a lost fight breaks any oath).
static func kept(deed: Dictionary, s: CombatState, seat: Seat) -> bool:
	match String(deed.get("kind", "")):
		"zero_deaths":
			for u in s.seats:
				if not u.alive():
					return false
			return true
		"curses":
			var dropped := int(seat.diag.get("curse_dropped", 0))
			return dropped >= 1 and int(seat.diag.get("curse_answered", 0)) >= dropped
		"chain_intact":
			return int(seat.diag.get("negate", 0)) >= int(deed.get("n", 5)) \
				and int(seat.diag.get("chain_break", 0)) == 0
		"perfects_n":
			return int(seat.diag.get("perfect", 0)) >= int(deed.get("n", 8))
		"kicks_clean":
			return int(seat.vars.get("kicks", 0)) >= int(deed.get("n", 6)) \
				and int(seat.diag.get("kick_whiff", 0)) == 0
		"no_dips":
			for u in s.seats:
				if int(u.diag.get("bloodied_dip", 0)) > 0:
					return false
			return true
	return false

## Live mid-fight violation for the tracker banner. Only MONOTONE breaks fire (a
## count-up deed like perfects_n can still be met, so it stays quiet until the end).
static func broken_live(deed: Dictionary, s: CombatState, seat: Seat) -> bool:
	match String(deed.get("kind", "")):
		"zero_deaths":
			for u in s.seats:
				if not u.alive():
					return true
			return false
		"curses":
			# unfixable once the 2s answer window lapses with answered < dropped
			var dropped := int(seat.diag.get("curse_dropped", 0))
			return int(seat.diag.get("curse_answered", 0)) < dropped \
				and s.tick - s.boss.last_curse_tick > CombatCore.to_ticks(2.0, s.config.fixed_hz)
		"chain_intact":
			return int(seat.diag.get("chain_break", 0)) > 0
		"kicks_clean":
			return int(seat.diag.get("kick_whiff", 0)) > 0
		"no_dips":
			for u in s.seats:
				if int(u.diag.get("bloodied_dip", 0)) > 0:
					return true
			return false
	return false

## The purse for a KEPT oath (PROGRESSION-PLAN table): Tokens + a bend on THAT
## kill's drop roll. stakes = (3 - ring) + (version - 1); versions don't exist yet.
static func purse(sev: int, stakes: int) -> Dictionary:
	match clampi(sev, 1, 3):
		1: return {"tokens": 1 + stakes / 2, "pity": 2, "floor": "", "opus": false}
		2: return {"tokens": 2 + stakes, "pity": 0, "floor": "sonnet", "opus": false}
		_: return {"tokens": 3 + stakes, "pity": 0, "floor": "sonnet", "opus": stakes >= 2}

static func sev_label(sev: int) -> String:
	return ["", "I", "II", "III"][clampi(sev, 1, 3)]
