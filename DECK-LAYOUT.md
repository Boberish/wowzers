# DECK LAYOUT — the canonical anatomy of a class (Framework v2, consolidated 2026-07-09)

**What this is.** The ONE place that says how a class deck is laid out: the SLOTS a deck
contains, the THREE AXES every card sits on, the CARD-TYPE vocabulary, and the DESIGN RULES that
govern all of it. The **deck-creator skill authors *to* this**; **every class reshape targets
it** (the next phase — Bill, 2026-07-09: "then we relook at classes to reshape stuff").

It consolidates what was scattered: the framework meta-shape (`TEMPO-PLAN.md`), the deck-creator
slots + card-types (`.claude/skills/deck-creator/SKILL.md`), the 7 class-design rules
(`MASTER-PLAN.md`), the tank ladders (`TANK-PLAN.md`), and the 2026-07-09 depth-pass additions
(`TEETH-PLAN.md`: the signature CD, branches, EASE-as-difficulty, the spells reconcile). **Where a
number here differs from an older doc, this doc wins** (the older ones get a pointer).

**The shape in one line:**
> core minigame → a **signature CD** → **Creed** → **Module** → **Boons** (the combo board) →
> **Rig** → **Keystone**, all gated by **Levels** (= your unlock count). Uniform chassis,
> asymmetric content.

---

## PART 1 — THE SLOTS (what a class deck contains)

| Slot | Count | What it is | Law |
|---|---|---|---|
| **Core minigame** | 1 | The class's timing minigame + its **dials** (what a card can touch). Always-on, fun bare. | Skill must move outcomes (Rule #4). Dodge stays the light shared safety. |
| **Signature CD** ⏱ | **1, baseline** | The class's ~1-min big-moment button — every class has one, *un-drafted* (fun bare). One button, not a lane. | **Amplifies skill, never `button = damage`** — pays off setup/timing (line it up with a boss window / your built combo). Varied by class; complements the drafted modules, never duplicates them. |
| **Creeds** | 3–5, **pick 1/run** | A run-long temperament that reshapes the spec's risk. | Curated, never rarity-rolled. Include one forgiving/crossover, one greed pole, one rhythm-changer, and **one WILD creed that rewrites the core mechanic**. |
| **Modules** | 2–3, **Floor-1 pick** | An **add-on to the core minigame** — a supplemental gauge/UI dynamic that layers a *new way to play on top of* the base loop (which stays fully playable without it). | A module must EARN its pixels — a passive with no new UI gets cut. **No transformer requirement** (dropped 2026-07-09, Bill): a module can be a steady supplement, a build engine, or *optionally* a fill→unleash→reset gauge — pick whatever adds the most play. Vary the 2–3; don't mandate an archetype. |
| **Boons** | 10–16 | The draftable pool, filed in **dial-lanes** (the address rule). | Every card names the dial it touches. Each lane: ≥1 greed, ≤1 insurance. |
| **Rig** | 2–4 WHENs | The one **WHEN→THEN** wiring — a single legible circuit, wired at first draft, re-wired once at end of Floor 2. | A WHEN must be chooseable/earnable, never a passive roll; rare WHENs pay premium. Does NOT grow within a run. |
| **Keystones** | **pool 2–3 · run 1** | Build-definers: authored 2–3 per spec (~1 per ladder), **acquire 1/run from an ELITE** (1-of-2 pick). | **Spectacle-grade, never a stat** — if it doesn't change how the minigame *looks* in play, it isn't a keystone. Persistently unlocked into the pool via **level + an oath kept**. |
| **Support** | 1 | The party-facing identity card (the **TEAM** type). | Keyed to the spec's core state — *uptime IS the buff*. |
| **Carries** | listed | Cross-spec cards that work verbatim on both specs. | Verify each against the new core mechanic — no "mostly works". |

*(Curios are the only cross-**class** lane and never touch the core mechanic. There is no
"spells" slot — see Part 5.)*

