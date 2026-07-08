# TANK-PLAN — the tank seat's class onto Framework v2 (two kits: THE DUELIST / THE WARDEN)

**Status:** 🟡 **DESIGN — Duelist deck v1 AT BILL'S VERDICT (2026-07-08).** The round-5 minigame
(tester v5) is the locked base; the Duelist's full deck is designed and on the verdict board:
https://claude.ai/code/artifact/cf273dd1-4169-45e2-b990-47000941d417 — interactive KEEP/TWEAK/CUT,
export blob comes back here. **Nothing is built yet.** Old Bulwark = frozen placeholder, NOT the base.
The Warden's deck is a LATER pass (after the Duelist proves the frame).
**Names open (on the board):** the class (VANGUARD / AEGIS / STALWART / IRONCLAD / Bill's own) and
the fatigue resource (WIND leads — the tester already yells WINDED; BREATH / LEGS / POISE alternates).

## §1 · THE LOCKED CORE (round 5 — full history in MASTER-PLAN §CLASSES 2026-07-07)

Classic rhythm defense on the HUD's own timing UI: ONE stream of incoming hits drawn as
**vertical bars, height = power** (skinny lines; the only fat bar is the Warden's HOLD).
- **PARTIAL MITIGATION LAW** — even a perfect leaks a sliver (mit cap ~0.90). **No self-heal, ever.**
- **THE HEALER DUET = the scoreboard** — your HP bleeds, a sim healer refills; too little bleed =
  healer idle, too much = you fall.
- **COMBO ◆** = the build-and-spend resource. **FATIGUE** (wind) = the leash.
- Feints (hollow — READ if ignored, BAITED if answered) · consistent stream, no phases ·
  per-boss authored streams (encounter data, Warband Law).
- **THE DUELIST** (dense/twitch, def+off): the whole game is balancing **PARRY vs DODGE** —
  DODGE (one dodge for soft AND hard; a GOOD covers small, leaks on tall; only PERFECT covers big)
  vs PARRY (tiny ~60ms window; big wind cost **land or miss**; land = gut the hit + counter + bank ◆).
  Unavoidables must be eaten. Spend ◆: **⚡ DUMP** (all pips as burst) or **🛡 GUARD** (2◆, heavy
  damage-cut window).
- **THE WARDEN** (heavy/endurance, def-only): BLOCK (tap; perfect banks ◆) + BRACE (the block HELD
  across fat HOLD bars / overlaps; drains fast). Blocks everything (PIERCE = boss affix knob).
  Offense = ⚡ DUMP off-rhythm. The old hold-blocks-all-free = a module, not base.
- **⚠ CUT HISTORY (don't rebuild):** R2 THREE DOORS/lanes · R3 SHIELD CHARGE-&-PLANT WALL +
  circle-size + THE DUEL/balance/TOPPLE/guard-break + hard phase breaks · R4 shared 3-verb kit.

**Tester v5 baseline knobs** (the deck's numbers hang off these; all become `duel_*` config):
parry window 60ms · good 230ms · wind pool 10, regen 1.9/s, dodge 1, parry 3.5 (land or miss) ·
mit: parry .95 / perfect dodge .80 / good .55 (+.30 leak per power over small) / graze .28 /
parry-miss .18 / **cap .90** · ◆ max 5, dump 70/◆, guard 2◆ = 55% cut for 2.6s · counter 30 ·
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
   Verb reducer in the kit (bars/wind/◆/duet hooks via existing seat surfaces); all numbers
   `duel_*` on the class config. Boss streams = encounter data (authored per Seal, Warband Law).
3. **Deck layers** kit-local + `_fw()` dispatch (creeds/modules/boons/rig per the Well's framework
   wiring); fixed rarities + `ctype` tags per [[card-type-tags]].
4. **Sims:** `duelist_sim` base loop + per-creed/module/build cells (Whetstone hold-EV, Crucible
   ignite timing, Dancer one-button win-rate) · determinism PASS 300 seeds · `raid_sim --tank=` carry.
5. **HUD slice:** the bar-stream on the raid HUD's timing instrument (StrikeJudge idiom) + ◆ pips +
   wind bar + module gauges; WSLg screenshot probe (headless can't render `_draw`).
6. **Pillar #3 flag:** ⚡ DUMP is the natural interrupt-carrier (burn the bank to kick) — engine-side
   flag with the interrupt-by-ability pass, not before.

## §5 · OPEN / LATER
- The Warden deck pass (same board format) — after the Duelist frame survives contact with Bill.
- Warden module candidates already named: the hold-all wall (old base, too strong) + dump variations.
- Per-boss authored streams for the 4 Seals (encounter data) — with the build, not the deck.
- Online spec-carry `(seed, spec)` — the shared debt every rework owes.
