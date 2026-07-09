---
name: deck-creator
description: Design or redesign a class/spec card deck (creeds, modules, boons, rig, keystones) for Project Rift. Encodes the Framework-v2 slots, Bill's fun laws (pick-tension first, greed over insurance, spectacle keystones), the anti-pattern list from his real cut history, and the design→verdict→build process. Invoke before authoring ANY card slate.
---

# DECK CREATOR — the card-design playbook

You are designing a deck for one spec of one class. The deck is not a list of bonuses;
it is a set of DECISIONS the player will be forced to make under pressure. Read the class's
plan doc (`TEMPO-PLAN.md` / `ALCHEMIST-PLAN.md` / `MENDER-PLAN.md` / …) and its verdict
history in MASTER-PLAN before writing a single card.

## 0 · The slots (Framework v2 — what a deck contains)

| Slot | Count | What it is | Law |
|---|---|---|---|
| **Creeds** | 3–5, pick 1/run | A run-long temperament that reshapes the spec's risk | Curated, never rarity-rolled. Include: one forgiving/crossover, one greed pole, one rhythm-changer, and **one WILD creed that rewrites the core mechanic** (Tutti-class) |
| **Modules** | 2–3, Floor-1 pick | A new UI dynamic — a gauge that adds a way to play | Exactly **one ⭐ transformer** per class (Overdrive/Shadow Dance-class: fills → a temporary transformed state → crashes). A module must EARN its pixels — "a passive, not extra UI" gets cut |
| **Boons** | 10–16 | The draftable pool, in LANES named after the core mechanic's dials | Every card names the dial it touches (the address rule). Each lane: ≥1 greed card, ≤1 insurance card |
| **Rig** | 2–4 WHENs | Earned MOMENTS that plug into the class THEN table | A WHEN must be *chooseable or earnable*, never a passive roll; rare WHENs pay premium by construction |
| **Keystones** | 2–3 | Build-definers dropped by ELITES only, never normal drafts | **Spectacle-grade, never a stat.** Bill's bar: "keystones need to be way more fun than open kick window." If it doesn't change how the bar/minigame LOOKS in play, it isn't a keystone |
| **Support** | 1 | The party-facing identity card | Keyed to the spec's core state (uptime IS the buff) |
| **Carries** | listed | Cross-spec cards that work VERBATIM on both specs | Verify each against the new core mechanic — no "mostly works" |

