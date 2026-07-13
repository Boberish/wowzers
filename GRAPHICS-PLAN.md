# GRAPHICS-PLAN — the AI-owned visual system (Project Rift)

> **Design of record, 2026-07-12.** This plan owns the game's visual direction and production
> pipeline across **characters · animation · environments · combat VFX · HUD/UI art**. It
> supersedes `ART-PLAN.md` v1's Twinfang-only painted-cutout plan. The old plan stays in git as
> decision history; its completed juice slice is a candidate to salvage, not an automatic merge.
>
> `godot/ART-PIPELINE.md` is **not deleted**: it remains the live animation-name/fallback contract
> until Art V2 proves and replaces individual actors. `godot/UI-OVERHAUL.md` remains the current
> functional/readability baseline. This plan owns what the final authored art becomes.

**Status:** 🟡 **P4 SOURCE ART COMPLETE · CLAUDE C5 RUNTIME RIG NEXT.** Bill approved **SUNPRINT CEL** on
2026-07-12: bright, playful, detailed screen-print/cel adventure art with controlled authored
texture rather than generic dark-fantasy micro-detail. C0/C1 are complete; C3 schema/bindings merged `1abfcd4`; C2 SceneKit merged as
`da314e9` under Bill's explicit assume-pass instruction. Its deferred tour/smoke/A-B matrix remains
verification debt, not a blocker to P3.
Generated boards remain visual references, not runtime assets or a locked pixel layout.

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

**V2 decision:** the boards resolved the open style gate to **SUNPRINT CEL**. The default world is
light, colorful, happy, and adventurous; authored darker dungeons are contrast scenes, not the
whole game's exposure. Confident irregular ink contours, deliberate color blocks, limited
screen-print grain, and consistent shape language replace glossy gradients, random filigree, and
generic AI-fantasy microtexture. Codex generates and prepares the art. Claude builds the reusable
native pipeline. The target remains a
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

### 2.3 HUD/UI — reaction-first painted components over live controls

Bill's V1 verdict clarified that this is a **split-second UI game represented by animated
characters**, not a character-control game with a decorative HUD. The timing/answer channel is the
primary attention target. Actors, environments, and VFX celebrate and explain the input without
competing with the next read.

The durable layout insight remains **one connected class instrument**:

- The answer channel is the largest persistent combat instrument, broad and prominent in the
  lower-middle, and owns timing truth.
- Flow/Aggro is the class spine beneath it and prints the 30% lock threshold.
- Five combo sockets live inside that spine.
- Wind is a secondary reservoir inside the same object.
- Four abilities dock compactly to the instrument and remain visually secondary to the next
  timing target.
- Player/party survivability and current target form a left island.
- Boss HP/cast/effects form an enemy island away from the timing instrument.

**Reaction-first contract:**

- A valid press responds in the same rendered frame: button depression/pulse, exact press mark,
  and local channel reaction do not wait for later attack impact.
- PERFECT/BULLSEYE/other grades are large, high-contrast, and anchored at the answer focus; a
  brief residual history remains while the next target is already readable.
- Feedback has three ordered layers: **press acknowledgment → timing verdict → world/actor payoff**.
  Layer 3 may be beautiful, but layers 1–2 carry the game.
- Shake, smears, flashes, and large typography never move or hide timing truth.
- Final pixel sizes are chosen in a live rapid-sequence prototype, not copied literally from a
  generated screenshot.

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

**High-flow law:** gameplay never queues behind presentation. Contact accents initially target
roughly 50–100 ms; recovery may run roughly 100–180 ms but is always interruptible. New committed
actions replace/scrub stale recovery immediately, especially for Twinfang at high Flow. The answer
channel and next target remain coherent even when character poses cannot visually finish.

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

### P1 · V1 STYLE BOARD — ✅ BILL VERDICT 2026-07-12

Generate **three coherent direction boards**, each showing the same small set: Duelist · one boss
silhouette · interior crop · outdoor crop · dashboard material fragment · one ability icon.

Candidate families (prompts refined before generation; names are descriptive, not decisions):

- **A · CRISP GRAPHIC CEL:** clean shapes, restrained outlines, readable color blocks.
- **B · PAINTED STORYBOOK:** richer brush texture/material, controlled painterly edges.
- **C · ETCHED RELIQUARY:** illustrated ink/engraving character edges with painted fills and
  Gilded-Age ornament.