**When each is granted (the run-flow):** between runs, level up → unlock more Creeds / Modules /
keystones into your pools · run start → draft 1-of-3 Creeds + Aspect · after fight 1 → wire the
Rig · every won fight → 1-of-3 boon draft · end of Floor 1 → pick 1 Module · elite nodes → acquire
a keystone (1-of-2) · end of Floor 2 → re-wire the Rig (free). The **signature CD is always
present** (baseline, never granted).

**The post-fight ceremony ORDER (as built — recorded 2026-07-10, closes loop-audit gap C):**
fight ends → campaign writeback (integrity · wounds · healer mana — `CampaignCore`, the one
rulebook) → the sworn **OATH resolves** (KEPT / BROKEN) → **THE RECKONING** (fight recap:
damage ranking + the fight's biggest hit) → the **loot beat** (⏣ mint from skill signals; a
DROP ceremony only at drop *events* — Seal kills / a still-locked SIGNATURE — otherwise
ring-scaled salvage ⏣) → the **1-of-3 boon draft** (REFORGE) → continue (map / floor
elevation / campaign clear). Code truth: `raid_hud._on_end`.

### THE RIG LAW — required, single-circuit, no stacking (locked 2026-07-04 · law-stated 2026-07-09)

Every class deck **ships a Rig** — a class reshape without one isn't done. One system, identical
chassis on every class; only the WHENs/THENs are class-authored:

- **WHENs (2–4+, class-authored)** — earned moments in the class's own minigame (a dead-centre
  strike · a full-bank dump · a correctly-ignored feint). Chooseable/earnable, **never a passive
  roll**. **THENs** are a small class table of modest role-shaped payoffs (bonus damage / resource
  refund / a brief buff / a warband banner).
- **ONE circuit per run.** Wire **1 WHEN → 1 THEN** at the first draft (after fight 1); **re-wire
  once, free, at end of Floor 2**. It never grows mid-run — no second wire, no amplify ladder.
- **The greed-dial payout (the balancer).** A THEN's magnitude is **computed** from the WHEN it's
  plugged into (`base × mult`), `mult` ≈ inverse-frequency × a rarity premium. A can't-miss WHEN
  pays a steady hum; a rare WHEN pays a spike — **collectible only if you actually land it**. No
  pairing rules; the wiring board shows the number before you commit. (Built reference:
  `data/twinfang/twinfang_rig.gd` — one lookup table, not combinatorics.)
- **Power budget = SIDE BOOST** — ~10% of the class's own output (~4% TTK). A flavour layer that
  reads as one sentence (*"WHEN I land a Riff → THEN the boss bleeds"*), never a pillar.
- **⚠ NO STACKING — cut 2026-07-04, never resurrect.** The old stackable model (a board of pieces,
  any WHEN fires every THEN) re-created the trickle and produced Bill's exact complaint —
  *"side-effect damage is killing the boss and I don't know why."* The only banking allowed is
  **inside one THEN, small and capped** (Killing Edge banks crit charges cap 3; Overcharge takes
  the max, never adds). A boon may double a rig fire (Second Opinion) — it may never add a circuit.

---

## PART 2 — THE THREE AXES EVERY CARD SITS ON

Every boon has three coordinates. They're **orthogonal — don't conflate them:**

1. **DIAL-LANE — the address (structural).** Which dial of the core mechanic the card touches.
   How boons are **filed** ("every card names its dial" — the address rule). The tank's lanes are
   SWING / STEP / BANK / SPEND.
2. **LADDER / BRANCH — the build (thematic).** Which build *direction* the card feeds. **2–3 per
   spec.** How builds are **themed and named** ("the thorns build"). Soft and mix-friendly: a card
   feeds **≥1** ladder, ladders **cross-feed**, each ladder ends in a keystone. This layer
   **cross-cuts** the dial-lanes.
3. **CARD-TYPE — the descriptor.** A **best-fit tag** from the 6-word vocabulary (Part 4) — a
   reading aid + per-deck coverage checklist, **not a strict taxonomy** (lenses-not-law,
   2026-07-09). The other two axes do the real categorizing; this one has no structural
   consequence.

