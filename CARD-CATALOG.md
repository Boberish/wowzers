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
| **Twinfang · Fermata** | rogue | 🔨 built (`f5d5397`) | v5 pool 🔨 cataloged · v6 kits 🟡 (D8) | `FERMATA-V5-BRIEF.md` + `TEMPO-PLAN.md §16/§18` |
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
| ⏱ **EN GARDE** (`engarde`) | STRAT | baseline | 🟡 | _(Was the unnamed "wall" 💡 — designed 2026-07-10, `TANK-PLAN §10.2`.)_ ~1-min challenge, ~4s: melee tempo at you +25% (the invitation), your leaks/slivers HALVED (the old GUARD's mitigation re-homed), clean answers pay DOUBLE flow, a perfect MAIN banks ◆◆; two slips break it early. Never touches targeting — the post-taunt clutch as an AMPLIFIER, never an override. |

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

### Boons — LANE: THE GAZE (aggro — NEW 2026-07-10, `BOSS-PLAN §1` V#9; taunt button deleted, these are the insurance)
| Card (id) | Type | Rarity | Status | Effect |
|---|---|---|---|---|
| **Lodestone** | STRAT | haiku | 💡 | Perfect MAIN restores ×2/×2.5/×3 the base flow spike (the taunt-shaped play, skill-gated — CARRY to Warden). |
| **Hard Stare** | EASE | haiku | 💡 | Flow floor +10/15/20% — your aggro can never fully collapse (peels stay possible, random-targeting doesn't; CARRY to Warden). |

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

### DUELIST · ABILITY TRANSFORMS (`TANK-PLAN §10` — 🟡 2026-07-10 · ≤1/run, Floor-2 ceremony 1-of-3, each a DOOR gating its 2 sub-boons; never a touch target)

| Card | id | Type | Rarity | St | Ladder | One line |
|---|---|---|---|---|---|---|
| **PRISE DE FER** (transform: PARRY) | `prisedefer` | RULE | ceremony | 🟡 | Ironside | A perfect parry SEIZES the bar (hold ≤1.2s, wind drains) → release THROWS it back; scales w/ bar power + hold (cap ≈ counter ×1.5). |
| **Disarm** (door) | `disarm` | STRAT | H/S/O | 🟡 | Ironside | A full-length seize downgrades the boss's next bar one size. |
| **Wrenched Steel** (door) | `wrenchedsteel` | GREED | H/S/O | 🟡 | Ironside | Seize drains wind ×2; the throw +40%. |
| **REMISE** (transform: PARRY) | `remise` | RULE | ceremony | 🟡 | Ghost | Parry = two half-presses: PRIME (~1/3 wind, primed-miss leaks −30%) + COMMIT in-window (rest of cost, full parry+counter). A primed feint costs only the prime. |
| **Second Intention** (door) | `secondintention` | STRAT | H/S/O | 🟡 | Ghost | A committed remise (both presses landed) banks +1◆. |
| **Beat Parry** (door) | `beatparry` | POWER | H/S/O | 🟡 | Ghost | The prime alone deflects harder (−30%→−45% leak). |
| **FLÈCHE** (transform: DUMP) | `fleche` | RULE | ceremony | 🟡 | Headsman | DUMP loads onto your blade (~2.5s); your next PERFECT answer releases it +25%. Expired load: half the ◆ return, rest fizzles. |
| **Running Edge** (door) | `runningedge` | POWER | H/S/O | 🟡 | Headsman | Flèche damage +15/22/30%. |
| **Point in Line** (door) | `pointinline` | STRAT | H/S/O | 🟡 | Headsman | A flèche released on a TALL-bar land staggers the stream half a beat. |

**Rig WHENs added by the doors (wiring-board entries, priced inverse-frequency):** *full-seize
throw* ~×5 · *remise committed on a tall bar* ~×4.5 · *flèche off a perfect answer* ~×5.
**Dancer law:** under the Dancer creed (no parry button) the two parry transforms leave the
Floor-2 offer (`TANK-PLAN §10.4`).

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

## TWINFANG · TEMPO — 🔨 mostly built · **DECK v4 (D0) ✅ GO 2026-07-10** (build brief `TEMPO-D0-BRIEF.md`; duos + Set Piece deferred)
_Built pool: back-fill from `TEMPO-PLAN.md` Appendix A (code-linked ids + SHAs) +
`godot/data/twinfang/*.gd` still owed. **The D0 deck pass (`TEMPO-PLAN.md §17`) proposes the rows
below** — themes **WOUND · EDGE · FINISH (v4 LOCKED, §17.12 GO record)**; every built card filed in §17.3._

**New / changed cards (D0 · ✅ GO 2026-07-10 — flip 🔨+SHA per merged brief slice):**

| Card | id | Type | Rarity | St | One line |
|---|---|---|---|---|---|
| **Uptempo** (creed) | `uptempo` | GREED | curated | ✂️ | CUT at the v4 lock — absorbed by the EASE dial (beat-speed knob, BITE face). |
| **Open Veins** (creed) | `openVeins` | STRAT | curated | ✅ | Bullseyes inscribe a 2-beat BLEED from run start — THE WOUND's entry; no UI at creed level. |
| **Hemorrhage** (module) | `hemorrhage` | STRAT | — | ✅ | The wound counter on the boss frame; bleeds +1 beat; Eviscerate may CASH the pot (+10%/bleed consumed). Builds the unbuilt data. |
| **Lacerate** | `lacerate` | STRAT | H/S/O | ✅ | Perfects also inscribe (half/⅔/full-value bleeds). |
| **Slow Bleed** | `slowBleed` | POWER | H/S/O | ✅ | Bleeds +1/+2/+2 beats & +10% tick (cap 5 beats). |
| **Arterial Note** | `arterialNote` | GREED | H/S/O | ✅ | Bleeds +30/40/55% harder, expire 1 beat sooner. |
| **Through-Line** | `throughline` | STRAT | H/S/O | ✅ | AUTHORED (was design-owed): consecutive Perfect+ +2%/stack cap 5, reset on Miss. |
| **Quickstep** | `quickstep` | GREED | H/S/O | ✅ | Each Perfect speeds AND tightens (~8%) your next window; floor-clamped, taper law. |
| **Grand Pause** | `grandPause` | STRAT | H/S/O | ✅ | A full-combo (5/5) Eviscerate hits +25/30/35% (reworded 07-10 — Bill: "so just full?" Yes; Overkill's over-cap bank is a separate pot). |
| **Heavy Ink** | `heavyInk` | GREED | H/S/O | ✅ | Combo pts >3 add +10% each to the next finisher; one decays per missed beat. |
| **THE CODA** (keystone) | `theCoda` | RULE | elite | ✅ | Max-combo Evis inside an Opening echoes as a second free finisher. |
| **EXSANGUINATE** (keystone) | `exsanguinate` | RULE | elite | ✅ | Evis consuming 5+ bleeds erupts as a 3-beat chained blood-burst (engine-free; no boss stagger). |
| **The Deep Cash** (rig WHEN) | `deepcash` | — | — | ✅ | WHEN I consume 4+ bleeds in one Evis (~×4.5). |
| **THE SET PIECE** (signature CD) | `setPiece` | STRAT | baseline | 🟡 | ~1-min CD: marks a 4-beat PHRASE; all Perfect+ = a build-scaled flourish. The DECK-LAYOUT §5 slot's first shape. |

**Ability audit — PASS 2 (`TEMPO-PLAN.md §17.11`, Bill's steer 2026-07-10 — transforms, not
buttons; the ABILITY-LAW allowance is now +1 and Tempo leaves its slot EMPTY).** Pass-1 spell
flips: Sforzando 🟡→✂️ · The Pickup 🟡→✂️ (+ doors Fortissimo/Marcato ✂️ — all to TEMPO A5) ·
The Count-In 🟡→🔮 (+ doors Section Leader/Tutti Chord 🔮 — the +1 slot's standing candidate) ·
The Rondo (spell) → REBORN below as a Coup TRANSFORM (id kept, button deleted) · The Accent WHEN
✂️ (died with Sforzando) · The Return WHEN survives under the transform.

| Card | id | Type | Rarity | St | One line |
|---|---|---|---|---|---|
| **CADENZA** (Coup transform) | `cadenza` | RULE | 1-of-3 pick | ✅ | Coup castable at Flow ≥2, damage scales with Flow consumed (full-Flow = today's ceiling) — the flexible cash. |
| **THE RONDO** (Coup transform) | `rondo` | RULE | 1-of-3 pick | ✅ | After a Coup, the next 4 beats RETURN: each Perfect+ re-strikes 15% of it (Bullseye 25%). The valley becomes act two. |
| **TREMOLO** (Evis transform) | `tremolo` | RULE | 1-of-3 pick | ✅ | Evis becomes a string: ≤3 presses, 2 combo each, graded per beat; all Perfect+ = final hit +40%. String = ONE finisher for boon math. |
| Dal Segno | `dalSegno` | STRAT | H/S/O | ✅ | Cadenza door: a Cadenza spending 4+ Flow seeds +1 (absorbs Da Capo's job). |
| Bravura | `bravura` | GREED | H/S/O | ✅ | Cadenza door: a full-Flow Cadenza inside an Opening +25%. |
| Second Theme | `secondTheme` | POWER | H/S/O | ✅ | Rondo door: the return % up a tier. |
| Da Capo (un-park) | `daCapo` | POWER | H/S/O | ✅ | Rondo door: +1 Flow seed, verbatim — parks from the open pool, returns behind this door. |
| Triplet | `triplet` | GREED | H/S/O | ✅ | Tremolo door: an all-Bullseye string pays the final hit +40% more (capped). |
| Rolled Chord | `rolledChord` | EASE | H/S/O | ✅ | Tremolo door: string windows pad ENTRY-side only (the widener law). |
| The Return (rig WHEN) | `returnWhen` | — | — | ✅ | WHEN my Rondo phrase returns ≥ half the Coup (~×6.0) — Rondo door. |
| **Whetstone** (creed) | `whetstone` | STRAT | curated | ✅ | v4 EDGE entry: your Bullseyes can crit from run start (small %, ×2) — the creed IS the A7 opt-in. |
| **The Strop** (module) | `strop` | STRAT | — | ✅ | v4 EDGE module: Perfect+ strikes stack KEEN (gauge, cap 5); your next crit consumes all KEEN for +8%/stack. |
| **Resonance** (system) | — | RULE | — | ✅ | **APPROVED 07-10** ("yeah, no set bonus"): 3 cards of one theme auto-light that theme's ONE rotational perk — Wound: after-tick · Edge: a crit steadies the beat · Finish: phrase-mark. Brief slice S2. |
| **THE DUO** (system) | — | RULE | — | ✅ | **APPROVED 07-10** ("yes we need this, make this rich and nice"): armed at ≥2 drafted cards from EACH of two themes → enters Opus offers, two-tone frame; rewards MIXING (resonance rewards depth — opposed pulls by design). Brief S3. |
| **Blood Coda** (duo) | `bloodCoda` | RULE | H/S/O | 🟡 | Wound×Finish: an Evis cashing 4+ live bleeds at full combo pays both ×1.15/1.25/1.4 — the burst paints the phrase-mark red. |
| **The Red Edge** (duo) | `redEdge` | RULE | H/S/O | 🟡 | Wound×Edge: every CRIT pulses ALL live bleeds one immediate extra tick — crit-fish while the pot is fat, against expiry. |
| **Grand Finale** (duo) | `grandFinale` | RULE | H/S/O | 🟡 | Edge×Finish: a full-combo finisher with the crit build hot is a GUARANTEED crit +50% crit dmg; the screen holds a half-beat on the number. |
| **The Reprise** (duo) | `reprise` | RULE | H/S/O | 🟡 | Rondo-transform×Wound: during the Return, each re-strike re-opens one expired bleed — transforms join the duo grammar. |
| **DOUBLE TIME v2** (keystone) | `doubleTime` | RULE | elite | ✅ | v1 beat-doubling CUT at the governor wall; v2 = ~8s of optional ghost half-beat pips, each landed = a free half-strike. **v4 re-slots it CLASS-generic** (Syncopation's shelf, not a branch capstone). |

**v4 branches ✅ LOCKED (GO, §17.12): WOUND · EDGE · FINISH; SWIFT demoted to generics** — Uptempo
(creed) ✂️ absorbed by the EASE dial (beat-speed knob, BITE face) · Quickstep + Through-Line
stay as generic STRIKE boons (governor-clamped) · the A7 three (Heartseeker/Serrated/Assassin's
Note) become EDGE's ladder boons unchanged (already offer-gated on a crit source).
**PASS-3 verdicts folded (07-10, Bill's artifact notes — §17.12):** SPEED GOVERNOR ✅ ("good",
a law — tracked in ledger/brief S0) · Resonance ✅ · Duo system ✅ + the rich slate above 🟡 ·
Pickup cut CONFIRMED · **NO-SINGLE-NEXT-HIT LAW** → `fencersLine` 🔨→REWORK 🟡 ("a Bullseye
widens your windows for the next 3 strikes") · `killingEdge` fallback → "next 3 strikes" ·
Count-In's parked text → the call covers 4 beats. **Build brief on main: `TEMPO-D0-BRIEF.md`.**
**Trim CONFIRMED (GO):** Momentum 🔨→🔮 · Held Breath 🔨→🔮 · Efficiency 🔨→🔮 (**Encore KEPT** —
the stated lean taken, cheap veto) · On the Beat stays 🟡 (unverdicted). **DUOS DEFERRED:**
system ✅ stands, the 4 duo cards stay 🟡 for the later wave (Bill: "save that for later"). **Role flag (still open):** Evis = standard interrupt
carrier + Coup = premium kick — pillar-#3 proposal 🟡.

## TWINFANG · FERMATA — 🔨 v5 BUILT (`f5d5397`) · **v6 KITS (D8) 🟡 2026-07-10**

Source: `FERMATA-V5-BRIEF.md` (the build truth) + `TEMPO-PLAN.md §16` (ladders) + `§18`
(assembly). Ladders: **BRINKMAN · RESTED BLADE · WINDOW-SETTER**.

**v5 pool (🔨 `f5d5397`, ladder-tagged):** creeds the Long Ramp [Brinkman entry] · Fleeting
Shade · Long Night · Tutti [wild] — modules ⭐Shadow Dance (no-snap fever) · the Mark — boons
stretto/refrain [Window-Setter] · coldCut [Cold Hand anchor] · theBrink/killingWhisper/
quietFuse [Brinkman] · firstNote/composure/restlessDark [Rested Blade] · vanish (the one
block) · twinEcho/firstBlood · ✦veilWarband [TEAM] — rig rested/razor/unravel — keystones
unseenBlade [Rested Blade] · eclipse [Window-Setter] · phantom [Afterimage anchor].

**v6 kits (🟡 — §16 ranking: Cold Hand · Afterimage):**

| Card | id | Type | Rarity | St | Kit | One line |
|---|---|---|---|---|---|---|
| The Doubled Dark (creed) | `doubleddark` | STRAT | curated | 🟡 | A | Twin Echo at half strength from run start. |
| Deep Shadow | `deepshadow` | POWER | H/S/O | 🟡 | A | Echoes inherit depth — a Bull's echo echoes at 45%. |
| Procession | `procession` | GREED | H/S/O | 🟡 | A | Consecutive Perfect+ releases add +1 echo to the NEXT (cap 3); snap/unravel clears. |
| THE COMPANY OF KNIVES (keystone) | `companyknives` | RULE | elite | 🟡 | A | Full-procession Bullseye: every banked echo flies, graded half-steps softer. |
| Kept Books (creed) | `keptbooks` | STRAT | curated | 🟡 | C | Good-band releases +1 CP from run start. *(Renamed from The Ledger — Duelist's Red Ledger family.)* |
| Patient Books | `patientbooks` | STRAT | H/S/O | 🟡 | C | Evis at 5 CP consumes the Mark at +1 tier. |
| No Flourishes | `noflourishes` | GREED | H/S/O | 🟡 | C | While your Brink is 0 (never built), Evis +25% — the chosen shallow book. |
| THE RECKONING STROKE (keystone) | `reckoningstroke` | RULE | elite | 🟡 | C | Tier-III brand + 5 CP + an Opening: one still frame, then the number. *(Freeze-beat rhyme w/ Estocada — at Bill from D2.)* |

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
| Muscle Memory | `musclememory` | STRAT | H/S/O | 🟡 | H | House-recipe pours strain 20% softer. *(Renamed from Practiced Hands — Brew's built Practiced Hand owns the family, D7.)* |
| Never Change | `neverchange` | GREED | H/S/O | 🟡 | H | House-style stacks to +30%; off-recipe drops it all. |
| THE DYNASTY POUR (keystone) | `dynastypour` | RULE | elite | 🟡 | H | 4th consecutive clean house batch: the band freezes on your recipe's walk for one stack. |
| On the House | `onthehouse` | TEAM | H/S/O | 🟡 | R | A bottled peak thrown to an ally: 70% as their buff on their next clean hit. |
| Private Reserve | `privatereserve` | GREED | H/S/O | 🟡 | R | Bottles kept 6s+ gain +25%; no second shelf while one waits. |
| CLOSING TIME (keystone) | `closingtime` | RULE | elite | 🟡 | R | Boss Opening: throw the whole shelf; every clean answer under it pays the finish. *(Renamed from Last Call — Brew boon collision.)* |

## ALCHEMIST · THE BREW — 🔨 BUILT (`alch-cards`) · §8 proposals + D7 kits 🟡 (one merged board)

Source: `ALCHEMIST-PLAN.md §2–§4` (built) · §8 (11 proposals) · §10 (ladders) · §12 (assembly).
Ladders: **SLOW BOIL · CANNONADE · ANCHOR**.

**Built pool (🔨 `alch-cards` 2026-07-06, ladder-tagged):** creeds Steady Hand [EASE·generic] ·
Volatile Mix [GREED·Cannonade entry] · Anchorite [STRAT·Anchor entry] · Purist [RULE·Slow Boil
entry] — modules Third Reagent [STRAT] · Fermentation [STRAT — P6 fix pending] · ⭐Reaction-
Vessel [RULE·Cannonade] — boons: FUEL Deep Cauldron/Preservative/Clinging Rot [Anchor] · VIAL
Steady Pour/Practiced Hand · POTENCY Quick Study/Distilled Focus/Concentrate/Killing Draught
[Anchor] · REACTION-RUPTURE Corrosive Blood/Deepening Rot/Perfect Emulsion [Slow Boil] ·
Rupturing/Chain Rupture/Catalyst/Volatile Reaction [Cannonade] · ✦Debilitator [TEAM] · Last
Call — spells Spitfire (interrupt carrier) / Decant / Reduction — the 6×6 rig board.

**§8 proposals (🟡 at Bill's board, slotted):** P1 Bullseye Pours [verb] · P2 Master's Draught
[Gauntlet-rhyme, VIAL] · P3 The Red Line [Cannonade keystone] · P4 Quicksilver [Anchor
keystone] · P5 Seething Vial [Slow Boil keystone] · P6 Fermentation hold-or-cash · P7 Strike
the Seam [Cannonade] · P8 Steady Under Fire [F3-probe] · P9 Brimming [Slow Boil GREED] ·
P10 The Fever [creed slot].

**D7 additive kits (🟡 — §10 ranking G · P · S):**

| Card | id | Type | Rarity | St | Kit | One line |
|---|---|---|---|---|---|---|
| The Wire-Walker (creed) | `wirewalker` | STRAT | curated | 🟡 | G | Low catches pay from run start; both-sides-low doubles (and risks all). |
| The Save | `thesave` | GREED | H/S/O | 🟡 | G | A catch under 2 units: +30% fuel back; hitting ZERO crashes Potency. |
| Practiced Wobble | `practicedwobble` | STRAT | H/S/O | 🟡 | G | After a low catch, balance window +15% for 4s. |
| THE PENDULUM (keystone) | `pendulum` | RULE | elite | 🟡 | G | 3 alternating low catches in one Potency cycle: ~6s of ×1.5 balance, bars swing in counterphase. |
| Venom-Tipped | `venomtipped` | STRAT | H/S/O | 🟡 | S | A dart during a fed, balanced reaction carries 20% of its tick. |
| Quick Draw | `quickdraw` | GREED | H/S/O | 🟡 | S | Darts drain 1 vial charge — fuel for tempo, per throw. |
| The Silencer | `silencer` | STRAT | H/S/O | 🟡⏸ | S | A dart that KICKS refunds potency drain 3s — parked on the pillar-#3 flag. |
| THE FUSILLADE (keystone) | `fusillade` | RULE | elite | 🟡⏸ | S | Post-kick ~4s: darts chain — parked on the pillar flag. |
| The Diagnostician (creed) | `diagnostician` | STRAT | curated | 🟡 | P | Boss HP milestones marked; a Rupture within 2s of one +15%. |
| Terminal Course | `terminalcourse` | POWER | H/S/O | 🟡 | P | Below 30% boss HP, Deepening Rot ramps ×2. |
| Called Shot | `calledshot` | GREED | H/S/O | 🟡 | P | Auto-declared Rupture budget: finish at-or-under = each +20%; over = excess −20%. |
| THE AUTOPSY REPORT (keystone) | `autopsyreport` | RULE | elite | 🟡 | P | A milestone-window killing Rupture: next fight opens +2 Potency. |

**Cross-spec renames executed this pass:** Cask kit-H *Practiced Hands* → **MUSCLE MEMORY**
(the Brew's built Practiced Hand owns the family) — veto restores.

## THE WELL — 🔨 deck BUILT (`500334f`) · **BRIM RESHAPE (D5) 🟡** · **DRAW: D6 reshape + SKIN 🔨 BUILT `ed358aa` (transforms 🟡 deferred)**

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
| The Millrace | `theMillrace` | POWER | H/S/O | 🔨 `ed358aa` | Rapids | **DEMOTED to boon (opus→sonnet).** Every 3rd cast free at full Current — honest economy; the Flume is crowned the Rapids keystone. |
| Cool Hand · Double Draw | — | mixed | H/S/O | 🔨 | generic | Release bread (untagged). |
| ~~Loose Grip · Short Pour~~ | — | EASE | — | 🔨→**park** | — | The SKIM pair — LEFT the offer pool (machinery guarded-kept); a wider band is the EASE dial's job. |
| rig: Clean Draw / High Water / Still Point | — | — | — | 🔨 | per theme | The built Draw WHENs. |
| ⭐ **THE VIGIL** (module) | `vigil` | RULE | — | 🔨 `ed358aa` | Vigil | Overruns become HELD heals (~3s, tremble→gutter); release instant. Draw-only offer; arms the hold via `_hold_armed()`. |
| **Second Hand** | `secondHand` | STRAT | H/S/O | 🔨 `ed358aa` | Vigil | Flash fires INSTANTLY while a held heal is cocked (keeps the one casting slot). |
| **Ride the Tremble** | `rideTremble` | GREED | H/S/O | 🔨 `ed358aa` | Vigil | Held heal +8%/half-second held (cap +60%). |
| **LOOSED AT LAST** (keystone) | `loosedAtLast` | RULE | elite | 🔨 `ed358aa` | Vigil | Held release within 0.2s of the ally's hit = intercept (full heal + a 2s absorb; reads the guarded `last_hit_tick`). |
| **Whitewater** | `whitewater` | POWER | H/S/O | 🔨 `ed358aa` | Rapids | Clean/still heals +4%/Current stack. |
| **Shoot the Gap** | `shootGap` | GREED | H/S/O | 🔨 `ed358aa` | Rapids | At MAX Current, Still-Point tags ×1.3. |
| **Eddyline** | `eddyline` | STRAT | H/S/O | 🔨 `ed358aa` | Rapids | One undercook/10s downgrades the Current instead of breaking it (still weak, still costs). |
| **THE FLUME** (keystone) | `flume` | RULE | elite | 🔨 `ed358aa` | Rapids | MAX Current held 12s → ~6s all releases auto-clean, then Current 0. |
| **Current Reading** | `currentReading` | STRAT | H/S/O | 🔨 `ed358aa` | Eddy | A tag in the band's first-third → +1 extra Current (the bridge). |
| **Deep Eddy** | `deepEddy` | GREED | H/S/O | 🔨 `ed358aa` | Eddy | Drift range ×2; Still-Point tags ×1.5. |
| **THE GLASS RIVER** (keystone) | `glassRiver` | RULE | elite | 🔨 `ed358aa` | Eddy | Three Still tags in a row → ~5s frozen drift + all-Still grading. |

**DRAW ABILITY PASS rows (`MENDER-PLAN §13` · **SKIN 🔨 BUILT `ed358aa`** — the transforms +
doors stay 🟡, S3 DEFERRED until the `tempo-d0` Floor-2 ceremony merges; each is a DOOR gating
its 2 sub-boons):**

| Card | id | Type | Rarity | St | Theme | One line |
|---|---|---|---|---|---|---|
| **SKIN** (base cast) | `skin` | — | base book | 🔨 `ed358aa` | shared book | Quick cast (1.4s), 1 ◍, graded release: ~6s the ally wears the water's skin — a share of each hit DEFERS into a ~3s drip (clean 35% · plain 20% · Still Point 45% + Glint). Never absorbs, never heals — re-times damage (CombatCore `_tick_skin` drains it as late damage). Draw-graded / Brim-plain. No stacking; recast refreshes. `SPELL_CAP` 8→9 (skin didn't crowd a spell; 8-cap trim PARKED). |
| **CUPPED HAND** (transform: Flash) | `cuppedhand` | RULE | ceremony | 🟡 **(S3 deferred — blocks on tempo-d0 Floor-2 ceremony)** | Rapids | Flash may be thrown FROM the Current: spend 1 stack → lands instantly, ungraded (plain, never clean/Glint), no cast bar. Never feeds the Current. |
| **Handful After Handful** (door) | `handfulafter` | POWER | H/S/O | 🟡 | Rapids | Cupped flashes +15/22/30%. |
| **Return to the River** (door) | `returnriver` | STRAT | H/S/O | 🟡 | Rapids | A clean release within ~2s of a cupped flash restores the spent stack. |
| **THE DEEP DRAW** (transform: Mend) | `deepdraw` | RULE | ceremony | 🟡 | Vigil | Mend gains a second band past clean: catch the DEEP band = ×1.6; past it = GUTTER (charge+cast lost — the free overrun is surrendered by drawing past). ⭐Vigil held: a missed deep band becomes a plain HELD heal instead. *(Name-family check: built `deepwell`/`deepstill`/`deepeddy` are distinct ids; the Long Draw creed is the run-long temperament, this is the per-cast gamble — recorded.)* |
| **Pearl Diver** (door) | `pearldiver` | GREED | H/S/O | 🟡 | Vigil | Deep band −30% size, pays ×2. |
| **Came Up Singing** (door) | `cameupsinging` | STRAT | H/S/O | 🟡 | Vigil | A caught deep band grants +2 Current (the Vigil↔Rapids bridge). |
| **THE BRAID** (transform: Cascade) | `braid` | RULE | ceremony | 🟡 | Eddy | Cascade's 3 arcs become 3 graded releases (one band each); all-clean → 3rd arc +40%. ONE cast for boon/charge math; grades per press; Current gain caps +1/string. |
| **Tight Braid** (door) | `tightbraid` | GREED | H/S/O | 🟡 | Eddy | Arc bands −25%; all-clean bonus +40%→+70%. |
| **Crossing Streams** (door) | `crossingstreams` | STRAT | H/S/O | 🟡 | Eddy | Each arc re-aims at release to the current lowest ally. |

**Rig WHENs added by the doors:** *cupped flash lands on an ally <30%* ~×4.5 · *deep band
caught* ~×4 · *all-clean braid* ~×5.

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
