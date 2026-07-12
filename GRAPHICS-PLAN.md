# GRAPHICS-PLAN — the AI-owned visual system (Project Rift)

> **Design of record, 2026-07-12.** This plan owns the game's visual direction and production
> pipeline across **characters · animation · environments · combat VFX · HUD/UI art**. It
> supersedes `ART-PLAN.md` v1's Twinfang-only painted-cutout plan. The old plan stays in git as
> decision history; its completed juice slice is a candidate to salvage, not an automatic merge.
>
> `godot/ART-PIPELINE.md` is **not deleted**: it remains the live animation-name/fallback contract
> until Art V2 proves and replaces individual actors. `godot/UI-OVERHAUL.md` remains the current
> functional/readability baseline. This plan owns what the final authored art becomes.

**Status:** 🟡 **PLANNING / AT VISUAL DIRECTION GATE V1.** Architecture and execution order are
captured. No final style, generated asset, or Art-V2 code is approved yet. The dashboard mock-up
from the Codex session is a useful composition reference, **not a locked skin or layout**.

---

## 0. THE NEW ASK + WHAT CHANGED

Bill is a senior full-stack developer with a job and family, not the production animator. The
pipeline must therefore make Bill the **creative director and playtester**, not the person who
cuts limbs, paints weights, keys animation, or maintains an art package.

**The labor contract:**

| Owner | Owns |
|---|---|
| **Codex** | image generation · image-edit iterations · visual anchors · character/scene/UI asset briefs · component/flipbook generation · visual inspection and art-consistency verdicts |
| **Claude** | the majority of non-image engineering: recon · worktrees/rebases · feature flags · view contracts · scene-profile system · rig/adapters · dashboard host · asset-import tooling · screenshot probes · verification · merge/docs bookkeeping |
| **Bill** | short choices between concrete visual options · playtest feel · approve/reject each gate · resolve true taste decisions |

Agents do the production work. Bill should be able to advance a slice with a few minutes of
feedback, not hours in Spine or an image editor.

**Old v1 assumption:** Across-the-Obelisk cel art was locked; Bill generated PNGs; Claude cut and
aligned them; rigid painted limbs on the existing Twinfang code rig were the target; UI and
environments were outside the plan.

**V2 assumption:** the style is deliberately **OPEN** until Bill sees comparison boards. Codex
generates and prepares the art. Claude builds the reusable native pipeline. The target is a
**C/D hybrid**: painted layered characters + selective deformation + replacement drawings at
extreme/contact poses + authored flipbook VFX, inside modular scene kits and a painted dashboard.

---

## 1. THE SIX LAWS

1. **OLD PLAYABLE ALWAYS.** The current code-art stage and HUD remain the default until a new
   slice is visually approved and verified. No half-built actor or dashboard can replace the
   playable path on `main`.
2. **VIEW-ONLY.** Art never enters combat state, checksums, policy observations, `(seed,spec)`, or
   protocol. It reads committed state/events and may interpolate presentation only.
3. **MODULAR SCENES, NOT ONE MOOD.** Characters and HUD cannot be painted into a dark dungeon.
   The same fight must render convincingly in an interior and outdoors before the environment
   system is accepted.
4. **ONE ANCHOR, MANY DERIVATIVES.** Every character/environment/UI family starts from an
   approved anchor image. New parts/poses are edits or constrained derivatives, never unrelated
   one-shot generations.
5. **ART SERVES THE VERB.** Contact poses, silhouettes, FX, and the HUD make timing readable in a
   peripheral glance. Beauty never muddies the answer channel, cast, HP, aggro, or effects.
6. **THIN MERGES.** Code/art lives in an `art-v2` worktree, merges `main` frequently, and returns
   in small reversible slices. Never let a month-long art branch become a parallel game.

---

## 2. THE TARGET VISUAL SYSTEM

### 2.1 Characters — C/D hybrid, native first

Each live actor is assembled from approved painted layers. Rigid pieces stay rigid where that is
the correct material (weapon, plate, buckles); soft regions gain deformation or controlled warp
(cloth, torso twist, scarf, coat tails). Extreme/contact poses may replace a hand, face, weapon,
or whole upper-body drawing for one authored beat. Energy/smoke/slash/impact effects use short
transparent flipbooks plus light procedural particles/shaders.

The existing `Actor2D` verb contract remains the boundary. Art V2 may use the current pose solver,
native `Skeleton2D`/`Polygon2D`, a small purpose-built painted-rig node, or a combination behind a
new adapter; the stage does not learn class-specific art details. Spine remains a specialist door,
not a prerequisite and not work Bill must learn.

