# WILDCARD SWEEP — design lessons from beyond the five anchors

Research file for Project Rift. Covers the wider net of games NOT in our anchor set (WoW retail,
Slay the Spire 1+2, Hades 1+2, Across the Obelisk, Expedition 33 have their own files — do not
duplicate them here). Two questions drive the picks: **(a)** how do the best rhythm/timing-melee
games make on-the-beat combat feel great, grade taps, punish misses, and stay fresh over a long
session? **(b)** how do the best build-craft games give depth without the stacking-soup trap our
anti-stacking law forbids? Written for other design agents — dense, factual, plain language.

## 1. Why these games

Rift's pilot spec (Twinfang·Tempo) is a **rhythm rogue**: graded taps (Bullseye/Perfect/Good)
build a Flow meter that accelerates the beat, combo points spend into an Eviscerate, one dump
(Coup de Grâce), and boss "Opening" punish windows pay ×1.9. That is a rhythm-melee game with an
active resource loop bolted to a deterministic MMO-combat skeleton. So the rhythm-melee picks are
the load-bearing ones: **Hi-Fi Rush** (everything-on-beat, grade + forgiveness), **Crypt of the
NecroDancer** (move-on-beat, groove chain that resets), **Metal: Hellsinger** (Fury multiplier
that decays not resets), **Sekiro** (deflect chains, posture as the real health bar), **Nioh**
(Ki Pulse — an active resource-refund tap, the single most transferable mechanic to Flow), and
**Monster Hunter** (weapon identities as self-contained sub-games — the model for our per-spec
minigames). For build-craft: **Balatro** (synergy grammar + greed of skipping), **Path of Exile**
(Ascendancy = capstone sub-spec), **Dead Cells** (scaling colors force build commitment). Two
cautionary tales guard our anti-stacking law and our signature-CD rule: **Risk of Rain 2** (proc
stacking soup — thrilling but the exact thing we banned) and **FFXIV** (the 2-minute meta —
homogenization from a rigid burst cadence). **DMC/God of War** style meters round out the
"reward variety, punish repetition" lesson.

---

## 2. Per-game sections

### Hi-Fi Rush (Tango Gameworks, 2023) — everything-on-the-beat action
**System.** The entire world pulses on the song's BPM; combat, jumps, dashes, even parries land
harder when synced. Two hidden grades matter: attacks are scored for **"Just Timing"** (on-beat
accuracy), and end-of-fight the game grades three axes — **Score** (moves + damage), **Just
Timing** (rhythm accuracy, must stay ≥85% for an S), and **Time** (speed). Final rank needs S in
two of three plus A in the last; a no-damage clear adds a bonus star. Crucially, **you are never
forced onto the beat** — off-beat inputs still work, they just do less and break your rating. A
metronome-cat companion (Beat) and constant visual pulse teach the tempo so non-rhythm players can
play by feel.
**Why it feels great.** The floor is "mash and still win"; the ceiling is "every hit on the
downbeat." The grade is *ambient* — you feel the extra oomph of a synced hit before you ever read
a number. Missing the beat is soft-punished (less damage, worse rank), never hard-punished (no
death, no combo wipe mid-swing).
**Missed-beat handling.** Pure forgiveness. Off-beat = suboptimal, not fatal. Difficulty scales by
enemy density and songs with busier subdivisions, not by tightening the input window to frame-
perfect.
**Lesson (one line).** Grade the beat but never gate on it — let the beat be the ceiling, not the
floor.

