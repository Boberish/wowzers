# ALCHEMIST-PLAN — "The Brew" (the poison CLASS — split out of Twinfang 2026-07-06)

**Status:** DESIGN (core locked 2026-07-05; audited + **PROMOTED TO ITS OWN CLASS by Bill 2026-07-06**,
spec-audit verdict F10) — NOT BUILT. **THE ALCHEMIST is a WORKING NAME — filler** (Bill: "alchemist or
something"; name/art are placeholder-grade until the build claim. Candidates: Venomancer / Plaguewright /
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
  beats (inheriting "every 3rd Perfect" would be incoherent in a charge-pour class). ⚠ The I3 vocabulary
  (Ripe / Emulsion / Saturation / Boil / Distill; its Top-Off THEN pre-cut for easing balance) is NOT
  locked — Bill hasn't decided if/thens for this class yet, and floated that WHENs may be per-class. 🟡
- **F16 · The Still is a Floor-1 trap under two creeds:** module offers go **creed-aware** (never offer
  The Still to Reckless Brewer — no saturation ⇒ the reserve never fills); under Volatile Mix the Still
  catches OVERFLOW but NOT spoils (it must not silently delete the creed's downside).
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
- **F22 · interrupt:** the kick button is being rethought globally — **INTERRUPT-BY-ABILITY**
  (WORLD-PLAN pillar 3): flagged class abilities interrupt as a side effect, less frequent, tighter
  window. Whether this class is a carrier (2/1/0 comp texture) = build-time call.
- **F1 reconcile (the Opening):** F1 was accepted pre-split as "Opening = the CLASS verb for both
  specs." Post-split it resolves as: Opening = **Twinfang's** baseline verb; the §3 "Opening —
  CROSS-SPEC module" row below is **dead as written**. Whether this class keeps an Opening-window
  interaction (Rupture-in-the-window bonus) is an open call — the F3 auto-evasion identity may cover
  the boss-hookup need differently.

---

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
- **Saturation:** each poison has a soft cap — pouring into a full side is mostly wasted ("more isn't better").
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

## 2. CREEDS (run posture, pick 1 of 3 offered from the pool) 🔒

1. **The Steady Hand** — forgiving: wide balance window, gentle potency drain, overflow fizzles (no spoil).
   Lower potency ceiling. *(the learner)*
2. **The Volatile Mix** — +50% potency ceiling & bigger Ruptures; a SPOILED pour or hard tip **crashes
   potency to 0**. *(the glass / greed pick)*
3. **The Reckless Brewer** — **no saturation** (overfill freely, bank bigger) but decay is DOUBLED.
   Pour constantly, never rest. *(high-APM frantic)*
4. **The Anchorite** — **ROT IS FROZEN** (set once, never decays) + the Vial charges **linearly** with a
   tighter sweet band: a one-poison PRECISION game against a fixed anchor. *(merged "Precise"+"Anchor";
   low-APM, high-control)*
5. **The Purist** — **NO RUPTURE AT ALL**; the sustained reaction is +35%. Pure DoT, zero burst;
   Rupture boons go dead (the trade). *(all-sustain identity)*

**⚖ Creed-aware offers are LAW (audit 2026-07-06):** Purist never sees Rupture cards; Anchorite filters
what it muffles; The Still is never offered to Reckless Brewer (§3).

## 3. MODULES (a new UI gauge + dynamic; pick 1 at Floor 1) 🔒

1. **The Third Reagent** — a slow-charging catalyst bar up top; **tap to drop it in** → amplifies the
   reaction for a while. Dropping it on the reaction's beat = small bonus (nice, never required).
2. **Fermentation** — a meter fills from sustained reaction; at full, a huge **FERMENT** detonation.
   Deliberately the **calm/chill** module (the class is busy — this is the low-intensity pick).
3. **The Still ⭐** — the per-class **TRANSFORMER** (design law: every class gets one radical change-up
   module): overfill/waste **distills into a reserve tank** you tap to auto-pour — flips saturation
   from "waste" into a banking game. **Audit F16 (accepted):** never offered under Reckless Brewer;
   under Volatile Mix it catches overflow but NOT spoils.
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
  Corrosive Blood (reaction +%) · Rupturing (burst +%) · Chain Rupture (Rupture keeps 30% of the brew —
  the F4 wave-shaper) · Volatile Reaction (+% while potency >66%) · **Perfect Emulsion** (near-perfect
  balance → reaction +% — the reward-not-ease Balance play) · **Catalyst** [rule-changer: Rupture
  detonates a phantom copy, brew intact; runes scale how much stays — **audit F18: the phantom is a
  value SNAPSHOT, not a free full Rupture; or exclusive with Chain Rupture at high tiers**] ·
  **Debilitator** [SUPPORT: the reaction weakens the boss for the whole raid — the class's raid-utility
  identity] · **DEEPENING ROT** [I5, accepted: fed-and-balanced reaction ramps Rot's tick; resets on
  stall/spoil] · **LAST CALL** [I4, accepted: boss cleanse/phase-change auto-Ruptures for full value
  first]
- **SPELLS (new buttons):** Spitfire (instant off-brew dart — filler between pours) ·
  Decant (pour the fuller poison into the emptier — snap-to-balance recovery, cooldown-gated) ·
  **REDUCTION** [I6, accepted: CD-gated — boil VOLUME into POTENCY; sacrifice sustain for spike]

CUT at triage: Sealed Flask, Deep Draught, Emulsion, Equilibrium, Catalytic Bond, Twin Venom.

## 5. Framework laws this obeys (shared chassis — see MASTER-PLAN CLASS DESIGN RULES)

- Creed = run-long POSTURE (1-of-3, creed-aware offers) · Module = new UI gauge + dynamic (1 at Floor 1)
  · Boon = incremental, categoried by what it touches · the COMBO RIG (one WHEN→THEN per run) is the
  shared cross-class system — **this class's rig vocabulary is OWED (audit F13; I3's menu unlocked 🟡)**.
- Cross-class content = **curios only** (fortune + off-verb; never touch the signature mechanic).
- Every class gets exactly one ⭐ transformer module (ours: The Still).
- Every class ships one SUPPORT boon (ours: Debilitator; Tempo's debt is paid by BATTLE HYMN — accepted
  audit I2, see `TEMPO-PLAN.md`).
- **AI-pilotable or it doesn't ship (rule #3):** a seeded policy must brew at 3 skill tiers with a real
  gradient before this class ships — the hold-release minigame needs a policy answer, same bar as Tempo.
- RAID-ONLY game; combat serious, wrapper silly; deterministic engine; thumb-playable.

## 6. Build order (when claimed — mirrors the Tempo pilot; AFTER the pilot proves the framework)

0. **Settle the 🟡 opens above with Bill first** — F2 (active patience), F3 (auto-evasion), the rig
   vocabulary (F13/I3). Name/art stay filler until here.
1. **Brew core** as a NEW CLASS KIT + headless sim: Vial charge/pour, two asymmetric poisons, Reaction
   (min × balance), Potency, Rupture + the F4 wave. Seat model as usual (`ClassKit` hooks + `seat.vars`,
   guarded no-ops for everyone else). Determinism + bands vs the Seals in `raid_sim` (a new DPS-seat
   class option) + its own solo sim harness added to `psim.sh`.
2. **The Brew HUD** on `raid_hud` (hold-zones + Rupture + see-saw + Potency bar; thumb-first).
3. Creeds → Modules → rig content → boons, verified per layer (the Tempo slice pattern).
