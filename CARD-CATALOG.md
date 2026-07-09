# CARD CATALOG — the single source of truth for card DESIGN + status (2026-07-09)

**What this is.** The ONE place that lists **every card** — creeds, modules, boons, rig
WHEN/THENs, keystones, support, spells, signature CDs — across **every class**, with its
**status** (idea → verdict → approved → built → cut). One doc, one format, one status column.

**Why it exists.** Card design was scattered across four per-class plan docs in four different
formats, with the *built* truth living separately in `godot/data/<class>/*.gd`. Nothing linked the
two, so proposals and code drifted silently (e.g. "**Duelist**" is a *proposed player kit* here but
a *boss encounter* in code — the shipped tank is still `Bulwark`). This doc is the fix: all card
design lives here, in one shape, with status made explicit instead of buried in prose glyphs.

**How it relates to the other docs (read this — it's the coordination rule):**
- **`DECK-LAYOUT.md`** = the *anatomy/schema* (slots, the 3 axes, the 6 card-types, the laws). It
  says what a deck must contain. **This doc = the actual cards that fill those slots.** Schema there,
  content here.
- **Per-class plan docs** (`TEMPO-PLAN.md`, `ALCHEMIST-PLAN.md`, `MENDER-PLAN.md`, `TANK-PLAN.md`,
  `FERMATA-V5-BRIEF.md`) keep the **rationale, discussion, minigame design, and build orders**. The
  **card SLATE moves here.** When a plan doc and this catalog disagree on a card's numbers/type/
  status, **this catalog wins** — the plan doc gets a pointer.
- **The code** (`godot/data/<class>/*.gd`) is the behavioral truth for **BUILT** cards (the effect
  logic). This catalog's `id`/`type`/`rarity` fields **mirror the code dict fields on purpose**, so
  a future `scripts/dump-cards.sh` can regenerate the BUILT rows straight from code and this doc
  becomes generate-from-code with zero reshape. (Bill, 2026-07-09: "generate from code later; for
  now a doc with stricter rules.")
- **The `deck-creator` skill** authors new slates **directly into this format** and drops them here
  as `💡`/`🟡` rows — never as loose prose in a plan doc.

---

## THE STATUS LIFECYCLE (the strict part — this is the point of the doc)

Every card row carries **exactly one** status glyph. A card moves through these states and the
row is edited **in the same commit** as the decision that moved it:

| Glyph | Status | Meaning | Who moves it |
|---|---|---|---|
| 💡 | **IDEA** | Floated in a design pass; not yet up for a decision. | Any design session. |
| 🟡 | **AT VERDICT** | On Bill's board — awaiting KEEP / TWEAK / CUT. | Whoever readies it for Bill. |
| ✅ | **APPROVED** | Bill approved the design; **not yet coded.** | **Only after Bill approves.** |
| 🔨 | **BUILT** | Coded + merged. Carries the git SHA in the *Source* column. | Whoever builds + merges it. |
| 🔮 | **PARKED** | Deferred — record, don't build. Keep for later. | Any session, with a reason. |
| ✂️ | **CUT** | Rejected or superseded → moved to the **Cut Ledger** (bottom). Never resurrect. | Whoever cuts it, with a one-line reason. |

### The maintenance rules (obey these on EVERY card touch)
1. **This doc is the source of truth for card design + status.** Add/track cards here, not in a plan
   doc's prose.
2. **New idea → add a row** as `💡 IDEA`, or `🟡 AT VERDICT` if it's ready for Bill's board.
3. **Bill approves → flip `🟡 → ✅` in the same edit** that records the approval. Bill's word is the
   only thing that sets `✅`. If he tweaks it, edit the effect text in the same edit.
4. **Bill rejects → `✂️ CUT`**: move the row to the Cut Ledger with a one-line reason; leave a
   tombstone pointer if it was referenced elsewhere.
5. **Coded + merged → flip `✅ → 🔨` and paste the SHA** in *Source*. A card is not `🔨` without a SHA.
6. **Numbers/effect change → edit the row in place.** Never leave stale text next to a live card.
7. **Never delete a card** — cut cards live forever in the Cut Ledger so a dead idea can't be
   re-proposed by a later session. (Matches the "Cut ledger — do not resurrect" convention.)
8. **Keep the roll-up honest.** When a status flips, update that class's one-line roll-up counts.

### The canonical row format
Cards are grouped **per class → per slot** (creeds, modules, boons-by-dial-lane, rig, keystones,
support, spells). Every table has the same columns:

> `| Card (id) | Type | Rarity | Status | Effect |`

- **Card (id)** — display name, with the **code id** in `code font` (or a proposed slug if unbuilt).
- **Type** — one of the 6 (`POWER` / `GREED` / `STRAT` / `EASE` / `RULE` / `TEAM`), per `DECK-LAYOUT.md §4`.
  ⚠ **EASE is the difficulty dial now (2026-07-09, `DECK-LAYOUT.md §4`)** — one rolled two-way dial
  (COMFORT ↔ BITE), **not** a stack of flat comfort stats. Existing flat-EASE *boons* (e.g. the
  Duelist's **Quick Wrists** / **Roll With It**) **fold into their class's dial at deck reshape**;
  don't author new flat comfort boons. Forgiving *creeds* (e.g. **The Veteran**) are a whole-run
  temperament, not comfort stats — they stay as creeds and keep their EASE flavor.
- **Rarity** — draft frequency `haiku`/`sonnet`/`opus` for boons; `—` for creeds/modules/rig/signature.
- **Status** — a lifecycle glyph from above.
- **Effect** — plain language (no jargon), with the **H/S/O ladder inline** where the card scales
  (e.g. `counter +20/30/40%` = the Haiku/Sonnet/Opus rungs). Put the **Source SHA** for `🔨` cards
  in parentheses at the end of the effect, e.g. `(built c1071bd)`.

---

## CLASS INDEX + STATUS ROLL-UP

| Class (spec) | Seat | Base | Deck status | Full slate |
|---|---|---|---|---|
| **Twinfang · Tempo** | rogue | 🔨 built | boons mostly 🔨, keystones/2nd-spec owed | [§ Twinfang](#twinfang) · `TEMPO-PLAN.md` |
| **Twinfang · Fermata** | rogue | partial | EDGE core 🔒, deck v5 🟡 | `FERMATA-V5-BRIEF.md` |
| **Alchemist · Brew** | caster | 🔨 built | full slate 🔨; review-pass proposals 🟡 | `ALCHEMIST-PLAN.md` |
| **Alchemist · Cask** | caster | 🔨 slices 1–2 | HUD/cards/balance owed | `ALCHEMIST-PLAN.md §7` |
| **The Well** | healer | 🔨 built | **deck 🔮 not authored** | `MENDER-PLAN.md` |
| **Mender** | healer | frozen | boons only in code | `MENDER-PLAN.md` |
| **Tank · Duelist** | tank | 🟡 round-5 locked | **deck v1 🟡 AT VERDICT · 0 built** | [§ Tank](#tank-the-duelist) · `TANK-PLAN.md` |
| **Tank · Warden** | tank | 🟡 locked | deck = later pass | `TANK-PLAN.md §5` |
| Bulwark / Bloomweaver / Reckoner / Voidcaller | — | FROZEN | code slate only, not under active planning | code `data/<class>/` |

**Fill status of THIS doc:** the **Tank · Duelist** section below is the fully-populated worked
reference (proves the format on a real slate). The other active classes are **stubs pending
back-fill** — say the word and they get filled from their plan docs + code in this same format.

---

<a id="tank-the-duelist"></a>
## TANK · THE DUELIST — 🟡 AT VERDICT (deck v1, 0 built) · base = round-5 locked

Source of record: `TANK-PLAN.md §3` (verdict board:
https://claude.ai/code/artifact/cf273dd1-4169-45e2-b990-47000941d417). **Nothing built yet** — old
Bulwark is the frozen placeholder, NOT this base. Names still open (class + fatigue resource "WIND").
Dials: THE READ / THE SWING / THE STEP / THE WIND / THE BANK / THE SPEND / THE DUET.
Three ladders: **Headsman** (bank-and-burst) · **Ironside** (guard engine) · **Ghost** (footwork).

> **⚠ BASE-MINIGAME PASS (2026-07-09, Bill — `TANK-PLAN.md §1b`):** GUARD is **dropped** from the
> Duelist (◆ → DUMP = damage only; defensive utility moves to the ~1-min defensive CD). So the SPEND
> lane's **Return to Sender** + **Cheap Iron** and the **The Wall** rig lose their premise here → **🔮
> PARKED, re-home to the Warden** (shield-based). Both specs now read the same: **2 matched buttons
> (MAIN + SECONDARY)**, one rating rule (§1b). Duelist = DODGE(2nd)/PARRY(main) + **WEAVE** (flurry);
> Warden = BLOCK(2nd)/SHIELD(main, HELD across flurries) + **SHIELD SLAM** (a *perfect shield hits back*,
> the parry-twin — not a separate button), **no dodge**. **FLOW → a module** (row below). Deck reshape
> deferred (branches after the minigame).

### Signature CD ⏱
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Defensive CD** _(unnamed — the tank's ~1-min "wall")_ | — | — | 💡 IDEA | Role-shaped defensive cooldown (a wall), per `DECK-LAYOUT.md §5`; carries the mitigation GUARD used to (◆ is damage-only now). Amplifies skill — line it up with a boss window — never `button = damage`. Both specs get one; shapes may differ. |

### Creeds (pick 1/run — curated)
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **The Veteran** | EASE | — | 🟡 | Window ~74ms; a missed swing refunds half its wind. Counter −25%, ◆ cap 4. The learner's blade — caps itself so you graduate out. |
| **The Wager** | GREED | — | 🟡 | Parry costs 4.5, a miss leaks +10% — a LAND banks ◆◆ and counter +40%. The greed pole. |
| **The Bellows** | STRAT | — | 🟡 | Wind regen halved; every clean answer (land or perfect step) +1.5 wind instantly. The pool becomes a chain. |
| **The Dancer** | RULE | — | 🟡 | **WILD — the parry button is GONE.** A PERFECT dodge IS the parry (counter + ◆ every other perfect); GOOD stays a dodge; baited lockout +0.2s. Pure height-reading; the mobile creed. |

### Modules (Floor-1 pick 1-of-3 · **add-ons to the minigame — no transformer requirement**)
> **⚠ MODULE REFRAME (2026-07-09, Bill — `DECK-LAYOUT.md §1`):** a module is an **add-on/supplement**
> to the core minigame (a gauge layered on top; base playable without it), NOT a mandated transformer.
> The old "exactly one ⭐ transformer per class" rule is **dropped** ("something about transforming I
> don't get" — Bill). The fill→transform→crash shape is now just one *optional* flavor. So **The
> Crucible below is up for keep / simplify to a plain supplement / cut** at reshape.

| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **The Crucible** | RULE | — | 🟡 | _Optional fill-and-unleash gauge (transform no longer required)._ Damage TAKEN fills it → IGNITE ~6s WHITE STEEL (parries cost 0 wind, lands bank ◆◆, counters ×1.5) → crash (regen dead 4s, gauge empty). Ignite timing is the decision. **At verdict: keep the fill→ignite→crash shape, simplify to a steady supplement, or cut.** |
| **The Scales** | STRAT | — | 🟡 | Balance pan: parries tip crimson, dodges tip blue; near-BALANCE grows an edge (→ +12% dealt / −12% taken); pegging a side kills it until re-centred. Anti-autopilot. |
| **The Whetstone** | GREED | — | 🟡 | Each banked ◆ sharpens over 4s (sharp pip ×1.5 in a dump); an unanswered real hit dulls your sharpest pip. Hold-vs-spend with teeth. |
| **Flow** _(the module)_ | STRAT | — | 💡 | **Reframed 2026-07-09:** base FLOW is now the **AGGRO meter** (`TANK-PLAN §1c`) — always on. This MODULE is the *upgrade*: your flow ALSO **ramps your DUMP damage** (aggro-hold → damage engine, the "lots of dodge, not much dmg" lever). Competes for the Floor-1 module slot; reconcile at deck reshape. |

### Boons — LANE: THE SWING
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Heavier Steel** | POWER | haiku | 🟡 | Counter +20/30/40%. |
| **Quick Wrists** | EASE | haiku | 🟡 | Window +8/12/16ms, fades while ◆ full (tapers with power). |
| **High Line** | STRAT | haiku | 🟡 | Tall-bar land: ◆◆ / +1 wind / counter ×1.5 vs tall. |
| **Overreach** | GREED | haiku | 🟡 | Parry while WINDED for 8/7/6% max-HP blood, never below 10% HP; O: blood-land banks ◆◆ (feeds the Crucible). |

### Boons — LANE: THE STEP
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Feather Step** | POWER | haiku | 🟡 | Dodge −25/35/50% wind, floor 0.5 (CARRY to Warden). |
| **Perfect Form** | STRAT | haiku | 🟡 | Perfect dodge refunds wind; next parry ≤2s −1/−1.5/−2 (the step-into-swing chain). |
| **Read the Room** | STRAT | haiku | 🟡 | A READ: +1 wind, next counter +8/12/16%; O stacks ×2. |
| **Roll With It** | EASE | haiku | 🟡 | Good dodge on tall: leak → 3s bleed, +0.5/0.7/1 wind (the lane's one pardon, dressed for the duet). |

### Boons — LANE: THE BANK
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Deep Pockets** | POWER | haiku | 🟡 | Cap +1 / +1 & start 1◆ / +2 & start 1◆ (CARRY; feeds Headsman + Ironside). |
| **The Rally** | GREED | haiku | 🟡 | Every 3rd/3rd/2nd land in an unbroken chain banks double; miss/graze breaks, dodges don't. |
| **Blood Price** | STRAT | haiku | 🟡 | Eat an unavoidable: ◆ / +2 wind / next spend +20%. |

### Boons — LANE: THE SPEND
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Powder Keg** | POWER | haiku | 🟡 | Dump +20/30/40% per ◆ (CARRY). |
| **All In** | GREED | haiku | 🟡 | Full-bank dump ×1.25/1.4/1.5; at full bank take +10%. |
| **Return to Sender** | STRAT | haiku | 🔮 | _Re-home to Warden (2026-07-09): GUARD dropped from Duelist._ Shield stores 40/55/70% of prevented damage, hurls it back as a bar when it drops. |
| **Cheap Iron** | EASE | haiku | 🔮 | _Re-home to Warden (2026-07-09): GUARD dropped from Duelist._ Shield-raise cheaper; cut 45/50/55%. |

### Rig (WHEN → THEN)
THENs: STRIKE 20 dmg · IRON 2s +20% DR · BREATH +2 wind · PIP +1◆ · BANNER 2.5s warband +5%.
| WHEN (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **The Tall Land** | STRAT | — | 🟡 | Parry a TALL bar (premium WHEN). |
| **The Big Spend** | STRAT | — | 🟡 | Dump ≥4◆. |
| **The Wall** | STRAT | — | 🔮 | _Re-home to Warden (2026-07-09): GUARD dropped from Duelist._ Shield eats a hit ≥15% max HP (premium). |
| **The Read** | STRAT | — | 🟡 | Correctly ignore a feint. |

### Keystones (elite-only · pool 3 / run 1 · spectacle)
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| 👑 **The Avalanche** | RULE | — | 🟡 | DUMP becomes a returning string: each ◆ sails BACK across the gate; press as it crosses = ×2. (Headsman capstone.) |
| 👑 **Borrowed Time** | RULE | — | 🟡 | A full-speed land SLOWS the stream 1.5s (bars crawl); slowed-time lands don't refresh (no perma-slow). (Ghost capstone.) |
| 👑 **The Impossible Parry** | RULE | — | 🟡 | Unavoidables grow a gold sliver: perfect swing at DOUBLE wind parries them; land = counter ×2 + ◆◆; miss = eat hit + swing. Makes Blood Price a live choice. (Ironside capstone.) |

### Support (1)
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| ✦ **Hold the Line** | TEAM | — | 🟡 | While THE LINE HOLDS (no unanswered real hit in last 5s), warband +6/8/10% damage. Uptime IS the buff (CARRY). |

### Carries (verbatim on the Warden — verified per-knob)
Feather Step (block cost = same knob) · Deep Pockets · Powder Keg · ✦ Hold the Line.
**NOT carried:** Blood Price (Warden has no unavoidables) · Read the Room (counter rider dead — no attack).

---

<a id="twinfang"></a>
## TWINFANG · TEMPO — 🔨 mostly built · keystones + 2nd spec owed
_Stub — back-fill from `TEMPO-PLAN.md` Appendix A "THE TEMPO CARD LEDGER" (already code-linked with
ids + SHAs) + `godot/data/twinfang/*.gd`._ Boons/creeds/modules/rig defined in `twinfang_boons.gd`,
`twinfang_creeds.gd`, `twinfang_modules.gd`, `twinfang_rig.gd`.

## ALCHEMIST · BREW / CASK — 🔨 built · review-pass proposals 🟡
_Stub — back-fill from `ALCHEMIST-PLAN.md §4` (Brew) + `§7` (Cask) + `§8` (review-pass verdicts) +
`godot/data/alchemist/*.gd`._

## THE WELL — 🔨 base built · deck 🔮 not authored
_Stub — back-fill from `MENDER-PLAN.md` "BOARD VERDICTS" export once the deck is authored +
`godot/data/well/*.gd`._

## MENDER + FROZEN CLASSES (Bulwark / Bloomweaver / Reckoner / Voidcaller)
_Code slate only, not under active planning. Fill on demand from `godot/data/<class>/<class>_boons.gd`._

---

## CUT LEDGER — do not resurrect

_Cards that were proposed and rejected/superseded. Each keeps a one-line reason so a later session
can't re-propose a dead idea. (Cross-references live tank cut-history in `TANK-PLAN.md:52`.)_

| Card | Class | Cut date | Reason |
|---|---|---|---|
| _(none logged yet — first entry goes here when a `🟡`/`✅` card is cut)_ | | | |