### Crypt of the NecroDancer (Brace Yourself, 2015) — move-on-the-beat roguelike
**System.** Every action (step, attack, dig) must happen on the beat or it does nothing / you lose
your **Groove Chain**. The chain is a coin/gold multiplier: kill 1 enemy → x2, kill 5 → x3 (x4 in
single-zone runs). **Any missed beat OR any damage taken resets the chain to x1.** Gold is your
build currency (shops between zones), so the chain directly funds your power — greed loop: push
the beat perfectly for richer builds, or play safe and stay poor. Enemies telegraph movement to
the same beat grid, so the whole board is a readable rhythm puzzle. The Bard character removes the
beat entirely (turn-based) as a built-in accessibility/difficulty toggle.
**Why it feels great.** The beat turns positioning into a rhythm puzzle: you're not just fighting,
you're *sequencing* moves to the bar line. The chain makes flawless play visibly, economically
rewarded.
**Missed-beat handling.** Hard reset of the *multiplier*, but not of your run — you don't die from
a missed beat, you just lose money velocity. This is the "reset creates tension" model (vs Metal's
"decay creates flow").
**Difficulty & fatigue.** New zones = new songs (fresh tempo/feel) + new enemy movement grammars.
Fatigue is fought by *changing the puzzle*, not just speeding it up.
**Lesson.** Tie the economy to the streak so flawless rhythm literally funds the build — a reset-
on-miss multiplier is the sharpest tension knob there is.

### Metal: Hellsinger (The Outsiders, 2022) — rhythm FPS with a Fury multiplier
**System.** Shooting/killing **on the beat** raises **Fury**, a damage multiplier that steps
1x → 2x → 4x → 8x → 16x. At 16x you deal max damage AND the song's full arrangement (vocals) kicks
in — the music itself is the reward. Off-beat actions and **taking damage** lower Fury; it also
**decays** gradually when you stop acting on-beat. A **Perfect** (tighter timing) hit deals more
damage, grants more Fury, and a Perfect killing blow scores higher than a "Good" kill. "Slaughter"
finishers and the "Ultimate" spend built resource.
**Why it feels great.** The soundtrack is a *diegetic* reward meter — you can hear your skill. The
decay (not instant reset) means one mistake doesn't erase everything; you claw the multiplier back.
**Missed-beat handling.** Graded (Perfect vs Good vs miss) + gradual decay. More forgiving than
NecroDancer's hard reset, which is why it sustains flow across a long level.
**Lesson.** A multiplier that *decays* keeps players in flow (recoverable); a multiplier that
*resets* creates spike tension. Pick per emotional target. And: make the reward audible/visible,
not just numeric.

### Sekiro: Shadows Die Twice (FromSoftware, 2019) — deflect & posture
**System.** Two bars per combatant: **Vitality** (health) and **Posture** (a stagger/stability
gauge). Deflecting an attack at the last moment (a perfect parry) adds almost nothing to *your*
Posture but chunks the *enemy's*. Fill an enemy's Posture → **Deathblow**. Key coupling: **an
enemy's Posture recovers faster the higher their Vitality** — so you must chip health to make
posture damage "stick," creating an aggression loop (deflect to break, but also hit to make breaks
permanent). Your own Posture recovers after ~1s of not taking posture damage, faster if you hold
guard. Deflect chains feel like a sword *conversation* — attack, deflect, attack, deflect at
tempo.
**Why it feels great.** It inverts Souls: retreating is *punished* (enemy posture regens), so the
game forces you into the rhythm. Mastery converts fear into a dance.
**Difficulty.** No difficulty slider; the "self-tune" is the skill ceiling itself — every fight is
a deflect-timing exam. Prosthetic tools are situational counters (soft build-craft).
**Lesson.** Make a *second* bar (Posture) the real objective, decoupled from health, and tie its
recovery to a variable so the player can't just turtle — the timing loop becomes mandatory, not
optional.

