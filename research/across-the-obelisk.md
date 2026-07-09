# Across the Obelisk — design notes

Researched 2026-07-09 (Chaos of Ophidian / Nenukil-era, v1.5+). Co-op deckbuilding roguelite by
Dreamsite Games / Paradox. **Why it's in the quarry:** it is the rare 4-PLAYER CO-OP deckbuilder —
our exact seat count. Everything about how it makes four independent decks combine into one board is
the reason to read it. Turn-based, no positioning/movement (fixed slots) — so its combat is closer to
Rift than any real-time game: the "interesting decision" is *which card into which timeline slot*, not
footwork. Numbers are point-in-time; verify before leaning on them for balance.

---

## 1. Build grammar

You pick **4 heroes** from a roster (~20+ across base + DLC) before a run, then descend a **branching
node map** across ~4 acts, each act opening in a **town** (shop cards, buy/sell gear, edit decks,
spend gold + shards/crystals). Each hero is a self-contained build with **its own card deck + 6-ish
gear slots + a persistent out-of-run perk tree**. A hero's deck is drawn from two pools: a **unique
personal talent pool** (that hero's signature cards) and a **shared class pool** (generic Warrior /
Scout / Mage / Healer cards any hero of that class can buy). Cards **rank up 0→3** at towns via a
branching **blue/gold upgrade** craft (crystals). Gear adds stats, resistances, and often extra cards
or triggers. The meta layer is the **perk tree** (player rank to 50; each rank = 1 perk point per
character; perks bank small permanent bonuses — HP, starting energy, starting block, etc.). So the run
is: draft a comp of 4 → shop each deck toward an archetype → tune upgrades → survive a fixed-but-
learnable map whose difficulty you dial up with optional corruptors. The **whole game is the party
composition** — no single hero wins; the payoff is cross-hero status chains.

## 2. Hero roster (by role)

Four base classes — **Warrior** (block/defense + physical), **Scout** (speed/utility/marks),
**Mage** (elemental burst/control), **Healer** (sustain/support) — roughly 4 heroes each at launch,
expanded by DLC, plus **Paladin**, a hybrid class that draws from **two class pools at once**. Each
hero is defined by a **status specialty** it is best at applying; builds are chosen by *which* of its
statuses you lean into.

**Warriors (tanks / bruisers)**
- **Magnus** (werewolf turncoat, a starting hero) — block engine. Generates block and **shares block to
  the whole party**; applies **Crack** (armor shred) + **Bleed**. Two distinct builds off one kit:
  **guardian** (block-share + taunt, party wall) vs **bruiser** (Crack/Bleed self-damage). The
  textbook "one hero, multiple builds" case.
- **Grukli** (orc berserker) — **Fury** specialist: Fury is a self-buff that raises damage but **bleeds
  him each turn per stack**, a built-in greed/risk dial. Stacks Bleed on enemies. Rage snowball.
- **Bree** (elf) — **Thorns** tank: stacks thorns into the triple digits by standing pat + playing
  **Taunt**, and enemies kill themselves on the reflect. Nearly no attack cards; the deck IS the tank.

**Scouts (speed / utility / dps)**
- **Andrin** (ranger, a starting hero) — **fastest hero**; **Hunter's Mark** (marks a target for death —
  the party does bonus damage into the mark), plus Bleed/Poison, ranged + melee flex. The party's tempo
  and focus-fire enabler.
- **Thuls** (assassin) — **Poison** + **Stealth/Camouflage**: builds poison stacks and burst from
  stealth. Ramp-then-detonate rogue.
- **Sylvie** (archer) — **Sight** debuff (reveals stealth) that also feeds **Bleed**; ranged attrition.
- **Gustav** (bard) — support scout: **Mind** damage + **Stanza aura** (a persistent party buff aura) +
  team buffs. Backline enabler rather than a damage seat.
- **Nenukil** (DLC engineer) — gadget scout that scales toward **defense OR damage** as he levels.

**Mages (elemental dps / control)**
- **Evelyn** (first mage, a starting hero) — **flex elementalist**: weapon-enchant + elemental
  resistances; can commit to **Fire / Ice / Lightning**. Jack-of-all-trades teaching hero, but her
  "which element" choice is a real fork.