> *Worked example (tank):* **Deep Pockets** is filed in the **BANK** dial-lane (structural), feeds
> **both** the Headsman and Ironside ladders (thematic — soft membership), and is tagged **STRAT**
> (descriptor). One card, three coordinates.

---

## PART 3 — THE LADDERS / BRANCHES (the build directions)

The thematic axis, formalized from the tank precedent (Headsman / Ironside / Ghost).

- **Count: 2 default, 3 when the fantasy fills it.** Depth-per-branch decides it — ~12 thematic
  boons split 2 ways = ~6/branch (deep), 3 ways = ~4/branch (thin). Don't force uniformity (Rule
  #1, asymmetric content): a rich spec earns a 3rd ladder (like the tank), a lean one stays at 2.
- **Soft = attractors, not cages.** A card can feed several ladders; you can always mix. Your
  synergy draft-slot naturally pulls you deeper into whatever you've started, so builds *coalesce*
  without being forced. **Shoehorning only happens if you hard-gate — soft tags never trap you.**
  Committing to one ladder just peaks higher than splitting.
- **Each ladder is a chain:** entry **Creed** → **Module** → **Boons** → capstone **Keystone**.
- **Keystones per ladder:** ~1 category keystone per ladder (its payoff — huge if you invested) +
  optional **generic** keystones (build-agnostic, for mixers). Pool 2–3, run 1.
- **Map legibility (the payoff for building categories):** some nodes **advertise** their reward
  ladder/type ("offers a Thorns boon") so you can **route toward the build you're chasing** — the
  Hades god-routing layer. Keep a **mix**: some legible (strategy), some random (discovery).

