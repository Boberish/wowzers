# MENDER-PLAN — the direct-cast healer onto Framework v2 (the Well · twin graded specs BRIM / DRAW)

**Status:** 🟢 **VERB PAIR LOCKED via feel-tester 2026-07-07** (Bill: "i like both alot, the draw one
is very nice … can we do both specs with those?" — both tester modes promoted to the spec pair).
Creed/module/deck design = owed; **nothing built in-engine yet**.
**Scope:** rebuilds the **Mender** — the healer seat's direct-cast class — onto Creeds / Modules /
WHEN-THEN. The Bloomweaver is NOT part of this (its framework re-clothing is its own later pass);
the **damage-healer is a 3rd healer-seat class, future**, with its own two specs.
**Artifacts:** design board https://claude.ai/code/artifact/68b0c28c-cc3a-4655-b9d5-fdc67e929e24 ·
**live verb tester** https://claude.ai/code/artifact/80b2169b-3f38-488e-a31c-d9b49a718b25
(BRIM ⇄ DRAW A/B + ⚙ knobs; source `brim-tester.html`, session scratchpad) ·
**⭐ VERDICT BOARD (2026-07-07, out with Bill):** https://claude.ai/code/artifact/958cdbe8-7c92-48cb-bf95-eae69b3994c1
— the FULL idea slate as rateable cards (BRIM tab 25 · DRAW tab 25 · CLASS tab 9: verb base rules,
4 creeds + 3 modules + 10 boons + 4 rig WHENs + 1 keystone per spec, shared Well/support/comp-texture/
names), 1–5 stars + comments, in-browser saves, EXPORT → paste-back. §2–§4 sketches below are
superseded by that slate wherever they differ; Bill's export = the card verdicts of record.
Companions: `TEMPO-PLAN.md` (framework + Fermata precedent) · `ALCHEMIST-PLAN.md` (build idiom) ·
MASTER-PLAN §CLASS FRAMEWORK v2 (the 7 design rules).

Legend: **🔒 LOCKED** (decided with Bill) · **🟡 OPEN** (settle before/at build) · **🔮 FUTURE** (parked).

---

## 0. The diagnosis + the fork (locked 2026-07-06)

- Bill's read, confirmed by code: **heal-low and overheal are boons, not specs.** The two aspects
  differ by ONE inverted Litany condition (`mender_kit.gd:167` — pip when a heal *leaves* the target
  ≥60% vs when it *caught* them ≤40%); everything else is payoff plumbing (Reservoir flywheel /
  brink ×2.5 scaling + Nerve). They demote into the framework (§2, §3).
- **NO MERGE with the Bloomweaver** (Split law F10): cast-bar triage and seed-gardening are
  different games; framework decks are per-spec so a merge saves nothing; the healer seat toggle
  already offers both classes.

## 1. THE CLASS 🔒

**Complexity budget (rule 2, stated):** the Mender sits at the **kit-breadth end** — the ~10-spell
click-cast book IS the class, the per-press minigame stays light, and the depth is triage choice
under pressure. One book, one Well, two specs = **the same grade in two places**.

- **THE WELL (base, both specs):** mana is a visible vessel — casts draw from it, it refills in
  **pulses** (never a flat trickle), overheal **SPILLS** (wasted; banking spill is module
  territory), Meditate is the battery decision, and DRY is a visible state. The Well is the class
  instrument on THE HUD.
- **SPEC 1 · BRIM — grade the LANDING.** Casts stay completely normal; every direct heal is graded
  by where the target's HP lands. In the brim band (default ≥90%) with zero spill = **PERFECT
  POUR** (mana refund + the class proc moment) · overshoot = **SPILL** (counted waste) · land low =
  safe, unpaid. The graded window lives on the **ally's bar**; the skill is sizing Flash vs Mend vs
  Cascade against incoming damage. Landing preview = the ghost segment (🟡 baked-in vs earned).
- **SPEC 2 · DRAW — grade the RELEASE.** Casts complete **manually**: release inside the end band =
  **CLEAN DRAW** (full heal + refund) · early = **UNDERCOOKED** (heal × p^1.5) · overrun =
  auto-completes plain. The window lives on **your cast bar**; spill still costs (economy) but is
  ungraded. Attention inverts — Brim reads the party, Draw reads your own hands. This is the
  Tempo/Fermata symmetry (on the beat vs out of the silence) on the healing side.
- **Shared by both specs:** the book (Flash / Mend / Renew / Ward / Cascade / Wellspring / Dispel /
  Meditate / signature / Rekindle), the Well, the GCD, and **cast-vs-dodge discipline** (a dodge
  cancels the cast; the healer's dodge-ration beats stay its test).
- **VIGIL (the hold) folds into DRAW build territory** 🔮 — a creed/module turns the overrun into a
  HELD state you walk around with and release on the spike. (Was the recommended spec 2; superseded
  by Bill's tester verdict. The good idea survives as Draw's transformer candidate.)

## 2. CREEDS 🟡 (per-spec pools — Tempo/Fermata precedent)

**Brim pool — the demoted aspects, now postures:**
- **FORESIGHT** (was Tidecaller) — play AHEAD: the band rewards topping before the hit; letting an
  ally slip low is the slip.
- **THE BRINK** (was Brinkwarden) — play BEHIND: heals scale on the bloodied (the ×2.5-at-0
  machinery exists), the band moves DOWN (perfect = the low catch), overtopping is the slip.
- Third creed TBD (a well/economy posture — e.g. a smaller Well, stronger pours).

**Draw pool — release temperaments (sketches, design pass owed):**
- **THE PATIENT HAND** — the overrun becomes a HELD heal (the Vigil fold), gutter if held too long.
- **THE QUICK PULL** — tighter band, softened undercooks; the fast crossover creed.
- A slow/heavy precision mirror (Largo/Long-Night idiom: slower casts, smaller band, bigger heals).

## 3. MODULES 🟡 (Floor-1 pick 1-of-3 · one ⭐ transformer · all three re-homed coded machinery)

- ⭐ **THE RESERVOIR** (transformer; was Tidecaller's engine) — spill banks into a second chamber on
  the Well; **SURGE** spends it as shields; shields re-bank a share of what they eat (the flywheel
  in `mender_kit.on_absorb`). Overheal stops being waste and becomes a second currency — the
  overheal build, opt-in.
- **TRIAGE PROTOCOL** (was Brinkwarden's other half) — bloodied allies build Nerve → **LAST STAND**
  (party heal + DR spend).
- **BENEDICTION** (was Litany) — in-condition heals light pips; the 5th cashes the party bloom.
- 🟡 module pool shared class-wide vs per-spec WHEN wording (the three are condition-flavored and
  read fine under either spec).

## 4. DECK 🔮 (after the base build proves)

- **WHEN dimensions come free per spec:** Brim keys off landings (WHEN I perfect-pour · WHEN I
  catch ≤40% · WHEN I spill); Draw keys off releases (WHEN I clean-draw · WHEN I undercook · WHEN I
  release a held heal). Rig slots the class THEN table like every other class.
- **Support boon sketch — THE SHINING HOUR:** while every ally stands ≥ ~80%, the warband gains
  damage. Topping the team IS the raid buff; no extra button (Battle-Hymn analog, pointed the other
  way because the healer is already support).
- 🟡 rule-5 clutch tool (one CD-gated damage dump?) · 🟡 interrupt carrier (the healer is the 1 or
  the 0 of the 2/1/0 comp texture).

## 5. Framework-law compliance (MASTER-PLAN ⚖ rules)

1 chassis ✓ (ClassKit hooks + `perform()` + universal dodge + creed/module/rig shape) · 2 budget
stated ✓ (§1) · 3 AI-pilotable ✓ — Brim tiers = sizing error, Draw tiers = release-timing jitter
(tick-stamped release action; Fermata is adding press/release plumbing to `perform()` anyway) ·
4 skill moves outcomes — tester separates hands on efficiency/pours; sim bands must reproduce it ·
5 role hard, off-role = clutch-capped · 6 fun bare — the book + one grade must carry a boonless
zone skirmish · 7 n/a.

## 6. ⚙ TESTER BASELINE (the numbers Bill played — his slider drags supersede)

brim band 90% · pour refund 25% · Well 900, pulse +18 / 2.0s · draw band 15% (undercook = ×p^1.5) ·
book: flash 33☽/1.5s/70 · mend 24☽/2.6s/95 · renew 27☽/HoT 72 · cascade 58☽/2.0s/45×3-lowest/8s cd ·
medit +160/25s (tester-shortened; the kit's is 160/55s) · GCD 1.2s · pressure script: melee
8–14/1.4s · buster 90/12s (2.5s tele) · nova 15–25 all/9s (1.8s tele) · hex dot 8×6 ticks/10s.

## 7. Build order (Alchemist idiom — the OLD Mender stays the frozen default until the verdict swap)

1. **Guarded kit base:** the spec pair rides the aspect slot (`--autostart=raid:healer:brim|draw`,
   the `raid:caster:brew` precedent); old tidecaller/brinkwarden stay the default — **byte-identical
   unless picked**. Draw needs the release action on the input surface (share Fermata's
   press/release idiom + AI policy release-jitter).
2. New healer sim (the rework loop) joins `psim.sh`; `raid_sim --healer` cells; determinism PASS
   both specs.
3. Creeds → 4. Modules (re-homes) → 5. deck + rig WHENs →
6. **HUD instrument:** the Well vessel panel + brim rings on the raid frames + the draw band on the
   player cast bar (StrikeJudge compact keeps the boss side) →
7. Balance at `--fightlen` bands (3–5 min mid / ~10 min late) — **never against today's 60–142s
   fights**; this is where the inert-healer finding finally gets closed.

## 8. OPEN verdicts 🟡

1. **Name** — keep MENDER? Spec names: BRIM / DRAW are strong working verbs (alts: WELLSPRING /
   DRAWN LIGHT).
2. **Landing preview** — baked into Brim, or earned (boon/level unlock)? Tester has the toggle.
3. **Interrupt carrier** — 1 or 0.
4. **Clutch damage dump** — yes/no (sustained damage-healing stays with class #3).
5. **Draw creed pool** — needs its real design pass.
6. **Module pool** — shared vs per-spec wording.
7. **Ward in a spill economy** — shields can never spill, making Ward the "safe" cast; does it need
   a brim-adjacent rule (e.g. ward on a full-HP ally = graded pour) or is safe-but-unpaid correct?