**First proof actor:** **THE DUELIST** — because its recent rebuild provides the clearest complete
vocabulary: idle · dodge · parry · dump · En Garde · windup/swing · hit · miss/slump · death ·
victory. The proof includes one deforming garment, one replacement contact drawing, and one
signature flipbook.

### 2.2 SceneKit — many scenes from one contract

An encounter selects a **Scene Profile**. A profile composes independent layers, never a baked
combat screenshot:

1. **Backdrop** — sky/wall/architecture, fills the aspect-expanded canvas.
2. **Distant life** — silhouettes, clouds, machinery, birds, banners, weather.
3. **Midground** — readable architecture/vegetation framing the combatants.
4. **Combat floor** — feet line, contact shadows, floor material, perspective cues.
5. **Encounter dressing** — optional boss/realm props and foreground occluders.
6. **Atmosphere + palette** — fog/embers/rain/dust/god-rays and light/accent parameters.

Scene profiles may change art, palette, light, and ambience but never actor scale/feet contract,
combat geometry, input, or UI truth. They support 16:9 and wider aspects without stretching key
art; sides grow through repeatable/extendable layers.

**Mandatory contrast-pair proof:**

- **Interior:** a dark bound chamber / undercroft / machine hall.
- **Exterior:** an outdoor Gilded-Age world scene in readable daylight or bright overcast.

The same Duelist, boss, timing channel, and dashboard must belong in both. Passing only the dark
scene is a failure: it would reproduce the "one dungeon forever" trap Bill flagged.

### 2.3 HUD/UI — painted components over live controls

The generated Duelist dashboard mock-up establishes a promising hierarchy, not final taste. Its
durable insight is **one connected class instrument**:

- Flow/Aggro is the primary spine and prints the 30% lock threshold.
- Five combo sockets live inside that spine.
- Wind is a secondary reservoir inside the same object.
- Four abilities dock to the instrument.
- The answer channel remains immediately above and owns timing truth.
- Player/party survivability and current target form a left island.
- Boss HP/cast/effects form an enemy island away from the timing instrument.

Implementation uses modular authored components: 9-slice frames/caps · fill masks · sockets ·
icons · glints · typography · effect rings. No text, numbers, fills, cooldowns, or state are baked
into the paintings. The dashboard is world-neutral; scene profiles may contribute restrained
accent tint/ornament, never swap the information grammar.

The current Gilded Reliquary UI remains the fallback and supplies proven readability rules. Art
V2 may simplify the mock-up's ornament, reshape the sword silhouette, move islands, and reduce
material density after Bill's boards/playtest.

### 2.4 VFX + motion

Motion has four layers, ordered by return:

1. **Pose timing:** anticipation → contact → recovery, scrubbed to telegraph truth where required.
2. **Stage response:** hit-stop, lunge, recoil, shake, damage numbers, boss flash.
3. **Authored FX:** replacement contact drawings and 4–8-frame slash/impact/smoke sheets.
4. **Atmosphere:** scene particles, cloth/scarf secondary motion, restrained post effects.

The `tempo-art` Slice 1 (`e4589a6`) may already solve useful pieces of layer 2. Claude must audit
and transplant only the reusable, current-main-safe parts; do not merge the old branch wholesale.

---

## 3. SAFETY / COEXISTENCE WITH LIVE CLAUDE PLAYTESTS

- Docs-only decisions land on `main` in small explicit-path commits.
- Art/code work gets a fresh `../wow-art-v2` worktree and branch based on the then-current main.
- Before every slice: `git merge main`; after long image/approval pauses: merge again before code.
- Art V2 lives under a non-canonical namespace such as `res://game/art_v2/` until approved.
- A view-only **Art V2 selector** (exact mechanism chosen by Claude Packet C1) defaults OFF on
  `main`; a debug argument enables it in the worktree/build. No protocol bump.
- `Actor2D.make()`'s existing fallback remains intact. Missing/failed V2 assets return the current
  puppet, never a null actor.
- The current HUD remains intact. A V2 dashboard host can be toggled independently from V2 actors
  and V2 scenes so regressions are isolated.
- Never stage `godot/project.godot` or any unexpected editor rewrite with an art slice.
- Never merge generated source sheets accidentally; only approved/processed runtime assets enter
  the game. Source anchors may live in a clearly marked source-art folder if Bill wants history.

---

## 4. THE ORDER — ONE APPROVAL GATE AT A TIME

### P0 · DOC RESET — this slice

New plan · old-plan deprecation · MASTER/LEDGER sync · Claude packets. No code or art. Stop at V1.

