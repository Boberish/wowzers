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