### Nioh 1/2 (Team Ninja, 2017/2020) — the Ki Pulse (MOST transferable)
**System.** Attacks spend **Ki** (stamina). After a combo, a spent-Ki cloud lingers and a window
opens; pressing **R1 at the right moment ("Ki Pulse")** instantly refunds a big chunk of the Ki
you just spent. The window opens as the recovery particles converge and closes ~0.3s after they
return (~0.5s total for advanced timing). **Flux** (switching stance during the pulse) refunds
~20% more Ki; **Flux II** (double stance switch) ~40% more. Higher Strength returns a higher
percentage; longer combos leave less Ki to reclaim. So the optimal loop is: attack → Ki Pulse on
the beat → keep pressure without gassing out. Perfectly timed pulses also clear enemy "Yokai
realm" pools from the floor. This is an **active resource-refund tap** — the exact shape of Flow.
**Why it feels great.** It turns stamina from a *passive drain you wait out* into an *active skill
you perform*. Good players never stop attacking because they refund their own gas on rhythm.
**Missed-tap handling.** Miss the pulse → you recover Ki slowly (passive), so you must pause and
lose pressure. Punishment is *tempo loss*, not damage/death. Fully forgiving to survival, brutal to
DPS.
**Lesson.** The single best steal for a resource-rhythm rogue: **an on-beat tap that refunds the
resource you just spent**, with tiered payouts for harder timing (Flux/Flux II = risk ladder).
This is "active reload beats passive regen" in its purest form.

### Monster Hunter (Capcom, series) — weapons as self-contained sub-games
**System.** 14 weapons, each a *different minigame* with its own gauge, timing, and state machine —
this is the model for Rift's "each spec is its own minigame":
- **Longsword — Spirit Gauge.** Landing hits fills a gauge; spending it on the **Spirit
  Roundslash** combo levels a color buff **white → yellow → red**, each color adding damage. Red
  decays over time, so you must keep re-hitting the combo to sustain it. Counters (**Foresight
  Slash**, **Iai Spirit Slash**) both defend AND refill/upgrade the gauge — defense feeds offense.
- **Charge Blade — Phials.** Charge phials in sword mode, morph to axe, dump them in a big
  **Amped Elemental Discharge**. **Guard Points** (blocking during a morph animation) reward
  precise timing with a free block + charge. A whole "bank then burst" economy.
- **Insect Glaive — Kinsect extracts.** Send a pet bug to harvest **red/white/orange** essences
  off body parts; collecting all three ("Triple Up") unlocks the strongest moveset for a duration.
  Build-and-maintain buff management mid-fight.
- **Great Sword — charge timing.** Hold to charge a slash through levels; releasing at the peak
  ("True Charged Slash") is a commit-timing gamble against monster telegraphs.
**Why it feels great.** Same monster, radically different *game* per weapon. Mastery is per-weapon,
so the content multiplies without new enemies. Every weapon has a "build a resource → spend it in a
committed burst" heartbeat.
**Lesson.** Give each spec a *distinct verb and gauge*, not a stat reskin — the minigame IS the
class identity. And bake "defense refills your offense gauge" into at least one counter move.

### Devil May Cry 5 / God of War — style meters (reward variety, punish repetition)
**System (DMC5).** The **Stylish Rank** climbs **D → C → B → A → S → SS → SSS** as you deal damage.
Two anti-degenerate rules: the gauge **depletes on inactivity**, and **repeating the same move
stops filling it** — variety is mandatory. Taking damage drops you **two ranks** (B→D, A→C,
S/SS/SSS→B); higher ranks also drain faster, so the top is a knife-edge. God of War's combat
grades combos similarly but with fewer teeth. The meter is pure spectacle/score, decoupled from
survival.
**Lesson.** If you want *expressive* combat, reward move *variety* and punish spam — a meter that
won't rise on repeats forces players to use their whole kit. Damage-drops-two-ranks is a clean
"one mistake costs a lot but not everything" curve.

