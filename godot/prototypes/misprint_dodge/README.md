# Misprint dodge — isolated Godot proof

This is the executable test requested by
`art_prototypes/misprint/2026-07-15/docs/ART_HANDOFF_2026-07-15.md`.
It does not replace the production Duelist actor and is not reachable from the
game's front door.

Run the interactive test with a display:

```bash
godot --path godot --rendering-driver opengl3 \
  res://prototypes/misprint_dodge/misprint_dodge_test.tscn
```

The scene launches the real Duelist HUD against Mistral. `NORMAL` preserves the
live songbook. `HIGH-FLOW` installs a test-only six-beat weave at 0.26-second
gaps. `AUTO` routes a real `DuelistPolicy` action through the controller input
queue; turn it off to use the normal gameplay keys.

The six source PNGs are byte-identical copies of the handoff. They actually vary
between 553–554 × 466–467 despite the handoff's fixed 553×466 claim, so the
adapter registers them into a 554×467 logical card without resampling or editing
the source pixels.

Verification:

```bash
godot --headless --path godot --script res://sim/misprint_dodge_probe.gd
godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script res://sim/misprint_dodge_tour.gd -- --out=/tmp/misprint-dodge
```

## Proof result — 2026-07-15

- The runtime copies match all six handoff PNGs byte-for-byte (SHA-256).
- Godot imports them losslessly (`compress/mode=0`), with mipmaps off, alpha
  border repair on, and premultiplication off. The adapter does not resample or
  rewrite the one-pixel source-size variations.
- A landed dodge/weave begins on the reducer event's tick. Active texture holds
  measure exactly 1 / 1 / 2 / 2 / 4 ticks, then ready returns at age 10.
- Root travel peaks at 91.16 display pixels. Coral/cobalt echoes are visible
  behind the active card only at ages 1 and 2.
- The 1920x1080 tour produced ready plus exact ages 0, 1, 2, 4, 6, and 9 for
  normal Mistral cadence, followed by high-flow ready, cancel/restart, and live
  flurry captures. Baselines stayed visually registered; the single rapier,
  lowered head, coat tails, and legs remained readable behind the actual HUD.
  No pose redraw was needed for this proof.
- The high-flow tour observed successive successful answers less than the
  ten-tick recovery apart; each success immediately restarted at pose 02.

Targeted gates passed: `misprint_dodge_probe`, `artv2_probe` (201 checks),
`ui_smoke_raid`, a 30-seed Mistral `raid_sim` A/B with byte-identical stdout and
CSV (`45dabf2d00346bd184cdf6324918f9a6`), the non-headless tour, and a 240-frame
interactive-scene boot. The proof uses only texture swaps, `Node2D` transforms,
and modulated `Sprite2D` duplicates; no particles, shaders, runtime libraries,
or renderer-specific calls were added.
