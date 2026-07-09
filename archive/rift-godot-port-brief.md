# Project Rift — Godot 4 Port Brief

*Paste this into `CLAUDE.md` at the repo root (or use it to seed one). It carries the full project state so a fresh Claude Code session can pick up without the original chat. Keaton is an experienced full-stack dev — keep guidance architectural, not hand-holdy.*

---

## What this is
A co-op roguelike built on **MMO trinity combat with character movement removed** and replaced by **timed active decisions**. Each role isolates the interesting raiding choices — triage, resource management, cooldown sequencing, reading boss telegraphs — into one distinct **verb**. Solo-playable with AI allies; the dream is 4-player co-op. PC, keyboard + mouse first. Long-term engine: **Godot 4**.

Progression is a Hades-style deckbuilder: "starts functional, builds toward specialized." Each class picks one of **two Aspects** at run start, which grants a signature mechanic and biases the between-fights draft.

**The four browser prototypes are the executable design spec.** They are vanilla single-file HTML/JS, no build step, and each has been headless-balance-verified. **Port the behavior, not the JS.** Lift the tuned numbers as starting values, then rebalance in-engine.

## The roster (all four combat classes built; Support class still unbuilt)
- **Bulwark — Tank** · verb: *mitigate / gamble.* *Warden* (parry → banks **Counter** → empowered riposte / Vindicate) vs *Juggernaut* (**Momentum**: eating/landing hits builds damage + mitigation, dodging **dumps** it; cash out with Avalanche). → `rift-bulwark-specs.html`
- **Twinfang — Melee DPS** · verb: *drive the rhythm.* *Tempo* (Flow **escalation tiers** transform the kit the deeper you hold the beat → **Coup de Grâce** capstone) vs *Venomancer* (three poison types kept live for a **Toxic Synergy** ramp you **detonate** with Rupture; rewards mixing normal/perfect strikes). → `rift-twinfang-specs.html`
- **Voidcaller — Caster DPS** · verb: *interrupt.* No dodge; **Space = interrupt** on a cooldown that can't catch everything. Boss casts near-continuously (heal / nuke / empower); **un-kicked heals heal the boss** (hard DPS-check), and a clean break heals you (sustain tied to skill). *Disruptor* (interrupts bank **Backlash** → **Overload** nuke that scales with casts broken) vs *Silencer* (interrupts **Silence** + leave **Exposed** → **Quietus**). Resource: **Focus**. Draftable extra interrupt spells (Silence, Counterspell). → `rift-voidcaller.html`
- **Mender — Healer** · verb: *keep-alive.* Click-cast raid frames + mana (VuhDo-style). *Tidecaller* (overhealing **banks** a **Reservoir** you **Surge** into raid shields right before a spike — play a beat *ahead*) vs *Brinkwarden* (heals get **huge and cheaper the lower** the target, so you let allies ride low and catch them; **bloodied allies hit harder**; holding them in the red builds **Nerve** → **Last Stand** — play a beat *behind*, on purpose). → `rift-mender-specs.html`
- **Launcher:** `rift.html` mounts all four in isolated `<iframe>`s (class select → each game's own Aspect pick).
- **Design doc:** `rift-design-plan.md` — §5b is the authoritative Aspect model.

## The core model to preserve — DATA-DRIVEN ENCOUNTERS
This is the most important thing to carry over. Every boss in the prototypes is **pure data** (the JS `ENCOUNTERS` array). Keep it that way — the next design milestone is *authoring the first real boss as data*, tailored so each mechanic pokes a specific role's verb (a parry-able tankbuster, an interruptible heal-cast, a raid spike that wants a Tidecaller Surge or a Brinkwarden Last Stand, poison/DoT phases for Venomancer + the dispel game).

A boss is:
- `melee`: `{every, min, max}` — continuous tank auto-attacks (not telegraphed).
- `abilities[]`: each `{id, name, tag, cast, cd, jitter, danger, resolve(m, target)}` where `cast` = telegraph length in seconds, `resolve` runs when the telegraph completes, `m` = current phase multiplier, `danger` = priority + red styling. Optional `mark` picks a victim at cast **start** (shown during the telegraph).
- `phases[]`: HP-threshold breakpoints `{at, mult, speed}` that ramp damage and cadence.
- optional `enrage`: hard timer → escalating raid-wide damage.

**Shared combat loop, each tick (dt):** regen resources → advance the player's in-progress cast → tick HoTs / DoTs / absorbs → `bossThink(dt)` (melee + advance a live telegraph, else pick the most-due ability; danger wins ties) → **apply group damage to boss = Σ over living allies of `ally.dps × f(hp%)`** → check win/lose.

**Win condition = that damage line.** Healthy allies deal more damage, so the boss dies before your resource/party runs out. Default `f = 0.3 + 0.7 * hp%`. Brinkwarden **overrides** `f` so bloodied allies hit harder (living on the edge speeds the kill) — keep that override as a hook, not a special-case.

## Suggested Godot 4 architecture
Map the data-driven JS **1:1 onto Godot Resources** — this is the natural fit and makes boss authoring a `.tres` file rather than code.

- `EncounterRes` (Resource): melee dict, `Array[AbilityRes]`, `Array[PhaseRes]`, enrage, intro.
- `AbilityRes` (Resource): id, name, tag, cast, cd, jitter, danger + an **effect**. Prefer an `enum kind` + params (`HEAL_BOSS / NOVA / DOT / TANKBUSTER / MARK_NUKE / EMPOWER / CHANNEL …`) over a script `Callable`, so bosses stay fully data-authored. Add kinds as new bosses need them.
- `AspectRes` / `UpgradeRes`: signature ability + draft-pool bias.
- `CombatController` (Node): owns party + boss state and the tick loop; phase logic. Emits **signals** — `telegraph_started(ability)`, `telegraph_resolved(ability)`, `unit_damaged(unit, amt, src)`, `unit_healed(unit, amt, overheal)`, `unit_died(unit)`, `resource_changed(...)`, `boss_hp_changed(...)`, `encounter_won` / `encounter_lost`. The HUD and raid frames **subscribe** to these — this replaces the imperative `render()` the prototypes call every frame.
- **Per role:** one scene for that role's input verb + HUD, all sharing `CombatController`. Healer = raid-frame grid with click-cast (hover + number key → cast on that unit). Tank = eat/dodge/parry-for-resource + telegraph reader. Caster = cast bar + interrupt. Melee = rhythm bar.
- **Damage/heal core:** `damage()` = absorb-then-HP; `healUnit()` = heal-absorb-then-HP-then-overheal, returning effective heal and exposing the overheal (Tidecaller banks it; the base "Overflow" upgrade converts a slice to shield). Route Last Stand's raid damage-reduction through `damage()`.
- **Co-op / threat (later, but design boss data for it now):** everyone-has-a-taunt threat model — the boss commits to a target it must choose, enabling tank swaps and hot-potato debuff spread.

## Recommended first milestone
Port **one class end-to-end** as a vertical slice, building the shared `CombatController` + Resource schema underneath it — then the other three snap on top. Best first pick: **Bulwark (tank)** — the tightest, most self-contained loop (single target, clearest telegraph → react verb), so you build the boss/telegraph/phase engine without also solving a raid-frame grid on day one. Do the **healer second** (most UI-heavy; needs frames to exist first). After one class runs, author an `EncounterRes` and you're positioned for the "first boss designed around the roster" step.

## Files to drop in the repo (reference implementations)
```
rift-design-plan.md          full design doc (§5b = Aspect model)
rift-bulwark-specs.html       tank: Warden / Juggernaut
rift-twinfang-specs.html      melee DPS: Tempo / Venomancer
rift-voidcaller.html          caster DPS: Disruptor / Silencer
rift-mender-specs.html        healer: Tidecaller / Brinkwarden
rift.html                     launcher (mounts all four)
```
Search each file's `ABILITIES` / `ENCOUNTERS` / Aspect-constant blocks for the verified balance numbers.
