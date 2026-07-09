# TANK-PLAN — the tank seat's class onto Framework v2 (two kits: THE DUELIST / THE WARDEN)

**Status:** 🟡 **DESIGN — base minigame being sharpened (2026-07-09); Duelist deck v1 AT BILL'S VERDICT.**
Latest locks: the two specs matched to 2 buttons (§1b) · **FLOW = the AGGRO meter, universal, progressive
peel (§1c)** · consequences flagged (§1d). The round-5 minigame (tester v5) is the base; the Duelist deck
is on the verdict board:
https://claude.ai/code/artifact/cf273dd1-4169-45e2-b990-47000941d417 — interactive KEEP/TWEAK/CUT,
export blob comes back here. **Nothing is built yet.** Old Bulwark = frozen placeholder, NOT the base.
The Warden's deck is a LATER pass (after the Duelist proves the frame).
**Names open (on the board):** the class (VANGUARD / AEGIS / STALWART / IRONCLAD / Bill's own) and
the fatigue resource (WIND leads — the tester already yells WINDED; BREATH / LEGS / POISE alternates).

**Dodge-unify reconciled (2026-07-08) — design + deck UNCHANGED.** The dodge-unify (one SPACE dodge,
F retired) was scoped to Twinfang/Alchemist/Well and does NOT touch the tank. Nothing on the board
changes. Two rules it makes explicit (§1a): the two kits are the **dodge tank** and the **shield tank**;
the tank runs its OWN dense defensive stream and **skips the universal dodge** every other seat gets —
so parry cleanly reclaims the now-free F, and no card is affected. (Plain words — "move"/"answer",
not "verb" — jargon dropped per the deck-creator pass.)

## §1 · THE LOCKED CORE (round 5 — full history in MASTER-PLAN §CLASSES 2026-07-07)

Classic rhythm defense on the HUD's own timing UI: ONE stream of incoming hits drawn as
**vertical bars, height = power** (skinny lines; the only fat bar is the Warden's HOLD).
- **PARTIAL MITIGATION LAW** — even a perfect leaks a sliver (mit cap ~0.90). **No self-heal, ever.**
- **THE HEALER DUET = the scoreboard** — your HP bleeds, a sim healer refills; too little bleed =
  healer idle, too much = you fall.
- **COMBO ◆** = the build-and-spend resource. **FATIGUE** (wind) = the leash.
- Feints (hollow — READ if ignored, BAITED if answered) · consistent stream, no phases ·
  per-boss authored streams (encounter data, Warband Law).
**⚖ THE SPECS MATCH (2026-07-09): each has exactly 2 answer buttons — a MAIN + a SECONDARY — read the
same way; only the flavor differs.** SECONDARY answers small (any rating) / normal (good+), **never
tall**, and **never hits back** (even a perfect leaves a sliver — the healer's never bored). MAIN answers
**any** size incl. tall, and a **PERFECT MAIN hits back** (counter + banks ◆). No third button. *(Which
button is "main" for the dodge tank — PARRY — is Bill's "block for small/med, shield for big" pattern
applied to "dodge for small/med, parry for big"; flip the labels if read backwards.)*
- **THE DUELIST — the dodge tank** (dense/twitch, def+off). **DODGE (secondary) + PARRY (main).** DODGE
  is the bread — a % mitigation that scales with timing, small/normal only, can't take a big one. PARRY
  is the main — tiny ~60ms window, big fatigue cost land-or-miss, answers any size, perfect = hit back.
  A *flurry* = a burst of fast skinny bars → **WEAVE** it (rapid dodges, **all or eat it all**; a clean
  weave opens a free RIPOSTE). **Eats UNAVOIDABLE** bars (the bleed). Skinny bars only. **◆ → ⚡ DUMP =
  damage.** **LOW HP, bar swings FAST** — a build for a quick healer. Fatigue = a **small pool, fast
  recharge** (the "ninja"), a **bubble**; DODGE recovers fast if you time the re-press (fumble → penalty),
  PARRY recovers slow even on a land.
- **THE WARDEN — the shield tank** (heavy/endurance, def-only + off-cd). **BLOCK (secondary) + SHIELD
  (main).** BLOCK is the light tap — small/normal % mitigation. SHIELD is the main — answers any size
  incl. big, is **HELD** across the fat HOLD/flurry bars, and a **PERFECT SHIELD hits back** (= **SHIELD
  SLAM**, the parry-twin). **No dodge** (dropped 2026-07-09). Blocks **everything** — no unavoidables
  (PIERCE = affix knob); bleeds via the partial-mit sliver + hold-drain. **◆ → ⚡ DUMP = damage**,
  off-rhythm. **MORE HP, takes bigger % chunks** — steadier bar. Fatigue = a **big pool, slow recharge**,
  a **bar** (his real leash — over-hold and you're winded). Stream slower + heavier vs the Duelist's
  density. The old hold-blocks-all-free = a module, not base.

### §1a · THE TANK SKIPS THE UNIVERSAL DODGE (post dodge-unify, 2026-07-08)
The tank's bar-stream **IS** the boss's telegraph stream to this seat — dense by design (pillar #2,
"the densest footwork"). So the tank does **NOT** run the separate universal dodge RATION the other
seats get (~3–8 sparse beats bolted onto their kit, `combat_core.gd:104` "every class has it, separate
from the class"). The tank's minigame already **is** its dodge/defense — one stream, not dodging on top
of dodging.
- **Dodge tank** answers each bar with **DODGE (secondary)** or **PARRY (main)**. Parry reclaims the
  now-free F (the universal F-dodge was retired in dodge-unify).
- **Shield tank** answers with **BLOCK (secondary) / SHIELD (main)**. It has **no dodge** and needs none.
- Both **replace** the universal dodge; they never stack on it.
- The Duelist's DODGE stays its OWN graded, height-law dodge **leashed by WIND** (≈1/step), NOT the flat
  universal 0.35s/1.3s cd — the wind pool is the anti-spam, so wind (not a global cooldown) is what
  limits chaining a barrage; keep fast recovery. The tank **never** opts into `ClassKit.unified_dodge()`
  (that hook merges two INPUTS for the three non-tank kits; the tank already runs bespoke parry + dodge).

### §1b · BASE-MINIGAME REFINEMENTS (2026-07-09, Bill) — the two specs, matched
The specs were blurring together; this pins what's DIFFERENT while making the two READ the same. **2
buttons each (MAIN + SECONDARY), no third**, on one rating rule:

| Bar | Dodge tank (2nd DODGE · main PARRY) | Shield tank (2nd BLOCK · main SHIELD) |
|---|---|---|
| small | either button, **any rating** | either button, **any rating** |
| normal | **MAIN any** rating · SECONDARY needs **good+** | **MAIN any** · SECONDARY needs **good+** |
| tall / big | **MAIN only** (PARRY) | **MAIN only** (SHIELD) |
| **flurry** | **WEAVE** — rapid DODGE, **all or eat it all** → clean weave = free RIPOSTE | **HOLD** the SHIELD through it |
| unavoidable | **EAT it** (the bleed) | **SHIELD it** (no unavoidables) |
| feint | READ — don't press | READ — don't waste a press |

- **PERFECT MAIN hits back** (PARRY / SHIELD-SLAM) = counter + banks ◆. The SECONDARY never hits back and
  **even a perfect leaves a sliver** (partial-mit law — the healer always has work).
- **SECONDARY = the bread** you spam through the dense small/normal stream; **MAIN = the commit** for the
  big ones + the hit-back.

**The two specs are leashed DIFFERENTLY (this is the feel-split):**
- **Dodge tank — twitch/recovery leash + LOW HP.** DODGE recovers fast **if you time the re-press**
  (chain the rhythm); fumble → a bigger recovery penalty. PARRY recovers slow even on a land. Fatigue = a
  **small pool, fast recharge** (a **bubble**). HP is **low and swings fast** → a build for a *quick* healer.
- **Shield tank — endurance-pool leash + HIGH HP.** BLOCK/SHIELD recover fine; his real leash is a **big
  pool that recharges slow** (a **bar**) that HOLDING drains fast — over-commit and you're winded. HP is
  **high, taken in bigger % chunks** → a steadier bar for a steadier healer.

**◆ = damage · CD = defense:** both specs spend **◆ → DUMP = pure damage** (tanks are defense-rich /
damage-poor — no defensive ◆-spend; 🛡 GUARD dropped). The mitigation GUARD used to give moves to the
class's **~1-min defensive signature CD** — the `DECK-LAYOUT.md §5` slot every class owes, role-shaped for
the tank as **a wall** (amplifies skill by lining it up with a boss window, never `button = damage`).
Owed, not yet designed. **⚠ Card fallout:** the guard cards (Return to Sender, Cheap Iron) + the Wall rig
re-home to the Warden; SPEND lane is now DUMP-only. Deferred per Bill (branches after the minigame) —
flagged in `CARD-CATALOG.md`.

**FLOW = the AGGRO meter, BASE — see §1c (2026-07-09, Bill).** Supersedes the earlier "flow = a module":
the clean-answer streak is now **base on every tank** and IS the boss's-attention/threat meter. The **FLOW
module** is repurposed as the *upgrade* — "your flow ALSO ramps your DUMP damage" (the aggro-hold becomes a
damage engine). Keep the *slow-mo* flavor to the Ghost keystone (Borrowed Time) so it doesn't double up.

### §1c · THE AGGRO SYSTEM — FLOW is the boss's attention (2026-07-09, Bill) — **UNIVERSAL**
**The reframe:** the tank's clean-answer streak, **FLOW**, IS the aggro/threat meter. Play clean → you
hold the boss's attention; slip → it drifts to the warband. Aggro stops being a damage-threat rotation
(the old "babysit" model Bill parked to raid-land) and becomes a **skill readout on the minigame you
already play**. Lore skin (the takeover): high flow = you hold the boss's *context*; a slip = it *compacts
you out* and wanders (reuses the existing THREAT_DROP = "context-window shift" flavor, MASTER-PLAN §255).

- **FLOW is BASE, not a module** (supersedes the same-day "flow = module" call): every tank always has the
  flow/aggro meter. The **FLOW module** becomes the *upgrade* — flow ALSO ramps your DUMP damage.
- **Universal — one rule everywhere (REVISES the "aggro = raid-only" lock `b2afbca`):** aggro works
  identically in overworld / dungeon / raid — **one habit, learned once**. Only the *ambient numbers*
  (boss damage/HP, via the Depth spine) scale by content — **never how aggro works**. A peel in the open
  world just hurts less; you never relearn it. The full coordination *expression* (tank-swaps, hot-potato
  curses) blooms at raid intensity because the numbers are brutal there, not because the rule changed.
- **The progressive peel (Bill's model):** aggro is a **%** (the tank's normalized flow). **≥ 30%** → the
  boss is locked on the top-threat seat (the tank). **< 30%** → each incoming attack has an **X% chance to
  peel** to another seat, **X rising as aggro falls**. **0%** → fully **random** targeting. A **TAUNT** is
  the hard override (grab it back a few seconds; everyone-has-a-taunt = a DPS can clutch-grab it, hot-potato
  curses force swaps).
- **Reuses the built threat engine wholesale** — `BossState.threat` (by seat index), `taunt_seat_i`,
  `_threat_target()`, `THREAT_DROP`, the victim gold-frame + aggro-lost banner. We only **change the tank's
  threat SOURCE from damage → flow**; non-tanks keep low passive threat (damage/heals).
- **No tank? it just degrades (Bill's "crazy stuff" for free):** aggro is universal, but **only the tank
  DRIVES it high** (via the flow minigame). Remove the tank → nobody drives it → aggro sits low → the peel
  goes random → everyone shares the incoming, all dodging hard. "3 DPS, no tank" = emergent hard-mode, not
  a special case. **Don't** bolt flow=aggro onto every class (a healer "holding the boss by healing
  cleanly" is off-fantasy) — aggro-% is the universal layer; flow is the tank's driver on top.

**The stream reconciliation (melee vs telegraph) — this IS the built architecture** (`raid_content.gd:8`
"melee chip + Crush/Talon → the TANK parries; Void Volley aoe string → EVERYONE dodges"). One boss stream,
consumed by role:
- **Melee** = the constant, **un-freezable** chip on the aggro-holder (`enc.melee {every,min,max}`) → the
  tank's **skinny small/normal bars** (the SECONDARY dodges/blocks). Only the aggro-holder eats it.
- **Targeted DEFENSIBLE telegraphs** (aimed at the victim) → the **tall bars** (the MAIN parries/shields) =
  the "big hits"; the *same* attack a peeled squishy must dodge.
- **AoE telegraph strings** → the **flurries** (WEAVE / HOLD); everyone dodges each beat on their ration.
- Tank sees melee + every telegraph (dense = "densest footwork"); non-tanks see only what's aimed at them
  (sparse). **Tuning coupling is mild:** melee is *3 scalars* (tempo + damage band), not an authored
  pattern — class tuning (windows/mit/flow) is done ONCE vs a standard melee tempo; each boss authors its
  telegraphs + turns the ONE melee-tempo knob (the difficulty dial, cranked at Gemini/Mythos). They
  **layer** (melee un-freezable; a telegraph freezes ability timers) — one legible seam, not a tangle.
- **Determinism (build constraint):** the peel roll + the 0%-random target MUST draw from a seeded stream
  in fixed order (`state.rng` inside `update()`, or a per-policy `DetRng` — never unseeded). Flow derives
  from deterministic clean-answer counts; checksums/lockstep stay correct for free.

### §1d · RIPPLES from flow-aggro (consequences to work — none block the lock above)
- **Non-tank survivability vs peeled attacks** — a slip can send a TARGETED big hit at a squishy
  (normally tank-only). Must be **dodgeable + dangerous-not-instant** (anti-death-spiral); the peeled hit
  still telegraphs to its new victim. Tune peel lethality.
- **Healer follows the boss** — the healer duet now shifts target with aggro (heal whoever's peeled) →
  more dynamic healing; a real consequence for healer design + the AI healer policy.
- **AI tank reliability is load-bearing** — solo/backfill: the AI tank must hold flow (playing clean does
  it) + be legible to its policy; a human squishy peeled by a dumb AI slip must not feel unfair.
- **Raid/dungeon identity** — "aggro = raid-only" was a plank of that split; now universal. Raids keep
  identity via intensity + the other raid-only bits. Revise [[raid-dungeon-identity-split]] + WORLD-PLAN.
- **Hold the Line (support)** overlaps the flow/aggro readout — reframe / key it off flow at the deck pass.
- **Crucible module** (fills from damage TAKEN) fills slower while the boss is peeled away — note at the deck pass.
- **Depth affix vocabulary** gains melee-tempo + peel-severity as intensity knobs (same TuningConfig spine).
- **Single-target law (pillar #1)** unaffected — one stream, varying recipient (the built "Swing → Victim"
  already does this); worth a clarifying line in WORLD-PLAN so it doesn't read as a violation.
- **⏭ NEXT THREAD — the flow economy:** what each clean answer ADDS, what a slip SUBTRACTS, the decay
  rate, and the flow→aggro% mapping (incl. the 30%/0% points). Nothing tunes until this is set.

- **⚠ CUT HISTORY (don't rebuild):** R2 THREE DOORS/lanes · R3 SHIELD CHARGE-&-PLANT WALL +
  circle-size + THE DUEL/balance/TOPPLE/guard-break + hard phase breaks · R4 shared 3-move kit.

**Tester v5 baseline knobs** (the deck's numbers hang off these; all become `duel_*` config):
parry window 60ms · good 230ms · wind pool 10, regen 1.9/s, dodge 1, parry 3.5 (land or miss) ·
mit: parry .95 / perfect dodge .80 / good .55 (+.30 leak per power over small) / graze .28 /
parry-miss .18 / **cap .90** · ◆ max 5, dump 70/◆ (~~guard 2◆~~ DROPPED 2026-07-09, §1b) · counter 30 ·
healer inflow 26/s · stream: chip gap .5s, real hit ~1.7s, feints .22, unavoidables .20.

## §2 · THE DIALS (the lanes ARE these)

1. **THE READ** — parry-or-dodge-or-ignore per bar; feints and unavoidables live here.
2. **THE SWING** — parry window / cost / the land payoff (counter + ◆).
3. **THE STEP** — dodge grades, the height law, the feint read.
4. **THE WIND** — pool/regen/costs (folded into SWING+STEP lanes as costs).
5. **THE BANK** — ◆ income (parry-only at base) and cap.
6. **THE SPEND** — the DUMP-vs-GUARD fork; guard placement vs unavoidables.
7. **THE DUET** — the bleed vs the healer; the party-facing surface (support card lives here).

## §3 · THE DUELIST DECK v1 (AT VERDICT — this is the hard copy)

**Design brief (Bill, 2026-07-08):** replay-driving, dynamic cards; **DEEP stacked builds, not many
strategies fighting** — every card feeds ≥1 of three named ladders; lanes cross-feed.

**THE THREE LADDERS:**
- **THE HEADSMAN** (bank-and-burst): Wager/Bellows → Whetstone → Heavier Steel · High Line ·
  The Rally · Deep Pockets · Powder Keg · All In → 👑 THE AVALANCHE.
- **THE IRONSIDE** (the guard engine): Veteran/Bellows → ⭐ Crucible → Cheap Iron · Return to
  Sender · Blood Price · Overreach · Deep Pockets → 👑 THE IMPOSSIBLE PARRY.
- **THE GHOST** (the footwork chain): Dancer/Bellows → Scales → Feather Step · Perfect Form ·
  Read the Room · The Rally → 👑 BORROWED TIME.

### CREEDS (pick 1/run — curated)
| Creed | TYPE | Effect |
|---|---|---|
| **The Veteran** | EASE | Window ~74ms; a missed swing refunds half its wind. Counter −25%, ◆ cap 4. The learner's blade — caps itself so you graduate out. |
| **The Wager** | GREED | Parry costs 4.5, a miss leaks +10% — a LAND banks ◆◆ and counter +40%. The greed pole. |
| **The Bellows** | STRAT | Wind regen halved; every clean answer (land or perfect step) +1.5 wind instantly. The rhythm-changer — the pool becomes a chain. |
| **The Dancer** | RULE | **WILD — the parry button is GONE.** A PERFECT dodge IS the parry (counter + ◆ every other perfect); GOOD stays a dodge; baited lockout +0.2s. One button, pure height-reading; the mobile creed. |

### MODULES (Floor-1 pick 1-of-3 · exactly one ⭐)
| Module | TYPE | Effect |
|---|---|---|
| ⭐ **The Crucible** | RULE | TRANSFORMER. Damage TAKEN fills it (the bleed is fuel) → IGNITES: ~6s WHITE STEEL (parries cost 0 wind, lands bank ◆◆, counters ×1.5) → crash (regen dead 4s, gauge empty). Eat-the-unavoidable-now ignite timing is the decision. |
| **The Scales** | STRAT | Balance pan: parries tip crimson, dodges tip blue; near-BALANCE = growing edge (to +12% dealt / −12% taken); pegging a side kills it until re-centred. Anti-autopilot. |
| **The Whetstone** | GREED | Each banked ◆ sharpens over 4s (sharp pip ×1.5 in a dump); an unanswered real hit dulls your sharpest pip. Hold-vs-spend with teeth. |

### BOONS (15 · 4 dial-lanes · H/S/O ladders, base = Haiku · EASE count 3/15 · ≤1 pardon per lane)
**LANE THE SWING:** Heavier Steel POWER (counter +20/30/40%) · Quick Wrists EASE (window
+8/12/16ms, fades while ◆ full — tapers with power) · High Line STRAT (tall-bar land: ◆◆ / +1 wind /
counter ×1.5 vs tall) · Overreach GREED (parry while WINDED for 8/7/6% max-HP blood, never below
10% HP; O: blood-land banks ◆◆ — feeds the Crucible).
**LANE THE STEP:** Feather Step POWER (dodge −25/35/50% wind, floor 0.5 — CARRY) · Perfect Form
STRAT (perfect dodge refunds wind; next parry ≤2s −1/−1.5/−2 — the step-into-swing chain) ·
Read the Room STRAT (a READ: +1 wind, next counter +8/12/16%; O stacks ×2) · Roll With It EASE
(good dodge on tall: leak → 3s bleed, +0.5/0.7/1 wind — the lane's one pardon, dressed for the duet).
**LANE THE BANK:** Deep Pockets POWER (cap +1 / +1 & start 1◆ / +2 & start 1◆ — CARRY) ·
The Rally GREED (every 3rd/3rd/2nd land in an unbroken chain banks double; miss/graze breaks,
dodges don't) · Blood Price STRAT (eat an unavoidable: ◆ / +2 wind / next spend +20%).
**LANE THE SPEND:** Powder Keg POWER (dump +20/30/40%/◆ — CARRY) · All In GREED (full-bank dump
×1.25/1.4/1.5; at full bank take +10%) · Return to Sender STRAT (guard stores 40/55/70% of
prevented damage, hurls it back as a bar when it drops) · Cheap Iron EASE (guard 1◆; cut 45/50/55%).

### RIG (WHEN → THEN · THENs: STRIKE 20 dmg · IRON 2s +20% DR · BREATH +2 wind · PIP +1◆ · BANNER 2.5s warband +5%)
The Tall Land (parry a TALL bar — premium) · The Big Spend (dump ≥4◆) · The Wall (Guard eats a
hit ≥15% max HP — premium) · The Read (correctly ignore a feint). All chooseable/earnable.

### KEYSTONES (elite-only, spectacle — each changes what the gate looks like)
- **THE AVALANCHE** — DUMP becomes a returning string: each ◆ is a bar sailing BACK across the
  gate; press as it crosses = ×2. The offense on the same instrument, reversed.
- **BORROWED TIME** — a full-speed land SLOWS the stream 1.5s (bars crawl); slowed-time lands
  don't refresh (no perma-slow).
- **THE IMPOSSIBLE PARRY** — unavoidables grow a gold sliver: perfect swing at DOUBLE wind cost
  parries them; land = counter ×2 + ◆◆; miss = eat hit + swing. Makes Blood Price a live choice.

### SUPPORT (1)
✦ **Hold the Line** TEAM — while THE LINE HOLDS (no unanswered real hit in last 5s), warband
+6/8/10% damage. Uptime IS the buff; keyed to the core state.

### CARRIES (verbatim on the Warden — verified per-knob)
Feather Step (block cost = same knob) · Deep Pockets · Powder Keg · ✦ Hold the Line.
NOT carried: Blood Price (Warden has no unavoidables) · Read the Room (counter rider dead — no attack).

### Self-audit (deck-creator §3/§1/§4 — for the record)
Anti-pattern sweep clean (no passive wind-ups, no stat keystones, no one-time bonuses, no extra
buttons — the Dancer REMOVES one; Avalanche reuses the same press) · insurance ≤1/lane, dressed
(Roll With It) · greed chosen per use everywhere (no luck-wearing-greed) · offer-trio spot-checks
pass (archetype breads compete; payoffs compete) · every card feeds a ladder, zero ballast ·
wideners taper with power (Quick Wrists) · caps stated on every scaling effect · BROKE/FADED/DEAD/
OPENED n/a (first deck; old Bulwark guard boons are the frozen placeholder's, not this class's).

## §4 · BUILD ORDER (after Bill's verdicts — do NOT start before the export blob lands)

1. **Fold verdicts** into this doc (statuses → STANDS/REWORKED/CUT), lock names (class + wind).
2. **Guarded base kit** (Well idiom): class codename on the tank seat, `--autostart=raid:tank:duelist`,
   old Bulwark stays the default — **byte-identical unless picked** (A/B via `scripts/ab-gate.sh`).
   The kit reducer runs bespoke **parry (F) + dodge (SPACE)** — **no `unified_dodge()` opt-in, and no
   universal dodge ration** (§1a); bars/wind/◆/duet hooks via existing seat surfaces; all numbers
   `duel_*` on the class config. Boss streams = encounter data (authored per Seal, Warband Law).
3. **Deck layers** kit-local + `_fw()` dispatch (creeds/modules/boons/rig per the Well's framework
   wiring); fixed rarities + `ctype` tags per [[card-type-tags]].
4. **Sims:** `duelist_sim` base loop + per-creed/module/build cells (Whetstone hold-EV, Crucible
   ignite timing, Dancer one-button win-rate) · determinism PASS 300 seeds · `raid_sim --tank=` carry.
5. **HUD slice:** the bar-stream on the raid HUD's timing instrument (StrikeJudge idiom) + ◆ pips +
   wind bar + module gauges; WSLg screenshot probe (headless can't render `_draw`). This stream IS the
   boss's telegraph to the tank seat — do NOT also spawn the universal dodge ration/cue (§1a).
6. **Pillar #3 flag:** ⚡ DUMP is the natural interrupt-carrier (burn the bank to kick) — engine-side
   flag with the interrupt-by-ability pass, not before.

## §5 · OPEN / LATER
- The Warden deck pass (same board format) — after the Duelist frame survives contact with Bill.
- Warden module candidates already named: the hold-all wall (old base, too strong) + dump variations.
- Per-boss authored streams for the 4 Seals (encounter data) — with the build, not the deck.
- Online spec-carry `(seed, spec)` — the shared debt every rework owes.
