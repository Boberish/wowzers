# ALCHEMIST-PLAN — "The Brew" (the poison CLASS — split out of Twinfang 2026-07-06)

**Status:** 🟢 **BASE MINIGAME BUILT & PLAYABLE 2026-07-06** (`alchemist-core` — Bill's direct order:
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
Spitfire/Decant/Reduction · second spec · a class puppet (art = voidcaller rig filler).
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
  beats (inheriting "every 3rd Perfect" would be incoherent in a charge-pour class). ⚠ The I3 vocabulary
  (Ripe / Emulsion / ~~Saturation~~ / Boil / ~~Distill~~; its Top-Off THEN pre-cut for easing balance) is
  NOT locked — Bill hasn't decided if/thens yet, floated per-class WHENs, and Saturation/Distill are
  now moot (mechanic cut 2026-07-06). 🟡
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
- ~~**Saturation:** each poison has a soft cap — pouring into a full side is mostly wasted.~~
  **CUT 2026-07-06 (Bill playtested it off — "better off").** It was flag-gated, A/B'd (the sim
  showed it barely bound — ±5pp win, same TTK/potency; a disciplined brewer never over-pours), then
  removed entirely. The HARD cap (12) is the only ceiling now; full pours always land. **⚠ knock-on:
  the two cards defined BY saturation are cut with it — the Reckless Brewer creed (§2) and the ⭐
  Still module (§3) — so the class now OWES a replacement ⭐ transformer** (design law: every class
  gets exactly one). The reaction's `min(V,R) × balance` skill is untouched — keeping the bars EVEN
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

## 3. MODULES (a new UI gauge + dynamic; pick 1 at Floor 1) 🔒

1. **The Third Reagent** — a slow-charging catalyst bar up top; **tap to drop it in** → amplifies the
   reaction for a while. Dropping it on the reaction's beat = small bonus (nice, never required).
2. **Fermentation** — a meter fills from sustained reaction; at full, a huge **FERMENT** detonation.
   Deliberately the **calm/chill** module (the class is busy — this is the low-intensity pick).
3. ⚠ **THE ⭐ TRANSFORMER SLOT IS OPEN (owed 2026-07-06).** ~~The Still — overfill/waste distills into
   a reserve tank~~ was the ⭐ transformer, but it was built ON saturation (distilling the waste); with
   saturation cut, it's gone. **Design law still stands: every class gets exactly one ⭐ radical
   change-up module — this class now owes a new one.** Candidates to explore (Bill's call): a
   Reaction-Vessel that INVERTS the loop (sustain-vs-burst flipped), a Twin-Still that runs two
   reactions, or a Catalyst-forge that turns Ruptures into a stacking engine. NOT saturation-based.
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
- Every class gets exactly one ⭐ transformer module (**ours is OWED — The Still was cut with
  saturation 2026-07-06; §3 slot 3 lists candidates**).
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
3. **NEXT (post-playtest):** fold Bill's feel verdicts into the §1 dials → Creeds → Modules → rig
   content → boons, verified per layer (the Tempo slice pattern). Also owed: the interrupt-carrier
   call (F22), a real class puppet, Commander AI-caster toggle exposure, name/art decision.
