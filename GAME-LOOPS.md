# GAME-LOOPS — the loop map + the 2026-07-09 loop audit

**What this is.** The **read-optimized view of the game**: the one place that states Project Rift
as its player-facing LOOPS — each loop's shape, cadence, build status, and pointers to the docs
that own its pieces. The plan docs are organized by *system / decision-session* (write-optimized:
each is a decision-of-record with dates and verdicts); nothing was organized by *what the player
does, inside what, inside what* — until this doc. **It is an INDEX, like `BUILD-LEDGER.md`** —
design detail stays in the owning docs; if this doc and an owning doc disagree, the owning doc
wins and this one gets fixed.

**Born from Bill's 2026-07-09 audit ask** (*"take our game, including all the plans, and get an
idea what we have — is ~23 .md docs the best way to store our game loop? it feels fractured"*).
The audit's verdict is §4 in one line: **the medium is right, the corpus is ~90 % coherent; the
felt fracture is a missing loop-level view (now this doc) plus a short list of drift spots (§3).**

**Upkeep rule:** when a loop's *shape* changes (a new surface, a moved owner, a new stage in the
run-flow), update its stanza + its §2 row **in the same commit as the decision** (the LEDGER-LAW
idiom). Pointer lines only — never write design here.

---

## §1 · THE LOOP STACK

The game in one line (current era): *you take one seat of a 4-seat warband into movement-free
trinity boss fights (answer the telegraph on time), inside roguelike runs (draft a deck as you
descend), behind doors in a persistent overworld you conquer once (quests grow the COLLECTION,
runs build the DECK), forever (Depth / Versions / standing — skill is the character level).*

Seven loops, innermost first. Innermost = why it feels good; outermost = why you come back.

### L0 · THE BEAT (~1–3 s) — answer the telegraph
One boss, one telegraph stream; you answer with your class's move (parry / dodge / release /
pour / …) and get graded (BULLSEYE/PERFECT/GOOD…); grades feed your class resource. ONE spacebar
dodge (active roster). Interrupts ride existing abilities in a tight window (the interrupt tax).
- **Owners:** `WORLD-PLAN.md` §COMBAT PILLARS (the laws) · each class plan (the spec's grade
  bands + minigame) · `DODGE-PLAN.md` (the one dodge) · MASTER-PLAN §GRAPHICS (StrikeJudge UI).
- **Status:** ✅ built for the active roster (Twinfang · Alchemist · Well); tank minigame locked
  at deck-verdict; interrupt-by-ability **unbuilt** (lands with the reworks — ⚠ post-PURGE
  interim: NO class carries a kick). After THE PURGE (2026-07-10) the only frozen kits left are
  Bulwark (dies with the Duelist) + Bloomweaver — they keep the old two-verb dodge.

### L1 · THE FIGHT (~2–12 min) — run the rotation, hit the moments
The class minigame loop (build/spend) + the boss's authored beats (dodge ration ~3–8 non-tank) +
kick windows + the **signature CD** lined up on a boss window + PACK heat-carry (combo state
persists across sequential pack members, walk-in valleys) + per-member enrage. Aggro = FLOW on
the tank's minigame, universal (design). Fight length ×2.5 BAKED; structure beats, never sponges.
- **Owners:** class plans (each rotation) · `WORLD-PLAN.md` §FIGHT LENGTH & PACING (packs ·
  bands · the 3 laws) + §COMBAT PILLARS (dodge ration, interrupt) · `DECK-LAYOUT.md` §5 (THE
  ABILITY LAW + the signature CD) · MASTER-PLAN §BOSSES + `SEAL-PILLAR-PLAN.md` (the claimable
  Seal dodge-ration retune) · `TANK-PLAN.md` §1c (aggro=flow).
- **Status:** rotations built (active roster); packs + length built; **signature CD built for NO
  class yet** (mandated for all — see §3 gap F); interrupt + aggro-flow unbuilt; the boss roster
  end-state is a *deliberate* unknown (BOSS-REDO era — recast, don't redesign yet).

### L2 · THE NODE (~30 s–5 min) — pick a door, resolve a screen
One map step: route choice → the node's payload — a fight · an INFERENCE-CHECK event (build-read
dice, ⚡ nudge, wagers, branches) · cache / cooling / market / ticket / Seal (~~personal GATE
exam~~ — cut 2026-07-10 THE PURGE) — → post-fight ceremonies (⏣ mint → drop roll *if the kill is
event-worthy* → 1-of-3 boon draft).
- **Owners:** MASTER-PLAN §MAPS (the as-built truth: DAG gen · tickets · checks · gates · shard
  gates) · `WORLD-PLAN.md` §THE WORLD MODEL (zone nodes) · `PROGRESSION-PLAN.md` §Drops
  (drops-are-EVENTS) · `TEETH-PLAN.md` (CONTEST node · curse events — unbuilt).
