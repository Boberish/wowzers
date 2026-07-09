# Clair Obscur: Expedition 33 — per-character battle minigames + timing parry

*Researched 2026-07-09. Numbers verified against Fextralife, Maxroll, Game8, GameSpot. Live game
(patch 1.3.0 era) — verify before leaning on exact windows for balance.*

**Why this file matters most.** E33 ships the exact thing Rift is betting on: six playable
characters, each a *different minigame on one shared combat chassis*, plus a real-time
timing-defense layer (dodge/parry) that doubles as a self-tuning difficulty dial. It sold ~5M and
review-swept on the strength of that. It is the closest published proof our class model works. Read
it as: what makes six mechanics legible side-by-side, and what the "skills-per-mechanic" grammar is.

---

## 1. Build grammar (one paragraph)

A character is **kit mechanic** (unique resource/state, the minigame) + **weapon** (raw power +
attribute scaling grade + up-to-3 passives that unlock at level milestones and hook the character's
mechanic) + **Pictos** (3 equip slots, each grants 3 stats and one passive "Lumina" effect) +
**Luminas** (passives you've permanently *learned* by using their Picto, re-equippable on a Lumina-
Point budget) + **attributes** (Vitality / Might / Agility / Defense / Luck; +3 points per level,
freely assigned). Weapons scale off **Might plus two weapon-specific attributes**, each graded
D→C→B→A→S — the grade, not the raw stat, is what turns points into damage. So a build is: pick the
weapon whose passives amplify your mechanic, pump the attributes it scales on, and fill the Lumina
budget with passives that patch the mechanic's weak spot. Combat itself runs on **AP** (spend to
cast, regenerate by basic-attacking and parrying) feeding a shared **Gradient** ultimate gauge, over
a **reactive turn-based** loop where every enemy hit is answered in real time by dodge or parry.

---

## 2. Character roster — six minigames, one chassis (the core section)

Party = **3 active of 6**. Each character starts every battle at their mechanic's floor and must
*build the state up during the fight* — no persistent between-fight charge. That per-fight rebuild is
what makes each one a legible loop instead of a passive stat.

### Gustave — the engineer (Overcharge gauge)
- **Fantasy:** prosthetic-armed inventor; a builder-into-nuke.
- **Mechanic — Overcharge:** a charge gauge (cap **10**). He gains Charges from *everything he does*
  — basic attacks (1), dodges, parries, and specific "builder" skills (Lumière Assault yields ~6-7
  over its 5 hits; Perfect-timed skills grant extra). At 10 the bionic arm glows red.
- **Skills×mechanic:** the payoff skill **Overcharge** consumes the full gauge for a huge Lightning
  nuke that at 10 charges reliably **Breaks** (stuns) the target. Other skills are graded builders —
  their charge yield jumps if you hit the Perfect-timing prompt during the animation.
- **Loop / moment:** spend ~2-3 turns building, watch for the red arm, dump Overcharge to Break the
  boss and open a burst window for the whole party. A pure fill-then-discharge minigame.
- *Design note:* Gustave is an Act-1 protagonist and **leaves the roster mid-story** — the game
  rotates its cast, and later swordsman **Verso** inherits several of his skill names. Rosters that
  change over a campaign is itself a steal-worthy structure.

### Lune — the scholar mage (elemental Stains)
- **Fantasy:** studious battlemage juggling five elements.
- **Mechanic — Stains:** casting an elemental skill deposits a matching **Stain** — Fire, Ice(Cold),
  Lightning, Earth, Light — into a small pool. Other skills *consume* Stains (usually of a paired
  element) to gain bonus effects: extra damage, extra hits, or reduced AP cost. **Light Stains are
  wild** — they substitute for any required Stain type.
- **Skills×mechanic:** every skill is tagged generator or consumer. Storm Caller hits twice if it
  consumes a Fire Stain; Thermal Transfer becomes an AP battery off burning/Earth-stained targets;
  **Mayhem** consumes *all* Stains and scales its damage by how many element-types it ate.
- **Loop / moment:** paint 2-4 Stains of the right colors across a couple casts, then fire the
  consumer that turns that specific palette into a spike. A short-horizon builder/spender puzzle
  where sequencing *which colors* matters more than raw count.

