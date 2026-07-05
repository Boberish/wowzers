# GEAR CATALOG v1 — Realm 1 Ledger pages (items + oaths), design of record

**Owns:** the concrete item & oath designs for Realm 1's boss Ledger pages. System laws
(lanes, slots, Monotonic Pool Law, drop machinery, oath purses) live in `PROGRESSION-PLAN.md` —
this doc is the content that GEAR-1/2/3/4 implement. Written 2026-07-03 against the class-fun
rework wave (Chain/Redline + Sunder · Accelerando/Poison-Wheel · Litany · Ripen/Snap) — every
combat item below names its hook and its combo so implementation is mechanical.

## Design rules (recap + catalog-local)

- **Lane law:** gear = fortune + new buttons (procs on execution moments, actives-with-charges,
  set pairs, map/economy utility). Never a passive "+X% to your verb" — that's a boon.
- **Guardrail — gear never plays the game for you.** No auto-grades, no auto-presses. Gear
  *rewards* reads and *offers decisions*; it never makes them. (One deliberate meme exception:
  THE UNPLUGGING, flagged below.)
- **Scope marks:** `UNIV` = any seat · `class[aspect]` = rolls only for that seat's class
  (personal loot filters rows by the seat). `[SIM]` = combat-touching, enters balance sims ·
  `[UTIL]` = map/economy, sims never see it (the volume lane).
