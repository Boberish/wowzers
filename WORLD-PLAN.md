# WORLD-PLAN — The Overworld ("the world is the menu")

**Locked design session with Bill, 2026-07-06.** This doc owns THE WORLD: the persistent
WoW-shaped overworld (zones, fog, flight paths, world events, hometown) that wraps the
existing roguelike instances (dungeons = Topology runs, raids = Ring descents). It also
records the COMBAT PILLARS locked in the same session — the rework-era laws every class
rework and every new encounter must obey.

**Thesis:** the world is PERMANENCE and the social layer; instances are VARIANCE and the
runs. You conquer a zone once, forever — then the world becomes your map of doors into
repeatable roguelike content. "The map is the menu" is not a compromise: combat has no
movement, so a zone IS a node map — which makes the whole MMO fantasy buildable on the
map/lobby/lockstep architecture we already have.

**What this is NOT (weighed and declined, 2026-07-06):**
- **NOT two games.** No solo-game / MMO-game split. GAME SHAPE's ONE GAME · ONE HUD law
  is REAFFIRMED — the split was weighed again with the MMO pitch on the table and declined
  for the same reasons it died on 2026-07-03 (double content, double tuning, and a
  no-trinity solo game orphans the tank/healer fantasies). Solo = the same fights with
  your AI warband; PLAY ONLINE stays a lobby layer, not a mode.
- **NOT a simulated MMO world.** No persistent server-simulated zones, no interest
  management, no walk-into-a-live-fight. Presence is a cheap lobby-layer feature; combat
  always happens in the lockstep rooms we have. Honest genre: **Deep Rock / Monster
  Hunter shape wearing an MMO overworld** — a world that feels alive at ANY population
  because the warband is always full (AI backfill is the moat).
- **NOT mid-fight joining.** PARKED (Bill, 2026-07-06 — "stick with what we have").
  The design sketch is preserved in §PARKED for when it's wanted: join = claim an
  AI-driven seat + deterministic replay catch-up from the input log. v1 world events are
  join-before-the-pull.

---

## LOCKED DECISIONS (2026-07-06, with Bill)

1. **ZONES = PERSISTENT CONQUEST.** Zone progress saves — cleared nodes stay cleared
   forever, fog stays lifted, you can stop mid-zone and come back. No wipe-reset, no
   drafts in zones. The world/instance line is exactly the permanence/variance line.
2. **OVERWORLD POWER = BARE KIT + PERSISTENT UNLOCKS.** Zone/quest/event fights enter
   with kit + Creed + whatever your unlock ledger has opened (levels = options, never
   stats — Law #1 intact). Boons, curios, Tokens, charge: **instance-only**. Zone fights
   are quick 2–4 min combat puzzles, tuned bare — cheap to generate, cheap to verify.
3. **THE WARBAND LAW.** You travel and fight as your 4-seat party EVERYWHERE — AI fills
   empty seats (Commander builds them), friends replace AI online. Every encounter in the
   game is tuned for exactly 4 seats ⇒ **no 1-to-x enemy scaling system, ever.** Solo
   pressure still exists inside the 4-seat frame: GATE-style personal nodes, `rand_target`
   personal beats, owned adds. (Bigger raid brackets = a someday decision, not v1.)
4. **INTERRUPT-BY-ABILITY (Bill's design — replaces the cut Voidcaller's verb).** No
   dedicated kick button and no kicker class: **certain existing abilities carry the
   interrupt** — landing one inside a kickable cast's window stops the cast. Full spec in
   §COMBAT PILLARS. Voidcaller is cut from the roster plan; it stays in code as the frozen
   caster-seat placeholder until the caster-seat rework replaces it.
5. **SINGLE TARGET LAW** and **DODGE RATION** — see §COMBAT PILLARS.
6. Prior locks that this plan builds on, unchanged: GAME SHAPE (one game / one HUD),
   PROGRESSION laws 1–6 (no persistent power, everything rides the fight spec, no timed
   content), Class Framework v2 (Tempo pilots; roster frozen until reworked), Depth /
   Versions endgame, Curio Economy v2 (Market primary).

---

## THE WORLD MODEL

### Structure: ATLAS → ZONE → NODE

- **THE ATLAS** — the world map, the game's front door (at W3 the flow becomes
  PLAY → Atlas). Regions of zones; fog over unvisited zones; your warband token sits on
  it. *Naming rule to kill ambiguity forever: the persistent world map = the **ATLAS**;
  the per-run instance maps stay the **TOPOLOGY**. Never mix the words.*
- **A ZONE** ("our Westfall") — an **authored, fixed node map** (~12–18 nodes): same
  geography for every player, because shared geography is what makes a world real
  ("the cave is north, the dungeon is on the east edge"). Light seeded dressing only
  (which skirmish variant spawns at a node); layout, landmarks, quest chain, and
  entrances are hand-placed. *(Authored-vs-seeded is a soft call — recorded as an open
  decision, but authored is the strong recommendation: guides, directions, and memory
  are the point of a world.)*
- **A NODE** — one screen of content: a fight (Forge skirmish / **ELITE mutator fight** /
  named miniboss / personal gate), an event (Inference-Check grammar reused verbatim),
  a **ZONE REMEMBERS choice** (§ZONE QUESTS & DYNAMICS), a cache, a camp (rest/lore),
  a WAYSTATION (flight path), a quest pickup/turn-in (the TICKETS system generalized to
  persistence), or an INSTANCE DOOR (dungeon / raid entrance).

### First visit — the conquest

- Fog hides everything but the entry edge and silhouettes of adjacent nodes
  (the "unindexed" idiom, now with a real fog system — un-parks the Panopticon curio).
