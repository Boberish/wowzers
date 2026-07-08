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

### ❌ CRAFTING / MATERIALS — DROPPED (re-cut 2026-07-09, Bill's own reasoning)
- **Reversed this morning, then re-cut.** We greenlit event-shaped crafting on 07-08; Bill then
  dismantled it: a boss-**specific** material is redundant (if the kill can just unlock the thing,
  the material is a pointless middle-step), and a **generic** material is something you farm =
  grind (which we cut). Either way materials add nothing but a grind we don't want.
- **The fantasy survives without them:** "earn your way to a keystone" is already delivered by
  **kill → unlock, gated behind an OATH** (the oath *is* the work / the rotation lesson). So no
  bench, no materials, no crafting — back to the original design's cut, re-derived from first
  principles.
- PROGRESSION-PLAN §Cut-list + MASTER §SYSTEMS E crafting-reversal notes reverted to "stays CUT"
  with a breadcrumb.

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

## REFINEMENTS (worked out later the same session, 2026-07-08 — after the initial commit `096334c`)

### 💠 THE BOSS-KILL REWARD STACK — base rewards + a need/greed BONUS roll on top (🔒 CONFIRMED, Bill 2026-07-08/09)
- **Two layers.** BASE = **personal, guaranteed, no-contest**: your unlock if a row's still locked (the checkmark / collection) + a **curio drop** you equip run-scoped — this is "equipment for everyone" (2 slots, refreshed each run, evaporates at run end). ON TOP = a **contested need/greed BONUS roll** for a **random-rarity UPGRADE** (bump a boon/curio this run) — the communal shiny, one winner.
- **Random rarity = the dopamine; better rarity = better reward.** Reuses the built **rarity-first roll** (Haiku/Sonnet/Opus, weighted + **pity** so droughts are bounded). Better rarity = a bigger swing this run / a cooler upgrade.
- **"On top" is the whole point — no-FOMO kept.** The base is guaranteed (everyone leaves with their loot); the need/greed roll is **pure bonus**, so losing it costs nothing (you kept your base). That's the WoW group-loot social buzz WITHOUT the punishment.
- **Legal by construction:** the upgrade is **run-scoped** (dies with the run); rarity scales *impact*, not permanent stats. **AI allies roll too** (run-scoped ⇒ the "AI keep no gear" blocker doesn't apply); solo = a near-guaranteed win + banter (*"I rolled a 98…"*).
- **NO materials** (crafting cut — see §CRAFTING / MATERIALS). Open feel-details: (a) do base curio drops *also* flash a rarity reveal, or concentrate the slot-machine into just the bonus roll? (b) exactly what the upgrade bumps (a boon's rarity / a curio).

### 🧩 CO-OP CONTEST = a cooperative PUZZLE → party bonus, never punishment (refines §CONTEST)
- Co-op mode of the CONTEST node = the party clears a **coordination puzzle** together; success pays a **party bonus** (a reroll charge / rarity bump / standing). Opt out or flub it = **only a missed opportunity**, zero penalty (co-op-rewarding-never-punishing; no FOMO).
- "Puzzle" **widens** CONTEST from a pure timing check to **coordination** (each seat answers its part of a shared pattern). Open feel-verdict: what a puzzle *is* in a movement-less game (synced beats / split soaks / a communal telegraph).

### ⏳ RESTED — the real-time layer (Bill likes the WoW "rested" model; NOT built)
- The Hades-II "real-time passage" feeling, done as **rested**: while away, a capped pool banks on **wall-clock** time; on return, your **earned event-XP pays ~2×** until it drains.
- **It multiplies EARNED XP, it does NOT hand out unlocks** (Bill's catch: a free "unlock any boon" would kill the quest). You still play the events to earn; rested only gets you to your next pick faster — the quest + oath gates are untouched.
- **Reuses the ONE XP meter** — no new currency, no new faucet, only the bonus. XP sources (all events, no kill-grind): quest turn-ins · oaths kept · first kills · zone conquest · gate proofs · instance clears.
- **Automatically law-safe:** XP only ever buys *options*, never power ⇒ "faster XP" = breadth sooner, never stronger; it can't become a treadmill even in principle. No decay, no reset, no gating ⇒ zero FOMO.
- **Bends (next-level):** event-based XP makes rested read as *"your next few milestones pay double"* (cleaner than WoW's mob-drain); optional skew toward your **least-played classes** = a "try your alts" nudge (which also levels your warband's other seats — the AI drafts from YOUR unlocks).
- **Shape note:** rested is *bank-while-away → spend-on-return*, NOT "ticks during play." The Hades-II "grows while you're in a run" flavor is a separate optional **rig/process** (a Bastion machine on wall-clock) + the **logged-off warband auto-runs → watch-the-replay** idea (real deterministic sims your AIs actually played). Both layer on top; rested alone is ~90% of the feeling for ~10% of the plumbing. Home: `PROGRESSION-PLAN.md` §THE UNLOCK SYSTEM (a rested multiplier on the meter).

### 🧭 THE "NEXT LEVEL" FILTER — a design law (Bill: keep it ahead of its time, not a repack)
- **Borrow the grammar, innovate the sentence.** Familiar SHELLS (draft, loot-roll, raid, unlocks, rested) are *smart* to borrow — they onboard players instantly. A game is only a "repack" if it borrows the shells **and** has a vanilla core.
- **The test for every borrowed system:** *does our version do something the original literally couldn't, because of (a) movement-removed timing combat or (b) the deterministic sim-is-game / real-AI-policy engine?* Yes → next-level. Straight port → bend it until it passes.
- Already passing this session: need/greed → run-scoped rarity-bump + **AI allies who roll & banter**; co-op minigame → a **puzzle on the timing engine**; idle/planting → **real deterministic runs your AI agents actually played**.
- **The moat (original, not borrowed):** the combat (raid trinity as a timing/reaction game) + the engine (deterministic, sim-is-game, AI teammates = real policies → solo == co-op, certified procedural fights, a maxed player + a fresh friend share a fair fight).

### 🌱 RETENTION — the "is there a point once you unlock everything" question (framework; recurs)
- A no-power game swaps the **power** grind for a **mastery + collection + standing** grind. Unlocking everything is the *tutorial*, not the finish. The forever-game: **Depth** (infinite, competitive, social skill rank) · **other classes** (each a deep tree; also upgrades your warband) · **collection/standing** (cosmetics, titles, crests, oath-completions, Versions) · **new content**.
- **Grinder valve = cosmetics + standing + Depth crests + repeatable OATHS** (re-swear ever-harder for run-scoped Token purses + drop-luck; the unlock is one-time, the challenge is infinitely repeatable). **Never** rerolls/consumables/power (that would undo the "teeth" + Law #1).
- **The social answer:** the no-power rule *is* what lets a maxed player and a fresh friend share one fair fight (the co-op scaling contract) — plus the parked MMO-feel levers (co-op-only cosmetics, oath-gifting, warband lending, shared Depth pushing). The rule Bill was "fighting" is what makes "play with friends forever" possible.
- **Confirmed fact:** the AI warband drafts from YOUR account unlocks ⇒ leveling any class improves every seat your warband fills.

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