- **Sim strategy (Law 6):** class-marked [SIM] items sim in that class's sim; UNIV [SIM] items
  sim in `raid_sim` (they're raid-sourced) + a per-class spot-check. Budget honored: ≤4 combat
  pieces per class + ~12 UNIV combat pieces total in v1.
- **Oath detectors read `seat.diag` ONLY** (deterministic, per-seat, never checksummed).
  `state.events` is view-only/bounded — never a detector source. Where a deed below needs a
  counter that only exists as an event today (benedictions, chain breaks, curse-answer timing,
  hp watermarks), GEAR-2 adds the matching `seat.diag` bump next to the kit's event emit.
- **Actives need a button:** 1–2 gear sockets beside the rune rail, keys **G / H** (free on all
  six HUDs; F=dodge, T=Challenge, M=meter, S=book). Charges shown as pips on the socket.
- **VERSION rows** require the Trial Ladder (still planned). Until it lands they render locked
  as *"REQUIRES A FUTURE PATCH"* — which is exactly what the theme wants them to say.
- **Gear noun (proposal for the open Q, not locked):** global **CURIO**, Realm-1 display skin
  **PERIPHERAL**. ("Relic" stays the boon card.)

---

## ⚠ UNIVERSAL CURIO POOL v2 — the direction changed (Bill, 2026-07-05)

**Read this before the per-boss pages below — those are now legacy.** From the Tempo-pilot curio pass, the
curio layer was redirected: curios are now a **single UNIVERSAL (cross-spec) FORTUNE / RUN-SHAPING pool** —
no per-class curios (kills the Bloomweaver-dark gap + per-class authoring; every class draws the same trinkets).
Retention is unaffected: you still unlock via boss oaths into a collection Ledger — the *reward* is just usable
by any class; the deep per-class retention moves to **Creeds / Modules / cards** (the class layer).

**THREE HARD RULES** (supersede the old lane law for curios): (1) **never touch the combat verb** — no Flow /
Perfect-graded window / strike-result hook / Marks (those are Creed/Module/card territory); (2) **always-on
rule-changes / "while X" conditionals / set-bonuses — NO one-shot or per-floor/per-fight counter budgets** (gate
only on natural beats: at a Seal, when you'd die, on a boss kill); (3) **no ability-charms** (nothing hung on
Kick/finisher/Dodge). Plus **(Bill, 07-05) no DOUBLE creeds/modules** — a curio may pick/swap/upgrade your one
Creed + one Module, never let you hold two.

**CUT — the 10 old verb-welded/class curios** (from `gear_catalog.gd`, the content pass): Powder Vial · Encore
Bell · Grace Period · Verification Stamp · Sticky Note · Debt Collector · Spark Plug · Echo Chamber · Salt Vial ·
Overflow Sluice. **KEEP** (already clean universal fortune): Swan Song · Cooling Paste · Scratchpad · Le Chat's
Bell (energy, NOT Flow) · Ticket Stub · Riftmaw Tooth.

**THE WORKING POOL (~18 universal curios, rarity = the guardrail — run-warpers are Opus/RARE):**

| Surface | Curio | Rarity | Always-on effect |
|---|---|---|---|
| Draft | **Expansion Bus** | Sonnet | Boon drafts are always **1-of-4** (set w/ any 2nd Fortune → 1-of-5). |
| Draft | **Cache Buffer** | Opus | Decline any draft to BANK it (no cap); at a Seal, cash all as one **1-of-(2+banked)** mega-draft. |
| Draft | **Mirror Array** | Sonnet | Your synergy-slot boon counts as **two** for stacking/synergy. |
| Draft | **Sync Coupler** | Haiku | Slot-0 synergy option guaranteed every draft, +1 rarity tier. |
| Module/Creed | **Root Access** ⭐ | Opus | Floor-1 Module pick shows your **ENTIRE unlocked pool** — take any one. |
| Module/Creed | **Reflash Bay** | Sonnet | At every Seal, swap your Module **OR** Creed for any unlocked, free. |
| Module/Creed | **Overclocked Firmware** | Haiku | Creed & Module always equipped **+1 tier**. |
| Map | **Panopticon Lens** | Haiku | Entering a floor reveals its whole Topology. |
| Map | **Port Forwarder** | Sonnet | Descend into **any** node on the next row (graph no longer constrains). |
| Map | **Replay Buffer** | Opus | Every CACHE node **resolves twice**. |
| Map | **Root Credential** | Sonnet | All GATEs open free (access-key cost = 0). |
| Econ/Slot | **Bootleg Expansion Port** ⭐ | Opus | A **3rd curio slot**; warranty void: **−25 max integrity permanently**, un-repairable. |
| Econ/Slot | **Hashgrinder Rig** | Sonnet | **All Token income ×2**, forever. |
| Econ/Slot | **Deprecation Notice** | Sonnet | **Haiku delisted** — every drop/Cache/Market rolls Sonnet+. |
| Econ/Slot | **Ratchet Firmware** | Haiku | Drop pity — a Haiku reward raises the next drop's floor until Sonnet+ lands. |
| Set/Wild | **The Rig** (Overclock Chip + Liquid Cooler) | Sonnet ×2 | Solo mild; SET → every boon **+1 tier** at **+1 wound/combat**. |
| Set/Wild | **Autosave / Cloud Rollback** ⭐ | Opus | Rewrites death: when you'd die, roll back to your last Seal at 1 integrity, boss heals full. |
| Set/Wild | **Fork Bomb** ⭐ | Sonnet | Draft an **Opus** boon → **draft again** (recurses). |
| Set/Wild | **Reverse Engineer** | Sonnet | Each boss kill bolts that boss's signature into your Ledger as a passive. |

**CUT from the pool (Bill 07-05, too strong / breaks identity):** Hivemind Fork (2 creeds) · Two-Factor pair
(2 creeds + 2 modules). One identity, never doubled. Source: bold-curio design pass (`wf_dea97f02`). Status:
approved "for now" — working pool, not final; the per-boss pages below are legacy pending the content pass.

## Drop scaling by depth (starting values, knobs on `TuningConfig`)

**ARMORY cadence (2026-07-03): drops are EVENTS.** Rolls fire only at Seal kills, gate
exams, and any kill whose SIGNATURE is still locked (first-kill shower); repeat skirmish
kills pay salvage Tokens (1/2/3⏣ by ring), no roll. With ~4–6 rolls per descent the
weights below are retuned RICHER than the pre-armory table (shipped in `Gear.rarity_weights`).

Rarity is rolled first (pity-bent, persists across bosses), then the item within the tier,
synergy-weighted (`draft.gd` tag matching — every item below lists its tags).

| Surface | Haiku / Sonnet / Opus base weights |
|---|---|
| Ring 3 (Seal + gate + first-kills) | 50 / 35 / 15 |
| Ring 2 | 38 / 40 / 22 |
| Ring 0 | 25 / 40 / 35 |
| Skirmish kills | first kill = the SIGNATURE (guaranteed); repeats = salvage ⏣, no roll |
| Boss version v2/v3 | shift a further 8pp per version from Haiku upward |
| Sworn-oath KEPT | purse bend on top (see PROGRESSION-PLAN table) |

**Signature philosophy (ARMORY, supersedes the all-Haiku taste rows):** the SIGNATURE is
the boss's iconic STRONG piece (printed Sonnet for the combat six) — a first kill must
change how the next fight feels. Shipped strong versions are inlined per row below.

---

# THE SEAL PAGES

## VORATHEK, THE RIFTMAW (Seal I — the tutorial page; universal basics)

- **RIFTMAW TOOTH** · **Sonnet (ARMORY)** · UNIV · [SIM] · **SIGNATURE (first kill)** — whenever
  a boss self-heal is DENIED (anyone's kick), **your defensive verb and dodge reset** and you
  gain +20 primary resource. *Combo:* makes the kick game visible to every seat from hour one —
  and the denial moment hands you your verbs back (a free guard/dodge/kick window).
  *Hook:* staggered-heal moment (`GearFx.tooth_grant` resets `defense_ready_tick`/`dodge_ready_tick`).
  *Tags:* [interrupt, mana, rage, focus]. Pop: *"CHECKPOINT CORRUPTED — scavenged."*
- **STICKY NOTE** · Haiku · bulwark · [SIM] · **OATH sev-I: "answer every Baleful Curse within
  2s"** — taunting back within 2s of a THREAT_DROP refunds +15 rage. *Combo:* teaches the
  curse response it's earned by; Challenge economy. *Hook:* taunt-after-threat-drop timer
  (deterministic tick pair). *Tags:* [guard, rage]. Flavor: a note taped to the boss's
  monitor: "THE TANK EXISTS."
- **GRACE PERIOD** · Sonnet · UNIV · [SIM] · **OATH sev-II: "clear with zero raider deaths"**
  — once per fight, your class streak survives its break: Warden chain-halving holds ·
  Tempo Flow survives one landed swing · Thornveil streak survives one wilt · Mender skips one
  Litany decay · Jugg's first below-cap dodge doesn't dump Momentum · Voidcaller's first
  whiffed kick refunds the cd. ONE item, six class meanings. *Hook:* each kit's break site
  checks a `gear_grace` flag. *Tags:* [counter, flow, thorns, litany, momentum, interrupt].
  Pop: *"GRACE PERIOD — forgiven."*
- **RIFTMAW'S HUNGER** · Opus · UNIV · [SIM] · **VERSION v2** — surviving a single hit ≥60
  primes you: your next ability is free and instant. *Combo:* Brinkwarden wants allies (and
  itself) bloodied; Jugg `bulldoze` eats CRUSHes on purpose; BLOCKABLE finishers become fuel.
  *Hook:* `on_damage_taken` threshold → one-shot flag consumed in `on_action`.
  *Tags:* [bloodied, momentum, rage]. Pop: *"PAIN IS FUEL."*

## MISTRAL-7B, LE GOLEM EFFICACE (Seal II — efficiency)

- **LE CHAT'S BELL** · **Sonnet (ARMORY)** · UNIV · [SIM] · **SIGNATURE** — start every fight
  with +30 primary resource, pre-warmed — and the warm start HUMS: resource flows twice as
  fast for the first 10s ("lightweight and efficient"). *Hook:* `GearFx.bell_live` at each
  kit's Scratchpad regen site. *Tags:* [mana, rage, focus, sap].
- **RELAY BATON** · Sonnet · UNIV · [SIM] · **OATH sev-II: "kick every verse of Recite the
  License"** — when ANOTHER raider lands a kick, your defensive-verb cooldown ticks 2s faster.
  *Combo:* the kick-rotation item — chains (2s verses vs 5s kick cd) become a relay; stacks
  with Twin Guard/Twin Step/Twin Void charges. Pure co-op fortune — does nothing solo.
  *Hook:* on any other seat's interrupt diag bump. *Tags:* [interrupt, guard, dodge].
- **FREE TIER** · Opus · UNIV · [SIM] · **VERSION v2** — the first use of each equipped
  active per fight consumes no charge. *Combo:* every active in this catalog (Pruning Shears,
  Mute Button, Leech Chalice, Rollback Script, the pair press…); the actives-build enabler.
  *Tags:* [tokens]. Flavor: *"You have used 0 of your 2 requests."*

## GEMINI ULTRA, THE TWIN CONSTELLATION (Seal III — doubles)

- **A/B COIN** · Haiku · UNIV · [SIM] · **SIGNATURE** — at fight start a seeded flip: +25
  resource or a 40-pt ward (result shown big: "variant A" / "variant B"). Fortune with a
  personality. *Tags:* [ward, mana, rage].
- **SEVERANCE PACKAGE** · Haiku · UNIV · [SIM] · **OATH sev-I: "destroy BARD.EXE before
  Gemini returns"** — when an add dies, the party heals 25 and you gain +10 resource.
  *Combo:* add waves and skirmish floors; makes killing the subagent feel *paid*.
  *Hook:* add-death moment. *Tags:* [growth, reservoir]. Pop: *"role made redundant."*
- **PLUG** (½ of THE UNPLUGGING) · Sonnet · UNIV · [SIM-pair] · **OATH sev-II: "no raider
  death during the add phase"** — alone: +1⏣ Token on every Seal kill. See THE UNPLUGGING.
- **SECOND OPINION** · Opus · UNIV · [SIM] · **VERSION v2** — your PERFECT and READ beat
  payoffs fire twice. *Combo:* the class-fun payoff economy doubled — chain links, Momentum,
  Flow, mana sips, Sap, Focus; monstrous with `trigBeat`-family slot pieces (their proc
  moments double too). The cross-class chase legendary. *Hook:* `on_strike_result` wrapper.
  *Tags:* [perfect, counter, flow, momentum]. Flavor: *"Double-checked. Both of you were right."*

## CLAUDE MYTHOS, THE FINAL COMPUTE (Seal IV — the finale page)

- **COMPLIMENTARY APOLOGY** · Haiku · UNIV · [SIM] · **SIGNATURE** — whenever the boss
  EMPOWERs or self-heals, you gain +10 resource. *"We apologize for the inconvenience."*
  *Tags:* [interrupt, mana]. (Even the finale page has a taste row.)
- **SCRATCHPAD** · Sonnet · UNIV · [SIM] · **OATH sev-II: "bring all four out alive"** — during any boss wind-up ≥6s, your resource regen triples. *Combo:* the
  ULTRATHINK/parked-comet answer — Reservoir banking, garden pre-planting, Focus pooling
  while it "thinks". *Hook:* `upkeep` reads the live telegraph length. *Tags:* [mana, sap,
  focus, reservoir]. Flavor: *"use the thinking time."*
- **SOCKET** (½ of THE UNPLUGGING) · Sonnet · UNIV · [SIM-pair] · **OATH sev-II: "kick the
  Conclusion in every Chain-of-Thought"** — alone: your actives get +1 max charge.
- **THE CONCLUSION** · Opus · UNIV · [SIM] · **BLOOD OATH sev-III: "win without ever kicking
  Hotfix Deployment"** (the boss heals free — a dps-check handicap) — while the boss is ≤15%,
  your verb-proc payloads fire ×2. *Combo:* the whole slot-verb build detonating in the
  execute window; pairs with Sunder's broken wall for the team burst finish.
  *Hook:* payload dispatch multiplier gated on boss hp frac. *Tags:* [perfect, counter,
  backlash, bloom]. Flavor: *"it scales."*
- **THE UNPLUGGING** (set pair: PLUG + SOCKET, both slots — your whole inventory) — once per
  fight, press G to yank the cord: the boss's current telegraph fizzles. *"(In hindsight, the
  power cable was right there.)"* The realm's central joke as the realm's meme build. ⚠ This
  is the ONE deliberate erase-a-mechanic item; the price is both slots and the pair's halves
  are modest alone (the PROGRESSION-PLAN set-pair tension, exactly). Playtest knob: fizzle
  everything vs. everything-but-UNANSWERABLE.

---

# THE SKIRMISH PAGES (2–3 rows, mostly UTIL — the taste lane)

## BARD.EXE (deprecated)
- **SWAN SONG** · Haiku · UNIV · [SIM] · **SIGNATURE** — when you die, you fire a final
  **200** blast and the party heals **25** (ARMORY buff — the poem got meatier).
  *"It saved its best poem for last."* *Tags:* [bloodied].
- **COUPON CODE** · Haiku · UNIV · [UTIL] · **OATH sev-I: "take zero hits from Farewell
  Sonnet"** — MARKET prices −1⏣.

## SONNET SUBAGENT (stray)
- **TICKET STUB** · Haiku · UNIV · [UTIL] · **SIGNATURE** — closing a TICKET also repairs
  +10% party integrity and pays +1⏣ (ARMORY buff). (The subagent does the chores.)
- **SKELETON API KEY** · Sonnet · UNIV · [UTIL] · **OATH sev-II: "kill before its second
  Parallel Tool Calls"** — opens one 401 door per floor without the key.

## OPUS SUBAGENT (stray)
- **COOLING PASTE** · Haiku · UNIV · [UTIL] · **SIGNATURE** — active (2 charges/run): clear
  one CORRUPTED SECTOR wound. The wound-economy pressure valve, earned not found.
- **ROLLBACK SCRIPT** · Sonnet · UNIV · [SIM] · **OATH sev-II: "deny every Hotfix
  Deployment"** — active (1/fight): restore your HP to its value 3s ago (self only — the
  fight keeps everything else; a misread stays punished, you just survive it). This is the
  parked "rewind verb" landing at its correct size: a rare defensive curio.
  *Hook:* per-seat hp ring-buffer (diag-family). *Tags:* [ward, bloodied].
