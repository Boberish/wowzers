# P3 Environment Source Anchors

These images are the approved visual anchors for the first Art V2 SceneKit pair.
They are source references only and must not be loaded directly by Godot.

- `anchors/stack-atrium-gameplay-anchor.png` — bright daytime data-center atrium.
- `anchors/stack-cold-aisle-gameplay-anchor.png` — darker night-maintenance machine hall.

Both anchors lock the SUNPRINT CEL family, Mistral's functional robot design, the bright-versus-dark
contrast, and the reaction-first HUD hierarchy. They do **not** lock baked UI pixels or character
positions into environment textures.

Runtime layers follow `godot/game/art_v2/SCENES.md` and land only after visual inspection:

```text
godot/game/art_v2/scenes/<profile>/
  backdrop.png
  distant.png
  midground.png
  floor.png
  dressing.png
```

Atmosphere remains profile parameters. Generated intermediates and rejected variants stay here,
outside `res://`; only approved processed layers enter the runtime folders.

## Delivery progress

- `stack_atrium/backdrop-v1.png` — approved prototype backdrop, 1672×941 RGB. Copied to
  `godot/game/art_v2/scenes/stack_atrium/backdrop.png` for the first live composition pass.
  Its regular atrium-bay rhythm is intentional for horizontal repetition; the distant,
  midground, and dressing layers must break center-mirrored symmetry with offset clusters.
- This v1 is below the preferred 2048×1024+ source target. Do not spend an upscale/regeneration
  pass until its scale, seam, and readability have been inspected in SceneKit.
- `stack_atrium/distant-*-v1.png` — chroma source, alpha extraction, and 2048×256 prepared runtime
  strip; delivered as layer 2/5 in `ebd7242`.
- `stack_atrium/midground-*-v1.png` — asymmetric chroma source, alpha extraction, and 2048×512
  prepared strip. The live 1080p tour keeps the timing lane readable; final density tuning waits
  until floor and dressing complete the scene.
