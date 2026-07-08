# TEETH-PLAN — the "more depth & more teeth" pass (design session with Bill, 2026-07-08)

**What this owns:** the systems pass from Bill's 2026-07-08 depth dump — add player-facing
DEPTH (spells, richer quests, loot rolls, a light crafting hook, curse events, an endless
node) and more TEETH (harsher, committed picks). Triaged live against the locked laws
(WORLD-PLAN pillars, PROGRESSION Laws #1/#4, Class Framework v2 rules). This is the session
record + build direction; each system's eventual home doc is in §WHERE EACH LANDS.

**Status legend:** 🔒 LOCKED (Bill called it) · ✅ BUILD-NOW (recommended, not vetoed — rides
existing tech) · 🟡 DESIGN-ONLY (needs a feel-verdict or coordination first) · ❌ DROPPED.

**Naming note:** named "TEETH" not "DEPTH" on purpose — the endgame **Depth** ladder
(`spec.depth`, MASTER-PLAN §MODES & ENDGAME) is a *different* system, co-designed in a parallel
thread. Do not mix the words.

---

## THE SESSION IN ONE LINE
Bill (playtest instinct): classes/quests feel thin next to WoW's breadth; we leaned too hard on
timer-combat and skipped depth. Add spells + WHEN→THEN picks, 4-player/contest quests, boss-loot
rolls + resources, a crafting hook, curse events, an endless mode — and pull rerolls out of
Tokens (picks converge; go harsher). **Verdict:** 7 ride tech we already have, rerolls locked,
PvP dropped.

---

## DECISIONS

### 🔒 REROLLS — remove token-rerolls; earn them (Bill, direct)
- Reroll stops being a cheap per-draft Token spend. Becomes a **scarce earned charge**: quest
  reward + Market purchase (**the Market already sells "banked reroll charges"** — half-specced).
- **LOCK retires with it** (LOCK only means "hold a card *through a reroll*" — no cheap reroll,
  no lock). **UPSELL stays** (gamble a slot up = build-shaping, not safety).
- **Tokens re-home to the Market** as the between-fight shopping currency (curios, banked reroll
  charges, wound repair). The mint's old main sink was rerolls; the Market becomes it.
- **Why:** the plan already diagnosed the density problem — *"we'd drifted to 5–6 pick-systems,
  worst on the ~3–5-fight dungeon"* (MASTER-PLAN §UNLOCK). Cheap rerolls converge every draft to
  the same BiS; scarcity makes picks committed. This is the spine of the "more teeth" theme.
- **Build-time reconciliation (don't miss):** two shipped curios hook this path — **Hot Reload**
  (free rerolls) and **Hashgrinder Rig** (Token income ×2). Both need reframing when rerolls leave
  the token economy. The deterministic replay tuple `(run_seed, picks, spends)` + `draft_sim`'s
  spend-transcript stay valid — reroll just drops out of the spend vocabulary (fewer spend types,
  same guarantee). Home: `ASCENSION-STEAL-PLAN.md` / `game/draft.gd`.

### ❌ PVP — dropped (Bill: "forget i mentioned it")
Recorded so it isn't re-derived: PvP appears nowhere in the plan, the combat model is
telegraph-*answer* not free-form fighting, and WARBAND LAW has no PvP analog. The loot-CONTEST
(below) is co-op / closest-wins-for-the-drop — **not** player-combat.

### ✅ THE CONTEST PRIMITIVE — build-now, first slice (highest leverage)
One primitive covers Bill's "4-player closest-to-the-line wins the item" + "co-op / 1v1v1
minigames." A **shared skill-check node**: one telegraph stream every seat answers, execution
scored, best/closest resolves the payout.
- **All tech exists.** The combat engine *is* a timing-minigame engine — the CAPTCHA event
  ("prove you're human: dodge this", one telegraph, reuses CombatCore) is the solo precedent. The
  30 Hz lockstep makes "who stopped closest" deterministic + cheat-proof over the wire.
- **Modes from one node:** CO-OP (all clear a shared bar) · CONTEST (closest/best wins a drop —
  the skill answer to loot distribution) · covers 1v1v1v1 *for the drop* (seats compete on
  execution, not combat).
- **On-theme:** *"BENCHMARK: highest score gets the compute."*
- **Law-clean:** loot distribution stays seeded (lockstep-safe); it decides *who gets* a drop,
  never power (Law #1). Home: WORLD-PLAN node/quest grammar (a new node kind) + a scoring layer
  over `strike_judge.gd`.
- **Open feel-verdict:** the scoring rule — closest-without-over? best-of-N beats? sudden-death?

### ✅ SPELLS & DEPTH — reweight, pilot one class (Bill's headline)
- **Not new tech.** Actives already exist as a first-class draft type: `type:"spell"` → ability
  bar (cap 5), supports exclusive twins. Bulwark/Alchemist/Well draft 2–3; Twinfang/Mender 0.
- **The move:** mint a signature spell kit per class + let the boon draft sometimes offer an
  **active** (or a wired WHEN→THEN) instead of a passive stat — Bill's "pick that instead of a
  static placement."
- **The "WoW has 50 abilities" trap:** answered by the framework's own **collection-vs-deck**
  split — *unlock* a big pool over time (the breadth), *run* a 5-slot loadout (the focus). That's
  the roguelike form of depth, already how the game thinks.
- **Guardrail (Class Design Rule #2):** complexity budget is spent *where the fantasy is* — lean
  classes stay lean-and-deep, broad classes go broad-and-clicky; "deep AND broad" is the smell. So
  **pilot on ONE class** (fold into the next rework), prove feel, then spread. Author via the
  `deck-creator` skill. Home: `TEMPO-PLAN.md` / the pilot class's plan.
- **Open feel-verdict:** which class pilots.

### ✅ LOOT — two distribution modes, both cheap
- **RNG need/greed** (the WoW dopamine): *already designed + half-approved* — the deferred
  "B-half" of the armory pass, parked behind ONE blocker: **AI raiders wear no gear**, so solo
  there's no counterparty. Fix (on-theme): the AI allies roll *and banter*, then hand it over —
  *"I rolled a 98. As a large language model I have earned this loot."* → scraps to you anyway.
  Drops are already seeded/lockstep-safe, so a *shared seeded* roll is legal by construction.
- **Skill contest** (closest-wins): the CONTEST primitive worn as a distributor — earn it.
- **"Random resources to roll on":** the crafting materials (below) sit in the loot table as roll
  results. Home: `PROGRESSION-PLAN.md` §loot (revive the B-half) + `raid_hud._after_drop`.

### ✅ CRAFTING — event-shaped only (partially reverses the old CUT)
- **Reverses** PROGRESSION-PLAN's "Material economy + crafting — CUT" **partially**: a narrow,
  event-shaped crafting is now IN.
- **The shape that stays legal:** signature materials are **drops off named/elite defeat EVENTS**
  (not a farm counter) → **extracted alive** to bank (the existing *extraction-schematic* hook:
  kept only if you reach the Seal alive) → forged at a bench into a **keystone UNLOCK** = a
  *draftable pool row*, never equipped power.
- **Best version:** gate the keystone behind material **+ an oath-kept** — the oath *is* the
  rotation lesson for the thing you unlock (existing "deep/keystone nodes need an oath" hook).
- **What stays CUT:** the counter-grind economy (essences/Foundry/reagent bars, "kill 200 → 50
  feathers"). Materials come from EVENTS not counters (Law #4 events-not-counters intact); the
  output is an unlock not a number (Law #1 intact). Bill (2026-07-08): *"if crafting/loot only
  unlock content like everything else it's fine — it's just the resources rule, breakable."*
- Home: `PROGRESSION-PLAN.md` (amend the cut) + a materials inventory type on the save + a bench.

### ✅ CURSE CARDS — via the named "biting blessings" hook
- Fits the "more teeth" theme + pairs with harsher picks. Two flavors:
  - **Welded downside** on a strong boon (greed — "powerful BUT…"). Precedent exists as the
    "greed toggles" (Twinfang Hone, Well blindfold, Tank Overreach) — expand the vocabulary.
  - **Event outcome** that *poisons an ability* for the rest of the run (StS/Hades-pact). New but
    cheap — a run-state debuff flag. This is the "curse card style event" Bill wants.
- Home: the map's already-named-but-unbuilt **"biting blessings"** (MASTER-PLAN §MAPS Phase 2/3).
- **Open feel-verdict:** bite magnitudes (how punishing before it's un-fun).

### 🟡 ENDLESS — a door on the Depth ladder (coordinate, do NOT fork)
- The infinite-scaling engine already exists + is locked: the **Depth** ladder (numeric spine +
  affix tiers that tighten windows / add beats, never stat-inflation; run-scoped power + a
  how-deep standing = already Law-#1-safe). "Balatro, go till you die" is a new **door/framing**,
  not a new system: an Atlas node chaining floors at ratcheting Depth until a wipe, build
  snowballing within the run. Hangs off the **dungeon push surface** (Depth's home).
- **Coordination:** Depth/endgame is being co-designed in a parallel thread (design-only until
  claimed). **Do NOT re-spec Depth here** — sync with that thread, then frame endless as its
  presentation layer. Home: `WORLD-PLAN.md` §INSTANCES (a new Atlas node) + the Depth thread.

---

## WHERE EACH LANDS (doc homes, for when these get claimed)
- Rerolls → `ASCENSION-STEAL-PLAN.md` + `game/draft.gd` (+ curio reconciliation).
- CONTEST → `WORLD-PLAN.md` node/quest grammar (new node kind) + scoring over `strike_judge.gd`.
- Spells/depth → `TEMPO-PLAN.md` / the pilot class's plan; author via `deck-creator` skill.
- Loot two-modes → `PROGRESSION-PLAN.md` §loot (revive B-half) + `raid_hud`.
- Crafting → `PROGRESSION-PLAN.md` (cut amended) + materials inventory + bench.
- Curse cards → MASTER-PLAN §MAPS "biting blessings".
- Endless → `WORLD-PLAN.md` §INSTANCES + the parallel Depth thread.

## COORDINATION (2026-07-08 — don't clobber)
- Depth/endgame parallel thread (endless folds in, don't fork).
- Live Tank rework at Bill's verdict (Duelist/Warden) — the spells pilot must NOT pick a tank
  spec until that lands.
- Live code worktrees: `cask-policy`, `tempo-pilot`. The `refit-p3`/P4 code line.
- These are all design decisions; **no code is touched by this doc.**

## OPEN FEEL-VERDICTS (Bill owes; none blocking the write-up)
1. Which class pilots the spell/depth reweight.
2. Curse-card bite magnitudes.
3. CONTEST scoring rule (closest-without-over / best-of-N / sudden-death).
4. Endless framing — after syncing with the Depth thread.

## RECOMMENDED BUILD ORDER
1. **CONTEST primitive** (unlocks the most: co-op minigames + skill loot; thinnest flagged slice).
2. **Rerolls-out + Tokens→Market** (locked; mostly-specced; the "teeth" spine).
3. **Loot need/greed revive** (solve the AI-gear blocker with the banter-roll).
4. **Crafting** (event-shaped) + **curse cards** (biting blessings) — the collection/teeth layer.
5. **Spells/depth pilot** — with the next class rework.
6. **Endless door** — after the Depth thread sync.
