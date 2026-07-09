# ALCHEMIST-PLAN — "The Brew" (the poison CLASS — split out of Twinfang 2026-07-06)

**Status:** 🟢 **FULL CARD SLATE BUILT 2026-07-06** (`alch-cards` — all six slices coded on top of the base
minigame: **4 Creeds · 3 Modules (incl. the ⭐ Reaction-Vessel) · the 6×6 Combo Rig · 18 Boons · 3 Spells**,
the framework HUD generalized off the Twinfang-only gate, creed-aware offers wired). Every layer guarded →
the undrafted brew is BYTE-IDENTICAL to the base (Crucible seed1 `4344960863911121821`); the raid DEFAULT
comp is byte-identical to main (`4978452801628609439` — the Debilitator engine touch, following the sunder
precedent, is byte-neutral). Gates: creed/module/rig/boon determinism all PASS · net_smoke ALL OK
(lockstep) · gear/commander/raid/draft probes PASS · ui_smoke_raid + WSLg ALEMBIC render OK · draft offers
21 cards, Purist hides the 4 rupture cards (verdict 6). Sim A/B blocks for all four layers live in
`alchemist_sim`. **Card BALANCE is the first-cut, Bill's-playtest dial** (each card distinct + sane; skill
moves outcomes; standouts flagged: Chain Rupture −12.6s per verdict 7, Catalyst −9.0s opus; HotPour/Emulsion
rig beats + Practiced Hand/Reduction are human-skill/comfort cards the safe AI doesn't chase). **Still OWED
(post-playtest):** ~~the 2nd spec~~ → **§7 THE CASK — SLICE 1 (verb base) BUILT & VERIFIED
2026-07-07 (`cask-spec`); slices 2–5 (policy gradient · CASKWORKS HUD · card layers · balance)
next — see §7.7**, a real class puppet (art = voidcaller filler), Commander AI-caster toggle,
online spec-carry of creed/module/rig, name/art decision. Play: **`--autostart=raid:caster:brew`**
(the Brew) · **`--autostart=raid:caster:cask`** (the Cask verb preview).

