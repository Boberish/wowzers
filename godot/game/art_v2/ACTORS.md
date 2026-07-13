# ART-V2 ACTORS — the painted-actor metadata contract (Packet C4)

> The contract between **Codex** (who generates/derives character layers) and
> **`PaintedActor2D`** (`painted_actor_2d.gd`, the class-agnostic adapter that
> renders them behind the `Actor2D` verb surface). SCENES.md's sibling. The
> adapter consumes what lands here by convention — zero code per delivered
> actor. Design law: `GRAPHICS-PLAN.md §2.1` (C/D hybrid, native first, no
> Spine dependency — the Spine door stays a door behind this same contract).

## 1. Folder convention (the id binding)

```
res://game/art_v2/actors/<id>/            id = class/boss id (duelist, riftmaw…)
  actor.json      the metadata (below)
  parts/*.png     painted layers, one file per part (transparent bg)
  frames/*.png    whole-figure replacement/contact drawings (transparent bg)
res://game/art_v2/actors/<id>_<aspect>/   optional aspect variant — wins over <id>/
```

- Resolution order (flag `--artv2=actors` ON): `<id>_<aspect>/actor.json` →
  `<id>/actor.json` → C1's plain `<id>.tscn` drop-in → **legacy puppet**.
- Missing folder, missing/invalid `actor.json`, or zero buildable parts ⇒ the
  adapter declines (`try_make` = null) and the CURRENT actor renders — the
  legacy factory (including its known post-purge fallthrough) is never edited.
- A missing individual part texture skips that part with a warning; the actor
  still builds (partial deliveries legal, same as scenes).
- Flag OFF (release default): none of this code runs.

## 2. actor.json schema

```jsonc
{
  "version": 1,
  "id": "duelist",
  "scale": 1.0,          // rig-level scale (the stage's slot scale multiplies on top)
  "height": 300,         // figure height px — gaze-diamond placement, frame anchoring
  "glow_part": "blade",  // optional: the part that reads power_glow (class resource)
  "parts": [             // ARRAY ORDER = PAINT ORDER (first = deepest)
    {
      "name": "torso",         // unique; parents reference it
      "tex": "parts/torso.png",
      "mode": "rigid",         // rigid (default) | deform
      "anchor": [0.5, 1.0],    // pivot as a fraction of the texture (origin point)
      "at": [0, -116],         // position relative to the PARENT's origin (root = feet, y-up negative)
      "parent": "",            // "" = rig root; else a previously-listed part name
      "rot": 0,                // initial rotation, degrees
      "sway": 6                // deform only: hem sway amplitude px
    }
  ],
  "frames": {                  // whole-figure replacement/contact drawings
    "windup_heavy": "frames/windup_heavy.png",   // shown SCRUBBED while that windup runs
    "swing_heavy": "frames/swing_heavy.png"      // flashed ~0.16s at the release
  }
}
```

Optional **`"poses"` block (C5)** — the data-driven verb vocabulary:

```jsonc
"poses": {                       // pose name -> {part: DELTA degrees from its base rot}
  "windup": {"root": -10, "arm": -95, "head": 6},   // scrubbed by the engine's amt
  "swing":  {"root": 6, "arm": -14},                // snapped at release, eased home
  "parry":  {"root": -4, "arm": -55},               // the deflection flick (evade_react)
  "lunge":  {"root": 6}
}
```

`"root"` tilts the whole rig; other keys rotate named parts. A missing pose falls
back to the C4 generic motion — the adapter stays class-agnostic; the vocabulary
is data. Windup precedence: `frames/windup_<kind>` replacement first, then the
`windup` pose lerp, then the generic coil.

Part modes: **rigid** = Sprite2D (weapon/plate/limb — offset/rotation only) ·
**deform** = Polygon2D warp quad (cloth/cloak — shoulders pinned, hem sways at
render rate). **Replacement frames** are the third mode: keys are
`windup_<kind>` / `swing_<kind>` per the telegraph kinds
(`light|heavy|crush|channel|curse|nova|cut_hi|cut_lo`); while active they hide
the layered rig entirely for one authored beat.

Anchors: the rig root origin is THE FEET (the stage positions actors by
`RaidStage2D.SLOTS` feet fractions — the adapter never moves them). Characters
are authored FACING RIGHT (the stage mirrors the boss by flipping scale.x).

## 3. Behavior laws (what the adapter guarantees)

- **Verbs in, pixels out.** Implements the full `Actor2D` surface; reads no
  CombatState, no seat vars, no clocks that matter. Idle breath/cloak sway are
  cosmetic wall-clock; **`windup(kind, amt)` is a pure function of `amt`** —
  the engine scrubs, the adapter poses (same amt ⇒ same silhouette).
- **Construction-time I/O only** (SCENES.md §3½ law): json + every texture are
  resolved in `try_make`; painters/`_process` never touch the filesystem —
  first-load-in-draw is the WSLg white-RID trap.
- **No Spine, no external runtimes** — Sprite2D/Polygon2D/Tween only.

## 4. Debug proof art (what ships in-repo today)

`actors/duelist/` now holds the REAL approved Duelist layers (C5, 2026-07-13):
cropped/normalized from `art-source/graphics-v2/p4-duelist/alpha/` by
`sim/artv2_part_prep.gd` (crop-to-used-rect + contract sizing — the tool never
generates or repaints; re-run it when Codex re-delivers a source). The old
flat-slab generator (`sim/artv2_actor_gen.gd`) remains for stubbing OTHER ids.

## 5. Verification pointers

- `sim/artv2_probe.gd` [7] — adapter contract checks (delivery-agnostic).
- `sim/artv2_scene_tour.gd -- --actors [--profile=…]` — visual tour with the
  painted adapter live; undelivered ids stay puppets in the same shot (the
  fallback, photographed). Full pose/contact matrix + live tank playtest =
  C4/C5 deferred debt (BUILD-LEDGER graphics row).
