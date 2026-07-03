## GEAR-1 (Curios) — the shared gear proc layer. Class kits call these tiny helpers
## at their proc sites; EVERYTHING is gated on `seat.gear`, so a gearless seat
## executes nothing and every gearless run stays byte-identical (the regression bar).
## Pure + deterministic (engine law): no rng, no wall-clock, no Nodes.
##
## Resource grants come back as floats and the KIT applies them through its own
## clamped gain helper (each class owns its cap) — GearFx never touches resources.
class_name GearFx
extends RefCounted

## Does this seat carry the curio?
static func has(seat: Seat, id: StringName) -> bool:
	return not seat.gear.is_empty() and seat.gear.has(id)

## One-shot per fight: true the FIRST time only (marks gear_vars, which the fight
## builder resets). False forever if the curio isn't carried.
static func once(seat: Seat, id: StringName) -> bool:
	if not has(seat, id) or bool(seat.gear_vars.get(id, false)):
		return false
	seat.gear_vars[id] = true
	return true

## LE CHAT'S BELL — +30 starting resource. Kits call from upkeep (any tick works;
## the flag makes it fire exactly once, on the first upkeep of the fight).
static func bell_grant(seat: Seat) -> float:
	return 30.0 if once(seat, &"lechat_bell") else 0.0

## LE CHAT'S BELL (ARMORY strong half) — the warm start keeps humming: true for the
## fight's first 10s. Kits double their regen (or trickle a dead resource) while it
## rings, at the same site as the Scratchpad check.
static func bell_live(s: CombatState, seat: Seat) -> bool:
	return has(seat, &"lechat_bell") and s.tick < CombatCore.to_ticks(10.0, s.config.fixed_hz)

## RIFTMAW TOOTH (ARMORY strong) — a DENIED boss self-heal hands your verbs back
## (defensive verb + universal dodge reset — mini() so it never delays one already
## ready) and pays +20 resource. Kits call from on_boss_heal_denied and apply the
## grant via their own clamped gain helper.
static func tooth_grant(s: CombatState, seat: Seat) -> float:
	if not has(seat, &"riftmaw_tooth"):
		return 0.0
	seat.defense_ready_tick = mini(seat.defense_ready_tick, s.tick)
	seat.dodge_ready_tick = mini(seat.dodge_ready_tick, s.tick)
	pop(s, seat, &"riftmaw_tooth")
	return 20.0

## SWAN SONG — on this seat's death: a 200 farewell blast + 25 to each living ally.
## Kits call at the END of on_damage_taken (hp is already applied and clamped there,
## so death is visible; _check_end hasn't run yet, so the blast lands this tick).
static func damage_taken(s: CombatState, seat: Seat) -> void:
	if seat.gear.is_empty():
		return
	if seat.hp <= 0.0 and once(seat, &"swan_song"):
		CombatCore.damage_boss(s, seat, 200.0, &"swan_song")
		for u in s.seats:
			if u != seat and u.alive():
				CombatCore.heal_unit(s, u, 25.0, seat, &"swan_song")
		pop(s, seat, &"swan_song")

## One-shot per fight keyed on gear_vars ONLY (no gear check) — pop throttles etc.
static func flag_once(seat: Seat, key: StringName) -> bool:
	if bool(seat.gear_vars.get(key, false)):
		return false
	seat.gear_vars[key] = true
	return true

## SCRATCHPAD — "use the thinking time": true while a boss wind-up ≥ 6s is live.
## Kits treble their regen (or trickle a dead resource) while this holds.
static func scratchpad_live(s: CombatState, seat: Seat) -> bool:
	if not has(seat, &"scratchpad") or s.telegraph == null:
		return false
	return s.telegraph.dur_ticks >= CombatCore.to_ticks(6.0, s.config.fixed_hz)

## View-only proc flash (the HUD pops the curio's name) — cosmetic, never gameplay.
static func pop(s: CombatState, seat: Seat, id: StringName) -> void:
	CombatCore.emit_event(s, {"t": "curio", "player": seat.is_player, "seat": seat, "id": String(id)})
