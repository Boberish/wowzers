# ART-PLAN — the character-art pass (Project Rift)

> **What this is.** The design-of-record for putting real, "nice and pro" character art +
> ability juice into the game, **starting with Twinfang·Tempo**. Born 2026-07-10 when Bill asked
> to begin the art for one class and to first sanity-check the *foundation* ("did we pick the best
> lib, are we ready for the future"). This doc is the plan; the **animation-name contract** that
> art must satisfy lives in `godot/ART-PIPELINE.md` (the two are companions — plan here, contract
> there). Tracking: MASTER-PLAN §GRAPHICS (living state) · BUILD-LEDGER §G (slate row) ·
> CARD-CATALOG (n/a — art, not cards).

**Status:** 🔨 **Slice 1 BUILT** (branch `tempo-art`, `e4589a6` — juice pass, view-layer only,
awaiting verify + merge). Slices 2–3 designed, Slice 2 waits on Bill's generated PNGs.

---

## 0. THE ASK & THE HEADLINE VERDICT

Bill: *"start the art for the Twinfang Tempo deck… mostly code art with basics + VFX to look
decent for little work… StS2 is the dream, but a budget code version — Across the Obelisk /
Darkest Dungeon style."* Then: *"before we commit, make sure we picked the best lib and are ready
for the future — up the max we can."* Locked scope: **this character ships no matter what — autos
(Strike) + two signature attacks (Eviscerate, Coup de Grâce).**

**The three decisions (locked with Bill via Q&A, 2026-07-10):**

| Decision | Choice | Why |
|---|---|---|
| **Renderer backend** | **Painted layers on the existing native `PoseRig2D` skeleton** (NOT Spine now) | Agents can author/tune code-driven poses directly; the `Actor2D` contract keeps **Spine Pro as a drop-in per-actor upgrade door** for later. $0, zero throwaway. |
| **Art style** | **Across the Obelisk cel** — clean cartoon, flat fills, soft outlines | Easiest for AI generation to keep consistent; forgiving of static art; fits the ironic-takeover tone. |
| **Art source** | **AI-generated** (Bill generates, Claude cuts/aligns/integrates) | Bill has the image-gen; Claude has the engine. Generate NOW, accept THEME-PLAN re-skin risk (regen cheap, re-cut ≈ half a day). |

---

## 1. FOUNDATION REVIEW — "is this the right base?" (the research)

Researched Spine, Godot-native Skeleton2D/Bone2D, DragonBones, Rive. Findings:

- **StS2 is literally Godot 4 + Spine.** Mega Crit migrated Slay the Spire 2 from Unity to Godot;
  characters are Spine skeletal meshes imported into Godot's node tree. So *the dream is
  same-engine* — the ceiling is reachable without changing stacks.
- **Spine Pro = $369 one-time**, and `spine-godot` is now a **drop-in GDExtension** (no custom
  engine builds; web export works). Its real cost is **not money or tech — it's that rigging and
  keying happen in a GUI editor an agent can't drive.** It's a skill tree Bill would climb alone.
- **Godot's own Bone2D / SkeletonModification2D layer is half-abandoned in 4.x** — thin docs, IK
  removed/reworked. Our hand-written pose solver already covers what we'd use it for.
- **DragonBones** (free Spine-alike) has no maintained Godot 4 runtime. **Rive** is immature for
  this use.

**Verdict: native skeleton now, Spine door explicitly open.** The load-bearing insight is that
**`Actor2D` (the contract, `godot/game/stage2d/actor_2d.gd`) isolates the renderer choice
per-actor.** Any actor can be a code puppet, a painted-cutout skeleton, or a `SpineActor2D` later
— the stage directors only ever call the contract; swapping a backend is dropping a file, not an
engine change. **Impact *feel* (hit-stop, screen shake, smears, shockwaves), not the animation
library, is most of perceived AAA quality** — and all of that is code we own. So we buy the feel
first (Slice 1), then the skin (Slice 2), then the FX flourish (Slice 3), and leave Spine as a
paid upgrade behind the same contract if Bill ever wants the last 20%.

---

## 2. WHAT ALREADY EXISTS (nothing starts from zero)

The 2D stage is real and built to receive art:

- **`RaidStage2D`** (`godot/game/stage2d/raid_stage_2d.gd`) — four raider puppets + boss in a
  staggered side-view rank; drives them from the combat event stream (`ability_fired` →
  `actor.act(id)` → scheduled impact VFX at the boss chest). Shared VFX kit: `_arc/_spark/_star/
  _bolt/_ghost/_swirl` + a `_punch` zoom.
- **`PoseRig2D`** (`pose_rig_2d.gd`) — the puppet animation engine: `Limb` shapes on named joints,
  eased pose blending, action sequences, stage-driven wind-up scrubbing, breathing, jolt,
  per-part glow/flash. Doc comment already anticipates this pass: *"Real cutout art later …
  replaces Limb draws only."*
- **`TwinfangRig2D`** (`twinfang_rig_2d.gd`) — 15 joints (root/hips/chest/head/arm_f/fore_f/hand_f/
  arm_b/fore_b/hand_b/leg_f/shin_f/leg_b/shin_b/scarf), full pose set + `act()` for strike /
  eviscerate / kick / coup / venoms, Flow glow. **The idle bounce beats at the Perfect-window
  tempo** — the rhythm made flesh.
- **`Actor2D.make()`** — the factory: **user art wins.** If `res://game/art/actors/<id>.tscn`
  exists it's wrapped in `SpriteActor2D`; else the code puppet. `godot/ART-PIPELINE.md` documents
  the full animation-name contract.
- **`screen_post.gdshader`** — a full-screen shockwave / chromatic-aberration / colour-wash /
  low-HP-vignette pass, **authored but wired to nothing** until Slice 1. Designed to sit at
  identity (free) when idle.
- The event stream (`raid_hud.gd` drains `CombatState.events` → `_stage2d.on_event` +
  `_handle_event`) is **view-only, never checksummed** — VFX can hang off it freely.

Design space 1920×1080, GL Compatibility (WebGL2/WSLg-safe), pure 2D. Raiders ~300px tall,
authored facing +X, feet at y=0.

---

## 3. THE SLICES

### Slice 1 — THE JUICE PASS ✅ BUILT (`e4589a6`, view-layer, no art dependency)

The biggest bang for the least work, and it needs no art at all. Class-agnostic impact feel, with
Twinfang's three signatures bespoke-tuned.

- **`ScreenPostFx`** (new, `game/ui/screen_post_fx.gd`) — wires the dormant `screen_post.gdshader`.
  Helpers `flash(col, amt, delay)` / `shock(center, amt, delay)` / `aberr(amt, delay)` /
  `set_vignette(v)`; all decay lives in the node; it **hides itself whenever every uniform is at
  rest** (idle frames pay nothing — the shader is identity then). The `delay` arg lets a press-time
  event land its shock on the *stage's* impact frame.
- **HUD trigger map** (`raid_hud._handle_event`):
  - `coup` → mint wash on press + shockwave & RGB-split timed +0.26 s (the plunge's landing)
  - `finisher` (eviscerate) with cp ≥ 4 → gold wash + light aberration on impact
  - `strike {result: bullseye/perfect}` → *subtle* mint flash (fires ~1/s — kept tiny)
  - big `hurt` taken by my seat → crimson wash + aberration
  - `staggered` (kick lands) → green "deny" wash
  - `opening` PUNISH → gold flash
  - low-HP crimson **vignette** that breathes in from 35 % HP, driven per-frame from `observe()`
- **Stage-local hit-stop** (`raid_stage_2d.hitstop`) — freezes the actor `_world` subtree
  (poses, particles) 60–90 ms on coup/evis/kick impacts while HUD, rhythm bar and in-flight FX
  tweens keep running: the impact frame HOLDS. **Never on plain strikes** — the idle bounce is the
  beat reference for the rhythm minigame.
- **Smears + lunges + ghosts** (`raid_stage_2d`) — additive dagger-arc crescents (white / mint
  Perfect / gold evis), DD-style lunge-slides toward the boss and back, mint afterimage ghosts
  along the coup leap.
- **Boss impact flash** — `PoseRig2D.flash_all(col, amt)` white-outs the boss on big impacts.
- **Damage-number styles** — `coup` / `finisher` already have bespoke big-mint `STYLE` entries.

### Slice 2 — PAINTED CUTOUT SKIN (needs Bill's PNGs)

Bolt the painted art onto the existing skeleton — every already-authored animation drives it with
no new animation work.

- **`tex` Limb kind** in `pose_rig_2d.gd` (~40 ln): a `Limb` gains `tex: Texture2D` +
  offset/rot/scale; `_draw()` for kind `"tex"` = silhouette shadow pass (draw the PNG black ~0.35 α,
  +2 px) → normal draw → glow/flash as tinted redraws of the same texture. `flash_part`/`part_glow`
  keep working unchanged.
- **`TwinfangSkinRig2D extends TwinfangRig2D`** (new file): overrides `_build()` only — **same
  joint tree, identical names/positions**, so all inherited poses + `act()` drive it. Loads tex
  limbs from `res://game/art/actors/twinfang/<part>.png`. A debug flag draws joint markers to speed
  alignment.
- **Factory**: `Actor2D.make` checks the parts dir → skin rig; `.tscn` keeps top priority; the
  vector puppet stays the fallback (delete nothing).
- **Secondary motion**: scarf/hood get cheap code spring physics; optional Polygon2D mesh-deform
  where rigid cutout reads stiff.
- **`godot/ART-PIPELINE.md`**: document the parts-dir path + note Spine as the upgrade door behind
  `Actor2D`.

### Slice 3 — FLIPBOOK FX + SIGNATURE POLISH ("up the max")

- **Flipbook FX sheets** — AI-generated 4–8-frame effect animations (slash arcs, impact bursts)
  played as `AnimatedSprite2D` one-shots over the actors on evis/coup. This is how StS2 / Darkest
  Dungeon 2 fake hand-drawn FX; **AI is good at effect frames** (style consistency barely matters
  for energy shapes). Augments the procedural `_arc`.
- **Retime** strike/evis/coup pose durations against the painted parts; tune smear shapes and
  screen-post amounts; review via screenshot tour with Bill; iterate.

---

## 4. THE AI-GENERATION BRIEF (Bill's parallel task)

**Format:** PNG with transparent background (alpha is the one hard requirement — no JPEG; layered
PSD or SVG also fine). Character ≈1200 px tall on a ~1500×1500 canvas (shown ~300 px in game — big
downscales clean). Two deliverables; #1 alone is enough to start.

**Deliverable 1 — REQUIRED (assembled character):**
> One 2D game character on a fully transparent background, PNG with alpha. Hooded rogue duelist
> with twin daggers, **full body, side view facing RIGHT**, feet on a common baseline. ≈1200 px
> tall, stylized ~5-heads proportions, oversized hood. **Pose: neutral athletic crouch, BOTH arms
> held out away from the torso with daggers pointed down-forward — no limb overlapping the torso or
> another limb.** Legs slightly apart, front/back leg clearly separated. **Style: Across the
> Obelisk — clean cel shading, flat fills, soft dark outlines (~3 px), light upper-left, NO
> gradients, NO ground shadow, NO background, no baked glow.** Back arm/leg one shade darker
> (depth). Long scarf trailing behind (left), clear of the silhouette. Palette: leather `#505064` ·
> hood `#3C3C4C` · pants `#464658` · sash `#8A7429` · dagger steel `#C7CCE0` · skin `#6B5C54` ·
> **glowing mint `#7FE0A0`** on eyes, scarf edge, dagger edges.

**Deliverable 2 — IDEAL (exploded parts sheet, 12 pieces on one ~2048×2048 transparent canvas,
same scale/angles, nothing touching):** ① head+hood ② torso+shoulder pad ③ pelvis+sash ④ front
upper arm ⑤ front forearm+hand+dagger ⑥ back upper arm ⑦ back forearm+hand+dagger ⑧ front thigh
⑨ front shin+boot ⑩ back thigh ⑪ back shin+boot ⑫ scarf. **Each piece extends ~15 % past its
joint with a rounded end** (paper-doll overlap — no seams on rotation); hidden areas painted in
(torso continues behind the arm).

The 12 pieces map 1:1 onto the skeleton's joints, so strike / the X-cross / the coup leap / dodges
/ the death sprawl all animate the art the day it's aligned. **Only two things break the pipeline:
limbs overlapping the body, and a baked shadow/background.** An 8-part fallback (whole legs, whole
back arm) is acceptable — stiffer knees/elbows, DD gets away with it. If the parts sheet comes back
off-model, skip it — Claude cuts Deliverable 1 by hand.

**Approval gates:** (1) Bill picks the raw generation = look approved. (2) Bill approves in-game
tour screenshots before anything merges.

---

## 5. FILES TOUCHED (collision map)

- `godot/game/raid_hud.gd` — post-fx node + trigger map. ⚠ **combat region only** — the
  `descent-map` session owns this file's MAP region; merge main often.
- `godot/game/ui/screen_post_fx.gd` — NEW (Slice 1)
- `godot/game/stage2d/raid_stage_2d.gd` — hit-stop, smears, lunges, coup ghosts, impact flash
- `godot/game/stage2d/pose_rig_2d.gd` — `flash_all` (Slice 1); `tex` Limb kind (Slice 2)
- `godot/game/stage2d/twinfang_skin_rig_2d.gd` — NEW (Slice 2)
- `godot/game/stage2d/actor_2d.gd` — factory parts-dir check (Slice 2)
- `godot/game/ui/damage_numbers.gd` — coup/finisher styles (already present)
- `godot/game/art/actors/twinfang/*.png` — NEW asset dir (Slice 2)
- `godot/ART-PIPELINE.md` — doc update (Slice 2)

Gotchas: colors via `Palette` **static var** (never `const`); place-then-add for any Control;
probe scripts start at frame 1 of `_process`.

---

## 6. VERIFICATION (the merge-back bar)

- **Visual (WSLg, NOT --headless — headless can't render `_draw`):**
  `godot --path godot --script res://sim/raid_stage_tour.gd --resolution 1920x1080 -- --out=/tmp/shots`
  → flip PNGs; and play `godot --path godot -- --autostart=raid:blade:tempo` for feel.
- **Determinism:** `scripts/ab-gate.sh raid_sim` byte-identical (all view-layer; prove it anyway) ·
  `scripts/verify-all.sh` green (run solo — the 7 GB box OOM-phantoms concurrent verify-alls) ·
  `ui_smoke_raid` green (already ALL OK for Slice 1).
- **Skin-rig fallback:** delete/rename the parts dir → the vector puppet returns, tour still clean.

---

## 7. PROCESS & SEQUENCING

- Worktree `../wow-tempo-art` (branch `tempo-art`); this design doc committed straight to `main`.
- Build order: **Slice 1 merges first** (no art dependency) → Bill generates art in parallel →
  **Slice 2** integrates when the PNGs land → **Slice 3** after.
- LEDGER LAW: BUILD-LEDGER §G row flips 🔨 + SHA on each merge; MASTER-PLAN §GRAPHICS is the living
  state.
- **Reusable for every other class.** The whole pipeline — juice pass, skin rig, flipbook FX — is
  class-agnostic; Twinfang is the pilot. Each future class = a generation brief + a
  `<class>_skin_rig_2d.gd` against its own joint tree. The Spine upgrade door stays open behind
  `Actor2D` the entire time.
