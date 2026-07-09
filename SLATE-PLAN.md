# SLATE-PLAN — THE SLATE MACHINE (all-class branch slates, one at a time)

> **What this is (Bill, 2026-07-10).** The Twinfang·Tempo branch-slate pass (`TEMPO-PLAN.md` §14,
> commit `29a60fa`) worked: research-grounded sub-spec pitches, skeptic-audited, landed 🟡 AT
> VERDICT. This doc GENERALIZES that pass to every class/spec and runs it as a QUEUE — one target
> at a time, a 15-minute loop tick claiming the next target when the last one lands. The generic
> pass is §1, the laws are §2, the loop protocol is §3, per-target notes are §4.
> **This is idea generation, not deck authoring** — deck builds (deck-creator skill, CARD-CATALOG
> rows) happen per target AFTER Bill picks from its slate, as separate claims outside this loop.

## 0. THE QUEUE (the checklist — the loop's single source of truth)

Status: ⬜ queued · 🔄 in flight (claim stamp) · 🟡 slate AT VERDICT · ✅ Bill picked (deck pass
unlocked) · ⏭ skipped by Bill. **Flip status in the same commit as the event.** Rows may be
reordered by Bill at any time; the loop always takes the FIRST ⬜ from the top.

| # | Target | Kind | Slate lands in | Status | Claimed | Note |
|---|---|---|---|---|---|---|
| 0 | Twinfang · **Tempo** | branch slate | `TEMPO-PLAN.md` §14 | 🟡 | — | THE WORKED REFERENCE (6 pitches, 3 skeptics, 0 kills). Bill picks 2–3 → deck pass. |
| 1 | Tank · **Warden** | branch slate | `TANK-PLAN.md` new § | ⬜ | — | Block-wall kit locked, deck unstarted — slate feeds the owed deck pass. No dodge on this kit; dodge-law checks become BLOCK-law checks. |
| 2 | Tank · **Duelist** | challenger slate | `TANK-PLAN.md` new § | ⬜ | — | Deck v1 (Headsman/Ironside/Ghost + Dancer) is AT BILL'S BOARD → it is **PITCH #0**; challengers must beat it. Flag clearly so it enriches, not muddies, the open verdict. |
| 3 | **Bloomweaver** (whole class) | class slate | NEW `BLOOM-PLAN.md` | ⬜ | — | Only class with NO v2 design — pitch CORE MINIGAME candidates (3–4) + spec identities, not branches. The biggest pass in the queue. |
| 4 | Alchemist · **Cask** | branch slate | `ALCHEMIST-PLAN.md` new § | ⬜ | — | Verb slices 1–2 built, cards owed (§7.7) — slate feeds the owed deck. |
| 5 | Well · **Brim** | branch slate | `MENDER-PLAN.md` new § | ⬜ | — | Deck built but branch-thin. Healer grammar: grade-the-landing (TARGET). |
| 6 | Well · **Draw** | branch slate | `MENDER-PLAN.md` new § | ⬜ | — | Sibling distinctness vs Brim is the hard check (SPEED/CURRENT vs TARGET). |
| 7 | Alchemist · **Brew** | challenger slate | `ALCHEMIST-PLAN.md` new § | ⬜ | — | Live deck + the §8 review pass (11 proposals 🟡) = a RICH incumbent — fold both in as PITCH #0 material; don't duplicate the review pass. |
| 8 | Twinfang · **Fermata** | challenger slate | `TEMPO-PLAN.md` new § | ⬜ | — | Deck v5 AT VERDICT = PITCH #0 (Cold Cut/Brink/Razor). Ramp/Snap verb locked — branches bend around it, never replace it. |

## 1. THE PASS (per target — generalized from the Tempo §14 run)

Every step INLINE — **no subagents, no Workflow tool** (Fable billing; memory
`no-workflow-tool-on-fable`). Docs-only, straight to `main`. Three commits per pass (checkpoints
so a token-death loses little):