- **CACHE PREFETCHER** · Haiku · UNIV · [UTIL] · **VERSION v2** — CACHE and secret rooms are
  revealed on floor entry ("cache hit!").

---

# THE GATE PAGES (class-marked — your exam pays in your class's toys; the natural oath stage)

## CAPTCHA-9, THE GATEKEEPER (tank gate → Bulwark page)
- **VERIFICATION STAMP** · **Sonnet (ARMORY)** · bulwark · [SIM] · **SIGNATURE** — your first
  clean negate each fight banks +4 chain links (Warden) / +8 Momentum (Jugg) **and resets
  Guard on the spot** (chain a second read). *"Verified: not a robot."*
  *Tags:* [parry, counter, momentum].
- **DEBT COLLECTOR** · Sonnet · bulwark[warden] · [SIM] · **OATH sev-II: "clear the gate with
  the chain never broken"** — Vindicate cashed at 5+ links also staggers the boss. *Combo:*
  Chain ride → cash → free swing window; `riposteChain`/`vindInterrupt` builds.
  *Hook:* `_vindicate` link count. *Tags:* [counter, riposte].
- **AFTERBURNER VALVE** · Sonnet · bulwark[juggernaut] · [SIM] · **OATH sev-II: "spend the
  whole gate fight at Momentum ≥6"** (the `sunder_jugg_at` floor — the deed teaches the
  Sunder feed) — entering OVERDRIVE vents a free mini-Avalanche (3 hits × 30, no cost, no
  Momentum spent; 10s icd). *Combo:* Redline riding; `snowball`/`sureFoot`. *Tags:* [momentum].