**Bill V1 verdict:** **A refined to SUNPRINT CEL.** Keep Graphic Cel's crisp silhouettes and
animation-friendly parts; make the default world bright, fun, and detailed through intentional
design rather than AI-looking microtexture. The UI is reaction-first per §2.3. No more slideshow
proof is required; proceed to the replaceability foundation.

### P2 · FOUNDATION RECON + FLAG — ✅ C0/C1 DONE · C2 MERGED `da314e9` (ASSUMED PASS)

Read-only architecture map, default-off selector/fallback, and a Scene Profile host with placeholder
layers. This proves replaceability without final art. Merge only if old default is byte-identical
and smokes clean.

**Verification debt:** Bill explicitly waived C2's long final matrix on 2026-07-12 so production
could continue. Run the recorded profile/resolution tour, UI smoke, and low-seed A/B gate before
Art V2 can become a release default; failures return to C2 without invalidating the asset work.

### P3 · ENVIRONMENT CONTRAST PAIR — ✅ 10/10 LAYERS + LIVE 1080P CONTRAST PROOF

Codex generates approved layered interior/exterior assets. Claude builds/imports the two profiles
and the screenshot tour. Bill approves the same fight in both before we expand scenes.

**Progress 2026-07-12:** C3 merged `1abfcd4`; source anchors archived `3a855ef`. Bill approved the
regular bright-atrium base as a quiet tileable backdrop; `stack_atrium/backdrop.png` is layer 1/5.
Its v1 resolution is prototype-grade, and later transparent layers deliberately provide the
asymmetry and encounter-specific composition.

Backdrop + distant shipped in `ebd7242` after the C3 visibility hotfix `516e1b0`. The asymmetric
midground is layer 3/5: transparent 2048×512 with the actor/timing lanes open. Floor and dressing
remain before the first complete Stack composition verdict.

**Stack Atrium 5/5 complete:** the opaque 2048×256 access-panel floor calms the lower band; the
512×512 coolant-column dressing frames both flanks. One live 1080p tour renders all five layers,
keeps feet fixed, and leaves the timing channel unobstructed. P3 now builds the Cold Aisle sibling.

**Cold Aisle 5/5 complete:** night-maintenance backdrop, drifting fan/catwalk strip, asymmetric
cooling midground, cool access-panel floor, and dehumidifier flank dressing. The paired live
1920×1080 tours render all 10 textures; feet records are identical across profiles; timing/HUD
remain untouched. The full resolution/legacy A-B matrix remains recorded debt before release
default, per Bill's explicit move-on instruction.

### P4 · DUELIST ANCHOR + RIG — 🟡 C4 ADAPTER 🔨 `05d9952` · I2 SOURCE ART 🔨 `11bcd4a` + `567adea` · CLAUDE C5 NEXT

Approve the canonical character → derive/extract runtime layers → native rig → core animations →
deforming garment → contact replacement. Old actor remains default until the complete tour passes.

**I2 image gate passed 2026-07-13:** Bill approved the revised light dodge-tank identity after
rejecting the armored first pass. Codex delivered the anchor, six separately generated part
sources, and two replacement poses as both chroma and alpha files under
`art-source/graphics-v2/p4-duelist/` (`11bcd4a`, `567adea`). At Bill's explicit delegation, C5 now
owns the non-image production tail: trim/normalize, runtime copy/import, anchor mapping, real pose
vocabulary, and verification. The debug slabs remain in `res://` until that work passes. **C5 may
not generate, redesign, or silently substitute any image.** If the delivered sources cannot meet
the runtime need, Claude stops and asks Bill; only after Bill approves does Codex generate or edit
another image.

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

### C1 · ART-V2 SELECTOR + FAIL-SAFE — 🔨 BUILT+MERGED `3da278f` (2026-07-12)

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

### C3 · ASSET IMPORT + SCENE TOUR — 🔨 BUILT+MERGED `1abfcd4` + hotfix `516e1b0` (2026-07-12; schema = `godot/game/art_v2/SCENES.md`; `stack_atrium` backdrop+distant delivered `ebd7242` and RENDERING; §3½ renderer law: textures resolve at host _ready, never in painters — WSLg first-load-in-draw = white RID)

