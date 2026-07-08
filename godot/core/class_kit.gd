## ClassKit — the seam where class-specific behaviour hangs off the generic engine.
## CombatCore calls these hooks; the default implementations are no-ops so a seat
## with no kit (e.g. the M0 dummy tank) behaves as a plain punching bag. Each combat
## class (Bulwark first) subclasses this. This is how "the other three snap on top".
##
## All hooks must stay PURE and deterministic (no rendering / wall-clock / unseeded
## RNG) — they run inside the same reducer as everything else.
class_name ClassKit
extends RefCounted

## Per-tick upkeep (resource decay, buff bookkeeping). Runs early in update().
func upkeep(_s: CombatState, _seat: Seat) -> void:
	pass

## The defensive verb was pressed (window/cooldown already set by CombatCore).
func on_defense_press(_s: CombatState, _seat: Seat) -> void:
	pass

## THE ONE DODGE (DODGE-PLAN.md): opt in so a single SPACE press answers both a
## DEFENSIBLE swing (negate) and barrage beats, on one cooldown. Default false keeps
## the split "defense"/"dodge" verbs byte-identical for every class that hasn't moved.
func unified_dodge() -> bool:
	return false

## A DEFENSIBLE swing was negated by a well-timed press. Default = pure negate
## (no extra effect); Warden overrides to reflect + bank Counter + open Riposte.
func on_negate(_s: CombatState, _seat: Seat, _ability: AbilityRes) -> void:
	pass

## GEAR-1: a boss self-heal cast was DENIED (kick/stagger cancelled a HEAL_BOSS
## telegraph). Called for EVERY living kitted seat, whoever landed the denial —
## gear procs (Riftmaw Tooth) hang here. Default: no reaction (byte-identical).
func on_boss_heal_denied(_s: CombatState, _seat: Seat) -> void:
	pass

## M7: the universal dodge was pressed (accepted past its recovery), before any
## beat grading. The Mender cancels its in-flight cast bar here (dodging > casting).
func on_dodge_press(_s: CombatState, _seat: Seat) -> void:
	pass

## M7: a strike-beat verdict for this seat (a StrikeRes.Grade). PERFECT/GOOD/
## GRAZE/BAITED land at the press; MISS/READ at the beat's impact. Class payoffs
## hang here (Warden banks Counter on PERFECT...). Default: no reaction.
func on_strike_result(_s: CombatState, _seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, _grade: int) -> void:
	pass

## Execute a class ability by id, optionally aimed at `target` (click-cast heals).
## Return true if it fired (consumed resources/GCD).
func on_action(_s: CombatState, _seat: Seat, _id: StringName, _target: Seat = null) -> bool:
	return false

## Heal multiplier the CASTER applies to a heal, based on the TARGET (Brinkwarden:
## bigger the lower the target). Default 1.0.
func heal_mult(_target: Seat) -> float:
	return 1.0

## Called after a heal overheals `target` by `over`. The CASTER routes it
## (Tidecaller banks a Reservoir; Overflow upgrade shields the target). Default: none.
func on_overheal(_s: CombatState, _caster: Seat, _target: Seat, _over: float) -> void:
	pass

## Called after ANY heal this CASTER produced resolves (direct, HoT tick, bloom),
## with the effective HP restored and the overheal spill. The Bloomweaver builds
## Verdance off `eff` — the resource IS the efficiency meter. Default: none.
func on_heal(_s: CombatState, _caster: Seat, _target: Seat, _eff: float, _over: float) -> void:
	pass

## Called on the HEALER's kit whenever an absorb shield on `target` eats damage.
## `emptied` = this hit fully consumed the ward (Bloomweaver Perfect Ward / thorns).
## Default: none.
func on_absorb(_s: CombatState, _healer: Seat, _target: Seat, _eaten: float, _emptied: bool) -> void:
	pass

## Per-seat override of the group-damage f(hp%) curve (Brinkwarden: bloodied allies
## hit harder). Return < 0 to use the engine's default curve.
func dps_factor(_s: CombatState, _seat: Seat, _frac: float) -> float:
	return -1.0

## Reduce incoming damage before it lands (DR buffs, momentum mitigation).
## `size` is the AbilityRes.Size of the source swing (or NONE for melee/enrage).
func modify_incoming(_s: CombatState, _seat: Seat, dmg: float, _source: StringName, _size: int) -> float:
	return dmg

## React to damage actually taken (post-mitigation): generate rage/momentum, etc.
func on_damage_taken(_s: CombatState, _seat: Seat, _dmg: float, _source: StringName, _size: int) -> void:
	pass

## Multiplier applied to this seat's outgoing boss damage (Juggernaut momentum).
func outgoing_mult(_seat: Seat) -> float:
	return 1.0

## Defensive-press timing, seconds. Return < 0 to fall back to TuningConfig defaults.
func defense_active() -> float:
	return -1.0
func defense_cd() -> float:
	return -1.0

## Extra fields merged into the observation a policy sees (rage, momentum, ...).
func observe(_s: CombatState, _seat: Seat) -> Dictionary:
	return {}
