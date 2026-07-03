# PROGRESSION-PLAN — the persistent meta-game (decisions of record)

**Purpose:** locked design from the progression design session with Bill (2026-07-02/03).
This doc owns everything PERSISTENT (unlocks, loot tables, feats, standing). The in-run draft
economy stays owned by `ASCENSION-STEAL-PLAN.md` / MASTER-PLAN §SYSTEMS (draft2 branch).
**Supersedes** the orphaned economy vocabulary in `RAID-PLAN.md` (essences / reagents /
Embers / Sigils / Riftcores / the Foundry) — that material economy is **CUT**, see Cut List.

**Thesis: skill is the character level.** In an execution game the player genuinely gets
stronger with hours played. The meta layer's job is to make that growth *legible and visible* —
never to sell power. Numbers die with the run; permanence buys **options and access**.

---

## Influences — one steal per game (the mix Bill asked for)

| Game | The one steal | Lands as |
|---|---|---|
| **WoW** | the loot *moment* (named drops, rarity colors, trinket procs, set pieces) + attunement-as-access | boss loot tables; Proofs gate Seals/realms; lobby crests |
| **Slay the Spire** | front-loaded, meaty, FINITE unlocks — then the game is the game | the first-kill shower (falls out of roster size, no extra system) |
| **Across the Obelisk** | gear bought at in-run shops; gear that grants *actives* (a new button) | MARKET nodes stock gear for Tokens; actives-with-charges |
| **Expedition 33** | quest-gated gear rows (its graded parry/dodge combat is already our core) | armed feats *(E33's use-based Picto mastery was considered and CUT — passive, no moment)* |
| **Hades** | only what's already built (aspects, the boon draft) | **no** cauldron, **no** materials, **no** incantation hub |

## Laws (non-negotiable)

1. **Numbers die with the run.** No persistent stats, levels, or gear power. Persistent
   rewards are always options (pool growth), access (Proofs), or standing (cosmetic/social).
2. **Monotonic Pool Law — an unlock must never make any future run worse.** Enforced by:
   rarity-first drop rolls (quality cadence is pity-driven, independent of pool size),
   synergy-weighted in-rarity picks, and a token floor on every roll (dupes + auto-scrap).
   Sandbagging (playing worse to avoid an unlock) must never be correct. Spot-assert in sims:
   expected run value non-decreasing in pool size.
3. **Lane discipline.** Boons (the draft) own the verb: +%, verb mods, *agency* (choice-of-3).
   Gear owns *fortune + new buttons*: procs, actives-with-charges, set pairs, map/economy
   utility. An effect that reads "+X% to your verb" is a boon, never gear.
4. **Forbidden:** crafting hubs, meta currencies, pre-run loadouts (aspect pick is the ONLY
   pre-run choice), timed content (daily/weekly), use-based mastery, pool opt-out.
5. **Everything rides the fight spec.** Persistent state that touches combat enters as pure
   data in `(seed, spec)` — exactly like aspects — so lockstep, checksums, AI-takeover, and
   headless sims stay correct. Drop rolls are seeded; raids use per-seat personal loot.
6. **Sim dimensionality:** combat-touching gear pools stay SMALL and per-class (the
   ASCENSION scoping rule). Volume lives in utility/map gear the balance sims never see.

## The four persistent tracks

1. **WORLD (the campaign spine).** Realm 1 = the Ring descent (3→0); each Seal kill is a
   Privilege Elevation; Proofs (demonstrated execution, seed-verifiable) gate Rings and
   realms — access, never stats. Realms are the expansion cadence and are horizontal by
   construction: Realm 2 is new bosses/tables/feats, never a higher item level.
2. **POOLS (the gear game, below).** Defeat / Perform / Extract grow per-class boon, gear,
   and event pools. Hour-40 runs are *richer* than hour-5 runs, not easier.
3. **RANK (the endgame).** Trial Ladder versions per boss + Depth on raids. Your best
   version/Depth record IS your gear score — earnable only with reads, verifiable by seed.
4. **BREADTH (the roster).** Five classes × two aspects. **Proof = clearing your class's
   personal exams in the campaign** (Tier-1 GATE duels / designated exam encounters — amended
   2026-07-03 per MASTER-PLAN §GAME SHAPE; was "solo gauntlet" pre-raid-only lock). The Proof
   is **standing, never an entry gate** — a friend joining a lobby is never sent away to solo
   first (AI-assist makes any seat playable; the crest shows who's proven).
   A fresh class re-runs the first-kill unlock shower.

## The gear game (full spec)

### Ledger pages — the permanent layer
- Every boss owns a page: a **4–6 row loot table**, all rows visible from the start (locked
  rows greyed), each row = item + **printed rarity** (Haiku/Sonnet/Opus — rarity is a fixed
  property of the item, never itself unlocked) + the deed that opens it.
- Row kinds: **SIGNATURE** (first kill — guaranteed unlock, and that kill's drop ceremony);
  **FEAT** rows (armed quests, below); **VERSION** rows (Trial-Ladder kills; version+feat
  combos are the chase rows).
- **Feats are ARMED (Bill's call, locked):** at the boss node / fight start you select one
  feat to arm → in-fight progress tracker + callout → completes **only when armed**. No
  accidental unlocks. (Serendipity variant = one gate on the same detector; kept as a
  playtest knob only.) Feat detectors read `seat.diag`/events — deterministic, per-seat.
  Deep rows may be arm-only *with a cost* later ("win with Guard sealed") = challenge-run
  content without a separate mode.
- **Where tables live (raid-only amendment, 2026-07-03):** a boss's table attaches to it
  **wherever it appears** — Seal fight, personal GATE node, owned add, split phase; a gate
  clear is a kill, and the gate is the natural feat-arming stage (you're alone; it's your
  exam). **PROVING GROUNDS practice fights are unlock-inert** (no drops/feats/Proofs) —
  otherwise practice becomes the farm and the campaign hollows.

### Drops — the in-run layer
- On boss kill, **two-step roll**: (1) rarity first — base weights (e.g. 70/25/5) bent by
  **pity** (per-run Opus counter; dry rolls bump, eventually guarantee) and **depth/version**
  (boss 5 / v3 rolls richer); (2) item among that boss's unlocked rows *of that rarity*,
  weighted by draft2 **synergy tags** toward the current build. If the boss has no unlocked
  row at the rolled tier, clamp to his best; the pity counter persists to the next boss.
- Player decision per drop: **EQUIP** (2 slots total — hard cap) or **SCRAP → Tokens**.
  Dupes of equipped items auto-scrap. Per-item **auto-scrap flag** in the Ledger (QoL):
  the item stays in the pool at FULL odds but arrives as Tokens without ceremony —
  comfort without the min-pool exploit (this is why pool opt-out/shelving is forbidden).
- **MARKET is the choice lane** (AtO): nodes stock 2–3 pieces from the realm's unlocked pool,
  priced in Tokens → the scrap→buy loop self-corrects bad luck without handouts.
- **Extraction (non-boss gear):** utility/map "schematics" found at CACHE / secret room /
  elite nodes; usable immediately in-run; **banked permanently only if you reach the floor's
  Seal alive**. Global progression inside the run's stakes. (Shard pity on wipe = open Q.)
- **Raids:** personal loot per seat, rolled from the run seed — lockstep-safe, replay-verifiable.
- Fallback knob if pure rolls whiff in playtests: roll-2-keep-1. Ship pure first.
- Gear is run-scoped, ALWAYS: win or wipe, items evaporate; unlocks and banked schematics remain.

### What gear IS (design space per lane discipline)
Procs tied to verbs ("after a perfect parry, next Guard is instant"), **actives with charges**
(a new button — huge in a one-verb game; e.g. consume to clear a wound), **set pairs** (the
one inventory tension 2 slots can hold — keep a weaker piece to complete the pair), and
map/economy utility (shop prices, 401 doors, cache reveals). Never raw verb %.

## Standing — make growth visible (and *seen*)

- **Character sheet per class:** Proof crest, deepest Ring, best boss versions, feats done,
  table completion. One gorgeous screen, Gilded Reliquary language.
- **Raid lobby crests/titles:** claiming a seat shows your standing (Mythos-slayer mark,
  Depth badge, no-bait Duelist title). Cosmetic, social, zero balance surface — the co-op
  lobby does the job WoW's Ironforge did. Realm-1 skin: verified badges, player "versions".
- **The Ledger is the atlas** of all four tracks — per-boss pages, per-class Proofs, the
  realm map filling in. The save file made beautiful. (A hub screen housing it = open Q.)

## Pacing / early game

First kills across the campaign roster = the StS front-loaded wave — 4 Seals + skirmish
minibosses + the 15 exam bosses arriving as GATE nodes / owned adds (MASTER-PLAN §GAME SHAPE)
— every early run ends in guaranteed unlocks, **no separate milestone system needed**. Feats
and versions carry the long tail. Nothing is timed, ever; the core loop must stand alone
(Bill, locked).

## Cut list (decided — do not resurrect casually)

- **Material economy + crafting** (essences/reagents/Embers/Riftcores, Foundry/cauldron) —
  CUT. Raid exclusivity is preserved structurally instead: raid bosses own tables that drop
  nowhere else, and Seal feats/versions gate their deep rows.
- **Use-based mastery / Inscription** (E33 Pictos) — CUT: passive bookkeeping, no moment.
  Unlocks must be *events* (defeat / perform / extract), not counters.
- **Pre-run equipped loadouts** and the run-start random sigil offer — CUT.
- **Daily/weekly seeded content** — CUT from core (deterministic-seed leaderboards stay a
  free someday, strictly opt-in).
- **Pool shelving/opt-out** — CUT (min-pool exploit → solved fortune lane); auto-scrap flag instead.
- Hades-style incantation/recipe hub — CUT (system unlocks may still gate on Proofs/Rings,
  but there is no purchase step).

## Open questions

- Checkpoint attunements (once Ring 3 is proven, may start at Ring 2 — Spelunky-shortcut
  tension: faster but leaner draft build-up).
- Slots exactly 2? Set-pair depth (pairs only, or 3-piece realm sets)? Gear noun (avoid
  "relic" — `relic_card.gd` is the boon card).
- Arm limit: one feat per fight vs per run. Shard pity for extraction. Serendipity knob.
- Altar/sacrifice rare map event (trade equipped item now → awakened row forever) — spice.
- Hub screen for Ledger/character sheet; where standing lives before accounts exist
  (R2 "accounts" line is still future).

## Sequencing & dependencies

0. **The substrate is already merged** (Draft 2.0 + slot-verbs + Tokens, 2026-07-02 — rarity/
   pity/synergy tags/Token mint+spends live in `game/draft.gd`) — gear REUSES that machinery,
   never forks it. GEAR-1 is claimable immediately.
1. **GEAR-1 (raid-campaign PoC — retargeted 2026-07-03 per the raid-only lock):** tables for
   the Ring-3 roster (Vorathek, MISTRAL-7B, the skirmish minibosses; ~8–12 items), kill-unlocks
   only, drop ceremony in raid-map mode (reuse `relic_card.gd` visuals), 2 slots per seat,
   scrap→Tokens, save-file unlock store.
2. **GEAR-2:** armed feats (detectors off `seat.diag`) + the Ledger page UI.
3. **GEAR-3:** MARKET gear stock + extraction schematics (map layer).
4. **GEAR-4:** raid personal loot + Seal tables; crests/standing later (needs accounts).

**Acceptance bar (every phase):** all class sims **byte-identical with gear absent**; drop &
feat determinism PASS; UI smokes green; Monotonic Pool Law spot-check (expected value
non-decreasing in pool size).
