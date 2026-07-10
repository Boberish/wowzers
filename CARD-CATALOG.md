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
- **Type** — best-fit tag from the 6-word vocabulary (`POWER` / `GREED` / `STRAT` / `EASE` / `RULE` /
  `TEAM`), per `DECK-LAYOUT.md §4`. ⚠ **Lenses, not a law (2026-07-09, Bill):** the type is a reading
  aid + a per-deck coverage/spread checklist, not a strict taxonomy — nothing mechanical reads it.
  Tag the dominant flavor; never contort a card to fit a box.
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
| **Tank · Duelist** | tank | 🟡 round-5 locked | **deck v1 🟡 AT VERDICT · 0 built** | [§ Tank](#tank-the-duelist) · `TANK-PLAN.md` |
| **Tank · Warden** | tank | 🟡 locked | deck = later pass | `TANK-PLAN.md §5` |
| Bulwark / Bloomweaver | — | FROZEN | code slate only; Bulwark dies with the Duelist merge | code `data/<class>/` |
| ~~Mender · Voidcaller · Reckoner~~ | — | ✂️ **DELETED (THE PURGE 2026-07-10)** | whole classes + card slates cut from code (git history is the attic) | MASTER §GAME SHAPE amendment |

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
### DUELIST · D2 SWAP KITS (v2 revision, `TANK-PLAN.md §9` — 🟡 2026-07-10; winning kits flip ✅, losers park 🔮 with their slate)

| Card | id | Type | Rarity | St | Kit | One line |
|---|---|---|---|---|---|---|
| **Cold Blood** (creed) | `coldblood` | STRAT | curated | 🟡 | M | Reads build INSIGHT from run start; feint tells louder. |
| **The Late Answer** | `lateanswer` | GREED | H/S/O | 🟡 | M | Last-slice parry = double insight; a whiff there costs 2. |
| **Toro** | `toro` | STRAT | H/S/O | 🟡 | M | A BAITED feint spends 1 insight to forgive the wind loss. |
| **LA ESTOCADA** (keystone) | `estocada` | RULE | elite | 🟡 | M | Full insight → the stream holds its breath, the counter lands ×3. |
| **Red Ledger** (creed) | `redledger` | STRAT | curated | 🟡 | S | Unavoidables bank ◆ (small) from run start. |
| **Paid in Iron** | `paidiniron` | STRAT | H/S/O | 🟡 | S | Below 60% HP counters +12/18/25%. |
| **The Deep Cut** | `deepcut` | GREED | H/S/O | 🟡 | S | Once/bank-cycle eat a normal bar on purpose: ◆◆ +3 wind; floor 25% HP. |
| **CRIMSON DIVIDEND** (keystone) | `crimsondividend` | RULE | elite | 🟡 | S | Full-bank dump <40% HP ×2; the healer's refill pours into your next bank. |
| **Storm Footing** (creed) | `stormfooting` | STRAT | curated | 🟡 | W | Clean weaves refund +1 wind from run start. |
| **Eye of the Storm** | `eyestorm` | STRAT | H/S/O | 🟡 | W | A clean weave's riposte also banks ◆. |
| **Thread the Needle** | `threadneedle` | GREED | H/S/O | 🟡 | W | Weave windows −15%, clean ripostes ×1.5. |
| **Rolling Thunder** | `rollingthunder` | POWER | H/S/O | 🟡 | W | Riposte +20/30/40% (the kit's bread). |
| **THE TEMPEST ANSWER** (keystone) | `tempestanswer` | RULE | elite | 🟡 | W | A survived flurry mirrors back as YOUR graded bar-string. |

**v1.1 errata (fold on verdict):** Quick Wrists + Roll With It → the EASE dial (leave pool) ·
FLOW module = 4th Floor-1 candidate · Hold the Line re-keys onto FLOW · GUARD trio resolved to
the Warden (§8) · absorbs: Read the Room→Kit M · Blood Price/Overreach→Kit S (double-filed).

## TANK · THE WARDEN — **DECK v1 (D1) 🟡 AT VERDICT 2026-07-10** · base locked, 0 built

Source of record: `TANK-PLAN.md §8` (themes **Payload · Slam · Rampart**, §6 ranking; Bill's ✅
picks swap cheap). Dials: READ / TAP / **HOLD** / SLAM / WIND / BANK / SPEND / LINE / **CHARGE**.

| Card | id | Type | Rarity | St | One line |
|---|---|---|---|---|---|
| **The Sentinel** (creed) | `sentinel` | EASE | curated | 🟡 | Blocks ~30% wider, slam counter −25%, ◆ cap 4 — the self-capping learner. |
| **Ballast** (creed) | `ballast` | STRAT | curated | 🟡 | The battery live from run start — PAYLOAD entry. |
| **The Drumhead** (creed) | `drumhead` | GREED | curated | 🟡 | Slam chains +1 wind/link; graze breaks — SLAM entry. |
| **Deep Keel** (creed) | `deepkeel` | STRAT | curated | 🟡 | Pool +20%, recharge unchanged — RAMPART entry. |
| **THE MONOLITH** (creed) | `monolith` | RULE | curated | 🟡 | **WILD: BLOCK is gone** — everything is HELD; one-button drain economy (the Dancer's mirror, mobile creed). |
| **The Coil** (module) | `coil` | STRAT | — | 🟡 | The battery gauge; taps feed 25%. |
| **Aftershock** (module) | `aftershock` | STRAT | — | 🟡 | 2s free-tap window after a perfect SLAM. |
| **The Bulwark Stance** (module) | `bulwarkstance` | GREED | — | 🟡 | Hold-all wall, drain +40% (the old base, priced). |
| **Return to Sender** | `returnsender` | STRAT | H/S/O | 🟡 | Re-homed 🔮→🟡 verbatim: stores 40/55/70% prevented, hurls back as a bar. |
| **Heavy Shipment** | `heavyshipment` | GREED | H/S/O | 🟡 | Battery cap +50%, decay +50%. |
| **Special Delivery** | `specialdelivery` | STRAT | H/S/O | 🟡 | Hurl during a tall wind-up ×1.25/1.35/1.5. |
| **Offensive Guard** | `offguard` | POWER | H/S/O | 🟡 | Perfect SHIELD → next DUMP +15/22/30%. |
| **Meet It Head-On** | `headon` | GREED | H/S/O | 🟡 | MAIN on small/normal (full wind) banks ◆. |
| **Drumfire** | `drumfire` | STRAT | H/S/O | 🟡 | Every 3rd consecutive clean SLAM banks ◆◆; graze breaks. |
| **Cheap Iron** | `cheapiron` | EASE | H/S/O | 🟡 | Re-homed 🔮→🟡: raises cost 45/50/55% less. |
| **Second Wind** | `secondwind_w` | STRAT | H/S/O | 🟡 | Hold released above half-pool refunds 2/3/4 wind. |
| **White Knuckles** | `whiteknuckles` | GREED | H/S/O | 🟡 | <25% wind: taps +15/20/25% mit; a whiff empties the pool. |
| **The Push** | `push` | STRAT | H/S/O | 🟡 | Pay 2 wind (8s cd): blunt the incoming bar one size. |
| **The Wall** (rig WHEN) | `wall` | — | — | 🟡 | Re-homed 🔮→🟡: shield eats a hit ≥15% max HP (~3.5). |
| **The Long Hold** (rig WHEN) | `longhold` | — | — | 🟡 | Hold through a full flurry (~2.5). |
| **The Counterweight** (rig WHEN) | `counterweight` | — | — | 🟡 | SLAM a tall bar (~2.0). |
| **THE SIEGE** (keystone) | `siege` | RULE | elite | 🟡 | Full charge → one colossal returning bar; press ×2. |
| **BREAKWATER** (keystone) | `breakwater` | RULE | elite | 🟡 | Perfect SLAM on tall SHOVES the next bar back down the lane. |
| **THE IMMOVABLE** (keystone) | `immovable` | RULE | elite | 🟡 | Clean full-flurry hold → 4s root (bars shrink), then the drain debt. |
| **THE GATE** (signature CD) | `gate` | TEAM | baseline | 🟡 | ~1-min: 4s warband wall scaled by your CURRENT wind % — the owed "wall" slot's first shape. |
| ✦ Hold the Line (support) | `holdline` | TEAM | — | 🟡 | Carry; re-keyed onto FLOW at build (§1d). |

**Carries:** Deep Pockets · Powder Keg verified; **Feather Step → proposed fold to Duelist-only**
(Cheap Iron owns the Warden's block-cost knob — tension point 3). Killed in-pass: Iron Reserves
(bread flooding).

## TWINFANG · TEMPO — 🔨 mostly built · **DECK v3 (D0) 🟡 AT VERDICT 2026-07-10**
_Built pool: back-fill from `TEMPO-PLAN.md` Appendix A (code-linked ids + SHAs) +
`godot/data/twinfang/*.gd` still owed. **The D0 deck pass (`TEMPO-PLAN.md §17`) proposes the rows
below** — themes WOUND · SWIFT · FINISH; every built card filed in §17.3._

**New / changed cards (D0 · all 🟡 at verdict):**

| Card | id | Type | Rarity | St | One line |
|---|---|---|---|---|---|
| **Uptempo** (creed) | `uptempo` | GREED | curated | 🟡 | Beat ~15% faster baseline, Perfects refund +2 energy — SWIFT's entry; never tightens past the F8 floor. |
| **Open Veins** (creed) | `openVeins` | STRAT | curated | 🟡 | Bullseyes inscribe a 2-beat BLEED from run start — THE WOUND's entry; no UI at creed level. |
| **Hemorrhage** (module) | `hemorrhage` | STRAT | — | 🟡 | The wound counter on the boss frame; bleeds +1 beat; Eviscerate may CASH the pot (+10%/bleed consumed). Builds the unbuilt data. |
| **Lacerate** | `lacerate` | STRAT | H/S/O | 🟡 | Perfects also inscribe (half/⅔/full-value bleeds). |
| **Slow Bleed** | `slowBleed` | POWER | H/S/O | 🟡 | Bleeds +1/+2/+2 beats & +10% tick (cap 5 beats). |
| **Arterial Note** | `arterialNote` | GREED | H/S/O | 🟡 | Bleeds +30/40/55% harder, expire 1 beat sooner. |
| **Through-Line** | `throughline` | STRAT | H/S/O | 🟡 | AUTHORED (was design-owed): consecutive Perfect+ +2%/stack cap 5, reset on Miss. |
| **Quickstep** | `quickstep` | GREED | H/S/O | 🟡 | Each Perfect speeds AND tightens (~8%) your next window; floor-clamped, taper law. |
| **Grand Pause** | `grandPause` | STRAT | H/S/O | 🟡 | Eviscerate at EXACTLY max combo +25/30/35%. |
| **Heavy Ink** | `heavyInk` | GREED | H/S/O | 🟡 | Combo pts >3 add +10% each to the next finisher; one decays per missed beat. |
| **THE CODA** (keystone) | `theCoda` | RULE | elite | 🟡 | Max-combo Evis inside an Opening echoes as a second free finisher. |
| **EXSANGUINATE** (keystone) | `exsanguinate` | RULE | elite | 🟡 | Evis consuming 5+ bleeds erupts as a 3-beat chained blood-burst (engine-free; no boss stagger). |
| **The Deep Cash** (rig WHEN) | `deepcash` | — | — | 🟡 | WHEN I consume 4+ bleeds in one Evis (~×4.5). |
| **THE SET PIECE** (signature CD) | `setPiece` | STRAT | baseline | 🟡 | ~1-min CD: marks a 4-beat PHRASE; all Perfect+ = a build-scaled flourish. The DECK-LAYOUT §5 slot's first shape. |

**Status-change proposals (Bill's call, §17 trim table):** Momentum/`flowCap` 🔨→🔮 · Da Capo 🔨→🔮 ·
Efficiency 🔨→🔮 (or keep, park Encore) · Held Breath (creed) 🔨→🔮 · On the Beat stays 🟡 candidate.

## ALCHEMIST · THE CASK — **✅ LOCKED SLATE (hard-copied D4, 2026-07-10) + additive kits 🟡**

Source: `ALCHEMIST-PLAN.md §7` (24 KEEP / 6 CUT, Bill 2026-07-07 — ✅ = approved, flips 🔨+SHA as
slices 3–5 build) + `§9`/`§11` (ladders + additive kits). Ladders: **BLEND LINE · GAUNTLET ·
TAP LIST** (§9.1).

| Card | id | Type | Rarity | St | Ladder | One line |
|---|---|---|---|---|---|---|
| The Solera (creed) | `solera` | EASE | curated | ✅ | Blend | Casks never sour; max 4 doses, proof cap 4. |
| The Overproofer (creed) | `overproofer` | GREED | curated | ✅ | Tap List | Cook ×0.5, window ×0.6, peak-taps +30%; a dump crashes proof. |
| The Single Malt (creed) | `singlemalt` | STRAT | curated | ✅ | Gauntlet | Strain softened ×0.91; swaps relieve NOTHING. |
| ⭐ The Blend (module) | `blend` | RULE | — | ✅ | Blend | No taps — batches pour into ONE compounding master blend; dumps TAINT it. |
| The Cellar (module) | `cellar` | STRAT | — | ✅ | Tap List | Bottle peaks (shelf 2), throw on demand. |
| The Copper Still (module) | `copperstill` | GREED | — | ✅ | any | RACK stir-beats: +quality, +cook, faster sour. |
| Master's Measure | `mastersmeasure` | POWER | H/S/O | ✅ | Gauntlet | Perfect+ pours +10/15/22% volume. |
| Heavy Hand | `heavyhand` | POWER | H/S/O | ✅ | Gauntlet | Max doses +1/+1&bigger/+2. |
| Iron Wrist | `ironwrist` | EASE | H/S/O | ✅ | Gauntlet | Strain shrink ×0.86/0.88/0.90. |
| Momentum Pour | `momentumpour` | GREED | H/S/O | ✅ | Gauntlet | +6/9/13% volume per strain level on that dose. |
| Clean Break | `cleanbreak` | STRAT | H/S/O | ✅ | generic | First pour after a swap +20/30/45% volume. |
| Slow Proof | `slowproof` | GREED | H/S/O | ✅ | Blend | Cook +25%, tap +30/40/55%. |
| Cooper's Ear | `coopersear` | EASE | H/S/O | ✅ | generic | Peak window +0.3/0.45/0.6s. |
| Breathe | `breathe` | EASE | H/S/O | ✅ | generic | Cook −0.8/1.2/1.6s. |
| Overproof | `overproofboon` | STRAT | H/S/O | ✅ | Tap List | Late taps BURN (60/70/80% + DoT) instead of souring. |
| Long Echo | `longecho` | POWER | H/S/O | ✅ | Blend | Tails +40/60/90%. |
| The Finisher | `finisher` | POWER | H/S/O | ✅ | Tap List | V finish ×1.4/1.5/1.65 · R tail ×2.5/3/3.5. |
| Killing Vintage | `killingvintage` | STRAT | H/S/O | ✅ | Blend | Below 20/25/33% boss HP casks never sour. |
| ✦ A Round for the House | `roundhouse` | TEAM | H/S/O | ✅ | Tap List | Peak taps buff party +3/4.5/6% for 4s (buff-channel debt). |
| rig: strain-×3 pour | `rig_strain3` | — | ~2.2 | ✅ | Gauntlet | WHEN I land a strain-×3 pour. |
| rig: 6-dose seal | `rig_seal6` | — | ~3.5 | ✅ | Gauntlet | WHEN I seal a 6-dose cask. |
| rig: dead-center tap | `rig_deadcenter` | — | ~5 | ✅ | Tap List | WHEN I tap dead-center. |
| 👑 THE CENTURY CASK | `centurycask` | RULE | elite | ✅ | Gauntlet | Dose cap GONE; +8%/dose past 6; strain never relieves past 6. |
| Spitfire (carry) | `spitfire` | — | — | ✅ | generic | The off-brew dart; the designated interrupt carrier. |

**Additive kits (D4/§11 — 🟡 pending Bill's §9 picks; ranking was H · T · R):**

| Card | id | Type | Rarity | St | Kit | One line |
|---|---|---|---|---|---|---|
| Double Barrel (module) | `doublebarrel` | STRAT | — | 🟡 | T | The second cask slot (the parked candidate, homed). |
| Clean Handoff | `cleanhandoff` | STRAT | H/S/O | 🟡 | T | Sealing during another cook grants that cook +0.3s window. |
| Rolling Boil | `rollingboil` | GREED | H/S/O | 🟡 | T | Two casks live: pours +15%; misses taint the OTHER cask −10%. |
| THE BOTTLING LINE (keystone) | `bottlingline` | RULE | elite | 🟡 | T | Two peak-taps in one 3s window pour as ONE doubled burst. |
| The Signature (creed) | `signature` | STRAT | curated | 🟡 | H | First sealed recipe = the HOUSE recipe; repeats +8%. |
| Practiced Hands | `practicedhands` | STRAT | H/S/O | 🟡 | H | House-recipe pours strain 20% softer. |
| Never Change | `neverchange` | GREED | H/S/O | 🟡 | H | House-style stacks to +30%; off-recipe drops it all. |
| THE DYNASTY POUR (keystone) | `dynastypour` | RULE | elite | 🟡 | H | 4th consecutive clean house batch: the band freezes on your recipe's walk for one stack. |
| On the House | `onthehouse` | TEAM | H/S/O | 🟡 | R | A bottled peak thrown to an ally: 70% as their buff on their next clean hit. |
| Private Reserve | `privatereserve` | GREED | H/S/O | 🟡 | R | Bottles kept 6s+ gain +25%; no second shelf while one waits. |
| CLOSING TIME (keystone) | `closingtime` | RULE | elite | 🟡 | R | Boss Opening: throw the whole shelf; every clean answer under it pays the finish. *(Renamed from Last Call — Brew boon collision.)* |

## ALCHEMIST · THE BREW — 🔨 built · review-pass proposals 🟡
_Stub — back-fill from `ALCHEMIST-PLAN.md §4` (Brew) + `§8` (review-pass verdicts) + `§10`
(ladder filing) + `godot/data/alchemist/*.gd` — D7's job._

## THE WELL — 🔨 deck BUILT (`500334f`) · **BRIM RESHAPE (D5) 🟡 2026-07-10** · Draw reshape = D6

Source: `MENDER-PLAN.md` deck banner (built) + §9/§10.7 (filing) + §11 (the Brim reshape).
Themes: **LOW CATCH · OVERFLOW ENGINE · GLINTSMITH** (the Pulse's cards wait, filed).
*(The old "deck not authored" note was catalog-format drift — the deck was always built; rows
land now. Shared + Brim below; Draw rows arrive with D6.)*

| Card | id | Type | Rarity | St | Theme | One line |
|---|---|---|---|---|---|---|
| The Brink (creed) | `brink` | GREED | curated | 🔨 `500334f` | Low Catch (entry) | Heals scale on the bloodied; the band drops LOW. |
| Foresight (creed) | `foresight` | STRAT | curated | 🔨 | Glintsmith-adj | Pours bank stacks while topped; a dip crashes them. |
| The Levee (creed) | `levee` | EASE | curated | 🔨 | Overflow (entry) | Low band + pours leave an absorb; weaker Glint. |
| The Shallows (creed) | `shallows` | STRAT | curated | 🔨 | Glintsmith (entry) | Tight high band, brighter Glint — glass. |
| ⭐ The Reservoir (module) | `reservoir` | RULE | — | 🔨 | Overflow | Spill banks → SURGE shields → re-bank flywheel. |
| Triage Protocol (module) | `triage` | STRAT | — | 🔨 | Low Catch | Bloodied allies build NERVE → auto LAST STAND. |
| Benediction (module) | `benediction` | STRAT | — | 🔨 | Glintsmith | Good grades light pips; the 5th cashes a party BLOOM. |
| Deep Well · Steady Pulse · Meditate · Warm Rekindle · Boiling Over · Second Ring · Cadence of Mend | — | mixed | H/S/O | 🔨 | generic | The shared/bread set (the Pulse's future material). |
| The Kept Light | `keptlight` | POWER | H/S/O | 🔨 | Glintsmith | Glint lasts longer + extends. |
| Brink Bell | `brinkbell` | EASE | H/S/O | 🔨 | Low Catch | Emergency absorb on an ally dropping low — **the counted pardon (1 total)**. |
| ✦ The Shining Hour | `shininghour` | TEAM | H/S/O | 🔨 | Glintsmith | Warband +dmg while everyone is topped. |
| Overflowing Cup · Still Water | — | STRAT | H/S/O | 🔨 | Overflow | The built spill pair. |
| Low Catch (boon) | `lowcatch` | STRAT | H/S/O | 🔨 | Low Catch | The boon its theme is named for. |
| The Blindfold | `blindfold` | GREED | H/S/O | 🔨 | Glintsmith | Preview OFF, bigger rewards — the greed pole (killed the D5 "Blind Pour" duplicate). |
| High Tide (keystone) | `hightide` | RULE | elite | 🔨 | Glintsmith | A pour Glints the WHOLE party while topped. |
| ~~Wide Brim~~ | `widebrim` | EASE | — | 🔨→**fold** | — | → the EASE dial (widener law) — leaves the pool at reshape. |
| rig: Sweet Pour / Spillover / Low Catch | — | — | — | 🔨 | per theme | The built Brim WHENs. |
| **Knife's Edge** | `knifesedge` | GREED | H/S/O | 🟡 | Low Catch | Band drops another 10%; catches +25%. |
| **Cool Head** | `coolhead` | STRAT | H/S/O | 🟡 | Low Catch | A catch during a boss telegraph string refunds 1 ◍. *(Renamed — Brew P8 owns "Steady Under Fire".)* |
| **THE UNDERTOW** (keystone) | `undertow` | RULE | elite | 🟡 | Low Catch | Three zero-spill catches pull the party's bars up 10% in one wave. |
| **Runneth Over** | `runnethover` | STRAT | H/S/O | 🟡 | Overflow | Spill banks at 130% on Cascade. |
| **Pressure Head** | `pressurehead` | GREED | H/S/O | 🟡 | Overflow | Reservoir over half: pours +1 ◍, Surge ×1.4. |
| **THE FLOODGATE** (keystone) | `floodgate` | RULE | elite | 🟡 | Overflow | Full Reservoir opens as a party shield wall; absorbs re-bank at half. |
| **Whetstone Waters** | `whetstonewaters` | POWER | H/S/O | 🟡 | Glintsmith | Glints +1s, stack to 2 allies. |
| **The Primed Vein** | `primedvein` | STRAT | H/S/O | 🟡 | Glintsmith | PRIME an ally: next landing window ×1.5; a perfect there Glints the party 1s. |
| **THE GILDED HOUR** (keystone) | `gildedhour` | RULE | elite | 🟡 | Glintsmith | All four Glints live: every ally's next clean answer crits. |

**DRAW rows (D6 reshape, `MENDER-PLAN.md §12` — themes VIGIL · RAPIDS · EDDY):**

| Card | id | Type | Rarity | St | Theme | One line |
|---|---|---|---|---|---|---|
| The Patient Hand (creed) | `patienthand` | STRAT | curated | 🔨 `500334f` | Vigil (entry) | Overrun becomes a HELD heal, released on the spike. |
| The Long Draw (creed) | `longdraw` | STRAT | curated | 🔨 | Vigil | Slow/big/tight — the Largo mirror. |
| The Narrows (creed) | `narrows` | GREED | curated | 🔨 | Rapids (entry) | Outside the band heals ZERO; in-band much stronger. |
| The Eddy (creed) | `eddy` | STRAT | curated | 🔨 | Eddy (entry) | The band's centre drifts each cast (deterministic). |
| Strong Pull | `strongpull` | POWER | H/S/O | 🔨 | Rapids | Max-Current clean heals +30%. |
| The Millrace | `millrace` | RULE→POWER | elite→H/S/O | 🔨 → **proposed DEMOTE to boon** | Rapids | Every 3rd cast free at full Current — economy in a keystone slot fails the locked bar; the Flume crowns instead. |
| Loose Grip · Short Pour · Cool Hand · Double Draw · Deep Still · Last Drops | — | mixed | H/S/O | 🔨 | effect-filing at build | Banner names only; Short Pour/Loose Grip presumed the Skim's (parked). |
| rig: Clean Draw / High Water / Still Point | — | — | — | 🔨 | per theme | The built Draw WHENs. |
| ⭐ **THE VIGIL** (module) | `vigilmodule` | RULE | — | 🟡 | Vigil | Overruns become HELD heals (~3s, visible tremble→gutter); release instant. |
| **Second Hand** | `secondhand` | STRAT | H/S/O | 🟡 | Vigil | Flash castable while holding. |
| **Ride the Tremble** | `ridetremble` | GREED | H/S/O | 🟡 | Vigil | Held heal +8%/half-second held. *(Renamed — Warden owns White Knuckles.)* |
| **LOOSED AT LAST** (keystone) | `loosedatlast` | RULE | elite | 🟡 | Vigil | Release within 0.2s of the ally's hit = PERFECT INTERCEPT (full heal + 2s shield). |
| **Whitewater** | `whitewater` | POWER | H/S/O | 🟡 | Rapids | Heals +4%/Current stack. |
| **Shoot the Gap** | `shootgap` | GREED | H/S/O | 🟡 | Rapids | At Current 5, Still-Point tags ×1.3. |
| **Eddyline** | `eddyline` | STRAT | H/S/O | 🟡 | Rapids | One undercook/10s downgrades the Current instead of breaking it (still weak, still costs). |
| **THE FLUME** (keystone) | `flume` | RULE | elite | 🟡 | Rapids | Current 5 held 12s → ~6s the river runs white (auto-clean releases), then 0. |
| **Current Reading** | `currentreading` | STRAT | H/S/O | 🟡 | Eddy | First-third drift tags grant +1 Current (the bridge). |
| **Deep Eddy** | `deepeddy` | GREED | H/S/O | 🟡 | Eddy | Drift range doubles; Still-Point tags ×1.5. |
| **THE GLASS RIVER** (keystone) | `glassriver` | RULE | elite | 🟡 | Eddy | Three moving Still-Point tags freeze the water ~5s. |

## BLOOMWEAVER — **ORCHARD CLOCK DECK v0 (D3) 🟡 PROVISIONAL 2026-07-10** · core unpicked

Source of record: `BLOOM-PLAN.md §4` (provisional on core A — Bill's core pick overrides; B/C/D
→ free re-run). Dials: ARC / PEAK / STAGGER / HARVEST / SAP / WILT / TABLE.

| Card | id | Type | Rarity | St | One line |
|---|---|---|---|---|---|
| **Long Summer** (creed) | `longsummer` | EASE | curated | 🟡 | Arcs 20% slower, windows 20% wider — the learner. |
| **Hothouse** (creed) | `hothouse` | GREED | curated | 🟡 | Arcs 25% faster, peaks +20% — the overclocked garden. |
| **Mulchwork** (creed) | `mulchwork` | STRAT | curated | 🟡 | Wilts leave MULCH: next plant there grows 30% faster, peaks +10%. |
| **THE WILD ROWS** (creed) | `wildrows` | RULE | curated | 🟡 | **WILD:** the garden plants itself; your skill = stagger-reading + harvests; +1 arc cap. |
| **The Almanac** (module) | `almanac` | STRAT | — | 🟡 | Forward timeline of the next ~8s of peaks; plants slot into gaps. |
| **The Cider Press** (module) | `ciderpress` | GREED | — | 🟡 | Overripe harvests squeeze into SAP instead of healing. |
| **Deep Roots** | `deeproots` | POWER | H/S/O | 🟡 | Peaks +15/22/30%. |
| **Forced Bloom** | `forcedbloom` | GREED | H/S/O | 🟡 | One unripe harvest per cycle at full value; its next arc wilts 30% faster. |
| **Second Fruit** | `secondfruit` | RULE | H/S/O | 🟡 | A Bullseye harvest replants itself free. |
| **Harvest Moon** | `harvestmoon` | GREED | H/S/O | 🟡 | Peaks within 0.5s of each other pay +20% both — deliberate stagger-collapse. |
| **Heavy Bough** | `heavybough` | POWER | H/S/O | 🟡 | While ≤2 arcs live, peaks +18/26/35% (the ORCHARD lean). |
| **Sugar Run** | `sugarrun` | STRAT | H/S/O | 🟡 | Bullseye harvests +1 Sap. |
| **Deep Cellar** | `deepcellar` | POWER | H/S/O | 🟡 | Sap cap +2. |
| **Root Tithe** | `roottithe` | GREED | H/S/O | 🟡 | Plants cost +1 Sap, heal +25%. |
| **Crop Rotation** | `croprotation` | STRAT | H/S/O | 🟡 | A harvest grants the oldest arc +10% ripeness. |
| **Overplanted** | `overplanted` | GREED | H/S/O | 🟡 | +1 arc cap; ALL arcs 10% faster. |
| **Companion Planting** | `companion` | STRAT | H/S/O | 🟡 | Two arcs may overlap on one ally; the 2nd at half value. |
| **The Clean Pick** (rig) | `cleanpick` | — | — | 🟡 | WHEN: Bullseye harvest (~1.2). |
| **The Full Table** (rig) | `fulltable` | — | — | 🟡 | WHEN: harvest at 4 live arcs (~3.0). |
| **The Rescue** (rig) | `rescue` | — | — | 🟡 | WHEN: peak harvested on an ally <40% HP (~4.0). |
| **FULL BLOOM** (keystone) | `fullbloom` | RULE | elite | 🟡 | 3 Bullseyes in one telegraph cycle → the whole garden ripens; one chord-press. |
| **THE ORCHARD ETERNAL** (keystone) | `orchardeternal` | RULE | elite | 🟡 | A full-table Bullseye plants a GOLDEN arc (re-peaks ~8s) until any WILT ends it. |
| ✦ **Harvest Home** (support) | `harvesthome` | TEAM | — | 🟡 | 3+ arcs harvested within 2s → warband +damage 3s. |
| **THE SEASON** (signature CD) | `season` | STRAT | baseline | 🟡 | ~1min: 6s of double growth + wider peaks — align the orchard with the boss window. |

## FROZEN CLASSES (Bulwark / Bloomweaver)
_Code slate only, not under active planning. Fill on demand from `godot/data/<class>/<class>_boons.gd`.
(Mender / Voidcaller / Reckoner were DELETED whole in THE PURGE 2026-07-10 — their card slates died
with the classes; recover from git history if a future rework wants a reference.)_

---

## CUT LEDGER — do not resurrect

_Cards that were proposed and rejected/superseded. Each keeps a one-line reason so a later session
can't re-propose a dead idea. (Cross-references live tank cut-history in `TANK-PLAN.md:52`.)_

| Card | Class | Cut date | Reason |
|---|---|---|---|
| _(none logged yet — first entry goes here when a `🟡`/`✅` card is cut)_ | | | |
