# Slay the Spire 1 + 2 — card-pool archetype design, relics, Ascension

*Researched 2026-07-09 (model knowledge + wiki/dev sources, cited at end). StS2 is in Steam Early
Access (launched 2026-03-05) — its roster and mechanics are live-moving; verify numbers before
leaning on them. StS1 is the finished, canonical reference.*

Idea quarry, not a spec. Everything here must pass **"borrow the grammar, innovate the sentence"** —
a stolen system has to do something only our timing-combat / deterministic engine could.

---

## 1. Build grammar

A StS run is **one character = one fixed card pool** (its "color") that you draft a ~25-40 card deck
out of, plus **relics** (permanent passives, no card slot) and **potions** (single-use consumables).
Three loops interlock: (a) the **deck** — every combat you're offered 1-of-3 cards; the skill is
*declining* rewards to keep the deck lean, because your whole deck shuffles each combat and bloat
dilutes your engine; (b) **relics** — always-on rule-benders that define which archetype the deck
can chase; (c) the **map** — a branching node tree (fight / elite / event / shop / campfire / rest)
you route through, trading HP and gold for power. Bosses gate each of 3 acts; the meta-goal is a
deck that *scales* faster than the enemies do. The core tension is **thin-deck consistency vs.
add-the-payoff greed**, resolved every single reward screen.

**What StS2 changed:** the single-upgrade-per-card rule is replaced/augmented by **Enchantments** —
stackable, permanent per-card modifiers (add a keyword, cut cost, amplify an effect) applied at
campfires and events, so a single card can carry several. Relics gained a **Durability** layer (some
burn out mid-combat after N activations, then recharge) and can be **permanently empowered at
campfires**, making relics a spendable upgrade track rather than static passives. Enemies now **react
to your board** (e.g. stack enough Block and an attacker may flip its intent to Buff/Debuff). And
StS2 shipped **1-4 player co-op** (see §5). Net effect: more *permanent in-run customization* and
more *dynamic enemy behavior* than StS1's cleaner but more static systems.

---

## 2. Character roster

Each character is a self-contained pool that **seeds 3-4 archetypes simultaneously** (see §3). Fantasy
· core resource · signature moment:

**StS1 — the four finished classes**

- **Ironclad** (80 HP, *Burning Blood*: heal 6 after each combat). Fantasy: the durable berserker.
  Resource: **Strength** (permanent +damage per Attack) and **Exhaust** (cards leave the deck for the
  combat — fuel, not waste). Three seeded builds: Strength-scaling (Demon Form +2 Str/turn, Limit
  Break doubles Str), Exhaust-engine (Corruption makes all Skills cost 0 and Exhaust; Feel No Pain /
  Dark Embrace pay you for exhausting), and Block/Body-Slam (Barricade = Block never expires → Body
  Slam deals damage = your Block). Signature moment: **Barricade + Entrench** turtles to 999 Block,
  then Body Slam one-shots. Or **Demon Form** turn 3 and every Strike becomes lethal.

- **Silent — GO DEEP (our rhythm-rogue analog).** (70 HP, lowest; *Ring of the Snake*: draw 2 extra
  cards turn 1). Fantasy: the glass-cannon assassin who wins on card *velocity* and stacked debuffs,
  never on a big single button. Three pillars, each a distinct win condition:
  - **Poison** — a stacking debuff dealing its value each turn *then* decrementing. Enablers: Deadly
    Poison, Noxious Fumes (apply poison every turn passively), Bouncing Flask. Payoffs: **Catalyst**
    (double all poison on a target — the finisher), **Corpse Explosion** (on death, poison chains to
    all enemies). It's a *ramp/patience* build: seed poison early, Catalyst late, watch it tick.
  - **Shivs + Discard** — Shivs are 0-cost 4-damage attacks generated in bulk (Blade Dance, Cloak &
    Dagger). Payoffs turn *count of cheap plays* into scaling: **Accuracy** (+3 damage per Shiv),
    **A Thousand Cuts** (deal 1 to ALL enemies per card played), **After Image** (gain Block per card
    played). Discard synergy: Tactician / Reflex reward *discarding* a card (energy / draw), so you
    thin and sculpt your hand actively.
  - **Thin-deck / draw engine** — the Silent draws harder than anyone; the skill is pruning to a
    ~15-card deck that draws itself, plus **Wraith Form** (Intangible: take 1 damage from any hit) as
    a panic button that costs ramping Dexterity. Signature moment: a full **discard-Shiv turn** where
    one Blade Dance snowballs into a whole hand of free knives + Thousand Cuts wiping the board.
  - *Why it maps to us:* poison=ramp-then-detonate, shivs=many small graded taps that scale by COUNT,
    discard=active hand-sculpting under time pressure. All three are timing/velocity fantasies, not
    "press big button." Our Flow meter (0-6 on graded taps) + combo-points→Eviscerate is the Silent's
    "small hits accumulate into a finisher" grammar rebuilt as a rhythm minigame.