- **KEYSTONE OF THE BROKEN WALL** · Opus · bulwark · [SIM] · **BLOOD OATH sev-III: "win with
  Guard sealed"** (the canonical Blood Oath) — when SUNDER hits max (WALL BROKEN), every
  raider's defensive verb resets. *Combo:* the tank's reads hand the whole raid its verbs
  back mid-burn — Sunder's co-op payoff made physical; stacks with Twin Guard/Step/Void
  (reset + charge = doubled windows inside the broken wall). Earned alone in your exam,
  wielded for the team. *Hook:* sunder-max moment → per-seat `defense_ready_tick` rewrite.
  *Tags:* [guard, parry, momentum]. Pop (raid-wide): *"THE WALL IS DOWN — GO."*

## FIREWALL (blade gate → Twinfang page)
- **POWDER VIAL** · **Sonnet (ARMORY)** · twinfang · [SIM] · **SIGNATURE** — your Kick also
  applies 3 stacks of the lit wheel lane (Venom) / +2 Flow (Tempo). *Combo:* folds the
  off-rhythm button into each aspect's engine. *Tags:* [poison, flow].
- **ENCORE BELL** · Sonnet · twinfang[tempo] · [SIM] · **OATH sev-II: "land 8 PERFECT strikes"** — after Coup consumes max Flow, your Perfect window holds at the wide Flow-0
  anchors for the next 3 strikes. *Combo:* the Accelerando cash-out breather — spend the BPM,
  get 3 beats to rebuild it; `dancersgrace`/`crescendo` builds. *Hook:* `coup` moment →
  window-anchor override counter. *Tags:* [flow, perfect, combo].