**Goal:** documented folder/schema for layered backgrounds, texture import defaults, and a tour
that renders both approved profiles in repeatable combat moments.

**Constraint:** tooling consumes Codex assets; it does not invent style or repaint them.

### C4 · PAINTED ACTOR ADAPTER — 🔨 BUILT+MERGED `05d9952` (2026-07-13; contract = `godot/game/art_v2/ACTORS.md`; rigid/deform/replacement modes proven on debug slabs at the duelist id; legacy factory untouched; pose/contact matrix + live playtest = deferred debt)

**Goal:** native reusable actor implementation consuming approved layer/anchor metadata while
satisfying `Actor2D` verbs and failing back to the current actor.

**Constraints:** class-agnostic adapter · rigid/deform/frame-swap parts · render-rate motion ·
windup scrub · no engine state · no Spine dependency.

### C5 · DUELIST RIG + CORE ANIMATIONS

**Goal:** map Codex's approved Duelist layer set onto C4 and implement the P4 vocabulary.

**Image-generation stop:** tooling/crop/scale/anchor/import work is authorized; new generation,
redesign, or art substitution is not. If a source or required pose is missing/unusable, stop and
ask Bill before handing an explicit image request back to Codex.

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
- **I2:** 🔨 `11bcd4a` + `567adea` — approved Duelist anchor + separated chroma/alpha part sources +
  windup/contact replacements; lower-level runtime preparation delegated to C5 by Bill.
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

## 10. IMPLEMENTATION MAP — Packet C0 recon (2026-07-12)

> Read-only audit against `main` @ `e0ebe88` (post tank-v3 merge — the AnswerChannel/one-bar
> era). Line numbers drift; the function names are the durable anchors. **Correction to §8's
> assumption:** tank-v3 is already MERGED to `main` — the collision picture below reflects that.

### 10.1 The seams — where each independent selector cuts

**ACTOR seam — `game/stage2d/actor_2d.gd` (70 lines, the whole contract):**
- `Actor2D.make(id, aspect)` `actor_2d.gd:58-70` is THE single actor factory; both call sites
  live in `raid_stage_2d.gd` (`:52` boss, `:75` seats). User art already wins via
  `res://game/art/actors/<id>.tscn` → `SpriteActor2D` (`:59-61`) — **that folder does not exist
  yet**; every seat is a placeholder puppet today.
- ⚠ **LIVE WART (post-PURGE fallthrough):** the factory matches only `twinfang | voidcaller |
  mender`; `RaidStage2D.setup` (`raid_stage_2d.gd:71-72`) now passes `duelist / alchemist /
  well` — all three fall through `_` to **`RiftmawRig2D` (the BOSS puppet)**. Tank, caster and
  healer render as mini-Riftmaws on main today, and `aspect` is dropped for them. The
  `voidcaller`/`mender` rigs are unreachable dead code; the factory's doc comment (`:56-57`)
  is stale. C4's adapter registration should fix the mapping in the same breath.
- Verb contract (`act/windup/swing/reacts/state-looks`, `:14-51`) is complete and boss-scrub
  proven: `SpriteActor2D.windup` (`sprite_actor_2d.gd:61-69`) already pauses + seeks
  `windup_<kind>` to `amt × length` per frame — the exact scrub law C4 needs, working today.
- `PoseRig2D` (`pose_rig_2d.gd`): joints/limbs (`:14-71,118-149`), named poses + seq + windup
  overlay solve (`:234-275`), `flash_part`/`part_glow` (`:217-231`). Cosmetic RNG only
  (`jolt :198`). This is the pose solver Art V2 may reuse behind the C4 adapter.

**SCENE seam — one construction point, one always-on node:**
- `raid_hud.gd:276` (`_ready`): `_stage = StageBackdrop.new()` — the ONE environment node,
  first child, alive behind every screen. `WorldShell` (`world_shell.gd:23`) instances
  `raid_main` as its child and adds NO backdrop of its own, so shell screens (home/atlas/
  bastion) draw over this same node. **C2's host replaces exactly this one line.**
