# PROGRESSION-PLAN — the persistent meta-game (decisions of record)

**Purpose:** locked design from the progression design session with Bill (2026-07-02/03).
This doc owns everything PERSISTENT (unlocks, loot tables, oaths, standing). The in-run draft
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
| **Expedition 33** | deed-gated gear rows (its graded parry/dodge combat is already our core) | sworn oaths *(E33's use-based Picto mastery was considered and CUT — passive, no moment)* |
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
   construction: Realm 2 is new bosses/tables/oaths, never a higher item level.
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

> **Content:** the concrete Realm-1 item + oath designs (per-boss Ledger pages, hooks, tags,
> combos, drop-weight scaling table) live in **`GEAR-CATALOG.md`** (authored 2026-07-03
> against the class-fun reworks). This section stays the system spec.

### Ledger pages — the permanent layer
- Every boss owns a page: a **4–6 row loot table**, all rows visible from the start (locked
  rows greyed), each row = item + **printed rarity** (Haiku/Sonnet/Opus — rarity is a fixed
  property of the item, never itself unlocked) + the deed that opens it.
- Row kinds: **SIGNATURE** (first kill — guaranteed unlock, and that kill's drop ceremony);
  **OATH** rows (sworn deeds, below); **VERSION** rows (Trial-Ladder kills; version+oath
  combos are the chase rows).
- **NAMING (2026-07-03, replaces "feats"/"armed quests" — "quest" belongs to the map's
  TICKETS):** the boss-page deed is an **OATH**. Arming = **SWEARING** it at the boss node;
  resolution = **OATH KEPT / OATH BROKEN** (one-word verdict pops). Arm-with-cost deep rows
  = **BLOOD OATHS** (the oath itself imposes the handicap: "win with Guard sealed").
  Realm-1 display skin (display-fields only, ids stay `oath_*`): oaths render as **SLAs**
  ("SLA SIGNED" / "SLA MET" / "SLA BREACHED — penalty clauses waived"), Blood Oaths as a
  **PIP — Performance Improvement Plan**. Rejected: Contracts (that register IS the Realm-1
  skin, keep it there), Bounties (names the boss, not the deed), Gambits/Wagers (imply a
  stake only Blood Oaths have).
- **Oaths are SWORN (Bill's call, locked — was "armed"):** at the boss node / fight start you
  select one oath to swear → in-fight progress tracker + callout → completes **only when
  sworn**. No accidental unlocks. (Serendipity variant = one gate on the same detector; kept
  as a playtest knob only.) Oath detectors read `seat.diag`/events — deterministic, per-seat.
  One sworn oath per seat per fight (open Q resolved 2026-07-03 — the tracker/callout UI and
  the payout math assume one).
- **Oath severity & difficulty scaling (2026-07-03, Bill's ask — "scale with difficulty for
  reward"):** every oath row carries a printed **severity I / II / III** matched to its row
  rarity (Haiku / Sonnet / Opus). Three scaling mechanisms, all seeded/deterministic:
  1. **Severity = deed difficulty.** Sev-I deeds are teaching-tier ("no missed kicks this
     fight"); Sev-II demand a clean read discipline ("zero BAITED, ≥6 PERFECTs"); Sev-III are
     version-gated (v2+/v3+) or Blood Oaths — the deed often only *exists* where the added
     mechanic does ("keep it through v2's added feint verse"). Reward scales because the deed
     is only performable where the difficulty is.
  2. **Re-swearing is the endgame loop.** An oath whose row is already unlocked stays
     swearable forever for an **in-run purse**: OATH KEPT pays Tokens + bends that kill's
     drop roll (see table). Permanent unlock once; replayable fortune forever.
  3. **The purse scales with STAKES** = ring depth + boss version:
     `stakes = (3 − ring) + (version − 1)` (Ring 3 v1 → 0 · Ring 0 v1 → 3 · Ring 0 v3 → 5).
     | Severity | Tokens on KEPT | Drop-roll bend on that kill |
     |---|---|---|
     | I | 1 + stakes/2 (floor) | +2 pity ticks |
     | II | 2 + stakes | rarity floor = Sonnet |
     | III / Blood | 3 + stakes | rarity floor = Sonnet; **guaranteed Opus at stakes ≥ 2** |
     (Starting values — knobs on `TuningConfig`, sims tune.) Purses are strictly additive
     and only exist at unlock-live surfaces (PROVING GROUNDS stays inert), so the Monotonic
     Pool Law holds and sandbagging is never correct. OATH BROKEN costs nothing (Blood Oaths
     excepted — their cost was paid in the handicap, still no post-fight penalty).
- **Where tables live (raid-only amendment, 2026-07-03):** a boss's table attaches to it
  **wherever it appears** — Seal fight, personal GATE node, owned add, split phase; a gate
  clear is a kill, and the gate is the natural oath-swearing stage (you're alone; it's your
  exam). **PROVING GROUNDS practice fights are unlock-inert** (no drops/oaths/Proofs) —
  otherwise practice becomes the farm and the campaign hollows.

### Drops — the in-run layer
- **Drops are EVENTS (ARMORY amendment, Bill 2026-07-03 — playtest verdict: a drop after
  every fight killed the moment).** A roll fires only at: **Seal kills**, **gate exams**,
  and **any kill whose SIGNATURE row is still locked** (preserves the StS first-kill
  shower). Repeat skirmish kills pay ring-scaled **salvage Tokens** (1⏣/2⏣/3⏣ at Ring
  3/2/0) with a toast, no ceremony. Scarcity is what makes the ceremony land; weights are
  retuned richer to match (~4–6 rolls/descent → each pays more; table in GEAR-CATALOG).
- **Signature philosophy (ARMORY, replaces the all-Haiku "taste rows"):** the first-kill
  SIGNATURE is the boss's *iconic strong piece* — feel-it-immediately, printed Sonnet for
  the combat six. Oath/version rows are the refinement and chase. First kills feel awesome.
- On boss kill, **two-step roll**: (1) rarity first — base weights bent by
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

#### ✅ CURIO ECONOMY v2 — amendment (Bill, 2026-07-05, from the Tempo-pilot curio pass)
Playtest-derived fixes to the drop feel ("I unlock cool things then only get a small drop chance,
and drops land too late — 2nd + last Seal, and the final drop is wasted post-kill"):
- **The MARKET is the PRIMARY, reliable path; rare drops become the JACKPOT bonus.** Reframe of
  record: **unlocking a curio adds it to your MARKET inventory** (a rotating offer drawn from your
  unlocked pool) — so an unlock is something you can *pursue* (earn Tokens → buy it), not a lottery
  ticket. The event-drop stays as the exciting cherry on top. This dissolves the "unlock → rarely
  see it" frustration without a pre-run loadout (the Market offer is a rotating random subset, bought
  MID-RUN with Tokens earned mid-run — you steer a hand, never pre-assemble one).
- **Markets appear from Floor 1, several per run** (pacing fix — curios come online early enough to
  matter). Map-gen quota should guarantee ≥1 Market per floor from Ring 3.
- **The final Seal pays META, not an in-run curio** (fixes the wasted post-kill drop): level/unlock
  progress + a carry-out reward for the *next* run. Skill at the finale → long-term power, not a dead drop.
- **Reroll = a BANKED consumable bought at the Market** (Bill): buy a reroll charge with Tokens, hold
  it, spend it on ANY later draft until used. This MOVES reroll off the draft-screen Token button and
  becomes the natural cap on build-control ("steer, don't solve" — you reroll as many times as you
  bought, never infinitely). Tokens' spend = curios · reroll charges · wound repair · occasional boon.
- **Curio CONTENT direction (Tempo pilot, cross-spec):** curios are the *fortune/run-shaping* layer,
  **cross-spec** (never touch Flow/window/strike-hook/Marks — those are Creed/Module/rig territory).
  Led by **DRAFT-SHAPERS** (A/B Test = +1 draft option · Version Control = bank a passed boon ·
  Hotfix = 2 boons from one draft · Merge Conflict = swap a boon at a Seal) as the rare exciting core,
  with modest **survival / capped-gamble / small ability-charm / anti-heal-strat** spice. **Passive
  pets/drones CUT** (meh without skill → that's a future Hunter class). See [[combat-upgrade-load]] +
  the curio design pass. The verb-touching offenders (Encore Bell / Grace Period / Le Chat / Second
  Opinion / Powder Vial) get cut/reworked per TEMPO-PLAN's lane rule.

### What gear IS (design space per lane discipline)
Procs tied to verbs ("after a perfect parry, next Guard is instant"), **actives with charges**
(a new button — huge in a one-verb game; e.g. consume to clear a wound), **set pairs** (the
one inventory tension 2 slots can hold — keep a weaker piece to complete the pair), and
map/economy utility (shop prices, 401 doors, cache reveals). Never raw verb %.

### THE ARMOR SET — the presentation layer (ARMORY, Bill 2026-07-03)
The run-build reads as GEARING UP, not "stacking imaginary things": a paper-doll **YOUR
SET** panel (`game/ui/armor_doll.gd`) renders every drafted boon as a PIECE forged into
one of five armor slots — **WEAPON** (your output; heal throughput for healers) ·
**HELM** (the resource engine) · **CUIRASS** (survival/wards/guard) · **GAUNTLETS** (the
class mechanic in hand) · **GREAVES** (footwork/beats) — plus the two curio equip slots
as **TRINKET** sockets. A slot's piece = its family's boon **count** (+N badge) and
**best-rarity** frame glow; hover lists the pieces. **Presentation ONLY**: the draft
economy is untouched (Hades stacking, no slot caps — pieces upgrade, never limit), the
lane law survives as *boons forge armor, drops socket trinkets*. Mapping: explicit
id→slot table in `data/armor_slots.gd` (+ tag fallback for future boons); DraftScreen
cards carry a "⚒ SLOT" forge chip; taking a pick toasts "⚒ SLOT REFORGED — piece N".
Shown on the descent map (bottom-left), beside the REFORGE draft, and grouped in the
combat build panel. *(Considered and deferred: capped slots w/ replacement (kills Hades
stacking), Need/Greed shared rolls vs the AI raid at Seals — the "B2/roll" halves of the
armory design; revisit after this cadence ships feel.)*

## Standing — make growth visible (and *seen*)

- **Character sheet per class:** Proof crest, deepest Ring, best boss versions, oaths kept,
  table completion. One gorgeous screen, Gilded Reliquary language.
- **Raid lobby crests/titles:** claiming a seat shows your standing (Mythos-slayer mark,
  Depth badge, no-bait Duelist title). Cosmetic, social, zero balance surface — the co-op
  lobby does the job WoW's Ironforge did. Realm-1 skin: verified badges, player "versions".
- **The Ledger is the atlas** of all four tracks — per-boss pages, per-class Proofs, the
  realm map filling in. The save file made beautiful. (A hub screen housing it = open Q.)

## Pacing / early game

First kills across the campaign roster = the StS front-loaded wave — 4 Seals + skirmish
minibosses + the 15 exam bosses arriving as GATE nodes / owned adds (MASTER-PLAN §GAME SHAPE)
— every early run ends in guaranteed unlocks, **no separate milestone system needed**. Oaths
and versions carry the long tail. Nothing is timed, ever; the core loop must stand alone
(Bill, locked).

## Cut list (decided — do not resurrect casually)

- **Material economy + crafting** (essences/reagents/Embers/Riftcores, Foundry/cauldron) —
  CUT. Raid exclusivity is preserved structurally instead: raid bosses own tables that drop
  nowhere else, and Seal oaths/versions gate their deep rows.
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
- Slots exactly 2? Set-pair depth (pairs only, or 3-piece realm sets)?
  *(Gear noun resolved 2026-07-03 with GEAR-1: **CURIO** global / **PERIPHERAL** Realm-1 skin.)*
- Shard pity for extraction. Serendipity knob. *(Arm limit resolved 2026-07-03: one sworn oath per seat per fight.)*
- Altar/sacrifice rare map event (trade equipped item now → awakened row forever) — spice.
- Hub screen for Ledger/character sheet; where standing lives before accounts exist
  (R2 "accounts" line is still future).

## Sequencing & dependencies

0. **The substrate is already merged** (Draft 2.0 + slot-verbs + Tokens, 2026-07-02 — rarity/
   pity/synergy tags/Token mint+spends live in `game/draft.gd`) — gear REUSES that machinery,
   never forks it. GEAR-1 is claimable immediately.
1. **GEAR-1 — ✅ DONE, merged 2026-07-03 (`866592f`; record in MASTER-PLAN Coordination Log):**
   9 signature items live on the raid campaign (Ring-3 roster + gate exams), first-kill unlock →
   `user://rift_gear.cfg`, drop ceremony (EQUIP/REPLACE/SCRAP→⏣, 2-slot cap, dupes auto-scrap),
   curios armed on the human seat, `sim/gear_probe.gd` + byte-identical gearless gate.
   v1 caveats: OFFLINE raid-map only (fold `gear` into the online campaign spec later);
   scrap Tokens BANK only until MARKET (GEAR-3). **Item designs: `GEAR-CATALOG.md` §Rollout GEAR-1.**
2. **GEAR-2 — ✅ DONE, merged 2026-07-03 (`8d18685`; record in MASTER-PLAN Coordination Log):**
   sworn oaths live on the raid campaign — Ledger offer screen, deed detectors (`game/oaths.gd`,
   diag/vars only), in-fight tracker w/ live BROKEN, KEPT = row unlocks into that kill's pool +
   stakes purse; rarity-first drop roll (ring weights/pity/bends); 7 oath-row curios.
   **Oath rows + v1 deed notes: `GEAR-CATALOG.md`.**
3. **GEAR-3:** MARKET gear stock + extraction schematics (map layer).
4. **GEAR-4:** raid personal loot + Seal tables; crests/standing later (needs accounts).

**Acceptance bar (every phase):** all class sims **byte-identical with gear absent**; drop &
oath determinism PASS; UI smokes green; Monotonic Pool Law spot-check (expected value
non-decreasing in pool size).
