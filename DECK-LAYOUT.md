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
| **Modules** | 2–3, **Floor-1 pick** | A new UI dynamic — a gauge that adds a way to play. | Exactly **one ⭐ transformer** per class (fills → temporary transformed state → crashes). A module must EARN its pixels. |
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
3. **CARD-TYPE — the descriptor.** One of the **6 universal types** (Part 4). How Bill reads a
   card at a glance; same meaning on every class.

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

---

## PART 4 — THE 6 CARD-TYPES (the universal vocabulary)

Every card is tagged with **exactly one** type — same meaning across every class (Bill classifies
at a glance). Verbatim:

- **POWER** — just bigger numbers (the bread).
- **GREED** — risk more for more; bites when you overreach.
- **STRAT** — rewards a specific plan or clever play.
- **EASE** — more forgiving / less twitchy. *(See the difficulty note below.)*
- **RULE** — changes a rule of the minigame (⭐ transformers and keystones live here). *(Bill's
  "weird" cards.)*
- **TEAM** — helps the whole warband (the one Support card). *(Bill's "support" card.)*

**EASE = player-authored difficulty (the lane Bill likes, with its guardrail).** Stacking
EASE-tagged cards makes the minigame more forgiving — for the player who wants to *live in the
execution* over juggling spells. It stays honest because **it's a trade, not a free
difficulty-drop: floor up, ceiling down.** Picks spent on comfort aren't spent on spikes, so an
EASE build peaks below a POWER/greed build; window-widening has a **cap** (diminishing returns) so
even full-EASE still asks for *some* execution; and you **count the EASE cards per deck** so a
class can't drift soft. It self-selects — pushers ignore it, learners and relaxers lean in. No
menu, no persistent power.

---

## PART 5 — THE SIGNATURE CD + the spells rule (the reconcile)

**The signature CD** is the class's one baseline big-moment (~1 min). For some classes it
*formalizes* a big-moment they already have; for others it's a new baseline button. It **amplifies
skill** (double your perfects for 8s if you built the combo and line it up with a boss window;
next 3 throws max-potency if you prepped vials) — never a flat `button = damage`. DPS CDs all help
damage but in **different shapes** (a burst you line up · a hold-and-release charge · a reactive
punish window); role CDs are role-shaped (a clutch group-save · a wall).

**The spells rule — reconciled (2026-07-09).** The old law "spell/extra-button lanes are dead"
(*"I don't like flurry, grace note, coda"*) stands **as an anti-filler rule**, now stated
precisely: **new buttons need a class-law reason.** Two things clear that bar:
- the **signature CD** (the one sanctioned baseline button per class), and
- a **broad-kit class** spending its complexity budget on **breadth** — a healer with more heals
  is *on-fantasy* (Rule #2: budget where the fantasy is), not filler. Twinfang stays 3-button;
  the **Well is the spells-reweight pilot** (direct-cast heals — charge/empower pours, a proactive
  shield, a beacon, the rewind showpiece; HoTs stay a whisper so Bloomweaver keeps that lane).

The `type:"spell"` machinery is unchanged (bar cap 5, exclusive `excl` twins); it's *used* where
the class law calls for it, never sprinkled as filler.

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
- **EASE is a trade** (floor up / ceiling down), never a free difficulty-drop.
- **Branches are soft** — attractors, not cages; hard-gating is the only thing that shoehorns.
- **The CD amplifies skill** — never `button = damage`.

---

## PART 7 — NOTES & OPEN

- Proofs in-house: the **tank** is the ladders precedent; the **healer (Well)** is the spells pilot.
- **Sequencing:** this doc is Phase 1. Phase 2 = **reshape each class onto it, one at a time** (the
  deck-creator is the tool; the tank/well are the templates).
- **Open feel-verdicts:** per-class CD shapes · branch count per spec (2 vs 3) · which keystones
  are category vs generic · the map reward-legibility mix · curse-cards ("biting blessings")
  interplay with EASE/greed.