- **Zek** — **Shadow/Dark** curse application → sets up **Dark explosions** (see status economy).
- **Cornelius** — **Fire/Burn** OR **Energy battery** (generates energy for the party): a damage build
  and a support build in one hero.
- **Wilbur** — **Lightning/Spark** specialist; passive **energizes a party member each turn**; his
  Spark can be perked to **spread to neighbors ~30%**. A chain-damage engine.

**Healers (sustain / hybrid damage)**
- **Reginald** (blessed healer, a starting hero) — highest raw healing + bonus **Holy** damage. The
  clean healer; also a Holy-damage build.
- **Malukah** — **Shadow healer**: deals Shadow damage and **heals the party off Dark on enemies** —
  offense and defense fused, pairs directly with Zek's Dark.
- **Nezglekt** — healing **Prophet**: Mind powers + **second sight** (Sight application + heal). Control-
  flavored healer.

**Paladin (DLC hybrid)**
- **Laia** (Paladin of Basthet, *Sands of Ulminin* DLC) — **accesses BOTH Warrior and Healer class
  pools**, healing + "burning passion" damage. The hybrid-class idea: a seat whose card space is the
  UNION of two roles = enormous build breadth, at the cost of a shallower personal pool.

## 3. Card / upgrade design patterns

- **Two-pool decks.** Every hero's buildable cards = its **unique talent pool** + the **shared class
  pool**. This keeps each hero identity-locked while letting any two Warriors feel different despite
  sharing generic block cards. Paladins draw from two class pools = the widest space.
- **Blue/gold branching upgrades (the craft).** Every card ranks up with **two mutually-exclusive
  paths** — a **gold** name and a **blue** name — that push it toward *different* archetypes (e.g. a
  strike whose blue path *adds Bleed* while its gold path *drops the DoT for raw Fury/damage*). You
  don't just make a card bigger; you commit it to a plan. **Purple** versions exist too (stronger, but
  only from combat/event rewards, not craftable). Upgrades cost crystals — a scarce economy, so you
  can't max everything.
- **Rank tiers.** Personal talent cards unlock/upgrade at **hero rank 20 (blue tier)** and **rank 44
  (gold tier)** — long-tail meta unlocks so a hero keeps deepening across many runs.
