# VENOM-PLAN — "The Brew" (the poison spec, clean-slate remake)

**Status:** DESIGN LOCKED (2026-07-05, with Bill) — NOT BUILT. The old poison-wheel Venomancer is dead;
this replaces it entirely. Companion: `TEMPO-PLAN.md` (the other Twinfang aspect — Tempo is the built pilot).
Feel-test artifact (thumb-playable): https://claude.ai/code/artifact/003f6832-5c3b-4d0f-bf28-8ea07534d313
Pile-triage artifact: https://claude.ai/code/artifact/1d0d2ac6-e35d-4021-b50a-2677fc1d31f7

**Identity:** the ANTI-TEMPO. Tempo = fast, twitchy, clean timing for Flow. Venom = patient, deliberate,
balanced *brewing* for Potency. Fewer, weightier decisions. Thumb-first controls (hold-release + taps) —
the whole game should be thumb-playable.

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

**POTENCY (the earned power bar — Venom's Flow):** fills while you sustain a **balanced, fed** reaction;
drains fast when lopsided or dry. **Multiplies EVERYTHING** (reaction + Rupture), ×1 → ×2.6.
One bar = "how well am I brewing," and it IS your power.

**RUPTURE (the trigger):** tap to detonate = **FUEL (balanced volume) × POWER (potency)** — multiplicative,
so the peak is both-high; the button **glows "ripe"** when both are up. Consumes most of the brew.
Situational early cash-out before a boss cleanse/phase.

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

## 3. MODULES (a new UI gauge + dynamic; pick 1 at Floor 1) 🔒

1. **The Third Reagent** — a slow-charging catalyst bar up top; **tap to drop it in** → amplifies the
   reaction for a while. Dropping it on the reaction's beat = small bonus (nice, never required).
2. **Fermentation** — a meter fills from sustained reaction; at full, a huge **FERMENT** detonation.
   Deliberately the **calm/chill** module (the class is busy — this is the low-intensity pick).
3. **The Still ⭐** — the per-class **TRANSFORMER** (design law: every class gets one radical change-up
   module): overfill/waste **distills into a reserve tank** you tap to auto-pour — flips saturation
   from "waste" into a banking game.
4. **The Opening** — **CROSS-SPEC** (shared with Tempo): boss swings open a vulnerability window;
   land RUPTURE inside it for a bonus. The first shared-content proof.

CUT at triage: Contagion (no adds/multi-target yet), Corrosion (debuff-track later), Twin Coil, Reflux Coil.

## 4. BOONS (roll Haiku/Sonnet/Opus per offer; grouped by the brew part they touch) 🔒

**Rarity law:** EVERY card rolls per offer — numeric boons scale the number; rule-changers scale via
**authored rune/word variations per tier**. No fixed-rarity cards.

- **FUEL:** Deep Cauldron (caps + usable ceiling up) · Preservative (both decay slower) ·
  Clinging Rot (Rot barely decays — the anchor identity)
- **VIAL:** Steady Pour (wider sweet band) · Practiced Hand (slower charge = easier catch; a sidegrade)
- **BALANCE:** *deliberately EMPTY of easing boons* — Bill cut Emulsion/Equilibrium/Catalytic Bond to
  protect the core min()-balance skill. Balance is REWARDED, never eased (see Perfect Emulsion below).
- **POTENCY:** Quick Study (fills faster) · Distilled Focus (drains slower on a slip) ·
  Concentrate (ceiling up)
- **REACTION / RUPTURE:** Corrosive Blood (reaction +%) · Rupturing (burst +%) · Chain Rupture (Rupture
  keeps 30% of the brew) · Volatile Reaction (+% while potency >66%) · **Perfect Emulsion** (near-perfect
  balance → reaction +% — the reward-not-ease Balance play) · **Catalyst** [rule-changer: Rupture
  detonates a phantom copy, brew intact; runes scale how much stays] · **Debilitator** [SUPPORT: the
  reaction weakens the boss for the whole raid — Venom's raid-utility identity]
- **SPELLS (new buttons):** Spitfire (instant off-brew dart — filler between pours) ·
  Decant (pour the fuller poison into the emptier — snap-to-balance recovery, cooldown-gated)

CUT at triage: Sealed Flask, Deep Draught, Emulsion, Equilibrium, Catalytic Bond, Twin Venom.

## 5. Framework laws this obeys (shared with Tempo)

- Creed = run-long POSTURE (1-of-3) · Module = new UI gauge + dynamic (1 at Floor 1) · Boon = incremental,
  categoried by what it touches · the COMBO RIG (one WHEN→THEN per run) is the shared cross-class system —
  Venom gets poison-themed WHENs/THENs when built.
- Cross-class content = **curios only** (fortune + off-verb; never touch the signature mechanic).
- Every class gets exactly one ⭐ transformer module.
- Each spec ships one SUPPORT boon (Venom = Debilitator; **⚠ Tempo still owes one**).
- RAID-ONLY game; combat serious, wrapper silly; deterministic engine; thumb-playable.

## 6. Build order (when claimed — mirrors the Tempo pilot)

1. **Brew core** in a new kit + headless sim: Vial charge/pour, two asymmetric poisons, Reaction
   (min × balance), Potency, Rupture. Determinism + bands vs the 3 Seals (`raid_sim --blade=venom...`).
2. **The Brew HUD** on `raid_hud` (hold-zones + Rupture + see-saw + Potency bar; thumb-first).
3. Creeds → Modules → rig content → boons, verified per layer (the Tempo slice pattern).
