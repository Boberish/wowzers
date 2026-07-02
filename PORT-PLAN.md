# Project Rift — Godot 4 Port Plan

> Read `CLAUDE.md` first for the locked decisions and the non-negotiable determinism rules. This doc is the *how* and the *order*.

## The mental model (for a web dev new to gamedev)

Think of `CombatCore` as a **pure reducer / business-logic layer** — like a backend service with no UI. It takes `(state, dt)` or `(state, action)` and returns the next state. It knows nothing about pixels, browsers, sockets, or the OS clock.

Three completely different programs `import` that same reducer:
- **The client** — draws the state and turns your keypresses into `perform(action)`.
- **The server** — the authoritative copy; it's the *real* game, clients are just windows into it.
- **The sim runner** — runs the reducer millions of times with no graphics to tune numbers.

Because there is exactly one copy of the rules, the game you play, the game your wife plays, and the numbers your balance spreadsheet trusts can **never disagree**. Everything in this plan exists to protect that property.

```
                        ┌───────────────────────────────┐
                        │  CombatCore  (pure reducer)    │
                        │  update(state, dt)             │
                        │  perform(state, action)        │
                        │  — no rendering / clock / RNG  │
                        │    beyond a seeded PRNG in state│
                        └───────────────┬───────────────┘
              ┌─────────────────────────┼─────────────────────────┐
              ▼                         ▼                         ▼
     ┌─────────────────┐      ┌───────────────────┐     ┌──────────────────┐
     │ CLIENT (browser)│      │ SERVER (headless, │     │ SIM RUNNER       │
     │ renders signals │◄────►│ Docker+tunnel)    │     │ (godot --headless│
     │ input→perform() │  WS  │ authoritative tick│     │  seed×config grid│
     └─────────────────┘      └───────────────────┘     │  → CSV)          │
                                                        └──────────────────┘
```

## Architecture layers

