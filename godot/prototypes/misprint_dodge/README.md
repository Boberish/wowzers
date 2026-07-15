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
queue; turn it off to use the normal gameplay keys.

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
- Holds are exactly **1 / 2 / 1 / 2 ticks** at 30 Hz; READY returns at age 6
  (200 ms total).
- Godot owns root motion: `30 px` peak, inside the approved 25–35 px range.
- The historical compact coral/cobalt duplicates remain behind CLEARANCE at
  ages 1–2. No smear frame, particles, shader, or new runtime library exists.
- Repeated successes cancel/restart immediately at COMPRESS.
- The selector remains default-off and missing cards fall back to the current
  production actor.

The older six-card proof remains in `frames/` only as historical evidence; it
is no longer the active card set.

## Verification — 2026-07-15

```bash
godot --headless --path godot --script res://sim/misprint_dodge_probe.gd
godot --headless --path godot --script res://sim/artv2_probe.gd
godot --headless --path godot --script res://sim/ui_smoke_raid.gd
scripts/ab-gate.sh raid_sim --seeds=30 --boss=mistral
godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
  --script res://sim/misprint_dodge_tour.gd -- --out=/tmp/misprint-good-v2b
```

Results: `misprint_dodge_probe` ALL OK · `artv2_probe` 201 checks ·
`ui_smoke_raid` ALL OK · A/B BYTE-IDENTICAL (CSV MD5
`45dabf2d00346bd184cdf6324918f9a6`) · non-headless tour ALL OK. The visual
tour confirmed shared ground contact, readable single rapier/cup guard, lowered
clearance silhouette, unobstructed timing instrument, and stable high-flow
cadence. The task stops here for Bill's GOOD-runtime verdict.