- **Defect** (75 HP; *Cracked Core*: start with a Lightning orb). Fantasy: the summoner-battery.
  Resource: **Orbs** in a limited slot row — Lightning (damage at end of turn), Frost (Block),
  Dark (ramps then bursts on Evoke), Plasma (energy) — plus **Focus** (+power to every orb). You
  **Channel** orbs in and **Evoke** the leftmost for a payoff. Seeded builds: Frost/Focus tank,
  Lightning aggro, Dark-evoke burst, and 0-cost Claw spam. Signature: **Echo Form** (first card each
  turn plays twice) + **Electrodynamics** turning every Lightning orb into board-wide chain damage.

- **Watcher — GO DEEP (stance-dance = our branch-switching question).** (72 HP; *Pure Water*: add a
  Miracle card). Fantasy: the martial-artist who flips between **Stances** for enormous swings.
  Resource: **Stances** — *Calm* (exit → +2 energy), *Wrath* (deal AND take **double** damage), and
  *Divinity* (deal **triple** damage for one turn, entered by hitting 10 **Mantra**). Plus **Scry**
  (look at / discard top cards) and **Retain** (keep cards across turns). The whole class is a
  high-wire act: Wrath doubles your output but you *die* if you eat a hit while in it, so the skill is
  entering Wrath, doing your damage, and **exiting to Calm before the enemy turn** — every turn is a
  timing puzzle of when to flip. Seeded builds: Stance-dance infinites (Rushdown draws on entering
  Wrath; Mental Fortress / Talk to the Hand generate Block/thorns per stance change → literal infinite
  loops), Mantra→Divinity (Blasphemy = Divinity next turn but you die if you don't exit), and
  Pressure-Points/Mark (a debuff that deals its stacked value on command, ignoring Block). Signature:
  a **Wrath→attack→Calm** dance that triples a turn's damage while eating zero, or a **Blasphemy +
  Vault** all-in that ends a boss in one Divinity turn. *Why it maps to us:* the Watcher is
  literally a **risk-stance you toggle in real time under threat** — the exact fantasy of our Creed
  temperaments and the EDGE/Fermata "bull at the lip" ramp-vs-snap. Wrath's "double out, die if hit"
  is a pure timing-window bet.

**StS2 — Early Access (5 launch characters; ≥1 more + 3 game modes confirmed coming)**

- **Ironclad, Silent, Defect** return, reworked but keeping their identities (Ironclad 80 HP /
  Burning Blood; Silent 70 HP / Ring of the Snake with a new keyword — see below; Defect orbs).
  Watcher is **not** in the EA roster.
- **The Regent** (new). Fantasy: the regal spellcaster who hoards power for a huge play. Resource:
  **Stars** — a currency that *accumulates over the combat and does NOT drain between turns*, spent
  (alongside energy) to fire the strongest cards. So it's a **stockpile-then-unload** rhythm: play
  cheap, bank Stars, then a Star-fueled bomb turn. (Contrast the Silent's spend-every-turn velocity.)
- **The Necrobinder** (new). Fantasy: the summoner who fights behind a companion. **Osty** is
  auto-summoned at combat start with **1 HP** and *intercepts attacks aimed at you* (a living body-
  block); Summon effects grow Osty's HP. Second mechanic: **Doom** — stack Doom on an enemy, and when
  its HP drops to/below the Doom threshold it **dies instantly** (a burst-execute you set up in
  advance). Signature: feed Osty huge, hide behind it, and detonate Doom for a guaranteed kill.

---

## 3. Card / upgrade design patterns

- **One pool seeds several archetypes at once.** The Ironclad pool contains Strength cards, Exhaust
  cards, and Block cards side by side; a run *commits* to one based on which build-arounds and relics
  you're offered. This is the whole magic: the pool is coherent (all "berserker" flavor) but supports
  3-4 different engines, so two Ironclad runs feel unrelated. **Directly = our BRANCHES**: one spec,
  2-3 sub-specs the draft leans you into, not a menu you pick up front.
- **Rarity = role, not just power.** *Commons are the bread* — cheap, reliable stat cards (Strike/
  Defend upgrades, small Block, small poison) that every deck runs and that keep you alive while the
  engine assembles. *Uncommons* are the engine pieces and most Powers (the build-arounds). *Rares*
  are **win conditions / payoffs** — Demon Form, Barricade, Corruption, Echo Form, Catalyst — high-
  impact cards a build is *about*. The lesson: a good pool has few rares but they're build-*definers*,
  and the commons carry the whole run. Maps onto our **Boons = bread that each address one dial**,
  **Keystone = the one rare build-definer (1/run from elites)**.
- **Build-around vs. payoff vs. enabler.** Three card jobs: *enablers* generate the resource cheaply
  (Blade Dance makes Shivs, Deadly Poison seeds poison), *payoffs* convert the resource to a spike
  (Accuracy, Catalyst, A Thousand Cuts), *build-arounds* are the Powers that change a rule so the
  whole deck reorients (Corruption, Barricade, Noxious Fumes). A build needs all three; drafts are
  about completing the triangle. **We already have this**: Creed (temperament) → Module (gauge) →
  Boons (enablers/payoffs) → Keystone (rule-flip build-around).
- **Keywords as glue.** Exhaust, Retain, Ethereal, Innate, Intangible, Scry — a small vocabulary of
  reusable verbs that let cards synergize legibly ("everything that Exhausts triggers Feel No Pain").
  The player learns the keyword once and reads combos instantly. **Steal the discipline, not the
  words**: our RIG (WHEN→THEN) is exactly a keyword-glue system — a tight set of earned-moment
  triggers that any card can hang an effect on.
- **Energy economy is the tempo clock.** 3 energy/turn base; most build-arounds are Powers you can
  only afford to seat over 1-2 turns; **0-cost cards** are the infinite-combo currency. Boss relics
  that hand +1 energy are the single biggest power spike in the game — because tempo, not raw numbers,
  is the bottleneck. (Our analog: the **signature CD** as the ~1-min tempo beat you build toward.)
- **Curses & Status cards = designed friction, not just bad luck.** Curses (Injury, Normality,
  Decay, Writhe, Pain) and Statuses (Wound, Dazed, Burn, Slimed, Void) are *unplayable/harmful cards
  shoved into your deck* by events, elites, and deal-with-the-devil choices. They dilute your draw
  (the thin-deck tax made literal) and some punish you actively (Burn deals damage if held, Normality
  caps cards/turn). They're the *cost side* of greed decisions and a knob the difficulty ladder turns
  (Ascension 10 = start every run cursed). Great **anti-insurance** design: the game makes you *pay in
  consistency* for power.
- **Relics — the deal-with-the-devil grammar.** Relic tiers: Common/Uncommon/Rare (found), **Boss**
  (chosen after each act boss), Shop, Event. **Boss relics are the signature design move**: nearly
  every one is *huge upside + a permanent rule you now live with* — Runic Dome (+1 energy, but you can
  no longer see enemy intents), Snecko Eye (+2 card draw, but all card costs are randomized 0-3),
  Philosopher's Stone (+1 energy, but every enemy starts with +1 Strength), Coffee Dripper (+1 energy,
  but you can never Rest), Sozu (+1 energy, but you can't use Potions), Velvet Choker (+1 card play/
  turn, but hard-capped at 6 cards played/turn). Each one *rewrites how you play the rest of the run*.
  **This is the richest steal in the file** (see §6).
- **StS2 additions.** New keywords: **Momentum** (a card's Attack damage grows by X *each time you
  play it this combat* — per-card scaling), **Echo** (the doubling family, e.g. Echo Form's "first
  card each turn plays twice"), and the Silent's new **Sly** (a card *auto-plays for free when
  discarded* — so a single discard can chain-trigger a whole run of free plays, a new velocity engine
  layered on the old discard theme). Per-character resources: **Stars** (Regent, bankable), **Doom +
  Osty** (Necrobinder). **Enchantments** replace the single-upgrade cap with stackable permanent card
  mods (the socket system — you can now over-tune one key card). **Relic Durability** (burn-out /
  recharge) and **campfire relic empowerment** turn relics into a second upgrade economy.

---

## 4. Difficulty & self-tuning — Ascension 1-20

The gold standard for **legible, one-knob-per-rung self-tuning.** You unlock the next rung by *beating*
the current one; each level adds **exactly one cumulative rule tweak**, so difficulty is a stack of
readable modifiers, not an opaque slider. The ladder is deliberately grouped:

- **A1-A4 — enemies hit harder** (A1 ~60% more Elites on the map; A2 normal enemies deal more; A3
  Elites deal more; A4 Bosses deal more).
- **A5-A6 — economy tightens** (A5 heal only 75% of missing HP after a boss, was 100%; A6 start each
  run already damaged, -10% HP).
- **A7-A9 — enemies have more HP** (normal / elite / boss toughness).
- **A10-A12 — your resources shrink** (A10 start every run with a Curse in the deck; A11 one fewer
  potion slot; A12 upgraded cards appear ~half as often in rewards).
- **A13-A16 — the economy squeezes harder** (A13 bosses drop less gold; A14 lower max HP; A15 events
  roll worse outcomes; A16 shops cost +10%).
- **A17-A19 — enemies get *smarter*** (normal / elite / boss movesets gain new, nastier abilities —
  the only rungs that change *behavior*, not numbers).
- **A20 — Double Boss** (after the visible Act-3 boss, you immediately fight a *second* Act-3 boss).

Design lessons: (1) each rung is *one* sentence a player can hold in their head; (2) the ladder
escalates along *different axes* (damage → healing → HP → your deck → economy → AI → structure) so it
never feels like just "+X%"; (3) A17-19 (smarter movesets) are the most beloved because they change
*decisions*, not just math — **the "harder should mean different, not bigger" principle.** On top of
Ascension, StS has a **Custom / Daily mode** with toggleable modifiers (seed sharing, positive AND
negative mutators) for self-directed challenge. StS2 keeps an Ascension ladder (being tuned in EA).

---

## 5. Party / co-op interplay

**StS1 has none** — a strictly solo game. **StS2 added 1-4 player co-op**, but the design is
instructive precisely because it's *thin*: each player keeps their **own separate deck, relics, gold,
and energy pool**, drafts their **own** card rewards, and takes their **own** turn against a **shared**
enemy that scales (~1.5-1.8× HP for two, near-double boss HP) and **targets everyone**. Cross-player
interaction is limited to: potions usable on an ally, giving your campfire heal to an ally, and a
small set of cards that affect "allies." So it's **two-to-four parallel solo games sharing a map and
an enemy** — the decks don't *interlock*; there's no aggro, no role division, no combo that spans two
players' hands. **This is the exact gap our 4-seat warband exploits:** our seats share ONE boss/
telegraph stream in *real time*, so seat A's parry can open a window seat B's dump detonates, tanks
own aggro the whole party plays around, and drafts can be *cross-seat* (a Boon on one seat that pays
another). StS proves the deck-draft/archetype grammar is beloved; it has *never* married that grammar
to genuine 4-player timing interplay. That marriage is our whole thesis.

---

## 6. STEAL CANDIDATES for Rift

Filter applied — each must exploit our timing-minigame / deterministic / 4-seat engine, not repack a
turn-based card system.

1. **Boss-relic = deal-with-the-devil Keystone.** StS boss relics = huge power + a permanent rule you
   now live with. Make some **Keystones cost a live rule**: e.g. "+X on dumps, but your dodge window
   is permanently tighter" or "double Flow gain, but Flow *decays* between beats." The devil's-bargain
   is *timing-shaped*, so the cost is a skill tax our engine can express — impossible in a game
   without a timing layer. (StS: Runic Dome / Snecko Eye.)
2. **Snecko Eye as an EASE card.** Snecko randomizes card costs for +2 draw — chaos for power. An
   **EASE=BITE roll** that *randomizes* one of your minigame's beat timings each cycle in exchange for
   +damage: the player who can read an unpredictable beat gets paid. COMFORT side locks the beat.
3. **Barricade / Body Slam as a RIG.** "Block never expires → deal damage = your Block" is a stored-
   resource-becomes-a-hit. RIG: **WHEN** you hold a perfect-parry chain without spending → **THEN**
   your next dump converts stored charge into bonus damage. Turns *defensive patience* into offense —
   only meaningful because our defense is an active timing act.
4. **Catalyst (double the ramp) as a finisher window.** The Silent seeds poison for turns, then
   Catalyst *doubles the whole stack* at the perfect moment. Rogue Keystone: build a ramping
   bleed/mark over several beats, and the **Coup de Grâce dump doubles the accumulated stack** if hit
   inside a boss "Opening" window. Patience → one detonation, gated on a timing read.
5. **Sly (auto-play on discard) → chain-dodge payoff.** StS2's Sly fires cards *for free when
   discarded*. Ours: a Module where a **whiffed-but-recovered input** (the thing you'd normally
   "discard") instead *auto-fires a small free strike* — turning a near-miss into a chain, rewarding
   flow-state recovery instead of punishing it. Pure timing-engine idea.
6. **Momentum (per-card ramp) → per-ability heat.** A card that grows each time you play it this
   combat = our **per-ability heat**: an ability that gets stronger each time you hit its window
   *cleanly* this fight, resetting on a miss. Rewards *consistency on one move*, not spam.
7. **Enchantment sockets → dial-tuning a signature.** StS2 lets you stack permanent mods on one key
   card. Let the player **over-tune their signature CD** across a run: each socket slides one minigame
   knob (wider window / +damage / faster charge), so a run *sculpts its own signature* — the EASE dial
   made persistent and per-move.
8. **Relic Durability → charged-not-passive Boons.** StS2 relics burn out after N combat activations
   then recharge. Convert "always-on" Boons into **charge Boons that spend and recharge on a timing
   beat** — you *earn* the proc by hitting windows, so power is paced by play, not by owning the card.
9. **Curses as deck-friction → telegraph friction.** StS shoves unplayable cards into your deck as the
   cost of greed. Ours (no deck to dilute): a greed pick that **injects an extra un-telegraphed beat**
   into the boss stream you now must answer — the friction lives in the *timing stream*, our version
   of deck bloat. Deterministic, so it's fair and learnable.
10. **Ascension "smarter movesets" (A17-19) → our depth ladder.** The best-loved rungs make enemies
    *behave* differently, not just bigger. Our M+/Depth ladder should add **new telegraph beats and
    faster strings**, not HP — "harder = new decisions." One rung = one new authored beat in a boss's
    stream. Directly maps to our difficulty philosophy.
11. **Watcher Wrath (double out / die if hit) → a Creed temperament.** A run-long Creed: **all your
    output is amplified, but a single missed answer costs double.** The Watcher's "flip to Wrath, do
    your damage, flip out before the enemy turn" *is* a real-time stance bet — perfect for a Creed the
    player toggles with a WHEN.
12. **Stockpile-then-unload (Regent Stars) → a bankable second resource.** A gauge that *does not
    decay*, filled by clean beats, spent on one big signature turn. A patience/greed alternative to our
    spend-every-beat Flow — a second Module temperament for a "hoarder" sub-spec.
13. **Thin-deck consistency vs. add-the-payoff greed → the draft's core tension.** StS's central
    decision is *declining* rewards. Our draft should sometimes offer a **"skip for a permanent buff"**
    — decline a Boon to tighten your kit / widen a window. Makes *not taking* power a real choice, the
    single most-praised StS design pillar.
14. **Colorless / cross-class cards → cross-seat Boons.** StS colorless cards fit any deck. Ours: a
    rare draft slot of **warband Boons that a teammate's actions power** ("when the tank parries, your
    next dump gets the Opening bonus") — the interplay StS co-op *never* built, native to our shared
    telegraph stream.

### Twinfang / rogue-flavored steals (Silent + Watcher are our closest kin)

- **Poison-ramp → Coup-ramp (the Silent's patience win).** Model a rogue sub-spec on *Noxious Fumes*:
  a passive that **auto-seeds a bleed/mark every beat** with no input, so the player spends attention
  on *positioning the Catalyst* (the doubling finisher) rather than re-applying. Ramp-then-detonate as
  a branch, opposite the burst branch. (Silent poison + Catalyst.)
- **Shiv velocity → Flow-count payoffs.** The Silent's Accuracy / A Thousand Cuts / After Image all
  pay off the *count of cheap plays*. Our combo-points→Eviscerate is already this; add Boons that read
  **Flow height at the moment of the dump** (bigger Flow = more Eviscerate targets / lifesteal /
  Block), so *how high you drove the meter* — not just that you dumped — is the reward. (Silent Shiv
  scaling.)
- **Discard sculpting → active hand under time pressure.** Tactician/Reflex reward *ditching* a card.
  Rogue Module: a **"reset a soured beat"** input — actively discard a bad window to redraw the rhythm
  cleaner, at a Flow cost. Turns the panic moment into a skill expression. (Silent discard.)
- **Wrath stance → the Opening as a self-imposed window.** Instead of only the boss's Opening giving
  ×1.9, let a rogue Creed **self-enter a "Wrath" for 2 beats: all output amplified, but any missed
  answer in it costs double.** The player *chooses* the risk window instead of waiting for the boss's
  — the Watcher's core bet, rhythm-ized. (Watcher Wrath.)
- **Blasphemy (all-in or die) → a Keystone dump.** Blasphemy = Divinity next turn but you die if you
  don't exit. Rogue Keystone: a **Coup de Grâce that hits ×3 but locks your dodge for its wind-up** —
  commit to the kill and you're defenseless until it lands. Pure spectacle, pure timing bet, 1/run.
  (Watcher Blasphemy + Vault.)
- **Wraith Form Intangible → a costed panic beat.** Intangible (all hits → 1 damage) costs ramping
  Dexterity. Rogue signature: a **1-min "phase" that trivializes one telegraph string but shrinks your
  Flow ceiling for a while after** — a bail-out that a greedy player refuses. Amplifies skill (you
  choose *when* the string is unanswerable), never button=damage. (Silent Wraith Form.)

---

## 7. Sources

- Slay the Spire 2 — Mechanics / Keywords wiki: https://slaythespire.wiki.gg/wiki/Slay_the_Spire_2:Mechanics · https://slaythespire.wiki.gg/wiki/Slay_the_Spire_2:Keywords
- StS2 roster + upcoming characters/modes (Casey Yano roadmap): https://sts2front.com/updates/upcoming-characters-and-modes/ · https://kotaku.com/slay-the-spire-2-new-modes-characters-2000684316
- StS2 new mechanics (Enchantments, Durability, Stars, Doom, Sly, dynamic intents): https://www.xmodhub.com/info/blog/slay-the-spire-2-new-mechanics-guide/ · https://pixelnitro.com/slay-the-spire-2-relics-spreadsheet-guide-to-all-items-new-mechanics-and-beta-meta-2026/ · https://sts2guide.com/mechanics
- StS2 keyword detail (Momentum enchantment, Echo Form): https://www.sts2companion.com/enchantments/momentum · https://slaythespire.wiki.gg/wiki/Slay_the_Spire_2:Echo_Form
- StS2 co-op design: https://www.pcgamer.com/games/roguelike/slay-the-spire-2-multiplayer-co-op/ · https://mobalytics.gg/slay-the-spire-2/guides/co-op-multiplayer · https://www.thegamer.com/slay-the-spire-2-multiplayer-coop-mode-explained-guide/ · https://www.stratgg.com/guides/co-op/
- StS2 characters overview: https://mobalytics.gg/slay-the-spire-2/characters · https://games.gg/slay-the-spire-2/guides/slay-the-spire-2-every-character-and-how-to-unlock-them/
- StS1 Ascension 1-20 ladder: https://slaythespire.wiki.gg/wiki/Ascension · https://slay-the-spire.fandom.com/wiki/Ascension
- StS1 character/keyword/relic design (model knowledge, cross-checked): https://slay-the-spire.fandom.com/wiki/
