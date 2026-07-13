# P4 Duelist source art

This folder holds Codex I2 source and preparation artifacts outside `res://`. Runtime accepts
only the processed PNGs under `godot/game/art_v2/actors/duelist/`.

## Approved anchor

- `anchors/duelist-dodge-tank-anchor-v1.png`
- Bill's gate: approved 2026-07-13 by continuing from the second, dodge-tank revision.
- Identity: young adult with tousled black hair; teal fitted short coat; navy trousers; light
  boots; one copper forearm deflection bracer; short burnt-red scarf split into two tails; one
  narrow straight single-hand dueling sword with a partial basket guard.
- Role read: low side-on guard, long mobile legs, free hand balancing, no shield, no plate. The
  Duelist tanks by baiting, slipping, and last-instant deflection rather than absorbing damage.

## Visual law

SUNPRINT CEL: confident irregular ink, deliberate flat color shapes, restrained authored print
grain, bright adventurous exposure, and clean animation-friendly silhouettes. Avoid glossy anime
rendering, generic knight armor, AI micro-ornament, long heroic capes, and oversized weapons.

## I2 delivery contract

The C4 adapter consumes six transparent parts in paint order (`cloak`, `legs`, `torso`, `head`,
`arm`, `blade`) and two transparent whole-figure replacements (`windup_heavy`, `swing_heavy`).
The figure is authored facing right with feet as the root. C5 owns final anchor coordinates and
the complete pose vocabulary after I2 delivers coherent source and runtime images.

Generated chroma sources use flat `#ff00ff`; prepared variants remove that key with the installed
image-generation helper. No source sheet is copied into `res://`.