**Sub-specializations ARE the depth engine (2026-07-09, Bill).** Each ladder/branch *is* a
sub-specialization, and **adding or deepening one is the primary lever for pool depth** — the
answer to "we need more boons/upgrades." A new sub-spec pays for itself in *meaningful* cards: its
own boons (a full dial-lane spread), its module, its capstone keystone — each pulling a distinct
build, none of it filler. Pair this with the **EASE dial** (§4, which collapsed the flat-comfort
flood into one rolled archetype) and you land the goal exactly: **more cards that matter, fewer that
don't** — *depth from sub-specs, de-bloat from EASE*. So when a class feels thin, the fix is usually
**a third branch with its own arc**, not ten more +5% boons. (This is why the count is "2 default, 3
when the fantasy fills it" — a rich spec earns a third sub-spec; a lean one stays at two.)

---

## PART 4 — THE 6 CARD-TYPES (lenses, not a law — demoted 2026-07-09, Bill)

**What the types are FOR — the two jobs they were invented to do, both authoring-time:**
1. **Spread** — de-flood the pool: a deck shouldn't be fourteen POWER cards in a row.
2. **Coverage** — a checklist so no *kind* of good card gets forgotten: did this deck get a greed
   card? a weird rule-bender? the difficulty dial? the team card?

**What they are NOT (Bill, 2026-07-09 — "to be strict removes a ton of freedom"):** a strict
taxonomy. The old law *"every card is tagged with exactly one type"* is **dropped**. Nothing
mechanical reads the type (verified: no code path, no draft weighting — the only code presence is
an inert `ctype` label on the Well's boon dicts); the axes that categorize *with consequences* are
**dial-lanes** (structural) and **ladders/sub-specs** (thematic) — Part 2. So:

- **Tag each card with its best-fit type** — a reading aid for Bill, nothing more. A card that
  honestly straddles two (a greedy card that rewards a plan) takes its dominant flavor; **never
  contort a design to fit a box**, and a card that fits no box is fine — these are ideas to start
  from, not walls.
- **Apply the checklist per DECK, not per card** — at authoring/audit time, walk the two jobs
  above (coverage + spread) against the whole slate.
- **Two "types" are really other things** and keep their own laws regardless of this demotion:
  **EASE** is a designed card archetype (the rolled two-way difficulty dial, below) and **TEAM**
  is the Support slot (Part 1) wearing a tag; **RULE** mostly means "keystone," which has its own
  slot laws.

The vocabulary (same meaning across every class):

- **POWER** — just bigger numbers (the bread).
- **GREED** — risk more for more; bites when you overreach.
- **STRAT** — rewards a specific plan or clever play.
- **EASE** — **the difficulty dial**: tune one of the class's own minigame knobs softer for
  comfort *or* harder for +damage. *(See the dial note below.)*
- **RULE** — changes a rule of the minigame (keystones live here; and an *optional* transformer-style
  module — the ⭐ just marks a class's flashiest module, no longer a required one). *(Bill's
  "weird" cards.)*
- **TEAM** — helps the whole warband (the one Support card). *(Bill's "support" card.)*

**EASE = the difficulty dial (redesigned 2026-07-09, Bill).** An EASE card no longer just makes
the minigame softer — it's a **two-way dial** on the class's own knobs (perfect-window size, beat
speed, dodge grace, …). On drop it **rolls 2–3 of the class's knobs**; you **take one** and slide
it either way:
- **← COMFORT** — wider / slower / more grace, **damage-neutral**. Free on the card; you pay only
  the opportunity cost (a draft slot, and the bite bonus you passed up).
- **BITE →** — tighter / faster / less grace, **+damage** (rarity-scaled). A *real gamble*, not
  free power: the tighter version makes a less-skilled player fall OUT of perfect more often and
  lose more than the bonus. You only profit if you can genuinely hit it — self-honest difficulty,
  no separate penalty needed. This is why the bite face reads **GREED-adjacent**, and why nobody
  auto-skips the card — the learner turns it down, the pusher turns it up.

**Why a dial, not a stack of flat comfort cards.** It **de-floods the pool** (one rolled archetype
replaces the dozen "Wider Window / Slower Beat" stats that were easy to author and dull to draft —
the actual pain that started this), puts a **decision on every drop** (which knob + which way), and
lets you **flip a knob mid-run** (comfort while you're learning the fight → bite once you've
mastered it — self-authored difficulty that tracks your growth). It's Hades' Pact-of-Punishment,
expressed through *our* timing dials (the "borrow the grammar, innovate the sentence" filter passes:
a difficulty slider that pays out per perfect is a thing only our timing-combat engine has).

**Guardrails (kept).** Comfort widening still **caps** (diminishing returns → even full-comfort
asks for *some* execution) and **tapers with power** (helps the cold player, not the hot one); the
roll only sets *which knobs are on offer* — **you** choose the direction, so the greed stays
*chosen per build*, never a lottery ("luck wearing greed's clothes", §deck-creator anti-patterns).
Lives **in the boon draft** as the EASE-type card (competing there is what keeps free comfort
honest — a slot spent on comfort isn't spent on a spike). It self-selects: pushers crank bite,
learners and relaxers crank comfort. No menu, no persistent power.

---

## PART 5 — THE SIGNATURE CD · THE ABILITY LAW (the button budget) · the spells rule

**The signature CD** is the class's one baseline big-moment (~1 min). For some classes it
*formalizes* a big-moment they already have; for others it's a new baseline button. It **amplifies
skill** (double your perfects for 8s if you built the combo and line it up with a boss window;
next 3 throws max-potency if you prepped vials) — never a flat `button = damage`. DPS CDs all help
damage but in **different shapes** (a burst you line up · a hold-and-release charge · a reactive
punish window); role CDs are role-shaped (a clutch group-save · a wall).

### THE ABILITY LAW — the button budget (locked 2026-07-09, Bill)

Lifting movement out of the game freed complexity budget — we can afford a few more buttons than
a bare 3-button kit. But the game stays about **optimizing a rotation**, never WoW's 50 buttons,
and every kit must fit a phone. Four rules:

1. **Count in TOUCH TARGETS, not "abilities."** Dodge counts, the signature CD counts, a module's
   button counts, every drafted spell counts. Desktop always has slack; **mobile is the binding
   wall**, so the law is written in buttons-on-glass. (The mobile spike shipped exactly 5 targets
   — big dodge under the left thumb, strike + 3 small under the right — and that layout is
   play-proven; it scales to 7: 2 left, 5 right.)
2. **The chassis is free: core 2–3 + dodge + signature CD = 4–5 targets.** Every class gets this
   without justification (Tempo today: strike · evis · coup + dodge, + the CD owed).
3. **The allowance: +1 above the chassis · HARD CEILING 6 — and the extra button enters only
   through doors that already exist** *(tightened from +2/7 — Bill, 2026-07-10, Tempo ability
   audit: "i dont want button bloat"; the freshness budget moves to ABILITY TRANSFORMS, below)*:
   a drafted spell (`type:"spell"`, earned in-run — the fight-1 kit stays lean and learnable) OR
   **one module button** (the Alchemist's catalyst is the precedent) — one or the other, not both.
   **Boons, creeds, and the rig NEVER add buttons** — they change what existing buttons do.
   Interrupts ride existing buttons (pillar #3 set the pattern: a new *need* doesn't get a new
   *button*). A class may leave the slot EMPTY (Tempo does).
   **The one exception — the broad-kit class: the Well, ceiling 8.** Breadth is its fantasy (Rule
   #2: budget where the fantasy is), and it's legal because its casts share ONE grammar (all pours
   on one timing system), so more buttons doesn't mean more things to track.
   **ABILITY TRANSFORMS (Tempo-piloted, 2026-07-10 — Bill: "upgrade/replace/change ability instead
   of new"):** the sanctioned way to keep abilities fresh without bloat — a drafted TRANSFORM card
   REWRITES how one existing ability works (Coup castable at any Flow · Evis becomes a graded
   string…). **≤1 transformed ability per run**, a ceremony pick, never a new touch target; each
   transform is a DOOR that gates its sub-boons into later offers. Spec: `TEMPO-PLAN.md §17.11`
   (generalize per class at reshape, like everything else in this doc).
4. **Every button must carry a WHEN, not just a WHAT.** This is the rule that actually protects
   "optimize the rotation" — the ceilings are just the fence. If the optimal play is "press it on
   cooldown, every time," it is not a button: make it a passive, a rig THEN, or fold it into an
   existing press. The freed movement budget buys **deeper timing on few buttons**, not more
   buttons.

**Compliance (current kits, counted honestly — re-run at the +1 law):** Twinfang 4 (+CD = 5;
**Tempo elects to leave its +1 slot EMPTY** — transforms carry the freshness, TEMPO §17.11; the
Count-In parks as the slot's standing candidate) · Alchemist fully drafted = 8 (+CD = 9 —
**over**; at reshape the catalyst module button + the 3 drafted spells now compete for **ONE**
allowance slot — a deeper trim than before) · the Well loaded = 10 (**over even its 8** — the
book gets a trim/fold at its reshape). The per-class `SPELL_CAP` in code (5 on
Twinfang/Alchemist/Voidcaller, 8 on the Well) is just the draft-machinery knob — retune each
class's knob to whatever its ceiling leaves free. The old "bar cap 5" note below was quoting that
knob; this law supersedes it.

**The spells rule — reconciled (2026-07-09).** The old law "spell/extra-button lanes are dead"
(*"I don't like flurry, grace note, coda"*) stands **as an anti-filler rule**, now stated
precisely: **new buttons need a class-law reason.** Two things clear that bar:
- the **signature CD** (the one sanctioned baseline button per class), and
- a **broad-kit class** spending its complexity budget on **breadth** — a healer with more heals
  is *on-fantasy* (Rule #2: budget where the fantasy is), not filler. Twinfang stays 3-button;
  the **Well is the spells-reweight pilot** (direct-cast heals — charge/empower pours, a proactive
  shield, a beacon, the rewind showpiece; HoTs stay a whisper so Bloomweaver keeps that lane).

The `type:"spell"` machinery is unchanged (per-class `SPELL_CAP`, exclusive `excl` twins); each
class's cap now derives from the ABILITY LAW above (whatever its ceiling leaves free). It's *used*
where the class law calls for it, never sprinkled as filler.

---

## PART 6 — THE DESIGN RULES (the laws over all of it)

The **7 class-design rules** are canonical in `MASTER-PLAN.md` §CLASS FRAMEWORK (locked
2026-07-06). In brief: (1) uniform interfaces, asymmetric content — no cookie-cutter; (2) one
complexity budget, spent where the fantasy is; (3) AI-pilotable or it doesn't ship; (4) skill must
move outcomes; (5) roles are HARD, off-role is SOFT clutch spice (2/1/0 distribution); (6) kits
must be fun BARE; (7) comp-variant content is parked.

**Added this session (2026-07-09):**
- **Borrow the grammar, innovate the sentence** (the next-level filter): every borrowed system
  must do something only our timing-combat or deterministic-AI engine could — else it's a repack.
- **EASE is a two-way dial** (redesigned 2026-07-09) — one card, one knob, slide it COMFORT
  (wider/slower, damage-neutral) or BITE (tighter/faster, +damage-as-a-gamble). De-floods the flat
  comfort cards into one rolled archetype; the direction is always *chosen*, never a lottery.
  Supersedes the old "floor up / ceiling down" framing. See §4.
- **Branches are soft** — attractors, not cages; hard-gating is the only thing that shoehorns.
- **The CD amplifies skill** — never `button = damage`.
- **Modules are add-ons, not transformers** (2026-07-09, Bill) — a module *supplements* the core
  minigame (a gauge layered on top; the base stays fully playable without it). The old "exactly one
  ⭐ transformer per class" **mandate is dropped** — the fill→transform→crash shape is now just one
  *optional* module flavor, not a required slot. See §1.
- **Sub-specializations are the depth engine** (2026-07-09, Bill) — deepen a class by adding/filling
  a branch (its own boons + module + keystone), not by stacking flat boons; EASE-dial de-bloat +
  sub-spec depth = more cards that matter, fewer that don't. See §3.
- **Card-types are lenses, not a law** (2026-07-09, Bill) — the 6-word vocabulary is an authoring
  checklist (spread + coverage, applied **per deck**) plus a best-fit reading tag; *"exactly one
  type per card"* is dropped and no design is ever contorted to fit a box. EASE (the dial
  archetype) and TEAM (the Support slot) keep their own laws independent of the tags. See §4.
- **THE ABILITY LAW** (2026-07-09, Bill · tightened 2026-07-10) — the button budget, counted in
  **touch targets** (mobile is the binding wall): chassis free (core 2–3 + dodge + signature CD),
  **+1 allowance** entering only via existing doors (a drafted spell OR one module button — not
  both), **hard ceiling 6** (the Well, the one sanctioned broad-kit, gets 8). Boons/creeds/rig
  never add buttons; interrupts ride existing buttons. **Every button needs a WHEN, not just a
  WHAT** — press-on-cooldown is a passive in a button costume. Freshness beyond the budget comes
  from **ABILITY TRANSFORMS** (rewrite an existing button, ≤1/run, Tempo-piloted), never more
  buttons. See §5.
- **The Rig is REQUIRED** (2026-07-09, Bill) — every class deck ships the single-circuit WHEN→THEN
  rig (see §1's RIG LAW): class-authored earned WHENs, greed-dial payout (`base × mult`), wire after
  fight 1 + one free Floor-2 re-wire. **The stackable multi-proc model stays CUT** — no THEN-board,
  no second wire; banking only inside one THEN, small and capped.

---

## PART 7 — NOTES & OPEN

- Proofs in-house: the **tank** is the ladders precedent; the **healer (Well)** is the spells pilot.
- **Sequencing:** this doc is Phase 1. Phase 2 = **reshape each class onto it, one at a time** (the
  deck-creator is the tool; the tank/well are the templates).
- **Open feel-verdicts:** per-class CD shapes · branch count per spec (2 vs 3) · which keystones
  are category vs generic · the map reward-legibility mix · curse-cards ("biting blessings")
  interplay with EASE/greed.