### Maelle — the fencer (four Stances)
- **Fantasy:** duelist who flows between guards.
- **Mechanic — Stances:** four states — **Stanceless** (neutral start), **Offensive** (+50% damage
  dealt, +50% damage taken), **Defensive** (−50% damage taken, +1 AP per parry/dodge), **Virtuose**
  (+200% damage, no downside — but hard to enter). **Switching into any stance grants +1 AP.**
- **Skills×mechanic:** most skills *move her between stances* and *gain a bonus effect conditional on
  the stance she's in* — e.g. a skill hits harder or adds an effect only from Offensive. Virtuose is
  reached only through specific skills, so it's an earned burst state, not a toggle.
- **Loop / moment:** chain skills so each one both fires its stance-conditional bonus and repositions
  her toward Virtuose, then unload the Virtuose window (Last Chance → Sword Ballet) at ×3 damage. A
  state-machine minigame: the *order* of skills is the puzzle, and each stance change hands back AP so
  a clean chain is self-fueling.

### Sciel — the fortune-teller (Foretell + Sun/Moon → Twilight)
- **Fantasy:** scythe-wielding card-reader who marks fate then cashes it.
- **Mechanic — Foretell + two charge tracks:** **Foretell** is a stacking debuff on the enemy (cap
  **10**, raised to **20** during Twilight). **Sun** skills apply Foretell and grant a **Sun Charge**;
  **Moon** skills consume Foretell and grant a **Moon Charge**. Both charge tracks stack freely.
- **Twilight (the payoff state):** if she starts a turn holding **≥1 Sun AND ≥1 Moon**, she may
  consume them to enter **Twilight for 2 turns** — Foretell application doubles, cap rises to 20,
  and she gains **+25% damage per Sun and Moon charge she consumed** to enter (2 Sun + 1 Moon = +75%).
  During Twilight she *stops generating* charges; when it ends both tracks reset to 0.
- **Skills×mechanic:** Focused Foretell (2 AP) stamps 2 Foretell (5 if the target has 0). Sealed Fate
  (Moon) does 5-7 hits each consuming 1 Foretell for "200% more damage." Grim Harvest heals the party
  30% +5% per Foretell consumed — the consumer skills double as party utility.