### Balatro (LocalThunk, 2024) — synergy grammar + the greed of skipping
**System.** A run is **8 Antes**, each = **Small Blind → Big Blind → Boss Blind** (score targets;
Boss Blinds add a rule-warp you can't skip). You can **skip** the Small/Big blind to grab a **Tag**
(a reward: free packs, extra money, a guaranteed rare joker) instead of the score + shop —
trading immediate power for a different kind of power, and pressure later. Power comes from
**Jokers** (max 5) whose effects compose into a **grammar**: some add flat **Chips**, some add
**Mult**, some **×Mult** (the multiplicative payoff tier), some trigger *other* jokers, some scale
per-hand. Winning is about *ordering and combining* a small set, not hoarding — the 5-slot cap
forces cuts. Boss Blinds ("debuff all face cards", "only 1 hand", etc.) attack whatever your build
leans on, testing robustness.
**Why it feels great.** Tiny rule set, combinatorial ceiling. The ×Mult tier is the dopamine — you
chase the joker that *multiplies* your engine, not adds to it. Skipping is a legible greed fork.
**Lesson.** A **hard slot cap** + a **tiered scaling grammar** (add → multiply → multiply-the-
multipliers) makes build-craft about *composition and cuts*, not accumulation — the antidote to
stacking soup. And a **skip-for-a-tag** fork turns "less now" into a real strategic choice.

### Path of Exile (Grinding Gear, series) — Ascendancy as capstone sub-spec
**System.** On top of a huge passive tree, each class picks an **Ascendancy** — a compact sub-class
(e.g. Slayer, Assassin, Elementalist) unlocked mid-campaign via a trial. An Ascendancy is ~6-8
dense nodes that **redefine how the build plays** (e.g. Slayer = leech + cull + overkill; Assassin
= crit + poison identity). It's a *capstone commitment*: chosen once, it names your build's fantasy
and warps every later choice around it. Separately, PoE's power comes from *links* (support gems
modifying a skill gem) — again a **grammar of modifiers on a core action**, not flat stat piles.
**Why it feels great.** The Ascendancy is the moment a generic class becomes *your* build; the ~6
nodes are individually strong and thematically tight, so the choice is memorable, not incremental.
**Lesson.** A **small, dense, identity-defining capstone chosen once per run** (our Keystone) beats
a long drip of small nodes. And **modifiers-on-a-core-action** (support gems) is the reusable
build grammar — cards that change *how your one verb behaves*, not new verbs.

### Dead Cells (Motion Twin, 2017) — scaling colors force commitment
**System.** Three scaling stats as **colors**: **Brutality (red)**, **Tactics (purple)**,
**Survival (green)**. Each scroll picked raises that color's DPS by **×1.15 per point** (formula:
Base × 1.15^(stat−1)). Weapons/skills **scale off one color**; mutations (56 total: 12 per color +
20 colorless) also scale off scroll count. Because scaling is exponential per color, **spreading
across colors is strictly worse than committing** — the system *pushes* a build identity by making
focus mathematically dominant. Two active-slot weapons + two skills + limited mutation slots =
constant cut decisions.
**Why it feels great.** You "become" a color over a run; every drop is read through "does this
scale my color?" — legible, fast decisions.
**Lesson.** **Exponential per-lane scaling** makes commitment the correct play without a rule
forbidding hybrids — the *math* enforces identity. Color-coding the whole item pool makes draft
decisions instant.

### Risk of Rain 2 (Hopoo, 2020) — the stacking-soup CAUTIONARY TALE
**System.** Items stack, and each has a **proc coefficient** (0–1) gating how reliably it triggers
on-hit effects (Effective Chance = Item Chance × Proc Coefficient). Three stack shapes: **linear**
(Syringe +15% attack speed each), **exponential** (Shaped Glass ×2 damage / ÷2 HP, compounding —
2 stacks = ×4 damage), and **hyperbolic/capped** (Chance = 1 − 1/(1 + coeff×stacks), approaches
but never hits 100%). Late runs become **proc chains**: one hit triggers item A which procs item B
which procs item C — screen-clearing chain reactions. Thrilling, but by design **unbounded and
opaque** — the fun IS the runaway snowball.
**Why it's a cautionary tale for us.** This is *exactly* the "stacking soup" our anti-stacking law
forbids. It's ecstatic but: (1) power is illegible (nobody reads the proc chain live), (2) balance
is impossible past a point (the game leans into it via a rising difficulty clock instead), (3) skill
expression drowns in the item pile. Rift wants the *legibility* of Balatro's capped grammar, not
this. **What to steal anyway:** the **proc coefficient** idea — a single scalar that says "how
strongly does THIS action trigger on-hit stuff" — is a clean, deterministic way to make some taps
(Bullseye) carry more trigger-weight than others *without* stacking counts.
**Lesson.** Uncapped multiplicative stacking = huge dopamine, zero legibility/balance. Take the
proc-*weight* concept, refuse the uncapped stacking.