0. **Preflight.** `git status` — note which files OTHER sessions have dirty; you will stage ONLY
   files you create/edit this pass, never theirs. Read this doc fully, then the target's plan doc
   + its verdict history (⚖ blocks + MASTER-PLAN §CLASS FRAMEWORK v2 rules 1–7) + `DECK-LAYOUT.md`
   (slots · axes · branches · ABILITY LAW) + the `deck-creator` skill (laws + anti-patterns) +
   the target's CARD-CATALOG rows.
1. **CLAIM (commit 1).** Flip the queue row ⬜→🔄 with a `date '+%m-%d %H:%M'` stamp + add the
   Coordination Log claim (if MASTER-PLAN is dirty from another session, put the claim line in the
   working tree anyway and note it rides their commit — commit only this doc).
2. **READ THE GROUND.** `research/README.md` + all knowledge-base files' STEAL CANDIDATES sections,
   re-mined through THIS class's lens (the existing per-game subsections are Twinfang-flavored —
   translate, don't copy).
3. **FRESH SWEEP (commit 2).** 3–6 WebSearches on the target's angle (§4 has starting angles) —
   scope→search→fetch→synthesize, no verify stage (memory `deep-research-skip-verify`). Write
   `research/<target>-sweep.md` on the README template (ends with STEAL CANDIDATES mapped to our
   grammar) + add its row to the README index table.
4. **SYNTHESIS — 4 lenses, inline, sequential:** ① branch/sub-spec shapes · ② greed surfaces ·
   ③ the class's core-mechanic grammar (timing for rhythm kits, triage for healers, reads for
   tanks…) · ④ spectacle/party (warband space is unclaimed — probe ≥1 cross-seat idea).
5. **PITCHES.** 4–6, each in the §14 anatomy: *name + tagline* · **the twist** · **what you're
   for** · **dials** (which core-mechanic dials it leans/BENDS) · **example cards (illustrative,
   3–4)** · **capstone keystone** (spectacle-grade) · **greed/comfort** · **sources** · **pillar
   check**. Where an incumbent design exists (queue note), it is **PITCH #0** restated honestly in
   the same anatomy and judged at the same bar.