- You fight node to node. **Branching is the zone's texture**: the critical path to the
  zone capstone is one spine; caves, shrines, and side-chains hang off it. Bill's exact
  fork is the design target: *"go fight stuff in a cave, or rush to the dungeon"* — both
  must be legitimate. Therefore:
  - **The dungeon door unlocks by ROUTE, not by completion**: clear any path of nodes
    that reaches the door. Rushing is real.
  - **ZONE CLEARED** (crest + waystation/flight unlock) = critical path + the zone
    capstone (a named boss from the casting pool at the spine's end).
  - Side content is optional and pays in unlock-lane rewards: Ledger rows, curio table
    deeds, cosmetics, standing, atlas lore.
- Cleared nodes never re-fight — travel through conquered territory is free node-hopping.
  Repeatable combat lives in instances and world events, NOT in zone respawns (no farm
  loop in the permanence layer; if playtests want an overworld grind valve, PATROL nodes
  are the parked idea — see §OPEN).
- Zone quests = persistent **TICKETS v2** — full grammar (route / deed / door / event
  tickets), ELITE mutator fights, and THE ZONE REMEMBERS flags all live in **§ZONE
  QUESTS & DYNAMICS** below. Rewards obey the lane law: **access** (flight, doors,
  attunement), **pool** (Ledger/curio unlocks), **standing** (crests/cosmetics). Never
  stats, never run-scoped currency.

### Travel & flight paths

- **WAYSTATION nodes** = flight masters. Unlocking a zone's waystation (zone-cleared)
  adds it to the flight network: instant travel between any two unlocked waystations from
  the Atlas. Within a cleared zone, click-to-travel between cleared nodes.
- First-visit traversal cost is the fights themselves (no travel-time mechanic, no mounts
  system — this is a menu with fiction, keep it lean).

### The hometown — THE BASTION (name TBD)

The hub zone, unlocked from the start, no combat. It **physicalizes the meta screens**
(and answers PROGRESSION-PLAN's open "hub screen" question): the **LEDGER HALL** (per-boss
pages, oaths, tables), the **CHARACTER SHEET** (proof crests, deepest ring, versions,
per-class levels), the **WARBAND CAMP** (Commander party setup lives here as a place),
a **PRACTICE yard** (the unlock-inert practice surface), the **QUEST BOARD** (optional zone
tickets — the Invention-Quest faucet, §MEWGENICS STEALS ②), and later the social lobby.
v1 = one gorgeous screen with stations, Gilded Reliquary language; it's a menu wearing
a town, and that's fine — it can grow doors later.

### The friend ritual — attunement without the WoW tax

- **Instance doors gate on the party, not the player:** everyone in the party must have
  the door unlocked (route-cleared) to enter the dungeon. So bringing a new friend means
  *fighting through Westfall together* — the ritual Bill wants, and it's shared combat,
  not "go solo your homework" (PROGRESSION's "never sent away" rule is satisfied — you
  go WITH them).
- **Co-op zone credit:** clearing a node in co-op credits every party member's world
  save that still needed it. The party plays the least-progressed member's frontier
  (helping = replaying content you've cleared; your save is untouched, they progress).
- **Budget law:** a zone's critical path ≤ ~30–45 min of first-visit content. The gate
  is a ritual, never a chore. No attunement *chains* — one zone's route unlocks its own
  doors, nothing else.
- The veteran's payoff for carrying: salvage Tokens are run-scoped so instead vets earn
  **standing + oath-gift economy** (E.5 — farm deeds, gift the drop-bend to the newbie:
  already designed, this is its stage) + their own side-content/Ledger gaps.

---

## ZONE QUESTS & DYNAMICS — TICKETS v2 (locked 2026-07-06, with Bill)

**THE ECONOMY SPLIT (Bill's pick — "The Split"):** the in-run rolling economy (Draft 2.0,
Tokens ⏣, rarity/pity rolls, Market, rerolls, wounds, run-tickets) is **KEPT VERBATIM as
the instance-only layer** — behind a door the run still exists (a dungeon is a contiguous
30–45 min Topology run), so mid-run build-editing moves indoors whole; zero rework of the
built systems. Zones mint NOTHING. **The bridge: overworld quests edit the COLLECTION;
runs edit the DECK** — zone quest rewards grow the pools instances roll from (Ledger rows,
curio table deeds, event-pool entries, Forge variants), never mid-run numbers (Hades'
Fated List pattern; Law #1 + Monotonic Pool Law intact). Zone quest inventory = tickets
only — keys/shards stay Topology texture (zones are deliberately LIGHTER than the raid web).

### The quest grammar (all persistent; Zone 1 builds the first three)
- **ROUTE tickets** — pickup at node A, turn-in at node C: directed conquest (first-visit
  traversal IS fights). The built TICKETS tech generalized to persistence.
- **DEED tickets** — performance objectives in zone fights ("zero missed kicks at the
  mill"), reusing the oath detector tech (`seat.diag`); one-shot persistent deeds,
  distinct from re-swearable instance oaths.
- **DOOR tickets** — the WoW dungeon-quest loop: the objective completes inside ANY run
  of the zone's dungeon, turn-in back in the zone. Reads run RESULTS (seed-verified),
  never injects state into a run.
- **EVENT tickets** — recurring quests on world events (standing lane, no-FOMO). W4.
- **ESCORT / VOLATILE tickets (Mewgenics steal, 2026-07-06)** — pick up a payload at node A,
  carry it to a turn-in: while you hold it, intervening fights gain an enemy-side MUTATOR
  (extra add / hazard beat — a BURDEN, never a buff, so the OVERWORLD POWER rule and the
  "mutator lives on the enemy side" rule both hold). The quest IS a run of harder fights, not a
  fetch errand — this turns TICKETS from an errand into a mechanic. Reuses the ELITE-mutator
  palette on a carried object instead of a node; enemy-side data rides `(seed, spec)` →
  sim-clean, lockstep-safe. Drop/timeout = payload lost (route as a failed ticket; no run-state
  injection). Rationale in §MEWGENICS STEALS ①.
- **Forge hook:** a ticket can flip a node's Forge variant ("the bandit leader appears
  once you've read the note") — authored feel on generated content.

### ELITE nodes = MUTATOR fights (Bill's "module" idea, 2026-07-06)
Some zone fights are ELITE: a Forge body + **one visible MUTATOR** (an affix that changes
the fight's shape — an added string verse, a chanter attendant, a hazard beat), never a
player draft (bare-kit law intact: the modifier lives on the ENEMY side, so player-side
sims stay clean). Where authored, the spicy variant is **choose your poison** — the node
offers 1-of-2 mutators before the pull: in instances you shape your BUILD; in zones you
shape the BATTLE. Mutators are Forge palette knobs → certified by `forge_sim` like
everything else.

### THE ZONE REMEMBERS (the one-time spice — Bill's pick over Zone Heat)
Choices and fight outcomes set **permanent zone flags** that visibly rewire later nodes:
burn the supply depot → the capstone loses its add wave but the cache node is gone; spare
the deserter → a backdoor opens two nodes later. Geography stays FIXED (authored-map law):
flags change node payloads / dressing / spawns / unlocked edges, never layout. Any flag
that touches a fight enters as pure data in `(seed, spec)` (the aspects idiom — lockstep
and sim safe). Your Mirefen ends up subtly different from your friend's — that IS the
social texture ("wait, your mill is still standing?"). Zone Heat (a route-reactive alert
dial) was weighed and passed over for Zone 1; it stays a candidate spice for a later zone.

### Co-op replay — the GUEST-WORLD rule (Bill's replay question, answered)
Extends the locked least-progressed-frontier credit rule; nothing new in netcode beyond
flags riding the campaign broadcast:
1. **A zone session plays ONE world:** the least-progressed member's save (tie → party
   leader). Guests see THAT world's flags — including choices that went differently from
   their own.
2. **Pending choices belong to the saves that still have them:** the frontier owner picks
   (others advise); the outcome writes back to every member whose save still had it
   pending. A member whose flag is already set keeps their own value — saves never
   regress, never overwrite.
3. **Guests re-fight nodes uncleared in the host's save — that IS zone replay.** Your own
   cleared zone never re-fights; "redo the quest with a friend" = play through HIS
   Mirefen and watch his choices land differently.
4. Personal full replay = a fresh character slot (world saves are per-slot already).

### Zone sizing — the node-count formula (Bill: "we should be able to scale up")
- **The spine is capped by the attunement budget law** (critical path ≤ 30–45 min), which
  pins it at **~8–12 nodes forever. Scaling is BREADTH, not length** — side chains hang
  off the spine freely (they don't tax the friend ritual; only the route to the door does).
- **Mix ratio:** ~½ fights (¾ Forge basics, ¼ elite/miniboss — elite cadence ~1 per 4–5
  basics), ~¼ events/choices, the rest utility (tickets / camps / caches / gate / doors).
- **Zone 1 target: ~20 nodes** (up from the earlier 14-node sketch — the Forge makes
  fights cheap; events/choices are the real authoring cost). Full-clear ≈ 45–70 min,
  route-to-door well inside the budget. Later zones scale to ~25–35 by adding chains,
  never spine.

### MEWGENICS STEALS — escort payloads · quest board · the risk fork (folded 2026-07-06, Bill: "123")
Three refinements lifted from Mewgenics' overworld (deep-research pass, 2026-07-06). Its skeleton
already matches ours (node maps · pickup→turn-in quests · attrition · persistent unlocks), so the
value is these specific parts, each adapted to our locked laws. **Land target: W2** (Forge +
TICKETS v2), the next unbuilt piece.
1. **ESCORT / VOLATILE tickets (①)** — the headline steal. Mewgenics quests carry a *run-altering
   modifier item* to a destination; ours were inert. New ticket verb (full spec in the grammar
   list above): holding the payload applies an enemy-side mutator to intervening fights — a
   BURDEN, never player power, so OVERWORLD POWER + "mutator on the enemy side" both hold. Turns a
   fetch quest into a MECHANIC. **GILDFIELDS fit:** escort the cracked GRAIN-VIAL toward the
   UNDERMILL door — the harvest-rot spreads an extra add into every fight en route until you turn
   it in (the dying-harvest arc made playable, not just backdrop). **SLICE BUILT (2026-07-06,
   branch `escort-ticket` `ca05269`, flagged `ESCORT_PREVIEW`):** pure `Escort` state machine on
   the world save (pickup 4 → carry → turn-in 19), a `carry.burden` add via the existing add-wave
   engine (**CombatCore untouched, pure data**); route WARDEN'S REST(4) → GRANARY STEPS(5)
   burdened → UNDERMILL GATE(19). Verified: `world_probe` + `ui_smoke_world` green, `raid_sim`
   **byte-identical** to baseline. **Deepened (`eaf628e`):** sustained TWO-WAVE burden (husks at
   0.8/0.45, self-sequencing — a tune knob), a pre-pull WARNING on burdened fights (the player
   connects the pressure to the vial), and the cleared-door turn-in **soft-lock fixed** (rush-
   then-carry still completes). Owed before merge-worthy breadth: a richer burden *flavor* (a
   kickable cast / hazard beat, once the interrupt pillar lands — the slice is a melee husk), a
   lane-law turn-in **reward** (a pool row — the slice pays a standing flag + toast), and route
   data lifted into authored node fields. **Awaiting Bill's feel pass** (`--autostart=zone`).
2. **THE QUEST BOARD (②)** — Mewgenics splits quests into *Progression* (story items from bosses)
   and *Invention* (optional, from an NPC — a steady faucet). We have the progression side
   (DOOR/ROUTE/ESCORT tickets); we lack the optional heartbeat. Add a **QUEST-BOARD station in THE
   BASTION** minting optional DEED/route tickets for standing + pool rows only (lane law) — a
   persistent "reason to go back into the Gildfields" that isn't the authored spine, and a real
   *function* for the hometown. (Station added to §THE BASTION.)
3. **THE RISK FORK (③)** — sharpen the "cave vs rush" fork (§First visit) into a legible, recurring
   2-way beat: EASY branch (1 fight, reconverges fast) vs HARD branch (Champion/ELITE fight + extra
   node + fatter cache), stakes signposted BEFORE the commit, both reconverging at the capstone.
   Steal the legibility + cadence; **swap the reward axis** — Mewgenics pays the hard path in
   level-ups/loot (in-run power, illegal here) → ours pays in **pool rows / standing / a fatter
   cache**, never stats. "Choose your poison" given a repeatable shape.

**Explicitly NOT stolen:** roster retirement/churn (it's the breeding engine Bill cut, and it
fights the fixed-warband fantasy) · the mana combat system (wrong genre) · their headline flaw,
route *predictability* — ZONE REMEMBERS + branching already beat it, so don't over-linearize
chasing their readability. **Where we're already ahead:** choice-persistence (they have none) and
verified procedural generation (they hand-author). **Parked for the RUN layer, not zones:** their
post-boss "bank now or push deeper" push-your-luck decision fits TOPOLOGY/raids (run economy dies
on failure), not persistent-conquest zones — revisit at the raid retune.

---

## INSTANCES — the run layer (what the world's doors open into)

| Surface | Shape | Length | Economy | Repeatable? |
|---|---|---|---|---|
| **Zone fight** | 1 authored/generated fight, 4 seats | 2–4 min | none (bare kit + unlocks) | no — conquest is permanent |
| **World event** | 1–2 fight encounter at an event node | 5–10 min | event Ledger table roll | while the event is up |
| **Personal gate** | 1v1 class exam (existing GATE tech) | 2–3 min | oath stage, table attach | as authored |
| **DUNGEON** | **1-floor Topology run** (seeded map, drafts, curios, Market, charge) → 1 Seal | 30–45 min | full run economy, compressed | **infinitely, "from scratch" — the roguelike core** |
| **RAID** | multi-floor Ring descent (Realm 1 = the existing 3-Ring Takeover, unchanged) | 1.5–3 h | full economy + shard gates + charge + finale meta-payout | infinitely; **Depth** scalar = endgame |

- **Dungeons are the Versions surface**: the door itself carries the version dial
  (v1/v2/v3 + fake patch notes) — the Trial Ladder gets a physical home instead of a menu.
- **Raids are the Depth surface**: the raid door carries the Depth dial. Both dials ride
  `(seed, spec)` as designed — nothing new.
- **Run pacing generalizes by structural breaks, not floors** (TEMPO-PLAN reconciliation):
  Creed at run start (all runs); **Module pick at the run's first structural break** —
  dungeon ≈ midpoint node; raid = end of Floor 1 (as specced). Long raids may earn a
  second Module slot at Ring 1/0 — flag for TEMPO-PLAN when the raid retune happens.
- **Realm reconciliation:** realms stay the RAID theming unit (Takeover = what's inside
  that raid). The overworld is the shared dark-fantasy Rift reality, played straight —
  which resolves the tone question cleanly: jokes live inside realm doors, the world
  outside them is earnest. Zone skins are world-fiction, Topology skins stay per-realm.

### RAID vs DUNGEON — the identity split (locked with Bill, 2026-07-07)

Bill's WoW-classic instinct ("raids: lockout + humans-only + aggro; dungeons: M+ farm")
triaged against the laws — what survived is the *identity* split, not the gates:

- **⚠ REVISED 2026-07-09 (Bill) — aggro is now UNIVERSAL, not raid-only.** The old lock
  quarantined aggro to raids because the *threat-meter* taunt was clunky. The tank rework
  replaces it with **aggro = FLOW** (a skill readout on the tank's minigame, not a rotation),
  so it's fun enough to live everywhere (`TANK-PLAN §1c`). **One rule in all content** —
  overworld / dungeon / raid — so players never relearn it; only the *ambient numbers* scale
  by content (the Depth spine), never the aggro rule. **Raids keep their identity via
  intensity** — the full coordination *expression* (tank-swaps, hot-potato curses, split
  soaks) blooms only at raid numbers. Single-target law holds: one boss stream, the recipient
  varies (the built "Swing → Victim"). `threat_enabled` stays the engine flag but is now on by
  default in group content, feeding off flow.
- **Dungeons are the M+ push surface.** The infinite Depth ladder (`spec.depth` numeric
  spine + affix breakpoints — design locked 2026-07-04, MASTER-PLAN §MODES & ENDGAME)
  gets the DUNGEON door as its **primary home**: 30–45 min runs are the natural
  push/farm cadence, and Forge tiers + TICKETS mutators are the affix vocabulary. One
  scalar, two doors — raids keep their Depth dial as the long-form flex; the dungeon is
  where you *push*. (The dungeon Version dial stays — Versions = discrete authored
  mechanic-adds, Depth = the continuous procedural scalar, as reconciled 07-04.)
- **Co-op-REWARDING, never co-op-GATED.** Human-only raids were weighed and CUT: they
  break the Warband Law and kill the flagship content for the actual audience. AI
  backfill stays everywhere; raids make human seats *shine* through coordination
  mechanics, not requirements.
- **No lockouts, re-affirmed.** A raid daily lockout was weighed and CUT: PROGRESSION
  law 4 (no timed content) stands — there is no economy to pace (numbers die with the
  run), and descent length (1.5–3 h) + the parked RAID RITES already carry the "raids
  are a big deal" weight without a clock.
- The *real* goal behind the instinct — "make people play together" — is recorded as an
  open want (MASTER-PLAN parking lot: **MMO-feel levers**); it will be served by
  presence/social systems, never by content gates.

### THE STAKES MODEL — wipe budget · attempt tokens · the difficulty contract (locked with Bill, 2026-07-09)

**The tension:** WoW bosses can be complex *because* a wipe is cheap — res, run back, retry. A
roguelike wipe is expensive — you lose the run. You can't have "learn-the-fight-by-wiping" AND
"one wipe ends your hour"; the **retry cost IS your complexity budget.** So the two doors take
two wipe rules, matching the identity split above.

- **RAID — floor checkpoint + a finite WIPE BUDGET** (the WoW loop, made roguelike-honest). A
  wipe does NOT end the descent: you res at the current **floor checkpoint** and re-pull the
  boss, and **cleared floors stay cleared** — this is the answer to open-decision #6 (descent
  save/resume = the floor checkpoint). But attempts are **finite**: a per-descent budget (start
  **3** — playtest). Spend the last one and the descent ends. So a fight you genuinely can't
  learn eventually costs you the run (roguelike stake intact), while a fight you *can* learn you
  beat inside the budget (WoW learn-and-retry intact). Monster Hunter's carts, fused with our
  economy.
- **DUNGEON — lean by default (1 life; from-scratch is the point at 30–45 min).** The roguelike
  core keeps its purity — a restart is fast, so no free checkpoint. Attempt tokens (below) can
  *buy in* defiance for players who want it, but the honest default is one life.
- **ATTEMPT TOKENS — the "paid strat" (our Death Defiance), spendable in ANY surface.** One
  consumable = +1 attempt on your budget. Two sources, both real opportunity-cost, never a free
  undo: **earned** at a node (a TICKETS reward you took *instead of* a curio) and **bought** at
  the Market with Tokens (rides GEAR-3; a natural extra Token sink alongside reroll charges — see
  PROGRESSION §Tokens). This is Bill's "earn a revive / shop auto-revive," reframed as a legible
  resource — a route/build *choice* that adds strategy instead of cheapening death.
- **Why it doesn't cheapen the roguelike.** A *free rewind* would; a *finite, earned/bought*
  attempt doesn't — Hades' Death Defiance is a build choice, not a safety net, in one of the
  most-loved roguelikes going. And the real anti-cheapening tool is already locked (PROGRESSION,
  2026-07-09): **oaths bank win-or-lose**, so a wipe is never *nothing* — partial persistent
  progress, never a rewind.

**THE DIFFICULTY CONTRACT — base vs the ladders (revised with Bill, 2026-07-09).** The base
fight is **not** "learnable in one session" — like the Spire, you lose runs learning it; it's a
mountain mastered **over many runs** (the Mistral→Gemini→Mythos arc already is this). What base
content does NOT do is pile on "20-mechanic mythic memorization." That infinite "study for an
hour" tier is the **ladders**, already designed (MASTER §MODES): **Versions** (per-boss
*authored* mechanic-adds — "each version ADDS MECHANICS, never +HP%"), **Depth** (the
*procedural* window-compressing scalar), and the parked **Run modifiers** (the StS-Heat /
Ascension stack). So: base = a learnable mountain; each +1 up a ladder adds a real mechanic;
failing costs attempts, then the run. *(Numbers — budget size, dungeon 1-life vs small budget —
are playtest, not blockers.)*

**BATTLE-REZ — already built; a different layer (reconciliation).** The in-fight revive exists:
the healer's **Rekindle** (the Well = 6 charges; the frozen Mender = 120 s CD), a 6 s channel,
back at 40 % HP, R-key on a fallen ally's frame. That's the *in-fight* answer to one seat dying
— a **combat** resource, separate from the run-loss wipe budget above. Open idea (💡): a
**boon/curio battle-rez** beyond the healer (Bill's "some boons with it") — an extra charge or a
self-rez trinket — so a healer-less warband isn't hard-locked. Capture only, not designed.

---

## WORLD EVENTS — the "big boss randomly pops" layer

- **v1 (with W4 online):** the server schedules an event in a zone ("VORATHEK tears
  through the Mirefen"). Everyone with that zone unlocked sees the Atlas banner + the
  event node pulse. Walking your warband there = joining an **open lobby**; the fight
  fires as a normal 4-seat lockstep room. **More than 4 show up → parallel rooms**
  against the same boss (instanced world boss, modern-MMO style) — everyone fights,
  nobody is locked out, and our room server already does rooms.
- **Offline parity (no dead-world failure mode):** events also fire in offline play on
  the same cadence logic — your AI warband answers the call. The world is alive alone.
- **No-FOMO law:** event rewards are fortune/standing (an event Ledger table, cosmetics),
  and any event-exclusive TABLE must recur — events are a *when*, never a *whether*.
  Nothing timed ever gates progression (PROGRESSION law 4 extends to events).
- Event bosses come from the casting pool. **Vorathek is reborn as the first world
  boss** — the wandering rift-beast fits perfectly, and it frees Seal I's slot in the
  raid ladder narrative (raid keeps it as the tutorial Seal until the raid retune).
- **Presence layer (W4):** a zone = a lightweight server room (roster of who's here,
  chat, map pins). Pure lobby-layer; combat protocol untouched. This is ALL the "MMO
  feel" v1 needs: seeing names in Westfall and a boss banner firing.

---

## THE ENCOUNTER FORGE — the enemy generator (the new tool this plan actually demands)

Zones need dozens of small fights; hand-authoring each kills throughput. The FORGE is a
seeded encounter assembler producing `EncounterRes` **pure data**, from per-zone palettes:

- **BODY archetypes** (HP band / melee cadence / loss-pressure shape): BRUTE (slow heavy
  exam swings), SWARM (chip + aoe beats), STALKER (feint-heavy), CHANTER (kickable casts),
  WARDEN-type (strings). Bodies are stat + cadence templates.
- **MOVES**: 1–2 abilities drawn from the zone's palette — every move is one of our
  proven exam verbs (parry-check swing, dodge string, kickable cast, personal rand-beat,
  crush/blockable) with tier knobs (window widths, damage fracs, string length).
- **A STRING TEMPLATE** (from the M7.2 library shapes) sized to the body.
- **TIER** = zone difficulty knob (teaching → veteran), scaling cadence/windows — never
  raw stat inflation beyond the spine (same philosophy as Depth).
- `make_skirmish` (add-packs → standalone fights) is the proven precedent; the Forge
  generalizes it.

**The determinism dividend — verified procedural content (our unfair advantage):** every
generated encounter is batch-simmed at 3 policy tiers before it ships. Auto-reject
out-of-band results (too lethal, too free, degenerate strings, unwinnable). A nightly
`forge_sim` pass = thousands of seeds across the whole generated pool with printed bands.
Nobody hand-tunes 60 zone fights; the harness certifies them. **Acceptance bar for the
Forge itself:** determinism PASS; band targets per tier hit within tolerance; zero
never-winnable outputs across the full seed sweep; named minibosses excluded (those get
a designer soul on a Forge body — generator does the body, a human does the signature).

### FORGE — build spec v1 — ✅ BUILT & MERGED 2026-07-07 (`d3722f5`; full record in the
### Coordination Log; shipped as specced below + the chaff-pair authoring rule: a SWARM
### is never alone.)
### THE DESCENT REFIT — ✅ BUILT (`raid-forge`, 2026-07-07): the Forge came home to the
### raid. Realm-1 "takeover" palette (CRAWLER SWARM / UNSUPERVISED LEARNER / SCRUM-CANTOR /
### LEGACY MONOLITH); floors grew to 8 rows = **20 nodes** (RunMap gained a `rows` param,
### default 6 = every classic map byte-identical); `floor_fights` interleaves takeover
### strays BETWEEN the story subagents (tier ramps t1→t3 with the ring); **packroll fillers
### → forge lightweights** — the open item below is CLOSED (a rolled trio now lands
### mid-fight-sized, not Seal-sized) with weights opened to 30/45/25; server + map screen
### follow. Story quotas (events / tickets / gate) untouched. Still open: per-body stage rigs.
- **`data/world/forge.gd`** — `Forge.make(zone, body, tier, seed) -> EncounterRes`, pure
  static, own DetRng. **THE ID IS THE RECIPE:** generated encounters carry id
  `forge:<zone>:<body>:<tier>:<seed>` and `RaidContent.encounter_by_id` gains a `forge:`
  prefix arm that REGENERATES from the id — specs stay strings, lockstep/replay/pack
  chains all work with zero registry (additive arm; every existing id untouched).
- **BODIES v1 (4):** SWARM (light, chip melee + dodge beats — the pack filler the quota
  roll has been waiting for) · STALKER (feint-heavy swings) · CHANTER (kickable casts +
  the kick-tax) · BRUTE (slow heavy parry exams). Each = HP/melee/enrage budget on the
  BAKED baseline (swarm ≈ 4.5k … brute ≈ 9.5k — a swarm-swarm-brute trio lands mid-fight
  size, fixing the "trio runs Seal-sized" wart) + 1–2 MOVES drawn seeded from the body's
  verb palette (parry swing / dodge string / kickable chant / nova) with **TIER knobs**
  (t1 teaching → t3 veteran: windows tighten, cadence quickens, string beats grow — never
  raw stat inflation).
- **ZONE PALETTE = the fiction skin:** per-zone name/intro tables (Gildfields: HUSKMAN
  REAPER · CHAFF-SWARM · HEDGE STALKER · GRAIN-CANTOR…) — the Forge does mechanics, the
  palette does soul. **Zone 1 content pass rides along:** every Gildfields stand-in
  (bard/sonnet/opus) swaps to authored `forge:` ids (fixed seeds = the world's "light
  seeded dressing", same fight for every player) — THE TONE CRACK CLOSES (no more
  BARD.EXE in the fields). THE PALE TILLER = a t2 BRUTE body wearing its authored name
  (the named-miniboss rule: generator body, human soul). The capstone stays VORATHEK
  (casting pool). **Raid Topology now uses a "takeover"-palette Forge pool too** (THE
  DESCENT REFIT): the story subagents (bard/sonnet/opus + the Seals) stay authored, and
  Forge strays fill between them + ride the pack walk-ins — the Realm-1 skin stays correct
  inside the door, now generated instead of duplicated.
- **`sim/forge_sim.gd`** — the certification harness (psim-sharded): sweep bodies ×
  tiers × seeds at 3 policy tiers; print bands; ASSERT determinism (id ⇒ identical
  checksum), zero expert-unwinnable, per-tier band tolerances; CSV per seed.
- **Gates:** forge_sim ALL PASS (Zone-1 pool certified) · frozen-main A/B twinfang(120)
  + raid(60) byte-identical (the encounter_by_id arm is additive) · world/raid smokes ·
  pack/packroll/world probes · play-copy sync. Stage puppets default for forge ids
  (per-body rigs = a later art pass).

---

## COMBAT PILLARS (rework-era laws — lock BEFORE continuing class reworks)

1. **SINGLE TARGET LAW.** One boss, one telegraph stream, no target-switching UI, ever.
   Multi-target flavor = the systems we have: add waves (boss withdraws), owned adds,
   split phases, chains. Click-cast healing, threat, and the dial all keep their one
   anchor. *(Bill, 2026-07-06: "put the mechanics into one thing.")*
2. **DODGE RATION.** The universal dodge STAYS for every seat — it's the one demand the
   boss can make of everyone, and M7.2 proved strings carry skill gradients (venom
   Executioner 95/78/52; the Choir finale *improved*). **(2026-07-08, `DODGE-PLAN.md`): it
   is now ONE verb** — the swing-negate and the barrage beat-dodge collapse onto a single
   spacebar dodge (0.35s recovery / 1.3s whiff), live for Twinfang/Alchemist/Well and the
   default for every reworked kit; the redundant F dodge is retired as classes convert. But it's rationed: **a few
   authored beats per fight, not a hundred** — target ~3–8 answerable beats per non-tank
   seat per boss (knob per tier), placed at moments, not as weather. Every class rework
   MUST define (a) its PERFECT/GOOD payoff into its own resource (M7.2 pattern) and
   (b) where beats sit relative to its rhythm — for Tempo, strings are authored into
   rhythm gaps so footwork punctuates the beat instead of breaking it. Tanks keep the
   densest footwork by design.
3. **INTERRUPT-BY-ABILITY** (Bill's spec, 2026-07-06). No kick button; no kicker class.
   - `AbilityRes` gains an `interrupts` flag (pure data). Landing a flagged ability while
     an INTERRUPTIBLE cast is inside its **KICK WINDOW** stops the cast (existing kick
     resolution path — silence/chain semantics unchanged).
   - **The window is TIGHT** — start from the clean-zone idiom (last ~35% of the cast)
     and tune down. The named risk is accidental kicks from normal rotation; the sims
     measure it directly: add an **accidental-kick rate** diagnostic (kicks landed by a
     policy that never aims) vs **deliberate-kick rate** (a policy that holds the ability
     for the window). Tuning target: accidental <10%, deliberate >85% at good-tier.
   - **Carriers are the class's DUMP/payoff abilities** wherever possible — holding your
     spender to stop a cast costs you throughput: the **interrupt tax** is the decision.
   - **Distribution is comp texture** (Bill): some classes carry 2 interrupt-capable
     abilities, some 1, some 0 — "who covers the kicks" becomes a party-assembly question
     (Commander included). Chain content (Seal verses) retunes against "the party must
     hold dumps across a chain," which is a richer version of the old kick-rotation.
   - HUD: carrier runes glow while a kickable cast is up; the StrikeJudge already renders
     the clean-zone window — reuse it.
   - Rollout: lands class-by-class WITH the Framework-v2 reworks (Tempo first — pick
     which Tempo ability carries it in TEMPO-PLAN §10's content pass).
4. **THE WARBAND LAW** (see LOCKED #3) — all content tuned for exactly 4 seats.
5. **OVERWORLD POWER RULE** (see LOCKED #2) — bare kit outside, full economy inside.
6. Standing engine law is untouched by ALL of this: `CombatCore` stays the pure
   deterministic reducer; the world is game-layer + net-lobby-layer only. The only
   engine-adjacent work in this plan is the `interrupts` ability flag (guarded, byte-
   identical when absent) and Forge output (pure data).

---

## FIGHT LENGTH & THE PACING GRAMMAR (locked with Bill, 2026-07-06)

**The finding (Bill, playtest):** fights are much too short — "I rarely get a combo off
before stuff dies" (Seals enrage at 90–142s; skirmishes at 60–70s; the Framework-v2 kits
have build arcs longer than the fights). Target: medium fights 3–5 min, late bosses ~10
min, overall boosted HP — BUT long fights tax focus, and menu/out-of-game time between
fights is lame. So length comes from STRUCTURE inside one battle, never from sponges or
screens. **Side dividend:** longer fights are the lever that finally makes the healer
economy bite (the logged inert-mana finding — mana ≥93%, idle 93–98% — was a fight-length
symptom as much as a tuning one).

### The three LAWS (verdict pass folded, Bill 2026-07-06)
1. **NO FLAT SPONGES.** Every added minute of fight length arrives with a *structure
   beat* (a new pack member, an arena, an add wave) — never the same intensity stretched.
   HP boosts ride structure.
2. **DEMAND ROTATION.** A long fight rotates which skill is loaded instead of sustaining
   everything — scheduled focus peaks with real valleys. The dodge ration budgets its
   ~3–8 beats **per segment**, placed at moments (pillar #2 unchanged, applied per-segment).
3. **NO HARD STOPS — valleys are DIEGETIC** (Bill's ruling: a pause "adds more stress...
   and how do we pause a battle? that's hard to keep your flow"). The battle clock never
   freezes into a text screen or countdown. The breather IS the fiction: the next pack
   member walking in (2–3s, no telegraphs), the boss withdrawing behind an add cycle,
   the chase transit. You stay in the arena, hands on the kit, pressure simply low.

### The GRAMMAR (fight shapes — Bill's verdict pass, 2026-07-06)
All shapes are INTRA-battle (zero menu time) and Single-Target-Law-clean (one telegraph
stream, always — packs are strictly sequential):
1. **PACK — KEPT, the primary shape** — 1–4 enemies fought sequentially in ONE battle:
   two smalls + a captain = a medium fight; 3–4 smalls = a gauntlet; one long duel.
   2–3s walk-in breathers between members (the diegetic valley). **Heat carries:**
   per-class combo state (Flow / vials / rig charge) persists across the pack — the
   payoff Bill's missing ("combo comes online" and STAYS online); each rework defines
   its pack-carry rule like it defines its PERFECT payoff. Forge assembles packs from
   BODY archetypes (SWARM smalls → BRUTE captain).
2. **THE CHASE — PARKED (Bill, 2026-07-07: "not sure i like, pressure to do one thing
   or another is meh, lets leave it open")** — the multi-arena running battle sits on
   the shelf with the design intact; revisit only if a zone's fiction begs for it.
3. **INTERLUDE WAVES — KEPT (lukewarm)** — the boss withdraws, light adds cycle through
   (proven Seal tech): an intensity valley that stays active. Use sparingly.

**CUT (Bill's verdict pass — do not resurrect casually):**
- **Verse/chorus phase grammar** — illegible as a concept ("i don't really get it");
  the *instinct* (escalating authored pressure + punish windows) survives informally in
  how Seals are already authored, but it is not a named system.
- **REPRIEVE phase-pause + THE DENY** — a pause with jobs is MORE stress, not less; a
  hard-stop pause has no flow-preserving mechanism (see Law 3). Never pause a battle.
- **SIDE-DUEL / AURA-ADD** — "very anti fun stuff," ditched for now (the Manastorm
  aura-add steal goes back on the shelf).

### Length bands — ✅ BASELINE BAKED ×2.5 (Bill: "merge this into the main", 2026-07-07,
### `7d740fe`) — the LONG FIGHTS scalar became the authored numbers (one launcher again).
All 4 Seals + 3 skirmishes: HP + enrage ×2.5 in `raid_content.gd`; `--fightlen` survives
as a dev knob RELATIVE to the new baseline; gate exams (class-content 1v1s) deliberately
stay authored-short — snappy exams, Bill can veto. **New raid bands @60 seeds:** riftmaw
100/97/77 · mistral 100/100/100 · gemini 100/87/10 · mythos 100/83/0 — expert holds
everywhere, good pays a fair tax on deep Seals, sloppy craters on Ring 2/0: the skill
spread widening is the DESIGN GOAL working; the **healer regen/mana retune is the
good-tier lever** if playtests want deep Seals kinder. Original targets (zone skirmish
60–90s · pack/elite 2–4 min · capstone 4–6 min · dungeon Seal 5–8 min · raid Seal 8–12
min · world boss 5–10 min) now read against the baked baseline; the zone spine stays
skirmish-weight so route-to-door holds the 30–45 min attunement budget.

**How shapes are ASSIGNED (locked 2026-07-07, Bill's "how do they get decided?"):**
authored in the permanence layer, seeded-within-quotas in the variance layer, always
authored for named bosses. Concretely: **zone nodes** carry their shape by hand (the
Granary Steps IS a pack-with-captain; the cave IS a gauntlet; a chase is a set-piece
node) — the Forge's seed only varies which BODIES fill the slots from the zone palette,
never the shape; **Topology floors** roll shapes from the run seed inside authored
quotas (the RunMap quota-bag idiom: "mids draw from {pack-2, pack-3, duel} weighted") —
deterministic per seed, varied across runs; **Seals / capstones / world bosses** are
hand-built, never rolled.

**Sequencing:** Bill feel-tests raw length FIRST (the `--fightlen=` dev scalar — global
HP/enrage multiplier, byte-identical absent — VERDICT 2026-07-07: "much better") ; the
grammar then lands with W2 (the Forge gets a SHAPE axis: pack/duel/gauntlet) + the boss
PILLAR PASS (Seals retuned onto packs/chase shapes + the bands). **The PACK mechanism is
the lead domino** — sequential encounters in one lockstep battle with per-class heat
carry is an engine-adjacent slice (guarded, byte-identical for single fights) that
everything else composes with. Healer regen / mana curves rebalance WITH the bands, not
before (the inert-mana fix rides this).

### PACK — build spec v1 — ✅ BUILT & MERGED 2026-07-07 (`f912a4f`; record in the
### Coordination Log. Shipped exactly as specced below; Granary Steps + Hollow Warren
### author the first packs; Bill feel-tests with `--fightlen` composing on top.)
- **Engine (the guarded touch):** `CombatState.pack: Array[EncounterRes]` + `pack_i`
  (empty = today's single fight, byte-identical). Boss death with members remaining ⇒
  NOT over/won: advance `pack_i`, reset the SAME BossState in place (no stale refs) from
  the next EncounterRes, swap `s.encounter`, stamp `boss.entered_tick`. Win fires only
  on the last corpse; a wipe anytime is a wipe. **Heat carries for free** — same
  CombatState, seats untouched (Flow/vials/rig/cooldowns/HP persist): the whole point.
- **WALK-IN grace** (the diegetic valley): for `pack_walkin_ticks` (TuningConfig, ~75 =
  2.5s) after a swap the new enemy takes no actions (no telegraphs, no melee); players
  MAY act — opening on the approaching enemy is the pull fantasy, and a small free
  window is the breather's reward. One `pack_next` event for HUD juice.
- **Per-member enrage:** `BossState.entered_tick` (default 0 ⇒ identical math for
  singles) — the enrage clock reads time-since-entry, so member 3 doesn't arrive
  pre-enraged. Phases stay HP-fraction (reset with the in-place boss reset).
- **Spec plumbing:** `make_spec(..., pack=[ids])` → `spec["pack"]` (absent/size<2 =
  plain fight, normalized away); `RaidNet.build`/`RaidContent.make_state` resolve the
  list. Pure data ⇒ rides `(seed, spec)` — lockstep/replay-safe by construction; online
  untouched v1 (no protocol bump — the field is additive and unsent).
- **HUD:** on `pack_next` — boss plate rebinds, BossIntro card for the next member,
  "▸ NEXT" toast. The SLAIN kill-moment fires only at fight end (engine `over` is truth).
- **Authoring (feel content):** Gildfields THE GRANARY STEPS = smalls→captain pack
  (bard·sonnet·opus), THE HOLLOW WARREN = gauntlet (bard·sonnet·bard); Pale Tiller stays
  a duel. `--fightlen` scales every member (and each member's enrage) so the scalar
  and packs compose. ⚠ v1 packs reuse full-HP skirmish bodies — total pool runs Seal-
  sized; the Forge's SWARM bodies later mint proper lightweights (feel-test knob: author
  fewer members before shrinking bodies).
- **Gates:** new `pack_probe` (determinism ×2 · win-after-last · walk-in silence ·
  member-2 enrage clock · size-1 normalizes to plain) · frozen-main A/B psim twinfang(120)
  + raid(60) byte-identical (engine touch!) · net_smoke (checksums) · raid/world/map/menu
  smokes · fightlen_probe both modes.

---

## PROGRESSION RECONCILIATION (what the world changes — and deliberately doesn't)

- **The WORLD track becomes literal.** PROGRESSION-PLAN track #1 gets its UI: the Atlas
  IS the World track. Fog lifted, zones crested, flight network grown, doors unlocked —
  access rendered as geography. No new currencies, no new grind: the world *visualizes*
  unlocks, it never mints them.
- **Law #1 fully intact:** zone/quest/event rewards are access / pool rows / standing.
  Numbers still die with the run; the run still lives behind instance doors.
- **LEVELS (locked 2026-07-06 — full spec in PROGRESSION-PLAN §LEVELS):** the unlock
  rollout becomes a WoW-shaped journey — milestones unlock SYSTEMS (zone crests → Modules/
  Creeds/rig/curio slots), event-XP levels pace each class's boon pool in waves; levels =
  options, never stats. **Zone gating: the campaign spine hard-gates by CREST**
  (attunement-style, Zone N's crest opens Zone N+1); each zone keeps 1–2 open over-tier
  **BORDERLAND** nodes as the high-level tease (Forge TIER wall, standing rewards only).
- **The Ledger lives in the hometown.** Standing (crests, versions, depth records) gets
  its physical home; the lobby-crest social layer points there.
- **Saves:** world state (fog/nodes/quests/flight/attunements) = a versioned local save
  (`user://rift_world.cfg` idiom, JSON, schema-versioned like `rift_net.cfg`), per
  character slot. Server accounts stay FUTURE (needed for cross-machine + verified
  standing; local-first is correct until then — same posture as gear/prior cfgs).

## ONLINE RECONCILIATION (reuse, then extend)

- **Co-op zone traversal = MAP-3b reused with persistent semantics:** server owns the
  live zone session, leader routes, fights are lockstep rooms, node results write back
  to every member's world save (credit rule above). New lobby-layer verbs (zone enter /
  state / node result) — additive protocol bump, combat frames untouched.
- **W4 presence** = zone rooms (roster/chat/pins) + event scheduler + event lobbies.
- **Mid-fight join: PARKED** (§PARKED). World events v1 don't need it.

---

## CONTENT v1 — the vertical slice (names TBD with Bill)

- **THE BASTION** (hometown hub).
- **ZONE 1 — "our Westfall"** (working name: **THE GILDFIELDS** — renamed from "Mirefen"
  2026-07-06 per Bill's Westfall steer; BUILT in W1): teaching zone. **~20
  nodes** (sizing formula in §ZONE QUESTS & DYNAMICS): a ~9-node spine (entry fight →
  Forge skirmishes → 1 ELITE mutator fight → event → quest camp → capstone named boss →
  waystation), cave side-chain w/ named miniboss ↔ direct-route fork, marsh side-chain
  (event + elite + cache), quest chain (3–4 tickets incl. 1 door ticket), 1 personal
  gate, 2–3 ZONE REMEMBERS choice moments, **DUNGEON DOOR** on the east edge.
- **DUNGEON 1 — "our Deadmines"**: 1-floor Topology, ~6–8 nodes, Forge skirmishes +
  1 recast mid-roster boss as its Seal, Versions dial at the door.
- **THE RAID DOOR — Realm 1: The Takeover**, the existing 3-Ring descent verbatim,
  standing at the region's far end as the capstone.
- **WORLD EVENT — VORATHEK, the Riftmaw**, wandering the region (W4; offline cadence too).
- Casting pool feeds everything: 15 solo bosses + Seal adds — recast, never rebuilt.

---

## CONVERSION PHASES (each mergeable alone; classic front door survives until W3)

- **W0 — FRESH SLATE (docs, this claim):** this plan + MASTER-PLAN §WORLD + pillar locks
  recorded. Companion cleanup claim: CLAUDE.md slims to laws/run-book (frozen milestone
  history → `HISTORY.md`), stale class notes marked pre-rework, Voidcaller-cut recorded.
- **W1 — THE ATLAS + ZONE 1 (offline, feature-flagged) — ✅ DONE, merged 2026-07-06
  (`b9c26aa`; full record in MASTER-PLAN's Coordination Log).** Shipped as designed plus
  Bill's steers: Zone 1 = **THE GILDFIELDS** (Westfall-inspired working name — the zone's
  mystery funnels into the UNDERMILL dungeon door), 20 authored nodes on a NEW ZoneScreen
  (not MapScreen — worn roads / fog / frontier, the earnest world look), THE SLUICE zone-
  remembers teaser live, Bastion hub v1 (Warband Camp = Commander re-doored), Atlas with
  the raid door as a place. Acceptance met: save round-trip determinism (`world_probe`),
  bare-kit stand-in fights via the shared factory (sims byte-identical vs frozen main),
  `ui_smoke_world` + WSLg tour. Deferred to W2: Forge fights, TICKETS v2 pass, real names.
- **W2 — THE FORGE:** generator + `forge_sim` certification harness + Zone 1 content
  pass (replace stand-ins with Forge skirmishes + 1 authored capstone + gate + quests).
  Acceptance: the Forge bar (bands per tier, zero unwinnable, determinism).
- **W3 — DOORS + FRONT-DOOR FLIP:** Dungeon 1 (1-floor Topology behind the door,
  Versions dial); raid door wired to the existing descent; attunement rule (route-based);
  **PLAY → ATLAS becomes the front door** (GAME SHAPE amended: still one game, the Atlas
  is the menu); zone-cleared crests on the character sheet. Acceptance: full loop
  playable offline — bastion → zone conquest → dungeon runs → raid descent; all sims
  green; the old realm-card flow removed.
- **W4 — THE LIVING WORLD (online):** co-op zone traversal (persistent write-back,
  least-progressed frontier binding); zone presence rooms (roster/chat/pins); world
  events v1 (scheduler + Atlas banner + open lobby + parallel rooms; offline cadence
  parity). Protocol bump; net smokes extended (2-client zone clear write-back, event
  lobby fire, zero desyncs).
- **W5 — BREADTH + RETUNE:** Zone 2 + Dungeon 2; event pool growth; Seal kick-chains
  retuned for interrupt-by-ability (with the rework classes as they land); dodge-ration
  audit across the boss roster (beat budgets per tier); Module-timing generalization
  lands with the raid retune.
- **LATER / gated on demand:** server accounts + cross-machine saves; mid-fight join;
  bigger raid brackets; party-vote routing; PATROL repeatables; mounts/cosmetic travel.

**Standing acceptance bar (every phase):** CombatCore untouched (or guarded byte-identical
where flagged); Twinfang sim (the active rework spine) + raid smoke green; map/world save
determinism; UI smokes; WSLg visual probe for any new screen.

---

## PARKED (recorded so we don't re-derive them)

- **Mid-fight join (the "join any time" fantasy):** join = claim an AI seat (mirror of
  the existing disconnect→AI-takeover) + catch up by deterministic replay of the tick-
  stamped input log from `(seed, spec)` — feasible on this engine, real work, not needed
  for v1 events. Revisit after W4 ships and event feel is known.
- **PATROL nodes** (opt-in repeatable overworld skirmishes paying salvage) — only if
  playtests demand an overworld grind valve; risks polluting the permanence layer.
- **Raid brackets >4** (5–8 seat raids with per-bracket Forge tuning) — after the
  4-seat world is proven.
- **RAID RITES (Bill, 2026-07-06):** recurring mandatory entry nodes at the raid door —
  something hard you re-do EVERY descent, upping the barrier so raids stay a big deal.
  Design later (post-Zone-1, "this is 1st zone"); interacts with descent save/resume
  (§OPEN #6).
- **Seat-claim spectate / live gate spectate**, party-vote routing — existing parks, unchanged.

## OPEN DECISIONS (small, for Bill, none blocking W1)

1. Zone maps authored (recommended, assumed above) vs seeded-per-player — confirm.
2. Names: the world/region, THE BASTION, THE MIREFEN, Dungeon 1, the game title itself
   (the parking-lot candidates read Realm-1-flavored; the world wants a realm-neutral title).
3. Dodge beat budget numbers per tier (start 3–8/fight non-tank; tune in W5 audit).
4. Which Tempo ability carries `interrupts` (lands in TEMPO-PLAN §10 content picks).
5. Event cadence + event-table recurrence rule specifics (the no-FOMO law's numbers).
6. ✅ **RESOLVED 2026-07-09** (§INSTANCES "THE STAKES MODEL"): raids **checkpoint between
   floors** + a finite **wipe budget**; the save/resume plumbing = the descent-checkpoint build
   item. Dungeon stays lean (1 life + optional attempt-token buy-in).
7. Second Module slot at Ring 1/0 for long raids (TEMPO-PLAN, at the raid retune).