### FFXIV (Square Enix) — job gauges + the 2-minute-meta CAUTIONARY TALE
**System (good part).** Every job has a bespoke **job gauge** — a custom on-screen resource with
its own rules (Ninja's Ninki + mudra combos, Machinist's Heat + Battery, Black Mage's Astral
Fire/Umbral Ice element flip). These gauges *are* the class identity and give each job a distinct
"engine" to manage — the strongest argument for our per-spec minigames.
**System (cautionary part — the "2-minute meta").** In Endwalker, raid buffs and burst cooldowns
were retuned so **nearly every job aligns its big damage window to a 120-second cadence** (personal
buffs at 60s, party buffs at 120s). Result: jobs *converged* — everyone plays the same "hold
everything, dump on the 2-minute" rhythm, missing the window is disproportionately punishing, and
distinct job identities eroded. Widely criticized as homogenization from a too-rigid cadence.
**Lesson.** Bespoke gauges = identity (steal). But **do not force every spec onto one global burst
cadence** — Rift's signature CDs and Openings should sit on *different* rhythms per spec, or they
homogenize into "everyone bursts on the same beat." Variable windows > one metronome for the whole
roster.

### Quick hits (shallower, still useful)
- **BPM: Bullets Per Minute** — rhythm FPS where you can only shoot/reload/dodge *on the beat*;
  reloading is a per-beat action so **the reload itself is a rhythm mini-game** (see steal:
  active-reload). Harder than Hellsinger because actions are gated, not just graded.
- **Darkest Dungeon** — **Stress** as a second health bar and **Quirks** (persistent
  positive/negative traits that accrete on characters) — a model for *persistent per-raider
  personality* if AI warband members ever earn history. Also: the Affliction/Virtue coinflip at
  100 stress = high-variance pressure valve.
- **Guitar Hero / Rock Band lineage** — note-highways and **star power** (bank a meter by nailing
  marked phrases, spend it for a score multiplier at a moment of your choosing) — the canonical
  "earn a burst window, spend it when you choose" loop.

---

## 3. Cross-game patterns (the recurring lessons)

1. **Grade the timing, don't gate it.** Hi-Fi Rush, Metal Hellsinger, DMC all let sloppy play
   *work* while making precise play *better*. Frame-perfect gating (NecroDancer, BPM) is a harder,
   nicher feel. Rift already grades (Bullseye/Perfect/Good) — keep the floor forgiving.
2. **Reset vs decay is your tension dial.** A streak that **resets on one miss** (NecroDancer
   groove, DMC damage-drop) = spike tension, "don't blow it." A streak that **decays gradually**
   (Metal Fury) = sustained flow, "claw it back." Choose per moment: bosses/Openings want reset
   stakes; trash/flow wants decay.
3. **Active resource-refund beats passive regen.** Nioh's Ki Pulse and star-power/active-reload all
   turn a *passive wait* into a *skill you perform*. Any resource that currently ticks back on its
   own is a candidate to become an on-beat tap.
4. **Defense should feed offense.** Sekiro deflect chunks enemy posture; MonHun Longsword counters
   refill the Spirit Gauge; Charge Blade Guard Points bank charge. The best timing kits make the
   defensive answer *also* an offensive input — no dead defensive beats.