6. **SKEPTICS ×3, inline, sequential** — three separate adversarial framings (e.g. "this is a
   repack of X" · "the engine/AI-policy cost is a lie" · "the fantasy dies in a 60s fight").
   Kill or fix every pitch; fold fixes; RANK by pick-tension; record kills/fix-count honestly
   (incl. an "honesty note" on any pitch kept for fantasy over strength — Soloist precedent).
7. **WRITE THE SLATE (commit 3)** — new § in the target's plan doc, 🟡 AT VERDICT, in the §14
   shape: *the harvest* (≤1 page, numbered) → *slate rules* (stated once) → *the pitches* →
   *slate-level checks* (spread · skeptic ranking · composition notes · engine debts ·
   **skipped-on-purpose**) → *next* (Bill picks N → deck-creator pass). Same commit: queue row
   🔄→🟡 · BUILD-LEDGER §2 row (LEDGER LAW) · Coordination Log entry ticked.
8. **STOP.** No deck authoring, no code, no CARD-CATALOG rows, no second target. Reply with a
   short human summary (what landed, the skeptic ranking, where to read it).

## 2. SLATE LAWS (every slate, every pitch)

1. **Base ideas only** — example cards are ILLUSTRATIONS; no CARD-CATALOG rows until the deck pass.
2. **Every branch changes the timing shape or what a press does — never just numbers** (Hades
   aspect standard). A stat-lean pitch is dead on arrival.
3. **Vary the meter's LAW, not the resource count** — bank vs decay vs reset an existing meter
   beats inventing a new one.
4. **Different clocks** — no two branches in one slate peak on the same cadence (the FFXIV
   2-minute trap).
5. **The entry creed carries the branch from run start; the module deepens it** — a branch that
   only exists after Floor 1 is dead cards for half a run.
6. **Every branch contributes a knob to the EASE dial** — never flat comfort cards.
7. **Touch budget per the ABILITY LAW** (`DECK-LAYOUT.md` §5: chassis free, +2 via draft/module
   doors, ceiling 7 / Well 8) — state the count per pitch.
8. **Greed is chosen per use with a bite you authored** — a bonus keyed to an uninfluenced roll is
   a lottery ticket.
9. **Pillar check per pitch:** single-target law · dodge stays defensive (or the kit's stated
   defensive core for no-dodge kits) · interrupt-by-ability angle if the class carries ·
   warband law · **AI-pilotable** (a seeded policy must express it — rule 3 of the class rules).
10. **Name the nearest neighbor** (sibling spec first, then other classes) and the distinction —
    "not the Alchemist, not Fermata's Mark" precedent.
11. **Skipped-on-purpose is mandatory** — the ideas you rejected and why, so nobody re-litigates.
12. **Borrow the grammar, innovate the sentence** — every steal must do something only our
    timing-combat / deterministic-AI engine could.

## 3. THE LOOP (protocol — how the queue gets walked)

- **The tick.** A session cron fires every 15 min (`12,27,42,57 * * * *` — off-minutes on
  purpose). Each tick: read this doc → **(a)** a 🔄 row with a claim **< 2 h old** → reply one
  line ("⏳ in flight: <target>") and stop; **(b)** a 🔄 row **≥ 2 h stale** → that pass died
  (token exhaustion, most likely) — `git status`/`git log` to find its partial work, salvage,
  finish that row; **(c)** else claim the first ⬜ and run THE PASS end-to-end; **(d)** no ⬜/🔄
  left → delete the cron job and report the queue drained. **One target per tick, never two.**
- **"Done" = the slate lands 🟡 AT VERDICT.** The loop does NOT wait for Bill's verdicts — all
  slates queue at his board; verdicts + deck passes are separate work outside this loop.
- **Token exhaustion is expected.** A tick that hits the usage limit simply dies; the next tick
  retries in 15 min and keeps retrying until the window resets. The queue + commits carry ALL
  state — nothing lives only in a session.
- **⚠ The cron is SESSION-ONLY** (in-memory, max 7 days). If the session ends, the loop stops —
  **restart in any new session by invoking the `slate-loop` skill** (`/slate-loop`), which
  re-creates the cron and runs one tick immediately. This doc is the state; the cron is just the
  heartbeat.
- **Concurrent-session discipline:** stage only your own files (other sessions keep dirty files
  in the shared tree); docs straight to main, commit as you finish, never leave the tree dirty
  at tick end.

## 4. PER-TARGET STARTING ANGLES (hints, not fences — each pass scopes its own sweep)

- **Warden:** block/posture economies without dodge — Lies of P perfect-guard, MonHun lance/
  gunlance, For Honor stance-blocking, Souls greatshield/poise, StS Barricade/block archetypes.
- **Duelist:** parry-first melee — Sekiro deflect economy, Nine Sols, E33 parry-strings (already
  in `research/expedition-33.md`), fighting-game defense meters. Incumbent = TANK-PLAN deck v1.
- **Bloomweaver:** grow-and-harvest as combat — PvZ lanes, Cult of the Lamb farming loops, druid/
  summoner spec fantasies (WoW file), garden-state engines (StS orbs/plants archetypes).
- **Cask:** pressure/ferment/pour grammars — brewing sims, Potion Craft, PoE flask builds,
  charge-and-vent kits. Read `ALCHEMIST-PLAN.md` §7.7 first for the locked verb.
- **Brim / Draw:** healer minigames that grade the HEAL not the target's bar — WoW healer spec
  identities (file exists), FF14 oGCD weaving, Overwatch support uptime — mapped onto
  grade-the-landing (Brim) vs grade-the-release/CURRENT (Draw). Sibling distinctness is the bar.
- **Brew:** reaction/combination depth — Magicka element combos, Noita wand-craft, StS Catalyst
  poison lines. Fold ALCHEMIST-PLAN §8's 11 live proposals in as incumbent material.
- **Fermata:** hold/release rhythm — Thumper, charge-shot grammars, held-note mechanics in rhythm
  games. The Ramp & the Snap is LOCKED — branches bend it, never replace it.
