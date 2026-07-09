---
name: slate-loop
description: Start or restart THE SLATE MACHINE — the two 15-minute loops that walk SLATE-PLAN.md's queues: Phase 1 branch slates per class/spec, then Phase 2 full deck designs from each slate's top-3 branches. Invoke in a fresh session to resume after a session died (token exhaustion, restart, crash). State lives in SLATE-PLAN.md; the crons are only the heartbeat.
---

# SLATE LOOP — start/restart the slate machine (both phases)

The queues, passes, laws, and loop protocols all live in **`SLATE-PLAN.md`** — read it first,
top to bottom (§0–§4 Phase 1 slates · §5–§6 Phase 2 decks). This skill only (re)arms the
heartbeats and runs one tick now.

## Steps

1. **Read `SLATE-PLAN.md`** (repo root).
2. **Arm the heartbeats.** `CronList` (ToolSearch `select:CronCreate,CronList,CronDelete` if not
   loaded). Create whichever of the two jobs is missing — but skip a phase's job if its queue is
   already drained (no ⬜/🔄 rows):

   **Job A — Phase 1 slates** · cron `12,27,42,57 * * * *` · recurring · prompt exactly:
   > SLATE LOOP TICK — autonomous queue processor (Bill is away; never ask questions). Work
   > INLINE — no subagents, no Workflow. Docs-only, straight to main; stage ONLY files you
   > create/edit (other sessions keep dirty files in the shared tree). Procedure: read
   > /home/bill/projects/Wowzers/SLATE-PLAN.md and follow §3 THE LOOP exactly: (a) a 🔄 queue
   > row claimed <2h ago → reply "⏳ in flight: <target>" and STOP; (b) a 🔄 row ≥2h stale →
   > salvage its partial work (git status/log) and finish that row's pass; (c) else claim the
   > first ⬜ row and run §1 THE PASS end-to-end (fresh WebSearches included) until the slate is
   > committed 🟡 AT VERDICT with queue + BUILD-LEDGER + Coordination Log flipped; (d) no ⬜/🔄
   > rows left → delete this cron job and report the queue drained. One target per tick. If the
   > usage limit hits mid-pass, just stop — the next tick resumes via (b).

   **Job B — Phase 2 decks** · cron `4,19,34,49 * * * *` · recurring · prompt exactly:
   > DECK LOOP TICK — autonomous Phase-2 processor (Bill is away; never ask questions). Work
   > INLINE — no subagents, no Workflow. DESIGN ONLY — plan-doc sections + CARD-CATALOG rows,
   > straight to main; NEVER code, no .gd files, no sims. Stage ONLY files you create/edit.
   > Procedure: read /home/bill/projects/Wowzers/SLATE-PLAN.md §5–§6. GATE: if any §0 Phase-1 row
   > is ⬜ or 🔄 → reply "⏳ slates not drained" and STOP. Then walk the §5 deck queue by §3's
   > rules: (a) a 🔄 row claimed <2h → "⏳ deck in flight: <target>", stop; (b) 🔄 ≥2h stale →
   > salvage + finish it; (c) else claim the first claimable ⬜ row and run §6 THE DECK PASS
   > end-to-end — invoke the deck-creator skill, author the FULL deck around the top-3-ranked
   > slate branches (Bill's ✅ picks override), run every coherence gate + the distinctness-ledger
   > check + 3 skeptics, land it 🟡 AT VERDICT with CARD-CATALOG rows + queue + ledger + log
   > flipped; (d) §5 drained → delete this cron job and report. One target per tick. If the usage
   > limit hits mid-pass, just stop — the next tick resumes via (b).

   Tell Bill the crons are session-only and auto-expire after 7 days — if the session ends,
   re-invoke `/slate-loop` in the new session.
3. **Run one tick immediately** (Phase 1's if its queue has ⬜/🔄 rows, else Phase 2's) — don't
   wait 15 minutes.