5. **A second bar, decoupled from health, is where mastery lives.** Sekiro Posture, Metal Fury,
   style meters. The interesting game is often played on the *non-health* gauge; tie its behavior to
   a variable so players can't cheese it by turtling.
6. **Cap the slots, tier the scaling — that's build depth without soup.** Balatro (5 jokers, add →
   ×Mult), PoE (support-gem grammar), Dead Cells (exponential per color). Depth = *composition +
   cuts*, not accumulation. RoR2 shows the opposite extreme: uncapped stacking = ecstatic but
   illegible and unbalanceable.
7. **Make the reward sensory, not numeric.** Metal's vocals at 16x, Hi-Fi Rush's synced-hit
   feel, style-rank announcer barks. The player should *feel/hear* the grade before reading it.
8. **Fight rhythm fatigue by changing the puzzle, not just the speed.** NecroDancer/MonHun rotate
   the *grammar* (new songs, new enemy grids, new weapon) rather than only tightening windows. Rift
   has this lever via boss telegraph variety + per-node modifiers.

---

## 4. Difficulty & self-tuning systems worth copying

- **Grade-based soft difficulty (Hi-Fi Rush).** The *rank* is the hard mode; the fight is beatable
  by anyone. Self-selecting: casuals clear, experts chase S. Rift's EASE dial (COMFORT↔BITE) is the
  same idea made explicit — let the player pick their window width for a damage trade.
- **Built-in toggle character (NecroDancer's Bard, Sekiro's tools).** A first-class "no-beat" or
  "assisted" mode inside the fiction, not a menu apology. Rift's AI-backfill + EASE cards can be
  this: a player who can't hold the beat leans on comfort rolls, not a difficulty menu.
- **Skill ceiling AS the difficulty curve (Sekiro).** No slider; the deflect exam scales itself.
  Risky for accessibility — Rift should pair any such spike with an EASE-comfort escape hatch.
- **Rule-warp gates (Balatro Boss Blinds).** Periodic modifiers that attack whatever the build
  leans on force *robust* builds, not one-trick engines. Maps to Rift's node modifiers / mutator
  elites — a boss that punishes "always-Bullseye" players teaches variety.
- **Variable burst windows > one global cadence (FFXIV counter-lesson).** Self-tuning across a
  roster should preserve *different* rhythms per spec, or every seat converges.

---

## 5. STEAL CANDIDATES for Rift

Filter applied: borrow the grammar, innovate the sentence — each must exploit our timing-minigame /
deterministic engine, not just repackage.

**General (any spec):**
1. **Proc-weight per tap grade (from RoR2 proc coefficient).** Give each tap grade a deterministic
   *trigger weight* — a Bullseye carries proc-weight 1.0, Perfect 0.6, Good 0.3 — so RIG WHEN→THEN
   wires fire *proportionally to how clean the tap was*, without any stacking count. Clean play
   triggers your build harder; sloppy play still triggers it a bit. Pure, cap-free, deterministic.
2. **Ki-Pulse resource refund as a Module (from Nioh).** A Module that opens a ~0.3s "reclaim"
   window right after a spender; tap on-beat to refund part of the spent resource. Tiered like
   Flux: a *tighter* tap (or a stance/branch-switch on the same input) refunds more. Turns our
   passive Flow-decay into an active skill and rewards aggression. **Prime steal.**
3. **Star-power banked burst (from Guitar Hero).** A signature CD you don't fire on cooldown but
   *bank* by nailing marked "phrase" beats, then spend at a moment you choose — amplifies skill
   (you earned it by clean play), never button=damage. Fits our signature-CD law exactly.
4. **Decay-vs-reset per surface (from Metal Hellsinger + NecroDancer).** Make Flow *decay* during
   trash flow (recoverable, sustains groove) but *reset* if you fumble a boss Opening (spike
   stakes). Same meter, two emotional modes selected by context — a Creed could pick which.