- **Status economy = the party's shared vocabulary.** Damage has **types** (Physical, Fire, Cold,
  Lightning, Poison/Nature, Shadow, Holy, Mind), each with a **per-unit resistance %**. Statuses split
  into **setters** and **payoffs**:
  - **DoTs:** **Bleed** (ticks *before* the target's turn, ignores armor), **Burn** (before turn, *is*
    blocked by armor and reduced by **Wet**), **Poison** (ticks *after* the turn, ignores armor).
  - **Explode statuses:** **Dark** — each stack lowers Shadow resist 1%; at **25 stacks it detonates**
    (~55 Shadow to the target + splash to neighbors). A stack-then-pop payoff.
  - **Spread:** **Spark**/Lightning hits **adjacent** units (position matters even without movement).
  - **Control/enable:** **Sight/Mark** (reveal stealth + enable bonus damage into it), **Wet** (kills
    Burn, opens Cold/Lightning lines), **Cold/Chill** (−speed), **Weak** (−damage dealt), **Vulnerable**,
    **Taunt** (force targeting), **Stealth**.
  - **Self-buffs with a cost:** **Fury** (+damage, bleeds you), **Powerful/Strength** (+damage, **cap 10**).
  - **Defensive:** **Block/Armor** (absorbs, *refreshes each turn* — use-it-or-lose-it), **Thorns**
    (reflect), **Regeneration**, **Evasion** (non-stacking — a new value *replaces*, doesn't add).
  - **Speed:** **Haste/Fast** — different speed buffs **stack**, identical ones only extend duration.
- **The whole point:** one hero *applies* a status, another *spends* it. Zek stacks Dark → Malukah
  heals off it and it explodes; Sylvie/Andrin apply Sight/Mark → the party's marked-target bonus damage
  turns on; Wilbur Sparks a wet, chilled clump. Cards are explicitly written as setters or payoffs so a
  4-deck comp reads as one combo machine.
- **Items/trinkets.** ~6 gear slots per hero (weapon, offhand, head, chest, ring/amulet, consumables);
  gear grants stats, resistances, and frequently **injects cards or trigger effects** into the deck —
  a second, non-card build axis.
- **Corruption cards / injuries.** At the **Bell** node (The Void) you can **corrupt a card** →
  replace it with a stronger **corrupted version that carries a drawback**; base **300 shards, 70%
  success**, and a **failure adds a "Void Memory" injury** (dead-weight curse card) to that deck.
  Other events also hand out injuries. So the deck-thinning/upgrading economy has a real gamble in it.

## 4. Difficulty & self-tuning systems

- **Base ladder → Madness.** Normal → Hard, then **Madness 1–16** as the endgame ladder. Each Madness
  step scales enemies broadly — **upgraded enemy cards, more speed / HP / energy** — and higher tiers
  also **cut the party's max vitality (HP)**. It's a coarse global multiplier, not a per-level affix
  list.
- **Corruptors (opt-in per-fight difficulty for reward).** Before some combats an **Obelisk Corruption**
  offer pops: accept a specific modifier to make the fight harder in exchange for better loot, tagged
  **Easy / Hard / Extreme**. Example — **Equalizer**: forces every "thermometer" reward in that fight up
  to the **Great** tier regardless of how slowly you win. Corruptors are a *player-authored* spike knob.
- **The thermometer (built-in speed→reward dial).** Combat rewards (XP/gold/cards) scale by **how fast
  you win** — finish in fewer rounds = a higher reward tier (Great/Good/…). This bakes a *skill
  expression → reward* curve into every fight without any difficulty menu; playing better literally pays
  more. Corruptors like Equalizer let you buy out of the speed tax.
- **Comp interaction.** Because scaling is global (enemy stats up, your HP down), higher Madness pushes
  you toward **hard status engines** (poison/dark/bleed that ignore armor and scale multiplicatively)
  and **hard defense** (block-share, thorns, healing throughput) — soft "fair fight" decks fall off. The
  difficulty ladder is effectively a filter on comp archetype, not just numbers.

## 5. Party / co-op interplay — the key section

**Seat control.** Each participant owns **1–4 heroes**: 4 players = 1 each, 2 players = 2 each, solo = all
4. You only ever play *your own* hero on its turn, editing/shopping only *your* decks. The single-player
game and the 4-player game are literally the same content with control split — **the same
solo=co-op principle Rift uses.**

**Turn order = one shared speed timeline.** All eight units (4 heroes + enemies) are ordered on a single
**initiative track shown at the top of the screen**, computed from **Speed** at combat start and
re-sorted as Haste/Chill land. Ties: a hero beats an equal-speed enemy; among heroes the **rightmost**
goes first; among enemies the **leftmost**. **Energy** (default ~3/turn) gates how many cards you play,
and **unused energy banks to next round** — so a seat can deliberately underplay this turn to nuke next
turn. This is the crux: co-op decisions are **sequenced on a public timeline**, so setter-before-payoff
ordering is a *scheduling* problem the four players solve together, live.

**Cross-hero synergy is the entire design.** Cards are authored as **setters** and **payoffs** that live
in *different heroes' decks*: apply-Dark (Zek) → detonate/heal-off-Dark (Malukah); Mark (Andrin/Sylvie)
→ party focus-fire bonus; block-share (Magnus) → keep the poison/thorns carry alive; energy-battery
(Cornelius/Wilbur) → let the mage dump twice. A comp is *drafted for its combo*, and the timeline forces
the party to interleave those plays in the right slots. No hero is self-sufficient at high Madness.

**Shared draft / reward decisions.** Map moves and event choices are **voted**; if votes disagree, a
**card-draw minigame** resolves it (**high / low / closest-to-2**, rule chosen by a random player) — a
lightweight, luck-flavored tiebreaker so no one player dictates the route. Event dice-rolls are resolved
by **everyone drawing cards**, spreading agency.

**Loot-goblin problem, largely designed out.** Rewards are **per-character**: gold and shards are **split
by hero** (control 2 heroes → get half the gold but only fund 2 decks), and **card rewards are earned by
the hero that fought**. So there's little zero-sum "who grabs the drop" friction — each seat's economy is
its own. The escape valve for imbalance: **currency is freely giftable** between players, letting a strong
seat prop up a new one. Town phases allow **simultaneous deck-editing/shopping**, so co-op doesn't
bottleneck on one person menuing.

**Residual friction it did *not* fully solve.** Voting still lets a majority route against one player;
the tiebreak minigame is random, not skill; and account-level unlocks mean a **new player joins without
the veteran's perks/cards**, so power is uneven across a lobby. These are the honest limits.

## 6. STEAL CANDIDATES for Rift

Filter: *borrow the grammar, innovate the sentence* — each must exploit our timing-minigame /
deterministic-AI / 4-seat-warband engine, not repack a turn-based card system.

1. **Setter/payoff status split across seats → cross-seat WHEN→THEN rig.** AtO's whole party is one
   hero applies a status, another spends it. Ours: a **RIG** card whose WHEN fires on *another seat's*
   earned moment ("WHEN an ally lands a Perfect / opens a boss Opening → THEN my next dump gets the
   ×1.9"). Our determinism makes cross-seat triggers exact; AI-backfilled seats can be *authored* to set
   up the human. The combo lives in real timing windows, not on a card queue.

2. **Blue/gold branching card upgrade → the EASE-adjacent "commit fork" on a Boon.** AtO upgrades commit a
   card to an archetype (blue adds the DoT, gold trades it for raw damage). Map onto a Boon draft: on
   pick, choose **one of two mutually-exclusive riders** (e.g. "widens your Perfect window" vs "adds a
   Bleed tick but keeps the window tight") — a one-time craft fork, distinct from the EASE slider because
   it's permanent-per-run and archetype-defining, not a live comfort/bite dial.

3. **The thermometer (speed→reward) → boss-Opening reward escalation.** AtO pays more for a faster kill,
   with no menu. Ours: a **run-long reward meter driven by clean play** — hit more Openings / Bullseyes
   across a fight and the *draft that fight offers* upgrades tier. Skill expression → build power, baked
   into combat, exploiting our graded-tap fidelity the same way AtO exploits round-count.

4. **Corruptors (opt-in per-fight spike for loot) → a Rig-node "dare" card.** Before a node, offer a
   toggle: "this fight's telegraphs come faster / an extra Opening-punish enrage → +1 draft pick." A
   **player-authored** difficulty knob per fight, separate from the global run difficulty — our version
   dials *telegraph density / window tightness*, the levers only a timing game has.

5. **Fury (self-buff that costs you) → greed Creeds.** AtO's Fury raises damage and bleeds you per stack —
   a pure greed dial. A **Creed** temperament: "your dumps hit harder, but a missed tap chips your own
   HP" — the run-long risk personality our Creed slot is built for, made legible because our misses are
   graded, not binary.

6. **Explode-at-threshold status (Dark @ 25) → a Module gauge that pops.** A **Module** meter that fills
   from a specific tap grade and **detonates a spectacle hit at a cap** — Dark's "stack then boom" as an
   add-on gauge to a minigame, where the fill rate is *your window accuracy*, not card count.

7. **Block that refreshes each turn (use-it-or-lose-it) → decaying resource pressure.** AtO block resets
   every turn, forcing spend-now. A tank Module resource that **decays unless refreshed by an answered
   telegraph** — pressures active defense instead of hoarding, and only reads on a live-window engine.

8. **Hybrid Paladin (two class pools) → a cross-branch Keystone.** Laia unions Warrior+Healer card space.
   A **Keystone** that opens a *second branch's* Boon pool to you for the rest of the run — huge breadth
   as a 1/run elite reward, the spectacle build-definer our Keystone slot wants.

9. **Injuries / corrupted-card gamble (300 shards, 70%, fail = curse) → a real draft gamble node.** AtO's
   Bell risks a curse card for a stronger card. Ours: an elite offer — **take a Keystone now, but a failed
   coin (seeded, deterministic) adds a "Static" card that narrows one window for the run**. Greed with a
   downside that our timing model makes felt.

10. **Energy-banking (underplay now to burst next turn) → a charge-hold beat.** AtO banks unused energy.
    Ours: a mechanic that lets a seat **deliberately skip its dump to store a stronger one** for the next
    boss Opening — a scheduling greed choice, tuned to our Opening-window cadence.

11. **Shared reward-per-hero economy → per-seat draft, no goblin.** AtO earns loot *per fighting hero* so
    there's no scramble. Confirm/keep Rift's rule: **each seat drafts its OWN 1-of-3**, AI seats auto-pick
    to a policy, humans never fight over one shared pick — sidesteps AtO's residual majority-vote friction.

12. **Single initiative timeline → shared "Opening slot" scheduling.** AtO's public speed track makes
    interleaving a group puzzle. Ours: surface the boss's **upcoming Opening/telegraph as a shared visible
    beat** so the warband coordinates *who dumps into it* — turning our single-telegraph-stream law into a
    4-seat scheduling minigame.

13. **Elemental resistance per damage type → boss "answer" typing.** AtO enemies resist types, steering
    comp. Ours (light touch): a boss phase that **resists one dump family**, nudging the warband to route
    Openings through the seat that isn't resisted — comp texture without a targeting UI.

### Twinfang / rogue-flavored subsection

- **Thuls' poison-ramp-then-stealth-burst → Flow's build-then-Eviscerate arc, but risk-gated.** AtO's
  assassin stacks poison quietly then bursts from stealth. Twinfang already ramps Flow 0→6; steal the
  *stealth commitment* as a **Creed**: taps at high Flow build a hidden stack that a **Coup de Grâce dump
  spends for a burst**, but breaking rhythm (a Good instead of Perfect) leaks it — greed on the ramp.
- **Andrin's Hunter's Mark (party focus-fire) → a Twinfang Rig that MARKS the boss Opening for the
  warband.** Andrin marks a target and the party's damage into it jumps. Twinfang RIG: "WHEN I hit a
  Bullseye during an Opening → THEN the Opening's ×1.9 applies to *all seats'* next hit" — the rogue as
  the party's tempo-setter, not just a solo dps.
- **Fury's bleed-yourself greed → a Redline Flow Creed.** Fury trades HP for damage per stack. Twinfang
  Creed: **push Flow past 6 into a Redline** where the beat speeds up further and dumps hit harder, but a
  whiff costs HP — the rhythm rogue's version of AtO's self-damaging rage dial, expressed through our
  accelerating-beat mechanic.
- **Blue/gold upgrade fork → a Twinfang Boon "which finisher" commit.** On drafting the Eviscerate Boon,
  fork it: **wider combo-window / same damage** vs **tighter window / bigger finisher** — AtO's archetype-
  commit craft, wearing our graded-window clothing.
- **Wilbur's Spark chaining to neighbors → a dodge-into-tempo payoff.** Steal "one action feeds the next"
  as: a **clean spacebar dodge during a barrage refunds a Flow tick** (dodge doesn't just survive, it
  *keeps the rhythm*), so defense and offense chain the way AtO chains Spark — only a one-verb-dodge
  timing game can do this.

## 7. Sources

- Across the Obelisk Wiki (Fandom): Characters, Keywords/Effects, Perks, Nodes, Cards, The Ancient Altar,
  Bell — https://ato.fandom.com/wiki/ (Characters, Keywords/Effects, Perks, Nodes, Cards pages)
- TheGamer — "Every Character In Across The Obelisk, Ranked" — https://www.thegamer.com/across-the-obelisk-all-characters-ranked/
- Gamer Rant — beginner tips, best adventurers, unlock guide — https://gamerant.com/across-the-obelisk-beginner-tips/
- SteamAH — Status Effects & Terminology — https://steamah.com/across-the-obelisk-status-effects-terminology/
- Steam Community guides — "Guide to Obelisk's Status Effects, Combat & Terminology" (id 2530833179),
  "Guide to Madness" (id 2966960857), "All Character Unlocks" (id 2654263360)
- itemlevel.net — Corrupted Items guide; Heiner/perks hero guide — https://itemlevel.net/
- Indie Hell Zone review (co-op/voting/turn structure) — https://indiehellzone.com/2023/10/05/across-the-obelisk/
- Steam Community discussions — "how does co-op differ from single player?" (thread 6063574513311913741),
  "How does multiplayer work?" (thread 3494258250281692819)
- RPGamer — 2024 DLC packs (Nenukil the Engineer / The Obsidian Uprising) — https://rpgamer.com/2024/05/across-the-obelisk-new-dlc-packs-revealed/
- Paradox Forums — Patch notes v1.4 / v1.5 (corruptors, upgrades)
