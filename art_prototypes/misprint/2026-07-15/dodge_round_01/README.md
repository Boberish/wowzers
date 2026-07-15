# Misprint Duelist — GOOD dodge four-pose gate

Date: 2026-07-15

Status: V2 static silhouette/consistency gate approved by Bill; production
cards and the slower clean-view runtime revision are complete on the isolated
feature branch. Bill's revised runtime verdict is next. No smear,
GREAT/PERFECT/parry art, gameplay, or production-default decision has been made.

Latest pose gate: `good_duck_four_pose_gate_v2_sword_foreground.png`.

SHA-256:

`84cd3720e93d772bf66ec9ad88a7ddeb1fd978dc28a004eb69085ed457cf5dab`

## Locked anchor

`user_refs/newSwordGaurd.png` is Bill's explicitly selected current Duelist
anchor. It is a byte-identical copy of the Downloads attachment:

`5654c49255a5d2acfdb522974fbcd909f961ba0b6776d04a44acec3a94feded4`

The anchor remains the separately shared READY stance; it is not repeated in
the active-pose count.

## First experiment

`good_duck_four_pose_gate.png` is a 2×2 key-pose board generated with the
built-in image tool. Read left-to-right, top-to-bottom:

1. COMPRESS
2. DEEPEST CLEARANCE
3. LOW SETTLE / OVERSHOOT
4. NEAR-READY RECOVERY

The board deliberately tests only four active authored silhouettes. It has no
smear, afterimage, motion line, colored echo, or baked root travel. The weapon
stays tucked during the low poses and returns toward guard only in pose 4.

Bill approved the V2 pose language and consistency. The initial isolated test
used the proposed 30 Hz holds of 1 / 2 / 1 / 2 ticks, then returned to the
shared ready anchor. Bill's first Windows runtime verdict superseded that
cadence; see **Readable runtime revision** below. GOOD root translation remains
within 25–35 display pixels and Godot-owned. Do not import this composition
board as runtime frames, and do not begin smear, GREAT, PERFECT, or parry art
before the revised GOOD-only runtime verdict.

## Production-card result

Completed on branch `codex/misprint-dodge-test` in `dc5dedb`. The approved V2
gate was not regenerated. `tools/build_good_dodge_cards.ps1` extracts the four
continuous inked figures from the warm-paper board, normalizes the separate
READY anchor to the same character scale, and registers all five cards onto a
transparent 768×768 canvas with a shared foot/root anchor. Source cards live in
`production_cards/`; byte-identical Godot copies live under
`godot/prototypes/misprint_dodge/frames_good_v2/`.

The first isolated/default-off proof held the active cards for **1 / 2 / 1 / 2
ticks** at 30 Hz, returned to READY at tick 6, and used `30 px` Godot-owned root
travel. That first 1920×1080 real-HUD tour passed at normal and
six-beat/0.26-second high-flow cadence. No smear, GREAT/PERFECT/parry art,
gameplay, protocol, production actor replacement, or default change was added.

## Readable runtime revision

Bill's first Windows verdict was that the six-tick pass was promising but
jerky, too fast to read as a duck, and obscured by the combat UI. Commit
`f0bc5a2` keeps the same five approved cards and changes only the isolated view
presentation:

- holds are **2 / 4 / 2 / 2 ticks** at 30 Hz, returning to READY at tick 10
  (333 ms total);
- DEEPEST CLEARANCE remains visible for four ticks / 133 ms;
- the tick-owned 30 px root targets receive a render-only 50 ms sine ease;
- `VIEW: CLEAN` is now stage-only by default, with all combat overlays hidden;
- `VIEW: FULL HUD` remains available from the wrapper controls.

The revised non-headless tour passed at normal and high-flow cadence and was
visually inspected at READY, COMPRESS, DEEPEST CLEARANCE, SETTLE, and RECOVERY.
The full raid UI smoke and pinned Mistral A/B gate also pass; the reducer output
remains byte-identical. Stop for Bill's verdict on this slower clean-view pass.

## Live motion lab

Commit `987e1cf` adds an isolated, presentation-only A/B lab around the same
approved cards and fixed 333 ms cadence. `MOTION: PUSHED` defaults to a visibly
excessive four-trail treatment; `MOTION: BASELINE` retains the readability
revision without trails. EASE (20–200 ms), TRAILS (0–4), SPREAD (0–1.50×),
OPACITY (0–1.50×), and BLUR (0–12 px) update the active actor live.

The initial effect nodes were active but hidden behind the stage because their
local z values were negative. The committed version uses a non-negative local
stack, keeps the main silhouette above every trail, and has been visually
confirmed in the real non-headless Mistral stage. Stop for Bill to report the
five preferred slider values; do not promote the exaggerated defaults.

## Sword-layer correction

Bill approved the four poses and caught a foreground-order error in panels 2
and 3: their blades crossed behind the wielding teal arms. V2 preserves the
pose sequence and redraws those overlap regions with the existing straight
blade/cup assembly in front of the sleeve. V1 remains beside it as the audit
source. Bill's verdict on corrected V2 was “looks great”; V2 is approved.