- **ROULETTE FANG** · Opus · twinfang[venomancer] · [SIM] · **OATH sev-III: "kill with all
  three venoms at ≥4 stacks"** — completing a full wheel revolution (V→F→C→V) while all
  three poisons live triggers a free micro-Rupture SIP (0.3×, keeps stacks and Synergy).
  *Combo:* the wheel-rider's legendary — ride for revolutions instead of fixating; stacks
  with `lingerVenom` (sip school) and `catalyst` Synergy ramp; Envenom-fixate becomes a real
  tension (fixating stops revolutions). *Hook:* wheel-wrap detector + all-lanes-live check.
  *Tags:* [poison, combo, rupture].

## THE PROMPTER (caster gate → Voidcaller page)
- **SPARK PLUG** · **Sonnet (ARMORY)** · voidcaller · [SIM] · **SIGNATURE** — your first TWO
  kicks each fight that answer a cast refund their WHOLE cooldown. *"Kick early, kick often."*
  *Tags:* [interrupt].
- **MUTE BUTTON** · Sonnet · voidcaller[silencer] · [SIM] · **OATH sev-II: "land 6 clean
  kicks in the gate"** — active (2/fight): extend a live Silence and Expose by 2s.
  *Combo:* Quietus stretching, `longsil`/`deepexpose` lockout builds; a spend *decision*
  (which cast deserves the longer gag?). *Tags:* [silence, interrupt].
