# Misprint GOOD dodge — isolated Godot proof

This is the executable GOOD-only test requested by
`art_prototypes/misprint/2026-07-15/CONTINUE-HERE.md`. It does not replace the
production Duelist actor and is not reachable from the game's front door.

Run the interactive test with a display:

```bash
godot --path godot --rendering-driver opengl3 \
  res://prototypes/misprint_dodge/misprint_dodge_test.tscn
```

The scene launches the real Duelist HUD against Mistral. `NORMAL` preserves the
live songbook. `HIGH-FLOW` installs a test-only six-beat weave at 0.26-second
gaps. `AUTO` routes real `DuelistPolicy` actions through the controller input
queue; turn it off to use the normal gameplay keys. The wrapper opens in
`VIEW: CLEAN`, which retains the live stage and actors while hiding the combat
HUD. Toggle it to `VIEW: FULL HUD` to inspect the same proof in the complete
play surface. It also opens in `MOTION: PUSHED`; toggle to `MOTION: BASELINE`
for the approved uncluttered comparison.

## Approved V2 cards

The current proof uses five fixed 768×768 transparent cards:

1. the separately approved READY anchor;
2. COMPRESS;
3. DEEPEST CLEARANCE;
4. LOW SETTLE / OVERSHOOT;
5. NEAR-READY RECOVERY.

Source cards live in
`art_prototypes/misprint/2026-07-15/dodge_round_01/production_cards/`; byte-
identical runtime copies live in `frames_good_v2/`. Rebuild both sets with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  art_prototypes/misprint/2026-07-15/tools/build_good_dodge_cards.ps1
```

The builder flood-fills only paper-like pixels connected to source edges and
keeps the largest continuous inked figure. It does not redraw active poses or
alter their surviving RGB pixels. The READY anchor alone is normalized to the
pose-gate scale (`0.57`); all cards share a foot/root registration at canvas
`x=384`, `y=768`. Transparent corners and source/runtime hash equality are
checked by the build/verification workflow.

## Runtime contract

- A landed dodge/weave starts COMPRESS on the reducer event's tick.
- Holds are exactly **2 / 4 / 2 / 2 ticks** at 30 Hz; READY returns at age 10
  (333 ms total). DEEPEST CLEARANCE therefore reads for 133 ms.
- Godot owns root motion: `30 px` peak, inside the approved 25–35 px range.
  Tick-owned targets remain deterministic. BASELINE uses a render-only 50 ms
  sine ease; PUSHED exposes its render easing as a live slider.
- The historical compact coral/cobalt duplicates remain behind CLEARANCE at
  ages 2–3. No smear frame, particles, shader, or new runtime library exists.
- Repeated successes cancel/restart immediately at COMPRESS.
- The selector remains default-off and missing cards fall back to the current
  production actor.
- CLEAN view is stage-only by default: the judgment channel, class band,
  top/side rails, dev widgets, and verdict overlays are suppressed. The test
  wrapper's controls remain available, and FULL HUD rebuilds the unhidden HUD.

## Live motion lab

The isolated wrapper exposes five presentation-only sliders. They update the
active actor on its next tick without restarting the fight, and never enter
combat state:

| Knob | Range | Exaggerated default |
|---|---:|---:|
| EASE | 20–200 ms | 120 ms |
| TRAILS | 0–4 | 4 |
| SPREAD | 0–1.50× | 1.00× |
| OPACITY | 0–1.50× | 1.00× |
| BLUR | 0–12 px | 6 px |

PUSHED uses four direction-aware tinted silhouettes, each shader-softened and
kept behind the main card. The local actor stack uses non-negative z-order;
the first implementation's negative effect z values put the trails behind the
stage environment even though the nodes reported visible. The visual tour—not
the visibility boolean—is the acceptance proof for this effect.

The older six-card proof remains in `frames/` only as historical evidence; it
is no longer the active card set.

## Verification — 2026-07-15

```bash
godot --headless --path godot --script res://sim/misprint_dodge_probe.gd
godot --headless --path godot --script res://sim/artv2_probe.gd
godot --headless --path godot --script res://sim/ui_smoke_raid.gd
scripts/ab-gate.sh raid_sim --seeds=30 --boss=mistral
godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script res://sim/misprint_dodge_tour.gd \
  -- --out=/tmp/misprint-good-live-sliders
```

Results: `misprint_dodge_probe` ALL OK · `artv2_probe` 201 checks ·
`ui_smoke_raid` ALL OK · A/B BYTE-IDENTICAL (CSV MD5
`45dabf2d00346bd184cdf6324918f9a6`) · non-headless tour ALL OK. The visual
tour confirmed shared ground contact, readable single rapier/cup guard, a
sustained deep-clearance silhouette, stage-only clean framing, visibly rendered
directional trails, and stable high-flow restart behavior. The probe also
changes the live knobs on an active actor without restart. The task stops here
for Bill to tune the motion lab and report the preferred values.
