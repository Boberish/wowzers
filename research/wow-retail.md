# World of Warcraft (retail) — class/spec design reference

Researched 2026-07-09. Live era = **Midnight (patch 12.0.7, Season 1)**, the expansion after The War
Within. Numbers churn every patch — verify before leaning on them for balance. This file is the
spec-identity + rotation-grammar quarry. Filter for stealing: *borrow the grammar, innovate the
sentence* — a stolen system must exploit our timing-minigame / deterministic engine, not repack.

---

## 1. Build grammar

WoW has **13 classes**, each with **2–4 specializations** (specs) — 40 specs total. A spec is the
real identity: it fixes your role (tank / healer / DPS), your resource, and your rotation. On top of
the spec you layer, in order: (a) the **class talent tree** (shared utility/survival across the
class), (b) the **spec talent tree** (the rotational build — builders, spenders, procs, capstones),
(c) a **Hero Talent tree** (a ~11-node sub-spec each spec picks 1 of 2 flavors of — the "mini-spec"
identity layer added in The War Within), and (d) **Apex Talents** (Midnight: a 4-point capstone at
the very bottom of the spec tree, level 81, that super-charges the ONE ability at the spec's core
fantasy). Talent trees are **point-buy DAGs**: you spend a fixed budget of points down gated rows,
so you can't take everything — every build is a set of exclusions. Nodes come in three shapes:
**passive** (numbers), **active** (new button), and **choice nodes** (pick 1 of 2 — the deliberate
either/or). Gear supplies stats + **tier sets** (a raid armor set that grants a 2-piece and 4-piece
spec-specific rotational bonus each season — temporary borrowed power that reshapes the rotation for
~6 months, then is replaced). Design north star, stated by Blizzard for decades: **"bring the player,
not the class"** — every spec should carry enough unique group value that no one is benched for their
class. Midnight's meta pushed **consistent uptime over theatrical 2–3-min burst windows**.

---

## 2. Spec / class roster

Format per spec: fantasy · core mechanic/resource loop · signature moment. Rogue is deep; six other
design-notable specs broken out after the roster.

**Death Knight** (Runes + Runic Power; a rune-recharge economy). *Blood* — vampiric tank, spends
runes on Death Strike to self-heal off a rolling damage-taken pool, manages Bone Shield stacks.
*Frost* — dual-wield or 2H burst, builds Runic Power, Killing Machine + Rime procs, Pillar of Frost
window; Breath-of-Sindragosa build (see deep-dive). *Unholy* — disease + pet summoner; Midnight
reworked it into a full **Scourge summoner** (Army of the Dead / Apocalypse spawning ghoul swarms),
Festering Wounds you pop with Scourge Strike, Sudden Doom procs.

**Demon Hunter** (Fury + resource-state metamorphosis). *Havoc* — hyper-mobile melee, Demon's Bite →
Chaos Strike / Blade Dance, Momentum/Inertia movement buffs, Metamorphosis burst. *Vengeance* —
tank, Soul Fragment management (shatter demons into souls you consume to heal), Fiery Brand + Demon
Spikes. *Devourer* (**NEW in Midnight**) — the long-awaited third spec: a **mid-range (20–25 yd)
Void caster** who reaps souls; Metamorphosis is no longer a cooldown but a **resource-driven "Void
Metamorphosis" state** you sustain as long as you keep feeding it souls (see deep-dive).

**Druid** (four forms, four resource systems — the shapeshifter). *Balance* — ranged caster,
**Eclipse** state-machine (see deep-dive), Astral Power → Starsurge/Starfall. *Feral* — melee, combo
points + Energy like a rogue, bleeds (Rip/Rake) + Tiger's Fury/Berserk windows, snapshotting. *Guardian*
— bear tank, Rage, Ironfur/Frenzied Regen, Thrash/Mangle. *Restoration* — HoT healer, blanket
Rejuvenation/Lifebloom/Wild Growth, Efflorescence ground pool, ramp-then-coast.

**Evoker** (Essence resource + **Empower** cast — hold a button to level 1/2/3, release). Mid-range
(25 yd) dragon. *Devastation* — burst caster, Fire Breath/Eternity Surge Empowers, Dragonrage window,
Disintegrate channel. *Preservation* — Empowered heals (Spiritbloom/Dream Breath), Echo + Temporal
Anomaly, Rewind rollback-heal. *Augmentation* — **support DPS that mostly buffs allies** (see deep-dive).

