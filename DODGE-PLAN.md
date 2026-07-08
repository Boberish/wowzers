# DODGE-PLAN — collapse the two dodge verbs into ONE (remove the F dodge)

**Status:** 🔴 DESIGN — ready to execute. Written 2026-07-08 (Bill's call). *Another agent executes this;
the mobile-spike session continues in parallel.* Work in a worktree; add a MASTER-PLAN Coordination Log
claim before starting.

## The decision (Bill, 2026-07-08)

There must be **ONE dodge — the spacebar dodge — and it answers everything.** The separate universal
dodge on **F is removed from the game entirely.** If a boss throws a **barrage** (a multi-beat string),
you dodge each beat with the *same* one dodge. Bill's own diagnosis of the hard part: the barrage was
built for **fast successive** dodges, so a single dodge on the current big-swing cooldown (2.4s) can't
keep up — **so the cooldown must be fixed** to let one dodge chain a barrage ("lower dodge cooldown to
work with the current system — seems best; or spread the beats out"). This plan does the removal + the
cd fix, across **all classes**.

## What exists today (the two verbs — this is the mess to fix)

The engine has **two** input verbs (`CombatCore.perform`, `godot/core/combat_core.gd:78-110`):

| Verb (type) | Key | What it answers | CD model | Per-class hooks it fires |
|---|---|---|---|---|
| `"defense"` | **SPACE** | **one** big DEFENSIBLE swing aimed at you — instant negate (`combat_core.gd:80-100`) | `defense_cd` **2.4s** (`_def_cd`→`kit.defense_cd()`), `defense_active` ~0.55s | `on_defense_press`, `on_negate` |
| `"dodge"` | **F** | the **barrage STRING beats** — graded via `_answer_strike` (`combat_core.gd:101-110`, `:441`) | `dodge_recovery` **0.35s** on a hit + `dodge_whiff_cd` **1.3s** on a wasted/feinted press | `on_dodge_press`, then `on_strike_result` |

**The drift Bill sensed is real and systemic:**
- `"defense"` is NOT uniformly "dodge" — it's *each class's own defensive verb*: Twinfang = dodge-negate,
  **Bulwark = PARRY** (riposte/counter, `bulwark_kit.gd:103,147`), **Voidcaller = kick-aim**
  (`voidcaller_policy.gd:65-67`). `"dodge"` (F) is the *shared* barrage-beat answer every seat has.
- The on-screen **"DODGE" button is wired inconsistently**: it sends `"defense"` for Twinfang
  (`raid_hud.gd:2445`) but `"dodge"` for **Reckoner** (`raid_hud.gd:2471`).
- **Healers have no real `defense`** — their ONLY dodge is `"dodge"`/F, which cancels their cast
  (the discipline test: `well_kit.gd:634`, `mender_kit.gd:92`, `bloomweaver_kit.gd:139`) *and* answers beats.
- **Fermata** relies on `on_dodge_press` too: a dodge input mid-coil **breaks the coil** (`twinfang_kit.gd:813-820`).
- The fast-recovery(0.35s)+whiff(1.3s) model on `"dodge"` is exactly the anti-spam that lets barrages
  chain (fast when you answer real beats, punished when you mash). **Keep this model** as the one dodge cd.

## The design — merge, don't just delete

**Collapse to ONE verb, bound to SPACE, that fires ALL the hooks and answers both shapes.** The boss
scheduler resolves **one telegraph per tick** (CLAUDE.md), so at any instant there is a single live
telegraph — either a defensible swing OR a barrage string — no double-fire ambiguity.

The single dodge press (recommend canonical action type `"dodge"`; the executor may keep `"defense"` —
either is fine as long as the merged branch fires every hook below, in this order):
1. `kit.on_dodge_press(...)` — healer cast-cancel · Fermata coil-break.
2. If the live telegraph is a **single DEFENSIBLE swing** aimed at you and in-window → **negate** it +
   `kit.on_negate(...)` (Bulwark riposte/counter, Twinfang dodgeCp/tfTrigEvade). *(the `combat_core.gd:92-100` block)*
3. Else if the live telegraph is a **barrage string** with an answerable beat → `_answer_strike(...)` →
   `kit.on_strike_result(...)` (Twinfang +Flow, the beat-dodge boons). *(the `combat_core.gd:110`/`:441` path)*
4. `kit.on_defense_press(...)` — Twin Step spare-charge recharge.
5. Apply the **cd**: `dodge_recovery` (0.35s) after a successful negate/answer; `dodge_whiff_cd` (1.3s)
   after a press that answered nothing or ate a feint. **Retire the 2.4s `defense_cd` gate.**

Then **delete**: the separate `"dodge"` perform branch (fold into the one branch), the **F key binding**
(`raid_hud.gd:_martial_key`/`_fermata_key` `KEY_F`), the duplicate ready-tick var (unify
`dodge_ready_tick`/`defense_ready_tick` → one), and the second DODGE rune. One rune, one key (SPC), one action.

### The cooldown fix (the crux) — recommendation + fallback

- **Recommended (do first):** the unified dodge uses the barrage model — **0.35s recovery on a hit, 1.3s
  whiff-lockout on a wasted press** — for *both* single-swing negates and beat answers. This is Bill's
  "lower the cd" and it lets one dodge chain a barrage immediately.
- **Balance risk to verify:** a single-swing negate at 0.35s recovery is far freer than at 2.4s. The whiff
  lockout is the anti-spam (you can't pre-mash — a press with nothing answerable eats 1.3s), and big swings
  are boss-cd-spaced anyway. **Sim-verify** it doesn't trivialize the negate (twinfang_sim, raid_sim bands).
- **Fallback if sims say negate is too free:** give a *successful single-swing negate* a longer recovery
  (~1.0s) while *beat answers* keep 0.35s — fast for barrage chains, a real commit for big swings. One knob.
- Bill's alt ("spread the beats out") is a *content* lever (widen barrage `StrikeRes.at` spacing) — keep it
  in reserve; prefer the cd fix so existing barrages don't all need re-authoring.

## Per-class handling (check every one — Bill's explicit ask)

| Class | `defense`/SPACE today | `dodge`/F today | After unify (the one dodge) |
|---|---|---|---|
| **Twinfang** (blade) | dodge-negate (+Twin Step, dodgeCp) | beat-answer (+Flow/energy, tfTrigBeat) · **Fermata coil-break** | one dodge: negate OR beat-answer; preserves Flow + coil-break |
| **Reckoner** (blade) | negate (`on_negate`) | beat-answer; its DODGE rune already sends `"dodge"` | one dodge; drop the F rune |
| **Bulwark** (tank) | **PARRY** (riposte/counter/reflect) | beat-answer (trigBeat, sureFoot) | one verb does parry-negate + beat-answer. **⚠ OPEN:** should the tank keep parry and dodge as *two* things (densest footwork, pillar 2)? — Bill decides (see below) |
| **Alchemist** (caster) | negate | beat-answer | one dodge (its F3 auto-evasion idea stays separate/unbuilt) |
| **Voidcaller** (caster, CUT/frozen) | **kick-aim** (its `defense` IS the interrupt) | beat-answer | keep kick as-is; fold beat-answer into the one dodge. Minimal effort (class is cut) |
| **Mender / Well / Bloomweaver** (healers) | none meaningful | **cast-cancel + beat-answer** (their only dodge) | the one dodge = cast-cancel + beat-answer, on SPACE |

## Boons that must keep working (they fire via `on_strike_result` PERFECT — preserved automatically)
Bulwark **Perfect Footwork** (`trigBeat`) + **Sure-Footed** (`sureFoot`) · Bloomweaver **Rootstep**
(`bwTrigBeat`) · Voidcaller **Void Step** (`vcTrigBeat`) · Mender **Graceful Step** (`mdTrigBeat`) ·
Twinfang `tfTrigBeat`/`dancersgrace`. As long as `_answer_strike → on_strike_result` still runs from the
unified dodge, these need **no change**. Bulwark **Retaliation**/**Punish the Lie** ride `on_negate`/feint —
also preserved. Verify each still procs after the merge.

## Files to change
- **`godot/core/combat_core.gd`** — merge the `"defense"`+`"dodge"` branches (`:78-110`) into one; unify the
  cd/ready-tick; keep `_answer_strike` (`:441`). This is the heart of it.
- **`godot/data/tuning_config.gd`** + per-class configs (`twinfang`/`alchemist` `dodge_cd`/`dodge_active`,
  and `defense_cd`/`defense_active`) — reconcile to the one cd model (`dodge_recovery`/`dodge_whiff_cd`).
- **All AI policies** (`godot/sim/policies/*.gd`) — each emits BOTH `{"type":"defense"}` and
  `{"type":"dodge"}` today; collapse to the one action (bulwark/twinfang/alchemist/voidcaller/reckoner/
  mender/well/bloomweaver).
- **`godot/game/raid_hud.gd`** — delete `KEY_F` in `_martial_key`(`:3111`)/`_fermata_key`(`:3128`); make the
  single dodge = SPACE + rune; fix the inconsistent DODGE-rune wiring (`:2445` vs `:2471`) to the one action;
  ensure the dodge CUE (`_render_dial`, `:3466`) flashes for BOTH single-swing telegraphs and barrage beats.
- **Kits** — mostly untouched (hooks preserved); only reconcile the ready-tick var name + Twin-Step/2nd-charge
  logic that rewrote `defense_ready_tick`.
- **Docs** — WORLD-PLAN pillar 2 + CLAUDE.md + MASTER-PLAN "universal dodge" language: reframe so the
  universal dodge IS the one class dodge (not a second verb). HISTORY note (M7 two-verb retired).

## Open questions for Bill (surface before finalizing)
1. **Bulwark tank:** collapse PARRY and DODGE into one input too, or is the tank the one seat that keeps
   *two* footwork verbs on purpose (pillar 2 = densest footwork)? (Recommend: collapse for consistency;
   Bulwark is a frozen placeholder pre-rework anyway, and the new tank design in TANK-PLAN is where its real
   footwork gets decided.)
2. **Negate cd:** ship the flat 0.35s/1.3s model, or pre-emptively give single-swing negates the ~1.0s
   recovery floor? (Recommend: flat first, sim, then floor only if needed.)

## Verification (byte-identical is NOT expected — behavior changes for every class → new baselines)
- **Determinism PASS** for every active sim after the change (twinfang_sim, raid_sim [all 4 Seals],
  alchemist_sim, well_sim, forge_sim).
- **Re-baseline balance bands** — the dodge cadence changes for every class; capture new twinfang_sim +
  raid_sim `--healer=…`/`--caster=…` bands and confirm the skill gradient still holds (expert dodges chain a
  barrage; sloppy eats beats). This is the real gate.
- **Probes/smokes:** the raid/beat probes, `ui_smoke_raid` (retire the F-dodge assertions; add a
  single-dodge-answers-both assertion), `net_smoke` (input protocol still identical checksums — note if the
  action-type rename touches the wire).
- **Each beat-dodge boon** still procs (list above).
- WSLg: the one DODGE rune + cue reads for a single swing AND a barrage.
