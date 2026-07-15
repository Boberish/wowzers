# Continue here — Misprint Duelist animation rework

Date: 2026-07-15

Branch: `codex/misprint-dodge-test` (experimental, unmerged)

This is the restart point for another computer or a fresh chat. Read
`AGENTS.md` and `MASTER-PLAN.md` first, then use this file as the decision
record for the current art task.

## Approved now

The current character/READY anchor is:

`dodge_round_01/user_refs/newSwordGaurd.png`

SHA-256:

`5654c49255a5d2acfdb522974fbcd909f961ba0b6776d04a44acec3a94feded4`

The current approved GOOD-dodge pose gate is:

`dodge_round_01/good_duck_four_pose_gate_v2_sword_foreground.png`

SHA-256:

`84cd3720e93d772bf66ec9ad88a7ddeb1fd978dc28a004eb69085ed457cf5dab`

Bill's verdict after the panel 2/3 sword-layer correction was **“looks
great.”** V2 is therefore the approved source gate. The earlier
`good_duck_four_pose_gate.png` remains only as an audit source.

The four active authored poses, read left-to-right and top-to-bottom, are:

1. COMPRESS
2. DEEPEST CLEARANCE
3. LOW SETTLE / OVERSHOOT
4. NEAR-READY RECOVERY

The READY anchor is shared separately and is not one of those four poses.

## Next isolated task

Productionize **only this approved GOOD dodge**:

1. Derive four transparent, fixed-canvas production cards from the approved V2
   gate while keeping the selected READY anchor consistent.
2. Preserve the single slender sword, brass cup guard, closed/gloved hands,
   outfit, proportions, ponytail, and the corrected foreground sword layering.
3. Test the active cards at 30 Hz with holds of **1 / 2 / 1 / 2 ticks**, then
   return to the shared READY anchor: six ticks / 200 ms total.
4. Keep root motion Godot-owned. Start with a restrained **25–35 display-pixel**
   GOOD-dodge translation rather than baking travel into the cards.
5. Keep the proof isolated and default-off. Do not replace the playable actor,
   change combat/gameplay, change protocol, or merge this branch to `main`.

Do **not** add a smear frame yet. Do **not** begin GREAT, PERFECT, or parry art
until Bill has seen and judged this GOOD-only runtime pass. The goal is to test
whether four authored active poses are enough before expanding the animation
set.

The display result `GOOD` maps to the existing internal
`StrikeRes.Grade.GOOD`; this task does not change grading logic.

## Historical proof — do not mistake it for the new gate

The older six-frame executable proof remains under:

`godot/prototypes/misprint_dodge/`

Its source cards are under `dodge_test/`. It established that fixed-card swaps,
root travel, and echo sprites work in the real HUD, but it predates the selected
cup-guard character and the approved four-pose gate. Keep it as a reference;
do not overwrite its source frames or treat them as the new production art.

## Start on the other computer

If the feature branch does not exist locally yet:

```bash
git fetch origin
git worktree add ../wow-misprint-dodge-test \
  -b codex/misprint-dodge-test origin/codex/misprint-dodge-test
cd ../wow-misprint-dodge-test
```

If that branch/worktree already exists there:

```bash
git fetch origin
cd ../wow-misprint-dodge-test
git pull --ff-only
```

Before stopping on either computer, commit and push the feature branch. Before
starting on the other, fetch and pull it. Do not work on this feature from both
computers simultaneously without first pushing one side.

## Fresh-chat prompt

> Work in the `codex/misprint-dodge-test` worktree. Read `AGENTS.md`,
> `MASTER-PLAN.md`, and
> `art_prototypes/misprint/2026-07-15/CONTINUE-HERE.md` first. Continue only the
> approved GOOD-dodge productionization described there: four transparent
> fixed-canvas active cards from the V2 pose gate, 1/2/1/2 ticks at 30 Hz,
> shared READY anchor, restrained Godot-owned root motion, isolated/default-off.
> Do not start GREAT/PERFECT/parry, change gameplay, replace production art, or
> merge to main. Claim the work in the Coordination Log before editing.