- `StageBackdrop` (`ui/stage_backdrop.gd`, 227 lines): `_init(is_combat)` menu/combat variants
  (`:19-26`), layers = `UiKit.stage_background` fill + `_arch` colonnade `_draw` (`:109-166`) +
  `_glow` rift/god-rays/ground-pool (`:179-227`) + `UiKit.gold_motes` + embers particles
  (`:59-82`). Fixed-jag const (`:17`) keeps it deterministic frame-to-frame. It is already a
  poor-man's Scene Profile (backdrop/midground/floor/atmosphere in one file) — C2 decomposes
  this grammar into the six-layer contract; `legacy` profile = this node unchanged.
- Combat floor contract (what profiles must NOT move): `RaidStage2D.SLOTS` feet fractions +
  per-slot scale/dim (`raid_stage_2d.gd:15-20`), `BOSS_AT` (`:21`), contact shadows in
  `_draw` (`:98-107`), `_layout` on `resized` (`:80,83-96`). Stretch = `canvas_items` +
  `expand` (project.godot) — wider aspects GROW design width, so fraction-anchored actors
  spread apart on 2560×1080; profile side-layers must be repeatable/extendable (law §2.2).

**DASHBOARD seam — `raid_hud._build_combat` + the band registry:**
- `raid_hud.gd:2583` `_build_combat(s)`: builds, in order — `_stage2d` (`:2587`) →
  `_shake_root` (`:2599`) → fixed widgets `_bar`/`_castbar`/`_dial`/`_judge`
  (`:2604-2627`) → `BossIntro` (`:2630`) → `_meter` (`:2636`) → raid frames col
  (`:2649-2678`) → `_aggro_warn` (`:2680`) → **`_band = ClassBand.for_hud(self)` + build
  (`:2688-2689`)** → build stamp → `_fx` overlay (`:2700-2703`) → pause button.
- Per-class instruments live in `game/ui/bands/*.gd` (`ClassBand.for_hud` picks by
  `_seat_cls_now()`). The tank's connected instrument already half-exists:
  `duelist_band.gd:build()` raises `AnswerChannel` (`:37-39`, bottom-center
  `place(-370,-412,370,-288)` under `_shake_root`), `DuelistGauge`, `VerdictSlam`, 4
  `AbilityRune`s. **The answer channel is timing truth (law §2.3) — C6 docks art AROUND it,
  never re-parents or smooths it.**
- Render feed: `_process` (`:3158`, guarded `_screen != "combat"`) → `_render_dial`
  (`:3209`, one-bar: dial+judge hidden for the duelist seat `:3215-3219`), `_render_frames`,
  `_band.render` (`:3192-3193`) → `_stage2d.sync(s)` + event drain to `_stage2d.on_event` +
  `_handle_event` (`:3195-3201`). `_handle_event` (`:3477`) is the juice trigger map.
- Teardown: `_clear` (`:298-311`) frees `_ui` children and nulls `_band`/`_stage2d` — any V2
  host member must be nulled there too (see H5 note below).

**View-config precedent (for the C1 selector):**
- User-arg parsing: `--fightlen=` in `raid_hud._ready` (`:289-293`); all autostart idioms
  live in `WorldShell.drive_autostart` (`world_shell.gd:70` region) — the boot owner, where an
  `--artv2=` arg belongs. Persistence precedent: `UI_CFG := "user://rift_ui.cfg"` +
  `ConfigFile` (`raid_hud.gd:2953,2979-3006`, the raid-col drag position).

### 10.2 Candidate selector shape (C1 input, not a decision)

One tiny static holder, no autoload: `game/art_v2/art_v2.gd` (`class_name ArtV2`) with three
independent `static var`s — `actors: bool` · `scene: String` (profile id, `""` = legacy) ·
`dash: bool` — set once by `WorldShell.drive_autostart` from `--artv2=actors,scene:<id>,dash`
(+ optional `user://rift_art.cfg` later). Consumption, one guarded line per seam:
1. `Actor2D.make()` head: `if ArtV2.actors: <v2 adapter try_make, null ⇒ fall through>` —
   sits ABOVE the user-art check without changing it; OFF ⇒ byte-identical path.
2. `raid_hud._ready:276`: `_stage = SceneKit.make(ArtV2.scene)` where unknown/empty profile
   returns `StageBackdrop.new()` (legacy).