- **Loop / moment:** seed the boss with Foretell (Sun) + throw one Moon to bank both charge colors →
  next turn pop Twilight → dump the big consumers into the doubled cap. A two-meter *gate* ("need one
  of each to unlock the burst") that teaches sequencing without a tutorial.

### Verso — the swordsman (Perfection Rank)
- **Fantasy:** flashy, aggressive fencer punished for getting touched.
- **Mechanic — Perfection Rank:** a ladder **D → C → B → A → S**, starting at D each battle. He gains
  Perfection on *every instance of damage he deals* (each hit of a multi-hit, basic attacks, Free-Aim
  shots) **and on every parry or dodge**. Higher rank = flat damage multiplier. **Taking any damage
  drops him one rank — but only once per enemy turn**, so eating one hit is survivable, eating a
  string is ruinous.
- **Skills×mechanic:** skills gain extra effects and *discounts* at rank thresholds — Perfect Break
  costs 5 AP instead of 7 at Rank B (and can jump you straight to S on a successful Break); Phantom
  Stars costs 5 instead of 9 at S. His basic is a fast timed 3-hit combo that ladders Perfection fast.
- **Loop / moment:** climb to S by chaining hits and flawless defense, then *stay* at S by never
  taking a clean hit — the entire kit is a **greed dial on not-getting-touched**. The most direct kin
  to Rift's "reward the untouchable rhythm run" temperament.

### Monoco — the Gestral (Bestial Wheel + stolen skills)
- **Fantasy:** shapeshifting beast-mimic who fights with enemies' own moves.
- **Mechanic — Bestial Wheel:** a rotating pointer with **9 positions** cycling through 5 mask
  categories — **Caster, Agile, Balanced, Heavy, Almighty** (each mask appears twice in a row except
  Almighty, once). Every skill **advances the pointer a fixed number of steps** and is tagged to a
  mask; a skill fires *enhanced* when the wheel currently sits on its matching mask.
- **Learned skills:** Monoco doesn't have a fixed spellbook — he **learns skills by defeating
  specific enemies** (collecting their "foot"), so his kit is a growing library of monster abilities.
- **Skills×mechanic:** because each skill both *has* a mask and *rotates* the wheel by a set amount,
  you plan a sequence so the next skill lands on-mask. Heavy-mask skills spread their buff to all
  allies; Almighty is the universal-good slot.
- **Loop / moment:** a **deterministic combo puzzle** — position is truth, every skill's rotation is
  known, so an expert routes a fixed sequence that keeps landing on-mask. Purest "system, not stats"
  character, and the most engine-friendly for us (no RNG, integer pointer state).

**What makes six minigames legible at once (the meta-lesson):**
- Each is **ONE gauge/state with a visible readout** next to the character (charge bar, stain pips,
  stance icon, Foretell stacks + Sun/Moon, rank letter, wheel pointer). One glance = one number.
- Every mechanic is a **builder→spender or a state-machine**, never a passive. You *do things* to move
  it and *do a different thing* to cash it.
- Skills are **tagged to the mechanic** (generator/consumer, stance-conditional, mask, rank-gated) so
  a character's whole skill list reads as "how do I feed and spend *my* meter," not a generic toolbox.
- The payoff is always a **conditional window** (10 charges / Twilight / Virtuose / Rank S / on-mask),
  never an always-on buff. Legibility = the window lights up.

---

## 3. Ability / upgrade design patterns

- **AP economy = the shared spine.** Every character runs on Action Points: basic Attack *generates*
  AP (the builder), skills *spend* it (costs seen from 2 up to 9), and **a successful parry refunds
  +1 AP**. So defense literally pays for offense. Mechanics bolt onto this — Maelle's stance-swap and
  Defensive stance mint extra AP, Verso's rank gives discounts, Sciel's charges are a parallel economy.
- **Gradient gauge = the ultimate layer.** A shared party meter filled by *spending AP* (~5% per AP).
  At a full charge you fire a **Gradient Attack** — big, and crucially it **does not end your turn**
  ("Play Again," capped once per turn), so ults *chain into* your normal turn instead of replacing it.
  This is the "signature that amplifies your turn rather than being the turn" pattern we want.
- **Break gauge = the shared vulnerability meter.** Each enemy has a gold Break bar under its HP that
  fills as it takes damage — but it **only actually Breaks (stuns + takes bonus damage) when hit by a
  Break-flagged skill or Gradient Attack.** Filling it isn't enough; you need the right *key*. This
  cleanly separates "chip damage" from "the punish that pops the window."
- **Weapons as build-definers (closest kin to our keystones).** Every weapon unlocks **passives at
  fixed level milestones — L4, L10, L20** — and the passives are *authored to the wielder's mechanic*
  (Maelle weapons grant stance passives, Sciel's grant Foretell/Sun/Moon hooks, Lune's grant
  stain effects). Scaling grade also steps up (e.g. C→B at L4, →A at L20, →S at max **L33**). So the
  weapon isn't a stat stick — it's a staged reveal of mechanic-specific power, unlocking as you commit.
- **Pictos (equip 3) vs Luminas (learn + budget) — the equip-to-learn loop.** You **equip up to 3
  Pictos**; each gives 3 stats + one passive. **Fight 4 battles with a Picto equipped and its passive
  becomes a permanently-known "Lumina"** you can then slot on *any* character *without* the physical
  Picto — but only within a **Lumina-Point budget** (1 point per level, more bought with the "Colour
  of Lumina" resource at camp; each Lumina has a point cost). Net: **you master a passive by actually
  running it**, then it enters a shared, budget-limited loadout pool. Commitment over hoarding.
- **What makes their best skills feel great:** (1) a Perfect-timing prompt *inside* the attack
  animation that boosts yield — offense has a rhythm layer too, not just defense; (2) skills that pay
  the mechanic AND do party utility (Grim Harvest heals *scaling with* Foretell spent); (3)
  discounts/extra-effects that trigger only in the earned state, so hitting the state visibly changes
  what a familiar button does.

---

## 4. Difficulty & self-tuning systems

- **Parry vs dodge = a difficulty dial expressed by skill, shipped in a AAA game.** Both answer the
  *same* incoming attack in real time:
  - **Dodge** — easier, wider window, avoids the damage, **no reward** (no AP, no counter). The safety
    net.
  - **Parry** — **tighter window**, avoids the damage, refunds **+1 AP**, and if you **parry every hit
    of a multi-hit string you unleash a counterattack**. High-risk, high-reward.
  - Exact frame windows aren't officially published, but the *design* is explicit: same threat, two
    answers, the tighter one pays out. This is precisely our EASE-dial philosophy (COMFORT = wide/
    damage-neutral, BITE = tight/+payoff) already validated at scale.
- **The "Expert / parry-only" crowd.** Because parry both fully negates and pays back, the mastery
  community plays **parry-only, dodge-never** — self-selecting the tighter dial for the counter loop.
  The dial isn't a menu setting; players *choose their difficulty every enemy swing.*
- **Difficulty modes** (changeable anytime out of battle): **Story** (enemies weaker, windows wide —
  patch 1.3.0 widened Story parry/dodge windows by up to **40%** and cut incoming damage), **Expeditioner**
  (Normal, the intended tuning), **Expert** (enemies hit harder, windows *smaller* — split-second).
  So the menu difficulty *and* the per-swing verb choice both move the same knob (window width),
  from two directions.
- **Jump / Gradient Counter / Expedition Counter** add texture: some attacks are dodge/parry-immune
  and must be **jumped** (marked with an icon); party-wide AOE attacks trigger an **Expedition
  Counter** where all three members parry together.

---

## 5. Party / co-op interplay

- **3 active of a 6-roster.** Turn-based order shown on a Timeline; you build a comp, not a solo kit.
- **Defense is real-time and per-character even on others' threats** — when the enemy acts, *whoever
  is targeted* must dodge/parry it themselves, so all three players (or the solo player, controlling
  all three) stay engaged through the whole enemy turn, not just their own.
- **Free-target counters:** counters and Gradient Attacks can be aimed at any enemy, and **Free Aim**
  lets a character spend AP to manually shoot an enemy weak point — offense isn't locked to turn order.
- **Cross-character mechanic combos:** Lune paints Burn/elemental states that Sciel and Maelle *cash*
  (Thermal Transfer turns Burn into AP; Maelle's fire loop stacks Burn for a partner); anyone can land
  the **Break-flagged** hit to pop the shared Break window another character built; the shared Gradient
  gauge means one character's AP-spending *fuels the party's* ultimate. The mechanics are separate
  minigames but they **feed shared meters (Break, Gradient) and shared debuff fields**, so a comp is
  "who builds the field, who cashes it."

---

## 6. STEAL CANDIDATES for Rift

Filter applied — *borrow the grammar, innovate the sentence*: each must exploit our timing-minigame /
deterministic engine, not repack a menu. Mapped to our grammar (BRANCH = Creed→Module→Boons→Keystone;
EASE dial; RIG WHEN→THEN; signature CD; ABILITY LAW ≤7 buttons).

1. **Break-gauge = the boss "Opening" made a shared visible meter.** *E33:* gold bar fills with any
   damage but only Breaks when hit by a Break-flagged attack. *Ours:* draw the Opening as a fillable
   gold bar on the boss; designate our **×1.9 dump hits as the "break-flagged" key** — landing a dump
   inside the window *pops* the bar for a party-wide stun/vuln. Turns the invisible punish window into
   a legible fill-then-key mechanic. (Boon/RULE card + engine flag; single-target-law safe.)

2. **Two-meter gate for the signature CD (Sciel Sun/Moon → Twilight).** *E33:* need ≥1 Sun AND ≥1 Moon
   to unlock Twilight. *Ours:* a Module with two tiny gauges fed by *different* graded actions (e.g.
   Bullseye feeds one, a clean dodge feeds the other); the **signature CD only lights when both ≥1**,
   and firing it spends them for a 2-window amplify. Teaches sequencing; signature amplifies skill,
   never button=damage.

3. **Perfection Rank = a "Redline" Creed (run-long temperament).** *E33:* Verso climbs D→S on clean
   hits, drops a rank on *any* damage taken (once per enemy turn). *Ours:* a Creed where a rank ladder
   multiplies dump damage, every clean beat climbs it, and **taking a hit (or a whiffed beat) demotes
   one rank.** Pure greed-on-not-getting-touched — a temperament, not a button. (See rogue subsection.)

4. **Stains = player-wired RIG builder/spender across buttons.** *E33:* one action deposits an elemental
   Stain, a *different* action consumes it for +hits/-cost. *Ours:* RIG card — **WHEN [you land a
   Bullseye] THEN [stamp a mark]**, and a Boon makes the next Coup de Grâce *consume* that mark for
   extra hits. The cross-button, earned-moment builder/spender is the grammar; the deterministic mark
   is the sentence.

5. **Virtuose = an earned Keystone spectacle state.** *E33:* +200% no-downside stance you can only
   *enter* through a specific setup. *Ours:* a Keystone (1/run) that opens a **hard-to-enter burst
   window** — e.g. reach Flow 6 via 3 straight Bullseyes — during which the minigame runs at max
   payoff for ~8s. Spectacle gated behind perfect play, never a toggle.

6. **Gradient "Play Again" = a dump that refunds the beat.** *E33:* Gradient Attacks don't end the
   turn (once/turn). *Ours:* a Keystone/Boon where a **Perfect dump inside the Opening refunds its own
   cost once per window** — lets spectacle chain without becoming spam, because the "once per Opening"
   *is* the WHEN. Rewards precision, not mashing.

7. **Weapon L4/10/20 milestone passives = staged keystone reveal.** *E33:* a weapon drips
   mechanic-specific passives as it levels. *Ours:* let a branch **Keystone unlock in stages across a
   run** (each elite kill deepens the same mechanic) instead of arriving whole — the build gets more
   *legible* as it grows, and elite kills feel like milestones, not just a token.

8. **Pictos→Lumina equip-to-learn loop = "master a card by running it."** *E33:* equip a Picto, fight
   4 battles, permanently learn its Lumina (then slot on a point budget). *Ours (meta):* a Boon you
   actually run for N fights becomes a **permanently-draftable known card at reduced draft cost** —
   commitment converts a one-run pickup into a repertoire card. Rewards playing with your build, not
   hoarding, and gives our persistent-unlock layer a *usage-driven* path.

9. **Stance-conditional skills WITHOUT a stance button (Maelle → Flow bands).** *E33:* every skill does
   something extra depending on which stance you're in. *Ours:* make **Boons read the Flow band you're
   currently in** ("at Flow 5-6 Eviscerate cleaves"; "below Flow 2, taps refund"). You get the stance-
   switch *feel* — the same button changing behavior with state — with **zero new buttons** (ABILITY
   LAW clean), because Flow is already on screen.

10. **Monoco wheel = a deterministic rotating-state Module.** *E33:* a 9-slot pointer advances a fixed
    number of steps per skill; skills pay off on-mask. *Ours:* a "cadence wheel" Module where **each
    strike advances an integer pointer** and the finisher only crits when the pointer sits on the
    matching pip — a self-set combo puzzle layered on the rhythm. Position-is-truth, RNG-free, perfect
    for our deterministic reducer.

11. **Perfect-parry-the-whole-string → the counter (all-or-nothing beat).** *E33:* you must parry
    *every* hit of a multi-hit chain to earn the counter. *Ours:* since one boss telegraph = one
    multi-beat string, **grade the whole string and only a clean sweep opens the Opening/counter** —
    a mid-fight escalating beat where partial success = survival, perfection = punish.

12. **Free-Aim weak-point shot = a greedy STRAT Boon.** *E33:* spend AP to manually target a weak
    point for burst. *Ours:* a Boon that **sacrifices a Flow tick to fire a precision shot into the
    boss's weak point during an Opening** — the cost is tempo, the payoff is burst. Legible risk fork.

13. **AP-refund-on-parry = defense pays offense (economy coupling).** *E33:* a successful parry
    refunds +1 AP. *Ours:* wire a **clean spacebar dodge to refund a Flow tick or shave the beat
    speed-up** — so nailing defense directly feeds the offense minigame, coupling the two loops the
    way E33 couples parry→AP→skills. (RIG-shaped: WHEN clean-dodge THEN +tempo.)

14. **Roster that rotates over the campaign (Gustave leaves).** *E33:* the playable cast changes across
    the story; a later character inherits an earlier one's skill names. *Ours:* Realm/act structure
    could **retire or swap a warband seat's aspect between realms**, or hand a signature move down a
    branch — a narrative reason the build changes, not just more cards.

### Twinfang / rogue subsection (mine Verso ranks + Maelle stances hard)

Our rogue: Flow 0-6 built on graded taps (Bullseye/Perfect/Good), beat speeds up as Flow climbs;
combo points → Eviscerate finisher; Coup de Grâce dump; boss "Opening" punish windows where dumps
hit ×1.9; one spacebar dodge.

- **The REDLINE Creed (Verso's Perfection Rank).** Flow gains an S-rank overlay: **every clean beat
  climbs D→C→B→A→S, each rank multiplies dump damage; a whiffed beat OR a hit taken demotes one rank
  (once per boss beat).** The untouchable rhythm run gets exponentially rewarded; one sloppy patch
  cascades. A temperament card that turns "never get touched" into the whole fantasy — greed dial in
  its purest form, and it reuses Flow rather than adding a meter.

- **The CRESCENDO Keystone (Maelle's Virtuose).** A spectacle window you can *only* enter by nailing
  **3 consecutive Bullseyes at Flow 6**: the beat locks at max speed, every tap counts Bullseye-tier,
  Flow can't decay, for ~8s. The +200%-no-downside state, earned by perfect play, gated behind a
  setup — never a toggle, always a payoff.

- **FLOW-BAND Boons (Maelle stance-conditional skills, no button).** Instead of a stance key, Boons
  read the band Flow sits in: *Flow 5-6 → Eviscerate cleaves a second time; Flow 3-4 → Coup de Grâce
  refunds a combo point; Flow 0-2 → taps rebuild faster.* Same buttons, different behavior by state —
  the stance-switch feel with **zero button-count cost** (ABILITY LAW clean).

- **The TWILIGHT signature CD (Sciel).** Twinfang's ~1-min button **spends banked combo points** to
  open a Twilight burst: for one window, **Opening dumps hit doubled but Flow can't bank** — commit
  your stockpile for a spike, then rebuild from zero. Amplifies skill (you still must hit the Opening),
  never auto-damage; the Sun/Moon gate (§steal #2) can be the *unlock condition* for pressing it.

- **STAIN Rigs (Lune).** WHEN Bullseye THEN stamp a colored mark on the boss; the next Coup de Grâce
  *consumes* it for +hits. Player wires which earned-moment feeds which finisher — a cross-button
  builder/spender the rogue assembles from RIG cards.

- **BREAK-bar Opening (Break gauge).** Reskin our Opening as the visible gold bar (§steal #1): the
  rogue's ×1.9 dumps are the break-flagged key, so the punish window becomes a fill-then-pop meter the
  whole warband can read and set up around.

---

## 7. Sources

- Fextralife — Combat: https://expedition33.wiki.fextralife.com/Combat
- Fextralife — Sciel: https://expedition33.wiki.fextralife.com/Sciel
- Fextralife — Verso: https://expedition33.wiki.fextralife.com/Verso
- Fextralife — Monoco: https://expedition33.wiki.fextralife.com/Monoco
- Maxroll — Combat Guide: https://maxroll.gg/clair-obscur-expedition-33/guides/combat-guide
- Maxroll — Gustave Skills: https://maxroll.gg/clair-obscur-expedition-33/guides/gustave-skills-guide
- Maxroll — Lune Skills: https://maxroll.gg/clair-obscur-expedition-33/guides/lune-skills-guide
- Maxroll — Maelle Skills: https://maxroll.gg/clair-obscur-expedition-33/guides/maelle-skills-guide
- Maxroll — Weapons/Attributes/Upgrades: https://maxroll.gg/clair-obscur-expedition-33/guides/weapon-attributes-upgrades-guide
- Game8 — Difficulty Differences: https://game8.co/games/Clair-Obscur-Expedition-33/archives/514633
- Game8 — Gradient Attacks: https://game8.co/games/Clair-Obscur-Expedition-33/archives/517477
- Game8 — Weapon Scaling: https://game8.co/games/Clair-Obscur-Expedition-33/archives/517399
- Fandom — Pictos and Lumina: https://clair-obscur.fandom.com/wiki/Pictos
- TheGamer — Break/Stun explained: https://www.thegamer.com/clair-obscur-expedition-33-break-stun-explained/
- GameSpot — All Party Members & abilities: https://www.gamespot.com/gallery/all-party-members-in-clair-obscur-expedition-33-and-their-abilities/2900-6501/
- X/@expedition33 — Maelle stances statement: https://x.com/expedition33/status/1904215353510461892