- **Status:** ✅ built deep (offline + online, protocol v13 since THE PURGE). Gaps: the post-fight ceremony
  *order* lives only in code; "biting blessings" is a name with no design (§3 drift 3).

### L3 · THE RUN (30 min–3 h) — build a deck, spend it on a mountain
Aspect + Creed at start → fight 1 → wire the RIG (1 WHEN→1 THEN) → a boon draft per win → Module
at Floor 1 → keystone at an ELITE (1-of-2) → free re-wire end of Floor 2 → OATHS sworn at bosses
→ Market / Tokens / curios / wounds attrition → THE STAKES (raid: floor checkpoints + finite wipe
budget + attempt tokens · dungeon: 1 life) → the finale pays META, not a drop. Two surfaces,
deliberately different density: **DUNGEON** (fast, light stack, mobile-first, the M+ Depth push
home, per-dungeon system subsets) / **RAID** (the full stack, 24–36 fights, the flagship).
- **Owners:** `DECK-LAYOUT.md` §1 "when each is granted" (**the cleanest single statement of the
  run-flow — start here**) · `PROGRESSION-PLAN.md` §UNLOCK 2 (two surfaces + the density law) ·
  `WORLD-PLAN.md` §INSTANCES + §THE STAKES MODEL · `ASCENSION-STEAL-PLAN.md` (the draft-economy
  engine of record — ⚠ partly stale, §3 drift 1/5) · `TEETH-PLAN.md` (rerolls-out 🔒 · CONTEST ·
  curse cards) · MASTER-PLAN §SYSTEMS (the as-built record).
- **Status:** the raid surface is built end-to-end (on pre-rework classes); **the dungeon door is
  unbuilt and has no content plan** (§3 gap A); stakes model locked 07-09, unbuilt; keystones a
  partial layer. **This is the most fractured loop — six doc homes** (see §2).

### L4 · THE WORLD (a session, ~30–70 min a zone) — conquer once, keep it forever
Atlas → a zone's frontier → node fights on the BARE KIT → tickets / deeds / escorts → ZONE
REMEMBERS choices → capstone → crest + waystation → doors unlock → the next zone, or through a
door into L3. Permanence/variance is exactly the world/instance line; zones mint nothing —
*"quests edit the COLLECTION, runs edit the DECK."*
- **Owner:** `WORLD-PLAN.md` — sole owner, the healthiest loop doc (model for the rest) ·
  `PROGRESSION-PLAN.md` §5 (the crest-gated campaign spine).
- **Status:** W1 built (THE GILDFIELDS, flagged preview); W2 = Forge content pass + TICKETS v2;
  the front door flips to the Atlas at W3.

### L5 · THE ACCOUNT (hours → forever) — the collection grows, the player grows
Event-XP (quests · oaths kept · first kills · conquest · clears — never kill-grind) → ONE meter →
Ledger-Tree nodes you choose (bread = levels only · deep/keystone = + an OATH KEPT) → crests
light branches → pools get richer, never stronger → endgame RANK = Depth (procedural, continuous)
+ Versions (authored, discrete) + standing/cosmetics. Oaths bank win-OR-lose; the first-kill
signature checkmark banks only on a WIN; rested multiplies earned XP (designed).
- **Owners:** `PROGRESSION-PLAN.md` (the owner: laws · the tree · four tracks · drops/oaths) ·
  `GEAR-CATALOG.md` (the page content) · MASTER-PLAN §MODES & ENDGAME (Depth/Versions) ·
  `TEETH-PLAN.md` §RESTED + §RETENTION.
- **Status:** design **locked 2026-07-08/09 — almost none of it built** (GEAR-1/2 + Draft 2.0
  substrate exist; tree/XP/crest-gates/stakes/rested all await W2/W3). The biggest
  designed-vs-built gap in the game; when the code phase opens, this loop is the backlog.