### P1 · V1 STYLE BOARD — Codex image generation

Generate **three coherent direction boards**, each showing the same small set: Duelist · one boss
silhouette · interior crop · outdoor crop · dashboard material fragment · one ability icon.

Candidate families (prompts refined before generation; names are descriptive, not decisions):

- **A · CRISP GRAPHIC CEL:** clean shapes, restrained outlines, readable color blocks.
- **B · PAINTED STORYBOOK:** richer brush texture/material, controlled painterly edges.
- **C · ETCHED RELIQUARY:** illustrated ink/engraving character edges with painted fills and
  Gilded-Age ornament.

**Bill V1:** choose one, combine named parts, or reject all. Nothing else advances first.

### P2 · FOUNDATION RECON + FLAG — Claude packets C0/C1/C2

Read-only architecture map, default-off selector/fallback, and a Scene Profile host with placeholder
layers. This proves replaceability without final art. Merge only if old default is byte-identical
and smokes clean.

### P3 · ENVIRONMENT CONTRAST PAIR — Codex I1 + Claude C3

Codex generates approved layered interior/exterior assets. Claude builds/imports the two profiles
and the screenshot tour. Bill approves the same fight in both before we expand scenes.

### P4 · DUELIST ANCHOR + RIG — Codex I2 + Claude C4/C5

Approve the canonical character → derive/extract runtime layers → native rig → core animations →
deforming garment → contact replacement. Old actor remains default until the complete tour passes.

### P5 · DUELIST DASHBOARD — Codex I3 + Claude C6

Generate a modular component sheet from the approved UI direction, implement the connected class
instrument over existing live data, then test at 1080p/720p/ultrawide and in both scene profiles.

### P6 · SIGNATURE VFX — Codex I4 + Claude C7

Flipbook FX + En Garde/Dump/parry/dodge polish, current juice salvage, effect budget/readability.

### P7 · VERTICAL-SLICE VERDICT

Bill plays old and V2 side by side. Decide: ship V2 default for Duelist · revise · or fall back.
Only after this verdict do we generalize to other classes/bosses/scenes.

### P8 · SCALE

Turn the proven pipeline into a queue. Character/scene/dashboard work stays in thin per-asset
slices; do not promise a whole-roster big bang.

---

## 5. CLAUDE-READY ENGINEERING PACKETS

These packets intentionally carry most non-image work. **Each must be claimed separately in
MASTER before code, use its own current-main worktree/branch unless explicitly sequenced in
`art-v2`, and update MASTER + BUILD-LEDGER after merge.** They are queued, not pre-authorized to
ignore Bill's gates.

### C0 · GRAPHICS RECON (read-only; may run after P0)

**Goal:** map the smallest current seams for independent actor/scene/dashboard selection.

**Read:** `Actor2D`/`SpriteActor2D`/`PoseRig2D` · `RaidStage2D` construction + resize ·
`StageBackdrop` · `raid_hud` combat construction/render · current screenshot tours · `tempo-art`
diff against current main.

**Deliverable:** append `GRAPHICS-PLAN §10 IMPLEMENTATION MAP` with exact functions/line anchors,
candidate selector shape, collision list, and slice-specific verification. **No code.** Explicitly
classify every `e4589a6` hunk as salvage / stale / collision / reject.

### C1 · ART-V2 SELECTOR + FAIL-SAFE

**Goal:** independent view-only toggles for actor, scene, dashboard; all default OFF.

**Constraints:** user args/view config only · no CombatState/spec/protocol/checksum · missing asset
falls back · release default remains old · no canonical actor path takeover.

**Gates:** import/parse · old-mode screenshot A/B · relevant UI smoke · raid sim byte-identical.

### C2 · SCENE PROFILE CONTRACT + PLACEHOLDER PROFILES

**Goal:** data-driven six-layer SceneKit host with `legacy`, `v2_interior_test`, and
`v2_exterior_test` using temporary colored/debug layers only.

**Constraints:** aspect-expand safe · actor feet/scale unchanged · no UI parenting changes ·
profile absence returns legacy · atmosphere view-only.

**Gates:** screenshot tour at 1920×1080, 1280×720, 2560×1080; old-mode A/B; UI smoke.

### C3 · ASSET IMPORT + SCENE TOUR

**Goal:** documented folder/schema for layered backgrounds, texture import defaults, and a tour
that renders both approved profiles in repeatable combat moments.

**Constraint:** tooling consumes Codex assets; it does not invent style or repaint them.

### C4 · PAINTED ACTOR ADAPTER