- **ECHO CHAMBER** · Opus · voidcaller[disruptor] · [SIM] · **OATH sev-III: "6+ kicks, none whiffed"** — a CLEAN kick at full Backlash echoes a free Overload at
  0.6× without spending the stacks. *Combo:* the full-bank rider — hold 5 stacks and keep
  kicking clean instead of dumping; `vcTrigClean` fires payloads on the same moment;
  `punish`/`overfocus`. *Hook:* `_do_interrupt` clean + backlash==max. *Tags:* [backlash,
  interrupt]. Flavor: *"the same opinion, louder."*

## POPUP, THE ADHOUND (healer gate → healer page)
- **SALT VIAL** · **Sonnet (ARMORY)** · mender · [SIM] · **SIGNATURE** — your dispel also heals
  the target 60 **and refunds its mana**. *Tags:* [mana]. (Dispel is the Mender's mint
  signature — the item makes it free AND visible.)
- **OVERFLOW SLUICE** · Sonnet · mender[tidecaller] · [SIM] · **OATH sev-II: "no ally below
  30% for the whole gate"** — overheal banked while the Reservoir is FULL becomes a ward on
  the tank at 0.5×. *Combo:* fixes the capped-flywheel waste; `floodgate`/Surge re-bank
  loops. *Hook:* `on_overheal` at reservoir cap. *Tags:* [reservoir, overheal, ward].