5. **Variety-demand meter (from DMC style).** An optional STRAT/GREED card: repeating the same tap
   pattern stops a bonus meter from rising; rotating your combo shapes keeps it climbing. Punishes
   one-button spam, rewards using the whole kit — enforces expression without a new button.
6. **Boss-Blind rule-warp nodes (from Balatro).** Node/elite modifiers that debuff whatever the
   build leans on ("Bullseyes give no Flow this fight; Goods give double") to force robust,
   varied play. Deterministic, seeded, maps onto mutator elites.
7. **Skip-for-a-tag draft fork (from Balatro).** Let a player *skip* a boon pick to bank a **Tag**
   (guaranteed-rarity next draft, or bonus charge) — a legible greed fork of "less now for a
   sharper later," using our existing draft economy.
8. **Exponential per-lane scaling to enforce branch identity (from Dead Cells).** Make each
   sub-spec BRANCH a scaling "color": boons that scale off *how many same-branch cards you've
   taken* (capped, but steep) so committing to one branch is mathematically the strong play — the
   math enforces identity, no anti-hybrid rule needed.
9. **Ascendancy-style capstone (from PoE) = our Keystone, validated.** Confirms the design: ONE
   dense, identity-defining, chosen-once capstone > a drip of small nodes. Keep Keystones
   spectacle build-definers, 1/run, warping the whole kit around them.
10. **Support-gem modifier grammar (from PoE).** Author boons as **modifiers on the one core verb**
    ("your Eviscerate now also...", "Bullseyes now chain to..."), not as new verbs — respects the
    7-button ceiling while multiplying build depth. This is the reusable card grammar.
11. **Defense-refills-offense counter (from Sekiro/MonHun).** At least one dodge/parry answer per
    spec should *also* feed the offensive gauge (a perfect spacebar dodge grants Flow or a combo
    point) — no dead defensive beats, and it makes the DODGE RATION beats feel offensive.
