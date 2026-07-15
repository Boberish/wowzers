# Misprint Duelist — GOOD dodge four-pose gate

Date: 2026-07-15

Status: V2 static silhouette/consistency gate approved by Bill. Production
cards/runtime are next; no smear, GREAT/PERFECT/parry art, gameplay, or default
decision has been made.

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

Bill approved the V2 pose language and consistency. The next isolated step is
to derive production-size fixed-canvas cards and test the proposed 30 Hz holds:
1 / 2 / 1 / 2 ticks, then return to the shared ready anchor. Start GOOD root
translation at a restrained 25–35 display pixels and keep it Godot-owned. Do
not import this composition board as runtime frames, and do not begin smear,
GREAT, PERFECT, or parry art before the GOOD-only runtime verdict.

## Sword-layer correction

Bill approved the four poses and caught a foreground-order error in panels 2
and 3: their blades crossed behind the wielding teal arms. V2 preserves the
pose sequence and redraws those overlap regions with the existing straight
blade/cup assembly in front of the sleeve. V1 remains beside it as the audit
source. Bill's verdict on corrected V2 was “looks great”; V2 is approved.
