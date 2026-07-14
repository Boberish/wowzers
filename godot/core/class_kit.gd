## ClassKit — the seam where class-specific behaviour hangs off the generic engine.
## CombatCore calls these hooks; the default implementations are no-ops so a seat
## with no kit (e.g. the M0 dummy tank) behaves as a plain punching bag. Each combat
## class (Bulwark first) subclasses this. This is how "the other three snap on top".
##
## All hooks must stay PURE and deterministic (no rendering / wall-clock / unseeded
## RNG) — they run inside the same reducer as everything else.
class_name ClassKit
extends RefCounted

## The drafted deck every kit reads (REFIT P4 hoist — these were byte-identical
## copies in all five kits). `boons`: drafted boon ids -> true (RaidNet.build folds
## a spec's per-seat boons in here). `modules`: equipped UI Module ids -> true.
var boons: Dictionary = {}
var modules: Dictionary = {}
## THE JAILBREAK DECK TAX (§7): ability ids poisoned by a run-length curse — CombatCore
## fizzles a pressed ability whose id is in here (offline only; empty = byte-identical).
var poisoned: Dictionary = {}

## Boon / Module lookups — the guarded-no-op idiom's foundation: absent = false,
## so an undrafted kit takes the vanilla path byte-identically.
func _b(id: String) -> bool:
	return bool(boons.get(id, false))

func _m(id: String) -> bool:
	return bool(modules.get(id, false))

## Seconds -> engine ticks at the fight's fixed rate (integer tick is truth).
func _tt(s: CombatState, sec: float) -> int:
	return CombatCore.to_ticks(sec, s.config.fixed_hz)

## Per-tick upkeep (resource decay, buff bookkeeping). Runs early in update().
func upkeep(_s: CombatState, _seat: Seat) -> void:
	pass

## The defensive verb was pressed (window/cooldown already set by CombatCore).
func on_defense_press(_s: CombatState, _seat: Seat) -> void:
	pass

## The defensive verb was RELEASED (TANK-PLAN §11.1 — the charged parry's release). Only
## the Duelist reads it; the default no-op keeps every other class byte-identical (a stray
## key-up costs nothing).
func on_defense_release(_s: CombatState, _seat: Seat) -> void:
	pass

## THE ONE DODGE (DODGE-PLAN.md): opt in so a single SPACE press answers both a
## DEFENSIBLE swing (negate) and barrage beats, on one cooldown. Default false keeps
## the split "defense"/"dodge" verbs byte-identical for every class that hasn't moved.
func unified_dodge() -> bool:
	return false

## BESPOKE DEFENSE (TANK-PLAN §1a, DUELIST-BRIEF S1): the tank runs its OWN graded parry +
## dodge instead of the shared dodge ration / binary negate. When true, CombatCore routes
## this seat's "defense" (PARRY main) and "dodge" (DODGE secondary) presses straight to the
## kit (on_defense_press / on_dodge_press — the kit owns wind + its own answer windows), and
## does NOT binary-negate a DEFENSIBLE swing aimed here: the hit flows through to _damage so
## the kit's modify_incoming applies GRADED PARTIAL mitigation (the partial-mit law, cap .90 —
## even a perfect leaks a sliver). Default false keeps every other class byte-identical.
func bespoke_defense() -> bool:
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

## THE STREAM (TANK-PLAN §0): a non-damage stream bar reached this seat — a FEINT
## (judge the read: press in window = BAITED, hold = READ) or an EAT (bookkeeping
## only; the damage rides _damage separately). `bar` is the committed entry, read-only.
## Default: no reaction (byte-identical for every non-stream class).
func on_stream_bar(_s: CombatState, _seat: Seat, _bar: Dictionary) -> void:
	pass

## Execute a class ability by id, optionally aimed at `target` (click-cast heals).
## Return true if it fired (consumed resources/GCD).
func on_action(_s: CombatState, _seat: Seat, _id: StringName, _target: Seat = null) -> bool:
	return false

## INTERRUPT-BY-ABILITY (COMBAT PILLAR #3): does pressing `id` carry a kick — the "interrupt
## tax" riding a class's dump / combo finisher? The moment such an ability COMMITS, CombatCore
## stops any live INTERRUPTIBLE cast (simple: press it during the cast, see _try_interrupt).
## Default false = this seat kicks nothing, so the interrupt path is never entered → byte-
## identical. Twinfang tags its Eviscerate, the Duelist tank its combo dump; a kit that carries
## a kick should also add `"carries_kick": true` to its observe() so the cast bar stops reading
## "uncontested".
func ability_interrupts(_id: StringName) -> bool:
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

## STATS PAGE v2 — the spec's own recap rows for the FULL REPORT page: whatever timing
## lines matter for THIS kit (Twinfang tempo-window %, Alchemist pour grades, the Well's
## charge floor). Each entry is {label:String, value:String, hint:String}, already formatted
## from seat.diag, so all per-spec display logic — and its rework drift — stays inside the
## kit file. Default [] = a kit with nothing spec-specific to add. Pure / read-only.
func recap_spec(_s: CombatState, _seat: Seat) -> Array:
	return []

## MeterPanel / band chrome — the class's accent colour. Returned as a built-in Color so the
## data layer never imports game/ui (Palette); a new kit self-colours the meter the day it
## merges, no MeterPanel edit. Default steel = a kit with no identity yet. Pure / read-only.
func accent() -> Color:
	return Color(0.56, 0.72, 0.88)   # generic steel