**Hunter** (Focus). *Beast Mastery* — pet commander, Barbed Shot frenzy stacks + Bestial Wrath,
fully mobile (all-instant). *Marksmanship* — precision ranged, Aimed Shot / Rapid Fire, Trueshot
window, Precise Shots procs. *Survival* — the melee hunter, mongoose-bite fury + Wildfire Bomb DoTs,
Kill Command/Coordinated Assault.

**Mage** (Mana + spec sub-resource). *Arcane* — Arcane Charges (0–4 ramp that scales Blast damage
and mana cost), burn/conserve phases, Arcane Surge burst. *Fire* — crit-chain: Fireball → **Hot
Streak** (two crits = instant Pyroblast), Combustion window forces guaranteed crits. *Frost* — control
caster, Fingers of Frost + Brain Freeze procs (Flurry → shatter Ice Lance), Frozen Orb + Icy Veins.

**Monk** (Energy/Chi melee; Mana healer). *Brewmaster* — stagger tank (damage smeared over time via
Stagger, purged by Purifying Brew), Keg Smash/Blackout Kick. *Windwalker* — combo dancer, Chi builder/
spenders, Storm Earth and Fire clones, Fists of Fury channel, Mastery rewards not repeating the same
button. *Mistweaver* — **Fistweaving** healer that heals by meleeing the boss (see deep-dive).

**Paladin** (Holy Power — 0–5 builder/spender). *Holy* — Holy Shock + Light of Dawn healer, beacon
transfer. *Protection* — block tank, Shield of the Righteous (Holy Power spend for active mitigation),
Avenger's Shield, Consecration ground uptime. *Retribution* — melee, build Holy Power → Templar's
Verdict / Divine Storm, Wake of Ashes + Crusade/Avenging Wrath window.

**Priest** (Mana; Shadow = Insanity). *Discipline* — **Atonement** healer: cast damage on the boss,
that damage heals everyone with your Atonement HoT — a healer that heals by DPSing; Schism/Radiance
setup then damage-dump. *Holy* — traditional dual-HoT/direct healer, Holy Words (Serenity/Sanctify
reset off other casts), Apotheosis/Divine Word. *Shadow* — DoT caster, Insanity resource, Shadowfiend
+ Voidform/Void Eruption, Mind Blast/Devouring Plague, Mind Flay filler.

**Rogue** — see the deep-dive below (all three specs).

**Shaman** (Maelstrom). *Elemental* — caster, Lava Burst (guaranteed crit on Flame Shock), Maelstrom
→ Earth Shock/Earthquake, Stormkeeper, Fire Elemental. *Enhancement* — melee, Maelstrom Weapon stacks
(melee builds instant-cast spells), Stormstrike, Feral Spirit wolves, Ascendance. *Restoration* —
Chain Heal + Riptide, Healing Rain, totems, Spirit Link Totem (raid damage-share cooldown).

