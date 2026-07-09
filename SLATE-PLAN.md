# SLATE-PLAN — THE SLATE MACHINE (all-class branch slates, one at a time)

> **What this is (Bill, 2026-07-10).** The Twinfang·Tempo branch-slate pass (`TEMPO-PLAN.md` §14,
> commit `29a60fa`) worked: research-grounded sub-spec pitches, skeptic-audited, landed 🟡 AT
> VERDICT. This doc GENERALIZES that pass to every class/spec and runs it as a QUEUE — one target
> at a time, a 15-minute loop tick claiming the next target when the last one lands. The generic
> pass is §1, the laws are §2, the loop protocol is §3, per-target notes are §4.
> **The machine has TWO PHASES (Phase 2 added 2026-07-10, Bill):** Phase 1 (§0–§4) = the branch
> slates, idea generation only. **Phase 2 (§5–§6) = THE DECK MACHINE** — once EVERY slate has
> landed, a second loop authors the FULL DECK (design only, never code) for each target around
> its **top-3-ranked branches** (Bill's ✅ picks override the ranking wherever he has verdicted).
>
> **⚠ CORRECTED 2026-07-10 00:35 (Bill).** A **branch is a build THEME inside the existing spec**
> (the tank's Headsman/Ironside/Ghost precedent): a general category — *bleeds, fast attacks,
> slow big finishers* — that cards/creeds/modules FEED so drafts synergize. **The base minigame
> stays untouched; the spec's identity stays.** Branch pitches ADDRESS existing dials, never bend
> them, add no buttons, and never hang the identity on a new gauge. The original Tempo §14 pass
> over-shot into minigame-rewire pitches — those are re-homed as SPEC/ASPECT IDEAS (`TEMPO-PLAN.md`
> §15 parking 🔮; Bill: keep as future spec ideas) and the **rewire-grade anatomy now applies to
> `class slate` rows ONLY** (Bloomweaver). Tempo §14 is REDONE as the corrected worked reference.

## 0. THE QUEUE (the checklist — the loop's single source of truth)

Status: ⬜ queued · 🔄 in flight (claim stamp) · 🟡 slate AT VERDICT · ✅ Bill picked (deck pass
unlocked) · ⏭ skipped by Bill. **Flip status in the same commit as the event.** Rows may be
reordered by Bill at any time; the loop always takes the FIRST ⬜ from the top.

| # | Target | Kind | Slate lands in | Status | Claimed | Note |
|---|---|---|---|---|---|---|
| 0 | Twinfang · **Tempo** | branch slate | `TEMPO-PLAN.md` §14 | 🟡 | — | THE WORKED REFERENCE (corrected 2026-07-10): 6 THEMES — Wound · Finish · Swift · Edge · Punish · Band — + existing-pool filing table. Bill picks 2–3 → deck pass. Old rewire pitches → §15 parking 🔮. |
| 1 | Tank · **Warden** | branch slate | `TANK-PLAN.md` §6 | 🟡 | — | LANDED 07-10: 5 themes (Payload · Slam · Rampart · Bannerman · Thornback), 1 kill, ~11 fixes, filing table for the 🔮 trio + carries. Bill picks 2–3. |
| 2 | Tank · **Duelist** | challenger slate | `TANK-PLAN.md` §7 | 🟡 | — | LANDED 07-10: 3 challengers (Matador · Stormweave · Scarlet Trade) join the live §3 board; v1 ladders = PITCH #0a/b/c; Bill picks 2–3 total. 1 kill, ~8 fixes. |
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
5. **PITCHES.** 4–6. **Anatomy depends on the row's Kind (corrected 2026-07-10):**
   - **branch / challenger slate → THEME anatomy** (Tempo §14 = the worked reference): *name +
     fantasy one-liner* · **what its cards DO** (the synergy spine in plain words) · **dials
     ADDRESSED** (existing dials only — never bent, no new buttons, no identity-gauge) ·
     **existing cards it absorbs** (name them — the filing is the point) · **example new cards,
     3–4 illustrative, spread across creed/module/boons/keystone** · **greed/comfort + its EASE
     knob** · **nearest neighbor + the distinction**. Slate-level: an **existing-pool filing
     table** (every built card → which theme(s) it feeds, or "generic") proving the themes
     organize the real deck. Where an incumbent exists (queue note), it is **PITCH #0** restated
     in the same anatomy.
   - **class slate → SPEC anatomy** (Bloomweaver only; the old §14-style rewire grade): *name +
     tagline* · **the twist** · **what you're for** · **dials** (may lean/BEND — it's a core-
     minigame pitch) · example cards · spectacle keystone · greed/comfort · sources · pillar check.
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
2. **A branch is a THEME, not a rewire (corrected 2026-07-10, Bill).** Base minigame untouched;
   the spec's identity stays. Its cards ADDRESS dials, never bend them. A theme must still be a
   real build direction with a payoff arc (creed→module→boons→keystone), not a stat pile — but
   "changes the timing shape / what a press does" is now the bar for **class slates only**.
3. **Vary the meter's LAW, not the resource count** *(class slates only)* — bank vs decay vs
   reset an existing meter beats inventing a new one. Branch themes don't get new meters at all
   (a module-tier tracker gauge is the ceiling, and it never defines the branch).
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
  slates queue at his board. When Phase 1 drains, **Phase 2 (§5) takes over on its own cron** and
  authors the decks from the top-3 branches per slate (Bill's picks override where present).
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

---

## 5. PHASE 2 — THE DECK MACHINE (full decks from the top-3 branches)

**The gate.** Phase 2 may not claim ANYTHING while any §0 row is ⬜ or 🔄. Its own cron
(`4,19,34,49 * * * *`) ticks every 15 min; before the gate opens every tick is a one-line
"⏳ slates not drained" no-op. After the gate opens it walks THIS queue exactly like §3 walks §0
(claim-fresh / stale-salvage / first-⬜ / one-target-per-tick / drain→delete-cron).

**Choosing the winners.** For each target: **Bill's ✅ picks win** wherever he has verdicted the
slate; otherwise take the **top 3 of the slate's recorded skeptic pick-tension ranking**. Name
the chosen 3 (and the ranking source line) at the top of the deck §. Bill re-verdicts the whole
deck anyway — a "wrong" provisional pick costs one re-pass, never code.

**Deck queue** (⬜ queued · 🔄 in flight · 🟡 deck AT VERDICT · ✅ approved · ⏭ skipped; a row is
claimable only when its §0 slate row is 🟡/✅ — a ⏭ slate skips its deck too):

| # | Target | Deck lands in | Status | Claimed | Note |
|---|---|---|---|---|---|
| D0 | Twinfang · **Tempo** | `TEMPO-PLAN.md` | ⬜ | — | Waits on the §14 REDO (row 0). Fold A1–A9 ledger verdicts + Through-Line/On-the-Beat drift in. |
| D1 | Tank · **Warden** | `TANK-PLAN.md` | ⬜ | — | Receives the 🔮 re-homed guard cards (ledger). No-dodge kit: EASE knobs live on BLOCK reads. |
| D2 | Tank · **Duelist** | `TANK-PLAN.md` | ⬜ | — | Deck v1 already AT BILL'S BOARD — this pass is a **v2 REVISION** around the winning themes, not a parallel deck; carry v1 verdicts that exist by then. |
| D3 | **Bloomweaver** | `BLOOM-PLAN.md` | ⬜ | — | Double-size: lock the top CORE-MINIGAME pitch first, then author that spec's deck. |
| D4 | Alchemist · **Cask** | `ALCHEMIST-PLAN.md` | ⬜ | — | Pays the owed §7.7 slices 3–5 card design. |
| D5 | Well · **Brim** | `MENDER-PLAN.md` | ⬜ | — | Deck exists in code — this is the RESHAPE onto branches (DECK-LAYOUT Phase 2), absorb-don't-duplicate. |
| D6 | Well · **Draw** | `MENDER-PLAN.md` | ⬜ | — | Same; sibling-distinctness vs D5 is a hard gate. |
| D7 | Alchemist · **Brew** | `ALCHEMIST-PLAN.md` | ⬜ | — | Reconcile with the §8 review-pass proposals — one merged deck, not two competing revisions. |
| D8 | Twinfang · **Fermata** | `TEMPO-PLAN.md` | ⬜ | — | v5 deck at verdict = the incumbent; v6 revision around winning themes. |

**Cross-deck DISTINCTNESS LEDGER** — each deck pass APPENDS its row here before writing cards,
and checks its plans against every earlier row (the cheap cross-class overlap gate — no re-reading
whole decks):

| Target | The 3 themes | Keystone spectacle shapes | Greed bites (what the player risks) |
|---|---|---|---|
| *(first deck pass writes the first row)* | | | |

## 6. THE DECK PASS (the deep prompt — one full deck, design only, NEVER code)

Run every step INLINE, in order, no skipping — the gates are where the quality comes from.
Three checkpoint commits (claim / mid-draft / final) so a token-death loses little.

0. **Preflight + full read.** `git status` (stage only your own files). Then read, in this
   order: **the `deck-creator` skill (INVOKE it — it is the playbook: slots, pick-tension law,
   fun hierarchy, anti-pattern list, coherence rules)** · `DECK-LAYOUT.md` whole (slots · 3 axes ·
   branches · card-type lenses · ABILITY LAW · signature CD · design rules) · MASTER-PLAN §CLASS
   FRAMEWORK v2 rules 1–7 · the target's plan doc END TO END (kit, verdict ⚖ blocks, its Phase-1
   slate §, open questions) · its CARD-CATALOG rows **including the Cut Ledger (never resurrect a
   cut without cause)** · `research/<target>-sweep.md` + the knowledge-base STEAL sections ·
   **the §5 distinctness ledger** (every earlier row) · GAME-LOOPS pointers for the class.
1. **CLAIM (commit 1).** Flip the §5 row ⬜→🔄 + stamp; Coordination Log claim line.
2. **WINNERS + DIALS FIRST.** State the 3 themes (per §5 rule) and then — before ANY card —
   write the **DIALS LIST**: every dial of the core minigame a card may address (deck-creator §4).
   The boon lanes ARE these dials. Then write the **budget line**: touch-target count vs the
   ABILITY LAW ceiling, module count, boon count target (10–16), keystone pool (2–3).
3. **APPEND THE DISTINCTNESS ROW (§5 table)** — themes, planned keystone spectacle shapes,
   planned greed bites — and CHECK it against every earlier row + built decks in CARD-CATALOG:
   a keystone spectacle shape, greed bite, or creed temperament that repeats another class's is
   REDESIGNED NOW, before cards get written around it. (Convergent bread is fine; convergent
   identity is not.)
4. **AUTHOR THE DECK (commit 2 mid-way)** — every DECK-LAYOUT slot, every card in CARD-CATALOG
   row format (id · type · rarity · one-line WHAT · the dial it addresses · the theme(s) it
   feeds):
   - **Creeds 3–5, pick 1:** one forgiving/crossover · one greed pole · one rhythm-changer ·
     one WILD (Tutti-class, rewrites how the core mechanic is scored — the one sanctioned
     rewire). **Each of the 3 themes must be ENTERABLE from run start via at least one creed**
     (§2 law 5 — no dead-until-Floor-1 themes).
   - **Modules 2–3, Floor-1 pick:** add-ons that EARN their pixels; no transformer requirement;
     at most one gauge each, and a gauge never defines a theme's identity.
   - **Boons 10–16 in dial-lanes:** each lane ≥1 greed, ≤1 insurance (dressed as a play, never a
     pardon); every boon names its theme(s) or "bread" (bread ≤ 3); rarity = build-definingness
     (Haiku/Sonnet/Opus), the H/S/O ladder designed per card, not scaled.
   - **Rig 2–4 WHENs:** chooseable/earnable moments only, single circuit, no stacking (RIG LAW);
     the WHENs should be moments the deck's own cards create.
   - **Keystones 2–3 (elite-only):** spectacle-grade — each must visibly change how the
     bar/minigame LOOKS in play, and light up 2–3 pool boons differently; per-theme where possible.
   - **Support 1** (party-facing, keyed to the spec's core state) · **signature ~1-min CD** shape
     (amplify skill, never button=damage) · **carries** verified VERBATIM against the core
     mechanic · **EASE dial knob list** (one knob per theme minimum) · spells reconcile if the
     class has a book.
   - **Where a deck already EXISTS** (queue note): this is a REVISION — file every existing card
     into a theme / bread / CUT-proposed table first; absorb, don't duplicate; carry Bill's prior
     verdicts forward untouched unless a theme demands a change (then flag it loudly).
5. **COHERENCE GATES (run all five, write the results into the doc — evidence, not claims):**
   - **Archetype walkthroughs:** for each theme, the "dream draft" (creed → module → 4–6 boons →
     keystone) written out with WHY each pick compounds the last — plus ONE cross-theme hybrid
     that still works. A theme whose walkthrough reads as "number gets bigger" gets redesigned.
   - **Offer-trio test:** deal 5 random 3-card offers per rarity tier from the finished pool; any
     auto-pick → fix the trio; any auto-skip → cut or spice. Show 2–3 of the actual trios.
   - **Overlap audit (in-deck):** no two cards address the same dial in the same direction at the
     same slot — merge or differentiate. Each theme keeps ≥3 exclusive cards; shared cards listed.
   - **Anti-pattern sweep:** every card checked against deck-creator §3 (passive wind-ups ·
     passives wearing UI · stat keystones · one-time bonuses · oversized knobs · extra buttons ·
     un-graspable rules · insurance stacking · luck wearing greed's clothes). List survivors of
     each near-miss.
   - **AI-pilotability note per theme:** one sentence on how a seeded policy expresses it at 3
     skill tiers (class rule 3). If the policy sentence needs a paragraph, the theme is too clever.
6. **SKEPTICS ×3, inline, sequential** — fresh framings for decks: ① the draft-table skeptic
   (auto-picks, dead cards, trap trios) · ② the repack skeptic (is any theme another class's deck
   in a costume? check the distinctness ledger again) · ③ the fight-clock skeptic (does the theme
   pay off inside a 60s zone fight AND a 7-node run arc?). Kill or fix; fold; record honestly.
7. **WRITE + TRACK (commit 3).** The deck § lands 🟡 AT VERDICT in the plan doc: *winners line* →
   *dials list* → *the deck by slot* → *coherence-gate evidence* → *skeptic record* → *open
   tension points for Bill* (the 3–6 calls only he can make, stated as questions with your lean).
   Same commit: **CARD-CATALOG rows for every card at 🟡** (CARD-TRACKING LAW — the catalog owns
   status; keep ids code-shaped) · §5 queue row 🔄→🟡 · distinctness-ledger row finalized ·
   BUILD-LEDGER §C row flip (LEDGER LAW) · Coordination Log tick.
8. **STOP.** Design only — no `.gd` files, no code edits, no sims, no second target. Reply with
   a short human summary: the 3 themes, the headline cards, the open tension points, where to read.