12. **Posture as a boss-side second bar (from Sekiro).** A boss "Poise" gauge, separate from HP,
    that only clean taps + interrupts fill; fill it → a Deathblow-style vulnerability (stacks with
    our Opening ×1.9). Its recovery scales with boss HP so players can't turtle to safety — forces
    sustained pressure. Interrupt-by-ability (our pillar #3) becomes the poise-breaker.
13. **Kinsect-style buff-collection Module (from MonHun Insect Glaive).** A Module where you must
    "collect" 2-3 colored beats mid-fight (each from a different tap type) to unlock a "Triple Up"
    empowered window — build-and-maintain, rewards reading the whole rhythm not one tap.
14. **Audible/visible grade escalation (from Metal Hellsinger).** Tie an *ambient* reward to Flow
    tier — the fight music/VFX layers in as Flow climbs 0→6 — so the reward is felt before it's
    read. Cosmetic-only (client RNG stream), so it stays deterministic-safe.

**Twinfang / rogue-flavored subsection (Flow 0-6, accelerating beat, combo→Eviscerate, Coup de
Grâce dump, Opening ×1.9, one spacebar dodge):**
15. **Ki-Pulse Coup de Grâce (Nioh).** After the Coup de Grâce dump, open a tight ~0.3s reclaim
    window; a clean tap there refunds a chunk of combo points (a "Flux" branch refunds more but
    demands a tighter tap) — so the greedy dump doesn't have to gut your tempo if you nail the
    follow-up. Turns the dump from a reset into a *risk that skill can recover from*.
16. **Deflect-chain Openings (Sekiro).** During a boss Opening, chain graded taps into a rising
    "pressure" sub-meter; a full chain converts the ×1.9 into a Deathblow-style burst. Missing a
    beat mid-chain *doesn't* end it (decay), but a fumbled dodge does (reset) — the two-mode dial
    from steal #4, applied to the signature moment.
17. **Beat-sync Bullseye halo (Hi-Fi Rush).** Make the accelerating beat *visible* as a pulsing
    ring the player syncs to; a Bullseye landed on the downbeat gets a small bonus (proc-weight
    1.0 from #1). Never required — off-beat taps still grade Good — but it gives the rogue a
    Hi-Fi-Rush "everything on the beat" ceiling on top of the existing window grading.
18. **Longsword-color Flow tiers (MonHun).** Reframe Flow 0-6 as escalating "edge" colors that
    *decay* if you stop hitting clean — at the top tier the beat is fastest AND Eviscerate gains a
    color-gated rider. Sustaining top Flow becomes the skill expression, and the decay (not reset)
    keeps the rogue in a groove between Openings.

---

## 6. Sources

- Nioh Ki Pulse / Flux timing & refund tiers: https://nioh3.net/guides/ki-pulse/ ·
  https://www.gamesradar.com/nioh-2-ki-pulse-guard-dodge-explained/ ·
  https://attackofthefanboy.com/guides/nioh-2-how-to-ki-pulse-how-to-restore-stamina/
- Hi-Fi Rush Just Timing / S-rank grading (≥85%): https://gamerant.com/hi-fi-rush-how-to-get-s-rank/ ·
  https://www.videogamer.com/guides/hi-fi-rush-how-to-get-s-rank-rating-in-every-fight/
- Metal: Hellsinger Fury 1x→16x, decay, Perfect vs Good:
  https://www.gameskinny.com/tips/metal-hellsinger-how-to-increase-fury-to-get-high-scores/ ·
  https://progameguides.com/metal-hellsinger/how-to-keep-fury-up-in-metal-hellsinger-tips-and-tricks/
- Crypt of the NecroDancer Groove Chain (x1→x3/x4, reset on miss/damage):
  https://crypt-of-the-necrodancer.fandom.com/wiki/Groove_Chain · https://cadence.link/general/coin-multiplier/
- Sekiro Posture / deflect / vitality-recovery coupling:
  https://sekiroshadowsdietwice.wiki.fextralife.com/Posture · http://whats-in-a-game.com/sekiros-genius-posture-mechanic/
- DMC5 Stylish Rank (D→SSS, variety, damage drops two ranks):
  https://devilmaycry.fandom.com/wiki/Stylish_Rank · https://www.shacknews.com/article/110322/stylish-points-and-style-ranks-in-devil-may-cry-5
- Balatro Antes/Blinds/skip-Tags (8 antes, Small/Big/Boss, skip for Tag):
  https://balatrowiki.org/w/Blinds_and_Antes · https://en.wikipedia.org/wiki/Balatro
- Dead Cells scaling colors (Brutality/Tactics/Survival, ×1.15^(stat−1), 56 mutations):
  https://deadcells.wiki.gg/wiki/Stats · https://deadcells.wiki.gg/wiki/Mutations
- Risk of Rain 2 proc coefficient & stacking (linear/exponential/hyperbolic):
  https://riskofrain2.wiki.gg/wiki/Proc_Coefficient · https://riskofrain2.wiki.gg/wiki/Item_Stacking
- FFXIV two-minute-meta / homogenization critique:
  https://forum.square-enix.com/ffxiv/threads/476776/ (community thread) ·
  Job gauges (general knowledge; e.g. Ninja/Machinist/Black Mage gauges)
- Monster Hunter weapon systems (Longsword Spirit Gauge, Charge Blade phials/Guard Points, Insect
  Glaive extracts, Great Sword charge): Monster Hunter World/Rise wikis (general knowledge).
- Path of Exile Ascendancy classes & support-gem links: general knowledge, poewiki.net.
- Guitar Hero / Rock Band Star Power; BPM: Bullets Per Minute; Darkest Dungeon Stress/Quirks:
  general knowledge.