1. **`CombatCore`** (`RefCounted`, pure) — the reducer. Fixed-timestep `update`, seeded RNG, `bossThink` scheduler, phase machine, `damage()`/`heal_unit()`, the group-damage line, `perform(action)`. No `Node`, no rendering, no wall clock.
2. **Data (Resources, authored as `.tres`)** — `EncounterRes`, `AbilityRes` (enum `EffectKind` + params, **no script closures** — closures aren't serializable), `PhaseRes`, `AspectRes`, `UpgradeRes`, and a `TuningConfig` holding every balance constant.
3. **Seat model** — every participant (you, an AI ally, the boss's current target) is a seat `(role, obs-adapter, action-set, policy, fidelity)`. `policy.act(obs) -> action|null`. Human = seat whose policy is the input adapter.
4. **`CombatController`** (`Node`) — owns the live `state`, runs the tick loop, calls `CombatCore`, and **emits signals**: `telegraph_started`, `telegraph_resolved`, `unit_damaged`, `unit_healed`, `unit_died`, `resource_changed`, `boss_hp_changed`, `encounter_won/lost`.
5. **View** — HUD + raid frames + (later) sprites/animations. Pure **subscribers** to signals. This is why the visual layer bolts on late and cheaply (see M6): the engine doesn't know it exists.
6. **Netcode** — server runs `CombatController` authoritatively; clients send tick-stamped inputs and receive state/signal deltas over WebSocket.
7. **`SimRunner`** (autoload, headless) — loops `CombatCore` over a `{class+spec × draft × tuning × skill × seed}` grid → CSV/JSON.

---

## Milestones

Sizing is relative effort, not calendar. **M0 + M1 are the real investment** (they build all the shared machinery); after that, classes "snap on."

### M0 — Walking skeleton (no gameplay yet) · size: M
Prove the pure core + headless pipeline *before* any class or UI exists.
- Godot 4 project (GDScript), folder structure, `TuningConfig`/`EncounterRes`/`AbilityRes`/`PhaseRes` Resource classes.
- `CombatCore` skeleton: `state` dict, fixed-30Hz `update`, integer tick, seeded mulberry32, tick-stamped input queue, signal list.
- Trivial encounter: one boss with one telegraphed ability + **a party-of-one seat + one stat-block ally seat + the group-damage line** (yes, even now — see M1 note).
- `SimRunner` autoload that runs N seeds headless and dumps a CSV. Even trivial output proves determinism + the sim pipeline end-to-end.
- **Exit check:** same seed → byte-identical result twice; two different "framerates" → identical result.

### M1 — Bulwark vertical slice (first real class), local single-player · size: L
The tightest self-contained loop → build the engine under it.
- Port the **Gatekeeper** encounter as a `.tres` (data): `bossThink` one-slot scheduler, phase machine (`[{1,1,1},{0.4,1.15,1.15}]`), telegraph resolution.
- Bulwark seat: rage-from-damage (`round(dmgTaken*0.42)`), 1.0s GCD, abilities (Cleave/Rampage/Fortify/Bloodthirst/Shockwave), and the **Space defensive negate as a window-overlap test** (`swing.dodgeable && tick < seat.dodging_until`, against `DEF.active`).
- Both Aspects as `AspectRes`: **Warden** (Parry→Counter→Vindicate, `PARRY_REFLECT=50`, riposte) and **Juggernaut** (Momentum snowball→Avalanche, `MOM_DMG=0.06`/`MOM_DR=0.025`).
- HUD (signal subscribers): boss HP, swing bar with red zone + flashing DODGE/PARRY prompt, rage bar, ability buttons w/ cooldowns, DPS meter.
- **Bake in the seat/party abstraction now, don't defer.** Bulwark is 1v1, but the analysis flagged that it exercises *none* of the party / group-damage / ally model that AI allies and co-op need. So: model Bulwark as a party-of-one, keep the stat-block ally + group-damage line from M0 live, and write a **Bulwark AI policy** so the fight can be bot-played. Run one throwaway 2-seat sim (Bulwark + stat-block DPS) to prove the ally path before moving on. This costs ~little and de-risks the exact thing Bulwark otherwise hides.
- **Exit check:** you can beat Gatekeeper by hand as Warden and as Juggernaut; the AI policy can too; a headless sim of the same fight produces sane win/TTK numbers.

### M2 — Online: dedicated headless server + browser client · size: L
Deliver "playable online with your wife."
- Run `CombatController` authoritatively in a **headless server** build. Clients send `{tick, action, target}`; server is the single source of truth and streams state/signals back.
- **WebSocket** transport (browser + native). Client renders from server state (optional later: client-side prediction; authority stays server-side).
- **Latency reconciliation for the sub-second defensive window** — the parry/dodge negate matches a press against `DEF.active` (0.34–0.62s), so reconcile using the client's input tick, not arrival time.
- Ship it: **web (WASM) export** of the client (mind the COOP/COEP headers), **Docker image** for the server, **Cloudflare Tunnel** for the `wss://` endpoint. Two people in one Gatekeeper fight.
- **Exit check:** you host the server in Docker on your desktop; your wife opens a browser link and joins your Bulwark fight; no desync.

### M3 — Balance-sim system (make tuning first-class) · size: M
Turn the M0 harness into a real tuning tool.
- Full sweep grid: `{class+spec, draft path, TuningConfig override, skill profile, seed 1..N (2k–10k)}`.
- **Skill is a policy parameter** `{latency, window-accuracy, priority weights}` → report **win-rate bands** (floor/median/expert), not a single fragile number.
- Per-cell record: win/lose, TTK (p10/p50/p90), **loss-cause histogram** (player death vs enrage vs timeout), HP remaining, resource waste, missed dodges/interrupts; healer adds deaths/mana-at-end/overheal.
- Emit CSV/JSON. **This is the "outside Godot" part you sensed:** *generation* runs in-engine (single source of truth), *analysis/plots* you do in **Python/pandas** over the CSVs — your comfort zone, zero risk of logic drift.
- **First, reconcile the prototype bugs/mismatches** (see `CLAUDE.md`) so you sim the intended numbers, not the buggy ones.
- **Exit check:** `godot --headless` sweeps a parameter and writes a CSV; a Python notebook plots win-rate vs that parameter.

### M4 — Mender (Healer) vertical slice + real co-op · size: L
Now the party/group-damage model pays off for real.
- Raid-frame grid + click-cast (hover + number key), mana + 1.2s GCD, HoTs/DoTs/absorbs, `heal_unit()` with overheal banking.
- A **real party of AI-DPS allies** at FULL fidelity (policies driving the ability engine), so you heal while bots deal damage down the group line.
- Both Aspects: **Tidecaller** (bank overheal → Reservoir → Surge shields, `TIDE_CONV=0.55`) and **Brinkwarden** (`f(hp%)` override: bloodied allies hit harder, discontinuity at 40%; Nerve → Last Stand). Keep the `f` override as a hook.
- **Exit check:** solo Mender + 3 AI DPS beats a boss; a human can swap in for any AI seat mid-design (interchangeability proven).

### M5 — Twinfang + Voidcaller, then 4-player co-op · size: M each
- Snap the two remaining classes onto `CombatCore`: Twinfang rhythm/Flow bar + poison synergy; Voidcaller cast bar + `Space`-interrupt clean-zone + Focus.
- Full 4-player co-op: any mix of human/AI seats (solo = 1 human + 3 AI; co-op up to 4 human).
- Add the **everyone-has-a-taunt threat model** so the boss commits to a target (tank swaps, hot-potato debuffs). Author boss data for it now.

### M7 — Strike Strings: Expedition-33-style graded defense · size: L  *(pulled ahead of M6 — DONE, see CLAUDE.md status)*
The single-window "circle cast, one press at the end" defense grows into a **rhythm layer**. The engine is already turn-shaped (one telegraph at a time, other timers frozen) — a string makes the boss's "turn" a multi-beat combo and grades every answer.
- **StrikeRes beats:** an `AbilityRes` gains an optional `strikes` array — each beat has its own impact moment (`at`), damage share, size, guard type (`DODGEABLE` / `BLOCKABLE` = partial-even-on-perfect / `UNANSWERABLE`), per-beat `feint` (press = BAITED, hold = READ) and `aoe` (every seat answers individually). Empty array = classic ability; **all pre-M7 content is byte-identical**.
- **Universal dodge:** a new `{"type":"dodge"}` action for EVERY class, separate from the class defensive verb (guard/kick stay untouched). Short recovery between presses; a press that answers nothing whiffs into a long lockout — panic-mashing eats the rest of the combo. Grading by press-to-impact delta: **PERFECT** (~0.14s, full negate + class payoff) / GOOD / GRAZE (partial) / MISS. Grade windows sized for the 30 Hz tick (33ms granularity — don't author tighter than ±2 ticks).
- **Healers are now hittable** by `aoe` beats (the untargetable rule stays for everything classic) → dodge-vs-cast-bar tension: dodging cancels your cast (mana unpaid, time lost). New raid loss cause: `healer_death`.
- **Class payoffs** via a new `ClassKit.on_strike_result(grade)` hook: Warden banks Counter on PERFECT, Jugg banks Momentum, (later) Twinfang perfect-dodge feeds Flow. Stat-block allies auto-roll dodges (config chance, authoritative rng).
- **Teach it on the Duelist** (a multi-beat combo with a stutter feint — the discipline boss grows a rhythm test), then a Mender encounter with an aoe string (healer personally dodges; allies' partial misses create triage). Sims grow grade diagnostics (perfect%, whiffs, baits, reads) via a deterministic `state.diag` counter dict.
- UI: the cast dial grows **beat pips** around the ring (feints hollow/purple), grade pops at the press, SHIFT = dodge everywhere (healers also get SPACE — their only defensive key).

### M6 — First data-authored boss for the roster + the visual layer · size: M
- Author a fresh `EncounterRes` where each mechanic pokes a specific role's verb (parry-able tankbuster, interruptible heal-cast, a raid spike that wants a Tidecaller Surge or Brinkwarden Last Stand, a poison phase).
- **Visual representation** (your "sprite + animations" goal): a boss sprite whose animation states are driven purely by existing signals — `telegraph_started` → wind-up, `telegraph_resolved` → attack, phase change → transition. Player abilities/spells become animation reps triggered by their actions. Because the view is a **signal subscriber**, this is additive: you never touch the sim to add art. Your current "UI-only" build stays valid the whole way; art is a late, low-risk layer.

---

## Where your two big worries land
- **"Online day 1, test fast":** delivered at end of **M2** — Docker server on your desk + browser link, no installs for testers.
- **"The game revolves around tuning":** the determinism rules (M0) + `TuningConfig` + `SimRunner` (M3) make thousands of seeded, reproducible sims the backbone. In-engine generation = truth; Python analysis = your ergonomics.
- **"Good AI for bad guys and good guys":** bad guys are data-authored encounters; good guys are `policy.act(obs)` seats with a skill knob — the *same* policies serve solo play, co-op fill, and the balance sweeps.
