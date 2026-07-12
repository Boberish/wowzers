# ART-V2 SCENES — the six-layer environment asset schema (Packet C3)

> The contract between **Codex** (who generates/prepares scene art) and **SceneKit**
> (`scene_kit.gd`, who renders it). Code consumes what lands here by convention —
> zero code changes per delivered layer. This file is the schema of record; the
> design law behind it is `GRAPHICS-PLAN.md §2.2` (six layers, SUNPRINT CEL,
> interior/exterior contrast). SceneKit never invents style or repaints assets.

## 1. Folder + filename convention (the profile binding)

Every `dir`-bound profile in `SceneKit.PROFILES` reads its layers from one folder:

```
res://game/art_v2/scenes/<profile_id>/
  backdrop.png    layer 1 — sky/wall/architecture. OPAQUE. Fills the canvas.
  distant.png     layer 2 — silhouettes/clouds/machinery strip. TRANSPARENT bg.
  midground.png   layer 3 — framing architecture/vegetation tile. TRANSPARENT bg.
  floor.png       layer 4 — floor material strip. OPAQUE.
  dressing.png    layer 5 — flank prop (drawn left + mirrored right). TRANSPARENT bg.
```

- Layer 6 (**atmosphere + palette**) is PARAMETERS ONLY — particles color/direction
  and a screen tint live in the profile dict, never a texture.
- A **missing file is legal**: that layer renders its colored debug placeholder with
  an `AWAITING CODEX · <profile>/<layer>.png` watermark. Delivering a file flips the
  layer to art on the next boot. Never a crash, never a hole, no partial-delivery
  ordering constraints.
- Live bindings today: `stack_atrium` (warm glass atrium) · `stack_cold_aisle`
  (cool server aisle). Both SUNPRINT CEL: bright, playful, authored — no
  dark-fantasy microtexture. New profile = one PROFILES entry + one folder.

## 2. How each layer is placed (the render contract)

Canvas: stretch `canvas_items` + `expand` — **wider aspects GROW width** (2560×1080
adds side canvas; height is the stable axis). Every layer therefore scales by
HEIGHT and repeats horizontally; key art is never stretched (§2.2).

| layer | placement | tiling / ultrawide behavior |
|---|---|---|
| backdrop | full height (y 0→h) | scale-by-height, tile any leftover width — make the tile's left/right edges CONTINUOUS (it wraps) |
| distant | sky band, y ≈ 0.06h→0.32h | tiled strip, drifts slowly leftward (~8 px/s) — must wrap seamlessly |
| midground | feet on the floor line, strip height 0.46h (top ≈ 0.34h) | tiled across width — repeatable pattern, seam-safe |
| floor | y 0.80h→h (THE FLOOR LINE is h·0.80 — actors' feet ride `RaidStage2D.SLOTS` at 0.775–0.790 and NEVER move) | tiled strip |
| dressing | flank prop: left at x≈0.02w, mirrored at x≈0.98w, ~0.34h tall, base on the floor line | drawn once per side — props frame the fight, never cross the combat lane |

The boss stands at x ≈ 0.72w (`FOCUS_X`); keep midground/dressing focal clutter off
the 0.10w–0.60w raider lane and the 0.65w–0.80w boss slot at gameplay height.

## 3. Source sizes + texture-import defaults

Target the 1080p design height; the engine scales from there:

- `backdrop` 2048×1024 (will render ≥1080 tall — author 1152+ tall if crispness
  matters; ≤2048 wide per the Web/GL budget law) · `distant` 1024×256 ·
  `midground` 1024×512 · `floor` 1024×256 · `dressing` ≤512×512.
- PNG, sRGB, transparent where the table says so. No baked vignettes/gradients
  over the combat lane (readability law §1.5).
- Import defaults (Godot 4 · GL Compatibility · WebGL2 targets): **Compress =
  Lossless** (WebP lossless on import) · **Mipmaps = ON** (layers downscale on
  720p) · filter linear (project default) · no VRAM compression (desktop-class
  BPTC/S3TC is unavailable on WebGL2 and these are few, large, reused textures).
  These are per-file `.import` settings Godot generates on first import — do NOT
  hand-edit `project.godot` importer defaults for this (§8: art never owns that
  diff). If a `.import` deviates, fix it in the editor's Import dock and re-import.
- Only **approved, processed runtime layers** enter these folders (§3 law). Source
  sheets/generations stay out of `res://` (a marked source-art folder outside the
  project if Bill wants history).

## 3½. Renderer law — no texture I/O in painters (2026-07-12 hotfix)

SceneKit resolves every layer texture ONCE, at host construction (`_ready`) —
never `load()` inside a draw callback. On the WSLg d3d12-GL driver a texture
whose FIRST load happens during a canvas draw pass uploads as a permanently
flat-white RID (the C3 texture-visibility bug: art loaded+drawn in-painter =
white screen; identical `.ctex` loaded up front = correct). Delivery semantics
are unchanged — files are picked up when the profile host boots.
`sim/artv2_tex_probe.gd` is the four-path regression harness (ctex up-front ·
ctex in-draw · ImageTexture · TextureRect); if scenes ever go white again on a
new driver, run it first.

## 4. The repeatable tour (visual acceptance)

```
godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script res://sim/artv2_scene_tour.gd -- --profile=stack_atrium --out=/abs/dir
```

One run per profile × resolution; shots at frames 40/160/300 (lineup · windup ·
busy) named `<profile>_<WxH>_f<frame>.png`, plus the FEET-LINE RECORD printed per
shot (actor positions — must be identical across profiles at the same resolution).
Acceptance matrix when assets land (C3 gate, GRAPHICS-PLAN §10.4): 1920×1080 ·
1280×720 · 2560×1080 × each bound profile + legacy, feet-line diff clean.
2026-07-12: matrix run DEFERRED as recorded debt (Bill's minimal-verify call) —
placeholder-state proof = one 1920×1080 shot per stack profile.

## 5. What this schema is NOT

- Not the actor pipeline (`ART-PIPELINE.md` / C4-C5) and not the dashboard (C6).
- Not a parallax/camera system — layers are flat bands today; depth cues come
  from the art. If a profile needs parallax later, it's a SceneKit feature behind
  the same data, not a new asset format.
- Not reachable by players: scenes render only under `--artv2=scene:<id>` (C1
  selector, default OFF). Legacy `StageBackdrop` remains the default everywhere.