**Warlock** (Mana + Soul Shards — 0–5 fragments spent on big spells). *Affliction* — multi-DoT rot
(Agony/Corruption/Unstable Affliction) + Malefic Rapture shard-dump, Soul Rot. *Demonology* — pet
army summoner (Call Dreadstalkers, Hand of Gul'dan → Wild Imps you Implode), Demonic Tyrant window.
*Destruction* — direct-damage burn (Immolate → Incinerate → Chaos Bolt shard-dump), Havoc cleave-copy,
Rain of Fire.

**Warrior** (Rage). *Arms* — 2H, Mortal Strike + Overpower, Colossus Smash armor-break window,
Execute. *Fury* — dual-wield frenzy (see deep-dive). *Protection* — shield tank, Shield Block/Ignore
Pain active mitigation, Shield Slam/Revenge, Last Stand.

### Deep-dive: Rogue (Energy + Combo Points — the universal builder/spender chassis)

All rogues run the same skeleton: **Energy** regenerates passively (a soft cap you never want to sit
full at); **builder** abilities spend Energy to generate **Combo Points** (0–5, sometimes 6–7 via
talents); **finishers** spend Combo Points, and their power/duration scales with points spent (a 5-CP
finisher is much stronger than 1-CP). The art is never wasting Energy (pooling before windows) and
never over-/under-capping Combo Points. Each spec bolts a distinct engine onto this chassis.

- **Assassination** — the poison/bleed assassin. DoT-and-poison "rot" build: keep Garrote + Rupture
  bleeds and Deadly/Wound Poison up, build CP, dump into **Envenom** (a finisher that spikes poison
  application and damage). Midnight reworked it toward a **controlled rot** identity: the skill line
  is now **chaining Envenoms** — refresh the short Envenom buff before it falls off, keeping it 100%
  uptime — with *less* reliance on micro-stealth openers and strict DoT-juggle. Cooldown: **Deathmark**
  (a debuff that duplicates your bleeds/poisons on the target for a window — stack everything under it).
  Feel: patient, layered, a slow build to an overwhelming poison spike.
- **Outlaw** — the swashbuckling pirate; the RNG/proc spec. Core loop: **Sinister Strike** (can
  randomly strike twice, granting a free **Ambush** proc via Opportunity) → build CP → **Dispatch**
  finisher, with **Between the Eyes** as a burst/utility finisher. Signature system: **Roll the Bones**
  — a finisher that grants random combat buffs, gambling for a good roll. **Midnight reworked it from
  6 discrete buffs to 4 unified/layered buffs (less RNG variance, more consistency).** Cooldowns
  cascade off **Restless Blades** (finishers reduce all your cooldowns), so the spec is a fast,
  low-downtime whirl. **Blade Flurry** cleaves single-target damage to nearby enemies. Feel: fastest,
  jangliest, most reactive rogue — you play the procs the game hands you.
- **Subtlety** — the shadowdancer; the burst-window spec, sometimes called a **90-second spec**.
  Baseline: build with **Backstab** / **Shadowstrike** (Shadowstrike needs stealth), spend on
  **Eviscerate**; manage **Shadow Dance** (a short window that grants stealth abilities out of stealth)
  and **Symbols of Death** (a personal damage buff you pre-cast). The whole spec orbits its burst:
  every ~90s line up **Shadow Blades + two Shadow Dances** and cram maximum damage into those windows;
  **Shadow Techniques** passively feeds extra Energy/CP. Feel: setup-heavy, positional, feast-or-famine
  — enormous when the window lands, thin between.

**Rogue Hero Talents** (each spec picks 1 of its 2): **Deathstalker** (Assn/Sub — mark a target,
stack a Deathstalker's Mark debuff, execute-flavored payoff), **Fatebound** (Assn/Outlaw — a
literal **coin-flip**: finishers flip a coin, matching flips stack a Fatebound Coin buff that snowballs
— pure escalating-luck fantasy), **Trickster** (Outlaw/Sub — Unseen Blade applies Fatebound-free
"Coup de Grace" style flourishes, flashy blade-illusion payoffs). These are the closest WoW analog to
Rift's **branch/sub-spec** layer: a small talent island that re-flavors an existing rotation without
being a whole new spec.

### Deep-dive: Fury Warrior — the Enrage self-feeding loop

The cleanest **positive-feedback rotation** in the game. Loop: generate Rage → spend it on **Rampage**
→ Rampage triggers **Enrage** (a self-buff: more damage, and often more Rage generation / haste) →
under Enrage your **Bloodthirst / Raging Blow / Thunder Blast** hit harder and generate more Rage →
which fuels the next Rampage → keeping Enrage lit. The skill is **Enrage uptime**: Rampage is your
only Enrage source, so you time it to never let Enrage drop, but not so early you Rage-starve. **Execute**
phase below ~35% target HP floods the rotation with a cheap hard-hitting finisher. Feel: fast, sloshing,
"keep the fire lit" — a rhythm of maintaining a buff you must actively re-light, not a burst you save.

### Deep-dive: Augmentation Evoker — the support-DPS buff spec

A genuinely unusual archetype: a **DPS spec whose damage mostly comes from buffing two teammates**,
added in Dragonflight and still the game's only true "support" role. Three levers: **Ebon Might**
(donate 16% of your primary stat, split among nearby DPS, while your own damage is up — must keep it
rolling, and it only buffs DPS, never tank/healer), **Prescience** (throw a short crit-buff onto a
teammate — you want it on the **burstiest** allies so it multiplies the most damage), and **Breath of
Eons** (a raid cooldown that banks a slice of your buffed allies' damage and detonates it — you sync
it with their personal cooldowns). The gameplay is **target selection + timing**, not personal DPS:
pick the right two partners, keep the donation buffs 100% up, and align the burst. Design lesson:
a whole engaging spec built on *making other players' numbers bigger* — pure co-op interplay as a
rotation. (It also warps group-building: everyone wants the Aug, and Aug wants the strongest carries.)

### Deep-dive: Frost DK "Breath of Sindragosa" — the sustain-the-channel build

A talent that turns Frost into a **resource-brinkmanship** build. Breath of Sindragosa is a toggle you
activate that **drains Runic Power every second and deals damage every second — it stays on only while
you can keep feeding it Runic Power**. Drop to zero RP and it falls off, wasting the window. So the
entire rotation reorganizes around never running dry: pool resources before pressing it, then thread
rune-spends and RP-generators to keep the meter alive for as long as possible. Feel: white-knuckle
sustain — a self-imposed juggling act where the fun is *how long can I keep it running*, not the press.

### Deep-dive: Balance Druid — the Eclipse state machine

Astral spellcasting toggles between two states. Casting **Wrath** (Nature) a few times enters **Solar
Eclipse** (empowers Nature/Starfire-adjacent spells); casting **Starfire** (Arcane) enters **Lunar
Eclipse** (empowers Arcane). You bounce between the two, banking **Astral Power** to spend on
**Starsurge** (single-target) or **Starfall** (AoE), with the **Dragonrage/Incarnation** window
doubling your output. The identity is a **two-state pendulum**: which Eclipse you're in changes which
button is best, so you're always reading the state, not mashing one spell. Feel: a slow ramp that
snowballs, with a satisfying flip-flop cadence.

### Deep-dive: Mistweaver Monk — "Fistweaving" (heal by attacking the boss)

A healer that **deals melee/spell damage to the enemy and that damage converts into healing** for the
party. Modern Mistweaver interleaves **Rising Sun Kick / Blackout Kick / Tiger Palm** (damage that
triggers healing via Ancient Teachings / **Jadefire Stomp / Jade Empowerment** chains) with direct
heals (Vivify, Renewing Mist, Enveloping Mist, Soothing Mist channel). The tension is **facing the
boss and playing a melee DPS rotation while watching health bars** — offense and healing are the same
buttons. Design lesson: collapse the heal/DPS dichotomy into one active loop so the healer is never
idle-watching bars. (Discipline Priest's **Atonement** is the ranged cousin: DoT/nuke the boss, the
damage heals your Atonement'd allies.)

### Deep-dive: Devourer Demon Hunter (NEW, Midnight) — sustained metamorphosis

The newest spec in the game (2026) and a clean modern-design showcase. A **mid-range Void caster**
(20–25 yd, dips to melee only for specific combos) that reaps souls of the slain. Its Metamorphosis is
**no longer a cooldown** — it's **Void Metamorphosis, a resource-driven state you enter and then
sustain by continually feeding it Soul Fragments**. The loop is generate souls → bank into the meta
state → keep it alive. It reached S-tier in Season 1 *without* a prior expansion's tuning data — a
signal that "sustain a powered-up state via a resource you keep earning" is a robust, feel-good
template. Echoes Breath of Sindragosa's brinkmanship but framed as a *fantasy transformation* you keep
alight rather than a drain you survive.

---

## 3. Ability / upgrade design patterns

**Rotation grammar (the recurring shapes).**
- **Builder / spender** — the core loop of most specs (Combo Points, Holy Power, Soul Shards, Chi,
  Maelstrom, Astral Power): build a 0–max resource with cheap presses, dump on a finisher whose payoff
  scales with how much you spent; never overcap, never starve. The most-reused, most-portable chassis.
- **Procs** — random/conditional free-or-empowered casts (Hot Streak, Brain Freeze, Rime, Sudden Doom,
  Opportunity, Killing Machine). Best procs are **reactive interrupts to your plan** — the game hands
  you a better button and you must notice and pivot. Bad procs = "press when lit, no decision."
- **Maintenance buffs / DoTs** — kept at 100% uptime (Enrage, Envenom buff, bleeds, Ebon Might, Flame
  Shock); skill = refresh-timing (pandemic: refresh in the last ~30% to extend, not clip). Rewards
  planning, punishes tunnel vision.
- **State machines** — Eclipse, Stagger, Arcane burn/conserve, Voidform: read a state, change which
  button is correct. Depth without adding buttons.
- **Windows** — a short empowered phase you set up and burst inside (Combustion, Dragonrage, Shadow
  Dance, Pillar of Frost, Metamorphosis): setup → align → dump.
- **Ramps** — heal/DoT specs pre-stack (Disc Atonement blanket, seed-stacking) then cash out on a known beat.
- **Execute phases** — under a HP threshold (~20–35%) a cheap hard-hitter unlocks (Execute, Kill Shot,
  Touch of Death); the rotation reshapes for the fight's last stretch.

**Talent-tree design.** Point-buy DAGs force exclusion — every build is what you *gave up*. **Choice
nodes** (pick 1 of 2) are the deliberate identity forks. Gates by row pace power. **Capstones** at the
bottom are build-definers. **Hero Talents** (TWW) are ~11-node islands, each shared by 2 specs, that
act as **sub-specs / mini-identities** — you pick 1 of 2 flavors, and they layer a small themed engine
(Fatebound's coin-flip, Rider of the Apocalypse's summoned horsemen) onto your existing rotation
*without* a full respec. **Apex Talents** (Midnight) are the newest layer: a 4-point capstone at the
tree bottom (level 81) that **super-charges the single ability at the spec's core fantasy** (e.g.
Frost's Frostwyrm's Fury +100% to first target + haste + extends Pillar of Frost). The stated intent:
pull each spec toward *one* defining button and a cleaner rhythm instead of juggling ten overlapping
procs. Design lesson for us: a capstone should **amplify the thing the spec already is**, not add a
tenth thing to track.

**Tier sets + borrowed power — what worked / failed.** *Tier sets* (2pc/4pc seasonal rotational
bonuses) work because they're **rotational, not just stats** — a good 4pc changes *how* you play for a
season (make a proc more frequent, add a payoff to your dump), then rotates out so it never permanently
bloats. *Artifact weapons* (Legion) worked as a per-spec identity trait tree but failed as a **grind
treadmill** (Artifact Power was an endless bar). *Azerite* (BfA) failed — power buried in confusing
gear-piece rings, unfun to acquire. *Covenants* (Shadowlands) gave strong class-flavored abilities but
**hard-locked build to a cosmetic faction choice** — players resented "borrow power OR play the
aesthetic/story I want," and it was eventually unlocked. Lesson: **borrowed power is great when it's
free to swap and reshapes the loop; toxic when it's a treadmill or a locked either/or that fights
player expression.** Talent trees (Dragonflight) were the corrective — permanent, freely respec'd,
expressive.

**What makes the best buttons feel great.** (1) A **windup you control** — Empower (hold-to-level),
pooling before a window, stacking before a dump. (2) A **crescendo payoff** — a 5-CP Eviscerate, a
Hot-Streak Pyroblast, a Chaos Bolt. (3) **Reactivity** — a proc that makes you deviate. (4) **Legible
feedback** — screen shake, sound, a number that dwarfs your fillers. (5) **A decision, not just a
press** — "press on cooldown, always correct" is the anti-pattern WoW itself is moving away from.

**Cooldown design.** The historical trend went from many **1-min** cooldowns (frequent small pops) to
stacking everything into **2-min / 3-min** mega-windows (all buttons align → one giant burst, then a
long dull valley). Players/designers found that **spiky** — it made non-burst windows feel dead and
made group play a scripted "3-2-1 GO" every two minutes. Midnight's Apex-Talent direction consciously
**pulls back toward sustained uptime and shorter, more frequent moments** over theatrical burst.
Lesson for us: prefer a **~1-min signature that recurs and stays engaging** over a rare 3-min dump —
and make the CD *amplify skill expression*, never be "press = damage."

---

## 4. Difficulty & self-tuning systems

**Raid difficulties (4 tiers, same bosses, scaling mechanics/HP/rewards):** **LFR** (Looking For Raid
— trivial, matchmade, mechanics mostly ignorable), **Normal**, **Heroic**, **Mythic** (fixed 20-player,
the hardest — extra mechanics, tightest tuning, prestige). Same encounter, escalating punishment and
loot. Lets one fight serve everyone from tourist to world-first.

**Mythic+ (M+) — the endless self-tuning dungeon ladder.** A dungeon + a **Keystone** of level N;
higher N = **exponentially more enemy HP/damage** + more **affixes**, on a **timer** (beat it → your
key levels up; miss → it downgrades). This is the design masterstroke: **players choose their own
difficulty** by pushing keys as high as they can clear, and the content self-scales infinitely.
**Midnight's affix structure (cleaner than old rotating-3):**
- **+2 to +5:** *Lindormi's Guidance* — a guiding/routing affix that reduces wipe-stress on low keys.
- **+5 to +11:** *Xal'atath's Bargain* — one of several **weekly-rotating** boss-cast mechanics
  (Devour, Pulsar, Ascendant, Voidbound, Emissary): each is a mini-puzzle you can **turn to your
  advantage** if you handle it (e.g. kill the Void Emissary in time → the whole group gains cooldown
  rate + Versatility). Affixes as *opt-in upside* if you play well, not just tax.
- **+7 to +9:** *Fortified* **or** *Tyrannical* (alternating weekly) — trash-heavy vs boss-heavy tuning.
- **+10 and up:** **both** Fortified and Tyrannical simultaneously.
- **+12 and up:** *Xal'atath's Guile* — **each death subtracts 15 seconds** from the timer (deaths
  become the real enemy at the top).
The genius: affixes are a **modifier layer over fixed content** so the same 8 dungeons stay fresh all
season, and the **timer + key up/down** creates a personal difficulty dial with a ratchet. (Historical
**Challenge Modes** in MoP/WoD were the precursor — fixed-level timed dungeons for cosmetics; M+ made
the ladder infinite and gear-rewarding.)

---

## 5. Party / co-op interplay

**Raid buffs — the "bring the player, not the class" backbone.** Many classes bring a **unique
raid-wide buff or utility** so comps want variety: Warrior **Battle Shout** (attack power), Mage
**Arcane Intellect**, Priest **Power Word: Fortitude** (stamina), Monk **Mystic Touch** / Rogue etc.
provide **armor-reduction/physical-magic debuffs on the boss**, Hunter/Evoker/others bring **Bloodlust/
Heroism/Time Warp** (a raid-wide 30% haste burst, once per fight — the single most-wanted party
button). Historically these overlapped so no one class was mandatory; the philosophy is *every seat
adds something no other seat does*.

**Externals — defensive cooldowns cast ON another player.** Paladin **Blessing of Sacrifice/Protection**,
Priest **Pain Suppression / Guardian Spirit**, Demon Hunter **Darkness**, Warlock **healthstones/gateway**,
Rogue **Tricks of the Trade** (throw threat/damage to an ally). These make survival a **team resource
you spend on each other**, not just self-care — a healer/tank can save a DPS mid-mechanic.

**Interrupt rotations.** Bosses/trash cast dangerous spells with a cast bar; the group **assigns an
interrupt order** ("kicks") so someone always has a kick off cooldown — a coordinated, timing-critical
team job. (Directly relevant to Rift's interrupt-by-ability pillar: WoW's kick is a dedicated short-CD
button; the *rotation* is the social layer of who-kicks-when.)

**Damage-share / group-mitigation cooldowns.** Shaman **Spirit Link Totem** (redistributes party HP),
raid walls timed to boss burst — the healer/tank job is *scheduling* these against the telegraph.
**Support as a role (Augmentation, §2)** is the purest case: group value literally becomes the rotation
— but it warped meta (everyone wants an Aug), a caution about over-centralizing buffs.

---

## 6. STEAL CANDIDATES for Rift

Mapped to our grammar — BRANCH (Creed→Module→Boons→Keystone) · EASE dial · RIG (WHEN→THEN) · signature
CD · ABILITY LAW (≤7 buttons, every button needs a WHEN). *Borrow the grammar, innovate the sentence.*

1. **Enrage self-feeding loop → a Module gauge that self-sustains.** (Fury) A Module: your dump lights
   a buff that makes your *taps* generate more Flow, which fuels the next dump — a fire you must keep
   lit. Miss the refresh cadence and it drops. Turns "press on CD" into "sustain a state through the
   minigame" — pure timing, no new button. Fits ABILITY LAW (it's a gauge, not a 7th touch target).

2. **Breath-of-Sindragosa brinkmanship → a Keystone "channel" you feed.** (Frost DK / Devourer) A
   capstone that opens a drain-meter: while it's up you deal bonus damage every beat, but it eats Flow
   each beat and ends when Flow hits zero. The whole run of the minigame reorganizes around *how long
   can I keep it alive* — spectacle build-definer that amplifies skill, never button=damage.

3. **Apex Talent (amplify the ONE core ability) → Keystone law.** (Midnight) Codify that every branch
   Keystone must **super-charge the thing the spec already is** (the Flow dump, the Opening punish),
   not bolt on a tenth mechanic. Bill's "keystone amplifies skill" already agrees — this is Blizzard
   arriving at the same rule after a decade of burst-bloat. Use it as the acceptance bar for Keystones.

4. **Roll the Bones (RNG buff bundle) → a GREED Boon.** (Outlaw) A card that, on a triggered moment,
   rolls 1 of 4 temperament buffs for the next stretch (wider window / faster beat / +dump / free
   dodge). The *reworked* 4-unified version is the lesson: keep variance readable, not a 6-way slot
   machine. Greed over insurance — you gamble the roll for tempo.

5. **Eclipse two-state pendulum → a Module with two lit modes.** (Balance) A Module where your minigame
   alternates between two states (say STRIKE-lit vs BLEED-lit); which taps score best flips with the
   state, so you read the gauge instead of mashing. Depth with zero extra buttons — exactly our "every
   button needs a WHEN" ethos, applied to the gauge itself.

6. **Hot Streak proc chain → a RIG WHEN→THEN.** (Fire Mage) RIG: WHEN two Perfect taps land
   back-to-back → THEN the next dump is instant/empowered. Earned-moment trigger, reactive, makes the
   player *chase* consecutive Perfects — turns proc-watching into a timing skill.

7. **Fistweaving / Atonement (heal by attacking) → the healer's core loop.** (Mistweaver/Disc) The
   Well/Mender rework can steal this wholesale: some healing *comes from* landing offensive taps on the
   boss's telegraph, so the healer plays the same one-target timing minigame as everyone else and is
   never idle-watching bars. Collapses the heal/DPS split into one active loop.

8. **Augmentation buff-donation → a TEAM Boon / support Creed.** (Aug Evoker) A card that donates a
   slice of *your* Flow-power to the ally with the highest current output, and a Keystone that banks
   the warband's damage in a window and detonates it. Makes "buff the carry" a timing decision — co-op
   interplay as a rotation, at our exact 4-seat count. (Watch the meta-warp: keep it a Boon, not a role.)

9. **M+ affix-as-opt-in-upside → run-map node modifiers.** (Xal'atath's Bargain) Node mutators that are
   a *mini-puzzle with upside*: handle the telegraph well (kill the emissary in the window) → the whole
   warband gains a buff for the floor; ignore it → it taxes you. Affixes that reward skill, not just
   raise HP. Slots onto our seeded node maps + deterministic telegraphs cleanly.

10. **M+ key ratchet (self-chosen difficulty + up/down) → the Depth ladder's tuning.** (Mythic+) Our
    endless/Depth door already wants this: push the key as high as you clear, beat the timer → it
    ratchets up, miss → down. Player-set difficulty with a ratchet, self-scaling forever — pairs with
    our deterministic engine (a key = a seed + a scaling number).

11. **Death-timer affix → a stakes knob.** (Xal'atath's Guile, +12) At high stakes, each wipe/death
    subtracts from a run budget or clock — deaths become the real enemy, not enemy HP. Maps directly to
    our wipe-budget / attempt-token stakes model.

12. **Externals (defensive CD cast on an ally) → a TEAM RIG.** (Pain Suppression / Sacrifice) RIG:
    WHEN an ally's health crosses a threshold → THEN your dodge/dump also throws them a shield. Makes
    survival a team resource spent through *your* timing, not a separate babysit button.

13. **Bloodlust/Time Warp (one raid-wide haste burst) → a shared signature CD.** One warband member's
    ~1-min signature briefly speeds *everyone's* beat — a group tempo spike you schedule against the
    boss's Opening window. The most-wanted button in WoW becomes a co-op timing decision.

14. **Choice nodes (pick 1 of 2) → the EASE dial's DNA.** (talent trees) The either/or is the whole
    point — our EASE card (roll 2–3 knobs, slide COMFORT↔BITE) is a live, per-run choice node applied
    to the minigame's tuning. Reinforces: every meaningful pick should be an exclusion, not an add.

15. **Covenant/borrowed-power failure → a design guardrail.** (Shadowlands) Cautionary steal: never
    hard-lock a build to a cosmetic/story choice or an endless grind bar. Our Boons/Keystones are
    free-to-redraft per run *by design* — this is the lesson that validates it. Keep borrowed power
    freely swappable and loop-reshaping, never a treadmill or a locked either/or.

### Twinfang / rogue-flavored angles (our rhythm rogue: Flow 0–6, graded Bullseye/Perfect/Good taps, beat speeds up as Flow climbs, CP→Eviscerate, Coup de Grâce dump, boss Opening punish ×1.9, one spacebar dodge)

- **Combo-point-scaled finisher → we already are Rift's rogue.** Eviscerate = CP dump whose payoff
  scales with points spent; Coup de Grâce = the Subtlety "cram it into the window" dump. Keep leaning
  in: the deep fun is *pooling then cashing*, never overcapping. (Assn's chain-Envenom = keep a dump
  buff at 100% uptime — a Module: refresh the Flow-dump buff before it drops.)
- **Fatebound coin-flip (Fatebound Hero Talent) → a Creed temperament.** A Creed where every finisher
  flips a coin; matching flips stack a snowballing buff. Escalating-luck fantasy that lives entirely on
  our graded-tap outcomes — a Bullseye could weight the flip. Greed dial: chase the streak.
- **Subtlety 90-second burst window → the Opening, amplified by a Keystone.** Sub's whole spec orbits a
  recurring ~90s Shadow-Dance window. Our boss Opening (dumps hit ×1.9) IS that window from the boss's
  side; a Subtlety-flavored Keystone could let the player *pre-load* Flow so the next Opening detonates
  — setup → align → dump, our signature-CD grammar.
- **Outlaw proc-reactivity → the fast, jangly branch.** Sinister Strike's random double-strike →
  Opportunity is the "play the procs the game hands you" feel. A branch (Creed + Module) where
  Bullseyes randomly grant a free empowered tap mid-rhythm — reward attention, punish tunnel.
- **Restless Blades (finishers reduce cooldowns) → dumps that shorten your signature CD.** A RIG:
  WHEN a full-Flow dump lands during an Opening → THEN shave time off your signature CD. Ties the
  reward of nailing the punish window to getting your big moment back sooner — a self-accelerating rogue.
- **Symbols of Death pre-buff → a windup you control before the Opening.** A tap-pattern you play in the
  lull *before* the boss's Opening that buffs the coming dump — rewards reading the telegraph ahead,
  our "windup you control → crescendo payoff" feel-great recipe.

---

## 7. Sources

- Warcraft Wiki — Hero talent trees (all classes): https://warcraft.wiki.gg/wiki/Hero_talent
- Wowhead — Hero Talents overview: https://www.wowhead.com/guide/classes/hero-talents
- Wowhead — Apex Talents (Midnight) overview: https://www.wowhead.com/guide/midnight/apex-talents-overview
- Blizzard News — Apex Talents in Midnight: https://news.blizzard.com/en-us/article/24244472
- Wowhead — Devourer Demon Hunter (new Void spec): https://www.wowhead.com/guide/midnight/devourer-demon-hunter-overview-new-void-specialization
- Icy Veins — Assassination Rogue rotation (12.0.7): https://www.icy-veins.com/wow/assassination-rogue-pve-dps-rotation-cooldowns-abilities
- Icy Veins — Outlaw Rogue rotation (12.0.7): https://www.icy-veins.com/wow/outlaw-rogue-pve-dps-rotation-cooldowns-abilities
- Icy Veins — Subtlety Rogue rotation (12.0.7): https://www.icy-veins.com/wow/subtlety-rogue-pve-dps-rotation-cooldowns-abilities
- Wowhead — Assassination Rogue (Midnight) overview: https://www.wowhead.com/guide/classes/rogue/assassination/overview-pve-dps
- Icy Veins — Fury Warrior rotation (12.0.7): https://www.icy-veins.com/wow/fury-warrior-pve-dps-rotation-cooldowns-abilities
- Icy Veins — Augmentation Evoker buff targets: https://www.icy-veins.com/wow/augmentation-evoker-buffs
- Wowhead — Mythic+ Season 1 overview (Midnight): https://www.wowhead.com/guide/midnight/mythic-plus-season-1-overview
- Warcraft Wiki — Mythic+ affix: https://warcraft.wiki.gg/wiki/Mythic%2B_affix
- Icy Veins — Midnight 12.1 class change notes: https://www.icy-veins.com/wow/news/massive-class-changes-midnight-12-1-curse-of-ulatek-development-notes/