- **LEECH CHALICE** · Sonnet · mender[brinkwarden] · [SIM] · **OATH sev-II: "light 10 Litany
  pips in the gate"** — active (2/fight): +40 Nerve now. *Combo:* Last Stand timing, Blood
  Pact ramps — buy the save you can see coming. *Tags:* [nerve, bloodied].
- **FIFTH PSALM** · Opus · mender · [SIM] · **OATH sev-III: "cash 3 Benedictions in one
  fight"** — Benediction (the 5th pip) also fires your triage payloads on every ally it
  touches. *Combo:* the Litany build-around — 4 allies × payloads, and those payload procs
  count toward `mdPropBenediction`'s every-5th counter (the loop is the point; no lockouts,
  rebalance the boss). *Hook:* `_benediction` → payload dispatch per target. *Tags:*
  [litany, mana, ward].
- **★ Bloomweaver rows (authored now, PARKED until a Bloomweaver seat is unlock-live —
  raid comp is bulwark/twinfang/voidcaller/mender today):**
  - **PRUNING SHEARS** · Sonnet · bloomweaver · [SIM] — active (2/fight): instantly RIPEN one
    ally's Growth (age jumps to `ripe_lo`). *Combo:* manufacture the harvest window — line up
    a ripe Lifesurge mass-bloom on demand. *Tags:* [growth, bloom].
  - **ORCHARD BELL** · Opus · bloomweaver[wildgrove] · [SIM] — a Bloom harvested inside the
    ripe window replants the Growth at half duration. *Combo:* the perpetual orchard —
    sustains `bwPropDeepGarden`'s 3-Growth floor and `bwTrigPlant` procs off skillful
    harvest timing alone. *Tags:* [growth, bloom, verdance].
  - **CROWN OF BRIARS** · Opus · bloomweaver[thornveil] · [SIM] — a Perfect Ward at full
    thorn charge chains bark to the two nearest allies (0.4× mini-wards). *Combo:* more ward
    surface = more Perfect Wards = more Verdance… and more wilt risk to the streak —
    self-balancing greed. *Tags:* [ward, thorns, verdance].

---

## Rollout mapping (matches PROGRESSION-PLAN phases)

- **GEAR-1 — ✅ SHIPPED 2026-07-03 (`866592f`):** all NINE signature rows live (the five
  above + the four gate items — the gates were free since their tables key by canonical
  encounter id), drop/scrap/2-slot plumbing, unlock store, ceremony, `gear_probe`. Scrap
  Tokens bank until MARKET (GEAR-3); offline raid-map only (online spec fold-in later).
- **GEAR-2 — ✅ SHIPPED 2026-07-03 (`8d18685`):** the oath system (Ledger offer screen /
  tracker banner / KEPT-unlocks-into-this-roll / stakes purses), the rarity-first roll
  (ring weights + pity + purse bends), detector diag, and SEVEN oath-row curios: Grace
  Period, Sticky Note, Scratchpad, Debt Collector, Encore Bell, Echo Chamber, Overflow
  Sluice. v1 deed adjustments (detectability): Mythos Scratchpad = "bring all four out
  alive"; Encore Bell = "land 8 PERFECT strikes" (Coup-count needs a diag); Echo Chamber
  = "6+ kicks, none whiffed". Still paper: RELAY BATON / FREE TIER / SECOND OPINION /
  the pair / KEYSTONE / ROULETTE FANG / FIFTH PSALM / THE CONCLUSION / MUTE BUTTON
  (actives need the G/H socket) + all VERSION rows (Trial Ladder).
- **GEAR-3 (MARKET/extraction):** [UTIL] items stock MARKETs; schematics lane.
- **GEAR-4 (Seal tables/personal loot):** GEMINI + MYTHOS pages, the pair, VERSION rows
  (behind Trial Ladder).

**Acceptance:** per PROGRESSION-PLAN (byte-identical with gear absent; drop & oath
determinism; Monotonic spot-assert) + one new bar: a `gear_probe.gd` that proves each [SIM]
item's proc fires (paired-seed win-rate/TTK delta per item, like `_prove_guard_mods`).