3. `_build_combat`: `if ArtV2.dash and <host has this class>:` build the V2 dashboard host
   instead of the fixed-widget block + band; else current code untouched.
All three are view-construction reads only — no CombatState/spec/protocol/checksum contact;
flags default off ⇒ smokes/sims byte-identical. (GDScript gotcha: `static var`, never `const`.)

### 10.3 Collision list (live, 2026-07-12)

| Surface | Who else is on it | Rule for art-v2 |
|---|---|---|
| `raid_hud.gd` | THE hotspot (LEDGER §0): tank-v3 playtest surface is LIVE on main (Bill mid-playtest, fix `ef7a44e` same day); SEAL-rework build (BOSS-BRIEF) queued against it; METER L4/L5 🟡 | Merge `main` into `art-v2` before EVERY slice; keep `_build_combat` edits additive + guarded; never edit `_render_dial`/answer-channel truth |
| `ui/bands/duelist_band.gd` + `ui/answer_channel.gd` | tank-v3's active feel surface, tuned daily | C6 is deliberately LAST (P5); dock around, never re-parent; the channel's `place` box is the positioning contract |
| `stage2d/*` | QUIET — only the purge id-swap since the `tempo-art` branch point; no open claims | Lowest-risk seam; C4/C5 land here. Fix the `make()` fallthrough wart here |
| `ui/stage_backdrop.gd` | Untouched since branch point; no claims | C2 replaces its construction site only; file itself stays as the `legacy` profile |
| `godot/project.godot` | ⚠ an UNCOMMITTED editor rewrite (comment-strip + key reorder) is sitting in the working tree RIGHT NOW — §8's warning is live, not theoretical | Never stage it with an art slice |
| Open ☐ claims (MASTER log) | slate-machine ×2, refit-p3, undermill, tank-design ×2 — docs-only or non-stage surfaces | No stage2d/backdrop overlap; re-check the log at each C-packet claim |

### 10.4 Slice-specific verification

- **Honest A/B caveat:** the view layer seeds cosmetic RNG from wall-clock
  (`raid_hud.gd:274 seed(Time.get_ticks_usec())`; `randf` in stage FX / smears / jolts), so
  pixel-diffing busy combat frames is unreliable. Old-mode A/B = idle/menu frames pixel-safe +
  busy frames eyeballed on tour sheets + `ab-gate.sh raid_sim` byte-identical + smokes green.
- **C1:** headless import · `ui_smoke_raid` · `scripts/ab-gate.sh raid_sim` (flags absent ⇒
  byte-identical) · WSLg `raid_stage_tour` + `screenshot_duelist_raid` old-mode sheets.
- **C2:** `raid_stage_tour --resolution` at 1920×1080 / 1280×720 / 2560×1080 (tour boots
  `raid_main` directly and drives `hud._launch` at frame 1 — `sim/raid_stage_tour.gd:14-33`,
  the probe-boot gotcha already encoded); feet-line check = SLOTS fractions unchanged in shots.
- **C4/C5:** pose/contact tour (extend `raid_stage_tour` shot list) · live `--autostart=raid`
  tank playtest · fallback proof = boot with the v2 asset folder renamed away → current puppet.
- **C6:** `ui_smoke_raid` · resolution matrix · both scene profiles · tank playtest.
- **C7:** tour + `ab-gate raid_sim`; budget check = `ScreenPostFx` hidden at rest (idle pays
  zero — its own contract), one-shot FX all `queue_free` ≤ ~1.2 s.
- **Budget baseline (C0 measurement):** today's stage is 100% vector `_draw` + CPUParticles
  (bursts of 12–24) + zero textures; the only shader is the dormant `screen_post.gdshader`.
  Texture/draw budgets have no baseline to inherit — C3 sets them when the first real assets
  land (per §7).
