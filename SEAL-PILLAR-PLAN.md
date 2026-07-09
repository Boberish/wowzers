# SEAL-PILLAR-PLAN — execution brief for the Seal Pillar Pass v1

**Status: CLAIMABLE (authored 2026-07-06 with Bill; hand this doc to the executing agent).**
Claim it in MASTER-PLAN's Coordination Log, work in a worktree (`git worktree add
../wow-seal-pillars -b seal-pillars`), and read this WHOLE doc before touching anything.
Companion context: `WORLD-PLAN.md` §COMBAT PILLARS (the why) · MASTER-PLAN §BOSSES (the
summary block this doc expands) · CLAUDE.md (laws, run-book, gotchas).

## The goal in one line

Bring the 4 raid Seals **closer to** the DODGE RATION pillar — *fewer, more meaningful
dodge beats for non-tank seats (~3–8 per fight), tanks keep the densest footwork* —
WITHOUT redesigning anything. Bill is explicitly not sure of the boss end-state yet:
this is a cheap, reversible tuning nudge, not the boss rework. When in doubt, do less.

## Scope

- **In:** `godot/data/raid/raid_content.gd` (the 4 Seals + their add waves' beat
  content), `godot/sim/raid_sim.gd` (new diagnostics + reporting), MASTER-PLAN §BOSSES
  (record results).
- **OUT — do not touch:**
  - **Kick chains / verses** (`_verse`/`_empower_verse` content, cds, amounts): interrupt
    content retunes only when interrupt-by-ability lands with the class reworks
    (WORLD-PLAN pillar 3). ~~The frozen Voidcaller still plays the caster seat.~~
    **⚠ 2026-07-10 (THE PURGE): Voidcaller is DELETED; the Alchemist (brew) is the caster
    default and carries NO kick** — verses go uncontested in the interim, so this pass
    baselines against the post-purge alchemist-comp bands, not the old voidcaller bands.
  - **Double-Check** (`gem_check`) and any tank-string/tank-swing content — tanks keep
    dense footwork by design.
  - **ULTRATHINK** (`myth_ultra`) — 3 aoe beats, the raid's marquee moment. Whole. Its
    beats are a *documented budget exception*.
  - **Engine files** (`core/`): not needed — see Phase A. If you believe you need an
    engine touch, stop and re-read Phase A; if you still do, it must be diag-only and
    byte-identical, and you flag it loudly in the log.
  - Solo bosses, gates, skirmishes, Tempo kit files (another session pilots Twinfang —
    never edit ANY kit while ANY sim runs), net protocol, HUD.

## Current beat sources (read the code, but here's the map — `data/raid/raid_content.gd`)

Beat mechanics: `aoe: true` beats are answered by EVERY living seat individually;
`rand_target` beats roll ONE victim per beat (healer included) at cast start. Grades land
per seat in `seat.diag` (`perfect/good/graze/miss` + `baited/read` for feints) via
`CombatCore._bump_diag`. Boss ability timers FREEZE during any telegraph; melee never
freezes. Expert TTKs (10-seed spot check, 2026-07-06): riftmaw ~57s · mistral ~49s ·
gemini ~64s · mythos ~84s — sloppy fights run LONGER, so they see more casts.

| Seal | Beat source | Shape | cd | Est. beats/non-tank seat/fight |
|---|---|---|---|---|
| **Vorathek** | `volley` Void Volley | **aoe ×3** | 13±2 | **~9–12 (over budget — the main offender)** |
| **Mistral** | `mist_fists` Mixture of Fists | rand ×3 | 16±2 | ~1.5–2.5 (under budget — fine) |
| **Gemini** | `gem_abtest` A/B Test | rand ×4 | 17±2 | ~3 |
| | `bard_sonnet` (BARD.EXE add) | **aoe ×3** | 12±1.5 | +3–6 while the add lives → **total ~6–9 (borderline)** |
| **Mythos** | `myth_fanout` Agentic Fan-Out | rand ×5 | 18±2 | ~4–5 |
| | `myth_ultra` ULTRATHINK | aoe ×3 | 42±4 | +3–6 **(exception — keep)** |
| | `sonnet_tools` (SONNET add) | **aoe ×3** | 11±1.5 | +3–6 while the add lives → **total ~10–17 (over budget)** |

These are static estimates — Phase A produces the real table before anything changes.

## Phase A — INSTRUMENT (must be byte-identical)

Add a per-seat **beat-budget table** to `raid_sim.gd`, printed per Seal per skill tier:

- Per seat (tank/blade/caster/healer): `presented` (= perfect+good+graze+miss),
  `perfect/good/graze/miss`, `feints` (baited+read). All of this already exists in
  `seat.diag` — this is aggregation + printing, **sim-side only, zero engine files**.
- Per beat-SOURCE cast counts (how many times volley/abtest/fanout/etc. actually fired):
  count **sim-side** by watching `state.telegraph` transitions in the sim's step loop
  (the sim drives `CombatCore` directly) — do NOT add engine counters for this.
- Print at least at `good` tier (the budget's reference tier) — all three tiers is better.

**Gate A (prove it before Phase B):** `raid_sim` determinism probes PASS ×4 Seals AND
checksums byte-identical to pre-change (a print-only diff cannot move them; if checksums
moved, you touched something you shouldn't have). Record the baseline table in the log.

## Phase B — RETUNE to budget (the deliberate re-baseline)

Budget: **~3–8 answerable beats per non-tank seat per fight at good tier**, exceptions
documented (ULTRATHINK). Prefer these levers in this order:
1. **Cast frequency (cd)** — fewer barrages per fight, each one still matters.
2. **Victims per cast / aoe→rand_target** — fewer seats answer each cast.
3. **Beat count per cast** — last resort; it changes the *feel* of the move most.

Recommended starting moves (verify against the Phase A table first):
- **Vorathek `volley`: cd 13→~20** (teaching Seal: the motion appears ~2×/fight ≈ 6
  beats/seat). If still hot, 3 beats→2.
- **Mistral: no change expected** (already under; it's the easy Seal — don't buff it).
- **Gemini `bard_sonnet`: cd 12→~16**, or convert its aoe beats→`rand_target` (BARD
  serenades ONE person — arguably funnier). A/B Test itself is roughly on budget.
- **Mythos `myth_fanout`: cd 18→~24–26** (keep all 5 beats — the fan-out IS its
  identity; make it rarer, not smaller). **`sonnet_tools`: aoe→`rand_target`**
  ("Parallel Tool Calls" hitting different targets is more thematic anyway) and/or
  cd 11→~15. ULTRATHINK untouched.

**⚠ The reverse-M7.2 trap — compensate the pressure.** Telegraphs freeze the boss's
other timers. Fewer barrage casts ⇒ fewer freezes ⇒ everything else cycles FASTER
(partial self-compensation on tank pressure), but sloppy tiers lose the beat-miss damage
that was killing them ⇒ expect loose win rates to drift UP. Pull them back with the
**unavoidable-pressure levers, never with more beats**: melee chip (`e.melee` — the
resource-tax precedent), nova/cataclysm amounts, DoT pressure, phase mults. `./tune.sh
<seal> 30 all --dmg=…` is the fast iteration loop (~15s); bake numbers into
`raid_content.gd` when a build feels right, then run the full gate.

**Band targets (curve preserved, expert stays ~100):**
| Seal | Pre-pass (300 seeds) | Target after |
|---|---|---|
| Vorathek | 100 / 100 / ~97 | ~same (teaching Seal) |
| Mistral | 100 / 100 / 100 | 100/100/100 (by design) |
| Gemini | 100 / 100 / 92 | ~100 / ~100 / **88–93** |
| Mythos | 100 / 95 / 43 | 100 / **92–97** / **≤50** (sloppy must still lose hard) |

The blade seat is mid-Tempo-rework, so treat exact percentages as indicative — **gate
hard on determinism + the beat-budget table + curve ORDER, not on ±a few pp.** If a
band lands way outside its target and no melee/nova nudge fixes it without distorting
the fight, STOP and record the tension for Bill rather than forcing it.

## Verification (the merge-back gate)

1. `raid_sim` determinism probes PASS ×4 Seals (default probes on, seed0=1 run).
2. **300-seed bands per Seal** via `scripts/psim.sh raid_sim 300 8 -- --boss=<seal>`
   (or one combined run) — record the full band table + the final beat-budget table.
3. Budgets: every non-tank seat within 3–8 at good tier, exceptions listed (ULTRATHINK).
4. `ui_smoke_raid` ALL OK · `net_smoke` ALL OK (content changes shift fight checksums —
   that's expected and fine; both replicas share the code. No protocol change here, but
   online play always needs server+clients on the same commit).
5. `twinfang_sim` still green (you shouldn't have touched anything it reads; prove it).

## Wrap-up (a task isn't done until the plan says so)

- Update MASTER-PLAN §BOSSES: replace the SEAL PILLAR PASS block's plan text with
  RESULTS (new bands, beat table, knobs changed with old→new values), tick your
  Coordination Log claim.
- Note the re-baseline explicitly: fight checksums CHANGED on purpose (content retune);
  any future byte-identity gate baselines from this merge forward.
- Leave a "v2 candidates" list: anything you saw but didn't touch (e.g. per-beat
  damage feel, add-window pacing, whether Mistral wants one signature dodge moment).

## Environment notes (this box = the laptop)

Godot 4.7-stable at `~/.local/bin/godot` (installed 2026-07-06). Fresh worktree: run
`godot --headless --path godot --import` FIRST or `class_name`s won't resolve. First
sim run logs a harmless `cannot open res://out/...` (gitignored dir, created on write).
`godot/out/` CSVs are gitignored — paste band tables into MASTER-PLAN, don't commit CSVs.
Repo has an `origin` remote — do NOT push; Bill decides when to sync.
