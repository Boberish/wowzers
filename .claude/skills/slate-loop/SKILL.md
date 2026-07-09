---
name: slate-loop
description: Start or restart THE SLATE MACHINE — the 15-minute loop that walks SLATE-PLAN.md's queue of all-class branch-slate passes, one class/spec at a time. Invoke in a fresh session to resume the loop after a session died (token exhaustion, restart, crash). State lives in SLATE-PLAN.md §0; the cron is only the heartbeat.
---

# SLATE LOOP — start/restart the slate machine

The queue, the pass, the laws, and the loop protocol all live in **`SLATE-PLAN.md`** — read it
first, top to bottom. This skill only (re)arms the heartbeat and runs one tick now.

## Steps

1. **Read `SLATE-PLAN.md`** (repo root). §0 = the queue (single source of truth), §1 = the pass,
   §2 = the laws, §3 = the loop protocol.
2. **Arm the heartbeat.** `CronList` (ToolSearch `select:CronCreate,CronList,CronDelete` if not
   loaded) — if no slate-loop job exists, create one:
   - cron: `12,27,42,57 * * * *` (every 15 min, off-minutes)
   - recurring: true
   - prompt — exactly this:
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
   - Tell Bill the cron is session-only and auto-expires after 7 days — if the session ends,
     re-invoke `/slate-loop` in the new session.
3. **Run one tick immediately** (same procedure as the prompt above) — don't wait 15 minutes.
