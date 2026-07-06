# SEAL-PILLAR-PASS — WORK IN PROGRESS (pause note, 2026-07-06)

**Branch:** `seal-pillars` (worktree `../wow-seal-pillars`). Paused at Bill's request for a
machine restart. This note is committed on the branch so ANY resuming session can continue.
Delete it before the final merge to main.

## State: Phase A DONE + committed. Phase B NOT started (zero content edits yet).

- **Commit `08b427f`** — Phase A instrumentation in `godot/sim/raid_sim.gd` (sim-side only).
  Adds a per-seat **beat-budget table** (presented = perfect+good+graze+miss; feints =
  baited+read, from existing `seat.diag`) + per-source **cast counts** (watch `s.telegraph`
  flip to a fresh instance). Printed per Seal per skill tier. `_write_csv` untouched.
- **GATE A PROVEN.** determinism PASS ×4 Seals, checksums identical to pre-change baseline;
  results CSV byte-identical. Baseline checksums (good to re-verify against):
  riftmaw `2944557473685282330` · mistral `4276933282488538635` ·
  gemini `882806584239960679` · mythos `5226496300050276706`.
- Coordination Log claim line added (🔨 seal-pillars · §BOSSES).

## THE KEY FINDING — the real numbers are already in budget

Baseline beat tables recorded at **60 seeds/tier** (`--probes=0`, all three tiers). The
budget = **~3–8 answerable beats / non-tank seat / fight at GOOD tier** (ULTRATHINK exempt).

| Seal | non-tank `presented` @good | verdict |
|---|---|---|
| **Vorathek** | 6.0 (all from `volley` aoe×3, casts 2.0) | **in budget** (top of comfortable) |
| **Mistral** | ~1.4 (`mist_fists` rand×3, casts 2.0) | under — **fine by design, don't buff** |
| **Gemini** | blade 5.0 / caster 4.8 / healer 5.0 (`gem_abtest` rand×4 ~2 + `bard_sonnet` aoe×3 @casts 1.0 ~3) | **in budget** |
| **Mythos** | blade 8.2 / caster 8.6 / healer 7.9 RAW | **~5 after backing out ULTRATHINK** (`myth_ultra` casts 1.0 × 3 aoe = 3 exempt) → in budget |

**The plan's static estimates (Vorathek 9–12, Mythos 10–17) were pessimistic.** Phase A's
whole point ("produce the real table before anything changes") did its job: the beats are
already distributed within the pillar. Tank seats run hot by design (Vorathek 6.0, Gemini
9.3 incl. `gem_check` string + 2.0 feints, Mythos 8.2) — that's the DODGE RATION pillar
("tanks keep the densest footwork"), left alone.

### Win bands at baseline (60 seeds — indicative, blade mid-Tempo-rework)
- Vorathek: 100 / 100 / 96.7 (sloppy: tank_death=1, healer_death=1)
- Mistral:  100 / 100 / 100
- Gemini:   100 / 98.3 / 65.0 (sloppy healer_death-dominant — 60-seed noise vs the 300-seed 92; re-run at 300)
- Mythos:   100 / 93.3 / 31.7 (good healer_death=4; sloppy healer_death-dominant)
(300-seed reference from the plan: Vorathek 100/100/97 · Gemini 100/100/92 · Mythos 100/95/43.)

## Phase B DECISION FOR BILL (the reason to pause here)

Because every Seal is **already within budget at good tier**, the aggressive cuts the plan
sketched (Vorathek `volley` cd 13→20, Mythos `fanout` cd 18→26, aoe→rand conversions) would
push Seals **UNDER** budget and soften fights for no benefit — the opposite of the intent.
Recommended options, lightest first (Bill picks):

1. **NO-OP content (recommended).** The pillar is met; ship Phase A's instrumentation as the
   deliverable, record the finding, leave Seal content alone. Fully reversible (it's a no-op).
2. **Single light nudge:** Mythos raw non-tank sits at the 8 ceiling (8.2–8.6). If we want
   headroom, `myth_fanout` cd 18→~22 pulls fanout casts ~1.9→~1.6 (≈ −0.5 beats/seat → ~8.0
   raw / ~5 net). Marginal; compensate only if sloppy drifts up (it won't much).
3. **Follow the plan's cuts anyway** — NOT recommended; distorts fights that are already on
   target. Only if Bill wants the Seals visibly *lighter* than today, not just "in budget."

My read: **do (1) or (2).** This is exactly the plan's "when in doubt do less / Bill isn't
sure of the boss end-state" caveat.

## RESUME CHECKLIST
1. `cd ../wow-seal-pillars`; if `main` advanced, `git merge main` (CLAUDE.md changed on main
   during this session — Twinfang/Alchemist split, unrelated to Seals).
2. Decide Phase B with Bill (options above). If no-op: skip to step 5.
3. If tuning: edit `godot/data/raid/raid_content.gd`. Iterate with `./tune.sh <seal> 30 all
   [--dmg=…]` (~fast). Compensate softening ONLY via melee/nova/dot/phase — NEVER more beats
   (reverse-M7.2). OUT: `gem_check`, `myth_ultra`, verses/chains, engine files.
4. Content checksums re-baseline ON PURPOSE (record new determinism checksums).
5. Verify gate: determinism PASS ×4 · 300-seed bands via `scripts/psim.sh raid_sim 300 8 --
   --boss=<seal>` (bands) + a direct `--seeds=…` run per Seal for the beat table · budgets
   3–8 non-tank (back out ULTRATHINK) · `ui_smoke_raid` + `net_smoke` + `twinfang_sim` green.
6. Update MASTER-PLAN §BOSSES (bands + beat table + knobs old→new), tick Coordination Log,
   leave v2 candidates. Delete THIS file. Merge to main (do NOT push — Bill syncs origin).

## Baseline beat-table raw dumps
Saved to scratch (`/tmp/.../scratchpad/beatbase_<seal>.txt`) — may not survive a machine
restart. Regenerate any time:
`for b in riftmaw mistral gemini mythos; do ~/.local/bin/godot --headless --path godot \
--script res://sim/raid_sim.gd -- --boss=$b --seeds=60 --skills=expert,good,sloppy \
--probes=0; done`