- **Everything:** `verify-all.sh` at slice END only (Bill's verify-minimal rule, 2026-07-11).

### 10.5 `tempo-art` Slice 1 (`e4589a6`) — hunk-by-hunk classification

The branch is ONE commit ahead of `0ad2ac8`; since then main's touched files drifted only in
`raid_hud.gd` (massively — tank-v2/v3, castbar split, event-map growth; all anchors survive
under new line numbers) and `raid_stage_2d.gd` (purge id-swap + `BulwarkRig2D` guard removal
only). `pose_rig_2d.gd`: zero drift. `screen_post.gdshader` exists on main, dormant, uniforms
exactly matching. **Verdict: 13/13 hunks SALVAGE (no stale, no reject) — but transplant as a
fresh C7 cherry-pick with re-anchors + the noted fixes, never a branch merge.**

| # | File · hunk | Verdict | Anchor on main today + notes |
|---|---|---|---|
| H1 | `ui/screen_post_fx.gd` (+`.uid`) — new 95-line `ScreenPostFx` | **SALVAGE** | File absent on main; shader uniforms match 1:1; self-hides at rest (idle pays zero — §7 law). C7 re-checks `hint_screen_texture` cost on WebGL2 |
| H2 | `pose_rig_2d.gd` — `flash_all()` | **SALVAGE** | Insert after `set_highlight` (`:215`); zero drift |
| H3 | `raid_hud.gd` — `var _post` member | **SALVAGE** | After `var _fx: Control` (`:238`) |
| H4 | `raid_hud.gd` — `_build_combat` creates `_post` topmost | **SALVAGE** | After `_fx` add (`:2703`), before `_add_pause_button()` (`:2704`) |
| H5 | `raid_hud.gd` — `_process` vignette feed | **SALVAGE + fix** | After `obs :=` (`:3167`). ⚠ Branch never nulls `_post` in `_clear` (`:305` region) — dangles on a freed node after teardown; dormant today only because `_handle_event` runs solely from combat `_process`. Add `_post = null` to `_clear` in the transplant |
| H6 | `raid_hud.gd` — `hurt` crimson flash + aberr (`amt ≥ 30`) | **SALVAGE** | Inside `mine` block of `"hurt"` (`:3509-3515`) |
| H7 | `raid_hud.gd` — `staggered` green deny-wash | **SALVAGE (re-anchor)** | Branch anchored a single big-text; main split `was_heal` → CHANT DENIED (`:3541-3547`). Insert after `_add_shake(5.0)` (`:3547`) |
| H8 | `raid_hud.gd` — `strike` bullseye/perfect mint washes | **SALVAGE** | Graded-verdict match intact (`:3602-3608`) |
| H9 | `raid_hud.gd` — new `finisher` branch (cp≥4 gold wash) | **SALVAGE + fix** | Event IS live: `twinfang_kit.gd:1464` (eviscerate) `/:1566` (envenom) emit `{"t":"finisher","cp"}`. ⚠ Event carries no `player` flag and the hunk never gates on `mine` — an AI blade's evis also washes the whole screen. C7 decides: add a player gate or accept party-wide |
| H10 | `raid_hud.gd` — `coup` wash + delayed (0.26 s) shock/aberr | **SALVAGE** | `:3622-3624`; shock center `(0.72,0.55)` = `BOSS_AT` fraction, still correct |
| H11 | `raid_hud.gd` — `opening` PUNISH flash | **SALVAGE** | `:3651-3653` |
| H12 | `raid_stage_2d.gd` — `_freeze` member + `_layout` `set_meta("home")` | **SALVAGE** | `:28` region / `:93`; layout re-stamps home on resize (correct) |
| H13 | `raid_stage_2d.gd` — `_fire` swing-juice (lunge/smear/coup ghosts) + `hitstop()/_lunge()/_smear()` + `_process` freeze + impact `flash_all`/hitstop/`ghostat` + `_ghost(col)` | **SALVAGE** | Anchors `:287-295` / `:298` / `:307-330` / `:386` all intact. Verified vs tank-v3: the tank's committed STREAM rides `AnswerChannel` (HUD widget, NOT under `_world`) — hit-stop can't touch timing truth; plain strikes exempt by design (idle bounce = beat reference); `kick` hitstop is a dead path until pillar #3 lands (harmless). Note: `_fxl` particles freeze WITH `_world` during the 0.06-0.09 s stop (tweens keep flying — they bind to the stage node); imperceptible, keep |

**Transplant route:** all of it is C7 scope (plus H2's `flash_all` which C5 may want earlier).
Cherry-pick from `e4589a6` hunk-wise onto a fresh current-main branch, apply the H5/H9 fixes,
then the standard C7 gates. After transplant, freeze `tempo-art` for deletion (its only commit
is then fully absorbed).