**Prior status (base):** 🟢 BASE MINIGAME BUILT & PLAYABLE 2026-07-06 (`alchemist-core` — Bill's direct order:
"can't go farther without knowing live things; just do the base mini game, UI/bars… the rest after";
this deliberately front-ran the "after the Tempo pilot proves" sequencing — the 🟡 opens get settled
BY playtesting). **Live now:** the §1 CORE LOOP verbatim from the feel-test artifact (`data/alchemist/`
AlchemistConfig/Kit/Content — all artifact constants as tunables + a `dmg_scale` raid dial, 0.55) ·
a CASTER-SEAT class option on THE HUD (voidcaller stays default; default comp proven byte-identical,
4 Seals × 100 seeds per-seed checksums) · **THE ALEMBIC** flagship instrument (hold-zone reservoirs,
the vial w/ breathing sweet band + verdict stamps, tap-to-Rupture reaction chamber w/ RIPE halo,
balance see-saw, potency shimmer strip, pour-history gems, droplet arcs, scale-punch banners) ·
hold-release input (HOLD 1/2, release = pour, 3/R = Rupture; pointer zones for touch) ·
AlchemistPolicy 3 tiers + `alchemist_sim` in `psim.sh` · its own GATE exam (THE SANDBOX — the Brew
can't play the kick exam) · codex entry. **Bands:** solo (300 seeds) crucible 100/99.7/50 · leech
96/78/0.7; raid (100 seeds, alch comp) riftmaw 100/100/68 · mistral 100/100/100 · gemini 100/99/47 ·
mythos 100/94/21 — expert parity w/ the voidcaller comp (Mistral TTK 47.5s vs 48.1s), sloppy pays for
the missing kicker (F22, deliberate). Play: **`--autostart=raid:caster:brew`** (or class select →
THE ALCHEMIST). **NOT built yet (post-playtest slices):** creeds · modules · boons/rig ·
Spitfire/Decant/Reduction · second spec · a class puppet (art = voidcaller rig filler) —
**card slate LOCKED for build 2026-07-06, see ⚖ PRE-BUILD RUN-THROUGH VERDICTS below.**
**THE ALCHEMIST is a WORKING NAME — filler** (Bill: "alchemist or
something"; name/art are placeholder-grade until the class ships. Candidates: Venomancer / Plaguewright /
keep Alchemist). The old poison-wheel **Twinfang·Venom stays IN CODE as the frozen second aspect** until
Twinfang's replacement spec lands (`TEMPO-PLAN.md` §13) — do not delete it in this split.
Feel-test artifact (thumb-playable): https://claude.ai/code/artifact/003f6832-5c3b-4d0f-bf28-8ea07534d313
Pile-triage artifact: https://claude.ai/code/artifact/1d0d2ac6-e35d-4021-b50a-2677fc1d31f7
Spec-audit board (verdicts 2026-07-06): https://claude.ai/code/artifact/168429ee-6039-40e0-a3aa-7d8658a30a9c

**Why a class, not a spec (F10, Bill 2026-07-06):** the Brew shares nothing with Tempo — different
resource, minigame, pace, and fantasy. As a Twinfang aspect it read as "a stationary chemist, not the
melee BLADE." Rather than re-skin the brewing as knife-work (the audit's fix), the chemist becomes the
whole class and owns the fantasy honestly. Twinfang gets a rhythm-variant second spec instead.

**Identity:** the patient, deliberate brewer — fewer, weightier decisions (vs Twinfang's fast, twitchy
timing). **Role: DPS** (the poison/DoT seat — HARD role per class-design rule #5). Complexity budget
(rule #2): **DEEP minigame, NARROW kit** — the brew IS the class. Thumb-first controls (hold-release +
taps). Freed from the blade chassis, the puppet can BE the chemist (art = PoseRig filler when built).

---

## ⚖ SPEC-AUDIT VERDICTS 2026-07-06 (Bill) — fold before build

### ACCEPTED — design law for the build
- **F4 · the loop gets a BUILD → PEAK → REBUILD wave:** sustain PLATEAUS at the top; Rupture-at-peak is
  the optimal cash-out that resets you into a fresh build — a wave every ~15–25s (no flat-plateau
  hoarding; Tempo gets its climax from max Flow → Coup, this is ours). Chain Rupture is the wave-shaper.
- **F13 · the COMBO RIG pillar must be spec'd** — the class owes rig WHENs/THENs authored off its OWN
  beats (inheriting "every 3rd Perfect" would be incoherent in a charge-pour class). **SETTLED
  2026-07-06 — the slate is LOCKED, see ⚖ PRE-BUILD RUN-THROUGH VERDICTS** (reuses the I3 names that
  survived: Ripe / Emulsion / Boil; Top-Off stays pre-cut for easing balance; Saturation/Distill moot).
- ~~**F16 · The Still is a Floor-1 trap under two creeds**~~ — **DEAD (saturation CUT 2026-07-06).**
  The Still distilled saturation-waste and the Reckless Brewer creed removed saturation; with the
  mechanic gone (playtested off — "better off"), both cards are cut and F16 has nothing to guard.
- **F18 · Catalyst + Chain Rupture = free repeatable Rupture:** Catalyst becomes a value SNAPSHOT
  (the phantom is a damage copy, not a free full Rupture), or the two go exclusive at high tiers.
- **F21 · boons are nearly all dials — add loop-FORKS:** the accepted idea cards below are the forks.
- **Creed-aware offers = LAW (the F7 fix):** a no-Rupture Purist never SEES a Rupture card; Anchorite
  filters the cards it muffles (Clinging Rot / Decant); split the 7-card Reaction/Rupture bucket into
  reaction-DoT vs Rupture-burst. (F7's altitude complaint — temperaments mixed with core-rewrites —
  dissolved with the split: a standalone class owns its own creed altitude.)
- **I4 💡 LAST CALL (on-phase payoff):** when the boss cleanses poisons / changes phase — the event that
  normally wipes the brew — it auto-RUPTURES for full value FIRST (small seed left). The scariest moment
  becomes your best detonation.
- **I5 💡 DEEPENING ROT (patience ramp):** the longer the reaction runs fed-and-balanced, the harder Rot
  ticks; resets on stall/spoil — pays the deliberate brewer for not panicking.
- **I6 💡 REDUCTION (spell):** CD-gated active — instantly converts VOLUME into POTENCY: trade the
  sustain buffer for immediate power right before a Rupture (Decant fixes balance; Reduction trades
  sustain for spike — completes the two-axis mastery).
- **I9 💡 KILLING DRAUGHT (execute):** below the execute threshold POTENCY stops draining — locked at
  your peak for the kill. (Curator note kept: the safe pick — first to trim if on-phase content bloats.)

### OPEN — Bill-steered, settle before/at build 🟡
- **F2 · patience must be ACTIVE, not idle (talk with Bill):** the feel-tester was already frantic —
  "no time at all to chill; couldn't keep the potion perfect for more than ~5–10s" — and Bill LIKES that
  high skill. The risk is creeds/boons easing it into a slow idle ("that would be a choice they made" —
  maybe acceptable!). Levers on the table: diminishing returns on eased setups · caps · the audit's
  active-scheduling fix (Potency drains whenever you're not feeding; interleaved decay clocks; every
  between-pour moment an early/late judgment). **Bill: "let's talk about it" — no lock yet.**
- **F3 · boss interaction / dodge texture:** the boss redo is REDUCING dodge load globally (DODGE RATION
  pillar), and Bill wants per-class variance → **leading idea: this is the AUTO-EVASION class** — the
  minigame is hands-full hard, so the seat auto-dodges some/most beats as its dodge-ration identity
  (class-design rule #1 lets dodge payoff differ per class). The audit's alternative — an unanswered
  swing SPOILS the pouring dose / crashes Potency a step — is PARKED, not chosen.
- **F5 · Potency stakes:** felt TOUGH in the feel-test — do NOT couple Potency to rising stakes in v1.
  Keep the audit fix (reaction consumes faster and/or sweet band narrows as Potency climbs; Anchorite
  waives it) as a **reserve lever** if playtests come back too easy.
- **F9 · readability:** verdict = **keep the current rendering** — "hard but fun" in the feel-test.
  The one-gestalt BALANCE-SCALE render (pooled fill = min(), tilt = which side, heat = potency) stays
  the documented fallback if it stops scaling under real fights.
- **F20 · VIAL pool is thin — but don't just add minigame-modifiers:** Bill: "we have lots of modifiers
  on this one — branch out from changing the mini game to add other things." New VIAL/loop content
  should open NON-minigame axes, not another sweet-band dial.
- **F22 · interrupt — SETTLED 2026-07-06 (Bill): SPITFIRE is the DESIGNATED CARRIER, built LATER.**
  When INTERRUPT-BY-ABILITY (WORLD-PLAN pillar 3) lands globally, Spitfire carries the flag — instant,
  off-brew, the perfect interrupt tax. Zero engine work in the card slices; the alch comp keeps paying
  for the missing kicker (sloppy bands) until the pillar ships. Not a zero-carrier class.
- **F1 reconcile (the Opening):** F1 was accepted pre-split as "Opening = the CLASS verb for both
  specs." Post-split it resolves as: Opening = **Twinfang's** baseline verb; the §3 "Opening —
  CROSS-SPEC module" row below is **dead as written**. Whether this class keeps an Opening-window
  interaction (Rupture-in-the-window bonus) is an open call — the F3 auto-evasion identity may cover
  the boss-hookup need differently.

---

## ⚖ PRE-BUILD RUN-THROUGH VERDICTS 2026-07-06 (Bill) — the card-slate lock

The "last run-through before code" pass. Four calls locked + four holes found in the accepted cards
and fixed here. **The slate below this section is now the build spec.**

1. **⭐ TRANSFORMER = THE REACTION-VESSEL (locked — fills §3 slot 3).** Inverts the loop: the reaction
   deals NOTHING and banks into a vessel; Rupture dumps the whole vessel at the potency multiplier.
   Sustain/burst flipped — the brew becomes a pure charge-and-release cannon; stall/die with a full
   vessel = damage never dealt (the risk). Purist never sees it (creed-aware module filter, verdict 6).
   Rejected: Twin-Still (doubles minigame load against the F2 "already frantic" finding), Catalyst-forge
   (overlaps Chain Rupture/Catalyst boons, dead under Purist).
2. **RIG SLATE LOCKED (settles F13/I3)** — WHENs (mult ≈ inverse-freq × premium, Sweet Pour = 1.0
   anchor; sim-tuned like Twinfang's): **Sweet Pour** 1.0 (a sweet-band release — the drumbeat) ·
   **Hot Pour** ~2.3 (the last 2% before the red line) · **Emulsion** ~3.0 (hold balance ≥ 0.9 for 4s)
   · **Ripe** ~4.5 (Rupture on a glowing sigil) · **Boil** ~6.5 (reach max Potency) · **Perfect Wave**
   ~8 (Rupture within 2s of max Potency — the F4 wave cashed at the top). THENs (base at Sweet Pour):
   **Splash** (damage burst) · **Backwash** (refill both poisons) · **Quicken** (instant Potency) ·
   **Residue** (small lingering boss DoT) · **Fume** (boss deals −% for 2s) · **Overfill** (next
   Rupture +%). Creed-aware board: Purist's board hides the Rupture WHENs (Ripe / Perfect Wave) and
   Overfill. No easing THENs (Top-Off stays cut).
3. **RARITY = FIXED PER CARD this slice (Tempo parity).** The plan's "every card rolls H/S/O per
   offer" law needs the per-offer tier-roll engine that is DESIGNED NOT BUILT for Tempo too
   (TEMPO-PLAN Appendix A). Ship fixed rarities + base numbers now; design the H/S/O ladders on paper
   per card; both classes inherit the shared tier-roll slice when it lands.
4. **F22 SETTLED — Spitfire = designated interrupt carrier, built when pillar 3 lands** (see the
   audit block above).
5. **LAST CALL REFRAMED — the trigger didn't exist.** The accepted card fired on "boss cleanses
   poisons / phase change — the event that normally wipes the brew," but NO engine boss cleanses
   anything and phase transitions don't wipe the brew (artifact-world premise). Reframed: **on a boss
   PHASE TRANSITION, the brew auto-cashes at full value (small seed left)** — no wipe mechanic added
   (boss-side changes belong to the Seal pillar pass). Still the on-phase payoff I4 wanted.
6. **CREED-AWARE OFFERS — the mechanism + the module extension.** Build: a `hide_creeds` tag on cards
   + one check in `Draft._ok()` reading `run.creed` — byte-identical for every untagged class (the
   determinism gate holds). **The law EXTENDS to MODULE offers:** Purist never sees Fermentation or
   the Reaction-Vessel (a no-detonation creed must not draw detonation modules).
7. **CHAIN RUPTURE number was STALE — as written it was a nerf.** The card said "keeps 30% of the
   brew" but the base kit already keeps 35% (`rupture_keep 0.35`, added after the card was drafted).
   Now: **keeps +30pp more (≈0.65 total)**, sim-tuned.
8. **Watch-items (not blockers):** the slate carries ~5 easing dials (Preservative / Clinging Rot /
   Steady Pour / Practiced Hand / Distilled Focus) — exactly the F2 drift, accepted as "a choice they
   made," reserve levers stay shelved; Purist is where F2 bites hardest (all-sustain + no wave = pure
   upkeep loop) — watch in playtest. Build-time defaults I set in code: Volatile Mix "hard tip"
   threshold, Killing Draught execute %, Anchorite filter list (Clinging Rot + Decant filtered;
   Preservative stays offered at half value).

## 1. THE CORE LOOP 🔒

**Two OPPOSING poisons** on a see-saw:
- **VENOM** — hot, aggressive, **fades fast** (demands constant attention)
- **ROT** — cold, creeping, **lingers** (set it and it holds)

**THE VIAL (the apply minigame):** hold a side to charge a vertical vial, release to pour.
- The fill is **non-linear** — slow at the bottom, **accelerates hard near the top** (quadratic).
- **Min-charge floor:** release too early = fizzle, nothing (no tap-spam).
- **Sweet band** near the top = a POTENT dose; **overflow past the red line = SPOILED** (~nothing).
- The greed: how high do you dare charge as it accelerates?

**THE REACTION (the core damage):** the two poisons react where they meet —
- Reaction scales with **min(Venom, Rot) × balance** — the SMALLER side gates it. 10/2 barely reacts.
- Raw single-poison DoT is deliberately weak; **blindly stacking one side is bad by design**.
- ~~**Saturation:** each poison has a soft cap — pouring into a full side is mostly wasted.~~
  **CUT 2026-07-06 (Bill playtested it off — "better off").** It was flag-gated, A/B'd (the sim
  showed it barely bound — ±5pp win, same TTK/potency; a disciplined brewer never over-pours), then
  removed entirely. The HARD cap (12) is the only ceiling now; full pours always land. **⚠ knock-on:
  the two cards defined BY saturation are cut with it — the Reckless Brewer creed (§2) and the ⭐
  Still module (§3) — so the class ~~now OWES a replacement ⭐ transformer~~ **[OWE VOID 2026-07-09,
  Bill — the transformer requirement is DROPPED; modules are add-ons now, `DECK-LAYOUT.md §1`. No
  replacement transformer is owed — the Reaction-Vessel `min(V,R)×balance` core stands on its own;
  fill any freed module slot with whatever adds the most play.]** The reaction's `min(V,R) × balance` skill is untouched — keeping the bars EVEN
  is still the whole game; you just can't waste a pour into a full side anymore.
- The reaction slowly **consumes the brew** — keep feeding it; no banking a stable pile.

**POTENCY (the earned power bar — this class's Flow):** fills while you sustain a **balanced, fed**
reaction; drains fast when lopsided or dry. **Multiplies EVERYTHING** (reaction + Rupture), ×1 → ×2.6.
One bar = "how well am I brewing," and it IS your power.

**RUPTURE (the trigger):** tap to detonate = **FUEL (balanced volume) × POWER (potency)** — multiplicative,
so the peak is both-high; the button **glows "ripe"** when both are up. Consumes most of the brew.
**Audit F4 (accepted):** sustain plateaus at the top, so Rupture-at-peak is the optimal cash — the loop
is a BUILD → PEAK → REBUILD wave (~15–25s), not a flat plateau with a hoarded button.

**Controls (thumb):** hold-left = brew Venom · hold-right = brew Rot · release = pour · tap = Rupture.

---

## 2. CREEDS (run posture, pick 1 of the pool) 🔒 — 4 now (Reckless Brewer cut with saturation)

1. **The Steady Hand** — forgiving: wide balance window, gentle potency drain, overflow fizzles (no spoil).
   Lower potency ceiling. *(the learner)*
2. **The Volatile Mix** — +50% potency ceiling & bigger Ruptures; a SPOILED pour or hard tip **crashes
   potency to 0**. *(the glass / greed pick)*
3. **The Anchorite** — **ROT IS FROZEN** (set once, never decays) + the Vial charges **linearly** with a
   tighter sweet band: a one-poison PRECISION game against a fixed anchor. *(merged "Precise"+"Anchor";
   low-APM, high-control)*
4. **The Purist** — **NO RUPTURE AT ALL**; the sustained reaction is +35%. Pure DoT, zero burst;
   Rupture boons go dead (the trade). *(all-sustain identity)*

~~**The Reckless Brewer** — no saturation, double decay~~ — **CUT 2026-07-06:** its whole upside was
"no saturation," which is now the default for everyone. A frantic high-APM creed slot is open if a
new hook is wanted (e.g. doubled decay + a raw-DoT or overflow reward — not saturation). 4 creeds is
fine (asymmetric class content is explicitly allowed, see §5 CLASS DESIGN RULES).

**⚖ Creed-aware offers are LAW (audit 2026-07-06):** Purist never sees Rupture cards; Anchorite filters
what it muffles. *(The old "Still never offered to Reckless Brewer" clause is dead — both cards cut.)*
**Extended to MODULES + the RIG BOARD (pre-build verdict 6):** Purist never sees Fermentation / the
Reaction-Vessel, and its rig board hides Ripe / Perfect Wave / Overfill. Mechanism: `hide_creeds` tags
+ one `Draft._ok()` check — byte-identical for untagged classes.

## 3. MODULES (a new UI gauge + dynamic; pick 1 at Floor 1) 🔒

1. **The Third Reagent** — a slow-charging catalyst bar up top; **tap to drop it in** → amplifies the
   reaction for a while. Dropping it on the reaction's beat = small bonus (nice, never required).
2. **Fermentation** — a meter fills from sustained reaction; at full, a huge **FERMENT** detonation.
   Deliberately the **calm/chill** module (the class is busy — this is the low-intensity pick).
3. ⭐ **THE REACTION-VESSEL (LOCKED 2026-07-06 — pre-build verdict 1; replaces the cut Still).** The
   radical change-up: the reaction deals NOTHING and BANKS into a vessel gauge; Rupture DUMPS the
   whole vessel at the potency multiplier. Sustain/burst inverted — a pure charge-and-release cannon;
   stall or die with a full vessel and the damage was never dealt. Purist-filtered (creed-aware
   modules). *(Rejected candidates: Twin-Still — doubles the minigame against F2; Catalyst-forge —
   overlaps Chain Rupture/Catalyst, dead under Purist.)*
4. ~~**The Opening** — CROSS-SPEC (shared with Tempo)~~ — **DEAD as written (split + audit F1):** the
   Opening is now Twinfang's baseline class verb, not a shareable module. Whether this class gets its
   own Opening-window interaction is open (see the F1 reconcile note up top). A replacement 4th module
   is owed when the roster firms up.

CUT at triage: Contagion (no adds/multi-target yet), Corrosion (debuff-track later), Twin Coil, Reflux Coil.

## 4. BOONS (roll Haiku/Sonnet/Opus per offer; grouped by the brew part they touch) 🔒

**Rarity law:** EVERY card rolls per offer — numeric boons scale the number; rule-changers scale via
**authored rune/word variations per tier**. No fixed-rarity cards.

- **FUEL:** Deep Cauldron (caps + usable ceiling up) · Preservative (both decay slower) ·
  Clinging Rot (Rot barely decays — the anchor identity)
- **VIAL:** Steady Pour (wider sweet band) · Practiced Hand (slower charge = easier catch; a sidegrade)
  — **⚠ audit F20:** the pool is thin, but grow it with NON-minigame axes, not more band/charge dials.
- **BALANCE:** *deliberately EMPTY of easing boons* — Bill cut Emulsion/Equilibrium/Catalytic Bond to
  protect the core min()-balance skill. Balance is REWARDED, never eased (see Perfect Emulsion below).
- **POTENCY:** Quick Study (fills faster) · Distilled Focus (drains slower on a slip) ·
  Concentrate (ceiling up) · **KILLING DRAUGHT** [I9, accepted: below execute threshold Potency stops
  draining — locked at peak for the kill]
- **REACTION / RUPTURE** *(split into reaction-DoT vs Rupture-burst buckets per the F7 fix)*:
  Corrosive Blood (reaction +%) · Rupturing (burst +%) · Chain Rupture (Rupture keeps +30pp MORE of the brew, ≈0.65 total —
  the base already keeps 35%, stale "keeps 30%" fixed pre-build verdict 7; the F4 wave-shaper) · Volatile Reaction (+% while potency >66%) · **Perfect Emulsion** (near-perfect
  balance → reaction +% — the reward-not-ease Balance play) · **Catalyst** [rule-changer: Rupture
  detonates a phantom copy, brew intact; runes scale how much stays — **audit F18: the phantom is a
  value SNAPSHOT, not a free full Rupture; or exclusive with Chain Rupture at high tiers**] ·
  **Debilitator** [SUPPORT: the reaction weakens the boss for the whole raid — the class's raid-utility
  identity] · **DEEPENING ROT** [I5, accepted: fed-and-balanced reaction ramps Rot's tick; resets on
  stall/spoil] · **LAST CALL** [I4, REFRAMED pre-build verdict 5: on a boss PHASE TRANSITION the brew
  auto-cashes at full value, small seed left — no cleanse/wipe mechanic exists in the engine and none
  is added; boss-side changes belong to the Seal pillar pass]
- **SPELLS (new buttons):** Spitfire (instant off-brew dart — filler between pours) ·
  Decant (pour the fuller poison into the emptier — snap-to-balance recovery, cooldown-gated) ·
  **REDUCTION** [I6, accepted: CD-gated — boil VOLUME into POTENCY; sacrifice sustain for spike]

CUT at triage: Sealed Flask, Deep Draught, Emulsion, Equilibrium, Catalytic Bond, Twin Venom.

## 5. Framework laws this obeys (shared chassis — see MASTER-PLAN CLASS DESIGN RULES)

- Creed = run-long POSTURE (1-of-3, creed-aware offers) · Module = new UI gauge + dynamic (1 at Floor 1)
  · Boon = incremental, categoried by what it touches · the COMBO RIG (one WHEN→THEN per run) is the
  shared cross-class system — **this class's rig vocabulary is LOCKED (pre-build verdict 2 settles
  F13/I3): Sweet Pour / Hot Pour / Emulsion / Ripe / Boil / Perfect Wave → Splash / Backwash /
  Quicken / Residue / Fume / Overfill.**
- Cross-class content = **curios only** (fortune + off-verb; never touch the signature mechanic).
- Every class gets exactly one ⭐ transformer module (**ours: THE REACTION-VESSEL — locked
  2026-07-06 pre-build verdict 1, see §3 slot 3**).
- Every class ships one SUPPORT boon (ours: Debilitator; Tempo's debt is paid by BATTLE HYMN — accepted
  audit I2, see `TEMPO-PLAN.md`).
- **AI-pilotable or it doesn't ship (rule #3):** a seeded policy must brew at 3 skill tiers with a real
  gradient before this class ships — the hold-release minigame needs a policy answer, same bar as Tempo.
- RAID-ONLY game; combat serious, wrapper silly; deterministic engine; thumb-playable.

## 6. Build order (steps 1–2 DONE 2026-07-06 — Bill's order inverted step 0 into "settle by playtest")

0. ~~Settle the 🟡 opens above with Bill first~~ → **now settled BY LIVE PLAYTEST of the base build**
   — F2 (active patience: the base ships the artifact's exact pacing), F3 (auto-evasion: base ships
   the STANDARD dodge — a held charge survives a dodge, footwork is manual), the rig vocabulary
   (F13/I3: still owed before the boon slice). Name/art stay filler.
1. ✅ **Brew core** (`data/alchemist/`) — Vial charge/pour, two asymmetric poisons, Reaction
   (min × balance), Potency, Rupture. `ClassKit` hooks + `seat.vars`, zero rng, guarded — default
   comp byte-identical (twinfang_sim 150 seeds + raid_sim 4×100 seeds CSV-diffed vs main).
   `alchemist_sim` (crucible/leech harness) in `psim.sh`; `raid_sim --caster=alchemist`.
2. ✅ **The Brew HUD** — THE ALEMBIC on `raid_hud` (hold-zones + tap-Rupture chamber + see-saw +
   Potency; pointer + keyboard). `ui_smoke_raid` covers the brew drive, gate exam and juice;
   `screenshot_alchemist_raid` is the WSLg visual probe.
3. ✅ **THE CARD BUILD — DONE 2026-07-06 (`alch-cards`, slices a–f), slate per the ⚖ PRE-BUILD VERDICTS.**
   Each layer landed guarded (byte-identical base), sim-A/B'd, and policy-taught (rule #3):
   a. ✅ **Framework generalization + Creeds (4)** — `_fw()` provider + `_fw_creed/module/rig*`
      dispatch replaced the Twinfang-only `_blade_tempo_human()` gate across `_show_creed_pick` /
      `_show_module_pick` / `_show_rig_wire` / `_inject_boons` / build-panel / rig-fire pop; the
      Alchemist caster now swears a Creed. Creeds: Steady Hand (potency-CAPPED) / Volatile Mix
      (glass) / Anchorite (frozen Rot + linear vial) / Purist (no Rupture, steep potency curve).
   b. ✅ **Modules** — Third Reagent (catalyst bar, key 4) · Fermentation (auto-detonate) · ⭐
      Reaction-Vessel (reaction banks → Rupture dumps). Compact ALEMBIC gauge + creed-aware offer
      (Purist hides the two burst modules).
   c. ✅ **Rig** — the locked 6×6 slate (verdict 2). Fire-points off the brew's own beats; fuel
      applies raw-fractional; Purist board hides burst WHENs + Overfill.
   d/e. ✅ **Boons (18)** — numeric bread + rule-changers: Chain Rupture (+30pp, verdict 7) · Catalyst
      (F18 phantom snapshot) · Last Call (verdict-5 phase-transition auto-cash) · Deepening Rot ·
      Killing Draught · Perfect Emulsion · Volatile Reaction · **Debilitator** (SUPPORT — raid-wide
      `boss.debilitate` debuff, sunder-precedent engine touch, byte-neutral). Fixed rarities (verdict
      3); rupture cards tagged `hide_creeds`.
   f. ✅ **Spells (3)** — Spitfire (filler + designated interrupt carrier, verdict 4) · Decant
      (snap-balance) · Reduction (I6 volume→power). Keys 5/6/7; drafted via the SHARED pool.
   **Still owed (post-playtest):** the 2nd spec · a real class puppet (art = voidcaller filler) ·
   Commander AI-caster toggle · ONLINE spec-carry of creed/module/rig (offline map+gate paths carry
   them now via `_inject_boons`; RaidNet spec doesn't yet — a shared follow-up with Twinfang) ·
   name/art decision. **Card balance = Bill's playtest dial** (first-cut bands in `alchemist_sim`).

---

## 7. THE CASK — the second spec 🟢 (design LOCKED FOR BUILD 2026-07-07 — the Opus build spec)

**Status:** verb feel-tested through **5 live iterations with Bill** (browser tester, artifact
`72390dbd…`; card board `374af4b3…`) + **full slate verdicted 2026-07-07: 24 KEEP / 6 CUT / 0 open.**
This section is the build handoff — everything below is decided; numbers are first-cut tunables
(all on `AlchemistConfig` as `cask_*`, zero literals). Working name **THE CASK** (name/art filler,
same rule as the class).

**Fantasy & polarity (the Fermata move, applied here):** the base Brew is the TWITCH brewer —
continuous decay, live upkeep. The Cask is the RECIPE brewer — discrete batches, planned pour
sequences, one big timed payoff. Same class soul (two poisons, vial greed, sweet-band pours);
the twist is the TIME GRAIN: continuous → batch. Shape = **HARD SPRINT (the stack) → SHORT
EXHALE (the cook) → the PEAK TAP** — the F4 wave at spec scale. Dead ends already playtested
OFF by Bill, do not resurrect: 10s idle cooks (v1) · pure-random band jumps (v2) ·
miss-only-drags-quality (v3) · full strain reset on swap (v4).

### 7.1 THE VERB (base kit — tester-verified numbers)
- **THE STACK:** pour 3–6 doses into the cask, either poison, any order. Each pour = the Brew's
  hold-release vial (charge accelerates: `dc = dt/1.2s × (0.42+1.9c)`), released into **THE BAND** —
  a moving target zone (width 0.16, roams 0.38–0.88, starts 0.62).
- **GRADED POURS (Bill's order, folded from the Master's-Measure verdict note):** BULLSEYE = inner
  30% of the band, dose quality ×1.25 · PERFECT = the band, ×1.0 · GOOD = up to 1.8× half-width
  outside, ×0.65 · beyond = **MISS**. Red line at 0.97 = spoil = MISS. Release under 0.20 charge =
  harmless fizzle-bail (the escape hatch — deliberately kept).
- **A MISS DUMPS THE BATCH** ("RUINED"): every stacked dose lost, proof −2, strain + band reset.
  This is the spec's stake — the deeper the stack, the scarier each release.
- **SIDE EFFECTS (the recipe):** **VENOM = HEAT** — each dose +20% burst; the band CLIMBS
  (+0.11–0.17) toward the red line. **ROT = TIME** — each dose +0.2s peak window + a damage TAIL;
  the band SINKS the same amount. Directional, plannable — VVRRV is a plotted path. (Bill note:
  the walk is TEXTURE, "just not to be too static" — keep steps modest, hang no more cards on it.)
- **STRAIN:** each consecutive same-side landed pour shrinks that side's band ×0.82 AND speeds its
  fill +15%; pouring the other side relieves the first by **2** (not a full reset — v5 lock). Seal
  or dump clears all strain. Makes "burst burst burst, dot, burst" (Bill's line) the emergent play.
- **THE FINISH:** the last dose stamps the batch — Venom finish ×1.25 burst · Rot finish ×2 tail.
- **SEAL:** tap the cask at 3+ doses (auto at 6). Quality q = avg pour grade; volume = sum of doses.
- **THE COOK:** ~5s hands-off to PEAK; peak window = ±(0.4 + 0.2×rotCount)s, clamp ≤0.6×cook. Ripe
  chime + halo at window start. Past the window it SOURS: value ×0.5^(dt/2.5s); under 0.25 for ~1s →
  WASTED (dump penalties, no damage).
- **THE TAP:** burst = `cask_base × vol × q × heat × finish × ageFactor × deadCenter × proofMult`
  (`dmg_scale` raid dial applies, same as the Brew). DEAD CENTER (inner 30% of the window) ×1.12.
  Tail (if rot in the recipe) = burst × 0.12 × rotCount over rotCount seconds, ticking every 0.5s.
- **PROOF (the earned-power bar, this spec's Potency):** 0–6 pips, +12%/pip on everything. Peak tap
  +1 · early/sour tap −2 · dump −2. **Proof is earned at the TAP only** — the Proof-of-the-Malt
  boon (proof from pours) was CUT to keep the bar honest.
- **Controls = the Brew's exact surface** (zero new input verbs): hold 1/2 = charge V/R, release =
  pour, 3/R tap = seal / peak-tap / rack. Multi-cask target priority: rack-active → ripest cooking →
  fullest filling.

### 7.2 CREEDS (spec pool, pick 1 — all KEEP)
- **THE SOLERA** [EASE] — casks never sour, the peak HOLDS. Cost: max 4 doses, proof cap 4.
- **THE OVERPROOFER** [GREED] — cook ×0.5, peak window ×0.6, peak-tap damage +30% (Bill asked:
  "taps +30%" = the payoff hit); a dump also crashes proof to 0.
- **THE SINGLE MALT** [STRAT] — strain shrink softened to ×0.91 but swaps relieve NOTHING.
  The one-poison chain purist; kills the weave, enables the all-V gauntlet.

### 7.3 MODULES (Floor-1 pick — all KEEP)
- ⭐ **THE BLEND** [RULE — the spec's transformer] — casks aren't tapped; each sealed cask pours
  into ONE master blend compounding +12%/clean batch. Tap the blend whenever — a DUMPED batch
  TAINTS it (halves it). The whole fight = one rolling hold-or-cash.
- **THE CELLAR** [STRAT] — peak-tapped casks can be BOTTLED (shelf of 2) instead of drunk; throw
  bottles on demand — bank burst for Openings / phase transitions.
- **THE COPPER STILL** [GREED] — repeatable RACK stir-beats mid-cook: each hit +quality but +1.2s
  cook and faster sour after peak. Push-your-luck; the opt-in active cook.

### 7.4 BOONS (address rule; type tags = Bill's cross-class taxonomy; ladders H/S/O on paper,
fixed rarity in code this slice — Tempo/Brew parity)
- **POUR:** Master's Measure [POWER] — Perfect+ pours pour +10/15/22% volume (rides the graded
  system) · Heavy Hand [POWER] — max doses +1 / +1 & bigger / +2.
- **STRAIN:** Iron Wrist [EASE] — shrink ×0.86/0.88/0.90 · Momentum Pour [GREED] — +6/9/13% volume
  per strain level on that dose (Bill: "trade window size for dmg — stacks with the perfect/good
  system") · Clean Break [STRAT] — first pour after a swap +20/30/45% volume (the anti-Single-Malt).
- **COOK:** Slow Proof [GREED] — cook +25%, tap +30/40/55% · Cooper's Ear [EASE] — window
  +0.3/0.45/0.6s · Breathe [EASE] — cook −0.8/1.2/1.6s.
- **TAP:** Overproof [STRAT] — late taps BURN instead of souring: 60/70/80% + burn DoT ·
  Long Echo [POWER] — tails +40/60/90% · The Finisher [POWER] — V ×1.4/1.5/1.65 · R tail
  ×2.5/3/3.5 · Killing Vintage [STRAT] — below 20/25/33% boss HP casks never sour ·
  **A Round for the House [TEAM — the spec's SUPPORT]** — peak taps buff party damage
  +3/4.5/6% for 4s (application rides the Battle-Hymn/Debilitator raid-channel precedent).
- **CUT (Bill 2026-07-07, do not resurrect without cause):** Practiced Tilt ("the jump doesn't
  really do much") · Bail Money · Proof of the Malt (proof stays tap-earned) · **Angel's Share —
  the cook stays SILENT, no leak DoT; the wait is pure anticipation** · Decant (no live bars —
  spec-hidden) · Reduction-reread (spec-hidden). **Spell carries: SPITFIRE ONLY** (unchanged;
  still the designated interrupt carrier). Spec-hide mechanism = the `hide_creeds` idiom extended
  to a spec tag in `Draft._ok()` — byte-identical for everyone else.
- **Parked candidate (unjudged):** Double Barrel — a second cask slot (tester toggle existed;
  never boarded). Offer to Bill at balance pass.

### 7.5 RIG (new WHENs → the existing class THEN table, mult ≈ inverse-freq × premium)
WHEN I land a strain-×3 pour (~2.2) · WHEN I seal a 6-dose cask (~3.5) · WHEN I tap dead-center
(~5). THENs unchanged (Splash/Backwash/Quicken/Residue/Fume/Overfill; fuel THENs read raw-fractional).

### 7.6 KEYSTONE (A8 — elite drop, never in normal drafts; acquisition = the shared Topology
elite-node dependency, same as Tempo's)
**THE CENTURY CASK** [RULE] — the dose cap is GONE; each dose past 6 adds +8% to everything, but
past 6 strain never relieves. The one-monstrous-cask build (Single Malt + Heavy Hand synergy).

### 7.7 BUILD ORDER (the Opus slices — each guarded, byte-identical unless picked, sim'd, then next)
1. ✅ **Verb base — BUILT & VERIFIED 2026-07-07 (`cask-spec`).** aspect `cask` guarded on the
   alchemist kit via `_cask()` (the Fermata idiom — `upkeep`/`on_action`/`observe` branch at the
   top; every Brew eval still tests `brew`, so no checksum moves). All §7.1 numbers are `cask_*`
   `@export`s on `AlchemistConfig`. Full reducer in `alchemist_kit.gd` (`_cask_*`): the walking
   band, graded pours (Bull/Perfect/Good, MISS→dump), Venom-heat/Rot-time side effects + band
   walk, per-side STRAIN (shrink + fill-speed, swap relief −2), SEAL→COOK→PEAK-tap with the
   age-factor sour curve, PROOF (tap-earned), the Rot tail. First-cut cask `AlchemistPolicy`
   branch (`_act_cask`, latency-scaled) + `alchemist_sim` cask cells (`_cask_ab` + `_prove_cask`,
   `_run_one` threads `aspect`). Minimal HUD selection wired (`ALCHEMIST_ASPECTS`+cask,
   `_sync_caster_cls`, `_launch` alias) so `--autostart=raid:caster:cask` resolves; the ALEMBIC
   renders a mapped observe superset until slice 3. **Gates ALL GREEN:** undrafted-brew Crucible
   seed1 = `4344960863911121821` (byte-identical, 40 & 300 seeds) · raid default comp = main
   `8987010164597652967` (byte-identical A/B) · Cask@good seed13==seed13 PASS, Cask@sloppy
   seed1≠seed2 (determinism 300 seeds) · `ui_smoke_raid` ALL OK. **Verb-health:** expert 100%
   (crucible) / 92% (leech), clean 6-dose seals, all-peak taps (0 early/0 sour), 0 dumps →
   climbing to ~17 dumps/run + collapse at sloppy (the stake bites); pour grades slide
   bull→perfect→good with latency. **⚠ Handoff to slice 2:** the good-tier collapses hard
   (crucible 18.7%, leech 0%) because the first-cut policy reuses the Brew's
   `RELEASE_NOISE_PER_LAT` (0.022, tuned for the 0.28-wide brew band) against the cask's ~0.13
   strained band — halve the cask noise coeff and add the strain-weave/chain temperament + a
   softer tap-lateness model in the real 3-tier policy. Also open for slice 5: `cask_base` (55)
   gives expert crucible TTK 58s vs the Brew's 37s — tune toward Seal-seat parity via `raid_sim
   --caster=alchemist` cells (a cask aspect hook there is owed).
2. **Policy** — 3 skill tiers (rule #3: no policy gradient, no ship): band-read accuracy/jitter,
   strain management (weave vs chain temperament per tier), seal-size strategy, peak-tap timing.
   Expert ≈ brew-comp parity on the Seals; sloppy pays visibly (dumps).
3. **HUD** — THE CASKWORKS instrument on `raid_hud` (reuse the ALEMBIC hold-zones; cask dial +
   recipe beads + strain pips + aging ring — the gauge-vs-cues question ships GAUGE ON, cues too).
   `ui_smoke_raid` drive + a WSLg `screenshot_` probe (headless can't render `_draw`).
4. **Creeds → Modules → Boons/Rig → Keystone** — the alch-cards slice pattern (a–f), spec-aware
   offers via the extended hide tag, fixed rarities, sim A/B per layer, policy taught per layer.
5. **Balance = Bill's playtest dial** (first-cut bands in `alchemist_sim`; `--caster=alchemist`
   raid cells for both specs).
- **Owed / shared follow-ups (not this claim):** online spec-carry (with Twinfang/Brew) · keystone
  acquisition (Topology elite nodes) · Commander AI-caster toggle · name/art · **the UNDER-FIRE
  feel risk (F3): stack-sprinting vs boss swings/dodge beats is UNTESTED — first in-game playtest
  answers it; if the sprint dies under fire, the levers are dodge-holds-charge (already the Brew's
  rule) and/or this spec inheriting the auto-evasion identity candidate.**

---

## 8. BREW REVIEW PASS 2026-07-07 (deck-creator audit vs the Cask) — 🟡 AT BILL'S VERDICT

The built §2–4 slate audited under the deck-creator playbook (born with the Cask, one day after the
Brew shipped). **The live deck STANDS untouched**; this pass produced type tags (POWER/GREED/STRAT/
EASE/RULE/TEAM on all 21 cards), H/S/O **paper ladders** for every card (closes verdict-3's design
debt — engine stays the shared later slice), and **11 proposals** on an interactive board:
https://claude.ai/code/artifact/86ca7f68-c8fe-41eb-a937-1a3fdfde9748

**Audit headlines:** deck temperament 5 EASE vs 3 GREED (FUEL + VIAL lanes have zero greed) ·
**ZERO keystones** (playbook wants 2–3; the Cask has Century Cask) · Fermentation auto-fires =
"a passive wearing UI" anti-pattern · the vial is the only ungraded pour verb left in the game ·
healthy: creed quota met with 4 (forgiving/greed/rhythm/wild-Purist), support + carries + 4 named
archetypes clean.

**The 11 (nothing built until verdicted; all numbers = config knobs):**
- **P1 BULLSEYE POURS** [VERB/RULE] — inner ~30% of the sweet band = ×1.25 dose (Cask-grammar
  back-port; nothing else moves, ceiling-only).
- **P2 Master's Draught** [VIAL/POWER] — bullseye pours +10/15/22% volume (Cask's Master's
  Measure rhyme; needs P1).
- **P3–P5 KEYSTONES (elite-only lane, keep ≥2):** **The Red Line** [GREED] — past-red ignites:
  ×2 dose but slams the see-saw; only the brim spoils · **Quicksilver** [RULE] — every 4th pour is
  silver, feeds BOTH sides at once, can still spoil · **The Seething Vial** [GREED] — a held charge
  hovering in the sweet band VENTS (~35% reaction dmg) while it hovers.
- **P6 Fermentation hold-or-cash** [TWEAK/STRAT] — FERMENT stops auto-firing; gauge locks full and
  your next Rupture drinks it (fill pauses while full). Fixes the zero-decision meter, stays calm.
- **P7 Strike the Seam** [RUPTURE/STRAT] — Rupture in the boss Opening +20/28/38%; settles F1 at
  deck level (needs the Opening window exposed to the caster seat). Purist-hidden.
- **P8 Steady Under Fire** [VIAL/STRAT] — a PERFECT boss answer makes the next pour spoil-proof +
  POTENT (8s). ⚠ F3-contingent (dead if auto-evasion lands) — doubles as a probe on that call.
- **P9 Brimming** [FUEL/GREED] — either poison >9/12: reaction +14/20/28% but that side decays ×2
  (returns the cut saturation's risk as a CHOSEN card).
- **P10 Creed THE FEVER** [GREED, optional 5th] — decay ×2, sweet+ pours SPLASH (~40% of dose) —
  the open frantic-APM slot's named hook.
- **P11 Close the "4th module owed" debt** [DOCS] — quota is 2–3 and we have 3 incl. the ⭐.

**On verdict:** fold KEEPs into §2–4 (hard-copy before build, per the playbook), then build as one
guarded `brew-review` slice — byte-identical undrafted, sim A/B per layer, policy taught (rule #3).