### L6 · THE WARBAND (cross-cutting) — four seats, always
Commander builds AI raiders from YOUR unlocks → seats fill (friends replace AI, byte-identical) →
lockstep co-op → the guest-world zone rule (play the least-progressed member's world) → world
events with open lobbies + offline parity (W4) → the parked MMO-feel levers (lending · bounties ·
ghost races · co-op standing).
- **Owners:** `WORLD-PLAN.md` (events · guest-world · presence) · MASTER-PLAN parking lot
  (MMO-feel levers — wants, none claimed) · `REFIT-PLAN.md` §4 (the shell architecture that
  hosts it) · `archive/RAID-PLAN.md` (netcode origin — frozen 2026-07-10).
- **Status:** the moat is built (lockstep, AI seats, online descent); the *feel* layer (presence,
  events, levers) is all W4+.

---

## §2 · THE FRAGMENTATION MAP

| Loop | Primary doc | Also lives in | Biggest hole |
|---|---|---|---|
| L0 beat | WORLD-PLAN §PILLARS | class plans · DODGE-PLAN | interrupt unbuilt |
| L1 fight | WORLD-PLAN §PACING | DECK-LAYOUT §5 · SEAL-PILLAR · TANK §1c · class plans | signature CD unbuilt anywhere |
| L2 node | MASTER §MAPS | WORLD-PLAN · PROGRESSION §Drops · TEETH | ceremony order = code-only |
| L3 run | DECK-LAYOUT §1 | PROGRESSION §UNLOCK-2 · WORLD §INSTANCES/§STAKES · ASCENSION-STEAL · TEETH · MASTER §SYSTEMS · **DESCENT-PLAN (raid) / DUNGEON-PLAN (dungeon), both 🟡 07-10** | ~~no dungeon plan~~ closed — both run surfaces specced, at verdict |
| L4 world | WORLD-PLAN | PROGRESSION §5 | — (healthy) |
| L5 account | PROGRESSION-PLAN | GEAR-CATALOG · MASTER §MODES · TEETH | designed, unbuilt |
| L6 warband | WORLD-PLAN | MASTER parking lot · REFIT §4 · RAID-PLAN | levers unclaimed |

Reading it: **L4 shows what right looks like** (one owner, others point at it). **L3 is the
fracture Bill feels** — six homes because five design sessions (draft2 · unlock · world · stakes ·
teeth) each touched the run without any doc owning "the run" itself. This doc's L3 stanza is now
that view; DECK-LAYOUT §1 is the closest in-doc statement.

---

## §3 · AUDIT FINDINGS (2026-07-09)

### Drift — decisions locked but not yet folded into their doc-of-record
*(all already tracked in TEETH §WHERE EACH LANDS — listed so nobody trusts a stale page)*
1. **Rerolls-out 🔒** (TEETH) is not in `ASCENSION-STEAL-PLAN.md` or MASTER §SYSTEMS-C — both
   still read "REROLL 1⏣ / LOCK" as current — ✅ **breadcrumbed 07-09/10** (ASCENSION-STEAL
   banner + MASTER §SYSTEMS-C); the real fold lands with the build claim.
2. **Loot need/greed B-half revival + the boss-kill reward stack** (TEETH 🔒) — ✅
   **breadcrumbed 07-10** into PROGRESSION §Drops; folds at the build claim.
3. **Curse cards → "biting blessings"** (MASTER §MAPS Phase 2/3) — still a name with no design.
4. `TEMPO-PLAN.md` §4's module language predates the 07-09 "modules are add-ons, not
   transformers" demotion — DECK-LAYOUT wins by its own rule; harmless, noted for the reshape.
5. ASCENSION-STEAL's *"Rift in one line"* describes the pre-world game (aspect → chain 5 bosses →
   draft; no creeds/world/two surfaces) — a stale summary at the top of an active doc-of-record.

