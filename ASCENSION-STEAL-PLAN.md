# Ascension → Rift: Design Steal-List & Plan Seed

**Purpose:** capture what we're taking from Project Ascension / *Conquest of Azeroth* (a classless WoW private server, CoA launched 2026-07-03) and turn it into a real milestone plan. This file is the **decisions of record** from the research session; the next step is to expand it into a `PORT-PLAN.md`-style milestone plan.

**Rift in one line:** co-op roguelike, MMO-trinity combat with *movement removed* → replaced by *timed active decisions*; one verb per role; run = pick 1-of-2 Aspect at start → chain 5 bosses → draft 1-of-3 boons between fights. 5 classes + 2nd healer done; M7 Strings (graded defense) roster-wide; R0/R1 co-op raid playable.

**Core research finding:** Ascension's genius is NOT "random spells" — it's the **anti-feelbad + build-as-assembly philosophy**: power = many small standalone modifiers that recombine *with no lockouts*, plus systems that keep randomness fair and steerable (Synergy rolls, pity/bad-luck protection, rarity-as-frequency, reroll currency, slot-based enchants). We're fundamentally different (fixed roles, execution-driven), so we steal the *philosophy*, not the classless structure.

---

## Decisions made this session
- **GREENLIT (near-term):** Synergy draft picks + Transform boons.
- **CORE evolution (the big bets):** Slot-based "build-your-verb" + Skill-minted draft currency, wrapped by Rarity-as-chase.
- **REFRAMED:** difficulty modifiers → a **Trial Ladder** (Mythic+-style: replay bosses at ascending tiers, harder + better rewards). Higher tier ADDS MECHANICS (string beats/feints/new phase), not just +HP.
- **PARKED:** Chronomancer-style "rewind" verb. Cool tech (our deterministic engine could do it cheaply), but erasing a misread undercuts a reaction game. Revisit only as a rare boon/relic, not a core verb.

---

## The shortlist (each: idea → Rift translation → where it touches)

### 1. Synergy draft picks  *(GREENLIT, small)*
Ascension: periodically the draft isn't pure-random — it picks an ability you **already own** and offers a talent that **specifically buffs it** (bad-luck protection: a rolled-off synergy won't recur for ≥25 rerolls; synergy chance rises each roll until one fires).
- **Rift:** tag each boon with the verbs/gauges/boons it interacts with. When building the 1-of-3 draft, force one slot to be a boon whose tags intersect the current build. Fixes incoherent random drafts — the #1 weakness of a random-boon roguelike.
- **Touches:** `data/*/*_boons.gd` (add interaction tags), the draft-builder in the run loop (`RunState` / HUD draft screen), `game/ui/relic_card.gd`.

### 2. Transform boons  *(GREENLIT, content)*
Ascension: top-rarity power = your ability **becomes a different ability** (Legendary enchant replaces a spell with a transformed version), not "+8%".
- **Rift:** make the top of every class's boon pool **transform the verb** (e.g. Guard → reflect; kick → also silence). We already do this in exactly one place (Twinfang Flow-tier transforms; Aspects). Lean into it everywhere.
- **Touches:** each `*_kit.gd` (ClassKit hooks already read the `boons` dict), `*_boons.gd`.

### 3. Slot-based "build-your-verb"  *(CORE — the headline)*
Ascension shipped **slot-based Mystic Enchants** and in Wildcard shattered legendaries into 1,500 mix-and-match modifiers with **no cooldown-sharing / no lockouts** (run Penance AND Icy Penance).
- **Rift:** we have one verb per role, so we shatter *the verb*. Give each verb **mod slots**, e.g. Guard = `[Trigger] + [Property] + [Payload]`:
  - Trigger: on-perfect-parry / on-feint-hold / on-3rd-guard
  - Property: +1 charge / wider window / off-shared-cooldown
  - Payload: reflect / heal raid / apply Exposed / bank Counter
  Drafting fills slots → two runs of the same class produce **tangibly different verbs** (the Hades Zeus-vs-Poseidon fantasy on our verb). Evolution of the existing `boons` dict, not new engine.
- **Load-bearing rule:** **NO LOCKOUTS.** Don't gate combos; let them stack and rebalance the *boss* instead. "My build broke the game" is the draw.
- **Touches:** a slot schema (new), rewrite of a class's boons into typed mods (start w/ Bulwark's 17 tank boons on Guard), draft UI to show slots.
- **Proof-of-concept target:** Bulwark Guard, because the class already exists.