**Goal:** native reusable actor implementation consuming approved layer/anchor metadata while
satisfying `Actor2D` verbs and failing back to the current actor.

**Constraints:** class-agnostic adapter · rigid/deform/frame-swap parts · render-rate motion ·
windup scrub · no engine state · no Spine dependency.

### C5 · DUELIST RIG + CORE ANIMATIONS

**Goal:** map Codex's approved Duelist layer set onto C4 and implement the P4 vocabulary.

**Gates:** automated pose/contact tour · live `raid:tank` playtest build · missing-assets fallback ·
determinism/raid integration check.

### C6 · DASHBOARD HOST + DUELIST BINDING

**Goal:** implement the modular painted dashboard using existing Flow/Wind/combo/ability/HP/party/
boss/cast/effect truth. Preserve the answer-channel positioning contract.

**Constraints:** art is replaceable texture/mask data · labels remain real fonts · no giant baked
HUD image · old band selectable · responsive safe areas · no gameplay smoothing of timing truth.

### C7 · VFX / FLIPBOOK RUNTIME + JUICE SALVAGE

**Goal:** reusable one-shot flipbook host, effect pooling/budget, and audited transplant of good
`tempo-art` Slice-1 pieces onto current main.

**Constraints:** no plain-strike hit-stop that breaks rhythm reference · GL Compatibility/WebGL2 ·
idle effects cost ~zero · no full-screen readability wash during answer windows.

### C8 · SLICE MERGE / VERIFY / DOC CLOSE

For every built packet: merge current `main` into branch → targeted checks → WSLg visual tour →
Bill gate where specified → merge-back → MASTER log/status + ledger SHA in same docs closure.

---

## 6. CODEX IMAGE / VISUAL PACKETS

- **I0:** V1 three-direction board.
- **I1:** approved interior/exterior contrast pair, delivered as separable scene layers.
- **I2:** Duelist anchor sheet + separated/derived runtime layers + replacement contact drawing.
- **I3:** dashboard component family: frame/caps/masks/fills/sockets/buttons/effect frames/icons.
- **I4:** short transparent FX sheets for dodge/parry/dump/En Garde/impact.
- **I5:** inspect tours, compare against anchor/style laws, request targeted edits, report visual
  acceptance evidence for the coordination log.

Each generated family is non-destructive and versioned. Approval chooses a derivative; rejected
generations do not silently enter runtime folders.

---

## 7. VERIFICATION + PERFORMANCE BUDGET

**Always:** current default remains playable · import clean · targeted smoke · deterministic sims
byte-identical for view-only work · missing V2 asset/profile returns legacy.

**Visual matrix:** 1920×1080 · 1280×720 · 2560×1080 (wide) · interior · exterior · idle · busy
answer channel · boss cast · peel/aggro warning · low HP · effect-heavy signature · death/victory.

**Web/GL law:** Compatibility renderer · no required backbuffer blur · shared/lightweight shaders ·
bounded particles · atlases where useful · no large permanently-running offscreen effects. Final
texture/draw budgets are set by C0/C3 measurements, not invented in this planning pass.

**Timing law:** gameplay note/gate/contact truth derives from ticks. Render interpolation may draw
between committed values; it never changes which input wins or when an attack resolves.

---

## 8. COLLISION MAP

- `raid_hud.gd`: tank playtest surface on live main; dashboard and screen-FX regions collide with
  multiple historical claims. Keep changes narrow, merge main frequently.
- `stage2d/raid_stage_2d.gd` + `pose_rig_2d.gd`: `tempo-art` has old branch work. Audit/cherry-pick
  concepts, never blind merge.
- `Actor2D.make()`: current fallback law is load-bearing; do not change canonical priority until V2
  approval.
- `stage_backdrop.gd`: current environment baseline; C2 owns the V2 host seam after recon.
- `godot/project.godot`: editor may rewrite it. Art work does not own that diff.
- UI asset imports and `.uid` files: stage only explicit approved paths; never sweep unrelated IDs.

---

## 9. FIRST DECISION — V1 ONLY

Before any final art or implementation, Bill reviews the three P1 boards. The questions are:

1. Which character rendering family feels like this game's long-term identity?
2. How ornate versus restrained should the persistent dashboard be?
3. Which elements from the existing mock-up are keep / change / remove?
4. Does the chosen family remain convincing in both the interior and exterior crop?

Everything else waits. This is deliberately the first small, reversible decision.

---

## 10. IMPLEMENTATION MAP

**Pending Claude Packet C0.** This section will receive the exact current-code seam map before C1.
