# Misprint Duelist — GOOD dodge four-pose gate

Date: 2026-07-15

Status: static silhouette/consistency approval gate only. No runtime frame set,
smear, GREAT/PERFECT/parry art, gameplay, or default decision.

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

If Bill approves the pose language and consistency, the next isolated step is
to derive production-size fixed-canvas cards and test the proposed 30 Hz holds:
1 / 2 / 1 / 2 ticks, then return to the shared ready anchor. Root translation
and any echo treatment remain Godot-owned. Do not import this composition board
as runtime frames.