### 4. Skill *buys* build agency  *(CORE — our edge, the fusion Ascension never made)*
Every Ascension anti-feelbad tool (Scrolls of Fortune, Synergy, Skill Cards) is gated by **grind/level**. We have a currency they don't: **execution skill, measured live** — perfect parries, clean kicks, no-hit phases (much already in `state.diag`).
- **Rift:** skilled play **mints draft-steering currency mid-run**. No-avoidable-damage boss → reroll token; perfect-parry streak → "lock a slot" token. Between-fight draft becomes an **economy** (reroll / lock slot / upsell common→rare), not a passive 1-of-3. Fuses our two axes (execution + build-craft) that every roguelike keeps separate. Most *ours* idea in the batch.
- **Touches:** `state.diag` (define which skill signals mint which tokens — deterministic, per-seat), `RunState` (currency + spend), draft UI (spend actions).

### 5. Rarity = chase, not wall  *(the frame that makes 3 & 4 sing)*
Ascension: **rarity only affects frequency, never caps** — legendaries are rare to *see* but you may build all-legendary.
- **Rift:** boon pool gets rarity that affects flash-frequency + jackpot feel; pity protection so no run is starved; the aspirational all-legendary run is genuinely possible → the chase is real.
- **Touches:** boon pool weighting + pity in the draft-builder.

### 6. Trial Ladder  *(REFRAMED #3 — the endgame)*
Ascension Mythic+ / Raid Trials / Manastorm: replayable content at **infinitely ascending tiers**, difficulty = *added mechanics* (affix count, Champion mini-bosses, phases), rewards scale, leaderboards + Realm First.
- **Rift:** bosses replayable at tiers 1/2/3…; **each tier adds string beats/feints or a new phase** (not just +HP). Deterministic engine (same seed → same run) = **trustworthy leaderboards for free.** Also steal **Manastorm's aura-add**: a mid-fight elite that BUFFS the boss until killed (creates a real "add vs boss" split — and helps the R3 single-telegraph-scheduler problem). Rewards feed the currency in #4/#5.
- **Touches:** M7 Strings content (tier-scaled beats), `TuningConfig`, run/encounter loop, a leaderboard capture (seed + result).

---

## How they stack (the pitch)
#1/#2 make the draft *cohere and matter*. #3 gives a verb worth *crafting*. #4 gives the *agency* to craft it — earned by skill, not grind. #5 gives it a *high end to chase*. #6 is the endgame that consumes it all. Net: a roguelike where **being good at the fight is how you build** — which no MMO-derived game does, because their power comes from gear/time, not execution. That's the wedge.

## Suggested sequencing (for the planner to refine)
- **Phase A (cheap, ships the feel):** #1 Synergy + #2 Transform boons on one class (Bulwark), + #5 rarity/pity. Low engine risk.
- **Phase B (the core bet):** #3 slot-based Guard on Bulwark as PoC → generalize the slot schema to a 2nd class.
- **Phase C (the differentiator):** #4 skill-currency economy wired to `state.diag`, draft becomes an economy.
- **Phase D (endgame):** #6 Trial Ladder + leaderboards, tier-scaled Strings.

## Open questions for the plan
- Slot schema: fixed slot types per verb, or per-class? How many slots (draft length = 5 fights → ~5-8 mods)?
- Does slot-based apply to ALL five verbs at once, or Bulwark-first then port?
- Skill-currency: which `state.diag` signals are already deterministic & seat-scoped vs need adding? Co-op crediting (per-seat).
- Rarity/pity: reuse across boon pool + slot mods, or separate pools?
- Trial Ladder: solo (Trials) only, or co-op (The Rift) too? Leaderboard scope (seed-verified).
- Keep the "no lockouts, rebalance the boss instead" rule tractable for the balance sims (`sim/*_sim.gd`).

## Theme addendum (2026-07-02)
Raids are now **themed REALMS** (see `MASTER-PLAN.md` → Realms & Themes); Realm 1 "The Takeover" carries the ironic AI theme, solo stays rift-fantasy. Still GLOBAL from this plan: rarity tiers named **Haiku/Sonnet/Opus** (#5) and the skill-minted draft currency as **Tokens** (#4). Realm-1-scoped: Trial-Ladder boss **versions** with fake patch notes (#6), feints-as-**hallucinations**. Scoping rule for #3 (locked): draft pools stay per-class; mods express through UI the class already has; cross-aspect bleed is rare spice only where the class UI supports it.

## Non-negotiables (do not break)
- `CombatCore` stays a **pure, deterministic, Node-free reducer** (fixed 30Hz, integer-tick truth, one seeded PRNG, all tuning in `TuningConfig`). Every new system must be sim-able headless.
- New systems guarded so existing solo content stays **byte-identical** in the regression sims (the established bar for every engine change).