### Stale blocks in otherwise-live docs — ✅ ALL FIXED 2026-07-09/10
6. MASTER §MAPS' shipped "NEXT (unclaimed)" list — ✅ stale-banner 07-09.
7. `RAID-PLAN.md` — ✅ frozen + moved to `archive/` 07-10.
8. MASTER §ONLINE "IN FLIGHT" header — ✅ fixed 07-10.
9. MASTER §CLASSES draft-parity bullet — ✅ struck 07-10 (plus §SYSTEMS-E GEAR-2→GEAR-3 and the
   dead §GRAPHICS 3D-HUD bullet, found via BUILD-LEDGER §0's drift list).

### Genuine gaps — questions no doc answers *(status updated 2026-07-10)*
- **A · THE DUNGEON has no plan** — ✅ **CLOSED 07-10:** consolidated as **WORLD-PLAN §THE
  DUNGEON** (shape · M+ identity · stakes · light stack · variety subsets · endless door);
  **structure spec landed same day: `DUNGEON-PLAN.md`** (🟡 8-verdict board — budget · map
  preset · door contract · subset table · UNDERGRANARY contract);
  content authoring (Dungeon 1's nodes + named boss) stays a W3 claim.
- **B · The first 15 minutes.** Still open — "Zone 1 rolls out every system" is the whole
  onboarding spec; the beat-by-beat first-session script is W2/W3 authoring work.
- **C · The post-fight ceremony order** — ✅ **CLOSED 07-10:** recorded in DECK-LAYOUT §1
  (writeback → oath → Reckoning → mint/drop → draft → continue; code truth `raid_hud._on_end`).
- **D · The roster queue** — ✅ **CLOSED 07-10:** MASTER §CLASSES now states it (tank next;
  the order after it is UNDECIDED and recorded as Bill's pick, which is the honest answer).
- **E · The comeback loop** — ✅ **stated 07-10** in PROGRESSION §Pacing (deliberately
  unclocked by Law #4; rested sweetens returns, never mints).
- **F · The signature CD** is mandated for every class (DECK-LAYOUT §1/§5), built for none, with
  per-class shapes an open feel-verdict — still flagged so it doesn't fall between the
  per-class reshape claims (ledger row exists, §C).

### What's healthy (found and worth keeping)
- **Zero live contradictions.** Every conflict found was a stale *echo* of a superseded state,
  and in each case the newer doc wins by an explicit, written rule (CARD-CATALOG wins cards ·
  DECK-LAYOUT wins anatomy · dated ⚠ SUPERSEDED banners elsewhere). The corpus self-corrects.
- The supersede idiom works under pressure — the aggro raid-only→universal revision (07-09) and
  the crafting cut→reverse→re-cut (07-08/09) were both handled in place, with breadcrumbs.
- The **BUILD-LEDGER / CARD-CATALOG / DECK-LAYOUT** triad (born 07-09) already closed the same
  fracture for execution tracking that this doc closes for design.
- WORLD-PLAN is the model plan doc: one owner, locked-decision headers, NOT-this lists, parked
  ideas recorded so they aren't re-derived.

---

## §4 · VERDICT — is a pile of .md files the right way to store the game?

**Yes — keep it. The problem was never the medium.** What .md-in-git buys, nothing else offers:
- **Same-commit atomicity** — decisions and their tracking flip together (the LEDGER and
  CARD-TRACKING laws literally depend on it; a wiki/Notion/DB breaks both).
- **Git history is the attic** — cut designs, frozen milestones, and deleted sims are all
  recoverable (HISTORY.md, the Cut Ledgers, and the fresh-slate deletions all rely on this).
- **Greppable and agent-native** — every session (human or AI) reads and writes the same store,
  with diffs and blame as provenance.

**The felt fracture is a READ-PATH problem, not a storage problem.** The docs are write-optimized
(one per system / decision session — the right shape for capturing verdicts); nothing was
read-optimized by loop. The proven fix is **thin INDEX docs over the decision docs** —
BUILD-LEDGER did it for "what's unbuilt," CARD-CATALOG for "what cards exist," this doc for
"what IS the game." Do **not** consolidate 23 docs into fewer, bigger ones: MASTER-PLAN at
~2,300 lines is where all the stale blocks live — big files rot faster than pointed ones.

**Follow-up status (updated 2026-07-10 — Bill greenlit the fixes + THE PURGE):**
1. ✅ drift banners (ASCENSION-STEAL, MASTER §MAPS) + CLAUDE.md index line.
2. ✅ RAID-PLAN frozen → `archive/` (with PORT-PLAN · port brief · UNLOCK-BRIEF · HISTORY;
   see `archive/README.md`).
3. ✅ DUNGEON spec — consolidated as WORLD-PLAN §THE DUNGEON (07-10); content authoring = W3.
4. ✅ stale headers fixed (§ONLINE · §CLASSES · §SYSTEMS-E · §GRAPHICS).
5. ⏳ TEETH folds land with their build claims (breadcrumbs point both ways).
6. **THE PURGE (2026-07-10, Bill)** — the audit's biggest downstream: Voidcaller/Mender/Reckoner
   + the 15 solo bosses + GATE nodes deleted from code; Alchemist/Well become seat defaults;
   Bulwark dies with the Duelist; old-game docs archived. Record: MASTER §GAME SHAPE amendment
   + BUILD-LEDGER §A½.