Curios are the only cross-CLASS lane and never touch the core mechanic. Spell/extra-button lanes are
dead ("I don't like flurry, or grace note, or coda") — new buttons need a class-law reason. **⚠ 2026-07-09 reconcile → `DECK-LAYOUT.md`:** the class-law bar is cleared by (a) the **signature ~1-min CD** (one sanctioned baseline button per class) and (b) a **broad-kit class** spending its budget on breadth (the healer's heals). `DECK-LAYOUT.md` is now the canonical anatomy (it adds the CD slot + the branches / 3-axes model) and wins on any diff with this table.

## 1 · THE PICK-TENSION LAW (the prime directive)

A card must REALLY want to be picked. **The longer the player hovers between three offers,
the better the slate.** You are not designing cards; you are designing the moment of choice.

- Before shipping, run the **offer-trio test**: deal yourself 5 random 3-card offers per
  rarity tier. If any trio has an auto-pick, that card is too strong or the other two are
  dead — fix the trio, not just the card. If any trio has an auto-skip, cut or spice it.
- Auto-picks that deserve to exist (true build-definers) don't get nerfed — they get
  **moved out of the draft** to elites/keystones ("why would you pick something else?").

## 2 · The fun hierarchy (what makes a card want to be picked)

1. **GREED** — more damage, more risk, more reward. The dial the player turns themselves.
2. **Payoff / spectacle** — a moment that looks and feels enormous when earned.
3. **Control** — agency over the core mechanic's randomness (rerolls, placement bias, pins).
4. **Tempo/pacing** — cards that let the player choose their cadence.
5. **Bread** — honest numeric food (haiku tier). Allowed, but even bread leans toward a build.
6. **Insurance** — "cover my mistakes." The LEAST fun shape. Never ship it raw.

**The insurance rule:** if the class needs a defensive/forgiveness effect, dress it as a
play, not a pardon. Vanish is an auto-dodge that lives inside the stealth fantasy;
Understudy is a groove-save with a recharge rhythm; a block should WANT something (store
the blocked hit and return it) rather than just subtract. If you catch yourself writing
"when you fail, it hurts less" — rewrite it as "here is a move you can make."

## 3 · The anti-pattern list (real cuts, Bill's words — check every card against these)

- **Passive wind-ups**: "Opportunist — winds up is meh." Waiting is not a mechanic.
- **Passives wearing UI**: "Deathmark — a passive, not extra UI." A gauge must create decisions.
- **Stat keystones**: Nightfall (boss wind-ups 12% slower) — cut. "Way more fun" is the bar.
- **One-time bonuses**: invisible in a 60s fight → cut. Effects must bend MANY attacks.
- **Oversized single knobs**: Fencer's Line at +60% — "too big, make it like +35% max."
- **Extra buttons**: the whole spells lane died. New inputs need a class-law reason.
- **Un-graspable rules**: "i dont get it" = death (Shadowmeld). If WHAT needs two sentences,
  the card is too clever. One clear line, then depth.
- **Insurance stacking**: two+ pardon-cards in one lane reads as a coward's build. Max one.
- **Luck wearing greed's clothes**: a bonus keyed to a ROLL the player didn't influence is a
  lottery ticket, not greed (the Fermata far-window stopgap). Greed must be CHOSEN per use.

## 4 · Coherence (the deck as one object)

- **Write the DIALS list first.** Enumerate what the core mechanic lets a card touch (for Fermata:
  the roll, the ride-depth, the snap, the rest, the draw, the release grade, Flow). Every
  card addresses exactly one dial; the lanes ARE the dials, so the deck teaches the model.
- **Design in polarity pairs.** Every axis gets two poles a build can commit to
  (near/far, fast/slow, safe-shallow/deep-greed). A pole without an opposite is a default.
- **2–4 constructible archetypes.** Name them while designing (e.g. "the speed knife:
  Stretto+Fleeting+Eclipse" / "the slow nuke: Knife+Unseen Blade+First Note"). If a card
  belongs to no archetype and no trio-dilemma, it's ballast.
- **Cross-reference moments.** The rig's WHENs should be moments other cards create; a
  keystone should make 2–3 pool boons light up differently. Synergy is written, not hoped.
- **When the core mechanic changes, run the BROKE / FADED / DEAD / OPENED sweep** over the whole
  deck: what leaned on the old rule (broke), what lost its bite (faded), what can no longer
  trigger (dead), and which NEW dials opened that nothing uses yet. New cards go in the
  opened space first.

## 5 · Numbers & rarity

- Every card ROLLS Haiku/Sonnet/Opus per offer. Numeric cards scale the number; rule-changer
  cards scale via authored RUNES (H = the rule; S/O add a rider, never a bigger rule).
- State the cap on every scaling effect (~+20–35% ceilings for window/damage riders).
- Multipliers and standing meters over procs; nothing hard-coded — every number is a config
  knob on the class config (sims sweep it).
- Wideners/forgiveness effects TAPER with power (help the cold player, not the hot one),
  and under edge-graded mechanics they extend the SAFE side only — never move the payoff lip.

## 6 · Process (design → verdict → build)

1. Read the plan doc + the verdict history. List the core mechanic's dials. Note standing laws.
2. Draft the slate per the quotas above. Tag every card with exactly ONE **TYPE** from the
   shared vocabulary (same meaning across every class — Bill classifies at a glance):
   **POWER** (just bigger numbers — the bread) · **GREED** (risk more for more; bites when you
   overreach) · **STRAT** (rewards a specific plan or clever play) · **EASE** (**the difficulty
   dial** — see below) · **RULE** (changes a rule of the minigame — ⭐transformers and keystones
   live here) · **TEAM** (helps the whole warband — the one support card).
   **EASE = the difficulty dial (redesigned 2026-07-09).** Do NOT author a stack of flat "wider
   window / slower beat" comfort cards (easy to write, dull to draft, floods the pool). Author
   **one dial archetype**: on drop it **rolls 2–3 of the class's knobs**; the player takes ONE and
   slides it **COMFORT** (wider/slower/more grace, **damage-neutral** — free, cost is the slot) or
   **BITE** (tighter/faster/less grace, **+damage** that only pays if they can hit it — a real
   whiff-gamble, GREED-adjacent). The roll sets *which knobs are offered*; the *direction is always
   chosen* (so it never trips "luck wearing greed's clothes"). Comfort still caps (diminishing
   returns) and tapers with power. Full spec: `DECK-LAYOUT.md §4`.
   Finer intent words (speed, control, comeback, build-around…) go in the WHY text, not pills.
3. Self-audit: anti-pattern list (§3), offer-trio test (§1), archetype check (§4),
   BROKE/FADED/DEAD/OPENED if the core mechanic moved.
4. Ship a **verdict artifact**: interactive KEEP/TWEAK/CUT cards with **WHAT / WHY / FEELS**
   + one colored TYPE pill + status chips (STANDS/REWORKED/NEW) + an export blob.
   **Plain language everywhere** — write effects in the game's own words, gloss every mechanic
   term, and open the page with a short "the words, quickly" glossary + a loop refresher
   (Bill juggles several classes; a board that needs design lingo to read is a failed board).
   Bill verdicts; you fold.
5. **Hard-copy the slate into `CARD-CATALOG.md` BEFORE building** (context dies; docs don't) — one
   row per card in the canonical format, each tagged with its status glyph (💡/🟡). That doc is THE
   single source of truth for every card's design + status; flip statuses there in the same commit
   as Bill's verdict (🟡→✅) and again when built (✅→🔨+SHA). The class plan doc keeps only the
   rationale / minigame design, not the slate. (See `CARD-CATALOG.md` header + CLAUDE.md CARD-TRACKING LAW.)
6. Build kit-local and aspect-gated (byte-identical when unpicked), knobs on the config,
   sim probe cells per creed/module/build, determinism PASS, then the HUD slice.
7. Feel questions that split 50/50 become dev-toggle A/Bs in a tester, never debates.
